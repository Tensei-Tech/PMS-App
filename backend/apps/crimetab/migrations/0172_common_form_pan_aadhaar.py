from django.db import migrations, models

"""
Migration 0172: Common Form Aadhaar and PAN numbers are checked

- New field type 'pan': PAN card number, typed in capitals and, when filled,
  5 letters + 4 digits + 1 letter (ABCDE1234F).
- Complainant / Accused / Suspected Accused Aadhaar become 'aadhaar' fields
  (exactly 12 digits when filled) and their PAN becomes 'pan'.
They stay optional (is_required is unchanged), so an empty number is fine.
(The app's Accused / Suspected Accused person cards check the same rules.)
Idempotent; backwards makes them text fields again.
"""

TEMPLATE_NAME = 'Common Form Baseline Template'
TYPES = {
    'complainant_aadhaar': 'aadhaar',
    'accused_aadhaar': 'aadhaar',
    'suspected_accused_aadhaar': 'aadhaar',
    'complainant_pan': 'pan',
    'accused_pan': 'pan',
    'suspected_accused_pan': 'pan',
}

FIELD_TYPE_CHOICES = [
    ('text', 'Text Field'), ('textarea', 'Multi-line Text Area'), ('number', 'Numeric Field'),
    ('date', 'Date Picker'), ('datetime', 'Date-Time Picker'), ('time', 'Time Picker'),
    ('dropdown', 'Dropdown Select'), ('checkbox', 'Checkbox Toggle'),
    ('radio', 'Radio Button Group'), ('chips', 'Chips Selector'), ('file', 'File Upload'),
    ('multi_select', 'Multi-Select Dropdown'), ('repeating_group', 'Repeating Group'),
    ('charges', 'Act & Section Picker'), ('mobile', 'Mobile Number (10 digits)'),
    ('email', 'E-mail Address'), ('aadhaar', 'Aadhaar Number (12 digits)'),
    ('pan', 'PAN Number (ABCDE1234F)'), ('year', 'Year (2001-2100)'),
]


def _fields(apps):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    return FieldTemplateField.objects.filter(template__template_name=TEMPLATE_NAME)


def forwards(apps, schema_editor):
    for key, field_type in TYPES.items():
        _fields(apps).filter(field_key=key).update(field_type=field_type)


def backwards(apps, schema_editor):
    _fields(apps).filter(field_key__in=list(TYPES)).update(field_type='text')


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0171_common_form_evidence_dates'),
    ]

    operations = [
        migrations.AlterField(
            model_name='fieldtemplatefield',
            name='field_type',
            field=models.CharField(choices=FIELD_TYPE_CHOICES, default='text', max_length=20),
        ),
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
