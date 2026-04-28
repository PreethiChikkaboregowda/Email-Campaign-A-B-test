-- Query 1 — Full Funnel Overview (Start Here)
-- Gives the complete picture before drilling into individual metrics
SELECT
  `group`,
  COUNT(*) AS total_sent,
  SUM(email_opened) AS total_opened,
  SUM(email_clicked) AS total_clicked,
  SUM(converted) AS total_converted,
  ROUND(SUM(email_opened) / COUNT(*) * 100, 2) AS open_rate_pct,
  ROUND(SUM(email_clicked) / COUNT(*) * 100, 2) AS ctr_pct,
  ROUND(SUM(converted) / COUNT(*) * 100, 2) AS conv_rate_pct,
  ROUND(SUM(order_value), 2) AS total_revenue
FROM `email-campaign-494507.email_campaign_data.email_ab_test`
GROUP BY `group`
ORDER BY `group`;


-- Query 2 — Open Rate by Variant
-- First touchpoint in the funnel — did the subject line get attention?
SELECT
  `group`,
  COUNT(*) AS total_sent,
  SUM(email_opened) AS total_opened,
  ROUND(SUM(email_opened) / COUNT(*) * 100, 2) AS open_rate_pct
FROM `email-campaign-494507.email_campaign_data.email_ab_test`
GROUP BY `group`
ORDER BY `group`;

-- Query 3 — CTR by Variant, Primary KPI
-- Main success metric — did personalisation drive more clicks?
SELECT
  `group`,
  COUNT(*) AS total_sent,
  SUM(email_clicked) AS total_clicked,
  ROUND(SUM(email_clicked) / COUNT(*) * 100, 2) AS ctr_pct
FROM `email-campaign-494507.email_campaign_data.email_ab_test`
GROUP BY `group`
ORDER BY `group`;

-- Query 4 — Conversion Rate After Click
-- Measures post-click quality — do clicks actually turn into purchases?
SELECT
  `group`,
  SUM(email_clicked) AS total_clicked,
  SUM(converted) AS total_converted,
  ROUND(SUM(converted) / SUM(email_clicked) * 100, 2) AS conversion_rate_pct
FROM `email-campaign-494507.email_campaign_data.email_ab_test`
GROUP BY `group`
ORDER BY `group`;

-- Query 5 — Revenue by Variant
-- Translates engagement metrics into business value
SELECT
  `group`,
  SUM(converted) AS total_conversions,
  ROUND(SUM(order_value), 2) AS total_revenue,
  ROUND(AVG(CASE WHEN converted = 1 THEN order_value END), 2) AS avg_order_value
FROM `email-campaign-494507.email_campaign_data.email_ab_test`
GROUP BY `group`
ORDER BY `group`;

-- Query 6 — CTR Lift by Device Type
-- Identifies which device segment benefits most from personalisation
WITH base AS (
  SELECT
    device_type,
    `group`,
    ROUND(SUM(email_clicked) / COUNT(*) * 100, 2) AS ctr_pct
  FROM `email-campaign-494507.email_campaign_data.email_ab_test`
  GROUP BY device_type, `group`
)
SELECT
  device_type,
  MAX(CASE WHEN `group` = 'control' THEN ctr_pct END) AS control_ctr,
  MAX(CASE WHEN `group` = 'variant' THEN ctr_pct END) AS variant_ctr,
  ROUND(MAX(CASE WHEN `group` = 'variant' THEN ctr_pct END) -
        MAX(CASE WHEN `group` = 'control' THEN ctr_pct END), 2) AS ctr_lift_pp
FROM base
GROUP BY device_type
ORDER BY ctr_lift_pp DESC;

-- Query 7 — Revenue Efficiency by Segment
-- Revenue per email sent is a fairer comparison than total revenue
SELECT
  `group`,
  customer_segment,
  COUNT(*) AS emails_sent,
  ROUND(SUM(order_value), 2) AS total_revenue,
  ROUND(SUM(order_value) / COUNT(*), 4) AS revenue_per_email,
  ROUND(AVG(CASE WHEN converted = 1 THEN order_value END), 2) AS avg_order_value
FROM `email-campaign-494507.email_campaign_data.email_ab_test`
GROUP BY `group`, customer_segment
ORDER BY customer_segment, `group`;

-- Query 8 — Weekly CTR Trend
-- Did the variant's advantage hold, grow, or shrink over time?
SELECT
  DATE_TRUNC(sent_at, WEEK) AS week_start,
  `group`,
  COUNT(*) AS total_sent,
  ROUND(SUM(email_clicked) / COUNT(*) * 100, 2) AS ctr_pct
FROM `email-campaign-494507.email_campaign_data.email_ab_test`
GROUP BY week_start, `group`
ORDER BY week_start, `group`;

-- Query 9 — Time to Click Analysis
-- Faster clicks signal stronger intent — not just higher volume
SELECT
  `group`,
  ROUND(AVG(TIMESTAMP_DIFF(clicked_at, sent_at, MINUTE)), 1) AS avg_mins_to_click,
  ROUND(MIN(TIMESTAMP_DIFF(clicked_at, sent_at, MINUTE)), 1) AS fastest_click_mins,
  ROUND(MAX(TIMESTAMP_DIFF(clicked_at, sent_at, MINUTE)), 1) AS slowest_click_mins
FROM `email-campaign-494507.email_campaign_data.email_ab_test`
WHERE email_clicked = 1
GROUP BY `group`;
