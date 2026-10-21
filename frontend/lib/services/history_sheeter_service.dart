import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_config.dart';
import 'api_service.dart';

/// Service handling all API communications for the History Sheeter Module.
class HistorySheeterService {
  static final HistorySheeterService _instance = HistorySheeterService._internal();
  factory HistorySheeterService() => _instance;
  HistorySheeterService._internal();

  final ApiService _api = ApiService();
  Map<String, dynamic>? _cachedConfig;

  /// Clear cached configuration
  void clearConfigCache() {
    _cachedConfig = null;
  }

  /// Fetch dynamic configuration (labels, limits, target_category_code) from backend
  Future<Map<String, dynamic>> fetchConfig({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedConfig != null) {
      return _cachedConfig!;
    }
    try {
      final response = await _api.get(ApiConfig.historySheeterConfig);
      if (response.isSuccess && response.data is Map) {
        _cachedConfig = Map<String, dynamic>.from(response.data as Map);
        return _cachedConfig!;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HistorySheeterService] fetchConfig error: $e');
      }
    }
    return _cachedConfig ?? {};
  }

  /// Fetch aggregate counts (active, open, closed)
  Future<Map<String, dynamic>> fetchCounts() async {
    try {
      final response = await _api.get(ApiConfig.historySheeterCounts);
      if (response.isSuccess && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HistorySheeterService] fetchCounts error: $e');
      }
    }
    return {'active': 0, 'open': 0, 'closed': 0};
  }

  /// Fetch paginated History Sheeters list
  Future<Map<String, dynamic>> fetchHistorySheeters({
    String tab = 'active',
    int page = 1,
    String q = '',
  }) async {
    try {
      final params = <String, String>{
        'tab': tab,
        'page': page.toString(),
      };
      if (q.trim().isNotEmpty) {
        params['q'] = q.trim();
      }

      final response = await _api.get(
        ApiConfig.historySheeter,
        queryParameters: params,
      );

      if (response.isSuccess && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HistorySheeterService] fetchHistorySheeters error: $e');
      }
    }
    return {'count': 0, 'page': page, 'page_size': 20, 'results': []};
  }

  /// Chart tab: every history sheet of the station (open and closed), one row
  /// each, with associate / rival / preventive counts.
  Future<Map<String, dynamic>> fetchChart({int page = 1, String q = ''}) async {
    try {
      final params = <String, String>{'page': page.toString()};
      if (q.trim().isNotEmpty) params['q'] = q.trim();
      final response = await _api.get(
        ApiConfig.historySheeterChart,
        queryParameters: params,
      );
      if (response.isSuccess && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HistorySheeterService] fetchChart error: $e');
      }
    }
    return {'count': 0, 'page': page, 'page_size': 20, 'results': []};
  }

  /// Fetch full details for a single History Sheeter
  Future<Map<String, dynamic>?> fetchHistorySheeterDetail(dynamic id) async {
    try {
      final response = await _api.get(ApiConfig.historySheeterDetail(id));
      if (response.isSuccess && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HistorySheeterService] fetchHistorySheeterDetail error: $e');
      }
    }
    return null;
  }

  /// Create a new History Sheeter
  Future<ApiResponse> createHistorySheeter(Map<String, dynamic> data) async {
    try {
      return await _api.post(ApiConfig.historySheeter, data: data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HistorySheeterService] createHistorySheeter error: $e');
      }
      return ApiResponse.error(e.toString());
    }
  }

  /// Update an existing History Sheeter (PATCH)
  Future<ApiResponse> updateHistorySheeter(dynamic id, Map<String, dynamic> data) async {
    try {
      return await _api.patch(ApiConfig.historySheeterDetail(id), data: data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HistorySheeterService] updateHistorySheeter error: $e');
      }
      return ApiResponse.error(e.toString());
    }
  }

  /// Download or stream PDF report bytes
  Future<Uint8List?> fetchPdfBytes(dynamic id) async {
    try {
      final token = await _api.getAuthToken();
      final headers = <String, String>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final uri = Uri.parse(ApiConfig.historySheeterPdf(id));
      final response =
          await ApiService.activeHttpClient.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[HistorySheeterService] fetchPdfBytes error: $e');
      }
    }
    return null;
  }

  /// Clear session cache
  void clearCache() {
    _cachedConfig = null;
  }
}
