import django.db.models.deletion
import django.utils.timezone
from django.db import migrations, models

"""
Migration 0182: sam_warrant_records (step B8)

The Sam/Warrant tab kept every answer (type, number, accused, court, issue
date, execution status, notes) only in the case JSON. One row per record now,
linked one-to-one to its case (deleting the case deletes the row). Created
empty; the backfill_service_tab_tables command copies saved records in. Other
states get the table from the state sync that runs after migrate.
"""


class Migration(migrations.Migration):

    dependencies = [
        ('cases', '0006_caserecord_disposal_date'),
        ('crimetab', '0181_court_name_and_investigation_step_ticks'),
    ]

    operations = [
        migrations.CreateModel(
            name='SamWarrantRecord',
            fields=[
                ('case', models.OneToOneField(db_column='case_id', on_delete=django.db.models.deletion.CASCADE,
                                              primary_key=True, related_name='sam_warrant', serialize=False,
                                              to='cases.caserecord')),
                ('warrant_type', models.CharField(blank=True, choices=[
                    ('summons', 'Summons'), ('bw', 'Bailable Warrant'), ('nbw', 'Non-Bailable Warrant')],
                    max_length=10, null=True)),
                ('warrant_number', models.CharField(blank=True, max_length=100, null=True)),
                ('accused_name', models.CharField(blank=True, max_length=255, null=True)),
                ('court_name', models.CharField(blank=True, max_length=255, null=True)),
                ('issue_date', models.DateField(blank=True, null=True)),
                ('execution_status', models.CharField(blank=True, choices=[
                    ('pending', 'Pending'), ('executed', 'Executed'), ('unserved', 'Unserved')],
                    max_length=10, null=True)),
                ('notes', models.TextField(blank=True, null=True)),
                ('created_at', models.DateTimeField(default=django.utils.timezone.now)),
                ('updated_at', models.DateTimeField(default=django.utils.timezone.now)),
            ],
            options={'db_table': 'sam_warrant_records', 'verbose_name': 'Summons / Warrant Record'},
        ),
    ]
