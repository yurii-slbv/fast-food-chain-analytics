-- =============================================================
-- SANDWICH ANALYTICS 
-- 03 | DATA CLEANING & MODELING
-- =============================================================
-- Run ONLY after importing the original, unmodified CSV tables.
-- Do NOT rerun on an already cleaned database: ALTER/RENAME and
-- PRIMARY KEY statements are intended for a fresh import.
-- The corrected raw import of 10_demo must preserve original
-- decimal-rate values; this script cannot restore truncated data.
-- The EER model documents relationships separately; no FOREIGN
-- KEY constraints are added to the production data here.

USE sandwich_analytics;

-- =============================================================
-- 01 | NORMALIZE RAW TEXT VALUES
-- =============================================================
-- Convert blank text to NULL before changing column data types.
SET SQL_SAFE_UPDATES = 0;

UPDATE `08_attributes`
SET
    LocalClients = NULLIF(TRIM(LocalClients), ''),
    BusinessClients = NULLIF(TRIM(BusinessClients), ''),
    SchoolClients = NULLIF(TRIM(SchoolClients), ''),
    TravelerClients = NULLIF(TRIM(TravelerClients), ''),
    `Labor Rate` = NULLIF(TRIM(`Labor Rate`), '');

UPDATE `07_weather`
SET
    Weather_Station = TRIM(Weather_Station),
    Air_Temp = NULLIF(TRIM(Air_Temp), ''),
    Dew_Point = NULLIF(TRIM(Dew_Point), ''),
    Pressure = NULLIF(TRIM(Pressure), ''),
    Wind_Dir = NULLIF(TRIM(Wind_Dir), ''),
    Wind_Spd = NULLIF(TRIM(Wind_Spd), ''),
    Sky_Cond = NULLIF(TRIM(Sky_Cond), ''),
    Precip_1hr = NULLIF(TRIM(Precip_1hr), ''),
    Precip_6hr = NULLIF(TRIM(Precip_6hr), '');

SET SQL_SAFE_UPDATES = 1;

-- =============================================================
-- 02 | ASSIGN DATA TYPES
-- =============================================================

-- 04_items_menu
ALTER TABLE `04_items_menu`
    MODIFY COLUMN Inv_Num INT NOT NULL,
    MODIFY COLUMN Item_Description VARCHAR(50),
    MODIFY COLUMN Cat_ID INT,
    MODIFY COLUMN Cat_Description VARCHAR(50),
    MODIFY COLUMN Sub_Cat_ID INT,
    MODIFY COLUMN Sub_Cat_Description VARCHAR(50);

-- 06_ing_inventory
ALTER TABLE `06_ing_inventory`
    MODIFY COLUMN Ingredient_ID INT NOT NULL,
    MODIFY COLUMN Description VARCHAR(50);

-- 05_ing_in_item
ALTER TABLE `05_ing_in_item`
    MODIFY COLUMN Ingredient_ID INT NOT NULL,
    MODIFY COLUMN Inv_Num INT NOT NULL,
    MODIFY COLUMN Quantity INT,
    MODIFY COLUMN Unit VARCHAR(10),
    MODIFY COLUMN Unit_Amt INT;

-- 08_attributes
ALTER TABLE `08_attributes`
    MODIFY COLUMN Store_Num INT NOT NULL,
    MODIFY COLUMN City VARCHAR(100),
    MODIFY COLUMN State VARCHAR(100),
    MODIFY COLUMN County VARCHAR(100),
    MODIFY COLUMN Weather_Station VARCHAR(100),
    MODIFY COLUMN Region INT,
    MODIFY COLUMN `Store type` VARCHAR(50),
    MODIFY COLUMN DriveThrough VARCHAR(5),
    MODIFY COLUMN WalmartClients VARCHAR(5),
    MODIFY COLUMN LocalClients DECIMAL(6,4),
    MODIFY COLUMN BusinessClients DECIMAL(6,4),
    MODIFY COLUMN SchoolClients DECIMAL(6,4),
    MODIFY COLUMN TravelerClients DECIMAL(6,4),
    MODIFY COLUMN HispanicRace VARCHAR(5),
    MODIFY COLUMN NativeAmericanRace VARCHAR(5),
    MODIFY COLUMN `Near school` VARCHAR(50),
    MODIFY COLUMN Fastfood_1mi INT,
    MODIFY COLUMN Otherfood_1mi INT,
    MODIFY COLUMN Monthly_Rent_Est DECIMAL(12,2),
    MODIFY COLUMN Op_Hours_Month INT,
    MODIFY COLUMN `Labor Rate` DECIMAL(6,4);

