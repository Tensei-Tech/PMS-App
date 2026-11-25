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
    this.groupedData,
  });

  final bool isAd;
  final List<Map<String, String>>? realDataRows;
  final int serialOffset;
  final Map<String, List<Map<String, String>>>? groupedData;

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
            0: FixedColumnWidth(65),
            1: FlexColumnWidth(1.1),
            2: FlexColumnWidth(1.3),
            3: FlexColumnWidth(1.3),
            4: FlexColumnWidth(1.5),
            5: FlexColumnWidth(1.2),
            6: FlexColumnWidth(1.4),
          };
        }

        Widget headerCell(String s, {Alignment align = Alignment.center}) =>
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              color: const Color(0xFFF8FAFC),
              alignment: align,
              child: Text(
                s,
                textAlign: align == Alignment.center
                    ? TextAlign.center
                    : TextAlign.left,
                softWrap: true,
                style: GoogleFonts.poppins(
                  fontSize: headerFontSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDark,
                  height: 1.15,
                ),
              ),
            );

        Widget dataCell(String s, {Alignment align = Alignment.center}) {
          final isDash = s.trim() == '—' || s.trim() == '-' || s.trim().isEmpty;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            alignment: align,
            child: Text(
              s.isEmpty ? '—' : s,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: cellFontSize,
                fontWeight: isDash ? FontWeight.w400 : FontWeight.w500,
                color: isDash ? const Color(0xFF94A3B8) : AppColors.navyDark,
                height: 1.15,
              ),
            ),
          );
        }

        final headers = <Widget>[
          headerCell('Sr. No'),
          headerCell('Cr. No.'),
          headerCell('Sec & Act', align: Alignment.centerLeft),
          headerCell('Head', align: Alignment.centerLeft),
          headerCell('Accused Name', align: Alignment.centerLeft),
          headerCell('Date of Arrest', align: Alignment.centerLeft),
          headerCell('IO Name', align: Alignment.centerLeft),
        ];

        TableRow rowFor(int idx, Map<String, String> r, [int? customSerial]) {
          final bg = (customSerial != null ? customSerial.isOdd : idx.isEven)
              ? Colors.white
              : const Color(0xFFF8FAFD);
          return TableRow(
            decoration: BoxDecoration(color: bg),
            children: [
              dataCell('${customSerial ?? (serialOffset + idx + 1)}'),
              dataCell(r['cr'] ?? '—'),
              dataCell(r['sections'] ?? '—', align: Alignment.centerLeft),
              dataCell(r['head'] ?? '—', align: Alignment.centerLeft),
              dataCell(
                  r['accused_name']?.isNotEmpty == true
                      ? r['accused_name']!
                      : '—',
                  align: Alignment.centerLeft),
              dataCell(r['arrest_date'] ?? '—', align: Alignment.centerLeft),
              dataCell(r['io'] ?? '—', align: Alignment.centerLeft),
            ],
          );
        }

        final isGrouped = groupedData != null && groupedData!.isNotEmpty;
        final maxH = constraints.maxHeight;
        final hasFiniteHeight = maxH.isFinite;

        final headerTable = Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
          ),
          child: Table(
            columnWidths: columnWidths,
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: const TableBorder(
              verticalInside: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              bottom: BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
            ),
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
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
              horizontalInside: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              verticalInside: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
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

        final List<Widget> groupWidgets = [];
        if (isGrouped) {
          var globalSerial = serialOffset;
          for (final entry in groupedData!.entries) {
            if (entry.value.isEmpty) continue;
            groupWidgets.add(
              Container(
                width: tableWidth,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  border: Border(
                    top: BorderSide(color: Color(0xFFCBD5E1), width: 1),
                    bottom: BorderSide(color: Color(0xFFCBD5E1), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.navyMid.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.lock_person_outlined,
                        size: 14,
                        color: AppColors.navyMid,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.key,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Text(
                        '${entry.value.length} ${entry.value.length == 1 ? 'case' : 'cases'}',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );

            groupWidgets.add(
              Container(
                decoration: const BoxDecoration(color: Colors.white),
                child: Table(
                  columnWidths: columnWidths,
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  border: const TableBorder(
                    horizontalInside:
                        BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    verticalInside:
                        BorderSide(color: Color(0xFFE2E8F0), width: 1),
                    bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                  ),
                  children: [
                    for (var i = 0; i < entry.value.length; i++)
                      rowFor(i, entry.value[i], ++globalSerial),
                  ],
                ),
              ),
            );
          }
        }

        final Widget contentToScroll = isGrouped
            ? (groupWidgets.isEmpty
                ? bodyTable
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: groupWidgets,
                  ))
            : bodyTable;

        final inner = Container(
          width: tableWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: hasFiniteHeight
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      headerTable,
                      Expanded(
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: contentToScroll,
                          ),
                        ),
                      ),
                    ],
                  )
                : IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        headerTable,
                        contentToScroll,
                      ],
                    ),
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
