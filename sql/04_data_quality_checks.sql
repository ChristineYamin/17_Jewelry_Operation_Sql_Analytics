-- ============================================
-- 1. Verify row counts
-- ============================================

SELECT 'branches' AS table_name, COUNT(*) AS row_count
FROM raw.branches

UNION ALL

SELECT 'customers', COUNT(*)
FROM raw.customers

UNION ALL

SELECT 'employees', COUNT(*)
FROM raw.employees

UNION ALL

SELECT 'suppliers', COUNT(*)
FROM raw.suppliers

UNION ALL

SELECT 'gold_types', COUNT(*)
FROM raw.gold_types

UNION ALL

SELECT 'products', COUNT(*)
FROM raw.products

UNION ALL

SELECT 'sales', COUNT(*)
FROM raw.sales

UNION ALL

SELECT 'sale_items', COUNT(*)
FROM raw.sale_items

UNION ALL

SELECT 'inventory', COUNT(*)
FROM raw.inventory

UNION ALL

SELECT 'gold_prices', COUNT(*)
FROM raw.gold_prices

ORDER BY table_name;

-- ============================================
-- 2. Check missing customer values
-- ============================================

SELECT
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE customer_name IS NULL) AS missing_names,
    COUNT(*) FILTER (WHERE phone IS NULL) AS missing_phones,
    COUNT(*) FILTER (WHERE city IS NULL) AS missing_cities,
    COUNT(*) FILTER (
        WHERE registration_date IS NULL
    ) AS missing_registration_dates
FROM raw.customers;


-- Check missing supplier values

SELECT
    COUNT(*) AS total_suppliers,
    COUNT(*) FILTER (
        WHERE supplier_name IS NULL
    ) AS missing_names,
    COUNT(*) FILTER (WHERE phone IS NULL) AS missing_phones,
    COUNT(*) FILTER (WHERE city IS NULL) AS missing_cities
FROM raw.suppliers;


-- Missing customer IDs represent walk-in customers

SELECT
    COUNT(*) AS total_sales,
    COUNT(*) FILTER (
        WHERE customer_id IS NULL
    ) AS walk_in_sales
FROM raw.sales;

-- ============================================
-- 3. Check duplicate customer records
-- ============================================

SELECT
    customer_name,
    phone,
    COUNT(*) AS duplicate_count
FROM raw.customers
GROUP BY customer_name, phone
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- Check duplicate sale-item combinations

SELECT
    sale_id,
    product_id,
    COUNT(*) AS duplicate_count
FROM raw.sale_items
GROUP BY sale_id, product_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- ============================================
-- 4. Check invalid numerical values
-- ============================================

SELECT *
FROM raw.products
WHERE
    weight_grams <= 0
    OR making_charge < 0
    OR cost_price <= 0
    OR selling_price <= 0;


SELECT *
FROM raw.sale_items
WHERE
    quantity <= 0
    OR unit_price <= 0;


SELECT *
FROM raw.inventory
WHERE
    stock_quantity < 0
    OR reorder_level < 0;


SELECT *
FROM raw.sales
WHERE discount_amount < 0;


SELECT *
FROM raw.gold_prices
WHERE price_per_gram <= 0;

-- ============================================
-- 5. Check broken table relationships
-- ============================================

-- Sales linked to missing customers
SELECT s.*
FROM raw.sales AS s
LEFT JOIN raw.customers AS c
    ON s.customer_id = c.customer_id
WHERE s.customer_id IS NOT NULL
  AND c.customer_id IS NULL;


-- Sales linked to missing employees
SELECT s.*
FROM raw.sales AS s
LEFT JOIN raw.employees AS e
    ON s.employee_id = e.employee_id
WHERE e.employee_id IS NULL;


-- Sale items linked to missing products or sales
SELECT si.*
FROM raw.sale_items AS si
LEFT JOIN raw.sales AS s
    ON si.sale_id = s.sale_id
LEFT JOIN raw.products AS p
    ON si.product_id = p.product_id
WHERE s.sale_id IS NULL
   OR p.product_id IS NULL;

-- ============================================
-- 6. Check date consistency
-- ============================================

-- Customer purchased before registration
SELECT
    s.sale_id,
    s.customer_id,
    s.sale_date,
    c.registration_date
FROM raw.sales AS s
JOIN raw.customers AS c
    ON s.customer_id = c.customer_id
WHERE s.sale_date::DATE < c.registration_date;


-- Employee handled a sale before being hired
SELECT
    s.sale_id,
    s.employee_id,
    s.sale_date,
    e.hire_date
FROM raw.sales AS s
JOIN raw.employees AS e
    ON s.employee_id = e.employee_id
WHERE s.sale_date::DATE < e.hire_date;


-- Sale happened before the branch opened
SELECT
    s.sale_id,
    s.branch_id,
    s.sale_date,
    b.opening_date
FROM raw.sales AS s
JOIN raw.branches AS b
    ON s.branch_id = b.branch_id
WHERE s.sale_date::DATE < b.opening_date;

-- ============================================
-- 7. Check employee and sale branch consistency
-- ============================================

SELECT COUNT(*) AS mismatched_branch_sales
FROM raw.sales AS s
JOIN raw.employees AS e
    ON s.employee_id = e.employee_id
WHERE s.branch_id <> e.branch_id;