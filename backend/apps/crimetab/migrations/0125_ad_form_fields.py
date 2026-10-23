from django.db import migrations

"""
Migration 0125: A.D. (Accidental Death) form for the Suicide and Other sub-tabs

The two A.D. sub-tabs (STAND_AD_SUICIDE, STAND_AD_OTHER) stop using the Common
Form Baseline Template and get only the new "AD Form Fields" bundle:
    AD Registration Info      AD No. (key case_number, shown as the case number)
    Deceased Details          Known / Unknown; Known -> list of deceased
                              (Add 1 / Add 2 ...): name, age, gender, occupation,
                              mobile, Aadhaar, religion, caste, PAN
    Unknown Deceased Details  on Unknown: approximate age, gender, skin colour,
                              height, identification mark, injury, physical
                              description; Shodh Patrika ... body funeral by
                              relative (checkboxes); on "Body funeral by relative":
                              relative's name, relation, age, gender, occupation,
                              mobile, Aadhaar, religion, caste
    Post Mortem               Y/N, on Yes: date
    Preserve                  viscera / blood / urine / other (+ type)
    FSL / CA                  Y/N, on Yes: date and the seized items sent
    Cause of Death            dropdown (+ Other: type)
    Procedural Details        Inquest / Exhumation Panchanama (ticking one shows
                              its date and time, saved as <key>_date)
    AD Summary                sent Y/N, on Yes: date
    AD Scrutiny               SDM sent / returned / granted Y/N, on Yes: date
Disposal: "SDM Granted" = Yes with its date (apps.cases.models.is_ad_case_disposed).
Answers stay in the case's extra_fields JSON (store_values_in_table off), where
the status rule reads them. Every field optional. Idempotent.
"""

TEMPLATE_NAME = 'AD Form Fields'
COMMON = 'Common Form Baseline Template'
CATEGORY_CODES = ('STAND_AD_SUICIDE', 'STAND_AD_OTHER')
YES = 'Yes'
OTHER = 'Other'
KNOWN = 'Known'
UNKNOWN = 'Unknown'

IDENTITY = 'ad_deceased_identities'
PRESERVE = 'ad_preserve_types'
CAUSES = 'ad_death_causes'
OPTIONS = {
    IDENTITY: [KNOWN, UNKNOWN],
    PRESERVE: ['Viscera', 'Blood', 'Urine', OTHER],
    CAUSES: ['Hanging', 'Drowning', 'Burning', 'Poisoning', 'Electrocution',
             'Drug Overdose', 'Fall', 'Snake Bite', OTHER, 'Unknown Cause'],
}


def opt(group):
    return f'/api/options/{group}/'


YES_NO = opt('yes_no')
GENDER = opt('gender')

REG = 'AD Registration Info'
DECEASED = 'Deceased Details'
UNKNOWN_SEC = 'Unknown Deceased Details'
PM = 'Post Mortem'
PRESERVE_SEC = 'Preserve'
FSL = 'FSL / CA'
CAUSE = 'Cause of Death'
PROCEDURAL = 'Procedural Details'
SUMMARY = 'AD Summary'
SCRUTINY = 'AD Scrutiny'

IS_UNKNOWN = ('ad_deceased_identity', UNKNOWN)
BY_RELATIVE = ('ad_body_funeral_relative', None)  # checkbox ticked