-- 09_city_crime
ALTER TABLE `09_city_crime`
    MODIFY COLUMN City VARCHAR(50) NOT NULL,
    MODIFY COLUMN Violent_crime INT,
    MODIFY COLUMN Violent_rate DECIMAL(10,2),
    MODIFY COLUMN Property_crime INT,
    MODIFY COLUMN Property_Rate DECIMAL(10,2),
    MODIFY COLUMN Total_crime INT,
    MODIFY COLUMN Total_Rate_crime DECIMAL(10,2);

-- 10_demo
ALTER TABLE `10_demo`
    MODIFY COLUMN County VARCHAR(50) NOT NULL,
    MODIFY COLUMN Population INT,
    MODIFY COLUMN `Unemployment Rate` DECIMAL(6,4),
    MODIFY COLUMN `Poverty Rate` DECIMAL(6,4),
    MODIFY COLUMN White DECIMAL(6,4),
    MODIFY COLUMN `Black or African American` DECIMAL(6,4),
    MODIFY COLUMN `American Indian or Alaskan Native` DECIMAL(6,4),
    MODIFY COLUMN Asian DECIMAL(6,4),
    MODIFY COLUMN `Native Hawaiian` DECIMAL(6,4),
    MODIFY COLUMN `Two or More Races` DECIMAL(6,4);

-- 07_weather
ALTER TABLE `07_weather`
    MODIFY COLUMN Weather_Station VARCHAR(100) NOT NULL,
    MODIFY COLUMN `Date` DATE NOT NULL,
    MODIFY COLUMN Hour INT NOT NULL,
    MODIFY COLUMN Air_Temp DECIMAL(10,2),
    MODIFY COLUMN Dew_Point DECIMAL(10,2),
    MODIFY COLUMN Pressure DECIMAL(10,2),
    MODIFY COLUMN Wind_Dir INT,
    MODIFY COLUMN Wind_Spd DECIMAL(10,2),
    MODIFY COLUMN Sky_Cond INT,
    MODIFY COLUMN Precip_1hr DECIMAL(10,4),
    MODIFY COLUMN Precip_6hr DECIMAL(10,4);

-- 01_receipts
ALTER TABLE `01_receipts`
    MODIFY COLUMN Receipt_ID VARCHAR(100) NOT NULL,
    MODIFY COLUMN Store_Num INT,
    MODIFY COLUMN `Date` DATE,
    MODIFY COLUMN Start_Time TIME,
    MODIFY COLUMN End_Time TIME,
    MODIFY COLUMN Check_Num INT,
    MODIFY COLUMN `Return` VARCHAR(5),
    MODIFY COLUMN Drive_Thru VARCHAR(5),
    MODIFY COLUMN Server_Name VARCHAR(100),
    MODIFY COLUMN Server_Title VARCHAR(100),
    MODIFY COLUMN Cashier_Name VARCHAR(100),
    MODIFY COLUMN Cashier_Title VARCHAR(100),
    MODIFY COLUMN Sub_Total DECIMAL(14,2),
    MODIFY COLUMN Tax DECIMAL(14,2),
    MODIFY COLUMN Discount_Type VARCHAR(100),
    MODIFY COLUMN Discount_Amt DECIMAL(14,2),
    MODIFY COLUMN Total DECIMAL(14,2);

-- 02_payment
ALTER TABLE `02_payment`
    MODIFY COLUMN Unnamed1 BIGINT,
    MODIFY COLUMN Receipt_ID VARCHAR(100),
    MODIFY COLUMN Payment_ID INT,
    MODIFY COLUMN Pay_Type VARCHAR(50),
    MODIFY COLUMN Tender_Amt DECIMAL(14,2),
    MODIFY COLUMN Tip DECIMAL(14,2),
    MODIFY COLUMN `Change` DECIMAL(14,2);

