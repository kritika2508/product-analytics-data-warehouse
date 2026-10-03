/*
==========================================================
Business Analysis Layer
==========================================================
Purpose:
Translate the existing Product Analytics warehouse into
decision-oriented analysis for Product, Growth, Customer
Success and Revenue stakeholders.

Assumed Gold objects:
- gold.fact_subscription_funnel
- gold.dim_users
- gold.fact_user_activity_daily
- gold.fact_revenue_monthly

The queries below are descriptive. They identify patterns
and segments for investigation; they do not establish
causality unless the underlying experimental design supports it.
*/

-- ========================================================
-- 1. Conversion by Company Size
-- ========================================================
IF OBJECT_ID('gold.vw_conversion_by_company_size', 'V') IS NOT NULL
    DROP VIEW gold.vw_conversion_by_company_size;
GO

CREATE VIEW gold.vw_conversion_by_company_size AS
SELECT
    u.company_size,
    COUNT(*) AS total_users,
    SUM(CAST(f.is_converted AS INT)) AS converted_users,
    CAST(
        SUM(CAST(f.is_converted AS INT)) * 1.0 / NULLIF(COUNT(*), 0)
        AS DECIMAL(6,4)
    ) AS conversion_rate,
    CAST(
        (
            SUM(CAST(f.is_converted AS INT)) * 1.0 / NULLIF(COUNT(*), 0)
        )
        - AVG(
            SUM(CAST(f.is_converted AS INT)) * 1.0 / NULLIF(COUNT(*), 0)
          ) OVER ()
        AS DECIMAL(6,4)
    ) AS conversion_gap_vs_segment_avg
FROM gold.fact_subscription_funnel f
JOIN gold.dim_users u
    ON f.user_id = u.user_id
GROUP BY u.company_size;
GO

-- ========================================================
-- 2. Conversion by Experiment Variant
-- ========================================================
IF OBJECT_ID('gold.vw_conversion_by_experiment', 'V') IS NOT NULL
    DROP VIEW gold.vw_conversion_by_experiment;
GO

CREATE VIEW gold.vw_conversion_by_experiment AS
SELECT
    u.experiment_variant,
    COUNT(*) AS total_users,
    SUM(CAST(f.is_converted AS INT)) AS converted_users,
    CAST(
        SUM(CAST(f.is_converted AS INT)) * 1.0 / NULLIF(COUNT(*), 0)
        AS DECIMAL(6,4)
    ) AS conversion_rate
FROM gold.fact_subscription_funnel f
JOIN gold.dim_users u
    ON f.user_id = u.user_id
GROUP BY u.experiment_variant;
GO

-- ========================================================
-- 3. Conversion by Country
-- ========================================================
IF OBJECT_ID('gold.vw_conversion_by_country', 'V') IS NOT NULL
    DROP VIEW gold.vw_conversion_by_country;
GO

CREATE VIEW gold.vw_conversion_by_country AS
SELECT
    u.country,
    COUNT(*) AS total_users,
    SUM(CAST(f.is_converted AS INT)) AS converted_users,
    CAST(
        SUM(CAST(f.is_converted AS INT)) * 1.0 / NULLIF(COUNT(*), 0)
        AS DECIMAL(6,4)
    ) AS conversion_rate
FROM gold.fact_subscription_funnel f
JOIN gold.dim_users u
    ON f.user_id = u.user_id
GROUP BY u.country;
GO

-- ========================================================
-- 4. Segment-level conversion matrix
-- ========================================================
/*
Use this query to identify combinations of acquisition
channel, company size and experiment variant that warrant
deeper investigation.
*/
SELECT
    u.acquisition_channel,
    u.company_size,
    u.experiment_variant,
    COUNT(*) AS total_users,
    SUM(CAST(f.is_converted AS INT)) AS converted_users,
    CAST(
        SUM(CAST(f.is_converted AS INT)) * 1.0 / NULLIF(COUNT(*), 0)
        AS DECIMAL(6,4)
    ) AS conversion_rate
FROM gold.fact_subscription_funnel f
JOIN gold.dim_users u
    ON f.user_id = u.user_id
GROUP BY
    u.acquisition_channel,
    u.company_size,
    u.experiment_variant
ORDER BY conversion_rate DESC;

