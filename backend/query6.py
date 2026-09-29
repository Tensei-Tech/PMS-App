import os
import django
from django.db import connection

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

cursor = connection.cursor()

cursor.execute("SELECT table_schema FROM information_schema.tables WHERE table_name = 'cases_caserecord';")
schemas = [r[0] for r in cursor.fetchall()]

for s in schemas:
    cursor.execute(f"SELECT status, count(*) FROM {s}.cases_caserecord GROUP BY status;")
    res = cursor.fetchall()
    if res:
        print(f"Schema {s}: {res}")
