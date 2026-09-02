/// Police Hierarchy & Role Access Helper based on Official Government Platform Matrix Standards.
///
/// Official Designations & Administrative Matrix Mapping Rules:
///
/// | Designation | Meaning                                                              | STATE ADMIN | DISTRICT ADMIN | DIVISION ADMIN | STATION ADMIN |
/// |-------------|----------------------------------------------------------------------|-------------|----------------|----------------|---------------|
/// | DG          | Director General of Police — head of state police force.             | MUST        | NEVER          | NEVER          | NEVER         |
/// | ADG         | Additional Director General — senior state-level police officer.     | MUST        | OPTIONAL       | NEVER          | NEVER         |
/// | IG          | Inspector General — senior officer for range/zone or major branch.   | MUST        | OPTIONAL       | NEVER          | NEVER         |
/// | DIG         | Deputy Inspector General — senior officer for range/major unit.      | MUST        | OPTIONAL       | OPTIONAL       | NEVER         |
/// | CP          | Commissioner of Police — head of police commissionerate.             | OPTIONAL    | MUST           | OPTIONAL       | NEVER         |
/// | SP          | Superintendent of Police — district police chief.                    | OPTIONAL    | MUST           | OPTIONAL       | NEVER         |
/// | SSP         | Senior Superintendent of Police — senior district police chief.      | OPTIONAL    | MUST           | OPTIONAL       | NEVER         |
/// | Add.SP      | Additional Superintendent of Police — assists SP / manages division. | OPTIONAL    | OPTIONAL       | MUST           | NEVER         |
/// | Add.CP      | Additional Commissioner of Police — senior commissionerate under CP. | OPTIONAL    | OPTIONAL       | MUST           | NEVER         |
/// | DCP         | Deputy Commissioner of Police — zone/division officer.               | OPTIONAL    | MUST           | MUST           | NEVER         |
/// | ACP         | Assistant Commissioner of Police — supervises subdivision/circle.    | NEVER       | OPTIONAL       | MUST           | NEVER         |
/// | DySP        | Deputy Superintendent of Police — supervises subdivision/circle.     | NEVER       | OPTIONAL       | MUST           | NEVER         |
/// | SDPO        | Sub-Divisional Police Officer — subdivision head (DySP/ACP level).   | NEVER       | OPTIONAL       | MUST           | NEVER         |
/// | PI/SHO/TI   | Police Inspector — station in-charge or unit officer.                | NEVER       | OPTIONAL       | OPTIONAL       | MUST          |
/// | API         | Assistant Police Inspector — assists station/unit operations.        | NEVER       | NEVER          | OPTIONAL       | MUST          |
/// | PSI/SI      | Police Sub-Inspector — field/investigation / station in-charge.      | NEVER       | NEVER          | OPTIONAL       | MUST          |
///
/// Rule Definitions:
/// - MUST: Normally suitable as the primary designation for that admin level.
/// - OPTIONAL: Can be allowed when officer's posting/responsibility supports it.
/// - NEVER: Should not normally receive that level of administrative role.
library;

enum AdminLevelRule { must, optional, never }

enum AdminLevel { stateAdmin, districtAdmin, divisionAdmin, stationAdmin }

class PoliceHierarchyHelper {
  PoliceHierarchyHelper._();

  /// Normalized Designation Keys
  static const String keyDG = 'DG';
  static const String keyADG = 'ADG';
  static const String keyIG = 'IG';
  static const String keyDIG = 'DIG';
  static const String keyCP = 'CP';
  static const String keySP = 'SP';
  static const String keySSP = 'SSP';
  static const String keyAddSP = 'ADD.SP';
  static const String keyAddCP = 'ADD.CP';
  static const String keyDCP = 'DCP';
  static const String keyACP = 'ACP';
  static const String keyDySP = 'DYSP';
  static const String keySDPO = 'SDPO';
  static const String keyPI = 'PI';
  static const String keyAPI = 'API';
  static const String keyPSI = 'PSI';

