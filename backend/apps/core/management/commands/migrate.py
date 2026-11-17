from django.core.management.commands.migrate import Command as BuiltinMigrateCommand
from django.core.management import call_command
from django.conf import settings
import logging

logger = logging.getLogger(__name__)


class Command(BuiltinMigrateCommand):
    """
    Overridden 'migrate' command for Multi-DB / Replica setup.
    Executing 'python manage.py migrate' automatically updates 
    Primary DB ('default') AND all active Replica DBs ('replica_1', 'replica_2') in one run!
    """

    def add_arguments(self, parser):
        super().add_arguments(parser)
        parser.add_argument(
            '--allow-rollback', action='store_true',
            help='Allow running migrations backwards on the shared database (it can drop tables and data).')

    def _refuse_rollback(self, options):
        """E1: going backwards on the shared database needs --allow-rollback (see apps.core.migration_safety)."""
        from django.core.management.base import CommandError
        from django.db import connections
        from django.db.migrations.executor import MigrationExecutor
        from apps.core.migration_safety import is_shared_database, rollback_plan

        if options.get('allow_rollback') or options.get('plan'):
            return
        connection = connections[options.get('database') or 'default']
        if not is_shared_database(connection):
            return
        backwards = rollback_plan(MigrationExecutor(connection), options.get('app_label'),
                                  options.get('migration_name'))
        if backwards:
            names = ', '.join(f'{m.app_label}.{m.name}' for m in backwards[:8])
            more = f' and {len(backwards) - 8} more' if len(backwards) > 8 else ''
            raise CommandError(
                f'Refused: this would undo {len(backwards)} migration(s) on the shared database '
                f'({names}{more}). That can drop tables and data. Check with --plan first; if it is '
                f'really needed, run again with --allow-rollback.')

    def handle(self, *args, **options):
        target_db = options.get('database') or 'default'
        self._refuse_rollback(options)

        # 1. Execute migration on target database
        super().handle(*args, **options)

        # If user explicitly passed a specific database target (e.g. --database=replica_1), stop here
        if options.get('database') and options.get('database') != 'default':
            return

        # 2. Automatically loop through all configured replica databases
        replica_databases = [db for db in ['replica_1', 'replica_2'] if db in settings.DATABASES]
        
        for replica_db in replica_databases:
            self.stdout.write(self.style.MIGRATE_HEADING(
                f"\n🔄 [Multi-DB Auto-Migrate] Migrating Replica Database: '{replica_db}'..."
            ))
            try:
                replica_options = options.copy()
                replica_options['database'] = replica_db
                call_command('migrate', **replica_options)
                self.stdout.write(self.style.SUCCESS(
                    f"✅ [Multi-DB Auto-Migrate] Replica '{replica_db}' updated successfully!\n"
                ))
            except Exception as e:
                self.stdout.write(self.style.ERROR(
                    f"⚠️ [Multi-DB Auto-Migrate] Error updating replica '{replica_db}': {e}\n"
                ))
