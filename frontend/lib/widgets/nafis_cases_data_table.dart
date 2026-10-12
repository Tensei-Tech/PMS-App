import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../modules/core/models/base_record.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/police_rbac_helper.dart';
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
    final auth = context.watch<AuthProvider>();
    final canSendReminder = PoliceRbacHelper.canSendReminder(auth);

    final tableCore = LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final double cellFontSize = w < 360 ? 9.5 : (w < 420 ? 10.5 : 11.5);
        final double headerFontSize = w < 360 ? 9.5 : (w < 420 ? 10.5 : 11.5);

        Widget headerCell(String s, {int flex = 1}) => Container(
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

        Widget dataCell(
          String s, {
          Alignment align = Alignment.center,
          Color? textColor,
          FontWeight? fontWeight,
        }) =>
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              alignment: align,
              child: Text(
                s,
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

        Widget pendingStatusBadge(String statusText) {
          final isPending = statusText.trim().toLowerCase() == 'pending' ||
              statusText.trim().toLowerCase() == 'no' ||
              statusText.isEmpty;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPending ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isPending ? const Color(0xFFEF5350) : const Color(0xFF66BB6A),
                width: 1,
              ),
            ),
            child: Text(
              isPending ? 'Pending' : 'Completed',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: cellFontSize - 0.5,
                fontWeight: FontWeight.w700,
                color: isPending ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
              ),
            ),
          );
        }

        Widget reminderActionCell(int idx, Map<String, dynamic> r) {
          if (!canSendReminder) {
            return dataCell('—');
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            alignment: Alignment.center,
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
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFEF5350)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_active_rounded,
                      size: 13,
                      color: Color(0xFFC62828),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Reminder',
                      style: GoogleFonts.poppins(
                        fontSize: cellFontSize - 1,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFC62828),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final columnWidths = <int, TableColumnWidth>{
          0: const IntrinsicColumnWidth(), // Sr. No
          1: const FlexColumnWidth(1.2), // Cr. No.
          2: const FlexColumnWidth(1.4), // SEC & ACT
          3: const FlexColumnWidth(1.4), // Accused Name
          4: const FlexColumnWidth(1.4), // IO Name
          5: const FlexColumnWidth(1.6), // Station Name
          6: const FlexColumnWidth(1.2), // Status (Red Pending)
          if (canSendReminder) 7: const FlexColumnWidth(1.3), // Action
        };

        final headers = <Widget>[
          headerCell('Sr. No'),
          headerCell('Cr. No.'),
          headerCell('SEC & ACT'),
          headerCell('Accused Name'),
          headerCell('IO Name'),
          headerCell('Police station name'),
          headerCell('NAFIS Status'),
          if (canSendReminder) headerCell('Action (PI)'),
        ];

        TableRow rowFor(int idx, Map<String, dynamic> r) {
          final bg = idx.isEven ? Colors.white : const Color(0xFFF6F8FF);
          final cr = r['cr']?.toString() ?? r['case_number']?.toString() ?? '—';
          final sections = r['sections']?.toString() ?? '—';
          final accused = r['accused_name']?.toString() ?? r['accused']?.toString() ?? '—';
          final io = r['io_name']?.toString() ?? r['io']?.toString() ?? r['assigned_officer']?.toString() ?? '—';
          final station = r['station']?.toString() ?? r['station_name']?.toString() ?? '—';
          final status = r['nafis_status']?.toString() ?? 'Pending';

          return TableRow(
            decoration: BoxDecoration(color: bg),
            children: [
              dataCell('${serialOffset + idx + 1}'),
              dataCell(cr),
              dataCell(sections),
              dataCell(accused.isEmpty ? '—' : accused),
              dataCell(io.isEmpty ? '—' : io, align: Alignment.centerLeft),
              dataCell(station.isEmpty ? '—' : station, align: Alignment.centerLeft),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                alignment: Alignment.center,
                child: pendingStatusBadge(status),
              ),
              if (canSendReminder) reminderActionCell(idx, r),
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
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: w > 720 ? w : 720),
                  child: Table(
                    columnWidths: columnWidths,
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: AppColors.lightBorder.withValues(alpha: 0.5),
                        width: 1,
                      ),
                      verticalInside: BorderSide(
                        color: AppColors.lightBorder.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    children: [
                      TableRow(children: headers),
                      for (var i = 0; i < rows.length; i++) rowFor(i, rows[i]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        return inner;
      },
    );

    return tableCore;
  }
}
