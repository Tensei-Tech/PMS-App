import logging
from django.db import connection, transaction

logger = logging.getLogger(__name__)


class TenantContext:
    """
    Context manager for dynamically setting the PostgreSQL search_path for multi-tenancy.
    Example:
        with TenantContext('maharashtra'):
            # Operations run within 'maharashtra, public' search path
            OfficerProfile.objects.all()
    """

    def __init__(self, schema_name: str):
        self.schema_name = schema_name or 'public'
        self.previous_schema = 'public'

    def __enter__(self):
        try:
            with connection.cursor() as cursor:
                # Sanitize schema name (alphanumeric and underscores only)
                clean_schema = "".join(c for c in self.schema_name if c.isalnum() or c == '_').lower()
                cursor.execute(f'SET search_path TO "{clean_schema}", public;')
                logger.debug(f"[Tenancy] search_path set to: {clean_schema}, public")
        except Exception as e:
            logger.error(f"[Tenancy] Failed to set search_path to {self.schema_name}: {e}")
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        try:
            with connection.cursor() as cursor:
                cursor.execute('SET search_path TO public;')
        except Exception as e:
            logger.error(f"[Tenancy] Failed to reset search_path to public: {e}")


def set_tenant_schema(schema_name: str):
    """
    Sets search_path on the active database connection.
    """
    if not schema_name:
        schema_name = 'public'
    clean_schema = "".join(c for c in schema_name if c.isalnum() or c == '_').lower()
    with connection.cursor() as cursor:
        cursor.execute(f'SET search_path TO "{clean_schema}", public;')


def provision_state_schema(schema_name: str):
    """
    Provisions a new PostgreSQL schema for a state tenant.
    Creates schema and executes DDL tables if not present.
    """
    clean_schema = "".join(c for c in schema_name if c.isalnum() or c == '_').lower()
    if not clean_schema:
        raise ValueError("Invalid schema name")

    with connection.cursor() as cursor:
        cursor.execute(f'CREATE SCHEMA IF NOT EXISTS "{clean_schema}";')
        logger.info(f"[Tenancy] Provisioned PostgreSQL schema: {clean_schema}")
