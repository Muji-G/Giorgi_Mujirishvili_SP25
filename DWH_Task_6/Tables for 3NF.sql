-- Create 3NF schema
CREATE SCHEMA IF NOT EXISTS bl_3nf;

-- CE_ADDRESSES
CREATE TABLE IF NOT EXISTS bl_3nf.ce_addresses (
    address_id      BIGINT PRIMARY KEY,
    address_line    VARCHAR(100),
    city_name       VARCHAR(50),
    region_name     VARCHAR(50),
    postal_code     VARCHAR(20),
    country_name    VARCHAR(50),
    insert_dt       DATE,
    update_dt       DATE,
    source_system   VARCHAR(100),
    source_entity   VARCHAR(100)
);

-- CE_CUSTOMERS
CREATE TABLE IF NOT EXISTS bl_3nf.ce_customers (
    customer_id      BIGINT PRIMARY KEY,
    customer_src_id  INT NOT NULL,
    customer_name    VARCHAR(100),
    segment_name     VARCHAR(50),
    address_id       BIGINT,
    insert_dt        DATE,
    update_dt        DATE,
    source_system    VARCHAR(100),
    source_entity    VARCHAR(100)
);

-- CE_EMPLOYEES
CREATE TABLE IF NOT EXISTS bl_3nf.ce_employees (
    employee_id      BIGINT PRIMARY KEY,
    employee_src_id  INT NOT NULL,
    employee_name    VARCHAR(100),
    role_name        VARCHAR(50),
    hire_dt          DATE,
    address_id       BIGINT,
    insert_dt        DATE,
    update_dt        DATE,
    source_system    VARCHAR(100),
    source_entity    VARCHAR(100)
);

-- CE_BRANCHES
CREATE TABLE IF NOT EXISTS bl_3nf.ce_branches (
    branch_id        BIGINT PRIMARY KEY,
    branch_src_id    INT NOT NULL,
    branch_name      VARCHAR(100),
    address_id       BIGINT,
    insert_dt        DATE,
    update_dt        DATE,
    source_system    VARCHAR(100),
    source_entity    VARCHAR(100)
);

-- CE_CHANNELS
CREATE TABLE IF NOT EXISTS bl_3nf.ce_channels (
    channel_id       BIGINT PRIMARY KEY,
    channel_src_id   INT NOT NULL,
    channel_name     VARCHAR(255),
    insert_dt        DATE,
    update_dt        DATE,
    source_system    VARCHAR(100),
    source_entity    VARCHAR(100)
);

-- CE_TIME_DAY
CREATE TABLE IF NOT EXISTS bl_3nf.ce_time_day (
    date_id         BIGINT PRIMARY KEY,
    date_src_id     DATE NOT NULL,
    year_no         INT,
    month_no        INT,
    day_no          INT,
    weekday_name    VARCHAR(20),
    insert_dt       DATE,
    update_dt       DATE,
    source_system   VARCHAR(100),
    source_entity   VARCHAR(100)
);

-- CE_PRODUCT_CATEGORIES
CREATE TABLE IF NOT EXISTS bl_3nf.ce_product_categories (
    category_id       BIGINT PRIMARY KEY,
    category_src_id   VARCHAR(20) NOT NULL,
    category_name     VARCHAR(100),
    insert_dt         DATE,
    update_dt         DATE,
    source_system     VARCHAR(100),
    source_entity     VARCHAR(100)
);

-- CE_PRODUCT_SUBCATEGORIES
CREATE TABLE IF NOT EXISTS bl_3nf.ce_product_subcategories (
    subcategory_id        BIGINT PRIMARY KEY,
    subcategory_src_id    VARCHAR(20) NOT NULL,
    subcategory_name      VARCHAR(100),
    category_src_id       VARCHAR(20),
    insert_dt             DATE,
    update_dt             DATE,
    source_system         VARCHAR(100),
    source_entity         VARCHAR(100)
);

-- CE_PRODUCTS
CREATE TABLE IF NOT EXISTS bl_3nf.ce_products (
    product_id            BIGINT PRIMARY KEY,
    product_src_id        VARCHAR(30) NOT NULL,
    product_name          VARCHAR(100),
    subcategory_src_id    VARCHAR(20) NOT NULL,
    loss_rate_act         FLOAT,
    insert_dt             DATE,
    update_dt             DATE,
    source_system         VARCHAR(100),
    source_entity         VARCHAR(100)
);

-- CE_PRODUCT_PRICES_SCD (SCD TYPE 2)
CREATE TABLE IF NOT EXISTS bl_3nf.ce_product_prices_scd (
    price_id         BIGINT PRIMARY KEY,
    product_id       BIGINT NOT NULL,
    price_type_name  VARCHAR(50),
    price_amt_act    FLOAT,
    start_dt         DATE,
    end_dt           DATE,
    is_active        VARCHAR(1),
    insert_dt        DATE,
    update_dt        DATE,
    source_system    VARCHAR(100),
    source_entity    VARCHAR(100)
);

