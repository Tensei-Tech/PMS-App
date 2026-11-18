import json

from django.db import migrations, models

"""
Migration 0191: dashboard tiles in their own table (dashboard_tiles).

The home dashboard grid was built from lists written in the app (Monthly ...
COIN), standalone categories (History Sheeter, MPDA) and the 'dashboard'/'tools'
module setting (Tadipar ... E-Learning). Now every tile except "Forms" is one
row of dashboard_tiles, and the app builds the grid from the active rows in
display_order.

The table is shared by all states, so it is created in public (like
module_settings). The rows reproduce the grid as it is today; the tools rows
are copied from the current 'dashboard'/'tools' setting, which stays as it is
for older app builds. Running it again adds nothing twice.
"""

CREATE_SQL = """
CREATE TABLE IF NOT EXISTS public.dashboard_tiles (
    id BIGSERIAL PRIMARY KEY,
    label VARCHAR(150) NOT NULL,
    module_key VARCHAR(100) NOT NULL UNIQUE,
    icon VARCHAR(255) NOT NULL DEFAULT '',
    icon_type VARCHAR(20) NOT NULL DEFAULT 'material',
    color VARCHAR(20) NULL,
    category_code VARCHAR(100) NULL,
    section VARCHAR(20) NOT NULL DEFAULT 'cases',
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);
CREATE INDEX IF NOT EXISTS dashboard_tiles_order_idx ON public.dashboard_tiles (display_order);
"""

# (label, module_key, icon, section, category_code), in grid order. "Forms" is
# not here: the app always shows it after "Pending".
TILES = [
    ('Monthly', 'monthly', 'calendar_month', 'stats', None),
    ('Pending', 'pending', 'pending_actions', 'stats', None),
    ('Detected', 'detected', 'search', 'stats', None),
    ('Undetected', 'undetected', 'visibility_off', 'stats', None),
    ('Disposal', 'disposal', 'delete_forever', 'stats', None),
    ('I to V', 'form_1_5', 'description', 'stats', None),
    ('VI', 'form_6', 'article', 'stats', None),
    ('Murder/Attempt to Murder', 'murder', 'gavel', 'cases', None),
    ('Dacoity/Robbery', 'dacoity', 'gavel', 'cases', None),
    ('Cheating/CBT', 'cheating', 'gavel', 'cases', None),
    ('Chain Snatching', 'chain_snatching', 'gavel', 'cases', None),
    ('A.D', 'ad', 'gavel', 'cases', None),
    ('Hurt', 'hurt', 'local_hospital', 'cases', None),
    ('Theft', 'theft', 'no_encryption', 'cases', None),
    ('Sand Theft', 'sand_theft', 'terrain', 'cases', None),
    ('Two/Four\nWheeler Theft', 'two_four_wheeler', 'two_wheeler', 'cases', None),
    ('Kidnapping/Missing', 'kidnapping', 'child_care', 'cases', None),
    ('N.C', 'nc', 'report', 'cases', None),
    ('Preventive', 'preventive', 'security', 'cases', None),
    ('Arrested', 'arrested', 'handcuffs', 'cases', None),
    ('Absconded', 'absconded', 'directions_run', 'cases', None),
    ('Crime against\nWomen', 'crime_women', 'woman', 'cases', None),
    ('Juvenile', 'juvenile', 'child_friendly', 'cases', None),  # shown as "CiCL"
    ('Victim', 'victim', 'healing', 'cases', None),
    ('Accident', 'accident', 'car_crash', 'cases', None),
    ('CRPC 156(3)/\nBNSS 175(3)', 'bnss', 'balance', 'cases', None),
    ('COIN', 'coin', 'monetization_on', 'cases', None),
    ('Prohibition', 'prohibition', 'admin_panel', 'cases', None),
    ('Gambling', 'gambling', 'monetization_on', 'cases', None),
    ('POCSO', 'pocso', 'shield', 'special', None),
    ('NDPS', 'ndps', 'medication', 'special', None),
    ('Gowansh', 'gowans', 'home_work', 'special', None),
    ('IT Act', 'it_act', 'computer', 'special', None),
    ('M.V Act', 'traffic', 'traffic', 'special', None),
    ('UAPA', 'uapa', 'account_balance', 'special', None),
    ('Sam/Warrant', 'sam_warrant', 'assignment', 'special', None),
    ('Muddemal', 'muddemal', 'inventory', 'special', None),
    ('RTI', 'application', 'description', 'special', 'STAND_RTI'),
    ('Passport/\nPVR/Licence', 'passport', 'badge', 'special', None),
    ('MCOCA', 'mcoca', 'policy', 'special', None),
    ('History Sheeter', 'stand_history_sheeter', 'assignment', 'special', 'STAND_HISTORY_SHEETER'),
    ('MPDA', 'stand_mpda', 'admin_panel', 'special', 'STAND_MPDA'),
]

