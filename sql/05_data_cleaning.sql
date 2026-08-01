-- ============================================
-- 1. Create cleaned branches table
-- ============================================

DROP TABLE IF EXISTS cleaned.branches;

CREATE TABLE cleaned.branches (
    branch_id INTEGER PRIMARY KEY,
    branch_name VARCHAR(100) NOT NULL UNIQUE,
    city VARCHAR(50) NOT NULL,
    opening_date DATE
);

INSERT INTO cleaned.branches (
    branch_id,
    branch_name,
    city,
    opening_date
)
SELECT
    branch_id,
    INITCAP(TRIM(branch_name)) AS branch_name,
    INITCAP(TRIM(city)) AS city,
    opening_date
FROM raw.branches;

-- ============================================
-- 2. Create cleaned customers table
-- ============================================

DROP TABLE IF EXISTS cleaned.customers;

CREATE TABLE cleaned.customers (
    customer_id INTEGER PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    phone VARCHAR(30),
    city VARCHAR(50),
    registration_date DATE NOT NULL
);

INSERT INTO cleaned.customers (
    customer_id,
    customer_name,
    phone,
    city,
    registration_date
)
SELECT
    customer_id,
    INITCAP(TRIM(customer_name)) AS customer_name,
    NULLIF(TRIM(phone), '') AS phone,
    INITCAP(NULLIF(TRIM(city), '')) AS city,
    registration_date
FROM raw.customers;

-- ============================================
-- 3. Create cleaned suppliers table
-- ============================================

DROP TABLE IF EXISTS cleaned.suppliers;

CREATE TABLE cleaned.suppliers (
    supplier_id INTEGER PRIMARY KEY,
    supplier_name VARCHAR(100) NOT NULL,
    city VARCHAR(50),
    phone VARCHAR(30)
);

INSERT INTO cleaned.suppliers (
    supplier_id,
    supplier_name,
    city,
    phone
)
SELECT
    supplier_id,
    INITCAP(TRIM(supplier_name)) AS supplier_name,
    INITCAP(NULLIF(TRIM(city), '')) AS city,
    NULLIF(TRIM(phone), '') AS phone
FROM raw.suppliers;

-- ============================================
-- 4. Create cleaned gold_types table
-- ============================================

DROP TABLE IF EXISTS cleaned.gold_types;
CREATE TABLE cleaned.gold_types (
    gold_type_id INTEGER PRIMARY KEY,
    gold_type_name VARCHAR(30) NOT NULL UNIQUE
);

INSERT INTO cleaned.gold_types (
    gold_type_id,
    gold_type_name
)
SELECT
    gold_type_id,
    UPPER(TRIM(gold_type_name)) AS gold_type_name
FROM raw.gold_types;

-- ============================================
-- 5. Create cleaned employees table
-- ============================================

DROP TABLE IF EXISTS cleaned.employees;

CREATE TABLE cleaned.employees (
    employee_id INTEGER PRIMARY KEY,
    employee_name VARCHAR(100) NOT NULL,
    branch_id INTEGER NOT NULL,
    job_title VARCHAR(50) NOT NULL,
    hire_date DATE NOT NULL,
    monthly_target DECIMAL(12,2) NOT NULL
        CHECK (monthly_target >= 0),

    CONSTRAINT fk_cleaned_employees_branch
        FOREIGN KEY (branch_id)
        REFERENCES cleaned.branches(branch_id)
);

INSERT INTO cleaned.employees (
    employee_id,
    employee_name,
    branch_id,
    job_title,
    hire_date,
    monthly_target
)
SELECT
    employee_id,
    INITCAP(TRIM(employee_name)) AS employee_name,
    branch_id,
    INITCAP(TRIM(job_title)) AS job_title,
    hire_date,
    monthly_target
FROM raw.employees;

-- ============================================
-- 6. Create cleaned products table
-- ============================================

DROP TABLE IF EXISTS cleaned.products;

CREATE TABLE cleaned.products (
    product_id INTEGER PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    gold_type_id INTEGER NOT NULL,
    weight_grams DECIMAL(10,2) NOT NULL
        CHECK (weight_grams > 0),
    making_charge DECIMAL(12,2) NOT NULL
        CHECK (making_charge >= 0),
    cost_price DECIMAL(14,2) NOT NULL
        CHECK (cost_price > 0),
    selling_price DECIMAL(14,2) NOT NULL
        CHECK (selling_price > 0),
    supplier_id INTEGER NOT NULL,

    CONSTRAINT fk_cleaned_products_gold_type
        FOREIGN KEY (gold_type_id)
        REFERENCES cleaned.gold_types(gold_type_id),

    CONSTRAINT fk_cleaned_products_supplier
        FOREIGN KEY (supplier_id)
        REFERENCES cleaned.suppliers(supplier_id)
);

