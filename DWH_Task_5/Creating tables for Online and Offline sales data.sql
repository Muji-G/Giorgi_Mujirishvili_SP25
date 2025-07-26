CREATE SCHEMA IF NOT EXISTS sa_online;
CREATE SCHEMA IF NOT EXISTS sa_offline;

-- Create file_fdw extension and server
CREATE EXTENSION IF NOT EXISTS file_fdw;
CREATE SERVER IF NOT EXISTS file_server
  FOREIGN DATA WRAPPER file_fdw;

-- External table for OFFLINE orders
CREATE FOREIGN TABLE IF NOT EXISTS sa_offline.ext_offline_orders (
    date_text              VARCHAR(20),
    time_text              VARCHAR(20),
    item_code              VARCHAR(20),
    quantity_sold          VARCHAR(10),
    unit_selling_price     VARCHAR(20),
    sale_or_return         VARCHAR(10),
    discount               VARCHAR(20),
    category_code          VARCHAR(20),
    wholesale_price        VARCHAR(20),
    loss_rate              VARCHAR(20),
    total_sales            VARCHAR(20),
    cost                   VARCHAR(20),
    gross_income           VARCHAR(20),
    year                   VARCHAR(10),
    month                  VARCHAR(10),
    day                    VARCHAR(10),
    employee_id            VARCHAR(20),
    branch                 VARCHAR(50),
    city                   VARCHAR(50),
    source_system          VARCHAR(20),
    customer_id            VARCHAR(50),
    transaction_id         VARCHAR(50)
)
SERVER file_server
OPTIONS (
    filename 'C:/Users/Elitebook/Desktop/SourceSystem_Offline.csv',
    format 'csv',
    header 'true'
);

-- External table for ONLINE orders
CREATE FOREIGN TABLE IF NOT EXISTS sa_online.ext_online_orders (
    raw_date              VARCHAR(20),
    sale_time             VARCHAR(20),
    item_code             VARCHAR(20),
    quantity_sold         VARCHAR(10),
    unit_selling_price    VARCHAR(20),
    sale_or_return        VARCHAR(10),
    discount              VARCHAR(20),
    item_name             VARCHAR(100),
    category_code         VARCHAR(20),
    category_name         VARCHAR(50),
    wholesale_price       VARCHAR(20),
    loss_rate             VARCHAR(20),
    total_sales           VARCHAR(20),
    cost                  VARCHAR(20),
    gross_income          VARCHAR(20),
    raw_datetime          VARCHAR(30),
    year                  VARCHAR(10),
    month                 VARCHAR(10),
    day                   VARCHAR(10),
    employee_id           VARCHAR(20),
    branch                VARCHAR(50),
    city                  VARCHAR(50),
    source_system         VARCHAR(20),
    transaction_id_1      VARCHAR(50),
    customer_id_1         VARCHAR(50),
    customer_id_2         VARCHAR(50),
    transaction_id_2      VARCHAR(50)
)
SERVER file_server
OPTIONS (
    filename 'C:/Users/Elitebook/Desktop/SourceSystem_Online.csv',
    format 'csv',
    header 'true'
);

-- Create target SRC tables (offline)
CREATE TABLE IF NOT EXISTS sa_offline.src_offline_orders (
    date_text              VARCHAR(20),
    time_text              VARCHAR(20),
    item_code              VARCHAR(20),
    quantity_sold          VARCHAR(10),
    unit_selling_price     VARCHAR(20),
    sale_or_return         VARCHAR(10),
    discount               VARCHAR(20),
    category_code          VARCHAR(20),
    wholesale_price        VARCHAR(20),
    loss_rate              VARCHAR(20),
    total_sales            VARCHAR(20),
    cost                   VARCHAR(20),
    gross_income           VARCHAR(20),
    year                   VARCHAR(10),
    month                  VARCHAR(10),
    day                    VARCHAR(10),
    employee_id            VARCHAR(20),
    branch                 VARCHAR(50),
    city                   VARCHAR(50),
    source_system          VARCHAR(20),
    customer_id            VARCHAR(50),
    transaction_id         VARCHAR(50)
);

-- inserting from EXT to SRC for offline orders
BEGIN;

