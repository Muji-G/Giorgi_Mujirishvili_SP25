-- I created the database in a different script but included it in this script too
CREATE DATABASE museum_db;

-- I now create a schema
DROP SCHEMA IF EXISTS museum_schema CASCADE;
CREATE SCHEMA museum_schema;

-- Set the schema
SET search_path TO museum_schema;


-- 1. item table
CREATE TABLE IF NOT EXISTS item (
    item_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL,
    origin_date DATE,
    location VARCHAR(255) DEFAULT 'Storage'
);

-- 2. exhibtion table
CREATE TABLE IF NOT EXISTS exhibition (
    exhibition_id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    online BOOLEAN DEFAULT FALSE
);

-- 3. item exhibition table (Many-to-Many)
CREATE TABLE IF NOT EXISTS item_exhibition (
    item_id INTEGER NOT NULL,
    exhibition_id INTEGER NOT NULL,
    PRIMARY KEY (item_id, exhibition_id),
    FOREIGN KEY (item_id) REFERENCES item(item_id) ON DELETE CASCADE,
    FOREIGN KEY (exhibition_id) REFERENCES exhibition(exhibition_id) ON DELETE CASCADE
);

-- 4. storage table
CREATE TABLE IF NOT EXISTS storage (
    storage_id SERIAL PRIMARY KEY,
    location_name VARCHAR(255) NOT NULL,
    climate_controlled BOOLEAN DEFAULT TRUE
);

-- 5. employee table
CREATE TABLE IF NOT EXISTS employee (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    position VARCHAR(100) NOT NULL,
    hire_date DATE NOT NULL DEFAULT CURRENT_DATE
);

-- 6. visitor table
CREATE TABLE IF NOT EXISTS visitor (
    visitor_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL
);

-- 7. item storage table 
CREATE TABLE IF NOT EXISTS item_storage (
    item_id INTEGER NOT NULL,
    storage_id INTEGER NOT NULL,
    PRIMARY KEY (item_id, storage_id),
    FOREIGN KEY (item_id) REFERENCES item(item_id) ON DELETE CASCADE,
    FOREIGN KEY (storage_id) REFERENCES storage(storage_id) ON DELETE cascade
);

