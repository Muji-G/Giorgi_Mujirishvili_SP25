-- Ensure the composite type exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_type t
        JOIN pg_namespace n ON n.oid = t.typnamespace
        WHERE t.typname = 'tp_ce_sales_row'
          AND n.nspname = 'bl_cl'
    ) THEN
        CREATE TYPE bl_cl.tp_ce_sales_row AS (
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
            gross_income_act FLOAT,
            source_system    TEXT,
            source_entity    TEXT
        );
    END IF;
END;
$$;


-- Resolver function
CREATE OR REPLACE FUNCTION bl_cl.fn_resolve_ce_sales_record(
    p_order_date    DATE,
    p_customer_src  TEXT,
    p_employee_src  TEXT,
    p_branch_src    TEXT,
    p_channel_src   TEXT,
    p_product_src   TEXT,
    p_unit_price    FLOAT,
    p_quantity      INT,
    p_unit_price2   FLOAT,
    p_discount      FLOAT,
    p_amount_tot    FLOAT,
    p_cost          FLOAT,
    p_gross_income  FLOAT,
    p_source_system TEXT,
    p_source_entity TEXT
)
RETURNS bl_cl.tp_ce_sales_row
LANGUAGE plpgsql
AS $$
DECLARE
    v_date_id     BIGINT;
    v_customer_id BIGINT;
    v_employee_id BIGINT;
    v_branch_id   BIGINT;
    v_channel_id  BIGINT;
    v_product_id  BIGINT;
    v_price_id    BIGINT;
    rec bl_cl.tp_ce_sales_row;
BEGIN
    SELECT date_id INTO v_date_id
      FROM bl_3nf.ce_time_day
     WHERE date_src_id = p_order_date;
    IF v_date_id IS NULL THEN RETURN NULL; END IF;

    SELECT customer_id INTO v_customer_id
      FROM bl_3nf.ce_customers
     WHERE customer_src_id::text = p_customer_src
       AND source_system = p_source_system;
    IF v_customer_id IS NULL THEN RETURN NULL; END IF;

    SELECT employee_id INTO v_employee_id
      FROM bl_3nf.ce_employees
     WHERE employee_src_id::text = p_employee_src;
    IF v_employee_id IS NULL THEN RETURN NULL; END IF;

    SELECT branch_id INTO v_branch_id
      FROM bl_3nf.ce_branches
     WHERE branch_src_id::text = p_branch_src
        OR LOWER(branch_name) = LOWER(p_branch_src)
     LIMIT 1;
    IF v_branch_id IS NULL THEN RETURN NULL; END IF;

    SELECT channel_id INTO v_channel_id
      FROM bl_3nf.ce_channels
     WHERE channel_src_id::text = p_channel_src
        OR LOWER(channel_name) = LOWER(p_channel_src)
     LIMIT 1;
    IF v_channel_id IS NULL THEN RETURN NULL; END IF;

    SELECT product_id INTO v_product_id
      FROM bl_3nf.ce_products
     WHERE product_src_id::text = p_product_src;
    IF v_product_id IS NULL THEN RETURN NULL; END IF;

    SELECT price_id INTO v_price_id
      FROM bl_3nf.ce_product_prices_scd
     WHERE product_id = v_product_id
       AND price_amt_act = p_unit_price
       AND (is_active IN ('Y','y') OR is_active::text ILIKE 'true')
     LIMIT 1;

    IF v_price_id IS NULL THEN
        SELECT price_id INTO v_price_id
          FROM bl_3nf.ce_product_prices_scd
         WHERE product_id = v_product_id
           AND (is_active IN ('Y','y') OR is_active::text ILIKE 'true')
         ORDER BY start_dt DESC
         LIMIT 1;
        IF v_price_id IS NULL THEN RETURN NULL; END IF;
    END IF;

    rec := ROW(v_date_id, v_customer_id, v_employee_id, v_branch_id, v_channel_id, v_product_id, v_price_id,
               p_quantity, p_unit_price2, p_discount, p_amount_tot, p_cost, p_gross_income,
               p_source_system, p_source_entity);
    RETURN rec;
