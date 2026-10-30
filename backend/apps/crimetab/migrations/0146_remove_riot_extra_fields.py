from django.db import migrations
from django.db.models import Q

"""
Migration 0146: Riot no longer gets the extra fields 0145 linked to it (data only)

Unlinks "Hurt Extra Fields" and "Non-Applicant Details" from Riot (code 106).
Assault on Public Servant keeps both. Only the links are removed: the
templates, their fields and any saved values stay.

Idempotent.
"""

TEMPLATE_NAMES = ('Hurt Extra Fields', 'Non-Applicant Details')
CATEGORY_NAME = 'Riot'
CATEGORY_CODE = '106'


def _riot(CaseCategory):
    return CaseCategory.objects.filter(Q(category_code=CATEGORY_CODE) | Q(category_name__iexact=CATEGORY_NAME))


def forwards(apps, schema_editor):
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
    CategoryFieldTemplate.objects.filter(
        category__in=_riot(CaseCategory), template__template_name__in=TEMPLATE_NAMES
    ).delete()


def backwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
    for tmpl in FieldTemplate.objects.filter(template_name__in=TEMPLATE_NAMES):
        for cat in _riot(CaseCategory):
            CategoryFieldTemplate.objects.get_or_create(category=cat, template=tmpl)


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0145_assault_riot_extra_fields'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
