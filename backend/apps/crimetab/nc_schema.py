"""
DDL for the N.C. (Non-Cognizable) tenant tables.

Single source used by migration 0054 (existing active states) and by
apps.core.tenancy.provision_state_schema (new states). Records live only in a
state's own schema; the form definition lives only in public.

Do not change this DDL for an existing column: add a new migration instead.
"""
import re

_SCHEMA_RE = re.compile(r'^[a-z_][a-z0-9_]*$')

NC_TABLE_NAMES = ('nc_records', 'nc_persons', 'nc_charges', 'nc_preventive_actions')

# {s} is replaced by the double-quoted schema name. No '%' characters, so the
# statements are safe for cursor.execute without parameters.
NC_TENANT_DDL = [
    # One row per N.C.; station_name scopes every read to the user's unit.
    """
    CREATE TABLE IF NOT EXISTS {s}.nc_records (
        id BIGSERIAL PRIMARY KEY,
        station_name VARCHAR(255) NOT NULL,
        nc_no VARCHAR(100),
        registered_date DATE,
        spot_village VARCHAR(255),
        spot_area VARCHAR(255),
        spot_address TEXT,
        occurrence_at TIMESTAMPTZ,
        io_name VARCHAR(255),
        io_designation VARCHAR(255),
        io_mobile VARCHAR(10) CHECK (io_mobile IS NULL OR io_mobile ~ '^[0-9]{10}$'),
        reg_name VARCHAR(255),
        reg_designation VARCHAR(255),
        reg_mobile VARCHAR(10) CHECK (reg_mobile IS NULL OR reg_mobile ~ '^[0-9]{10}$'),
        first_information TEXT,
        post_crime_registered VARCHAR(100),
        post_crime_no VARCHAR(100),
        post_act TEXT,
        post_section TEXT,
        legacy_case_id VARCHAR(128) UNIQUE,
        created_by VARCHAR(128),
        created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
    """,
    # Keyset list per station: ORDER BY registered_date DESC NULLS LAST, id DESC
    """
    CREATE INDEX IF NOT EXISTS nc_records_station_regdate_idx
        ON {s}.nc_records (station_name, registered_date DESC NULLS LAST, id DESC)
    """,
    # Complainants and Non applicants (any number of each).
    """
    CREATE TABLE IF NOT EXISTS {s}.nc_persons (
        id BIGSERIAL PRIMARY KEY,
        nc_id BIGINT NOT NULL REFERENCES {s}.nc_records(id) ON DELETE CASCADE,
        person_type VARCHAR(20) NOT NULL CHECK (person_type IN ('complainant', 'non_applicant')),
        display_order SMALLINT NOT NULL DEFAULT 0,
        name VARCHAR(255),
        age SMALLINT CHECK (age IS NULL OR (age >= 1 AND age <= 120)),
        gender VARCHAR(50),
        caste VARCHAR(255),
        profession VARCHAR(255),
        mobile VARCHAR(10) CHECK (mobile IS NULL OR mobile ~ '^[0-9]{10}$'),
        address TEXT,
        aadhaar VARCHAR(20)
    )
    """,
    # Load one page's persons in one query, already grouped and ordered.
    """
    CREATE INDEX IF NOT EXISTS nc_persons_nc_type_order_idx
        ON {s}.nc_persons (nc_id, person_type, display_order)
    """,
    # Act / Section / Subsection as text copies; ids kept WITHOUT foreign keys so
    # replacing the public Acts data never changes or deletes a saved charge.
    """
    CREATE TABLE IF NOT EXISTS {s}.nc_charges (
        id BIGSERIAL PRIMARY KEY,
        nc_id BIGINT NOT NULL REFERENCES {s}.nc_records(id) ON DELETE CASCADE,
        display_order SMALLINT NOT NULL DEFAULT 0,
        act_id BIGINT,
        section_id BIGINT,
        subsection_id BIGINT,
        act_name TEXT,
        section_number TEXT,
        section_title TEXT,
        subsection_code TEXT
    )
    """,
    """
    CREATE INDEX IF NOT EXISTS nc_charges_nc_idx ON {s}.nc_charges (nc_id)
    """,
    # Preventive rows; person_id may only point to a Non applicant (enforced by
    # the API). Provision is text validated against option_values, no FK.
    """
    CREATE TABLE IF NOT EXISTS {s}.nc_preventive_actions (
        id BIGSERIAL PRIMARY KEY,
        nc_id BIGINT NOT NULL REFERENCES {s}.nc_records(id) ON DELETE CASCADE,
        person_id BIGINT REFERENCES {s}.nc_persons(id) ON DELETE CASCADE,
        display_order SMALLINT NOT NULL DEFAULT 0,
        provision VARCHAR(100),
        action_date DATE,
        outward_number VARCHAR(100),
        bond_date DATE,
        bond_cancellation_date DATE,
        preventive_number VARCHAR(100)
    )
    """,
    # Disposal EXISTS / NOT EXISTS checks and the page load scan by nc_id.
    """
    CREATE INDEX IF NOT EXISTS nc_prev_nc_idx ON {s}.nc_preventive_actions (nc_id)
    """,
    # ON DELETE CASCADE from nc_persons and person lookups per N.C.
    """
    CREATE INDEX IF NOT EXISTS nc_prev_nc_person_idx ON {s}.nc_preventive_actions (nc_id, person_id)
    """,
    # Added by migration 0124 (Outward Date after Outward Number)
    """
    ALTER TABLE {s}.nc_preventive_actions ADD COLUMN IF NOT EXISTS outward_date DATE
    """,
]


def quote_schema(schema_name: str) -> str:
    """Validated, double-quoted schema identifier; raises on anything unexpected."""
    name = (schema_name or '').strip()
    if not _SCHEMA_RE.match(name):
        raise ValueError(f'Invalid schema name: {schema_name!r}')
    return f'"{name}"'


def create_nc_tables(cursor, schema_name: str) -> None:
    """Create the N.C. tables and indexes in one existing schema (idempotent)."""
    s = quote_schema(schema_name)
    for stmt in NC_TENANT_DDL:
        # replace(), not format(): the regex checks contain literal braces
        cursor.execute(stmt.replace('{s}', s))
