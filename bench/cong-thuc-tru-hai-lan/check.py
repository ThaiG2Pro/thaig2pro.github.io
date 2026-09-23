#!/usr/bin/env python3
"""Two readings of one availability rule, checked on one real number set and
10,000 random ones. Stdlib only. Writes results/summary.json, results/cases-sample.csv, raw/cases.csv (gitignored).

Model (see README "Assumptions"):
  T   = total intake of one SKU across its batches
  P_i = campaign i, holding (quota_total, quota_used); quota_used are units already
        sold out of that campaign's allocation ("allocated mode")
  C   = units sold straight from the shared pool ("central mode"), not through any quota
  batch quantity_used = sum(quota_used) + C   (every sale decrements a batch)

Readings of "available = total intake - total allocated - total sold":
  literal : T - sum(quota_total) - (sum(quota_used) + C)   # "sold" = every sale
  correct : T - sum(quota_total) - C                       # "sold" = central-mode sales only
  canon   : sum(bt - bu) over batches - sum(qt - qu) over campaigns
            (the spec's first form; `correct` is its second form and the one that
            shipped. Equal iff every sale is booked on a batch.)
"""
import csv, json, os, random, sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "results")
RAW = os.path.join(HERE, "raw")
os.makedirs(OUT, exist_ok=True)
os.makedirs(RAW, exist_ok=True)


def readings(T, campaigns, C):
    sum_qt = sum(qt for qt, _ in campaigns)
    sum_qu = sum(qu for _, qu in campaigns)
    literal = T - sum_qt - (sum_qu + C)
    correct = T - sum_qt - C
    batch_used = sum_qu + C
    canon = (T - batch_used) - sum(qt - qu for qt, qu in campaigns)
    return dict(sum_qt=sum_qt, sum_qu=sum_qu, literal=literal, correct=correct, canon=canon)


def random_case(rng):
    T = rng.randint(1, 5000)
    n = rng.randint(0, 6)
    campaigns = []
    budget = T
    for _ in range(n):
        qt = rng.randint(0, max(0, budget))
        qu = rng.randint(0, qt)
        campaigns.append((qt, qu))
        budget -= qt
    C = rng.randint(0, max(0, budget))
    return T, campaigns, C


def main():
    # --- 1. the number set from the incident (drafts/inbox.md 2026-09-07) ---
    fixed = readings(200, [(10, 1), (88, 9), (12, 0)], 0)
    print("1) Incident number set: T=200, campaigns 10/1, 88/9, 12/0, central sales 0")
    print(f"   literal reading : {fixed['literal']}")
    print(f"   correct reading : {fixed['correct']}   (production screen showed 90)")
    print(f"   spec first form : {fixed['canon']}")
    print(f"   gap             : {fixed['correct'] - fixed['literal']}   "
          f"(sum quota_used = {fixed['sum_qu']})")
    ok_fixed = fixed["literal"] == 80 and fixed["correct"] == 90 and fixed["canon"] == 90

    # --- 2. property check on random inputs ---
    N = 10_000
    rng = random.Random(20260907)
    rows, bad, indistinguishable, negative = [], 0, 0, 0
    for i in range(N):
        T, campaigns, C = random_case(rng)
        r = readings(T, campaigns, C)
        gap = r["correct"] - r["literal"]
        holds = gap == r["sum_qu"] and r["canon"] == r["correct"]
        bad += not holds
        indistinguishable += gap == 0
        negative += r["literal"] < 0 <= r["correct"]
        rows.append([i, T, len(campaigns), r["sum_qt"], r["sum_qu"], C,
                     r["literal"], r["correct"], r["canon"], gap, int(holds)])

    header = ["case", "T", "n_campaigns", "sum_quota_total", "sum_quota_used",
              "central_sold", "literal", "correct", "canon", "gap", "identity_holds"]
    for path, data in ((os.path.join(RAW, "cases.csv"), rows),
                       (os.path.join(OUT, "cases-sample.csv"), rows[:20])):
        with open(path, "w", newline="") as f:
            w = csv.writer(f); w.writerow(header); w.writerows(data)

    print(f"\n2) {N} random cases (seed 20260907), T in [1,5000], 0-6 campaigns, central sales >= 0")
    print(f"   identity  gap == sum(quota_used)  violated in : {bad} cases")
    print(f"   spec first form != second form in            : "
          f"{sum(1 for r in rows if r[8] != r[7])} cases")
    print(f"   cases where both readings agree (sum quota_used = 0): {indistinguishable} "
          f"({100.0 * indistinguishable / N:.1f}%)")
    print(f"   cases where literal reading goes negative while correct is >= 0: {negative} "
          f"({100.0 * negative / N:.1f}%)")

    summary = {
        "incident_set": {"T": 200, "campaigns": [[10, 1], [88, 9], [12, 0]], "central_sold": 0,
                         **fixed, "gap": fixed["correct"] - fixed["literal"]},
        "random": {"n": N, "seed": 20260907, "identity_violations": bad,
                   "canon_mismatches": sum(1 for r in rows if r[8] != r[7]),
                   "indistinguishable_cases": indistinguishable,
                   "literal_negative_while_correct_nonneg": negative},
        "assumption": "batch quantity_used = sum(quota_used) + central_sold; confirmed against the ordering write path (both counters written in one transaction, both reverted on cancel)",
    }
    with open(os.path.join(OUT, "summary.json"), "w") as f:
        json.dump(summary, f, indent=2)

    ok = ok_fixed and bad == 0
    print("\nRESULT:", "identity holds; literal reading double-counts exactly sum(quota_used)"
          if ok else "UNEXPECTED — read the numbers above, do not edit the README to match")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
