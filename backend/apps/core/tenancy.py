import logging
import threading
from django.db import connection

logger = logging.getLogger(__name__)

_thread_local = threading.local()


def _get_schema_stack() -> list:
    """Returns the thread-local schema stack, initializing it if not present."""
    if not hasattr(_thread_local, 'schema_stack'):
        _thread_local.schema_stack = []
    return _thread_local.schema_stack


class TenantContext:
    """
    Stack-safe Context manager for dynamically setting the PostgreSQL search_path for multi-tenancy.
    Maintains a thread-local LIFO stack so nested blocks cleanly restore outer tenant schemas on exit.
    
    Example:
        with TenantContext('kerala'):
            # search_path is 'kerala, public'
            with TenantContext('maharashtra'):
                # search_path is 'maharashtra, public'
            # search_path correctly restored to 'kerala, public'
        # search_path correctly restored to 'public'
    """

    def __init__(self, schema_name: str):
        self.target_schema = "".join(c for c in (schema_name or 'public') if c.isalnum() or c == '_').lower() or 'public'

    def __enter__(self):
        stack = _get_schema_stack()
        stack.append(self.target_schema)

        if connection.vendor != 'postgresql':
            return self

        try:
            with connection.cursor() as cursor:
                if self.target_schema != 'public':
                    cursor.execute(f'SET search_path TO "{self.target_schema}", public;')
                else:
                    cursor.execute('SET search_path TO public;')
                logger.debug(f"[Tenancy] search_path set to: {self.target_schema}, public (stack depth: {len(stack)})")
        except Exception as e:
            logger.error(f"[Tenancy] Failed to set search_path to {self.target_schema}: {e}")
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        stack = _get_schema_stack()
        if stack:
            stack.pop()
        
        # Restore to whatever is on top of the stack, or 'public' if empty
        restore_schema = stack[-1] if stack else 'public'

        if connection.vendor != 'postgresql':
            return

        try:
            with connection.cursor() as cursor:
                if restore_schema and restore_schema != 'public':
                    cursor.execute(f'SET search_path TO "{restore_schema}", public;')
                else:
                    cursor.execute('SET search_path TO public;')
                logger.debug(f"[Tenancy] Restored search_path to: {restore_schema} (stack depth: {len(stack)})")
        except Exception as e:
            logger.error(f"[Tenancy] Failed to restore search_path to {restore_schema}: {e}")


def set_tenant_schema(schema_name: str):
    """
    Sets search_path on the active database connection.
    """
    if connection.vendor != 'postgresql':
        return
    clean_schema = "".join(c for c in (schema_name or 'public') if c.isalnum() or c == '_').lower() or 'public'
    try:
        with connection.cursor() as cursor:
            if clean_schema != 'public':
                cursor.execute(f'SET search_path TO "{clean_schema}", public;')
            else:
                cursor.execute('SET search_path TO public;')
    except Exception:
        # If connection was closed or dropped by the remote pooler, reconnect cleanly
        try:
            connection.close()
            with connection.cursor() as cursor:
                if clean_schema != 'public':
                    cursor.execute(f'SET search_path TO "{clean_schema}", public;')
                else:
                    cursor.execute('SET search_path TO public;')
        except Exception as e:
            logger.warning(f"[Tenancy] Failed to set search_path to {clean_schema}: {e}")


def provision_state_schema(schema_name: str, state_code: str = None, state_name: str = None):
    """
    Provisions a new PostgreSQL schema for a state tenant.
    Creates schema and executes DDL tables (users_officerprofile, master_divisions) if not present.
    """
    if connection.vendor != 'postgresql':
        return
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
        CREATE TABLE IF NOT EXISTS "{clean_schema}".users_notificationrecord (
            id SERIAL PRIMARY KEY,
            target_role_id VARCHAR(64) DEFAULT '',
            target_station_name VARCHAR(255),
            target_district VARCHAR(128),
            target_state_code VARCHAR(10),
            target_user_uid VARCHAR(128),
            title VARCHAR(255) NOT NULL,
            body TEXT NOT NULL,
            category VARCHAR(64) DEFAULT 'approval_request',
            registration_uid VARCHAR(128),
            status VARCHAR(32) DEFAULT 'pending',
            is_read BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
        );
        CREATE TABLE IF NOT EXISTS "{clean_schema}".users_transferrequest (
            id VARCHAR(128) PRIMARY KEY,
            requested_by_uid VARCHAR(128) NOT NULL,
            officer_name VARCHAR(255) DEFAULT '',
            from_designation VARCHAR(128) DEFAULT '',
            to_designation VARCHAR(128) DEFAULT '',
            from_station_name VARCHAR(255) DEFAULT '',
            to_station_name VARCHAR(255) DEFAULT '',
            from_district VARCHAR(128) DEFAULT '',
            to_district VARCHAR(128) DEFAULT '',
            from_state VARCHAR(128) DEFAULT '',
            to_state VARCHAR(128) DEFAULT '',
            from_unit_type VARCHAR(128) DEFAULT '',
            to_unit_type VARCHAR(128) DEFAULT '',
            reason TEXT DEFAULT '',
            status VARCHAR(32) DEFAULT 'pending',
            approved_by_uid VARCHAR(128),
            rejected_by_uid VARCHAR(128),
            rejection_reason TEXT,
            approved_at TIMESTAMPTZ,
            rejected_at TIMESTAMPTZ,
            created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
        );
        """)
        logger.info(f"[Tenancy] Provisioned PostgreSQL schema & tables: {clean_schema} (State: {resolved_name}/{resolved_code})")


def get_active_tenant_schema(request=None) -> str:
    """
    Dynamically determines active tenant schema name from active TenantContext thread stack,
    request headers, or state_schema attribute.
    Logs warning if no tenant context is available and defaults to 'public'.
    """
    # 1. Explicit thread-local context (from TenantContext stack)
    stack = _get_schema_stack()
    if stack:
        return stack[-1]

    # 2. Request attributes & headers
    if request:
        schema = getattr(request, 'state_schema', None)
        if not schema and hasattr(request, 'META'):
            schema = request.META.get('HTTP_X_TENANT_SCHEMA') or request.META.get('HTTP_X_STATE_SCHEMA')
        if schema:
            return schema

    logger.warning("[Tenancy] No active tenant context or request header found; falling back to 'public'")
    return 'public'


