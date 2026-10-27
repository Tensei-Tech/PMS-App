import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../modules/core/models/base_record.dart';
import '../services/backend_case_service.dart';
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
        final double cellFontSize = w < 400 ? 11.5 : 13.0;
        final double headerFontSize = w < 400 ? 12.0 : 13.5;

        Widget headerCell(String s, {Alignment align = Alignment.centerLeft}) =>
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              alignment: align,
              child: Text(
                s,
                textAlign: align == Alignment.center
                    ? TextAlign.center
                    : TextAlign.left,
                style: GoogleFonts.poppins(
                  fontSize: headerFontSize,
                  fontWeight: FontWeight.w600,
                  color:
                      const Color(0xFF1E293B), // Navy/Slate matching screenshot
                ),
              ),
            );

        Widget dataCell(
          String s, {
          Alignment align = Alignment.centerLeft,
          Color? textColor,
          FontWeight? fontWeight,
          int? maxLines,
        }) =>
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              alignment: align,
              child: Text(
                s,
                maxLines: maxLines ?? 3,
                overflow: TextOverflow.ellipsis,
                textAlign: align == Alignment.center
                    ? TextAlign.center
                    : TextAlign.left,
                style: GoogleFonts.poppins(
                  fontSize: cellFontSize,
                  fontWeight: fontWeight ?? FontWeight.w400,
                  color: textColor ?? const Color(0xFF334155),
                ),
              ),
            );

        Widget statusBadge(bool isPending) {
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isPending
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isPending ? 'Pending' : 'Done',
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
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: const Size(80, 30),
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
                style: GoogleFonts.poppins(
                  fontSize: cellFontSize - 1.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }

        final columnWidths = <int, TableColumnWidth>{
          0: const FixedColumnWidth(70), // Sr. No.
          1: const FlexColumnWidth(1.4), // Accused Name
          2: const FlexColumnWidth(1.2), // CR No.
          3: const FlexColumnWidth(1.4), // Section/Act
          4: const FlexColumnWidth(1.4), // Head
          5: const FlexColumnWidth(1.5), // IO Name
          6: const FixedColumnWidth(130), // Status
          7: const FixedColumnWidth(130), // Action
        };

        final headers = <Widget>[
          headerCell('Sr. No.', align: Alignment.centerLeft),
          headerCell('Accused Name'),
          headerCell('CR No.'),
          headerCell('Section/Act'),
          headerCell('Head'),
          headerCell('IO Name'),
          headerCell('Status', align: Alignment.center),
          headerCell('Action', align: Alignment.center),
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

          final color =
              (r['nafis_status_color'] ?? '').toString().toLowerCase();
          final rawStatus =
              (r['nafis_status'] ?? r['status'] ?? '').toString().trim();
          final isGreen = color == 'green' ||
              rawStatus.toLowerCase() == 'done' ||
              rawStatus.toLowerCase() == 'chargesheeted';
          final isPending = !isGreen;

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
              ),
              dataCell(accusedName),
              dataCell(cr),
              dataCell(sectionAct),
              dataCell(head),
              dataCell(ioName.isEmpty ? 'Unassigned' : ioName),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                child: statusBadge(isPending),
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

        return Container(
          width: double.infinity,
          height: maxH.isFinite ? maxH : null,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: w > 900 ? w : 900),
                  child: Table(
                    columnWidths: columnWidths,
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                        ),
                        children: headers,
                      ),
                      for (var i = 0; i < rows.length; i++) rowFor(i, rows[i]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
