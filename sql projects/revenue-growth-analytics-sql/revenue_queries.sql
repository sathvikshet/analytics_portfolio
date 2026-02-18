/*
Project: Revenue & Growth Analytics using SQL
File: revenue_queries.sql
Author: Sathvik
Purpose:
Analyze revenue trends and growth metrics to understand
monthly performance, month-over-month growth, and year-over-year growth.

Assumptions:
1. Revenue includes only successful payments
2. Refunds and failed payments are excluded
3. Revenue is analyzed on a monthly basis
*/

--------------------------------------------------
-- Business Question 1:
-- How much total revenue do we generate each month?
--------------------------------------------------

WITH valid_payments AS (
    SELECT
        o.order_id,
        o.customer_id,
        p.payment_value AS revenue,
        o.order_purchase_timestamp
    FROM orders o
    JOIN payments p
        ON o.order_id = p.order_id
    WHERE p.payment_status = 'success'
),
monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', order_purchase_timestamp) AS month,
        SUM(revenue) AS total_revenue
    FROM valid_payments
    GROUP BY 1
)
SELECT
    month,
    total_revenue
FROM monthly_revenue
ORDER BY month;

-- Explanation:
-- This query shows the monthly revenue trend and helps identify
-- seasonality and overall revenue growth patterns.

--------------------------------------------------
-- Business Question 2:
-- How is revenue growing or declining compared to the previous month?
--------------------------------------------------

WITH valid_payments AS (
    SELECT
        o.order_id,
        p.payment_value AS revenue,
        o.order_purchase_timestamp
    FROM orders o
    JOIN payments p
        ON o.order_id = p.order_id
    WHERE p.payment_status = 'success'
),
monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', order_purchase_timestamp) AS month,
        SUM(revenue) AS revenue
    FROM valid_payments
    GROUP BY 1
)
SELECT
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS previous_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month))
        / NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100,
        2
    ) AS mom_growth_percentage
FROM monthly_revenue
ORDER BY month;

-- Explanation:
-- This query calculates month-over-month (MoM) revenue growth.
-- It helps founders understand acceleration or slowdown in revenue.

--------------------------------------------------
-- Business Question 3:
-- How does this month’s revenue compare with the same month last year?
--------------------------------------------------

WITH valid_payments AS (
    SELECT
        o.order_id,
        p.payment_value AS revenue,
        o.order_purchase_timestamp
    FROM orders o
    JOIN payments p
        ON o.order_id = p.order_id
    WHERE p.payment_status = 'success'
),
monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', order_purchase_timestamp) AS month,
        SUM(revenue) AS revenue
    FROM valid_payments
    GROUP BY 1
)
SELECT
    month,
    revenue,
    LAG(revenue, 12) OVER (ORDER BY month) AS last_year_revenue,
    ROUND(
        (revenue - LAG(revenue, 12) OVER (ORDER BY month))
        / NULLIF(LAG(revenue, 12) OVER (ORDER BY month), 0) * 100,
        2
    ) AS yoy_growth_percentage
FROM monthly_revenue
ORDER BY month;

-- Explanation:
-- This query measures year-over-year (YoY) revenue growth.
-- It helps evaluate long-term business growth while removing seasonality effects.
