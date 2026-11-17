import django.db.models.deletion
import django.utils.timezone
from django.db import migrations, models

"""
Migration 0188: Preventive tab answers in tables (step B9)

The Preventive tab kept every answer only in the case JSON
(extra_fields['preventiveForm']), so preventive_action_items stayed empty for it.
- preventive_records: the case-level answers (crime reference, sections,
  preventive provision / number / date / outward no., IO, risk, status, remarks),
  one row per entry, linked one-to-one to its case.
- preventive_action_items gets accused_action, bond_taken and bond_details:
  each named accused of the entry is one row there.
No data is changed here; backfill_service_tab_tables copies saved entries.
Other states get the table and columns from the state sync.
"""


def text(size=None):
    if size:
        return models.CharField(blank=True, max_length=size, null=True)
    return models.TextField(blank=True, null=True)


class Migration(migrations.Migration):

    dependencies = [
        ('cases', '0006_caserecord_disposal_date'),
        ('crimetab', '0187_tadipar_crime_chart_entries'),
    ]

    operations = [
        migrations.AddField(model_name='preventiveactionitems', name='accused_action', field=text(100)),
        migrations.AddField(model_name='preventiveactionitems', name='bond_taken',
                            field=models.BooleanField(blank=True, null=True)),
        migrations.AddField(model_name='preventiveactionitems', name='bond_details', field=text()),
        migrations.CreateModel(
            name='PreventiveRecord',
            fields=[
                ('case', models.OneToOneField(db_column='case_id', on_delete=django.db.models.deletion.CASCADE,
                                              primary_key=True, related_name='preventive_record', serialize=False,
                                              to='cases.caserecord')),
                ('crime_no', text(100)),
                ('reg_date', models.DateField(blank=True, null=True)),
                ('crime_category', text(255)),
                ('case_status', text(100)),
                ('act', text(255)),
                ('selected_sections', text()),
                ('other_sections', text()),
                ('has_preventive_no', models.BooleanField(blank=True, null=True)),
                ('preventive_section_act', text(255)),
                ('preventive_no', text(100)),
                ('preventive_date', models.DateField(blank=True, null=True)),
                ('outward_no', text(100)),
                ('io_name', text(255)),
                ('risk_flag', text(100)),
                ('action_status', text(100)),
                ('remarks', text()),
                ('created_at', models.DateTimeField(default=django.utils.timezone.now)),
                ('updated_at', models.DateTimeField(default=django.utils.timezone.now)),
            ],
            options={'db_table': 'preventive_records', 'verbose_name': 'Preventive Record'},
        ),
    ]
