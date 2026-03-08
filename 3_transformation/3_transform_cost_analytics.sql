----------------------------------------------------------------------
-- 3. COST_ANALYTICS: Medicare Spending Efficiency per Beneficiary
----------------------------------------------------------------------
USE ROLE DATA_TRANSFORM_ROLE;
USE WAREHOUSE DATA_TRANSFORM_WH;
CREATE OR REPLACE TABLE HEALTHCARE_DB.TRANSFORM_SCHEMA.TRANSFORMED_COST_ANALYTICS AS
SELECT
    "Facility ID"                                           AS FACILITY_ID,
    "Measure ID"                                            AS MEASURE_ID,
    "Value"                                                 AS SPENDING_RATIO,

    CASE
        WHEN "Value" > 1.0 THEN 'Above National Average'
        WHEN "Value" = 1.0 THEN 'At National Average'
        WHEN "Value" < 1.0 THEN 'Below National Average'
        ELSE 'Not Available'
    END                                                     AS SPENDING_BENCHMARK,

    CASE
        WHEN "Value" >= 1.10 THEN 'High Overspend'
        WHEN "Value" >= 1.03 THEN 'Moderate Overspend'
        WHEN "Value" > 1.00  THEN 'Slight Overspend'
        WHEN "Value" BETWEEN 0.97 AND 1.00 THEN 'Efficient'
        WHEN "Value" < 0.97 THEN 'Highly Efficient'
        ELSE 'Unknown'
    END                                                     AS COST_EFFICIENCY_TIER,

    ROUND(("Value" - 1.0) * 100, 2)                        AS SPENDING_DEVIATION_PCT,

    "Start Date"                                            AS MEASUREMENT_START_DATE,
    "End Date"                                              AS MEASUREMENT_END_DATE
FROM HEALTHCARE_DB.RAW_SCHEMA.COST_ANALYTICS;
