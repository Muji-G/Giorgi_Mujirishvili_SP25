ALTER TABLE bl_dm.dim_employees
    ADD CONSTRAINT uq_dim_employees_employee_src_id UNIQUE (employee_src_id);

ALTER TABLE bl_dm.dim_customers
    ADD CONSTRAINT uq_dim_customers_customer_src_id UNIQUE (customer_src_id);

ALTER TABLE bl_dm.dim_branches
    ADD CONSTRAINT uq_dim_branches_branch_src_id UNIQUE (branch_src_id);

ALTER TABLE bl_dm.dim_channels
    ADD CONSTRAINT uq_dim_channels_channel_src_id UNIQUE (channel_src_id);

ALTER TABLE bl_dm.dim_products
    ADD CONSTRAINT uq_dim_products_product_src_id UNIQUE (product_src_id);

--CE_CUSTOMERS
--FUNCTION
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tp_customer_row' AND typnamespace = 'bl_cl'::regnamespace) THEN
        CREATE TYPE bl_cl.tp_customer_row AS (
            customer_src_id VARCHAR(30),
            customer_name   VARCHAR(100),
            segment_name    VARCHAR(50),
            city_name       VARCHAR(50),
            region_name     VARCHAR(50),
            country_name    VARCHAR(50),
            source_system   VARCHAR(100),
            source_entity   VARCHAR(100)
        );
    END IF;
END;
$$;

-- Function selecting new customers from ce_customers.  Joins to
-- addresses to provide city/region/country.  Filters out records
-- already present in dim_customers based on customer_src_id.
CREATE OR REPLACE FUNCTION bl_cl.fn_get_new_dim_customers()
RETURNS SETOF bl_cl.tp_customer_row
LANGUAGE sql
AS $$
    SELECT
        c.customer_src_id,
        c.customer_name,
        c.segment_name,
        a.city_name,
        a.region_name,
        a.country_name,
        c.source_system,
        c.source_entity
    FROM bl_3nf.ce_customers c
    JOIN bl_3nf.ce_addresses a ON c.address_id = a.address_id
    LEFT JOIN bl_dm.dim_customers d ON d.customer_src_id = c.customer_src_id
    WHERE d.customer_src_id IS NULL;
$$;

-- Procedure to load customers.  Uses dynamic upsert.  Surrogate keys
-- generated via seq_dim_customers.
CREATE OR REPLACE PROCEDURE bl_cl.pr_load_dim_customers()
LANGUAGE plpgsql
AS $$
DECLARE
    cust_row bl_cl.tp_customer_row;
    cur      REFCURSOR;
    v_rows   INTEGER := 0;
BEGIN
    OPEN cur FOR SELECT * FROM bl_cl.fn_get_new_dim_customers();
    LOOP
        FETCH cur INTO cust_row;
        EXIT WHEN NOT FOUND;
        EXECUTE format(
            'INSERT INTO bl_dm.dim_customers (
                 customer_id, customer_src_id, customer_name, segment_name,
                 city_name, region_name, country_name,
                 ta_insert_dt, ta_update_dt, source_system, source_entity
             ) VALUES (
                 nextval(''bl_dm.seq_dim_customers''), $1, $2, $3, $4, $5, $6,
                 CURRENT_DATE, CURRENT_DATE, $7, $8
             )
             ON CONFLICT (customer_src_id) DO UPDATE
             SET customer_name = EXCLUDED.customer_name,
                 segment_name  = EXCLUDED.segment_name,
                 city_name     = EXCLUDED.city_name,
                 region_name   = EXCLUDED.region_name,
                 country_name  = EXCLUDED.country_name,
                 ta_update_dt  = CURRENT_DATE,
                 source_system = EXCLUDED.source_system,
                 source_entity = EXCLUDED.source_entity'
        ) USING cust_row.customer_src_id, cust_row.customer_name, cust_row.segment_name,
              cust_row.city_name, cust_row.region_name, cust_row.country_name,
              cust_row.source_system, cust_row.source_entity;
        v_rows := v_rows + 1;
    END LOOP;
    CLOSE cur;
    CALL bl_cl.pr_log_etl_event('pr_load_dim_customers', v_rows,
        CASE WHEN v_rows > 0 THEN 'Loaded/updated ' || v_rows || ' customers.' ELSE 'No new customers.' END);
