-- =====================================================
-- SANDWICH ANALYTICS
-- 01 | RAW DATA IMPORT
-- =====================================================

-- Database setup
CREATE DATABASE IF NOT EXISTS sandwich_analytics;
USE sandwich_analytics;

-- Check whether local file loading is enabled
SHOW VARIABLES LIKE 'local_infile';


-- =====================================================
-- 01 | RECEIPTS
-- =====================================================

CREATE TABLE `01_receipts` (
    Receipt_ID TEXT,
    Store_Num TEXT,
    `Date` TEXT,
    Start_Time TEXT,
    End_Time TEXT,
    Check_Num TEXT,
    `Return` TEXT,
    Drive_Thru TEXT,
    Server_Name TEXT,
    Server_Title TEXT,
    Cashier_Name TEXT,
    Cashier_Title TEXT,
    Sub_Total TEXT,
    Tax TEXT,
    Discount_Type TEXT,
    Discount_Amt TEXT,
    Total TEXT
);

LOAD DATA LOCAL INFILE
'raw_data/E1_Receipts.csv'
INTO TABLE `01_receipts`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;


-- =====================================================
-- 02 | PAYMENTS
-- =====================================================

CREATE TABLE `02_payment` (
    Unnamed1 TEXT,
    Receipt_ID TEXT,
    Payment_ID TEXT,
    Pay_Type TEXT,
    Tender_Amt TEXT,
    Tip TEXT,
    `Change` TEXT
);

LOAD DATA LOCAL INFILE
'raw_data/E2_Payment.csv'
INTO TABLE `02_payment`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;


-- =====================================================
-- 03 | RECEIPT ITEMS
-- =====================================================

CREATE TABLE `03_items_receipt` (
    Receipt_ID TEXT,
    Inv_Num TEXT,
    Price TEXT,
    Food_Cost TEXT,
    `Count` TEXT,
    Sales_Total TEXT,
    Cost_Total TEXT
);

LOAD DATA LOCAL INFILE
'raw_data/E3_Item_on_Receipt.csv'
INTO TABLE `03_items_receipt`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;


-- =====================================================
-- 04–06 | MENU & INGREDIENT DATA
-- =====================================================

-- Import through MySQL Workbench Import Wizard:
-- 04_items_menu ("raw_data/E4_Menu_Items.csv")
-- 05_ing_in_item ("raw_data/E5_Ing_in_Item.csv")
-- 06_ing_inventory ("raw_data/E6_Ingredients.csv")


-- =====================================================
-- 07 | WEATHER
-- =====================================================

CREATE TABLE `07_weather` (
    Weather_Station TEXT,
    Date TEXT,
    Hour TEXT,
    Air_Temp TEXT,
    Dew_Point TEXT,
    Pressure TEXT,
    Wind_Dir TEXT,
    Wind_Spd TEXT,
    Sky_Cond TEXT,
    Precip_1hr TEXT,
    Precip_6hr TEXT
);

LOAD DATA LOCAL INFILE
'raw_data/E7_Weather.csv'
INTO TABLE `07_weather`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;


-- =====================================================
-- 08 | STORE ATTRIBUTES
-- =====================================================

-- Raw TEXT columns preserve original CSV values
CREATE TABLE `08_attributes` (
    Store_Num TEXT,
    City TEXT,
    State TEXT,
    County TEXT,
    Weather_Station TEXT,
    Region TEXT,
    `Store type` TEXT,
    DriveThrough TEXT,
    WalmartClients TEXT,
    LocalClients TEXT,
    BusinessClients TEXT,
    SchoolClients TEXT,
    TravelerClients TEXT,
    HispanicRace TEXT,
    NativeAmericanRace TEXT,
    `Near school` TEXT,
    Fastfood_1mi TEXT,
    Otherfood_1mi TEXT,
    Monthly_Rent_Est TEXT,
    Op_Hours_Month TEXT,
    `Labor Rate` TEXT
);

LOAD DATA LOCAL INFILE
'raw_data/E8_Attributes.csv'
INTO TABLE `08_attributes`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;


-- =====================================================
-- 09–10 | EXTERNAL DATA
-- =====================================================

-- Imported through MySQL Workbench Import Wizard:
-- 09_city_crime
-- 10_demo


-- =====================================================
-- IMPORT VALIDATION
-- =====================================================

-- Verify imported tables
SHOW TABLES;

-- Check row counts
SELECT COUNT(*) FROM `01_receipts`;
SELECT COUNT(*) FROM `02_payment`;
SELECT COUNT(*) FROM `03_items_receipt`;
SELECT COUNT(*) FROM `04_items_menu`;
SELECT COUNT(*) FROM `05_ing_in_item`;
SELECT COUNT(*) FROM `06_ing_inventory`;
SELECT COUNT(*) FROM `07_weather`;
SELECT COUNT(*) FROM `08_attributes`;
SELECT COUNT(*) FROM `09_city_crime`;
SELECT COUNT(*) FROM `10_demo`;
