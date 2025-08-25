BEGIN;
CREATE SCHEMA IF NOT EXISTS user_dilab_student54;
SET search_path TO user_dilab_student54;
COMMIT;

BEGIN;
CREATE TABLE IF NOT EXISTS stg_dim_products_raw(
  product_id_txt           VARCHAR(64),
  product_src_id_txt       VARCHAR(64),
  product_name             VARCHAR(512),
  category_name            VARCHAR(256),
  loss_rate_act_txt        VARCHAR(64),
  ta_insert_dt_txt         VARCHAR(64),
  ta_update_dt_txt         VARCHAR(64),
  source_system            VARCHAR(128),
  source_entity            VARCHAR(128)
);

CREATE TABLE IF NOT exists stg_dim_customers_raw(
  customer_id_txt          VARCHAR(64),
  customer_src_id_txt      VARCHAR(64),
  customer_name            VARCHAR(256),
  segment_name             VARCHAR(128),
  city_name                VARCHAR(128),
  region_name              VARCHAR(128),
  country_name             VARCHAR(128),
  ta_insert_dt_txt         VARCHAR(64),
  ta_update_dt_txt         VARCHAR(64),
  source_system            VARCHAR(128),
  source_entity            VARCHAR(128)
);


CREATE table IF NOT EXISTS stg_dim_dates_raw(
  date_id_txt              VARCHAR(16),
  date_act_txt             VARCHAR(16),
  year_no_txt              VARCHAR(8),
  month_no_txt             VARCHAR(8),
  day_no_txt               VARCHAR(8),
  week_no_txt              VARCHAR(8),
  weekday_no_txt           VARCHAR(8),
  weekday_name             VARCHAR(16),
  month_name               VARCHAR(16),
  quarter_no_txt           VARCHAR(8),
  ta_insert_dt_txt         VARCHAR(64),
  ta_update_dt_txt         VARCHAR(64)
);


CREATE TABLE IF NOT EXISTS stg_fct_sales_raw(
  date_id_txt              VARCHAR(16),
  customer_id_txt          VARCHAR(64),
  employee_id_txt          VARCHAR(64),
  product_id_txt           VARCHAR(64),
  branch_id_txt            VARCHAR(64),
  channel_id_txt           VARCHAR(64),
  price_id_txt             VARCHAR(64),
  quantity_act_txt         VARCHAR(64),
  unit_price_act_txt       VARCHAR(64),
  amount_act_txt           VARCHAR(64),
  cost_act_txt             VARCHAR(64),
  gross_income_act_txt     VARCHAR(64),
  discount_act_txt         VARCHAR(64),
  ta_insert_dt_txt         VARCHAR(64),
  ta_update_dt_txt         VARCHAR(64)
);
COMMIT;


TRUNCATE stg_dim_products_raw;
COPY stg_dim_products_raw
FROM 's3://aws-giorgi-mujirishvili-hw1/di_dwh_database/bl_dm/dim_products/dim_products.csv'
IAM_ROLE 'arn:aws:iam::260586643565:role/dilab-redshift-role'
REGION 'eu-central-1'
CSV IGNOREHEADER 1 DELIMITER ',' EMPTYASNULL BLANKSASNULL ACCEPTINVCHARS TRUNCATECOLUMNS;

TRUNCATE stg_dim_customers_raw;
COPY stg_dim_customers_raw
FROM 's3://aws-giorgi-mujirishvili-hw1/di_dwh_database/bl_dm/dim_customers/dim_customers.csv'
IAM_ROLE 'arn:aws:iam::260586643565:role/dilab-redshift-role'
REGION 'eu-central-1'
CSV IGNOREHEADER 1 DELIMITER ',' EMPTYASNULL BLANKSASNULL ACCEPTINVCHARS TRUNCATECOLUMNS;

TRUNCATE stg_dim_dates_raw;
COPY stg_dim_dates_raw
FROM 's3://aws-giorgi-mujirishvili-hw1/di_dwh_database/bl_dm/dim_dates/'
IAM_ROLE 'arn:aws:iam::260586643565:role/dilab-redshift-role'
REGION 'eu-central-1'
CSV IGNOREHEADER 1 DELIMITER ',' EMPTYASNULL BLANKSASNULL ACCEPTINVCHARS TRUNCATECOLUMNS
DATEFORMAT 'YYYY-MM-DD';

TRUNCATE stg_fct_sales_raw;
COPY stg_fct_sales_raw
FROM 's3://aws-giorgi-mujirishvili-hw1/di_dwh_database/bl_dm/fct_sales/'
IAM_ROLE 'arn:aws:iam::260586643565:role/dilab-redshift-role'
REGION 'eu-central-1'
CSV IGNOREHEADER 1 DELIMITER ',' EMPTYASNULL BLANKSASNULL ACCEPTINVCHARS TRUNCATECOLUMNS;



