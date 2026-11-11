/*
=============================================================
SANDWICH ANALYTICS
04 | SQL ANALYSIS & BUSINESS KPIs
=============================================================
------------------------------------------------------------
OBJECTIVE
- Benchmark store performance.
- Evaluate product profitability.
- Identify financial improvement opportunities.
- Quantify potential business impact.

DATA SOURCES
- 01_receipts: Store revenue and transactions.
- 03_items_receipt: Product sales and costs.
- 04_items_menu: Product names and categories.

METHODOLOGY
- Store revenue = subtotal - discount (excludes sales tax).
- Gross Profit = Product Sales - COGS.
- Gross Margin = Gross Profit / Product Sales.
- 2012 is the reference year for store comparisons
  and financial scenarios.
- Data cleaning and cost imputation were completed
  before this analysis.

All queries are read-only.
*/


-- ==========================================================
-- 01. BUSINESS OVERVIEW
-- ==========================================================

-- BUSINESS QUESTION
-- What is the overall scale of the business?

USE sandwich_analytics;
SELECT
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT store_num) AS active_stores,
    MIN(receipt_date) AS first_sale_date,
    MAX(receipt_date) AS last_sale_date,
    COUNT(DISTINCT receipt_date) AS sales_days,
    ROUND(SUM(sub_total - discount_amt), 2) AS net_revenue,
    ROUND(AVG(sub_total - discount_amt), 2) AS avg_order_value
FROM `01_receipts`;

-- KEY FINDINGS
-- 9.50M transactions across 25 stores.
-- Period: January 2003 - May 2013.
-- Net Revenue: 76.74M.
-- Average Order Value: 8.08.
-- AOV includes all receipt records, including returns.


-- ==========================================================
-- 02. REVENUE TRENDS
-- ==========================================================

-- BUSINESS QUESTION
-- How has network revenue evolved over time?


-- 02.1 Annual Revenue & Network Expansion

SELECT
    YEAR(receipt_date) AS year,
    COUNT(*) AS transactions,
    COUNT(DISTINCT store_num) AS active_stores,
    COUNT(DISTINCT receipt_date) AS sales_days,
    ROUND(SUM(sub_total - discount_amt), 2) AS net_revenue,
    ROUND(
        SUM(sub_total - discount_amt) /
        COUNT(DISTINCT store_num), 2
    ) AS revenue_per_store
FROM `01_receipts`
GROUP BY YEAR(receipt_date)
ORDER BY year;

-- KEY FINDINGS
-- Revenue grew substantially between 2003 and 2012.
-- 2009-2010: revenue +47.6%; active stores 17 -> 24.
-- 2011: highest full-year revenue, 12.69M.
-- 2012: revenue declined approximately 2%.
-- Network expansion explains part of the revenue growth.

-- LIMITATIONS
-- 2013 is incomplete and excluded from full-year comparisons.
-- Revenue per store does not adjust for individual
-- store operating periods.


-- 02.2 Monthly Revenue Patterns

-- Compare months across complete calendar years.
-- Revenue per sales day adjusts for month length.

SELECT
    MONTH(receipt_date) AS month,
    COUNT(*) AS transactions,
    ROUND(SUM(sub_total - discount_amt), 2) AS net_revenue,
    ROUND(
        SUM(sub_total - discount_amt) /
        COUNT(DISTINCT receipt_date), 2
    ) AS revenue_per_sales_day
FROM `01_receipts`
WHERE YEAR(receipt_date) < 2013
GROUP BY MONTH(receipt_date)
ORDER BY month;

-- KEY FINDINGS
-- June: highest revenue per sales day, 21,309.82.
-- January: lowest, 16,531.57.
-- Difference: approximately 28.9%.

-- LIMITATION
-- Changes in store coverage may affect monthly patterns.
-- These results do not isolate seasonality.


-- 02.3 Revenue by Day of Week

