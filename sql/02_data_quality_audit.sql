-- ============================================================
-- SANDWICH ANALYTICS
-- 02 | DATA QUALITY AUDIT
-- ============================================================

USE sandwich_analytics;

-- Audit only: no changes to source data.
-- Large-table samples use the first 10,000 returned rows.
-- These are not random or representative samples.


-- ============================================================
-- 01 | KEY COMPLETENESS & UNIQUENESS
-- ============================================================

-- Receipts: check missing IDs across the full table
SELECT
    COUNT(*) AS missing_ids
FROM `01_receipts`
WHERE Receipt_ID IS NULL OR TRIM(Receipt_ID) = '';

-- Menu items
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT Inv_Num) AS unique_items,
    SUM(Inv_Num IS NULL OR TRIM(Inv_Num) = '') AS missing_ids
FROM `04_items_menu`;

-- Store attributes
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT Store_Num) AS unique_stores,
    SUM(Store_Num IS NULL OR TRIM(Store_Num) = '') AS missing_ids
FROM `08_attributes`;

-- Ingredient mappings: composite key
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT Inv_Num, Ingredient_ID) AS unique_pairs,
    SUM(
        Inv_Num IS NULL OR TRIM(Inv_Num) = ''
        OR Ingredient_ID IS NULL OR TRIM(Ingredient_ID) = ''
    ) AS missing_keys
FROM `05_ing_in_item`;

-- Ingredient inventory
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT Ingredient_ID) AS unique_ingredients,
    SUM(Ingredient_ID IS NULL OR TRIM(Ingredient_ID) = '') AS missing_ids
FROM `06_ing_inventory`;

-- Weather: station + date + hour
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT Weather_Station, Date, Hour) AS unique_observations,
    SUM(
        Weather_Station IS NULL OR TRIM(Weather_Station) = ''
        OR Date IS NULL OR TRIM(Date) = ''
        OR Hour IS NULL OR TRIM(Hour) = ''
    ) AS missing_keys
FROM `07_weather`;

-- City crime
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT City) AS unique_cities,
    SUM(City IS NULL OR TRIM(City) = '') AS missing_cities
FROM `09_city_crime`;

-- County demographics
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT County) AS unique_counties,
    SUM(County IS NULL OR TRIM(County) = '') AS missing_counties
FROM `10_demo`;

-- Verify restored unemployment values
SELECT
    County,
    `Unemployment Rate`
FROM `10_demo`;


-- ============================================================
-- 02 | REFERENCE DATA COMPLETENESS
-- ============================================================

-- Check menu descriptions and categories
SELECT
    SUM(Item_Description IS NULL OR TRIM(Item_Description) = '') AS missing_items,
    SUM(Cat_ID IS NULL OR TRIM(Cat_ID) = '') AS missing_categories,
    SUM(Cat_Description IS NULL OR TRIM(Cat_Description) = '') AS missing_cat_names,
    SUM(Sub_Cat_ID IS NULL OR TRIM(Sub_Cat_ID) = '') AS missing_subcategories,
    SUM(Sub_Cat_Description IS NULL OR TRIM(Sub_Cat_Description) = '') AS missing_subcat_names
FROM `04_items_menu`;

-- Check essential store attributes
SELECT
    SUM(City IS NULL OR TRIM(City) = '') AS missing_city,
    SUM(County IS NULL OR TRIM(County) = '') AS missing_county,
    SUM(Weather_Station IS NULL OR TRIM(Weather_Station) = '') AS missing_station,
    SUM(`Store type` IS NULL OR TRIM(`Store type`) = '') AS missing_store_type
FROM `08_attributes`;


-- ============================================================
-- 03 | REFERENCE TABLE RELATIONSHIPS
-- ============================================================

-- Stores without matching city or county records
SELECT
    a.Store_Num,
    a.City,
    a.County
FROM `08_attributes` a
LEFT JOIN `09_city_crime` c
    ON a.City = c.City
LEFT JOIN `10_demo` d
    ON a.County = d.County
WHERE c.City IS NULL OR d.County IS NULL;

-- Weather stations without exact matches
SELECT DISTINCT
    a.Weather_Station
FROM `08_attributes` a
LEFT JOIN (
    SELECT DISTINCT Weather_Station
    FROM `07_weather`
) w
    ON a.Weather_Station = w.Weather_Station
WHERE w.Weather_Station IS NULL;

-- Recheck weather relationships after removing whitespace
SELECT DISTINCT
    a.Weather_Station
