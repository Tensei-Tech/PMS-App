from django.db import migrations

"""
Migration 0082: RTI form section "Outcome" -> "Information Given"

Renames only the section heading of the RTI Form fields (rti_outcome,
rti_replied_date, rti_rejected_date, rti_rejection_reason, rti_transferred_to).
Field labels, including the "Outcome" field itself, are unchanged.
"""

TEMPLATE_NAME = 'RTI Form'
OLD_SECTION = 'Outcome'
NEW_SECTION = 'Information Given'


def rename_section(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME, section=OLD_SECTION
    ).update(section=NEW_SECTION)


def restore_section(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME, section=NEW_SECTION
    ).update(section=OLD_SECTION)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0081_mpda_proposal_revoked_card'),
    ]

    operations = [
        migrations.RunPython(rename_section, reverse_code=restore_section),
    ]
