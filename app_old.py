from pathlib import Path

output_path = Path("/mnt/data/app_clean.py")

code = r'''import pandas as pd
import plotly.express as px
import psycopg2
import streamlit as st


# =========================================================
# PAGE CONFIGURATION
# =========================================================
st.set_page_config(
    page_title="Jewelry Operations Analytics",
    page_icon="💎",
    layout="wide",
)


# =========================================================
# CUSTOM CSS
# =========================================================
st.markdown(
    """
    <style>
        .block-container {
            max-width: 1450px;
            padding-top: 1.6rem;
            padding-bottom: 3rem;
        }

        h1 {
            font-size: 2.25rem !important;
            margin-bottom: 0.2rem !important;
        }

        h2 {
            font-size: 1.45rem !important;
            margin-top: 1.8rem !important;
            padding-bottom: 0.45rem;
            border-bottom: 2px solid rgba(184, 134, 11, 0.35);
        }

        div[data-testid="stMetric"] {
            background: rgba(184, 134, 11, 0.06);
            border: 1px solid rgba(184, 134, 11, 0.22);
            border-radius: 14px;
            padding: 1rem;
            min-height: 120px;
        }

        div[data-testid="stMetricLabel"] {
            font-weight: 600;
        }

        div[data-testid="stDataFrame"] {
            border: 1px solid rgba(128, 128, 128, 0.18);
            border-radius: 12px;
            overflow: hidden;
        }

        .dashboard-subtitle {
            color: #6b7280;
            font-size: 1rem;
            margin-bottom: 1.4rem;
        }

        .section-note {
            color: #6b7280;
            font-size: 0.92rem;
            margin-top: -0.4rem;
            margin-bottom: 0.8rem;
        }

        .dashboard-footer {
            text-align: center;
            color: #8a8a8a;
            font-size: 0.85rem;
            padding-top: 2rem;
        }
    </style>
    """,
    unsafe_allow_html=True,
)


# =========================================================
# CONSTANTS
# =========================================================
CHART_HEIGHT = 410
PLOTLY_CONFIG = {
    "displayModeBar": False,
    "responsive": True,
}


# =========================================================
# DATABASE FUNCTIONS
# =========================================================
@st.cache_resource
def get_connection():
    """Create and cache the PostgreSQL connection."""
    return psycopg2.connect(
        host=st.secrets["postgres"]["host"],
        port=st.secrets["postgres"]["port"],
        database=st.secrets["postgres"]["database"],
        user=st.secrets["postgres"]["user"],
        password=st.secrets["postgres"]["password"],
    )


@st.cache_data(ttl=600)
def run_query(query: str) -> pd.DataFrame:
    """Run a SQL query and return the results as a DataFrame."""
    connection = get_connection()

    with connection.cursor() as cursor:
        cursor.execute(query)
        columns = [column[0] for column in cursor.description]
        rows = cursor.fetchall()

    return pd.DataFrame(rows, columns=columns)


# =========================================================
# DISPLAY HELPERS
# =========================================================
def make_numeric(dataframe: pd.DataFrame, columns: list[str]) -> pd.DataFrame:
    """Convert selected columns to numeric values when they exist."""
    dataframe = dataframe.copy()

    for column in columns:
        if column in dataframe.columns:
            dataframe[column] = pd.to_numeric(
                dataframe[column],
                errors="coerce",
            )

    return dataframe


def style_chart(figure, height: int = CHART_HEIGHT):
    """Apply one consistent layout to every Plotly chart."""
    figure.update_layout(
        height=height,
        margin=dict(l=20, r=20, t=60, b=30),
        template="plotly_white",
        legend_title_text="",
        hoverlabel=dict(font_size=13),
    )
    return figure


def show_chart(figure):
    """Display a Plotly chart with the shared dashboard configuration."""
    st.plotly_chart(
        style_chart(figure),
        use_container_width=True,
        config=PLOTLY_CONFIG,
    )


def section_title(title: str, note: str | None = None):
    """Display a consistent section heading."""
    st.subheader(title)

    if note:
        st.markdown(
            f'<div class="section-note">{note}</div>',
            unsafe_allow_html=True,
        )


# =========================================================
# DATABASE CONNECTION CHECK
# =========================================================
try:
    get_connection()
    st.sidebar.success("PostgreSQL connected")
except Exception as error:
    st.error(f"Database connection failed: {error}")
    st.stop()


# =========================================================
# HEADER
# =========================================================
st.title("💎 Jewelry Operations Analytics")
st.markdown(
    """
    <div class="dashboard-subtitle">
        SQL-powered analytics for sales, customers, products, inventory,
        branches, and employees.
    </div>
    """,
    unsafe_allow_html=True,
)


# =========================================================
# LOAD DATA
# =========================================================
executive_df = run_query(
    "SELECT * FROM analytics.executive_summary;"
)

monthly_df = run_query(
    """
    SELECT *
    FROM analytics.monthly_sales_summary
    ORDER BY sales_month;
    """
)

branch_df = run_query(
    """
    SELECT *
    FROM analytics.branch_performance
    ORDER BY net_revenue DESC;
    """
)

customer_df = run_query(
    """
    SELECT *
    FROM analytics.customer_summary
    ORDER BY total_spent DESC;
    """
)

customer_segment_raw = run_query(
    "SELECT * FROM analytics.customer_segments;"
)

product_df = run_query(
    """
    SELECT *
    FROM analytics.product_performance
    ORDER BY gross_revenue DESC;
    """
)

inventory_df = run_query(
    """
    SELECT *
    FROM analytics.inventory_risk
    ORDER BY stock_quantity ASC;
    """
)

employee_df = run_query(
    """
    SELECT *
    FROM analytics.employee_performance
    ORDER BY net_revenue DESC;
    """
)


# =========================================================
# PREPARE DATA
# =========================================================
monthly_df["sales_month"] = pd.to_datetime(
    monthly_df["sales_month"],
    errors="coerce",
)

branch_df = make_numeric(
    branch_df,
    ["net_revenue", "estimated_net_profit"],
)

customer_df = make_numeric(
    customer_df,
    ["total_spent", "average_transaction_value"],
)

product_df = make_numeric(
    product_df,
    ["gross_revenue"],
)

employee_df = make_numeric(
    employee_df,
    ["net_revenue", "estimated_net_profit"],
)


# =========================================================
# SIDEBAR FILTER
# =========================================================
st.sidebar.header("Dashboard Filters")

branch_options = ["All Branches"] + sorted(
    employee_df["branch_name"].dropna().unique().tolist()
)

selected_branch = st.sidebar.selectbox(
    "Employee branch",
    branch_options,
)

if selected_branch == "All Branches":
    filtered_employee_df = employee_df.copy()
else:
    filtered_employee_df = employee_df[
        employee_df["branch_name"] == selected_branch
    ].copy()


# =========================================================
# EXECUTIVE OVERVIEW
# =========================================================
section_title(
    "Executive Overview",
    "High-level business performance indicators.",
)

if not executive_df.empty:
    summary = executive_df.iloc[0]

    row_one = st.columns(3)
    row_one[0].metric(
        "Net Revenue",
        f"{float(summary['net_revenue']) / 1_000_000_000:,.2f} B MMK",
    )
    row_one[1].metric(
        "Transactions",
        f"{int(summary['total_transactions']):,}",
    )
    row_one[2].metric(
        "Estimated Net Profit",
        f"{float(summary['estimated_net_profit']) / 1_000_000_000:,.2f} B MMK",
    )

    row_two = st.columns(3)
    row_two[0].metric(
        "Average Transaction Value",
        f"{float(summary['average_transaction_value']) / 1_000_000:,.2f} M MMK",
    )
    row_two[1].metric(
        "Units Sold",
        f"{int(summary['total_units_sold']):,}",
    )
    row_two[2].metric(
        "Registered Customers",
        f"{int(summary['registered_customers']):,}",
    )


# =========================================================
# SALES PERFORMANCE
# =========================================================
section_title(
    "Sales Performance",
    "Monthly revenue movement and branch-level performance.",
)

sales_col_one, sales_col_two = st.columns(2)

with sales_col_one:
    monthly_chart = px.line(
        monthly_df,
        x="sales_month",
        y="net_revenue",
        markers=True,
        title="Monthly Net Revenue",
        labels={
            "sales_month": "Month",
            "net_revenue": "Net Revenue (MMK)",
        },
    )
    monthly_chart.update_yaxes(tickformat=".2s")
    show_chart(monthly_chart)

with sales_col_two:
    branch_chart = px.bar(
        branch_df,
        x="branch_name",
        y="net_revenue",
        title="Net Revenue by Branch",
        labels={
            "branch_name": "Branch",
            "net_revenue": "Net Revenue (MMK)",
        },
    )
    branch_chart.update_yaxes(tickformat=".2s")
    show_chart(branch_chart)


# =========================================================
# CUSTOMER ANALYSIS
# =========================================================
section_title(
    "Customer Analysis",
    "Customer spending, segmentation, and transaction behavior.",
)

top_customers = customer_df.head(10).sort_values(
    "total_spent",
    ascending=True,
)

customer_col_one, customer_col_two = st.columns([1.6, 1])

with customer_col_one:
    customer_chart = px.bar(
        top_customers,
        x="total_spent",
        y="customer_name",
        orientation="h",
        title="Top 10 Customers by Spending",
        labels={
            "customer_name": "Customer",
            "total_spent": "Total Spending (MMK)",
        },
    )
    customer_chart.update_xaxes(tickformat=".2s")
    show_chart(customer_chart)

with customer_col_two:
    segment_column = next(
        (
            column
            for column in [
                "customer_segment",
                "segment",
                "segment_name",
            ]
            if column in customer_segment_raw.columns
        ),
        None,
    )

    if segment_column:
        customer_segment_df = (
            customer_segment_raw.groupby(segment_column)
            .size()
            .reset_index(name="customer_count")
        )

        customer_segment_chart = px.pie(
            customer_segment_df,
            names=segment_column,
            values="customer_count",
            hole=0.58,
            title="Customer Segments",
        )
        customer_segment_chart.update_traces(
            textposition="inside",
            textinfo="percent",
        )
        show_chart(customer_segment_chart)
    else:
        st.info("No customer segment column was found.")

st.markdown("#### Customer Summary")
st.dataframe(
    customer_df[
        [
            "customer_name",
            "city",
            "purchase_count",
            "total_spent",
            "average_transaction_value",
        ]
    ],
    use_container_width=True,
    hide_index=True,
    height=390,
)


# =========================================================
# PRODUCT AND INVENTORY ANALYSIS
# =========================================================
section_title(
    "Product & Inventory Analysis",
    "Product revenue contribution and current inventory risk.",
)

top_products = product_df.head(10).sort_values(
    "gross_revenue",
    ascending=True,
)

category_revenue_df = (
    product_df.groupby(
        "category",
        as_index=False,
    )["gross_revenue"]
    .sum()
)

product_col_one, product_col_two = st.columns([1.6, 1])

with product_col_one:
    product_chart = px.bar(
        top_products,
        x="gross_revenue",
        y="product_name",
        color="category",
        orientation="h",
        title="Top 10 Products by Gross Revenue",
        labels={
            "product_name": "Product",
            "gross_revenue": "Gross Revenue (MMK)",
            "category": "Category",
        },
    )
    product_chart.update_xaxes(tickformat=".2s")
    show_chart(product_chart)

with product_col_two:
    category_revenue_chart = px.pie(
        category_revenue_df,
        names="category",
        values="gross_revenue",
        hole=0.58,
        title="Gross Revenue by Product Category",
    )
    category_revenue_chart.update_traces(
        textposition="inside",
        textinfo="percent",
    )
    show_chart(category_revenue_chart)


inventory_status_df = (
    inventory_df.groupby("inventory_status")
    .size()
    .reset_index(name="product_count")
)

inventory_col_one, inventory_col_two = st.columns([1, 2])

with inventory_col_one:
    inventory_status_chart = px.pie(
        inventory_status_df,
        names="inventory_status",
        values="product_count",
        hole=0.58,
        title="Inventory Status",
    )
    inventory_status_chart.update_traces(
        textposition="inside",
        textinfo="percent",
    )
    show_chart(inventory_status_chart)

with inventory_col_two:
    st.markdown("#### Inventory Risk")
    st.dataframe(
        inventory_df[
            [
                "branch_name",
                "product_name",
                "category",
                "stock_quantity",
                "reorder_level",
                "inventory_status",
            ]
        ],
        use_container_width=True,
        hide_index=True,
        height=CHART_HEIGHT,
    )


# =========================================================
# BRANCH AND EMPLOYEE PERFORMANCE
# =========================================================
section_title(
    "Branch & Employee Performance",
    "Employee sales contribution filtered by branch.",
)

top_employees = filtered_employee_df.head(10).sort_values(
    "net_revenue",
    ascending=True,
)

employee_chart = px.bar(
    top_employees,
    x="net_revenue",
    y="employee_name",
    color="branch_name",
    orientation="h",
    title="Top Employees by Net Revenue",
    labels={
        "employee_name": "Employee",
        "net_revenue": "Net Revenue (MMK)",
        "branch_name": "Branch",
    },
)
employee_chart.update_xaxes(tickformat=".2s")
show_chart(employee_chart)

st.markdown("#### Employee Performance Summary")
st.dataframe(
    filtered_employee_df[
        [
            "employee_name",
            "job_title",
            "branch_name",
            "transaction_count",
            "units_sold",
            "net_revenue",
            "estimated_net_profit",
        ]
    ],
    use_container_width=True,
    hide_index=True,
    height=390,
)


# =========================================================
# FOOTER
# =========================================================
st.markdown(
    """
    <div class="dashboard-footer">
        Jewelry Operations SQL Analytics · PostgreSQL · Streamlit · Plotly
    </div>
    """,
    unsafe_allow_html=True,
)
'''

output_path.write_text(code, encoding="utf-8")

print(f"Created: {output_path}")
print(f"Lines: {len(code.splitlines())}")
