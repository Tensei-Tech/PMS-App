// lib/services/connectivity/connectivity_engine_stub.dart
import 'dart:async';
import 'connectivity_engine.dart';

export 'connectivity_engine.dart';

ConnectivityEngine createConnectivityEngine() => _StubConnectivityEngine();

class _StubConnectivityEngine implements ConnectivityEngine {
  @override
  Future<bool> checkInternet() async => true;

  @override
  Stream<bool>? get onConnectivityChanged => null;

  @override
  void dispose() {}
}
