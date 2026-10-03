# Observed Insights

These observations were calculated from the project source data available in the existing repository package. They are descriptive findings, not causal conclusions.

## Conversion

- Total users: **10,000**
- Overall signup-to-paid conversion: **39.64%**
- Trial duration in the source data: **14 days**

## Segment Differences

### Company size

| Segment | Users | Conversion |
|---|---:|---:|
| Enterprise | 988 | 61.03% |
| Medium | 3,039 | 47.19% |
| Small | 5,973 | 32.26% |

The dataset shows a substantial conversion difference by company size. This makes company size a useful segmentation dimension for onboarding, activation and sales-assisted conversion analysis.

### Acquisition channel

| Channel | Users | Conversion |
|---|---:|---:|
| Ads | 3,498 | 39.88% |
| Referral | 1,566 | 39.85% |
| Organic | 4,936 | 39.40% |

Observed conversion is relatively similar across the three acquisition channels in this dataset. Channel analysis is therefore more useful as a monitoring dimension than as the sole explanation for conversion performance.

### Experiment variant

| Variant | Users | Conversion |
|---|---:|---:|
| A | 5,050 | 37.51% |
| B | 4,950 | 41.82% |

Variant B is **4.31 percentage points** higher than Variant A in observed conversion. The difference should be validated against the experiment's randomization, exposure, sample-size and statistical-significance assumptions before being used as evidence of a causal effect.

## Engagement

The calculated monthly stickiness averages about **13.13%** across the available activity period.

The strongest observed month is June 2024 at approximately **14.17%**, while June 2025 falls to approximately **10.07%**. This suggests a useful management question around whether the recent engagement decline is associated with customer mix, product usage patterns or changes in the event data.

## Revenue

The revenue data increasingly shifts toward existing-customer revenue after the first few months.

For example, in June 2024 the observed monthly revenue mix contains approximately:

- **$18.5K new revenue**
- **$70.8K expansion revenue**

This makes expansion revenue an important KPI for monitoring monetization depth among existing customers.

## Business Questions Created by the Findings

1. Why do enterprise users convert at a materially higher rate than small businesses?
2. Does onboarding need to differ by company size?
3. What product behavior distinguishes high-retention customers from low-retention customers?
4. Is the Variant B conversion difference statistically meaningful?
5. What explains the engagement decline observed toward the end of the activity period?
6. Which existing-customer segments are responsible for expansion revenue?

## Action Framework

The project intentionally stops short of treating correlations as recommendations. Each observation should move through:

**Finding → hypothesis → validation → action → KPI monitoring**
