from django.db import migrations
from django.db.models import Q

"""
Migration 0149: "Gambling Extra Fields" for Gambling (data only)

Template: "Gambling Extra Fields" (store_values_in_table = True)
Linked to: Gambling (code 603, STAND_GAMBLING)

Sections:
1. Search Warrant: Warrant Type (Search Warrant), Issued By Name, Issued By
   Designation (SDPO / ACP), Spot (Close / Open)
2. A. House / Property Owner Details: Name, Age, Gender, Occupation, Mobile Number,
   Aadhaar Number, PAN Number, Religion, Caste, Address
3. B. Search / Property Details: Address of Place Searched, Electricity Bill Taken
   (Yes/No), Water Bill Taken (Yes/No), Address Proof / Search Details

Answers are stored as rows in tenant case_extra_field_values table.
Idempotent.
"""

TEMPLATE_NAME = 'Gambling Extra Fields'
CATEGORY_CODES = ('603', 'STAND_GAMBLING')
CATEGORY_NAME = 'Gambling'
YES_NO = '/api/options/yes_no/'
GENDER = '/api/options/gender/'

OPTION_GROUPS = {
    'gambling_warrant_types': ['Search Warrant'],
    'gambling_warrant_issuers': ['SDPO', 'ACP'],
    'gambling_spot_types': ['Close', 'Open'],
}


def _opt(group):
    return f'/api/options/{group}/'


SEC_WARRANT = 'Search Warrant'
SEC_OWNER = 'A. House / Property Owner Details'
SEC_PROPERTY = 'B. Search / Property Details'

# (label, key, type, section, order, options_source)
FIELDS = [
    # 1. Search Warrant
    ('Warrant Type', 'gmb_warrant_type', 'radio', SEC_WARRANT, 10, _opt('gambling_warrant_types')),
    ('Issued By — Name', 'gmb_warrant_issued_by_name', 'text', SEC_WARRANT, 11, None),
    ('Issued By — Designation', 'gmb_warrant_issued_by_designation', 'radio', SEC_WARRANT, 12,
     _opt('gambling_warrant_issuers')),
    ('Spot', 'gmb_spot_type', 'radio', SEC_WARRANT, 13, _opt('gambling_spot_types')),

    # A. House / Property Owner Details
    ('1. Name', 'gmb_owner_name', 'text', SEC_OWNER, 20, None),
    ('2. Age', 'gmb_owner_age', 'number', SEC_OWNER, 21, 'digits:3'),
    ('3. Gender', 'gmb_owner_gender', 'dropdown', SEC_OWNER, 22, GENDER),
    ('4. Occupation', 'gmb_owner_occupation', 'text', SEC_OWNER, 23, None),
    ('5. Mobile Number', 'gmb_owner_mobile', 'mobile', SEC_OWNER, 24, None),
    ('6. Aadhaar Number', 'gmb_owner_aadhaar', 'aadhaar', SEC_OWNER, 25, None),
    ('7. PAN Number', 'gmb_owner_pan', 'text', SEC_OWNER, 26, None),
    ('8. Religion', 'gmb_owner_religion', 'text', SEC_OWNER, 27, None),
    ('9. Caste', 'gmb_owner_caste', 'text', SEC_OWNER, 28, None),
    ('10. Address', 'gmb_owner_address', 'textarea', SEC_OWNER, 29, None),

    # B. Search / Property Details
    ('11. Address of Place Searched', 'gmb_search_place_address', 'textarea', SEC_PROPERTY, 30, None),
    ('12. Electricity Bill Taken', 'gmb_electricity_bill_taken', 'radio', SEC_PROPERTY, 31, YES_NO),
    ('13. Water Bill Taken', 'gmb_water_bill_taken', 'radio', SEC_PROPERTY, 32, YES_NO),
    ('14. Address Proof / Search Details', 'gmb_address_proof_details', 'textarea', SEC_PROPERTY, 33, None),
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
    for label, key, ftype, section, order, opt_src in FIELDS:
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
        ('crimetab', '0148_prohibition_extra_fields'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
