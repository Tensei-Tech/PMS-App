from django.db import migrations

"""
Migration 0069: History Sheeter "Chart" tab settings (data only)

module_key 'history_sheeter': the fourth tab's label, the six column headers and
the combined Name / Age / Gender / Address / Mobile layout. In the layout, '|'
separates parts; a part whose values are all empty is skipped; parts are joined
with chart_person_separator. Aadhaar is never shown. Existing keys are kept.
"""

SETTINGS = [
    ('tab_chart_label', 'Chart'),
    ('chart_header_sr_no', 'Sr. No.'),
    ('chart_header_person', 'Name, Age, Gender, Address, Mobile'),
    ('chart_header_total_cases', 'Total Criminal Cases'),
    ('chart_header_associates', 'Known Associates / Gang Members'),
    ('chart_header_rivals', 'Rival / Adverse Persons'),
    ('chart_header_preventive', 'Preventive Action'),
    ('chart_person_template', '{name}|{age} Yrs|{gender}|{address}|Mob: {mobile}'),
    ('chart_person_separator', ', '),
]


def seed(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    for key, value in SETTINGS:
        ModuleSetting.objects.get_or_create(
            module_key='history_sheeter', setting_key=key, defaults={'setting_value': value}
        )


def unseed(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    ModuleSetting.objects.filter(
        module_key='history_sheeter', setting_key__in=[k for k, _ in SETTINGS]
    ).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0068_hs_crime_chart_act_section_subsection'),
    ]

    operations = [
        migrations.RunPython(seed, reverse_code=unseed),
    ]
