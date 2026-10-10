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

