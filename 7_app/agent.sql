----------------------------------------------------------------------
-- SEMANTIC VIEW: Hospital Payer Analytics
----------------------------------------------------------------------
CREATE OR REPLACE SEMANTIC VIEW HEALTHCARE_DB.ANALYTICS_SCHEMA.HOSPITAL_PAYER_ANALYTICS_SV

  TABLES (
    scorecard AS HEALTHCARE_DB.ANALYTICS_SCHEMA.ANALYTICS_HOSPITAL_PAYER_SCORECARD
      PRIMARY KEY (FACILITY_ID)
      COMMENT = 'Unified per-hospital scorecard for payer network evaluation',

    penalty AS HEALTHCARE_DB.ANALYTICS_SCHEMA.ANALYTICS_READMISSION_PENALTY_RISK
      COMMENT = 'Condition-level readmission penalty risk per hospital under HRRP',

    cost_quality AS HEALTHCARE_DB.ANALYTICS_SCHEMA.ANALYTICS_COST_VS_QUALITY
      PRIMARY KEY (FACILITY_ID)
      COMMENT = 'Hospital-level cost vs quality analysis linking Medicare spending with outcomes',

    state_bench AS HEALTHCARE_DB.ANALYTICS_SCHEMA.ANALYTICS_STATE_BENCHMARKING
      PRIMARY KEY (STATE)
      COMMENT = 'State-level aggregated benchmarking for regional payer strategy',

    patient_exp AS HEALTHCARE_DB.ANALYTICS_SCHEMA.ANALYTICS_PATIENT_EXPERIENCE_IMPACT
      PRIMARY KEY (FACILITY_ID)
      COMMENT = 'Hospital-level patient experience analysis linking HCAHPS with outcomes'
  )

  RELATIONSHIPS (
    penalty (FACILITY_ID) REFERENCES scorecard,
    cost_quality (FACILITY_ID) REFERENCES scorecard,
    patient_exp (FACILITY_ID) REFERENCES scorecard,
    scorecard (STATE) REFERENCES state_bench
  )

  FACTS (
    scorecard.overall_rating_fact AS OVERALL_RATING
      COMMENT = 'CMS overall hospital star rating (1-5)',
    scorecard.total_discharges_fact AS TOTAL_DISCHARGES
      COMMENT = 'Total discharges across all measured conditions',
    scorecard.total_readmissions_fact AS TOTAL_READMISSIONS
      COMMENT = 'Total readmissions across all measured conditions',
    scorecard.avg_excess_readm_fact AS AVG_EXCESS_READMISSION_RATIO
      COMMENT = 'Average excess readmission ratio. Below 1.0 is better.',
    scorecard.mspb_spending_fact AS MSPB_SPENDING_RATIO
      COMMENT = 'Medicare Spending Per Beneficiary ratio. Below 1.0 is efficient.',
    scorecard.spending_deviation_fact AS SPENDING_DEVIATION_PCT
      COMMENT = 'Pct deviation from national average spending',
    scorecard.conditions_penalized_fact AS CONDITIONS_PENALIZED
      COMMENT = 'Number of conditions where hospital is penalized',
    scorecard.composite_score_fact AS PAYER_COMPOSITE_SCORE
      COMMENT = 'Payer composite score 0-100',
    scorecard.patient_exp_star_fact AS PATIENT_EXPERIENCE_STAR
      COMMENT = 'HCAHPS patient experience star rating 1-5',
    scorecard.complication_high_risk_fact AS COMPLICATION_HIGH_RISK_COUNT
      COMMENT = 'Number of complication measures classified as High Risk',

    penalty.num_discharges_fact AS NUMBER_OF_DISCHARGES
      COMMENT = 'Discharges for a specific condition at a hospital',
    penalty.num_readmissions_fact AS NUMBER_OF_READMISSIONS
      COMMENT = '30-day readmissions for this condition',
    penalty.excess_readm_ratio_fact AS EXCESS_READMISSION_RATIO
      COMMENT = 'Excess readmission ratio. Above 1.0 means penalized.',
    penalty.predicted_rate_fact AS PREDICTED_READMISSION_RATE
      COMMENT = 'Risk-adjusted predicted readmission rate',
    penalty.expected_rate_fact AS EXPECTED_READMISSION_RATE
      COMMENT = 'Expected readmission rate based on national average',
    penalty.cost_exposure_fact AS ESTIMATED_PAYER_COST_EXPOSURE
      COMMENT = 'Estimated payer cost exposure in dollars',

    cost_quality.cost_decile_fact AS COST_DECILE
      COMMENT = 'Cost decile 1=lowest spending 10=highest',
    cost_quality.readm_decile_fact AS READMISSION_DECILE
      COMMENT = 'Readmission decile 1=lowest 10=highest',
    cost_quality.avg_mortality_fact AS AVG_MORTALITY_RATE
      COMMENT = 'Average mortality rate',
    cost_quality.avg_safety_fact AS AVG_SAFETY_EVENT_RATE
      COMMENT = 'Average patient safety event rate',

    state_bench.total_hospitals_fact AS TOTAL_HOSPITALS
      COMMENT = 'Total hospitals in the state',
    state_bench.preferred_hospitals_fact AS PREFERRED_TIER_HOSPITALS
      COMMENT = 'Preferred tier hospitals in the state',
    state_bench.high_risk_hospitals_fact AS HIGH_RISK_TIER_HOSPITALS
      COMMENT = 'High Risk tier hospitals in the state',
    state_bench.hospitals_penalized_fact AS HOSPITALS_PENALIZED
      COMMENT = 'Hospitals penalized for readmissions in the state',
    state_bench.pct_penalized_fact AS PCT_HOSPITALS_PENALIZED
      COMMENT = 'Pct of hospitals penalized',
    state_bench.state_readm_rank_fact AS STATE_READMISSION_RANK
      COMMENT = 'State rank by readmission ratio 1=best',
    state_bench.state_cost_rank_fact AS STATE_COST_RANK
      COMMENT = 'State rank by spending ratio 1=best',

    patient_exp.overall_star_fact AS OVERALL_STAR_RATING
      COMMENT = 'Overall HCAHPS star rating 1-5',
    patient_exp.nurse_comm_fact AS NURSE_COMM_STAR
      COMMENT = 'Nurse communication star rating 1-5',
    patient_exp.doctor_comm_fact AS DOCTOR_COMM_STAR
      COMMENT = 'Doctor communication star rating 1-5',
    patient_exp.pct_recommend_fact AS PCT_WOULD_RECOMMEND
      COMMENT = 'Pct who would definitely recommend hospital',
    patient_exp.avg_domain_star_fact AS AVG_DOMAIN_STAR_RATING
      COMMENT = 'Average across HCAHPS domain star ratings'
  )

  DIMENSIONS (
    scorecard.facility_id_dim AS FACILITY_ID
      COMMENT = 'Unique hospital facility identifier',
    scorecard.facility_name_dim AS FACILITY_NAME
      WITH SYNONYMS = ('hospital name', 'hospital')
      COMMENT = 'Hospital name',
    scorecard.state_dim AS STATE
      WITH SYNONYMS = ('US state')
      COMMENT = 'US state abbreviation',
    scorecard.city_dim AS CITY
      COMMENT = 'City where hospital is located',
    scorecard.county_dim AS COUNTY
      COMMENT = 'County where hospital is located',
    scorecard.hospital_type_dim AS HOSPITAL_TYPE
      COMMENT = 'Type of hospital',
    scorecard.hospital_ownership_dim AS HOSPITAL_OWNERSHIP
      WITH SYNONYMS = ('ownership type')
      COMMENT = 'Ownership type',
    scorecard.network_tier_dim AS PAYER_NETWORK_TIER
      WITH SYNONYMS = ('tier', 'network tier')
      COMMENT = 'Payer-assigned tier: Preferred, Standard, High Risk, Unrated',
    scorecard.composite_status_dim AS PAYER_COMPOSITE_STATUS
      WITH SYNONYMS = ('composite status', 'payer status')
      COMMENT = 'Top Performer, Standard, Watch List, or Under Review',
    scorecard.readmission_risk_dim AS READMISSION_RISK_FLAG
      COMMENT = 'Readmission risk: High, Medium, or Low',
    scorecard.quality_concern_dim AS QUALITY_CONCERN_LEVEL
      COMMENT = 'Quality concern: High, Medium, or Low',
    scorecard.cost_efficiency_dim AS COST_EFFICIENCY_TIER
      WITH SYNONYMS = ('spending tier', 'cost tier')
      COMMENT = 'Spending tier classification',

    penalty.condition_dim AS CONDITION_CATEGORY
      WITH SYNONYMS = ('condition', 'diagnosis')
      COMMENT = 'Clinical condition: AMI, Heart Failure, Pneumonia, COPD, Hip/Knee, CABG',
    penalty.penalty_status_dim AS PENALTY_STATUS
      COMMENT = 'Penalized Above Expected, At Expected, Below Expected, or Not Available',
    penalty.risk_tier_dim AS PAYER_RISK_TIER
      COMMENT = 'Risk tier: Critical, High, Moderate, Low',

    cost_quality.value_quadrant_dim AS PAYER_VALUE_QUADRANT
      WITH SYNONYMS = ('value quadrant')
      COMMENT = 'High Value, High Cost Good Quality, Low Cost Quality Gap, Moderate Value, Low Value',

    patient_exp.experience_readm_quad_dim AS EXPERIENCE_READMISSION_QUADRANT
      COMMENT = 'Quadrant combining satisfaction and readmission performance',
    patient_exp.experience_cost_quad_dim AS EXPERIENCE_COST_QUADRANT
      COMMENT = 'Quadrant combining satisfaction and cost efficiency',
    patient_exp.vbp_eligibility_dim AS VBP_INCENTIVE_ELIGIBILITY
      WITH SYNONYMS = ('VBP eligible', 'value-based purchasing')
      COMMENT = 'Eligible or Not Eligible'
  )

  METRICS (
    scorecard.total_hospital_count AS COUNT(scorecard.facility_id_dim)
      WITH SYNONYMS = ('number of hospitals', 'hospital count')
      COMMENT = 'Total count of hospitals',
    scorecard.avg_composite_score AS AVG(scorecard.composite_score_fact)
      WITH SYNONYMS = ('average composite score')
      COMMENT = 'Average payer composite score',
    scorecard.avg_spending_ratio AS AVG(scorecard.mspb_spending_fact)
      WITH SYNONYMS = ('average spending ratio', 'avg MSPB')
      COMMENT = 'Average MSPB spending ratio',
    scorecard.avg_readmission_ratio AS AVG(scorecard.avg_excess_readm_fact)
      WITH SYNONYMS = ('average readmission ratio')
      COMMENT = 'Average excess readmission ratio',
    scorecard.total_discharge_count AS SUM(scorecard.total_discharges_fact)
      COMMENT = 'Total discharges across all hospitals',
    scorecard.avg_patient_star AS AVG(scorecard.patient_exp_star_fact)
      COMMENT = 'Average patient experience star rating',

    penalty.total_cost_exposure AS SUM(penalty.cost_exposure_fact)
      WITH SYNONYMS = ('total payer cost exposure', 'cost exposure')
      COMMENT = 'Total estimated payer cost exposure from excess readmissions',
    penalty.avg_excess_ratio AS AVG(penalty.excess_readm_ratio_fact)
      COMMENT = 'Average excess readmission ratio at condition level',
    penalty.total_excess_readmissions AS SUM(penalty.num_readmissions_fact)
      COMMENT = 'Total readmissions across all conditions',
    penalty.penalized_condition_count AS COUNT(penalty.penalty_status_dim)
      COMMENT = 'Count of condition-level penalty records',

    state_bench.sum_hospitals AS SUM(state_bench.total_hospitals_fact)
      COMMENT = 'Sum of hospitals across states',
    state_bench.avg_state_cost_rank AS AVG(state_bench.state_cost_rank_fact)
      COMMENT = 'Average state cost rank'
  )

  COMMENT = 'Semantic view for hospital readmission and payer analytics'

  AI_SQL_GENERATION 'Always include FACILITY_NAME when answering about hospitals. Include STATE when comparing hospitals. Round all numeric outputs to 2 decimal places. For top/best hospitals, order by PAYER_COMPOSITE_SCORE DESC. For worst/riskiest, order by PAYER_COMPOSITE_SCORE ASC or filter High Risk. MSPB_SPENDING_RATIO below 1.0 is cost efficient. EXCESS_READMISSION_RATIO below 1.0 is better than expected.'

  AI_QUESTION_CATEGORIZATION 'Covers hospital quality, readmission penalties, Medicare spending, patient experience, and state benchmarking from a payer perspective. Reject questions about individual patient records, PHI, or clinical diagnoses.';