# Used only when the 'dashboard'/'tools' setting is missing or empty
DEFAULT_TOOLS = [
    {'module_key': 'tadipar', 'label': 'Tadipar', 'icon': 'assets/icons/tadipar.svg',
     'icon_type': 'asset', 'color': '0xFF1ABC9C', 'category_code': 'tadipar'},
    {'module_key': 'repeat_offender', 'label': 'Repeat Offender', 'icon': 'assets/icons/repeatoffender.svg',
     'icon_type': 'asset', 'color': '0xFFF39C12'},
    {'module_key': 'itsso', 'label': 'ITSSO', 'icon': 'assets/icons/itsso.svg',
     'icon_type': 'asset', 'color': '0xFFE91E63'},
    {'module_key': 'nafis', 'label': 'NAFIS/Fingerprint', 'icon': 'fingerprint_rounded',
     'icon_type': 'material', 'color': '0xFF673AB7'},
    {'module_key': 'dar', 'label': 'DAR/IRAD', 'icon': 'assets/icons/dar.svg',
     'icon_type': 'asset', 'color': '0xFF607D8B'},
    {'module_key': 'elearning', 'label': 'E-Learning', 'icon': 'school_rounded',
     'icon_type': 'material', 'color': '0xFF7F8C8D'},
]

# Tools that have their own tile no longer (Licence is a tab of Passport/PVR/Licence,
# IRAD a tab of DAR/IRAD)
SKIPPED_TOOLS = {'licence', 'irad'}


def create_table(apps, schema_editor):
    if schema_editor.connection.vendor == 'postgresql':
        schema_editor.execute(CREATE_SQL)
    else:
        schema_editor.create_model(apps.get_model('crimetab', 'DashboardTile'))


def _current_tools(apps):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    setting = ModuleSetting.objects.filter(module_key='dashboard', setting_key='tools').first()
    try:
        tools = json.loads(setting.setting_value or '[]') if setting else []
    except (TypeError, ValueError):
        tools = []
    if not isinstance(tools, list):
        tools = []
    tools = [t for t in tools if isinstance(t, dict) and t.get('module_key')]
    active = [t for t in tools
              if t.get('is_active', True) and t.get('module_key') not in SKIPPED_TOOLS]
    if not active:
        return DEFAULT_TOOLS
    return sorted(active, key=lambda t: int(t.get('display_order') or 0))


def seed_tiles(apps, schema_editor):
    DashboardTile = apps.get_model('crimetab', 'DashboardTile')
    order = 0
    for label, module_key, icon, section, category_code in TILES:
        order += 10
        DashboardTile.objects.get_or_create(
            module_key=module_key,
            defaults={
                'label': label, 'icon': icon, 'icon_type': 'material',
                'section': section, 'category_code': category_code,
                'display_order': order, 'is_active': True,
            },
        )
    for tool in _current_tools(apps):
        order += 10
        icon = str(tool.get('icon') or '')
        icon_type = tool.get('icon_type') or ('asset' if icon.startswith('assets/') else 'material')
        DashboardTile.objects.get_or_create(
            module_key=str(tool['module_key']),
            defaults={
                'label': str(tool.get('label') or tool['module_key']),
                'icon': icon, 'icon_type': icon_type,
                'color': tool.get('color'),
                'category_code': tool.get('category_code'),
                'section': 'tools', 'display_order': order, 'is_active': True,
            },
        )


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0190_hide_licence_dashboard_tile'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[
                # Going backwards keeps the table and its rows (nothing is dropped)
                migrations.RunPython(create_table, reverse_code=migrations.RunPython.noop),
            ],
            state_operations=[
                migrations.CreateModel(
                    name='DashboardTile',
                    fields=[
                        ('id', models.BigAutoField(primary_key=True, serialize=False)),
                        ('label', models.CharField(max_length=150)),
                        ('module_key', models.CharField(max_length=100, unique=True)),
                        ('icon', models.CharField(blank=True, default='', max_length=255)),
                        ('icon_type', models.CharField(default='material', max_length=20)),
                        ('color', models.CharField(blank=True, max_length=20, null=True)),
                        ('category_code', models.CharField(blank=True, max_length=100, null=True)),
                        ('section', models.CharField(
                            choices=[('stats', 'Crime statistics'), ('cases', 'Case categories'),
                                     ('special', 'Special acts and services'), ('tools', 'Tools')],
                            default='cases', max_length=20)),
                        ('display_order', models.IntegerField(default=0)),
                        ('is_active', models.BooleanField(default=True)),
                    ],
                    options={
                        'verbose_name': 'Dashboard Tile',
                        'verbose_name_plural': 'Dashboard Tiles',
                        'db_table': 'dashboard_tiles',
                        'ordering': ['display_order', 'id'],
                    },
                ),
            ],
        ),
        migrations.RunPython(seed_tiles, reverse_code=migrations.RunPython.noop),
    ]
