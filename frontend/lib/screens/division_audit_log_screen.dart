// lib/screens/division_audit_log_screen.dart
// Division Admin Audit Logs Screen (Division-scoped security event stream).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'state_audit_log_screen.dart';

class DivisionAuditLogScreen extends StatelessWidget {
  const DivisionAuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Reuses the StateAuditLogScreen widget — the backend automatically enforces Division Scope ABAC filtering.
    return const StateAuditLogScreen();
  }
}
