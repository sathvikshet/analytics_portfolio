/*
Project: Revenue & Growth Analytics using SQL
File: leakage_analysis.sql
Author: Sathvik
Purpose:
Analyze revenue leakage caused by failed and refunded payments
to understand gaps between gross and net revenue.

Assumptions:
1. Gross revenue includes all payment attempts
2. Net revenue includes only successful payments
3. Refunds and failed payments represent revenue leakage
*/

--------------------------------------------------
-- Business Question 1:
-- How much gross revenue vs net revenue do we generate each month?
--------------------------------------------------

WITH payment_summary AS (
    SELECT
        o.order_id,
        o.customer_id,
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        p.payment_status,
        p.payment_value
    FROM orders o
    JOIN payments p
        ON o.order_id = p.order_id
)
SELECT
    month,
    ROUND(SUM(payment_value), 2) AS gross_revenue,
    ROUND(
        SUM(
            CASE
                WHEN payment_status = 'success' THEN payment_value
                ELSE 0
            END
        ), 2
    ) AS net_revenue
FROM payment_summary
GROUP BY month
ORDER BY month;

-- Explanation:
-- Compares total attempted revenue with successfully captured revenue.
-- Highlights the overall gap caused by payment issues.

--------------------------------------------------
-- Business Question 2:
-- How many refunds occur each month and how much revenue is refunded?
--------------------------------------------------

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    COUNT(*) AS refund_count,
    ROUND(SUM(p.payment_value), 2) AS refund_amount
FROM orders o
JOIN payments p
    ON o.order_id = p.order_id
WHERE p.payment_status = 'refunded'
GROUP BY month
ORDER BY month;

-- Explanation:
-- Measures revenue loss due to refunds.
-- Useful for identifying issues related to returns, disputes, or fraud.

--------------------------------------------------
-- Business Question 3:
-- How much revenue is lost due to failed payments?
--------------------------------------------------

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    COUNT(*) AS failed_payment_count,
    ROUND(SUM(p.payment_value), 2) AS failed_payment_value
FROM orders o
JOIN payments p
    ON o.order_id = p.order_id
WHERE p.payment_status = 'failed'
GROUP BY month
ORDER BY month;

-- Explanation:
-- Captures revenue loss from unsuccessful payment attempts.
-- Indicates potential problems with payment gateways or user experience.

--------------------------------------------------
-- Business Question 4:
-- What percentage of gross revenue is lost due to payment failures and refunds?
--------------------------------------------------

WITH monthly_payments AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        SUM(p.payment_value) AS gross_revenue,
        SUM(
            CASE
                WHEN p.payment_status = 'success' THEN p.payment_value
                ELSE 0
            END
        ) AS net_revenue
    FROM orders o
    JOIN payments p
        ON o.order_id = p.order_id
    GROUP BY month
)
SELECT
    month,
    ROUND(gross_revenue, 2) AS gross_revenue,
    ROUND(net_revenue, 2) AS net_revenue,
    ROUND(
        (gross_revenue - net_revenue)
        / NULLIF(gross_revenue, 0) * 100,
        2
    ) AS leakage_percentage
FROM monthly_payments
ORDER BY month;

-- Explanation:
-- Quantifies revenue leakage as a percentage of gross revenue.
-- Helps founders prioritize fixes in payment processing and refunds.
