from django.test import TestCase, TransactionTestCase, override_settings
from django.db import connection
from django.db.migrations.loader import MigrationLoader
from django.db.backends.postgresql.schema import DatabaseSchemaEditor
from unittest.mock import MagicMock
from rest_framework import status
from apps.crimetab.models.dynamic_engine import FieldTemplate, FieldTemplateField, OptionValue
from apps.cases.models import CaseRecord
from apps.crimetab.models.common_form import CasesPerson, ArrestReleaseStatus
import importlib
migration_0037 = importlib.import_module("apps.crimetab.migrations.0037_finalize_common_form_baseline_template")
finalize_baseline_template = migration_0037.finalize_baseline_template
FINAL_BASELINE_FIELDS = migration_0037.FINAL_BASELINE_FIELDS
BASELINE_TEMPLATE_NAME = migration_0037.BASELINE_TEMPLATE_NAME
from apps.crimetab.management.commands.seed_common_form import Command as SeedCommand


class Migration0037ScratchDatabaseTest(TestCase):
    """
    Scratch database test verifying migration 0037 on an isolated SQLite database.
    Ensures zero interaction with live database and validates idempotency and full compliance.
    """

    def setUp(self):
        from apps.core.tenancy import TenantContext
        from apps.public_master.models import StateRegistry
        StateRegistry.objects.get_or_create(
            state_code='MH',
            defaults={'state_name': 'Maharashtra', 'schema_name': 'maharashtra', 'is_active': True}
        )
        self.tenant_ctx = TenantContext('maharashtra')
        self.tenant_ctx.__enter__()
        self.client = self.client_class(HTTP_X_STATE_CODE='MH')

        # 1. Simulate the exact user STATE:
        # A FieldTemplate with a non-1 ID to prove matching is by template_name, never by id.
        self.template = FieldTemplate.objects.create(
            template_id=42,
            template_name=BASELINE_TEMPLATE_NAME
        )

        # 92 fields from initial common_fields with section=None,
        # old 'Physical Description' label, and missing fields absent.
        # We can pull from the seed_common_form common_fields definitions
        raw_initial_92 = [
            ('CR Number', 'cr_number', 'common', 'text', True, 10),
            ('Registration Date & Time', 'registered_datetime', 'common', 'datetime', True, 20),
            ('Unknown Accused Involved', 'is_unknown_accused', 'common', 'checkbox', False, 30),
            ('Village / Town', 'village_town', 'common', 'text', False, 40),
            ('Area Name', 'area_name', 'common', 'text', False, 50),
            ('Crime Spot Full Address', 'full_address', 'common', 'textarea', False, 60),
            ('Occurrence Date & Time', 'occurrence_datetime', 'common', 'datetime', False, 70),
            ('Acts & Sections Filed', 'charges', 'common', 'chips', False, 80),
            ('Complainant Name', 'complainant_name', 'common', 'text', False, 90),
            ('Complainant Age', 'complainant_age', 'common', 'number', False, 100),
            ('Complainant Gender', 'complainant_gender', 'common', 'dropdown', False, 110),
            ('Complainant Occupation', 'complainant_occupation', 'common', 'text', False, 120),
            ('Complainant Mobile', 'complainant_mobile', 'common', 'text', False, 130),
            ('Complainant Aadhaar', 'complainant_aadhaar', 'common', 'text', False, 140),
            ('Complainant PAN', 'complainant_pan', 'common', 'text', False, 150),
            ('Complainant Religion', 'complainant_religion', 'common', 'text', False, 160),
            ('Complainant Caste', 'complainant_caste', 'common', 'text', False, 170),
            ('Complainant Address', 'complainant_address', 'common', 'textarea', False, 180),
            ('Accused Name', 'accused_name', 'common', 'text', False, 190),
            ('Accused Age', 'accused_age', 'common', 'number', False, 200),
            ('Accused Gender', 'accused_gender', 'common', 'dropdown', False, 210),
            ('Accused Occupation', 'accused_occupation', 'common', 'text', False, 220),
            ('Accused Mobile', 'accused_mobile', 'common', 'text', False, 230),
            ('Accused Aadhaar', 'accused_aadhaar', 'common', 'text', False, 240),
            ('Accused PAN', 'accused_pan', 'common', 'text', False, 250),
            ('Accused Religion', 'accused_religion', 'common', 'text', False, 260),
            ('Accused Caste', 'accused_caste', 'common', 'text', False, 270),
            ('Accused Address', 'accused_address', 'common', 'textarea', False, 280),
            ('Approximate Age', 'approximate_age', 'common', 'text', False, 290),
            ('Skin Colour', 'skin_colour', 'common', 'text', False, 300),
            ('Possible Occupation', 'possible_occupation', 'common', 'text', False, 310),
            ('Identification Mark', 'identification_mark', 'common', 'textarea', False, 320),
            ('Height', 'height', 'common', 'text', False, 330),
            ('Physical Description', 'description', 'common', 'textarea', False, 340),  # To be renamed to Description
            ('IO Name', 'io_name', 'common', 'text', False, 350),
            ('IO Designation', 'io_designation', 'common', 'text', False, 360),
            ('Registered By Name', 'registered_by_name', 'common', 'text', False, 370),
            ('Registered By Designation', 'registered_by_designation', 'common', 'text', False, 380),
            ('Arrest Date & Time', 'arrest_datetime', 'common', 'datetime', False, 390),
            ('Sec 47/48 BNSS Complied', 'sec_47_48_bnss', 'common', 'checkbox', False, 400),
            ('Relative / Friend Informed', 'relative_friend_name', 'common', 'text', False, 410),
            ('Relative / Friend Relation', 'relative_friend_relation', 'common', 'text', False, 420),
            ('Release on Notice', 'release_on_notice', 'common', 'checkbox', False, 430),
            ('Release on Notice Date & Time', 'release_on_notice_datetime', 'common', 'datetime', False, 440),
            ('Anticipatory Bail', 'anticipatory_bail', 'common', 'checkbox', False, 450),
            ('Anticipatory Bail Date & Time', 'anticipatory_bail_datetime', 'common', 'datetime', False, 460),
            ('Death of Accused', 'death_of_accused', 'common', 'checkbox', False, 470),
            ('Death of Accused Date & Time', 'death_of_accused_datetime', 'common', 'datetime', False, 480),
            ('PCR (Days)', 'pcr_days', 'common', 'number', False, 490),
            ('MCR', 'mcr', 'common', 'checkbox', False, 500),
            ('PR Bond', 'pr_bond', 'common', 'checkbox', False, 510),
            ('Bail', 'bail', 'common', 'checkbox', False, 520),
            ('Surety Name', 'surety_name', 'common', 'text', False, 530),
            ('Jail', 'jail', 'common', 'checkbox', False, 540),
            ('CCTV Checked', 'cctv_checked', 'common', 'checkbox', False, 550),
            ('CDR Sent Date', 'cdr_sent_date', 'common', 'date', False, 560),
            ('CDR Received Date', 'cdr_received_date', 'common', 'date', False, 570),
            ('Spot Panchanama', 'spot_panchanama', 'common', 'checkbox', False, 580),
            ('Seizure Panchanama', 'seizure_panchanama', 'common', 'checkbox', False, 590),
            ('Search Panchanama', 'search_panchanama', 'common', 'checkbox', False, 600),
            ('Personal Search Panchanama', 'personal_search_panchanama', 'common', 'checkbox', False, 610),
            ('Memorandum Panchanama', 'memorandum_panchanama', 'common', 'checkbox', False, 620),
            ('Identification Panchanama', 'identification_panchanama', 'common', 'checkbox', False, 630),
            ('Identification Parade Panchanama', 'identification_parade_panchanama', 'common', 'checkbox', False, 640),
            ('E-Shakshya', 'e_shakshya', 'common', 'checkbox', False, 650),
            ('Fingerprint Taken', 'fingerprint_taken', 'common', 'checkbox', False, 660),
            ('NAFIS Fingerprint', 'nafis_fingerprint', 'common', 'checkbox', False, 670),
            ('Object Name', 'object_name', 'common', 'text', False, 675),
            ('Seizure Description', 'seizure_description', 'common', 'textarea', False, 680),
            ('Seizure From Whom', 'seizure_person_name', 'common', 'text', False, 690),
            ('Preventive Action Type', 'preventive_action_type', 'common', 'dropdown', False, 700),
            ('Preventive Action Date', 'preventive_action_date', 'common', 'date', False, 710),
            ('Preventive Action Outward No', 'preventive_outward_no', 'common', 'text', False, 720),
            ('Bond Date', 'bond_date', 'common', 'date', False, 730),
            ('Bond Cancellation Date', 'bond_cancellation_date', 'common', 'date', False, 740),
            ('Discharged Accused', 'is_discharged', 'common', 'checkbox', False, 750),
            ('SDPO/ACP Send Date', 'sdpo_acp_send_date', 'common', 'date', False, 760),
            ('SDPO/ACP Grant Date', 'sdpo_acp_grant_date', 'common', 'date', False, 770),
            ('Addl SP/DCP Send Date', 'addl_sp_dcp_send_date', 'common', 'date', False, 780),
            ('Addl SP/DCP Grant Date', 'addl_sp_dcp_grant_date', 'common', 'date', False, 790),
            ('Addl CP Send Date', 'addl_cp_send_date', 'common', 'date', False, 800),
            ('Addl CP Grant Date', 'addl_cp_grant_date', 'common', 'date', False, 810),
            ('APP Send Date', 'app_send_date', 'common', 'date', False, 820),
            ('APP Grant Date', 'app_grant_date', 'common', 'date', False, 830),
            ('Charge Sheet No', 'charge_sheet_no', 'common', 'text', False, 840),
            ('A Final Number', 'a_final_number', 'common', 'text', False, 850),
            ('B Final Number', 'b_final_number', 'common', 'text', False, 860),
            ('C Final Number', 'c_final_number', 'common', 'text', False, 870),
            ('NC Final Number', 'nc_final_number', 'common', 'text', False, 880),
            ('Abeted Summary No', 'abeted_summary_no', 'common', 'text', False, 890),
            ('Stay by High Court Date', 'stay_by_high_court_date', 'common', 'date', False, 900),
            ('Quashed by High Court Date', 'quashed_by_high_court_date', 'common', 'date', False, 910),
        ]

        self.assertEqual(len(raw_initial_92), 92, "Initial state must have exactly 92 fields")

        for label, key, src, ftype, req, order in raw_initial_92:
            FieldTemplateField.objects.create(
                template=self.template,
                field_label=label,
                field_key=key,
                field_source=src,
                field_type=ftype,
                is_required=req,
                section=None,  # No section on any of them
                display_order=order,
            )

    def tearDown(self):
        if hasattr(self, 'tenant_ctx'):
            try:
                self.tenant_ctx.__exit__(None, None, None)
            except Exception:
                pass

    def test_migration_run_and_idempotence(self):
        # Verify initial state: 92 fields, 0 sections
        self.assertEqual(FieldTemplateField.objects.filter(template=self.template).count(), 92)
        self.assertEqual(FieldTemplateField.objects.filter(template=self.template, section__isnull=False).count(), 0)

        # Mock schema_editor
        class MockSchemaEditor:
            connection = connection

        from django.apps import apps

        # Run migration 0037 first time
        finalize_baseline_template(apps, MockSchemaEditor())

        # Verify: Total fields is now 109 (92 existing + 17 added)
        all_fields = FieldTemplateField.objects.filter(template=self.template).order_by('display_order')
        self.assertEqual(all_fields.count(), 109)

        # 1. Verify every field has a section (heading)
        fields_without_section = all_fields.filter(section__isnull=True)
        self.assertEqual(fields_without_section.count(), 0)
        empty_section_fields = all_fields.filter(section='')
        self.assertEqual(empty_section_fields.count(), 0)

        # 2. Verify all missing fields are added
        missing_keys_to_verify = [
            # Suspected Accused (10 fields)
            'suspected_accused_name', 'suspected_accused_age', 'suspected_accused_gender',
            'suspected_accused_occupation', 'suspected_accused_mobile', 'suspected_accused_aadhaar',
            'suspected_accused_pan', 'suspected_accused_religion', 'suspected_accused_caste',
            'suspected_accused_address',
            # Unidentified Accused (2 fields)
            'unidentified_gender', 'unidentified_address',
            # Arrest
            'arrested_person_name',
            # Remand & Custody
            'pr_bond_date', 'jail_date',
            # Discharge Accused
            'discharge_date',
            # Court Filing and Final Summary
            'cc_st_number',
        ]
        self.assertEqual(len(missing_keys_to_verify), 17)
        for key in missing_keys_to_verify:
            field = all_fields.filter(field_key=key).first()
            self.assertIsNotNone(field, f"Missing field {key} was not added")
            self.assertEqual(field.field_source, 'common')
            self.assertFalse(field.is_required, f"Field {key} must have is_required=False")

        # Verify is_required rules: Only CR Number and Registration Date & Time are True
        required_fields = list(all_fields.filter(is_required=True).values_list('field_key', flat=True))
        self.assertEqual(set(required_fields), {'cr_number', 'registered_datetime'})

        # 3. Verify 'Physical Description' renamed to 'Description' (key kept as 'description')
        desc_field = all_fields.filter(field_key='description').first()
        self.assertIsNotNone(desc_field)
        self.assertEqual(desc_field.field_label, 'Description')
        self.assertEqual(desc_field.section, 'Unidentified Accused')

        # 4. Verify display_order groups fields by section in the exact section order
        expected_sections_in_order = [
            'Crime Registration Info',
            'Acts & Sections Filed',
            'Crime Spot',
            'Complainant',
            'Accused',
            'Suspected Accused',
            'Unidentified Accused',
            'Unknown Accused',
            'Officer',
            'Arrest',
            'Remand & Custody',
            'CCTV and CDR Investigation',
            'All Panchnama',
            'Evidence',
            'Seizure Records',
            'Preventive Action',
            'Discharge Accused',
            'Scrutiny',
            'Court Filing and Final Summary',
        ]
        self.assertEqual(len(expected_sections_in_order), 19)

        # Iterate through fields and ensure sections appear in the exact order without interleaving
        seen_sections = []
        last_order = -1
        for f in all_fields:
            self.assertGreater(f.display_order, last_order, f"display_order {f.display_order} not strictly increasing")
            last_order = f.display_order
            if not seen_sections or seen_sections[-1] != f.section:
                seen_sections.append(f.section)

        self.assertEqual(seen_sections, expected_sections_in_order, "Sections do not match the required order")

        # Verify exact field counts per section
        expected_section_counts = {
            'Crime Registration Info': 2,
            'Acts & Sections Filed': 1,
            'Crime Spot': 4,
            'Complainant': 10,
            'Accused': 10,
            'Suspected Accused': 10,
            'Unidentified Accused': 8,
            'Unknown Accused': 1,
            'Officer': 4,
            'Arrest': 11,
            'Remand & Custody': 8,
            'CCTV and CDR Investigation': 3,
            'All Panchnama': 7,
            'Evidence': 3,
            'Seizure Records': 3,
            'Preventive Action': 5,
            'Discharge Accused': 2,
            'Scrutiny': 8,
            'Court Filing and Final Summary': 9,
        }
        for sec, cnt in expected_section_counts.items():
            actual_cnt = all_fields.filter(section=sec).count()
            self.assertEqual(actual_cnt, cnt, f"Section '{sec}' must have {cnt} fields, found {actual_cnt}")

        # Explicitly verify Court Filing and Final Summary field keys
        court_keys = list(all_fields.filter(section='Court Filing and Final Summary').values_list('field_key', flat=True))
        expected_court_keys = [
            'charge_sheet_no', 'a_final_number', 'b_final_number', 'c_final_number',
            'nc_final_number', 'abeted_summary_no', 'stay_by_high_court_date',
            'quashed_by_high_court_date', 'cc_st_number'
        ]
        self.assertEqual(court_keys, expected_court_keys)

        # Explicitly verify Arrest field keys
        arrest_keys = list(all_fields.filter(section='Arrest').values_list('field_key', flat=True))
        expected_arrest_keys = [
            'arrested_person_name', 'arrest_datetime', 'sec_47_48_bnss',
            'relative_friend_name', 'relative_friend_relation', 'release_on_notice',
            'release_on_notice_datetime', 'anticipatory_bail', 'anticipatory_bail_datetime',
            'death_of_accused', 'death_of_accused_datetime'
        ]
        self.assertEqual(arrest_keys, expected_arrest_keys)

        # 5. Verify option_values seeded for 'gender'
        gender_options = list(OptionValue.objects.filter(option_group='gender', is_active=True)
                              .order_by('display_order').values_list('option_value', flat=True))
        self.assertEqual(gender_options, ['Male', 'Female', 'Other'])

        # Verify options_source set on the 4 gender fields and None on others
        expected_gender_keys = {
            'complainant_gender',
            'accused_gender',
            'suspected_accused_gender',
            'unidentified_gender'
        }
        for f in all_fields:
            if f.field_key in expected_gender_keys:
                self.assertEqual(f.options_source, '/api/options/gender/',
                                 f"Field {f.field_key} must have options_source='/api/options/gender/'")
            else:
                self.assertIsNone(f.options_source,
                                  f"Field {f.field_key} should not have options_source set")

        # 6. Run the migration a SECOND time to verify it is SAFE TO RUN TWICE (Idempotence)
        finalize_baseline_template(apps, MockSchemaEditor())

        all_fields_after_second_run = FieldTemplateField.objects.filter(template=self.template).order_by('display_order')
        self.assertEqual(all_fields_after_second_run.count(), 109, "Second run must not create duplicates")
        self.assertEqual(list(all_fields_after_second_run.values('field_key', 'display_order', 'section', 'field_label')),
                         list(all_fields.values('field_key', 'display_order', 'section', 'field_label')))

    def test_suspected_accused_as_arrested_person_preserves_role(self):
        """
        Choosing a Suspected Accused as the arrested person must keep that person's
        role as suspected_accused, and not create or change an accused.
        """
        case = CaseRecord.objects.create(
            id='test-case-suspect-arrest-1',
            module_key='crime',
            title='Test Suspect Arrest Role Preservation',
            case_number='CR/303/2026',
        )

        # 1. Create a Suspected Accused on the case
        suspect = CasesPerson.objects.create(
            case=case,
            name='Ramesh Shinde',
            role='suspected_accused',
            age=35,
            gender='Male'
        )

        self.assertEqual(CasesPerson.objects.filter(case=case, role='suspected_accused').count(), 1)
        self.assertEqual(CasesPerson.objects.filter(case=case, role='accused').count(), 0)

        # 2. Pick the existing suspected accused by existing_person_id in arrests payload
        payload_pick = {
            'arrests': [
                {
                    'existing_person_id': suspect.person_id,
                    'arrest_datetime': '2026-10-11T12:00:00Z',
                    'sec_47_48_bnss': True,
                    'relative_friend_name': 'Suresh Shinde',
                    'relative_friend_relation': 'Brother'
                }
            ]
        }
        res_pick = self.client.put(f'/api/cases/{case.id}/', data=payload_pick, content_type='application/json')
        self.assertEqual(res_pick.status_code, status.HTTP_200_OK)

        # Verify that suspect's role is STILL suspected_accused and no accused was created
        suspect.refresh_from_db()
        self.assertEqual(suspect.role, 'suspected_accused', "Suspect role must remain 'suspected_accused'")
        self.assertEqual(CasesPerson.objects.filter(case=case, role='accused').count(), 0, "No accused should be created")
        self.assertEqual(CasesPerson.objects.filter(case=case, role='suspected_accused').count(), 1)

        # Verify ArrestReleaseStatus is linked to the suspected accused
        arrest = ArrestReleaseStatus.objects.filter(person=suspect).first()
        self.assertIsNotNone(arrest, "Arrest record must link to the suspected accused")
        self.assertEqual(arrest.relative_friend_name, 'Suresh Shinde')

        # 3. Test typing the exact suspected accused name (name matching resolution)
        case_2 = CaseRecord.objects.create(
            id='test-case-suspect-arrest-2',
            module_key='crime',
            title='Test Suspect Arrest Typed Name',
            case_number='CR/304/2026',
        )
        suspect_2 = CasesPerson.objects.create(
            case=case_2,
            name='Vijay Patil',
            role='suspected_accused'
        )
        payload_typed = {
            'arrests': [
                {
                    'typed_name': 'Vijay Patil',
                    'arrest_datetime': '2026-10-11T14:00:00Z',
                    'sec_47_48_bnss': True,
                }
            ]
        }
        res_typed = self.client.put(f'/api/cases/{case_2.id}/', data=payload_typed, content_type='application/json')
        self.assertEqual(res_typed.status_code, status.HTTP_200_OK)

        suspect_2.refresh_from_db()
        self.assertEqual(suspect_2.role, 'suspected_accused', "Suspect role must remain 'suspected_accused'")
        self.assertEqual(CasesPerson.objects.filter(case=case_2, role='accused').count(), 0, "No accused should be created")
        self.assertEqual(CasesPerson.objects.filter(case=case_2, role='suspected_accused').count(), 1)
        self.assertTrue(ArrestReleaseStatus.objects.filter(person=suspect_2).exists())

    def test_postgresql_schema_editor_execution_path(self):
        """
        Validates the PostgreSQL execution path:
        1. Confirms direct public.option_values INSERT with ON CONFLICT DO NOTHING (no schema discovery loop).
        2. Confirms direct public.field_templates SELECT (no schema discovery loop for field_templates).
        3. Confirms direct public.field_template_fields updates/inserts run cleanly with parameters.
        """
        from django.apps import apps

        executed_queries = []

        class MockPgCursor:
            def __enter__(self):
                return self

            def __exit__(self, exc_type, exc_val, exc_tb):
                pass

            def execute(self, sql, params=None):
                executed_queries.append((sql.strip(), params))

            def fetchall(self):
                last_sql = executed_queries[-1][0] if executed_queries else ""
                if "public.field_templates" in last_sql:
                    return [(42,)]
                return []

            def fetchone(self):
                last_sql = executed_queries[-1][0] if executed_queries else ""
                if "public.field_template_fields" in last_sql:
                    return (101,)
                return None

        mock_conn = MagicMock()
        mock_conn.vendor = 'postgresql'
        mock_conn.cursor.return_value = MockPgCursor()

        editor = DatabaseSchemaEditor(mock_conn)
        finalize_baseline_template(apps, editor)

        # 1. Verify query 1 is direct public.option_values insert (no schema discovery loop)
        first_query = executed_queries[0][0]
        self.assertIn("INSERT INTO public.option_values", first_query)
        self.assertIn("ON CONFLICT (option_group, option_value) DO NOTHING", first_query)

        # 2. Verify query 2 is direct public.field_templates lookup (no information_schema discovery)
        second_query = executed_queries[1][0]
        self.assertIn("FROM public.field_templates", second_query)
        for q, _ in executed_queries:
            self.assertNotIn("information_schema", q, "Migration 0037 must not use information_schema discovery")

        # 3. Verify all 109 baseline fields were processed with UPDATE / INSERT on public.field_template_fields
        self.assertEqual(len(executed_queries), 1 + 1 + (109 * 2))
        for q, params in executed_queries[2:]:
            self.assertIn("public.field_template_fields", q)