--TYPED DIMENSIONS

CREATE TABLE IF NOT EXISTS dim_products(
  product_id     BIGINT,
  product_src_id BIGINT,
  product_name   VARCHAR(512),
  category_name  VARCHAR(256),
  loss_rate_act  DECIMAL(9,4),
  ta_insert_dt   TIMESTAMP,
  ta_update_dt   TIMESTAMP,
  source_system  VARCHAR(128),
  source_entity  VARCHAR(128)
)
DISTSTYLE AUTO
SORTKEY AUTO;


INSERT INTO dim_products (
  product_id, product_src_id, product_name, category_name,
  loss_rate_act, ta_insert_dt, ta_update_dt, source_system, source_entity
)
WITH cleaned AS (
  SELECT
    NULLIF(TRIM(product_id_txt), '')                 AS product_id_txt,
    NULLIF(TRIM(product_src_id_txt), '')             AS product_src_id_txt,
    NULLIF(TRIM(product_name), '')                   AS product_name,
    NULLIF(TRIM(category_name), '')                  AS category_name,
    NULLIF(TRIM(loss_rate_act_txt), '')              AS loss_rate_act_txt,
    NULLIF(TRIM(ta_insert_dt_txt), '')               AS ta_insert_dt_txt,
    NULLIF(TRIM(ta_update_dt_txt), '')               AS ta_update_dt_txt,
    NULLIF(TRIM(source_system), '')                  AS source_system,
    NULLIF(TRIM(source_entity), '')                  AS source_entity
  FROM user_dilab_student54.stg_dim_products_raw
)
SELECT
  TRY_CAST(NULLIF(UPPER(product_id_txt),     'UNKNOWN') AS BIGINT)       AS product_id,
  TRY_CAST(NULLIF(UPPER(product_src_id_txt), 'UNKNOWN') AS BIGINT)       AS product_src_id,
  product_name,
  category_name,
  TRY_CAST(loss_rate_act_txt AS DECIMAL(9,4))                              AS loss_rate_act,
  TRY_CAST(ta_insert_dt_txt AS TIMESTAMP)                                  AS ta_insert_dt,
  TRY_CAST(ta_update_dt_txt AS TIMESTAMP)                                  AS ta_update_dt,
  source_system,
  source_entity
FROM cleaned;



CREATE TABLE IF NOT EXISTS dim_customers(
  customer_id     BIGINT,
  customer_src_id BIGINT,
  customer_name   VARCHAR(256),
  segment_name    VARCHAR(128),
  city_name       VARCHAR(128),
  region_name     VARCHAR(128),
  country_name    VARCHAR(128),
  ta_insert_dt    TIMESTAMP,
  ta_update_dt    TIMESTAMP,
  source_system   VARCHAR(128),
  source_entity   VARCHAR(128)
)
DISTSTYLE AUTO
SORTKEY AUTO;

INSERT INTO dim_customers (
  customer_id, customer_src_id, customer_name, segment_name,
  city_name, region_name, country_name, ta_insert_dt, ta_update_dt,
  source_system, source_entity
)
WITH cleaned AS (
  SELECT
    NULLIF(TRIM(customer_id_txt), '')            AS customer_id_txt,
    NULLIF(TRIM(customer_src_id_txt), '')        AS customer_src_id_txt,
    NULLIF(TRIM(customer_name), '')              AS customer_name,
    NULLIF(TRIM(segment_name), '')               AS segment_name,
    NULLIF(TRIM(city_name), '')                  AS city_name,
    NULLIF(TRIM(region_name), '')                AS region_name,
    NULLIF(TRIM(country_name), '')               AS country_name,
    NULLIF(TRIM(ta_insert_dt_txt), '')           AS ta_insert_dt_txt,
    NULLIF(TRIM(ta_update_dt_txt), '')           AS ta_update_dt_txt,
    NULLIF(TRIM(source_system), '')              AS source_system,
    NULLIF(TRIM(source_entity), '')              AS source_entity
  FROM stg_dim_customers_raw
)
SELECT
  TRY_CAST(NULLIF(UPPER(customer_id_txt),     'UNKNOWN') AS BIGINT),
  TRY_CAST(NULLIF(UPPER(customer_src_id_txt), 'UNKNOWN') AS BIGINT),
  customer_name, segment_name, city_name, region_name, country_name,
  TRY_CAST(ta_insert_dt_txt AS TIMESTAMP),
  TRY_CAST(ta_update_dt_txt AS TIMESTAMP),
  source_system, source_entity
FROM cleaned;


