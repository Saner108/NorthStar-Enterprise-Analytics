# SQL DEVELOPMENT STANDARDS

Version: 1.0

Project:
NorthStar Retail Group
Inventory Visibility Pilot — Electronics & Home Goods, Southwest Region

Status: Approved
Scope Note: Coding standards apply regardless of project scale, so most of the enterprise version carries over unchanged. Adjustments below are limited to references that assume a live multi-developer team, a source system to reconcile against, or customer data — none of which apply to this solo, pilot-scoped, synthetic-data project. This document is written to be directly actionable by an implementation agent (e.g., Claude Code) working from this repo — every rule here should be followed literally when generating SQL for this project, with no ambiguity left for interpretation.

---

# Guiding Principles

Simple before clever. Readable before compact. Optimized only after correctness is verified. Documented so the logic is understandable without the original author present — including by the analyst reviewing Claude Code's output.

---

# Naming Conventions (Unchanged from Enterprise Standard)

**Tables:** `Fact_Sales`, `Fact_Inventory_Snapshot`, `Dim_Product`, `Dim_Store`, `Dim_Date`

**Views:** `vw_InStockRate`, `vw_StockoutClassification`, `vw_EstimatedLostMargin` (prefix `vw_`, PascalCase, name describes the business question answered — not the tables involved)

**Columns:** Descriptive, no abbreviations — `Sales_Amount`, `Quantity_On_Hand`, `Estimated_Lost_Margin`, not `SlsAmt` or `QOH`

**Aliases:** Meaningful, not single letters — `Fact_Sales AS fs`, `Dim_Product AS dp`, `Fact_Inventory_Snapshot AS fis`

---

# Formatting Standards

- Keywords uppercase: `SELECT`, `FROM`, `WHERE`, `GROUP BY`, `JOIN`
- Explicit JOIN syntax only — never comma joins
- One selected column per line for any query longer than ~3 columns
- Indent nested queries and CTEs clearly

---

# Required Script Header (Every SQL File)

Every `.sql` file in this repo must begin with a comment block:

```sql
-- Purpose: [What business question this answers]
-- Business Requirement: [FR-P0X reference from Business_Requirements_Document.md]
-- Business Rule(s): [BR-XXX reference from Business_Rules_Catalog.md]
-- Author: [Project Lead / Claude Code, if implementation-agent generated]
-- Created Date: [date]
-- Dependencies: [tables/views this query requires]
```

**This is not optional decoration** — it's what makes every query traceable back to a specific documented requirement, consistent with the Business Rules Catalog's Definition of Done: no KPI or query exists "because it seemed useful," only because it answers something already justified in this repo.

---

# JOIN Standards (Pilot-Specific Note)

- Standard: explicit `INNER JOIN` / `LEFT JOIN`, never implicit comma joins.
- **Special case for this pilot:** any join from `Fact_Sales` or `Fact_Inventory_Snapshot` to `Dim_Product` must account for SCD Type 2 (per Dimension_Table_Specifications.md and Source_to_Target_Mapping.md) — this is **not** a simple `ON fs.Product_Key = dp.Product_Key` lookup by current version. The join must resolve to whichever `Dim_Product` row was effective on the fact row's date:

```sql
-- Correct SCD Type 2-aware join pattern
FROM Fact_Sales fs
JOIN Dim_Product dp
    ON fs.SKU = dp.SKU  -- or fs.Product_Key if surrogate key was already resolved at load time
    AND fs.Transaction_Date >= dp.Effective_Start_Date
    AND (fs.Transaction_Date < dp.Effective_End_Date OR dp.Effective_End_Date IS NULL)
```

If Product_Key is already correctly resolved at load time (per Source_to_Target_Mapping.md), a simple `Product_Key` join is fine at query time — the SCD-aware logic only needs to run once, during load, not on every downstream query. Which approach was used should be stated explicitly in the script header's Dependencies line.

---

# NULL Handling

- No column in this pilot's schema is expected to be NULL except `Effective_End_Date` in `Dim_Product` (NULL = currently active version) — this is an intentional NULL, not a data quality issue, and should be handled with `IS NULL` checks, not `COALESCE`.
- Never assume NULL equals zero in aggregations.

---

# Core Query Patterns This Pilot Will Need

Rather than generic aggregation examples, here are the specific query shapes this project's KPIs require — Claude Code should implement these patterns directly:

**KPI-P01 (In-Stock Rate):**
```sql
-- Purpose: Calculate daily in-stock rate by store
-- Business Rule: BR-008
SELECT
    ds.Store_Name,
    dd.Full_Date,
    COUNT(CASE WHEN fis.Quantity_On_Hand > 0 THEN 1 END) * 100.0 / COUNT(*) AS In_Stock_Rate_Pct
FROM Fact_Inventory_Snapshot fis
JOIN Dim_Store ds ON fis.Store_Key = ds.Store_Key
JOIN Dim_Date dd ON fis.Date_Key = dd.Date_Key
WHERE ds.Location_Type = 'Store'  -- exclude the DC from store-level in-stock rate
GROUP BY ds.Store_Name, dd.Full_Date
```

