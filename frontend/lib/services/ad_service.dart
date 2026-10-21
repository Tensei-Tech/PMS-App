import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_config.dart';
import 'api_service.dart';

/// API client for the A.D. hub (`/api/ad/`). Each sub-tab (Suicide / Other
/// ...) is asked for by its category code; labels, sub-tabs and messages come
/// from `/api/ad/config/`.
class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  final ApiService _api = ApiService();
  Map<String, dynamic>? _cachedConfig;

  void clearConfigCache() {
    _cachedConfig = null;
  }

  Future<Map<String, dynamic>> fetchConfig({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedConfig != null) return _cachedConfig!;
    try {
      final response = await _api.get(ApiConfig.adConfig);
      if (response.isSuccess && response.data is Map) {
        _cachedConfig = Map<String, dynamic>.from(response.data as Map);
        return _cachedConfig!;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AdService] fetchConfig error: $e');
    }
    return _cachedConfig ?? {};
  }

  /// {'total', 'pending', 'disposal'} of one sub-tab
  Future<Map<String, dynamic>> fetchCounts(String category) async {
    try {
      final response = await _api
          .get(ApiConfig.adCounts, queryParameters: {'category': category});
      if (response.isSuccess && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AdService] fetchCounts error: $e');
    }
    return {};
  }

  /// One keyset page: {'results': [...], 'next_cursor': String?, 'page_size': int}
  Future<Map<String, dynamic>> fetchPage({
    required String category,
    required String tab,
    String q = '',
    String? cursor,
  }) async {
    try {
      final params = <String, String>{'category': category, 'tab': tab};
      if (q.trim().isNotEmpty) params['q'] = q.trim();
      if (cursor != null && cursor.isNotEmpty) params['cursor'] = cursor;
      final response = await _api.get(ApiConfig.ad, queryParameters: params);
      if (response.isSuccess && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AdService] fetchPage error: $e');
    }
    return {'results': <dynamic>[], 'next_cursor': null};
  }

  /// {'id', 'is_disposal', 'status_label', 'sections': [...], 'form_data': {...}}
  Future<Map<String, dynamic>?> fetchDetail(dynamic id) async {
    try {
      final response = await _api.get(ApiConfig.adDetail(id));
      if (response.isSuccess && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[AdService] fetchDetail error: $e');
    }
    return null;
  }

  Future<ApiResponse> create(String category, Map<String, dynamic> data) async {
    try {
      final url = Uri.parse(ApiConfig.ad)
          .replace(queryParameters: {'category': category}).toString();
      return await _api.post(url, data: data);
    } catch (e) {
      if (kDebugMode) debugPrint('[AdService] create error: $e');
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse> update(dynamic id, Map<String, dynamic> data) async {
    try {
      return await _api.patch(ApiConfig.adDetail(id), data: data);
    } catch (e) {
      if (kDebugMode) debugPrint('[AdService] update error: $e');
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
          .get(Uri.parse(ApiConfig.adPdf(id)), headers: headers);
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (e) {
      if (kDebugMode) debugPrint('[AdService] fetchPdfBytes error: $e');
    }
    return null;
  }
}
