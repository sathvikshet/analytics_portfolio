/*
Project: Product, Retention & Churn Analytics using SQL
File: funnel_analysis.sql
Author: Sathvik
Purpose:
Analyze the user conversion funnel from signup to payment
to identify drop-offs and optimization opportunities.

Assumptions:
1. events table contains one row per user interaction
2. event_name represents key funnel steps
3. Funnel steps occur in a logical progression
*/

--------------------------------------------------
-- Business Question 1:
-- What are the key funnel events captured for each user?
--------------------------------------------------

WITH funnel_events AS (
    SELECT DISTINCT
        user_id,
        event_name
    FROM events
    WHERE event_name IN (
        'signup',
        'first_action',
        'subscribe',
        'payment_success'
    )
)
SELECT
    user_id,
    event_name
FROM funnel_events
ORDER BY user_id, event_name;

-- Explanation:
-- Filters and isolates only the events that are part of the core funnel.
-- Acts as the base dataset for funnel analysis.

--------------------------------------------------
-- Business Question 2:
-- How many users reach each step of the funnel?
--------------------------------------------------

WITH funnel_events AS (
    SELECT DISTINCT
        user_id,
        event_name
    FROM events
    WHERE event_name IN (
        'signup',
        'first_action',
        'subscribe',
        'payment_success'
    )
)
SELECT
    COUNT(DISTINCT user_id) FILTER (WHERE event_name = 'signup') AS signup_users,
    COUNT(DISTINCT user_id) FILTER (WHERE event_name = 'first_action') AS activated_users,
    COUNT(DISTINCT user_id) FILTER (WHERE event_name = 'subscribe') AS subscribed_users,
    COUNT(DISTINCT user_id) FILTER (WHERE event_name = 'payment_success') AS paying_users
FROM funnel_events;

-- Explanation:
-- Provides a high-level snapshot of how many users
-- progress through each funnel stage.

--------------------------------------------------
-- Business Question 3:
-- What are the conversion rates between each funnel step?
--------------------------------------------------

WITH funnel_counts AS (
    SELECT
        COUNT(DISTINCT user_id) FILTER (WHERE event_name = 'signup') AS signup_users,
        COUNT(DISTINCT user_id) FILTER (WHERE event_name = 'first_action') AS activated_users,
        COUNT(DISTINCT user_id) FILTER (WHERE event_name = 'subscribe') AS subscribed_users,
        COUNT(DISTINCT user_id) FILTER (WHERE event_name = 'payment_success') AS paying_users
    FROM events
)
SELECT
    signup_users,
    activated_users,
    subscribed_users,
    paying_users,
    ROUND(
        activated_users * 100.0 / NULLIF(signup_users, 0),
        2
    ) AS signup_to_activation_pct,
    ROUND(
        subscribed_users * 100.0 / NULLIF(activated_users, 0),
        2
    ) AS activation_to_subscription_pct,
    ROUND(
        paying_users * 100.0 / NULLIF(subscribed_users, 0),
        2
    ) AS subscription_to_payment_pct
FROM funnel_counts;

-- Explanation:
-- Calculates conversion percentages between funnel stages.
-- Helps identify where users drop off the most.

--------------------------------------------------
-- Business Question 4:
-- How many users drop off at each stage of the funnel?
--------------------------------------------------

WITH funnel_counts AS (
    SELECT
        COUNT(DISTINCT user_id) FILTER (WHERE event_name = 'signup') AS signup_users,
        COUNT(DISTINCT user_id) FILTER (WHERE event_name = 'first_action') AS activated_users,
        COUNT(DISTINCT user_id) FILTER (WHERE event_name = 'subscribe') AS subscribed_users,
        COUNT(DISTINCT user_id) FILTER (WHERE event_name = 'payment_success') AS paying_users
    FROM events
)
SELECT
    signup_users - activated_users AS drop_after_signup,
    activated_users - subscribed_users AS drop_after_activation,
    subscribed_users - paying_users AS drop_after_subscription
FROM funnel_counts;

-- Explanation:
-- Quantifies user loss at each funnel stage.
-- Highlights the biggest friction points in the user journey.
