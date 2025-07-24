--CE_CUSTOMERS
--FUNCTION
CREATE OR REPLACE FUNCTION bl_cl.get_new_dm_customers()
RETURNS TABLE (
    customer_src_id   VARCHAR,
    customer_name     VARCHAR,
    segment_name      VARCHAR,
    city_name         VARCHAR,
    region_name       VARCHAR,
    country_name      VARCHAR,
    ta_insert_dt      DATE,
    ta_update_dt      DATE,
    source_system     VARCHAR,
    source_entity     VARCHAR
)
LANGUAGE SQL
AS $$
    SELECT
        c.customer_src_id,
        c.customer_name,
        c.segment_name,
        a.city_name,
        a.region_name,
        a.country_name,
        CURRENT_DATE,
        CURRENT_DATE,
        c.source_system,
        c.source_entity
    FROM bl_3nf.ce_customers c
    JOIN bl_3nf.ce_addresses a
      ON c.address_id = a.address_id
    WHERE NOT EXISTS (
        SELECT 1
        FROM bl_dm.dim_customers d
        WHERE d.customer_src_id = c.customer_src_id
    )
$$;


--PROCEDURE
CREATE OR REPLACE PROCEDURE bl_cl.load_dm_customers()
LANGUAGE plpgsql
AS $$
DECLARE
    v_customer_src_id   VARCHAR;
    v_customer_name     VARCHAR;
    v_segment_name      VARCHAR;
    v_city_name         VARCHAR;
    v_region_name       VARCHAR;
    v_country_name      VARCHAR;
    v_ta_insert_dt      DATE;
    v_ta_update_dt      DATE;
    v_source_system     VARCHAR;
    v_source_entity     VARCHAR;
    v_row_count         INT := 0;
    v_rows_inserted     INT := 0;
BEGIN
    FOR v_customer_src_id, v_customer_name, v_segment_name,
        v_city_name, v_region_name, v_country_name,
        v_ta_insert_dt, v_ta_update_dt,
        v_source_system, v_source_entity
    IN SELECT * FROM bl_cl.get_new_dm_customers()
    LOOP
        BEGIN
            INSERT INTO bl_dm.dim_customers (
                customer_src_id,
                customer_name,
                segment_name,
                city_name,
                region_name,
                country_name,
                ta_insert_dt,
                ta_update_dt,
                source_system,
                source_entity
            )
            VALUES (
                v_customer_src_id,
                v_customer_name,
                v_segment_name,
                v_city_name,
                v_region_name,
                v_country_name,
                v_ta_insert_dt,
                v_ta_update_dt,
                v_source_system,
                v_source_entity
            );

            GET DIAGNOSTICS v_row_count = ROW_COUNT;
            v_rows_inserted := v_rows_inserted + v_row_count;

        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Skipping customer %: %', v_customer_src_id, SQLERRM;
        END;
    END LOOP;

    CALL bl_cl.log_procedure_activity(
        'load_dm_customers',
        v_rows_inserted,
        CASE
            WHEN v_rows_inserted > 0 THEN 'Inserted new customers records.'
            ELSE 'No new customers to insert.'
        END
    );

EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.log_procedure_activity(
            'load_dm_customers',
            0,
            'Failed in load_dm_customers(): ' || SQLERRM
        );
        RAISE;
END;
$$;

-- checking candidate rows
SELECT * FROM bl_cl.get_new_dm_customers();

-- executing the loader
CALL bl_cl.load_dm_customers();

-- checking log
SELECT * FROM bl_cl.load_log
WHERE procedure_name = 'load_dm_customers'
ORDER BY log_ts DESC;

