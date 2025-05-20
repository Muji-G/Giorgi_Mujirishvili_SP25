SET search_path TO sh;

--Task 1
--Create a query to produce a sales report highlighting the top customers with the highest sales across different sales channels. 
--This report should list the top 5 customers for each channel. 
--Additionally, calculate a key performance indicator (KPI) called 'sales_percentage,' 
--which represents the percentage of a customer's sales relative to the total sales within their respective channel.
--Please format the columns as follows:
--Display the total sales amount with two decimal places
--Display the sales percentage with four decimal places and include the percent sign (%) at the end
--Display the result for each channel in descending order of sales


WITH cst AS (
    SELECT 
        cust_id,
        channel_id,
        SUM(amount_sold) AS amount_sold,
        RANK() OVER (PARTITION BY channel_id ORDER BY SUM(amount_sold) DESC) AS sales_rank,
        SUM(SUM(amount_sold)) OVER (PARTITION BY channel_id) AS channel_sales
    FROM sales
    GROUP BY cust_id, channel_id
)
SELECT 
    cha.channel_desc,
    cus.cust_last_name,
    cus.cust_first_name,
    cst.amount_sold::DECIMAL(10,2),
    TO_CHAR(cst.amount_sold * 100.0 / cst.channel_sales, 'FM999.0000%') AS sales_percentage
FROM cst
INNER JOIN customers cus ON cus.cust_id = cst.cust_id 
INNER JOIN channels cha ON cha.channel_id = cst.channel_id
WHERE sales_rank <= 5
ORDER BY cha.channel_desc, sales_percentage DESC;


-- I used CTE because of complexity of the query. also, I needed to filter window function column (rank) with WHERE clause.


--Task 2
--Create a query to retrieve data for a report that displays the total sales for all products 
--in the Photo category in the Asian region for the year 2000. 
--Calculate the overall report total and name it 'YEAR_SUM'
--Display the sales amount with two decimal places
--Display the result in descending order of 'YEAR_SUM'
--For this report, consider exploring the use of the crosstab function. 
--Additional details and guidance can be found at this link


CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT 
    ct.prod_desc,
    ROUND(COALESCE(ct.q1, 0), 2) AS q1,
    ROUND(COALESCE(ct.q2, 0), 2) AS q2,
    ROUND(COALESCE(ct.q3, 0), 2) AS q3,
    ROUND(COALESCE(ct.q4, 0), 2) AS q4,
    ROUND(COALESCE(ct.q1, 0) + COALESCE(ct.q2, 0) + COALESCE(ct.q3, 0) + COALESCE(ct.q4, 0), 2) AS year_sum
FROM crosstab(
    $$
    SELECT 
        p.prod_desc,
        EXTRACT(quarter FROM s.time_id)::INT AS quarter,
        SUM(s.amount_sold) AS quarterly_sales
    FROM sales s
    INNER JOIN customers c ON s.cust_id = c.cust_id
    INNER JOIN countries co ON co.country_id = c.country_id
    INNER JOIN products p ON p.prod_id = s.prod_id
    WHERE UPPER(p.prod_category) = 'PHOTO'
      AND UPPER(co.country_region) = 'ASIA'
      AND s.time_id BETWEEN '2000-01-01' AND '2000-12-31'
    GROUP BY p.prod_desc, quarter
    ORDER BY p.prod_desc, quarter
    $$,
    $$ SELECT generate_series(1,4) $$
) AS ct(prod_desc TEXT, q1 NUMERIC, q2 NUMERIC, q3 NUMERIC, q4 NUMERIC)
ORDER BY ct.prod_desc;

--Task 3
--Create a query to generate a sales report for customers ranked in the top 300 based 
--on total sales in the years 1998, 1999, and 2001. The report should be categorized based on sales channels, 
--and separate calculations should be performed for each channel.
--Retrieve customers who ranked among the top 300 in sales for the years 1998, 1999, and 2001
--Categorize the customers based on their sales channels
--Perform separate calculations for each sales channel
--Include in the report only purchases made on the channel specified
--Format the column so that total sales are displayed with two decimal places

