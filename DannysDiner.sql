CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

  
-- 1. What is the total amount each customer spent at the restaurant?

SELECT
  	s.customer_id, SUM(m.price) AS AmountSpent
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;


-- 2. How many days has each customer visited the restaurant?

SELECT
  	customer_id, count(DISTINCT order_date) AS No_of_Days
FROM dannys_diner.sales 
GROUP BY customer_id
ORDER BY customer_id;


-- 3. What was the first item from the menu purchased by each customer?

WITH first_item_purchased AS(
	SELECT
  		s.customer_id,s.order_date, m.product_name,
		RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
	FROM dannys_diner.menu m
	INNER JOIN dannys_diner.sales s
	ON m.product_id = s.product_id
	)

SELECT 
	customer_id, product_name 
FROM first_item_purchased 
WHERE rank =1;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1
  	 m.product_name, COUNT(s.product_id) AS no_of_products
FROM dannys_diner.menu m
INNER JOIN dannys_diner.sales s
ON m.product_id = s.product_id
GROUP BY m.product_name
ORDER BY no_of_products DESC;


-- 5. Which item was the most popular for each customer?

WITH most_popular_items AS(
	SELECT
  		s.customer_id, m.product_name, COUNT(s.product_id) AS no_of_times_purchased,
		RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC)AS rank
	FROM dannys_diner.menu m
	INNER JOIN dannys_diner.sales s
	ON m.product_id = s.product_id
	GROUP BY s.customer_id, m.product_name
	ORDER BY s.customer_id ASC, COUNT(s.product_id) DESC
	)

SELECT 
	customer_id, product_name 
FROM most_popular_items 
WHERE rank=1;


-- 6. Which item was purchased first by the customer after they became a member?

WITH first_purchased AS(
	SELECT 
		s.customer_id, s.order_date, s.product_id,
		RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS rank
	FROM dannys_diner.sales s
	INNER JOIN dannys_diner.members m
	ON s.customer_id=m.customer_id
	WHERE s.order_date>=m.join_date
	)

SELECT
	customer_id, m.product_name 
FROM first_purchased f
INNER JOIN dannys_diner.menu m
ON f.product_id = m.product_id
WHERE rank = 1
ORDER BY customer_id;


-- 7. Which item was purchased just before the customer became a member?

WITH purchase_before_member AS(
	SELECT 
		s.customer_id, s.order_date, s.product_id,
		RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rank
	FROM dannys_diner.sales s
	INNER JOIN dannys_diner.members m
	ON s.customer_id=m.customer_id
	WHERE s.order_date<m.join_date
	)

SELECT 
	customer_id, m.product_name 
FROM purchase_before_member p
INNER JOIN dannys_diner.menu m
ON p.product_id = m.product_id
WHERE rank = 1
ORDER BY customer_id;


-- 8. What is the total items and amount spent for each member before they became a member?

SELECT 
	s.customer_id, COUNT(s.product_id) AS unique_items,SUM(m.price) AS amount_spent
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu m
ON s.product_id = m.product_id
INNER JOIN dannys_diner.members me
ON s.customer_id=me.customer_id
WHERE s.order_date<me.join_date
GROUP BY s.customer_id;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT 
	s.customer_id, 
	SUM(CASE WHEN m.product_name = 'sushi' then 2*m.price*10
		ELSE m.price*10 
		END) AS points
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY customer_id
ORDER BY points DESC;




-- 10. In the first week after a customer joins the program
-- (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH customer_member_points AS(
	SELECT 
		s.customer_id, s.order_date, s.product_id, m.product_name,m.price,me.join_date,EXTRACT(MONTH FROM s.order_date) AS month,
		CASE 
			WHEN (s.order_date >= me.join_date AND s.order_date < me.join_date+7) THEN 2*m.price*10
			ELSE
    			CASE 
        			WHEN m.product_name = 'sushi' THEN 2*m.price*10
					ELSE m.price*10 
					END
			END AS points
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu m
ON s.product_id = m.product_id
INNER JOIN dannys_diner.members me
on s.customer_id=me.customer_id
)

SELECT 
	customer_id, SUM(points)
FROM customer_member_points
WHERE month = 1
GROUP BY customer_id
ORDER BY customer_id;




