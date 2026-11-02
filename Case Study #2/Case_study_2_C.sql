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
#2 What was the most commonly added extra?
with a1 as (select 
j.ads
from customer_orders co 
join
json_table(
concat('[',co.extras,']'),
'$[*]' columns(ads int path '$')) as j
where co.extras not like '' and co.extras  is not null)
select 
pt.topping_name 
,count(pt.topping_name) as count_of_toppings
from a1 
left join pizza_toppings pt on pt.topping_id = a1.ads
group by 1
order by 2 desc


topping_name|count_of_toppings|
------------+-----------------+
Bacon       |                4|
Chicken     |                1|
Cheese      |                1|
;


#3 What was the most common exclusion?
with a1 as (select 
j.exclusion
from customer_orders co 
join
json_table(
concat('[',co.exclusion,']'),
'$[*]' columns(exclusion int path '$')) as j
where co.exclusion not like '' and co.exclusion  is not null)
select 
pt.topping_name 
,count(pt.topping_name) as count_of_toppings
from a1 
left join pizza_toppings pt on pt.topping_id = a1.exclusion
group by 1
order by 2 desc


topping_name|count_of_toppings|
------------+-----------------+
Cheese      |                4|
BBQ Sauce   |                1|
Mushrooms   |                1|
;

#4 Generate an order item for each record in the customers_orders table in the format of one of the following:
#Meat Lovers | Meat Lovers - Exclude Beef | Meat Lovers - Extra Bacon | Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
with a1 as (
select
row_number() over (order by pn.pizza_name ) as true_key
,pn.pizza_name 
,co.exclusion 
,co.extras 
from customer_orders co 
left join pizza_names pn on pn.pizza_id = co.pizza_id )
,
#przygotowanie json dla excluded
a2 as (
select
a1.true_key 
,a1.pizza_name
,a1.exclusion
from a1
where a1.exclusion is not null and a1.exclusion not like ''
)
#zrobienie json na excluded
,
a3 as (select 
true_key
,exc.excluded
from a2
join json_table(
concat('[',a2.exclusion,']'),'$[*]'
columns (excluded int path '$')
) as exc
)
#dodanie nazw wylączonych skladnikow
,
a4 as (
select 
true_key
,a3.excluded 
,pt.topping_name 
from a3
left join pizza_toppings pt  on a3.excluded = pt.topping_id  
)
,
#przygotowanie json dla extras
a5 as (
select
a1.true_key 
,a1.pizza_name
,a1.extras
from a1
where a1.extras is not null and a1.extras not like ''
)
#zrobienie json na extras
,
a6 as (select 
true_key
,ext.extras
from a5
join json_table(
concat('[',a5.extras,']'),'$[*]'
columns (extras int path '$')
) as ext
)
#dodanie nazw wylączonych skladnikow
,
a7 as (
select 
true_key
,a6.extras 
,pt.topping_name 
from a6
left join pizza_toppings pt  on a6.extras = pt.topping_id  
)
#zrobienie group concat dla nazw skladnickow exclude
, a8 as (select 
true_key
,group_concat(a4.topping_name) as excluded_name
from a4
group by 1)
,
a9 as (
select
true_key
,group_concat(topping_name) as extra_name
from a7
group by 1
)
,
a10 as (select  #Polączenie w logiczna calosc joinowanie true key z nazwami 
a1.true_key 
,a1.pizza_name 
,a8.excluded_name 
,a9.extra_name 
from a1
left join a8 on a1.true_key = a8.true_key 
left join a9 on a1.true_key = a9.true_key 
)
select 
true_key
,a10.pizza_name
, case when extra_name is not null and excluded_name is not null then group_concat(pizza_name,' ','Excluded',' ',excluded_name,' ','Extra',' ',extra_name)
when excluded_name is not null then group_concat(pizza_name,' ','Excluded',' ',excluded_name)
when extra_name is not null then group_concat(pizza_name,' ','Extra',' ',extra_name)
else a10.pizza_name
end as Summarized_changes
from a10
group by 1,2

