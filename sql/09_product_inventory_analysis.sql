-- ============================================
-- 1. Overall product and inventory KPIs
-- ============================================

SELECT
    COUNT(DISTINCT p.product_id) AS total_products,
    COUNT(DISTINCT p.category) AS total_categories,
    SUM(i.stock_quantity) AS total_stock_units,
    COUNT(*) FILTER (
        WHERE i.stock_quantity = 0
    ) AS out_of_stock_records,
    COUNT(*) FILTER (
        WHERE i.stock_quantity > 0
          AND i.stock_quantity <= i.reorder_level
    ) AS low_stock_records,
    ROUND(
        SUM(i.stock_quantity * p.cost_price),
        2
    ) AS estimated_inventory_cost_value,
    ROUND(
        SUM(i.stock_quantity * p.selling_price),
        2
    ) AS estimated_inventory_retail_value
FROM cleaned.products AS p
JOIN cleaned.inventory AS i
    ON p.product_id = i.product_id;

-- ============================================
-- 2. Product performance by category
-- ============================================

SELECT
    p.category,
    COUNT(DISTINCT p.product_id) AS product_count,
    COUNT(DISTINCT si.sale_id) AS transaction_count,
    SUM(si.quantity) AS units_sold,
    ROUND(
        SUM(si.quantity * si.unit_price),
        2
    ) AS gross_revenue,
    ROUND(
        SUM(
            si.quantity * (
                si.unit_price - p.cost_price
            )
        ),
        2
    ) AS estimated_profit_before_discount,
    ROUND(
        AVG(p.selling_price),
        2
    ) AS average_product_price
FROM cleaned.products AS p
LEFT JOIN cleaned.sale_items AS si
    ON p.product_id = si.product_id
GROUP BY p.category
ORDER BY gross_revenue DESC NULLS LAST;

-- ============================================
-- 3. Low-stock and out-of-stock products
-- ============================================

SELECT
    b.branch_name,
    p.product_id,
    p.product_name,
    p.category,
    i.stock_quantity,
    i.reorder_level,
    CASE
        WHEN i.stock_quantity = 0
            THEN 'Out of Stock'
        WHEN i.stock_quantity <= i.reorder_level
            THEN 'Low Stock'
    END AS stock_status
FROM cleaned.inventory AS i
JOIN cleaned.branches AS b
    ON i.branch_id = b.branch_id
JOIN cleaned.products AS p
    ON i.product_id = p.product_id
WHERE i.stock_quantity <= i.reorder_level
ORDER BY
    CASE
        WHEN i.stock_quantity = 0 THEN 1
        ELSE 2
    END,
    b.branch_name,
    i.stock_quantity;

-- ============================================
-- 4. Inventory value by branch
-- ============================================

SELECT
    b.branch_id,
    b.branch_name,
    b.city,
    SUM(i.stock_quantity) AS total_stock_units,
    ROUND(
        SUM(i.stock_quantity * p.cost_price),
        2
    ) AS inventory_cost_value,
    ROUND(
        SUM(i.stock_quantity * p.selling_price),
        2
    ) AS inventory_retail_value,
    ROUND(
        SUM(
            i.stock_quantity
            * (p.selling_price - p.cost_price)
        ),
        2
    ) AS potential_inventory_profit
FROM cleaned.inventory AS i
JOIN cleaned.branches AS b
    ON i.branch_id = b.branch_id
JOIN cleaned.products AS p
    ON i.product_id = p.product_id
GROUP BY
    b.branch_id,
    b.branch_name,
    b.city
ORDER BY inventory_retail_value DESC;

-- ============================================
-- 5. Slow-moving and unsold products
-- ============================================

WITH reference_date AS (
    SELECT
        MAX(sale_date::DATE) AS analysis_date
    FROM cleaned.sales
),

product_sales AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        MAX(s.sale_date::DATE) AS last_sale_date,
        COALESCE(SUM(si.quantity), 0) AS total_units_sold
    FROM cleaned.products AS p
    LEFT JOIN cleaned.sale_items AS si
        ON p.product_id = si.product_id
    LEFT JOIN cleaned.sales AS s
        ON si.sale_id = s.sale_id
    GROUP BY
        p.product_id,
        p.product_name,
        p.category
),

product_inventory AS (
    SELECT
        product_id,
        SUM(stock_quantity) AS total_stock_quantity
    FROM cleaned.inventory
    GROUP BY product_id
)

SELECT
    ps.product_id,
    ps.product_name,
    ps.category,
    ps.total_units_sold,
    ps.last_sale_date,
    CASE
        WHEN ps.last_sale_date IS NULL THEN NULL
        ELSE r.analysis_date - ps.last_sale_date
    END AS days_since_last_sale,
    pi.total_stock_quantity,
    CASE
        WHEN ps.last_sale_date IS NULL
            THEN 'Never Sold'
        WHEN r.analysis_date - ps.last_sale_date > 180
            THEN 'Slow Moving'
    END AS product_status
