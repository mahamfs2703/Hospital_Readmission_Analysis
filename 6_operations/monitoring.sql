--CREATING VIEWS FOR MONITORING CREDIT USAGE

-- 1. Overall Credit Consumption by Service Type
CREATE OR REPLACE VIEW Healthcare_DB.GOVERNANCE_SCHEMA.V_CREDIT_CONSUMPTION_SUMMARY AS
WITH base AS (
SELECT
service_type,
SUM(credits_used) AS total_credits
FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_HISTORY
WHERE start_time >= DATEADD(DAY,-30,CURRENT_DATE())
GROUP BY service_type
)

SELECT
service_type,
ROUND(total_credits,2) AS total_credits,
ROUND(total_credits / SUM(total_credits) OVER() * 100,1) AS pct_of_total
FROM base
ORDER BY total_credits DESC;

-- 2. Daily Credit Usage Trend
CREATE OR REPLACE VIEW Healthcare_DB.GOVERNANCE_SCHEMA.V_DAILY_CREDIT_TREND AS
SELECT
DATE(start_time) AS usage_date,
ROUND(SUM(credits_used),2) AS daily_credits,
ROUND(SUM(credits_used_compute),2) AS compute_credits,
ROUND(SUM(credits_used_cloud_services),2) AS cloud_credits
FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_HISTORY
WHERE start_time >= DATEADD(DAY,-30,CURRENT_DATE())
GROUP BY DATE(start_time)
ORDER BY usage_date DESC;

-- 3. Warehouse Credit Consumption
CREATE OR REPLACE VIEW Healthcare_DB.GOVERNANCE_SCHEMA.V_WAREHOUSE_CREDIT_USAGE AS
SELECT
warehouse_name,
ROUND(SUM(credits_used),2) AS total_credits,
ROUND(AVG(credits_used),4) AS avg_hourly_credits,
COUNT(*) AS active_hours,
MIN(start_time) AS first_usage,
MAX(start_time) AS last_usage
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE start_time >= DATEADD(DAY,-30,CURRENT_DATE())
GROUP BY warehouse_name
ORDER BY total_credits DESC;

-- 4. Top Expensive Queries
CREATE OR REPLACE VIEW Healthcare_DB.GOVERNANCE_SCHEMA.V_TOP_EXPENSIVE_QUERIES AS
SELECT
qa.query_id,
qh.warehouse_name,
qh.user_name,
ROUND(SUM(qa.credits_attributed_compute),4) AS credits_used,
qh.start_time,
ROUND(qh.total_elapsed_time/1000,2) AS duration_sec,
LEFT(qh.query_text,200) AS query_preview
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY qa
JOIN SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY qh
ON qa.query_id = qh.query_id
WHERE qa.start_time >= DATEADD(DAY,-7,CURRENT_DATE())
GROUP BY qa.query_id,qh.warehouse_name,qh.user_name,qh.start_time,qh.total_elapsed_time,qh.query_text
ORDER BY credits_used DESC
LIMIT 100;

-- 5. User Credit Consumption
CREATE OR REPLACE VIEW Healthcare_DB.GOVERNANCE_SCHEMA.V_USER_CREDIT_CONSUMPTION AS
SELECT
user_name,
COUNT(DISTINCT query_id) AS query_count,
ROUND(SUM(credits_attributed_compute),2) AS total_credits,
ROUND(AVG(credits_attributed_compute),4) AS avg_credits_per_query
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY
WHERE start_time >= DATEADD(DAY,-30,CURRENT_DATE())
GROUP BY user_name
ORDER BY total_credits DESC;

-- 6. Database Storage Usage
CREATE OR REPLACE VIEW Healthcare_DB.GOVERNANCE_SCHEMA.V_DATABASE_STORAGE_USAGE AS
SELECT
database_name,
ROUND(average_database_bytes/POWER(1024,3),2) AS storage_gb,
ROUND(average_failsafe_bytes/POWER(1024,3),2) AS failsafe_gb,
ROUND((average_database_bytes+average_failsafe_bytes)/POWER(1024,3),2) AS total_gb
FROM SNOWFLAKE.ACCOUNT_USAGE.DATABASE_STORAGE_USAGE_HISTORY
WHERE usage_date = (
SELECT MAX(usage_date)
FROM SNOWFLAKE.ACCOUNT_USAGE.DATABASE_STORAGE_USAGE_HISTORY
);

