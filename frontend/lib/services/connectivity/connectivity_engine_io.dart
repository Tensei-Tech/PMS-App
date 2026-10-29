// lib/services/connectivity/connectivity_engine_io.dart
import 'dart:async';
import 'dart:io';

import 'connectivity_engine.dart';

export 'connectivity_engine.dart';

ConnectivityEngine createConnectivityEngine() => _IoConnectivityEngine();

class _IoConnectivityEngine implements ConnectivityEngine {
  final _controller = StreamController<bool>.broadcast();

  @override
  Stream<bool>? get onConnectivityChanged => _controller.stream;

  @override
  Future<bool> checkInternet() async {
    // 1. Primary DNS lookup check
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(milliseconds: 2500));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    // 2. Fallback direct socket probe to Google public DNS (port 53)
    try {
      final socket = await Socket.connect(
        '8.8.8.8',
        53,
        timeout: const Duration(milliseconds: 2000),
      );
      socket.destroy();
      return true;
    } catch (_) {}

    // 3. Fallback direct socket probe to Cloudflare public DNS (port 53)
    try {
      final socket = await Socket.connect(
        '1.1.1.1',
        53,
        timeout: const Duration(milliseconds: 2000),
      );
      socket.destroy();
      return true;
    } catch (_) {}

    return false;
  }

  @override
  void dispose() {
    _controller.close();
  }
}
