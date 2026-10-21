import importlib

from django.db import migrations

"""
Migration 0119: POCSO extra fields back, per the POCSO list (data only)

Rebuilds "POCSO Extra Fields" (removed by 0117) with the fields of 0110, linked
only to the POCSO categories:
    POCSO - Victim Details         name (select only: ABC 1, ABC 2, ...), age, KYC
                                   like the Common Form complainant, age proof
                                   (TC, Bonafide Certificate, Aadhaar Card,
                                   Ossification Test, Other) + Other (type)
    POCSO - Medical & Statements   medical of victim / accused, victim's statement,
                                   lady officer, CWC, 164 CrPC / 183 BNSS,
                                   counselling (each Y/N, Date on Yes)
    POCSO - DNA & FSL              victim / accused DNA sample, sent to FSL, FSL
                                   report received (each Y/N, Date on Yes)
    POCSO - Vehicle & Absconding   SD entry of vehicle number and time, case diary
                                   vehicle entry (Y/N)
Left out because the Common Form already shows them on every tab, POCSO
included: Vehicle Log Book Entry and the Section 82, 83 check (0110's own copy
of the latter is dropped). Answers are stored as rows of case_extra_field_values.
Idempotent.
"""

POCSO_0110 = 'apps.crimetab.migrations.0110_pocso_extra_fields'
REMOVE_0117 = 'apps.crimetab.migrations.0117_remove_pocso_extra_fields'

TEMPLATE_NAME = 'POCSO Extra Fields'
# 0110 fields the Common Form already covers
DROPPED = ('pocso_sec_82_83_action', 'pocso_sec_82_83_action_date')
AGE_PROOF_OTHER = ('Other Age Proof (type)', 'pocso_age_proof_other', 'text',
                   'POCSO - Victim Details', 105, 'pocso_age_proof', 'Other')


def forwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    importlib.import_module(POCSO_0110).forwards(apps, schema_editor)
    tmpl = FieldTemplate.objects.get(template_name=TEMPLATE_NAME)
    FieldTemplateField.objects.filter(template=tmpl, field_key__in=DROPPED).delete()
    label, key, ftype, section, order, parent, value = AGE_PROOF_OTHER
    FieldTemplateField.objects.get_or_create(
        template=tmpl, field_key=key,
        defaults={'field_label': label, 'field_source': 'custom', 'field_type': ftype,
                  'is_required': False, 'section': section, 'display_order': order,
                  'depends_on_field_key': parent, 'depends_on_value': value},
    )


def backwards(apps, schema_editor):
    importlib.import_module(REMOVE_0117).forwards(apps, schema_editor)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0118_vehicle_entry_checks_to_crime_against_women'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
