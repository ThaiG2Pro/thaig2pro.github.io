# bench/bug-import-tra-nham-bang — an import that looked up the wrong table for years

Supporting evidence for the post *"The Import That Edited the Wrong Row for Years
Because Two Tables Shared the Same IDs"*
(`content/posts/bug-import-tra-nham-bang.en.md`).

## The question

An import row carries a SKU code. The handler resolves it to `product_variants.id`
("sku_id"), then has to find the quota row for that SKU **in one campaign**, which lives
in `campaign_product_variants` — a different table with its own auto-increment sequence.
The original code did `CampaignProductVariant::findOrFail($row['sku_id'])`: a
`product_variants` key looked up as a `campaign_product_variants` key.

Question: **why does a test with one SKU and one campaign stay green on that code?**

Answer: because with one row in each table, both ids are 1. The wrong lookup lands on
the right row by coincidence. Only a fixture with **one SKU in two campaigns** makes the
ids diverge, and that is the only fixture on which the bug is visible.

## Method

`schema.sql` — three tables with generic names, all `AUTOINCREMENT`. `ImportHandler.php`
— the handler with one flag: `fixed = false` reproduces the original single-key lookup,
`fixed = true` looks up by `(product_variant_id, campaign_id)`. `run.php` — two tests
against an in-memory sqlite, no framework, no dependencies:

| Test | Fixture | Asserts |
|---|---|---|
| 1 | 1 SKU, 1 campaign, 1 quota row | after import, that row's quota is 50 |
| 2 | 1 SKU in 2 campaigns (A, B); import targets B | (a) resolved row is B's, and its id ≠ the SKU's id · (b) after the write, B's quota is 50 and A's is unchanged |

Assertion 2(a) is what the real regression test in the private codebase checks. Assertion
2(b) is the step that test does **not** run — the post names this gap in its Limits
section; the bench includes it so a reader can see the write land on the wrong row.

## How to run

```bash
./run.sh
```

That runs `run.php` twice inside `php:8.2-cli` (override with `PHP_IMAGE=php:cli` for
the current release), once per mode. Nothing needed on your machine but Docker. Without
Docker: `php run.php broken` and `php run.php fixed` on any PHP 8.2+ with `pdo_sqlite`.

Actual output, 2026-09-23, copied verbatim:

```
=== 1/2 BROKEN — the original lookup ===
Import lookup — mode: BROKEN

  ✓  test 1 — one SKU in one campaign: quota is updated
  ✘  test 2 — one SKU in two campaigns: adjusting B resolves B's row, not A's
       resolved row id: expected 2, got 1

1 passed, 1 failed

=== 2/2 FIXED — lookup by (SKU, campaign) pair ===
Import lookup — mode: FIXED

  ✓  test 1 — one SKU in one campaign: quota is updated
  ✓  test 2 — one SKU in two campaigns: adjusting B resolves B's row, not A's

2 passed, 0 failed

Bench reproduces the finding: test 1 is green on the broken code, test 2 is not.
```

**The BROKEN run is the finding.** Test 1 is the test a reasonable developer writes
first, and it passes on the broken code — that is why zero tests caught this. Test 2
fails with `expected 2, got 1`: the handler asked for campaign B's row (id 2) and got
campaign A's row (id 1), because the SKU's id is 1.

Verified on **PHP 8.2.33 (`php:8.2-cli`) and PHP 8.5.10 (`php:cli`)**, sqlite
`:memory:`, identical output on both.

## What this does not measure

- **Blast radius.** Nothing here says how many production rows were written wrongly,
  or whether production ids overlapped the way staging ids did. The post says the
  same: not measured.
- **The real test's exact fixture.** The private regression test seeds one variant,
  two campaigns and two quota rows and asserts on the resolved id — test 2(a) mirrors
  that. It relies on natural auto-increment order, not on forcing ids apart; so does
  this bench.
- **Runtime cost of the fix.** The pair lookup does more work per row than the
  single-key lookup did. Not counted or timed here, not timed in the post.
- **The validation/processing split.** The original handler resolves the row in two
  places (validate, then process); the fix had to land in both. This bench has one
  `resolveRow()` used by one `processRow()`, so it cannot show the "validator fixed,
  processor still wrong" option that the post's Trade-offs section rejects.
