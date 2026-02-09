/* STEP 1: Data Extraction & Filtering (a1)
   - Joining Orders, Positions, and Products tables.
   - Filtering for the year 2020.
   - Excluding returned orders to focus on net sales.
*/
with a1 as (select 
o.order_date 
,extract(year_month from o.order_date) as date_key
,o.order_id 
,op.product_id
,op.item_quantity
,op.position_discount
,p.product_price
from orders o 
left join order_positions op on o.order_id=op.order_id
-- Corrected join condition: linking order positions to products table
left join products p on op.product_id = p.product_id
where not exists(
select * from order_returns or2 
where or2.order_id = o.order_id)
and year(o.order_date)=2020)
,
/* STEP 2: Net Value Calculation (a2)
   - Calculating GMV (Gross Merchandise Value) per line item.
   - Handling discounts safely with COALESCE function.
*/
	a2 as (select 
	order_date
	,date_key
	,month(order_date) as month_num
	,case when position_discount > 0
	then (1-coalesce(position_discount,0))*product_price*item_quantity
	else product_price*item_quantity
	end as gmv_net
	from a1)
	,
/* STEP 3: Monthly Aggregation (a3)
   - Summing up sales to get the total monthly revenue.
   - Sorting by month to prepare for the window function.
*/
		a3 as (select 
		month_num
		,round(sum(gmv_net),0) as total_sale
		from a2
		group by 1
		order by 1 asc)
/* STEP 4: Moving Average Calculation
   - Computing the 3-Month Moving Average.
   - LOGIC: Average of (Current Month + 2 Previous Months).
*/
	select *
	,ROUND(avg(total_sale)over(order by month_num rows between 2 preceding and current row),0) as lasts
	from a3
