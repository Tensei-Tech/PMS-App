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

      // 2. Active network probe: verify internet reachability without failing on offline local backend
      final client = http.Client();
      try {
        final isLocal = ApiConfig.baseUrl.contains('127.0.0.1') ||
            ApiConfig.baseUrl.contains('localhost');
        if (!isLocal) {
          final probeUri = Uri.parse(ApiConfig.rootHealthUrl).replace(
            queryParameters: {
              '_probe': DateTime.now().millisecondsSinceEpoch.toString(),
            },
          );
          final response = await client
              .get(probeUri)
              .timeout(const Duration(milliseconds: 2500));
          if (response.statusCode != 0) return true;
        }
      } catch (_) {}

      // Fallback probe: Google DNS HTTPS (CORS Access-Control-Allow-Origin: * supported)
      try {
        final response = await client
            .get(Uri.parse('https://dns.google/resolve?name=google.com'))
            .timeout(const Duration(milliseconds: 2500));
        return response.statusCode == 200;
      } catch (_) {
        // If probe fails (e.g. firewalled intranet), trust browser navigator.onLine
        return web.window.navigator.onLine;
      } finally {
        client.close();
      }
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _controller.close();
  }
}
