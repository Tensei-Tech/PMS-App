import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../modules/core/models/base_record.dart';
import '../services/backend_case_service.dart';
import '../theme/app_theme.dart';
import '../utils/excel_export_helper.dart';
import 'send_reminder_dialog.dart';

class NAFISCasesDataTable extends StatelessWidget {
  const NAFISCasesDataTable({
    super.key,
    this.realDataRows,
    this.rawRecords,
    this.serialOffset = 0,
    this.onRowTap,
    this.showChargeSheetDateColumn = true,
  });

  final List<Map<String, dynamic>>? realDataRows;
  final List<ModuleRecord>? rawRecords;
  final int serialOffset;
  final void Function(int index, Map<String, dynamic> row)? onRowTap;
  final bool showChargeSheetDateColumn;

  @override
  Widget build(BuildContext context) {
    final rows = realDataRows ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final isMobile = w < 880;
        final double cellFontSize = w < 360 ? 9.5 : (w < 420 ? 10.5 : 11.5);
        final double headerFontSize = w < 360 ? 9.5 : (w < 420 ? 10.5 : 11.5);
        const double hPad = 8.0;
        const double vPad = 8.0;

        final double col0W = isMobile ? 56.0 : 65.0;
        final double col1W = isMobile ? 140.0 : 155.0;
        final double col2W = isMobile ? 100.0 : 110.0;
        final double col3W = isMobile ? 125.0 : 140.0;
        final double col4W = isMobile ? 120.0 : 130.0;
        final double col5W = isMobile ? 135.0 : 150.0;
        final double col6W = isMobile ? 96.0 : 105.0;
        final double col7W = isMobile ? 120.0 : 130.0;

        final double totalColumnsWidth =
            col0W + col1W + col2W + col3W + col4W + col5W + col6W + col7W;
        final double tableWidth = math.max(w, totalColumnsWidth);

        Widget headerCell(String s, {Alignment align = Alignment.centerLeft}) =>
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: hPad, vertical: 9),
              color: AppColors.navyMid,
              alignment: align,
              child: Text(
                s,
                softWrap: true,
                textAlign: align == Alignment.center
                    ? TextAlign.center
                    : TextAlign.left,
                style: GoogleFonts.poppins(
                  fontSize: headerFontSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
            );

        Widget dataCell(
          String s, {
          Alignment align = Alignment.centerLeft,
          Color? textColor,
          FontWeight? fontWeight,
          int? maxLines,
          VoidCallback? onTap,
        }) {
          final trimmed = s.trim();
          final isDash = trimmed == '—' || trimmed == '-' || trimmed.isEmpty;
          final display = trimmed.isEmpty || trimmed == '-' ? '—' : s;
          final content = Container(
            padding:
                const EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            alignment: align,
            child: Text(
              display,
              maxLines: maxLines ?? 2,
              overflow: TextOverflow.ellipsis,
              textAlign:
                  align == Alignment.center ? TextAlign.center : TextAlign.left,
              style: GoogleFonts.poppins(
                fontSize: cellFontSize,
                fontWeight:
                    isDash ? FontWeight.w400 : (fontWeight ?? FontWeight.w500),
                color: isDash
                    ? const Color(0xFF94A3B8)
                    : (textColor ?? AppColors.navyDark),
                height: 1.15,
              ),
            ),
          );

          if (onTap != null) {
            return InkWell(
              onTap: onTap,
              child: content,
            );
          }
          return content;
        }

        Widget statusBadge(bool isPending, {String? label}) {
          final text = label ?? (isPending ? 'Pending' : 'Done');
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isPending
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }

        Widget actionCell(int idx, Map<String, dynamic> r, bool isPending) {
          if (!isPending) {
            return Center(
              child: Text(
                '—',
                style: GoogleFonts.poppins(
                  fontSize: cellFontSize,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            );
          }

          final caseId = (r['id'] ?? r['case_id'] ?? '').toString();
          final crNo =
              (r['cr'] ?? r['cr_no'] ?? r['case_number'] ?? '').toString();

          return Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                minimumSize: const Size(84, 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                if (caseId.isNotEmpty) {
                  final ok =
                      await BackendCaseService().sendNafisReminderToIO(caseId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? 'Reminder sent to IO for case $crNo'
                            : 'Reminder recorded for case $crNo'),
                        backgroundColor: const Color(0xFFEF4444),
                      ),
                    );
                  }
                } else {
                  ModuleRecord record;
                  if (rawRecords != null && idx < rawRecords!.length) {
                    record = rawRecords![idx];
                  } else {
                    record = ModuleRecord.fromMap(r);
                  }
                  SendReminderDialog.show(
                    context,
                    record,
                    initialPreset: 'NAFIS Fingerprint Pending',
                  );
                }
              },
              child: Text(
                'Remind to IO',
                maxLines: 1,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }

        final columnWidths = isMobile
            ? <int, TableColumnWidth>{
                0: FixedColumnWidth(col0W), // Sr. No.
                1: FixedColumnWidth(col1W), // Accused Name
                2: FixedColumnWidth(col2W), // CR No.
                3: FixedColumnWidth(col3W), // Section/Act
                4: FixedColumnWidth(col4W), // Head
                5: FixedColumnWidth(col5W), // IO Name
                6: FixedColumnWidth(col6W), // Status
                7: FixedColumnWidth(col7W), // Remind to IO
              }
            : const <int, TableColumnWidth>{
                0: FixedColumnWidth(65),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1.1),
                3: FlexColumnWidth(1.4),
                4: FlexColumnWidth(1.3),
                5: FlexColumnWidth(1.5),
                6: FixedColumnWidth(105),
                7: FixedColumnWidth(130),
              };

