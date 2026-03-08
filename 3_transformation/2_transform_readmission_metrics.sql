----------------------------------------------------------------------
-- 2. READMISSION_METRICS: Excess Readmission & Penalty Risk Analysis
----------------------------------------------------------------------
USE ROLE DATA_TRANSFORM_ROLE;
USE WAREHOUSE DATA_TRANSFORM_WH;
CREATE OR REPLACE TABLE HEALTHCARE_DB.TRANSFORM_SCHEMA.TRANSFORMED_READMISSION_METRICS AS
SELECT
    "Facility ID"                                           AS FACILITY_ID,
    "Facility Name"                                         AS FACILITY_NAME,
    "State"                                                 AS STATE,
    "Measure Name"                                          AS MEASURE_NAME,

    CASE
        WHEN "Measure Name" = 'READM-30-AMI-HRRP'       THEN 'Acute Myocardial Infarction'
        WHEN "Measure Name" = 'READM-30-HF-HRRP'        THEN 'Heart Failure'
        WHEN "Measure Name" = 'READM-30-PN-HRRP'        THEN 'Pneumonia'
        WHEN "Measure Name" = 'READM-30-COPD-HRRP'      THEN 'COPD'
        WHEN "Measure Name" = 'READM-30-HIP-KNEE-HRRP'  THEN 'Hip/Knee Replacement'
        WHEN "Measure Name" = 'READM-30-CABG-HRRP'      THEN 'CABG Surgery'
    END                                                     AS CONDITION_CATEGORY,

    "Number of Discharges"                                  AS NUMBER_OF_DISCHARGES,
    TRY_CAST("Number of Readmissions" AS INT)               AS NUMBER_OF_READMISSIONS,
    "Excess Readmission Ratio"                              AS EXCESS_READMISSION_RATIO,
    "Predicted Readmission Rate"                            AS PREDICTED_READMISSION_RATE,
    "Expected Readmission Rate"                             AS EXPECTED_READMISSION_RATE,

    ROUND("Predicted Readmission Rate" - "Expected Readmission Rate", 4)
                                                            AS READMISSION_RATE_VARIANCE,

    CASE
        WHEN "Excess Readmission Ratio" > 1.0 THEN 'Penalized (Above Expected)'
        WHEN "Excess Readmission Ratio" = 1.0 THEN 'At Expected'
        WHEN "Excess Readmission Ratio" < 1.0 THEN 'Below Expected'
        ELSE 'Not Available'
    END                                                     AS PENALTY_STATUS,

    CASE
        WHEN "Excess Readmission Ratio" >= 1.10 THEN 'Critical'
        WHEN "Excess Readmission Ratio" >= 1.05 THEN 'High'
        WHEN "Excess Readmission Ratio" > 1.00  THEN 'Moderate'
        WHEN "Excess Readmission Ratio" <= 1.00 THEN 'Low'
        ELSE 'Unknown'
    END                                                     AS PAYER_RISK_TIER,

    CASE
        WHEN "Number of Discharges" IS NOT NULL
             AND "Excess Readmission Ratio" > 1.0
        THEN ROUND("Number of Discharges" * ("Excess Readmission Ratio" - 1.0) * ("Predicted Readmission Rate" / 100), 2)
        ELSE 0
    END                                                     AS ESTIMATED_EXCESS_READMISSIONS,

    "Start Date"                                            AS MEASUREMENT_START_DATE,
    "End Date"                                              AS MEASUREMENT_END_DATE
FROM HEALTHCARE_DB.RAW_SCHEMA.READMISSION_METRICS;
