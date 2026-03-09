/* STEP 1: Data Extraction (a1)
   - Joining Orders, Order Positions, and Products.
   - Excluding returned orders to ensure we analyze actual retained revenue.
*/
with a1 as (select 
o.order_date 
,o.customer_id 
,o.order_id 
,op.item_quantity 
,op.position_discount 
,p.product_price
,p.product_id 
from orders o
left join order_positions op on o.order_id = op.order_id
left join products p on p.product_id = op.product_id 
where not exists (select *from
order_returns or2 where o.order_id = or2.order_id))
,
	/* STEP 2: Line Item Net Value (a2)
	   - Calculating the Net GMV for each individual product in the cart.
	   - Using COALESCE to handle NULL discounts safely.
	*/
	a2 as (select 
	customer_id 
	,order_date
	,order_id
	,product_id
	,case when position_discount > 0
	then (1-coalesce(position_discount,0))*item_quantity*product_price
	else item_quantity*product_price
	end as gmv_net
	from a1)
	,
		/* STEP 3: Order Level Aggregation (a3)
		   - Summing the line items to get the Total Cart Value (Total Spend) per order.
		*/
		a3 as (select 
		customer_id 
		,order_date
		,order_id
		,sum(gmv_net) as total_spend
		from a2
		group by 1,2,3)
		,
			/* STEP 4: Chronological Ordering (a4)
			   - Applying ROW_NUMBER() to identify the 1st, 2nd, 3rd, etc., order for EACH customer.
			*/
			a4 as (select 
			customer_id
			,order_date
			,order_id
			,total_spend
			,row_number()over(partition by customer_id order by order_date asc) as count
			from a3)
			,
				/* STEP 5: Sequence Categorization (a5)
				   - Grouping the order sequences into distinct, readable tiers.
				   - Combining the 4th and all subsequent orders into a single "4+ order" bucket.
				*/
				a5 as (select 
				customer_id
				,total_spend
				,case when count = 1 
				then "1 order"
				when count = 2
				then "2 order"
				when count = 3
				then "3 order"
				when count >=4
				then "4+ order"
				end as order_number
				from a4)
					/* STEP 6: Final Aggregation (Insight Generation)
					   - Calculating the Average Order Value (AOV) and Total Revenue for each sequence tier.
					*/
					select
					order_number
					,round(avg(total_spend),2) average_spend
					,round(sum(total_spend),2) total_spend
					from a5 
					group by 1
