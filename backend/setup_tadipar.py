import os
import django
import sys

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from apps.crimetab.models import CaseCategory, FieldTemplate, FieldTemplateField, CategoryFieldTemplate

def run():
    print("Setting up Tadipar module configurations...")

    # 1. Create or get Category
    cat, created = CaseCategory.objects.get_or_create(
        category_name='Tadipar',
        defaults={'category_code': 'tadipar'}
    )
    if not created:
        cat.category_code = 'tadipar'
        cat.save()

    # 2. Create or get FieldTemplate
    tmpl, created = FieldTemplate.objects.get_or_create(
        template_name='Tadipar Base Template'
    )

    # 3. Link Category to Template
    CategoryFieldTemplate.objects.get_or_create(
        category=cat,
        template=tmpl
    )

    # 4. Define Fields
    fields = [
        # SECTION 1: BASIC DETAILS
        {'label': 'Sr.no.', 'key': 'sr_no', 'type': 'number', 'section': 'Basic Details', 'order': 1},
        {'label': 'Externed Name', 'key': 'externed_name', 'type': 'text', 'section': 'Basic Details', 'order': 2},
        {'label': 'Alias', 'key': 'alias', 'type': 'text', 'section': 'Basic Details', 'order': 3},
        {'label': 'Nickname', 'key': 'nickname', 'type': 'text', 'section': 'Basic Details', 'order': 4},
        {'label': 'Age', 'key': 'age', 'type': 'number', 'section': 'Basic Details', 'order': 5},
        {'label': 'Gender', 'key': 'gender', 'type': 'dropdown', 'section': 'Basic Details', 'order': 6, 'config': {'options': ['Male', 'Female', 'Other']}},
        {'label': 'Mobile Number', 'key': 'mo_no', 'type': 'text', 'section': 'Basic Details', 'order': 7},
        {'label': 'Address', 'key': 'address', 'type': 'textarea', 'section': 'Basic Details', 'order': 8},
        
        # SECTION 2: ORDER DETAILS
        {'label': 'Order Date', 'key': 'order_date', 'type': 'date', 'section': 'Order Details', 'order': 9},
        {'label': 'Order Number', 'key': 'order_number', 'type': 'text', 'section': 'Order Details', 'order': 10},
        {'label': 'Act', 'key': 'act_id', 'type': 'dependent_dropdown', 'section': 'Order Details', 'order': 11, 'config': {'api_url': 'acts/', 'label_key': 'act_name', 'value_key': 'id'}},
        {'label': 'Section', 'key': 'section_id', 'type': 'dependent_dropdown', 'section': 'Order Details', 'order': 11.1, 'config': {'api_url': 'act-sections/?act_id={parent_value}', 'depends_on': 'act_id', 'label_key': 'display_name', 'value_key': 'id'}},
        {'label': 'Subsection', 'key': 'subsection_id', 'type': 'dependent_dropdown', 'section': 'Order Details', 'order': 11.2, 'config': {'api_url': 'act-subsections/?section_id={parent_value}', 'depends_on': 'section_id', 'label_key': 'display_name', 'value_key': 'id'}},
        
        # SECTION 3: EXTERNMENT PERIOD
        {'label': 'Externment Period - From', 'key': 'period_from', 'type': 'date', 'section': 'Externment Period', 'order': 12},
        {'label': 'Externment Period - To', 'key': 'period_to', 'type': 'date', 'section': 'Externment Period', 'order': 13},
        
        # SECTION 4: STATUS & REVOCATION
        {'label': 'Revoked by Court Date', 'key': 'revoked_date', 'type': 'date', 'section': 'Status & Revocation', 'order': 14},
        {'label': 'Current Address', 'key': 'current_address', 'type': 'textarea', 'section': 'Status & Revocation', 'order': 15},
        
        # SECTION 5: PROHIBITED AREA
        {'label': 'Prohibited District/Area', 'key': 'prohibited_areas', 'type': 'chips', 'section': 'Prohibited Area', 'order': 16, 'config': {'options': ['Bhandara', 'Gondia', 'Nagpur', 'Wardha', 'Chandrapur', 'Amravati', 'Gadchiroli', 'Yavatmal', 'Akola', 'Buldhana', 'Washim']}},

        
        # SECTION 6: CRIME CHART (Repeater)
        {
            'label': 'Crime Chart',
            'key': 'crime_chart_entries',
            'type': 'repeater',
            'section': 'Crime Chart',
            'order': 17,
            'config': {
                'fields': [
                    {'label': 'CR No.', 'key': 'cr_number', 'type': 'text'},
                    {'label': 'Crime Head', 'key': 'crime_head', 'type': 'text'},
                    {'label': 'Act', 'key': 'act_id', 'type': 'dependent_dropdown', 'config': {'api_url': 'acts/', 'label_key': 'act_name', 'value_key': 'id'}},
                    {'label': 'Section', 'key': 'section_id', 'type': 'dependent_dropdown', 'config': {'api_url': 'act-sections/?act_id={parent_value}', 'depends_on': 'act_id', 'label_key': 'display_name', 'value_key': 'id'}},
                    {'label': 'Register Date', 'key': 'register_date', 'type': 'date'},
                    {'label': 'Police Station', 'key': 'police_station_id', 'type': 'dependent_dropdown', 'config': {'api_url': 'stations/', 'label_key': 'name', 'value_key': 'id'}},
                ]
            }
        },
    ]

    # Clear existing fields for this template
    FieldTemplateField.objects.filter(template=tmpl).delete()

    # Create new fields
    for f in fields:
        FieldTemplateField.objects.create(
            template=tmpl,
            field_label=f['label'],
            field_key=f['key'],
            field_source='custom',
            field_type=f['type'],
            is_required=f.get('required', False),
            section=f['section'],
            display_order=f['order'],
            field_config=f.get('config')
        )
    print("Tadipar fields successfully registered!")

if __name__ == '__main__':
    run()
