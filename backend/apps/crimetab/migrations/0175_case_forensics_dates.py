from django.db import migrations, models

"""
Migration 0175: dates for the Common Form's evidence ticks

The Common Form asks for a date beside e-Sakshya, Fingerprint Taken and NAFIS
(e_shakshya_date, fingerprint_taken_date, nafis_fingerprint_date), but
case_forensics had no column for them, so they lived only in the case JSON.
Three nullable date columns; no data is changed. Other states get them from the
state sync that runs after migrate.
"""


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0174_road_accident_case_foreign_keys'),
    ]

    operations = [
        migrations.AddField(model_name='caseforensics', name='e_shakshya_date',
                            field=models.DateField(blank=True, null=True)),
        migrations.AddField(model_name='caseforensics', name='fingerprint_taken_date',
                            field=models.DateField(blank=True, null=True)),
        migrations.AddField(model_name='caseforensics', name='nafis_fingerprint_date',
                            field=models.DateField(blank=True, null=True)),
    ]