true_key|pizza_name|Summarized_changes                                        |
--------+----------+----------------------------------------------------------+
       1|meatlovers|meatlovers                                                |
       2|meatlovers|meatlovers                                                |
       3|meatlovers|meatlovers                                                |
       4|meatlovers|meatlovers Excluded Cheese                                |
       5|meatlovers|meatlovers Excluded Cheese                                |
       6|meatlovers|meatlovers Extra Bacon                                    |
       7|meatlovers|meatlovers                                                |
       8|meatlovers|meatlovers Excluded Cheese Extra Bacon,Chicken            |
       9|meatlovers|meatlovers                                                |
      10|meatlovers|meatlovers Excluded BBQ Sauce,Mushrooms Extra Bacon,Cheese|
      11|vegetarian|vegetarian                                                |
      12|vegetarian|vegetarian Excluded Cheese                                |
      13|vegetarian|vegetarian                                                |
      14|vegetarian|vegetarian Extra Bacon                                    |


;
#5 Generate an alphabetically ordered comma separated ingredient list 
#for each pizza order from the customer_orders table and add
#a 2x in front of any relevant ingredients
with a1 as (select    #przygotowanie tabeli danych
row_number() over (order by co.order_id) as unique_key
,co.order_id 
,co.customer_id 
,co.pizza_id 
,t.toppings 
,co.exclusion 
,co.extras 
from customer_orders co 
left join pizza_ingriedients t on co.pizza_id = t.pizza_id )
,
a2 as (#zrobienie json_tabel aby miec liste skladnikow do pizzy
select 
unique_key 
,toping_list.toping
from a1
join json_table(concat('[',toppings,']'), '$[*]'
columns(toping int path '$')
) as toping_list
)
,
a3 as (#zrobienie nastepnie listy json dla wylaczen
select
unique_key
,exc.excluded
from a1
join json_table(concat('[',exclusion,']'), '$[*]'
columns( excluded int path '$')
) as exc
)
,
a4 as (#pozbycie sie excluded z glownej listy, Stworzenie nowej listy bez excluded
select 
a2.unique_key 
,a2.toping
from a2
left join a3 on a2.unique_key = a3.unique_key and a2.toping = a3.excluded 
where excluded is null
)
,a5 as (#stworzenie listy extras
select 
unique_key
,ext.extra
from a1
join json_table(concat('[',extras,']'), '$[*]'
columns(extra int path '$')
) as ext
)
,a6 as (#dodanie extras do listy po odjeciu excluded
select * from a4
union all
select * from a5
)
,a7 as (#porzadkowanie listy a6 liczenie podwojnych skladnikow
select *
,count(toping) as count_of_toping
from a6
group by 1,2
)
,a8 as (#dodawanie nazw skladnikow i szykowanie sie pod concat
select 
a7.unique_key 
,a7.toping 
,a7.count_of_toping 
,pt.topping_name
from a7
left join pizza_toppings pt on a7.toping = pt.topping_id )
,
a9 as(select #szykowanie podwojnych nazw
unique_key
,case when count_of_toping >1
then concat(count_of_toping,'x ',topping_name)
else topping_name
end as toping_count
from a8
order by 2
) 
,
a10 as (select #dodanie nazw pizz 
unique_key
,group_concat(toping_count) as toping_list
from a9
group by 1)
select 
a10.unique_key
,a1.order_id 
,pn.pizza_name 
,a10.toping_list
from a10
left join a1 on a10.unique_key = a1.unique_key 
left join pizza_names pn  on a1.pizza_id = pn.pizza_id 


