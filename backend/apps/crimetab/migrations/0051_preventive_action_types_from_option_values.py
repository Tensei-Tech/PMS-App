from django.db import migrations, models

"""
Migration 0051: Common Form preventive action types come from the database

- Seeds public.option_values (option_group 'preventive_action_types') with the
  11 provisions that were previously hardcoded in PreventiveActionItems.ACTION_TYPE_CHOICES.
- In every tenant schema that has preventive_action_items:
    * normalises the legacy spaced spellings ('107 Crpc / 126 BNSS') to the canonical ones
    * drops the hardcoded preventive_action_items_action_type_check constraint
    * widens action_type to VARCHAR(100) (same as option_values.option_value)
- Allowed values are now validated in the API against active option_values rows,
  so provisions can be added / renamed / deactivated without a code change.
"""

OPTION_GROUP = 'preventive_action_types'

PREVENTIVE_TYPES = [
    ('107 CrPC/126 BNSS', 10),
    ('109 CrPC/128 BNSS', 20),
    ('110 CrPC/129 BNSS', 30),
    ('151(3) CrPC/170 BNSS', 40),
    ('144 CrPC/163 BNSS', 50),
    ('149 CrPC/168 BNSS', 60),
    ('55 MPA', 70),
    ('56 MPA', 80),
    ('57 MPA', 90),
    ('122 MPA', 100),
    ('93 Prohibition Act', 110),
]

LEGACY_SPELLINGS = {
    '107 Crpc / 126 BNSS': '107 CrPC/126 BNSS',
    '109 Crpc / 128 BNSS': '109 CrPC/128 BNSS',
    '110 Crpc / 129 BNSS': '110 CrPC/129 BNSS',
    '151(3) Crpc / 170 BNSS': '151(3) CrPC/170 BNSS',
    '144 Crpc / 163 BNSS': '144 CrPC/163 BNSS',
    '149 Crpc / 168 BNSS': '149 CrPC/168 BNSS',
}


def forwards(apps, schema_editor):
    OptionValue = apps.get_model('crimetab', 'OptionValue')
    for value, order in PREVENTIVE_TYPES:
        OptionValue.objects.get_or_create(
            option_group=OPTION_GROUP,
            option_value=value,
            defaults={'display_order': order, 'is_active': True},
        )

    if schema_editor.connection.vendor != 'postgresql':
        return

    with schema_editor.connection.cursor() as cursor:
        cursor.execute(
            "SELECT table_schema FROM information_schema.tables WHERE table_name = 'preventive_action_items'"
        )
        schemas = [row[0] for row in cursor.fetchall()]
        for schema in schemas:
            table = f'"{schema}".preventive_action_items'
            cursor.execute(f"ALTER TABLE {table} DROP CONSTRAINT IF EXISTS preventive_action_items_action_type_check")
            cursor.execute(f"ALTER TABLE {table} ALTER COLUMN action_type TYPE VARCHAR(100)")
            for old, new in LEGACY_SPELLINGS.items():
                cursor.execute(f"UPDATE {table} SET action_type = %s WHERE action_type = %s", [new, old])


def backwards(apps, schema_editor):
    OptionValue = apps.get_model('crimetab', 'OptionValue')
    OptionValue.objects.filter(option_group=OPTION_GROUP).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0050_history_sheeter_same_as_above_order'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            state_operations=[
                migrations.AlterField(
                    model_name='preventiveactionitems',
                    name='action_type',
                    field=models.CharField(max_length=100),
                ),
            ],
            database_operations=[
                migrations.RunPython(forwards, backwards),
            ],
        ),
    ]
