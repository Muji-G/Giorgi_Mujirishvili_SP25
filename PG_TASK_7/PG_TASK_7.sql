CREATE OR REPLACE PROCEDURE BL_3NF.create_all_tables()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Create Sequences
    CREATE SEQUENCE IF NOT EXISTS BL_3NF.seq_address_id;
    CREATE SEQUENCE IF NOT EXISTS BL_3NF.seq_customer_id;
    CREATE SEQUENCE IF NOT EXISTS BL_3NF.seq_employee_id;
    CREATE SEQUENCE IF NOT EXISTS BL_3NF.seq_branch_id;
    CREATE SEQUENCE IF NOT EXISTS BL_3NF.seq_channel_id;
    CREATE SEQUENCE IF NOT EXISTS BL_3NF.seq_date_id;
    CREATE SEQUENCE IF NOT EXISTS BL_3NF.seq_category_id;
    CREATE SEQUENCE IF NOT EXISTS BL_3NF.seq_subcategory_id;
    CREATE SEQUENCE IF NOT EXISTS BL_3NF.seq_product_id;
    CREATE SEQUENCE IF NOT EXISTS BL_3NF.seq_price_id;

    -- Create Tables
    CREATE TABLE IF NOT EXISTS BL_3NF.CE_ADDRESSES (
        ADDRESS_ID      BIGINT PRIMARY KEY DEFAULT nextval('BL_3NF.seq_address_id'),
        ADDRESS_LINE    VARCHAR(100),
        CITY_NAME       VARCHAR(50),
        REGION_NAME     VARCHAR(50),
        POSTAL_CODE     VARCHAR(20),
        COUNTRY_NAME    VARCHAR(50),
        INSERT_DT       DATE,
        UPDATE_DT       DATE,
        SOURCE_SYSTEM   VARCHAR(100),
        SOURCE_ENTITY   VARCHAR(100)
    );

    CREATE TABLE IF NOT EXISTS BL_3NF.CE_BRANCHES (
        BRANCH_ID        BIGINT PRIMARY KEY DEFAULT nextval('BL_3NF.seq_branch_id'),
        BRANCH_SRC_ID    VARCHAR(20) NOT NULL,
        BRANCH_NAME      VARCHAR(100),
        ADDRESS_ID       BIGINT NOT NULL,
        INSERT_DT        DATE,
        UPDATE_DT        DATE,
        SOURCE_SYSTEM    VARCHAR(100),
        SOURCE_ENTITY    VARCHAR(100),
        FOREIGN KEY (ADDRESS_ID) REFERENCES BL_3NF.CE_ADDRESSES(ADDRESS_ID)
    );

    CREATE TABLE IF NOT EXISTS BL_3NF.CE_CHANNELS (
        CHANNEL_ID       BIGINT PRIMARY KEY DEFAULT nextval('BL_3NF.seq_channel_id'),
        CHANNEL_SRC_ID   VARCHAR(20) NOT NULL,
        CHANNEL_NAME     VARCHAR(255),
        INSERT_DT        DATE,
        UPDATE_DT        DATE,
        SOURCE_SYSTEM    VARCHAR(100),
        SOURCE_ENTITY    VARCHAR(100)
    );

    CREATE TABLE IF NOT EXISTS BL_3NF.CE_CUSTOMERS (
        CUSTOMER_ID      BIGINT PRIMARY KEY DEFAULT nextval('BL_3NF.seq_customer_id'),
        CUSTOMER_SRC_ID  VARCHAR(20) NOT NULL,
        CUSTOMER_NAME    VARCHAR(100),
        SEGMENT_NAME     VARCHAR(50),
        ADDRESS_ID       BIGINT NOT NULL,
        INSERT_DT        DATE,
        UPDATE_DT        DATE,
        SOURCE_SYSTEM    VARCHAR(100),
        SOURCE_ENTITY    VARCHAR(100),
        FOREIGN KEY (ADDRESS_ID) REFERENCES BL_3NF.CE_ADDRESSES(ADDRESS_ID)
    );

    CREATE TABLE IF NOT EXISTS BL_3NF.CE_EMPLOYEES (
        EMPLOYEE_ID      BIGINT PRIMARY KEY DEFAULT nextval('BL_3NF.seq_employee_id'),
        EMPLOYEE_SRC_ID  VARCHAR(20) NOT NULL,
        EMPLOYEE_NAME    VARCHAR(100),
        ROLE_NAME        VARCHAR(50),
        HIRE_DT          DATE,
        ADDRESS_ID       BIGINT NOT NULL,
        INSERT_DT        DATE,
        UPDATE_DT        DATE,
        SOURCE_SYSTEM    VARCHAR(100),
        SOURCE_ENTITY    VARCHAR(100),
        FOREIGN KEY (ADDRESS_ID) REFERENCES BL_3NF.CE_ADDRESSES(ADDRESS_ID)
    );

    CREATE TABLE IF NOT EXISTS BL_3NF.CE_TIME_DAY (
        DATE_ID         BIGINT PRIMARY KEY DEFAULT nextval('BL_3NF.seq_date_id'),
        DATE_SRC_ID     DATE NOT NULL,
        YEAR_NO         INT,
        MONTH_NO        INT,
        DAY_NO          INT,
        WEEKDAY_NAME    VARCHAR(20),
        INSERT_DT       DATE,
        UPDATE_DT       DATE,
        SOURCE_SYSTEM   VARCHAR(100),
        SOURCE_ENTITY   VARCHAR(100)
    );

    CREATE TABLE IF NOT EXISTS BL_3NF.CE_PRODUCT_CATEGORIES (
        CATEGORY_ID       BIGINT PRIMARY KEY DEFAULT nextval('BL_3NF.seq_category_id'),
        CATEGORY_SRC_ID   VARCHAR(20) NOT NULL,
        CATEGORY_NAME     VARCHAR(100),
        INSERT_DT         DATE,
        UPDATE_DT         DATE,
        SOURCE_SYSTEM     VARCHAR(100),
        SOURCE_ENTITY     VARCHAR(100)
    );

    CREATE TABLE IF NOT EXISTS BL_3NF.CE_PRODUCT_SUBCATEGORIES (
        SUBCATEGORY_ID        BIGINT PRIMARY KEY DEFAULT nextval('BL_3NF.seq_subcategory_id'),
        SUBCATEGORY_SRC_ID    VARCHAR(20) NOT NULL,
        SUBCATEGORY_NAME      VARCHAR(100),
        CATEGORY_ID           BIGINT NOT NULL,
        INSERT_DT             DATE,
        UPDATE_DT             DATE,
        SOURCE_SYSTEM         VARCHAR(100),
        SOURCE_ENTITY         VARCHAR(100),
        FOREIGN KEY (CATEGORY_ID) REFERENCES BL_3NF.CE_PRODUCT_CATEGORIES(CATEGORY_ID)
    );

    CREATE TABLE IF NOT EXISTS BL_3NF.CE_PRODUCTS (
        PRODUCT_ID            BIGINT PRIMARY KEY DEFAULT nextval('BL_3NF.seq_product_id'),
        PRODUCT_SRC_ID        VARCHAR(30) NOT NULL,
        PRODUCT_NAME          VARCHAR(100),
        SUBCATEGORY_ID        BIGINT NOT NULL,
        LOSS_RATE_ACT         FLOAT,
        INSERT_DT             DATE,
        UPDATE_DT             DATE,
        SOURCE_SYSTEM         VARCHAR(100),
        SOURCE_ENTITY         VARCHAR(100),
        FOREIGN KEY (SUBCATEGORY_ID) REFERENCES BL_3NF.CE_PRODUCT_SUBCATEGORIES(SUBCATEGORY_ID)
    );

    CREATE TABLE IF NOT EXISTS BL_3NF.CE_PRODUCT_PRICES_SCD (
        PRICE_ID         BIGINT PRIMARY KEY DEFAULT nextval('BL_3NF.seq_price_id'),
        PRODUCT_ID       BIGINT NOT NULL,
        PRICE_TYPE_NAME  VARCHAR(50),
        PRICE_AMT_ACT    FLOAT,
        START_DT         DATE,
        END_DT           DATE,
        IS_ACTIVE        VARCHAR(1),
        INSERT_DT        DATE,
        UPDATE_DT        DATE,
        SOURCE_SYSTEM    VARCHAR(100),
        SOURCE_ENTITY    VARCHAR(100),
        FOREIGN KEY (PRODUCT_ID) REFERENCES BL_3NF.CE_PRODUCTS(PRODUCT_ID)
    );

    CREATE TABLE IF NOT EXISTS BL_3NF.CE_SALES (
        DATE_ID          BIGINT NOT NULL,
        CUSTOMER_ID      BIGINT NOT NULL,
        EMPLOYEE_ID      BIGINT NOT NULL,
        BRANCH_ID        BIGINT NOT NULL,
        CHANNEL_ID       BIGINT NOT NULL,
        PRODUCT_ID       BIGINT NOT NULL,
        PRICE_ID         BIGINT NOT NULL,
        QUANTITY_NO      INT,
        UNIT_PRICE_ACT   FLOAT,
        DISCOUNT_ACT     FLOAT,
        AMOUNT_TOT_ACT   FLOAT,
        COST_ACT         FLOAT,
        GROSS_INCOME_ACT FLOAT,
        FOREIGN KEY (DATE_ID) REFERENCES BL_3NF.CE_TIME_DAY(DATE_ID),
        FOREIGN KEY (CUSTOMER_ID) REFERENCES BL_3NF.CE_CUSTOMERS(CUSTOMER_ID),
        FOREIGN KEY (EMPLOYEE_ID) REFERENCES BL_3NF.CE_EMPLOYEES(EMPLOYEE_ID),
        FOREIGN KEY (BRANCH_ID) REFERENCES BL_3NF.CE_BRANCHES(BRANCH_ID),
        FOREIGN KEY (CHANNEL_ID) REFERENCES BL_3NF.CE_CHANNELS(CHANNEL_ID),
        FOREIGN KEY (PRODUCT_ID) REFERENCES BL_3NF.CE_PRODUCTS(PRODUCT_ID),
        FOREIGN KEY (PRICE_ID) REFERENCES BL_3NF.CE_PRODUCT_PRICES_SCD(PRICE_ID)
    );
