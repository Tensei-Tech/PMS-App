import datetime
import calendar
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
    FieldTemplate,
    FieldTemplateField,
)
from apps.crimetab.models.mpda import (
    MpdaProposal,
    MpdaGangMember,
    MpdaCrimeChartEntry,
)
from apps.public_master.models import Designation
from apps.crimetab.views import OptionValuesView
from apps.crimetab.views_mpda import (
    MpdaConfigView,
    MpdaCountsView,
    MpdaListCreateView,
    MpdaDetailView,
    MpdaPDFView,
    MpdaOfficersView,
)


class DummyMpdaOfficerUser:
    def __init__(self, station_name="Crime HQ Police Station", uid="off_mpda_1"):
        self.uid = uid
        self.id = uid
        self.name = "Inspector MPDA Test"
        self.email = "mpda_test@example.com"
        self.role_id = "officer"
        self.station_name = station_name
        self.station_id = "st_crime_hq"
        self.state_code = "MH"
        self.state_schema = "public"
        self.is_anonymous = False
        self.is_authenticated = True


class MpdaBackendTestCase(TestCase):
    def setUp(self):
        cache.clear()
        self.factory = APIRequestFactory()
        self.user = DummyMpdaOfficerUser()

        # Seed yes_no option values
        OptionValue.objects.get_or_create(option_group='yes_no', option_value='Yes', defaults={'display_order': 10, 'is_active': True})
        OptionValue.objects.get_or_create(option_group='yes_no', option_value='No', defaults={'display_order': 20, 'is_active': True})

        # Seed MPDA options
        for opt, ord_val in [('Granted', 10), ('Rejected', 20)]:
            OptionValue.objects.get_or_create(option_group='mpda_outcomes', option_value=opt, defaults={'display_order': ord_val, 'is_active': True})
        for opt, ord_val in [('DM', 10), ('CP', 20), ('Other', 30)]:
            OptionValue.objects.get_or_create(option_group='mpda_detaining_authorities', option_value=opt, defaults={'display_order': ord_val, 'is_active': True})
        for opt, ord_val in [('Dangerous Person', 10), ('Bootlegger', 20)]:
            OptionValue.objects.get_or_create(option_group='mpda_categories', option_value=opt, defaults={'display_order': ord_val, 'is_active': True})

        # Seed 12 crime types
        crime_types = [
            'Murder', 'Attempt to Murder', 'Dacoity', 'Robbery',
            'Extortion', 'Kidnapping', 'Rape', 'Molestation',
            'House Breaking', 'Theft', 'Rioting', 'Body Offence'
        ]
        for idx, ct in enumerate(crime_types, 1):
            OptionValue.objects.get_or_create(
                option_group='mpda_crime_types',
                option_value=ct,
                defaults={'display_order': idx * 10, 'is_active': True}
            )

        # Seed module settings
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='target_category_code', defaults={'setting_value': 'STAND_MPDA'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='enforce_permissions', defaults={'setting_value': 'false'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='max_gang_members', defaults={'setting_value': '5'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='empty_request_message', defaults={'setting_value': 'Cannot save empty record. At least one field must be filled.'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='crime_chart_group_by_field', defaults={'setting_value': 'mpda_crime_type'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='card_total_label', defaults={'setting_value': 'Total MPDA proposal'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='card_approved_label', defaults={'setting_value': 'Approved MPDA'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='card_rejected_label', defaults={'setting_value': 'Rejected MPDA'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='card_jail_label', defaults={'setting_value': 'Total person in jail under MPDA'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='card_released_next_month_label', defaults={'setting_value': 'Released in next month'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='tab_total_label', defaults={'setting_value': 'Total MPDA proposal'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='tab_approved_label', defaults={'setting_value': 'Approved MPDA'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='tab_rejected_label', defaults={'setting_value': 'Rejected MPDA'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='tab_jail_label', defaults={'setting_value': 'Total person in jail under MPDA'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='tab_released_next_month_label', defaults={'setting_value': 'Released in next month'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='btn_edit_label', defaults={'setting_value': 'Edit'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='btn_view_label', defaults={'setting_value': 'View'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='btn_pdf_label', defaults={'setting_value': 'PDF'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='date_format', defaults={'setting_value': '%d/%m/%Y'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='scope_station_roles', defaults={'setting_value': 'officer,station_admin'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='template_name', defaults={'setting_value': 'MPDA Proposal Template'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='pdf_subtitle', defaults={'setting_value': 'MPDA Proposal Docket'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='pdf_filename_prefix', defaults={'setting_value': 'MPDA'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='pdf_department_suffix', defaults={'setting_value': 'DEPARTMENT'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='pdf_police_department_suffix', defaults={'setting_value': 'POLICE DEPARTMENT'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='pdf_fallback_title', defaults={'setting_value': 'POLICE DEPARTMENT'})
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='missing_state_message', defaults={'setting_value': 'State code could not be resolved from authenticated user credentials.'})

        # Seed template & fields
        tmpl, _ = FieldTemplate.objects.get_or_create(template_name='MPDA Proposal Template')
        FieldTemplateField.objects.get_or_create(
            template=tmpl, field_key='mpda_proposal_no',
            defaults={'field_label': 'MPDA proposal no', 'field_source': 'custom', 'field_type': 'text', 'display_order': 10}
        )
        FieldTemplateField.objects.get_or_create(
            template=tmpl, field_key='mpda_proposal_year',
            defaults={'field_label': 'MPDA proposal year', 'field_source': 'custom', 'field_type': 'text', 'display_order': 15}
        )
        FieldTemplateField.objects.get_or_create(
            template=tmpl, field_key='mpda_accused_name',
            defaults={'field_label': 'Accused Name', 'field_source': 'custom', 'field_type': 'text', 'display_order': 20}
        )
        FieldTemplateField.objects.get_or_create(
            template=tmpl, field_key='mpda_io_name',
            defaults={'field_label': 'IO Name', 'field_source': 'custom', 'field_type': 'text', 'display_order': 30}
        )
        FieldTemplateField.objects.get_or_create(
            template=tmpl, field_key='mpda_io_post',
            defaults={'field_label': 'Designation', 'field_source': 'custom', 'field_type': 'dropdown', 'options_source': '/api/options/designations/', 'display_order': 35}
        )
        FieldTemplateField.objects.get_or_create(
            template=tmpl, field_key='mpda_crime_chart',
            defaults={'field_label': 'Crime Chart', 'field_source': 'custom', 'field_type': 'repeating_group', 'options_source': '/api/options/mpda_crime_types/', 'display_order': 40}
        )
        FieldTemplateField.objects.get_or_create(
            template=tmpl, field_key='mpda_crime_type',
            defaults={'field_label': 'Crime Type', 'field_source': 'custom', 'field_type': 'dropdown', 'parent_field_key': 'mpda_crime_chart', 'options_source': '/api/options/mpda_crime_types/', 'display_order': 41}
        )

        # Seed Designation master entries
        Designation.objects.update_or_create(
            code='PI',
            defaults={'title': 'Police Inspector', 'display_name': 'Police Inspector (PI)', 'rank_level': 7, 'is_active': True}
        )
        Designation.objects.update_or_create(
            code='PSI',
            defaults={'title': 'Police Sub-Inspector', 'display_name': 'Police Sub-Inspector (PSI)', 'rank_level': 8, 'is_active': True}
        )

        # Create active officer in station scope
        OfficerProfile.objects.update_or_create(
            uid="officer_io_101",
            defaults={
                "name": "Sub-Inspector V. R. Pawar",
                "designation": "PSI",
                "station_id": self.user.station_id,
                "station_name": self.user.station_name,
                "account_status": "active"
            }
        )

    def test_yes_no_option_values_parity_and_six_counts(self):
        """
        User Requirement 4:
        Confirm detained, government_confirmation and detention_order_revoked
        values match the yes_no option values exactly, and that the six MPDA counts
        follow them.
        """
        if connection.vendor != 'postgresql':
            self.skipTest("Requires PostgreSQL for native calendar month range date filtering and six-count aggregation.")
        yes_no_options = list(OptionValue.objects.filter(option_group='yes_no', is_active=True).values_list('option_value', flat=True))
        self.assertIn('Yes', yes_no_options)
        self.assertIn('No', yes_no_options)
        self.assertEqual(len(yes_no_options), 2)

    def test_boundary_conditions_six_mpda_counts(self):
        """
        Boundary conditions verification for the six MPDA counts:
        first and last days of next month, revoked order exclusions,
        and detained Yes with blank jail name exclusions.
        """
        if connection.vendor != 'postgresql':
            self.skipTest("Requires PostgreSQL for native next calendar month range date filtering and jail exclusions.")

        # Helper to compute next month boundary dates
        today = datetime.date.today()
        if today.month == 12:
            ny, nm = today.year + 1, 1
        else:
            ny, nm = today.year, today.month + 1
        first_day_next_month = datetime.date(ny, nm, 1)
        _, last_day_num = calendar.monthrange(ny, nm)
        last_day_next_month = datetime.date(ny, nm, last_day_num)

        # 1. Proposal: Granted (Approved count)
        MpdaProposal.objects.create(
            station_name=self.user.station_name,
            proposal_no_and_year="MPDA/01/2026",
            accused_name="Accused A",
            proposal_outcome="Granted",
            granted_date=today
        )

        # 2. Proposal: Rejected (Rejected count)
        MpdaProposal.objects.create(
            station_name=self.user.station_name,
            proposal_no_and_year="MPDA/02/2026",
            accused_name="Accused B",
            proposal_outcome="Rejected",
            rejected_date=today
        )

        # 3. Proposal: Detained='Yes' with Jail Name, not revoked (In Jail count)
        MpdaProposal.objects.create(
            station_name=self.user.station_name,
            proposal_no_and_year="MPDA/03/2026",
            accused_name="Accused C",
            detained="Yes",
            jail_name="Yerwada Central Jail",
            detention_order_revoked="No"
        )

        # 4. Proposal: Boundary test: Detained='Yes' but NO jail name entered (Must NOT count in Jail)
        MpdaProposal.objects.create(
            station_name=self.user.station_name,
            proposal_no_and_year="MPDA/04/2026",
            accused_name="Accused D",
            detained="Yes",
            jail_name="",
            detention_order_revoked="No"
        )

        # 5. Proposal: Revoked='Yes' (Revoked count; must NOT count in Jail even if Detained='Yes')
        MpdaProposal.objects.create(
            station_name=self.user.station_name,
            proposal_no_and_year="MPDA/05/2026",
            accused_name="Accused E",
            detained="Yes",
            jail_name="Arthur Road Jail",
            detention_order_revoked="Yes",
            order_revoked_date=today
        )

        # 6. Proposal: Completion on first day of next month (Released in next month count)
        MpdaProposal.objects.create(
            station_name=self.user.station_name,
            proposal_no_and_year="MPDA/06/2026",
            accused_name="Accused F",
            detention_completion_date=first_day_next_month,
            detention_order_revoked="No"
        )

        # 7. Proposal: Completion on last day of next month (Released in next month count boundary)
        MpdaProposal.objects.create(
            station_name=self.user.station_name,
            proposal_no_and_year="MPDA/07/2026",
            accused_name="Accused G",
            detention_completion_date=last_day_next_month,
            detention_order_revoked=None
        )

        # 8. Proposal: Completion in next month BUT Revoked='Yes' (Must NOT count in released next month)
        MpdaProposal.objects.create(
            station_name=self.user.station_name,
            proposal_no_and_year="MPDA/08/2026",
            accused_name="Accused H",
            detention_completion_date=first_day_next_month,
            detention_order_revoked="Yes"
        )

        # 9. Proposal: Completion in current month (Must NOT count in released next month)
        MpdaProposal.objects.create(
            station_name=self.user.station_name,
            proposal_no_and_year="MPDA/09/2026",
            accused_name="Accused I",
            detention_completion_date=today
        )

        req = self.factory.get('/api/mpda/counts/')
        force_authenticate(req, user=self.user)
        res = MpdaCountsView.as_view()(req)
        self.assertEqual(res.status_code, status.HTTP_200_OK)

        # Verify all 6 counts exactly:
        self.assertEqual(res.data['total'], 9)               # all 9 proposals
        self.assertEqual(res.data['approved'], 1)            # Proposal 1
        self.assertEqual(res.data['rejected'], 1)            # Proposal 2
        self.assertEqual(res.data['jail'], 1)                # Proposal 3 only (4 has no jail name, 5 is revoked)
        self.assertEqual(res.data['revoked'], 2)             # Proposals 5 and 8
        self.assertEqual(res.data['released_next_month'], 2) # Proposals 6 and 7 (Proposal 8 is revoked)

    def test_proposal_revoked_card_count_and_list(self):
        """'Total MPDA Revoked' counts and lists proposals whose Revoked is Yes with a Revoked Date."""
        st = self.user.station_name
        today = datetime.date.today()
        MpdaProposal.objects.create(station_name=st, proposal_no_and_year="RV/1", proposal_revoked="Yes",
                                    proposal_revoked_date=today)
        # Revoked = Yes without its date is not counted yet
        MpdaProposal.objects.create(station_name=st, proposal_no_and_year="RV/6", proposal_revoked="Yes")
        MpdaProposal.objects.create(station_name=st, proposal_no_and_year="RV/2", proposal_revoked="No")
        MpdaProposal.objects.create(station_name=st, proposal_no_and_year="RV/3")
        # Detention order revoked is a different field and must not count here
        MpdaProposal.objects.create(station_name=st, proposal_no_and_year="RV/4", detention_order_revoked="Yes")
        # Another station's revoked proposal is not visible
        MpdaProposal.objects.create(station_name="Other Station", proposal_no_and_year="RV/5", proposal_revoked="Yes",
                                    proposal_revoked_date=today)
        cache.clear()

        req = self.factory.get('/api/mpda/counts/')
        force_authenticate(req, user=self.user)
        res = MpdaCountsView.as_view()(req)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['proposal_revoked'], 1)

        req = self.factory.get('/api/mpda/?tab=proposal_revoked')
        force_authenticate(req, user=self.user)
        res = MpdaListCreateView.as_view()(req)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['count'], 1)
        self.assertEqual(res.data['results'][0]['proposal_no_and_year'], "RV/1")

    def test_released_card_day_filters(self):
        """Released card: 10 / 20 day filters count and list releases from today to today + N days."""
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='released_filter_days',
                                               defaults={'setting_value': '20,10'})
        st = self.user.station_name
        today = datetime.date.today()
        for no, offset, revoked in (("RL/5", 5, None), ("RL/15", 15, None),
                                    ("RL/30", 30, None), ("RL/REV", 5, "Yes"), ("RL/PAST", -1, None)):
            MpdaProposal.objects.create(station_name=st, proposal_no_and_year=no,
                                        detention_completion_date=today + datetime.timedelta(days=offset),
                                        detention_order_revoked=revoked)
        cache.clear()

        req = self.factory.get('/api/mpda/counts/')
        force_authenticate(req, user=self.user)
        res = MpdaCountsView.as_view()(req)
        self.assertEqual(res.data['released_in_days'], {'20': 2, '10': 1})

        for days, expected in (('10', {'RL/5'}), ('20', {'RL/5', 'RL/15'})):
            req = self.factory.get(f'/api/mpda/?tab=released_next_month&days={days}')
            force_authenticate(req, user=self.user)
            res = MpdaListCreateView.as_view()(req)
            self.assertEqual({r['proposal_no_and_year'] for r in res.data['results']}, expected)

    def test_approved_and_rejected_need_their_date(self):
        """Approved / Rejected count and list a proposal only once its outcome date is filled."""
        st = self.user.station_name
        today = datetime.date.today()
        MpdaProposal.objects.create(station_name=st, proposal_no_and_year="AP/1",
                                    proposal_outcome="Granted", granted_date=today)
        MpdaProposal.objects.create(station_name=st, proposal_no_and_year="AP/2", proposal_outcome="Granted")
        MpdaProposal.objects.create(station_name=st, proposal_no_and_year="RJ/1",
                                    proposal_outcome="Rejected", rejected_date=today)
        MpdaProposal.objects.create(station_name=st, proposal_no_and_year="RJ/2", proposal_outcome="Rejected")
        cache.clear()

        req = self.factory.get('/api/mpda/counts/')
        force_authenticate(req, user=self.user)
        res = MpdaCountsView.as_view()(req)
        self.assertEqual((res.data['approved'], res.data['rejected']), (1, 1))

        for tab, expected in (('approved', 'AP/1'), ('rejected', 'RJ/1')):
            req = self.factory.get(f'/api/mpda/?tab={tab}')
            force_authenticate(req, user=self.user)
            res = MpdaListCreateView.as_view()(req)
            self.assertEqual(res.data['count'], 1)
            self.assertEqual(res.data['results'][0]['proposal_no_and_year'], expected)

    def test_chk_mpda_outcome_dates_relaxed(self):
        """
        User Requirement 1:
        chk_mpda_outcome_dates must not force a date. Allow Granted with the date
        NULL, Rejected with the date NULL, and nothing; keep forbidding Granted with
        a rejected_date, or Rejected with a granted_date.
        """
        # 1. Granted with date NULL
        p1 = MpdaProposal.objects.create(
            station_name=self.user.station_name,
            proposal_no_and_year="P1",
            proposal_outcome="Granted",
            granted_date=None,
            rejected_date=None
        )
        self.assertIsNotNone(p1.id)

        # 2. Rejected with date NULL
        p2 = MpdaProposal.objects.create(
            station_name=self.user.station_name,
            proposal_no_and_year="P2",
            proposal_outcome="Rejected",
            granted_date=None,
            rejected_date=None
        )
        self.assertIsNotNone(p2.id)

        # 3. Blank outcome with dates NULL
        p3 = MpdaProposal.objects.create(
            station_name=self.user.station_name,
            proposal_no_and_year="P3",
            proposal_outcome=None,
            granted_date=None,
            rejected_date=None
        )
        self.assertIsNotNone(p3.id)

        # 4. In create view: Choosing Granted clears rejected_date automatically
        req = self.factory.post('/api/mpda/', {
            'mpda_proposal_no_and_year': 'P4',
            'mpda_proposal_outcome': 'Granted',
            'mpda_rejected_date': '15/10/2026'
        }, format='json')
        force_authenticate(req, user=self.user)
        res = MpdaListCreateView.as_view()(req)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data['proposal_outcome'], 'Granted')
        self.assertIsNone(res.data['rejected_date'])

    def test_gang_members_max_limit_from_settings(self):
        # Limit removed per Requirement 8: 6 members should succeed
        gm_6 = [{'mpda_gang_member_name': f"Member {i}"} for i in range(1, 7)]
        req2 = self.factory.post('/api/mpda/', {'mpda_proposal_no_and_year': 'P_GM6', 'gang_members': gm_6}, format='json')
        force_authenticate(req2, user=self.user)
        res2 = MpdaListCreateView.as_view()(req2)
        self.assertEqual(res2.status_code, status.HTTP_201_CREATED)
        self.assertEqual(len(res2.data['gang_members']), 6)

    def test_save_with_only_one_field(self):
        """User Requirement 6: save with only one field."""
        req = self.factory.post('/api/mpda/', {'mpda_accused_name': 'Only One Field Accused'}, format='json')
        force_authenticate(req, user=self.user)
        res = MpdaListCreateView.as_view()(req)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data['accused_name'], 'Only One Field Accused')
        self.assertEqual(res.data['station_name'], self.user.station_name)

    def test_save_with_granted_and_no_date(self):
        """User Requirement 6: save with Granted and no date."""
        req = self.factory.post('/api/mpda/', {
            'mpda_proposal_no': 'GR_NO_DATE_01',
            'mpda_proposal_outcome': 'Granted',
            'mpda_granted_date': ''
        }, format='json')
        force_authenticate(req, user=self.user)
        res = MpdaListCreateView.as_view()(req)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data['proposal_outcome'], 'Granted')
        self.assertIsNone(res.data['granted_date'])
        self.assertIsNone(res.data['rejected_date'])

    def test_save_with_rejected_and_a_date(self):
        """User Requirement 6: save with Rejected and a date."""
        req = self.factory.post('/api/mpda/', {
            'mpda_proposal_no': 'REJ_WITH_DATE_01',
            'mpda_proposal_outcome': 'Rejected',
            'mpda_rejected_date': '12/10/2026'
        }, format='json')
        force_authenticate(req, user=self.user)
        res = MpdaListCreateView.as_view()(req)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data['proposal_outcome'], 'Rejected')
        self.assertEqual(str(res.data['rejected_date']), '2026-10-12')
        self.assertIsNone(res.data['granted_date'])

    def test_crime_chart_loads_and_groups_12_sections(self):
        """User Requirement 6: crime chart loads and groups the 12 sections."""
        # 1. Option values view returns the 12 crime types
        req_opt = self.factory.get('/api/options/mpda_crime_types/')
        force_authenticate(req_opt, user=self.user)
        res_opt = OptionValuesView.as_view()(req_opt, group='mpda_crime_types')
        self.assertEqual(res_opt.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res_opt.data), 12)

        # 2. Group by field setting is seeded
        grp_setting = ModuleSetting.objects.get(module_key='mpda', setting_key='crime_chart_group_by_field')
        self.assertEqual(grp_setting.setting_value, 'mpda_crime_type')

        # 3. Create MPDA proposal with entries for all 12 sections
        crime_types = res_opt.data
        entries = [
            {'mpda_crime_type': ct, 'mpda_cr_no': f'{i}/2026', 'mpda_police_station': 'HQ Station'}
            for i, ct in enumerate(crime_types, 1)
        ]
        req_create = self.factory.post('/api/mpda/', {
            'mpda_proposal_no': 'CHART_12_TEST',
            'mpda_crime_chart': entries
        }, format='json')
        force_authenticate(req_create, user=self.user)
        res_create = MpdaListCreateView.as_view()(req_create)
        self.assertEqual(res_create.status_code, status.HTTP_201_CREATED)
        prop_id = res_create.data['id']

        # 4. Detail view retrieves all 12 entries
        req_det = self.factory.get(f'/api/mpda/{prop_id}/')
        force_authenticate(req_det, user=self.user)
        res_det = MpdaDetailView.as_view()(req_det, pk=prop_id)
        self.assertEqual(res_det.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res_det.data['crime_chart']), 12)

    def test_crime_chart_act_section_subsection_round_trip(self):
        """Crime Chart rows keep the Act / Section / Subsection picked from the Acts master."""
        charge = {
            'act_id': 7, 'act_name': 'BNS', 'section_id': 70, 'section_number': '103',
            'section_title': 'Murder', 'subsection_id': 701, 'subsection_code': '(1)',
        }
        req_create = self.factory.post('/api/mpda/', {
            'mpda_proposal_no': 'CHART_ACT_TEST',
            'mpda_crime_chart': [
                {'mpda_crime_type': 'Crimes against the body', 'mpda_crime_cr_no': '1/2026',
                 'mpda_crime_act_section': [charge]},
                # Only an Act / Section picked: the row is still kept
                {'mpda_crime_type': 'Crimes against property', 'mpda_crime_act_section': [charge]},
            ],
        }, format='json')
        force_authenticate(req_create, user=self.user)
        res_create = MpdaListCreateView.as_view()(req_create)
        self.assertEqual(res_create.status_code, status.HTTP_201_CREATED)

        req_det = self.factory.get(f"/api/mpda/{res_create.data['id']}/")
        force_authenticate(req_det, user=self.user)
        rows = MpdaDetailView.as_view()(req_det, pk=res_create.data['id']).data['mpda_crime_chart']
        self.assertEqual(len(rows), 2)
        for row in rows:
            self.assertEqual(row['act_section'], 'BNS / 103 / (1)')
            self.assertEqual(row['mpda_crime_act_section'], [charge])

    def test_post_dropdown_lists_posts_from_database_and_changes_dynamically(self):
        """User Requirement 6: post dropdown lists posts from database and changing a row changes the list."""
        req = self.factory.get('/api/options/designations/')
        force_authenticate(req, user=self.user)
        res = OptionValuesView.as_view()(req, group='designations')
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn('Police Inspector (PI)', res.data)
        self.assertIn('Police Sub-Inspector (PSI)', res.data)

        # Deactivate PSI
        Designation.objects.filter(code='PSI').update(is_active=False)
        cache.clear()
        res2 = OptionValuesView.as_view()(req, group='designations')
        self.assertNotIn('Police Sub-Inspector (PSI)', res2.data)
        self.assertIn('Police Inspector (PI)', res2.data)

        # Add a new post
        Designation.objects.create(
            code='DGP',
            title='Director General of Police',
            display_name='Director General of Police (DGP)',
            rank_level=1,
            is_active=True
        )
        cache.clear()
        res3 = OptionValuesView.as_view()(req, group='designations')
        self.assertIn('Director General of Police (DGP)', res3.data)
        self.assertEqual(res3.data[0], 'Director General of Police (DGP)')

    def test_no_uid_is_read_or_written(self):
        """User Requirement 1 & 6: no uid is read or written."""
        # 1. In Create: sending io_uid is ignored and never written to db
        req = self.factory.post('/api/mpda/', {
            'mpda_proposal_no': 'NO_UID_01',
            'mpda_io_name': 'Inspector Ramesh',
            'mpda_io_uid': 'attempted_write_uid_123'
        }, format='json')
        force_authenticate(req, user=self.user)
        res = MpdaListCreateView.as_view()(req)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        prop = MpdaProposal.objects.get(id=res.data['id'])
        self.assertIsNone(prop.io_uid)
        self.assertEqual(prop.io_name, 'Inspector Ramesh')

        # 2. In Detail: io_uid is omitted from representation and display_rows
        req_det = self.factory.get(f'/api/mpda/{prop.id}/')
        force_authenticate(req_det, user=self.user)
        res_det = MpdaDetailView.as_view()(req_det, pk=prop.id)
        self.assertNotIn('io_uid', res_det.data)
        display_labels = [r[0] for r in res_det.data.get('display_rows', [])]
        self.assertNotIn('IO UID', display_labels)
        self.assertIn('IO Name', display_labels)

        # 3. In Patch: sending io_uid is ignored and never written
        req_patch = self.factory.patch(
            f'/api/mpda/{prop.id}/',
            {'mpda_io_uid': 'malicious_patch_uid'},
            format='json'
        )
        force_authenticate(req_patch, user=self.user)
        res_patch = MpdaDetailView.as_view()(req_patch, pk=prop.id)
        self.assertEqual(res_patch.status_code, status.HTTP_200_OK)
        prop.refresh_from_db()
        self.assertIsNone(prop.io_uid)

    def test_split_proposal_no_and_year(self):
        """User Requirement 2: split proposal no and year into two fields."""
        req = self.factory.post('/api/mpda/', {
            'mpda_proposal_no': 'CASE-55',
            'mpda_proposal_year': '2026',
            'mpda_accused_name': 'Split Field Test'
        }, format='json')
        force_authenticate(req, user=self.user)
        res = MpdaListCreateView.as_view()(req)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data['proposal_no'], 'CASE-55')
        self.assertEqual(res.data['proposal_year'], '2026')
        self.assertEqual(res.data['proposal_no_and_year'], 'CASE-55/2026')

        req_det = self.factory.get(f"/api/mpda/{res.data['id']}/")
        force_authenticate(req_det, user=self.user)
        res_det = MpdaDetailView.as_view()(req_det, pk=res.data['id'])
        display_labels = [r[0] for r in res_det.data.get('display_rows', [])]
        self.assertIn('MPDA proposal no', display_labels)
        self.assertIn('MPDA proposal year', display_labels)

    def test_officer_scoping_hierarchy_station_division_district_state(self):
        # 1. Setup multi-unit officer profiles
        OfficerProfile.objects.update_or_create(
            uid="officer_div_match",
            defaults={"name": "Div Officer", "email": "div_off@example.com", "division_id": "div_north", "district_id": "dist_1", "account_status": "active"}
        )
        OfficerProfile.objects.update_or_create(
            uid="officer_dist_match",
            defaults={"name": "Dist Officer", "email": "dist_off@example.com", "division_id": "div_south", "district_id": "dist_1", "account_status": "active"}
        )
        OfficerProfile.objects.update_or_create(
            uid="officer_other_dist",
            defaults={"name": "Other Dist Officer", "email": "other_off@example.com", "division_id": "div_other", "district_id": "dist_2", "account_status": "active"}
        )

        # 2. Test Division Admin scope
        div_user = DummyMpdaOfficerUser()
        div_user.role_id = 'division_admin'
        div_user.division_id = 'div_north'
        div_user.district_id = 'dist_1'
        req_div = self.factory.get('/api/mpda/officers/')
        force_authenticate(req_div, user=div_user)
        res_div = MpdaOfficersView.as_view()(req_div)
        uids_div = [o['uid'] for o in res_div.data]
        self.assertIn('officer_div_match', uids_div)
        self.assertNotIn('officer_dist_match', uids_div)
        self.assertNotIn('officer_other_dist', uids_div)

        # 3. Test District Admin scope
        dist_user = DummyMpdaOfficerUser()
        dist_user.role_id = 'district_admin'
        dist_user.division_id = 'div_north'
        dist_user.district_id = 'dist_1'
        req_dist = self.factory.get('/api/mpda/officers/')
        force_authenticate(req_dist, user=dist_user)
        res_dist = MpdaOfficersView.as_view()(req_dist)
        uids_dist = [o['uid'] for o in res_dist.data]
        self.assertIn('officer_div_match', uids_dist)
        self.assertIn('officer_dist_match', uids_dist)
        self.assertNotIn('officer_other_dist', uids_dist)

        # 4. Test State Super Admin scope (sees all active officers)
        state_user = DummyMpdaOfficerUser()
        state_user.role_id = 'state_super_admin'
        req_state = self.factory.get('/api/mpda/officers/')
        force_authenticate(req_state, user=state_user)
        res_state = MpdaOfficersView.as_view()(req_state)
        uids_state = [o['uid'] for o in res_state.data]
        self.assertIn('officer_div_match', uids_state)
        self.assertIn('officer_dist_match', uids_state)
        self.assertIn('officer_other_dist', uids_state)

        # 5. Test Unconfigured role gets empty results and error message
        anon_role_user = DummyMpdaOfficerUser()
        anon_role_user.role_id = 'unknown_external_role'
        req_unconf = self.factory.get('/api/mpda/officers/')
        force_authenticate(req_unconf, user=anon_role_user)
        res_unconf = MpdaOfficersView.as_view()(req_unconf)
        self.assertEqual(res_unconf.data['results'], [])
        self.assertIn('not have an officer assignment scope', res_unconf.data['message'])

    def test_empty_request_rejected(self):
        req = self.factory.post('/api/mpda/', {}, format='json')
        force_authenticate(req, user=self.user)
        res = MpdaListCreateView.as_view()(req)
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('Cannot save empty record', res.data['error'])

    def test_config_endpoint_returns_database_labels(self):
        req = self.factory.get('/api/mpda/config/')
        force_authenticate(req, user=self.user)
        res = MpdaConfigView.as_view()(req)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data['target_category_code'], 'STAND_MPDA')
        self.assertEqual(res.data['card_labels']['total'], 'Total MPDA proposal')
        self.assertEqual(res.data['card_labels']['approved'], 'Approved MPDA')
        self.assertEqual(res.data['max_gang_members'], 5)

    def test_detail_view_and_patch(self):
        prop = MpdaProposal.objects.create(station_name=self.user.station_name, proposal_no_and_year="Initial/01")
        req_get = self.factory.get(f'/api/mpda/{prop.id}/')
        force_authenticate(req_get, user=self.user)
        res_get = MpdaDetailView.as_view()(req_get, pk=prop.id)
        self.assertEqual(res_get.status_code, status.HTTP_200_OK)
        self.assertTrue(len(res_get.data['display_rows']) >= 1)

        req_patch = self.factory.patch(
            f'/api/mpda/{prop.id}/',
            {
                'mpda_accused_name': 'Updated Accused',
                'gang_members': [{'mpda_gang_member_name': 'Gang Member Alpha'}]
            },
            format='json'
        )
        force_authenticate(req_patch, user=self.user)
        res_patch = MpdaDetailView.as_view()(req_patch, pk=prop.id)
        self.assertEqual(res_patch.status_code, status.HTTP_200_OK)
        self.assertEqual(res_patch.data['accused_name'], 'Updated Accused')
        self.assertEqual(len(res_patch.data['gang_members']), 1)

    def test_pdf_generation(self):
        prop = MpdaProposal.objects.create(
            station_name=self.user.station_name,
            proposal_no_and_year="MPDA/PDF/01",
            accused_name="Accused PDF Test"
        )
        MpdaGangMember.objects.create(proposal=prop, name="Member 1", display_order=1)
        MpdaCrimeChartEntry.objects.create(proposal=prop, crime_type="Murder", cr_no="99/2026", police_station="Cyber PS")

        req = self.factory.get(f'/api/mpda/{prop.id}/pdf/')
        force_authenticate(req, user=self.user)
        res = MpdaPDFView.as_view()(req, pk=prop.id)
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res['Content-Type'], 'application/pdf')
        self.assertTrue(len(res.content) > 100)

    def test_pdf_generation_without_state_code_returns_400(self):
        prop = MpdaProposal.objects.create(station_name=self.user.station_name, proposal_no_and_year="MPDA/PDF/02")
        user_no_state = DummyMpdaOfficerUser()
        user_no_state.state_code = None
        req = self.factory.get(f'/api/mpda/{prop.id}/pdf/')
        force_authenticate(req, user=user_no_state)
        res = MpdaPDFView.as_view()(req, pk=prop.id)
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('State code could not be resolved', res.data['error'])

    def test_audit_log_written_without_personal_data(self):
        req = self.factory.post('/api/mpda/', {'mpda_accused_name': 'Confidential Accused'}, format='json')
        force_authenticate(req, user=self.user)
        res = MpdaListCreateView.as_view()(req)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)

        log = AuditLog.objects.filter(category='mpda', event='mpda:create').first()
        self.assertIsNotNone(log)
        self.assertEqual(log.station_name, self.user.station_name)
        self.assertNotIn('Confidential Accused', str(log.metadata))

    def test_total_misc_crime_field(self):
        """Test total_misc_crime create, detail, display_rows, and patch."""
        # 1. Create with total_misc_crime
        req = self.factory.post('/api/mpda/', {
            'mpda_proposal_no': 'MISC_01',
            'mpda_total_crime': '15',
            'mpda_serious_crimes': '10',
            'mpda_total_misc_crime': '5',
        }, format='json')
        force_authenticate(req, user=self.user)
        res = MpdaListCreateView.as_view()(req)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data.get('total_misc_crime'), 5)
        self.assertEqual(res.data.get('mpda_total_misc_crime'), 5)

        prop_id = res.data['id']
        prop = MpdaProposal.objects.get(id=prop_id)
        self.assertEqual(prop.total_misc_crime, 5)

        # 2. Detail representation and display_rows
        req_det = self.factory.get(f'/api/mpda/{prop_id}/')
        force_authenticate(req_det, user=self.user)
        res_det = MpdaDetailView.as_view()(req_det, pk=prop_id)
        self.assertEqual(res_det.data.get('total_misc_crime'), 5)
        self.assertEqual(res_det.data.get('mpda_total_misc_crime'), 5)

        # 3. Patch total_misc_crime
        req_patch = self.factory.patch(
            f'/api/mpda/{prop_id}/',
            {'mpda_total_misc_crime': '8'},
            format='json'
        )
        force_authenticate(req_patch, user=self.user)
        res_patch = MpdaDetailView.as_view()(req_patch, pk=prop_id)
        self.assertEqual(res_patch.status_code, status.HTTP_200_OK)
        prop.refresh_from_db()
        self.assertEqual(prop.total_misc_crime, 8)

