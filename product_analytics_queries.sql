/*
==================================================
Product Growth Analytics SQL Queries
==================================================
This file contains SQL views and analytical queries
used to analyze product performance, including:

• Funnel Conversion
• Acquisition Channel Performance
• Trial Drop-off Analysis
• Retention Cohort Analysis
• DAU/MAU Stickiness
• Revenue Expansion vs New Revenue

============================================
 Funnel Conversion Analysis
============================================
This view calculates the overall conversion performance of the product's subscription funnel.

Metrics calculated:
1. total_users: Total number of users who signed up.
2. converted_users: Number of users who successfully converted from trial to paid subscription.
3. conversion_rate: Percentage of users who converted.
The conversion rate helps evaluate how effectively the product converts trial users into paying customers.
*/

CREATE VIEW vw_funnel_conversion AS
SELECT
    COUNT(*) AS total_users,
    SUM(CAST(is_converted AS INT)) AS converted_users,
    SUM(CAST(is_converted AS INT)) * 1.0 / COUNT(*) AS conversion_rate
FROM gold.fact_subscription_funnel;

/*
============================================
 Conversion Rate by Signup Month
 ============================================
This view calculates the monthly conversion rate of users based on the month they signed up.

Metrics calculated:
1. signup_month: The month in which users registered.
2. total_users: Total number of users who signed up in that month.
3. converted_users: Number of users who converted to a paid subscription.
4. conversion_rate: Percentage of users who converted.
This analysis helps identify trends in user acquisition quality and evaluate how effectively different signup cohorts convert over time.

Optimization:
DATEFROMPARTS is used to standardize the signup date to the
first day of the month and is reused in both SELECT and GROUP BY to maintain consistency and avoid redundant transformations.
*/
CREATE VIEW vw_conversion_by_month AS
SELECT
    DATEFROMPARTS(YEAR(signup_date), MONTH(signup_date), 1) AS signup_month,
    COUNT(*) AS total_users,
    SUM(CAST(is_converted AS INT)) AS converted_users,
    CAST(SUM(CAST(is_converted AS INT)) * 1.0 / COUNT(*) AS DECIMAL(5,4)) AS conversion_rate
FROM gold.fact_subscription_funnel
GROUP BY DATEFROMPARTS(YEAR(signup_date), MONTH(signup_date), 1);

/*
============================================
Conversion Rate by Acquisition Channel
============================================
Metrics:
acquisition_channel: Source through which users joined
total_users: Number of users from the channel
converted_users: Users who converted to paid
conversion_rate: Percentage of users who converted

Optimization: Join only required fields from dim_users.
*/
CREATE VIEW vw_conversion_by_channel AS
SELECT
    u.acquisition_channel,
    COUNT(*) AS total_users,
    SUM(CAST(f.is_converted AS INT)) AS converted_users,
    CAST(SUM(CAST(f.is_converted AS INT)) * 1.0 / COUNT(*) AS DECIMAL(5,4)) AS conversion_rate
FROM gold.fact_subscription_funnel f
JOIN gold.dim_users u
    ON f.user_id = u.user_id
GROUP BY u.acquisition_channel;

/*
============================================
Funnel Stage Counts
============================================
Calculates the number of users at each stage of the subscription funnel: signup, trial start, trial completion, and paid subscription.

Optimization: Uses conditional aggregation to calculate all stages in a single table scan.
*/
SELECT
    COUNT(*) AS total_signups,
    SUM(CASE WHEN trial_start_date IS NOT NULL THEN 1 ELSE 0 END) AS trial_started,
    SUM(CASE WHEN trial_end_date IS NOT NULL THEN 1 ELSE 0 END) AS trial_completed,
    SUM(CASE WHEN subscription_start_date IS NOT NULL THEN 1 ELSE 0 END) AS subscribed_users
FROM gold.fact_subscription_funnel;

/*
============================================
Trial to Paid Conversion Speed
============================================
Calculates the average number of days users take to convert from trial start to paid subscription.

Optimization: Filters only converted users to reduce rows processed.
*/
SELECT
    AVG(DATEDIFF(day, trial_start_date, subscription_start_date)) AS avg_days_to_convert
FROM gold.fact_subscription_funnel
WHERE subscription_start_date IS NOT NULL;

/*
============================================
 Trial Drop-off Analysis
============================================
Calculates how many trial users convert to paid and how many drop off without subscribing.

Optimization: Uses conditional aggregation to compute all metrics in a single query.
*/
CREATE VIEW vw_drop_off AS
SELECT
    COUNT(*) AS total_trial_users,
    SUM(CASE WHEN subscription_start_date IS NOT NULL THEN 1 ELSE 0 END) AS converted_users,
    SUM(CASE WHEN subscription_start_date IS NULL THEN 1 ELSE 0 END) AS dropped_users,
    CAST(
        SUM(CASE WHEN subscription_start_date IS NULL THEN 1 ELSE 0 END) * 1.0/ COUNT(*) AS DECIMAL(5,4)
    ) AS dropoff_rate
FROM gold.fact_subscription_funnel;

/*
============================================
 Trial Duration vs Conversion Rate
============================================
Analyzes how trial length affects conversion from trial to paid subscription.

Optimization: Computes trial duration once and groups results by duration.
*/
SELECT
    DATEDIFF(day, trial_start_date, trial_end_date) AS trial_duration_days,
    COUNT(*) AS total_users,
    SUM(CAST(is_converted AS INT)) AS converted_users,
    CAST(SUM(CAST(is_converted AS INT)) * 1.0 / COUNT(*) AS DECIMAL(5,4)) AS conversion_rate