SELECT
    DAYNAME(receipt_date) AS weekday,
    COUNT(*) AS transactions,
    ROUND(SUM(sub_total - discount_amt), 2) AS net_revenue,
    ROUND(
        SUM(sub_total - discount_amt) /
        COUNT(DISTINCT receipt_date), 2
    ) AS revenue_per_sales_day
FROM `01_receipts`
WHERE YEAR(receipt_date) < 2013
GROUP BY
    DAYNAME(receipt_date),
    DAYOFWEEK(receipt_date)
ORDER BY DAYOFWEEK(receipt_date);

-- KEY FINDINGS
-- Friday: highest revenue per sales day, 22,888.91.
-- Sunday: lowest, 14,646.31.
-- Friday generates approximately 56.3% more than Sunday.

-- LIMITATION
-- Results are not adjusted for the number of stores
-- operating on each weekday.


-- ==========================================================
-- 03. STORE PERFORMANCE BENCHMARKING
-- ==========================================================

-- BUSINESS QUESTION
-- Which stores outperform or underperform the network?


-- 03.1 Historical Store Performance (2003-2012)

-- Revenue per sales day reduces differences caused
-- by unequal numbers of recorded selling days.

SELECT
    store_num,
    COUNT(*) AS transactions,
    COUNT(DISTINCT receipt_date) AS sales_days,
    ROUND(SUM(sub_total - discount_amt), 2) AS net_revenue,
    ROUND(AVG(sub_total - discount_amt), 2) AS avg_order_value,
    ROUND(
        SUM(sub_total - discount_amt) /
        COUNT(DISTINCT receipt_date), 2
    ) AS revenue_per_sales_day
FROM `01_receipts`
WHERE YEAR(receipt_date) < 2013
GROUP BY store_num
ORDER BY revenue_per_sales_day DESC;

-- KEY FINDINGS
-- Historical leaders: Stores 2, 8 and 3.
-- Historical laggards: Stores 24, 22 and 17.
-- Historical rankings are affected by different
-- store operating periods.


-- 03.2 Comparable Store Benchmarking (2012)

-- Use the latest complete year.
-- Revenue/Day = Transactions/Day x Average Order Value.

SELECT
    store_num,
    COUNT(*) AS transactions,
    COUNT(DISTINCT receipt_date) AS sales_days,
    ROUND(
        COUNT(*) / COUNT(DISTINCT receipt_date), 2
    ) AS transactions_per_sales_day,
    ROUND(SUM(sub_total - discount_amt), 2) AS net_revenue,
    ROUND(AVG(sub_total - discount_amt), 2) AS avg_order_value,
    ROUND(
        SUM(sub_total - discount_amt) /
        COUNT(DISTINCT receipt_date), 2
    ) AS revenue_per_sales_day
FROM `01_receipts`
WHERE YEAR(receipt_date) = 2012
GROUP BY store_num
ORDER BY revenue_per_sales_day DESC;

-- KEY FINDINGS
-- Top stores: 8, 1, 2.
-- Bottom stores: 22, 24, 17.
-- Store 8: 2,529.03 revenue per sales day.
-- Store 22: 769.10 revenue per sales day.
-- Performance gap: 3.29x.

-- PERFORMANCE DRIVERS
-- Store 8: 276.95 transactions/day; AOV 9.13.
-- Store 22: 107.90 transactions/day; AOV 7.13.
-- Store 8 generates 2.57x more transactions/day.
-- Its AOV is also 28.1% higher.
-- Transaction volume is the main contributor
-- to the revenue gap.

-- LIMITATIONS
-- Store 0 has only 166 sales days in 2012.
-- Other stores have approximately 363-365 sales days.
-- Sales days are dates with recorded transactions,
-- not confirmed operating days.


-- ==========================================================
-- 04. PRODUCT DATA QUALITY & COVERAGE
-- ==========================================================

-- BUSINESS QUESTION
-- Are product sales and costs reliable enough
-- for profitability analysis?


