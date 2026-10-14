import django, os
os.environ['DJANGO_SETTINGS_MODULE'] = 'config.settings'
django.setup()

from apps.users.models import OfficerProfile
from apps.elearning.models import OfficerCourseRecord
from django.db.models import Q

station = "Maharashtra Police HQ"

print(f"=== Searching station: '{station}' ===\n")

# 1. Check OfficerProfile matches
officers = OfficerProfile.objects.all()
exact = officers.filter(Q(station_name__iexact=station) | Q(station_name__icontains=station))
print(f"OfficerProfile matches for '{station}': {exact.count()}")
for o in exact:
    print(f"  - {o.name} | station_name='{o.station_name}'")

# 2. Check all unique station names in OfficerProfile
print(f"\nAll unique stations in OfficerProfile:")
for s in officers.values_list('station_name', flat=True).distinct():
    print(f"  '{s}'")

# 3. Check course records
records = OfficerCourseRecord.objects.all()
print(f"\nTotal course records: {records.count()}")
for r in records:
    print(f"  - {r.officer_name} | station='{r.station_name}' | course={r.course_name}")

# 4. Check what the logged-in user's station looks like
from django.contrib.auth import get_user_model
User = get_user_model()
for u in User.objects.all():
    sn = getattr(u, 'station_name', 'N/A')
    print(f"\nAuth User: {u.username} | station_name='{sn}' | type={type(sn)}")
