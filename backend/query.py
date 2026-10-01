import os
import django
from django.db import connection

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

cursor = connection.cursor()

print('--- DB SCHEMA ---')
cursor.execute("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'cases_caserecord';")
for row in cursor.fetchall():
    print(row)

print('--- POSTGRES COUNT ---')
cursor.execute("SELECT count(*) FROM cases_caserecord;")
print('Total:', cursor.fetchone()[0])

print('--- POSTGRES STATUS GROUP ---')
cursor.execute("SELECT status, count(*) FROM cases_caserecord GROUP BY status;")
for row in cursor.fetchall():
    print(row)
