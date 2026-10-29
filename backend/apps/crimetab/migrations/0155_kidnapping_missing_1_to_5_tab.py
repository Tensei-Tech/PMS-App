from django.db import migrations

"""
Migration 0155: One combined "Kidnapping/Missing" sub-tab under "1 to 5" (data only)

0154 removed the separate Kidnapping and Missing sub-tabs of "1 to 5". This adds
a single sub-tab in their place:
  "Kidnapping/Missing" (code 120, group "1 to 5", display order 20)
with the "Common Form Baseline Template" and the "Kidnapping / Missing Extra Fields"
template (0144). The dashboard's Kidnapping/Missing tile opens this tab.

Idempotent.
"""

CATEGORY_NAME = 'Kidnapping/Missing'
CATEGORY_CODE = '120'
GROUP_ID = 1  # "1 to 5"
DISPLAY_ORDER = 20
BASELINE_TEMPLATE = 'Common Form Baseline Template'
EXTRA_TEMPLATE = 'Kidnapping / Missing Extra Fields'


def forwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CaseCategoryGroup = apps.get_model('crimetab', 'CaseCategoryGroup')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')

    group = CaseCategoryGroup.objects.filter(pk=GROUP_ID).first()
    if not group:
        return
    baseline = FieldTemplate.objects.filter(template_name=BASELINE_TEMPLATE).first()
    cat, _ = CaseCategory.objects.update_or_create(
        group=group, category_code=CATEGORY_CODE, parent_category=None,
        defaults={'category_name': CATEGORY_NAME, 'display_order': DISPLAY_ORDER,
                  'is_active': True, 'template': baseline},
    )
    for name in (BASELINE_TEMPLATE, EXTRA_TEMPLATE):
        tmpl = FieldTemplate.objects.filter(template_name=name).first()
        if tmpl:
            CategoryFieldTemplate.objects.get_or_create(category=cat, template=tmpl)


def backwards(apps, schema_editor):
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
    cats = CaseCategory.objects.filter(group_id=GROUP_ID, category_code=CATEGORY_CODE, category_name=CATEGORY_NAME)
    CategoryFieldTemplate.objects.filter(category__in=cats).delete()
    cats.delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0154_remove_1_to_5_kidnapping_missing'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
