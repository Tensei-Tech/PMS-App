from django.db import migrations

"""
Migration 0103: Road Accident tabs show the Common Form again

An earlier migration (0057, file since removed) unlinked the "Common Form
Baseline Template" from every tab using the "Road Accident Extra Template", so
those tabs showed only the accident questions. This links the baseline again
(public.category_field_templates), so they show the common form plus the
accident questions. Where both templates have the same field key (cr_number),
the form definition keeps the baseline's. Idempotent.
"""

BASELINE = 'Common Form Baseline Template'
ROAD_ACCIDENT = 'Road Accident Extra Template'


def link(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
    baseline = FieldTemplate.objects.filter(template_name=BASELINE).first()
    accident = FieldTemplate.objects.filter(template_name=ROAD_ACCIDENT).first()
    if not baseline or not accident:
        return
    for category_id in CategoryFieldTemplate.objects.filter(template=accident) \
            .values_list('category_id', flat=True):
        CategoryFieldTemplate.objects.get_or_create(category_id=category_id, template=baseline)


def unlink(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')
    baseline = FieldTemplate.objects.filter(template_name=BASELINE).first()
    accident = FieldTemplate.objects.filter(template_name=ROAD_ACCIDENT).first()
    if not baseline or not accident:
        return
    ids = CategoryFieldTemplate.objects.filter(template=accident).values_list('category_id', flat=True)
    CategoryFieldTemplate.objects.filter(template=baseline, category_id__in=list(ids)).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0102_road_accident_datetime_spot_columns'),
    ]

    operations = [
        migrations.RunPython(link, reverse_code=unlink),
    ]
