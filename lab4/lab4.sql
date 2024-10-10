/* 
    Droping tables:
*/
DROP TABLE IF EXISTS Ticket_number CASCADE;

DROP TABLE IF EXISTS Payment CASCADE;

DROP TABLE IF EXISTS Booking CASCADE;

DROP TABLE IF EXISTS Flight CASCADE;

DROP TABLE IF EXISTS Weekly_schedule CASCADE;

DROP TABLE IF EXISTS Route CASCADE;

DROP TABLE IF EXISTS Airport CASCADE;

DROP TABLE IF EXISTS Price_day CASCADE;

DROP TABLE IF EXISTS Price CASCADE;

DROP TABLE IF EXISTS Passenger CASCADE;

DROP PROCEDURE IF EXISTS addYear;

DROP PROCEDURE IF EXISTS addDay;

DROP PROCEDURE IF EXISTS addDestination;

DROP PROCEDURE IF EXISTS addRoute;

DROP PROCEDURE IF EXISTS addFlight;

DROP FUNCTION IF EXISTS calculateFreeSeats;

DROP FUNCTION IF EXISTS calculatePrice;

DROP PROCEDURE IF EXISTS addReservation;

DROP PROCEDURE IF EXISTS addPassenger;

DROP PROCEDURE IF EXISTS addContact;

DROP PROCEDURE IF EXISTS addPayment;

DROP TRIGGER IF EXISTS CreateTicket;

DROP VIEW IF EXISTS allFlights;


/* 
    Creation of tables:
*/

CREATE TABLE Passenger (
    NAME varchar(30),
    PASSPORT_NUMBER integer,


    constraint pk_passenger 
        primary key (PASSPORT_NUMBER)
);

CREATE TABLE Price (
    YEAR integer,
    PROFIT_FACTOR double,


    constraint pk_price 
        primary key (YEAR)
);
/*Had to add this table to make WEEKDAY_FACTOR work properly*/
CREATE TABLE Price_day (
    YEAR integer,
    DAY varchar(10),
    WEEKDAY_FACTOR double,



    constraint pk_price_day 
        primary key (YEAR, DAY)
);



CREATE TABLE Airport (
    AIRPORT_CODE varchar(3),
    COUNTRY varchar(30),
    AIRPORT_NAME varchar(30),


    constraint pk_airport 
        primary key (AIRPORT_CODE)
);

CREATE TABLE Route (
    ROUTE_ID integer AUTO_INCREMENT,
    ROUTE_PRICE double,
    ARRIVAL_CITY varchar(3),
    DEPARTURE_CITY varchar(3),
    YEAR integer,


    constraint pk_route 
        primary key (ROUTE_ID),
    constraint fk_route_arrival_airport
        FOREIGN KEY (ARRIVAL_CITY) references Airport(AIRPORT_CODE),
    constraint fk_route_departure_airport
        FOREIGN KEY (DEPARTURE_CITY) references Airport(AIRPORT_CODE)
);

CREATE TABLE Weekly_schedule (
    SCHEDULE_ID integer AUTO_INCREMENT,
    YEAR integer,
    DAY varchar(10),
    DEPARTURE_TIME time,
    R_id integer, 


    constraint pk_ws 
        primary key (SCHEDULE_ID),
    constraint fk_ws_route
        foreign key (R_id) references Route(ROUTE_ID)
);

CREATE TABLE Flight (
    FLIGHT_NUMBER integer AUTO_INCREMENT,
    WEEK integer,
    FLIGHT_SCHEDULE integer,


    constraint pk_flight 
        primary key (FLIGHT_NUMBER),
    constraint fk_flight_ws 
        FOREIGN KEY (FLIGHT_SCHEDULE) references Weekly_schedule(SCHEDULE_ID)
);

