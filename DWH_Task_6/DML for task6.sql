-- inserting default rows
-- CE_ADDRESSES
BEGIN;
INSERT INTO BL_3NF.CE_ADDRESSES (
    ADDRESS_ID, ADDRESS_LINE, CITY_NAME, REGION_NAME, POSTAL_CODE,
    COUNTRY_NAME, INSERT_DT, UPDATE_DT, SOURCE_SYSTEM, SOURCE_ENTITY
)
SELECT
    0, 'Unknown', 'Unknown', 'Unknown', '00000', 'Unknown',
    CURRENT_DATE, CURRENT_DATE, 'DEFAULT', 'DEFAULT'
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_ADDRESSES WHERE ADDRESS_ID = 0
);
COMMIT;
-- I was having issues with table employee and only solution I found was to hardcode adress_id to 0 and then
-- I reset sequence to avoid conflicts with manually inserted ID = 0
SELECT setval('BL_3NF.seq_address_id', GREATEST((SELECT MAX(ADDRESS_ID) FROM BL_3NF.CE_ADDRESSES), 1));

-- CE_CUSTOMERS
BEGIN;
INSERT INTO BL_3NF.CE_CUSTOMERS (
    CUSTOMER_SRC_ID, CUSTOMER_NAME, SEGMENT_NAME, ADDRESS_ID,
    INSERT_DT, UPDATE_DT, SOURCE_SYSTEM, SOURCE_ENTITY
)
SELECT 
    -1, 'Unknown', 'Unknown', 0,
    CURRENT_DATE, CURRENT_DATE, 'DEFAULT', 'DEFAULT'
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_CUSTOMERS WHERE CUSTOMER_SRC_ID = -1
);

-- CE_EMPLOYEES
INSERT INTO BL_3NF.CE_EMPLOYEES (
    EMPLOYEE_SRC_ID, EMPLOYEE_NAME, ROLE_NAME, HIRE_DT, ADDRESS_ID,
    INSERT_DT, UPDATE_DT, SOURCE_SYSTEM, SOURCE_ENTITY
)
SELECT 
    -1, 'Unknown', 'Unknown', DATE '1900-01-01', 0,
    CURRENT_DATE, CURRENT_DATE, 'DEFAULT', 'DEFAULT'
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_EMPLOYEES WHERE EMPLOYEE_SRC_ID = -1
);
COMMIT;

-- CE_BRANCHES
BEGIN;
INSERT INTO BL_3NF.CE_BRANCHES (
    BRANCH_SRC_ID, BRANCH_NAME, ADDRESS_ID,
    INSERT_DT, UPDATE_DT, SOURCE_SYSTEM, SOURCE_ENTITY
)
SELECT 
    -1, 'Unknown', 0,
    CURRENT_DATE, CURRENT_DATE, 'DEFAULT', 'DEFAULT'
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_BRANCHES WHERE BRANCH_SRC_ID = -1
);

-- CE_CHANNELS
INSERT INTO BL_3NF.CE_CHANNELS (
    CHANNEL_SRC_ID, CHANNEL_NAME, INSERT_DT, UPDATE_DT, SOURCE_SYSTEM, SOURCE_ENTITY
)
SELECT 
    -1, 'Unknown', CURRENT_DATE, CURRENT_DATE, 'DEFAULT', 'DEFAULT'
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_CHANNELS WHERE CHANNEL_SRC_ID = -1
);
COMMIT;

-- CE_TIME_DAY
BEGIN;
INSERT INTO BL_3NF.CE_TIME_DAY (
    DATE_SRC_ID, YEAR_NO, MONTH_NO, DAY_NO, WEEKDAY_NAME,
    INSERT_DT, UPDATE_DT, SOURCE_SYSTEM, SOURCE_ENTITY
)
SELECT 
    DATE '1900-01-01', 1900, 1, 1, 'Monday',
    CURRENT_DATE, CURRENT_DATE, 'DEFAULT', 'DEFAULT'
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_TIME_DAY WHERE DATE_SRC_ID = DATE '1900-01-01'
);
COMMIT;

