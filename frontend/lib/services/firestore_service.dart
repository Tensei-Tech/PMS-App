// lib/services/firestore_service.dart
// Fallback stub replacing legacy Cloud Firestore operations.
// All active database storage & permissions have migrated to Django PostgreSQL REST backend.

import 'dart:async';
import '../modules/core/models/base_record.dart';
import '../models/user_model.dart';

class FirestoreService {
  static const String colUsers = 'users';
  static const String colCases = 'cases';
  static const String colPending = 'pending_cases';
  static const String colDisposal = 'disposal_cases';
  static const String colFirs = 'firs';
  static const String colWanted = 'wanted';
  static const String colStations = 'stations';

  Future<void> saveUser(UserModel user) async {}

  Future<void> updateUserField(String uid, String field, dynamic value) async {}

  Future<UserModel?> getUser(String uid) async => null;

  Stream<UserModel?> watchUser(String uid) => Stream.value(null);

  Future<UserModel?> getUserByEmail(String email) async => null;

  Future<void> saveCase(ModuleRecord record, {bool isCreate = false}) async {}

  Future<void> deleteCase(String id, {required String moduleKey}) async {}

  Stream<ModuleRecord?> watchCaseById(String id) => Stream.value(null);

  Stream<Map<String, dynamic>?> watchDocumentData(
    String collection,
    String docId,
  ) =>
      Stream.value(null);

  Stream<List<ModuleRecord>> getCasesStream(
    String moduleKey,
    String stationId,
  ) =>
      Stream.value(const []);

  Stream<List<ModuleRecord>> watchAssignedCasesStream(
    String officerUid, {
    required bool activeOnly,
  }) =>
      Stream.value(const []);

  Stream<List<ModuleRecord>> getRecentCasesStream(
    int limit,
    String stationId,
  ) =>
      Stream.value(const []);

  Stream<List<ModuleRecord>> getStationCasesStream(String stationId) =>
      Stream.value(const []);

  Stream<List<ModuleRecord>> getPendingCasesStream(String stationId) =>
      Stream.value(const []);

  Future<List<ModuleRecord>> fetchPendingCasesOnce(String stationId) async =>
      [];

  Stream<List<ModuleRecord>> getDisposalCasesStream(String stationId) =>
      Stream.value(const []);

  Future<void> saveFir(Map<String, dynamic> firData) async {}

  Future<void> saveWanted(Map<String, dynamic> wantedData) async {}

  Future<UserModel?> findFloatingUserByEmailOrPhone(String query) async => null;

  Future<void> assignFloatingUserToStation({
    required String uid,
    required String stationName,
    required String district,
    required String stationAddress,
  }) async {}

  Future<List<UserModel>> getUsersAtStation(String stationName) async => [];

  Future<List<String>> getPoliceStationNames() async => getAllStationNames();

  Future<List<String>> getAllStationNames() async => const [];

  Stream<dynamic> watchUserAppPreferences(String uid) => Stream.value(null);

  Future<void> mergeUserAppPreferences(
    String uid,
    Map<String, dynamic> fields,
  ) async {}

  Future<String?> addUserFeedback({
    required String uid,
    required String name,
    required String email,
    required String message,
    String category = 'General',
    String? clientTimestampIso,
  }) async =>
      null;

  Stream<List<UserModel>> watchPendingRegistrationRequests({
    required bool isSuperAdmin,
    required bool canReview,
    required String approverDesignation,
    required String approverZone,
    required String approverStation,
  }) =>
      Stream.value(const []);

  Future<void> approveUserRegistration(String uid) async {}

  Future<void> rejectUserRegistration(String uid) async {}

  Future<void> sendCaseReminder({
    required String caseId,
    required String caseNumber,
    required String caseTitle,
    required String stationName,
    required String ioName,
    required String ioUid,
    required String sentByUid,
    required String sentByName,
    required String sentByDesignation,
    required String reminderType,
    String notes = '',
  }) async {}

  Stream<List<Map<String, dynamic>>> getIoRemindersStream(String ioUid) =>
      Stream.value(const []);

  Stream<List<Map<String, dynamic>>> getStationRemindersStream(
    String stationName,
  ) =>
      Stream.value(const []);

  Stream<List<Map<String, dynamic>>> getSentRemindersStream(String sentByUid) =>
      Stream.value(const []);

  Stream<List<Map<String, dynamic>>> getAllRemindersStream() =>
      Stream.value(const []);
}
