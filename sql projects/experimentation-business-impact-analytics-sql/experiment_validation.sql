/*
Project: Experimentation & Business Impact Analytics using SQL
File: experiment_validation.sql
Author: Sathvik
Purpose:
Validate experiment setup by checking user assignment,
variant distribution, and detecting Sample Ratio Mismatch (SRM).

Assumptions:
1. Each user is assigned to only one experiment variant
2. experiment_name identifies the experiment
3. Variants are expected to be evenly split unless specified
*/

--------------------------------------------------
-- Business Question 1:
-- Which users are assigned to each experiment variant?
--------------------------------------------------

WITH experiment_users AS (
    SELECT DISTINCT
        user_id,
        experiment_name,
        variant
    FROM experiments
)
SELECT
    user_id,
    experiment_name,
    variant
FROM experiment_users
ORDER BY experiment_name, variant, user_id;

-- Explanation:
-- Creates a clean base table of experiment participants.
-- Used to validate experiment assignment before analysis.

--------------------------------------------------
-- Business Question 2:
-- How many users are assigned to each variant?
--------------------------------------------------

WITH experiment_users AS (
    SELECT DISTINCT
        user_id,
        experiment_name,
        variant
    FROM experiments
)
SELECT
    variant,
    COUNT(DISTINCT user_id) AS users_in_variant
FROM experiment_users
GROUP BY variant
ORDER BY variant;

-- Explanation:
-- Checks absolute user counts per variant.
-- Large imbalances may indicate assignment issues.

--------------------------------------------------
-- Business Question 3:
-- What percentage of users are in each experiment variant?
--------------------------------------------------

WITH experiment_users AS (
    SELECT DISTINCT
        user_id,
        variant
    FROM experiments
),
variant_counts AS (
    SELECT
        variant,
        COUNT(*) AS users
    FROM experiment_users
    GROUP BY variant
),
total_users AS (
    SELECT
        SUM(users) AS total_users
    FROM variant_counts
)
SELECT
    v.variant,
    v.users,
    ROUND(
        v.users * 100.0 / t.total_users,
        2
    ) AS actual_percentage
FROM variant_counts v
CROSS JOIN total_users t
ORDER BY v.variant;

-- Explanation:
-- Converts variant counts into percentage distribution.
-- Used to compare against expected experiment split (e.g. 50/50).

--------------------------------------------------
-- Business Question 4:
-- Is there a Sample Ratio Mismatch (SRM) in the experiment?
--------------------------------------------------

WITH experiment_users AS (
    SELECT DISTINCT
        user_id,
        variant
    FROM experiments
),
variant_distribution AS (
    SELECT
        variant,
        COUNT(*) * 1.0 /
        SUM(COUNT(*)) OVER () AS distribution_ratio
    FROM experiment_users
    GROUP BY variant
)
SELECT
    variant,
    ROUND(distribution_ratio, 3) AS distribution_ratio,
    CASE
        WHEN distribution_ratio BETWEEN 0.45 AND 0.55
            THEN 'OK'
        ELSE 'POTENTIAL_SRM'
    END AS srm_status
FROM variant_distribution
ORDER BY variant;

-- Explanation:
-- Detects Sample Ratio Mismatch (SRM).
-- SRM indicates experiment results may be invalid
-- due to biased user assignment.
