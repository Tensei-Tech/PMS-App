// lib/services/connectivity/connectivity_engine_web.dart
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

import '../api_config.dart';
import 'connectivity_engine.dart';

export 'connectivity_engine.dart';

ConnectivityEngine createConnectivityEngine() => _WebConnectivityEngine();

class _WebConnectivityEngine implements ConnectivityEngine {
  final _controller = StreamController<bool>.broadcast();

  _WebConnectivityEngine() {
    _attachListeners();
  }

  void _attachListeners() {
    try {
      final win = web.window as JSObject;

      // 1. Direct window.onoffline and window.ononline handlers
      win.setProperty(
        'onoffline'.toJS,
        ((JSAny? e) {
          _controller.add(false);
        }).toJS,
      );

      win.setProperty(
        'ononline'.toJS,
        ((JSAny? e) {
          _controller.add(true);
        }).toJS,
      );

      // 2. addEventListener for both events
      win.callMethod(
        'addEventListener'.toJS,
        'offline'.toJS,
        ((JSAny? e) {
          _controller.add(false);
        }).toJS,
      );

      win.callMethod(
        'addEventListener'.toJS,
        'online'.toJS,
        ((JSAny? e) {
          _controller.add(true);
        }).toJS,
      );
    } catch (_) {}
  }

  @override
  Stream<bool>? get onConnectivityChanged => _controller.stream;

  @override
  Future<bool> checkInternet() async {
    try {
      // 1. Browser navigator.onLine check
      if (!web.window.navigator.onLine) {
        return false;
      }

      // 2. Active network probe: catches DevTools "Offline" throttling and real internet loss
      final probeUri = Uri.parse(ApiConfig.rootHealthUrl).replace(
        queryParameters: {
          '_probe': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final client = http.Client();
      try {
        final response = await client
            .get(probeUri)
            .timeout(const Duration(milliseconds: 3500));
        // Any HTTP response (200, 401, 404, etc.) proves network is active
        return response.statusCode != 0;
      } finally {
        client.close();
      }
    } catch (_) {
      // Network failure, timeout, or DevTools Offline throttling
      return false;
    }
  }

  @override
  void dispose() {
    _controller.close();
  }
}
