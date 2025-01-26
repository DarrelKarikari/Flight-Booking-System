# Flight Booking System

An advanced MySQL database system for managing airline bookings, flights, and passenger information.

## Features

- Complete flight booking management
- Real-time seat availability tracking
- Price change auditing
- Passenger management
- Automated booking process
- Flight search functionality

## Requirements

- MySQL Server 8.0+
- MySQL Workbench (recommended)
- 50MB minimum storage space
- 4GB RAM recommended

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/flight-booking-system.git
cd flight-booking-system
```

2. Import database schema:
```bash
mysql -u your_username -p < schema.sql
```

3. Configure database connection:
- Copy `config.example.sql` to `config.sql`
- Update credentials in `config.sql`

## Database Structure

### Core Tables
- airports: Airport information
- airlines: Airline details
- aircraft: Aircraft inventory
- flights: Flight schedules and status
- passengers: Passenger information
- bookings: Booking records
- price_changes_audit: Price modification tracking

### Views
- available_flights: Real-time flight availability

### Stored Procedures
- book_flight: Process new bookings
- search_flights: Search available flights

## Usage

### Search for Flights
```sql
CALL search_flights('New York', 'London', '2024-02-01');
```

### Book a Flight
```sql
CALL book_flight(passenger_id, flight_id, seat_number, @booking_id);
```

### Check Available Seats
```sql
SELECT * FROM available_flights 
WHERE departure_city = 'New York' 
AND arrival_city = 'London';
```

## Security Features

- Transaction management
- Foreign key constraints
- Input validation
- Price change auditing
- Error handling

## Performance Optimization

- Indexed queries
- Optimized table structure
- Efficient stored procedures
- Minimal redundancy

## Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## License

MIT License - See LICENSE.md for details

## Support

For support, email: darrelkarikari@outlook.com
