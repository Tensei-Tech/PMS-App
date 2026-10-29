from django.db import migrations, models

"""
Migration 0124: N.C. Preventive - Outward Date after Outward Number

1. Tenant tables: <state schema>.nc_preventive_actions gets outward_date DATE
   in every active state schema that already exists (IF NOT EXISTS). New states
   get it from apps.crimetab.nc_schema (same DDL).
2. NC Form: new optional date field 'Outward Date' (nc_prev_outward_date) right
   after Outward Number; Bond Date and Bond Cancellation Date move one place on.
"""

TEMPLATE_NAME = 'NC Form'
GROUP_KEY = 'nc_preventive_actions'
FIELD_KEY = 'nc_prev_outward_date'
FIELD_ORDER = 106
# field_key: (new display_order, old display_order)
ORDER = {
    'nc_prev_bond_date': (107, 106),
    'nc_prev_bond_cancel_date': (108, 107),
}


def add_tenant_column(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return  # SQLite tests build tables from the models
    from apps.crimetab.nc_schema import quote_schema

    with schema_editor.connection.cursor() as cursor:
        cursor.execute("SELECT to_regclass('public.states')")
        if cursor.fetchone()[0] is None:
            return
        cursor.execute(
            """
            SELECT s.schema_name
            FROM public.states s
            JOIN information_schema.schemata sc ON sc.schema_name = s.schema_name
            WHERE s.is_active = TRUE
              AND s.schema_name NOT IN ('public', 'information_schema', 'pg_catalog')
            ORDER BY s.schema_name
            """
        )
        for (schema_name,) in cursor.fetchall():
            s = quote_schema(schema_name)
            cursor.execute(f"SELECT to_regclass('{s}.nc_preventive_actions')")
            if cursor.fetchone()[0] is None:
                continue
            cursor.execute(
                f'ALTER TABLE {s}.nc_preventive_actions '
                'ADD COLUMN IF NOT EXISTS outward_date DATE'
            )


def add_form_field(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl is None:
        return
    fields = FieldTemplateField.objects.filter(template=tmpl)
    for key, (new, old) in ORDER.items():
        fields.filter(field_key=key, display_order=old).update(display_order=new)
    FieldTemplateField.objects.get_or_create(
        template=tmpl,
        field_key=FIELD_KEY,
        defaults={
            'field_label': 'Outward Date',
            'field_source': 'custom',
            'field_type': 'date',
            'is_required': False,
            'section': 'Preventive',
            'display_order': FIELD_ORDER,
            'parent_field_key': GROUP_KEY,
        },
    )


def remove_form_field(apps, schema_editor):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    fields = FieldTemplateField.objects.filter(template__template_name=TEMPLATE_NAME)
    fields.filter(field_key=FIELD_KEY).delete()
    for key, (new, old) in ORDER.items():
        fields.filter(field_key=key, display_order=new).update(display_order=old)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0123_nc_caste_label'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[
                # Reverse is a no-op: the column (and its dates) is never dropped by a rollback
                migrations.RunPython(add_tenant_column, reverse_code=migrations.RunPython.noop),
            ],
            state_operations=[
                migrations.AddField(
                    model_name='ncpreventiveaction',
                    name='outward_date',
                    field=models.DateField(blank=True, null=True),
                ),
            ],
        ),
        migrations.RunPython(add_form_field, reverse_code=remove_form_field),
    ]
