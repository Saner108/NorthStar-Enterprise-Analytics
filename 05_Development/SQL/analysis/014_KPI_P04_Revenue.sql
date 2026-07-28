-- Purpose: KPI-P04 Revenue — total pilot-region revenue, as a monthly trend.
-- Business Requirement: FR-P05
-- Business Rule(s): BR-001, BR-002 (Sales_Amount), BR-003 (attributed to date)
-- Author: Claude Code, reviewed by Project Lead
-- Created Date: 2026-07-28
-- Dependencies: Fact_Sales, Dim_Date.
--
-- Context metric — mainly the denominator for interpreting KPI-P02's lost margin.
-- Monthly grain feeds the trend line; SUM(Sales_Amount) over the window is the total.

SELECT
    dd.Year,
    dd.Month,
    dd.Month_Name,
    ROUND(SUM(fs.Sales_Amount), 2) AS Monthly_Revenue,
    SUM(fs.Quantity_Sold)          AS Units_Sold
FROM Fact_Sales fs
JOIN Dim_Date dd ON fs.Date_Key = dd.Date_Key
GROUP BY dd.Year, dd.Month, dd.Month_Name
ORDER BY dd.Year, dd.Month;
