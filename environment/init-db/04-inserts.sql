-- Заполнить БД данными (по 5–10 записей в каждую таблицу). Для заполнения можно
-- использовать как INSERT (минимум по 1 строке в каждую таблицу), так и внешние
-- источники данных (XLS, CSV).

SET search_path = credit_scheme, public;

-- models
INSERT INTO models
(threshold, algorithm_description, deployed_at, traffic_percent, model_type)
VALUES (0.841, 'GradBoost v1', '2023-01-10', 0.5, 'verification'),
       (0.789, 'CatBoost v1', '2023-01-03', 0.5, 'scoring'),
       (0.822, 'AdaBoost v1', '2023-04-12', 0.5, 'verification'),
       (0.705, 'GradBoost v2', '2023-04-30', 0.5, 'scoring');

-- decision_reasons
INSERT INTO decision_reasons
    (decision_text)
VALUES ('В черном списке'),
       ('Не одобрен верификационной моделью'),
       ('Не одобрен скоринговой моделью'),
       ('Не одобрен бизнес логикой'),
       ('Кредит одобрен');