END;
$$;

CREATE OR REPLACE PROCEDURE BL_3NF.drop_all_objects()
LANGUAGE plpgsql
AS $$
BEGIN
    DROP TABLE IF EXISTS BL_3NF.CE_SALES CASCADE;
    DROP TABLE IF EXISTS BL_3NF.CE_PRODUCT_PRICES_SCD CASCADE;
    DROP TABLE IF EXISTS BL_3NF.CE_PRODUCTS CASCADE;
    DROP TABLE IF EXISTS BL_3NF.CE_PRODUCT_SUBCATEGORIES CASCADE;
    DROP TABLE IF EXISTS BL_3NF.CE_PRODUCT_CATEGORIES CASCADE;
    DROP TABLE IF EXISTS BL_3NF.CE_TIME_DAY CASCADE;
    DROP TABLE IF EXISTS BL_3NF.CE_EMPLOYEES CASCADE;
    DROP TABLE IF EXISTS BL_3NF.CE_CUSTOMERS CASCADE;
    DROP TABLE IF EXISTS BL_3NF.CE_CHANNELS CASCADE;
    DROP TABLE IF EXISTS BL_3NF.CE_BRANCHES CASCADE;
    DROP TABLE IF EXISTS BL_3NF.CE_ADDRESSES CASCADE;

    DROP SEQUENCE IF EXISTS BL_3NF.seq_address_id CASCADE;
    DROP SEQUENCE IF EXISTS BL_3NF.seq_customer_id CASCADE;
    DROP SEQUENCE IF EXISTS BL_3NF.seq_employee_id CASCADE;
    DROP SEQUENCE IF EXISTS BL_3NF.seq_branch_id CASCADE;
    DROP SEQUENCE IF EXISTS BL_3NF.seq_channel_id CASCADE;
    DROP SEQUENCE IF EXISTS BL_3NF.seq_date_id CASCADE;
    DROP SEQUENCE IF EXISTS BL_3NF.seq_category_id CASCADE;
    DROP SEQUENCE IF EXISTS BL_3NF.seq_subcategory_id CASCADE;
    DROP SEQUENCE IF EXISTS BL_3NF.seq_product_id CASCADE;
    DROP SEQUENCE IF EXISTS BL_3NF.seq_price_id CASCADE;

    RAISE NOTICE 'All BL_3NF objects dropped.';
END;
$$;

CALL BL_3NF.drop_all_objects();

CALL BL_3NF.create_all_tables();

-- creating schema and log table, as well as log procedure activity
CREATE SCHEMA IF NOT EXISTS BL_CL;
-- granting priviledges
BEGIN;

-- BL_DM schema and its tables
GRANT USAGE ON SCHEMA BL_DM TO postgres;
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA BL_DM TO postgres;

-- BL_3NF sequences and tables
GRANT USAGE ON ALL SEQUENCES IN SCHEMA BL_3NF TO postgres;
GRANT SELECT ON ALL TABLES IN SCHEMA BL_3NF TO postgres;

-- full privileges on BL_CL schema
GRANT ALL ON SCHEMA BL_CL TO postgres;
GRANT SELECT, INSERT ON bl_cl.load_log TO postgres;

-- BL_3NF tables
GRANT SELECT, INSERT ON bl_3nf.ce_addresses TO postgres;
GRANT SELECT, INSERT ON bl_3nf.ce_customers TO postgres;
GRANT SELECT, INSERT ON bl_3nf.ce_employees TO postgres;
GRANT SELECT, INSERT ON bl_3nf.ce_branches TO postgres;
GRANT SELECT, INSERT ON bl_3nf.ce_channels TO postgres;
GRANT SELECT, INSERT ON bl_3nf.ce_products TO postgres;
GRANT SELECT, INSERT ON bl_3nf.ce_product_categories TO postgres;
GRANT SELECT, INSERT ON bl_3nf.ce_product_subcategories TO postgres;
GRANT SELECT, INSERT ON bl_3nf.ce_product_prices_scd TO postgres;

COMMIT;

BEGIN;
CREATE SEQUENCE IF NOT EXISTS bl_cl.seq_load_log_id;
CREATE TABLE IF NOT EXISTS bl_cl.load_log (
    log_id           BIGINT PRIMARY KEY DEFAULT nextval('bl_cl.seq_load_log_id'),
    log_ts           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    procedure_name   TEXT NOT NULL,
    rows_affected    INTEGER NOT NULL,
    log_message      TEXT
);
COMMIT;

