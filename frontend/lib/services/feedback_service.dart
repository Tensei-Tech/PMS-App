// lib/services/feedback_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import 'firestore_service.dart';

class FeedbackService {
  /// Submits feedback to Firestore (central [/feedback] for Master Admin Dashboard)
  /// and mirrors to webhook if available.
  Future<bool> submitFeedback({
    required String name,
    required String email,
    required String message,
    String category = 'General',
    String uid = '',
  }) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();
    final trimmedMessage = message.trim();
    final clientTs = DateTime.now().toIso8601String();

    // 1. Submit to Firestore (/feedback collection for Master Admin Dashboard)
    try {
      await FirestoreService().addUserFeedback(
        uid: uid,
        name: trimmedName,
        email: trimmedEmail,
        category: category,
        message: trimmedMessage,
        clientTimestampIso: clientTs,
      );
    } catch (e) {
      debugPrint('[FeedbackService] Firestore save notice: $e');
    }

    // 2. Webhook POST notification (Apps Script)
    if (ApiConstants.feedbackWebAppUrl.isNotEmpty) {
      try {
        final body = {
          'name': trimmedName,
          'email': trimmedEmail,
          'category': category,
          'message': trimmedMessage,
          'timestamp': clientTs,
        };

        await http.post(
          Uri.parse(ApiConstants.feedbackWebAppUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        );
      } catch (e) {
        debugPrint('[FeedbackService] Webhook notice: $e');
      }
    } else {
      debugPrint(
        '[FeedbackService] FEEDBACK_WEB_APP_URL is not set; skipping webhook mirror.',
      );
    }

    // Always complete successfully for the user
    return true;
  }
}
