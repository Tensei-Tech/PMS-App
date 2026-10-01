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
      if (stationName != null && stationName.isNotEmpty) {
        queryParams['station_name'] = stationName;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (moduleKey != null && moduleKey.isNotEmpty) {
        queryParams['module_key'] = moduleKey;
      }
      if (assignedOfficerUid != null && assignedOfficerUid.isNotEmpty) {
        queryParams['assigned_officer_uid'] = assignedOfficerUid;
      }

      final response = await _api.get(
        ApiConfig.cases,
        queryParameters: queryParams,
      );

      if (response.isSuccess) {
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        } else if (response.data is Map &&
            response.data.containsKey('results')) {
          // Paginated response handling
          return List<Map<String, dynamic>>.from(response.data['results']);
        }
      } else {
        if (kDebugMode) {
          debugPrint(
            '[BackendCaseService] fetchCases failed: ${response.errorMessage}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BackendCaseService] fetchCases exception: $e');
      }
    }
    return null;
  }

  /// Fetch cases specifically assigned to the currently authenticated officer
  Future<List<Map<String, dynamic>>?> fetchAssignedCases({
    bool activeOnly = true,
  }) async {
    try {
      final url = '${ApiConfig.cases}assigned-to-me/';
      final response = await _api.get(
        url,
        queryParameters: {'active_only': activeOnly.toString()},
      );

      if (response.isSuccess && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BackendCaseService] fetchAssignedCases exception: $e');
      }
    }
    return null;
  }

  /// Fetch pending cases, optionally filtering by time range and category
  Future<List<Map<String, dynamic>>?> fetchPendingCases({
    String? ioUid,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (ioUid != null && ioUid.isNotEmpty) {
        queryParams['io'] = ioUid;
      }
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['end_date'] = endDate;
      }

      final url = '${ApiConfig.cases}pending/';
      final response = await _api.get(url, queryParameters: queryParams);

      if (response.isSuccess) {
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        } else if (response.data is Map &&
            response.data.containsKey('results')) {
          return List<Map<String, dynamic>>.from(response.data['results']);
        }
      } else {
        if (kDebugMode) {
          debugPrint(
            '[BackendCaseService] fetchPendingCases error: ${response.errorMessage}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BackendCaseService] fetchPendingCases exception: $e');
      }
    }
    return null;
  }

  /// Fetch IO-wise pending cases
  Future<List<Map<String, dynamic>>?> fetchPendingIOWise({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['end_date'] = endDate;
      }

      final url = '${ApiConfig.cases}pending/io-wise/';
      final response = await _api.get(url, queryParameters: queryParams);

      if (response.isSuccess && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        if (kDebugMode) {
          debugPrint(
            '[BackendCaseService] fetchPendingIOWise error: ${response.errorMessage}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BackendCaseService] fetchPendingIOWise exception: $e');
      }
    }
    return null;
  }

  /// Fetch time-wise grouped pending counts
  Future<List<Map<String, dynamic>>?> fetchPendingTimeWise() async {
    try {
      final url = '${ApiConfig.cases}pending/time-wise/';
      final response = await _api.get(url);
      if (response.isSuccess && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        if (kDebugMode) {
          debugPrint(
            '[BackendCaseService] fetchPendingTimeWise error: ${response.errorMessage}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BackendCaseService] fetchPendingTimeWise exception: $e');
      }
    }
    return null;
  }

  /// Fetch case-wise disposal records (Paginated)
  Future<Map<String, dynamic>?> fetchDisposalCases({
    String? ioUid,
    String? startDate,
    String? endDate,
    int? page,
    int? pageSize,
    String? station,
    String? district,
    String? crimeType,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (ioUid != null && ioUid.isNotEmpty) {
        queryParams['io_uid'] = ioUid;
      }
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['end_date'] = endDate;
      }
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['page_size'] = pageSize;
      if (station != null && station.isNotEmpty) queryParams['station'] = station;
      if (district != null && district.isNotEmpty) queryParams['district'] = district;
      if (crimeType != null && crimeType.isNotEmpty) queryParams['crime_type'] = crimeType;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final url = '${ApiConfig.cases}disposal/case-wise/';
      final response = await _api.get(url, queryParameters: queryParams);

      if (response.isSuccess) {
        if (response.data is Map && response.data.containsKey('results')) {
          return Map<String, dynamic>.from(response.data);
        } else if (response.data is List) {
           return {'results': List<Map<String, dynamic>>.from(response.data), 'count': (response.data as List).length};
        }
      } else {
        if (kDebugMode) {
          debugPrint(
            '[BackendCaseService] fetchDisposalCases error: ${response.errorMessage}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BackendCaseService] fetchDisposalCases exception: $e');
      }
    }
    return null;
  }

  /// Fetch IO-wise disposal cases
  Future<List<Map<String, dynamic>>?> fetchDisposalIOWise({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['end_date'] = endDate;
      }

      final url = '${ApiConfig.cases}disposal/designation-wise/';
      final response = await _api.get(url, queryParameters: queryParams);

      if (response.isSuccess && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        if (kDebugMode) {
          debugPrint(
            '[BackendCaseService] fetchDisposalIOWise error: ${response.errorMessage}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BackendCaseService] fetchDisposalIOWise exception: $e');
      }
    }
    return null;
  }

  /// Fetch time-wise grouped disposal counts
  Future<List<Map<String, dynamic>>?> fetchDisposalTimeWise() async {
    try {
      final url = '${ApiConfig.cases}disposal/time-wise/';
      final response = await _api.get(url);
      if (response.isSuccess && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        if (kDebugMode) {
          debugPrint(
            '[BackendCaseService] fetchDisposalTimeWise error: ${response.errorMessage}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BackendCaseService] fetchDisposalTimeWise exception: $e');
      }
    }
    return null;
  }

  /// Fetch Crime-Type-wise grouped disposal counts
  Future<List<Map<String, dynamic>>?> fetchDisposalCrimeTypeWise() async {
    try {
      final url = '${ApiConfig.cases}disposal/crime-type-wise/';
      final response = await _api.get(url);
      if (response.isSuccess && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        if (kDebugMode) {
          debugPrint(
            '[BackendCaseService] fetchDisposalCrimeTypeWise error: ${response.errorMessage}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BackendCaseService] fetchDisposalCrimeTypeWise exception: $e');
      }
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
      if (kDebugMode) {
        debugPrint('[BackendCaseService] fetchCaseById exception: $e');
      }
    }
    return null;
  }

  /// Create a new case record on backend
  Future<Map<String, dynamic>?> createCase(
    Map<String, dynamic> caseData,
  ) async {
    try {
      final response = await _api.post(ApiConfig.cases, body: caseData);

      if (response.isSuccess && response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        if (kDebugMode) {
          debugPrint(
            '[BackendCaseService] createCase error: ${response.errorMessage}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BackendCaseService] createCase exception: $e');
      }
    }
    return null;
  }

  /// Update an existing case record on backend
  Future<Map<String, dynamic>?> updateCase(
    String id,
    Map<String, dynamic> caseData,
  ) async {
    try {
      final url = '${ApiConfig.cases}$id/';
      final response = await _api.patch(url, body: caseData);

      if (response.isSuccess && response.data is Map<String, dynamic>) {
        return response.data;
      } else {
        if (kDebugMode) {
          debugPrint(
            '[BackendCaseService] updateCase error: ${response.errorMessage}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[BackendCaseService] updateCase exception: $e');
      }
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
      if (kDebugMode) {
        debugPrint('[BackendCaseService] deleteCase exception: $e');
      }
      return false;
    }
  }
}
