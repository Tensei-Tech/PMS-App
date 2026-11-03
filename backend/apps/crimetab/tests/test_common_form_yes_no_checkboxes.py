import importlib

from django.apps import apps as django_apps
from django.test import TestCase

from apps.cases.models import CaseRecord
from apps.crimetab.models.dynamic_engine import FieldTemplate, FieldTemplateField

mig = importlib.import_module('apps.crimetab.migrations.0169_common_form_yes_no_to_checkboxes')

YES_NO_FIELDS = [
    # (key, label, [(dependent key, label)])
    ('witness_summons', 'Witness Summons', []),
    ('vehicle_log_book_entry', 'Vehicle Log Book Entry',
     [('vehicle_log_book_entry_date', 'Vehicle Log Book Entry Date'),
      ('vehicle_log_book_entry_reason', 'Vehicle Log Book Entry Reason')]),
    ('mobile_spot_recording', 'Mobile Spot Recording',
     [('mobile_spot_recording_date', 'Mobile Spot Recording Date')]),
]


class CommonFormYesNoCheckboxTests(TestCase):
    """Migration 0169: Common Form Yes / No radios are checkboxes."""

    def setUp(self):
        tmpl, _ = FieldTemplate.objects.get_or_create(template_name=mig.TEMPLATE_NAME)
        for key, label, dependents in YES_NO_FIELDS:
            FieldTemplateField.objects.update_or_create(
                template=tmpl, field_key=key,
                defaults={'field_label': label, 'field_type': 'radio', 'options_source': mig.YES_NO})
            for dep_key, dep_label in dependents:
                FieldTemplateField.objects.update_or_create(
                    template=tmpl, field_key=dep_key,
                    defaults={'field_label': dep_label, 'field_type': 'date',
                              'depends_on_field_key': key, 'depends_on_value': mig.YES})
        # Another template's Yes / No radio is left alone
        other, _ = FieldTemplate.objects.get_or_create(template_name='TEST Other Template')
        FieldTemplateField.objects.create(
            template=other, field_key='witness_summons', field_label='TEST',
            field_type='radio', options_source=mig.YES_NO)

    def fields(self):
        return {f.field_key: f for f in FieldTemplateField.objects.filter(
            template__template_name=mig.TEMPLATE_NAME)}

    def test_yes_no_fields_are_checkboxes_and_ticked_shows_dependents(self):
        mig.forwards(django_apps, None)
        f = self.fields()
        for key, _, dependents in YES_NO_FIELDS:
            self.assertEqual((f[key].field_type, f[key].options_source), ('checkbox', None), key)
            for dep_key, _ in dependents:
                self.assertEqual((f[dep_key].depends_on_field_key, f[dep_key].depends_on_value),
                                 (key, None), dep_key)
        other = FieldTemplateField.objects.get(template__template_name='TEST Other Template')
        self.assertEqual(other.field_type, 'radio')

    def test_saved_answers_convert_and_backwards_restores(self):
        case = CaseRecord.objects.create(
            case_number='TEST_CF_YN', extra_fields={
                'witness_summons': 'Yes', 'vehicle_log_book_entry': 'No',
                'mobile_spot_recording': '', 'mobile_spot_recording_date': '',
                'cr_number': 'TEST'})
        mig.forwards(django_apps, None)
        mig.forwards(django_apps, None)
        case.refresh_from_db()
        self.assertEqual(case.extra_fields, {
            'witness_summons': True, 'mobile_spot_recording': '',
            'mobile_spot_recording_date': '', 'cr_number': 'TEST'})

        mig.backwards(django_apps, None)
        case.refresh_from_db()
        self.assertEqual(case.extra_fields['witness_summons'], 'Yes')
        f = self.fields()
        self.assertEqual((f['witness_summons'].field_type, f['witness_summons'].options_source),
                         ('radio', mig.YES_NO))
        self.assertEqual(f['vehicle_log_book_entry_date'].depends_on_value, mig.YES)


mig_mobile = importlib.import_module('apps.crimetab.migrations.0170_common_form_mobile_numbers')