END;
$$;

SELECT * FROM bl_cl.fn_get_new_dim_customers();
CALL bl_cl.pr_load_dim_customers();
CALL bl_cl.pr_load_dim_customers();
SELECT customer_src_id, COUNT(*) FROM bl_dm.dim_customers GROUP BY customer_src_id HAVING COUNT(*) > 1;


--DM_EMPLOYEES
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_type
        WHERE typname = 'tp_employee_row'
          AND typnamespace = 'bl_cl'::regnamespace
    ) THEN
        CREATE TYPE bl_cl.tp_employee_row AS (
            employee_src_id VARCHAR(30),
            employee_name   VARCHAR(100),
            role_name       VARCHAR(100),
            hire_dt         DATE,
            city_name       VARCHAR(50),
            region_name     VARCHAR(50),
            country_name    VARCHAR(50),
            source_system   VARCHAR(100),
            source_entity   VARCHAR(100)
        );
    END IF;
END;
$$;

-- Create or replace the function that fetches new employee rows
CREATE OR REPLACE FUNCTION bl_cl.fn_get_new_dim_employees()
RETURNS SETOF bl_cl.tp_employee_row
LANGUAGE sql
AS $$
    SELECT
        e.employee_src_id,
        e.employee_name,
        e.role_name,
        COALESCE(e.hire_dt, DATE '1990-01-01') AS hire_dt,
        a.city_name,
        a.region_name,
        a.country_name,
        e.source_system,
        e.source_entity
    FROM bl_3nf.ce_employees e
    JOIN bl_3nf.ce_addresses a ON e.address_id = a.address_id
    LEFT JOIN bl_dm.dim_employees d ON d.employee_src_id = e.employee_src_id
    WHERE d.employee_src_id IS NULL;
$$;
-- Procedure to load employees.  Uses dynamic SQL to insert/upsert and
-- generates surrogate keys via seq_dim_employees.
CREATE OR REPLACE PROCEDURE bl_cl.pr_load_dim_employees()
LANGUAGE plpgsql
AS $$
DECLARE
    emp_row bl_cl.tp_employee_row;
    cur     REFCURSOR;
    v_rows  INTEGER := 0;
BEGIN
    OPEN cur FOR SELECT * FROM bl_cl.fn_get_new_dim_employees();
    LOOP
        FETCH cur INTO emp_row;
        EXIT WHEN NOT FOUND;
        EXECUTE format(
            'INSERT INTO bl_dm.dim_employees (
                 employee_id, employee_src_id, employee_name, role_name, hire_dt,
                 city_name, region_name, country_name,
                 ta_insert_dt, ta_update_dt, source_system, source_entity
             ) VALUES (
                 nextval(''bl_dm.seq_dim_employees''), $1, $2, $3, $4,
                 $5, $6, $7, CURRENT_DATE, CURRENT_DATE, $8, $9
             )
             ON CONFLICT (employee_src_id) DO UPDATE
             SET employee_name = EXCLUDED.employee_name,
                 role_name     = EXCLUDED.role_name,
                 hire_dt       = EXCLUDED.hire_dt,
                 city_name     = EXCLUDED.city_name,
                 region_name   = EXCLUDED.region_name,
                 country_name  = EXCLUDED.country_name,
                 ta_update_dt  = CURRENT_DATE,
                 source_system = EXCLUDED.source_system,
                 source_entity = EXCLUDED.source_entity'
        ) USING emp_row.employee_src_id, emp_row.employee_name, emp_row.role_name,
              emp_row.hire_dt, emp_row.city_name, emp_row.region_name, emp_row.country_name,
              emp_row.source_system, emp_row.source_entity;
        v_rows := v_rows + 1;
    END LOOP;
    CLOSE cur;
    CALL bl_cl.pr_log_etl_event('pr_load_dim_employees', v_rows,
        CASE WHEN v_rows > 0 THEN 'Loaded/updated ' || v_rows || ' employees.' ELSE 'No new employees.' END);
END;
$$;

SELECT * FROM bl_cl.fn_get_new_dim_employees();
CALL bl_cl.pr_load_dim_employees();
CALL bl_cl.pr_load_dim_employees();
SELECT employee_src_id, COUNT(*) FROM bl_dm.dim_employees GROUP BY employee_src_id HAVING COUNT(*) > 1;
SELECT * FROM bl_dm.dim_employees de 
ORDER BY de.employee_src_id desc

