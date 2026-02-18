/*
Project: Product, Retention & Churn Analytics using SQL
File: feature_adoption.sql
Author: Sathvik
Purpose:
Analyze feature adoption and understand how feature usage
relates to user retention and churn.

Assumptions:
1. event_name represents a product feature or action
2. Each event row indicates usage of a feature by a user
3. Users inactive for more than 30 days are considered churned
*/

--------------------------------------------------
-- Business Question 1:
-- Which features are used the most across all users?
--------------------------------------------------

SELECT
    event_name AS feature_name,
    COUNT(DISTINCT user_id) AS users_using_feature
FROM events
GROUP BY event_name
ORDER BY users_using_feature DESC;

-- Explanation:
-- Shows overall feature popularity.
-- Helps identify core vs rarely used features.

--------------------------------------------------
-- Business Question 2:
-- What percentage of users have adopted each feature?
--------------------------------------------------

WITH total_users AS (
    SELECT
        COUNT(DISTINCT user_id) AS total_users
    FROM users
)
SELECT
    e.event_name AS feature_name,
    COUNT(DISTINCT e.user_id) AS users_using_feature,
    ROUND(
        COUNT(DISTINCT e.user_id) * 100.0 / t.total_users,
        2
    ) AS adoption_pct
FROM events e
CROSS JOIN total_users t
GROUP BY e.event_name, t.total_users
ORDER BY adoption_pct DESC;

-- Explanation:
-- Converts raw usage counts into adoption percentages.
-- Makes it easier to compare features fairly.

--------------------------------------------------
-- Business Question 3:
-- Which users are considered churned based on inactivity?
--------------------------------------------------

WITH churned_users AS (
    SELECT
        user_id
    FROM (
        SELECT
            user_id,
            MAX(event_time) AS last_seen
        FROM events
        GROUP BY user_id
    ) t
    WHERE last_seen < CURRENT_DATE - INTERVAL '30 days'
)
SELECT
    user_id
FROM churned_users;

-- Explanation:
-- Identifies churned users using inactivity-based definition.
-- Used to link feature usage with churn outcomes.

--------------------------------------------------
-- Business Question 4:
-- How does feature usage differ between retained and churned users?
--------------------------------------------------

WITH churned_users AS (
    SELECT
        user_id
    FROM (
        SELECT
            user_id,
            MAX(event_time) AS last_seen
        FROM events
        GROUP BY user_id
    ) t
    WHERE last_seen < CURRENT_DATE - INTERVAL '30 days'
)
SELECT
    e.event_name AS feature_name,
    COUNT(DISTINCT e.user_id) FILTER (
        WHERE cu.user_id IS NULL
    ) AS retained_users_using_feature,
    COUNT(DISTINCT e.user_id) FILTER (
        WHERE cu.user_id IS NOT NULL
    ) AS churned_users_using_feature
FROM events e
LEFT JOIN churned_users cu
    ON e.user_id = cu.user_id
GROUP BY e.event_name
ORDER BY retained_users_using_feature DESC;

-- Explanation:
-- Compares feature usage between retained and churned users.
-- Helps identify features associated with long-term retention.

--------------------------------------------------
-- Business Question 5:
-- Which features have the highest retention impact?
--------------------------------------------------

WITH churned_users AS (
    SELECT
        user_id
    FROM (
        SELECT
            user_id,
            MAX(event_time) AS last_seen
        FROM events
        GROUP BY user_id
    ) t
    WHERE last_seen < CURRENT_DATE - INTERVAL '30 days'
),
feature_stats AS (
    SELECT
        e.event_name,
        COUNT(DISTINCT e.user_id) FILTER (
            WHERE cu.user_id IS NULL
        ) AS retained_users,
        COUNT(DISTINCT e.user_id) FILTER (
            WHERE cu.user_id IS NOT NULL
        ) AS churned_users
    FROM events e
    LEFT JOIN churned_users cu
        ON e.user_id = cu.user_id
    GROUP BY e.event_name
)
SELECT
    event_name AS feature_name,
    retained_users,
    churned_users,
    ROUND(
        retained_users * 1.0 /
        NULLIF(retained_users + churned_users, 0),
        2
    ) AS retention_ratio
FROM feature_stats
ORDER BY retention_ratio DESC;

-- Explanation:
-- Calculates retention ratio per feature.
-- Features with higher ratios are strong candidates for
-- onboarding, promotion, and product investment.