----------------------------------------------------------------------
-- CORTEX AGENT: Hospital Payer Analytics Agent
----------------------------------------------------------------------
CREATE OR REPLACE AGENT HEALTHCARE_DB.ANALYTICS_SCHEMA.HOSPITAL_PAYER_AGENT
  COMMENT = 'Cortex Agent for hospital readmission and payer analytics - answers natural language questions about hospital quality, readmission penalties, cost efficiency, patient experience, and state benchmarking from a payer perspective'
  PROFILE = '{"display_name": "Hospital Payer Analytics Agent", "color": "blue"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  orchestration:
    budget:
      seconds: 60
      tokens: 16000

  instructions:
    response: >
      You are a hospital payer analytics expert. Respond concisely with data-driven insights.
      Always include hospital names and states when listing hospitals.
      Round numeric values to 2 decimal places.
      When presenting cost exposure, format as USD with commas.
      If a query returns many rows, summarize the key findings and show the top results.
      When comparing hospitals, highlight which are Top Performers vs Under Review.
    orchestration: >
      Use the PayerAnalytics tool for all questions about hospitals, readmissions, costs,
      patient experience, state benchmarking, penalties, and quality metrics.
      The data covers US hospitals with CMS quality measures from a payer (insurance company) perspective.
      Key concepts:
      - Excess Readmission Ratio below 1.0 means better than expected (good)
      - MSPB Spending Ratio below 1.0 means cost efficient (good)
      - Payer Composite Score is 0-100 (higher is better)
      - Network Tiers are Preferred, Standard, High Risk, Unrated
      - Composite Status values are Top Performer, Standard, Watch List, Under Review
      - HRRP conditions are AMI, Heart Failure, Pneumonia, COPD, Hip/Knee Replacement, CABG Surgery
    system: >
      You are an AI assistant for a health insurance payer organization.
      You help analysts evaluate hospital network quality, identify readmission penalty risks,
      assess cost efficiency, and compare state-level performance.
      Never fabricate data. Only use data returned by the tools.
      If the question cannot be answered with available data, say so clearly.
    sample_questions:
      - question: "Which are the top 10 hospitals by payer composite score?"
        answer: "I will query the hospital scorecard to find the top 10 hospitals ranked by their payer composite score."
      - question: "What is the total payer cost exposure from excess readmissions?"
        answer: "I will calculate the total estimated payer cost exposure across all hospitals and conditions from the readmission penalty data."
      - question: "Which states have the highest readmission penalty rates?"
        answer: "I will look at the state benchmarking data to find states with the highest percentage of penalized hospitals."
      - question: "Show me hospitals that are High Risk but have good patient satisfaction."
        answer: "I will cross-reference network tier with patient experience data to find High Risk hospitals that still have high star ratings."
      - question: "Compare cost efficiency across hospital ownership types."
        answer: "I will analyze MSPB spending ratios grouped by hospital ownership type to compare cost efficiency."

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "PayerAnalytics"
        description: >
          Queries hospital readmission and payer analytics data across 5 analytics tables:
          hospital scorecard (per-hospital composite metrics), readmission penalty risk
          (condition-level HRRP penalties), cost vs quality (spending efficiency and outcomes),
          state benchmarking (state-level aggregated metrics), and patient experience impact
          (HCAHPS satisfaction linked with readmission and cost). Use this tool for any question
          about hospital quality ratings, readmission ratios, Medicare spending, patient satisfaction
          star ratings, payer network tiers, penalty cost exposure, state rankings, or value-based
          purchasing eligibility.
    - tool_spec:
        type: "data_to_chart"
        name: "data_to_chart"
        description: "Generates visualizations from query results. Use when the user asks for charts, graphs, or visual comparisons."

  tool_resources:
    PayerAnalytics:
      semantic_view: "HEALTHCARE_DB.ANALYTICS_SCHEMA.HOSPITAL_PAYER_ANALYTICS_SV"
      execution_environment:
        type: "warehouse"
        warehouse: "COMPUTE_WH"
  $$;


----------------------------------------------------------------------
-- TEST THE AGENT
----------------------------------------------------------------------
-- SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
--   'HEALTHCARE_DB.ANALYTICS_SCHEMA.HOSPITAL_PAYER_AGENT',
--   '{ "messages": [{ "role": "user", "content": [{ "type": "text", "text": "What are the top 5 hospitals by payer composite score?" }] }] }'
-- );
