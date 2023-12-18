-- Заполнить БД данными (по 5–10 записей в каждую таблицу). Для заполнения можно
-- использовать как INSERT (минимум по 1 строке в каждую таблицу), так и внешние
-- источники данных (XLS, CSV).

SET search_path = credit_scheme, public;

-- models
INSERT INTO models
(threshold, algorithm_description, deployed_at, traffic_percent, model_type)
VALUES (0.370, 'GradBoost v1', '2023-01-10', 0.776, 'verification'),
       (0.412, 'CatBoost v1', '2023-01-03', 0.681, 'scoring'),
       (0.561, 'AdaBoost v1', '2023-04-12', 0.705, 'verification'),
       (0.509, 'GradBoost v2', '2023-04-30', 0.691, 'verification'),
       (0.611, 'CatBoost v2', '2023-06-01', 0.817, 'scoring');

-- history_requests
INSERT INTO history_requests
(request_at, request_sum, first_name, last_name, middle_name, birth_date,
 passport, passport_issued_by, email, phone_number, country, city, address)
VALUES ('2023-01-17 15:32:04', 32000, 'Иван', 'Иванов', 'Неиванович', '1999-05-18',
        '8415341288', 'МФЦ Алтайского Края', 'ivanov@yandex.ru', '72663767143', 'Лалаленд', 'КАЗАХСТАН',
        'ул. Примерная, д. 3'),
       ('2023-03-12 22:39:00', 17550, 'Мария', 'Петрова', 'Александровна', '1988-01-05',
        '4108551337', 'МВД России по Московскому району', 'mari.petrova@mail.ru', '77302561558', 'Лалаленд2', 'ойбой',
        'пр. Образцовый, д. 35а'),
       ('2023-04-04 08:51:54', 5600, 'Алексей', 'Сидоров', 'Николаевич', '2000-10-29',
        '0820228228', 'УМВД Приморского края', 'alex.ninja@gmail.com', '73705435023', 'Типостан', 'Типобург',
        'ул. Типовая, д. 93к2'),
       ('2023-05-25 13:14:07', 44370, 'Елена', 'Козлова', 'Сергеевна', '1997-12-23',
        '8417634900', 'МФЦ Алтайского Края', 'helen97@yandex.ru', '72663859943', 'Лалаленд', 'КАЗАХСТАН',
        'ул. Стандартная, д. 15'),
       ('2023-06-17 15:32:04', 32000, 'Дмитрий', 'Васильев', 'Дмитриевич', '1979-08-09',
        '4119559372', 'МФЦ Ясеневского района', 'dmitry.dadaya@rambler.ru', '70728969901', 'Лалаленд', 'КАЗАХСТАН',
        'ул. Колотушника, д. Пушкина'),
       ('2023-07-30 01:14:07', 100000, 'Захар', 'Кондауров', 'Дадаон', '2003-08-19',
        '1419635900', 'УМВД Псковской области', 'zahar.otec@edu.hse.ru', '79505353535', 'Лалаленд', 'КАЗАХСТАН',
        'ул. Кантемировская, д. 101'),
       ('2023-08-01 05:18:57', 5000, 'Микро', 'Кидала', 'Один', '1999-05-12',
        '0519345700', 'УМВД Кидал', 'scammer228@mail.ru', '79941011133', 'Лалаленд2', 'ойбой', 'ул. Кукушкина, д. 51'),
       ('2023-08-02 06:18:57', 5000, 'Микро', 'Кидала', 'Два', '1990-06-12',
        '0510123456', 'УМВД Кидал', 'scammer1337@mail.ru', '79943453455', 'Лалаленд2', 'ойбой', 'ул. Кукушкина, д. 51'),
       ('2023-08-03 07:18:57', 5000, 'Микро', 'Кидала', 'Три', '2000-07-12',
        '0520375677', 'УМВД Кидал', 'scammer1448@mail.ru', '79941084329', 'Лалаленд2', 'ойбой', 'ул. Кукушкина, д. 51');
