from django.db import migrations

"""
Migration 0114: new Murder extra fields (data only)

Adds to "Murder Section Extra Fields" (already linked to the Murder category):
    Deceased Details               name and KYC like the Common Form complainant:
                                   gender, occupation, mobile, Aadhaar, PAN,
                                   religion, caste, address
    Post-Mortem & FSL              post-mortem Y/N + date, post-mortem report Y/N +
                                   date, viscera sent to FSL Y/N + date, FSL report Y/N
    Inquest & Exhumation Panchnama inquest / exhumation panchnama date and time
Yes/No questions are radios on /api/options/yes_no/; each Date shows only when
its answer is "Yes". Mobile / Aadhaar use the 'mobile' / 'aadhaar' types. Every
field is optional. New murder_* keys, so text the removed fields (0113) left in
a case's JSON does not come back. The bundle now stores answers as rows of
case_extra_field_values (store_values_in_table). Idempotent.
"""

TEMPLATE_NAME = 'Murder Section Extra Fields'
YES_NO = '/api/options/yes_no/'
YES = 'Yes'

DECEASED = 'Deceased Details'
PM = 'Post-Mortem & FSL'
PANCHNAMA = 'Inquest & Exhumation Panchnama'

# (label, key, type, section, order, options_source, depends_on_key)
FIELDS = [
    ('Deceased Name', 'murder_deceased_name', 'text', DECEASED, 10, None, None),
    ('Deceased Gender', 'murder_deceased_gender', 'dropdown', DECEASED, 20, '/api/options/gender/', None),
    ('Deceased Occupation', 'murder_deceased_occupation', 'text', DECEASED, 30, None, None),
    ('Deceased Mobile', 'murder_deceased_mobile', 'mobile', DECEASED, 40, None, None),
    ('Deceased Aadhaar', 'murder_deceased_aadhaar', 'aadhaar', DECEASED, 50, None, None),
    ('Deceased PAN', 'murder_deceased_pan', 'text', DECEASED, 60, None, None),
    ('Deceased Religion', 'murder_deceased_religion', 'text', DECEASED, 70, None, None),
    ('Deceased Caste', 'murder_deceased_caste', 'text', DECEASED, 80, None, None),
    ('Deceased Address', 'murder_deceased_address', 'textarea', DECEASED, 90, None, None),

    ('Post-Mortem', 'murder_postmortem', 'radio', PM, 110, YES_NO, None),
    ('Post-Mortem Date', 'murder_postmortem_date', 'date', PM, 120, None, 'murder_postmortem'),
    ('Post-Mortem Report', 'murder_pm_report', 'radio', PM, 130, YES_NO, None),
    ('Post-Mortem Report Date', 'murder_pm_report_date', 'date', PM, 140, None, 'murder_pm_report'),
    ('Viscera Sent to FSL', 'murder_viscera_fsl', 'radio', PM, 150, YES_NO, None),
    ('Viscera Sent to FSL Date', 'murder_viscera_fsl_date', 'date', PM, 160, None, 'murder_viscera_fsl'),
    ('FSL Report', 'murder_fsl_report', 'radio', PM, 170, YES_NO, None),

    ('Inquest Panchnama Date & Time', 'murder_inquest_datetime', 'datetime', PANCHNAMA, 210, None, None),
    ('Exhumation Panchnama Date & Time', 'murder_exhumation_datetime', 'datetime', PANCHNAMA, 220, None, None),
]


def forwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')

    # Answers saved as rows of case_extra_field_values (services/table_field_values.py)
    tmpl, _ = FieldTemplate.objects.update_or_create(
        template_name=TEMPLATE_NAME, defaults={'store_values_in_table': True})
    for label, key, ftype, section, order, options, parent in FIELDS:
        FieldTemplateField.objects.get_or_create(
            template=tmpl,
            field_key=key,
            defaults={
                'field_label': label,
                'field_source': 'custom',
                'field_type': ftype,
                'is_required': False,
                'section': section,
                'display_order': order,
                'options_source': options,
                'depends_on_field_key': parent,
                'depends_on_value': YES if parent else None,
            },
        )
    # Already linked by seed_common_form; make sure every Murder tab has it
    for cat in CaseCategory.objects.filter(category_name='Murder'):
        CategoryFieldTemplate.objects.get_or_create(category=cat, template=tmpl)


def backwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME, field_key__in=[k for _, k, *_ in FIELDS]
    ).delete()
    FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).update(store_values_in_table=False)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0113_remove_old_murder_extra_fields'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