--DM_EMPLOYEES
--FUNCTION
CREATE OR REPLACE FUNCTION bl_cl.get_new_dm_employees()
RETURNS TABLE (
    employee_src_id   VARCHAR,
    employee_name     VARCHAR,
    role_name         VARCHAR,
    hire_dt           DATE,
    city_name         VARCHAR,
    region_name       VARCHAR,
    country_name      VARCHAR,
    ta_insert_dt      DATE,
    ta_update_dt      DATE,
    source_system     VARCHAR,
    source_entity     VARCHAR
)
LANGUAGE SQL
AS $$
    SELECT
        e.employee_src_id,
        e.employee_name,
        e.role_name,
        e.hire_dt,
        a.city_name,
        a.region_name,
        a.country_name,
        CURRENT_DATE,
        CURRENT_DATE,
        e.source_system,
        e.source_entity
    FROM bl_3nf.ce_employees e
    JOIN bl_3nf.ce_addresses a
      ON e.address_id = a.address_id
    WHERE NOT EXISTS (
        SELECT 1
        FROM bl_dm.dim_employees d
        WHERE d.employee_src_id = e.employee_src_id
    )
$$;

--PROCEDURE
CREATE OR REPLACE PROCEDURE bl_cl.load_dm_employees()
LANGUAGE plpgsql
AS $$
DECLARE
    v_employee_src_id   VARCHAR;
    v_employee_name     VARCHAR;
    v_role_name         VARCHAR;
    v_hire_dt           DATE;
    v_city_name         VARCHAR;
    v_region_name       VARCHAR;
    v_country_name      VARCHAR;
    v_ta_insert_dt      DATE;
    v_ta_update_dt      DATE;
    v_source_system     VARCHAR;
    v_source_entity     VARCHAR;

    v_row_count         INT := 0;
    v_rows_inserted     INT := 0;
BEGIN
    FOR v_employee_src_id, v_employee_name, v_role_name,
        v_hire_dt, v_city_name, v_region_name, v_country_name,
        v_ta_insert_dt, v_ta_update_dt,
        v_source_system, v_source_entity
    IN SELECT * FROM bl_cl.get_new_dm_employees()
    LOOP
        BEGIN
            INSERT INTO bl_dm.dim_employees (
                employee_src_id,
                employee_name,
                role_name,
                hire_dt,
                city_name,
                region_name,
                country_name,
                ta_insert_dt,
                ta_update_dt,
                source_system,
                source_entity
            )
            VALUES (
                v_employee_src_id,
                v_employee_name,
                v_role_name,
                v_hire_dt,
                v_city_name,
                v_region_name,
                v_country_name,
                v_ta_insert_dt,
                v_ta_update_dt,
                v_source_system,
                v_source_entity
            );

            GET DIAGNOSTICS v_row_count = ROW_COUNT;
            v_rows_inserted := v_rows_inserted + v_row_count;

        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Skipping employee %: %', v_employee_src_id, SQLERRM;
        END;
    END LOOP;

    CALL bl_cl.log_procedure_activity(
        'load_dm_employees',
        v_rows_inserted,
        CASE
            WHEN v_rows_inserted > 0 THEN 'Inserted new employees records.'
            ELSE 'No new employees to insert.'
        END
    );

EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.log_procedure_activity(
            'load_dm_employees',
            0,
            'Failed in load_dm_employees(): ' || SQLERRM
        );
        RAISE;
END;
$$;


-- checking candidate rows
SELECT * FROM bl_cl.get_new_dm_employees()

-- executing the loader
CALL bl_cl.load_dm_employees();

-- checking log
SELECT * FROM bl_cl.load_log
WHERE procedure_name = 'load_dm_employees'
ORDER BY log_ts DESC;

SELECT COUNT(*) FROM bl_cl.get_new_dm_employees()


--DM_BRANCHES
--FUNCTION
CREATE OR REPLACE FUNCTION bl_cl.get_new_dm_branches()
RETURNS TABLE (
    branch_src_id   VARCHAR,
    branch_name     VARCHAR,
    city_name       VARCHAR,
    region_name     VARCHAR,
    country_name    VARCHAR,
    ta_insert_dt    DATE,
    ta_update_dt    DATE,
    source_system   VARCHAR,
    source_entity   VARCHAR
)
LANGUAGE SQL
AS $$
    SELECT
        b.branch_src_id,
        b.branch_name,
        a.city_name,
        a.region_name,
        a.country_name,
        CURRENT_DATE,
        CURRENT_DATE,
        b.source_system,
        b.source_entity
    FROM bl_3nf.ce_branches b
    JOIN bl_3nf.ce_addresses a
      ON b.address_id = a.address_id
    WHERE NOT EXISTS (
        SELECT 1
        FROM bl_dm.dim_branches d
        WHERE d.branch_src_id = b.branch_src_id
    )
