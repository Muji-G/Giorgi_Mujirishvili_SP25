-- Returns a list of films matching the title pattern with an index and stock availability

CREATE OR REPLACE FUNCTION public.films_in_stock_by_title(title_pattern TEXT)
RETURNS TABLE(row_num INTEGER, title TEXT, in_stock BOOLEAN) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ROW_NUMBER() OVER ()::INTEGER AS row_num,  -- we have to cast ROW_NUMBER to INTEGER to match return type.
        f.title,
        EXISTS (
            SELECT 1 FROM inventory i WHERE i.film_id = f.film_id
        ) AS in_stock
    FROM film f
    WHERE f.title ILIKE title_pattern;
END;
$$ LANGUAGE plpgsql;


select * from public.films_in_stock_by_title('%love%');