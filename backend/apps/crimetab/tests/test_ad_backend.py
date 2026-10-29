import importlib

from django.apps import apps as django_apps
from django.core.cache import cache
from django.test import TestCase
from rest_framework import status
from rest_framework.test import APIRequestFactory, force_authenticate

from apps.cases.models import CaseRecord
from apps.crimetab.models import ModuleSetting
from apps.crimetab.models.groupings import CaseCategory
from apps.crimetab.views_ad import (
    AdConfigView,
    AdCountsView,
    AdDetailView,
    AdListCreateView,
    AdPdfView,
)

SUICIDE = 'STAND_AD_SUICIDE'
OTHER = 'STAND_AD_OTHER'


def _seed_ad_public_data():
    """Run the real data migrations so tests use exactly the seeded rows."""
    if not CaseCategory.objects.filter(category_code='STAND_AD').exists():
        CaseCategory.objects.create(category_name='A.D.', category_code='STAND_AD', display_order=40)
    for name in ('0121_ad_suicide_and_other_subtabs', '0125_ad_form_fields', '0126_ad_module_settings',
                 '0130_ad_disposal_rule_settings'):
        importlib.import_module(f'apps.crimetab.migrations.{name}').forwards(django_apps, None)


class DummyUser:
    def __init__(self, station='TEST_Station A', uid='TEST_uid_1'):
        self.uid = uid
        self.id = uid
        self.name = 'TEST Officer'
        self.email = 'test_ad@example.com'
        self.role_id = 'officer'
        self.station_name = station
        self.additional_stations = []
        self.station_id = 'TEST_st'
        self.state_code = 'MH'
        self.state_schema = 'public'
        self.is_anonymous = False
        self.is_authenticated = True


SDM_GRANTED = {'ad_sdm_granted': 'Yes', 'ad_sdm_granted_date': '15/10/2026'}


