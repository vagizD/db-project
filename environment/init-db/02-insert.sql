set search_path = credit_scheme, public;

select *
from history_requests;

--this works
insert into history_requests
values (DEFAULT, now(), 1000, 'Daniil', 'Martsenyuk', 'Bibikov', '132323', now() - interval '10' day,
        now() + interval '10' day,
        'danila@mail.ruu', '1234567890', 'address');

-- this doesn't cause of requested sum, email constraints, passport expiring date etc
-- insert into history_requests
-- values (DEFAULT, now()::date, 100, 'Daniil', 'M', 'B', '132323', now()::date - 10, now()::date + 10,
--         'danila@mail.ruu', '1234567890', 'address');

insert into history_requests
values (DEFAULT, now()::date, 1009, 'Daniil', 'M', 'B', '132323', now()::date - 10, now()::date + 10,
        'danilamail.ruu', '1234567890', 'address');

insert into history_requests
values (DEFAULT, now()::date, 1001, 'Daniil', 'M', 'B', '132323', now()::date - 10, now()::date,
        'danila@mail.ruu', '1234567890', 'address');

insert into history_verification_results
values (DEFAULT, 1, 0.2323, false, now());

-- this won't work because there exists only one row in history requests
insert into history_verification_results
values (DEFAULT, 1, 0.565231, true, now());


select *
from history_verification_results;

select *
from history_requests;

insert into decision_reasons
values (default, 'пошел на матан');

--works
insert into models
values (default, 0.234, '', now() - interval '1' year, 0.1, 1);

-- doesn't
-- insert into models
-- values (default, 0.234, '', now() - interval '1' year, 1.1, 1);