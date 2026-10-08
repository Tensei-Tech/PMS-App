from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('public_master', '0010_drop_unused_public_tables'),
    ]

    operations = [
        migrations.RunSQL(
            sql="""
            DROP TABLE IF EXISTS public.stations_old_unused;
            """,
            reverse_sql=migrations.RunSQL.noop,
        ),
    ]
