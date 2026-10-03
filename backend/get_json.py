import urllib.request
import json

req = urllib.request.Request('http://localhost:8000/api/cases/disposal/case-wise/')
# We need auth. The views require authentication.
# Let's just do it directly via django models/serializers.
import os, django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()
from apps.cases.models import CaseRecord
from apps.cases.serializers import DisposalCaseRecordSerializer

case = CaseRecord.objects.filter(module_key='theft').first()
if case:
    serializer = DisposalCaseRecordSerializer(case)
    print(json.dumps(serializer.data, indent=2))
else:
    print("No case found")
