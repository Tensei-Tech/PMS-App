import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.test import RequestFactory
from apps.cases.views import TimeWisePendingView, IOWisePendingView
from apps.cases.views import TimeWiseDisposalView, DesignationWiseDisposalView

from rest_framework.test import force_authenticate
from django.contrib.auth import get_user_model
User = get_user_model()

user = User.objects.first()

factory = RequestFactory()

TimeWisePendingView.permission_classes = []
TimeWiseDisposalView.permission_classes = []
IOWisePendingView.permission_classes = []
DesignationWiseDisposalView.permission_classes = []

request1 = factory.get('/api/cases/pending/time-wise/')
force_authenticate(request1, user=user)
response1 = TimeWisePendingView.as_view()(request1)
print("PENDING TIME-WISE:", response1.data)

request2 = factory.get('/api/cases/disposal/time-wise/')
force_authenticate(request2, user=user)
response2 = TimeWiseDisposalView.as_view()(request2)
print("DISPOSAL TIME-WISE:", response2.data)

request3 = factory.get('/api/cases/pending/io-wise/')
force_authenticate(request3, user=user)
response3 = IOWisePendingView.as_view()(request3)
print("PENDING IO-WISE:", response3.data)

request4 = factory.get('/api/cases/disposal/designation-wise/')
force_authenticate(request4, user=user)
response4 = DesignationWiseDisposalView.as_view()(request4)
print("DISPOSAL IO-WISE:", response4.data)

request3 = factory.get('/api/cases/pending/io-wise/')
response3 = IOWisePendingView.as_view()(request3)
print("PENDING IO-WISE:", response3.data)

request4 = factory.get('/api/cases/disposal/designation-wise/')
response4 = DesignationWiseDisposalView.as_view()(request4)
print("DISPOSAL IO-WISE:", response4.data)