FROM `08_attributes` a
LEFT JOIN (
    SELECT DISTINCT TRIM(Weather_Station) AS Weather_Station
    FROM `07_weather`
) w
    ON a.Weather_Station = w.Weather_Station
WHERE w.Weather_Station IS NULL;


-- ============================================================
-- 04 | INGREDIENT MAPPING & COVERAGE
-- ============================================================

-- Identify unmatched menu items and ingredients
SELECT
    COUNT(*) AS total_mappings,
    SUM(i.Inv_Num IS NULL) AS unmatched_menu_rows,
    COUNT(DISTINCT CASE
        WHEN i.Inv_Num IS NULL THEN m.Inv_Num
    END) AS unmatched_products,
    SUM(g.Ingredient_ID IS NULL) AS unmatched_ingredients
FROM `05_ing_in_item` m
LEFT JOIN `04_items_menu` i
    ON TRIM(m.Inv_Num) = TRIM(i.Inv_Num)
LEFT JOIN `06_ing_inventory` g
    ON TRIM(m.Ingredient_ID) = TRIM(g.Ingredient_ID);

-- Inspect ingredients of products missing from the menu
SELECT
    m.Inv_Num,
    g.Description AS ingredient,
    m.Quantity,
    m.Unit
FROM `05_ing_in_item` m
LEFT JOIN `04_items_menu` i
    ON TRIM(m.Inv_Num) = TRIM(i.Inv_Num)
LEFT JOIN `06_ing_inventory` g
    ON m.Ingredient_ID = g.Ingredient_ID
WHERE i.Inv_Num IS NULL
ORDER BY m.Inv_Num;

-- Check ingredient coverage across the menu
SELECT
    COUNT(DISTINCT i.Inv_Num) AS total_menu_items,
    COUNT(DISTINCT m.Inv_Num) AS items_with_ingredients
FROM `04_items_menu` i
LEFT JOIN `05_ing_in_item` m
    ON i.Inv_Num = m.Inv_Num;

-- Check historical sales for the 10 identified missing products
-- Full-table scan: potentially expensive without indexes
SELECT
    Inv_Num,
    COUNT(*) AS sales_records
FROM `03_items_receipt`
WHERE Inv_Num IN (
    '35081', '35082', '35083', '35084',
    '35085', '35086', '35087',
    '1221', '1285', '3602'
)
GROUP BY Inv_Num
ORDER BY sales_records DESC;


-- ============================================================
-- 05 | TRANSACTION & PAYMENT KEYS
-- ============================================================

-- Check payment identifiers and uniqueness (sample)
SELECT
    COUNT(*) AS payment_rows,
    COUNT(DISTINCT Receipt_ID) AS unique_receipts,
    COUNT(DISTINCT Payment_ID) AS unique_payment_ids,
    COUNT(DISTINCT Receipt_ID, Payment_ID) AS unique_payment_pairs,
    COUNT(DISTINCT Unnamed1) AS unique_row_ids,
    SUM(Receipt_ID IS NULL OR TRIM(Receipt_ID) = '') AS missing_receipts,
    SUM(Payment_ID IS NULL OR TRIM(Payment_ID) = '') AS missing_payments
FROM (
    SELECT Unnamed1, Receipt_ID, Payment_ID
    FROM `02_payment`
    LIMIT 10000
) AS sample;

-- Investigate repeated payment keys (sample)
SELECT
    Receipt_ID,
    Payment_ID,
    COUNT(*) AS payment_rows
FROM (
    SELECT Receipt_ID, Payment_ID
    FROM `02_payment`
    LIMIT 10000
) AS sample
GROUP BY Receipt_ID, Payment_ID
HAVING COUNT(*) > 1
ORDER BY payment_rows DESC
LIMIT 10;

-- Check receipt item identifiers (sample)
SELECT
    COUNT(*) AS checked_rows,
    SUM(Receipt_ID IS NULL OR TRIM(Receipt_ID) = '') AS missing_receipts,
    SUM(Inv_Num IS NULL OR TRIM(Inv_Num) = '') AS missing_items
FROM (
    SELECT Receipt_ID, Inv_Num
    FROM `03_items_receipt`
    LIMIT 10000
) AS sample;


-- ============================================================
-- 06 | PAYMENT DATA QUALITY
-- ============================================================

-- Payment method distribution (sample)
SELECT
    Pay_Type,
    COUNT(*) AS payment_count
FROM (
    SELECT Pay_Type
    FROM `02_payment`
    LIMIT 10000
) AS sample
GROUP BY Pay_Type
ORDER BY payment_count DESC;

