import importlib

from django.apps import apps as django_apps
from django.core.cache import cache
from django.test import TestCase

from apps.cases.models import CaseRecord
from apps.crimetab.models.dynamic_engine import FieldTemplateField
from apps.crimetab.tests.test_ad_backend import AdBackendTests, _seed_ad_public_data
from apps.crimetab.views_ad import AdDetailView

mig = importlib.import_module('apps.crimetab.migrations.0161_ad_unknown_deceased_multiple')
mig_same_card = importlib.import_module(
    'apps.crimetab.migrations.0165_ad_unknown_deceased_in_deceased_details')
mig_pm_report = importlib.import_module('apps.crimetab.migrations.0166_ad_pm_report')
mig_checkboxes = importlib.import_module('apps.crimetab.migrations.0167_ad_yes_no_to_checkboxes')
mig_card = importlib.import_module('apps.crimetab.migrations.0168_ad_deceased_and_inquiry_card')
mig_persons = importlib.import_module('apps.crimetab.migrations.0173_ad_deceased_person_list')


def _seed_before_persons():
    """The A.D. form as 0161-0168 left it: 0169 (per-person list) undone."""
    _seed_ad_public_data()
    mig_persons.backwards(django_apps, None)

UNKNOWN = {'ad_deceased_identity': 'Unknown'}


class AdUnknownDeceasedFormTests(TestCase):
    """Migration 0161: Unknown Deceased Details is a list of persons."""

    def setUp(self):
        _seed_before_persons()

    def fields(self):
        return {f.field_key: f for f in FieldTemplateField.objects.filter(
            template__template_name=mig.TEMPLATE_NAME)}

    def test_unknown_details_are_a_list_shown_on_unknown(self):
        f = self.fields()
        group = f[mig.GROUP_KEY]
        self.assertEqual(group.field_type, 'repeating_group')
        # 0165 moved the list into the Known list's card
        self.assertEqual(group.section, mig_same_card.NEW_SECTION)
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


class AdUnknownDeceasedSameCardTests(TestCase):
    """Migration 0165: Unknown Deceased opens in the Deceased Details card."""

    def setUp(self):
        _seed_before_persons()

    def sections(self):
        return dict(FieldTemplateField.objects.filter(
            template__template_name=mig.TEMPLATE_NAME).values_list('field_key', 'section'))

    def test_known_and_unknown_lists_share_one_card(self):
        s = self.sections()
        self.assertEqual(s['ad_deceased_identity'], 'Deceased Details')
        self.assertEqual(s['ad_deceased'], 'Deceased Details')
        for key in [mig.GROUP_KEY] + mig.CHILD_KEYS:
            self.assertEqual(s[key], 'Deceased Details', key)
        self.assertNotIn(mig_same_card.OLD_SECTION, s.values())

    def test_idempotent_and_backwards_moves_only_the_unknown_list(self):
        mig_same_card.forwards(django_apps, None)
        mig_same_card.backwards(django_apps, None)
        s = self.sections()
        for key in [mig.GROUP_KEY] + mig.CHILD_KEYS:
            self.assertEqual(s[key], mig_same_card.OLD_SECTION, key)
        self.assertEqual(s['ad_deceased'], 'Deceased Details')
        self.assertEqual(s['ad_deceased_identity'], 'Deceased Details')
        mig_same_card.forwards(django_apps, None)
        self.assertEqual(self.sections()[mig.GROUP_KEY], 'Deceased Details')


