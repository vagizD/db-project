import polars as pl
from textwrap import dedent
from os.path import dirname, abspath, join
from cred_routing import cred_routing
from connections import execute_query


def simulate_cred_routing(data_path):
    data = pl.read_csv(data_path)
    cols = data.columns
    for row in data.rows():
        request = dict(zip(cols, row))
        cred_routing(request)
    print("All decisions made.")


def simulate_orders():
    query = dedent(
        """
        INSERT INTO credit_scheme.orders
                (request_id, client_id, issued_sum, 
                 cred_end_date, fee_percent, paid_sum, 
                 next_payment_date, overdue_sum, issued_at,
                 is_closed)
        SELECT
            hc.request_id as request_id, 
            hr.passport as client_id,
            hc.approved_sum as issued_sum, 
            hc.max_cred_end_date as cred_end_date,
            0.10 as fee_percent,
            0 as paid_sum,
            current_date + interval '1 month' as next_payment_date,
            0 as overdue_sum,
            current_date as issued_at,
            FALSE as is_closed
        FROM credit_scheme.history_decisions hc
        LEFT JOIN credit_scheme.history_requests hr
            ON hc.request_id = hr.request_id
        WHERE hc.approved_sum IS NOT NULL
        """
    )

    execute_query(query)
    print("Clients added.")


def simulate_payments():
    query = dedent(
        """
        INSERT INTO credit_scheme.history_payments
            (order_id, payment_sum_main, 
             payment_sum_percent, payment_date)
        VALUES (1, 10000, 0, '2023-05-01'),
               (2, 5020, 0, '2023-09-15'),
               (3, 999, 0, '2023-10-14'),
               (3, 512, 0, '2023-10-30'),
               (3, 955, 0, '2023-11-19'),
               (4, 1050, 0, '2023-09-29'),
               (6, 14940, 0, '2023-09-10');
       """
    )

    execute_query(query)
    print("Payments processed.")


def simulate_blacklist():
    query = dedent(
        """
        INSERT INTO credit_scheme.blacklist
            (client_id, under_report, start_date)
        SELECT
            client_id,
            'Скамер' as under_report,
            '2023-07-28' as start_date
        FROM credit_scheme.clients
        ORDER BY random()
        LIMIT 2
       """
    )

    execute_query(query)
    print("Blacklist updated.")


def simulate_overdue_algo():
    query = dedent(
        """
        -- testing purposes
        update credit_scheme.orders
        set issued_at         = current_date - interval '2' month,
            next_payment_date = current_date - interval '1' day
        where order_id <= 3
          and is_closed = false;
          
        SELECT *
        FROM credit_scheme.check_overdues();
        
        SELECT *
        FROM credit_scheme.penalty();
        """
    )

    execute_query(query)


if __name__ == "__main__":
    dir_path = dirname(abspath(__file__))
    data_path = join(dir_path, 'data', 'requests.txt')

    simulate_cred_routing(data_path)
    # new order -> new client, 03-02-trigger works!
    simulate_orders()
    # new payment -> maybe credit is closed -> check paid_sum, 03-01-trigger works!
    simulate_payments()
    simulate_blacklist()
    # client didn't pay -> charge pennies -> 10-functions work!
    simulate_overdue_algo()
