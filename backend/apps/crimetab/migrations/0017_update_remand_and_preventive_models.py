from django.db import migrations, models
import django.db.models.deletion


def update_db_schemas_and_templates(apps, schema_editor):
    with schema_editor.connection.cursor() as cursor:
        # 1. Update public.field_template_fields for Remand & Custody dates
        cursor.execute("SELECT 1 FROM public.field_templates WHERE template_id = 1;")
        if cursor.fetchone():
            # Check if pr_bond_date exists
            cursor.execute(
                "SELECT field_def_id FROM public.field_template_fields WHERE template_id = 1 AND field_key = 'pr_bond_date';"
            )
            if not cursor.fetchone():
                cursor.execute(
                    """
                    INSERT INTO public.field_template_fields 
                    (template_id, field_label, field_key, field_source, field_type, is_required, display_order, section)
                    VALUES (1, 'PR Bond Date', 'pr_bond_date', 'common', 'date', false, 615, 'Remand & Custody');
                    """
                )

            # Check if jail_date exists
            cursor.execute(
                "SELECT field_def_id FROM public.field_template_fields WHERE template_id = 1 AND field_key = 'jail_date';"
            )
            if not cursor.fetchone():
                cursor.execute(
                    """
                    INSERT INTO public.field_template_fields 
                    (template_id, field_label, field_key, field_source, field_type, is_required, display_order, section)
                    VALUES (1, 'Jail Date', 'jail_date', 'common', 'date', false, 645, 'Remand & Custody');
                    """
                )

        # 2. Multi-schema column and constraint sync
        for schema in ['public', 'maharashtra', 'manipur', 'bihar']:
            cursor.execute("SELECT 1 FROM information_schema.schemata WHERE schema_name = %s;", [schema])
            if not cursor.fetchone():
                continue
            # remand_custody columns
            cursor.execute(f"ALTER TABLE IF EXISTS {schema}.remand_custody ADD COLUMN IF NOT EXISTS pr_bond_date date;")
            cursor.execute(f"ALTER TABLE IF EXISTS {schema}.remand_custody ADD COLUMN IF NOT EXISTS jail_date date;")

            # preventive_action_items columns
            cursor.execute(f"ALTER TABLE IF EXISTS {schema}.preventive_action_items ADD COLUMN IF NOT EXISTS person_id bigint;")
            cursor.execute(f"ALTER TABLE IF EXISTS {schema}.preventive_action_items ADD COLUMN IF NOT EXISTS name character varying(150);")

            # final_verdict column
            cursor.execute(f"ALTER TABLE IF EXISTS {schema}.final_verdict ADD COLUMN IF NOT EXISTS cc_st_number character varying(50);")

            # Update constraints on remand_custody
            cursor.execute(f"ALTER TABLE IF EXISTS {schema}.remand_custody DROP CONSTRAINT IF EXISTS chk_pr_bond_requires_mcr;")
            cursor.execute(
                f"""
                ALTER TABLE IF EXISTS {schema}.remand_custody 
                ADD CONSTRAINT chk_pr_bond_requires_mcr 
                CHECK (((pr_bond IS NULL OR pr_bond = false OR mcr = true) AND (pr_bond_date IS NULL OR pr_bond = true)));
                """
            )

            cursor.execute(f"ALTER TABLE IF EXISTS {schema}.remand_custody DROP CONSTRAINT IF EXISTS chk_surety_jail_requires_bail;")
            cursor.execute(
                f"""
                ALTER TABLE IF EXISTS {schema}.remand_custody 
                ADD CONSTRAINT chk_surety_jail_requires_bail 
                CHECK ((((surety_name IS NULL OR surety_name = '') OR bail = true) AND (jail IS NULL OR jail = false OR mcr = true) AND (jail_date IS NULL OR jail = true)));
                """
            )


def revert_db_schemas_and_templates(apps, schema_editor):
    with schema_editor.connection.cursor() as cursor:
        cursor.execute("DELETE FROM public.field_template_fields WHERE template_id = 1 AND field_key IN ('pr_bond_date', 'jail_date');")


class Migration(migrations.Migration):
    dependencies = [
        ('crimetab', '0016_separate_unknown_accused_section'),
    ]

    operations = [
        # RemandCustody field additions
        migrations.AddField(
            model_name='remandcustody',
            name='pr_bond_date',
            field=models.DateField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='remandcustody',
            name='jail_date',
            field=models.DateField(blank=True, null=True),
        ),
        # PreventiveActionItems field additions
        migrations.AddField(
            model_name='preventiveactionitems',
            name='person',
            field=models.ForeignKey(
                blank=True,
                db_column='person_id',
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='preventive_actions',
                to='crimetab.casesperson'
            ),
        ),
        migrations.AddField(
            model_name='preventiveactionitems',
            name='name',
            field=models.CharField(blank=True, max_length=150, null=True),
        ),
        # FinalVerdict field addition
        migrations.SeparateDatabaseAndState(
            database_operations=[],
            state_operations=[
                migrations.AddField(
                    model_name='finalverdict',
                    name='cc_st_number',
                    field=models.CharField(blank=True, max_length=50, null=True),
                ),
            ],
        ),
        # Constraint updates
        migrations.RemoveConstraint(
            model_name='remandcustody',
            name='chk_pr_bond_requires_mcr',
        ),
        migrations.RemoveConstraint(
            model_name='remandcustody',
            name='chk_surety_jail_requires_bail',
        ),
        migrations.AddConstraint(
            model_name='remandcustody',
            constraint=models.CheckConstraint(
                condition=(
                    (models.Q(pr_bond__isnull=True) | models.Q(pr_bond=False) | models.Q(mcr=True)) &
                    (models.Q(pr_bond_date__isnull=True) | models.Q(pr_bond=True))
                ),
                name='chk_pr_bond_requires_mcr'
            ),
        ),
        migrations.AddConstraint(
            model_name='remandcustody',
            constraint=models.CheckConstraint(
                condition=(
                    (models.Q(surety_name__isnull=True) | models.Q(surety_name='') | models.Q(bail=True)) &
                    (models.Q(jail__isnull=True) | models.Q(jail=False) | models.Q(mcr=True)) &
                    (models.Q(jail_date__isnull=True) | models.Q(jail=True))
                ),
                name='chk_surety_jail_requires_bail'
            ),
        ),
        # Run custom python for database schemas and field_template_fields
        migrations.RunPython(update_db_schemas_and_templates, revert_db_schemas_and_templates),
    ]
