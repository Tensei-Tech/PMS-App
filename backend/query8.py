import os
import django
from django.db import connection

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

cursor = connection.cursor()
cursor.execute("SELECT id, status FROM maharashtra.cases_caserecord;")
for r in cursor.fetchall():
    print(r)
