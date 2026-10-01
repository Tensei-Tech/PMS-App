import os
import django
from django.db import connection

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

cursor = connection.cursor()
cursor.execute("SELECT count(*) FROM public.cases_caserecord WHERE status IN ('Open', 'Under Investigation');")
print("Public schema Open/Under Inv count:", cursor.fetchone()[0])
cursor.execute("SELECT count(*) FROM maharashtra.cases_caserecord WHERE status IN ('Open', 'Under Investigation');")
print("Maharashtra schema Open/Under Inv count:", cursor.fetchone()[0])

print("Querying the one with data:")
cursor.execute("SELECT id, status FROM public.cases_caserecord WHERE status IN ('Open', 'Under Investigation');")
for r in cursor.fetchall():
    print("Public:", r)
    
cursor.execute("SELECT id, status FROM maharashtra.cases_caserecord WHERE status IN ('Open', 'Under Investigation');")
for r in cursor.fetchall():
    print("Maharashtra:", r)
