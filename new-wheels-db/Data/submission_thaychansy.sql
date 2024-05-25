USE new_wheels;

/*

-----------------------------------------------------------------------------------------------------------------------------------
													    Guidelines
-----------------------------------------------------------------------------------------------------------------------------------

The provided document is a guide for the project. Follow the instructions and take the necessary steps to finish
the project in the SQL file			

-----------------------------------------------------------------------------------------------------------------------------------
                                                         Queries
                                               
-----------------------------------------------------------------------------------------------------------------------------------*/
  
/*-- QUESTIONS RELATED TO CUSTOMERS
     [Q1] What is the distribution of customers across states?
     Hint: For each state, count the number of customers.*/

-- Answer: Perform the query to find the distribution of customers across state

SELECT 
	distinct state, 
    COUNT(*) OVER (PARTITION BY state) AS state_count
FROM customer_t;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q2] What is the average rating in each quarter?
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5.

Hint: Use a common table expression and in that CTE, assign numbers to the different customer ratings. 
      Now average the feedback for each quarter. 

Note: For reference, refer to question number 4. Week-2: mls_week-2_gl-beats_solution-1.sql. 
      You'll get an overview of how to use common table expressions from this question.*/

-- Answer: Perfrom sub-query to assign numeric values for customer_feeback and use CTE to find average feedback
select * from order_t;

WITH feedback_sel AS (
SELECT
		quarter_number,
		CASE WHEN customer_feedback = 'Very Bad' THEN 1
		WHEN customer_feedback = 'Bad' THEN 2
		WHEN customer_feedback = 'Okay' THEN 3
		WHEN customer_feedback = 'Good' THEN 4
		WHEN customer_feedback = 'Very Good' THEN 5
		end AS feedback
	FROM order_t)
SELECT 
	quarter_number,
    avg(feedback) AS feedback_avg
FROM feedback_sel
GROUP BY 1
ORDER BY 1;
	
-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q3] Are customers getting more dissatisfied over time?

Hint: Need the percentage of different types of customer feedback in each quarter. Use a common table expression and
	  determine the number of customer feedback in each category as well as the total number of customer feedback in each quarter.
	  Now use that common table expression to find out the percentage of different types of customer feedback in each quarter.
      Eg: (total number of very good feedback/total customer feedback)* 100 gives you the percentage of very good feedback.
      
Note: For reference, refer to question number 4. Week-2: mls_week-2_gl-beats_solution-1.sql. 
      You'll get an overview of how to use common table expressions from this question.*/
      
-- Answer: 
WITH feedback_sel AS (
SELECT
		quarter_number,
        customer_feedback,
     	CASE WHEN customer_feedback = 'Very Bad' THEN 1
		WHEN customer_feedback = 'Bad' THEN 2
		WHEN customer_feedback = 'Okay' THEN 3
		WHEN customer_feedback = 'Good' THEN 4
		WHEN customer_feedback = 'Very Good' THEN 5
		end AS feedback,
		count(*) AS feedback_count,
        sum(count(*)) OVER (PARTITION BY quarter_number) AS total_count
FROM order_t

 GROUP BY 1,2
    )
SELECT 
	fs.quarter_number,
    fs.customer_feedback,
    fs.feedback,
    fs.feedback_count,
    (fs.feedback_count * 1.0 / fs.total_count) * 100 AS feedback_percentage
FROM feedback_sel AS fs
ORDER BY 1,3;	

-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q4] Which are the top 5 vehicle makers preferred by the customer.

Hint: For each vehicle make what is the count of the customers.*/

-- Answer: Joining product_t and order_t to retrieve top 5 vehicle makers preferred by the customer
SELECT
	pt.vehicle_maker,
    COUNT(ot.product_id) AS top_5
FROM product_t AS pt 
JOIN order_t AS ot
USING(product_id)
GROUP BY vehicle_maker
ORDER BY top_5 DESC
LIMIT 5;

-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q5] What is the most preferred vehicle make in each state?

Hint: Use the window function RANK() to rank based on the count of customers for each state and vehicle maker. 
After ranking, take the vehicle maker whose rank is 1.*/

-- Answer: Rank count of customers for each state and vehicle. Use CTE with nested query in order to achieve the expected results

SELECT distinct state, vehicle_maker
FROM (
WITH cust_order AS
(
SELECT ot.customer_id, 
    pt.vehicle_maker,
    count(ot.customer_id) OVER(PARTITION BY pt.vehicle_maker) AS car_count
FROM order_t AS ot
JOIN product_t AS pt
ON ot.product_id = pt.product_id
)
SELECT 
	c.state,
	co.vehicle_maker,
	car_count,
RANK() OVER(PARTITION by c.state ORDER BY car_count DESC) as ranking
FROM cust_order AS co
JOIN customer_t AS c
ON co.customer_id = c.customer_id
ORDER BY c.state, ranking
) AS ranked_data
WHERE ranking = 1;


-- ---------------------------------------------------------------------------------------------------------------------------------

/*QUESTIONS RELATED TO REVENUE and ORDERS 

-- [Q6] What is the trend of number of orders by quarters?

Hint: Count the number of orders for each quarter.*/

-- Answer: 
SELECT
	distinct quarter_number,
    sum(quantity) OVER(PARTITION BY quarter_number) AS orders_by_quarter
FROM order_t;
    
-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q7] What is the quarter over quarter % change in revenue? 

Hint: Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
      To calculate you need to use the common table expression to find out the sum of revenue for each quarter.
      Then use that CTE along with the LAG function to calculate the QoQ percentage change in revenue.
*/

-- Asnwer: 
WITH quarter_revenue AS (
SELECT
	distinct quarter_number,
    sum(vehicle_price * quantity) AS revenue
    FROM order_t
    GROUP BY 1
    ORDER BY 1
    )
SELECT
	quarter_number,
    revenue,
    (revenue - LAG(revenue) OVER (ORDER BY quarter_number)) / LAG(revenue) OVER (ORDER BY quarter_number) * 100 AS qoq_percent_change
FROM quarter_revenue;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q8] What is the trend of revenue and orders by quarters?

Hint: Find out the sum of revenue and count the number of orders for each quarter.*/

-- Asnwer: 
SELECT
	distinct quarter_number,
    sum(vehicle_price * quantity) OVER (PARTITION BY quarter_number) AS revenue, 
    sum(quantity) OVER(PARTITION BY quarter_number) AS orders_by_quarter
FROM order_t;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?

Hint: Find out the average of discount for each credit card type.*/

-- Answer:
SELECT 
	distinct ct.credit_card_type,
	AVG(ot.discount) OVER(PARTITION BY ct.credit_card_type) AS avg_discount_per_credit_type
FROM customer_t AS ct
JOIN order_t AS ot
ON ct.customer_id = ot.customer_id;


-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the dateiff function to find the difference between the ship date and the order date.
*/

-- Answer: 
SELECT
  AVG(DATEDIFF(ship_date, order_date)) AS avg_days
FROM order_t;
 

-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------



