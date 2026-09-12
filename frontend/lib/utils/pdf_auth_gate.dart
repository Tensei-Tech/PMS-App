// lib/utils/pdf_auth_gate.dart
// PDF export PIN gate — coordinates with PoliceMgmtApp resume biometric (main.dart).

import 'package:flutter/material.dart';

/// While **true**, the app resume-handler must **not** stack another biometric overlay
/// (see [PoliceMgmtApp] in `main.dart`). **Idle value is false.**
bool isPdfDownloadAuthGateActive = false;

Future<void> runWithPdfAuthGate(
  BuildContext context,
  Future<void> Function() action,
) async {
  if (!context.mounted) return;
  await action();
}
