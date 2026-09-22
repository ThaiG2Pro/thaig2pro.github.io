---
title: "Ghost Quota: How a Missing Foreign Key Quietly Lowers a Sales Ceiling"
date: 2026-09-22T15:00:00+07:00
draft: false
description: "An orphaned row in a table with no foreign key used to just skew a report. After a shared-pool feature shipped, the same row started locking real units out of sale."
tags: ["database", "data-integrity", "foreign-key", "backend", "migrations"]
categories: ["Engineering"]
author: "Hoang Nguyen Thai"
showToc: true
TocOpen: true
cover:
    image: "/images/posts/quota-ma-thieu-foreign-key/cover.png"
    alt: "An orphaned row still counted against a shared stock pool with no screen to release it"
---

A table called `campaign_product_variants` had no foreign key, no `ON DELETE CASCADE`, and no `deleted_at`. Before the shared pool existed, that was a cosmetic problem: a handful of rows pointing at SKUs that no longer existed made a report look a few units smaller than reality. I never saw anyone treat that as a bug, and I did not go back through old tickets to check.

Then we shipped a shared stock pool — several campaigns drawing quota from one pool per SKU — and the same orphaned rows stopped being cosmetic. On a dev database I could still poke at, 14 orphan rows were locking 294 units out of sale, permanently, with no admin screen that could select and release them. The missing foreign key had turned pre-existing technical debt into a lowered sales ceiling.

## Dissecting it: what an orphan row actually costs

The mechanism is simple once you see it, which is exactly why nothing forced anyone to look at it. Each row in `campaign_product_variants` assigns a quota to one campaign for one SKU. The shared pool feature computes how much of a SKU's stock is still sellable by taking the pool total and subtracting everything allocated across every campaign that references that SKU — one aggregate query, no per-campaign filtering, because filtering by campaign is exactly what a *shared* pool is supposed to avoid.

That aggregate does not check whether the SKU a row points to still exists. It sums the `quota` column for every row that references the SKU id, full stop. Before the shared pool, a variant getting deleted or replaced elsewhere in the system just left behind a dangling row that reporting quietly ignored. After the shared pool, that same dangling row keeps contributing its quota to the "already allocated" side of the subtraction. The SKU it once belonged to is still on sale, still real, and still taking orders from campaigns that have nothing to do with the orphan.

And there is no way to find it in the product. The orphan row does not belong to any campaign an operator can currently open — its parent campaign may have ended, its variant may have been replaced — so there is no edit screen, no "release quota" button, nothing to click. It sits in the database counting against a real SKU's ceiling forever, or until someone runs a query against production by hand.

I confirmed the shape of the problem with a two-level `LEFT JOIN` pre-check (call it V7). It is a reconstruction with generic table and column names, not a verbatim copy of the production query: join `campaign_product_variants` to `product_variants`, then to the parent campaign, and count rows where either side is `NULL` or soft-deleted.

```sql
SELECT cpv.id, cpv.product_variant_id, cpv.quota
FROM campaign_product_variants cpv
LEFT JOIN product_variants pv
       ON pv.id = cpv.product_variant_id
      AND pv.deleted_at IS NULL
LEFT JOIN campaigns c
       ON c.id = cpv.campaign_id
      AND c.deleted_at IS NULL
WHERE pv.id IS NULL OR c.id IS NULL;
```

On the dev database this returned 14 rows totaling 294 units. I have not measured how that number moves once you also count SKUs where the aggregate goes negative and gets clamped back to zero — that is a related symptom of the same missing constraint, but I have not run that count and will not put a figure on it here.

## Trade-offs

The obvious fix is the foreign key itself, with `ON DELETE CASCADE` so an orphan can never exist again. I proposed exactly that and it got rejected, for two reasons:

- **`ALTER TABLE ... ADD CONSTRAINT` fails immediately if orphan rows already exist.** The migration would have to clean the data first, and the release we were preparing had an acceptance criterion that the migration run instantly — no backfill step, no maintenance window. Adding the constraint straight away was not an option without breaking that criterion.
- **`ON DELETE CASCADE` deletes rows that an audit table still points to.** The audit trail records what quota was allocated and when, keyed off `campaign_product_variants.id`. A cascade delete would silently erase the row an auditor needs to explain a past allocation, in exchange for a constraint that only prevents *future* orphans.

What shipped instead: the V7 pre-check as a release gate — the flag that turns the shared pool on cannot go live until that query returns zero rows on the target environment — plus a regression test that seeds exactly one orphan row and asserts the pool computation surfaces it instead of silently absorbing it into the subtraction. The actual foreign key was moved to its own ticket with a named owner, decoupled from this release.

## What I measured, and what I did not

The 14 rows and the 294 units are dev-database numbers, from a private codebase you cannot run against. Treat them as proof that the mechanism is real, not as a claim about scale — I have not run the V7 query against production, and the release gate means I will only get that number once, right before the flag flips, not as a number to publish here in advance.

The gate also does not fix the root cause: nothing in the schema stops a new orphan row from being created tomorrow — I have not traced which code path created the existing ones, so I cannot say whether it is still active. The gate only stops this *release* from shipping on top of dirty data. And the fix that would close the gap for good — the actual foreign key — is sitting on a separate ticket with a named owner; as of writing I do not know whether it has a date. A pre-check catches problems at the one gate it guards; it does not fix the schema that let them in.

If I were doing this over, I would push harder to schedule the backfill-and-constrain migration in the same quarter as the feature that made the debt expensive, instead of accepting "separate ticket" as a resolution on its own.
