from django.db import migrations

"""
Migration 0058: extra N.C. module_settings used by the API (Step 3)

Data only, idempotent (existing keys are left untouched). Adds the generic error
messages, the charge table headings and the PDF footer texts so no N.C. text is
typed in code.
"""

SETTINGS = [
    ('request_failed_message', 'The request could not be completed. Please try again.'),
    ('invalid_request_message', 'Invalid request.'),
    ('charge_act_label', 'Act'),
    ('charge_section_label', 'Section'),
    ('charge_subsection_label', 'Subsection'),
    ('pdf_footer_text', 'CONFIDENTIAL - FOR OFFICIAL USE ONLY'),
    ('pdf_generated_label', 'Generated on {time}'),
    ('pdf_page_label', 'Page {page} of {total}'),
]


def seed(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    for key, value in SETTINGS:
        ModuleSetting.objects.get_or_create(module_key='nc', setting_key=key, defaults={'setting_value': value})


def unseed(apps, schema_editor):
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    ModuleSetting.objects.filter(module_key='nc', setting_key__in=[k for k, _ in SETTINGS]).delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0056_road_accident_tenant_tables'),
    ]

    operations = [
        migrations.RunPython(seed, reverse_code=unseed),
    ]
