# bench/merge-conflict-copy-nhanh-thu-ba — a merge has two parents; a line from a third one is a bug

Supporting evidence for the post *"Resolving a conflict by copying the whole file from a
third branch"* (`content/posts/merge-conflict-copy-nhanh-thu-ba.en.md`).

## The question

Two branches conflict on one file. The conflict is "resolved" by copying the whole file
from a **third** branch that already contains both sides plus one unrelated line.

Question: **for that resolution, how many lines of the result cannot be traced to either
true parent of the merge relative to their merge-base, and which of two checks finds
them — (1) a one-sided diff that only asks "did any line disappear?", or (2) a two-parent
provenance diff?**

## The five parameters

| Parameter | Value |
|---|---|
| Baseline | the correct resolution: keep both sides' added lines, nothing else. Both checks must pass on it, otherwise they are useless |
| Dataset | a synthetic git repo built by `run.sh`: a 12-line middleware manifest (`kernel.txt`, plain text, not real code) plus one file per named class. Four branches: `main` (base), `staging` (adds 1 line), `feature` (adds 1 different line at the same spot, so the merge really conflicts), `development` (has both, plus 1 unrelated line and its class file). Three resolutions of the same `staging <- feature` merge: `correct`, `copy-third-branch`, `drop-a-line` (a control where verify 1 *does* fire) |
| Environment | git 2.43.0, bash, coreutils. Author/committer identity and dates are pinned, so every commit hash is identical on every machine |
| Runs | fully deterministic. Run twice locally on 2026-09-23; `results/summary.json` and `results/history.txt` byte-identical between runs. A second run is the "repetition" |
| Not measured | see the last section |

## Method

`verify-merge.sh <repo> <merge-commit> <path>` is the reusable check:

1. Take the merge's two true parents: `git show -s --format='%P'`.
2. Take their merge-base: `git merge-base p1 p2`.
3. Added lines of `base..merge` must be a subset of added lines of `base..p1` ∪ `base..p2`.
   Removed lines likewise. Anything outside is printed as `STRAY_ADDED` / `STRAY_REMOVED`.

`run.sh` also runs the check that was actually done in the incident (**verify 1**: diff the
result against the branch merged into, count only `-` lines, pass if 0) and a **boot check**
(every middleware named in the manifest must have a class file in that commit's tree; a
missing one stands in for the "class not found, every API route returns 500" failure).

## How to run

```bash
./run.sh
```

Writes `results/summary.json`, `results/run.log`, `results/history.txt`; the repo itself
goes to `raw/repo` (gitignored).

Actual output, 2026-09-23, git 2.43.0:

| Resolution | verify 1: `-` lines vs staging | verify 2: stray lines vs both parents | boot check |
|---|---|---|---|
| `correct` | 0 → PASS | 0 → PASS | PASS |
| `copy-third-branch` | 0 → **PASS (false negative)** | 1 added, `RateLimitByPlan` → FAIL | FAIL, class missing |
| `drop-a-line` | 1 → FAIL | 1 removed, `StartSession` → FAIL | PASS |

Reading: verify 1 catches lost lines but is blind to extra lines by construction, because
a line pulled in from a third branch is a `+` and verify 1 never looks at `+`. Verify 2 is
the same `git diff`, asked twice more with the right reference points, and it names the
stray line.

## What this does not measure

- **The incident's own numbers.** The 17h55' of failing `/api/*` routes and the two fix
  commits live in a private repository. Nothing here reproduces them; this bench only shows
  the detection mechanism on a stand-in. In the post those numbers are the author's account,
  this bench is the reproducible part — two different kinds of evidence (L-011).
- **Two layers, split in two.** The incident's copy from the third branch both *dropped* the
  merged-into branch's line and *added* a stray one. The bench models these separately:
  `copy-third-branch` is the state after the incident's first fix (both sides present, one
  stray line), `drop-a-line` is the lost-line layer on its own. No scenario has both at once.
- **The real crash.** No PHP runtime, no framework. The boot check is a stand-in: "name
  listed but class file absent in this tree". It shows the *condition*, not the 500.
- **Line-set, not line-position.** verify-merge.sh compares sets of line contents. A line
  that legitimately exists in a parent but was placed at the wrong position, or a
  duplicate of an existing line, is not flagged. Reordering middleware is a real bug class
  this check misses.
- **One file.** The check runs per path. The incident was also one file; a multi-file copy
  would need a loop over `git diff --name-only base..merge`.
- **Whitespace-only changes** are treated as real changes (`-U0`, no `-w`). Trailing-space
  noise would appear as stray lines. Deliberate: in a manifest, whitespace is content.
- **Scale.** 12 lines, 4 branches. Nothing here says how the check behaves on a file with
  hundreds of conflicting hunks; it says only that the false negative exists at any size.
