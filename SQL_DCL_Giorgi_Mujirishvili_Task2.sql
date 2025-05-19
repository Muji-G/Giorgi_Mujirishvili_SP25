-- 1) Create a new user with the username "rentaluser" and the password "rentalpassword".
-- Give the user the ability to connect to the database but no other permissions.
SET search_path TO public;

BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'rentaluser') THEN
        CREATE ROLE rentaluser LOGIN PASSWORD 'rentalpassword';
    END IF;
END
$$;
GRANT CONNECT ON DATABASE dvdrental TO rentaluser;


-- 2) Grant "rentaluser" SELECT permission for the "customer" table. 

GRANT SELECT ON customer TO rentaluser; 

-- check to make sure this permission works correctly
SET ROLE rentaluser;
SELECT * FROM customer;
RESET ROLE;

-- 3) Create a new user group called "rental" and add "rentaluser" to the group. 

DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'rental') THEN
        CREATE ROLE rental;
    END IF;
END
$$;
GRANT rental TO rentaluser;

-- 4) Grant the "rental" group INSERT and UPDATE permissions for the "rental" table.

GRANT INSERT, UPDATE ON public.rental TO rental;

-- insert a new row and update one existing row in the "rental" table under that role

SET ROLE rentaluser;

-- insert
INSERT INTO rental (rental_date, inventory_id, customer_id, return_date, staff_id)
SELECT NOW(), inventory_id, customer_id, NULL, staff_id
FROM public.inventory, public.customer, public.staff
LIMIT 1;

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
DO $$
BEGIN
    BEGIN
        INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id)
        SELECT NOW(), inventory_id, customer_id, NULL, staff_id
        FROM public.inventory, public.customer, public.staff
        LIMIT 1;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Failure: %', SQLERRM;
    END;
END
$$;

RESET ROLE;


-- 6) Create a personalized role for any customer already existing in the dvd_rental database. 
-- The name of the role name must be client_{first_name}_{last_name} (omit curly brackets). 
-- The customer's payment and rental history must not be empty. 

CREATE OR REPLACE FUNCTION create_client_roles()
RETURNS void AS $$
DECLARE
    rec RECORD;
    role_name TEXT;
    role_exists BOOLEAN;
BEGIN
    FOR rec IN
        SELECT c.first_name, c.last_name
        FROM public.customer c
        WHERE EXISTS (
            SELECT 1 FROM public.rental r WHERE r.customer_id = c.customer_id
        ) AND EXISTS (
            SELECT 1 FROM public.payment p WHERE p.customer_id = c.customer_id
        )
    LOOP
        role_name := 'client_' || lower(rec.first_name) || '_' || lower(rec.last_name);

        -- Check if role exists
        SELECT EXISTS (
            SELECT 1 FROM pg_roles WHERE rolname = role_name
        ) INTO role_exists;

        -- Create role if it doesn't exist
        IF NOT role_exists THEN
            EXECUTE format('CREATE ROLE %I;', role_name);
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;



