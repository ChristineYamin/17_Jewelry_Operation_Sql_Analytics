
# 💎 Jewelry Operations SQL Analytics
An end-to-end analytics project for a multi-branch jewelry retail business, built with **PostgreSQL, SQL, Power BI, Python, Plotly, and Streamlit**.

The project transforms raw operational data into an analytics-ready database, reusable SQL views, interactive dashboards, and business insights covering sales, customers, products, inventory, branches, and employees.

## 📌 Project Overview

Jewelry businesses need to monitor many operational areas at the same time, including revenue, profitability, customer behavior, product performance, stock levels, branch performance, and employee contribution.

This project builds a complete analytics system that answers those needs through:

- Synthetic data generation
- Relational database design
- Data validation and cleaning
- SQL analysis
- Analytics views
- Query optimization
- Power BI reporting
- Interactive Streamlit deployment

## 🛠️ Technology Stack

| Area | Technology |
|---|---|
| Database | PostgreSQL |
| Cloud Database | Neon PostgreSQL |
| Database Management | pgAdmin 4 |
| Query Language | SQL |
| Data Generation | Python, Pandas, Faker |
| Dashboarding | Power BI |
| Web Application | Streamlit |
| Visualization | Plotly |
| Database Connection | psycopg2 |
| Development | VS Code |
| Version Control | Git and GitHub |

## Workflow steps by steps
1. create the doc folder and add business_requirements.md , data_dictionary.md, database_schema.md 
2. Synthetic Data Generation : Python, Pandas, and Faker were used to generate realistic synthetic jewelry retail data.The generated data includes:
5 branches
1,000 customers
40 employees
20 suppliers
300 products
1,500 inventory records
2,924 gold price records
10,000 sales transactions
The data was exported as CSV files for PostgreSQL import.
3. Raw Data Import: The CSV files were imported into the PostgreSQL raw schema. This schema preserves the original imported records before cleaning and transformation. 
CSV Files → raw schema
5. There are 13 sql files.
Data Quality Validation
SQL queries were used to check:

Missing values
Duplicate records
Invalid dates
Primary-key uniqueness
Foreign-key consistency
Branch consistency
Invalid sales values
Inventory issues
Sales recorded before an employee’s hire date

Detected issues were corrected before continuing with the analysis.

6. Data Cleaning

Validated records were transferred from the raw schema into the cleaned schema.

Cleaning tasks included:

Standardizing data types
Removing invalid or duplicate records
Correcting inconsistent relationships
Validating customer and employee references
Ensuring sales and inventory values were valid

raw schema → validation and cleaning → cleaned schema

7. Exploratory SQL Analysis

Exploratory queries were written to understand:

Transaction volume
Revenue distribution
Customer activity
Product performance
Inventory levels
Branch performance
Employee contribution

This stage helped identify the most useful business metrics for the dashboards.

8. Business Analysis

Separate SQL scripts were created for:

Sales analysis
Customer analysis
Product and inventory analysis
Branch and employee analysis
Advanced business analysis

The analysis included monthly trends, customer spending, product revenue, inventory risk, branch profitability, and employee performance.

9. Analytics View Creation

Reusable views were created inside the analytics schema:
analytics.executive_summary
analytics.monthly_sales_summary
analytics.branch_performance
analytics.customer_summary
analytics.customer_segments
analytics.product_performance
analytics.inventory_risk
analytics.employee_performance
These views serve as the reporting layer for Power BI and Streamlit.
cleaned schema → analytics views → dashboards

10. Query Optimization

Indexes were added to frequently queried columns, including:

Foreign keys
Transaction dates
Customer IDs
Product IDs
Branch IDs
Employee IDs

EXPLAIN ANALYZE was used to review query execution and confirm that the indexes improved data retrieval.

11. Power BI Dashboard Development

The PostgreSQL analytics views were connected to Power BI.

Four dashboard pages were created:

Executive Overview
Customer Analysis
Product & Inventory
Branch & Employee Performance

The report includes KPI cards, trend charts, bar charts, donut charts, tables, and interactive filters.

12. Streamlit Application Development

A Streamlit dashboard was developed using Python, Pandas, Plotly, and psycopg2.

The application includes:

Executive KPI cards
Monthly revenue trend
Branch revenue comparison
Customer analysis
Product and category analysis
Inventory risk monitoring
Employee performance analysis
Interactive branch filtering
Custom CSS and responsive layouts

13. Cloud Database Migration

The local PostgreSQL database was backed up using pgAdmin and restored to a hosted Neon PostgreSQL database.

Local PostgreSQL → pgAdmin backup → Neon PostgreSQL

This allowed the deployed Streamlit application to access the database online.

14. Streamlit Cloud Deployment

The Streamlit application was deployed to Streamlit Community Cloud.

Database credentials were securely stored using Streamlit Secrets and excluded from GitHub.

GitHub Repository
        ↓
Streamlit Community Cloud
        ↓
Neon PostgreSQL Database


15. Documentation and Version Control

The complete project was uploaded to GitHub with:

SQL scripts
Python scripts
Power BI dashboard
Streamlit application
Database documentation
Screenshots
Requirements file
README documentation
.gitignore security configuration

