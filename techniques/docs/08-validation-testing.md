# 8 — Known-Answer Testing & Automated Validation

**What it is.** The pipeline ends with **17 automated integrity checks** plus **known-answer
tests**: coordinates where I *already know* the correct classification, so I can confirm the
analysis is correct, not merely that it ran without error.

**Why I chose it.** "It ran" is not "it's right." Row counts, grain uniqueness, referential
integrity, SCD2 correctness, and the two injected classification cases each assert a specific
expected value. This is the difference between a script and a *trustworthy* pipeline — and it's
exactly what caught a real bug: a validation query that had drifted out of sync with the KPI it
was meant to check (it counted the DC's own zero rows as stockouts).

**What it looks like.**

| # | Check | Expected | Actual |
|---|---|---|---|
| 5 | Inventory rows = 23×150×365 | 1,259,250 | 1,259,250 ✅ |
| 12 | SCD2 SKU has exactly 2 versions | 2 | 2 ✅ |
| 15 | Facts join to date-correct version | 0 misrouted | 0 ✅ |
| 16/17 | Known Distribution & Shortage cases exist | ≥1 each | ✅ |

```
>>> all 17 validation checks PASSED
```

**How I'd defend it.** "I don't trust a pipeline that just runs. I assert row counts, integrity,
and two known-answer cases. That discipline caught a validation query that had drifted from the
KPI it was checking."