CREATE TABLE IF NOT EXISTS dim_dates(
  date_id       INTEGER,            
  date_act      DATE,
  year_no       SMALLINT,
  month_no      SMALLINT,
  day_no        SMALLINT,
  week_no       SMALLINT,
  weekday_no    SMALLINT,
  weekday_name  VARCHAR(16),
  month_name    VARCHAR(16),
  quarter_no    SMALLINT,
  ta_insert_dt  TIMESTAMP,
  ta_update_dt  TIMESTAMP
)
DISTSTYLE AUTO
SORTKEY (date_act);

TRUNCATE dim_dates;
INSERT INTO dim_dates (
  date_id, date_act, year_no, month_no, day_no,
  week_no, weekday_no, weekday_name, month_name, quarter_no,
  ta_insert_dt, ta_update_dt
)
SELECT
  TRY_CAST(NULLIF(TRIM(date_id_txt),   '') AS INTEGER),
  TRY_CAST(NULLIF(TRIM(date_act_txt),  '') AS DATE),
  TRY_CAST(NULLIF(TRIM(year_no_txt),   '') AS SMALLINT),
  TRY_CAST(NULLIF(TRIM(month_no_txt),  '') AS SMALLINT),
  TRY_CAST(NULLIF(TRIM(day_no_txt),    '') AS SMALLINT),
  TRY_CAST(NULLIF(TRIM(week_no_txt),   '') AS SMALLINT),
  TRY_CAST(NULLIF(TRIM(weekday_no_txt),'') AS SMALLINT),
  NULLIF(TRIM(weekday_name), ''),
  NULLIF(TRIM(month_name), ''),
  TRY_CAST(NULLIF(TRIM(quarter_no_txt),'') AS SMALLINT),
  TRY_CAST(NULLIF(TRIM(ta_insert_dt_txt), '') AS TIMESTAMP),
  TRY_CAST(NULLIF(TRIM(ta_update_dt_txt), '') AS TIMESTAMP)
FROM stg_dim_dates_raw;


-- TYPED FACT


CREATE TABLE IF NOT EXISTS fct_sales(
  date_id          INTEGER,
  customer_id      BIGINT,
  employee_id      BIGINT,
  product_id       BIGINT,
  branch_id        BIGINT,
  channel_id       BIGINT,
  price_id         BIGINT,
  quantity_act     INTEGER,
  unit_price_act   DECIMAL(12,2),
  amount_act       DECIMAL(14,2),
  cost_act         DECIMAL(14,2),
  gross_income_act DECIMAL(14,2),
  discount_act     DECIMAL(14,2),
  ta_insert_dt     TIMESTAMP,
  ta_update_dt     TIMESTAMP
)
DISTKEY (customer_id)     
SORTKEY (date_id);        


TRUNCATE user_dilab_student54.fct_sales;

INSERT INTO fct_sales (
  date_id, customer_id, employee_id, product_id, branch_id, channel_id, price_id,
  quantity_act, unit_price_act, amount_act, cost_act, gross_income_act, discount_act,
  ta_insert_dt, ta_update_dt
)
WITH cleaned AS (
  SELECT
    -- IDs: strip blanks; turn 'UNKNOWN' → NULL
    NULLIF(UPPER(TRIM(date_id_txt)),      'UNKNOWN') AS date_id_txt,
    NULLIF(UPPER(TRIM(customer_id_txt)),  'UNKNOWN') AS customer_id_txt,
    NULLIF(UPPER(TRIM(employee_id_txt)),  'UNKNOWN') AS employee_id_txt,
    NULLIF(UPPER(TRIM(product_id_txt)),   'UNKNOWN') AS product_id_txt,
    NULLIF(UPPER(TRIM(branch_id_txt)),    'UNKNOWN') AS branch_id_txt,
    NULLIF(UPPER(TRIM(channel_id_txt)),   'UNKNOWN') AS channel_id_txt,
    NULLIF(UPPER(TRIM(price_id_txt)),     'UNKNOWN') AS price_id_txt,

    NULLIF(TRIM(quantity_act_txt),      '') AS quantity_act_txt,
    NULLIF(TRIM(unit_price_act_txt),    '') AS unit_price_act_txt,
    NULLIF(TRIM(amount_act_txt),        '') AS amount_act_txt,
    NULLIF(TRIM(cost_act_txt),          '') AS cost_act_txt,
    NULLIF(TRIM(gross_income_act_txt),  '') AS gross_income_act_txt,
    NULLIF(TRIM(discount_act_txt),      '') AS discount_act_txt,

    NULLIF(TRIM(ta_insert_dt_txt),      '') AS ta_insert_dt_txt,
    NULLIF(TRIM(ta_update_dt_txt),      '') AS ta_update_dt_txt
  FROM stg_fct_sales_raw
)
SELECT
  TRY_CAST(date_id_txt     AS INTEGER),
  TRY_CAST(customer_id_txt AS BIGINT),
  TRY_CAST(employee_id_txt AS BIGINT),
  TRY_CAST(product_id_txt  AS BIGINT),
  TRY_CAST(branch_id_txt   AS BIGINT),
  TRY_CAST(channel_id_txt  AS BIGINT),
  TRY_CAST(price_id_txt    AS BIGINT),

  TRY_CAST(quantity_act_txt      AS INTEGER),
  TRY_CAST(unit_price_act_txt    AS DECIMAL(12,2)),
  TRY_CAST(amount_act_txt        AS DECIMAL(14,2)),
  TRY_CAST(cost_act_txt          AS DECIMAL(14,2)),
  TRY_CAST(gross_income_act_txt  AS DECIMAL(14,2)),
  TRY_CAST(discount_act_txt      AS DECIMAL(14,2)),

  TRY_CAST(ta_insert_dt_txt AS TIMESTAMP),
  TRY_CAST(ta_update_dt_txt AS TIMESTAMP)