-- CE_PRODUCT_CATEGORIES
BEGIN;
INSERT INTO BL_3NF.CE_PRODUCT_CATEGORIES (
    CATEGORY_SRC_ID, CATEGORY_NAME,
    INSERT_DT, UPDATE_DT, SOURCE_SYSTEM, SOURCE_ENTITY
)
SELECT 
    'n.a.', 'Unknown', CURRENT_DATE, CURRENT_DATE, 'DEFAULT', 'DEFAULT'
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_PRODUCT_CATEGORIES WHERE CATEGORY_SRC_ID = 'n.a.'
);

-- CE_PRODUCT_SUBCATEGORIES
INSERT INTO BL_3NF.CE_PRODUCT_SUBCATEGORIES (
    SUBCATEGORY_SRC_ID, SUBCATEGORY_NAME, CATEGORY_SRC_ID,
    INSERT_DT, UPDATE_DT, SOURCE_SYSTEM, SOURCE_ENTITY
)
SELECT 
    'n.a.', 'Unknown', 'n.a.', CURRENT_DATE, CURRENT_DATE, 'DEFAULT', 'DEFAULT'
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_PRODUCT_SUBCATEGORIES WHERE SUBCATEGORY_SRC_ID = 'n.a.'
);

-- CE_PRODUCTS
INSERT INTO BL_3NF.CE_PRODUCTS (
    PRODUCT_SRC_ID, PRODUCT_NAME, SUBCATEGORY_SRC_ID, LOSS_RATE_ACT,
    INSERT_DT, UPDATE_DT, SOURCE_SYSTEM, SOURCE_ENTITY
)
SELECT 
    'n.a.', 'Unknown', 'n.a.', 0.0,
    CURRENT_DATE, CURRENT_DATE, 'DEFAULT', 'DEFAULT'
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_PRODUCTS WHERE PRODUCT_SRC_ID = 'n.a.'
);

-- CE_PRODUCT_PRICES_SCD
INSERT INTO BL_3NF.CE_PRODUCT_PRICES_SCD (
    PRODUCT_ID, PRICE_TYPE_NAME, PRICE_AMT_ACT,
    START_DT, END_DT, IS_ACTIVE,
    INSERT_DT, UPDATE_DT, SOURCE_SYSTEM, SOURCE_ENTITY
)
SELECT 
    (SELECT PRODUCT_ID FROM BL_3NF.CE_PRODUCTS WHERE PRODUCT_SRC_ID = 'n.a.' LIMIT 1),
    'Default', 0.0,
    DATE '1900-01-01', DATE '9999-12-31', 'Y',
    CURRENT_DATE, CURRENT_DATE, 'DEFAULT', 'DEFAULT'
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_PRODUCT_PRICES_SCD WHERE PRICE_TYPE_NAME = 'Default'
);
COMMIT;


-- now I isert data in those tables

-- CE_ADDRESSES
BEGIN;
INSERT INTO BL_3NF.CE_ADDRESSES (
    ADDRESS_LINE, CITY_NAME, REGION_NAME, POSTAL_CODE, COUNTRY_NAME,
    INSERT_DT, UPDATE_DT, SOURCE_SYSTEM, SOURCE_ENTITY
)
SELECT DISTINCT
    COALESCE(NULLIF(src.branch, ''), 'Unknown') AS address_line,
    COALESCE(NULLIF(src.city, ''), 'Unknown') AS city_name,
    'Unknown' AS region_name,
    '00000' AS postal_code,
    'Unknown' AS country_name,
    CURRENT_DATE, CURRENT_DATE,
    'OFFLINE', 'SRC_OFFLINE_ORDERS'
FROM sa_offline.src_offline_orders src
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_ADDRESSES a WHERE a.ADDRESS_LINE = src.branch AND a.CITY_NAME = src.city
)
UNION
SELECT DISTINCT
    COALESCE(NULLIF(src.branch, ''), 'Unknown') AS address_line,
    COALESCE(NULLIF(src.city, ''), 'Unknown') AS city_name,
    'Unknown', '00000', 'Unknown',
    CURRENT_DATE, CURRENT_DATE,
    'ONLINE', 'SRC_ONLINE_ORDERS'
FROM sa_online.src_online_orders src
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_ADDRESSES a WHERE a.ADDRESS_LINE = src.branch AND a.CITY_NAME = src.city
);
COMMIT;

