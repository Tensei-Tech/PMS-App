from django.db import migrations, models

"""
Migration 0127: act_sections.ipc_section

Optional text column with the corresponding old IPC section of a section
(e.g. BNS 101 -> IPC 300), filled by `manage.py import_acts` from the files'
IPC column. Nullable, so existing rows are unaffected.
"""


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0126_ad_module_settings'),
    ]

    operations = [
        migrations.AddField(
            model_name='actsection',
            name='ipc_section',
            field=models.CharField(blank=True, max_length=20, null=True),
        ),
    ]
