/// Police Hierarchy & Role Access Helper based on Government Platform Standards.
///
/// Matrix Definition:
/// 1. State Super Admin: DG, ADG, IG, DIG, SI, SDPO, Add.SP, PI (State Scope)
///    -> Create District Admin, Division Admin, Station Head
///    -> Send Reminders, View all State Data, Send Alert
/// 2. District Admin: CP, Add.CP, DCP, ACP, SP, Add.SP (District Scope)
///    -> Create Division Admin, Station Head
///    -> View District Data, Send Alert, Send Reminders
/// 3. Division Admin (City/Sub-Div): DySP, ACP, SDPO, ASP
///    -> See District & Station Data, Switch station within district, Select multiple stations
/// 4. Station Head: PSI, API, PI, ASP
///    -> Edit station cases, View station data, Send Reminder to IO
/// 5. Officer (Field IO): All ranks
///    -> Edit own case, View station cases
class PoliceHierarchyHelper {
  PoliceHierarchyHelper._();

  static const List<String> stateSuperAdminRanks = [
    'DG', 'DGP', 'DIRECTOR GENERAL OF POLICE',
    'ADG', 'ADGP', 'ADDITIONAL DIRECTOR GENERAL OF POLICE',
    'IG', 'IGP', 'INSPECTOR GENERAL OF POLICE',
    'DIG', 'DEPUTY INSPECTOR GENERAL OF POLICE',
    'STATE SUPER ADMIN', 'SUPER ADMIN'
  ];

  static const List<String> districtAdminRanks = [
    'CP', 'COMMISSIONER OF POLICE',
    'JT. CP', 'JOINT COMMISSIONER OF POLICE',
    'ADDL. CP', 'ADDITIONAL COMMISSIONER OF POLICE',
    'DCP', 'DEPUTY COMMISSIONER OF POLICE',
    'SP', 'SUPERINTENDENT OF POLICE',
    'ADDL. SP', 'ADDITIONAL SUPERINTENDENT OF POLICE',
    'DISTRICT ADMIN'
  ];

  static const List<String> divisionAdminRanks = [
    'DYSP', 'DY. SP', 'DEPUTY SUPERINTENDENT OF POLICE',
    'ACP', 'ASSISTANT COMMISSIONER OF POLICE',
    'SDPO', 'SUB DIVISIONAL POLICE OFFICER',
    'ASP', 'ASSISTANT SUPERINTENDENT OF POLICE',
    'DIVISION ADMIN'
  ];

  static const List<String> stationHeadRanks = [
    'PI', 'POLICE INSPECTOR',
    'SR. PI', 'SENIOR POLICE INSPECTOR',
    'API', 'ASSISTANT POLICE INSPECTOR',
    'PSI', 'POLICE SUB INSPECTOR',
    'STATION HEAD'
  ];

  /// Normalizes designation string for comparison
  static String _norm(String? value) => (value ?? '').trim().toUpperCase();

  /// Check if user is State Super Admin
  static bool isStateSuperAdmin(String? designation, String? roleId) {
    final r = _norm(roleId);
    if (r == 'MASTER_ADMIN' || r == 'SUPER_ADMIN' || r == 'STATE_SUPER_ADMIN') return true;
    final d = _norm(designation);
    return stateSuperAdminRanks.any((rank) => d.contains(rank));
  }

  /// Check if user is District Admin
  static bool isDistrictAdmin(String? designation, String? roleId) {
    if (isStateSuperAdmin(designation, roleId)) return false;
    final r = _norm(roleId);
    if (r == 'DISTRICT_ADMIN' || r == 'DISTRICT_HEAD') return true;
    final d = _norm(designation);
    return districtAdminRanks.any((rank) => d.contains(rank));
  }

  /// Check if user is Division Admin
  static bool isDivisionAdmin(String? designation, String? roleId) {
    final r = _norm(roleId);
    if (r == 'DIVISION_ADMIN' || r == 'SUBDIVISION_HEAD') return true;
    final d = _norm(designation);
    return divisionAdminRanks.any((rank) => d.contains(rank));
  }

  /// Check if user is Station Head
  static bool isStationHead(String? designation, String? roleId) {
    final r = _norm(roleId);
    if (r == 'STATION_HEAD' || r == 'PI' || r == 'SHO') return true;
    final d = _norm(designation);
    return stationHeadRanks.any((rank) => d.contains(rank));
  }

  // ── PERMISSIONS MATRIX CHECKS ──

  /// State Super Admin can create District Admin, Division Admin & Station Head
  static bool canCreateDistrictAdmin(String? designation, String? roleId) {
    return isStateSuperAdmin(designation, roleId);
  }

  /// State Super Admin & District Admin can create Division Admin
  static bool canCreateDivisionAdmin(String? designation, String? roleId) {
    return isStateSuperAdmin(designation, roleId) || isDistrictAdmin(designation, roleId);
  }

  /// State Super Admin & District Admin can create Station Head
  static bool canCreateStationHead(String? designation, String? roleId) {
    return isStateSuperAdmin(designation, roleId) || isDistrictAdmin(designation, roleId);
  }

  /// State Super Admin & District Admin can send State/District Alerts
  static bool canSendAlerts(String? designation, String? roleId) {
    return isStateSuperAdmin(designation, roleId) || isDistrictAdmin(designation, roleId);
  }

  /// State Super Admin, District Admin & Station Head can send Reminders
  static bool canSendReminders(String? designation, String? roleId) {
    return isStateSuperAdmin(designation, roleId) ||
        isDistrictAdmin(designation, roleId) ||
        isStationHead(designation, roleId);
  }

  /// User scope badge title
  static String getRoleBadgeTitle(String? designation, String? roleId) {
    if (isStateSuperAdmin(designation, roleId)) return 'STATE SUPER ADMIN';
    if (isDistrictAdmin(designation, roleId)) return 'DISTRICT ADMIN';
    if (isDivisionAdmin(designation, roleId)) return 'DIVISION ADMIN';
    if (isStationHead(designation, roleId)) return 'STATION HEAD';
    return 'FIELD OFFICER (IO)';
  }
}
