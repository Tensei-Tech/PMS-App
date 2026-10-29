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
        create_module_tables(cursor, clean_schema)
    logger.info(f"[Tenancy] Provisioned PostgreSQL schema & tables: {clean_schema} (State: {resolved_name}/{resolved_code})")


def create_module_tables(cursor, clean_schema: str):
    """RTI, History Sheeter, MPDA and N.C. tables of one tenant schema. Idempotent."""
    cursor.execute(f"""
        CREATE TABLE IF NOT EXISTS "{clean_schema}".rti_applications (
            rti_id BIGSERIAL PRIMARY KEY,
            station_name VARCHAR(255) NOT NULL,
            serial_year SMALLINT NOT NULL,
            serial_no INTEGER NOT NULL,
            applicant_name VARCHAR(255),
            applicant_age SMALLINT CHECK (applicant_age BETWEEN 1 AND 999),
            mobile_no VARCHAR(10) CHECK (mobile_no ~ '^[0-9]{{10}}$'),
            address TEXT,
            email VARCHAR(254),
            received_date DATE,
            due_date DATE,
            replied_date DATE,
            rejected_date DATE,
            rejection_reason TEXT,
            transferred_to TEXT,
            transferred_date DATE,
            info_type VARCHAR(50),
            info_type_other VARCHAR(50),
            assigned_officer_uid VARCHAR(128),
            assigned_officer_name VARCHAR(255),
            assigned_officer_designation VARCHAR(128),
            mode_of_receipt VARCHAR(50),
            is_bpl BOOLEAN NOT NULL DEFAULT FALSE,
            remark TEXT,
            appealed BOOLEAN NOT NULL DEFAULT FALSE,
            appeal_date DATE,
            status VARCHAR(10) GENERATED ALWAYS AS (
                CASE WHEN replied_date IS NOT NULL OR rejected_date IS NOT NULL
                     OR length(trim(coalesce(transferred_to,''))) > 0
                THEN 'Disposal' ELSE 'Pending' END) STORED,
            created_by VARCHAR(128),
            created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT rti_serial_unique UNIQUE (station_name, serial_year, serial_no),
            CONSTRAINT rti_due_after_received CHECK (due_date IS NULL OR received_date IS NULL OR due_date >= received_date),
            CONSTRAINT rti_one_outcome CHECK (
                (CASE WHEN replied_date IS NOT NULL THEN 1 ELSE 0 END
               + CASE WHEN rejected_date IS NOT NULL THEN 1 ELSE 0 END
               + CASE WHEN length(trim(coalesce(transferred_to,''))) > 0 THEN 1 ELSE 0 END) <= 1),
            CONSTRAINT rti_reject_reason CHECK (
                (rejected_date IS NULL AND rejection_reason IS NULL)
             OR (rejected_date IS NOT NULL AND length(trim(coalesce(rejection_reason,''))) > 0)),
            CONSTRAINT rti_appeal_rule CHECK (
                (appealed AND appeal_date IS NOT NULL) OR (NOT appealed AND appeal_date IS NULL))
        );
        CREATE INDEX IF NOT EXISTS rti_station_status_idx
            ON "{clean_schema}".rti_applications (station_name, status);

        CREATE TABLE IF NOT EXISTS "{clean_schema}".history_sheeters (
            id BIGSERIAL PRIMARY KEY,
            station_name VARCHAR(255) NOT NULL,
            sr_no BIGINT NOT NULL,
            name VARCHAR(255),
            alias VARCHAR(255),
            nickname VARCHAR(255),
            age INT CHECK (age IS NULL OR (age >= 1 AND age <= 999)),
            gender VARCHAR(50),
            mobile_no VARCHAR(10) CHECK (mobile_no IS NULL OR mobile_no ~ '^[0-9]{{10}}$'),
            address TEXT,
            history_sheet_no VARCHAR(100),
            opening_date DATE,
            order_date DATE,
            permanent_address TEXT,
            present_address TEXT,
            same_as_above BOOLEAN DEFAULT FALSE,
            native_place VARCHAR(255),
            occupation VARCHAR(255),
            aadhaar_id_details VARCHAR(255),
            categories TEXT[],
            category_other VARCHAR(255),
            modus_operandi TEXT,
            total_cases INT,
            convicted_cases INT,
            pending_cases INT,
            acquitted_discharged_cases INT,
            whereabouts TEXT,
            last_verification_date DATE,
            verification_remarks TEXT,
            closure_date DATE,
            closure_reason VARCHAR(255),
            closure_remarks TEXT,
            currently_in_jail VARCHAR(10),
            currently_on_bail VARCHAR(10),
            created_by VARCHAR(100),
            created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT uq_history_sheeter_station_sr_no UNIQUE (station_name, sr_no)
        );
        CREATE INDEX IF NOT EXISTS hs_station_sr_idx ON "{clean_schema}".history_sheeters (station_name, sr_no);

        CREATE TABLE IF NOT EXISTS "{clean_schema}".history_sheeter_related_persons (
            id BIGSERIAL PRIMARY KEY,
            history_sheeter_id BIGINT NOT NULL REFERENCES "{clean_schema}".history_sheeters(id) ON DELETE CASCADE,
            person_type VARCHAR(20) NOT NULL CHECK (person_type IN ('associate', 'rival', 'surety')),
            name VARCHAR(255),
            alias VARCHAR(255),
            nickname VARCHAR(255),
            age INT CHECK (age IS NULL OR (age >= 1 AND age <= 999)),
            gender VARCHAR(50),
            mobile_no VARCHAR(10) CHECK (mobile_no IS NULL OR mobile_no ~ '^[0-9]{{10}}$'),
            address TEXT,
            created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
        );
        CREATE INDEX IF NOT EXISTS hs_rel_person_hs_idx ON "{clean_schema}".history_sheeter_related_persons (history_sheeter_id, person_type);

        CREATE TABLE IF NOT EXISTS "{clean_schema}".history_sheeter_preventive_actions (
            id BIGSERIAL PRIMARY KEY,
            history_sheeter_id BIGINT NOT NULL REFERENCES "{clean_schema}".history_sheeters(id) ON DELETE CASCADE,
            action_type VARCHAR(100),
            action_other VARCHAR(255),
            created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
        );
        CREATE INDEX IF NOT EXISTS hs_prev_hs_idx ON "{clean_schema}".history_sheeter_preventive_actions (history_sheeter_id);

        CREATE TABLE IF NOT EXISTS "{clean_schema}".history_sheeter_crimes (
            id BIGSERIAL PRIMARY KEY,
            history_sheeter_id BIGINT NOT NULL REFERENCES "{clean_schema}".history_sheeters(id) ON DELETE CASCADE,
            cr_no VARCHAR(100),
            crime_head TEXT,
            act_section TEXT,
            register_date DATE,
            police_station VARCHAR(255),
            created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
        );
        CREATE INDEX IF NOT EXISTS hs_crimes_hs_idx ON "{clean_schema}".history_sheeter_crimes (history_sheeter_id);
        CREATE INDEX IF NOT EXISTS hs_crimes_reg_date_idx ON "{clean_schema}".history_sheeter_crimes (register_date);
        ALTER TABLE "{clean_schema}".history_sheeter_crimes
            ADD COLUMN IF NOT EXISTS act_id BIGINT,
            ADD COLUMN IF NOT EXISTS section_id BIGINT,
            ADD COLUMN IF NOT EXISTS subsection_id BIGINT,
            ADD COLUMN IF NOT EXISTS act_name TEXT,
            ADD COLUMN IF NOT EXISTS section_number TEXT,
            ADD COLUMN IF NOT EXISTS section_title TEXT,
            ADD COLUMN IF NOT EXISTS subsection_code TEXT;

        CREATE TABLE IF NOT EXISTS "{clean_schema}".mpda_proposals (
            id BIGSERIAL PRIMARY KEY,
            station_name VARCHAR(255) NOT NULL,
            proposal_no_and_year VARCHAR(100),
            accused_name VARCHAR(255),
            accused_aadhaar VARCHAR(50),
            accused_mobile VARCHAR(10) CHECK (accused_mobile IS NULL OR accused_mobile ~ '^[0-9]{{10}}$'),
            accused_address TEXT,
            accused_age INT CHECK (accused_age IS NULL OR (accused_age >= 1 AND accused_age <= 999)),
            accused_gender VARCHAR(50),
            io_uid VARCHAR(100),
            io_name VARCHAR(255),
            io_post VARCHAR(100),
            proposal_outcome VARCHAR(20),
            granted_date DATE,
            rejected_date DATE,
            detaining_authority VARCHAR(50),
            detaining_authority_other VARCHAR(255),
            detained VARCHAR(10),
            detention_date DATE,
            detention_completion_date DATE,
            jail_name VARCHAR(255),
            transfer_jail_name VARCHAR(255),
            government_confirmation VARCHAR(10),
            govt_confirmation_date DATE,
            detention_order_revoked VARCHAR(10),
            order_revoked_date DATE,
            mpda_category VARCHAR(100),
            mpda_category_other VARCHAR(255),
            total_crime INT,
            serious_crimes INT,
            total_misc_crime INT,
            created_by VARCHAR(100),
            created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
            CONSTRAINT chk_mpda_outcome_dates CHECK (
                (proposal_outcome = 'Granted' AND rejected_date IS NULL) OR
                (proposal_outcome = 'Rejected' AND granted_date IS NULL) OR
                ((proposal_outcome IS NULL OR proposal_outcome = '') AND granted_date IS NULL AND rejected_date IS NULL)
            )
        );
        CREATE INDEX IF NOT EXISTS mpda_station_outcome_idx ON "{clean_schema}".mpda_proposals (station_name, proposal_outcome);
        ALTER TABLE "{clean_schema}".mpda_proposals
            ADD COLUMN IF NOT EXISTS proposal_no VARCHAR(50),
            ADD COLUMN IF NOT EXISTS proposal_year VARCHAR(10),
            ADD COLUMN IF NOT EXISTS proposal_revoked VARCHAR(10),
            ADD COLUMN IF NOT EXISTS proposal_revoked_date DATE;

        CREATE TABLE IF NOT EXISTS "{clean_schema}".mpda_accused_persons (
            id BIGSERIAL PRIMARY KEY,
            proposal_id BIGINT NOT NULL REFERENCES "{clean_schema}".mpda_proposals(id) ON DELETE CASCADE,
            display_order SMALLINT DEFAULT 1,
            name VARCHAR(255),
            age INT CHECK (age IS NULL OR (age >= 1 AND age <= 999)),
            gender VARCHAR(50),
            occupation VARCHAR(255),
            mobile VARCHAR(10) CHECK (mobile IS NULL OR mobile = '' OR mobile ~ '^[0-9]{{10}}$'),
            aadhaar VARCHAR(50),
            pan VARCHAR(50),
            "cast" VARCHAR(100),
            religion VARCHAR(100),
            address TEXT,
            created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
        );
        CREATE INDEX IF NOT EXISTS mpda_accused_prop_idx ON "{clean_schema}".mpda_accused_persons (proposal_id);

        CREATE TABLE IF NOT EXISTS "{clean_schema}".mpda_gang_members (
            id BIGSERIAL PRIMARY KEY,
            proposal_id BIGINT NOT NULL REFERENCES "{clean_schema}".mpda_proposals(id) ON DELETE CASCADE,
            name VARCHAR(255),
            display_order SMALLINT DEFAULT 1,
            created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
        );
        CREATE INDEX IF NOT EXISTS mpda_gang_prop_idx ON "{clean_schema}".mpda_gang_members (proposal_id);
        ALTER TABLE "{clean_schema}".mpda_gang_members
            ADD COLUMN IF NOT EXISTS age INT CHECK (age IS NULL OR (age >= 1 AND age <= 999)),
            ADD COLUMN IF NOT EXISTS gender VARCHAR(50),
            ADD COLUMN IF NOT EXISTS occupation VARCHAR(255),
            ADD COLUMN IF NOT EXISTS mobile VARCHAR(10) CHECK (mobile IS NULL OR mobile = '' OR mobile ~ '^[0-9]{{10}}$'),
            ADD COLUMN IF NOT EXISTS aadhaar VARCHAR(50),
            ADD COLUMN IF NOT EXISTS pan VARCHAR(50),
            ADD COLUMN IF NOT EXISTS "cast" VARCHAR(100),
            ADD COLUMN IF NOT EXISTS religion VARCHAR(100),
            ADD COLUMN IF NOT EXISTS address TEXT;

        CREATE TABLE IF NOT EXISTS "{clean_schema}".mpda_crime_chart_entries (
            id BIGSERIAL PRIMARY KEY,
            proposal_id BIGINT NOT NULL REFERENCES "{clean_schema}".mpda_proposals(id) ON DELETE CASCADE,
            crime_type VARCHAR(100),
            cr_no VARCHAR(100),
            crime_date DATE,
            police_station VARCHAR(255),
            created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
        );
        CREATE INDEX IF NOT EXISTS mpda_crime_prop_idx ON "{clean_schema}".mpda_crime_chart_entries (proposal_id);
        ALTER TABLE "{clean_schema}".mpda_crime_chart_entries
            ADD COLUMN IF NOT EXISTS act_id BIGINT,
            ADD COLUMN IF NOT EXISTS section_id BIGINT,
            ADD COLUMN IF NOT EXISTS subsection_id BIGINT,
            ADD COLUMN IF NOT EXISTS act_name TEXT,
            ADD COLUMN IF NOT EXISTS section_number TEXT,
            ADD COLUMN IF NOT EXISTS section_title TEXT,
            ADD COLUMN IF NOT EXISTS subsection_code TEXT,
            ADD COLUMN IF NOT EXISTS act_section TEXT;
        """)

    # N.C. tables (same DDL as migration 0054)
    from apps.crimetab.nc_schema import create_nc_tables
    create_nc_tables(cursor, clean_schema)


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