--DM_BRANCHES
--FUNCTION

-- Composite type for branches.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tp_branch_row' AND typnamespace = 'bl_cl'::regnamespace) THEN
        CREATE TYPE bl_cl.tp_branch_row AS (
            branch_src_id  VARCHAR(30),
            city_name      VARCHAR(50),
            region_name    VARCHAR(50),
            country_name   VARCHAR(50),
            source_system  VARCHAR(100),
            source_entity  VARCHAR(100)
        );
    END IF;
END;
$$;

-- Function returning new branches.  Joins ce_branches to ce_addresses.
CREATE OR REPLACE FUNCTION bl_cl.fn_get_new_dim_branches()
RETURNS SETOF bl_cl.tp_branch_row
LANGUAGE sql
AS $$
    SELECT
        b.branch_src_id,
        a.city_name,
        a.region_name,
        a.country_name,
        b.source_system,
        b.source_entity
    FROM bl_3nf.ce_branches b
    JOIN bl_3nf.ce_addresses a ON b.address_id = a.address_id
    LEFT JOIN bl_dm.dim_branches d ON d.branch_src_id = b.branch_src_id :: VARCHAR(100)
    WHERE d.branch_src_id IS NULL;
$$;

-- Procedure to load branches.  Uses dynamic upsert.
CREATE OR REPLACE PROCEDURE bl_cl.pr_load_dim_branches()
LANGUAGE plpgsql
AS $$
DECLARE
    br_row bl_cl.tp_branch_row;
    cur    REFCURSOR;
    v_rows INTEGER := 0;
BEGIN
    OPEN cur FOR SELECT * FROM bl_cl.fn_get_new_dim_branches();
    LOOP
        FETCH cur INTO br_row;
        EXIT WHEN NOT FOUND;
        EXECUTE format(
            'INSERT INTO bl_dm.dim_branches (
                 branch_id, branch_src_id, city_name, region_name, country_name,
                 ta_insert_dt, ta_update_dt, source_system, source_entity
             ) VALUES (
                 nextval(''bl_dm.seq_dim_branches''), $1, $2, $3, $4, CURRENT_DATE, CURRENT_DATE, $5, $6
             )
             ON CONFLICT (branch_src_id) DO UPDATE
             SET city_name    = EXCLUDED.city_name,
                 region_name  = EXCLUDED.region_name,
                 country_name = EXCLUDED.country_name,
                 ta_update_dt = CURRENT_DATE,
                 source_system = EXCLUDED.source_system,
                 source_entity = EXCLUDED.source_entity'
        ) USING br_row.branch_src_id, br_row.city_name, br_row.region_name,
              br_row.country_name, br_row.source_system, br_row.source_entity;
        v_rows := v_rows + 1;
    END LOOP;
    CLOSE cur;
    CALL bl_cl.pr_log_etl_event('pr_load_dim_branches', v_rows,
        CASE WHEN v_rows > 0 THEN 'Loaded/updated ' || v_rows || ' branches.' ELSE 'No new branches.' END);
END;
$$;


SELECT * FROM bl_cl.fn_get_new_dim_branches();
CALL bl_cl.pr_load_dim_branches();
CALL bl_cl.pr_load_dim_branches();
SELECT branch_src_id, COUNT(*) FROM bl_dm.dim_branches GROUP BY branch_src_id HAVING COUNT(*) > 1;
SELECT * FROM bl_dm.dim_branches db 
ORDER BY branch_id DESC

--DIM_CHANNELS
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tp_channel_row' AND typnamespace = 'bl_cl'::regnamespace) THEN
        CREATE TYPE bl_cl.tp_channel_row AS (
            channel_src_id VARCHAR(30),
            channel_name   VARCHAR(100),
            source_system  VARCHAR(100),
            source_entity  VARCHAR(100)
        );
    END IF;
END;
$$;

-- Function returning new channels.
CREATE OR REPLACE FUNCTION bl_cl.fn_get_new_dim_channels()
RETURNS SETOF bl_cl.tp_channel_row
LANGUAGE sql
AS $$
    SELECT
        c.channel_src_id,
        c.channel_name,
        c.source_system,
        c.source_entity
    FROM bl_3nf.ce_channels c
    LEFT JOIN bl_dm.dim_channels d ON d.channel_src_id = c.channel_src_id :: VARCHAR(100)
    WHERE d.channel_src_id IS NULL;