  /// Complete Matrix Mapping Table: [Normalized Designation] -> Map<AdminLevel, AdminLevelRule>
  static const Map<String, Map<AdminLevel, AdminLevelRule>> matrix = {
    'DG': {
      AdminLevel.stateAdmin: AdminLevelRule.must,
      AdminLevel.districtAdmin: AdminLevelRule.never,
      AdminLevel.divisionAdmin: AdminLevelRule.never,
      AdminLevel.stationAdmin: AdminLevelRule.never,
    },
    'ADG': {
      AdminLevel.stateAdmin: AdminLevelRule.must,
      AdminLevel.districtAdmin: AdminLevelRule.optional,
      AdminLevel.divisionAdmin: AdminLevelRule.never,
      AdminLevel.stationAdmin: AdminLevelRule.never,
    },
    'IG': {
      AdminLevel.stateAdmin: AdminLevelRule.must,
      AdminLevel.districtAdmin: AdminLevelRule.optional,
      AdminLevel.divisionAdmin: AdminLevelRule.never,
      AdminLevel.stationAdmin: AdminLevelRule.never,
    },
    'DIG': {
      AdminLevel.stateAdmin: AdminLevelRule.must,
      AdminLevel.districtAdmin: AdminLevelRule.optional,
      AdminLevel.divisionAdmin: AdminLevelRule.optional,
      AdminLevel.stationAdmin: AdminLevelRule.never,
    },
    'CP': {
      AdminLevel.stateAdmin: AdminLevelRule.optional,
      AdminLevel.districtAdmin: AdminLevelRule.must,
      AdminLevel.divisionAdmin: AdminLevelRule.optional,
      AdminLevel.stationAdmin: AdminLevelRule.never,
    },
    'SP': {
      AdminLevel.stateAdmin: AdminLevelRule.optional,
      AdminLevel.districtAdmin: AdminLevelRule.must,
      AdminLevel.divisionAdmin: AdminLevelRule.optional,
      AdminLevel.stationAdmin: AdminLevelRule.never,
    },
    'SSP': {
      AdminLevel.stateAdmin: AdminLevelRule.optional,
      AdminLevel.districtAdmin: AdminLevelRule.must,
      AdminLevel.divisionAdmin: AdminLevelRule.optional,
      AdminLevel.stationAdmin: AdminLevelRule.never,
    },
    'ADD.SP': {
      AdminLevel.stateAdmin: AdminLevelRule.optional,
      AdminLevel.districtAdmin: AdminLevelRule.optional,
      AdminLevel.divisionAdmin: AdminLevelRule.must,
      AdminLevel.stationAdmin: AdminLevelRule.never,
    },
    'ADD.CP': {
      AdminLevel.stateAdmin: AdminLevelRule.optional,
      AdminLevel.districtAdmin: AdminLevelRule.optional,
      AdminLevel.divisionAdmin: AdminLevelRule.must,
      AdminLevel.stationAdmin: AdminLevelRule.never,
    },
    'DCP': {
      AdminLevel.stateAdmin: AdminLevelRule.optional,
      AdminLevel.districtAdmin: AdminLevelRule.must,
      AdminLevel.divisionAdmin: AdminLevelRule.must,
      AdminLevel.stationAdmin: AdminLevelRule.never,
    },
    'ACP': {
      AdminLevel.stateAdmin: AdminLevelRule.never,
      AdminLevel.districtAdmin: AdminLevelRule.optional,
      AdminLevel.divisionAdmin: AdminLevelRule.must,
      AdminLevel.stationAdmin: AdminLevelRule.never,
    },
    'DYSP': {
      AdminLevel.stateAdmin: AdminLevelRule.never,
      AdminLevel.districtAdmin: AdminLevelRule.optional,
      AdminLevel.divisionAdmin: AdminLevelRule.must,
      AdminLevel.stationAdmin: AdminLevelRule.never,
    },
    'SDPO': {
      AdminLevel.stateAdmin: AdminLevelRule.never,
      AdminLevel.districtAdmin: AdminLevelRule.optional,
      AdminLevel.divisionAdmin: AdminLevelRule.must,
      AdminLevel.stationAdmin: AdminLevelRule.never,
    },
    'PI': {
      AdminLevel.stateAdmin: AdminLevelRule.never,
      AdminLevel.districtAdmin: AdminLevelRule.optional,
      AdminLevel.divisionAdmin: AdminLevelRule.optional,
      AdminLevel.stationAdmin: AdminLevelRule.must,
    },
    'API': {
      AdminLevel.stateAdmin: AdminLevelRule.never,
      AdminLevel.districtAdmin: AdminLevelRule.never,
      AdminLevel.divisionAdmin: AdminLevelRule.optional,
      AdminLevel.stationAdmin: AdminLevelRule.must,
    },
    'PSI': {
      AdminLevel.stateAdmin: AdminLevelRule.never,
      AdminLevel.districtAdmin: AdminLevelRule.never,
      AdminLevel.divisionAdmin: AdminLevelRule.optional,
      AdminLevel.stationAdmin: AdminLevelRule.must,
    },
  };

