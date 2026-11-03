import importlib

from django.db import migrations

"""
Migration 0172: A.D. "Deceased & Inquiry Details" repeats per dead person

The card now holds one list, "Deceased Person" (Add 1 / Add 2 ...). Each person
has their own:
  Identity (Known / Unknown) with the Known or Unknown details,
  Post Mortem, Preserve, FSL / CA, Cause of Death, Procedural Details.
Those headings show inside each person (field_config 'heading').

- New repeating_group ad_persons (one row open at start); the fields above
  become its children with their keys, types and conditions unchanged.
- The Known ("Deceased") and "Unknown Deceased" lists are gone: one row is one
  person, so their fields sit straight in the row.
- "Seized Items" is a text box per person (items one per line) instead of a
  list, as a list cannot sit inside a list.
- ad.list_card_fields reads the person rows.
- Saved cases in every state schema: each Known / Unknown person becomes a
  row; the case's Post Mortem ... Procedural answers go to person #1 (seized
  items as "name - description" lines). Empty answers are dropped.
Idempotent; backwards restores the lists and moves person #1's answers back
(other persons' Post Mortem ... answers are dropped).
"""

TEMPLATE_NAME = 'AD Form Fields'
SECTION = 'Deceased Details'
CARD = 'Deceased & Inquiry Details'
GROUP_KEY = 'ad_persons'
GROUP_LABEL = 'Deceased Person'
GROUP_ORDER = 100
IDENTITY_KEY = 'ad_deceased_identity'
KNOWN_GROUP = 'ad_deceased'
UNKNOWN_GROUP = 'ad_unknown_deceased'
SEIZED_KEY = 'ad_seized_items'
SEIZED_CHILDREN = ('ad_seized_item_name', 'ad_seized_item_description')
DATE_SUFFIX = '_date'

KNOWN_KEYS = [
    'ad_deceased_name', 'ad_deceased_age', 'ad_deceased_gender', 'ad_deceased_occupation',
    'ad_deceased_mobile', 'ad_deceased_aadhaar', 'ad_deceased_religion', 'ad_deceased_caste',
    'ad_deceased_pan',
]
UNKNOWN_KEYS = [
    'ad_unknown_approx_age', 'ad_unknown_gender', 'ad_unknown_skin_colour', 'ad_unknown_height',
    'ad_unknown_identification_mark', 'ad_unknown_injury', 'ad_unknown_physical_description',
    'ad_shodh_patrika', 'ad_gazette', 'ad_media_publication', 'ad_dna_sent_ca',
    'ad_dna_report_received', 'ad_fingerprint_taken', 'ad_body_funeral_police',
    'ad_body_funeral_relative',
    'ad_relative_name', 'ad_relative_relation', 'ad_relative_age', 'ad_relative_gender',
    'ad_relative_occupation', 'ad_relative_mobile', 'ad_relative_aadhaar',
    'ad_relative_religion', 'ad_relative_caste',
]
# Case-level answers that become each person's: heading -> keys (form order)
INQUIRY = {
    'Post Mortem': ['ad_postmortem', 'ad_postmortem_date', 'ad_pm_report', 'ad_pm_report_date'],
    'Preserve': ['ad_preserve', 'ad_preserve_other'],
    'FSL / CA': ['ad_fsl_ca_sent', 'ad_fsl_ca_sent_date', SEIZED_KEY],
    'Cause of Death': ['ad_cause_of_death', 'ad_cause_of_death_other'],
    'Procedural Details': ['ad_inquest_panchanama', 'ad_exhumation_panchanama'],
}
INQUIRY_KEYS = [k for keys in INQUIRY.values() for k in keys]
# Saved answers that move with them (checkbox date-times)
INQUIRY_ANSWER_KEYS = INQUIRY_KEYS + [
    'ad_inquest_panchanama' + DATE_SUFFIX, 'ad_exhumation_panchanama' + DATE_SUFFIX,
]
UNKNOWN_ANSWER_KEYS = UNKNOWN_KEYS + [k + DATE_SUFFIX for k in UNKNOWN_KEYS[7:15]]
CHILD_KEYS = [IDENTITY_KEY] + KNOWN_KEYS + UNKNOWN_KEYS + INQUIRY_KEYS

OLD_CARD_FIELDS = ('case_number,ad_deceased_identity,ad_deceased.ad_deceased_name,ad_cause_of_death,'
                   'ad_postmortem+ad_postmortem_date,ad_sdm_granted+ad_sdm_granted_date')
