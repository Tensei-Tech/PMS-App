import datetime
from django.db import connection
from django.test import TestCase
from django.core.cache import cache
from rest_framework.test import APIRequestFactory, force_authenticate
from rest_framework import status

from apps.core.models import AuditLog
from apps.users.models import OfficerProfile
from apps.crimetab.models import (
    ModuleSetting,
    OptionValue,
    CaseCategory,
    FieldTemplate,
    CategoryFieldTemplate,
    FieldTemplateField,
)
from apps.crimetab.models.history_sheeter import (
    HistorySheeter,
    HistorySheeterRelatedPerson,
    HistorySheeterPreventiveAction,
    HistorySheeterCrime,
)
from apps.crimetab.views_history_sheeter import (
    HistorySheeterConfigView,
    HistorySheeterCountsView,
    HistorySheeterListCreateView,
    HistorySheeterDetailView,
    HistorySheeterPDFView,
    _get_active_cutoff_date,
)


class DummyOfficerUser:
    def __init__(self, station_name="Cyber Police Station", uid="off_hs_1"):
        self.uid = uid
        self.id = uid
        self.name = "Inspector HS Test"
        self.email = "hs_test@example.com"
        self.role_id = "officer"
        self.station_name = station_name
        self.station_id = "st_cyber"
        self.state_code = "MH"
        self.state_schema = "public"
        self.is_anonymous = False
        self.is_authenticated = True


