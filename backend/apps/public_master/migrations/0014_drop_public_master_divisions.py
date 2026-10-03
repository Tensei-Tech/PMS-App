from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('public_master', '0013_ensure_maharashtra_master_divisions'),
    ]

    operations = [
        migrations.RunSQL(
            sql="""
            DROP TABLE IF EXISTS public.master_divisions CASCADE;
            """,
            reverse_sql=migrations.RunSQL.noop,
        ),
    ]
