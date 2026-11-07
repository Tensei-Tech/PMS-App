from django.db import migrations

"""
Migration 0161: an A.D. case can have more than one unknown deceased.

The "Unknown Deceased Details" fields (0125) were single answers. They now sit
in an "Unknown Deceased" list (Add 1 / Add 2 ...), like the Known "Deceased"
list: each person has the approximate age, gender, description, Shodh Patrika
... body funeral checkboxes and, when "Body Funeral by Relative" is ticked, the
relative's details.

- New repeating_group field ad_unknown_deceased, shown on Deceased Identity =
  Unknown (the condition the single fields had).
- The single fields become its children; the relative fields keep their
  dependency on ad_body_funeral_relative, now checked within each person's row.
- Saved cases: single answers move into person #1 of the list, so nothing is
  lost. Backwards moves person #1 back and drops any further persons' answers.
Idempotent.
"""

TEMPLATE_NAME = 'AD Form Fields'
SECTION = 'Unknown Deceased Details'
GROUP_KEY = 'ad_unknown_deceased'
GROUP_LABEL = 'Unknown Deceased'
GROUP_ORDER = 199
IDENTITY_KEY = 'ad_deceased_identity'
UNKNOWN = 'Unknown'
BY_RELATIVE_KEY = 'ad_body_funeral_relative'
CHECKBOX_DATE_SUFFIX = '_date'

# The person's own fields: shown on Unknown before, now shown by the group.
PERSON_KEYS = [
    'ad_unknown_approx_age',
    'ad_unknown_gender',
    'ad_unknown_skin_colour',
    'ad_unknown_height',
    'ad_unknown_identification_mark',
    'ad_unknown_injury',
    'ad_unknown_physical_description',
    'ad_shodh_patrika',
    'ad_gazette',
    'ad_media_publication',
    'ad_dna_sent_ca',
    'ad_dna_report_received',
    'ad_fingerprint_taken',
    'ad_body_funeral_police',
    'ad_body_funeral_relative',
]
# Shown when Body Funeral by Relative is ticked (kept, now per row).
RELATIVE_KEYS = [
    'ad_relative_name',
    'ad_relative_relation',
    'ad_relative_age',
    'ad_relative_gender',
    'ad_relative_occupation',
    'ad_relative_mobile',
    'ad_relative_aadhaar',
    'ad_relative_religion',
    'ad_relative_caste',
]
CHILD_KEYS = PERSON_KEYS + RELATIVE_KEYS
# Saved answer keys that belong to a person (checkboxes may carry a date)
ANSWER_KEYS = CHILD_KEYS + [k + CHECKBOX_DATE_SUFFIX for k in PERSON_KEYS]


def _blank(value):
    return value is None or value == '' or value == [] or value == {}


def forwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    CaseRecord = apps.get_model('cases', 'CaseRecord')

    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is not None:
        FieldTemplateField.objects.update_or_create(
            template=tmpl,
            field_key=GROUP_KEY,
            defaults={
                'field_label': GROUP_LABEL,
                'field_source': 'custom',
                'field_type': 'repeating_group',
                'is_required': False,
                'section': SECTION,
                'display_order': GROUP_ORDER,
                'options_source': None,
                'parent_field_key': None,
                'depends_on_field_key': IDENTITY_KEY,
                'depends_on_value': UNKNOWN,
            },
        )
        fields = FieldTemplateField.objects.filter(template=tmpl)
        fields.filter(field_key__in=PERSON_KEYS).update(
            parent_field_key=GROUP_KEY,
            depends_on_field_key=None,
            depends_on_value=None,
        )
        fields.filter(field_key__in=RELATIVE_KEYS).update(
            parent_field_key=GROUP_KEY,
        )

    # Saved single answers -> person #1
    for record in CaseRecord.objects.filter(extra_fields__has_any_keys=ANSWER_KEYS):
        extra = dict(record.extra_fields or {})
        person = {}
        for key in ANSWER_KEYS:
            if key in extra:
                value = extra.pop(key)
                if not _blank(value):
                    person[key] = value
        if person and not extra.get(GROUP_KEY):
            extra[GROUP_KEY] = [person]
        record.extra_fields = extra
        record.save(update_fields=['extra_fields'])


def backwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    CaseRecord = apps.get_model('cases', 'CaseRecord')

    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is not None:
        fields = FieldTemplateField.objects.filter(template=tmpl)
        fields.filter(field_key__in=PERSON_KEYS).update(
            parent_field_key=None,
            depends_on_field_key=IDENTITY_KEY,
            depends_on_value=UNKNOWN,
        )
        fields.filter(field_key__in=RELATIVE_KEYS).update(parent_field_key=None)
        fields.filter(field_key=GROUP_KEY).delete()

    # Person #1 -> single answers
    for record in CaseRecord.objects.filter(extra_fields__has_key=GROUP_KEY):
        extra = dict(record.extra_fields or {})
        rows = extra.pop(GROUP_KEY, None)
        first = rows[0] if isinstance(rows, list) and rows else {}
        if isinstance(first, dict):
            for key in ANSWER_KEYS:
                if key in first and not _blank(first[key]):
                    extra.setdefault(key, first[key])
        record.extra_fields = extra
        record.save(update_fields=['extra_fields'])


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0160_restore_dar_irad_nafis_tiles'),
        ('cases', '0006_caserecord_disposal_date'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
