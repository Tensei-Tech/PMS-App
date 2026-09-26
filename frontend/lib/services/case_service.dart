// lib/services/case_service.dart
// PostgreSQL & Django REST powered Case Service replacing Cloud Firestore for module records.

import 'package:flutter/foundation.dart';
import '../modules/core/models/base_record.dart';
import 'api_config.dart';
import 'api_service.dart';

class CaseService {
  static final CaseService _instance = CaseService._internal();
  factory CaseService() => _instance;
  CaseService._internal();

  final ApiService _api = ApiService();
  final Map<String, List<ModuleRecord>> _casesCache = {};
  final Map<String, DateTime> _casesCacheTime = {};

  /// Fetch cases for a specific module and station from Django PostgreSQL backend
  Future<List<ModuleRecord>> fetchCases({
    required String moduleKey,
    required String stationId,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$moduleKey:$stationId';
    final cachedRecords = _casesCache[cacheKey];
    final cachedTime = _casesCacheTime[cacheKey];

    if (!forceRefresh && cachedRecords != null && cachedTime != null) {
      final cacheAge = DateTime.now().difference(cachedTime);
      if (cacheAge < const Duration(seconds: 10)) {
        return cachedRecords;
      }
    }

    final token = await _api.getAuthToken();
    if (token == null || token.isEmpty || _api.isTokenExpired(token)) {
      return _casesCache[cacheKey] ?? [];
    }

    try {
      final response = await _api.get(
        ApiConfig.cases,
        queryParameters: {'module_key': moduleKey, 'station_name': stationId},
      );

      if (response.isSuccess) {
        final data = response.data;
        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map<String, dynamic>) {
          list = (data['results'] as List?) ??
              (data['cases'] as List?) ??
              [];
        }

        final records = list
            .map(
              (item) => ModuleRecord.fromMap(
                Map<String, dynamic>.from(item as Map),
                item['id']?.toString(),
              ),
            )
            .toList();
        _casesCache[cacheKey] = records;
        _casesCacheTime[cacheKey] = DateTime.now();
        return records;
      } else {
        if (kDebugMode && response.statusCode != 401) {
          debugPrint(
            '[$moduleKey] CaseService.fetchCases failed: ${response.errorMessage}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[$moduleKey] CaseService.fetchCases exception: $e');
      }
    }
    return [];
  }

  /// Fetch all cases for an entire station from Django backend (for dashboard stats)
  Future<List<ModuleRecord>> fetchStationCases(String stationId) async {
    if (stationId.trim().isEmpty) return [];

    final token = await _api.getAuthToken();
    if (token == null || token.isEmpty || _api.isTokenExpired(token)) {
      return [];
    }

    try {
      final response = await _api.get(
        ApiConfig.cases,
        queryParameters: {'station_name': stationId.trim()},
      );

      if (response.isSuccess) {
        final data = response.data;
        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map<String, dynamic>) {
          list = (data['results'] as List?) ??
              (data['cases'] as List?) ??
              [];
        }

        return list
            .map(
              (item) => ModuleRecord.fromMap(
                Map<String, dynamic>.from(item as Map),
                item['id']?.toString(),
              ),
            )
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CaseService] fetchStationCases exception: $e');
      }
    }
    return [];
  }

  /// Fetch cases assigned to the current officer from Django backend
  Future<List<ModuleRecord>> fetchAssignedCases({
    bool activeOnly = true,
  }) async {
    final token = await _api.getAuthToken();
    if (token == null || token.isEmpty || _api.isTokenExpired(token)) {
      return [];
    }

    try {
      final response = await _api.get(
        '${ApiConfig.cases}assigned-to-me/',
        queryParameters: {'active_only': activeOnly.toString()},
      );

      if (response.isSuccess) {
        final data = response.data;
        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map<String, dynamic>) {
          list = (data['results'] as List?) ??
              (data['cases'] as List?) ??
              [];
        }

        return list
            .map(
              (item) => ModuleRecord.fromMap(
                Map<String, dynamic>.from(item as Map),
                item['id']?.toString(),
              ),
            )
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CaseService] fetchAssignedCases exception: $e');
      }
    }
    return [];
  }

  /// Invalidate cases cache
  void invalidateCache([String? moduleKey, String? stationId]) {
    if (moduleKey != null && stationId != null) {
      final key = '$moduleKey:$stationId';
      _casesCache.remove(key);
      _casesCacheTime.remove(key);
    } else {
      _casesCache.clear();
      _casesCacheTime.clear();
    }
  }

  /// Clear in-memory cases cache
  void clearCache() => invalidateCache();

  /// Create a new case record in PostgreSQL backend
  Future<bool> saveCase(ModuleRecord record, {bool isCreate = true}) async {
    try {
      invalidateCache(record.moduleKey, record.stationName);
      final payload = record.toDjangoMap();
      ApiResponse response;
      if (isCreate) {
        response = await _api.post(ApiConfig.cases, body: payload);
      } else {
        final url = '${ApiConfig.cases}${record.id}/';
        response = await _api.put(url, body: payload);
      }
      if (response.isSuccess) {
        invalidateCache();
      }
      return response.isSuccess;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CaseService] saveCase exception: $e');
      }
      return false;
    }
  }

  /// Delete a case record in PostgreSQL backend
  Future<bool> deleteCase(String id) async {
    try {
      invalidateCache();
      final url = '${ApiConfig.cases}$id/';
      final response = await _api.delete(url);
      if (response.isSuccess) {
        invalidateCache();
      }
      return response.isSuccess;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CaseService] deleteCase exception: $e');
      }
      return false;
    }
  }

  /// Fetch Case PDF report payload from Django backend: GET /api/cases/{id}/pdf/
  Future<Map<String, dynamic>?> fetchCasePdfData(String caseId) async {
    if (caseId.trim().isEmpty) return null;
    try {
      final url = '${ApiConfig.cases}$caseId/pdf/';
      final response = await _api.get(url);
      if (response.isSuccess && response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CaseService] fetchCasePdfData exception: $e');
      }
    }
    return null;
  }

  final Map<String, List<Map<String, dynamic>>> _childrenCache = {};

  /// Fetch child categories for a category ID or name: GET /api/categories/{id}/children/
  Future<List<Map<String, dynamic>>> fetchCategoryChildren(
    String categoryIdOrName, {
    String? stationName,
    bool forceRefresh = false,
  }) async {
    final key = '$categoryIdOrName:${stationName ?? ''}';
    if (!forceRefresh && _childrenCache.containsKey(key)) {
      return _childrenCache[key]!;
    }
    try {
      final url = '${ApiConfig.baseUrl}/categories/$categoryIdOrName/children/';
      final response = await _api.get(
        url,
        queryParameters: stationName != null && stationName.isNotEmpty
            ? {'station_name': stationName}
            : null,
      );
      if (response.isSuccess && response.data is List) {
        final list = (response.data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _childrenCache[key] = list;
        return list;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CaseService] fetchCategoryChildren exception: $e');
      }
    }
    return [];
  }

  /// Fetch unified dashboard tabs (Groups 1-5 & Part 6 + All Standalone Tabs):
  /// GET /api/categories/dashboard-tabs/?station_name=...
  Future<Map<String, dynamic>?> fetchDashboardTabs({
    String? stationName,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}/categories/dashboard-tabs/';
      final response = await _api.get(
        url,
        queryParameters: stationName != null && stationName.isNotEmpty
            ? {'station_name': stationName}
            : null,
      );
      if (response.isSuccess && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CaseService] fetchDashboardTabs exception: $e');
      }
    }
    return null;
  }

  /// Fetch standalone categories: GET /api/categories/standalone/?station_name=...
  Future<List<Map<String, dynamic>>> fetchStandaloneCategories({
    String? stationName,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}/categories/standalone/';
      final response = await _api.get(
        url,
        queryParameters: stationName != null && stationName.isNotEmpty
            ? {'station_name': stationName}
            : null,
      );
      if (response.isSuccess && response.data is List) {
        return (response.data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CaseService] fetchStandaloneCategories exception: $e');
      }
    }
    return [];
  }

  /// Fetch all category groups: GET /api/groups/
  Future<List<Map<String, dynamic>>> fetchGroups({
    String? stationName,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}/groups/';
      final response = await _api.get(
        url,
        queryParameters: stationName != null && stationName.isNotEmpty
            ? {'station_name': stationName}
            : null,
      );
      if (response.isSuccess && response.data is List) {
        return (response.data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CaseService] fetchGroups exception: $e');
      }
    }
    return [];
  }

  /// Fetch categories for a specific group (e.g. 1 for '1 to 5', 2 for 'Part 6'):
  /// GET /api/groups/{groupId}/categories/
  Future<List<Map<String, dynamic>>> fetchGroupCategories(
    int groupId, {
    String? stationName,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}/groups/$groupId/categories/';
      final response = await _api.get(
        url,
        queryParameters: stationName != null && stationName.isNotEmpty
            ? {'station_name': stationName}
            : null,
      );
      if (response.isSuccess && response.data is List) {
        return (response.data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CaseService] fetchGroupCategories exception: $e');
      }
    }
    return [];
  }

  /// Priority 3: Fetch all administrative divisions: GET /api/divisions/
  Future<List<Map<String, dynamic>>> fetchDivisions({String? stateId}) async {
    try {
      final url = '${ApiConfig.baseUrl}/divisions/';
      final response = await _api.get(
        url,
        queryParameters: stateId != null && stateId.isNotEmpty ? {'state_id': stateId} : null,
      );
      if (response.isSuccess && response.data is List) {
        return (response.data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CaseService] fetchDivisions exception: $e');
      }
    }
    return [];
  }

  /// Priority 3: Fetch districts, optionally filtered by division: GET /api/districts/?division_id=...
  Future<List<Map<String, dynamic>>> fetchDistricts({dynamic divisionId}) async {
    try {
      final url = '${ApiConfig.baseUrl}/districts/';
      final response = await _api.get(
        url,
        queryParameters: divisionId != null && divisionId.toString().isNotEmpty
            ? {'division_id': divisionId.toString()}
            : null,
      );
      if (response.isSuccess && response.data is List) {
        return (response.data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CaseService] fetchDistricts exception: $e');
      }
    }
    return [];
  }

  /// Priority 3: Fetch police stations, optionally filtered by district: GET /api/stations/?district_id=...
  Future<List<Map<String, dynamic>>> fetchStations({dynamic districtId}) async {
    try {
      final url = '${ApiConfig.baseUrl}/stations/';
      final response = await _api.get(
        url,
        queryParameters: districtId != null && districtId.toString().isNotEmpty
            ? {'district_id': districtId.toString()}
            : null,
      );
      if (response.isSuccess && response.data is List) {
        return (response.data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CaseService] fetchStations exception: $e');
      }
    }
    return [];
  }

  /// Fetch cases for a specific category: GET /api/categories/{id}/cases/
  Future<List<ModuleRecord>> fetchCategoryCases(
    String categoryIdOrName, {
    String? stationName,
    String? status,
    String? search,
  }) async {
    try {
      final url = '${ApiConfig.baseUrl}/categories/$categoryIdOrName/cases/';
      final params = <String, dynamic>{};
      if (stationName != null && stationName.isNotEmpty) {
        params['station_name'] = stationName;
      }
      if (status != null && status.isNotEmpty) {
        params['status'] = status;
      }
      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }

      final response = await _api.get(
        url,
        queryParameters: params.isNotEmpty ? params : null,
      );

      if (response.isSuccess && response.data is Map) {
        final data = response.data as Map;
        final rawCases = data['cases'];
        if (rawCases is List) {
          return rawCases
              .map(
                (item) => ModuleRecord.fromMap(
                  Map<String, dynamic>.from(item as Map),
                  item['id']?.toString(),
                ),
              )
              .toList();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CaseService] fetchCategoryCases exception: $e');
      }
    }
    return [];
  }

  final Map<String, Map<String, dynamic>> _formDefCache = {};

  /// Fetch dynamic form definition for a category: GET /api/categories/{id}/form-definition/
  Future<Map<String, dynamic>?> fetchFormDefinition(
    dynamic categoryIdOrName, {
    String? caseId,
    List<dynamic>? sectionIds,
    List<dynamic>? sections,
    bool forceRefresh = false,
  }) async {
    final secList = sections ?? sectionIds;
    final cacheKey =
        '$categoryIdOrName:${caseId ?? ''}:${secList?.map((s) => s.toString()).join(',') ?? ''}';
    if (!forceRefresh && _formDefCache.containsKey(cacheKey)) {
      return _formDefCache[cacheKey];
    }
    try {
      final url =
          '${ApiConfig.baseUrl}/categories/$categoryIdOrName/form-definition/';
      final params = <String, dynamic>{};
      if (caseId != null && caseId.isNotEmpty) {
        params['case_id'] = caseId;
      }
      if (secList != null && secList.isNotEmpty) {
        final secJoined = secList.map((s) => s.toString().trim()).where((s) => s.isNotEmpty).join(',');
        if (secJoined.isNotEmpty) {
          params['sections'] = secJoined;
        }
      }

      final response = await _api.get(
        url,
        queryParameters: params.isNotEmpty ? params : null,
      );

      if (response.isSuccess && response.data is Map) {
        final def = Map<String, dynamic>.from(response.data as Map);
        _formDefCache[cacheKey] = def;
        return def;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CaseService] fetchFormDefinition exception: $e');
      }
    }
    return null;
  }
}


