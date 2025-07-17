SET search_path = labs, public;

-- creating table test_index_plan
CREATE TABLE IF NOT EXISTS test_index_plan (
    num FLOAT8 NOT NULL,
    load_date TIMESTAMPTZ NOT NULL
);

-- inserting the data into the table
INSERT INTO test_index_plan (num, load_date)
SELECT random(), x
FROM   generate_series(
           '2017-01-01 00:00'::timestamptz,
           '2021-12-31 23:59:59'::timestamptz,
           '10 seconds'::interval) AS x;

SET max_parallel_workers_per_gather = 0;

EXPLAIN
SELECT * 
FROM test_index_plan
WHERE load_date BETWEEN '2021-09-01 00:00' AND '2021-10-31 23:59:59'
ORDER BY num;

EXPLAIN ANALYZE
SELECT * 
FROM test_index_plan
WHERE load_date BETWEEN '2021-09-01 00:00' AND '2021-10-31 23:59:59'
ORDER BY num;


EXPLAIN (ANALYZE, BUFFERS)
SELECT * 
FROM test_index_plan
WHERE load_date BETWEEN '2021-09-01 00:00' AND '2021-10-31 23:59:59'
ORDER BY num;


-- TASK 1.2
-- 1. creating an index
CREATE INDEX IF NOT EXISTS idx_test_index_plan_loaddate
    ON test_index_plan (load_date);

-- refreshing statistics so the planner knows about the new index
ANALYZE test_index_plan;

-- disabling parallel workers
SET max_parallel_workers_per_gather = 0;

-- 1st
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM   test_index_plan
WHERE  load_date BETWEEN '2021-09-01 00:00'
                       AND '2021-10-31 11:59:59'
ORDER  BY 1;          

-- 2nd
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM   test_index_plan
WHERE  load_date BETWEEN '2021-09-01 00:00'
                       AND '2021-10-31 11:59:59'
ORDER  BY 1;

-- 1.2.3
-- dropping the index if it exists
DROP INDEX IF EXISTS idx_test_index_plan_loaddate;

-- creating covering index that includes both columns used in the query
CREATE INDEX idx_test_index_plan_covering
    ON test_index_plan (load_date, num);


-- re running the query
SET max_parallel_workers_per_gather = 0;

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM test_index_plan
WHERE load_date BETWEEN '2021-09-01 00:00' AND '2021-10-31 11:59:59'
ORDER BY num;

-- 1.2.4
-- dropping all existing indexes
DROP INDEX IF EXISTS idx_test_index_plan_loaddate;
DROP INDEX IF EXISTS idx_test_index_plan_covering;

-- creating BRIN index
CREATE INDEX idx_test_index_plan_loaddate_brin
    ON test_index_plan USING brin (load_date);

ANALYZE test_index_plan;

SET max_parallel_workers_per_gather = 0;

-- first run 
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM test_index_plan
WHERE load_date BETWEEN '2021-09-01 00:00'
                     AND '2021-10-31 11:59:59'
ORDER BY 1;

-- second run 
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM test_index_plan
WHERE load_date BETWEEN '2021-09-01 00:00'
                     AND '2021-10-31 11:59:59'
ORDER BY 1;

-- TASK 3
CREATE TABLE IF NOT EXISTS test_inserts (
    num        FLOAT NOT NULL,
    load_date  TIMESTAMPTZ NOT NULL
);

CREATE INDEX idx_test_inserts_loaddate
    ON test_inserts (load_date);

INSERT INTO test_inserts (num, load_date)
SELECT num, load_date
FROM test_index_plan;

CREATE TABLE emp (
    empno     NUMERIC(4)  NOT NULL CONSTRAINT emp_pk PRIMARY KEY,
    ename     VARCHAR(10) UNIQUE,
    job       VARCHAR(9),
    mgr       NUMERIC(4),
    hiredate  DATE
);

INSERT INTO emp (empno, ename, job, mgr, hiredate)
VALUES 
    (1,'SMITH','CLERK',13,'1980-12-17'),
    (2,'ALLEN','SALESMAN',6,'1981-02-20'),
    (3,'WARD','SALESMAN',6,'1981-02-22'),
    (4,'JONES','MANAGER',9,'1981-04-02'),
    (5,'MARTIN','SALESMAN',6,'1981-09-28'),
    (6,'BLAKE','MANAGER',9,'1981-05-01'),
    (7,'CLARK','MANAGER',9,'1981-06-09'),
    (8,'SCOTT','ANALYST',4,'1987-04-19'),
    (9,'KING','PRESIDENT',NULL,'1981-11-17'),
    (10,'TURNER','SALESMAN',6,'1981-09-08'),
    (11,'ADAMS','CLERK',8,'1987-05-23'),
    (12,'JAMES','CLERK',6,'1981-12-03'),
    (13,'FORD','ANALYST',4,'1981-12-03'),
    (14,'MILLER','CLERK',7,'1982-01-23');

-- TASK 2.2.4
COPY (
    SELECT num, '"' || load_date || '"' AS load_date
    FROM test_index_plan
) TO 'D:/postgresql_exports/test_index_plan_quoted.csv'
DELIMITER ',' CSV HEADER;

COPY (
    SELECT num, load_date
    FROM test_index_plan
    WHERE load_date BETWEEN '2021-09-01 00:00' AND '2021-09-01 11:59:59'
) TO 'D:/postgresql_exports/test_index_plan_filtered.csv'
DELIMITER ',' CSV HEADER;

CREATE TABLE test_copy (
    num        FLOAT NOT NULL,
    load_date  TIMESTAMPTZ NOT NULL
);

CREATE INDEX idx_test_copy_loaddate
    ON test_copy (load_date);


COPY test_copy (num, load_date)
FROM 'D:/postgresql_exports/test_index_plan_quoted.csv'
DELIMITER ',' CSV HEADER;

-- TASK 5
INSERT INTO emp (empno, ename, job, mgr, hiredate)
VALUES 
    (1,  'SMITH',  'MANAGER', 13, '2021-12-01'),
    (14, 'KELLY',  'CLERK',    1, '2021-12-01'),
    (15, 'HANNAH', 'CLERK',    1, '2021-12-01'),
    (11, 'ADAMS',  'SALESMAN',8, '2021-12-01'),
    (4,  'JONES',  'ANALIST',  9, '2021-12-01') 
ON CONFLICT (empno)
DO UPDATE
SET 
    ename    = EXCLUDED.ename,
    job      = EXCLUDED.job,
    mgr      = EXCLUDED.mgr,
    hiredate = EXCLUDED.hiredate;
