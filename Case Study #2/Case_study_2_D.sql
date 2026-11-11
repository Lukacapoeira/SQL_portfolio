#1 If a Meat Lovers pizza costs $12 and Vegetarian costs $10
# and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

with pizza_cost as (select 
pn.pizza_name 
,case when pn.pizza_name = "meatlovers" then 12
else 10 end as cost
from customer_orders co 
join runner_orders ro on co.order_id = ro.order_id 
join pizza_names pn on co.pizza_id = pn.pizza_id 
where ro.duration is not null)
select 
pizza_name
,sum(cost) as profit
from pizza_cost
group by 1


pizza_name|profit|
----------+------+
meatlovers|   108|
vegetarian|    30|

;


#2 What if there was an additional $1 charge for any pizza extras?
#Add cheese is $1 extra

with pizza_cost as (select 
pn.pizza_name 
,row_number() over (order by pizza_name) as unique_key
,extras
,case when pn.pizza_name = "meatlovers" then 12
else 10 end as cost
from customer_orders co 
join runner_orders ro on co.order_id = ro.order_id 
join pizza_names pn on co.pizza_id = pn.pizza_id 
where ro.duration is not null)
,
extras_cost_table as (select 
unique_key
,extra_table.extra
from pizza_cost
join json_table(concat('[',extras,']'),'$[*]'
columns(extra int path '$') 
)as extra_table )
,
count_of_extras as (select
unique_key
,count(extra) as extras_count
from extras_cost_table
group by 1)
,
final_cost_table as (select 
pizza_name 
,pizza_cost.unique_key 
,cost
,extras_count
,case when extras_count is null
then cost 
else extras_count + cost end as final_pizza_cost
from pizza_cost
left join count_of_extras on pizza_cost.unique_key = count_of_extras.unique_key )
select 
pizza_name
,sum(final_pizza_cost) as total_profit
from final_cost_table 
group by 1

pizza_name|total_profit|
----------+------------+
meatlovers|         111|
vegetarian|          31|
;

# 3 The Pizza Runner team now wants to add an additional ratings system that allows customers
#to rate their runner, how would you design an additional table for this new dataset - 
#generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

create table ratings 
(order_id int,
rate int )
;

insert into ratings
(order_id,rate)
values 
('1',floor(RAND() * (10-5))+1),
('2',floor(RAND() * (10-5))+1),
('3',floor(RAND() * (10-5))+1),
('4',floor(RAND() * (10-5))+1),
('5',floor(RAND() * (10-5))+1),
('6',floor(RAND() * (10-5))+1),
('7',floor(RAND() * (10-5))+1),
('8',floor(RAND() * (10-5))+1),
('9',floor(RAND() * (10-5))+1),
('10',floor(RAND() * (10-5))+1)

order_id|rate|
--------+----+
       1|   1|
       2|   3|
       3|   3|
       4|   1|
       5|   1|
       6|   4|
       7|   2|
       8|   2|
       9|   1|
      10|   1|
;
#4 Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
#customer_id | order_id | runner_id | rating | order_time | pickup_time | Time between order and pickup
#Delivery duration | Average speed | Total number of pizzas
select 
co.customer_id 
,co.order_id 
,ro.runner_id 
,r.rate 
,co.order_time 
,ro.pickup_time 
,TIMEDIFF(ro.pickup_time,co.order_time) as time_between
,REGEXP_SUBSTR(ro.duration,'[0-9]+') as duration_in_minutes
,round((ro.distance/REGEXP_SUBSTR(ro.duration,'[0-9]+')) * 60) as average_speed
,count(co.pizza_id)
from customer_orders co
join runner_orders ro on co.order_id = ro.order_id 
join ratings r on co.order_id = r.order_id 
where ro.pickup_time is not null
group by 1,2,3,4,5,6,7,8,9


customer_id|order_id|runner_id|rate|order_time         |pickup_time        |time_between|duration_in_minutes|average_speed|count(co.pizza_id)|
-----------+--------+---------+----+-------------------+-------------------+------------+-------------------+-------------+------------------+
101        |1       |1        |   1|2020-01-01 18:05:02|2020-01-01 18:15:34|    00:10:32|32                 |         38.0|                 1|
101        |2       |1        |   3|2020-01-01 19:00:52|2020-01-01 19:10:54|    00:10:02|27                 |         44.0|                 1|
102        |3       |1        |   3|2020-01-02 23:51:23|2020-01-03 00:12:37|    00:21:14|20                 |         40.0|                 2|
103        |4       |2        |   1|2020-01-04 13:23:46|2020-01-04 13:53:03|    00:29:17|40                 |         35.0|                 3|
104        |5       |3        |   1|2020-01-08 21:00:29|2020-01-08 21:10:57|    00:10:28|15                 |         40.0|                 1|
105        |7       |2        |   2|2020-01-08 21:20:29|2020-01-08 21:30:45|    00:10:16|25                 |         60.0|                 1|
102        |8       |2        |   2|2020-01-09 23:54:33|2020-01-10 00:15:02|    00:20:29|15                 |         94.0|                 1|
104        |10      |1        |   1|2020-01-11 18:34:49|2020-01-11 18:50:20|    00:15:31|10                 |         60.0|                 2|

;

#5 If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid 
# $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
with sales_table as (select 
pn.pizza_name 
,case when pn.pizza_name = "meatlovers" 
then 12 else 10 end as cost
,round((ro.distance * 0.3),2) as runner_cost
from customer_orders co 
join pizza_names pn on co.pizza_id = pn.pizza_id
join runner_orders ro on co.order_id = ro.order_id 
where ro.pickup_time is not null)
select 
pizza_name
,sum(cost-runner_cost) as profit
from sales_table
group by 1


pizza_name|profit|
----------+------+
meatlovers| 61.92|
vegetarian| 11.46|
;
select * from pizza_names