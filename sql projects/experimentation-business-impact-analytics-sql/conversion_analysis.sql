/*
Project: Experimentation & Business Impact Analytics using SQL
File: conversion_analysis.sql
Author: Sathvik
Purpose:
Measure conversion performance of experiment variants,
calculate conversion rates, and quantify uplift between variants.

Assumptions:
1. Conversion is defined as a successful payment
2. payment_status = 'success' indicates conversion
3. Each user belongs to only one experiment variant
*/

--------------------------------------------------
-- Business Question 1:
-- Which users are part of each experiment variant?
--------------------------------------------------

WITH experiment_users AS (
    SELECT DISTINCT
        user_id,
        variant
    FROM experiments
)
SELECT
    user_id,
    variant
FROM experiment_users
ORDER BY variant, user_id;

-- Explanation:
-- Establishes the experiment population.
-- Acts as the base dataset for conversion analysis.

--------------------------------------------------
-- Business Question 2:
-- Which users successfully converted (made a payment)?
--------------------------------------------------

WITH converted_users AS (
    SELECT DISTINCT
        o.customer_id AS user_id
    FROM orders o
    JOIN payments p
        ON o.order_id = p.order_id
    WHERE p.payment_status = 'success'
)
SELECT
    user_id
FROM converted_users;

-- Explanation:
-- Identifies users who completed a successful conversion.
-- Conversion is defined as a completed payment.

--------------------------------------------------
-- Business Question 3:
-- How many users converted in each experiment variant?
--------------------------------------------------

WITH experiment_users AS (
    SELECT DISTINCT
        user_id,
        variant
    FROM experiments
),
converted_users AS (
    SELECT DISTINCT
        o.customer_id AS user_id
    FROM orders o
    JOIN payments p
        ON o.order_id = p.order_id
    WHERE p.payment_status = 'success'
)
SELECT
    e.variant,
    COUNT(DISTINCT e.user_id) AS total_users,
    COUNT(DISTINCT c.user_id) AS converted_users
FROM experiment_users e
LEFT JOIN converted_users c
    ON e.user_id = c.user_id
GROUP BY e.variant
ORDER BY e.variant;

-- Explanation:
-- Provides absolute conversion counts per variant.
-- Useful for sanity checks before calculating rates.

--------------------------------------------------
-- Business Question 4:
-- What is the conversion rate for each variant?
--------------------------------------------------

WITH experiment_users AS (
    SELECT DISTINCT
        user_id,
        variant
    FROM experiments
),
converted_users AS (
    SELECT DISTINCT
        o.customer_id AS user_id
    FROM orders o
    JOIN payments p
        ON o.order_id = p.order_id
    WHERE p.payment_status = 'success'
),
variant_stats AS (
    SELECT
        e.variant,
        COUNT(DISTINCT e.user_id) AS total_users,
        COUNT(DISTINCT c.user_id) AS converted_users
    FROM experiment_users e
    LEFT JOIN converted_users c
        ON e.user_id = c.user_id
    GROUP BY e.variant
)
SELECT
    variant,
    total_users,
    converted_users,
    ROUND(
        converted_users * 100.0 /
        NULLIF(total_users, 0),
        2
    ) AS conversion_rate_pct
FROM variant_stats
ORDER BY conversion_rate_pct DESC;

-- Explanation:
-- Calculates conversion rate per variant.
-- Primary metric used to compare experiment performance.

--------------------------------------------------
-- Business Question 5:
-- What is the conversion uplift of Variant B vs Variant A?
--------------------------------------------------

WITH conversion_rates AS (
    SELECT
        e.variant,
        ROUND(
            COUNT(DISTINCT o.customer_id) * 100.0 /
            NULLIF(COUNT(DISTINCT e.user_id), 0),
            2
        ) AS conversion_rate
    FROM experiments e
    LEFT JOIN orders o
        ON e.user_id = o.customer_id
    LEFT JOIN payments p
        ON o.order_id = p.order_id
       AND p.payment_status = 'success'
    GROUP BY e.variant
)
SELECT
    MAX(CASE WHEN variant = 'B' THEN conversion_rate END)
    - MAX(CASE WHEN variant = 'A' THEN conversion_rate END)
    AS absolute_lift_pct,
    ROUND(
        (
            MAX(CASE WHEN variant = 'B' THEN conversion_rate END)
            - MAX(CASE WHEN variant = 'A' THEN conversion_rate END)
        ) /
        NULLIF(MAX(CASE WHEN variant = 'A' THEN conversion_rate END), 0)
        * 100,
        2
    ) AS relative_lift_pct
FROM conversion_rates;

-- Explanation:
-- Measures absolute and relative uplift of Variant B over Variant A.
-- Quantifies the true impact of the experiment on conversions.
