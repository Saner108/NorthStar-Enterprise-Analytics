# 7 — Deterministic Synthetic Data Generation

**What it is.** No live source systems exist, so a Python script generates the data: seeded
RNG, realistic distributions, written to CSV staging, then loaded. It is a **one-time
generation pipeline**, not a production ETL feed — and I'm careful to call it that.

**Why I chose these methods.**
- **Seeded RNG (`--seed 42`)** → the entire 1.6M-row dataset is byte-for-byte reproducible;
  anyone can regenerate and verify the exact numbers.
- **Log-uniform pricing** (not flat uniform) → a realistic assortment is mostly cheap items
  with a thin expensive tail; flat uniform produced an implausible ~\$685 average price.
- **Per-store hazard model for stockouts** → each store gets its own stockout-day rate, so
  availability genuinely *varies* store to store (~88%–97%) instead of a flat, uninteresting
  ~99.9% everywhere.
- **Injected known-answer cases** → a guaranteed Distribution case, a True-Shortage case, and
  the SCD2 reclassification, so the analysis can be checked against a known truth.

**What it looks like.**

```mermaid
flowchart LR
    G["generate (seeded)"] --> S["CSV staging"] --> V["validate"] --> L1["load dimensions"] --> L2["load facts"] --> A["analyze / KPIs"]
```

```python
cost   = round(math.exp(rng.uniform(math.log(5.0), math.log(250.0))), 2)  # log-uniform
hazard = store_rate[store_id] / E_DUR   # store-specific stockout frequency
```

**How I'd defend it.** "It's synthetic and I say so — a one-time seeded generator, not a
production ETL. The seed makes it reproducible, and I injected a known problem so I could prove
my analysis detects it rather than hoping."
