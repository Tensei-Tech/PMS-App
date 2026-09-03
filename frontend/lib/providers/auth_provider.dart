import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../constants/app_constants.dart';
import '../services/api_config.dart';
import '../services/api_service.dart';
import '../utils/app_constants.dart';
import '../utils/pin_crypto.dart';
import '../services/firestore_service.dart';
import '../services/lockout_service.dart';
import '../services/audit_service.dart';
import '../services/secure_storage.dart';
import '../models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import '../services/permission_service.dart';


void _secureLog(String message) {
  if (kDebugMode) debugPrint('[AuthProvider] $message');
}

class RegistrationResult {
  final bool success;
  final String? errorCode;
  final String? errorMessage;
  final String? userId;

  const RegistrationResult._({
    required this.success,
    this.errorCode,
    this.errorMessage,
    this.userId,
  });

  factory RegistrationResult.success(String userId) =>
      RegistrationResult._(success: true, userId: userId);

  factory RegistrationResult.failure(String code, String message) =>
      RegistrationResult._(success: false, errorCode: code, errorMessage: message);

  factory RegistrationResult.networkError() => const RegistrationResult._(
        success: false,
        errorCode: 'network-request-failed',
        errorMessage: 'Network connection failed. Please check your internet connection.',
      );

  factory RegistrationResult.emailInUse() => const RegistrationResult._(
        success: false,
        errorCode: 'email-already-in-use',
        errorMessage: 'This Government ID is already registered. Please login instead.',
      );

  factory RegistrationResult.weakPassword() => const RegistrationResult._(
        success: false,
        errorCode: 'weak-password',
        errorMessage: 'PIN does not meet security requirements. Please try again.',
      );

  factory RegistrationResult.invalidEmail() => const RegistrationResult._(
        success: false,
        errorCode: 'invalid-email',
        errorMessage: 'Invalid email format. Please enter a valid Government Email.',
      );

  factory RegistrationResult.unknownError(String message) => RegistrationResult._(
        success: false,
        errorCode: 'unknown',
        errorMessage: 'Registration failed: $message',
      );

  factory RegistrationResult.firestoreError(String authUid, {String? message}) =>
      RegistrationResult._(
        success: false,
        errorCode: 'backend-error',
        errorMessage: message ??
            'Could not save your profile to the database. Please try again or contact support.',
        userId: authUid,
      );
}

class AuthProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  final LockoutService _lockout = LockoutService();
  final AuditService _audit = AuditService();
  static final _secure = SecureStorage.instance;

  bool _isSessionActive = false;
  bool _isRegistered = false;
  bool _isInitialized = false;

  String _uid = '';
  String _username = '';
  String _fullName = '';
  String _email = '';
  String _phone = '';
  String _designation = '';
  String _badgeNumber = '';
  String _stationName = '';
  String? _overrideStationName;
  String _stationAddress = '';
  String _stationLandline = '';
  String _govtId = '';
  String _profilePhoto = '';
  String _role = 'officer';
  String _stateCode = 'MH';
  List<String> _additionalStations = [];
  String? _district;
  String? _divisionName;
  String? _zone;
  String _accountStatus = UserAccountStatus.active;
  String _status = '';
  bool _stationCaseViewGranted = false;
  String? _departmentLogoUrl;
  String get uid => _uid;
  String? get departmentLogoUrl => _departmentLogoUrl;

  bool get isSessionActive => _isSessionActive;
  bool get isRegistered => _isRegistered;
  bool get isLoggedIn => _isSessionActive;
  bool get isInitialized => _isInitialized;
  String get username => _username;
  String get fullName => _fullName;
  String get email => _email;
  String get phone => _phone;
  String get contactNumber => _phone;
  String get designation => _designation;
  String get badgeNumber => _badgeNumber;
  String get sevaNumber => _badgeNumber.isNotEmpty ? _badgeNumber : _govtId;
  String get stationName => _overrideStationName ?? _stationName;
  /// Active station for queries and new records (may differ from [homeStationName] when switched).
  String get activeStation => stationName;
  String get homeStationName => _stationName;
  String get stationAddress => _stationAddress;
  String get stationLandline => _stationLandline;
  String get govtId => _govtId;
  String get profilePhoto => _profilePhoto;
  String get role => _role;
  String get roleId => _role;
  String get stateCode => _stateCode;
  List<String> get additionalStations => List.unmodifiable(_additionalStations);
  String get district => _district ?? '';
  String get divisionName => _divisionName ?? '';
  String get zone => _zone ?? _district ?? '';
  String get accountStatus => _accountStatus;
  String get status => _status;
  bool get stationCaseViewGranted => _stationCaseViewGranted;
  bool get isAccountActive =>
      _accountStatus == UserAccountStatus.active &&
      _status.trim().toLowerCase() != 'inactive';
  bool get isAccountPendingApproval =>
      _accountStatus == UserAccountStatus.pendingApproval;

  UserModel? get currentUser => uid.isNotEmpty
      ? UserModel(
          uid: uid,
          name: fullName,
          badgeNumber: badgeNumber,
          designation: designation,
          email: email,
          phone: phone,
          stationName: stationName,
          stationAddress: stationAddress,
          stationLandline: stationLandline,
          govtId: govtId,
          photoUrl: profilePhoto,
          role: role,
          stateCode: stateCode,
          district: district,
          zone: zone,
          stationCaseViewGranted: _stationCaseViewGranted,
          departmentLogoUrl: _departmentLogoUrl,
        )
      : null;

  bool get isAdmin => _role == 'admin' || _role == 'master_admin';
  bool get isSupervisor => _role == 'supervisor' || _role == 'division_admin' || _role == 'district_admin' || _role == 'admin' || _role == 'master_admin';
  bool get isViewingOtherStation =>
      _overrideStationName != null && _overrideStationName != _stationName;

  DynamicPermissionsModel? _dynamicPermissions;
  DynamicPermissionsModel? get dynamicPermissions => _dynamicPermissions;

  /// Evaluate dynamic DB permission flag
  bool hasPermission(String permissionCode) {
    if (_dynamicPermissions != null) {
      return _dynamicPermissions!.hasPermission(permissionCode);
    }
    // Fallback based on 6-tier Police RBAC Specification Matrix
    final normRole = _role.toLowerCase().trim();
    switch (permissionCode) {
      case 'alert:send':
      case 'reminder:send':
        return ['master_admin', 'state_super_admin', 'district_admin'].contains(normRole);
      case 'reminder:to_io':
        return ['master_admin', 'state_super_admin', 'district_admin', 'supervisor', 'division_admin', 'station_admin'].contains(normRole);
      case 'district:view_data':
        return ['master_admin', 'state_super_admin', 'district_admin', 'supervisor', 'division_admin'].contains(normRole);
      case 'station:view_data':
        return true;
      case 'station:select_multiple':
      case 'station:switch':
        return ['master_admin', 'state_super_admin', 'district_admin', 'supervisor', 'division_admin'].contains(normRole);
      case 'case:edit_station':
        return ['master_admin', 'state_super_admin', 'district_admin', 'supervisor', 'division_admin', 'station_admin'].contains(normRole);
      case 'case:edit_own':
        return true;
      default:
        return false;
    }
  }

  /// Sync live DB dynamic permissions from backend API
  Future<void> fetchDynamicPermissions() async {
    try {
      final perms = await PermissionService().fetchUserPermissions();
      if (perms != null) {
        _dynamicPermissions = perms;
        notifyListeners();
      }
    } catch (_) {}
  }


  /// Switch the active station (for senior officers viewing another station).
  void switchStation(String stationName) {
    if (stationName == _stationName) {
      _overrideStationName = null;
    } else {
      _overrideStationName = stationName;
    }
    notifyListeners();
  }

  /// Reset to the officer's home station.
  void resetToHomeStation() {
    _overrideStationName = null;
    notifyListeners();
  }

  /// Add a station to the officer's additional locations list.
  /// Persists to Firestore immediately.
  Future<void> addStation(String stationName) async {
    final trimmed = stationName.trim();
    if (trimmed.isEmpty) return;
    if (_additionalStations.contains(trimmed)) return; // Already added
    if (trimmed == _stationName) return; // Already home station
    _additionalStations.add(trimmed);
    notifyListeners();
    // Persist to Firestore
    try {
      await _firestore.updateUserField(uid, 'additionalStations', _additionalStations);
    } catch (e) {
      _secureLog('addStation: Firestore persist failed');
    }
  }

  /// Remove a station/location from the officer's additional locations list.
  /// Persists to Firestore immediately.
  Future<void> removeStation(String stationName) async {
    final trimmed = stationName.trim();
    if (trimmed.isEmpty) return;
    if (trimmed == _stationName) return; // Never remove home station
    if (!_additionalStations.contains(trimmed)) return;
    _additionalStations.remove(trimmed);
    notifyListeners();
    // Persist to Firestore
    try {
      await _firestore.updateUserField(uid, 'additionalStations', _additionalStations);
    } catch (e) {
      _secureLog('removeStation: Firestore persist failed');
    }
  }

  String get displayName {
    if (_fullName.isNotEmpty) return _fullName;
    if (_username.isNotEmpty) {
      return _username[0].toUpperCase() + _username.substring(1);
    }
    return 'Officer';
  }

  AuthProvider() {
    _init();
  }

  void _init() {
    Future.microtask(() async {
      try {
        final storedEmail = (await _secure.read(key: StorageKeys.email) ?? '').trim();
        final storedToken = (await _secure.read(key: ApiConstants.jwtAccessTokenKey) ?? '').trim();
        final storedProfileJson = await _secure.read(key: 'user_profile_json');

        if (storedProfileJson != null && storedProfileJson.isNotEmpty) {
          try {
            final userMap = json.decode(storedProfileJson) as Map<String, dynamic>;
            final profile = UserModel.fromMap(userMap);
            _applyProfile(profile);
            _uid = profile.uid;
          } catch (_) {}
        }

        bool isTokenValid = false;
        if (storedToken.isNotEmpty && !ApiService().isTokenExpired(storedToken)) {
          await ApiService().setAuthToken(storedToken);
          isTokenValid = true;
        } else {
          // Attempt silent refresh via Refresh Token
          final refreshed = await ApiService().refreshAccessToken();
          if (refreshed) {
            isTokenValid = true;
          }
        }

        if (isTokenValid) {
          _isRegistered = true;
          _isSessionActive = true;
          unawaited(fetchDynamicPermissions());
        } else {
          await ApiService().clearAuthToken();
          _isSessionActive = false;
        }
      } catch (e, s) {
        _secureLog('Error in AuthProvider _init: $e\n$s');
      } finally {
        _isInitialized = true;
        notifyListeners();
      }
    });
  }

  void _applyProfile(UserModel profile) {
    _username = profile.name;
    _fullName = profile.name;
    _email = profile.email;
    _phone = profile.phone;
    _designation = profile.designation;
    _badgeNumber = profile.badgeNumber;
    _stationName = profile.stationName;
    _overrideStationName = null;
    _stationAddress = profile.stationAddress;
    _stationLandline = profile.stationLandline;
    _govtId = profile.govtId;
    _profilePhoto = profile.photoUrl;
    _role = profile.role.isNotEmpty ? profile.role : 'officer';
    _stateCode = profile.stateCode.isNotEmpty ? profile.stateCode : 'MH';
    _additionalStations = List<String>.from(profile.additionalStations);
    _district = profile.district;
    _divisionName = profile.divisionName;
    _zone = profile.effectiveZone.isNotEmpty ? profile.effectiveZone : null;
    _accountStatus = profile.accountStatus;
    _status = profile.status;
    _stationCaseViewGranted = profile.stationCaseViewGranted;
    _departmentLogoUrl = profile.departmentLogoUrl;
  }

  void _clearProfileState() {
    _username = '';
    _fullName = '';
    _phone = '';
    _designation = '';
    _stationName = '';
    _overrideStationName = null;
    _stationAddress = '';
    _stationLandline = '';
    _govtId = '';
    _profilePhoto = '';
    _role = 'officer';
    _badgeNumber = '';
    _additionalStations = [];
    _district = null;
    _divisionName = null;
    _zone = null;
    _accountStatus = UserAccountStatus.active;
    _status = '';
    _stationCaseViewGranted = false;
  }

  /// Checks if an account with the given email or phone number already exists in PostgreSQL backend.
  Future<bool> checkContactExists({
    required String email,
    required String phone,
  }) async {
    final sanitizedEmail = email.trim().toLowerCase();
    final sanitizedPhone = phone.replaceAll(RegExp(r'\D'), '');

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.authCheckExists),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': sanitizedEmail,
          'phone': sanitizedPhone,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['exists'] == true;
      }
      return false;
    } catch (e) {
      _secureLog('checkContactExists error: $e');
      return false;
    }
  }

  Future<RegistrationResult> registerWithPin({
    required String fullName,
    required String designation,
    required String email,
    required String phone,
    required String pin,
    XFile? idCardFile,
    XFile? selfieFile,
    String stationName = '',
    String stationAddress = '',
    String stationLandline = '',
    String govtId = '',
    String? district,
    String stateCode = 'MH',
    String roleId = 'officer',
  }) async {
    final sanitizedEmail = email.trim().toLowerCase();
    final sanitizedPhone = phone.trim();
    final sanitizedPin = pin.trim();

    final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.\w+$');
    if (!emailRegex.hasMatch(sanitizedEmail)) {
      return RegistrationResult.invalidEmail();
    }

    try {
      final response = await ApiService().post(
        ApiConfig.authRegister,
        body: {
          'email': sanitizedEmail,
          'password': sanitizedPin,
          'full_name': fullName.trim(),
          'designation': designation.trim(),
          'phone': sanitizedPhone,
          'station_name': stationName.trim(),
          'district': district?.trim() ?? '',
          'badge_number': govtId.trim().isNotEmpty ? govtId.trim() : '',
          'state_code': stateCode.toUpperCase(),
          'role_id': roleId,
        },
      );

      if (!response.isSuccess) {
        return RegistrationResult.failure('backend_error', response.errorMessage ?? 'Registration failed.');
      }

      final data = response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : {};
      final userJson = data['user'] as Map<String, dynamic>? ?? {};
      final authUid = userJson['uid']?.toString() ?? userJson['id']?.toString() ?? '';

      final salt = PinCrypto.generateSalt();
      final pinHash = await PinCrypto.hashPinAsync(sanitizedPin, salt);

      await _secure.write(key: StorageKeys.email, value: sanitizedEmail);
      await _secure.write(key: StorageKeys.pinHash, value: pinHash);
      await _secure.write(key: StorageKeys.pinSalt, value: salt);
      await _secure.write(key: 'user_profile_json', value: json.encode(userJson));

      final accountStatus = data['account_status']?.toString() ?? 'pending_approval';
      if (accountStatus == 'active' && data['tokens'] != null && data['tokens'] is Map) {
        final tokens = data['tokens'] as Map<String, dynamic>;
        final access = (tokens['access_token'] ?? tokens['access'])?.toString();
        final refresh = (tokens['refresh_token'] ?? tokens['refresh'])?.toString();
        if (access != null && access.isNotEmpty) {
          await ApiService().setAuthToken(access);
        }
        if (refresh != null && refresh.isNotEmpty) {
          await _secure.write(key: ApiConstants.jwtRefreshTokenKey, value: refresh);
        }
        _isSessionActive = true;
      } else {
        // Pending approval: Do NOT set tokens or activate session
        await ApiService().setAuthToken('');
        await _secure.delete(key: ApiConstants.jwtRefreshTokenKey);
        _isSessionActive = false;
      }

      final newUser = UserModel.fromMap(userJson);
      _uid = authUid;
      _isRegistered = true;
      _applyProfile(newUser);
      notifyListeners();

      await _audit.log(AuditEvent.registrationSuccess, uid: authUid);
      return RegistrationResult.success(authUid);
    } catch (e, st) {
      _secureLog('registerWithPin unexpected error: $e\n$st');
      return RegistrationResult.unknownError('$e');
    }
  }

  Future<String?> loginWithPin({
    required String email,
    required String pin,
  }) async {
    return loginByEmailAndPin(email: email, pin: pin);
  }

  Future<String?> loginWithBiometrics(String email) async {
    final lockoutStatus = await _lockout.checkStatus();
    if (lockoutStatus.isLocked) {
      return 'Account locked. Try again in ${lockoutStatus.remainingLabel}.';
    }

    final storedHash = (await _secure.read(key: StorageKeys.pinHash) ?? '').trim();
    if (storedHash.isEmpty) {
      return 'No credentials found on device. Please login with PIN.';
    }

    final storedProfileJson = await _secure.read(key: 'user_profile_json');
    if (storedProfileJson != null && storedProfileJson.isNotEmpty) {
      try {
        final userMap = json.decode(storedProfileJson) as Map<String, dynamic>;
        final user = UserModel.fromMap(userMap);
        _uid = user.uid;
        _isRegistered = true;
        _isSessionActive = true;
        _applyProfile(user);
        await fetchDynamicPermissions();
        notifyListeners();
        return null;
      } catch (_) {}
    }
    return 'Session expired. Please login with PIN.';
  }

  Future<String?> loginByEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return loginByEmailAndPin(email: email, pin: password);
  }

  Future<String?> loginByEmailAndPin({
    required String email,
    required String pin,
  }) async {
    final lockoutStatus = await _lockout.checkStatus();
    if (lockoutStatus.isLocked) {
      return 'Account locked. Try again in ${lockoutStatus.remainingLabel}.';
    }

    try {
      final sanitizedEmail = email.trim().toLowerCase();
      final sanitizedPin = pin.trim();

      final response = await http.post(
        Uri.parse(ApiConfig.authLogin),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': sanitizedEmail,
          'password': sanitizedPin,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userJson = data['user'] as Map<String, dynamic>;
        final user = UserModel.fromMap(userJson);

        final salt = PinCrypto.generateSalt();
        final pinHash = await PinCrypto.hashPinAsync(sanitizedPin, salt);
        await _secure.write(key: StorageKeys.email, value: sanitizedEmail);
        await _secure.write(key: StorageKeys.pinHash, value: pinHash);
        await _secure.write(key: StorageKeys.pinSalt, value: salt);
        await _secure.write(key: 'user_profile_json', value: json.encode(userJson));

        // Store JWT authentication tokens for backend API requests
        if (data['tokens'] != null && data['tokens'] is Map) {
          final tokens = data['tokens'] as Map<String, dynamic>;
          final access = (tokens['access_token'] ?? tokens['access'])?.toString();
          final refresh = (tokens['refresh_token'] ?? tokens['refresh'])?.toString();
          if (access != null && access.isNotEmpty) {
            await ApiService().setAuthToken(access);
          }
          if (refresh != null && refresh.isNotEmpty) {
            await _secure.write(key: ApiConstants.jwtRefreshTokenKey, value: refresh);
          }
        }

        await _lockout.recordSuccess();

        _uid = user.uid;
        _isRegistered = true;
        _isSessionActive = true;
        _applyProfile(user);
        await fetchDynamicPermissions();

        notifyListeners();
        return null;
      } else {
        final status = await _lockout.recordFailedAttempt();
        if (status.isLocked) {
          return 'Too many failed attempts. Try again in ${status.remainingLabel}.';
        }
        try {
          final data = json.decode(response.body);
          return data['error'] ?? 'Invalid email or password.';
        } catch (_) {
          return 'Invalid email or password.';
        }
      }
    } catch (e) {
      _secureLog('loginByEmailAndPin error: $e');
      return 'Could not connect to authentication server. Ensure backend is running.';
    }
  }

  Future<String> getStoredGovtEmail() async {
    return (await _secure.read(key: StorageKeys.email) ?? '').trim();
  }

  Future<bool> verifyPin(String pin) async {
    final lockoutStatus = await _lockout.checkStatus();
    if (lockoutStatus.isLocked) return false;

    final storedHash = (await _secure.read(key: StorageKeys.pinHash) ?? '').trim();
    final storedSalt = (await _secure.read(key: StorageKeys.pinSalt) ?? '').trim();

    if (storedHash.isEmpty || storedSalt.isEmpty) {
      _secureLog('verifyPin: no stored hash/salt found');
      return false;
    }

    // Try first with optimized 1,000 iterations
    var isValid = await PinCrypto.verifyPinAsync(pin.trim(), storedHash, storedSalt, 1000);

    // Fallback to legacy 100,000 iterations
    if (!isValid) {
      isValid = await PinCrypto.verifyPinAsync(pin.trim(), storedHash, storedSalt, 100000);
      if (isValid) {
        final newSalt = PinCrypto.generateSalt();
        final newHash = await PinCrypto.hashPinAsync(pin.trim(), newSalt);
        await _secure.write(key: StorageKeys.pinHash, value: newHash);
        await _secure.write(key: StorageKeys.pinSalt, value: newSalt);
        _secureLog('verifyPin: migrated hash from 100,000 to 1,000 iterations successfully');
      }
    }

    if (isValid) {
      await _lockout.recordSuccess();
      _isSessionActive = true;
      notifyListeners();
      await _audit.log(AuditEvent.pinVerifySuccess, uid: _uid);
      return true;
    } else {
      final status = await _lockout.recordFailedAttempt();
      await _audit.log(AuditEvent.pinVerifyFailed, uid: _uid);
      if (status.isLocked) {
        await _audit.log(AuditEvent.lockoutTriggered, uid: _uid);
      }
      return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    final response = await ApiService().changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );

    if (response.isSuccess) {
      final newSalt = PinCrypto.generateSalt();
      final newHash = await PinCrypto.hashPinAsync(newPassword.trim(), newSalt);
      await _secure.write(key: StorageKeys.pinHash, value: newHash);
      await _secure.write(key: StorageKeys.pinSalt, value: newSalt);
      await _audit.log(AuditEvent.pinChanged, uid: _uid);
      return true;
    }

    return false;
  }

  Future<bool> changePin(String oldPin, String newPin) async {
    final storedHash = await _secure.read(key: StorageKeys.pinHash) ?? '';
    final storedSalt = await _secure.read(key: StorageKeys.pinSalt) ?? '';

    var isOldPinValid = await PinCrypto.verifyPinAsync(
      oldPin.trim(), storedHash, storedSalt, 1000,
    );
    if (!isOldPinValid) {
      isOldPinValid = await PinCrypto.verifyPinAsync(
        oldPin.trim(), storedHash, storedSalt, 100000,
      );
    }
    if (!isOldPinValid) {
      await _audit.log(AuditEvent.pinChangeFailed, uid: _uid);
      return false;
    }

    final newSalt = PinCrypto.generateSalt();
    final newHash = await PinCrypto.hashPinAsync(newPin.trim(), newSalt);

    await _secure.write(key: StorageKeys.pinHash, value: newHash);
    await _secure.write(key: StorageKeys.pinSalt, value: newSalt);

    await _audit.log(AuditEvent.pinChanged, uid: _uid);
    return true;
  }

  Future<void> resetPin(String newPin) async {
    final newSalt = PinCrypto.generateSalt();
    final newHash = await PinCrypto.hashPinAsync(newPin.trim(), newSalt);
    await _secure.write(key: StorageKeys.pinHash, value: newHash);
    await _secure.write(key: StorageKeys.pinSalt, value: newSalt);
    await _secure.delete(key: StorageKeys.pin);
    await _audit.log(AuditEvent.pinChanged, uid: _uid);
  }

  void setSessionActive() {
    _isSessionActive = true;
    notifyListeners();
  }

  Future<void> signOutToLogin() async {
    await ApiService().clearAuthToken();
    _isSessionActive = false;
    _isRegistered = true;
    notifyListeners();
  }

  void lockApp() {
    _isSessionActive = false;
    notifyListeners();
    _audit.log(AuditEvent.sessionLocked, uid: _uid);
  }

  Future<void> fullLogout() async {
    final savedEmail = await _secure.read(key: StorageKeys.email);
    final savedHash = await _secure.read(key: StorageKeys.pinHash);
    final savedSalt = await _secure.read(key: StorageKeys.pinSalt);

    await ApiService().clearAuthToken();
    await _secure.deleteAll();

    if (savedEmail != null) await _secure.write(key: StorageKeys.email, value: savedEmail);
    if (savedHash != null)  await _secure.write(key: StorageKeys.pinHash, value: savedHash);
    if (savedSalt != null)  await _secure.write(key: StorageKeys.pinSalt, value: savedSalt);

    await _lockout.resetAll();

    _clearProfileState();
    _uid = '';
    _isSessionActive = false;
    _isRegistered = true;

    notifyListeners();
    await _audit.log(AuditEvent.fullLogout);
  }

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? designation,
    String? stationName,
    String? stationAddress,
    String? stationLandline,
    String? profilePhoto,
  }) async {
    if (fullName != null)        _fullName = fullName;
    if (phone != null)           _phone = phone;
    if (designation != null)     _designation = designation;
    if (stationName != null)     _stationName = stationName;
    if (stationAddress != null)  _stationAddress = stationAddress;
    if (stationLandline != null) _stationLandline = stationLandline;
    if (profilePhoto != null)    _profilePhoto = profilePhoto;

    final user = UserModel(
      uid: _uid,
      name: _fullName,
      badgeNumber: _badgeNumber,
      designation: _designation,
      email: _email,
      phone: _phone,
      stationName: _stationName,
      stationAddress: _stationAddress,
      stationLandline: _stationLandline,
      govtId: _govtId,
      photoUrl: _profilePhoto,
      idCardUrl: null,
      role: _role,
      additionalStations: _additionalStations,
      district: _district,
      accountStatus: _accountStatus,
    );
    await _secure.write(key: 'user_profile_json', value: json.encode(user.toMap()));

    notifyListeners();
  }

  Future<void> refreshProfileFromFirestore() async {
    try {
      final storedProfileJson = await _secure.read(key: 'user_profile_json');
      if (storedProfileJson != null && storedProfileJson.isNotEmpty) {
        final userMap = json.decode(storedProfileJson) as Map<String, dynamic>;
        final profile = UserModel.fromMap(userMap);
        _applyProfile(profile);
        notifyListeners();
      }
    } catch (e) {
      _secureLog('refreshProfile failed: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    final result = await loginWithPin(email: email, pin: password);
    return result == null;
  }

  Future<LockoutStatus> getLockoutStatus() => _lockout.checkStatus();

  Future<void> logout() async {
    _isSessionActive = false;
    await ApiService().clearAuthToken();
    await _secure.delete(key: ApiConstants.jwtAccessTokenKey);
    await _secure.delete(key: ApiConstants.jwtRefreshTokenKey);
    _clearProfileState();
    notifyListeners();
  }

  void onUserInteraction() {
    // Used by main.dart for inactivity timer.
  }
}