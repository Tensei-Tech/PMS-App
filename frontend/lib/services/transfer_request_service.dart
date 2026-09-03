// lib/services/transfer_request_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/transfer_request_model.dart';
import 'api_config.dart';
import 'api_service.dart';

class TransferRequestService {
  final ApiService _api = ApiService();

  /// Registration-style station address for a transfer target posting.
  static String buildTargetStationAddress(TransferRequest request) {
    return '${request.toDistrict}, ${request.toState} • ${request.toUnitType}';
  }

  /// Pending request blocking a new submission.
  Future<TransferRequest?> getActiveRequestForUser(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final res =
          await _api.get('${ApiConfig.transfers}?uid=$uid&status=pending');
      if (res.statusCode == 200 &&
          res.data is List &&
          (res.data as List).isNotEmpty) {
        return TransferRequest.fromMap(
            (res.data as List).first, (res.data as List).first['id']);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TransferRequestService.getActiveRequestForUser: $e');
      }
    }
    return null;
  }

  Stream<TransferRequest?> watchActiveRequestForUser(String uid) async* {
    final req = await getActiveRequestForUser(uid);
    yield req;
  }

  /// Most recent non-terminal request for status UI (pending / approved / rejected).
  Future<TransferRequest?> getLatestStatusRequestForUser(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final res = await _api.get('${ApiConfig.transfers}?uid=$uid');
      if (res.statusCode == 200 &&
          res.data is List &&
          (res.data as List).isNotEmpty) {
        return TransferRequest.fromMap(
            (res.data as List).first, (res.data as List).first['id']);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TransferRequestService.getLatestStatusRequestForUser: $e');
      }
    }
    return null;
  }

  /// Pending requests for destination approvers (PI/API or SP/CP).
  Future<List<TransferRequest>> getPendingForApprover({
    required String homeStationName,
    required String district,
    String? approverDesignation,
  }) async {
    try {
      final url =
          '${ApiConfig.transfers}?status=pending&to_station_name=${Uri.encodeComponent(homeStationName)}&to_district=${Uri.encodeComponent(district)}';
      final res = await _api.get(url);
      if (res.statusCode == 200 && res.data is List) {
        return (res.data as List)
            .map((item) => TransferRequest.fromMap(item, item['id']))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TransferRequestService.getPendingForApprover: $e');
      }
    }
    return [];
  }

  Future<String> createRequest(TransferRequest request) async {
    final id = request.id.isNotEmpty
        ? request.id
        : '${DateTime.now().millisecondsSinceEpoch}';
    final payload = {
      'id': id,
      'requested_by_uid': request.requestedByUid,
      'officer_name': request.requestedByName,
      'from_designation': request.fromDesignation,
      'to_designation': request.toDesignation,
      'from_station_name': request.fromStationName,
      'to_station_name': request.toStationName,
      'from_district': request.fromDistrict,
      'to_district': request.toDistrict,
      'from_state': request.fromState,
      'to_state': request.toState,
      'from_unit_type': request.fromUnitType,
      'to_unit_type': request.toUnitType,
      'reason': request.requesterNote,
      'status': 'pending',
    };

    final res = await _api.post(ApiConfig.transfers, body: payload);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return id;
    }
    throw Exception('Failed to create transfer request: ${res.data}');
  }

  Future<void> cancelRequest(String requestId) async {
    await _api.post('${ApiConfig.transfers}$requestId/cancel/');
  }

  Future<void> approveTransfer({
    required TransferRequest request,
    required String approverUid,
  }) async {
    await _api.post('${ApiConfig.transfers}${request.id}/approve/', body: {
      'approved_by_uid': approverUid,
    });
  }

  Future<void> rejectTransfer({
    required String requestId,
    required String approverUid,
    String? rejectionReason,
  }) async {
    await _api.post('${ApiConfig.transfers}$requestId/reject/', body: {
      'rejected_by_uid': approverUid,
      'rejection_reason': rejectionReason ?? '',
    });
  }
}
