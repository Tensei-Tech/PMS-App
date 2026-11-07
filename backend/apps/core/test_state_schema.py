from django.apps import apps as django_apps
from django.db import connection
from django.test import TestCase

from apps.core.state_schema import (
    RETIRED_TABLES,
    SHARED_TABLES,
    STATE_TABLES,
    plan_state_schema,
    state_models,
    sync_state_schema,
)
from apps.core.tenancy import TenantContext, provision_state_schema


class StateTableListTests(TestCase):
    """Every model must say where its table lives, so no new tab is left out of new states."""

    def test_every_model_is_listed_once(self):
        lists = (STATE_TABLES, SHARED_TABLES, RETIRED_TABLES)
        for model in django_apps.get_models():
            if not model._meta.managed or model._meta.proxy:
                continue
            table = model._meta.db_table
            homes = [name for name, tables in zip(('STATE', 'SHARED', 'RETIRED'), lists) if table in tables]
            self.assertEqual(
                len(homes), 1,
                f'{model._meta.label} ({table}) is in {homes or "no list"}. Add it to exactly one of '
                f'STATE_TABLES or SHARED_TABLES in apps/core/state_schema.py.',
            )

    def test_listed_state_tables_have_models(self):
        model_tables = {m._meta.db_table for m in state_models()}
        self.assertEqual(STATE_TABLES - model_tables, set())

    def test_lists_do_not_overlap(self):
        self.assertFalse(STATE_TABLES & SHARED_TABLES)
        self.assertFalse((STATE_TABLES | SHARED_TABLES) & RETIRED_TABLES)

    def test_case_tables_are_state_tables(self):
        for table in ('cases_caserecord', 'cases_person', 'muddemal_records', 'road_accident_records'):
            self.assertIn(table, STATE_TABLES)
        for table in ('case_categories', 'field_templates', 'states', 'roles'):
            self.assertIn(table, SHARED_TABLES)


class StateSchemaSyncPostgresTests(TestCase):
    """A provisioned state gets every state table and column (PostgreSQL only; runs in CI)."""

    schema = 'test_state_schema_sync'

    def setUp(self):
        if connection.vendor != 'postgresql':
            self.skipTest('State schemas exist only on PostgreSQL')

    def tearDown(self):
        if connection.vendor == 'postgresql':
            with connection.cursor() as cursor:
                cursor.execute(f'DROP SCHEMA IF EXISTS "{self.schema}" CASCADE;')

    def test_new_state_has_every_state_table_and_column(self):
        provision_state_schema(self.schema, state_code='TS', state_name='Test Sync')
        create, add = plan_state_schema(self.schema)
        self.assertEqual(create, [])
        self.assertEqual(add, {})

    def test_new_state_gets_muddemal_starting_config(self):
        provision_state_schema(self.schema, state_code='TS', state_name='Test Sync')
        from apps.muddemal.models import MuddemalConfig, MuddemalPropertyCategory
        with TenantContext(self.schema):
            self.assertTrue(MuddemalConfig.objects.filter(config_key='ui_labels').exists())
            self.assertTrue(MuddemalConfig.objects.filter(config_key='property_statuses').exists())
            self.assertTrue(MuddemalPropertyCategory.objects.exists())

    def test_new_state_can_save_a_case(self):
        provision_state_schema(self.schema, state_code='TS', state_name='Test Sync')
        from apps.cases.models import CaseRecord
        from apps.crimetab.models.accident import RoadAccidentRecord
        with TenantContext(self.schema):
            case = CaseRecord.objects.create(id='TEST_SYNC_1', case_number='CR/TS/1', station_name='TEST')
            RoadAccidentRecord.objects.create(case=case)
            case.delete()
            self.assertFalse(RoadAccidentRecord.objects.exists())

    def test_second_sync_changes_nothing_and_keeps_data(self):
        provision_state_schema(self.schema, state_code='TS', state_name='Test Sync')
        from apps.cases.models import CaseRecord
        with TenantContext(self.schema):
            CaseRecord.objects.create(id='TEST_SYNC_KEEP', case_number='CR/TS/2', station_name='TEST')
        report = sync_state_schema(self.schema)
        self.assertEqual((report['created'], report['columns_added'], report['seeded']), ([], {}, []))
        with TenantContext(self.schema):
            self.assertTrue(CaseRecord.objects.filter(id='TEST_SYNC_KEEP').exists())

    def test_missing_column_is_added_back(self):
        provision_state_schema(self.schema, state_code='TS', state_name='Test Sync')
        with connection.cursor() as cursor:
            cursor.execute(f'ALTER TABLE "{self.schema}".cases_caserecord DROP COLUMN disposal_date')
        self.assertEqual(plan_state_schema(self.schema)[1], {'cases_caserecord': ['disposal_date']})
        report = sync_state_schema(self.schema)
        self.assertEqual(report['columns_added'], {'cases_caserecord': ['disposal_date']})
        self.assertEqual(plan_state_schema(self.schema)[1], {})

    def test_dry_run_creates_nothing(self):
        report = sync_state_schema(self.schema, dry_run=True)
        self.assertIn('cases_caserecord', report['created'])
        with connection.cursor() as cursor:
            cursor.execute('SELECT 1 FROM information_schema.schemata WHERE schema_name = %s', [self.schema])
            self.assertIsNone(cursor.fetchone())
