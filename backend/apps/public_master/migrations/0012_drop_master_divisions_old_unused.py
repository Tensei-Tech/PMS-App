from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('public_master', '0011_drop_stations_old_unused'),
    ]

    operations = [
        migrations.RunSQL(
            sql="""
            DROP TABLE IF EXISTS public.master_divisions_old_unused;
            """,
            reverse_sql=migrations.RunSQL.noop,
        ),
    ]
