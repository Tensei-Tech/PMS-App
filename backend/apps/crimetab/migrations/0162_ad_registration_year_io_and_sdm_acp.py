from django.db import migrations

"""
Migration 0162: A.D. registration fields and wording.

- Section "AD Registration Info" is now "AD Registration Info and Year".
- New, after AD No. in that section:
    Year            (ad_year) year picker of 2001-3001; shows once an AD No.
                    is entered and is then required, so every AD No. has its year
    IO Name         (ad_io_name) officers of the user's police station
                    (options_source /api/ad/officers/ -> the engine's officer picker)
    IO Designation  (ad_io_designation) dropdown of all active designations
                    (options_source /api/options/designations/), as on the NC form
- "SDM Sent" / "SDM Sent Date" read "SDM/ACP Sent" / "SDM/ACP Sent Date".
Idempotent; backwards restores the old wording and removes the new fields.
"""

TEMPLATE_NAME = 'AD Form Fields'
OLD_SECTION = 'AD Registration Info'
NEW_SECTION = 'AD Registration Info and Year'
AD_NO_KEY = 'case_number'

# field_key -> FieldTemplateField values (all in NEW_SECTION, after AD No. = 10)
NEW_FIELDS = {
    'ad_year': {
        'field_label': 'Year',
        'field_type': 'year',
        'is_required': True,
        'display_order': 20,
        'options_source': 'years:2001-3001',
        # Shown (and required) once an AD No. is entered
        'depends_on_field_key': AD_NO_KEY,
        'depends_on_value': None,
    },
    'ad_io_name': {
        'field_label': 'IO Name',
        'field_type': 'text',
        'is_required': False,
        'display_order': 30,
        'options_source': '/api/ad/officers/',
        'depends_on_field_key': None,
        'depends_on_value': None,
    },
    'ad_io_designation': {
        'field_label': 'IO Designation',
        'field_type': 'dropdown',
        'is_required': False,
        'display_order': 40,
        'options_source': '/api/options/designations/',
        'depends_on_field_key': None,
        'depends_on_value': None,
    },
}

LABELS = {
    # field_key: (old label, new label)
    'ad_sdm_sent': ('SDM Sent', 'SDM/ACP Sent'),
    'ad_sdm_sent_date': ('SDM Sent Date', 'SDM/ACP Sent Date'),
}


def forwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is None:
        return
    fields = FieldTemplateField.objects.filter(template=tmpl)
    fields.filter(section=OLD_SECTION).update(section=NEW_SECTION)
    for key, values in NEW_FIELDS.items():
        FieldTemplateField.objects.update_or_create(
            template=tmpl,
            field_key=key,
            defaults={
                **values,
                'field_source': 'custom',
                'section': NEW_SECTION,
                'parent_field_key': None,
            },
        )
    for key, (_, new) in LABELS.items():
        fields.filter(field_key=key).update(field_label=new)


def backwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is None:
        return
    fields = FieldTemplateField.objects.filter(template=tmpl)
    fields.filter(field_key__in=list(NEW_FIELDS)).delete()
    fields.filter(section=NEW_SECTION).update(section=OLD_SECTION)
    for key, (old, _) in LABELS.items():
        fields.filter(field_key=key).update(field_label=old)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0161_ad_unknown_deceased_multiple'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