class AdPmReportTests(TestCase):
    """Migration 0166: PM Report (Yes/No) with its date in Post Mortem."""

    def setUp(self):
        _seed_before_persons()

    def test_pm_report_and_date_shown_when_ticked(self):
        f = {x.field_key: x for x in FieldTemplateField.objects.filter(
            template__template_name=mig.TEMPLATE_NAME)}
        report, date = f['ad_pm_report'], f['ad_pm_report_date']
        # 0167 turned the Yes / No radio into a checkbox
        self.assertEqual((report.field_type, report.section), ('checkbox', 'Post Mortem'))
        self.assertIsNone(report.options_source)
        self.assertEqual(date.field_type, 'date')
        self.assertEqual((date.depends_on_field_key, date.depends_on_value),
                         ('ad_pm_report', None))
        self.assertLess(f['ad_postmortem_date'].display_order, report.display_order)
        self.assertLess(report.display_order, date.display_order)

    def test_idempotent_and_backwards_removes_them(self):
        mig_pm_report.forwards(django_apps, None)
        keys = ['ad_pm_report', 'ad_pm_report_date']
        self.assertEqual(FieldTemplateField.objects.filter(field_key__in=keys).count(), 2)
        mig_pm_report.backwards(django_apps, None)
        self.assertFalse(FieldTemplateField.objects.filter(field_key__in=keys).exists())
        mig_pm_report.forwards(django_apps, None)
        self.assertEqual(FieldTemplateField.objects.filter(field_key__in=keys).count(), 2)


class AdYesNoCheckboxTests(TestCase):
    """Migration 0167: A.D. Yes / No radios are checkboxes; ticked shows the date."""

    def setUp(self):
        _seed_before_persons()
        from apps.cases.tests_disposal import seed_ad_disposal_rule
        seed_ad_disposal_rule()
        mig_checkboxes.forwards(django_apps, None)
        cache.clear()

    def fields(self):
        return {f.field_key: f for f in FieldTemplateField.objects.filter(
            template__template_name=mig.TEMPLATE_NAME)}

    def test_yes_no_fields_are_checkboxes_and_dates_show_when_ticked(self):
        f = self.fields()
        for key in mig_checkboxes.KEYS:
            self.assertEqual(f[key].field_type, 'checkbox', key)
            self.assertIsNone(f[key].options_source, key)
        for key in ('ad_postmortem_date', 'ad_pm_report_date', 'ad_fsl_ca_sent_date',
                    'ad_seized_items', 'ad_summary_sent_date', 'ad_sdm_granted_date'):
            self.assertIsNotNone(f[key].depends_on_field_key, key)
            self.assertIsNone(f[key].depends_on_value, key)
        # Not a Yes / No question: stays a radio
        self.assertEqual(f['ad_deceased_identity'].field_type, 'radio')

    def test_saved_yes_becomes_ticked_and_no_is_dropped(self):
        case = CaseRecord.objects.create(
            case_number='TEST_AD_CB', module_key='ad',
            extra_fields={'ad_postmortem': 'Yes', 'ad_postmortem_date': '01/11/2026',
                          'ad_pm_report': 'No', 'ad_cause_of_death': 'TEST'})
        mig_checkboxes.forwards(django_apps, None)
        case.refresh_from_db()
        self.assertEqual(case.extra_fields, {'ad_postmortem': True,
                                             'ad_postmortem_date': '01/11/2026',
                                             'ad_cause_of_death': 'TEST'})
        mig_checkboxes.backwards(django_apps, None)
        case.refresh_from_db()
        self.assertEqual(case.extra_fields['ad_postmortem'], 'Yes')
        self.assertEqual(self.fields()['ad_postmortem'].field_type, 'radio')
        self.assertEqual(self.fields()['ad_postmortem_date'].depends_on_value, 'Yes')

    def test_sdm_granted_ticked_with_date_is_disposal(self):
        from apps.cases.models import is_ad_case_disposed
        self.assertTrue(is_ad_case_disposed({
            'module_key': 'ad',
            'extra_fields': {'ad_sdm_granted': True, 'ad_sdm_granted_date': '02/11/2026'}}))
        # Older "Yes" answers still count
        self.assertTrue(is_ad_case_disposed({
            'module_key': 'ad',
            'extra_fields': {'ad_sdm_granted': 'Yes', 'ad_sdm_granted_date': '02/11/2026'}}))
        self.assertFalse(is_ad_case_disposed({
            'module_key': 'ad', 'extra_fields': {'ad_sdm_granted': True}}))


