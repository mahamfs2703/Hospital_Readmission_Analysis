import streamlit as st
from snowflake.snowpark.context import get_active_session
import pandas as pd
import altair as alt

session = get_active_session()

DB_SCHEMA = "HEALTHCARE_DB.ANALYTICS_SCHEMA"

st.set_page_config(layout="wide")
st.title("Hospital Readmission & Payer Analytics")

@st.cache_data(ttl=1800)
def load_table(table_name):
    return session.sql(f"SELECT * FROM {DB_SCHEMA}.{table_name} LIMIT 5000").to_pandas()

scorecard = load_table("ANALYTICS_HOSPITAL_PAYER_SCORECARD")
penalty = load_table("ANALYTICS_READMISSION_PENALTY_RISK")
cost_quality = load_table("ANALYTICS_COST_VS_QUALITY")
state_bench = load_table("ANALYTICS_STATE_BENCHMARKING")
patient_exp = load_table("ANALYTICS_PATIENT_EXPERIENCE_IMPACT")

required_cols = ["FACILITY_ID", "PAYER_COMPOSITE_SCORE"]
if not set(required_cols).issubset(scorecard.columns):
    st.error("Missing required columns in scorecard view")
    st.stop()

tab1, tab2, tab3, tab4, tab5, tab6 = st.tabs([
    "Overview",
    "Hospital Scorecard",
    "Readmission Penalty Risk",
    "Cost vs Quality",
    "State Benchmarking",
    "Patient Experience"
])

# ─────────────────────────── TAB 1: OVERVIEW ───────────────────────────
with tab1:
    st.header("Portfolio Overview")

    total_hospitals = scorecard["FACILITY_ID"].nunique()
    avg_composite = scorecard["PAYER_COMPOSITE_SCORE"].mean()
    avg_readm = scorecard["AVG_EXCESS_READMISSION_RATIO"].mean()
    avg_spend = scorecard["MSPB_SPENDING_RATIO"].mean()

    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Total Hospitals", f"{total_hospitals:,}")
    c2.metric("Avg Composite Score", f"{avg_composite:.1f}" if pd.notna(avg_composite) else "N/A")
    c3.metric("Avg Excess Readmission Ratio", f"{avg_readm:.4f}" if pd.notna(avg_readm) else "N/A")
    c4.metric("Avg Spending Ratio (MSPB)", f"{avg_spend:.4f}" if pd.notna(avg_spend) else "N/A")

    st.subheader("Network Tier Distribution")
    tier_counts = scorecard["PAYER_NETWORK_TIER"].value_counts().reset_index()
    tier_counts.columns = ["Tier", "Count"]
    tier_chart = alt.Chart(tier_counts).mark_arc(innerRadius=50).encode(
        theta=alt.Theta("Count:Q"),
        color=alt.Color("Tier:N", scale=alt.Scale(
            domain=["Preferred", "Standard", "High Risk", "Unrated"],
            range=["#2ecc71", "#3498db", "#e74c3c", "#95a5a6"]
        )),
        tooltip=["Tier", "Count"]
    ).properties(width=350, height=350)

    status_counts = scorecard["PAYER_COMPOSITE_STATUS"].value_counts().reset_index()
    status_counts.columns = ["Status", "Count"]
    status_chart = alt.Chart(status_counts).mark_bar().encode(
        x=alt.X("Count:Q"),
        y=alt.Y("Status:N", sort="-x"),
        color=alt.Color("Status:N", scale=alt.Scale(
            domain=["Top Performer", "Standard", "Watch List", "Under Review"],
            range=["#2ecc71", "#3498db", "#f39c12", "#e74c3c"]
        )),
        tooltip=["Status", "Count"]
    ).properties(width=350, height=250)

    left, right = st.columns(2)
    left.altair_chart(tier_chart, use_container_width=True)
    right.altair_chart(status_chart, use_container_width=True)

    st.subheader("Composite Score Distribution")
    score_hist = alt.Chart(scorecard.dropna(subset=["PAYER_COMPOSITE_SCORE"])).mark_bar(
        opacity=0.8, color="#3498db"
    ).encode(
        x=alt.X("PAYER_COMPOSITE_SCORE:Q", bin=alt.Bin(maxbins=30), title="Payer Composite Score"),
        y=alt.Y("count()", title="Number of Hospitals"),
        tooltip=["count()"]
    ).properties(height=300)
    st.altair_chart(score_hist, use_container_width=True)


