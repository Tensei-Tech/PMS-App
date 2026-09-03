import 'package:flutter/foundation.dart';
import 'api_config.dart';
import 'api_service.dart';

/// Data class representing user's dynamic DB permission configuration
class DynamicPermissionsModel {
  final String roleId;
  final String stateCode;
  final bool isMaster;
  final List<String> permissions;

  DynamicPermissionsModel({
    required this.roleId,
    required this.stateCode,
    required this.isMaster,
    required this.permissions,
  });

  factory DynamicPermissionsModel.fromMap(Map<String, dynamic> map) {
    final list = map['permissions'];
    List<String> perms = [];
    if (list is List) {
      perms = list.map((e) => e.toString()).toList();
    }
    return DynamicPermissionsModel(
      roleId: map['role_id']?.toString() ?? 'officer',
      stateCode: map['state_code']?.toString() ?? 'MH',
      isMaster: map['is_master'] == true,
      permissions: perms,
    );
  }

  bool hasPermission(String permissionCode) {
    if (isMaster || roleId == 'master_admin') return true;
    return permissions.contains(permissionCode);
  }
}

/// Service class for fetching dynamic RBAC permissions from Django REST Backend
class PermissionService {
  final ApiService _api = ApiService();

  /// Fetch live dynamic permissions for the current user from PostgreSQL `public.role_permissions`
  Future<DynamicPermissionsModel?> fetchUserPermissions() async {
    final token = await _api.getAuthToken();
    if (token == null || token.isEmpty || _api.isTokenExpired(token)) {
      return null;
    }

    try {
      final response = await _api.get(ApiConfig.authPermissions);
      if (response.isSuccess && response.data is Map<String, dynamic>) {
        return DynamicPermissionsModel.fromMap(response.data);
      } else {
        if (kDebugMode) {
          debugPrint(
              '[PermissionService] Error fetching permissions: ${response.errorMessage}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PermissionService] Exception fetching permissions: $e');
      }
    }
    return null;
  }
}
