update orders -- so we have anything to choose (comment this query later)
set cred_end_date     = current_date + interval '1' year,
    next_payment_date = current_date - interval '1' day
where order_id <= 2
  and is_closed = false;

create or replace function check_overdues() returns void as
$$
begin
    insert into overdue_orders(order_id, overdue_start_date)
    select order_id, current_date
    from (select o.order_id as order_id,
                 paid_sum,
                 issued_at,
                 fee_percent,
                 issued_sum,
                 overdue_sum
          from orders o
                   left join overdue_orders ov on o.order_id = ov.order_id
          where is_closed = false
            and next_payment_date = current_date - interval '1' day
            and (overdue_end_date is not null
              or (overdue_start_date is null and overdue_end_date is null))
          group by o.order_id, issued_at, paid_sum) possible_overdues
    where (select get_ttl_due_sum(fee_percent, issued_sum, overdue_sum, issued_at, current_date) - paid_sum) > 0;
end;
$$ language plpgsql;

create or replace function penalty() returns void as
$$
begin
    update orders
    set overdue_sum = overdue_sum +
                      0.05 * get_ttl_due_sum(fee_percent, issued_sum, overdue_sum, issued_at, cred_end_date) /
                      date_part('month', cred_end_date) - date_part('month', issued_at)
    where (orders.order_id = any (select o.order_id
                                  from overdue_orders ov
                                           inner join orders o on ov.order_id = o.order_id
                                  where overdue_end_date is null));
end;
$$
    language plpgsql;

select *
from check_overdues();

select *
from penalty();