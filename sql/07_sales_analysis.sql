-- ============================================
-- 1. Overall sales KPIs
-- ============================================

WITH transaction_totals AS (
    SELECT
        s.sale_id,
        s.discount_amount,
        SUM(si.quantity) AS units_sold,
        SUM(si.quantity * si.unit_price) AS gross_revenue,
        SUM(
            si.quantity * (si.unit_price - p.cost_price)
        ) AS estimated_profit_before_discount
    FROM cleaned.sales AS s
    JOIN cleaned.sale_items AS si
        ON s.sale_id = si.sale_id
    JOIN cleaned.products AS p
        ON si.product_id = p.product_id
    GROUP BY
        s.sale_id,
        s.discount_amount
)

SELECT
    COUNT(*) AS total_transactions,
    SUM(units_sold) AS total_units_sold,
    ROUND(SUM(gross_revenue), 2) AS gross_revenue,
    ROUND(SUM(discount_amount), 2) AS total_discounts,
    ROUND(
        SUM(gross_revenue - discount_amount),
        2
    ) AS net_revenue,
    ROUND(
        AVG(gross_revenue - discount_amount),
        2
    ) AS average_transaction_value,
    ROUND(
        SUM(
            estimated_profit_before_discount
            - discount_amount
        ),
        2
    ) AS estimated_net_profit
FROM transaction_totals;

-- ============================================
-- 2. Monthly sales performance
-- ============================================

WITH transaction_totals AS (
    SELECT
        s.sale_id,
        DATE_TRUNC('month', s.sale_date)::DATE
            AS sales_month,
        s.discount_amount,
        SUM(si.quantity) AS units_sold,
        SUM(si.quantity * si.unit_price)
            AS gross_revenue,
        SUM(
            si.quantity * (si.unit_price - p.cost_price)
        ) AS estimated_profit_before_discount
    FROM cleaned.sales AS s
    JOIN cleaned.sale_items AS si
        ON s.sale_id = si.sale_id
    JOIN cleaned.products AS p
        ON si.product_id = p.product_id
    GROUP BY
        s.sale_id,
        DATE_TRUNC('month', s.sale_date),
        s.discount_amount
)

SELECT
    sales_month,
    COUNT(*) AS transaction_count,
    SUM(units_sold) AS units_sold,
    ROUND(SUM(gross_revenue), 2) AS gross_revenue,
    ROUND(SUM(discount_amount), 2) AS total_discounts,
    ROUND(
        SUM(gross_revenue - discount_amount),
        2
    ) AS net_revenue,
    ROUND(
        SUM(
            estimated_profit_before_discount
            - discount_amount
        ),
        2
    ) AS estimated_net_profit
FROM transaction_totals
GROUP BY sales_month
ORDER BY sales_month;

-- ============================================
-- 3. Month-over-month revenue growth
-- ============================================

WITH transaction_totals AS (
    SELECT
        s.sale_id,
        DATE_TRUNC('month', s.sale_date)::DATE AS sales_month,
        SUM(si.quantity * si.unit_price)
            - s.discount_amount AS net_revenue
    FROM cleaned.sales AS s
    JOIN cleaned.sale_items AS si
        ON s.sale_id = si.sale_id
    GROUP BY
        s.sale_id,
        DATE_TRUNC('month', s.sale_date),
        s.discount_amount
),

monthly_sales AS (
    SELECT
        sales_month,
        SUM(net_revenue) AS net_revenue
    FROM transaction_totals
    GROUP BY sales_month
),

monthly_comparison AS (
    SELECT
        sales_month,
        net_revenue,
        LAG(net_revenue) OVER (
            ORDER BY sales_month
        ) AS previous_month_revenue
    FROM monthly_sales
)

SELECT
    sales_month,
    ROUND(net_revenue, 2) AS net_revenue,
    ROUND(previous_month_revenue, 2)
        AS previous_month_revenue,
    ROUND(
        (
            net_revenue - previous_month_revenue
        ) / NULLIF(previous_month_revenue, 0) * 100,
        2
    ) AS monthly_growth_percentage
FROM monthly_comparison
ORDER BY sales_month;

-- ============================================
-- 4. Product category sales performance
-- ============================================

WITH item_values AS (
    SELECT
        s.sale_id,
        p.category,
        si.quantity,
        si.quantity * si.unit_price AS item_revenue,
        si.quantity * (
            si.unit_price - p.cost_price
        ) AS item_profit_before_discount,
        s.discount_amount
    FROM cleaned.sales AS s
    JOIN cleaned.sale_items AS si
        ON s.sale_id = si.sale_id
    JOIN cleaned.products AS p
        ON si.product_id = p.product_id
),

sale_totals AS (
    SELECT
        sale_id,
        SUM(item_revenue) AS sale_gross_revenue
    FROM item_values
    GROUP BY sale_id
),

allocated_values AS (
    SELECT
        iv.*,
        iv.discount_amount
            * iv.item_revenue
            / NULLIF(st.sale_gross_revenue, 0)
            AS allocated_discount
    FROM item_values AS iv
    JOIN sale_totals AS st
        ON iv.sale_id = st.sale_id
)

