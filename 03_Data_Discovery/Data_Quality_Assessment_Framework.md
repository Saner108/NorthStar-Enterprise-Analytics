# DATA QUALITY ASSESSMENT FRAMEWORK

Version: 1.0

Project:
NorthStar Retail Group
Inventory Visibility Pilot — Electronics & Home Goods, Southwest Region

Status: Approved
Scope Note: This framework applies the same six data quality dimensions used in the enterprise version, but reinterprets them for a synthesized-data pilot rather than live production systems. The dimensions themselves don't change — only how they're measured.

---

# Purpose

Even though this pilot's data is synthesized rather than pulled from live systems, applying real data quality discipline to the generation process is what makes the resulting analysis defensible. "It's just test data" is not an excuse to skip validation — a data model with silent integrity bugs produces wrong KPIs regardless of where the data came from.

---

# Data Quality Dimensions (Reinterpreted for Synthetic Pilot Data)

## 1. Completeness

**Definition:** Every store/SKU/day combination that should exist, does exist.

**Pilot Check:** For the trailing 12-month window, every pilot store should have an Inventory_Snapshot row for every SKU on every day — no missing days, no missing SKU/store pairs.

**Business Impact if Violated:** A missing snapshot day would look identical to "no data available," which could be misread as a stockout or hide a real one.

---

## 2. Accuracy

**Definition:** Generated values reflect plausible real-world retail behavior, not arbitrary numbers.

**Pilot Check:** Sales volumes and inventory levels should follow believable patterns (e.g., higher electronics sales around known seasonal periods, inventory declining with sales and increasing only via modeled transfer/receipt events — never changing without a logical cause).

**Business Impact if Violated:** Unrealistic data produces findings that wouldn't hold up if challenged ("would this actually happen in a real store?").

---

## 3. Consistency

**Definition:** The same Store_ID, SKU, and identifiers are used identically across all three tables (Sales_Transactions, Inventory_Snapshot, Product_Master, Store_Dimension).

**Pilot Check:** No variant spellings/formats of the same store or product ID across tables.

**Business Impact if Violated:** Inconsistent IDs break joins silently, causing undercounted or duplicated results with no obvious error message.

---

## 4. Validity

**Definition:** Values follow the business rules documented in the Data Dictionary.

**Pilot Check (examples):**
- Quantity_On_Hand ≥ 0 always
- Sales_Amount = Quantity × Unit_Price, always
- Transaction_Date and Snapshot_Date fall within the defined 12-month pilot window
- Category is only "Electronics" or "Home Goods"

**Business Impact if Violated:** Invalid records distort KPI calculations (e.g., a negative inventory value would make a store look "worse than stocked out," which isn't a real state).

---

## 5. Uniqueness

**Definition:** No duplicate primary keys.

**Pilot Check:** Transaction_ID unique in Sales_Transactions; (Snapshot_Date, Location_ID, SKU) combination unique in Inventory_Snapshot.

**Business Impact if Violated:** Duplicate rows would inflate sales totals or create ambiguous inventory readings (two different quantities for the same store/SKU/day).

---

## 6. Timeliness (Reinterpreted for Synthetic Data)

**Definition:** For synthetic data, timeliness isn't about live refresh speed — it's about whether the simulated timeline is internally coherent.

**Pilot Check:** Inventory_Snapshot dates form a complete, unbroken daily sequence for the pilot window; no snapshot exists "ahead of" its simulated date; sales transactions never reference a date outside the modeled inventory timeline.

**Business Impact if Violated:** A broken timeline would make trend analysis (Phase 5) invalid — you can't calculate a 12-month in-stock rate trend if the underlying dates have gaps or overlaps.

---

# Data Quality Scorecard (Pilot Targets)

| Dimension | Target | Validation Method |
|---|---|---|
| Completeness | 100% (no missing store/SKU/day rows) | Row count check: expected rows = stores × SKUs × days |
| Accuracy | Plausibility review | Spot-check distributions against expected retail seasonality |
| Consistency | 100% | Join validation — zero orphaned foreign keys |
| Validity | 100% | Automated business rule checks (Quantity ≥ 0, etc.) |
| Uniqueness | 100% | Primary key duplicate check |
| Timeliness | 100% (no date gaps) | Sequential date check on Inventory_Snapshot |

**Note:** Pilot targets are set at 100% for objective/structural checks (completeness, uniqueness, validity, consistency, timeliness) because this is generated data under our control — unlike live enterprise data, there's no excuse for structural errors we introduced ourselves. "Accuracy" remains a judgment call validated by plausibility review, since there's no external ground truth to compare synthetic data against.

---

# Data Profiling Checklist (Applied Before Any Analysis)

- [ ] Row count matches expected (stores × SKUs × days)
- [ ] No duplicate primary keys
- [ ] No missing values in required fields (per Data Dictionary null rules)
- [ ] All Store_IDs in Sales_Transactions/Inventory_Snapshot exist in Store_Dimension
- [ ] All SKUs in Sales_Transactions/Inventory_Snapshot exist in Product_Master
- [ ] Category values limited to Electronics/Home Goods only
- [ ] Date ranges fall within the defined 12-month window
- [ ] No negative Quantity_On_Hand or Sales_Amount values

---

# Common Data Quality Issues to Guard Against (Pilot-Specific)

## Orphaned Foreign Keys
**Example:** A Sales_Transactions row references a SKU not present in Product_Master.
**Cause in a synthetic pilot:** Generation script bug — SKU list used to generate sales doesn't match SKU list used to generate Product_Master.
**Fix:** Generate the SKU/Store master lists first, then reference those same lists in every downstream table.

## Impossible Inventory Values
**Example:** Quantity_On_Hand goes negative.
**Cause:** Generation logic allowed sales to exceed available inventory without decrementing correctly.
**Fix:** Inventory decrement logic must be tied directly to sales generation, not generated independently.

## Timeline Gaps
**Example:** Inventory_Snapshot missing rows for several consecutive days.
**Cause:** Loop/range error in generation script.
**Fix:** Explicitly validate date range completeness as a generation script test, not just an afterthought.

---

# Severity Levels (Pilot Context)

- **Critical:** Would invalidate the core in-stock rate KPI (e.g., duplicate snapshot rows, orphaned foreign keys)
- **High:** Would distort but not invalidate findings (e.g., unrealistic seasonality patterns)
- **Medium/Low:** Cosmetic (e.g., inconsistent capitalization in Store_Name)

---

# Success Criteria

This assessment is complete when:

- The data profiling checklist has been run against the generated dataset and passes.
- Any failed checks have a documented root cause and fix, not a workaround.
- The analyst can confidently say the in-stock rate KPI is built on structurally sound data before any findings are presented.

---

# Analyst Reflection

Before trusting the generated dataset:

- Do I understand exactly how this data was generated, since I generated it myself?
- Would these numbers make sense if a real store manager saw them?
- Have I validated referential integrity, not just eyeballed a few rows?
- Can I defend this data model's soundness if directly challenged in an interview?
