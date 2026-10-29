from django.db import migrations
from django.db.models import Q

"""
Migration 0148: "Prohibition Extra Fields" for Prohibition (data only)

Template: "Prohibition Extra Fields" (store_values_in_table = True)
Linked to: Prohibition (code 602, STAND_PROHIBITION)

Sections:
1. Seized Liquor: checkboxes Homemade Liquor / Country Liquor (Desi Daru) / Foreign Liquor.
   For each ticked liquor: Sample Taken (Yes/No), Total Seized in (ml / Liter, one of the
   two), Total Seized Quantity (number), Destroyed Date.
2. Preventive: Section 93 of Prohibition Act (Yes/No), and its date if Yes.

Answers are stored as rows in tenant case_extra_field_values table.
Idempotent.
"""

TEMPLATE_NAME = 'Prohibition Extra Fields'
CATEGORY_CODES = ('602', 'STAND_PROHIBITION')
CATEGORY_NAME = 'Prohibition'
YES_NO = '/api/options/yes_no/'
YES = 'Yes'

HOMEMADE = 'Homemade Liquor'
COUNTRY = 'Country Liquor (Desi Daru)'
FOREIGN = 'Foreign Liquor'

OPTION_GROUPS = {
    'prohibition_liquor_types': [HOMEMADE, COUNTRY, FOREIGN],
    'prohibition_quantity_units': ['ml', 'Liter'],
}

UNITS = '/api/options/prohibition_quantity_units/'
SEC_LIQUOR = 'Seized Liquor'
SEC_PREVENTIVE = 'Preventive'

# (label, key, type, section, order, depends_on_key, depends_on_val, options_source)
FIELDS = [
    ('Seized Liquor (select all that apply)', 'proh_liquor_types', 'multi_select', SEC_LIQUOR, 10,
     None, None, '/api/options/prohibition_liquor_types/'),
]

# The same questions for each liquor, shown once that liquor is ticked.
for order, (name, prefix) in enumerate(((HOMEMADE, 'proh_homemade'), (COUNTRY, 'proh_country'),
                                        (FOREIGN, 'proh_foreign')), start=1):
    base = 10 + order * 10
    FIELDS += [
        (f'{name}: Sample Taken', f'{prefix}_sample_taken', 'radio', SEC_LIQUOR, base + 1,
         'proh_liquor_types', name, YES_NO),
        (f'{name}: Total Seized in (ml / Liter)', f'{prefix}_unit', 'radio', SEC_LIQUOR, base + 2,
         'proh_liquor_types', name, UNITS),
        (f'{name}: Total Seized Quantity', f'{prefix}_quantity', 'number', SEC_LIQUOR, base + 3,
         'proh_liquor_types', name, None),
        (f'{name}: Destroyed Date', f'{prefix}_destroyed_date', 'date', SEC_LIQUOR, base + 4,
         'proh_liquor_types', name, None),
    ]

FIELDS += [
    ('Section 93 of Prohibition Act', 'proh_section_93', 'radio', SEC_PREVENTIVE, 60, None, None, YES_NO),
    ('Section 93 Date', 'proh_section_93_date', 'date', SEC_PREVENTIVE, 61, 'proh_section_93', YES, None),
]


def forwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
    OptionValue = apps.get_model('crimetab', 'OptionValue')

    for group, values in OPTION_GROUPS.items():
        for i, value in enumerate(values, 1):
            OptionValue.objects.get_or_create(
                option_group=group, option_value=value,
                defaults={'display_order': i * 10, 'is_active': True},
            )

    tmpl, _ = FieldTemplate.objects.update_or_create(
        template_name=TEMPLATE_NAME, defaults={'store_values_in_table': True}
    )
    for label, key, ftype, section, order, parent_k, parent_v, opt_src in FIELDS:
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
                'parent_field_key': '',
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
        ('crimetab', '0147_normal_accident_extra_fields'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
