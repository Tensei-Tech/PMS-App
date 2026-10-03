import os, django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()
from apps.cases.models import CaseRecord
from apps.crimetab.models.groupings import CaseCategory
from django.db.models import Q

# 1. Distinct module_keys
distinct_keys = CaseRecord.objects.values_list('module_key', flat=True).distinct()
print(f"Distinct keys: {list(distinct_keys)}")

# Build map once (one query! well, we can query all CaseCategory)
cats = CaseCategory.objects.all()
cat_map = {}
for c in cats:
    if c.category_code:
        cat_map[c.category_code.lower()] = c.category_name
    if c.category_name:
        cat_map[c.category_name.lower()] = c.category_name

for key in distinct_keys:
    if not key: continue
    lower_key = key.strip().lower()
    name = cat_map.get(lower_key, key)
    print(f"{key} -> {name}")

