--CE_SALES
--FUNCTION
CREATE OR REPLACE FUNCTION bl_cl.fn_get_new_3nf_ce_sales_rows()
RETURNS TABLE (
    date_id BIGINT,
    customer_id BIGINT,
    employee_id BIGINT,
    branch_id BIGINT,
    channel_id BIGINT,
    product_id BIGINT,
    price_id BIGINT,
    quantity_no INT,
    unit_price_act FLOAT,
    discount_act FLOAT,
    amount_tot_act FLOAT,
    cost_act FLOAT,
    gross_income_act FLOAT
)
LANGUAGE SQL
AS $$
WITH unified_source AS (
    SELECT
        'OFFLINE' AS channel_name,
        o.item_code,
        o.unit_selling_price,
        o.discount,
        o.total_sales,
        o.cost,
        o.gross_income,
        o.quantity_sold,
        o.year,
        o.month,
        o.day,
        o.employee_id,
        o.branch,
        o.city,
        o.customer_id,
        MAKE_DATE(CAST(o.year AS INT), CAST(o.month AS INT), CAST(o.day AS INT)) AS sale_date
    FROM sa_offline.src_offline_orders o
    WHERE TRIM(o.item_code) <> ''
      AND o.unit_selling_price ~ '^[0-9.]+$'
      AND o.year ~ '^\d{4}$' AND o.month ~ '^\d{1,2}$' AND o.day ~ '^\d{1,2}$'

    UNION ALL

    SELECT
        'ONLINE',
        o.item_code,
        o.unit_selling_price,
        o.discount,
        o.total_sales,
        o.cost,
        o.gross_income,
        o.quantity_sold,
        o.year,
        o.month,
        o.day,
        o.employee_id,
        o.branch,
        o.city,
        COALESCE(o.customer_id_1, o.customer_id_2),
        MAKE_DATE(CAST(o.year AS INT), CAST(o.month AS INT), CAST(o.day AS INT)) AS sale_date
    FROM sa_online.src_online_orders o
    WHERE TRIM(o.item_code) <> ''
      AND o.unit_selling_price ~ '^[0-9.]+$'
      AND o.year ~ '^\d{4}$' AND o.month ~ '^\d{1,2}$' AND o.day ~ '^\d{1,2}$'
),

prepared_data AS (
    SELECT
        (SELECT date_id FROM bl_3nf.ce_time_day WHERE date_src_id = us.sale_date) AS date_id,

        (SELECT customer_id FROM bl_3nf.ce_customers
         WHERE CAST(customer_src_id AS TEXT) = REGEXP_REPLACE(us.customer_id, '[^0-9]', '', 'g')
         LIMIT 1) AS customer_id,

        (SELECT employee_id FROM bl_3nf.ce_employees
         WHERE CAST(employee_src_id AS TEXT) = REGEXP_REPLACE(us.employee_id, '[^0-9]', '', 'g')
         LIMIT 1) AS employee_id,

        (SELECT branch_id FROM bl_3nf.ce_branches
         WHERE LOWER(branch_name) = LOWER(TRIM(us.branch))
           AND EXISTS (
               SELECT 1 FROM bl_3nf.ce_addresses a
               WHERE a.address_id = ce_branches.address_id
                 AND LOWER(a.city_name) = LOWER(TRIM(us.city))
           )
         LIMIT 1) AS branch_id,

        (SELECT channel_id FROM bl_3nf.ce_channels
         WHERE LOWER(channel_name) = LOWER(us.channel_name)
         LIMIT 1) AS channel_id,

        (SELECT product_id FROM bl_3nf.ce_products
         WHERE product_src_id = us.item_code
         LIMIT 1) AS product_id,

        (SELECT price_id FROM bl_3nf.ce_product_prices_scd
         WHERE product_id = (
             SELECT product_id FROM bl_3nf.ce_products WHERE product_src_id = us.item_code LIMIT 1
         )
         AND price_amt_act = CAST(us.unit_selling_price AS FLOAT)
         LIMIT 1) AS price_id,

        CAST(NULLIF(us.quantity_sold, '') AS INT) AS quantity_no,
        CAST(us.unit_selling_price AS FLOAT) AS unit_price_act,
        COALESCE(CAST(NULLIF(us.discount, '') AS FLOAT), 0.0) AS discount_act,
        COALESCE(CAST(NULLIF(us.total_sales, '') AS FLOAT), 0.0) AS amount_tot_act,
        COALESCE(CAST(NULLIF(us.cost, '') AS FLOAT), 0.0) AS cost_act,
        COALESCE(CAST(NULLIF(us.gross_income, '') AS FLOAT), 0.0) AS gross_income_act
    FROM unified_source us
)

