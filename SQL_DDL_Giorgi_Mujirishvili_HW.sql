-- I created the database in different script but I also put it in here too 
CREATE DATABASE subway_transport; 

-- Now I create the schema
CREATE SCHEMA IF NOT EXISTS subway_system;

-- Table: country
CREATE TABLE IF NOT EXISTS subway_system.country (
    country_ID SERIAL PRIMARY KEY,
    country_name VARCHAR(50) NOT NULL,
    country_code VARCHAR(30) NOT NULL UNIQUE,
    continent VARCHAR(30) NOT NULL
);

-- Table: city
CREATE TABLE IF NOT EXISTS subway_system.city (
    city_ID SERIAL PRIMARY KEY,
    city_name VARCHAR(70) NOT NULL,
    country_ID INT NOT NULL REFERENCES subway_system.country(country_ID),
    population INT CHECK (population >= 0)
);


-- Table: stations
CREATE TABLE IF NOT EXISTS subway_system.stations (
    station_ID SERIAL PRIMARY KEY,
    station_name VARCHAR(100) NOT NULL,
    location VARCHAR(150) NOT NULL,
    city_ID INT NOT NULL REFERENCES subway_system.city(city_ID),
    open_date DATE CHECK (open_date > DATE '2000-01-01'),
    status VARCHAR(20) NOT NULL
);


-- Table: line
CREATE TABLE IF NOT EXISTS subway_system.line (
    line_ID SERIAL PRIMARY KEY,
    line_name VARCHAR(100) NOT NULL,
    start_station_ID INT NOT NULL REFERENCES subway_system.stations(station_ID),
    end_station_ID INT NOT NULL REFERENCES subway_system.stations(station_ID),
    total_stations INT CHECK (total_stations > 0)
);


-- Table: route
CREATE TABLE IF NOT EXISTS subway_system.route (
    route_ID SERIAL PRIMARY KEY,
    line_ID INT NOT NULL REFERENCES subway_system.line(line_ID),
    station_ID INT NOT NULL REFERENCES subway_system.stations(station_ID),
    sequence_number INT CHECK (sequence_number >= 1)
);


-- Table: train
CREATE TABLE IF NOT EXISTS subway_system.train (
    train_ID SERIAL PRIMARY KEY,
    model VARCHAR(50) NOT NULL,
    capacity INT NOT NULL CHECK (capacity > 0),
    manufacture_year INT CHECK (manufacture_year >= 2000),
    status VARCHAR(20) NOT NULL
);

-- Table: schedule
CREATE TABLE IF NOT EXISTS subway_system.schedule (
    schedule_ID SERIAL PRIMARY KEY,
    line_ID INT NOT NULL REFERENCES subway_system.line(line_ID),
    operating_frequency VARCHAR(50) NOT NULL,
    start_time TIMESTAMP NOT NULL,
    end_time TIMESTAMP NOT NULL,
    required_trains INT CHECK (required_trains > 0),
    required_employees INT CHECK (required_employees > 0)
);


-- Table: train_schedule
CREATE TABLE IF NOT EXISTS subway_system.train_schedule (
    train_schedule_ID SERIAL PRIMARY KEY,
    train_ID INT NOT NULL REFERENCES subway_system.train(train_ID),
    schedule_ID INT NOT NULL REFERENCES subway_system.schedule(schedule_ID),
    assignment_date DATE CHECK (assignment_date > DATE '2000-01-01'),
    shift VARCHAR(20) NOT NULL
);


-- Table: position
CREATE TABLE IF NOT EXISTS subway_system.position (
    position_ID SERIAL PRIMARY KEY,
    title VARCHAR(50) NOT NULL,
    description TEXT
);

-- Table: employee
CREATE TABLE IF NOT EXISTS subway_system.employee (
    employee_ID SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    position_ID INT NOT NULL REFERENCES subway_system.position(position_ID),
    assigned_station_ID INT REFERENCES subway_system.stations(station_ID),
    hire_date DATE CHECK (hire_date > DATE '2000-01-01'),
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(30)
);


-- Table: maintenance_type
CREATE TABLE IF NOT EXISTS subway_system.maintenance_type (
    maintenance_type_ID SERIAL PRIMARY KEY,
    type_name VARCHAR(30) NOT NULL,
    description TEXT
);


