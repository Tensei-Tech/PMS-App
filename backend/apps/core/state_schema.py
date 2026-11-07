"""
Every state schema gets the same tables, built from the Django models.

Why this exists
---------------
The database connection's default search_path is `maharashtra, public`, so when
`migrate` creates a table (CreateModel) Postgres puts it in `maharashtra` only.
Other states only had the tables someone also wrote by hand in
provision_state_schema (RTI, History Sheeter, MPDA, N.C., Road Accident), so a
new state had no cases_caserecord and could not save a case.

What it does
------------
sync_state_schema(schema) looks at the state's schema and, for every model in
STATE_TABLES:
  * creates the table if it is missing (from the model, so it always matches
    the code; foreign keys to shared tables resolve to public), and
  * adds any column the model has but the table lacks.
It never drops or changes a table, a column or a row. Running it twice does
nothing the second time.

It runs:
  * when a state is provisioned (apps.core.tenancy.provision_state_schema),
  * after every `migrate`, for every active state (apps.core.signals), so a
    new tab or field reaches all states, not only Maharashtra,
  * by hand: `python manage.py sync_state_schemas [--schema X] [--dry-run]`.

Adding a model?  Put its db_table in STATE_TABLES (one copy per state) or in
SHARED_TABLES (one copy in public). apps.core.test_state_schema fails until you do.
"""
import logging

from django.apps import apps as django_apps
from django.db import connection

logger = logging.getLogger(__name__)

# One copy per state, in the state's own schema
STATE_TABLES = frozenset({
    # cases and crime details
    'cases_caserecord', 'cases_person', 'case_category_links', 'case_extra_field_values',
    'crime_registration_info', 'crime_spot', 'crime_case_responsibility', 'crime_case_acts_sections',
    'case_forensics', 'cctv_technical', 'seizure_records', 'scrutiny_pipeline', 'procedural_checklist',
    'arrest_release_status', 'remand_custody', 'discharge_status', 'final_verdict',
    'preventive_action_items', 'preventive_bond',
    # modules
    'rti_applications',
    'history_sheeters', 'history_sheeter_crimes', 'history_sheeter_related_persons',
    'history_sheeter_preventive_actions',
    'mpda_proposals', 'mpda_accused_persons', 'mpda_gang_members', 'mpda_crime_chart_entries',
    'nc_records', 'nc_persons', 'nc_charges', 'nc_preventive_actions',
    'road_accident_records', 'road_accident_vehicles', 'road_accident_injured', 'road_accident_deceased',
    'muddemal_records', 'muddemal_properties', 'muddemal_property_categories',
    'muddemal_property_movements', 'muddemal_disposals', 'muddemal_fsl_records',
    'muddemal_field_definitions', 'muddemal_configs', 'muddemal_audit_logs',
    'elearning_course', 'elearning_officercourserecord',
    # people and places of the state
    'users_officerprofile', 'users_notificationrecord', 'users_transferrequest',
    'stations_policestation', 'districts', 'master_divisions', 'dynamic_ui_configs',
})

# One copy for everyone, in public
SHARED_TABLES = frozenset({
    'states', 'master_users', 'roles', 'permissions', 'role_permissions', 'user_role_mappings',
    'designations', 'app_announcements',
    'case_categories', 'case_category_groups', 'field_templates', 'field_template_fields',
    'category_field_templates', 'category_field_overrides', 'section_field_templates',
    'option_values', 'module_settings', 'acts', 'act_sections', 'act_subsections',
    'core_auditlog', 'core_sosalert',
    'auth_user', 'auth_group', 'auth_permission', 'auth_group_permissions', 'auth_user_groups',
    'auth_user_user_permissions', 'django_content_type', 'django_session', 'django_admin_log',
})

# Models whose tables were dropped on purpose (crimetab 0021); never created
RETIRED_TABLES = frozenset({'district_admins', 'super_admins'})

SYSTEM_SCHEMAS = frozenset({
    'public', 'information_schema', 'pg_catalog', 'pg_toast', 'auth', 'storage', 'realtime', 'vault',
    'extensions', 'graphql', 'graphql_public', 'supabase_functions', 'supabase_migrations', 'net',
    'cron', 'pgbouncer', 'pgsodium', 'pgsodium_masks',
})


def state_models():
    """Concrete, managed models whose table lives in each state's schema."""
    return [
        m for m in django_apps.get_models()
        if m._meta.managed and not m._meta.proxy and m._meta.db_table in STATE_TABLES
    ]


