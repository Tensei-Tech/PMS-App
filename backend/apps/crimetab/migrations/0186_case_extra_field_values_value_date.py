from django.db import migrations, models

"""
Migration 0186: case_extra_field_values.value_date (step B4)

A.D. answers move from the case JSON into case_extra_field_values, one row per
answer (a deceased person's answers at the person's position). A ticked
checkbox carries a date / time beside it (Inquest Panchanama 04/11/2026 11:37),
kept here as the form sends it. One nullable column; no data is changed here
(backfill_service_tab_tables copies the saved A.D. answers). Other states get
the column from the state sync that runs after migrate.
"""


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0185_tadipar_records'),
    ]

    operations = [
        migrations.AddField(model_name='caseextrafieldvalue', name='value_date',
                            field=models.TextField(blank=True, null=True)),
    ]