-- 7. Cost Anomaly Detection
CREATE OR REPLACE VIEW Healthcare_DB.GOVERNANCE_SCHEMA.V_COST_ANOMALIES AS
SELECT
date AS anomaly_date,
ROUND(actual_value,2) AS actual_credits,
ROUND(forecasted_value,2) AS forecasted_credits,
ROUND(actual_value-forecasted_value,2) AS variance,
ROUND((actual_value-forecasted_value)/NULLIF(forecasted_value,0)*100,2) AS variance_pct
FROM SNOWFLAKE.ACCOUNT_USAGE.ANOMALIES_DAILY
WHERE is_anomaly = TRUE
AND date >= DATEADD(DAY,-30,CURRENT_DATE())
ORDER BY date DESC;
-- 8. Week-over-Week Comparison
CREATE OR REPLACE VIEW Healthcare_DB.GOVERNANCE_SCHEMA.V_WEEK_OVER_WEEK_COMPARISON AS

SELECT 'current_week' AS period,
ROUND(SUM(credits_used),2) AS total_credits
FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_HISTORY
WHERE start_time >= DATEADD(DAY,-7,CURRENT_DATE())
AND start_time < CURRENT_DATE()

UNION ALL

SELECT 'previous_week',
ROUND(SUM(credits_used),2)
FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_HISTORY
WHERE start_time >= DATEADD(DAY,-14,CURRENT_DATE())
AND start_time < DATEADD(DAY,-7,CURRENT_DATE());

-- 9. Hourly Consumption Pattern
CREATE OR REPLACE VIEW Healthcare_DB.GOVERNANCE_SCHEMA.V_HOURLY_CONSUMPTION_PATTERN AS
SELECT
HOUR(start_time) AS hour_of_day,
ROUND(AVG(credits_used),4) AS avg_credits,
ROUND(MAX(credits_used),4) AS peak_credits,
COUNT(DISTINCT DATE(start_time)) AS days_sampled
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE start_time >= DATEADD(DAY,-30,CURRENT_DATE())
GROUP BY HOUR(start_time)
ORDER BY hour_of_day;

-- 10. Query Type Distribution
CREATE OR REPLACE VIEW Healthcare_DB.GOVERNANCE_SCHEMA.V_QUERY_TYPE_DISTRIBUTION AS
SELECT
query_type,
COUNT(*) AS query_count,
ROUND(AVG(total_elapsed_time)/1000,2) AS avg_duration_sec,
ROUND(SUM(bytes_scanned)/POWER(1024,3),2) AS total_gb_scanned,
ROUND(AVG(rows_produced),0) AS avg_rows_produced
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE start_time >= DATEADD(DAY,-30,CURRENT_DATE())
GROUP BY query_type
ORDER BY query_count DESC;

-- 11. Data Transfer Monitoring
CREATE OR REPLACE VIEW Healthcare_DB.GOVERNANCE_SCHEMA.V_DATA_TRANSFER_USAGE AS
SELECT
DATE(start_time) AS transfer_date,
source_region,
target_region,
transfer_type,
ROUND(SUM(bytes_transferred)/POWER(1024,3),2) AS gb_transferred
FROM SNOWFLAKE.ACCOUNT_USAGE.DATA_TRANSFER_HISTORY
WHERE start_time >= DATEADD(DAY,-30,CURRENT_DATE())
GROUP BY DATE(start_time),source_region,target_region,transfer_type
ORDER BY transfer_date DESC,gb_transferred DESC;

-- 12. Resource Monitor Utilization
CREATE OR REPLACE VIEW Healthcare_DB.GOVERNANCE_SCHEMA.V_RESOURCE_MONITOR_STATUS AS
SELECT
name AS monitor_name,
credit_quota,
used_credits,
remaining_credits,
ROUND(used_credits/NULLIF(credit_quota,0)*100,2) AS utilization_pct,
notify,
suspend,
suspend_immediate,
warehouses,
owner
FROM SNOWFLAKE.ACCOUNT_USAGE.RESOURCE_MONITORS;

-- Verification
SHOW VIEWS IN SCHEMA Healthcare_DB.GOVERNANCE_SCHEMA;