unique_key|order_id|pizza_name|toping_list                                                      |
----------+--------+----------+-----------------------------------------------------------------+
         1|1       |meatlovers|Bacon,BBQ Sauce,Beef,Cheese,Chicken,Mushrooms,Pepperoni,Salami   |
         2|10      |meatlovers|Bacon,BBQ Sauce,Beef,Cheese,Chicken,Mushrooms,Pepperoni,Salami   |
         3|10      |meatlovers|2x Bacon,Beef,2x Cheese,Chicken,Pepperoni,Salami                 |
         4|2       |meatlovers|Bacon,BBQ Sauce,Beef,Cheese,Chicken,Mushrooms,Pepperoni,Salami   |
         5|3       |meatlovers|Bacon,BBQ Sauce,Beef,Cheese,Chicken,Mushrooms,Pepperoni,Salami   |
         6|3       |vegetarian|Cheese,Mushrooms,Onions,Peppers,Tomatoes,Tomato Sauce            |
         7|4       |meatlovers|Bacon,BBQ Sauce,Beef,Chicken,Mushrooms,Pepperoni,Salami          |
         8|4       |meatlovers|Bacon,BBQ Sauce,Beef,Chicken,Mushrooms,Pepperoni,Salami          |
         9|4       |vegetarian|Mushrooms,Onions,Peppers,Tomatoes,Tomato Sauce                   |
        10|5       |meatlovers|2x Bacon,BBQ Sauce,Beef,Cheese,Chicken,Mushrooms,Pepperoni,Salami|
        11|6       |vegetarian|Cheese,Mushrooms,Onions,Peppers,Tomatoes,Tomato Sauce            |
        12|7       |vegetarian|Cheese,Mushrooms,Onions,Peppers,Tomatoes,Tomato Sauce,Bacon      |
        13|8       |meatlovers|Bacon,BBQ Sauce,Beef,Chicken,Mushrooms,Pepperoni,Salami,Cheese   |
        14|9       |meatlovers|2x Bacon,Beef,2x Chicken,Mushrooms,Pepperoni,Salami,BBQ Sauce    |
;

#6 What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
with a1 as (# przygotowanie tabeli danych w tym wylaczenie niedowiezionych
select 
t.toppings 
,co.exclusion 
,co.extras 
from customer_orders co
left join runner_orders ro on co.order_id = ro.order_id 
left join pizza_ingriedients t on co.pizza_id = t.pizza_id 
where ro.pickup_time is not null)
,a2 as (select # wykonanie listy json_table dla listy topping
j.toping_list
from a1
join JSON_TABLE(concat('[',toppings,']'),'$[*]'
columns (toping_list int path '$')) as j
)
,a3 as (select #zrobienie json na excluded
exc.excluded
,count(exc.excluded) as count_of_excluded
from a1
join json_table(concat('[',exclusion,']'), '$[*]'
columns(excluded int path '$')
) as exc
group by 1)
,a4 as (select #zrobienie json na extras
ext.extra
from a1
join json_table(concat('[',extras,']'), '$[*]'
columns(extra int path '$')
) as ext)
,a5 as (select * from a2 #union all na zamowieniach i extras
union all
select * from a4)
,a6 as (select #przygotowanie zestawienia toping oraz excluded toping  
a5.toping_list
,count(a5.toping_list) as count_of_basic_topping
,count_of_excluded
from a5
left join a3 on a3.excluded = a5.toping_list 
group by 1,3
order by 1 asc)
select 
pt.topping_name 
,case when count_of_excluded is not null then
count_of_basic_topping  - count_of_excluded 
else count_of_basic_topping
end as final_topings_number
from a6
left join pizza_toppings pt on a6.toping_list = pt.topping_id 
order by 2 desc


topping_name|final_topings_number|
------------+--------------------+
Bacon       |                  12|
Mushrooms   |                  11|
Cheese      |                  10|
Beef        |                   9|
Chicken     |                   9|
Pepperoni   |                   9|
Salami      |                   9|
BBQ Sauce   |                   8|
Onions      |                   3|
Peppers     |                   3|
Tomatoes    |                   3|
Tomato Sauce|                   3|