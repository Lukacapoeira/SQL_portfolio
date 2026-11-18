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
customer_id#1 How many customers has Foodie-Fi ever had?
select 
count(distinct(s.customer_id)) as unique_customers
from subscriptions s 


unique_customers|
----------------+
            1001|
;

#6 What is the number and percentage of customer plans after their initial free trial?


with a1 as (select 
s.customer_id 
,p.plan_name 
,s.start_date 
,lead(p.plan_name ) over (partition by s.customer_id order by s.start_date asc) as next_plan
from subscriptions s 
left join plans p on s.plan_id = p.plan_id )
,
a2 as (
select
count(plan_name) as total_subscripton
from a1
where plan_name = "trial")
,
a3 as (select 
next_plan
,count(next_plan) as plans_count
from a1
where plan_name = 'trial'
group by 1)
select
next_plan 
,plans_count
,(plans_count/total_subscripton) *100 as percentage
from a3
join a2 on true

next_plan    |plans_count|percentage|
-------------+-----------+----------+
basic monthly|        546|   54.6000|
pro annual   |         37|    3.7000|
pro monthly  |        325|   32.5000|
churn        |         92|    9.2000|


;
#7 What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
with a1 as (select 
s.customer_id 
,p.plan_name 
,s.start_date 
,row_number() over (partition by customer_id order by start_date desc) as newest_plan
from subscriptions s
join plans p on s.plan_id = p.plan_id 
where start_date <= '2020-12-31' and p.plan_name <> "churn")
,
a2 as (select
customer_id 
,plan_name 
,newest_plan 
from a1
where newest_plan = 1)
,
a3 as(select
count(plan_name) as total_count
from a2)
select 
plan_name 
,count(plan_name) as plan_total
,(count(plan_name)/max(total_count)) * 100 as percentage
from a2
join a3
group by 1

plan_name    |plan_total|percentage|
-------------+----------+----------+
basic monthly|       287|   28.6713|
pro annual   |       196|   19.5804|
pro monthly  |       409|   40.8591|
trial        |       109|   10.8891|

;

#8 How many customers have upgraded to an annual plan in 2020?
select 
count(*) as upgraded_to_annual
from (select 
customer_id
,start_date
,plan_name
,lead(plan_name) over (partition by customer_id order by start_date asc) as next_plan
from subscriptions s 
join plans p on s.plan_id = p.plan_id 
where year(start_date) = 2020) as customer_list
where next_plan like '%annual%'

upgraded_to_annual|
------------------+
               195|
;


#9 How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

with a1 as (select 
s.customer_id 
,s.start_date 
,p.plan_name 
,min(s.start_date) over (partition by customer_id) as joined_date
,case when plan_name = 'pro annual'
then start_date else ""
end as become_pro_date
from subscriptions s 
join plans p on s.plan_id = p.plan_id )
,
a2 as (select 
joined_date 
,become_pro_date 
,DATEDIFF(become_pro_date,joined_date) as days_needed
from a1
where become_pro_date <> "")
select 
avg(days_needed) as average_days_needed
from a2

average_days_needed|
-------------------+
           104.2162|
           
           
 ;
 
 #9 Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
 with a1 as (select 
s.customer_id 
,s.start_date 
,p.plan_name 
,min(s.start_date) over (partition by customer_id) as joined_date
,case when plan_name = 'pro annual'
then start_date else ""
end as become_pro_date
from subscriptions s 
join plans p on s.plan_id = p.plan_id )
,
a2 as (select 
joined_date 
,become_pro_date 
,DATEDIFF(become_pro_date,joined_date) as days_needed
from a1
where become_pro_date <> "")
,
a3 as (select 
days_needed 
,concat(floor(days_needed/30)*30+1,'-',floor(days_needed/30)*30+30) as bins
from a2)
select 
bins
,count(bins) as time_need
from a3
group by 1


bins   |time_need|
-------+---------+
1-30   |       49|
121-150|       43|
61-90  |       33|
31-60  |       25|
151-180|       35|
91-120 |       35|
181-210|       27|
331-360|        1|
241-270|        5|
211-240|        4|
271-300|        1|
301-330|        1|

;
#11 How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
with a1 as (select
s.customer_id 
,p.plan_name 
,s.start_date 
,lag(plan_name) over (partition by customer_id order by start_date desc) as next_plan
from subscriptions s 
join plans p on s.plan_id = p.plan_id
where year(s.start_date) = 2020 )
select 
count(*) as downgrade_count
from a1
where plan_name = "pro monthly" and next_plan = "basic monthly"

downgrade_count|
---------------+
              0|
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
