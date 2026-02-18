/*
Project: Experimentation & Business Impact Analytics using SQL
File: retention_comparision.sql
Author: Sathvik
Purpose:
Compare retention performance between experiment variants
to understand long-term impact beyond conversion and revenue.

Assumptions:
1. User is considered retained if active in the last 30 days
2. event_time represents user activity timestamp
3. Each user belongs to only one experiment variant
*/

--------------------------------------------------
-- Business Question 1:
-- When was each user last active on the platform?
--------------------------------------------------

WITH last_activity AS (
    SELECT
        user_id,
        MAX(event_time) AS last_seen
    FROM events
    GROUP BY user_id
)
SELECT
    user_id,
    last_seen
FROM last_activity
ORDER BY last_seen DESC;

-- Explanation:
-- Captures the most recent activity per user.
-- Used to determine retention status.

--------------------------------------------------
-- Business Question 2:
-- How many users are retained in each experiment variant?
--------------------------------------------------

WITH last_activity AS (
    SELECT
        user_id,
        MAX(event_time) AS last_seen
    FROM events
    GROUP BY user_id
),
experiment_users AS (
    SELECT DISTINCT
        user_id,
        variant
    FROM experiments
)
SELECT
    e.variant,
    COUNT(DISTINCT e.user_id) AS total_users,
    COUNT(DISTINCT e.user_id) FILTER (
        WHERE la.last_seen >= CURRENT_DATE - INTERVAL '30 days'
    ) AS retained_users
FROM experiment_users e
JOIN last_activity la
    ON e.user_id = la.user_id
GROUP BY e.variant
ORDER BY e.variant;

-- Explanation:
-- Measures retained users per variant using a 30-day activity window.
-- Helps compare engagement sustainability.

--------------------------------------------------
-- Business Question 3:
-- What is the retention rate for each variant?
--------------------------------------------------

WITH last_activity AS (
    SELECT
        user_id,
        MAX(event_time) AS last_seen
    FROM events
    GROUP BY user_id
),
experiment_users AS (
    SELECT DISTINCT
        user_id,
        variant
    FROM experiments
),
retention_stats AS (
    SELECT
        e.variant,
        COUNT(DISTINCT e.user_id) AS total_users,
        COUNT(DISTINCT e.user_id) FILTER (
            WHERE la.last_seen >= CURRENT_DATE - INTERVAL '30 days'
        ) AS retained_users
    FROM experiment_users e
    JOIN last_activity la
        ON e.user_id = la.user_id
    GROUP BY e.variant
)
SELECT
    variant,
    total_users,
    retained_users,
    ROUND(
        retained_users * 100.0 /
        NULLIF(total_users, 0),
        2
    ) AS retention_rate_pct
FROM retention_stats
ORDER BY retention_rate_pct DESC;

-- Explanation:
-- Converts retained user counts into retention percentages.
-- Retention rate is a core metric for experiment success.

--------------------------------------------------
-- Business Question 4:
-- What is the retention uplift of Variant B compared to Variant A?
--------------------------------------------------

WITH retention_rates AS (
    SELECT
        e.variant,
        COUNT(DISTINCT e.user_id) FILTER (
            WHERE la.last_seen >= CURRENT_DATE - INTERVAL '30 days'
        ) * 1.0 /
        COUNT(DISTINCT e.user_id) AS retention_rate
    FROM experiments e
    JOIN (
        SELECT
            user_id,
            MAX(event_time) AS last_seen
        FROM events
        GROUP BY user_id
    ) la
        ON e.user_id = la.user_id
    GROUP BY e.variant
)
SELECT
    MAX(CASE WHEN variant = 'B' THEN retention_rate END)
    - MAX(CASE WHEN variant = 'A' THEN retention_rate END)
    AS absolute_retention_lift,
    ROUND(
        (
            MAX(CASE WHEN variant = 'B' THEN retention_rate END)
            - MAX(CASE WHEN variant = 'A' THEN retention_rate END)
        ) /
        NULLIF(MAX(CASE WHEN variant = 'A' THEN retention_rate END), 0)
        * 100,
        2
    ) AS relative_retention_lift_pct
FROM retention_rates;

-- Explanation:
-- Measures retention improvement of Variant B over Variant A.
-- This shows whether the experiment creates lasting value,
-- not just short-term conversion gains.
