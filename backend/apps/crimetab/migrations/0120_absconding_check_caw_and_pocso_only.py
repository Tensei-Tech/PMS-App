from django.db import migrations

"""
Migration 0120: Section 82, 83 check only for Crime Against Women and POCSO (data only)

0116 put "Accused Not Traceable: Action under Section 82, 83 Initiated" (+ its
Date on "Yes") in the Common Form, so every crime tab showed an "Absconding
Accused" section. It belongs to Crime Against Women and POCSO only: removed
from the Common Form (no case had a value in it) and added to
    Crime Against Women Extra Fields   section "CAW - Absconding Accused"
    POCSO Extra Fields                 section "POCSO - Absconding Accused"
Idempotent.
"""

COMMON = 'Common Form Baseline Template'
YES_NO = '/api/options/yes_no/'
YES = 'Yes'
LABEL = 'Accused Not Traceable: Action under Section 82, 83 Initiated'
DATE_LABEL = 'Section 82, 83 Action Date'

COMMON_KEY = 'accused_sec_82_83_action'
COMMON_SECTION = 'Absconding Accused'
COMMON_ORDER = 796

# template: (key prefix, section, order)
TARGETS = {
    'Crime Against Women Extra Fields': ('caw', 'CAW - Absconding Accused', 900),
    'POCSO Extra Fields': ('pocso', 'POCSO - Absconding Accused', 700),
}


def _create_pair(FieldTemplateField, tmpl, key, section, order):
    FieldTemplateField.objects.get_or_create(
        template=tmpl, field_key=key,
        defaults={'field_label': LABEL, 'field_source': 'custom', 'field_type': 'radio',
                  'is_required': False, 'section': section, 'display_order': order,
                  'options_source': YES_NO},
    )
    FieldTemplateField.objects.get_or_create(
        template=tmpl, field_key=f'{key}_date',
        defaults={'field_label': DATE_LABEL, 'field_source': 'custom', 'field_type': 'date',
                  'is_required': False, 'section': section, 'display_order': order + 1,
                  'depends_on_field_key': key, 'depends_on_value': YES},
    )


def _keys(key):
    return [key, f'{key}_date']


def forwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(template__template_name=COMMON,
                                      field_key__in=_keys(COMMON_KEY)).delete()
    for tname, (prefix, section, order) in TARGETS.items():
        tmpl = FieldTemplate.objects.filter(template_name=tname).first()
        if tmpl is not None:
            _create_pair(FieldTemplateField, tmpl, f'{prefix}_sec_82_83_action', section, order)


def backwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    for tname, (prefix, _, _) in TARGETS.items():
        FieldTemplateField.objects.filter(template__template_name=tname,
                                          field_key__in=_keys(f'{prefix}_sec_82_83_action')).delete()
    common = FieldTemplate.objects.filter(template_name=COMMON).first()
    if common is not None:
        _create_pair(FieldTemplateField, common, COMMON_KEY, COMMON_SECTION, COMMON_ORDER)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0119_pocso_extra_fields_again'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
