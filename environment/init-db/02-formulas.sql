set
    search_path = credit_scheme, public;

CREATE
    OR REPLACE function get_ttl_due_sum(
    fee_percent numeric(4, 3),
    issued_sum numeric(19, 2),
    overdue_sum numeric(19, 2),
    issued_at date,
    cred_end_date date)
    RETURNS numeric(19, 2) AS
$$
select issued_sum *
       (
           1 + fee_percent + 0.02 * greatest(
                   date_part('month', cred_end_date) - date_part('month', issued_at),
                   1)
           ) + overdue_sum;
$$ LANGUAGE sql;
