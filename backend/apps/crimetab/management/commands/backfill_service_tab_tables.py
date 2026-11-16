from collections import Counter

from django.core.management.base import BaseCommand
from django.db import transaction

from apps.core.tenancy import TenantContext
from apps.crimetab.service_tab_tables import save_sam_warrant


class Command(BaseCommand):
    help = ('Copy service tab answers saved only in case JSON into their tables '
            '(Sam/Warrant -> sam_warrant_records). The JSON is not changed and running it '
            'again only refreshes the rows. Default: every active state; --dry-run reads only.')

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
        for schema in schemas:
            totals = Counter()
            with TenantContext(schema), transaction.atomic():
                for case in CaseRecord.objects.filter(module_key__iexact='sam_warrant').iterator():
                    values = save_sam_warrant(case, write=not dry_run)
                    totals['sam/warrant rows'] += 1
                    if not values['warrant_type']:
                        totals['type unclear'] += 1
                        self.stdout.write(f'  {case.pk}: type unclear '
                                          f'({case.extra_fields.get("warrant_type")!r}, {case.sub_category!r})')
            verb = 'would write' if dry_run else 'wrote'
            self.stdout.write(self.style.SUCCESS(f'{schema}: {verb} ' + (', '.join(
                f'{k} {v}' for k, v in totals.items()) or 'nothing')))
