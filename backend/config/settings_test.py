"""
Test settings configuration using an isolated in-memory SQLite scratch database.
This guarantees zero interactions or risk with the live database during test runs.
"""

from .settings import *

# Isolated in-memory SQLite scratch database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': ':memory:',
    }
}

# Disable migration execution during unit tests on SQLite scratch DB
class DisableMigrations:
    def __contains__(self, item):
        return True

    def __getitem__(self, item):
        return None

MIGRATION_MODULES = DisableMigrations()

