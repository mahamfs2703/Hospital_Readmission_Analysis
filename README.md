# Hospital Readmission Accelerator

An end-to-end Snowflake solution for analyzing CMS hospital readmission data from a **payer (insurance company) perspective**. Built on a medallion architecture (Bronze > Silver > Gold), it delivers a Streamlit dashboard and a Cortex Agent for natural language analytics.

---


## Table mapping

CMS Dataset			                      → Your RAW Table

Hospital General Info		                FACILITIES_RAW				

HRRP				                        READMISSION_METRICS			

Timely & Effective Care		                ENCOUNTERS_RAW (process measures)	

Complications & Deaths		                Analytics enrichment			

HCAHPS				                         Patient experience layer	

Medicare Spending		                     Cost analytics				

## Architecture

```
CMS CSV Files                 RAW_SCHEMA (Bronze)        RAW_SCHEMA (Silver)           ANALYTICS_SCHEMA (Gold)
  Facilities             -->    FACILITIES            -->  TRANSFORMED_FACILITIES    -->  ANALYTICS_HOSPITAL_PAYER_SCORECARD
  HRRP Readmissions      -->    READMISSION_METRICS   -->  TRANSFORMED_READMISSION   -->  ANALYTICS_READMISSION_PENALTY_RISK
  Medicare Spending       -->    COST_ANALYTICS        -->  TRANSFORMED_COST          -->  ANALYTICS_COST_VS_QUALITY
  Complications/Deaths    -->    COMPLICATIONS_AND_    -->  TRANSFORMED_COMPLICATIONS -->  ANALYTICS_STATE_BENCHMARKING
  HCAHPS Patient Survey   -->    PATIENT_SURVEY        -->  TRANSFORMED_PATIENT       -->  ANALYTICS_PATIENT_EXPERIENCE_IMPACT
  Timely/Effective Care   -->    ENCOUNTERS            -->  TRANSFORMED_ENCOUNTERS    |
                                                                                      v
                                                                            Streamlit Dashboard
                                                                            Cortex Agent (NL Query)
```

---

## Project Structure

```
Hospital Readmission Accelerator/
├── 01_setup/                         # Environment provisioning
│   ├── 01_create_roles.sql           # RBAC roles (Ingest, Transform, Analyst, Admin)
│   ├── 02_create_database.sql        # HEALTHCARE_DB
│   ├── 03_create_schema.sql          # RAW_SCHEMA, ANALYTICS_SCHEMA, GOVERNANCE
│   ├── 04_create_warehouse.sql       # DATA_INGEST_WH, COMPUTE_WH
│   ├── 05_create_resource_monitors.sql
│   └── 06_create_file_format.sql     # CMS_CSV_FORMAT
│
├── 02_ingestion/                     # Bronze layer
│   ├── create_raw_tables.sql         # 6 raw CMS tables
│   └── load_cms_data.sql             # COPY INTO from RAW_STAGE
│
├── 03_transform/                     # Silver layer (payer-perspective transformations)
│   ├── 01_transform_facilities.sql   # Network tier, risk flags, quality concern
│   ├── 02_transform_readmission_metrics.sql  # Penalty status, risk tier, excess readmissions
│   ├── 03_transform_cost_analytics.sql       # Spending benchmark, efficiency tier
│   ├── 04_transform_complications_and_death.sql  # Measure category, risk classification
│   ├── 05_transform_patient_survey.sql       # Experience domain, satisfaction tier
│   └── 06_transform_encounters.sql           # Metric group, care quality domain
│
├── 04_analytics/                     # Gold layer
│   ├── 01_analytics_hospital_payer_scorecard.sql  # Unified composite scorecard
│   ├── 02_analytics_readmission_penalty_risk.sql  # HRRP penalty deep-dive + cost exposure
│   ├── 03_analytics_cost_vs_quality.sql           # Value quadrant analysis
│   ├── 04_analytics_state_benchmarking.sql        # State-level rankings
│   └── 05_analytics_patient_experience_impact.sql # HCAHPS vs readmission/cost quadrants
│
├── 05_governance/                    # Data governance
│   ├── tags.sql                      # DATA_CLASSIFICATION, DATA_DOMAIN, PII_TYPE tags
│   ├── masking_policies.sql          # String PII, phone, ZIP, financial, clinical masking
│   └── row_access_policy.sql         # State-based row filtering by role
│
├── 06_monitoring/                    # Operational monitoring
│   └── monitoring.sql                # Credit consumption, warehouse usage views
│
├── 07_cortex_agent/                  # AI-powered analytics
│   └── cortex_agent_setup.sql        # Semantic view + Cortex Agent creation
│
├── 08_dashboard/                     # Streamlit in Snowflake
│   └── streamlit_dashboard.sql       # 6-tab interactive dashboard
│
└── README.md
```

