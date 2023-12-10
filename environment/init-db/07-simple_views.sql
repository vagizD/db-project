-- Создать по 1 представлению на каждую таблицу.
-- Все представления должны храниться в отдельной схеме с представлениями.
-- В представлениях должен быть реализован механизм маскирования персональных данных
-- и скрытия технических полей (суррогатных ключей, полей версионности и т.п.).
-- Для сокрытия полей с персональными данными недостаточно просто целиком удалить столбец с данными.
-- Например, для номера карты можно использовать маскирование вида: 4276********0000.


-- drop schema credit_views cascade;
create schema if not exists credit_views;

set search_path = credit_scheme;

-- считаю, что скрытие = не берем, маскирование - заменяем часть звёздочками

create or replace view credit_views.clients_view as
select *
from clients;

create or replace view credit_views.blacklist_view as
select *
from blacklist;

-- test
select *
from credit_views.blacklist_view;

-- truncate table clients, blacklist cascade; -- to insert data again
-- ALTER SEQUENCE blacklist_client_id_seq RESTART WITH 1;
-- ALTER SEQUENCE clients_client_id_seq RESTART WITH 1;

insert into clients
values (default, true, true),
       (default, true, true);

insert into blacklist
values (default, 'gone too late', now()),
       (default, 'gone too early', now());

-- if client_id is masked here than what's left?
select *
from credit_views.clients_view;

select *
from credit_views.blacklist_view;


-- decision_reasons_view and history_credit_history are not needed as well)
create or replace view credit_views.decision_reasons_view as
select *
from decision_reasons;

create or replace view credit_views.history_credit_history_view as
select *
from history_credit_history;

select *
from history_decisions;

insert into history_requests
values (default, now() - interval '1' day, 10000, 'Fedor', 'Kokoshkin', '-', '1234567890',
        'myself', now()::date + interval '1000' year, 'a@b.c', '12345678901', 'senegal');

insert into decision_reasons
values (default, 'named Daniil');

alter sequence history_decisions_request_id_seq restart with 1;

insert into history_decisions
values (1, 1, null, null, null, null, false, null);

select *
from credit_views.decision_reasons_view;

create or replace view credit_views.history_decisions_view as
select -- request_id omitted
       -- decision_reason_id, model_id  to
       model_score,
       scored_at,
       approved_sum,
       -- is_under,
       max_cred_end_date
--        substr(customers.name, 1, 1) || regexp_replace(substr(customers.name, 2), '\w', '*', 'g')   as masked_name,
--        substr(customers.email, 1, 1) || regexp_replace(substr(customers.email, 2), '\w', '*', 'g') as masked_email,
from history_decisions;

create or replace function mask_number(x anyelement)
    returns text as
$$
begin
    return regexp_replace(substr(x::text, 1, length(x::text) - 1), '\w', '*', 'g') ||
           substr(x::text, length(x::text));
end;
$$ language plpgsql;

create or replace view credit_views.history_payments_view as
select mask_number(payment_sum_main)    as masked_sum,
       mask_number(payment_sum_percent) as masked_percent,
       payment_date
from history_payments;

insert into orders
values (default, default, default, 1::bool, 10000, '2024-01-01', 0.2, 0, now()::date, 1::bool, 0, '2022-01-01');

insert into history_payments
values (1, 1000, 1234, now()::date - interval '1' day);

select *
from credit_views.history_payments_view;

create or replace function mask_name(nm text)
    returns text as
$$
begin
    return substr(nm, 1, 1) || regexp_replace(substr(nm, length(nm) - 2), '\w', '*', 'g') ||
           substr(nm, length(nm));
end;
$$ language plpgsql;

create or replace view credit_views.history_requests_view
as
select request_at,
       mask_number(request_sum)            as masked_requsted_sum,
       mask_name(first_name)               as masked_first_name,
       mask_name(last_name)                as masked_last_name,
       mask_name(middle_name)              as masked_middle_name,
       mask_number(passport)               as masked_passport,
       mask_name(passport_issued_by)       as masked_passport_issued_by,
       mask_number(passport_expiring_date) as masked_expiring_date,
       mask_name(email)                    as masked_email,
       mask_number(phone_number)           as masked_number,
       mask_name(address)                  as masked_address
from history_requests;

select *
from history_requests;

select *
from credit_views.history_requests_view;


create or replace view credit_views.history_verification_results_view
as
select mask_number(score) as masked_score, is_verified, verified_at
from history_verification_results;

create or replace view credit_views.models_view
as
select model_id,
       mask_number(threshold)       as masked_threshlod,
       algorithm_description,
       deployed_at,
       mask_number(traffic_percent) as masked_traffic_percent,
       model_type
from models;

create or replace view credit_views.order_view
as
select order_id,
       request_id,
       client_id,
       '*' as is_issued,
       cred_end_date,
       fee_percent,
       paid_sum,
       next_payment_date,
       '*' as order_status,
       overdue_sum,
       issued_at
from orders; -- TODO: if null then we need to mask too

create or replace view credit_views.overdue_orders_view
as
select order_id, overdue_start_date, overdue_end_date
from overdue_orders; -- TODO: date mask function