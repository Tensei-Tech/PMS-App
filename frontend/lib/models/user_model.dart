// lib/models/user_model.dart
// Domain 1 (PIN Hardening): removed plaintext `pin` field.
// Domain 3 (RBAC): added `role` field — defaults to 'officer'.
// PIN hash/salt are NEVER stored in UserModel; they live only in flutter_secure_storage.

/// Lifecycle states for officer accounts.
class UserAccountStatus {
  UserAccountStatus._();

  static const String active = 'active';
  static const String archived = 'archived';
  static const String pendingApproval = 'pending_approval';
  static const String pending = 'pending';
  static const String rejected = 'rejected';
}

class UserModel {
  final String uid;
  final String name;
  final String badgeNumber;
  final String designation;
  final String email;
  final String phone;
  final String stationName;
  final String stationAddress;
  final String stationLandline;
  final String govtId;
  final String photoUrl;
  final String? idCardUrl;
  final String role; // 'officer' | 'supervisor' | 'admin' — set by admin only
  final String stateCode; // 'MH', 'GJ', 'KA', etc.
  final List<String>
      additionalStations; // Extra stations added by CP-level officers
  /// `active` (default) | `archived` | `pending_approval` | `rejected`
  final String accountStatus;

  /// Operational status written by admin console (e.g. `inactive`, `rejected`).
  final String status;

  /// District / commissionerate name (structured; backfilled from stationAddress).
  final String? district;

  /// Division name (e.g. Amravati Division)
  final String? divisionName;

  /// Jurisdiction zone for hierarchy-scoped approvals (defaults to [district]).
  final String? zone;

  /// When true, junior ranks may view full station case dashboard (PI/API grant).
  final bool stationCaseViewGranted;
  final int? age;
  final String? gender;
  final String? departmentLogoUrl;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.badgeNumber,
    required this.designation,
    required this.email,
    required this.phone,
    required this.stationName,
    required this.stationAddress,
    required this.stationLandline,
    required this.govtId,
    this.photoUrl = '',
    this.idCardUrl,
    this.role = 'officer', // Default: least-privilege on registration
    this.stateCode = 'MH',
    this.additionalStations = const [],
    this.accountStatus = UserAccountStatus.active,
    this.status = '',
    this.district,
    this.divisionName,
    this.zone,
    this.stationCaseViewGranted = false,
    this.age,
    this.gender,
    this.departmentLogoUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'badgeNumber': badgeNumber,
      'designation': designation,
      'email': email,
      'phone': phone,
      'stationName': stationName,
      'stationAddress': stationAddress,
      'stationLandline': stationLandline,
      'govtId': govtId,
      'photoUrl': photoUrl,
      if (idCardUrl != null && idCardUrl!.trim().isNotEmpty)
        'idCardUrl': idCardUrl,
      'role': role,
      'stateCode': stateCode,
      'additionalStations': additionalStations,
      'district': district ?? '',
      'divisionName': divisionName ?? '',
      if ((zone ?? district ?? '').trim().isNotEmpty)
        'zone': (zone ?? district ?? '').trim(),
      if (accountStatus != UserAccountStatus.active)
        'accountStatus': accountStatus,
      if (stationCaseViewGranted) 'stationCaseViewGranted': true,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      if (departmentLogoUrl != null) 'departmentLogoUrl': departmentLogoUrl,
      // NOTE: PIN hash/salt are NEVER written to Firestore via this model.
      // They are managed exclusively in flutter_secure_storage by AuthProvider.
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return UserModel(
      uid: docId ?? map['uid'] ?? map['id'] ?? '',
      name: map['name'] ?? map['full_name'] ?? '',
      badgeNumber: map['badgeNumber'] ?? map['badge_number'] ?? '',
      designation: map['designation'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      stationName: map['stationName'] ?? map['station_name'] ?? '',
      stationAddress: map['stationAddress'] ?? map['station_address'] ?? '',
      stationLandline: map['stationLandline'] ?? map['station_landline'] ?? '',
      govtId: map['govtId'] ?? map['govt_id'] ?? '',
      photoUrl: (map['photoUrl'] ?? map['photo_url']) as String? ?? '',
      idCardUrl: (map['idCardUrl'] ?? map['id_card_url']) as String?,
      role: map['role'] ?? map['role_id'] ?? 'officer',
      stateCode: map['stateCode'] ?? map['state_code'] ?? 'MH',
      additionalStations: (map['additionalStations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      accountStatus: map['accountStatus'] as String? ??
          map['account_status'] as String? ??
          map['status'] as String? ??
          UserAccountStatus.active,
      status: map['status'] as String? ?? '',
      district: map['district'] as String?,
      divisionName:
          map['divisionName'] as String? ?? map['division_name'] as String?,
      zone: map['zone'] as String? ?? map['district'] as String?,
      stationCaseViewGranted: map['stationCaseViewGranted'] == true ||
          map['station_case_view_granted'] == true,
      age: map['age'] is int
          ? map['age'] as int
          : int.tryParse(map['age']?.toString() ?? ''),
      gender: map['gender'] as String?,
      departmentLogoUrl: (map['departmentLogoUrl'] ??
          map['department_logo_url'] ??
          map['state_logo_url']) as String?,
      createdAt:
          DateTime.tryParse(map['createdAt'] ?? map['created_at'] ?? '') ??
              DateTime.now(),
    );
  }

  /// Zone used for jurisdiction filters; falls back to district.
  String get effectiveZone {
    final z = zone?.trim() ?? '';
    if (z.isNotEmpty) return z;
    return district?.trim() ?? '';
  }
}
