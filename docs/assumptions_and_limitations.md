# Assumptions & Limitations

## Assumptions
- Users with a recorded subscription start date are treated as converted.
- Activity records represent product usage events suitable for DAU/MAU calculations.
- Revenue is grouped by month for product-growth analysis.
- A user's first revenue month is treated as their acquisition revenue month.

## Limitations
- The dataset is analytical/synthetic rather than a production source system.
- Marketing spend is unavailable, so CAC and ROAS are outside the current scope.
- Refunds, chargebacks and accounting adjustments are not modelled unless present in source data.
- Cohort retention measures recorded activity, not necessarily paid status.
- Experiment-variant comparisons are descriptive unless randomization, exposure and sample-size assumptions are validated.
