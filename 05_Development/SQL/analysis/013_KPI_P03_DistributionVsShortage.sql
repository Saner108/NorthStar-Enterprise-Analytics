-- Purpose: KPI-P03 Distribution vs. Shortage — the pilot's core hypothesis test.
-- Business Requirement: FR-P07
-- Business Rule(s): BR-008b (pooled regional inventory classification)
-- Author: Claude Code, reviewed by Project Lead
-- Created Date: 2026-07-28
-- Dependencies: Fact_Inventory_Snapshot (self-comparison across Dim_Store).
--
-- BR-008b: for each stockout (BR-008: Quantity_On_Hand = 0), sum Quantity_On_Hand for
-- the SAME Product_Key on the SAME Date_Key across ALL OTHER locations (other stores +
-- the regional DC). Pooled >= 3 units -> 'Distribution Issue'; pooled 0-2 -> 'True Shortage'
-- (3-unit redistributable-surplus floor; a 1-2 unit remnant is not shippable stock).
-- Because Product_Key is the SCD Type 2 version effective on the date, all locations on
-- a given date share the same Product_Key for a SKU, so pooling by Product_Key+Date_Key
-- is correct. This script returns the headline split (the dashboard's hero visual);
-- vw_StockoutClassification (016) exposes the per-stockout detail.
--
-- The correlated-subquery pattern below is the form documented in
-- SQL_Development_Standards.md; at this pilot's volume it runs acceptably against the
-- (Product_Key, Date_Key) index. A SUM() OVER (PARTITION BY ...) rewrite is the
-- sanctioned optimization path ONLY if it ever proves too slow — not preemptively.

WITH stockout_classification AS (
    SELECT
        fis.Snapshot_Key,
        CASE
            WHEN (SELECT COALESCE(SUM(fis2.Quantity_On_Hand), 0)
                  FROM Fact_Inventory_Snapshot fis2
                  WHERE fis2.Product_Key = fis.Product_Key
                    AND fis2.Date_Key    = fis.Date_Key
                    AND fis2.Store_Key   <> fis.Store_Key) > 2  -- BR-008b: >=3 units = redistributable surplus (1-2 = shelf remnant)
            THEN 'Distribution Issue'
            ELSE 'True Shortage'
        END AS Classification
    FROM Fact_Inventory_Snapshot fis
    JOIN Dim_Store ds ON fis.Store_Key = ds.Store_Key
    WHERE fis.Quantity_On_Hand = 0
      AND ds.Location_Type = 'Store'    -- classify store stockouts (the DC is the pool)
)
SELECT
    Classification,
    COUNT(*) AS Stockout_Events,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS Pct_Of_Stockouts
FROM stockout_classification
GROUP BY Classification
ORDER BY Stockout_Events DESC;
