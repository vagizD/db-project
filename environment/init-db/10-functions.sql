set search_path = credit_scheme, public;

-- testing purposes
update orders
set cred_end_date     = current_date + interval '6' month,
    next_payment_date = current_date - interval '1' day
where order_id <= 2
  and is_closed = false;

create or replace function check_overdues() returns void as
$$
begin
    insert into overdue_orders(order_id, overdue_start_date)
    select order_id, current_date
    from (select o.order_id                      as order_id,
                 paid_sum,
                 issued_at,
                 total_due_sum,
                 cred_end_date,
                 (date_part('month', current_date) -
                  date_part('month', issued_at)) as months_passed,
                 greatest(date_part('month', cred_end_date) -
                          date_part('month', issued_at),
                          1)                     as n_months
          from orders o
                   left join overdue_orders ov on o.order_id = ov.order_id
          where is_closed = false
            and next_payment_date = current_date - interval '1' day
            and (
              overdue_end_date is not null
                  or
              (overdue_start_date is null and overdue_end_date is null)
              )
          group by o.order_id, issued_at, paid_sum) possible_overdues
    -- current paid_sum < required paid_sum
    where total_due_sum * (months_passed / n_months) > paid_sum;
end;
$$ language plpgsql;

create or replace function penalty() returns void as
$$
begin
    update orders o
    set overdue_sum = overdue_sum +
                      0.05 * total_due_sum /
                      greatest(
                              date_part('month', cred_end_date) - date_part('month', issued_at),
                              1)
    where (o.order_id in (select distinct o.order_id
                          from overdue_orders ov
                                   inner join orders o
                                              on ov.order_id = o.order_id
                          where overdue_end_date is null));
end;
$$
    language plpgsql;

select *
from check_overdues();

select *
from penalty();

select *
from orders;