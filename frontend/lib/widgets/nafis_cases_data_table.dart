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
        final isTiny = w < 450;
        final isSmall = w < 720;
        final double cellFontSize = isTiny ? 9.5 : (isSmall ? 10.5 : 11.5);
        final double headerFontSize = isTiny ? 9.5 : (isSmall ? 10.5 : 11.5);

        Widget headerCell(String s, {Alignment align = Alignment.center}) =>
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTiny ? 4 : (isSmall ? 6 : 8),
                vertical: isTiny ? 6 : 9,
              ),
              color: AppColors.navyDark,
              alignment: align,
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

        Widget dataCell(
          String s, {
          Alignment align = Alignment.center,
          Color? textColor,
          FontWeight? fontWeight,
        }) =>
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTiny ? 4 : (isSmall ? 6 : 8),
                vertical: isTiny ? 6 : 8,
              ),
              alignment: align,
              child: Text(
                s,
                textAlign: align == Alignment.center
                    ? TextAlign.center
                    : TextAlign.left,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: GoogleFonts.poppins(
                  fontSize: cellFontSize,
                  fontWeight: fontWeight ?? FontWeight.w500,
                  color: textColor ?? AppColors.lightText,
                  height: 1.15,
                ),
              ),
            );

        Widget statusBadge(bool isPending) {
          return Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTiny ? 6 : 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: isPending
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                isPending ? 'Pending' : 'Done',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: (cellFontSize - 1.0).clamp(8.5, 11.0),
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
                '—',
                style: GoogleFonts.poppins(
                  fontSize: cellFontSize + 1,
                  fontWeight: FontWeight.w500,
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
                padding: EdgeInsets.symmetric(
                  horizontal: isTiny ? 4 : 6,
                  vertical: 0,
                ),
                minimumSize: Size(isTiny ? 52 : 62, 26),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
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
                isTiny ? 'Remind' : 'Remind to IO',
                style: GoogleFonts.poppins(
                  fontSize: (cellFontSize - 1.5).clamp(8.5, 10.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }

        final columnWidths = <int, TableColumnWidth>{
          0: isTiny
              ? const FixedColumnWidth(40)
              : (isSmall ? const FixedColumnWidth(48) : const FixedColumnWidth(55)),
          1: const FlexColumnWidth(1.15),
          2: const FlexColumnWidth(1.3),
          3: const FlexColumnWidth(1.05),
          4: const FlexColumnWidth(1.15),
          5: const FlexColumnWidth(0.85),
          6: const FlexColumnWidth(1.05),
        };

        final headers = <Widget>[
          headerCell('Sr. No.'),
          headerCell('CR No.'),
          headerCell('Section/Act'),
          headerCell('Charge Sheet Date'),
          headerCell('IO Name'),
          headerCell('Status'),
          headerCell('Action'),
        ];

        TableRow rowFor(int idx, Map<String, dynamic> r) {
          final bg = idx.isEven ? Colors.white : const Color(0xFFF8FAFD);
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
          final sectionAct = formattedSection.isEmpty ? '—' : formattedSection;

          final chargeSheetDate = (r['charge_sheet_date'] ??
                  r['chargesheet_date'] ??
                  extra['charge_sheet_date'] ??
                  extra['chargeSheetDate'] ??
                  extra['cs_date'] ??
                  '')
              .toString()
              .trim();

          final ioName = (r['io_name'] ??
                  r['assigned_officer'] ??
                  r['io'] ??
                  extra['io_name'] ??
                  extra['assigned_officer'] ??
                  'Unassigned')
              .toString()
              .trim();

          final rawStatus = (r['nafis_status'] ??
                  extra['nafis_status'] ??
                  r['status'] ??
                  '')
              .toString()
              .trim()
              .toLowerCase();
          final statusColor = (r['nafis_status_color'] ??
                  extra['nafis_status_color'] ??
                  '')
              .toString()
              .trim()
              .toLowerCase();
          final isGreen = statusColor == 'green' ||
              rawStatus == 'done' ||
              rawStatus == 'chargesheeted' ||
              rawStatus == 'yes' ||
              rawStatus == 'true';
          final isPending = !isGreen;

          return TableRow(
            decoration: BoxDecoration(color: bg),
            children: [
              dataCell('${serialOffset + idx + 1}'),
              dataCell(cr.isEmpty ? '—' : cr),
              dataCell(sectionAct),
              dataCell(chargeSheetDate.isEmpty ? 'Pending' : chargeSheetDate),
              dataCell(ioName.isEmpty ? 'Unassigned' : ioName,
                  align: Alignment.centerLeft),
              statusBadge(isPending),
              actionCell(idx, r, isPending),
            ],
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Table(
              columnWidths: columnWidths,
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: const TableBorder(
                horizontalInside:
                    BorderSide(color: Color(0xFFEDF2F7), width: 1),
                verticalInside:
                    BorderSide(color: Color(0xFFEDF2F7), width: 1),
              ),
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
      },
    );
  }
}
