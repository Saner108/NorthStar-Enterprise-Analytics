-- Purpose: KPI-P02 Estimated Lost Margin from stockouts, ranked by store x product.
-- Business Requirement: FR-P04
-- Business Rule(s): BR-008a (impact estimation), BR-014/BR-015 (unit margin)
-- Author: Claude Code, reviewed by Project Lead
-- Created Date: 2026-07-28
-- Dependencies: Fact_Inventory_Snapshot (in-stock/stockout days), Fact_Sales
--   (baseline sales rate), Dim_Product (margin), Dim_Store. Grain: store x
--   Product_Key (the SCD Type 2 version-specific key resolved at load).
--
-- BR-008a: estimated lost units = (baseline daily sales rate on IN-STOCK days)
--   x (number of stockout days); estimated lost margin = lost units x (Retail_Price
--   - Unit_Cost). This is DISTINCT from BR-008 detection and BR-008b classification
--   (Decision 3) — it is impact/cost estimation, not stockout detection.

WITH inventory_days AS (
    SELECT
        Store_Key,
        Product_Key,
        SUM(CASE WHEN Quantity_On_Hand > 0 THEN 1 ELSE 0 END) AS In_Stock_Days,
        SUM(CASE WHEN Quantity_On_Hand = 0 THEN 1 ELSE 0 END) AS Stockout_Days
    FROM Fact_Inventory_Snapshot
    GROUP BY Store_Key, Product_Key
),
baseline_sales AS (
    SELECT
        Store_Key,
        Product_Key,
        SUM(Quantity_Sold) AS Total_Units_Sold
    FROM Fact_Sales
    GROUP BY Store_Key, Product_Key
)
SELECT
    ds.Store_Name,
    dp.SKU,
    dp.Product_Name,
    dp.Category,
    inv.Stockout_Days,
    ROUND(
        CASE WHEN inv.In_Stock_Days > 0
             THEN 1.0 * COALESCE(bs.Total_Units_Sold, 0) / inv.In_Stock_Days
             ELSE 0 END, 4) AS Baseline_Daily_Sales_Rate,
    ROUND(
        CASE WHEN inv.In_Stock_Days > 0
             THEN 1.0 * COALESCE(bs.Total_Units_Sold, 0) / inv.In_Stock_Days
             ELSE 0 END * inv.Stockout_Days, 2) AS Estimated_Lost_Units,
    ROUND(
        CASE WHEN inv.In_Stock_Days > 0
             THEN 1.0 * COALESCE(bs.Total_Units_Sold, 0) / inv.In_Stock_Days
             ELSE 0 END * inv.Stockout_Days
        * (dp.Retail_Price - dp.Unit_Cost), 2) AS Estimated_Lost_Margin
FROM inventory_days inv
JOIN Dim_Store   ds ON inv.Store_Key   = ds.Store_Key
JOIN Dim_Product dp ON inv.Product_Key = dp.Product_Key
LEFT JOIN baseline_sales bs
       ON inv.Store_Key = bs.Store_Key AND inv.Product_Key = bs.Product_Key
WHERE ds.Location_Type = 'Store'        -- lost SALES margin is a store-level concept
  AND inv.Stockout_Days > 0
ORDER BY Estimated_Lost_Margin DESC;
