-- 1) Create table ‘table_to_delete’ and fill it with the following query:

CREATE TABLE table_to_delete AS
               SELECT 'veeeeeeery_long_string' || x AS col
               FROM generate_series(1,(10^7)::int) x; -- generate_series() creates 10^7 rows of sequential numbers from 1 to 10000000 (10^7)
               
-- 2) Lookup how much space this table consumes with the following query:

               SELECT *, pg_size_pretty(total_bytes) AS total,
                                    pg_size_pretty(index_bytes) AS INDEX,
                                    pg_size_pretty(toast_bytes) AS toast,
                                    pg_size_pretty(table_bytes) AS TABLE
               FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
                               FROM (SELECT c.oid,nspname AS table_schema,
                                                               relname AS TABLE_NAME,
                                                              c.reltuples AS row_estimate,
                                                              pg_total_relation_size(c.oid) AS total_bytes,
                                                              pg_indexes_size(c.oid) AS index_bytes,
                                                              pg_total_relation_size(reltoastrelid) AS toast_bytes
                                              FROM pg_class c
                                              LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                                              WHERE relkind = 'r'
                                              ) a
                                    ) a
               WHERE table_name LIKE '%table_to_delete%';
               
           	-- total_bytes 602,415,104,
            -- index_bytes 0,
            -- toast_bytes 8192
            -- table_bytes 602,406,912
            -- total 575 MB
            -- toast 8192 bytes
            -- table 575 MB
               
-- 3) Issue the following DELETE operation on ‘table_to_delete’:

DELETE FROM table_to_delete
               WHERE REPLACE(col, 'veeeeeeery_long_string','')::int % 3 = 0; -- removes 1/3 of all rows



-- a) 19 sec
-- b) 
	SELECT *, pg_size_pretty(total_bytes) AS total,
                                    pg_size_pretty(index_bytes) AS INDEX,
                                    pg_size_pretty(toast_bytes) AS toast,
                                    pg_size_pretty(table_bytes) AS TABLE
               FROM ( SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes
                               FROM (SELECT c.oid,nspname AS table_schema,
                                                               relname AS TABLE_NAME,
                                                              c.reltuples AS row_estimate,
                                                              pg_total_relation_size(c.oid) AS total_bytes,
                                                              pg_indexes_size(c.oid) AS index_bytes,
                                                              pg_total_relation_size(reltoastrelid) AS toast_bytes
                                              FROM pg_class c
                                              LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
                                              WHERE relkind = 'r'
                                              ) a
                                    ) a
               WHERE table_name LIKE '%table_to_delete%';


                    
           	-- total_bytes 602,611,712
            -- index_bytes 0,
            -- toast_bytes 8192
            -- table_bytes 602,603,520
            -- total 575 MB
            -- toast 8192 bytes
            -- table 575 MB
               
-- c)
VACUUM FULL VERBOSE table_to_delete;
-- public.table_to_delete": found 0 removable, 6666667 nonremovable row versions in 73536 pages

-- d)we see significant space reduction, because VACUUM FULL rewrites the table, compacting it and physically removing dead tuples.

-- e)

DROP TABLE IF EXISTS table_to_delete;
CREATE TABLE table_to_delete AS
SELECT 'veeeeeeery_long_string' || x AS col
FROM generate_series(1,(10^7)::int) x;

               
-- 4) 

TRUNCATE table_to_delete;

-- a) 1.052s
-- b) - c) TRUNCATE works instantly and frees all table space. It's much faster than DELETE + VACUUM FULL.



