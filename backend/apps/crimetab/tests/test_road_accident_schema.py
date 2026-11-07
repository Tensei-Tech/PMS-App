import re

from django.db import connection
from django.test import TestCase

from apps.core.tenancy import provision_state_schema
from apps.crimetab.models.accident import (
    RoadAccidentDeceased,
    RoadAccidentInjured,
    RoadAccidentRecord,
    RoadAccidentVehicle,
)
from apps.crimetab.road_accident_schema import (
    CASE_FK_NAMES,
    CASE_UNIQUE_NAME,
    ROAD_ACCIDENT_TABLE_NAMES,
    ROAD_ACCIDENT_TENANT_DDL,
    link_road_accident_cases,
)

MODELS = (RoadAccidentRecord, RoadAccidentVehicle, RoadAccidentInjured, RoadAccidentDeceased)


def ddl_columns(table):
    """Column names in the CREATE TABLE statement of one table."""
    stmt = next(s for s in ROAD_ACCIDENT_TENANT_DDL if f'{{s}}.{table} (' in s and 'CREATE TABLE' in s)
    body = stmt[stmt.index('(') + 1:stmt.rindex(')')]
    return {re.match(r'\s*(\w+)', line).group(1) for line in body.split(',\n') if line.strip()}


class RoadAccidentDdlMatchesModelsTests(TestCase):
    """New states get their tables from this DDL; it must not drift from the models."""

    def test_every_model_column_is_in_the_ddl(self):
        for model in MODELS:
            table = model._meta.db_table
            self.assertIn(table, ROAD_ACCIDENT_TABLE_NAMES)
            model_columns = {f.column for f in model._meta.concrete_fields}
            self.assertEqual(ddl_columns(table), model_columns, table)


class ProvisionRoadAccidentTablesTests(TestCase):
    """A newly provisioned state gets the four tables, indexes and case links (PostgreSQL only)."""

    schema = 'test_provision_road_accident'

    def setUp(self):
        if connection.vendor != 'postgresql':
            self.skipTest('Schema provisioning is PostgreSQL-specific')

    def tearDown(self):
        if connection.vendor == 'postgresql':
            with connection.cursor() as cursor:
                cursor.execute(f'DROP SCHEMA IF EXISTS "{self.schema}" CASCADE;')

    def _constraints(self):
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT c.conname FROM pg_constraint c JOIN pg_namespace n ON n.oid = c.connamespace
                WHERE n.nspname = %s
            """, [self.schema])
            return {r[0] for r in cursor.fetchall()}

    def test_new_state_gets_road_accident_tables(self):
        provision_state_schema(self.schema, state_code='TR', state_name='Test Road Accident')
        with connection.cursor() as cursor:
            cursor.execute('SELECT table_name FROM information_schema.tables WHERE table_schema = %s',
                           [self.schema])
            tables = {r[0] for r in cursor.fetchall()}
        self.assertTrue(set(ROAD_ACCIDENT_TABLE_NAMES) <= tables, tables)

    def test_case_links_added_once_cases_table_exists(self):
        provision_state_schema(self.schema, state_code='TR', state_name='Test Road Accident')
        with connection.cursor() as cursor:
            if 'cases_caserecord' not in self._tables(cursor):
                # No case table in this state yet: nothing to link to
                self.assertFalse(link_road_accident_cases(cursor, self.schema))
                cursor.execute(f'CREATE TABLE "{self.schema}".cases_caserecord (id VARCHAR(128) PRIMARY KEY)')
            self.assertTrue(link_road_accident_cases(cursor, self.schema))
            self.assertTrue(link_road_accident_cases(cursor, self.schema))  # idempotent
        constraints = self._constraints()
        for name in [*CASE_FK_NAMES.values(), CASE_UNIQUE_NAME]:
            self.assertIn(name, constraints)

    def _tables(self, cursor):
        cursor.execute('SELECT table_name FROM information_schema.tables WHERE table_schema = %s', [self.schema])
        return {r[0] for r in cursor.fetchall()}
