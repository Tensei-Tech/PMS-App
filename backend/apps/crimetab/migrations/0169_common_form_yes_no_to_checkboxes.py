import importlib

from django.db import migrations

"""
Migration 0169: Common Form Yes / No questions become checkboxes

Witness Summons, Vehicle Log Book Entry and Mobile Spot Recording (radios with
the Yes / No options, 0062 / 0063 / 0107) are now checkboxes. Ticking one shows
what "Yes" showed: the Vehicle Log Book date and reason, the Mobile Spot
Recording date.

- The fields' type becomes checkbox and their Yes / No options source is cleared.
- Fields shown on "Yes" are shown while the box is ticked (no depends_on_value).
- Saved cases in every state schema: "Yes" becomes ticked (true); "No" is
  removed, as an unticked box is not saved.
Idempotent; backwards restores the radios and "Yes" answers.
"""

TEMPLATE_NAME = 'Common Form Baseline Template'
YES_NO = '/api/options/yes_no/'
YES = 'Yes'

KEYS = [
    'witness_summons',
    'vehicle_log_book_entry',
    'mobile_spot_recording',
]

_each_schema = importlib.import_module(
    'apps.crimetab.migrations.0167_ad_yes_no_to_checkboxes'
)._each_schema


def _convert_cases(to_checkbox):
    from apps.cases.models import CaseRecord
    for record in CaseRecord.objects.filter(extra_fields__has_any_keys=KEYS):
        extra = dict(record.extra_fields or {})
        for key in KEYS:
            if key not in extra:
                continue
            answer = str(extra[key]).strip().lower()
            if to_checkbox:
                if answer in ('yes', 'true', '1'):
                    extra[key] = True
                elif answer in ('no', 'false', '0'):
                    extra.pop(key)
            elif extra[key] is True or answer in ('true', '1'):
                extra[key] = YES
        if extra != record.extra_fields:
            record.extra_fields = extra
            record.save(update_fields=['extra_fields'])


def _set_fields(apps, to_checkbox):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    fields = FieldTemplateField.objects.filter(template__template_name=TEMPLATE_NAME)
    if to_checkbox:
        fields.filter(field_key__in=KEYS).update(field_type='checkbox', options_source=None)
        fields.filter(depends_on_field_key__in=KEYS, depends_on_value=YES).update(
            depends_on_value=None)
    else:
        fields.filter(field_key__in=KEYS).update(field_type='radio', options_source=YES_NO)
        fields.filter(depends_on_field_key__in=KEYS, depends_on_value__isnull=True).update(
            depends_on_value=YES)


def forwards(apps, schema_editor):
    _set_fields(apps, to_checkbox=True)
    _each_schema(schema_editor, lambda: _convert_cases(to_checkbox=True))


def backwards(apps, schema_editor):
    _set_fields(apps, to_checkbox=False)
    _each_schema(schema_editor, lambda: _convert_cases(to_checkbox=False))


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0168_ad_deceased_and_inquiry_card'),
        ('cases', '0006_caserecord_disposal_date'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
