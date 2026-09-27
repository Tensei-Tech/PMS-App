from django.test import TestCase, Client
from django.utils import timezone
from django.db import transaction, IntegrityError
from rest_framework import status

from apps.cases.models import CaseRecord
from apps.crimetab.models.groupings import CaseCategoryGroup, CaseCategory, CaseCategoryLink
from apps.crimetab.models.dynamic_engine import (
    FieldTemplate,
    FieldTemplateField,
    CategoryFieldTemplate,
    SectionFieldTemplate,
    CaseExtraFieldValue,
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
        from apps.core.tenancy import set_tenant_schema
        from apps.public_master.models import StateRegistry
        StateRegistry.objects.get_or_create(
            state_code='MH',
            defaults={'state_name': 'Maharashtra', 'schema_name': 'maharashtra', 'is_active': True}
        )
        set_tenant_schema('maharashtra')

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

        # Murder extra fields
        FieldTemplateField.objects.get_or_create(
            template=self.tmpl_murder,
            field_key='deceased_name',
            defaults={'field_label': 'Deceased Name', 'field_source': 'custom', 'field_type': 'text', 'display_order': 1000}
        )
        FieldTemplateField.objects.get_or_create(
            template=self.tmpl_murder,
            field_key='inquest_panchanama',
            defaults={'field_label': 'Inquest Panchanama Details', 'field_source': 'custom', 'field_type': 'textarea', 'display_order': 1010}
        )

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

    def test_1_form_renders_common_fields_and_tab_specific_extras_immediately(self):
        """
        Trigger A Fix: Opening Murder tab shows BOTH the shared baseline fields (88)
        AND Murder's own extra fields immediately, with NO section picked yet.
        """
        form_def = get_form_definition(category_id=self.cat_murder.category_id)
        field_keys = [f['field_key'] for f in form_def['fields']]
        # Shared baseline fields
        self.assertIn('cr_number', field_keys)
        self.assertIn('complainant_name', field_keys)
        self.assertIn('accused_name', field_keys)
        # Murder's own extra fields appear immediately
        self.assertIn('deceased_name', field_keys)
        self.assertIn('inquest_panchanama', field_keys)
        # Hurt's extra fields should NOT be present yet
        self.assertNotIn('injured_name', field_keys)

    def test_2_dynamic_multi_charge_layering_without_losing_data(self):
        """
        Trigger B:
        1. Add Murder's section -> confirm no duplicates or breakages.
        2. Add Hurt's section as second charge on the SAME case -> confirm Hurt's dynamic fields
           get appended into the same continuous form without losing Murder's data.
        """
        # 1. Add Murder section charged
        form_def_murder = get_form_definition(
            category_id=self.cat_murder.category_id,
            charged_section_ids=[self.sec_murder.section_id]
        )
        keys_murder = [f['field_key'] for f in form_def_murder['fields']]
        self.assertIn('deceased_name', keys_murder)
        self.assertIn('inquest_panchanama', keys_murder)
        self.assertNotIn('injured_name', keys_murder)

        # 2. Add Hurt section charged on the same case
        form_def_multi = get_form_definition(
            category_id=self.cat_murder.category_id,
            charged_section_ids=[self.sec_murder.section_id, self.sec_hurt.section_id]
        )
        keys_multi = [f['field_key'] for f in form_def_multi['fields']]
        # Both sets of fields must be present in the same continuous form
        self.assertIn('deceased_name', keys_multi)
        self.assertIn('inquest_panchanama', keys_multi)
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

        # Case D: Invalid Remand - Jail set but Bail=False -> Rejected by DB constraint
        with self.assertRaises((IntegrityError, ValueError)):
            with transaction.atomic():
                RemandCustody.objects.create(
                    person=person,
                    bail=False,
                    jail=True
                )

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

        today = timezone.now().date()

        # 1. Add first provision
        pa1 = PreventiveActionItems.objects.create(
            case=case,
            action_type='107 CrPC/126 BNSS',
            action_date=today,
            outward_number='OUT/101'
        )
        self.assertEqual(pa1.action_type, '107 CrPC/126 BNSS')

        # 2. Add second provision to same case
        pa2 = PreventiveActionItems.objects.create(
            case=case,
            action_type='93 Prohibition Act',
            action_date=today,
            outward_number='OUT/102'
        )
        self.assertEqual(pa2.action_type, '93 Prohibition Act')

        # 3. Both exist on the same case
        self.assertEqual(PreventiveActionItems.objects.filter(case=case).count(), 2)

        # 4. Duplicate same provision on same case must fail
        with self.assertRaises(IntegrityError):
            with transaction.atomic():
                PreventiveActionItems.objects.create(
                    case=case,
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
