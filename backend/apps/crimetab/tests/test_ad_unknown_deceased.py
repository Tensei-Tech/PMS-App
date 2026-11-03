import importlib

from django.apps import apps as django_apps
from django.core.cache import cache
from django.test import TestCase

from apps.cases.models import CaseRecord
from apps.crimetab.models.dynamic_engine import FieldTemplateField
from apps.crimetab.tests.test_ad_backend import AdBackendTests, _seed_ad_public_data
from apps.crimetab.views_ad import AdDetailView

mig = importlib.import_module('apps.crimetab.migrations.0161_ad_unknown_deceased_multiple')

UNKNOWN = {'ad_deceased_identity': 'Unknown'}


class AdUnknownDeceasedFormTests(TestCase):
    """Migration 0161: Unknown Deceased Details is a list of persons."""

    def setUp(self):
        _seed_ad_public_data()

    def fields(self):
        return {f.field_key: f for f in FieldTemplateField.objects.filter(
            template__template_name=mig.TEMPLATE_NAME)}

    def test_unknown_details_are_a_list_shown_on_unknown(self):
        f = self.fields()
        group = f[mig.GROUP_KEY]
        self.assertEqual(group.field_type, 'repeating_group')
        self.assertEqual(group.section, mig.SECTION)
        self.assertEqual((group.depends_on_field_key, group.depends_on_value),
                         ('ad_deceased_identity', 'Unknown'))
        for key in mig.CHILD_KEYS:
            self.assertEqual(f[key].parent_field_key, mig.GROUP_KEY, key)
        # The list shows the person's fields; relatives still need the tick
        self.assertIsNone(f['ad_unknown_injury'].depends_on_field_key)
        self.assertEqual(f['ad_relative_name'].depends_on_field_key, 'ad_body_funeral_relative')
        self.assertLess(group.display_order, f['ad_unknown_approx_age'].display_order)

    def test_idempotent_and_backwards_restores_single_fields(self):
        mig.forwards(django_apps, None)
        self.assertEqual(FieldTemplateField.objects.filter(field_key=mig.GROUP_KEY).count(), 1)
        mig.backwards(django_apps, None)
        f = self.fields()
        self.assertNotIn(mig.GROUP_KEY, f)
        self.assertIsNone(f['ad_unknown_injury'].parent_field_key)
        self.assertEqual(f['ad_unknown_injury'].depends_on_value, 'Unknown')
        self.assertEqual(f['ad_relative_name'].depends_on_field_key, 'ad_body_funeral_relative')
        mig.forwards(django_apps, None)
        self.assertEqual(self.fields()['ad_unknown_injury'].parent_field_key, mig.GROUP_KEY)

    def test_saved_single_answers_move_into_person_one(self):
        old = CaseRecord.objects.create(
            case_number='TEST_AD_OLD',
            extra_fields={'ad_deceased_identity': 'Unknown', 'ad_unknown_injury': 'TEST cut',
                          'ad_body_funeral_relative': True, 'ad_relative_name': 'TEST Sita',
                          'ad_postmortem': 'No'})
        other = CaseRecord.objects.create(
            case_number='TEST_AD_OTHER', extra_fields={'ad_postmortem': 'Yes'})
        mig.forwards(django_apps, None)
        old.refresh_from_db()
        self.assertEqual(old.extra_fields[mig.GROUP_KEY], [{
            'ad_unknown_injury': 'TEST cut', 'ad_body_funeral_relative': True,
            'ad_relative_name': 'TEST Sita'}])
        self.assertNotIn('ad_unknown_injury', old.extra_fields)
        self.assertEqual(old.extra_fields['ad_postmortem'], 'No')
        other.refresh_from_db()
        self.assertEqual(other.extra_fields, {'ad_postmortem': 'Yes'})

        mig.backwards(django_apps, None)
        old.refresh_from_db()
        self.assertNotIn(mig.GROUP_KEY, old.extra_fields)
        self.assertEqual(old.extra_fields['ad_unknown_injury'], 'TEST cut')
        self.assertEqual(old.extra_fields['ad_relative_name'], 'TEST Sita')


class AdUnknownDeceasedApiTests(AdBackendTests):
    """Saving, cleaning and showing several unknown deceased through the API."""

    TWO_PERSONS = {
        **UNKNOWN,
        mig.GROUP_KEY: [
            {'ad_unknown_approx_age': '40', 'ad_unknown_injury': 'TEST head',
             'ad_body_funeral_relative': True, 'ad_relative_name': 'TEST Sita'},
            # Relative not ticked: the relative's name is dropped for this person
            {'ad_unknown_approx_age': '25', 'ad_relative_name': 'TEST ignored',
             'ad_gazette': True},
        ],
    }

    def setUp(self):
        cache.clear()
        super().setUp()

    def test_two_unknown_deceased_are_saved(self):
        res = self.create({'case_number': 'TEST_AD_U1', **self.TWO_PERSONS})
        self.assertEqual(res.status_code, 201, res.data)
        rows = CaseRecord.objects.get(pk=res.data['id']).extra_fields[mig.GROUP_KEY]
        self.assertEqual(len(rows), 2)
        self.assertEqual(rows[0]['ad_relative_name'], 'TEST Sita')
        self.assertEqual(rows[1], {'ad_unknown_approx_age': '25', 'ad_gazette': True})

    def test_unknown_list_dropped_when_deceased_is_known(self):
        res = self.create({'case_number': 'TEST_AD_U2', **self.TWO_PERSONS,
                           'ad_deceased_identity': 'Known'})
        extra = CaseRecord.objects.get(pk=res.data['id']).extra_fields
        self.assertNotIn(mig.GROUP_KEY, extra)

    def test_view_shows_one_block_per_unknown_deceased(self):
        rid = self.create({'case_number': 'TEST_AD_U3', **self.TWO_PERSONS}).data['id']
        det = AdDetailView.as_view()(self._req('get', f'/api/ad/{rid}/'), pk=rid).data
        blocks = {s['title']: {r['label']: r['value'] for r in s['rows']}
                  for s in det['sections'] if s['title'].startswith(mig.GROUP_LABEL)}
        self.assertEqual(set(blocks), {'Unknown Deceased 1', 'Unknown Deceased 2'})
        self.assertEqual(blocks['Unknown Deceased 1']['Relative Name'], 'TEST Sita')
        self.assertNotIn('Relative Name', blocks['Unknown Deceased 2'])
        self.assertEqual(len(det['form_data'][mig.GROUP_KEY]), 2)
