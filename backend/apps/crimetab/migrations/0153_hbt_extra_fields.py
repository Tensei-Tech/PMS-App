from django.db import migrations
from django.db.models import Q

"""
Migration 0153: "HBT Extra Fields" for HBT (House Breaking Theft) (data only)

Template: "HBT Extra Fields" (store_values_in_table = True)
Linked to: HBT (code 105)

Sections:
1. Type of Theft (select all that apply)
2. Stolen Property List (Add Stolen Property): Name of Property *, Description / Markings,
   Value (₹) *; Total Stolen Value (₹) added up automatically
3. Recovered Property List (Add Recovered Item): Recovered Property Name (From Stolen) *,
   Recovered Date & Time *, Recovered From (Accused / Place) *, Value (₹),
   Return to Owner? (Yes/No), Who gave it to? (Authority / Person Name)

Option names carry no commas: a condition on a checkbox list can split a stored
value at commas.

Answers are stored as rows in tenant case_extra_field_values table.
Idempotent.
"""

TEMPLATE_NAME = 'HBT Extra Fields'
CATEGORY_CODES = ('105',)
CATEGORY_NAME = 'HBT'
YES_NO = '/api/options/yes_no/'

OPTION_GROUPS = {
    'hbt_theft_types': [
        'Precious Metal / Jewellery', 'Any Metal (Copper / Iron / Scrap)', 'Diamond and Precious Stone',
        'Vehicle Theft', 'Cattle / Animal Theft', 'Cash', 'ATM and Banking Related',
        'Mobile and Electronic Instrument', 'Metal Wire / Cable Theft', 'Agricultural Produce Theft',
    ],
}

SEC_TYPE = 'Type of Theft'
SEC_STOLEN = 'Stolen Property List'
SEC_RECOVERED = 'Recovered Property List'
STOLEN = 'hbt_stolen_props'
RECOVERED = 'hbt_recovered_props'

# (label, key, type, section, order, options_source, parent_field_key, required)
FIELDS = [
    # 2. Type of Theft
    ('Type of Theft (select all that apply)', 'hbt_theft_types', 'multi_select', SEC_TYPE, 10,
     '/api/options/hbt_theft_types/', None, False),

    # 3. Stolen Property List
    ('Stolen Property (Add Stolen Property)', STOLEN, 'repeating_group', SEC_STOLEN, 20, None, None, False),
    ('1. Name of Property', 'hbt_stolen_name', 'text', SEC_STOLEN, 21, None, STOLEN, True),
    ('2. Description / Markings', 'hbt_stolen_description', 'text', SEC_STOLEN, 22, None, STOLEN, False),
    ('3. Value (₹)', 'hbt_stolen_value', 'number', SEC_STOLEN, 23, None, STOLEN, True),
    ('Total Stolen Value (₹)', 'hbt_stolen_total_value', 'number', SEC_STOLEN, 29,
     f'sum:{STOLEN}.hbt_stolen_value', None, False),

    # 4. Recovered Property List
    ('Recovered Property (Add Recovered Item)', RECOVERED, 'repeating_group', SEC_RECOVERED, 30, None, None, False),
    ('1. Recovered Property Name (From Stolen)', 'hbt_recovered_name', 'text', SEC_RECOVERED, 31,
     None, RECOVERED, True),
    ('2. Recovered Date & Time', 'hbt_recovered_datetime', 'datetime', SEC_RECOVERED, 32, None, RECOVERED, True),
    ('3. Recovered From (Accused / Place)', 'hbt_recovered_from', 'text', SEC_RECOVERED, 33, None, RECOVERED, True),
    ('4. Value (₹)', 'hbt_recovered_value', 'number', SEC_RECOVERED, 34, None, RECOVERED, False),
    ('Return to Owner?', 'hbt_recovered_return_to_owner', 'radio', SEC_RECOVERED, 35, YES_NO, RECOVERED, False),
    ('5. Who gave it to? (Authority / Person Name)', 'hbt_recovered_given_to', 'text', SEC_RECOVERED, 36,
     None, RECOVERED, False),
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
    for label, key, ftype, section, order, opt_src, grp, required in FIELDS:
        FieldTemplateField.objects.update_or_create(
            template=tmpl,
            field_key=key,
            defaults={
                'field_label': label,
                'field_source': 'custom',
                'field_type': ftype,
                'is_required': required,
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
        ('crimetab', '0152_murder_fields_ipc_304a'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
