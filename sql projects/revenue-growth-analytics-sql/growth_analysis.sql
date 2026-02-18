/*
Project: Revenue & Growth Analytics using SQL
File: growth_analysis.sql
Author: Sathvik
Purpose:
Analyze where revenue is coming from by geography, product,
and customers, and understand revenue concentration patterns.

Assumptions:
1. Revenue includes only successful payments
2. Refunds and failed payments are excluded
3. Each payment represents completed revenue
*/

--------------------------------------------------
-- Business Question 1:
-- Which countries generate the highest total revenue?
--------------------------------------------------

WITH valid_payments AS (
    SELECT
        o.order_id,
        o.customer_id,
        c.customer_state AS country,
        p.payment_value AS revenue
    FROM orders o
    JOIN payments p
        ON o.order_id = p.order_id
    JOIN customers c
        ON o.customer_id = c.customer_id
    WHERE p.payment_status = 'success'
)
SELECT
    country,
    ROUND(SUM(revenue), 2) AS total_revenue
FROM valid_payments
GROUP BY country
ORDER BY total_revenue DESC;

-- Explanation:
-- Identifies top-performing geographic regions.
-- Helps prioritize markets for growth and marketing spend.

--------------------------------------------------
-- Business Question 2:
-- Which products contribute the most to total revenue?
--------------------------------------------------

WITH valid_payments AS (
    SELECT
        o.order_id,
        oi.product_id,
        p.payment_value AS revenue
    FROM orders o
    JOIN payments p
        ON o.order_id = p.order_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE p.payment_status = 'success'
)
SELECT
    product_id,
    ROUND(SUM(revenue), 2) AS total_revenue
FROM valid_payments
GROUP BY product_id
ORDER BY total_revenue DESC;

-- Explanation:
-- Highlights high-revenue products.
-- Useful for inventory planning, pricing, and promotions.

--------------------------------------------------
-- Business Question 3:
-- Which customers generate the highest total revenue?
--------------------------------------------------

WITH customer_revenue AS (
    SELECT
        o.customer_id,
        SUM(p.payment_value) AS total_revenue
    FROM orders o
    JOIN payments p
        ON o.order_id = p.order_id
    WHERE p.payment_status = 'success'
    GROUP BY o.customer_id
)
SELECT
    customer_id,
    ROUND(total_revenue, 2) AS total_revenue
FROM customer_revenue
ORDER BY total_revenue DESC;

-- Explanation:
-- Identifies high-value customers.
-- Helps focus retention and loyalty efforts on top contributors.

--------------------------------------------------
-- Business Question 4:
-- What percentage of total revenue comes from top customers?
--------------------------------------------------

WITH customer_revenue AS (
    SELECT
        o.customer_id,
        SUM(p.payment_value) AS total_revenue
    FROM orders o
    JOIN payments p
        ON o.order_id = p.order_id
    WHERE p.payment_status = 'success'
    GROUP BY o.customer_id
),
ranked_customers AS (
    SELECT
        customer_id,
        total_revenue,
        SUM(total_revenue) OVER () AS overall_revenue,
        SUM(total_revenue) OVER (
            ORDER BY total_revenue DESC
        ) AS cumulative_revenue
    FROM customer_revenue
)
SELECT
    customer_id,
    ROUND(total_revenue, 2) AS total_revenue,
    ROUND(cumulative_revenue / overall_revenue * 100, 2) AS cumulative_revenue_pct
FROM ranked_customers
ORDER BY total_revenue DESC;

-- Explanation:
-- Shows revenue concentration using cumulative contribution.
-- Helps assess dependency risk on a small group of customers.
