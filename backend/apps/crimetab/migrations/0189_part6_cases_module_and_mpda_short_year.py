from django.db import migrations

"""
Migration 0189: data fixes D5 and D9 (approved 17 Nov 2026)

D5 - Part 6 crimes saved from the "1 to 5" form kept module_key 'form_1_5'
     (7 on the shared database: Prohibition, Gambling, NDPS, Gowansh x2, IT Act,
     UAPA). Each case whose tab name is a Part 6 tab (case_categories group 2)
     gets module_key 'form_6'; one with no tab link gets a link to that tab (only
     when exactly one Part 6 tab has the name). The fetching tabs already
     counted them as Part 6 (group_case_q); this makes the data agree.
D9 - An MPDA proposal year saved as two digits ('26') becomes four, by the
     rule the MPDA save uses since then: 2000 + the number, '00' is 2100. The
     combined "no./year" text is rebuilt the same way.
Not reversible by design: the old values were wrong.
"""

SKIP = ('information_schema', 'pg_catalog', 'pg_toast', 'auth', 'storage', 'realtime', 'vault', 'extensions',
        'graphql', 'graphql_public', 'supabase_functions', 'supabase_migrations', 'net', 'cron', 'pgbouncer',
        'pgsodium', 'pgsodium_masks')


def schemas_with(cursor, table):
    cursor.execute("""SELECT table_schema FROM information_schema.tables
                      WHERE table_name = %s AND NOT (table_schema = ANY(%s))""", [table, list(SKIP)])
    return [r[0] for r in cursor.fetchall()]


def categories_table(cursor):
    for schema in ('public',) + tuple(schemas_with(cursor, 'case_categories')):
        cursor.execute('SELECT 1 FROM information_schema.tables WHERE table_schema = %s '
                       "AND table_name = 'case_categories'", [schema])
        if cursor.fetchone():
            return f'"{schema}".case_categories'
    return None


def forwards(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return
    with schema_editor.connection.cursor() as cursor:
        categories = categories_table(cursor)
        if categories:
            for schema in schemas_with(cursor, 'cases_caserecord'):
                cursor.execute(f"""
                    UPDATE "{schema}".cases_caserecord c SET module_key = 'form_6'
                    WHERE c.module_key = 'form_1_5'
                      AND EXISTS (SELECT 1 FROM {categories} k WHERE k.group_id = 2
                                  AND lower(trim(k.category_name)) = lower(trim(c.sub_category)))
                    RETURNING c.id""")
                moved = [r[0] for r in cursor.fetchall()]
                linked = 0
                cursor.execute('SELECT 1 FROM information_schema.tables WHERE table_schema = %s '
                               "AND table_name = 'case_category_links'", [schema])
                if moved and cursor.fetchone():
                    cursor.execute(f"""
                        INSERT INTO "{schema}".case_category_links (case_id, category_id, is_primary, created_at)
                        SELECT c.id, min(k.category_id), TRUE, now()
                        FROM "{schema}".cases_caserecord c
                        JOIN {categories} k ON k.group_id = 2
                             AND lower(trim(k.category_name)) = lower(trim(c.sub_category))
                        WHERE c.id = ANY(%s)
                          AND NOT EXISTS (SELECT 1 FROM "{schema}".case_category_links l WHERE l.case_id = c.id)
                        GROUP BY c.id
                        HAVING count(*) = 1""", [moved])
                    linked = cursor.rowcount
                if moved:
                    print(f'  0189: {schema}: {len(moved)} Part 6 cases moved to form_6, {linked} linked to their tab')

        for schema in schemas_with(cursor, 'mpda_proposals'):
            cursor.execute(f"""
                UPDATE "{schema}".mpda_proposals p
                SET proposal_year = y.full_year,
                    proposal_no_and_year = CASE WHEN coalesce(trim(p.proposal_no), '') <> ''
                                                THEN trim(p.proposal_no) || '/' || y.full_year
                                                ELSE p.proposal_no_and_year END
                FROM (SELECT id, CASE WHEN trim(proposal_year)::int = 0 THEN '2100'
                                      ELSE (2000 + trim(proposal_year)::int)::text END AS full_year
                      FROM "{schema}".mpda_proposals
                      WHERE trim(proposal_year) ~ '^[0-9]{{1,2}}$') y
                WHERE p.id = y.id""")
            if cursor.rowcount:
                print(f'  0189: {schema}: {cursor.rowcount} MPDA proposal year(s) written in full')


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0188_preventive_records'),
    ]

    operations = [
        migrations.RunPython(forwards, migrations.RunPython.noop),
    ]
