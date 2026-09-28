# bench/khong-them-index-viet-nguong-leo-thang-thanh-so — how far does "no index yet" scale?

Supporting evidence for the post *"I Wrote the Index Escalation Threshold as a Number,
Then Measured It and Found It Off by 15x to 100x"* (`content/posts/khong-them-index-viet-nguong-leo-thang-thanh-so.en.md`).

## The question

A voucher filter was merged against a table the team does not own, with **no index** on
the lookup column, and a written trigger for asking the owning team: *"more than ~1M
rows OR p95 above 300 ms"*. The trigger was already in the design record; a linear
extrapolation from one EXPLAIN on staging (3.2K rows, under 1 ms) was written afterwards
as its basis: about 1 ms at 100K rows, about 10 ms at 1M.

Two questions this bench answers:

1. Is the linear extrapolation right? At what row count does the query cross 300 ms?
2. Was the rejected `OR` shape (`voucher_code = ? OR voucher_serial = ?`) really unable
   to use indexes?

## Method

`bench.sql` builds two tables with generic names (`orders`, `order_vouchers`, ~2.14
vouchers per order like staging), fills them from MariaDB's `seq_` engine, then times
one correlated `EXISTS` lookup — the shape the order grid uses — **5 runs per variant,
each run against a different existing voucher**, timed server-side with `SYSDATE(6)`
so client round-trips do not count. Median is the 3rd of 5 sorted runs.

| Variant | What it is |
|---|---|
| `single-noindex` | as shipped: one column, no index |
| `single-index` | the deferred fix: NON-UNIQUE index on `voucher_code` |
| `or-both-indexed` | the rejected shape, with both columns indexed |

Sizes: 3,217 rows (the staging count), 100,000, 1,000,000.

## How to run

```bash
./run.sh                                  # mariadb:latest, sizes 3217 100000 1000000
MARIADB_IMAGE=mariadb:10.11 ./run.sh      # another version
./run.sh 3217 50000                       # other sizes (max 1,000,000)
```

Only Docker is needed. The script starts a throwaway container, feeds `bench.sql` once
per size, prints the plans and the timing table, and removes the container. About 2
minutes per version on the machine below.

## Results (2026-09-28, verbatim in `results-13.0.txt` and `results-10.11.txt`)

Machine: 12th Gen Intel(R) Core(TM) i5-1235U, WSL2, Docker 29.6, default MariaDB config (128 MB buffer pool).

Median ms of the lookup, `order_vouchers` row count across:

| Variant | 3,217 | 100,000 | 1,000,000 |
|---|---|---|---|
| MariaDB 13.0.2 — single-noindex | 0.589 | 24.797 | 147.656 |
| MariaDB 13.0.2 — single-index | 0.125 | 0.093 | 0.204 |
| MariaDB 13.0.2 — or-both-indexed | 0.167 | 0.330 | 0.565 |
| MariaDB 10.11.18 — single-noindex | 2.319 | 44.279 | 967.945 |
| MariaDB 10.11.18 — single-index | 0.426 | 0.503 | 0.622 |
| MariaDB 10.11.18 — or-both-indexed | 0.561 | 0.523 | 0.454 |

Min/max of the 5 runs are in the raw files. The 10.11 run at 1M spread from 723 to
1,150 ms; every other cell spread less than 2x.

**The 1M no-index cell is sensitive to machine load.** That size on 13.0 was run four times in
total (`results-13.0-reruns.txt`): medians of 148, 162 and 129 ms with the machine
otherwise idle, and 485 ms while another CPU-heavy process was running. The indexed
variants stayed under 1 ms in every run. Read the 1M no-index numbers as "about 130 to
160 ms on 13.0 when idle, and about three times that under contention", not as a fixed value.

What the plans say (`EXPLAIN` in the raw files):

- No index: the inner table is read with `type: ALL` at every size. On 13.0 at 1M rows
  the optimizer switches from a materialized subquery to a semi-join over the full scan;
  it is still a full scan.
- Index: `type: ref` on `ix_code`, one row, at every size.
- OR with both columns indexed: `type: index_merge`, `Using union(ix_code, ix_serial)` —
  on both versions.

## What this shows

1. **The staging number was right on one version, the extrapolation was not on either.**
   Under 1 ms at 3.2K rows reproduces on 13.0 (0.6 ms) and does not on 10.11 (2.3 ms).
   Growth is not 1 ms per 100K: the first 100K rows cost ~25 ms on 13.0 and ~44 ms on
   10.11. Past that, 13.0 grows slower than linear (6x the time for 10x the rows) and
   10.11 faster than linear (22x the time for 10x the rows).
   The extrapolated "~10 ms at 1M" is off by 15x (13.0) to 100x (10.11).
2. **The two clauses of the trigger do not agree.** On 13.0 on an idle machine, 1M rows
   is 130 to 160 ms, so the row-count clause fires first and the latency clause is slack;
   under CPU contention the same cell came out at 485 ms, above the latency clause. On 10.11, 300 ms is
   crossed somewhere between 100K and 1M rows: about 680K if you extend the 100K point
   linearly, about 310K if you extend the 1M point, and the bench did not measure in
   between. Either way the row-count clause fires late and only the p95 clause protects
   users. A written
   trigger with two clauses only works if someone is actually watching the p95 one.
3. **The recorded reason for rejecting the OR shape (no index means a full scan) holds;
   the unrecorded assumption that OR would stay hard to index later does not.** With both
   columns indexed, both versions plan `index_merge union` and stay under 1 ms at 1M rows. The value
   object that picks one column by string shape is still a reasonable design (one
   predicate, one index, no dependence on optimizer merging), but the post must not claim
   the OR shape was unindexable.
4. **The non-unique index removes the growth entirely**: flat at 0.1 to 0.6 ms across
   all three table sizes, on both versions.

## What this does not measure

- **Production row count.** The production table was not reachable from the author's environment; this
  bench cannot tell you where that table stands. The post states it as unmeasured.
- **The production MariaDB version and hardware.** Two versions are shown precisely
  because the 1M result differs 6.5x between them. Nothing found in the portal's
  repository pins a MariaDB version (the database runs outside the application's Docker
  setup), so the bench does not claim which column applies.
- **Cold cache or disk-bound scans.** 1M rows of this schema fit in the default buffer
  pool, so every number here is an in-memory scan. A production table that does not fit
  is slower than any row here.
- **Concurrency.** One query at a time. p95 under real load is not p95 of 5 sequential
  runs.
- **The export path.** The export applies the same predicate inside a per-chunk query;
  its cost is this number times the number of chunks, which the bench does not run.
- **Write cost of the index** on the owning system's insert path — the reason the
  request is for a NON-UNIQUE index — is not measured.
