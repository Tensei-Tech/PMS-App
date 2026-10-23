from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0037_finalize_common_form_baseline_template'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[],
            state_operations=[
                migrations.AlterField(
                    model_name='fieldtemplatefield',
                    name='field_type',
                    field=models.CharField(
                        choices=[
                            ('text', 'Text Field'),
                            ('textarea', 'Multi-line Text Area'),
                            ('number', 'Numeric Field'),
                            ('date', 'Date Picker'),
                            ('datetime', 'Date-Time Picker'),
                            ('dropdown', 'Dropdown Select'),
                            ('checkbox', 'Checkbox Toggle'),
                            ('radio', 'Radio Button Group'),
                            ('chips', 'Chips Selector'),
                            ('file', 'File Upload'),
                            ('multi_select', 'Multi-Select Dropdown'),
                            ('repeating_group', 'Repeating Group'),
                        ],
                        default='text',
                        max_length=20,
                    ),
                ),
            ],
        ),
    ]
