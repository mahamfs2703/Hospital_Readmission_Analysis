# Deployment Guide - Hospital Readmission Accelerator

## Prerequisites

- Snowflake account with **ACCOUNTADMIN** role access
- CMS data files uploaded to a Snowflake stage (see Step 2)
- Estimated deployment time: **15-20 minutes**

---

## Step 1: Environment Setup

Run each script in order using the **ACCOUNTADMIN** role.

```
USE ROLE ACCOUNTADMIN;
```

| Order | Script | What It Does |
|-------|--------|--------------|
| 1.1 | `01_setup/01_create_roles.sql` | Creates 5 roles: Data_Ingest_Role, Data_Transform_Role, Data_Analyst_Role, Data_Engineer_Role, Admin_Role with hierarchy |
| 1.2 | `01_setup/02_create_database.sql` | Creates HEALTHCARE_DB |
| 1.3 | `01_setup/03_create_schema.sql` | Creates RAW_SCHEMA (Bronze), TRANSFORM_SCHEMA (Silver), ANALYTICS_SCHEMA (Gold), GOVERNANCE_SCHEMA; grants all privileges |
| 1.4 | `01_setup/04_create_warehouse.sql` | Creates Data_Ingest_WH (S), Data_Transform_WH (M), Data_Analytics_WH (L) with auto-suspend; grants usage to roles |
| 1.5 | `01_setup/05_create_resource_monitors.sql` | Creates resource monitors for each warehouse + account-level monitor (daily quotas: 5/10/15/50 credits) |
| 1.6 | `01_setup/06_create_file_format.sql` | Creates CMS_CSV_FORMAT with MM/DD/YYYY dates, NULL handling for CMS values |

**Verification:**
```sql
SHOW ROLES LIKE '%ROLE';
SHOW WAREHOUSES LIKE '%_WH';
SHOW SCHEMAS IN DATABASE HEALTHCARE_DB;
```

---

## Step 2: Data Ingestion (Bronze Layer)

Upload the 6 CMS CSV files to the stage, then load into raw tables.

| Order | Script | What It Does |
|-------|--------|--------------|
| 2.1 | `02_ingestion/create_raw_tables.sql` | Creates 6 raw tables: FACILITIES, READMISSION_METRICS, COST_ANALYTICS, COMPLICATIONS_AND_DEATHS_HOSPITAL, PATIENT_SURVEY, ENCOUNTERS |
| 2.2 | `02_ingestion/load_cms_data.sql` | COPY INTO from @RAW_STAGE for all 6 CSV files |

**Before running 2.2**, ensure the CMS files are in the stage:
```sql
LIST @HEALTHCARE_DB.RAW_SCHEMA.RAW_STAGE;
```

Expected files:
- `Hospital_General_Information.csv`
- `HRRP (Hospital_Readmission_ReductionProgram).csv`
- `Medicare Spending Per Beneficiary.csv`
- `Complications_and_Deaths-Hospital.csv`
- `HCAHPS_Patient_Survey_Hospital.csv`
- `Timely_and_Effective_Care-Hospital.csv`

**Verification:**
```sql
SELECT 'FACILITIES' AS TBL, COUNT(*) AS ROWS FROM HEALTHCARE_DB.RAW_SCHEMA.FACILITIES
UNION ALL SELECT 'READMISSION_METRICS', COUNT(*) FROM HEALTHCARE_DB.RAW_SCHEMA.READMISSION_METRICS
UNION ALL SELECT 'COST_ANALYTICS', COUNT(*) FROM HEALTHCARE_DB.RAW_SCHEMA.COST_ANALYTICS
UNION ALL SELECT 'COMPLICATIONS', COUNT(*) FROM HEALTHCARE_DB.RAW_SCHEMA.COMPLICATIONS_AND_DEATHS_HOSPITAL
UNION ALL SELECT 'PATIENT_SURVEY', COUNT(*) FROM HEALTHCARE_DB.RAW_SCHEMA.PATIENT_SURVEY
UNION ALL SELECT 'ENCOUNTERS', COUNT(*) FROM HEALTHCARE_DB.RAW_SCHEMA.ENCOUNTERS;
```

Expected row counts: 5,426 | 18,330 | 2,974 | 95,780 | 325,652 | 138,129

---

