-- ============================================
-- 1. Registered customer KPIs
-- ============================================

WITH transaction_totals AS (
    SELECT
        s.sale_id,
        s.customer_id,
        SUM(si.quantity * si.unit_price)
            - s.discount_amount AS net_revenue
    FROM cleaned.sales AS s
    JOIN cleaned.sale_items AS si
        ON s.sale_id = si.sale_id
    WHERE s.customer_id IS NOT NULL
    GROUP BY
        s.sale_id,
        s.customer_id,
        s.discount_amount
),

customer_summary AS (
    SELECT
        customer_id,
        COUNT(*) AS purchase_count,
        SUM(net_revenue) AS total_spent
    FROM transaction_totals
    GROUP BY customer_id
)

SELECT
    COUNT(*) AS customers_with_purchases,

    COUNT(*) FILTER (
        WHERE purchase_count = 1
    ) AS one_time_customers,

    COUNT(*) FILTER (
        WHERE purchase_count > 1
    ) AS repeat_customers,

    ROUND(
        COUNT(*) FILTER (
            WHERE purchase_count > 1
        ) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS repeat_customer_percentage,

    ROUND(AVG(total_spent), 2)
        AS average_customer_value,

    ROUND(SUM(total_spent), 2)
        AS registered_customer_revenue

FROM customer_summary;

-- ============================================
-- 2. Top 20 customers by total spending
-- ============================================

WITH reference_date AS (
    SELECT
        MAX(sale_date::DATE) AS analysis_date
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

customer_summary AS (
    SELECT
        customer_id,
        COUNT(*) AS purchase_count,
        MAX(sale_date) AS last_purchase_date,
        SUM(net_revenue) AS total_spent,
        AVG(net_revenue) AS average_transaction_value
    FROM transaction_totals
    GROUP BY customer_id
)

SELECT
    c.customer_id,
    c.customer_name,
    COALESCE(c.city, 'Unknown') AS city,
    cs.purchase_count,
    cs.last_purchase_date,
    r.analysis_date - cs.last_purchase_date
        AS days_since_last_purchase,
    ROUND(cs.total_spent, 2) AS total_spent,
    ROUND(
        cs.average_transaction_value,
        2
    ) AS average_transaction_value

FROM customer_summary AS cs

JOIN cleaned.customers AS c
    ON cs.customer_id = c.customer_id

CROSS JOIN reference_date AS r

ORDER BY cs.total_spent DESC
LIMIT 20;

-- ============================================
-- 3. Customer purchase-frequency groups
-- ============================================

WITH customer_purchases AS (
    SELECT
        customer_id,
        COUNT(*) AS purchase_count
    FROM cleaned.sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
)

SELECT
    CASE
        WHEN purchase_count = 1 THEN 'One-time Customer'
        WHEN purchase_count BETWEEN 2 AND 5 THEN 'Occasional Customer'
        WHEN purchase_count BETWEEN 6 AND 10 THEN 'Regular Customer'
        ELSE 'Frequent Customer'
    END AS customer_group,
    COUNT(*) AS customer_count
FROM customer_purchases
GROUP BY customer_group
ORDER BY customer_count DESC;

-- ============================================
-- 4. Customer revenue by city
-- ============================================

WITH transaction_totals AS (
    SELECT
        s.sale_id,
        s.customer_id,
        SUM(si.quantity * si.unit_price)
            - s.discount_amount AS net_revenue
    FROM cleaned.sales AS s
    JOIN cleaned.sale_items AS si
        ON s.sale_id = si.sale_id
    WHERE s.customer_id IS NOT NULL
    GROUP BY
        s.sale_id,
        s.customer_id,
        s.discount_amount
)

SELECT
    COALESCE(c.city, 'Unknown') AS city,
    COUNT(DISTINCT c.customer_id) AS purchasing_customers,
    COUNT(tt.sale_id) AS transaction_count,
    ROUND(SUM(tt.net_revenue), 2) AS net_revenue,
    ROUND(AVG(tt.net_revenue), 2)
        AS average_transaction_value
FROM transaction_totals AS tt
JOIN cleaned.customers AS c
    ON tt.customer_id = c.customer_id
GROUP BY COALESCE(c.city, 'Unknown')
ORDER BY net_revenue DESC;

-- ============================================
-- 5. Valuable inactive customers
-- ============================================

WITH reference_date AS (
    SELECT
        MAX(sale_date::DATE) AS analysis_date
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

customer_summary AS (
    SELECT
        customer_id,
        MAX(sale_date) AS last_purchase_date,
        COUNT(*) AS purchase_count,
        SUM(net_revenue) AS total_spent
    FROM transaction_totals
    GROUP BY customer_id
)

SELECT
    c.customer_id,
    c.customer_name,
    COALESCE(c.city, 'Unknown') AS city,
    cs.purchase_count,
    cs.last_purchase_date,
    r.analysis_date - cs.last_purchase_date
        AS days_inactive,
    ROUND(cs.total_spent, 2) AS total_spent
FROM customer_summary AS cs
JOIN cleaned.customers AS c
    ON cs.customer_id = c.customer_id
CROSS JOIN reference_date AS r
WHERE r.analysis_date - cs.last_purchase_date > 180
ORDER BY cs.total_spent DESC
LIMIT 20;

-- ============================================
-- 6. Monthly new vs returning customers
-- ============================================

WITH customer_first_purchase AS (
    SELECT
        customer_id,
        DATE_TRUNC(
            'month',
            MIN(sale_date)
        )::DATE AS first_purchase_month
    FROM cleaned.sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
),

monthly_customer_activity AS (
    SELECT DISTINCT
        s.customer_id,
        DATE_TRUNC(
            'month',
            s.sale_date
        )::DATE AS sales_month
    FROM cleaned.sales AS s
    WHERE s.customer_id IS NOT NULL
)

SELECT
    mca.sales_month,

    COUNT(*) FILTER (
        WHERE mca.sales_month =
              cfp.first_purchase_month
    ) AS new_customers,

    COUNT(*) FILTER (
        WHERE mca.sales_month >
              cfp.first_purchase_month
    ) AS returning_customers,

    COUNT(*) AS active_customers

FROM monthly_customer_activity AS mca

JOIN customer_first_purchase AS cfp
    ON mca.customer_id = cfp.customer_id

GROUP BY mca.sales_month
ORDER BY mca.sales_month;

-- ============================================
-- 7. RFM customer scoring
-- ============================================

WITH reference_date AS (
    SELECT
        MAX(sale_date::DATE) + 1
            AS analysis_date
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
        SUM(tt.net_revenue) AS monetary_value
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
    ROUND(r.monetary_value, 2)
        AS monetary_value,
    r.recency_score,
    r.frequency_score,
    r.monetary_score

FROM rfm_scores AS r

JOIN cleaned.customers AS c
    ON r.customer_id = c.customer_id

ORDER BY
    r.monetary_score DESC,
    r.frequency_score DESC,
    r.recency_score DESC;

-- ============================================
-- 8. RFM customer segment distribution
-- ============================================

WITH reference_date AS (
    SELECT
        MAX(sale_date::DATE) + 1
            AS analysis_date
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
        SUM(tt.net_revenue) AS monetary_value
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
),

customer_segments AS (
    SELECT
        *,
        CASE
            WHEN recency_score >= 4
                 AND frequency_score >= 4
                 AND monetary_score >= 4
                THEN 'Champions'

            WHEN recency_score <= 2
                 AND frequency_score >= 3
                THEN 'At Risk'

            WHEN recency_score >= 4
                 AND frequency = 1
                THEN 'New Customers'

            WHEN frequency_score >= 4
                 AND monetary_score >= 3
                THEN 'Loyal Customers'

            WHEN recency_score >= 4
                 AND frequency_score BETWEEN 2 AND 3
                THEN 'Potential Loyalists'

            WHEN recency_score <= 2
                 AND frequency_score <= 2
                THEN 'Hibernating'

            ELSE 'Needs Attention'
        END AS customer_segment

    FROM rfm_scores
)

SELECT
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(
        COUNT(*) * 100.0
        / SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage,
    ROUND(
        SUM(monetary_value),
        2
    ) AS segment_revenue,
    ROUND(
        AVG(monetary_value),
        2
    ) AS average_customer_value

FROM customer_segments

GROUP BY customer_segment
ORDER BY segment_revenue DESC;