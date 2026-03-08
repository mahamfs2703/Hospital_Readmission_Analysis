--CREATING WAREHOUSES
-- Warehouse for data ingestion (Bronze layer ETL)
CREATE OR REPLACE WAREHOUSE Data_Ingest_WH
    WAREHOUSE_SIZE = 'SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Warehouse for raw data ingestion into Bronze layer';

-- Warehouse for data transformation (Silver layer processing)
CREATE OR REPLACE WAREHOUSE Data_Transform_WH
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 120
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Warehouse for data transformation and cleansing';

-- Warehouse for data science work (Gold layer)
CREATE OR REPLACE WAREHOUSE Data_Analytics_WH
    WAREHOUSE_SIZE = 'LARGE'
    AUTO_SUSPEND = 180
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Warehouse for data analysis';


--GRANTING PRIVILES ON WAREHOUSE TO ROLES
GRANT USAGE ON WAREHOUSE Data_Ingest_WH TO ROLE Data_Ingest_Role;
GRANT USAGE ON WAREHOUSE Data_Transform_WH TO ROLE Data_Transform_Role;
GRANT USAGE ON WAREHOUSE Data_Analytics_WH TO ROLE Data_Analyst_Role;

-- Data Engineer gets access to ingestion and transformation warehouses
GRANT USAGE, OPERATE ON WAREHOUSE Data_Ingest_WH TO ROLE Data_Engineer_Role;
GRANT USAGE, OPERATE ON WAREHOUSE Data_Transform_WH TO ROLE Data_Engineer_Role;

-- Admin gets full control on all warehouses
GRANT ALL PRIVILEGES ON WAREHOUSE Data_Ingest_WH TO ROLE Admin_Role;
GRANT ALL PRIVILEGES ON WAREHOUSE Data_Transform_WH TO ROLE Admin_Role;
GRANT ALL PRIVILEGES ON WAREHOUSE Data_Analytics_WH TO ROLE Admin_Role;

-- Verification
SHOW WAREHOUSES LIKE '%_WH';