from django.test import TestCase

from apps.public_master.designation_matrix import MATRIX, NEVER, apply_matrix
from apps.public_master.models import Designation


def _designation(code, **extra):
    fields = dict(title=code, rank_level=5, allowed_categories=['field_officer'], allowed_admin_roles=[],
                  is_state_admin_allowed=False, is_district_admin_allowed=False,
                  is_division_admin_allowed=False, is_station_admin_allowed=False)
    fields.update(extra)
    return Designation.objects.update_or_create(code=code, defaults=fields)[0]


class DesignationMatrixTests(TestCase):
    def _flags(self, code):
        d = Designation.objects.get(code=code)
        return (d.is_state_admin_allowed, d.is_district_admin_allowed,
                d.is_division_admin_allowed, d.is_station_admin_allowed)

    def test_every_matrix_row_is_applied(self):
        for code in MATRIX:
            _designation(code, is_station_admin_allowed=True)
        apply_matrix(Designation)
        for code, row in MATRIX.items():
            self.assertEqual(self._flags(code), tuple(rule != NEVER for rule in row), code)

    def test_one_designation_allowed_at_several_levels(self):
        _designation('DCP', allowed_admin_roles=['district_admin'])
        apply_matrix(Designation)
        dcp = Designation.objects.get(code='DCP')
        # MUST levels first (district, division), then OPTIONAL (state).
        self.assertEqual(dcp.allowed_admin_roles, ['district_admin', 'division_admin', 'state_admin'])
        self.assertIn('admin_officer', dcp.allowed_categories)

    def test_never_levels_are_removed(self):
        _designation('ACP', is_station_admin_allowed=True, allowed_admin_roles=['station_admin', 'district_admin'])
        _designation('IG', is_division_admin_allowed=True)
        apply_matrix(Designation)
        self.assertEqual(self._flags('ACP'), (False, True, True, False))
        self.assertEqual(Designation.objects.get(code='ACP').allowed_admin_roles, ['division_admin', 'district_admin'])
        self.assertEqual(self._flags('IG'), (True, True, False, False))

    def test_spelling_variants_follow_their_row(self):
        for code in ['Addl. SP', 'Addl.SP', 'Addl. CP', 'Dy. SP', 'DGP']:
            _designation(code)
        apply_matrix(Designation)
        self.assertEqual(self._flags('Addl. SP'), self._flags('Addl.SP'))
        self.assertEqual(self._flags('Addl. SP'), (True, True, True, False))
        self.assertEqual(self._flags('Addl. CP'), (True, True, True, False))
        self.assertEqual(self._flags('Dy. SP'), (False, True, True, False))
        self.assertEqual(self._flags('DGP'), (True, False, False, False))

    def test_state_hq_ranks_stay_admin_only(self):
        _designation('DG', allowed_categories=['admin_officer'])
        apply_matrix(Designation)
        self.assertEqual(Designation.objects.get(code='DG').allowed_categories, ['admin_officer'])

    def test_ranks_outside_the_matrix_are_untouched(self):
        _designation('PC')
        _designation('TI', is_district_admin_allowed=True, allowed_admin_roles=['district_admin'])
        apply_matrix(Designation)
        self.assertEqual(self._flags('PC'), (False, False, False, False))
        self.assertEqual(Designation.objects.get(code='TI').allowed_admin_roles, ['district_admin'])