$$;

-- Procedure to load channels with dynamic upsert.
CREATE OR REPLACE PROCEDURE bl_cl.pr_load_dim_channels()
LANGUAGE plpgsql
AS $$
DECLARE
    ch_row bl_cl.tp_channel_row;
    cur    REFCURSOR;
    v_rows INTEGER := 0;
BEGIN
    OPEN cur FOR SELECT * FROM bl_cl.fn_get_new_dim_channels();
    LOOP
        FETCH cur INTO ch_row;
        EXIT WHEN NOT FOUND;
        EXECUTE format(
            'INSERT INTO bl_dm.dim_channels (
                 channel_id, channel_src_id, channel_name,
                 ta_insert_dt, ta_update_dt, source_system, source_entity
             ) VALUES (
                 nextval(''bl_dm.seq_dim_channels''), $1, $2,
                 CURRENT_DATE, CURRENT_DATE, $3, $4
             )
             ON CONFLICT (channel_src_id) DO UPDATE
             SET channel_name  = EXCLUDED.channel_name,
                 ta_update_dt  = CURRENT_DATE,
                 source_system = EXCLUDED.source_system,
                 source_entity = EXCLUDED.source_entity'
        ) USING ch_row.channel_src_id, ch_row.channel_name, ch_row.source_system, ch_row.source_entity;
        v_rows := v_rows + 1;
    END LOOP;
    CLOSE cur;
    CALL bl_cl.pr_log_etl_event('pr_load_dim_channels', v_rows,
        CASE WHEN v_rows > 0 THEN 'Loaded/updated ' || v_rows || ' channels.' ELSE 'No new channels.' END);
END;
$$;


SELECT * FROM bl_cl.fn_get_new_dim_channels();
CALL bl_cl.pr_load_dim_channels();
CALL bl_cl.pr_load_dim_channels();
SELECT channel_src_id, COUNT(*) FROM bl_dm.dim_channels GROUP BY channel_src_id HAVING COUNT(*) > 1;


--DIM_PRODUCTS
--FUNCTION
-- Composite type for product rows.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tp_product_row' AND typnamespace = 'bl_cl'::regnamespace) THEN
        CREATE TYPE bl_cl.tp_product_row AS (
            product_src_id VARCHAR(30),
            product_name   VARCHAR(100),
            category_name  VARCHAR(50),
            loss_rate_act  FLOAT,
            source_system  VARCHAR(100),
            source_entity  VARCHAR(100)
        );
    END IF;
END;
$$;

-- Function returning new products from 3NF.  Joins to subcategories and
-- categories to derive category_name.
CREATE OR REPLACE FUNCTION bl_cl.fn_get_new_dim_products()
RETURNS SETOF bl_cl.tp_product_row
LANGUAGE sql
AS $$
    SELECT
        p.product_src_id,
        p.product_name,
        c.category_name,
        p.loss_rate_act,
        p.source_system,
        p.source_entity
    FROM bl_3nf.ce_products p
    JOIN bl_3nf.ce_product_subcategories s ON p.subcategory_id = s.subcategory_id
    JOIN bl_3nf.ce_product_categories   c ON s.category_id    = c.category_id
    LEFT JOIN bl_dm.dim_products d ON d.product_src_id = p.product_src_id
    WHERE d.product_src_id IS NULL;
$$;

-- Procedure to load products.  Uses dynamic upsert and sequence.
CREATE OR REPLACE PROCEDURE bl_cl.pr_load_dim_products()
LANGUAGE plpgsql
AS $$
DECLARE
    prod_row bl_cl.tp_product_row;
    cur      REFCURSOR;
    v_rows   INTEGER := 0;
