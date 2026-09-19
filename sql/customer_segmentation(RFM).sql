USE olist_ecommerce;



-- Recency (most recent order per customer for all delivered orders)
SELECT 
    c.customer_unique_id,
    MAX(o.order_purchase_timestamp) AS most_recent_order,
    DATEDIFF(
        (SELECT MAX(order_purchase_timestamp) FROM olist_orders_dataset WHERE order_status = 'delivered'),
        MAX(o.order_purchase_timestamp)
    ) AS recency
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id;

-- Frequency (count of distinct delivered orders per customer )
SELECT 
    c.customer_unique_id,
    COUNT(o.order_id) AS frequency
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
ORDER BY frequency DESC;

-- Monetary (total amount spent across all delivered orders )
SELECT 
    c.customer_unique_id,
    SUM(op.payment_value) AS monetary
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
JOIN olist_order_payments_dataset op ON o.order_id = op.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id;



-- verify count of single orders vs multiple orders customers 
SELECT frequency, COUNT(*) AS num_customers
FROM (
    SELECT c.customer_unique_id, COUNT(o.order_id) AS frequency
    FROM olist_orders_dataset o
    JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
) t
GROUP BY frequency
ORDER BY frequency;



-- create a common view as single clean source for python and tableau 
CREATE VIEW vw_customer_rfm AS
WITH recency_cte AS (
    SELECT 
        c.customer_unique_id,
        DATEDIFF(
            (SELECT MAX(order_purchase_timestamp) FROM olist_orders_dataset WHERE order_status = 'delivered'),
            MAX(o.order_purchase_timestamp)
        ) AS recency
    FROM olist_orders_dataset o
    JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
frequency_cte AS (
    SELECT 
        c.customer_unique_id,
        COUNT(o.order_id) AS frequency
    FROM olist_orders_dataset o
    JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
monetary_cte AS (
    SELECT 
        c.customer_unique_id,
        SUM(op.payment_value) AS monetary
    FROM olist_orders_dataset o
    JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
    JOIN olist_order_payments_dataset op ON o.order_id = op.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT 
    r.customer_unique_id,
    r.recency,
    f.frequency,
    m.monetary
FROM recency_cte r
JOIN frequency_cte f ON r.customer_unique_id = f.customer_unique_id
JOIN monetary_cte m ON r.customer_unique_id = m.customer_unique_id;