import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_config.dart';
import 'api_service.dart';

/// Service handling all API communications for the MPDA Module.
class MpdaService {
  static final MpdaService _instance = MpdaService._internal();
  factory MpdaService() => _instance;
  MpdaService._internal();

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
      final response = await _api.get(ApiConfig.mpdaConfig);
      if (response.isSuccess && response.data is Map) {
        _cachedConfig = Map<String, dynamic>.from(response.data as Map);
        return _cachedConfig!;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MpdaService] fetchConfig error: $e');
      }
    }
    return _cachedConfig ?? {};
  }

  /// Fetch aggregate counts (total, approved, rejected, jail, released_next_month)
  Future<Map<String, dynamic>> fetchCounts() async {
    try {
      final response = await _api.get(ApiConfig.mpdaCounts);
      if (response.isSuccess && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MpdaService] fetchCounts error: $e');
      }
    }
    return {
      'total': 0,
      'approved': 0,
      'rejected': 0,
      'jail': 0,
      'released_next_month': 0,
    };
  }

  /// Fetch paginated MPDA proposals list
  Future<Map<String, dynamic>> fetchProposals({
    String tab = 'total',
    int page = 1,
    String q = '',
    int? days,
  }) async {
    try {
      final params = <String, String>{
        'tab': tab,
        'page': page.toString(),
      };
      // Released card day filter (today .. today + days)
      if (days != null) {
        params['days'] = days.toString();
      }
      if (q.trim().isNotEmpty) {
        params['q'] = q.trim();
      }

      final response = await _api.get(
        ApiConfig.mpda,
        queryParameters: params,
      );

      if (response.isSuccess && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MpdaService] fetchProposals error: $e');
      }
    }
    return {'count': 0, 'page': page, 'page_size': 20, 'results': []};
  }

  /// Summary: every proposal of the station, one row each (serial, accused,
  /// gang member count, outcome with its date, MPDA category).
  Future<Map<String, dynamic>> fetchSummary(
      {int page = 1, String q = ''}) async {
    try {
      final params = <String, String>{'page': page.toString()};
      if (q.trim().isNotEmpty) params['q'] = q.trim();
      final response =
          await _api.get(ApiConfig.mpdaSummary, queryParameters: params);
      if (response.isSuccess && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MpdaService] fetchSummary error: $e');
      }
    }
    return {'count': 0, 'page': page, 'page_size': 20, 'results': []};
  }

  /// Detention end reminders of the officer's own police station: proposals
  /// whose Detention End Date is within the reminder period (backend setting,
  /// one month). Title / message / labels come from the backend.
  Future<Map<String, dynamic>> fetchDetentionReminders() async {
    try {
      final response = await _api.get(ApiConfig.mpdaReminders);
      if (response.isSuccess && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MpdaService] fetchDetentionReminders error: $e');
      }
    }
    return {'count': 0, 'results': []};
  }

  /// Mark the officer's manual ("Send Reminder") reminders as read
  Future<void> markRemindersSeen() async {
    try {
      await _api.post(ApiConfig.mpdaRemindersSeen);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MpdaService] markRemindersSeen error: $e');
      }
    }
  }

  /// Summary action: send a detention reminder now to every station officer
  Future<ApiResponse> sendReminder(dynamic id) async {
    try {
      return await _api.post(ApiConfig.mpdaRemind(id));
    } catch (e) {
      return ApiResponse.error('Exception: $e');
    }
  }

  /// Fetch full details for a single MPDA proposal
  Future<Map<String, dynamic>?> fetchProposalDetail(dynamic id) async {
    try {
      final response = await _api.get(ApiConfig.mpdaDetail(id));
      if (response.isSuccess && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MpdaService] fetchProposalDetail error: $e');
      }
    }
    return null;
  }

  /// Fetch scoped active officers for IO picker
  Future<List<Map<String, dynamic>>> fetchOfficers() async {
    try {
      final response = await _api.get(ApiConfig.mpdaOfficers);
      if (response.isSuccess && response.data is List) {
        return (response.data as List)
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MpdaService] fetchOfficers error: $e');
      }
    }
    return [];
  }

  /// Create a new MPDA proposal
  Future<ApiResponse> createProposal(Map<String, dynamic> data) async {
    try {
      return await _api.post(ApiConfig.mpda, data: data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MpdaService] createProposal error: $e');
      }
      return ApiResponse.error(e.toString());
    }
  }

  /// Update an existing MPDA proposal (PATCH)
  Future<ApiResponse> updateProposal(
      dynamic id, Map<String, dynamic> data) async {
    try {
      return await _api.patch(ApiConfig.mpdaDetail(id), data: data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MpdaService] updateProposal error: $e');
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
      final uri = Uri.parse(ApiConfig.mpdaPdf(id));
      final response =
          await ApiService.activeHttpClient.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[MpdaService] fetchPdfBytes error: $e');
      }
    }
    return null;
  }

  /// Clear session cache
  void clearCache() {
    _cachedConfig = null;
  }
}
