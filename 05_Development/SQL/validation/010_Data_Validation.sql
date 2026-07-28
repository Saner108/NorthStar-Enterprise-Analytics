-- Purpose: Phase 2 data validation — one PASS/FAIL row per profiling check.
-- Business Requirement: FR-P01..FR-P07 (trusted dataset precondition)
-- Business Rule(s): BR-002, BR-007, BR-008, BR-008b, BR-011/012, SCD Type 2 rules
-- Author: Claude Code, reviewed by Project Lead
-- Created Date: 2026-07-28
-- Dependencies: all tables loaded (001-009). Implements the Data Quality Assessment
--   Framework profiling checklist and Fact_Table_Specification.md expected volumes.
--
-- Returns columns: Seq, Check_Name, Expected, Actual, Status ('PASS'/'FAIL').
-- run_pipeline.py exits non-zero if any row is 'FAIL'.

SELECT Seq, Check_Name, Expected, Actual,
       CASE WHEN Pass = 1 THEN 'PASS' ELSE 'FAIL' END AS Status
FROM (
    -- 1. Dim_Date row count = 365 (12-month window)
    SELECT 1 AS Seq, 'Dim_Date row count' AS Check_Name, '365' AS Expected,
           CAST(COUNT(*) AS TEXT) AS Actual, (COUNT(*) = 365) AS Pass
    FROM Dim_Date
    UNION ALL
    -- 2. Dim_Store row count = 23 (22 stores + 1 DC)
    SELECT 2, 'Dim_Store row count (22 stores + 1 DC)', '23',
           CAST(COUNT(*) AS TEXT), (COUNT(*) = 23) FROM Dim_Store
    UNION ALL
    -- 3. Dim_Product row count = 151 (150 SKUs + 1 extra SCD2 version)
    SELECT 3, 'Dim_Product row count (150 SKUs + 1 SCD2 version)', '151',
           CAST(COUNT(*) AS TEXT), (COUNT(*) = 151) FROM Dim_Product
    UNION ALL
    -- 4. Fact_Sales volume roughly matches ~343,200 (tolerance +/- 15%)
    SELECT 4, 'Fact_Sales row count ~343,200 (+/-15%)', '291720..394680',
           CAST(COUNT(*) AS TEXT),
           (COUNT(*) BETWEEN 291720 AND 394680) FROM Fact_Sales
    UNION ALL
    -- 5. Fact_Inventory_Snapshot volume = 23 x 150 x 365 = 1,259,250 (exact)
    SELECT 5, 'Fact_Inventory_Snapshot row count (23x150x365)', '1259250',
           CAST(COUNT(*) AS TEXT), (COUNT(*) = 1259250)
    FROM Fact_Inventory_Snapshot
    UNION ALL
    -- 6. No duplicate inventory grain (Date_Key, Store_Key, Product_Key)
    SELECT 6, 'No duplicate inventory grain keys', '0',
           CAST(COUNT(*) AS TEXT), (COUNT(*) = 0)
    FROM (SELECT 1 FROM Fact_Inventory_Snapshot
          GROUP BY Date_Key, Store_Key, Product_Key HAVING COUNT(*) > 1)
    UNION ALL
    -- 7. Referential integrity: no orphaned Fact_Sales foreign keys
    SELECT 7, 'Fact_Sales orphaned foreign keys', '0',
           CAST(COUNT(*) AS TEXT), (COUNT(*) = 0)
    FROM Fact_Sales fs
    WHERE NOT EXISTS (SELECT 1 FROM Dim_Date dd  WHERE dd.Date_Key  = fs.Date_Key)
       OR NOT EXISTS (SELECT 1 FROM Dim_Store ds WHERE ds.Store_Key = fs.Store_Key)
       OR NOT EXISTS (SELECT 1 FROM Dim_Product dp WHERE dp.Product_Key = fs.Product_Key)
    UNION ALL
    -- 8. Referential integrity: no orphaned Fact_Inventory_Snapshot foreign keys
    SELECT 8, 'Fact_Inventory_Snapshot orphaned foreign keys', '0',
           CAST(COUNT(*) AS TEXT), (COUNT(*) = 0)
    FROM Fact_Inventory_Snapshot fis
    WHERE NOT EXISTS (SELECT 1 FROM Dim_Date dd  WHERE dd.Date_Key  = fis.Date_Key)
       OR NOT EXISTS (SELECT 1 FROM Dim_Store ds WHERE ds.Store_Key = fis.Store_Key)
       OR NOT EXISTS (SELECT 1 FROM Dim_Product dp WHERE dp.Product_Key = fis.Product_Key)
    UNION ALL
    -- 9. No negative measures (BR-002, BR-007)
    SELECT 9, 'No negative sales/inventory measures', '0',
           CAST(COUNT(*) AS TEXT), (COUNT(*) = 0)
    FROM (
        SELECT 1 FROM Fact_Sales WHERE Quantity_Sold < 0 OR Sales_Amount < 0
        UNION ALL
        SELECT 1 FROM Fact_Inventory_Snapshot WHERE Quantity_On_Hand < 0
    )
    UNION ALL
    -- 10. Category limited to the two pilot values (BR-012)
    SELECT 10, 'Category in {Electronics, Home Goods}', '0 violations',
           CAST(COUNT(*) AS TEXT) || ' violations', (COUNT(*) = 0)
    FROM Dim_Product WHERE Category NOT IN ('Electronics', 'Home Goods')
    UNION ALL
    -- 11. All dates within the 12-month pilot window
    SELECT 11, 'Fact dates within pilot window', '0 outside',
           CAST(COUNT(*) AS TEXT) || ' outside', (COUNT(*) = 0)
    FROM (
        SELECT Date_Key FROM Fact_Sales
        UNION ALL SELECT Date_Key FROM Fact_Inventory_Snapshot
    ) WHERE Date_Key < 20250101 OR Date_Key > 20251231
    UNION ALL
    -- 12. SCD2: the reclassified SKU has exactly 2 Dim_Product rows (Decision 4)
    SELECT 12, 'SCD2 SKU-1099 has exactly 2 versions', '2',
           CAST(COUNT(*) AS TEXT), (COUNT(*) = 2)
    FROM Dim_Product WHERE SKU = 'SKU-1099'
    UNION ALL
    -- 13. SCD2: exactly one Is_Current = 1 per SKU
    SELECT 13, 'SCD2 exactly one current version per SKU', '0 violations',
           CAST(COUNT(*) AS TEXT) || ' violations', (COUNT(*) = 0)
    FROM (SELECT SKU FROM Dim_Product GROUP BY SKU
          HAVING SUM(Is_Current) <> 1)
    UNION ALL
    -- 14. SCD2: no overlapping effective ranges for any SKU
    SELECT 14, 'SCD2 no overlapping effective date ranges', '0 overlaps',
           CAST(COUNT(*) AS TEXT) || ' overlaps', (COUNT(*) = 0)
    FROM Dim_Product a
    JOIN Dim_Product b
      ON a.SKU = b.SKU AND a.Product_Key <> b.Product_Key
     AND a.Effective_Start_Date <= COALESCE(b.Effective_End_Date, '9999-12-31')
     AND COALESCE(a.Effective_End_Date, '9999-12-31') >= b.Effective_Start_Date
    UNION ALL
    -- 15. SCD2 join correctness: v1 (Electronics, Product_Key by MIN) only appears in
    --     facts dated on/before its Effective_End_Date; v2 only on/after v2 start.
    SELECT 15, 'SCD2 facts reference historically correct version', '0 misrouted',
           CAST(COUNT(*) AS TEXT) || ' misrouted', (COUNT(*) = 0)
    FROM (
        SELECT fis.Snapshot_Key
        FROM Fact_Inventory_Snapshot fis
        JOIN Dim_Product dp ON fis.Product_Key = dp.Product_Key
        JOIN Dim_Date dd ON fis.Date_Key = dd.Date_Key
        WHERE dp.SKU = 'SKU-1099'
          AND (dd.Full_Date < dp.Effective_Start_Date
               OR dd.Full_Date > COALESCE(dp.Effective_End_Date, '9999-12-31'))
    )
    UNION ALL
    -- 16. KPI-P03 known-answer: at least one Distribution Issue stockout exists
    SELECT 16, 'KPI-P03 >= 1 Distribution Issue stockout', '>= 1',
           CAST(COUNT(*) AS TEXT), (COUNT(*) >= 1)
    FROM Fact_Inventory_Snapshot fis
    WHERE fis.Quantity_On_Hand = 0
      AND (SELECT COALESCE(SUM(fis2.Quantity_On_Hand), 0)
           FROM Fact_Inventory_Snapshot fis2
           WHERE fis2.Product_Key = fis.Product_Key
             AND fis2.Date_Key = fis.Date_Key
             AND fis2.Store_Key <> fis.Store_Key) > 0
    UNION ALL
    -- 17. KPI-P03 known-answer: at least one True Shortage stockout exists
    SELECT 17, 'KPI-P03 >= 1 True Shortage stockout', '>= 1',
           CAST(COUNT(*) AS TEXT), (COUNT(*) >= 1)
    FROM Fact_Inventory_Snapshot fis
    WHERE fis.Quantity_On_Hand = 0
      AND (SELECT COALESCE(SUM(fis2.Quantity_On_Hand), 0)
           FROM Fact_Inventory_Snapshot fis2
           WHERE fis2.Product_Key = fis.Product_Key
             AND fis2.Date_Key = fis.Date_Key
             AND fis2.Store_Key <> fis.Store_Key) = 0
) checks
ORDER BY Seq;
