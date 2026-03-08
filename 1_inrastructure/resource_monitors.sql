-- =============================================================================
-- RESOURCE MONITORS FOR CMS HOSPITAL READMISSION PROJECT
-- =============================================================================

-- -----------------------------------------------------------------------------
-- INGEST WAREHOUSE RESOURCE MONITOR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE RESOURCE MONITOR Data_Ingest_RM
WITH CREDIT_QUOTA = 5
FREQUENCY = DAILY
START_TIMESTAMP = IMMEDIATELY
TRIGGERS 
ON 75 PERCENT DO NOTIFY
ON 80 PERCENT DO SUSPEND
ON 95 PERCENT DO SUSPEND_IMMEDIATE;

-- Attach monitor to warehouse
ALTER WAREHOUSE Data_Ingest_WH
SET RESOURCE_MONITOR = Data_Ingest_RM;


-- -----------------------------------------------------------------------------
-- TRANSFORM WAREHOUSE RESOURCE MONITOR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE RESOURCE MONITOR Data_Transform_RM
WITH CREDIT_QUOTA = 10
FREQUENCY = DAILY
START_TIMESTAMP = IMMEDIATELY
TRIGGERS
ON 75 PERCENT DO NOTIFY
ON 80 PERCENT DO SUSPEND
ON 95 PERCENT DO SUSPEND_IMMEDIATE;

ALTER WAREHOUSE Data_Transform_WH
SET RESOURCE_MONITOR = Data_Transform_RM;


-- -----------------------------------------------------------------------------
-- ANALYTICS WAREHOUSE RESOURCE MONITOR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE RESOURCE MONITOR Data_Analytics_RM
WITH CREDIT_QUOTA = 15
FREQUENCY = DAILY
START_TIMESTAMP = IMMEDIATELY
TRIGGERS
ON 75 PERCENT DO NOTIFY
ON 80 PERCENT DO SUSPEND
ON 95 PERCENT DO SUSPEND_IMMEDIATE;

ALTER WAREHOUSE Data_Analytics_WH
SET RESOURCE_MONITOR = Data_Analytics_RM;


-- -----------------------------------------------------------------------------
-- ACCOUNT LEVEL RESOURCE MONITOR
-- -----------------------------------------------------------------------------
CREATE OR REPLACE RESOURCE MONITOR Data_Account_RM
WITH CREDIT_QUOTA = 50
FREQUENCY = DAILY
START_TIMESTAMP = IMMEDIATELY
TRIGGERS
ON 75 PERCENT DO NOTIFY
ON 80 PERCENT DO SUSPEND
ON 95 PERCENT DO SUSPEND_IMMEDIATE;