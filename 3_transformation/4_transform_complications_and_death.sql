----------------------------------------------------------------------
-- 4. COMPLICATIONS_AND_DEATHS: Mortality & Safety Indicators
----------------------------------------------------------------------
USE ROLE DATA_TRANSFORM_ROLE;
USE WAREHOUSE DATA_TRANSFORM_WH;
CREATE OR REPLACE TABLE HEALTHCARE_DB.TRANSFORM_SCHEMA.TRANSFORMED_COMPLICATIONS_AND_DEATHS AS
SELECT
    "Facility ID"                                           AS FACILITY_ID,
    "Facility Name"                                         AS FACILITY_NAME,
    "State"                                                 AS STATE,
    "Measure ID"                                            AS MEASURE_ID,
    "Measure Name"                                          AS MEASURE_NAME,

    CASE
        WHEN "Measure ID" LIKE 'MORT%' OR "Measure ID" = 'Hybrid_HWM' THEN 'Mortality'
        WHEN "Measure ID" LIKE 'PSI%'  THEN 'Patient Safety'
        WHEN "Measure ID" = 'COMP_HIP_KNEE' THEN 'Complication'
        ELSE 'Other'
    END                                                     AS MEASURE_CATEGORY,

    "Compared to National"                                  AS COMPARED_TO_NATIONAL,
    TRY_CAST("Denominator" AS INT)                          AS DENOMINATOR,
    TRY_CAST("Score" AS FLOAT)                              AS SCORE,
    TRY_CAST("Lower Estimate" AS FLOAT)                     AS LOWER_ESTIMATE,
    TRY_CAST("Higher Estimate" AS FLOAT)                    AS HIGHER_ESTIMATE,

    CASE
        WHEN "Compared to National" = 'Worse Than the National Rate' THEN 'High Risk'
        WHEN "Compared to National" = 'No Different Than the National Rate' THEN 'Standard'
        WHEN "Compared to National" = 'Better Than the National Rate' THEN 'Low Risk'
        ELSE 'Insufficient Data'
    END                                                     AS PAYER_RISK_CLASSIFICATION,

    CASE
        WHEN TRY_CAST("Score" AS FLOAT) IS NOT NULL
             AND TRY_CAST("Higher Estimate" AS FLOAT) IS NOT NULL
        THEN ROUND(TRY_CAST("Higher Estimate" AS FLOAT) - TRY_CAST("Lower Estimate" AS FLOAT), 2)
        ELSE NULL
    END                                                     AS CONFIDENCE_INTERVAL_WIDTH,

    "Start Date"                                            AS MEASUREMENT_START_DATE,
    "End Date"                                              AS MEASUREMENT_END_DATE
FROM HEALTHCARE_DB.RAW_SCHEMA.COMPLICATIONS_AND_DEATHS_HOSPITAL;
