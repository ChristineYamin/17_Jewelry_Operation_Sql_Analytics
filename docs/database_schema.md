# Database Schema PLan
1. Branches
Stores information about each jewelry-shop branch.
- branch_id
- branch_name
- City
- opening_date

2. Customers
Stores customer information.
- customer_id
- customer_name
- phone
- city
- registration_date

3. Employees
Stores employees working at each branch.
- employee_id
- employee_name
- branch_id
- job_title
- hire_date
- monthly_target

4. Suppliers
Stores jewelry and gold suppliers.
- supplier_id
- supplier_name
- city
- phone

5. Products
Stores jewelry-product information
- product_id
- product_name
- category
- gold_type
- weight_grams
- making_charge
- cost_price
- selling_price
- supplier_id

6. Sales
Stores the main information for each transaction.
- sale_id
- customer_id
- emloyee_id
- branch_id
- sale_date
- payment_method
- discount_amount

7. Sale items
Stores the individual products included in each transaction.
- sale_item_id
- sale_id
- product_id
- quantity
- unit_price

8. Inventory
Stores product stock for each branch.
- inventory_id
- branch_id
- product_id
- stock_quantity
- reorder_level
- last_updated

9. Gold prices
Stores historical gold prices.
- price_date
- gold_type
- price_per_gram

## Main Relationship
- one branch can have many employees.
- One branch can have many sales.
- One branch can hold many inventory records.
- One customer can make many purchases.
- One employee can handle many sales.
- One sale can contain many sale items.
- One product can appear in many sale items.
- One supplier can supply many products.
- One product can be stored in multiple branches.