NEW_CARD_FIELDS = ('case_number,ad_persons.ad_deceased_identity,ad_persons.ad_deceased_name,'
                   'ad_persons.ad_cause_of_death,ad_persons.ad_postmortem_date,'
                   'ad_sdm_granted+ad_sdm_granted_date')

_each_schema = importlib.import_module(
    'apps.crimetab.migrations.0167_ad_yes_no_to_checkboxes'
)._each_schema


def _blank(value):
    # An unticked checkbox (false) is not saved either
    return value is None or value is False or value == '' or value == [] or value == {}


def _set_config(field, **changes):
    config = dict(field.field_config or {})
    for key, value in changes.items():
        if value is None:
            config.pop(key, None)
        else:
            config[key] = value
    if config != (field.field_config or {}):
        field.field_config = config
        field.save(update_fields=['field_config'])


# ── Fields ───────────────────────────────────────────────────────────────────
def _fields_forwards(apps):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is None:
        return
    FieldTemplateField.objects.update_or_create(
        template=tmpl, field_key=GROUP_KEY,
        defaults={
            'field_label': GROUP_LABEL, 'field_source': 'custom',
            'field_type': 'repeating_group', 'is_required': False,
            'section': SECTION, 'display_order': GROUP_ORDER,
            'options_source': None, 'parent_field_key': None,
            'depends_on_field_key': None, 'depends_on_value': None,
            'field_config': {'card': CARD, 'start_with_one_row': True},
        },
    )
    fields = FieldTemplateField.objects.filter(template=tmpl)
    fields.filter(field_key__in=CHILD_KEYS).update(parent_field_key=GROUP_KEY, section=SECTION)
    fields.filter(field_key__in=KNOWN_KEYS).update(
        depends_on_field_key=IDENTITY_KEY, depends_on_value='Known')
    # The person's own Unknown fields (the relative's keep "Body Funeral by Relative")
    fields.filter(field_key__in=UNKNOWN_KEYS[:15]).update(
        depends_on_field_key=IDENTITY_KEY, depends_on_value='Unknown')
    fields.filter(field_key=SEIZED_KEY).update(field_type='textarea')
    fields.filter(field_key__in=(KNOWN_GROUP, UNKNOWN_GROUP) + SEIZED_CHILDREN).delete()

    _set_config(fields.get(field_key=IDENTITY_KEY), heading=SECTION)
    for heading, keys in INQUIRY.items():
        f = fields.filter(field_key=keys[0]).first()
        if f is not None:
            _set_config(f, heading=heading)


def _fields_backwards(apps):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is None:
        return
    common = {'field_source': 'custom', 'is_required': False, 'options_source': None,
              'field_config': {'card': CARD}}
    groups = [
        (KNOWN_GROUP, 'Deceased', SECTION, 110, None, (IDENTITY_KEY, 'Known')),
        (UNKNOWN_GROUP, 'Unknown Deceased', SECTION, 199, None, (IDENTITY_KEY, 'Unknown')),
        ('ad_seized_item_name', 'Item Name', 'FSL / CA', 621, SEIZED_KEY, None),
        ('ad_seized_item_description', 'Description', 'FSL / CA', 622, SEIZED_KEY, None),
    ]
    for key, label, section, order, parent, depends in groups:
        FieldTemplateField.objects.update_or_create(
            template=tmpl, field_key=key,
            defaults={**common, 'field_label': label, 'section': section,
                      'display_order': order, 'parent_field_key': parent,
                      'field_type': 'repeating_group' if parent is None else 'text',
                      'depends_on_field_key': depends[0] if depends else None,
                      'depends_on_value': depends[1] if depends else None},
        )
    fields = FieldTemplateField.objects.filter(template=tmpl)
    fields.filter(field_key__in=KNOWN_KEYS).update(
        parent_field_key=KNOWN_GROUP, depends_on_field_key=None, depends_on_value=None)
    fields.filter(field_key__in=UNKNOWN_KEYS[:15]).update(
        parent_field_key=UNKNOWN_GROUP, depends_on_field_key=None, depends_on_value=None)
    fields.filter(field_key__in=UNKNOWN_KEYS[15:]).update(parent_field_key=UNKNOWN_GROUP)
    fields.filter(field_key=IDENTITY_KEY).update(parent_field_key=None)
    fields.filter(field_key=SEIZED_KEY).update(field_type='repeating_group')
    for heading, keys in INQUIRY.items():
        fields.filter(field_key__in=keys).update(parent_field_key=None, section=heading)
    for f in fields.filter(field_key__in=[IDENTITY_KEY] + [k[0] for k in INQUIRY.values()]):
        _set_config(f, heading=None)
    fields.filter(field_key=GROUP_KEY).delete()


