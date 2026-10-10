import importlib
from unittest.mock import MagicMock
from django.test import TransactionTestCase
from django.db import connection
from django.db.backends.postgresql.schema import DatabaseSchemaEditor
from django.db.migrations.loader import MigrationLoader
from django.db.migrations.state import ProjectState

class Migration0036MogrifySafetyTestCase(TransactionTestCase):
    """
    Validates migration 0036 through the REAL migration execution path:
    1. Confirms psycopg2 / Django mogrify safety (no IndexError: tuple index out of range).
    2. Proves that escaping % as %% allows DatabaseSchemaEditor.execute(sql) to interpolate correctly.
    3. Runs migration 0036 via Django's MigrationLoader and schema_editor to ensure no gap
       between direct SQL and the migration path.
    """

    def setUp(self):
        self.migration_module = importlib.import_module(
            "apps.crimetab.migrations.0036_make_rti_fields_optional_and_add_empty_message"
        )
        self.sql = self.migration_module.SQL_DROP_NOT_NULL_AND_ADD_SETTING

    def test_mogrify_interpolation_safety(self):
        """
        Verify that SQL_DROP_NOT_NULL_AND_ADD_SETTING in migration 0036 can be interpolated
        with an empty tuple params=() without raising IndexError, TypeError, or ValueError.
        """
        try:
            formatted = self.sql % ()
        except Exception as e:
            self.fail(f"Interpolating migration 0036 SQL with empty params failed: {type(e).__name__}: {e}")

        # The resulting SQL sent to PostgreSQL must have single %I and single % wildcards
        self.assertIn("%I", formatted)
        self.assertNotIn("%%I", formatted)
        self.assertIn("%due_date%received_date%", formatted)
        self.assertNotIn("%%due_date%%", formatted)
        self.assertIn("%rti_due_after_received%", formatted)

    def test_unescaped_sql_fails_with_format_error(self):
        """
        Recreates the unescaped SQL containing single %I and % wildcards,
        proving that passing it to mogrify/printf formatting with empty tuple params=()
        fails before any SQL can reach PostgreSQL.
        """
        unescaped_sql = self.sql.replace("%%", "%")
        with self.assertRaises((TypeError, IndexError, ValueError)):
            _ = unescaped_sql % ()

    def test_postgres_schema_editor_compose_sql_mogrify(self):
        """
        Tests Django's DatabaseSchemaEditor for PostgreSQL.
        In Django's postgresql backend, schema_editor.execute(sql, params=()) calls
        connection.ops.compose_sql(sql, params) -> cursor.mogrify(sql, params).
        When % is escaped as %%, this executes cleanly and passes unescaped SQL to PostgreSQL.
        """
        mock_conn = MagicMock()
        mock_conn.vendor = 'postgresql'
        mock_conn.features.can_rollback_ddl = True
        mock_conn.in_atomic_block = False

        # Simulate psycopg2 cursor mogrify behavior on tuples
        mock_conn.ops.compose_sql.side_effect = lambda sql, params: sql % params
        editor = DatabaseSchemaEditor(mock_conn)

        # 1. Unescaped SQL must fail
        unescaped_sql = self.sql.replace("%%", "%")
        with self.assertRaises((TypeError, IndexError, ValueError)):
            editor.execute(unescaped_sql)

        # 2. Escaped SQL in 0036 must succeed
        editor.execute(self.sql)

    def test_migration_loads_and_applies_via_schema_editor(self):
        """
        Loads migration 0036 via Django's MigrationLoader and applies it through schema_editor,
        matching the exact execution path taken by 'python manage.py migrate'.
        """
        loader = MigrationLoader(connection, ignore_no_migrations=True)
        migration = loader.get_migration('crimetab', '0036_make_rti_fields_optional_and_add_empty_message')
        self.assertIsNotNone(migration)

        state = loader.project_state(('crimetab', '0035_add_rti_role_scope_settings'))
        with connection.schema_editor(atomic=False) as editor:
            # Apply through real migration path
            migration.apply(state.clone(), editor)

            # Test idempotence (safe to run twice)
            migration.apply(state.clone(), editor)