$$;


--PROCEDURE
CREATE OR REPLACE PROCEDURE bl_cl.load_dm_branches()
LANGUAGE plpgsql
AS $$
DECLARE
    v_branch_src_id   VARCHAR;
    v_branch_name     VARCHAR;
    v_city_name       VARCHAR;
    v_region_name     VARCHAR;
    v_country_name    VARCHAR;
    v_ta_insert_dt    DATE;
    v_ta_update_dt    DATE;
    v_source_system   VARCHAR;
    v_source_entity   VARCHAR;
    v_row_count       INT := 0;
    v_rows_inserted   INT := 0;
BEGIN
    FOR v_branch_src_id, v_branch_name, v_city_name, v_region_name,
        v_country_name, v_ta_insert_dt, v_ta_update_dt,
        v_source_system, v_source_entity
    IN SELECT * FROM bl_cl.get_new_dm_branches()
    LOOP
        BEGIN
            INSERT INTO bl_dm.dim_branches (
                branch_src_id,
                branch_name,
                city_name,
                region_name,
                country_name,
                ta_insert_dt,
                ta_update_dt,
                source_system,
                source_entity
            )
            VALUES (
                v_branch_src_id,
                v_branch_name,
                v_city_name,
                v_region_name,
                v_country_name,
                v_ta_insert_dt,
                v_ta_update_dt,
                v_source_system,
                v_source_entity
            );

            GET DIAGNOSTICS v_row_count = ROW_COUNT;
            v_rows_inserted := v_rows_inserted + v_row_count;

        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Skipping branch %: %', v_branch_src_id, SQLERRM;
        END;
    END LOOP;

    CALL bl_cl.log_procedure_activity(
        'load_dm_branches',
        v_rows_inserted,
        CASE
            WHEN v_rows_inserted > 0 THEN 'Inserted new branches records.'
            ELSE 'No new branches to insert.'
        END
    );

EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.log_procedure_activity(
            'load_dm_branches',
            0,
            'Failed in load_dm_branches(): ' || SQLERRM
        );
        RAISE;
END;
$$;


SELECT * FROM bl_cl.get_new_dm_branches()

-- executing the loader
CALL bl_cl.load_dm_branches();

-- checking log
SELECT * FROM bl_cl.load_log
WHERE procedure_name = 'load_dm_branches'
ORDER BY log_ts DESC;

SELECT COUNT(*) FROM bl_cl.get_new_dm_branches()


--DIM_CHANNELS
--FUNCTION
CREATE OR REPLACE FUNCTION bl_cl.get_new_dm_channels()
RETURNS TABLE (
    channel_src_id   VARCHAR,
    channel_name     VARCHAR,
    ta_insert_dt     DATE,
    ta_update_dt     DATE,
    source_system    VARCHAR,
    source_entity    VARCHAR
)
LANGUAGE SQL
AS $$
    SELECT
        channel_src_id,
        channel_name,
        CURRENT_DATE,
        CURRENT_DATE,
        source_system,
        source_entity
    FROM bl_3nf.ce_channels
    WHERE NOT EXISTS (
        SELECT 1
        FROM bl_dm.dim_channels d
        WHERE d.channel_src_id = ce_channels.channel_src_id :: VARCHAR
    )
$$;


--PROCEDURE
CREATE OR REPLACE PROCEDURE bl_cl.load_dm_channels()
LANGUAGE plpgsql
AS $$
DECLARE
    v_channel_src_id   VARCHAR;
    v_channel_name     VARCHAR;
    v_ta_insert_dt     DATE;
    v_ta_update_dt     DATE;
    v_source_system    VARCHAR;
    v_source_entity    VARCHAR;
    v_row_count        INT := 0;
    v_rows_inserted    INT := 0;
