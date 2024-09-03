/*
data dictionary:

menu_items table:
	column				description
    menu_item_id		Unique ID of a menu item
	item_name			Name of a menu item
	category			Category or type of cuisine of the menu item
	price				Price of the menu item (US Dollars $)
    
order details
	column				description:
	order_details_id	Unique ID of an item in an order
	order_id			ID of an order
	order_date			Date an order was put in (MM/DD/YY)
	order_time			Time an order was put in (HH:MM:SS AM/PM)
	item_id				Matches the menu_item_id in the menu_items table
*/

-- 1.1: View the menu_items table and write a query to find the number of items on the menu

SELECT COUNT(DISTINCT menu_item_id)
FROM menu_items;

-- answer: 32

-- 1.2: What are the least and most expensive items on the menu?

SELECT
	item_name,
    price
FROM menu_items
ORDER BY price DESC LIMIT 1;

SELECT
	item_name,
    price
FROM menu_items
ORDER BY price ASC LIMIT 1;

-- shrimp scampi is the most expensive item at 19.95. edamame is the cheapest at 5.

-- 1.3: How many italian dishes are on the menu? What are the least and most expensive Italian dishes on the menu?

SELECT
	category,
    COUNT(item_name) AS number_of_italian_dishes
FROM menu_items
WHERE category='Italian'
GROUP BY category;

SELECT
	item_name,
    price
FROM menu_items
WHERE category='Italian'
ORDER BY price DESC LIMIT 1;

SELECT
	item_name,
    price
FROM menu_items
WHERE category='Italian'
ORDER BY price ASC LIMIT 1;

-- There are 9 Italian dishes on the menu. The most expensive is Shrimp Scampi, still. The cheapest is Spaghetti at 14.50.

-- 1.4: How many dishes are in each category? What is the average dish range price within each category?

SELECT
	category,
    COUNT(menu_item_id) AS no_of_dishes,
    AVG(price) AS avg_price
FROM menu_items
GROUP BY category;

-- There are 6 American dishes that average at 10.00~, 8 Asian dishes averaging at 13.50~, 9 Mexican dishes averaging at 12~, and 9 Italian dishes averaging at 16.75.

-- 2.1: what is the date range of the order_details table?

SELECT order_date
FROM order_details
ORDER BY order_date DESC;

-- The timeframe is from January 1st 2023 to March 31st 2023.

-- 2.2: How many orders were made during this range? How many items were ordered in this range?

SELECT
	COUNT(DISTINCT order_id) AS no_of_orders,
    COUNT(item_id) AS no_of_items_ordered
FROM order_details;

-- 5370 orders for a total of 12097 items.

-- 2.3: What orders had the most number of items?

SELECT
	order_id,
    COUNT(item_id) AS items_in_order
FROM order_details
GROUP BY order_id
ORDER BY items_in_order DESC;

-- 7 different orders had 14 items.

-- 2.4: How many orders had more than 12 items?

SELECT
	order_id,
    COUNT(item_id) AS items_in_order
FROM order_details
GROUP BY order_id
HAVING items_in_order > 12;

-- 20 orders had more than 12 items.

-- 3.1: Combine the menu_items and order_detail tables into a single table.

SELECT *
FROM order_details AS od
	LEFT JOIN menu_items AS mi
		ON od.item_id = mi.menu_item_id;

-- 3.2: What were the least and most order items? What categories were they in?

SELECT
	od.item_id,
    mi.item_name,
    mi.category,
    COUNT(od.order_id) AS times_ordered
FROM order_details AS od
	LEFT JOIN menu_items AS mi
		ON od.item_id = mi.menu_item_id
GROUP BY od.item_id
ORDER BY times_ordered DESC;

-- The most commonly ordered item was the hamburger, American. The least common order was chicken tacos, Mexican

-- 3.3: What were the top 5 orders in terms of money spent?

SELECT
	od.order_id,
    SUM(mi.price) AS order_total
FROM order_details AS od
	LEFT JOIN menu_items AS mi
		ON od.item_id = mi.menu_item_id
GROUP BY od.order_id
ORDER BY order_total DESC
LIMIT 5;

-- See above. 192.15, 191.05, 190.10, 189.70, 185.10

-- 3.4: View the details of the highest spending order. Which items were purchased for the highest spending order?

SELECT *
FROM order_details AS od
	LEFT JOIN menu_items AS mi
		ON od.item_id = mi.menu_item_id
WHERE order_id = 440;

/* 2 orders of spaghetti & meatballs, 1 order of spaghetti, 1 steak tacos, 1 hot dog, 2 orders of fettuccine alfredo,
1 korean beef bowl, 1 meat lasagna, 1 edamame, 1 chips & salsa, 1 chicken parm, 1 french fries, 1 eggplant parm */

-- 3.5: View the details of the top 5 highest spending orders.

SELECT *
FROM order_details AS od
	LEFT JOIN menu_items AS mi
		ON od.item_id = mi.menu_item_id
WHERE od.order_id IN (440, 2075, 1957, 330, 2675);