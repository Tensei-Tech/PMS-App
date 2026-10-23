from io import StringIO

from django.core.management import call_command
from django.test import TestCase

from apps.crimetab.act_names import get_act, official_act_name
from apps.crimetab.models.common_form import Act, ActSection

BNS = 'THE BHARATIYA NYAYA SANHITA (BNS), 2023'


class ActNamesTests(TestCase):
    def test_short_and_old_names_resolve_to_the_official_act(self):
        for name in ('BNS', 'BNS 2023', 'bns2023', 'Bharatiya Nyaya Sanhita 2023'):
            self.assertEqual(official_act_name(name), BNS)
        self.assertEqual(official_act_name('TEST Unknown Act'), 'TEST Unknown Act')

    def test_get_act_reuses_the_existing_act(self):
        act = Act.objects.create(act_name=BNS)
        self.assertEqual(get_act('BNS').pk, act.pk)
        self.assertEqual(get_act('Bharatiya Nyaya Sanhita 2023').pk, act.pk)
        self.assertEqual(Act.objects.count(), 1)

    def test_seed_scripts_do_not_create_a_second_bns_act(self):
        act = Act.objects.create(act_name=BNS)
        ActSection.objects.create(act=act, section_number='309', section_title='TEST Robbery title')
        call_command('seed_crimetab', stdout=StringIO())
        call_command('seed_common_form', stdout=StringIO())
        self.assertEqual(list(Act.objects.values_list('act_name', flat=True)), [BNS])
        # Sections the seeds use are added to that act; imported titles are kept
        self.assertEqual(ActSection.objects.get(act=act, section_number='309').section_title,
                         'TEST Robbery title')
        self.assertTrue(ActSection.objects.filter(act=act, section_number='310').exists())