BEGIN
    FOR v_channel_src_id, v_channel_name, v_ta_insert_dt, v_ta_update_dt,
        v_source_system, v_source_entity
    IN SELECT * FROM bl_cl.get_new_dm_channels()
    LOOP
        BEGIN
            INSERT INTO bl_dm.dim_channels (
                channel_src_id,
                channel_name,
                ta_insert_dt,
                ta_update_dt,
                source_system,
                source_entity
            )
            VALUES (
                v_channel_src_id,
                v_channel_name,
                v_ta_insert_dt,
                v_ta_update_dt,
                v_source_system,
                v_source_entity
            );

            GET DIAGNOSTICS v_row_count = ROW_COUNT;
            v_rows_inserted := v_rows_inserted + v_row_count;

        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Skipping channel %: %', v_channel_src_id, SQLERRM;
        END;
    END LOOP;

    CALL bl_cl.log_procedure_activity(
        'load_dm_channels',
        v_rows_inserted,
        CASE
            WHEN v_rows_inserted > 0 THEN 'Inserted new channels records.'
            ELSE 'No new channels to insert.'
        END
    );

EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.log_procedure_activity(
            'load_dm_channels',
            0,
            'Failed in load_dm_channels(): ' || SQLERRM
        );
        RAISE;
END;
$$;

SELECT * FROM bl_cl.get_new_dm_branches()


-- executing the loader
CALL bl_cl.load_dm_channels();

-- checking log
SELECT * FROM bl_cl.load_log
WHERE procedure_name = 'load_dm_channels'
ORDER BY log_ts DESC;

SELECT COUNT(*) FROM bl_cl.get_new_dm_channels()

SELECT
    c.channel_src_id,
    c.channel_name,
    c.source_system,
    c.source_entity,
    d.channel_id,
    d.ta_insert_dt
FROM bl_3nf.ce_channels c
JOIN bl_dm.dim_channels d
  ON d.channel_src_id = c.channel_src_id :: VARCHAR
ORDER BY d.channel_id;

DROP FUNCTION bl_cl.get_new_dm_products()
--DIM_PRODUCTS
--FUNCTION
CREATE OR REPLACE FUNCTION bl_cl.get_new_dm_products()
RETURNS TABLE (
    product_src_id     TEXT,
    product_name       TEXT,
    category_name      TEXT,
    loss_rate_pct      FLOAT,
    ta_insert_dt       DATE,
    ta_update_dt       DATE,
    source_system      TEXT,
    source_entity      TEXT
)
LANGUAGE SQL
AS $$
WITH deduplicated_products AS (
    SELECT *
         , ROW_NUMBER() OVER (
             PARTITION BY product_src_id
             ORDER BY 
               CASE WHEN product_name ILIKE 'Unknown' THEN 1 ELSE 0 END,
               CASE source_system WHEN 'ONLINE' THEN 1 WHEN 'OFFLINE' THEN 2 ELSE 3 END,
               ta_insert_dt DESC
         ) AS rn
    FROM (
        SELECT DISTINCT
            COALESCE(TRIM(item_code), 'n.a.') AS product_src_id,
            COALESCE(NULLIF(TRIM(item_name), ''), 'Unknown') AS product_name,
            COALESCE(NULLIF(TRIM(category_code), ''), 'Unknown') AS category_name,
            CAST(COALESCE(NULLIF(loss_rate, ''), '0') AS FLOAT) AS loss_rate_pct,
            CURRENT_DATE AS ta_insert_dt,
            CURRENT_DATE AS ta_update_dt,
            'ONLINE' AS source_system,
            'SRC_ONLINE_ORDERS' AS source_entity
        FROM sa_online.src_online_orders
        WHERE item_code IS NOT NULL

        UNION ALL

        SELECT DISTINCT
            COALESCE(TRIM(item_code), 'n.a.') AS product_src_id,
            COALESCE(NULLIF(TRIM(item_code), ''), 'Unknown') AS product_name,
            COALESCE(NULLIF(TRIM(category_code), ''), 'Unknown') AS category_name,
            CAST(COALESCE(NULLIF(loss_rate, ''), '0') AS FLOAT) AS loss_rate_pct,
            CURRENT_DATE AS ta_insert_dt,
            CURRENT_DATE AS ta_update_dt,
            'OFFLINE' AS source_system,
            'SRC_OFFLINE_ORDERS' AS source_entity
        FROM sa_offline.src_offline_orders
        WHERE item_code IS NOT NULL
    ) raw_combined
)
SELECT
    product_src_id,
    product_name,
    category_name,
    loss_rate_pct,
    ta_insert_dt,
    ta_update_dt,
    source_system,
    source_entity
