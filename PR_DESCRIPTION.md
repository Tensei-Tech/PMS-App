# Pull Request: Resolve Security, Secrets Management, and Test Coverage Review Items

## Overview
This PR resolves all 6 feedback items from the code review, specifically addressing PBKDF2 iteration restoration and backward-compatible user migration, secrets externalization for the feedback webhook, comprehensive test coverage for PDF mapping and PIN crypto, and documentation for the Flutter SDK bump.

---

## Key Changes

### 1. Authentication & PIN Security (PBKDF2 Iteration Restoration)
- **Problem:** `PinCrypto._iterations` was previously reduced to 1,000, which falls below security recommendations for short numeric PINs.
- **Fix:**
  - Restored `PinCrypto._iterations` to **100,000** iterations, aligning with NIST SP 800-132 and OWASP standards for PBKDF2-HMAC-SHA256 to resist offline GPU brute-force attacks.
  - Added seamless backward compatibility in `AuthProvider.verifyPin` and `AuthProvider.changePin`:
    1. Validation is attempted with **100,000** iterations first.
    2. If validation fails, it falls back to **1,000** iterations to accommodate users who registered or updated their PIN during the regression window.
    3. When a legacy 1,000-iteration PIN succeeds, `AuthProvider` immediately re-hashes the PIN using a fresh salt and 100,000 iterations, updating secure storage transparently.

### 2. Secrets Management (Google Apps Script Webhook)
- **Problem:** The Google Apps Script deployment URL was hardcoded in `app_constants.dart`.
- **Fix:**
  - Updated `ApiConstants.feedbackWebAppUrl` to use Dart's compile-time environment variable:
    ```dart
    static const String feedbackWebAppUrl = String.fromEnvironment(
      'FEEDBACK_WEB_APP_URL',
      defaultValue: '',
    );
    ```
  - Added a defensive check in `FeedbackService`: if the URL is not provided, the webhook mirror is skipped cleanly without throwing exceptions, while primary feedback logging to Firestore proceeds unhindered.
  - Added `secrets.example.json` to version control as a setup template.
  - Added `secrets.json` and `*.secrets.json` to `.gitignore`.
  - Added `.vscode/launch.json` configured with `--dart-define-from-file=secrets.json` for IDE launch convenience.

### 3. Flutter SDK Version Bump Justification
- **Reasoning for Flutter 3.47.2 / Modern Stable Channel:**
  - **`web: ^1.0.0` Support:** Modern Flutter web applications transition away from the deprecated `dart:html` package to the standard `package:web` and Dart Wasm interop, which requires modern Dart 3+ / Flutter stable releases.
  - **Firebase & Android Tooling Alignment:** Updated plugins (`firebase_core ^4.7.0`, `cloud_firestore ^6.3.0`, `flutter_local_notifications ^21.0.0`) require modern Android Gradle Plugin (AGP 8.x) and Gradle 8+ tooling supported in modern Flutter builds.
  - **Security & CI Consistency:** Aligns local development environments with GitHub Actions CI runner (`subosito/flutter-action@v2` targeting `3.47.2`).

### 4. Automated Tests
- **`test/utils/crime_detail_pdf_test.dart`**:
  - Validates `mapToCrimeDetailDoc` across standard KYC payloads (complainant, victim, spot address concatenation, IO details).
  - Validates fallback priority chains for FIR identifiers (`crNo` -> `firNo` -> `caseNumber` -> `adNo` -> `ncNo`) and incident dates.
  - Validates resilience against empty maps, missing keys, invalid types, and stress testing with 10,000+ character and Marathi Unicode inputs.
- **`test/utils/pin_crypto_test.dart`**:
  - Validates salt generation entropy and length (64 hex characters).
  - Validates deterministic hashing and uniqueness across different salts.
  - Validates constant-time string comparison.
  - Validates the migration path from legacy 1,000 iterations to 100,000 iterations.

---

## How to Test & Verify

### Local Run with Secrets
1. Copy `frontend/secrets.example.json` to `frontend/secrets.json`:
   ```bash
   cp frontend/secrets.example.json frontend/secrets.json
   ```
2. Run via VS Code (<kbd>F5</kbd>) or via CLI:
   ```bash
   flutter run --dart-define-from-file=secrets.json
   ```

### Run Automated Tests
```bash
cd frontend
flutter test test/utils/crime_detail_pdf_test.dart
flutter test test/utils/pin_crypto_test.dart
```

### Static Analysis
```bash
cd frontend
flutter analyze
```
