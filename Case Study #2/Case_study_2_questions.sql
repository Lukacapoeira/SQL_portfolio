#1 How many pizzas were ordered?
select 
count(co.pizza_id) as pizza_ordered
from customer_orders co 
;
#2 How many unique customer orders were made?
select
count(distinct(co.order_id)) as count_of_unique_orders
from customer_orders co 
;
#3 How many successful orders were delivered by each runner?
select 
ro.runner_id 
,count(ro.order_id) as count_of_succesful_delivery
from runner_orders ro 
where ro.cancelation = ''
group by 1
order by 2 desc
;
#4 How many of each type of pizza was delivered?
select
pn.pizza_name 
,count(co.pizza_id) as count_of_pizza	
from customer_orders co 
join runner_orders ro on co.order_id = ro.order_id 
join pizza_names pn on co.pizza_id = pn.pizza_id 
where ro.cancelation = ''
group by 1
order by 2 desc
;
#5 How many Vegetarian and Meatlovers were ordered by each customer
select 
co.customer_id 
,pn.pizza_name 
,count(pn.pizza_name) as count_of_pizza_type
from customer_orders co 
join pizza_names pn on co.pizza_id = pn.pizza_id 
group by 1,2
order by 1,3 desc
;
#6 What was the maximum number of pizzas delivered in a single order?
select max(pizza_in_order) as max_pizza_in_delivery
from 
	(select 
	co.order_id 
	,count(co.pizza_id) as pizza_in_order
	from customer_orders co 
	join runner_orders ro on co.order_id = ro.order_id 
	where ro.cancelation =''
	group by 1 
	order by 2 desc) count_of_order
;
#7 For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
with a1 as (select 
co.customer_id 
,case when co.exclusion = '' and co.extras = '' then 'Changed'
else 'Basic' end as changed
from customer_orders co 
join runner_orders ro on co.order_id = ro.order_id 
where ro.cancelation = '')
	select 
	customer_id
	,changed
	,count(changed) as count_of_changes
	from a1
	group by 1,2
	order by 1,3 desc
;
#8 How many pizzas were delivered that had both exclusions and extras
with a1 as (select 
case when co.exclusion !='' and co.extras !=''
then 'double_change'
else 'basic'
end as changed
from customer_orders co 
left join runner_orders ro on co.order_id = ro.order_id 
where ro.cancelation ='')
select 
count(*) as total_count_of_fouble_change
from a1 
where changed = 'double_change'