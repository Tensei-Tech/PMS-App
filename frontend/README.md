# police_management_app

A new Flutter project ..

## Backend address (API_BASE_URL)

The app reads the backend address from `API_BASE_URL` at build time. The
values live in `config/` (they are not secret):

- `config/prod.json`: the deployed backend, for release APKs
- `config/dev.json`: a backend running on this computer

Build the release APK with:

```bash
flutter build apk --release --dart-define-from-file=config/prod.json
```

Without it the app falls back to `http://127.0.0.1:8000/api`. On a phone that
address is the phone itself, so login fails. A release build without
`API_BASE_URL` now says so on the login screen. The GitHub workflow
`build-apk.yml` checks `config/prod.json` before building.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
