-- 3. Сводка по моделям:
-- * для каждой модели для всех одобренных но не выданных кредитов  type 1
-- * для каждой модели для всех выданных кредитов                   type 2
-- * для каждой модели для всех отказанных нами                     type 3
--
--  средняя запрошенная сумма, средняя одобренная сумма, разница средних,
--  средний одобренный период

set search_path = credit_scheme, public;


create or replace view models_info as
    select 1 as type, model_id, avg(request_sum) as avg_request_sum, avg(approved_sum) as avg_approved_sum, avg(request_sum) - avg(approved_sum) as diff_avg_req_app_sum,
    avg(extract(year from age(max_cred_end_date, scored_at))*12 + extract(month from age(max_cred_end_date, scored_at))) as avg_end_date
    from history_decisions
    inner join (select history_decisions.request_id
    from history_decisions

    EXCEPT

    select orders.request_id
    from history_decisions
    inner join orders on history_decisions.request_id = orders.request_id) as tbl1 on history_decisions.request_id = tbl1.request_id
    inner join history_requests on history_requests.request_id = history_decisions.request_id
    where approved_sum != -1
    group by model_id, type

    UNION

    select 2 as type, model_id, avg(request_sum) as avg_request_sum, avg(approved_sum) as avg_approved_sum, avg(request_sum) - avg(approved_sum) as diff_avg_req_app_sum,
    avg(extract(year from age(max_cred_end_date, scored_at))*12 + extract(month from age(max_cred_end_date, scored_at))) as avg_end_date
    from history_decisions
    inner join history_requests on history_requests.request_id = history_decisions.request_id
    inner join orders on history_decisions.request_id = orders.request_id
    group by model_id, type

    UNION

    select 3 as type, model_id, avg(request_sum) as avg_request_sum, 0 as avg_approved_sum, avg(request_sum) as diff_avg_req_app_sum,
    0 as avg_end_date
    from history_decisions
    inner join  history_requests on history_requests.request_id = history_decisions.request_id
    where approved_sum = -1
    group by model_id, type
    order by type;