# ─────────────────────────── TAB 2: HOSPITAL SCORECARD ───────────────────────────
with tab2:
    st.header("Hospital Payer Scorecard")

    f1, f2, f3 = st.columns(3)
    states = ["All"] + sorted(scorecard["STATE"].dropna().unique().tolist())
    sel_state = f1.selectbox("State", states, key="sc_state")
    tiers = ["All"] + sorted(scorecard["PAYER_NETWORK_TIER"].dropna().unique().tolist())
    sel_tier = f2.selectbox("Network Tier", tiers, key="sc_tier")
    statuses = ["All"] + sorted(scorecard["PAYER_COMPOSITE_STATUS"].dropna().unique().tolist())
    sel_status = f3.selectbox("Composite Status", statuses, key="sc_status")

    df = scorecard.copy()
    if sel_state != "All":
        df = df[df["STATE"] == sel_state]
    if sel_tier != "All":
        df = df[df["PAYER_NETWORK_TIER"] == sel_tier]
    if sel_status != "All":
        df = df[df["PAYER_COMPOSITE_STATUS"] == sel_status]

    if df.empty:
        st.warning("No data available for selected filters")
        st.stop()

    st.metric("Hospitals Shown", len(df))

    display_cols = [
        "FACILITY_ID", "FACILITY_NAME", "STATE", "OVERALL_RATING",
        "PAYER_NETWORK_TIER", "PAYER_COMPOSITE_STATUS", "PAYER_COMPOSITE_SCORE",
        "AVG_EXCESS_READMISSION_RATIO", "MSPB_SPENDING_RATIO",
        "CONDITIONS_PENALIZED", "PATIENT_EXPERIENCE_STAR"
    ]
    st.dataframe(
        df[display_cols].sort_values("PAYER_COMPOSITE_SCORE", ascending=False),
        use_container_width=True,
        height=500
    )

    st.subheader("Score vs Spending Ratio")
    scatter = alt.Chart(df.dropna(subset=["PAYER_COMPOSITE_SCORE", "MSPB_SPENDING_RATIO"])).mark_circle(size=40).encode(
        x=alt.X("MSPB_SPENDING_RATIO:Q", title="MSPB Spending Ratio", scale=alt.Scale(zero=False)),
        y=alt.Y("PAYER_COMPOSITE_SCORE:Q", title="Payer Composite Score"),
        color=alt.Color("PAYER_NETWORK_TIER:N", scale=alt.Scale(
            domain=["Preferred", "Standard", "High Risk", "Unrated"],
            range=["#2ecc71", "#3498db", "#e74c3c", "#95a5a6"]
        )),
        tooltip=["FACILITY_NAME", "STATE", "PAYER_COMPOSITE_SCORE", "MSPB_SPENDING_RATIO", "PAYER_NETWORK_TIER"]
    ).properties(height=400)
    rule = alt.Chart(pd.DataFrame({"x": [1.0]})).mark_rule(strokeDash=[4, 4], color="red").encode(x="x:Q")
    st.altair_chart(scatter + rule, use_container_width=True)


