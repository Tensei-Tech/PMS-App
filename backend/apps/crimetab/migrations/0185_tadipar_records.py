import django.db.models.deletion
import django.utils.timezone
from django.db import migrations, models

"""
Migration 0185: tadipar_records (step B5)

The Tadipar tab kept every answer only in the case JSON (three copies: top
level, extra_field_values, dynamic_extra_fields). One row per externment order
now, linked one-to-one to its case (deleting the case deletes the row). Column
names follow the form keys. Act / Section / Subsection and the Crime Chart are
text: the app shows them as text boxes. Created empty;
backfill_service_tab_tables copies saved orders in. Other states get the table
from the state sync that runs after migrate.
"""


def text(size=None):
    if size:
        return models.CharField(blank=True, max_length=size, null=True)
    return models.TextField(blank=True, null=True)


class Migration(migrations.Migration):

    dependencies = [
        ('cases', '0006_caserecord_disposal_date'),
        ('crimetab', '0184_licence_records'),
    ]

    operations = [
        migrations.CreateModel(
            name='TadiparRecord',
            fields=[
                ('case', models.OneToOneField(db_column='case_id', on_delete=django.db.models.deletion.CASCADE,
                                              primary_key=True, related_name='tadipar', serialize=False,
                                              to='cases.caserecord')),
                ('sr_no', models.IntegerField(blank=True, null=True)),
                ('externed_name', text(255)),
                ('alias', text(255)),
                ('nickname', text(255)),
                ('age', models.IntegerField(blank=True, null=True)),
                ('gender', text(20)),
                ('mo_no', text(15)),
                ('address', text()),
                ('order_date', models.DateField(blank=True, null=True)),
                ('order_number', text(100)),
                ('act_id', text(255)),
                ('section_id', text(255)),
                ('subsection_id', text(255)),
                ('act_section', text()),
                ('period_from', models.DateField(blank=True, null=True)),
                ('period_to', models.DateField(blank=True, null=True)),
                ('revoked_date', models.DateField(blank=True, null=True)),
                ('current_address', text()),
                ('prohibited_areas', text(255)),
                ('crime_chart_entries', text()),
                ('created_at', models.DateTimeField(default=django.utils.timezone.now)),
                ('updated_at', models.DateTimeField(default=django.utils.timezone.now)),
            ],
            options={'db_table': 'tadipar_records', 'verbose_name': 'Tadipar Record'},
        ),
    ]
