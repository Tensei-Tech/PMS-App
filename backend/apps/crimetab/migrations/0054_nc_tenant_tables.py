import django.db.models.deletion
from django.db import migrations, models

"""
Migration 0054: N.C. tenant tables

Creates nc_records, nc_persons, nc_charges and nc_preventive_actions (with their
indexes) in every schema named in public.states with is_active = TRUE that
already exists. It never creates or drops a schema. Idempotent (IF NOT EXISTS).
New states get the same tables from apps.core.tenancy.provision_state_schema.
The DDL lives in apps.crimetab.nc_schema (single source for both paths).
"""


def create_nc_tenant_tables(apps, schema_editor):
    if schema_editor.connection.vendor != 'postgresql':
        return  # SQLite tests build tables from the models
    from apps.crimetab.nc_schema import create_nc_tables

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
            create_nc_tables(cursor, schema_name)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0053_nc_public_data'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[
                # Reverse is a no-op: N.C. records are never dropped by a rollback
                migrations.RunPython(create_nc_tenant_tables, reverse_code=migrations.RunPython.noop),
            ],
            state_operations=[
                migrations.CreateModel(
                    name='NcRecord',
                    fields=[
                        ('id', models.BigAutoField(primary_key=True, serialize=False)),
                        ('station_name', models.CharField(max_length=255)),
                        ('nc_no', models.CharField(blank=True, max_length=100, null=True)),
                        ('registered_date', models.DateField(blank=True, null=True)),
                        ('spot_village', models.CharField(blank=True, max_length=255, null=True)),
                        ('spot_area', models.CharField(blank=True, max_length=255, null=True)),
                        ('spot_address', models.TextField(blank=True, null=True)),
                        ('occurrence_at', models.DateTimeField(blank=True, null=True)),
                        ('io_name', models.CharField(blank=True, max_length=255, null=True)),
                        ('io_designation', models.CharField(blank=True, max_length=255, null=True)),
                        ('io_mobile', models.CharField(blank=True, max_length=10, null=True)),
                        ('reg_name', models.CharField(blank=True, max_length=255, null=True)),
                        ('reg_designation', models.CharField(blank=True, max_length=255, null=True)),
                        ('reg_mobile', models.CharField(blank=True, max_length=10, null=True)),
                        ('first_information', models.TextField(blank=True, null=True)),
                        ('post_crime_registered', models.CharField(blank=True, max_length=100, null=True)),
                        ('post_crime_no', models.CharField(blank=True, max_length=100, null=True)),
                        ('post_act', models.TextField(blank=True, null=True)),
                        ('post_section', models.TextField(blank=True, null=True)),
                        ('legacy_case_id', models.CharField(blank=True, max_length=128, null=True, unique=True)),
                        ('created_by', models.CharField(blank=True, max_length=128, null=True)),
                        ('created_at', models.DateTimeField(auto_now_add=True)),
                        ('updated_at', models.DateTimeField(auto_now=True)),
                    ],
                    options={
                        'verbose_name': 'N.C. Record',
                        'verbose_name_plural': 'N.C. Records',
                        'db_table': 'nc_records',
                    },
                ),
                migrations.CreateModel(
                    name='NcPerson',
                    fields=[
                        ('id', models.BigAutoField(primary_key=True, serialize=False)),
                        ('person_type', models.CharField(max_length=20)),
                        ('display_order', models.SmallIntegerField(default=0)),
                        ('name', models.CharField(blank=True, max_length=255, null=True)),
                        ('age', models.SmallIntegerField(blank=True, null=True)),
                        ('gender', models.CharField(blank=True, max_length=50, null=True)),
                        ('caste', models.CharField(blank=True, max_length=255, null=True)),
                        ('profession', models.CharField(blank=True, max_length=255, null=True)),
                        ('mobile', models.CharField(blank=True, max_length=10, null=True)),
                        ('address', models.TextField(blank=True, null=True)),
                        ('aadhaar', models.CharField(blank=True, max_length=20, null=True)),
                        ('nc', models.ForeignKey(db_column='nc_id', on_delete=django.db.models.deletion.CASCADE, related_name='persons', to='crimetab.ncrecord')),
                    ],
                    options={
                        'verbose_name': 'N.C. Person',
                        'verbose_name_plural': 'N.C. Persons',
                        'db_table': 'nc_persons',
                    },
                ),
                migrations.CreateModel(
                    name='NcCharge',
                    fields=[
                        ('id', models.BigAutoField(primary_key=True, serialize=False)),
                        ('display_order', models.SmallIntegerField(default=0)),
                        ('act_id', models.BigIntegerField(blank=True, null=True)),
                        ('section_id', models.BigIntegerField(blank=True, null=True)),
                        ('subsection_id', models.BigIntegerField(blank=True, null=True)),
                        ('act_name', models.TextField(blank=True, null=True)),
                        ('section_number', models.TextField(blank=True, null=True)),
                        ('section_title', models.TextField(blank=True, null=True)),
                        ('subsection_code', models.TextField(blank=True, null=True)),
                        ('nc', models.ForeignKey(db_column='nc_id', on_delete=django.db.models.deletion.CASCADE, related_name='charges', to='crimetab.ncrecord')),
                    ],
                    options={
                        'verbose_name': 'N.C. Charge',
                        'verbose_name_plural': 'N.C. Charges',
                        'db_table': 'nc_charges',
                    },
                ),
                migrations.CreateModel(
                    name='NcPreventiveAction',
                    fields=[
                        ('id', models.BigAutoField(primary_key=True, serialize=False)),
                        ('display_order', models.SmallIntegerField(default=0)),
                        ('provision', models.CharField(blank=True, max_length=100, null=True)),
                        ('action_date', models.DateField(blank=True, null=True)),
                        ('outward_number', models.CharField(blank=True, max_length=100, null=True)),
                        ('bond_date', models.DateField(blank=True, null=True)),
                        ('bond_cancellation_date', models.DateField(blank=True, null=True)),
                        ('preventive_number', models.CharField(blank=True, max_length=100, null=True)),
                        ('nc', models.ForeignKey(db_column='nc_id', on_delete=django.db.models.deletion.CASCADE, related_name='preventive_actions', to='crimetab.ncrecord')),
                        ('person', models.ForeignKey(blank=True, db_column='person_id', null=True, on_delete=django.db.models.deletion.CASCADE, related_name='preventive_actions', to='crimetab.ncperson')),
                    ],
                    options={
                        'verbose_name': 'N.C. Preventive Action',
                        'verbose_name_plural': 'N.C. Preventive Actions',
                        'db_table': 'nc_preventive_actions',
                    },
                ),
            ],
        ),
    ]
