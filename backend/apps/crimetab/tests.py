import json
from django.test import TestCase, Client
from django.utils import timezone
from django.db import transaction, IntegrityError
from rest_framework import status
from apps.core.tenancy import TenantContext

from apps.cases.models import CaseRecord
from apps.crimetab.models.groupings import CaseCategoryGroup, CaseCategory, CaseCategoryLink
from apps.crimetab.models.dynamic_engine import (
    FieldTemplate,
    FieldTemplateField,
    CategoryFieldTemplate,
    SectionFieldTemplate,
    CaseExtraFieldValue,
    ModuleSetting,
)
from apps.crimetab.models.common_form import (
    CrimeRegistrationInfo,
    Act,
    ActSection,
    ActSubsection,
    CrimeCaseActsSections,
    CrimeSpot,
    CasesPerson,
    CrimeCaseResponsibility,
    ArrestReleaseStatus,
    RemandCustody,
    CctvTechnical,
    ProceduralChecklist,
    CaseForensics,
    SeizureRecords,
    PreventiveActionItems,
    PreventiveBond,
    DischargeStatus,
    ScrutinyPipeline,
    FinalVerdict,
)
from apps.crimetab.services.dynamic_form_service import get_form_definition
from apps.crimetab.services.counter_service import get_group_counters, get_category_counters