## Step 3: Transformations (Silver Layer)

Run all 6 transformation scripts. These create payer-perspective derived columns (risk tiers, penalty status, spending benchmarks).

| Order | Script | Output Table |
|-------|--------|-------------|
| 3.1 | `03_transform/01_transform_facilities.sql` | TRANSFORMED_FACILITIES |
| 3.2 | `03_transform/02_transform_readmission_metrics.sql` | TRANSFORMED_READMISSION_METRICS |
| 3.3 | `03_transform/03_transform_cost_analytics.sql` | TRANSFORMED_COST_ANALYTICS |
| 3.4 | `03_transform/04_transform_complications_and_death.sql` | TRANSFORMED_COMPLICATIONS_AND_DEATHS |
| 3.5 | `03_transform/05_transform_patient_survey.sql` | TRANSFORMED_PATIENT_SURVEY |
| 3.6 | `03_transform/06_transform_encounters.sql` | TRANSFORMED_ENCOUNTERS |

**Verification:**
```sql
SHOW TABLES LIKE 'TRANSFORMED%' IN HEALTHCARE_DB.RAW_SCHEMA;
-- Should return 6 tables
```

---

## Step 4: Analytics (Gold Layer)

Run all 5 analytics scripts. These build the final payer-facing analytical tables.

| Order | Script | Output Table |
|-------|--------|-------------|
| 4.1 | `04_analytics/01_analytics_hospital_payer_scorecard.sql` | ANALYTICS_HOSPITAL_PAYER_SCORECARD |
| 4.2 | `04_analytics/02_analytics_readmission_penalty_risk.sql` | ANALYTICS_READMISSION_PENALTY_RISK + ANALYTICS_STATE_READMISSION_SUMMARY |
| 4.3 | `04_analytics/03_analytics_cost_vs_quality.sql` | ANALYTICS_COST_VS_QUALITY |
| 4.4 | `04_analytics/04_analytics_state_benchmarking.sql` | ANALYTICS_STATE_BENCHMARKING |
| 4.5 | `04_analytics/05_analytics_patient_experience_impact.sql` | ANALYTICS_PATIENT_EXPERIENCE_IMPACT |

**Verification:**
```sql
SHOW TABLES LIKE 'ANALYTICS%' IN HEALTHCARE_DB.ANALYTICS_SCHEMA;
-- Should return 5-6 tables
```

---

## Step 5: Governance

Run the 3 governance scripts in order. These apply tags, masking policies, and row-level security.

| Order | Script | What It Does |
|-------|--------|-------------|
| 5.1 | `05_governance/tags.sql` | Creates GOVERNANCE schema, 3 tags (DATA_CLASSIFICATION, DATA_DOMAIN, PII_TYPE), applies to all sensitive columns |
| 5.2 | `05_governance/masking_policies.sql` | Creates 6 masking policies (string PII, phone, ZIP, financial, clinical) + unmask functions, applies to all 6 raw tables |
| 5.3 | `05_governance/row_access_policy.sql` | Creates STATE_ACCESS_MAPPING table, RAP_STATE_FILTER policy, applies state-level row filtering to 5 tables |

**Verification:**
```sql
-- Check masking policies
SELECT * FROM TABLE(HEALTHCARE_DB.INFORMATION_SCHEMA.POLICY_REFERENCES(
    REF_ENTITY_NAME => 'HEALTHCARE_DB.RAW_SCHEMA.FACILITIES',
    REF_ENTITY_DOMAIN => 'TABLE'
));

-- Check tags
SELECT * FROM TABLE(HEALTHCARE_DB.INFORMATION_SCHEMA.TAG_REFERENCES_ALL_COLUMNS(
    'HEALTHCARE_DB.RAW_SCHEMA.FACILITIES', 'TABLE'
));

-- Test masking as restricted role
USE ROLE REPORTING_ROLE;
SELECT "Facility Name", "Address", "Telephone Number", "ZIP Code"
FROM HEALTHCARE_DB.RAW_SCHEMA.FACILITIES LIMIT 5;
-- Expected: ***MASKED***, ***MASKED***, ***-***-XXXX, XXX**
```

---

## Step 6: Monitoring

