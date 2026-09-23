---
title: "The Import That Edited the Wrong Row for Years Because Two Tables Shared the Same IDs"
date: 2026-09-22T17:00:00+07:00
draft: false
description: "A quota import took a product id and looked it up in a different table. Auto-increment made the ids overlap, so every run changed exactly one row and nobody noticed."
tags: ["backend", "testing", "data-integrity", "laravel", "import"]
categories: ["Engineering"]
author: "Hoang Nguyen Thai"
showToc: true
TocOpen: true
cover:
    image: "/images/posts/bug-import-tra-nham-bang/cover.png"
    alt: "Two tables with overlapping auto-increment ids, an import file pointing at one and the code reading the other"
---

An import feature that adjusts campaign quotas from a spreadsheet had been in production for years. Every manual QA pass looked the same: upload a file, open the campaign, see one quota changed, mark the ticket done. Zero automated tests covered the handler.

It was editing the wrong row. Not sometimes — structurally, on every run where the two ids happened to line up, and on the staging database they did. The number of production rows it touched over those years is something I have not measured and will not guess at here. What I can show is the mechanism, why three separate safety nets each let it through, and the one test that would have caught it on day one.

---

## Dissecting it: an id that means one thing in the file and another in the code

The import file has a SKU code column. The handler first turns that code into `sku_id`, the primary key of `product_variants` — the table of sellable SKUs. Then it called the ORM's find-or-fail on the quota model with that id, which compiles to this (reconstructed in the bench, not copied from the codebase):

```sql
SELECT * FROM campaign_product_variants WHERE id = :sku_id
```

The quota model is a different table: `campaign_product_variants`, one row per (campaign, SKU) pair, holding that pair's quota. Its primary key has nothing to do with the SKU's primary key. The code took a `product_variants.id` and looked it up as a `campaign_product_variants.id`.

Why did it work at all? Both tables use auto-increment starting from small numbers. On a staging database where both tables have been filling up from the bottom, an id like 7 exists in both. `findOrFail` finds *a* row, the update succeeds, and one quota changes. That is exactly what QA was checking for.

Say the file says: SKU-A, whose `product_variants.id` is 7, should have its quota set to 50 in campaign 3. The handler loads `campaign_product_variants` row 7, which belongs to SKU-B in campaign 1, and sets *that* quota to 50. Open campaign 3: SKU-A is unchanged. Open campaign 1: SKU-B now reads 50. Nobody opens campaign 1, because the ticket was about campaign 3.

Three nets, three separate holes:

1. **Tests:** there were none on this handler. Zero. But a test written the natural way — seed one SKU, seed one campaign row, import, assert — would have passed too, because both fixtures get id 1.
2. **Code review:** the line reads as correct. The variable is called `sku_id`, the model's name contains "product variant" too, and find-or-fail on a model is an everyday ORM idiom. The mismatch is semantic, not syntactic, and nothing on the screen says "these two ids live in different sequences."
3. **Manual QA:** the check was "did one row change?", and one row always changed. The check that would have caught it — "did the *right* row change, and did nothing else?" — needs a second campaign in the fixture, which a happy-path QA script does not set up.

The bug surfaced only when a new acceptance criterion arrived. It said nothing about lookups: a new stock mode was being introduced, where a SKU draws from a shared pool instead of a per-campaign quota, and the import had to reject any row pointing at a SKU in that mode. To know whether a row is in that mode you have to load the *right* row. Reading the handler to do that is when the single-key lookup stopped looking innocent.

---

## Trade-offs

The import has two steps that each look a row up: a validation step that decides whether the row is acceptable, and a processing step that writes the quota. The acceptance criterion only asked for a rejection, and rejections happen in validation. Three options were on the table, and the decision record kept all three.

- **Resolve by pair in validation only, leave the processing step as it was.** Rejected. This is the "just enough to turn the criterion green" option, and it satisfies it to the letter: the validator would now correctly identify the (SKU, campaign) row, report on it, and then the processor would go on writing to the wrong row exactly as before. A validator that checks one row while the writer touches another is worse than no validator, because it produces a green report for a wrong write.
- **Resolve by pair in both steps.** Chosen. The handler now resolves the SKU code to its `product_variants.id`, then finds the campaign row by `(product_variant_id, campaign_id)` through the campaign's product list, in validation and in processing alike. More lookups per row than before. I have not measured the import's runtime before and after, so I will not claim the difference is negligible.
- **Split the fix into its own ticket and block the acceptance criterion on it.** Rejected. The recorded reasons are two: the criterion cannot be implemented while the lookup is wrong, and the release scope was already locked, so it could not be moved. I would add a third that the record does not state: in the meantime the import keeps writing wrong quotas.

The second decision was about the test, and it is the one I would defend hardest. A regression test that seeds one SKU in one campaign and asserts the resolved row is right would have been green on the broken code: with one row in each table, the ids coincide. The test I wrote instead puts **one SKU in two campaigns**, adjusts campaign B, and asserts two things: the resolved row is B's row, not A's, and its id is not the SKU's id. The cost is having to seed the second campaign — more fixture than a happy-path test needs, and a test that reads less like a story and more like a trap. It checks the resolution step only; it does not run the write and then assert campaign A's quota stayed put. That is a gap, and I name it below.

---

## What changed, measured

| Metric | Before | After |
|---|---|---|
| Automated tests on the import handler | 0 | 1 |
| Tests that fail on the original code | 0 | 1 |

That is the whole table, and I am not going to pad it. The count comes from the private codebase and you cannot verify it. The before/after row count of corrupted data does not exist, because I did not run a production audit. The fix shipped alongside the new acceptance criterion; going back through history was not part of it.

The mechanism itself you *can* run. [`bench/bug-import-tra-nham-bang`](https://github.com/thaig2pro/thaig2pro.github.io/tree/main/bench/bug-import-tra-nham-bang) rebuilds it from scratch with generic table names, no company code: two tables that both auto-increment, an import that looks up the wrong one, and two tests side by side. The first seeds one SKU in one campaign and passes on the broken code. The second seeds one SKU in two campaigns and fails on the broken code, passes on the fix. One command runs both.

---

## Limits, and what I would do differently

**What this does not tell you:** how much production data was wrong, whether production ids overlapped the way staging ids did, and whether any operator ever noticed a quota they did not set. I did not measure any of it, and the bench cannot either — it reconstructs the mechanism, not the blast radius. The regression test also stops at the resolution step: nothing yet asserts that after a real write to campaign B, campaign A's quota is unchanged.

**The general rule I took away:** every handler of the form "take an id from entity X, look it up in entity Y" needs a test where X and Y have deliberately different ids. A test that uses overlapping ids passes whether the code is right or wrong, which makes it worse than no test — it produces confidence with no evidence behind it.

**What I would do differently:** I would not wait for an acceptance criterion to force a re-read of the handler. Any import path that has zero tests and years of green QA is a place where "nothing is wrong" and "nothing is checked" have become indistinguishable. Next time I inherit one, I will write the two-campaign test before touching anything else, and let it tell me whether the years of quiet were quiet for a good reason.
