// lib/screens/notification_screen.dart
// Full-page notification history — lists all received FCM notifications.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';
import '../utils/translation_helper.dart';
import '../widgets/module_hub_screen_app_bar.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  Stream<List<Map<String, dynamic>>>? _remindersStream;
  String? _lastStreamKey;

  Stream<List<Map<String, dynamic>>> _getRemindersStream(
    AuthProvider auth,
    FirestoreService firestore,
  ) {
    final key = '${auth.designation}|${auth.uid}|${auth.stationName}';
    if (_remindersStream != null && _lastStreamKey == key) {
      return _remindersStream!;
    }
    _lastStreamKey = key;
    _remindersStream = SeniorOfficerRoles.isCpLevel(auth.designation) ||
            SeniorOfficerRoles.isSpLevel(auth.designation)
        ? firestore.getAllRemindersStream()
        : (auth.isSupervisor || auth.isAdmin)
            ? firestore.getSentRemindersStream(auth.uid)
            : (auth.stationName.isNotEmpty
                ? firestore.getStationRemindersStream(auth.stationName)
                : firestore.getIoRemindersStream(auth.uid));
    return _remindersStream!;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final auth = context.watch<AuthProvider>();
    final items = provider.notifications;
    final firestore = FirestoreService();
    final reminderCount =
        provider.rtiReminders.length + provider.detentionReminders.length;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.lightBg,
        appBar: ModuleHubScreenAppBar(
          title: TranslationHelper.translate(context, 'Notifications & Reminders'),
          subtitle: TranslationHelper.translate(
            context,
            'Directives, Case Reminders & System Alerts',
          ),
          actionWidget: items.any((n) => !n.isRead)
              ? TextButton.icon(
                  onPressed: () =>
                      context.read<NotificationProvider>().clearBadge(),
                  icon: const Icon(
                    Icons.done_all_rounded,
                    size: 16,
                    color: Color(0xFF1976D2),
                  ),
                  label: Text(
                    TranslationHelper.translate(context, 'Mark Read'),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1976D2),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    backgroundColor: const Color(0xFFE8F1FC),
                    shape: const StadiumBorder(),
                  ),
                )
              : null,
        ),
        body: Column(
          children: [
            // ── Police Theme Sub-Tab Bar Strip ──
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: TabBar(
                    labelColor: AppColors.navyDark,
                    unselectedLabelColor: AppColors.lightSubText,
                    indicatorColor: const Color(0xFF1976D2),
                    indicatorWeight: 2.5,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.notifications_active_outlined,
                              size: 17,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              TranslationHelper.translate(
                                context,
                                'Case Reminders',
                              ),
                            ),
                            if (reminderCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F1FC),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full),
                                ),
                                child: Text(
                                  '$reminderCount',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1976D2),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.mark_email_unread_outlined,
                              size: 17,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              TranslationHelper.translate(
                                context,
                                'System Alerts',
                              ),
                            ),
                            if (provider.unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full),
                                ),
                                child: Text(
                                  '${provider.unreadCount}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFE65100),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Tab Contents Centered & Constrained for Desktop ──
            Expanded(
              child: TabBarView(
                children: [
                  // ── TAB 1: MPDA detention reminders + live Case Reminders ─────
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: Column(
                        children: [
                          if (provider.rtiReminders.isNotEmpty)
                            _buildReminderSection(
                              provider.rtiReminders,
                              provider.rtiReminderLabel,
                            ),
                          if (provider.detentionReminders.isNotEmpty)
                            _buildDetentionReminders(provider),
                          Expanded(
                            child: StreamBuilder<List<Map<String, dynamic>>>(
                              initialData: const <Map<String, dynamic>>[],
                              stream: _getRemindersStream(auth, firestore),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final reminders = snapshot.data ?? [];
                                final isSenior = SeniorOfficerRoles.isCpLevel(
                                      auth.designation,
                                    ) ||
                                    SeniorOfficerRoles.isSpLevel(
                                      auth.designation,
                                    ) ||
                                    auth.isSupervisor;

                                if (reminders.isEmpty) {
                                  return _buildEmptyRemindersState(
                                    isSenior: isSenior,
                                    context: context,
                                  );
                                }

                                return ListView.separated(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  itemCount: reminders.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final r = reminders[index];
                                    return _buildReminderCard(
                                      r,
                                      isSenior: isSenior,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── TAB 2: System / FCM Alerts ────────────────────────────────
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: items.isEmpty
                          ? _buildEmptyState(context)
                          : _buildList(items),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// MPDA detention end reminders of the officer's station (text from the
  /// backend settings), shown from one month before the end date.
  Widget _buildDetentionReminders(NotificationProvider provider) =>
      _buildReminderSection(
          provider.detentionReminders, provider.detentionReminderLabel);

  /// Reminder cards with a section label (texts come from backend settings).
  Widget _buildReminderSection(List<Map<String, dynamic>> items, String label) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 340),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
        children: [
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDark,
                ),
              ),
            ),
          for (final r in items)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: const Color(0xFFFECACA),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.event_busy_rounded,
                      size: 18,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ('${r['title'] ?? ''}'.isNotEmpty)
                          Text(
                            '${r['title']}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        Text(
                          '${r['message'] ?? ''}',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: AppColors.navyDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Manual reminders carry no days-left count
                  if (r['days_left'] != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '${r['days_left']}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyRemindersState({
    required bool isSenior,
    required BuildContext context,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F1FC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                size: 46,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              TranslationHelper.translate(
                context,
                isSenior ? 'No Directives Issued Yet' : 'No Case Reminders',
              ),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                TranslationHelper.translate(
                  context,
                  isSenior
                      ? 'Supervisory directives (PCR, FSL, Charge Sheet) you issue to Investigating Officers will appear here.'
                      : 'Supervisory directives sent by Senior Officers will appear here.',
                ),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: AppColors.lightSubText,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> r, {required bool isSenior}) {
    final reminderType = r['reminderType'] ?? 'Supervisory Directive';
    final caseNo = r['caseNumber'] ?? r['caseTitle'] ?? 'Case';
    final sentByName = r['sentByName'] ?? 'Senior Officer';
    final sentByRank = r['sentByDesignation'] ?? '';
    final ioName = r['ioName'] ?? 'Assigned IO';
    final stationName = r['stationName'] ?? '';
    final notes = r['notes'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FC),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  reminderType,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1976D2),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  caseNo,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isSenior
                ? 'Assigned IO: $ioName ${stationName.isNotEmpty ? '• $stationName' : ''}'
                : 'From: $sentByName ${sentByRank.isNotEmpty ? '($sentByRank)' : ''}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.navyDark,
            ),
          ),
          if (isSenior) ...[
            const SizedBox(height: 2),
            Text(
              'Issued By: $sentByName ${sentByRank.isNotEmpty ? '($sentByRank)' : ''}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.lightSubText,
              ),
            ),
          ] else if (ioName.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Directed To: $ioName',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.lightSubText,
              ),
            ),
          ],
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: const Border(
                  left: BorderSide(color: Color(0xFF1976D2), width: 3),
                  top: BorderSide(color: Color(0xFFE2E8F0)),
                  right: BorderSide(color: Color(0xFFE2E8F0)),
                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.format_quote_rounded,
                    size: 16,
                    color: Color(0xFF1976D2),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      notes,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.navyDark,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F1FC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 46,
                color: Color(0xFF1976D2),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              TranslationHelper.translate(context, 'No System Alerts'),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                TranslationHelper.translate(
                  context,
                  'You\'re all caught up! Push notifications and system alerts will appear here.',
                ),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: AppColors.lightSubText,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<NotificationItem> items) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return _NotificationCard(item: item);
      },
    );
  }
}

// ── Notification Card ─────────────────────────────────────────────────────────
class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  const _NotificationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatTimestamp(item.timestamp);
    final isUnread = !item.isRead;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnread ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isUnread
              ? const Color(0xFFBFDBFE)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Icon ────────────────────────────────────────────────────────────
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isUnread
                  ? const Color(0xFFE8F1FC)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              isUnread
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              color: isUnread
                  ? const Color(0xFF1976D2)
                  : AppColors.lightSubText,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // ── Content ─────────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight:
                              isUnread ? FontWeight.w700 : FontWeight.w600,
                          color: AppColors.navyDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1976D2),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                if (item.body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: AppColors.lightSubText,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: AppColors.lightSubText.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.lightSubText.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday, ${DateFormat.jm().format(dt)}';
    if (diff.inDays < 7) return DateFormat('EEEE, h:mm a').format(dt);
    return DateFormat('dd MMM yyyy, h:mm a').format(dt);
  }
}
