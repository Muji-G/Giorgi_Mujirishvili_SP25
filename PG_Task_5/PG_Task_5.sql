SET search_path TO labs, public

DROP TABLE IF EXISTS test_joins_a, test_joins_b;
CREATE TABLE test_joins_a (id1 int, id2 int);
CREATE TABLE test_joins_b (id1 int, id2 int);

INSERT INTO test_joins_a
SELECT generate_series(1,10_000), 3;

INSERT INTO test_joins_b
SELECT generate_series(1,10_000), 3;

ANALYZE;          

-- query with inequality join
EXPLAIN ANALYZE
SELECT * FROM test_joins_a a, test_joins_b b
WHERE a.id1 > b.id1;


-- cross join query
EXPLAIN ANALYZE
SELECT *
FROM test_joins_a a
CROSS JOIN test_joins_b b;

--TASK 2
SET enable_nestloop = off;
SET enable_mergejoin = off;


EXPLAIN ANALYZE
SELECT * FROM test_joins_a a, test_joins_b b
WHERE a.id1 = b.id1;

EXPLAIN ANALYZE
SELECT *
FROM test_joins_a a
WHERE EXISTS (
  SELECT 1
  FROM test_joins_b b
  WHERE b.id1 = a.id1
);

RESET enable_nestloop;
RESET enable_mergejoin;

SET enable_hashjoin = off;
EXPLAIN ANALYZE
SELECT *
FROM test_joins_a a
WHERE EXISTS (
  SELECT 1
  FROM test_joins_b b
  WHERE b.id1 = a.id1
);

--TASK 3
EXPLAIN ANALYZE
SELECT *
FROM test_joins_a a
JOIN test_joins_b b ON a.id1 = b.id1;

SET enable_mergejoin = off;
EXPLAIN ANALYZE
SELECT *
FROM test_joins_a a
JOIN test_joins_b b ON a.id1 = b.id1;

SET enable_mergejoin = on;

--TASK 4
DROP TABLE IF EXISTS test_joins_c;
CREATE TABLE test_joins_c (
    id1 INT,
    id2 INT
);

INSERT INTO test_joins_c
SELECT generate_series(1, 1000000), (random() * 10)::INT;

ANALYZE test_joins_c;


EXPLAIN
SELECT c.id2
FROM test_joins_b b
JOIN test_joins_a a ON b.id1 = a.id1
LEFT JOIN test_joins_c c ON c.id1 = b.id1;

SET join_collapse_limit = 1;

EXPLAIN
SELECT c.id2
FROM test_joins_b b
JOIN test_joins_a a ON b.id1 = a.id1
LEFT JOIN test_joins_c c ON c.id1 = b.id1;

SET join_collapse_limit = 8;

--TASK 5
DROP TABLE IF EXISTS orders;
CREATE TABLE orders AS
SELECT 
    id AS order_id,
    (id * 10 * random() * 10)::int AS order_cost,
    'order number ' || id AS order_num
FROM generate_series(1, 1000) AS id;

DROP TABLE IF EXISTS stores;
CREATE TABLE stores (
    store_id INT,
    store_name TEXT,
    max_order_cost INT
);

INSERT INTO stores VALUES
    (1, 'grossery shop', 800),
    (2, 'bakery', 100),
    (3, 'manufactured goods', 3000)
ON CONFLICT DO NOTHING;


SELECT 
    s.store_id,
    s.store_name,
    o.order_id,
    o.order_cost,
    o.order_num
FROM stores s
LEFT JOIN LATERAL (
    SELECT *
    FROM orders o
    WHERE o.order_cost < s.max_order_cost
    ORDER BY o.order_cost DESC
    LIMIT 10
) o ON true;

--TASK 6
WITH RECURSIVE emp_hierarchy AS (
  SELECT 
    e.empno,
    e.mgr,
    e.ename,
    e.ename AS mngname,
    1 AS lvl
  FROM emp e
  WHERE e.mgr IS NULL 

  UNION ALL

  SELECT 
    e.empno,
    e.mgr,
    e.ename,
    eh.ename AS mngname,
    eh.lvl + 1
  FROM emp e
  JOIN emp_hierarchy eh ON e.mgr = eh.empno
)

SELECT * FROM emp_hierarchy
ORDER BY lvl, empno;


-- TASK 7
CREATE TABLE order_log (
    log_id integer primary key generated always as identity,
    order_id integer,
    order_cost integer,
    order_num text,
    action_type varchar(1) CHECK (action_type IN ('U','D')),
    log_date TIMESTAMPTZ DEFAULT now()
);

WITH updated_rows AS (
    UPDATE orders
    SET order_cost = order_cost / 2
    WHERE order_cost BETWEEN 100 AND 1000
    RETURNING order_id, order_cost * 2 AS old_order_cost, order_num
),
log_updates AS (
    INSERT INTO order_log (order_id, order_cost, order_num, action_type)
    SELECT order_id, old_order_cost, order_num, 'U'
    FROM updated_rows
    RETURNING 1
),
deleted_rows AS (
    DELETE FROM orders
    WHERE order_cost < 50
    RETURNING order_id, order_cost, order_num
),
log_deletes AS (
    INSERT INTO order_log (order_id, order_cost, order_num, action_type)
    SELECT order_id, order_cost, order_num, 'D'
    FROM deleted_rows
    RETURNING 1
)

select * from ORDER_LOG
