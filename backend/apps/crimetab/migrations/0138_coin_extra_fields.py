from django.db import migrations
from django.db.models import Q

"""
Migration 0138: Link Coin category to Cheating Extra Fields (data only).

Links the "Cheating Extra Fields" template (store_values_in_table = True)
to Coin categories (code '128' under 1 to 5, and 'STAND_COIN' standalone).

Includes:
1. Type of Cheating:
   - Cash (radio Yes/No) -> Cash Amount (₹)
   - Online Send (radio Yes/No) -> Online Send Amount (₹)
   - Bank Withdraw (radio Yes/No) -> Bank Withdraw Amount (₹)
   - Total Value (₹) (sum of amounts)
2. Victim Details:
   - Victim count stepper: Victim (how many victims were there) (- 1 +)
   - Victims repeating group: Name, Age, Gender

Idempotent.
"""

TEMPLATE_NAME = 'Cheating Extra Fields'
CATEGORY_CODES = ('128', 'STAND_COIN')
CATEGORY_NAME = 'Coin'


def forwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')

    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if not tmpl:
        return

    for cat in CaseCategory.objects.filter(
        Q(category_code__in=CATEGORY_CODES) | Q(category_name__iexact=CATEGORY_NAME)
    ):
        CategoryFieldTemplate.objects.get_or_create(category=cat, template=tmpl)


def backwards(apps, schema_editor):
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CategoryFieldTemplate = apps.get_model('crimetab', 'CategoryFieldTemplate')

    tmpl = FieldTemplate.objects.filter(template_name=TEMPLATE_NAME).first()
    if not tmpl:
        return

    cats = CaseCategory.objects.filter(
        Q(category_code__in=CATEGORY_CODES) | Q(category_name__iexact=CATEGORY_NAME)
    )
    CategoryFieldTemplate.objects.filter(category__in=cats, template=tmpl).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0137_cheating_extra_fields'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
