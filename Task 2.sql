-- This function returns sales revenue by category for a specific quarter given by date input.

CREATE OR REPLACE FUNCTION public.get_sales_revenue_by_category_qtr(target_quarter DATE)
RETURNS TABLE(category TEXT, total_revenue NUMERIC) as
$$
BEGIN
    RETURN QUERY
    WITH quarter_period AS (
        SELECT
            DATE_TRUNC('quarter', target_quarter) AS quarter_start,
            DATE_TRUNC('quarter', target_quarter) + INTERVAL '3 month' - INTERVAL '1 day' AS quarter_end
    )
    SELECT
        c.name AS category,
        SUM(p.amount) AS total_revenue
    FROM payment p
    JOIN rental r ON p.rental_id = r.rental_id
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film_category fc ON i.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    JOIN quarter_period qp ON r.rental_date BETWEEN qp.quarter_start AND qp.quarter_end
    GROUP BY c.name
    HAVING SUM(p.amount) > 0;
END;
$$ 
LANGUAGE plpgsql;

select * from public.get_sales_revenue_by_category_qtr;
