import json
from django.db import migrations, models

"""
Migration 0137: Preventive module dynamic database configuration.
Stores configurable dropdown options (OptionValue), defaults, section titles,
and module settings (ModuleSetting) in PostgreSQL to make Preventive 100% database-driven.
"""

PREVENTIVE_OPTIONS = [
    # Case Statuses
    ('preventive_case_statuses', 'Under Investigation', 1),
    ('preventive_case_statuses', 'Chargesheeted', 2),

    # Risk Flags
    ('preventive_risk_flags', '\U0001F6A8 High Priority', 1),
    ('preventive_risk_flags', '\U0001F6D1 Sensitive', 2),

    # Action Statuses
    ('preventive_action_statuses', '\U0001F7E2 Preventive Action Completed', 1),
    ('preventive_action_statuses', '\U0001F7E1 Partially Completed', 2),
    ('preventive_action_statuses', '\U0001F534 No Preventive Action Recorded', 3),

    # Accused Action Types
    ('preventive_accused_actions', 'Arrested', 1),
    ('preventive_accused_actions', 'Notice Issued', 2),
    ('preventive_accused_actions', 'Not Arrested', 3),

    # Yes/No Options
    ('yes_no', 'Yes', 1),
    ('yes_no', 'No', 2),
]

PREVENTIVE_CONFIG = {
    "target_category_code": "STAND_PREVENTIVE",
    "template_name": "Preventive Module Configuration Template",
    "section_title": "Preventive Action",
    "section_order": 10,
    "defaults": {
        "crime_category": "",
        "act": "",
        "section": "",
        "has_preventive_no": "No",
        "case_status": "Under Investigation",
        "risk_flag": "\U0001F6A8 High Priority",
        "action_status": "\U0001F7E2 Preventive Action Completed",
        "accused_action_type": "Arrested",
        "bond_taken": "No",
        "date_default": "current_date",
        "complainant": ""
    },
    "section_titles": {
        "case_ref": "Case & Crime Reference",
        "sections": "Sections & Acts",
        "accused": "Accused Details",
        "istegasha": "Preventive / Istegasha Details",
        "risk_status": "Risk Flag & Action Status",
        "preventive_action": "Preventive Action"
    },
    "action_labels": {
        "add": "Add Preventive Case",
        "edit": "Edit",
        "view": "View",
        "pdf": "PDF"
    },
    "messages": {
        "no_station": "No valid police station assigned to the current user or session. Please select or switch to a police station before saving.",
        "empty_request": "Please enter Crime No. / FIR No. / NC No. or Preventive No."
    }
}


