CREATE SCHEMA subway;

CREATE TABLE subway.country (
    country_ID INT PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL,
    country_code VARCHAR(30) NOT NULL UNIQUE,
    continent VARCHAR(30) NOT NULL,
    CHECK (continent IN ('Asia', 'Europe', 'North America', 'South America', 'Africa', 'Oceania', 'Antarctica')),
    CHECK (country_name <> '')
);


CREATE TABLE subway.city (
    city_ID INT PRIMARY KEY,
    city_name VARCHAR(70) NOT NULL,
    country_ID INT NOT NULL REFERENCES subway.country(country_ID),
    population INT NOT NULL CHECK (population >= 0)
);


CREATE TABLE subway.stations (
    station_ID INT PRIMARY KEY,
    station_name VARCHAR(100) NOT NULL,
    location VARCHAR(150),
    city_ID INT NOT NULL REFERENCES subway.city(city_ID),
    open_date DATE NOT NULL CHECK (open_date > '2000-01-01'),
    status VARCHAR(20) NOT NULL CHECK (status IN ('active', 'inactive'))
);


CREATE TABLE subway.position (
    position_ID INT PRIMARY KEY,
    title VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
);


CREATE TABLE subway.employee (
    employee_ID INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    position_ID INT NOT NULL REFERENCES subway.position(position_ID),
    assigned_station_ID INT REFERENCES subway.stations(station_ID),
    hire_date DATE NOT NULL CHECK (hire_date > '2000-01-01'),
    email VARCHAR(100) UNIQUE CHECK (email LIKE '%@%._%'),
    phone VARCHAR(20)
);

CREATE TABLE subway.line (
    line_ID INT PRIMARY KEY,
    line_name VARCHAR(100) NOT NULL,
    start_station_ID INT NOT NULL REFERENCES subway.stations(station_ID),
    end_station_ID INT NOT NULL REFERENCES subway.stations(station_ID),
    total_stations INT NOT NULL CHECK (total_stations >= 0)
);


CREATE TABLE subway.route (
    route_ID INT PRIMARY KEY,
    line_ID INT NOT NULL REFERENCES subway.line(line_ID),
    station_ID INT NOT NULL REFERENCES subway.stations(station_ID),
    sequence_number INT NOT NULL CHECK (sequence_number > 0)
);


CREATE TABLE subway.schedule (
    schedule_ID INT PRIMARY KEY,
    line_ID INT NOT NULL REFERENCES subway.line(line_ID),
    operating_frequency VARCHAR(50) NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    required_trains INT NOT NULL CHECK (required_trains >= 0),
    required_employees INT NOT NULL CHECK (required_employees >= 0)
);


CREATE TABLE subway.train (
    train_ID INT PRIMARY KEY,
    model VARCHAR(50) NOT NULL,
    capacity INT NOT NULL CHECK (capacity >= 0),
    manufacture_year INT NOT NULL CHECK (manufacture_year >= 2000),
    status VARCHAR(20) NOT NULL CHECK (status IN ('active', 'maintenance', 'decommissioned'))
);


CREATE TABLE subway.train_schedule (
    train_schedule_ID INT PRIMARY KEY,
    train_ID INT NOT NULL REFERENCES subway.train(train_ID),
    schedule_ID INT NOT NULL REFERENCES subway.schedule(schedule_ID),
    assignment_date DATE NOT NULL CHECK (assignment_date > '2000-01-01'),
    shift VARCHAR(20) NOT NULL CHECK (shift IN ('morning', 'afternoon', 'night'))
);

CREATE TABLE subway.infrastructure (
    infrastructure_ID INT PRIMARY KEY,
    type VARCHAR(50) NOT NULL,
    location VARCHAR(100) NOT NULL,
    installation_date DATE NOT NULL CHECK (installation_date > '2000-01-01'),
    last_inspection_date DATE CHECK (last_inspection_date > '2000-01-01'),
    status VARCHAR(20) NOT NULL CHECK (status IN ('active', 'under_maintenance', 'retired'))
);

CREATE TABLE subway.maintenance_type (
    maintenance_type_ID INT PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL,
    description TEXT
);

