import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.db import connection
with connection.cursor() as cursor:
    cursor.execute("SET search_path TO maharashtra, public;")

from rest_framework.test import APIClient
from apps.users.models import OfficerProfile

try:
    c = APIClient()
    user = OfficerProfile.objects.first()
    if user:
        c.force_authenticate(user=user)
    
    r1 = c.get('/api/cases/repeat-offender/case-wise/?page_size=100')
    print(f"Repeat Offender page_size=100: Status {r1.status_code}, Count: {r1.json().get('count')}, Results: {len(r1.json().get('results', []))}")
    
    r2 = c.get('/api/cases/nafis/case-wise/?page_size=100')
    print(f"NAFIS page_size=100: Status {r2.status_code}, Count: {r2.json().get('count')}, Results: {len(r2.json().get('results', []))}")

    r3 = c.get('/api/cases/nafis/case-wise/?all=true')
    print(f"NAFIS all=true: Status {r3.status_code}, Is List: {isinstance(r3.json(), list)}, Len: {len(r3.json()) if isinstance(r3.json(), list) else 'dict'}")
except Exception as e:
    import traceback
    traceback.print_exc()
