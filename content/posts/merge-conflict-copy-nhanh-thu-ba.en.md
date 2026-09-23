---
title: "A Merge Has Exactly Two Parents. The Line From a Third Branch Took Down Every API Route."
date: 2026-09-23T14:42:00+07:00
draft: false
description: "A conflict in the HTTP kernel was resolved by copying the whole file from a third branch. One middleware line came along, its class did not, and /api/* returned 500 for almost 18 hours."
tags: ["git", "merge-conflict", "laravel", "incident", "code-review"]
categories: ["Engineering"]
author: "Hoang Nguyen Thai"
showToc: true
TocOpen: true
cover:
    image: "/images/posts/merge-conflict-copy-nhanh-thu-ba/cover.png"
    alt: "A merge commit with two parents, and a third branch feeding one extra line into the resolved file"
---

For 17 hours and 55 minutes, every route under `/api/*` on staging answered with a fatal error. The merge that caused it landed at 17:18 one evening; the fix that ended it landed at 11:13 the next morning. That duration is from the private repository and the server log, so you cannot verify it; read it as my account.

The merge itself was ordinary: a feature branch into staging, one conflict, in the file that registers HTTP middleware. The conflict was real, both sides had added a line at the same spot. What went wrong was not the conflict. It was how the conflict was "resolved", and then how the result was checked and declared fine.

---

## Dissecting it: a resolve that was fast, and a check that was one-sided

The framework's HTTP kernel is a list. Every middleware that runs on a request is named there, in order. Staging had added one line to the API group. The feature branch had added a different line at the same position. Git stopped and asked which to keep.

The answer chosen was neither. The development branch, a third branch that was not one of the two being merged, already had the feature side's line, because the feature had been integrated there earlier. So the whole file was copied from development over the conflicted one, staged, and committed. Faster than reading the conflict markers, and it looked like the merge had already been done somewhere.

It had not. Development did not have staging's line, so the copy dropped it. That is the first layer of damage: a resolve that was supposed to keep both sides kept one.

The second layer is the one that crashed. Development also had one more line in that group: another ticket had registered a rate-limiting middleware there. It was backed by a package installed on development and never on staging. The copy brought the registration line and nothing else. On staging, the kernel now named a class that did not exist on disk. The framework resolves that class on every request that passes through the API group, so every API request failed the same way.

Why did the check after the resolve not catch it? Because of the question it asked. The check was a diff of the resolved file against the branch being merged into, read with one question in mind: *did any line disappear?* Every line in the diff was a `+`. No `-`. Passed. The question that was never asked was the one that mattered: *does each of these `+` lines belong to one of the two sides of this merge?* One of them did not. The first fix restored the dropped line and went out verified the same one-sided way: zero lines missing, pass. The stray line was still in the file. It took the server log to say so.

The second time I checked differently, and this is the mechanism the rest of the post is about. A merge commit has exactly two parents, and git will tell you which:

```bash
git show -s --format='%P' <merge-commit>      # two hashes, p1 and p2
git merge-base p1 p2                          # where they forked
```

Relative to that merge-base, parent 1 added some lines and parent 2 added some lines. The resolved file may add the union of those and nothing more. Any `+` line in `base..merge` that is not a `+` line in `base..p1` or `base..p2` came from somewhere else. Same rule for `-` lines. Three diffs instead of one, all against reference points the merge itself defines. Run that way, the second fix showed zero lines whose origin could not be explained.

---

## Trade-offs

- **Re-do the merge by hand, from the conflict markers.** Available, and it would have produced the same correct file. I did not take it, because the bad merge was already on the branch and I wanted a check that works on any merge commit *after the fact*, not only on one I am about to make. Re-resolving fixes this merge; a provenance check can be pointed at the last twenty.
- **Keep the one-sided diff, read it more carefully.** Rejected. Reading harder is not a control. The diff against a single reference cannot distinguish "a line the other parent added" from "a line a third branch added", because both show as `+`. The information is not in that diff; no amount of attention puts it there.
- **Compare against both true parents** (chosen). Cost: six `git diff` calls at three reference points, and 38 lines of shell. It also came with a rule I now hold as absolute. Never take content from a branch that is not one of the two parents to resolve a conflict between them, no matter how "complete" that branch looks. The check is a line-set comparison, so it is blind to ordering, and I will come back to that below.
- **Install the missing package on staging instead.** Rejected. That would make the stray line stop crashing while leaving it stray. The rate limiter belonged to another ticket. Making the symptom go away is not the same as removing the line that had no right to be there.

---

## What changed, measured

Two kinds of evidence here, and I keep them apart.

From the incident, which you cannot re-run:

| Metric | Before | After |
|---|---|---|
| `/api/*` on staging returning 500 | 17h55' | 0 errors after the second fix |
| First verification (one reference, "any line missing?") | 0 lines missing, 1 stray line let through | |
| Second verification (both true parents) | | 0 lines with unexplained origin |

From the bench, which you can. [`bench/merge-conflict-copy-nhanh-thu-ba`](https://github.com/thaig2pro/thaig2pro.github.io/tree/main/bench/merge-conflict-copy-nhanh-thu-ba) builds a small git repository from scratch, no company code: a 12-line middleware manifest, four branches (base, staging, feature, development), a real conflict, and the same merge resolved three ways. One command runs everything and writes the results.

| Resolution | One-sided check: `-` lines vs staging | Two-parent check: stray lines | Boot check |
|---|---|---|---|
| Correct, keep both sides | 0, pass | 0, pass | pass |
| Copy the file from development | 0, **pass, wrongly** | 1 added, `RateLimitByPlan`, fail | fail, class missing |
| Correct but drop one base line | 1, fail | 1 removed, `StartSession`, fail | pass |

The third row is a control: it shows the one-sided check does catch what it was designed to catch. The second row is the incident after its first fix: both sides present, one stray line. The one-sided check passes on it by construction, not by bad luck. The incident's original copy also dropped staging's line, which is the third row's failure; the bench keeps the two layers in separate scenarios so each check's blind spot shows on its own. The boot check is a stand-in for the 500: every name in the manifest must have a class file in that commit's tree. Commit hashes are pinned, so two runs on two machines produce byte-identical output.

---

## Limits, and what I would do differently

**What the check does not see.** It compares sets of line contents, not positions. A line that both parents legitimately have, placed in the wrong order by the resolve, passes. In a middleware list, order is behavior, so that is a real class of bug this check misses. It also runs per file; a copy that touched several files needs a loop over the changed paths. And it treats whitespace as content, which is right for a manifest and noisy for anything else. The bench is 12 lines and four branches; it shows the false negative exists, not how the check behaves on a file with hundreds of conflicting hunks.

**What the bench does not show.** No framework, no PHP, no 500. The boot check demonstrates the condition, "registered but absent", not the crash. And nothing here reproduces the 17h55'; that number lives in a log you cannot read.

**What I would do differently.** The resolve took a shortcut because the correct content was visibly sitting in another branch. Next time that temptation shows up, I will treat it as the signal it is: if a third branch has the answer, the two parents together have the same answer, and the only thing the third branch can add is something that does not belong. And I will run the two-parent diff before pushing any conflict resolve, not after the log tells me to.
