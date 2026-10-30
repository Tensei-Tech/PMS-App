import json
from django.db import migrations

"""
Migration 0136: Dashboard tools dynamic configuration in module_settings.
Stores all dashboard tools metadata (module key, display name, icon identifier/asset,
color, category, and display order) in database, removing frontend hardcoded entries.
"""

DASHBOARD_TOOLS = [
    {
        "module_key": "licence",
        "label": "Licence",
        "icon": "assignment_ind_rounded",
        "icon_type": "material",
        "color": "0xFF9B59B6",
        "category": "service_tool",
        "display_order": 1,
        "is_active": True,
    },
    {
        "module_key": "tadipar",
        "label": "Tadipar",
        "icon": "assets/icons/tadipar.svg",
        "icon_type": "asset",
        "color": "0xFF1ABC9C",
        "category": "service_tool",
        "category_code": "tadipar",
        "display_order": 2,
        "is_active": True,
    },
    {
        "module_key": "repeat_offender",
        "label": "Repeat Offender",
        "icon": "warning_rounded",
        "icon_type": "material",
        "color": "0xFFF39C12",
        "category": "service_tool",
        "display_order": 3,
        "is_active": True,
    },
    {
        "module_key": "itsso",
        "label": "ITSSO",
        "icon": "description_rounded",
        "icon_type": "material",
        "color": "0xFFE91E63",
        "category": "service_tool",
        "display_order": 4,
        "is_active": True,
    },
    {
        "module_key": "nafis",
        "label": "NAFIS",
        "icon": "fingerprint_rounded",
        "icon_type": "material",
        "color": "0xFF673AB7",
        "category": "service_tool",
        "display_order": 5,
        "is_active": True,
    },
    {
        "module_key": "dar",
        "label": "DAR",
        "icon": "folder_rounded",
        "icon_type": "material",
        "color": "0xFF607D8B",
        "category": "service_tool",
        "display_order": 6,
        "is_active": True,
    },
    {
        "module_key": "irad",
        "label": "IRAD",
        "icon": "analytics_rounded",
        "icon_type": "material",
        "color": "0xFF34495E",
        "category": "service_tool",
        "display_order": 7,
        "is_active": True,
    },
    {
        "module_key": "elearning",
        "label": "E-Learning",
        "icon": "school_rounded",
        "icon_type": "material",
        "color": "0xFF7F8C8D",
        "category": "service_tool",
        "display_order": 8,
        "is_active": True,
    },
]


def forwards(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    ModuleSetting.objects.update_or_create(
        module_key='dashboard',
        setting_key='tools',
        defaults={'setting_value': json.dumps(DASHBOARD_TOOLS)}
    )


def backwards(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    ModuleSetting.objects.filter(module_key='dashboard', setting_key='tools').delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0135_tadipar_sr_no_auto_sequence'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]