WITH ranked_1998 AS --Customer sales rank in 1998
(
SELECT ch.channel_desc, 
       c.cust_id, 
       c.cust_last_name, 
       c.cust_first_name, 
       SUM(s.amount_sold) AS total_sales,
       RANK() OVER (PARTITION BY ch.channel_desc ORDER BY SUM(s.amount_sold) DESC) AS rank
FROM sales s
JOIN channels ch ON s.channel_id = ch.channel_id
JOIN customers c ON s.cust_id = c.cust_id
WHERE EXTRACT(YEAR FROM s.time_id) = 1998
GROUP BY ch.channel_desc, c.cust_id, c.cust_last_name, c.cust_first_name
),
ranked_1999 AS --Customer sales rank in 1999
(
SELECT ch.channel_desc, 
       c.cust_id, 
       c.cust_last_name, 
       c.cust_first_name, 
       SUM(s.amount_sold) AS total_sales,
       RANK() OVER (PARTITION BY ch.channel_desc ORDER BY SUM(s.amount_sold) DESC) AS rank
FROM sales s
JOIN channels ch ON s.channel_id = ch.channel_id
JOIN customers c ON s.cust_id = c.cust_id
WHERE EXTRACT(YEAR FROM s.time_id) = 1999
GROUP BY ch.channel_desc, c.cust_id, c.cust_last_name, c.cust_first_name
),
ranked_2001 AS --Customer sales rank in 2001
(
SELECT ch.channel_desc, 
       c.cust_id, 
       c.cust_last_name, 
       c.cust_first_name, 
       SUM(s.amount_sold) AS total_sales,
       RANK() OVER (PARTITION BY ch.channel_desc ORDER BY SUM(s.amount_sold) DESC) AS rank
FROM sales s
JOIN channels ch ON s.channel_id = ch.channel_id
JOIN customers c ON s.cust_id = c.cust_id
WHERE EXTRACT(YEAR FROM s.time_id) = 2001
GROUP BY ch.channel_desc, c.cust_id, c.cust_last_name, c.cust_first_name
),
common_customers AS -- common customers in top 300 list accross years 1998, 1999 and 2001
(
SELECT  r1998.cust_id,
        r1998.cust_last_name, 
		r1998.cust_first_name, 
		r1998.channel_desc
FROM ranked_1998 r1998
JOIN ranked_1999 r1999 ON r1998.cust_id = r1999.cust_id AND r1998.channel_desc = r1999.channel_desc
JOIN ranked_2001 r2001 ON r1998.cust_id = r2001.cust_id AND r1998.channel_desc = r2001.channel_desc
WHERE r1998.rank <= 300 AND r1999.rank <= 300 AND r2001.rank <= 300
)
SELECT cc.channel_desc, 
       cc.cust_last_name, 
       cc.cust_first_name, 
       ROUND(SUM(s.amount_sold), 2) AS total_sales
FROM common_customers cc
JOIN sales s ON cc.cust_id = s.cust_id
JOIN channels ch ON s.channel_id = ch.channel_id
WHERE ch.channel_desc = cc.channel_desc
GROUP BY cc.channel_desc, cc.cust_last_name, cc.cust_first_name
ORDER BY cc.channel_desc, total_sales DESC;


--Create a query to generate a sales report for January 2000, February 2000, 
--and March 2000 specifically for the Europe and Americas regions.
--Display the result by months and by product category in alphabetical order.


SELECT DISTINCT
    to_char(s.time_id, 'yyyy-mm') AS calendar_month_desc,
    p.prod_category,
    TO_CHAR(SUM(CASE WHEN UPPER(co.country_region) = 'AMERICAS' THEN s.amount_sold ELSE 0 END) 
        OVER (PARTITION BY to_char(s.time_id, 'yyyy-mm'), p.prod_category), '999,999') AS Americas_SALES,
    TO_CHAR(SUM(CASE WHEN UPPER(co.country_region) = 'EUROPE' THEN s.amount_sold ELSE 0 END) 
        OVER (PARTITION BY to_char(s.time_id, 'yyyy-mm'), p.prod_category), '999,999') AS Europe_SALES
FROM sales s
INNER JOIN customers c ON c.cust_id = s.cust_id
INNER JOIN countries co ON co.country_id = c.country_id
INNER JOIN products p ON s.prod_id = p.prod_id
WHERE EXTRACT (YEAR FROM s.time_id) = 2000
  AND EXTRACT (MONTH FROM s.time_id) IN (1, 2, 3)
  AND UPPER(co.country_region) IN ('AMERICAS', 'EUROPE')
ORDER BY calendar_month_desc, p.prod_category;










