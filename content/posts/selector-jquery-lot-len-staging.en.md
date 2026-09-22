---
title: "Every Increase Failed With 422, and the User Saw Nothing At All"
date: 2026-09-22T10:00:00+07:00
draft: false
description: "A jQuery selector pointed at the wrong container and matched zero elements, so every Increase was submitted as a Decrease of zero. The worse half: the server's 422 landed inside a hidden tab pane, so the error rendered into nothing."
tags: ["jquery", "frontend", "validation", "error-handling", "debugging", "staging"]
categories: ["Engineering"]
author: "Hoang Nguyen Thai"
showToc: true
TocOpen: true
cover:
    image: "/images/posts/selector-jquery-lot-len-staging/cover.png"
    alt: "A validation error message rendered inside a hidden tab pane, invisible to the user"
---

QC's bug report had two sentences. Clicking **Increase** in the adjust-quantity modal did nothing. Clicking it again also did nothing.

"Nothing" is the worst symptom to be handed. A crash leaves a stack trace, a wrong result leaves a wrong number; an unchanged screen leaves no starting point at all.

## What was actually broken

The screen is an internal admin panel for a promotions backend. An operator opens a modal to adjust the allocated quantity for one SKU in one campaign. The modal has two tabs — Increase and Decrease — and one submit button. Whichever tab is active decides which operation is sent.

On staging, **100% of Increase attempts were rejected by the server with HTTP 422**, and **zero of those rejections produced a message on screen**. Both figures come from a manual QC pass on staging, not from instrumentation; I say more about that below.

The odd part is that nothing on the server was wrong. The validation rules were the rules we wanted, the 422 was the correct response to the request that arrived, and the response body was well formed. There was no server-side line to fix, and the operation still failed on every attempt.

---

## Dissecting it: two bugs wearing one coat

I spent the first stretch on the server anyway, because a 422 on every request looks like validation rules that drifted out of sync with the form. Reading the request body in the network tab ended that: the rules were fine, the body was wrong. `adjustment_type` was `decrease` and `decrease_quantity` was `0` — on a form where I had just typed a positive number into the Increase tab. The browser had been asking to decrease by zero, and the server had been right to say no.

So the payload was assembled wrong. The code that assembles it reads the active tab:

```js
// intent: which tab is the operator on?
const type = $('#adjustmentTabContent .nav-link.active').data('type');
```

`#adjustmentTabContent` is the container holding the two **panes** — the bodies of the tabs. The two clickable tab headers, which carry `.nav-link` and `data-type`, live in a `<ul>` *above* that container, not inside it. The selector was correct in isolation and correct in the parent, just not in that combination. It matched zero elements.

jQuery does not consider zero matches an error. `.data('type')` on an empty set returns `undefined`. The payload builder fell back to its default branch. Every submission went out the same way: decrease, quantity zero.

The root cause was the quick part: one wrong selector, one line to fix. What makes the bug worth writing up is how it survived each layer of checking, and then failed in front of the operator without leaving a trace.

**Why did no test catch it?** Every server-side feature test for this endpoint posts `adjustment_type` directly as a form field. That is the correct shape of a test for a controller, and also exactly the shape that never executes a line of the modal's JavaScript.

The comfortable explanation would be that the project has no browser tests. That explanation is false, and I checked before writing it down. Playwright is declared in the project's `package.json`, and eight other changes in the same repository ship their own spec folder and config. The tooling was there. Colleagues were using it that same month. This change simply had no spec folder of its own — so the gap was never in the toolchain. It was in what this piece of work counted as finished.

**And why did nobody see the error?** The server's 422 response was well formed — a map of field names to messages, the contract the front end expects. The front end did the standard thing: for each field in the map, find the input with that name and render the message next to it.

Each tab carries its own input — `increase_quantity` and `decrease_quantity` — so the field name in the error decides which one gets the message. It named the one sitting inside the pane that was not active. Bootstrap tabs hide the inactive pane with `display: none`. The message was written into the DOM correctly, attached to the correct element, and rendered into zero pixels. A well-formed error delivered into a container nobody can see is indistinguishable from silence.

