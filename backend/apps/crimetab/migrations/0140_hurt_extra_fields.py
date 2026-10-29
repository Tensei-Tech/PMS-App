from django.db import migrations
from django.db.models import Q

"""
Migration 0140: "Hurt Extra Fields" for Hurt category (data only)

Template: "Hurt Extra Fields" (store_values_in_table = True)
Linked to: Hurt category (code 121, STAND_HURT, and category_name 'Hurt')

Section: Injured Person Details
Repeating Group: Injured Persons (hurt_injured_persons)
  Child fields:
  - Personal Details:
    - Name (text)
    - Age (number, digits:3)
    - Gender (dropdown, /api/options/gender/)
    - Mobile (mobile)
    - Aadhaar (aadhaar)
    - PAN (text)
  - Person Deceased (radio, Yes/No)
    - If YES:
      - Date & Time of Death (datetime)
      - Inquest Panchanama (radio, Yes/No)
        - If YES: Date & Time (datetime)
      - Exhumation Panchanama (radio, Yes/No)
        - If YES: Date & Time (datetime)
      - Postmortem (radio, Yes/No)
        - If YES:
          - Postmortem Date (date)
          - Postmortem Time (time)
          - Postmortem Report Sent (radio, Yes/No)
            - If YES: Sent Date (date), Sent Time (time)
          - Viscera Sent to FSL (radio, Yes/No)
            - If YES:
              - Sent Date (date), Sent Time (time)
              - FSL Report (radio, Yes/No)
                - If YES: Report Date (date), Report Time (time)

Answers are stored as rows in tenant case_extra_field_values table.
Idempotent.
"""

TEMPLATE_NAME = 'Hurt Extra Fields'
CATEGORY_NAME = 'Hurt'
CATEGORY_CODES = ['121', 'STAND_HURT']
YES_NO = '/api/options/yes_no/'
GENDER = '/api/options/gender/'
YES = 'Yes'

SEC_INJURED = 'Injured Person Details'
GROUP_KEY = 'hurt_injured_persons'

# (label, key, type, section, order, depends_on_key, depends_on_val, options_source, parent_field_key)
FIELDS = [
    ('Injured Persons', GROUP_KEY, 'repeating_group', SEC_INJURED, 10, None, None, None, None),

    # Personal Details
    ('Name', 'hurt_injured_name', 'text', SEC_INJURED, 20, None, None, None, GROUP_KEY),
    ('Age', 'hurt_injured_age', 'number', SEC_INJURED, 30, None, None, 'digits:3', GROUP_KEY),
    ('Gender', 'hurt_injured_gender', 'dropdown', SEC_INJURED, 40, None, None, GENDER, GROUP_KEY),
    ('Mobile', 'hurt_injured_mobile', 'mobile', SEC_INJURED, 50, None, None, None, GROUP_KEY),
    ('Aadhaar', 'hurt_injured_aadhaar', 'aadhaar', SEC_INJURED, 60, None, None, None, GROUP_KEY),
    ('PAN', 'hurt_injured_pan', 'text', SEC_INJURED, 70, None, None, None, GROUP_KEY),

    # Person deceased
    ('Person Deceased', 'hurt_person_deceased', 'radio', SEC_INJURED, 80, None, None, YES_NO, GROUP_KEY),

    # If Person deceased == Yes: Date & Time of Death
    ('Date & Time of Death', 'hurt_death_datetime', 'datetime', SEC_INJURED, 90,
     'hurt_person_deceased', YES, None, GROUP_KEY),

    # Inquest Panchanama (Appears if Person Died == Yes)
    ('Inquest Panchanama', 'hurt_inquest_panchanama', 'radio', SEC_INJURED, 100,
     'hurt_person_deceased', YES, YES_NO, GROUP_KEY),
    ('Inquest Panchanama Date & Time', 'hurt_inquest_datetime', 'datetime', SEC_INJURED, 110,
     'hurt_inquest_panchanama', YES, None, GROUP_KEY),

    # Exhumation Panchanama (Appears if Person Died == Yes)
    ('Exhumation Panchanama', 'hurt_exhumation_panchanama', 'radio', SEC_INJURED, 120,
     'hurt_person_deceased', YES, YES_NO, GROUP_KEY),
    ('Exhumation Panchanama Date & Time', 'hurt_exhumation_datetime', 'datetime', SEC_INJURED, 130,
     'hurt_exhumation_panchanama', YES, None, GROUP_KEY),

    # Postmortem (Appears if Person Died == Yes)
    ('Postmortem', 'hurt_postmortem', 'radio', SEC_INJURED, 140,
     'hurt_person_deceased', YES, YES_NO, GROUP_KEY),
    ('Postmortem Date', 'hurt_postmortem_date', 'date', SEC_INJURED, 150,
     'hurt_postmortem', YES, None, GROUP_KEY),
    ('Postmortem Time', 'hurt_postmortem_time', 'time', SEC_INJURED, 160,
     'hurt_postmortem', YES, None, GROUP_KEY),

    # Postmortem Report Sent (Appears if Postmortem == Yes)
    ('Postmortem Report Sent', 'hurt_pm_report_sent', 'radio', SEC_INJURED, 170,
     'hurt_postmortem', YES, YES_NO, GROUP_KEY),
    ('Postmortem Report Sent Date', 'hurt_pm_report_sent_date', 'date', SEC_INJURED, 180,
     'hurt_pm_report_sent', YES, None, GROUP_KEY),
    ('Postmortem Report Sent Time', 'hurt_pm_report_sent_time', 'time', SEC_INJURED, 190,
     'hurt_pm_report_sent', YES, None, GROUP_KEY),

    # Viscera Sent to FSL (Appears if Postmortem == Yes)
    ('Viscera Sent to FSL', 'hurt_viscera_fsl', 'radio', SEC_INJURED, 200,
     'hurt_postmortem', YES, YES_NO, GROUP_KEY),
    ('Viscera Sent Date', 'hurt_viscera_fsl_date', 'date', SEC_INJURED, 210,
     'hurt_viscera_fsl', YES, None, GROUP_KEY),
    ('Viscera Sent Time', 'hurt_viscera_fsl_time', 'time', SEC_INJURED, 220,
     'hurt_viscera_fsl', YES, None, GROUP_KEY),

    # FSL Report (Appears if Viscera Sent to FSL == Yes)
    ('FSL Report', 'hurt_fsl_report', 'radio', SEC_INJURED, 230,
     'hurt_viscera_fsl', YES, YES_NO, GROUP_KEY),
    ('FSL Report Date', 'hurt_fsl_report_date', 'date', SEC_INJURED, 240,
     'hurt_fsl_report', YES, None, GROUP_KEY),
    ('FSL Report Time', 'hurt_fsl_report_time', 'time', SEC_INJURED, 250,
     'hurt_fsl_report', YES, None, GROUP_KEY),
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
        ('crimetab', '0139_extortion_extra_fields'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
