import streamlit as st
import pandas as pd
import psycopg2
import plotly.express as px

st.set_page_config(
    page_title = "Jewelry Operations Analytics",
    page_icon = "💎",
    layout="wide"
)

st.title("💎 Jewlry Operations Analytics")
st.write("SQL-powered dashboard for sales, customers, products, inventory, branches, and employees")
st.markdown("""
    <style>
    /* Global App Background */
    .stApp {
        background-color: #121212;
        color: #EAEAEA;
    }

    /* Metric Cards Styling */
    div[data-testid="stMetric"] {
        background-color: #1E1E1E;
        border: 1px solid #333333;
        padding: 15px 20px;
        border-radius: 8px;
        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.3);
        transition: border 0.3s ease;
    }
    
    div[data-testid="stMetric"]:hover {
        border: 1px solid #D4AF37; /* Gold accent on hover */
    }

    div[data-testid="stMetric"] label {
        color: #AAAAAA !important;
        font-size: 0.9rem !important;
    }

    div[data-testid="stMetric"] div[data-testid="stMetricValue"] {
        color: #D4AF37 !important; /* Gold metric numbers */
        font-weight: 600;
    }

    /* Subheaders and Titles styling */
    h1, h2, h3 {
        font-family: 'Helvetica Neue', sans-serif;
        letter-spacing: 0.5px;
    }
    
    h1 {
        color: #F3E5AB; /* Champagne gold title */
    }

    h2, h3 {
        color: #EAEAEA;
        border-bottom: 1px solid #2A2A2A;
        padding-bottom: 8px;
        margin-top: 2rem !important;
    }

    /* Dataframes and Tables */
    div[data-testid="stDataFrame"] {
        border: 1px solid #333333;
        border-radius: 8px;
        overflow: hidden;
    }

    /* Sidebar Styling */
    div[data-testid="stSidebar"] {
        background-color: #181818;
        border-right: 1px solid #2A2A2A;
    }

    /* Success / Error Boxes */
    div[data-testid="stSuccess"] {
        background-color: rgba(212, 175, 55, 0.1);
        border: 1px solid #D4AF37;
        color: #F3E5AB;
    }
    </style>
""", unsafe_allow_html=True)


@st.cache_resource
def get_connection():
    return psycopg2.connect(
        host=st.secrets["postgres"]["host"],
        port=st.secrets["postgres"]["port"],
        database=st.secrets["postgres"]["database"],
        user=st.secrets["postgres"]["user"],
        password=st.secrets["postgres"]["password"],
    )


try:
    connection = get_connection()
    st.success("✅ Connected to PostgreSQL successfully!")
except Exception as error:
    st.error(f"Database connection failed: {error}")

#----------------------------------------------
# Add a reusable SQL 
#---------------------------------------------
@st.cache_data
def run_query(query: str) -> pd.DataFrame:
    connection = get_connection()

    with connection.cursor() as cursor:
        cursor.execute(query)
        column_names = [column[0] for column in cursor.description]
        rows = cursor.fetchall()

    return pd.DataFrame(rows, columns=column_names)

#--------------------------------------------
# Display the executive KPI cards
#--------------------------------------------
executive_df = run_query(
    "SELECT * FROM analytics.executive_summary;"
)

if not executive_df.empty:
    summary = executive_df.iloc[0]

    st.subheader("Executive Overview")

    col1, col2, col3 = st.columns(3)

    col1.metric(
        "Net Revenue",
        f"{float(summary['net_revenue']) / 1_000_000_000:,.2f} B MMK"
    )

    col2.metric(
        "Transactions",
        f"{int(summary['total_transactions']):,}"
    )

    col3.metric(
        "Estimated Net Profit",
        f"{float(summary['estimated_net_profit']) / 1_000_000_000:,.2f} B MMK"
    )

    col4, col5, col6 = st.columns(3)

    col4.metric(
        "Average Transaction Value",
        f"{float(summary['average_transaction_value']) / 1_000_000:,.2f} M MMK"
    )

    col5.metric(
        "Units Sold",
        f"{int(summary['total_units_sold']):,}"
    )

    col6.metric(
        "Registered Customers",
        f"{int(summary['registered_customers']):,}"
    )

#------------------------------------
# Load monthly and branch data
#-----------------------------------

monthly_df = run_query("""
    SELECT *
    FROM analytics.monthly_sales_summary
    ORDER BY sales_month;
""")

branch_df = run_query("""
    SELECT *
    FROM analytics.branch_performance
    ORDER BY net_revenue DESC;
""")

#--------------------------
# Display two charts
#-------------------------
st.subheader("Sales Performance")

chart_col1, chart_col2 = st.columns(2)

with chart_col1:
    monthly_df["sales_month"] = pd.to_datetime(monthly_df["sales_month"])

    monthly_chart = px.line(
        monthly_df,
        x="sales_month",
        y="net_revenue",
        markers=True,
        title="Monthly Net Revenue"
    )

    monthly_chart.update_layout(
        xaxis_title="Month",
        yaxis_title="Net Revenue (MMK)"
    )

    st.plotly_chart(monthly_chart, use_container_width=True)

with chart_col2:
    branch_chart = px.bar(
        branch_df,
        x="branch_name",
        y="net_revenue",
        title="Net Revenue by Branch"
    )

    branch_chart.update_layout(
        xaxis_title="Branch",
        yaxis_title="Net Revenue (MMK)"
    )

    st.plotly_chart(branch_chart, use_container_width=True)