-- 03_items_receipt
ALTER TABLE `03_items_receipt`
    MODIFY COLUMN Receipt_ID VARCHAR(100),
    MODIFY COLUMN Inv_Num INT,
    MODIFY COLUMN Price DECIMAL(14,2),
    MODIFY COLUMN Food_Cost DECIMAL(14,4),
    MODIFY COLUMN `Count` INT,
    MODIFY COLUMN Sales_Total DECIMAL(14,2),
    MODIFY COLUMN Cost_Total DECIMAL(14,4);

-- =============================================================
-- 03 | STANDARDIZE COLUMN NAMES (snake_case)
-- =============================================================

-- 04_items_menu
ALTER TABLE `04_items_menu`
    RENAME COLUMN Inv_Num TO inv_num,
    RENAME COLUMN Item_Description TO item_description,
    RENAME COLUMN Cat_ID TO cat_id,
    RENAME COLUMN Cat_Description TO cat_description,
    RENAME COLUMN Sub_Cat_ID TO sub_cat_id,
    RENAME COLUMN Sub_Cat_Description TO sub_cat_description;

-- 05_ing_in_item
ALTER TABLE `05_ing_in_item`
    RENAME COLUMN Ingredient_ID TO ingredient_id,
    RENAME COLUMN Inv_Num TO inv_num,
    RENAME COLUMN Quantity TO quantity,
    RENAME COLUMN Unit TO unit,
    RENAME COLUMN Unit_Amt TO unit_amt;

-- 06_ing_inventory
ALTER TABLE `06_ing_inventory`
    RENAME COLUMN Ingredient_ID TO ingredient_id,
    RENAME COLUMN Description TO description;

-- 07_weather
ALTER TABLE `07_weather`
    RENAME COLUMN Weather_Station TO weather_station,
    RENAME COLUMN `Date` TO observation_date,
    RENAME COLUMN Hour TO hour,
    RENAME COLUMN Air_Temp TO air_temp,
    RENAME COLUMN Dew_Point TO dew_point,
    RENAME COLUMN Pressure TO pressure,
    RENAME COLUMN Wind_Dir TO wind_dir,
    RENAME COLUMN Wind_Spd TO wind_spd,
    RENAME COLUMN Sky_Cond TO sky_cond,
    RENAME COLUMN Precip_1hr TO precip_1hr,
    RENAME COLUMN Precip_6hr TO precip_6hr;

-- 08_attributes
ALTER TABLE `08_attributes`
    RENAME COLUMN Store_Num TO store_num,
    RENAME COLUMN City TO city,
    RENAME COLUMN State TO state,
    RENAME COLUMN County TO county,
    RENAME COLUMN Weather_Station TO weather_station,
    RENAME COLUMN Region TO region,
    RENAME COLUMN `Store type` TO store_type,
    RENAME COLUMN DriveThrough TO drive_through,
    RENAME COLUMN WalmartClients TO walmart_clients,
    RENAME COLUMN LocalClients TO local_clients,
    RENAME COLUMN BusinessClients TO business_clients,
    RENAME COLUMN SchoolClients TO school_clients,
    RENAME COLUMN TravelerClients TO traveler_clients,
    RENAME COLUMN HispanicRace TO hispanic_race,
    RENAME COLUMN NativeAmericanRace TO native_american_race,
    RENAME COLUMN `Near school` TO near_school,
    RENAME COLUMN Fastfood_1mi TO fastfood_1mi,
    RENAME COLUMN Otherfood_1mi TO otherfood_1mi,
    RENAME COLUMN Monthly_Rent_Est TO monthly_rent_est,
    RENAME COLUMN Op_Hours_Month TO op_hours_month,
    RENAME COLUMN `Labor Rate` TO labor_rate;

