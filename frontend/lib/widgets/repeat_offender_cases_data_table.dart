import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class RepeatOffenderCasesDataTable extends StatelessWidget {
  const RepeatOffenderCasesDataTable({
    super.key,
    this.realDataRows,
    this.serialOffset = 0,
  });

  final List<Map<String, String>>? realDataRows;
  final int serialOffset;

  /// The ditto quotation symbol for repeated values
  static const String dittoSymbol = '""';

  /// Formats repeat offender rows so that consecutive repeating values
  /// (accused name, sec/act, head, police station) for the same offender display ditto quotation marks ("").
  static List<Map<String, String>> applyDittoFormatting(
      List<Map<String, String>> inputRows) {
    final result = <Map<String, String>>[];
    for (var idx = 0; idx < inputRows.length; idx++) {
      final r = inputRows[idx];
      final currName = (r['accused_name'] ?? '').trim();
      final currCr = (r['cr'] ?? '').trim();
      final currSections = (r['sections'] ?? '').trim();
      final currHead = (r['head'] ?? '').trim();
      final currStation = (r['station'] ?? '').trim();

      String dispName = currName.isEmpty ? '—' : currName;
      String dispSections = currSections.isEmpty ? '—' : currSections;
      String dispHead = currHead.isEmpty ? '—' : currHead;
      String dispStation = currStation.isEmpty ? '—' : currStation;

      if (idx > 0) {
        final prev = inputRows[idx - 1];
        final prevName = (prev['accused_name'] ?? '').trim();
        final prevSections = (prev['sections'] ?? '').trim();
        final prevHead = (prev['head'] ?? '').trim();
        final prevStation = (prev['station'] ?? '').trim();

        final isSameAccused = currName.isNotEmpty &&
            currName.toLowerCase() == prevName.toLowerCase();

        if (isSameAccused) {
          dispName = dittoSymbol;

          if (currSections.isNotEmpty &&
              currSections != '—' &&
              currSections != '-' &&
              currSections.toLowerCase() == prevSections.toLowerCase()) {
            dispSections = dittoSymbol;
          }

          if (currHead.isNotEmpty &&
              currHead != '—' &&
              currHead != '-' &&
              currHead.toLowerCase() == prevHead.toLowerCase()) {
            dispHead = dittoSymbol;
          }

          if (currStation.isNotEmpty &&
              currStation != '—' &&
              currStation != '-' &&
              currStation.toLowerCase() == prevStation.toLowerCase()) {
            dispStation = dittoSymbol;
          }
        }
      }

      final copy = Map<String, String>.from(r);
      copy['accused_name'] = dispName;
      copy['cr'] = currCr.isEmpty ? '—' : currCr;
      copy['sections'] = dispSections;
      copy['head'] = dispHead;
      copy['station'] = dispStation;
      result.add(copy);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final rawRows = realDataRows ?? [];
    final rows = applyDittoFormatting(rawRows);

    final tableCore = LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final double cellFontSize = w < 360 ? 9.5 : (w < 420 ? 10.5 : 11.5);
        final double headerFontSize = w < 360 ? 9.5 : (w < 420 ? 10.5 : 11.5);

        final columnWidths = <int, TableColumnWidth>{
          0: const IntrinsicColumnWidth(),
          1: const FlexColumnWidth(1.4),
          2: const FlexColumnWidth(1.2),
          3: const FlexColumnWidth(1.2),
          4: const FlexColumnWidth(1.4),
          5: const FlexColumnWidth(1.8),
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

        Widget dataCell(String s, {Alignment align = Alignment.center}) {
          final isDitto = s == dittoSymbol;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            alignment: isDitto ? Alignment.center : align,
            child: Text(
              s,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: GoogleFonts.poppins(
                fontSize: cellFontSize,
                fontWeight: isDitto ? FontWeight.w700 : FontWeight.w500,
                color: isDitto ? AppColors.navyMid : AppColors.lightText,
                height: 1.15,
              ),
            ),
          );
        }

        final headers = <Widget>[
          headerCell('Sr. No'),
          headerCell('Accused Name'),
          headerCell('Cr. No.'),
          headerCell('Sec/Act'),
          headerCell('Head'),
          headerCell('Police station'),
        ];

        TableRow rowFor(int idx, Map<String, String> r) {
          final bg = idx.isEven ? Colors.white : const Color(0xFFF6F8FF);
          final stationVal = r['station'] ?? '—';
          return TableRow(
            decoration: BoxDecoration(color: bg),
            children: [
              dataCell('${serialOffset + idx + 1}'),
              dataCell(r['accused_name'] ?? '—'),
              dataCell(r['cr'] ?? '—'),
              dataCell(r['sections'] ?? '—'),
              dataCell(r['head'] ?? '—'),
              dataCell(
                stationVal,
                align: stationVal == dittoSymbol
                    ? Alignment.center
                    : Alignment.centerLeft,
              ),
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
}
