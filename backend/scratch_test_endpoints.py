import requests

BASE_URL = "http://127.0.0.1:8000/api"

# Get a valid token (simulate login)
# We will use the test user or just assume authentication is disabled for test, but actually the backend is running and we can just use test client or simulate it.
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()
from rest_framework.test import APIClient
from django.contrib.auth import get_user_model
User = get_user_model()
user = User.objects.filter(is_superuser=True).first()
if not user:
    user = User.objects.create_superuser('testsuper', 'test@test.com', 'pass')

client = APIClient()
client.force_authenticate(user=user)

def sim_request(url, params=None):
    print(f"\n[APP REQUEST] GET {url} params: {params or {}}")
    response = client.get(url, params)
    print(f"[BACKEND RESPONSE] Status: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        if isinstance(data, dict) and 'results' in data:
            print(f"   => Paginated Response: count={data['count']}, results={len(data['results'])} items")
        elif isinstance(data, list):
            print(f"   => List Response: {len(data)} items")
        else:
            print(f"   => Other: {data}")
    else:
        print(f"   => Error: {response.content}")

# 1. Open Disposal Hub (Case Wise tab defaults)
sim_request("/api/cases/disposal/case-wise/", {'page': 1, 'page_size': 20})

# 2. Switch to Time Wise tab
sim_request("/api/cases/disposal/time-wise/")

# 3. Tap a month row from Time Wise (e.g. September 2026)
sim_request("/api/cases/disposal/case-wise/", {
    'start_date': '2026-09-01',
    'end_date': '2026-09-30',
    'page': 1,
    'page_size': 20
})

# 4. Switch to IO Wise tab
sim_request("/api/cases/disposal/designation-wise/")

# 5. Tap an officer row
sim_request("/api/cases/disposal/case-wise/", {
    'io_uid': 'some-officer-uid',
    'page': 1,
    'page_size': 20
})