-- -- insert
-- INSERT INTO history_requests
--     (request_at, request_sum, first_name, last_name, middle_name, passport, passport_issued_by, birth_date, email, phone_number, country, city, address)
-- VALUES
--     ('2023-12-08', 1500, 'Alexey', 'Filippov', 'Fyodorovich', '1234567890', 'Passport Agency', '1949-12-31', 'affilippov@mail.com', '12345678900', 'Russia', 'St. Petersburg', 'Kantemirovskaya st., 3a building 1'),
--     ('2023-12-08', 2000, 'Yuri', 'Bibikov', 'Nikolaevich', '1987654321', 'Passport Office', '1950-10-15', 'ynbibikov@mail.com', '79544438334', 'Russia', 'St. Petersburg', 'Kantemirovskaya st., 3a building 1'),
--     ('2023-12-08', 3000, 'Augustin', 'Louis', 'Cauchy', '5678901234', 'Passport Service', '1800-05-20', 'ilovecalculus@mail.com', '75385920662', 'Russia', 'Shakhty', 'Vishnevaya st., 10, apt. 123'),
--     ('2023-12-08', 1200, 'Vladimir', 'Basov', 'Diff', '3456789012', 'Passport Department', '546-12-15', 'zakhodite@yandex.ru', '74986864292', 'Russia', 'St. Petersburg', 'Petrovskaya Pier'),
--     ('2023-12-08', 2500, 'Sergei', 'Kryzhevich', 'Gennadievich', '4567890123', 'Passport Authority', '1964-09-30', 'sgkryzhevich@mail.com', '73511782834', 'Russia', 'St. Petersburg', 'Kantemirovskaya st., 3A building 1'),
--     ('2023-12-09', 2800, 'Evgeniy', 'Sokolov', 'Evgenievich', '9876543210', 'Passport Office', '1984-11-30', 'escaos@yandex.com', '73084391903', 'Russia', 'Dolgoprudny', '17 September st., 7, apt. 200'),
--     ('2023-12-09', 1500, 'Alexander', 'Khrabrov', 'Igorevich', '5432109876', 'Passport Agency', '1969-09-15', 'aikhrabrov@mail.com', '72387438108', 'Russia', 'St. Petersburg', 'Kantemirovskaya st., 3a building 1'),
--     ('2023-12-09', 1800, 'Sergei', 'Gorikhovsky', 'Dmovich', '1234509876', 'Passport Service', '1984-08-31', 'zacofezaidu@yandex.com', '78901234567', 'Russia', 'Vladivostok', 'Verkhneportovaya st., 50a'),
--     ('2023-12-09', 2200, 'Evgeniy', 'Linsky', 'Evgenievich', '7654321098', 'Passport Department', '1979-12-31', 'elinsky@mail.com', '72387438108', 'Russia', 'Moscow', 'Pochtovaya st., 7, apt. 213'),
--     ('2023-12-09', 3200, 'Inga', 'Andreeva', 'Alexandrovna', '5432109877', 'Passport Authority', '1985-10-31', 'ingaingainga@mail.com', '75227031639', 'Russia', 'St. Petersburg', 'Kantemirovskaya st., 3a building 1');

-- history_verification_results
INSERT INTO history_verification_results
    (request_id, model_id, score, is_verified, verified_at)
VALUES (1, 1, 0.542, true, '2023-01-18 09:12:54'),
       (2, 1, 0.609, true, '2023-03-12 23:49:15'),
       (3, 1, 0.228, false, '2023-04-05 18:42:00'),
       (4, 4, 0.550, true, '2023-05-25 22:12:15'),
       (5, 4, 0.649, true, '2023-06-19 17:33:34'),
       (6, 4, 0.755, true, '2023-08-01 05:55:31'),
       (7, 4, 0.612, true, '2023-08-03 21:41:44'),
       (8, 4, 0.951, true, '2023-08-05 15:39:01'),
       (9, 4, 0.701, true, '2023-08-06 02:11:55');

-- decision_reasons
INSERT INTO decision_reasons
    (decision_text)
VALUES ('В черном списке'),
       ('Не одобрен верификационной моделью'),
       ('Не одобрен скоринговой моделью'),
       ('Не одобрен бизнес логикой'),
       ('Кредит одобрен');

