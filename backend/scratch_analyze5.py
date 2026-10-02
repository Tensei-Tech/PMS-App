import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from apps.cases.serializers import CaseRecordSerializer
from apps.cases.models import CaseRecord

payload = {
    'case_number': 'FLUTTER_TEST_001',
    'title': 'Test Case',
    'module_key': 'murder',
    'module': 'murder',
    'station_name': 'Central',
    'extra_fields': {
        'chargeSheetNumber': 'CS-111',
        'aFinalNo': 'A-222',
        'bFinalNo': 'B-333',
        'cFinalNo': 'C-444',
        'ncFinalNo': 'NC-555',
        'abatedSummaryNo': 'AS-666',
        'ccStNumber': 'CC-777'
    }
}

serializer = CaseRecordSerializer(data=payload)
if serializer.is_valid():
    case = serializer.save(created_by='test_user')
    print("Stored Extra Fields:", case.extra_fields)
    
    # Cleanup
    case.delete()
else:
    print("Errors:", serializer.errors)
