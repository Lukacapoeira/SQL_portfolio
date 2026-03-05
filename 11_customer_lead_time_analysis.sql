/* STEP 1: Base Data Extraction (a1)
   - Selecting the core order details needed for timeline analysis.
*/
with a1 as (select 
o.order_date 
,o.order_id 
,o.customer_id 
from orders o)
,
	/* STEP 2: Fetching the Next Order Date (a2)
	   - Using LEAD() to peek at the next chronological order for each customer.
	   - PARTITION BY customer_id ensures we don't mix up different customers' timelines.
	   - ORDER BY order_date ensures we are looking exactly at the next consecutive order.
	*/
	a2 as (select 
	order_id
	,customer_id
	,order_date
	,lead(order_date)over(partition by customer_id order by order_date ) as next_order
	from a1)
	,
		/* STEP 3: Calculating Days Between Orders (a3)
		   - Using DATEDIFF to calculate the gap between the current order and the next one.
		*/
		a3 as (select 
		customer_id 
		,DATEDIFF(next_order,order_date) as days_beetween
		from a2)
			/* STEP 4: Final Aggregation
			   - Calculating the average order gap per customer.
			   - The HAVING clause gracefully filters out one-time buyers (who have NULL averages).
			*/
			select
			customer_id
			,round(avg(days_beetween),0) as average_order
			from a3
			group by 1
			having average_order >=0