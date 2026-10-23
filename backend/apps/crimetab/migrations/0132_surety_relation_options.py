from django.db import migrations

"""
Migration 0132: surety relations as option values (data only)

The Remand & Custody surety "Relation with Accused" dropdown had a fixed list in
the app; it now loads /api/options/surety_relations/. Same 16 values, same
order. Idempotent; existing values are kept.
"""

GROUP = 'surety_relations'
VALUES = ['Father', 'Mother', 'Brother', 'Sister', 'Spouse', 'Son', 'Daughter', 'Uncle',
          'Aunt', 'Friend', 'Relative', 'Neighbour', 'Employer', 'Colleague', 'Advocate', 'Other']


def forwards(apps, schema_editor):
    OptionValue = apps.get_model('crimetab', 'OptionValue')
    for i, value in enumerate(VALUES, 1):
        OptionValue.objects.get_or_create(
            option_group=GROUP, option_value=value,
            defaults={'display_order': i * 10, 'is_active': True},
        )


def backwards(apps, schema_editor):
    OptionValue = apps.get_model('crimetab', 'OptionValue')
    OptionValue.objects.filter(option_group=GROUP, option_value__in=VALUES).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0131_age_fields_max_digits'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
