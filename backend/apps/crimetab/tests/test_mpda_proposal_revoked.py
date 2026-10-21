import datetime

from django.test import TestCase
from rest_framework.test import force_authenticate

from apps.crimetab.models import ModuleSetting
from apps.crimetab.models.mpda import MpdaProposal
from apps.crimetab.serializers_mpda import MpdaProposalDetailSerializer
from apps.crimetab.tests.test_mpda_backend import MpdaBackendTestCase
from apps.crimetab.views_mpda import MpdaDetailView, MpdaListCreateView, MpdaPDFView


class MpdaProposalRevokedTests(TestCase):
    def setUp(self):
        MpdaBackendTestCase.setUp(self)
        ModuleSetting.objects.update_or_create(module_key='mpda', setting_key='enforce_permissions',
                                               defaults={'setting_value': 'false'})

    def _create(self, payload):
        req = self.factory.post('/api/mpda/', {'mpda_proposal_no_and_year': 'TEST 7/2026', **payload},
                                format='json')
        force_authenticate(req, user=self.user)
        res = MpdaListCreateView.as_view()(req)
        self.assertIn(res.status_code, (200, 201), res.data)
        return MpdaProposal.objects.order_by('-id').first()

    def _patch(self, prop, payload):
        req = self.factory.patch(f'/api/mpda/{prop.id}/', payload, format='json')
        force_authenticate(req, user=self.user)
        self.assertEqual(MpdaDetailView.as_view()(req, pk=prop.id).status_code, 200)
        prop.refresh_from_db()

    def test_yes_saves_date_and_returns_it_for_edit(self):
        prop = self._create({'mpda_proposal_outcome': 'Granted', 'mpda_granted_date': '01/10/2026',
                             'mpda_proposal_revoked': 'Yes', 'mpda_proposal_revoked_date': '12/10/2026'})
        self.assertEqual((prop.proposal_revoked, prop.proposal_revoked_date),
                         ('Yes', datetime.date(2026, 10, 12)))
        data = MpdaProposalDetailSerializer(prop).data
        self.assertEqual(data['mpda_proposal_revoked'], 'Yes')
        self.assertEqual(data['mpda_proposal_revoked_date'], '12/10/2026')

    def test_no_clears_the_date(self):
        prop = self._create({'mpda_proposal_revoked': 'No', 'mpda_proposal_revoked_date': '12/10/2026'})
        self.assertEqual((prop.proposal_revoked, prop.proposal_revoked_date), ('No', None))

    def test_patch_switching_to_no_clears_date_and_other_patch_keeps_it(self):
        prop = self._create({'mpda_proposal_revoked': 'Yes', 'mpda_proposal_revoked_date': '12/10/2026'})
        self._patch(prop, {'mpda_jail_name': 'TEST Jail'})
        self.assertEqual(prop.proposal_revoked_date, datetime.date(2026, 10, 12))
        self._patch(prop, {'mpda_proposal_revoked': 'No'})
        self.assertEqual((prop.proposal_revoked, prop.proposal_revoked_date), ('No', None))

    def test_detail_returns_keyed_display_fields(self):
        prop = self._create({'mpda_proposal_revoked': 'Yes', 'mpda_proposal_revoked_date': '12/10/2026'})
        req = self.factory.get(f'/api/mpda/{prop.id}/')
        force_authenticate(req, user=self.user)
        res = MpdaDetailView.as_view()(req, pk=prop.id)
        self.assertEqual(res.status_code, 200)
        self.assertIn('display_fields', res.data)
        for f in res.data['display_fields']:
            self.assertEqual(set(f), {'field_key', 'label', 'value', 'section'})

    def test_pdf_renders(self):
        prop = self._create({'mpda_proposal_revoked': 'Yes', 'mpda_proposal_revoked_date': '12/10/2026'})
        req = self.factory.get(f'/api/mpda/{prop.id}/pdf/')
        force_authenticate(req, user=self.user)
        res = MpdaPDFView.as_view()(req, pk=prop.id)
        self.assertEqual(res.status_code, 200)
