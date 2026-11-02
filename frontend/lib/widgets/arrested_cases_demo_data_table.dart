import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class ArrestedCasesDemoDataTable extends StatelessWidget {
  const ArrestedCasesDemoDataTable({
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

        final isMobile = constraints.maxWidth < 650;
        final double tableWidth;
        final Map<int, TableColumnWidth> columnWidths;

        if (isMobile) {
          const srWidth = 48.0;
          final colUnitW = (constraints.maxWidth - srWidth) / 2.5;
          final col4W = math.max(colUnitW * 1.3, 130.0);
          final col5W = math.max(colUnitW * 1.0, 100.0);
          final col6W = math.max(colUnitW * 1.15, 120.0);
          tableWidth = srWidth + (colUnitW * 3) + col4W + col5W + col6W;

          columnWidths = <int, TableColumnWidth>{
            0: const FixedColumnWidth(srWidth),
            1: FixedColumnWidth(colUnitW),
            2: FixedColumnWidth(colUnitW),
            3: FixedColumnWidth(colUnitW),
            4: FixedColumnWidth(col4W),
            5: FixedColumnWidth(col5W),
            6: FixedColumnWidth(col6W),
          };
        } else {
          tableWidth = math.max(constraints.maxWidth, 850.0);
          columnWidths = const <int, TableColumnWidth>{
            0: IntrinsicColumnWidth(),
            1: FlexColumnWidth(1.1),
            2: FlexColumnWidth(1.3),
            3: FlexColumnWidth(1.3),
            4: FlexColumnWidth(1.5),
            5: FlexColumnWidth(1.2),
            6: FlexColumnWidth(1.4),
          };
        }

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
          headerCell('Head'),
          headerCell('Accused Name'),
          headerCell('Date of Arrest'),
          headerCell('IO Name'),
        ];

        TableRow rowFor(int idx, Map<String, String> r) {
          final bg = idx.isEven ? Colors.white : const Color(0xFFF8FAFD);
          return TableRow(
            decoration: BoxDecoration(color: bg),
            children: [
              dataCell('${serialOffset + idx + 1}'),
              dataCell(r['cr'] ?? '—'),
              dataCell(r['sections'] ?? '—'),
              dataCell(r['head'] ?? '—'),
              dataCell(
                  r['accused_name']?.isNotEmpty == true
                      ? r['accused_name']!
                      : '—',
                  align: Alignment.centerLeft),
              dataCell(r['arrest_date'] ?? '—'),
              dataCell(r['io'] ?? '—', align: Alignment.centerLeft),
            ],
          );
        }

        final maxH = constraints.maxHeight;
        final hasFiniteHeight = maxH.isFinite;
        final double estHeight = 44.0 * (rows.length + 1) + 20.0;
        final double containerHeight = hasFiniteHeight
            ? maxH
            : math.min(MediaQuery.of(context).size.height * 0.65, estHeight);

        final headerTable = Container(
          decoration: const BoxDecoration(
            color: AppColors.navyDark,
          ),
          child: Table(
            columnWidths: columnWidths,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: const TableBorder(
              verticalInside: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: AppColors.navyDark),
                children: headers,
              ),
            ],
          ),
        );

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
                        for (var c = 0; c < 7; c++)
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
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                headerTable,
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
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
    return tableCore;
  }
}
