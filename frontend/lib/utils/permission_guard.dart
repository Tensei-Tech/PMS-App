import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// PermissionGuard: Dynamic UI Guard Component.
/// Conditionally renders [child] ONLY if logged-in user possesses [permissionCode] in DB.
/// If user lacks permission, renders [fallback] (defaults to SizedBox.shrink()).
class PermissionGuard extends StatelessWidget {
  final String permissionCode;
  final Widget child;
  final Widget fallback;

  const PermissionGuard({
    super.key,
    required this.permissionCode,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final hasPerm = auth.hasPermission(permissionCode);

    if (hasPerm) {
      return child;
    }
    return fallback;
  }
}