-- 04.1 Sales & Cost Validation

-- Checks are performed after cost imputation.
-- Estimated costs are identified by cost_imputed = 1.

SELECT
    COUNT(*) AS total_rows,

    SUM(CASE
        WHEN quantity IS NULL OR price IS NULL
            OR sales_total IS NULL OR food_cost IS NULL
            OR cost_total IS NULL
        THEN 1 ELSE 0
    END) AS missing_values,

    SUM(CASE
        WHEN ABS(sales_total - price * quantity) > 0.01
        THEN 1 ELSE 0
    END) AS sales_mismatches,

    SUM(CASE
        WHEN ABS(cost_total - food_cost * quantity) > 0.01
        THEN 1 ELSE 0
    END) AS cost_mismatches,

    SUM(CASE WHEN cost_imputed = 1
        THEN 1 ELSE 0 END) AS imputed_rows,

    ROUND(SUM(CASE WHEN cost_imputed = 1
        THEN cost_total ELSE 0 END), 2) AS estimated_cogs,

    SUM(CASE WHEN food_cost = 0 AND sales_total > 0
        THEN 1 ELSE 0 END) AS unresolved_positive_costs

FROM `03_items_receipt`;

-- DATA CLEANING SUMMARY
-- Initial records: 20,346,147.
-- Initial zero-cost rows: 54,118 (0.266%).
-- Affected sales: 92,123.46 (0.12%).
-- Only 11 product IDs were affected.
-- No suitable comparable products were available
-- for some missing costs.
-- Applied a revenue-weighted cost ratio: 35.198646%.
-- Updated 51,858 positive-sales records.
-- Remaining non-positive-sales records were not imputed.
-- Original affected values were backed up.
-- Imputed values were flagged for transparency.
-- Validated estimated COGS after update: 32,735.94.

-- LIMITATIONS
-- Imputed costs are estimates, not measured costs.
-- Initial estimate of 32,426.21 differs from the
-- post-update total and requires reconciliation.
-- Minor line-level differences can result from rounding.


-- 04.2 Menu Catalog Coverage

-- Check which sold products can be linked
-- to the product and category reference table.

SELECT
    COUNT(DISTINCT i.inv_num) AS sold_products,

    COUNT(DISTINCT CASE
        WHEN m.inv_num IS NULL THEN i.inv_num
    END) AS missing_products,

    ROUND(SUM(CASE
        WHEN m.inv_num IS NULL THEN i.sales_total
        ELSE 0
    END), 2) AS unmatched_sales,

    ROUND(
        100 * SUM(CASE
            WHEN m.inv_num IS NULL THEN i.sales_total
            ELSE 0
        END) / SUM(i.sales_total), 2
    ) AS unmatched_sales_pct

FROM `03_items_receipt` AS i
LEFT JOIN `04_items_menu` AS m
    ON i.inv_num = m.inv_num;

-- KEY FINDINGS
-- Total products sold: 672.
-- Products missing from menu catalog: 334.
-- Unmatched sales: 58.35M (75.03%).

-- DECISION
-- Preserve all products and their financial data.
-- Use inv_num as the primary product identifier.
-- Assign 'Unknown' to unavailable names/categories.
-- Do not infer categories without reliable evidence.


-- ==========================================================
-- 05. MENU PROFITABILITY
-- ==========================================================

-- BUSINESS QUESTION
-- Which products generate the most gross profit?
-- Where are the largest margin improvement opportunities?


-- 05.1 Overall Product Gross Margin

-- Gross Margin = (Sales - COGS) / Sales.

SELECT
    ROUND(SUM(sales_total), 2) AS total_sales,
    ROUND(SUM(cost_total), 2) AS total_cogs,
    ROUND(SUM(sales_total - cost_total), 2) AS gross_profit,
    ROUND(
        100 * SUM(sales_total - cost_total) /
        SUM(sales_total), 2
    ) AS gross_margin_pct