-- CE_CUSTOMERS
BEGIN;
WITH raw_customers AS (
    SELECT
        CAST(REGEXP_REPLACE(TRIM(customer_id), '[^0-9]', '', 'g') AS INT) AS customer_src_id,
        'OFFLINE' AS source_system,
        'SRC_OFFLINE_ORDERS' AS source_entity,
        ROW_NUMBER() OVER (PARTITION BY REGEXP_REPLACE(TRIM(customer_id), '[^0-9]', '', 'g') ORDER BY customer_id) AS rn
    FROM sa_offline.src_offline_orders
    WHERE TRIM(customer_id) ~ '[0-9]'

    UNION ALL

    SELECT
        CAST(REGEXP_REPLACE(TRIM(customer_id_1), '[^0-9]', '', 'g') AS INT) AS customer_src_id,
        'ONLINE' AS source_system,
        'SRC_ONLINE_ORDERS' AS source_entity,
        ROW_NUMBER() OVER (PARTITION BY REGEXP_REPLACE(TRIM(customer_id_1), '[^0-9]', '', 'g') ORDER BY customer_id_1) AS rn
    FROM sa_online.src_online_orders
    WHERE TRIM(customer_id_1) ~ '[0-9]'
),
deduplicated AS (
    SELECT * FROM raw_customers WHERE rn = 1
),
-- filtering out customers already inserted
final AS (
    SELECT * FROM deduplicated d
    WHERE NOT EXISTS (
        SELECT 1 FROM BL_3NF.CE_CUSTOMERS c
        WHERE c.CUSTOMER_SRC_ID = d.customer_src_id
    )
)
INSERT INTO BL_3NF.CE_CUSTOMERS (
    CUSTOMER_SRC_ID, CUSTOMER_NAME, SEGMENT_NAME, ADDRESS_ID,
    INSERT_DT, UPDATE_DT, SOURCE_SYSTEM, SOURCE_ENTITY
)
SELECT
    customer_src_id,
    'Unknown',
    'Unknown',
    0,  -- valid default fallback
    CURRENT_DATE, CURRENT_DATE,
    source_system, source_entity
FROM final;
COMMIT;


-- CE_PRODUCTS
BEGIN;
INSERT INTO BL_3NF.CE_PRODUCTS (
    PRODUCT_SRC_ID,
    PRODUCT_NAME,
    SUBCATEGORY_SRC_ID,
    LOSS_RATE_ACT,
    INSERT_DT,
    UPDATE_DT,
    SOURCE_SYSTEM,
    SOURCE_ENTITY
)
SELECT DISTINCT
    src.item_code AS product_src_id,
    'Unknown' AS product_name,
    COALESCE(NULLIF(src.category_code, ''), 'n.a.') AS subcategory_src_id,
    COALESCE(CAST(NULLIF(src.loss_rate, '') AS FLOAT), 0.0) AS loss_rate_act,
    CURRENT_DATE, CURRENT_DATE, 'OFFLINE', 'SRC_OFFLINE_ORDERS'
FROM sa_offline.src_offline_orders src
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_PRODUCTS p WHERE p.PRODUCT_SRC_ID = src.item_code
)
UNION
SELECT DISTINCT
    src.item_code AS product_src_id,
    COALESCE(NULLIF(src.item_name, ''), 'Unknown') AS product_name,
    COALESCE(NULLIF(src.category_code, ''), 'n.a.') AS subcategory_src_id,
    COALESCE(CAST(NULLIF(src.loss_rate, '') AS FLOAT), 0.0) AS loss_rate_act,
    CURRENT_DATE, CURRENT_DATE, 'ONLINE', 'SRC_ONLINE_ORDERS'
FROM sa_online.src_online_orders src
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_PRODUCTS p WHERE p.PRODUCT_SRC_ID = src.item_code
);
COMMIT;

-- CE_TIME_DAY
INSERT INTO BL_3NF.CE_TIME_DAY (
    DATE_SRC_ID, YEAR_NO, MONTH_NO, DAY_NO, WEEKDAY_NAME,
    INSERT_DT, UPDATE_DT, SOURCE_SYSTEM, SOURCE_ENTITY
)
SELECT
    d::DATE,
    EXTRACT(YEAR FROM d),
    EXTRACT(MONTH FROM d),
    EXTRACT(DAY FROM d),
    TRIM(TO_CHAR(d, 'Day')),
    CURRENT_DATE,
    CURRENT_DATE,
    'SYSTEM',
    'GENERATED'