class AdOneCardTests(TestCase):
    """Migration 0168: A.D. sections 2-7 share one card, headings unchanged."""

    def setUp(self):
        _seed_before_persons()

    def cards(self):
        return {(f.section, (f.field_config or {}).get('card'))
                for f in FieldTemplateField.objects.filter(template__template_name=mig.TEMPLATE_NAME)}

    def test_sections_two_to_seven_share_the_card(self):
        cards = self.cards()
        for section in mig_card.SECTIONS:
            self.assertIn((section, mig_card.CARD_TITLE), cards)
        self.assertIn(('AD Scrutiny', None), cards)
        self.assertIn(('AD Registration Info and Year', None), cards)

    def test_idempotent_and_backwards_removes_the_card(self):
        mig_card.forwards(django_apps, None)
        mig_card.backwards(django_apps, None)
        self.assertEqual({card for _, card in self.cards()}, {None})
        mig_card.forwards(django_apps, None)
        self.assertIn(('Post Mortem', mig_card.CARD_TITLE), self.cards())


class AdPersonListTests(TestCase):
    """Migration 0169: the card repeats per dead person."""

    def setUp(self):
        _seed_ad_public_data()

    def fields(self):
        return {f.field_key: f for f in FieldTemplateField.objects.filter(
            template__template_name=mig.TEMPLATE_NAME)}

    def test_each_person_has_details_and_inquiry(self):
        f = self.fields()
        group = f[mig_persons.GROUP_KEY]
        self.assertEqual((group.field_type, group.section), ('repeating_group', 'Deceased Details'))
        self.assertEqual(group.field_config.get('card'), mig_card.CARD_TITLE)
        self.assertTrue(group.field_config.get('start_with_one_row'))
        for key in mig_persons.CHILD_KEYS:
            self.assertEqual(f[key].parent_field_key, mig_persons.GROUP_KEY, key)
        for gone in ('ad_deceased', 'ad_unknown_deceased', 'ad_seized_item_name'):
            self.assertNotIn(gone, f)
        self.assertEqual((f['ad_deceased_name'].depends_on_field_key, f['ad_deceased_name'].depends_on_value),
                         ('ad_deceased_identity', 'Known'))
        self.assertEqual(f['ad_unknown_injury'].depends_on_value, 'Unknown')
        self.assertEqual(f['ad_relative_name'].depends_on_field_key, 'ad_body_funeral_relative')
        self.assertEqual(f['ad_seized_items'].field_type, 'textarea')
        self.assertEqual(f['ad_postmortem'].field_config.get('heading'), 'Post Mortem')
        self.assertEqual(f['ad_fsl_ca_sent'].field_config.get('heading'), 'FSL / CA')
        # Scrutiny and Summary stay once per case
        self.assertIsNone(f['ad_sdm_granted'].parent_field_key)

    def test_saved_cases_move_into_person_rows(self):
        old = CaseRecord.objects.create(
            case_number='TEST_AD_P1', module_key='ad', extra_fields={
                'ad_deceased_identity': 'Unknown', 'ad_sdm_returned': True,
                'ad_unknown_deceased': [{'ad_unknown_injury': 'TEST cut'}, {'ad_gazette': True}],
                'ad_postmortem': True, 'ad_postmortem_date': '01/11/2026',
                'ad_seized_items': [{'ad_seized_item_name': 'TEST rope',
                                     'ad_seized_item_description': 'blue'}],
                'ad_inquest_panchanama': True, 'ad_inquest_panchanama_date': '02/11/2026 10:00',
                'ad_exhumation_panchanama': False})
        mig_persons.forwards(django_apps, None)
        old.refresh_from_db()
        self.assertEqual(old.extra_fields, {
            'ad_sdm_returned': True,
            'ad_persons': [
                {'ad_deceased_identity': 'Unknown', 'ad_unknown_injury': 'TEST cut',
                 'ad_postmortem': True, 'ad_postmortem_date': '01/11/2026',
                 'ad_seized_items': 'TEST rope - blue', 'ad_inquest_panchanama': True,
                 'ad_inquest_panchanama_date': '02/11/2026 10:00'},
                {'ad_deceased_identity': 'Unknown', 'ad_gazette': True},
            ]})
        mig_persons.forwards(django_apps, None)
        old.refresh_from_db()
        self.assertEqual(len(old.extra_fields['ad_persons']), 2)

        mig_persons.backwards(django_apps, None)
        old.refresh_from_db()
        self.assertEqual(old.extra_fields['ad_unknown_deceased'],
                         [{'ad_unknown_injury': 'TEST cut'}, {'ad_gazette': True}])
        self.assertEqual(old.extra_fields['ad_postmortem_date'], '01/11/2026')
        self.assertEqual(old.extra_fields['ad_seized_items'], [{'ad_seized_item_name': 'TEST rope - blue'}])
        self.assertIn('ad_deceased', self.fields())
        self.assertNotIn(mig_persons.GROUP_KEY, self.fields())


