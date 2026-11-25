from django.db import migrations

"""
Migration 0201: "FSL Report" reads "FSL Report Received" (data only)

The FSL Report question of the Murder, Attempt to Murder, Hurt and Robbery /
Dacoity forms is renamed "FSL Report Received", like the POCSO and Crime
Against Women ones already are. Only the label changes; keys and saved case
values are untouched. Its date / time fields keep their names.

Backwards puts "FSL Report" back. Idempotent.
"""

OLD = 'FSL Report'
NEW = 'FSL Report Received'
KEYS = ['murder_fsl_report', 'atm_fsl_report', 'hurt_fsl_report', 'rd_fsl_report']


def _rename(apps, frm, to):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(field_key__in=KEYS, field_label=frm).update(field_label=to)


def forwards(apps, schema_editor):
    _rename(apps, OLD, NEW)


def backwards(apps, schema_editor):
    _rename(apps, NEW, OLD)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0200_cctv_checked_last'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
