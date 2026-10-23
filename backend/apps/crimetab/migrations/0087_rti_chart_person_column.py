from django.db import migrations

"""
Migration 0087: RTI Chart combined person column (data only)

Name, Age, Mobile No. and Address are shown in ONE column. Header and layout
come from module_settings: in chart_person_template '|' separates parts; a part
whose values are all empty is skipped; parts are joined with
chart_person_separator. Existing keys are kept.
"""

SETTINGS = [
    ('chart_header_person', 'Name, Age, Mobile No., Address'),
    ('chart_person_template', '{name}|{age} Yrs|Mob: {mobile}|{address}'),
    ('chart_person_separator', ', '),
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
        ('crimetab', '0086_rti_chart_applicant_name_header'),
    ]

    operations = [
        migrations.RunPython(seed, reverse_code=unseed),
    ]
