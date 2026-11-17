import django.db.models.deletion
import django.utils.timezone
from django.db import migrations, models

"""
Migration 0187: tadipar_crime_chart_entries (step B10)

Since the app draws the Tadipar Crime Chart as rows (PR #172), it sends a list
of rows: CR No., Crime Head, Act, Section, Register Date, Police Station. One
row each here, linked to the order (deleting the case deletes them), with the
Act / Section / station names copied beside their ids. Text typed before the
rows existed stays in tadipar_records.crime_chart_entries. Created empty; no
saved order has rows yet. Other states get the table from the state sync.
"""


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0186_case_extra_field_values_value_date'),
    ]

    operations = [
        migrations.CreateModel(
            name='TadiparCrimeChartEntry',
            fields=[
                ('id', models.BigAutoField(primary_key=True, serialize=False)),
                ('record', models.ForeignKey(db_column='case_id', on_delete=django.db.models.deletion.CASCADE,
                                             related_name='crime_chart', to='crimetab.tadiparrecord')),
                ('row_no', models.IntegerField(default=0)),
                ('cr_number', models.CharField(blank=True, max_length=100, null=True)),
                ('crime_head', models.TextField(blank=True, null=True)),
                ('act_id', models.BigIntegerField(blank=True, null=True)),
                ('act_name', models.TextField(blank=True, null=True)),
                ('section_id', models.BigIntegerField(blank=True, null=True)),
                ('section_number', models.CharField(blank=True, max_length=50, null=True)),
                ('register_date', models.DateField(blank=True, null=True)),
                ('police_station_id', models.BigIntegerField(blank=True, null=True)),
                ('police_station_name', models.CharField(blank=True, max_length=255, null=True)),
                ('created_at', models.DateTimeField(default=django.utils.timezone.now)),
            ],
            options={'db_table': 'tadipar_crime_chart_entries', 'verbose_name': 'Tadipar Crime Chart Entry',
                     'unique_together': {('record', 'row_no')}},
        ),
    ]