-- 8. Table for visitor transactions
CREATE TABLE IF NOT EXISTS visitor_transaction (
    transaction_id SERIAL PRIMARY KEY,
    visitor_id INT NOT NULL,
    exhibition_id INT NOT NULL,
    transaction_date DATE DEFAULT CURRENT_DATE,
    ticket_price NUMERIC(6,2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    CONSTRAINT fk_visitor FOREIGN KEY (visitor_id) REFERENCES visitor(visitor_id),
    CONSTRAINT fk_exhibition FOREIGN KEY (exhibition_id) REFERENCES exhibition(exhibition_id)
);


-- Use ALTER TABLE to add at least 5 check constraints across the tables to restrict certain values, as example 

-- 1. CHECK: Start date of exhibitions must be after Jan 1, 2024
ALTER TABLE exhibition
ADD CONSTRAINT chk_exhibition_start_date
CHECK (start_date > '2024-01-01');

-- 2. Item category must be from predefined set
ALTER TABLE item
ADD CONSTRAINT chk_item_category
CHECK (category IN ('Artwork', 'Artifact', 'Specimen', 'Historical Object'));

-- 3. Hire date must be after 1900
ALTER TABLE employee
ADD CONSTRAINT chk_employee_hire_date
CHECK (hire_date > '1900-01-01');

-- 4. Visitor email must contain '@' 
ALTER TABLE Visitor
ADD CONSTRAINT chk_email_format_
CHECK (
    POSITION('@' IN email) > 1 
    AND POSITION('.' IN email) > POSITION('@' IN email) + 1
);

-- 5. Ensuring payment method is a valid one
ALTER TABLE visitor_transaction
ADD CONSTRAINT chk_payment_method
CHECK (
    payment_method IN ('cash', 'credit_card', 'mobile_payment')
);


-- I will add a column for employee, called full name
ALTER TABLE employee
ADD COLUMN full_name VARCHAR(201) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED;


-- Part 4: Data Insertion

INSERT INTO storage (location_name, climate_controlled)
VALUES 
('Tbilisi National Storage', TRUE),
('Batumi Coastal Archives', TRUE),
('Kutaisi Museum Warehouse', FALSE),
('Rustavi History Depot', TRUE),
('Sighnaghi Cultural Storage', TRUE),
('Mtskheta Preservation Center', FALSE)
ON CONFLICT DO NOTHING;


INSERT INTO item (name, description, category, origin_date, location)
VALUES 
('Ancient Colchian Coin', 'Gold coin from ancient Colchis kingdom.', 'Artifact', '0300-01-01' :: DATE, 'Tbilisi National Storage'),
('Kvevri Wine Vessel', 'Traditional Georgian clay wine vessel.', 'Artifact', '1600-01-01' :: DATE, 'Batumi Coastal Archives'),
('Batumi Skyline Painting', 'Modern painting of Batumi seafront.', 'Artwork', '2018-04-20' :: DATE, 'Kutaisi Museum Warehouse'),
('Tbilisi Old Town Photograph', 'Historical photo of Tbilisi.', 'Artwork', '1940-09-12' :: DATE, 'Rustavi History Depot'),
('Georgian Dinosaur Fossil', 'Fossil found in the Imereti region.', 'Specimen', '0200-01-01' :: DATE, 'Sighnaghi Cultural Storage'),
('Medieval Georgian Manuscript', 'Handwritten Georgian script document.', 'Historical Object', '1200-05-18' :: DATE, 'Mtskheta Preservation Center')
ON CONFLICT DO NOTHING;


INSERT INTO exhibition (title, start_date, end_date, online)
VALUES 
('Treasures of Ancient Colchis', '2025-02-05' :: DATE, '2025-04-30' :: DATE, TRUE),
('The Wine Culture of Georgia', '2025-01-15' :: DATE, '2025-03-15' :: DATE, FALSE),
('Modern Art of Batumi', '2025-03-01' :: DATE, '2025-05-01' :: DATE, TRUE),
('Tbilisi Through the Lens', '2025-02-10' :: DATE, '2025-04-15' :: DATE, TRUE),
('Fossils of the Caucasus', '2025-01-25' :: DATE, '2025-04-25' :: DATE, FALSE),
('Sacred Scripts of Georgia', '2025-03-10' :: DATE, '2025-06-10' :: DATE, TRUE)
ON CONFLICT DO NOTHING;


INSERT INTO item_exhibition (item_id, exhibition_id)
VALUES
(1, 1), -- Colchian Coin in Treasures of Colchis
(2, 2), -- Kvevri Wine Vessel in Wine Culture
(3, 3), -- Batumi Skyline Painting in Modern Art
(4, 4), -- Old Town Photo in Tbilisi Through the Lens
(5, 5), -- Dinosaur Fossil in Fossils of the Caucasus
(6, 6) -- Georgian Manuscript in Sacred Scripts
ON CONFLICT DO NOTHING;

truncate table item_exhibition

INSERT INTO employee (first_name, last_name, position, hire_date)
VALUES 
('Nino', 'Beridze', 'Curator', '2021-07-15' :: DATE),
('Giorgi', 'Lomadze', 'Archivist', '2022-05-10' :: DATE),
('Tamar', 'Abashidze', 'Conservator', '2020-09-20' :: DATE),
('Lasha', 'Gelashvili', 'Exhibition Manager', '2023-04-01' :: DATE),
('Salome', 'Chikovani', 'Tour Guide', '2024-02-05' :: DATE),
('Dato', 'Kiknadze', 'Education Coordinator', '2022-11-11' :: DATE)
ON CONFLICT DO NOTHING;

INSERT INTO visitor (first_name, last_name, email)
VALUES 
('Ana', 'Tsereteli', 'atsereteli@gmail.ge'),
('Nikoloz', 'Shvelidze', 'nshvelidze@gmail.ge'),
('Mariam', 'Khurtsidze', 'mkhurtsidze@gmail.ge'),
('Zurab', 'Tugushi', 'ztugushi@gmail.ge'),
('Sopho', 'Gogoladze', 'sgogoladze@gmail.ge'),
('Irakli', 'Gvazava', 'igvazava@gmail.ge')
ON CONFLICT DO NOTHING;

INSERT INTO item_storage (item_id, storage_id)
VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 6)
ON CONFLICT DO NOTHING;

