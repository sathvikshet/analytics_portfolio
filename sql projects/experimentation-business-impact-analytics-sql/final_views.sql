/*
Project: Experimentation & Business Impact Analytics using SQL
File: final_views.sql
Author: Sathvik
Purpose:
Create reusable, business-ready views for experiment validation,
conversion impact, revenue impact, and retention comparison.

These views act as a single source of truth for
decision-making and BI dashboards.
*/

--------------------------------------------------
-- View 1: Experiment Variant Distribution
-- Purpose: Validate experiment assignment & detect SRM
--------------------------------------------------

CREATE OR REPLACE VIEW experiment_variant_distribution AS
SELECT
    variant,
    COUNT(DISTINCT user_id) AS users_in_variant,
    ROUND(
        COUNT(DISTINCT user_id) * 100.0 /
        SUM(COUNT(DISTINCT user_id)) OVER (),
        2
    ) AS percentage_share
FROM experiments
GROUP BY variant;

--------------------------------------------------
-- View 2: Conversion Rate by Variant
-- Purpose: Measure experiment conversion performance
--------------------------------------------------

CREATE OR REPLACE VIEW experiment_conversion_rate AS
WITH converted_users AS (
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
    COUNT(DISTINCT c.user_id) AS converted_users,
    ROUND(
        COUNT(DISTINCT c.user_id) * 100.0 /
        NULLIF(COUNT(DISTINCT e.user_id), 0),
        2
    ) AS conversion_rate_pct
FROM experiments e
LEFT JOIN converted_users c
  ON e.user_id = c.user_id
GROUP BY e.variant;

--------------------------------------------------
-- View 3: Revenue & ARPU by Variant
-- Purpose: Measure monetization impact of experiment
--------------------------------------------------

CREATE OR REPLACE VIEW experiment_revenue_arpu AS
WITH user_revenue AS (
    SELECT
        o.customer_id AS user_id,
        SUM(p.payment_value) AS revenue
    FROM orders o
    JOIN payments p
      ON o.order_id = p.order_id
    WHERE p.payment_status = 'success'
    GROUP BY o.customer_id
)
SELECT
    e.variant,
    COUNT(DISTINCT e.user_id) AS users,
    ROUND(SUM(COALESCE(r.revenue, 0)), 2) AS total_revenue,
    ROUND(
        SUM(COALESCE(r.revenue, 0)) /
        NULLIF(COUNT(DISTINCT e.user_id), 0),
        2
    ) AS arpu
FROM experiments e
LEFT JOIN user_revenue r
  ON e.user_id = r.user_id
GROUP BY e.variant;

--------------------------------------------------
-- View 4: Retention Rate by Variant (30-day activity)
-- Purpose: Measure long-term impact of experiment
--------------------------------------------------

CREATE OR REPLACE VIEW experiment_retention_rate AS
WITH last_activity AS (
    SELECT
        user_id,
        MAX(event_time) AS last_seen
    FROM events
    GROUP BY user_id
)
SELECT
    e.variant,
    COUNT(DISTINCT e.user_id) AS total_users,
    COUNT(DISTINCT e.user_id) FILTER (
        WHERE la.last_seen >= CURRENT_DATE - INTERVAL '30 days'
    ) AS retained_users,
    ROUND(
        COUNT(DISTINCT e.user_id) FILTER (
            WHERE la.last_seen >= CURRENT_DATE - INTERVAL '30 days'
        ) * 100.0 /
        NULLIF(COUNT(DISTINCT e.user_id), 0),
        2
    ) AS retention_rate_pct
FROM experiments e
JOIN last_activity la
  ON e.user_id = la.user_id
GROUP BY e.variant;

--------------------------------------------------
-- View 5: Experiment Impact Summary
-- Purpose: One-row business decision summary
--------------------------------------------------

CREATE OR REPLACE VIEW experiment_impact_summary AS
WITH conversion AS (
    SELECT * FROM experiment_conversion_rate
),
revenue AS (
    SELECT * FROM experiment_revenue_arpu
),
retention AS (
    SELECT * FROM experiment_retention_rate
)
SELECT
    c.variant,
    c.conversion_rate_pct,
    r.arpu,
    ret.retention_rate_pct
FROM conversion c
JOIN revenue r
  ON c.variant = r.variant
JOIN retention ret
  ON c.variant = ret.variant;
