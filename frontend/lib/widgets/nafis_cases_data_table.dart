import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../modules/core/models/base_record.dart';
import 'send_reminder_dialog.dart';

class NAFISCasesDataTable extends StatelessWidget {
  const NAFISCasesDataTable({
    super.key,
    this.realDataRows,
    this.rawRecords,
    this.serialOffset = 0,
    this.onRowTap,
  });

  final List<Map<String, dynamic>>? realDataRows;
  final List<ModuleRecord>? rawRecords;
  final int serialOffset;
  final void Function(int index, Map<String, dynamic> row)? onRowTap;

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
                textAlign: align == Alignment.center ? TextAlign.center : TextAlign.left,
                style: GoogleFonts.poppins(
                  fontSize: headerFontSize,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B), // Navy/Slate matching screenshot
                ),
              ),
            );

        Widget dataCell(
          String s, {
          Alignment align = Alignment.centerLeft,
          Color? textColor,
          FontWeight? fontWeight,
        }) =>
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              alignment: align,
              child: Text(
                s,
                textAlign: align == Alignment.center ? TextAlign.center : TextAlign.left,
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: isPending ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isPending ? 'Pending' : 'Chargesheeted',
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

          return Center(
            child: InkWell(
              onTap: () {
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
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Remind to IO',
                  style: GoogleFonts.poppins(
                    fontSize: cellFontSize - 1.0,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        }

        final columnWidths = <int, TableColumnWidth>{
          0: const FixedColumnWidth(80),   // Sr. No.
          1: const FlexColumnWidth(1.2),   // CR No.
          2: const FlexColumnWidth(1.4),   // Section/Act
          3: const FlexColumnWidth(1.8),   // Accused Name
          4: const FixedColumnWidth(150),  // Status
          5: const FixedColumnWidth(160),  // Action
        };

        final headers = <Widget>[
          headerCell('Sr. No.', align: Alignment.centerLeft),
          headerCell('CR No.'),
          headerCell('Section/Act'),
          headerCell('Accused Name'),
          headerCell('Status', align: Alignment.center),
          headerCell('Action', align: Alignment.center),
        ];

        TableRow rowFor(int idx, Map<String, dynamic> r) {
          final cr = (r['cr'] ?? r['cr_no'] ?? r['case_number'] ?? r['crNo'] ?? '').toString();
          
          final sectionAct = (r['section_act'] ??
                  r['sections'] ??
                  r['section'] ??
                  r['act_section'] ??
                  r['acts_sections'] ??
                  '')
              .toString();

          final extra = r['extra_fields'] is Map ? r['extra_fields'] as Map : {};
          String accused = (r['accused_name'] ??
                  r['accused'] ??
                  extra['accused_name'] ??
                  extra['accused'] ??
                  '')
              .toString();
          if (accused.isEmpty && rawRecords != null && idx < rawRecords!.length) {
            accused = rawRecords![idx].accused;
          }

          final rawStatus = (r['nafis_status'] ?? r['status'] ?? '').toString().trim();
          final isPending = rawStatus.toLowerCase() == 'pending' ||
              rawStatus.toLowerCase() == 'no' ||
              rawStatus.isEmpty;

          return TableRow(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
              ),
            ),
            children: [
              dataCell('${serialOffset + idx + 1}', align: Alignment.centerLeft),
              dataCell(cr),
              dataCell(sectionAct),
              dataCell(accused.isEmpty ? '—' : accused),
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
                  constraints: BoxConstraints(minWidth: w > 750 ? w : 750),
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
