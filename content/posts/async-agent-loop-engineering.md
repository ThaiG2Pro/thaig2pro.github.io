+++
title = 'Async Agent Loop: Đảm bảo khả năng kiểm soát và phản hồi thời gian thực cho AI Agent'
date = 2024-03-10T00:00:00+07:00
draft = false
description = 'Phân tích kiến trúc xử lý không đồng bộ (asynchronous) để giữ cho AI Agent luôn nhạy bén và có khả năng kiểm soát cao trong môi trường production.'
tags = ['Python', 'Asyncio', 'AI Agent', 'Software Architecture']
categories = ['Engineering']
author = 'Hoang Nguyen Thai'
showToc = true
TocOpen = false
+++

Trong kiến trúc của một AI Agent, "Loop" chính là bộ não điều hành. Tuy nhiên, một sai lầm phổ biến là thiết kế Loop theo dạng tuần tự (synchronous). Nếu Agent đang thực hiện một task nặng (như crawl web hoặc chạy một script dài), nó sẽ hoàn toàn "mù điếc" trước các lệnh mới của người dùng cho đến khi task đó xong.

Hôm nay, chúng ta sẽ phân tích cách ứng dụng `asyncio` để biến một vòng lặp vô tận trở thành một hệ thống điều hành Agent chuyên nghiệp, đảm bảo tính phản hồi (responsiveness) và khả năng kiểm soát (controllability).

---

## Tổng quan kiến trúc Loop

Mô hình chung của một Agent System hiện đại thường vận hành theo cơ chế không đồng bộ để tách biệt các luồng dữ liệu.

![Agent Loop Architecture Overview](/images/posts/async-agent-loop-engineering/architecture-overview.png)
*Flow đồ hiển thị sự tách biệt giữa Inbound Message Queue, Loop Dispatcher, và Tool Execution Layer*

---

## 1. Non-blocking Dispatcher: Tách biệt việc "Nhận" và "Xử lý"

Vấn đề lớn nhất của các Agent sơ khai là: **Khi đang suy nghĩ, nó không thể nghe.** 

Trong một kiến trúc Loop chuẩn, thay vì đợi quá trình xử lý tin nhắn hoàn thành mới nhận tin nhắn tiếp theo, chúng ta sử dụng `asyncio.create_task` để đẩy logic xử lý vào background. Điều này giúp vòng lặp chính (`while self._running`) luôn sẵn sàng tiếp nhận tín hiệu mới.

```python
# Trích đoạn logic từ vòng lặp chính
while self._running:
    try:
        # Chờ message từ bus với timeout để tránh treo loop
        msg = await asyncio.wait_for(self.bus.consume_inbound(), timeout=1.0)
    except asyncio.TimeoutError:
        continue

    if msg.content.strip().lower() == "/stop":
        await self._handle_stop(msg)
    else:
        # Dispatch message thành một task độc lập
        task = asyncio.create_task(self._dispatch(msg))
        self._active_tasks.setdefault(msg.session_key, []).append(task)
        # Tự động dọn dẹp task khi hoàn thành
        task.add_done_callback(lambda t, k=msg.session_key: self._active_tasks.get(k, []) and self._active_tasks[k].remove(t))
```

**Cái hay ở đây là gì?** 
- Vòng lặp chính luôn nhạy bén với lệnh `/stop`.
- Mỗi yêu cầu được xử lý trong một "green thread" riêng biệt thông qua `_dispatch`.
- Hệ thống có thể quản lý đồng thời nhiều session khác nhau mà không block lẫn nhau.

---

## 2. Surgical Cancellation: Cơ chế "Dừng khẩn cấp"

Nếu Agent của bạn bị lặp vô tận (looping) hoặc đang thực thi một tool tốn kém, bạn cần một nút "Emergency Stop". Nhờ việc lưu trữ các task đang chạy trong `self._active_tasks` theo `session_key`, chúng ta có thể thực hiện dừng chính xác tác vụ đó:

```python
async def _handle_stop(self, msg: InboundMessage) -> None:
    """Hủy toàn bộ active tasks của một session cụ thể."""
    tasks = self._active_tasks.pop(msg.session_key, [])
    cancelled = sum(1 for t in tasks if not t.done() and t.cancel())
    
    for t in tasks:
        try:
            await t # Đảm bảo task đã dừng hẳn
        except (asyncio.CancelledError, Exception):
            pass
            
    # Hủy luôn các sub-agents đang chạy liên quan
    await self.subagents.cancel_by_session(msg.session_key)
```

Việc quản lý task theo session giúp hệ thống đa người dùng hoạt động ổn định: Dừng task của người dùng A không ảnh hưởng đến tiến trình của người dùng B.

---

## 3. Real-time Progress qua Async Callbacks

Người dùng sẽ cảm thấy rất "bất an" nếu màn hình đứng yên trong 30 giây khi AI đang suy nghĩ. Một kiến trúc Agent tốt cần stream được tiến độ thực hiện (progress) về client ngay khi nó đang diễn ra.

![Streaming Feedback Loop](/images/posts/async-agent-loop-engineering/streaming-feedback.png)
*Minh họa cách Assistant Thought và Tool Call Result được gửi về UI thông qua Async Callback trong khi Loop vẫn đang chạy*

```python
# Stream suy nghĩ và công cụ đang dùng trong lúc chạy loop
if response.has_tool_calls:
    if on_progress:
        thought = self._strip_think(response.content)
        if thought:
            # Gửi suy nghĩ (thought) về UI ngay lập tức
            await on_progress(thought)
        # Gửi hint về công cụ (tool) chuẩn bị được gọi
        await on_progress(self._tool_hint(response.tool_calls), tool_hint=True)
```

Nhờ `await`, việc gửi tiến độ không làm block logic chính của Agent, tạo ra trải nghiệm UX mượt mà, giúp người dùng biết Agent vẫn đang "sống".

---

## 4. Lock Management: Đảm bảo tính nhất quán (Consistency)

Dù chạy async để tăng hiệu suất, nhưng việc thay đổi trạng thái session (history, memory) cần sự cẩn trọng tuyệt đối để tránh **Race Condition**. Nếu không có Lock, hai message gửi gần nhau có thể ghi đè dữ liệu lên nhau.

```python
async def _dispatch(self, msg: InboundMessage) -> None:
    """Xử lý message dưới một global lock để đảm bảo thứ tự."""
    async with self._processing_lock:
        try:
            response = await self._process_message(msg)
            if response is not None:
                await self.bus.publish_outbound(response)
        except asyncio.CancelledError:
            logger.info("Task cancelled for session {}", msg.session_key)
            raise
```

Sử dụng `asyncio.Lock()` đảm bảo rằng dù ta nhận message không đồng bộ, nhưng việc cập nhật trạng thái hệ thống và sinh phản hồi luôn diễn ra theo một trình tự an toàn.

---

## Tổng kết

Việc khai thác `asyncio` trong Agent Loop không chỉ đơn thuần là để chạy nhanh hơn. Đó là về:
1. **Responsiveness**: Luôn lắng nghe và phản hồi người dùng bất cứ lúc nào.
2. **Controllability**: Khả năng can thiệp và dừng các tác vụ sai lầm ngay lập tức.
3. **Observability**: Minh bạch hóa quá trình suy nghĩ của AI theo thời gian thực.

Nếu bạn đang xây dựng một Agent System nghiêm túc, hãy đầu tư vào một **Async Heartbeat**. Đó là sự khác biệt giữa một script chạy tự động đơn giản và một hệ thống Agent thực thụ.
