-- ============================================
-- 1. Monthly sales summary view
-- ============================================

CREATE OR REPLACE VIEW analytics.monthly_sales_summary AS

WITH transaction_totals AS (
    SELECT
        s.sale_id,
        DATE_TRUNC('month', s.sale_date)::DATE
            AS sales_month,
        s.customer_id,
        s.discount_amount,
        SUM(si.quantity) AS units_sold,
        SUM(si.quantity * si.unit_price)
            AS gross_revenue,
        SUM(
            si.quantity *
            (si.unit_price - p.cost_price)
        ) AS profit_before_discount
    FROM cleaned.sales AS s
    JOIN cleaned.sale_items AS si
        ON s.sale_id = si.sale_id
    JOIN cleaned.products AS p
        ON si.product_id = p.product_id
    GROUP BY
        s.sale_id,
        DATE_TRUNC('month', s.sale_date),
        s.customer_id,
        s.discount_amount
)

SELECT
    sales_month,
    COUNT(*) AS transaction_count,
    COUNT(DISTINCT customer_id)
        AS registered_customers,
    SUM(units_sold) AS units_sold,
    ROUND(SUM(gross_revenue), 2)
        AS gross_revenue,
    ROUND(SUM(discount_amount), 2)
        AS total_discounts,
    ROUND(
        SUM(gross_revenue - discount_amount),
        2
    ) AS net_revenue,
    ROUND(
        SUM(profit_before_discount - discount_amount),
        2
    ) AS estimated_net_profit,
    ROUND(
        AVG(gross_revenue - discount_amount),
        2
    ) AS average_transaction_value
FROM transaction_totals
GROUP BY sales_month
ORDER BY sales_month;

-- ============================================
-- 2. Branch performance view
-- ============================================

CREATE OR REPLACE VIEW analytics.branch_performance AS

WITH transaction_totals AS (
    SELECT
        s.sale_id,
        s.branch_id,
        s.customer_id,
        s.discount_amount,
        SUM(si.quantity) AS units_sold,
        SUM(si.quantity * si.unit_price)
            AS gross_revenue,
        SUM(
            si.quantity *
            (si.unit_price - p.cost_price)
        ) AS profit_before_discount
    FROM cleaned.sales AS s
    JOIN cleaned.sale_items AS si
        ON s.sale_id = si.sale_id
    JOIN cleaned.products AS p
        ON si.product_id = p.product_id
    GROUP BY
        s.sale_id,
        s.branch_id,
        s.customer_id,
        s.discount_amount
)

SELECT
    b.branch_id,
    b.branch_name,
    b.city,
    COUNT(tt.sale_id) AS transaction_count,
    COUNT(DISTINCT tt.customer_id)
        AS registered_customers,
    COALESCE(SUM(tt.units_sold), 0)
        AS units_sold,
    ROUND(
        COALESCE(
            SUM(tt.gross_revenue - tt.discount_amount),
            0
        ),
        2
    ) AS net_revenue,
    ROUND(
        COALESCE(
            AVG(tt.gross_revenue - tt.discount_amount),
            0
        ),
        2
    ) AS average_transaction_value,
    ROUND(
        COALESCE(
            SUM(
                tt.profit_before_discount
                - tt.discount_amount
            ),
            0
        ),
        2
    ) AS estimated_net_profit
FROM cleaned.branches AS b
LEFT JOIN transaction_totals AS tt
    ON b.branch_id = tt.branch_id
GROUP BY
    b.branch_id,
    b.branch_name,
    b.city;

-- ============================================
-- 3. Product performance view
-- ============================================

CREATE OR REPLACE VIEW analytics.product_performance AS

SELECT
    p.product_id,
    p.product_name,
    p.category,
    gt.gold_type_name,
    COUNT(DISTINCT si.sale_id) AS transaction_count,
    COALESCE(SUM(si.quantity), 0) AS units_sold,

    ROUND(
        COALESCE(
            SUM(si.quantity * si.unit_price),
            0
        ),
        2
    ) AS gross_revenue,

    ROUND(
        COALESCE(
            SUM(
                si.quantity *
                (si.unit_price - p.cost_price)
            ),
            0
        ),
        2
    ) AS estimated_profit_before_discount

FROM cleaned.products AS p

JOIN cleaned.gold_types AS gt
    ON p.gold_type_id = gt.gold_type_id

