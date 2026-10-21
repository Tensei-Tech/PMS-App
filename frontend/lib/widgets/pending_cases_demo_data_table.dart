// lib/widgets/pending_cases_demo_data_table.dart
// Shared pending demo [Table] with interactive CR No. linking and case details popup.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/ad_form_screen.dart';
import '../modules/core/models/base_record.dart';
import '../modules/missing/screens/missing_form_screen.dart';
import '../modules/mpda/screens/mpda_form_screen.dart';
import '../modules/nc/screens/nc_form_screen.dart';
import '../modules/preventive/screens/preventive_form_screen.dart';
import '../screens/common_form_screen.dart';
import '../screens/module_form_screen.dart';
import '../screens/module_record_detail_screen.dart';
import '../services/backend_case_service.dart';
import '../theme/app_theme.dart';
import '../utils/common_form_module.dart';
import '../utils/pending_table_firestore_mapper.dart';

class PendingCasesDemoDataTable extends StatelessWidget {
  const PendingCasesDemoDataTable({
    super.key,
    required this.isAd,
    this.realDataRows,
    this.serialOffset = 0,
    this.isAbsconded = false,
    this.isVictim = false,
    this.isUndetected = false,
  });

  final bool isAd;
  final List<Map<String, String>>? realDataRows;
  final int serialOffset;
  final bool isAbsconded;
  final bool isVictim;
  final bool isUndetected;

