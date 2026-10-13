// lib/modules/preventive/providers/preventive_provider.dart
import 'package:flutter/foundation.dart';
import '../../core/providers/base_module_provider.dart';
import '../../../services/case_service.dart';

class PreventiveProvider extends BaseModuleProvider {
  CaseService get _caseService => CaseService();

  Map<String, dynamic>? _config;
  Map<String, dynamic>? get config => _config;

  Map<String, dynamic>? _stats;
  Map<String, dynamic>? get stats => _stats;

  bool _isLoadingConfig = false;
  bool get isLoadingConfig => _isLoadingConfig;

  PreventiveProvider() : super('preventive');

  List<String> get crimeCategories {
    if (_config != null && _config!['crime_categories'] is List) {
      return (_config!['crime_categories'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  List<String> get preventiveActs {
    if (_config != null) {
      final acts = _config!['preventive_acts'] ?? _config!['preventive_items'];
      if (acts is List) {
        return acts
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    return [];
  }

  List<String> get caseStatuses {
    if (_config != null && _config!['case_statuses'] is List) {
      return (_config!['case_statuses'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  List<String> get riskFlags {
    if (_config != null && _config!['risk_flags'] is List) {
      return (_config!['risk_flags'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  List<String> get actionStatuses {
    if (_config != null && _config!['action_statuses'] is List) {
      return (_config!['action_statuses'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  int get backendTotalCount => _stats?['total_cases'] is int ? _stats!['total_cases'] as int : records.length;
  int get backendPendingCount => _stats?['pending_cases'] is int ? _stats!['pending_cases'] as int : 0;
  int get backendDisposalCount => _stats?['disposal_cases'] is int ? _stats!['disposal_cases'] as int : 0;

  Future<void> loadConfig({bool force = false}) async {
    if (_config != null && !force) return;
    _isLoadingConfig = true;
    notifyListeners();
    try {
      final res = await _caseService.fetchPreventiveConfig();
      if (res != null) {
        _config = res;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PreventiveProvider] loadConfig error: $e');
      }
    } finally {
      _isLoadingConfig = false;
      notifyListeners();
    }
  }

  Future<void> loadStats({bool force = false}) async {
    try {
      final res = await _caseService.fetchPreventiveStats();
      if (res != null) {
        _stats = res;
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PreventiveProvider] loadStats error: $e');
      }
    }
  }

  @override
  Future<void> ensureInitialized({bool forceRefresh = false}) async {
    await super.ensureInitialized(forceRefresh: forceRefresh);
    if (_config == null || forceRefresh) {
      await loadConfig(force: forceRefresh);
      await loadStats(force: forceRefresh);
    }
  }
}

