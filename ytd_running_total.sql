/* STEP 1: Data Extraction (a1)
   - Retrieving order details for the year 2019.
   - Extracting month numbers for chronological sorting.
   - Filtering out returned orders to ensure accuracy.
*/
with a1 as (select 
o.order_date
,month(o.order_date) as month_num
,o.order_id 
,op.item_quantity 
,op.product_id 
,op.position_discount 
,p.product_price 
from orders o
left join order_positions op on o.order_id = op.order_id
left join products p on op.product_id = p.product_id 
where not exists(select *
from order_returns or2 where
or2.order_id = o.order_id)
and year(o.order_date) = 2019)
,
/* STEP 2: Net Value Calculation (a2)
   - Applying the discount logic to calculate Net GMV.
   - Using COALESCE to handle potential NULL values in discounts.
*/
	a2 as (select 
	month_num 
	,order_id
	,case when position_discount > 0
	then (1-coalesce(position_discount,0))*item_quantity*product_price
	else item_quantity*product_price
	end as gmv_net
	from a1)
	,
	/* STEP 3: Monthly Aggregation (a3)
   - Summing up net sales for each month.
   - Ordering by month to prepare for the window function.
*/
		a3 as (select 
		month_num
		,round(sum(gmv_net),2) as total_sales
		from  a2
		group by 1
		order by 1 asc)
		/* STEP 4: Running Total Calculation (YTD)
   - Calculating the Cumulative Sum (Running Total) using a Window Function.
   - LOGIC: The window grows with each row (Unbounded Preceding to Current Row).
*/
			select *
			,sum(total_sales) over (order by month_num asc) as running_total
			from a3
