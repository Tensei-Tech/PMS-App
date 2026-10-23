// lib/services/connectivity/connectivity_service.dart
import 'dart:async';

import 'connectivity_engine.dart';
import 'connectivity_engine_stub.dart'
    if (dart.library.io) 'connectivity_engine_io.dart'
    if (dart.library.js_interop) 'connectivity_engine_web.dart'
    show createConnectivityEngine;

export 'connectivity_engine.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;

  ConnectivityService._internal() {
    _engine = createConnectivityEngine();
    _engine.onConnectivityChanged?.listen((online) {
      reportConnectionStatus(online);
    });
  }

  late final ConnectivityEngine _engine;
  final _controller = StreamController<bool>.broadcast();
  bool _lastKnownStatus = true;
  int _consecutiveFailures = 0;
  DateTime? _lastSuccessfulRequest;

  Stream<bool> get onStatusChanged => _controller.stream;
  bool get isConnected => _lastKnownStatus;

  /// Called when an API request succeeds to confirm connection is healthy
  void reportApiSuccess() {
    _lastSuccessfulRequest = DateTime.now();
    _consecutiveFailures = 0;
    reportConnectionStatus(true);
  }

  /// Explicitly check internet connection
  Future<bool> checkConnection() async {
    final status = await _engine.checkInternet();
    if (!status) {
      // If a successful API response happened in the last 6 seconds, ignore transient probe timeout
      if (_lastSuccessfulRequest != null &&
          DateTime.now().difference(_lastSuccessfulRequest!).inSeconds < 6) {
        return true;
      }
      _consecutiveFailures++;
      // Require 2 consecutive failed probes before flagging offline
      if (_consecutiveFailures < 2 && _lastKnownStatus) {
        return true;
      }
    } else {
      _consecutiveFailures = 0;
    }
    reportConnectionStatus(status);
    return status;
  }

  /// Called internally by engine or externally by ApiService on network success/failure
  void reportConnectionStatus(bool isConnected) {
    if (isConnected) {
      _consecutiveFailures = 0;
    }
    if (_lastKnownStatus != isConnected) {
      _lastKnownStatus = isConnected;
      _controller.add(isConnected);
    }
  }

  void dispose() {
    _engine.dispose();
    _controller.close();
  }
}
