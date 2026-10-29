from django.db import migrations
from django.db.models import Q

"""
Migration 0150: "CBT Extra Fields" for CBT (Criminal Breach of Trust) (data only)

Template: "CBT Extra Fields" (store_values_in_table = True)
Linked to: CBT (code 108)

Section: Property Details
Repeating Group: Property (cbt_properties), add with +
  - Property Description (text, at most 20 words: options source 'words:20')
  - Value (₹) (number)
Total Value (₹) (number, sum:cbt_properties.cbt_property_value, filled automatically)

Answers are stored as rows in tenant case_extra_field_values table.
Idempotent.
"""

TEMPLATE_NAME = 'CBT Extra Fields'
CATEGORY_CODES = ('108',)
CATEGORY_NAME = 'CBT'

SEC_PROPERTY = 'Property Details'
GROUP_KEY = 'cbt_properties'

# (label, key, type, section, order, options_source, parent_field_key)
FIELDS = [
    ('Property', GROUP_KEY, 'repeating_group', SEC_PROPERTY, 10, None, None),
    ('Property Description (in 20 words)', 'cbt_property_description', 'text', SEC_PROPERTY, 11, 'words:20', GROUP_KEY),
    ('Value (₹)', 'cbt_property_value', 'number', SEC_PROPERTY, 12, None, GROUP_KEY),
    ('Total Value (₹)', 'cbt_total_value', 'number', SEC_PROPERTY, 20, f'sum:{GROUP_KEY}.cbt_property_value', None),
]


def forwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')

    tmpl, _ = FieldTemplate.objects.update_or_create(
        template_name=TEMPLATE_NAME, defaults={'store_values_in_table': True}
    )
    for label, key, ftype, section, order, opt_src, grp in FIELDS:
        FieldTemplateField.objects.update_or_create(
            template=tmpl,
            field_key=key,
            defaults={
                'field_label': label,
                'field_source': 'custom',
                'field_type': ftype,
                'is_required': False,
                'section': section,
                'display_order': order,
                'options_source': opt_src,
                'depends_on_field_key': None,
                'depends_on_value': None,
                'parent_field_key': grp or '',
            },
        )

    for cat in CaseCategory.objects.filter(Q(category_code__in=CATEGORY_CODES) | Q(category_name__iexact=CATEGORY_NAME)):
        CategoryFieldTemplate.objects.get_or_create(category=cat, template=tmpl)


def backwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')

    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if not tmpl:
        return
    CategoryFieldTemplate.objects.filter(template=tmpl).delete()
    FieldTemplateField.objects.filter(template=tmpl).delete()
    tmpl.delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0149_gambling_extra_fields'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
