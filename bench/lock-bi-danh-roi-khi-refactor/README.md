# bench/lock-bi-danh-roi-khi-refactor — a lock that a green test cannot see

Supporting evidence for the post *"The Lock I Dropped During a Refactor"*
(`content/posts/lock-bi-danh-roi-khi-refactor.en.md`).

## The question

A service reads a shared stock pool, then writes an allocation against it. The read is
supposed to happen inside a row lock (`SELECT ... FOR UPDATE`) so two concurrent requests
for the same SKU cannot both see the pre-write balance.

Question: **does a passing test suite prove the lock is there?**

Answer, on the sqlite test driver: no. Laravel's `SQLiteGrammar` inherits `compileLock()`
and returns an empty string, because sqlite has no `FOR UPDATE`. The call is a silent
no-op. Any test that asserts "the read is locked" by observing behaviour on sqlite passes
identically with and without `lockForUpdate()`.

## Method

1. Swap the connection's query grammar for one whose `compileLock()` emits a marker
   comment (`/* for update */`) instead of an empty string — `ForcesLockSyntax.php`.
2. Capture compiled SQL with `DB::listen()` while exercising each write path.
3. Assert every `select ... from "stock_pools"` on that path carries the marker —
   `StockPoolLockTest.php`.

Schema is `schema.sql`: one pool row per SKU, many campaigns drawing from it.

## Numbers

| Metric | Before | After |
|---|---|---|
| Concurrency tests over the pool read | 0 | 4 |
| Write paths covered by a lock assertion | 0 of 3 | 3 of 3 |
| Full suite | 1101 passed | 1184 passed |

The +83 is the whole batch of tests added in that cycle, not the lock tests alone; the
lock tests are 4 of them. Both suite numbers come from the same `phpunit` invocation on
the same machine, one before the fix branch and one after.

## How to run

These five files reconstruct the mechanism outside the original codebase. They are a
self-contained demonstration, not a drop-in for your project.

1. `composer create-project laravel/laravel bench-lock` — Laravel 12, PHP 8.2+.
2. Copy all five files into `tests/Feature/`. They declare `namespace Tests\Feature`,
   so Laravel's default PSR-4 mapping autoloads them with no `composer.json` changes.
3. With `StockPoolService::LOCKED_READ` left at `false` (the post-refactor bug):

   ```
   php artisan test --filter=NaiveConcurrencyTest   # 1 passed
   php artisan test --filter=StockPoolLockTest      # 3 failed
   ```

4. Set `LOCKED_READ` to `true` (the pre-refactor code) and run both again:

   ```
   php artisan test --filter=NaiveConcurrencyTest   # 1 passed
   php artisan test --filter=StockPoolLockTest      # 3 passed
   ```

**Step 4 is the finding.** `NaiveConcurrencyTest` is the test a reasonable developer
writes when QA asks for concurrency coverage: drive the write paths, assert the pool
never oversells. It is green in both runs. It cannot tell the locked version from the
lock-free one, because sqlite discards the lock clause either way — so it would have
stayed green through the entire window the lock was missing.

`StockPoolLockTest` separates them only because `ForcesLockSyntax` swaps the query
grammar for one that emits `/* for update */` where the lock clause belongs, turning an
invisible difference into text an assertion can read.

Verified on **Laravel 12.x, PHP 8.2, sqlite `:memory:`**, exactly as printed above.
`MarksLockInCompiledSql` also handles the Laravel ≤ 11 grammar constructor (no
`Connection` argument), but that path was not run here.

## What this does not measure

- **Real contention.** The test inspects SQL text, not runtime behaviour. It proves the
  lock is *requested*, not that it is *sufficient* — lock ordering, deadlocks and
  transaction boundaries are out of scope.
- **Production oversell volume.** I never got a number for how many orders were affected
  during the window the lock was missing. It was caught before release, so the honest
  figure is "unknown, plausibly zero".
- **MySQL/Postgres behaviour.** The whole trick exists because sqlite is the odd one out.
  On MySQL the same assertion is unnecessary; a different technique (two connections,
  real transactions) is needed there and is slower.
- **Whether the marker comment stays truthful.** If a future Laravel release changes how
  `compileLock()` is reached, the trait can go stale and pass for the wrong reason. It
  needs a canary test of its own, which I have not written.