-- history_decisions
INSERT INTO history_decisions
(request_id, decision_reason_id, model_id, model_score, scored_at, approved_sum, is_under, max_cred_end_date)
VALUES (1, 5, 2, 0.551, '2023-01-20 16:20:21', 18500, false, '2023-04-20 23:59:00'),
       (2, 5, 2, 0.696, '2023-03-14 10:19:05', 14000, false, '2023-05-14 23:59:00'),
       (3, 2, 1, null, null, -1, false, null),
       (4, 5, 2, 0.408, '2023-05-28 15:00:53', 21500, true, '2023-07-28 23:59:59'),
       (5, 5, 5, 0.719, '2023-06-21 05:52:09', 30000, false, '2023-10-21 23:59:59'),
       (6, 5, 5, 1.000, '2023-08-03 13:51:10', 100000, false, '2023-12-03 23:59:59'),
       (7, 5, 5, 0.600, '2023-08-06 13:14:15', 3210, true, '2023-09-06 23:59:59'),
       (8, 5, 5, 0.700, '2023-08-08 10:34:41', 4300, false, '2023-09-08 23:59:59'),
       (9, 5, 5, 0.650, '2023-08-09 23:15:01', 3780, false, '2023-09-09 23:59:59');

-- clients
INSERT INTO clients
    (client_id, has_active_credit, is_first_time)
VALUES ('8415341288', true, true),
       ('4108551337', true, true),
       ('8417634900', true, true),
       ('4119559372', true, true),
       ('1419635900', true, true),
       ('0519345700', true, true),
       ('0510123456', true, true),
       ('0520375677', true, true);

-- blacklist
INSERT INTO blacklist
    (client_id, under_report, start_date)
VALUES ('0519345700', 'Скамер', '2023-08-10'),
       ('0510123456', 'Скамер', '2023-08-10'),
       ('0520375677', 'Скамер', '2023-08-10'),
       ('1419635900', 'Многократная просрочка', '2023-10-03'),
       ('8417634900', 'Многократная просрочка', '2023-07-28');

-- orders
INSERT INTO orders
(request_id, client_id, issued_sum, cred_end_date, fee_percent,
 paid_sum, next_payment_date, is_closed, overdue_sum, issued_at)
VALUES (1, '8415341288', 18500, '2023-04-20', 0.25, 0, '2023-02-20', false, 0, '2023-01-20'),
       (4, '8417634900', 18000, '2023-10-21', 0.25, 0, '2023-08-21', false, 0, '2023-06-21'),
       (6, '1419635900', 90000, '2023-12-03', 0.23, 0, '2023-11-03', false, 0, '2023-08-03'),
       (7, '0519345700', 5000, '2023-09-06', 0.30, 0, '2023-08-06', false, 0, '2023-08-06'),
       (8, '0510123456', 5000, '2023-09-08', 0.27, 0, '2023-08-08', false, 0, '2023-08-08'),
       (9, '0520375677', 5000, '2023-09-09', 0.16, 0, '2023-08-09', false, 0, '2023-08-09');

-- history_credit_history
INSERT INTO history_credit_history
    (request_id, credit_history_xml)
VALUES (1, 'DATA 1'),
       (2, 'DATA 2'),
       (4, 'DATA 4'),
       (5, 'DATA 5'),
       (6, 'DATA 6'),
       (7, 'DATA 7'),
       (8, 'DATA 8'),
       (9, 'DATA 9');

-- history_payments
INSERT INTO history_payments
(payment_id, order_id, payment_sum_main, payment_sum_percent, payment_date)
VALUES (default, 1, 10000, 0, '2023-05-01'),
       (default, 2, 5020, 0, '2023-09-15'),
       (default, 3, 999, 0, '2023-10-14'),
       (default, 4, 1050, 0, '2023-09-29'),
       (default, 6, 14940, 0, '2023-09-10');
-- credit is closed!!

-- overdue_orders
INSERT INTO overdue_orders
    (order_id, overdue_start_date, overdue_end_date)
VALUES (1, '2023-03-20', '2023-05-01'),
       (2, '2023-09-09', null),
       (3, '2023-08-03', '2023-08-15'),
       (4, '2023-09-03', '2023-09-10'),
       (6, '2023-10-03', '2023-10-21');