  @override
  Widget build(BuildContext context) {
    final rows = realDataRows ?? [];

    final tableCore = LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final double cellFontSize = w < 360 ? 9.5 : (w < 420 ? 10.5 : 11.5);
        final double headerFontSize = w < 360 ? 9.5 : (w < 420 ? 10.5 : 11.5);

        final columnWidths = isVictim
            ? <int, TableColumnWidth>{
                0: const IntrinsicColumnWidth(),
                1: const FlexColumnWidth(1.0),
                2: const FlexColumnWidth(1.2),
                3: const FlexColumnWidth(1.2),
                4: const FlexColumnWidth(1.2),
                5: const FlexColumnWidth(1.0),
                6: const FlexColumnWidth(1.2),
                7: const FlexColumnWidth(1.2),
              }
            : isAbsconded
                ? <int, TableColumnWidth>{
                    0: const IntrinsicColumnWidth(),
                    1: const FlexColumnWidth(1.2),
                    2: const FlexColumnWidth(1.4),
                    3: const FlexColumnWidth(1.4),
                    4: const FlexColumnWidth(1.4),
                    5: const FlexColumnWidth(1.8),
                  }
                : <int, TableColumnWidth>{
                    0: const IntrinsicColumnWidth(),
                    1: const FlexColumnWidth(1.5),
                    2: const FlexColumnWidth(1.5),
                    3: const FlexColumnWidth(1.5),
                    4: const FlexColumnWidth(2.0),
                  };

        Widget headerCell(String s) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              color: AppColors.navyDark,
              alignment: Alignment.center,
              child: Text(
                s,
                textAlign: TextAlign.center,
                softWrap: true,
                style: GoogleFonts.poppins(
                  fontSize: headerFontSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
            );

        Widget dataCell(String s, {Alignment align = Alignment.center}) =>
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              alignment: align,
              child: Text(
                s,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: GoogleFonts.poppins(
                  fontSize: cellFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppColors.lightText,
                  height: 1.15,
                ),
              ),
            );

        Widget clickableCrCell(Map<String, String> r) {
          final cr = r['cr']?.trim().isNotEmpty == true ? r['cr']!.trim() : '—';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            alignment: Alignment.center,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showCaseFilledInfoDialog(context, r),
                borderRadius: BorderRadius.circular(6),
                hoverColor: AppColors.navyMid.withValues(alpha: 0.1),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          cr,
                          textAlign: TextAlign.center,
                          softWrap: true,
                          style: GoogleFonts.poppins(
                            fontSize: cellFontSize,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navyMid,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.navyMid,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.open_in_new_rounded,
                        size: 11,
                        color: AppColors.navyMid,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final headers = <Widget>[
          headerCell('Sr. No'),
          headerCell('Cr. No.'),
          headerCell('SEC & ACT'),
          if (isAbsconded) headerCell('Accused Name (फरार आरोपी)'),
          if (isVictim) headerCell('Head'),
          if (isVictim) headerCell('Name'),
          if (isVictim) headerCell('Injured/Deceased'),
          headerCell('IO Name'),
          headerCell('Police station name'),
        ];

        TableRow rowFor(int idx, Map<String, String> r) {
          final bg = idx.isEven ? Colors.white : const Color(0xFFF6F8FF);
          return TableRow(
            decoration: BoxDecoration(color: bg),
            children: [
              dataCell('${serialOffset + idx + 1}'),
              clickableCrCell(r),
              dataCell(r['sections']!),
              if (isAbsconded)
                dataCell(
                  r['accused']?.isNotEmpty == true ? r['accused']! : '—',
                  align: Alignment.centerLeft,
                ),
              if (isVictim)
                dataCell(
                    r['victim_head']?.isNotEmpty == true
                        ? r['victim_head']!
                        : '—',
                    align: Alignment.centerLeft),
              if (isVictim)
                dataCell(
                    r['victim_name']?.isNotEmpty == true
                        ? r['victim_name']!
                        : '—',
                    align: Alignment.centerLeft),
              if (isVictim)
                dataCell(
                    r['injured_deceased']?.isNotEmpty == true
                        ? r['injured_deceased']!
                        : '—',
                    align: Alignment.centerLeft),
              dataCell(r['io']!, align: Alignment.centerLeft),
              dataCell(r['station']!, align: Alignment.centerLeft),
            ],
          );
        }

        final maxH = constraints.maxHeight;
        final inner = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: maxH.isFinite ? maxH : null,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.lightBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Table(
              columnWidths: columnWidths,
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder.all(color: AppColors.lightBorder, width: 1),
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: AppColors.navyDark),
                  children: headers,
                ),
                for (var i = 0; i < rows.length; i++) rowFor(i, rows[i]),
              ],
            ),
          ),
        );
        if (maxH.isFinite) return inner;
        const estimatedRowPx = 44.0;
        final estHeight =
            estimatedRowPx * (rows.isEmpty ? 2 : rows.length + 1) + 16;
        return SizedBox(height: estHeight, child: inner);
      },
    );
    return tableCore;
  }

  /// Resolve ModuleRecord from row data, in-memory cache, or backend API.
  Future<ModuleRecord> _resolveRecord(Map<String, String> row) async {
    final id = row['id'] ?? '';
    final cr = row['cr'] ?? '';

    if (id.isNotEmpty && getPendingModuleRecord(id) != null) {
      return getPendingModuleRecord(id)!;
    }
    if (cr.isNotEmpty && getPendingModuleRecord(cr) != null) {
      return getPendingModuleRecord(cr)!;
    }

    if (id.isNotEmpty) {
      final raw = await BackendCaseService().fetchCaseById(id);
      if (raw != null) {
        final rec = ModuleRecord.fromMap(raw, id);
        cachePendingModuleRecord(rec);
        return rec;
      }
    }

    // Build fallback ModuleRecord from populated table row
    final fallback = ModuleRecord(
      id: id.isNotEmpty ? id : cr,
      moduleKey: row['module_key']?.isNotEmpty == true
          ? row['module_key']!
          : 'theft',
      title: row['title']?.isNotEmpty == true
          ? row['title']!
          : (row['head']?.isNotEmpty == true ? row['head']! : 'Case $cr'),
      caseNumber: cr,
      description: row['description'] ?? '',
      complainant: row['complainant'] ?? '',
      accused: row['accused'] ?? '',
      location: row['station'] ?? '',
      incidentDate: DateTime.tryParse(row['incident_date'] ?? '') ??
          DateTime.now(),
      priority: row['priority'] ?? 'Medium',
      status: row['status'] ?? 'Pending',
      assignedOfficer: row['io'] ?? '',
      subCategory: row['sub_category']?.isNotEmpty == true
          ? row['sub_category']
          : row['head'],
      stationName: row['station'] ?? '',
    );
    cachePendingModuleRecord(fallback);
    return fallback;
  }

  /// Opens the edit form corresponding to the record's module type.
  void _openCaseEditScreen(BuildContext context, ModuleRecord record) {
    final moduleLabel = record.subCategory?.isNotEmpty == true
        ? record.subCategory!
        : record.title;

    if (record.moduleKey == 'ad') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: ADFormScreen(
            existingRecord: record,
            popCountAfterSubmit: 2,
          ),
        ),
      );
      return;
    }
    if (record.moduleKey == 'nc') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: NcFormScreen(
            moduleLabel: moduleLabel,
            subCategory: record.subCategory,
            existingRecord: record,
          ),
        ),
      );
      return;
    }
    if (record.moduleKey == 'missing') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: MissingFormScreen(
            moduleLabel: moduleLabel,
            subCategory: record.subCategory,
            existingRecord: record,
          ),
        ),
      );
      return;
    }
    if (record.moduleKey == 'preventive') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: PreventiveFormScreen(
            moduleLabel: moduleLabel,
            subCategory: record.subCategory,
            existingRecord: record,
          ),
        ),
      );
      return;
    }
    if (record.moduleKey == 'mpda') {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: MpdaFormScreen(
            moduleLabel: moduleLabel,
            subCategory: record.subCategory,
            existingRecord: record,
          ),
        ),
      );
      return;
    }
    if (moduleUsesCommonCrimeForm(record.moduleKey)) {
      Navigator.push(
        context,
        AppTheme.fadeSlideRoute(
          page: CommonFormScreen(
            moduleLabel: moduleLabel,
            moduleKey: record.moduleKey,
            existingRecord: record,
          ),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      AppTheme.fadeSlideRoute(
        page: ModuleFormScreen(
          moduleLabel: moduleLabel,
          moduleKey: record.moduleKey,
          existingRecord: record,
        ),
      ),
    );
  }

  /// Displays the case filled information modal with View Details & Edit Case buttons.
  void _showCaseFilledInfoDialog(BuildContext context, Map<String, String> row) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: FutureBuilder<ModuleRecord>(
              future: _resolveRecord(row),
              builder: (context, snapshot) {
                final record = snapshot.data;
                final cr = row['cr'] ?? '—';
                final head = row['head'] ?? 'Case Record';
                final sections = row['sections'] ?? '—';
                final accused =
                    row['accused']?.isNotEmpty == true ? row['accused']! : '—';
                final io = row['io']?.isNotEmpty == true ? row['io']! : '—';
                final station = row['station']?.isNotEmpty == true
                    ? row['station']!
                    : '—';
                final period = row['period'] ?? '';
                final complainant = row['complainant'];

                final statusText = isAbsconded
                    ? 'Absconded'
                    : (isUndetected
                        ? 'Undetected'
                        : (isVictim
                            ? 'Victim'
                            : (row['status']?.isNotEmpty == true
                                ? row['status']!
                                : 'Pending')));

                Color badgeBg = const Color(0xFFF1F5F9);
                Color badgeBorder = const Color(0xFFCBD5E1);
                Color badgeText = const Color(0xFF475569);

                if (isAbsconded) {
                  badgeBg = const Color(0xFFFEF2F2);
                  badgeBorder = const Color(0xFFFECACA);
                  badgeText = const Color(0xFFB91C1C);
                } else if (isUndetected) {
                  badgeBg = const Color(0xFFFFFBEB);
                  badgeBorder = const Color(0xFFFDE68A);
                  badgeText = const Color(0xFFB45309);
                } else if (isVictim) {
                  badgeBg = const Color(0xFFF0FDF4);
                  badgeBorder = const Color(0xFFBBF7D0);
                  badgeText = const Color(0xFF15803D);
                }

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.navyMid.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isAbsconded
                                  ? Icons.directions_run_rounded
                                  : Icons.folder_open_rounded,
                              color: AppColors.navyMid,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CR No. $cr',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navyDark,
                                  ),
                                ),
                                Text(
                                  head,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.lightSubText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              border: Border.all(color: badgeBorder),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusText,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: badgeText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 20, color: AppColors.lightSubText),
                            onPressed: () => Navigator.pop(dialogCtx),
                            splashRadius: 18,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppColors.lightBorder),
                      const SizedBox(height: 16),

                      // Information Grid
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _infoRow(
                                icon: Icons.gavel_rounded,
                                label: 'Act & Sections',
                                value: sections,
                              ),
                              const SizedBox(height: 10),
                              _infoRow(
                                icon: isAbsconded
                                    ? Icons.directions_run_rounded
                                    : Icons.person_off_rounded,
                                label: isAbsconded
                                    ? 'Accused Name (फरार आरोपी)'
                                    : 'Accused (आरोपी)',
                                value: accused,
                                highlight: isAbsconded ||
                                    accused.contains('Unknown') ||
                                    accused.contains('अज्ञात') ||
                                    accused == '—',
                              ),
                              const SizedBox(height: 10),
                              _infoRow(
                                icon: Icons.badge_rounded,
                                label: 'Investigating Officer (I.O.)',
                                value: io,
                              ),
                              const SizedBox(height: 10),
                              _infoRow(
                                icon: Icons.local_police_rounded,
                                label: 'Police Station',
                                value: station,
                              ),
                              if (period.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                _infoRow(
                                  icon: Icons.calendar_today_rounded,
                                  label: 'Period / Incident Date',
                                  value: period,
                                ),
                              ],
                              if (complainant != null &&
                                  complainant.isNotEmpty &&
                                  complainant != '—') ...[
                                const SizedBox(height: 10),
                                _infoRow(
                                  icon: Icons.person_outline_rounded,
                                  label: 'Complainant',
                                  value: complainant,
                                ),
                              ],
                              if (row['victim_head']?.isNotEmpty == true) ...[
                                const SizedBox(height: 10),
                                _infoRow(
                                  icon: Icons.category_rounded,
                                  label: 'Victim Head',
                                  value: row['victim_head']!,
                                ),
                              ],
                              if (row['victim_name']?.isNotEmpty == true) ...[
                                const SizedBox(height: 10),
                                _infoRow(
                                  icon: Icons.person_rounded,
                                  label: 'Victim Name',
                                  value: row['victim_name']!,
                                ),
                              ],
                              if (row['injured_deceased']?.isNotEmpty == true) ...[
                                const SizedBox(height: 10),
                                _infoRow(
                                  icon: Icons.healing_rounded,
                                  label: 'Injured / Deceased',
                                  value: row['injured_deceased']!,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: AppColors.lightBorder),
                      const SizedBox(height: 16),

                      // Action Buttons: View Details & Edit Case
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(dialogCtx);
                                if (record != null) {
                                  Navigator.push(
                                    context,
                                    AppTheme.fadeSlideRoute(
                                      page: ModuleRecordDetailScreen(
                                        record: record,
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.visibility_rounded,
                                  size: 17),
                              label: Text(
                                'View Details',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.navyMid,
                                side: const BorderSide(
                                    color: AppColors.navyMid),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(dialogCtx);
                                if (record != null) {
                                  _openCaseEditScreen(context, record);
                                }
                              },
                              icon: const Icon(Icons.edit_note_rounded,
                                  size: 19),
                              label: Text(
                                'Edit Case',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.navyMid,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.navyMid),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.lightSubText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
                    color: highlight
                        ? const Color(0xFFDC2626)
                        : AppColors.navyDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
