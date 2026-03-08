--SETTING UP ALERTS

-- Prerequisites: Grant alert privileges to admin role
GRANT EXECUTE ALERT ON ACCOUNT TO ROLE ADMIN_ROLE;
GRANT EXECUTE MANAGED ALERT ON ACCOUNT TO ROLE ADMIN_ROLE;

-- Create alert history logging table
CREATE TABLE IF NOT EXISTS Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_LOG (
    alert_name VARCHAR,
    alert_time TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    alert_message VARCHAR
);

--COST USAGE ALERTS
-- 1. Daily Credit Threshold Alert (>20 credits/day)
CREATE OR REPLACE ALERT Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_DAILY_CREDIT_THRESHOLD
    SCHEDULE = '1440 MINUTE'
    IF (EXISTS (
        SELECT 1 FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_HISTORY
        WHERE DATE(start_time) = CURRENT_DATE() - 1
        GROUP BY DATE(start_time)
        HAVING SUM(credits_used) > 20
    ))
    THEN
        INSERT INTO Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_LOG (alert_name, alert_message)
        SELECT 'DAILY_CREDIT_THRESHOLD', 'Daily credit usage exceeded 20 credits on ' || (CURRENT_DATE() - 1);

-- 2. Warehouse Credit Spike Alert (single warehouse >5 credits/hour)
CREATE OR REPLACE ALERT Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_WAREHOUSE_CREDIT_SPIKE
    SCHEDULE = '60 MINUTE'
    IF (EXISTS (
        SELECT 1 FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
        WHERE start_time >= DATEADD(HOUR, -1, CURRENT_TIMESTAMP())
        GROUP BY warehouse_name
        HAVING SUM(credits_used) > 5
    ))
    THEN
        INSERT INTO Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_LOG (alert_name, alert_message)
        SELECT 'WAREHOUSE_CREDIT_SPIKE', 'Warehouse exceeded 5 credits in the last hour';

-- 3. Weekly Cost Increase Alert (>25% increase WoW)
CREATE OR REPLACE ALERT Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_WEEKLY_COST_INCREASE
    SCHEDULE = 'USING CRON 0 8 * * 1 America/New_York'
    IF (EXISTS (
        WITH weekly AS (
            SELECT 
                SUM(CASE WHEN start_time >= DATEADD(DAY, -7, CURRENT_DATE()) THEN credits_used ELSE 0 END) AS current_week,
                SUM(CASE WHEN start_time >= DATEADD(DAY, -14, CURRENT_DATE()) AND start_time < DATEADD(DAY, -7, CURRENT_DATE()) THEN credits_used ELSE 0 END) AS previous_week
            FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_HISTORY
            WHERE start_time >= DATEADD(DAY, -14, CURRENT_DATE())
        )
        SELECT 1 FROM weekly WHERE current_week > previous_week * 1.25 AND previous_week > 0
    ))
    THEN
        INSERT INTO Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_LOG (alert_name, alert_message)
        VALUES ('WEEKLY_COST_INCREASE', 'Weekly credit usage increased by more than 25%');

-- 4. Expensive Query Alert (query >0.5 credits)
CREATE OR REPLACE ALERT Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_EXPENSIVE_QUERY
    SCHEDULE = '30 MINUTE'
    IF (EXISTS (
        SELECT 1 FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY
        WHERE start_time >= DATEADD(MINUTE, -30, CURRENT_TIMESTAMP())
        AND credits_attributed_compute > 0.5
    ))
    THEN
        INSERT INTO Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_LOG (alert_name, alert_message)
        SELECT 'EXPENSIVE_QUERY', 'Query consumed more than 0.5 credits in the last 30 minutes';

-- 5. Storage Growth Alert (>10% daily increase)
CREATE OR REPLACE ALERT Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_STORAGE_GROWTH
    SCHEDULE = '1440 MINUTE'
    IF (EXISTS (
        WITH storage AS (
            SELECT 
                SUM(CASE WHEN usage_date = CURRENT_DATE() - 1 THEN average_database_bytes ELSE 0 END) AS today_bytes,
                SUM(CASE WHEN usage_date = CURRENT_DATE() - 2 THEN average_database_bytes ELSE 0 END) AS yesterday_bytes
            FROM SNOWFLAKE.ACCOUNT_USAGE.DATABASE_STORAGE_USAGE_HISTORY
            WHERE usage_date >= CURRENT_DATE() - 2
        )
        SELECT 1 FROM storage WHERE today_bytes > yesterday_bytes * 1.10 AND yesterday_bytes > 0
    ))
    THEN
        INSERT INTO Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_LOG (alert_name, alert_message)
        VALUES ('STORAGE_GROWTH', 'Storage increased by more than 10% in the last day');

-- 6. Resource Monitor Near Limit Alert (>80% utilization)
CREATE OR REPLACE ALERT Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_RESOURCE_MONITOR_WARNING
    SCHEDULE = '60 MINUTE'
    IF (EXISTS (
        SELECT 1 FROM SNOWFLAKE.ACCOUNT_USAGE.RESOURCE_MONITORS
        WHERE used_credits / NULLIF(credit_quota, 0) > 0.80
    ))
    THEN
        INSERT INTO Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_LOG (alert_name, alert_message)
        SELECT 'RESOURCE_MONITOR_WARNING', 'Resource monitor exceeded 80% utilization';

--QUEUE AND PERFOMANCE ALERTS