-- 09_city_crime
ALTER TABLE `09_city_crime`
    RENAME COLUMN City TO city,
    RENAME COLUMN Violent_crime TO violent_crime,
    RENAME COLUMN Violent_rate TO violent_rate,
    RENAME COLUMN Property_crime TO property_crime,
    RENAME COLUMN Property_Rate TO property_rate,
    RENAME COLUMN Total_crime TO total_crime,
    RENAME COLUMN Total_Rate_crime TO total_crime_rate;

-- 10_demo
ALTER TABLE `10_demo`
    RENAME COLUMN County TO county,
    RENAME COLUMN Population TO population,
    RENAME COLUMN `Unemployment Rate` TO unemployment_rate,
    RENAME COLUMN `Poverty Rate` TO poverty_rate,
    RENAME COLUMN White TO white,
    RENAME COLUMN `Black or African American` TO black_or_african_american,
    RENAME COLUMN `American Indian or Alaskan Native` TO american_indian_or_alaskan_native,
    RENAME COLUMN Asian TO asian,
    RENAME COLUMN `Native Hawaiian` TO native_hawaiian,
    RENAME COLUMN `Two or More Races` TO two_or_more_races;

-- 01_receipts
ALTER TABLE `01_receipts`
    RENAME COLUMN Receipt_ID TO receipt_id,
    RENAME COLUMN Store_Num TO store_num,
    RENAME COLUMN `Date` TO receipt_date,
    RENAME COLUMN Start_Time TO start_time,
    RENAME COLUMN End_Time TO end_time,
    RENAME COLUMN Check_Num TO check_num,
    RENAME COLUMN `Return` TO is_return,
    RENAME COLUMN Drive_Thru TO drive_thru,
    RENAME COLUMN Server_Name TO server_name,
    RENAME COLUMN Server_Title TO server_title,
    RENAME COLUMN Cashier_Name TO cashier_name,
    RENAME COLUMN Cashier_Title TO cashier_title,
    RENAME COLUMN Sub_Total TO sub_total,
    RENAME COLUMN Tax TO tax,
    RENAME COLUMN Discount_Type TO discount_type,
    RENAME COLUMN Discount_Amt TO discount_amt,
    RENAME COLUMN Total TO total;

-- 02_payment
ALTER TABLE `02_payment`
    RENAME COLUMN Unnamed1 TO source_row_id,
    RENAME COLUMN Receipt_ID TO receipt_id,
    RENAME COLUMN Payment_ID TO payment_id,
    RENAME COLUMN Pay_Type TO pay_type,
    RENAME COLUMN Tender_Amt TO tender_amt,
    RENAME COLUMN Tip TO tip,
    RENAME COLUMN `Change` TO change_amount;

-- 03_items_receipt
ALTER TABLE `03_items_receipt`
    RENAME COLUMN Receipt_ID TO receipt_id,
    RENAME COLUMN Inv_Num TO inv_num,
    RENAME COLUMN Price TO price,
    RENAME COLUMN Food_Cost TO food_cost,
    RENAME COLUMN `Count` TO quantity,
    RENAME COLUMN Sales_Total TO sales_total,
    RENAME COLUMN Cost_Total TO cost_total;

-- =============================================================
-- 04 | PRIMARY KEYS AND JOIN INDEXES
-- =============================================================
-- The receipt-item key is (receipt_id, inv_num); payments use
-- source_row_id because receipt_id can have multiple payments.

ALTER TABLE `04_items_menu`
ADD PRIMARY KEY (inv_num);

ALTER TABLE `05_ing_in_item`
ADD PRIMARY KEY (inv_num, ingredient_id);

ALTER TABLE `06_ing_inventory`
ADD PRIMARY KEY (ingredient_id);

ALTER TABLE `08_attributes`
ADD PRIMARY KEY (store_num);

ALTER TABLE `09_city_crime`
ADD PRIMARY KEY (city);

ALTER TABLE `10_demo`
ADD PRIMARY KEY (county);

ALTER TABLE `07_weather`
ADD PRIMARY KEY (weather_station, observation_date, hour);

ALTER TABLE `01_receipts`
ADD PRIMARY KEY (receipt_id);

