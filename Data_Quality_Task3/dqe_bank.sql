CREATE SCHEMA IF NOT EXISTS dqe_task3;

CREATE EXTENSION IF NOT EXISTS file_fdw;
CREATE SERVER IF NOT EXISTS csv_ext_server FOREIGN DATA WRAPPER file_fdw;

CREATE FOREIGN TABLE IF NOT EXISTS dqe_task3.bank (
	age INT,
	job VARCHAR(100),
	marital VARCHAR(100),
	education VARCHAR(100),
	"default" VARCHAR(5),
	balance INT,
	housing VARCHAR(5),
	loan VARCHAR(5),
	contact VARCHAR(100),
	duration INT
	) SERVER csv_ext_server
	OPTIONS (
		filename '/Users/tianshani/Documents/Code/EPAM_DataAnalytics/DQE/bank.csv',
		format 'csv',
		header 'true'
		);

-- 1
SELECT min(age), max(age)
FROM dqe_task3.bank;

-- 2
SELECT DISTINCT marital
FROM dqe_task3.bank;

-- 3
SELECT DISTINCT "default"
FROM dqe_task3.bank;

SELECT DISTINCT housing
FROM dqe_task3.bank;

SELECT DISTINCT loan
FROM dqe_task3.bank;

-- 4
SELECT count(1)
FROM dqe_task3.bank
WHERE balance < 0 AND lower(loan) = 'no';

-- 5
SELECT DISTINCT contact
FROM dqe_task3.bank;

-- 6
SELECT DISTINCT job
FROM dqe_task3.bank;

SELECT DISTINCT education
FROM dqe_task3.bank;

-- 7