END;
$$;

-- Function to return only new rows
CREATE OR REPLACE FUNCTION bl_cl.fn_get_new_ce_sales()
RETURNS SETOF bl_cl.tp_ce_sales_row
LANGUAGE plpgsql
AS $$
DECLARE
    rec bl_cl.tp_ce_sales_row;
BEGIN
    -- Online orders
    FOR rec IN
        SELECT
            (sub.r).date_id,
            (sub.r).customer_id,
            (sub.r).employee_id,
            (sub.r).branch_id,
            (sub.r).channel_id,
            (sub.r).product_id,
            (sub.r).price_id,
            (sub.r).quantity_no,
            (sub.r).unit_price_act,
            (sub.r).discount_act,
            (sub.r).amount_tot_act,
            (sub.r).cost_act,
            (sub.r).gross_income_act,
            (sub.r).source_system,
            (sub.r).source_entity
        FROM (
            SELECT bl_cl.fn_resolve_ce_sales_record(
                MAKE_DATE(o.year::INT, o.month::INT, o.day::INT),
                o.customer_id_1::text,
                o.employee_id::text,
                o.branch::text,
                'ONLINE',
                o.item_code::text,
                o.unit_selling_price::FLOAT,
                o.quantity_sold::INT,
                o.unit_selling_price::FLOAT,
                o.discount::FLOAT,
                o.total_sales::FLOAT,
                o.cost::FLOAT,
                o.gross_income::FLOAT,
                'Online',
                'SRC_ONLINE_ORDERS'
            ) AS r
            FROM sa_online.src_online_orders o
        ) sub
        WHERE sub.r IS NOT NULL
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM bl_3nf.ce_sales s
            WHERE s.date_id = rec.date_id AND s.customer_id = rec.customer_id
              AND s.employee_id = rec.employee_id AND s.branch_id = rec.branch_id
              AND s.channel_id = rec.channel_id AND s.product_id = rec.product_id
              AND s.price_id = rec.price_id
        ) THEN
            RETURN NEXT rec;
        END IF;
    END LOOP;

    -- Offline orders
    FOR rec IN
        SELECT
            (sub.r).date_id,
            (sub.r).customer_id,
            (sub.r).employee_id,
            (sub.r).branch_id,
            (sub.r).channel_id,
            (sub.r).product_id,
            (sub.r).price_id,
            (sub.r).quantity_no,
            (sub.r).unit_price_act,
            (sub.r).discount_act,
            (sub.r).amount_tot_act,
            (sub.r).cost_act,
            (sub.r).gross_income_act,
            (sub.r).source_system,
            (sub.r).source_entity
        FROM (
            SELECT bl_cl.fn_resolve_ce_sales_record(
                MAKE_DATE(o.year::INT, o.month::INT, o.day::INT),
                o.customer_id::text,
                o.employee_id::text,
                o.branch::text,
                'OFFLINE',
                o.item_code::text,
                o.unit_selling_price::FLOAT,
                o.quantity_sold::INT,
                o.unit_selling_price::FLOAT,
                o.discount::FLOAT,
                o.total_sales::FLOAT,
                o.cost::FLOAT,
                o.gross_income::FLOAT,
                'Offline',
                'SRC_OFFLINE_ORDERS'
            ) AS r
            FROM sa_offline.src_offline_orders o
        ) sub
        WHERE sub.r IS NOT NULL
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM bl_3nf.ce_sales s
            WHERE s.date_id = rec.date_id AND s.customer_id = rec.customer_id
              AND s.employee_id = rec.employee_id AND s.branch_id = rec.branch_id
              AND s.channel_id = rec.channel_id AND s.product_id = rec.product_id
              AND s.price_id = rec.price_id
        ) THEN
            RETURN NEXT rec;
        END IF;
    END LOOP;
    RETURN;
END;
$$;


-- Load procedure
CREATE OR REPLACE PROCEDURE bl_cl.sp_load_ce_sales()
LANGUAGE plpgsql
AS $$
DECLARE
    rec bl_cl.tp_ce_sales_row;
    v_rows_inserted INT := 0;
    cur REFCURSOR;
