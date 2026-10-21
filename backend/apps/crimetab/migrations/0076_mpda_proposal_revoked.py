from django.db import migrations, models

"""
Migration 0076: "Revoked" under the MPDA Proposal Outcome

1. Two fields in the MPDA Proposal Template, right after Rejected Date:
   - Revoked (Yes / No radio, options from the 'yes_no' group)
   - Revoked Date (shown only when Revoked = Yes)
2. mpda_proposals gets proposal_revoked / proposal_revoked_date in every
   schema that has the table.

Idempotent. Existing proposals start with both columns empty.
"""

TEMPLATE_NAME = 'MPDA Proposal Template'

# (label, key, type, order, options_source, depends_on_key, depends_on_value)
FIELDS = [
    ('Revoked', 'mpda_proposal_revoked', 'radio', 65, '/api/options/yes_no/', None, None),
    ('Revoked Date', 'mpda_proposal_revoked_date', 'date', 66, None, 'mpda_proposal_revoked', 'Yes'),
]


def add_fields(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    OptionValue = apps.get_model('crimetab', 'OptionValue')
    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is None:
        return
    outcome = FieldTemplateField.objects.filter(template=tmpl, field_key='mpda_proposal_outcome').first()
    section = outcome.section if outcome else None
    yes = OptionValue.objects.filter(option_group='yes_no', is_active=True).first()
    yes_value = yes.option_value if yes else 'Yes'
    for label, key, ftype, order, opts, dep_key, dep_val in FIELDS:
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
                'depends_on_field_key': dep_key,
                'depends_on_value': yes_value if dep_val else None,
            },
        )


def remove_fields(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    FieldTemplateField.objects.filter(
        template__template_name=TEMPLATE_NAME, field_key__in=[f[1] for f in FIELDS]
    ).delete()


def add_columns(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return  # SQLite tests build the columns from the model
    with schema_editor.connection.cursor() as cursor:
        cursor.execute(
            "SELECT table_schema FROM information_schema.tables WHERE table_name = 'mpda_proposals'"
        )
        for (schema,) in cursor.fetchall():
            cursor.execute(
                f'ALTER TABLE "{schema}".mpda_proposals '
                'ADD COLUMN IF NOT EXISTS proposal_revoked VARCHAR(10), '
                'ADD COLUMN IF NOT EXISTS proposal_revoked_date DATE'
            )


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0075_mpda_gang_member_details'),
    ]

    operations = [
        migrations.RunPython(add_fields, reverse_code=remove_fields),
        migrations.SeparateDatabaseAndState(
            database_operations=[
                migrations.RunPython(add_columns, reverse_code=migrations.RunPython.noop),
            ],
            state_operations=[
                migrations.AddField(model_name='mpdaproposal', name='proposal_revoked',
                                    field=models.CharField(blank=True, max_length=10, null=True)),
                migrations.AddField(model_name='mpdaproposal', name='proposal_revoked_date',
                                    field=models.DateField(blank=True, null=True)),
            ],
        ),
    ]