# (label, key, type, section, order, options_source, parent_field_key, depends_on (key, value) or None)
FIELDS = [
    ('AD No.', 'case_number', 'text', REG, 10, None, None, None),

    ('Deceased Identity', 'ad_deceased_identity', 'radio', DECEASED, 100, opt(IDENTITY), None, None),
    ('Deceased', 'ad_deceased', 'repeating_group', DECEASED, 110, None, None, ('ad_deceased_identity', KNOWN)),
    ('Name', 'ad_deceased_name', 'text', DECEASED, 111, None, 'ad_deceased', None),
    ('Age', 'ad_deceased_age', 'number', DECEASED, 112, None, 'ad_deceased', None),
    ('Gender', 'ad_deceased_gender', 'dropdown', DECEASED, 113, GENDER, 'ad_deceased', None),
    ('Occupation', 'ad_deceased_occupation', 'text', DECEASED, 114, None, 'ad_deceased', None),
    ('Mobile', 'ad_deceased_mobile', 'mobile', DECEASED, 115, None, 'ad_deceased', None),
    ('Aadhaar Card', 'ad_deceased_aadhaar', 'aadhaar', DECEASED, 116, None, 'ad_deceased', None),
    ('Religion', 'ad_deceased_religion', 'text', DECEASED, 117, None, 'ad_deceased', None),
    ('Caste', 'ad_deceased_caste', 'text', DECEASED, 118, None, 'ad_deceased', None),
    ('PAN', 'ad_deceased_pan', 'text', DECEASED, 119, None, 'ad_deceased', None),

    ('Approximate Age', 'ad_unknown_approx_age', 'number', UNKNOWN_SEC, 200, None, None, IS_UNKNOWN),
    ('Gender', 'ad_unknown_gender', 'dropdown', UNKNOWN_SEC, 210, GENDER, None, IS_UNKNOWN),
    ('Skin Colour', 'ad_unknown_skin_colour', 'text', UNKNOWN_SEC, 220, None, None, IS_UNKNOWN),
    ('Height', 'ad_unknown_height', 'text', UNKNOWN_SEC, 230, None, None, IS_UNKNOWN),
    ('Identification Mark', 'ad_unknown_identification_mark', 'text', UNKNOWN_SEC, 240, None, None, IS_UNKNOWN),
    ('Injury', 'ad_unknown_injury', 'text', UNKNOWN_SEC, 250, None, None, IS_UNKNOWN),
    ('Physical Description (Type)', 'ad_unknown_physical_description', 'textarea', UNKNOWN_SEC, 260, None, None, IS_UNKNOWN),
    ('Shodh Patrika', 'ad_shodh_patrika', 'checkbox', UNKNOWN_SEC, 270, None, None, IS_UNKNOWN),
    ('Gazette', 'ad_gazette', 'checkbox', UNKNOWN_SEC, 271, None, None, IS_UNKNOWN),
    ('Media Publication', 'ad_media_publication', 'checkbox', UNKNOWN_SEC, 272, None, None, IS_UNKNOWN),
    ('DNA Sent to CA', 'ad_dna_sent_ca', 'checkbox', UNKNOWN_SEC, 273, None, None, IS_UNKNOWN),
    ('DNA Report Received', 'ad_dna_report_received', 'checkbox', UNKNOWN_SEC, 274, None, None, IS_UNKNOWN),
    ('Fingerprint Taken', 'ad_fingerprint_taken', 'checkbox', UNKNOWN_SEC, 275, None, None, IS_UNKNOWN),
    ('Body Funeral by Police', 'ad_body_funeral_police', 'checkbox', UNKNOWN_SEC, 276, None, None, IS_UNKNOWN),
    ('Body Funeral by Relative', 'ad_body_funeral_relative', 'checkbox', UNKNOWN_SEC, 277, None, None, IS_UNKNOWN),
    ('Relative Name', 'ad_relative_name', 'text', UNKNOWN_SEC, 280, None, None, BY_RELATIVE),
    ('Relation', 'ad_relative_relation', 'text', UNKNOWN_SEC, 281, None, None, BY_RELATIVE),
    ('Relative Age', 'ad_relative_age', 'number', UNKNOWN_SEC, 282, None, None, BY_RELATIVE),
    ('Relative Gender', 'ad_relative_gender', 'dropdown', UNKNOWN_SEC, 283, GENDER, None, BY_RELATIVE),
    ('Relative Occupation', 'ad_relative_occupation', 'text', UNKNOWN_SEC, 284, None, None, BY_RELATIVE),
    ('Relative Mobile Number', 'ad_relative_mobile', 'mobile', UNKNOWN_SEC, 285, None, None, BY_RELATIVE),
    ('Relative Aadhaar Number', 'ad_relative_aadhaar', 'aadhaar', UNKNOWN_SEC, 286, None, None, BY_RELATIVE),
    ('Relative Religion', 'ad_relative_religion', 'text', UNKNOWN_SEC, 287, None, None, BY_RELATIVE),
    ('Relative Caste', 'ad_relative_caste', 'text', UNKNOWN_SEC, 288, None, None, BY_RELATIVE),

    ('PM (Post Mortem)', 'ad_postmortem', 'radio', PM, 400, YES_NO, None, None),
    ('PM Date', 'ad_postmortem_date', 'date', PM, 410, None, None, ('ad_postmortem', YES)),

    ('Preserve', 'ad_preserve', 'multi_select', PRESERVE_SEC, 500, opt(PRESERVE), None, None),
    ('Other Preserve (type)', 'ad_preserve_other', 'text', PRESERVE_SEC, 510, None, None, ('ad_preserve', OTHER)),

    ('FSL / CA Send', 'ad_fsl_ca_sent', 'radio', FSL, 600, YES_NO, None, None),
    ('FSL / CA Send Date', 'ad_fsl_ca_sent_date', 'date', FSL, 610, None, None, ('ad_fsl_ca_sent', YES)),
    ('Seized Items', 'ad_seized_items', 'repeating_group', FSL, 620, None, None, ('ad_fsl_ca_sent', YES)),
    ('Item Name', 'ad_seized_item_name', 'text', FSL, 621, None, 'ad_seized_items', None),
    ('Description', 'ad_seized_item_description', 'text', FSL, 622, None, 'ad_seized_items', None),

    ('Cause of Death', 'ad_cause_of_death', 'dropdown', CAUSE, 700, opt(CAUSES), None, None),
    ('Other Cause (type)', 'ad_cause_of_death_other', 'text', CAUSE, 710, None, None, ('ad_cause_of_death', OTHER)),

    ('Inquest Panchanama', 'ad_inquest_panchanama', 'checkbox', PROCEDURAL, 800, None, None, None),
    ('Exhumation Panchanama', 'ad_exhumation_panchanama', 'checkbox', PROCEDURAL, 810, None, None, None),

    ('AD Summary Sent', 'ad_summary_sent', 'radio', SUMMARY, 900, YES_NO, None, None),
    ('AD Summary Sent Date', 'ad_summary_sent_date', 'date', SUMMARY, 910, None, None, ('ad_summary_sent', YES)),

    ('SDM Sent', 'ad_sdm_sent', 'radio', SCRUTINY, 1000, YES_NO, None, None),
    ('SDM Sent Date', 'ad_sdm_sent_date', 'date', SCRUTINY, 1010, None, None, ('ad_sdm_sent', YES)),
    ('SDM Returned', 'ad_sdm_returned', 'radio', SCRUTINY, 1020, YES_NO, None, None),
    ('SDM Returned Date', 'ad_sdm_returned_date', 'date', SCRUTINY, 1030, None, None, ('ad_sdm_returned', YES)),
    ('SDM Granted', 'ad_sdm_granted', 'radio', SCRUTINY, 1040, YES_NO, None, None),
    ('SDM Granted Date', 'ad_sdm_granted_date', 'date', SCRUTINY, 1050, None, None, ('ad_sdm_granted', YES)),
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

    tmpl, _ = FieldTemplate.objects.update_or_create(
        template_name=TEMPLATE_NAME, defaults={'store_values_in_table': False})
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

    # Only the A.D. fields on the two sub-tabs: drop the Common Form link
    for cat in CaseCategory.objects.filter(category_code__in=CATEGORY_CODES):
        CategoryFieldTemplate.objects.filter(category=cat).exclude(template=tmpl).delete()
        CategoryFieldTemplate.objects.get_or_create(category=cat, template=tmpl)


def backwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
    OptionValue = apps.get_model('crimetab', 'OptionValue')
    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is not None:
        CategoryFieldTemplate.objects.filter(template=tmpl).delete()
        FieldTemplateField.objects.filter(template=tmpl).delete()
        tmpl.delete()
    common = FieldTemplate.objects.filter(template_name=COMMON).first()
    if common is not None:
        for cat in CaseCategory.objects.filter(category_code__in=CATEGORY_CODES):
            CategoryFieldTemplate.objects.get_or_create(category=cat, template=common)
    OptionValue.objects.filter(option_group__in=list(OPTIONS)).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0124_nc_preventive_outward_date'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
