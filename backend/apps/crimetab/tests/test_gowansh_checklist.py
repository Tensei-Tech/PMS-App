import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.crimetab.models.dynamic_engine import (
    CategoryFieldTemplate, FieldTemplate, FieldTemplateField, OptionValue,
)
from apps.crimetab.models.groupings import CaseCategory, CaseCategoryGroup
from apps.crimetab.services.dynamic_form_service import get_form_definition

mig = importlib.import_module('apps.crimetab.migrations.0112_gowansh_full_checklist')


class GowanshChecklistTests(TestCase):
    def setUp(self):
        group, _ = CaseCategoryGroup.objects.get_or_create(
            group_id=2, defaults={'group_name': 'Part 6', 'group_code': 'VI', 'display_order': 2}
        )
        self.tmpl, _ = FieldTemplate.objects.get_or_create(template_name=mig.TEMPLATE_NAME)
        mig.backwards(django_apps, None)  # start from the six old fields of 0024
        self.cat = CaseCategory.objects.create(group=group, category_name='TEST Gowansh',
                                               category_code='TEST_GOWANSH', display_order=1)
        CategoryFieldTemplate.objects.get_or_create(category=self.cat, template=self.tmpl)
        mig.forwards(django_apps, None)

    def _fields(self):
        return {f['field_key']: f for f in get_form_definition(self.cat.pk)['fields']}

    def test_every_field_present_and_optional(self):
        fields = self._fields()
        for _, key, *_ in mig.FIELDS:
            self.assertIn(key, fields)
            self.assertFalse(fields[key]['is_required'])
        self.assertTrue(FieldTemplate.objects.get(pk=self.tmpl.pk).store_values_in_table)

    def test_dropdowns_and_their_options(self):
        fields = self._fields()
        self.assertEqual(fields['gowansh_animal_type']['field_type'], 'dropdown')
        self.assertEqual(fields['gowansh_cruelty_nature']['field_type'], 'multi_select')
        self.assertEqual(
            list(OptionValue.objects.filter(option_group='gowansh_animal_types')
                 .order_by('display_order').values_list('option_value', flat=True)),
            mig.OPTIONS['gowansh_animal_types'])
        self.assertEqual(fields['gowansh_postmortem_date']['depends_on_field_key'], 'gowansh_postmortem')
        self.assertEqual(fields['gowansh_postmortem_date']['depends_on_value'], 'Done')

    def test_old_fields_removed(self):
        keys = set(self._fields())
        for gone in ('gowansh_est_value', 'gowansh_seizure_loc', 'gowansh_custody_place'):
            self.assertNotIn(gone, keys)
        self.assertEqual({k for k in keys if k.startswith('gowansh_')},
                         {key for _, key, *_ in mig.FIELDS})

    def test_idempotent_and_reversible(self):
        mig.forwards(django_apps, None)
        qs = FieldTemplateField.objects.filter(template=self.tmpl)
        self.assertEqual(qs.count(), len(mig.FIELDS))
        mig.backwards(django_apps, None)
        self.assertEqual(set(qs.values_list('field_key', flat=True)), set(mig.ORIGINAL))
        self.assertEqual(qs.get(field_key='gowansh_animal_type').field_type, 'text')
        self.assertFalse(FieldTemplate.objects.get(pk=self.tmpl.pk).store_values_in_table)
