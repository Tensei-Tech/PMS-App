// lib/utils/ad_firestore_payload.dart

import 'package:intl/intl.dart';
import '../modules/core/models/base_record.dart';

class AdFirestorePayload {
  AdFirestorePayload._();

  static String adNoFromRecord(ModuleRecord r) {
    final n = r.caseNumber.trim();
    if (n.isNotEmpty) return n;
    return (r.extraFields['adNo']?.toString() ?? '').trim();
  }

  static bool _empty(dynamic v) =>
      v == null || v.toString().trim().isEmpty;

  /// Fills missing/empty form fields from the case hub record (same rules as detail screen).
  static Map<String, dynamic> mergeHubIntoForm(
    Map<String, dynamic> form,
    ModuleRecord hub,
  ) {
    final m = Map<String, dynamic>.from(form);
    final adNo = adNoFromRecord(hub);
    if (_empty(m['adNo']) && adNo.isNotEmpty) {
      m['adNo'] = adNo;
    }
    if (_empty(m['compName'])) {
      m['compName'] = hub.complainant;
    }
    if (_empty(m['spotAddress'])) {
      m['spotAddress'] = hub.location;
    }
    if (_empty(m['regDate'])) {
      m['regDate'] = DateFormat('dd/MM/yyyy').format(hub.incidentDate);
    }
    if (_empty(m['ioName'])) {
      m['ioName'] = hub.assignedOfficer;
    }
    return m;
  }

  static Future<Map<String, dynamic>> loadFormMapByAdNo(String adNo) async {
    final r = await loadFormWithSource(adNo);
    return r.data;
  }

  static Future<({Map<String, dynamic> data, AdFirestoreFormSource source})>
      loadFormWithSource(String adNo) async {
    return (data: <String, dynamic>{}, source: AdFirestoreFormSource.none);
  }
}

enum AdFirestoreFormSource { submitted, draft, none }
