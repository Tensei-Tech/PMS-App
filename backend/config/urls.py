from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse


def health_check(request):
    return JsonResponse({
        'status': 'healthy',
        'service': 'PMS App Backend',
        'api_version': '1.0.0'
    })


urlpatterns = [
    # Root Health Check for Render & Load Balancers
    path('', health_check, name='root-health-check'),

    # Enterprise Django Admin Console
    path('admin/', admin.site.urls),

    # Enterprise REST API Domain Services (Clean Resource-Oriented Routing)
    path('api/auth/', include('apps.authentication.urls')),
    path('api/master/', include('apps.public_master.urls')),
    path('api/users/', include('apps.users.urls')),
    path('api/stations/', include('apps.stations.urls')),
    path('', include('apps.cases.urls')),
    path('api/cases/', include('apps.cases.urls')),
    path('api/core/', include('apps.core.urls')),
]