## Final Pipeline
Business Requirements → ER Diagram and Database Design → Synthetic Data Generation → PostgreSQL Database Setup in pgAdmin 4 → Raw Data Import → Data Quality Checks → Data Cleaning → Exploratory and Business Analysis → Analytics Views → Indexes and Query Optimization → Power BI Dashboard → Streamlit Application → Neon PostgreSQL Migration → Streamlit Cloud Deployment

## 🗂️ Database Architecture

The PostgreSQL database is organized into three schemas:

### `raw`
Stores imported source data with minimal transformation.
### `cleaned`
Stores validated and cleaned records used for analysis.
### `analytics`
Stores reusable analytical views used by Power BI and Streamlit.
Main operational tables:
- `branches`
- `customers`
- `employees`
- `suppliers`
- `gold_types`
- `products`
- `inventory`
- `gold_prices`
- `sales`
- `sale_items`

## 📈 Analytics Views

The analytics layer contains the following views:

- `analytics.executive_summary`
- `analytics.monthly_sales_summary`
- `analytics.branch_performance`
- `analytics.customer_summary`
- `analytics.customer_segments`
- `analytics.product_performance`
- `analytics.inventory_risk`
- `analytics.employee_performance`

These views centralize business logic and provide clean, reusable datasets for reporting.

## 🧾 Dataset

The project uses a synthetic jewelry retail dataset representing realistic business operations.

| Dataset | Approximate Records |
|---|---:|
| Branches | 5 |
| Customers | 1,000 |
| Employees | 40 |
| Suppliers | 20 |
| Products | 300 |
| Inventory Records | 1,500 |
| Gold Price Records | 2,924 |
| Sales Transactions | 10,000 |

The dataset includes:

- Registered and walk-in customers
- Multiple branches
- Product categories and gold types
- Employee assignments
- Inventory levels
- Historical sales transactions
- Gold price records


## 🧹 Data Quality Validation

The project includes checks for:

- Missing values
- Duplicate records
- Primary-key uniqueness
- Foreign-key consistency
- Invalid dates
- Branch consistency
- Employee hire-date validity
- Sales amount validity
- Inventory-level validity

One important rule ensured that an employee could not be assigned to a sale that occurred before the employee's hire date.
## 🧠 SQL Workflow

The SQL workflow is organized into 13 scripts:

01_database_setup.sql
02_create_tables.sql
03_insert_data.sql
04_data_quality_checks.sql
05_data_cleaning.sql
06_exploratory_analysis.sql
07_sales_analysis.sql
08_customer_analysis.sql
09_product_inventory_analysis.sql
10_branch_employee_analysis.sql
11_advanced_analysis.sql
12_create_views.sql
13_indexes_optimization.sql

## scripts cover
Database and schema setup
Table creation and constraints
Data insertion
Data quality checks
Data cleaning
Exploratory analysis
Sales analysis
Customer analysis
Product and inventory analysis
Branch and employee analysis
Advanced SQL analysis
Analytics view creation
Indexing and optimization

## Powerbi dashboard
The Power BI report contains four pages:

1. Executive Overview
Revenue and profit KPIs
Transaction and customer KPIs
Monthly revenue trend
Branch revenue comparison
Product category revenue distribution
2. Customer Analysis
Customer segmentation
Top customers by spending
Customer spending by city
Revenue by customer segment
Customer summary table
3. Product & Inventory
Top products by revenue
Product category revenue
Inventory status
Inventory risk table
Inventory value by branch
4. Branch & Employee Performance
Branch revenue
Estimated branch profit
Top employees
Employee performance table
Interactive branch filter

Power BI file: dashboard/Jewelry_Operations_Dashboard.pbix

# stremlit dashboard
The deployed Streamlit app includes:

Six executive KPI cards
Monthly net revenue trend
Branch revenue comparison
Top customer analysis
Customer segment donut chart
Product category revenue donut chart
Inventory status donut chart
Customer summary table
Inventory risk table
Employee performance chart
Employee performance table
Interactive branch filter
Responsive layout and custom CSS

The app connects securely to a hosted Neon PostgreSQL database through Streamlit Secrets.

### configure PostgreSQL credentials
Create 
.streamlit/secrets.toml
ADD
[postgres]
host = "YOUR_POSTGRES_HOST"
port = "5432"
database = "YOUR_DATABASE_NAME"
user = "YOUR_DATABASE_USER"
password = "YOUR_DATABASE_PASSWORD"
sslmode = "require"

## Security

Database credentials are stored through Streamlit Secrets and excluded from GitHub.

## Project Highlights
Designed a normalized PostgreSQL database
Generated realistic synthetic retail data
Built raw, cleaned, and analytics schemas
Performed structured data quality checks
Developed reusable SQL views
Organized the SQL workflow into 13 scripts
Added indexes and reviewed query performance
Built a four-page Power BI dashboard
Developed an interactive Streamlit dashboard
Migrated the database from local PostgreSQL to Neon
Deployed the Streamlit app publicly
Added secure cloud database configuration
Implemented interactive branch filtering
Added custom CSS and reusable visualization functions

## Limitations
The dataset is synthetic.
Profit is estimated from generated cost and sales data.
Results demonstrate analytical capability rather than real business performance.
The Power BI report is included as a local .pbix file

## Future Improvement
Date and product category filters
Sales forecasting
Automated low-stock alerts
Role-based access
Real-time gold price integration
Scheduled database refreshes
Customer churn prediction
Product recommendation analysis

### Author
Shwe Yamin