// lib/screens/case_detail_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../modules/core/models/base_record.dart';
import '../providers/auth_provider.dart';
import '../services/case_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/case_visibility.dart';
import '../utils/police_rbac_helper.dart';
import '../widgets/send_reminder_dialog.dart';
import '../utils/common_form_module.dart';
import '../utils/pdf_helper.dart';
import '../widgets/access_denied_view.dart';
import '../widgets/dynamic_form/dynamic_form_screen.dart';
import '../widgets/module_record_dynamic_document_view.dart';
import 'case_form_screen.dart';
import 'transfer_case_form_screen.dart';

class CaseDetailScreen extends StatefulWidget {
  final ModuleRecord caseData;

  /// When false (e.g. opened from Recent Cases), hides FABs on the detail page.
  final bool showFloatingActions;

  const CaseDetailScreen({
    super.key,
    required this.caseData,
    this.showFloatingActions = true,
  });

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  final _firestore = FirestoreService();
  late ModuleRecord _record;
  bool _recordDeleted = false;
  bool _accessDenied = false;
  StreamSubscription<ModuleRecord?>? _subscription;

  @override
  void initState() {
    super.initState();
    _record = widget.caseData;
    _subscribeToRecord();
  }

  void _subscribeToRecord() {
    final id = _record.id;
    if (id.isEmpty) return;
    _fetchFreshRecord();
    _subscription?.cancel();
    _subscription = _firestore.watchCaseById(id).listen(
      (next) {
        if (!mounted) return;
        if (next != null) {
          setState(() {
            _recordDeleted = false;
            _accessDenied = false;
            _record = next;
          });
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _accessDenied = true);
      },
    );
  }

