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
        queryParameters: {
          'module_key': moduleKey,
          'station_name': stationId,
        },
      );

      if (response.isSuccess) {
        final data = response.data;
        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map<String, dynamic> && data['results'] is List) {
          list = data['results'] as List;
        }

        final records = list
            .map((item) => ModuleRecord.fromMap(
                  Map<String, dynamic>.from(item as Map),
                  item['id']?.toString(),
                ))
            .toList();
        _casesCache[cacheKey] = records;
        _casesCacheTime[cacheKey] = DateTime.now();
        return records;
      } else {
        if (kDebugMode && response.statusCode != 401) {
          debugPrint('[$moduleKey] CaseService.fetchCases failed: ${response.errorMessage}');
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
        queryParameters: {
          'station_name': stationId.trim(),
        },
      );

      if (response.isSuccess) {
        final data = response.data;
        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map<String, dynamic> && data['results'] is List) {
          list = data['results'] as List;
        }

        return list
            .map((item) => ModuleRecord.fromMap(
                  Map<String, dynamic>.from(item as Map),
                  item['id']?.toString(),
                ))
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
  Future<List<ModuleRecord>> fetchAssignedCases({bool activeOnly = true}) async {
    final token = await _api.getAuthToken();
    if (token == null || token.isEmpty || _api.isTokenExpired(token)) {
      return [];
    }

    try {
      final response = await _api.get(
        '${ApiConfig.cases}assigned-to-me/',
        queryParameters: {
          'active_only': activeOnly.toString(),
        },
      );

      if (response.isSuccess) {
        final data = response.data;
        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map<String, dynamic> && data['results'] is List) {
          list = data['results'] as List;
        }

        return list
            .map((item) => ModuleRecord.fromMap(
                  Map<String, dynamic>.from(item as Map),
                  item['id']?.toString(),
                ))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CaseService] fetchAssignedCases exception: $e');
      }
    }
    return [];
  }

  /// Create a new case record in PostgreSQL backend
  Future<bool> saveCase(ModuleRecord record, {bool isCreate = true}) async {
    try {
      final payload = record.toDjangoMap();
      ApiResponse response;
      if (isCreate) {
        response = await _api.post(ApiConfig.cases, body: payload);
      } else {
        final url = '${ApiConfig.cases}${record.id}/';
        response = await _api.put(url, body: payload);
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
      final url = '${ApiConfig.cases}$id/';
      final response = await _api.delete(url);
      return response.isSuccess;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CaseService] deleteCase exception: $e');
      }
      return false;
    }
  }
}
