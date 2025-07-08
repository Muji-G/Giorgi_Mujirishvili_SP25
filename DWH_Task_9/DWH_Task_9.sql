create database test_db;

SELECT d.oid, d.datname, d.datistemplate, d.datallowconn, t.spcname
FROM pg_database d
JOIN pg_tablespace t ON t.oid = d.dattablespace;

SHOW data_directory;

CREATE TABLESPACE mytablespace
LOCATION 'D:/pg_tablespaces/tblspc_test';

SELECT * FROM pg_tablespace;

ALTER DATABASE test_db SET TABLESPACE mytablespace 

-- this part isn't running yet because it has connection to test_db
-- so I terminated the connection and ran this part in different db 

SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'test_db';

SELECT d.oid, d.datname, d.datistemplate, d.datallowconn, t.spcname
FROM pg_database d
JOIN pg_tablespace t ON t.oid = d.dattablespace;

-- TASK 2.3
CREATE SCHEMA IF NOT EXISTS labs;

CREATE TABLE IF NOT EXISTS labs.person (
    id INTEGER NOT NULL,
    name VARCHAR(15)
);

SHOW search_path; --public, public, "$user"

SET search_path TO labs;

INSERT INTO person VALUES (1, 'Bob');
INSERT INTO person VALUES (2, 'Alice');
INSERT INTO person VALUES (3, 'Robert');

-- TASK 3.1

CREATE EXTENSION IF NOT EXISTS pageinspect;

SELECT p.id, p.name, p.ctid, p.xmin, p.xmax
FROM labs.person p;


SELECT t_xmin, t_xmax, t_ctid,
tuple_data_split('labs.person'::regclass, t_data, t_infomask,
t_infomask2, t_bits)
FROM heap_page_items(get_raw_page('labs.person', 0));


-- transaction N1
BEGIN;
INSERT INTO labs.person VALUES (4, 'John');
COMMIT;

-- transaction N2
BEGIN;
UPDATE labs.person SET name = 'Alex' WHERE id = 2;
COMMIT;

-- 
BEGIN;
DELETE FROM labs.person WHERE id = 3;
COMMIT;

BEGIN;
INSERT INTO labs.person VALUES (999, 'Test');
DELETE FROM labs.person WHERE id = 999;
COMMIT;

SELECT p.id, p.name, p.ctid, p.xmin, p.xmax FROM labs.person p;

SELECT t_xmin, t_xmax, t_ctid,
tuple_data_split('labs.person'::regclass, t_data, t_infomask,
t_infomask2, t_bits)
FROM heap_page_items(get_raw_page('labs.person', 0));

-- TASK 3.2
SELECT t_xmin, t_xmax, t_ctid,
tuple_data_split('labs.person'::regclass, t_data, t_infomask,
t_infomask2, t_bits)
FROM heap_page_items(get_raw_page('labs.person', 0));

-- running vacuum
VACUUM labs.person;

-- inserting row
INSERT INTO labs.person VALUES (5, 'Sarah');

-- running vacuum full
VACUUM FULL labs.person;

SELECT * FROM labs.person;
SELECT p.ctid, p.xmin, p.xmax FROM labs.person p;