BEGIN
    OPEN cur FOR SELECT * FROM bl_cl.fn_get_new_dim_products();
    LOOP
        FETCH cur INTO prod_row;
        EXIT WHEN NOT FOUND;
        EXECUTE format(
            'INSERT INTO bl_dm.dim_products (
                 product_id, product_src_id, product_name, category_name, loss_rate_act,
                 ta_insert_dt, ta_update_dt, source_system, source_entity
             ) VALUES (
                 nextval(''bl_dm.seq_dim_products''), $1, $2, $3, $4,
                 CURRENT_DATE, CURRENT_DATE, $5, $6
             )
             ON CONFLICT (product_src_id) DO UPDATE
             SET product_name  = EXCLUDED.product_name,
                 category_name = EXCLUDED.category_name,
                 loss_rate_act = EXCLUDED.loss_rate_act,
                 ta_update_dt  = CURRENT_DATE,
                 source_system = EXCLUDED.source_system,
                 source_entity = EXCLUDED.source_entity'
        ) USING prod_row.product_src_id, prod_row.product_name,
              prod_row.category_name, prod_row.loss_rate_act,
              prod_row.source_system, prod_row.source_entity;
        v_rows := v_rows + 1;
    END LOOP;
    CLOSE cur;
    CALL bl_cl.pr_log_etl_event('pr_load_dim_products', v_rows,
        CASE WHEN v_rows > 0 THEN 'Loaded/updated ' || v_rows || ' products.' ELSE 'No new products.' END);
END;
$$;

SELECT * FROM bl_cl.fn_get_new_dim_products();
CALL bl_cl.pr_load_dim_products();
CALL bl_cl.pr_load_dim_products();
SELECT product_src_id, COUNT(*) FROM bl_dm.dim_products GROUP BY product_src_id HAVING COUNT(*) > 1;

-- Composite type for product price rows.  It includes product_src_id and
-- derived price amounts for both unit and fact prices.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tp_product_price_row' AND typnamespace = 'bl_cl'::regnamespace) THEN
        CREATE TYPE bl_cl.tp_product_price_row AS (
            product_src_id   VARCHAR(30),
            price_unit_act   FLOAT,
            price_fact_act   FLOAT,
            start_dt         DATE,
            end_dt           DATE,
            is_active        VARCHAR(1),
            source_system    VARCHAR(100),
            source_entity    VARCHAR(100)
        );
    END IF;
END;
$$;

-- Function returning all price records from 3NF with their product_src_id.
-- 1. Redefine fn_get_all_dim_product_prices() to eliminate duplicates
CREATE OR REPLACE FUNCTION bl_cl.fn_get_all_dim_product_prices()
RETURNS SETOF bl_cl.tp_product_price_row
LANGUAGE sql
AS $$
    SELECT DISTINCT ON (pr.product_src_id, pp.start_dt)
        pr.product_src_id,
        pp.price_amt_act AS price_unit_act,
        pp.price_amt_act AS price_fact_act,
        pp.start_dt,
        pp.end_dt,
        -- Normalise is_active: treat 'true','t','y','1' as 'Y'; everything else as 'N'
        CASE
            WHEN lower(pp.is_active::text) IN ('true','t','y','1') THEN 'Y'
            WHEN lower(pp.is_active::text) IN ('false','f','n','0') THEN 'N'
            ELSE COALESCE(pp.is_active::text, 'N')
        END AS is_active,
        pp.source_system,
        pp.source_entity
    FROM bl_3nf.ce_product_prices_scd pp
    JOIN bl_3nf.ce_products pr ON pp.product_id = pr.product_id
    ORDER BY pr.product_src_id, pp.start_dt;
$$;
-- 2. Update pr_load_dim_product_prices() to skip exact duplicates

CREATE OR REPLACE PROCEDURE bl_cl.pr_load_dim_product_prices()
LANGUAGE plpgsql
AS $$
DECLARE
    rec     bl_cl.tp_product_price_row;
    cur     REFCURSOR;
    v_rows  INTEGER := 0;
    v_active RECORD;
    v_same   RECORD;
    new_is_active BOOLEAN;
