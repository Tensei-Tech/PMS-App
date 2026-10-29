from django.db import migrations
from django.db.models import Q

"""
Migration 0151: Crime Against Women extra fields for Rape, Molestation and 498 (A) IPC (data only)

Links the existing "Crime Against Women Extra Fields" template (victim details,
medical & statements, DNA / post-mortem / FSL, digital & documentary evidence,
cyber crime, acid attack, government vehicle use, absconding accused) as it is to:
  Rape (code 112), Molestation (code 113), 498 (A) IPC (code 116)

Idempotent.
"""

TEMPLATE_NAME = 'Crime Against Women Extra Fields'
CATEGORY_CODES = ('112', '113', '116')
CATEGORY_NAMES = ('Rape', 'Molestation', '498 (A) IPC')


def _categories(CaseCategory):
    name_q = Q()
    for name in CATEGORY_NAMES:
        name_q |= Q(category_name__iexact=name)
    return CaseCategory.objects.filter(Q(category_code__in=CATEGORY_CODES) | name_q)


def forwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')

    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if not tmpl:
        return
    for cat in _categories(CaseCategory):
        CategoryFieldTemplate.objects.get_or_create(category=cat, template=tmpl)


def backwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')

    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if tmpl:
        CategoryFieldTemplate.objects.filter(category__in=_categories(CaseCategory), template=tmpl).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0150_cbt_extra_fields'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
