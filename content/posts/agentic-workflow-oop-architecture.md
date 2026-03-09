---
title: "Phân tích Kiến trúc Agentic Workflow qua lăng kính OOP: Case Study loop.py"
date: 2026-03-06T14:00:00+07:00
draft: false
description: "Phân tích thực tế cách Encapsulation, Abstraction, Composition và Polymorphism được áp dụng để xây dựng hệ thống điều phối ReAct bền bỉ cho AI Agent."
tags: ["AIAgent", "Python", "SoftwareArchitecture", "OOP", "CleanCode"]
categories: ["Kiến trúc hệ thống"]
author: "Hoang Nguyen Thai"
showToc: true
TocOpen: true
cover:
    image: "images/posts/agentic-workflow-oop-architecture/loop-oop.png"
    alt: "Kiến trúc Agentic Workflow trong mã nguồn thực tế"
---

Tháng trước, khi bắt tay vào xây dựng hệ thống AI Agent, tôi bắt đầu bằng một file script đơn giản dài khoảng 200 dòng. Mọi thứ hoạt động hoàn hảo cho đến khi tôi thêm công cụ (Tool) thứ 5 và bắt đầu xử lý các tác vụ bất đồng bộ. Code trở thành một mớ bòng bong (Spaghetti code) không thể debug.

Đó là lúc tôi nhận ra: Xây dựng AI Agent không phải là bài toán viết Prompt hay gọi API mô hình ngôn ngữ. Nó là bài toán về **Kỹ thuật Phần mềm (Software Engineering)**. Tệp tin `loop.py` mà tôi thiết kế lại sau đó chính là minh chứng cho việc áp dụng 4 nguyên lý OOP kinh điển để kiểm soát sự phức tạp của vòng lặp ReAct (Reasoning and Acting).

---

## 1. Tính Đóng Gói (Encapsulation): Tránh "đầu độc" Context

Trong kiến trúc của tôi, lớp `AgentLoop` hoạt động như một máy trạng thái (State machine) khép kín. Việc đóng gói không chỉ để code trông "sạch" hơn, mà để giải quyết một lỗi chí mạng: **Context poisoning**. Khi LLM trả về một phản hồi lỗi (ví dụ: HTTP 400), nếu không được cách ly, lỗi này sẽ bị ghi vào lịch sử hội thoại, khiến Agent kẹt vĩnh viễn trong một vòng lặp lỗi.

- **Thực thi:** Tôi khóa chặt các logic nhạy cảm như `_run_agent_loop` hay `_process_message` thành phương thức private. Trạng thái `self._running` và `self._processing_lock` đảm bảo Agent không bao giờ xử lý chồng chéo tin nhắn.

```python
class AgentLoop:
    def __init__(self, ...):
        self._running = False
        self._processing_lock = asyncio.Lock()

    async def run(self) -> None:
        """EntryPoint duy nhất để hệ thống bên ngoài tương tác"""
        async with self._processing_lock:
            self._running = True
            await self._run_agent_loop()
```

---

## 2. Tính Trừu Tượng (Abstraction): Chống "Vendor Lock-in"

Khi OpenAI gặp sự cố diện rộng, tôi cần chuyển sang hệ thống Claude của Anthropic ngay lập tức. Nếu gọi trực tiếp API của OpenAI trong vòng lặp, toàn bộ hệ thống sẽ tê liệt.

- **Giải pháp:** `AgentLoop` chỉ giao tiếp với một Interface trừu tượng là `LLMProvider`.
- **Thực thi:** Tại thời điểm chạy, `self.provider` có thể là bất kỳ mô hình nào. `AgentLoop` không cần biết việc chuẩn bị Payload cho GPT-4 khác với Claude 3.5 ra sao.

```python
# Gọi LLM thông qua interface chung, miễn nhiễm với sự thay đổi của Vendor
response = await self.provider.chat(
    messages=messages,
    tools=self.tools.get_definitions(),
    model=self.model,
)
```

---

## 3. Tính Hợp Thành (Composition): Giải quyết "Diamond Problem"

**Điều tôi đã thử và thất bại:** Ban đầu, tôi dùng tính Kế thừa (Inheritance) để tạo ra `CoderAgent` kế thừa từ `BaseAgent`. Nhưng khi cần một Agent vừa biết code vừa biết tìm kiếm (Researcher), kiến trúc phả hệ vỡ vụn vì vấn đề đa kế thừa (Diamond problem).

- **Giải pháp:** Chuyển sang tính Hợp thành (Composition - "Has-a"). Tôi thiết kế `AgentLoop` như một nhạc trưởng, không tự làm gì cả mà chỉ điều phối các module chuyên biệt.
- **Cấu trúc:** 
    - `self.context = ContextBuilder()`: Xử lý build prompt.
    - `self.sessions = SessionManager()`: Quản lý bộ nhớ.
    - `self.tools = ToolRegistry()`: Quản lý kỹ năng.

```python
def __init__(self, ...):
    # AgentLoop không tự quản lý bộ nhớ hay tool, nó sở hữu các module thực hiện việc đó
    self.context = ContextBuilder(workspace)   
    self.sessions = SessionManager(workspace)   
    self.tools = ToolRegistry()                 
```

---

## 4. Tính Đa Hình (Polymorphism): Plug-and-Play Architecture

Làm sao để Agent biết cách gọi một công cụ tìm kiếm web so với một công cụ đọc file local, khi mà bản chất hai hành động này hoàn toàn khác nhau? Câu trả lời là Đa hình.

- **Thực thi:** Mọi công cụ (từ `ReadFileTool` đến `WebSearchTool`) đều tuân thủ chung một interface có hàm `execute()`.
- **Lợi ích:** Trong vòng lặp ReAct, đoạn code thực thi công cụ luôn cố định. Khi cần cắm thêm giao thức mới như MCP (Model Context Protocol), tôi không phải sửa dù chỉ một dòng code bên trong `loop.py`.

```python
# Một lời gọi duy nhất, nhưng hành vi thực thi biến hóa theo từng Tool cụ thể
for tool_call in response.tool_calls:
    result = await self.tools.execute(tool_call.name, tool_call.arguments)
    messages = self.context.add_tool_result(messages, tool_call.id, tool_call.name, result)
```

---

## Sơ đồ kiến trúc tối giản

Sơ đồ dưới đây minh họa sự phối hợp nhịp nhàng của 4 tính chất OOP để tạo nên một bộ điều phối hoàn chỉnh:

![Kiến trúc Agentic Workflow](/images/posts/agentic-workflow-oop-architecture/loop-oop.png)
*Hình 1: Kiến trúc điều phối của AgentLoop.*

---

## Đúc kết

Sự khác biệt giữa một bản "demo chạy cho vui" và một hệ thống AI dùng trong Production không nằm ở việc bạn viết Prompt khéo đến đâu. Nó nằm ở việc bạn tổ chức kiến trúc phần mềm như thế nào. 

Bài học tôi rút ra sau khi đập đi xây lại `loop.py`: **Mô hình ngôn ngữ (LLM) là bộ não, nhưng nếu không có một khung xương (Architecture) vững chắc, bộ não đó cũng không thể nâng đỡ được một cơ thể hoạt động bền bỉ.**
