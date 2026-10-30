"""My Cases lists only the cases the signed-in officer created."""
import jwt
from django.conf import settings
from django.core.cache import cache
from django.test import TestCase
from rest_framework.test import APIClient

from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.public_master.models import Role, StateRegistry
from apps.users.models import OfficerProfile


class MyCasesTests(TestCase):
    def setUp(self):
        cache.clear()
        StateRegistry.objects.create(state_code='MH', state_name='Maharashtra', schema_name='maharashtra', is_active=True)
        Role.objects.get_or_create(id='officer', defaults={'name': 'officer', 'level': 'station'})
        for uid in ('gauri', 'other'):
            OfficerProfile.objects.create(uid=uid, email=f'{uid}@x.in', name=uid, station_name='Station A',
                                          role_id='officer', account_status='active')
        with TenantContext('maharashtra'):
            for pk, creator, state in (('m1', 'gauri', 'Pending'), ('m2', 'gauri', 'Disposed'), ('m3', 'other', 'Pending')):
                CaseRecord.objects.create(id=pk, module_key='form_1_5', sub_category='Murder', title='T',
                                          case_number=pk, station_name='Station A', created_by=creator, status=state)

    def tearDown(self):
        cache.clear()

    def _ids(self, scope):
        client = APIClient()
        token = jwt.encode({'uid': 'gauri', 'state_code': 'MH', 'user_type': 'officer'},
                           settings.SECRET_KEY, algorithm='HS256')
        client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}', HTTP_X_STATE_CODE='MH')
        response = client.get('/api/cases/mine/', {'scope': scope})
        self.assertEqual(response.status_code, 200, response.content[:200])
        return sorted(row['id'] for row in response.json())

    def test_only_own_cases(self):
        self.assertEqual(self._ids('all'), ['m1', 'm2'])

    def test_pending_and_disposal_split(self):
        self.assertEqual(self._ids('pending'), ['m1'])
        self.assertEqual(self._ids('disposal'), ['m2'])
