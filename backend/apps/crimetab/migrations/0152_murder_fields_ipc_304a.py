from django.db import migrations
from django.db.models import Q

"""
Migration 0152: Murder extra fields for IPC (A) 304 (data only)

Links the existing "Murder Section Extra Fields" template (Deceased Details,
Post-Mortem & FSL, Inquest & Exhumation Panchnama) as it is to:
  IPC (A) 304 (code 115)

Idempotent.
"""

TEMPLATE_NAME = 'Murder Section Extra Fields'
CATEGORY_CODES = ('115',)
CATEGORY_NAMES = ('IPC (A) 304',)


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
        ('crimetab', '0151_caw_fields_rape_molestation_498a'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
