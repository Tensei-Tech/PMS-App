import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../models/base_record.dart';
import '../../../services/case_service.dart';
import '../../../utils/case_visibility.dart';
import '../../../utils/ad_disposal_helper.dart';

class BaseModuleProvider extends ChangeNotifier {
  final String moduleKey;
  CaseService get _caseService => CaseService();
  Timer? _pollTimer;
  List<ModuleRecord> _records = [];
  final Set<String> _deletedIds = {};
  String _stationId = '';
  String _uid = '';
  CaseVisibilityMode _visibilityMode = CaseVisibilityMode.ownCasesOnly;

  BaseModuleProvider(this.moduleKey);

  void clearStationContext({bool clearRecords = false}) {
    _pollTimer?.cancel();
    _pollTimer = null;
    _stationId = '';
    _uid = '';
    if (clearRecords) {
      _records = [];
      _deletedIds.clear();
    }
    notifyListeners();
  }

  void setStationContext({
    required String stationId,
    required String uid,
    required CaseVisibilityMode visibilityMode,
  }) {
    if (uid.isEmpty) {
      clearStationContext();
      return;
    }

    final effectiveStation = stationId.isNotEmpty ? stationId : 'ALL';
    if (_stationId == effectiveStation &&
        _uid == uid &&
        _visibilityMode == visibilityMode &&
        _pollTimer != null) {
      return;
    }
    _stationId = effectiveStation;
    _uid = uid;
    _visibilityMode = visibilityMode;
    _pollTimer?.cancel();

    _fetchCases();
    // 30-second periodic background poll for live synchronization with Django backend
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchCases();
    });
  }

  Future<void> _fetchCases({bool forceRefresh = false}) async {
    if (_uid.isEmpty) return;
    try {
      final fetched = await _caseService.fetchCases(
        moduleKey: moduleKey,
        stationId: _stationId,
        forceRefresh: forceRefresh,
      );

      if (fetched.isNotEmpty) {
        // Merge backend records with existing local records by ID
        final Map<String, ModuleRecord> merged = {
          for (final r in _records)
            if (!_deletedIds.contains(r.id)) r.id: r,
        };
        for (final r in fetched) {
          if (!_deletedIds.contains(r.id)) {
            merged[r.id] = r;
          }
        }
        final mergedList = merged.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        _records = CaseVisibility.filterRecords(
          mergedList,
          uid: _uid,
          mode: _visibilityMode,
        );
        notifyListeners();
      } else if (forceRefresh && _records.isEmpty) {
        _records = [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[$moduleKey] CaseService fetch error: $e');
    }
  }

  Future<void> refresh() => _fetchCases(forceRefresh: true);

  void seedDemoRecords(List<ModuleRecord> demoRecords) {
    if (_records.isEmpty) {
      _records = List.from(demoRecords);
      notifyListeners();
    }
  }

  /// Back-compat shim for form screens that only inject station + uid.
  void setStationId(String stationId, {String createdBy = ''}) {
    setStationContext(
      stationId: stationId,
      uid: createdBy,
      visibilityMode: CaseVisibilityMode.stationWide,
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  List<ModuleRecord> get records => _records;
  int get totalCount => _records.length;
  int get openCount =>
      _records.where((r) => isRecordPending(r) && r.status == 'Open').length;
  int get activeCount => _records.where((r) => isRecordPending(r)).length;
  int get resolvedCount => _records.where((r) => r.status == 'Resolved').length;
  int get closedCount => _records.where(isRecordDisposal).length;

  String get stationId => _stationId;
  String get createdBy => _uid;

  ModuleRecord? getById(String id) {
    return _records.firstWhereOrNull((r) => r.id == id);
  }

  List<ModuleRecord> getFilteredRecords(String? subCategory) {
    if (subCategory == null ||
        subCategory.trim().isEmpty ||
        subCategory == 'All' ||
        subCategory.toLowerCase() == moduleKey.toLowerCase()) {
      return records;
    }
    return records.where((r) => r.subCategory == subCategory).toList();
  }

  int getFilteredTotalCount(String? subCategory) {
    if (subCategory == null ||
        subCategory.trim().isEmpty ||
        subCategory == 'All' ||
        subCategory.toLowerCase() == moduleKey.toLowerCase()) {
      return totalCount;
    }
    return records.where((r) => r.subCategory == subCategory).length;
  }

  int getFilteredOpenCount(String? subCategory) {
    if (subCategory == null ||
        subCategory.trim().isEmpty ||
        subCategory == 'All' ||
        subCategory.toLowerCase() == moduleKey.toLowerCase()) {
      return openCount;
    }
    return records
        .where((r) => r.subCategory == subCategory && r.status == 'Open')
        .length;
  }

  int getFilteredActiveCount(String? subCategory) {
    if (subCategory == null ||
        subCategory.trim().isEmpty ||
        subCategory == 'All' ||
        subCategory.toLowerCase() == moduleKey.toLowerCase()) {
      return activeCount;
    }
    return records
        .where((r) => r.subCategory == subCategory && r.status == 'Active')
        .length;
  }

  int getFilteredResolvedCount(String? subCategory) {
    if (subCategory == null ||
        subCategory.trim().isEmpty ||
        subCategory == 'All' ||
        subCategory.toLowerCase() == moduleKey.toLowerCase()) {
      return resolvedCount;
    }
    return records
        .where((r) => r.subCategory == subCategory && r.status == 'Resolved')
        .length;
  }

  int getFilteredClosedCount(String? subCategory) {
    if (subCategory == null ||
        subCategory.trim().isEmpty ||
        subCategory == 'All' ||
        subCategory.toLowerCase() == moduleKey.toLowerCase()) {
      return closedCount;
    }
    return records
        .where((r) => r.subCategory == subCategory && isRecordDisposal(r))
        .length;
  }

  Future<void> addRecord(ModuleRecord record) async {
    if (record.moduleKey != moduleKey) {
      throw ArgumentError(
        'Cannot add a ${record.moduleKey} record into $moduleKey module!',
      );
    }
    final autoStatus = isAdDisposalCase(record) &&
            (record.status == 'Open' || record.status == 'Pending')
        ? 'Disposal'
        : record.status;
    final enriched = record.copyWith(
      status: autoStatus,
      stationName: record.stationName.isEmpty ? _stationId : record.stationName,
      createdBy: record.createdBy.isEmpty ? _uid : record.createdBy,
      assignedOfficerUid: record.assignedOfficerUid ??
          (_uid.isNotEmpty ? _uid : record.assignedOfficerUid),
    );

    _deletedIds.remove(enriched.id);

    // Optimistic local add so UI updates instantly and stays permanently
    final existingIdx = _records.indexWhere((r) => r.id == enriched.id);
    if (existingIdx >= 0) {
      _records[existingIdx] = enriched;
    } else {
      _records.insert(0, enriched);
    }
    notifyListeners();

    try {
      await _caseService.saveCase(enriched, isCreate: true);
    } catch (e) {
      debugPrint('[$moduleKey] saveCase sync error: $e');
    }
    await _fetchCases(forceRefresh: true);
  }

  Future<void> updateRecord(ModuleRecord record) async {
    if (record.moduleKey != moduleKey) {
      throw ArgumentError(
        'Cannot update a ${record.moduleKey} record in $moduleKey module!',
      );
    }
    final autoStatus = isAdDisposalCase(record) &&
            (record.status == 'Open' || record.status == 'Pending')
        ? 'Disposal'
        : record.status;
    final enriched = record.copyWith(
      status: autoStatus,
      stationName: record.stationName.isEmpty ? _stationId : record.stationName,
      createdBy: record.createdBy.isEmpty ? _uid : record.createdBy,
      assignedOfficerUid: record.assignedOfficerUid ??
          (_uid.isNotEmpty ? _uid : record.assignedOfficerUid),
    );

    _deletedIds.remove(enriched.id);

    // Optimistically update local list so UI reflects status change immediately
    final idx = _records.indexWhere((r) => r.id == enriched.id);
    if (idx != -1) {
      _records[idx] = enriched;
    } else {
      _records.insert(0, enriched);
    }
    notifyListeners();

    try {
      await _caseService.saveCase(enriched, isCreate: false);
    } catch (e) {
      debugPrint('[$moduleKey] saveCase update error: $e');
    }
    await _fetchCases(forceRefresh: true);
  }

  Future<void> deleteRecord(String id) async {
    _deletedIds.add(id);
    _records.removeWhere((r) => r.id == id);
    notifyListeners();

    try {
      await _caseService.deleteCase(id);
    } catch (e) {
      debugPrint('[$moduleKey] deleteCase error: $e');
    }
    await _fetchCases(forceRefresh: true);
  }

  ModuleRecord createRecord({
    required String title,
    required String caseNumber,
    required String description,
    required String complainant,
    required String accused,
    required String location,
    required DateTime incidentDate,
    required String priority,
    required String assignedOfficer,
    String? subCategory,
    Map<String, dynamic>? extraFields,
    String? assignedOfficerUid,
  }) {
    return ModuleRecord(
      id: const Uuid().v4(),
      moduleKey: moduleKey,
      title: title,
      caseNumber: caseNumber,
      description: description,
      complainant: complainant,
      accused: accused,
      location: location,
      incidentDate: incidentDate,
      priority: priority,
      status: 'Open',
      assignedOfficer: assignedOfficer,
      subCategory: subCategory,
      extraFields: extraFields ?? {},
      stationName: _stationId,
      createdBy: _uid,
      assignedOfficerUid: assignedOfficerUid ?? (_uid.isNotEmpty ? _uid : null),
    );
  }
}
