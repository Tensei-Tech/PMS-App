// lib/widgets/bell_icon_widget.dart
// Animated bell icon with red badge counter for FCM notifications.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../screens/notification_screen.dart';
import '../theme/app_theme.dart';

class BellIconWidget extends StatefulWidget {
  const BellIconWidget({super.key});

  @override
  State<BellIconWidget> createState() => _BellIconWidgetState();
}

class _BellIconWidgetState extends State<BellIconWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;
  int _prevCount = 0;

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _hoverEntry;
  Timer? _showTimer;
  Timer? _hideTimer;
  bool _isHoveringBell = false;
  bool _isHoveringCard = false;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _removeHoverCard();
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _onTap() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _removeHoverCard();
    final provider = context.read<NotificationProvider>();
    provider.clearBadge();
    Navigator.push(
      context,
      AppTheme.fadeSlideRoute(page: const NotificationScreen()),
    );
  }

  void _scheduleShow() {
    _hideTimer?.cancel();
    if (_hoverEntry != null) return;
    _showTimer?.cancel();
    _showTimer = Timer(const Duration(milliseconds: 180), () {
      if (!mounted || (!_isHoveringBell && !_isHoveringCard)) return;
      _insertHoverCard();
    });
  }

  void _scheduleHide() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 220), () {
      if (!mounted || _isHoveringBell || _isHoveringCard) return;
      _removeHoverCard();
    });
  }

  void _removeHoverCard() {
    _hoverEntry?.remove();
    _hoverEntry = null;
  }

  void _insertHoverCard() {
    if (_hoverEntry != null || !mounted) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _hoverEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        width: 310,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(0, 8),
          child: MouseRegion(
            onEnter: (_) {
              _isHoveringCard = true;
              _hideTimer?.cancel();
            },
            onExit: (_) {
              _isHoveringCard = false;
              _scheduleHide();
            },
            child: Material(
              color: Colors.transparent,
              child: _buildHoverCard(ctx),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_hoverEntry!);
  }

  Widget _buildHoverCard(BuildContext ctx) {
    final provider = context.watch<NotificationProvider>();
    final items = provider.notifications.take(4).toList();
    final detentionCount = provider.detentionReminders.length;
    final rtiCount = provider.rtiReminders.length;
    final unread = provider.unreadCount;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Notifications',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: unread > 0
                        ? AppColors.dangerRed.withValues(alpha: 0.1)
                        : AppColors.navyMid.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unread > 0 ? '$unread unread' : 'All caught up',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color:
                          unread > 0 ? AppColors.dangerRed : AppColors.navyMid,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          if (items.isEmpty && detentionCount == 0 && rtiCount == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 28,
                    color: AppColors.navyMid.withValues(alpha: 0.35),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'No new notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.lightSubText,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            if (detentionCount > 0)
              _hoverSummaryRow(
                Icons.gavel_rounded,
                'Detention reminders',
                '$detentionCount pending',
              ),
            if (rtiCount > 0)
              _hoverSummaryRow(
                Icons.assignment_late_outlined,
                'RTI reminders',
                '$rtiCount due',
              ),
            for (final n in items)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: n.isRead
                            ? const Color(0xFFCBD5E1)
                            : AppColors.navyMid,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight:
                                  n.isRead ? FontWeight.w500 : FontWeight.w600,
                              color: AppColors.navyDark,
                            ),
                          ),
                          if (n.body.isNotEmpty)
                            Text(
                              n.body,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.lightSubText,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
              onTap: _onTap,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(11)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View all notifications',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyMid,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppColors.navyMid,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hoverSummaryRow(IconData icon, String label, String badge) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.navyMid),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.navyDark,
              ),
            ),
          ),
          Text(
            badge,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.navyMid,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationProvider>().unreadCount;

    // Trigger bounce animation when count increases.
    if (unread > _prevCount && unread > 0) {
      _bounceCtrl.forward(from: 0);
    }
    _prevCount = unread;

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          _isHoveringBell = true;
          _scheduleShow();
        },
        onExit: (_) {
          _isHoveringBell = false;
          _scheduleHide();
        },
        child: GestureDetector(
          onTap: _onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Bell button (matches existing _appBarBtn style) ─────────────
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6FB),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: AppColors.navyDark,
                    size: 20,
                  ),
                ),

                // ── Badge counter ───────────────────────────────────────────────
                if (unread > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: ScaleTransition(
                      scale: _bounceAnim,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.dangerRed,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.dangerRed.withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