BEGIN
    OPEN cur FOR SELECT * FROM bl_cl.fn_get_new_ce_sales();
    LOOP
        FETCH cur INTO rec;
        EXIT WHEN NOT FOUND;
        INSERT INTO bl_3nf.ce_sales (
            date_id, customer_id, employee_id, branch_id, channel_id,
            product_id, price_id, quantity_no, unit_price_act,
            discount_act, amount_tot_act, cost_act, gross_income_act
        ) VALUES (
            rec.date_id, rec.customer_id, rec.employee_id, rec.branch_id, rec.channel_id,
            rec.product_id, rec.price_id, rec.quantity_no, rec.unit_price_act,
            rec.discount_act, rec.amount_tot_act, rec.cost_act, rec.gross_income_act
        );
        v_rows_inserted := v_rows_inserted + 1;
    END LOOP;
    CLOSE cur;
    CALL bl_cl.pr_log_etl_event(
        'sp_load_ce_sales',
        v_rows_inserted,
        CASE WHEN v_rows_inserted > 0 THEN
            'Inserted ' || v_rows_inserted || ' new CE_SALES rows.'
        ELSE
            'No new CE_SALES rows to insert.'
        END
    );
END;
$$;

-- Preview new rows without inserting
SELECT * FROM bl_cl.fn_get_new_ce_sales();
-- Load new rows
CALL bl_cl.sp_load_ce_sales();
-- Check CE_SALES contents
SELECT * FROM bl_3nf.ce_sales ORDER BY date_id DESC;
-- Review the ETL log
SELECT * FROM bl_cl.log_etl_executions
-- WHERE procedure_name = 'sp_load_ce_sales'
ORDER BY log_dt DESC;




-- Procedure: pr_load_fct_sales_dm

CREATE OR REPLACE PROCEDURE bl_cl.pr_load_fct_sales_dm(
    p_months_back INT DEFAULT 3
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_now        DATE := CURRENT_DATE;
    v_start_win  DATE;
    v_end_win    DATE := (date_trunc('month', v_now) + INTERVAL '1 month')::DATE;
    v_part_start DATE;
    v_part_end   DATE;
    v_part_name  TEXT;
    v_rows       INTEGER := 0;
BEGIN
    IF p_months_back < 1 THEN
        p_months_back := 1;
    END IF;
    -- Determine start of rolling window: e.g. if p_months_back = 3 and
    -- today is 2025-08-15, start at the first day of June 2025
    v_start_win := (date_trunc('month', v_now) - (p_months_back - 1) * INTERVAL '1 month')::DATE;

    -- Build a temporary staging table with new fact rows for the window
    -- Only select rows from CE_SALES whose date falls within the window
    -- and which do not already exist in the DM fact table.
    DROP TABLE IF EXISTS pg_temp.stg_fct_sales;
    CREATE TEMP TABLE stg_fct_sales AS
    SELECT
        s.date_id,
        s.customer_id,
        s.employee_id,
        s.product_id,
        s.branch_id,
        s.channel_id,
        s.price_id,
        s.quantity_no      AS quantity_act,
        s.unit_price_act   AS unit_price_act,
        s.amount_tot_act   AS amount_act,
        s.cost_act         AS cost_act,
        s.gross_income_act AS gross_income_act,
        s.discount_act     AS discount_act,
        CURRENT_DATE       AS ta_insert_dt,
        CURRENT_DATE       AS ta_update_dt
    FROM bl_3nf.ce_sales s
    JOIN bl_dm.dim_dates d ON d.date_id = s.date_id
    WHERE d.date_act >= v_start_win
      AND d.date_act <  v_end_win
      AND NOT EXISTS (
            SELECT 1
            FROM bl_dm.fct_sales f
            WHERE f.date_id     = s.date_id
              AND f.customer_id = s.customer_id
              AND f.employee_id = s.employee_id
              AND f.branch_id   = s.branch_id
              AND f.channel_id  = s.channel_id
              AND f.product_id  = s.product_id
              AND f.price_id    = s.price_id
        );

    -- Iterate through each month in the window
    v_part_start := v_start_win;
    WHILE v_part_start < v_end_win LOOP
        v_part_end := (v_part_start + INTERVAL '1 month')::DATE;
        v_part_name := format('fct_sales_%s', to_char(v_part_start, 'YYYYMM'));

        -- Detach and drop existing partition if it exists
        EXECUTE format('ALTER TABLE bl_dm.fct_sales DETACH PARTITION IF EXISTS %I', v_part_name);
        EXECUTE format('DROP TABLE IF EXISTS bl_dm.%I', v_part_name);

        -- Create a fresh partition for the month
        EXECUTE format(
            'CREATE TABLE bl_dm.%I PARTITION OF bl_dm.fct_sales FOR VALUES FROM (%L) TO (%L)',
            v_part_name, v_part_start, v_part_end
        );

        -- Insert data for this month from the staging table
        EXECUTE format(
            'INSERT INTO bl_dm.fct_sales (
                date_id, customer_id, employee_id, product_id, branch_id,
                channel_id, quantity_act, unit_price_act, amount_act,
                cost_act, gross_income_act, discount_act, ta_insert_dt,
                ta_update_dt, price_id
            )
            SELECT date_id, customer_id, employee_id, product_id, branch_id,
                   channel_id, quantity_act, unit_price_act, amount_act,
                   cost_act, gross_income_act, discount_act, ta_insert_dt,
                   ta_update_dt, price_id
            FROM pg_temp.stg_fct_sales
            WHERE date_id >= %L AND date_id < %L',
            v_part_start, v_part_end
        );
        -- Update row count
        GET DIAGNOSTICS v_rows = v_rows + ROW_COUNT;

        v_part_start := v_part_end;
    END LOOP;

    -- Log the result
    CALL bl_cl.pr_log_etl_event(
        'pr_load_fct_sales_dm',
        v_rows,
        CASE WHEN v_rows > 0 THEN 'Loaded ' || v_rows || ' fact rows into DM.' ELSE 'No fact rows loaded.' END
    );