ALTER TABLE `02_payment`
    MODIFY COLUMN source_row_id BIGINT NOT NULL,
    ADD PRIMARY KEY (source_row_id);

ALTER TABLE `03_items_receipt`
ADD PRIMARY KEY (receipt_id, inv_num);

ALTER TABLE `01_receipts`
ADD INDEX idx_store_date (store_num, receipt_date);

ALTER TABLE `02_payment`
ADD INDEX idx_receipt_id (receipt_id);

ALTER TABLE `03_items_receipt`
ADD INDEX idx_inv_num (inv_num);

-- =============================================================
-- 05 | REPAIR INCOMPLETE RECEIPT IDS IN ITEM LINES
-- =============================================================
-- Affected receipt IDs end in '_' rather than '0' or '1'.
-- Match an existing purchase/return receipt. When both exist,
-- use negative item sales to identify returns; otherwise purchase.
-- Keep ambiguous zero-sales rows unchanged for manual handling.
-- Recovery is split into store groups, as in the validated cleanup.
-- IMPORTANT: use this only on the original imported rows.

SET SQL_SAFE_UPDATES = 0;

-- Store 20
UPDATE `03_items_receipt` i
JOIN `01_receipts` r
    ON r.receipt_id = CONCAT(
        i.receipt_id,
        CASE WHEN i.sales_total < 0 THEN '1' ELSE '0' END
    )
SET i.receipt_id = r.receipt_id
WHERE LEFT(i.receipt_id, 3) = '20_'
  AND RIGHT(i.receipt_id, 1) = '_';

-- Store 12
UPDATE `03_items_receipt` i
LEFT JOIN `01_receipts` r0
    ON CONCAT(i.receipt_id, '0') = r0.receipt_id
LEFT JOIN `01_receipts` r1
    ON CONCAT(i.receipt_id, '1') = r1.receipt_id
SET i.receipt_id = CASE
    WHEN r0.receipt_id IS NULL THEN r1.receipt_id
    WHEN r1.receipt_id IS NULL THEN r0.receipt_id
    WHEN i.sales_total < 0 THEN r1.receipt_id
    ELSE r0.receipt_id
END
WHERE LEFT(i.receipt_id, 3) IN ('12_')
  AND RIGHT(i.receipt_id, 1) = '_'
  AND (r0.receipt_id IS NOT NULL OR r1.receipt_id IS NOT NULL);

-- Stores 17, 22, 24
UPDATE `03_items_receipt` i
LEFT JOIN `01_receipts` r0
    ON CONCAT(i.receipt_id, '0') = r0.receipt_id
LEFT JOIN `01_receipts` r1
    ON CONCAT(i.receipt_id, '1') = r1.receipt_id
SET i.receipt_id = CASE
    WHEN r0.receipt_id IS NULL THEN r1.receipt_id
    WHEN r1.receipt_id IS NULL THEN r0.receipt_id
    WHEN i.sales_total < 0 THEN r1.receipt_id
    ELSE r0.receipt_id
END
WHERE LEFT(i.receipt_id, 3) IN ('17_', '22_', '24_')
  AND RIGHT(i.receipt_id, 1) = '_'
  AND (r0.receipt_id IS NOT NULL OR r1.receipt_id IS NOT NULL);

-- Stores 16, 18, 21, 23
UPDATE `03_items_receipt` i
LEFT JOIN `01_receipts` r0
    ON CONCAT(i.receipt_id, '0') = r0.receipt_id
LEFT JOIN `01_receipts` r1
    ON CONCAT(i.receipt_id, '1') = r1.receipt_id
SET i.receipt_id = CASE
    WHEN r0.receipt_id IS NULL THEN r1.receipt_id
    WHEN r1.receipt_id IS NULL THEN r0.receipt_id
    WHEN i.sales_total < 0 THEN r1.receipt_id
    ELSE r0.receipt_id
END
WHERE LEFT(i.receipt_id, 3) IN ('16_', '18_', '21_', '23_')
  AND RIGHT(i.receipt_id, 1) = '_'
  AND (r0.receipt_id IS NOT NULL OR r1.receipt_id IS NOT NULL);

