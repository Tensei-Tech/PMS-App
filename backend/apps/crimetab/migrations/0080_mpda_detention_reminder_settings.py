from django.db import migrations

"""
Migration 0080: MPDA detention end reminder settings

GET /api/mpda/reminders/ lists, for the officer's own police station, every
detained proposal whose Detention End Date is within the next
`detention_reminder_days` days. Title / message / labels live here so they can
be changed without a release. Message placeholders:
{proposal_no} {accused} {end_date} {days_left}
Idempotent (get_or_create keeps any value already changed).
"""

SETTINGS = [
    ('detention_reminder_days', '30'),
    ('detention_reminder_title', 'Detention ending soon'),
    ('detention_reminder_message',
     'Proposal {proposal_no}: detention of {accused} ends on {end_date} ({days_left} days left).'),
    ('detention_reminder_banner', '{count} detention(s) ending within {days} days'),
    ('detention_reminder_tab_label', 'MPDA Detention'),
]


def forwards(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    for key, value in SETTINGS:
        ModuleSetting.objects.get_or_create(module_key='mpda', setting_key=key,
                                            defaults={'setting_value': value})


def backwards(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    ModuleSetting.objects.filter(module_key='mpda', setting_key__in=[k for k, _ in SETTINGS]).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0079_mpda_detention_start_end'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
