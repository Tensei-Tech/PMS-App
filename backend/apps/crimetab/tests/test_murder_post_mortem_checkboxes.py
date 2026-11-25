import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.crimetab.models.dynamic_engine import FieldTemplate, FieldTemplateField

mig = importlib.import_module('apps.crimetab.migrations.0198_murder_post_mortem_checkboxes')

QUESTIONS = ['murder_postmortem', 'murder_pm_report', 'murder_viscera_fsl', 'murder_fsl_report']
DATES = {
    'murder_postmortem_date': 'murder_postmortem',
    'murder_pm_report_date': 'murder_pm_report',
    'murder_viscera_fsl_date': 'murder_viscera_fsl',
}


class MurderPostMortemCheckboxTests(TestCase):
    """Migration 0198: Murder Post-Mortem & FSL Yes / No radios are checkboxes."""

    def setUp(self):
        tmpl, _ = FieldTemplate.objects.get_or_create(template_name=mig.TEMPLATE_NAME)
        for key in QUESTIONS:
            FieldTemplateField.objects.update_or_create(
                template=tmpl, field_key=key,
                defaults={'field_label': key, 'field_type': 'radio', 'options_source': mig.YES_NO})
        for key, parent in DATES.items():
            FieldTemplateField.objects.update_or_create(
                template=tmpl, field_key=key,
                defaults={'field_label': key, 'field_type': 'date',
                          'depends_on_field_key': parent, 'depends_on_value': mig.YES})
        # Another template's Yes / No radio is left alone
        other, _ = FieldTemplate.objects.get_or_create(template_name='TEST Other Template')
        FieldTemplateField.objects.create(
            template=other, field_key='murder_postmortem', field_label='TEST',
            field_type='radio', options_source=mig.YES_NO)

    def rows(self, template_name=mig.TEMPLATE_NAME):
        return {f.field_key: f for f in FieldTemplateField.objects.filter(
            template__template_name=template_name)}

    def test_questions_become_checkboxes_and_dates_show_when_ticked(self):
        mig.forwards(django_apps, None)
        mig.forwards(django_apps, None)  # idempotent
        rows = self.rows()
        for key in QUESTIONS:
            self.assertEqual((rows[key].field_type, rows[key].options_source), ('checkbox', None))
        for key, parent in DATES.items():
            self.assertEqual((rows[key].depends_on_field_key, rows[key].depends_on_value),
                             (parent, 'Yes|true'))
        other = self.rows('TEST Other Template')['murder_postmortem']
        self.assertEqual(other.field_type, 'radio')

    def test_backwards_restores_the_radios(self):
        mig.forwards(django_apps, None)
        mig.backwards(django_apps, None)
        rows = self.rows()
        for key in QUESTIONS:
            self.assertEqual((rows[key].field_type, rows[key].options_source), ('radio', mig.YES_NO))
        for key in DATES:
            self.assertEqual(rows[key].depends_on_value, 'Yes')