class AdPersonsApiTests(AdBackendTests):
    """Saving, cleaning and showing several deceased persons through the API."""

    TWO_PERSONS = {
        mig_persons.GROUP_KEY: [
            {'ad_deceased_identity': 'Unknown', 'ad_unknown_approx_age': '40',
             'ad_body_funeral_relative': True, 'ad_relative_name': 'TEST Sita',
             'ad_postmortem': True, 'ad_postmortem_date': '01/11/2026'},
            # Known: the Unknown answers and the unticked relative's name are dropped
            {'ad_deceased_identity': 'Known', 'ad_deceased_name': 'TEST Ram',
             'ad_unknown_injury': 'TEST ignored', 'ad_relative_name': 'TEST ignored',
             'ad_cause_of_death': 'Hanging'},
        ],
    }

    def setUp(self):
        cache.clear()
        super().setUp()

    def test_each_person_keeps_their_own_answers(self):
        res = self.create({'case_number': 'TEST_AD_U1', **self.TWO_PERSONS})
        self.assertEqual(res.status_code, 201, res.data)
        rows = CaseRecord.objects.get(pk=res.data['id']).extra_fields[mig_persons.GROUP_KEY]
        self.assertEqual(len(rows), 2)
        self.assertEqual(rows[0]['ad_relative_name'], 'TEST Sita')
        self.assertEqual(rows[0]['ad_postmortem_date'], '01/11/2026')
        self.assertEqual(rows[1], {'ad_deceased_identity': 'Known', 'ad_deceased_name': 'TEST Ram',
                                   'ad_cause_of_death': 'Hanging'})

    def test_view_shows_one_block_per_person(self):
        rid = self.create({'case_number': 'TEST_AD_U3', **self.TWO_PERSONS}).data['id']
        det = AdDetailView.as_view()(self._req('get', f'/api/ad/{rid}/'), pk=rid).data
        blocks = {s['title']: {r['label']: r['value'] for r in s['rows']}
                  for s in det['sections'] if s['title'].startswith(mig_persons.GROUP_LABEL)}
        self.assertEqual(set(blocks), {'Deceased Person 1', 'Deceased Person 2'})
        self.assertEqual(blocks['Deceased Person 1']['Relative Name'], 'TEST Sita')
        # PM's date is its own row, not repeated beside the tick. Labels come
        # from the form: "PM (Post Mortem)" reads "PM" after 0164
        labels = {f.field_key: f.field_label for f in FieldTemplateField.objects.filter(
            field_key__in=('ad_postmortem', 'ad_postmortem_date'))}
        person_one = blocks['Deceased Person 1']
        self.assertEqual(person_one[labels['ad_postmortem_date']], '01/11/2026')
        self.assertNotIn('01/11/2026', person_one[labels['ad_postmortem']])
        self.assertEqual(blocks['Deceased Person 2']['Name'], 'TEST Ram')
        self.assertEqual(len(det['form_data'][mig_persons.GROUP_KEY]), 2)
