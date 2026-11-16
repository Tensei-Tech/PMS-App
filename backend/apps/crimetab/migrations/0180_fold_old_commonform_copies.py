import json

from django.db import migrations

"""
Migration 0180: fold the old commonForm copies (step A6)

Since step A5, saving a case moves the answers that only the commonForm copy
holds to the top level of extra_fields and drops the copy. This does the same,
once, for the cases saved before that and not edited since (97 on the shared
database when written; their JSON shrinks from 1.44 MB to 0.68 MB, and a
read-only check showed no answer the form shows changes).

Each copy is first saved, unchanged, in <schema>.cases_commonform_backup
(case_id, common_form, common_form_alt, folded_at). Going back puts the copies
back into extra_fields from there; the answers moved to the top level stay.
The backup table can be dropped once the team is happy.

The fold rule is frozen here (same as apps/cases/common_form_copy.py when
written): the copy's non-empty answer wins, nested dicts merge key by key,
bookkeeping keys keep the top-level value, nested older copies are dropped.
"""

SKIP = ('information_schema', 'pg_catalog', 'pg_toast', 'auth', 'storage', 'realtime', 'vault', 'extensions',
        'graphql', 'graphql_public', 'supabase_functions', 'supabase_migrations', 'net', 'cron', 'pgbouncer',
        'pgsodium', 'pgsodium_masks')
EMPTY = (None, '', [], {})
COPY_KEYS = ('commonForm', 'common_form')
KEEP_TOP = frozenset({'id', 'lastEditedAt', 'updatedAt', 'updated_at', 'createdAt', 'created_at'})
BACKUP = 'cases_commonform_backup'


def _merge(top, copy):
    out = dict(top)
    for key, value in copy.items():
        if key in COPY_KEYS or value in EMPTY:
            continue
        current = out.get(key)
        if key in KEEP_TOP and current not in EMPTY:
            continue
        if isinstance(value, dict) and isinstance(current, dict):
            out[key] = _merge(current, value)
        else:
            out[key] = value
    return out


def fold(extra):
    folded = {k: v for k, v in extra.items() if k not in COPY_KEYS}
    for key in COPY_KEYS:
        if isinstance(extra.get(key), dict):
            folded = _merge(folded, extra[key])
    return folded


def case_schemas(cursor):
    cursor.execute("""SELECT table_schema FROM information_schema.tables
                      WHERE table_name = 'cases_caserecord' AND NOT (table_schema = ANY(%s))""", [list(SKIP)])
    return [r[0] for r in cursor.fetchall()]


def _as_dict(value):
    if isinstance(value, str):
        value = json.loads(value)
    return value if isinstance(value, dict) else None


def forwards(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return
    with schema_editor.connection.cursor() as cursor:
        for schema in case_schemas(cursor):
            cursor.execute(f"""SELECT id, extra_fields FROM "{schema}".cases_caserecord
                               WHERE jsonb_typeof(extra_fields::jsonb) = 'object'
                                 AND (extra_fields::jsonb -> 'commonForm' IS NOT NULL
                                      OR extra_fields::jsonb -> 'common_form' IS NOT NULL)""")
            rows = cursor.fetchall()
            if not rows:
                continue
            cursor.execute(f"""CREATE TABLE IF NOT EXISTS "{schema}".{BACKUP} (
                                   case_id varchar(128) PRIMARY KEY,
                                   common_form jsonb,
                                   common_form_alt jsonb,
                                   folded_at timestamptz NOT NULL DEFAULT now())""")
            folded_count = 0
            for case_id, raw in rows:
                extra = _as_dict(raw)
                if extra is None:
                    continue
                cursor.execute(f"""INSERT INTO "{schema}".{BACKUP} (case_id, common_form, common_form_alt)
                                   VALUES (%s, %s::jsonb, %s::jsonb)
                                   ON CONFLICT (case_id) DO NOTHING""",
                               [case_id, json.dumps(extra.get('commonForm')), json.dumps(extra.get('common_form'))])
                cursor.execute(f'UPDATE "{schema}".cases_caserecord SET extra_fields = %s::jsonb WHERE id = %s',
                               [json.dumps(fold(extra)), case_id])
                folded_count += 1
            print(f'  0180: {schema}: {folded_count} commonForm copies folded (backup in {schema}.{BACKUP})')


def backwards(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return
    with schema_editor.connection.cursor() as cursor:
        for schema in case_schemas(cursor):
            cursor.execute("SELECT 1 FROM information_schema.tables WHERE table_schema = %s AND table_name = %s",
                           [schema, BACKUP])
            if not cursor.fetchone():
                continue
            cursor.execute(f'SELECT case_id, common_form, common_form_alt FROM "{schema}".{BACKUP}')
            for case_id, copy, alt in cursor.fetchall():
                cursor.execute(f'SELECT extra_fields FROM "{schema}".cases_caserecord WHERE id = %s', [case_id])
                row = cursor.fetchone()
                extra = _as_dict(row[0]) if row else None
                if extra is None:
                    continue
                if _as_dict(copy) is not None:
                    extra['commonForm'] = _as_dict(copy)
                if _as_dict(alt) is not None:
                    extra['common_form'] = _as_dict(alt)
                cursor.execute(f'UPDATE "{schema}".cases_caserecord SET extra_fields = %s::jsonb WHERE id = %s',
                               [json.dumps(extra), case_id])


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0179_missing_foreign_key_indexes'),
    ]

    operations = [
        migrations.RunPython(forwards, backwards),
    ]