class CommonFormE2ETests(TestCase):
    def setUp(self):
        from django.db import connection
        if connection.connection and hasattr(connection.connection, 'closed') and connection.connection.closed:
            connection.connect()

        from apps.core.tenancy import TenantContext
        from apps.public_master.models import StateRegistry
        StateRegistry.objects.get_or_create(
            state_code='MH',
            defaults={'state_name': 'Maharashtra', 'schema_name': 'maharashtra', 'is_active': True}
        )
        self.tenant_ctx = TenantContext('maharashtra')
        self.tenant_ctx.__enter__()

        self.client = Client(HTTP_X_STATE_CODE='MH')

        # Clean existing test artifacts if any
        SectionFieldTemplate.objects.all().delete()
        CaseExtraFieldValue.objects.all().delete()
        CaseCategoryLink.objects.all().delete()
        CaseRecord.objects.all().delete()

        # 1. Category Groups
        self.group_1to5, _ = CaseCategoryGroup.objects.get_or_create(
            group_id=1,
            defaults={'group_name': '1 to 5', 'group_code': 'I TO V', 'display_order': 1}
        )
        self.group_part6, _ = CaseCategoryGroup.objects.get_or_create(
            group_id=2,
            defaults={'group_name': 'Part 6', 'group_code': 'VI', 'display_order': 2}
        )

        # 2. Baseline Template & Custom Section Templates
        self.baseline_tmpl, _ = FieldTemplate.objects.get_or_create(template_name='Common Form Baseline Template')
        self.tmpl_murder, _ = FieldTemplate.objects.get_or_create(template_name='Murder Section Extra Fields')
        self.tmpl_hurt, _ = FieldTemplate.objects.get_or_create(template_name='Hurt Section Extra Fields')

        # Baseline common fields
        FieldTemplateField.objects.get_or_create(
            template=self.baseline_tmpl,
            field_key='cr_number',
            defaults={'field_label': 'CR Number', 'field_source': 'common', 'field_type': 'text', 'display_order': 10}
        )
        FieldTemplateField.objects.get_or_create(
            template=self.baseline_tmpl,
            field_key='complainant_name',
            defaults={'field_label': 'Complainant Name', 'field_source': 'common', 'field_type': 'text', 'display_order': 90}
        )
        FieldTemplateField.objects.get_or_create(
            template=self.baseline_tmpl,
            field_key='accused_name',
            defaults={'field_label': 'Accused Name', 'field_source': 'common', 'field_type': 'text', 'display_order': 190}
        )

        # Murder extra template (no extra fields currently attached)
        # Hurt extra fields
        FieldTemplateField.objects.get_or_create(
            template=self.tmpl_hurt,
            field_key='injured_name',
            defaults={'field_label': 'Injured Person Name', 'field_source': 'custom', 'field_type': 'text', 'display_order': 1100}
        )
        FieldTemplateField.objects.get_or_create(
            template=self.tmpl_hurt,
            field_key='injury_type',
            defaults={'field_label': 'Injury Type / Severity', 'field_source': 'custom', 'field_type': 'text', 'display_order': 1110}
        )

        # 3. Categories
        self.cat_murder = CaseCategory.objects.filter(category_name='Murder', group=self.group_1to5).first()
        if not self.cat_murder:
            self.cat_murder = CaseCategory.objects.create(
                group=self.group_1to5,
                category_name='Murder',
                category_code='101',
                template=self.baseline_tmpl,
                display_order=1
            )
        else:
            self.cat_murder.template = self.baseline_tmpl
            self.cat_murder.save()

        self.cat_hurt = CaseCategory.objects.filter(category_name='Hurt', group=self.group_1to5).first()
        if not self.cat_hurt:
            self.cat_hurt = CaseCategory.objects.create(
                group=self.group_1to5,
                category_name='Hurt',
                category_code='107',
                template=self.baseline_tmpl,
                display_order=2
            )
        else:
            self.cat_hurt.template = self.baseline_tmpl
            self.cat_hurt.save()

        self.cat_ad = CaseCategory.objects.filter(category_name='A.D.').first()
        if not self.cat_ad:
            self.cat_ad = CaseCategory.objects.create(category_name='A.D.', category_code='AD', template=None, group=self.group_1to5)
        self.cat_suicide = CaseCategory.objects.filter(category_name='Suicide').first()
        if not self.cat_suicide:
            self.cat_suicide = CaseCategory.objects.create(category_name='Suicide', category_code='SUI', template=None, group=self.group_1to5)
        self.cat_nc = CaseCategory.objects.filter(category_name='N.C.').first()
        if not self.cat_nc:
            self.cat_nc = CaseCategory.objects.create(category_name='N.C.', category_code='NC', template=None, group=self.group_1to5)

        # CategoryFieldTemplate mappings (Trigger A: multiple templates per tab)
        CategoryFieldTemplate.objects.get_or_create(category=self.cat_murder, template=self.baseline_tmpl)
        CategoryFieldTemplate.objects.get_or_create(category=self.cat_murder, template=self.tmpl_murder)
        CategoryFieldTemplate.objects.get_or_create(category=self.cat_hurt, template=self.baseline_tmpl)

        # 4. Acts & Sections
        self.act_bns, _ = Act.objects.get_or_create(
            act_name='Bharatiya Nyaya Sanhita 2023',
            defaults={'display_order': 1}
        )
        self.sec_murder = ActSection.objects.filter(act=self.act_bns, section_number='103').first()
        if not self.sec_murder:
            self.sec_murder = ActSection.objects.create(act=self.act_bns, section_number='103', section_title='Punishment for murder')

        self.sec_hurt = ActSection.objects.filter(act=self.act_bns, section_number='115').first()
        if not self.sec_hurt:
            self.sec_hurt = ActSection.objects.create(act=self.act_bns, section_number='115', section_title='Voluntarily causing hurt')

        # Trigger B mappings (Section-triggered dynamic templates)
        SectionFieldTemplate.objects.get_or_create(section=self.sec_murder, template=self.tmpl_murder)
        SectionFieldTemplate.objects.get_or_create(section=self.sec_hurt, template=self.tmpl_hurt)

    def tearDown(self):
        if hasattr(self, 'tenant_ctx'):
            try:
                self.tenant_ctx.__exit__(None, None, None)
            except Exception:
                pass

    def test_1_form_renders_common_fields_and_tab_specific_extras_immediately(self):
        """
        Opening Murder tab shows shared baseline fields and does not include
        removed Murder extras or Hurt's section extras.
        """
        form_def = get_form_definition(category_id=self.cat_murder.category_id)
        field_keys = [f['field_key'] for f in form_def['fields']]
        # Shared baseline fields
        self.assertIn('cr_number', field_keys)
        self.assertIn('complainant_name', field_keys)
        self.assertIn('accused_name', field_keys)
        # Removed Murder fields must not be present
        self.assertNotIn('deceased_name', field_keys)
        self.assertNotIn('inquest_panchanama', field_keys)
        # Hurt's extra fields should NOT be present yet
        self.assertNotIn('injured_name', field_keys)

    def test_2_dynamic_multi_charge_layering_without_losing_data(self):
        """
        Trigger B:
        1. Add Murder's section -> confirm no duplicates or breakages.
        2. Add Hurt's section as second charge on the SAME case -> confirm Hurt's dynamic fields
           get appended into the same continuous form.
        """
        # 1. Add Murder section charged
        form_def_murder = get_form_definition(
            category_id=self.cat_murder.category_id,
            charged_section_ids=[self.sec_murder.section_id]
        )
        keys_murder = [f['field_key'] for f in form_def_murder['fields']]
        self.assertIn('cr_number', keys_murder)
        self.assertNotIn('deceased_name', keys_murder)
        self.assertNotIn('inquest_panchanama', keys_murder)
        self.assertNotIn('injured_name', keys_murder)

        # 2. Add Hurt section charged on the same case
        form_def_multi = get_form_definition(
            category_id=self.cat_murder.category_id,
            charged_section_ids=[self.sec_murder.section_id, self.sec_hurt.section_id]
        )
        keys_multi = [f['field_key'] for f in form_def_multi['fields']]
        # Baseline and dynamic Hurt section fields are present
        self.assertIn('cr_number', keys_multi)
        self.assertNotIn('deceased_name', keys_multi)
        self.assertNotIn('inquest_panchanama', keys_multi)
        self.assertIn('injured_name', keys_multi)
        self.assertIn('injury_type', keys_multi)

    def test_3_mcr_pr_bond_and_bail_surety_jail_constraints(self):
        """
        Step 6.3: Confirm MCR -> PR Bond and Bail -> Surety/Jail reveal logic works and is
        enforced if bypassed at the model/database constraint level.
        """
        case = CaseRecord.objects.create(
            id='test-case-remand-1',
            module_key='crime',
            title='Test Remand Constraints',
            case_number='CR/101/2026',
            station_name='Pune PS'
        )
        person = CasesPerson.objects.create(
            case=case,
            role='accused',
            name='Ramesh Patil'
        )

        # Case A: Valid Remand - MCR=True and PR Bond=True
        remand_valid = RemandCustody.objects.create(
            person=person,
            mcr=True,
            pr_bond=True,
            bail=True,
            surety_name='Suresh Patil',
            jail=False
        )
        self.assertTrue(remand_valid.pr_bond)
        self.assertTrue(remand_valid.mcr)
        remand_valid.delete()

        # Case B: Invalid Remand - PR Bond=True but MCR=False -> Rejected by DB constraint
        with self.assertRaises((IntegrityError, ValueError)):
            with transaction.atomic():
                RemandCustody.objects.create(
                    person=person,
                    mcr=False,
                    pr_bond=True
                )

        # Case C: Invalid Remand - Surety Name set but Bail=False -> Rejected by DB constraint
        with self.assertRaises((IntegrityError, ValueError)):
            with transaction.atomic():
                RemandCustody.objects.create(
                    person=person,
                    bail=False,
                    surety_name='Suresh Patil'
                )

        # Case D: Invalid Remand - Jail set but MCR=False -> Rejected by DB constraint
        with self.assertRaises((IntegrityError, ValueError)):
            with transaction.atomic():
                RemandCustody.objects.create(
                    person=person,
                    mcr=False,
                    jail=True
                )

        # Case E: Invalid Remand - PR Bond Date set but PR Bond=False -> Rejected by DB constraint
        with self.assertRaises((IntegrityError, ValueError)):
            with transaction.atomic():
                RemandCustody.objects.create(
                    person=person,
                    mcr=True,
                    pr_bond=False,
                    pr_bond_date=timezone.now().date()
                )

        # Case F: Invalid Remand - Jail Date set but Jail=False -> Rejected by DB constraint
        with self.assertRaises((IntegrityError, ValueError)):
            with transaction.atomic():
                RemandCustody.objects.create(
                    person=person,
                    mcr=True,
                    jail=False,
                    jail_date=timezone.now().date()
                )

        # Case G: Valid Remand with PR Bond Date and Jail Date
        remand_dates = RemandCustody.objects.create(
            person=person,
            mcr=True,
            pr_bond=True,
            pr_bond_date=timezone.now().date(),
            jail=True,
            jail_date=timezone.now().date()
        )
        self.assertIsNotNone(remand_dates.pr_bond_date)
        self.assertIsNotNone(remand_dates.jail_date)
        remand_dates.delete()

    def test_4_tab_without_extras_and_standalone_categories(self):
        """
        1. Open a tab with NO extra template configured (e.g. Hurt category with just baseline)
           -> confirm it only shows the 88 shared fields, and none of Murder's extras.
        2. Confirm A.D., Suicide, and N.C. do NOT show this Common Form.
        """
        # Category with only baseline template
        form_def_hurt = get_form_definition(category_id=self.cat_hurt.category_id)
        hurt_keys = [f['field_key'] for f in form_def_hurt['fields']]
        self.assertIn('cr_number', hurt_keys)
        self.assertNotIn('deceased_name', hurt_keys)
        self.assertNotIn('inquest_panchanama', hurt_keys)
        self.assertNotIn('injured_name', hurt_keys)

        # Standalone categories
        for cat in [self.cat_ad, self.cat_suicide, self.cat_nc]:
            form_def = get_form_definition(category_id=cat.category_id)
            self.assertEqual(len(form_def['fields']), 0, f"Category {cat.category_name} should not have Common Form fields")

    def test_5_preventive_action_multi_provision_and_duplicate_rejection(self):
        """
        Step 6.5: Confirm Preventive Action:
        - Select 107 CrPC/126 BNSS with date -> saves.
        - Add second provision 93 Prohibition Act -> saves as separate row.
        - Trying to add 107 CrPC/126 BNSS a second time to same case is rejected (duplicate).
        """
        case = CaseRecord.objects.create(
            id='test-case-prev-1',
            module_key='crime',
            title='Test Preventive Actions',
            case_number='CR/102/2026',
            station_name='Pune PS'
        )

        person = CasesPerson.objects.create(
            case=case,
            role='accused',
            name='Ramesh Patil'
        )

        today = timezone.now().date()

        # 1. Add first provision for person
        pa1 = PreventiveActionItems.objects.create(
            case=case,
            person=person,
            action_type='107 CrPC/126 BNSS',
            action_date=today,
            outward_number='OUT/101'
        )
        self.assertEqual(pa1.action_type, '107 CrPC/126 BNSS')

        # 2. Add second provision for person on same case
        pa2 = PreventiveActionItems.objects.create(
            case=case,
            person=person,
            action_type='93 Prohibition Act',
            action_date=today,
            outward_number='OUT/102'
        )
        self.assertEqual(pa2.action_type, '93 Prohibition Act')

        # 3. Both exist on the same case
        self.assertEqual(PreventiveActionItems.objects.filter(case=case).count(), 2)

        # 4. Duplicate same provision on same person and case must fail
        with self.assertRaises(IntegrityError):
            with transaction.atomic():
                PreventiveActionItems.objects.create(
                    case=case,
                    person=person,
                    action_type='107 CrPC/126 BNSS',
                    action_date=today,
                    outward_number='OUT/103'
                )

    def test_6_procedural_checklist_independent_datetimes_and_multi_check(self):
        """
        Step 6.6: Confirm Procedural Checklist:
        - Check Spot Panchanama with Date & Time -> saves correctly.
        - Check Memorandum Panchanama with independent Date & Time -> both rows exist without conflict.
        """
        case = CaseRecord.objects.create(
            id='test-case-proc-1',
            module_key='crime',
            title='Test Procedural Checklist',
            case_number='CR/103/2026',
            station_name='Pune PS'
        )

        dt1 = timezone.now()
        dt2 = timezone.now() + timezone.timedelta(hours=2)

        # 1. Spot Panchanama
        p1 = ProceduralChecklist.objects.create(
            case=case,
            item_name='Spot Panchanama',
            is_checked=True,
            event_datetime=dt1
        )
        # 2. Memorandum Panchanama
        p2 = ProceduralChecklist.objects.create(
            case=case,
            item_name='Memorandum Panchanama',
            is_checked=True,
            event_datetime=dt2
        )

        self.assertEqual(ProceduralChecklist.objects.filter(case=case).count(), 2)
        self.assertEqual(p1.event_datetime, dt1)
        self.assertEqual(p2.event_datetime, dt2)

    def test_7_full_case_crud_api_lifecycle(self):
        """
        Step 6.7: Full End-to-End API CRUD Lifecycle:
        - POST /api/cases/ with full relational payload (all sections)
        - GET /api/cases/{id}/ returns all relational entities
        - PUT /api/cases/{id}/ updates atomically
        - GET /api/cases/{id}/pdf/ returns PDF report data
        - GET /api/categories/{id}/cases/ lists category cases
        """
        now = timezone.now()
        today = now.date()

        case_payload = {
            'id': 'case-e2e-full-1',
            'module_key': 'crime',
            'title': 'Robbery and Hurt Incident',
            'case_number': 'CR/2026/9999',
            'station_name': 'Shivajinagar PS',
            'status': 'Pending',
            'priority': 'High',
            'incident_date': str(now),
            'category_ids': [self.cat_murder.category_id],
            'registration_info': {
                'cr_number': '9999/2026',
                'registered_datetime': str(now),
                'is_unknown_accused': False
            },
            'crime_spot': {
                'village_town': 'Pune',
                'area_name': 'FC Road',
                'full_address': 'Shop 4, FC Road, Pune',
                'occurrence_datetime': str(now)
            },
            'responsibility': {
                'io_name': 'Insp. Jadhav',
                'io_designation': 'PI',
                'registered_by_name': 'HC Shinde',
                'registered_by_designation': 'HC'
            },
            'charges': [
                {'act_id': self.act_bns.act_id, 'section_id': self.sec_murder.section_id},
                {'act_id': self.act_bns.act_id, 'section_id': self.sec_hurt.section_id},
            ],
            'persons': [
                {
                    'role': 'complainant',
                    'name': 'Ganesh K',
                    'age': 35,
                    'gender': 'Male',
                    'mobile': '9876543210',
                    'address': 'Pune'
                },
                {
                    'role': 'accused',
                    'name': 'Vikram Singh',
                    'age': 28,
                    'gender': 'Male',
                    'mobile': '9123456780',
                    'address': 'Mumbai',
                    'arrest_status': {
                        'arrest_datetime': str(now),
                        'sec_47_48_bnss': True,
                        'relative_friend_name': 'Sunil Singh',
                        'relative_friend_relation': 'Brother'
                    },
                    'remand_custody': {
                        'pcr_days': 3,
                        'mcr': True,
                        'pr_bond': True,
                        'bail': True,
                        'surety_name': 'Sunil Singh',
                        'jail': False
                    }
                }
            ],
            'cctv_technical': {
                'cctv_checked': True,
                'cdr_sent_date': str(today),
                'cdr_received_date': str(today)
            },
            'procedural_checklists': [
                {'item_name': 'Spot Panchanama', 'is_checked': True, 'event_datetime': str(now)},
                {'item_name': 'Memorandum Panchanama', 'is_checked': True, 'event_datetime': str(now)}
            ],
            'forensics': {
                'e_shakshya': True,
                'fingerprint_taken': True,
                'nafis_fingerprint': True
            },
            'seizures': [
                {'description': 'Gold Chain 10 grams', 'name': 'Vikram Singh'}
            ],
            'preventive_actions': [
                {'action_type': '107 CrPC/126 BNSS', 'action_date': str(today), 'outward_number': 'OUT-999'}
            ],
            'preventive_bond': {
                'bond_date': str(today)
            },
            'scrutiny_pipeline': {
                'sdpo_acp_send_date': str(today)
            },
            'final_verdict': {
                'charge_sheet_no': 'CS-2026-001'
            }
        }

        # 1. POST /api/cases/
        post_res = self.client.post('/api/cases/', data=case_payload, content_type='application/json')
        self.assertEqual(post_res.status_code, status.HTTP_201_CREATED)
        created_data = post_res.json()
        self.assertEqual(created_data['id'], 'case-e2e-full-1')
        self.assertEqual(len(created_data['charges']), 2)
        self.assertEqual(len(created_data['persons']), 2)
        self.assertEqual(created_data['registration_info']['cr_number'], '9999/2026')
        self.assertEqual(created_data['crime_spot']['area_name'], 'FC Road')

        # 2. GET /api/cases/{id}/
        get_res = self.client.get('/api/cases/case-e2e-full-1/')
        self.assertEqual(get_res.status_code, status.HTTP_200_OK)
        fetched_data = get_res.json()
        self.assertEqual(fetched_data['title'], 'Robbery and Hurt Incident')
        self.assertEqual(fetched_data['forensics']['e_shakshya'], True)
        self.assertEqual(fetched_data['final_verdict']['charge_sheet_no'], 'CS-2026-001')

        # 3. PUT /api/cases/{id}/
        update_payload = {
            'title': 'Robbery and Hurt Incident (Updated)',
            'status': 'Disposal',
            'final_verdict': {
                'charge_sheet_no': 'CS-2026-001-FINAL',
                'a_final_number': 'A-99'
            }
        }
        put_res = self.client.put('/api/cases/case-e2e-full-1/', data=update_payload, content_type='application/json')
        self.assertEqual(put_res.status_code, status.HTTP_200_OK)
        updated_data = put_res.json()
        self.assertEqual(updated_data['title'], 'Robbery and Hurt Incident (Updated)')
        self.assertEqual(updated_data['status'], 'Disposal')
        self.assertEqual(updated_data['final_verdict']['charge_sheet_no'], 'CS-2026-001-FINAL')
        self.assertEqual(updated_data['final_verdict']['a_final_number'], 'A-99')

        # 4. GET /api/cases/{id}/pdf/
        pdf_res = self.client.get('/api/cases/case-e2e-full-1/pdf/')
        self.assertEqual(pdf_res.status_code, status.HTTP_200_OK)
        pdf_json = pdf_res.json()
        self.assertIn('case_summary', pdf_json)
        self.assertIn('police_station', pdf_json)

        # 5. GET /api/categories/{id}/cases/
        cat_cases_res = self.client.get(f'/api/categories/{self.cat_murder.category_id}/cases/')
        self.assertEqual(cat_cases_res.status_code, status.HTTP_200_OK)
        cat_json = cat_cases_res.json()
        self.assertEqual(cat_json['total_cases'], 1)
        self.assertEqual(cat_json['cases'][0]['id'], 'case-e2e-full-1')

    def test_8_arrest_pick_or_type_new_person(self):
        """
        Arrest:
        1. Type a brand-new name -> creates a real CasesPerson row with role='accused'
           and that new person shows up in the case's Accused list.
        2. Pick an EXISTING accused -> reuses existing person_id, no duplicate created.
        """
        now = timezone.now()
        case = CaseRecord.objects.create(
            id='test-case-arrest-1',
            module_key='crime',
            title='Test Arrest Person Resolution',
            case_number='CR/201/2026',
            station_name='Pune PS'
        )

        # 1. Type a brand-new name in Arrest
        payload_new = {
            'arrests': [
                {
                    'typed_name': 'Anil Patil',
                    'arrest_datetime': str(now),
                    'sec_47_48_bnss': True,
                    'relative_friend_name': 'Sanjay Patil',
                    'relative_friend_relation': 'Father'
                }
            ]
        }
        res_new = self.client.put(f'/api/cases/{case.id}/', data=payload_new, content_type='application/json')
        self.assertEqual(res_new.status_code, status.HTTP_200_OK)

        # Confirm CasesPerson row was created with role='accused'
        accused_persons = CasesPerson.objects.filter(case=case, role='accused')
        self.assertEqual(accused_persons.count(), 1)
        person_anil = accused_persons.first()
        self.assertEqual(person_anil.name, 'Anil Patil')

        # Confirm ArrestReleaseStatus is linked to this person
        arrest_record = ArrestReleaseStatus.objects.filter(person=person_anil).first()
        self.assertIsNotNone(arrest_record)
        self.assertTrue(arrest_record.sec_47_48_bnss)

        # 2. Pick an EXISTING accused from dropdown
        payload_existing = {
            'arrests': [
                {
                    'existing_person_id': person_anil.person_id,
                    'arrest_datetime': str(now),
                    'sec_47_48_bnss': True,
                    'relative_friend_name': 'Sanjay Patil (Updated)',
                    'relative_friend_relation': 'Father'
                }
            ]
        }
        res_exist = self.client.put(f'/api/cases/{case.id}/', data=payload_existing, content_type='application/json')
        self.assertEqual(res_exist.status_code, status.HTTP_200_OK)

        # Confirm no duplicate person created
        self.assertEqual(CasesPerson.objects.filter(case=case, role='accused').count(), 1)
        arrest_updated = ArrestReleaseStatus.objects.filter(person=person_anil).first()
        self.assertEqual(arrest_updated.relative_friend_name, 'Sanjay Patil (Updated)')

    def test_9_discharge_pick_or_type_new_person(self):
        """
        Discharge:
        1. Type a brand-new name -> creates a real CasesPerson row and links DischargeStatus.
        2. Pick an existing accused -> reuses existing person_id without duplication.
        """
        case = CaseRecord.objects.create(
            id='test-case-discharge-1',
            module_key='crime',
            title='Test Discharge Person Resolution',
            case_number='CR/202/2026',
            station_name='Pune PS'
        )

        # 1. Type a brand-new name in Discharge
        payload_new = {
            'discharges': [
                {
                    'typed_name': 'Deepak Shinde',
                    'is_discharged': True
                }
            ]
        }
        res_new = self.client.put(f'/api/cases/{case.id}/', data=payload_new, content_type='application/json')
        self.assertEqual(res_new.status_code, status.HTTP_200_OK)

        # Confirm CasesPerson row was created
        with TenantContext('maharashtra'):
            person_deepak = CasesPerson.objects.filter(case=case, name='Deepak Shinde').first()
            self.assertIsNotNone(person_deepak)
            self.assertEqual(person_deepak.role, 'accused')

            # Confirm DischargeStatus is linked
            dis_record = DischargeStatus.objects.filter(person=person_deepak).first()
            self.assertIsNotNone(dis_record)
            self.assertTrue(dis_record.is_discharged)

        # 2. Pick EXISTING accused
        payload_exist = {
            'discharges': [
                {
                    'existing_person_id': person_deepak.person_id,
                    'is_discharged': True
                }
            ]
        }
        res_exist = self.client.put(f'/api/cases/{case.id}/', data=payload_exist, content_type='application/json')
        self.assertEqual(res_exist.status_code, status.HTTP_200_OK)
        self.assertEqual(CasesPerson.objects.filter(case=case, name='Deepak Shinde').count(), 1)

    def test_10_seizure_pick_or_type_new_person_and_query(self):
        """
        Seizure:
        1. Pick an existing accused -> seized_from_person_id is set correctly.
        2. Type a brand-new name -> new CasesPerson row created and linked via seized_from_person_id.
        3. Querying SELECT * FROM seizure_records WHERE seized_from_person_id = <id>
           correctly returns items seized from that exact accused.
        """
        case = CaseRecord.objects.create(
            id='test-case-seizure-1',
            module_key='crime',
            title='Test Seizure Person Resolution',
            case_number='CR/203/2026',
            station_name='Pune PS'
        )

        # Existing accused
        existing_accused = CasesPerson.objects.create(
            case=case,
            role='accused',
            name='Vijay Kadam'
        )

        # 1. Seizure from existing accused + Seizure from brand-new typed name
        payload = {
            'seizures': [
                {
                    'description': 'Mobile Phone Samsung Galaxy',
                    'existing_person_id': existing_accused.person_id,
                },
                {
                    'description': 'Cash INR 50000',
                    'typed_name': 'Kailash Deshmukh',
                }
            ]
        }
        res = self.client.put(f'/api/cases/{case.id}/', data=payload, content_type='application/json')
        self.assertEqual(res.status_code, status.HTTP_200_OK)

        # Check Seizure 1 (Existing accused)
        s1 = SeizureRecords.objects.filter(case=case, description='Mobile Phone Samsung Galaxy').first()
        self.assertIsNotNone(s1)
        self.assertEqual(s1.seized_from_person_id, existing_accused.person_id)
        self.assertEqual(s1.name, 'Vijay Kadam')

        # Check Seizure 2 (Brand-new typed name)
        s2 = SeizureRecords.objects.filter(case=case, description='Cash INR 50000').first()
        self.assertIsNotNone(s2)
        self.assertEqual(s2.name, 'Kailash Deshmukh')
        self.assertIsNotNone(s2.seized_from_person_id)

        # Confirm new person was created in CasesPerson
        new_person = CasesPerson.objects.filter(case=case, name='Kailash Deshmukh').first()
        self.assertIsNotNone(new_person)
        self.assertEqual(s2.seized_from_person_id, new_person.person_id)

        # 3. Query items seized from exact accused
        vijay_seizures = SeizureRecords.objects.filter(seized_from_person_id=existing_accused.person_id)
        self.assertEqual(vijay_seizures.count(), 1)
        self.assertEqual(vijay_seizures.first().description, 'Mobile Phone Samsung Galaxy')

        kailash_seizures = SeizureRecords.objects.filter(seized_from_person_id=new_person.person_id)
        self.assertEqual(kailash_seizures.count(), 1)
        self.assertEqual(kailash_seizures.first().description, 'Cash INR 50000')

    def test_11_court_filing_auto_disposal_status(self):
        """
        Part E:
        If ANY of the 8 Court Filing fields is filled:
        A Final Number, B Final Number, C Final Number, NC Final Number,
        Abeted Summary No., CC/ST Number, Stay by High Court Date, Quashed by High Court Date,
        then cases_caserecord.status must automatically be set to 'Disposal'.
        If none of these fields are filled, status stays 'Pending'.
        """
        import uuid
        # Case 1: Status Pending, fill in only "CC/ST Number", save, confirm status becomes 'Disposal'
        case_id_1 = str(uuid.uuid4())
        payload_1 = {
            'id': case_id_1,
            'case_number': f'CR/TEST-DISP-1-{uuid.uuid4().hex[:4]}',
            'title': 'Test Case With CC/ST Number',
            'station_name': 'Test Station',
            'status': 'Pending',
            'court_filing': {
                'cc_st_number': 'CC/1024/2026',
            }
        }
        res_1 = self.client.post('/api/cases/', data=json.dumps(payload_1), content_type='application/json')
        self.assertEqual(res_1.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res_1.data.get('status'), 'Disposal')

        case_1_db = CaseRecord.objects.get(pk=case_id_1)
        self.assertEqual(case_1_db.status, 'Disposal')

        # Case 2: Status Pending, none of the 8 fields filled, confirm status stays 'Pending'
        case_id_2 = str(uuid.uuid4())
        payload_2 = {
            'id': case_id_2,
            'case_number': f'CR/TEST-DISP-2-{uuid.uuid4().hex[:4]}',
            'title': 'Test Case With No Court Filing Fields',
            'station_name': 'Test Station',
            'status': 'Pending',
            'court_filing': {}
        }
        res_2 = self.client.post('/api/cases/', data=json.dumps(payload_2), content_type='application/json')
        self.assertEqual(res_2.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res_2.data.get('status'), 'Pending')

        case_2_db = CaseRecord.objects.get(pk=case_id_2)
        self.assertEqual(case_2_db.status, 'Pending')

    def test_12_multiple_accused_suspected_unidentified_arrest(self):
        """
        Part H:
        Confirm saving multiple Accused, Suspected Accused, Unidentified Accused, and Arrest records
        and reloading preserves all entries properly.
        """
        import uuid
        case_id = str(uuid.uuid4())
        payload = {
            'id': case_id,
            'case_number': f'CR/TEST-MUL-{uuid.uuid4().hex[:4]}',
            'title': 'Test Case Multiple Persons',
            'station_name': 'Test Station',
            'status': 'Pending',
            'accused': [
                {'name': 'Accused Person One', 'age': '28', 'gender': 'Male'},
                {'name': 'Accused Person Two', 'age': '35', 'gender': 'Female'},
            ],
            'suspectedAccused': [
                {'name': 'Suspected One', 'age': '30', 'gender': 'Male'},
                {'name': 'Suspected Two', 'age': '40', 'gender': 'Female'},
            ],
            'unidentifiedList': [
                {'description': 'Unknown Suspect 1', 'gender': 'Male', 'approxAge': '25-30'},
                {'description': 'Unknown Suspect 2', 'gender': 'Female', 'approxAge': '30-35'},
            ],
            'arrests': [
                {
                    'typed_name': 'Accused Person One',
                    'arrest_datetime': '2026-09-15 10:00',
                    'sec_47_48_bnss': True,
                    'relative_friend_name': 'Friend John',
                },
                {
                    'typed_name': 'Accused Person Two',
                    'arrest_datetime': '2026-09-16 11:30',
                    'release_on_notice': True,
                    'release_on_notice_datetime': '2026-09-16 14:00',
                },
            ]
        }
        res = self.client.post('/api/cases/', data=json.dumps(payload), content_type='application/json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)

        # Retrieve case
        get_res = self.client.get(f'/api/cases/{case_id}/')
        self.assertEqual(get_res.status_code, status.HTTP_200_OK)

        # Check DB Records
        acc_persons = CasesPerson.objects.filter(case_id=case_id, role='accused')
        self.assertEqual(acc_persons.count(), 2)

        susp_persons = CasesPerson.objects.filter(case_id=case_id, role='suspected_accused')
        self.assertEqual(susp_persons.count(), 2)

        unid_persons = CasesPerson.objects.filter(case_id=case_id, role='unidentified')
        self.assertEqual(unid_persons.count(), 2)

        arrests = ArrestReleaseStatus.objects.filter(person__case_id=case_id)
        self.assertEqual(arrests.count(), 2)

    def test_13_unknown_accused_repeating_list(self):
        """
        Part I:
        Convert Unknown Accused into a repeating list.
        2 separate entries on one test case both save as CasesPerson rows with role='unknown_accused',
        and both come back on reload.
        """
        import uuid
        case_id = str(uuid.uuid4())
        payload = {
            'id': case_id,
            'case_number': f'CR/TEST-UNK-{uuid.uuid4().hex[:4]}',
            'title': 'Test Case Unknown Accused List',
            'station_name': 'Test Station',
            'status': 'Pending',
            'unknown_accused': [
                {'name': 'Unknown Accused #1', 'role': 'unknown_accused'},
                {'name': 'Unknown Accused #2', 'role': 'unknown_accused'},
            ]
        }
        res = self.client.post('/api/cases/', data=json.dumps(payload), content_type='application/json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)

        # Confirm 2 CasesPerson rows with role='unknown_accused'
        unk_persons = CasesPerson.objects.filter(case_id=case_id, role='unknown_accused')
        self.assertEqual(unk_persons.count(), 2)
        names = set(unk_persons.values_list('name', flat=True))
        self.assertIn('Unknown Accused #1', names)
        self.assertIn('Unknown Accused #2', names)

        # Retrieve and verify reload
        get_res = self.client.get(f'/api/cases/{case_id}/')
        self.assertEqual(get_res.status_code, status.HTTP_200_OK)
        persons_returned = get_res.data.get('persons', [])
        unk_returned = [p for p in persons_returned if p.get('role') == 'unknown_accused']
        self.assertEqual(len(unk_returned), 2)

    def test_14_twin_categories_and_nested_accident_tabs(self):
        """
        Tests for twin category resolution across standalone and group tabs:
        1. Case saved from standalone row appears under group tab and vice versa.
        2. Counters count each case once (DISTINCT).
        3. Tabs with no twins work normally.
        4. Nested Accident tabs (and sub-tabs) roll up correctly across twin branches.
        """
        import uuid
        from apps.crimetab.services.counter_service import (
            get_twin_category_ids,
            get_descendant_category_ids,
            get_category_counters,
            get_group_counters,
        )

        # 1. Setup Twin Theft Categories (Standalone + Group 1-5)
        theft_group = CaseCategory.objects.create(
            group=self.group_1to5,
            category_name='Theft',
            category_code='119',
            template=self.baseline_tmpl,
            display_order=10
        )
        theft_standalone = CaseCategory.objects.create(
            group=None,
            category_name='Theft',
            category_code='STAND_THEFT',
            template=self.baseline_tmpl,
            display_order=20
        )

        # Verify helper get_twin_category_ids
        twins_from_group = get_twin_category_ids(theft_group.category_id)
        twins_from_stand = get_twin_category_ids(theft_standalone.category_id)
        self.assertEqual(set(twins_from_group), {theft_group.category_id, theft_standalone.category_id})
        self.assertEqual(set(twins_from_stand), {theft_group.category_id, theft_standalone.category_id})

        # 2. Case A: Saved from standalone Theft
        case_a_id = str(uuid.uuid4())
        case_a = CaseRecord.objects.create(
            id=case_a_id,
            case_number=f'CR/THEFT-STAND-{uuid.uuid4().hex[:4]}',
            title='Standalone Theft Case',
            station_name='Test Station',
            status='Pending',
            sub_category='Theft',
        )
        CaseCategoryLink.objects.create(case=case_a, category=theft_standalone, is_primary=True)

        # 3. Case B: Saved from group Theft
        case_b_id = str(uuid.uuid4())
        case_b = CaseRecord.objects.create(
            id=case_b_id,
            case_number=f'CR/THEFT-GRP-{uuid.uuid4().hex[:4]}',
            title='Group Theft Case',
            station_name='Test Station',
            status='Pending',
            sub_category='Theft',
        )
        CaseCategoryLink.objects.create(case=case_b, category=theft_group, is_primary=True)

        # Test Case A and B appear under BOTH endpoints:
        # GET /api/categories/{group_id}/cases/
        res_group_cases = self.client.get(f'/api/categories/{theft_group.category_id}/cases/')
        self.assertEqual(res_group_cases.status_code, status.HTTP_200_OK)
        group_case_ids = {c['id'] for c in res_group_cases.data['cases']}
        self.assertIn(case_a_id, group_case_ids, "Case saved from standalone should appear under group tab")
        self.assertIn(case_b_id, group_case_ids, "Case saved from group should appear under group tab")
        self.assertEqual(res_group_cases.data['total_cases'], 2)

        # GET /api/categories/{standalone_id}/cases/
        res_stand_cases = self.client.get(f'/api/categories/{theft_standalone.category_id}/cases/')
        self.assertEqual(res_stand_cases.status_code, status.HTTP_200_OK)
        stand_case_ids = {c['id'] for c in res_stand_cases.data['cases']}
        self.assertIn(case_a_id, stand_case_ids, "Case saved from standalone should appear under standalone tab")
        self.assertIn(case_b_id, stand_case_ids, "Case saved from group should appear under standalone tab")
        self.assertEqual(res_stand_cases.data['total_cases'], 2)

        # Check counters count distinct (each case counted once)
        cnt_group = get_category_counters(theft_group.category_id)
        cnt_stand = get_category_counters(theft_standalone.category_id)
        self.assertEqual(cnt_group['total'], 2)
        self.assertEqual(cnt_stand['total'], 2)

        # 4. Tab with NO twin (Single tab only)
        single_cat = CaseCategory.objects.create(
            group=None,
            category_name='SingleUnmatchedTab',
            category_code='STAND_SINGLE',
            display_order=30
        )
        case_c_id = str(uuid.uuid4())
        case_c = CaseRecord.objects.create(
            id=case_c_id,
            case_number=f'CR/SINGLE-{uuid.uuid4().hex[:4]}',
            title='Single Tab Case',
            station_name='Test Station',
            status='Pending',
            sub_category='SingleUnmatchedTab',
        )
        CaseCategoryLink.objects.create(case=case_c, category=single_cat, is_primary=True)

        twins_single = get_twin_category_ids(single_cat.category_id)
        self.assertEqual(twins_single, [single_cat.category_id])

        res_single = self.client.get(f'/api/categories/{single_cat.category_id}/cases/')
        self.assertEqual(res_single.status_code, status.HTTP_200_OK)
        self.assertEqual(res_single.data['total_cases'], 1)
        self.assertEqual(res_single.data['cases'][0]['id'], case_c_id)

        cnt_single = get_category_counters(single_cat.category_id)
        self.assertEqual(cnt_single['total'], 1)

        # 5. Nested Accident tabs (Group Accident + Standalone Accident + Child tabs)
        accident_group = CaseCategory.objects.create(
            group=self.group_1to5,
            category_name='Accident',
            category_code='126',
            display_order=40
        )
        accident_stand = CaseCategory.objects.create(
            group=None,
            category_name='Accident',
            category_code='STAND_ACCIDENT',
            display_order=50
        )

        road_acc_group = CaseCategory.objects.create(
            parent_category=accident_group,
            category_name='Road Accident',
            category_code='201',
            display_order=1
        )
        road_acc_stand = CaseCategory.objects.create(
            parent_category=accident_stand,
            category_name='Road Accident',
            category_code='STAND_ROAD_ACC',
            display_order=1
        )

        rash_driving_child = CaseCategory.objects.create(
            parent_category=road_acc_group,
            category_name='Death Due to Rash Driving',
            category_code='301',
            display_order=1
        )

        # Save an accident case linked to the grandchild "Death Due to Rash Driving"
        case_d_id = str(uuid.uuid4())
        case_d = CaseRecord.objects.create(
            id=case_d_id,
            case_number=f'CR/ACC-RASH-{uuid.uuid4().hex[:4]}',
            title='Rash Driving Incident',
            station_name='Test Station',
            status='Pending',
            sub_category='Death Due to Rash Driving',
        )
        CaseCategoryLink.objects.create(case=case_d, category=rash_driving_child, is_primary=True)

        # Descendant IDs of standalone Accident must include child & grandchild from both branches
        descendants_stand_acc = get_descendant_category_ids(accident_stand.category_id)
        self.assertIn(accident_group.category_id, descendants_stand_acc)
        self.assertIn(accident_stand.category_id, descendants_stand_acc)
        self.assertIn(road_acc_group.category_id, descendants_stand_acc)
        self.assertIn(road_acc_stand.category_id, descendants_stand_acc)
        self.assertIn(rash_driving_child.category_id, descendants_stand_acc)

        # GET cases on standalone Accident returns case_d
        res_stand_acc_cases = self.client.get(f'/api/categories/{accident_stand.category_id}/cases/')
        self.assertEqual(res_stand_acc_cases.status_code, status.HTTP_200_OK)
        self.assertEqual(res_stand_acc_cases.data['total_cases'], 1)
        self.assertEqual(res_stand_acc_cases.data['cases'][0]['id'], case_d_id)

        # GET cases on group Accident returns case_d
        res_grp_acc_cases = self.client.get(f'/api/categories/{accident_group.category_id}/cases/')
        self.assertEqual(res_grp_acc_cases.status_code, status.HTTP_200_OK)
        self.assertEqual(res_grp_acc_cases.data['total_cases'], 1)

        # GET /api/categories/{id}/children/ on standalone Accident returns Road Accident
        res_stand_children = self.client.get(f'/api/categories/{accident_stand.category_id}/children/')
        self.assertEqual(res_stand_children.status_code, status.HTTP_200_OK)
        child_names = [c['category_name'] for c in res_stand_children.data]
        self.assertIn('Road Accident', child_names)
        self.assertEqual(child_names.count('Road Accident'), 1, "Child should not be duplicated")
        self.assertTrue(res_stand_children.data[0]['has_children'])
        self.assertEqual(res_stand_children.data[0]['counters']['total'], 1)

    def test_charges_hydration_and_preservation_on_edit(self):
        """
        Verify:
        1. Create a case with 2 charges (e.g. IPC Murder 302 + Hurt 323).
        2. Open it for EDIT (GET details).
        3. Confirm both charges show correctly pre-selected/hydrated in charges list.
        4. Re-save/update without changes (PUT /api/cases/{id}/), confirm both charges are STILL there on reload, not lost or duplicated.
        """
        import uuid
        case_id = str(uuid.uuid4())

        # Ensure Act and Sections exist
        with TenantContext('maharashtra'):
            act, _ = Act.objects.get_or_create(act_name='Indian Penal Code')
            sec_murder, _ = ActSection.objects.get_or_create(act=act, section_number='302', defaults={'section_title': 'Punishment for murder'})
            sec_hurt, _ = ActSection.objects.get_or_create(act=act, section_number='323', defaults={'section_title': 'Punishment for voluntarily causing hurt'})

            act_id = act.act_id
            sec_murder_id = sec_murder.section_id
            sec_hurt_id = sec_hurt.section_id

        create_payload = {
            'id': case_id,
            'case_number': f'CR/TEST-CHARGES-{uuid.uuid4().hex[:4]}',
            'title': 'Test Multiple Charges Hydration',
            'station_name': 'Test Station',
            'status': 'Under Investigation',
            'charges': [
                {'act_id': act_id, 'section_id': sec_murder_id, 'section_number': '302', 'act_name': 'Indian Penal Code'},
                {'act_id': act_id, 'section_id': sec_hurt_id, 'section_number': '323', 'act_name': 'Indian Penal Code'},
            ]
        }

        # 1. Create case with 2 charges
        res = self.client.post('/api/cases/', data=json.dumps(create_payload), content_type='application/json')
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)

        # Confirm 2 charges saved in DB
        with TenantContext('maharashtra'):
            db_charges = CrimeCaseActsSections.objects.filter(case_id=case_id)
            self.assertEqual(db_charges.count(), 2)

        # 2. Fetch case for EDIT
        get_res = self.client.get(f'/api/cases/{case_id}/')
        self.assertEqual(get_res.status_code, status.HTTP_200_OK)
        fetched_charges = get_res.data.get('charges', [])
        
        # 3. Confirm both charges show correctly, pre-selected
        self.assertEqual(len(fetched_charges), 2)
        sec_numbers = {c.get('section_number') for c in fetched_charges}
        self.assertIn('302', sec_numbers)
        self.assertIn('323', sec_numbers)

        # 4. Save without changing anything (simulate Edit screen Submit)
        update_payload = dict(get_res.data)
        update_payload['charges'] = fetched_charges
        put_res = self.client.put(f'/api/cases/{case_id}/', data=json.dumps(update_payload), content_type='application/json')
        self.assertEqual(put_res.status_code, status.HTTP_200_OK)

        # 5. Reload and verify both charges STILL exist (not lost, not duplicated)
        reload_res = self.client.get(f'/api/cases/{case_id}/')
        self.assertEqual(reload_res.status_code, status.HTTP_200_OK)
        reloaded_charges = reload_res.data.get('charges', [])
        self.assertEqual(len(reloaded_charges), 2)
        reloaded_sec_numbers = {c.get('section_number') for c in reloaded_charges}
        self.assertEqual(reloaded_sec_numbers, {'302', '323'})
        with TenantContext('maharashtra'):
            self.assertEqual(CrimeCaseActsSections.objects.filter(case_id=case_id).count(), 2)

    def test_category_with_slash_in_name_routes_and_access(self):
        """
        Verify that categories with '/' in their name (e.g. 'Two/Four Wheeler Theft', 'Sec 156(3)/175(3)(BNSS)'):
        1. Open children and form-definition via ID-based routes:
           /api/categories/<int:category_id>/children/
           /api/categories/<int:category_id>/form-definition/
           for both group row and standalone row.
        2. Open children and form-definition via name-based path routes:
           /api/categories/<path:name>/children/
           /api/categories/<path:name>/form-definition/
           supporting encoded ('Two%2FFour%20Wheeler%20Theft') and decoded slashes.
        """
        import uuid
        from urllib.parse import quote

        # 1. Create Group and Standalone twin categories with '/' in their names
        theft_grp = CaseCategory.objects.create(
            category_name="Two/Four Wheeler Theft",
            category_code="TWO_FOUR_WHEELER_THEFT_GRP",
            group=self.group_1to5,
            display_order=100,
            is_active=True,
        )
        theft_stand = CaseCategory.objects.create(
            category_name="Two/Four Wheeler Theft",
            category_code="TWO_FOUR_WHEELER_THEFT_STAND",
            group=None,
            display_order=100,
            is_active=True,
        )

        # Create child under group category
        child_two = CaseCategory.objects.create(
            category_name="Two Wheeler Theft",
            category_code="TWO_WHEELER_THEFT",
            parent_category=theft_grp,
            group=self.group_1to5,
            is_active=True,
        )
        child_four = CaseCategory.objects.create(
            category_name="Four Wheeler Theft",
            category_code="FOUR_WHEELER_THEFT",
            parent_category=theft_stand,
            is_active=True,
        )

        # 2. Test ID-based routes for Group row
        res_grp_id_children = self.client.get(f'/api/categories/{theft_grp.category_id}/children/')
        self.assertEqual(res_grp_id_children.status_code, status.HTTP_200_OK)
        grp_child_names = [c['category_name'] for c in res_grp_id_children.data]
        self.assertIn("Two Wheeler Theft", grp_child_names)
        self.assertIn("Four Wheeler Theft", grp_child_names)

        res_grp_id_form = self.client.get(f'/api/categories/{theft_grp.category_id}/form-definition/')
        self.assertEqual(res_grp_id_form.status_code, status.HTTP_200_OK)
        self.assertEqual(res_grp_id_form.data['category_id'], theft_grp.category_id)
        self.assertIn('fields', res_grp_id_form.data)

        # 3. Test ID-based routes for Standalone row
        res_stand_id_children = self.client.get(f'/api/categories/{theft_stand.category_id}/children/')
        self.assertEqual(res_stand_id_children.status_code, status.HTTP_200_OK)
        stand_child_names = [c['category_name'] for c in res_stand_id_children.data]
        self.assertIn("Two Wheeler Theft", stand_child_names)
        self.assertIn("Four Wheeler Theft", stand_child_names)

        res_stand_id_form = self.client.get(f'/api/categories/{theft_stand.category_id}/form-definition/')
        self.assertEqual(res_stand_id_form.status_code, status.HTTP_200_OK)
        self.assertEqual(res_stand_id_form.data['category_id'], theft_stand.category_id)
        self.assertIn('fields', res_stand_id_form.data)

        # 4. Test Name-based routes with slashes
        # A) Decoded slash URL: /api/categories/Two/Four Wheeler Theft/children/
        res_name_children = self.client.get('/api/categories/Two/Four Wheeler Theft/children/')
        self.assertEqual(res_name_children.status_code, status.HTTP_200_OK)
        self.assertTrue(len(res_name_children.data) >= 2)

        res_name_form = self.client.get('/api/categories/Two/Four Wheeler Theft/form-definition/')
        self.assertEqual(res_name_form.status_code, status.HTTP_200_OK)
        self.assertIn('fields', res_name_form.data)

        # B) Encoded slash URL: /api/categories/Two%2FFour%20Wheeler%20Theft/form-definition/
        encoded_name = quote("Two/Four Wheeler Theft", safe='')
        res_enc_children = self.client.get(f'/api/categories/{encoded_name}/children/')
        self.assertEqual(res_enc_children.status_code, status.HTTP_200_OK)

        res_enc_form = self.client.get(f'/api/categories/{encoded_name}/form-definition/')
        self.assertEqual(res_enc_form.status_code, status.HTTP_200_OK)

        # 5. Test another tab with complex slash name: 'Sec 156(3)/175(3)(BNSS)'
        sec_cat = CaseCategory.objects.create(
            category_name="Sec 156(3)/175(3)(BNSS)",
            category_code="SEC_156_3_175_3_BNSS",
            group=None,
            is_active=True,
        )
        res_sec_id_form = self.client.get(f'/api/categories/{sec_cat.category_id}/form-definition/')
        self.assertEqual(res_sec_id_form.status_code, status.HTTP_200_OK)

        res_sec_name_form = self.client.get('/api/categories/Sec 156(3)/175(3)(BNSS)/form-definition/')
        self.assertEqual(res_sec_name_form.status_code, status.HTTP_200_OK)


class CounterServiceTests(TestCase):
    def setUp(self):
        from apps.core.tenancy import set_tenant_schema
        from apps.public_master.models import StateRegistry
        StateRegistry.objects.get_or_create(
            state_code='MH',
            defaults={'state_name': 'Maharashtra', 'schema_name': 'maharashtra', 'is_active': True}
        )
        set_tenant_schema('maharashtra')
        self.group = CaseCategoryGroup.objects.create(group_name='Test Group', group_code='TEST_GRP', display_order=1)
        self.cat1 = CaseCategory.objects.create(category_name='Cat 1', category_code='CAT1', group=self.group)

    def test_get_category_counters_no_name_error(self):
        try:
            get_category_counters(self.cat1.category_id)
        except NameError as e:
            self.fail(f"NameError unexpectedly: {e}")


class AccidentSubcategoriesMigrationTests(TestCase):
    """
    Tests the 0025 accident subcategories and template links migration:
    1. Run on a fresh database twice (verifying initial insertion and idempotency).
    2. Run on an existing project copy twice (verifying 0 changes / no duplicates).
    """
    def setUp(self):
        import importlib
        migration_mod = importlib.import_module('apps.crimetab.migrations.0025_accident_subcategories_and_template_links')
        self.apply_fn = migration_mod.apply_accident_subcategories
        self.reverse_fn = migration_mod.reverse_accident_subcategories

        # Clean slate for test
        CategoryFieldTemplate.objects.all().delete()
        CaseCategory.objects.all().delete()
        CaseCategoryGroup.objects.all().delete()

        # Seed groups
        self.group_1to5 = CaseCategoryGroup.objects.create(
            group_id=1, group_name='1 to 5', group_code='I TO V', display_order=1
        )
        self.group_part6 = CaseCategoryGroup.objects.create(
            group_id=2, group_name='Part 6', group_code='VI', display_order=2
        )

        # Baseline Template
        self.baseline_tmpl = FieldTemplate.objects.create(
            template_id=1,
            template_name='Common Form Baseline Template'
        )

        # Seed 1-to-5 base categories including Group Accident
        self.grp_accident = CaseCategory.objects.create(
            category_id=26,
            category_name='Accident',
            category_code='126',
            group=self.group_1to5,
            display_order=26,
            is_active=True
        )

        # Seed 22 Standalone tabs (19 standard + 3 exempt: A.D., Suicide, N.C.)
        standalone_names = [
            'Theft', 'Kidnapping', 'Hurt', 'Sand Theft', 'Two/Four Wheeler Theft',
            'Missing', 'Crime Against Women', 'Accident', 'Sec 156(3)/175(3)(BNSS)', 'Coin',
            'Suicide', 'A.D.', 'N.C.',
            'ST Drugs', 'Prohibition', 'Gambling', 'POCSO', 'NDPS',
            'Gowansh', 'IT Act', 'M.V Act', 'UAPA'
        ]
        self.standalone_categories = []
        for idx, name in enumerate(standalone_names, start=29):
            cat = CaseCategory.objects.create(
                category_id=idx,
                category_name=name,
                category_code=f'STAND_{idx}',
                group=None,
                display_order=idx,
                is_active=True
            )
            self.standalone_categories.append(cat)

    def test_fresh_database_run_twice(self):
        """
        Simulate fresh database:
        - Before: 23 categories (1 group Accident + 22 standalone tabs).
        - Run 1: Adds 8 subcategories (4 group + 4 standalone) and links 27 templates (19 standalone + 8 subcategories).
        - Run 2: Exactly same row counts (idempotent).
        """
        from django.apps import apps
        from django.db import connection

        class DummySchemaEditor:
            def __init__(self, conn):
                self.connection = conn

        schema_editor = DummySchemaEditor(connection)

        # --- BEFORE RUN 1 ---
        cat_count_before = CaseCategory.objects.count()
        cft_count_before = CategoryFieldTemplate.objects.count()
        self.assertEqual(cat_count_before, 23)
        self.assertEqual(cft_count_before, 0)

        # --- RUN 1 (Fresh Database) ---
        self.apply_fn(apps, schema_editor)

        cat_count_after_1 = CaseCategory.objects.count()
        cft_count_after_1 = CategoryFieldTemplate.objects.count()

        # 23 initial + 8 new accident subcategories = 31
        self.assertEqual(cat_count_after_1, 31)
        # 19 standalone tabs (22 minus AD, Suicide, NC) + 6 accident subcategories = 25 links (Road Accident is NOT linked)
        self.assertEqual(cft_count_after_1, 25)

        # Verify Accident hierarchy structure
        # Group 1 subcategories
        grp_norm = CaseCategory.objects.get(category_name='Normal Accident', group=self.group_1to5)
        self.assertEqual(grp_norm.category_code, 'ACC_NORMAL')
        self.assertEqual(grp_norm.parent_category, self.grp_accident)
        self.assertEqual(grp_norm.display_order, 1)

        grp_road = CaseCategory.objects.get(category_name='Road Accident', group=self.group_1to5)
        self.assertEqual(grp_road.category_code, 'ACC_ROAD')
        self.assertEqual(grp_road.parent_category, self.grp_accident)
        self.assertEqual(grp_road.display_order, 2)
        # Road Accident intentionally has NO Common Form link
        self.assertFalse(CategoryFieldTemplate.objects.filter(category=grp_road).exists())

        grp_rash = CaseCategory.objects.get(category_name='Death Due to Rash Driving', group=self.group_1to5)
        self.assertEqual(grp_rash.category_code, 'ACC_RASH')
        self.assertEqual(grp_rash.parent_category, grp_road)

        grp_other = CaseCategory.objects.get(category_name='Other Road Accident', group=self.group_1to5)
        self.assertEqual(grp_other.category_code, 'ACC_OTHER')
        self.assertEqual(grp_other.parent_category, grp_road)

        # Standalone subcategories
        stand_accident = CaseCategory.objects.get(category_name='Accident', group__isnull=True, parent_category__isnull=True)
        stand_norm = CaseCategory.objects.get(category_name='Normal Accident', group__isnull=True)
        self.assertEqual(stand_norm.category_code, 'STAND_ACC_NORMAL')
        self.assertEqual(stand_norm.parent_category, stand_accident)

        stand_road = CaseCategory.objects.get(category_name='Road Accident', group__isnull=True)
        self.assertEqual(stand_road.category_code, 'STAND_ACC_ROAD')
        self.assertEqual(stand_road.parent_category, stand_accident)
        # Road Accident intentionally has NO Common Form link
        self.assertFalse(CategoryFieldTemplate.objects.filter(category=stand_road).exists())

        stand_rash = CaseCategory.objects.get(category_name='Death Due to Rash Driving', group__isnull=True)
        self.assertEqual(stand_rash.category_code, 'STAND_ACC_RASH')
        self.assertEqual(stand_rash.parent_category, stand_road)

        stand_other = CaseCategory.objects.get(category_name='Other Road Accident', group__isnull=True)
        self.assertEqual(stand_other.category_code, 'STAND_ACC_OTHER')
        self.assertEqual(stand_other.parent_category, stand_road)

        # --- RUN 2 (Idempotency Check on fresh database) ---
        self.apply_fn(apps, schema_editor)

        cat_count_after_2 = CaseCategory.objects.count()
        cft_count_after_2 = CategoryFieldTemplate.objects.count()
        self.assertEqual(cat_count_after_2, 31)
        self.assertEqual(cft_count_after_2, 25)

    def test_existing_project_copy_run_twice(self):
        """
        Simulate user project copy where rows already exist:
        - Setup: Pre-populate the 8 Accident subcategories and all 25 links.
        - Run 1: Must make 0 changes (row counts before == after).
        - Run 2: Must make 0 changes (row counts before == after).
        """
        from django.apps import apps
        from django.db import connection

        class DummySchemaEditor:
            def __init__(self, conn):
                self.connection = conn

        schema_editor = DummySchemaEditor(connection)

        # Pre-apply migration once to establish existing project state
        self.apply_fn(apps, schema_editor)

        cat_count_existing = CaseCategory.objects.count()
        cft_count_existing = CategoryFieldTemplate.objects.count()
        self.assertEqual(cat_count_existing, 31)
        self.assertEqual(cft_count_existing, 25)

        # --- RUN 1 on Existing Project Copy ---
        self.apply_fn(apps, schema_editor)
        self.assertEqual(CaseCategory.objects.count(), cat_count_existing)
        self.assertEqual(CategoryFieldTemplate.objects.count(), cft_count_existing)

        # --- RUN 2 on Existing Project Copy ---
        self.apply_fn(apps, schema_editor)
        self.assertEqual(CaseCategory.objects.count(), cat_count_existing)
        self.assertEqual(CategoryFieldTemplate.objects.count(), cft_count_existing)

    def test_reverse_migration(self):
        from django.apps import apps
        from django.db import connection

        class DummySchemaEditor:
            def __init__(self, conn):
                self.connection = conn

        schema_editor = DummySchemaEditor(connection)

        # Apply migration
        self.apply_fn(apps, schema_editor)
        self.assertEqual(CaseCategory.objects.count(), 31)

        # Reverse migration
        self.reverse_fn(apps, schema_editor)
        # Should be back to initial 23 categories
        self.assertEqual(CaseCategory.objects.count(), 23)
        self.assertFalse(
            CaseCategory.objects.filter(
                category_name__in=['Normal Accident', 'Road Accident', 'Death Due to Rash Driving', 'Other Road Accident']
            ).exists()
        )


class UnlinkedCategoryFormDefinitionTests(TestCase):
    def setUp(self):
        from apps.public_master.models import StateRegistry
        StateRegistry.objects.get_or_create(
            state_code='MH',
            defaults={'state_name': 'Maharashtra', 'schema_name': 'maharashtra', 'is_active': True}
        )
        self.tenant_ctx = TenantContext('maharashtra')
        self.tenant_ctx.__enter__()
        self.client = Client(HTTP_X_STATE_CODE='MH')

    def tearDown(self):
        self.tenant_ctx.__exit__(None, None, None)

    def test_unlinked_category_returns_empty_fields_and_no_baseline(self):
        unlinked_cat = CaseCategory.objects.create(
            category_name='Test Unlinked Tab',
            category_code='STAND_UNLINKED',
            group=None,
            template=None,
            display_order=99,
            is_active=True
        )

        # 1. Test Service function directly
        form_def = get_form_definition(unlinked_cat.category_id)
        self.assertEqual(form_def['category_id'], unlinked_cat.category_id)
        self.assertEqual(form_def['fields'], [])
        self.assertEqual(form_def['fields_count'], 0)
        self.assertFalse(form_def['has_linked_bundle'])
        self.assertFalse(form_def['has_common_form_baseline'])

        # 2. Test API Endpoint by ID
        resp = self.client.get(f'/api/categories/{unlinked_cat.category_id}/form-definition/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        data = resp.json()
        self.assertEqual(data['fields'], [])
        self.assertEqual(data['fields_count'], 0)
        self.assertFalse(data['has_linked_bundle'])
        self.assertFalse(data['has_common_form_baseline'])

        # 3. Test API Endpoint by Name
        resp_name = self.client.get('/api/categories/Test Unlinked Tab/form-definition/')
        self.assertEqual(resp_name.status_code, status.HTTP_200_OK)
        self.assertEqual(resp_name.json()['fields'], [])

    def test_unknown_category_returns_404_never_baseline_fallback(self):
        resp = self.client.get('/api/categories/NonExistentCategoryXYZ/form-definition/')
        self.assertEqual(resp.status_code, status.HTTP_404_NOT_FOUND)


class EnginePrerequisitesTests(TestCase):
    def setUp(self):
        from apps.core.tenancy import TenantContext
        from apps.crimetab.models.dynamic_engine import OptionValue, FieldTemplate, FieldTemplateField, CategoryFieldTemplate
        from apps.crimetab.models.groupings import CaseCategory

        self.tenant_ctx = TenantContext('maharashtra')
        self.tenant_ctx.__enter__()
        self.client = Client(HTTP_X_STATE_CODE='MH')

        OptionValue.objects.all().delete()
        FieldTemplateField.objects.all().delete()
        CategoryFieldTemplate.objects.all().delete()
        FieldTemplate.objects.all().delete()

    def tearDown(self):
        if hasattr(self, 'tenant_ctx'):
            self.tenant_ctx.__exit__(None, None, None)

    def test_field_template_field_conditional_and_radio_support(self):
        from apps.crimetab.models.dynamic_engine import FieldTemplate, FieldTemplateField, CategoryFieldTemplate
        from apps.crimetab.models.groupings import CaseCategory

        tmpl = FieldTemplate.objects.create(template_name='RTI Template')
        parent_field = FieldTemplateField.objects.create(
            template=tmpl,
            field_label='Applicant Type',
            field_key='applicant_type',
            field_source='custom',
            field_type='radio',
            display_order=10,
            options_source='/api/options/applicant_types/'
        )
        child_field = FieldTemplateField.objects.create(
            template=tmpl,
            field_label='Bar Registration Number',
            field_key='bar_reg_no',
            field_source='custom',
            field_type='text',
            display_order=20,
            depends_on_field_key='applicant_type',
            depends_on_value='Advocate'
        )

        cat = CaseCategory.objects.create(
            category_name='RTI Requests',
            category_code='RTI_REQ',
            display_order=1,
            is_active=True
        )
        CategoryFieldTemplate.objects.create(category=cat, template=tmpl)

        form_def = get_form_definition(cat.category_id)
        fields = form_def['fields']
        self.assertEqual(len(fields), 2)

        p = [f for f in fields if f['field_key'] == 'applicant_type'][0]
        self.assertEqual(p['field_type'], 'radio')
        self.assertEqual(p['options_source'], '/api/options/applicant_types/')
        self.assertIsNone(p['depends_on_field_key'])
        self.assertIsNone(p['depends_on_value'])

        c = [f for f in fields if f['field_key'] == 'bar_reg_no'][0]
        self.assertEqual(c['depends_on_field_key'], 'applicant_type')
        self.assertEqual(c['depends_on_value'], 'Advocate')

    def test_option_values_model_and_endpoint(self):
        from apps.crimetab.models.dynamic_engine import OptionValue

        OptionValue.objects.create(
            option_group='rti_mode_of_receipt',
            option_value='By Post / Courier',
            display_order=20,
            is_active=True
        )
        OptionValue.objects.create(
            option_group='rti_mode_of_receipt',
            option_value='In Person / Physical',
            display_order=10,
            is_active=True
        )
        OptionValue.objects.create(
            option_group='rti_mode_of_receipt',
            option_value='Inactive Deprecated Option',
            display_order=5,
            is_active=False
        )

        # Query GET /api/options/<group>/
        resp = self.client.get('/api/options/rti_mode_of_receipt/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        data = resp.json()

        # Should only contain active options sorted by display_order
        self.assertEqual(data, ['In Person / Physical', 'By Post / Courier'])

    def test_unknown_group_returns_empty_list_never_500(self):
        resp = self.client.get('/api/options/completely_unknown_group_xyz/')
        self.assertEqual(resp.status_code, status.HTTP_200_OK)
        self.assertEqual(resp.json(), [])

    def test_migration_0026_sql_is_safe_to_run_twice(self):
        import importlib
        from django.db import connection
        mig = importlib.import_module('apps.crimetab.migrations.0026_remove_general_crime_baseline_template')
        sql_up = mig.SQL_REMOVE_GENERAL_CRIME_BASELINE_TEMPLATE

        if connection.vendor == 'postgresql':
            with connection.cursor() as cursor:
                # First run
                cursor.execute(sql_up)
                # Second run (must not raise error)
                cursor.execute(sql_up)

        # Non-postgresql / ORM test run
        from django.apps import apps as django_apps
        from apps.crimetab.models.dynamic_engine import FieldTemplate
        editor = type('DummyEditor', (), {'connection': connection})()
        # First execution
        mig.remove_general_crime_baseline_template(django_apps, editor)
        # Second execution (second run changes nothing and passes cleanly)
        mig.remove_general_crime_baseline_template(django_apps, editor)
        self.assertFalse(FieldTemplate.objects.filter(template_name='General Crime Baseline Template').exists())

    def test_migration_0027_sql_is_safe_to_run_twice(self):
        import importlib
        from django.db import connection
        mig = importlib.import_module('apps.crimetab.migrations.0027_add_dynamic_engine_conditional_fields_and_option_values')
        sql_up = mig.SQL_IDEMPOTENT_UP

        if connection.vendor == 'postgresql':
            with connection.cursor() as cursor:
                # First run
                cursor.execute(sql_up)
                # Second run (must not raise error)
                cursor.execute(sql_up)

    def test_rti_form_definition_and_seed_data(self):
        import importlib
        from django.apps import apps as django_apps
        from django.db import connection
        mig29 = importlib.import_module('apps.crimetab.migrations.0029_add_rti_category_template_and_seed_data')
        editor = type('DummyEditor', (), {'connection': connection})()
        # Run seed migration twice to ensure idempotency (second run changes nothing)
        mig29.seed_rti_data(django_apps, editor)
        mig29.seed_rti_data(django_apps, editor)

        from apps.crimetab.models import CaseCategory, FieldTemplate, CategoryFieldTemplate, FieldTemplateField, ModuleSetting, OptionValue
        from apps.public_master.models import Permission

        # 1. 4 Permissions
        self.assertTrue(Permission.objects.filter(id='rti:create').exists())
        self.assertTrue(Permission.objects.filter(id='rti:view').exists())
        self.assertTrue(Permission.objects.filter(id='rti:update').exists())
        self.assertTrue(Permission.objects.filter(id='rti:pdf').exists())

        # 2. RTI Tab row
        cat = CaseCategory.objects.get(category_name='RTI')
        self.assertEqual(cat.category_code, 'STAND_RTI')

        # 3. "RTI Form" bundle
        tmpl = FieldTemplate.objects.get(template_name='RTI Form')

        # 4. Link
        self.assertTrue(CategoryFieldTemplate.objects.filter(category=cat, template=tmpl).exists())

        # 5. 20 Fields
        self.assertEqual(FieldTemplateField.objects.filter(template=tmpl).count(), 20)

        # Form definition integration check
        form_def = get_form_definition(cat.category_id)
        fields = form_def['fields']
        self.assertEqual(len(fields), 20)
        keys = [f['field_key'] for f in fields]
        self.assertIn('rti_received_date', keys)
        self.assertIn('rti_applicant_name', keys)
        self.assertNotIn('cr_number', keys)
        self.assertNotIn('complainant_name', keys)

        # 6. Verify module settings
        self.assertEqual(ModuleSetting.objects.get(module_key='rti', setting_key='due_days').setting_value, '30')
        self.assertEqual(ModuleSetting.objects.get(module_key='common', setting_key='no_form_message').setting_value, 'No form configured for this tab')

        # 7. Verify option values
        self.assertTrue(OptionValue.objects.filter(option_group='rti_mode_of_receipt', option_value='Online').exists())
        self.assertTrue(OptionValue.objects.filter(option_group='rti_info_type', option_value='Crime record').exists())
        self.assertTrue(OptionValue.objects.filter(option_group='rti_outcome', option_value='Replied').exists())


class RTIAPIEndpointsTests(TestCase):
    def setUp(self):
        from django.db import connection
        if connection.connection and hasattr(connection.connection, 'closed') and connection.connection.closed:
            connection.connect()

        from apps.public_master.models import StateRegistry
        StateRegistry.objects.get_or_create(
            state_code='MH',
            defaults={'state_name': 'Maharashtra', 'schema_name': 'maharashtra', 'is_active': True}
        )
        self.tenant_ctx = TenantContext('maharashtra')
        self.tenant_ctx.__enter__()

        import importlib
        from django.apps import apps as django_apps
        mig29 = importlib.import_module('apps.crimetab.migrations.0029_add_rti_category_template_and_seed_data')
        mig31 = importlib.import_module('apps.crimetab.migrations.0031_add_rti_enforce_permissions_setting')
        editor = type('DummyEditor', (), {'connection': connection})()
        mig29.seed_rti_data(django_apps, editor)
        mig31.seed_enforce_permissions(django_apps, editor)

        # Create Officers
        from apps.users.models import OfficerProfile
        self.officer1 = OfficerProfile.objects.create(
            uid='officer_station_a_1',
            email='patil@cyber.gov.in',
            name='Inspector Ramesh Patil',
            designation='PI',
            station_name='Cyber Police Station',
            account_status='active',
            role_id='officer'
        )
        self.officer2 = OfficerProfile.objects.create(
            uid='officer_station_b_1',
            email='pawar@sadar.gov.in',
            name='Sub Inspector Suresh Pawar',
            designation='PSI',
            station_name='Sadar Police Station',
            account_status='active',
            role_id='officer'
        )

        self.client = Client(HTTP_X_STATE_CODE='MH')

    def tearDown(self):
        self.tenant_ctx.__exit__(None, None, None)

    def _auth_headers(self, officer, state_code='MH'):
        import jwt
        from django.conf import settings
        payload = {'uid': officer.uid, 'state_code': state_code, 'user_type': 'officer'}
        token = jwt.encode(payload, settings.SECRET_KEY, algorithm='HS256')
        return {'HTTP_AUTHORIZATION': f'Bearer {token}', 'HTTP_X_STATE_CODE': state_code}

    def test_unauthenticated_returns_401(self):
        resp = self.client.get('/api/rti/')
        self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_authenticated_user_without_grant_can_crud_when_enforce_permissions_false(self):
        # Force enforce_permissions = false
        ModuleSetting.objects.filter(module_key='rti', setting_key='enforce_permissions').update(setting_value='false')

        headers1 = self._auth_headers(self.officer1)

        # 1. Create
        payload = {
            'received_date': '2026-10-01',
            'due_date': '2026-10-31',
            'mode_of_receipt': 'Online',
            'applicant_name': 'Anil Sharma',
            'applicant_age': 35,
            'mobile_no': '9876543210',
            'address': 'Flat 101, MG Road, Pune',
            'email': 'anil@example.com',
            'info_type': 'Crime record',
            'assigned_officer_uid': self.officer1.uid,
            'rti_outcome': 'Replied',
            'replied_date': '2026-10-15',
            'remark': 'Provided copy of FIR',
            'appealed': False
        }
        create_resp = self.client.post('/api/rti/', data=json.dumps(payload), content_type='application/json', **headers1)
        self.assertEqual(create_resp.status_code, status.HTTP_201_CREATED)
        rti_data = create_resp.json()
        rti_id = rti_data['rti_id']
        self.assertEqual(rti_data['serial_display'], 'RTI-2026/1')
        self.assertEqual(rti_data['status'], 'Disposal')

        # 2. List
        list_resp = self.client.get('/api/rti/', **headers1)
        self.assertEqual(list_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(list_resp.json()['count'], 1)

        # 3. Counts
        counts_resp = self.client.get('/api/rti/counts/', **headers1)
        self.assertEqual(counts_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(counts_resp.json()['total'], 1)

        # 4. View
        detail_resp = self.client.get(f'/api/rti/{rti_id}/', **headers1)
        self.assertEqual(detail_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(detail_resp.json()['applicant_name'], 'Anil Sharma')

        # 5. Edit (PATCH)
        patch_resp = self.client.patch(f'/api/rti/{rti_id}/', data=json.dumps({'remark': 'Updated remark text'}), content_type='application/json', **headers1)
        self.assertEqual(patch_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(patch_resp.json()['remark'], 'Updated remark text')

        # 6. PDF
        pdf_resp = self.client.get(f'/api/rti/{rti_id}/pdf/', **headers1)
        self.assertEqual(pdf_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(pdf_resp['Content-Type'], 'application/pdf')

    def test_user_gets_403_when_enforce_permissions_true_without_grant(self):
        # Force enforce_permissions = true
        ModuleSetting.objects.filter(module_key='rti', setting_key='enforce_permissions').update(setting_value='true')

        headers1 = self._auth_headers(self.officer1)

        # Create -> 403
        payload = {
            'received_date': '2026-10-01',
            'mode_of_receipt': 'Online',
            'applicant_name': 'Rahul Verma',
            'address': 'Deccan, Pune',
            'info_type': 'Personal',
            'assigned_officer_uid': self.officer1.uid,
        }
        self.assertEqual(self.client.post('/api/rti/', data=json.dumps(payload), content_type='application/json', **headers1).status_code, status.HTTP_403_FORBIDDEN)
        self.assertEqual(self.client.get('/api/rti/', **headers1).status_code, status.HTTP_403_FORBIDDEN)
        self.assertEqual(self.client.get('/api/rti/counts/', **headers1).status_code, status.HTTP_403_FORBIDDEN)

    def test_station_boundary_isolation(self):
        ModuleSetting.objects.filter(module_key='rti', setting_key='enforce_permissions').update(setting_value='false')

        headers1 = self._auth_headers(self.officer1)
        headers2 = self._auth_headers(self.officer2)

        # Officer 1 in Cyber Station creates RTI
        payload = {
            'received_date': '2026-10-01',
            'mode_of_receipt': 'Online',
            'applicant_name': 'Cyber Station Applicant',
            'address': 'Cyber Cell Pune',
            'info_type': 'Crime record',
            'assigned_officer_uid': self.officer1.uid,
        }
        res = self.client.post('/api/rti/', data=json.dumps(payload), content_type='application/json', **headers1)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        rti_id = res.json()['rti_id']

        # Officer 2 in Sadar Station attempts to view/list
        list_res = self.client.get('/api/rti/', **headers2)
        self.assertEqual(list_res.json()['count'], 0) # Cannot see Cyber Station applications!
        self.assertEqual(self.client.get(f'/api/rti/{rti_id}/', **headers2).status_code, status.HTTP_404_NOT_FOUND)

    def test_outcome_partial_patch_conflict_returns_400(self):
        ModuleSetting.objects.filter(module_key='rti', setting_key='enforce_permissions').update(setting_value='false')
        headers1 = self._auth_headers(self.officer1)

        payload = {
            'received_date': '2026-10-01',
            'mode_of_receipt': 'Online',
            'applicant_name': 'Priya Deshmukh',
            'address': 'Kothrud, Pune',
            'info_type': 'Personal',
            'assigned_officer_uid': self.officer1.uid,
            'rti_outcome': 'Replied',
            'replied_date': '2026-10-05',
        }
        res = self.client.post('/api/rti/', data=json.dumps(payload), content_type='application/json', **headers1)
        rti_id = res.json()['rti_id']

        # Patch attempting to fill rejected_date while replied_date exists -> conflict!
        patch_res = self.client.patch(f'/api/rti/{rti_id}/', data=json.dumps({'rejected_date': '2026-10-10'}), content_type='application/json', **headers1)
        self.assertEqual(patch_res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('Invalid outcome', patch_res.json()['error'])

    def test_no_hardcoding_module_settings_dynamic_behavior(self):
        ModuleSetting.objects.filter(module_key='rti', setting_key='enforce_permissions').update(setting_value='false')
        headers1 = self._auth_headers(self.officer1)

        # 1. Dynamically change due_days from 30 to 15
        ModuleSetting.objects.filter(module_key='rti', setting_key='due_days').update(setting_value='15')
        payload = {
            'received_date': '2026-10-01',
            'mode_of_receipt': 'Online',
            'applicant_name': 'Dynamic Test Applicant',
            'address': 'Kothrud, Pune',
            'info_type': 'Crime record',
            'assigned_officer_uid': self.officer1.uid,
        }
        res1 = self.client.post('/api/rti/', data=json.dumps(payload), content_type='application/json', **headers1)
        self.assertEqual(res1.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res1.json()['due_date'], '2026-10-16') # 15 days after 2026-10-01!

        # 2. Dynamically change serial_prefix and serial_format
        ModuleSetting.objects.filter(module_key='rti', setting_key='serial_prefix').update(setting_value='RTI-MH')
        ModuleSetting.objects.filter(module_key='rti', setting_key='serial_format').update(setting_value='{prefix}/{year}#{serial_no:04d}')
        res2 = self.client.get(f"/api/rti/{res1.json()['rti_id']}/", **headers1)
        self.assertEqual(res2.json()['serial_display'], 'RTI-MH/2026#0001')

        # 3. Dynamically change max_words_remark from 20 to 3
        ModuleSetting.objects.filter(module_key='rti', setting_key='max_words_remark').update(setting_value='3')
        patch_payload = {'remark': 'This remark contains five words total.'}
        patch_res = self.client.patch(f"/api/rti/{res1.json()['rti_id']}/", data=json.dumps(patch_payload), content_type='application/json', **headers1)
        self.assertEqual(patch_res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('remark exceeds maximum limit of 3 words', patch_res.json()['error'])

    def test_counts_cache_invalidated_on_create_and_edit(self):
        ModuleSetting.objects.filter(module_key='rti', setting_key='enforce_permissions').update(setting_value='false')
        headers1 = self._auth_headers(self.officer1)

        # 1. Fetch counts (populates cache)
        counts1 = self.client.get('/api/rti/counts/', **headers1).json()
        self.assertEqual(counts1['total'], 0)

        # 2. Create application -> clears cache and updates total count
        payload = {
            'received_date': '2026-10-01',
            'mode_of_receipt': 'Online',
            'applicant_name': 'Cache Test Applicant',
            'address': 'Shivajinagar, Pune',
            'info_type': 'Crime record',
            'assigned_officer_uid': self.officer1.uid,
        }
        create_res = self.client.post('/api/rti/', data=json.dumps(payload), content_type='application/json', **headers1)
        rti_id = create_res.json()['rti_id']

        counts2 = self.client.get('/api/rti/counts/', **headers1).json()
        self.assertEqual(counts2['total'], 1)
        self.assertEqual(counts2['pending'], 1)
        self.assertEqual(counts2['disposal'], 0)

        # 3. Edit application (Add replied_date -> moves to disposal) -> clears cache and updates pending/disposal counts
        self.client.patch(f'/api/rti/{rti_id}/', data=json.dumps({'rti_outcome': 'Replied', 'replied_date': '2026-10-10'}), content_type='application/json', **headers1)

        counts3 = self.client.get('/api/rti/counts/', **headers1).json()
        self.assertEqual(counts3['total'], 1)
        self.assertEqual(counts3['pending'], 0)
        self.assertEqual(counts3['disposal'], 1)

    def test_rti_officers_endpoint_station_isolation_and_formatting(self):
        from apps.users.models import OfficerProfile

        # Setup Station Chhatrapati (Station A) and Station Sadar (Station B)
        st_a_active_1 = OfficerProfile.objects.create(
            uid='off_chhatrapati_1',
            email='chhat_1@mh.gov.in',
            name='Ramesh Kulkarni',
            designation='PI',
            station_name='Chhatrapati Police Station',
            account_status='active',
            role_id='officer'
        )
        st_a_active_2 = OfficerProfile.objects.create(
            uid='off_chhatrapati_2',
            email='chhat_2@mh.gov.in',
            name='Ganesh Shinde',
            designation='',
            station_name='Chhatrapati Police Station',
            account_status='active',
            role_id='officer'
        )
        st_a_inactive = OfficerProfile.objects.create(
            uid='off_chhatrapati_inactive',
            email='chhat_inact@mh.gov.in',
            name='Inactive Officer',
            designation='PSI',
            station_name='Chhatrapati Police Station',
            account_status='archived',
            role_id='officer'
        )
        st_b_active = OfficerProfile.objects.create(
            uid='off_sadar_1',
            email='sadar_1@mh.gov.in',
            name='Suresh Deshmukh',
            designation='API',
            station_name='Sadar Police Station',
            account_status='active',
            role_id='officer'
        )

        headers_a = self._auth_headers(st_a_active_1)

        # 1. Station A logged-in officer queries /api/rti/officers/
        resp_a = self.client.get('/api/rti/officers/', **headers_a)
        self.assertEqual(resp_a.status_code, status.HTTP_200_OK)
        officers_a = resp_a.json()

        # Must return only 2 active officers of Chhatrapati
        uids_a = [o['uid'] for o in officers_a]
        self.assertIn('off_chhatrapati_1', uids_a)
        self.assertIn('off_chhatrapati_2', uids_a)
        self.assertNotIn('off_chhatrapati_inactive', uids_a, "Inactive officer must be hidden")
        self.assertNotIn('off_sadar_1', uids_a, "Officer of another station must never be returned")

        # 2. Check ready label formatting "Name, Designation"
        off_1_data = next(o for o in officers_a if o['uid'] == 'off_chhatrapati_1')
        self.assertEqual(off_1_data['name'], 'Ramesh Kulkarni')
        self.assertEqual(off_1_data['designation'], 'PI')
        self.assertEqual(off_1_data['label'], 'Ramesh Kulkarni, PI')

        off_2_data = next(o for o in officers_a if o['uid'] == 'off_chhatrapati_2')
        self.assertEqual(off_2_data['name'], 'Ganesh Shinde')
        self.assertEqual(off_2_data['designation'], '')
        self.assertEqual(off_2_data['label'], 'Ganesh Shinde')

        # 3. Station B logged-in officer queries /api/rti/officers/
        headers_b = self._auth_headers(st_b_active)
        resp_b = self.client.get('/api/rti/officers/', **headers_b)
        self.assertEqual(resp_b.status_code, status.HTTP_200_OK)
        officers_b = resp_b.json()

        uids_b = [o['uid'] for o in officers_b]
        self.assertIn('off_sadar_1', uids_b)
        self.assertNotIn('off_chhatrapati_1', uids_b)

        # 4. Trimming and case-folding test (user station with leading/trailing spaces or lowercase)
        st_a_active_1.station_name = ' chhatrapati police station '
        st_a_active_1.save()
        resp_case_insensitive = self.client.get('/api/rti/officers/', **self._auth_headers(st_a_active_1))
        self.assertEqual(resp_case_insensitive.status_code, status.HTTP_200_OK)
        self.assertEqual(len(resp_case_insensitive.json()), 2)