class HistorySheeterBackendTestCase(TestCase):
    def setUp(self):
        cache.clear()
        self.factory = APIRequestFactory()
        self.user = DummyOfficerUser()

        # Seed module settings
        ModuleSetting.objects.update_or_create(module_key='history_sheeter', setting_key='target_category_code', defaults={'setting_value': 'STAND_HISTORY_SHEETER'})
        ModuleSetting.objects.update_or_create(module_key='history_sheeter', setting_key='enforce_permissions', defaults={'setting_value': 'false'})
        ModuleSetting.objects.update_or_create(module_key='history_sheeter', setting_key='word_limit_modus_operandi', defaults={'setting_value': '25'})
        ModuleSetting.objects.update_or_create(module_key='history_sheeter', setting_key='word_limit_whereabouts', defaults={'setting_value': '25'})
        ModuleSetting.objects.update_or_create(module_key='history_sheeter', setting_key='max_serial_retries', defaults={'setting_value': '5'})
        ModuleSetting.objects.update_or_create(module_key='history_sheeter', setting_key='empty_request_message', defaults={'setting_value': 'Cannot save empty record. At least one field must be filled.'})
        ModuleSetting.objects.update_or_create(module_key='history_sheeter', setting_key='tab_active_label', defaults={'setting_value': 'Active History Sheeter'})
        ModuleSetting.objects.update_or_create(module_key='history_sheeter', setting_key='tab_open_label', defaults={'setting_value': 'History Sheet Open'})
        ModuleSetting.objects.update_or_create(module_key='history_sheeter', setting_key='tab_closed_label', defaults={'setting_value': 'History Sheet Closed'})
        ModuleSetting.objects.update_or_create(module_key='history_sheeter', setting_key='btn_edit_label', defaults={'setting_value': 'Edit'})
        ModuleSetting.objects.update_or_create(module_key='history_sheeter', setting_key='btn_view_label', defaults={'setting_value': 'View'})
        ModuleSetting.objects.update_or_create(module_key='history_sheeter', setting_key='btn_pdf_label', defaults={'setting_value': 'PDF'})
        ModuleSetting.objects.update_or_create(module_key='history_sheeter', setting_key='date_format', defaults={'setting_value': '%d/%m/%Y'})
        ModuleSetting.objects.update_or_create(module_key='history_sheeter', setting_key='template_name', defaults={'setting_value': 'History Sheeter Template'})
        ModuleSetting.objects.update_or_create(module_key='history_sheeter', setting_key='pdf_subtitle', defaults={'setting_value': 'History Sheeter Docket'})
        ModuleSetting.objects.update_or_create(module_key='history_sheeter', setting_key='pdf_filename_prefix', defaults={'setting_value': 'HistorySheeter'})
        ModuleSetting.objects.update_or_create(module_key='history_sheeter', setting_key='pdf_department_suffix', defaults={'setting_value': 'DEPARTMENT'})
        ModuleSetting.objects.update_or_create(module_key='history_sheeter', setting_key='pdf_police_department_suffix', defaults={'setting_value': 'POLICE DEPARTMENT'})
        ModuleSetting.objects.update_or_create(module_key='history_sheeter', setting_key='pdf_fallback_title', defaults={'setting_value': 'POLICE DEPARTMENT'})
        ModuleSetting.objects.update_or_create(module_key='history_sheeter', setting_key='missing_state_message', defaults={'setting_value': 'State code could not be resolved from authenticated user credentials.'})
        ModuleSetting.objects.update_or_create(
            module_key='history_sheeter',
            setting_key='copy_on_tick_rules',
            defaults={
                'setting_value': '[{"trigger_field": "hs_same_as_above", "source_field": "hs_permanent_address", "target_field": "hs_present_address"}]'
            }
        )

        # Seed template & fields
        tmpl, _ = FieldTemplate.objects.get_or_create(template_name='History Sheeter Template')
        FieldTemplateField.objects.get_or_create(
            template=tmpl, field_key='hs_name',
            defaults={'field_label': 'Name', 'field_source': 'custom', 'field_type': 'text', 'display_order': 10}
        )
        FieldTemplateField.objects.get_or_create(
            template=tmpl, field_key='hs_alias',
            defaults={'field_label': 'Alias', 'field_source': 'custom', 'field_type': 'text', 'display_order': 20}
        )

    def test_config_endpoint_returns_database_settings(self):
        req = self.factory.get('/api/history-sheeter/config/')
        force_authenticate(req, user=self.user)
        view = HistorySheeterConfigView.as_view()
        res = view(req)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['target_category_code'], 'STAND_HISTORY_SHEETER')
        self.assertEqual(res.data['sub_tab_labels']['active'], 'Active History Sheeter')
        self.assertEqual(res.data['max_serial_retries'], 5)
        self.assertEqual(res.data['word_limits']['modus_operandi'], 25)
        self.assertIn('copy_on_tick_rules', res.data)
        self.assertEqual(len(res.data['copy_on_tick_rules']), 1)
        self.assertEqual(res.data['copy_on_tick_rules'][0]['trigger_field'], 'hs_same_as_above')

    def test_copy_on_tick_setting_change_updates_api_without_code_change(self):
        ModuleSetting.objects.filter(
            module_key='history_sheeter',
            setting_key='copy_on_tick_rules'
        ).update(setting_value='[{"trigger_field": "custom_tick", "source_field": "custom_src", "target_field": "custom_tgt"}]')

        req = self.factory.get('/api/history-sheeter/config/')
        force_authenticate(req, user=self.user)
        view = HistorySheeterConfigView.as_view()
        res = view(req)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data['copy_on_tick_rules']), 1)
        self.assertEqual(res.data['copy_on_tick_rules'][0]['trigger_field'], 'custom_tick')
        self.assertEqual(res.data['copy_on_tick_rules'][0]['source_field'], 'custom_src')
        self.assertEqual(res.data['copy_on_tick_rules'][0]['target_field'], 'custom_tgt')

    def test_empty_request_rejected(self):
        req = self.factory.post('/api/history-sheeter/', {}, format='json')
        force_authenticate(req, user=self.user)
        view = HistorySheeterListCreateView.as_view()
        res = view(req)
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('Cannot save empty record', res.data['error'])

    def test_word_limit_validation(self):
        long_mo = "word " * 30  # 30 words > limit 25
        req = self.factory.post('/api/history-sheeter/', {'hs_name': 'Test Suspect', 'hs_modus_operandi': long_mo}, format='json')
        force_authenticate(req, user=self.user)
        view = HistorySheeterListCreateView.as_view()
        res = view(req)
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('word limit', res.data['error'])

    def test_create_and_serial_numbering_per_station(self):
        payload1 = {
            'hs_name': 'Ganesh',
            'hs_alias': 'Ganya',
            'hs_category_type': ['Body Offender', 'Property Offender'],
            'hs_associates': [{'hs_assoc_name': 'Ramesh', 'hs_assoc_age': 28}],
            'hs_preventive_actions': [{'hs_preventive_action_type': 'MPDA'}],
            'hs_crime_chart': [{'hs_crime_cr_no': '12/2025', 'hs_crime_police_station': 'Cyber PS'}]
        }
        req1 = self.factory.post('/api/history-sheeter/', payload1, format='json')
        force_authenticate(req1, user=self.user)
        res1 = HistorySheeterListCreateView.as_view()(req1)
        self.assertEqual(res1.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res1.data['sr_no'], 1)
        self.assertEqual(len(res1.data['related_persons']), 1)
        self.assertEqual(len(res1.data['preventive_actions']), 1)
        self.assertEqual(len(res1.data['crimes']), 1)

        payload2 = {'hs_name': 'Suresh', 'hs_alias': 'Surya'}
        req2 = self.factory.post('/api/history-sheeter/', payload2, format='json')
        force_authenticate(req2, user=self.user)
        res2 = HistorySheeterListCreateView.as_view()(req2)
        self.assertEqual(res2.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res2.data['sr_no'], 2)

        # Different station starts at 1
        other_user = DummyOfficerUser(station_name="City Police Station", uid="off_hs_2")
        req3 = self.factory.post('/api/history-sheeter/', {'hs_name': 'Mahesh'}, format='json')
        force_authenticate(req3, user=other_user)
        res3 = HistorySheeterListCreateView.as_view()(req3)
        self.assertEqual(res3.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res3.data['sr_no'], 1)

    def test_counts_and_boundary_crime_within_12_months(self):
        if connection.vendor != 'postgresql':
            self.skipTest("Requires PostgreSQL for native calendar date arithmetic and tenant schema queries.")
        today = datetime.date.today()
        cutoff_12m = _get_active_cutoff_date()
        # 1. Open with crime registered 100 days ago (Active)
        hs1 = HistorySheeter.objects.create(station_name=self.user.station_name, sr_no=1, name="Person 1")
        HistorySheeterCrime.objects.create(history_sheeter=hs1, register_date=today - datetime.timedelta(days=100))

        # 2. Open with crime registered on exact 12-month boundary day (Active Boundary)
        hs2 = HistorySheeter.objects.create(station_name=self.user.station_name, sr_no=2, name="Person 2")
        HistorySheeterCrime.objects.create(history_sheeter=hs2, register_date=cutoff_12m)

        # 3. Open with crime registered 1 day prior to 12-month boundary (Open only, NOT Active)
        hs3 = HistorySheeter.objects.create(station_name=self.user.station_name, sr_no=3, name="Person 3")
        HistorySheeterCrime.objects.create(history_sheeter=hs3, register_date=cutoff_12m - datetime.timedelta(days=1))

        # 4. Closed sheet (Closed)
        HistorySheeter.objects.create(station_name=self.user.station_name, sr_no=4, name="Person 4", closure_date=today)

        req = self.factory.get('/api/history-sheeter/counts/')
        force_authenticate(req, user=self.user)
        res = HistorySheeterCountsView.as_view()(req)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['active'], 2)  # hs1 and hs2
        self.assertEqual(res.data['open'], 4)    # all opened (created) this year, incl. closed hs4
        self.assertEqual(res.data['closed'], 1)  # hs4 closed this year
        self.assertEqual(res.data['total'], 4)

        # Tab lists boundary verification:
        # 1. tab=active includes hs1 and hs2 (exact 12-month boundary), excludes hs3 and hs4
        req_act = self.factory.get('/api/history-sheeter/?tab=active')
        force_authenticate(req_act, user=self.user)
        res_act = HistorySheeterListCreateView.as_view()(req_act)
        names_act = [r['name'] for r in res_act.data['results']]
        self.assertEqual(res_act.data['count'], 2)
        self.assertIn("Person 1", names_act)
        self.assertIn("Person 2", names_act)
        self.assertNotIn("Person 3", names_act)
        self.assertNotIn("Person 4", names_act)

        # 2. tab=open lists every sheet opened in the current year
        req_open = self.factory.get('/api/history-sheeter/?tab=open')
        force_authenticate(req_open, user=self.user)
        res_open = HistorySheeterListCreateView.as_view()(req_open)
        self.assertEqual(res_open.data['count'], 4)

        # 3. tab=closed includes hs4 only
        req_cls = self.factory.get('/api/history-sheeter/?tab=closed')
        force_authenticate(req_cls, user=self.user)
        res_cls = HistorySheeterListCreateView.as_view()(req_cls)
        names_cls = [r['name'] for r in res_cls.data['results']]
        self.assertEqual(res_cls.data['count'], 1)
        self.assertIn("Person 4", names_cls)
        self.assertNotIn("Person 1", names_cls)
        self.assertNotIn("Person 2", names_cls)
        self.assertNotIn("Person 3", names_cls)

    def test_counts_distinct_with_multiple_crimes_and_zero_crimes(self):
        """
        User Requirement:
        The History Sheeter aggregate joins crimes. Confirm distinct=True ensures:
        a sheeter with 3 crimes counts once, and a sheeter with no crimes counts once.
        """
        # Sheeter 1 (Open): Has 3 crimes
        hs1 = HistorySheeter.objects.create(station_name=self.user.station_name, sr_no=1, name="Triple Crime Suspect")
        HistorySheeterCrime.objects.create(history_sheeter=hs1, cr_no="CR1/2026")
        HistorySheeterCrime.objects.create(history_sheeter=hs1, cr_no="CR2/2026")
        HistorySheeterCrime.objects.create(history_sheeter=hs1, cr_no="CR3/2026")

        # Sheeter 2 (Open): Has 0 crimes
        hs2 = HistorySheeter.objects.create(station_name=self.user.station_name, sr_no=2, name="Zero Crime Suspect")

        # Sheeter 3 (Closed): Has 3 crimes
        today = datetime.date.today()
        hs3 = HistorySheeter.objects.create(station_name=self.user.station_name, sr_no=3, name="Closed Triple Crime", closure_date=today)
        HistorySheeterCrime.objects.create(history_sheeter=hs3, cr_no="CR4/2026")
        HistorySheeterCrime.objects.create(history_sheeter=hs3, cr_no="CR5/2026")
        HistorySheeterCrime.objects.create(history_sheeter=hs3, cr_no="CR6/2026")

        # Sheeter 4 (Closed): Has 0 crimes
        hs4 = HistorySheeter.objects.create(station_name=self.user.station_name, sr_no=4, name="Closed Zero Crime", closure_date=today)

        req = self.factory.get('/api/history-sheeter/counts/')
        force_authenticate(req, user=self.user)
        res = HistorySheeterCountsView.as_view()(req)
        self.assertEqual(res.status_code, status.HTTP_200_OK)

        # All 4 were opened (created) this year; each counts once despite its crimes
        self.assertEqual(res.data['open'], 4)
        self.assertEqual(res.data['total'], 4)
        # hs3 (3 crimes) + hs4 (0 crimes) = exactly 2 closed this year
        self.assertEqual(res.data['closed'], 2)

    def test_year_jail_bail_and_total_tabs(self):
        from apps.crimetab.models import OptionValue
        OptionValue.objects.get_or_create(option_group='yes_no', option_value='Yes',
                                          defaults={'display_order': 10, 'is_active': True})
        OptionValue.objects.get_or_create(option_group='yes_no', option_value='No',
                                          defaults={'display_order': 20, 'is_active': True})
        today = datetime.date.today()
        last_year = today.replace(year=today.year - 1, month=6, day=1)
        st = self.user.station_name
        HistorySheeter.objects.create(station_name=st, sr_no=1, name="Opened This Year", opening_date=today)
        HistorySheeter.objects.create(station_name=st, sr_no=2, name="Opened Last Year", opening_date=last_year)
        HistorySheeter.objects.create(station_name=st, sr_no=3, name="Closed This Year",
                                      opening_date=last_year, closure_date=today)
        HistorySheeter.objects.create(station_name=st, sr_no=4, name="Closed Last Year",
                                      opening_date=last_year, closure_date=last_year)
        HistorySheeter.objects.create(station_name=st, sr_no=5, name="In Jail", opening_date=last_year,
                                      currently_in_jail='Yes', currently_on_bail='No')
        HistorySheeter.objects.create(station_name=st, sr_no=6, name="On Bail", opening_date=last_year,
                                      currently_in_jail='No', currently_on_bail='Yes')
        HistorySheeter.objects.create(station_name="Other Station", sr_no=1, name="Other", opening_date=today,
                                      currently_in_jail='Yes')
        cache.clear()

        req = self.factory.get('/api/history-sheeter/counts/')
        force_authenticate(req, user=self.user)
        counts = HistorySheeterCountsView.as_view()(req).data
        self.assertEqual(counts['total'], 6)
        self.assertEqual(counts['open'], 1)
        self.assertEqual(counts['closed'], 1)
        self.assertEqual(counts['jail'], 1)
        self.assertEqual(counts['bail'], 1)

        def names(tab):
            r = self.factory.get(f'/api/history-sheeter/?tab={tab}')
            force_authenticate(r, user=self.user)
            return [x['name'] for x in HistorySheeterListCreateView.as_view()(r).data['results']]
        self.assertEqual(names('open'), ['Opened This Year'])
        self.assertEqual(names('closed'), ['Closed This Year'])
        self.assertEqual(names('jail'), ['In Jail'])
        self.assertEqual(names('bail'), ['On Bail'])
        self.assertEqual(len(names('total')), 6)
        for tab in ('total', 'open', 'closed', 'jail', 'bail'):
            self.assertEqual(len(names(tab)), counts[tab])

    def test_list_filter_by_tab_and_category(self):
        if connection.vendor != 'postgresql':
            self.skipTest("Requires PostgreSQL for native text[] array containment (@>) queries.")
        today = datetime.date.today()
        hs1 = HistorySheeter.objects.create(station_name=self.user.station_name, sr_no=1, name="Akash Gupta", alias="Akki", categories=['Body Offender'])
        HistorySheeterCrime.objects.create(history_sheeter=hs1, register_date=today - datetime.timedelta(days=50))

        HistorySheeter.objects.create(station_name=self.user.station_name, sr_no=2, name="Deepak Patil", closure_date=today, categories=['Narcotics / NDPS'])

        # Filter tab=active
        req_act = self.factory.get('/api/history-sheeter/?tab=active')
        force_authenticate(req_act, user=self.user)
        res_act = HistorySheeterListCreateView.as_view()(req_act)
        self.assertEqual(res_act.data['count'], 1)
        self.assertEqual(res_act.data['results'][0]['name'], 'Akash Gupta')

        # Filter tab=closed
        req_cls = self.factory.get('/api/history-sheeter/?tab=closed')
        force_authenticate(req_cls, user=self.user)
        res_cls = HistorySheeterListCreateView.as_view()(req_cls)
        self.assertEqual(res_cls.data['count'], 1)
        self.assertEqual(res_cls.data['results'][0]['name'], 'Deepak Patil')

        # Filter by category
        req_cat = self.factory.get('/api/history-sheeter/?category=Body Offender')
        force_authenticate(req_cat, user=self.user)
        res_cat = HistorySheeterListCreateView.as_view()(req_cat)
        self.assertEqual(res_cat.data['count'], 1)
        self.assertEqual(res_cat.data['results'][0]['name'], 'Akash Gupta')

    def test_search_by_alias_and_sr_no(self):
        HistorySheeter.objects.create(station_name=self.user.station_name, sr_no=1, name="Akash Gupta", alias="Akki")
        req_srch = self.factory.get('/api/history-sheeter/?q=Akki')
        force_authenticate(req_srch, user=self.user)
        res_srch = HistorySheeterListCreateView.as_view()(req_srch)
        self.assertEqual(res_srch.data['count'], 1)

    def test_detail_view_and_patch(self):
        hs = HistorySheeter.objects.create(station_name=self.user.station_name, sr_no=1, name="Initial Name")
        req_get = self.factory.get(f'/api/history-sheeter/{hs.id}/')
        force_authenticate(req_get, user=self.user)
        res_get = HistorySheeterDetailView.as_view()(req_get, pk=hs.id)
        self.assertEqual(res_get.status_code, status.HTTP_200_OK)
        self.assertTrue(len(res_get.data['display_rows']) >= 1)

        req_patch = self.factory.patch(
            f'/api/history-sheeter/{hs.id}/',
            {'hs_name': 'Updated Name', 'hs_alias': 'New Alias'},
            format='json'
        )
        force_authenticate(req_patch, user=self.user)
        res_patch = HistorySheeterDetailView.as_view()(req_patch, pk=hs.id)
        self.assertEqual(res_patch.status_code, status.HTTP_200_OK)
        self.assertEqual(res_patch.data['name'], 'Updated Name')
        self.assertEqual(res_patch.data['alias'], 'New Alias')

    def test_patch_with_full_detail_payload(self):
        """Edit form posts back the whole detail record, including reverse-relation keys."""
        hs = HistorySheeter.objects.create(station_name=self.user.station_name, sr_no=1, name="Round Trip")
        req_get = self.factory.get(f'/api/history-sheeter/{hs.id}/')
        force_authenticate(req_get, user=self.user)
        detail = HistorySheeterDetailView.as_view()(req_get, pk=hs.id).data

        payload = {k: ('' if v is None else v) for k, v in detail.items()}
        payload['hs_closure_reason'] = 'Reformed'
        req_patch = self.factory.patch(f'/api/history-sheeter/{hs.id}/', payload, format='json')
        force_authenticate(req_patch, user=self.user)
        res_patch = HistorySheeterDetailView.as_view()(req_patch, pk=hs.id)
        self.assertEqual(res_patch.status_code, status.HTTP_200_OK)
        self.assertEqual(res_patch.data['closure_reason'], 'Reformed')
        self.assertEqual(res_patch.data['sr_no'], 1)

    def test_pdf_generation(self):
        hs = HistorySheeter.objects.create(station_name=self.user.station_name, sr_no=1, name="Suspect PDF Test")
        HistorySheeterCrime.objects.create(history_sheeter=hs, cr_no="100/2026", police_station="Cyber PS")
        req = self.factory.get(f'/api/history-sheeter/{hs.id}/pdf/')
        force_authenticate(req, user=self.user)
        res = HistorySheeterPDFView.as_view()(req, pk=hs.id)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res['Content-Type'], 'application/pdf')
        self.assertTrue(len(res.content) > 100)

    def test_pdf_generation_without_state_code_returns_400(self):
        hs = HistorySheeter.objects.create(station_name=self.user.station_name, sr_no=1, name="Suspect PDF Test")
        user_no_state = DummyOfficerUser()
        user_no_state.state_code = None
        req = self.factory.get(f'/api/history-sheeter/{hs.id}/pdf/')
        force_authenticate(req, user=user_no_state)
        res = HistorySheeterPDFView.as_view()(req, pk=hs.id)
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('State code could not be resolved', res.data['error'])

    def test_audit_log_written_without_personal_data(self):
        req = self.factory.post('/api/history-sheeter/', {'hs_name': 'Confidential Name'}, format='json')
        force_authenticate(req, user=self.user)
        res = HistorySheeterListCreateView.as_view()(req)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)

        log = AuditLog.objects.filter(category='history_sheeter', event='history_sheeter:create').first()
        self.assertIsNotNone(log)
        self.assertEqual(log.station_name, self.user.station_name)
        # Ensure raw name is not in metadata
        self.assertNotIn('Confidential Name', str(log.metadata))
