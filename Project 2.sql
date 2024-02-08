-- Task 1 -- Create an ER diagram for the given aircargo database.


create database aircargo;
use aircargo;

select * from customer;
select * from pof;
select * from routes;
select * from ticket_details;

Describe customer;
Describe pof;
Describe routes;
Describe ticket_details;

-- Task 2 -- Write a query to create route_details table using suitable data types for the fields, such as route_id, flight_num, origin_airport, destination_airport, aircraft_id, and distance_miles. Implement the check constraint for the flight number and unique constraint for the route_id fields. Also, make sure that the distance miles field is greater than 0.

create table route_details
( route_id int,
flight_num int,
origin_airport varchar(10),
destination_airport varchar(10),
aircraft_id varchar(10),
distance int,
check (flight_num is not null),
unique (route_id),
check (distance>0)
);

Describe route_details;
  
-- Task 3 -- Write a query to display all the passengers (customers) who have travelled in routes 01 to 25. Take data  from the passengers_on_flights table.

select * from pof
              where route_id between 1 and 25
					order by customer_id;
                    
-- Task 4 -- Write a query to identify the number of passengers and total revenue in business class from the ticket_details table.

select Class_id, count(class_id = 'Bussiness') as Bussiness_Class_Passengers, 
sum(no_of_tickets*price_per_ticket) as Total_revenue from ticket_details 
where Class_id = 'Bussiness'
group by class_id
order by Total_revenue;

-- Task 5 -- Write a query to display the full name of the customer by extracting the first name and last name from the customer table.

select concat(first_name, ' ', last_name) as Full_Name 
       from customer
            order by Full_name;

-- Task 6 -- Write a query to extract the customers who have registered and booked a ticket. Use data from the customer and ticket_details tables.

select c.customer_id , concat(c.first_name, ' ' , c.last_name) as Full_Name, 
count(t.no_of_tickets) as Total_Tickets_booked
from customer c join ticket_details t using (customer_id)
group by c.customer_id, Full_Name
order by Total_tickets_booked desc;

-- Task 7 -- Write a query to identify the customer’s first name and last name based on their customer ID and brand (Emirates) from the ticket_details table.

select c.customer_id, c.first_name, c.last_name
from customer c
join ticket_details t using (customer_id)
where brand = 'Emirates' 
order by c.customer_id;

-- Task 8 -- Write a query to identify the customers who have travelled by Economy Plus class using Group By and Having clause on the passengers_on_flights table.
                     
select c.first_name, c.last_name,p.customer_id, p.class_id 
from pof p left join customer c on p.customer_id = c.customer_id
group by 1,2,3,4
having class_id= 'Economy Plus';
			

-- Task 9 -- Write a query to identify whether the revenue has crossed 10000 using the IF clause on the ticket_details table.

select sum(no_of_tickets*price_per_ticket) as Total_revenue, 
if(sum(no_of_tickets*price_per_ticket)>10000, 'Yes. Revenue Crossed 10000', 'Revenue less than 10000') as Revenue_Status
from ticket_details;

-- Task 10 -- Write a query to create and grant access to a new user to perform operations on a database.

CREATE VIEW bussinessclass_brand AS SELECT t.customer_id, t.class_id,t.brand, c.first_name, c.last_name
FROM ticket_details AS t LEFT JOIN customer AS c ON t.customer_id = c.customer_id
WHERE t.class_id =‘Bussiness’;

SELECT * FROM aircargo.businessclass_brand;

-- Task 11 -- Write a query to find the maximum ticket price for each class using window functions on the ticket_details table.

with cte as (
select class_id, max(price_per_ticket) as Maximum_price, 
dense_rank () over (partition by class_id) as dense
from ticket_details
group by class_id order by Maximum_price desc)
select class_id, Maximum_price from cte where dense = 1;

-- Task 12 -- Write a query to extract the passengers whose route ID is 4 by improving the speed and performance of the passengers_on_flights table.

select * from aircargo.routes
	where route_id = 4;

## Before the index query the cost and performance are found to be at 0.1 sec

create index route_id on routes(route_id);

-- Checking indexes --
show indexes from routes;

