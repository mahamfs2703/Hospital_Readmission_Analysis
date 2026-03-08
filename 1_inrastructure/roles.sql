-- =============================================================================
-- ROLE SETUP FOR CMS HOSPITAL READMISSION ANALYSIS PROJECT
-- =============================================================================

-- CREATING ROLES

CREATE OR REPLACE ROLE Data_Ingest_Role;
-- Responsible for ingesting CMS raw datasets (BRONZE LAYER)

CREATE OR REPLACE ROLE Data_Transform_Role;
-- Responsible for cleaning and transforming CMS data (SILVER LAYER)

CREATE OR REPLACE ROLE Data_Analyst_Role;
-- Responsible for building readmission KPIs and analytical models (GOLD LAYER)

CREATE OR REPLACE ROLE Data_Engineer_Role;
-- Responsible for building ELT pipelines and managing data workflows

CREATE OR REPLACE ROLE Admin_Role;
-- Full administrative control over the project environment


-- =============================================================================
-- ROLE HIERARCHY
-- Higher roles inherit privileges from lower roles
-- =============================================================================

GRANT ROLE Data_Ingest_Role TO ROLE Data_Transform_Role;
GRANT ROLE Data_Transform_Role TO ROLE Data_Analyst_Role;
GRANT ROLE Data_Analyst_Role TO ROLE Data_Engineer_Role;
GRANT ROLE Data_Engineer_Role TO ROLE Admin_Role;
GRANT ROLE Admin_Role TO ROLE SYSADMIN;