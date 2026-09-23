---
title: "The Formula in the Ticket Subtracted Sales Twice, and Only Two Screenshots Could Prove It"
date: 2026-09-23T14:00:00+07:00
draft: false
description: "An acceptance criterion defined available stock as intake minus allocated minus sold. Read literally it gave 80; production showed 90. The gap was exactly the units counted twice."
tags: ["backend", "requirements", "data-integrity", "inventory", "testing"]
categories: ["Engineering"]
author: "Hoang Nguyen Thai"
showToc: true
TocOpen: true
cover:
    image: "/images/posts/cong-thuc-tru-hai-lan/cover.png"
    alt: "A 200-unit bar split into 110 allocated and 90 shared pool, the 10 units sold out of quotas highlighted inside the 110, and two subtractions below it: the literal reading giving 80 and the production screen giving 90"
---

One SKU. Total intake 200 units. Three campaigns hold quotas of 10, 88 and 12 units, and have sold 1, 9 and 0 out of those quotas. How many units are still available to sell?

The ticket said: **available = total intake − total allocated − total sold.** Plug the numbers in and you get 200 − 110 − 10 = 80. The production screen for that SKU, at the same moment, said 90.

Ten units is not a rounding error on a 200-unit SKU. It is the difference between a campaign being able to sell and being told the shelf is empty. And this sentence was about to become the acceptance criterion for a new feature. The feature lets a campaign sell straight from the shared warehouse pool, with no quota of its own. Every order in that new mode would be checked against whatever this formula computes. If the formula undercounts by 10, the new mode refuses 10 sales it should have taken. If somebody "fixes" it the other way, it oversells.

Had it shipped as written, the campaign that gets refused would have paid first, and the developer holding a screen that disagrees with the spec, second.

---

## Dissecting it: the same units inside two of the three terms

The number set above is the real one from the incident, with the SKU name removed. It was already sitting in the proposal document; the algebra only needed someone to do it instead of trusting the sentence.

"Total allocated" is the sum of every campaign's quota: 10 + 88 + 12 = 110. "Total sold" is the sum of what those campaigns sold: 1 + 9 + 0 = 10. The literal reading subtracts both.

But a quota is a promise of units, and a sale out of that quota does not create a new claim on the warehouse. The 9 units campaign two sold were already inside its 88. Subtracting 110 already removed them; subtracting 10 again removes them a second time. That is where the 80 comes from, and it is why the gap is exactly 10: **the error of the literal reading is always equal to the units sold out of quotas.** In the bench linked below, that identity holds in 10,000 random cases with zero exceptions.

![The 200-unit bar, the 10 sold units sitting inside the 110 allocated, and the two subtractions](/images/posts/cong-thuc-tru-hai-lan/cover.png)
*Figure 1: the 10 units sold out of quotas are already inside the 110 allocated. The literal reading subtracts them a second time.*

So which reading did the author of the sentence mean? A sentence cannot tell you. What settled it was two screenshots of two different screens for the same SKU, taken within the same minute. Same minute matters, because a sale landing between the two shots would move the numbers and turn a proof into a coincidence. This is not hypothetical: a third screenshot of the same SKU, fourteen minutes later, already showed 89 instead of 90. One unit had moved in between. Between the first two, the inputs and the computed 90 were on record. The screen was subtracting allocated quotas and then subtracting only the units sold *outside* any quota, straight from the pool. In this number set that was zero, hence 200 − 110 − 0 = 90.

Read that way, "total sold" in the ticket meant "sold from the shared pool", a quantity that the per-campaign quotas never contain. The sentence was correct under one reading and ambiguous on paper.

Why did nobody catch it earlier? Two reasons that are worth separating:

1. **On a fresh campaign, both readings agree.** If no campaign has sold anything yet, the "total sold" term is zero either way and both formulas return the same number. A manual check on newly seeded data cannot see the bug. The bench confirms this: in every random case where quota sales sum to zero, the two readings are identical.
2. **The sentence has the shape of a correct formula.** "Total minus reserved minus sold" is a familiar shape for an inventory rule. My guess, and it is only a guess, is that a sentence with that shape does not make anyone stop. It did not make me stop either, until the screen did. Nothing in the wording says "one of these terms already contains the other."

---

## Trade-offs

Once the meaning was pinned, the specification kept two forms of the formula, and the design had to choose which one to ship.

- **The batch form:** sum over warehouse batches of (batch total − batch used), minus the sum over campaigns of (quota − quota used). This reads naturally off the warehouse tables. It is correct only if every sale, in either mode, has been booked against a batch, so that batch-used and quota-used move together. The ordering service does write both counters in one transaction and reverts both on cancel. But "the invariant is maintained by the write path" is a weaker guarantee than "the formula does not need the invariant".
- **The intake form:** total intake − allocated quotas − units sold from the pool. Chosen. It has no batch-used term at all, so a missed revert on a cancelled order cannot drift it. The cost is that the SQL has to know which sales came from the pool and which from a quota, which is one more filter to get right and to defend in review.

---

## What changed, measured

| Quantity | Literal reading of the ticket | Reading the screen implements |
|---|---|---|
| Available units, real number set | 80 | 90 |
| Difference | 10, equal to units sold out of quotas | |
| Random cases where the identity "gap = quota sales" fails | 0 of 10,000 | |
| Random cases where the two readings agree | every case with zero quota sales | |

The 80 and 90 come from one SKU in the private system and a screenshot I cannot show you. The rest you can run. [`bench/cong-thuc-tru-hai-lan`](https://github.com/thaig2pro/thaig2pro.github.io/tree/main/bench/cong-thuc-tru-hai-lan) is a stdlib Python script with no database: it computes both readings and the batch form on the incident's number set and on 10,000 random inputs, asserts the identity on each, and exits non-zero if it ever breaks. One command, same output locally and in a clean container.

I did not measure performance; this was never about speed. What changed is that the formula has one pinned meaning with a real number set behind it, and the shipped form is the one that does not depend on batch bookkeeping being perfect.

---

## Limits, and what I would do differently

**What this does not tell you:** how many SKUs on production had quota sales greater than zero at the time, which is the only population where the two readings differ. I did not measure it, so I cannot say how many screens would have shown a wrong number if the literal formula had shipped. The screenshots proved which quantity the screen subtracts, not that the screen is right by some external standard; the bench takes that definition as input and shows the arithmetic. And I did not check whether every historical cancelled order actually reverted both counters, which is exactly why the shipped form avoids relying on it.

**The rule I took away:** for every rule of the form "available = total − reserved − sold", ask two questions before it becomes an acceptance criterion. Does one term already contain another? And what does the production screen compute for one real SKU, right now? A rule that has not been checked against a real number set is a sentence, not a specification.

**What I would do differently:** do the arithmetic on the day the sentence is written, not after a screen contradicts it. The numbers were already in the proposal. The subtraction itself is trivial; the only hard part is deciding that a sentence which reads like every other inventory rule still needs to be checked.
