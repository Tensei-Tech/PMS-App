from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from apps.authentication.views import (
    RegisterView, LoginView, UserPermissionsView, CheckContactExistsView, SendOTPView,
    PendingApprovalsNotificationListView, ApproveRejectOfficerRegistrationView
)

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('check-exists/', CheckContactExistsView.as_view(), name='check-exists'),
    path('send-otp/', SendOTPView.as_view(), name='send-otp'),
    path('notifications/pending-approvals/', PendingApprovalsNotificationListView.as_view(), name='pending-approvals'),
    path('users/<str:uid>/approve-registration/', ApproveRejectOfficerRegistrationView.as_view(), name='approve-registration'),
    # Aliases for backwards compatibility & frontend route flexibility
    path('officers/notifications/', PendingApprovalsNotificationListView.as_view(), name='officers-notifications-alias'),
    path('officers/approvals/<str:uid>/', ApproveRejectOfficerRegistrationView.as_view(), name='officers-approvals-alias'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token-refresh'),
    path('me/permissions/', UserPermissionsView.as_view(), name='me-permissions'),
]
