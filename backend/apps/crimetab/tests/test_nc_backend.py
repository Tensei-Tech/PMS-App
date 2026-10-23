import importlib

from django.apps import apps as django_apps
from django.core.cache import cache
from django.db import connection
from django.test import TestCase
from django.test.utils import CaptureQueriesContext
from rest_framework import status
from rest_framework.test import APIRequestFactory, force_authenticate

from apps.crimetab.models import FieldTemplateField, ModuleSetting, OptionValue
from apps.crimetab.models.common_form import Act, ActSection
from apps.crimetab.models.nc import NcCharge, NcPerson, NcPreventiveAction, NcRecord
from apps.crimetab.services import nc_service as svc
from apps.crimetab.views_nc import (
    NcOfficersView,
    NcConfigView,
    NcCountsView,
    NcDetailView,
    NcListCreateView,
    NcPdfView,
)
from apps.crimetab.tests.state_schema import enter_state_schema

DATE_ONLY = '149 CrPC/168 BNSS'
OTHER = '107 CrPC/126 BNSS'


class _Editor:
    connection = connection


def _seed_nc_public_data():
    """Run the real data migrations so tests use exactly the seeded rows."""
    for name in ('0053_nc_public_data', '0058_nc_api_settings', '0059_nc_officer_and_designation_pickers',
                 '0090_nc_list_card_settings', '0092_nc_pending_definition_wording',
                 '0093_nc_preventive_rule_date_and_outward'):
        mod = importlib.import_module(f'apps.crimetab.migrations.{name}')
        seed = getattr(mod, 'seed_nc_public', None) or getattr(mod, 'seed', None) or mod.forwards
        seed(django_apps, _Editor())
    for idx, g in enumerate(['Male', 'Female', 'Other'], 1):
        OptionValue.objects.get_or_create(option_group='gender', option_value=g,
                                          defaults={'display_order': idx, 'is_active': True})


class DummyUser:
    def __init__(self, station='TEST_Station A', uid='TEST_uid_1', role='officer', extra=None):
        self.uid = uid
        self.id = uid
        self.name = 'TEST Officer'
        self.email = 'test_nc@example.com'
        self.role_id = role
        self.station_name = station
        self.additional_stations = extra or []
        self.station_id = 'TEST_st'
        self.state_code = 'MH'
        self.state_schema = 'public'
        self.is_anonymous = False
        self.is_authenticated = True


def prev_row(provision=None, date=None, outward=None, bond=None, cancel=None, person=None, number=None):
    return {
        'nc_prev_person': person or '', 'nc_prev_provision': provision or '',
        'nc_prev_date': date or '', 'nc_prev_outward_no': outward or '',
        'nc_prev_bond_date': bond or '', 'nc_prev_bond_cancel_date': cancel or '',
        'nc_prev_number': number or '',
    }


def full_other_row(**kw):
    return prev_row(OTHER, '01/10/2026', 'OUT-1', '02/10/2026', '03/10/2026', **kw)


