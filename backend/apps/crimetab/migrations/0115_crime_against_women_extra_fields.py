from django.db import migrations

"""
Migration 0115: "Crime Against Women Extra Fields" (data only)

New bundle (store_values_in_table: answers saved as rows of
case_extra_field_values), linked only to the Crime Against Women categories
(codes '125' and 'STAND_WOMEN'); the Common Form (acts & sections included)
stays as it is. Sections:
    CAW - Victim Details             name (select only: ABC 1, ABC 2, ...), age,
                                     KYC like the Common Form complainant, age
                                     proof (+ Other), relation to accused (+ Other)
    CAW - Medical & Statements       medical, statements, CWC, 164 CrPC / 183 BNSS,
                                     counselling, witnesses, parents / relatives
    CAW - DNA, Post-Mortem & FSL     victim / accused DNA (Y / N / Not Applicable),
                                     on Yes: sent to FSL, FSL report;
                                     post-mortem, on Yes: report, viscera, FSL report
    CAW - Digital & Documentary Evidence
                                     digital evidence, on Yes: platforms (+ Other);
                                     documentary evidence, on Yes: documents list
                                     (type + Other, Add 1 / Add 2 ...); dowry evidence
    CAW - Cyber Crime                URL, user ID, screenshots ... deepfake (Y/N)
    CAW - Acid Attack / Serious Physical Assault
                                     asked first; on Yes: chemical, FSL letter,
                                     official report, photographs
The acts / sections tables are empty in this database, so the dowry and acid
attack checks cannot yet be tied to a BNS section; acid attack is gated by its
own Yes / No question instead.

Option groups: caw_victim_names (ABC 1 .. ABC 20), caw_age_proofs, yes_no_na,
victim_accused_relations, caw_digital_evidence_types, caw_document_types.
Every field optional. Idempotent.
"""

TEMPLATE_NAME = 'Crime Against Women Extra Fields'
CATEGORY_CODES = ('125', 'STAND_WOMEN')
YES = 'Yes'
OTHER = 'Other'

VICTIM_NAMES = 'caw_victim_names'
AGE_PROOFS = 'caw_age_proofs'
YES_NO_NA = 'yes_no_na'
RELATIONS = 'victim_accused_relations'
DIGITAL = 'caw_digital_evidence_types'
DOCUMENTS = 'caw_document_types'
OPTIONS = {
    VICTIM_NAMES: [f'ABC {i}' for i in range(1, 21)],
    AGE_PROOFS: ['TC / Bonafide Certificate', 'Aadhaar Card', 'Ossification Test', OTHER],
    YES_NO_NA: ['Yes', 'No', 'Not Applicable'],
    RELATIONS: ['Husband', 'Wife', 'Father', 'Mother', 'Son', 'Daughter', 'Brother', 'Sister',
                'Father-in-law', 'Mother-in-law', 'Brother-in-law', 'Sister-in-law',
                'Son-in-law', 'Daughter-in-law', 'Uncle', 'Aunt', 'Cousin', 'Grandfather',
                'Grandmother', 'Stepfather', 'Stepmother', 'Guardian', 'Relative',
                'Neighbour', 'Friend', 'Teacher', 'Employer', 'Colleague', 'Known Person',
                'Stranger', OTHER],
    DIGITAL: ['WhatsApp', 'SMS', 'Call Recording', 'Instagram', 'Facebook', 'Threads',
              'X (formerly Twitter)', 'TikTok', 'Snapchat', 'Telegram', OTHER],
    DOCUMENTS: ['Marriage Certificate', 'Divorce / Separation Documents', 'Previous Complaint',
                'Court Orders', OTHER],
}


def opt(group):
    return f'/api/options/{group}/'


YES_NO = opt('yes_no')

VICTIM = 'CAW - Victim Details'
STATEMENTS = 'CAW - Medical & Statements'
DNA = 'CAW - DNA, Post-Mortem & FSL'
EVIDENCE = 'CAW - Digital & Documentary Evidence'
CYBER = 'CAW - Cyber Crime'
ACID = 'CAW - Acid Attack / Serious Physical Assault'

