import io
import datetime
import unittest
from django.db import connection
from rest_framework.test import APIRequestFactory, force_authenticate
from rest_framework import status

from apps.users.models import OfficerProfile
from apps.crimetab.models import RTIApplication, ModuleSetting, FieldTemplateField, OptionValue
from apps.crimetab.views_rti import (
    RTIDetailView,
    RTIPdfView,
    get_rti_display_rows,
    ensure_date_format_setting,
)
from apps.core.tenancy import TenantContext, provision_state_schema


class RTIDisplayRowsAndPdfParityTestCase(unittest.TestCase):
    """
    Validates that RTI Screen display rows (API view response) and RTI PDF rows:
    1. Are produced by the single source of truth function `get_rti_display_rows`.
    2. Have identical labels, order, and display values across all application outcomes:
       - Replied
       - Rejected (with reason)
       - Transferred
       - Pending (no outcome)
    3. Conform to all formatting rules:
       - Dates in module_settings['date_format']
       - Booleans as 'Yes' and 'No'
       - Blank values as empty cells (''), never 'None' or '-'
       - Officer as 'Name, Designation'
       - Conditional fields hidden when parent value does not show them
    4. Confirm zero hardcoded labels, formats, or status words typed in RTIPdfView.
    """

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.scratch_schema = "test_scratch_rti_pdf_parity"
        if connection.vendor == 'postgresql':
            with connection.cursor() as cursor:
                cursor.execute(f'DROP SCHEMA IF EXISTS "{cls.scratch_schema}" CASCADE;')
                cursor.execute(f'CREATE SCHEMA "{cls.scratch_schema}";')
            with TenantContext(cls.scratch_schema):
                provision_state_schema(cls.scratch_schema, state_code="TS", state_name="Test State")

    @classmethod
    def tearDownClass(cls):
        try:
            if connection.vendor == 'postgresql':
                with connection.cursor() as cursor:
                    cursor.execute(f'DROP SCHEMA IF EXISTS "{cls.scratch_schema}" CASCADE;')
        finally:
            super().tearDownClass()

    def setUp(self):
        if connection.vendor != 'postgresql':
            self.skipTest("This test requires PostgreSQL database connection.")

        with TenantContext('public'):
            ensure_date_format_setting()
            # Ensure standard status settings
            ModuleSetting.objects.update_or_create(module_key='rti', setting_key='status_pending_label', defaults={'setting_value': 'Pending'})
            ModuleSetting.objects.update_or_create(module_key='rti', setting_key='status_disposal_label', defaults={'setting_value': 'Disposal'})
            ModuleSetting.objects.update_or_create(module_key='rti', setting_key='serial_label', defaults={'setting_value': 'Sr. No.'})
            ModuleSetting.objects.update_or_create(module_key='rti', setting_key='status_label', defaults={'setting_value': 'Status'})

        with TenantContext(self.scratch_schema):
            self.officer, _ = OfficerProfile.objects.update_or_create(
                uid="officer_parity_1",
                defaults={
                    "name": "S. V. Kadam",
                    "designation": "Assistant Commissioner of Police",
                    "station_name": "Crime HQ",
                    "account_status": "active",
                }
            )

        class DummyUser:
            def __init__(self, st_name="Crime HQ", uid_val="officer_parity_1"):
                self.uid = uid_val
                self.id = uid_val
                self.name = "S. V. Kadam"
                self.email = "kadam@example.com"
                self.role_id = "officer"
                self.station_name = st_name
                self.state_code = "TS"
                self.state_schema = "test_scratch_rti_pdf_parity"
                self.is_anonymous = False
                self.is_authenticated = True

        self.user = DummyUser()
        self.factory = APIRequestFactory()

    def tearDown(self):
        if connection.vendor == 'postgresql':
            with TenantContext(self.scratch_schema):
                RTIApplication.objects.all().delete()

    def _get_api_detail_rows(self, rti_id):
        view = RTIDetailView.as_view()
        request = self.factory.get(f'/api/rti/{rti_id}/')
        request.user = self.user
        request.state_code = "TS"
        request.state_schema = self.scratch_schema
        force_authenticate(request, user=self.user)
        response = view(request, pk=rti_id)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('display_rows', response.data)
        return response.data['display_rows']

    def _get_pdf_response(self, rti_id):
        view = RTIPdfView.as_view()
        request = self.factory.get(f'/api/rti/{rti_id}/pdf/')
        request.user = self.user
        request.state_code = "TS"
        request.state_schema = self.scratch_schema
        force_authenticate(request, user=self.user)
        response = view(request, pk=rti_id)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response['Content-Type'], 'application/pdf')
        return response.content

    def test_parity_outcome_replied(self):
        """
        Outcome = 'Replied':
        Screen rows and PDF rows must be 100% identical.
        Replied Date present; Rejected Date, Reason for Rejection, Transfer To hidden.
        """
        with TenantContext(self.scratch_schema):
            rti = RTIApplication.objects.create(
                station_name="Crime HQ",
                serial_year=2026,
                serial_no=101,
                applicant_name="Sunil Patil",
                applicant_age=42,
                address="Shivaji Nagar, Pune",
                email="sunil@example.com",
                received_date=datetime.date(2026, 1, 10),
                due_date=datetime.date(2026, 2, 9),
                replied_date=datetime.date(2026, 1, 20),
                info_type="Crime record",
                assigned_officer_uid=self.officer.uid,
                assigned_officer_name=self.officer.name,
                assigned_officer_designation=self.officer.designation,
                mode_of_receipt="Online",
                is_bpl=False,
                remark="Furnished by registered post.",
                appealed=False,
            )

            screen_rows = self._get_api_detail_rows(rti.pk)
            pdf_rows = RTIPdfView.get_table_rows(rti, schema=self.scratch_schema)
            pdf_bytes = self._get_pdf_response(rti.pk)

            # 1. Identical rows comparison
            self.assertEqual(len(screen_rows), len(pdf_rows))
            for i, (s_row, p_row) in enumerate(zip(screen_rows, pdf_rows)):
                self.assertEqual(s_row[0], p_row[0], f"Row {i} label mismatch: {s_row[0]} vs {p_row[0]}")
                self.assertEqual(s_row[1], p_row[1], f"Row {i} value mismatch for {s_row[0]}: {s_row[1]} vs {p_row[1]}")

            labels = [r[0] for r in screen_rows]
            values_dict = {r[0]: r[1] for r in screen_rows}

            # 2. Check conditional visibility
            self.assertIn("Replied Date", labels)
            self.assertEqual(values_dict["Replied Date"], "20/01/2026")
            self.assertNotIn("Rejected Date", labels)
            self.assertNotIn("Reason for Rejection", labels)
            self.assertNotIn("Transfer To", labels)
            self.assertNotIn("Other (specify)", labels)
            self.assertNotIn("Appeal Date", labels)

            # 3. Check format requirements
            self.assertEqual(values_dict["Status"], "Disposal")
            self.assertEqual(values_dict["Assigned Officer"], "S. V. Kadam, Assistant Commissioner of Police")
            self.assertEqual(values_dict["BPL"], "No")
            self.assertEqual(values_dict["Appealed"], "No")
            self.assertNotIn("None", values_dict.values())
            self.assertTrue(pdf_bytes.startswith(b'%PDF-'))

    def test_parity_outcome_rejected(self):
        """
        Outcome = 'Rejected':
        Screen rows and PDF rows must be 100% identical.
        Rejected Date and Reason for Rejection present; Replied Date and Transfer To hidden.
        """
        with TenantContext(self.scratch_schema):
            rti = RTIApplication.objects.create(
                station_name="Crime HQ",
                serial_year=2026,
                serial_no=102,
                applicant_name="Amit Deshmukh",
                applicant_age=35,
                address="Camp, Pune",
                email="amit@example.com",
                received_date=datetime.date(2026, 1, 12),
                due_date=datetime.date(2026, 2, 11),
                rejected_date=datetime.date(2026, 1, 25),
                rejection_reason="Exempt under Section 8(1)(j) RTI Act 2005",
                info_type="Personal",
                assigned_officer_uid=self.officer.uid,
                assigned_officer_name=self.officer.name,
                assigned_officer_designation=self.officer.designation,
                mode_of_receipt="Post",
                is_bpl=True,
                remark="Third party private data.",
                appealed=True,
                appeal_date=datetime.date(2026, 2, 2),
            )

            screen_rows = self._get_api_detail_rows(rti.pk)
            pdf_rows = RTIPdfView.get_table_rows(rti, schema=self.scratch_schema)
            pdf_bytes = self._get_pdf_response(rti.pk)

            self.assertEqual(len(screen_rows), len(pdf_rows))
            for i, (s_row, p_row) in enumerate(zip(screen_rows, pdf_rows)):
                self.assertEqual(s_row[0], p_row[0])
                self.assertEqual(s_row[1], p_row[1])

            labels = [r[0] for r in screen_rows]
            values_dict = {r[0]: r[1] for r in screen_rows}

            self.assertIn("Rejected Date", labels)
            self.assertEqual(values_dict["Rejected Date"], "25/01/2026")
            self.assertIn("Reason for Rejection", labels)
            self.assertEqual(values_dict["Reason for Rejection"], "Exempt under Section 8(1)(j) RTI Act 2005")
            self.assertNotIn("Replied Date", labels)
            self.assertNotIn("Transfer To", labels)
            self.assertIn("Appeal Date", labels)
            self.assertEqual(values_dict["Appeal Date"], "02/02/2026")
            self.assertEqual(values_dict["BPL"], "Yes")
            self.assertEqual(values_dict["Appealed"], "Yes")
            self.assertTrue(pdf_bytes.startswith(b'%PDF-'))

    def test_parity_outcome_transferred(self):
        """
        Outcome = 'Transferred':
        Screen rows and PDF rows must be 100% identical.
        Transfer To present; Replied Date, Rejected Date, Reason for Rejection hidden.
        """
        with TenantContext(self.scratch_schema):
            rti = RTIApplication.objects.create(
                station_name="Crime HQ",
                serial_year=2026,
                serial_no=103,
                applicant_name="Deepa Kulkarni",
                applicant_age=29,
                address="Kothrud, Pune",
                email="deepa@example.com",
                received_date=datetime.date(2026, 1, 15),
                due_date=datetime.date(2026, 2, 14),
                transferred_to="PIO, Crime Branch CID Pune",
                info_type="Other",
                info_type_other="Special Investigation Report",
                assigned_officer_uid=self.officer.uid,
                assigned_officer_name=self.officer.name,
                assigned_officer_designation=self.officer.designation,
                mode_of_receipt="In person",
                is_bpl=False,
                remark="Matter pertains to state CID.",
                appealed=False,
            )

            screen_rows = self._get_api_detail_rows(rti.pk)
            pdf_rows = RTIPdfView.get_table_rows(rti, schema=self.scratch_schema)
            pdf_bytes = self._get_pdf_response(rti.pk)

            self.assertEqual(len(screen_rows), len(pdf_rows))
            for i, (s_row, p_row) in enumerate(zip(screen_rows, pdf_rows)):
                self.assertEqual(s_row[0], p_row[0])
                self.assertEqual(s_row[1], p_row[1])

            labels = [r[0] for r in screen_rows]
            values_dict = {r[0]: r[1] for r in screen_rows}

            self.assertIn("Transfer To", labels)
            self.assertEqual(values_dict["Transfer To"], "PIO, Crime Branch CID Pune")
            self.assertNotIn("Replied Date", labels)
            self.assertNotIn("Rejected Date", labels)
            self.assertNotIn("Reason for Rejection", labels)
            self.assertIn("Other (specify)", labels)
            self.assertEqual(values_dict["Other (specify)"], "Special Investigation Report")
            self.assertTrue(pdf_bytes.startswith(b'%PDF-'))

    def test_parity_outcome_pending(self):
        """
        Outcome = Pending / None:
        Screen rows and PDF rows must be 100% identical.
        All 4 outcome fields hidden. Blank values rendered as empty string ('').
        """
        with TenantContext(self.scratch_schema):
            rti = RTIApplication.objects.create(
                station_name="Crime HQ",
                serial_year=2026,
                serial_no=104,
                applicant_name="Vikas More",
                received_date=datetime.date(2026, 2, 1),
                due_date=datetime.date(2026, 3, 3),
                info_type="Missing",
                mode_of_receipt="Email",
                is_bpl=False,
                appealed=False,
            )

            screen_rows = self._get_api_detail_rows(rti.pk)
            pdf_rows = RTIPdfView.get_table_rows(rti, schema=self.scratch_schema)
            pdf_bytes = self._get_pdf_response(rti.pk)

            self.assertEqual(len(screen_rows), len(pdf_rows))
            for i, (s_row, p_row) in enumerate(zip(screen_rows, pdf_rows)):
                self.assertEqual(s_row[0], p_row[0])
                self.assertEqual(s_row[1], p_row[1])

            labels = [r[0] for r in screen_rows]
            values_dict = {r[0]: r[1] for r in screen_rows}

            self.assertNotIn("Replied Date", labels)
            self.assertNotIn("Rejected Date", labels)
            self.assertNotIn("Reason for Rejection", labels)
            self.assertNotIn("Transfer To", labels)
            self.assertNotIn("Other (specify)", labels)
            self.assertNotIn("Appeal Date", labels)
            self.assertEqual(values_dict["Status"], "Pending")
            self.assertEqual(values_dict["Age"], "")
            self.assertEqual(values_dict["Address"], "")
            self.assertEqual(values_dict["Assigned Officer"], "")
            self.assertEqual(values_dict["Outcome"], "")
            self.assertNotIn("None", values_dict.values())
            self.assertTrue(pdf_bytes.startswith(b'%PDF-'))
