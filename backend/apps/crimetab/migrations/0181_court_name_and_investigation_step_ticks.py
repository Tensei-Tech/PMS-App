from django.db import migrations, models

"""
Migration 0181: court name, and three more ticks in procedural_checklist

- final_verdict.court_name: the Common Form's court name lived only in the case
  JSON. One nullable column; no data is changed here (the
  backfill_common_form_tables command fills it for saved cases).
- procedural_checklist.item_name accepts Witness Summons, Mobile Spot Recording
  and Vehicle Log Book Entry, kept like the panchanama ticks (a row when
  ticked, its date in event_datetime). Only the choices change: no column.
Other states get the column from the state sync that runs after migrate.
"""


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0180_fold_old_commonform_copies'),
    ]

    operations = [
        migrations.AddField(model_name='finalverdict', name='court_name',
                            field=models.CharField(blank=True, max_length=255, null=True)),
        migrations.AlterField(
            model_name='proceduralchecklist', name='item_name',
            field=models.CharField(max_length=40, choices=[
                ('Spot Panchanama', 'Spot Panchanama'),
                ('Seizure Panchanama', 'Seizure Panchanama'),
                ('Search Panchanama', 'Search Panchanama'),
                ('Personal Search Panchanama', 'Personal Search Panchanama'),
                ('Memorandum Panchanama', 'Memorandum Panchanama'),
                ('Identification Panchanama', 'Identification Panchanama'),
                ('Identification Parade Panchanama', 'Identification Parade Panchanama'),
                ('Witness Summons', 'Witness Summons'),
                ('Mobile Spot Recording', 'Mobile Spot Recording'),
                ('Vehicle Log Book Entry', 'Vehicle Log Book Entry'),
            ]),
        ),
    ]
