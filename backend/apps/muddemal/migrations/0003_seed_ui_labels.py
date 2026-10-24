from django.db import migrations


def seed_ui_labels(apps, schema_editor):
    MuddemalConfig = apps.get_model('muddemal', 'MuddemalConfig')

    ui_labels_data = {
        'property_category_label': 'Type of Property',
        'all_categories_label': 'All Types of Property',
        'attributes_tab_label': 'Information',
        'attributes_section_label': 'Dynamic Information',
        'category_specific_info_label': 'Category-Specific Information',
        'select_property_category_label': 'Select Type of Property *',
        'fill_dynamic_info_label': 'Select type of property and fill dynamic information',
    }

    MuddemalConfig.objects.update_or_create(
        config_key='ui_labels',
        defaults={
            'config_value': ui_labels_data,
            'description': 'Master database-driven UI labels for Muddemal Property Management',
        }
    )


def reverse_seed_ui_labels(apps, schema_editor):
    pass


class Migration(migrations.Migration):

    dependencies = [
        ('muddemal', '0002_seed_muddemal_data'),
    ]

    operations = [
        migrations.AlterModelOptions(
            name='muddemalpropertycategory',
            options={
                'ordering': ['display_order', 'category_name'],
                'verbose_name': 'Type of Property',
                'verbose_name_plural': 'Types of Property',
            },
        ),
        migrations.RunPython(seed_ui_labels, reverse_seed_ui_labels),
    ]
