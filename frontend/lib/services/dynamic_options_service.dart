// lib/services/dynamic_options_service.dart
// In-memory cached loader for dynamic database-driven option values and routes.

import 'package:flutter/foundation.dart';
import 'api_config.dart';
import 'api_service.dart';

class DynamicOptionsService {
  static final DynamicOptionsService _instance =
      DynamicOptionsService._internal();
  factory DynamicOptionsService() => _instance;
  DynamicOptionsService._internal();

  final ApiService _api = ApiService();

  // Session-scoped in-memory cache
  final Map<String, List<String>> _optionsCache = {};

  /// Computes a cache key. Never cache an officer list across stations.
  String buildCacheKey(String route, {String? stationId}) {
    final cleanRoute = route.trim().toLowerCase();
    final isOfficerOrStation = cleanRoute.contains('officer') ||
        cleanRoute.contains('station') ||
        cleanRoute.contains('user');
    if (isOfficerOrStation) {
      final s = (stationId ?? '').trim().toLowerCase();
      return '$cleanRoute:station=$s';
    }
    return cleanRoute;
  }

  /// Clears the in-memory session cache (called on logout)
  void clearCache() {
    _optionsCache.clear();
    _recordsCache.clear();
  }

  /// Synchronously checks if options are cached
  List<String>? getCachedOptions(String route, {String? stationId}) {
    final key = buildCacheKey(route, stationId: stationId);
    return _optionsCache[key];
  }

  /// Synchronously checks whether a cache key exists
  bool hasCached(String route, {String? stationId}) {
    final key = buildCacheKey(route, stationId: stationId);
    return _optionsCache.containsKey(key);
  }

  /// Full URL for a route such as `acts/` or `/api/options/gender/`.
  static String absoluteUrl(String route) {
    var url = route.trim();
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (!url.startsWith('/')) url = '/$url';
    if (!url.startsWith('/api/')) url = '/api$url';
    final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
    return '$base$url';
  }

  final Map<String, List<Map<String, dynamic>>> _recordsCache = {};

  /// The raw rows of a route (e.g. `acts/`, `act-sections/?act_id=3`), for
  /// controls that keep an id and show a label (dependent dropdowns).
  /// Cached per route for the session; errors are thrown, not cached.
  Future<List<Map<String, dynamic>>> fetchRecords(String route) async {
    final trimmed = route.trim();
    if (trimmed.isEmpty) return const [];
    final key = trimmed.toLowerCase();
    final cached = _recordsCache[key];
    if (cached != null) return cached;

    final response = await _api.get(absoluteUrl(trimmed));
    if (!response.isSuccess) {
      throw Exception('Could not load options (${response.statusCode})');
    }
    final data = response.data;
    final items = data is List
        ? data
        : data is Map
            ? ((data['results'] ?? data['options'] ?? data['values'])
                    as List?) ??
                const []
            : const [];
    final rows = items
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    _recordsCache[key] = rows;
    return rows;
  }

  /// Loads options from route, parses them, and caches them in memory.
  Future<List<String>> fetchOptions(
    String route, {
    String? stationId,
    bool forceRefresh = false,
  }) async {
    final trimmedRoute = route.trim();
    if (trimmedRoute.isEmpty) return [];

    final key = buildCacheKey(trimmedRoute, stationId: stationId);
    if (!forceRefresh && _optionsCache.containsKey(key)) {
      return _optionsCache[key]!;
    }

    try {
      final url = absoluteUrl(trimmedRoute);

      final queryParams = <String, dynamic>{};
      final cleanRoute = trimmedRoute.toLowerCase();
      if (stationId != null &&
          stationId.isNotEmpty &&
          (cleanRoute.contains('officer') || cleanRoute.contains('station'))) {
        queryParams['station_name'] = stationId;
        queryParams['station_id'] = stationId;
      }

      final response = await _api.get(
        url,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.isSuccess) {
        final data = response.data;
        List<dynamic> items = [];
        if (data is List) {
          items = data;
        } else if (data is Map) {
          items = (data['results'] as List?) ??
              (data['options'] as List?) ??
              (data['values'] as List?) ??
              [];
        }

        final parsed = items
            .map((item) {
              if (item is String) return item;
              if (item is Map) {
                return (item['display_name'] ??
                        item['label'] ??
                        item['option_value'] ??
                        item['name'] ??
                        item['title'] ??
                        item['value'] ??
                        item.toString())
                    .toString();
              }
              return item.toString();
            })
            .where((s) => s.trim().isNotEmpty)
            .toList();

        _optionsCache[key] = parsed;
        return parsed;
      } else {
        if (kDebugMode) {
          debugPrint(
              '[DynamicOptionsService] Failed response for $url: ${response.statusCode}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '[DynamicOptionsService] Error loading options from $route: $e');
      }
      rethrow;
    }
  }
}
