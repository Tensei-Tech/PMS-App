import os
from config.settings import *  # Import base settings
import dj_database_url

# Override DATABASES to use PostgreSQL for tests.
# CI sets DATABASE_URL; fallback to a local postgres instance.
DATABASES = {
    "default": dj_database_url.config(
        default="postgresql://postgres:postgres@localhost:5432/test_db",
        conn_max_age=0,
    )
}
