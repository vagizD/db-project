-- Статистика по городам: средняя выданная сумма, медианная выданная сумма,
-- разница сумм выданных кредитов между прошлым и настоящим месяцем, средний платеж,
-- медианный платеж, разница сумм всех платежей между прошлым и настоящим месяцем.

SET search_path = credit_scheme, public;

CREATE OR REPLACE VIEW credit_views.stats_by_cities AS
    WITH orders_data AS (
    SELECT hr.city,
           COALESCE(ROUND(AVG(o.issued_sum), 3), 0) AS avg_issued_sum,
           COALESCE(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY o.issued_sum), 0) AS median_issued_sum,
           ABS(
                SUM(CASE
                    WHEN EXTRACT(MONTH FROM o.issued_at) = EXTRACT(MONTH FROM CURRENT_DATE)
                    THEN o.issued_sum
                    ELSE 0
                    END
                ) -
                SUM(CASE
                    WHEN extract(MONTH FROM o.issued_at) = EXTRACT(MONTH FROM CURRENT_DATE - INTERVAL '1 month')
                    THEN o.issued_sum
                    ELSE 0
                    END
                )
           ) AS issued_sum_diff
    FROM history_requests hr
    LEFT JOIN orders o
    ON hr.request_id = o.request_id
    GROUP BY hr.city
    ),
    payments_data AS (
    SELECT hr.city,
           COALESCE(ROUND(AVG(hp.payment_sum_main + hp.payment_sum_percent), 3), 0) AS average_payment_sum,
           COALESCE(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY (hp.payment_sum_main + hp.payment_sum_percent)), 0) AS median_payment_sum,
           ABS(
               SUM(CASE
                   WHEN EXTRACT(MONTH FROM hp.payment_date) = EXTRACT(MONTH FROM CURRENT_DATE)
                   THEN hp.payment_sum_main + hp.payment_sum_percent
                   ELSE 0
                   END
               ) -
               SUM(CASE
                   WHEN EXTRACT(MONTH FROM hp.payment_date) = EXTRACT(MONTH FROM CURRENT_DATE - INTERVAL '1 month')
                   THEN hp.payment_sum_main + hp.payment_sum_percent
                   ELSE 0
                   END
               )
           ) AS payment_sum_diff
    FROM history_requests hr
    LEFT JOIN orders o
    ON hr.request_id = o.request_id
    LEFT JOIN history_payments hp
    ON hp.order_id = o.order_id
    GROUP BY hr.city
)
SELECT od.city,
       od.avg_issued_sum,
       od.median_issued_sum,
       od.issued_sum_diff,
       pd.average_payment_sum,
       pd.median_payment_sum,
       pd.payment_sum_diff
FROM orders_data od
INNER JOIN payments_data pd
ON od.city = pd.city;

SELECT * FROM credit_views.stats_by_cities;