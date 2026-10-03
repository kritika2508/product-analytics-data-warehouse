# Data Model

## Architecture

Raw source data flows through three analytical layers:

```text
Sources
  ↓
Bronze: raw ingestion
  ↓
Silver: cleaning + standardization + deduplication
  ↓
Gold: business-ready facts and dimensions
  ↓
Power BI / SQL analysis
```

## Core Gold Objects

- `gold.fact_subscription_funnel` — user-level subscription funnel states.
- `gold.dim_users` — user and acquisition attributes.
- `gold.fact_user_activity_daily` — daily user activity.
- `gold.fact_revenue_monthly` — monthly revenue by user.

## Analytical Relationships

```text
dim_users
   │
   ├──────────────► fact_subscription_funnel
   │
   └──────────────► fact_user_activity_daily
                         │
                         └──► Cohort Retention

fact_revenue_monthly
   └──► New vs Expansion Revenue
```