# ─────────────────────────── TAB 3: READMISSION PENALTY RISK ───────────────────────────
with tab3:
    st.header("Readmission Penalty Risk Analysis")

    f1, f2 = st.columns(2)
    conditions = ["All"] + sorted(penalty["CONDITION_CATEGORY"].dropna().unique().tolist())
    sel_cond = f1.selectbox("Condition", conditions, key="rp_cond")
    risk_tiers = ["All"] + sorted(penalty["PAYER_RISK_TIER"].dropna().unique().tolist())
    sel_risk = f2.selectbox("Payer Risk Tier", risk_tiers, key="rp_risk")

    pdf = penalty.copy()
    if sel_cond != "All":
        pdf = pdf[pdf["CONDITION_CATEGORY"] == sel_cond]
    if sel_risk != "All":
        pdf = pdf[pdf["PAYER_RISK_TIER"] == sel_risk]

    if pdf.empty:
        st.warning("No data available for selected filters")
        st.stop()

    pdf_with_data = pdf.dropna(subset=["EXCESS_READMISSION_RATIO"])
    m1, m2, m3, m4 = st.columns(4)
    m1.metric("Records (with data)", f"{len(pdf_with_data):,}")
    m2.metric("Hospitals", f"{pdf_with_data['FACILITY_ID'].nunique():,}")
    penalized_count = (pdf_with_data["PENALTY_STATUS"] == "Penalized (Above Expected)").sum()
    m3.metric("Penalized Conditions", f"{penalized_count:,}")
    total_cost_exp = pdf_with_data["ESTIMATED_PAYER_COST_EXPOSURE"].sum()
    m4.metric("Total Cost Exposure", f"${total_cost_exp:,.0f}")

    st.subheader("Excess Readmission Ratio by Condition")
    box = alt.Chart(pdf.dropna(subset=["EXCESS_READMISSION_RATIO", "CONDITION_CATEGORY"])).mark_boxplot(
        extent="min-max"
    ).encode(
        x=alt.X("CONDITION_CATEGORY:N", title="Condition"),
        y=alt.Y("EXCESS_READMISSION_RATIO:Q", title="Excess Readmission Ratio", scale=alt.Scale(zero=False)),
        color="CONDITION_CATEGORY:N"
    ).properties(height=400)
    rule = alt.Chart(pd.DataFrame({"y": [1.0]})).mark_rule(strokeDash=[4, 4], color="red").encode(y="y:Q")
    st.altair_chart(box + rule, use_container_width=True)

    st.subheader("Top 20 Hospitals by Estimated Payer Cost Exposure")
    top_cost = pdf.nlargest(20, "ESTIMATED_PAYER_COST_EXPOSURE").copy()
    top_cost["DISPLAY_LABEL"] = top_cost["FACILITY_NAME"] + " (" + top_cost["CONDITION_CATEGORY"].fillna("Unknown") + ")"
    bar = alt.Chart(top_cost).mark_bar(color="#e74c3c").encode(
        x=alt.X("ESTIMATED_PAYER_COST_EXPOSURE:Q", title="Estimated Payer Cost Exposure ($)"),
        y=alt.Y("DISPLAY_LABEL:N", sort="-x", title=""),
        tooltip=["FACILITY_NAME", "STATE", "CONDITION_CATEGORY", "EXCESS_READMISSION_RATIO", "ESTIMATED_PAYER_COST_EXPOSURE"]
    ).properties(height=500)
    st.altair_chart(bar, use_container_width=True)


