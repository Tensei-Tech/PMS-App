from django.db import migrations

"""
Migration 0089: RTI due-date reminder settings (data only)

Reminders go to the officer assigned to a pending RTI application:
first one reminder_first_days_before days before the Due Date, second one
reminder_second_days_before days before, then every day from
reminder_daily_from_days_before days before until the application is disposed.
Placeholders: {sr_no} {applicant} {due_date} {days_left}; manual reminders also
{sender} {officer}. Also the Summary tab "Action" column and button label.
Existing keys are kept.
"""

SETTINGS = [
    ('reminder_first_days_before', '30'),
    ('reminder_second_days_before', '25'),
    ('reminder_daily_from_days_before', '24'),
    ('reminder_tab_label', 'RTI Reminders'),
    ('reminder_banner', '{count} RTI reminder(s)'),
    ('reminder_title', 'RTI {sr_no} reply due'),
    ('reminder_message', '{sr_no} ({applicant}) is due on {due_date}. Days left: {days_left}.'),
    ('manual_reminder_title', 'RTI {sr_no} reminder from {sender}'),
    ('manual_reminder_message', 'Please act on RTI {sr_no} ({applicant}), due on {due_date}.'),
    ('manual_reminder_sent_message', 'Reminder sent to {officer}.'),
    ('manual_reminder_no_officer_message', 'No officer is assigned to this RTI application.'),
    ('action_remind_label', 'Send Reminder'),
    ('chart_header_action', 'Action'),
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
        ('crimetab', '0088_rti_chart_tab_renamed_summary'),
    ]

    operations = [
        migrations.RunPython(seed, reverse_code=unseed),
    ]
