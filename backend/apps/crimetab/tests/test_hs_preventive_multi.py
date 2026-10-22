from django.core.cache import cache
from django.test import TestCase
from rest_framework.test import APIRequestFactory, force_authenticate

from apps.crimetab.models import FieldTemplate, FieldTemplateField, ModuleSetting
from apps.crimetab.models.history_sheeter import HistorySheeterPreventiveAction
from apps.crimetab.tests.test_history_sheeter_backend import DummyOfficerUser
from apps.crimetab.views_history_sheeter import HistorySheeterDetailView, HistorySheeterListCreateView
from apps.crimetab.tests.state_schema import enter_state_schema


class HistorySheeterMultiPreventiveTests(TestCase):
    def setUp(self):
        enter_state_schema(self)
        cache.clear()
        ModuleSetting.objects.update_or_create(module_key='history_sheeter', setting_key='enforce_permissions',
                                               defaults={'setting_value': 'false'})
        tmpl, _ = FieldTemplate.objects.get_or_create(template_name='TEST HS Template')
        FieldTemplateField.objects.get_or_create(
            template=tmpl, field_key='hs_preventive_action_other',
            defaults={'field_label': 'TEST Other', 'field_source': 'custom', 'field_type': 'text',
                      'display_order': 1, 'depends_on_field_key': 'hs_preventive_action_type',
                      'depends_on_value': 'Other', 'parent_field_key': 'hs_preventive_actions'})
        self.factory = APIRequestFactory()
        self.user = DummyOfficerUser()

    def _rows(self, hs_id):
        return sorted(HistorySheeterPreventiveAction.objects.filter(history_sheeter_id=hs_id)
                      .values_list('action_type', 'action_other'))

    def test_several_ticked_actions_become_one_row_each(self):
        req = self.factory.post('/api/history-sheeter/', {
            'hs_name': 'TEST Person',
            'hs_preventive_actions': [
                {'hs_preventive_action_type': ['MPDA', 'Externment', 'Other'],
                 'hs_preventive_action_other': 'TEST details'},
            ],
        }, format='json')
        force_authenticate(req, user=self.user)
        res = HistorySheeterListCreateView.as_view()(req)
        self.assertEqual(res.status_code, 201, res.data)
        self.assertEqual(self._rows(res.data['id']),
                         [('Externment', ''), ('MPDA', ''), ('Other', 'TEST details')])

    def test_edit_replaces_rows_and_accepts_single_values(self):
        req = self.factory.post('/api/history-sheeter/', {
            'hs_name': 'TEST Person',
            'hs_preventive_actions': [{'hs_preventive_action_type': ['MPDA', 'Externment']}],
        }, format='json')
        force_authenticate(req, user=self.user)
        hs_id = HistorySheeterListCreateView.as_view()(req).data['id']

        req = self.factory.patch(f'/api/history-sheeter/{hs_id}/', {
            'hs_preventive_actions': [{'hs_preventive_action_type': 'MPDA'},
                                      {'hs_preventive_action_type': '107 CrPC/126 BNSS, 55 MPA'}],
        }, format='json')
        force_authenticate(req, user=self.user)
        self.assertEqual(HistorySheeterDetailView.as_view()(req, pk=hs_id).status_code, 200)
        self.assertEqual([t for t, _ in self._rows(hs_id)], ['107 CrPC/126 BNSS', '55 MPA', 'MPDA'])
