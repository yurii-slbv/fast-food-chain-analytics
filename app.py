
import pandas as pd
import streamlit as st
import altair as alt

st.set_page_config(page_title="Menu Intelligence", layout="wide")

# =====================================================
# 1. DATA & FILTERS
# =====================================================

df = pd.read_csv("data/menu_intelligence.csv")

st.title("Menu Intelligence")
st.caption("Product Profitability & Financial Impact | 17 May 2012 – 16 May 2013")

stores = sorted(df["store_num"].unique().tolist())

store = st.sidebar.selectbox(
    "Select Store", ["All Stores"] + stores
)

if store != "All Stores":
    df = df[df["store_num"] == store]

# Product aggregation
products = df.groupby("inv_num", as_index=False).agg(
    units_sold=("units_sold", "sum"),
    revenue=("item_sales", "sum"),
    cogs=("cogs", "sum")
)

products["gross_profit"] = products["revenue"] - products["cogs"]
products["unit_profit"] = (
    products["gross_profit"] /
    products["units_sold"].where(products["units_sold"] != 0)
)
products["gross_margin_pct"] = (
    products["gross_profit"] /
    products["revenue"].where(products["revenue"] != 0) * 100
)

# =====================================================
# 2. MENU ENGINEERING
# =====================================================

eligible = (
    (products["units_sold"] > 0) &
    (products["revenue"] > 0)
)

median_units = products.loc[eligible, "units_sold"].median()
median_profit = products.loc[eligible, "unit_profit"].median()

high_pop = products["units_sold"] >= median_units
high_profit = products["unit_profit"] >= median_profit

products["menu_segment"] = "Unclassified"

products.loc[
    eligible & high_pop & high_profit, "menu_segment"
] = "Star"

products.loc[
    eligible & high_pop & ~high_profit, "menu_segment"
] = "Plowhorse"

products.loc[
    eligible & ~high_pop & high_profit, "menu_segment"
] = "Puzzle"

products.loc[
    eligible & ~high_pop & ~high_profit, "menu_segment"
] = "Dog"

# =====================================================
# 3. PARETO CLASSIFICATION
# =====================================================

products = products.sort_values(
    "revenue", ascending=False
).reset_index(drop=True)

# Positive-revenue products for Pareto
pareto = products[products["revenue"] > 0].copy()

pareto["revenue_share_pct"] = (
    pareto["revenue"] / pareto["revenue"].sum() * 100
)

pareto["cumulative_pct"] = (
    pareto["revenue_share_pct"].cumsum()
)

pareto["rank"] = range(1, len(pareto) + 1)

# Include the product crossing the 80% threshold
pareto["pareto_80"] = (
    pareto["cumulative_pct"].shift(fill_value=0) < 80
)

priority_ids = pareto.loc[
    pareto["pareto_80"], "inv_num"
].tolist()

products["pareto_80"] = products["inv_num"].isin(priority_ids)

products["priority_opportunity"] = (
    products["pareto_80"] &
    (products["menu_segment"] == "Plowhorse")
)

priority = products[products["priority_opportunity"]].copy()

# =====================================================
# 4. KPI OVERVIEW
# =====================================================

revenue = products["revenue"].sum()
cogs = products["cogs"].sum()
profit = products["gross_profit"].sum()
margin = profit / revenue * 100 if revenue else 0

k1, k2, k3, k4, k5 = st.columns(5)

k1.metric("Item Sales", f"${revenue:,.0f}")
k2.metric("COGS", f"${cogs:,.0f}")
k3.metric("Gross Profit", f"${profit:,.0f}")
k4.metric("Gross Margin", f"{margin:.1f}%")
k5.metric("Products", len(products))

st.divider()

# =====================================================
# 5. PARETO ANALYSIS
# =====================================================

st.subheader("01 | Revenue Concentration — Pareto")

p1, p2, p3 = st.columns(3)

p1.metric("Pareto Products", len(priority_ids))
p2.metric(
    "Share of Portfolio",
    f"{len(priority_ids) / len(products) * 100:.1f}%"
)
p3.metric(
    "Revenue Concentration",
    f"{pareto.loc[pareto['pareto_80'], 'revenue'].sum() / pareto['revenue'].sum() * 100:.1f}%"
)


# Pareto threshold
pareto_pct = (
    pareto.loc[pareto["pareto_80"], "revenue"].sum()
    / pareto["revenue"].sum() * 100
)

threshold = pd.DataFrame({
    "rank": [len(priority_ids)],
    "cumulative_pct": [pareto_pct]
})

