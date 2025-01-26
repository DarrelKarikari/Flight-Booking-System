-- Create Database
CREATE DATABASE flight_booking_system;
USE flight_booking_system;

-- Create Tables with proper constraints and relationships
CREATE TABLE airports (
    airport_id CHAR(3) PRIMARY KEY,
    airport_name VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    country VARCHAR(50) NOT NULL,
    timezone VARCHAR(50) NOT NULL
);

CREATE TABLE airlines (
    airline_id CHAR(2) PRIMARY KEY,
    airline_name VARCHAR(100) NOT NULL,
    country_of_origin VARCHAR(50) NOT NULL
);

CREATE TABLE aircraft (
    aircraft_id VARCHAR(10) PRIMARY KEY,
    airline_id CHAR(2),
    model VARCHAR(50) NOT NULL,
    total_seats INT NOT NULL,
    manufacturing_year YEAR,
    FOREIGN KEY (airline_id) REFERENCES airlines(airline_id)
);

CREATE TABLE flights (
    flight_id VARCHAR(10) PRIMARY KEY,
    airline_id CHAR(2),
    aircraft_id VARCHAR(10),
    departure_airport CHAR(3),
    arrival_airport CHAR(3),
    departure_time DATETIME NOT NULL,
    arrival_time DATETIME NOT NULL,
    base_price DECIMAL(10,2) NOT NULL,
    status ENUM('Scheduled', 'Delayed', 'Boarding', 'In Air', 'Landed', 'Cancelled') DEFAULT 'Scheduled',
    FOREIGN KEY (airline_id) REFERENCES airlines(airline_id),
    FOREIGN KEY (aircraft_id) REFERENCES aircraft(aircraft_id),
    FOREIGN KEY (departure_airport) REFERENCES airports(airport_id),
    FOREIGN KEY (arrival_airport) REFERENCES airports(airport_id)
);

CREATE TABLE passengers (
    passenger_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    date_of_birth DATE NOT NULL,
    passport_number VARCHAR(20) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE bookings (
    booking_id VARCHAR(10) PRIMARY KEY,
    passenger_id INT,
    flight_id VARCHAR(10),
    seat_number VARCHAR(4) NOT NULL,
    booking_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    booking_status ENUM('Confirmed', 'Cancelled', 'Checked-in') DEFAULT 'Confirmed',
    total_price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (passenger_id) REFERENCES passengers(passenger_id),
    FOREIGN KEY (flight_id) REFERENCES flights(flight_id)
);

-- Create an audit table for tracking price changes
CREATE TABLE price_changes_audit (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    flight_id VARCHAR(10),
    old_price DECIMAL(10,2),
    new_price DECIMAL(10,2),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(50)
);

-- Create a trigger to track price changes
DELIMITER //
CREATE TRIGGER after_flight_price_update
AFTER UPDATE ON flights
FOR EACH ROW
BEGIN
    IF OLD.base_price != NEW.base_price THEN
        INSERT INTO price_changes_audit (flight_id, old_price, new_price, changed_by)
        VALUES (NEW.flight_id, OLD.base_price, NEW.base_price, CURRENT_USER());
    END IF;
END;//
DELIMITER ;

-- Create a view for available flights
CREATE VIEW available_flights AS
SELECT 
    f.flight_id,
    al.airline_name,
    dep.city AS departure_city,
    arr.city AS arrival_city,
    f.departure_time,
    f.arrival_time,
    f.base_price,
    (ac.total_seats - COUNT(b.booking_id)) AS available_seats
FROM flights f
JOIN airlines al ON f.airline_id = al.airline_id
JOIN airports dep ON f.departure_airport = dep.airport_id
JOIN airports arr ON f.arrival_airport = arr.airport_id
JOIN aircraft ac ON f.aircraft_id = ac.aircraft_id
LEFT JOIN bookings b ON f.flight_id = b.flight_id
WHERE f.departure_time > NOW()
AND f.status != 'Cancelled'
GROUP BY f.flight_id;

-- Create stored procedure for booking a flight
DELIMITER //
CREATE PROCEDURE book_flight(
    IN p_passenger_id INT,
    IN p_flight_id VARCHAR(10),
    IN p_seat_number VARCHAR(4),
    OUT p_booking_id VARCHAR(10)
)
BEGIN
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_available_seats INT;
    
    -- Start transaction
    START TRANSACTION;
    
    -- Check if flight exists and get price
    SELECT base_price, (ac.total_seats - COUNT(b.booking_id))
    INTO v_price, v_available_seats
    FROM flights f
    JOIN aircraft ac ON f.aircraft_id = ac.aircraft_id
    LEFT JOIN bookings b ON f.flight_id = b.flight_id
    WHERE f.flight_id = p_flight_id
    GROUP BY f.flight_id;
    
    -- Check if seats are available
    IF v_available_seats <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No seats available for this flight';
        ROLLBACK;
    END IF;
    
    -- Generate booking ID
    SET p_booking_id = CONCAT('BK', LPAD(FLOOR(RAND() * 1000000), 6, '0'));
    
    -- Create booking
    INSERT INTO bookings (booking_id, passenger_id, flight_id, seat_number, total_price)
    VALUES (p_booking_id, p_passenger_id, p_flight_id, p_seat_number, v_price);
    
    -- Commit transaction
    COMMIT;
END //
DELIMITER ;

-- Create stored procedure for flight search
DELIMITER //
CREATE PROCEDURE search_flights(
    IN p_departure_city VARCHAR(50),
    IN p_arrival_city VARCHAR(50),
    IN p_departure_date DATE
)
BEGIN
    SELECT 
        f.flight_id,
        al.airline_name,
        dep.city AS departure_city,
        arr.city AS arrival_city,
        f.departure_time,
        f.arrival_time,
        f.base_price,
        f.status,
        (ac.total_seats - COUNT(b.booking_id)) AS available_seats
    FROM flights f
    JOIN airlines al ON f.airline_id = al.airline_id
    JOIN airports dep ON f.departure_airport = dep.airport_id
    JOIN airports arr ON f.arrival_airport = arr.airport_id
    JOIN aircraft ac ON f.aircraft_id = ac.aircraft_id
    LEFT JOIN bookings b ON f.flight_id = b.flight_id
    WHERE dep.city = p_departure_city
    AND arr.city = p_arrival_city
    AND DATE(f.departure_time) = p_departure_date
    GROUP BY f.flight_id
    HAVING available_seats > 0;
END //
DELIMITER ;

-- Sample data insertion
INSERT INTO airports (airport_id, airport_name, city, country, timezone) VALUES
('JFK', 'John F. Kennedy International Airport', 'New York', 'USA', 'America/New_York'),
('LAX', 'Los Angeles International Airport', 'Los Angeles', 'USA', 'America/Los_Angeles'),
('LHR', 'London Heathrow Airport', 'London', 'UK', 'Europe/London');

INSERT INTO airlines (airline_id, airline_name, country_of_origin) VALUES
('AA', 'American Airlines', 'USA'),
('BA', 'British Airways', 'UK'),
('DL', 'Delta Air Lines', 'USA');

-- Index creation for performance optimization
CREATE INDEX idx_flight_search ON flights(departure_airport, arrival_airport, departure_time);
CREATE INDEX idx_booking_status ON bookings(booking_status);
CREATE INDEX idx_passenger_email ON passengers(email);

-- Example usage:
-- CALL search_flights('New York', 'London', '2024-02-01');
-- CALL book_flight(1, 'FL123', '12A', @booking_id);