-- ========================================================
-- 5. Funnel stage performance
-- ========================================================
WITH funnel AS (
    SELECT
        COUNT(*) AS signups,
        SUM(CASE WHEN trial_start_date IS NOT NULL THEN 1 ELSE 0 END) AS trials,
        SUM(CASE WHEN trial_end_date IS NOT NULL THEN 1 ELSE 0 END) AS completed_trials,
        SUM(CASE WHEN subscription_start_date IS NOT NULL THEN 1 ELSE 0 END) AS paid_users
    FROM gold.fact_subscription_funnel
)
SELECT
    signups,
    trials,
    completed_trials,
    paid_users,
    CAST(trials * 1.0 / NULLIF(signups, 0) AS DECIMAL(6,4)) AS signup_to_trial_rate,
    CAST(completed_trials * 1.0 / NULLIF(trials, 0) AS DECIMAL(6,4)) AS trial_completion_rate,
    CAST(paid_users * 1.0 / NULLIF(completed_trials, 0) AS DECIMAL(6,4)) AS trial_to_paid_rate,
    CAST(paid_users * 1.0 / NULLIF(signups, 0) AS DECIMAL(6,4)) AS signup_to_paid_rate
FROM funnel;

-- ========================================================
-- 6. Monthly product health
-- ========================================================
/*
One reusable view for the executive dashboard:
conversion + engagement trend in a common monthly grain.
*/
IF OBJECT_ID('gold.vw_monthly_product_health', 'V') IS NOT NULL
    DROP VIEW gold.vw_monthly_product_health;
GO

CREATE VIEW gold.vw_monthly_product_health AS
WITH conversion AS (
    SELECT
        DATEFROMPARTS(YEAR(signup_date), MONTH(signup_date), 1) AS month,
        COUNT(*) AS signups,
        SUM(CAST(is_converted AS INT)) AS converted_users,
        CAST(
            SUM(CAST(is_converted AS INT)) * 1.0 / NULLIF(COUNT(*), 0)
            AS DECIMAL(6,4)
        ) AS conversion_rate
    FROM gold.fact_subscription_funnel
    GROUP BY DATEFROMPARTS(YEAR(signup_date), MONTH(signup_date), 1)
),
daily_activity AS (
    SELECT
        DATEFROMPARTS(YEAR(activity_date), MONTH(activity_date), 1) AS month,
        activity_date,
        COUNT(DISTINCT user_id) AS dau
    FROM gold.fact_user_activity_daily
    GROUP BY
        DATEFROMPARTS(YEAR(activity_date), MONTH(activity_date), 1),
        activity_date
),
monthly_activity AS (
    SELECT
        DATEFROMPARTS(YEAR(activity_date), MONTH(activity_date), 1) AS month,
        COUNT(DISTINCT user_id) AS mau
    FROM gold.fact_user_activity_daily
    GROUP BY DATEFROMPARTS(YEAR(activity_date), MONTH(activity_date), 1)
),
stickiness AS (
    SELECT
        d.month,
        AVG(d.dau) AS avg_dau,
        m.mau,
        CAST(AVG(d.dau) * 1.0 / NULLIF(m.mau, 0) AS DECIMAL(6,4)) AS stickiness_ratio
    FROM daily_activity d
    JOIN monthly_activity m
        ON d.month = m.month
    GROUP BY d.month, m.mau
)
SELECT
    c.month,
    c.signups,
    c.converted_users,
    c.conversion_rate,
    s.avg_dau,
    s.mau,
    s.stickiness_ratio
FROM conversion c
LEFT JOIN stickiness s
    ON c.month = s.month;
GO

-- ========================================================
-- 7. New vs existing-customer revenue
-- ========================================================
IF OBJECT_ID('gold.vw_revenue_mix', 'V') IS NOT NULL
    DROP VIEW gold.vw_revenue_mix;
GO

CREATE VIEW gold.vw_revenue_mix AS
WITH first_revenue AS (
    SELECT
        user_id,
        MIN(revenue_month) AS first_revenue_month
    FROM gold.fact_revenue_monthly
    GROUP BY user_id
)
SELECT
    r.revenue_month,
    SUM(CASE
        WHEN r.revenue_month = f.first_revenue_month
        THEN r.total_revenue ELSE 0 END) AS new_revenue,
    SUM(CASE
        WHEN r.revenue_month > f.first_revenue_month
        THEN r.total_revenue ELSE 0 END) AS expansion_revenue,
    SUM(r.total_revenue) AS total_revenue
FROM gold.fact_revenue_monthly r
JOIN first_revenue f
    ON r.user_id = f.user_id
GROUP BY r.revenue_month;
GO

-- ========================================================
-- 8. Trial conversion speed distribution
-- ========================================================
SELECT
    DATEDIFF(day, trial_start_date, subscription_start_date) AS days_to_convert,
    COUNT(*) AS converted_users
FROM gold.fact_subscription_funnel
WHERE trial_start_date IS NOT NULL
  AND subscription_start_date IS NOT NULL
GROUP BY DATEDIFF(day, trial_start_date, subscription_start_date)
ORDER BY days_to_convert;
