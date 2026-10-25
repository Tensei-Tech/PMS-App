"""
Gunicorn settings. Gunicorn reads ./gunicorn.conf.py automatically, so this
applies to `gunicorn config.wsgi:application` run from backend/ (Procfile or
Render start command) unless the command passes its own -c/--workers flags.

Without it Gunicorn ran one worker with one thread: every request waited in a
single queue, and a slow login blocked everyone. Threads let requests overlap
while they wait on the database. Each value can be changed on Render.
"""
import os

# Processes. Each holds a full copy of Django (~150 MB); keep 2 on the 512 MB free plan.
workers = int(os.getenv('WEB_CONCURRENCY', '2'))

# Threads per process: requests served at once = workers x threads. Each thread
# keeps its own database connection, so this also caps connections to Supabase.
worker_class = 'gthread'
threads = int(os.getenv('GUNICORN_THREADS', '4'))

# Default 30 s can kill a slow request on a cold free instance with a 502.
timeout = int(os.getenv('GUNICORN_TIMEOUT', '60'))
graceful_timeout = 30
keepalive = 5

# Recycle workers now and then to cap slow memory growth.
max_requests = int(os.getenv('GUNICORN_MAX_REQUESTS', '1000'))
max_requests_jitter = 100

# Bind: Gunicorn uses $PORT (set by Render) when no bind is given.
