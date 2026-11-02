import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class RepeatOffenderCasesDataTable extends StatefulWidget {
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
  State<RepeatOffenderCasesDataTable> createState() =>
      _RepeatOffenderCasesDataTableState();
}

class _RepeatOffenderCasesDataTableState
    extends State<RepeatOffenderCasesDataTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rawRows = widget.realDataRows ?? [];
    final rows = RepeatOffenderCasesDataTable.applyDittoFormatting(rawRows);

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
          final colUnitW = math.max((constraints.maxWidth - srWidth) / 2.5, 90.0);
          final col1W = math.max(colUnitW * 1.3, 140.0);
          final col2W = math.max(colUnitW * 1.1, 110.0);
          final col3W = math.max(colUnitW * 1.0, 100.0);
          final col4W = math.max(colUnitW * 1.2, 120.0);
          final col5W = math.max(colUnitW * 1.4, 150.0);
          tableWidth = srWidth + col1W + col2W + col3W + col4W + col5W;

          columnWidths = <int, TableColumnWidth>{
            0: const FixedColumnWidth(srWidth),
            1: FixedColumnWidth(col1W),
            2: FixedColumnWidth(col2W),
            3: FixedColumnWidth(col3W),
            4: FixedColumnWidth(col4W),
            5: FixedColumnWidth(col5W),
          };
        } else {
          tableWidth = math.max(constraints.maxWidth, 850.0);
          columnWidths = const <int, TableColumnWidth>{
            0: FixedColumnWidth(55.0),
            1: FlexColumnWidth(1.4),
            2: FlexColumnWidth(1.2),
            3: FlexColumnWidth(1.2),
            4: FlexColumnWidth(1.4),
            5: FlexColumnWidth(1.8),
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

        Widget dataCell(String s, {Alignment align = Alignment.center}) {
          final isDitto = s == RepeatOffenderCasesDataTable.dittoSymbol;
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
              dataCell('${widget.serialOffset + idx + 1}'),
              dataCell(r['accused_name'] ?? '—'),
              dataCell(r['cr'] ?? '—'),
              dataCell(r['sections'] ?? '—'),
              dataCell(r['head'] ?? '—'),
              dataCell(
                stationVal,
                align: stationVal == RepeatOffenderCasesDataTable.dittoSymbol
                    ? Alignment.center
                    : Alignment.centerLeft,
              ),
            ],
          );
        }

        final maxH = constraints.maxHeight;
        final hasFiniteHeight = maxH.isFinite;
        final double estHeight = 44.0 * (rows.length + 1) + 20.0;
        final double containerHeight = hasFiniteHeight
            ? maxH
            : math.min(MediaQuery.of(context).size.height * 0.70, estHeight);

        final headerTable = Container(
          decoration: const BoxDecoration(
            color: AppColors.navyDark,
          ),
          child: Table(
            columnWidths: columnWidths,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: const TableBorder(
              verticalInside:
                  BorderSide(color: Color(0xFFE2E8F0), width: 1),
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
              horizontalInside:
                  BorderSide(color: Color(0xFFEDF2F7), width: 1),
              verticalInside:
                  BorderSide(color: Color(0xFFEDF2F7), width: 1),
            ),
            children: rows.isEmpty
                ? [
                    TableRow(
                      children: [
                        for (var c = 0; c < 6; c++)
                          dataCell(
                              c == 0 ? '-' : (c == 1 ? 'No repeat offender records' : '-')),
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightBorder, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                headerTable,
                Expanded(
                  child: Scrollbar(
                    controller: _verticalController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _verticalController,
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
          controller: _horizontalController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: inner,
          ),
        );
      },
    );
    return tableCore;
  }
}
