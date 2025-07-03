CREATE DATABASE supermarket_dw;

--Creatinh schema for dimensional model
CREATE SCHEMA IF NOT EXISTS BL_DM;

--Creating DIM_TIME_DAY table
CREATE TABLE IF NOT EXISTS BL_DM.DIM_TIME_DAY (
    DATE_ID          INTEGER PRIMARY KEY,               -- surrogate key (YYYYMMDD)
    DATE_ACT         DATE NOT NULL,                     -- actual calendar date
    YEAR_NO          INTEGER NOT NULL CHECK (YEAR_NO BETWEEN 1900 AND 2100),
    MONTH_NO         INTEGER NOT NULL CHECK (MONTH_NO BETWEEN 1 AND 12),
    DAY_NO           INTEGER NOT NULL CHECK (DAY_NO BETWEEN 1 AND 31),
    WEEK_NO          INTEGER NOT NULL CHECK (WEEK_NO BETWEEN 1 AND 53),
    WEEKDAY_NO       INTEGER NOT NULL CHECK (WEEKDAY_NO BETWEEN 0 AND 6),
    WEEKDAY_NAME     VARCHAR(10) NOT NULL CHECK (
        WEEKDAY_NAME IN (
            'Sunday', 'Monday', 'Tuesday', 'Wednesday',
            'Thursday', 'Friday', 'Saturday'
        )
    ),
    MONTH_NAME       VARCHAR(10) NOT NULL CHECK (
        MONTH_NAME IN (
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
        )
    ),
    QUARTER_NO       INTEGER NOT NULL CHECK (QUARTER_NO BETWEEN 1 AND 4),
    TA_INSERT_DT     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    TA_UPDATE_DT     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

--Insert data with
START TRANSACTION;

INSERT INTO BL_DM.DIM_TIME_DAY (
    DATE_ID,
    DATE_ACT,
    YEAR_NO,
    MONTH_NO,
    DAY_NO,
    WEEK_NO,
    WEEKDAY_NO,
    WEEKDAY_NAME,
    MONTH_NAME,
    QUARTER_NO
)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INTEGER          AS DATE_ID,
    d                                        AS DATE_ACT,
    EXTRACT(YEAR FROM d)::INTEGER            AS YEAR_NO,
    EXTRACT(MONTH FROM d)::INTEGER           AS MONTH_NO,
    EXTRACT(DAY FROM d)::INTEGER             AS DAY_NO,
    EXTRACT(WEEK FROM d)::INTEGER            AS WEEK_NO,
    EXTRACT(DOW FROM d)::INTEGER             AS WEEKDAY_NO,
    TRIM(TO_CHAR(d, 'Day'))                  AS WEEKDAY_NAME,
    TRIM(TO_CHAR(d, 'Month'))                AS MONTH_NAME,
    EXTRACT(QUARTER FROM d)::INTEGER         AS QUARTER_NO
FROM generate_series(
    DATE '2000-01-01',
    DATE '2050-12-31',
    INTERVAL '1 day'
) AS d
ON CONFLICT DO NOTHING;

COMMIT;
