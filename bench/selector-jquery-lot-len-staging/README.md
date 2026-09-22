# bench/selector-jquery-lot-len-staging — an error message that renders into zero pixels

Supporting evidence for the post *"Every Increase Failed With 422, and the User Saw
Nothing At All"* (`content/posts/selector-jquery-lot-len-staging.en.md`).

## The question

Two things went wrong in one modal, and only one of them is interesting.

1. A jQuery selector pointed at the container holding the tab **panes** instead of the
   `<ul>` holding the tab **headers**, so it matched zero elements. `.data('type')` on an
   empty set returns `undefined`, the payload builder fell through to its default branch,
   and every Increase went over the wire as a Decrease of zero.
2. The server's 422 was well formed. The front end rendered it correctly, next to the
   input the error was keyed to — an input sitting inside the tab pane that was not
   active, which Bootstrap hides with `display: none`.

Question: **what does a test that checks "did we render the server's error?" actually
prove?**

Answer: nothing the operator can use. That assertion is green in exactly the run where
the operator sees an unchanged screen.

## Method

`index.html` reconstructs the mechanism outside the original codebase: the same tab
markup, real jQuery (3.7.1 slim, vendored in `vendor/`), tab switching that hides the
inactive pane with `display: none`, two inputs named `increase_quantity` and
`decrease_quantity`, and a fake server that answers with a well-formed 422 keyed to a
field name.

Two config flags, settable in the page or as query parameters:

| Flag | `1` (default) | `0` |
|---|---|---|
| `broken` | selector is `#adjustmentTabContent .nav-link.active` — matches 0 | selector is `#adjustmentTabs .nav-link.active` — matches 1 |
| `naive` | render each message next to its input, unconditionally | check whether the target is visible; anything that is not falls through to a shared alert box |

`specs/adjust-quantity.spec.ts` is the spec file that was never written in the original
ticket. It is one file, it opens the modal, clicks Increase, and asserts what goes over
the wire.

## How to run

```bash
./run.sh
```

That runs the suite inside `mcr.microsoft.com/playwright:v1.63.0-noble` as your own uid,
installs `@playwright/test` once, and needs nothing on your machine but Docker. To poke
at it by hand instead, open `index.html` in any browser — no server, no build step — and
use the checkboxes at the top.

Actual output, 2026-09-22, copied verbatim from the `list` reporter:

```
Running 6 tests using 1 worker

  ✓  1 specs/adjust-quantity.spec.ts:17:7 › bug 1 — the selector matches zero elements › broken selector: an Increase of 5 is submitted as a Decrease of 0 (2.4s)
  ✓  2 specs/adjust-quantity.spec.ts:31:7 › bug 1 — the selector matches zero elements › fixed selector: the same click submits an Increase of 5 (1.3s)
  ✓  3 specs/adjust-quantity.spec.ts:48:7 › bug 2 — the error renders into zero pixels › naive rendering: the message is in the DOM and invisible (1.4s)
  ✓  4 specs/adjust-quantity.spec.ts:70:7 › bug 2 — the error renders into zero pixels › visibility-aware rendering: the same 422 reaches the operator (1.4s)
  ✓  5 specs/adjust-quantity.spec.ts:82:7 › bug 2 — the error renders into zero pixels › naive rendering is fine when the field is on screen (1.2s)
form moved down 59px
  ✓  6 specs/adjust-quantity.spec.ts:93:7 › the cost of the fallback box › the shared alert pushes the form down when it appears (1.4s)

  6 passed (12.6s)
```

The per-test durations vary between runs; `form moved down 59px` and the pass/fail
column do not.

Every test is green on purpose. The suite describes what happens; it is not a
before/after where half of it is supposed to be red.

## Where the finding is

Test 3. Both assertions below describe the **same run**, with the broken selector and
naive rendering:

```ts
// "Did we render the server's error?" — green.
await expect(message).toHaveCount(1);
await expect(message).toHaveText('The quantity must be at least 1.');

// What the operator saw.
await expect(message).toBeHidden();
expect(await message.boundingBox()).toBeNull();
```

`boundingBox()` returning `null` is the whole post in one line: the element exists, it
carries the right text, it is attached to the right input, and it occupies no space on
screen. A well-formed error delivered into a container nobody can see is
indistinguishable from silence.

Test 5 is the control. With the selector fixed, the 422 lands on the field the operator
is looking at, and naive rendering shows it inline — so the swallowing is not "the error
code is broken", it is "the error code has a blind spot nobody measured".

Test 6 checks the cost of the chosen fix rather than its benefit: the shared alert box
is in normal flow at the top of the modal, so it displaces the form when it appears. On
the 900×900 Desktop Chrome viewport this repro uses, that is 59px. The number is a
property of this page's styling, not of the production modal — what it verifies is the
direction of the claim, not its magnitude.

## Verified on

- `mcr.microsoft.com/playwright:v1.63.0-noble`, `@playwright/test` pinned to `1.63.0`,
  Chromium as shipped in that image.
- jQuery 3.7.1 slim, vendored — the repro runs with no network once the image is pulled.

`package.json` pins the exact Playwright version because the runner and the browser
image must match; a caret range here resolved to 1.63.0 against a 1.60.0 image and every
test failed to launch a browser. To move forward, bump both together.

## What this does not measure

- **Anything from the real incident.** The 100% rejection rate and the zero visible
  errors come from a manual QC pass on a private staging environment. This page cannot
  produce those figures and does not try to. It reconstructs the mechanism only.
- **How many fields the real modal hides.** This repro has exactly one input per pane,
  which is enough to show the mechanism: a message keyed to a field inside a pane with
  `display: none` renders into zero pixels. How many such fields the production modal
  holds was never counted, so neither the post nor this page puts a number on it.
- **Bootstrap.** The tab behaviour is hand-rolled in about ten lines, because the only
  part that matters is `display: none` on the inactive pane. If your tab library hides
  panes some other way — `visibility: hidden`, zero height, off-screen positioning —
  `boundingBox()` and jQuery's `:visible` will disagree with each other, and the
  visibility-aware renderer would need a different test.
- **The three cases the fix does not cover**, listed in the post's limits section: an
  element scrolled out of view, one covered by an overlay, and one inside a collapsed
  accordion that is still laid out. All three are visible to `:visible` and to
  `boundingBox()`, so this check would pass while the operator still sees nothing.
- **Whether any of this was worth doing.** Nobody re-ran the QC pass on the real system
  after the fix. There is no "after" number in the post for that reason.
