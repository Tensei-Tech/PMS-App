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

    def handle(self, *args, **options):
        target_db = options.get('database') or 'default'
        
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
