/* STEP 1: Data Extraction (a1)
   - Joining Orders, Positions, and Products tables.
   - Filtering for the year 2020 and excluding returned items.
*/
with a1 as (select 
o.order_date
,o.customer_id 
,o.order_id 
,op.item_quantity 
,op.position_discount 
,p.product_price 
from orders o
left join order_positions op on o.order_id = op.order_id 
left join products p on op.product_id = p.product_id
where not exists(
select * from order_returns or2
where o.order_id = or2.order_id)
and year(o.order_date)=2020)
,
	/* STEP 2: Identifying First Order & Calculating Net Value (a2)
	   - Using Window Function MIN() to find the first time a customer bought an item.
	   - Calculating Net GMV for the current transaction line.
	*/
	a2 as (select 
	order_date
	,customer_id
	,min(order_date)over(partition by customer_id) as first_order
	,case when position_discount > 0
	then (1-coalesce(position_discount,0))*item_quantity*product_price
	else item_quantity*product_price
	end as gmv_net
	from a1)
	,
		/* STEP 3: Flagging Customer Type (a3)
		   - Comparing current order date with the customer's first order date.
		   - If they match, the customer is 'New' in this transaction. Otherwise, 'Returning'.
		*/
		a3 as (select 
		order_date 
		,customer_id
		,first_order 
		,gmv_net
		,case when order_date = first_order
		then "New"
		else "Returning"
		end as "Client_type"
		from  a2)
			/* STEP 4: Final Aggregation
			   - Summing the GMV grouped by the exact month and the customer type flag.
			   - Sorting chronologically to show the revenue evolution.
			*/
			select 
			client_type
			,month(order_date) as month
			,round(sum(gmv_net),2) as total_sales
			from a3
			group by 1,2
			order by 2,1 asc