# ─────────────────────────── TAB 4: COST VS QUALITY ───────────────────────────
with tab4:
    st.header("Cost vs Quality Analysis")

    f1, f2 = st.columns(2)
    quadrants = ["All"] + sorted(cost_quality["PAYER_VALUE_QUADRANT"].dropna().unique().tolist())
    sel_quad = f1.selectbox("Value Quadrant", quadrants, key="cq_quad")
    ownerships = ["All"] + sorted(cost_quality["HOSPITAL_OWNERSHIP"].dropna().unique().tolist())
    sel_own = f2.selectbox("Hospital Ownership", ownerships, key="cq_own")

    cdf = cost_quality.copy()
    if sel_quad != "All":
        cdf = cdf[cdf["PAYER_VALUE_QUADRANT"] == sel_quad]
    if sel_own != "All":
        cdf = cdf[cdf["HOSPITAL_OWNERSHIP"] == sel_own]

    if cdf.empty:
        st.warning("No data available for selected filters")
        st.stop()

    m1, m2, m3 = st.columns(3)
    m1.metric("Hospitals", f"{cdf['FACILITY_ID'].nunique():,}")
    _cq_spend = cdf['MSPB_SPENDING_RATIO'].mean()
    _cq_readm = cdf['AVG_EXCESS_READMISSION_RATIO'].mean()
    m2.metric("Avg Spending Ratio", f"{_cq_spend:.4f}" if pd.notna(_cq_spend) else "N/A")
    m3.metric("Avg Excess Readmission Ratio", f"{_cq_readm:.4f}" if pd.notna(_cq_readm) else "N/A")

    st.subheader("Value Quadrant Distribution")
    quad_counts = cdf["PAYER_VALUE_QUADRANT"].value_counts().reset_index()
    quad_counts.columns = ["Quadrant", "Count"]
    qchart = alt.Chart(quad_counts).mark_bar().encode(
        x=alt.X("Count:Q"),
        y=alt.Y("Quadrant:N", sort="-x"),
        color=alt.Color("Quadrant:N", scale=alt.Scale(
            domain=["High Value", "High Cost / Good Quality", "Low Cost / Quality Gap", "Moderate Value", "Low Value"],
            range=["#2ecc71", "#3498db", "#f39c12", "#95a5a6", "#e74c3c"]
        )),
        tooltip=["Quadrant", "Count"]
    ).properties(height=250)
    st.altair_chart(qchart, use_container_width=True)

    st.subheader("Spending Ratio vs Readmission Ratio")
    scatter = alt.Chart(
        cdf.dropna(subset=["MSPB_SPENDING_RATIO", "AVG_EXCESS_READMISSION_RATIO"])
    ).mark_circle(size=40).encode(
        x=alt.X("MSPB_SPENDING_RATIO:Q", title="MSPB Spending Ratio", scale=alt.Scale(zero=False)),
        y=alt.Y("AVG_EXCESS_READMISSION_RATIO:Q", title="Avg Excess Readmission Ratio", scale=alt.Scale(zero=False)),
        color=alt.Color("PAYER_VALUE_QUADRANT:N", scale=alt.Scale(
            domain=["High Value", "High Cost / Good Quality", "Low Cost / Quality Gap", "Moderate Value", "Low Value"],
            range=["#2ecc71", "#3498db", "#f39c12", "#95a5a6", "#e74c3c"]
        )),
        tooltip=["FACILITY_NAME", "STATE", "PAYER_VALUE_QUADRANT", "MSPB_SPENDING_RATIO", "AVG_EXCESS_READMISSION_RATIO"]
    ).properties(height=450)
    hline = alt.Chart(pd.DataFrame({"y": [1.0]})).mark_rule(strokeDash=[4, 4], color="gray").encode(y="y:Q")
    vline = alt.Chart(pd.DataFrame({"x": [1.0]})).mark_rule(strokeDash=[4, 4], color="gray").encode(x="x:Q")
    st.altair_chart(scatter + hline + vline, use_container_width=True)


