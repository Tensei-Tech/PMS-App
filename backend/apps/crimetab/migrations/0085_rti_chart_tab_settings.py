from django.db import migrations

"""
Migration 0085: RTI "Chart" tab settings (data only)

module_key 'rti': the fourth tab's label, the nine column headers and the
"Information Given" layout (outcome chosen by the user + its date). In the
layout, '|' separates parts; a part whose values are all empty is skipped; parts
are joined with chart_info_given_separator. Existing keys are kept.
"""

SETTINGS = [
    ('tab_chart_label', 'Chart'),
    ('chart_header_sr_no', 'Sr. No.'),
    ('chart_header_received_date', 'Received Date'),
    ('chart_header_due_date', 'Due Date'),
    ('chart_header_age', 'Age'),
    ('chart_header_mobile_no', 'Mobile No.'),
    ('chart_header_address', 'Address'),
    ('chart_header_info_type', 'Type of Information'),
    ('chart_header_assigned_officer', 'Assigned Officer'),
    ('chart_header_info_given', 'Information Given'),
    ('chart_info_given_template', '{outcome}|({date})'),
    ('chart_info_given_separator', ' '),
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
        ('crimetab', '0084_rti_mobile_email_field_types'),
    ]

    operations = [
        migrations.RunPython(seed, reverse_code=unseed),
    ]
