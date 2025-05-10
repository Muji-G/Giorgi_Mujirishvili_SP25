-- 1) Create a new user with the username "rentaluser" and the password "rentalpassword".
-- Give the user the ability to connect to the database but no other permissions.

CREATE ROLE rentaluser LOGIN PASSWORD 'rentalpassword'
GRANT CONNECT ON DATABASE dvdrental TO rentaluser;


-- 2) Grant "rentaluser" SELECT permission for the "customer" table. 

GRANT SELECT ON customer TO rentaluser; 

-- check to make sure this permission works correctly
SET ROLE rentaluser;
SELECT * FROM customer;
RESET ROLE;

-- 3) Create a new user group called "rental" and add "rentaluser" to the group. 

CREATE ROLE rental;
GRANT rental TO rentaluser;

-- 4) Grant the "rental" group INSERT and UPDATE permissions for the "rental" table.

GRANT INSERT ON rental TO rental;
GRANT UPDATE ON rental TO rental;

-- insert a new row and update one existing row in the "rental" table under that role

SET ROLE rentaluser;

-- insert
INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
VALUES (NOW(), 1, 1, NULL, 1);

-- update
UPDATE rental
SET return_date = NOW()
WHERE rental_id = (SELECT MAX(rental_id) FROM rental);

RESET ROLE;


-- 5) Revoke the "rental" group's INSERT permission for the "rental" table. 
-- Try to insert new rows into the "rental" table make sure this action is denied.

REVOKE INSERT ON rental FROM rental;

SET ROLE rentaluser;

-- this should now fail
INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
VALUES (NOW(), 1, 1, NULL, 1);

RESET ROLE;


-- 6) Create a personalized role for any customer already existing in the dvd_rental database. 
-- The name of the role name must be client_{first_name}_{last_name} (omit curly brackets). 
-- The customer's payment and rental history must not be empty. 

SELECT c.first_name, c.last_name
FROM customer c
WHERE EXISTS (SELECT 1 FROM rental r WHERE r.customer_id = c.customer_id)
  AND EXISTS (SELECT 1 FROM payment p WHERE p.customer_id = c.customer_id)
LIMIT 1;

-- this query returns client named Patricia Johnson, so I create a role for her
CREATE ROLE client_patricia_johnson;


