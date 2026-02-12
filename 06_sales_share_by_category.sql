/* STEP 1: Data Extraction (a1)
   - Joining Orders, Positions, Products, and Product Groups.
   - Filtering for the year 2020.
   - Excluding returns (NOT EXISTS) to ensure net sales accuracy.
*/
with a1 as (select 
o.order_date
,o.order_id
,op.item_quantity 
,op.position_discount 
,p.product_price 
,pg.product_group 
from orders o
left join order_positions op on o.order_id = op.order_id 
left join products p on op.product_id = p.product_id 
left join product_groups pg on p.group_id =pg.group_id 
where not exists (
select * from order_returns or2
where o.order_id = or2.order_id)
and year(o.order_date)=2020)
,
/* STEP 2: Net Value Calculation (a2)
   - Calculating Net GMV per transaction line.
   - Logic: Price * Quantity * (1 - Discount).
*/
	a2 as (select 
	order_date
	,order_id 
	,case when position_discount > 0
	then item_quantity * product_price*(1-coalesce(position_discount,0))
	else item_quantity * product_price
	end as gmv_net
	,product_group
	from a1)
	,
	/* STEP 3: Category Aggregation (a3)
   - Summing sales by Product Group.
	*/
		a3 as (select 
		product_group
		,sum(gmv_net) as total_sales
		from a2
		group by 1)
		/* STEP 4: Share of Total Calculation
   - Calculating the percentage share for each group.
   - TECHNIQUE: total_sales / SUM(total_sales) OVER() -> (Part / Whole).
   - The empty OVER() clause allows access to the grand total in every row.
   */
			select * from 
				(select 
				product_group
				,round(total_sales,2)
				,round((total_sales/sum(total_sales)over())*100,1) as percent_of_total
				from a3)
			as summarize