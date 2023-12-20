
set search_path = credit_scheme, public;

-- select issued_sum, total_due_sum
-- from orders
-- where order_id = 4;
--
-- update orders
-- set issued_sum = 2 * issued_sum
-- where order_id = 4;
--
-- select issued_sum, total_due_sum
-- from orders
-- where order_id = 4;


CREATE
OR REPLACE function get_ttl_due_sum(
    fee_percent numeric(4, 3),
    issued_sum numeric(19, 2),
    overdue_sum numeric(19, 2),
    issued_at date,
    cred_end_date date)
    RETURNS numeric(19, 2) AS
$$
select issued_sum;
$$
LANGUAGE sql IMMUTABLE
                STRICT;

-- UPDATE orders
-- SET issued_sum = issued_sum;
--
-- select issued_sum, total_due_sum
-- from orders
-- where order_id = 4;