  /// Normalizes designation string to canonical code
  static String normalizeDesignation(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'PI';
    final d = raw.trim().toUpperCase();

    if (d == 'DG' || d == 'DGP' || d.contains('DIRECTOR GENERAL')) return 'DG';
    if (d == 'ADG' || d == 'ADGP' || d.contains('ADDITIONAL DIRECTOR GENERAL')) {
      return 'ADG';
    }
    if (d == 'IG' || d == 'IGP' || d.contains('INSPECTOR GENERAL')) return 'IG';
    if (d == 'DIG' || d.contains('DEPUTY INSPECTOR GENERAL')) return 'DIG';

    if (d == 'CP' || d.contains('COMMISSIONER OF POLICE')) return 'CP';
    if (d == 'SSP' || d.contains('SENIOR SUPERINTENDENT')) return 'SSP';
    if (d == 'SP' || d.contains('SUPERINTENDENT OF POLICE')) return 'SP';

    if (d == 'ADD.SP' ||
        d == 'ADDL. SP' ||
        d == 'ADDL SP' ||
        d.contains('ADDITIONAL SUPERINTENDENT')) {
      return 'ADD.SP';
    }
    if (d == 'ADD.CP' ||
        d == 'ADDL. CP' ||
        d == 'ADDL CP' ||
        d.contains('ADDITIONAL COMMISSIONER')) {
      return 'ADD.CP';
    }

    if (d == 'DCP' || d.contains('DEPUTY COMMISSIONER')) return 'DCP';
    if (d == 'ACP' || d.contains('ASSISTANT COMMISSIONER')) return 'ACP';
    if (d == 'DYSP' ||
        d == 'DY. SP' ||
        d == 'DY SP' ||
        d.contains('DEPUTY SUPERINTENDENT')) {
      return 'DYSP';
    }
    if (d == 'SDPO' ||
        d.contains('SUB-DIVISIONAL') ||
        d.contains('SUB DIVISIONAL')) {
      return 'SDPO';
    }

    if (d == 'API' || d.contains('ASSISTANT POLICE INSPECTOR')) return 'API';
    if (d == 'PSI' ||
        d == 'SI' ||
        d.contains('SUB INSPECTOR') ||
        d.contains('SUB-INSPECTOR')) {
      return 'PSI';
    }

    return 'PI'; // Default fallback for PI / SHO / TI
  }

  /// Convert string admin level to enum
  static AdminLevel? parseAdminLevel(String? levelStr) {
    if (levelStr == null) return null;
    final l = levelStr.trim().toLowerCase();
    if (l.contains('state')) return AdminLevel.stateAdmin;
    if (l.contains('district')) return AdminLevel.districtAdmin;
    if (l.contains('division') ||
        l.contains('subdivision') ||
        l.contains('zone')) {
      return AdminLevel.divisionAdmin;
    }
    if (l.contains('station') || l.contains('head') || l.contains('sho')) {
      return AdminLevel.stationAdmin;
    }
    return null;
  }

  /// Get Matrix Rule (MUST, OPTIONAL, NEVER) for a given designation and admin level
  static AdminLevelRule getRule(String designation, AdminLevel level) {
    final code = normalizeDesignation(designation);
    final row = matrix[code];
    if (row != null && row.containsKey(level)) {
      return row[level]!;
    }
    return AdminLevelRule.optional;
  }

  /// Check if designation is allowed for admin level (MUST or OPTIONAL)
  static bool isRoleAllowed(String designation, AdminLevel level) {
    final rule = getRule(designation, level);
    return rule == AdminLevelRule.must || rule == AdminLevelRule.optional;
  }

  /// Returns list of MUST designations for specified AdminLevel
  static List<String> getMustDesignations(AdminLevel level) {
    return matrix.entries
        .where((e) => e.value[level] == AdminLevelRule.must)
        .map((e) => e.key)
        .toList();
  }

