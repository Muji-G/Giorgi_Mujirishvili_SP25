-- TASK 1

-- Choose your top-3 favorite movies and add them to the 'film' table 
-- Fill in rental rates with 4.99, 9.99 and 19.99 and rental durations with 1, 2 and 3 weeks respectively.

START TRANSACTION;

INSERT INTO film (
    title, 
    description, 
    release_year, 
    language_id, 
    rental_duration, 
    rental_rate, 
    length, 
    replacement_cost, 
    rating, 
    special_features
) VALUES (
    'Eyes Wide Shut', 
    'A Manhattan doctor embarks on a bizarre, night-long odyssey', 
    1999, 
    1, 
    1, 
    4.99, 
    159, 
    21.99, 
    'R', 
    '{Trailers}'
);

INSERT INTO film (
    title, 
    description, 
    release_year, 
    language_id, 
    rental_duration, 
    rental_rate, 
    length, 
    replacement_cost, 
    rating, 
    special_features
) VALUES (
    'The Art of Self Defense', 
    'After being attacked on the street, a young man enlists at a local dojo', 
    2019, 
    1, 
    2, 
    9.99, 
    104, 
    14.99, 
    'R', 
    '{Trailers}'
);

INSERT INTO film (
    title, 
    description, 
    release_year, 
    language_id, 
    rental_duration, 
    rental_rate, 
    length, 
    replacement_cost, 
    rating, 
    special_features
) VALUES (
    'Manchester by the Sea', 
    'An uncle is forced to take care of his teenage nephew', 
    2016, 
    1, 
    3, 
    19.99, 
    137, 
    29.99, 
    'R', 
    '{Trailers}'
);

COMMIT;

-- I added those three movies and I skipped columns film_id, because it is auto increment and there was no need to 
-- add identificator manually, original_language_id, because it was NULL in most cases, last_update, since the 
-- default value of that column is NOW and Fulltext, since it writes values by itself. I typed trailers in {} braces
-- because the data type forced me to.

-- Add the actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables (6 or more actors in total).  
select * from actor a 

START TRANSACTION;

-- 1. Insert actors 
-- Since I know that there are no real named actors in db I use simple query
START TRANSACTION;

-- Insert 8 known actors (assuming none exist in the actor table)
INSERT INTO actor (first_name, last_name)
VALUES 
    ('Tom', 'Cruise'),
    ('Nicole', 'Kidman'),
    ('Jesse', 'Eisenberg'),
    ('Casey', 'Affleck'),
    ('Michelle', 'Williams'),
    ('Sydney', 'Pollack'),
    ('Alessandro', 'Nivola'),
    ('Lucas', 'Hedges');

COMMIT;

-- If I wanted to make sure that there are no duplicates I would write additonally where not exists, for example
-- WHERE NOT EXISTS (
--    SELECT 1 FROM actor WHERE first_name = 'Michelle' AND last_name = 'Williams')

			
-- 2. Link actors to films in film_actor table

START TRANSACTION;

-- Eyes Wide Shut
INSERT INTO film_actor (film_id, actor_id)
SELECT f.film_id, a.actor_id
FROM film f, actor a
WHERE f.title = 'Eyes Wide Shut'
  AND (a.first_name, a.last_name) IN (
      ('Tom', 'Cruise'),
      ('Nicole', 'Kidman'),
      ('Sydney', 'Pollack')
  );

-- The Art of Self Defense
INSERT INTO film_actor (film_id, actor_id)
SELECT f.film_id, a.actor_id
FROM film f, actor a
WHERE f.title = 'The Art of Self Defense'
  AND (a.first_name, a.last_name) IN (
      ('Jesse', 'Eisenberg'),
      ('Alessandro', 'Nivola')
  );

-- Manchester by the Sea
INSERT INTO film_actor (film_id, actor_id)
SELECT f.film_id, a.actor_id
FROM film f, actor a
WHERE f.title = 'Manchester by the Sea'
  AND (a.first_name, a.last_name) IN (
      ('Casey', 'Affleck'),
      ('Michelle', 'Williams'),
      ('Lucas', 'Hedges')
  );

COMMIT;


-- Same thing applies here too, I knew there were no duplicates so I simplified the query.

-- Add your favorite movies to any store's inventory.

START TRANSACTION;

-- Eyes Wide Shut
INSERT INTO inventory (film_id, store_id)
SELECT f.film_id, 1
FROM film f
WHERE f.title = 'Eyes Wide Shut';

-- The Art of Self Defense
INSERT INTO inventory (film_id, store_id)
SELECT f.film_id, 1
FROM film f
WHERE f.title = 'The Art of Self Defense';

-- Manchester by the Sea
INSERT INTO inventory (film_id, store_id)
SELECT f.film_id, 1
FROM film f
WHERE f.title = 'Manchester by the Sea';

COMMIT;



-- Alter any existing customer in the database with at least 43 rental and 43 payment records.
-- Change their personal data to yours (first name, last name, address, etc.)

-- At first, lets find the customer who has at least 43 rental and 43 payment records

SELECT c.customer_id
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id
HAVING COUNT(DISTINCT r.rental_id) >= 43 AND COUNT(DISTINCT p.payment_id) >= 43
LIMIT 1;

-- The outcome of this quey was customer_id = 1, which means that I will change his data to mine
-- Now let's take the adress, which adress_id 1 and use it in my task
