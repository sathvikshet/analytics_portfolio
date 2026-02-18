/*
Project: Product, Retention & Churn Analytics using SQL
File: churn_detection.sql
Author: Sathvik
Purpose:
Identify churned users using activity-based and subscription-based
signals, and calculate overall churn rate.

Assumptions:
1. User is considered inactive if no activity in the last 30 days
2. event_time represents user activity timestamp
3. Subscription churn is identified using subscription end_date
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
-- Captures the most recent activity date for each user.
-- Serves as the base signal for inactivity-based churn.

--------------------------------------------------
-- Business Question 2:
-- Which users have been inactive for more than 30 days?
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
WHERE last_seen < CURRENT_DATE - INTERVAL '30 days'
ORDER BY last_seen;

-- Explanation:
-- Flags users who have stopped engaging recently.
-- These users are considered behaviorally churned.

--------------------------------------------------
-- Business Question 3:
-- Which users have churned based on subscription cancellation?
--------------------------------------------------

SELECT
    user_id,
    end_date
FROM subscriptions
WHERE end_date IS NOT NULL
  AND end_date < CURRENT_DATE;

-- Explanation:
-- Identifies users whose paid subscriptions have ended.
-- Represents explicit churn for subscription-based products.

--------------------------------------------------
-- Business Question 4:
-- Which users are churned based on either inactivity or subscription end?
--------------------------------------------------

WITH inactive_users AS (
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
subscription_churn AS (
    SELECT
        user_id
    FROM subscriptions
    WHERE end_date IS NOT NULL
      AND end_date < CURRENT_DATE
)
SELECT DISTINCT
    user_id
FROM inactive_users
UNION
SELECT DISTINCT
    user_id
FROM subscription_churn;

-- Explanation:
-- Combines behavioral churn and subscription churn.
-- Produces a unified list of churned users.

--------------------------------------------------
-- Business Question 5:
-- What is the overall churn rate of the product?
--------------------------------------------------

WITH active_users AS (
    SELECT DISTINCT
        user_id
    FROM events
    WHERE event_time >= CURRENT_DATE - INTERVAL '30 days'
),
churned_users AS (
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
    ROUND(
        COUNT(DISTINCT churned_users.user_id) * 100.0 /
        NULLIF(
            COUNT(DISTINCT active_users.user_id)
            + COUNT(DISTINCT churned_users.user_id),
            0
        ),
        2
    ) AS churn_rate_pct
FROM churned_users, active_users;

-- Explanation:
-- Calculates churn rate as the percentage of churned users
-- relative to the total recent user base.
-- This is a core metric for product health.
