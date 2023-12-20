-- Вывести нарастающую сумму выплат по каждому клиенту за последние 6 месяцев

set search_path = credit_scheme, public;

SELECT c.client_id,
       hp.payment_sum_main,
       hp.payment_sum_percent,
       SUM(hp.payment_sum_main) OVER (PARTITION BY c.client_id ORDER BY hp.payment_date) as cumulative_sum_main,
       SUM(hp.payment_sum_percent) OVER (PARTITION BY c.client_id ORDER BY hp.payment_date) as cumulative_sum_percent,
       hp.payment_date
FROM clients c
INNER JOIN orders o
ON c.client_id = o.client_id
INNER JOIN history_payments hp
ON o.order_id = hp.order_id
WHERE hp.payment_date >= CURRENT_TIMESTAMP - INTERVAL '6 months'
ORDER BY c.client_id;

-- На каждого клиента вывести разницу между последним и предпоследним взятым кредитов
-- (и тоже самое для запрошенных кредитов)

WITH ordered_credits AS (
    SELECT ROW_NUMBER() OVER (PARTITION BY o.client_id ORDER BY o.cred_end_date DESC) AS rn,
           o.client_id AS client, o.cred_end_date,
           o.issued_sum AS last_ord_sum,
           LEAD(o.issued_sum, 1, 0) OVER (PARTITION BY o.client_id ORDER BY o.cred_end_date DESC) AS prev_ord_sum
    FROM orders o
    ),
requested_credits AS (
    SELECT ROW_NUMBER() OVER (PARTITION BY hr.passport ORDER BY hr.request_at desc) AS rn,
            hr.passport AS client, hr.request_at,
            hr.request_sum AS last_req_sum,
            LEAD(hr.request_sum, 1, 0) OVER (PARTITION BY hr.passport ORDER BY hr.request_at desc) AS prev_req_sum
    FROM history_requests hr
)
SELECT oc.client,
       oc.last_ord_sum,
       oc.prev_ord_sum,
       ABS(oc.last_ord_sum - oc.prev_ord_sum) as ord_sum_diff,
       rc.last_req_sum,
       rc.prev_req_sum,
       ABS(rc.last_req_sum - rc.prev_req_sum) as req_sum_diff
FROM ordered_credits oc
INNER JOIN requested_credits rc
ON oc.client = rc.client
WHERE oc.rn = rc.rn AND oc.rn = 1;

-- Для каждого города вывести сумму всех выплат по этому городу, а также процент от суммы по всем городам

WITH sum_by_cities AS (
    SELECT hr.city,
           coalesce(sum(payments.total_amt), 0) as total_amt
    FROM history_requests hr
    LEFT JOIN (
        SELECT o.request_id,
               SUM(hp.payment_sum_main + hp.payment_sum_percent) as total_amt
        FROM orders o
        INNER JOIN history_payments hp
        ON o.order_id = hp.order_id
        GROUP BY o.request_id
    ) as payments
    ON hr.request_id = payments.request_id
    GROUP BY hr.city
)
SELECT sbc.city,
       sbc.total_amt,
       ROUND((sbc.total_amt / greatest(SUM(sbc.total_amt) OVER(), 1)) * 100::numeric(19, 2), 3) as percentage_of_total_sum
FROM sum_by_cities as sbc;
