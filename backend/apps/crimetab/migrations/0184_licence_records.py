import django.db.models.deletion
import django.utils.timezone
from django.db import migrations, models

"""
Migration 0184: licence_records (step B7)

The Licence tab kept every answer only in the case JSON. One row per
application now, linked one-to-one to its case (deleting the case deletes the
row): licence number, type (and its base type / other NOC details), applicant
and business name, received date, status and when it last changed, remarks.
Created empty; backfill_service_tab_tables copies saved applications in. Other
states get the table from the state sync that runs after migrate.
"""


class Migration(migrations.Migration):

    dependencies = [
        ('cases', '0006_caserecord_disposal_date'),
        ('crimetab', '0183_passport_pvr_records'),
    ]

    operations = [
        migrations.CreateModel(
            name='LicenceRecord',
            fields=[
                ('case', models.OneToOneField(db_column='case_id', on_delete=django.db.models.deletion.CASCADE,
                                              primary_key=True, related_name='licence', serialize=False,
                                              to='cases.caserecord')),
                ('licence_number', models.CharField(blank=True, max_length=100, null=True)),
                ('licence_type', models.CharField(blank=True, max_length=255, null=True)),
                ('base_licence_type', models.CharField(blank=True, max_length=255, null=True)),
                ('other_noc_type', models.CharField(blank=True, max_length=255, null=True)),
                ('applicant_name', models.CharField(blank=True, max_length=255, null=True)),
                ('business_name', models.CharField(blank=True, max_length=255, null=True)),
                ('received_date', models.DateField(blank=True, null=True)),
                ('licence_status', models.CharField(blank=True, max_length=20, null=True)),
                ('status_updated_at', models.DateTimeField(blank=True, null=True)),
                ('remarks', models.TextField(blank=True, null=True)),
                ('created_at', models.DateTimeField(default=django.utils.timezone.now)),
                ('updated_at', models.DateTimeField(default=django.utils.timezone.now)),
            ],
            options={'db_table': 'licence_records', 'verbose_name': 'Licence Record'},
        ),
    ]
