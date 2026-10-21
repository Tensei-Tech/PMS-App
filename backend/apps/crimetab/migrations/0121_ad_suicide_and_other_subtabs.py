from django.db import migrations

"""
Migration 0121: A.D. gets two sub-tabs, "Suicide" and "Other" (data only)

Two child categories (parent_category = the A.D. tab, code 'STAND_AD'), like
Accident's Normal / Road Accident sub-tabs:
    Suicide   STAND_AD_SUICIDE   display_order 1
    Other     STAND_AD_OTHER     display_order 2
Opening A.D. then shows these two tiles (the app opens sub-tiles for any
category with children); each has its own case list and form. Both use the
Common Form Baseline Template until A.D.-specific fields are added. No A.D.
case existed, so nothing moves. Idempotent.
"""

PARENT_CODE = 'STAND_AD'
COMMON = 'Common Form Baseline Template'
CHILDREN = [
    ('Suicide', 'STAND_AD_SUICIDE', 1),
    ('Other', 'STAND_AD_OTHER', 2),
]


def forwards(apps, schema_editor):
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
    parent = CaseCategory.objects.filter(category_code=PARENT_CODE).first()
    if parent is None:
        return
    common = FieldTemplate.objects.filter(template_name=COMMON).first()
    for name, code, order in CHILDREN:
        child, _ = CaseCategory.objects.get_or_create(
            category_code=code,
            defaults={'category_name': name, 'parent_category': parent, 'group': parent.group,
                      'display_order': order, 'is_active': True},
        )
        if common is not None:
            CategoryFieldTemplate.objects.get_or_create(category=child, template=common)


def backwards(apps, schema_editor):
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
    codes = [code for _, code, _ in CHILDREN]
    CategoryFieldTemplate.objects.filter(category__category_code__in=codes).delete()
    CaseCategory.objects.filter(category_code__in=codes).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0120_absconding_check_caw_and_pocso_only'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
