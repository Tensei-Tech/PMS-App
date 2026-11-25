import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.crimetab.models.dynamic_engine import FieldTemplate, FieldTemplateField

mig = importlib.import_module('apps.crimetab.migrations.0200_cctv_checked_last')
SECTION = 'CCTV and CDR Investigation'


class CctvCheckedLastTests(TestCase):
    """Migration 0200: CCTV Checked comes after the two CDR dates."""

    def setUp(self):
        tmpl, _ = FieldTemplate.objects.get_or_create(template_name=mig.TEMPLATE_NAME)
        for key, ftype, order in [('cctv_checked', 'checkbox', 700),
                                  ('cdr_sent_date', 'date', 710),
                                  ('cdr_received_date', 'date', 720)]:
            FieldTemplateField.objects.update_or_create(
                template=tmpl, field_key=key,
                defaults={'field_label': key, 'field_type': ftype,
                          'section': SECTION, 'display_order': order})

    def order(self):
        return list(FieldTemplateField.objects.filter(
            template__template_name=mig.TEMPLATE_NAME, section=SECTION,
        ).order_by('display_order').values_list('field_key', flat=True))

    def test_cctv_checked_moves_last(self):
        mig.forwards(django_apps, None)
        mig.forwards(django_apps, None)  # idempotent
        self.assertEqual(self.order(), ['cdr_sent_date', 'cdr_received_date', 'cctv_checked'])

    def test_backwards_puts_it_first(self):
        mig.forwards(django_apps, None)
        mig.backwards(django_apps, None)
        self.assertEqual(self.order(), ['cctv_checked', 'cdr_sent_date', 'cdr_received_date'])
