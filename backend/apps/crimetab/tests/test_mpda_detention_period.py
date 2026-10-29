import datetime

from django.test import TestCase
from rest_framework.test import force_authenticate

from apps.crimetab.models import ModuleSetting
from apps.crimetab.models.mpda import MpdaProposal
from apps.crimetab.tests.test_mpda_backend import MpdaBackendTestCase
from apps.crimetab.views_mpda import MpdaDetailView, MpdaListCreateView
from apps.crimetab.tests.state_schema import enter_state_schema


class MpdaDetentionPeriodTests(TestCase):
    def setUp(self):
        enter_state_schema(self)
        MpdaBackendTestCase.setUp(self)
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='enforce_permissions',
                                               defaults={'setting_value': 'false'})

    def _create(self, payload):
        req = self.factory.post('/api/mpda/', {'mpda_proposal_no_and_year': 'TEST 3/2026', **payload},
                                format='json')
        force_authenticate(req, user=self.user)
        return MpdaListCreateView.as_view()(req)

    def _latest(self):
        return MpdaProposal.objects.order_by('-id').first()

    def test_detained_yes_keeps_start_and_end(self):
        res = self._create({'mpda_detained': 'Yes', 'mpda_detention_date': '01/10/2026',
                            'mpda_detention_completion_date': '01/10/2027'})
        self.assertIn(res.status_code, (200, 201), res.data)
        prop = self._latest()
        self.assertEqual((prop.detention_date, prop.detention_completion_date),
                         (datetime.date(2026, 10, 1), datetime.date(2027, 10, 1)))

    def test_not_detained_clears_both_dates(self):
        self._create({'mpda_detained': 'No', 'mpda_detention_date': '01/10/2026',
                      'mpda_detention_completion_date': '01/10/2027'})
        prop = self._latest()
        self.assertEqual((prop.detention_date, prop.detention_completion_date), (None, None))

    def test_end_before_start_rejected(self):
        res = self._create({'mpda_detained': 'Yes', 'mpda_detention_date': '01/10/2026',
                            'mpda_detention_completion_date': '01/09/2026'})
        self.assertEqual(res.status_code, 400)

    def test_patch_to_no_clears_dates(self):
        self._create({'mpda_detained': 'Yes', 'mpda_detention_date': '01/10/2026'})
        prop = self._latest()
        req = self.factory.patch(f'/api/mpda/{prop.id}/', {'mpda_detained': 'No'}, format='json')
        force_authenticate(req, user=self.user)
        self.assertEqual(MpdaDetailView.as_view()(req, pk=prop.id).status_code, 200)
        prop.refresh_from_db()
        self.assertIsNone(prop.detention_date)
