-- Создать по 1 представлению на каждую таблицу.
-- Все представления должны храниться в отдельной схеме с представлениями.
-- В представлениях должен быть реализован механизм маскирования персональных данных
-- и скрытия технических полей (суррогатных ключей, полей версионности и т.п.).
-- Для сокрытия полей с персональными данными недостаточно просто целиком удалить столбец с данными.
-- Например, для номера карты можно использовать маскирование вида: 4276********0000.


-- drop schema if exists credit_views cascade;
create schema if not exists credit_views;

set search_path = credit_scheme, public;

create or replace function credit_views.mask_number(x anyelement)
    returns text as
$$
begin
    case
        when x is null then return '****' || 0;
        else return regexp_replace(substr(x::text, 1, length(x::text) - 1), '\w', '*', 'g') ||
                    substr(x::text, length(x::text));
        end case;
end;
$$ language plpgsql;

create or replace function credit_views.mask_name(nm text)
    returns text as
$$
begin
    case
        when nm is null then return 'A' || '****' || 'a';
        else return substr(nm, 1, 1) || regexp_replace(substr(nm, length(nm) - 2), '\w', '*', 'g') ||
                    substr(nm, length(nm));
        end case;
end;
$$ language plpgsql;

create or replace function credit_views.mask_date(nm anyelement)
    returns text as
$$
begin
    case
        when nm is null then return '1999' || '*******';
        else return substr(nm::text, 1, 5) || regexp_replace(substr(nm::text, length(nm::text) - 5), '\w', '*', 'g');
        end case;
end;
$$ language plpgsql;

-- считаю, что скрытие = не берем, маскирование - заменяем часть звёздочками

create or replace view credit_views.clients_view as
select credit_views.mask_number(client_id) masked_client_id, has_active_credit, is_first_time
from clients;

create or replace view credit_views.blacklist_view as
select credit_views.mask_number(client_id)   masked_client_id,
       under_report,
       credit_views.mask_date(start_date) as masked_date
from blacklist;

-- test
select *
from credit_views.clients_view;

select *
from credit_views.blacklist_view;

-- decision_reasons_view and history_credit_history are not needed as well)
create or replace view credit_views.decision_reasons_view as
select *
from decision_reasons;

create or replace view credit_views.history_credit_history_view as
select request_id, credit_views.mask_name(credit_history_xml) as masked_credit_history_xml
from history_credit_history;

select *
from credit_views.history_credit_history_view;

select *
from credit_views.decision_reasons_view;

create or replace view credit_views.history_decisions_view as
select model_score,
       scored_at,
       approved_sum,
       max_cred_end_date
from history_decisions;

select *
from credit_views.history_decisions_view;

create or replace view credit_views.history_payments_view as
select credit_views.mask_number(payment_sum_main)    as masked_sum,
       credit_views.mask_number(payment_sum_percent) as masked_percent,
       payment_date
from history_payments;


select *
from credit_views.history_payments_view;

create or replace view credit_views.history_requests_view
as
select request_at,
       credit_views.mask_number(request_sum)      as masked_requsted_sum,
       credit_views.mask_name(first_name)         as masked_first_name,
       credit_views.mask_name(last_name)          as masked_last_name,
       credit_views.mask_name(middle_name)        as masked_middle_name,
       credit_views.mask_number(birth_date)       as masked_birth_date,
       credit_views.mask_number(passport)         as masked_passport,
       credit_views.mask_name(passport_issued_by) as masked_passport_issued_by,
       credit_views.mask_name(email)              as masked_email,
       credit_views.mask_number(phone_number)     as masked_number,
       credit_views.mask_name(country)            as masked_country,
       credit_views.mask_name(city)               as masked_city,
       credit_views.mask_name(address)            as masked_address
from history_requests;

select *
from history_requests;

select *
from credit_views.history_requests_view;


create or replace view credit_views.history_verification_results_view
as
select credit_views.mask_number(score) as masked_score, is_verified, verified_at
from history_verification_results;

select *
from credit_views.history_verification_results_view;

create or replace view credit_views.models_view
as
select model_id,
       credit_views.mask_number(threshold)       as masked_threshlod,
       algorithm_description,
       deployed_at,
       credit_views.mask_number(traffic_percent) as masked_traffic_percent,
       model_type
from models;

select *
from credit_views.models_view;

create or replace view credit_views.order_view
as
select order_id,
       request_id,
       credit_views.mask_number(client_id) as masked_client_id,
       '*'                                 as is_issued,
       cred_end_date,
       fee_percent,
       paid_sum,
       next_payment_date,
       '*'                                 as is_closed,
       overdue_sum,
       issued_at
from orders;

select *
from credit_views.order_view;

create or replace view credit_views.overdue_orders_view
as
select order_id, overdue_start_date, overdue_end_date
from overdue_orders;

select *
from credit_views.overdue_orders_view;