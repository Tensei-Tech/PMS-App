"""
The hierarchy screen's Divisions tab lists real sub-divisions (the ones
division admins hold, with their district), never the six old regional
divisions; admin kinds come from the role, not the designation.
"""
from django.db import connection
from rest_framework import status

from apps.authentication.test_security_holes import SecurityTestBase, _officer, _officer_headers, _save_everywhere

OLD_REGIONAL_DIVISIONS = {'Konkan', 'Pune', 'Nashik', 'Chhatrapati Sambhajinagar', 'Amravati', 'Nagpur'}


class HierarchyDivisionsTests(SecurityTestBase):
    def setUp(self):
        super().setUp()
        self.state_admin = _officer('state_admin', station='', district='', division='')
        self.shirdi = _officer('division_admin', station='', district='Ahilyanagar', division='Shirdi Sub-Division')
        self.karad = _officer('division_admin', station='', district='Satara', division='Karad Sub-Division')
        self.district_admin = _officer('district_admin', station='', district='Ahilyanagar', division='')
        self.district_admin.designation = 'DIG'  # a division-like rank must not move them under Divisions
        _save_everywhere(self.district_admin)

    def _directory(self, caller):
        response = self.client.get('/api/users/hierarchy-directory/', **_officer_headers(caller))
        self.assertEqual(response.status_code, status.HTTP_200_OK, response.data)
        return response.data

    def test_divisions_are_the_sub_divisions_division_admins_hold(self):
        data = self._directory(self.state_admin)
        divisions = {(d['name'], d['district']): [a['uid'] for a in d['admins']] for d in data['divisions']}
        self.assertEqual(divisions, {
            ('Shirdi Sub-Division', 'Ahilyanagar'): [self.shirdi.uid],
            ('Karad Sub-Division', 'Satara'): [self.karad.uid],
        })
        self.assertFalse({d['name'] for d in data['divisions']} & OLD_REGIONAL_DIVISIONS)
        self.assertFalse(any(name.endswith(' Division') and name.split(' Division')[0] in OLD_REGIONAL_DIVISIONS
                             for name in (d['name'] for d in data['divisions'])))

    def test_district_admin_is_listed_by_role_not_designation(self):
        data = self._directory(self.state_admin)
        district_admins = [a['uid'] for d in data['districts'] for a in d['admins']]
        division_admins = [a['uid'] for d in data['divisions'] for a in d['admins']]
        self.assertIn(self.district_admin.uid, district_admins)
        self.assertNotIn(self.district_admin.uid, division_admins)

    def test_division_admin_sees_only_their_sub_division_and_district(self):
        data = self._directory(self.shirdi)
        self.assertEqual([d['name'] for d in data['divisions']], ['Shirdi Sub-Division'])
        self.assertEqual(data['assigned_division'], 'Shirdi Sub-Division')
        self.assertTrue(all(d['name'].casefold() == 'ahilyanagar' for d in data['districts']))


class PlaceholderDivisionsRemovedTests(SecurityTestBase):
    def test_no_old_regional_division_rows_after_migrations(self):
        if connection.vendor != 'postgresql':
            self.skipTest('master_divisions lives in Postgres state schemas only')
        with connection.cursor() as cursor:
            cursor.execute("SELECT table_schema FROM information_schema.tables WHERE table_name = 'master_divisions'")
            for (schema,) in cursor.fetchall():
                cursor.execute(f'SELECT name FROM "{schema}".master_divisions')
                names = {row[0] for row in cursor.fetchall()}
                self.assertFalse(names & OLD_REGIONAL_DIVISIONS, schema)
