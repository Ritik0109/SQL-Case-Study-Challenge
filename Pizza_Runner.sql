--A. Pizza Metrics


--How many Pizza were orders?
Select 
	count(order_id) as Ordered_Pizza
from
	#customer_orders

--How many unique Pizza were orders?
Select 
	count(distinct order_id) as unique_customers
from
	#customer_orders

--How many successful orders were delivered by each runner?
Select 
	runner_id, count(order_id) as Delivered 
from	
	#runner_orders
where cancellation = ''
group by runner_id


--How many of each type of pizza was delivered?
Select 
	pn.pizza_name, count(co.pizza_id) as Delivered_orders
from 
	#customer_orders co
left outer join
	#runner_orders ro on co.order_id=ro.order_id
left outer join
	pizza_names pn on co.pizza_id=pn.pizza_id
where ro.cancellation = ''
group by pn.pizza_name;



--How many Vegetarian and Meatlovers were ordered by each customer?


Select 
	co.customer_id,cast(p.pizza_name as varchar), count(co.pizza_id) as orderCount
from 
	#customer_orders co
 join 
	pizza_names p
on co.pizza_id=p.pizza_id
group by co.customer_id,cast(p.pizza_name as varchar)
order by co.customer_id



--What was the maximum number of pizzas delivered in a single order?

Select 
	 top 1 count(pizza_id) as Delivered_pizzas 
from 
	#customer_orders co
join
	#runner_orders ro
on co.order_id=ro.order_id
where ro.cancellation like ''
group by co.order_id
order by Delivered_pizzas desc



--For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

Select 
	customer_id,
SUM(CASE 
  WHEN c.exclusions <> ' ' OR c.extras <> ' ' THEN 1
  ELSE 0
  END) AS at_least_1_change,
SUM(CASE 
  WHEN c.exclusions = ' ' AND c.extras = ' ' THEN 1 
  ELSE 0
  END) AS no_change
from
	#customer_orders c
join 
	#runner_orders ro
on c.order_id=ro.order_id
where cancellation like ''
GROUP BY c.customer_id
ORDER BY c.customer_id;



--How many pizzas were delivered that had both exclusions and extras?


Select 
	count(c.pizza_id) as Total_pizzas_delivered_with_changes
from	
	(Select * from #customer_orders
	where extras not like '' and exclusions not like '') c
join
	#runner_orders r
on c.order_id=r.order_id
where distance != 0



--What was the total volume of pizzas ordered for each hour of the day?

Select	
	DATEPART(HOUR, [order_time]) as Hour_of_the_day, count(order_id) as Total_pizza_ord
from 
	#customer_orders
group by DATEPART(HOUR,[order_time])



--What was the volume of orders for each day of the week?

Select FORMAT(DATEADD(DAY, 2, order_time),'dddd') AS day_of_week, 
-- add 2 to adjust 1st day of the week as Monday
 COUNT(order_id) AS total_pizzas_ordered
FROM #customer_orders
GROUP BY FORMAT(DATEADD(DAY, 2, order_time),'dddd');





--B. Runner and Customer Experience


--How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

Select 
	DATEPART(WEEK, registration_date) as registration_week,
	count(runner_id) as runner_signups
from
	runners
group by DATEPART(WEEK, registration_date)


--What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

Select
	c.order_id, c.order_time,r.pickup_time, avg(DATEDIFF(MINUTE,c.order_time,r.pickup_time)) as AVG_Pickup_Time
from
	#customer_orders c
join 
	#runner_orders r
on c.order_id=r.order_id
where r.distance != 0
group by c.order_id, c.order_time,r.pickup_time



SELECT AVG(pickup_minutes) AS avg_pickup_minutes
FROM time_taken_cte
WHERE pickup_minutes > 1;


--Is there any relationship between the number of pizzas and how long the order takes to prepare?

With cte_pizza as
(Select
	c.order_id, c.order_time,r.pickup_time,count(c.pizza_id) as Total_Pizzas, avg(DATEDIFF(MINUTE,c.order_time,r.pickup_time)) as AVG_Pickup_Time
from
	#customer_orders c
join 
	#runner_orders r
on c.order_id=r.order_id
where r.distance != 0
group by c.order_id, c.order_time,r.pickup_time)

Select 
	Total_pizzas, avg(Avg_Pickup_time) as Avg_prep_time
from
	cte_pizza
group by Total_pizzas


--What was the average distance travelled for each customer?

Select 
	c.Customer_id, Round(avg(r.distance),2) as Avg_distance_Travelled
from 
	#customer_orders c
join
	#runner_orders r
on c.order_id=r.order_id
where distance != 0
group by c.customer_id


--What was the difference between the longest and shortest delivery times for all orders?



Select 
  (
    max(duration)- min(duration)
  ) delivery_time_diff 
from 
  #runner_orders
where 
  distance != 0




  --What was the average speed for each runner for each delivery and do you notice any trend for these values?


Select 
	 r.runner_id, c.customer_id, c.order_id, 
	 count(c.order_id) as pizza_count, 
	 r.distance, (r.duration / 60) as duration_hr, 
	 round(distance/duration * 60,2) as Avg_speed
from 
	#runner_orders r
join 
	#customer_orders c
on r.order_id=c.order_id
where distance != 0
group by r.runner_id, c.customer_id, c.order_id,r.distance, r.duration
order by c.order_id;




--What is the successful delivery percentage for each runner?

Select 
	runner_id,
	round(100* sum(
case
when distance = 0 then 0
else 1 
end) / count(*),0) as success_del
from
	#runner_orders
group by runner_id





































create table #customer_orders (order_id smallint, customer_id int, pizza_id smallint, exclusions varchar(10) NOT NULL, extras varchar(10) NOT NULL, order_time datetime) 

Insert into #customer_orders 
Select 
	order_id, customer_id, pizza_id,
case 
when exclusions is null or exclusions like 'null' then '' else exclusions
end as exclusions,
case
when extras is Null or extras like 'null' then '' else extras   
end as extras,
order_time
from 
	customer_orders

	Select 
	order_id,
	runner_id,
case 
when pickup_time is null or pickup_time like 'null' then '' else pickup_time
end as pickup_time,
case 
when distance like 'null' then ''
when distance like '%km' then trim ('km' from distance) else distance
end as distance,
case 
when duration like 'null' then '' 
when duration like '%mins' then trim ('mins' from duration) 
when duration like '%minute' then trim ('minute' from duration)
when duration like '%minutes' then trim ('minutes' from duration) else duration
end as duration,
case 
when cancellation is null or cancellation like 'null' then '' else cancellation
end as cancellation
into #runner_orders
from
	runner_orders
go




alter table #runner_orders
alter column pickup_time datetime;
alter table #runner_orders
alter column distance float;
alter table #runner_orders
alter column duration int;