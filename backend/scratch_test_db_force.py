import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.db import connection

try:
    with connection.cursor() as cursor:
        connection.autocommit = True
        cursor.execute("DROP DATABASE IF EXISTS test_postgres WITH (FORCE);")
        print("Successfully force-dropped test_postgres.")
except Exception as e:
    print("Force drop failed:", e)
    
    # fallback
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'test_postgres' AND pid <> pg_backend_pid();")
            cursor.execute("DROP DATABASE IF EXISTS test_postgres;")
            print("Successfully dropped test_postgres.")
    except Exception as e2:
        print("Fallback drop failed:", e2)
