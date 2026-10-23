from django.db import migrations

"""
Migration 0066: standalone tab rows for dashboard tiles that had no DB category

Juvenile, Victim, Sam/Warrant, Muddemal, Passport/PVR/Lic and MCOCA get a
standalone row in public.case_categories (group NULL). They are NOT linked to
any form template, so they still open "No form configured" until a form is
linked. Names match the dashboard tile labels so the tile resolves its row.

public.case_categories.category_id has no default on the live database, so ids
are assigned as MAX(category_id) + 1 under a table lock. Idempotent (skips a code
that already exists).
"""

# (category_name, category_code, display_order) — after MPDA (119)
TABS = [
    ('Juvenile', 'STAND_JUVENILE', 120),
    ('Victim', 'STAND_VICTIM', 121),
    ('Sam/Warrant', 'STAND_SAM_WARRANT', 122),
    ('Muddemal', 'STAND_MUDDEMAL', 123),
    ('Passport/PVR/Lic', 'STAND_PASSPORT', 124),
    ('MCOCA', 'STAND_MCOCA', 125),
]


def add_tabs(apps, schema_editor):
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    if schema_editor.connection.vendor == 'postgresql':
        with schema_editor.connection.cursor() as cursor:
            cursor.execute('LOCK TABLE public.case_categories IN EXCLUSIVE MODE')
    for name, code, order in TABS:
        if CaseCategory.objects.filter(category_code=code).exists():
            continue
        next_id = (CaseCategory.objects.order_by('-category_id')
                   .values_list('category_id', flat=True).first() or 0) + 1
        CaseCategory.objects.create(
            category_id=next_id,
            category_name=name,
            category_code=code,
            group=None,
            parent_category=None,
            template=None,
            is_active=True,
            display_order=order,
        )


def remove_tabs(apps, schema_editor):
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    CaseCategory.objects.filter(category_code__in=[c for _, c, _ in TABS]).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0065_remove_standalone_st_drugs'),
    ]

    operations = [
        migrations.RunPython(add_tabs, reverse_code=remove_tabs),
    ]
