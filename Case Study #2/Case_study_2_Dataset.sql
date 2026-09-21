create table runners (
runner_id varchar(1),
registration_date date)
;
insert into runners
values 
('1','2021-01-01'),
('2','2021-01-03'),
('3','2021-01-08'),
('4','2021-01-15')
;
create table customer_orders 
(order_id varchar(10),
customer_id varchar(5),
pizza_id varchar(1),
exclusion varchar (10),
extras varchar(10),
order_time timestamp )
;

insert into customer_orders
(order_id,customer_id,pizza_id,exclusion,extras,order_time)
values
('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');
;
create table runner_orders
(order_id varchar(2),
runner_id varchar(2),
pickup_time timestamp,
distance varchar(10),
duration varchar(20),
cancelation varchar(30))
;
insert into runner_orders
(order_id,runner_id,pickup_time,distance,duration,cancelation)
values
('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', null, null, null, 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', null, null, null, 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');

create table pizza_names(
pizza_id integer
,
pizza_name varchar(20)
)
;

insert into pizza_names
(pizza_id,pizza_name)
values 
(1,'meatlovers'),
(2,'vegetarian')

;

create table pizza_toppings
(
topping_id integer,
topping_name varchar(20)
)

;

insert into pizza_toppings
(topping_id,topping_name)
values 
 (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');

update runner_orders ro 
set distance = trim(REGEXP_SUBSTR(distance,'[0-9.]+'))
where ro.distance is not null;

alter table runner_orders 
modify column distance float;
select distance from runner_orders
;
select exclusion,extras from customer_orders;
update customer_orders 
set extras = ''
where extras is null
;
create table pizza_ingriedients
(pizza_id varchar(1),
toppings varchar(15));
alter table pizza_ingriedients
modify column toppings varchar(30)
;

insert into pizza_ingriedients 
(pizza_id,toppings)
values 
('1', '1, 2, 3, 4, 5, 6, 8, 10'),
  ('2', '4, 6, 7, 9, 11, 12');

create table ratings (
order_id varchar(20) ,
rating integer)
;
insert into ratings 
(order_id,rating)
values 
(1,floor(rand()*(5-1)+1)),
(2,floor(rand()*(5-1)+1)),
(3,floor(rand()*(5-1)+1)),
(4,floor(rand()*(5-1)+1)),
(5,floor(rand()*(5-1)+1)),
(6,floor(rand()*(5-1)+1)),
(7,floor(rand()*(5-1)+1)),
(8,floor(rand()*(5-1)+1)),
(9,floor(rand()*(5-1)+1)),
(10,floor(rand()*(5-1)+1))
;
drop table ratings 