CREATE TABLE Booking (
    RESERVATION_NUMBER integer AUTO_INCREMENT,
    CONTACT_PHONE BIGINT,
    CONTACT_EMAIL varchar(30),
    AMOUNT_PAYED double,
    FLIGHT_NR_fk integer,


    constraint pk_booking 
        primary key (RESERVATION_NUMBER),
    constraint fk_booking_flight 
        FOREIGN KEY (FLIGHT_NR_fk) references Flight(FLIGHT_NUMBER)
);

CREATE TABLE Payment (
    PAYMENT_ID integer AUTO_INCREMENT,
    CREDIT_CARD_NUMBER BIGINT,
    CREDIT_CARD_HOLDER varchar(50), 
    R_NUMBER integer,


    constraint pk_payment 
        primary key (PAYMENT_ID),
    constraint fk_payment_booking 
        FOREIGN KEY (R_NUMBER) references Booking(RESERVATION_NUMBER)
);

CREATE TABLE Ticket_number (
    PASS_NUMBER_fk integer,
    RES_NUMBER_fk integer,
    TICKET_NR integer, 


    constraint pk_ticket_number
        primary key (PASS_NUMBER_fk, RES_NUMBER_fk, TICKET_NR),
    constraint fk_pass_nr_passenger 
        FOREIGN KEY (PASS_NUMBER_fk) references Passenger(PASSPORT_NUMBER),
    constraint fk_res_nr_booking 
        FOREIGN KEY (RES_NUMBER_fk) references Booking(RESERVATION_NUMBER)
);

/*
    Procedures:
*/

delimiter //
CREATE PROCEDURE addYear(IN y integer, IN factor double)
BEGIN
INSERT INTO Price
VALUES (y, factor);
end;
//
delimiter ;

delimiter //
CREATE PROCEDURE addDay(IN y integer, IN d varchar(10), IN factor double)
BEGIN
INSERT INTO Price_day(YEAR, DAY, WEEKDAY_FACTOR)
VALUES (y, d, factor);
end;
//
delimiter ;

delimiter //
CREATE PROCEDURE addDestination(IN AIRPORT_CODE varchar(3), IN AIRPORT_NAME varchar(30), IN COUNTRY varchar(30))
BEGIN
INSERT INTO Airport(AIRPORT_CODE, AIRPORT_NAME, COUNTRY)
VALUES (AIRPORT_CODE, AIRPORT_NAME, COUNTRY);
end;
//
delimiter ;

delimiter //
CREATE PROCEDURE addRoute(IN AIRPORT_CODE_DEPARTURE varchar(3), IN AIRPORT_CODE_ARRIVAL varchar(3)
, IN YEAR integer, IN ROUTE_PRICE double)
BEGIN
INSERT INTO Route(DEPARTURE_CITY, ARRIVAL_CITY, ROUTE_PRICE, YEAR)
VALUES (AIRPORT_CODE_DEPARTURE, AIRPORT_CODE_ARRIVAL, ROUTE_PRICE, YEAR);
end;
//
delimiter ;


delimiter //
CREATE PROCEDURE addFlight(IN AIRPORT_CODE_DEPARTURE varchar(3), IN AIRPORT_CODE_ARRIVAL varchar(3)
, IN YEAR integer, IN Day varchar(10), In DEPARTURE_TIME Time)
BEGIN
DECLARE count INT;
SET count = 1;

INSERT INTO Weekly_schedule(YEAR, DAY, DEPARTURE_TIME, R_id)
VALUES(YEAR, Day, DEPARTURE_TIME, (SELECT Route.ROUTE_ID FROM Route WHERE (Route.DEPARTURE_CITY = AIRPORT_CODE_DEPARTURE AND Route.ARRIVAL_CITY = AIRPORT_CODE_ARRIVAL AND Route.YEAR = YEAR)));

WHILE count <= 52 DO
    INSERT INTO Flight(WEEK, FLIGHT_SCHEDULE)
    VALUES(count, (SELECT Weekly_schedule.SCHEDULE_ID FROM Weekly_schedule WHERE (Weekly_schedule.YEAR = YEAR AND Weekly_schedule.DAY = DAY AND Weekly_schedule.DEPARTURE_TIME = DEPARTURE_TIME)));
    SET count = count + 1;
