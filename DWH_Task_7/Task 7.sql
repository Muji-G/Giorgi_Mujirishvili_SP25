-- 1. creating schema
BEGIN;
CREATE SCHEMA IF NOT EXISTS BL_DM;
COMMIT;

-- 2. creating sequences
BEGIN;
CREATE SEQUENCE IF NOT EXISTS BL_DM.seq_dim_employees;
CREATE SEQUENCE IF NOT EXISTS BL_DM.seq_dim_branches;
CREATE SEQUENCE IF NOT EXISTS BL_DM.seq_dim_channels;
CREATE SEQUENCE IF NOT EXISTS BL_DM.seq_dim_customers;
CREATE SEQUENCE IF NOT EXISTS BL_DM.seq_dim_products;
CREATE SEQUENCE IF NOT EXISTS BL_DM.seq_dim_product_prices_scd;
COMMIT;


-- 3. creating tables
-- dim_dates
BEGIN;
CREATE TABLE IF NOT EXISTS BL_DM.dim_dates (
    date_id         BIGINT PRIMARY KEY,
    date_act        DATE NOT NULL,
    year_no         INT NOT NULL,
    month_no        INT NOT NULL,
    day_no          INT NOT NULL,
    week_no         INT NOT NULL,
    weekday_no      INT NOT NULL,
    weekday_name    VARCHAR(15) NOT NULL,
    month_name      VARCHAR(15) NOT NULL,
    quarter_no      INT NOT NULL,
    ta_insert_dt    DATE NOT NULL,
    ta_update_dt    DATE NOT NULL
);
COMMIT;

-- dim_employees
BEGIN;
CREATE TABLE IF NOT EXISTS BL_DM.dim_employees (
    employee_id         BIGINT PRIMARY KEY,
    employee_src_id     VARCHAR(30) NOT NULL,
    employee_name       VARCHAR(100) NOT NULL,
    role_name           VARCHAR(100) NOT NULL,
    hire_dt             DATE NOT NULL,
    city_name           VARCHAR(50) NOT NULL,
    region_name         VARCHAR(50) NOT NULL,
    country_name        VARCHAR(50) NOT NULL,
    ta_insert_dt        DATE NOT NULL,
    ta_update_dt        DATE NOT NULL,
    source_system       VARCHAR(100) NOT NULL,
    source_entity       VARCHAR(100) NOT NULL
);

-- dim_customers
CREATE TABLE IF NOT EXISTS BL_DM.dim_customers (
    customer_id         BIGINT PRIMARY KEY,
    customer_src_id     VARCHAR(30) NOT NULL,
    customer_name       VARCHAR(100) NOT NULL,
    segment_name        VARCHAR(50) NOT NULL,
    city_name           VARCHAR(50) NOT NULL,
    region_name         VARCHAR(50) NOT NULL,
    country_name        VARCHAR(50) NOT NULL,
    ta_insert_dt        DATE NOT NULL,
    ta_update_dt        DATE NOT NULL,
    source_system       VARCHAR(100) NOT NULL,
    source_entity       VARCHAR(100) NOT NULL
);
COMMIT;


-- dim_branches
BEGIN;
CREATE TABLE IF NOT EXISTS BL_DM.dim_branches (
    branch_id           BIGINT PRIMARY KEY,
    branch_src_id       VARCHAR(30) NOT NULL,
    city_name           VARCHAR(50) NOT NULL,
    region_name         VARCHAR(50) NOT NULL,
    country_name        VARCHAR(50) NOT NULL,
    ta_insert_dt        DATE NOT NULL,
    ta_update_dt        DATE NOT NULL,
    source_system       VARCHAR(100) NOT NULL,
    source_entity       VARCHAR(100) NOT NULL
);

-- dim_channels
CREATE TABLE IF NOT EXISTS BL_DM.dim_channels (
    channel_id          BIGINT PRIMARY KEY,
    channel_src_id      VARCHAR(30) NOT NULL,
    channel_name        VARCHAR(100) NOT NULL,
    ta_insert_dt        DATE NOT NULL,
    ta_update_dt        DATE NOT NULL,
    source_system       VARCHAR(100) NOT NULL,
    source_entity       VARCHAR(100) NOT NULL
);
COMMIT;