-- Stores 13, 15, 19
UPDATE `03_items_receipt` i
LEFT JOIN `01_receipts` r0
    ON CONCAT(i.receipt_id, '0') = r0.receipt_id
LEFT JOIN `01_receipts` r1
    ON CONCAT(i.receipt_id, '1') = r1.receipt_id
SET i.receipt_id = CASE
    WHEN r0.receipt_id IS NULL THEN r1.receipt_id
    WHEN r1.receipt_id IS NULL THEN r0.receipt_id
    WHEN i.sales_total < 0 THEN r1.receipt_id
    ELSE r0.receipt_id
END
WHERE LEFT(i.receipt_id, 3) IN ('13_', '15_', '19_')
  AND RIGHT(i.receipt_id, 1) = '_'
  AND (r0.receipt_id IS NOT NULL OR r1.receipt_id IS NOT NULL);

-- Stores 10, 11, 14 (exclude ambiguous zero-sales lines)
UPDATE `03_items_receipt` i
LEFT JOIN `01_receipts` r0
    ON CONCAT(i.receipt_id, '0') = r0.receipt_id
LEFT JOIN `01_receipts` r1
    ON CONCAT(i.receipt_id, '1') = r1.receipt_id
SET i.receipt_id = CASE
    WHEN r0.receipt_id IS NULL THEN r1.receipt_id
    WHEN r1.receipt_id IS NULL THEN r0.receipt_id
    WHEN i.sales_total < 0 THEN r1.receipt_id
    ELSE r0.receipt_id
END
WHERE LEFT(i.receipt_id, 3) IN ('10_', '11_', '14_')
  AND RIGHT(i.receipt_id, 1) = '_'
  AND (r0.receipt_id IS NOT NULL OR r1.receipt_id IS NOT NULL)
  AND NOT (
      r0.receipt_id IS NOT NULL
      AND r1.receipt_id IS NOT NULL
      AND i.sales_total = 0
  );

SET SQL_SAFE_UPDATES = 1;

-- =============================================================
-- 06 | RESOLVE FIVE AMBIGUOUS ZERO-REVENUE ITEM LINES
-- =============================================================
-- The five lines cannot be assigned reliably to purchase/return.
-- They contain zero sales_total and 18.6033 combined cost_total.
-- The exact identifiers below were reviewed and explicitly excluded.
-- No receipts or payment records are deleted.

-- Confirm precisely five candidate rows before executing the DELETE.
SELECT receipt_id, inv_num, quantity, sales_total, cost_total
FROM `03_items_receipt`
WHERE (receipt_id = '10_11/10/2005_19:04_10130_' AND inv_num = 4901)
   OR (receipt_id = '11_06/19/2006_16:41_10135_' AND inv_num IN (11052, 11065, 11089))
   OR (receipt_id = '14_11/13/2006_11:12_10026_' AND inv_num = 4904);

SET SQL_SAFE_UPDATES = 0;

DELETE FROM `03_items_receipt`
WHERE ((receipt_id = '10_11/10/2005_19:04_10130_' AND inv_num = 4901)
    OR (receipt_id = '11_06/19/2006_16:41_10135_' AND inv_num IN (11052, 11065, 11089))
    OR (receipt_id = '14_11/13/2006_11:12_10026_' AND inv_num = 4904))
  AND sales_total = 0;

SET SQL_SAFE_UPDATES = 1;

-- ==========================================================
--  07 | COST IMPUTATION
-- ==========================================================
-- PROBLEM
-- 54,118 rows have zero food cost (0.266%).
-- Affected sales represent 0.12% of total item sales.
-- METHOD
-- Estimate missing costs using the revenue-weighted
-- COGS-to-sales ratio of products with known costs.
-- Preserve original values and flag estimated records.

-- 1. Back up affected records
CREATE TABLE zero_cost_backup AS
SELECT
    receipt_id,
    inv_num,
    food_cost,
    cost_total
FROM `03_items_receipt`
WHERE food_cost = 0
    AND sales_total > 0;

-- 2. Add imputation flag
ALTER TABLE `03_items_receipt`
ADD COLUMN cost_imputed TINYINT DEFAULT 0;