INSERT INTO sa_offline.src_offline_orders (
    date_text,
    time_text,
    item_code,
    quantity_sold,
    unit_selling_price,
    sale_or_return,
    discount,
    category_code,
    wholesale_price,
    loss_rate,
    total_sales,
    cost,
    gross_income,
    year,
    month,
    day,
    employee_id,
    branch,
    city,
    source_system,
    customer_id,
    transaction_id
)
SELECT
    date_text,
    time_text,
    item_code,
    quantity_sold,
    unit_selling_price,
    sale_or_return,
    discount,
    category_code,
    wholesale_price,
    loss_rate,
    total_sales,
    cost,
    gross_income,
    year,
    month,
    day,
    employee_id,
    branch,
    city,
    source_system,
    customer_id,
    transaction_id
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY transaction_id
               ORDER BY transaction_id
           ) AS rn
    FROM sa_offline.ext_offline_orders
) AS dedup
WHERE rn = 1;

COMMIT;

-- Create target SRC tables (online)
CREATE TABLE IF NOT EXISTS sa_online.src_online_orders (
    raw_date              VARCHAR(20),
    sale_time             VARCHAR(20),
    item_code             VARCHAR(20),
    quantity_sold         VARCHAR(10),
    unit_selling_price    VARCHAR(20),
    sale_or_return        VARCHAR(10),
    discount              VARCHAR(20),
    item_name             VARCHAR(100),
    category_code         VARCHAR(20),
    category_name         VARCHAR(50),
    wholesale_price       VARCHAR(20),
    loss_rate             VARCHAR(20),
    total_sales           VARCHAR(20),
    cost                  VARCHAR(20),
    gross_income          VARCHAR(20),
    raw_datetime          VARCHAR(30),
    year                  VARCHAR(10),
    month                 VARCHAR(10),
    day                   VARCHAR(10),
    employee_id           VARCHAR(20),
    branch                VARCHAR(50),
    city                  VARCHAR(50),
    source_system         VARCHAR(20),
    transaction_id_1      VARCHAR(50),
    customer_id_1         VARCHAR(50),
    customer_id_2         VARCHAR(50),
    transaction_id_2      VARCHAR(50)
);

-- checking for differences in transaction_id and customer_id fields
SELECT COUNT(*) AS total_records FROM sa_online.ext_online_orders;

SELECT COUNT(*) AS differing_transaction_ids
FROM sa_online.ext_online_orders
WHERE transaction_id_1 IS DISTINCT FROM transaction_id_2;

SELECT COUNT(*) AS differing_customer_ids
FROM sa_online.ext_online_orders
WHERE customer_id_1 IS DISTINCT FROM customer_id_2;

--inserting only deduplicated rows into SRC table, assuming transaction_id_1 is primary

BEGIN;

INSERT INTO sa_online.src_online_orders (
    raw_date,
    sale_time,
    item_code,
    quantity_sold,
    unit_selling_price,
    sale_or_return,
    discount,
    item_name,
    category_code,
    category_name,
    wholesale_price,
    loss_rate,
    total_sales,
    cost,
    gross_income,
    raw_datetime,
    year,
    month,
    day,
    employee_id,
    branch,
    city,
    source_system,
    transaction_id_1,
    customer_id_1,
    customer_id_2,
    transaction_id_2
)
SELECT
    raw_date,
    sale_time,
    item_code,
    quantity_sold,
    unit_selling_price,
    sale_or_return,
    discount,
    item_name,
    category_code,
    category_name,
    wholesale_price,
    loss_rate,
    total_sales,
    cost,
    gross_income,
    raw_datetime,
    year,
    month,
    day,
    employee_id,
    branch,
    city,
    source_system,
    transaction_id_1,
    customer_id_1,
    customer_id_2,
    transaction_id_2
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY transaction_id_1
               ORDER BY transaction_id_1
           ) AS rn
    FROM sa_online.ext_online_orders
) AS dedup
WHERE rn = 1;

COMMIT;


-- Preview external tables
SELECT * FROM sa_online.ext_online_orders LIMIT 5;
SELECT * FROM sa_offline.ext_offline_orders LIMIT 5;

-- Preview source tables
SELECT * FROM sa_online.src_online_orders LIMIT 5;
SELECT * FROM sa_offline.src_offline_orders LIMIT 5;