# ---------------------------------------
# Load customer data
# --------------------------------------
customer_df = run_query("""
    SELECT *
    FROM analytics.customer_summary
    ORDER BY total_spent DESC;
""")

customer_df["total_spent"] = pd.to_numeric(
    customer_df["total_spent"]
)

#------------------------------------------
# Add the top-customer chart
# --------------------------------------------

st.subheader("Customer Analysis")

top_customers = customer_df.head(10)

customer_chart = px.bar(
    top_customers,
    x="customer_name",
    y="total_spent",
    title="Top 10 Customers by Spending"
)

customer_chart.update_layout(
    xaxis_title="Customer",
    yaxis_title="Total Spending (MMK)"
)

st.plotly_chart(customer_chart, use_container_width=True)

# ------------------------------------------------
# Add the customer segment donut chart
# --------------------------------------

customer_segment_raw = run_query("""
    SELECT *
    FROM analytics.customer_segments;
""")

segment_column = next(
    (
        column for column in
        ["customer_segment", "segment", "segment_name"]
        if column in customer_segment_raw.columns
    ),
    None
)

if segment_column:
    customer_segment_df = (
        customer_segment_raw
        .groupby(segment_column)
        .size()
        .reset_index(name="customer_count")
    )

    customer_segment_chart = px.pie(
        customer_segment_df,
        names=segment_column,
        values="customer_count",
        hole=0.55,
        title="Customer Segments"
    )

    st.plotly_chart(
        customer_segment_chart,
        use_container_width=True
    )


# ---------------------------------------------
# Add the customer table
# ----------------------------------------
st.write("### Customer Summary")

st.dataframe(
    customer_df[
        [
            "customer_name",
            "city",
            "purchase_count",
            "total_spent",
            "average_transaction_value"
        ]
    ],
    use_container_width=True,
    hide_index=True
)

#-------------------------------------------------
# Load product and inventory data
#------------------------------------------------
product_df = run_query("""
    SELECT *
    FROM analytics.product_performance
    ORDER BY gross_revenue DESC;
""")

inventory_df = run_query("""
    SELECT *
    FROM analytics.inventory_risk
    ORDER BY stock_quantity ASC;
""")

product_df["gross_revenue"] = pd.to_numeric(
    product_df["gross_revenue"]
)

#--------------------------------------------------
# Add the top-products chart
# ------------------------------------------------
st.subheader("Product & Inventory Analysis")

top_products = product_df.head(10)

product_chart = px.bar(
    top_products,
    x="product_name",
    y="gross_revenue",
    color="category",
    title="Top 10 Products by Gross Revenue"
)

product_chart.update_layout(
    xaxis_title="Product",
    yaxis_title="Gross Revenue (MMK)"
)

st.plotly_chart(product_chart, use_container_width=True)

# -------------------------------------------
# Product category Revenue donut chart
# ------------------------------------------
category_revenue_df = (
    product_df
    .groupby("category", as_index=False)["gross_revenue"]
    .sum()
)

category_revenue_chart = px.pie(
    category_revenue_df,
    names="category",
    values="gross_revenue",
    hole=0.55,
    title="Gross Revenue by Product Category"
)

st.plotly_chart(
    category_revenue_chart,
    use_container_width=True
)





# ------------------------------------------------
# Add the inventory-risk table
#------------------------------------------------
st.write("### Inventory Risk")

st.dataframe(
    inventory_df[
        [
            "branch_name",
            "product_name",
            "category",
            "stock_quantity",
            "reorder_level",
            "inventory_status"
        ]
    ],
    use_container_width=True,
    hide_index=True
)

# --------------------------------------------
# Inventory Status Donut Chart
# ------------------------------------------
inventory_status_df = (
    inventory_df
    .groupby("inventory_status")
    .size()
    .reset_index(name="product_count")
)

inventory_status_chart = px.pie(
    inventory_status_df,
    names="inventory_status",
    values="product_count",
    hole=0.55,
    title="Inventory Status"
)

st.plotly_chart(
    inventory_status_chart,
    use_container_width=True
)
# ---------------------------------------
# Load employee data
# -----------------------------------------
employee_df = run_query("""
    SELECT *
    FROM analytics.employee_performance
    ORDER BY net_revenue DESC;
""")

employee_df["net_revenue"] = pd.to_numeric(
    employee_df["net_revenue"]
)

# ---------------------------------------------
# Add a branch filter and employee chart
#----------------------------------------------
st.subheader("Branch & Employee Performance")

branch_options = ["All Branches"] + sorted(
    employee_df["branch_name"].dropna().unique().tolist()
)

selected_branch = st.selectbox(
    "Select Branch",
    branch_options
)

if selected_branch == "All Branches":
    filtered_employee_df = employee_df.copy()
else:
    filtered_employee_df = employee_df[
        employee_df["branch_name"] == selected_branch
    ]

top_employees = filtered_employee_df.head(10)

employee_chart = px.bar(
    top_employees,
    x="employee_name",
    y="net_revenue",
    color="branch_name",
    title="Top Employees by Net Revenue"
)

employee_chart.update_layout(
    xaxis_title="Employee",
    yaxis_title="Net Revenue (MMK)"
)

st.plotly_chart(employee_chart, use_container_width=True)

# ------------------------------------
# Add the employee table
# ------------------------------------
st.write("### Employee Performance Summary")

st.dataframe(
    filtered_employee_df[
        [
            "employee_name",
            "job_title",
            "branch_name",
            "transaction_count",
            "units_sold",
            "net_revenue",
            "estimated_net_profit"
        ]
    ],
    use_container_width=True,
    hide_index=True
)
