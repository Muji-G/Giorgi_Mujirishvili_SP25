-- creating schema and log table, as well as log procedure activity
CREATE SCHEMA IF NOT EXISTS BL_CL;

BEGIN;
CREATE TABLE IF NOT EXISTS BL_CL.load_log (
    log_id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
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

--CE_ADDRESSES
--FUNCTION
CREATE OR REPLACE FUNCTION bl_cl.get_new_addresses()
RETURNS TABLE (
    address_line    VARCHAR,
    city_name       VARCHAR,
    region_name     VARCHAR,
    postal_code     VARCHAR,
    country_name    VARCHAR,
    insert_dt       DATE,
    update_dt       DATE,
    source_system   VARCHAR,
    source_entity   VARCHAR
)
LANGUAGE SQL
AS $$
    SELECT DISTINCT
        TRIM(branch)       AS address_line,
        TRIM(city)         AS city_name,
        CASE
            WHEN LOWER(city) IN ('tbilisi', 'city a') THEN 'East'
            WHEN LOWER(city) IN ('batumi', 'city b') THEN 'West'
            ELSE 'Central'
        END                AS region_name,
        LPAD(ABS(HASHTEXT(city))::TEXT, 5, '0') AS postal_code,
        'Georgia'          AS country_name,
        CURRENT_DATE       AS insert_dt,
        CURRENT_DATE       AS update_dt,
        source_system,
        'SRC_ONLINE_ORDERS' AS source_entity
    FROM sa_online.src_online_orders o
    WHERE branch IS NOT NULL AND TRIM(branch) <> ''

    UNION

    SELECT DISTINCT
        TRIM(branch),
        TRIM(city),
        CASE
            WHEN LOWER(city) IN ('kutaisi') THEN 'West'
            ELSE 'Central'
        END,
        LPAD(ABS(HASHTEXT(city))::TEXT, 5, '0'),
        'Georgia',
        CURRENT_DATE,
        CURRENT_DATE,
        source_system,
        'SRC_OFFLINE_ORDERS'
    FROM sa_offline.src_offline_orders o
    WHERE branch IS NOT NULL AND TRIM(branch) <> '';
$$;

--PROCEDURE
CREATE OR REPLACE PROCEDURE bl_cl.load_addresses()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_inserted INTEGER := 0;
    v_row_count     INTEGER := 0;
BEGIN
    INSERT INTO bl_3nf.ce_addresses (
        address_line,
        city_name,
        region_name,
        postal_code,
        country_name,
        insert_dt,
        update_dt,
        source_system,
        source_entity
    )
    SELECT
        address_line,
        city_name,
        region_name,
        postal_code,
        country_name,
        insert_dt,
        update_dt,
        source_system,
        source_entity
    FROM bl_cl.get_new_addresses() s
    WHERE NOT EXISTS (
        SELECT 1
        FROM bl_3nf.ce_addresses c
        WHERE LOWER(c.address_line) = LOWER(s.address_line)
          AND LOWER(c.city_name) = LOWER(s.city_name)
          AND LOWER(COALESCE(c.region_name, '')) = LOWER(COALESCE(s.region_name, ''))
          AND LOWER(COALESCE(c.postal_code, '')) = LOWER(COALESCE(s.postal_code, ''))
          AND LOWER(c.country_name) = LOWER(s.country_name)
          AND c.source_system = s.source_system
          AND c.source_entity = s.source_entity
    );

    GET DIAGNOSTICS v_row_count = ROW_COUNT;
    v_rows_inserted := v_row_count;

    CALL bl_cl.log_procedure_activity(
        'load_addresses',
        v_rows_inserted,
        CASE 
            WHEN v_rows_inserted > 0 THEN 'Inserted address rows from src_online/offline_orders.'
            ELSE 'No new addresses to insert.'
        END
    );

EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.log_procedure_activity(
            'load_addresses',
            0,
            'Failed: ' || SQLERRM
        );
        RAISE;
END;
$$;

SELECT COUNT(*) AS new_address_count
FROM bl_cl.get_new_addresses();


CALL bl_cl.load_addresses();

SELECT *
FROM bl_cl.load_log
WHERE procedure_name = 'load_addresses'
ORDER BY log_id DESC
LIMIT 1;

--CE_CUSTOMERS
--FUNCTION
CREATE OR REPLACE FUNCTION bl_cl.get_new_customers()
RETURNS TABLE (
    customer_src_id VARCHAR,
    customer_name   VARCHAR,
    insert_dt       DATE,
    update_dt       DATE,
    source_system   VARCHAR,
    source_entity   VARCHAR
)
LANGUAGE SQL
AS $$
    -- online source
    SELECT DISTINCT
        TRIM(customer_id_1)       AS customer_src_id,
        'Online Customer'         AS customer_name,
        CURRENT_DATE              AS insert_dt,
        CURRENT_DATE              AS update_dt,
        source_system,
        'SRC_ONLINE_ORDERS'       AS source_entity
    FROM sa_online.src_online_orders
    WHERE customer_id_1 IS NOT NULL AND TRIM(customer_id_1) <> ''

    UNION

    -- offline source
    SELECT DISTINCT
        TRIM(customer_id)         AS customer_src_id,
        'Offline Customer'        AS customer_name,
        CURRENT_DATE,
        CURRENT_DATE,
        source_system,
        'SRC_OFFLINE_ORDERS'
    FROM sa_offline.src_offline_orders
    WHERE customer_id IS NOT NULL AND TRIM(customer_id) <> '';
$$;

--PROCEDURE
CREATE OR REPLACE PROCEDURE bl_cl.load_customers()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_inserted INTEGER := 0;
    v_row_count     INTEGER := 0;
    v_rec           RECORD;
BEGIN
    FOR v_rec IN SELECT * FROM bl_cl.get_new_customers()
    LOOP
        BEGIN
            INSERT INTO bl_3nf.ce_customers (
                customer_src_id,
                customer_name,
                insert_dt,
                update_dt,
                source_system,
                source_entity
            )
            SELECT
                v_rec.customer_src_id,
                v_rec.customer_name,
                v_rec.insert_dt,
                v_rec.update_dt,
                v_rec.source_system,
                v_rec.source_entity
            WHERE NOT EXISTS (
                SELECT 1
                FROM bl_3nf.ce_customers c
                WHERE LOWER(TRIM(c.customer_src_id)) = LOWER(TRIM(v_rec.customer_src_id))
                  AND LOWER(TRIM(c.source_system)) = LOWER(TRIM(v_rec.source_system))
                  AND LOWER(TRIM(c.source_entity)) = LOWER(TRIM(v_rec.source_entity))
            );

            GET DIAGNOSTICS v_row_count = ROW_COUNT;
            v_rows_inserted := v_rows_inserted + v_row_count;

        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Skipping error for customer %: %', v_rec.customer_src_id, SQLERRM;
        END;
    END LOOP;

    CALL bl_cl.log_procedure_activity(
        'load_customers',
        v_rows_inserted,
        CASE 
            WHEN v_rows_inserted > 0 THEN 'Inserted new customer rows.'
            ELSE 'No new customers to insert.'
        END
    );

EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.log_procedure_activity(
            'load_customers',
            0,
            'Failed in load_customers(): ' || SQLERRM
        );
        RAISE;
END;
$$;





select count(*) FROM bl_cl.get_new_customers(); -- 1000 rows

CALL bl_cl.load_customers();

SELECT * FROM bl_cl.load_log
WHERE procedure_name = 'load_customers'
ORDER BY log_id DESC;

SELECT * FROM bl_cl.get_new_customers();


--CE_CUSTOMERS
--FUNCTION
CREATE OR REPLACE FUNCTION bl_cl.get_new_employees()
RETURNS TABLE (
    employee_src_id VARCHAR,
    employee_name   VARCHAR,
    insert_dt       DATE,
    update_dt       DATE,
    source_system   VARCHAR,
    source_entity   VARCHAR
)
LANGUAGE SQL
AS $$
    SELECT DISTINCT
        TRIM(employee_id)              AS employee_src_id,
        TRIM(employee_id) 			   AS employee_name,
        CURRENT_DATE                   AS insert_dt,
        CURRENT_DATE                   AS update_dt,
        source_system,
        'SRC_ONLINE_ORDERS'           AS source_entity
    FROM sa_online.src_online_orders
    WHERE employee_id IS NOT NULL AND TRIM(employee_id) <> ''

    UNION

    SELECT DISTINCT
        TRIM(employee_id),
        TRIM(employee_id),
        CURRENT_DATE,
        CURRENT_DATE,
        source_system,
        'SRC_OFFLINE_ORDERS'
    FROM sa_offline.src_offline_orders
    WHERE employee_id IS NOT NULL AND TRIM(employee_id) <> '';
$$;


--PROCEDURE
CREATE OR REPLACE PROCEDURE bl_cl.load_employees()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_inserted INTEGER := 0;
    v_row_count     INTEGER := 0;
    v_rec           RECORD;
BEGIN
    FOR v_rec IN SELECT * FROM bl_cl.get_new_employees()
    LOOP
        BEGIN
            INSERT INTO bl_3nf.ce_employees (
                employee_src_id,
                employee_name,
                insert_dt,
                update_dt,
                source_system,
                source_entity
            )
            SELECT
                v_rec.employee_src_id,
                v_rec.employee_name,
                v_rec.insert_dt,
                v_rec.update_dt,
                v_rec.source_system,
                v_rec.source_entity
            WHERE NOT EXISTS (
                SELECT 1
                FROM bl_3nf.ce_employees e
                WHERE TRIM(LOWER(e.employee_src_id)) = TRIM(LOWER(v_rec.employee_src_id))
            );

            GET DIAGNOSTICS v_row_count = ROW_COUNT;
            v_rows_inserted := v_rows_inserted + v_row_count;

        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Skipping employee %: %', v_rec.employee_src_id, SQLERRM;
        END;
    END LOOP;

    CALL bl_cl.log_procedure_activity(
        'load_employees',
        v_rows_inserted,
        CASE 
            WHEN v_rows_inserted > 0 THEN 'Inserted new employees.'
            ELSE 'No new employees to insert.'
        END
    );

EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.log_procedure_activity(
            'load_employees',
            0,
            'Failed in load_employees(): ' || SQLERRM
        );
        RAISE;
END;
$$;


select * FROM bl_cl.get_new_employees();
CALL bl_cl.load_employees();

ALTER TABLE bl_3nf.ce_employees
ALTER COLUMN employee_src_id TYPE VARCHAR;

SELECT * FROM bl_cl.load_log
WHERE procedure_name = 'load_employees'
ORDER BY log_id DESC;

SELECT employee_src_id, COUNT(*)
FROM bl_3nf.ce_employees
GROUP BY employee_src_id
HAVING COUNT(*) > 1;


--CE_BRANCHES
--FUNCTION
CREATE OR REPLACE FUNCTION bl_cl.get_new_branches()
RETURNS TABLE (
    branch_src_id VARCHAR,
    branch_name   VARCHAR,
    city_name     VARCHAR,
    insert_dt     DATE,
    update_dt     DATE,
    source_system VARCHAR,
    source_entity VARCHAR
)
LANGUAGE SQL
AS $$
    SELECT DISTINCT
        TRIM(branch)                      AS branch_src_id,
        TRIM(branch)                      AS branch_name,
        TRIM(city)                        AS city_name,
        CURRENT_DATE                      AS insert_dt,
        CURRENT_DATE                      AS update_dt,
        source_system,
        'SRC_ONLINE_ORDERS'              AS source_entity
    FROM sa_online.src_online_orders
    WHERE branch IS NOT NULL AND TRIM(branch) <> ''

    UNION

    SELECT DISTINCT
        TRIM(branch),
        TRIM(branch),
        TRIM(city),
        CURRENT_DATE,
        CURRENT_DATE,
        source_system,
        'SRC_OFFLINE_ORDERS'
    FROM sa_offline.src_offline_orders
    WHERE branch IS NOT NULL AND TRIM(branch) <> '';
$$;


--PROCEDURE
CREATE OR REPLACE PROCEDURE bl_cl.load_branches()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_inserted INTEGER := 0;
    v_row_count     INTEGER := 0;
    v_rec           RECORD;
    v_address_id    BIGINT;
BEGIN
    FOR v_rec IN SELECT * FROM bl_cl.get_new_branches()
    LOOP
        BEGIN
            SELECT address_id INTO v_address_id
            FROM bl_3nf.ce_addresses
            WHERE LOWER(TRIM(city_name)) = LOWER(TRIM(v_rec.city_name))
            LIMIT 1;

            IF v_address_id IS NULL THEN
                RAISE NOTICE 'No matching address found for city: %', v_rec.city_name;
                CONTINUE;
            END IF;
            INSERT INTO bl_3nf.ce_branches (
                branch_src_id,
                branch_name,
                address_id,
                insert_dt,
                update_dt,
                source_system,
                source_entity
            )
            SELECT
                v_rec.branch_src_id,
                v_rec.branch_name,
                v_address_id,
                v_rec.insert_dt,
                v_rec.update_dt,
                v_rec.source_system,
                v_rec.source_entity
            WHERE NOT EXISTS (
                SELECT 1
                FROM bl_3nf.ce_branches b
                WHERE LOWER(TRIM(b.branch_src_id)) = LOWER(TRIM(v_rec.branch_src_id))
            );

            GET DIAGNOSTICS v_row_count = ROW_COUNT;
            v_rows_inserted := v_rows_inserted + v_row_count;

        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Skipping branch %: %', v_rec.branch_src_id, SQLERRM;
        END;
    END LOOP;

    CALL bl_cl.log_procedure_activity(
        'load_branches',
        v_rows_inserted,
        CASE 
            WHEN v_rows_inserted > 0 THEN 'Inserted new branches.'
            ELSE 'No new branches to insert.'
        END
    );

EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.log_procedure_activity(
            'load_branches',
            0,
            'Failed in load_branches(): ' || SQLERRM
        );
        RAISE;
END;
$$;


select count(*) FROM bl_cl.get_new_branches();

CALL bl_cl.load_branches();

SELECT *
FROM bl_cl.load_log
WHERE procedure_name = 'load_branches'
ORDER BY log_ts DESC


SELECT
    (SELECT rows_affected
     FROM bl_cl.load_log
     WHERE procedure_name = 'load_branches'
     ORDER BY log_ts DESC
     LIMIT 1) AS logged_rows_inserted,

    (SELECT COUNT(*) FROM bl_3nf.ce_branches) AS actual_total_rows,

    (SELECT COUNT(*) FROM (
        SELECT DISTINCT branch_src_id
        FROM bl_cl.get_new_branches()
        WHERE LOWER(TRIM(branch_src_id)) NOT IN (
            SELECT LOWER(TRIM(branch_src_id)) FROM bl_3nf.ce_branches
        )
    ) AS diff) AS remaining_candidates;

    
    
 

--CE_CHANNELS
--FUNCTION
CREATE OR REPLACE FUNCTION bl_cl.get_new_channels()
RETURNS TABLE (
    channel_src_id INTEGER,
    channel_name   VARCHAR(100),
    insert_dt      DATE,
    update_dt      DATE,
    source_system  VARCHAR(100),
    source_entity  VARCHAR(100)
)
LANGUAGE SQL
AS $$
    SELECT
        1 AS channel_src_id,
        'ONLINE' AS channel_name,
        CURRENT_DATE AS insert_dt,
        CURRENT_DATE AS update_dt,
        'CSV' AS source_system,
        'SRC_ONLINE_ORDERS' AS source_entity

    UNION ALL

    SELECT
        2,
        'OFFLINE',
        CURRENT_DATE,
        CURRENT_DATE,
        'CSV',
        'SRC_OFFLINE_ORDERS';
$$;

--PROCEDURE
CREATE OR REPLACE PROCEDURE bl_cl.load_channels()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rows_inserted INTEGER := 0;
    v_row_count     INTEGER := 0;
    v_rec           RECORD;
BEGIN
    FOR v_rec IN SELECT * FROM bl_cl.get_new_channels()
    LOOP
        BEGIN
            INSERT INTO bl_3nf.ce_channels (
                channel_src_id,
                channel_name,
                insert_dt,
                update_dt,
                source_system,
                source_entity
            )
            SELECT
                v_rec.channel_src_id,
                v_rec.channel_name,
                v_rec.insert_dt,
                v_rec.update_dt,
                v_rec.source_system,
                v_rec.source_entity
            WHERE NOT EXISTS (
                SELECT 1
                FROM bl_3nf.ce_channels c
                WHERE c.channel_src_id = v_rec.channel_src_id
            );

            GET DIAGNOSTICS v_row_count = ROW_COUNT;
            v_rows_inserted := v_rows_inserted + v_row_count;

        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Skipping channel %: %', v_rec.channel_src_id, SQLERRM;
        END;
    END LOOP;

    CALL bl_cl.log_procedure_activity(
        'load_channels',
        v_rows_inserted,
        CASE 
            WHEN v_rows_inserted > 0 THEN 'Inserted new channels.'
            ELSE 'No new channels to insert.'
        END
    );

EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.log_procedure_activity(
            'load_channels',
            0,
            'Failed in load_channels(): ' || SQLERRM
        );
        RAISE;
END;
$$;

SELECT * FROM bl_cl.get_new_channels();

SELECT *
FROM bl_cl.get_new_channels() c
WHERE c.channel_src_id NOT IN (
    SELECT channel_src_id FROM bl_3nf.ce_channels
);

call bl_cl.load_channels();

SELECT *
FROM bl_cl.load_log
WHERE procedure_name = 'load_channels'
ORDER BY log_ts desc;

SELECT COUNT(*) AS remaining_branch_candidates
FROM bl_cl.get_new_branches() b
WHERE LOWER(TRIM(b.branch_src_id)) NOT IN (
    SELECT LOWER(TRIM(branch_src_id))
    FROM bl_3nf.ce_branches
);

--CE_PRODUCTS
--FUNCTION
CREATE OR REPLACE FUNCTION bl_cl.get_new_products()
RETURNS TABLE (
    product_src_id     VARCHAR(100),
    product_name       VARCHAR(100),
    subcategory_src_id VARCHAR(100),
    loss_rate_act      FLOAT,
    insert_dt          DATE,
    update_dt          DATE,
    source_system      VARCHAR(100),
    source_entity      VARCHAR(100)
)
LANGUAGE SQL
AS $$
    WITH unified AS (
        SELECT DISTINCT ON (TRIM(item_code))
            TRIM(item_code) AS product_src_id,
            COALESCE(NULLIF(TRIM(item_name), ''), 'UNKNOWN') AS product_name,
            TRIM(category_code) AS subcategory_src_id,
            CAST(loss_rate AS FLOAT) AS loss_rate_act,
            CURRENT_DATE AS insert_dt,
            CURRENT_DATE AS update_dt,
            source_system,
            'SRC_ONLINE_ORDERS' AS source_entity
        FROM sa_online.src_online_orders
        WHERE item_code IS NOT NULL AND TRIM(item_code) <> ''

        UNION ALL

        SELECT DISTINCT ON (TRIM(item_code))
            TRIM(item_code),
            'UNKNOWN',
            TRIM(category_code),
            CAST(loss_rate AS FLOAT),
            CURRENT_DATE,
            CURRENT_DATE,
            source_system,
            'SRC_OFFLINE_ORDERS'
        FROM sa_offline.src_offline_orders
        WHERE item_code IS NOT NULL AND TRIM(item_code) <> ''
    )
    SELECT *
    FROM unified u
    WHERE NOT EXISTS (
        SELECT 1
        FROM bl_3nf.ce_products p
        WHERE LOWER(TRIM(p.product_src_id)) = LOWER(TRIM(u.product_src_id))
    );
$$;

--PROCEDURE
CREATE OR REPLACE PROCEDURE bl_cl.load_products()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rec RECORD;
    v_rows_inserted INT := 0;
    v_row_count INT := 0;
    v_subcategory_id INT;
BEGIN
    FOR v_rec IN SELECT * FROM bl_cl.get_new_products()
    LOOP
        BEGIN
            -- Lookup subcategory_id
            SELECT subcategory_id INTO v_subcategory_id
            FROM bl_3nf.ce_product_subcategories
            WHERE LOWER(TRIM(subcategory_src_id)) = LOWER(TRIM(v_rec.subcategory_src_id))
            LIMIT 1;

            IF v_subcategory_id IS NULL THEN
                RAISE NOTICE 'Subcategory not found for %', v_rec.subcategory_src_id;
                CONTINUE;
            END IF;

            -- Insert only if not already present
            INSERT INTO bl_3nf.ce_products (
                product_src_id,
                product_name,
                subcategory_src_id,
                loss_rate_act,
                insert_dt,
                update_dt,
                source_system,
                source_entity,
                subcategory_id
            )
            SELECT
                v_rec.product_src_id,
                v_rec.product_name,
                v_rec.subcategory_src_id,
                v_rec.loss_rate_act,
                v_rec.insert_dt,
                v_rec.update_dt,
                v_rec.source_system,
                v_rec.source_entity,
                v_subcategory_id
            WHERE NOT EXISTS (
                SELECT 1 FROM bl_3nf.ce_products p
                WHERE LOWER(TRIM(p.product_src_id)) = LOWER(TRIM(v_rec.product_src_id))
            );

            GET DIAGNOSTICS v_row_count = ROW_COUNT;
            v_rows_inserted := v_rows_inserted + v_row_count;

        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Skipping product %: %', v_rec.product_src_id, SQLERRM;
        END;
    END LOOP;

    -- Log procedure run
    CALL bl_cl.log_procedure_activity(
        'load_products',
        v_rows_inserted,
        CASE 
            WHEN v_rows_inserted > 0 THEN 'Inserted new products.'
            ELSE 'No new products to insert.'
        END
    );

EXCEPTION
    WHEN OTHERS THEN
        CALL bl_cl.log_procedure_activity(
            'load_products',
            0,
            'Failed in load_products(): ' || SQLERRM
        );
        RAISE;
END;
$$;


select * FROM bl_cl.get_new_products(); -- 50 rows

CALL bl_cl.load_products();

SELECT *
FROM bl_cl.load_log
WHERE procedure_name = 'load_products'
ORDER BY log_ts DESC

-- actual records from the function that are NOT in the target table
SELECT *
FROM bl_cl.get_new_products() np
WHERE NOT EXISTS (
    SELECT 1
    FROM bl_3nf.ce_products p
    WHERE LOWER(TRIM(p.product_src_id)) = LOWER(TRIM(np.product_src_id))
);

-- counting distinct item codes in ONLINE source
SELECT COUNT(DISTINCT TRIM(item_code)) FROM sa_online.src_online_orders WHERE item_code IS NOT NULL AND TRIM(item_code) <> ''; --50 

-- counting distinct item codes in OFFLINE source
SELECT COUNT(DISTINCT TRIM(item_code)) FROM sa_offline.src_offline_orders WHERE item_code IS NOT NULL AND TRIM(item_code) <> ''; --50

-- counting distinct product_src_id in CE_PRODUCTS
SELECT COUNT(DISTINCT TRIM(product_src_id)) FROM bl_3nf.ce_products; --51 all 50 +1 default row


--CE_PRODUCT_CATEGORIES
--FUNCTION
CREATE OR REPLACE FUNCTION bl_cl.get_new_product_categories()
RETURNS TABLE (
    category_src_id   VARCHAR(100),
    category_name     VARCHAR(100),
    insert_dt         DATE,
    update_dt         DATE,
    source_system     VARCHAR(100),
    source_entity     VARCHAR(100)
)
LANGUAGE SQL
AS $$
    SELECT DISTINCT
        TRIM(category_code) AS category_src_id,
        INITCAP(TRIM(category_code)) AS category_name,
        CURRENT_DATE,
        CURRENT_DATE,
        'FILE_CSV',
        'SRC_ONLINE_ORDERS'
    FROM sa_online.src_online_orders
    WHERE TRIM(category_code) IS NOT NULL
      AND TRIM(category_code) <> ''
      AND LOWER(TRIM(category_code)) <> 'n.a.'
      AND TRIM(category_code) NOT IN (
          SELECT category_src_id
          FROM bl_3nf.ce_product_categories
      );
$$;


--PROCEDURE
CREATE OR REPLACE PROCEDURE bl_cl.load_product_categories()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rec RECORD;
    v_rows_inserted INT := 0;
    v_row_count INT := 0;
BEGIN
    FOR v_rec IN SELECT * FROM bl_cl.get_new_product_categories()
    LOOP
        BEGIN
            INSERT INTO bl_3nf.ce_product_categories (
                category_src_id,
                category_name,
                insert_dt,
                update_dt,
                source_system,
                source_entity
            )
            SELECT
                v_rec.category_src_id,
                v_rec.category_name,
                v_rec.insert_dt,
                v_rec.update_dt,
                v_rec.source_system,
                v_rec.source_entity
            WHERE NOT EXISTS (
                SELECT 1
                FROM bl_3nf.ce_product_categories c
                WHERE c.category_src_id = v_rec.category_src_id
            );

            GET DIAGNOSTICS v_row_count = ROW_COUNT;
            v_rows_inserted := v_rows_inserted + v_row_count;

        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Skipping category %: %', v_rec.category_src_id, SQLERRM;
        END;
    END LOOP;

    CALL bl_cl.log_procedure_activity(
        'load_product_categories',
        v_rows_inserted,
        CASE 
            WHEN v_rows_inserted > 0 THEN 'Inserted new product categories.'
            ELSE 'No new product categories to insert.'
        END
    );
END;
$$;

select * FROM bl_cl.get_new_product_categories()

CALL bl_cl.load_products();

SELECT *
FROM bl_cl.load_log
WHERE procedure_name = 'load_products'
ORDER BY log_ts DESC


SELECT *
FROM bl_3nf.ce_product_categories
WHERE LOWER(TRIM(category_src_id)) NOT IN (
    SELECT LOWER(TRIM(category_code))
    FROM sa_online.src_online_orders
    WHERE category_code IS NOT NULL AND TRIM(category_code) <> ''
);

--CE_PRODUCT_SUBCATEGORIES
--FUNCTION
CREATE OR REPLACE FUNCTION bl_cl.get_new_product_subcategories()
RETURNS TABLE (
    subcategory_src_id VARCHAR(100),
    subcategory_name   VARCHAR(100),
    insert_dt          DATE,
    update_dt          DATE,
    source_system      VARCHAR(100),
    source_entity      VARCHAR(100)
)
LANGUAGE SQL
AS $$
    SELECT DISTINCT
        TRIM(category_code) AS subcategory_src_id,
        INITCAP(TRIM(category_code)) AS subcategory_name,
        CURRENT_DATE,
        CURRENT_DATE,
        'FILE_CSV',
        'SRC_ONLINE_ORDERS'
    FROM sa_online.src_online_orders
    WHERE TRIM(category_code) IS NOT NULL
      AND TRIM(category_code) <> ''
      AND LOWER(TRIM(category_code)) <> 'n.a.'
      AND TRIM(category_code) NOT IN (
          SELECT subcategory_src_id
          FROM bl_3nf.ce_product_subcategories
      );
$$;

--PROCEDURE
CREATE OR REPLACE PROCEDURE bl_cl.load_product_subcategories()
LANGUAGE plpgsql
AS $$
DECLARE
    v_rec RECORD;
    v_rows_inserted INT := 0;
    v_row_count INT := 0;
BEGIN
    FOR v_rec IN SELECT * FROM bl_cl.get_new_product_subcategories()
    LOOP
        BEGIN
            INSERT INTO bl_3nf.ce_product_subcategories (
                subcategory_src_id,
                subcategory_name,
                insert_dt,
                update_dt,
                source_system,
                source_entity
            )
            SELECT
                v_rec.subcategory_src_id,
                v_rec.subcategory_name,
                v_rec.insert_dt,
                v_rec.update_dt,
                v_rec.source_system,
                v_rec.source_entity
            WHERE NOT EXISTS (
                SELECT 1
                FROM bl_3nf.ce_product_subcategories s
                WHERE s.subcategory_src_id = v_rec.subcategory_src_id
            );

            GET DIAGNOSTICS v_row_count = ROW_COUNT;
            v_rows_inserted := v_rows_inserted + v_row_count;

        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Skipping subcategory %: %', v_rec.subcategory_src_id, SQLERRM;
        END;
    END LOOP;

    CALL bl_cl.log_procedure_activity(
        'load_product_subcategories',
        v_rows_inserted,
        CASE 
            WHEN v_rows_inserted > 0 THEN 'Inserted new product subcategories.'
            ELSE 'No new product subcategories to insert.'
        END
    );
END;
$$;



select * FROM bl_cl.get_new_product_subcategories()

CALL bl_cl.load_product_subcategories();

SELECT *
FROM bl_cl.load_log
WHERE procedure_name = 'load_product_subcategories'
ORDER BY log_ts DESC


SELECT *
FROM bl_3nf.ce_product_subcategories
WHERE LOWER(TRIM(subcategory_src_id)) NOT IN (
    SELECT LOWER(TRIM(category_code))
    FROM sa_online.src_online_orders
    WHERE category_code IS NOT NULL AND TRIM(category_code) <> ''
);


--PRODUCT_PRICES_SCD
--FUNCTION
CREATE OR REPLACE FUNCTION bl_cl.get_new_product_prices_scd()
RETURNS TABLE (
    product_id INT,
    price_amt_act FLOAT,
    price_type_name VARCHAR(50),
    start_dt DATE,
    end_dt DATE,
    is_active VARCHAR(1),
    insert_dt DATE,
    update_dt DATE,
    source_system VARCHAR(50),
    source_entity VARCHAR(50)
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
    )
    SELECT
        p.product_id,
        CAST(src.unit_selling_price AS FLOAT),
        'Standard',
        CURRENT_DATE,
        DATE '9999-12-31',
        'Y',
        CURRENT_DATE,
        CURRENT_DATE,
        'MERGED',
        'SRC_ONLINE_AND_OFFLINE'
    FROM src_combined src
    JOIN bl_3nf.ce_products p
      ON p.product_src_id = src.item_code
    WHERE NOT EXISTS (
        SELECT 1
        FROM bl_3nf.ce_product_prices_scd scd
        WHERE scd.product_id = p.product_id
          AND scd.price_amt_act = CAST(src.unit_selling_price AS FLOAT)
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
    FOR v_rec IN SELECT * FROM bl_cl.get_new_product_prices_scd()
    LOOP
        BEGIN
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

        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Skipping product price for product_id %: %', v_rec.product_id, SQLERRM;
        END;
    END LOOP;

    CALL bl_cl.log_procedure_activity(
        'load_product_prices_scd',
        v_rows_inserted,
        CASE WHEN v_rows_inserted > 0
             THEN 'Inserted new product price records.'
             ELSE 'No new product prices to insert.'
        END
    );

EXCEPTION WHEN OTHERS THEN
    CALL bl_cl.log_procedure_activity(
        'load_product_prices_scd',
        0,
        'Failed in load_product_prices_scd(): ' || SQLERRM
    );
    RAISE;
END;
$$;



SELECT * 
FROM bl_cl.get_new_product_prices();

CALL bl_cl.load_product_prices();

SELECT *
FROM bl_cl.load_log
WHERE procedure_name = 'load_product_prices'
ORDER BY log_ts DESC;


SELECT DISTINCT
    TRIM(o.item_code) AS product_src_id,
    o.unit_selling_price
FROM (
    SELECT item_code, unit_selling_price FROM sa_online.src_online_orders
    WHERE item_code IS NOT NULL AND unit_selling_price IS NOT NULL AND TRIM(item_code) <> '' AND TRIM(unit_selling_price) <> ''
    UNION ALL
    SELECT item_code, unit_selling_price FROM sa_offline.src_offline_orders
    WHERE item_code IS NOT NULL AND unit_selling_price IS NOT NULL AND TRIM(item_code) <> '' AND TRIM(unit_selling_price) <> ''
) o
WHERE LOWER(TRIM(o.item_code) || '|' || TRIM(o.unit_selling_price)) NOT IN (
    SELECT LOWER(TRIM(p.product_src_id) || '|' || TRIM(s.price_amt_act::TEXT))
    FROM bl_3nf.ce_product_prices_scd s
    JOIN bl_3nf.ce_products p ON s.product_id = p.product_id
);
