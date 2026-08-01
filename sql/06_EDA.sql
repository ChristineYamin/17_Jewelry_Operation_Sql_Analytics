-- ============================================
-- 1. Basic business overview
-- ============================================

SELECT
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT customer_id) AS registered_customers,
    COUNT(DISTINCT employee_id) AS active_employees,
    COUNT(DISTINCT branch_id) AS active_branches
FROM cleaned.sales;

-- ============================================
-- 2. Sales date range
-- ============================================

SELECT
    MIN(sale_date) AS first_sale_date,
    MAX(sale_date) AS latest_sale_date,
    MAX(sale_date)::DATE - MIN(sale_date)::DATE AS total_days
FROM cleaned.sales;

-- ============================================
-- 3. Product and category overview
-- ============================================

SELECT
    category,
    COUNT(*) AS product_count,
    ROUND(AVG(weight_grams), 2) AS average_weight_grams,
    ROUND(AVG(selling_price), 2) AS average_selling_price
FROM cleaned.products
GROUP BY category
ORDER BY product_count DESC;

-- ============================================
-- 4. Payment method distribution
-- ============================================

SELECT
    payment_method,
    COUNT(*) AS transaction_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS transaction_percentage
FROM cleaned.sales
GROUP BY payment_method
ORDER BY transaction_count DESC;

-- ============================================
-- 5. Branch transaction overview
-- ============================================

SELECT
    b.branch_id,
    b.branch_name,
    b.city,
    COUNT(s.sale_id) AS transaction_count,
    COUNT(DISTINCT s.customer_id) AS registered_customers
FROM cleaned.branches AS b
LEFT JOIN cleaned.sales AS s
    ON b.branch_id = s.branch_id
GROUP BY
    b.branch_id,
    b.branch_name,
    b.city
ORDER BY transaction_count DESC;

-- ============================================
-- 6. Registered vs walk-in transactions
-- ============================================

SELECT
    CASE
        WHEN customer_id IS NULL THEN 'Walk-in Customer'
        ELSE 'Registered Customer'
    END AS customer_type,
    COUNT(*) AS transaction_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS transaction_percentage
FROM cleaned.sales
GROUP BY customer_type
ORDER BY transaction_count DESC;

-- ============================================
-- 7. Customer distribution by city
-- ============================================

SELECT
    COALESCE(city, 'Unknown') AS city,
    COUNT(*) AS customer_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage
FROM cleaned.customers
GROUP BY COALESCE(city, 'Unknown')
ORDER BY customer_count DESC;

-- ============================================
-- 8. Sale-item quantity overview
-- ============================================

SELECT
    COUNT(*) AS total_sale_items,
    SUM(quantity) AS total_units_sold,
    ROUND(AVG(quantity), 2) AS average_quantity_per_item,
    MIN(quantity) AS minimum_quantity,
    MAX(quantity) AS maximum_quantity
FROM cleaned.sale_items;

-- ============================================
-- 9. Product pricing and estimated margins
-- ============================================

SELECT
    category,
    COUNT(*) AS product_count,
    ROUND(AVG(cost_price), 2) AS average_cost_price,
    ROUND(AVG(selling_price), 2) AS average_selling_price,
    ROUND(AVG(selling_price - cost_price), 2)
        AS average_estimated_profit,
    ROUND(
        AVG(
            (selling_price - cost_price)
            / NULLIF(selling_price, 0) * 100
        ),
        2
    ) AS average_profit_margin_percentage
FROM cleaned.products
GROUP BY category
ORDER BY average_estimated_profit DESC;

-- ============================================
-- 10. Inventory status overview
-- ============================================

SELECT
    CASE
        WHEN stock_quantity = 0 THEN 'Out of Stock'
        WHEN stock_quantity <= reorder_level THEN 'Low Stock'
        ELSE 'Healthy Stock'
    END AS inventory_status,
    COUNT(*) AS inventory_record_count,
    SUM(stock_quantity) AS total_units
FROM cleaned.inventory
GROUP BY inventory_status
ORDER BY inventory_record_count DESC;

-- ============================================
-- 11. Gold price overview
-- ============================================

SELECT
    gt.gold_type_name,
    MIN(gp.price_per_gram) AS minimum_price_per_gram,
    MAX(gp.price_per_gram) AS maximum_price_per_gram,
    ROUND(AVG(gp.price_per_gram), 2)
        AS average_price_per_gram
FROM cleaned.gold_prices AS gp
JOIN cleaned.gold_types AS gt
    ON gp.gold_type_id = gt.gold_type_id
GROUP BY
    gt.gold_type_id,
    gt.gold_type_name
ORDER BY gt.gold_type_id;

-- ============================================
-- 12. Monthly transaction trend
-- ============================================

SELECT
    DATE_TRUNC('month', sale_date)::DATE AS sales_month,
    COUNT(*) AS transaction_count,
    COUNT(DISTINCT customer_id) AS registered_customers
FROM cleaned.sales
GROUP BY DATE_TRUNC('month', sale_date)
ORDER BY sales_month;

-- ============================================
-- 13. Units sold by product category
-- ============================================

SELECT
    p.category,
    COUNT(DISTINCT si.sale_id) AS transactions,
    SUM(si.quantity) AS units_sold
FROM cleaned.sale_items AS si
JOIN cleaned.products AS p
    ON si.product_id = p.product_id
GROUP BY p.category
ORDER BY units_sold DESC;

-- ============================================
-- 14. Products supplied by each supplier
-- ============================================

SELECT
    s.supplier_id,
    s.supplier_name,
    COUNT(p.product_id) AS products_supplied
FROM cleaned.suppliers AS s
LEFT JOIN cleaned.products AS p
    ON s.supplier_id = p.supplier_id
GROUP BY
    s.supplier_id,
    s.supplier_name
ORDER BY products_supplied DESC;