FROM `03_items_receipt`;

-- KEY FINDINGS
-- Product Sales: 77.77M.
-- COGS: 27.93M.
-- Gross Profit: 49.83M.
-- Gross Margin: 64.08%.

-- LIMITATION
-- These are item-level figures, not fully reconciled
-- financial statements for the entire network.


-- 05.2 Category Performance

-- Include Unknown to avoid excluding valid sales.

SELECT
    COALESCE(m.cat_description, 'Unknown') AS category,
    COUNT(DISTINCT i.inv_num) AS products,
    ROUND(SUM(i.sales_total), 2) AS sales,
    ROUND(SUM(i.cost_total), 2) AS cogs,
    ROUND(
        SUM(i.sales_total - i.cost_total), 2
    ) AS gross_profit,
    ROUND(
        100 * SUM(i.sales_total - i.cost_total) /
        SUM(i.sales_total), 2
    ) AS gross_margin_pct
FROM `03_items_receipt` AS i
LEFT JOIN `04_items_menu` AS m
    ON i.inv_num = m.inv_num
GROUP BY category
ORDER BY gross_profit DESC;

-- KEY FINDINGS
-- Unknown represents 75.03% of item-level sales.
-- Known categories include Beverages, Miscellaneous,
-- Sandwiches and Breakfast.

-- LIMITATION
-- Category rankings do not represent the complete
-- product mix because of missing category information.


-- 05.3 Top 20 Products by Gross Profit

-- Product IDs remain usable even when names are missing.

SELECT
    i.inv_num,
    COALESCE(m.item_description, 'Unknown') AS product,
    SUM(i.quantity) AS units_sold,
    ROUND(SUM(i.sales_total), 2) AS sales,
    ROUND(SUM(i.cost_total), 2) AS cogs,
    ROUND(
        SUM(i.sales_total - i.cost_total), 2
    ) AS gross_profit,
    ROUND(
        100 * SUM(i.sales_total - i.cost_total) /
        SUM(i.sales_total), 2
    ) AS gross_margin_pct
FROM `03_items_receipt` AS i
LEFT JOIN `04_items_menu` AS m
    ON i.inv_num = m.inv_num
GROUP BY i.inv_num, m.item_description
ORDER BY gross_profit DESC
LIMIT 20;

-- KEY FINDINGS
-- Product 1651: highest historical Gross Profit, 3.41M.
-- 21OZ DRINK: 2.66M.
-- CHIPS: 2.34M.
-- High total profit does not imply a high profit margin.


-- 05.4 Product Margin Opportunities

-- Compare financially significant products
-- against the historical network margin of 64.08%.

-- Potential Gap = Sales x Target Margin - Current Profit.
-- This is a benchmark gap, not guaranteed profit.

SELECT
    i.inv_num,
    COALESCE(m.item_description, 'Unknown') AS product,
    ROUND(SUM(i.sales_total), 2) AS sales,
    ROUND(
        100 * SUM(i.sales_total - i.cost_total) /
        SUM(i.sales_total), 2
    ) AS gross_margin_pct,
    ROUND(
        SUM(i.sales_total) * 0.6408 -
        SUM(i.sales_total - i.cost_total), 2
    ) AS potential_profit_gap
FROM `03_items_receipt` AS i
LEFT JOIN `04_items_menu` AS m
    ON i.inv_num = m.inv_num
GROUP BY i.inv_num, m.item_description
HAVING SUM(i.sales_total) > 100000
    AND SUM(i.sales_total - i.cost_total) /
        SUM(i.sales_total) < 0.6408
ORDER BY potential_profit_gap DESC
LIMIT 15;

-- KEY FINDINGS
-- Product 1521: margin 47.18%.
-- Largest historical margin gap: 323,289.95.
-- Other high-priority products: 1641, 35050, 5014.

-- LIMITATIONS
-- Different products may have different target margins.
-- The 64.08% target is a scenario assumption.
-- Historical gaps cover the full dataset period.


