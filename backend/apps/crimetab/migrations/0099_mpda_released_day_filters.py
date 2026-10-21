from django.db import migrations

"""
Migration 0099: MPDA "Released in next month" card day filters (data only)

- released_filter_days: the day filters shown inside the card, comma separated.
  Picking one lists proposals whose detention completes from today up to
  today + that many days (revoked detention orders excluded).
- released_filter_label: chip text, {days} is replaced by the number.
Existing keys are kept.
"""

SETTINGS = [
    ('released_filter_days', '20,10'),
    ('released_filter_label', '{days} days'),
]


def seed(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    for key, value in SETTINGS:
        ModuleSetting.objects.get_or_create(
            module_key='mpda', setting_key=key, defaults={'setting_value': value}
        )


def unseed(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    ModuleSetting.objects.filter(
        module_key='mpda', setting_key__in=[k for k, _ in SETTINGS]
    ).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0098_mpda_crime_chart_act_section_subsection'),
    ]

    operations = [
        migrations.RunPython(seed, reverse_code=unseed),
    ]
