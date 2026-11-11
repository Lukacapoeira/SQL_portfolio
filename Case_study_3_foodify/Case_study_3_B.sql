#1 How many customers has Foodie-Fi ever had?
select 
count(distinct(s.customer_id)) as unique_customers
from subscriptions s 


unique_customers|
----------------+
            1001|
;
#2 What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
select 
month(s.start_date) as month
,count(month(s.start_date)) as count_of_trial
from subscriptions s 
left join plans p on p.plan_id = s.plan_id 
where p.plan_name = "trial"
group by 1
order by 1 asc


month|count_of_trial|
-----+--------------+
    1|            88|
    2|            68|
    3|            94|
    4|            81|
    5|            88|
    6|            79|
    7|            89|
    8|            88|
    9|            87|
   10|            79|
   11|            75|
   12|            84|
;
#3 What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name

select 
s.plan_id 
,count(s.plan_id) as count_of_plans
from subscriptions s 
where YEAR(s.start_date ) > 2020
group by 1
order by 1 asc


plan_id|count_of_plans|
-------+--------------+
      1|             8|
      2|            60|
      3|            63|
      4|            71|
;

#4 What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
with a1 as (select 
s.customer_id 
,p.plan_name 
from subscriptions s 
left join plans p on s.plan_id = p.plan_id )
,
a2 as (select
count(distinct(customer_id)) as unique_customer
from a1)
select 
unique_customer
,round(((count(plan_name)/unique_customer)*100),1) as churn_percentage
from a1
join a2
where plan_name = "churn"
group by 1


unique_customer|churn_percentage|
---------------+----------------+
           1001|            30.7|
           
           ;
#5 How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
with a1 as (select 
s.customer_id 
,p.plan_name 
,lag(p.plan_name) over (partition by s.customer_id order by s.start_date) as before_plan
from subscriptions s 
left join plans p on s.plan_id = p.plan_id)
,
a2 as (select 
customer_id
,plan_name
,before_plan
,case when plan_name = "churn" and before_plan = "trial"
then 1 else 0 end as churn_after_trial
from a1)
select
sum(churn_after_trial) as churn_after_trial_sum
,round((sum(churn_after_trial)/count(distinct(customer_id))*100),0) as percent_churn_after_trial
from a2

churn_after_trial_sum|percent_churn_after_trial|
---------------------+-------------------------+
                   92|                        9|
