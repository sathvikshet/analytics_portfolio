/*
Project: Product, Retention & Churn Analytics using SQL
File: activity_metrics.sql
Author: Sathvik
Purpose:
Analyze user activity metrics to understand engagement levels
using DAU, WAU, MAU, and DAU/MAU ratio.

Assumptions:
1. Each row in events represents a user interaction
2. event_time indicates when the activity occurred
3. Active user = user with at least one event in the time period
*/

--------------------------------------------------
-- Business Question 1:
-- What does the base daily activity data look like?
--------------------------------------------------

WITH daily_activity AS (
    SELECT DISTINCT
        user_id,
        DATE(event_time) AS activity_date
    FROM events
)
SELECT
    user_id,
    activity_date
FROM daily_activity
ORDER BY activity_date, user_id;

-- Explanation:
-- Creates a clean base table with one row per user per day.
-- Used as a foundation for daily activity metrics.

--------------------------------------------------
-- Business Question 2:
-- How many daily active users (DAU) do we have each day?
--------------------------------------------------

WITH daily_activity AS (
    SELECT DISTINCT
        user_id,
        DATE(event_time) AS activity_date
    FROM events
)
SELECT
    activity_date,
    COUNT(DISTINCT user_id) AS dau
FROM daily_activity
GROUP BY activity_date
ORDER BY activity_date;

-- Explanation:
-- Measures daily user engagement.
-- Helps track short-term usage patterns and spikes.

--------------------------------------------------
-- Business Question 3:
-- How many weekly active users (WAU) do we have?
--------------------------------------------------

WITH weekly_activity AS (
    SELECT DISTINCT
        user_id,
        DATE_TRUNC('week', event_time) AS week
    FROM events
)
SELECT
    week,
    COUNT(DISTINCT user_id) AS wau
FROM weekly_activity
GROUP BY week
ORDER BY week;

-- Explanation:
-- Measures engagement at a weekly level.
-- Smooths out daily fluctuations in usage.

--------------------------------------------------
-- Business Question 4:
-- How many monthly active users (MAU) do we have?
--------------------------------------------------

WITH monthly_activity AS (
    SELECT DISTINCT
        user_id,
        DATE_TRUNC('month', event_time) AS month
    FROM events
)
SELECT
    month,
    COUNT(DISTINCT user_id) AS mau
FROM monthly_activity
GROUP BY month
ORDER BY month;

-- Explanation:
-- Measures long-term engagement.
-- Commonly used as a core product health metric.

--------------------------------------------------
-- Business Question 5:
-- How engaged are users relative to the monthly active base (DAU/MAU)?
--------------------------------------------------

WITH dau AS (
    SELECT
        DATE(event_time) AS day,
        COUNT(DISTINCT user_id) AS dau
    FROM events
    GROUP BY day
),
mau AS (
    SELECT
        DATE_TRUNC('month', event_time) AS month,
        COUNT(DISTINCT user_id) AS mau
    FROM events
    GROUP BY month
)
SELECT
    d.day,
    d.dau,
    m.mau,
    ROUND(
        d.dau * 1.0 / NULLIF(m.mau, 0),
        3
    ) AS dau_mau_ratio
FROM dau d
JOIN mau m
  ON DATE_TRUNC('month', d.day) = m.month
ORDER BY d.day;

-- Explanation:
-- DAU/MAU ratio indicates stickiness of the product.
-- Higher values mean users return more frequently.