---

## Data Sources

| Source File | Table | Records | Description |
|---|---|---|---|
| Hospital_General_Information.csv | FACILITIES | 5,426 | Hospital profiles, CMS star ratings, ownership |
| HRRP (Hospital_Readmission_ReductionProgram).csv | READMISSION_METRICS | 18,330 | 30-day readmission ratios by condition |
| Medicare Spending Per Beneficiary.csv | COST_ANALYTICS | 2,974 | MSPB spending ratios vs national average |
| Complications_and_Deaths-Hospital.csv | COMPLICATIONS_AND_DEATHS_HOSPITAL | 95,780 | Mortality & patient safety indicators |
| HCAHPS_Patient_Survey_Hospital.csv | PATIENT_SURVEY | 325,652 | Patient experience survey results |
| Timely_and_Effective_Care-Hospital.csv | ENCOUNTERS | 138,129 | ED, sepsis, clinical quality measures |

---

## Key Payer Metrics

| Metric | Description | Good Value |
|---|---|---|
| Excess Readmission Ratio | Hospital readmissions vs expected | < 1.0 |
| MSPB Spending Ratio | Medicare spending vs national average | < 1.0 |
| Payer Composite Score | Weighted score (0-100) across all dimensions | Higher is better |
| Payer Network Tier | Preferred / Standard / High Risk / Unrated | Preferred |
| Payer Composite Status | Top Performer / Standard / Watch List / Under Review | Top Performer |
| Estimated Payer Cost Exposure | Dollar impact of excess readmissions ($15K/readmission) | $0 |

---

## Deployment

Run scripts in numbered order:

```
01_setup/     -->  01_ through 06_ (create roles, DB, schemas, warehouses)
02_ingestion/ -->  create_raw_tables.sql, then load_cms_data.sql
03_transform/ -->  01_ through 06_ (silver layer transformations)
04_analytics/ -->  01_ through 05_ (gold layer analytics tables)
05_governance/-->  tags.sql, masking_policies.sql, row_access_policy.sql
06_monitoring/-->  monitoring.sql
07_cortex_agent/-> cortex_agent_setup.sql
08_dashboard/ -->  streamlit_dashboard.sql (deploy to Streamlit in Snowflake)
```

---

## Roles & Access Control

| Role | Layer | Permissions |
|---|---|---|
| DATA_INGEST_ROLE | Bronze | Load raw CMS data into RAW_SCHEMA |
| DATA_TRANSFORM_ROLE | Silver | Read raw, write transformed tables |
| DATA_ANALYST_ROLE | Gold | Read all, write analytics tables, unmasked ZIP/financial data |
| DATA_ENGINEER_ROLE | All | Full PII access, manage pipelines |
| ADMIN_ROLE | All | Full access including governance |
| REPORTING_ROLE | Gold (restricted) | Read-only, masked PII, state-filtered rows (AL, CA, NY, TX, FL) |

---

## Governance

**Tags:** `DATA_CLASSIFICATION` (PII/PHI/SENSITIVE/INTERNAL/PUBLIC), `DATA_DOMAIN`, `PII_TYPE`

**Masking Policies:**
- Facility Name, Address -> fully masked for non-privileged roles
- Phone -> last 4 digits shown
- ZIP Code -> 3-digit prefix only
- Financial values -> NULL for non-privileged roles
- Clinical metrics -> rounded to integer

**Row Access Policy:** State-based filtering controlled via `GOVERNANCE.STATE_ACCESS_MAPPING` table

---

## Cortex Agent

The **Hospital Payer Analytics Agent** answers natural language questions across all 5 analytics tables.

**Location:** `HEALTHCARE_DB.ANALYTICS_SCHEMA.HOSPITAL_PAYER_AGENT`

**Sample questions:**
- "Which are the top 10 hospitals by payer composite score?"
- "What is the total payer cost exposure from excess readmissions?"
- "Which states have the highest readmission penalty rates?"
- "Show me hospitals that are High Risk but have good patient satisfaction"
- "Compare cost efficiency across hospital ownership types"

---

## Streamlit Dashboard

**Location:** `HEALTHCARE_DB.ANALYTICS_SCHEMA.HOSPITAL_PAYER_DASHBOARD`

| Tab | Description |
|---|---|
| Overview | Portfolio KPIs, network tier distribution, composite score histogram |
| Hospital Scorecard | Filterable hospital table, score vs spending scatter plot |
| Readmission Penalty Risk | Cost exposure KPIs, box plots by condition, top-20 bar chart |
| Cost vs Quality | Value quadrant distribution, spending vs readmission scatter |
| State Benchmarking | State rankings, tier composition, state-level scatter |
| Patient Experience | HCAHPS quadrant analysis, star rating vs readmission, domain comparison |
