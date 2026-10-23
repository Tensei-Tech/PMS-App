import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.crimetab.models.dynamic_engine import FieldTemplate, FieldTemplateField
from apps.crimetab.models.groupings import CaseCategory, CaseCategoryGroup
from apps.crimetab.services.dynamic_form_service import get_form_definition

mig = importlib.import_module('apps.crimetab.migrations.0114_murder_extra_fields')
KEYS = {k for _, k, *_ in mig.FIELDS}


class MurderExtraFieldsTests(TestCase):
    def setUp(self):
        group, _ = CaseCategoryGroup.objects.get_or_create(
            group_id=1, defaults={'group_name': '1 to 5', 'group_code': 'I TO V', 'display_order': 1}
        )
        self.murder = CaseCategory.objects.filter(category_name='Murder').first() or \
            CaseCategory.objects.create(group=group, category_name='Murder',
                                        category_code='TEST_MURDER', display_order=1)
        self.other = CaseCategory.objects.create(group=group, category_name='TEST Other',
                                                 category_code='TEST_OTHER', display_order=2)
        mig.forwards(django_apps, None)

    def _fields(self, category):
        return {f['field_key']: f for f in get_form_definition(category.pk)['fields']}

    def test_fields_show_only_for_murder(self):
        fields = self._fields(self.murder)
        self.assertTrue(KEYS <= set(fields))
        self.assertFalse(any(fields[k]['is_required'] for k in KEYS))
        self.assertFalse(KEYS & set(self._fields(self.other)))

    def test_kyc_types_and_dates_on_yes(self):
        fields = self._fields(self.murder)
        self.assertEqual(fields['murder_deceased_mobile']['field_type'], 'mobile')
        self.assertEqual(fields['murder_deceased_aadhaar']['field_type'], 'aadhaar')
        self.assertEqual(fields['murder_inquest_datetime']['field_type'], 'datetime')
        for date_key in ('murder_postmortem_date', 'murder_pm_report_date', 'murder_viscera_fsl_date'):
            parent = fields[date_key]['depends_on_field_key']
            self.assertEqual(date_key, f'{parent}_date')
            self.assertEqual(fields[date_key]['depends_on_value'], 'Yes')
            self.assertEqual(fields[parent]['field_type'], 'radio')

    def test_idempotent_and_reversible(self):
        mig.forwards(django_apps, None)
        qs = FieldTemplateField.objects.filter(template__template_name=mig.TEMPLATE_NAME, field_key__in=KEYS)
        self.assertEqual(qs.count(), len(mig.FIELDS))
        self.assertTrue(FieldTemplate.objects.get(template_name=mig.TEMPLATE_NAME).store_values_in_table)
        mig.backwards(django_apps, None)
        self.assertFalse(qs.exists())