-- Check missing and negative payment values (sample)
SELECT
    COUNT(*) AS checked_rows,
    SUM(Pay_Type IS NULL OR TRIM(Pay_Type) = '') AS missing_payment_type,
    SUM(Tender_Amt IS NULL OR TRIM(Tender_Amt) = '') AS missing_tender,
    SUM(Tip IS NULL OR TRIM(Tip) = '') AS missing_tip,
    SUM(`Change` IS NULL OR TRIM(`Change`) = '') AS missing_change,
    SUM(Tender_Amt < 0) AS negative_tender,
    SUM(Tip < 0) AS negative_tip,
    SUM(`Change` < 0) AS negative_change
FROM (
    SELECT Pay_Type, Tender_Amt, Tip, `Change`
    FROM `02_payment`
    LIMIT 10000
) AS sample;


-- ============================================================
-- 07 | RECEIPT RETURNS & DISCOUNTS
-- ============================================================

-- Check return patterns (sample)
SELECT
    `Return`,
    COUNT(*) AS total_receipts,
    SUM(Total < 0) AS negative_totals
FROM (
    SELECT `Return`, Total
    FROM `01_receipts`
    LIMIT 10000
) AS sample
GROUP BY `Return`;

-- Analyze discount types (sample)
SELECT
    Discount_Type,
    COUNT(*) AS receipts,
    SUM(CAST(Discount_Amt AS DECIMAL(12,2))) AS total_discount
FROM (
    SELECT Discount_Type, Discount_Amt
    FROM `01_receipts`
    LIMIT 10000
) AS sample
GROUP BY Discount_Type
ORDER BY receipts DESC;

-- Validate receipt totals after discounts (sample)
SELECT
    Receipt_ID,
    Sub_Total,
    Tax,
    Discount_Amt,
    Total,
    ROUND(Sub_Total + Tax - Discount_Amt, 2) AS calculated_total
FROM (
    SELECT Receipt_ID, Sub_Total, Tax, Discount_Amt, Total
    FROM `01_receipts`
    LIMIT 10000
) AS sample
WHERE Discount_Amt > 0
LIMIT 10;


-- ============================================================
-- 08 | SALES & COST DATA QUALITY
-- ============================================================

-- Validate financial calculations (sample)
SELECT
    COUNT(*) AS checked_rows,
    SUM(
        ROUND(Price * `Count`, 2) != ROUND(Sales_Total, 2)
    ) AS sales_errors,
    SUM(
        ROUND(Food_Cost * `Count`, 4) != ROUND(Cost_Total, 4)
    ) AS cost_errors
FROM (
    SELECT Price, Food_Cost, `Count`, Sales_Total, Cost_Total
    FROM `03_items_receipt`
    LIMIT 10000
) AS sample;

-- Check missing financial values (sample)
SELECT
    COUNT(*) AS checked_rows,
    SUM(Price IS NULL OR TRIM(Price) = '') AS missing_price,
    SUM(Food_Cost IS NULL OR TRIM(Food_Cost) = '') AS missing_cost,
    SUM(`Count` IS NULL OR TRIM(`Count`) = '') AS missing_quantity,
    SUM(Sales_Total IS NULL OR TRIM(Sales_Total) = '') AS missing_sales,
    SUM(Cost_Total IS NULL OR TRIM(Cost_Total) = '') AS missing_cost_total
FROM (
    SELECT Price, Food_Cost, `Count`, Sales_Total, Cost_Total
    FROM `03_items_receipt`
    LIMIT 10000
) AS sample;

-- Identify zero and negative financial values (sample)
SELECT
    COUNT(*) AS checked_rows,
    SUM(Price = 0) AS zero_price,
    SUM(Price < 0) AS negative_price,
    SUM(Food_Cost = 0) AS zero_cost,
    SUM(Food_Cost < 0) AS negative_cost,
    SUM(`Count` <= 0) AS non_positive_quantity
FROM (
    SELECT Price, Food_Cost, `Count`
    FROM `03_items_receipt`
    LIMIT 10000
) AS sample;


-- ============================================================
-- 09 | MENU CATALOG COVERAGE
-- ============================================================

-- Check product and sales coverage (sample)
SELECT
    COUNT(*) AS checked_rows,
    COUNT(DISTINCT s.Inv_Num) AS total_products,
    COUNT(DISTINCT i.Inv_Num) AS matched_products,
    COUNT(DISTINCT CASE
        WHEN i.Inv_Num IS NULL THEN s.Inv_Num
    END) AS unmatched_products,
    SUM(i.Inv_Num IS NULL) AS unmatched_sales_rows,
    ROUND(
        100 * SUM(i.Inv_Num IS NULL) / COUNT(*), 2
    ) AS unmatched_rows_pct
