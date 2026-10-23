from django.db import migrations

"""
Migration 0110: "POCSO Extra Fields" for POCSO crimes (data only)

- New bundle "POCSO Extra Fields", linked (category_field_templates) only to the
  POCSO categories (codes '604' and 'STAND_POCSO'). Four sections:
    POCSO - Victim Details            name (select only: ABC 1, ABC 2, ...), age,
                                      KYC like the Common Form complainant, age proof
    POCSO - Medical & Statements      medical (victim / accused), statements, CWC,
                                      164 CrPC / 183 BNSS, counselling
    POCSO - DNA & FSL                 victim and accused DNA sample, sent to FSL,
                                      FSL report received
    POCSO - Vehicle & Absconding      SD / case diary vehicle entry, Sec 82, 83 action
- Option groups: pocso_victim_names (ABC 1 .. ABC 20, so the victim's real name is
  never typed) and pocso_age_proofs (TC, Bonafide Certificate, Aadhaar Card,
  Ossification Test, Other).
- Yes/No questions are radios on /api/options/yes_no/; each Date shows only when
  its answer is "Yes". Mobile / Aadhaar use the 'mobile' / 'aadhaar' types.
  Every field is optional.
Values are stored as rows of case_extra_field_values (store_values_in_table). Idempotent.
"""

TEMPLATE_NAME = 'POCSO Extra Fields'
CATEGORY_CODES = ('604', 'STAND_POCSO')
YES_NO = '/api/options/yes_no/'
YES = 'Yes'

VICTIM_NAMES = 'pocso_victim_names'
AGE_PROOFS = 'pocso_age_proofs'
OPTIONS = {
    VICTIM_NAMES: [f'ABC {i}' for i in range(1, 21)],
    AGE_PROOFS: ['TC', 'Bonafide Certificate', 'Aadhaar Card', 'Ossification Test', 'Other'],
}

VICTIM = 'POCSO - Victim Details'
MEDICAL = 'POCSO - Medical & Statements'
DNA = 'POCSO - DNA & FSL'
ACTION = 'POCSO - Vehicle & Absconding'

