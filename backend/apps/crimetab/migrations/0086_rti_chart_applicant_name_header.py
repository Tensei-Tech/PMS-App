from django.db import migrations

"""
Migration 0086: RTI Chart "Applicant Name" column header (data only).
Existing keys are kept.
"""

SETTINGS = [
    ('chart_header_applicant_name', 'Applicant Name'),
]


def seed(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    for key, value in SETTINGS:
        ModuleSetting.objects.get_or_create(
            module_key='rti', setting_key=key, defaults={'setting_value': value}
        )


def unseed(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    ModuleSetting.objects.filter(module_key='rti', setting_key__in=[k for k, _ in SETTINGS]).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0085_rti_chart_tab_settings'),
    ]

    operations = [
        migrations.RunPython(seed, reverse_code=unseed),
    ]