# Pareto curve
line = alt.Chart(pareto).mark_line(
    color="#78C7FF",
    strokeWidth=2
).encode(
    x=alt.X("rank:Q", title="Products Ranked by Revenue"),
   y=alt.Y(
    "cumulative_pct:Q",
    title="Cumulative Revenue (%)",
    scale=alt.Scale(domain=[0, 100]),
    axis=alt.Axis(format=".0f")
),
tooltip=[
    alt.Tooltip("rank:Q", title="Product Rank"),
    alt.Tooltip("cumulative_pct:Q", title="Cumulative Revenue (%)", format=".2f")
]
)

# Vertical threshold
vertical = alt.Chart(threshold).mark_rule(
    color="#FF9E54",
    strokeDash=[6, 5]
).encode(x="rank:Q")

# Horizontal threshold
horizontal = alt.Chart(threshold).mark_rule(
    color="#FF9E54",
    strokeDash=[6, 5]
).encode(y="cumulative_pct:Q")

# Intersection point
point = alt.Chart(threshold).mark_circle(
    size=110,
    color="#FF9E54"
).encode(
    x="rank:Q",
    y="cumulative_pct:Q"
)

# Label
label = alt.Chart(threshold).mark_text(
    align="left",
    dx=10,
    dy=-12,
    color="#FF9E54",
    fontSize=13
).encode(
    x="rank:Q",
    y="cumulative_pct:Q",
    text=alt.value(f"{len(priority_ids)} products | {pareto_pct:.1f}%")
)

st.altair_chart(
    line + vertical + horizontal + point + label,
    use_container_width=True
)

st.write("**Pareto Product List**")

st.dataframe(
    products.loc[products["pareto_80"], [
        "inv_num", "menu_segment", "units_sold",
        "revenue", "gross_profit", "gross_margin_pct"
    ]].round(2),
    hide_index=True,
    width="stretch"
)

# =====================================================
# 6. MENU ENGINEERING
# =====================================================

st.divider()
st.subheader("02 | Menu Engineering")

plot_data = products.copy()

chart = alt.Chart(plot_data).mark_circle(size=90).encode(
    x=alt.X("units_sold:Q", title="Units Sold"),
    y=alt.Y("unit_profit:Q", title="Gross Profit per Unit"),
   color=alt.Color(
    "menu_segment:N",
    title="Menu Segment",
    sort=["Star", "Plowhorse", "Puzzle", "Dog", "Unclassified"],
    legend=alt.Legend(
        labelLimit=400,
        labelExpr=(
            "datum.label === 'Star' ? 'Star — High sales, high unit profit' : "
            "datum.label === 'Plowhorse' ? 'Plowhorse — High sales, low unit profit' : "
            "datum.label === 'Puzzle' ? 'Puzzle — Low sales, high unit profit' : "
            "datum.label === 'Dog' ? 'Dog — Low sales, low unit profit' : "
            "'Unclassified — Non-positive sales or quantity'"
        )
    )
),
    tooltip=[
        alt.Tooltip("inv_num:N", title="Product ID"),
        alt.Tooltip("menu_segment:N", title="Segment"),
        alt.Tooltip("units_sold:Q", title="Units Sold", format=","),
        alt.Tooltip("unit_profit:Q", title="Unit Profit", format=".2f"),
        alt.Tooltip("revenue:Q", title="Revenue", format=",.2f"),
        alt.Tooltip("gross_margin_pct:Q", title="Gross Margin %", format=".1f")
    ]
).interactive()

st.altair_chart(chart, use_container_width=True)

st.caption(
    f"Median popularity: {median_units:,.0f} units | "
    f"Median profitability: ${median_profit:.2f} per unit"
)

segment_summary = products.groupby(
    "menu_segment", as_index=False
).agg(
    products=("inv_num", "count"),
    revenue=("revenue", "sum"),
    gross_profit=("gross_profit", "sum")
)

st.dataframe(
    segment_summary.round(2),
    hide_index=True,
    width="stretch"
)

# =====================================================
# 7. PRIORITY OPPORTUNITIES
# =====================================================

st.divider()
st.subheader("03 | Priority Opportunities")

st.write(
    "Products meeting two criteria: "
    "**1)** Part of the Pareto 80% revenue group. "
    "**2)** High sales volume but below-median profit per unit (Plowhorse)."
)

a, b, c = st.columns(3)

