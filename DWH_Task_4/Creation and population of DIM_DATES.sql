--Creating the DIM_DATES table
CREATE TABLE IF NOT EXISTS DIM_DATES (
    DATE_KEY         INTEGER PRIMARY KEY,               -- surrogate key (YYYYMMDD)
    DATE_ACT         DATE NOT NULL,                     -- actual calendar date
    YEAR_NO          INTEGER NOT NULL CHECK (YEAR_NO BETWEEN 1900 AND 2100), -- calendar year
    MONTH_NO         INTEGER NOT NULL CHECK (MONTH_NO BETWEEN 1 AND 12), -- month number
    DAY_NO           INTEGER NOT NULL CHECK (DAY_NO BETWEEN 1 AND 31), -- day of the month
    WEEK_NO          INTEGER NOT NULL CHECK (WEEK_NO BETWEEN 1 AND 53),	-- week number
    WEEKDAY_NO       INTEGER NOT NULL CHECK (WEEKDAY_NO BETWEEN 0 AND 6), -- weekday number
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

    INSERT_DT        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UPDATE_DT        TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- Populating DIM_DATES with a range from 2000-01-01 to 2050-12-31
INSERT INTO DIM_DATES (
    DATE_KEY,
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
    TO_CHAR(d, 'YYYYMMDD')::INTEGER          AS DATE_KEY,
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
) AS d;

ON CONFLICT (DATE_KEY) DO NOTHING;
