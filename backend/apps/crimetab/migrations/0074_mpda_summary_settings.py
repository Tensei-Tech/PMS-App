from django.db import migrations

"""
Migration 0074: MPDA "Summary" settings (data only)

module_key 'mpda': the Summary card label, the five column headers, the accused
layout (Name, Age, Gender, Mobile, Address of every accused) and the outcome
layout (outcome with the date that belongs to it). In a layout '|' separates
parts and a part whose values are all empty is skipped. Existing keys are kept.
"""

SETTINGS = [
    ('card_summary_label', 'Summary'),
    ('summary_header_sr_no', 'Sr. No.'),
    ('summary_header_accused', 'Accused (Name, Age, Gender, Mobile, Address)'),
    ('summary_header_gang_members', 'Gang / Group Members'),
    ('summary_header_outcome', 'Proposal Outcome & Date'),
    ('summary_header_category', 'MPDA Category'),
    ('summary_accused_template', '{name}|{age} Yrs|{gender}|Mob: {mobile}|{address}'),
    ('summary_accused_separator', ', '),
    ('summary_outcome_template', '{outcome}|({date})'),
]


def seed(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    for key, value in SETTINGS:
        ModuleSetting.objects.get_or_create(module_key='mpda', setting_key=key,
                                            defaults={'setting_value': value})


def unseed(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    ModuleSetting.objects.filter(module_key='mpda', setting_key__in=[k for k, _ in SETTINGS]).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0073_add_total_misc_crime'),
    ]

    operations = [
        migrations.RunPython(seed, reverse_code=unseed),
    ]
