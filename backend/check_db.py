import psycopg2
import os, django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()
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
cur.execute("SELECT pid, application_name, state, query FROM pg_stat_activity WHERE datname='test_postgres'")
rows = cur.fetchall()
print("ROWS:", rows)
for r in rows:
    pid = r[0]
    print("Killing PID:", pid)
    cur.execute(f"SELECT pg_terminate_backend({pid})")
cur.close()
conn.close()
