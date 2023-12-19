from psycopg2 import connect # you need pip install here

cn = connect(database="postgres", user="postgres", password="1234")

res = cn.cursor()

with open('../environment/init-db/01-create.sql', encoding='utf-8') as f:
    create = f.read()

res.execute(create)

with open('../environment/init-db/04-inserts.sql', encoding='utf-8') as f:
    insert = f.read()

res.execute(insert)

check = "SELECT * FROM orders"

res.execute(check)

out = res.fetchall()
print(*out)
