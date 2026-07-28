-- Purpose: KPI-P05 Gross Margin % at the product level.
-- Business Requirement: FR-P04 (supports margin weighting)
-- Business Rule(s): BR-014 (gross profit = Retail_Price - Unit_Cost), BR-015 (margin %)
-- Author: Claude Code, reviewed by Project Lead
-- Created Date: 2026-07-28
-- Dependencies: Dim_Product.
--
-- Gross Margin % = (Retail_Price - Unit_Cost) / Retail_Price x 100, at the SKU level.
-- Reported for the CURRENT version of each SKU (Is_Current = 1); an input to KPI-P02
-- and a filter/sort dimension, not typically a standalone dashboard visual.

SELECT
    dp.SKU,
    dp.Product_Name,
    dp.Category,
    dp.Unit_Cost,
    dp.Retail_Price,
    ROUND((dp.Retail_Price - dp.Unit_Cost), 2) AS Gross_Profit_Per_Unit,
    ROUND((dp.Retail_Price - dp.Unit_Cost) / dp.Retail_Price * 100, 2) AS Gross_Margin_Pct
FROM Dim_Product dp
WHERE dp.Is_Current = 1
ORDER BY Gross_Margin_Pct DESC;