-- Table: infrastructure
CREATE TABLE IF NOT EXISTS subway_system.infrastructure (
    infrastructure_ID SERIAL PRIMARY KEY,
    type VARCHAR(30) NOT NULL,
    location VARCHAR(150) NOT NULL,
    installation_date DATE,
    last_inspection_date DATE,
    status VARCHAR(20)
);

-- Table: maintenance_task
CREATE TABLE IF NOT EXISTS subway_system.maintenance_task (
    maintenance_task_ID SERIAL PRIMARY KEY,
    infrastructure_ID INT NOT NULL REFERENCES subway_system.infrastructure(infrastructure_ID),
    maintenance_type_ID INT NOT NULL REFERENCES subway_system.maintenance_type(maintenance_type_ID),
    scheduled_date DATE CHECK (scheduled_date > DATE '2000-01-01'),
    completion_date DATE,
    employee_ID INT REFERENCES subway_system.employee(employee_ID),
    description TEXT,
    cost DECIMAL(10,2) CHECK (cost >= 0)
);


-- Table: passenger
CREATE TABLE IF NOT EXISTS subway_system.passenger (
    passenger_ID SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(70),
    phone VARCHAR(20),
    registration_date DATE CHECK (registration_date > DATE '2000-01-01'),
    country_ID INT NOT NULL REFERENCES subway_system.country(country_ID)
);

-- Table: ticket_type
CREATE TABLE IF NOT EXISTS subway_system.ticket_type (
    ticket_type_ID SERIAL PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL,
    price DECIMAL(8,2) NOT NULL CHECK (price >= 0),
    discount_rate DECIMAL(4,2) CHECK (discount_rate >= 0)
);


-- Table: promotions
CREATE TABLE IF NOT EXISTS subway_system.promotions (
    promotion_ID SERIAL PRIMARY KEY,
    ticket_type_ID INT NOT NULL REFERENCES subway_system.ticket_type(ticket_type_ID),
    promotion_name VARCHAR(100) NOT NULL,
    description TEXT,
    start_date DATE CHECK (start_date > DATE '2000-01-01'),
    end_date DATE CHECK (end_date > DATE '2000-01-01'),
    discount_percentage DECIMAL(4,2) CHECK (discount_percentage >= 0)
);


-- Table: ticket
CREATE TABLE IF NOT EXISTS subway_system.ticket (
    ticket_ID SERIAL PRIMARY KEY,
    ticket_type_ID INT NOT NULL REFERENCES subway_system.ticket_type(ticket_type_ID),
    passenger_ID INT NOT NULL REFERENCES subway_system.passenger(passenger_ID),
    route_ID INT NOT NULL REFERENCES subway_system.route(route_ID),
    purchase_date TIMESTAMP NOT NULL,
    valid_until TIMESTAMP NOT NULL,
    price DECIMAL(8,2) NOT NULL CHECK (price >= 0)
);

-- Now let's add data to our tables. All INSERTs use ON CONFLICT DO NOTHING for rerunnability

-- Country
INSERT INTO subway_system.country (country_name, country_code, continent) VALUES
('Georgia', 'GE', 'Europe'),
('Armenia', 'AM', 'Asia')
ON CONFLICT DO NOTHING;


-- City
INSERT INTO subway_system.city (city_name, country_ID, population) VALUES
('Tbilisi', 1, 1200000),
('Gyumri', 2, 120000)
ON CONFLICT DO NOTHING;


-- Stations
INSERT INTO subway_system.stations (station_name, location, city_ID, open_date, status) VALUES
('Rustaveli', 'Rustaveli Ave, Tbilisi', 1, '2001-06-01', 'active'),
('Freedom Square', 'Freedom Sq, Tbilisi', 1, '2002-09-12', 'active')
ON CONFLICT DO NOTHING;

-- Line
INSERT INTO subway_system.line (line_name, start_station_ID, end_station_ID, total_stations) VALUES
('Red Line', 1, 2, 8),
('Green Line', 2, 1, 6)
ON CONFLICT DO NOTHING;

-- Route
INSERT INTO subway_system.route (line_ID, station_ID, sequence_number) VALUES
(1, 1, 1), (1, 2, 2),
(2, 2, 1), (2, 1, 2)
ON CONFLICT DO NOTHING;

-- Train
INSERT INTO subway_system.train (model, capacity, manufacture_year, status) VALUES
('Tbilisi-M1', 280, 2008, 'active'),
('Tbilisi-M2', 260, 2012, 'active')
ON CONFLICT DO NOTHING;