END WHILE;  

end;
//
delimiter ;


delimiter //
CREATE FUNCTION calculateFreeSeats(flightnumber INT)
RETURNS integer
BEGIN
    DECLARE total_seats integer;
    DECLARE seats_reserved integer;
    SET total_seats = 40;

    SELECT COUNT(*) INTO seats_reserved FROM Ticket_number WHERE Ticket_number.RES_NUMBER_fk IN (SELECT RESERVATION_NUMBER FROM Booking WHERE Booking.FLIGHT_NR_fk = flightnumber AND Booking.AMOUNT_PAYED is not NULL);


    RETURN total_seats - seats_reserved; 
END;
//
delimiter ;


delimiter //
CREATE FUNCTION calculatePrice(flightnumber INT)
RETURNS float
BEGIN
    DECLARE seat_price double;
    DECLARE w_scheduleID integer; 
    DECLARE r_price double; 
    DECLARE w_factor double;
    DECLARE booked_seats integer; 
    DECLARE p_factor double; 

    SELECT SCHEDULE_ID INTO w_scheduleID FROM Weekly_schedule WHERE Weekly_schedule.SCHEDULE_ID IN (SELECT Flight.FLIGHT_SCHEDULE FROM Flight WHERE Flight.FLIGHT_NUMBER = flightnumber);


    SELECT WEEKDAY_FACTOR INTO w_factor FROM Price_day WHERE (Price_day.Day IN(SELECT Weekly_schedule.DAY FROM Weekly_schedule WHERE(Weekly_schedule.SCHEDULE_ID = w_scheduleID)) AND Price_day.YEAR IN(SELECT Weekly_schedule.YEAR FROM Weekly_schedule WHERE(Weekly_schedule.SCHEDULE_ID = w_scheduleID)));

    SELECT ROUTE_PRICE INTO r_price FROM Route WHERE Route.ROUTE_ID IN (SELECT Weekly_schedule.R_id FROM Weekly_schedule WHERE Weekly_schedule.SCHEDULE_ID = w_scheduleID);

    SET booked_seats = 40 - calculateFreeSeats(flightnumber);

    SELECT PROFIT_FACTOR INTO p_factor FROM Price WHERE Price.YEAR IN (SELECT Weekly_schedule.YEAR FROM Weekly_schedule WHERE Weekly_schedule.SCHEDULE_ID = w_scheduleID);

    SET seat_price = r_price * w_factor * ((booked_seats + 1)/40) * p_factor;

    RETURN seat_price; 
END;
//
delimiter ;


delimiter //
CREATE TRIGGER CreateTicket
AFTER INSERT ON Payment
FOR EACH ROW 
BEGIN
    DECLARE nr integer;

	UPDATE Ticket_number as table_ticket, (SELECT RES_NUMBER_fk, PASS_NUMBER_fk, rand()*999999 as generated_ticketnr FROM Ticket_number Where (RES_NUMBER_fk = new.R_NUMBER)) as ticket_numbers
    SET table_ticket.TICKET_NR = ticket_numbers.generated_ticketnr + 1
    WHERE (table_ticket.RES_NUMBER_fk = ticket_numbers.RES_NUMBER_fk AND table_ticket.PASS_NUMBER_fk = ticket_numbers.PASS_NUMBER_fk);
    SELECT COUNT(*) INTO nr FROM Ticket_number as t1, Ticket_number as t2 Where ((t1.PASS_NUMBER_fk <> t2.PASS_NUMBER_fk OR t1.RES_NUMBER_fk <> t2.RES_NUMBER_fk) AND t1.TICKET_NR = t2.TICKET_NR AND t1.TICKET_NR <> 0);
    WHILE nr > 1 DO
    UPDATE Ticket_number as table_ticket, (SELECT RES_NUMBER_fk, PASS_NUMBER_fk, rand()*999999 as generated_ticketnr FROM Ticket_number Where (RES_NUMBER_fk = new.R_NUMBER)) as ticket_numbers
    SET table_ticket.TICKET_NR = ticket_numbers.generated_ticketnr + 1
    WHERE (table_ticket.RES_NUMBER_fk = ticket_numbers.RES_NUMBER_fk AND table_ticket.PASS_NUMBER_fk = ticket_numbers.PASS_NUMBER_fk);
    SELECT COUNT(*) INTO nr FROM Ticket_number as t1, Ticket_number as t2 Where ((t1.PASS_NUMBER_fk <> t2.PASS_NUMBER_fk OR t1.RES_NUMBER_fk <> t2.RES_NUMBER_fk) AND t1.TICKET_NR = t2.TICKET_NR AND t1.TICKET_NR <> 0);
    END WHILE;
