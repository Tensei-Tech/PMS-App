// lib/services/rti_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_config.dart';
import 'api_service.dart';

/// Service handling all API communications for the RTI Module.
class RtiService {
  static final RtiService _instance = RtiService._internal();
  factory RtiService() => _instance;
  RtiService._internal();

  final ApiService _api = ApiService();
  Map<String, dynamic>? _cachedConfig;

  /// Fetch dynamic configuration (labels, limits, target_category_code) from backend
  Future<Map<String, dynamic>> fetchConfig({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedConfig != null) {
      return _cachedConfig!;
    }
    try {
      final response = await _api.get(ApiConfig.rtiConfig);
      if (response.isSuccess && response.data is Map) {
        _cachedConfig = Map<String, dynamic>.from(response.data as Map);
        return _cachedConfig!;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RtiService] fetchConfig error: $e');
      }
    }
    return _cachedConfig ?? {};
  }

  /// Fetch aggregate counts (total, pending, disposal)
  Future<Map<String, dynamic>> fetchCounts() async {
    try {
      final response = await _api.get(ApiConfig.rtiCounts);
      if (response.isSuccess && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RtiService] fetchCounts error: $e');
      }
    }
    return {'total': 0, 'pending': 0, 'disposal': 0};
  }

  /// Fetch paginated RTI applications list
  Future<Map<String, dynamic>> fetchApplications({
    String status = 'all',
    int page = 1,
    String q = '',
  }) async {
    try {
      final params = <String, String>{
        'status': status,
        'page': page.toString(),
      };
      if (q.trim().isNotEmpty) {
        params['q'] = q.trim();
      }

      final response = await _api.get(
        ApiConfig.rti,
        queryParameters: params,
      );

      if (response.isSuccess && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RtiService] fetchApplications error: $e');
      }
    }
    return {'count': 0, 'page': page, 'page_size': 20, 'results': []};
  }

  /// Fetch full details for a single RTI application
  Future<Map<String, dynamic>?> fetchApplicationDetail(dynamic rtiId) async {
    try {
      final response = await _api.get(ApiConfig.rtiDetail(rtiId));
      if (response.isSuccess && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RtiService] fetchApplicationDetail error: $e');
      }
    }
    return null;
  }

  /// Create a new RTI application
  Future<ApiResponse> createApplication(Map<String, dynamic> data) async {
    try {
      return await _api.post(ApiConfig.rti, data: data);
    } catch (e) {
      return ApiResponse.error('Exception: $e');
    }
  }

  /// Update an existing RTI application
  Future<ApiResponse> updateApplication(
      dynamic rtiId, Map<String, dynamic> data) async {
    try {
      return await _api.patch(ApiConfig.rtiDetail(rtiId), data: data);
    } catch (e) {
      return ApiResponse.error('Exception: $e');
    }
  }

  /// Fetch PDF report bytes for an RTI application
  Future<Uint8List?> fetchPdfBytes(dynamic rtiId) async {
    try {
      final token = await _api.getAuthToken();
      final headers = <String, String>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final uri = Uri.parse(ApiConfig.rtiPdf(rtiId));
      final response =
          await ApiService.activeHttpClient.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RtiService] fetchPdfBytes error: $e');
      }
    }
    return null;
  }

  /// Clear session cache
  void clearCache() {
    _cachedConfig = null;
  }
}
