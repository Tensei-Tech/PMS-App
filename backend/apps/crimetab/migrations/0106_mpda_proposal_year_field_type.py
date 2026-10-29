from django.db import migrations, models

"""
Migration 0106: 'year' field type; MPDA Proposal Year uses it

- Adds field type 'year' to the form engine (state only; field_type has no DB
  check): a dropdown of 2001-2100 that can also be typed into, where a short
  year means 20xx ('03' -> 2003, '00' -> 2100).
- Switches only mpda_proposal_year in the MPDA Proposal Template to it
  (is_required unchanged).
"""

TEMPLATE_NAME = 'MPDA Proposal Template'
KEY = 'mpda_proposal_year'


def forwards(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME, field_key=KEY, field_type='text'
    ).update(field_type='year')


def backwards(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME, field_key=KEY, field_type='year'
    ).update(field_type='text')


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0105_mpda_detention_dates_side_by_side'),
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
                    ('aadhaar', 'Aadhaar Number (12 digits)'),
                    ('year', 'Year (2001-2100)'),
                ],
                default='text',
                max_length=20,
            ),
        ),
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
