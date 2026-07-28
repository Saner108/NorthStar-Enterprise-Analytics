-- Purpose: KPI-P01 In-Stock Rate — % of a store's assortment in stock, by store/day.
-- Business Requirement: FR-P01
-- Business Rule(s): BR-008 (stockout = Quantity_On_Hand = 0; detection only)
-- Author: Claude Code, reviewed by Project Lead
-- Created Date: 2026-07-28
-- Dependencies: Fact_Inventory_Snapshot, Dim_Store, Dim_Date
--
-- Note: this is BR-008 DETECTION only — no sales/demand condition is attached
-- (Decision 3). The DC is excluded via Location_Type = 'Store' because it does not
-- sell directly to customers (BR-013). Grain: store x day. This query is the
-- canonical pattern documented in SQL_Development_Standards.md.

SELECT
    ds.Store_Name,
    dd.Full_Date,
    COUNT(CASE WHEN fis.Quantity_On_Hand > 0 THEN 1 END) * 100.0 / COUNT(*)
        AS In_Stock_Rate_Pct
FROM Fact_Inventory_Snapshot fis
JOIN Dim_Store ds ON fis.Store_Key = ds.Store_Key
JOIN Dim_Date  dd ON fis.Date_Key  = dd.Date_Key
WHERE ds.Location_Type = 'Store'        -- exclude the DC from store-level in-stock rate
GROUP BY ds.Store_Name, dd.Full_Date
ORDER BY ds.Store_Name, dd.Full_Date;