FROM generate_series(DATE '2024-01-01', CURRENT_DATE, INTERVAL '1 day') d
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_TIME_DAY WHERE DATE_SRC_ID = d
);

-- CE_PRODUCT_PRICES_SCD
BEGIN;
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
    ) t
)
INSERT INTO BL_3NF.CE_PRODUCT_PRICES_SCD (
    PRODUCT_ID, PRICE_TYPE_NAME, PRICE_AMT_ACT,
    START_DT, END_DT, IS_ACTIVE,
    INSERT_DT, UPDATE_DT, SOURCE_SYSTEM, SOURCE_ENTITY
)
SELECT
    p.PRODUCT_ID,
    'Standard' AS PRICE_TYPE_NAME,
    CAST(src.unit_selling_price AS FLOAT),
    CURRENT_DATE,
    DATE '9999-12-31',
    'Y',
    CURRENT_DATE, CURRENT_DATE,
    'MERGED', 'SRC_ONLINE_AND_OFFLINE'
FROM src_combined src
JOIN BL_3NF.CE_PRODUCTS p
    ON p.PRODUCT_SRC_ID = src.item_code
WHERE NOT EXISTS (
    SELECT 1
    FROM BL_3NF.CE_PRODUCT_PRICES_SCD pp
    WHERE pp.PRODUCT_ID = p.PRODUCT_ID
      AND pp.PRICE_AMT_ACT = CAST(src.unit_selling_price AS FLOAT)
);
COMMIT;

-- CE_BRANCHES
BEGIN;
-- deduplicatng unique (branch, city) pairs across both sources
WITH distinct_branches AS (
    SELECT DISTINCT branch, city
    FROM sa_offline.src_offline_orders
    WHERE branch IS NOT NULL AND city IS NOT NULL
    UNION
    SELECT DISTINCT branch, city
    FROM sa_online.src_online_orders
    WHERE branch IS NOT NULL AND city IS NOT NULL
)
INSERT INTO BL_3NF.CE_BRANCHES (
    BRANCH_SRC_ID, BRANCH_NAME, ADDRESS_ID,
    INSERT_DT, UPDATE_DT, SOURCE_SYSTEM, SOURCE_ENTITY
)
SELECT
    COALESCE(CAST(NULLIF(REGEXP_REPLACE(branch, '[^0-9]', '', 'g'), '') AS INT), 0),
    branch,
    COALESCE((
        SELECT ADDRESS_ID
        FROM BL_3NF.CE_ADDRESSES a
        WHERE LOWER(TRIM(a.ADDRESS_LINE)) = LOWER(TRIM(db.branch))
          AND LOWER(TRIM(a.CITY_NAME)) = LOWER(TRIM(db.city))
        LIMIT 1
    ), 0),
    CURRENT_DATE, CURRENT_DATE,
    'MERGED', 'SRC_ONLINE_AND_OFFLINE'
FROM distinct_branches db;
COMMIT;


-- CE_CHANNELS
BEGIN;
INSERT INTO BL_3NF.CE_CHANNELS (
    CHANNEL_SRC_ID, CHANNEL_NAME, INSERT_DT, UPDATE_DT, SOURCE_SYSTEM, SOURCE_ENTITY
)
SELECT -1, 'Offline', CURRENT_DATE, CURRENT_DATE, 'MANUAL', 'MANUAL'
FROM (SELECT 1) dummy
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_CHANNELS
    WHERE LOWER(TRIM(CHANNEL_NAME)) = 'offline'
)
UNION
SELECT -2, 'Online', CURRENT_DATE, CURRENT_DATE, 'MANUAL', 'MANUAL'
FROM (SELECT 1) dummy
WHERE NOT EXISTS (
    SELECT 1 FROM BL_3NF.CE_CHANNELS
    WHERE LOWER(TRIM(CHANNEL_NAME)) = 'online'
);

COMMIT;



