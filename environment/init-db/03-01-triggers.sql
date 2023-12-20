
set search_path = credit_scheme, public;

-- На входящий платеж:
-- 1. Обновляется поле paid_sum по кредиту.
-- 2. Если этим платежем клиент погасил кредит, статус кредита (is_closed)
-- и наличие активного кредита у клиента (has_active_credit) изменяются.

CREATE
    OR REPLACE PROCEDURE close_and_remove_active_credit(order_id_ integer)
    LANGUAGE sql AS
$$
    UPDATE credit_scheme.orders o
    SET is_closed = True
    WHERE o.order_id = order_id_;

    UPDATE credit_scheme.clients c
    SET has_active_credit = False,
        is_first_time     = False
    WHERE c.client_id = (SELECT client_id
                         FROM credit_scheme.orders o
                         WHERE o.order_id = order_id_);
$$;

CREATE
    OR REPLACE PROCEDURE update_paid_sum(order_id_ integer,
                                         payment_sum numeric(19, 2))
    LANGUAGE sql AS
$$
    UPDATE credit_scheme.orders o
    SET paid_sum = o.paid_sum + payment_sum
    WHERE o.order_id = order_id_;
$$;

CREATE
    OR REPLACE FUNCTION new_payment_check()
    RETURNS trigger AS
$func$
BEGIN
    IF
        (SELECT is_closed
         FROM credit_scheme.orders o
         WHERE o.order_id = NEW.order_id) = True
    THEN
        RAISE EXCEPTION 'Credit is already closed.';
    END IF;

    CALL credit_scheme.update_paid_sum(NEW.order_id,
                         NEW.payment_sum_main + NEW.payment_sum_percent);

    IF
        (SELECT total_due_sum - paid_sum as amt_left
         FROM credit_scheme.orders o
         WHERE o.order_id = NEW.order_id)
            <= 0.0
    THEN
        CALL credit_scheme.close_and_remove_active_credit(NEW.order_id);
    END IF;

    RETURN NEW;
END;
$func$
    LANGUAGE plpgsql;

CREATE TRIGGER payment_check
    AFTER INSERT
    ON history_payments
    FOR EACH ROW
EXECUTE PROCEDURE new_payment_check();