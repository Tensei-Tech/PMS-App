from django.db import migrations
from django.db.models import Q

"""
Migration 0141: "Mischief Extra Fields" for Mischief category (data only)

Template: "Mischief Extra Fields" (store_values_in_table = True)
Linked to: Mischief category (code 110, STAND_MISCHIEF, and category_name 'Mischief')

Section: Damage Property Details
Repeating Group: Damage Property (mischief_damaged_property)
  Child fields:
  - Description (text)
  - Value (₹) (number)

Auto-sum field:
  - Total Value (₹) (number, sum:mischief_damaged_property.mischief_property_value)

Answers are stored as rows in tenant case_extra_field_values table.
Idempotent.
"""

TEMPLATE_NAME = 'Mischief Extra Fields'
CATEGORY_NAME = 'Mischief'
CATEGORY_CODES = ['110', 'STAND_MISCHIEF']

SEC_DAMAGE = 'Damage Property Details'
GROUP_KEY = 'mischief_damaged_property'

# (label, key, type, section, order, depends_on_key, depends_on_val, options_source, parent_field_key)
FIELDS = [
    ('Damage Property', GROUP_KEY, 'repeating_group', SEC_DAMAGE, 10, None, None, None, None),

    # Child fields of damage property
    ('Description', 'mischief_property_description', 'text', SEC_DAMAGE, 20, None, None, None, GROUP_KEY),
    ('Value (₹)', 'mischief_property_value', 'number', SEC_DAMAGE, 30, None, None, None, GROUP_KEY),

    # Total Value (auto calculated sum)
    ('Total Value (₹)', 'mischief_total_value', 'number', SEC_DAMAGE, 40, None, None,
     f'sum:{GROUP_KEY}.mischief_property_value', None),
]


def forwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')

    tmpl, _ = FieldTemplate.objects.update_or_create(
        template_name=TEMPLATE_NAME, defaults={'store_values_in_table': True}
    )
    for label, key, ftype, section, order, parent_k, parent_v, opt_src, grp in FIELDS:
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
                'depends_on_field_key': parent_k,
                'depends_on_value': parent_v,
                'parent_field_key': grp or '',
            },
        )

    for cat in CaseCategory.objects.filter(
        Q(category_code__in=CATEGORY_CODES) | Q(category_name__iexact=CATEGORY_NAME)
    ):
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
        ('crimetab', '0140_hurt_extra_fields'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
