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
FROM customer_t 
ORDER BY state_count DESC;

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
WITH feedback_final AS (
SELECT  quarter_number,
	    SUM(CASE WHEN customer_feedback = 'Very Good' then 1 ELSE 0 END) AS very_good,
        SUM(CASE WHEN customer_feedback = 'Good' then 1 ELSE 0 END) AS good,
        SUM(CASE WHEN customer_feedback = 'Okay' then 1 ELSE 0 END) AS okay,
        SUM(CASE WHEN customer_feedback = 'Bad' then 1 ELSE 0 END) AS bad,
        SUM(CASE WHEN customer_feedback = 'Very BAD' then 1 ELSE 0 END) AS very_bad,
        COUNT(customer_feedback) AS total_feedback
FROM order_t
GROUP BY 1)

SELECT quarter_number,
	   100*(very_good/total_feedback) AS per_ver_good,
       100*(good/total_feedback) AS per_good,
       100*(okay/total_feedback) AS per_okay,
       100*(bad/total_feedback) AS per_bad,
       100*(very_bad/total_feedback) AS per_very_bad
FROM feedback_final
ORDER BY 1;



-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q4] Which are the top 5 vehicle makers preferred by the customer.

Hint: For each vehicle make what is the count of the customers.*/

-- Answer: Joining product_t and order_t to retrieve top 5 vehicle makers preferred by the customer
SELECT
	pt.vehicle_maker,
    COUNT(ot.product_id) AS top_5
FROM product_t AS pt 
INNER JOIN order_t AS ot
USING(product_id)
GROUP BY vehicle_maker
ORDER BY top_5 DESC
LIMIT 5;

-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q5] What is the most preferred vehicle make in each state?

Hint: Use the window function RANK() to rank based on the count of customers for each state and vehicle maker. 
After ranking, take the vehicle maker whose rank is 1.*/

-- Answer: Rank count of customers for each state and vehicle. Use CTE with nested query in order to achieve the expected results

WITH final AS (
SELECT C.state,
	   P.vehicle_maker,
       COUNT(C.customer_id) AS cnt_cust
FROM customer_t C 
INNER JOIN order_t O
ON C.customer_id = O.customer_id
INNER JOIN product_t P
ON O.product_id =P.product_id

GROUP BY 1,2),
final_rank AS (
SELECT *, DENSE_RANK() OVER( PARTITION BY STATE ORDER BY CNT_CUST DESC) AS drnk
FROM final)

SELECT state, 
	   vehicle_maker,
	   cnt_cust,
       drnk
FROM final_rank
WHERE drnk = 1;


-- ---------------------------------------------------------------------------------------------------------------------------------

/*QUESTIONS RELATED TO REVENUE and ORDERS 

-- [Q6] What is the trend of number of orders by quarters?

Hint: Count the number of orders for each quarter.*/

-- Answer: 
SELECT
	distinct quarter_number,
    count(quantity) OVER(PARTITION BY quarter_number) AS orders_by_quarter
FROM order_t;

    
-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q7] What is the quarter over quarter % change in revenue? 

Hint: Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
      To calculate you need to use the common table expression to find out the sum of revenue for each quarter.
      Then use that CTE along with the LAG function to calculate the QoQ percentage change in revenue.
*/

-- Asnwer: 
WITH quarter_rev AS (
SELECT quarter_number,
	   SUM(quantity *(vehicle_price - ((discount/100)*vehicle_price))) AS total_revenue
FROM order_t
GROUP BY 1
ORDER BY 1   )

SELECT *, 100*((total_revenue - LAG(total_revenue) OVER(ORDER BY quarter_number)))/(LAG(total_revenue)OVER(ORDER BY quarter_number)) AS perc_qoq
FROM  quarter_rev;  

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q8] What is the trend of revenue and orders by quarters?

Hint: Find out the sum of revenue and count the number of orders for each quarter.*/

-- Asnwer: 
SELECT quarter_number,
	   SUM(quantity *(vehicle_price - ((discount/100)*vehicle_price))) AS total_revenue,
       COUNT(order_id) AS total_orders
FROM order_t
GROUP BY 1
ORDER BY 1;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?

Hint: Find out the average of discount for each credit card type.*/

-- Answer:
SELECT 
	distinct ct.credit_card_type,
	AVG(ot.discount) OVER(PARTITION BY ct.credit_card_type) AS avg_discount_per_credit_type
FROM customer_t AS ct
INNER JOIN order_t AS ot
ON ct.customer_id = ot.customer_id
ORDER BY 2 DESC;


-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the dateiff function to find the difference between the ship date and the order date.
*/

-- Answer: 
SELECT
	distinct quarter_number,
  AVG(DATEDIFF(ship_date, order_date)) OVER (PARTITION BY quarter_number) AS avg_ship_days
FROM order_t;

 


-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------



