import os
import django
from django.db import connection

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

cursor = connection.cursor()

cursor.execute("SELECT count(*) FROM cases_caserecord;")
print("Total directly:", cursor.fetchone()[0])

cursor.execute("SELECT table_schema, table_type FROM information_schema.tables WHERE table_name = 'cases_caserecord';")
for r in cursor.fetchall():
    print(r)
    
cursor.execute("SELECT n.nspname, c.relname, c.reltuples FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE c.relname = 'cases_caserecord';")
for r in cursor.fetchall():
    print(r)
