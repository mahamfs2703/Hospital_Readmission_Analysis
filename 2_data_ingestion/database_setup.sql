-- =============================================================================
-- CREATING DATABASES
-- =============================================================================

--CREATE OR REPLACE DATABASE Healthcare_DB;

-- =============================================================================
-- CREATING SCHEMAS (MEDALLION ARCHITECTURE)
-- =============================================================================

CREATE OR REPLACE SCHEMA Healthcare_DB.RAW_SCHEMA;        -- Bronze Layer
CREATE OR REPLACE SCHEMA Healthcare_DB.TRANSFORM_SCHEMA;  -- Silver Layer
CREATE OR REPLACE SCHEMA Healthcare_DB.ANALYTICS_SCHEMA;  -- Gold Layer

CREATE OR REPLACE SCHEMA Healthcare_DB.GOVERNANCE_SCHEMA;

-- =============================================================================
-- GRANTING DATABASE USAGE
-- =============================================================================

GRANT USAGE ON DATABASE Healthcare_DB TO ROLE Data_Ingest_Role;
GRANT USAGE ON DATABASE Healthcare_DB TO ROLE Data_Transform_Role;
GRANT USAGE ON DATABASE Healthcare_DB TO ROLE Data_Analyst_Role;
GRANT USAGE ON DATABASE Healthcare_DB TO ROLE Data_Engineer_Role;


-- =============================================================================
-- PRIVILEGES FOR RAW_SCHEMA (BRONZE LAYER)
-- =============================================================================

GRANT USAGE ON SCHEMA Healthcare_DB.RAW_SCHEMA TO ROLE Data_Ingest_Role;

GRANT SELECT ON ALL TABLES IN SCHEMA Healthcare_DB.RAW_SCHEMA TO ROLE Data_Ingest_Role;
GRANT SELECT ON FUTURE TABLES IN SCHEMA Healthcare_DB.RAW_SCHEMA TO ROLE Data_Ingest_Role;


-- =============================================================================
-- PRIVILEGES FOR TRANSFORM_SCHEMA (SILVER LAYER)
-- =============================================================================

GRANT USAGE ON SCHEMA Healthcare_DB.TRANSFORM_SCHEMA TO ROLE Data_Transform_Role;

GRANT SELECT ON ALL TABLES IN SCHEMA Healthcare_DB.TRANSFORM_SCHEMA TO ROLE Data_Transform_Role;
GRANT SELECT ON FUTURE TABLES IN SCHEMA Healthcare_DB.TRANSFORM_SCHEMA TO ROLE Data_Transform_Role;


-- =============================================================================
-- PRIVILEGES FOR ANALYTICS_SCHEMA (GOLD LAYER)
-- =============================================================================

GRANT USAGE ON SCHEMA Healthcare_DB.ANALYTICS_SCHEMA TO ROLE Data_Analyst_Role;

GRANT SELECT ON ALL TABLES IN SCHEMA Healthcare_DB.ANALYTICS_SCHEMA TO ROLE Data_Analyst_Role;
GRANT SELECT ON FUTURE TABLES IN SCHEMA Healthcare_DB.ANALYTICS_SCHEMA TO ROLE Data_Analyst_Role;


-- =============================================================================
-- DATA ENGINEER ROLE PRIVILEGES
-- =============================================================================

-- BRONZE LAYER
GRANT CREATE TABLE, CREATE VIEW ON SCHEMA Healthcare_DB.RAW_SCHEMA TO ROLE Data_Engineer_Role;

GRANT INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN SCHEMA Healthcare_DB.RAW_SCHEMA TO ROLE Data_Engineer_Role;
GRANT INSERT, UPDATE, DELETE, TRUNCATE ON FUTURE TABLES IN SCHEMA Healthcare_DB.RAW_SCHEMA TO ROLE Data_Engineer_Role;


-- SILVER LAYER
GRANT CREATE TABLE, CREATE VIEW ON SCHEMA Healthcare_DB.TRANSFORM_SCHEMA TO ROLE Data_Engineer_Role;

GRANT INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN SCHEMA Healthcare_DB.TRANSFORM_SCHEMA TO ROLE Data_Engineer_Role;
GRANT INSERT, UPDATE, DELETE, TRUNCATE ON FUTURE TABLES IN SCHEMA Healthcare_DB.TRANSFORM_SCHEMA TO ROLE Data_Engineer_Role;


-- =============================================================================
-- ADMIN ROLE PRIVILEGES
-- =============================================================================

GRANT ALL PRIVILEGES ON SCHEMA Healthcare_DB.RAW_SCHEMA TO ROLE ADMIN_ROLE;
GRANT ALL PRIVILEGES ON SCHEMA Healthcare_DB.TRANSFORM_SCHEMA TO ROLE ADMIN_ROLE;
GRANT ALL PRIVILEGES ON SCHEMA Healthcare_DB.ANALYTICS_SCHEMA TO ROLE ADMIN_ROLE;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA Healthcare_DB.ANALYTICS_SCHEMA TO ROLE ADMIN_ROLE;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA Healthcare_DB.ANALYTICS_SCHEMA TO ROLE ADMIN_ROLE;

------------------------------------------------------------------------------
--ADDITIONAL PRIVILEGES ON ANALYTICS_SCHEMA FOR DATA ANALYST ROLE
GRANT USAGE ON DATABASE HEALTHCARE_DB TO ROLE DATA_ANALYST_ROLE;
GRANT USAGE ON SCHEMA HEALTHCARE_DB.TRANSFORM_SCHEMA TO ROLE DATA_ANALYST_ROLE;
GRANT SELECT ON ALL TABLES IN SCHEMA HEALTHCARE_DB.TRANSFORM_SCHEMA TO ROLE DATA_ANALYST_ROLE;
GRANT USAGE ON SCHEMA HEALTHCARE_DB.ANALYTICS_SCHEMA TO ROLE DATA_ANALYST_ROLE;
GRANT CREATE TABLE ON SCHEMA HEALTHCARE_DB.ANALYTICS_SCHEMA TO ROLE DATA_ANALYST_ROLE;
GRANT USAGE ON WAREHOUSE DATA_ANALYTICS_WH TO ROLE DATA_ANALYST_ROLE;
-- =============================================================================
-- VERIFY ROLE PRIVILEGES
-- =============================================================================

SHOW GRANTS TO ROLE ADMIN_ROLE;
SHOW GRANTS TO ROLE Data_Engineer_Role;
SHOW GRANTS TO ROLE Data_Analyst_Role;