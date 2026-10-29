from django.db import migrations

"""
Migration 0059: N.C. officer and designation pickers (data only, NC Form fields only)

- IO Name / Registered By Name: officers of the user's police station
  (options_source /api/nc/officers/ -> the engine's officer picker)
- IO Designation / Registered By Designation: dropdown of all active designations
  from the designations master (options_source /api/options/designations/)

Idempotent; touches only fields of the "NC Form" template.
"""

TEMPLATE_NAME = 'NC Form'

# field_key: (new field_type, new options_source, old field_type, old options_source)
CHANGES = {
    'nc_io_name': ('text', '/api/nc/officers/', 'text', None),
    'nc_reg_name': ('text', '/api/nc/officers/', 'text', None),
    'nc_io_designation': ('dropdown', '/api/options/designations/', 'text', None),
    'nc_reg_designation': ('dropdown', '/api/options/designations/', 'text', None),
}


def _apply(apps, new):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    for key, (ntype, nsrc, otype, osrc) in CHANGES.items():
        ftype, src = (ntype, nsrc) if new else (otype, osrc)
        FieldTemplateField.objects.filter(
            template__template_name=TEMPLATE_NAME, field_key=key
        ).update(field_type=ftype, options_source=src)


def forwards(apps, schema_editor):
    _apply(apps, new=True)


def backwards(apps, schema_editor):
    _apply(apps, new=False)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0058_nc_api_settings'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
