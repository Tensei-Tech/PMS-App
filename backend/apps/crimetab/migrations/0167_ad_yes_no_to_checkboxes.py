import importlib

from django.db import migrations

"""
Migration 0167: A.D. Yes / No questions become checkboxes

Every Yes / No radio on the A.D. form (PM, PM Report, FSL / CA Send,
AD Summary Sent, SDM/ACP Sent, SDM Returned, SDM Granted) is now a checkbox.
Ticking it shows its date (and, for FSL / CA, the seized items), as "Yes" did.

- The fields' type becomes checkbox and their Yes / No options source is cleared.
- Fields shown on "Yes" are shown while the box is ticked (no depends_on_value).
- Saved cases in every state schema: "Yes" becomes ticked (true); "No" is
  removed, as an unticked box is not saved.
- Disposal is "SDM Granted ticked with its date": ad.disposal_value is "true"
  (CaseRecord saves its answer as true) and the Pending message says so.
Idempotent; backwards restores the radios, "Yes" answers and settings.
"""

TEMPLATE_NAME = 'AD Form Fields'
YES_NO = '/api/options/yes_no/'
YES = 'Yes'
NO = 'No'

KEYS = [
    'ad_postmortem',
    'ad_pm_report',
    'ad_fsl_ca_sent',
    'ad_summary_sent',
    'ad_sdm_sent',
    'ad_sdm_returned',
    'ad_sdm_granted',
]

# module_settings (module 'ad'): key -> (old, new)
SETTINGS = {
    'disposal_value': ('Yes', 'true'),
    'pending_definition_message': (
        'Pending: SDM Granted is not yet "Yes" with its date. '
        'A case moves to Disposal when SDM Granted is Yes and the date is filled.',
        'Pending: SDM Granted is not yet ticked with its date. '
        'A case moves to Disposal when SDM Granted is ticked and the date is filled.',
    ),
}

tenant_schemas = importlib.import_module(
    'apps.crimetab.migrations.0133_tenant_module_tables_and_id_sequences'
).tenant_schemas


def _convert_cases(to_checkbox):
    from apps.cases.models import CaseRecord
    for record in CaseRecord.objects.filter(extra_fields__has_any_keys=KEYS):
        extra = dict(record.extra_fields or {})
        for key in KEYS:
            if key not in extra:
                continue
            value = extra[key]
            if to_checkbox:
                if str(value).strip().lower() in ('yes', 'true', '1'):
                    extra[key] = True
                else:
                    extra.pop(key)
            elif value is True or str(value).strip().lower() in ('true', '1', 'yes'):
                extra[key] = YES
        if extra != record.extra_fields:
            record.extra_fields = extra
            # update_fields keeps status as it is; disposal is unchanged since
            # disposal_value changes in step with the saved answer
            record.save(update_fields=['extra_fields'])


def _each_schema(schema_editor, fn):
    """Runs fn in every state schema (tests call forwards with no schema editor)."""
    from django.db import connection as default_connection
    connection = getattr(schema_editor, 'connection', None) or default_connection
    if connection.vendor != 'postgresql':
        fn()
        return
    from apps.core.tenancy import TenantContext
    with connection.cursor() as cursor:
        schemas = tenant_schemas(cursor)
    if not schemas:
        fn()
        return
    for schema in schemas:
        with TenantContext(schema):
            fn()


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


def _set_settings(apps, pick):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    for key, values in SETTINGS.items():
        ModuleSetting.objects.filter(module_key='ad', setting_key=key).update(
            setting_value=pick(values))


def forwards(apps, schema_editor):
    _set_fields(apps, to_checkbox=True)
    _set_settings(apps, lambda v: v[1])
    _each_schema(schema_editor, lambda: _convert_cases(to_checkbox=True))


def backwards(apps, schema_editor):
    _set_fields(apps, to_checkbox=False)
    _set_settings(apps, lambda v: v[0])
    _each_schema(schema_editor, lambda: _convert_cases(to_checkbox=False))


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0166_ad_pm_report'),
        ('cases', '0006_caserecord_disposal_date'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