FROM deduplicated_products
WHERE rn = 1;
$$;

--PROCEDURE
CREATE OR REPLACE PROCEDURE bl_cl.load_dm_products()
LANGUAGE plpgsql
AS $$
DECLARE
    v_product_src_id   VARCHAR;
    v_product_name     VARCHAR;
    v_category_name    VARCHAR;
    v_loss_rate_act    NUMERIC;
    v_ta_insert_dt     DATE;
    v_ta_update_dt     DATE;
    v_source_system    TEXT;
    v_source_entity    TEXT;
    v_row_count        INT := 0;
    v_rows_inserted    INT := 0;
BEGIN
    FOR v_product_src_id, v_product_name, v_category_name,
        v_loss_rate_act, v_ta_insert_dt, v_ta_update_dt,
        v_source_system, v_source_entity
    IN SELECT * FROM bl_cl.get_new_dm_products()
    LOOP
        BEGIN
            INSERT INTO bl_dm.dim_products (
                product_src_id,
                product_name,
                category_name,
                loss_rate_act,
                ta_insert_dt,
                ta_update_dt,
                source_system,
                source_entity
            )
            VALUES (
                v_product_src_id,
                v_product_name,
                v_category_name,
                v_loss_rate_act,
                v_ta_insert_dt,
                v_ta_update_dt,
                v_source_system,
                v_source_entity
            );

            GET DIAGNOSTICS v_row_count = ROW_COUNT;
            v_rows_inserted := v_rows_inserted + v_row_count;

        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Skipping product %: %', v_product_src_id, SQLERRM;
        END;
    END LOOP;

    CALL bl_cl.log_procedure_activity(
        'load_dm_products',
        v_rows_inserted,
        CASE
            WHEN v_rows_inserted > 0 THEN 'Inserted new product records.'
            ELSE 'No new products to insert.'
        END
    );

EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.log_procedure_activity(
            'load_dm_products',
            0,
            'Failed in load_dm_products(): ' || SQLERRM
        );
        RAISE;
END;
$$;

SELECT * FROM bl_cl.get_new_dm_products()


-- executing the loader
CALL bl_cl.load_dm_products();

-- checking log
SELECT * FROM bl_cl.load_log
WHERE procedure_name = 'load_dm_products'
ORDER BY log_ts DESC;

SELECT COUNT(*) FROM bl_cl.get_new_dm_products()

SELECT 
    d.product_src_id,
    d.product_name,
    d.category_name,
    d.loss_rate_act,
    d.source_system,
    d.source_entity,
    d.ta_insert_dt
FROM bl_dm.dim_products d
JOIN bl_3nf.ce_products p
    ON d.product_src_id = p.product_src_id
ORDER BY d.ta_insert_dt DESC;


