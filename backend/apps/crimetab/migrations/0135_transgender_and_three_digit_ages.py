import re

from django.db import migrations

"""
Migration 0135: Transgender gender option; three-digit ages accepted everywhere

1. option_values 'gender' gets 'Transgender' (between Female and Other), so every
   gender dropdown that loads /api/options/gender/ offers it.
2. The module tables' age CHECK constraints allowed 1-120 while the forms accept
   three digits; saving e.g. 150 failed. Every CHECK in public / a state schema
   that caps an age column at 120 is recreated with the same rule up to 999
   (same constraint name), and the N.C. "Age must be between 1 and 120." message
   says 999. Idempotent.
"""

GENDER_GROUP = 'gender'
NEW_GENDER = 'Transgender'
NEW_GENDER_ORDER = 25  # Male 10, Female 20, Transgender 25, Other 30

OLD_MAX, NEW_MAX = 120, 999

SYSTEM_SCHEMAS = ('information_schema', 'pg_catalog', 'pg_toast', 'auth', 'storage', 'realtime',
                  'graphql', 'graphql_public', 'vault', 'supabase_functions', 'supabase_migrations',
                  'extensions', 'cron', 'net', '_analytics', '_realtime', 'pgbouncer')


def add_transgender(apps, schema_editor):
    OptionValue = apps.get_model('crimetab', 'OptionValue')
    OptionValue.objects.get_or_create(
        option_group=GENDER_GROUP, option_value=NEW_GENDER,
        defaults={'display_order': NEW_GENDER_ORDER, 'is_active': True},
    )


def remove_transgender(apps, schema_editor):
    OptionValue = apps.get_model('crimetab', 'OptionValue')
    OptionValue.objects.filter(option_group=GENDER_GROUP, option_value=NEW_GENDER).delete()


def _recap_ages(schema_editor, old, new):
    if schema_editor.connection.vendor != 'postgresql':
        return
    # "<age column> <= <old>" inside a constraint definition
    pattern = re.compile(r'(\(?\w*age\w*\)? <= )%d\b' % old)
    with schema_editor.connection.cursor() as cursor:
        cursor.execute(
            """
            SELECT n.nspname, t.relname, con.conname, pg_get_constraintdef(con.oid)
            FROM pg_constraint con
            JOIN pg_class t ON t.oid = con.conrelid
            JOIN pg_namespace n ON n.oid = t.relnamespace
            WHERE con.contype = 'c' AND NOT (n.nspname = ANY(%s)) AND n.nspname NOT LIKE 'pg\\_%%'
            """,
            [list(SYSTEM_SCHEMAS)],
        )
        for schema, table, name, definition in cursor.fetchall():
            new_def = pattern.sub(lambda m: f'{m.group(1)}{new}', definition)
            if new_def == definition:
                continue
            cursor.execute(f'ALTER TABLE "{schema}"."{table}" DROP CONSTRAINT "{name}"')
            cursor.execute(f'ALTER TABLE "{schema}"."{table}" ADD CONSTRAINT "{name}" {new_def}')


def _age_message(max_age):
    return f'Age must be between 1 and {max_age}.'


def _swap_age_message(apps, old, new):
    # Only the message as seeded (0053); a customised text is left alone
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    ModuleSetting.objects.filter(module_key='nc', setting_key='invalid_age_message',
                                 setting_value=_age_message(old)).update(setting_value=_age_message(new))


def raise_age_caps(apps, schema_editor):
    _recap_ages(schema_editor, OLD_MAX, NEW_MAX)
    _swap_age_message(apps, OLD_MAX, NEW_MAX)


def restore_age_caps(apps, schema_editor):
    _recap_ages(schema_editor, NEW_MAX, OLD_MAX)
    _swap_age_message(apps, NEW_MAX, OLD_MAX)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0134_cases_person_medical'),
    ]

    operations = [
        migrations.RunPython(add_transgender, reverse_code=remove_transgender),
        migrations.RunPython(raise_age_caps, reverse_code=restore_age_caps),
    ]