-- 3. Calculate cost ratio before updating
CREATE TEMPORARY TABLE cost_ratio AS
SELECT
    CAST(
        SUM(cost_total) / SUM(sales_total)
        AS DECIMAL(12, 8)
    ) AS ratio
FROM `03_items_receipt`
WHERE food_cost > 0
    AND sales_total > 0;

-- 4. Impute missing costs
SET SQL_SAFE_UPDATES = 0;

UPDATE `03_items_receipt` AS i
JOIN cost_ratio AS r
SET
    i.food_cost = ROUND(i.price * r.ratio, 4),
    i.cost_total = ROUND(i.sales_total * r.ratio, 2),
    i.cost_imputed = 1
WHERE i.food_cost = 0
    AND i.sales_total > 0;

SET SQL_SAFE_UPDATES = 1;

-- 5. Validate results
SELECT
    SUM(cost_imputed = 1) AS imputed_rows,
    ROUND(SUM(CASE WHEN cost_imputed = 1
        THEN cost_total ELSE 0 END), 2) AS estimated_cogs,
    SUM(CASE WHEN food_cost = 0 AND sales_total > 0
        THEN 1 ELSE 0 END) AS unresolved_costs
FROM `03_items_receipt`;

-- EXPECTED RESULTS
-- Imputed rows: 51,858.
-- Unresolved positive-sales zero-cost rows: 0.
-- Estimated COGS: approximately 32,735.94.
-- All imputed values are marked cost_imputed = 1.

-- =============================================================
-- 08 | POST-CLEANING VALIDATION
-- =============================================================
-- Expected: 20,346,147 item lines; zero incomplete receipt IDs.
SELECT
    COUNT(*) AS item_rows,
    SUM(RIGHT(receipt_id, 1) = '_') AS incomplete_receipt_ids
FROM `03_items_receipt`;

-- Sample post-repair receipt relationship check (not a full-table audit).
SELECT
    COUNT(*) AS checked_rows,
    SUM(r.receipt_id IS NULL) AS orphan_items
FROM (
    SELECT receipt_id
    FROM `03_items_receipt`
    ORDER BY receipt_id
    LIMIT 100000 OFFSET 10000000
) i
LEFT JOIN `01_receipts` r
    ON i.receipt_id = r.receipt_id;

-- All imported tables should have a primary key.
SELECT
    table_name,
    COUNT(*) AS primary_key_columns
FROM information_schema.key_column_usage
WHERE table_schema = 'sandwich_analytics'
  AND constraint_name = 'PRIMARY'
GROUP BY table_name
ORDER BY table_name;

-- Menu coverage: missing menu items are retained in receipt-item sales.
SELECT
    COUNT(*) AS sold_products,
    SUM(m.inv_num IS NOT NULL) AS catalog_products,
    SUM(m.inv_num IS NULL) AS uncataloged_products
FROM (
    SELECT DISTINCT inv_num
    FROM `03_items_receipt`
) s
LEFT JOIN `04_items_menu` m
    ON s.inv_num = m.inv_num;

-- =============================================================
-- 09 | FINANCIAL KPI RULES AND DATA LIMITATIONS
-- =============================================================
-- 01_receipts is the primary source for store-level sales.
-- Net revenue before tax = sub_total - discount_amt (provisional;
-- validate tax/return conventions before final KPI publication).
-- 03_items_receipt records item sales and available item costs.
-- Receipt-level discounts are not allocated to individual items.
-- Product catalog coverage is incomplete (334 of 672 sold IDs missing).
-- Item detail does not fully reconcile to receipt subtotals:
-- in the reviewed 1,000-receipt sample, 45 had no item records;
-- absolute matched-item subtotal discrepancies totaled 623.95;
-- absent-item receipt subtotals totaled 240.75 (absolute).
-- Item-level COGS may be incomplete and return treatment unverified.
-- Do not subtract item-level COGS from all receipt revenue to
-- publish a definitive gross profit or gross margin.
-- For missing menu classifications, use LEFT JOIN with COALESCE
-- in analytical queries, not invented product mappings.