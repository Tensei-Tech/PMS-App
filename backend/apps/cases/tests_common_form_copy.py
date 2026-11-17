"""The commonForm copy is folded into the top level and not stored (step A5)."""
from django.test import TestCase

from apps.cases.common_form_copy import fold_common_form
from apps.cases.models import CaseRecord
from apps.core.tenancy import TenantContext


class FoldCommonFormTests(TestCase):

    def test_answers_only_in_the_copy_move_up(self):
        out = fold_common_form({'a': 1, 'commonForm': {'regDate': '10/10/2026', 'accused': [{'name': 'Rohit'}]}})
        self.assertEqual(out, {'a': 1, 'regDate': '10/10/2026', 'accused': [{'name': 'Rohit'}]})

    def test_copy_wins_like_the_form_did_but_not_for_bookkeeping(self):
        out = fold_common_form({'crNo': 'CR/A1', 'lastEditedAt': 'new', 'blank': '',
                                'commonForm': {'crNo': 'A1', 'lastEditedAt': 'old', 'blank': 'x', 'empty': ''}})
        self.assertEqual(out['crNo'], 'A1')
        self.assertEqual(out['lastEditedAt'], 'new')
        self.assertEqual(out['blank'], 'x')
        self.assertNotIn('empty', out)

    def test_template_answers_are_merged_key_by_key(self):
        out = fold_common_form({'dynamic_extra_fields': {'witness_summons': 'false', 'caw_age': ''},
                                'commonForm': {'dynamic_extra_fields': {'caw_age': '12', 'caw_dna': ''}}})
        self.assertEqual(out['dynamic_extra_fields'], {'witness_summons': 'false', 'caw_age': '12'})

    def test_nested_older_copies_are_dropped(self):
        out = fold_common_form({'commonForm': {'x': 1, 'commonForm': {'y': 2}}, 'common_form': {'z': 3}})
        self.assertEqual(out, {'x': 1, 'z': 3})

    def test_without_a_copy_nothing_changes(self):
        extra = {'a': 1}
        self.assertIs(fold_common_form(extra), extra)
        self.assertIsNone(fold_common_form(None))

    def test_saving_a_case_stores_no_copy(self):
        with TenantContext('maharashtra'):
            case = CaseRecord.objects.create(id='CF_FOLD', case_number='CR/F', station_name='T',
                                             extra_fields={'commonForm': {'cctv_checked': True}})
            stored = CaseRecord.objects.get(pk='CF_FOLD').extra_fields
            self.assertEqual(stored, {'cctv_checked': True})
            self.assertTrue(case.pk)