-- Fetching details using index -- 
select * from routes where route_id = 4;

## After creating an index query the cost and performance are same as 0.1 sec


-- Task 13 --  For the route ID 4, write a query to view the execution plan of the passengers_on_flights table.

select aircraft_id, depart, arrival, travel_date, flight_num 
from aircargo.pof where route_id = 4;

-- Task 14 -- Write a query to calculate the total price of all tickets booked by a customer across different aircraft IDs using rollup function.

select if (grouping (aircraft_id), 'Total',aircraft_id) as Aircraft, sum(no_of_tickets) as Total_tickets,
sum(no_of_tickets*price_per_ticket) as Total_Revenue
from ticket_details
group by aircraft_id with rollup
order by 3;

-- Task 15 -- Write a query to create a view with only business class customers along with the brand of airlines.

create view  business_class as select c.first_name, c.last_name, t.brand
from customer c
join ticket_details t using (customer_id)
where class_id in ('Bussiness');

select * from business_class;

-- Task 16 -- Write a query to create a stored procedure to get the details of all passengers flying between a range of routes defined in run time. Also, return an error message if the table doesn't exist.

DELIMITER $$
CREATE PROCEDURE Flight_route_range3 (IN flight_route_id1 INT, IN flight_route_id2 INT)
BEGIN
DECLARE pof INT;
DECLARE customer INT;
SELECT COUNT(*) INTO passengers_table_exists
FROM information_schema.tables
WHERE table_schema = DATABASE() AND table_name = ‘pof’;
SELECT COUNT(*) INTO customer
FROM information_schema.tables
WHERE table_schema = DATABASE() AND table_name = customer
— If either of the tables does not exist, return an error message
IF passengers_table_exists = 0 OR customer_table_exists = 0 THEN
SELECT ‘Error: One or more required tables do not exist. ‘ AS Message;
ELSE
— Check the number of rows that would be returned by the query
SET @num_rows = (
SELECT COUNT(*)
FROM passengers_on_flights AS p
WHERE p.route_id BETWEEN flight_route_id1 AND flight_route_id2
);
— If no rows are returned, raise an error message
IF @num_rows = 0 THEN
SELECT ‘Error: No data found for the specified flight route range. Table Doesnt Exist’ AS Message;
ELSE
— Fetch the passenger and customer details between the specified routes
SELECT p.route_id,
p.depart,
p.arrival,
p.seat_num,
c.* FROM passengers_on_flights AS p 
INNER JOIN customer AS c ON p.customer_id = c.customer_id 
WHERE p.route_id BETWEEN flight_route_id1 AND flight_route_id2
ORDER BY p.route_id;
END IF;
END IF;
END $$

DELIMITER;

CALL Flight_route_range3(1,50);


-- Task 17 -- Write a query to create a stored procedure that extracts all the details from the routes table where the travelled distance is more than 2000 miles.

drop procedure if exists distance;
delimiter //
create procedure distance ( in miles int)
begin
select * from routes
where distance_miles >miles
order by distance_miles;
end//
delimiter ;

call distance (2000);

-- Task 18-- Write a query to create a stored procedure that groups the distance travelled by each flight into three categories. The categories are, short distance travel (SDT) for >=0 AND <= 2000 miles, intermediate distance travel (IDT) for >2000 AND <=6500, and long-distance travel (LDT) for >6500.

call distance_information();

-- Task 19 -- Write a query to extract ticket purchase date, customer ID, class ID and specify if the complimentary services are provided for the specific class using a stored function in stored procedure on the ticket_details table. •	If the class is Business and Economy Plus, then complimentary services are given as Yes, else it is No

call complimentary_services(1);


-- Task 20 -- Write a query to extract the first record of the customer whose last name ends with Scott using a cursor from the customer table.

delimiter $$

Create Procedure firstrecord()
begin
declare a varchar(20);
declare b varchar(20);
declare c int;
declare cursor_1 cursor for select first_name, last_name, customer_id from customer where last_name = "scott";
open cursor_1;
fetch cursor_1 into a, b, c;
select a as First_name,b as last_name, c as customer_id;
close cursor_1;
end $$

call firstrecord();



