  Future<void> _fetchFreshRecord() async {
    final id = _record.id;
    if (id.isEmpty) return;
    try {
      final fresh = await CaseService().fetchCaseById(id);
      if (fresh != null && mounted) {
        setState(() {
          _recordDeleted = false;
          _accessDenied = false;
          _record = fresh;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canView = CaseVisibility.canViewRecord(record: _record, auth: auth);
    final showContent = !_recordDeleted && !_accessDenied && canView;

    if (_accessDenied || !canView) {
      return Scaffold(
        backgroundColor: AppColors.lightBg,
        body: _buildAccessDeniedBody(context),
      );
    }
    if (_recordDeleted) {
      return Scaffold(
        backgroundColor: AppColors.lightBg,
        body: _buildDeletedBody(),
      );
    }
    if (moduleUsesCommonCrimeForm(_record.moduleKey)) {
      return DynamicFormScreen(
        categoryId: _record.extraFields['categoryId'],
        moduleLabel: _record.firestoreCategoryDisplayName,
        moduleKey: _record.moduleKey,
        subCategory: _record.subCategory,
        existingRecord: _record,
        readOnly: true,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: _buildLiveBody(context, showContent),
      bottomNavigationBar: widget.showFloatingActions
          ? _buildStickyBottomActions(context, showContent)
          : null,
    );
  }

  Widget _buildAccessDeniedBody(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context),
        SliverFillRemaining(
          hasScrollBody: false,
          child: AccessDeniedView(
            message: CaseVisibility.showAskPiHint(CaseVisibility.resolveFor(
              context.read<AuthProvider>(),
            ))
                ? 'Ask your PI or API for station-wide dashboard access to view this record.'
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDeletedBody() {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.delete_forever_rounded,
                      size: 64, color: AppColors.lightSubText),
                  const SizedBox(height: 16),
                  Text(
                    'This record no longer exists',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'It may have been deleted by another officer.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.lightSubText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveBody(BuildContext context, bool showContent) {
    final isTransferred = _record.status == 'Transferred Out';
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(context),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isTransferred) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lock_outline_rounded,
                                color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Transferred Out (Read-Only)',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Transferred to Bandra Police Station by PI John Doe on ${DateTime.now().toLocal().toString().split(' ')[0]}.\nRemark: Handing over case jurisdiction as per order 1234.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _buildStatusHeader(),
                const SizedBox(height: 24),
                ModuleRecordDynamicDocumentView(
                  record: _record,
                  moduleLabel: _record.firestoreCategoryDisplayName,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 70,
      pinned: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: AppColors.lightBorder, height: 1.0),
      ),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.navyDark, size: 20),
      ),
      title: Text(
        _record.caseNumber,
        style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppColors.navyDark,
            fontSize: 16),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    final statusColor = _record.status == 'Open'
        ? AppColors.warningOrange
        : _record.status == 'Active'
            ? AppColors.infoBlue
            : _record.status == 'Resolved'
                ? AppColors.successGreen
                : AppColors.lightSubText;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration:
                BoxDecoration(color: statusColor, shape: BoxShape.circle),
            child: const Icon(Icons.assignment_turned_in_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Case Status',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w600)),
                Text(
                  _record.status.toUpperCase(),
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                      letterSpacing: 1.1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildStickyBottomActions(BuildContext context, bool showContent) {
    if (_recordDeleted || !showContent) return null;

    return Builder(builder: (ctx) {
      final auth = context.watch<AuthProvider>();
      final canEdit = PoliceRbacHelper.canEditRecord(_record, auth);
      final canSendReminder = PoliceRbacHelper.canSendReminder(auth);

      return LayoutBuilder(builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;

        Widget actionBtn({
          required String label,
          required IconData icon,
          required VoidCallback onPressed,
        }) {
          final btn = ElevatedButton.icon(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.navyDark,
              elevation: 0,
              side: const BorderSide(color: AppColors.lightBorder),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              padding: EdgeInsets.symmetric(
                vertical: isSmall ? 10 : 16,
                horizontal: isSmall ? 8 : 16,
              ),
              minimumSize: Size(0, isSmall ? 40 : 48),
              tapTargetSize: isSmall
                  ? MaterialTapTargetSize.shrinkWrap
                  : MaterialTapTargetSize.padded,
            ),
            icon: Icon(icon, size: isSmall ? 18 : 20),
            label: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: isSmall ? 12.5 : 14,
              ),
            ),
          );

          if (isSmall) {
            return btn;
          }

          return SizedBox(
            width: 220,
            child: btn,
          );
        }

        final buttons = <Widget>[
          actionBtn(
            label: 'Download PDF',
            icon: Icons.picture_as_pdf_rounded,
            onPressed: () => PdfHelper.generateCasePdf(_record),
          ),
          if (canSendReminder)
            actionBtn(
              label: 'Send Reminder',
              icon: Icons.notifications_active_rounded,
              onPressed: () => SendReminderDialog.show(context, _record),
            ),
          if (canEdit)
            actionBtn(
              label: 'Edit Record',
              icon: Icons.edit_note_rounded,
              onPressed: () {
                Navigator.push(
                  context,
                  AppTheme.fadeSlideRoute(
                    page: CaseFormScreen(
                      categoryName: _record.category,
                      existingCase: _record,
                    ),
                  ),
                );
              },
            ),
          if (_record.status != 'Transferred Out')
            actionBtn(
              label: 'Transfer Case',
              icon: Icons.swap_horiz_rounded,
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  AppTheme.fadeSlideRoute(
                    page: TransferCaseFormScreen(record: _record),
                  ),
                );
                if (result == true) {
                  setState(() {
                    _record = ModuleRecord(
                      id: _record.id,
                      moduleKey: _record.moduleKey,
                      title: _record.title,
                      caseNumber: _record.caseNumber,
                      description: _record.description,
                      complainant: _record.complainant,
                      accused: _record.accused,
                      location: _record.location,
                      incidentDate: _record.incidentDate,
                      priority: _record.priority,
                      status: 'Transferred Out',
                      assignedOfficer: _record.assignedOfficer,
                      subCategory: _record.subCategory,
                      createdAt: _record.createdAt,
                      extraFields: _record.extraFields,
                      createdBy: _record.createdBy,
                      assignedOfficerUid: _record.assignedOfficerUid,
                      stationName: _record.stationName,
                    );
                  });
                }
              },
            ),
        ];

        if (buttons.isEmpty) return const SizedBox.shrink();

        Widget child;
        if (isSmall) {
          final rows = <Widget>[];
          for (int i = 0; i < buttons.length; i += 2) {
            final hasSecond = i + 1 < buttons.length;
            rows.add(
              Row(
                children: [
                  Expanded(child: buttons[i]),
                  if (hasSecond) ...[
                    const SizedBox(width: 8),
                    Expanded(child: buttons[i + 1]),
                  ],
                ],
              ),
            );
            if (i + 2 < buttons.length) {
              rows.add(const SizedBox(height: 8));
            }
          }
          child = Column(
            mainAxisSize: MainAxisSize.min,
            children: rows,
          );
        } else {
          child = Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: buttons,
          );
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: isSmall ? 10 : AppSpacing.md,
            horizontal: isSmall ? 12 : AppSpacing.lg,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.lightBorder)),
          ),
          child: SafeArea(
            child: child,
          ),
        );
      });
    });
  }
}