        final headers = <Widget>[
          headerCell('Sr. No.', align: Alignment.center),
          headerCell('Accused Name'),
          headerCell('CR No.'),
          headerCell('Section/Act'),
          headerCell('Head'),
          headerCell('IO Name'),
          headerCell('Status', align: Alignment.center),
          headerCell('Remind to IO', align: Alignment.center),
        ];

        TableRow rowFor(int idx, Map<String, dynamic> r) {
          final cr =
              (r['cr'] ?? r['cr_no'] ?? r['case_number'] ?? r['crNo'] ?? '')
                  .toString();

          final extra =
              r['extra_fields'] is Map ? r['extra_fields'] as Map : {};
          final sectionActRaw = r['section_act'] ??
              r['acts_sections'] ??
              r['sections'] ??
              r['section'] ??
              r['act_section'] ??
              r['sectionAct'] ??
              extra['section_act'] ??
              extra['acts_sections'] ??
              extra['sections'] ??
              extra['section'] ??
              extra['act_section'] ??
              extra['sectionAct'];
          final formattedSection =
              ExcelExportHelper.formatSectionAct(sectionActRaw);
          final sectionAct = formattedSection.isEmpty ? '-' : formattedSection;

          final rawAccused = r['accused_name'] ??
              r['accused'] ??
              extra['accused_name'] ??
              extra['accused'];
          final formattedAccused = ExcelExportHelper.formatAccused(rawAccused);
          final accusedName = formattedAccused.isEmpty ? '-' : formattedAccused;

          final headRaw = r['head'] ??
              r['sub_category'] ??
              r['subCategory'] ??
              r['title'] ??
              extra['head'] ??
              extra['crime_head'] ??
              '-';
          final head = headRaw.toString().trim().isEmpty
              ? '-'
              : headRaw.toString().trim();

          final ioName = (r['io_name'] ??
                  r['assigned_officer'] ??
                  r['io'] ??
                  extra['io_name'] ??
                  extra['assigned_officer'] ??
                  'Unassigned')
              .toString()
              .trim();

          final color = (r['fingerprint_status_color'] ??
                  r['nafis_status_color'] ??
                  extra['fingerprint_status_color'] ??
                  extra['nafis_status_color'] ??
                  '')
              .toString()
              .toLowerCase();
          final rawStatus = (r['fingerprint_status'] ??
                  r['nafis_status'] ??
                  extra['fingerprint_status'] ??
                  extra['nafis_status'] ??
                  r['status'] ??
                  '')
              .toString()
              .trim()
              .toLowerCase();
          final isGreen = color == 'green' ||
              color == 'taken' ||
              r['fingerprint_taken'] == true ||
              rawStatus == 'taken' ||
              rawStatus == 'done' ||
              rawStatus == 'chargesheeted' ||
              rawStatus == 'yes' ||
              rawStatus == 'true';
          final isPending = !isGreen;
          final statusLabel = r['status_label'] ??
              r['fingerprint_status'] ??
              (isPending ? 'Pending' : 'Done');

          final handleTap = onRowTap != null ? () => onRowTap!(idx, r) : null;

          final bg = idx.isEven ? Colors.white : const Color(0xFFF6F8FF);
          return TableRow(
            decoration: BoxDecoration(color: bg),
            children: [
              dataCell(
                r['sr_no']?.toString() ?? '${serialOffset + idx + 1}',
                align: Alignment.center,
                onTap: handleTap,
              ),
              dataCell(accusedName, onTap: handleTap),
              dataCell(cr, onTap: handleTap),
              dataCell(sectionAct, onTap: handleTap),
              dataCell(head, onTap: handleTap),
              dataCell(ioName.isEmpty ? 'Unassigned' : ioName,
                  onTap: handleTap),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                alignment: Alignment.center,
                child: statusBadge(isPending, label: statusLabel.toString()),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                alignment: Alignment.center,
                child: actionCell(idx, r, isPending),
              ),
            ],
          );
        }

        final maxH = constraints.maxHeight;

        final hasFiniteHeight = maxH.isFinite;
        final double estHeight = 44.0 * (rows.length + 1) + 20.0;
        final double containerHeight = hasFiniteHeight
            ? maxH
            : math.max(MediaQuery.of(context).size.height * 0.75, estHeight);

        final headerTable = Container(
          decoration: const BoxDecoration(
            color: AppColors.navyMid,
          ),
          child: Table(
            columnWidths: columnWidths,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: const TableBorder(
              verticalInside: BorderSide(color: Color(0x33FFFFFF), width: 1),
              bottom: BorderSide(color: AppColors.navyDark, width: 1.5),
            ),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: AppColors.navyMid),
                children: headers,
              ),
            ],
          ),
        );

        final colCount = headers.length;
        final bodyTable = Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Table(
            columnWidths: columnWidths,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: const TableBorder(
              horizontalInside: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              verticalInside: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
            children: rows.isEmpty
                ? [
                    TableRow(
                      children: [
                        for (var c = 0; c < colCount; c++)
                          dataCell(
                              c == 0 ? '-' : (c == 2 ? 'No records' : '-')),
                      ],
                    ),
                  ]
                : [
                    for (var i = 0; i < rows.length; i++) rowFor(i, rows[i]),
                  ],
          ),
        );

        final inner = Container(
          width: tableWidth,
          height: containerHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                headerTable,
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      scrollDirection: Axis.vertical,
                      child: bodyTable,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        return Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: inner,
          ),
        );
      },
    );
  }
}