-- CE_EMPLOYEES
BEGIN;
-- I used this regex to remove unnecessary symbols in ID
WITH combined AS (
    SELECT
        REGEXP_REPLACE(TRIM(employee_id), '^[^0-9]+', '', 'g') AS cleaned_id,
        'OFFLINE' AS source_system,
        'SRC_OFFLINE_ORDERS' AS source_entity
    FROM sa_offline.src_offline_orders
    WHERE employee_id IS NOT NULL AND TRIM(employee_id) <> ''
    UNION ALL
    SELECT
        REGEXP_REPLACE(TRIM(employee_id), '^[^0-9]+', '', 'g'),
        'ONLINE',
        'SRC_ONLINE_ORDERS'
    FROM sa_online.src_online_orders
    WHERE employee_id IS NOT NULL AND TRIM(employee_id) <> ''
),
filtered AS (
    SELECT
        CAST(cleaned_id AS INT) AS employee_src_id,
        source_system,
        source_entity
    FROM combined
    WHERE cleaned_id ~ '^[0-9]+$'
),
deduplicated AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY employee_src_id ORDER BY source_system) AS rn
    FROM filtered
),
final AS (
    SELECT * FROM deduplicated
    WHERE rn = 1
      AND NOT EXISTS (
          SELECT 1 FROM BL_3NF.CE_EMPLOYEES e
          WHERE e.EMPLOYEE_SRC_ID = deduplicated.employee_src_id
      )
)
INSERT INTO BL_3NF.CE_EMPLOYEES (
    EMPLOYEE_SRC_ID, EMPLOYEE_NAME, ROLE_NAME, HIRE_DT, ADDRESS_ID,
    INSERT_DT, UPDATE_DT, SOURCE_SYSTEM, SOURCE_ENTITY
)
SELECT
    employee_src_id,
    'Unknown',
    'Unknown',
    DATE '1900-01-01',
    0,
    CURRENT_DATE, CURRENT_DATE,
    source_system, source_entity
FROM final;
COMMIT;



-- CE_PRODUCT_CATEGORIES
BEGIN;
INSERT INTO BL_3NF.CE_PRODUCT_CATEGORIES (
    CATEGORY_SRC_ID, CATEGORY_NAME,
    INSERT_DT, UPDATE_DT, SOURCE_SYSTEM, SOURCE_ENTITY
)
SELECT DISTINCT
    COALESCE(NULLIF(src.category_code, ''), 'n.a.') AS category_src_id,
    'Unknown' AS category_name,
    CURRENT_DATE, CURRENT_DATE, 'OFFLINE', 'SRC_OFFLINE_ORDERS'
FROM sa_offline.src_offline_orders src
WHERE NOT EXISTS (
    SELECT 1
    FROM BL_3NF.CE_PRODUCT_CATEGORIES c
    WHERE c.CATEGORY_SRC_ID = COALESCE(NULLIF(src.category_code, ''), 'n.a.')
)
UNION
SELECT DISTINCT
    COALESCE(NULLIF(src.category_code, ''), 'n.a.') AS category_src_id,
    COALESCE(NULLIF(src.category_name, ''), 'Unknown') AS category_name,
    CURRENT_DATE, CURRENT_DATE, 'ONLINE', 'SRC_ONLINE_ORDERS'
FROM sa_online.src_online_orders src
WHERE NOT EXISTS (
    SELECT 1
    FROM BL_3NF.CE_PRODUCT_CATEGORIES c
    WHERE c.CATEGORY_SRC_ID = COALESCE(NULLIF(src.category_code, ''), 'n.a.')
);
COMMIT;

-- CE_PRODUCT_SUBCATEGORIES
BEGIN;
INSERT INTO BL_3NF.CE_PRODUCT_SUBCATEGORIES (
    SUBCATEGORY_SRC_ID, SUBCATEGORY_NAME, CATEGORY_SRC_ID,
    INSERT_DT, UPDATE_DT, SOURCE_SYSTEM, SOURCE_ENTITY
)
SELECT DISTINCT
    COALESCE(NULLIF(src.category_code, ''), 'n.a.') AS subcategory_src_id,
    'Unknown' AS subcategory_name,
    COALESCE(NULLIF(src.category_code, ''), 'n.a.') AS category_src_id,
    CURRENT_DATE, CURRENT_DATE, 'OFFLINE', 'SRC_OFFLINE_ORDERS'