# ─────────────────────────── TAB 5: STATE BENCHMARKING ───────────────────────────
with tab5:
    st.header("State-Level Payer Benchmarking")

    m1, m2, m3, m4 = st.columns(4)
    m1.metric("States", f"{state_bench['STATE'].nunique()}")
    m2.metric("Total Hospitals", f"{state_bench['TOTAL_HOSPITALS'].sum():,}")
    m3.metric("Avg Readmission Ratio", f"{state_bench['AVG_EXCESS_READMISSION_RATIO'].mean():.4f}")
    m4.metric("Avg Spending Ratio", f"{state_bench['AVG_SPENDING_RATIO'].mean():.4f}")

    st.subheader("States Ranked by Readmission Performance")
    state_sorted = state_bench.sort_values("AVG_EXCESS_READMISSION_RATIO", ascending=True).head(25)
    bar = alt.Chart(state_sorted).mark_bar().encode(
        x=alt.X("AVG_EXCESS_READMISSION_RATIO:Q", title="Avg Excess Readmission Ratio"),
        y=alt.Y("STATE:N", sort=alt.EncodingSortField(field="AVG_EXCESS_READMISSION_RATIO", order="ascending"), title=""),
        color=alt.condition(
            alt.datum.AVG_EXCESS_READMISSION_RATIO > 1.0,
            alt.value("#e74c3c"),
            alt.value("#2ecc71")
        ),
        tooltip=["STATE", "TOTAL_HOSPITALS", "AVG_EXCESS_READMISSION_RATIO", "AVG_SPENDING_RATIO", "PCT_HOSPITALS_PENALIZED"]
    ).properties(height=600)
    rule = alt.Chart(pd.DataFrame({"x": [1.0]})).mark_rule(strokeDash=[4, 4], color="black").encode(x="x:Q")
    st.altair_chart(bar + rule, use_container_width=True)

    st.subheader("State Network Tier Composition")
    tier_data = state_bench[["STATE", "PREFERRED_TIER_HOSPITALS", "STANDARD_TIER_HOSPITALS",
                             "HIGH_RISK_TIER_HOSPITALS", "UNRATED_HOSPITALS"]].melt(
        id_vars=["STATE"], var_name="Tier", value_name="Count"
    )
    tier_data["Tier"] = tier_data["Tier"].str.replace("_TIER_HOSPITALS", "").str.replace("_HOSPITALS", "").str.replace("_", " ").str.title()
    stacked = alt.Chart(tier_data).mark_bar().encode(
        x=alt.X("Count:Q", stack="normalize", title="Proportion"),
        y=alt.Y("STATE:N", sort=alt.EncodingSortField(field="Count", op="sum", order="descending"), title=""),
        color=alt.Color("Tier:N", scale=alt.Scale(
            domain=["Preferred", "Standard", "High Risk", "Unrated"],
            range=["#2ecc71", "#3498db", "#e74c3c", "#95a5a6"]
        )),
        tooltip=["STATE", "Tier", "Count"]
    ).properties(height=800)
    st.altair_chart(stacked, use_container_width=True)

    st.subheader("Spending vs Readmission by State")
    state_scatter = alt.Chart(
        state_bench.dropna(subset=["AVG_SPENDING_RATIO", "AVG_EXCESS_READMISSION_RATIO"])
    ).mark_circle(size=80).encode(
        x=alt.X("AVG_SPENDING_RATIO:Q", title="Avg Spending Ratio", scale=alt.Scale(zero=False)),
        y=alt.Y("AVG_EXCESS_READMISSION_RATIO:Q", title="Avg Excess Readmission Ratio", scale=alt.Scale(zero=False)),
        size=alt.Size("TOTAL_HOSPITALS:Q", title="Total Hospitals"),
        tooltip=["STATE", "TOTAL_HOSPITALS", "AVG_SPENDING_RATIO", "AVG_EXCESS_READMISSION_RATIO",
                  "AVG_PATIENT_STAR_RATING", "PCT_HOSPITALS_PENALIZED"]
    ).properties(height=450)
    hline = alt.Chart(pd.DataFrame({"y": [1.0]})).mark_rule(strokeDash=[4, 4], color="gray").encode(y="y:Q")
    vline = alt.Chart(pd.DataFrame({"x": [1.0]})).mark_rule(strokeDash=[4, 4], color="gray").encode(x="x:Q")
    st.altair_chart(state_scatter + hline + vline, use_container_width=True)


