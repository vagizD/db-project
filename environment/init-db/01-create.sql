CREATE SCHEMA IF NOT EXISTS credit_scheme;

SET search_path = credit_scheme, public;

CREATE TABLE IF NOT EXISTS history_requests
(
    request_id             serial primary key,
    request_date           timestamp not null,
    request_sum            int check (not null and request_sum >= 1000),
    first_name             text      not null,
    last_name              text      not null,
    middle_name            text      not null,
    passport               text check (length(passport) = 10),  -- TODO
    passport_issued_by     text      not null,
    passport_expiring_date date check (not null and passport_expiring_date > now()::date),
    email                  text check (email like '%@%.%'),
    phone_number           text check (phone_number ~ '^\d+$' and length(phone_number) = 11),
    address                text      not null
);

CREATE TABLE IF NOT EXISTS history_verification_results
(
    request_id  SERIAL primary key REFERENCES history_requests,
    model_id    integer   not null,
    score       numeric(4, 3) check ( 0 <= score and score <= 1),
    is_verified boolean   not null,
    verified_at timestamp not null
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
    model_type            integer check (model_type in (0, 1))
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
    decision_reason_id serial references decision_reasons,
    model_id           serial references models,
    model_score        numeric(4, 3) check
        (case when decision_reason_id in (0, 1) then null else model_score between 0 and 1 end),
    scored_at          timestamp check
        (case when decision_reason_id in (0, 1) then null else not null end),
    is_approved        integer check
        (case when decision_reason_id in (0, 1) then -1 else is_approved in (0, 1) end),
    approved_sum       integer check
        (case when decision_reason_id in (0, 1) then approved_sum = -1 else approved_sum >= 0 end),
    is_under           boolean not null,
    -- we have credits up to 1950, so use 1900 as flag of credit absence
    max_cred_end_date  date check (max_cred_end_date = '1900.01.01'::date or max_cred_end_date > now()::date)
);

CREATE TABLE IF NOT EXISTS clients
(
    client_id         serial primary key,  -- passport
    has_active_credit boolean not null,
    is_first_time     boolean not null -- 0 if we issued exactly 1 credit to this client, 1 otherwise (>= 2)
);

CREATE TABLE IF NOT EXISTS blacklist
(
    client_id    serial primary key references clients,
    under_report text not null,
    start_date   date not null
);

CREATE TABLE IF NOT EXISTS orders
(
    order_id          serial primary key,
    request_id        serial references history_requests,
    client_id         serial references clients,
    is_issued         boolean not null,  -- flag field
    issued_sum        integer check (case when is_issued = true then null else issued_sum > 100 end),
    cred_end_date     date check (case when is_issued = true then null else not null end),
    fee_percent       numeric(4, 3) check (case when is_issued = true then null else fee_percent between 0 and 1 end),
    paid_sum          int check (case when is_issued = true then null else paid_sum >= 0 end),
    next_payment_date date check (case when is_issued = true then null
                                       else next_payment_date between issued_at and cred_end_date end),
    order_status      boolean check (case when is_issued = true then null else order_status in (0, 1, 2) end),
    overdue_sum       integer check (case when is_issued = true then null else not null end),
    issued_at         date check (case when is_issued = true then null else not null end)
);

CREATE TABLE IF NOT EXISTS history_payments
(
    order_id         serial primary key references orders,
    -- rubles, paid for main due
    payment_sum_main double precision check (not null and payment_sum_main > 0),
    -- rubles,  paid for overdue (additional percents)
    payment_sum_percent      double precision check (not null or payment_sum_percent > 0),
    payment_date     date not null
);

CREATE TABLE IF NOT EXISTS overdue_orders
(
    id                 serial primary key,
    order_id           serial references history_payments,
    overdue_start_date date not null,
    overdue_end_date   date check ( null or overdue_end_date >= overdue_start_date)
);

CREATE TABLE IF NOT EXISTS history_credit_history
(
    request_id         serial primary key references history_requests,
    credit_history_xml text
);


-- finally decisions
CREATE TABLE IF NOT EXISTS history_decisions
(
    request_id         serial primary key references history_requests,
    decision_reason_id serial references decision_reasons,
    model_id           serial references models,
    model_score        numeric(4, 3) check ( 0 <= model_score and model_score <= 1),
    scored_at          timestamp not null,
    is_approved        integer check (is_approved in (-1, 0, 1)),
    approved_sum       integer check ( approved_sum = -1 or approved_sum > 0 ),
    is_under           boolean   not null,
    max_cred_end_date  date check ( max_cred_end_date = '1970.01.01' or max_cred_end_date > now()::date)
-- or should we use timestamp? also won't this constraint end up in a mess?
);

CREATE TABLE IF NOT EXISTS clients
(
    client_id         serial primary key,
    has_active_Credit boolean not null,
    is_first_time     boolean not null -- first time, huh?:)
);

CREATE TABLE IF NOT EXISTS blacklist
(
    client_id    serial primary key references clients,
    under_report text,
    start_date   timestamp not null -- or should we use date?
);

CREATE TABLE IF NOT EXISTS orders
(
    order_id          serial primary key,
    request_id        serial references history_requests,
    client_id         serial references clients,
    is_issued         boolean not null,
    issued_sum        integer check (case when is_issued = true then null else not null end),  -- double precision isn't suitable for integer
    cred_end_date     date check (case when is_issued = true then null else not null end),
    fee_percent       numeric(4, 3) check (0 <= fee_percent and fee_percent <= 1),
    paid_sum          int check (case when is_issued = true then null else paid_sum >= 0 end), -- not just not null but >= 0 if is issued
    next_payment_date date check (case when is_issued = true then null else not null end),     -- maybe >= now()::date ?
    order_status      boolean check (case when is_issued = true then null else not null end),
    overdue_sum       integer check (case when is_issued = true then null else not null end),
    issued_at         date check (case when is_issued = true then null else not null end)      -- we could not store is_issued using as flag 1970.01.01
);

CREATE TABLE IF NOT EXISTS history_payments
(
    order_id         serial primary key references orders,
    payment_sum_main double precision check (not null and payment_sum_main > 0),
    fee_percent      double precision check (not null or fee_percent > 0), -- payment_sum_percent sounds way too bad
    payment_date     date not null
);

CREATE TABLE IF NOT EXISTS overdue_orders
(
    id                 serial primary key,
    order_id           serial references history_payments,
    overdue_start_date date not null,
    overdue_end_date   date check ( null or overdue_end_date <= now()::date)
-- this constraint will work purely, right? (as today shifts constraint will to)
);

CREATE TABLE IF NOT EXISTS history_credit_history
(
    request_id         serial primary key references history_requests,
    credit_history_xml text
);