-- CE_SALES (FACT)
CREATE TABLE IF NOT EXISTS bl_3nf.ce_sales (
    date_id          BIGINT,
    customer_id      BIGINT,
    employee_id      BIGINT,
    branch_id        BIGINT,
    channel_id       BIGINT,
    product_id       BIGINT,
    price_id         BIGINT,
    quantity_no      INT,
    unit_price_act   FLOAT,
    discount_act     FLOAT,
    amount_tot_act   FLOAT,
    cost_act         FLOAT,
    gross_income_act FLOAT
);



-- Inserting default row into ce_addresses
INSERT INTO bl_3nf.ce_addresses
SELECT 0, 'Unknown', 'Unknown', 'Unknown', '00000', 'Unknown', CURRENT_DATE, CURRENT_DATE, 'DEFAULT', 'DEFAULT'
WHERE NOT EXISTS (SELECT 1 FROM bl_3nf.ce_addresses WHERE address_id = 0);
COMMIT;

-- Inserting default row into ce_customers
INSERT INTO bl_3nf.ce_customers
SELECT 0, 0, 'Unknown', 'Unknown', 0, CURRENT_DATE, CURRENT_DATE, 'DEFAULT', 'DEFAULT'
WHERE NOT EXISTS (SELECT 1 FROM bl_3nf.ce_customers WHERE customer_id = 0);
COMMIT;

-- Inserting default row into ce_employees
INSERT INTO bl_3nf.ce_employees
SELECT 0, 0, 'Unknown', 'Unknown', CURRENT_DATE, 0, CURRENT_DATE, CURRENT_DATE, 'DEFAULT', 'DEFAULT'
WHERE NOT EXISTS (SELECT 1 FROM bl_3nf.ce_employees WHERE employee_id = 0);
COMMIT;

-- Inserting default row into ce_branches
INSERT INTO bl_3nf.ce_branches
SELECT 0, 0, 'Unknown', 0, CURRENT_DATE, CURRENT_DATE, 'DEFAULT', 'DEFAULT'
WHERE NOT EXISTS (SELECT 1 FROM bl_3nf.ce_branches WHERE branch_id = 0);
COMMIT;

-- Inserting default row into ce_channels
INSERT INTO bl_3nf.ce_channels
SELECT 0, 0, 'Unknown', CURRENT_DATE, CURRENT_DATE, 'DEFAULT', 'DEFAULT'
WHERE NOT EXISTS (SELECT 1 FROM bl_3nf.ce_channels WHERE channel_id = 0);
COMMIT;

-- Inserting default row into ce_time_day
INSERT INTO bl_3nf.ce_time_day
SELECT 0, CURRENT_DATE, 0, 0, 0, 'Unknown', CURRENT_DATE, CURRENT_DATE, 'DEFAULT', 'DEFAULT'
WHERE NOT EXISTS (SELECT 1 FROM bl_3nf.ce_time_day WHERE date_id = 0);
COMMIT;

-- Inserting default row into ce_product_categories
INSERT INTO bl_3nf.ce_product_categories
SELECT 0, '0', 'Unknown', CURRENT_DATE, CURRENT_DATE, 'DEFAULT', 'DEFAULT'
WHERE NOT EXISTS (SELECT 1 FROM bl_3nf.ce_product_categories WHERE category_id = 0);
COMMIT;

-- Inserting default row into ce_product_subcategories
INSERT INTO bl_3nf.ce_product_subcategories
SELECT 0, '0', 'Unknown', '0', CURRENT_DATE, CURRENT_DATE, 'DEFAULT', 'DEFAULT'
WHERE NOT EXISTS (SELECT 1 FROM bl_3nf.ce_product_subcategories WHERE subcategory_id = 0);
COMMIT;

-- Inserting default row into ce_products
INSERT INTO bl_3nf.ce_products
SELECT 0, '0', 'Unknown', '0', 0.0, CURRENT_DATE, CURRENT_DATE, 'DEFAULT', 'DEFAULT'
WHERE NOT EXISTS (SELECT 1 FROM bl_3nf.ce_products WHERE product_id = 0);
COMMIT;

-- Inserting default row into SCD2 table
INSERT INTO bl_3nf.ce_product_prices_scd
SELECT 0, 0, 'Default', 0.0, CURRENT_DATE, NULL, 'Y', CURRENT_DATE, CURRENT_DATE, 'DEFAULT', 'DEFAULT'
WHERE NOT EXISTS (SELECT 1 FROM bl_3nf.ce_product_prices_scd WHERE price_id = 0);
COMMIT;
