#1 How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
select 
week_num
,count(runner_id) as count_of_runner
	from
	(select 
	*
	,round(DATEDIFF(r.registration_date,'2021-01-01')/7) + 1 as week_num
	from runners r
	) as registration
group by 1

			
			week_num|count_of_runner|
			--------+---------------+
			       1|              2|
			       2|              1|
			       3|              1|
;
#2 What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
select 
ro.runner_id 
,avg(minute(TIMEDIFF(ro.pickup_time,co.order_time))) as average_time
from customer_orders co 
join runner_orders ro on co.order_id = ro.order_id
where ro.pickup_time is not null 
group by 1

			
			runner_id|average_time|
			---------+------------+
			1        |     15.3333|
			2        |     23.4000|
			3        |     10.0000|
;

#3 Is there any relationship between the number of pizzas and how long the order takes to prepare?
with a1 as(select 
co.order_id 
,count(co.order_id) as number_of_pizza
,TIMEDIFF(ro.pickup_time,co.order_time) as time_need
from customer_orders co 
left join runner_orders ro on co.order_id = ro.order_id 
where ro.pickup_time  is not null
group by 1,3)
select 
number_of_pizza 
,avg(minute(time_need)) as average_time_need
from a1
group by 1


			number_of_pizza|average_time_need|
			---------------+-----------------+
			              1|          12.0000|
			              2|          18.0000|
			              3|          29.0000|
;
#4 What was the average distance travelled for each customer?
select
runner_id
,round(avg(distance),2) as avg_distance
from runner_orders ro 
where ro.distance is not null
group by 1

			
			runner_id|avg_distance|
			---------+------------+
			1        |       15.85|
			2        |       23.93|
			3        |        10.0|
;
#5 What was the difference between the longest and shortest delivery times for all orders?
select
timediff(max(TIMEDIFF(ro.pickup_time ,co.order_time)),min(TIMEDIFF(ro.pickup_time ,co.order_time))) as time_dierence_Longest_VS_Shortest
from customer_orders co 
left join runner_orders ro on co.order_id = ro.order_id 
where ro.pickup_time is not null

			
			time_dierence_Longest_VS_Shortest|
			---------------------------------+
			                         00:19:15|
;
#6 What was the average speed for each runner for each delivery and do you notice any trend for these values?
with a1 as (select
ro.runner_id 
,ro.distance 
,REGEXP_substr(ro.duration  ,'([0-9]+)') as time_in_minutes
from runner_orders ro 
where ro.duration is not null)
select 
*
,round(distance/time_in_minutes *60,2) as average_speed_per_100_km
from a1

			
			runner_id|distance|time_in_minutes|average_speed_per_100_km|
			---------+--------+---------------+------------------------+
			1        |    20.0|32             |                    37.5|
			1        |    20.0|27             |                   44.44|
			1        |    13.4|20             |                    40.2|
			2        |    23.4|40             |                    35.1|
			3        |    10.0|15             |                    40.0|
			2        |    25.0|25             |                    60.0|
			2        |    23.4|15             |                    93.6|
			1        |    10.0|10             |                    60.0|
;
#7 What is the successful delivery percentage for each runner?
with a1 as (select 
ro.runner_id 
,case when duration is not null then 1 else 0 end as succes
from runner_orders ro )
select 
runner_id
,SUM(succes)/COUNT(succes) as succes_rate
from a1
group by 1


runner_id|succes_rate|
---------+-----------+
1        |     1.0000|
2        |     0.7500|
3        |     0.5000|