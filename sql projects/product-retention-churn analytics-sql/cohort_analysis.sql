/*
Project: Product, Retention & Churn Analytics using SQL
File: cohort_analysis.sql
Author: Sathvik
Purpose:
Analyze user retention using cohort analysis based on
signup month and subsequent monthly activity.

Assumptions:
1. signup_date represents the user’s first registration date
2. event_time represents user activity after signup
3. Retention is measured monthly
*/

--------------------------------------------------
-- Business Question 1:
-- What is the signup cohort (month) for each user?
--------------------------------------------------

WITH signup_cohort AS (
    SELECT
        user_id,
        DATE_TRUNC('month', signup_date) AS cohort_month
    FROM users
)
SELECT
    user_id,
    cohort_month
FROM signup_cohort
ORDER BY cohort_month, user_id;

-- Explanation:
-- Assigns each user to a cohort based on their signup month.
-- This cohort acts as the baseline for retention analysis.

--------------------------------------------------
-- Business Question 2:
-- In which months are users active after signup?
--------------------------------------------------

WITH monthly_activity AS (
    SELECT DISTINCT
        user_id,
        DATE_TRUNC('month', event_time) AS activity_month
    FROM events
)
SELECT
    user_id,
    activity_month
FROM monthly_activity
ORDER BY activity_month, user_id;

-- Explanation:
-- Captures user activity at a monthly level.
-- Used to measure whether users return after signup.

--------------------------------------------------
-- Business Question 3:
-- How many users from each cohort return in subsequent months?
--------------------------------------------------

WITH signup_cohort AS (
    SELECT
        user_id,
        DATE_TRUNC('month', signup_date) AS cohort_month
    FROM users
),
monthly_activity AS (
    SELECT DISTINCT
        user_id,
        DATE_TRUNC('month', event_time) AS activity_month
    FROM events
)
SELECT
    s.cohort_month,
    EXTRACT(
        MONTH FROM AGE(a.activity_month, s.cohort_month)
    ) AS cohort_age_month,
    COUNT(DISTINCT a.user_id) AS retained_users
FROM signup_cohort s
JOIN monthly_activity a
  ON s.user_id = a.user_id
GROUP BY 1, 2
ORDER BY 1, 2;

-- Explanation:
-- Measures how many users remain active as the cohort ages.
-- Helps identify drop-off patterns after signup.

--------------------------------------------------
-- Business Question 4:
-- What percentage of each cohort is retained over time?
--------------------------------------------------

WITH signup_cohort AS (
    SELECT
        user_id,
        DATE_TRUNC('month', signup_date) AS cohort_month
    FROM users
),
monthly_activity AS (
    SELECT DISTINCT
        user_id,
        DATE_TRUNC('month', event_time) AS activity_month
    FROM events
),
cohort_data AS (
    SELECT
        s.cohort_month,
        EXTRACT(
            MONTH FROM AGE(a.activity_month, s.cohort_month)
        ) AS cohort_age,
        COUNT(DISTINCT a.user_id) AS retained_users
    FROM signup_cohort s
    JOIN monthly_activity a
      ON s.user_id = a.user_id
    GROUP BY 1, 2
),
cohort_size AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT user_id) AS cohort_users
    FROM signup_cohort
    GROUP BY cohort_month
)
SELECT
    c.cohort_month,
    c.cohort_age,
    ROUND(
        c.retained_users * 100.0 / cs.cohort_users,
        2
    ) AS retention_pct
FROM cohort_data c
JOIN cohort_size cs
  ON c.cohort_month = cs.cohort_month
ORDER BY 1, 2;

-- Explanation:
-- Converts retained user counts into retention percentages.
-- This is the standard output used in cohort retention tables.
