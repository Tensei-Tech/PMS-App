import re

import django.db.models.deletion
from django.db import migrations, models

"""
Migration 0195: tabs linked to their case category, and their own Marathi /
Hindi labels.

- category (category_id -> case_categories) on dashboard_tiles,
  dashboard_subtabs, form_1_5_tabs and form_6_tabs. The app used to find a
  tab's category by its spelled name, so a typo or a renamed label silently
  showed 0 cases; now the row points at the category itself.
- label_mr / label_hi: the tab's label in Marathi / Hindi. Empty means the
  app's own translation of the English label, as before; fill them when a
  label is renamed.

The links are filled in the way the app picked a category until now, so every
tab keeps opening the same category:
  dashboard tile  its category_code, else a category whose code is the tile's
                  module_key, else the same name, else the same name ignoring
                  case and punctuation (active categories in display order)
  sub-tab         the "1 to 5" (group 1) category of the same name
  1 to 5 tab      the group 1 category with its category_code, else its name
  Part 6 tab      the same in group 2
Only adds columns and fills links; going backwards changes nothing.
"""


def norm(text):
    return re.sub(r'[^a-z0-9]', '', (text or '').lower())


def _first(rows, test):
    return next((r for r in rows if test(r)), None)


def _by_code_or_name(rows, code, name):
    if code:
        row = _first(rows, lambda c: (c.category_code or '').upper() == code.upper())
        if row:
            return row
    row = _first(rows, lambda c: (c.category_name or '').strip().lower() == name.strip().lower())
    return row or _first(rows, lambda c: norm(c.category_name) == norm(name))


def link_categories(apps, schema_editor):
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    active = list(CaseCategory.objects.filter(is_active=True).order_by('display_order', 'category_id'))
    top = [c for c in active if c.parent_category_id is None]
    group1 = [c for c in top if c.group_id == 1]
    group2 = [c for c in top if c.group_id == 2]

    DashboardTile = apps.get_model('crimetab', 'DashboardTile')
    for tile in DashboardTile.objects.filter(category__isnull=True, section__in=['cases', 'special', 'tools']):
        name = tile.label.replace('\n', ' ')
        row = None
        if tile.category_code:
            row = _first(active, lambda c: (c.category_code or '').upper() == tile.category_code.upper())
        if row is None:
            row = _first(active, lambda c: (c.category_code or '').lower() == tile.module_key.lower())
        if row is None:
            row = _by_code_or_name(active, None, name)
        if row is not None:
            tile.category_id = row.category_id
            tile.save(update_fields=['category'])

    DashboardSubtab = apps.get_model('crimetab', 'DashboardSubtab')
    for tab in DashboardSubtab.objects.filter(category__isnull=True, screen_key='category'):
        row = _by_code_or_name(group1, None, tab.label)
        if row is not None:
            tab.category_id = row.category_id
            tab.save(update_fields=['category'])

    for model_name, rows in (('Form15Tab', group1), ('Form6Tab', group2)):
        model = apps.get_model('crimetab', model_name)
        for tab in model.objects.filter(category__isnull=True):
            row = _by_code_or_name(rows, tab.category_code, tab.tab_name)
            if row is not None:
                tab.category_id = row.category_id
                tab.save(update_fields=['category'])


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0194_merge_dashboard_tabs_and_service_tab_dates'),
    ]

    operations = [
        migrations.AddField(
            model_name='dashboardsubtab',
            name='category',
            field=models.ForeignKey(blank=True, db_column='category_id', null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='+', to='crimetab.casecategory'),
        ),
        migrations.AddField(
            model_name='dashboardsubtab',
            name='label_hi',
            field=models.CharField(blank=True, default='', max_length=150),
        ),
        migrations.AddField(
            model_name='dashboardsubtab',
            name='label_mr',
            field=models.CharField(blank=True, default='', max_length=150),
        ),
        migrations.AddField(
            model_name='dashboardtile',
            name='category',
            field=models.ForeignKey(blank=True, db_column='category_id', null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='+', to='crimetab.casecategory'),
        ),
        migrations.AddField(
            model_name='dashboardtile',
            name='label_hi',
            field=models.CharField(blank=True, default='', max_length=150),
        ),
        migrations.AddField(
            model_name='dashboardtile',
            name='label_mr',
            field=models.CharField(blank=True, default='', max_length=150),
        ),
        migrations.AddField(
            model_name='form15tab',
            name='category',
            field=models.ForeignKey(blank=True, db_column='category_id', null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='+', to='crimetab.casecategory'),
        ),
        migrations.AddField(
            model_name='form15tab',
            name='label_hi',
            field=models.CharField(blank=True, default='', max_length=150),
        ),
        migrations.AddField(
            model_name='form15tab',
            name='label_mr',
            field=models.CharField(blank=True, default='', max_length=150),
        ),
        migrations.AddField(
            model_name='form6tab',
            name='category',
            field=models.ForeignKey(blank=True, db_column='category_id', null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='+', to='crimetab.casecategory'),
        ),
        migrations.AddField(
            model_name='form6tab',
            name='label_hi',
            field=models.CharField(blank=True, default='', max_length=150),
        ),
        migrations.AddField(
            model_name='form6tab',
            name='label_mr',
            field=models.CharField(blank=True, default='', max_length=150),
        ),
        migrations.RunPython(link_categories, reverse_code=migrations.RunPython.noop),
    ]
