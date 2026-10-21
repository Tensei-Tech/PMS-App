from django.db import migrations, models

"""
Migration 0084: mobile / email field types; RTI Mobile No. and E-mail use them

- Adds field types 'mobile' (optional, exactly 10 digits when filled) and
  'email' (optional, valid address when filled) to the form engine (state only;
  field_type has no DB check).
- Switches only the RTI Form fields rti_mobile_no and rti_email to these types.
  Both stay optional (is_required unchanged).
"""

TEMPLATE_NAME = 'RTI Form'
FIELD_TYPES = {'rti_mobile_no': 'mobile', 'rti_email': 'email'}


def use_new_types(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    for key, ftype in FIELD_TYPES.items():
        FieldTemplateField.objects.filter(
            template__template_name=TEMPLATE_NAME, field_key=key, field_type='text'
        ).update(field_type=ftype)


def restore_text_type(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    for key, ftype in FIELD_TYPES.items():
        FieldTemplateField.objects.filter(
            template__template_name=TEMPLATE_NAME, field_key=key, field_type=ftype
        ).update(field_type='text')


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0083_rti_transferred_date'),
    ]

    operations = [
        migrations.AlterField(
            model_name='fieldtemplatefield',
            name='field_type',
            field=models.CharField(
                choices=[
                    ('text', 'Text Field'),
                    ('textarea', 'Multi-line Text Area'),
                    ('number', 'Numeric Field'),
                    ('date', 'Date Picker'),
                    ('datetime', 'Date-Time Picker'),
                    ('dropdown', 'Dropdown Select'),
                    ('checkbox', 'Checkbox Toggle'),
                    ('radio', 'Radio Button Group'),
                    ('chips', 'Chips Selector'),
                    ('file', 'File Upload'),
                    ('multi_select', 'Multi-Select Dropdown'),
                    ('repeating_group', 'Repeating Group'),
                    ('charges', 'Act & Section Picker'),
                    ('mobile', 'Mobile Number (10 digits)'),
                    ('email', 'E-mail Address'),
                ],
                default='text',
                max_length=20,
            ),
        ),
        migrations.RunPython(use_new_types, reverse_code=restore_text_type),
    ]
