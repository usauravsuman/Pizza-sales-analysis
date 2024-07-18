create database piza_sales_data_analysis;


-- then load dataset on the data table (order_details.csv,orders.csv,pizza_types.csv, pizzas.csv)
use piza_sales_data_analysis;

select * from order_details,orders,pizza_types,pizzas;


--total number of orders placed.
select count(*) as total_order
from orders;

--total revenue generated from pizza sales.
SELECT SUM(cast(od.quantity as INT) * cast(p.price as DECIMAL(10,2))) AS total_revenue -- (cast note)
FROM order_details od
JOIN 
pizzas p 
ON od.pizza_id = p.pizza_id;


--highest-priced pizza.

SELECT pizza_id, pizza_type_id, size, price
FROM pizzas
WHERE price = (SELECT MAX(price) FROM pizzas);


--the most common pizza size ordered.
select top 1 pizzas.size, count(*) as size_count
from pizzas
group by size
order by size_count desc;


--top 5 most ordered pizza types along with their quantities.

select top 5 pt.name AS pizza_type, SUM(cast(od.quantity as int)) as total_quantity
from order_details od 
join 
pizzas p
on od.pizza_id = p.pizza_id
join 
pizza_types pt 
on p.pizza_type_id = pt.pizza_type_id
group by pt.name
order by total_quantity desc;

--Join the necessary tables to find the total quantity of each pizza category ordered.

SELECT pt.name AS pizza_category, SUM(CAST(od.quantity AS INT)) AS total_quantity
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id
JOIN pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY total_quantity DESC;

--distribution of orders by hour of the day.
SELECT 
    DATEPART(HOUR, time) AS hour_of_day, 
    COUNT(*) AS order_count
FROM 
    orders
GROUP BY 
    DATEPART(HOUR, time)
ORDER BY 
    hour_of_day;

--Join relevant tables to find the category-wise distribution of pizzas.
SELECT 
    pt.category AS pizza_category, 
    SUM(CAST(od.quantity AS INT)) AS total_quantity
FROM 
    order_details od
JOIN 
    pizzas p ON od.pizza_id = p.pizza_id
JOIN 
    pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY 
    pt.category
ORDER BY 
    total_quantity DESC;


--average number of pizzas ordered per day.
SELECT 
    date,
    AVG(daily_order_count) AS average_pizzas_ordered
FROM (
    SELECT 
        o.date,
        SUM(CAST(od.quantity AS INT)) AS daily_order_count
    FROM 
        orders o
    JOIN 
        order_details od ON o.order_id = od.order_id
    GROUP BY 
        o.date
) AS daily_orders
GROUP BY 
    date
ORDER BY 
    date;

--top 3 most ordered pizza types based on revenue.
SELECT TOP 3
    pt.name AS pizza_type,
    SUM(CAST(od.quantity AS INT) * CAST(p.price AS DECIMAL(10,2))) AS total_revenue
FROM 
    order_details od
JOIN 
    pizzas p ON od.pizza_id = p.pizza_id
JOIN 
    pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY 
    pt.name
ORDER BY 
    total_revenue DESC;



--contribution of each pizza type to total revenue.

DECLARE @total_revenue DECIMAL(10,2);
SELECT @total_revenue = SUM(CAST(od.quantity AS INT) * CAST(p.price AS DECIMAL(10,2)))
FROM order_details od
JOIN pizzas p ON od.pizza_id = p.pizza_id;

-- Calculate revenue for each pizza type and its percentage contribution
SELECT 
    pt.name AS pizza_type,
    SUM(CAST(od.quantity AS INT) * CAST(p.price AS DECIMAL(10,2))) AS revenue,
    (SUM(CAST(od.quantity AS INT) * CAST(p.price AS DECIMAL(10,2))) / @total_revenue) * 100 AS percentage_contribution
FROM 
    order_details od
JOIN 
    pizzas p ON od.pizza_id = p.pizza_id
JOIN 
    pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
GROUP BY 
    pt.name;

--revenue generated over time.

SELECT 
    date,
    SUM(revenue) OVER (ORDER BY CONVERT(VARCHAR, date)) AS cumulative_revenue
FROM (
    SELECT 
        o.date,
        SUM(CAST(od.quantity AS INT) * CAST(p.price AS DECIMAL(10,2))) AS revenue
    FROM 
        orders o
    JOIN 
        order_details od ON o.order_id = od.order_id
    JOIN 
        pizzas p ON od.pizza_id = p.pizza_id
    GROUP BY 
        o.date
) AS daily_revenue
ORDER BY 
    date;



--top 3 most ordered pizza types based on revenue for each pizza category.
WITH PizzaTypeRevenue AS (
    SELECT 
        pt.category AS pizza_category,
        pt.name AS pizza_type,
        SUM(CAST(od.quantity AS INT) * CAST(p.price AS DECIMAL(10, 2))) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY pt.category ORDER BY SUM(CAST(od.quantity AS INT) * CAST(p.price AS DECIMAL(10, 2))) DESC) AS category_rank
    FROM 
        order_details od
    JOIN 
        pizzas p ON od.pizza_id = p.pizza_id
    JOIN 
        pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
    GROUP BY 
        pt.category, pt.name
)
SELECT 
    pizza_category,
    pizza_type,
    revenue
FROM 
    PizzaTypeRevenue
WHERE 
    category_rank <= 3;
