/*
Project: Product, Retention & Churn Analytics using SQL
File: final_views.sql
Author: Sathvik
Purpose:
Provide reusable, production-ready views for core
product, retention, churn, funnel, and feature analytics.

These views are intended to act as a single source of truth
for dashboards and stakeholder reporting.
*/

--------------------------------------------------
-- View 1: Daily Active Users (DAU)
--------------------------------------------------

CREATE OR REPLACE VIEW daily_active_users AS
SELECT
    DATE(event_time) AS activity_date,
    COUNT(DISTINCT user_id) AS dau
FROM events
GROUP BY activity_date;

--------------------------------------------------
-- View 2: Monthly Active Users (MAU)
--------------------------------------------------

CREATE OR REPLACE VIEW monthly_active_users AS
SELECT
    DATE_TRUNC('month', event_time) AS month,
    COUNT(DISTINCT user_id) AS mau
FROM events
GROUP BY month;

--------------------------------------------------
-- View 3: DAU / MAU Ratio (Product Stickiness)
--------------------------------------------------

CREATE OR REPLACE VIEW dau_mau_ratio AS
SELECT
    d.activity_date,
    d.dau,
    m.mau,
    ROUND(
        d.dau * 1.0 / NULLIF(m.mau, 0),
        3
    ) AS dau_mau_ratio
FROM daily_active_users d
JOIN monthly_active_users m
  ON DATE_TRUNC('month', d.activity_date) = m.month;

--------------------------------------------------
-- View 4: Monthly Cohort Retention
--------------------------------------------------

CREATE OR REPLACE VIEW cohort_retention AS
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
  ON c.cohort_month = cs.cohort_month;

--------------------------------------------------
-- View 5: Funnel Conversion Summary
--------------------------------------------------

CREATE OR REPLACE VIEW funnel_conversion_summary AS
SELECT
    COUNT(DISTINCT user_id) FILTER (WHERE event_name = 'signup') AS signup_users,
    COUNT(DISTINCT user_id) FILTER (WHERE event_name = 'first_action') AS activated_users,
    COUNT(DISTINCT user_id) FILTER (WHERE event_name = 'subscribe') AS subscribed_users,
    COUNT(DISTINCT user_id) FILTER (WHERE event_name = 'payment_success') AS paying_users,
    ROUND(
        COUNT(DISTINCT user_id) FILTER (WHERE event_name = 'first_action')
        * 100.0 /
        NULLIF(
            COUNT(DISTINCT user_id) FILTER (WHERE event_name = 'signup'),
            0
        ),
        2
    ) AS signup_to_activation_pct,
    ROUND(
        COUNT(DISTINCT user_id) FILTER (WHERE event_name = 'subscribe')
        * 100.0 /
        NULLIF(
            COUNT(DISTINCT user_id) FILTER (WHERE event_name = 'first_action'),
            0
        ),
        2
    ) AS activation_to_subscription_pct,
    ROUND(
        COUNT(DISTINCT user_id) FILTER (WHERE event_name = 'payment_success')
        * 100.0 /
        NULLIF(
            COUNT(DISTINCT user_id) FILTER (WHERE event_name = 'subscribe'),
            0
        ),
        2
    ) AS subscription_to_payment_pct
FROM events;

--------------------------------------------------
-- View 6: Churned Users (30-day Inactivity)
--------------------------------------------------

CREATE OR REPLACE VIEW churned_users AS
SELECT
    user_id,
    MAX(event_time) AS last_seen
FROM events
GROUP BY user_id
HAVING MAX(event_time) < CURRENT_DATE - INTERVAL '30 days';

--------------------------------------------------
-- View 7: Overall Churn Rate
--------------------------------------------------

CREATE OR REPLACE VIEW churn_rate_summary AS
WITH active_users AS (
    SELECT DISTINCT
        user_id
    FROM events
    WHERE event_time >= CURRENT_DATE - INTERVAL '30 days'
),
churned AS (
    SELECT user_id FROM churned_users
)
SELECT
    ROUND(
        COUNT(DISTINCT churned.user_id) * 100.0 /
        NULLIF(
            COUNT(DISTINCT active_users.user_id)
            + COUNT(DISTINCT churned.user_id),
            0
        ),
        2
    ) AS churn_rate_pct
FROM active_users, churned;

--------------------------------------------------
-- View 8: Feature Retention Impact
--------------------------------------------------

CREATE OR REPLACE VIEW feature_retention_impact AS
WITH churned AS (
    SELECT user_id FROM churned_users
),
feature_stats AS (
    SELECT
        e.event_name AS feature_name,
        COUNT(DISTINCT e.user_id) FILTER (
            WHERE c.user_id IS NULL
        ) AS retained_users,
        COUNT(DISTINCT e.user_id) FILTER (
            WHERE c.user_id IS NOT NULL
        ) AS churned_users
    FROM events e
    LEFT JOIN churned c
      ON e.user_id = c.user_id
    GROUP BY e.event_name
)
SELECT
    feature_name,
    retained_users,
    churned_users,
    ROUND(
        retained_users * 1.0 /
        NULLIF(retained_users + churned_users, 0),
        2
    ) AS retention_ratio
FROM feature_stats;
