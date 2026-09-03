import 'package:flutter/foundation.dart';
import 'evidence_geotag_service.dart';
import 'api_config.dart';
import 'api_service.dart';

class OfficerSosService {
  static final OfficerSosService _instance = OfficerSosService._internal();
  factory OfficerSosService() => _instance;
  OfficerSosService._internal();

  final ApiService _api = ApiService();

  /// Broadcasts an Emergency Duress SOS Alert to Control Room & Admin Console
  Future<String> triggerEmergencySos({
    required String officerName,
    required String sevaNumber,
    required String designation,
    required String stationName,
    required String contactNumber,
    String officerId = 'officer',
    String? note,
  }) async {
    final alertId = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      final location = await EvidenceGeotagService().getCurrentLocation();

      final lat = location?.latitude ?? 0.0;
      final lng = location?.longitude ?? 0.0;
      final mapsUrl = (lat != 0.0 && lng != 0.0)
          ? 'https://www.google.com/maps/search/?api=1&query=$lat,$lng'
          : null;

      final payload = {
        'id': alertId,
        'officer_id': officerId,
        'officer_name': officerName,
        'seva_number': sevaNumber,
        'designation': designation,
        'station_name': stationName,
        'contact_number': contactNumber,
        'status': 'ACTIVE_DURESS',
        'note': note ?? 'Officer triggered Emergency SOS in field',
        'latitude': lat,
        'longitude': lng,
        'accuracy': location?.accuracy,
        'maps_url': mapsUrl,
        'is_resolved': false,
      };

      // Post to PostgreSQL Django API
      try {
        await _api.post(ApiConfig.sosAlerts, data: payload);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[OfficerSosService] Django SOS endpoint error: $e');
        }
      }

      return alertId;
    } catch (e) {
      if (kDebugMode) debugPrint('Emergency SOS trigger failed: $e');
      return alertId;
    }
  }

  /// Resolve an existing SOS alert
  Future<void> resolveSosAlert(String alertId, {String? resolutionNote}) async {
    try {
      await _api.post('${ApiConfig.sosAlerts}$alertId/resolve/', data: {
        'resolution_note': resolutionNote ?? 'Resolved by Control Room',
      });
    } catch (_) {}
  }
}
