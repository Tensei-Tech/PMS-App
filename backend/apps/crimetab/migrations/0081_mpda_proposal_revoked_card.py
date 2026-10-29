from django.db import migrations

"""
Migration 0081: MPDA "Total MPDA Revoked" card and tab labels

Adds the card / tab labels for proposals whose "Revoked" (mpda_proposal_revoked)
is Yes. Data only; existing settings are never overwritten.
"""

SETTINGS = [
    ('card_proposal_revoked_label', 'Total MPDA Revoked'),
    ('tab_proposal_revoked_label', 'Total MPDA Revoked'),
]


def add_labels(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    for key, value in SETTINGS:
        ModuleSetting.objects.get_or_create(
            module_key='mpda', setting_key=key, defaults={'setting_value': value}
        )


def remove_labels(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    ModuleSetting.objects.filter(module_key='mpda', setting_key__in=[k for k, _ in SETTINGS]).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0080_mpda_detention_reminder_settings'),
    ]

    operations = [
        migrations.RunPython(add_labels, reverse_code=remove_labels),
    ]
