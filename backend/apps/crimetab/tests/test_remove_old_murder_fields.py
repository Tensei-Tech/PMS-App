import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.crimetab.models.dynamic_engine import CategoryFieldTemplate, FieldTemplate, FieldTemplateField
from apps.crimetab.models.groupings import CaseCategory, CaseCategoryGroup
from apps.crimetab.services.dynamic_form_service import get_form_definition

mig = importlib.import_module('apps.crimetab.migrations.0113_remove_old_murder_extra_fields')
OLD_KEYS = {k for _, k, _, _ in mig.OLD_FIELDS}


class RemoveOldMurderFieldsTests(TestCase):
    def setUp(self):
        group, _ = CaseCategoryGroup.objects.get_or_create(
            group_id=1, defaults={'group_name': '1 to 5', 'group_code': 'I TO V', 'display_order': 1}
        )
        self.tmpl, _ = FieldTemplate.objects.get_or_create(template_name=mig.TEMPLATE_NAME)
        self.cat = CaseCategory.objects.create(group=group, category_name='TEST Murder',
                                               category_code='TEST_MURDER', display_order=1)
        CategoryFieldTemplate.objects.get_or_create(category=self.cat, template=self.tmpl)
        mig.backwards(django_apps, None)  # the old fields, as before 0113

    def _keys(self):
        return {f['field_key'] for f in get_form_definition(self.cat.pk)['fields']}

    def test_old_fields_gone_template_and_link_kept(self):
        self.assertTrue(OLD_KEYS <= self._keys())
        mig.forwards(django_apps, None)
        self.assertFalse(OLD_KEYS & self._keys())
        self.assertTrue(FieldTemplate.objects.filter(pk=self.tmpl.pk).exists())
        self.assertTrue(CategoryFieldTemplate.objects.filter(category=self.cat, template=self.tmpl).exists())
        mig.forwards(django_apps, None)  # idempotent

    def test_backwards_restores_old_fields(self):
        mig.forwards(django_apps, None)
        mig.backwards(django_apps, None)
        restored = set(FieldTemplateField.objects.filter(template=self.tmpl).values_list('field_key', flat=True))
        self.assertTrue(OLD_KEYS <= restored, OLD_KEYS - restored)
