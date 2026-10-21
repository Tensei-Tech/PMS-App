from django.db import migrations

"""
Migration 0130: A.D. disposal rule in module_settings (data only)

apps.cases.models.is_ad_case_disposed reads these instead of fixed keys:
    disposal_field_key       ad_sdm_granted       (AD form: SDM Granted)
    disposal_value           Yes
    disposal_date_field_key  ad_sdm_granted_date  (AD form: SDM Granted Date)
A case moves to Disposal when the field has the value and the date is filled.
Idempotent; existing values are never overwritten.
"""

SETTINGS = [
    ('disposal_field_key', 'ad_sdm_granted'),
    ('disposal_value', 'Yes'),
    ('disposal_date_field_key', 'ad_sdm_granted_date'),
]


def forwards(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    for key, value in SETTINGS:
        ModuleSetting.objects.get_or_create(module_key='ad', setting_key=key,
                                            defaults={'setting_value': value})


def backwards(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    ModuleSetting.objects.filter(module_key='ad', setting_key__in=[k for k, _ in SETTINGS]).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0129_road_accident_models_state'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