class NcBackendTests(TestCase):
    def setUp(self):
        enter_state_schema(self)
        cache.clear()
        _seed_nc_public_data()
        self.factory = APIRequestFactory()
        self.user = DummyUser()

    # ── helpers ──
    def _req(self, method, path, data=None, user=None, **params):
        fn = getattr(self.factory, method)
        req = fn(path, data, format='json') if data is not None else fn(path, params)
        force_authenticate(req, user=user or self.user)
        return req

    def create(self, payload, user=None):
        res = NcListCreateView.as_view()(self._req('post', '/api/nc/', payload, user))
        return res

    def list(self, user=None, **params):
        req = self.factory.get('/api/nc/', params)
        force_authenticate(req, user=user or self.user)
        return NcListCreateView.as_view()(req)

    def counts(self, user=None):
        cache.clear()
        req = self.factory.get('/api/nc/counts/')
        force_authenticate(req, user=user or self.user)
        return NcCountsView.as_view()(req).data

    # ── status rule ──
    def _status_of(self, rows):
        res = self.create({'nc_no': 'TEST_1', 'nc_non_applicants': [{'nc_na_name': 'TEST_NA'}],
                           'nc_preventive_actions': rows})
        self.assertEqual(res.status_code, status.HTTP_201_CREATED, res.data)
        det = NcDetailView.as_view()(self._req('get', f'/api/nc/{res.data["id"]}/'), pk=res.data['id'])
        return det.data['is_disposal']

    def test_168_bnss_with_only_date_is_disposal(self):
        self.assertTrue(self._status_of([prev_row(DATE_ONLY, '01/10/2026')]))

    def test_168_bnss_without_date_is_pending(self):
        self.assertFalse(self._status_of([prev_row(DATE_ONLY)]))

    def test_other_provision_with_all_four_is_disposal(self):
        self.assertTrue(self._status_of([full_other_row()]))

    def test_other_provision_with_date_and_outward_is_disposal(self):
        # Bond Date and Bond Cancellation Date are no longer needed (0093)
        self.assertTrue(self._status_of([prev_row(OTHER, '01/10/2026', 'OUT-1')]))

    def test_other_provision_missing_outward_is_pending(self):
        self.assertFalse(self._status_of([prev_row(OTHER, '01/10/2026')]))

    def test_required_fields_are_a_setting(self):
        ModuleSetting.objects.filter(module_key='nc', setting_key='preventive_required_fields')             .update(setting_value='outward_number,bond_cancellation_date')
        self.assertFalse(self._status_of([prev_row(OTHER, '01/10/2026', 'OUT-1', '02/10/2026')]))
        self.assertTrue(self._status_of([full_other_row()]))

    def test_no_preventive_rows_is_pending(self):
        self.assertFalse(self._status_of([]))

    def test_several_rows_need_every_row_complete(self):
        self.assertTrue(self._status_of([prev_row(DATE_ONLY, '01/10/2026'), full_other_row()]))
        self.assertFalse(self._status_of([prev_row(DATE_ONLY, '01/10/2026'), prev_row(OTHER, '01/10/2026')]))

    def test_preventive_number_is_not_part_of_rule(self):
        self.assertTrue(self._status_of([prev_row(DATE_ONLY, '01/10/2026', number='')]))

    def test_date_only_provision_is_a_setting(self):
        ModuleSetting.objects.filter(module_key='nc', setting_key='date_only_provision').update(setting_value=OTHER)
        self.assertTrue(self._status_of([prev_row(OTHER, '01/10/2026')]))
        self.assertFalse(self._status_of([prev_row(DATE_ONLY, '01/10/2026')]))

    def test_counts_follow_an_edit_for_users_with_additional_stations(self):
        user = DummyUser(extra=['TEST_Station Extra'])
        rid = self.create({'nc_non_applicants': [{'nc_na_name': 'TEST_NA'}],
                           'nc_preventive_actions': [full_other_row()]}, user=user).data['id']

        def counts():  # no cache.clear(): the real cached path
            req = self.factory.get('/api/nc/counts/')
            force_authenticate(req, user=user)
            return NcCountsView.as_view()(req).data
        self.assertEqual(counts()['disposal'], 1)
        # Edit removes the Outward Number -> the row is incomplete -> Pending
        row = full_other_row()
        row['nc_prev_outward_no'] = ''
        res = NcDetailView.as_view()(self._req('patch', f'/api/nc/{rid}/', {'nc_preventive_actions': [row]}, user),
                                     pk=rid)
        self.assertEqual(res.status_code, 200)
        self.assertEqual(counts(), {'total': 1, 'pending': 1, 'disposal': 0})

    def test_total_is_pending_plus_disposal_and_list_tabs_agree(self):
        self._status_of([prev_row(DATE_ONLY, '01/10/2026')])
        self._status_of([prev_row(DATE_ONLY)])
        self._status_of([])
        c = self.counts()
        self.assertEqual(c, {'total': 3, 'pending': 2, 'disposal': 1})
        self.assertEqual(c['total'], c['pending'] + c['disposal'])
        for tab in ('total', 'pending', 'disposal'):
            self.assertEqual(len(self.list(tab=tab).data['results']), c[tab])

    # ── validation ──
    def test_empty_request_rejected(self):
        res = self.create({'nc_no': '', 'nc_complainants': [{'nc_cmp_name': ''}]})
        self.assertEqual(res.status_code, 400)
        self.assertEqual(res.data['error'], ModuleSetting.objects.get(module_key='nc', setting_key='empty_request_message').setting_value)
        self.assertEqual(NcRecord.objects.count(), 0)

    def test_preventive_person_must_be_non_applicant(self):
        res = self.create({'nc_complainants': [{'nc_cmp_name': 'TEST_C'}],
                           'nc_non_applicants': [{'nc_na_name': 'TEST_NA'}],
                           'nc_preventive_actions': [prev_row(DATE_ONLY, '01/10/2026', person='TEST_C')]})
        self.assertEqual(res.status_code, 400)
        self.assertEqual(NcRecord.objects.count(), 0)

        ok = self.create({'nc_non_applicants': [{'nc_na_name': 'TEST_NA'}],
                          'nc_preventive_actions': [prev_row(DATE_ONLY, '01/10/2026', person='TEST_NA')]})
        self.assertEqual(ok.status_code, 201)
        row = NcPreventiveAction.objects.get(nc_id=ok.data['id'])
        self.assertEqual(row.person.person_type, svc.PERSON_TYPE_NON_APPLICANT)

    def test_preventive_row_without_person_is_allowed(self):
        self.assertEqual(self.create({'nc_preventive_actions': [prev_row(DATE_ONLY, '01/10/2026')]}).status_code, 201)

    def test_preventive_outward_date_is_saved_and_returned(self):
        row = prev_row(DATE_ONLY, '01/10/2026', outward='OUT-1')
        row['nc_prev_outward_date'] = '04/10/2026'
        res = self.create({'nc_preventive_actions': [row]})
        self.assertEqual(res.status_code, 201, res.data)
        saved = NcPreventiveAction.objects.get(nc_id=res.data['id'])
        self.assertEqual(str(saved.outward_date), '2026-10-04')
        det = NcDetailView.as_view()(self._req('get', f'/api/nc/{res.data["id"]}/'), pk=res.data['id'])
        self.assertIn('04/10/2026', str(det.data))

    def test_field_rules(self):
        bad = [
            {'nc_complainants': [{'nc_cmp_name': 'TEST', 'nc_cmp_age': '0'}]},
            {'nc_complainants': [{'nc_cmp_name': 'TEST', 'nc_cmp_age': '121'}]},
            {'nc_complainants': [{'nc_cmp_name': 'TEST', 'nc_cmp_mobile': '12345'}]},
            {'nc_complainants': [{'nc_cmp_name': 'TEST', 'nc_cmp_aadhaar': '1234'}]},
            {'nc_complainants': [{'nc_cmp_name': 'TEST', 'nc_cmp_gender': 'TEST_Unknown'}]},
            {'nc_io_mobile': '98765'},
            {'nc_first_information': 'x' * 51},
            {'nc_registered_date': '31/02/2026'},
            {'nc_preventive_actions': [prev_row('TEST_Not a provision', '01/10/2026')]},
        ]
        for payload in bad:
            self.assertEqual(self.create(payload).status_code, 400, payload)
        good = {'nc_first_information': 'x' * 50, 'nc_io_mobile': '9876543210',
                'nc_complainants': [{'nc_cmp_name': 'TEST', 'nc_cmp_age': '120', 'nc_cmp_mobile': '9876543210',
                                     'nc_cmp_aadhaar': '123456789012', 'nc_cmp_gender': 'Female'}]}
        self.assertEqual(self.create(good).status_code, 201)

    def test_post_nc_fields_cleared_unless_yes(self):
        res = self.create({'nc_no': 'TEST', 'nc_post_crime_registered': 'No', 'nc_post_crime_no': 'TEST_99'})
        self.assertIsNone(NcRecord.objects.get(pk=res.data['id']).post_crime_no)
        res = self.create({'nc_no': 'TEST', 'nc_post_crime_registered': 'Yes', 'nc_post_crime_no': 'TEST_99'})
        self.assertEqual(NcRecord.objects.get(pk=res.data['id']).post_crime_no, 'TEST_99')

    # ── charges survive Acts replacement ──
    def test_charges_are_text_copies(self):
        act = Act.objects.create(act_name='TEST_Act')
        sec = ActSection.objects.create(act=act, section_number='TEST_1', section_title='TEST title')
        res = self.create({'nc_charges': [{'act_id': act.pk, 'act_name': 'TEST_Act', 'section_id': sec.pk,
                                           'section_number': 'TEST_1', 'section_title': 'TEST title'}]})
        self.assertEqual(res.status_code, 201)
        ActSection.objects.all().delete()
        Act.objects.all().delete()
        charge = NcCharge.objects.get(nc_id=res.data['id'])
        self.assertEqual((charge.act_name, charge.section_number, charge.section_title),
                         ('TEST_Act', 'TEST_1', 'TEST title'))

    # ── isolation and auth ──
    def test_station_isolation(self):
        other = DummyUser(station='TEST_Station B', uid='TEST_uid_2')
        mine = self.create({'nc_no': 'TEST_A'}).data['id']
        self.create({'nc_no': 'TEST_B'}, user=other)
        self.assertEqual([r['nc_no'] for r in self.list().data['results']], ['TEST_A'])
        res = NcDetailView.as_view()(self._req('get', f'/api/nc/{mine}/', user=other), pk=mine)
        self.assertEqual(res.status_code, 404)
        self.assertEqual(self.counts(user=other)['total'], 1)

    def test_401_without_user(self):
        req = self.factory.get('/api/nc/')
        self.assertEqual(NcListCreateView.as_view()(req).status_code, 401)

    def test_403_when_permissions_enforced(self):
        ModuleSetting.objects.filter(module_key='nc', setting_key='enforce_permissions').update(setting_value='true')
        self.assertEqual(self.list().status_code, 403)
        self.assertEqual(self.create({'nc_no': 'TEST'}).status_code, 403)

    def test_no_station_returns_400(self):
        self.assertEqual(self.list(user=DummyUser(station='')).status_code, 400)

    # ── edit ──
    def test_patch_validates_merged_state_and_replaces_children(self):
        rid = self.create({'nc_no': 'TEST', 'nc_complainants': [{'nc_cmp_name': 'TEST_C1'}]}).data['id']
        res = NcDetailView.as_view()(self._req('patch', f'/api/nc/{rid}/', {'nc_io_mobile': '12'}), pk=rid)
        self.assertEqual(res.status_code, 400)
        res = NcDetailView.as_view()(self._req('patch', f'/api/nc/{rid}/',
                                               {'nc_complainants': [{'nc_cmp_name': 'TEST_C2'}]}), pk=rid)
        self.assertEqual(res.status_code, 200)
        self.assertEqual(list(NcPerson.objects.filter(nc_id=rid).values_list('name', flat=True)), ['TEST_C2'])
        self.assertEqual(NcRecord.objects.get(pk=rid).nc_no, 'TEST')

    # ── view / pdf ──
    def test_view_masks_aadhaar_and_pdf_renders(self):
        rid = self.create({'nc_no': 'TEST', 'nc_complainants': [{'nc_cmp_name': 'TEST', 'nc_cmp_aadhaar': '123456789012'}]}).data['id']
        det = NcDetailView.as_view()(self._req('get', f'/api/nc/{rid}/'), pk=rid).data
        flat = str(det['sections'])
        self.assertIn('XXXXXXXX9012', flat)
        self.assertNotIn('123456789012', flat)
        pdf = NcPdfView.as_view()(self._req('get', f'/api/nc/{rid}/pdf/'), pk=rid)
        self.assertEqual(pdf.status_code, 200)
        self.assertEqual(pdf['Content-Type'], 'application/pdf')

    # ── data-driven: settings, options and labels change without code ──
    def test_settings_option_and_label_changes_are_followed(self):
        ModuleSetting.objects.filter(module_key='nc', setting_key='tab_pending_label').update(setting_value='TEST_Open')
        cfg = NcConfigView.as_view()(self._req('get', '/api/nc/config/')).data
        self.assertEqual(cfg['sub_tab_labels']['pending'], 'TEST_Open')

        OptionValue.objects.create(option_group='nc_preventive_provisions', option_value='TEST_Provision', display_order=999)
        self.assertEqual(self.create({'nc_preventive_actions': [prev_row('TEST_Provision', '01/10/2026')]}).status_code, 201)

        FieldTemplateField.objects.filter(field_key='nc_no').update(field_label='TEST NC Number')
        rid = self.create({'nc_no': 'TEST'}).data['id']
        det = NcDetailView.as_view()(self._req('get', f'/api/nc/{rid}/'), pk=rid).data
        self.assertIn('TEST NC Number', str(det['sections']))

        ModuleSetting.objects.filter(module_key='nc', setting_key='first_information_max_length').update(setting_value='5')
        self.assertEqual(self.create({'nc_first_information': 'TEST_long'}).status_code, 400)

    # ── keyset pagination ──
    def test_keyset_pagination_walks_all_rows_once(self):
        ModuleSetting.objects.filter(module_key='nc', setting_key='page_size').update(setting_value='2')
        for i, d in enumerate(['01/10/2026', '01/10/2026', '', '05/10/2026', '']):
            self.create({'nc_no': f'TEST_{i}', 'nc_registered_date': d})
        seen, cursor = [], None
        while True:
            params = {'cursor': cursor} if cursor else {}
            data = self.list(**params).data
            seen += [r['nc_no'] for r in data['results']]
            cursor = data['next_cursor']
            if not cursor:
                break
        self.assertEqual(len(seen), 5)
        self.assertEqual(len(set(seen)), 5)
        self.assertEqual(seen[0], 'TEST_3')  # newest registered date first, NULL dates last

    # ── list card ──
    def test_list_card_shows_requested_fields_and_every_preventive_row(self):
        self.create({
            'nc_no': 'TEST_NC_7',
            'nc_registered_date': '05/10/2026',
            'nc_charges': [{'act_name': 'TEST Act', 'section_number': '117'}],
            'nc_complainants': [{'nc_cmp_name': 'TEST_C1'}, {'nc_cmp_name': 'TEST_C2'}],
            'nc_non_applicants': [{'nc_na_name': 'TEST_NA'}],
            'nc_io_name': 'TEST IO',
            'nc_preventive_actions': [
                prev_row(DATE_ONLY, '01/10/2026', number='P-1'),
                prev_row(OTHER, '02/10/2026', 'OUT-9', '03/10/2026', '04/10/2026'),
            ],
        })
        item = self.list().data['results'][0]
        rows = dict((label, value) for label, value in item['card_rows'])
        self.assertEqual(rows['NC No.'], 'TEST_NC_7')
        self.assertEqual(rows['Complainant'], 'TEST_C1, TEST_C2')
        self.assertEqual(rows['Non Applicant'], 'TEST_NA')
        # Act and Section share one box; Registered Date is not on the card
        self.assertIn('TEST Act 117', rows.values())
        self.assertNotIn('Registered Date', rows)
        self.assertIn('TEST IO', [v for _, v in item['card_rows']])
        self.assertEqual(len(item['preventive_rows']), 2)
        first = dict((label, value) for label, value in item['preventive_rows'][0])
        self.assertIn('P-1', [v for v in first.values()][0])  # Preventive / Number box
        second = dict((label, value) for label, value in item['preventive_rows'][1])
        # Outward No. and Date share one box; Bond Cancellation Date is not shown
        self.assertEqual(second['Outward Number / Date'], 'OUT-9\n02/10/2026')
        self.assertNotIn('Bond Cancellation Date', second)
        self.assertEqual(len(second), 3)

    def test_config_has_pending_definition_with_date_only_provision(self):
        req = self.factory.get('/api/nc/config/')
        force_authenticate(req, user=self.user)
        data = NcConfigView.as_view()(req).data
        self.assertIn(DATE_ONLY, data['pending_definition'])
        self.assertTrue(data['serial_label'])

    # ── constant query count ──
    def test_list_query_count_is_constant(self):
        def run():
            with CaptureQueriesContext(connection) as ctx:
                self.assertEqual(self.list().status_code, 200)
            return len(ctx.captured_queries)

        payload = {'nc_complainants': [{'nc_cmp_name': 'TEST'}], 'nc_non_applicants': [{'nc_na_name': 'TEST_NA'}],
                   'nc_charges': [{'act_name': 'TEST'}],
                   'nc_preventive_actions': [prev_row(DATE_ONLY, '01/10/2026', person='TEST_NA')]}
        self.create(payload)
        one = run()
        for _ in range(15):
            self.create(payload)
        self.assertEqual(run(), one)

    def test_detail_and_counts_query_count_is_constant(self):
        payload = {'nc_complainants': [{'nc_cmp_name': f'TEST_{i}'} for i in range(10)],
                   'nc_preventive_actions': [prev_row(DATE_ONLY, '01/10/2026') for _ in range(10)]}
        small = self.create({'nc_no': 'TEST'}).data['id']
        big = self.create(payload).data['id']

        def q(pk):
            with CaptureQueriesContext(connection) as ctx:
                NcDetailView.as_view()(self._req('get', f'/api/nc/{pk}/'), pk=pk)
            return len(ctx.captured_queries)
        self.assertEqual(q(small), q(big))


