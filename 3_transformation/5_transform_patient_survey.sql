----------------------------------------------------------------------
-- 6. PATIENT_SURVEY: HCAHPS Patient Experience Metrics
----------------------------------------------------------------------
USE ROLE DATA_TRANSFORM_ROLE;
USE WAREHOUSE DATA_TRANSFORM_WH;

CREATE OR REPLACE TABLE HEALTHCARE_DB.TRANSFORM_SCHEMA.TRANSFORMED_PATIENT_SURVEY AS
SELECT
    "Facility ID"                                           AS FACILITY_ID,
    "Facility Name"                                         AS FACILITY_NAME,
    "State"                                                 AS STATE,
    "HCAHPS Measure ID"                                     AS MEASURE_ID,
    "HCAHPS Question"                                       AS SURVEY_QUESTION,
    "HCAHPS Answer Description"                             AS ANSWER_DESCRIPTION,
    TRY_CAST("Patient Survey Star Rating" AS INT)           AS STAR_RATING,
    TRY_CAST("HCAHPS Answer Percent" AS FLOAT)              AS ANSWER_PERCENT,
    TRY_CAST("HCAHPS Linear Mean Value" AS FLOAT)           AS LINEAR_MEAN_VALUE,
    TRY_CAST("Number of Completed Surveys" AS INT)          AS COMPLETED_SURVEYS,
    TRY_CAST("Survey Response Rate Percent" AS FLOAT)       AS RESPONSE_RATE_PCT,

    CASE
        WHEN "HCAHPS Measure ID" LIKE 'H_COMP_1%' OR "HCAHPS Measure ID" LIKE 'H_NURSE%'
            THEN 'Nurse Communication'
        WHEN "HCAHPS Measure ID" LIKE 'H_COMP_2%' OR "HCAHPS Measure ID" LIKE 'H_DOCTOR%'
            THEN 'Doctor Communication'
        WHEN "HCAHPS Measure ID" LIKE 'H_COMP_5%' OR "HCAHPS Measure ID" LIKE 'H_MED%' OR "HCAHPS Measure ID" LIKE 'H_SIDE%'
            THEN 'Communication About Medications'
        WHEN "HCAHPS Measure ID" LIKE 'H_COMP_6%' OR "HCAHPS Measure ID" LIKE 'H_SYMPTOMS%'
            THEN 'Discharge Information'
        WHEN "HCAHPS Measure ID" LIKE 'H_CLEAN%'
            THEN 'Hospital Cleanliness'
        WHEN "HCAHPS Measure ID" LIKE 'H_QUIET%'
            THEN 'Hospital Quietness'
        WHEN "HCAHPS Measure ID" LIKE 'H_HSP_RATING%'
            THEN 'Overall Rating'
        WHEN "HCAHPS Measure ID" LIKE 'H_RECMND%'
            THEN 'Willingness to Recommend'
        ELSE 'Other'
    END                                                     AS PAYER_EXPERIENCE_DOMAIN,

    CASE
        WHEN TRY_CAST("Patient Survey Star Rating" AS INT) >= 4 THEN 'High Satisfaction'
        WHEN TRY_CAST("Patient Survey Star Rating" AS INT) = 3  THEN 'Average Satisfaction'
        WHEN TRY_CAST("Patient Survey Star Rating" AS INT) <= 2
             AND TRY_CAST("Patient Survey Star Rating" AS INT) IS NOT NULL THEN 'Low Satisfaction'
        ELSE 'Not Rated'
    END                                                     AS SATISFACTION_TIER,

    "Start Date"                                            AS MEASUREMENT_START_DATE,
    "End Date"                                              AS MEASUREMENT_END_DATE
FROM HEALTHCARE_DB.RAW_SCHEMA.PATIENT_SURVEY;
