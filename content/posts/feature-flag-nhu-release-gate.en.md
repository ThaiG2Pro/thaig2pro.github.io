---
title: "A Feature Flag as a Cross-Team Release Gate"
date: 2026-09-22T09:00:00+07:00
draft: false
description: "Shipping a feature you already know will fail 100% of the time if switched on too early — by turning a feature flag into a mandatory deploy order for another team."
tags: ["feature-flags", "release-engineering", "cross-team", "incident-prevention"]
categories: ["Release Engineering"]
author: "Hoang Nguyen Thai"
showToc: true
TocOpen: true
cover:
    image: "/images/posts/feature-flag-nhu-release-gate/cover.png"
    alt: "Diagram of a feature flag gating deploy order between two teams"
---

There's a kind of bug I never saw in a log, because it never ran: I read it straight out
of two lines of code, before writing a single line of my own. The question wasn't "how
do I fix this" — it was whether shipping something you already know will fail every
single time, if flipped on too early, counts as done.

---

## Context

Early this September I owned the backend piece of a new promotional mode: every product
in a campaign gets its own sale quota, and the system must reject orders once that quota
runs out. The feature had a fixed ship date, and my part sat inside it.

My scope was the quota service, where I had full write access. But orders flow through a
second service, owned by another team, and that service has to read the new quota value
correctly before anything can actually sell. I had no merge rights into that repo.

## The conflict

Before writing any code, I read through that other service to see how it reads quota.
Two spots in the same repo treated an empty value (`NULL`) in opposite ways:

1. The order check coerced `NULL` to zero — `Number(quota_total ?? 0)`. Empty means
   "out of stock," the order is rejected.
2. The storefront treated `NULL` as "unlimited," so the product still showed as
   purchasable.

The new mode isn't encoded in `NULL`. It has its own column that states the stock source
explicitly: own quota, or shared pool. `NULL` in the quota column is just a consequence —
a row selling from the shared pool has no quota of its own to write. But the other
service doesn't read that source column yet. It only sees `NULL`, and reads `NULL` two
opposite ways. Going back through the design doc, the count was worse than two: `NULL`
is read as 0 in three places and as unlimited in three others, across two systems.

What I could see from two lines: turn the mode on, and every shared-pool order gets
rejected while the screen keeps saying the item is in stock.

I couldn't fix it myself — wrong repo, wrong team. Why two spots in one repo disagree, I
don't know and didn't go asking; this post only covers what I read. The other team wasn't
negligent either: the failure only exists once the new mode is on, and the mode didn't
exist yet.

Two things were true, and they couldn't both win. The ship date was fixed, and nothing in
my own scope justified slipping it. And turning the flag on before the other team's fix
landed meant 100% of shared-pool orders rejected the first time a customer tried the
feature — a public failure, in exactly the place meant to impress.

## What I decided

I shipped the code and the migration on schedule, but kept the flag defaulted **off** in
production. Then I wrote the condition for turning it on as a mandatory two-step deploy
order for the other team:

1. **Fence the reserved stock first.** Stock already allocated to other campaigns has to
   be split off from the shared pool, so an "unlimited" order can't sell into it.
2. **Loosen the `NULL` handling second.** Only once the pool is fenced does the order
   check change: empty no longer means out of stock, it defers to the source column.

Reversing the order produces the opposite failure. Flag on too early: every shared-pool
order is rejected. Loosen before fencing: 100% oversell. The reason: between the two
steps, a shared-pool order is held back neither by its own quota nor by the reserved
stock.

An illustrative number, to show why the order matters. Say the shared pool holds 10
units, and all 10 are reserved for another campaign. Loosen `NULL` before fencing: a
shared-pool order reads "unlimited" and sells all 10 — the other campaign's stock. Fence
first, then loosen: the same order sees a pool of 0 and is correctly rejected.

The flag here isn't for gradual rollout. It's a way to turn a cross-team dependency into
something checkable: the flag being off means the conditions aren't met, and the
conditions live in a document anyone can read.

## The cost

As of writing, the flag is still off. The feature is in production — but for real users
nothing has changed. From the outside that looks like an
unfinished feature, even though my part was done on schedule. "Done" for the whole
feature now depends on the schedule of a team I don't control.

I also took on work outside my original scope: writing a deploy-order document for a
repo that isn't mine, clear enough for the other team to follow without me in the room.
And the business value of the new mode is delayed by however long the other team takes
to deploy. How long, how many orders — I don't have those numbers yet, because it isn't
over.

## What I'd do differently

Next time I'd read the dependent service's code **during design review**, before writing
any of my own — not after picking up the work and finding it then. "How does the downstream
service handle an empty value" should be a mandatory item in any cross-team design
review, not something one engineer digs up out of a habit of reading code before
changing it.

I'd also push for treating the flag as a two-party contract from day one, instead of
setting the condition alone and handing it over. A deploy order agreed at design time
sits in both teams' backlogs from the start, rather than being a document one side writes
and the other side waits to read.

---

Have you ever had to ship something you knew would fail if switched on at the wrong
moment? How did you convince the dependent team?