-- dim_products
BEGIN;
CREATE TABLE IF NOT EXISTS BL_DM.dim_products (
    product_id          BIGINT PRIMARY KEY,
    product_src_id      VARCHAR(30) NOT NULL,
    product_name        VARCHAR(100) NOT NULL,
    category_name       VARCHAR(50) NOT NULL,
    loss_rate_act       FLOAT NOT NULL,
    ta_insert_dt        DATE NOT NULL,
    ta_update_dt        DATE NOT NULL,
    source_system       VARCHAR(100) NOT NULL,
    source_entity       VARCHAR(100) NOT NULL
);

-- dim_product_prices_scd
CREATE TABLE IF NOT EXISTS BL_DM.dim_product_prices_scd (
    price_id            BIGINT PRIMARY KEY,
    product_src_id      VARCHAR(30) NOT NULL,
    price_unit_act      FLOAT NOT NULL,
    price_fact_act      FLOAT NOT NULL,
    start_dt            DATE NOT NULL,
    end_dt              DATE NOT NULL,
    is_active           VARCHAR(1) NOT NULL,
    ta_insert_dt        DATE NOT NULL,
    ta_update_dt        DATE NOT NULL,
    source_system       VARCHAR(100) NOT NULL,
    source_entity       VARCHAR(100) NOT NULL
);
COMMIT


-- fct_sales
BEGIN;
CREATE TABLE IF NOT EXISTS BL_DM.fct_sales (
    date_id             BIGINT NOT NULL,
    customer_id         BIGINT NOT NULL,
    employee_id         BIGINT NOT NULL,
    product_id          BIGINT NOT NULL,
    branch_id           BIGINT NOT NULL,
    channel_id          BIGINT NOT NULL,
    quantity_act        FLOAT,
    unit_price_act      FLOAT,
    amount_act          FLOAT,
    cost_act            FLOAT,
    gross_income_act    FLOAT,
    discount_act        FLOAT,
    ta_insert_dt        DATE NOT NULL,
    ta_update_dt        DATE NOT NULL
);

COMMIT;


-- 4. inserting default rows

BEGIN;

-- dim_dates default row
INSERT INTO BL_DM.dim_dates
SELECT -1, '1990-01-01', 0, 0, 0, 0, 0, 'Unknown', 'Unknown', 0, CURRENT_DATE, CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM BL_DM.dim_dates WHERE date_id = -1);

-- dim_employees default row
INSERT INTO BL_DM.dim_employees
SELECT -1, 'Unknown', 'Unknown', 'Unknown', '1990-01-01', 'Unknown', 'Unknown', 'Unknown', CURRENT_DATE, CURRENT_DATE, 'DEFAULT', 'DEFAULT'
WHERE NOT EXISTS (SELECT 1 FROM BL_DM.dim_employees WHERE employee_id = -1);

-- dim_branches default row
INSERT INTO BL_DM.dim_branches
SELECT -1, 'Unknown', 'Unknown', 'Unknown', 'Unknown', CURRENT_DATE, CURRENT_DATE, 'DEFAULT', 'DEFAULT'
WHERE NOT EXISTS (SELECT 1 FROM BL_DM.dim_branches WHERE branch_id = -1);

-- dim_channels default row
INSERT INTO BL_DM.dim_channels
SELECT -1, 'Unknown', 'Unknown', CURRENT_DATE, CURRENT_DATE, 'DEFAULT', 'DEFAULT'
WHERE NOT EXISTS (SELECT 1 FROM BL_DM.dim_channels WHERE channel_id = -1);

-- dim_customers default row
INSERT INTO BL_DM.dim_customers
SELECT -1, 'Unknown', 'Unknown', 'Unknown', 'Unknown', 'Unknown', 'Unknown', CURRENT_DATE, CURRENT_DATE, 'DEFAULT', 'DEFAULT'
WHERE NOT EXISTS (SELECT 1 FROM BL_DM.dim_customers WHERE customer_id = -1);