def _card_setting(apps, old, new):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    ModuleSetting.objects.filter(
        module_key='ad', setting_key='list_card_fields', setting_value=old,
    ).update(setting_value=new)


# ── Saved cases ──────────────────────────────────────────────────────────────
def _seized_text(rows):
    if isinstance(rows, str):
        return rows.strip()
    lines = []
    for row in rows if isinstance(rows, list) else []:
        if isinstance(row, dict):
            parts = [str(row.get(k) or '').strip() for k in SEIZED_CHILDREN]
            line = ' - '.join(p for p in parts if p)
            if line:
                lines.append(line)
    return '\n'.join(lines)


def _rows(value):
    return [r for r in value if isinstance(r, dict)] if isinstance(value, list) else []


def _to_persons(extra):
    """Old answers -> (new extra_fields, changed?)."""
    old_keys = [IDENTITY_KEY, KNOWN_GROUP, UNKNOWN_GROUP] + INQUIRY_ANSWER_KEYS
    if GROUP_KEY in extra or not any(k in extra for k in old_keys):
        return extra, False
    extra = dict(extra)
    identity = extra.pop(IDENTITY_KEY, None)
    persons = []
    for row in _rows(extra.pop(KNOWN_GROUP, None)):
        person = {k: v for k, v in row.items() if k in KNOWN_KEYS and not _blank(v)}
        if person:
            persons.append({IDENTITY_KEY: 'Known', **person})
    for row in _rows(extra.pop(UNKNOWN_GROUP, None)):
        person = {k: v for k, v in row.items() if k in UNKNOWN_ANSWER_KEYS and not _blank(v)}
        if person:
            persons.append({IDENTITY_KEY: 'Unknown', **person})
    if not persons and not _blank(identity):
        persons.append({IDENTITY_KEY: identity})

    inquiry = {}
    for key in INQUIRY_ANSWER_KEYS:
        value = extra.pop(key, None)
        if key == SEIZED_KEY:
            value = _seized_text(value)
        if not _blank(value):
            inquiry[key] = value
    if inquiry:
        if not persons:
            persons.append({})
        persons[0].update(inquiry)
    if persons:
        extra[GROUP_KEY] = persons
    return extra, True


def _from_persons(extra):
    if GROUP_KEY not in extra:
        return extra, False
    extra = dict(extra)
    persons = _rows(extra.pop(GROUP_KEY))
    if not persons:
        return extra, True
    first = persons[0]
    identity = first.get(IDENTITY_KEY)
    if identity:
        extra[IDENTITY_KEY] = identity
    known = [{k: v for k, v in p.items() if k in KNOWN_KEYS} for p in persons
             if p.get(IDENTITY_KEY) == 'Known']
    unknown = [{k: v for k, v in p.items() if k in UNKNOWN_ANSWER_KEYS} for p in persons
               if p.get(IDENTITY_KEY) == 'Unknown']
    if any(known):
        extra[KNOWN_GROUP] = [r for r in known if r]
    if any(unknown):
        extra[UNKNOWN_GROUP] = [r for r in unknown if r]
    for key in INQUIRY_ANSWER_KEYS:
        value = first.get(key)
        if key == SEIZED_KEY and isinstance(value, str):
            value = [{SEIZED_CHILDREN[0]: line.strip()} for line in value.splitlines() if line.strip()]
        if not _blank(value):
            extra[key] = value
    return extra, True


def _convert_cases(convert):
    from apps.cases.models import CaseRecord
    for record in CaseRecord.objects.filter(module_key='ad'):
        extra, changed = convert(record.extra_fields or {})
        if changed and extra != record.extra_fields:
            record.extra_fields = extra
            record.save(update_fields=['extra_fields'])


def forwards(apps, schema_editor):
    _fields_forwards(apps)
    _card_setting(apps, OLD_CARD_FIELDS, NEW_CARD_FIELDS)
    _each_schema(schema_editor, lambda: _convert_cases(_to_persons))


def backwards(apps, schema_editor):
    _fields_backwards(apps)
    _card_setting(apps, NEW_CARD_FIELDS, OLD_CARD_FIELDS)
    _each_schema(schema_editor, lambda: _convert_cases(_from_persons))


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0171_common_form_evidence_dates'),
        ('cases', '0006_caserecord_disposal_date'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