FROM gold.fact_subscription_funnel
WHERE trial_start_date IS NOT NULL
  AND trial_end_date IS NOT NULL
GROUP BY DATEDIFF(day, trial_start_date, trial_end_date)
ORDER BY trial_duration_days;

/*
============================================
 Retention Cohort Analysis
============================================
Analyzes user retention by grouping users into monthly signup cohorts and tracking their activity in subsequent months.

Metrics:
cohort_month: Month users signed up
month_number: Months since signup
active_users: Users active in that month
retention_rate: Percentage of users retained

Optimization:
Uses CTEs to calculate cohort size once and reuse it for retention calculations.
*/
CREATE VIEW vw_retention_cohort AS
WITH cohort_size AS (
    SELECT
        DATEFROMPARTS(YEAR(signup_date), MONTH(signup_date), 1) AS cohort_month,
        COUNT(*) AS total_users
    FROM gold.fact_subscription_funnel
    GROUP BY DATEFROMPARTS(YEAR(signup_date), MONTH(signup_date), 1)
),
retention AS (
    SELECT
        DATEFROMPARTS(YEAR(c.signup_date), MONTH(c.signup_date), 1) AS cohort_month,
        DATEDIFF(
            month,
            DATEFROMPARTS(YEAR(c.signup_date), MONTH(c.signup_date), 1),
            DATEFROMPARTS(YEAR(a.activity_date), MONTH(a.activity_date), 1)
        ) AS month_number,
        COUNT(DISTINCT a.user_id) AS active_users
    FROM gold.fact_subscription_funnel c
    JOIN gold.fact_user_activity_daily a
        ON c.user_id = a.user_id
    WHERE a.activity_date >= c.signup_date
    GROUP BY
        DATEFROMPARTS(YEAR(c.signup_date), MONTH(c.signup_date), 1),
        DATEDIFF(
            month,
            DATEFROMPARTS(YEAR(c.signup_date), MONTH(c.signup_date), 1),
            DATEFROMPARTS(YEAR(a.activity_date), MONTH(a.activity_date), 1)
        )
)

SELECT
    r.cohort_month,
    r.month_number,
    r.active_users,
    c.total_users,
    CAST(r.active_users * 1.0 / c.total_users AS DECIMAL(5,4)) AS retention_rate
FROM retention r
JOIN cohort_size c
    ON r.cohort_month = c.cohort_month;

   -- ============================================
-- DAU / MAU Stickiness Analysis
-- ============================================
-- Measures user engagement by calculating how often
-- users return to the product.

-- Stickiness = Average Daily Active Users / Monthly Active Users

-- Daily Active Users (DAU)
-- Counts unique users active on each day.

SELECT
    activity_date,
    COUNT(DISTINCT user_id) AS dau
FROM gold.fact_user_activity_daily
GROUP BY activity_date
ORDER BY activity_date;


-- Monthly Active Users (MAU)
-- Counts unique users active within each month.

SELECT
    DATEFROMPARTS(YEAR(activity_date), MONTH(activity_date), 1) AS activity_month,
    COUNT(DISTINCT user_id) AS mau
FROM gold.fact_user_activity_daily
GROUP BY DATEFROMPARTS(YEAR(activity_date), MONTH(activity_date), 1)
ORDER BY activity_month;

/*
============================================
 Stickiness Ratio (DAU / MAU)
============================================
Calculates monthly stickiness using average DAU divided by total MAU.
*/
CREATE VIEW vw_stickiness AS
WITH daily_users AS (
    SELECT
        DATEFROMPARTS(YEAR(activity_date), MONTH(activity_date), 1) AS month,
        activity_date,
        COUNT(DISTINCT user_id) AS dau
    FROM gold.fact_user_activity_daily
    GROUP BY
        DATEFROMPARTS(YEAR(activity_date), MONTH(activity_date), 1),
        activity_date
),
monthly_users AS (
    SELECT
        DATEFROMPARTS(YEAR(activity_date), MONTH(activity_date), 1) AS month,
        COUNT(DISTINCT user_id) AS mau
    FROM gold.fact_user_activity_daily
    GROUP BY DATEFROMPARTS(YEAR(activity_date), MONTH(activity_date), 1)
)
SELECT
    d.month,
    AVG(d.dau) AS avg_daily_users,
    m.mau,
    CAST(AVG(d.dau) * 1.0 / m.mau AS DECIMAL(5,4)) AS stickiness_ratio
FROM daily_users d
JOIN monthly_users m
    ON d.month = m.month
GROUP BY d.month, m.mau;

/*
============================================
Revenue Expansion vs New Revenue
============================================
Analyzes monthly revenue by separating revenue generated from new users and existing users.

New revenue: Revenue generated in a user's first revenue month.
Expansion revenue: Revenue generated from users after their first purchase month.
*/

-- Identify the first revenue month for each user
SELECT
    user_id,
    MIN(revenue_month) AS first_revenue_month
FROM gold.fact_revenue_monthly
GROUP BY user_id;

-- Create view for revenue breakdown
CREATE VIEW vw_revenue_growth AS
WITH first_purchase AS (
    SELECT
        user_id,
        MIN(revenue_month) AS first_revenue_month
    FROM gold.fact_revenue_monthly
    GROUP BY user_id
)
SELECT
    r.revenue_month,
    SUM(CASE WHEN r.revenue_month = f.first_revenue_month THEN r.total_revenue ELSE 0
        END) AS new_revenue,
    SUM(CASE WHEN r.revenue_month > f.first_revenue_month THEN r.total_revenue ELSE 0
        END) AS expansion_revenue

FROM gold.fact_revenue_monthly r
JOIN first_purchase f
    ON r.user_id = f.user_id
GROUP BY r.revenue_month;