FROM sa_offline.src_offline_orders src
WHERE NOT EXISTS (
    SELECT 1
    FROM BL_3NF.CE_PRODUCT_SUBCATEGORIES s
    WHERE s.SUBCATEGORY_SRC_ID = COALESCE(NULLIF(src.category_code, ''), 'n.a.')
)
UNION
SELECT DISTINCT
    COALESCE(NULLIF(src.category_code, ''), 'n.a.') AS subcategory_src_id,
    COALESCE(NULLIF(src.category_name, ''), 'Unknown') AS subcategory_name,
    COALESCE(NULLIF(src.category_code, ''), 'n.a.') AS category_src_id,
    CURRENT_DATE, CURRENT_DATE, 'ONLINE', 'SRC_ONLINE_ORDERS'
FROM sa_online.src_online_orders src
WHERE NOT EXISTS (
    SELECT 1
    FROM BL_3NF.CE_PRODUCT_SUBCATEGORIES s
    WHERE s.SUBCATEGORY_SRC_ID = COALESCE(NULLIF(src.category_code, ''), 'n.a.')
);
COMMIT;

-- CE_SALES
-- in my source files date didn't have correct structure, so I had to create it using day month and year
BEGIN;
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
        (SELECT DATE_ID FROM BL_3NF.CE_TIME_DAY WHERE DATE_SRC_ID = us.sale_date) AS date_id,
        (SELECT CUSTOMER_ID FROM BL_3NF.CE_CUSTOMERS
         WHERE CUSTOMER_SRC_ID = CAST(REGEXP_REPLACE(us.customer_id, '[^0-9]', '', 'g') AS INT)
         LIMIT 1) AS customer_id,
        (SELECT EMPLOYEE_ID FROM BL_3NF.CE_EMPLOYEES
         WHERE EMPLOYEE_SRC_ID = CAST(REGEXP_REPLACE(us.employee_id, '[^0-9]', '', 'g') AS INT)
         LIMIT 1) AS employee_id,
        (SELECT BRANCH_ID FROM BL_3NF.CE_BRANCHES
         WHERE LOWER(BRANCH_NAME) = LOWER(TRIM(us.branch))
           AND EXISTS (
               SELECT 1 FROM BL_3NF.CE_ADDRESSES a
               WHERE a.ADDRESS_ID = BL_3NF.CE_BRANCHES.ADDRESS_ID
                 AND LOWER(a.CITY_NAME) = LOWER(TRIM(us.city))
           )
         LIMIT 1) AS branch_id,
        (SELECT CHANNEL_ID FROM BL_3NF.CE_CHANNELS
         WHERE LOWER(CHANNEL_NAME) = LOWER(us.channel_name)
         LIMIT 1) AS channel_id,
        (SELECT PRODUCT_ID FROM BL_3NF.CE_PRODUCTS
         WHERE PRODUCT_SRC_ID = us.item_code
         LIMIT 1) AS product_id,
        (SELECT PRICE_ID FROM BL_3NF.CE_PRODUCT_PRICES_SCD
         WHERE PRODUCT_ID = (
             SELECT PRODUCT_ID FROM BL_3NF.CE_PRODUCTS WHERE PRODUCT_SRC_ID = us.item_code LIMIT 1
         )
         AND PRICE_AMT_ACT = CAST(us.unit_selling_price AS FLOAT)
         LIMIT 1) AS price_id,
        CAST(NULLIF(us.quantity_sold, '') AS INT) AS quantity_no,
        CAST(us.unit_selling_price AS FLOAT) AS unit_price_act,
        COALESCE(CAST(NULLIF(us.discount, '') AS FLOAT), 0.0) AS discount_act,
        COALESCE(CAST(NULLIF(us.total_sales, '') AS FLOAT), 0.0) AS amount_tot_act,
        COALESCE(CAST(NULLIF(us.cost, '') AS FLOAT), 0.0) AS cost_act,
        COALESCE(CAST(NULLIF(us.gross_income, '') AS FLOAT), 0.0) AS gross_income_act
    FROM unified_source us
),

