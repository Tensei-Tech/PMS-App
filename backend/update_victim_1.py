import re
import os

base_dir = r"c:\Users\Nitin\Downloads\PMS-App-dev\PMS-App-dev\backend\apps\cases"

# 1. Update utils.py
utils_path = os.path.join(base_dir, 'utils.py')
with open(utils_path, 'r', encoding='utf-8') as f:
    utils_content = f.read()

victim_utils_code = '''

def get_victim_cases():
    \"\"\"
    Returns cases that fall under Victim categories.
    Modules: POCSO, Crime Against Women, Accident, Cheating/Fraud, Domestic Violence, Missing/Kidnapping.
    \"\"\"
    from apps.core.tenancy import get_active_tenant_schema, set_tenant_schema
    
    schema = get_active_tenant_schema()
    if schema and schema != 'public':
        set_tenant_schema(schema)
        
    target_modules = [
        'pocso', 'crime_women', 'accident', 'cheating', '498_a_ipc', 'missing', 'kidnapping'
    ]
    
    # We can also add category_links logic if needed, but module_key is standard
    from django.db.models import Q
    queryset = CaseRecord.objects.filter(
        Q(module_key__in=target_modules) |
        Q(sub_category__iexact='pocso') |
        Q(sub_category__iexact='crime against women') |
        Q(sub_category__iexact='accident') |
        Q(sub_category__iexact='cheating') |
        Q(sub_category__iexact='498 (a) ipc') |
        Q(sub_category__iexact='missing') |
        Q(sub_category__iexact='kidnapping')
    ).distinct()
    
    if schema and schema != 'public':
        set_tenant_schema(schema)
        
    return queryset
'''
if 'def get_victim_cases' not in utils_content:
    with open(utils_path, 'a', encoding='utf-8') as f:
        f.write(victim_utils_code)

# 2. Update urls.py
urls_path = os.path.join(base_dir, 'urls.py')
with open(urls_path, 'r', encoding='utf-8') as f:
    urls_content = f.read()

if 'VictimCaseWiseView' not in urls_content:
    urls_content = urls_content.replace('from apps.cases.views import (', '''from apps.cases.views import (
    VictimCaseWiseView,
    VictimStatsView,''')
    urls_content = urls_content.replace("]", """]
    path('victim/case-wise/', VictimCaseWiseView.as_view(), name='victim-case-wise'),
    path('victim/stats/', VictimStatsView.as_view(), name='victim-stats'),
]""")
    with open(urls_path, 'w', encoding='utf-8') as f:
        f.write(urls_content)

print('Success')
