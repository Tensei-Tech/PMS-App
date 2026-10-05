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
        if connection.vendor != 'postgresql':
            return self
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
        if connection.vendor != 'postgresql':
            return
        try:
            with connection.cursor() as cursor:
                cursor.execute('SET search_path TO public;')
        except Exception as e:
            logger.error(f"[Tenancy] Failed to reset search_path to public: {e}")


def set_tenant_schema(schema_name: str):
    """
    Sets search_path on the active database connection.
    """
    if connection.vendor != 'postgresql':
        return
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
    if connection.vendor != 'postgresql':
        return
    clean_schema = "".join(c for c in schema_name if c.isalnum() or c == '_').lower()
    if not clean_schema:
        raise ValueError("Invalid schema name")

    with connection.cursor() as cursor:
        cursor.execute(f'CREATE SCHEMA IF NOT EXISTS "{clean_schema}";')
        cursor.execute(f"""
        CREATE TABLE IF NOT EXISTS "{clean_schema}".users_officerprofile (
            uid VARCHAR(128) PRIMARY KEY,
            name VARCHAR(255),
            password VARCHAR(128),
            badge_number VARCHAR(64),
            designation VARCHAR(128),
            email VARCHAR(255) UNIQUE,
            phone VARCHAR(32),
            station_name VARCHAR(255),
            station_id VARCHAR(64),
            station_address TEXT,
            station_landline VARCHAR(32),
            govt_id VARCHAR(64),
            photo_url VARCHAR(1024),
            id_card_url VARCHAR(1024),
            role_id VARCHAR(64) DEFAULT 'officer',
            additional_stations JSONB DEFAULT '[]'::jsonb,
            account_status VARCHAR(32) DEFAULT 'active',
            division_name VARCHAR(128),
            division_id VARCHAR(64),
            district VARCHAR(128),
            district_id VARCHAR(64),
            zone VARCHAR(128),
            age INT,
            gender VARCHAR(20),
            station_case_view_granted BOOLEAN DEFAULT FALSE,
            is_biometric_enabled BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
        );
        ALTER TABLE "{clean_schema}".users_officerprofile ADD COLUMN IF NOT EXISTS division_name VARCHAR(128);
        ALTER TABLE "{clean_schema}".users_officerprofile ADD COLUMN IF NOT EXISTS division_id VARCHAR(64);
        ALTER TABLE "{clean_schema}".users_officerprofile ADD COLUMN IF NOT EXISTS is_biometric_enabled BOOLEAN DEFAULT FALSE;
        """)
        logger.info(f"[Tenancy] Provisioned PostgreSQL schema & tables: {clean_schema}")


def get_active_tenant_schema(request=None) -> str:
    """
    Dynamically determines active tenant schema name from request headers, state_schema attribute,
    or active StateRegistry in DB. Never relies on hardcoded schema names.
    """
    if request:
        schema = getattr(request, 'state_schema', None)
        if not schema and hasattr(request, 'META'):
            schema = request.META.get('HTTP_X_TENANT_SCHEMA') or request.META.get('HTTP_X_STATE_SCHEMA')
        if schema and schema != 'public':
            return schema
    try:
        from apps.public_master.models import StateRegistry
        state = StateRegistry.objects.filter(is_active=True).first()
        if state and state.schema_name:
            return state.schema_name
    except Exception:
        pass
    return 'public'

