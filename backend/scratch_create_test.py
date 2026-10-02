import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.cases.models import CaseRecord
from rest_framework.test import APIClient

client = APIClient()

# Test 1: Normal ORM creation without specifying PK
case1 = CaseRecord.objects.create(case_number='TEST_CREATE_1', title='Title 1', module_key='form_1_5')
print(f"ORM Create: id={case1.pk}, case_number={case1.case_number}, disposal_date={case1.extra_fields.get('disposal_date')}")

# Test 2: Create via CreateCaseView (raw SQL)
payload = {
    'case_number': 'TEST_CREATE_2',
    'title': 'Title 2',
    'module': 'form_1_5'
}
response = client.post('/api/cases/create_case/', payload, format='json')
print(f"API Create: status={response.status_code}, data={response.data}")

if response.status_code == 201:
    case_id = response.data['case_id']
    case2 = CaseRecord.objects.get(pk=case_id)
    print(f"API Create verify: case_number={case2.case_number}")
