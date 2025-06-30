CREATE SCHEMA IF NOT EXISTS sa_online;
CREATE SCHEMA IF NOT EXISTS sa_offline;

CREATE EXTENSION IF NOT EXISTS file_fdw;
CREATE SERVER IF NOT EXISTS file_server
FOREIGN DATA WRAPPER file_fdw;

CREATE FOREIGN TABLE sa_offline.ext_offline_orders (
    date_text              TEXT,
    time_text              TEXT,
    item_code              VARCHAR(20),
    quantity_sold          INT,
    unit_selling_price     FLOAT,
    sale_or_return         VARCHAR(10),
    discount               FLOAT,
    category_code          VARCHAR(20),
    wholesale_price        FLOAT,
    loss_rate              FLOAT,
    total_sales            FLOAT,
    cost                   FLOAT,
    gross_income           FLOAT,
    year                   INT,
    month                  INT,
    day                    INT,
    employee_id            VARCHAR(20),
    branch                 VARCHAR(50),
    city                   VARCHAR(50),
    source_system          VARCHAR(20),
    customer_id            VARCHAR(50),
    transaction_id         VARCHAR(50)
)
SERVER file_server
OPTIONS (
    filename 'C:/Users/Elitebook/Desktop/SourceSystem_Offline.csv',  
    format 'csv',
    header 'true'
);

SELECT * FROM sa_offline.ext_offline_orders LIMIT 5;

CREATE FOREIGN TABLE sa_online.ext_online_orders (
    raw_date             TEXT,              
    sale_time            TIME,              
    item_code            VARCHAR(20),
    quantity_sold        INT,
    unit_selling_price   FLOAT,
    sale_or_return       VARCHAR(10),
    discount             FLOAT,
    item_name            TEXT,
    category_code        VARCHAR(20),
    category_name        TEXT,
    wholesale_price      FLOAT,
    loss_rate            FLOAT,
    total_sales          FLOAT,
    cost                 FLOAT,
    gross_income         FLOAT,
    raw_datetime         TEXT,              
    year                 INT,
    month                INT,
    day                  INT,
    employee_id          VARCHAR(10),
    branch               VARCHAR(50),
    city                 VARCHAR(50),
    source_system        VARCHAR(20),
    transaction_id_1     VARCHAR(30),
    customer_id_1        VARCHAR(30),
    customer_id_2        VARCHAR(30),
    transaction_id_2     VARCHAR(30)
)
SERVER file_server
OPTIONS (
    filename 'C:/Users/Elitebook/Desktop/SourceSystem_Online.csv',  
    format 'csv',
    header 'true'
);


SELECT * FROM sa_online.ext_online_orders LIMIT 5;


CREATE TABLE IF NOT EXISTS sa_online.src_online_orders AS
SELECT DISTINCT * FROM sa_online.ext_online_orders;

CREATE TABLE IF NOT EXISTS sa_offline.src_offline_orders AS
SELECT DISTINCT * FROM sa_offline.ext_offline_orders;
