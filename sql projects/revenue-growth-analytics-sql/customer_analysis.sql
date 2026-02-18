/*
Project: Revenue & Growth Analytics using SQL
File: customer_analysis.sql
Author: Sathvik
Purpose:
Analyze customer value, spending behavior, and revenue risk
to support retention and growth decisions.

Assumptions:
1. Revenue includes only successful payments
2. Each customer_id uniquely identifies a customer
3. Revenue is aggregated at monthly and lifetime levels
*/

--------------------------------------------------
-- Business Question 1:
-- On average, how much revenue does each customer generate?
--------------------------------------------------

WITH valid_payments AS (
    SELECT
        o.customer_id,
        p.payment_value AS revenue
    FROM orders o
    JOIN payments p
        ON o.order_id = p.order_id
    WHERE p.payment_status = 'success'
)
SELECT
    ROUND(SUM(revenue) / COUNT(DISTINCT customer_id), 2) AS arpu
FROM valid_payments;

-- Explanation:
-- Calculates Average Revenue Per User (ARPU).
-- Helps understand overall customer monetization level.

--------------------------------------------------
-- Business Question 2:
-- How does average revenue per customer change month by month?
--------------------------------------------------

WITH valid_payments AS (
    SELECT
        o.customer_id,
        p.payment_value AS revenue,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month
    FROM orders o
    JOIN payments p
        ON o.order_id = p.order_id
    WHERE p.payment_status = 'success'
)
SELECT
    month,
    ROUND(SUM(revenue) / COUNT(DISTINCT customer_id), 2) AS arpu
FROM valid_payments
GROUP BY month
ORDER BY month;

-- Explanation:
-- Tracks ARPU trends over time.
-- Useful for identifying improvements or drops in customer value.

--------------------------------------------------
-- Business Question 3:
-- How much total revenue has each customer generated over their lifetime?
--------------------------------------------------

WITH customer_revenue AS (
    SELECT
        o.customer_id,
        SUM(p.payment_value) AS lifetime_revenue
    FROM orders o
    JOIN payments p
        ON o.order_id = p.order_id
    WHERE p.payment_status = 'success'
    GROUP BY o.customer_id
)
SELECT
    customer_id,
    ROUND(lifetime_revenue, 2) AS lifetime_revenue
FROM customer_revenue
ORDER BY lifetime_revenue DESC;

-- Explanation:
-- Identifies high-value customers based on lifetime contribution.
-- Helps prioritize retention and loyalty programs.

--------------------------------------------------
-- Business Question 4:
-- How is revenue distributed across different customer value segments?
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
        NTILE(5) OVER (ORDER BY total_revenue DESC) AS revenue_bucket
    FROM customer_revenue
)
SELECT
    revenue_bucket,
    COUNT(customer_id) AS customer_count,
    ROUND(SUM(total_revenue), 2) AS revenue_generated
FROM ranked_customers
GROUP BY revenue_bucket
ORDER BY revenue_bucket;

-- Explanation:
-- Segments customers into revenue-based tiers.
-- Helps compare top vs low-value customer groups.

--------------------------------------------------
-- Business Question 5:
-- How much does each customer spend every month?
--------------------------------------------------

WITH monthly_customer_spend AS (
    SELECT
        o.customer_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        SUM(p.payment_value) AS monthly_revenue
    FROM orders o
    JOIN payments p
        ON o.order_id = p.order_id
    WHERE p.payment_status = 'success'
    GROUP BY o.customer_id, month
)
SELECT
    customer_id,
    month,
    monthly_revenue
FROM monthly_customer_spend
ORDER BY customer_id, month;

-- Explanation:
-- Shows individual customer spending patterns over time.
-- Used as a base for identifying behavior changes.

--------------------------------------------------
-- Business Question 6:
-- Which customers show a decline in spending compared to the previous month?
--------------------------------------------------

WITH monthly_customer_spend AS (
    SELECT
        o.customer_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        SUM(p.payment_value) AS revenue
    FROM orders o
    JOIN payments p
        ON o.order_id = p.order_id
    WHERE p.payment_status = 'success'
    GROUP BY o.customer_id, month
),
spend_trend AS (
    SELECT
        customer_id,
        month,
        revenue,
        LAG(revenue) OVER (
            PARTITION BY customer_id
            ORDER BY month
        ) AS prev_month_revenue
    FROM monthly_customer_spend
)
SELECT
    customer_id,
    month,
    revenue,
    prev_month_revenue,
    ROUND(
        (revenue - prev_month_revenue)
        / NULLIF(prev_month_revenue, 0) * 100,
        2
    ) AS revenue_change_pct
FROM spend_trend
WHERE prev_month_revenue IS NOT NULL
  AND revenue < prev_month_revenue
ORDER BY revenue_change_pct;

-- Explanation:
-- Detects customers with declining monthly spend.
-- These customers may be at risk of churn.

--------------------------------------------------
-- Business Question 7:
-- Which customers show repeated decline in spending over multiple months?
--------------------------------------------------

WITH monthly_customer_spend AS (
    SELECT
        o.customer_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        SUM(p.payment_value) AS revenue
    FROM orders o
    JOIN payments p
        ON o.order_id = p.order_id
    WHERE p.payment_status = 'success'
    GROUP BY o.customer_id, month
),
spend_trend AS (
    SELECT
        customer_id,
        month,
        revenue,
        LAG(revenue) OVER (
            PARTITION BY customer_id
            ORDER BY month
        ) AS prev_revenue
    FROM monthly_customer_spend
),
risk_flag AS (
    SELECT
        customer_id,
        COUNT(*) AS declining_months
    FROM spend_trend
    WHERE revenue < prev_revenue
    GROUP BY customer_id
)
SELECT
    customer_id,
    declining_months
FROM risk_flag
WHERE declining_months >= 2
ORDER BY declining_months DESC;

-- Explanation:
-- Flags high-risk customers with consistent spending decline.
-- Useful for proactive retention strategies.

--------------------------------------------------
-- Business Question 8:
-- How much total revenue is at risk due to declining customer behavior?
--------------------------------------------------

WITH customer_lifetime AS (
    SELECT
        o.customer_id,
        SUM(p.payment_value) AS lifetime_revenue
    FROM orders o
    JOIN payments p
        ON o.order_id = p.order_id
    WHERE p.payment_status = 'success'
    GROUP BY o.customer_id
),
high_risk_customers AS (
    SELECT DISTINCT customer_id
    FROM (
        SELECT
            customer_id,
            COUNT(*) AS declining_months
        FROM (
            SELECT
                o.customer_id,
                DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
                SUM(p.payment_value) AS revenue,
                LAG(SUM(p.payment_value)) OVER (
                    PARTITION BY o.customer_id
                    ORDER BY DATE_TRUNC('month', o.order_purchase_timestamp)
                ) AS prev_revenue
            FROM orders o
            JOIN payments p
                ON o.order_id = p.order_id
            WHERE p.payment_status = 'success'
            GROUP BY o.customer_id, month
        ) t
        WHERE revenue < prev_revenue
        GROUP BY customer_id
        HAVING COUNT(*) >= 2
    ) risky
)
SELECT
    ROUND(SUM(cl.lifetime_revenue), 2) AS revenue_at_risk
FROM customer_lifetime cl
JOIN high_risk_customers h
    ON cl.customer_id = h.customer_id;

-- Explanation:
-- Estimates total revenue exposed to potential churn.
-- Helps founders quantify financial impact of customer decline.
