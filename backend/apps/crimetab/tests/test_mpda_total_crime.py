from django.test import TestCase
from rest_framework.test import force_authenticate

from apps.crimetab.models import ModuleSetting
from apps.crimetab.models.mpda import MpdaProposal
from apps.crimetab.tests.test_mpda_backend import MpdaBackendTestCase
from apps.crimetab.views_mpda import MpdaDetailView, MpdaListCreateView


class MpdaTotalCrimeTests(TestCase):
    def setUp(self):
        MpdaBackendTestCase.setUp(self)
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='enforce_permissions',
                                               defaults={'setting_value': 'false'})

    def _create(self, payload):
        req = self.factory.post('/api/mpda/', {'mpda_proposal_no_and_year': 'TEST 5/2026', **payload},
                                format='json')
        force_authenticate(req, user=self.user)
        return MpdaListCreateView.as_view()(req)

    def _patch(self, prop, payload):
        req = self.factory.patch(f'/api/mpda/{prop.id}/', payload, format='json')
        force_authenticate(req, user=self.user)
        return MpdaDetailView.as_view()(req, pk=prop.id)

    def test_total_is_serious_plus_misc_whatever_is_sent(self):
        res = self._create({'mpda_total_crime': '99', 'mpda_serious_crimes': '3',
                            'mpda_total_misc_crime': '4'})
        self.assertIn(res.status_code, (200, 201), res.data)
        prop = MpdaProposal.objects.order_by('-id').first()
        self.assertEqual((prop.total_crime, prop.serious_crimes, prop.total_misc_crime), (7, 3, 4))

    def test_only_one_part_given(self):
        self._create({'mpda_serious_crimes': '5'})
        prop = MpdaProposal.objects.order_by('-id').first()
        self.assertEqual(prop.total_crime, 5)

    def test_patch_recalculates_with_stored_part(self):
        self._create({'mpda_serious_crimes': '2', 'mpda_total_misc_crime': '1'})
        prop = MpdaProposal.objects.order_by('-id').first()
        self.assertEqual(self._patch(prop, {'mpda_total_misc_crime': '6'}).status_code, 200)
        prop.refresh_from_db()
        self.assertEqual(prop.total_crime, 8)

    def test_legacy_total_without_parts_is_kept(self):
        self._create({'mpda_total_crime': '9'})
        self.assertEqual(MpdaProposal.objects.order_by('-id').first().total_crime, 9)

    def test_patch_with_a_smaller_total_cannot_go_below_serious(self):
        self._create({'mpda_serious_crimes': '5', 'mpda_total_misc_crime': '2'})
        prop = MpdaProposal.objects.order_by('-id').first()
        self.assertEqual(self._patch(prop, {'mpda_total_crime': '1'}).status_code, 200)
        prop.refresh_from_db()
        self.assertEqual(prop.total_crime, 7)
        self.assertLessEqual(prop.serious_crimes, prop.total_crime)

    def test_negative_count_rejected(self):
        res = self._create({'mpda_serious_crimes': '-1'})
        self.assertEqual(res.status_code, 400)
