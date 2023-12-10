SET search_path = credit_scheme;


-- insert
insert into credit_scheme.history_requests (request_at, request_sum, first_name, last_name, middle_name, passport, passport_issued_by, passport_expiring_date, email, phone_number, address)
values
    ('2023-12-08', 1500, 'Alexey', 'Filippov', 'Fyodorovich', '1234567890', 'Passport Agency', '2025-12-31', 'affilippov@mail.com', '12345678900', 'Russia, St. Petersburg, Kantemirovskaya st., 3a building 1'),
    ('2023-12-08', 2000, 'Yuri', 'Bibikov', 'Nikolaevich', '1987654321', 'Passport Office', '2024-10-15', 'ynbibikov@mail.com', '79544438334', 'Russia, St. Petersburg, Kantemirovskaya st., 3a building 1'),
    ('2023-12-08', 3000, 'Augustin', 'Louis', 'Cauchy', '5678901234', 'Passport Service', '2026-05-20', 'ilovecalculus@mail.com', '75385920662', 'Russia, Shakhty, Vishnevaya st., 10, apt. 123'),
    ('2023-12-08', 1200, 'Vladimir', 'Basov', 'Diff', '3456789012', 'Passport Department', '2023-12-15', 'zakhodite@yandex.ru', '74986864292', 'Russia, St. Petersburg, Petrovskaya Pier'),
    ('2023-12-08', 2500, 'Sergei', 'Kryzhevich', 'Gennadievich', '4567890123', 'Passport Authority', '2025-09-30', 'sgkryzhevich@mail.com', '73511782834', 'Russia, St. Petersburg, Kantemirovskaya st., 3A building 1'),
    ('2023-12-09', 2800, 'Evgeniy', 'Sokolov', 'Evgenievich', '9876543210', 'Passport Office', '2025-11-30', 'escaos@yandex.com', '73084391903', 'Russia, Dolgoprudny, 17 September st., 7, apt. 200'),
    ('2023-12-09', 1500, 'Alexander', 'Khrabrov', 'Igorevich', '5432109876', 'Passport Agency', '2024-09-15', 'aikhrabrov@mail.com', '72387438108', 'Russia, St. Petersburg, Kantemirovskaya st., 3a building 1'),
    ('2023-12-09', 1800, 'Sergei', 'Gorikhovsky', 'Dmovich', '1234509876', 'Passport Service', '2026-08-31', 'zacofezaidu@yandex.com', '78901234567', 'Russia, Vladivostok, Verkhneportovaya st., 50a'),
    ('2023-12-09', 2200, 'Evgeniy', 'Linsky', 'Evgenievich', '7654321098', 'Passport Department', '2023-12-31', 'elinsky@mail.com', '72387438108', 'Russia, Moscow, Pochtovaya st., 7, apt. 213'),
    ('2023-12-09', 3200, 'Inga', 'Andreeva', 'Alexandrovna', '5432109877', 'Passport Authority', '2025-10-31', 'ingaingainga@mail.com', '75227031639', 'Russia, St. Petersburg, Kantemirovskaya st., 3a building 1');


insert into credit_scheme.clients (client_id, has_active_credit, is_first_time)
values
    ('1234567890', false, true),
    ('0987654321', false, true),
    ('5678901234', false, false),
    ('3456789012', false, true),
    ('4567890123', false, true),
    ('9876543210', false, false),
    ('5432109876', false, true),
    ('1234509876', false, false),
    ('7654321098', false, false),
    ('5432109877', false, true);

insert into credit_scheme.blacklist (client_id, under_report, start_date)
values
    ('3456789012', 'спам, просит всех прочитать свою книгу', now()),
    ('1234509876', 'опоздал на 50 минут', '2023-01-08'),
    ('5678901234', 'КОШИКОШИКОШИ', '1800-03-06');

-- select

-- сумма по запрашиваемым кредитам, сгруппированная по адресу прописки

select address, sum(request_sum)
from history_requests
where request_sum >= 1500
group by address
order by sum(request_sum) desc;


-- Имя и дата истечения срока паспорта тех, кто подавал заявку позже 2023-12-08

select first_name, last_name, middle_name, passport_expiring_date
from history_requests
where request_at > '2023-12-08'::date
order by passport_expiring_date desc;

-- попавшие в blacklist их адрес и причина попадания

select first_name, last_name, middle_name, under_report, address
from blacklist b
inner join history_requests hr on hr.passport = b.client_id;

-- Клиенты и сумма кредита не из черного списка с заявкой на > 2000 рублей

select passport, request_sum
from history_requests
where request_sum > 2000

except

select passport, request_sum
from blacklist b
inner join history_requests hr on hr.passport = b.client_id
order by request_sum desc;

-- update

update history_requests
set request_sum = request_sum + 1000
where address = 'Russia, St. Petersburg, Kantemirovskaya st., 3a building 1' and request_at > '2023-12-08'::date;

update history_requests
set request_sum = request_sum - 100
where request_at < now()::date and request_sum >= 1100;

update blacklist
set under_report = 'расхищал гробницы'
where under_report != 'опоздал на 50 минут';

update blacklist
set under_report = '*неактуально* ' || under_report
where start_date < now() - interval '10' year;

-- delete

delete from history_requests where request_sum < 1500;

delete from history_requests where passport_expiring_date < now();

delete from blacklist where under_report like '*неактуально* %';

delete from blacklist where start_date = now();
