import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_config.dart';
import 'api_service.dart';

/// API client for the independent N.C. (Non-Cognizable) module (`/api/nc/`).
/// Labels, limits and messages come from `/api/nc/config/`.
class NcService {
  static final NcService _instance = NcService._internal();
  factory NcService() => _instance;
  NcService._internal();

  final ApiService _api = ApiService();
  Map<String, dynamic>? _cachedConfig;

  void clearConfigCache() {
    _cachedConfig = null;
  }

  Future<Map<String, dynamic>> fetchConfig({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedConfig != null) return _cachedConfig!;
    try {
      final response = await _api.get(ApiConfig.ncConfig);
      if (response.isSuccess && response.data is Map) {
        _cachedConfig = Map<String, dynamic>.from(response.data as Map);
        return _cachedConfig!;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[NcService] fetchConfig error: $e');
    }
    return _cachedConfig ?? {};
  }

  /// {'total', 'pending', 'disposal'}
  Future<Map<String, dynamic>> fetchCounts() async {
    try {
      final response = await _api.get(ApiConfig.ncCounts);
      if (response.isSuccess && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[NcService] fetchCounts error: $e');
    }
    return {};
  }

  /// One keyset page: {'results': [...], 'next_cursor': String?, 'page_size': int}
  Future<Map<String, dynamic>> fetchPage({
    required String tab,
    String q = '',
    String? cursor,
  }) async {
    try {
      final params = <String, String>{'tab': tab};
      if (q.trim().isNotEmpty) params['q'] = q.trim();
      if (cursor != null && cursor.isNotEmpty) params['cursor'] = cursor;
      final response = await _api.get(ApiConfig.nc, queryParameters: params);
      if (response.isSuccess && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[NcService] fetchPage error: $e');
    }
    return {'results': <dynamic>[], 'next_cursor': null};
  }

  /// {'id', 'is_disposal', 'status_label', 'sections': [...], 'form_data': {...}}
  Future<Map<String, dynamic>?> fetchDetail(dynamic id) async {
    try {
      final response = await _api.get(ApiConfig.ncDetail(id));
      if (response.isSuccess && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[NcService] fetchDetail error: $e');
    }
    return null;
  }

  Future<ApiResponse> create(Map<String, dynamic> data) async {
    try {
      return await _api.post(ApiConfig.nc, data: data);
    } catch (e) {
      if (kDebugMode) debugPrint('[NcService] create error: $e');
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse> update(dynamic id, Map<String, dynamic> data) async {
    try {
      return await _api.patch(ApiConfig.ncDetail(id), data: data);
    } catch (e) {
      if (kDebugMode) debugPrint('[NcService] update error: $e');
      return ApiResponse.error(e.toString());
    }
  }

  Future<Uint8List?> fetchPdfBytes(dynamic id) async {
    try {
      final token = await _api.getAuthToken();
      final headers = <String, String>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await ApiService.activeHttpClient
          .get(Uri.parse(ApiConfig.ncPdf(id)), headers: headers);
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (e) {
      if (kDebugMode) debugPrint('[NcService] fetchPdfBytes error: $e');
    }
    return null;
  }
}
