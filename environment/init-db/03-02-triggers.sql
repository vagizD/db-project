
set search_path = credit_scheme, public;

-- На каждую вставку в orders
-- проверять, что человек уже в клиентах,
-- если да, тогда меняем has_active_credit = True,
-- если нет - вставим его в таблицу clients


create or replace function new_order_check()
    returns trigger as
    $$
    begin
        if (select client_id
            from clients
            where client_id = new.client_id) is not null
        then
            update clients
            set has_active_credit = true
            where client_id = new.client_id;
        else
            insert into clients (client_id, has_active_credit, is_first_time)
            values (new.client_id, true, true);
        end if;
    return new;
    end;
    $$ language plpgsql;

create or replace trigger update_active_credit_status
    before insert on orders for each row
    execute function new_order_check();