---

## Trade-offs

The selector fix was on the table alone at first. By the end there were four.

- **Fix the selector, ship it.** One line, closes the ticket. Rejected as a complete fix because it leaves the swallowing in place: the input this error was keyed to is still one tab away, and any later error keyed to a field in a closed pane disappears the same way.
- **Delete the selector entirely: one submit handler per tab, type hard-coded.** Removes this class of bug entirely, since there is no lookup to get wrong. Rejected because this modal shares three things: the submit path, the payload builder, and the error rendering. Splitting the tabs duplicates all three.
- **Fix the selector, and make error rendering visibility-aware** — the one I picked. After mapping each message to its field, check whether the target is actually visible; anything that cannot be shown in place falls through to a shared alert box at the top of the modal. The cost comes in three parts: a second rendering path to maintain; a rule that each message appears in exactly one of the two places, never both; and fallback text that is less precise than an inline message, because it names the field instead of pointing at it.

There was a fourth option, and it is the only one that would have caught this *before* staging: a browser-level spec for the modal. One spec file would have covered it: open the modal, click Increase, assert what goes over the wire. It did not happen, and not because the harness was missing — the harness exists, and it was in active use elsewhere in the same repository. The real reason is that the work was scoped as a front-end bug fix, and nothing in the process asked for a test before it was called done.

---

## Measured results

Two kinds of evidence, and it is worth keeping them apart.

The figures below come from a **manual QC pass on a private staging environment**, before the fix. They describe that session accurately. They are not long-run statistics.

- **Increase attempts rejected with 422:** 100%
- **Rejections visible to the operator:** 0

The "after" column is missing on purpose, because there is nothing honest to put in it. Nobody ran the QC pass again. I have no measured figure for the fixed behaviour, only the change itself.

What you *can* run is the mechanism, reconstructed from scratch as a static page in [`bench/selector-jquery-lot-len-staging/`](https://github.com/thaig2pro/thaig2pro.github.io/tree/main/bench/selector-jquery-lot-len-staging): the same tab markup, the wrong selector next to the right one, and a fake 422 response you can route either to the hidden field or through the fallback alert. Open it in a browser and the message vanishes in front of you.

The same folder holds the spec this work never got: one Playwright file that opens the modal, clicks Increase, and asserts what goes over the wire. `./run.sh` runs it in a container. The test that matters makes two assertions about the same run — the message is in the DOM, and `boundingBox()` returns null.

One thing got worse. The shared alert box adds a region at the top of the modal that can push the form down as it appears, and for a field that *is* visible the message is now reachable by two code paths, so the exclusivity rule is load-bearing. Break it and the operator sees the same complaint twice.

And one count stayed exactly where it was: browser specs covering this modal, from 0 to **0**.

That one I can check rather than remember. The fix is a single commit touching a single view template, and it adds no test file. Five days later it is still the last commit on the branch.

So the loop closes on itself: the harness was available, this change did not use it, a JavaScript bug reached staging, the fix shipped without a test, and no one ran the QC pass again. Every step is individually reasonable. Together they guarantee the next one lands the same way.

---

## Limits, and what I would do differently

The visibility check asks whether the element is currently rendered. That catches a hidden tab pane, which was my bug. It does not catch three other cases:

- an element scrolled far out of view
- one covered by an overlay
- one inside a collapsed accordion that is technically laid out

All three still render the message somewhere nobody looks.

The fallback is also only as good as the error contract. It handles messages keyed to a field name. An error the server returns without a field key, or keyed to a field this form does not contain, still has no home — I did not handle that case, and I do not know how often it happens.

What I would do differently is not about selectors at all. I followed the 422 to the server because a status code is a loud signal, when the strongest signal I actually had was that **the user saw nothing** — and "no feedback" is a front-end fact, always. I now treat silence as its own bug, logged separately from whatever caused it. The selector was a one-line fix; the silence is what made it expensive to find, and it would have outlived the fix.

A system that fails loudly gets debugged. A system that fails politely gets a bug report that says "clicking it does nothing".
