from django.test import TestCase
from rest_framework.test import force_authenticate

from apps.crimetab.models import FieldTemplate, FieldTemplateField, ModuleSetting
from apps.crimetab.models.mpda import MpdaGangMember, MpdaProposal
from apps.crimetab.serializers_mpda import MpdaProposalDetailSerializer
from apps.crimetab.tests.test_mpda_backend import MpdaBackendTestCase
from apps.crimetab.views_mpda import (
    MpdaDetailView,
    MpdaListCreateView,
    MpdaPDFView,
    get_mpda_repeating_sections,
)

GANG = {
    'mpda_gang_member_name': 'TEST Raju', 'mpda_gang_member_age': '28',
    'mpda_gang_member_gender': 'Male', 'mpda_gang_member_mobile': '9876543210',
    'mpda_gang_member_aadhaar': '123412341234', 'mpda_gang_member_address': 'TEST Pune',
    'mpda_gang_member_occupation': 'TEST Driver', 'mpda_gang_member_pan': 'TESTP1234',
    'mpda_gang_member_cast': 'TEST Cast', 'mpda_gang_member_religion': 'TEST Religion',
}


class MpdaGangMemberDetailsTests(TestCase):
    def setUp(self):
        # Same seeded settings / options / user as the MPDA backend suite
        MpdaBackendTestCase.setUp(self)
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='enforce_permissions',
                                               defaults={'setting_value': 'false'})

    def _create(self, gang):
        req = self.factory.post('/api/mpda/', {'mpda_proposal_no_and_year': 'TEST 9/2026',
                                               'mpda_gang_members': gang}, format='json')
        force_authenticate(req, user=self.user)
        res = MpdaListCreateView.as_view()(req)
        self.assertIn(res.status_code, (200, 201), res.data)
        return MpdaProposal.objects.order_by('-id').first()

    def test_all_details_are_saved_and_returned_for_edit(self):
        prop = self._create([GANG])
        gm = MpdaGangMember.objects.get(proposal=prop)
        self.assertEqual((gm.name, gm.age, gm.gender, gm.mobile, gm.aadhaar, gm.address, gm.occupation,
                          gm.pan, gm.cast, gm.religion),
                         ('TEST Raju', 28, 'Male', '9876543210', '123412341234', 'TEST Pune', 'TEST Driver',
                          'TESTP1234', 'TEST Cast', 'TEST Religion'))
        data = MpdaProposalDetailSerializer(prop).data
        edit_row = data['mpda_gang_members'][0]
        for key, value in GANG.items():
            self.assertEqual(edit_row[key], value)

    def test_member_without_name_but_with_details_is_kept_and_bad_values_dropped(self):
        prop = self._create([{'mpda_gang_member_age': '300', 'mpda_gang_member_mobile': '123',
                              'mpda_gang_member_occupation': 'TEST Only Occupation'}, {}])
        members = list(MpdaGangMember.objects.filter(proposal=prop))
        self.assertEqual(len(members), 1)
        self.assertEqual((members[0].age, members[0].mobile, members[0].occupation),
                         (None, None, 'TEST Only Occupation'))

    def test_edit_replaces_members(self):
        prop = self._create([GANG])
        req = self.factory.patch(f'/api/mpda/{prop.id}/', {
            'mpda_gang_members': [{'mpda_gang_member_name': 'TEST New', 'mpda_gang_member_age': '33'}],
        }, format='json')
        force_authenticate(req, user=self.user)
        self.assertEqual(MpdaDetailView.as_view()(req, pk=prop.id).status_code, 200)
        self.assertEqual(list(MpdaGangMember.objects.filter(proposal=prop).values_list('name', 'age')),
                         [('TEST New', 33)])

    def test_view_rows_follow_the_form_fields_and_pdf_renders(self):
        tmpl, _ = FieldTemplate.objects.get_or_create(template_name='TEST MPDA Template')
        parent = FieldTemplateField.objects.create(template=tmpl, field_key='mpda_gang_members',
                                                   field_label='TEST Gang', field_type='repeating_group',
                                                   display_order=150)
        for order, (key, label) in enumerate([('mpda_gang_member_name', 'TEST Name'),
                                              ('mpda_gang_member_age', 'TEST Age'),
                                              ('mpda_gang_member_mobile', 'TEST Mobile')], 151):
            FieldTemplateField.objects.create(template=tmpl, field_key=key, field_label=label,
                                              field_type='text', display_order=order,
                                              parent_field_key='mpda_gang_members')
        prop = self._create([GANG])
        ftfs = [parent] + list(FieldTemplateField.objects.filter(template=tmpl,
                                                                 parent_field_key='mpda_gang_members')
                               .order_by('display_order'))
        sections = {s[3]: s for s in get_mpda_repeating_sections(prop, ftfs=ftfs)}
        _title, headers, rows, _key = sections['mpda_gang_members']
        self.assertEqual(headers, ['Sr. No.', 'TEST Name', 'TEST Age', 'TEST Mobile'])
        self.assertEqual(rows, [['1', 'TEST Raju', '28', '9876543210']])

        req = self.factory.get(f'/api/mpda/{prop.id}/pdf/')
        force_authenticate(req, user=self.user)
        res = MpdaPDFView.as_view()(req, pk=prop.id)
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res['Content-Type'], 'application/pdf')
