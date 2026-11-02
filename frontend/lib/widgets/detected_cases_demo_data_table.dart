// lib/widgets/pending_cases_demo_data_table.dart
// Shared pending demo [Table] — same layout as [PendingDemoTableScreen].

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class DetectedCasesDemoDataTable extends StatelessWidget {
  const DetectedCasesDemoDataTable({
    super.key,
    required this.isAd,
    this.realDataRows,
    this.serialOffset = 0,
  });

  final bool isAd;
  final List<Map<String, String>>? realDataRows;
  final int serialOffset;

  @override
  Widget build(BuildContext context) {
    final rows = realDataRows ?? [];

    final tableCore = LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final double cellFontSize = w < 360 ? 9.5 : (w < 420 ? 10.5 : 11.5);
        final double headerFontSize = w < 360 ? 9.5 : (w < 420 ? 10.5 : 11.5);

        final columnWidths = <int, TableColumnWidth>{
          0: const FixedColumnWidth(55),
          1: const FlexColumnWidth(1.1),
          2: const FlexColumnWidth(1.3),
          3: const FlexColumnWidth(1.3),
          4: const FlexColumnWidth(1.6),
          5: const FlexColumnWidth(1.4),
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

        final headers = <Widget>[
          headerCell('Sr. No'),
          headerCell('Cr. No.'),
          headerCell('SEC/ACT'),
          headerCell('Head'),
          headerCell('Accused Name'),
          headerCell('IO Name'),
        ];

        TableRow rowFor(int idx, Map<String, String> r) {
          final bg = idx.isEven ? Colors.white : const Color(0xFFF6F8FF);
          return TableRow(
            decoration: BoxDecoration(color: bg),
            children: [
              dataCell('${serialOffset + idx + 1}'),
              dataCell(r['cr']?.isNotEmpty == true ? r['cr']! : '-'),
              dataCell(
                  r['sections']?.isNotEmpty == true ? r['sections']! : '-'),
              dataCell(r['head']?.isNotEmpty == true ? r['head']! : '-'),
              dataCell(r['accused']?.isNotEmpty == true ? r['accused']! : '-',
                  align: Alignment.centerLeft),
              dataCell(r['io']?.isNotEmpty == true ? r['io']! : '-',
                  align: Alignment.centerLeft),
            ],
          );
        }

        final maxH = constraints.maxHeight;
        final inner = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.lightBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Sticky Fixed Blue Header ──
                Container(
                  color: AppColors.navyDark,
                  child: Table(
                    columnWidths: columnWidths,
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      TableRow(
                        decoration:
                            const BoxDecoration(color: AppColors.navyDark),
                        children: headers,
                      ),
                    ],
                  ),
                ),
                // ── Scrollable Case Rows ──
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: maxH.isFinite
                        ? (maxH - 45).clamp(100.0, 10000.0)
                        : 520.0,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Table(
                      columnWidths: columnWidths,
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      border: const TableBorder(
                        horizontalInside:
                            BorderSide(color: Color(0xFFEDF2F7), width: 1),
                        verticalInside:
                            BorderSide(color: Color(0xFFEDF2F7), width: 1),
                      ),
                      children: [
                        for (var i = 0; i < rows.length; i++) rowFor(i, rows[i]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        return inner;
      },
    );
    return tableCore;
  }
}
