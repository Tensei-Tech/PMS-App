from django.db import migrations

"""
Migration 0079: MPDA detention period = Start Date + End Date, only when Detained = Yes

The two existing date fields (and columns) are reused, so jail / release
counts keep working:
  mpda_detention_date             "Detention Date"            -> "Detention Start Date"
  mpda_detention_completion_date  "Detention Completion Date" -> "Detention End Date"
Both are shown only when Detained is Yes (the Yes value comes from the
'yes_no' option group). Also adds the "end before start" message setting.
"""

TEMPLATE_NAME = 'MPDA Proposal Template'
DETAINED_KEY = 'mpda_detained'

# key: (new label, old label, old depends_on_field_key, old depends_on_value)
FIELDS = {
    'mpda_detention_date': ('Detention Start Date', 'Detention Date', DETAINED_KEY, 'Yes'),
    'mpda_detention_completion_date': ('Detention End Date', 'Detention Completion Date', None, None),
}
SETTING = ('detention_end_before_start_message',
           'Detention End Date cannot be before Detention Start Date.')


def forwards(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    OptionValue = apps.get_model('crimetab', 'OptionValue')
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    yes = OptionValue.objects.filter(option_group='yes_no', is_active=True).first()
    yes_value = yes.option_value if yes else 'Yes'
    for key, (label, _old_label, _k, _v) in FIELDS.items():
        FieldTemplateField.objects.filter(template__template_name=TEMPLATE_NAME, field_key=key).update(
            field_label=label, depends_on_field_key=DETAINED_KEY, depends_on_value=yes_value,
        )
    ModuleSetting.objects.get_or_create(module_key='mpda', setting_key=SETTING[0],
                                        defaults={'setting_value': SETTING[1]})


def backwards(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    for key, (_label, old_label, old_key, old_value) in FIELDS.items():
        FieldTemplateField.objects.filter(template__template_name=TEMPLATE_NAME, field_key=key).update(
            field_label=old_label, depends_on_field_key=old_key, depends_on_value=old_value,
        )
    ModuleSetting.objects.filter(module_key='mpda', setting_key=SETTING[0]).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0078_mpda_crime_totals_order'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
