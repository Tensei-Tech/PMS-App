"""Tests for the Android in-app update endpoints (no database, GitHub mocked)."""
from unittest import mock

import requests
from django.test import RequestFactory, SimpleTestCase, override_settings

from apps.core.app_version import AppDownloadView, AppVersionView

RELEASE_SETTINGS = dict(
    APP_LATEST_BUILD='42',
    APP_MIN_BUILD='40',
    APP_DOWNLOAD_URL='',
    APP_RELEASE_REPO='Tensei-Tech/PMS-App',
    APP_RELEASE_GITHUB_TOKEN='test-token',
)


def _response(status_code, json_data=None, headers=None):
    resp = mock.Mock()
    resp.status_code = status_code
    resp.json.return_value = json_data or {}
    resp.headers = headers or {}
    return resp


class AppVersionViewTests(SimpleTestCase):
    def setUp(self):
        self.factory = RequestFactory()

    def _get(self):
        return AppVersionView.as_view()(self.factory.get('/api/app-version/'))

    @override_settings(**RELEASE_SETTINGS)
    def test_reports_builds_and_backend_download_link(self):
        response = self._get()
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['latest_build'], 42)
        self.assertEqual(response.data['min_build'], 40)
        self.assertTrue(response.data['download_url'].endswith('/api/app-version/download/'))

    @override_settings(APP_LATEST_BUILD='0', APP_MIN_BUILD='0', APP_DOWNLOAD_URL='')
    def test_nothing_configured_means_no_update(self):
        response = self._get()
        self.assertEqual(response.data, {'latest_build': 0, 'min_build': 0, 'download_url': ''})

    @override_settings(APP_LATEST_BUILD='10', APP_MIN_BUILD='99', APP_DOWNLOAD_URL='')
    def test_minimum_never_exceeds_latest(self):
        self.assertEqual(self._get().data['min_build'], 10)

    @override_settings(APP_LATEST_BUILD='abc', APP_MIN_BUILD=' 5 ', APP_DOWNLOAD_URL='')
    def test_bad_values_are_treated_as_zero(self):
        response = self._get()
        self.assertEqual(response.data['latest_build'], 0)
        self.assertEqual(response.data['min_build'], 5)

    @override_settings(**{**RELEASE_SETTINGS, 'APP_DOWNLOAD_URL': 'https://play.google.com/store/apps/details?id=x'})
    def test_download_url_override(self):
        self.assertEqual(
            self._get().data['download_url'],
            'https://play.google.com/store/apps/details?id=x',
        )

    @override_settings(**RELEASE_SETTINGS)
    def test_token_is_never_returned(self):
        self.assertNotIn('test-token', str(self._get().data))


class AppDownloadViewTests(SimpleTestCase):
    def setUp(self):
        self.factory = RequestFactory()

    def _get(self):
        return AppDownloadView.as_view()(self.factory.get('/api/app-version/download/'))

    @override_settings(**RELEASE_SETTINGS)
    @mock.patch('apps.core.app_version.requests.get')
    def test_redirects_to_signed_apk_url(self, mock_get):
        mock_get.side_effect = [
            _response(200, {'assets': [
                {'name': 'notes.txt', 'url': 'https://api.github.com/assets/1'},
                {'name': 'khakhi-diary-build-42.apk', 'url': 'https://api.github.com/assets/2'},
            ]}),
            _response(302, headers={'Location': 'https://objects.githubusercontent.com/signed'}),
        ]
        response = self._get()
        self.assertEqual(response.status_code, 302)
        self.assertEqual(response['Location'], 'https://objects.githubusercontent.com/signed')
        release_call, asset_call = mock_get.call_args_list
        self.assertIn('/repos/Tensei-Tech/PMS-App/releases/tags/build-42', release_call.args[0])
        self.assertEqual(asset_call.args[0], 'https://api.github.com/assets/2')
        self.assertEqual(asset_call.kwargs['headers']['Accept'], 'application/octet-stream')
        self.assertFalse(asset_call.kwargs['allow_redirects'])

    @override_settings(**{**RELEASE_SETTINGS, 'APP_RELEASE_GITHUB_TOKEN': ''})
    @mock.patch('apps.core.app_version.requests.get')
    def test_not_set_up_without_token(self, mock_get):
        self.assertEqual(self._get().status_code, 503)
        mock_get.assert_not_called()

    @override_settings(**RELEASE_SETTINGS)
    @mock.patch('apps.core.app_version.requests.get')
    def test_missing_release(self, mock_get):
        mock_get.return_value = _response(404)
        self.assertEqual(self._get().status_code, 502)

    @override_settings(**RELEASE_SETTINGS)
    @mock.patch('apps.core.app_version.requests.get')
    def test_release_without_apk(self, mock_get):
        mock_get.return_value = _response(200, {'assets': [{'name': 'a.zip', 'url': 'u'}]})
        self.assertEqual(self._get().status_code, 502)

    @override_settings(**RELEASE_SETTINGS)
    @mock.patch('apps.core.app_version.requests.get')
    def test_github_unreachable(self, mock_get):
        mock_get.side_effect = requests.ConnectionError('down')
        self.assertEqual(self._get().status_code, 502)

    @override_settings(**{**RELEASE_SETTINGS, 'APP_DOWNLOAD_URL': 'https://play.google.com/x'})
    @mock.patch('apps.core.app_version.requests.get')
    def test_override_skips_github(self, mock_get):
        response = self._get()
        self.assertEqual(response.status_code, 302)
        self.assertEqual(response['Location'], 'https://play.google.com/x')
        mock_get.assert_not_called()
