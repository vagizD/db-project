
-- На каждую вставку в orders
-- проверять, что человек уже в клиентах,
-- если да, тогда меняем has_active_credit = True,
-- если нет - вставим его в таблицу clients

set search_path = credit_scheme, public;

create or replace function new_order_check()
    returns trigger as
    $$
    begin
        if exists (select client_id
                   from credit_scheme.clients
                   where client_id = new.client_id)
        then
            update credit_scheme.clients
            set has_active_credit = true
            where client_id = new.client_id;
        else
            insert into credit_scheme.clients (client_id, has_active_credit, is_first_time)
            values (new.client_id, true, true);
        end if;
    return new;
    end;
    $$ language plpgsql;

create or replace trigger update_active_credit_status
    before insert on orders for each row
    execute function new_order_check();
