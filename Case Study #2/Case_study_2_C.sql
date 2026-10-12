#1 What are the standard ingredients for each pizza?
with a1 as (select 
t.pizza_id
,jt.topping_id
,pt.topping_name 
from pizza_ingriedients t 
join json_table(concat('[',t.toppings,']'),
'$[*]' columns(topping_id int path '$')) as jt
on true 
left join pizza_toppings pt  on jt.topping_id = pt.topping_id
left join pizza_names pn on t.pizza_id = pn.pizza_id )
select 
pizza_id
,GROUP_CONCAT(topping_name) as topping_name
from a1
group by 1

pizza_id|topping_name                                                                                       |
--------+---------------------------------------------------------------------------------------------------+
1       |Bacon,BBQ Sauce,Beef,Cheese,Chicken,Mushrooms,Pepperoni,Salami                                     |
2       |Cheese,Mushrooms,Onions,Peppers,Tomatoes,Tomato Sauce                                              |
3       |Bacon,BBQ Sauce,Beef,Cheese,Chicken,Mushrooms,Onions,Pepperoni,Peppers,Salami,Tomatoes,Tomato Sauce|
;
