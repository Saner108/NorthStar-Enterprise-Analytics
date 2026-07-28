-- Purpose: Create the four Power BI-ready reporting views (Phase 4).
-- Business Requirement: FR-P01, FR-P04, FR-P05, FR-P07
-- Business Rule(s): BR-008 (P01), BR-008a (lost margin), BR-008b (classification),
--                   BR-002/003 (revenue)
-- Author: Claude Code, reviewed by Project Lead
-- Created Date: 2026-07-28
-- Dependencies: all tables loaded (001-009). Views named per SQL_Development_Standards.md
--   (vw_ prefix, PascalCase, named for the business question). Deliberately excluded:
--   vw_CustomerInsights (no CRM data) and a generic vw_ExecutiveDashboard (this pilot
--   has one dashboard; these four views feed it directly).

-- ---------------------------------------------------------------------------
-- vw_InStockRate — store/day in-stock rate (KPI-P01, BR-008). DC excluded.
-- ---------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_InStockRate;
CREATE VIEW vw_InStockRate AS
SELECT
    ds.Store_Key,
    ds.Store_Name,
    dd.Date_Key,
    dd.Full_Date,
    dd.Year,
    dd.Month,
    dd.Month_Name,
    COUNT(*)                                                   AS Assortment_SKUs,
    COUNT(CASE WHEN fis.Quantity_On_Hand > 0 THEN 1 END)      AS In_Stock_SKUs,
    COUNT(CASE WHEN fis.Quantity_On_Hand > 0 THEN 1 END) * 100.0 / COUNT(*)
                                                              AS In_Stock_Rate_Pct
FROM Fact_Inventory_Snapshot fis
JOIN Dim_Store ds ON fis.Store_Key = ds.Store_Key
JOIN Dim_Date  dd ON fis.Date_Key  = dd.Date_Key
WHERE ds.Location_Type = 'Store'
GROUP BY ds.Store_Key, ds.Store_Name, dd.Date_Key, dd.Full_Date,
         dd.Year, dd.Month, dd.Month_Name;

-- ---------------------------------------------------------------------------
-- vw_StockoutClassification — per-stockout distribution/shortage label (KPI-P03,
-- BR-008b). One row per store stockout event (store/SKU/day).
-- ---------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_StockoutClassification;
CREATE VIEW vw_StockoutClassification AS
SELECT
    ds.Store_Key,
    ds.Store_Name,
    dp.Product_Key,
    dp.SKU,
    dp.Product_Name,
    dp.Category,
    dd.Date_Key,
    dd.Full_Date,
    (SELECT COALESCE(SUM(fis2.Quantity_On_Hand), 0)
     FROM Fact_Inventory_Snapshot fis2
     WHERE fis2.Product_Key = fis.Product_Key
       AND fis2.Date_Key    = fis.Date_Key
       AND fis2.Store_Key   <> fis.Store_Key)                 AS Pooled_Regional_Inventory,
    CASE
        WHEN (SELECT COALESCE(SUM(fis2.Quantity_On_Hand), 0)
              FROM Fact_Inventory_Snapshot fis2
              WHERE fis2.Product_Key = fis.Product_Key
                AND fis2.Date_Key    = fis.Date_Key
                AND fis2.Store_Key   <> fis.Store_Key) > 0
        THEN 'Distribution Issue'
        ELSE 'True Shortage'
    END                                                       AS Classification
FROM Fact_Inventory_Snapshot fis
JOIN Dim_Store   ds ON fis.Store_Key   = ds.Store_Key
JOIN Dim_Product dp ON fis.Product_Key = dp.Product_Key
JOIN Dim_Date    dd ON fis.Date_Key    = dd.Date_Key
WHERE fis.Quantity_On_Hand = 0
  AND ds.Location_Type = 'Store';

-- ---------------------------------------------------------------------------
-- vw_EstimatedLostMargin — store/SKU lost-margin estimate (KPI-P02, BR-008a).
-- ---------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_EstimatedLostMargin;
CREATE VIEW vw_EstimatedLostMargin AS
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
    SELECT Store_Key, Product_Key, SUM(Quantity_Sold) AS Total_Units_Sold
    FROM Fact_Sales
    GROUP BY Store_Key, Product_Key
)
SELECT
    ds.Store_Key,
    ds.Store_Name,
    dp.Product_Key,
    dp.SKU,
    dp.Product_Name,
    dp.Category,
    inv.Stockout_Days,
    CASE WHEN inv.In_Stock_Days > 0
         THEN 1.0 * COALESCE(bs.Total_Units_Sold, 0) / inv.In_Stock_Days
         ELSE 0 END                                            AS Baseline_Daily_Sales_Rate,
    CASE WHEN inv.In_Stock_Days > 0
         THEN 1.0 * COALESCE(bs.Total_Units_Sold, 0) / inv.In_Stock_Days
         ELSE 0 END * inv.Stockout_Days                        AS Estimated_Lost_Units,
    CASE WHEN inv.In_Stock_Days > 0
         THEN 1.0 * COALESCE(bs.Total_Units_Sold, 0) / inv.In_Stock_Days
         ELSE 0 END * inv.Stockout_Days
         * (dp.Retail_Price - dp.Unit_Cost)                    AS Estimated_Lost_Margin
FROM inventory_days inv
JOIN Dim_Store   ds ON inv.Store_Key   = ds.Store_Key
JOIN Dim_Product dp ON inv.Product_Key = dp.Product_Key
LEFT JOIN baseline_sales bs
       ON inv.Store_Key = bs.Store_Key AND inv.Product_Key = bs.Product_Key
WHERE ds.Location_Type = 'Store'
  AND inv.Stockout_Days > 0;

-- ---------------------------------------------------------------------------
-- vw_PilotRevenueSummary — monthly revenue context (KPI-P04, BR-002/003).
-- ---------------------------------------------------------------------------
DROP VIEW IF EXISTS vw_PilotRevenueSummary;
CREATE VIEW vw_PilotRevenueSummary AS
SELECT
    dd.Year,
    dd.Month,
    dd.Month_Name,
    SUM(fs.Sales_Amount)   AS Monthly_Revenue,
    SUM(fs.Quantity_Sold)  AS Units_Sold,
    COUNT(*)               AS Transaction_Line_Count
FROM Fact_Sales fs
JOIN Dim_Date dd ON fs.Date_Key = dd.Date_Key
GROUP BY dd.Year, dd.Month, dd.Month_Name;
