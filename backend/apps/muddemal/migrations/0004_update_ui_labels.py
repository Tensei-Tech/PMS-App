from django.db import migrations


def update_ui_labels(apps, schema_editor):
    MuddemalConfig = apps.get_model('muddemal', 'MuddemalConfig')

    ui_labels_obj = MuddemalConfig.objects.filter(config_key='ui_labels').first()
    existing_data = ui_labels_obj.config_value if ui_labels_obj and isinstance(ui_labels_obj.config_value, dict) else {}

    updated_data = {
        **existing_data,
        'property_category_label': 'Type of Property',
        'all_categories_label': 'All Types of Property',
        'property_status_label': 'Property Status',
        'all_statuses_label': 'All Statuses',
        'source_module_label': 'Source Module',
        'all_source_modules_label': 'All PMS Modules',
        'search_hint_label': 'Search CR No., Accused, Description, Seized From...',
        'clear_filters_label': 'Clear Filters',
        'attributes_tab_label': 'Information',
        'attributes_section_label': 'Dynamic Information',
        'category_specific_info_label': 'Category-Specific Information',
        'select_property_category_label': 'Select Type of Property *',
        'fill_dynamic_info_label': 'Select type of property and fill dynamic information',
    }

    MuddemalConfig.objects.update_or_create(
        config_key='ui_labels',
        defaults={
            'config_value': updated_data,
            'description': 'Master database-driven UI labels for Muddemal Property Management',
        }
    )


def reverse_update_ui_labels(apps, schema_editor):
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('muddemal', '0003_seed_ui_labels'),
    ]

    operations = [
        migrations.RunPython(update_ui_labels, reverse_update_ui_labels),
    ]
