import os
from os.path import abspath, dirname, join
from psycopg2 import pool
from textwrap import dedent
from dotenv import load_dotenv
from functools import cached_property

dir_path = dirname(abspath(__file__))
dotenv_path = join(dir_path, '..', 'environment', '.env')
load_dotenv(dotenv_path=dotenv_path)


class AvengersDB:
    host: str = os.getenv("POSTGRES_HOST")
    password: str = os.getenv("POSTGRES_PASSWORD")
    user: str = os.getenv("POSTGRES_USER")
    dbname: str = os.getenv("POSTGRES_DB")

    @cached_property
    def pool(self):
        return pool.SimpleConnectionPool(
            minconn=1,
            maxconn=5,
            user=self.user,
            password=self.password,
            host=self.host,
            database=self.dbname
        )

    def get_conn(self):
        return self.pool.getconn()

    def put_conn(self, conn):
        self.pool.putconn(conn)


def pool_conn(func):
    """Atomacity"""
    def inner(*args, **kwargs):
        made_tries = 0
        allowed_tries = 2
        while made_tries < allowed_tries:
            conn = avengers.get_conn()
            try:
                with conn.cursor() as cur:
                    result = func(cur, *args, **kwargs)
            except Exception as e:
                print(e)
                conn.rollback()
                if made_tries == allowed_tries:
                    raise e
                made_tries += 1
            else:
                conn.commit()
                break
            finally:
                avengers.put_conn(conn)

        return result

    return inner


@pool_conn
def execute_query(cur, query):
    cur.execute(query)


@pool_conn
def insert_query(cur, data, columns, full_table_name, has_return=None) -> None:
    params = [data.get(col) for col in columns]
    columns_sql = ','.join(columns)
    values_sql = ','.join(['%s'] * len(columns))

    query = dedent(
        f"""
        insert into {full_table_name} 
            ({columns_sql})
        values
            ({values_sql})
        """
    )

    if has_return:
        query = dedent(query + f'\n returning {has_return}')

    cur.execute(query, params)

    if has_return:
        return cur.fetchone()[0]


@pool_conn
def is_blacklist(cur, request) -> bool:
    client_id = request.get('passport')

    params = [client_id]
    query = dedent(
        f"""
        select 1
        from credit_scheme.blacklist
        where client_id = '%s'
        """
    )

    cur.execute(query, params)

    return cur.fetchone() is not None


def insert_history_credit_history(request):
    columns = [
        'request_id',
        'credit_history_xml'
    ]

    full_table_name = "credit_scheme.history_credit_history"

    insert_query(request, columns, full_table_name)


def insert_history_requests(request):
    columns = [
        'request_at',
        'request_sum',
        'first_name',
        'last_name',
        'middle_name',
        'birth_date',
        'passport',
        'passport_issued_by',
        'email',
        'phone_number',
        'country',
        'city',
        'address'
    ]

    full_table_name = "credit_scheme.history_requests"

    return insert_query(request, columns, full_table_name, has_return='request_id')


def insert_history_decisions(request):
    columns = [
        'request_id',
        'decision_reason_id',
        'scoring_model_id',
        'scoring_model_score',
        'scored_at',
        'approved_sum',
        'is_under',
        'max_cred_end_date'
    ]

    full_table_name = "credit_scheme.history_decisions"

    insert_query(request, columns, full_table_name)


def insert_history_verification_results(request):
    columns = [
        'request_id',
        'verification_model_id',
        'verification_model_score',
        'is_verified',
        'verified_at'
    ]

    full_table_name = "credit_scheme.history_verification_results"

    insert_query(request, columns, full_table_name)


avengers = AvengersDB()