# (label, key, type, section, order, options_source, parent_field_key, depends_on (key, value) or None)
FIELDS = [
    ('Victim Name', 'caw_victim_name', 'dropdown', VICTIM, 10, opt(VICTIM_NAMES), None, None),
    ('Victim Age', 'caw_victim_age', 'number', VICTIM, 20, None, None, None),
    ('Victim Gender', 'caw_victim_gender', 'dropdown', VICTIM, 30, opt('gender'), None, None),
    ('Victim Occupation', 'caw_victim_occupation', 'text', VICTIM, 40, None, None, None),
    ('Victim Mobile', 'caw_victim_mobile', 'mobile', VICTIM, 50, None, None, None),
    ('Victim Aadhaar', 'caw_victim_aadhaar', 'aadhaar', VICTIM, 60, None, None, None),
    ('Victim PAN', 'caw_victim_pan', 'text', VICTIM, 70, None, None, None),
    ('Victim Religion', 'caw_victim_religion', 'text', VICTIM, 80, None, None, None),
    ('Victim Caste', 'caw_victim_caste', 'text', VICTIM, 90, None, None, None),
    ('Age Proof', 'caw_age_proof', 'dropdown', VICTIM, 100, opt(AGE_PROOFS), None, None),
    ('Other Age Proof (type)', 'caw_age_proof_other', 'text', VICTIM, 105, None, None, ('caw_age_proof', OTHER)),
    ('Relation to Accused', 'caw_relation_to_accused', 'dropdown', VICTIM, 110, opt(RELATIONS), None, None),
    ('Other Relation (type)', 'caw_relation_other', 'text', VICTIM, 115, None, None, ('caw_relation_to_accused', OTHER)),
    ('Victim Address', 'caw_victim_address', 'textarea', VICTIM, 120, None, None, None),

    ('Medical of Victim', 'caw_victim_medical', 'radio', STATEMENTS, 210, YES_NO, None, None),
    ('Medical of Accused', 'caw_accused_medical', 'radio', STATEMENTS, 220, YES_NO, None, None),
    ("Victim's Statement", 'caw_victim_statement', 'radio', STATEMENTS, 230, YES_NO, None, None),
    ('Statement Taken by Lady Officer', 'caw_statement_by_lady_officer', 'radio', STATEMENTS, 240, YES_NO, None, None),
    ('CWC Statement', 'caw_cwc_statement', 'radio', STATEMENTS, 250, YES_NO, None, None),
    ('164 CrPC / 183 BNSS Statement', 'caw_164_statement', 'radio', STATEMENTS, 260, YES_NO, None, None),
    ('Counselling', 'caw_counselling', 'radio', STATEMENTS, 270, YES_NO, None, None),
    ('Witness Examined', 'caw_witness_examined', 'radio', STATEMENTS, 280, opt(YES_NO_NA), None, None),
    ('Statements of Parents / Relatives', 'caw_parents_statements', 'radio', STATEMENTS, 290, opt(YES_NO_NA), None, None),

    ('DNA Sample of Victim Taken', 'caw_victim_dna', 'radio', DNA, 310, opt(YES_NO_NA), None, None),
    ('Victim Sample Sent to FSL', 'caw_victim_fsl_sent', 'radio', DNA, 320, YES_NO, None, ('caw_victim_dna', YES)),
    ('Victim FSL Report Received', 'caw_victim_fsl_report', 'radio', DNA, 330, YES_NO, None, ('caw_victim_dna', YES)),
    ('DNA Sample of Accused Taken', 'caw_accused_dna', 'radio', DNA, 340, opt(YES_NO_NA), None, None),
    ('Accused Sample Sent to FSL', 'caw_accused_fsl_sent', 'radio', DNA, 350, YES_NO, None, ('caw_accused_dna', YES)),
    ('Accused FSL Report Received', 'caw_accused_fsl_report', 'radio', DNA, 360, YES_NO, None, ('caw_accused_dna', YES)),
    ('Post-Mortem', 'caw_postmortem', 'radio', DNA, 370, YES_NO, None, None),
    ('Post-Mortem Report Received', 'caw_pm_report_received', 'radio', DNA, 380, YES_NO, None, ('caw_postmortem', YES)),
    ('Viscera Sent to FSL', 'caw_viscera_fsl_sent', 'radio', DNA, 390, YES_NO, None, ('caw_postmortem', YES)),
    ('Viscera FSL Report Received', 'caw_viscera_fsl_report', 'radio', DNA, 400, YES_NO, None, ('caw_postmortem', YES)),

    ('Digital & Electronic Evidence', 'caw_digital_evidence', 'radio', EVIDENCE, 510, opt(YES_NO_NA), None, None),
    ('Digital Evidence Source', 'caw_digital_evidence_types', 'multi_select', EVIDENCE, 520, opt(DIGITAL), None, ('caw_digital_evidence', YES)),
    ('Other Digital Source (type)', 'caw_digital_evidence_other', 'text', EVIDENCE, 530, None, None, ('caw_digital_evidence_types', OTHER)),
    ('Documentary Evidence Taken', 'caw_documentary_evidence', 'radio', EVIDENCE, 540, opt(YES_NO_NA), None, None),
    ('Documents', 'caw_documents', 'repeating_group', EVIDENCE, 550, None, None, ('caw_documentary_evidence', YES)),
    ('Document Type', 'caw_document_type', 'dropdown', EVIDENCE, 551, opt(DOCUMENTS), 'caw_documents', None),
    ('Other Document (type)', 'caw_document_other', 'text', EVIDENCE, 552, None, 'caw_documents', ('caw_document_type', OTHER)),
    ('Dowry Demand Evidence Collected', 'caw_dowry_evidence', 'radio', EVIDENCE, 560, YES_NO, None, None),

    ('URL / Profile Link Preserved', 'caw_url_preserved', 'radio', CYBER, 610, YES_NO, None, None),
    ('Username / User ID Preserved', 'caw_user_id_preserved', 'radio', CYBER, 620, YES_NO, None, None),
    ('Screenshots Taken', 'caw_screenshots_taken', 'radio', CYBER, 630, YES_NO, None, None),
    ('Screen Recording', 'caw_screen_recording', 'radio', CYBER, 640, YES_NO, None, None),
    ('Platform Preservation Request Initiated (where applicable)', 'caw_platform_preservation', 'radio', CYBER, 650, YES_NO, None, None),
    ('IP / Log Information Taken', 'caw_ip_log_taken', 'radio', CYBER, 660, YES_NO, None, None),
    ('Fake Profile Identity Investigated', 'caw_fake_profile_investigated', 'radio', CYBER, 670, YES_NO, None, None),
    ('Morphed / Deepfake Content Preserved', 'caw_deepfake_preserved', 'radio', CYBER, 680, YES_NO, None, None),

    ('Acid Attack / Serious Physical Assault Case', 'caw_acid_attack', 'radio', ACID, 710, YES_NO, None, None),
    ('Chemical / Container Recovered', 'caw_chemical_recovered', 'radio', ACID, 720, YES_NO, None, ('caw_acid_attack', YES)),
    ('Letter to FSL', 'caw_acid_fsl_letter', 'radio', ACID, 730, YES_NO, None, ('caw_acid_attack', YES)),
    ('Official Report Received', 'caw_acid_report_received', 'radio', ACID, 740, YES_NO, None, ('caw_acid_attack', YES)),
    ('Photographs Documented as per Procedure', 'caw_acid_photographs', 'radio', ACID, 750, YES_NO, None, ('caw_acid_attack', YES)),
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
    for label, key, ftype, section, order, options, parent, depends in FIELDS:
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
                'parent_field_key': parent,
                'depends_on_field_key': depends[0] if depends else None,
                'depends_on_value': depends[1] if depends else None,
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
        ('crimetab', '0114_murder_extra_fields'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
