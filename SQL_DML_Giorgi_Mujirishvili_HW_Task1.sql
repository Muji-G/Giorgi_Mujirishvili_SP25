-- TASK 1

-- Choose your top-3 favorite movies and add them to the 'film' table 
-- Fill in rental rates with 4.99, 9.99 and 19.99 and rental durations with 1, 2 and 3 weeks respectively.
SET search_path TO public;

START TRANSACTION;
INSERT INTO film (
    title, description, release_year, language_id, rental_duration, rental_rate, length,
    replacement_cost, rating, special_features, last_update
)
SELECT 
    v.title, v.description, v.release_year, l.language_id, v.rental_duration, v.rental_rate,
    v.length, v.replacement_cost, v.rating::mpaa_rating, v.special_features, current_date
FROM (
    VALUES
        ('Eyes Wide Shut', 'A Manhattan doctor embarks on a bizarre, night-long odyssey', 1999, 7, 4.99, 159, 21.99, 'R', ARRAY['Trailers']),
        ('The Art of Self Defense', 'After being attacked on the street, a young man enlists at a local dojo', 2019, 14, 9.99, 104, 14.99, 'R', ARRAY['Trailers']),
        ('Manchester by the Sea', 'An uncle is forced to take care of his teenage nephew', 2016, 21, 19.99, 137, 29.99, 'R', ARRAY['Trailers'])
) AS v(title, description, release_year, rental_duration, rental_rate, length, replacement_cost, rating, special_features)
JOIN language l ON l.name = 'English'
WHERE NOT EXISTS (
    SELECT 1 FROM film f WHERE f.title = v.title
)
RETURNING film_id;

--Add the actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables

INSERT INTO actor (first_name, last_name, last_update)
SELECT v.first_name, v.last_name, current_date
FROM (
    VALUES
        ('Tom', 'Cruise'),
        ('Nicole', 'Kidman'),
        ('Sydney', 'Pollack'),
        ('Jesse', 'Eisenberg'),
        ('Alessandro', 'Nivola'),
        ('Casey', 'Affleck'),
        ('Michelle', 'Williams'),
        ('Lucas', 'Hedges')
) AS v(first_name, last_name)
WHERE NOT EXISTS (
    SELECT 1 FROM actor a WHERE a.first_name = v.first_name AND a.last_name = v.last_name
)
RETURNING actor_id;


-- Eyes Wide Shut
INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, current_date
FROM actor a
JOIN film f ON f.title = 'Eyes Wide Shut'
WHERE (a.first_name, a.last_name) IN (('Tom', 'Cruise'), ('Nicole', 'Kidman'), ('Sydney', 'Pollack'))
  AND NOT EXISTS (
      SELECT 1 FROM film_actor fa WHERE fa.actor_id = a.actor_id AND fa.film_id = f.film_id
)
RETURNING actor_id, film_id;

-- The Art of Self Defense
INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, current_date
FROM actor a
JOIN film f ON f.title = 'The Art of Self Defense'
WHERE (a.first_name, a.last_name) IN (('Jesse', 'Eisenberg'), ('Alessandro', 'Nivola'))
  AND NOT EXISTS (
      SELECT 1 FROM film_actor fa WHERE fa.actor_id = a.actor_id AND fa.film_id = f.film_id
)
RETURNING actor_id, film_id;

-- Manchester by the Sea
INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT a.actor_id, f.film_id, current_date
FROM actor a
JOIN film f ON f.title = 'Manchester by the Sea'
WHERE (a.first_name, a.last_name) IN (('Casey', 'Affleck'), ('Michelle', 'Williams'), ('Lucas', 'Hedges'))
  AND NOT EXISTS (
      SELECT 1 FROM film_actor fa WHERE fa.actor_id = a.actor_id AND fa.film_id = f.film_id
)
RETURNING actor_id, film_id;

-- now I add those movies to store, where stre id is 1
INSERT INTO inventory (film_id, store_id, last_update)
SELECT f.film_id, 1, current_date
FROM film f
WHERE f.title IN ('Eyes Wide Shut', 'The Art of Self Defense', 'Manchester by the Sea')
  AND NOT EXISTS (
      SELECT 1 FROM inventory i WHERE i.film_id = f.film_id AND i.store_id = 1
)
RETURNING inventory_id, film_id;

-- Alter any existing customer in the database with at least 43 rental and 43 payment records.
-- Change their personal data to yours (first name, last name, address, etc.)

-- at first, lets find the customer who has at least 43 rental and 43 payment records

WITH qualified_customer AS (
    SELECT c.customer_id
    FROM customer c
    JOIN rental r ON c.customer_id = r.customer_id
    JOIN payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id
    HAVING COUNT(DISTINCT r.rental_id) >= 43 AND COUNT(DISTINCT p.payment_id) >= 43
    LIMIT 1
),

-- now I clean up customer's history

deleted_payments AS (
    DELETE FROM payment
    WHERE customer_id = (SELECT customer_id FROM qualified_customer)
    RETURNING payment_id
),
deleted_rentals AS (
    DELETE FROM rental
    WHERE customer_id = (SELECT customer_id FROM qualified_customer)
    RETURNING rental_id
),

--  updating customer info

updated_customer AS (
    UPDATE customer
    SET first_name = 'Giorgi',
        last_name = 'Mujirishvili',
        email = 'mujirishvili.giorgi@gmail.com',
        address_id = 1,
        last_update = current_date
    WHERE customer_id = (SELECT customer_id FROM qualified_customer)
    RETURNING customer_id
),

-- for renting the movies I found a way to simulate different dates using film_id % 10

new_rentals AS (
    INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id, return_date, last_update)
    SELECT 
        DATE '2017-01-01' + (f.film_id % 10),
        i.inventory_id,
        qc.customer_id,
        1,
        DATE '2017-01-03' + (f.film_id % 10),
        current_date
    FROM inventory i
    JOIN film f ON f.film_id = i.film_id
    JOIN qualified_customer qc ON TRUE
    WHERE f.title IN ('Eyes Wide Shut', 'The Art of Self Defense', 'Manchester by the Sea')
      AND NOT EXISTS (
          SELECT 1 FROM rental r 
          WHERE r.inventory_id = i.inventory_id AND r.customer_id = qc.customer_id
    )
    RETURNING rental_id, inventory_id, customer_id
)

-- since payment didn't have last_updated column I used a temporary column to not alter the schema permanently

INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT 
    nr.customer_id,
    1,
    nr.rental_id,
    CASE f.title
        WHEN 'Eyes Wide Shut' THEN 4.99
        WHEN 'The Art of Self Defense' THEN 9.99
        WHEN 'Manchester by the Sea' THEN 19.99
    END,
    DATE '2017-01-03' + (f.film_id % 10)
FROM new_rentals nr
JOIN inventory i ON nr.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
WHERE f.title IN ('Eyes Wide Shut', 'The Art of Self Defense', 'Manchester by the Sea')
RETURNING payment_id, amount;

COMMIT;

