from django.db import migrations

# The six regional "divisions" (Konkan, Pune, Nashik, ...) seeded into each
# state schema's master_divisions are not real police divisions. A division is
# now a sub-division inside one district or city, typed in when its Division
# Admin is created, so these rows are removed. Officer accounts keep the
# division names written on them.
PLACEHOLDER_DIVISIONS = [
    ('Chhatrapati Sambhajinagar', 'CSN'),
    ('Pune', 'PUN'),
    ('Nashik', 'NSK'),
    ('Konkan', 'KNK'),
    ('Nagpur', 'NGP'),
    ('Amravati', 'AMR'),
]


def _schemas_with_divisions(cursor):
    cursor.execute(
        "SELECT table_schema FROM information_schema.tables WHERE table_name = 'master_divisions'"
    )
    return [row[0] for row in cursor.fetchall()]


def remove_placeholder_divisions(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return  # master_divisions lives in Postgres state schemas only
    with schema_editor.connection.cursor() as cursor:
        for schema in _schemas_with_divisions(cursor):
            for name, code in PLACEHOLDER_DIVISIONS:
                cursor.execute(
                    f'DELETE FROM "{schema}".master_divisions WHERE name = %s AND code = %s',
                    [name, code],
                )


def restore_placeholder_divisions(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return
    with schema_editor.connection.cursor() as cursor:
        for schema in _schemas_with_divisions(cursor):
            for name, code in PLACEHOLDER_DIVISIONS:
                cursor.execute(
                    f'INSERT INTO "{schema}".master_divisions (state_code, state_name, name, code, created_at) '
                    f"SELECT 'MH', 'Maharashtra', %s, %s, now() "
                    f'WHERE NOT EXISTS (SELECT 1 FROM "{schema}".master_divisions WHERE name = %s AND code = %s)',
                    [name, code, name, code],
                )


class Migration(migrations.Migration):

    dependencies = [
        ('public_master', '0018_officer_edits_own_cases_only'),
    ]

    operations = [
        migrations.RunPython(remove_placeholder_divisions, restore_placeholder_divisions),
    ]
