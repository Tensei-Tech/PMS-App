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
        final isSmall = w < 480;
        final double cellFontSize = isSmall ? 10.5 : 12.0;
        final double headerFontSize = isSmall ? 10.5 : 12.0;

        final columnWidths = <int, TableColumnWidth>{
          0: isSmall ? const FixedColumnWidth(48) : const FixedColumnWidth(65),
          1: const FlexColumnWidth(1.2),
          2: const FlexColumnWidth(1.5),
          3: const FlexColumnWidth(2.0),
        };

        Widget headerCell(String s, {Alignment align = Alignment.center}) =>
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 6 : 12,
                vertical: isSmall ? 8 : 11,
              ),
              color: AppColors.navyDark,
              alignment: align,
              child: Text(
                s,
                textAlign: align == Alignment.centerLeft
                    ? TextAlign.left
                    : TextAlign.center,
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
              padding: EdgeInsets.symmetric(
                horizontal: isSmall ? 6 : 12,
                vertical: isSmall ? 8 : 10,
              ),
              alignment: align,
              child: Text(
                s.isEmpty ? '—' : s,
                softWrap: true,
                textAlign: align == Alignment.centerLeft
                    ? TextAlign.left
                    : TextAlign.center,
                overflow: TextOverflow.visible,
                style: GoogleFonts.poppins(
                  fontSize: cellFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppColors.lightText,
                  height: 1.25,
                ),
              ),
            );

        final headers = <Widget>[
          headerCell('Sr. No'),
          headerCell('Cr. No.'),
          headerCell('SEC & ACT', align: Alignment.centerLeft),
          headerCell('Accused name', align: Alignment.centerLeft),
        ];

        TableRow rowFor(int idx, Map<String, String> r) {
          final bg = idx.isEven ? Colors.white : const Color(0xFFF8FAFD);
          return TableRow(
            decoration: BoxDecoration(color: bg),
            children: [
              dataCell('${serialOffset + idx + 1}'),
              dataCell(r['cr'] ?? '—'),
              dataCell(r['sections'] ?? '—', align: Alignment.centerLeft),
              dataCell(r['accused'] ?? '—', align: Alignment.centerLeft),
            ],
          );
        }

        final inner = ClipRRect(
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
        return inner;
      },
    );
    return tableCore;
  }
}
