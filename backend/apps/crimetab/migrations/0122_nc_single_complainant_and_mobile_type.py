from django.db import migrations

"""
Migration 0122: NC Form - one complainant, mobile number validation

- Complainant group (nc_complainants): options source 'max:1', so the form
  shows a single complainant with no Add / Remove buttons.
- Complainant and non applicant mobile -> field type 'mobile' (exactly 10
  digits when filled).
All fields stay optional (is_required unchanged).
"""

TEMPLATE_NAME = 'NC Form'
SINGLE_ROW_GROUP = 'nc_complainants'
SINGLE_ROW_SOURCE = 'max:1'
MOBILE_KEYS = ('nc_cmp_mobile', 'nc_na_mobile')


def forwards(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    fields = FieldTemplateField.objects.filter(template__template_name=TEMPLATE_NAME)
    fields.filter(field_key=SINGLE_ROW_GROUP, field_type='repeating_group').update(
        options_source=SINGLE_ROW_SOURCE)
    fields.filter(field_key__in=MOBILE_KEYS, field_type='text').update(field_type='mobile')


def backwards(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    fields = FieldTemplateField.objects.filter(template__template_name=TEMPLATE_NAME)
    fields.filter(field_key=SINGLE_ROW_GROUP, options_source=SINGLE_ROW_SOURCE).update(
        options_source=None)
    fields.filter(field_key__in=MOBILE_KEYS, field_type='mobile').update(field_type='text')


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0121_ad_suicide_and_other_subtabs'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