END;
//
delimiter ;


delimiter //
CREATE PROCEDURE addReservation(IN AIRPORT_CODE_DEPARTURE varchar(3), IN AIRPORT_CODE_ARRIVAL varchar(3)
, IN YEAR integer, IN WEEK integer, IN DAY varchar(10), IN DEPARTURE_TIME time, IN nr_of_passenger integer, OUT output_reservation_nr integer)
BEGIN
    DECLARE which_route integer;
    DECLARE which_schedule integer;
    DECLARE which_flight integer;

    SELECT ROUTE_ID INTO which_route FROM Route WHERE (Route.DEPARTURE_CITY = AIRPORT_CODE_DEPARTURE AND Route.ARRIVAL_CITY = AIRPORT_CODE_ARRIVAL AND Route.YEAR = YEAR);
    SELECT SCHEDULE_ID INTO which_schedule FROM Weekly_schedule WHERE (Weekly_schedule.R_id = which_route AND Weekly_schedule.YEAR = YEAR AND Weekly_schedule.DAY = DAY AND Weekly_schedule.DEPARTURE_TIME = DEPARTURE_TIME);
    SELECT FLIGHT_NUMBER INTO which_flight FROM Flight WHERE (Flight.FLIGHT_SCHEDULE = which_schedule AND Flight.WEEK = WEEK);
    IF which_flight is not null AND nr_of_passenger < calculateFreeSeats(which_flight)
    THEN
    INSERT INTO Booking(FLIGHT_NR_fk)
    VALUES (which_flight);
    SELECT MAX(RESERVATION_NUMBER) INTO output_reservation_nr from Booking;
    ELSE
    SELECT "Incorrect flightdetails or no seats left" as "Message";
    SET output_reservation_nr = 0;
    END IF;
END;
//
delimiter ;


delimiter //
CREATE PROCEDURE addPassenger(IN RESERVATION_NUMBER integer, 
IN PASSPORT_NUMBER integer, IN NAME varchar(30))
BEGIN
IF RESERVATION_NUMBER IN (SELECT RESERVATION_NUMBER FROM Booking WHERE (Booking.RESERVATION_NUMBER = RESERVATION_NUMBER AND Booking.AMOUNT_PAYED is NULL))
THEN
IF not PASSPORT_NUMBER IN (SELECT PASSPORT_NUMBER FROM Passenger WHERE (Passenger.PASSPORT_NUMBER = PASSPORT_NUMBER AND Passenger.NAME = NAME))
THEN
INSERT INTO Passenger(NAME, PASSPORT_NUMBER)
VALUES (NAME, PASSPORT_NUMBER);
END IF;
INSERT INTO Ticket_number(PASS_NUMBER_fk, RES_NUMBER_fk, TICKET_NR)
VALUES (PASSPORT_NUMBER, RESERVATION_NUMBER, 0);
ELSE
SELECT "Not a valid reservation number or Booking final" as "Message";
END IF;
end;
//
delimiter ;


