// lib/modules/muddemal/providers/muddemal_provider.dart
// State management provider for Digital Muddemal / Property Management Module.
// Maintains backward compatibility with BaseModuleProvider while providing full
// dynamic schema-driven capabilities, cross-module linking, alerts, and dashboards.

import 'package:flutter/foundation.dart';
import '../../core/providers/base_module_provider.dart';
import '../../../widgets/dynamic_form/dynamic_field_model.dart';
import '../models/muddemal_models.dart';
import '../services/muddemal_api_service.dart';

class MuddemalProvider extends BaseModuleProvider {
  final MuddemalApiService _muddemalApi = MuddemalApiService();

  MuddemalProvider() : super('muddemal');

  // Metadata State (zero hardcoded strings, all from backend)
  List<MuddemalCategory> _categories = [];
  List<MuddemalCategory> get categories => _categories;

  Map<String, dynamic> _configs = {};
  Map<String, dynamic> get configs => _configs;

  List<Map<String, dynamic>> get sourceModules {
    final raw = _configs['source_modules'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return [];
  }

  /// Dynamic database-driven UI labels (loaded from backend muddemal_configs table)
  Map<String, dynamic> get uiLabels {
    final raw = _configs['ui_labels'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {
      'property_category_label': 'Type of Property',
      'all_categories_label': 'All Types of Property',
      'property_status_label': 'Property Status',
      'all_statuses_label': 'All Statuses',
      'source_module_label': 'Source Module',
      'all_source_modules_label': 'All PMS Modules',
      'search_hint_label':
          'Search CR No., Accused, Description, Seized From...',
      'clear_filters_label': 'Clear Filters',
      'attributes_tab_label': 'Information',
      'attributes_section_label': 'Dynamic Information',
      'category_specific_info_label': 'Category-Specific Information',
      'select_property_category_label': 'Select Type of Property *',
      'fill_dynamic_info_label':
          'Select type of property and fill dynamic information',
    };
  }

  String get propertyCategoryLabel =>
      uiLabels['property_category_label']?.toString() ?? 'Type of Property';

  String get allCategoriesLabel =>
      uiLabels['all_categories_label']?.toString() ?? 'All Types of Property';

  String get propertyStatusLabel =>
      uiLabels['property_status_label']?.toString() ?? 'Property Status';

  String get allStatusesLabel =>
      uiLabels['all_statuses_label']?.toString() ?? 'All Statuses';

  String get sourceModuleLabel =>
      uiLabels['source_module_label']?.toString() ?? 'Source Module';

  String get allSourceModulesLabel =>
      uiLabels['all_source_modules_label']?.toString() ?? 'All PMS Modules';

  String get searchHintLabel =>
      uiLabels['search_hint_label']?.toString() ??
      'Search CR No., Accused, Description, Seized From...';

  String get clearFiltersLabel =>
      uiLabels['clear_filters_label']?.toString() ?? 'Clear Filters';

  String get attributesTabLabel =>
      uiLabels['attributes_tab_label']?.toString() ?? 'Information';

  String get attributesSectionLabel =>
      uiLabels['attributes_section_label']?.toString() ?? 'Dynamic Information';

  String get categorySpecificInfoLabel =>
      uiLabels['category_specific_info_label']?.toString() ??
      'Category-Specific Information';

  String get selectPropertyCategoryLabel =>
      uiLabels['select_property_category_label']?.toString() ??
      'Select Type of Property *';

  String get fillDynamicInfoLabel =>
      uiLabels['fill_dynamic_info_label']?.toString() ??
      'Select type of property and fill dynamic information';

  List<String> get measurementUnits {
    final raw = _configs['measurement_units'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return const [];
  }

  List<String> get propertyStatuses {
    final raw = _configs['property_statuses'];
    if (raw is List) {
      return raw
          .map((e) {
            if (e is Map) {
              return e['code']?.toString() ?? e['label']?.toString() ?? '';
            }
            return e.toString();
          })
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }

  List<Map<String, String>> get propertyStatusOptions {
    final raw = _configs['property_statuses'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => {
                'code': e['code']?.toString() ?? '',
                'label': e['label']?.toString() ?? '',
              })
          .where((m) => m['code']!.isNotEmpty)
          .toList();
    }
    return [];
  }

  List<String> get movementLocations {
    final raw = _configs['movement_locations'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return const [];
  }

  List<String> get movementTypes {
    final raw = _configs['movement_types'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return const [];
  }

  List<String> get disposalTypes {
    final raw = _configs['disposal_types'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return const [];
  }

  /// Dynamic available years from database records + current year
  List<int> get availableYears {
    final raw = _configs['available_years'];
    if (raw is List) {
      final list = raw
          .map((e) => int.tryParse(e.toString()))
          .whereType<int>()
          .toList();
      if (list.isNotEmpty) return list;
    }
    return [DateTime.now().year];
  }

  /// Dynamic database-driven dashboard tabs
  List<MuddemalDashboardTab> get dashboardTabs {
    final raw = _configs['dashboard_tabs'];
    if (raw is List) {
      final list = raw
          .whereType<Map>()
          .map((m) => MuddemalDashboardTab.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      if (list.isNotEmpty) {
        list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        return list;
      }
    }
    return const [
      MuddemalDashboardTab(key: 'All', label: 'Total Cases', badgeColor: '#2563EB', displayOrder: 1),
      MuddemalDashboardTab(key: 'Pending', label: 'Pending', badgeColor: '#EA580C', displayOrder: 2),
      MuddemalDashboardTab(key: 'Disposal', label: 'Disposal', badgeColor: '#059669', displayOrder: 3),
    ];
  }

  /// Dynamic disposal authorities from database
  List<MuddemalDisposalAuthority> get disposalAuthorities {
    final raw = _configs['disposal_authorities'];
    if (raw is List) {
      final list = raw
          .whereType<Map>()
          .map((m) => MuddemalDisposalAuthority.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      list.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
      return list;
    }
    return const [];
  }

  /// Dynamic FSL dispatch reasons from database
  List<String> get fslDispatchReasons {
    final raw = _configs['fsl_dispatch_reasons'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return const [];
  }

  /// Dynamic FSL report statuses from database
  List<MuddemalFslReportStatus> get fslReportStatuses {
    final raw = _configs['fsl_report_statuses'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((m) => MuddemalFslReportStatus.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return const [];
  }

  /// Dynamic status categories from database
  Map<String, dynamic> get statusCategories {
    final raw = _configs['status_categories'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  /// Check if a status string represents a disposal state
  bool isDisposalStatus(String status) {
    if (status.isEmpty) return false;
    final cat = statusCategories['disposal'];
    if (cat is List && cat.isNotEmpty) {
      final clean = status.trim().toLowerCase();
      return cat.any((c) => c.toString().trim().toLowerCase() == clean);
    }
    final s = status.toLowerCase();
    return s.contains('dispos') || s.contains('returned') || s.contains('released');
  }

  /// Check if a status string represents a pending state
  bool isPendingStatus(String status) {
    if (status.isEmpty) return false;
    final cat = statusCategories['pending'];
    if (cat is List && cat.isNotEmpty) {
      final clean = status.trim().toLowerCase();
      return cat.any((c) => c.toString().trim().toLowerCase() == clean);
    }
    return !isDisposalStatus(status);
  }

  /// Checks if a property matches a configured tab
  bool propertyMatchesTab(String tabKey, MuddemalPropertyItem property) {
    if (tabKey == 'All' || tabKey == 'all' || tabKey.isEmpty) return true;
    final tab = dashboardTabs.firstWhere(
      (t) => t.key.toLowerCase() == tabKey.toLowerCase(),
      orElse: () => MuddemalDashboardTab(key: tabKey, label: tabKey, badgeColor: '#2563EB', displayOrder: 0),
    );
    if (tab.applicableStatuses.isNotEmpty) {
      return tab.applicableStatuses.any(
        (s) => s.trim().toLowerCase() == property.propertyStatus.trim().toLowerCase(),
      );
    }
    if (tabKey.toLowerCase() == 'disposal') {
      return isDisposalStatus(property.propertyStatus) || isDisposalStatus(property.disposalStatus);
    }
    if (tabKey.toLowerCase() == 'pending') {
      return !isDisposalStatus(property.propertyStatus) && !isDisposalStatus(property.disposalStatus);
    }
    return true;
  }

  /// Fetch next unique FSL reference number from backend API
  Future<String?> getNextFslReference(int propertyId, {String? labCode}) async {
    return await _muddemalApi.fetchNextFslReference(propertyId, labCode: labCode);
  }

  // Active Register and Properties State
  List<MuddemalRegisterHeader> _registers = [];
  List<MuddemalRegisterHeader> get registers => _registers;

  MuddemalRegisterHeader? _activeRegister;
  MuddemalRegisterHeader? get activeRegister => _activeRegister;

  List<MuddemalPropertyItem> _properties = [];
  List<MuddemalPropertyItem> get properties => _properties;

  MuddemalPropertyItem? _selectedProperty;
  MuddemalPropertyItem? get selectedProperty => _selectedProperty;

  // Filter and search states
  String? _selectedCategoryFilter;
  String? get selectedCategoryFilter => _selectedCategoryFilter;

  String? _selectedStatusFilter;
  String? get selectedStatusFilter => _selectedStatusFilter;

  String? _selectedSourceModuleFilter;
  String? get selectedSourceModuleFilter => _selectedSourceModuleFilter;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // Live KPI totals derived from loaded backend data
  int get totalPropertiesCount => _properties.length;
  double get totalSeizedValuation =>
      _properties.fold(0.0, (sum, p) => sum + p.totalItemValue);
  int get fslPendingCount => _properties
      .where((p) => p.fslRequired && p.fslStatus != 'Received')
      .length;
  int get inMuddemalRoomCount => _properties
      .where((p) =>
          p.currentCustodyLocation.contains('Muddemal Room') ||
          p.currentCustodyLocation.contains('मालखाना'))
      .length;

  Map<String, dynamic>? _propertySummary;
  Map<String, dynamic> get propertySummary => _propertySummary ?? const {};

  Map<String, dynamic> get liveValuations {
    // If backend database returned valuation summary, prioritize database aggregates
    final summary = _propertySummary;
    if (summary != null &&
        summary.isNotEmpty &&
        (summary['total_registered_value'] != null ||
            summary['total_seized_property_value'] != null)) {
      return summary;
    }

    double totalVal = 0;
    double recoveredVal = 0;
    double stolenVal = 0;
    double seizedVal = 0;
    final props = _properties;
    for (final p in props) {
      totalVal += p.totalItemValue;
      final isStolen = p.categoryCode == 'STOLEN_PROPERTY' ||
          p.propertyStatus == 'Stolen – Not Recovered' ||
          p.propertyStatus == 'Recovered';
      if (isStolen) {
        stolenVal += p.totalItemValue;
        if (p.propertyStatus == 'Recovered') {
          recoveredVal += p.totalItemValue;
        }
      } else {
        seizedVal += p.totalItemValue;
      }
    }
    return {
      'total_registered_value': totalVal,
      'total_stolen_value': stolenVal,
      'recovered_property_value': recoveredVal,
      'total_seized_property_value': seizedVal,
    };
  }

  // Dynamic field definitions cached per category code
  final Map<String, List<DynamicFieldDef>> _categoryFieldCache = {};
  List<DynamicFieldDef> _currentCategoryFields = [];
  List<DynamicFieldDef> get currentCategoryFields => _currentCategoryFields;

  // Cross-module discovered properties
  List<DiscoveredSourceProperty> _discoveredProperties = [];
  List<DiscoveredSourceProperty> get discoveredProperties =>
      _discoveredProperties;

  // Dashboards & Alerts
  Map<String, dynamic> _fslAlerts = {};
  Map<String, dynamic> get fslAlerts => _fslAlerts;

  Map<String, dynamic> _stolenDashboard = {};
  Map<String, dynamic> get stolenDashboard => _stolenDashboard;

  Map<String, dynamic> _seizedDashboard = {};
  Map<String, dynamic> get seizedDashboard => _seizedDashboard;

  Map<String, dynamic> _pendingDashboard = {};
  Map<String, dynamic> get pendingDashboard => _pendingDashboard;

  Map<String, dynamic> _monthlyYearlyReport = {};
  Map<String, dynamic> get monthlyYearlyReport => _monthlyYearlyReport;

  // UI state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isFieldsLoading = false;
  bool get isFieldsLoading => _isFieldsLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String _filterStation = '';
  String get filterStation => _filterStation;

  int? _selectedYear;
  int? get selectedYear => _selectedYear;

  void setYear(int? yr) {
    _selectedYear = yr;
    loadProperties();
    loadDashboards();
    notifyListeners();
  }

  void setCategoryFilter(String? catCode) {
    _selectedCategoryFilter = catCode;
    loadProperties();
  }

  void setStatusFilter(String? status) {
    _selectedStatusFilter = status;
    loadProperties();
  }

  void setSourceModuleFilter(String? sourceModule) {
    _selectedSourceModuleFilter = sourceModule;
    loadProperties();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadProperties();
  }

  void clearFilters() {
    _selectedCategoryFilter = null;
    _selectedStatusFilter = null;
    _selectedSourceModuleFilter = null;
    _selectedYear = null;
    _searchQuery = '';
    loadProperties();
  }

  /// 1. Initialize metadata (categories, configs, centralized properties, registers)
  Future<void> loadInitialMetadata({String? stationName}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _muddemalApi.fetchConfigs(),
        _muddemalApi.fetchCategories(),
      ]);

      _configs = results[0] as Map<String, dynamic>;
      _categories = results[1] as List<MuddemalCategory>;

      if (stationName != null && stationName.isNotEmpty) {
        _filterStation = stationName;
      }

      await Future.wait([
        loadRegistersForStation(_filterStation),
        loadProperties(stationName: _filterStation),
      ]);
    } catch (e) {
      _errorMessage = 'Error loading Muddemal metadata: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 1a. Centralized auto-fetched properties for station/filters
  Future<void> loadProperties({
    String? stationName,
    bool forceSync = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final st = stationName ?? _filterStation;
      if (forceSync && st.isNotEmpty) {
        await _muddemalApi.syncSourceModules(stationName: st);
      }
      final results = await Future.wait([
        _muddemalApi.fetchProperties(
          stationName: st,
          categoryCode: _selectedCategoryFilter,
          propertyStatus: _selectedStatusFilter,
          sourceModule: _selectedSourceModuleFilter,
          year: _selectedYear,
          search: _searchQuery,
        ),
        _muddemalApi.fetchPropertySummary(
          stationName: st,
          categoryCode: _selectedCategoryFilter,
          sourceModule: _selectedSourceModuleFilter,
          propertyStatus: _selectedStatusFilter,
          year: _selectedYear,
        ),
      ]);
      _properties = results[0] as List<MuddemalPropertyItem>;
      _propertySummary = results[1] as Map<String, dynamic>;
      _refreshActiveRegisterValuations();
    } catch (e) {
      _errorMessage = 'Error loading Muddemal properties: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 1b. Explicitly trigger auto-sync across all source modules and refresh
  Future<void> syncAllSources() async {
    await loadProperties(forceSync: true);
    if (_filterStation.isNotEmpty) {
      await loadRegistersForStation(_filterStation);
    }
  }

  /// 2. Load Registers for station
  Future<void> loadRegistersForStation(String stationName) async {
    _filterStation = stationName;
    try {
      _registers = await _muddemalApi.fetchRegisters(
        stationName: stationName,
        year: _selectedYear,
      );
      if (_registers.isNotEmpty && _activeRegister == null) {
        _activeRegister = _registers.first;
      }
    } catch (e) {
      debugPrint('[MuddemalProvider] loadRegisters error: $e');
    }
    notifyListeners();
  }

  /// 3. Select a Register and optionally filter its properties
  void selectRegister(MuddemalRegisterHeader register,
      {bool filterProperties = false}) {
    _activeRegister = register;
    if (filterProperties) {
      _properties = register.properties;
    }
    if (_activeRegister?.crCaseId != null) {
      loadDiscoverableProperties(_activeRegister!.crCaseId!);
    }
    notifyListeners();
  }

  /// 4. Select a specific CR case and load/create register
  Future<void> selectCase({
    required String caseId,
    required String crNumber,
    required String stationName,
    String? ioName,
    String? ioId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final caseProps = await _muddemalApi.fetchCaseProperties(caseId);
      _properties = caseProps;

      // Find if register exists for this case in _registers
      final existingReg = _registers.firstWhere(
        (r) => r.crCaseId == caseId || r.crNumberSnapshot == crNumber,
        orElse: () => MuddemalRegisterHeader(
          id: 0,
          registerNo: 'PENDING_REGISTRATION',
          policeStationId: stationName,
          stationName: stationName,
          crCaseId: caseId,
          crNumberSnapshot: crNumber,
          registrationDate: DateTime.now().toIso8601String().split('T').first,
          ioName: ioName,
          ioId: ioId,
          recordStatus: 'Active',
          remarks: 'Muddemal Register for $crNumber',
          properties: caseProps,
        ),
      );

      _activeRegister = existingReg;
      await loadDiscoverableProperties(caseId);
    } catch (e) {
      _errorMessage = 'Error selecting CR case: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 5. Load dynamic field schema for category (cached)
  Future<List<DynamicFieldDef>> loadCategoryFields(String categoryCode) async {
    if (_categoryFieldCache.containsKey(categoryCode)) {
      _currentCategoryFields = _categoryFieldCache[categoryCode]!;
      notifyListeners();
      return _currentCategoryFields;
    }

    _isFieldsLoading = true;
    notifyListeners();

    try {
      final fields = await _muddemalApi.fetchCategoryFields(categoryCode);
      _categoryFieldCache[categoryCode] = fields;
      _currentCategoryFields = fields;
    } catch (e) {
      debugPrint('[MuddemalProvider] loadCategoryFields error: $e');
    } finally {
      _isFieldsLoading = false;
      notifyListeners();
    }
    return _currentCategoryFields;
  }

  /// 6. Load cross-module discoverable properties from SeizureRecords & Case JSON
  Future<void> loadDiscoverableProperties(String caseId) async {
    try {
      _discoveredProperties =
          await _muddemalApi.fetchDiscoverableProperties(caseId);
    } catch (e) {
      debugPrint('[MuddemalProvider] loadDiscoverableProperties error: $e');
    }
    notifyListeners();
  }

  /// 7. Add Property under active register
  Future<MuddemalPropertyItem?> addProperty(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Ensure register exists
      if (_activeRegister == null || _activeRegister!.id == 0) {
        final regData = {
          'station_name':
              _filterStation.isNotEmpty ? _filterStation : 'Station',
          'cr_case_id': _activeRegister?.crCaseId,
          'cr_number_snapshot':
              _activeRegister?.crNumberSnapshot ?? 'CR-00/2026',
          'investigating_officer_name': _activeRegister?.ioName ?? '',
          'investigating_officer_id': _activeRegister?.ioId ?? '',
        };
        final newReg = await _muddemalApi.createRegister(regData);
        if (newReg != null) {
          _activeRegister = newReg;
          _registers.insert(0, newReg);
        }
      }

      data['muddemal_record'] = _activeRegister?.id;

      final newProp = await _muddemalApi.createProperty(data);
      if (newProp != null) {
        _properties.insert(0, newProp);
        _refreshActiveRegisterValuations();
        _isLoading = false;
        notifyListeners();
        return newProp;
      } else {
        _errorMessage =
            _muddemalApi.lastError ?? 'Failed to register property.';
      }
    } catch (e) {
      _errorMessage = 'Failed to create property: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  /// 8. Update Property
  Future<bool> updateProperty(int propertyId, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updated = await _muddemalApi.updateProperty(propertyId, data);
      if (updated != null) {
        final idx = _properties.indexWhere((p) => p.id == propertyId);
        if (idx >= 0) _properties[idx] = updated;
        if (_selectedProperty?.id == propertyId) _selectedProperty = updated;
        _refreshActiveRegisterValuations();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = _muddemalApi.lastError ?? 'Failed to update property.';
      }
    } catch (e) {
      _errorMessage = 'Failed to update property: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  /// 9. Link discovered source property idempotently
  Future<bool> linkDiscoveredProperty(
      String caseId, DiscoveredSourceProperty item) async {
    try {
      final prop = await _muddemalApi.linkDiscoveredProperty(caseId, {
        'muddemal_record_id': _activeRegister?.id,
        'source_module': item.sourceModule,
        'source_record_id': item.sourceRecordId,
        'category_code': item.inferredCategoryCode,
        'description': item.description,
        'quantity': item.quantity,
        'unit': item.unit,
        'total_item_value': item.totalItemValue,
        'seized_from': item.seizedFrom,
      });

      if (prop != null) {
        final existingIdx = _properties.indexWhere((p) => p.id == prop.id);
        if (existingIdx >= 0) {
          _properties[existingIdx] = prop;
        } else {
          _properties.insert(0, prop);
        }
        await loadDiscoverableProperties(caseId);
        _refreshActiveRegisterValuations();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[MuddemalProvider] linkDiscoveredProperty error: $e');
    }
    return false;
  }

  /// 10. Record Custody Movement
  Future<bool> recordMovement(int propertyId, Map<String, dynamic> data) async {
    final ok = await _muddemalApi.recordMovement(propertyId, data);
    if (ok) {
      await loadProperties();
    }
    return ok;
  }

  /// 11. Record FSL Action
  Future<bool> recordFSL(int propertyId, Map<String, dynamic> data) async {
    final ok = await _muddemalApi.recordFSL(propertyId, data);
    if (ok) {
      await loadProperties();
      loadFSLAlerts();
    }
    return ok;
  }

  /// 12. Record Disposal / Supurdnama
  Future<bool> recordDisposal(int propertyId, Map<String, dynamic> data) async {
    final ok = await _muddemalApi.recordDisposal(propertyId, data);
    if (ok) {
      await loadProperties();
    }
    return ok;
  }

  /// Fetch audit trail for a property
  Future<List<Map<String, dynamic>>> fetchAuditTrail(int propertyId) async {
    return await _muddemalApi.fetchAuditTrail(propertyId);
  }

  Future<void> refreshCaseProperties(String caseId) async {
    await loadProperties();
    if (_selectedProperty != null) {
      _selectedProperty = _properties.firstWhere(
        (p) => p.id == _selectedProperty!.id,
        orElse: () => _selectedProperty!,
      );
    }
    _refreshActiveRegisterValuations();
    notifyListeners();
  }

  void setSelectedProperty(MuddemalPropertyItem? prop) {
    _selectedProperty = prop;
    notifyListeners();
  }

  /// 13. Load FSL Alerts
  Future<void> loadFSLAlerts() async {
    try {
      _fslAlerts =
          await _muddemalApi.fetchFSLAlerts(stationName: _filterStation);
    } catch (e) {
      debugPrint('[MuddemalProvider] loadFSLAlerts error: $e');
    }
    notifyListeners();
  }

  /// 14. Load Dashboards
  Future<void> loadDashboards() async {
    try {
      final results = await Future.wait([
        _muddemalApi.fetchStolenDashboard(
            stationName: _filterStation, year: _selectedYear),
        _muddemalApi.fetchSeizedDashboard(
            stationName: _filterStation, year: _selectedYear),
        _muddemalApi.fetchPendingDashboard(
            stationName: _filterStation, year: _selectedYear),
        _muddemalApi.fetchMonthlyYearlyReport(
            stationName: _filterStation, year: _selectedYear),
      ]);

      _stolenDashboard = results[0];
      _seizedDashboard = results[1];
      _pendingDashboard = results[2];
      _monthlyYearlyReport = results[3];
    } catch (e) {
      debugPrint('[MuddemalProvider] loadDashboards error: $e');
    }
    notifyListeners();
  }

  void _refreshActiveRegisterValuations() {
    // Live client-side recalculation of totals for responsive UI update
    double stolenVal = 0;
    double recoveredVal = 0;
    double seizedVal = 0;
    double totalVal = 0;
    int stolenCount = 0;

    for (final p in _properties) {
      totalVal += p.totalItemValue;
      final isStolen = p.categoryCode == 'STOLEN_PROPERTY' ||
          p.propertyStatus == 'Stolen – Not Recovered' ||
          p.propertyStatus == 'Recovered';

      if (isStolen) {
        stolenCount++;
        stolenVal += p.totalItemValue;
        if (p.propertyStatus == 'Recovered') {
          recoveredVal += p.totalItemValue;
        }
      } else {
        seizedVal += p.totalItemValue;
      }
    }

    final notRec = (stolenVal - recoveredVal).clamp(0, double.infinity);
    final recPct = stolenVal > 0 ? (recoveredVal / stolenVal) * 100 : 0.0;

    if (_activeRegister != null) {
      _activeRegister = MuddemalRegisterHeader(
        id: _activeRegister!.id,
        registerNo: _activeRegister!.registerNo,
        policeStationId: _activeRegister!.policeStationId,
        stationName: _activeRegister!.stationName,
        crCaseId: _activeRegister!.crCaseId,
        crNumberSnapshot: _activeRegister!.crNumberSnapshot,
        registrationDate: _activeRegister!.registrationDate,
        ioName: _activeRegister!.ioName,
        ioId: _activeRegister!.ioId,
        recordStatus: _activeRegister!.recordStatus,
        remarks: _activeRegister!.remarks,
        propertiesCount: _properties.length,
        valuations: {
          'total_registered_value': totalVal,
          'total_stolen_value': stolenVal,
          'recovered_property_value': recoveredVal,
          'not_recovered_property_value': notRec,
          'total_seized_property_value': seizedVal,
          'recovery_percentage':
              stolenVal > 0 ? '${recPct.toStringAsFixed(2)}%' : 'N/A',
          'recovery_percentage_numeric': recPct,
          'total_stolen_items_count': stolenCount,
        },
        properties: _properties,
      );
    }
  }
}
