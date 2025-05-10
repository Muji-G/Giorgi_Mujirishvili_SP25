CREATE OR REPLACE FUNCTION public.most_popular_films_by_countries(countries TEXT[])
RETURNS TABLE (
    country TEXT, film TEXT,
    rating TEXT, language TEXT,
    length INT, release_year INT) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT ON (co.country) 
        co.country::text, f.title::text,
        f.rating::text, l.name::text,
        f.length::int, f.release_year::int
    FROM country co
    JOIN city ci ON co.country_id = ci.country_id
    JOIN address a ON ci.city_id = a.city_id
    JOIN customer cu ON a.address_id = cu.address_id
    JOIN rental r ON cu.customer_id = r.customer_id
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
    JOIN language l ON f.language_id = l.language_id
    WHERE co.country = ANY(countries)
    GROUP BY co.country, f.title, f.rating, l.name, f.length, f.release_year
    ORDER BY co.country, COUNT(*) DESC;
END;
$$ LANGUAGE plpgsql;


select * from public.most_popular_films_by_countries(array['Afghanistan', 'Brazil', 'United States']);