SELECT *
FROM prepared_data p
WHERE date_id IS NOT NULL
  AND customer_id IS NOT NULL
  AND employee_id IS NOT NULL
  AND branch_id IS NOT NULL
  AND channel_id IS NOT NULL
  AND product_id IS NOT NULL
  AND price_id IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM bl_3nf.ce_sales t
      WHERE t.date_id = p.date_id
        AND t.customer_id = p.customer_id
        AND t.employee_id = p.employee_id
        AND t.branch_id = p.branch_id
        AND t.channel_id = p.channel_id
        AND t.product_id = p.product_id
        AND t.price_id = p.price_id
  );
$$;

--PROCEDURE
CREATE OR REPLACE PROCEDURE bl_cl.sp_load_ce_sales()
LANGUAGE plpgsql
AS $$
DECLARE
    v_start_time TIMESTAMP := clock_timestamp();
    v_rows_inserted INT := 0;
BEGIN
    -- Insert only new sales records not already in ce_sales
    INSERT INTO bl_3nf.ce_sales (
	 date_id,
    customer_id,
    employee_id,
    branch_id,
    channel_id,
    product_id,
    price_id,
    quantity_no,
    unit_price_act,
    discount_act,
    amount_tot_act,
    cost_act,
    gross_income_act
    )
    SELECT *
    FROM bl_cl.fn_get_new_3nf_ce_sales_rows();

    GET DIAGNOSTICS v_rows_inserted = ROW_COUNT;

    -- Log success
    INSERT INTO bl_cl.load_log (
        log_ts, procedure_name, rows_affected, log_message
    )
    VALUES (
        v_start_time, 'bl_cl.sp_load_ce_sales', v_rows_inserted,
        'SUCCESS: Inserted new CE_SALES records'
    );
EXCEPTION
    WHEN OTHERS THEN
        -- Log failure
        INSERT INTO bl_cl.load_log (
            log_ts, procedure_name, rows_affected, log_message
        )
        VALUES (
            v_start_time, 'bl_cl.sp_load_ce_sales', 0,
            'FAILURE: ' || SQLERRM
        );
        RAISE;
END;
$$;


select * from bl_cl.fn_get_new_3nf_ce_sales_rows()

CALL bl_cl.sp_load_ce_sales()

SELECT * 
FROM bl_cl.load_log
WHERE procedure_name = 'bl_cl.sp_load_ce_sales'
ORDER BY log_ts DESC;


--DIM_SALES
--PARTITIONS
ALTER TABLE bl_dm.fct_sales
PARTITION BY RANGE (date_id);

-- since this query sin't supported by postgres I had to recreate the table and add partitions there
ALTER TABLE bl_dm.fct_sales RENAME TO fct_sales_old;
 
BEGIN;
CREATE TABLE bl_dm.fct_sales (
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
    ta_update_dt        DATE NOT NULL,
    PRIMARY KEY (date_id, product_id, branch_id, customer_id, channel_id)
) PARTITION BY RANGE (date_id);
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

DROP TABLE bl_dm.fct_sales_old;


--ROLLING WINDOW
DO $$
DECLARE
    base_month DATE := date_trunc('month', CURRENT_DATE - INTERVAL '2 months');
    current_month DATE;
    next_month DATE;
    part_name TEXT;
    from_date_id BIGINT;
    to_date_id   BIGINT;
BEGIN
    FOR i IN 0..3 LOOP
        current_month := base_month + (i || ' month')::INTERVAL;
        next_month := current_month + INTERVAL '1 month';
        part_name := format('fct_sales_%s', to_char(current_month, 'YYYY_MM'));

        SELECT date_id INTO from_date_id
        FROM bl_3nf.ce_time_day
        WHERE date_src_id = current_month;

        SELECT date_id INTO to_date_id
        FROM bl_3nf.ce_time_day
        WHERE date_src_id = next_month;

        IF from_date_id IS NOT NULL AND to_date_id IS NOT NULL THEN
            EXECUTE format(
                'CREATE TABLE IF NOT EXISTS bl_dm.%I PARTITION OF bl_dm.fct_sales
                 FOR VALUES FROM (%L) TO (%L);',
                part_name, from_date_id, to_date_id
            );
        END IF;
    END LOOP;
