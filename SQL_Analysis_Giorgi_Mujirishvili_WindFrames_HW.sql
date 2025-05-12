-- Task 1

WITH sales_report AS
		(SELECT
			co.country_region,
			EXTRACT (YEAR FROM s.time_id) AS calendar_year,
			ch.channel_desc,
			SUM(s.amount_sold) AS amount_sold,
			SUM(s.amount_sold) * 100 / SUM(SUM(s.amount_sold)) OVER (PARTITION BY co.country_region,EXTRACT (YEAR FROM s.time_id)) AS "% BY CHANNELS"
		FROM sales s
		INNER JOIN products p on p.prod_id = s.prod_id
		INNER JOIN channels ch on ch.channel_id = s.channel_id
		INNER JOIN customers c on c.cust_id = s.cust_id
		INNER JOIN countries co on co.country_id = c.country_id
		WHERE LOWER(co.country_region) IN ('americas','asia','europe')
		and EXTRACT (YEAR FROM s.time_id) BETWEEN 1998 and 2001
		GROUP BY co.country_region, EXTRACT (YEAR FROM s.time_id), ch.channel_desc
		ORDER BY co.country_region, EXTRACT (YEAR FROM s.time_id), ch.channel_desc
),
	previous_year AS 
		(
		SELECT sr."% BY CHANNELS" ,  
		LAG(sr."% BY CHANNELS") OVER (PARTITION BY sr.country_region, sr.channel_desc ORDER BY sr.calendar_year) AS prev_per
		FROM sales_report sr
)
SELECT 
	sr.country_region,
	sr.calendar_year,
	sr.channel_desc,
	to_char(sr.amount_sold,'FM9,999,999,999 $') AS amount_sold,
	to_char(sr."% BY CHANNELS",'FM999,990.00%') AS "% BY CHANNELS",
	to_char(py.prev_per,'FM999,990.00%') AS "% PREVIOUS PERIOD",
	to_char(sr."% BY CHANNELS" - py.prev_per,'FM999,990.00%') AS "% DIFF"
FROM sales_report sr
INNER JOIN previous_year py ON sr."% BY CHANNELS" = py."% BY CHANNELS" -- used join to link previous and current year details
WHERE sr.calendar_year BETWEEN 1999 AND 2001
ORDER BY sr.country_region,sr.calendar_year,sr.channel_desc;

-- We want to group the data by region and year to calculate percentages within those groups.
-- For comparing this year’s data to last year’s, LAG() looks at the previous year's value directly, so no extra frame is needed

-- Task 2


SELECT t.calendar_week_number,
       t.time_id,
       t.day_name,
       SUM(s.amount_sold) AS sales,
       SUM(SUM(s.amount_sold)) OVER (PARTITION BY t.calendar_week_number ORDER BY t.calendar_week_number, t.time_id RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sum,
       ROUND(CASE
                WHEN LOWER(t.day_name) IN ('tuesday', 'wednesday', 'thursday', 'saturday', 'sunday') 
                THEN AVG(SUM(s.amount_sold)) OVER (ORDER BY t.time_id ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING)
                WHEN LOWER(t.day_name) = 'monday' 
                THEN AVG(SUM(s.amount_sold)) OVER (ORDER BY t.time_id ROWS BETWEEN 2 PRECEDING AND 1 FOLLOWING)
                WHEN LOWER(t.day_name) = 'friday' 
                THEN AVG(SUM(s.amount_sold)) OVER (ORDER BY t.time_id ROWS BETWEEN 1 PRECEDING AND 2 FOLLOWING)
        END, 2) AS centered_3_day_avg 
FROM sh.times t 
JOIN sh.sales s ON s.time_id = t.time_id
WHERE t.calendar_week_number BETWEEN 49 AND 51
AND t.calendar_year = 1999
GROUP BY t.calendar_week_number,
         t.time_id,
         t.day_name
ORDER BY t.calendar_week_number, t.time_id;

-- In this caseRANGE is used to sum all sales from the start of the week up until the current day and
-- ROWS is used to average sales from the exact previous and next days. This ensures the average is centered around each day.



-- Task 3


WITH sales_report AS 
(
SELECT c.country_region,
       t.calendar_year,
       ch.channel_desc,
	   SUM(s.amount_sold) AS amount_sold,
       SUM(SUM(s.amount_sold)) OVER (PARTITION BY t.calendar_year, c.country_region ORDER BY t.calendar_week_number RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales,

       -- centered 3-day moving average using rows (previous, current, and following days)

ROUND(AVG(SUM(s.amount_sold)) OVER (PARTITION BY c.country_region, t.calendar_year, ch.channel_desc ORDER BY t.time_id ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING), 2) AS centered_3_day_avg,

		-- ranking channels within each region using groups

RANK() OVER (PARTITION BY c.country_region ORDER BY SUM(s.amount_sold) DESC GROUPS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS channel_rank
FROM sh.countries c
JOIN sh.customers cu ON c.country_id = cu.country_id  
JOIN sh.sales s ON cu.cust_id = s.cust_id            
JOIN sh.channels ch ON ch.channel_id = s.channel_id  
JOIN sh.times t ON s.time_id = t.time_id             
WHERE c.country_region IN ('Americas', 'Asia', 'Europe')
AND t.calendar_year BETWEEN 1999 AND 2001
GROUP BY c.country_region, t.calendar_year, ch.channel_desc, t.calendar_week_number, t.time_id
)
SELECT *
FROM sales_report sr
ORDER BY sr.country_region, sr.calendar_year, sr.channel_desc;


-- RANGE helps add up sales from the start of the year up to the current week. ROWS gives a centered average by using 
-- the current, previous, and next days. GROUPS is used for ranking channels, so if two channels have the same sales, they get the same rank.

