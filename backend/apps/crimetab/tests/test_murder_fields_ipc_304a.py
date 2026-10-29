import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.crimetab.models import CaseCategory, CategoryFieldTemplate, FieldTemplate
from apps.crimetab.services.dynamic_form_service import get_form_definition

murder = importlib.import_module('apps.crimetab.migrations.0114_murder_extra_fields')
link = importlib.import_module('apps.crimetab.migrations.0152_murder_fields_ipc_304a')


class MurderFieldsForIpc304aTests(TestCase):
    """IPC (A) 304 shows the Murder extra fields."""

    def setUp(self):
        self.ipc304a = CaseCategory.objects.filter(category_code='115').first() or \
            CaseCategory.objects.create(category_name='IPC (A) 304', category_code='115')
        self.other = CaseCategory.objects.create(category_name='TEST Other', category_code='TEST_OTHER')
        if not FieldTemplate.objects.filter(template_name=link.TEMPLATE_NAME).exists():
            murder.forwards(django_apps, None)
        link.forwards(django_apps, None)
        self.tmpl = FieldTemplate.objects.get(template_name=link.TEMPLATE_NAME)

    def test_murder_fields_show_for_ipc_304a_only(self):
        keys = {f['field_key'] for f in get_form_definition(self.ipc304a.category_id)['fields']}
        for _, key, *_ in murder.FIELDS:
            self.assertIn(key, keys)
        self.assertFalse(CategoryFieldTemplate.objects.filter(category=self.other, template=self.tmpl).exists())

    def test_running_twice_adds_no_duplicate_link(self):
        link.forwards(django_apps, None)
        self.assertEqual(CategoryFieldTemplate.objects.filter(category=self.ipc304a, template=self.tmpl).count(), 1)

    def test_backwards_removes_only_the_new_link(self):
        link.backwards(django_apps, None)
        self.assertFalse(CategoryFieldTemplate.objects.filter(category=self.ipc304a, template=self.tmpl).exists())
        self.assertTrue(FieldTemplate.objects.filter(template_name=link.TEMPLATE_NAME).exists())
