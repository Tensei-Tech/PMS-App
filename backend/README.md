# PMS Backend Testing Guide

## Running Tests

### 1. Default Unit Tests (SQLite)
By default, standard unit tests run using Django's in-memory SQLite database:
```bash
python manage.py test apps.crimetab.tests.test_rti_officers
```

### 2. PostgreSQL Scratch Database Integration Tests
Tests that require PostgreSQL-specific features (such as multi-tenant schemas via `search_path` and `GENERATED ALWAYS` computed columns in `test_rti_postgres.py`) require a PostgreSQL connection.

To run `test_rti_postgres.py` against a local/scratch PostgreSQL database:
1. Ensure a PostgreSQL scratch/test database is accessible.
2. Set the test database engine and credentials (e.g., via environment variables or test settings) pointing to your scratch database.
3. Run the PostgreSQL test suite:
```bash
python manage.py test apps.crimetab.tests.test_rti_postgres
```
Scratch schemas created during test execution (`test_scratch_rti_testcase`, `test_scratch_rti_other_state`) are isolated and automatically dropped in a `finally` block upon test completion.

### 3. PostgreSQL Migration Verification (Real Migration Path)
To test all migrations from 0001 to 0036 through the real Django migration path (`python manage.py migrate`) against an isolated scratch PostgreSQL database:
1. Ensure your scratch PostgreSQL database is running (never the live project).
2. Set `DATABASE_URL` in your test environment to point to your scratch PostgreSQL database (e.g., `postgresql://postgres:postgres@localhost:5432/scratch_test_db`).
3. Run migrations through the real path:
```bash
python manage.py migrate
```
4. Confirm idempotence (safe to run multiple times):
```bash
python manage.py migrate
```
5. Run the automated migration test suite:
```bash
python manage.py test apps.crimetab.tests.test_migration_0036
```
This validates `DatabaseSchemaEditor` mogrify parameter interpolation, confirms that `%` characters are properly escaped as `%%`, and exercises the migration through Django's `MigrationLoader` and `schema_editor`.


## Performance settings (Render → Environment)

All optional; the defaults are below.

| Variable | Default | What it does |
|---|---|---|
| `WEB_CONCURRENCY` | `2` | Gunicorn worker processes (`gunicorn.conf.py`). Use `1` if the instance runs out of memory. |
| `GUNICORN_THREADS` | `4` | Threads per worker; requests served at once = workers × threads (also the max database connections). |
| `GUNICORN_TIMEOUT` | `60` | Seconds before a stuck request is killed. |
| `DB_CONN_MAX_AGE` | `60` | Seconds a database connection is kept for reuse. Forced to `0` on Supabase's transaction pooler (port 6543) to keep tenant `search_path` isolated; use the session pooler (port 5432). |
| `SLOW_REQUEST_MS` | `1000` | Requests slower than this are logged as warnings. |
| `REDIS_URL` | empty | Upstash Redis connection string (`rediss://default:<password>@<host>:6379`, from Upstash → Connect → Redis). Set: the shared cache lives in Upstash and survives restarts and sleep. Empty: per-process memory. Tests never use it. |
| `CACHE_KEY_PREFIX` | `pms` | Prefix of every cache key in Upstash. `cache.clear()` deletes only these keys, never the whole database. Use a different prefix if another environment shares the same Upstash database. |
| `REDIS_CONNECT_TIMEOUT` / `REDIS_TIMEOUT` | `2` / `2` | Seconds before a Redis call gives up. On any Redis error the app serves without cache and retries Redis after 30 s; requests never fail because of the cache. |

The Upstash REST token (`UPSTASH_REDIS_REST_TOKEN`) is **not** the Redis password:
copy the full Redis URL from the Upstash dashboard into `REDIS_URL`.
Cached responses are per user by default (`@cache_response(..., per_user=False)`
only for reference data that is the same for everyone).

Every request logs one line such as `[Timing] GET /api/cases/ 200 412ms db=9q/180ms`
(Render → Logs) and returns a `Server-Timing` header.
