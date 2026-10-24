// lib/modules/muddemal/services/muddemal_api_service.dart
// HTTP client service for Digital Muddemal / Property Management Module.
// Strictly speaks to Django REST backend APIs.
import '../../../services/api_config.dart';
import '../../../services/api_service.dart';
import '../../../widgets/dynamic_form/dynamic_field_model.dart';
import '../models/muddemal_models.dart';

class MuddemalApiService {
  final ApiService _api = ApiService();

  String get _base => '${ApiConfig.baseUrl}/muddemal';

  bool _isAllStations(String? st) {
    if (st == null || st.trim().isEmpty) return true;
    final upper = st.trim().toUpperCase();
    return upper == 'ALL' ||
        upper == 'ALL STATIONS' ||
        upper == 'ALL_STATIONS' ||
        upper == 'ALL POLICE STATIONS';
  }

  /// 1. Fetch system configs (alert thresholds, measurement units, statuses)
  Future<Map<String, dynamic>> fetchConfigs() async {
    final res = await _api.get('$_base/configs/');
    if (res.isSuccess && res.data is Map && res.data['configs'] is Map) {
      return Map<String, dynamic>.from(res.data['configs'] as Map);
    }
    return {};
  }

  /// 2. Fetch all 21 property categories
  Future<List<MuddemalCategory>> fetchCategories() async {
    final res = await _api.get('$_base/categories/');
    if (res.isSuccess) {
      final list = (res.data is List)
          ? res.data as List
          : (res.data is Map && res.data['results'] is List)
              ? res.data['results'] as List
              : [];
      return list
          .whereType<Map>()
          .map((m) => MuddemalCategory.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return [];
  }

  /// 3. Fetch dynamic fields for a specific category
  Future<List<DynamicFieldDef>> fetchCategoryFields(String categoryCode) async {
    final res = await _api.get('$_base/categories/$categoryCode/fields/');
    if (res.isSuccess && res.data is Map && res.data['fields'] is List) {
      final rawList = res.data['fields'] as List;
      return rawList
          .whereType<Map>()
          .map((m) => DynamicFieldDef.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return [];
  }

  /// 4. Fetch Muddemal Registers
  Future<List<MuddemalRegisterHeader>> fetchRegisters({
    String? stationName,
    String? crNumber,
    String? status,
    int? year,
  }) async {
    final queryParams = <String, String>{};
    if (!_isAllStations(stationName)) {
      queryParams['station_name'] = stationName!;
    }
    if (crNumber != null && crNumber.isNotEmpty) {
      queryParams['cr_number'] = crNumber;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['record_status'] = status;
    }
    if (year != null) {
      queryParams['year'] = year.toString();
    }

    final queryString = Uri(queryParameters: queryParams).query;
    final url = queryString.isNotEmpty ? '$_base/registers/?$queryString' : '$_base/registers/';

    final res = await _api.get(url);
    if (res.isSuccess) {
      final list = (res.data is List)
          ? res.data as List
          : (res.data is Map && res.data['results'] is List)
              ? res.data['results'] as List
              : [];
      return list
          .whereType<Map>()
          .map((m) => MuddemalRegisterHeader.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return [];
  }

  /// 5. Create a new Muddemal Register header
  Future<MuddemalRegisterHeader?> createRegister(Map<String, dynamic> data) async {
    final res = await _api.post('$_base/registers/', data: data);
    if (res.isSuccess && res.data is Map) {
      return MuddemalRegisterHeader.fromJson(Map<String, dynamic>.from(res.data as Map));
    }
    return null;
  }

  /// 6. Fetch properties for a specific CR Case
  Future<List<MuddemalPropertyItem>> fetchCaseProperties(String caseId) async {
    final res = await _api.get('$_base/cases/$caseId/properties/');
    if (res.isSuccess && res.data is Map && res.data['properties'] is List) {
      final list = res.data['properties'] as List;
      return list
          .whereType<Map>()
          .map((m) => MuddemalPropertyItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return [];
  }

  /// 7. Discover candidate properties from SeizureRecords & Case JSON
  Future<List<DiscoveredSourceProperty>> fetchDiscoverableProperties(String caseId) async {
    final res = await _api.get('$_base/cases/$caseId/discoverable-properties/');
    if (res.isSuccess && res.data is Map && res.data['discovered_properties'] is List) {
      final list = res.data['discovered_properties'] as List;
      return list
          .whereType<Map>()
          .map((m) => DiscoveredSourceProperty.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return [];
  }

  /// 8. Idempotently link discovered source property
  Future<MuddemalPropertyItem?> linkDiscoveredProperty(
    String caseId,
    Map<String, dynamic> data,
  ) async {
    final res = await _api.post('$_base/cases/$caseId/link-property/', data: data);
    if (res.isSuccess && res.data is Map && res.data['property'] is Map) {
      return MuddemalPropertyItem.fromJson(Map<String, dynamic>.from(res.data['property'] as Map));
    }
    return null;
  }

  /// 8a. Centralized fetch of all Muddemal properties (auto-synced from Crime, Prohibition, Gambling, etc.)
  Future<List<MuddemalPropertyItem>> fetchProperties({
    String? stationName,
    String? categoryCode,
    String? propertyStatus,
    String? sourceModule,
    String? fslStatus,
    int? year,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (!_isAllStations(stationName)) {
      queryParams['station_name'] = stationName!;
    }
    if (categoryCode != null && categoryCode.isNotEmpty && categoryCode != 'ALL') {
      queryParams['category'] = categoryCode;
    }
    if (propertyStatus != null && propertyStatus.isNotEmpty && propertyStatus != 'ALL') {
      queryParams['property_status'] = propertyStatus;
    }
    if (sourceModule != null && sourceModule.isNotEmpty && sourceModule != 'ALL' && sourceModule != 'all') {
      queryParams['source_module'] = sourceModule;
    }
    if (fslStatus != null && fslStatus.isNotEmpty && fslStatus != 'ALL') {
      queryParams['fsl_status'] = fslStatus;
    }
    if (year != null) {
      queryParams['year'] = year.toString();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final queryString = Uri(queryParameters: queryParams).query;
    final url = queryString.isNotEmpty ? '$_base/properties/?$queryString' : '$_base/properties/';

    final res = await _api.get(url);
    if (res.isSuccess) {
      final list = (res.data is List)
          ? res.data as List
          : (res.data is Map && res.data['results'] is List)
              ? res.data['results'] as List
              : [];
      return list
          .whereType<Map>()
          .map((m) => MuddemalPropertyItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return [];
  }

  /// 8b. Explicitly trigger auto-sync across all connected PMS modules
  Future<Map<String, dynamic>> syncSourceModules({String? stationName}) async {
    final queryParams = <String, String>{};
    if (!_isAllStations(stationName)) {
      queryParams['station_name'] = stationName!;
    }
    final queryString = Uri(queryParameters: queryParams).query;
    final url = queryString.isNotEmpty ? '$_base/properties/sync/?$queryString' : '$_base/properties/sync/';

    final res = await _api.post(url);
    if (res.isSuccess && res.data is Map) {
      return Map<String, dynamic>.from(res.data as Map);
    }
    return {};
  }

  /// 8c. Fetch Auto-Fetch architecture diagnostics & connected source modules status
  Future<Map<String, dynamic>> fetchAutoFetchStatus() async {
    final res = await _api.get('$_base/auto-fetch/');
    if (res.isSuccess && res.data is Map) {
      return Map<String, dynamic>.from(res.data as Map);
    }
    return {};
  }

  /// 8d. Fetch real-time valuation summary from backend database
  Future<Map<String, dynamic>> fetchPropertySummary({
    String? stationName,
    String? categoryCode,
    String? sourceModule,
    String? propertyStatus,
    int? year,
  }) async {
    final queryParams = <String, String>{};
    if (!_isAllStations(stationName)) {
      queryParams['station_name'] = stationName!;
    }
    if (categoryCode != null && categoryCode.isNotEmpty && categoryCode != 'ALL') {
      queryParams['category_code'] = categoryCode;
    }
    if (sourceModule != null && sourceModule.isNotEmpty && sourceModule != 'ALL' && sourceModule != 'all') {
      queryParams['source_module'] = sourceModule;
    }
    if (propertyStatus != null && propertyStatus.isNotEmpty && propertyStatus != 'ALL') {
      queryParams['property_status'] = propertyStatus;
    }
    if (year != null) {
      queryParams['year'] = year.toString();
    }

    final queryString = Uri(queryParameters: queryParams).query;
    final url = queryString.isNotEmpty ? '$_base/properties/summary/?$queryString' : '$_base/properties/summary/';

    final res = await _api.get(url);
    if (res.isSuccess && res.data is Map && res.data['summary'] is Map) {
      return Map<String, dynamic>.from(res.data['summary'] as Map);
    }
    return {};
  }

  String? lastError;

  /// 9. Create a new property
  Future<MuddemalPropertyItem?> createProperty(Map<String, dynamic> data) async {
    lastError = null;
    final res = await _api.post('$_base/properties/', data: data);
    if (res.isSuccess && res.data is Map) {
      return MuddemalPropertyItem.fromJson(Map<String, dynamic>.from(res.data as Map));
    }
    lastError = res.errorMessage ?? (res.data != null ? res.data.toString() : 'Failed to register property.');
    return null;
  }

  /// 10. Update property (e.g. valuation, extra_fields, status)
  Future<MuddemalPropertyItem?> updateProperty(
    int propertyId,
    Map<String, dynamic> data,
  ) async {
    lastError = null;
    final res = await _api.put('$_base/properties/$propertyId/', data: data);
    if (res.isSuccess && res.data is Map) {
      return MuddemalPropertyItem.fromJson(Map<String, dynamic>.from(res.data as Map));
    }
    lastError = res.errorMessage ?? (res.data != null ? res.data.toString() : 'Failed to save changes.');
    return null;
  }

  /// 11. Record chain of custody movement
  Future<bool> recordMovement(int propertyId, Map<String, dynamic> data) async {
    final res = await _api.post('$_base/properties/$propertyId/movements/', data: data);
    return res.isSuccess;
  }

  /// 12. Record FSL dispatch or received report
  Future<bool> recordFSL(int propertyId, Map<String, dynamic> data) async {
    final res = await _api.post('$_base/properties/$propertyId/fsl/', data: data);
    return res.isSuccess;
  }

  /// 13. Record Supurdnama, owner release, or disposal
  Future<bool> recordDisposal(int propertyId, Map<String, dynamic> data) async {
    final res = await _api.post('$_base/properties/$propertyId/disposal/', data: data);
    return res.isSuccess;
  }

  /// 14. Fetch audit trail for property
  Future<List<Map<String, dynamic>>> fetchAuditTrail(int propertyId) async {
    final res = await _api.get('$_base/properties/$propertyId/audit-trail/');
    if (res.isSuccess && res.data is Map && res.data['audit_trail'] is List) {
      return (res.data['audit_trail'] as List).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    }
    return [];
  }

  /// 15. Fetch FSL alerts
  Future<Map<String, dynamic>> fetchFSLAlerts({String? stationName, String? ioName}) async {
    final queryParams = <String, String>{};
    if (stationName != null && stationName != 'ALL') {
      queryParams['station_name'] = stationName;
    }
    if (ioName != null && ioName.isNotEmpty) {
      queryParams['io_name'] = ioName;
    }
    final queryString = Uri(queryParameters: queryParams).query;
    final url = queryString.isNotEmpty ? '$_base/alerts/fsl/?$queryString' : '$_base/alerts/fsl/';

    final res = await _api.get(url);
    if (res.isSuccess && res.data is Map && res.data['alerts'] is Map) {
      return Map<String, dynamic>.from(res.data['alerts'] as Map);
    }
    return {};
  }

  /// 16. Fetch Dashboards
  Future<Map<String, dynamic>> fetchStolenDashboard({String? stationName, int? year, int? month}) async {
    final q = <String, String>{};
    if (stationName != null && stationName != 'ALL') q['station_name'] = stationName;
    if (year != null) q['year'] = year.toString();
    if (month != null) q['month'] = month.toString();
    final qs = Uri(queryParameters: q).query;
    final url = qs.isNotEmpty ? '$_base/dashboards/stolen/?$qs' : '$_base/dashboards/stolen/';

    final res = await _api.get(url);
    if (res.isSuccess && res.data is Map && res.data['dashboard'] is Map) {
      return Map<String, dynamic>.from(res.data['dashboard'] as Map);
    }
    return {};
  }

  Future<Map<String, dynamic>> fetchSeizedDashboard({String? stationName, int? year, int? month}) async {
    final q = <String, String>{};
    if (stationName != null && stationName != 'ALL') q['station_name'] = stationName;
    if (year != null) q['year'] = year.toString();
    if (month != null) q['month'] = month.toString();
    final qs = Uri(queryParameters: q).query;
    final url = qs.isNotEmpty ? '$_base/dashboards/seized/?$qs' : '$_base/dashboards/seized/';

    final res = await _api.get(url);
    if (res.isSuccess && res.data is Map && res.data['dashboard'] is Map) {
      return Map<String, dynamic>.from(res.data['dashboard'] as Map);
    }
    return {};
  }

  Future<Map<String, dynamic>> fetchPendingDashboard({String? stationName, int? year, int? month}) async {
    final q = <String, String>{};
    if (stationName != null && stationName != 'ALL') q['station_name'] = stationName;
    if (year != null) q['year'] = year.toString();
    if (month != null) q['month'] = month.toString();
    final qs = Uri(queryParameters: q).query;
    final url = qs.isNotEmpty ? '$_base/dashboards/pending/?$qs' : '$_base/dashboards/pending/';

    final res = await _api.get(url);
    if (res.isSuccess && res.data is Map && res.data['dashboard'] is Map) {
      return Map<String, dynamic>.from(res.data['dashboard'] as Map);
    }
    return {};
  }

  Future<Map<String, dynamic>> fetchMonthlyYearlyReport({String? stationName, int? year}) async {
    final q = <String, String>{};
    if (stationName != null && stationName != 'ALL') q['station_name'] = stationName;
    if (year != null) q['year'] = year.toString();
    final qs = Uri(queryParameters: q).query;
    final url = qs.isNotEmpty ? '$_base/dashboards/monthly-yearly/?$qs' : '$_base/dashboards/monthly-yearly/';

    final res = await _api.get(url);
    if (res.isSuccess && res.data is Map && res.data['report'] is Map) {
      return Map<String, dynamic>.from(res.data['report'] as Map);
    }
    return {};
  }
}
