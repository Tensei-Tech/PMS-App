import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.crimetab.models.dynamic_engine import FieldTemplate, FieldTemplateField
from apps.crimetab.models.groupings import CaseCategory, CaseCategoryGroup
from apps.crimetab.services.dynamic_form_service import get_form_definition

mig = importlib.import_module('apps.crimetab.migrations.0108_mv_act_extra_fields')


class MvActExtraFieldsTests(TestCase):
    def setUp(self):
        group, _ = CaseCategoryGroup.objects.get_or_create(
            group_id=2, defaults={'group_name': 'Part 6', 'group_code': 'VI', 'display_order': 2}
        )
        self.mv = CaseCategory.objects.filter(category_code='STAND_MV_ACT').first() or \
            CaseCategory.objects.create(group=group, category_name='TEST M.V Act',
                                        category_code='STAND_MV_ACT', display_order=1)
        self.other = CaseCategory.objects.create(group=group, category_name='TEST Other',
                                                 category_code='TEST_OTHER', display_order=2)
        mig.forwards(django_apps, None)  # links the categories created above

    def _keys(self, category):
        return {f['field_key'] for f in get_form_definition(category.pk)['fields']}

    def test_fields_show_only_for_mv_act_crimes(self):
        keys = self._keys(self.mv)
        for key in ('mv_vehicle_number', 'mv_dl_number', 'mv_insurance_valid',
                    'mv_breath_reading', 'mv_vehicle_released_date', 'mv_dl_suspended'):
            self.assertIn(key, keys)
        self.assertFalse(any(k.startswith('mv_') for k in self._keys(self.other)))

    def test_every_listed_field_exists_once_and_is_optional(self):
        fields = FieldTemplateField.objects.filter(template__template_name=mig.TEMPLATE_NAME)
        self.assertEqual(fields.count(), len(mig.FIELDS))
        self.assertFalse(fields.filter(is_required=True).exists())
        mig.forwards(django_apps, None)  # idempotent
        self.assertEqual(fields.count(), len(mig.FIELDS))

    def test_yes_no_radios_and_details_shown_only_on_yes(self):
        by_key = {f.field_key: f for f in FieldTemplateField.objects.filter(
            template__template_name=mig.TEMPLATE_NAME)}
        self.assertEqual(by_key['mv_has_driving_licence'].field_type, 'radio')
        self.assertEqual(by_key['mv_has_driving_licence'].options_source, mig.YES_NO)
        for key in ('mv_dl_number', 'mv_dl_class', 'mv_dl_validity'):
            self.assertEqual(by_key[key].depends_on_field_key, 'mv_has_driving_licence')
            self.assertEqual(by_key[key].depends_on_value, 'Yes')
        self.assertEqual(by_key['mv_breath_reading'].depends_on_field_key, 'mv_breath_test')
        self.assertEqual(by_key['mv_vehicle_seized_date'].depends_on_field_key, 'mv_vehicle_seized')
        self.assertIsNone(by_key['mv_vehicle_number'].depends_on_field_key)

    def test_backwards_removes_template_and_links(self):
        mig.backwards(django_apps, None)
        self.assertFalse(FieldTemplate.objects.filter(template_name=mig.TEMPLATE_NAME).exists())
        self.assertFalse(any(k.startswith('mv_') for k in self._keys(self.mv)))
