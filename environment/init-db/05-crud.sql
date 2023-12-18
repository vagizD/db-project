
SET search_path = credit_scheme, public;

-- select

-- сумма по запрашиваемым кредитам, сгруппированная по городу

select city, sum(request_sum)
from history_requests
where request_sum >= 1500
group by city
order by sum(request_sum) desc;


-- Имя и дата рождения тех, кто подавал заявку позже 2023-12-08

select first_name, last_name, middle_name, birth_date
from history_requests
where request_at > '2023-12-08'::date
order by birth_date desc;

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
set passport_issued_by = 'New Department'
where country = 'Russia' and city = 'St. Petersburg' and address = 'Kantemirovskaya st., 3a building 1' and request_at > '2023-12-08'::date;

update blacklist
set under_report = 'расхищал гробницы'
where under_report != 'опоздал на 50 минут';

update blacklist
set under_report = '*неактуально* ' || under_report
where start_date < now() - interval '10' year;

-- delete

delete from history_requests where request_sum < 1500;

delete from history_requests where birth_date < '1945-01-1'::date;

delete from blacklist where under_report like '*неактуально* %';

delete from blacklist where start_date::date = now()::date;
