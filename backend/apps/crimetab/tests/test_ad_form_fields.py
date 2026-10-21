import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.cases.models import CaseRecord, is_ad_case_disposed
from apps.crimetab.models.dynamic_engine import (
    CategoryFieldTemplate,
    FieldTemplate,
    FieldTemplateField,
    OptionValue,
)
from apps.crimetab.models.groupings import CaseCategory
from apps.crimetab.services.dynamic_form_service import get_form_definition

subtabs = importlib.import_module('apps.crimetab.migrations.0121_ad_suicide_and_other_subtabs')
mig = importlib.import_module('apps.crimetab.migrations.0125_ad_form_fields')


class AdFormFieldsTests(TestCase):
    def setUp(self):
        self.ad = CaseCategory.objects.filter(category_code='STAND_AD').first() or \
            CaseCategory.objects.create(category_name='A.D.', category_code='STAND_AD', display_order=40)
        common, _ = FieldTemplate.objects.get_or_create(template_name=mig.COMMON)
        FieldTemplateField.objects.get_or_create(
            template=common, field_key='TEST_common_field',
            defaults={'field_label': 'TEST Common', 'field_type': 'text'})
        subtabs.forwards(django_apps, None)
        mig.forwards(django_apps, None)
        from apps.cases.tests_disposal import seed_ad_disposal_rule
        seed_ad_disposal_rule()

    def _subtab(self, code):
        return CaseCategory.objects.get(category_code=code)

    def test_subtabs_use_only_the_ad_form(self):
        for code in mig.CATEGORY_CODES:
            names = set(CategoryFieldTemplate.objects.filter(category=self._subtab(code))
                        .values_list('template__template_name', flat=True))
            self.assertEqual(names, {mig.TEMPLATE_NAME})
            keys = [f['field_key'] for f in get_form_definition(self._subtab(code).pk)['fields']]
            self.assertNotIn('TEST_common_field', keys)
            self.assertEqual(keys, [k for _, k, *_ in sorted(mig.FIELDS, key=lambda f: f[4])])

    def test_known_unknown_switch_and_sdm_dates(self):
        f = {x.field_key: x for x in FieldTemplateField.objects.filter(template__template_name=mig.TEMPLATE_NAME)}
        self.assertEqual((f['ad_deceased'].depends_on_field_key, f['ad_deceased'].depends_on_value),
                         ('ad_deceased_identity', 'Known'))
        self.assertEqual(f['ad_unknown_injury'].depends_on_value, 'Unknown')
        self.assertEqual(f['ad_relative_name'].depends_on_field_key, 'ad_body_funeral_relative')
        self.assertEqual(f['ad_deceased_name'].parent_field_key, 'ad_deceased')
        self.assertEqual(f['ad_sdm_granted_date'].depends_on_field_key, 'ad_sdm_granted')
        self.assertFalse(any(x.is_required for x in f.values()))
        self.assertEqual(
            list(OptionValue.objects.filter(option_group=mig.CAUSES).order_by('display_order')
                 .values_list('option_value', flat=True)),
            mig.OPTIONS[mig.CAUSES])

    def test_idempotent_and_backwards_restores_common_form(self):
        mig.forwards(django_apps, None)
        self.assertEqual(FieldTemplateField.objects.filter(template__template_name=mig.TEMPLATE_NAME).count(),
                         len(mig.FIELDS))
        mig.backwards(django_apps, None)
        for code in mig.CATEGORY_CODES:
            names = set(CategoryFieldTemplate.objects.filter(category=self._subtab(code))
                        .values_list('template__template_name', flat=True))
            self.assertEqual(names, {mig.COMMON})
        self.assertFalse(FieldTemplate.objects.filter(template_name=mig.TEMPLATE_NAME).exists())

    def test_disposal_is_sdm_granted_yes_with_date(self):
        def case(**extra):
            return CaseRecord.objects.create(module_key='ad', sub_category='Suicide', extra_fields=extra)

        done = case(ad_sdm_granted='Yes', ad_sdm_granted_date='15/10/2026')
        self.assertTrue(is_ad_case_disposed(done))
        self.assertEqual(done.status, 'Disposal')
        for pending in (case(ad_sdm_granted='Yes'),
                        case(ad_sdm_granted='No', ad_sdm_granted_date='15/10/2026'),
                        case(ad_sdm_sent='Yes', ad_sdm_sent_date='15/10/2026')):
            self.assertEqual(pending.status, 'Pending')

        # Answer changed back to No: the case returns to Pending
        done.extra_fields['ad_sdm_granted'] = 'No'
        done.save()
        self.assertEqual(done.status, 'Pending')