FROM (
    SELECT Inv_Num
    FROM `03_items_receipt`
    LIMIT 10000
) s
LEFT JOIN `04_items_menu` i
    ON TRIM(s.Inv_Num) = TRIM(i.Inv_Num);

-- Check financial coverage by the menu catalog (sample)
SELECT
    ROUND(SUM(s.Sales_Total), 2) AS total_line_sales,
    ROUND(SUM(CASE
        WHEN i.Inv_Num IS NULL THEN s.Sales_Total
        ELSE 0
    END), 2) AS unmatched_line_sales,
    ROUND(
        100 * SUM(CASE
            WHEN i.Inv_Num IS NULL THEN s.Sales_Total
            ELSE 0
        END) / NULLIF(SUM(s.Sales_Total), 0), 2
    ) AS unmatched_sales_pct
FROM (
    SELECT Inv_Num, Sales_Total
    FROM `03_items_receipt`
    LIMIT 10000
) s
LEFT JOIN `04_items_menu` i
    ON TRIM(s.Inv_Num) = TRIM(i.Inv_Num);

-- Identify highest-impact missing products (sample)
SELECT
    s.Inv_Num,
    COUNT(*) AS sales_records,
    ROUND(SUM(s.Sales_Total), 2) AS total_line_sales
FROM (
    SELECT Inv_Num, Sales_Total
    FROM `03_items_receipt`
    LIMIT 10000
) s
LEFT JOIN `04_items_menu` i
    ON TRIM(s.Inv_Num) = TRIM(i.Inv_Num)
WHERE i.Inv_Num IS NULL
GROUP BY s.Inv_Num
ORDER BY total_line_sales DESC
LIMIT 15;


-- ============================================================
-- 10 | DATA QUALITY AUDIT — FINAL SUMMARY
-- ============================================================

