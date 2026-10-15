// lib/providers/connectivity_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/connectivity/connectivity_service.dart';

class ConnectivityProvider extends ChangeNotifier {
  final ConnectivityService _service = ConnectivityService();

  bool _isConnected = true;
  bool _isChecking = false;
  bool _wasOffline = false;
  bool _userDismissedBanner = false;
  DateTime? _lastChecked;
  Timer? _heartbeatTimer;
  StreamSubscription<bool>? _subscription;

  bool get isConnected => _isConnected;
  bool get isChecking => _isChecking;
  bool get wasOffline => _wasOffline;
  bool get userDismissedBanner => _userDismissedBanner;
  DateTime? get lastChecked => _lastChecked;

  ConnectivityProvider() {
    _init();
  }

  void _init() {
    _subscription = _service.onStatusChanged.listen((connected) {
      _handleStatusChange(connected);
    });

    // Run an initial non-blocking connectivity check
    unawaited(checkConnection());

    // Adaptive heartbeat: 15s when online, 4s when offline to recover fast
    _startHeartbeat();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    final interval = _isConnected
        ? const Duration(seconds: 15)
        : const Duration(seconds: 4);
    _heartbeatTimer = Timer(interval, () async {
      await checkConnection(background: true);
      _startHeartbeat();
    });
  }

  void _handleStatusChange(bool connected) {
    _lastChecked = DateTime.now();
    if (_isConnected != connected) {
      if (!connected) {
        _wasOffline = true;
        _userDismissedBanner = false; // Reset dismissal when connection is lost
      }
      _isConnected = connected;
      _startHeartbeat();
      notifyListeners();
    }
  }

  /// Manually or automatically trigger an internet reachability check
  Future<bool> checkConnection({bool background = false}) async {
    if (!background) {
      _isChecking = true;
      notifyListeners();
    }

    try {
      final connected = await _service.checkConnection();
      _handleStatusChange(connected);
      return connected;
    } finally {
      if (!background) {
        _isChecking = false;
        notifyListeners();
      }
    }
  }

  /// Allow the user to hide the top warning banner temporarily
  void dismissBanner() {
    _userDismissedBanner = true;
    notifyListeners();
  }

  /// Reset dismissal so banner can be displayed again
  void showBannerAgain() {
    _userDismissedBanner = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
