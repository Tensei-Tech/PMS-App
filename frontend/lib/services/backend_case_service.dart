import 'package:flutter/foundation.dart';
import 'api_config.dart';
import 'api_service.dart';

/// Service for managing case records with the Django REST API backend.
class BackendCaseService {
  final ApiService _api = ApiService();

  /// Fetch list of cases with optional filtering
  Future<List<Map<String, dynamic>>?> fetchCases({
    String? stationName,
    String? status,
    String? moduleKey,
    String? assignedOfficerUid,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (stationName != null && stationName.isNotEmpty) queryParams['station_name'] = stationName;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (moduleKey != null && moduleKey.isNotEmpty) queryParams['module_key'] = moduleKey;
      if (assignedOfficerUid != null && assignedOfficerUid.isNotEmpty) {
        queryParams['assigned_officer_uid'] = assignedOfficerUid;
      }

      final response = await _api.get(ApiConfig.cases, queryParameters: queryParams);

      if (response.isSuccess) {
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        } else if (response.data is Map && response.data.containsKey('results')) {
          // Paginated response handling
          return List<Map<String, dynamic>>.from(response.data['results']);
        }
      } else {
        if (kDebugMode) debugPrint('[BackendCaseService] fetchCases failed: ${response.errorMessage}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[BackendCaseService] fetchCases exception: $e');
    }
    return null;
  }

  /// Fetch cases specifically assigned to the currently authenticated officer
  Future<List<Map<String, dynamic>>?> fetchAssignedCases({bool activeOnly = true}) async {
    try {
      final url = '${ApiConfig.cases}assigned-to-me/';
      final response = await _api.get(url, queryParameters: {'active_only': activeOnly.toString()});

      if (response.isSuccess && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[BackendCaseService] fetchAssignedCases exception: $e');
    }
    return null;
  }

  /// Fetch a single case record by ID
  Future<Map<String, dynamic>?> fetchCaseById(String id) async {
    try {
      final url = '${ApiConfig.cases}$id/';
      final response = await _api.get(url);

      if (response.isSuccess && response.data is Map<String, dynamic>) {
        return response.data;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[BackendCaseService] fetchCaseById exception: $e');
    }
    return null;
  }

  /// Create a new case record on backend
  Future<Map<String, dynamic>?> createCase(Map<String, dynamic> caseData) async {
    try {
      final response = await _api.post(ApiConfig.cases, body: caseData);

      if (response.isSuccess && response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        if (kDebugMode) debugPrint('[BackendCaseService] createCase error: ${response.errorMessage}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[BackendCaseService] createCase exception: $e');
    }
    return null;
  }

  /// Update an existing case record on backend
  Future<Map<String, dynamic>?> updateCase(String id, Map<String, dynamic> caseData) async {
    try {
      final url = '${ApiConfig.cases}$id/';
      final response = await _api.patch(url, body: caseData);

      if (response.isSuccess && response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        if (kDebugMode) debugPrint('[BackendCaseService] updateCase error: ${response.errorMessage}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[BackendCaseService] updateCase exception: $e');
    }
    return null;
  }

  /// Delete a case record on backend
  Future<bool> deleteCase(String id) async {
    try {
      final url = '${ApiConfig.cases}$id/';
      final response = await _api.delete(url);
      return response.isSuccess;
    } catch (e) {
      if (kDebugMode) debugPrint('[BackendCaseService] deleteCase exception: $e');
      return false;
    }
  }
}
