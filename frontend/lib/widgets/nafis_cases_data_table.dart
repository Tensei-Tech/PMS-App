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
        final double cellFontSize = isMobile ? 12.0 : 13.0;
        final double headerFontSize = isMobile ? 12.0 : 13.5;
        final double hPad = isMobile ? 10.0 : 14.0;
        final double vPad = isMobile ? 10.0 : 12.0;

        final double col0W = isMobile ? 60.0 : 70.0;
        final double col1W = isMobile ? 150.0 : 160.0;
        final double col2W = isMobile ? 100.0 : 110.0;
        final double col3W = isMobile ? 130.0 : 140.0;
        final double col4W = isMobile ? 120.0 : 130.0;
        final double col5W = isMobile ? 140.0 : 150.0;
        final double col6W = isMobile ? 100.0 : 110.0;
        final double col7W = isMobile ? 130.0 : 135.0;

        final double totalColumnsWidth = col0W +
            col1W +
            col2W +
            col3W +
            col4W +
            col5W +
            col6W +
            col7W;
        final double tableWidth = math.max(w, totalColumnsWidth);

        Widget headerCell(String s, {Alignment align = Alignment.centerLeft}) =>
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: hPad, vertical: vPad + 3),
              color: AppColors.navyDark,
              alignment: align,
              child: Text(
                s,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                textAlign: align == Alignment.center
                    ? TextAlign.center
                    : TextAlign.left,
                style: GoogleFonts.poppins(
                  fontSize: headerFontSize,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
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
          final content = Container(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            alignment: align,
            child: Text(
              s,
              maxLines: maxLines ?? 3,
              overflow: TextOverflow.ellipsis,
              textAlign:
                  align == Alignment.center ? TextAlign.center : TextAlign.left,
              style: GoogleFonts.poppins(
                fontSize: cellFontSize,
                fontWeight: fontWeight ?? FontWeight.w400,
                color: textColor ?? const Color(0xFF334155),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
                  fontSize: cellFontSize - 1.0,
                  fontWeight: FontWeight.w700,
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
                '-',
                style: GoogleFonts.poppins(
                  fontSize: cellFontSize + 2,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
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
                minimumSize: const Size(88, 30),
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
                  fontSize: cellFontSize - 1.0,
                  fontWeight: FontWeight.bold,
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
                0: FixedColumnWidth(70),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1.1),
                3: FlexColumnWidth(1.4),
                4: FlexColumnWidth(1.3),
                5: FlexColumnWidth(1.5),
                6: FixedColumnWidth(110),
                7: FixedColumnWidth(135),
              };

        final headers = <Widget>[
          headerCell('Sr. No.', align: Alignment.centerLeft),
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

          return TableRow(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
              ),
            ),
            children: [
              dataCell(
                r['sr_no']?.toString() ?? '${serialOffset + idx + 1}',
                align: Alignment.centerLeft,
                onTap: handleTap,
              ),
              dataCell(accusedName, onTap: handleTap),
              dataCell(cr, onTap: handleTap),
              dataCell(sectionAct, onTap: handleTap),
              dataCell(head, onTap: handleTap),
              dataCell(ioName.isEmpty ? 'Unassigned' : ioName,
                  onTap: handleTap),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                child: statusBadge(isPending, label: statusLabel.toString()),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
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
            color: AppColors.navyDark,
          ),
          child: Table(
            columnWidths: columnWidths,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: const TableBorder(
              verticalInside: BorderSide(color: Color(0xFF1E293B), width: 1),
              bottom: BorderSide(color: Color(0xFF1E293B), width: 1.5),
            ),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: AppColors.navyDark),
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
              horizontalInside: BorderSide(color: Color(0xFFEDF2F7), width: 1),
              verticalInside: BorderSide(color: Color(0xFFEDF2F7), width: 1),
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
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
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