END;
$$;



 CALL bl_cl.pr_load_fct_sales_dm();
 CALL bl_cl.pr_load_fct_sales_dm();  -- second run should insert zero rows
 SELECT * FROM bl_cl.log_etl_executions
   WHERE procedure_name = 'pr_load_fct_sales_dm'
   ORDER BY log_dt DESC;
 
 

SELECT relname AS partition_name
FROM pg_catalog.pg_class c
JOIN pg_catalog.pg_inherits i ON c.oid = i.inhrelid
JOIN pg_catalog.pg_class p ON i.inhparent = p.oid
WHERE p.relname = 'fct_sales';


SELECT date_id, customer_id, employee_id, product_id, branch_id, channel_id, price_id, COUNT(*)
FROM bl_dm.fct_sales
WHERE date_id >= (SELECT date_id FROM bl_dm.dim_dates WHERE date_act = date_trunc('month', CURRENT_DATE) - INTERVAL '2 months')
GROUP BY 1,2,3,4,5,6,7
HAVING COUNT(*) > 1;


SELECT COUNT(*) AS missing_fact_rows
FROM (
    SELECT s.date_id, s.customer_id, s.employee_id, s.product_id, s.branch_id, s.channel_id, s.price_id
    FROM bl_3nf.ce_sales s
    JOIN bl_dm.dim_dates d ON d.date_id = s.date_id
    WHERE d.date_act >= (date_trunc('month', CURRENT_DATE) - INTERVAL '2 months')
      AND d.date_act <  (date_trunc('month', CURRENT_DATE) + INTERVAL '1 month')
    EXCEPT
    SELECT date_id, customer_id, employee_id, product_id, branch_id, channel_id, price_id
    FROM bl_dm.fct_sales
    WHERE date_id >= (SELECT date_id FROM bl_dm.dim_dates WHERE date_act = date_trunc('month', CURRENT_DATE) - INTERVAL '2 months')
) missing;