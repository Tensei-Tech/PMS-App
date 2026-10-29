from django.db import migrations
from django.db.models import Q

"""
Migration 0145: Extra fields for Assault on Public Servant and Riot (data only)

Linked to: Assault on Public Servant (code 111) and Riot (code 106)

1. Injured Person Details: the existing "Hurt Extra Fields" template (0140), linked
   as it is (Injured Persons list: Name, Age, Gender, Mobile, Aadhaar, PAN,
   Person Deceased -> Date & Time of Death, Inquest / Exhumation Panchanama,
   Postmortem -> Report Sent, Viscera Sent to FSL -> FSL Report).
2. New template "Non-Applicant Details" (store_values_in_table = True):
   Non-Applicants list, at most 3 (options source 'max:3'): Name, Age (Years),
   Gender, Caste, Profession / Occupation, Mobile Number, Address, Aadhaar Card Number.

Answers are stored as rows in tenant case_extra_field_values table.
Idempotent.
"""

HURT_TEMPLATE = 'Hurt Extra Fields'
TEMPLATE_NAME = 'Non-Applicant Details'
CATEGORY_NAMES = ('Assault on Public Servant', 'Riot')
CATEGORY_CODES = ('111', '106')
GENDER = '/api/options/gender/'

SEC_NON_APPLICANT = 'Non-Applicant Details'
GROUP_KEY = 'non_applicants'

# (label, key, type, section, order, options_source, parent_field_key)
FIELDS = [
    ('Non-Applicants (maximum 3)', GROUP_KEY, 'repeating_group', SEC_NON_APPLICANT, 10, 'max:3', None),
    ('1. Name', 'non_applicant_name', 'text', SEC_NON_APPLICANT, 11, None, GROUP_KEY),
    ('2. Age (Years)', 'non_applicant_age', 'number', SEC_NON_APPLICANT, 12, 'digits:3', GROUP_KEY),
    ('3. Gender', 'non_applicant_gender', 'dropdown', SEC_NON_APPLICANT, 13, GENDER, GROUP_KEY),
    ('4. Caste', 'non_applicant_caste', 'text', SEC_NON_APPLICANT, 14, None, GROUP_KEY),
    ('5. Profession / Occupation', 'non_applicant_occupation', 'text', SEC_NON_APPLICANT, 15, None, GROUP_KEY),
    ('6. Mobile Number', 'non_applicant_mobile', 'mobile', SEC_NON_APPLICANT, 16, None, GROUP_KEY),
    ('7. Address', 'non_applicant_address', 'textarea', SEC_NON_APPLICANT, 17, None, GROUP_KEY),
    ('8. Aadhaar Card Number', 'non_applicant_aadhaar', 'aadhaar', SEC_NON_APPLICANT, 18, None, GROUP_KEY),
]


def _categories(CaseCategory):
    name_q = Q()
    for name in CATEGORY_NAMES:
        name_q |= Q(category_name__iexact=name)
    return CaseCategory.objects.filter(Q(category_code__in=CATEGORY_CODES) | name_q)


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

    hurt = FieldTemplate.objects.filter(template_name=HURT_TEMPLATE).first()
    for cat in _categories(CaseCategory):
        CategoryFieldTemplate.objects.get_or_create(category=cat, template=tmpl)
        if hurt:
            CategoryFieldTemplate.objects.get_or_create(category=cat, template=hurt)


def backwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')

    hurt = FieldTemplate.objects.filter(template_name=HURT_TEMPLATE).first()
    if hurt:
        CategoryFieldTemplate.objects.filter(category__in=_categories(CaseCategory), template=hurt).delete()
    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if not tmpl:
        return
    CategoryFieldTemplate.objects.filter(template=tmpl).delete()
    FieldTemplateField.objects.filter(template=tmpl).delete()
    tmpl.delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0144_kidnapping_missing_extra_fields'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
