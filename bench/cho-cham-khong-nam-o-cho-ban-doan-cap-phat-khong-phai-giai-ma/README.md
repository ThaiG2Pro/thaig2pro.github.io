# Where the cost of a 60-version chain was

Directory: `bench/cho-cham-khong-nam-o-cho-ban-doan-cap-phat-khong-phai-giai-ma/`

Supporting evidence for the post *"I Explained a Slow Read and Wrote It Down. The Ratio That Disproved It Was Already in the Table."*.

The code under test is my toy database [minidb](https://github.com/ThaiG2Pro/mini-kv-db)
(Go, no dependencies). This directory does not copy its source; `run.sh` clones the
public repo at three pinned commits (plus 807b7be, where `BenchmarkCopyVsAlloc` was added) and runs the same two benchmarks the post quotes.

## The question

In minidb every version of a row lives in one record, newest first. A read walks the
chain and returns the first version its snapshot can see. At 60 versions a read was
8.5x slower than at 1 version. **Where is that cost?** Two candidates:

- in *walking and decoding* the chain (then a reader that needs the last version should
  pay more than one that needs the first), or
- in something done once per read regardless of which version is wanted.

## Method

- `BenchmarkGetChainDepth` in `internal/txn/bench_test.go`: a key with 1 or 60 versions,
  read by a fresh snapshot (`newest`) and by a snapshot older than the whole chain
  (`oldest`). `-benchtime=200000x`, `-benchmem`.
- `BenchmarkCopyVsAlloc` in `internal/btree/bench_test.go`: copy 897 bytes into an
  existing buffer vs `make` a new 1 KB slice then copy. Separates the two things pprof
  reports as one `memmove`.
- Three commits of minidb, run alternately: `348f120` (before: decode the whole chain,
  copy the value out), `e48552f` (fix 1: lazy decoding, the fix the hypothesis prescribed),
  `4a4ef0f` (fix 2: `GetFunc` view + `head()`). `BenchmarkCopyVsAlloc` is run from
  `807b7be`, the commit that added it.
- **Paired runs.** The author's machine is a laptop under WSL2 with other processes
  running; single numbers moved ±40%. `run.sh` therefore alternates before/after and
  `ratio.py` reports the median and quartiles of the **per-pair** ratio. If the
  interquartile range straddles 1.0, the honest answer is "no difference detected".

## How to run

Nothing is installed on your machine; the clones land in `src-*/` (git-ignored).

```bash
# with Docker (what produced results-docker-wsl2-20261005.txt), about 1.5 minutes
docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp -e GOCACHE=/tmp/gocache \
  -e GOPATH=/tmp/gopath -e GOFLAGS=-buildvcs=false -v "$PWD:/b" -w /b golang:1.26 \
  bash -c 'git config --global --add safe.directory "*"; ./run.sh 10'

# or with local Go 1.26+ and git
./run.sh 10
```

`run.sh` ends by calling `ratio.py` on the file it just wrote. To re-read an older run:
`./ratio.py results-docker-wsl2-20261005.txt`. Do not pass a glob: `ratio.py` reads one
file, and a glob would silently pick the oldest result in the directory.

Expected, in order: 30 `## pair` blocks of four `Benchmark` lines, then the copy/alloc
lines, then the file name, then `ratio.py` prints the finding (three `oldest/newest` ratios all near 1.0)
and the per-benchmark `fix1/before` and `after/before` ratios.

## What the clean run showed

`golang:1.26` image (go1.26.8), host WSL2 on an i5-1235U, 2026-10-05, 10 pairs
(`results-docker-wsl2-20261005.txt`):

| depth 60 | oldest / newest, median [Q1, Q3] | newest median | B/op |
|---|---|---|---|
| before | 1.03 [0.96, 1.15] | 1872 ns | 3585 |
| fix 1 | 1.05 [1.00, 1.08] | 1417 ns | 897 |
| fix 2 | 1.04 [0.96, 1.09] | 392 ns | 4 |

| per-pair ratio vs before | fix 1 | fix 2 |
|---|---|---|
| depth=1 newest | 1.01 [0.97, 1.26] | 0.88 [0.81, 1.01] |
| depth=60 newest | 0.77 [0.71, 0.81] | 0.21 [0.19, 0.24] |
| depth=60 oldest | 0.75 [0.74, 0.78] | 0.21 [0.18, 0.23] |

Copy vs alloc in the same container: copy 897 B 10.8–11.9 ns; `make` 1 KB + copy
449–696 ns (about 40–60x; the host is still WSL2, see the limits below).

Reading: the reader that needs the last version never paid more than the one that
needs the first, on any of the three commits. Fix 1 removed the decoded array (3585 to
897 B) and bought about a quarter, equally for both readers, which is what the
hypothesis said should not happen. Fix 2 took both to a fifth. Depth 60 after fix 2 is
still 2.2x depth 1 (392 vs 177 ns): the tail check.

## Results the post quotes (author's machine)

Author's runs, WSL2, Intel i5-1235U, 2026-10-01 (minidb `diary/phase9.md`, table 10):

| | before (median) | after (median) | after/before, median [Q1, Q3] |
|---|---|---|---|
| depth=1 newest | 348 ns | 299 ns | 0.85 [0.80, 0.88] |
| depth=60 newest | 5213 ns | 708 ns | 0.14 [0.13, 0.16] |
| depth=60 oldest | 3878 ns | 714 ns | 0.18 [0.17, 0.19] |
| bytes allocated per read, depth=60 | 3585 | 4 | |

Phase 6 numbers (same benchmark, 2026-09, `diary/phase6.md`): depth=60 newest 1450 ns,
oldest 1480 ns (oldest/newest 1.02; the diary wrote 0.98, divided upside down), depth=1 171 ns.

Copy vs alloc:

| | WSL2 (2026-10-01) | bare Linux, Ryzen 7 H 255 (2026-10-01) |
|---|---|---|
| copy 897 B into existing buffer | 18–25 ns | 24–27 ns |
| `make` 1 KB + copy | 890–1865 ns | 154–193 ns |
| ratio alloc / copy | ~50x | ~7x |

## What this does not measure

- **The absolute cost of an allocation.** WSL2 reported ~1000 ns with 60% in page
  faults in the author's first reading; with page faults disabled (`GODEBUG=madvdontneed=0`, same day) it still cost about 550 ns, so page faults were not the main cost. Bare Linux reported 154–193 ns and no page-fault signature. The qualitative
  claim (allocation costs more than the copy) held on both; the magnitude is a property
  of the kernel and VM, not of the code. Quote the ratio, not the nanoseconds.
- **Disk.** Everything fits in the buffer pool; no I/O on the read path.
- **Concurrency.** One goroutine. Pin/unpin contention on the page is not exercised.
- **Whether the remaining 2.4x (708 vs 299 ns) can be removed.** It is the tail-check
  walk kept on purpose; removing it trades read speed for later detection of a
  corrupted chain. Not measured because not wanted.
- **Bare Linux for the paired run.** Both the author's 0.14 / 0.18 and the container's
  0.21 / 0.21 were produced on WSL2 hosts (Docker Desktop runs inside WSL2 too). The
  copy-vs-alloc ratio of 40–60x in the container is the WSL2 number again, not the ~7x
  of bare Linux. `run.sh` is here so someone can add that row.
- **Why the author's ratios were stronger (0.14 vs 0.21).** Unknown. Candidates: the
  author's "before" was measured on a noisier day, and the two runs used different Go
  patch versions. Not investigated.

Conditions that would reverse the conclusion: a chain layout where old versions live
elsewhere (undo log, separate page) makes the "copy the whole chain" cost disappear by
design, and the depth cost would then come back as the pointer-chasing phase 6 assumed.