FROM cleaned;

SELECT 'products' AS t,
       (SELECT COUNT(*) FROM user_dilab_student54.stg_dim_products_raw) AS stg,
       (SELECT COUNT(*) FROM user_dilab_student54.dim_products)          AS typed
UNION ALL
SELECT 'customers',
       (SELECT COUNT(*) FROM user_dilab_student54.stg_dim_customers_raw),
       (SELECT COUNT(*) FROM user_dilab_student54.dim_customers)
UNION ALL
SELECT 'dates',
       (SELECT COUNT(*) FROM user_dilab_student54.stg_dim_dates_raw),
       (SELECT COUNT(*) FROM user_dilab_student54.dim_dates)
UNION ALL
SELECT 'fct_sales',
       (SELECT COUNT(*) FROM user_dilab_student54.stg_fct_sales_raw),
       (SELECT COUNT(*) FROM user_dilab_student54.fct_sales);

ANALYZE COMPRESSION dim_products;
ANALYZE COMPRESSION dim_customers;
ANALYZE COMPRESSION dim_dates;
ANALYZE COMPRESSION fct_sales;



-- Table summary 
SELECT
  ti."schema",
  ti."table",
  ti.tbl_rows                                   AS rows,
  ti.size                                       AS size_mb,
  ti.encoded,
  ti.diststyle,
  ti.sortkey1,
  ti.sortkey_num,
  ti.unsorted,                                 
  ti.stats_off,                                 
  ti.skew_rows,                                 
  ti.skew_sortkey1                             
FROM svv_table_info ti
WHERE ti."schema" = 'user_dilab_student54'
ORDER BY ti.size DESC;

SELECT
  table_schema, table_name, column_name, data_type, ordinal_position,
  character_maximum_length AS max_char, numeric_precision
FROM svv_columns
WHERE table_schema = 'user_dilab_student54'
  AND table_name IN ('fct_sales','dim_products','dim_customers','dim_dates')
ORDER BY table_name, ordinal_position;


-- Recreate with the SAME columns, but force RAW (no compression) on each
CREATE TABLE fct_sales_withoutcomp (
  date_id           INTEGER          ENCODE RAW,
  customer_id       BIGINT           ENCODE RAW,
  employee_id       BIGINT           ENCODE RAW,
  product_id        BIGINT           ENCODE RAW,
  branch_id         BIGINT           ENCODE RAW,
  channel_id        BIGINT           ENCODE RAW,
  price_id          BIGINT           ENCODE RAW,
  quantity_act      INTEGER          ENCODE RAW,
  unit_price_act    DECIMAL(12,2)    ENCODE RAW,
  amount_act        DECIMAL(14,2)    ENCODE RAW,
  cost_act          DECIMAL(14,2)    ENCODE RAW,
  gross_income_act  DECIMAL(14,2)    ENCODE RAW,
  discount_act      DECIMAL(14,2)    ENCODE RAW,
  ta_insert_dt      TIMESTAMP        ENCODE RAW,
  ta_update_dt      TIMESTAMP        ENCODE RAW
)
DISTKEY (customer_id)
SORTKEY (date_id);


INSERT INTO user_dilab_student54.fct_sales_withoutcomp
SELECT * FROM user_dilab_student54.fct_sales;

ANALYZE COMPRESSION user_dilab_student54.fct_sales;               
ANALYZE COMPRESSION user_dilab_student54.fct_sales_withoutcomp;   

