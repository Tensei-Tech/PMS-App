import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.crimetab.models.dynamic_engine import FieldTemplate, FieldTemplateField
from apps.crimetab.models.groupings import CaseCategory, CaseCategoryGroup
from apps.crimetab.services.dynamic_form_service import get_form_definition

mig = importlib.import_module('apps.crimetab.migrations.0109_two_four_wheeler_theft_extra_fields')


class VehicleTheftExtraFieldsTests(TestCase):
    def setUp(self):
        group, _ = CaseCategoryGroup.objects.get_or_create(
            group_id=1, defaults={'group_name': '1 to 5', 'group_code': 'I TO V', 'display_order': 1}
        )
        self.vehicle = CaseCategory.objects.filter(category_code='STAND_VEHICLE').first() or \
            CaseCategory.objects.create(group=group, category_name='TEST Two/Four Wheeler Theft',
                                        category_code='STAND_VEHICLE', display_order=1)
        self.other = CaseCategory.objects.create(group=group, category_name='TEST Other',
                                                 category_code='TEST_OTHER', display_order=2)
        mig.forwards(django_apps, None)  # links the categories created above

    def _fields(self, category):
        return {f['field_key']: f for f in get_form_definition(category.pk)['fields']}

    def test_nine_fields_show_only_for_two_four_wheeler_theft(self):
        fields = self._fields(self.vehicle)
        keys = [k for _, k, _, _, _ in mig.FIELDS]
        self.assertEqual(len(keys), 9)
        for key in keys:
            self.assertIn(key, fields)
            self.assertEqual(fields[key]['section'], 'D. Vehicle Theft')
            self.assertFalse(fields[key]['is_required'])
        self.assertFalse(any(k.startswith('vt_') for k in self._fields(self.other)))

    def test_sub_type_is_a_dropdown_of_vehicle_sub_types(self):
        f = self._fields(self.vehicle)['vt_vehicle_sub_type']
        self.assertEqual(f['field_type'], 'dropdown')
        self.assertEqual(f['options_source'], '/api/options/theft_vehicle_sub_types/')

    def test_idempotent_and_reversible(self):
        mig.forwards(django_apps, None)
        self.assertEqual(
            FieldTemplateField.objects.filter(template__template_name=mig.TEMPLATE_NAME).count(), 9)
        mig.backwards(django_apps, None)
        self.assertFalse(FieldTemplate.objects.filter(template_name=mig.TEMPLATE_NAME).exists())
        self.assertFalse(any(k.startswith('vt_') for k in self._fields(self.vehicle)))
