import os, django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.cases.models import CaseRecord
from apps.crimetab.models.groupings import CaseCategory

# 1. Every distinct module_key in the database
distinct_keys = CaseRecord.objects.values_list('module_key', flat=True).distinct()

print("Distinct module_keys in DB:", list(distinct_keys))

# 2. Let's see what CaseCategory has:
cats = CaseCategory.objects.all()
for c in cats:
    print(f"CaseCategory: id={c.pk}, name='{c.category_name}', code='{c.category_code}'")

# How does the frontend display them? Wait, the frontend `Classification.name` maps module_key to label.