class CommonFormMobileNumberTests(TestCase):
    """Migration 0170: Common Form mobile numbers are 'mobile' fields, still optional."""

    def setUp(self):
        tmpl, _ = FieldTemplate.objects.get_or_create(template_name=mig_mobile.TEMPLATE_NAME)
        for key in mig_mobile.KEYS:
            FieldTemplateField.objects.update_or_create(
                template=tmpl, field_key=key,
                defaults={'field_label': key, 'field_type': 'text', 'is_required': False})

    def fields(self):
        return {f.field_key: f for f in FieldTemplateField.objects.filter(
            template__template_name=mig_mobile.TEMPLATE_NAME, field_key__in=mig_mobile.KEYS)}

    def test_mobile_type_and_not_required(self):
        mig_mobile.forwards(django_apps, None)
        mig_mobile.forwards(django_apps, None)
        for key, f in self.fields().items():
            self.assertEqual((f.field_type, f.is_required), ('mobile', False), key)
        mig_mobile.backwards(django_apps, None)
        self.assertEqual({f.field_type for f in self.fields().values()}, {'text'})


mig_dates = importlib.import_module('apps.crimetab.migrations.0171_common_form_evidence_dates')


class CommonFormEvidenceDateTests(TestCase):
    """Migration 0171: ticking an Evidence checkbox shows its date."""

    def setUp(self):
        tmpl, _ = FieldTemplate.objects.get_or_create(template_name=mig_dates.TEMPLATE_NAME)
        for key, _, order, _ in mig_dates.DATES:
            FieldTemplateField.objects.update_or_create(
                template=tmpl, field_key=key,
                defaults={'field_label': key, 'field_type': 'checkbox',
                          'section': mig_dates.SECTION, 'display_order': order})
        for key, old, _ in mig_dates.MOVED:
            FieldTemplateField.objects.update_or_create(
                template=tmpl, field_key=key,
                defaults={'field_label': key, 'section': mig_dates.SECTION, 'display_order': old})

    def evidence(self):
        return list(FieldTemplateField.objects.filter(
            template__template_name=mig_dates.TEMPLATE_NAME, section=mig_dates.SECTION,
        ).order_by('display_order').values_list('field_key', 'field_type', 'depends_on_field_key',
                                                'depends_on_value', 'is_required'))

    def test_each_checkbox_is_followed_by_its_optional_date(self):
        mig_dates.forwards(django_apps, None)
        mig_dates.forwards(django_apps, None)
        rows = self.evidence()
        self.assertEqual([r[0] for r in rows], [
            'e_shakshya', 'e_shakshya_date', 'fingerprint_taken', 'fingerprint_taken_date',
            'nafis_fingerprint', 'nafis_fingerprint_date',
            'mobile_spot_recording', 'mobile_spot_recording_date'])
        dates = {r[0]: r for r in rows if r[0].endswith('_date') and r[1] == 'date'}
        for key, *_ in mig_dates.DATES:
            self.assertEqual(dates[key + '_date'][1:], ('date', key, None, False))

    def test_backwards_removes_the_dates(self):
        mig_dates.forwards(django_apps, None)
        mig_dates.backwards(django_apps, None)
        self.assertEqual([r[0] for r in self.evidence()], [
            'e_shakshya', 'fingerprint_taken', 'nafis_fingerprint',
            'mobile_spot_recording', 'mobile_spot_recording_date'])


mig_ids = importlib.import_module('apps.crimetab.migrations.0172_common_form_pan_aadhaar')


class CommonFormAadhaarPanTests(TestCase):
    """Migration 0172: Common Form Aadhaar / PAN are checked fields, still optional."""

    def setUp(self):
        tmpl, _ = FieldTemplate.objects.get_or_create(template_name=mig_ids.TEMPLATE_NAME)
        for key in mig_ids.TYPES:
            FieldTemplateField.objects.update_or_create(
                template=tmpl, field_key=key,
                defaults={'field_label': key, 'field_type': 'text', 'is_required': False})

    def fields(self):
        return {f.field_key: f for f in FieldTemplateField.objects.filter(
            template__template_name=mig_ids.TEMPLATE_NAME, field_key__in=list(mig_ids.TYPES))}

    def test_aadhaar_and_pan_types_and_not_required(self):
        mig_ids.forwards(django_apps, None)
        mig_ids.forwards(django_apps, None)
        for key, f in self.fields().items():
            self.assertEqual((f.field_type, f.is_required), (mig_ids.TYPES[key], False), key)
        self.assertIn(('pan', 'PAN Number (ABCDE1234F)'), FieldTemplateField._meta.get_field('field_type').choices)
        mig_ids.backwards(django_apps, None)
        self.assertEqual({f.field_type for f in self.fields().values()}, {'text'})