  /// Returns list of OPTIONAL designations for specified AdminLevel
  static List<String> getOptionalDesignations(AdminLevel level) {
    return matrix.entries
        .where((e) => e.value[level] == AdminLevelRule.optional)
        .map((e) => e.key)
        .toList();
  }

  /// Returns list of ALLOWED (MUST + OPTIONAL) designations for specified AdminLevel
  static List<String> getAllowedDesignations(AdminLevel level) {
    return matrix.entries
        .where((e) => e.value[level] != AdminLevelRule.never)
        .map((e) => e.key)
        .toList();
  }

  /// Check if user is State Super Admin
  static bool isStateSuperAdmin(String? designation, String? roleId) {
    final r = (roleId ?? '').trim().toUpperCase();
    if (r == 'MASTER_ADMIN' || r == 'SUPER_ADMIN' || r == 'STATE_SUPER_ADMIN') {
      return true;
    }
    final level = parseAdminLevel(roleId);
    if (level == AdminLevel.stateAdmin) return true;
    return isRoleAllowed(designation ?? '', AdminLevel.stateAdmin);
  }

  /// Check if user is District Admin
  static bool isDistrictAdmin(String? designation, String? roleId) {
    final r = (roleId ?? '').trim().toUpperCase();
    if (r == 'DISTRICT_ADMIN' || r == 'DISTRICT_HEAD') return true;
    final level = parseAdminLevel(roleId);
    if (level == AdminLevel.districtAdmin) return true;
    return isRoleAllowed(designation ?? '', AdminLevel.districtAdmin);
  }

  /// Check if user is Division Admin
  static bool isDivisionAdmin(String? designation, String? roleId) {
    final r = (roleId ?? '').trim().toUpperCase();
    if (r == 'DIVISION_ADMIN' || r == 'SUBDIVISION_HEAD') return true;
    final level = parseAdminLevel(roleId);
    if (level == AdminLevel.divisionAdmin) return true;
    return isRoleAllowed(designation ?? '', AdminLevel.divisionAdmin);
  }

  /// Check if user is Station Head / Admin
  static bool isStationHead(String? designation, String? roleId) {
    final r = (roleId ?? '').trim().toUpperCase();
    if (r == 'STATION_HEAD' || r == 'STATION_ADMIN' || r == 'SHO') return true;
    final level = parseAdminLevel(roleId);
    if (level == AdminLevel.stationAdmin) return true;
    return isRoleAllowed(designation ?? '', AdminLevel.stationAdmin);
  }

  /// Role badge title
  static String getRoleBadgeTitle(String? designation, String? roleId) {
    if (isStateSuperAdmin(designation, roleId)) return 'STATE SUPER ADMIN';
    if (isDistrictAdmin(designation, roleId)) return 'DISTRICT ADMIN';
    if (isDivisionAdmin(designation, roleId)) return 'DIVISION ADMIN';
    if (isStationHead(designation, roleId)) return 'STATION HEAD';
    return 'FIELD OFFICER (IO)';
  }

  static bool canCreateDistrictAdmin(String? designation, String? roleId) {
    return isStateSuperAdmin(designation, roleId);
  }

  static bool canCreateDivisionAdmin(String? designation, String? roleId) {
    return isStateSuperAdmin(designation, roleId) ||
        isDistrictAdmin(designation, roleId);
  }

  static bool canSendAlerts(String? designation, String? roleId) {
    return isStateSuperAdmin(designation, roleId) ||
        isDistrictAdmin(designation, roleId) ||
        isDivisionAdmin(designation, roleId) ||
        isStationHead(designation, roleId);
  }

  static bool canSendReminders(String? designation, String? roleId) {
    return isStateSuperAdmin(designation, roleId) ||
        isDistrictAdmin(designation, roleId) ||
        isDivisionAdmin(designation, roleId) ||
        isStationHead(designation, roleId);
  }

  /// Check if user has administrative authority to approve officer registrations
  static bool hasAdminAuthority(String? designation, String? roleId) {
    return isStateSuperAdmin(designation, roleId) ||
        isDivisionAdmin(designation, roleId) ||
        isDistrictAdmin(designation, roleId) ||
        isStationHead(designation, roleId);
  }

  static bool canViewOfficerApprovals(String? designation, String? roleId) {
    return hasAdminAuthority(designation, roleId);
  }
}
