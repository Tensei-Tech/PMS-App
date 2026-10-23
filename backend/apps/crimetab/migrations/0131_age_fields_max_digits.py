from django.db import migrations
from django.db.models import Q

"""
Migration 0131: age digit limit as field data (data only)

The form engine limited ages to 3 digits by looking at the field key ('age' or
'..._age'). The limit is now the field's options source 'digits:<n>': this sets
'digits:3' on every number field with such a key and no options source yet
(complainant / accused / deceased / applicant ages ...). To change or remove a
limit, edit that field's options_source. Idempotent.
"""

LIMIT = 'digits:3'


def _age_number_fields(apps):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    return FieldTemplateField.objects.filter(
        Q(field_key='age') | Q(field_key__endswith='_age'), field_type='number')


def forwards(apps, schema_editor):
    _age_number_fields(apps).filter(Q(options_source__isnull=True) | Q(options_source='')).update(
        options_source=LIMIT)


def backwards(apps, schema_editor):
    _age_number_fields(apps).filter(options_source=LIMIT).update(options_source=None)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0130_ad_disposal_rule_settings'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
