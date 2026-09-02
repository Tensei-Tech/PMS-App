import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:web/web.dart' as web;
import 'evidence_geotag_service.dart';

Future<GeotagLocation?> getWebCurrentLocation() async {
  try {
    final completer = Completer<GeotagLocation?>();
    final options = web.PositionOptions(
      enableHighAccuracy: true,
      timeout: 10000,
    );

    web.window.navigator.geolocation.getCurrentPosition(
      (web.GeolocationPosition pos) {
        final coords = pos.coords;
        final loc = GeotagLocation(
          latitude: coords.latitude.toDouble(),
          longitude: coords.longitude.toDouble(),
          accuracy: coords.accuracy.toDouble(),
          timestamp: DateFormat(
            'dd-MMM-yyyy HH:mm:ss',
          ).format(DateTime.now()),
        );
        completer.complete(loc);
      }.toJS,
      (web.GeolocationPositionError err) {
        debugPrint('Geolocation error: ${err.message}');
        completer.complete(null);
      }.toJS,
      options,
    );
    return await completer.future;
  } catch (e) {
    debugPrint('Web Geolocation exception: $e');
  }
  return null;
}
