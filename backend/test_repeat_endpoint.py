import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from rest_framework.test import APIClient
from apps.users.models import OfficerProfile

try:
    c = APIClient()
    user = OfficerProfile.objects.first()
    if user:
        c.force_authenticate(user=user)
    
    response = c.get('/api/cases/repeat-offender/case-wise/')
    print(f"Status Code: {response.status_code}")
    print(f"Response Data: {response.json() if response.status_code == 200 else response.content}")
except Exception as e:
    import traceback
    traceback.print_exc()
