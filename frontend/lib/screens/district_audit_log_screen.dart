// lib/screens/district_audit_log_screen.dart
// District Admin Audit Logs Screen (District-scoped security event stream).

import 'package:flutter/material.dart';
import 'state_audit_log_screen.dart';

class DistrictAuditLogScreen extends StatelessWidget {
  const DistrictAuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Reuses StateAuditLogScreen — backend automatically enforces District Scope ABAC filtering with zero data leak.
    return const StateAuditLogScreen();
  }
}
