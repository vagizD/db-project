-- DROP SCHEMA credit_scheme CASCADE;

CREATE SCHEMA IF NOT EXISTS credit_scheme;

SET search_path = credit_scheme;

CREATE TABLE IF NOT EXISTS clients
(
    client_id         text check (length(client_id) = 10) primary key,
    has_active_credit boolean not null,
    -- is_first_time == true, if client has exactly 1 credit in our company, else false
    is_first_time     boolean not null
);

CREATE TABLE IF NOT EXISTS history_requests
(
    request_id             serial primary key,
    request_at             timestamp(0) not null,
    request_sum            int check (not null and request_sum >= 1000),
    first_name             text      not null,
    last_name              text      not null,
    middle_name            text      not null,
    passport               text check (length(passport) = 10), -- TODO
    passport_issued_by     text      not null,
    passport_expiring_date date check (not null and passport_expiring_date > now()::date),
    email                  text check (email like '%@%.%'),
    phone_number           text check (phone_number ~ '^\d+$' and length(phone_number) = 11),
    address                text      not null
);

CREATE TABLE IF NOT EXISTS history_verification_results
(
    request_id  integer primary key references history_requests,
    model_id    integer   not null,
    score       numeric(4, 3) check (score between 0 and 1),
    is_verified boolean   not null,
    verified_at timestamp(0) not null
);

-- before creation of history_decisions we need to create additional tables
CREATE TABLE IF NOT EXISTS decision_reasons
(
    decision_reason_id serial primary key,
    decision_text      text not null
);

CREATE TABLE IF NOT EXISTS models
(
    model_id              serial primary key,
    threshold             numeric(4, 3) check (threshold between 0 and 1),
    algorithm_description text,
    deployed_at           date not null,
    traffic_percent       numeric(4, 3) check (traffic_percent between 0 and 1),
    model_type            text check (model_type in ('verification', 'scoring'))
);


-- finally decisions
CREATE TABLE IF NOT EXISTS history_decisions
(
    request_id         serial primary key references history_requests,
    -- decision_reason_id == 0 is in blacklist
    -- decision_reason_id == 1 is client not verified
    -- decision_reason_id == 2 is scoring model did not approve
    -- decision_reason_id == 3 is business logic failed
    -- decision_reason_id == 4 is order approved
    decision_reason_id integer references decision_reasons,
    model_id           integer references models,
    model_score        numeric(4, 3) check
        (case when decision_reason_id in (0, 1) then null else model_score between 0 and 1 end),
    scored_at          timestamp(0) check
        (case when decision_reason_id in (0, 1) then null else not null end),
    approved_sum       integer check
        (case when decision_reason_id in (0, 1) then approved_sum = -1 else approved_sum >= 0 end),
    is_under           boolean not null,
    max_cred_end_date  date check (case when decision_reason_id in (0, 1, 2, 3) then null else not null end)
);

CREATE TABLE IF NOT EXISTS orders
(
    order_id          serial primary key,
    request_id        integer references history_requests,
    client_id         integer references clients,
    is_issued         boolean not null, -- flag field
    issued_sum        integer check (case when is_issued = false then null else issued_sum > 100 end),
    cred_end_date     date check (case when is_issued = false then null else not null end),
    fee_percent       numeric(4, 3) check (case when is_issued = false then null else fee_percent between 0 and 1 end),
    paid_sum          numeric(19, 2) check (case when is_issued = false then null else paid_sum >= 0 end),
    next_payment_date date check (case
                                      when is_issued = false then null
                                      else next_payment_date between issued_at and cred_end_date end),
    order_status      boolean check (case when is_issued = false then null else not null end),
    overdue_sum       numeric(19, 2) check (case when is_issued = false then null else not null end),
    issued_at         date check (case when is_issued = false then null else not null end)
);

CREATE TABLE IF NOT EXISTS history_payments
(
    order_id            serial primary key references orders,
    -- rubles, paid for main due
    payment_sum_main    double precision check (not null and payment_sum_main > 0),
    -- rubles,  paid for overdue (additional percents)
    payment_sum_percent double precision check (not null or payment_sum_percent > 0),
    payment_date        date not null
);

CREATE TABLE IF NOT EXISTS blacklist
(
    client_id    text check (length(client_id) = 10) primary key references clients,
    under_report text,
    start_date   timestamp(0) not null
);

CREATE TABLE IF NOT EXISTS overdue_orders
(
    id                 serial primary key,
    order_id           integer references history_payments,
    overdue_start_date date not null,
    overdue_end_date   date check (null or overdue_end_date >= overdue_start_date)
);

CREATE TABLE IF NOT EXISTS history_credit_history
(
    request_id         integer references history_requests,
    credit_history_xml text
);