CREATE TABLE fct_sales_analyzedcomp (
  date_id           INTEGER          ENCODE RAW,     
  customer_id       BIGINT           ENCODE AZ64,
  employee_id       BIGINT           ENCODE AZ64,
  product_id        BIGINT           ENCODE AZ64,
  branch_id         BIGINT           ENCODE AZ64,
  channel_id        BIGINT           ENCODE AZ64,
  price_id          BIGINT           ENCODE AZ64,
  quantity_act      INTEGER          ENCODE RAW,     
  unit_price_act    DECIMAL(12,2)    ENCODE AZ64,
  amount_act        DECIMAL(14,2)    ENCODE AZ64,
  cost_act          DECIMAL(14,2)    ENCODE AZ64,
  gross_income_act  DECIMAL(14,2)    ENCODE AZ64,
  discount_act      DECIMAL(14,2)    ENCODE AZ64,
  ta_insert_dt      TIMESTAMP        ENCODE AZ64,
  ta_update_dt      TIMESTAMP        ENCODE AZ64
)
DISTKEY (customer_id)
SORTKEY (date_id);

INSERT INTO fct_sales_analyzedcomp
SELECT * FROM fct_sales;

SELECT "table", tbl_rows, size AS size_mb, diststyle, sortkey1, sortkey_num, encoded
FROM svv_table_info
WHERE "schema" = 'user_dilab_student54'
  AND "table" IN ('fct_sales','fct_sales_withoutcomp','fct_sales_analyzedcomp')
ORDER BY size DESC;


--
CREATE TABLE IF NOT EXISTS user_dilab_student54.rpt_sales_monthly_channel (
  month_start   DATE,
  channel_id    BIGINT,
  country_name  VARCHAR(128),
  revenue       DECIMAL(18,2),
  quantity      BIGINT,
  customers     BIGINT
)
DISTSTYLE KEY
DISTKEY (channel_id)
SORTKEY (month_start);

-- Simple log table to capture runtimes
CREATE TABLE IF NOT EXISTS user_dilab_student54.rpt_etl_log (
  run_id        BIGINT IDENTITY(1,1),
  started_at    TIMESTAMP,
  finished_at   TIMESTAMP,
  date_from     DATE,
  date_to       DATE,
  inserted_rows BIGINT,
  query_id      BIGINT,
  exec_ms       BIGINT,
  note          VARCHAR(200)
)
DISTSTYLE AUTO;


