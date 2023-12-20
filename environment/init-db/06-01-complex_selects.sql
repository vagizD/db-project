
set search_path = credit_scheme, public;


-- insert into history_requests (request_at, request_sum, first_name, last_name, middle_name, birth_date,
--      passport, passport_issued_by, email, phone_number, country, city, address)
-- VALUES (now()::date, 6000, 'NAME1', 'NAME1', 'NAME1', '1999-10-10', '8417634900', 'DEP', 'examp@ex.com', '77777777777', 'Russia', 'City1', 'Address1'),
--        (now()::date, 6000, 'NAME2', 'NAME2', 'NAME2', '1998-9-9', '0519345700', 'DEP', 'examp@ex.com', '77777777778', 'Russia', 'City1', 'Address2');
--
-- insert into orders (request_id, client_id, issued_sum, cred_end_date, fee_percent, paid_sum, next_payment_date, is_closed, overdue_sum, issued_at)
-- values (13, '8417634900', 6000, '2024-04-20', 0.1, 2000, '2023-12-31', false, 4000, '2023-10-10'),
--        (14, '0519345700', 4500, '2024-03-20', 0.2, 500, '2023-12-28', false, 4000, '2023-10-10');
--
--
-- insert into history_payments (order_id, payment_sum_main, payment_sum_percent, payment_date)
-- VALUES (15, 1000, 123, now()::date),
--        (16, 500, 200, now()::date);
--
-- update history_payments
-- set payment_sum_percent = 321
-- where order_id = 4;
--
-- update history_payments
-- set payment_sum_percent = 121
-- where order_id = 2;

-- 1. Для каждого клиента и кредита
-- за последние 6 месяцев вывести каждую просрочку, сумму всех просрочек за кредит,
-- минимальную просрочку, отклонение от этой просрочки


select orders.client_id, orders.order_id, history_payments.payment_sum_percent,
       sum(payment_sum_percent) OVER (PARTITION BY orders.client_id range current row) as total_payment_sum_percent,
       min(payment_sum_percent) OVER (PARTITION BY orders.client_id range current row) as min_payment_sum_percent,
       payment_sum_percent - min(payment_sum_percent) OVER (PARTITION BY orders.client_id range current row) as diff_min_payment
from orders
left join history_payments on orders.order_id = history_payments.order_id
where orders.issued_at >= now()::date - interval '6 months'
order by total_payment_sum_percent DESC NULLS LAST;



-- 2. На каждого клиента вывести по всем кредитам за последние 6 месяцев
-- сумму кредитов, сумму всех платежей для каждого кредита, процент второго от первого

select client_id, orders.order_id,
       sum(issued_sum)
       OVER (PARTITION BY orders.client_id range current row) as cred_sum,
       paid_sum,
       paid_sum / sum(issued_sum)
       OVER (PARTITION BY orders.client_id range current row) * 100 as total_payments_prc
from orders
where orders.issued_at >= now()::date - interval '6 months';


-- delete from history_requests
-- where request_id in (13, 14);
--
-- delete from orders
-- where request_id in (13, 14);
--
-- delete from history_payments
-- where order_id in (15, 16);
--
-- update history_payments
-- set payment_sum_percent = 0
-- where order_id = 4;
--
-- update history_payments
-- set payment_sum_percent = 0
-- where order_id = 2;

--
--