class Migration0037RealMigrationPathTest(TransactionTestCase):
    """
    Validates migration 0037 through the REAL migration execution path:
    Runs migration 0037 via Django's MigrationLoader and schema_editor to ensure no gap
    between direct execution and the 'python manage.py migrate' path.
    """

    def setUp(self):
        from apps.core.tenancy import TenantContext
        from apps.public_master.models import StateRegistry
        StateRegistry.objects.get_or_create(
            state_code='MH',
            defaults={'state_name': 'Maharashtra', 'schema_name': 'maharashtra', 'is_active': True}
        )
        self.tenant_ctx = TenantContext('maharashtra')
        self.tenant_ctx.__enter__()
        self.template = FieldTemplate.objects.create(
            template_id=99,
            template_name=BASELINE_TEMPLATE_NAME
        )

    def tearDown(self):
        if hasattr(self, 'tenant_ctx'):
            try:
                self.tenant_ctx.__exit__(None, None, None)
            except Exception:
                pass

    def test_migration_loads_and_applies_via_migration_loader_and_schema_editor(self):
        """
        Loads migration 0037 via Django's MigrationLoader and applies it through schema_editor,
        matching the exact execution path taken by 'python manage.py migrate'.
        """
        with override_settings(MIGRATION_MODULES={}):
            loader = MigrationLoader(connection, ignore_no_migrations=False)
            migration = loader.get_migration('crimetab', '0037_finalize_common_form_baseline_template')
            self.assertIsNotNone(migration)

            state = loader.project_state(('crimetab', '0036_make_rti_fields_optional_and_add_empty_message'))
            with connection.schema_editor(atomic=False) as editor:
                # 1. Apply through real migration path
                migration.apply(state.clone(), editor)

                # Check field count
                all_fields = FieldTemplateField.objects.filter(template=self.template)
                self.assertEqual(all_fields.count(), 109)

                # 2. Test idempotence (safe to run twice)
                migration.apply(state.clone(), editor)
                all_fields_2 = FieldTemplateField.objects.filter(template=self.template)
                self.assertEqual(all_fields_2.count(), 109)