--PROCEDURE
CREATE OR REPLACE PROCEDURE user_dilab_student54.sp_load_rpt_sales_monthly(
  IN p_from DATE,
  IN p_to   DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_start   TIMESTAMP;
  v_qid     BIGINT;
  v_rows    BIGINT;
  v_exec_ms BIGINT;
BEGIN
  -- turn off result cache for this session (important for timing tests)
  EXECUTE 'SET enable_result_cache_for_session TO OFF';

  v_start := GETDATE();

  -- idempotent delete for the requested month range
  DELETE FROM user_dilab_student54.rpt_sales_monthly_channel
  WHERE month_start BETWEEN date_trunc('month', p_from)
                        AND date_trunc('month', p_to);

  -- === MAIN SELECT (joins 3+ tables) ===
  INSERT INTO user_dilab_student54.rpt_sales_monthly_channel
  SELECT
    date_trunc('month', d.date_act) AS month_start,
    s.channel_id,
    c.country_name,
    SUM(s.amount_act)               AS revenue,
    SUM(s.quantity_act)             AS quantity,
    COUNT(DISTINCT s.customer_id)   AS customers
  FROM user_dilab_student54.fct_sales      AS s
  JOIN user_dilab_student54.dim_dates      AS d ON d.date_id     = s.date_id
  JOIN user_dilab_student54.dim_customers  AS c ON c.customer_id = s.customer_id
  -- Optional fourth table:
  -- JOIN user_dilab_student54.dim_products   AS p ON p.product_id  = s.product_id
  WHERE d.date_act BETWEEN p_from AND p_to
  GROUP BY 1,2,3;

  -- capture query id and runtime
  SELECT pg_last_query_id() INTO v_qid;

  SELECT SUM(rows) INTO v_rows            -- rows inserted across slices
  FROM stl_insert WHERE query = v_qid;

  SELECT DATEDIFF(ms, starttime, endtime) INTO v_exec_ms
  FROM stl_query WHERE query = v_qid;

  ANALYZE user_dilab_student54.rpt_sales_monthly_channel;

  INSERT INTO user_dilab_student54.rpt_etl_log
  (started_at, finished_at, date_from, date_to, inserted_rows, query_id, exec_ms, note)
  VALUES (v_start, GETDATE(), p_from, p_to, v_rows, v_qid, v_exec_ms, 'sp_load_rpt_sales_monthly');
END;
$$;

-- CALLING THE PROCEDURE
CALL user_dilab_student54.sp_load_rpt_sales_monthly('2024-01-01','2024-12-31');

SELECT COUNT(*) AS rows_loaded
FROM rpt_sales_monthly_channel
WHERE month_start BETWEEN DATE '2024-01-01' AND DATE '2024-12-31';

SELECT *
FROM rpt_sales_monthly_channel
WHERE month_start BETWEEN DATE '2024-01-01' AND DATE '2024-12-31'
ORDER BY month_start, channel_id
LIMIT 50;

SELECT *
FROM rpt_etl_log
ORDER BY run_id DESC
LIMIT 5;


-- Making sure the cache is off for fair timing
SET enable_result_cache_for_session TO OFF;

-- Looking at the plan 
EXPLAIN
SELECT
  date_trunc('month', d.date_act) AS month_start,
  s.channel_id,
  c.country_name,
  SUM(s.amount_act)             AS revenue,
  SUM(s.quantity_act)           AS quantity,
  COUNT(DISTINCT s.customer_id) AS customers
FROM user_dilab_student54.fct_sales     s
JOIN user_dilab_student54.dim_dates     d ON d.date_id     = s.date_id
JOIN user_dilab_student54.dim_customers c ON c.customer_id = s.customer_id
WHERE d.date_act BETWEEN DATE '2024-01-01' AND DATE '2024-12-31'
GROUP BY 1,2,3;

-- Running the query once
SELECT
  date_trunc('month', d.date_act) AS month_start,
  s.channel_id,
  c.country_name,
  SUM(s.amount_act) AS revenue,
  SUM(s.quantity_act) AS quantity,
  COUNT(DISTINCT s.customer_id) AS customers
FROM user_dilab_student54.fct_sales s
JOIN user_dilab_student54.dim_dates d     ON d.date_id     = s.date_id
JOIN user_dilab_student54.dim_customers c ON c.customer_id = s.customer_id
WHERE d.date_act BETWEEN DATE '2024-01-01' AND DATE '2024-12-31'
GROUP BY 1,2,3;

-- Grabing the last query id 
SELECT pg_last_query_id() 

-- Checking query summary
SELECT * FROM svl_query_summary
WHERE query = 1970220;

-- turn off result cache for fair timing
SET enable_result_cache_for_session TO OFF;

-- Building optimized fact with encodings auto-chosen from data
DROP TABLE IF EXISTS user_dilab_student54.fct_sales_opt;

CREATE TABLE user_dilab_student54.fct_sales_opt
DISTKEY (channel_id)
SORTKEY (date_id, channel_id)
AS
SELECT * FROM user_dilab_student54.fct_sales;

ANALYZE user_dilab_student54.fct_sales_opt;
VACUUM SORT ONLY user_dilab_student54.fct_sales_opt;

EXPLAIN
SELECT date_trunc('month', d.date_act) AS month_start,
       s.channel_id,
       c.country_name,
       SUM(s.amount_act) AS revenue,
       SUM(s.quantity_act) AS quantity,
       COUNT(DISTINCT s.customer_id) AS customers
FROM user_dilab_student54.fct_sales_opt s
JOIN user_dilab_student54.dim_dates d     ON d.date_id     = s.date_id
JOIN user_dilab_student54.dim_customers c ON c.customer_id = s.customer_id
WHERE d.date_act BETWEEN DATE '2024-01-01' AND DATE '2024-12-31'
GROUP BY 1,2,3;

EXPLAIN
SELECT date_trunc('month', d.date_act) AS month_start,
       s.channel_id,
       c.country_name,
       SUM(s.amount_act) AS revenue,
       SUM(s.quantity_act) AS quantity,
       COUNT(DISTINCT s.customer_id) AS customers
FROM user_dilab_student54.fct_sales_opt s
JOIN user_dilab_student54.dim_dates d     ON d.date_id     = s.date_id
JOIN user_dilab_student54.dim_customers c ON c.customer_id = s.customer_id
WHERE d.date_act BETWEEN DATE '2024-01-01' AND DATE '2024-12-31'
GROUP BY 1,2,3;


SET enable_result_cache_for_session TO OFF;
SELECT date_trunc('month', d.date_act), s.channel_id, c.country_name,
       SUM(s.amount_act), SUM(s.quantity_act), COUNT(DISTINCT s.customer_id)
FROM user_dilab_student54.fct_sales s
JOIN user_dilab_student54.dim_dates d     ON d.date_id     = s.date_id
JOIN user_dilab_student54.dim_customers c ON c.customer_id = s.customer_id
WHERE d.date_act BETWEEN DATE '2024-01-01' AND DATE '2024-12-31'
GROUP BY 1,2,3;

SELECT DATEDIFF(ms, starttime, endtime) AS elapsed_ms
FROM stl_query
WHERE query = pg_last_query_id();

SET enable_result_cache_for_session TO OFF;
SELECT date_trunc('month', d.date_act), s.channel_id, c.country_name,
       SUM(s.amount_act), SUM(s.quantity_act), COUNT(DISTINCT s.customer_id)
FROM user_dilab_student54.fct_sales_opt s
JOIN user_dilab_student54.dim_dates d     ON d.date_id     = s.date_id
JOIN user_dilab_student54.dim_customers c ON c.customer_id = s.customer_id
WHERE d.date_act BETWEEN DATE '2024-01-01' AND DATE '2024-12-31'
GROUP BY 1,2,3;



-- turn off result cache when the proc runs
CREATE OR REPLACE PROCEDURE user_dilab_student54.sp_load_rpt_sales_monthly_opt(
  IN p_from DATE,
  IN p_to   DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_start   TIMESTAMP;
  v_qid     BIGINT;
  v_rows    BIGINT;
  v_exec_ms BIGINT;
BEGIN
  EXECUTE 'SET enable_result_cache_for_session TO OFF';
  v_start := GETDATE();

  -- idempotent replace for the requested window
  DELETE FROM user_dilab_student54.rpt_sales_monthly_channel
  WHERE month_start BETWEEN date_trunc('month', p_from)
                        AND date_trunc('month', p_to);

  INSERT INTO user_dilab_student54.rpt_sales_monthly_channel
  SELECT
    date_trunc('month', d.date_act) AS month_start,
    s.channel_id,
    c.country_name,
    SUM(s.amount_act)             AS revenue,
    SUM(s.quantity_act)           AS quantity,
    COUNT(DISTINCT s.customer_id) AS customers
  FROM user_dilab_student54.fct_sales_opt    s        -- << optimized fact
  JOIN user_dilab_student54.dim_dates        d ON d.date_id     = s.date_id
  JOIN user_dilab_student54.dim_customers    c ON c.customer_id = s.customer_id
  WHERE d.date_act BETWEEN p_from AND p_to
  GROUP BY 1,2,3;

  -- capture metrics
  SELECT pg_last_query_id() INTO v_qid;
  SELECT COALESCE(SUM(rows),0) INTO v_rows FROM stl_insert WHERE query = v_qid;
  SELECT DATEDIFF(ms, starttime, endtime) INTO v_exec_ms FROM stl_query WHERE query = v_qid;

  ANALYZE user_dilab_student54.rpt_sales_monthly_channel;

  INSERT INTO user_dilab_student54.rpt_etl_log
    (started_at, finished_at, date_from, date_to, inserted_rows, query_id, exec_ms, note)
  VALUES
    (v_start, GETDATE(), p_from, p_to, v_rows, v_qid, v_exec_ms, 'sp_load_rpt_sales_monthly_opt');
END;
$$;


CALL user_dilab_student54.sp_load_rpt_sales_monthly_opt('2024-01-01','2024-12-31');

-- rows written for the window
SELECT COUNT(*) AS rows_loaded
FROM user_dilab_student54.rpt_sales_monthly_channel
WHERE month_start BETWEEN '2024-01-01' AND '2024-12-31';

-- quick sample
SELECT *
FROM user_dilab_student54.rpt_sales_monthly_channel
WHERE month_start BETWEEN '2024-01-01' AND '2024-12-31'
ORDER BY month_start, channel_id
LIMIT 50;

-- last run log + timing
SELECT *
FROM user_dilab_student54.rpt_etl_log
ORDER BY run_id DESC
LIMIT 1;

CREATE TABLE lineorder_1
(
lo_orderkey INTEGER NOT NULL,
lo_linenumber INTEGER NOT NULL,
lo_custkey INTEGER NOT NULL,
lo_partkey INTEGER NOT NULL,
lo_suppkey INTEGER NOT NULL,
lo_orderdate INTEGER NOT NULL,
lo_orderpriority VARCHAR(15) NOT NULL,
lo_shippriority VARCHAR(1) NOT NULL,
lo_quantity INTEGER NOT NULL,
lo_extendedprice INTEGER NOT NULL,
lo_ordertotalprice INTEGER NOT NULL,
lo_discount INTEGER NOT NULL,
lo_revenue INTEGER NOT NULL,
lo_supplycost INTEGER NOT NULL,
lo_tax INTEGER NOT NULL,
lo_commitdate INTEGER NOT NULL,
lo_shipmode VARCHAR(10) NOT NULL
);

CREATE TABLE lineorder_2
(
lo_orderkey INTEGER NOT NULL,
lo_linenumber INTEGER NOT NULL,
lo_custkey INTEGER NOT NULL,
lo_partkey INTEGER NOT NULL,
lo_suppkey INTEGER NOT NULL,
lo_orderdate INTEGER NOT NULL,
lo_orderpriority VARCHAR(15) NOT NULL,
lo_shippriority VARCHAR(1) NOT NULL,
lo_quantity INTEGER NOT NULL,
lo_extendedprice INTEGER NOT NULL,
lo_ordertotalprice INTEGER NOT NULL,
lo_discount INTEGER NOT NULL,
lo_revenue INTEGER NOT NULL,
lo_supplycost INTEGER NOT NULL,
lo_tax INTEGER NOT NULL,
lo_commitdate INTEGER NOT NULL,
lo_shipmode VARCHAR(10) NOT NULL
);


-- COPY 1
COPY lineorder_1
(
  lo_orderkey,
  lo_linenumber,
  lo_custkey,
  lo_partkey,
  lo_suppkey,
  lo_orderdate,
  lo_orderpriority,
  lo_shippriority,
  lo_quantity,
  lo_extendedprice,
  lo_ordertotalprice,
  lo_discount,
  lo_revenue,
  lo_supplycost,
  lo_tax,
  lo_commitdate,
  lo_shipmode
)
FROM 's3://s3labbucket/files/lineorder/file/'
CREDENTIALS 'aws_iam_role=arn:aws:iam::260586643565:role/dilab-redshift-role'
REGION 'eu-central-1'
FORMAT AS CSV GZIP
DATEFORMAT AS 'MM-DD-YYYY'
IGNOREHEADER 1;

-- COPY 2
COPY lineorder_2
(
  lo_orderkey,
  lo_linenumber,
  lo_custkey,
  lo_partkey,
  lo_suppkey,
  lo_orderdate,
  lo_orderpriority,
  lo_shippriority,
  lo_quantity,
  lo_extendedprice,
  lo_ordertotalprice,
  lo_discount,
  lo_revenue,
  lo_supplycost,
  lo_tax,
  lo_commitdate,
  lo_shipmode
)
FROM 's3://s3labbucket/files/lineorders/'
CREDENTIALS 'aws_iam_role=arn:aws:iam::260586643565:role/dilab-redshift-role'
REGION 'eu-central-1'
FORMAT AS PARQUET;




-- Creating Glue DB 'dilab_student54' and making an external schema bound to it
CREATE EXTERNAL SCHEMA IF NOT EXISTS user_dilab_student54_ext
FROM DATA CATALOG
DATABASE 'dilab_student54'
IAM_ROLE 'arn:aws:iam::260586643565:role/dilab-redshift-role'
CREATE EXTERNAL DATABASE IF NOT EXISTS;


-- Turn off result cache for consistency
SET enable_result_cache_for_session TO OFF;

UNLOAD ('
  SELECT
    date_trunc(''month'', d.date_act) AS month_start,
    s.date_id,
    s.customer_id,
    s.product_id,
    s.channel_id,
    s.quantity_act,
    s.amount_act,
    s.cost_act,
    s.gross_income_act,
    s.discount_act
  FROM user_dilab_student54.fct_sales s
  JOIN user_dilab_student54.dim_dates d ON d.date_id = s.date_id
  WHERE d.date_act BETWEEN DATE ''2024-01-01'' AND DATE ''2024-12-31''
')
TO 's3://aws-giorgi-mujirishvili-hw1/spectrum/fct_sales_monthly/'
IAM_ROLE 'arn:aws:iam::260586643565:role/dilab-redshift-role'
FORMAT AS PARQUET
PARTITION BY (month_start)            
ALLOWOVERWRITE;


DROP TABLE IF EXISTS user_dilab_student54_ext.ext_fct_sales_monthly;

CREATE EXTERNAL TABLE user_dilab_student54_ext.ext_fct_sales_monthly (
  date_id          INT,
  customer_id      BIGINT,
  product_id       BIGINT,
  channel_id       BIGINT,
  quantity_act     INT,
  amount_act       DECIMAL(14,2),
  cost_act         DECIMAL(14,2),
  gross_income_act DECIMAL(14,2),
  discount_act     DECIMAL(14,2)
)
PARTITIONED BY (month_start DATE)
STORED AS PARQUET
LOCATION 's3://aws-giorgi-mujirishvili-hw1/spectrum/fct_sales_monthly/';


-- Produces one ALTER TABLE per month; copy the "ddl" column and execute it
WITH months AS (
  SELECT dateadd('month', i, DATE '2024-01-01') AS m
  FROM (SELECT 0 i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL
        SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL
        SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11) t
)
SELECT
  'ALTER TABLE user_dilab_student54_ext.ext_fct_sales_monthly ' ||
  'ADD IF NOT EXISTS PARTITION (month_start = DATE ' ||
  quote_literal(to_char(date_trunc('month', m),'YYYY-MM-01')) || ') LOCATION ' ||
  quote_literal(
    's3://aws-giorgi-mujirishvili-hw1/spectrum/fct_sales_monthly/month_start=' ||
    to_char(date_trunc('month', m),'YYYY-MM-01') || '/'
  ) || ';' AS ddl
FROM months;