# (label, key, type, section, order, options_source, depends_on_key)
FIELDS = [
    ('Victim Name', 'pocso_victim_name', 'dropdown', VICTIM, 10, f'/api/options/{VICTIM_NAMES}/', None),
    ('Victim Age', 'pocso_victim_age', 'number', VICTIM, 20, None, None),
    ('Victim Gender', 'pocso_victim_gender', 'dropdown', VICTIM, 30, '/api/options/gender/', None),
    ('Victim Occupation', 'pocso_victim_occupation', 'text', VICTIM, 40, None, None),
    ('Victim Mobile', 'pocso_victim_mobile', 'mobile', VICTIM, 50, None, None),
    ('Victim Aadhaar', 'pocso_victim_aadhaar', 'aadhaar', VICTIM, 60, None, None),
    ('Victim PAN', 'pocso_victim_pan', 'text', VICTIM, 70, None, None),
    ('Victim Religion', 'pocso_victim_religion', 'text', VICTIM, 80, None, None),
    ('Victim Caste', 'pocso_victim_caste', 'text', VICTIM, 90, None, None),
    ('Age Proof', 'pocso_age_proof', 'dropdown', VICTIM, 100, f'/api/options/{AGE_PROOFS}/', None),
    ('Victim Address', 'pocso_victim_address', 'textarea', VICTIM, 110, None, None),

    ('Medical of Victim', 'pocso_victim_medical', 'radio', MEDICAL, 210, YES_NO, None),
    ('Medical of Victim Date', 'pocso_victim_medical_date', 'date', MEDICAL, 220, None, 'pocso_victim_medical'),
    ('Medical of Accused', 'pocso_accused_medical', 'radio', MEDICAL, 230, YES_NO, None),
    ('Medical of Accused Date', 'pocso_accused_medical_date', 'date', MEDICAL, 240, None, 'pocso_accused_medical'),
    ("Victim's Statement", 'pocso_victim_statement', 'radio', MEDICAL, 250, YES_NO, None),
    ("Victim's Statement Date", 'pocso_victim_statement_date', 'date', MEDICAL, 260, None, 'pocso_victim_statement'),
    ('Statement Taken by Lady Officer', 'pocso_statement_by_lady_officer', 'radio', MEDICAL, 270, YES_NO, None),
    ('CWC Statement', 'pocso_cwc_statement', 'radio', MEDICAL, 280, YES_NO, None),
    ('CWC Statement Date', 'pocso_cwc_statement_date', 'date', MEDICAL, 290, None, 'pocso_cwc_statement'),
    ('164 CrPC / 183 BNSS Statement', 'pocso_164_statement', 'radio', MEDICAL, 300, YES_NO, None),
    ('164 CrPC / 183 BNSS Statement Date', 'pocso_164_statement_date', 'date', MEDICAL, 310, None, 'pocso_164_statement'),
    ('Counselling', 'pocso_counselling', 'radio', MEDICAL, 320, YES_NO, None),
    ('Counselling Date', 'pocso_counselling_date', 'date', MEDICAL, 330, None, 'pocso_counselling'),

    ('DNA Sample of Victim Taken', 'pocso_victim_dna', 'radio', DNA, 410, YES_NO, None),
    ('DNA Sample of Victim Taken Date', 'pocso_victim_dna_date', 'date', DNA, 420, None, 'pocso_victim_dna'),
    ('Victim Sample Sent to FSL', 'pocso_victim_fsl_sent', 'radio', DNA, 430, YES_NO, None),
    ('Victim Sample Sent to FSL Date', 'pocso_victim_fsl_sent_date', 'date', DNA, 440, None, 'pocso_victim_fsl_sent'),
    ('Victim FSL Report Received', 'pocso_victim_fsl_report', 'radio', DNA, 450, YES_NO, None),
    ('Victim FSL Report Received Date', 'pocso_victim_fsl_report_date', 'date', DNA, 460, None, 'pocso_victim_fsl_report'),
    ('DNA Sample of Accused Taken', 'pocso_accused_dna', 'radio', DNA, 470, YES_NO, None),
    ('DNA Sample of Accused Taken Date', 'pocso_accused_dna_date', 'date', DNA, 480, None, 'pocso_accused_dna'),
    ('Accused Sample Sent to FSL', 'pocso_accused_fsl_sent', 'radio', DNA, 490, YES_NO, None),
    ('Accused Sample Sent to FSL Date', 'pocso_accused_fsl_sent_date', 'date', DNA, 500, None, 'pocso_accused_fsl_sent'),
    ('Accused FSL Report Received', 'pocso_accused_fsl_report', 'radio', DNA, 510, YES_NO, None),
    ('Accused FSL Report Received Date', 'pocso_accused_fsl_report_date', 'date', DNA, 520, None, 'pocso_accused_fsl_report'),

    ('Government Vehicle Used: SD Entry of Vehicle Number and Time', 'pocso_govt_vehicle_sd_entry', 'radio', ACTION, 610, YES_NO, None),
    ('Case Diary Vehicle Entry', 'pocso_case_diary_vehicle_entry', 'radio', ACTION, 620, YES_NO, None),
    ('Accused Not Traceable: Action under Section 82, 83 Initiated', 'pocso_sec_82_83_action', 'radio', ACTION, 630, YES_NO, None),
    ('Section 82, 83 Action Date', 'pocso_sec_82_83_action_date', 'date', ACTION, 640, None, 'pocso_sec_82_83_action'),
]


def forwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
    OptionValue = apps.get_model('crimetab', 'OptionValue')

    for group, values in OPTIONS.items():
        for i, value in enumerate(values, 1):
            OptionValue.objects.get_or_create(
                option_group=group, option_value=value,
                defaults={'display_order': i * 10, 'is_active': True},
            )

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
    for cat in CaseCategory.objects.filter(category_code__in=CATEGORY_CODES):
        CategoryFieldTemplate.objects.get_or_create(category=cat, template=tmpl)


def backwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    OptionValue = apps.get_model('crimetab', 'OptionValue')
    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is not None:
        CategoryFieldTemplate.objects.filter(template=tmpl).delete()
        FieldTemplateField.objects.filter(template=tmpl).delete()
        tmpl.delete()
    OptionValue.objects.filter(option_group__in=list(OPTIONS)).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0109_two_four_wheeler_theft_extra_fields'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
