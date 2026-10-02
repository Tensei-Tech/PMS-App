import os, django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()
import json
from rest_framework.test import APIClient
from django.contrib.auth import get_user_model
from django.contrib.auth.models import Permission

User = get_user_model()
User.objects.filter(username='testadmin').delete()
user = User.objects.create(username='testadmin', password='123')
user.station_name = 'Central'
user.save()
# We need to give them permission 'case:view' but in Django permissions it's usually 'cases.view_caserecord' or similar. 
# Or we can just mock `HasPermission` out for the test.
from apps.cases.views import DisposalCaseWiseView
DisposalCaseWiseView.permission_classes = []

client = APIClient()
client.force_authenticate(user=user)

from apps.cases.models import CaseRecord
CaseRecord.objects.all().delete()
for i in range(25):
    CaseRecord.objects.create(
        module_key='theft',
        case_number=f'CR_{i+1}',
        station_name='Central',
        extra_fields={'act': 'IPC', 'section': '379', 'ccStNumber': f'CC-{i+1}', 'disposal_date': '2023-01-01'}
    )

res = client.get('/api/cases/disposal/case-wise/', {'page': 2, 'page_size': 20})
if res.status_code == 200:
    data = res.json()
    print("Page 2 results:")
    print(json.dumps(data['results'][0:2], indent=2))
else:
    print("Error:", res.status_code)


