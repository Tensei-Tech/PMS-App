from collections import Counter

from django.core.management.base import BaseCommand
from django.db import transaction

from apps.core.tenancy import TenantContext
from apps.crimetab.common_form_tables import save_common_form_tables


class Command(BaseCommand):
    help = ('Copy the Common Form answers saved only in case JSON (charges, crime spot, complainant '
            'and accused, CCTV, e-Sakshya / fingerprint / NAFIS, panchanama ticks) into their '
            'tables. The JSON is not changed and no person is deleted. '
            'Default: every active state; --dry-run reads only.')

    def add_arguments(self, parser):
        parser.add_argument('--schema', action='append', dest='schemas',
                            help='State schema (repeatable). Default: every active state.')
        parser.add_argument('--dry-run', action='store_true',
                            help='Show what would be written; the database is not changed.')

    def handle(self, *args, schemas=None, dry_run=False, **options):
        from apps.cases.models import CaseRecord
        if not schemas:
            from apps.core.state_schema import active_state_schemas
            schemas = active_state_schemas()
        write = not dry_run
        for schema in schemas:
            totals = Counter()
            with TenantContext(schema), transaction.atomic():
                for case in CaseRecord.objects.only('id', 'extra_fields').iterator():
                    if not isinstance(case.extra_fields, dict) or not case.extra_fields:
                        continue
                    totals['cases'] += 1
                    # Charges are only replaced when the JSON names at least one we can find
                    done = save_common_form_tables(case, extra=case.extra_fields, write=write,
                                                   keep_charges_when_empty=True)
                    totals['charge rows'] += done['charges']
                    totals['charges not found'] += done['charges_skipped']
                    totals['cases with charges'] += 1 if done['charges'] else 0
                    totals['crime spot rows'] += int(done['crime_spot'])
                    totals['people added'] += done['people_added']
                    totals['people filled in'] += done['people_updated']
                    totals['cctv rows'] += int(done['cctv'])
                    totals['forensics rows'] += int(done['forensics'])
                    totals['panchanama rows'] += done['panchanama']
            verb = 'would write' if dry_run else 'wrote'
            self.stdout.write(self.style.SUCCESS(f'{schema}: {verb} ' + ', '.join(
                f'{k} {v}' for k, v in totals.items())))
