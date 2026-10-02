import os, django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()
from django.db import connection
cursor = connection.cursor()
cursor.execute("SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'test_postgres' AND pid != pg_backend_pid();")
print("Terminated.")
