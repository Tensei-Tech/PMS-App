from django.db import migrations
from django.db.models import Q

"""
Migration 0142: "Attempt to Murder Extra Fields" for Attempt to Murder category (data only)

Template: "Attempt to Murder Extra Fields" (store_values_in_table = True)
Linked to: Attempt to Murder category (code 102, STAND_ATTEMPT_TO_MURDER, and category_name 'Attempt to Murder')

Sections:
1. Injured Person Details
   - Quick Action: Same as complainant (checkbox, auto-fills details from complainant)
   - Name (text)
   - Age (number, digits:3)
   - Gender (dropdown, /api/options/gender/)
   - Occupation (text)
   - Mobile (mobile)
   - Aadhaar (aadhaar)
   - PAN (text)
   - Religion (text)
   - Caste (text)

2. Inquest & Exhumation Panchanama
   - Inquest Panchanama (radio, Yes/No)
     - If Yes: Date & Time of Inquest Panchanama (datetime)
   - Exhumation Panchanama (radio, Yes/No)
     - If Yes: Date & Time of Exhumation Panchanama (datetime)

3. Post-Mortem & FSL
   - Postmortem (radio, Yes/No)
     - If Yes:
       - Postmortem Date (date)
       - Postmortem Time (time)
       - Postmortem Report Sent (radio, Yes/No)
         - If Yes: PM Report Sent Date (date), PM Report Sent Time (time)
       - Viscera Sent to FSL (radio, Yes/No)
         - If Yes:
           - Viscera Sent Date (date), Viscera Sent Time (time)
           - FSL Report (radio, Yes/No)
             - If Yes: FSL Report Date (date), FSL Report Time (time)

Answers are stored as rows in tenant case_extra_field_values table.
Idempotent.
"""

TEMPLATE_NAME = 'Attempt to Murder Extra Fields'
CATEGORY_NAME = 'Attempt to Murder'
CATEGORY_CODES = ['102', 'STAND_ATTEMPT_TO_MURDER']
YES_NO = '/api/options/yes_no/'
GENDER = '/api/options/gender/'
YES = 'Yes'

SEC_INJURED = 'Injured Person Details'
SEC_PANCHANAMA = 'Inquest & Exhumation Panchanama'
SEC_PM = 'Post-Mortem & FSL'

# (label, key, type, section, order, depends_on_key, depends_on_val, options_source, parent_field_key)
FIELDS = [
    # 1. Injured Person Details
    ('Same as complainant', 'atm_same_as_complainant', 'checkbox', SEC_INJURED, 5, None, None, None, None),
    ('Name', 'atm_injured_name', 'text', SEC_INJURED, 10, None, None, None, None),
    ('Age', 'atm_injured_age', 'number', SEC_INJURED, 20, None, None, 'digits:3', None),
    ('Gender', 'atm_injured_gender', 'dropdown', SEC_INJURED, 30, None, None, GENDER, None),
    ('Occupation', 'atm_injured_occupation', 'text', SEC_INJURED, 40, None, None, None, None),
    ('Mobile', 'atm_injured_mobile', 'mobile', SEC_INJURED, 50, None, None, None, None),
    ('Aadhaar', 'atm_injured_aadhaar', 'aadhaar', SEC_INJURED, 60, None, None, None, None),
    ('PAN', 'atm_injured_pan', 'text', SEC_INJURED, 70, None, None, None, None),
    ('Religion', 'atm_injured_religion', 'text', SEC_INJURED, 80, None, None, None, None),
    ('Caste', 'atm_injured_caste', 'text', SEC_INJURED, 90, None, None, None, None),

    # 2. Inquest & Exhumation Panchanama
    ('Inquest Panchanama', 'atm_inquest_panchanama', 'radio', SEC_PANCHANAMA, 100, None, None, YES_NO, None),
    ('Date & Time of Inquest Panchanama', 'atm_inquest_datetime', 'datetime', SEC_PANCHANAMA, 110,
     'atm_inquest_panchanama', YES, None, None),
    ('Exhumation Panchanama', 'atm_exhumation_panchanama', 'radio', SEC_PANCHANAMA, 120, None, None, YES_NO, None),
    ('Date & Time of Exhumation Panchanama', 'atm_exhumation_datetime', 'datetime', SEC_PANCHANAMA, 130,
     'atm_exhumation_panchanama', YES, None, None),

    # 3. Post-Mortem & FSL
    ('Postmortem', 'atm_postmortem', 'radio', SEC_PM, 140, None, None, YES_NO, None),
    ('Postmortem Date', 'atm_postmortem_date', 'date', SEC_PM, 150,
     'atm_postmortem', YES, None, None),
    ('Postmortem Time', 'atm_postmortem_time', 'time', SEC_PM, 160,
     'atm_postmortem', YES, None, None),

    ('Postmortem Report Sent', 'atm_pm_report_sent', 'radio', SEC_PM, 170,
     'atm_postmortem', YES, YES_NO, None),
    ('PM Report Sent Date', 'atm_pm_report_sent_date', 'date', SEC_PM, 180,
     'atm_pm_report_sent', YES, None, None),
    ('PM Report Sent Time', 'atm_pm_report_sent_time', 'time', SEC_PM, 190,
     'atm_pm_report_sent', YES, None, None),

    ('Viscera Sent to FSL', 'atm_viscera_fsl', 'radio', SEC_PM, 200,
     'atm_postmortem', YES, YES_NO, None),
    ('Viscera Sent Date', 'atm_viscera_fsl_date', 'date', SEC_PM, 210,
     'atm_viscera_fsl', YES, None, None),
    ('Viscera Sent Time', 'atm_viscera_fsl_time', 'time', SEC_PM, 220,
     'atm_viscera_fsl', YES, None, None),

    ('FSL Report', 'atm_fsl_report', 'radio', SEC_PM, 230,
     'atm_viscera_fsl', YES, YES_NO, None),
    ('FSL Report Date', 'atm_fsl_report_date', 'date', SEC_PM, 240,
     'atm_fsl_report', YES, None, None),
    ('FSL Report Time', 'atm_fsl_report_time', 'time', SEC_PM, 250,
     'atm_fsl_report', YES, None, None),
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
        ('crimetab', '0141_mischief_extra_fields'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