delimiter //
CREATE PROCEDURE addContact(IN RESERVATION_NUMBER integer, IN PASSPORT_NUMBER integer
, IN CONTACT_EMAIL varchar(30), IN CONTACT_PHONE BIGINT)
BEGIN
IF RESERVATION_NUMBER IN (SELECT RESERVATION_NUMBER FROM Booking WHERE (Booking.RESERVATION_NUMBER = RESERVATION_NUMBER))
THEN
IF not PASSPORT_NUMBER IN (SELECT PASS_NUMBER_fk FROM Ticket_number WHERE (Ticket_number.PASS_NUMBER_fk = PASSPORT_NUMBER AND Ticket_number.RES_NUMBER_fk = RESERVATION_NUMBER))
THEN
SELECT "The person is not a passenger of the reservation" as "Message";
END IF;
UPDATE Booking
SET Booking.CONTACT_EMAIL = CONTACT_EMAIL, Booking.CONTACT_PHONE = CONTACT_PHONE
WHERE (RESERVATION_NUMBER IN (SELECT RES_NUMBER_fk FROM Ticket_number WHERE (Ticket_number.PASS_NUMBER_fk = PASSPORT_NUMBER)) AND Booking.RESERVATION_NUMBER = RESERVATION_NUMBER);
ELSE
SELECT "The given reservation number does not exist" as "Message";
END IF;

end;
//
delimiter ;



delimiter //
CREATE PROCEDURE addPayment(IN RES_NUMBER integer, IN CREDIT_CARD_HOLDER varchar(50)
, IN CREDIT_CARD_NUMBER BIGINT)
BEGIN
DECLARE passengers_on_booking integer;
DECLARE flightnumber integer;

SELECT COUNT(*) INTO passengers_on_booking from Ticket_number WHERE (Ticket_number.RES_NUMBER_fk = RES_NUMBER);
SELECT FLIGHT_NR_fk INTO flightnumber FROM Booking WHERE (Booking.RESERVATION_NUMBER = RES_NUMBER);
IF (flightnumber is not null AND calculateFreeSeats(flightnumber) >= passengers_on_booking AND (RES_NUMBER IN (SELECT RESERVATION_NUMBER FROM Booking WHERE (Booking.RESERVATION_NUMBER = RES_NUMBER AND Booking.CONTACT_PHONE is not NULL))))
THEN
INSERT INTO Payment(CREDIT_CARD_NUMBER, CREDIT_CARD_HOLDER, R_NUMBER)
VALUES (CREDIT_CARD_NUMBER, CREDIT_CARD_HOLDER, RES_NUMBER);
UPDATE Booking
SET Booking.AMOUNT_PAYED = calculatePrice(flightnumber) * passengers_on_booking
WHERE (Booking.RESERVATION_NUMBER = RES_NUMBER);
ELSE
SELECT "There is no free seats, no Contact to this reservation or wrong reservation number" as "Message";
END IF;

end;
//
delimiter ;

CREATE VIEW allFlights AS 
SELECT (SELECT AIRPORT_NAME FROM Airport WHERE(Airport.AIRPORT_CODE = Route.DEPARTURE_CITY)) as departure_city_name, (SELECT AIRPORT_NAME FROM Airport WHERE(Airport.AIRPORT_CODE = Route.ARRIVAL_CITY)) as destination_city_name, DEPARTURE_TIME as departure_time, 
DAY as departure_day, WEEK as departure_week, Weekly_schedule.YEAR as departure_year, 
calculateFreeSeats(FLIGHT_NUMBER) as nr_of_free_seats, calculatePrice(FLIGHT_NUMBER) as current_price_per_seat
FROM Route, Weekly_schedule, Flight, Airport 
WHERE(Route.ROUTE_ID = Weekly_schedule.R_id AND Flight.FLIGHT_SCHEDULE = Weekly_schedule.SCHEDULE_ID AND Route.DEPARTURE_CITY = Airport.AIRPORT_CODE);