# ─────────────────────────── TAB 6: PATIENT EXPERIENCE ───────────────────────────
with tab6:
    st.header("Patient Experience Impact Analysis")

    f1, f2 = st.columns(2)
    pe_states = ["All"] + sorted(patient_exp["STATE"].dropna().unique().tolist())
    sel_pe_state = f1.selectbox("State", pe_states, key="pe_state")
    pe_quads = ["All"] + sorted(patient_exp["EXPERIENCE_READMISSION_QUADRANT"].dropna().unique().tolist())
    sel_pe_quad = f2.selectbox("Experience-Readmission Quadrant", pe_quads, key="pe_quad")

    pedf = patient_exp.copy()
    if sel_pe_state != "All":
        pedf = pedf[pedf["STATE"] == sel_pe_state]
    if sel_pe_quad != "All":
        pedf = pedf[pedf["EXPERIENCE_READMISSION_QUADRANT"] == sel_pe_quad]

    if pedf.empty:
        st.warning("No data available for selected filters")
        st.stop()

    pe_with_star = pedf.dropna(subset=["OVERALL_STAR_RATING"])
    m1, m2, m3, m4 = st.columns(4)
    m1.metric("Hospitals", f"{pedf['FACILITY_ID'].nunique():,}")
    _avg_star = pe_with_star["OVERALL_STAR_RATING"].mean()
    m2.metric("Avg Star Rating", f"{_avg_star:.2f}" if pd.notna(_avg_star) else "N/A")
    _avg_domain = pe_with_star["AVG_DOMAIN_STAR_RATING"].mean()
    m3.metric("Avg Domain Star Rating", f"{_avg_domain:.2f}" if pd.notna(_avg_domain) else "N/A")
    vbp_eligible = (pedf["VBP_INCENTIVE_ELIGIBILITY"] == "Eligible").sum()
    m4.metric("VBP Incentive Eligible", f"{vbp_eligible:,}")

    st.subheader("Experience-Readmission Quadrant Distribution")
    quad_data = pedf["EXPERIENCE_READMISSION_QUADRANT"].value_counts().reset_index()
    quad_data.columns = ["Quadrant", "Count"]
    pe_quad_chart = alt.Chart(quad_data).mark_bar().encode(
        x=alt.X("Count:Q"),
        y=alt.Y("Quadrant:N", sort="-x"),
        color=alt.Color("Quadrant:N", scale=alt.Scale(
            domain=["High Satisfaction / Low Readmission", "High Satisfaction / High Readmission",
                    "Moderate", "Low Satisfaction / Low Readmission", "Low Satisfaction / High Readmission"],
            range=["#2ecc71", "#f39c12", "#95a5a6", "#3498db", "#e74c3c"]
        )),
        tooltip=["Quadrant", "Count"]
    ).properties(height=250)
    st.altair_chart(pe_quad_chart, use_container_width=True)

    st.subheader("Star Rating vs Excess Readmission Ratio")
    pe_scatter = alt.Chart(
        pe_with_star.dropna(subset=["AVG_EXCESS_READMISSION_RATIO"])
    ).mark_circle(size=40, opacity=0.6).encode(
        x=alt.X("OVERALL_STAR_RATING:Q", title="Overall Star Rating", scale=alt.Scale(domain=[0.5, 5.5])),
        y=alt.Y("AVG_EXCESS_READMISSION_RATIO:Q", title="Avg Excess Readmission Ratio", scale=alt.Scale(zero=False)),
        color=alt.Color("EXPERIENCE_READMISSION_QUADRANT:N", title="Quadrant", scale=alt.Scale(
            domain=["High Satisfaction / Low Readmission", "High Satisfaction / High Readmission",
                    "Moderate", "Low Satisfaction / Low Readmission", "Low Satisfaction / High Readmission"],
            range=["#2ecc71", "#f39c12", "#95a5a6", "#3498db", "#e74c3c"]
        )),
        tooltip=["FACILITY_NAME", "STATE", "OVERALL_STAR_RATING", "AVG_EXCESS_READMISSION_RATIO",
                 "EXPERIENCE_READMISSION_QUADRANT", "VBP_INCENTIVE_ELIGIBILITY"]
    ).properties(height=450)
    pe_hline = alt.Chart(pd.DataFrame({"y": [1.0]})).mark_rule(strokeDash=[4, 4], color="gray").encode(y="y:Q")
    st.altair_chart(pe_scatter + pe_hline, use_container_width=True)

    st.subheader("Domain Star Ratings Comparison")
    domain_cols = ["NURSE_COMM_STAR", "DOCTOR_COMM_STAR", "MED_COMM_STAR", "DISCHARGE_INFO_STAR", "CLEANLINESS_STAR"]
    domain_labels = ["Nurse Comm", "Doctor Comm", "Med Comm", "Discharge Info", "Cleanliness"]
    domain_avgs = [pe_with_star[c].mean() for c in domain_cols]
    domain_df = pd.DataFrame({"Domain": domain_labels, "Avg Star Rating": domain_avgs}).dropna()
    domain_bar = alt.Chart(domain_df).mark_bar(color="#3498db").encode(
        x=alt.X("Avg Star Rating:Q", scale=alt.Scale(domain=[0, 5]), title="Avg Star Rating"),
        y=alt.Y("Domain:N", sort="-x", title=""),
        tooltip=["Domain", "Avg Star Rating"]
    ).properties(height=250)
    st.altair_chart(domain_bar, use_container_width=True)