def _clean(schema_name):
    name = "".join(c for c in (schema_name or '') if c.isalnum() or c == '_').lower()
    if not name or name in SYSTEM_SCHEMAS:
        raise ValueError(f'Not a state schema: {schema_name!r}')
    return name


def _schema_columns(cursor, schema):
    """{table: {column, ...}} for every table in one schema, in one query."""
    cursor.execute("""
        SELECT c.table_name, c.column_name FROM information_schema.columns c
        JOIN information_schema.tables t ON t.table_schema = c.table_schema AND t.table_name = c.table_name
        WHERE c.table_schema = %s AND t.table_type = 'BASE TABLE'
    """, [schema])
    tables = {}
    for table, column in cursor.fetchall():
        tables.setdefault(table, set()).add(column)
    return tables


def plan_state_schema(schema_name):
    """What sync_state_schema would do: (tables to create, {table: [columns to add]})."""
    schema = _clean(schema_name)
    with connection.cursor() as cursor:
        existing = _schema_columns(cursor, schema)
    create, add = [], {}
    for model in state_models():
        table = model._meta.db_table
        if table not in existing:
            create.append(table)
            continue
        missing = [f.column for f in model._meta.local_concrete_fields if f.column not in existing[table]]
        if missing:
            add[table] = missing
    return sorted(create), add


def sync_state_schema(schema_name, dry_run=False, seed=True):
    """
    Create missing state tables and columns in one state schema (never drops anything).
    Returns {'schema', 'created': [...], 'columns_added': {table: [...]}, 'seeded': [...]}.
    """
    from apps.core.tenancy import TenantContext

    schema = _clean(schema_name)
    report = {'schema': schema, 'created': [], 'columns_added': {}, 'seeded': []}
    if connection.vendor != 'postgresql':
        return report

    if not dry_run:
        with connection.cursor() as cursor:
            cursor.execute(f'CREATE SCHEMA IF NOT EXISTS "{schema}"')

    create, add = plan_state_schema(schema)
    report['created'], report['columns_added'] = create, add
    if dry_run or (not create and not add and not seed):
        return report

    by_table = {m._meta.db_table: m for m in state_models()}
    # Unqualified names in Django's DDL go to the state schema; foreign keys to
    # shared tables resolve to public. Foreign keys are added at the end of the
    # editor block, so the order the tables are created in does not matter.
    with TenantContext(schema):
        if create or add:
            with connection.schema_editor() as editor:
                for table in create:
                    editor.create_model(by_table[table])
                for table, columns in add.items():
                    model = by_table[table]
                    for field in model._meta.local_concrete_fields:
                        if field.column in columns:
                            editor.add_field(model, field)
        if seed:
            report['seeded'] = seed_state_config()

    if create or add:
        logger.info(f"[StateSchema] {schema}: created {create or 'nothing'}, added columns {add or 'none'}")
    return report


def seed_state_config():
    """
    Starting configuration a state needs before its tabs work. Only fills a
    table that is empty, so an existing state's edited settings are never
    overwritten. Call inside TenantContext(schema).
    """
    from apps.muddemal.models import MuddemalConfig
    seeded = []
    if not MuddemalConfig.objects.exists():
        import importlib
        mig = 'apps.muddemal.migrations.'
        importlib.import_module(mig + '0002_seed_muddemal_data').seed_muddemal_initial_data(django_apps, None)
        importlib.import_module(mig + '0003_seed_ui_labels').seed_ui_labels(django_apps, None)
        importlib.import_module(mig + '0004_update_ui_labels').update_ui_labels(django_apps, None)
        # 0005's forwards() sets search_path to maharashtra, so use its data only
        for cfg in importlib.import_module(mig + '0005_muddemal_dynamic_configuration').CONFIGS:
            MuddemalConfig.objects.update_or_create(
                config_key=cfg['config_key'],
                defaults={'config_value': cfg['config_value'], 'description': cfg['description']},
            )
        seeded.append('muddemal')
    return seeded


def active_state_schemas():
    """Schema names of active states in public.states."""
    from apps.public_master.models import StateRegistry
    names = StateRegistry.objects.filter(is_active=True).exclude(schema_name__isnull=True) \
        .exclude(schema_name='').values_list('schema_name', flat=True)
    return sorted({_clean(n) for n in names})
