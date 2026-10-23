from django.db import migrations, models

"""
Migration 0128: act tables for the full act / section import

- acts: act_name up to 255 characters (official act names are long).
- act_sections: section_title is text (some titles are over 1,000 characters);
  ipc_section up to 255 characters (some rows list several IPC sections).
- act_subsections: subsection_title (text) and ipc_section (an IPC section can
  differ per subsection, e.g. BNS 125(a) -> 337, 125(b) -> 338).
All new columns are nullable; the tables' existing rows are unaffected.
"""


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0127_actsection_ipc_section'),
    ]

    operations = [
        migrations.AlterField(
            model_name='act',
            name='act_name',
            field=models.CharField(default='', max_length=255),
        ),
        migrations.AlterField(
            model_name='actsection',
            name='section_title',
            field=models.TextField(default=''),
        ),
        migrations.AlterField(
            model_name='actsection',
            name='ipc_section',
            field=models.CharField(blank=True, max_length=255, null=True),
        ),
        migrations.AddField(
            model_name='actsubsection',
            name='subsection_title',
            field=models.TextField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='actsubsection',
            name='ipc_section',
            field=models.CharField(blank=True, max_length=255, null=True),
        ),
    ]
