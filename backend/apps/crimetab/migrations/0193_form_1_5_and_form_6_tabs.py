from django.db import migrations, models

"""
Migration 0193: the case-type tabs of "1 to 5" and Part 6 in their own tables.

  form_1_5_tabs  the tabs of Form I-V Cases ("1 to 5"): Murder, Attempt to
                 Murder, Dacoity ... Coin
  form_6_tabs    the tabs of Form VI Cases (Part 6): Prohibition, Gambling,
                 POCSO ... UAPA

The screens listed every active top-level category of group 1 / group 2 and
then hid some names written in the app. Now each tab is one row, and a screen
shows the active rows in display_order. tab_name is the case category the tab
lists, spelled as in case_categories.

Rows are copied from case_categories as they are today (group 1 without the
names the app hid). Shared by all states, so both tables are created in public
(like dashboard_tiles). Running it again adds nothing twice; going backwards
keeps the tables.
"""

TABLES = ('form_1_5_tabs', 'form_6_tabs')

CREATE_SQL = """
CREATE TABLE IF NOT EXISTS public.{table} (
    id BIGSERIAL PRIMARY KEY,
    tab_name VARCHAR(150) NOT NULL UNIQUE,
    category_code VARCHAR(100) NULL,
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE INDEX IF NOT EXISTS {table}_order_idx ON public.{table} (display_order);
"""

# Names the "1 to 5" screen used to hide even when they were in group 1
HIDDEN_FROM_FORM_1_5 = {
    'st drugs', 'st_drugs', 'stdrugs', 'prohibition', 'gambling', 'pocso', 'ndps',
    'gowansh', 'it act', 'm.v act', 'mv act', 'uapa', 'kidnapping', 'missing',
}

# Used only when case_categories has no rows for the group (e.g. a new database)
DEFAULT_FORM_1_5 = [
    'Murder', 'Attempt to Murder', 'Dacoity', 'Robbery', 'HBT', 'Theft', 'Riot',
    'Unlawful Assembly', 'Kidnapping/Missing', 'CBT', 'Cheating', 'Mischief', 'Hurt',
    'Assault on Public Servant', 'Rape', 'Molestation', 'Extortion', 'IPC (A) 304',
    '498 (A) IPC', 'Other IPC', 'Chain Snatching', 'Sand Theft', 'Two/Four Wheeler',
    'Crime Against Women', 'Accident', 'Sec 156(3)/175 (3)(BNSS)', 'COIN',
]
DEFAULT_FORM_6 = ['Prohibition', 'Gambling', 'POCSO', 'NDPS', 'Gowansh', 'IT Act', 'M.V Act', 'UAPA']


def create_tables(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        for table in TABLES:
            schema_editor.execute(CREATE_SQL.format(table=table))
    else:
        schema_editor.create_model(apps.get_model('crimetab', 'Form15Tab'))
        schema_editor.create_model(apps.get_model('crimetab', 'Form6Tab'))


def _group_tabs(apps, group_id):
    """(name, code) of the group's active top-level categories, in their order."""
    CaseCategory = apps.get_model('crimetab', 'CaseCategory')
    rows = (CaseCategory.objects
            .filter(group_id=group_id, parent_category__isnull=True, is_active=True)
            .order_by('display_order', 'category_id')
            .values_list('category_name', 'category_code'))
    seen, tabs = set(), []
    for name, code in rows:
        name = (name or '').strip()
        if name and name.lower() not in seen:
            seen.add(name.lower())
            tabs.append((name, code))
    return tabs


def _seed(model, tabs):
    for i, (name, code) in enumerate(tabs, start=1):
        model.objects.get_or_create(
            tab_name=name,
            defaults={'category_code': code, 'display_order': i * 10, 'is_active': True},
        )


def seed_tabs(apps, schema_editor):
    form_1_5 = [(n, c) for n, c in _group_tabs(apps, 1) if n.lower() not in HIDDEN_FROM_FORM_1_5]
    _seed(apps.get_model('crimetab', 'Form15Tab'),
          form_1_5 or [(n, None) for n in DEFAULT_FORM_1_5])
    form_6 = _group_tabs(apps, 2)
    _seed(apps.get_model('crimetab', 'Form6Tab'),
          form_6 or [(n, None) for n in DEFAULT_FORM_6])


def tab_fields():
    return [
        ('id', models.BigAutoField(primary_key=True, serialize=False)),
        ('tab_name', models.CharField(max_length=150, unique=True)),
        ('category_code', models.CharField(blank=True, max_length=100, null=True)),
        ('display_order', models.IntegerField(default=0)),
        ('is_active', models.BooleanField(default=True)),
    ]


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0192_dashboard_subtabs'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[
                # Going backwards keeps the tables and their rows (nothing is dropped)
                migrations.RunPython(create_tables, reverse_code=migrations.RunPython.noop),
            ],
            state_operations=[
                migrations.CreateModel(
                    name='Form15Tab',
                    fields=tab_fields(),
                    options={
                        'verbose_name': 'Form I-V Tab',
                        'verbose_name_plural': 'Form I-V Tabs',
                        'db_table': 'form_1_5_tabs',
                        'ordering': ['display_order', 'id'],
                        'abstract': False,
                    },
                ),
                migrations.CreateModel(
                    name='Form6Tab',
                    fields=tab_fields(),
                    options={
                        'verbose_name': 'Form VI Tab',
                        'verbose_name_plural': 'Form VI Tabs',
                        'db_table': 'form_6_tabs',
                        'ordering': ['display_order', 'id'],
                        'abstract': False,
                    },
                ),
            ],
        ),
        migrations.RunPython(seed_tabs, reverse_code=migrations.RunPython.noop),
    ]
