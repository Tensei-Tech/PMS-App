from django.db import migrations

"""
Migration 0166: A.D. "Post Mortem" card asks for the PM report (data only)

After "PM" / "PM Date" the card now has:
- "PM Report" (ad_pm_report): Yes / No
- "PM Report Date" (ad_pm_report_date): shown when PM Report = Yes

Same pattern as the Murder form's Post-Mortem Report fields.
Idempotent; backwards removes the two fields.
"""

TEMPLATE_NAME = 'AD Form Fields'
SECTION = 'Post Mortem'
YES_NO = '/api/options/yes_no/'

FIELDS = [
    # (label, key, type, order, options_source, depends_on)
    ('PM Report', 'ad_pm_report', 'radio', 420, YES_NO, None),
    ('PM Report Date', 'ad_pm_report_date', 'date', 430, None, ('ad_pm_report', 'Yes')),
]


def forwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')

    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is None:
        return
    for label, key, ftype, order, options, depends in FIELDS:
        FieldTemplateField.objects.update_or_create(
            template=tmpl,
            field_key=key,
            defaults={
                'field_label': label,
                'field_source': 'custom',
                'field_type': ftype,
                'is_required': False,
                'section': SECTION,
                'display_order': order,
                'options_source': options,
                'parent_field_key': None,
                'depends_on_field_key': depends[0] if depends else None,
                'depends_on_value': depends[1] if depends else None,
            },
        )


def backwards(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME,
        field_key__in=[key for _, key, *_ in FIELDS],
    ).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0165_ad_unknown_deceased_in_deceased_details'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
