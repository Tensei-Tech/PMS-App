// lib/modules/passport/providers/passport_provider.dart
import '../../core/models/base_record.dart';
import '../../core/providers/base_module_provider.dart';

class PassportProvider extends BaseModuleProvider {
  static const String statusPending = 'Pending';
  static const String statusVerified = 'Verified / Report Submitted';
  static const String statusPartial = 'Partially Verified';

  PassportProvider() : super('passport');

  static bool isVerifiedRecord(ModuleRecord r) {
    if (r.extraFields.containsKey('verified_count')) {
      final v = int.tryParse(r.extraFields['verified_count'].toString()) ?? 0;
      return v > 0;
    }
    final s = r.status.trim().toLowerCase();
    final vs = (r.extraFields['verification_status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    return s == statusVerified.toLowerCase() ||
        s == statusPartial.toLowerCase() ||
        vs == statusVerified.toLowerCase() ||
        vs == statusPartial.toLowerCase() ||
        s.contains('verified') ||
        s.contains('submitted') ||
        vs.contains('verified') ||
        vs.contains('submitted');
  }

  static bool isPendingRecord(ModuleRecord r) {
    if (r.extraFields.containsKey('pending_count')) {
      final p = int.tryParse(r.extraFields['pending_count'].toString()) ?? 0;
      return p > 0;
    }
    final s = r.status.trim().toLowerCase();
    final vs = (r.extraFields['verification_status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    return s == statusPending.toLowerCase() ||
        s == statusPartial.toLowerCase() ||
        vs == statusPending.toLowerCase() ||
        vs == statusPartial.toLowerCase() ||
        s.contains('pending') ||
        vs.contains('pending');
  }

  static int getRecordVerifiedCount(ModuleRecord r) {
    if (r.extraFields.containsKey('verified_count')) {
      return int.tryParse(r.extraFields['verified_count'].toString()) ?? 0;
    }
    return isVerifiedRecord(r) ? 1 : 0;
  }

  static int getRecordPendingCount(ModuleRecord r) {
    if (r.extraFields.containsKey('pending_count')) {
      return int.tryParse(r.extraFields['pending_count'].toString()) ?? 0;
    }
    return isPendingRecord(r) ? 1 : 0;
  }

  static int getRecordTotalCount(ModuleRecord r) {
    if (r.extraFields.containsKey('total_count')) {
      final t = int.tryParse(r.extraFields['total_count'].toString());
      if (t != null) return t;
    }
    return getRecordVerifiedCount(r) + getRecordPendingCount(r);
  }

  List<ModuleRecord> get totalReceivedRecords => records;
  List<ModuleRecord> get verifiedRecords =>
      records.where((r) => getRecordVerifiedCount(r) > 0).toList();
  List<ModuleRecord> get pendingRecords =>
      records.where((r) => getRecordPendingCount(r) > 0).toList();

  int get totalReceivedCount =>
      records.fold(0, (sum, r) => sum + getRecordTotalCount(r));
  int get verifiedCount =>
      records.fold(0, (sum, r) => sum + getRecordVerifiedCount(r));
  int get pendingCount =>
      records.fold(0, (sum, r) => sum + getRecordPendingCount(r));
}