SELECT
    category,
    COUNT(DISTINCT sale_id) AS transaction_count,
    SUM(quantity) AS units_sold,
    ROUND(SUM(item_revenue), 2) AS gross_revenue,
    ROUND(SUM(allocated_discount), 2)
        AS allocated_discounts,
    ROUND(
        SUM(item_revenue - allocated_discount),
        2
    ) AS net_revenue,
    ROUND(
        SUM(
            item_profit_before_discount
            - allocated_discount
        ),
        2
    ) AS estimated_net_profit
FROM allocated_values
GROUP BY category
ORDER BY net_revenue DESC;

-- ============================================
-- 5. Sales performance by payment method
-- ============================================

WITH transaction_totals AS (
    SELECT
        s.sale_id,
        s.payment_method,
        s.discount_amount,
        SUM(si.quantity) AS units_sold,
        SUM(si.quantity * si.unit_price)
            AS gross_revenue,
        SUM(
            si.quantity * (
                si.unit_price - p.cost_price
            )
        ) AS profit_before_discount
    FROM cleaned.sales AS s
    JOIN cleaned.sale_items AS si
        ON s.sale_id = si.sale_id
    JOIN cleaned.products AS p
        ON si.product_id = p.product_id
    GROUP BY
        s.sale_id,
        s.payment_method,
        s.discount_amount
)

SELECT
    payment_method,
    COUNT(*) AS transaction_count,
    SUM(units_sold) AS units_sold,
    ROUND(SUM(gross_revenue), 2) AS gross_revenue,
    ROUND(SUM(discount_amount), 2)
        AS total_discounts,
    ROUND(
        SUM(gross_revenue - discount_amount),
        2
    ) AS net_revenue,
    ROUND(
        AVG(gross_revenue - discount_amount),
        2
    ) AS average_transaction_value,
    ROUND(
        SUM(profit_before_discount - discount_amount),
        2
    ) AS estimated_net_profit
FROM transaction_totals
GROUP BY payment_method
ORDER BY net_revenue DESC;

-- ============================================
-- 6. Top-performing products
-- ============================================

WITH item_values AS (
    SELECT
        s.sale_id,
        p.product_id,
        p.product_name,
        p.category,
        si.quantity,
        si.quantity * si.unit_price AS item_revenue,
        si.quantity * (si.unit_price - p.cost_price)
            AS profit_before_discount,
        s.discount_amount
    FROM cleaned.sales AS s
    JOIN cleaned.sale_items AS si
        ON s.sale_id = si.sale_id
    JOIN cleaned.products AS p
        ON si.product_id = p.product_id
),

sale_totals AS (
    SELECT
        sale_id,
        SUM(item_revenue) AS sale_gross_revenue
    FROM item_values
    GROUP BY sale_id
),

allocated_values AS (
    SELECT
        iv.*,
        iv.discount_amount
            * iv.item_revenue
            / NULLIF(st.sale_gross_revenue, 0)
            AS allocated_discount
    FROM item_values AS iv
    JOIN sale_totals AS st
        ON iv.sale_id = st.sale_id
)

SELECT
    product_id,
    product_name,
    category,
    COUNT(DISTINCT sale_id) AS transaction_count,
    SUM(quantity) AS units_sold,
    ROUND(
        SUM(item_revenue - allocated_discount),
        2
    ) AS net_revenue,
    ROUND(
        SUM(profit_before_discount - allocated_discount),
        2
    ) AS estimated_net_profit
FROM allocated_values
GROUP BY
    product_id,
    product_name,
    category
ORDER BY net_revenue DESC
LIMIT 20;

-- ============================================
-- 7. Sales performance by day of week
-- ============================================

WITH transaction_totals AS (
    SELECT
        s.sale_id,
        EXTRACT(DOW FROM s.sale_date) AS day_number,
        TO_CHAR(s.sale_date, 'FMDay') AS day_name,
        SUM(si.quantity * si.unit_price)
            - s.discount_amount AS net_revenue
    FROM cleaned.sales AS s
    JOIN cleaned.sale_items AS si
        ON s.sale_id = si.sale_id
    GROUP BY
        s.sale_id,
        s.sale_date,
        s.discount_amount
)

SELECT
    day_number,
    day_name,
    COUNT(*) AS transaction_count,
    ROUND(SUM(net_revenue), 2) AS net_revenue,
    ROUND(AVG(net_revenue), 2)
        AS average_transaction_value
FROM transaction_totals
GROUP BY
    day_number,
    day_name
ORDER BY day_number;

-- ============================================
-- 8. Discounted vs non-discounted transactions
-- ============================================

WITH transaction_totals AS (
    SELECT
        s.sale_id,
        CASE
            WHEN s.discount_amount > 0
                THEN 'Discounted'
            ELSE 'No Discount'
        END AS discount_status,
        s.discount_amount,
        SUM(si.quantity * si.unit_price)
            AS gross_revenue
    FROM cleaned.sales AS s
    JOIN cleaned.sale_items AS si
        ON s.sale_id = si.sale_id
    GROUP BY
        s.sale_id,
        s.discount_amount
)

SELECT
    discount_status,
    COUNT(*) AS transaction_count,
    ROUND(SUM(gross_revenue), 2)
        AS gross_revenue,
    ROUND(SUM(discount_amount), 2)
        AS total_discounts,
    ROUND(
        SUM(gross_revenue - discount_amount),
        2
    ) AS net_revenue,
    ROUND(
        AVG(gross_revenue - discount_amount),
        2
    ) AS average_transaction_value
FROM transaction_totals
GROUP BY discount_status
ORDER BY net_revenue DESC;