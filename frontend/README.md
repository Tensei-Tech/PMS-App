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

## Test builds and in-app updates

Every push to `dev` builds a signed APK and publishes it as a GitHub Release
tagged `build-<number>` (the GitHub Actions run number). The app asks the
backend which build is current and offers the update. Testers download through
the backend, so they never need access to this GitHub repository.

### One-time setup

1. **Release signing key** (every build must use the same key, or Android
   refuses to install it over the old app). On your own computer, run:

   ```bash
   keytool -genkey -v -keystore khakhidiary.jks -keyalg RSA -keysize 4096 -validity 10000 -alias khakhidiary
   ```

   Keep `khakhidiary.jks` and its passwords somewhere safe and **never commit
   them**. The Play Store needs this same key later.

2. **GitHub secrets** (repo → Settings → Secrets and variables → Actions):

   | Secret | Value |
   |---|---|
   | `ANDROID_KEYSTORE_BASE64` | the keystore as base64 (`base64 -w0 khakhidiary.jks`, or in PowerShell `[Convert]::ToBase64String([IO.File]::ReadAllBytes("khakhidiary.jks"))`) |
   | `ANDROID_KEYSTORE_PASSWORD` | keystore password |
   | `ANDROID_KEY_ALIAS` | `khakhidiary` |
   | `ANDROID_KEY_PASSWORD` | key password |

3. **Download token**: create a GitHub fine-grained personal access token with
   access to only this repository and **Contents: Read-only**.

4. **Render environment** (backend service → Environment):

   | Variable | Value |
   |---|---|
   | `APP_RELEASE_GITHUB_TOKEN` | the token from step 3 |
   | `APP_LATEST_BUILD` | newest build number (e.g. `57`); older builds see "Update available" |
   | `APP_MIN_BUILD` | oldest allowed build; older builds are blocked until they update. `0` = off |
   | `APP_DOWNLOAD_URL` | leave empty; after the Play Store launch, set it to the Play Store link |

The first build signed with the release key cannot update an app signed with
the old debug key: uninstall the old app once, then install the new one.

### After each merge into `dev`

1. Wait for the "Build & Release Android APK" workflow to finish. Its summary
   shows the build number.
2. On Render, set `APP_LATEST_BUILD` to that number. To force everyone onto it,
   also set `APP_MIN_BUILD` to the same number.
3. Testers see the update the next time they open the app (or within 30
   minutes of returning to it) and tap **Update** to download it.

Builds made on your own computer have no build number and never show update
prompts.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