INSERT INTO cleaned.products (
    product_id,
    product_name,
    category,
    gold_type_id,
    weight_grams,
    making_charge,
    cost_price,
    selling_price,
    supplier_id
)
SELECT
    product_id,
    TRIM(product_name) AS product_name,
    INITCAP(TRIM(category)) AS category,
    gold_type_id,
    weight_grams,
    making_charge,
    cost_price,
    selling_price,
    supplier_id
FROM raw.products;

-- ============================================
-- 7. Create cleaned sales table
-- ============================================

DROP TABLE IF EXISTS cleaned.sales;

CREATE TABLE cleaned.sales (
    sale_id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    employee_id INTEGER NOT NULL,
    branch_id INTEGER NOT NULL,
    sale_date TIMESTAMP NOT NULL,
    payment_method VARCHAR(30) NOT NULL,
    discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0
        CHECK (discount_amount >= 0),

    CONSTRAINT fk_cleaned_sales_customer
        FOREIGN KEY (customer_id)
        REFERENCES cleaned.customers(customer_id),

    CONSTRAINT fk_cleaned_sales_employee
        FOREIGN KEY (employee_id)
        REFERENCES cleaned.employees(employee_id),

    CONSTRAINT fk_cleaned_sales_branch
        FOREIGN KEY (branch_id)
        REFERENCES cleaned.branches(branch_id)
);

INSERT INTO cleaned.sales (
    sale_id,
    customer_id,
    employee_id,
    branch_id,
    sale_date,
    payment_method,
    discount_amount
)
SELECT
    sale_id,
    customer_id,
    employee_id,
    branch_id,
    sale_date,
    INITCAP(TRIM(payment_method)) AS payment_method,
    discount_amount
FROM raw.sales;

-- ============================================
-- 8. Create cleaned sale_items table
-- ============================================

DROP TABLE IF EXISTS cleaned.sale_items;

CREATE TABLE cleaned.sale_items (
    sale_item_id INTEGER PRIMARY KEY,
    sale_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL
        CHECK (quantity > 0),
    unit_price DECIMAL(14,2) NOT NULL
        CHECK (unit_price > 0),

    CONSTRAINT fk_cleaned_sale_items_sale
        FOREIGN KEY (sale_id)
        REFERENCES cleaned.sales(sale_id),

    CONSTRAINT fk_cleaned_sale_items_product
        FOREIGN KEY (product_id)
        REFERENCES cleaned.products(product_id)
);

INSERT INTO cleaned.sale_items (
    sale_item_id,
    sale_id,
    product_id,
    quantity,
    unit_price
)
SELECT
    sale_item_id,
    sale_id,
    product_id,
    quantity,
    unit_price
FROM raw.sale_items;

-- ============================================
-- 9. Create cleaned inventory table
-- ============================================

DROP TABLE IF EXISTS cleaned.inventory;

CREATE TABLE cleaned.inventory (
    inventory_id INTEGER PRIMARY KEY,
    branch_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    stock_quantity INTEGER NOT NULL
        CHECK (stock_quantity >= 0),
    reorder_level INTEGER NOT NULL
        CHECK (reorder_level >= 0),
    last_updated DATE NOT NULL,

    CONSTRAINT fk_cleaned_inventory_branch
        FOREIGN KEY (branch_id)
        REFERENCES cleaned.branches(branch_id),

    CONSTRAINT fk_cleaned_inventory_product
        FOREIGN KEY (product_id)
        REFERENCES cleaned.products(product_id),

    CONSTRAINT uq_cleaned_inventory_branch_product
        UNIQUE (branch_id, product_id)
);

INSERT INTO cleaned.inventory (
    inventory_id,
    branch_id,
    product_id,
    stock_quantity,
    reorder_level,
    last_updated
)
SELECT
    inventory_id,
    branch_id,
    product_id,
    stock_quantity,
    reorder_level,
    last_updated
FROM raw.inventory;

-- ============================================
-- 10. Create cleaned gold_prices table
-- ============================================

DROP TABLE IF EXISTS cleaned.gold_prices;

CREATE TABLE cleaned.gold_prices (
    price_date DATE NOT NULL,
    gold_type_id INTEGER NOT NULL,
    price_per_gram DECIMAL(14,2) NOT NULL
        CHECK (price_per_gram > 0),

    CONSTRAINT pk_cleaned_gold_prices
        PRIMARY KEY (price_date, gold_type_id),

    CONSTRAINT fk_cleaned_gold_prices_gold_type
        FOREIGN KEY (gold_type_id)
        REFERENCES cleaned.gold_types(gold_type_id)
);

INSERT INTO cleaned.gold_prices (
    price_date,
    gold_type_id,
    price_per_gram
)
SELECT
    price_date,
    gold_type_id,
    price_per_gram
FROM raw.gold_prices;

