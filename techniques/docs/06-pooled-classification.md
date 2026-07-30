# 6 — Pooled-Inventory Root-Cause Classification

**What it is.** The pilot's core analytical technique and its hypothesis test (BR-008b). For
every store stockout, sum that SKU's on-hand quantity **across all other pilot locations + the
DC on the same day**. If a redistributable surplus (≥3 units) existed elsewhere, it's a
**Distribution Issue**; if the region was also at/near zero, it's a **True Shortage**.

**Why I chose it.** This is the single query that proves or disproves the founding hypothesis
("the problem is distribution, not supply"). It's a *self-join across the same fact table on
Product_Key + Date_Key*, excluding the stocked-out store itself. The ≥3-unit threshold is a
documented judgment call — a stray 1–2 units elsewhere is shelf residue, not a redistributable
fix — and the raw pooled quantity is exposed so borderline cases stay auditable.

**What it looks like.** Two real, injected known-answer cases:

| Store | SKU | Date | Pooled elsewhere | Classification |
|---|---|---|---|---|
| NorthStar UT #05 | SKU-1010 | 2025-06-10 | **1,297** units | Distribution Issue |
| NorthStar UT #01 | SKU-1020 | 2025-09-05 | **0** units | True Shortage |

```sql
CASE WHEN (SELECT COALESCE(SUM(f2.Quantity_On_Hand),0)
           FROM Fact_Inventory_Snapshot f2
           WHERE f2.Product_Key = f.Product_Key      -- same SKU version
             AND f2.Date_Key    = f.Date_Key         -- same day
             AND f2.Store_Key  <> f.Store_Key) > 2   -- everywhere else
     THEN 'Distribution Issue' ELSE 'True Shortage' END
```

Across the dataset this returns **79.7% Distribution / 20.3% Shortage** — computed, not assumed.

**How I'd defend it.** "It's a same-day self-join pooling every other location. The store was
empty while 1,297 units sat nearby — that's a distribution problem by construction, not opinion."
