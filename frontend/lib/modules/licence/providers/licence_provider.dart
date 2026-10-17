// lib/modules/licence/providers/licence_provider.dart
import '../../core/models/base_record.dart';
import '../../core/providers/base_module_provider.dart';

enum LicenceStatusFilter {
  totalReceived,
  approved,
  rejected,
  returned,
  pending,
}

class LicenceProvider extends BaseModuleProvider {
  static const String statusPending = 'Pending';
  static const String statusApproved = 'Approved';
  static const String statusRejected = 'Rejected';
  static const String statusReturned = 'Returned';

  LicenceProvider() : super('licence');

  static bool isApprovedRecord(ModuleRecord r) {
    final s = r.status.trim().toLowerCase();
    final vs = (r.extraFields['licence_status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    return s == 'approved' || vs == 'approved';
  }

  static bool isRejectedRecord(ModuleRecord r) {
    final s = r.status.trim().toLowerCase();
    final vs = (r.extraFields['licence_status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    return s == 'rejected' || vs == 'rejected';
  }

  static bool isReturnedRecord(ModuleRecord r) {
    final s = r.status.trim().toLowerCase();
    final vs = (r.extraFields['licence_status'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    return s == 'returned' || vs == 'returned';
  }

  static bool isPendingRecord(ModuleRecord r) {
    return !isApprovedRecord(r) && !isRejectedRecord(r) && !isReturnedRecord(r);
  }

  List<ModuleRecord> get totalReceivedRecords => records;
  List<ModuleRecord> get approvedRecords =>
      records.where(isApprovedRecord).toList();
  List<ModuleRecord> get rejectedRecords =>
      records.where(isRejectedRecord).toList();
  List<ModuleRecord> get returnedRecords =>
      records.where(isReturnedRecord).toList();
  List<ModuleRecord> get pendingRecords =>
      records.where(isPendingRecord).toList();

  int get totalReceivedCount => records.length;
  int get approvedCount => records.where(isApprovedRecord).length;
  int get rejectedCount => records.where(isRejectedRecord).length;
  int get returnedCount => records.where(isReturnedRecord).length;
  int get pendingCount => records.where(isPendingRecord).length;
}
