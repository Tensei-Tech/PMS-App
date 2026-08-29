// lib/screens/station_audit_log_screen.dart
// Station Admin Audit Logs Screen (Station-scoped security event stream for SHO / Station Head).

import 'package:flutter/material.dart';
import 'state_audit_log_screen.dart';

class StationAuditLogScreen extends StatelessWidget {
  const StationAuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Reuses StateAuditLogScreen — backend automatically enforces Station Scope ABAC filtering with zero data leak.
    return const StateAuditLogScreen();
  }
}