CREATE TABLE subway.maintenance_task (
    maintenance_task_ID INT PRIMARY KEY,
    infrastructure_ID INT NOT NULL REFERENCES subway.infrastructure(infrastructure_ID),
    maintenance_type_ID INT NOT NULL REFERENCES subway.maintenance_type(maintenance_type_ID),
    scheduled_date DATE NOT NULL CHECK (scheduled_date > '2000-01-01'),
    completion_date DATE,
    employee_ID INT REFERENCES subway.employee(employee_ID),
    description TEXT,
    cost DECIMAL(10,2) CHECK (cost >= 0)
);

CREATE TABLE subway.ticket_type (
    ticket_type_ID INT PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL,
    price DECIMAL(8,2) NOT NULL CHECK (price >= 0),
    discount_rate DECIMAL(4,2) CHECK (discount_rate >= 0)
);

CREATE TABLE subway.promotions (
    promotion_ID INT PRIMARY KEY,
    ticket_type_ID INT NOT NULL REFERENCES subway.ticket_type(ticket_type_ID),
    promotion_name VARCHAR(100) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL CHECK (start_date > '2000-01-01'),
    end_date DATE CHECK (end_date > '2000-01-01'),
    discount_percentage DECIMAL(4,2) NOT NULL CHECK (discount_percentage >= 0)
);


CREATE TABLE subway.passenger (
    passenger_ID INT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE,
    registration_date DATE NOT NULL CHECK (registration_date > '2000-01-01'),
    country_ID INT NOT NULL REFERENCES subway.country(country_ID)
);


CREATE TABLE subway.ticket (
    ticket_ID INT PRIMARY KEY,
    ticket_type_ID INT NOT NULL REFERENCES subway.ticket_type(ticket_type_ID),
    passenger_ID INT NOT NULL REFERENCES subway.passenger(passenger_ID),
    route_ID INT NOT NULL REFERENCES subway.route(route_ID),
    purchase_date TIMESTAMP NOT NULL CHECK (purchase_date > '2000-01-01'),
    valid_until TIMESTAMP NOT NULL CHECK (valid_until > '2000-01-01'),
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0)
);

-- Inserting data
INSERT INTO subway.country VALUES 
(1, 'Georgia', 'GEO', 'Europe'), 
(2, 'Azerbaijan', 'AZ', 'Asia');

INSERT INTO subway.city VALUES
(1, 'Tbilisi', 1, 1152000),
(2, 'Baku', 2, 2420000);

INSERT INTO subway.stations VALUES
(1, 'Liberty Square Station', 'Tbilisi', 1, '2003-01-04'::DATE, 'active'),
(2, '28 May Station', 'Baku', 2, '2004-02-05'::DATE, 'active');

INSERT INTO subway.line VALUES
(1, 'Tbilisi Line 1', 1, 1, 1),
(2, 'Baku Green Line', 2, 2, 1);

INSERT INTO subway.route VALUES
(1, 1, 1, 1),
(2, 2, 2, 1);

INSERT INTO subway.schedule VALUES
(1, 1, '10 times per day','2025-04-07 08:00', '2025-04-07 08:10', 2, 5),
(2, 2, '15 times per day','2025-04-07 09:30', '2025-04-07 09:45', 4, 12);

INSERT INTO subway.train VALUES
(1, 'Tbilisi Metro T1', 300, 2009, 'active'),
(2, 'Baku Metro B2', 320, 2007, 'maintenance');

INSERT INTO subway.train_schedule VALUES
(1, 1, 1, '2025-04-08'::DATE, 'night'),
(2, 2, 2, '2025-04-09'::DATE, 'morning');

INSERT INTO subway.position VALUES
(1, 'Train Operator'),
(2, 'Station Supervisor');

INSERT INTO subway.employee VALUES
(1, 'Nino','Beridze', 1, 2, '2020-01-15'::DATE, 'Nino@gmail.com', '+995124272'),
(2, 'Giorgi', 'Mujiri', 2, 1, '2018-09-30'::DATE, 'Gio@gmail.com','+9955555542');

INSERT INTO subway.infrastructure VALUES
(1, 'Control Room', 'Tbilisi', '2017-02-09'::DATE, '2024-09-12'::DATE, 'retired'),
(2, 'Escalator', 'Baku', '2021-12-12'::DATE, '2025-01-04'::DATE, 'active');

INSERT INTO subway.maintenance_type VALUES
(1, 'Electrical Check'),
(2, 'Track Alignment');

