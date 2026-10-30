// lib/services/connectivity/connectivity_engine.dart
import 'dart:async';

abstract class ConnectivityEngine {
  Future<bool> checkInternet();
  Stream<bool>? get onConnectivityChanged => null;
  void dispose() {}
}
