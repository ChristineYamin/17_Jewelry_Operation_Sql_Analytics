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