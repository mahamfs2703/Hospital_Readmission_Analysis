----------------------------------------------------------------------
-- 5. ENCOUNTERS: Timely & Effective Care Performance Metrics
----------------------------------------------------------------------
USE ROLE DATA_TRANSFORM_ROLE;
USE WAREHOUSE DATA_TRANSFORM_WH;
CREATE OR REPLACE TABLE HEALTHCARE_DB.TRANSFORM_SCHEMA.TRANSFORMED_ENCOUNTERS AS
SELECT
    "Facility ID"                                           AS FACILITY_ID,
    "Facility Name"                                         AS FACILITY_NAME,
    "State"                                                 AS STATE,
    "Condition"                                             AS CONDITION_CATEGORY,
    "Measure ID"                                            AS MEASURE_ID,
    "Measure Name"                                          AS MEASURE_NAME,
    TRY_CAST("Score" AS FLOAT)                              AS SCORE,
    TRY_CAST("Sample" AS INT)                               AS SAMPLE_SIZE,

    CASE
        WHEN "Condition" = 'Emergency Department'              THEN 'ED Efficiency'
        WHEN "Condition" = 'Sepsis Care'                       THEN 'Sepsis Compliance'
        WHEN "Condition" = 'Electronic Clinical Quality Measure' THEN 'Clinical Quality'
        WHEN "Condition" = 'Healthcare Personnel Vaccination'  THEN 'Infection Prevention'
        WHEN "Condition" = 'Cataract surgery outcome'          THEN 'Surgical Outcome'
        WHEN "Condition" = 'Colonoscopy care'                  THEN 'Preventive Care'
        ELSE 'Other'
    END                                                     AS PAYER_METRIC_GROUP,

    CASE
        WHEN "Measure ID" IN ('OP_18a','OP_18b','OP_18c','OP_18d') THEN 'ED Wait Time'
        WHEN "Measure ID" = 'EDV'                           THEN 'ED Volume'
        WHEN "Measure ID" = 'OP_22'                         THEN 'ED Transfer Communication'
        WHEN "Measure ID" = 'OP_23'                         THEN 'Head CT Timeliness'
        WHEN "Measure ID" LIKE 'SEP%' OR "Measure ID" LIKE 'SEV_SEP%' THEN 'Sepsis Bundle Compliance'
        WHEN "Measure ID" LIKE 'HH_%'                       THEN 'Hospital Harm'
        WHEN "Measure ID" LIKE 'STK_%'                      THEN 'Stroke Care'
        WHEN "Measure ID" LIKE 'VTE_%'                      THEN 'VTE Prevention'
        WHEN "Measure ID" LIKE 'GMCS%'                      THEN 'Malnutrition Screening'
        WHEN "Measure ID" = 'IMM_3'                         THEN 'Staff Vaccination'
        WHEN "Measure ID" = 'OP_29'                         THEN 'Colonoscopy Follow-Up'
        WHEN "Measure ID" = 'OP_31'                         THEN 'Cataract Outcome'
        WHEN "Measure ID" = 'SAFE_USE_OF_OPIOIDS'          THEN 'Opioid Stewardship'
        WHEN "Measure ID" = 'OP_40'                         THEN 'Surgical Safety'
        ELSE 'Other'
    END                                                     AS CARE_QUALITY_DOMAIN,

    "Start Date"                                            AS MEASUREMENT_START_DATE,
    "End Date"                                              AS MEASUREMENT_END_DATE
FROM HEALTHCARE_DB.RAW_SCHEMA.ENCOUNTERS;
