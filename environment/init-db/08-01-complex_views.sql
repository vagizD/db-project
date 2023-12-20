-- Кол-во отказанных и одобренных заявок по всем
-- возможным решениям (decision_reason_text) за последние 6 месяцев

set search_path = credit_scheme, public;

create or replace view credit_views.decisions_requests_summary as
    select
        dr.decision_text,
        count(hd.request_id) as total_requests
    from decision_reasons dr
    left join history_decisions hd
        on dr.decision_reason_id = hd.decision_reason_id
    left join history_requests hr
        on hd.request_id = hr.request_id
    group by
        dr.decision_text;

select * from credit_views.decisions_requests_summary;
