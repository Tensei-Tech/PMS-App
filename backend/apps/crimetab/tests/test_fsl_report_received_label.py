import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.crimetab.models.dynamic_engine import FieldTemplate, FieldTemplateField

mig = importlib.import_module('apps.crimetab.migrations.0201_fsl_report_received_label')


class FslReportReceivedLabelTests(TestCase):
    """Migration 0201: "FSL Report" questions read "FSL Report Received"."""

    def setUp(self):
        tmpl, _ = FieldTemplate.objects.get_or_create(template_name='TEST Murder Extra')
        for key in mig.KEYS:
            FieldTemplateField.objects.create(template=tmpl, field_key=key,
                                              field_label='FSL Report', field_type='radio')
        # Its date keeps its own name
        FieldTemplateField.objects.create(template=tmpl, field_key='hurt_fsl_report_date',
                                          field_label='FSL Report Date', field_type='date')

    def label(self, key):
        # Only this test's rows: a migrated database has the real ones too
        return FieldTemplateField.objects.get(
            template__template_name='TEST Murder Extra', field_key=key).field_label

    def test_renamed(self):
        mig.forwards(django_apps, None)
        mig.forwards(django_apps, None)  # idempotent
        for key in mig.KEYS:
            self.assertEqual(self.label(key), 'FSL Report Received')
        self.assertEqual(self.label('hurt_fsl_report_date'), 'FSL Report Date')

    def test_backwards(self):
        mig.forwards(django_apps, None)
        mig.backwards(django_apps, None)
        for key in mig.KEYS:
            self.assertEqual(self.label(key), 'FSL Report')