/*
DATA IMPORT & STRUCTURE
------------------------------------------------------------
- All 10 CSV files imported successfully.
- Row counts verified against source data.
- Raw columns are predominantly stored as TEXT.
- Data types, primary keys and indexes require modeling.


KEY COMPLETENESS & UNIQUENESS
------------------------------------------------------------
Full-table checks:

- Receipts: 9,499,778 rows; 0 missing Receipt_IDs.
- Menu Items: 560 unique IDs; 0 missing.
- Store Attributes: 25 unique IDs; 0 missing.
- Ingredient Inventory: 3,014 unique IDs; 0 missing.
- Ingredient Mapping: 77 unique item-ingredient pairs.
- Weather: 427,231 unique station-date-hour records.
- City Crime: 12 unique cities; 0 missing.
- County Demographics: 6 unique counties; 0 missing.

Large tables:

- Payments: 9,550,807 rows.
- Receipt Items: 20,346,152 rows.
- Sample key completeness checks passed.

Pending:
- Full Receipt_ID uniqueness validation.
- Full payment row identifier validation.
- Large-table referential integrity checks.


REFERENCE DATA & RELATIONSHIPS
------------------------------------------------------------
- Menu descriptions and categories: No missing values.
- Essential store attributes: No missing values.
- Store-to-City relationships: Valid.
- Store-to-County relationships: Valid.
- Store-to-Weather relationships: Valid after TRIM.
- Ingredient IDs in mapping table: All matched.

Issue:
- Leading whitespace identified in the weather station
  name "North Town Airport" in 07_weather.


INGREDIENT MAPPING & COVERAGE
------------------------------------------------------------
- Total menu products: 560.
- Products with ingredient mappings: 47.
- Ingredient coverage: 8.4%.

- Unmatched ingredient mapping rows: 17.
- Unique affected products: 10.
- Historical sales records for these products: 52,854.

Likely special POS items:
- 35081-35087: Chips + Drink combinations.
- 1221, 1285: Kids Pak Toy components.
- 3602: House Salad substitution.

These descriptions are inferred from ingredient data.

Conclusion:
- Ingredient mappings are insufficient for complete
  menu-level cost reconstruction.
- Transaction-level Food_Cost and Cost_Total are
  the preferred cost sources, subject to validation.


MENU CATALOG COVERAGE
------------------------------------------------------------
Based on a 10,000-row sales sample:

- Unique products: 278.
- Matched products: 141.
- Unmatched products: 137.
- Unmatched sales rows: 49.75%.
- Unmatched share of line sales: 74.08%.

Top 15 unmatched products represent:
- 68.38% of unmatched line sales.
- 50.66% of total sampled line sales.

Business impact:
- Product-level analysis remains possible by Inv_Num.
- Category-level analysis has substantial coverage risk.
- Unmatched products must not be excluded silently.
- Line sales are not final net revenue after discounts.

Note:
- These percentages are sample-specific.
- Full-dataset coverage remains unvalidated.


SALES & COST DATA QUALITY
------------------------------------------------------------
Based on 10,000 receipt-item records:

- Sales calculation errors: 0.
- Cost calculation errors: 0.
- Missing financial values: 0.
- Zero prices: 15.
- Negative prices: 81.
- Zero food costs: 31.
- Negative food costs: 1.
- Non-positive quantities: 0.

Observed calculations:
- Sales_Total = Price * Count.
- Cost_Total = Food_Cost * Count.

Conclusion:
- Financial data supports potential Gross Profit
  and Gross Margin calculations.
- Full-dataset validation is still required.


RETURNS & DISCOUNTS
------------------------------------------------------------
Based on 10,000 sampled receipts:

- Regular receipts: 9,931.
- Return receipts: 69.
- All sampled returns had negative totals.
- Regular receipts had no negative totals.

Discount validation:
- Total = Sub_Total + Tax - Discount_Amt.
- Confirmed for 10 discounted receipt examples.

Important:
- Receipt Total already includes discounts and tax.
- Do not subtract discounts twice.
- Return treatment requires further validation.
- Positive Food_Cost on negative sales was observed.
- Receipt and item-level financial data must be
  reconciled before final KPI calculations.


PAYMENT DATA QUALITY
------------------------------------------------------------
Based on 10,000 payment records:

- Missing financial values: 0.
- Missing payment types: 112.
- Negative Tender_Amt: 74.
- Negative Tip: 0.
- Negative Change: 0.

Payment structure:
- Unique Receipt_IDs: 9,938.
- Unique Payment_IDs: 113.
- Unique Receipt_ID + Payment_ID pairs: 9,938.
- Split payments confirmed.
- Unnamed1 unique in the 10,000-row sample.

Conclusion:
- Payment_ID is not a unique row identifier.
- Receipt_ID + Payment_ID is also not unique.
- Unnamed1 is a candidate technical primary key.
- Payment amounts must be aggregated by Receipt_ID
  before joining to receipt-level financial KPIs.
- Negative payments require return reconciliation.


IMPORT PRECISION ISSUE
------------------------------------------------------------
- Unemployment Rate was incorrectly imported as BIGINT.
- Original decimal values were converted to zero.
- Table 10_demo was recreated using TEXT columns.
- Original values successfully restored.

Status: FIXED.

The corrected import must be retained in
raw_data_import.sql.


============================================================
NEXT ACTIONS — DATA CLEANING & MODELING
============================================================

1. DATA TYPES
   - Convert raw TEXT columns to appropriate types.
   - Validate numeric formats before conversion.
   - Preserve financial precision.

2. DATA STANDARDIZATION
   - Normalize whitespace and relevant text values.
   - Correct weather station naming inconsistencies.
   - Keep an auditable cleaning process.

3. KEYS & INDEXES
   - Validate full-table key uniqueness.
   - Establish appropriate primary keys.
   - Create indexes for large-table joins.

4. REFERENTIAL INTEGRITY
   - Validate Receipts to Payments.
   - Validate Receipts to Receipt Items.
   - Validate Receipt Items to Menu.
   - Investigate orphan records and unmatched IDs.

5. FINANCIAL VALIDATION
   - Validate calculations across complete data.
   - Investigate zero and negative financial values.
   - Reconcile payments, returns and discounts.
   - Confirm COGS treatment for returned items.
   - Define Revenue, COGS, Gross Profit and Margin.

6. MENU DATA ENRICHMENT
   - Preserve all original sales records.
   - Assign UNKNOWN to unresolved categories.
   - Infer categories only with sufficient evidence.
   - Track inferred categories separately.
   - Reassess menu coverage across complete data.

7. ANALYTICAL DATA MODEL
   - Prepare tables for SQL and Tableau analysis.
   - Validate join cardinality to prevent duplication.
   - Create the final EER Diagram.


============================================================
FINAL CONCLUSION
============================================================

The dataset provides a strong foundation for
Store Performance Benchmarking and transaction-level
financial analysis.

Key limitations:

- Incomplete menu catalog.
- Limited ingredient mapping coverage.
- Financial anomalies and return accounting questions.
- Unvalidated keys and relationships in large tables.

The next priority is to build a clean, consistent
and validated analytical data model while preserving
the original transaction records.

IMPORTANT:
Sample-based results must not be generalized to
the full dataset without further validation.

============================================================
*/
