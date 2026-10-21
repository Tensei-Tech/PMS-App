// lib/providers/notification_provider.dart
// State management for FCM push notifications — badge count + notification list.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/fcm_service.dart';
import '../services/mpda_service.dart';
import '../services/rti_service.dart';

/// Single notification item stored in memory.
class NotificationItem {
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });
}

/// Provider that owns the notification list and badge count.
/// Listens to [FcmService.onForegroundMessage] to auto-add incoming messages.
class NotificationProvider extends ChangeNotifier {
  final List<NotificationItem> _notifications = [];
  StreamSubscription<RemoteMessage>? _fcmSub;

  /// MPDA detention end reminders of the officer's station (from the backend:
  /// shown from one month before the Detention End Date until that date).
  List<Map<String, dynamic>> _detentionReminders = const [];
  Map<String, dynamic> _detentionReminderLabels = const {};
  final Set<String> _seenReminderKeys = {};

  List<Map<String, dynamic>> get detentionReminders => _detentionReminders;

  /// Section label for the reminders list (backend setting).
  String get detentionReminderLabel =>
      _detentionReminderLabels['tab']?.toString() ?? '';

  /// Banner text with {count} / {days} filled in (backend setting).
  String detentionReminderBanner(int days) =>
      (_detentionReminderLabels['banner']?.toString() ?? '')
          .replaceAll('{count}', '${_detentionReminders.length}')
          .replaceAll('{days}', '$days');

  int _detentionReminderDays = 0;
  int get detentionReminderDays => _detentionReminderDays;

  /// RTI due-date reminders of the logged-in officer (from the backend: 30 and
  /// 25 days before the Due Date, then daily; plus manual reminders).
  List<Map<String, dynamic>> _rtiReminders = const [];
  Map<String, dynamic> _rtiReminderLabels = const {};

  List<Map<String, dynamic>> get rtiReminders => _rtiReminders;

  /// Section label for the RTI reminders list (backend setting).
  String get rtiReminderLabel => _rtiReminderLabels['tab']?.toString() ?? '';

  /// Reload the officer's RTI reminders (call on dashboard open).
  Future<void> loadRtiReminders() async {
    final data = await RtiService().fetchReminders();
    _rtiReminders = ((data['results'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    _rtiReminderLabels =
        Map<String, dynamic>.from((data['labels'] as Map?) ?? const {});
    notifyListeners();
  }

  // A reminder counts as new again every day until the end date
  String _reminderKey(Map r) {
    final now = DateTime.now();
    return '${r['id']}@${now.year}-${now.month}-${now.day}';
  }

  /// Reload the station's detention reminders (call on dashboard / MPDA open).
  Future<void> loadDetentionReminders() async {
    final data = await MpdaService().fetchDetentionReminders();
    _detentionReminders = ((data['results'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    _detentionReminderLabels =
        Map<String, dynamic>.from((data['labels'] as Map?) ?? const {});
    _detentionReminderDays = int.tryParse('${data['days'] ?? ''}') ?? 0;
    notifyListeners();
  }

  /// All stored notifications, newest first.
  List<NotificationItem> get notifications =>
      List.unmodifiable(_notifications.reversed);

  /// Number of unread notifications (displayed as the badge count).
  int get unreadCount =>
      _notifications.where((n) => !n.isRead).length +
      _detentionReminders
          .where((r) => !_seenReminderKeys.contains(_reminderKey(r)))
          .length +
      _rtiReminders
          .where((r) => !_seenReminderKeys.contains(_reminderKey(r)))
          .length;

  /// Start listening to the FCM foreground stream.
  /// Call this once from main.dart after FcmService.initialize().
  void startListening() {
    _fcmSub?.cancel();
    _fcmSub = FcmService().onForegroundMessage.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    final notification = message.notification;
    final title =
        notification?.title ?? message.data['title'] ?? 'Notification';
    final body = notification?.body ?? message.data['body'] ?? '';

    addNotification(title: title, body: body);
  }

  /// Manually add a notification (also used by background handler if needed).
  void addNotification({required String title, required String body}) {
    _notifications.add(
      NotificationItem(title: title, body: body, timestamp: DateTime.now()),
    );
    notifyListeners();
  }

  /// Mark all notifications as read — resets the badge count to 0.
  void clearBadge() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    _seenReminderKeys.addAll(_detentionReminders.map(_reminderKey));
    _seenReminderKeys.addAll(_rtiReminders.map(_reminderKey));
    if (_rtiReminders.any((r) => r['kind'] == 'manual')) {
      RtiService().markRemindersSeen();
    }
    if (_detentionReminders.any((r) => r['kind'] == 'manual')) {
      MpdaService().markRemindersSeen();
    }
    notifyListeners();
  }

  /// Remove all stored notifications.
  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _fcmSub?.cancel();
    super.dispose();
  }
}
