// lib/modules/preventive/utils/preventive_form_pdf.dart
// Generates official Excel/Tabular PDF reports for Preventive / Istegasha action records.

import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../screens/ad_form_screen.dart' show ACT_DATA;
import '../../../utils/pdf_unicode_fonts.dart';

class PreventiveFormPdfHelper {
  // Palette matching clean Excel / official police register design
  static const _kDark = PdfColor.fromInt(0xFF0F172A);
  static const _kHeaderBg = PdfColor.fromInt(0xFFE2E8F0);
  static const _kLabelBg = PdfColor.fromInt(0xFFF1F5F9);
  static const _kRowAltBg = PdfColor.fromInt(0xFFF8FAFC);
  static const _kGreen = PdfColor.fromInt(0xFF059669);
  static const _kRed = PdfColor.fromInt(0xFFDC2626);
  static const _kAmber = PdfColor.fromInt(0xFFD97706);
  static const _kSec = PdfColor.fromInt(0xFF475569);
  static const _kBorder = PdfColor.fromInt(0xFFCBD5E1);
  static const _kWhite = PdfColors.white;

  /// Sanitizes text by stripping emojis or special symbol glyphs that cause missing font boxes
  static String _cleanText(dynamic v) {
    if (v == null) return '—';
    var s = v.toString().trim();
    if (s.isEmpty) return '—';
    // Remove emoji and symbol unicode ranges
    s = s
        .replaceAll(
          RegExp(
            r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{200D}\u{FE0F}\u{2611}\u{2610}\u{2705}\u{274C}]',
            unicode: true,
          ),
          '',
        )
        .trim();
    return s.isEmpty ? '—' : s;
  }

  /// Resolves raw section numbers (e.g. "25", "101") to their full descriptive titles (e.g. "25 - Unlawful Possession of Arms")
  static String _resolveSectionFullName(String? actKey, dynamic rawSections) {
    if (rawSections == null) return '—';

    List<String> sectionList = [];
    if (rawSections is List) {
      sectionList = rawSections
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else {
      final s = rawSections.toString().trim();
      if (s.isEmpty || s == '—') return '—';
      sectionList = s
          .split(RegExp(r'[,;]\s*'))
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }

    if (sectionList.isEmpty) return '—';

    // Build fast lookup dictionary from ACT_DATA master mapping
    final Map<String, String> actSectionMap = {};
    for (final actEntry in ACT_DATA.entries) {
      final act = actEntry.key.toUpperCase();
      final secList = actEntry.value['sections'] as List<dynamic>? ?? [];
      for (final sec in secList) {
        if (sec is Map) {
          final val = sec['val']?.toString().trim() ?? '';
          final label = sec['label']?.toString().trim() ?? '';
          if (val.isNotEmpty && label.isNotEmpty) {
            actSectionMap['$act:$val'.toUpperCase()] = label;
            actSectionMap['$act $val'.toUpperCase()] = label;
            actSectionMap[val.toUpperCase()] = label;
          }
        }
      }
    }

    final normalizedAct = (actKey ?? '').trim().toUpperCase();

    final resolved = sectionList.map((sec) {
      final cleanSec = sec.trim();
      if (cleanSec.contains(' - ')) return cleanSec; // Already full title

      // 1. Check with specific Act prefix: "ARMS:25"
      final keyWithAct = '$normalizedAct:$cleanSec'.toUpperCase();
      if (actSectionMap.containsKey(keyWithAct)) {
        return actSectionMap[keyWithAct]!;
      }

      // 2. Strip prefix if user stored "ARMS 25"
      final rawKey = cleanSec
          .replaceAll(RegExp(r'^[A-Za-z_]+\s*'), '')
          .trim()
          .toUpperCase();
      final keyWithActStripped = '$normalizedAct:$rawKey'.toUpperCase();
      if (actSectionMap.containsKey(keyWithActStripped)) {
        return actSectionMap[keyWithActStripped]!;
      }

      if (actSectionMap.containsKey(cleanSec.toUpperCase())) {
        return actSectionMap[cleanSec.toUpperCase()]!;
      }

      if (actSectionMap.containsKey(rawKey)) {
        return actSectionMap[rawKey]!;
      }

      return cleanSec;
    }).toList();

    return resolved.join(', ');
  }

  /// Generates printable PDF bytes for a Preventive Action / Istegasha record in Excel format.
  static Future<Uint8List> generatePdf({
    required Map<String, dynamic> data,
    String? policeStation,
    String? district,
    PdfPageFormat format = PdfPageFormat.a4,
  }) async {
    final formMap = (data['preventiveForm'] is Map<String, dynamic>)
        ? data['preventiveForm'] as Map<String, dynamic>
        : data;

    final caseRef = formMap['caseRef'] as Map<String, dynamic>? ?? {};
    final sections = formMap['sections'] as Map<String, dynamic>? ?? {};
    final accusedList = formMap['accusedList'] as List<dynamic>? ?? [];
    List<dynamic> effectiveAccusedList = List<dynamic>.from(accusedList);
    if (effectiveAccusedList.isEmpty) {
      final legacyAccused =
          (data['accusedNames'] ?? data['accused'])?.toString().trim() ?? '';
      if (legacyAccused.isNotEmpty) {
        effectiveAccusedList = [
          {
            'name': legacyAccused,
            'actionType': '—',
            'bondTaken': '—',
            'bondDetails': '—',
          }
        ];
      }
    }
    final istegasha = formMap['istegasha'] as Map<String, dynamic>? ?? {};
    final riskAndStatus =
        formMap['riskAndStatus'] as Map<String, dynamic>? ?? {};

    final crimeNo = _cleanText(
      caseRef['crimeNo']?.toString().isNotEmpty == true
          ? caseRef['crimeNo']
          : (data['caseNumber'] ?? data['case_number'] ?? '—'),
    );
    final regDate = _cleanText(caseRef['regDate']);
    final crimeCategory = _cleanText(caseRef['crimeCategory']);
    final caseStatus = _cleanText(
      caseRef['caseStatus']?.toString().isNotEmpty == true
          ? caseRef['caseStatus']
          : (data['status'] ?? '—'),
    );

    final selectedAct = _cleanText(sections['act']);
    final selectedSections = _resolveSectionFullName(
      selectedAct,
      sections['selectedSections'] ??
          sections['sections'] ??
          data['selectedSections'] ??
          data['sections'],
    );
    final otherSections = _cleanText(sections['otherSections']);

    final preventiveSectionAct = _cleanText(
      istegasha['preventiveSectionAct']?.toString().isNotEmpty == true
          ? istegasha['preventiveSectionAct']
          : (data['preventiveSectionAct'] ??
              data['preventiveSecAct'] ??
              data['preventiveAct'] ??
              istegasha['act'] ??
              '—'),
    );

    final preventiveNo = _cleanText(istegasha['preventiveNo']);
    final preventiveDate = _cleanText(istegasha['preventiveDate']);
    final outwardNo = _cleanText(istegasha['outwardNo']);
    final ioName = _cleanText(
      istegasha['ioName']?.toString().isNotEmpty == true
          ? istegasha['ioName']
          : (data['assignedOfficer'] ?? data['assigned_officer'] ?? '—'),
    );

    final riskFlag = _cleanText(
      riskAndStatus['riskFlag']?.toString().isNotEmpty == true
          ? riskAndStatus['riskFlag']
          : (data['priority'] ?? '—'),
    );
    final actionStatus = _cleanText(riskAndStatus['actionStatus']);
    final remarks = _cleanText(riskAndStatus['remarks']);

    final psLabel = (policeStation != null && policeStation.isNotEmpty)
        ? policeStation
        : (district != null && district.isNotEmpty
            ? district
            : 'Maharashtra Police');
    final distLabel = (district != null && district.isNotEmpty) ? district : '';

    pw.ThemeData theme;
    try {
      final fonts = await Future.wait([
        PdfGoogleFonts.openSansRegular(),
        PdfGoogleFonts.openSansBold(),
        PdfGoogleFonts.notoSansDevanagariRegular(),
        PdfGoogleFonts.notoSansDevanagariBold(),
      ]).timeout(const Duration(seconds: 2));

      theme = pw.ThemeData.withFont(
        base: fonts[0],
        bold: fonts[1],
        fontFallback: [fonts[2], fonts[3]],
      );
    } catch (_) {
      try {
        final unicode = await PdfUnicodeFonts.openSansTheme()
            .timeout(const Duration(seconds: 2));
        theme = unicode;
      } catch (_) {
        theme = pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        );
      }
    }

    final doc = pw.Document(theme: theme);
    final printTime = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        maxPages: 100,
        theme: theme,
        pageFormat: format,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        header: (pw.Context ctx) => ctx.pageNumber == 1
            ? _buildCleanHeader(psLabel, distLabel, printTime)
            : pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                padding: const pw.EdgeInsets.only(bottom: 4),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: _kBorder, width: 0.5),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'PREVENTIVE ACTION & ISTEGASHA REPORT — $crimeNo',
                      style: const pw.TextStyle(fontSize: 7.5, color: _kSec),
                    ),
                    pw.Text(
                      'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                      style: const pw.TextStyle(fontSize: 7.5, color: _kSec),
                    ),
                  ],
                ),
              ),
        footer: (pw.Context ctx) => _buildFooter(ctx),
        build: (pw.Context ctx) => [
          // Section 1: Case & Crime Reference (Excel Table)
          _buildExcelSectionHeader(
              '1', 'CASE & CRIME REFERENCE', 'गुन्हा व खटला संदर्भ'),
          pw.Table(
            border: pw.TableBorder.all(color: _kBorder, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.2),
              1: pw.FlexColumnWidth(2.8),
              2: pw.FlexColumnWidth(2.0),
              3: pw.FlexColumnWidth(3.0),
            },
            children: [
              pw.TableRow(
                children: [
                  _buildLabelCell('Crime / FIR / NC No.'),
                  _buildValueCell(crimeNo, isBold: true),
                  _buildLabelCell('Arrest Date'),
                  _buildValueCell(regDate),
                ],
              ),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _kRowAltBg),
                children: [
                  _buildLabelCell('Crime Category'),
                  _buildValueCell(crimeCategory),
                  _buildLabelCell('Case Status'),
                  _buildValueCell(caseStatus),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),

          // Section 2: Acts & Sections (Excel Table)
          _buildExcelSectionHeader(
              '2', 'ACTS & SECTIONS (BNS / OTHER ACTS)', 'कलमे व कायदे'),
          pw.Table(
            border: pw.TableBorder.all(color: _kBorder, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.8),
              1: pw.FlexColumnWidth(2.0),
              2: pw.FlexColumnWidth(1.8),
              3: pw.FlexColumnWidth(4.4),
            },
            children: [
              pw.TableRow(
                children: [
                  _buildLabelCell('Selected Act'),
                  _buildValueCell(selectedAct),
                  _buildLabelCell('Sections (कलमे)'),
                  _buildValueCell(selectedSections, isBold: true),
                ],
              ),
              if (otherSections != '—' && otherSections.isNotEmpty)
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _kRowAltBg),
                  children: [
                    _buildLabelCell('Other / Custom Sections'),
                    _buildValueCell(otherSections),
                    _buildLabelCell(''),
                    _buildValueCell(''),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 8),

          // Section 3: Accused & Action Table (Excel Table)
          _buildExcelSectionHeader(
            '3',
            'ACCUSED & PREVENTIVE ACTION DETAILS',
            'आरोपी व प्रतिबंधक कारवाई तपशील',
          ),
          effectiveAccusedList.isEmpty
              ? pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _kBorder, width: 0.5),
                  ),
                  child: pw.Text(
                    'No accused records entered',
                    style: const pw.TextStyle(fontSize: 8, color: _kSec),
                  ),
                )
              : pw.Table(
                  border: pw.TableBorder.all(color: _kBorder, width: 0.5),
                  columnWidths: const {
                    0: pw.FixedColumnWidth(24),
                    1: pw.FlexColumnWidth(3.0),
                    2: pw.FlexColumnWidth(2.2),
                    3: pw.FlexColumnWidth(1.6),
                    4: pw.FlexColumnWidth(3.2),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: _kLabelBg),
                      children: [
                        _buildTh('#'),
                        _buildTh('Accused Name (नाव)'),
                        _buildTh('Action / Status'),
                        _buildTh('Bond Taken'),
                        _buildTh('Bond Amount / Surety Details'),
                      ],
                    ),
                    for (int i = 0; i < effectiveAccusedList.length; i++)
                      pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: i % 2 == 1 ? _kRowAltBg : _kWhite,
                        ),
                        children: [
                          _buildTd('${i + 1}', alignCenter: true),
                          _buildTd(
                            _cleanText(
                              effectiveAccusedList[i] is Map
                                  ? effectiveAccusedList[i]['name']
                                  : effectiveAccusedList[i],
                            ),
                            isBold: true,
                          ),
                          _buildTd(
                            _cleanText(
                              effectiveAccusedList[i] is Map
                                  ? effectiveAccusedList[i]['actionType']
                                  : null,
                            ),
                          ),
                          _buildTd(
                            _cleanText(
                              effectiveAccusedList[i] is Map
                                  ? effectiveAccusedList[i]['bondTaken']
                                  : null,
                            ),
                            alignCenter: true,
                          ),
                          _buildTd(
                            _cleanText(
                              effectiveAccusedList[i] is Map
                                  ? effectiveAccusedList[i]['bondDetails']
                                  : null,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
          pw.SizedBox(height: 8),

          // Section 4: Preventive & Istegasha Details (Excel Table)
          _buildExcelSectionHeader('4', 'PREVENTIVE & ISTEGASHA DETAILS',
              'प्रतिबंधक / इस्तेगाशा तपशील'),
          pw.Table(
            border: pw.TableBorder.all(color: _kBorder, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.2),
              1: pw.FlexColumnWidth(2.8),
              2: pw.FlexColumnWidth(2.0),
              3: pw.FlexColumnWidth(3.0),
            },
            children: [
              pw.TableRow(
                children: [
                  _buildLabelCell('Preventive Section Act'),
                  _buildValueCell(preventiveSectionAct, isBold: true),
                  _buildLabelCell('Preventive No. (इस्तेगाशा क्र.)'),
                  _buildValueCell(preventiveNo, isBold: true),
                ],
              ),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _kRowAltBg),
                children: [
                  _buildLabelCell('Date of Preventive'),
                  _buildValueCell(preventiveDate),
                  _buildLabelCell('Outward No. (जावक क्र.)'),
                  _buildValueCell(outwardNo),
                ],
              ),
              pw.TableRow(
                children: [
                  _buildLabelCell('Investigating Officer (IO)'),
                  _buildValueCell(ioName, isBold: true),
                  _buildLabelCell(''),
                  _buildValueCell(''),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 8),

          // Section 5: Risk Flag & Action Status (Excel Table)
          _buildExcelSectionHeader(
            '5',
            'RISK FLAG & PREVENTIVE ACTION STATUS',
            'जोखीम ध्वज व कारवाई स्थिती',
          ),
          pw.Table(
            border: pw.TableBorder.all(color: _kBorder, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.2),
              1: pw.FlexColumnWidth(2.8),
              2: pw.FlexColumnWidth(2.0),
              3: pw.FlexColumnWidth(3.0),
            },
            children: [
              pw.TableRow(
                children: [
                  _buildLabelCell('Risk Flag (जोखीम)'),
                  _buildStatusCell(riskFlag, isRisk: true),
                  _buildLabelCell('Action Status (कारवाई स्थिती)'),
                  _buildStatusCell(actionStatus, isRisk: false),
                ],
              ),
              if (remarks != '—' && remarks.isNotEmpty)
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _kRowAltBg),
                  children: [
                    _buildLabelCell('Remarks / Summary'),
                    _buildValueCell(remarks),
                    _buildLabelCell(''),
                    _buildValueCell(''),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 18),

          // Signature Block
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(width: 140, height: 0.8, color: _kBorder),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Investigating Officer (IO)',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: _kDark,
                    ),
                  ),
                  pw.Text(
                    ioName,
                    style: const pw.TextStyle(fontSize: 7.5, color: _kSec),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(width: 140, height: 0.8, color: _kBorder),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Police Station In-Charge / PI',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: _kDark,
                    ),
                  ),
                  pw.Text(
                    'Seal & Signature',
                    style: const pw.TextStyle(fontSize: 7, color: _kSec),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ── Clean Document Header & Footer ──────────────────────────────────────────
  static pw.Widget _buildCleanHeader(
    String psLabel,
    String distLabel,
    String printTime,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _kDark, width: 1.2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'PREVENTIVE ACTION & ISTEGASHA REPORT',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _kDark,
                  letterSpacing: 0.5,
                ),
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                'प्रतिबंधक कारवाई / इस्तेगाशा नोंद अहवाल',
                style: const pw.TextStyle(fontSize: 8, color: _kSec),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                '$psLabel ${distLabel.isNotEmpty ? '• $distLabel' : ''}',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: _kDark,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _kRed, width: 0.6),
                  borderRadius: pw.BorderRadius.circular(2),
                ),
                child: pw.Text(
                  'CONFIDENTIAL',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                    color: _kRed,
                  ),
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'Date: $printTime',
                style: const pw.TextStyle(fontSize: 7, color: _kSec),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _kBorder, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Khakhi Diary · Crime Monitoring & Preventive Action System',
            style: const pw.TextStyle(fontSize: 6.5, color: _kSec),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 6.5, color: _kSec),
          ),
        ],
      ),
    );
  }

  // ── Excel Table Helpers ───────────────────────────────────────────────────
  static pw.Widget _buildExcelSectionHeader(
    String secNum,
    String title,
    String marathiTitle,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: const pw.BoxDecoration(
        color: _kHeaderBg,
        border: pw.Border(
          top: pw.BorderSide(color: _kBorder, width: 0.5),
          left: pw.BorderSide(color: _kBorder, width: 0.5),
          right: pw.BorderSide(color: _kBorder, width: 0.5),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 12,
            height: 12,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: _kDark,
              borderRadius: pw.BorderRadius.circular(2),
            ),
            child: pw.Text(
              secNum,
              style: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                color: _kWhite,
              ),
            ),
          ),
          pw.SizedBox(width: 5),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: _kDark,
            ),
          ),
          pw.SizedBox(width: 4),
          pw.Text(
            '($marathiTitle)',
            style: const pw.TextStyle(fontSize: 6.5, color: _kSec),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildLabelCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
      color: _kLabelBg,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: _kSec,
        ),
      ),
    );
  }

  static pw.Widget _buildValueCell(String text, {bool isBold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
      child: pw.Text(
        text.isEmpty ? '—' : text,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: _kDark,
        ),
      ),
    );
  }

  static pw.Widget _buildStatusCell(String value, {required bool isRisk}) {
    PdfColor color = _kDark;
    final valLower = value.toLowerCase();
    if (isRisk) {
      if (valLower.contains('high')) {
        color = _kRed;
      } else if (valLower.contains('sensitive')) {
        color = _kAmber;
      }
    } else {
      if (valLower.contains('completed')) {
        color = _kGreen;
      } else if (valLower.contains('partial')) {
        color = _kAmber;
      } else if (valLower.contains('no')) {
        color = _kRed;
      }
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
      child: pw.Text(
        value.isEmpty ? '—' : value,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _buildTh(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: _kDark,
        ),
      ),
    );
  }

  static pw.Widget _buildTd(
    String text, {
    bool isBold = false,
    bool alignCenter = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
      child: pw.Text(
        text.isEmpty ? '—' : text,
        textAlign: alignCenter ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: _kDark,
        ),
      ),
    );
  }

  /// Prints or directly downloads generated PDF to local PC.
  static Future<void> printPdf({
    required Map<String, dynamic> data,
    String? policeStation,
    String? district,
  }) async {
    final pForm = data['preventiveForm'];
    final caseRef = (pForm is Map) ? pForm['caseRef'] : null;
    final crimeNo = ((caseRef is Map) ? caseRef['crimeNo'] : null) ??
        data['crimeNo'] ??
        data['caseNumber'] ??
        '';
    final sanitizeNo = crimeNo.toString().replaceAll(RegExp(r'[^\w\d_-]'), '_');
    final fileName = sanitizeNo.isNotEmpty
        ? 'Preventive_Report_${sanitizeNo}_${DateTime.now().millisecondsSinceEpoch}.pdf'
        : 'Preventive_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';

    final bytes = await generatePdf(
      data: data,
      policeStation: policeStation,
      district: district,
    );

    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }
}
