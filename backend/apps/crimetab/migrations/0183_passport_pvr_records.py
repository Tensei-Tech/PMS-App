import django.db.models.deletion
import django.utils.timezone
from django.db import migrations, models

"""
Migration 0183: passport_pvr_records (step B6)

The Passport and PVR tabs kept every answer only in the case JSON. One row per
entry now, linked one-to-one to its case (deleting the case deletes the row):
kind (passport / pvr), file number, total / verified / pending counts, status,
verification date, and the applicant fields of older single-applicant entries.
Created empty; backfill_service_tab_tables copies saved entries in. Other states
get the table from the state sync that runs after migrate.
"""


class Migration(migrations.Migration):

    dependencies = [
        ('cases', '0006_caserecord_disposal_date'),
        ('crimetab', '0182_sam_warrant_records'),
    ]

    operations = [
        migrations.CreateModel(
            name='PassportPvrRecord',
            fields=[
                ('case', models.OneToOneField(db_column='case_id', on_delete=django.db.models.deletion.CASCADE,
                                              primary_key=True, related_name='passport_pvr', serialize=False,
                                              to='cases.caserecord')),
                ('kind', models.CharField(choices=[('passport', 'Passport'), ('pvr', 'PVR')], max_length=10)),
                ('file_number', models.CharField(blank=True, max_length=100, null=True)),
                ('total_count', models.IntegerField(blank=True, null=True)),
                ('verified_count', models.IntegerField(blank=True, null=True)),
                ('pending_count', models.IntegerField(blank=True, null=True)),
                ('verification_status', models.CharField(blank=True, max_length=50, null=True)),
                ('verification_date', models.DateField(blank=True, null=True)),
                ('applicant_name', models.CharField(blank=True, max_length=255, null=True)),
                ('applicant_phone', models.CharField(blank=True, max_length=20, null=True)),
                ('applicant_address', models.TextField(blank=True, null=True)),
                ('verification_outcome', models.CharField(blank=True, max_length=100, null=True)),
                ('remarks', models.TextField(blank=True, null=True)),
                ('created_at', models.DateTimeField(default=django.utils.timezone.now)),
                ('updated_at', models.DateTimeField(default=django.utils.timezone.now)),
            ],
            options={'db_table': 'passport_pvr_records', 'verbose_name': 'Passport / PVR Record'},
        ),
    ]
