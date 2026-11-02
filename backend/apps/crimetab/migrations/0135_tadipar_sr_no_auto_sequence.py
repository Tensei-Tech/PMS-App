from django.db import migrations, models

"""
Migration 0135: Tadipar Sr. No. auto-generation and sequence configuration.
1. Ensures 'field_config' JSONB column exists on field_template_fields table and model state.
2. Configures FieldTemplateField for 'sr_no' in Tadipar Base Template:
   - options_source = 'auto:sequence'
   - field_config = {'auto_generate': True, 'read_only': True, 'sequence_type': 'sr_no'}
3. Backfills existing Tadipar CaseRecords with sequential 'sr_no' values (1..N).
4. Sets the initial last sequence counter in ModuleSetting.
"""


def configure_tadipar_auto_sr_no(apps, schema_editor):
    CaseRecord = apps.get_model('cases', 'CaseRecord')
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')

    # 1. Update FieldTemplateField for sr_no in Tadipar directly via cursor to set jsonb field_config reliably
    with schema_editor.connection.cursor() as cur:
        cur.execute(
            """
            UPDATE field_template_fields
            SET options_source = 'auto:sequence',
                field_config = '{"auto_generate": true, "read_only": true, "sequence_type": "sr_no"}'::jsonb
            WHERE field_key = 'sr_no' OR field_def_id = 1493
            """
        )

    # 2. Backfill existing Tadipar records with clean sequential Sr. No.
    cases = list(
        CaseRecord.objects.filter(module_key='tadipar').order_by('id')
    )
    total_cases = len(cases)
    for idx, case in enumerate(cases, 1):
        extra = case.extra_fields if isinstance(case.extra_fields, dict) else {}
        extra['sr_no'] = str(idx)

        if 'commonForm' in extra and isinstance(extra['commonForm'], dict):
            extra['commonForm']['sr_no'] = str(idx)
        if 'extra_field_values' in extra and isinstance(extra['extra_field_values'], dict):
            extra['extra_field_values']['sr_no'] = str(idx)
        if 'dynamic_extra_fields' in extra and isinstance(extra['dynamic_extra_fields'], dict):
            extra['dynamic_extra_fields']['sr_no'] = str(idx)

        case.extra_fields = extra
        case.save(update_fields=['extra_fields'])

    # 3. Initialize sequence counter in ModuleSetting
    last_seq = str(total_cases) if total_cases > 0 else '0'
    ModuleSetting.objects.update_or_create(
        module_key='tadipar',
        setting_key='last_seq_sr_no',
        defaults={'setting_value': last_seq}
    )
    ModuleSetting.objects.update_or_create(
        module_key='tadipar',
        setting_key='last_seq_sr_no_maharashtra_police_hq',
        defaults={'setting_value': last_seq}
    )


def noop_reverse(apps, schema_editor):
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0134_remove_st_drugs_category_and_cases'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            state_operations=[
                migrations.AddField(
                    model_name='fieldtemplatefield',
                    name='field_config',
                    field=models.JSONField(blank=True, default=dict, null=True),
                ),
            ],
            database_operations=[
                migrations.RunSQL(
                    sql="ALTER TABLE field_template_fields ADD COLUMN IF NOT EXISTS field_config jsonb DEFAULT '{}'::jsonb;",
                    reverse_sql="ALTER TABLE field_template_fields DROP COLUMN IF EXISTS field_config;",
                ),
            ],
        ),
        migrations.RunPython(configure_tadipar_auto_sr_no, noop_reverse),
    ]
