from django.db import migrations

"""
Migration 0164: shorter A.D. form labels (data only)

- "Deceased Identity" (ad_deceased_identity) reads "Identity"
- "PM (Post Mortem)" (ad_postmortem) reads "PM"

Field keys, answers and the "Post Mortem" section name stay the same.
Idempotent; backwards restores the old labels.
"""

TEMPLATE_NAME = 'AD Form Fields'

LABELS = {
    # field_key: (old label, new label)
    'ad_deceased_identity': ('Deceased Identity', 'Identity'),
    'ad_postmortem': ('PM (Post Mortem)', 'PM'),
}


def _relabel(apps, pick):
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')
    fields = FieldTemplateField.objects.filter(template__template_name=TEMPLATE_NAME)
    for key, labels in LABELS.items():
        fields.filter(field_key=key).update(field_label=pick(labels))


def forwards(apps, schema_editor):
    _relabel(apps, lambda labels: labels[1])


def backwards(apps, schema_editor):
    _relabel(apps, lambda labels: labels[0])


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0163_rename_normal_accident_to_other_accident'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
