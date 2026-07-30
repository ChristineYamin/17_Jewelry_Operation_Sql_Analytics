-- Table 1: Branches

CREATE TABLE IF NOT EXISTS raw.branches (
    branch_id INTEGER PRIMARY KEY,
    branch_name VARCHAR(100) NOT NULL UNIQUE,
    city VARCHAR(50) NOT NULL,
    opening_date DATE
);

-- Table 2: Customers

CREATE TABLE IF NOT EXISTS raw.customers (
    customer_id INTEGER PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    phone VARCHAR(30),
    city VARCHAR(50),
    registration_date DATE NOT NULL
);

-- Table 3: Suppliers

CREATE TABLE IF NOT EXISTS raw.suppliers (
    supplier_id INTEGER PRIMARY KEY,
    supplier_name VARCHAR(100) NOT NULL,
    city VARCHAR(50),
    phone VARCHAR(30)
);

-- Table 4: Gold Types

CREATE TABLE IF NOT EXISTS raw.gold_types (
    gold_type_id INTEGER PRIMARY KEY,
    gold_type_name VARCHAR(30) NOT NULL UNIQUE
);

-- Table 5: Employees

CREATE TABLE IF NOT EXISTS raw.employees (
    employee_id INTEGER PRIMARY KEY,
    employee_name VARCHAR(100) NOT NULL,
    branch_id INTEGER NOT NULL,
    job_title VARCHAR(50) NOT NULL,
    hire_date DATE NOT NULL,
    monthly_target DECIMAL(12,2) NOT NULL CHECK (monthly_target >= 0),

    CONSTRAINT fk_employees_branch
        FOREIGN KEY (branch_id)
        REFERENCES raw.branches(branch_id)
);

-- Table 6: Products

CREATE TABLE IF NOT EXISTS raw.products (
    product_id INTEGER PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    gold_type_id INTEGER NOT NULL,
    weight_grams DECIMAL(10,2) NOT NULL CHECK (weight_grams > 0),
    making_charge DECIMAL(12,2) NOT NULL CHECK (making_charge >= 0),
    cost_price DECIMAL(14,2) NOT NULL CHECK (cost_price > 0),
    selling_price DECIMAL(14,2) NOT NULL CHECK (selling_price > 0),
    supplier_id INTEGER NOT NULL,

    CONSTRAINT fk_products_gold_type
        FOREIGN KEY (gold_type_id)
        REFERENCES raw.gold_types(gold_type_id),

    CONSTRAINT fk_products_supplier
        FOREIGN KEY (supplier_id)
        REFERENCES raw.suppliers(supplier_id)
);

-- Table 7: Sales

CREATE TABLE IF NOT EXISTS raw.sales (
    sale_id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    employee_id INTEGER NOT NULL,
    branch_id INTEGER NOT NULL,
    sale_date TIMESTAMP NOT NULL,
    payment_method VARCHAR(30) NOT NULL,
    discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0
        CHECK (discount_amount >= 0),

    CONSTRAINT fk_sales_customer
        FOREIGN KEY (customer_id)
        REFERENCES raw.customers(customer_id),

    CONSTRAINT fk_sales_employee
        FOREIGN KEY (employee_id)
        REFERENCES raw.employees(employee_id),

    CONSTRAINT fk_sales_branch
        FOREIGN KEY (branch_id)
        REFERENCES raw.branches(branch_id)
);

-- Table 8: Sale Items

CREATE TABLE IF NOT EXISTS raw.sale_items (
    sale_item_id INTEGER PRIMARY KEY,
    sale_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(14,2) NOT NULL CHECK (unit_price > 0),

    CONSTRAINT fk_sale_items_sale
        FOREIGN KEY (sale_id)
        REFERENCES raw.sales(sale_id),

    CONSTRAINT fk_sale_items_product
        FOREIGN KEY (product_id)
        REFERENCES raw.products(product_id)
);

-- Table 9: Inventory

CREATE TABLE IF NOT EXISTS raw.inventory (
    inventory_id INTEGER PRIMARY KEY,
    branch_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    stock_quantity INTEGER NOT NULL CHECK (stock_quantity >= 0),
    reorder_level INTEGER NOT NULL CHECK (reorder_level >= 0),
    last_updated DATE NOT NULL,

    CONSTRAINT fk_inventory_branch
        FOREIGN KEY (branch_id)
        REFERENCES raw.branches(branch_id),

    CONSTRAINT fk_inventory_product
        FOREIGN KEY (product_id)
        REFERENCES raw.products(product_id),

    CONSTRAINT uq_inventory_branch_product
        UNIQUE (branch_id, product_id)
);

-- Table 10: Gold Prices

CREATE TABLE IF NOT EXISTS raw.gold_prices (
    price_date DATE NOT NULL,
    gold_type_id INTEGER NOT NULL,
    price_per_gram DECIMAL(14,2) NOT NULL CHECK (price_per_gram > 0),

    CONSTRAINT pk_gold_prices
        PRIMARY KEY (price_date, gold_type_id),

    CONSTRAINT fk_gold_prices_gold_type
        FOREIGN KEY (gold_type_id)
        REFERENCES raw.gold_types(gold_type_id)
);