-- 7. Long Running Query Alert (>10 minutes)
CREATE OR REPLACE ALERT Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_LONG_RUNNING_QUERY
    SCHEDULE = '15 MINUTE'
    IF (EXISTS (
        SELECT 1 FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE start_time >= DATEADD(MINUTE, -15, CURRENT_TIMESTAMP())
        AND total_elapsed_time > 600000
        AND execution_status = 'SUCCESS'
    ))
    THEN
        INSERT INTO Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_LOG (alert_name, alert_message)
        SELECT 'LONG_RUNNING_QUERY', 'Query ran longer than 10 minutes';

-- 8. Query Queue Time Alert (>60 seconds queued)
CREATE OR REPLACE ALERT Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_QUERY_QUEUE_TIME
    SCHEDULE = '15 MINUTE'
    IF (EXISTS (
        SELECT 1 FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE start_time >= DATEADD(MINUTE, -15, CURRENT_TIMESTAMP())
        AND queued_overload_time > 60000
    ))
    THEN
        INSERT INTO Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_LOG (alert_name, alert_message)
        SELECT 'QUERY_QUEUE_TIME', 'Queries queued for more than 60 seconds due to warehouse overload';

-- 9. Failed Query Alert (multiple failures)
CREATE OR REPLACE ALERT Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_FAILED_QUERIES
    SCHEDULE = '30 MINUTE'
    IF (EXISTS (
        SELECT 1 FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE start_time >= DATEADD(MINUTE, -30, CURRENT_TIMESTAMP())
        AND execution_status = 'FAIL'
        GROUP BY warehouse_name
        HAVING COUNT(*) > 5
    ))
    THEN
        INSERT INTO Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_LOG (alert_name, alert_message)
        SELECT 'FAILED_QUERIES', 'More than 5 query failures in the last 30 minutes';

-- 10. Warehouse Idle Alert (warehouse running with no queries for 30+ min)
CREATE OR REPLACE ALERT Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_WAREHOUSE_IDLE
    SCHEDULE = '30 MINUTE'
    IF (EXISTS (
        WITH active_warehouses AS (
            SELECT warehouse_name FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
            WHERE start_time >= DATEADD(MINUTE, -30, CURRENT_TIMESTAMP())
            AND credits_used > 0
        ),
        query_activity AS (
            SELECT DISTINCT warehouse_name FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
            WHERE start_time >= DATEADD(MINUTE, -30, CURRENT_TIMESTAMP())
        )
        SELECT 1 FROM active_warehouses aw
        LEFT JOIN query_activity qa ON aw.warehouse_name = qa.warehouse_name
        WHERE qa.warehouse_name IS NULL
    ))
    THEN
        INSERT INTO Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_LOG (alert_name, alert_message)
        SELECT 'WAREHOUSE_IDLE', 'Warehouse consuming credits with no query activity';

-- 11. High Concurrency Alert (>50 concurrent queries)
CREATE OR REPLACE ALERT Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_HIGH_CONCURRENCY
    SCHEDULE = '15 MINUTE'
    IF (EXISTS (
        SELECT 1 FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE start_time >= DATEADD(MINUTE, -15, CURRENT_TIMESTAMP())
        GROUP BY DATE_TRUNC('MINUTE', start_time), warehouse_name
        HAVING COUNT(*) > 50
    ))
    THEN
        INSERT INTO Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_LOG (alert_name, alert_message)
        SELECT 'HIGH_CONCURRENCY', 'More than 50 concurrent queries detected on a warehouse';

-- 12. Data Transfer Spike Alert (>1GB transferred)
CREATE OR REPLACE ALERT Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_DATA_TRANSFER_SPIKE
    SCHEDULE = '60 MINUTE'
    IF (EXISTS (
        SELECT 1 FROM SNOWFLAKE.ACCOUNT_USAGE.DATA_TRANSFER_HISTORY
        WHERE start_time >= DATEADD(HOUR, -1, CURRENT_TIMESTAMP())
        GROUP BY target_region
        HAVING SUM(bytes_transferred) > 1073741824
    ))
    THEN
        INSERT INTO Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_LOG (alert_name, alert_message)
        SELECT 'DATA_TRANSFER_SPIKE', 'Data transfer exceeded 1GB in the last hour';

-- =============================================================================
-- RESUME ALL ALERTS
-- =============================================================================

ALTER ALERT Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_DAILY_CREDIT_THRESHOLD RESUME;
ALTER ALERT Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_WAREHOUSE_CREDIT_SPIKE RESUME;
ALTER ALERT Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_WEEKLY_COST_INCREASE RESUME;
ALTER ALERT Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_EXPENSIVE_QUERY RESUME;
ALTER ALERT Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_STORAGE_GROWTH RESUME;
ALTER ALERT Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_RESOURCE_MONITOR_WARNING RESUME;
ALTER ALERT Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_LONG_RUNNING_QUERY RESUME;
ALTER ALERT Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_QUERY_QUEUE_TIME RESUME;
ALTER ALERT Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_FAILED_QUERIES RESUME;
ALTER ALERT Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_WAREHOUSE_IDLE RESUME;
ALTER ALERT Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_HIGH_CONCURRENCY RESUME;
ALTER ALERT Healthcare_DB.GOVERNANCE_SCHEMA.ALERT_DATA_TRANSFER_SPIKE RESUME;

-- Verification
SHOW ALERTS IN SCHEMA Healthcare_DB.GOVERNANCE_SCHEMA;