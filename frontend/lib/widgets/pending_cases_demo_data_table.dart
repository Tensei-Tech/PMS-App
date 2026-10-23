// lib/widgets/pending_cases_demo_data_table.dart
// Shared pending demo [Table] — same layout as [PendingDemoTableScreen].

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class PendingCasesDemoDataTable extends StatelessWidget {
  const PendingCasesDemoDataTable({
    super.key,
    required this.isAd,
    this.realDataRows,
    this.serialOffset = 0,
    this.isAbsconded = false,
    this.isVictim = false,
  });

  final bool isAd;
  final List<Map<String, String>>? realDataRows;
  final int serialOffset;
  final bool isAbsconded;
  final bool isVictim;

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
              dataCell(r['cr'] ?? '—'),
              dataCell(r['sections'] ?? '—'),
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
              dataCell(r['io'] ?? '—', align: Alignment.centerLeft),
              dataCell(r['station'] ?? '—', align: Alignment.centerLeft),
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
