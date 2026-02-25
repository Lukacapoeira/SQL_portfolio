/* STEP 1: Data Extraction & Filtering (a1)
   - Joining Orders, Order Positions, Products, and Customer tables.
   - Filtering for the year 2019.
   - Excluding returned orders to ensure we only analyze successful transactions.
*/
with a1 as (select 
o.order_date 
,c.customer_name 
,o.order_id 
,op.item_quantity 
,op.position_discount 
,p.product_price 
from orders o
left join order_positions op on o.order_id = op.order_id 
left join products p on op.product_id = p.product_id 
left join customer c on o.customer_id = c.customer_id
where not exists(select *
from order_returns or2 where o.order_id = or2.order_id)
and year(o.order_date) = 2019)
,
	/* STEP 2: Net Value Calculation (a2)
	   - Calculating Net GMV per item line.
	   - Using COALESCE to safely handle NULL discount values.
	*/
	a2 as (select 
	customer_name
	,case when position_discount > 0
	then (1-coalesce(position_discount,0))*product_price*item_quantity
	else item_quantity*product_price
	end as gmv
	from a1)
	,
		/* STEP 3: Customer Aggregation (a3)
		   - Summing the total spending (GMV) for each customer.
		*/
		a3 as (select
		customer_name
		,sum(gmv) as total_sales
		from a2
		group by 1)
			/* STEP 4: Quartile Segmentation & Filtering (NTILE)
			   - Using NTILE(4) to divide customers into 4 equal tiers based on spending.
			   - Wrapping the query to filter and display ONLY the top tier (Quartile 1).
			*/
			select * from(
			select 
			customer_name 
			,round(total_sales,2) as clean_sales
			,ntile(4) over(order by total_sales desc) as quartile
			from a3) as top
			where quartile = 1