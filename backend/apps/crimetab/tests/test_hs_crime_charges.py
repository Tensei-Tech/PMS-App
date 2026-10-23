from django.core.cache import cache
from django.test import TestCase
from rest_framework.test import APIRequestFactory, force_authenticate

from apps.crimetab.models import ModuleSetting
from apps.crimetab.models.common_form import Act, ActSection
from apps.crimetab.models.history_sheeter import HistorySheeterCrime
from apps.crimetab.serializers_history_sheeter import HistorySheeterDetailSerializer
from apps.crimetab.tests.test_history_sheeter_backend import DummyOfficerUser
from apps.crimetab.views_history_sheeter import HistorySheeterDetailView, HistorySheeterListCreateView
from apps.crimetab.tests.state_schema import enter_state_schema

CHARGE = {'act_id': 1, 'act_name': 'TEST Act', 'section_id': 2, 'section_number': 'TEST 10',
          'section_title': 'TEST title', 'subsection_id': 3, 'subsection_code': 'TEST (a)'}


class HistorySheeterCrimeChargeTests(TestCase):
    def setUp(self):
        enter_state_schema(self)
        cache.clear()
        ModuleSetting.objects.update_or_create(module_key='history_sheeter', setting_key='enforce_permissions',
                                               defaults={'setting_value': 'false'})
        self.factory = APIRequestFactory()
        self.user = DummyOfficerUser()

    def _create(self, crime):
        req = self.factory.post('/api/history-sheeter/', {'hs_name': 'TEST', 'hs_crime_chart': [crime]},
                                format='json')
        force_authenticate(req, user=self.user)
        res = HistorySheeterListCreateView.as_view()(req)
        self.assertEqual(res.status_code, 201, res.data)
        return res.data['id']

    def test_picked_charge_saves_columns_and_combined_text(self):
        hs_id = self._create({'hs_crime_cr_no': 'TEST 1/2026', 'hs_crime_act_section': [CHARGE]})
        cr = HistorySheeterCrime.objects.get(history_sheeter_id=hs_id)
        self.assertEqual((cr.act_id, cr.section_id, cr.subsection_id), (1, 2, 3))
        self.assertEqual((cr.act_name, cr.section_number, cr.subsection_code), ('TEST Act', 'TEST 10', 'TEST (a)'))
        self.assertEqual(cr.act_section, 'TEST Act / TEST 10 / TEST (a)')

    def test_edit_form_gets_the_charge_back_and_legacy_text_is_kept(self):
        hs_id = self._create({'hs_crime_act_section': [CHARGE]})
        data = HistorySheeterDetailSerializer(HistorySheeterCrime.objects.get(history_sheeter_id=hs_id)
                                              .history_sheeter).data
        self.assertEqual(data['hs_crime_chart'][0]['hs_crime_act_section'][0]['subsection_code'], 'TEST (a)')

        legacy = self._create({'hs_crime_act_section': 'TEST IPC 302'})
        cr = HistorySheeterCrime.objects.get(history_sheeter_id=legacy)
        self.assertEqual((cr.act_section, cr.act_id), ('TEST IPC 302', None))
        data = HistorySheeterDetailSerializer(cr.history_sheeter).data
        self.assertEqual(data['hs_crime_chart'][0]['hs_crime_act_section'], 'TEST IPC 302')

    def test_charge_survives_replacing_acts_data(self):
        act = Act.objects.create(act_name='TEST Act')
        sec = ActSection.objects.create(act=act, section_number='TEST 10', section_title='TEST title')
        hs_id = self._create({'hs_crime_act_section': [dict(CHARGE, act_id=act.pk, section_id=sec.pk)]})
        ActSection.objects.all().delete()
        Act.objects.all().delete()
        cr = HistorySheeterCrime.objects.get(history_sheeter_id=hs_id)
        self.assertEqual((cr.act_name, cr.section_number), ('TEST Act', 'TEST 10'))

    def test_patch_replaces_crime_rows(self):
        hs_id = self._create({'hs_crime_act_section': [CHARGE]})
        req = self.factory.patch(f'/api/history-sheeter/{hs_id}/', {
            'hs_crime_chart': [{'hs_crime_act_section': [dict(CHARGE, subsection_code=None, subsection_id=None)]}],
        }, format='json')
        force_authenticate(req, user=self.user)
        self.assertEqual(HistorySheeterDetailView.as_view()(req, pk=hs_id).status_code, 200)
        cr = HistorySheeterCrime.objects.get(history_sheeter_id=hs_id)
        self.assertEqual(cr.act_section, 'TEST Act / TEST 10')
