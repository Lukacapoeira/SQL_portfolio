/* STEP 1: Data Extraction & Filtering (a1)
   - Joining Orders, Positions, and Products.
   - Filtering for the year 2020 and excluding returned items.
*/
with a1 as (select 
o.order_id 
,o.order_date
,op.item_quantity 
,op.position_discount 
,p.product_price 
,p.product_name 
from orders o
left join order_positions op on o.order_id = op.order_id 
left join products p on op.product_id =p.product_id 
where not exists (select * from order_returns or2 
where o.order_id = or2.order_id)
and year(o.order_date)=2020)
,
	/* STEP 2: Net Value Calculation (a2)
   - Calculating Net GMV for each line item.
   - Ensuring safe discount handling with COALESCE(val, 0).
	*/
	a2 as (select 
	product_name
	,case when position_discount > 0 
	then item_quantity*product_price*(1-coalesce(position_discount,0))
	else item_quantity*product_price
	end as gmv_net
	from a1)
	,
		/* STEP 3: Product Level Aggregation (a3)
	   - Summing total sales per individual product.
		*/
		a3 as (select 
		product_name
		,SUM(gmv_net) as product_sales
		from a2
		group by 1)
		,
			/* STEP 4: Relative Share Calculation (a4)
		   - Calculating each product's percentage of total store sales.
		   - Formula: (Product Sales / Total Store Sales) * 100
			*/
			a4 as (select *
			,((product_sales/sum(product_sales)over())*100) as product_partition
			from a3 
			order by product_partition desc)
				/* STEP 5: Cumulative Share & Filtering (Pareto Rule)
			   - Calculating the Running Total of the percentage share.
			   - Sorting by best-selling products first.
			   - Filtering only the products that make up the first 80% of revenue.
				*/
				select * from (select *
				,sum(product_partition) over (order by product_sales desc) as pareto_rule
				from a4) as filter 
				where pareto_rule <= 80
