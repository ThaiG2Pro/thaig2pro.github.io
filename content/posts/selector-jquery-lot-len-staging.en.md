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

Nothing is the hard part. A crash has a stack trace; a wrong number has a wrong number. This had a modal that sat there and a user with no idea whether the system had heard them.

## What was actually broken

The screen is an internal admin panel for a promotions backend. An operator opens a modal to adjust the allocated quantity for one SKU in one campaign. The modal has two tabs — Increase and Decrease — and one submit button. Whichever tab is active decides which operation is sent.

On staging, **100% of Increase attempts were rejected by the server with HTTP 422**, and **zero of those rejections produced a message on screen**. Both figures come from a manual QC pass on staging, not from instrumentation; I say more about that below.

The rejection itself was correct behaviour. The server was refusing a request that asked to *decrease* the quantity by *zero* units — which is exactly what the browser sent, every single time, no matter which tab the operator had open.

---

## Dissecting it: two bugs wearing one coat

My first hypothesis was the server. A 422 on every request smells like validation rules that drifted out of sync with the form after a recent change. I read the rules, then read the request body in the network tab, and the hypothesis died right there: the rules were fine, the body was wrong. `adjustment_type` was `decrease` and `quantity` was `0` — on a form where I had just typed a positive number into the Increase tab.

So the payload was assembled wrong. The code that assembles it reads the active tab:

```js
// intent: which tab is the operator on?
const type = $('#adjustmentTabContent .nav-link.active').data('type');
```

`#adjustmentTabContent` is the container holding the two **panes** — the bodies of the tabs. The two clickable tab headers, which carry `.nav-link` and `data-type`, live in a `<ul>` *above* that container, not inside it. The selector was correct in isolation and correct in the parent, just not in that combination. It matched zero elements.

jQuery does not consider zero matches an error. `.data('type')` on an empty set returns `undefined`, the payload builder fell back to its default branch, and every submission went out as the default: decrease, quantity zero.

One selector, one line. But the reason nobody *saw* the failure is the actual subject of this post.

**Why no test caught it.** Every server-side feature test for this endpoint posts `adjustment_type` directly as a form field. That is the correct shape of a test for a controller, and also exactly the shape that never executes a line of the modal's JavaScript. The bug lived in the gap between "we have server tests" and "we have no browser tests" — both true, and the second one was nobody's ticket.

**Why nobody saw the error.** The server's 422 response was well formed — a map of field names to messages, the contract the front end expects. The front end did the standard thing: for each field in the map, find the input with that name and render the message next to it.

The input named `quantity` exists twice in this modal, once per tab, and the one the error was keyed to sat inside the pane that was not active. Bootstrap tabs hide the inactive pane with `display: none`. The message was written into the DOM correctly, attached to the correct element, and rendered into zero pixels. A well-formed error delivered into a container nobody can see is indistinguishable from silence.

---

## Trade-offs

Four options, and the selector fix was on the table alone at first.

- **Fix the selector, ship it.** One line, closes the ticket. Rejected as a complete fix because it leaves the swallowing in place: the next error keyed to any hidden field — and this modal has several — disappears the same way.
- **Delete the selector entirely: one submit handler per tab, type hard-coded.** Removes this class of bug entirely, since there is no lookup to get wrong. Rejected because it duplicates the submit path, the payload builder and the error rendering across two handlers, in a modal where all three are shared.
- **Fix the selector, and make error rendering visibility-aware** — chosen. After mapping each message to its field, check whether the target is actually visible; anything that cannot be shown in place falls through to a shared alert box at the top of the modal. Cost: a second rendering path to maintain, plus a rule that a message goes to exactly one of the two places, never both. The fallback text is also less precise than an inline message — it names the field instead of pointing at it.
- **Build browser-level coverage for the modal.** The only option that would have caught this before staging. Rejected for this ticket, not forever: there is no browser-test harness in the project, and standing one up is multi-day work needing an owner and a CI budget. Pretending it fits inside a bug fix is how it ends up half-built and disabled.

---

## Measured results

Two kinds of evidence, and it is worth keeping them apart.

The figures below come from a **manual QC pass on a private staging environment**: an operator ran the flow before and after the fix while I read the network tab. No instrumentation, no request counter, no error-rate dashboard. You cannot rerun them, and 100% means "every attempt in that session", not a rate measured over time.

- **Increase attempts rejected with 422:** 100% → 0%
- **Rejections visible to the operator:** 0 → all of them
- **Elements matched by the tab selector:** 0 → 1

What you *can* run is the mechanism, reconstructed from scratch as a single static page in [`bench/selector-jquery-lot-len-staging/`](https://github.com/thaig2pro/thaig2pro.github.io/tree/main/bench/selector-jquery-lot-len-staging): the same tab markup, the wrong selector next to the right one, and a fake 422 response you can route either to the hidden field or through the fallback alert. Open it in a browser and the message vanishes in front of you.

One thing got worse. The shared alert box adds a region at the top of the modal that can push the form down as it appears, and for a field that *is* visible the message is now reachable by two code paths, so the exclusivity rule is load-bearing. Break it and the operator sees the same complaint twice.

And one number did not move: **automated tests covering this path: 0 → 0.** The repro page is a demonstration, not a test. Nothing in CI fails if the selector breaks again tomorrow.

---

## Limits, and what I would do differently

The visibility check asks whether the element is currently rendered. That catches a hidden tab pane, which was my bug. It does not catch an element scrolled far out of view, one covered by an overlay, or one in a collapsed accordion that is technically laid out. Those still render into somewhere nobody looks.

The fallback is also only as good as the error contract. It handles messages keyed to a field name. An error the server returns without a field key, or keyed to a field this form does not contain, still has no home — I did not handle that case, and I do not know how often it happens.

What I would do differently is not about selectors at all. I spent the first stretch of debugging on the server because the 422 pointed there, when the strongest signal available was that **the user saw nothing** — and "no feedback" is a front-end fact, always. I now treat silence as its own bug, logged separately from whatever caused it. The selector was a one-line fix; the silence is what made it expensive to find, and it would have outlived the fix.

A system that fails loudly gets debugged. A system that fails politely gets a bug report that says "clicking it does nothing".
