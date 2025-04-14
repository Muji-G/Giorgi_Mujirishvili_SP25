-- This view calculates total sales revenue by film category for the current quarter,
-- it uses a CTE to identify the start and end dates of the current quarter

CREATE OR REPLACE VIEW public.sales_revenue_by_category_qtr AS
WITH current_period AS (
    SELECT
        DATE_TRUNC('quarter', CURRENT_DATE) AS quarter_start,
        DATE_TRUNC('quarter', CURRENT_DATE) + INTERVAL '3 month' - INTERVAL '1 day' AS quarter_end
),
sales_data AS (
    SELECT
        c.name AS category,
        SUM(p.amount) AS total_revenue
    FROM payment p
    JOIN rental r ON p.rental_id = r.rental_id
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film_category fc ON i.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    JOIN current_period cp ON r.rental_date BETWEEN cp.quarter_start AND cp.quarter_end
    GROUP BY c.name
) SELECT * FROM sales_data WHERE total_revenue > 0;
-- We needed this last select statement to only return categories with sales


SELECT * FROM public.sales_revenue_by_category_qtr();

-- This function doesn't return anything because there is no sales data for current period, 
-- if we want we can change the CURRENT_DATE to a specific date
