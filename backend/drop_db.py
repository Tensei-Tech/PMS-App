import psycopg2
from config.settings import DATABASES
db_cfg = DATABASES['default']
conn = psycopg2.connect(
    dbname='postgres',
    user=db_cfg['USER'],
    password=db_cfg['PASSWORD'],
    host=db_cfg['HOST'],
    port=db_cfg['PORT']
)
conn.autocommit = True
cur = conn.cursor()
cur.execute("SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'test_postgres' AND pid != pg_backend_pid();")
try:
    cur.execute("DROP DATABASE IF EXISTS test_postgres WITH (FORCE);")
except psycopg2.errors.SyntaxError:
    cur.execute("DROP DATABASE IF EXISTS test_postgres;")
cur.close()
conn.close()
print("Dropped successfully.")
