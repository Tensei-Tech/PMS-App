from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('public_master', '0009_alter_stateregistry_super_admin_name_and_more'),
    ]

    operations = [
        migrations.RunSQL(
            sql="""
            DROP TABLE IF EXISTS public.stations_policestation_old_unused;
            DROP TABLE IF EXISTS public.districts_old_unused;
            DROP TABLE IF EXISTS public.cases_caserecord_old_unused;
            """,
            reverse_sql=migrations.RunSQL.noop,
        ),
    ]
