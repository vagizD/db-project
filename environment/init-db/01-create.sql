-- DROP SCHEMA credit_scheme CASCADE;

CREATE SCHEMA IF NOT EXISTS credit_scheme;

SET search_path = credit_scheme, public;

CREATE TABLE IF NOT EXISTS history_requests
(
    request_id         serial primary key,
    request_at         timestamp(0) not null,
    request_sum        int check (not null and request_sum >= 1000),
    first_name         text         not null,
    last_name          text         not null,
    middle_name        text         not null,
    birth_date         date check (not null and birth_date <= now()::date - interval '18 years'),
    passport           text check (length(passport) = 10), -- TODO
    passport_issued_by text         not null,
    email              text check (email like '%@%.%'),
    phone_number       text check (phone_number ~ '^\d+$' and length(phone_number) = 11),
    country            text         not null,
    city               text         not null,
    address            text         not null
);

CREATE TABLE IF NOT EXISTS clients
(
    client_id         text primary key check (length(client_id) = 10),
    has_active_credit boolean not null,
    -- is_first_time == true, if client has exactly 1 credit in our company, else false
    is_first_time     boolean not null
);

CREATE TABLE IF NOT EXISTS history_verification_results
(
    request_id  integer primary key references history_requests,
    model_id    integer      not null,
    score       numeric(4, 3) check (score between 0 and 1),
    is_verified boolean      not null,
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
    -- decision_reason_id == 1 is in blacklist
    -- decision_reason_id == 2 is client not verified
    -- decision_reason_id == 3 is scoring model did not approve
    -- decision_reason_id == 4 is business logic failed
    -- decision_reason_id == 5 is order approved
    decision_reason_id integer references decision_reasons,
    model_id           integer references models,
    model_score        numeric(4, 3) check
        (case when decision_reason_id in (1, 2) then null else model_score between 0 and 1 end),
    scored_at          timestamp(0) check
        (case when decision_reason_id in (1, 2) then null else not null end),
    approved_sum       integer check
        (case when decision_reason_id in (1, 2) then approved_sum = -1 else approved_sum >= 0 end),
    is_under           boolean not null,
    max_cred_end_date  date check (case when decision_reason_id in (1, 2, 3, 4) then null else not null end)
);

CREATE OR REPLACE function get_ttl_due_sum( -- this way we'll be easily able to change generated column
    fee_percent numeric(4, 3),
    issued_sum numeric(19, 2),
    overdue_sum numeric(19, 2),
    issued_at date,
    cred_end_date date)
    RETURNS numeric(19, 2) AS
$$
select issued_sum *
       (1 + fee_percent + 0.02 * greatest(date_part('month', cred_end_date) - date_part('month', issued_at), 1)) +
       overdue_sum;
$$ LANGUAGE sql IMMUTABLE
                STRICT;

CREATE TABLE IF NOT EXISTS orders
(
    order_id          serial primary key,
    request_id        integer references history_requests,
    client_id         text references clients,
    issued_sum        integer check (issued_sum >= 1000),
    cred_end_date     date           not null,
    fee_percent       numeric(4, 3) check (fee_percent between 0 and 1),
    paid_sum          numeric(19, 2) check (paid_sum >= 0),
    next_payment_date date check (next_payment_date between issued_at and cred_end_date),
    is_closed         boolean        not null,
    overdue_sum       numeric(19, 2) not null,
    issued_at         date           not null,
    total_due_sum     numeric(19, 2) generated always as (get_ttl_due_sum(fee_percent, issued_sum, overdue_sum,
                                                                          issued_at, cred_end_date) ) stored
);

CREATE TABLE IF NOT EXISTS history_payments
(
    payment_id          serial primary key,
    order_id            integer references orders,
    -- rubles, paid for main due
    payment_sum_main    numeric(19, 2) check (not null and payment_sum_main >= 0),
    -- rubles,  paid for overdue (additional percents)
    payment_sum_percent numeric(19, 2) check (not null and payment_sum_percent >= 0),
    payment_date        date not null,
    check (payment_sum_main > 0 or payment_sum_percent > 0)
);

CREATE TABLE IF NOT EXISTS blacklist
(
    client_id    text primary key references clients,
    under_report text,
    start_date   timestamp(0) not null
);

CREATE TABLE IF NOT EXISTS overdue_orders
(
    id                 serial primary key,
    order_id           integer references orders,
    overdue_start_date date not null,
    overdue_end_date   date check (null or overdue_end_date >= overdue_start_date)
);

CREATE TABLE IF NOT EXISTS history_credit_history
(
    request_id         integer references history_requests,
    credit_history_xml text
);