**KPI-P03 (Distribution vs. Shortage) — the pilot's core hypothesis test:**
```sql
-- Purpose: Classify each stockout as distribution issue vs. true shortage
-- Business Rule: BR-008b
SELECT
    fis.Store_Key,
    fis.Product_Key,
    fis.Date_Key,
    (SELECT SUM(fis2.Quantity_On_Hand)
     FROM Fact_Inventory_Snapshot fis2
     WHERE fis2.Product_Key = fis.Product_Key
       AND fis2.Date_Key = fis.Date_Key
       AND fis2.Store_Key != fis.Store_Key) AS Pooled_Regional_Inventory,
    CASE
        WHEN (SELECT SUM(fis2.Quantity_On_Hand)
              FROM Fact_Inventory_Snapshot fis2
              WHERE fis2.Product_Key = fis.Product_Key
                AND fis2.Date_Key = fis.Date_Key
                AND fis2.Store_Key != fis.Store_Key) > 0
        THEN 'Distribution Issue'
        ELSE 'True Shortage'
    END AS Classification
FROM Fact_Inventory_Snapshot fis
WHERE fis.Quantity_On_Hand = 0
```

**Note for Claude Code implementation:** the correlated subquery pattern above is clear and correct but not the most performant approach at scale; given this pilot's actual row count (~1.26M rows, per Fact_Table_Specification.md), it will run acceptably. If performance becomes an issue, a window function (`SUM() OVER (PARTITION BY Product_Key, Date_Key)`) would be the optimization path — but per the earlier documented principle, don't add that complexity unless the simple version actually proves too slow.

---

# Performance Best Practices (Right-Sized Per Fact_Table_Specification.md)

- Select only required columns; avoid `SELECT *` even in a small pilot — it's a habit worth keeping regardless of scale.
- No custom indexing/partitioning strategy is needed at this pilot's volume (~1.6M total rows) — standard primary key constraints are sufficient, per the volume analysis already documented.
- Prefer CTEs over deeply nested subqueries for readability, even though performance wouldn't meaningfully differ at this scale — this is a maintainability choice, not a performance one, at this row count.

---

# Data Validation (Pilot-Adjusted)

Before treating any query result as final:

- Compare totals against the **expected row counts and value ranges documented in Fact_Table_Specification.md** — there is no external source system to reconcile against, since this is generated data, but there is a documented expectation to check against.
- Confirm the SCD Type 2 join resolves correctly for the one deliberately-reclassified SKU (spot-check before/after its `Effective_Start_Date`).
- Confirm KPI-P03 produces at least one "Distribution Issue" and one "True Shortage" result, matching the deliberately-generated test scenarios noted in Data_Generation_Pipeline_Design.md.

---

# Version Control (Adjusted for Solo + Implementation-Agent Workflow)

- All SQL scripts stored in this GitHub repo under `05_Development/SQL/`.
- Since this is a solo project with Claude Code as an implementation agent rather than a multi-developer team, "pull request peer review" becomes: **every generated script/change should be reviewed against this Standards document and the relevant KPI/Business Rule before being merged** — the review checklist below still applies, just performed by the analyst rather than a second developer.
- Every script still requires the header block (Purpose, Business Requirement, Business Rule, Author, Created Date, Dependencies) — if Claude Code generates a script, "Author" should note that explicitly (e.g., "Claude Code, reviewed by [Project Lead]").

---

# Code Review Checklist (Self-Review, Solo Project)

Before accepting any Claude Code-generated SQL as final:

- [ ] Follows naming conventions above
- [ ] Header block present and accurate
- [ ] Business logic matches the exact rule in Business_Rules_Catalog.md (especially BR-008 vs. BR-008a vs. BR-008b — these are easy to conflate, as demonstrated earlier in this project's own planning process)
- [ ] SCD Type 2 join handled correctly wherever Dim_Product is involved
- [ ] No unnecessary complexity for this pilot's actual scale
- [ ] Validation checks (above) have been run and pass

---

# Common Mistakes to Guard Against (Pilot-Specific Addition)

In addition to the standard list (SELECT *, ignoring NULLs, inconsistent aliases): **conflating stockout detection with stockout impact** is this project's own documented near-miss (see the earlier correction in this project's development where "stockout" was initially proposed to require zero sales, not just zero inventory). Any SQL that filters `Fact_Inventory_Snapshot` by a `Sales_Amount = 0` condition as part of *detecting* a stockout is implementing the wrong rule — flag this explicitly in review.

---

# Success Criteria

SQL standards are being followed correctly when every script in `05_Development/SQL/` has a complete header, implements the exact business rule it claims to (verifiable against Business_Rules_Catalog.md), and could be understood by a reviewer with no additional explanation needed.
