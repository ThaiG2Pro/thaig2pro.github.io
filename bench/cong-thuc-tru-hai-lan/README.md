# bench/cong-thuc-tru-hai-lan — one availability rule, two readings, ten units apart

Supporting evidence for the post *"The formula in the ticket subtracted sales twice"*
(`content/posts/cong-thuc-tru-hai-lan.en.md`).

## The question

A ticket defined available stock for one SKU as
**"total intake − total allocated − total sold"**. Read literally, "total sold" includes
units sold out of a campaign's allocation, which are already inside "total allocated", so
those units are subtracted twice.

Question: **on one SKU with total intake T, N campaigns each holding
(quota_total, quota_used), and C units sold straight from the shared pool, what does the
literal reading return versus the reading the production screen implements, and is the
gap always exactly Σ quota_used?**

## The five parameters

| Parameter | Value |
|---|---|
| Baseline | the literal reading of the ticket's sentence: `T − Σquota_total − (Σquota_used + C)` |
| Dataset | (1) the incident's number set, de-identified: T=200, campaigns 10/1, 88/9, 12/0, C=0. (2) 10,000 random cases, seed `20260907`, T∈[1,5000], 0–6 campaigns, quota_used ≤ quota_total, Σquota_total + C ≤ T |
| Environment | Python 3.12.3 locally and `python:3.12-alpine` in Docker, stdlib only, no database. Integer arithmetic, so no timing, warm-up or jitter concerns |
| Runs | deterministic; one run per environment gives identical output. The random set is the "repetition" — 10,000 independent inputs, every one checked |
| Not measured | see the last section |

## Method

`check.py` computes three readings of the rule for each input:

| Name | Formula | Meaning |
|---|---|---|
| `literal` | `T − Σqt − (Σqu + C)` | "total sold" = every sale |
| `correct` | `T − Σqt − C` | the spec's second form — the one that shipped, and what the production screen showed. "Total sold" = only units sold from the shared pool |
| `canon` | `Σ(batch_total − batch_used) − Σ(qt − qu)` | the spec's first form; equals `correct` only if every sale is booked on a batch |

Two assertions, both must hold on every input or the script exits 1:

1. `correct − literal == Σquota_used` — the gap is the fingerprint of double counting.
2. `canon == correct` — the two forms of the spec agree. The shipped code uses the second
   form precisely so it does not depend on batch bookkeeping (see Assumptions).

### Assumptions

- **`batch_used = Σquota_used + C`**: every sale, whichever mode, decrements a batch.
  Confirmed against the ordering service's write path: each order writes both the
  campaign row's used counter and the batch's used counter in one transaction, and
  reverts both on cancel. The invariant can still drift if a revert is missed; that is
  why the shipped code uses the second form, which has no batch-used term. Only `canon`
  depends on this invariant; `literal` and `correct` do not.
- Campaign allocations never exceed intake (Σqt + C ≤ T). The identity holds without
  this, but the generator keeps inputs realistic.

## How to run

```bash
./run.sh
```

Uses local `python3` (3.8+) if present, otherwise `python:3.12-alpine` via Docker.
Writes `results/summary.json`, `results/cases-sample.csv` (first 20 random cases) and
`raw/cases.csv` (all 10,000, gitignored).

Actual output, 2026-09-23, identical on Python 3.12.3 (local) and `python:3.12-alpine`:

```
1) Incident number set: T=200, campaigns 10/1, 88/9, 12/0, central sales 0
   literal reading : 80
   correct reading : 90   (production screen showed 90)
   spec first form : 90
   gap             : 10   (sum quota_used = 10)

2) 10000 random cases (seed 20260907), T in [1,5000], 0-6 campaigns, central sales >= 0
   identity  gap == sum(quota_used)  violated in : 0 cases
   spec first form != second form in            : 0 cases
   cases where both readings agree (sum quota_used = 0): 1422 (14.2%)
   cases where literal reading goes negative while correct is >= 0: 7487 (74.9%)

RESULT: identity holds; literal reading double-counts exactly sum(quota_used)
```

**What the post may take from this:** 80 vs 90, gap 10 = Σquota_used on the incident
set; 0 violations of the identity in 10,000 random cases; and the fact that the two
readings are **indistinguishable whenever Σquota_used = 0** — on a fresh campaign with no
allocated sale yet, the literal formula returns the right number, which is why a quick
manual check on new data cannot catch it.

**What the post may not take from this:** the percentages 14.2% and 74.9%. They describe
the random generator (how it splits T between campaigns and pool), not any production
data. They are printed so a reader can see the run, not so they can be quoted.

## What this does not measure

- **Which reading the ticket's author meant.** The screenshots settled that "sold" here
  counts only shared-pool lines; this bench takes that as input, it does not prove it.
- **The real screen.** The 90 comes from a production screenshot recorded in the
  incident notes; the bench reproduces it arithmetically, it does not query the system.
- **Whether the batch-used invariant actually holds on production data.** The write path
  maintains it; whether every historical cancel reverted both counters is not checked here.
  Only `canon` depends on it.
- **Frequency in production.** Nothing here says how many SKUs had Σquota_used > 0 at the
  time, so nothing here says how many screens would have shown a wrong number.
- **Anything about performance or the query itself.** Pure integer arithmetic; the SQL
  that implements `canon` is not reconstructed.
