from django.core.management.base import BaseCommand, CommandError
from django.db import connection

from apps.core.state_schema import active_state_schemas, plan_state_schema, sync_state_schema


class Command(BaseCommand):
    help = ('Give state schemas every table and column their models define '
            '(adds only; never drops or changes data). Default: all active states.')

    def add_arguments(self, parser):
        parser.add_argument('--schema', action='append', dest='schemas',
                            help='State schema to sync (repeatable). Default: every active state.')
        parser.add_argument('--dry-run', action='store_true', help='Only show what would be created.')

    def handle(self, *args, schemas=None, dry_run=False, **options):
        if connection.vendor != 'postgresql':
            raise CommandError('State schemas exist only on PostgreSQL.')
        targets = schemas or active_state_schemas()
        if not targets:
            self.stdout.write('No active states.')
            return
        for schema in targets:
            if dry_run:
                create, add = plan_state_schema(schema)
                self.stdout.write(self.style.MIGRATE_HEADING(f'{schema} (dry run)'))
                self.stdout.write(f'  would create {len(create)} tables: {", ".join(create) or "-"}')
                for table, cols in add.items():
                    self.stdout.write(f'  would add to {table}: {", ".join(cols)}')
                continue
            report = sync_state_schema(schema)
            self.stdout.write(self.style.SUCCESS(
                f"{schema}: created {len(report['created'])} tables, "
                f"added columns to {len(report['columns_added'])} tables, "
                f"seeded {', '.join(report['seeded']) or 'nothing'}"
            ))
