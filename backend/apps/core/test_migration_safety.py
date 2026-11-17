"""E1 / E4: rollbacks refused on the shared database; new dangerous migrations need a review."""
from types import SimpleNamespace
from unittest import mock

from django.core.management import call_command
from django.core.management.base import CommandError
from django.db import migrations, models
from django.test import TestCase

from apps.core import migration_safety as safety


def fake_loader(**named):
    return SimpleNamespace(disk_migrations={('core', name): m for name, m in named.items()})


def migration(*operations, reviewed=None):
    m = migrations.Migration('9999_test', 'core')
    m.operations = list(operations)
    if reviewed:
        m.reviewed_dangerous = reviewed
    return m


def delete_rows(apps, schema_editor):
    apps.get_model('cases', 'CaseRecord').objects.filter(module_key='x').delete()


class DangerousMigrationTests(TestCase):

    def test_no_unreviewed_dangerous_migrations(self):
        """The CI gate: a new migration that drops, renames or deletes must be marked reviewed."""
        found = safety.unreviewed_dangerous_migrations()
        self.assertEqual(found, [], 'Review these migrations, then add reviewed_dangerous: %s' % found)

    def test_dangerous_operations_and_text_are_found(self):
        m = migration(
            migrations.RemoveField(model_name='x', name='y'),
            migrations.RunSQL('DELETE FROM maharashtra.cases_caserecord WHERE id = 1'),
            migrations.RunPython(delete_rows),
            migrations.SeparateDatabaseAndState(database_operations=[migrations.RunSQL('DROP TABLE old')]),
        )
        reasons = safety.migration_problems(m)
        self.assertTrue(any(r.startswith('RemoveField') for r in reasons), reasons)
        self.assertTrue(any('DELETE FROM' in r for r in reasons), reasons)
        self.assertTrue(any('.DELETE()' in r for r in reasons), reasons)
        self.assertTrue(any('DROP TABLE' in r for r in reasons), reasons)

    def test_safe_migration_passes(self):
        m = migration(migrations.AddField(model_name='x', name='y', field=models.TextField(null=True)))
        with mock.patch.object(safety, '_our_migrations', lambda loader: loader.disk_migrations), \
                mock.patch.object(safety, 'read_baseline', lambda: set()):
            self.assertEqual(safety.unreviewed_dangerous_migrations(fake_loader(**{'9999_a': m})), [])

    def test_new_dangerous_migration_fails_until_reviewed(self):
        bad = migration(migrations.DeleteModel(name='Old'))
        ok = migration(migrations.DeleteModel(name='Old'), reviewed='checked on a copy')
        with mock.patch.object(safety, '_our_migrations', lambda loader: loader.disk_migrations), \
                mock.patch.object(safety, 'read_baseline', lambda: {'core.9999_old'}):
            found = safety.unreviewed_dangerous_migrations(fake_loader(**{'9999_bad': bad, '9999_ok': ok,
                                                                          '9999_old': bad}))
        self.assertEqual([k for k, _ in found], ['core.9999_bad'])

    def test_command_reports_and_fails(self):
        with mock.patch('apps.core.management.commands.check_migration_safety.unreviewed_dangerous_migrations',
                        return_value=[('core.9999_bad', ['DeleteModel: drops a table'])]):
            with self.assertRaises(CommandError):
                call_command('check_migration_safety', stdout=mock.MagicMock())


class RollbackGuardTests(TestCase):

    def test_shared_database_is_a_remote_postgres(self):
        pg = lambda host: SimpleNamespace(vendor='postgresql', settings_dict={'HOST': host})  # noqa: E731
        self.assertTrue(safety.is_shared_database(pg('aws-0-ap-south-1.pooler.supabase.com')))
        self.assertFalse(safety.is_shared_database(pg('localhost')))
        self.assertFalse(safety.is_shared_database(SimpleNamespace(vendor='sqlite', settings_dict={})))

    def _guard(self, **options):
        from apps.core.management.commands.migrate import Command
        Command()._refuse_rollback({'database': 'default', 'plan': False, 'allow_rollback': False, **options})

    def test_rollback_plan_lists_what_would_be_undone(self):
        nodes = {('crimetab', '0187_a'): SimpleNamespace(app_label='crimetab', name='0187_a'),
                 ('crimetab', '0188_b'): SimpleNamespace(app_label='crimetab', name='0188_b')}
        loader = SimpleNamespace(applied_migrations={k: True for k in nodes}, graph=SimpleNamespace(nodes=nodes),
                                 get_migration_by_prefix=lambda app, name: SimpleNamespace(name='0187_a'))
        executor = SimpleNamespace(
            loader=loader,
            migration_plan=lambda targets: [(nodes[('crimetab', '0188_b')], True)])
        self.assertEqual([m.name for m in safety.rollback_plan(executor, 'crimetab', '0187')], ['0188_b'])
        self.assertEqual([m.name for m in safety.rollback_plan(executor, 'crimetab', 'zero')], ['0187_a', '0188_b'])
        self.assertEqual(safety.rollback_plan(executor, 'crimetab', None), [])

    def test_going_backwards_is_refused_on_the_shared_database(self):
        undo = [SimpleNamespace(app_label='crimetab', name='0188_preventive_records')]
        with mock.patch('apps.core.migration_safety.is_shared_database', return_value=True),                 mock.patch('apps.core.migration_safety.rollback_plan', return_value=undo):
            with self.assertRaises(CommandError) as err:
                self._guard(app_label='crimetab', migration_name='0187')
            self.assertIn('--allow-rollback', str(err.exception))
            self.assertIn('crimetab.0188_preventive_records', str(err.exception))
            self._guard(app_label='crimetab', migration_name='0187', plan=True)  # --plan only prints
            self._guard(app_label='crimetab', migration_name='0187', allow_rollback=True)

    def test_forwards_and_local_databases_are_not_blocked(self):
        with mock.patch('apps.core.migration_safety.is_shared_database', return_value=True),                 mock.patch('apps.core.migration_safety.rollback_plan', return_value=[]):
            self._guard(app_label='crimetab', migration_name=None)  # nothing to undo
        undo = [SimpleNamespace(app_label='crimetab', name='0188_x')]
        with mock.patch('apps.core.migration_safety.rollback_plan', return_value=undo):
            self._guard(app_label='crimetab', migration_name='0187')  # local database: not blocked
