import logging

from django.db import connections

logger = logging.getLogger(__name__)


def sync_states_after_migrate(sender, using='default', **kwargs):
    """
    After `migrate`, give every active state the tables and columns Maharashtra
    just got (Django creates them only in the first schema of the search_path).
    Connected with sender=CoreConfig, so it runs once per migrate.
    """
    if using != 'default' or connections[using].vendor != 'postgresql':
        return
    from apps.core.state_schema import active_state_schemas, sync_state_schema
    try:
        schemas = active_state_schemas()
    except Exception as e:  # public.states not created yet (first migrate of a fresh database)
        logger.info(f'[StateSchema] Skipped state sync: {e}')
        return
    verbosity = kwargs.get('verbosity', 1)
    for schema in schemas:
        report = sync_state_schema(schema)
        if verbosity and (report['created'] or report['columns_added'] or report['seeded']):
            print(f"  State schema {schema}: created {len(report['created'])} tables, "
                  f"added columns to {len(report['columns_added'])} tables, seeded {report['seeded'] or 'nothing'}")
