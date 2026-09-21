---
title: "The Lock I Dropped During a Refactor, and the 1184 Green Tests That Didn't Notice"
date: 2026-09-21T10:00:00+07:00
draft: false
description: "A row lock vanished during a refactor. The suite stayed green because sqlite silently ignores FOR UPDATE. How I made the lock visible to a test, and what it cost."
tags: ["concurrency", "testing", "laravel", "sqlite", "refactoring", "tdd"]
categories: ["Engineering"]
author: "Hoang Nguyen Thai"
showToc: true
TocOpen: true
cover:
    image: "/images/posts/lock-bi-danh-roi-khi-refactor/cover.png"
    alt: "A SELECT FOR UPDATE statement dissolving into an empty string on the sqlite driver"
---

QA filed a one-line gap: *no concurrency tests on the stock pool.* I opened the file expecting to write four tests and close it in an afternoon. Instead I found that the lock those tests were supposed to cover was not there anymore.

## What can go wrong here

The system is a promotions backend. Several campaigns draw from one shared stock pool per SKU. Before a campaign can reserve units, a service reads the pool balance, subtracts what is already reserved, and writes an allocation.

Those three steps are only safe if nothing slips in between them. Say the pool holds 10 units and two orders arrive in the same instant, on two different campaigns. Both read 10. Both conclude they can take 10. Both write. The system believes it sold 10 units; it has in fact promised 20. Nobody upstream notices until a warehouse cannot ship.

The design document was explicit about this: *read the pool inside the lock.* The original code did. Then I rewrote the read path to call a new lock-free pool helper, because many read-only callers were paying for a lock they did not need. The `lockForUpdate()` left with the old code.

The suite stayed green and code review passed. In the diff this looked like a tidy extraction: a few lines removed, one call added. The missing lock never showed up as a wrong line — it sat among the *deleted* lines, and reviewers read added lines far more closely than deleted ones. Why the suite stayed green is the longer story, and it is the part worth telling.

---

## Dissecting it: the test that could not fail

My first hypothesis was the boring one — the lock was still there, and the QA gap was just missing test coverage. So I wrote the test I assumed would pass: exercise the write path, assert the pool read is locked.

It passed. I had not added any lock.

That is the moment the afternoon turned into a day. A test that passes before you write the code is not a test, it is a decoration. I ran it against the deliberately broken version, the old version, a version with the pool read deleted entirely — green, green, green.

The cause is one inherited method. Laravel compiles `->lockForUpdate()` through the query grammar's `compileLock()`. sqlite has no `SELECT ... FOR UPDATE`, so `SQLiteGrammar` inherits the default and returns an empty string. The lock does not error, does not warn, does not appear in the compiled SQL. On the test driver it is a **silent no-op**:

```php
// What the service says
$pool = StockPool::where('sku', $sku)->lockForUpdate()->first();

// What sqlite executes
// select * from "stock_pools" where "sku" = ? limit 1
```

Every behavioural assertion I could write on sqlite was blind to the one thing I needed to assert.

The fix was to stop testing behaviour and start testing the **generated SQL**. I swapped the connection's grammar for a subclass whose `compileLock()` emits a marker comment instead of an empty string, captured queries with `DB::listen()`, and asserted that every pool read on every write path carried the marker:

```php
protected function compileLock(Builder $query, $value): string
{
    return $value ? ' /* for update */' : '';
}
```

Now the test failed. That red was the actual finding — the refactor, not the missing coverage. The whole trait is about thirty lines.

---

## Trade-offs

Three options were on the table, and the one I picked is the weakest of the three on paper.

- **Two real connections against MySQL.** Open two transactions, have the second block, assert it waits. This tests the lock for real, including ordering and timeouts. Cost: the test suite needs a live MySQL service, per-test setup goes from milliseconds to seconds, and CI grows a dependency that developers must run locally. For three write paths I estimated the suite would lose more time than the whole feature took to build.
- **Assert on generated SQL.** Fast, no infrastructure, runs on the existing sqlite driver. Cost: it proves the lock is *requested*, not that it is *sufficient*. It is coupled to a framework internal — if `compileLock()` moves, the trait rots and starts passing for the wrong reason.
- **A static rule: every write path must call a wrapper that locks.** Cheapest of all, no test at all. Rejected because it only catches mistakes that *look* like mistakes — someone hand-writing a query and forgetting the wrapper. Mine slips through: I did call the wrapper. I called the lock-free variant of it.

I chose the SQL assertion because the failure I had actually experienced was "the call disappeared", not "the lock was too weak". A test should be aimed at the bug that happened. The MySQL suite is the right investment when contention itself becomes the problem; it was not, yet.

---

## Measured results

Two different kinds of evidence sit behind this section, and it is worth keeping them apart.

The counts below were measured in a **private codebase**, on the same machine and the same `phpunit` invocation before and after the fix. You cannot rerun them, and you should discount them accordingly.

What you *can* rerun is the mechanism — the silent no-op itself, which is the part that generalises. It is reconstructed from scratch in [`bench/lock-bi-danh-roi-khi-refactor/`](https://github.com/thaig2pro/thaig2pro.github.io/tree/main/bench/lock-bi-danh-roi-khi-refactor): a fresh Laravel project, five files, and a constant you flip to move between the broken and the fixed version. It ships two tests. The behavioural one — the test a reasonable developer writes for "concurrency coverage" — is green in both settings. That is the finding, reproduced in about five minutes.

- **Concurrency tests over the pool read:** 0 → 4
- **Write paths with a lock assertion:** 0 of 3 → 3 of 3
- **Full suite:** 1101 → 1184 passed (the +83 is the whole cycle's tests; 4 of them are these)

There is one cost I **did not measure**: the grammar swap forces a fresh connection per test, so the suite got slower. I never recorded a before and after, so I have no figure to give. It is small at four tests and it scales with every path added later.

The oversell itself was never measured in production, because the lock came back before release. The honest figure for orders affected is unknown, plausibly zero.

---

## Limits, and what I would do differently

The test inspects SQL text. It cannot see lock ordering, deadlocks, or a transaction boundary drawn in the wrong place — a read can be correctly locked and still be inside a transaction that commits too early. That class of bug is still uncovered.

It is also coupled to a framework internal with no canary. If a future release changes how `compileLock()` is reached, my trait quietly stops marking anything and every assertion passes again — the exact failure mode I was trying to eliminate, one layer up.

What I would do differently is earlier and cheaper than any of this. The design document said "read the pool inside the lock", and that sentence had no test attached to it. When I extracted the lock-free helper, nothing connected the written intent to the code. I now treat it as a rule: **if a design document states an invariant, the commit that introduces the invariant also introduces the test that fails without it.** Not later, not in the QA pass — in that commit, while it is still obvious what the sentence means.

The suite was green for a reason. It just wasn't the reason I believed.
