-- setting the search path to public
SET search_path TO public;

-- creating the employee table
DROP TABLE IF EXISTS employee;
CREATE TABLE employee (
    id SERIAL PRIMARY KEY,
    name VARCHAR,
    status VARCHAR
);

-- transaction 1 - insert a row and checking xmin/xmax
BEGIN;
SELECT txid_current(); -- Get current transaction ID
INSERT INTO employee (name, status) VALUES ('Alice', 'Not fired');
SELECT *, xmin, xmax FROM employee;
COMMIT;

-- transaction 2 - reading out the row
BEGIN;
SELECT *, xmin, xmax FROM employee;
COMMIT;

-- transaction 3 - deleting Alice, then reinserting her
BEGIN;
SELECT txid_current();
DELETE FROM employee WHERE id = 1;
SELECT *, xmin, xmax FROM employee;
COMMIT;

-- reinserting Alice 
INSERT INTO employee (name, status) VALUES ('Alice', 'Not fired');

BEGIN;
SELECT *, xmin, xmax FROM employee;
COMMIT;

-- transaction 4 - updating Alice's status
BEGIN;
SELECT txid_current();
UPDATE employee SET status = 'Fired' WHERE id = 2;
SELECT *, xmin, xmax FROM employee;
COMMIT;

-- setting transaction isolation level to REPEATABLE READ
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- checking current isolation level
SHOW TRANSACTION ISOLATION LEVEL;

-- recreatng table for cmin/cmax (these are visible only internally)
DROP TABLE IF EXISTS employee;
CREATE TABLE employee(
    id SERIAL PRIMARY KEY,
    name VARCHAR,
    status VARCHAR
);


-- causing Serialization Anomaly
-- for this to happen we need 2 separate sessions
-- SESSION 1:
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT * from employee WHERE id = 2;
-- SESSION 2:
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT * FROM employee WHERE id = 2;
UPDATE employee SET status = 'Session 2 update' WHERE id = 2;
COMMIT;
-- SESSION 1:
UPDATE employee SET status = 'Session 1 update' WHERE id = 2;
COMMIT; -- failing with serialization error

-- losing Update in READ COMMITTED
-- SESSION 1:
BEGIN;
SELECT status FROM employee WHERE id = 2; -- gets 'Not fired'
-- SESSION 2:
BEGIN;
UPDATE employee SET status = 'Fired by Session 2' WHERE id = 2;
COMMIT;
-- SESSION 2:
UPDATE employee SET status = 'Fired by Session 1' WHERE id = 2;
COMMIT; -- silently overwrites Session B update



SELECT ... FROM employee WHERE id = 2 FOR UPDATE
-- this locks the row so that no other session can change it until the first transaction finishes. Example:

-- SESSION A:
BEGIN;
SELECT status FROM employee WHERE id = 2 FOR UPDATE;
-- this locks row until SESSION A commits
Now, if Session B tries to update the same row, it will wait or fail, depending on lock timeout.