class AdBackendTests(TestCase):
    def setUp(self):
        cache.clear()
        _seed_ad_public_data()
        self.factory = APIRequestFactory()
        self.user = DummyUser()

    def _req(self, method, path, data=None, user=None, **params):
        fn = getattr(self.factory, method)
        if data is not None:
            query = '&'.join(f'{k}={v}' for k, v in params.items())
            req = fn(f'{path}?{query}' if query else path, data, format='json')
        else:
            req = fn(path, params)
        force_authenticate(req, user=user or self.user)
        return req

    def create(self, payload, category=SUICIDE, user=None):
        return AdListCreateView.as_view()(self._req('post', '/api/ad/', payload, user, category=category))

    def list(self, category=SUICIDE, user=None, **params):
        return AdListCreateView.as_view()(self._req('get', '/api/ad/', None, user, category=category, **params))

    def counts(self, category=SUICIDE, user=None):
        cache.clear()
        return AdCountsView.as_view()(self._req('get', '/api/ad/counts/', None, user, category=category)).data

    def patch(self, rid, payload):
        return AdDetailView.as_view()(self._req('patch', f'/api/ad/{rid}/', payload), pk=rid)

    def test_config_lists_the_sub_tabs_and_labels_from_settings(self):
        data = AdConfigView.as_view()(self._req('get', '/api/ad/config/')).data
        self.assertEqual([c['code'] for c in data['sub_categories']], [SUICIDE, OTHER])
        self.assertEqual(data['sub_tab_labels']['disposal'], 'Disposal')
        self.assertEqual(data['action_labels']['add'], 'Add A.D.')

    def test_create_lists_card_and_counts_per_sub_tab(self):
        res = self.create({'case_number': 'TEST_AD_1', 'ad_deceased_identity': 'Known',
                           'ad_deceased': [{'ad_deceased_name': 'TEST Ram', 'ad_deceased_age': '45'}, {}],
                           'ad_cause_of_death': 'Hanging'})
        self.assertEqual(res.status_code, status.HTTP_201_CREATED, res.data)
        rec = CaseRecord.objects.get(pk=res.data['id'])
        self.assertEqual((rec.module_key, rec.sub_category, rec.case_number), ('ad', 'Suicide', 'TEST_AD_1'))
        self.assertEqual(rec.extra_fields['ad_deceased'], [{'ad_deceased_name': 'TEST Ram', 'ad_deceased_age': '45'}])

        item = self.list().data['results'][0]
        cards = dict((r[0], r[1]) for r in item['card_rows'])
        self.assertEqual(cards['AD No.'], 'TEST_AD_1')
        self.assertEqual(cards['Deceased Name'], 'TEST Ram')
        self.assertEqual(cards['Cause of Death'], 'Hanging')
        self.assertEqual(self.counts(), {'total': 1, 'pending': 1, 'disposal': 0})
        self.assertEqual(self.counts(OTHER), {'total': 0, 'pending': 0, 'disposal': 0})

    def test_sdm_granted_yes_with_date_moves_to_disposal(self):
        rid = self.create({'case_number': 'TEST_AD_2'}).data['id']
        self.assertEqual(self.patch(rid, {'ad_sdm_granted': 'Yes'}).status_code, 200)
        self.assertEqual(self.counts()['disposal'], 0)
        self.assertEqual(self.patch(rid, SDM_GRANTED).status_code, 200)
        self.assertEqual(self.counts(), {'total': 1, 'pending': 0, 'disposal': 1})
        self.assertEqual([r['id'] for r in self.list(tab='disposal').data['results']], [rid])
        self.assertEqual(self.list(tab='pending').data['results'], [])
        self.assertEqual(self.list(tab='disposal').data['results'][0]['status_label'], 'Disposal')
        # Back to No: Pending again
        self.patch(rid, {'ad_sdm_granted': 'No'})
        self.assertEqual(self.counts()['pending'], 1)

    def test_hidden_answers_are_dropped(self):
        rid = self.create({'case_number': 'TEST_AD_3', 'ad_deceased_identity': 'Known',
                           'ad_unknown_injury': 'TEST cut', 'ad_postmortem': 'No',
                           'ad_postmortem_date': '01/10/2026'}).data['id']
        extra = CaseRecord.objects.get(pk=rid).extra_fields
        self.assertNotIn('ad_unknown_injury', extra)
        self.assertNotIn('ad_postmortem_date', extra)

    def test_panchanama_checkbox_keeps_its_date_time(self):
        rid = self.create({'ad_inquest_panchanama': True,
                           'ad_inquest_panchanama_date': '21/10/2026 10:30'}).data['id']
        det = AdDetailView.as_view()(self._req('get', f'/api/ad/{rid}/'), pk=rid).data
        self.assertEqual(det['form_data']['ad_inquest_panchanama_date'], '21/10/2026 10:30')
        self.assertIn('Yes (21/10/2026 10:30)', str(det['sections']))

    def test_validation_and_bad_requests(self):
        self.assertEqual(self.create({'ad_deceased_identity': 'Known',
                                      'ad_deceased': [{'ad_deceased_mobile': '12'}]}).status_code, 400)
        self.assertEqual(self.create({}).status_code, 400)
        self.assertEqual(self.create({'case_number': 'X'}, category='NOPE').status_code, 400)
        self.assertEqual(self.list(tab='bad').status_code, 400)

    def test_station_isolation(self):
        rid = self.create({'case_number': 'TEST_AD_4'}).data['id']
        other = DummyUser(station='TEST_Station B', uid='TEST_uid_2')
        self.assertEqual(self.counts(user=other)['total'], 0)
        res = AdDetailView.as_view()(self._req('get', f'/api/ad/{rid}/', user=other), pk=rid)
        self.assertEqual(res.status_code, 404)

    def test_view_masks_aadhaar_and_pdf_renders(self):
        rid = self.create({'case_number': 'TEST_AD_5', 'ad_deceased_identity': 'Known',
                           'ad_deceased': [{'ad_deceased_name': 'TEST', 'ad_deceased_aadhaar': '1234 5678 9012'}]}
                          ).data['id']
        det = AdDetailView.as_view()(self._req('get', f'/api/ad/{rid}/'), pk=rid).data
        self.assertEqual(det['category_code'], SUICIDE)
        self.assertIn('XXXXXXXX9012', str(det['sections']))
        self.assertNotIn('123456789012', str(det['sections']))
        pdf = AdPdfView.as_view()(self._req('get', f'/api/ad/{rid}/pdf/'), pk=rid)
        self.assertEqual(pdf.status_code, 200)
        self.assertEqual(pdf['Content-Type'], 'application/pdf')

    def test_card_layout_and_labels_follow_settings(self):
        ModuleSetting.objects.filter(module_key='ad', setting_key='list_card_fields').update(
            setting_value='ad_cause_of_death+ad_cause_of_death_other')
        ModuleSetting.objects.filter(module_key='ad', setting_key='tab_pending_label').update(
            setting_value='TEST_Open')
        self.create({'ad_cause_of_death': 'Other', 'ad_cause_of_death_other': 'TEST fall'})
        item = self.list().data['results'][0]
        self.assertEqual(item['card_rows'], [['Cause of Death / Other Cause (type)', 'Other\nTEST fall']])
        self.assertEqual(item['status_label'], 'TEST_Open')

    def test_search_and_keyset_pages(self):
        ModuleSetting.objects.filter(module_key='ad', setting_key='page_size').update(setting_value='2')
        ids = [self.create({'case_number': f'TEST_AD_P{i}'}).data['id'] for i in range(5)]
        seen, cursor = [], None
        while True:
            params = {'cursor': cursor} if cursor else {}
            page = self.list(**params).data
            seen += [r['id'] for r in page['results']]
            cursor = page['next_cursor']
            if not cursor:
                break
        self.assertEqual(sorted(seen), sorted(ids))
        self.assertEqual(len(seen), len(set(seen)))
        hits = self.list(q='TEST_AD_P3').data['results']
        self.assertEqual([r['case_number'] for r in hits], ['TEST_AD_P3'])