-- dim_products default row
INSERT INTO BL_DM.dim_products
SELECT -1, 'Unknown', 'Unknown', 'Unknown', 0.0, CURRENT_DATE, CURRENT_DATE, 'DEFAULT', 'DEFAULT'
WHERE NOT EXISTS (SELECT 1 FROM BL_DM.dim_products WHERE product_id = -1);

-- dim_product_prices_scd default row
INSERT INTO BL_DM.dim_product_prices_scd
SELECT -1, 'Unknown', 0.0, 0.0, '1990-01-01', '9999-12-31', 'N', CURRENT_DATE, CURRENT_DATE, 'DEFAULT', 'DEFAULT'
WHERE NOT EXISTS (SELECT 1 FROM BL_DM.dim_product_prices_scd WHERE price_id = -1);

COMMIT;


-- altering the tables based on comments
BEGIN;
-- setting default sequence for dim_employees
ALTER TABLE BL_DM.dim_employees
ALTER COLUMN employee_id SET DEFAULT nextval('BL_DM.seq_dim_employees');

-- setting default sequence for dim_customers
ALTER TABLE BL_DM.dim_customers
ALTER COLUMN customer_id SET DEFAULT nextval('BL_DM.seq_dim_customers');

-- setting default sequence for dim_branches
ALTER TABLE BL_DM.dim_branches
ALTER COLUMN branch_id SET DEFAULT nextval('BL_DM.seq_dim_branches');

-- setting default sequence for dim_channels
ALTER TABLE BL_DM.dim_channels
ALTER COLUMN channel_id SET DEFAULT nextval('BL_DM.seq_dim_channels');

-- setting default sequence for dim_products
ALTER TABLE BL_DM.dim_products
ALTER COLUMN product_id SET DEFAULT nextval('BL_DM.seq_dim_products');

-- setting default sequence for dim_product_prices_scd
ALTER TABLE BL_DM.dim_product_prices_scd
ALTER COLUMN price_id SET DEFAULT nextval('BL_DM.seq_dim_product_prices_scd');
COMMIT;


BEGIN;
-- adding foreign key for date_id
ALTER TABLE BL_DM.fct_sales
ADD CONSTRAINT fk_sales_date
FOREIGN KEY (date_id)
REFERENCES BL_DM.dim_dates(date_id);

-- adding foreign key for customer_id
ALTER TABLE BL_DM.fct_sales
ADD CONSTRAINT fk_sales_customer
FOREIGN KEY (customer_id)
REFERENCES BL_DM.dim_customers(customer_id);

-- adding foreign key for employee_id
ALTER TABLE BL_DM.fct_sales
ADD CONSTRAINT fk_sales_employee
FOREIGN KEY (employee_id)
REFERENCES BL_DM.dim_employees(employee_id);

-- adding foreign key for product_id
ALTER TABLE BL_DM.fct_sales
ADD CONSTRAINT fk_sales_product
FOREIGN KEY (product_id)
REFERENCES BL_DM.dim_products(product_id);

-- adding foreign key for branch_id
ALTER TABLE BL_DM.fct_sales
ADD CONSTRAINT fk_sales_branch
FOREIGN KEY (branch_id)
REFERENCES BL_DM.dim_branches(branch_id);

-- adding foreign key for channel_id
ALTER TABLE BL_DM.fct_sales
ADD CONSTRAINT fk_sales_channel
FOREIGN KEY (channel_id)
REFERENCES BL_DM.dim_channels(channel_id);
COMMIT;


BEGIN;
ALTER TABLE BL_DM.fct_sales
ADD COLUMN price_id BIGINT DEFAULT -1;
ALTER TABLE BL_DM.fct_sales
ADD CONSTRAINT fk_sales_price
FOREIGN KEY (price_id)
REFERENCES BL_DM.dim_product_prices_scd(price_id);
COMMIT;

