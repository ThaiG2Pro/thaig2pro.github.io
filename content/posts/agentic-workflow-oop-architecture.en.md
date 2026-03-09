---
title: "Analyzing Agentic Workflow Architecture via OOP: A loop.py Case Study"
date: 2026-03-06T14:00:00+07:00
draft: false
description: "A real-world analysis of how Encapsulation, Abstraction, Composition, and Polymorphism are applied to build production-ready ReAct orchestration loops for AI Agents."
tags: ["AIAgent", "Python", "SoftwareArchitecture", "OOP", "CleanCode"]
categories: ["System Architecture"]
author: "Hoang Nguyen Thai"
showToc: true
TocOpen: true
cover:
    image: "images/posts/agentic-workflow-oop-architecture/loop-oop.png"
    alt: "Agentic Workflow Architecture in real-world source code"
---

Last month, when I started building an AI Agent system, I began with a simple script of about 200 lines. Everything worked perfectly until I added the fifth tool and started handling asynchronous tasks. The code quickly devolved into an un-debuggable mess of spaghetti code.

That's when I realized: Building an AI Agent isn't just about writing prompts or calling LLM APIs. It is a **Software Engineering** problem. The `loop.py` file that I subsequently redesigned stands as a testament to applying the four classic OOP principles to control the complexity of the ReAct (Reasoning and Acting) loop.

---

## 1. Encapsulation: Preventing Context Poisoning

In my architecture, the `AgentLoop` class operates as a closed state machine. Encapsulation here isn't just to make the code look "cleaner"—it solves a fatal flaw: **Context poisoning**. When an LLM returns an error response (e.g., HTTP 400), if not isolated, this error gets written into the conversation history, trapping the Agent in an endless loop of failures.

- **Implementation:** I locked down sensitive logic like `_run_agent_loop` and `_process_message` as private methods. The `self._running` state and `self._processing_lock` ensure the Agent never processes messages concurrently or falls into race conditions.

```python
class AgentLoop:
    def __init__(self, ...):
        self._running = False
        self._processing_lock = asyncio.Lock()

    async def run(self) -> None:
        """The single entry point for external interaction"""
        async with self._processing_lock:
            self._running = True
            await self._run_agent_loop()
```

---

## 2. Abstraction: Preventing Vendor Lock-in

When OpenAI experienced a widespread outage, I needed to switch to Anthropic's Claude immediately. If I had hardcoded OpenAI API calls within the loop, the entire system would have been paralyzed.

- **Solution:** `AgentLoop` only communicates with an abstract interface: `LLMProvider`.
- **Implementation:** At runtime, `self.provider` can be any model. `AgentLoop` doesn't need to know how preparing a payload for GPT-4 differs from Claude 3.5.

```python
# Invoke LLM through a generic interface, immune to Vendor changes
response = await self.provider.chat(
    messages=messages,
    tools=self.tools.get_definitions(),
    model=self.model,
)
```

---

## 3. Composition: Solving the "Diamond Problem"

**What I tried and failed:** Initially, I used Inheritance to create a `CoderAgent` inheriting from a `BaseAgent`. But when I needed an Agent that could both code and search the web (a Researcher), the inheritance hierarchy collapsed due to multiple inheritance issues (the Diamond problem).

- **Solution:** I switched to Composition ("Has-a"). I designed `AgentLoop` as an orchestrator that doesn't do the heavy lifting itself, but instead coordinates specialized modules.
- **Structure:** 
    - `self.context = ContextBuilder()`: Handles prompt building.
    - `self.sessions = SessionManager()`: Manages memory.
    - `self.tools = ToolRegistry()`: Manages skills.

```python
def __init__(self, ...):
    # AgentLoop doesn't manage memory or tools directly; it owns modules that do
    self.context = ContextBuilder(workspace)   
    self.sessions = SessionManager(workspace)   
    self.tools = ToolRegistry()                 
```

---

## 4. Polymorphism: Plug-and-Play Architecture

How does the Agent know how to call a web search tool versus a local file-reading tool, given that their underlying mechanics are entirely different? The answer is Polymorphism.

- **Implementation:** Every tool (from `ReadFileTool` to `WebSearchTool`) adheres to a common interface containing an `execute()` method.
- **Benefit:** Inside the ReAct loop, the tool execution code remains completely static. When I need to plug in a new protocol like MCP (Model Context Protocol), I don't have to modify a single line of code inside `loop.py`.

```python
# A single call, but the execution behavior morphs based on the specific Tool
for tool_call in response.tool_calls:
    result = await self.tools.execute(tool_call.name, tool_call.arguments)
    messages = self.context.add_tool_result(messages, tool_call.id, tool_call.name, result)
```

---

## Minimalist System Diagram

The diagram below illustrates the seamless coordination of the four OOP pillars to create a complete orchestration engine:

![Agentic Workflow Architecture](/images/posts/agentic-workflow-oop-architecture/loop-oop.png)
*Figure 1: The orchestration architecture of AgentLoop.*

---

## The Takeaway

The difference between a "fun prototype" and a production-grade AI system doesn't lie in how cleverly you write your prompts. It lies in how you organize your software architecture. 

The lesson I learned after tearing down and rebuilding `loop.py`: **The Language Model (LLM) is the brain, but without a solid architectural skeleton, that brain cannot support a body capable of enduring sustained, real-world operation.**
