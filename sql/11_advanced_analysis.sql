-- ============================================
-- 1. Monthly cumulative revenue and
--    three-month rolling average
-- ============================================

WITH transaction_totals AS (
    SELECT
        s.sale_id,
        DATE_TRUNC('month', s.sale_date)::DATE
            AS sales_month,
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

monthly_revenue AS (
    SELECT
        sales_month,
        SUM(net_revenue) AS net_revenue
    FROM transaction_totals
    GROUP BY sales_month
)

SELECT
    sales_month,
    ROUND(net_revenue, 2) AS monthly_net_revenue,

    ROUND(
        SUM(net_revenue) OVER (
            ORDER BY sales_month
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ),
        2
    ) AS cumulative_net_revenue,

    ROUND(
        AVG(net_revenue) OVER (
            ORDER BY sales_month
            ROWS BETWEEN 2 PRECEDING
            AND CURRENT ROW
        ),
        2
    ) AS three_month_rolling_average

FROM monthly_revenue
ORDER BY sales_month;

-- ============================================
-- 2. Product revenue ranking within category
-- ============================================

WITH product_performance AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(si.quantity) AS units_sold,
        SUM(
            si.quantity * si.unit_price
        ) AS gross_revenue
    FROM cleaned.products AS p
    JOIN cleaned.sale_items AS si
        ON p.product_id = si.product_id
    GROUP BY
        p.product_id,
        p.product_name,
        p.category
)

SELECT
    product_id,
    product_name,
    category,
    units_sold,
    ROUND(gross_revenue, 2) AS gross_revenue,

    DENSE_RANK() OVER (
        PARTITION BY category
        ORDER BY gross_revenue DESC
    ) AS revenue_rank_within_category,

    ROUND(
        gross_revenue * 100.0
        / SUM(gross_revenue) OVER (
            PARTITION BY category
        ),
        2
    ) AS category_revenue_percentage

FROM product_performance
ORDER BY
    category,
    revenue_rank_within_category;

-- ============================================
-- 3. Product revenue contribution and Pareto analysis
-- ============================================

WITH product_revenue AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        SUM(
            si.quantity * si.unit_price
        ) AS gross_revenue
    FROM cleaned.products AS p
    JOIN cleaned.sale_items AS si
        ON p.product_id = si.product_id
    GROUP BY
        p.product_id,
        p.product_name,
        p.category
),

ranked_products AS (
    SELECT
        *,
        SUM(gross_revenue) OVER (
            ORDER BY gross_revenue DESC, product_id
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS cumulative_revenue,

        SUM(gross_revenue) OVER ()
            AS total_revenue
    FROM product_revenue
)

SELECT
    product_id,
    product_name,
    category,
    ROUND(gross_revenue, 2)
        AS gross_revenue,

    ROUND(
        gross_revenue * 100.0
        / NULLIF(total_revenue, 0),
        2
    ) AS revenue_contribution_percentage,

    ROUND(
        cumulative_revenue * 100.0
        / NULLIF(total_revenue, 0),
        2
    ) AS cumulative_revenue_percentage,

    CASE
        WHEN cumulative_revenue * 100.0
             / NULLIF(total_revenue, 0) <= 80
            THEN 'Top Revenue Contributors'
        ELSE 'Remaining Products'
    END AS pareto_group

FROM ranked_products
ORDER BY gross_revenue DESC;

-- ============================================
-- 4. Monthly branch revenue share and ranking
-- ============================================

WITH transaction_totals AS (
    SELECT
        s.sale_id,
        s.branch_id,
        DATE_TRUNC(
            'month',
            s.sale_date
        )::DATE AS sales_month,

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

monthly_branch_revenue AS (
    SELECT
        branch_id,
        sales_month,
        COUNT(*) AS transaction_count,
        SUM(net_revenue) AS net_revenue
    FROM transaction_totals
    GROUP BY
        branch_id,
        sales_month
)

SELECT
    mbr.sales_month,
    b.branch_name,
    mbr.transaction_count,

    ROUND(
        mbr.net_revenue,
        2
    ) AS net_revenue,

    ROUND(
        mbr.net_revenue * 100.0
        / NULLIF(
            SUM(mbr.net_revenue) OVER (
                PARTITION BY mbr.sales_month
            ),
            0
        ),
        2
    ) AS monthly_revenue_share_percentage,

    RANK() OVER (
        PARTITION BY mbr.sales_month
        ORDER BY mbr.net_revenue DESC
    ) AS monthly_branch_rank

FROM monthly_branch_revenue AS mbr

JOIN cleaned.branches AS b
    ON mbr.branch_id = b.branch_id

ORDER BY
    mbr.sales_month,
    monthly_branch_rank;

-- ============================================
-- 5. Gold price and monthly sales relationship
-- ============================================

WITH transaction_totals AS (
    SELECT
        s.sale_id,
        DATE_TRUNC(
            'month',
            s.sale_date
        )::DATE AS sales_month,

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

monthly_gold_prices AS (
    SELECT
        DATE_TRUNC(
            'month',
            gp.price_date
        )::DATE AS price_month,

        AVG(gp.price_per_gram)
            AS average_24k_price_per_gram

    FROM cleaned.gold_prices AS gp

    JOIN cleaned.gold_types AS gt
        ON gp.gold_type_id = gt.gold_type_id

    WHERE gt.gold_type_name = '24K'

    GROUP BY
        DATE_TRUNC('month', gp.price_date)
),

combined_data AS (
    SELECT
        ms.sales_month,
        mgp.average_24k_price_per_gram,
        ms.net_revenue
    FROM monthly_sales AS ms

    JOIN monthly_gold_prices AS mgp
        ON ms.sales_month = mgp.price_month
),

comparison AS (
    SELECT
        *,
        LAG(average_24k_price_per_gram) OVER (
            ORDER BY sales_month
        ) AS previous_month_gold_price,

        LAG(net_revenue) OVER (
            ORDER BY sales_month
        ) AS previous_month_revenue
    FROM combined_data
)

SELECT
    sales_month,

    ROUND(
        average_24k_price_per_gram,
        2
    ) AS average_24k_price_per_gram,

    ROUND(net_revenue, 2)
        AS net_revenue,

    ROUND(
        (
            average_24k_price_per_gram
            - previous_month_gold_price
        )
        / NULLIF(previous_month_gold_price, 0)
        * 100,
        2
    ) AS gold_price_change_percentage,

    ROUND(
        (
            net_revenue
            - previous_month_revenue
        )
        / NULLIF(previous_month_revenue, 0)
        * 100,
        2
    ) AS revenue_change_percentage

FROM comparison
ORDER BY sales_month;