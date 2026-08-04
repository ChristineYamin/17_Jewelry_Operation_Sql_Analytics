-- ============================================
-- 1. Indexes for sales and sale_items
-- ============================================

CREATE INDEX IF NOT EXISTS idx_cleaned_sales_sale_date
    ON cleaned.sales (sale_date);

CREATE INDEX IF NOT EXISTS idx_cleaned_sales_customer_id
    ON cleaned.sales (customer_id);

CREATE INDEX IF NOT EXISTS idx_cleaned_sales_employee_id
    ON cleaned.sales (employee_id);

CREATE INDEX IF NOT EXISTS idx_cleaned_sales_branch_id
    ON cleaned.sales (branch_id);

CREATE INDEX IF NOT EXISTS idx_cleaned_sale_items_sale_id
    ON cleaned.sale_items (sale_id);

CREATE INDEX IF NOT EXISTS idx_cleaned_sale_items_product_id
    ON cleaned.sale_items (product_id);

-- ============================================
-- 2. Supporting indexes for other tables
-- ============================================

CREATE INDEX IF NOT EXISTS idx_cleaned_products_category
    ON cleaned.products (category);

CREATE INDEX IF NOT EXISTS idx_cleaned_products_supplier_id
    ON cleaned.products (supplier_id);

CREATE INDEX IF NOT EXISTS idx_cleaned_inventory_branch_id
    ON cleaned.inventory (branch_id);

CREATE INDEX IF NOT EXISTS idx_cleaned_inventory_product_id
    ON cleaned.inventory (product_id);

CREATE INDEX IF NOT EXISTS idx_cleaned_gold_prices_gold_type_date
    ON cleaned.gold_prices (gold_type_id, price_date);

-- ============================================
-- 3. Update query-planner statistics
-- ============================================

ANALYZE cleaned.sales;
ANALYZE cleaned.sale_items;
ANALYZE cleaned.products;
ANALYZE cleaned.inventory;
ANALYZE cleaned.gold_prices;

-- ============================================
-- 4. Inspect query performance
-- ============================================

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    s.sale_id,
    s.sale_date,
    s.branch_id,
    SUM(si.quantity * si.unit_price) AS gross_revenue
FROM cleaned.sales AS s
JOIN cleaned.sale_items AS si
    ON s.sale_id = si.sale_id
WHERE s.sale_date >= '2025-01-01'
  AND s.sale_date < '2025-02-01'
GROUP BY
    s.sale_id,
    s.sale_date,
    s.branch_id;