import os
import django
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.cases.models import CaseRecord

qs = CaseRecord.objects.all()
c = 0
for case in qs:
    ex = case.extra_fields if isinstance(case.extra_fields, dict) else {}
    acc = ex.get('commonForm', {}).get('accusedDetails', [])
    ages = [a.get('age') for a in acc if isinstance(a, dict)]
    dobs = [a.get('dob') for a in acc if isinstance(a, dict)]
    
    is_juv = False
    for age in ages:
        if age and str(age).isdigit() and int(age) < 18:
            is_juv = True
            print('Found juvenile age:', age, 'in case:', case.id)
            break
            
    if is_juv:
        c += 1
        continue
        
    for dob in dobs:
        if dob:
            print('Found DOB in case', case.id, dob)

print('Total juvenile cases found:', c)
