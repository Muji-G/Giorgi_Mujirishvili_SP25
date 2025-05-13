SET search_path TO public;

CREATE OR REPLACE FUNCTION films_in_stock_by_title(title_pattern TEXT)
RETURNS TABLE(
    row_num INTEGER,
    title TEXT,
    in_stock BOOLEAN,
    last_customer TEXT,
    last_rental_date TIMESTAMP
) AS $$
DECLARE
    film_rec RECORD;
    counter INTEGER := 0;
BEGIN
    FOR film_rec IN
        SELECT
            f.film_id,
            f.title,
            EXISTS (
                SELECT 1
                FROM inventory i
                LEFT JOIN rental r ON i.inventory_id = r.inventory_id AND r.return_date IS NULL
                WHERE i.film_id = f.film_id
                GROUP BY i.inventory_id
                HAVING COUNT(r.rental_id) = 0
            ) AS in_stock,
            (
                SELECT c.first_name || ' ' || c.last_name
                FROM rental r
                JOIN customer c ON r.customer_id = c.customer_id
                JOIN inventory i ON r.inventory_id = i.inventory_id
                WHERE i.film_id = f.film_id
                ORDER BY r.rental_date DESC
                LIMIT 1
            ) AS last_customer,
            (
                SELECT r.rental_date
                FROM rental r
                JOIN inventory i ON r.inventory_id = i.inventory_id
                WHERE i.film_id = f.film_id
                ORDER BY r.rental_date DESC
                LIMIT 1
            ) AS last_rental_date
        FROM film f
        WHERE f.title ILIKE title_pattern
    LOOP
        counter := counter + 1;
        row_num := counter;
        title := film_rec.title;
        in_stock := film_rec.in_stock;
        last_customer := film_rec.last_customer;
        last_rental_date := film_rec.last_rental_date;

        RETURN NEXT;  
    END LOOP;

    RETURN;
END;
$$ LANGUAGE plpgsql;
