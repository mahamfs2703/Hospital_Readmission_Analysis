----------------------------------------------------------------------
-- 1. FACILITIES: Hospital Profile & Quality Tier Classification
----------------------------------------------------------------------
USE ROLE DATA_TRANSFORM_ROLE;
USE WAREHOUSE DATA_TRANSFORM_WH;
CREATE OR REPLACE TABLE HEALTHCARE_DB.TRANSFORM_SCHEMA.TRANSFORMED_FACILITIES AS
SELECT
    "Facility ID"                                           AS FACILITY_ID,
    "Facility Name"                                         AS FACILITY_NAME,
    "City/Town"                                             AS CITY,
    "State"                                                 AS STATE,
    "ZIP Code"                                              AS ZIP_CODE,
    "County/Parish"                                         AS COUNTY,
    "Hospital Type"                                         AS HOSPITAL_TYPE,
    "Hospital Ownership"                                    AS HOSPITAL_OWNERSHIP,
    "Emergency Services"                                    AS EMERGENCY_SERVICES,
    TRY_CAST("Hospital overall rating" AS INT)              AS OVERALL_RATING,

    TRY_CAST("Count of Facility MORT Measures" AS INT)      AS MORTALITY_MEASURES_REPORTED,
    TRY_CAST("Count of MORT Measures Better" AS INT)        AS MORTALITY_BETTER_THAN_NATIONAL,
    TRY_CAST("Count of MORT Measures Worse" AS INT)         AS MORTALITY_WORSE_THAN_NATIONAL,

    TRY_CAST("Count of Facility Safety Measures" AS INT)    AS SAFETY_MEASURES_REPORTED,
    TRY_CAST("Count of Safety Measures Better" AS INT)      AS SAFETY_BETTER_THAN_NATIONAL,
    TRY_CAST("Count of Safety Measures Worse" AS INT)       AS SAFETY_WORSE_THAN_NATIONAL,

    TRY_CAST("Count of Facility READM Measures" AS INT)     AS READMISSION_MEASURES_REPORTED,
    TRY_CAST("Count of READM Measures Better" AS INT)       AS READMISSION_BETTER_THAN_NATIONAL,
    TRY_CAST("Count of READM Measures Worse" AS INT)        AS READMISSION_WORSE_THAN_NATIONAL,

    TRY_CAST("Count of Facility Pt Exp Measures" AS INT)    AS PATIENT_EXP_MEASURES_REPORTED,
    TRY_CAST("Count of Facility TE Measures" AS INT)        AS TIMELY_EFFECTIVE_MEASURES_REPORTED,

    CASE
        WHEN TRY_CAST("Hospital overall rating" AS INT) >= 4 THEN 'Preferred'
        WHEN TRY_CAST("Hospital overall rating" AS INT) = 3  THEN 'Standard'
        WHEN TRY_CAST("Hospital overall rating" AS INT) <= 2
             AND TRY_CAST("Hospital overall rating" AS INT) IS NOT NULL THEN 'High Risk'
        ELSE 'Unrated'
    END                                                     AS PAYER_NETWORK_TIER,

    CASE
        WHEN TRY_CAST("Count of READM Measures Worse" AS INT) >= 3 THEN 'High'
        WHEN TRY_CAST("Count of READM Measures Worse" AS INT) BETWEEN 1 AND 2 THEN 'Medium'
        ELSE 'Low'
    END                                                     AS READMISSION_RISK_FLAG,

    CASE
        WHEN TRY_CAST("Count of MORT Measures Worse" AS INT) >= 2
          OR TRY_CAST("Count of Safety Measures Worse" AS INT) >= 2 THEN 'High'
        WHEN TRY_CAST("Count of MORT Measures Worse" AS INT) = 1
          OR TRY_CAST("Count of Safety Measures Worse" AS INT) = 1 THEN 'Medium'
        ELSE 'Low'
    END                                                     AS QUALITY_CONCERN_LEVEL
FROM HEALTHCARE_DB.RAW_SCHEMA.FACILITIES;