LEFT JOIN cleaned.sale_items AS si
    ON p.product_id = si.product_id

GROUP BY
    p.product_id,
    p.product_name,
    p.category,
    gt.gold_type_name;

-- ============================================
-- 4. Customer summary view
-- ============================================

CREATE OR REPLACE VIEW analytics.customer_summary AS

WITH transaction_totals AS (
    SELECT
        s.sale_id,
        s.customer_id,
        s.sale_date::DATE AS sale_date,

        SUM(si.quantity * si.unit_price)
            - s.discount_amount AS net_revenue

    FROM cleaned.sales AS s

    JOIN cleaned.sale_items AS si
        ON s.sale_id = si.sale_id

    WHERE s.customer_id IS NOT NULL

    GROUP BY
        s.sale_id,
        s.customer_id,
        s.sale_date,
        s.discount_amount
)

SELECT
    c.customer_id,
    c.customer_name,
    COALESCE(c.city, 'Unknown') AS city,

    COUNT(tt.sale_id) AS purchase_count,

    MIN(tt.sale_date) AS first_purchase_date,

    MAX(tt.sale_date) AS last_purchase_date,

    ROUND(
        COALESCE(SUM(tt.net_revenue), 0),
        2
    ) AS total_spent,

    ROUND(
        COALESCE(AVG(tt.net_revenue), 0),
        2
    ) AS average_transaction_value

FROM cleaned.customers AS c

LEFT JOIN transaction_totals AS tt
    ON c.customer_id = tt.customer_id

GROUP BY
    c.customer_id,
    c.customer_name,
    c.city;

-- ============================================
-- 5. Inventory risk view
-- ============================================

CREATE OR REPLACE VIEW analytics.inventory_risk AS

SELECT
    i.inventory_id,
    b.branch_id,
    b.branch_name,
    p.product_id,
    p.product_name,
    p.category,
    i.stock_quantity,
    i.reorder_level,
    i.last_updated,

    CASE
        WHEN i.stock_quantity = 0
            THEN 'Out of Stock'

        WHEN i.stock_quantity <= i.reorder_level
            THEN 'Low Stock'

        ELSE 'Healthy Stock'
    END AS inventory_status,

    ROUND(
        i.stock_quantity * p.cost_price,
        2
    ) AS inventory_cost_value,

    ROUND(
        i.stock_quantity * p.selling_price,
        2
    ) AS inventory_retail_value

FROM cleaned.inventory AS i

JOIN cleaned.branches AS b
    ON i.branch_id = b.branch_id

JOIN cleaned.products AS p
    ON i.product_id = p.product_id;

-- ============================================
-- 6. Employee performance view
-- ============================================

CREATE OR REPLACE VIEW analytics.employee_performance AS

WITH transaction_totals AS (
    SELECT
        s.sale_id,
        s.employee_id,
        SUM(si.quantity) AS units_sold,

        SUM(si.quantity * si.unit_price)
            - s.discount_amount AS net_revenue,

        SUM(
            si.quantity *
            (si.unit_price - p.cost_price)
        ) - s.discount_amount AS estimated_net_profit

    FROM cleaned.sales AS s

    JOIN cleaned.sale_items AS si
        ON s.sale_id = si.sale_id

    JOIN cleaned.products AS p
        ON si.product_id = p.product_id

    GROUP BY
        s.sale_id,
        s.employee_id,
        s.discount_amount
)

SELECT
    e.employee_id,
    e.employee_name,
    e.job_title,
    b.branch_id,
    b.branch_name,
    e.monthly_target,

    COUNT(tt.sale_id) AS transaction_count,

    COALESCE(
        SUM(tt.units_sold),
        0
    ) AS units_sold,

    ROUND(
        COALESCE(SUM(tt.net_revenue), 0),
        2
    ) AS net_revenue,

    ROUND(
        COALESCE(AVG(tt.net_revenue), 0),
        2
    ) AS average_transaction_value,

    ROUND(
        COALESCE(
            SUM(tt.estimated_net_profit),
            0
        ),
        2
    ) AS estimated_net_profit

FROM cleaned.employees AS e

JOIN cleaned.branches AS b
    ON e.branch_id = b.branch_id

LEFT JOIN transaction_totals AS tt
    ON e.employee_id = tt.employee_id

