from django.db import migrations, models

class Migration(migrations.Migration):

    dependencies = [
        ('cases', '0005_alter_caserecord_status'),
    ]

    operations = [
        migrations.AddField(
            model_name='caserecord',
            name='disposal_date',
            field=models.DateTimeField(blank=True, null=True),
        ),
    ]
