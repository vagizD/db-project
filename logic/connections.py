import asyncpg
from typing import Union
from dataclasses import dataclass


@dataclass
class DatabaseConnection:
    host: str
    password: str
    user: str
    dbname: str


class Database:

    def __init__(self, config: DatabaseConnection):
        self.pool: Union[asyncpg.Pool, None] = None
        self.config = config

    async def create_pool(self):
        self.pool = await asyncpg.create_pool(
            user=self.config.user,
            password=self.config.password,
            host=self.config.host,
            database=self.config.dbname
        )

    async def execute(self, query: str, *params,
                      fetch: bool = False, fetch_val: bool = False,
                      fetch_row: bool = False, execute: bool = False):
        async with self.pool.acquire() as connection:
            connection: asyncpg.Connection
            async with connection.transaction():
                if fetch:
                    result = await connection.fetch(query, *params)
                elif fetch_val:
                    result = await connection.fetchval(query, *params)
                elif fetch_row:
                    result = await connection.fetchrow(query, *params)
                elif execute:
                    result = await connection.execute(query, *params)
                return result

    def insert_history_requests(self, request):
        ...

    def insert_history_verification_results(self, request):
        ...

    def insert_history_decisions(self, request):
        ...

    def insert_blacklist(self, client):
        ...

    def insert_overdue_orders(self, order):
        ...

    def insert_history_payments(self, payment):
        ...

    def insert_models(self, model):
        ...

    def insert_clients(self, client):
        ...

    def insert_decision_reasons(self, reason):
        ...

    def insert_orders(self, order):
        ...

    def insert_history_credit_history(self, credit_history):
        ...