INSERT INTO visitor_transaction (visitor_id, exhibition_id, transaction_date, ticket_price, payment_method)
VALUES 
(1, 2, '2025-02-15' :: DATE, 20.00, 'credit_card'),
(2, 1, '2025-02-28' :: DATE, 15.00, 'cash'),
(3, 3, '2025-03-05' :: DATE, 25.00, 'mobile_payment'),
(4, 2, '2025-03-18' :: DATE, 20.00, 'credit_card'),
(5, 4, '2025-03-25' :: DATE, 30.00, 'credit_card'),
(6, 1, '2025-04-02' :: DATE, 15.00, 'cash'),
(1, 3, '2025-04-10' :: DATE, 25.00, 'mobile_payment'),
(2, 4, '2025-04-18' :: DATE, 30.00, 'credit_card'),
(5, 2, '2025-04-20' :: DATE, 20.00, 'cash')
ON CONFLICT DO NOTHING;



-- Part 5:
-- Create a function that updates data in one of your tables. This function should take the following input arguments:
-- The primary key value of the row you want to update
-- The name of the column you want to update
-- The new value you want to set for the specified column

-- I created a function which will take in the primary key, column name and new value and it will update relevant item 
-- in ITEM table


CREATE OR REPLACE FUNCTION update_item_column(
    p_item_id INT,
    p_column_name TEXT,
    p_new_value TEXT
)
RETURNS VOID AS
$$
BEGIN
    EXECUTE FORMAT(
        'UPDATE item SET %I = %L WHERE item_id = %L',
        p_column_name, p_new_value, p_item_id
    );
    
    RAISE NOTICE 'Item %: column "%" updated to %', p_item_id, p_column_name, p_new_value;
END;
$$
LANGUAGE plpgsql;


-- Part 5.2
-- Create a function that adds a new transaction to your transaction table. 
-- You can define the input arguments and output format. 
-- Make sure all transaction attributes can be set with the function (via their natural keys). 
-- The function does not need to return a value but should confirm the successful insertion of the new transaction.


CREATE OR REPLACE FUNCTION add_visitor_transaction(
    p_visitor_id INT,
    p_exhibition_id INT,
    p_transaction_date DATE DEFAULT CURRENT_DATE,
    p_ticket_price NUMERIC(6,2),
    p_payment_method VARCHAR(50)
)
RETURNS VOID AS
$$
BEGIN
    INSERT INTO visitor_transaction (visitor_id, exhibition_id, transaction_date, ticket_price, payment_method)
    VALUES (p_visitor_id, p_exhibition_id, p_transaction_date, p_ticket_price, p_payment_method);
    
    RAISE NOTICE 'Transaction successfully inserted for visitor ID %', p_visitor_id;
END;
$$
LANGUAGE plpgsql;

-- Part 6
-- Create a view that presents analytics for the most recently added quarter in your database.

CREATE OR REPLACE VIEW v_latest_quarter_analytics AS
SELECT DISTINCT
    v.first_name || ' ' || v.last_name AS visitor_name,
    v.email,
    e.title AS exhibition_title,
    t.transaction_date,
    t.ticket_price,
    t.payment_method
FROM visitor_transaction t
JOIN visitor v ON v.visitor_id = t.visitor_id
JOIN exhibition e ON e.exhibition_id = t.exhibition_id
WHERE 
    t.transaction_date >= date_trunc('quarter', CURRENT_DATE) - INTERVAL '3 months'
    AND t.transaction_date < date_trunc('quarter', CURRENT_DATE)
ORDER BY t.transaction_date DESC;

-- Part 7
-- Create a read-only role for the manager. This role should have permission to perform 
-- SELECT queries on the database tables, and also be able to log in. 


-- at first I create the role museum_manager
CREATE ROLE museum_manager
    LOGIN                         -- can log into the database
    PASSWORD 'StrongPassword123!' 
    NOSUPERUSER                   -- cannot create roles or databases
    NOCREATEDB
    NOCREATEROLE
    NOINHERIT                     -- explicit permissions must be given
    NOREPLICATION

 
-- now I grant SELECT privileges
-- grant SELECT on all existing tables in the schema
GRANT USAGE ON SCHEMA museum_schema TO museum_manager;
GRANT SELECT ON ALL TABLES IN SCHEMA museum_schema TO museum_manager;

-- also ensure that future tables automatically allow SELECT
ALTER DEFAULT PRIVILEGES IN SCHEMA museum_schema
GRANT SELECT ON TABLES TO museum_manager;




