import datetime
from django.db import connection
from django.core.cache import cache
from rest_framework.test import APITestCase, APIRequestFactory, force_authenticate
from rest_framework import status

from apps.users.models import OfficerProfile
from apps.crimetab.models import RTIApplication
from apps.crimetab.views_rti import RTIListCreateView, RTIDetailView, RTIOfficersView
from apps.core.tenancy import TenantContext, provision_state_schema


class RTIApplicationPostgresTestCase(APITestCase):
    """
    Integration tests against PostgreSQL scratch database schema verifying:
    1. CREATE, READ, EDIT operations and status column auto-computation (GENERATED ALWAYS).
    2. Multi-tenant PostgreSQL schema isolation ensuring officers of one state schema
       never leak or appear in another state schema's GET /api/rti/officers/.
    """

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.scratch_schema = "test_scratch_rti_testcase"
        cls.other_scratch_schema = "test_scratch_rti_other_state"
        if connection.vendor == 'postgresql':
            with connection.cursor() as cursor:
                cursor.execute(f'DROP SCHEMA IF EXISTS "{cls.scratch_schema}" CASCADE;')
                cursor.execute(f'DROP SCHEMA IF EXISTS "{cls.other_scratch_schema}" CASCADE;')
                cursor.execute(f'CREATE SCHEMA "{cls.scratch_schema}";')
                cursor.execute(f'CREATE SCHEMA "{cls.other_scratch_schema}";')
            with TenantContext(cls.scratch_schema):
                provision_state_schema(cls.scratch_schema, state_code="TS", state_name="Test State")
                from apps.crimetab.models import OptionValue
                OptionValue.objects.get_or_create(option_group='rti_mode_of_receipt', option_value='Online')
                OptionValue.objects.get_or_create(option_group='rti_info_type', option_value='Crime record')
                OptionValue.objects.get_or_create(option_group='rti_outcome', option_value='Replied')
            with TenantContext(cls.other_scratch_schema):
                provision_state_schema(cls.other_scratch_schema, state_code="KA", state_name="Karnataka Scratch")

    @classmethod
    def tearDownClass(cls):
        try:
            if connection.vendor == 'postgresql':
                with connection.cursor() as cursor:
                    cursor.execute(f'DROP SCHEMA IF EXISTS "{cls.scratch_schema}" CASCADE;')
                    cursor.execute(f'DROP SCHEMA IF EXISTS "{cls.other_scratch_schema}" CASCADE;')
        finally:
            super().tearDownClass()

    def setUp(self):
        cache.clear()
        if connection.vendor != 'postgresql':
            self.skipTest("This test requires PostgreSQL database connection.")

        with TenantContext(self.scratch_schema):
            self.officer = OfficerProfile.objects.create(
                uid="officer_scratch_100",
                name="Inspector Scratch",
                designation="PI",
                station_name="Scratch Station",
                account_status="active"
            )

        class ScratchUser:
            uid = "officer_scratch_100"
            id = "officer_scratch_100"
            name = "Inspector Scratch"
            email = "scratch@example.com"
            role_id = "officer"
            station_name = "Scratch Station"
            station_id = "ST_SCRATCH_100"
            state_code = "TS"
            state_schema = self.scratch_schema
            is_anonymous = False
            is_authenticated = True

        self.user = ScratchUser()
        self.factory = APIRequestFactory()

    def tearDown(self):
        cache.clear()

    def test_create_read_update_status_flip_on_postgresql(self):
        schema = self.scratch_schema
        with TenantContext(schema):
            # 1. CREATE (POST)
            post_view = RTIListCreateView.as_view()
            post_payload = {
                "received_date": "2026-10-01",
                "mode_of_receipt": "Online",
                "applicant_name": "Test Applicant",
                "address": "789 Scratch Road",
                "info_type": "Crime record",
                "assigned_officer_uid": self.officer.uid
            }
            req = self.factory.post("/api/rti/", post_payload, format="json")
            force_authenticate(req, user=self.user)
            req.state_schema = schema

            res = post_view(req)
            self.assertEqual(res.status_code, status.HTTP_201_CREATED)
            self.assertEqual(res.data.get("status"), "Pending")
            rti_id = res.data.get("rti_id")
            self.assertIsNotNone(rti_id)

            # 2. READ (GET)
            detail_view = RTIDetailView.as_view()
            req = self.factory.get(f"/api/rti/{rti_id}/")
            force_authenticate(req, user=self.user)
            req.state_schema = schema

            res = detail_view(req, pk=rti_id)
            self.assertEqual(res.status_code, status.HTTP_200_OK)
            self.assertEqual(res.data.get("status"), "Pending")

            # 3. EDIT (PATCH) - Outcome Replied -> Status flips to Disposal
            patch_payload = {
                "rti_outcome": "Replied",
                "replied_date": "2026-10-05"
            }
            req = self.factory.patch(f"/api/rti/{rti_id}/", patch_payload, format="json")
            force_authenticate(req, user=self.user)
            req.state_schema = schema

            res = detail_view(req, pk=rti_id)
            self.assertEqual(res.status_code, status.HTTP_200_OK)
            self.assertEqual(res.data.get("status"), "Disposal")

            # Verify directly from DB
            db_obj = RTIApplication.objects.get(pk=rti_id)
            self.assertEqual(db_obj.status, "Disposal")

    def test_state_tenant_isolation_never_returns_other_state_officers(self):
        """
        PostgreSQL Multi-Tenant Schema Isolation Test:
        Verifies that GET /api/rti/officers/ executed in state schema TS (Test State)
        strictly resolves against TS's schema tables and NEVER returns officers seeded
        in state schema KA (Karnataka Scratch), even if station_name and station_id match.
        """
        # 1. Seed officer in TS schema
        with TenantContext(self.scratch_schema):
            OfficerProfile.objects.create(
                uid="officer_ts_alpha",
                name="TS Alpha Officer",
                designation="PI",
                station_name="Alpha Station",
                station_id="ST_ALPHA_COMMON",
                account_status="active"
            )

        # 2. Seed officer in KA schema with identical station_name and station_id
        with TenantContext(self.other_scratch_schema):
            OfficerProfile.objects.create(
                uid="officer_ka_alpha",
                name="KA Alpha Officer",
                designation="PI",
                station_name="Alpha Station",
                station_id="ST_ALPHA_COMMON",
                account_status="active"
            )

        # 3. Request as TS user in TS schema
        class TSUser:
            uid = "user_ts_alpha"
            id = "user_ts_alpha"
            name = "TS User"
            email = "user_ts@example.com"
            role_id = "officer"
            station_name = "Alpha Station"
            station_id = "ST_ALPHA_COMMON"
            state_code = "TS"
            state_schema = self.scratch_schema
            is_anonymous = False
            is_authenticated = True

        officers_view = RTIOfficersView.as_view()
        req_ts = self.factory.get("/api/rti/officers/")
        force_authenticate(req_ts, user=TSUser())
        req_ts.state_schema = self.scratch_schema

        res_ts = officers_view(req_ts)
        self.assertEqual(res_ts.status_code, status.HTTP_200_OK)
        ts_uids = [o['uid'] for o in res_ts.data]

        # TS officer must be present
        self.assertIn("officer_ts_alpha", ts_uids)
        # KA officer from another PostgreSQL schema MUST NEVER be present
        self.assertNotIn("officer_ka_alpha", ts_uids)

        # 4. Reverse check: Request as KA user in KA schema
        class KAUser:
            uid = "user_ka_alpha"
            id = "user_ka_alpha"
            name = "KA User"
            email = "user_ka@example.com"
            role_id = "officer"
            station_name = "Alpha Station"
            station_id = "ST_ALPHA_COMMON"
            state_code = "KA"
            state_schema = self.other_scratch_schema
            is_anonymous = False
            is_authenticated = True

        req_ka = self.factory.get("/api/rti/officers/")
        force_authenticate(req_ka, user=KAUser())
        req_ka.state_schema = self.other_scratch_schema

        res_ka = officers_view(req_ka)
        self.assertEqual(res_ka.status_code, status.HTTP_200_OK)
        ka_uids = [o['uid'] for o in res_ka.data]

        # KA officer must be present
        self.assertIn("officer_ka_alpha", ka_uids)
        # TS officer from another PostgreSQL schema MUST NEVER be present
        self.assertNotIn("officer_ts_alpha", ka_uids)

    def test_create_application_with_one_field_only(self):
        schema = self.scratch_schema
        post_view = RTIListCreateView.as_view()

        # Filling only ONE field is valid and must succeed
        payload = {"applicant_name": "Single Field Applicant"}
        req = self.factory.post("/api/rti/", payload, format="json")
        force_authenticate(req, user=self.user)
        req.state_schema = schema

        res = post_view(req)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertEqual(res.data.get("applicant_name"), "Single Field Applicant")
        self.assertIsNone(res.data.get("received_date"))
        self.assertIsNone(res.data.get("due_date"))
        self.assertIsNone(res.data.get("mode_of_receipt"))
        self.assertIsNone(res.data.get("address"))
        self.assertIsNone(res.data.get("info_type"))
        self.assertEqual(res.data.get("status"), "Pending")
        self.assertIsNotNone(res.data.get("serial_no"))

    def test_create_application_with_no_fields_returns_400(self):
        schema = self.scratch_schema
        post_view = RTIListCreateView.as_view()

        # 1. Empty dict
        req = self.factory.post("/api/rti/", {}, format="json")
        force_authenticate(req, user=self.user)
        req.state_schema = schema

        res = post_view(req)
        self.assertEqual(res.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("error", res.data)
        self.assertIn("At least one form field must be provided", res.data["error"])

        # 2. Dict with only blank / whitespace / false values
        blank_payload = {
            "applicant_name": "   ",
            "address": "",
            "mode_of_receipt": "",
            "is_bpl": False,
            "appealed": False
        }
        req2 = self.factory.post("/api/rti/", blank_payload, format="json")
        force_authenticate(req2, user=self.user)
        req2.state_schema = schema

        res2 = post_view(req2)
        self.assertEqual(res2.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("error", res2.data)
        self.assertIn("At least one form field must be provided", res2.data["error"])

    def test_edit_clears_fields(self):
        schema = self.scratch_schema
        post_view = RTIListCreateView.as_view()
        detail_view = RTIDetailView.as_view()

        # Create with fields
        req = self.factory.post("/api/rti/", {
            "applicant_name": "Original Name",
            "address": "Original Address",
            "mode_of_receipt": "Online"
        }, format="json")
        force_authenticate(req, user=self.user)
        req.state_schema = schema
        res = post_view(req)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        rti_id = res.data.get("rti_id")

        # Edit clearing fields
        patch_req = self.factory.patch(f"/api/rti/{rti_id}/", {
            "applicant_name": "",
            "address": ""
        }, format="json")
        force_authenticate(patch_req, user=self.user)
        patch_req.state_schema = schema

        patch_res = detail_view(patch_req, pk=rti_id)
        self.assertEqual(patch_res.status_code, status.HTTP_200_OK)
        self.assertIsNone(patch_res.data.get("applicant_name"))
        self.assertIsNone(patch_res.data.get("address"))

        # Verify DB directly
        with TenantContext(schema):
            db_obj = RTIApplication.objects.get(pk=rti_id)
            self.assertIsNone(db_obj.applicant_name)
            self.assertIsNone(db_obj.address)

    def test_patch_sends_nothing(self):
        schema = self.scratch_schema
        post_view = RTIListCreateView.as_view()
        detail_view = RTIDetailView.as_view()

        # Create
        req = self.factory.post("/api/rti/", {"applicant_name": "Patch Test"}, format="json")
        force_authenticate(req, user=self.user)
        req.state_schema = schema
        res = post_view(req)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        rti_id = res.data.get("rti_id")

        # PATCH with empty dict {}
        patch_req = self.factory.patch(f"/api/rti/{rti_id}/", {}, format="json")
        force_authenticate(patch_req, user=self.user)
        patch_req.state_schema = schema

        patch_res = detail_view(patch_req, pk=rti_id)
        self.assertEqual(patch_res.status_code, status.HTTP_200_OK)
        self.assertEqual(patch_res.data.get("applicant_name"), "Patch Test")

    def test_pdf_of_mostly_blank_application(self):
        schema = self.scratch_schema
        from apps.crimetab.views_rti import RTIPdfView
        post_view = RTIListCreateView.as_view()
        pdf_view = RTIPdfView.as_view()

        # Create mostly blank application (only applicant_name)
        req = self.factory.post("/api/rti/", {"applicant_name": "Solo Applicant"}, format="json")
        force_authenticate(req, user=self.user)
        req.state_schema = schema
        res = post_view(req)
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        rti_id = res.data.get("rti_id")

        # Request PDF
        pdf_req = self.factory.get(f"/api/rti/{rti_id}/pdf/")
        force_authenticate(pdf_req, user=self.user)
        pdf_req.state_schema = schema

        pdf_res = pdf_view(pdf_req, pk=rti_id)
        self.assertEqual(pdf_res.status_code, status.HTTP_200_OK)
        self.assertEqual(pdf_res['Content-Type'], 'application/pdf')
        self.assertTrue(len(pdf_res.content) > 100)
        # Verify PDF header
        self.assertTrue(pdf_res.content.startswith(b'%PDF'))

    def test_migration_idempotent_single_constraint_and_nullable_columns(self):
        """
        Verifies:
        1. Migration drops NOT NULL from exactly the 6 columns across tenant schemas.
        2. Drops any existing due-date constraint and adds exactly one 'rti_due_after_received' constraint.
        3. Running the migration twice is completely safe (idempotent) and produces no duplicate constraints.
        """
        import importlib
        migration_0036 = importlib.import_module(
            "apps.crimetab.migrations.0036_make_rti_fields_optional_and_add_empty_message"
        )
        apply_rti_nullable_and_setting = migration_0036.apply_rti_nullable_and_setting

        schemas_to_check = [self.scratch_schema, self.other_scratch_schema]
        target_cols = ['applicant_name', 'address', 'received_date', 'due_date', 'info_type', 'mode_of_receipt']

        # Execute migration pass 1
        with connection.schema_editor() as editor:
            apply_rti_nullable_and_setting(None, editor)

        def verify_schema_integrity():
            with connection.cursor() as cursor:
                for sch in schemas_to_check:
                    # 1. Verify all 6 columns are nullable
                    cursor.execute("""
                        SELECT column_name, is_nullable
                        FROM information_schema.columns
                        WHERE table_schema = %s AND table_name = 'rti_applications'
                          AND column_name = ANY(%s);
                    """, [sch, target_cols])
                    rows = cursor.fetchall()
                    self.assertEqual(len(rows), 6)
                    for col_name, is_null in rows:
                        self.assertEqual(is_null, 'YES', f"Column {col_name} in {sch} should be nullable")

                    # 2. Verify exactly one due-date check constraint exists on the table
                    cursor.execute("""
                        SELECT con.conname, pg_get_constraintdef(con.oid)
                        FROM pg_constraint con
                        JOIN pg_class rel ON rel.oid = con.conrelid
                        JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
                        WHERE nsp.nspname = %s
                          AND rel.relname = 'rti_applications'
                          AND con.contype = 'c'
                          AND (
                              pg_get_constraintdef(con.oid) ILIKE '%%due_date%%received_date%%'
                              OR con.conname LIKE '%%rti_due_after_received%%'
                          );
                    """, [sch])
                    constraints = cursor.fetchall()
                    self.assertEqual(
                        len(constraints), 1,
                        f"Expected exactly 1 due-date constraint on {sch}.rti_applications, found: {constraints}"
                    )
                    conname, condef = constraints[0]
                    self.assertEqual(conname, 'rti_due_after_received')
                    self.assertIn('due_date IS NULL', condef)
                    self.assertIn('received_date IS NULL', condef)

        # Verification after pass 1
        verify_schema_integrity()

        # Execute migration pass 2 (safe to run twice / idempotent)
        with connection.schema_editor() as editor:
            apply_rti_nullable_and_setting(None, editor)

        # Verification after pass 2
        verify_schema_integrity()



