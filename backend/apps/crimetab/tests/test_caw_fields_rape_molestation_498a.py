import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.crimetab.models import CaseCategory, CategoryFieldTemplate, FieldTemplate
from apps.crimetab.services.dynamic_form_service import get_form_definition
from apps.crimetab.services.table_field_values import table_values_for_case
from apps.crimetab.views import _save_case_child_entities

caw = importlib.import_module('apps.crimetab.migrations.0115_crime_against_women_extra_fields')
link = importlib.import_module('apps.crimetab.migrations.0151_caw_fields_rape_molestation_498a')

TARGETS = (('112', 'Rape'), ('113', 'Molestation'), ('116', '498 (A) IPC'))


class CawFieldsForRapeMolestation498aTests(TestCase):
    """Rape, Molestation and 498 (A) IPC show the Crime Against Women extra fields."""

    def setUp(self):
        self.cats = [CaseCategory.objects.filter(category_code=code).first() or
                     CaseCategory.objects.create(category_name=name, category_code=code)
                     for code, name in TARGETS]
        self.other = CaseCategory.objects.create(category_name='TEST Other', category_code='TEST_OTHER')
        if not FieldTemplate.objects.filter(template_name=link.TEMPLATE_NAME).exists():
            caw.forwards(django_apps, None)
        link.forwards(django_apps, None)
        self.tmpl = FieldTemplate.objects.get(template_name=link.TEMPLATE_NAME)

    def test_template_linked_to_each_category(self):
        for cat in self.cats:
            self.assertTrue(CategoryFieldTemplate.objects.filter(category=cat, template=self.tmpl).exists(),
                            cat.category_name)
            keys = {f['field_key'] for f in get_form_definition(cat.category_id)['fields']}
            for key in ('caw_victim_name', 'caw_victim_medical', 'caw_victim_dna', 'caw_digital_evidence',
                        'caw_url_preserved', 'caw_acid_attack'):
                self.assertIn(key, keys, f'{cat.category_name}: missing {key}')
        self.assertFalse(CategoryFieldTemplate.objects.filter(category=self.other, template=self.tmpl).exists())

    def test_running_twice_adds_no_duplicate_links(self):
        link.forwards(django_apps, None)
        for cat in self.cats:
            self.assertEqual(CategoryFieldTemplate.objects.filter(category=cat, template=self.tmpl).count(), 1)

    def test_values_saved_and_loaded_for_a_498a_case(self):
        values = {'caw_victim_age': '27', 'caw_victim_medical': 'Yes', 'caw_dowry_evidence': 'Yes'}
        with TenantContext('maharashtra'):
            case = CaseRecord.objects.create(
                id='498A_TEST_1', case_number='CR/498A_TEST_1', title='TEST 498A', sub_category='498 (A) IPC',
                module_key='form_1_5', station_name='TEST Station', extra_fields=dict(values))
            _save_case_child_entities(case, {**values, 'extra_fields': dict(values)})
            loaded = table_values_for_case(case)
            self.assertEqual({k: loaded.get(k) for k in values}, values)