-- Schedule
INSERT INTO subway_system.schedule (line_ID, operating_frequency, start_time, end_time, required_trains, required_employees) VALUES
(1, 'Every 7 mins', '2025-01-01 06:00:00', '2025-01-01 23:00:00', 2, 4),
(2, 'Every 12 mins', '2025-01-01 05:30:00', '2025-01-01 22:30:00', 2, 3)
ON CONFLICT DO NOTHING;

-- Train Schedule
INSERT INTO subway_system.train_schedule (train_ID, schedule_ID, assignment_date, shift) VALUES
(1, 1, '2025-04-20', 'Morning'),
(2, 2, '2025-04-20', 'Evening')
ON CONFLICT DO NOTHING;

-- Position
INSERT INTO subway_system.position (title, description) VALUES
('Driver', 'Responsible for train operations'),
('Technician', 'Handles train maintenance')
ON CONFLICT DO NOTHING;

-- Employee
INSERT INTO subway_system.employee (first_name, last_name, position_ID, assigned_station_ID, hire_date, email, phone) VALUES
('Nino', 'Kiknadze', 1, 1, '2021-05-01', 'nino.k@gmail.com', '599123456'),
('Giorgi', 'Beridze', 2, 2, '2019-08-10', 'giorgi.b@gmail.com', '599654321')
ON CONFLICT DO NOTHING;

-- Maintenance Type
INSERT INTO subway_system.maintenance_type (type_name, description) VALUES
('Electrical', 'Electrical system maintenance'),
('Structural', 'Structural safety checks')
ON CONFLICT DO NOTHING;

-- Infrastructure
INSERT INTO subway_system.infrastructure (type, location, installation_date, last_inspection_date, status) VALUES
('Tunnel', 'Tbilisi Line A', '2004-07-15', '2025-01-01', 'Good'),
('Bridge', 'Mtkvari River Overpass', '2006-03-20', '2025-03-01', 'Good')
ON CONFLICT DO NOTHING;

-- Maintenance Task
INSERT INTO subway_system.maintenance_task (infrastructure_ID, maintenance_type_ID, scheduled_date, completion_date, employee_ID, description, cost) VALUES
(1, 1, '2025-04-01', '2025-04-02', 2, 'Signal relay check', 180.00),
(2, 2, '2025-04-05', NULL, 2, 'Bridge inspection', 120.00)
ON CONFLICT DO NOTHING;

-- Passenger
INSERT INTO subway_system.passenger (first_name, last_name, email, phone, registration_date, country_ID) VALUES
('Dato', 'Gelashvili', 'dato.g@gmail.com', '593123456', '2023-06-01', 1),
('Nana', 'Melikidze', 'nana.m@gmail.com', '593789012', '2023-07-15', 1)
ON CONFLICT DO NOTHING;

-- Ticket Type
INSERT INTO subway_system.ticket_type (type_name, price, discount_rate) VALUES
('Standard', 1.00, 0),
('Student', 0.50, 0.20)
ON CONFLICT DO NOTHING;

-- Promotions
INSERT INTO subway_system.promotions (ticket_type_ID, promotion_name, description, start_date, end_date, discount_percentage) VALUES
(2, 'Student Spring Promo', 'Discount for students in spring', '2025-03-01', '2025-05-31', 20.00),
(1, 'Tbilisoba Special', 'Festival discount', '2025-10-01', '2025-10-10', 10.00)
ON CONFLICT DO NOTHING;

-- Ticket
INSERT INTO subway_system.ticket (ticket_type_ID, passenger_ID, route_ID, purchase_date, valid_until, price) VALUES
(1, 1, 1, '2025-04-20 09:00:00', '2025-04-20 23:59:00', 1.00),
(2, 2, 2, '2025-04-20 10:00:00', '2025-04-20 23:59:00', 0.40)
ON CONFLICT DO NOTHING;



-- Now lets add record_ts column to each table

ALTER TABLE subway_system.country ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway_system.city ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway_system.stations ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway_system.line ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway_system.route ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway_system.train ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway_system.schedule ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway_system.train_schedule ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway_system.position ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway_system.employee ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway_system.maintenance_type ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway_system.infrastructure ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway_system.maintenance_task ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway_system.passenger ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway_system.ticket_type ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway_system.promotions ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE subway_system.ticket ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;





