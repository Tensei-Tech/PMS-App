import os
import django
from django.db import connection

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

cursor = connection.cursor()
cursor.execute("SELECT table_schema, count(*) FROM information_schema.tables WHERE table_name = 'cases_caserecord' GROUP BY table_schema;")
for r in cursor.fetchall():
    print(r)
    
cursor.execute("SELECT table_schema FROM information_schema.tables WHERE table_name = 'cases_caserecord';")
schemas = [r[0] for r in cursor.fetchall()]

for s in schemas:
    cursor.execute(f"SELECT count(*) FROM {s}.cases_caserecord WHERE status IN ('Open', 'Under Investigation');")
    print(f"Schema {s} Open/UI count:", cursor.fetchone()[0])