def forwards(apps, schema_editor):
    OptionValue = apps.get_model('crimetab', 'OptionValue')
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    FieldTemplate = apps.get_model('crimetab', 'FieldTemplate')
    FieldTemplateField = apps.get_model('crimetab', 'FieldTemplateField')

    # 1. Seed OptionValues
    for group, val, order in PREVENTIVE_OPTIONS:
        OptionValue.objects.update_or_create(
            option_group=group,
            option_value=val,
            defaults={
                'display_order': order,
                'is_active': True,
            }
        )

    # 2. Seed ModuleSettings
    ModuleSetting.objects.update_or_create(
        module_key='preventive',
        setting_key='config',
        defaults={'setting_value': json.dumps(PREVENTIVE_CONFIG)}
    )
    ModuleSetting.objects.update_or_create(
        module_key='preventive',
        setting_key='target_category_code',
        defaults={'setting_value': 'STAND_PREVENTIVE'}
    )
    ModuleSetting.objects.update_or_create(
        module_key='preventive',
        setting_key='section_title',
        defaults={'setting_value': 'Preventive Action'}
    )

    # 3. Ensure template 48 fields have complete configuration
    tmpl = FieldTemplate.objects.filter(template_name='Preventive Module Configuration Template').first()
    if tmpl:
        fields_data = [
            {
                'field_key': 'crime_no',
                'field_label': 'Crime No. / FIR No. / NC no. *',
                'field_type': 'text',
                'is_required': True,
                'section': 'Case & Crime Reference',
                'display_order': 100,
                'field_config': {'placeholder': 'e.g. 142/2026 or NC 88/2026'},
            },
            {
                'field_key': 'reg_date',
                'field_label': 'Registration / Arrest Date *',
                'field_type': 'date',
                'is_required': True,
                'section': 'Case & Crime Reference',
                'display_order': 110,
                'field_config': {'default': 'current_date'},
            },
            {
                'field_key': 'crime_category',
                'field_label': 'Crime Category *',
                'field_type': 'dropdown',
                'is_required': True,
                'options_source': 'categories',
                'section': 'Case & Crime Reference',
                'display_order': 120,
                'field_config': {'default': ''},
            },
            {
                'field_key': 'case_status',
                'field_label': 'Case Status',
                'field_type': 'dropdown',
                'is_required': False,
                'options_source': 'preventive_case_statuses',
                'section': 'Case & Crime Reference',
                'display_order': 130,
                'field_config': {
                    'default': 'Under Investigation',
                    'options': ['Under Investigation', 'Chargesheeted'],
                },
            },
            {
                'field_key': 'act',
                'field_label': 'Act *',
                'field_type': 'dropdown',
                'is_required': True,
                'options_source': 'acts',
                'section': 'Sections & Acts',
                'display_order': 200,
                'field_config': {'default': ''},
            },
            {
                'field_key': 'sections',
                'field_label': 'Sections *',
                'field_type': 'chips',
                'is_required': False,
                'section': 'Sections & Acts',
                'display_order': 210,
                'field_config': {'default': ''},
            },
            {
                'field_key': 'other_sections',
                'field_label': 'Other Sections',
                'field_type': 'text',
                'is_required': False,
                'section': 'Sections & Acts',
                'display_order': 220,
                'field_config': {'placeholder': 'e.g. Sec 110/117 BNSS, Sec 107 CrPC'},
            },
            {
                'field_key': 'has_preventive_no',
                'field_label': 'Has Preventive No. / \u0907\u0938\u094d\u0924\u0947\u0917\u093e\u0936\u093e \u0928\u0902\u092c\u0930 *',
                'field_type': 'dropdown',
                'is_required': True,
                'options_source': 'yes_no',
                'section': 'Preventive & Istegasha Details',
                'display_order': 410,
                'field_config': {
                    'default': 'No',
                    'options': ['Yes', 'No'],
                    'enables_fields': ['preventive_no', 'preventive_date'],
                },
            },
            {
                'field_key': 'preventive_section_act',
                'field_label': 'Preventive Section Act (\u092a\u094d\u0930\u0924\u093f\u092c\u0902\u0927\u0915 \u0915\u0932\u092e / \u0915\u093e\u092f\u0926\u093e) *',
                'field_type': 'dropdown',
                'is_required': True,
                'options_source': 'preventive_action_types',
                'section': 'Preventive & Istegasha Details',
                'display_order': 415,
                'field_config': {'default': ''},
            },
            {
                'field_key': 'preventive_no',
                'field_label': 'Preventive No. / \u0907\u0938\u094d\u0924\u0947\u0917\u093e\u0936\u093e \u0928\u0902\u092c\u0930 *',
                'field_type': 'text',
                'is_required': True,
                'section': 'Preventive & Istegasha Details',
                'display_order': 420,
                'field_config': {
                    'depends_on': {'field': 'has_preventive_no', 'value': 'Yes'},
                    'placeholder': 'e.g. IST/04/2026 or Prev No. 12',
                },
            },
            {
                'field_key': 'preventive_date',
                'field_label': 'Date of Preventive (\u092a\u094d\u0930\u0924\u093f\u092c\u0902\u0927\u0915 \u0924\u093e\u0930\u0940\u0916) *',
                'field_type': 'date',
                'is_required': True,
                'section': 'Preventive & Istegasha Details',
                'display_order': 430,
                'field_config': {
                    'default': 'current_date',
                    'depends_on': {'field': 'has_preventive_no', 'value': 'Yes'},
                },
            },
            {
                'field_key': 'outward_no',
                'field_label': 'Outward Number',
                'field_type': 'text',
                'is_required': False,
                'section': 'Preventive & Istegasha Details',
                'display_order': 440,
                'field_config': {'placeholder': 'e.g. OW/PS/452/2026'},
            },
            {
                'field_key': 'io_name',
                'field_label': 'Investigating Officer (IO)',
                'field_type': 'text',
                'is_required': False,
                'section': 'Preventive & Istegasha Details',
                'display_order': 450,
                'field_config': {'placeholder': 'e.g. PSI Patil / ASI Deshmukh'},
            },
            {
                'field_key': 'risk_flag',
                'field_label': 'Risk Flag',
                'field_type': 'dropdown',
                'is_required': False,
                'options_source': 'preventive_risk_flags',
                'section': 'Risk Flag & Preventive Action Status',
                'display_order': 510,
                'field_config': {
                    'default': '\U0001F6A8 High Priority',
                    'options': ['\U0001F6A8 High Priority', '\U0001F6D1 Sensitive'],
                },
            },
            {
                'field_key': 'preventive_action_status',
                'field_label': 'Preventive Action Status (\u0915\u093e\u0930\u0935\u093e\u0908 \u0938\u094d\u0925\u093f\u0924\u0940)',
                'field_type': 'dropdown',
                'is_required': True,
                'options_source': 'preventive_action_statuses',
                'section': 'Risk Flag & Preventive Action Status',
                'display_order': 520,
                'field_config': {
                    'default': '\U0001F7E2 Preventive Action Completed',
                    'options': [
                        '\U0001F7E2 Preventive Action Completed',
                        '\U0001F7E1 Partially Completed',
                        '\U0001F534 No Preventive Action Recorded',
                    ],
                },
            },
            {
                'field_key': 'remarks',
                'field_label': 'Remarks / Action Summary',
                'field_type': 'textarea',
                'is_required': False,
                'section': 'Risk Flag & Preventive Action Status',
                'display_order': 530,
                'field_config': {'placeholder': 'Enter preventive order details...'},
            },
        ]
        for f in fields_data:
            FieldTemplateField.objects.update_or_create(
                template=tmpl,
                field_key=f['field_key'],
                defaults={
                    'field_label': f['field_label'],
                    'field_type': f['field_type'],
                    'is_required': f.get('is_required', False),
                    'section': f.get('section', 'General'),
                    'display_order': f.get('display_order', 0),
                    'options_source': f.get('options_source'),
                    'field_config': f.get('field_config'),
                }
            )


def backwards(apps, schema_editor):
    OptionValue = apps.get_model('crimetab', 'OptionValue')
    ModuleSetting = apps.get_model('crimetab', 'ModuleSetting')
    for group, val, _ in PREVENTIVE_OPTIONS:
        OptionValue.objects.filter(option_group=group, option_value=val).delete()
    ModuleSetting.objects.filter(module_key='preventive').delete()


class Migration(migrations.Migration):

    dependencies = [
        ('crimetab', '0136_dashboard_tools_configuration'),
    ]

    operations = [
        migrations.RunPython(forwards, reverse_code=backwards),
    ]
