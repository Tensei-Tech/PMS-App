import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext
from apps.crimetab.models import CaseCategory, CaseCategoryGroup, CategoryFieldTemplate, FieldTemplate
from apps.crimetab.services.dynamic_form_service import get_form_definition
from apps.crimetab.services.table_field_values import table_values_for_case
from apps.crimetab.views import _save_case_child_entities

extra = importlib.import_module('apps.crimetab.migrations.0144_kidnapping_missing_extra_fields')
tab = importlib.import_module('apps.crimetab.migrations.0155_kidnapping_missing_1_to_5_tab')


class KidnappingMissing1To5TabTests(TestCase):
    """"1 to 5" has one combined Kidnapping/Missing sub-tab with the Kidnapping / Missing extra fields."""

    def setUp(self):
        CaseCategoryGroup.objects.get_or_create(
            group_id=1, defaults={'group_name': '1 to 5', 'group_code': 'I TO V', 'display_order': 1})
        CaseCategory.objects.filter(group_id=1, category_code='120').delete()
        FieldTemplate.objects.get_or_create(template_name=tab.BASELINE_TEMPLATE)
        if not FieldTemplate.objects.filter(template_name=tab.EXTRA_TEMPLATE).exists():
            extra.forwards(django_apps, None)
        tab.forwards(django_apps, None)
        self.cat = CaseCategory.objects.get(group_id=1, category_code='120')

    def test_combined_sub_tab_with_both_templates(self):
        self.assertEqual((self.cat.category_name, self.cat.display_order, self.cat.is_active),
                         ('Kidnapping/Missing', 20, True))
        linked = set(CategoryFieldTemplate.objects.filter(category=self.cat)
                     .values_list('template__template_name', flat=True))
        self.assertEqual(linked, {tab.BASELINE_TEMPLATE, tab.EXTRA_TEMPLATE})
        keys = {f['field_key'] for f in get_form_definition(self.cat.category_id)['fields']}
        self.assertTrue({'kdn_person_name', 'kdn_custody_to', 'kdn_ca_sent_date'} <= keys)

    def test_running_twice_keeps_one_sub_tab(self):
        tab.forwards(django_apps, None)
        self.assertEqual(CaseCategory.objects.filter(group_id=1, category_code='120').count(), 1)
        self.assertEqual(CategoryFieldTemplate.objects.filter(category=self.cat).count(), 2)

    def test_case_in_the_tab_saves_extra_fields(self):
        values = {'kdn_person_name': 'Priya', 'kdn_custody_to': 'Relative', 'kdn_ca_sent': 'No'}
        with TenantContext('maharashtra'):
            case = CaseRecord.objects.create(
                id='KM_TEST_1', case_number='CR/KM_TEST_1', title='TEST', sub_category='Kidnapping/Missing',
                module_key='form_1_5', station_name='S', extra_fields=dict(values))
            _save_case_child_entities(case, {**values, 'extra_fields': dict(values)})
            self.assertEqual(table_values_for_case(case), values)


class KidnappingMissingFieldsAfterCommonFormTests(TestCase):
    """The Kidnapping / Missing extra fields are listed after every common form field."""

    def setUp(self):
        CaseCategoryGroup.objects.get_or_create(
            group_id=1, defaults={'group_name': '1 to 5', 'group_code': 'I TO V', 'display_order': 1})
        CaseCategory.objects.filter(group_id=1, category_code='120').delete()
        baseline, _ = FieldTemplate.objects.get_or_create(template_name=tab.BASELINE_TEMPLATE)
        baseline.fields.get_or_create(field_key='test_common_last', defaults={
            'field_label': 'Common last', 'field_type': 'text', 'display_order': 1090})
        if not FieldTemplate.objects.filter(template_name=tab.EXTRA_TEMPLATE).exists():
            extra.forwards(django_apps, None)
        tab.forwards(django_apps, None)
        self.after = importlib.import_module('apps.crimetab.migrations.0156_kidnapping_missing_fields_after_common_form')
        self.after.forwards(django_apps, None)
        self.cat = CaseCategory.objects.get(group_id=1, category_code='120')

    def test_extra_fields_follow_the_common_form_in_their_own_order(self):
        keys = [f['field_key'] for f in get_form_definition(self.cat.category_id)['fields']]
        kdn = [k for k in keys if k.startswith('kdn_')]
        self.assertGreater(keys.index(kdn[0]), keys.index('test_common_last'))
        self.assertEqual(kdn[:3], ['kdn_person_name', 'kdn_person_age', 'kdn_person_gender'])
        self.assertEqual(kdn[-1], 'kdn_ca_sent_date')

    def test_running_twice_moves_once(self):
        self.after.forwards(django_apps, None)
        orders = FieldTemplate.objects.get(template_name=tab.EXTRA_TEMPLATE).fields.values_list('display_order', flat=True)
        self.assertEqual((min(orders), max(orders)), (2010, 2049))