GROUP BY
    e.employee_id,
    e.employee_name,
    e.job_title,
    b.branch_id,
    b.branch_name,
    e.monthly_target;


-- ============================================
-- 7. Customer RFM segments view
-- ============================================

CREATE OR REPLACE VIEW analytics.customer_segments AS

WITH reference_date AS (
    SELECT
        MAX(sale_date::DATE) + 1 AS analysis_date
    FROM cleaned.sales
),

transaction_totals AS (
    SELECT
        s.sale_id,
        s.customer_id,
        s.sale_date::DATE AS sale_date,

        SUM(si.quantity * si.unit_price)
            - s.discount_amount AS net_revenue

    FROM cleaned.sales AS s

    JOIN cleaned.sale_items AS si
        ON s.sale_id = si.sale_id

    WHERE s.customer_id IS NOT NULL

    GROUP BY
        s.sale_id,
        s.customer_id,
        s.sale_date,
        s.discount_amount
),

customer_rfm AS (
    SELECT
        tt.customer_id,

        r.analysis_date - MAX(tt.sale_date)
            AS recency_days,

        COUNT(*) AS frequency,

        SUM(tt.net_revenue)
            AS monetary_value

    FROM transaction_totals AS tt

    CROSS JOIN reference_date AS r

    GROUP BY
        tt.customer_id,
        r.analysis_date
),

rfm_scores AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary_value,

        NTILE(5) OVER (
            ORDER BY recency_days DESC
        ) AS recency_score,

        NTILE(5) OVER (
            ORDER BY frequency
        ) AS frequency_score,

        NTILE(5) OVER (
            ORDER BY monetary_value
        ) AS monetary_score

    FROM customer_rfm
)

SELECT
    c.customer_id,
    c.customer_name,
    COALESCE(c.city, 'Unknown') AS city,

    r.recency_days,
    r.frequency,

    ROUND(
        r.monetary_value,
        2
    ) AS monetary_value,

    r.recency_score,
    r.frequency_score,
    r.monetary_score,

    CASE
        WHEN r.recency_score >= 4
             AND r.frequency_score >= 4
             AND r.monetary_score >= 4
            THEN 'Champions'

        WHEN r.recency_score <= 2
             AND r.frequency_score >= 3
            THEN 'At Risk'

        WHEN r.recency_score >= 4
             AND r.frequency = 1
            THEN 'New Customers'

        WHEN r.frequency_score >= 4
             AND r.monetary_score >= 3
            THEN 'Loyal Customers'

        WHEN r.recency_score >= 4
             AND r.frequency_score BETWEEN 2 AND 3
            THEN 'Potential Loyalists'

        WHEN r.recency_score <= 2
             AND r.frequency_score <= 2
            THEN 'Hibernating'

        ELSE 'Needs Attention'
    END AS customer_segment

FROM rfm_scores AS r

JOIN cleaned.customers AS c
    ON r.customer_id = c.customer_id;

-- ============================================
-- 8. Executive summary view
-- ============================================

CREATE OR REPLACE VIEW analytics.executive_summary AS

WITH transaction_totals AS (
    SELECT
        s.sale_id,
        s.customer_id,
        s.branch_id,
        s.discount_amount,

        SUM(si.quantity) AS units_sold,

        SUM(si.quantity * si.unit_price)
            AS gross_revenue,

        SUM(
            si.quantity *
            (si.unit_price - p.cost_price)
        ) AS profit_before_discount

    FROM cleaned.sales AS s

    JOIN cleaned.sale_items AS si
        ON s.sale_id = si.sale_id

    JOIN cleaned.products AS p
        ON si.product_id = p.product_id

    GROUP BY
        s.sale_id,
        s.customer_id,
        s.branch_id,
        s.discount_amount
)

SELECT
    COUNT(*) AS total_transactions,

    COUNT(DISTINCT customer_id)
        AS registered_customers,

    COUNT(DISTINCT branch_id)
        AS active_branches,

    SUM(units_sold)
        AS total_units_sold,

    ROUND(
        SUM(gross_revenue),
        2
    ) AS gross_revenue,

    ROUND(
        SUM(discount_amount),
        2
    ) AS total_discounts,

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
            profit_before_discount
            - discount_amount
        ),
        2
    ) AS estimated_net_profit

FROM transaction_totals;