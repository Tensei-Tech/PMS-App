"""
DDL for the Road Accident tenant tables.

Used by apps.core.tenancy.provision_state_schema, so a new state gets the same
four tables that existing states got from migrations 0056 + 0102 + 0174:
road_accident_records, _vehicles, _injured and _deceased, with case_id linked
to the state's cases_caserecord (ON DELETE CASCADE, one record per case).

Columns match the shared database exactly. Do not change this DDL for an
existing column: add a new migration, then update this file to match it.
"""
from apps.crimetab.nc_schema import quote_schema

ROAD_ACCIDENT_TABLE_NAMES = (
    'road_accident_records', 'road_accident_vehicles', 'road_accident_injured', 'road_accident_deceased',
)

# Constraint names are the ones migration 0174 adds, so both paths agree
CASE_FK_NAMES = {table: f'{table}_case_id_fk' for table in ROAD_ACCIDENT_TABLE_NAMES}
CASE_UNIQUE_NAME = 'road_accident_records_case_id_uniq'

# {s} is replaced by the double-quoted schema name. No '%' characters, so the
# statements are safe for cursor.execute without parameters.
ROAD_ACCIDENT_TENANT_DDL = [
    """
    CREATE TABLE IF NOT EXISTS {s}.road_accident_records (
        id BIGSERIAL PRIMARY KEY,
        case_id VARCHAR(128),
        station_id BIGINT,
        station_name VARCHAR(255),
        nature_of_accident VARCHAR(100),
        nature_of_accident_other VARCHAR(255),
        vehicle_abandoned VARCHAR(10),
        driver_subsequently_traced VARCHAR(10),
        victim_identity_established VARCHAR(10),
        eye_witnesses_identity VARCHAR(10),
        irad VARCHAR(10),
        irad_date DATE,
        dar VARCHAR(10),
        dar_date DATE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
        accident_datetime TIMESTAMPTZ,
        accident_spot TEXT
    )
    """,
    "CREATE INDEX IF NOT EXISTS road_acc_station_idx ON {s}.road_accident_records (station_name)",
    """
    CREATE TABLE IF NOT EXISTS {s}.road_accident_vehicles (
        id BIGSERIAL PRIMARY KEY,
        accident_record_id BIGINT NOT NULL REFERENCES {s}.road_accident_records(id) ON DELETE CASCADE,
        case_id VARCHAR(128),
        display_order SMALLINT DEFAULT 1,
        vehicle_number VARCHAR(100),
        vehicle_name VARCHAR(100),
        company_name VARCHAR(100),
        company_name_other VARCHAR(100),
        model VARCHAR(100),
        owner_name_address TEXT,
        driver_name_address TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
    """,
    "CREATE INDEX IF NOT EXISTS road_acc_veh_rec_idx ON {s}.road_accident_vehicles (accident_record_id)",
    "CREATE INDEX IF NOT EXISTS road_acc_veh_case_idx ON {s}.road_accident_vehicles (case_id)",
    """
    CREATE TABLE IF NOT EXISTS {s}.road_accident_injured (
        id BIGSERIAL PRIMARY KEY,
        accident_record_id BIGINT NOT NULL REFERENCES {s}.road_accident_records(id) ON DELETE CASCADE,
        case_id VARCHAR(128),
        display_order SMALLINT DEFAULT 1,
        name VARCHAR(255),
        age INT,
        gender VARCHAR(50),
        address TEXT,
        occupation VARCHAR(255),
        mobile_no VARCHAR(20),
        aadhaar_card VARCHAR(50),
        pan_card VARCHAR(50),
        caste VARCHAR(100),
        religion VARCHAR(100),
        death VARCHAR(10),
        death_date DATE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
    """,
    "CREATE INDEX IF NOT EXISTS road_acc_inj_rec_idx ON {s}.road_accident_injured (accident_record_id)",
    "CREATE INDEX IF NOT EXISTS road_acc_inj_case_idx ON {s}.road_accident_injured (case_id)",
    """
    CREATE TABLE IF NOT EXISTS {s}.road_accident_deceased (
        id BIGSERIAL PRIMARY KEY,
        accident_record_id BIGINT NOT NULL REFERENCES {s}.road_accident_records(id) ON DELETE CASCADE,
        case_id VARCHAR(128),
        display_order SMALLINT DEFAULT 1,
        name VARCHAR(255),
        age INT,
        gender VARCHAR(50),
        address TEXT,
        occupation VARCHAR(255),
        mobile_no VARCHAR(20),
        aadhaar_card VARCHAR(50),
        pan_card VARCHAR(50),
        caste VARCHAR(100),
        religion VARCHAR(100),
        post_mortem VARCHAR(10),
        pm_report_received VARCHAR(10),
        viscera_sent_fsl VARCHAR(10),
        fsl_report_received VARCHAR(10),
        created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
    """,
    "CREATE INDEX IF NOT EXISTS road_acc_dec_rec_idx ON {s}.road_accident_deceased (accident_record_id)",
    "CREATE INDEX IF NOT EXISTS road_acc_dec_case_idx ON {s}.road_accident_deceased (case_id)",
]


def _has_constraint(cursor, schema_name, table, name):
    cursor.execute("""
        SELECT 1 FROM pg_constraint c
        JOIN pg_class t ON t.oid = c.conrelid JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE n.nspname = %s AND t.relname = %s AND c.conname = %s
    """, [schema_name, table, name])
    return cursor.fetchone() is not None


def _has_table(cursor, schema_name, table):
    cursor.execute('SELECT 1 FROM information_schema.tables WHERE table_schema = %s AND table_name = %s',
                   [schema_name, table])
    return cursor.fetchone() is not None


def link_road_accident_cases(cursor, schema_name: str) -> bool:
    """
    Add the case_id foreign keys and the one-record-per-case rule (idempotent).
    Needs the schema's cases_caserecord; returns False and adds nothing without it.
    """
    s = quote_schema(schema_name)
    if not _has_table(cursor, schema_name, 'cases_caserecord'):
        return False
    for table, fk in CASE_FK_NAMES.items():
        if not _has_constraint(cursor, schema_name, table, fk):
            cursor.execute(
                f'ALTER TABLE {s}.{table} ADD CONSTRAINT {fk} FOREIGN KEY (case_id) '
                f'REFERENCES {s}.cases_caserecord(id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED'
            )
    if not _has_constraint(cursor, schema_name, 'road_accident_records', CASE_UNIQUE_NAME):
        cursor.execute(f'ALTER TABLE {s}.road_accident_records ADD CONSTRAINT {CASE_UNIQUE_NAME} UNIQUE (case_id)')
    return True


def create_road_accident_tables(cursor, schema_name: str) -> None:
    """Create the four Road Accident tables, indexes and case links in one existing schema (idempotent)."""
    s = quote_schema(schema_name)
    for stmt in ROAD_ACCIDENT_TENANT_DDL:
        cursor.execute(stmt.replace('{s}', s))
    link_road_accident_cases(cursor, schema_name)
