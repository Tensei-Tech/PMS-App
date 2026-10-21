from django.db import migrations

"""
Migration 0077: MPDA Total Crime is calculated, not typed

Total Crime = Total Serious Crime + Total Miscellaneous Crime. The form engine
reads the options source `sum:<field>,<field>` on a number field, fills it
automatically and makes it read-only. The backend applies the same rule on
save, so Total Serious Crime can never be more than Total Crime.

Also adds the two validation messages as module settings.
Idempotent; reverse clears the options source again.
"""

TEMPLATE_NAME = 'MPDA Proposal Template'
TOTAL_KEY = 'mpda_total_crime'
SUM_SOURCE = 'sum:mpda_serious_crimes,mpda_total_misc_crime'

SETTINGS = [
    ('serious_exceeds_total_message', 'Total Serious Crime cannot be more than Total Crime.'),
    ('crime_count_negative_message', 'Crime counts cannot be negative.'),
]


def forwards(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME, field_key=TOTAL_KEY
    ).update(options_source=SUM_SOURCE)
    for key, value in SETTINGS:
        ModuleSetting.objects.get_or_create(
            module_key='mpda', setting_key=key, defaults={'setting_value': value}
        )


def backwards(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME, field_key=TOTAL_KEY, options_source=SUM_SOURCE
    ).update(options_source=None)
    ModuleSetting.objects.filter(module_key='mpda', setting_key__in=[k for k, _ in SETTINGS]).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0076_mpda_proposal_revoked'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
