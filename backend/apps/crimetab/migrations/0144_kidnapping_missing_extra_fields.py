from django.db import migrations
from django.db.models import Q

"""
Migration 0144: "Kidnapping / Missing Extra Fields" for Kidnapping and Missing (data only)

Template: "Kidnapping / Missing Extra Fields" (store_values_in_table = True)
Linked to: Kidnapping (code 120, STAND_KIDNAP) and Missing (code 124, STAND_MISSING)

Sections:
1. Kidnapped Person Detail: Name, Age, Gender, Caste, Address, Mobile No.
2. Found When: Date / Time, SD No., Statement of Kidnapped Person (Yes/No)
3. Custody To (radio: Parents (KYC), Relative, Shelter Home); for Parents (KYC)
   the parent's Name, Relation, Mobile, Aadhaar and Address
4. Statements, each Yes/No and, if Yes, its date: 164/183 BNSS Statement,
   CWC Statement, Medical Statement, In Camera Statement, CA Sent

Replaces the app's built-in Kidnapping section (saved as kidnapping_extra JSON).

Answers are stored as rows in tenant case_extra_field_values table.
Idempotent.
"""

TEMPLATE_NAME = 'Kidnapping / Missing Extra Fields'
CATEGORY_NAMES = ('Kidnapping', 'Missing')
CATEGORY_CODES = ('120', 'STAND_KIDNAP', '124', 'STAND_MISSING')
YES_NO = '/api/options/yes_no/'
GENDER = '/api/options/gender/'
YES = 'Yes'
PARENTS = 'Parents (KYC)'

OPTION_GROUPS = {
    'kidnap_custody_to': [PARENTS, 'Relative', 'Shelter Home'],
}

SEC_PERSON = 'Kidnapped Person Detail'
SEC_FOUND = 'Found When'
SEC_CUSTODY = 'Custody To'
SEC_STATEMENTS = 'Statements'

# (label, key, type, section, order, depends_on_key, depends_on_val, options_source)
FIELDS = [
    # 1. Kidnapped Person Detail
    ('Name', 'kdn_person_name', 'text', SEC_PERSON, 10, None, None, None),
    ('Age', 'kdn_person_age', 'number', SEC_PERSON, 11, None, None, 'digits:3'),
    ('Gender', 'kdn_person_gender', 'dropdown', SEC_PERSON, 12, None, None, GENDER),
    ('Caste', 'kdn_person_caste', 'text', SEC_PERSON, 13, None, None, None),
    ('Address', 'kdn_person_address', 'textarea', SEC_PERSON, 14, None, None, None),
    ('Mobile No.', 'kdn_person_mobile', 'mobile', SEC_PERSON, 15, None, None, None),

    # 2. Found When
    ('Date / Time', 'kdn_found_datetime', 'datetime', SEC_FOUND, 20, None, None, None),
    ('SD No.', 'kdn_found_sd_no', 'text', SEC_FOUND, 21, None, None, None),
    ('Statement of Kidnapped Person', 'kdn_person_statement', 'radio', SEC_FOUND, 22, None, None, YES_NO),

    # 3. Custody To
    ('Custody To', 'kdn_custody_to', 'radio', SEC_CUSTODY, 30, None, None, '/api/options/kidnap_custody_to/'),
    ("Parent's Name", 'kdn_parent_name', 'text', SEC_CUSTODY, 31, 'kdn_custody_to', PARENTS, None),
    ('Relation (Father / Mother / Guardian)', 'kdn_parent_relation', 'text', SEC_CUSTODY, 32,
     'kdn_custody_to', PARENTS, None),
    ("Parent's Mobile No.", 'kdn_parent_mobile', 'mobile', SEC_CUSTODY, 33, 'kdn_custody_to', PARENTS, None),
    ("Parent's Aadhaar", 'kdn_parent_aadhaar', 'aadhaar', SEC_CUSTODY, 34, 'kdn_custody_to', PARENTS, None),
    ("Parent's Address", 'kdn_parent_address', 'textarea', SEC_CUSTODY, 35, 'kdn_custody_to', PARENTS, None),

    # 4. Statements (Yes/No, and the date if Yes)
    ('164/183 BNSS Statement', 'kdn_bnss_statement', 'radio', SEC_STATEMENTS, 40, None, None, YES_NO),
    ('164/183 BNSS Statement Date', 'kdn_bnss_statement_date', 'date', SEC_STATEMENTS, 41,
     'kdn_bnss_statement', YES, None),
    ('CWC Statement', 'kdn_cwc_statement', 'radio', SEC_STATEMENTS, 42, None, None, YES_NO),
    ('CWC Statement Date', 'kdn_cwc_statement_date', 'date', SEC_STATEMENTS, 43, 'kdn_cwc_statement', YES, None),
    ('Medical Statement', 'kdn_medical_statement', 'radio', SEC_STATEMENTS, 44, None, None, YES_NO),
    ('Medical Statement Date', 'kdn_medical_statement_date', 'date', SEC_STATEMENTS, 45,
     'kdn_medical_statement', YES, None),
    ('In Camera Statement', 'kdn_in_camera_statement', 'radio', SEC_STATEMENTS, 46, None, None, YES_NO),
    ('In Camera Statement Date', 'kdn_in_camera_statement_date', 'date', SEC_STATEMENTS, 47,
     'kdn_in_camera_statement', YES, None),
    ('CA Sent', 'kdn_ca_sent', 'radio', SEC_STATEMENTS, 48, None, None, YES_NO),
    ('CA Sent Date', 'kdn_ca_sent_date', 'date', SEC_STATEMENTS, 49, 'kdn_ca_sent', YES, None),
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

    name_q = Q()
    for name in CATEGORY_NAMES:
        name_q |= Q(category_name__iexact=name)
    for cat in CaseCategory.objects.filter(Q(category_code__in=CATEGORY_CODES) | name_q):
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
        ('crimetab', '0143_robbery_dacoity_extra_fields'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
