# Power BI Enhancement Specification

The existing PBIX should be evolved into a decision-oriented dashboard with four pages.

## 1. Executive Overview

### KPI cards
- Total Users
- Conversion Rate
- Trial Drop-off Rate
- Retention Rate
- Stickiness
- Total Revenue
- New Revenue
- Expansion Revenue

### Visuals
- Monthly conversion trend
- Monthly stickiness trend
- New vs expansion revenue
- Acquisition channel conversion
- Company-size conversion

## 2. Funnel Diagnosis

Visualize:

Signup → Trial Start → Trial Completion → Paid

Add stage-to-stage conversion rates and absolute drop-off counts.

Recommended slicers:
- Signup month
- Acquisition channel
- Company size
- Country
- Experiment variant

## 3. Retention & Engagement

Include:
- Cohort retention heatmap
- DAU trend
- MAU trend
- Stickiness trend
- Activity by company size

## 4. Experiment & Segmentation

Include:
- Variant A vs B conversion
- Conversion by company size
- Conversion by acquisition channel
- Conversion by country
- Segment matrix

### Recommended interaction

Selecting a segment should cross-filter the funnel, retention and revenue views.

## Business-facing design principle

Each page should answer a question, not just display a metric:

**What happened? → Where did it happen? → Who/which segment is involved? → What should be investigated next?**

## Note

The repository enhancement includes the SQL and documentation required to support these pages. The binary PBIX itself should be updated in Power BI Desktop using the new gold views.
