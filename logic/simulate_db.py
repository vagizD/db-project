import asyncio
import logging

from environs import Env
from connections import DatabaseConnection, Database


async def simulate():
    env = Env()
    env.read_env("../environment/.env")
    db = Database(DatabaseConnection(
        host=env.str("POSTGRES_HOST"),
        password=env.str("POSTGRES_PASSWORD"),
        user=env.str("POSTGRES_USER"),
        dbname=env.str("POSTGRES_DB")
    ))
    await db.create_pool()
    logging.info("Database connected successfully")

    # TODO


if __name__ == '__main__':
    try:
        asyncio.run(simulate())
    except Exception as err:
        print(err)
