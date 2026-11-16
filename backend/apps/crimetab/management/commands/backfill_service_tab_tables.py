from collections import Counter

from django.core.management.base import BaseCommand
from django.db import transaction

from apps.core.tenancy import TenantContext
from apps.crimetab.service_tab_tables import (
    LICENCE_MODULES, PASSPORT_PVR_MODULES, TADIPAR_MODULES, save_licence, save_passport_pvr, save_sam_warrant,
    save_tadipar)


class Command(BaseCommand):
    help = ('Copy service tab answers saved only in case JSON into their tables '
            '(Sam/Warrant -> sam_warrant_records, Passport / PVR -> passport_pvr_records, Licence -> licence_records, Tadipar -> tadipar_records, A.D. -> case_extra_field_values). The JSON is not changed and running it '
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
                for case in CaseRecord.objects.filter(module_key__in=PASSPORT_PVR_MODULES).iterator():
                    values = save_passport_pvr(case, write=not dry_run)
                    totals['passport/pvr rows'] += 1
                    if values['total_count'] is None:
                        totals['passport/pvr without counts'] += 1
                for case in CaseRecord.objects.filter(module_key__in=LICENCE_MODULES).iterator():
                    save_licence(case, write=not dry_run)
                    totals['licence rows'] += 1
                for case in CaseRecord.objects.filter(module_key__in=TADIPAR_MODULES).iterator():
                    save_tadipar(case, write=not dry_run)
                    totals['tadipar rows'] += 1
                # A.D.: the form answers as one row each in case_extra_field_values
                from apps.crimetab.services import ad_service
                ad_defs = ad_service.load_field_defs(ad_service.AdSettings())
                for case in CaseRecord.objects.filter(module_key__iexact='ad').iterator():
                    values = ad_service.json_form_data(case, ad_defs)
                    if not values:
                        continue  # e.g. an A.D. case saved from the Common Form with blank A.D. answers
                    rows = ad_service.build_answer_rows(case, values, ad_defs)
                    if not dry_run:
                        ad_service.save_answers(case, values, ad_defs)
                    totals['a.d. cases'] += 1
                    totals['a.d. answer rows'] += len(rows)
            verb = 'would write' if dry_run else 'wrote'
            self.stdout.write(self.style.SUCCESS(f'{schema}: {verb} ' + (', '.join(
                f'{k} {v}' for k, v in totals.items()) or 'nothing')))
