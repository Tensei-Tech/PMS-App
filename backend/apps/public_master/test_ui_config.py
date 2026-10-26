"""GET /api/master/ui-config/ is public and must never fail with a 500."""
from unittest import mock

from django.db import ProgrammingError
from django.test import TestCase
from rest_framework.test import APIClient

from apps.public_master.models import DynamicUIConfig
from apps.public_master.views import DEFAULT_UI_CONFIG

URL = '/api/master/ui-config/'


class UIConfigViewTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_stored_configs_are_returned(self):
        DynamicUIConfig.objects.create(key='repeat_offender_summary', value={'title': 'Custom'})
        response = self.client.get(URL)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data, {'repeat_offender_summary': {'title': 'Custom'}})

    def test_empty_table_returns_defaults(self):
        response = self.client.get(URL)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data, DEFAULT_UI_CONFIG)

    def test_missing_table_returns_defaults_not_500(self):
        # Live case: the table sits in a state schema, so the public search_path cannot see it.
        with mock.patch.object(
            DynamicUIConfig.objects, 'all',
            side_effect=ProgrammingError('relation "dynamic_ui_configs" does not exist'),
        ):
            response = self.client.get(URL)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data, DEFAULT_UI_CONFIG)
