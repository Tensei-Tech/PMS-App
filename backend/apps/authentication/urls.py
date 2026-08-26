from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from apps.authentication.views import RegisterView, LoginView, UserPermissionsView

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token-refresh'),
    path('me/permissions/', UserPermissionsView.as_view(), name='me-permissions'),
]