-- ==========================================================
-- 06. FINANCIAL SCENARIO ANALYSIS (2012)
-- ==========================================================

-- BUSINESS QUESTION
-- What financial improvements could selected
-- operational and pricing changes generate?

-- SCENARIOS
-- A. Store 22: +10% transaction volume.
-- B. Store 24: +5% average order value.
-- C. Top 10 products: margin improvement to 64.08%.

-- All scenarios use 2012 as the comparison period.
-- Revenue uplift and gross profit uplift are
-- different metrics and must not be added directly.


-- 06.1 Store 22 - Transaction Growth

-- ASSUMPTIONS
-- +10% transactions.
-- Average order value remains unchanged.

SELECT
    store_num,
    ROUND(
        SUM(sub_total - discount_amt), 2
    ) AS current_revenue,
    ROUND(
        SUM(sub_total - discount_amt) * 0.10, 2
    ) AS revenue_uplift,
    ROUND(
        SUM(sub_total - discount_amt) * 1.10, 2
    ) AS projected_revenue
FROM `01_receipts`
WHERE store_num = 22
    AND YEAR(receipt_date) = 2012
GROUP BY store_num;

-- KEY RESULT
-- Current Revenue: 280,720.99.
-- Potential Revenue Uplift: +28,072.10.
-- Projected Revenue: 308,793.09.


-- 06.2 Store 24 - Average Order Value Growth

-- ASSUMPTIONS
-- +5% average order value.
-- Transaction volume remains unchanged.

SELECT
    store_num,
    ROUND(
        AVG(sub_total - discount_amt), 2
    ) AS current_aov,
    ROUND(
        AVG(sub_total - discount_amt) * 1.05, 2
    ) AS projected_aov,
    ROUND(
        SUM(sub_total - discount_amt) * 0.05, 2
    ) AS revenue_uplift
FROM `01_receipts`
WHERE store_num = 24
    AND YEAR(receipt_date) = 2012
GROUP BY store_num;

-- KEY RESULT
-- Current AOV: 6.51.
-- Projected AOV: 6.84.
-- Potential Revenue Uplift: +14,882.76.


-- 06.3 Top 10 Product Margin Optimization

-- SELECTION
-- 2012 product sales > 100,000.
-- Product Gross Margin < 64.08%.
-- Top 10 by potential gross profit improvement.

-- ASSUMPTIONS
-- Target Gross Margin: 64.08%.
-- Sales remain unchanged.
-- Improvements come from reducing COGS.

SELECT
    i.inv_num,
    ROUND(SUM(i.sales_total), 2) AS sales,
    ROUND(
        100 * SUM(i.sales_total - i.cost_total) /
        SUM(i.sales_total), 2
    ) AS gross_margin_pct,
    ROUND(
        SUM(i.sales_total) * 0.6408 -
        SUM(i.sales_total - i.cost_total), 2
    ) AS potential_profit_uplift
FROM `03_items_receipt` AS i
JOIN `01_receipts` AS r
    ON i.receipt_id = r.receipt_id
WHERE YEAR(r.receipt_date) = 2012
GROUP BY i.inv_num
HAVING SUM(i.sales_total) > 100000
    AND SUM(i.sales_total - i.cost_total) /
        SUM(i.sales_total) < 0.6408
ORDER BY potential_profit_uplift DESC
LIMIT 10;

-- KEY RESULT
-- Combined potential Gross Profit Uplift: 245,407.24.
-- Highest individual opportunity: Product 14747.
-- Product 1521 is the second-largest opportunity.

-- LIMITATIONS
-- Achieving the target margin is not guaranteed.
-- Product cost reduction feasibility requires review.
-- Imputed COGS introduces estimation uncertainty.


-- ==========================================================
-- 07. FINAL VALIDATION & RECONCILIATION
-- ==========================================================