BEGIN
    OPEN cur FOR SELECT * FROM bl_cl.fn_get_all_dim_product_prices() ORDER BY product_src_id, start_dt;
    LOOP
        FETCH cur INTO rec;
        EXIT WHEN NOT FOUND;
        -- determine boolean value from rec.is_active (text) using case-insensitive match
        new_is_active := CASE
            WHEN lower(rec.is_active::text) IN ('true','t','y','1') THEN TRUE
            WHEN lower(rec.is_active::text) IN ('false','f','n','0') THEN FALSE
            ELSE FALSE
        END;

        -- skip if an identical record already exists in dim_product_prices_scd
        SELECT price_id INTO v_same
        FROM bl_dm.dim_product_prices_scd
        WHERE product_src_id   = rec.product_src_id
          AND price_unit_act   = rec.price_unit_act
          AND price_fact_act   = rec.price_fact_act
          AND start_dt         = rec.start_dt
          AND end_dt           = rec.end_dt
          AND is_active        = new_is_active;

        IF v_same IS NOT NULL THEN
            CONTINUE;  -- identical record exists; skip this one
        END IF;

        -- find the current active record for this product
        SELECT * INTO v_active
        FROM bl_dm.dim_product_prices_scd
        WHERE product_src_id = rec.product_src_id AND is_active = TRUE
        LIMIT 1;

        IF v_active IS NULL THEN
            -- no active record; insert new one
            INSERT INTO bl_dm.dim_product_prices_scd (
                price_id, product_src_id, price_unit_act, price_fact_act,
                start_dt, end_dt, is_active, ta_insert_dt, ta_update_dt,
                source_system, source_entity
            ) VALUES (
                nextval('bl_dm.seq_dim_product_prices_scd'),
                rec.product_src_id, rec.price_unit_act, rec.price_fact_act,
                rec.start_dt, rec.end_dt, new_is_active,
                CURRENT_DATE, CURRENT_DATE,
                rec.source_system, rec.source_entity
            );
            v_rows := v_rows + 1;
        ELSE
            -- check if the active record differs from the new one
            IF v_active.price_unit_act <> rec.price_unit_act
               OR v_active.start_dt <> rec.start_dt
               OR v_active.end_dt   <> rec.end_dt
               OR v_active.price_fact_act <> rec.price_fact_act
               OR v_active.is_active <> new_is_active THEN
                -- close the active record
                UPDATE bl_dm.dim_product_prices_scd
                SET end_dt       = rec.start_dt - INTERVAL '1 day',
                    is_active    = FALSE,
                    ta_update_dt = CURRENT_DATE
                WHERE price_id = v_active.price_id;
                -- insert the new version
                INSERT INTO bl_dm.dim_product_prices_scd (
                    price_id, product_src_id, price_unit_act, price_fact_act,
                    start_dt, end_dt, is_active, ta_insert_dt, ta_update_dt,
                    source_system, source_entity
                ) VALUES (
                    nextval('bl_dm.seq_dim_product_prices_scd'),
                    rec.product_src_id, rec.price_unit_act, rec.price_fact_act,
                    rec.start_dt, rec.end_dt, new_is_active,
                    CURRENT_DATE, CURRENT_DATE,
                    rec.source_system, rec.source_entity
                );
                v_rows := v_rows + 1;
            END IF;
        END IF;
    END LOOP;
    CLOSE cur;
    CALL bl_cl.pr_log_etl_event('pr_load_dim_product_prices', v_rows,
        CASE WHEN v_rows > 0 THEN 'Processed ' || v_rows || ' price version(s).' ELSE 'No price changes.' END);
END;
$$;

SELECT * FROM bl_cl.fn_get_all_dim_product_prices()
CALL bl_cl.pr_load_dim_product_prices();
CALL bl_cl.pr_load_dim_product_prices();
-- Verify that only one active record per product_src_id exists
SELECT product_src_id, COUNT(*) FROM bl_dm.dim_product_prices_scd WHERE is_active = 'Y' GROUP BY product_src_id HAVING COUNT(*) > 1;
-- Examine versions for a product
SELECT * FROM bl_dm.dim_product_prices_scd WHERE product_src_id = '<PRODUCT_SRC_ID>' ORDER BY start_dt;

select * from bl_dm.dim_product_prices_scd dpps 

-- lookup the product_id for ITM001
SELECT product_id FROM bl_3nf.ce_products WHERE product_src_id = 'ITM001';

-- insert a new price row for this product with a new start date
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
) VALUES (
    1,                       
    'Standard',
    120.00,
    DATE '2025-08-15',
    DATE '9999-12-31',
    'Y',                    
    CURRENT_DATE,
    CURRENT_DATE,
    'MERGED',
    'SRC_ONLINE_AND_OFFLINE'
);

CALL bl_cl.pr_load_dim_product_prices();

SELECT
    product_src_id,
    price_unit_act,
    start_dt,
    end_dt,
    is_active
FROM bl_dm.dim_product_prices_scd
WHERE product_src_id = 'ITM001'
ORDER BY start_dt;
