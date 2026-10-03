import logging
import threading
from django.db import connection, transaction

logger = logging.getLogger(__name__)

_thread_local = threading.local()


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
        self.previous_schema = getattr(_thread_local, 'tenant_schema', 'public')

    def __enter__(self):
        try:
            clean_schema = "".join(c for c in self.schema_name if c.isalnum() or c == '_').lower()
            _thread_local.tenant_schema = clean_schema
            with connection.cursor() as cursor:
                cursor.execute(f'SET search_path TO "{clean_schema}", public;')
                logger.debug(f"[Tenancy] search_path set to: {clean_schema}, public")
        except Exception as e:
            logger.error(f"[Tenancy] Failed to set search_path to {self.schema_name}: {e}")
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        try:
            _thread_local.tenant_schema = self.previous_schema
            clean_prev = "".join(c for c in self.previous_schema if c.isalnum() or c == '_').lower() if self.previous_schema else 'public'
            with connection.cursor() as cursor:
                if clean_prev and clean_prev != 'public':
                    cursor.execute(f'SET search_path TO "{clean_prev}", public;')
                else:
                    cursor.execute('SET search_path TO public;')
        except Exception as e:
            logger.error(f"[Tenancy] Failed to reset search_path to {self.previous_schema}: {e}")


def set_tenant_schema(schema_name: str):
    """
    Sets search_path on the active database connection.
    """
    if not schema_name:
        schema_name = 'public'
    clean_schema = "".join(c for c in schema_name if c.isalnum() or c == '_').lower()
    _thread_local.tenant_schema = clean_schema
    with connection.cursor() as cursor:
        cursor.execute(f'SET search_path TO "{clean_schema}", public;')


def provision_state_schema(schema_name: str, state_code: str = None, state_name: str = None):
    """
    Provisions a new PostgreSQL schema for a state tenant.
    Creates schema and executes DDL tables (users_officerprofile, master_divisions) if not present.
    """
    clean_schema = "".join(c for c in schema_name if c.isalnum() or c == '_').lower()
    if not clean_schema:
        raise ValueError("Invalid schema name")

    if not state_code or not state_name:
        try:
            from apps.public_master.models import StateRegistry
            reg = StateRegistry.objects.filter(schema_name=clean_schema).first()
            if reg:
                state_code = state_code or reg.state_code
                state_name = state_name or reg.state_name
        except Exception:
            pass

    resolved_code = (state_code or clean_schema[:2].upper())[:10]
    resolved_name = state_name or clean_schema.replace('_', ' ').title()

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
        CREATE TABLE IF NOT EXISTS "{clean_schema}".master_divisions (
            id BIGSERIAL PRIMARY KEY,
            state_code VARCHAR(10) NOT NULL DEFAULT '{resolved_code}',
            state_name VARCHAR(100) NOT NULL DEFAULT '{resolved_name}',
            name VARCHAR(128) NOT NULL,
            code VARCHAR(64),
            created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT "{clean_schema}_master_divisions_state_name_uniq" UNIQUE (state_code, name)
        );
        """)
        logger.info(f"[Tenancy] Provisioned PostgreSQL schema & tables: {clean_schema} (State: {resolved_name}/{resolved_code})")


def get_active_tenant_schema(request=None) -> str:
    """
    Dynamically determines active tenant schema name from active TenantContext thread context,
    request headers, state_schema attribute, or active StateRegistry in DB.
    """
    # 1. Active TenantContext in current thread
    current = getattr(_thread_local, 'tenant_schema', None)
    if current and current != 'public':
        return current

    # 2. Request attributes & headers
    if request:
        schema = getattr(request, 'state_schema', None)
        if not schema and hasattr(request, 'META'):
            schema = request.META.get('HTTP_X_TENANT_SCHEMA') or request.META.get('HTTP_X_STATE_SCHEMA')
        if schema and schema != 'public':
            return schema

    # 3. Fallback to active StateRegistry in DB
    try:
        from apps.public_master.models import StateRegistry
        state = StateRegistry.objects.filter(is_active=True).first()
        if state and state.schema_name:
            return state.schema_name
    except Exception:
        pass

    return 'public'