-- BUSINESS QUESTION
-- Are store-level revenue and item-level sales consistent?


-- 07.1 Revenue Reconciliation (2012)

-- Receipt-based revenue is the primary source
-- for store performance metrics.

SELECT
    ROUND(
        SUM(sub_total - discount_amt), 2
    ) AS receipt_revenue
FROM `01_receipts`
WHERE YEAR(receipt_date) = 2012;

-- Product sales are linked to the same receipt period.

SELECT
    ROUND(SUM(i.sales_total), 2) AS item_sales
FROM `03_items_receipt` AS i
JOIN `01_receipts` AS r
    ON i.receipt_id = r.receipt_id
WHERE YEAR(r.receipt_date) = 2012;

-- KEY FINDINGS
-- Receipt Revenue: 12,442,959.40.
-- Matched Item Sales: 12,381,651.50.
-- Difference: 61,307.90 (0.49%).

-- DECISION
-- Use 01_receipts for store revenue KPIs.
-- Use 03_items_receipt for product profitability.
-- Do not treat the two totals as interchangeable.


-- 07.2 Receipts Without Item Records (2012)

SELECT
    COUNT(*) AS receipts_without_items,

    SUM(CASE
        WHEN r.sub_total - r.discount_amt > 0
        THEN 1 ELSE 0
    END) AS positive_revenue_receipts,

    SUM(CASE
        WHEN r.sub_total - r.discount_amt = 0
        THEN 1 ELSE 0
    END) AS zero_revenue_receipts,

    SUM(CASE
        WHEN r.sub_total - r.discount_amt < 0
        THEN 1 ELSE 0
    END) AS negative_revenue_receipts,

    ROUND(
        SUM(r.sub_total - r.discount_amt), 2
    ) AS unmatched_receipt_revenue

FROM `01_receipts` AS r
LEFT JOIN `03_items_receipt` AS i
    ON r.receipt_id = i.receipt_id
WHERE YEAR(r.receipt_date) = 2012
    AND i.receipt_id IS NULL;

-- KEY FINDINGS
-- Receipts without items: 84,955.
-- Positive revenue: 57,107 receipts.
-- Zero revenue: 27,548 receipts.
-- Negative revenue: 300 receipts.
-- Revenue without linked items: 285,879.28.

-- This does not fully explain the 0.49% discrepancy.
-- Differences within matched receipts also contribute.


-- ==========================================================
-- 08. FINAL BUSINESS FINDINGS
-- ==========================================================

-- STORE PERFORMANCE
-- - Store 8 leads the 2012 daily revenue ranking.
-- - Store 22 has the lowest daily revenue.
-- - Transaction volume is the main performance driver.
-- - Store 24 has a particularly low AOV.

-- MENU PROFITABILITY
-- - Historical item-level Gross Margin: 64.08%.
-- - Product 1521 has a large margin improvement gap.
-- - Missing product categories limit category analysis.
-- - Product-level analysis remains possible using inv_num.

-- FINANCIAL OPPORTUNITIES (2012)
-- - Store 22, +10% transactions: +28,072.10 revenue.
-- - Store 24, +5% AOV: +14,882.76 revenue.
-- - Top 10 products, 64.08% margin: +245,407.24
--   potential gross profit.

-- DATA LIMITATIONS
-- - Historical data: 2003-2013.
-- - 2013 is incomplete.
-- - Store operating periods differ.
-- - 75.03% of item sales lack a catalog category.
-- - Some product costs were estimated.
-- - Receipt/item revenue difference: 0.49% in 2012.
-- - Currency unit must be verified before publication.
-- - Financial scenarios are hypothetical, not forecasts.

-- TABLEAU HANDOFF
-- - Store Scorecard: Section 03.2.
-- - Category Performance: Section 05.2.
-- - Product Performance: Sections 05.3-05.4.
-- - Financial Opportunities: Section 06.
-- - Data Quality Notes: Sections 04 and 07.
