from django.db import migrations, models

"""
Migration 0181: court name, and three more ticks in procedural_checklist

- final_verdict.court_name: the Common Form's court name lived only in the case
  JSON. One nullable column; no data is changed here (the
  backfill_common_form_tables command fills it for saved cases).
- procedural_checklist.item_name accepts Witness Summons, Mobile Spot Recording
  and Vehicle Log Book Entry, kept like the panchanama ticks (a row when
  ticked, its date in event_datetime). No column; the database's own
  check rule procedural_checklist_item_name_check (from 0004, it allowed only
  the seven panchanama names) is replaced in every schema that has it.
Other states get the column from the state sync that runs after migrate.
"""

PANCHANAMA = ('Spot Panchanama', 'Seizure Panchanama', 'Search Panchanama', 'Personal Search Panchanama',
              'Memorandum Panchanama', 'Identification Panchanama', 'Identification Parade Panchanama')
STEPS = ('Witness Summons', 'Mobile Spot Recording', 'Vehicle Log Book Entry')
CHECK = 'procedural_checklist_item_name_check'


def _set_check(schema_editor, names, validate):
    if schema_editor.connection.vendor != 'postgresql':
        return
    allowed = ', '.join("'" + n.replace("'", "''") + "'" for n in names)
    with schema_editor.connection.cursor() as cursor:
        cursor.execute("""SELECT table_schema FROM information_schema.tables
                          WHERE table_name = 'procedural_checklist'""")
        for (schema,) in cursor.fetchall():
            cursor.execute(f'ALTER TABLE "{schema}".procedural_checklist DROP CONSTRAINT IF EXISTS {CHECK}')
            cursor.execute(f'ALTER TABLE "{schema}".procedural_checklist ADD CONSTRAINT {CHECK} '
                           f'CHECK (item_name IN ({allowed})){"" if validate else " NOT VALID"}')


def allow_steps(apps, schema_editor):
    _set_check(schema_editor, PANCHANAMA + STEPS, validate=True)


def panchanama_only(apps, schema_editor):
    # rows of the three steps may exist by then: kept, only new ones are refused
    _set_check(schema_editor, PANCHANAMA, validate=False)


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
        migrations.RunPython(allow_steps, panchanama_only),
    ]
