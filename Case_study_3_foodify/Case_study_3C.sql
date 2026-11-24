#Challenge monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
#upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
#upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
#once a customer churns they will no longer make payments

#165
;
with recursive a1 as (select 
s.customer_id 
,s.start_date 
,p.plan_name 
,p.price
,lead(s.start_date) over (partition by s.customer_id order by s.start_date asc) as upgrade_date
from subscriptions s 
left join plans p on s.plan_id = p.plan_id 
where p.plan_name <> "churn")
,
	historia_platnosci as (
	select
	customer_id
	,start_date
	,plan_name
	,price
	,upgrade_date
	from a1
	union all
	select 
	customer_id 
	,DATE_ADD(start_date,interval 1 MONTH) as start_date
	,plan_name 
	,price
	,upgrade_date
	from historia_platnosci
	where DATE_ADD(start_date,interval 1 MONTH) < upgrade_date )
	,
		a3 as (
		select
		customer_id 
		,start_date 
		,plan_name
		,price
		,upgrade_date
		,lag(price) over (partition by customer_id order by start_date asc) as last_cost
		from historia_platnosci)
		,
			a4 as(
			select
			customer_id
			,start_date
			,plan_name
			,price
			,lag(start_date) over (partition by customer_id order by start_date asc) as last_payment
			,last_cost
			,case when (last_cost-price) < 0
			then 1 else 0 end as need_discharg
			from a3)
			,
				a5 as (
				select
				customer_id
				,start_date
				,plan_name
				,price
				,last_payment
				,last_cost
				,need_discharg
				,DATEDIFF(start_date,last_payment) as time_to_upgrade
				from a4
				)
				,
					a6 as (
					select 
					customer_id
					,start_date
					,plan_name
					,price
					,last_payment
					,last_cost
					,need_discharg
					,time_to_upgrade
					,case when need_discharg = 1 
					then round(price - (last_cost * ((30-time_to_upgrade)/30)),1) end as amount_charged
					from a5
					)
						select 
						customer_id
						,start_date
						,plan_name
						,case when amount_charged < price
						then round(amount_charged,1) 
						else round(price,1) end as final_cost
						from a6