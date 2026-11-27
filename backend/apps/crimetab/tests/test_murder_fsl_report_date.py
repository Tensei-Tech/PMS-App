import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.crimetab.models.dynamic_engine import FieldTemplate, FieldTemplateField

mig = importlib.import_module('apps.crimetab.migrations.0202_murder_fsl_report_date')


class MurderFslReportDateTests(TestCase):
    """Migration 0202: ticking FSL Report Received shows its date."""

    def setUp(self):
        tmpl, _ = FieldTemplate.objects.get_or_create(template_name=mig.TEMPLATE_NAME)
        FieldTemplateField.objects.update_or_create(
            template=tmpl, field_key=mig.PARENT,
            defaults={'field_label': 'FSL Report Received', 'field_type': 'checkbox',
                      'section': mig.SECTION, 'display_order': 2170})

    def date_field(self):
        return FieldTemplateField.objects.filter(
            template__template_name=mig.TEMPLATE_NAME, field_key=mig.KEY).first()

    def test_date_added_after_the_checkbox_and_shown_when_ticked(self):
        mig.forwards(django_apps, None)
        mig.forwards(django_apps, None)  # idempotent
        f = self.date_field()
        self.assertEqual((f.field_type, f.section, f.display_order, f.is_required),
                         ('date', mig.SECTION, 2180, False))
        self.assertEqual((f.depends_on_field_key, f.depends_on_value), (mig.PARENT, 'Yes|true'))
        self.assertEqual(FieldTemplateField.objects.filter(
            template__template_name=mig.TEMPLATE_NAME, field_key=mig.KEY).count(), 1)

    def test_backwards_removes_it(self):
        mig.forwards(django_apps, None)
        mig.backwards(django_apps, None)
        self.assertIsNone(self.date_field())