INSERT INTO subway.maintenance_task VALUES
(1, 1, 1, '2025-03-01'::DATE, '2025-03-04'::DATE, 1, 'Rebuilding of whole room', 20000.00),
(2, 2, 2, '2025-03-10'::DATE, '2025-03-12'::DATE, 2, 'Changing escalator', 14000.00);

INSERT INTO subway.ticket_type VALUES
(1, 'Standard', 29.99, 10.00),
(2, 'Student', 19.99, 5.00);

INSERT INTO subway.promotions VALUES
(1, 1, 'Weekend Promo', '', '2025-04-01'::DATE, '2025-04-08'::DATE, 5.00),
(2, 1, 'Student Discount','', '2025-01-01'::DATE, '2025-12-12'::DATE, 20.00);

INSERT INTO subway.passenger VALUES
(1, 'Tamar', 'Gelashvili', 'tamar.gelashvili@example.com', '+995577288913', '2025-01-02'::DATE, 1),
(2, 'Mamuka', 'Shalikashvili', 'ali.mammadov@example.com', '+995673892093', '2024-02-02'::DATE, 1);

INSERT INTO subway.ticket VALUES
(1, 1, 1, 1, '2024-03-09 08:30', '2024-03-09 12:30', 1.50),
(2, 2, 2, 2, '2024-04-01 11:01', '2024-04-01 15:01', 0.80);


-- Altering tables

ALTER TABLE subway.country ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE;
ALTER TABLE subway.city ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE;
ALTER TABLE subway.stations ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE;
ALTER TABLE subway.line ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE;
ALTER TABLE subway.route ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE;
ALTER TABLE subway.schedule ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE;
ALTER TABLE subway.train ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE;
ALTER TABLE subway.train_schedule ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE;
ALTER TABLE subway.position ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE;
ALTER TABLE subway.employee ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE;
ALTER TABLE subway.infrastructure ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE;
ALTER TABLE subway.maintenance_type ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE;
ALTER TABLE subway.maintenance_task ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE;
ALTER TABLE subway.ticket_type ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE;
ALTER TABLE subway.promotions ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE;
ALTER TABLE subway.passenger ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE;
ALTER TABLE subway.ticket ADD COLUMN record_ts DATE DEFAULT CURRENT_DATE;

UPDATE subway.country SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
UPDATE subway.city SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
UPDATE subway.stations SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
UPDATE subway.line SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
UPDATE subway.route SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
UPDATE subway.schedule SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
UPDATE subway.train SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
UPDATE subway.train_schedule SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
UPDATE subway.position SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
UPDATE subway.employee SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
UPDATE subway.infrastructure SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
UPDATE subway.maintenance_type SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
UPDATE subway.maintenance_task SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
UPDATE subway.ticket_type SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
UPDATE subway.promotions SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
UPDATE subway.passenger SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;
UPDATE subway.ticket SET record_ts = CURRENT_DATE WHERE record_ts IS NULL;

ALTER TABLE subway.country ALTER COLUMN record_ts SET NOT NULL;
ALTER TABLE subway.city ALTER COLUMN record_ts SET NOT NULL;
ALTER TABLE subway.stations ALTER COLUMN record_ts SET NOT NULL;
ALTER TABLE subway.line ALTER COLUMN record_ts SET NOT NULL;
ALTER TABLE subway.route ALTER COLUMN record_ts SET NOT NULL;
ALTER TABLE subway.schedule ALTER COLUMN record_ts SET NOT NULL;
ALTER TABLE subway.train ALTER COLUMN record_ts SET NOT NULL;
ALTER TABLE subway.train_schedule ALTER COLUMN record_ts SET NOT NULL;
ALTER TABLE subway.position ALTER COLUMN record_ts SET NOT NULL;
ALTER TABLE subway.employee ALTER COLUMN record_ts SET NOT NULL;
ALTER TABLE subway.infrastructure ALTER COLUMN record_ts SET NOT NULL;
ALTER TABLE subway.maintenance_type ALTER COLUMN record_ts SET NOT NULL;
ALTER TABLE subway.maintenance_task ALTER COLUMN record_ts SET NOT NULL;
ALTER TABLE subway.ticket_type ALTER COLUMN record_ts SET NOT NULL;
ALTER TABLE subway.promotions ALTER COLUMN record_ts SET NOT NULL;
ALTER TABLE subway.passenger ALTER COLUMN record_ts SET NOT NULL;
ALTER TABLE subway.ticket ALTER COLUMN record_ts SET NOT NULL;

