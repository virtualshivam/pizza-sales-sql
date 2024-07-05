create database pizzahut;

use pizzahut;

drop table if exists order_details;
create table order_details(
	order_details_id int not null,
    order_id int not null,
    pizza_id text not null,
    quantity int not null,
    primary key(order_details_id)
);

alter table orders modify column `date` date;
alter table orders modify column `time` time;

/*                                                                                   Basic Questions                                                                        */
-- 1. Retrieve the total number of orders placed.
SELECT 
    COUNT(DISTINCT order_id) AS total_orders_count
FROM
    orders;


-- 2. Calculate the total revenue generated from pizza sales.
SELECT 
    ROUND(SUM(od.quantity * p.price), 2) AS total_revenue
FROM
    order_details od
        INNER JOIN
    pizzas p ON p.pizza_id = od.pizza_id;
    

-- 3. Identify the highest-priced pizza.
SELECT 
    pizza_types.name, pizzas.price
FROM
    pizzas
        JOIN
    pizza_types ON pizzas.pizza_type_id = pizza_types.pizza_type_id
WHERE
    price = (SELECT 
            MAX(price)
        FROM
            pizzas);

-- Alternate Method

SELECT 
    pizza_types.name, pizzas.price
FROM
    pizzas
        JOIN
    pizza_types ON pizzas.pizza_type_id = pizza_types.pizza_type_id
ORDER BY price DESC
LIMIT 1;


-- 4. Identify the most common pizza size ordered.
SELECT 
    p.size, sum(quantity)
FROM
    order_details od
        INNER JOIN
    pizzas p ON p.pizza_id = od.pizza_id
GROUP BY p.size
ORDER BY 2 DESC
LIMIT 1; 
    

-- 5. List the top 5 most ordered pizza types along with their quantities.

SELECT 
    pizza_types.name,
    SUM(order_details.quantity) AS total_quantity_ordered
FROM
    order_details
        JOIN
    pizzas ON order_details.pizza_id = pizzas.pizza_id
        JOIN
    pizza_types ON pizzas.pizza_type_id = pizza_types.pizza_type_id
GROUP BY pizza_types.name
ORDER BY total_quantity_ordered DESC
LIMIT 5;


/*                                                                      Intermediate Questions                                                                */
-- 1. Join the necessary tables to find the total quantity of each pizza category ordered.
SELECT 
    pizza_types.category,
    SUM(order_details.quantity) AS quantity_ordered
FROM
    order_details
        JOIN
    pizzas ON order_details.pizza_id = pizzas.pizza_id
        JOIN
    pizza_types ON pizzas.pizza_type_id = pizza_types.pizza_type_id
GROUP BY pizza_types.category
ORDER BY 2 DESC;


-- 2. Determine the distribution of orders by hour of the day.

SELECT 
    HOUR(`time`) AS order_hour, COUNT(order_id) AS order_count
FROM
    orders
GROUP BY 1
ORDER BY 1 ASC;

-- Insight: Orders peak during afternoon 12 to 1 p.m. and then falls and again peaks during 5 to 7 p.m. 


-- 3. Join relevant tables to find the category-wise distribution of pizzas.
SELECT 
    category, COUNT(*) as  pizza_available
FROM
    pizza_types
GROUP BY category;


-- 4. Group the orders by date and calculate the average number of pizzas ordered per day.

-- With CTE
with cte as (
  select 
    `date`, 
    sum(quantity) as quantity_sold 
  from 
    orders o 
    join order_details od on o.order_id = od.order_id 
  group by 
    `date`
) 
select 
  round(
    avg(quantity_sold), 
    0
  ) as average_quantity_per_day 
from 
  cte;
  
-- With Subquery 
SELECT 
    FLOOR(AVG(quantity_sold)) AS average_quantity_sold_per_day
FROM
    (SELECT 
        `date`, SUM(quantity) AS quantity_sold
    FROM
        orders o
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY `date`) AS date_wise_orders; 

-- 5. Determine the top 3 most ordered pizza types based on revenue.
SELECT 
    pizza_types.name,
    SUM(order_details.quantity * pizzas.price) AS revenue
FROM
    order_details
        JOIN
    pizzas ON order_details.pizza_id = pizzas.pizza_id
        JOIN
    pizza_types ON pizzas.pizza_type_id = pizza_types.pizza_type_id
GROUP BY pizza_types.name
ORDER BY 2 DESC
limit 3;
-- Insight: Chicken Pizzas are generating the most revenue



/*                                                                      Advanced Questions                                                                */
-- 1. Calculate the percentage contribution of each pizza type to total revenue.
-- Pizza Type
with cte1 as (SELECT 
    pizza_types.name,
    SUM(order_details.quantity * pizzas.price) AS revenue
FROM
    order_details
        JOIN
    pizzas ON order_details.pizza_id = pizzas.pizza_id
        JOIN
    pizza_types ON pizzas.pizza_type_id = pizza_types.pizza_type_id
GROUP BY pizza_types.name
ORDER BY 2 DESC),
cte2 as (select sum(revenue) as total_revenue from cte1)
select cte1.* , concat(round(cte1.revenue/cte2.total_revenue *100,2),"%") share_in_revenue from cte1,cte2;
-- Pizza Category
with cte1 as (SELECT 
    pizza_types.category,
    SUM(order_details.quantity * pizzas.price) AS revenue
FROM
    order_details
        JOIN
    pizzas ON order_details.pizza_id = pizzas.pizza_id
        JOIN
    pizza_types ON pizzas.pizza_type_id = pizza_types.pizza_type_id
GROUP BY pizza_types.category
ORDER BY 2 DESC),
cte2 as (select sum(revenue) as total_revenue from cte1)
select cte1.* , concat(round(cte1.revenue/cte2.total_revenue *100,2),"%") share_in_revenue from cte1,cte2;
-- Pizza Category Subquery
SELECT 
    pizza_types.category,
    CONCAT(ROUND(SUM(order_details.quantity * pizzas.price) / (SELECT 
                            SUM(price * quantity)
                        FROM
                            order_details,
                            pizzas
                        WHERE
                            order_details.pizza_id = pizzas.pizza_id) * 100,
                    2),
            '%') share_in_revenue
FROM
    order_details
        JOIN
    pizzas ON order_details.pizza_id = pizzas.pizza_id
        JOIN
    pizza_types ON pizzas.pizza_type_id = pizza_types.pizza_type_id
GROUP BY pizza_types.category
ORDER BY 2 DESC;


-- 2. Analyze the cumulative revenue generated over time.
select orders.date
, round(sum(sum(quantity*price)) over(order by `date`),2) as cumulative_revenue
 from order_details join pizzas on order_details.pizza_id = pizzas.pizza_id join orders on orders.order_id = order_details.order_id
group by 1;


-- 3. Determine the top 3 most ordered pizza types based on revenue for each pizza category.
with cte as (select name,category
, rank() over(partition by category order by sum(price*quantity) desc) as rn
,sum(price*quantity) as revenue
 FROM
    order_details
        JOIN
    pizzas ON order_details.pizza_id = pizzas.pizza_id
        JOIN
    pizza_types ON pizzas.pizza_type_id = pizza_types.pizza_type_id
    group by category,name)
select name,category, revenue from cte where rn<4;