CREATE OR REPLACE PROCEDURE BL_CL.log_procedure_activity(
    p_procedure_name TEXT,
    p_rows_affected  INTEGER,
    p_log_message    TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO BL_CL.load_log(procedure_name, rows_affected, log_message)
    VALUES (p_procedure_name, p_rows_affected, p_log_message);
END;
$$;

--CE_TIMES_DAY
--FUNCTION
CREATE OR REPLACE FUNCTION bl_cl.fn_get_new_ce_time_day()
RETURNS TABLE (
    date_src_id     DATE,
    year_no         INT,
    month_no        INT,
    day_no          INT,
    weekday_name    VARCHAR,
    insert_dt       DATE,
    update_dt       DATE,
    source_system   TEXT,
    source_entity   TEXT
)
LANGUAGE SQL
AS $$
    WITH unified_dates AS (
        SELECT DISTINCT
            MAKE_DATE(CAST(year AS INT), CAST(month AS INT), CAST(day AS INT)) AS date_src_id,
            year::INT AS year_no,
            month::INT AS month_no,
            day::INT AS day_no,
            TO_CHAR(MAKE_DATE(year::INT, month::INT, day::INT), 'Day') AS weekday_name,
            CURRENT_DATE AS insert_dt,
            CURRENT_DATE AS update_dt,
            'Offline' AS source_system,
            'SRC_OFFLINE_ORDERS' AS source_entity
        FROM sa_offline.src_offline_orders
        WHERE year IS NOT NULL AND month IS NOT NULL AND day IS NOT NULL

        UNION

        SELECT DISTINCT
            MAKE_DATE(CAST(year AS INT), CAST(month AS INT), CAST(day AS INT)),
            year::INT,
            month::INT,
            day::INT,
            TO_CHAR(MAKE_DATE(year::INT, month::INT, day::INT), 'Day'),
            CURRENT_DATE,
            CURRENT_DATE,
            'Online',
            'SRC_ONLINE_ORDERS'
        FROM sa_online.src_online_orders
        WHERE year IS NOT NULL AND month IS NOT NULL AND day IS NOT NULL
    )
    SELECT *
    FROM unified_dates
    WHERE date_src_id NOT IN (
        SELECT date_src_id FROM bl_3nf.ce_time_day
    );
$$;

--PROCEDURE
CREATE OR REPLACE PROCEDURE bl_cl.sp_load_ce_time_day()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_inserted INTEGER := 0;
    v_row_count     INTEGER := 0;
    v_rec           RECORD;
BEGIN
    FOR v_rec IN SELECT * FROM bl_cl.fn_get_new_ce_time_day() LOOP
        BEGIN
            INSERT INTO bl_3nf.ce_time_day (
                date_src_id,
                year_no,
                month_no,
                day_no,
                weekday_name,
                insert_dt,
                update_dt,
                source_system,
                source_entity
            )
            VALUES (
                v_rec.date_src_id,
                v_rec.year_no,
                v_rec.month_no,
                v_rec.day_no,
                TRIM(v_rec.weekday_name),
                v_rec.insert_dt,
                v_rec.update_dt,
                v_rec.source_system,
                v_rec.source_entity
            );

            GET DIAGNOSTICS v_row_count = ROW_COUNT;
            v_rows_inserted := v_rows_inserted + v_row_count;

        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Skipping date %: %', v_rec.date_src_id, SQLERRM;
        END;
    END LOOP;

    CALL bl_cl.log_procedure_activity(
        'sp_load_ce_time_day',
        v_rows_inserted,
        CASE 
            WHEN v_rows_inserted > 0 THEN 'Inserted new CE_TIME_DAY rows.'
            ELSE 'No new CE_TIME_DAY rows to insert.'
        END
    );

EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.log_procedure_activity(
            'sp_load_ce_time_day',
            0,
            'Failed in sp_load_ce_time_day(): ' || SQLERRM
        );
        RAISE;
END;
$$;

-- 1. Preview new rows
SELECT * FROM bl_cl.fn_get_new_ce_time_day();

-- 2. Count of new date rows
SELECT COUNT(*) AS new_date_count FROM bl_cl.fn_get_new_ce_time_day();

-- 3. Run the procedure
CALL bl_cl.sp_load_ce_time_day();

-- 4. View loaded data
SELECT * FROM bl_3nf.ce_time_day ORDER BY date_id DESC;

-- 5. Log check
SELECT * FROM bl_cl.load_log
WHERE procedure_name = 'sp_load_ce_time_day'
ORDER BY log_ts DESC;

-- 6. Check for duplicates
SELECT date_src_id, source_system, source_entity, COUNT(*)
FROM bl_3nf.ce_time_day
GROUP BY date_src_id, source_system, source_entity
HAVING COUNT(*) > 1;

--CE_ADDRESSES
--FUNCTION
CREATE OR REPLACE FUNCTION bl_cl.fn_get_new_ce_addresses()
RETURNS TABLE (
    address_line    TEXT,
    city_name       TEXT,
    region_name     TEXT,
    postal_code     TEXT,
    country_name    TEXT,
    insert_dt       DATE,
    update_dt       DATE,
    source_system   TEXT,
    source_entity   TEXT
)
LANGUAGE sql
AS $$
    WITH unified_source AS (
        SELECT DISTINCT
            TRIM(branch) AS address_line,
            TRIM(city) AS city_name,
            'UNKNOWN' AS region_name,
            'UNKNOWN' AS postal_code,
            'UNKNOWN' AS country_name,
            CURRENT_DATE AS insert_dt,
            CURRENT_DATE AS update_dt,
            'Online' AS source_system,
            'SRC_ONLINE_ORDERS' AS source_entity
        FROM sa_online.src_online_orders
        WHERE branch IS NOT NULL AND city IS NOT NULL

        UNION

        SELECT DISTINCT
            TRIM(branch),
            TRIM(city),
            'UNKNOWN',
            'UNKNOWN',
            'UNKNOWN',
            CURRENT_DATE,
            CURRENT_DATE,
            'Offline',
            'SRC_OFFLINE_ORDERS'
        FROM sa_offline.src_offline_orders
        WHERE branch IS NOT NULL AND city IS NOT NULL
    )
    SELECT *
    FROM unified_source
    WHERE (address_line, city_name, source_system, source_entity) NOT IN (
        SELECT address_line, city_name, source_system, source_entity
        FROM bl_3nf.ce_addresses
    );
$$;


--PROCEDURE
CREATE OR REPLACE PROCEDURE bl_cl.load_ce_addresses()
LANGUAGE plpgsql
AS $$
DECLARE
    v_address_line    TEXT;
    v_city_name       TEXT;
    v_region_name     TEXT;
    v_postal_code     TEXT;
    v_country_name    TEXT;
    v_insert_dt       DATE;
    v_update_dt       DATE;
    v_source_system   TEXT;
    v_source_entity   TEXT;

    inserted_count    INTEGER := 0;

    cur CURSOR FOR SELECT * FROM bl_cl.fn_get_new_ce_addresses();
BEGIN
    OPEN cur;
    LOOP
        FETCH cur INTO
            v_address_line, v_city_name, v_region_name,
            v_postal_code, v_country_name,
            v_insert_dt, v_update_dt,
            v_source_system, v_source_entity;
        EXIT WHEN NOT FOUND;

        EXECUTE $sql$
            INSERT INTO bl_3nf.ce_addresses (
                address_line, city_name, region_name,
                postal_code, country_name,
                insert_dt, update_dt,
                source_system, source_entity
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        $sql$
        USING
            v_address_line, v_city_name, v_region_name,
            v_postal_code, v_country_name,
            v_insert_dt, v_update_dt,
            v_source_system, v_source_entity;

        inserted_count := inserted_count + 1;
    END LOOP;
    CLOSE cur;

    INSERT INTO bl_cl.load_log (
        procedure_name, rows_affected, log_message
    )
    VALUES (
        'bl_cl.load_ce_addresses', inserted_count, 'Inserted new CE_ADDRESSES rows'
    );

    INSERT INTO bl_cl.load_etl_executions (
        log_dt, procedure_name, rows_affected, log_message
    )
    VALUES (
        CURRENT_DATE, 'bl_cl.load_ce_addresses', inserted_count, 'Inserted new CE_ADDRESSES rows'
    );
END;
$$;

-- 1. Preview new address rows to be inserted
SELECT * 
FROM bl_cl.fn_get_new_ce_addresses();

-- 2. Count of new address rows
SELECT COUNT(*) AS new_address_count
FROM bl_cl.fn_get_new_ce_addresses();

-- 3. Execute the procedure to load new addresses
CALL bl_cl.sp_load_ce_addresses();

-- 4. View newly inserted addresses
SELECT * 
FROM bl_3nf.ce_addresses
ORDER BY address_id DESC;

-- 5. Check load log for CE_ADDRESSES load activity
SELECT * 
FROM bl_cl.load_log
WHERE procedure_name = 'sp_load_ce_addresses'
ORDER BY log_ts DESC;

-- 6. Check for duplicates based on business key
SELECT address_line, city_name, source_system, source_entity, COUNT(*) AS duplicate_count
FROM bl_3nf.ce_addresses
GROUP BY address_line, city_name, source_system, source_entity
HAVING COUNT(*) > 1;

-- 7. Check for NULL or invalid addresses (city or branch missing)
SELECT * 
FROM bl_3nf.ce_addresses
WHERE city_name IS NULL OR address_line IS NULL;


--CE_CUSTOMERS
--FUNCTION
CREATE OR REPLACE FUNCTION bl_cl.fn_get_new_ce_customers()
RETURNS TABLE (
    customer_src_id  VARCHAR,
    customer_name    VARCHAR,
    segment_name     VARCHAR,
    address_id       BIGINT,
    insert_dt        DATE,
    update_dt        DATE,
    source_system    TEXT,
    source_entity    TEXT
)
LANGUAGE SQL
AS $$
    WITH unified_source AS (
        SELECT DISTINCT
            TRIM(o.customer_id_1) AS customer_src_id,
            'UNKNOWN' AS customer_name,
            'UNKNOWN' AS segment_name,
            a.address_id,
            CURRENT_DATE AS insert_dt,
            CURRENT_DATE AS update_dt,
            'Online' AS source_system,
            'SRC_ONLINE_ORDERS' AS source_entity
        FROM sa_online.src_online_orders o
        JOIN bl_3nf.ce_addresses a
          ON TRIM(o.city) = a.city_name
         AND TRIM(o.branch) = a.address_line
         AND a.source_system = 'Online'
         AND a.source_entity = 'SRC_ONLINE_ORDERS'
        WHERE o.customer_id_1 IS NOT NULL

        UNION

        SELECT DISTINCT
            TRIM(o.customer_id) AS customer_src_id,
            'UNKNOWN',
            'UNKNOWN',
            a.address_id,
            CURRENT_DATE,
            CURRENT_DATE,
            'Offline',
            'SRC_OFFLINE_ORDERS'
        FROM sa_offline.src_offline_orders o
        JOIN bl_3nf.ce_addresses a
          ON TRIM(o.city) = a.city_name
         AND TRIM(o.branch) = a.address_line
         AND a.source_system = 'Offline'
         AND a.source_entity = 'SRC_OFFLINE_ORDERS'
        WHERE o.customer_id IS NOT NULL
    ),
    deduplicated AS (
        SELECT *,
               ROW_NUMBER() OVER (
                   PARTITION BY customer_src_id, source_system, source_entity
                   ORDER BY address_id
               ) AS rn
        FROM unified_source
    )
    SELECT
        customer_src_id,
        customer_name,
        segment_name,
        address_id,
        insert_dt,
        update_dt,
        source_system,
        source_entity
    FROM deduplicated
    WHERE rn = 1
      AND (customer_src_id, source_system, source_entity) NOT IN (
          SELECT customer_src_id, source_system, source_entity
          FROM bl_3nf.ce_customers
      );
$$;

--PROCEDURE
CREATE OR REPLACE PROCEDURE bl_cl.sp_load_ce_customers()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rec RECORD;
    v_row_count INT := 0;
    v_rows_inserted INT := 0;
BEGIN
    FOR v_rec IN SELECT * FROM bl_cl.fn_get_new_ce_customers() LOOP
        BEGIN
            INSERT INTO bl_3nf.ce_customers (
                customer_src_id,
                customer_name,
                segment_name,
                address_id,
                insert_dt,
                update_dt,
                source_system,
                source_entity
            )
            VALUES (
                v_rec.customer_src_id,
                v_rec.customer_name,
                v_rec.segment_name,
                v_rec.address_id,
                v_rec.insert_dt,
                v_rec.update_dt,
                v_rec.source_system,
                v_rec.source_entity
            );

            GET DIAGNOSTICS v_row_count = ROW_COUNT;
            v_rows_inserted := v_rows_inserted + v_row_count;

        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Skipping error for customer %: %', v_rec.customer_src_id, SQLERRM;
        END;
    END LOOP;

    CALL bl_cl.log_procedure_activity(
        'sp_load_ce_customers',
        v_rows_inserted,
        CASE 
            WHEN v_rows_inserted > 0 THEN 'Inserted new CE_CUSTOMERS rows.'
            ELSE 'No new CE_CUSTOMERS rows to insert.'
        END
    );

EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.log_procedure_activity(
            'sp_load_ce_customers',
            0,
            'Failed in sp_load_ce_customers(): ' || SQLERRM
        );
        RAISE;
END;
$$;


-- 1. Preview new customer rows
SELECT * FROM bl_cl.fn_get_new_ce_customers();

-- 2. Count new customer rows
SELECT COUNT(*) FROM bl_cl.fn_get_new_ce_customers();

-- 3. Execute procedure to insert new customers
CALL bl_cl.sp_load_ce_customers();

-- 4. View newly inserted customers
SELECT * FROM bl_3nf.ce_customers ORDER BY customer_id DESC;

-- 5. Check log for procedure activity
SELECT * FROM bl_cl.load_log
WHERE procedure_name = 'sp_load_ce_customers'
ORDER BY log_ts DESC;

-- 6. Check for duplicates (business key)
SELECT customer_src_id, source_system, source_entity, COUNT(*) AS duplicate_count
FROM bl_3nf.ce_customers
GROUP BY customer_src_id, source_system, source_entity
HAVING COUNT(*) > 1;

-- 7. Check for invalid address_id references
SELECT c.*
FROM bl_3nf.ce_customers c
LEFT JOIN bl_3nf.ce_addresses a ON c.address_id = a.address_id
WHERE a.address_id IS NULL;


--CE_EMPLOYEES
--FUNCTION
CREATE OR REPLACE FUNCTION bl_cl.get_new_employees()
RETURNS TABLE (
    employee_src_id  TEXT,
    employee_name    VARCHAR,
    role_name        VARCHAR,
    hire_dt          DATE,
    address_id       BIGINT,
    insert_dt        DATE,
    update_dt        DATE,
    source_system    VARCHAR,
    source_entity    VARCHAR
)
LANGUAGE SQL
AS $$
    WITH unified_source AS (
        SELECT DISTINCT
            TRIM(o.employee_id) AS employee_src_id,
            TRIM(o.employee_id) AS employee_name,
            'UNKNOWN' AS role_name,
            NULL::DATE AS hire_dt,
            a.address_id,
            CURRENT_DATE AS insert_dt,
            CURRENT_DATE AS update_dt,
            'Online' AS source_system,
            'SRC_ONLINE_ORDERS' AS source_entity
        FROM sa_online.src_online_orders o
        JOIN bl_3nf.ce_addresses a 
          ON TRIM(o.branch) = a.address_line
         AND TRIM(o.city) = a.city_name
         AND a.source_system = 'Online'
         AND a.source_entity = 'SRC_ONLINE_ORDERS'
        WHERE o.employee_id IS NOT NULL AND TRIM(o.employee_id) <> ''

        UNION

        SELECT DISTINCT
            TRIM(o.employee_id),
            TRIM(o.employee_id),
            'UNKNOWN',
            NULL::DATE,
            a.address_id,
            CURRENT_DATE,
            CURRENT_DATE,
            'Offline',
            'SRC_OFFLINE_ORDERS'
        FROM sa_offline.src_offline_orders o
        JOIN bl_3nf.ce_addresses a 
          ON TRIM(o.branch) = a.address_line
         AND TRIM(o.city) = a.city_name
         AND a.source_system = 'Offline'
         AND a.source_entity = 'SRC_OFFLINE_ORDERS'
        WHERE o.employee_id IS NOT NULL AND TRIM(o.employee_id) <> ''
    ),
    deduplicated AS (
        SELECT *, ROW_NUMBER() OVER (
            PARTITION BY employee_src_id, source_system, source_entity
            ORDER BY address_id
        ) AS rn
        FROM unified_source
    )
    SELECT
        employee_src_id, employee_name, role_name, hire_dt,
        address_id, insert_dt, update_dt, source_system, source_entity
    FROM deduplicated
    WHERE rn = 1
      AND (employee_src_id, source_system, source_entity) NOT IN (
            SELECT employee_src_id, source_system, source_entity
            FROM bl_3nf.ce_employees
      );
$$;


--PROCEDURE
CREATE OR REPLACE PROCEDURE bl_cl.load_employees()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rec RECORD;
    v_row_count INT := 0;
    v_rows_inserted INT := 0;
BEGIN
    FOR v_rec IN SELECT * FROM bl_cl.get_new_employees() LOOP
        BEGIN
            INSERT INTO bl_3nf.ce_employees (
                employee_src_id,
                employee_name,
                role_name,
                hire_dt,
                address_id,
                insert_dt,
                update_dt,
                source_system,
                source_entity
            )
            VALUES (
                v_rec.employee_src_id,
                v_rec.employee_name,
                v_rec.role_name,
                v_rec.hire_dt,
                v_rec.address_id,
                v_rec.insert_dt,
                v_rec.update_dt,
                v_rec.source_system,
                v_rec.source_entity
            );

            GET DIAGNOSTICS v_row_count = ROW_COUNT;
            v_rows_inserted := v_rows_inserted + v_row_count;

        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Skipping employee %: %', v_rec.employee_src_id, SQLERRM;
        END;
    END LOOP;

    CALL bl_cl.log_procedure_activity(
        'load_employees',
        v_rows_inserted,
        CASE
            WHEN v_rows_inserted > 0 THEN 'Inserted new employee rows.'
            ELSE 'No new employees to insert.'
        END
    );

EXCEPTION WHEN OTHERS THEN
    CALL bl_cl.log_procedure_activity(
        'load_employees',
        0,
        'Failed in load_employees(): ' || SQLERRM
    );
    RAISE;
END;
$$;


-- 1. Preview new employee rows to be inserted
SELECT * 
FROM bl_cl.get_new_employees();

-- 2. Count of new employee rows
SELECT COUNT(*) AS new_employee_count
FROM bl_cl.get_new_employees();

-- 3. Execute the procedure to load new employees
CALL bl_cl.load_employees();

-- 4. View newly inserted employees
SELECT * 
FROM bl_3nf.ce_employees
ORDER BY employee_id DESC;

-- 5. Check load log for CE_EMPLOYEES load activity
SELECT * 
FROM bl_cl.load_log
WHERE procedure_name = 'load_employees'
ORDER BY log_ts DESC;

-- 6. Check for duplicates based on business key
SELECT employee_src_id, source_system, source_entity, COUNT(*) AS duplicate_count
FROM bl_3nf.ce_employees
GROUP BY employee_src_id, source_system, source_entity
HAVING COUNT(*) > 1;

-- 7. Check for invalid foreign key references to address_id
SELECT e.*
FROM bl_3nf.ce_employees e
LEFT JOIN bl_3nf.ce_addresses a ON e.address_id = a.address_id
WHERE a.address_id IS NULL;


--CE_BRANCHES
--FUNCTION
CREATE OR REPLACE FUNCTION bl_cl.fn_get_new_ce_branches()
RETURNS TABLE (
    branch_src_id   INT,
    branch_name     VARCHAR,
    address_id      BIGINT,
    insert_dt       DATE,
    update_dt       DATE,
    source_system   TEXT,
    source_entity   TEXT
)
LANGUAGE SQL
AS $$
    WITH unified_source AS (
        SELECT DISTINCT
            TRIM(branch) AS branch_name,
            TRIM(branch) AS address_line,
            TRIM(city)   AS city_name,
            'Offline'    AS source_system,
            'SRC_OFFLINE_ORDERS' AS source_entity
        FROM sa_offline.src_offline_orders
        WHERE branch IS NOT NULL AND city IS NOT NULL

        UNION

        SELECT DISTINCT
            TRIM(branch),
            TRIM(branch),
            TRIM(city),
            'Online',
            'SRC_ONLINE_ORDERS'
        FROM sa_online.src_online_orders
        WHERE branch IS NOT NULL AND city IS NOT NULL
    ),
    with_ids AS (
        SELECT
            ROW_NUMBER() OVER (
                ORDER BY branch_name, city_name, source_system, source_entity
            ) AS branch_src_id,
            *
        FROM unified_source
    )
    SELECT
        b.branch_src_id,
        b.branch_name,
        a.address_id,
        CURRENT_DATE,
        CURRENT_DATE,
        b.source_system,
        b.source_entity
    FROM with_ids b
    JOIN bl_3nf.ce_addresses a
      ON a.address_line = b.address_line
     AND a.city_name = b.city_name
     AND a.source_system = b.source_system
     AND a.source_entity = b.source_entity
    WHERE (b.branch_src_id, b.source_system, b.source_entity) NOT IN (
        SELECT branch_src_id, source_system, source_entity
        FROM bl_3nf.ce_branches
    );
$$;



--PROCEDURE
CREATE OR REPLACE PROCEDURE bl_cl.load_ce_branches()
LANGUAGE plpgsql
AS $$
DECLARE
    v_branch_src_id  INT;
    v_branch_name    VARCHAR;
    v_address_id     BIGINT;
    v_insert_dt      DATE;
    v_update_dt      DATE;
    v_source_system  TEXT;
    v_source_entity  TEXT;

    inserted_count   INTEGER := 0;

    cur CURSOR FOR SELECT * FROM bl_cl.fn_get_new_ce_branches();
BEGIN
    OPEN cur;
    LOOP
        FETCH cur INTO
            v_branch_src_id, v_branch_name, v_address_id,
            v_insert_dt, v_update_dt,
            v_source_system, v_source_entity;
        EXIT WHEN NOT FOUND;

        EXECUTE $SQL$
            INSERT INTO bl_3nf.ce_branches (
                branch_src_id, branch_name, address_id,
                insert_dt, update_dt,
                source_system, source_entity
            ) VALUES ($1, $2, $3, $4, $5, $6, $7)
        $SQL$
        USING
            v_branch_src_id, v_branch_name, v_address_id,
            v_insert_dt, v_update_dt,
            v_source_system, v_source_entity;

        inserted_count := inserted_count + 1;
    END LOOP;
    CLOSE cur;

    -- Log via centralized procedure
    CALL bl_cl.log_procedure_activity(
        'bl_cl.load_ce_branches',
        inserted_count,
        'Inserted new CE_BRANCHES rows'
    );
END;
$$;



-- 1. Preview new branch rows to be inserted
SELECT * FROM bl_cl.fn_get_new_ce_branches();

-- 2. Count how many new branches would be inserted
SELECT COUNT(*) AS new_branch_count
FROM bl_cl.fn_get_new_ce_branches();

-- 3. Run the loading procedure
CALL bl_cl.load_ce_branches();

-- 4. Check the most recently inserted branches
SELECT *
FROM bl_3nf.ce_branches
ORDER BY branch_id desc;

-- 5. Validate latest log entry in load_log
SELECT *
FROM bl_cl.load_log
WHERE procedure_name = 'bl_cl.load_ce_branches'
ORDER BY log_ts DESC;

-- 6. Check for duplicate BRANCH_SRC_ID per source
SELECT branch_src_id, source_system, source_entity, COUNT(*) AS cnt
FROM bl_3nf.ce_branches
GROUP BY branch_src_id, source_system, source_entity
HAVING COUNT(*) > 1;

-- 7. Ensure all branches have valid address_id references
SELECT b.branch_id, b.branch_name, b.address_id
FROM bl_3nf.ce_branches b
LEFT JOIN bl_3nf.ce_addresses a ON b.address_id = a.address_id
WHERE a.address_id IS NULL;

-- 8. Count rows by source system for sanity
SELECT source_system, COUNT(*) AS total_rows
FROM bl_3nf.ce_branches
GROUP BY source_system;

-- 9. Re-run the loader to ensure it is repeatable (should insert 0 rows)
CALL bl_cl.load_ce_branches();

-- 10. Confirm 0 rows inserted in last execution
SELECT *
FROM bl_cl.load_log
WHERE procedure_name = 'bl_cl.load_ce_branches'
ORDER BY log_ts DESC
LIMIT 1;

    
 

--CE_CHANNELS
--FUNCTION
CREATE OR REPLACE FUNCTION bl_cl.fn_get_new_ce_channels()
RETURNS TABLE (
    channel_src_id   INT,
    channel_name     VARCHAR,
    insert_dt        DATE,
    update_dt        DATE,
    source_system    TEXT,
    source_entity    TEXT
)
LANGUAGE SQL
AS $$
    WITH unified_source AS (
        SELECT DISTINCT
            TRIM(source_system) AS channel_name,
            'Offline' AS source_system,
            'SRC_OFFLINE_ORDERS' AS source_entity
        FROM sa_offline.src_offline_orders
        WHERE source_system IS NOT NULL

        UNION

        SELECT DISTINCT
            TRIM(source_system),
            'Online',
            'SRC_ONLINE_ORDERS'
        FROM sa_online.src_online_orders
        WHERE source_system IS NOT NULL
    ),
    with_ids AS (
        SELECT
            ROW_NUMBER() OVER (
                ORDER BY channel_name, source_system, source_entity
            ) AS channel_src_id,
            channel_name,
            source_system,
            source_entity
        FROM unified_source
    )
    SELECT
        channel_src_id,
        channel_name,
        CURRENT_DATE AS insert_dt,
        CURRENT_DATE AS update_dt,
        source_system,
        source_entity
    FROM with_ids
    WHERE (channel_src_id, source_system, source_entity) NOT IN (
        SELECT channel_src_id, source_system, source_entity
        FROM bl_3nf.ce_channels
    );
$$;


--PROCEDURE
CREATE OR REPLACE PROCEDURE bl_cl.load_ce_channels()
LANGUAGE plpgsql
AS $$
DECLARE
    v_channel_src_id  INT;
    v_channel_name    VARCHAR;
    v_insert_dt       DATE;
    v_update_dt       DATE;
    v_source_system   TEXT;
    v_source_entity   TEXT;

    inserted_count    INTEGER := 0;

    cur CURSOR FOR SELECT * FROM bl_cl.fn_get_new_ce_channels();
BEGIN
    OPEN cur;
    LOOP
        FETCH cur INTO
            v_channel_src_id, v_channel_name,
            v_insert_dt, v_update_dt,
            v_source_system, v_source_entity;
        EXIT WHEN NOT FOUND;

        EXECUTE $SQL$
            INSERT INTO bl_3nf.ce_channels (
                channel_src_id, channel_name,
                insert_dt, update_dt,
                source_system, source_entity
            ) VALUES ($1, $2, $3, $4, $5, $6)
        $SQL$
        USING
            v_channel_src_id, v_channel_name,
            v_insert_dt, v_update_dt,
            v_source_system, v_source_entity;

        inserted_count := inserted_count + 1;
    END LOOP;
    CLOSE cur;

    -- Centralized logging
    CALL bl_cl.log_procedure_activity(
        'bl_cl.load_ce_channels',
        inserted_count,
        'Inserted new CE_CHANNELS rows'
    );
END;
$$;

-- 1. Preview new channel rows to be inserted
SELECT * 
FROM bl_cl.fn_get_new_ce_channels()

-- 2. Count of new channel rows
SELECT COUNT(*) AS new_channel_count
FROM bl_cl.fn_get_new_ce_channels()

-- 3. Execute the procedure to load new channels
CALL bl_cl.load_channels();

-- 4. View newly inserted channels
SELECT * 
FROM bl_3nf.ce_channels
ORDER BY channel_id DESC;

-- 5. Check load log for CE_CHANNELS load activity
SELECT * 
FROM bl_cl.load_log
WHERE procedure_name = 'load_channels'
ORDER BY log_ts DESC;

-- 6. Check for duplicates based on business key
SELECT channel_src_id, source_system, source_entity, COUNT(*) AS duplicate_count
FROM bl_3nf.ce_channels
GROUP BY channel_src_id, source_system, source_entity
HAVING COUNT(*) > 1;


--CE_PRODUCTS
--FUNCTION
CREATE OR REPLACE FUNCTION bl_cl.fn_get_new_ce_products()
RETURNS TABLE (
    product_src_id     VARCHAR,
    product_name       VARCHAR,
    subcategory_id     BIGINT,
    loss_rate_act      FLOAT,
    insert_dt          DATE,
    update_dt          DATE,
    source_system      TEXT,
    source_entity      TEXT
)
LANGUAGE SQL
AS $$
    WITH unified_source AS (
        SELECT DISTINCT
            TRIM(item_code) AS product_src_id,
            TRIM(item_name) AS product_name,
            sc.subcategory_id,
            CAST(loss_rate AS FLOAT) AS loss_rate_act,
            CURRENT_DATE AS insert_dt,
            CURRENT_DATE AS update_dt,
            'Online' AS source_system,
            'SRC_ONLINE_ORDERS' AS source_entity
        FROM sa_online.src_online_orders o
        JOIN bl_3nf.ce_product_subcategories sc
          ON TRIM(o.category_code) = sc.subcategory_src_id
         AND sc.source_system = 'Online'
         AND sc.source_entity = 'SRC_ONLINE_ORDERS'
        WHERE item_code IS NOT NULL AND TRIM(item_code) <> ''

        UNION

        SELECT DISTINCT
            TRIM(item_code),
            TRIM(item_code),  -- No name in offline source
            sc.subcategory_id,
            CAST(loss_rate AS FLOAT),
            CURRENT_DATE,
            CURRENT_DATE,
            'Offline',
            'SRC_OFFLINE_ORDERS'
        FROM sa_offline.src_offline_orders o
        JOIN bl_3nf.ce_product_subcategories sc
          ON TRIM(o.category_code) = sc.subcategory_src_id
         AND sc.source_system = 'Offline'
         AND sc.source_entity = 'SRC_OFFLINE_ORDERS'
        WHERE item_code IS NOT NULL AND TRIM(item_code) <> ''
    ),
    ranked_products AS (
        SELECT *,
               ROW_NUMBER() OVER (
                   PARTITION BY product_src_id, source_system, source_entity
                   ORDER BY subcategory_id
               ) AS rn
        FROM unified_source
    )
    SELECT
        product_src_id,
        product_name,
        subcategory_id,
        loss_rate_act,
        insert_dt,
        update_dt,
        source_system,
        source_entity
    FROM ranked_products
    WHERE rn = 1
      AND (product_src_id, source_system, source_entity) NOT IN (
          SELECT product_src_id, source_system, source_entity
          FROM bl_3nf.ce_products
      );
$$;


--PROCEDURE
CREATE OR REPLACE PROCEDURE bl_cl.sp_load_ce_products()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_inserted INTEGER := 0;
    v_row_count     INTEGER := 0;
    v_rec           RECORD;
BEGIN
    FOR v_rec IN SELECT * FROM bl_cl.fn_get_new_ce_products() LOOP
        BEGIN
            INSERT INTO bl_3nf.ce_products (
                product_src_id,
                product_name,
                subcategory_id,
                loss_rate_act,
                insert_dt,
                update_dt,
                source_system,
                source_entity
            )
            VALUES (
                v_rec.product_src_id,
                v_rec.product_name,
                v_rec.subcategory_id,
                v_rec.loss_rate_act,
                v_rec.insert_dt,
                v_rec.update_dt,
                v_rec.source_system,
                v_rec.source_entity
            );

            GET DIAGNOSTICS v_row_count = ROW_COUNT;
            v_rows_inserted := v_rows_inserted + v_row_count;

        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Skipping product %: %', v_rec.product_src_id, SQLERRM;
        END;
    END LOOP;

    CALL bl_cl.log_procedure_activity(
        'sp_load_ce_products',
        v_rows_inserted,
        CASE 
            WHEN v_rows_inserted > 0 THEN 'Inserted new products.'
            ELSE 'No new products to insert.'
        END
    );

EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.log_procedure_activity(
            'sp_load_ce_products',
            0,
            'Failed in sp_load_ce_products(): ' || SQLERRM
        );
        RAISE;
END;
$$;


-- 1. Preview new product rows to be inserted
SELECT * FROM bl_cl.fn_get_new_ce_products();

-- 2. Count of new product rows
SELECT COUNT(*) AS new_product_count
FROM bl_cl.fn_get_new_ce_products();

-- 3. Execute the procedure to load new products
CALL bl_cl.sp_load_ce_products();

-- 4. View newly inserted products
SELECT * FROM bl_3nf.ce_products
ORDER BY product_id DESC;

-- 5. Check load log for product load activity
SELECT * FROM bl_cl.load_log
WHERE procedure_name = 'sp_load_ce_products'
ORDER BY log_ts DESC;

-- 6. Check for duplicates based on business key
SELECT product_src_id, source_system, source_entity, COUNT(*) AS duplicate_count
FROM bl_3nf.ce_products
GROUP BY product_src_id, source_system, source_entity
HAVING COUNT(*) > 1;

-- 7. Check for invalid subcategory_id references
SELECT p.*
FROM bl_3nf.ce_products p
LEFT JOIN bl_3nf.ce_product_subcategories s ON p.subcategory_id = s.subcategory_id
WHERE s.subcategory_id IS NULL;


--CE_PRODUCT_CATEGORIES
--FUNCTION
CREATE OR REPLACE FUNCTION bl_cl.fn_get_new_ce_product_categories()
RETURNS TABLE (
    category_src_id VARCHAR,
    category_name   VARCHAR,
    insert_dt       DATE,
    update_dt       DATE,
    source_system   VARCHAR,
    source_entity   VARCHAR
)
LANGUAGE SQL
AS $$
    WITH unified_source AS (
        SELECT DISTINCT
            TRIM(category_code) AS category_src_id,
            TRIM(category_name) AS category_name,
            CURRENT_DATE        AS insert_dt,
            CURRENT_DATE        AS update_dt,
            'Online'            AS source_system,
            'SRC_ONLINE_ORDERS' AS source_entity
        FROM sa_online.src_online_orders
        WHERE category_code IS NOT NULL AND TRIM(category_code) <> ''

        UNION

        SELECT DISTINCT
            TRIM(category_code),
            'UNKNOWN', -- No category_name in offline
            CURRENT_DATE,
            CURRENT_DATE,
            'Offline',
            'SRC_OFFLINE_ORDERS'
        FROM sa_offline.src_offline_orders
        WHERE category_code IS NOT NULL AND TRIM(category_code) <> ''
    ),
    ranked_source AS (
        SELECT *,
               ROW_NUMBER() OVER (
                   PARTITION BY category_src_id, source_system, source_entity
                   ORDER BY category_name NULLS LAST
               ) AS rn
        FROM unified_source
    )
    SELECT
        category_src_id,
        category_name,
        insert_dt,
        update_dt,
        source_system,
        source_entity
    FROM ranked_source
    WHERE rn = 1
      AND (category_src_id, source_system, source_entity) NOT IN (
          SELECT category_src_id, source_system, source_entity
          FROM bl_3nf.ce_product_categories
      );
$$;

--PROCEDURE
CREATE OR REPLACE PROCEDURE bl_cl.sp_load_ce_product_categories()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_inserted INTEGER := 0;
    v_row_count     INTEGER := 0;
    v_rec           RECORD;
BEGIN
    FOR v_rec IN SELECT * FROM bl_cl.fn_get_new_ce_product_categories() LOOP
        BEGIN
            INSERT INTO bl_3nf.ce_product_categories (
                category_src_id,
                category_name,
                insert_dt,
                update_dt,
                source_system,
                source_entity
            )
            VALUES (
                v_rec.category_src_id,
                v_rec.category_name,
                v_rec.insert_dt,
                v_rec.update_dt,
                v_rec.source_system,
                v_rec.source_entity
            );

            GET DIAGNOSTICS v_row_count = ROW_COUNT;
            v_rows_inserted := v_rows_inserted + v_row_count;

        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Skipping category %: %', v_rec.category_src_id, SQLERRM;
        END;
    END LOOP;

    CALL bl_cl.log_procedure_activity(
        'sp_load_ce_product_categories',
        v_rows_inserted,
        CASE 
            WHEN v_rows_inserted > 0 THEN 'Inserted new category rows.'
            ELSE 'No new categories to insert.'
        END
    );

EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.log_procedure_activity(
            'sp_load_ce_product_categories',
            0,
            'Failed in sp_load_ce_product_categories(): ' || SQLERRM
        );
        RAISE;
END;
$$;

-- 1. Preview new category rows to be inserted
SELECT * FROM bl_cl.fn_get_new_ce_product_categories();

-- 2. Count of new category rows
SELECT COUNT(*) AS new_category_count
FROM bl_cl.fn_get_new_ce_product_categories();

-- 3. Execute the procedure to load new categories
CALL bl_cl.sp_load_ce_product_categories();

-- 4. View newly inserted categories
SELECT * 
FROM bl_3nf.ce_product_categories
ORDER BY category_id DESC;

-- 5. Check load log for category load activity
SELECT * 
FROM bl_cl.load_log
WHERE procedure_name = 'sp_load_ce_product_categories'
ORDER BY log_ts DESC;

-- 6. Check for duplicates based on business key
SELECT category_src_id, source_system, source_entity, COUNT(*) AS duplicate_count
FROM bl_3nf.ce_product_categories
GROUP BY category_src_id, source_system, source_entity
HAVING COUNT(*) > 1;

--CE_PRODUCT_SUBCATEGORIES
--FUNCTION
CREATE OR REPLACE FUNCTION bl_cl.fn_get_new_ce_product_subcategories()
RETURNS TABLE (
    subcategory_src_id VARCHAR,
    subcategory_name   VARCHAR,
    category_id        BIGINT,
    insert_dt          DATE,
    update_dt          DATE,
    source_system      TEXT,
    source_entity      TEXT
)
LANGUAGE SQL
AS $$
    WITH unified_source AS (
        SELECT DISTINCT
            TRIM(o.category_code) AS subcategory_src_id,
            TRIM(o.category_code) AS subcategory_name,
            c.category_id         AS category_id,
            CURRENT_DATE          AS insert_dt,
            CURRENT_DATE          AS update_dt,
            'Online'              AS source_system,
            'SRC_ONLINE_ORDERS'   AS source_entity
        FROM sa_online.src_online_orders o
        JOIN bl_3nf.ce_product_categories c
          ON TRIM(o.category_code) = c.category_src_id
         AND c.source_system = 'Online'

        UNION

        SELECT DISTINCT
            TRIM(o.category_code) AS subcategory_src_id,
            TRIM(o.category_code) AS subcategory_name,
            c.category_id         AS category_id,
            CURRENT_DATE          AS insert_dt,
            CURRENT_DATE          AS update_dt,
            'Offline'             AS source_system,
            'SRC_OFFLINE_ORDERS'  AS source_entity
        FROM sa_offline.src_offline_orders o
        JOIN bl_3nf.ce_product_categories c
          ON TRIM(o.category_code) = c.category_src_id
         AND c.source_system = 'Offline'
    ),
    ranked_rows AS (
        SELECT 
            subcategory_src_id,
            subcategory_name,
            category_id,
            insert_dt,
            update_dt,
            source_system,
            source_entity,
            ROW_NUMBER() OVER (
                PARTITION BY subcategory_src_id, source_system, source_entity
                ORDER BY category_id
            ) AS rn
        FROM unified_source
    )
    SELECT 
        subcategory_src_id,
        subcategory_name,
        category_id,
        insert_dt,
        update_dt,
        source_system,
        source_entity
    FROM ranked_rows
    WHERE rn = 1
      AND (subcategory_src_id, source_system, source_entity) NOT IN (
            SELECT subcategory_src_id, source_system, source_entity
            FROM bl_3nf.ce_product_subcategories
      );
$$;

--PROCEDURE
CREATE OR REPLACE PROCEDURE bl_cl.sp_load_ce_product_subcategories()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_inserted INTEGER := 0;
    v_row_count     INTEGER := 0;
    v_rec           RECORD;
BEGIN
    FOR v_rec IN SELECT * FROM bl_cl.fn_get_new_ce_product_subcategories() LOOP
        BEGIN
            INSERT INTO bl_3nf.ce_product_subcategories (
                subcategory_src_id,
                subcategory_name,
                category_id,
                insert_dt,
                update_dt,
                source_system,
                source_entity
            )
            VALUES (
                v_rec.subcategory_src_id,
                v_rec.subcategory_name,
                v_rec.category_id,
                v_rec.insert_dt,
                v_rec.update_dt,
                v_rec.source_system,
                v_rec.source_entity
            );

            GET DIAGNOSTICS v_row_count = ROW_COUNT;
            v_rows_inserted := v_rows_inserted + v_row_count;

        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Skipping subcategory %: %', v_rec.subcategory_src_id, SQLERRM;
        END;
    END LOOP;

    CALL bl_cl.log_procedure_activity(
        'sp_load_ce_product_subcategories',
        v_rows_inserted,
        CASE 
            WHEN v_rows_inserted > 0 THEN 'Inserted new subcategory rows.'
            ELSE 'No new subcategories to insert.'
        END
    );

EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.log_procedure_activity(
            'sp_load_ce_product_subcategories',
            0,
            'Failed in sp_load_ce_product_subcategories(): ' || SQLERRM
        );
        RAISE;
END;
$$;



-- 1. Preview new product subcategory rows to be inserted
SELECT * 
FROM bl_cl.fn_get_new_ce_product_subcategories();

-- 2. Count of new product subcategory rows
SELECT COUNT(*) AS new_subcategory_count
FROM bl_cl.fn_get_new_ce_product_subcategories();

-- 3. Execute the procedure to load new product subcategories
CALL bl_cl.sp_load_ce_product_subcategories();

-- 4. View newly inserted product subcategories
SELECT * 
FROM bl_3nf.ce_product_subcategories
ORDER BY subcategory_id DESC;

-- 5. Check load log for subcategory load activity
SELECT * 
FROM bl_cl.load_log
WHERE procedure_name = 'sp_load_ce_product_subcategories'
ORDER BY log_ts DESC;

-- 6. Check for duplicates based on business key
SELECT subcategory_src_id, source_system, source_entity, COUNT(*) AS duplicate_count
FROM bl_3nf.ce_product_subcategories
GROUP BY subcategory_src_id, source_system, source_entity
HAVING COUNT(*) > 1;

-- 7. Check for invalid foreign key references to category_id
SELECT s.*
FROM bl_3nf.ce_product_subcategories s
LEFT JOIN bl_3nf.ce_product_categories c ON s.category_id = c.category_id
WHERE c.category_id IS NULL;


--PRODUCT_PRICES_SCD
--FUNCTION
CREATE OR REPLACE FUNCTION bl_cl.fn_get_new_product_prices_scd()
RETURNS TABLE (
    product_id         BIGINT,
    price_amt_act      FLOAT,
    price_type_name    VARCHAR,
    start_dt           DATE,
    end_dt             DATE,
    is_active          VARCHAR(1),
    insert_dt          DATE,
    update_dt          DATE,
    source_system      VARCHAR,
    source_entity      VARCHAR
)
LANGUAGE SQL
AS $$
    WITH src_combined AS (
        SELECT DISTINCT item_code, unit_selling_price
        FROM (
            SELECT item_code, unit_selling_price
            FROM sa_offline.src_offline_orders
            WHERE item_code IS NOT NULL AND unit_selling_price IS NOT NULL AND unit_selling_price <> ''
            UNION
            SELECT item_code, unit_selling_price
            FROM sa_online.src_online_orders
            WHERE item_code IS NOT NULL AND unit_selling_price IS NOT NULL AND unit_selling_price <> ''
        ) AS merged
    ),
    mapped_prices AS (
        SELECT
            p.product_id,
            CAST(src.unit_selling_price AS FLOAT) AS price_amt_act,
            'Standard' AS price_type_name,
            CURRENT_DATE AS start_dt,
            DATE '9999-12-31' AS end_dt,
            'Y' AS is_active,
            CURRENT_DATE AS insert_dt,
            CURRENT_DATE AS update_dt,
            'MERGED' AS source_system,
            'SRC_ONLINE_AND_OFFLINE' AS source_entity
        FROM src_combined src
        JOIN bl_3nf.ce_products p ON p.product_src_id = src.item_code
    )
    SELECT *
    FROM mapped_prices mp
    WHERE NOT EXISTS (
        SELECT 1
        FROM bl_3nf.ce_product_prices_scd scd
        WHERE scd.product_id = mp.product_id
          AND scd.is_active = 'Y'
          AND scd.price_amt_act = mp.price_amt_act
    );
$$;



--PROCEDURE
CREATE OR REPLACE PROCEDURE bl_cl.load_product_prices_scd()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rec RECORD;
    v_row_count INT := 0;
    v_rows_inserted INT := 0;
BEGIN
    FOR v_rec IN SELECT * FROM bl_cl.fn_get_new_product_prices_scd()
    LOOP
        -- Step 1: Deactivate current active price (if exists)
        UPDATE bl_3nf.ce_product_prices_scd
        SET
            is_active = 'N',
            end_dt = CURRENT_DATE - 1,
            update_dt = CURRENT_DATE
        WHERE product_id = v_rec.product_id
          AND is_active = 'Y';

        -- Step 2: Insert new price record
        INSERT INTO bl_3nf.ce_product_prices_scd (
            product_id,
            price_type_name,
            price_amt_act,
            start_dt,
            end_dt,
            is_active,
            insert_dt,
            update_dt,
            source_system,
            source_entity
        )
        VALUES (
            v_rec.product_id,
            v_rec.price_type_name,
            v_rec.price_amt_act,
            v_rec.start_dt,
            v_rec.end_dt,
            v_rec.is_active,
            v_rec.insert_dt,
            v_rec.update_dt,
            v_rec.source_system,
            v_rec.source_entity
        );

        GET DIAGNOSTICS v_row_count = ROW_COUNT;
        v_rows_inserted := v_rows_inserted + v_row_count;
    END LOOP;

    CALL bl_cl.log_procedure_activity(
        'load_product_prices_scd',
        v_rows_inserted,
        CASE 
            WHEN v_rows_inserted > 0 THEN 'Inserted new SCD2 product prices.'
            ELSE 'No new product prices to insert.'
        END
    );

EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.log_procedure_activity(
            'load_product_prices_scd',
            0,
            'Failed in load_product_prices_scd(): ' || SQLERRM
        );
        RAISE;
END;
$$;



-- 1. Preview new product price rows to be inserted
SELECT * 
FROM bl_cl.get_new_product_prices_scd();

-- 2. Count of new product price rows
SELECT COUNT(*) AS new_product_price_count
FROM bl_cl.get_new_product_prices_scd();

-- 3. Execute the procedure to load new product price rows
CALL bl_cl.load_product_prices_scd();

-- 4. View newly inserted product prices
SELECT * 
FROM bl_3nf.ce_product_prices_scd
ORDER BY price_id DESC;

-- 5. Check load log for product prices SCD load activity
SELECT * 
FROM bl_cl.load_log
WHERE procedure_name = 'load_product_prices_scd'
ORDER BY log_ts DESC;

-- 6. Check for duplicates based on business key (product_id + price_amt_act)
SELECT product_id, price_amt_act, COUNT(*) AS duplicate_count
FROM bl_3nf.ce_product_prices_scd
GROUP BY product_id, price_amt_act
HAVING COUNT(*) > 1;

-- 7. Check for invalid foreign key references to product_id
SELECT pps.*
FROM bl_3nf.ce_product_prices_scd pps
LEFT JOIN bl_3nf.ce_products p ON pps.product_id = p.product_id
WHERE p.product_id IS NULL;

-- 8. Check that active rows have correct SCD flags
SELECT *
FROM bl_3nf.ce_product_prices_scd
WHERE is_active = 'Y'
and price_id = 1


UPDATE sa_online.src_online_orders
SET unit_selling_price = 55.00
WHERE item_code = 'ITM001';

SELECT * 
FROM bl_cl.fn_get_new_product_prices_scd()
WHERE product_id = 123;

SELECT product_id
FROM bl_3nf.ce_products
WHERE product_src_id = 'ITM001';