final_deduplicated AS (
    SELECT DISTINCT *
    FROM prepared_data
    WHERE date_id IS NOT NULL
      AND customer_id IS NOT NULL
      AND employee_id IS NOT NULL
      AND branch_id IS NOT NULL
      AND channel_id IS NOT NULL
      AND product_id IS NOT NULL
      AND price_id IS NOT NULL
)

INSERT INTO BL_3NF.CE_SALES (
    DATE_ID, CUSTOMER_ID, EMPLOYEE_ID, BRANCH_ID, CHANNEL_ID,
    PRODUCT_ID, PRICE_ID,
    QUANTITY_NO, UNIT_PRICE_ACT, DISCOUNT_ACT,
    AMOUNT_TOT_ACT, COST_ACT, GROSS_INCOME_ACT
)
SELECT
    date_id, customer_id, employee_id, branch_id, channel_id,
    product_id, price_id,
    quantity_no, unit_price_act, discount_act,
    amount_tot_act, cost_act, gross_income_act
FROM final_deduplicated;

COMMIT;


-- now I check if the data was correctly loaded

-- CE_CUSTOMERS
WITH src AS (
    SELECT
        (SELECT COUNT(DISTINCT customer_id) FROM sa_offline.src_offline_orders) +
        (SELECT COUNT(DISTINCT customer_id_1) FROM sa_online.src_online_orders) AS count
),
bl AS (
    SELECT COUNT(*) - 1 AS cnt  -- exclude default row
    FROM BL_3NF.CE_CUSTOMERS
)
SELECT src.count AS src_cnt, bl.cnt AS bl_cnt,
       CASE WHEN src.count = bl.cnt THEN 'OK' ELSE 'Mismatch' END AS status
FROM src, bl;

-- CE_PRODUCTS
WITH src AS (
    SELECT
        COALESCE((SELECT COUNT(DISTINCT item_code) FROM sa_offline.src_offline_orders), 0) +
        COALESCE((SELECT COUNT(DISTINCT item_code) FROM sa_online.src_online_orders), 0) AS cnt
),
bl AS (
    SELECT COUNT(*) - 1 AS cnt
    FROM BL_3NF.CE_PRODUCTS
)
SELECT src.cnt, bl.cnt,
    CASE WHEN src.cnt = bl.cnt THEN 'OK' ELSE 'Mismatch' END AS status
FROM src, bl;

-- CE_PRODUCT_CATEGORIES
WITH src AS (
    SELECT
        COALESCE((SELECT COUNT(DISTINCT category_code) FROM sa_offline.src_offline_orders), 0) +
        COALESCE((SELECT COUNT(DISTINCT category_code) FROM sa_online.src_online_orders), 0) AS cnt
),
bl AS (
    SELECT COUNT(*) - 1 AS cnt
    FROM BL_3NF.CE_PRODUCT_CATEGORIES
)
SELECT src.cnt, bl.cnt,
    CASE WHEN src.cnt = bl.cnt THEN 'OK' ELSE 'Mismatch' END AS status
FROM src, bl;


-- CE_PRODUCT_SUBCATEGORIES
WITH src AS (
    SELECT
        COALESCE((SELECT COUNT(DISTINCT category_code) FROM sa_offline.src_offline_orders), 0) +
        COALESCE((SELECT COUNT(DISTINCT category_code) FROM sa_online.src_online_orders), 0) AS cnt
),
bl AS (
    SELECT COUNT(*) - 1 AS cnt
    FROM BL_3NF.CE_PRODUCT_SUBCATEGORIES
)
SELECT src.cnt, bl.cnt,
    CASE WHEN src.cnt = bl.cnt THEN 'OK' ELSE 'Mismatch' END AS status
FROM src, bl;


-- CE_BRANCHES
WITH src AS (
    SELECT COUNT(DISTINCT branch || '|' || city) AS count
    FROM (
        SELECT branch, city FROM sa_offline.src_offline_orders
        UNION
        SELECT branch, city FROM sa_online.src_online_orders
    ) s
    WHERE branch IS NOT NULL AND city IS NOT NULL
),
bl AS (
    SELECT COUNT(*) AS cnt
    FROM BL_3NF.CE_BRANCHES
    WHERE BRANCH_SRC_ID != -1  -- excluding default
)
SELECT src.count AS src_cnt, bl.cnt AS bl_cnt,
    CASE WHEN src.count = bl.cnt THEN 'OK' ELSE 'Mismatch' END AS status