a.metric("Priority Products", len(priority))
b.metric("Combined Item Sales", f"${priority['revenue'].sum():,.0f}")
c.metric("Combined Gross Profit", f"${priority['gross_profit'].sum():,.0f}")

st.dataframe(
    priority[[
        "inv_num", "units_sold", "revenue",
        "cogs", "gross_profit", "gross_margin_pct",
        "unit_profit"
    ]].round(2),
    hide_index=True,
    width="stretch"
)

st.caption(
    "These products are candidates for pricing and cost review, "
    "not automatically underperforming products."
)

# =====================================================
# 8. PRODUCT PERFORMANCE
# =====================================================

st.divider()
st.subheader("04 | Product Performance")

segments = st.multiselect(
    "Menu Segment",
    ["Star", "Plowhorse", "Puzzle", "Dog", "Unclassified"],
    default=["Star", "Plowhorse", "Puzzle", "Dog", "Unclassified"]
)

only_pareto = st.checkbox("Show Pareto 80% Products Only")

table = products[products["menu_segment"].isin(segments)]

if only_pareto:
    table = table[table["pareto_80"]]

st.dataframe(
    table[[
        "inv_num", "menu_segment", "pareto_80",
        "units_sold", "revenue", "cogs",
        "gross_profit", "gross_margin_pct", "unit_profit"
    ]].round(2),
    hide_index=True,
    width="stretch"
)

# =====================================================
# 9. FINANCIAL IMPACT — WHAT-IF SCENARIO
# =====================================================

st.divider()
st.subheader("05 | Financial Impact — What-if Simulator")

scope = st.selectbox(
    "Product Selection",
    [
        "Priority Opportunities",
        "Pareto 80% Products",
        "All Products"
    ]
)

if scope == "Priority Opportunities":
    scenario_products = priority.copy()
elif scope == "Pareto 80% Products":
    scenario_products = products[products["pareto_80"]].copy()
else:
    scenario_products = products.copy()

scenario_products = scenario_products[
    (scenario_products["units_sold"] > 0) &
    (scenario_products["revenue"] > 0)
]

if scenario_products.empty:
    st.warning("No eligible products in this selection.")
else:
    product_id = st.selectbox(
        "Select Product ID",
        scenario_products["inv_num"].tolist()
    )

    selected = scenario_products[
        scenario_products["inv_num"] == product_id
    ].iloc[0]

    st.write(
        f"**Segment:** {selected['menu_segment']} | "
        f"**Units Sold:** {selected['units_sold']:,.0f} | "
        f"**Gross Margin:** {selected['gross_margin_pct']:.1f}%"
    )

    c1, c2, c3 = st.columns(3)

    with c1:
        price_change = st.slider(
            "Price Change (%)", -20, 20, 0
        )

    with c2:
        cost_change = st.slider(
            "Unit COGS Change (%)", -20, 20, 0
        )

    with c3:
        volume_change = st.slider(
            "Sales Volume Change (%)", -30, 30, 0
        )

    # Baseline
    base_revenue = selected["revenue"]
    base_cogs = selected["cogs"]
    base_profit = base_revenue - base_cogs

    # Scenario
    new_revenue = (
        base_revenue *
        (1 + price_change / 100) *
        (1 + volume_change / 100)
    )

    new_cogs = (
        base_cogs *
        (1 + cost_change / 100) *
        (1 + volume_change / 100)
    )

    new_profit = new_revenue - new_cogs
    profit_impact = new_profit - base_profit

    impact_pct = (
        profit_impact / abs(base_profit) * 100
        if base_profit != 0 else 0
    )

    s1, s2, s3, s4 = st.columns(4)

    s1.metric("Current Gross Profit", f"${base_profit:,.0f}")
    s2.metric("Scenario Gross Profit", f"${new_profit:,.0f}")
    s3.metric("Profit Impact", f"${profit_impact:+,.0f}")
    s4.metric("Profit Change", f"{impact_pct:+.1f}%")

    comparison = pd.DataFrame({
        "Scenario": ["Current", "What-if"],
        "Gross Profit": [base_profit, new_profit]
    })

    st.bar_chart(
        comparison,
        x="Scenario",
        y="Gross Profit"
    )

    st.caption(
        "Scenarios assume independent changes in price, unit cost "
        "and volume. Demand response is not predicted. "
        "All financial impacts represent gross profit, not net profit."
    )

# =====================================================
# 10. EXPORT
# =====================================================

st.divider()

st.download_button(
    "Download Product Performance",
    data=products.to_csv(index=False),
    file_name="product_performance.csv",
    mime="text/csv"
)