class NcOfficerAndDesignationTests(TestCase):
    def setUp(self):
        enter_state_schema(self)
        cache.clear()
        _seed_nc_public_data()
        from apps.public_master.models import Designation
        from apps.users.models import OfficerProfile
        Designation.objects.create(code='TEST_PI', title='TEST Police Inspector',
                                   display_name='TEST Police Inspector (PI)', rank_level=5, is_active=True)
        for uid, name, station, st in [
            ('TEST_o1', 'TEST Officer One', 'TEST_Station A', 'active'),
            ('TEST_o2', 'TEST Officer Two', '  test_station a ', 'active'),
            ('TEST_o3', 'TEST Other Station', 'TEST_Station B', 'active'),
            ('TEST_o4', 'TEST Inactive', 'TEST_Station A', 'suspended'),
        ]:
            OfficerProfile.objects.create(uid=uid, email=f'{uid}@example.com', name=name, designation='PI',
                                          station_name=station, account_status=st, role_id='officer')
        self.factory = APIRequestFactory()
        self.user = DummyUser()

    def test_officers_are_active_officers_of_the_users_station(self):
        req = self.factory.get('/api/nc/officers/')
        force_authenticate(req, user=self.user)
        res = NcOfficersView.as_view()(req)
        self.assertEqual(res.status_code, 200)
        self.assertEqual([o['label'] for o in res.data], ['TEST Officer One', 'TEST Officer Two'])

    def test_designation_must_come_from_designations_master(self):
        def post(desig):
            req = self.factory.post('/api/nc/', {'nc_io_name': 'TEST Officer One', 'nc_io_designation': desig},
                                    format='json')
            force_authenticate(req, user=self.user)
            return NcListCreateView.as_view()(req)
        self.assertEqual(post('TEST Police Inspector (PI)').status_code, 201)
        self.assertEqual(post('TEST Not a designation').status_code, 400)
