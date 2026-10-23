from django.db import migrations, models

"""
Migration 0104: MPDA mobile / Aadhaar validation and "Caste" label

- Adds field type 'aadhaar' (optional, exactly 12 digits when filled, typed in
  groups of four: 1234 5678 9012) to the form engine (state only; field_type has
  no DB check).
- MPDA Proposal Template, accused and gang member rows:
    Mobile  -> 'mobile'  (exactly 10 digits when filled)
    Aadhaar -> 'aadhaar'
    label 'Cast' -> 'Caste'
  All stay optional (is_required unchanged).
"""

TEMPLATE_NAME = 'MPDA Proposal Template'
FIELD_TYPES = {
    'mpda_accused_mobile': 'mobile',
    'mpda_gang_member_mobile': 'mobile',
    'mpda_accused_aadhaar': 'aadhaar',
    'mpda_gang_member_aadhaar': 'aadhaar',
}
CASTE_KEYS = ('mpda_accused_cast', 'mpda_gang_member_cast')


def forwards(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    fields = FieldTemplateField.objects.filter(template__template_name=TEMPLATE_NAME)
    for key, ftype in FIELD_TYPES.items():
        fields.filter(field_key=key, field_type='text').update(field_type=ftype)
    fields.filter(field_key__in=CASTE_KEYS, field_label='Cast').update(field_label='Caste')


def backwards(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    fields = FieldTemplateField.objects.filter(template__template_name=TEMPLATE_NAME)
    for key, ftype in FIELD_TYPES.items():
        fields.filter(field_key=key, field_type=ftype).update(field_type='text')
    fields.filter(field_key__in=CASTE_KEYS, field_label='Caste').update(field_label='Cast')


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0103_relink_common_form_to_road_accident'),
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
                ],
                default='text',
                max_length=20,
            ),
        ),
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
