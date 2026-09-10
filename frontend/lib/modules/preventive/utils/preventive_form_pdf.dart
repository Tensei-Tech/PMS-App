// lib/modules/preventive/utils/preventive_form_pdf.dart
// Generates ultra-smooth official PDF reports for Preventive / Istegasha action records.

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../utils/pdf_unicode_fonts.dart';

class PreventiveFormPdfHelper {
  // Palette matching Maharashtra Police design
  static const _kDark = PdfColor.fromInt(0xFF0F172A);
  static const _kTeal = PdfColor.fromInt(0xFF0EA5E9);
  static const _kGreen = PdfColor.fromInt(0xFF10B981);
  static const _kRed = PdfColor.fromInt(0xFFEF4444);
  static const _kAmber = PdfColor.fromInt(0xFFF59E0B);
  static const _kSec = PdfColor.fromInt(0xFF64748B);
  static const _kBg = PdfColor.fromInt(0xFFF8FAFC);
  static const _kBorder = PdfColor.fromInt(0xFFE2E8F0);
  static const _kWhite = PdfColors.white;

  /// Generates printable PDF bytes for a Preventive Action / Istegasha record.
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
    final istegasha = formMap['istegasha'] as Map<String, dynamic>? ?? {};
    final riskAndStatus =
        formMap['riskAndStatus'] as Map<String, dynamic>? ?? {};

    final crimeNo = caseRef['crimeNo']?.toString().isNotEmpty == true
        ? caseRef['crimeNo']
        : (data['caseNumber'] ?? data['case_number'] ?? '—');
    final regDate = caseRef['regDate']?.toString().isNotEmpty == true
        ? caseRef['regDate']
        : '—';
    final crimeCategory =
        caseRef['crimeCategory']?.toString().isNotEmpty == true
            ? caseRef['crimeCategory']
            : '—';
    final caseStatus = caseRef['caseStatus']?.toString().isNotEmpty == true
        ? caseRef['caseStatus']
        : (data['status'] ?? '—');

    final selectedAct =
        sections['act']?.toString().isNotEmpty == true ? sections['act'] : '—';
    final selectedSections = (sections['selectedSections'] is List)
        ? (sections['selectedSections'] as List).join(', ')
        : (sections['selectedSections']?.toString() ?? '—');
    final otherSections =
        sections['otherSections']?.toString().isNotEmpty == true
            ? sections['otherSections']
            : '—';

    final preventiveNo =
        istegasha['preventiveNo']?.toString().isNotEmpty == true
            ? istegasha['preventiveNo']
            : '—';
    final preventiveDate =
        istegasha['preventiveDate']?.toString().isNotEmpty == true
            ? istegasha['preventiveDate']
            : '—';
    final outwardNo = istegasha['outwardNo']?.toString().isNotEmpty == true
        ? istegasha['outwardNo']
        : '—';
    final ioName = istegasha['ioName']?.toString().isNotEmpty == true
        ? istegasha['ioName']
        : (data['assignedOfficer'] ?? data['assigned_officer'] ?? '—');

    final riskFlag = riskAndStatus['riskFlag']?.toString().isNotEmpty == true
        ? riskAndStatus['riskFlag']
        : (data['priority'] ?? '—');
    final actionStatus =
        riskAndStatus['actionStatus']?.toString().isNotEmpty == true
            ? riskAndStatus['actionStatus']
            : '—';
    final remarks = riskAndStatus['remarks']?.toString().isNotEmpty == true
        ? riskAndStatus['remarks']
        : '—';

    final subtitle = [
      if (policeStation != null && policeStation.isNotEmpty) policeStation,
      if (district != null && district.isNotEmpty) district,
      'Maharashtra Police · Preventive Action / इस्तेगाशा नोंद',
    ].join(' · ');

    pw.ThemeData theme;
    try {
      theme = pw.ThemeData.withFont(
        base: await PdfGoogleFonts.openSansRegular(),
        bold: await PdfGoogleFonts.openSansBold(),
        italic: await PdfGoogleFonts.openSansItalic(),
        boldItalic: await PdfGoogleFonts.openSansBoldItalic(),
      );
    } catch (_) {
      theme = await PdfUnicodeFonts.openSansTheme();
    }

