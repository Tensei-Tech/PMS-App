from django.db import migrations

"""
Migration 0100: MPDA detention reminders (data only)

1. Automatic reminder schedule before the Detention End Date: once at 30 days,
   once at 20 days, then every day from 10 days until the end date.
2. "Send Reminder" action on the Summary table: button label and the messages
   of the reminder sent to every officer of the police station (placeholders
   {proposal_no} {accused} {end_date} {days_left} {sender} {io} {station} {count}).
Existing keys are kept.
"""

SETTINGS = [
    ('detention_reminder_first_days', '30'),
    ('detention_reminder_second_days', '20'),
    ('detention_reminder_daily_from_days', '10'),
    ('btn_remind_label', 'Send Reminder'),
    ('summary_header_actions', 'Actions'),
    ('manual_reminder_title', 'MPDA detention reminder'),
    ('manual_reminder_message',
     'Reminder from {sender}: detention of {accused} (MPDA {proposal_no}) ends on '
     '{end_date} ({days_left} days left).'),
    ('manual_reminder_sent_message', 'Reminder sent to {count} officer(s) of {station}.'),
    ('manual_reminder_no_officers_message', 'No active officers found for this police station.'),
    ('manual_reminder_ended_message',
     'Reminders can be sent only until the Detention End Date.'),
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
        ('crimetab', '0099_mpda_released_day_filters'),
    ]

    operations = [
        migrations.RunPython(seed, reverse_code=unseed),
    ]
