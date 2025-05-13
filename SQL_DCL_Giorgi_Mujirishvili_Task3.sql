SET search_path TO public;

-- at first I create a role for customer users
CREATE ROLE customer_user NOINHERIT LOGIN PASSWORD 'securepassword';

-- now I create a function to get the current customer's ID from the session
CREATE OR REPLACE FUNCTION current_customer_id()
RETURNS INTEGER AS $$
BEGIN
  RETURN current_setting('app.current_customer_id')::INTEGER;
EXCEPTION WHEN others THEN
  RETURN NULL;
END;
$$ LANGUAGE plpgsql STABLE;

-- now I have to enable row-level security on the rental and payment tables
ALTER TABLE rental ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;

-- now I create RLS policy on rental table
CREATE POLICY rental_customer_policy
ON rental
FOR SELECT
USING (customer_id = current_customer_id());

-- and on payment table
CREATE POLICY payment_customer_policy
ON payment
FOR SELECT
USING (customer_id = current_customer_id());

-- now I force all access to go through RLS
ALTER TABLE rental FORCE ROW LEVEL SECURITY;
ALTER TABLE payment FORCE ROW LEVEL SECURITY;

-- and now I grant access to the customer_user role
GRANT USAGE ON SCHEMA public TO customer_user;
GRANT SELECT ON rental, payment TO customer_user;

-- for seeing if this solution works, I will simulate a session
-- where I am using customer_id of 1 and these select statements
-- should only return the information about first row of table
SET SESSION app.current_customer_id = '1';
SELECT * FROM rental;
SELECT * FROM payment;
