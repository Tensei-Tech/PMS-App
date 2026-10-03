import psycopg2
conn = psycopg2.connect(dbname='postgres', user='postgres', password='password', host='localhost', port=5432)
conn.autocommit = True
cur = conn.cursor()
cur.execute("SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'test_postgres' AND pid <> pg_backend_pid();")
cur.execute("DROP DATABASE IF EXISTS test_postgres;")
print("Test DB dropped.")
cur.close()
conn.close()
