from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    # Enterprise Django Admin Console
    path('admin/', admin.site.urls),

    # Enterprise REST API Domain Services (Clean Resource-Oriented Routing)
    path('api/auth/', include('apps.authentication.urls')),
    path('api/master/', include('apps.public_master.urls')),
    path('api/users/', include('apps.users.urls')),
    path('api/stations/', include('apps.stations.urls')),
    path('api/cases/', include('apps.cases.urls')),
]
