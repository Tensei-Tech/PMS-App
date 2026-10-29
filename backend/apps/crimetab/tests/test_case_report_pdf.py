"""
The View / PDF of a "1 to 5" / Part 6 case is a server-made PDF in the RTI
report style, with rows taken from the case's own form.
"""
import importlib

import jwt
from django.apps import apps as django_apps
from django.conf import settings
from django.core.cache import cache
from django.test import TestCase
from rest_framework.test import APIClient

from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.crimetab.models import CaseCategory, CasesPerson, CategoryFieldTemplate, FieldTemplate
from apps.crimetab.serializers import FullCaseDetailSerializer
from apps.crimetab.services.case_report_pdf import case_category, case_report_rows
from apps.public_master.models import Role, StateRegistry
from apps.users.models import OfficerProfile

murder = importlib.import_module('apps.crimetab.migrations.0114_murder_extra_fields')


class CaseReportPdfTests(TestCase):
    def setUp(self):
        cache.clear()
        StateRegistry.objects.create(state_code='MH', state_name='Maharashtra', schema_name='maharashtra', is_active=True)
        Role.objects.get_or_create(id='officer', defaults={'name': 'officer', 'level': 'station'})
        self.officer = OfficerProfile.objects.create(uid='off-a', email='a@x.in', name='A', station_name='Station A',
                                                     role_id='officer', account_status='active')
        self.outsider = OfficerProfile.objects.create(uid='off-b', email='b@x.in', name='B', station_name='Station B',
                                                      role_id='officer', account_status='active')
        self.cat = CaseCategory.objects.filter(category_name='Murder').first() or \
            CaseCategory.objects.create(category_name='Murder', category_code='QC_MURDER')
        if not FieldTemplate.objects.filter(template_name='Murder Section Extra Fields').exists():
            murder.forwards(django_apps, None)
        tmpl = FieldTemplate.objects.get(template_name='Murder Section Extra Fields')
        CategoryFieldTemplate.objects.get_or_create(category=self.cat, template=tmpl)
        with TenantContext('maharashtra'):
            self.case = CaseRecord.objects.create(
                id='pdf-1', module_key='form_1_5', sub_category='Murder', title='T', case_number='CR/45',
                station_name='Station A', created_by='off-a',
                extra_fields={'murder_deceased_name': 'Ramesh Patil', 'murder_postmortem': 'Yes'})
            CasesPerson.objects.create(case=self.case, role='accused', name='Suresh K', age=34)

    def tearDown(self):
        cache.clear()

    def _client(self, officer):
        client = APIClient()
        token = jwt.encode({'uid': officer.uid, 'state_code': 'MH', 'user_type': 'officer'},
                           settings.SECRET_KEY, algorithm='HS256')
        client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}', HTTP_X_STATE_CODE='MH')
        return client

    def test_rows_use_the_form_labels_and_case_values(self):
        with TenantContext('maharashtra'):
            self.assertEqual(case_category(self.case), self.cat)
            rows = case_report_rows(self.case, FullCaseDetailSerializer(self.case).data)
        labelled = {label: value for kind, label, value in rows if kind == 'row'}
        self.assertEqual(labelled.get('Deceased Name'), 'Ramesh Patil')
        self.assertEqual(labelled.get('Post-Mortem'), 'Yes')
        self.assertIn('Suresh K', labelled.get('Accused 1', ''))
        sections = [label for kind, label, _ in rows if kind == 'section']
        self.assertIn('Deceased Details', sections)
        self.assertIn('Persons', sections)

    def test_endpoint_returns_a_pdf(self):
        response = self._client(self.officer).get('/api/cases/pdf-1/report-pdf/')
        self.assertEqual(response.status_code, 200, getattr(response, 'content', b'')[:200])
        self.assertEqual(response['Content-Type'], 'application/pdf')
        self.assertTrue(response.content.startswith(b'%PDF'))
        self.assertIn('Case_CR_45.pdf', response['Content-Disposition'])

    def test_other_station_cannot_get_it(self):
        self.assertEqual(self._client(self.outsider).get('/api/cases/pdf-1/report-pdf/').status_code, 404)
