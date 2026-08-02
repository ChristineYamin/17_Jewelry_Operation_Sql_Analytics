-- ============================================
-- 1. Branch sales performance
-- ============================================

WITH transaction_totals AS (
    SELECT
        s.sale_id,
        s.branch_id,
        s.customer_id,
        s.discount_amount,
        SUM(si.quantity) AS units_sold,
        SUM(si.quantity * si.unit_price) AS gross_revenue,
        SUM(
            si.quantity * (si.unit_price - p.cost_price)
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
    SUM(tt.units_sold) AS units_sold,
    ROUND(SUM(tt.gross_revenue), 2)
        AS gross_revenue,
    ROUND(SUM(tt.discount_amount), 2)
        AS total_discounts,
    ROUND(
        SUM(tt.gross_revenue - tt.discount_amount),
        2
    ) AS net_revenue,
    ROUND(
        AVG(tt.gross_revenue - tt.discount_amount),
        2
    ) AS average_transaction_value,
    ROUND(
        SUM(
            tt.profit_before_discount
            - tt.discount_amount
        ),
        2
    ) AS estimated_net_profit
FROM cleaned.branches AS b
LEFT JOIN transaction_totals AS tt
    ON b.branch_id = tt.branch_id
GROUP BY
    b.branch_id,
    b.branch_name,
    b.city
ORDER BY net_revenue DESC NULLS LAST;
-- ============================================
-- 2. Branch performance rankings
-- ============================================

WITH transaction_totals AS (
    SELECT
        s.sale_id,
        s.branch_id,
        SUM(si.quantity * si.unit_price)
            - s.discount_amount AS net_revenue
    FROM cleaned.sales AS s
    JOIN cleaned.sale_items AS si
        ON s.sale_id = si.sale_id
    GROUP BY
        s.sale_id,
        s.branch_id,
        s.discount_amount
),

branch_performance AS (
    SELECT
        b.branch_id,
        b.branch_name,
        b.city,
        COUNT(tt.sale_id) AS transaction_count,
        COALESCE(SUM(tt.net_revenue), 0)
            AS net_revenue
    FROM cleaned.branches AS b
    LEFT JOIN transaction_totals AS tt
        ON b.branch_id = tt.branch_id
    GROUP BY
        b.branch_id,
        b.branch_name,
        b.city
)

SELECT
    branch_id,
    branch_name,
    city,
    transaction_count,
    ROUND(net_revenue, 2) AS net_revenue,

    RANK() OVER (
        ORDER BY net_revenue DESC
    ) AS revenue_rank,

    RANK() OVER (
        ORDER BY transaction_count DESC
    ) AS transaction_rank

FROM branch_performance
ORDER BY revenue_rank;

-- ============================================
-- 3. Employee sales performance
-- ============================================

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
    b.branch_name,
    COUNT(tt.sale_id) AS transaction_count,
    COALESCE(SUM(tt.units_sold), 0) AS units_sold,
    ROUND(
        COALESCE(SUM(tt.net_revenue), 0),
        2
    ) AS net_revenue,
    ROUND(
        COALESCE(AVG(tt.net_revenue), 0),
        2
    ) AS average_transaction_value,
    ROUND(
        COALESCE(SUM(tt.estimated_net_profit), 0),
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
    b.branch_name
ORDER BY net_revenue DESC;

-- ============================================
-- 4. Employee rankings within each branch
-- ============================================

WITH transaction_totals AS (
    SELECT
        s.sale_id,
        s.employee_id,
        SUM(si.quantity * si.unit_price)
            - s.discount_amount AS net_revenue
    FROM cleaned.sales AS s
    JOIN cleaned.sale_items AS si
        ON s.sale_id = si.sale_id
    GROUP BY
        s.sale_id,
        s.employee_id,
        s.discount_amount
),

employee_performance AS (
    SELECT
        e.employee_id,
        e.employee_name,
        e.job_title,
        e.branch_id,
        b.branch_name,
        COUNT(tt.sale_id) AS transaction_count,
        COALESCE(SUM(tt.net_revenue), 0)
            AS net_revenue
    FROM cleaned.employees AS e
    JOIN cleaned.branches AS b
        ON e.branch_id = b.branch_id
    LEFT JOIN transaction_totals AS tt
        ON e.employee_id = tt.employee_id
    GROUP BY
        e.employee_id,
        e.employee_name,
        e.job_title,
        e.branch_id,
        b.branch_name
)

SELECT
    employee_id,
    employee_name,
    job_title,
    branch_name,
    transaction_count,
    ROUND(net_revenue, 2) AS net_revenue,

    RANK() OVER (
        PARTITION BY branch_id
        ORDER BY net_revenue DESC
    ) AS rank_within_branch,

    RANK() OVER (
        ORDER BY net_revenue DESC
    ) AS overall_rank

FROM employee_performance
ORDER BY overall_rank;

-- ============================================
-- 5. Monthly employee target achievement
-- ============================================

WITH transaction_totals AS (
    SELECT
        s.sale_id,
        s.employee_id,
        DATE_TRUNC('month', s.sale_date)::DATE
            AS sales_month,
        SUM(si.quantity * si.unit_price)
            - s.discount_amount AS net_revenue
    FROM cleaned.sales AS s
    JOIN cleaned.sale_items AS si
        ON s.sale_id = si.sale_id
    GROUP BY
        s.sale_id,
        s.employee_id,
        DATE_TRUNC('month', s.sale_date),
        s.discount_amount
),

monthly_employee_performance AS (
    SELECT
        e.employee_id,
        e.employee_name,
        e.branch_id,
        b.branch_name,
        e.monthly_target,
        tt.sales_month,
        COUNT(tt.sale_id) AS transaction_count,
        SUM(tt.net_revenue) AS monthly_net_revenue
    FROM cleaned.employees AS e
    JOIN cleaned.branches AS b
        ON e.branch_id = b.branch_id
    JOIN transaction_totals AS tt
        ON e.employee_id = tt.employee_id
    GROUP BY
        e.employee_id,
        e.employee_name,
        e.branch_id,
        b.branch_name,
        e.monthly_target,
        tt.sales_month
)

SELECT
    employee_id,
    employee_name,
    branch_name,
    sales_month,
    transaction_count,
    monthly_target,
    ROUND(monthly_net_revenue, 2)
        AS monthly_net_revenue,
    ROUND(
        monthly_net_revenue
        / NULLIF(monthly_target, 0) * 100,
        2
    ) AS target_achievement_percentage,
    CASE
        WHEN monthly_net_revenue >= monthly_target
            THEN 'Target Achieved'
        ELSE 'Below Target'
    END AS target_status
FROM monthly_employee_performance
ORDER BY
    sales_month,
    target_achievement_percentage DESC;

-- ============================================
-- 6. Employee target achievement summary
-- ============================================

WITH transaction_totals AS (
    SELECT
        s.sale_id,
        s.employee_id,
        DATE_TRUNC('month', s.sale_date)::DATE
            AS sales_month,
        SUM(si.quantity * si.unit_price)
            - s.discount_amount AS net_revenue
    FROM cleaned.sales AS s
    JOIN cleaned.sale_items AS si
        ON s.sale_id = si.sale_id
    GROUP BY
        s.sale_id,
        s.employee_id,
        DATE_TRUNC('month', s.sale_date),
        s.discount_amount
),

monthly_performance AS (
    SELECT
        e.employee_id,
        e.employee_name,
        e.branch_id,
        e.monthly_target,
        tt.sales_month,
        SUM(tt.net_revenue) AS monthly_net_revenue
    FROM cleaned.employees AS e
    JOIN transaction_totals AS tt
        ON e.employee_id = tt.employee_id
    GROUP BY
        e.employee_id,
        e.employee_name,
        e.branch_id,
        e.monthly_target,
        tt.sales_month
)

SELECT
    mp.employee_id,
    mp.employee_name,
    b.branch_name,
    COUNT(*) AS active_sales_months,
    COUNT(*) FILTER (
        WHERE mp.monthly_net_revenue
              >= mp.monthly_target
    ) AS months_target_achieved,
    ROUND(
        COUNT(*) FILTER (
            WHERE mp.monthly_net_revenue
                  >= mp.monthly_target
        ) * 100.0 / COUNT(*),
        2
    ) AS target_success_rate_percentage,
    ROUND(
        AVG(
            mp.monthly_net_revenue
            / NULLIF(mp.monthly_target, 0)
            * 100
        ),
        2
    ) AS average_target_achievement_percentage
FROM monthly_performance AS mp
JOIN cleaned.branches AS b
    ON mp.branch_id = b.branch_id
GROUP BY
    mp.employee_id,
    mp.employee_name,
    b.branch_name
ORDER BY target_success_rate_percentage DESC;

-- ============================================
-- 7. Monthly branch revenue growth
-- ============================================

WITH transaction_totals AS (
    SELECT
        s.sale_id,
        s.branch_id,
        DATE_TRUNC('month', s.sale_date)::DATE
            AS sales_month,
        SUM(si.quantity * si.unit_price)
            - s.discount_amount AS net_revenue
    FROM cleaned.sales AS s
    JOIN cleaned.sale_items AS si
        ON s.sale_id = si.sale_id
    GROUP BY
        s.sale_id,
        s.branch_id,
        DATE_TRUNC('month', s.sale_date),
        s.discount_amount
),

monthly_branch_sales AS (
    SELECT
        branch_id,
        sales_month,
        COUNT(*) AS transaction_count,
        SUM(net_revenue) AS net_revenue
    FROM transaction_totals
    GROUP BY
        branch_id,
        sales_month
),

branch_comparison AS (
    SELECT
        *,
        LAG(net_revenue) OVER (
            PARTITION BY branch_id
            ORDER BY sales_month
        ) AS previous_month_revenue
    FROM monthly_branch_sales
)

SELECT
    b.branch_name,
    bc.sales_month,
    bc.transaction_count,
    ROUND(bc.net_revenue, 2)
        AS net_revenue,
    ROUND(bc.previous_month_revenue, 2)
        AS previous_month_revenue,
    ROUND(
        (
            bc.net_revenue
            - bc.previous_month_revenue
        )
        / NULLIF(
            bc.previous_month_revenue,
            0
        ) * 100,
        2
    ) AS monthly_growth_percentage
FROM branch_comparison AS bc
JOIN cleaned.branches AS b
    ON bc.branch_id = b.branch_id
ORDER BY
    b.branch_name,
    bc.sales_month;