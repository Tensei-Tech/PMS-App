import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.crimetab.models.dynamic_engine import FieldTemplate, FieldTemplateField

mig = importlib.import_module('apps.crimetab.migrations.0199_move_witness_summons_to_evidence')


class WitnessSummonsToEvidenceTests(TestCase):
    """Migration 0199: Witness Summons moves from CCTV & CDR to Evidence."""

    def setUp(self):
        tmpl, _ = FieldTemplate.objects.get_or_create(template_name=mig.TEMPLATE_NAME)
        FieldTemplateField.objects.update_or_create(
            template=tmpl, field_key='witness_summons',
            defaults={'field_label': 'Witness Summons', 'field_type': 'checkbox',
                      'section': mig.CCTV, 'display_order': 723})
        other, _ = FieldTemplate.objects.get_or_create(template_name='TEST Other Template')
        FieldTemplateField.objects.create(
            template=other, field_key='witness_summons', field_label='TEST',
            field_type='checkbox', section=mig.CCTV, display_order=723)

    def field(self, template_name=mig.TEMPLATE_NAME):
        return FieldTemplateField.objects.get(
            template__template_name=template_name, field_key='witness_summons')

    def test_moves_to_end_of_evidence(self):
        mig.forwards(django_apps, None)
        mig.forwards(django_apps, None)  # idempotent
        f = self.field()
        self.assertEqual((f.section, f.display_order), ('Evidence', 840))
        self.assertEqual(self.field('TEST Other Template').section, mig.CCTV)

    def test_backwards_restores_cctv(self):
        mig.forwards(django_apps, None)
        mig.backwards(django_apps, None)
        f = self.field()
        self.assertEqual((f.section, f.display_order), (mig.CCTV, 723))
