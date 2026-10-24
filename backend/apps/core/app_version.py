"""
In-app update check for the Android APK.

GET /api/app-version/           -> {latest_build, min_build, download_url}
GET /api/app-version/download/  -> redirect to the APK of build APP_LATEST_BUILD

The APK lives in a GitHub Release (tag build-<number>) of a private repo. The
download view fetches it with a read-only token kept on the server and
redirects to GitHub's short-lived signed file URL, so testers never need
access to the repository.
"""
import logging

import requests
from django.conf import settings
from django.http import HttpResponseRedirect
from django.urls import reverse
from rest_framework import permissions, status, views
from rest_framework.response import Response

logger = logging.getLogger(__name__)

GITHUB_API = 'https://api.github.com'
GITHUB_TIMEOUT_SECONDS = 15
REDIRECT_STATUSES = {301, 302, 303, 307, 308}


def _build_setting(name):
    """Read a build-number setting; a missing or bad value counts as 0 (off)."""
    raw = str(getattr(settings, name, '') or '0').strip()
    try:
        return max(int(raw), 0)
    except ValueError:
        logger.warning("[AppVersion] %s=%r is not a whole number; treating it as 0", name, raw)
        return 0


def _builds():
    latest = _build_setting('APP_LATEST_BUILD')
    minimum = _build_setting('APP_MIN_BUILD')
    # A minimum above the latest build would lock everyone out with nothing to install.
    if latest and minimum > latest:
        minimum = latest
    return latest, minimum


class AppVersionView(views.APIView):
    """Public: the app calls this before login."""
    authentication_classes = []
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        latest, minimum = _builds()
        download_url = getattr(settings, 'APP_DOWNLOAD_URL', '') or ''
        if not download_url and latest:
            download_url = request.build_absolute_uri(reverse('app-version-download'))
        return Response({
            'latest_build': latest,
            'min_build': minimum,
            'download_url': download_url,
        })


class AppDownloadView(views.APIView):
    """Public: opened in the phone's browser, which then downloads the APK."""
    authentication_classes = []
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        override = getattr(settings, 'APP_DOWNLOAD_URL', '') or ''
        if override:
            return HttpResponseRedirect(override)

        latest, _ = _builds()
        token = getattr(settings, 'APP_RELEASE_GITHUB_TOKEN', '') or ''
        repo = getattr(settings, 'APP_RELEASE_REPO', '') or ''
        if not (latest and token and repo):
            return Response(
                {'error': 'App download is not set up yet.'},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        headers = {
            'Authorization': f'Bearer {token}',
            'Accept': 'application/vnd.github+json',
            'X-GitHub-Api-Version': '2022-11-28',
        }
        tag = f'build-{latest}'
        try:
            release = requests.get(
                f'{GITHUB_API}/repos/{repo}/releases/tags/{tag}',
                headers=headers,
                timeout=GITHUB_TIMEOUT_SECONDS,
            )
            if release.status_code != 200:
                logger.error("[AppDownload] GitHub returned %s for release %s", release.status_code, tag)
                return self._unavailable(f'Release {tag} was not found.')

            asset = next(
                (a for a in release.json().get('assets', []) if str(a.get('name', '')).endswith('.apk')),
                None,
            )
            if not asset:
                logger.error("[AppDownload] Release %s has no .apk file", tag)
                return self._unavailable(f'Release {tag} has no APK file.')

            # Asking for the raw file makes GitHub answer with a redirect to a
            # signed URL that works without the token for a few minutes.
            file_response = requests.get(
                asset['url'],
                headers={**headers, 'Accept': 'application/octet-stream'},
                timeout=GITHUB_TIMEOUT_SECONDS,
                allow_redirects=False,
            )
        except (requests.RequestException, ValueError, KeyError) as exc:
            logger.error("[AppDownload] Could not fetch %s from GitHub: %s", tag, type(exc).__name__)
            return self._unavailable('Could not reach the download server.')

        location = file_response.headers.get('Location')
        if file_response.status_code in REDIRECT_STATUSES and location:
            return HttpResponseRedirect(location)

        logger.error("[AppDownload] GitHub returned %s for the APK of %s", file_response.status_code, tag)
        return self._unavailable('Could not get the APK file.')

    @staticmethod
    def _unavailable(message):
        return Response({'error': message}, status=status.HTTP_502_BAD_GATEWAY)