| Order | Script | What It Does |
|-------|--------|-------------|
| 6.1 | `06_monitoring/monitoring.sql` | Creates credit consumption, warehouse usage, and query performance monitoring views in GOVERNANCE_SCHEMA |

---

## Step 7: Cortex Agent

| Order | Script | What It Does |
|-------|--------|-------------|
| 7.1 | `07_cortex_agent/cortex_agent_setup.sql` | Creates Semantic View (HOSPITAL_PAYER_ANALYTICS_SV) over all 5 analytics tables, then creates HOSPITAL_PAYER_AGENT with text-to-SQL and charting tools |

**Verification:**
```sql
-- Test the agent
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  'HEALTHCARE_DB.ANALYTICS_SCHEMA.HOSPITAL_PAYER_AGENT',
  '{ "messages": [{ "role": "user", "content": [{ "type": "text", "text": "How many hospitals are in the dataset?" }] }] }'
);
```

---

## Step 8: Streamlit Dashboard

| Order | Script | What It Does |
|-------|--------|-------------|
| 8.1 | `08_dashboard/streamlit_dashboard.sql` | Deploys a 6-tab Streamlit app (HOSPITAL_PAYER_DASHBOARD) to ANALYTICS_SCHEMA with environment.yml |

**Access:** Snowsight > Projects > Streamlit > HOSPITAL_PAYER_DASHBOARD

---

## Execution Summary

| Phase | Scripts | Role | Warehouse |
|-------|---------|------|-----------|
| Setup | 01_setup/01-06 | ACCOUNTADMIN | N/A |
| Ingestion | 02_ingestion/01-02 | DATA_INGEST_ROLE | Data_Ingest_WH |
| Transform | 03_transform/01-06 | DATA_TRANSFORM_ROLE | Data_Transform_WH |
| Analytics | 04_analytics/01-05 | DATA_ANALYST_ROLE | Data_Analytics_WH |
| Governance | 05_governance/01-03 | ACCOUNTADMIN | COMPUTE_WH |
| Monitoring | 06_monitoring/01 | ACCOUNTADMIN | COMPUTE_WH |
| Cortex Agent | 07_cortex_agent/01 | ACCOUNTADMIN | COMPUTE_WH |
| Dashboard | 08_dashboard/01 | ACCOUNTADMIN | COMPUTE_WH |

---

## Troubleshooting

| Issue | Resolution |
|-------|-----------|
| `Schema does not exist` | Run Step 1 (setup) scripts first in order |
| `Table does not exist` during transforms | Ensure Step 2 (ingestion) completed with correct row counts |
| `COPY INTO` fails with format errors | Verify CMS_CSV_FORMAT exists: `SHOW FILE FORMATS IN HEALTHCARE_DB.RAW_SCHEMA` |
| Masking policy compile error | Ensure GOVERNANCE schema and UNMASK_PII/UNMASK_SENSITIVE functions exist (run masking_policies.sql before tags.sql SET TAG with policies) |
| Agent returns "missing execution environment" | Verify COMPUTE_WH warehouse exists and is accessible |
| Streamlit app shows no data | Verify analytics tables exist in ANALYTICS_SCHEMA with `SHOW TABLES LIKE 'ANALYTICS%' IN HEALTHCARE_DB.ANALYTICS_SCHEMA` |
| Row access policy blocks all data | Check STATE_ACCESS_MAPPING has entries for your current role: `SELECT * FROM HEALTHCARE_DB.GOVERNANCE.STATE_ACCESS_MAPPING` |

---

## Objects Created

| Type | Count | Schema |
|------|-------|--------|
| Roles | 5 | N/A |
| Warehouses | 3 | N/A |
| Resource Monitors | 4 | N/A |
| Raw Tables | 6 | RAW_SCHEMA |
| Transformed Tables | 6 | RAW_SCHEMA |
| Analytics Tables | 5-6 | ANALYTICS_SCHEMA |
| Tags | 3 | GOVERNANCE |
| Masking Policies | 6 | GOVERNANCE |
| Row Access Policy | 1 | GOVERNANCE |
| Monitoring Views | 3+ | GOVERNANCE_SCHEMA |
| Semantic View | 1 | ANALYTICS_SCHEMA |
| Cortex Agent | 1 | ANALYTICS_SCHEMA |
| Streamlit App | 1 | ANALYTICS_SCHEMA |
