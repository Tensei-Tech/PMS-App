from django.db import migrations

"""
Migration 0116: "every crime" checks move to the Common Form; POCSO relation (data only)

Common Form Baseline Template (so every crime has them):
    Vehicle Log Book     794 Government Vehicle Used: SD Entry of Vehicle Number and Time (Y/N)
                         795 Case Diary Vehicle Entry (Y/N)
                         (after the existing Vehicle Log Book Entry, Date, Reason)
    Absconding Accused   Accused Not Traceable: Action under Section 82, 83 Initiated (Y/N)
                         + its Date on "Yes"
POCSO Extra Fields:
    - the same three checks (added by 0110) are removed: the Common Form has them
      now; none had a saved value
    - Relation to Accused (dropdown, victim_accused_relations of 0115) + Other (type)
Every field optional. Idempotent.
"""

COMMON = 'Common Form Baseline Template'
POCSO = 'POCSO Extra Fields'
YES_NO = '/api/options/yes_no/'
YES = 'Yes'
OTHER = 'Other'

# (template, label, key, type, section, order, options_source, depends_on (key, value) or None)
NEW_FIELDS = [
    (COMMON, 'Government Vehicle Used: SD Entry of Vehicle Number and Time', 'govt_vehicle_sd_entry',
     'radio', 'Vehicle Log Book', 794, YES_NO, None),
    (COMMON, 'Case Diary Vehicle Entry', 'case_diary_vehicle_entry',
     'radio', 'Vehicle Log Book', 795, YES_NO, None),
    (COMMON, 'Accused Not Traceable: Action under Section 82, 83 Initiated', 'accused_sec_82_83_action',
     'radio', 'Absconding Accused', 796, YES_NO, None),
    (COMMON, 'Section 82, 83 Action Date', 'accused_sec_82_83_action_date',
     'date', 'Absconding Accused', 797, None, ('accused_sec_82_83_action', YES)),
    (POCSO, 'Relation to Accused', 'pocso_relation_to_accused',
     'dropdown', 'POCSO - Victim Details', 103, '/api/options/victim_accused_relations/', None),
    (POCSO, 'Other Relation (type)', 'pocso_relation_other',
     'text', 'POCSO - Victim Details', 104, None, ('pocso_relation_to_accused', OTHER)),
]

# POCSO fields of 0110 now covered by the Common Form (recreated going backwards)
POCSO_REMOVED = [
    ('Government Vehicle Used: SD Entry of Vehicle Number and Time', 'pocso_govt_vehicle_sd_entry', 'radio', 610, YES_NO, None),
    ('Case Diary Vehicle Entry', 'pocso_case_diary_vehicle_entry', 'radio', 620, YES_NO, None),
    ('Accused Not Traceable: Action under Section 82, 83 Initiated', 'pocso_sec_82_83_action', 'radio', 630, YES_NO, None),
    ('Section 82, 83 Action Date', 'pocso_sec_82_83_action_date', 'date', 640, None, 'pocso_sec_82_83_action'),
]
POCSO_ACTION_SECTION = 'POCSO - Vehicle & Absconding'


def forwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    templates = {t.template_name: t for t in FieldTemplate.objects.filter(template_name__in=[COMMON, POCSO])}
    for tname, label, key, ftype, section, order, options, depends in NEW_FIELDS:
        tmpl = templates.get(tname)
        if tmpl is None:
            continue
        FieldTemplateField.objects.get_or_create(
            template=tmpl,
            field_key=key,
            defaults={
                'field_label': label,
                'field_source': 'custom',
                'field_type': ftype,
                'is_required': False,
                'section': section,
                'display_order': order,
                'options_source': options,
                'depends_on_field_key': depends[0] if depends else None,
                'depends_on_value': depends[1] if depends else None,
            },
        )
    FieldTemplateField.objects.filter(
        template__template_name=POCSO, field_key__in=[k for _, k, *_ in POCSO_REMOVED]
    ).delete()


def backwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    for tname, _, key, *_ in NEW_FIELDS:
        FieldTemplateField.objects.filter(template__template_name=tname, field_key=key).delete()
    pocso = FieldTemplate.objects.filter(template_name=POCSO).first()
    if pocso is None:
        return
    for label, key, ftype, order, options, parent in POCSO_REMOVED:
        FieldTemplateField.objects.get_or_create(
            template=pocso, field_key=key,
            defaults={'field_label': label, 'field_source': 'custom', 'field_type': ftype,
                      'is_required': False, 'section': POCSO_ACTION_SECTION, 'display_order': order,
                      'options_source': options, 'depends_on_field_key': parent,
                      'depends_on_value': YES if parent else None},
        )


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0115_crime_against_women_extra_fields'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
