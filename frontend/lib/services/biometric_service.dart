import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'api_service.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Checks if the device has biometric hardware and supports it.
  Future<bool> isHardwareSupported() async {
    try {
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Checks if biometrics are both supported AND enrolled.
  Future<bool> isBiometricAvailable() async {
    try {
      final bool supported = await isHardwareSupported();
      final bool enrolled = await hasEnrolledBiometrics();
      return supported && enrolled;
    } catch (e) {
      return false;
    }
  }

  /// Returns the type of biometrics available on the device.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return <BiometricType>[];
    }
  }

  /// Checks if there are any enrolled biometrics.
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final List<BiometricType> availableBiometrics =
          await _auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Performs biometric authentication.
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Check if biometric is enabled for a specific user email profile in DB
  Future<bool> isBiometricConfiguredForUser(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      bool localVal = prefs.getBool('biometric_setup_$cleanEmail') ?? false;
      if (localVal) return true;

      // Remote DB query check via /api/auth/check-exists/?email=...
      final apiService = ApiService();
      final response = await apiService.get(
          '${ApiConfig.baseUrl}/auth/check-exists/?email=${Uri.encodeComponent(cleanEmail)}');
      if (response.isSuccess && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        bool remoteVal = data['is_biometric_enabled'] == true;
        if (remoteVal) {
          await prefs.setBool('biometric_setup_$cleanEmail', true);
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Register or unregister biometric setup for a specific user email profile in DB
  Future<void> setBiometricConfiguredForUser(
      String email, bool configured) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_setup_$cleanEmail', configured);

      // Remote DB sync
      final apiService = ApiService();
      await apiService.patch(
        '${ApiConfig.baseUrl}/users/me/',
        body: {'is_biometric_enabled': configured},
      );
    } catch (_) {}
  }
}
