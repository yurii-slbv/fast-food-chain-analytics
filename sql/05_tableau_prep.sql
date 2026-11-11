-- ==========================================================
-- SANDWICH ANALYTICS 
-- 05 | TABLEAU DATA PREPARATION
-- ==========================================================
-- Run after data_cleaning_modeling.sql.
-- Output: tableau_store_performance
-- Granularity: Store x Date x Hour
-- ==========================================================

USE sandwich_analytics;


-- ==========================================================
-- 01 | STORE REVENUE & TRANSACTIONS
-- ==========================================================

DROP TABLE IF EXISTS tableau_receipts_hourly;

CREATE TABLE tableau_receipts_hourly AS
SELECT
    store_num,
    receipt_date,
    HOUR(start_time) AS sales_hour,
    COUNT(*) AS transactions,
    SUM(sub_total) AS sub_total,
    SUM(discount_amt) AS discount_amt,
    SUM(tax) AS tax,
    SUM(sub_total - discount_amt) AS net_revenue,
    SUM(total) AS total_sales
FROM `01_receipts`
GROUP BY
    store_num,
    receipt_date,
    HOUR(start_time);


-- ==========================================================
-- 02 | PRODUCT SALES & PROFITABILITY
-- ==========================================================

DROP TABLE IF EXISTS tableau_items_hourly;

CREATE TABLE tableau_items_hourly AS
SELECT
    r.store_num,
    r.receipt_date,
    HOUR(r.start_time) AS sales_hour,
    SUM(i.sales_total) AS item_sales,
    SUM(i.cost_total) AS cogs,
    SUM(i.sales_total - i.cost_total) AS gross_profit
FROM `03_items_receipt` i
JOIN `01_receipts` r
    ON i.receipt_id = r.receipt_id
GROUP BY
    r.store_num,
    r.receipt_date,
    HOUR(r.start_time);


-- ==========================================================
-- 03 | FINAL TABLEAU DATASET
-- ==========================================================
-- LEFT JOIN preserves revenue even when item data is missing.

DROP TABLE IF EXISTS tableau_store_performance;

CREATE TABLE tableau_store_performance AS
SELECT
    r.store_num,
    a.city,
    a.region,
    a.store_type,
    r.receipt_date,
    DAYNAME(r.receipt_date) AS weekday,
    r.sales_hour,
    r.transactions,
    r.sub_total,
    r.discount_amt,
    r.tax,
    r.net_revenue,
    r.total_sales,
    i.item_sales,
    i.cogs,
    i.gross_profit
FROM tableau_receipts_hourly r
LEFT JOIN tableau_items_hourly i
    ON r.store_num = i.store_num
    AND r.receipt_date = i.receipt_date
    AND r.sales_hour = i.sales_hour
LEFT JOIN `08_attributes` a
    ON r.store_num = a.store_num;


-- ==========================================================
-- 04 | DATA VALIDATION
-- ==========================================================

-- Check dataset size, coverage and missing item data.

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT store_num) AS stores,
    COUNT(DISTINCT city) AS cities,
    SUM(item_sales IS NULL) AS rows_without_item_sales
FROM tableau_store_performance;


-- Verify that financial totals were preserved.

SELECT
    (SELECT ROUND(SUM(net_revenue), 2)
     FROM tableau_receipts_hourly) AS source_revenue,

    ROUND(SUM(net_revenue), 2) AS tableau_revenue,

    (SELECT ROUND(SUM(item_sales), 2)
     FROM tableau_items_hourly) AS source_item_sales,

    ROUND(SUM(item_sales), 2) AS tableau_item_sales,

    (SELECT ROUND(SUM(cogs), 2)
     FROM tableau_items_hourly) AS source_cogs,

    ROUND(SUM(cogs), 2) AS tableau_cogs
FROM tableau_store_performance;


-- ==========================================================
-- 05 | CLEANUP
-- ==========================================================
-- Keep only the final Tableau dataset.

DROP TABLE IF EXISTS tableau_receipts_hourly;
DROP TABLE IF EXISTS tableau_items_hourly;