FROM src, bl;


-- CE_EMPLOYEES --
WITH src AS (
    SELECT COUNT(DISTINCT REGEXP_REPLACE(TRIM(employee_id), '^[^0-9]+', '', 'g')) AS count
    FROM (
        SELECT employee_id FROM sa_offline.src_offline_orders
        UNION ALL
        SELECT employee_id FROM sa_online.src_online_orders
    ) all_employees
    WHERE employee_id IS NOT NULL AND TRIM(employee_id) <> ''
),
bl AS (
    SELECT COUNT(*) - 1 AS cnt  -- exclude default row
    FROM BL_3NF.CE_EMPLOYEES
)
SELECT src.count AS src_cnt, bl.cnt AS bl_cnt,
       CASE WHEN src.count = bl.cnt THEN 'OK ' ELSE 'Mismatch' END AS status
FROM src, bl;

-- CE_ADDRESSES
WITH src AS (
    SELECT
        COALESCE((
            SELECT COUNT(DISTINCT branch || '|' || city)
            FROM sa_offline.src_offline_orders
            WHERE branch IS NOT NULL AND city IS NOT NULL
        ), 0) +
        COALESCE((
            SELECT COUNT(DISTINCT branch || '|' || city)
            FROM sa_online.src_online_orders
            WHERE branch IS NOT NULL AND city IS NOT NULL
        ), 0) AS cnt
),
bl AS (
    SELECT COUNT(*) - 1 AS cnt -- exclude default row
    FROM BL_3NF.CE_ADDRESSES
)
SELECT
    src.cnt AS src_count,
    bl.cnt AS bl_count,
    CASE
        WHEN src.cnt = bl.cnt THEN 'OK'
        ELSE 'Mismatch'
    END AS status
FROM src, bl;

-- CE_PRODUCT_PRICE_SCD
WITH src AS (
    SELECT
        (SELECT COUNT(DISTINCT item_code || '|' || unit_selling_price)
         FROM sa_offline.src_offline_orders
         WHERE unit_selling_price IS NOT NULL AND unit_selling_price <> '')
        +
        (SELECT COUNT(DISTINCT item_code || '|' || unit_selling_price)
         FROM sa_online.src_online_orders
         WHERE unit_selling_price IS NOT NULL AND unit_selling_price <> '')
        AS count
),
bl AS (
    SELECT COUNT(*) - 1 AS cnt -- exclude default row
    FROM BL_3NF.CE_PRODUCT_PRICES_SCD
)
SELECT src.count AS src_cnt, bl.cnt AS bl_cnt,
    CASE WHEN src.count = bl.cnt THEN 'OK' ELSE 'Mismatch' END AS status
FROM src, bl;

-- CE_SALES
-- CE_SALES validation
WITH src AS (
    SELECT
        -- count of rows with valid numeric unit_selling_price and item_code from OFFLINE
        (SELECT COUNT(*)
         FROM sa_offline.src_offline_orders
         WHERE TRIM(item_code) <> ''
           AND unit_selling_price ~ '^[0-9.]+$'
           AND year ~ '^\d{4}$' AND month ~ '^\d{1,2}$' AND day ~ '^\d{1,2}$') +

        -- count of rows with valid numeric unit_selling_price and item_code from ONLINE
        (SELECT COUNT(*)
         FROM sa_online.src_online_orders
         WHERE TRIM(item_code) <> ''
           AND unit_selling_price ~ '^[0-9.]+$'
           AND year ~ '^\d{4}$' AND month ~ '^\d{1,2}$' AND day ~ '^\d{1,2}$')
        AS src_cnt
),
bl AS (
    SELECT COUNT(*) AS bl_cnt
    FROM BL_3NF.CE_SALES
)
SELECT src.src_cnt, bl.bl_cnt,
       CASE WHEN src.src_cnt = bl.bl_cnt THEN 'OK' ELSE 'Mismatch' END AS status
FROM src, bl;
