import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.db import connection

with connection.cursor() as cursor:
    cursor.execute("""
        SELECT pid, state, query 
        FROM pg_stat_activity 
        WHERE datname = 'test_postgres' AND pid <> pg_backend_pid();
    """)
    rows = cursor.fetchall()
    print("--- Sessions holding test_postgres ---")
    for r in rows:
        print(f"PID: {r[0]}, State: {r[1]}, Query: {r[2]}")
    
    if rows:
        print("\nTerminating sessions...")
        cursor.execute("SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'test_postgres' AND pid <> pg_backend_pid();")
        print("Done terminating.")
    
    import time
    time.sleep(1)

    print("\nAttempting to drop database...")
    try:
        connection.autocommit = True
        cursor.execute("DROP DATABASE IF EXISTS test_postgres;")
        print("Successfully dropped test_postgres.")
    except Exception as e:
        print("Drop failed:", e)
    finally:
        connection.autocommit = False