END $$;

-- DETACHING AND DROPPING OLDER PARTITIONS
DO $$
DECLARE
    cutoff DATE := date_trunc('month', CURRENT_DATE - INTERVAL '3 months');
    part RECORD;
BEGIN
    FOR part IN
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'bl_dm'
          AND tablename LIKE 'fct_sales_%'
    LOOP
        IF to_date(substring(part.tablename from 11), 'YYYY_MM') < cutoff THEN
            EXECUTE format('ALTER TABLE bl_dm.fct_sales DETACH PARTITION bl_dm.%I;', part.tablename);
            EXECUTE format('DROP TABLE IF EXISTS bl_dm.%I;', part.tablename);
        END IF;
    END LOOP;
END $$;

-- FUNCTION
CREATE OR REPLACE FUNCTION bl_dm.fn_get_new_fct_sales_rows()
RETURNS TABLE (
    date_id BIGINT,
    customer_id BIGINT,
    employee_id BIGINT,
    product_id BIGINT,
    branch_id BIGINT,
    channel_id BIGINT,
    price_id BIGINT,
    quantity_act FLOAT,
    unit_price_act FLOAT,
    amount_act FLOAT,
    cost_act FLOAT,
    gross_income_act FLOAT,
    discount_act FLOAT
)
LANGUAGE SQL
AS $$
    SELECT
        s.date_id,
        s.customer_id,
        s.employee_id,
        s.product_id,
        s.branch_id,
        s.channel_id,
        s.price_id,
        s.quantity_no       AS quantity_act,
        s.unit_price_act    AS unit_price_act,
        s.amount_tot_act    AS amount_act,
        s.cost_act          AS cost_act,
        s.gross_income_act  AS gross_income_act,
        s.discount_act      AS discount_act
    FROM bl_3nf.ce_sales s
    WHERE s.date_id IN (
        SELECT date_id
        FROM bl_3nf.ce_time_day
        WHERE date_src_id >= date_trunc('month', CURRENT_DATE - INTERVAL '2 months')
    )
    AND NOT EXISTS (
        SELECT 1
        FROM bl_dm.fct_sales f
        WHERE f.date_id = s.date_id
          AND f.product_id = s.product_id
          AND f.branch_id = s.branch_id
          AND f.customer_id = s.customer_id
          AND f.channel_id = s.channel_id
          AND f.price_id = s.price_id
    );
$$;

-- 6. Refresh Procedure Using Deduplication
CREATE OR REPLACE PROCEDURE bl_dm.sp_refresh_dm_fact_sales()
LANGUAGE plpgsql
AS $$
DECLARE
    v_start_time TIMESTAMP := clock_timestamp();
    v_rows_inserted INT := 0;
BEGIN
    INSERT INTO bl_dm.fct_sales (
        date_id, customer_id, employee_id, product_id, branch_id,
        channel_id, price_id,
        quantity_act, unit_price_act, amount_act,
        cost_act, gross_income_act, discount_act,
        ta_insert_dt, ta_update_dt
    )
    SELECT
        date_id, customer_id, employee_id, product_id, branch_id,
        channel_id, price_id,
        quantity_act, unit_price_act, amount_act,
        cost_act, gross_income_act, discount_act,
        CURRENT_DATE, CURRENT_DATE
    FROM bl_dm.fn_get_new_fct_sales_rows();

    GET DIAGNOSTICS v_rows_inserted = ROW_COUNT;

    INSERT INTO etl_log (
        procedure_name, execution_ts, rows_inserted, status, message
    )
    VALUES (
        'bl_dm.sp_refresh_dm_fact_sales',
        v_start_time, v_rows_inserted,
        'SUCCESS', 'DM fact_sales refresh completed using deduplicated function'
    );

EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO etl_log (
            procedure_name, execution_ts, rows_inserted, status, message
        )
        VALUES (
            'bl_dm.sp_refresh_dm_fact_sales',
            v_start_time, 0,
            'FAILURE', SQLERRM
        );
        RAISE;
END;
$$;


select * from bl_dm.fn_get_new_fct_sales_rows()

CALL bl_cl.sp_load_ce_sales()


