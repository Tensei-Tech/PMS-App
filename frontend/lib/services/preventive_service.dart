import 'dart:async';
import 'package:flutter/foundation.dart';

import 'api_config.dart';
import 'api_service.dart';

/// Database-driven configuration service for the Preventive & Istegasha module.
/// Loads dynamic dropdown options (OptionValue), defaults, section titles, and
/// statutory messages from PostgreSQL via `/api/preventive/config/`.
class PreventiveService {
  static final PreventiveService _instance = PreventiveService._internal();
  factory PreventiveService() => _instance;
  PreventiveService._internal();

  final ApiService _api = ApiService();
  Map<String, dynamic>? _cachedConfig;

  void clearConfigCache() {
    _cachedConfig = null;
  }

  Future<Map<String, dynamic>> fetchConfig({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedConfig != null && _cachedConfig!.isNotEmpty) {
      return _cachedConfig!;
    }
    try {
      final response = await _api.get(ApiConfig.preventiveConfig);
      if (response.isSuccess && response.data is Map) {
        _cachedConfig = Map<String, dynamic>.from(response.data as Map);
        return _cachedConfig!;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PreventiveService] fetchConfig error: $e');
      }
    }
    return _cachedConfig ?? {};
  }

  @visibleForTesting
  void seedConfigForTesting(Map<String, dynamic> config) {
    _cachedConfig = Map<String, dynamic>.from(config);
  }

  List<String> get caseStatuses {
    final list = _cachedConfig?['case_statuses'];
    if (list is List && list.isNotEmpty) {
      return list.map((e) => e.toString()).toList();
    }
    return const [];
  }

  List<String> get riskFlags {
    final list = _cachedConfig?['risk_flags'];
    if (list is List && list.isNotEmpty) {
      return list.map((e) => e.toString()).toList();
    }
    return const [];
  }

  List<String> get actionStatuses {
    final list = _cachedConfig?['action_statuses'];
    if (list is List && list.isNotEmpty) {
      return list.map((e) => e.toString()).toList();
    }
    return const [];
  }

  List<String> get accusedActionTypes {
    final list = _cachedConfig?['accused_action_types'];
    if (list is List && list.isNotEmpty) {
      return list.map((e) => e.toString()).toList();
    }
    return const [];
  }

  List<String> get yesNoOptions {
    final list = _cachedConfig?['yes_no_options'];
    if (list is List && list.isNotEmpty) {
      return list.map((e) => e.toString()).toList();
    }
    return const [];
  }

  Map<String, dynamic> get defaults {
    final m = _cachedConfig?['defaults'];
    if (m is Map) {
      return Map<String, dynamic>.from(m);
    }
    return const {};
  }

  Map<String, String> get sectionTitles {
    final m = _cachedConfig?['section_titles'];
    if (m is Map) {
      return m.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return const {};
  }

  Map<String, String> get actionLabels {
    final m = _cachedConfig?['action_labels'];
    if (m is Map) {
      return m.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return const {};
  }

  Map<String, String> get messages {
    final m = _cachedConfig?['messages'];
    if (m is Map) {
      return m.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return const {};
  }

  String get sectionTitle =>
      _cachedConfig?['section_title']?.toString() ?? 'Preventive Action';
}