    final doc = pw.Document(theme: theme);
    final printTime = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        maxPages: 100,
        pageFormat: format,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context ctx) => ctx.pageNumber == 1
            ? _buildHeader(subtitle, printTime)
            : pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.only(bottom: 6),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                      bottom: pw.BorderSide(color: _kBorder, width: 0.5)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'PREVENTIVE ACTION & ISTEGASHA REPORT — $crimeNo',
                      style: const pw.TextStyle(fontSize: 8, color: _kSec),
                    ),
                    pw.Text(
                      'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                      style: const pw.TextStyle(fontSize: 8, color: _kSec),
                    ),
                  ],
                ),
              ),
        footer: (pw.Context ctx) => _buildFooter(ctx),
        build: (pw.Context ctx) => [
          // Section 1: Case & Crime Reference
          _buildSectionCard(
            secNum: '1',
            title: 'CASE & CRIME REFERENCE',
            marathiTitle: 'गुन्हा व खटला संदर्भ',
            content: pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: _buildKvItem(
                          'Crime No. / FIR No. / NC No.', crimeNo.toString(),
                          isHighlight: true),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      flex: 2,
                      child:
                          _buildKvItem('Registration Date', regDate.toString()),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: _buildKvItem(
                          'Crime Category', crimeCategory.toString()),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      flex: 2,
                      child: _buildKvItem('Case Status', caseStatus.toString()),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Section 2: Acts & Sections
          _buildSectionCard(
            secNum: '2',
            title: 'ACTS & SECTIONS (BNS / OTHER ACTS)',
            marathiTitle: 'कलमे व कायदे',
            content: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 1,
                      child:
                          _buildKvItem('Selected Act', selectedAct.toString()),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      flex: 2,
                      child: _buildKvItem(
                          'Sections (कलमे)', selectedSections.toString()),
                    ),
                  ],
                ),
                if (otherSections.toString().trim() != '—' &&
                    otherSections.toString().trim().isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  _buildKvItem(
                      'Other / Custom Sections', otherSections.toString()),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Section 3: Accused & Action Table
          _buildSectionCard(
            secNum: '3',
            title: 'ACCUSED & PREVENTIVE ACTION DETAILS',
            marathiTitle: 'आरोपी व प्रतिबंधक कारवाई तपशील',
            content: accusedList.isEmpty
                ? pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('No accused records entered',
                        style: const pw.TextStyle(fontSize: 9, color: _kSec)),
                  )
                : pw.Table(
                    border: pw.TableBorder.all(color: _kBorder, width: 0.5),
                    columnWidths: const {
                      0: pw.FixedColumnWidth(28),
                      1: pw.FlexColumnWidth(3),
                      2: pw.FlexColumnWidth(2),
                      3: pw.FlexColumnWidth(1.5),
                      4: pw.FlexColumnWidth(3),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: _kBg),
                        children: [
                          _buildTh('#'),
                          _buildTh('Accused Name (नाव)'),
                          _buildTh('Action / Status'),
                          _buildTh('Bond Taken'),
                          _buildTh('Bond Amount / Surety Details'),
                        ],
                      ),
                      for (int i = 0; i < accusedList.length; i++)
                        pw.TableRow(
                          decoration: pw.BoxDecoration(
                            color: i % 2 == 1
                                ? const PdfColor.fromInt(0xFFFAFAFA)
                                : _kWhite,
                          ),
                          children: [
                            _buildTd('${i + 1}', alignCenter: true),
                            _buildTd(accusedList[i]['name']?.toString() ?? '—',
                                isBold: true),
                            _buildTd(accusedList[i]['actionType']?.toString() ??
                                '—'),
                            _buildTd(
                                accusedList[i]['bondTaken']?.toString() ?? '—',
                                alignCenter: true),
                            _buildTd(
                                accusedList[i]['bondDetails']?.toString() ??
                                    '—'),
                          ],
                        ),
                    ],
                  ),
          ),
          pw.SizedBox(height: 12),

          // Section 4: Preventive & Istegasha Details
          _buildSectionCard(
            secNum: '4',
            title: 'PREVENTIVE & ISTEGASHA DETAILS',
            marathiTitle: 'प्रतिबंधक / इस्तेगाशा तपशील',
            content: pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildKvItem('Preventive No. / इस्तेगाशा नंबर',
                          preventiveNo.toString(),
                          isHighlight: true),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: _buildKvItem(
                          'Date of Preventive', preventiveDate.toString()),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildKvItem(
                          'Outward Number (जावक क्र.)', outwardNo.toString()),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: _buildKvItem(
                          'Investigating Officer (IO)', ioName.toString()),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // Section 5: Risk Flag & Action Status
          _buildSectionCard(
            secNum: '5',
            title: 'RISK FLAG & PREVENTIVE ACTION STATUS',
            marathiTitle: 'जोखीम ध्वज व कारवाई स्थिती',
            content: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildStatusBadge('Risk Flag', riskFlag.toString(),
                          isRisk: true),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: _buildStatusBadge(
                          'Action Status', actionStatus.toString(),
                          isRisk: false),
                    ),
                  ],
                ),
                if (remarks.toString().trim() != '—' &&
                    remarks.toString().trim().isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  _buildKvItem('Remarks / Case Summary', remarks.toString()),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Signature Block
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(width: 140, height: 1, color: _kBorder),
                  pw.SizedBox(height: 4),
                  pw.Text('Investigating Officer (IO)',
                      style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: _kDark)),
                  pw.Text(ioName.toString(),
                      style: const pw.TextStyle(fontSize: 8, color: _kSec)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(width: 140, height: 1, color: _kBorder),
                  pw.SizedBox(height: 4),
                  pw.Text('Police Station In-Charge / PI',
                      style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: _kDark)),
                  pw.Text('Seal & Signature',
                      style: const pw.TextStyle(fontSize: 7, color: _kSec)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ── Header & Footer Helpers ────────────────────────────────────────────────
  static pw.Widget _buildHeader(String subtitle, String printTime) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: pw.BoxDecoration(
        color: _kDark,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'MAHARASHTRA POLICE',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: _kWhite,
                  letterSpacing: 1,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'PREVENTIVE ACTION & ISTEGASHA REPORT (प्रतिबंधक कारवाई / इस्तेगाशा अहवाल)',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: _kAmber,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                subtitle,
                style: const pw.TextStyle(fontSize: 7, color: _kSec),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('CONFIDENTIAL',
                  style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: _kRed)),
              pw.SizedBox(height: 2),
              pw.Text('Date: $printTime',
                  style: const pw.TextStyle(fontSize: 7, color: _kSec)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _kBorder, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Khakhi Diary · Crime Monitoring & Preventive Action System',
              style: const pw.TextStyle(fontSize: 7, color: _kSec)),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 7, color: _kSec)),
        ],
      ),
    );
  }

  // ── Card & Content Helpers ─────────────────────────────────────────────────
  static pw.Widget _buildSectionCard({
    required String secNum,
    required String title,
    required String marathiTitle,
    required pw.Widget content,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _kBorder, width: 0.6),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: const pw.BoxDecoration(
              color: _kBg,
              borderRadius:
                  pw.BorderRadius.vertical(top: pw.Radius.circular(5)),
              border:
                  pw.Border(bottom: pw.BorderSide(color: _kBorder, width: 0.5)),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 14,
                  height: 14,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    color: _kDark,
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Text(
                    secNum,
                    style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: _kWhite),
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Text(
                  title,
                  style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: _kDark),
                ),
                pw.SizedBox(width: 6),
                pw.Text(
                  '($marathiTitle)',
                  style: const pw.TextStyle(fontSize: 7, color: _kSec),
                ),
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: content,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildKvItem(String label, String value,
      {bool isHighlight = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: pw.BoxDecoration(
        color: isHighlight ? const PdfColor.fromInt(0xFFF0F9FF) : _kBg,
        borderRadius: pw.BorderRadius.circular(4),
        border:
            pw.Border.all(color: isHighlight ? _kTeal : _kBorder, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 7, color: _kSec)),
          pw.SizedBox(height: 2),
          pw.Text(
            value.isEmpty ? '—' : value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight:
                  isHighlight ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isHighlight ? _kDark : _kDark,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatusBadge(String label, String value,
      {required bool isRisk}) {
    PdfColor badgeColor = _kTeal;
    PdfColor bgColor = const PdfColor.fromInt(0xFFF0F9FF);

    final valLower = value.toLowerCase();
    if (isRisk) {
      if (valLower.contains('high')) {
        badgeColor = _kRed;
        bgColor = const PdfColor.fromInt(0xFFFEE2E2);
      } else if (valLower.contains('sensitive')) {
        badgeColor = _kAmber;
        bgColor = const PdfColor.fromInt(0xFFFEF3C7);
      }
    } else {
      if (valLower.contains('completed')) {
        badgeColor = _kGreen;
        bgColor = const PdfColor.fromInt(0xFFECFDF5);
      } else if (valLower.contains('partial')) {
        badgeColor = _kAmber;
        bgColor = const PdfColor.fromInt(0xFFFFFBEB);
      } else if (valLower.contains('no')) {
        badgeColor = _kRed;
        bgColor = const PdfColor.fromInt(0xFFFEF2F2);
      }
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: badgeColor, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 7, color: _kSec)),
          pw.SizedBox(height: 2),
          pw.Text(
            value.isEmpty ? '—' : value,
            style: pw.TextStyle(
                fontSize: 9, fontWeight: pw.FontWeight.bold, color: badgeColor),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTh(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
            fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _kDark),
      ),
    );
  }

  static pw.Widget _buildTd(String text,
      {bool isBold = false, bool alignCenter = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text.isEmpty ? '—' : text,
        textAlign: alignCenter ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: _kDark,
        ),
      ),
    );
  }

  /// Prints or opens share sheet with generated PDF.
  static Future<void> printPdf({
    required Map<String, dynamic> data,
    String? policeStation,
    String? district,
  }) async {
    final fileName =
        'Preventive_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final bytes = await generatePdf(
      data: data,
      policeStation: policeStation,
      district: district,
    );
    try {
      if (kIsWeb) {
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: fileName,
        );
      } else {
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name: fileName,
        );
      }
    } catch (_) {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    }
  }
}