DROP FUNCTION bl_cl.get_new_dm_product_prices_scd()
--PRODUCT_PRICES_SCD
--FUNCTION
CREATE OR REPLACE FUNCTION bl_cl.get_new_dm_product_prices_scd()
RETURNS TABLE (
    product_src_id TEXT,
    price_unit_act FLOAT,
    price_fact_act FLOAT,
    start_dt DATE,
    end_dt DATE,
    is_active VARCHAR(5),
    ta_insert_dt DATE,
    ta_update_dt DATE,
    source_system TEXT,
    source_entity TEXT
)
LANGUAGE SQL
AS $$
WITH source_data AS (
    SELECT DISTINCT 
        TRIM(item_code) AS product_src_id,
        CAST(unit_selling_price AS FLOAT) AS price_unit_act,
        'SRC_OFFLINE_ORDERS' AS source_entity,
        source_system
    FROM sa_offline.src_offline_orders
    WHERE item_code IS NOT NULL AND unit_selling_price ~ '^[0-9.]+$'

    UNION

    SELECT DISTINCT 
        TRIM(item_code) AS product_src_id,
        CAST(unit_selling_price AS FLOAT) AS price_unit_act,
        'SRC_ONLINE_ORDERS' AS source_entity,
        source_system
    FROM sa_online.src_online_orders
    WHERE item_code IS NOT NULL AND unit_selling_price ~ '^[0-9.]+$'
),
ranked_prices AS (
    SELECT 
        product_src_id,
        price_unit_act,
        source_system,
        source_entity,
        ROW_NUMBER() OVER (PARTITION BY product_src_id, source_system ORDER BY price_unit_act, source_entity) AS rn,
        COUNT(*) OVER (PARTITION BY product_src_id) AS cnt
    FROM source_data
),
dated_versions AS (
    SELECT 
        product_src_id,
        price_unit_act,
        price_unit_act AS price_fact_act,
        DATE '2024-01-01' + (rn - 1) * INTERVAL '1 day' AS start_dt,
        DATE '2024-01-01' + rn * INTERVAL '1 day' AS end_dt,
        rn,
        cnt,
        source_system,
        source_entity
    FROM ranked_prices
),
finalized_versions AS (
    SELECT 
        product_src_id,
        price_unit_act,
        price_fact_act,
        start_dt,
        CASE 
            WHEN rn = cnt THEN DATE '9999-12-31'
            ELSE end_dt
        END AS end_dt,
        rn = cnt AS is_active,
        CURRENT_DATE AS ta_insert_dt,
        CURRENT_DATE AS ta_update_dt,
        source_system,
        source_entity
    FROM dated_versions
)
SELECT *
FROM finalized_versions
WHERE (product_src_id, price_unit_act) NOT IN (
    SELECT product_src_id, price_unit_act FROM bl_dm.dim_product_prices_scd
);
$$;


--PROCEDURE
CREATE OR REPLACE PROCEDURE bl_cl.load_dm_product_prices_scd()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_inserted INT := 0;
BEGIN
    INSERT INTO bl_dm.dim_product_prices_scd (
        product_src_id,
        price_unit_act,
        price_fact_act,
        start_dt,
        end_dt,
        is_active,
        ta_insert_dt,
        ta_update_dt,
        source_system,
        source_entity
    )
    SELECT 
        product_src_id,
        price_unit_act,
        price_fact_act,
        start_dt,
        end_dt,
        is_active :: BOOLEAN,
        ta_insert_dt,
        ta_update_dt,
        source_system,
        source_entity
    FROM bl_cl.get_new_dm_product_prices_scd();

    GET DIAGNOSTICS v_rows_inserted = ROW_COUNT;

    CALL bl_cl.log_procedure_activity(
        'load_dm_product_prices_scd',
        v_rows_inserted,
        CASE
            WHEN v_rows_inserted > 0 THEN 'Inserted new product price records'
            ELSE 'No new product prices to insert.'
        END
    );

EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.log_procedure_activity(
            'load_dm_product_prices_scd',
            0,
            'Failed in load_dm_product_prices_scd(): ' || SQLERRM
        );
        RAISE;
END;
$$;



SELECT * FROM bl_cl.get_new_dm_product_prices_scd()

-- executing the loader
CALL bl_cl.load_dm_product_prices_scd()

-- checking log
SELECT * FROM bl_cl.load_log
WHERE procedure_name = 'load_dm_product_prices_scd'
ORDER BY log_ts DESC;

SELECT COUNT(*) FROM bl_cl.get_new_dm_products()


