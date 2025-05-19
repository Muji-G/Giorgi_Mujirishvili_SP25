-- TASK 1

WITH sales_per_channel AS (
  SELECT
    chnl.channel_desc, con.country_region,

    -- Quantity sold in each channel, each country
    SUM(sls.quantity_sold) AS sales_count,
    -- Maximum of SUM(quantity_sales) for each channel
    MAX(SUM(sls.quantity_sold)) OVER (
      PARTITION BY chnl.channel_desc
      ) AS max_sales_count,
    -- Summary quantity_sales for each channel
    SUM(SUM(sls.quantity_sold)) OVER (
      PARTITION BY chnl.channel_desc
      ) AS sum_sales_count
  FROM sh.sales sls
    LEFT JOIN sh.channels chnl ON chnl.channel_id = sls.channel_id
    LEFT JOIN sh.customers cus ON cus.cust_id = sls.cust_id
    LEFT JOIN sh.countries con ON con.country_id = cus.country_id
  GROUP BY chnl.channel_desc, con.country_region
)
SELECT
  spc.channel_desc, spc.country_region,
  -- Round and format sales_count
  TO_CHAR(ROUND(spc.sales_count, 2), '9,999,999,999.99') AS sales,
  -- Calculate, round and format percentage
  TO_CHAR(ROUND(100*spc.max_sales_count / spc.sum_sales_count, 2), '999.99%') AS "SALES %"
FROM sales_per_channel spc
WHERE spc.sales_count = spc.max_sales_count
ORDER BY spc.sales_count DESC
;


-- TASK 2

WITH calc_prev_year_sales AS (
  SELECT
    prd.prod_subcategory_id,
    prd.prod_subcategory_desc,
    t.calendar_year,
    SUM(sls.amount_sold) AS total_sales, -- Sales from this year
    -- Sales from last year (no values with year 1997 so substitute with 0)
    COALESCE(LAG(SUM(sls.amount_sold), 1) OVER (
      PARTITION BY prd.prod_subcategory_id
      ORDER BY t.calendar_year
      ), 0) AS prev_total_sales
  FROM sh.sales sls
    LEFT JOIN sh.products prd
      ON sls.prod_id = prd.prod_id
    LEFT JOIN sh.times t
      ON sls.time_id = t.time_id
  GROUP BY prd.prod_subcategory_id, prd.prod_subcategory_desc, t.calendar_year
)
SELECT DISTINCT
  cpys.prod_subcategory_desc
FROM calc_prev_year_sales cpys
-- Now take only subcategories, ids of which are not in list of subcategories
-- which have at least one year with negative profit
WHERE cpys.prod_subcategory_id NOT IN (SELECT DISTINCT
                                          cpys.prod_subcategory_id
                                        FROM calc_prev_year_sales cpys
                                        WHERE cpys.total_sales - cpys.prev_total_sales <= 0)
ORDER BY cpys.prod_subcategory_desc
;

-- TASK 3

WITH calc_diff_sales AS (
  SELECT
    t.calendar_year,
    t.calendar_quarter_desc,
    prd.prod_category_desc,
    SUM(sls.amount_sold) AS sum_sales,
    FIRST_VALUE(SUM(sls.amount_sold)) OVER (
      PARTITION BY t.calendar_year, prd.prod_category_desc
      ORDER BY t.calendar_quarter_desc
      ) AS first_q_sum_sales,
    SUM(SUM(sls.amount_sold)) OVER (
      PARTITION BY t.calendar_year
      ORDER BY t.calendar_quarter_desc
      -- Here I tried with and without window frame and result was the same
      -- Since we need cum_sum by quarters I chose range, because
      -- quarters are present 3 times for each category
      RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
--       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
      ) AS cum_sum$
  FROM sh.sales sls
   LEFT JOIN sh.products prd ON prd.prod_id = sls.prod_id
   LEFT JOIN sh.times t ON sls.time_id = t.time_id
   LEFT JOIN sh.channels chnl ON sls.channel_id = chnl.channel_id
  WHERE
    t.calendar_year IN (1999, 2000) AND
    lower(chnl.channel_desc) IN ('partners', 'internet') AND
    lower(prd.prod_category_desc) IN ('electronics', 'hardware', 'software/other')
  GROUP BY t.calendar_year, t.calendar_quarter_desc, prd.prod_category_desc)
SELECT
  cds.calendar_year,
  cds.calendar_quarter_desc,
  cds.prod_category_desc,
  TO_CHAR(ROUND(cds.sum_sales, 2), '9,999,999,999.99') AS sales$,
  CASE
    WHEN cds.sum_sales-cds.first_q_sum_sales = 0
      THEN 'N/A'
    ELSE
      TO_CHAR(ROUND(100*(cds.sum_sales-cds.first_q_sum_sales)/cds.first_q_sum_sales, 2), '999.99%')
    END AS diff_percent,
  TO_CHAR(cds.cum_sum$, '9,999,999,999.99') AS cum_sum$
FROM calc_diff_sales cds
ORDER BY cds.calendar_year, cds.calendar_quarter_desc, sales$ DESC
;
