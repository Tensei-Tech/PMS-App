from django.db import migrations, models

"""
Migration 0075: MPDA gang / group members get the same details as an accused

1. Nine child fields under "mpda_gang_members" in the MPDA Proposal Template
   (labels and types copied from the accused fields): Age, Gender, Mobile,
   Aadhaar, Address, Occupation, PAN card, Cast, Religion. All optional.
2. mpda_gang_members gets the matching columns in every schema that has the
   table (age and mobile with the same checks as mpda_accused_persons).

Idempotent. Existing gang members keep their names; new columns start empty.
"""

TEMPLATE_NAME = 'MPDA Proposal Template'
PARENT = 'mpda_gang_members'

# (label, key, type, order, options_source)
FIELDS = [
    ('Age', 'mpda_gang_member_age', 'number', 152, None),
    ('Gender', 'mpda_gang_member_gender', 'dropdown', 153, '/api/options/gender/'),
    ('Mobile', 'mpda_gang_member_mobile', 'text', 154, None),
    ('Aadhaar', 'mpda_gang_member_aadhaar', 'text', 155, None),
    ('Address', 'mpda_gang_member_address', 'textarea', 156, None),
    ('Occupation', 'mpda_gang_member_occupation', 'text', 157, None),
    ('PAN card', 'mpda_gang_member_pan', 'text', 158, None),
    ('Cast', 'mpda_gang_member_cast', 'text', 159, None),
    ('Religion', 'mpda_gang_member_religion', 'text', 160, None),
]

COLUMNS_SQL = [
    "ADD COLUMN IF NOT EXISTS age INT CHECK (age IS NULL OR (age >= 1 AND age <= 120))",
    "ADD COLUMN IF NOT EXISTS gender VARCHAR(50)",
    "ADD COLUMN IF NOT EXISTS occupation VARCHAR(255)",
    "ADD COLUMN IF NOT EXISTS mobile VARCHAR(10) CHECK (mobile IS NULL OR mobile = '' OR mobile ~ '^[0-9]{10}$')",
    "ADD COLUMN IF NOT EXISTS aadhaar VARCHAR(50)",
    "ADD COLUMN IF NOT EXISTS pan VARCHAR(50)",
    'ADD COLUMN IF NOT EXISTS "cast" VARCHAR(100)',
    "ADD COLUMN IF NOT EXISTS religion VARCHAR(100)",
    "ADD COLUMN IF NOT EXISTS address TEXT",
]


def add_fields(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is None:
        return
    parent = FieldTemplateField.objects.filter(template=tmpl, field_key=PARENT).first()
    section = parent.section if parent else None
    for label, key, ftype, order, opts in FIELDS:
        FieldTemplateField.objects.get_or_create(
            template=tmpl,
            field_key=key,
            defaults={
                'field_label': label,
                'field_source': 'custom',
                'field_type': ftype,
                'is_required': False,
                'section': section,
                'display_order': order,
                'options_source': opts,
                'parent_field_key': PARENT,
            },
        )


def remove_fields(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME, field_key__in=[k for _, k, _, _, _ in FIELDS]
    ).delete()


def add_columns(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return  # SQLite tests build the columns from the model
    with schema_editor.connection.cursor() as cursor:
        cursor.execute(
            "SELECT table_schema FROM information_schema.tables WHERE table_name = 'mpda_gang_members'"
        )
        for (schema,) in cursor.fetchall():
            cursor.execute(f'ALTER TABLE "{schema}".mpda_gang_members ' + ', '.join(COLUMNS_SQL))


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0074_mpda_summary_settings'),
    ]

    operations = [
        migrations.RunPython(add_fields, reverse_code=remove_fields),
        migrations.SeparateDatabaseAndState(
            database_operations=[
                migrations.RunPython(add_columns, reverse_code=migrations.RunPython.noop),
            ],
            state_operations=[
                migrations.AddField(model_name='mpdagangmember', name='age',
                                    field=models.IntegerField(blank=True, null=True)),
                migrations.AddField(model_name='mpdagangmember', name='gender',
                                    field=models.CharField(blank=True, max_length=50, null=True)),
                migrations.AddField(model_name='mpdagangmember', name='occupation',
                                    field=models.CharField(blank=True, max_length=255, null=True)),
                migrations.AddField(model_name='mpdagangmember', name='mobile',
                                    field=models.CharField(blank=True, max_length=10, null=True)),
                migrations.AddField(model_name='mpdagangmember', name='aadhaar',
                                    field=models.CharField(blank=True, max_length=50, null=True)),
                migrations.AddField(model_name='mpdagangmember', name='pan',
                                    field=models.CharField(blank=True, max_length=50, null=True)),
                migrations.AddField(model_name='mpdagangmember', name='cast',
                                    field=models.CharField(blank=True, max_length=100, null=True)),
                migrations.AddField(model_name='mpdagangmember', name='religion',
                                    field=models.CharField(blank=True, max_length=100, null=True)),
                migrations.AddField(model_name='mpdagangmember', name='address',
                                    field=models.TextField(blank=True, null=True)),
            ],
        ),
    ]