FROM product_sales AS ps
JOIN product_inventory AS pi
    ON ps.product_id = pi.product_id
CROSS JOIN reference_date AS r
WHERE ps.last_sale_date IS NULL
   OR r.analysis_date - ps.last_sale_date > 180
ORDER BY
    ps.last_sale_date NULLS FIRST,
    pi.total_stock_quantity DESC;

-- ============================================
-- 6. Top 20 products by sales performance
-- ============================================

SELECT
    p.product_id,
    p.product_name,
    p.category,
    gt.gold_type_name,
    COUNT(DISTINCT si.sale_id) AS transaction_count,
    SUM(si.quantity) AS units_sold,
    ROUND(
        SUM(si.quantity * si.unit_price),
        2
    ) AS gross_revenue,
    ROUND(
        SUM(
            si.quantity *
            (si.unit_price - p.cost_price)
        ),
        2
    ) AS estimated_profit_before_discount
FROM cleaned.products AS p
JOIN cleaned.sale_items AS si
    ON p.product_id = si.product_id
JOIN cleaned.gold_types AS gt
    ON p.gold_type_id = gt.gold_type_id
GROUP BY
    p.product_id,
    p.product_name,
    p.category,
    gt.gold_type_name
ORDER BY gross_revenue DESC
LIMIT 20;

-- ============================================
-- 7. Potential overstock based on recent sales
-- ============================================

WITH reference_date AS (
    SELECT
        MAX(sale_date::DATE) AS analysis_date
    FROM cleaned.sales
),

recent_product_sales AS (
    SELECT
        si.product_id,
        SUM(si.quantity) AS units_sold_last_90_days
    FROM cleaned.sale_items AS si
    JOIN cleaned.sales AS s
        ON si.sale_id = s.sale_id
    CROSS JOIN reference_date AS r
    WHERE s.sale_date::DATE >
          r.analysis_date - 90
    GROUP BY si.product_id
),

product_inventory AS (
    SELECT
        product_id,
        SUM(stock_quantity) AS total_stock_quantity
    FROM cleaned.inventory
    GROUP BY product_id
)

SELECT
    p.product_id,
    p.product_name,
    p.category,
    pi.total_stock_quantity,
    COALESCE(
        rps.units_sold_last_90_days,
        0
    ) AS units_sold_last_90_days,

    ROUND(
        pi.total_stock_quantity::NUMERIC
        / NULLIF(
            rps.units_sold_last_90_days,
            0
        ),
        2
    ) AS stock_to_recent_sales_ratio,

    CASE
        WHEN COALESCE(
            rps.units_sold_last_90_days,
            0
        ) = 0
        AND pi.total_stock_quantity > 0
            THEN 'No Recent Sales'

        WHEN pi.total_stock_quantity >
             rps.units_sold_last_90_days * 2
            THEN 'Potential Overstock'

        ELSE 'Normal Stock'
    END AS inventory_risk

FROM cleaned.products AS p

JOIN product_inventory AS pi
    ON p.product_id = pi.product_id

LEFT JOIN recent_product_sales AS rps
    ON p.product_id = rps.product_id

WHERE
    COALESCE(
        rps.units_sold_last_90_days,
        0
    ) = 0
    OR pi.total_stock_quantity >
       rps.units_sold_last_90_days * 2

ORDER BY
    units_sold_last_90_days,
    pi.total_stock_quantity DESC;

-- ============================================
-- 8. Supplier product and sales performance
-- ============================================

WITH product_sales AS (
    SELECT
        si.product_id,
        SUM(si.quantity) AS units_sold,
        SUM(
            si.quantity * si.unit_price
        ) AS gross_revenue
    FROM cleaned.sale_items AS si
    GROUP BY si.product_id
),

product_inventory AS (
    SELECT
        product_id,
        SUM(stock_quantity) AS stock_quantity
    FROM cleaned.inventory
    GROUP BY product_id
)

SELECT
    s.supplier_id,
    s.supplier_name,
    COUNT(p.product_id) AS products_supplied,

    COALESCE(
        SUM(ps.units_sold),
        0
    ) AS units_sold,

    ROUND(
        COALESCE(
            SUM(ps.gross_revenue),
            0
        ),
        2
    ) AS gross_revenue,

    COALESCE(
        SUM(pi.stock_quantity),
        0
    ) AS current_stock_units,

    ROUND(
        COALESCE(
            SUM(
                pi.stock_quantity
                * p.cost_price
            ),
            0
        ),
        2
    ) AS inventory_cost_value

FROM cleaned.suppliers AS s

LEFT JOIN cleaned.products AS p
    ON s.supplier_id = p.supplier_id

LEFT JOIN product_sales AS ps
    ON p.product_id = ps.product_id

LEFT JOIN product_inventory AS pi
    ON p.product_id = pi.product_id

GROUP BY
    s.supplier_id,
    s.supplier_name

ORDER BY gross_revenue DESC;
