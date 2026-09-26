// lib/utils/reason_of_arrest_pdf.dart
//
// Official, high-performance PDF generator for Reason of Arrest Notice (सुचनापत्र)
// u/s 35(1)(b)(ii) BNSS, 2023.
// Generates both pages in authentic Maharashtra Police format with:
// - Proportional page layouts that eliminate empty bottom white voids
// - Authentic Devanagari typography with deep navy blue ink (#0D47A1) for values
// - Structured multi-line reason blocks for Reasons 1 to 5 on Page 1
// - Balanced paragraph spacing, statutory note banner, and official signature/stamp boxes on Page 2
// - Static font caching and preloading for instant (< 150ms) generation speed.

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'form_image_pdf_helper.dart';
import 'pdf_font_cache.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Font Caching & Preloading
// ──────────────────────────────────────────────────────────────────────────────

pw.Font? _cachedDevanagariRegular;
pw.Font? _cachedDevanagariBold;

Future<void> preloadReasonOfArrestPdfFonts() async {
  try {
    _cachedDevanagariRegular ??= await PdfFontCache.devanagariRegular();
    _cachedDevanagariBold ??= await PdfFontCache.devanagariBold();
  } catch (_) {}
}

const _kInkColor = Color(0xFF0D47A1);
final _kPdfInkColor = PdfColor.fromHex('#0D47A1');

// ──────────────────────────────────────────────────────────────────────────────
// Public API
// ──────────────────────────────────────────────────────────────────────────────

Future<void> previewReasonOfArrestPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final fileName =
      'Reason_of_Arrest_${DateTime.now().millisecondsSinceEpoch}.pdf';
  final section = (doc['formSection']?.toString() ?? '').toLowerCase();
  final showMain = section.isEmpty ||
      (section.contains('main') && !section.contains('continuation'));
  final showCont = section.isEmpty || section.contains('continuation');

  final pages = <Widget>[];
  if (showMain) pages.add(_buildPg1Widget(doc));
  if (showCont) pages.add(_buildPg2Widget(doc));

  await FormImagePdfHelper.previewImageBasedPdf(
    context,
    fileName: fileName,
    pages: pages,
    fallbackPdfGenerator: () => generateReasonOfArrestPdf(doc),
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// Vector PDF Generator (Instant, high quality fallback)
// ──────────────────────────────────────────────────────────────────────────────

Future<Uint8List> generateReasonOfArrestPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();

  // Load / retrieve cached fonts with fallback
  pw.Font devanagari;
  pw.Font devanagariBold;

  try {
    _cachedDevanagariRegular ??= await PdfFontCache.devanagariRegular();
    devanagari = _cachedDevanagariRegular!;
  } catch (_) {
    devanagari = pw.Font.helvetica();
  }

  try {
    _cachedDevanagariBold ??= await PdfFontCache.devanagariBold();
    devanagariBold = _cachedDevanagariBold!;
  } catch (_) {
    devanagariBold = pw.Font.helveticaBold();
  }

  final regular = pw.TextStyle(
    font: devanagari,
    fontSize: 11,
    lineSpacing: 3.5,
    color: PdfColors.black,
  );
  final bold = pw.TextStyle(
    font: devanagariBold,
    fontSize: 11,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.black,
  );
  final valueStyle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 11,
    fontWeight: pw.FontWeight.bold,
    color: _kPdfInkColor,
  );
  final headerStyle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 12.5,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.black,
  );
  final titleStyle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 18,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.black,
  );

  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  final outwardNo = v('outwardNo');
  final outwardYear = v('outwardYear');
  final policeStation = v('policeStation', v('subjectPs'));
  final taluka = v('taluka', v('ioTaluka'));
  final district = v('district', v('ioDistrict'));
  final noticeDate = v('noticeDate');
  final accusedNameAddress = v('accusedNameAddress');
  final subjectPs = v('subjectPs', policeStation);
  final subjectCrNo = v('subjectCrNo');
  final subjectSection = v('subjectSection');
  final ioName = v('ioName', v('ioNameRank'));

  final section = v('formSection').toLowerCase();
  final showMain = section.isEmpty ||
      (section.contains('main') && !section.contains('continuation'));
  final showCont = section.isEmpty || section.contains('continuation');

  const lightBorder = pw.BorderSide(color: PdfColors.grey400, width: 0.6);

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 1: Vector Layout (Proportional & Filled)
  // ══════════════════════════════════════════════════════════════════════════
  if (showMain) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 34),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Top Header
            pw.Center(
              child: pw.Text(
                'भारतीय नागरीक सुरक्षा संहिता, २०२३ चे कलम ३५ (१)(ब)(ii) नुसार अन्वये',
                style: headerStyle,
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 6),

            // Title
            pw.Center(
              child: pw.Text(
                'सुचनापत्र',
                style: titleStyle,
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 12),

            // Right-aligned dispatch details
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Container(
                width: 260,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text('जावक.क्रमांक- ', style: bold),
                        pw.Expanded(
                          child: pw.Container(
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(bottom: lightBorder),
                            ),
                            child: pw.Text(
                              outwardNo.isNotEmpty
                                  ? '$outwardNo / $outwardYear'
                                  : '        /        ',
                              style:
                                  outwardNo.isNotEmpty ? valueStyle : regular,
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Row(
                      children: [
                        pw.Text('पोलीस स्टेशन ', style: bold),
                        pw.Expanded(
                          child: pw.Container(
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(bottom: lightBorder),
                            ),
                            child: pw.Text(
                              policeStation.isNotEmpty ? policeStation : ' ',
                              style: policeStation.isNotEmpty
                                  ? valueStyle
                                  : regular,
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Row(
                      children: [
                        pw.Text('ता. ', style: bold),
                        pw.Expanded(
                          flex: 5,
                          child: pw.Container(
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(bottom: lightBorder),
                            ),
                            child: pw.Text(
                              taluka.isNotEmpty ? taluka : ' ',
                              style: taluka.isNotEmpty ? valueStyle : regular,
                            ),
                          ),
                        ),
                        pw.Text(' -जिल्हा ', style: bold),
                        pw.Expanded(
                          flex: 5,
                          child: pw.Container(
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(bottom: lightBorder),
                            ),
                            child: pw.Text(
                              district.isNotEmpty ? district : ' ',
                              style: district.isNotEmpty ? valueStyle : regular,
                            ),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Row(
                      children: [
                        pw.Text('दिनांक:- ', style: bold),
                        pw.Expanded(
                          child: pw.Container(
                            decoration: const pw.BoxDecoration(
                              border: pw.Border(bottom: lightBorder),
                            ),
                            child: pw.Text(
                              noticeDate.isNotEmpty ? noticeDate : ' ',
                              style:
                                  noticeDate.isNotEmpty ? valueStyle : regular,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 14),

            // Recipient block
            pw.Text('प्रति,', style: bold),
            pw.SizedBox(height: 3),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('नाव व पत्ता :- ', style: bold),
                pw.Expanded(
                  child: pw.Container(
                    constraints: const pw.BoxConstraints(minHeight: 22),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: lightBorder),
                    ),
                    child: pw.Text(
                      accusedNameAddress.isNotEmpty ? accusedNameAddress : ' ',
                      style:
                          accusedNameAddress.isNotEmpty ? valueStyle : regular,
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            // Subject block
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: regular,
                children: [
                  const pw.TextSpan(text: 'विषय:- पोलीस स्टेशन '),
                  pw.TextSpan(
                    text: subjectPs.isNotEmpty ? ' $subjectPs ' : ' --------- ',
                    style: subjectPs.isNotEmpty ? valueStyle : bold,
                  ),
                  const pw.TextSpan(text: ' गुन्हा रजि.क्र. '),
                  pw.TextSpan(
                    text:
                        subjectCrNo.isNotEmpty ? ' $subjectCrNo ' : ' ------- ',
                    style: subjectCrNo.isNotEmpty ? valueStyle : bold,
                  ),
                  const pw.TextSpan(text: ' कलम '),
                  pw.TextSpan(
                    text: subjectSection.isNotEmpty
                        ? ' $subjectSection '
                        : ' ----- ',
                    style: subjectSection.isNotEmpty ? valueStyle : bold,
                  ),
                  const pw.TextSpan(
                    text:
                        ' --- भा.न्या.स. नुसार दाखल असलेल्या गुन्ह्यांचे अनुषंगाने आरोपीस अटक करतांना अटक करण्यासाठी आधारभूत मुद्दे आणि अटकेची कारणे कळविणे बाबत.',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Main Notice Paragraph
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: regular,
                children: [
                  const pw.TextSpan(
                    text:
                        '       आपणास या सुचनापत्राद्वारे कळविण्यात येते की, आपल्या विरुद्ध पोलीस ठाणे ',
                  ),
                  pw.TextSpan(
                    text: policeStation.isNotEmpty
                        ? ' $policeStation '
                        : ' ------------- ',
                    style: policeStation.isNotEmpty ? valueStyle : bold,
                  ),
                  const pw.TextSpan(text: 'येथे गुन्हा रजि.क्र. '),
                  pw.TextSpan(
                    text:
                        subjectCrNo.isNotEmpty ? ' $subjectCrNo ' : ' ------- ',
                    style: subjectCrNo.isNotEmpty ? valueStyle : bold,
                  ),
                  const pw.TextSpan(text: ' कलम '),
                  pw.TextSpan(
                    text: subjectSection.isNotEmpty
                        ? ' $subjectSection '
                        : ' ------------ ',
                    style: subjectSection.isNotEmpty ? valueStyle : bold,
                  ),
                  const pw.TextSpan(
                    text:
                        ' भारतीय न्याय संहिता २०२३ अन्वये गुन्हा नोंद करण्यात आला असुन, आम्ही ',
                  ),
                  pw.TextSpan(
                    text: ioName.isNotEmpty ? ' $ioName ' : ' -------------- ',
                    style: ioName.isNotEmpty ? valueStyle : bold,
                  ),
                  const pw.TextSpan(
                    text:
                        'तपासी अधिकारी म्हणून सदर गुन्ह्यांचा तपास करीत आहोत. सदर गुन्ह्यांचे तपासकामी आपणास अटक करणे गरजेचे असून भारतीय नागरीक सुरक्षा संहिता २०२३ चे कलम ३५ (१)(ब)(ii) नुसार अटकेची कारणे खालील प्रमाणे आहेत.',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Reasons Header
            pw.Center(
              child: pw.Text(
                'अटकेची कारणे (REASONS FOR ARREST)',
                style: bold.copyWith(fontSize: 12.5),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 10),

            // Reasons 1 to 5 (Spacious ruled entry blocks)
            for (var i = 1; i <= 5; i++) ...[
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${['१', '२', '३', '४', '५'][i - 1]}. ',
                      style: bold,
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        constraints: const pw.BoxConstraints(minHeight: 52),
                        padding: const pw.EdgeInsets.only(
                            bottom: 2, left: 2, right: 2),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: lightBorder,
                          ),
                        ),
                        child: pw.Text(
                          v('reason$i').isNotEmpty ? v('reason$i') : ' ',
                          style:
                              v('reason$i').isNotEmpty ? valueStyle : regular,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            pw.SizedBox(height: 12),

            // Bottom Right continuation marker
            pw.Align(
              alignment: pw.Alignment.bottomRight,
              child: pw.Text('२..', style: bold.copyWith(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 2: Vector Layout (Spacious, Dignified & Official)
  // ══════════════════════════════════════════════════════════════════════════
  if (showCont) {
    final relativeName = v('relativeName');
    final relativeAddress = v('relativeAddress');
    final relativePhone = v('relativePhone');
    final accusedSig = v('accusedSig');
    final accusedNameSig = v('accusedNameSig');
    final accusedDateTime = v('accusedDateTime');
    final ioNameRank = v('ioNameRank');
    final ioPs = v('ioPs');
    final ioTaluka = v('ioTaluka');
    final ioDistrict = v('ioDistrict');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 34),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(
              child: pw.Text(
                '.. २ ..',
                style: bold.copyWith(fontSize: 13),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 24),

            // Paragraph 1
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: regular.copyWith(fontSize: 11.5, lineSpacing: 4.5),
                children: const [
                  pw.TextSpan(
                    text:
                        '       आपणास असेही कळविण्यांत येते की, नमुद गुन्हा हा दखलपात्र असुन अजामीनपात्र आहे आणि त्यामुळे आपण त्या गुन्ह्यात न्यायालयात जामिनाचा अर्ज सादर करुन न्यायालयाचे आदेशाने जामिनावर मुक्त होवु शकता.',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 22),

            // Paragraph 2
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: regular.copyWith(fontSize: 11.5, lineSpacing: 4.5),
                children: [
                  const pw.TextSpan(
                    text: '       आपल्या अटकेची माहीती आपले नातेवाईक/ मित्र ',
                  ),
                  pw.TextSpan(
                    text: relativeName.isNotEmpty
                        ? ' $relativeName '
                        : ' ----------------- ',
                    style: relativeName.isNotEmpty ? valueStyle : bold,
                  ),
                  const pw.TextSpan(text: 'रा. '),
                  pw.TextSpan(
                    text: relativeAddress.isNotEmpty
                        ? ' $relativeAddress '
                        : ' ------------------ ',
                    style: relativeAddress.isNotEmpty ? valueStyle : bold,
                  ),
                  const pw.TextSpan(
                    text: 'यांना लेखी सुचनेव्दारे/फोन क्रमांक ',
                  ),
                  pw.TextSpan(
                    text: relativePhone.isNotEmpty
                        ? ' $relativePhone '
                        : ' --------- ',
                    style: relativePhone.isNotEmpty ? valueStyle : bold,
                  ),
                  const pw.TextSpan(
                    text: 'यावर संपर्क करुन देण्यांत आली आहे.',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 22),

            // Paragraph 3
            pw.RichText(
              text: pw.TextSpan(
                style: regular.copyWith(fontSize: 11.5, lineSpacing: 4.5),
                children: const [
                  pw.TextSpan(
                    text: '       याकरीता आपणास सुचनापत्र देण्यांत येत आहे.',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 28),

            // Official Note Banner
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                border: pw.Border.all(color: PdfColors.grey400, width: 0.7),
              ),
              child: pw.Text(
                'टीप :- सदर सुचनापत्राची मूळ प्रत आरोपीस प्रत्यक्ष समजवून देऊन बजावण्यात आली असून, त्याची स्वाक्षरी / अंगठ्याचा ठसा घेऊन रीतसर पोच घेण्यात आली आहे. सदर दस्तऐवज तपास अभिलेखात समाविष्ट करण्यात आला आहे.',
                style: regular.copyWith(fontSize: 10.5, lineSpacing: 3),
                textAlign: pw.TextAlign.justify,
              ),
            ),
            pw.SizedBox(height: 36),

            // Signatures (Two Dignified Columns with Official Signature Boxes)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left Column (Accused Acknowledgment)
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'मला सुचनापत्र प्राप्त झाले (आरोपीची पोच)',
                        style: bold.copyWith(fontSize: 11.5),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Container(
                        height: 85,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                              color: PdfColors.grey500, width: 0.8),
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(3)),
                        ),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          accusedSig.isNotEmpty
                              ? accusedSig
                              : '(येथे आरोपीची सही / डाव्या हाताच्या अंगठ्याचा ठसा)',
                          style: accusedSig.isNotEmpty
                              ? valueStyle
                              : regular.copyWith(
                                  color: PdfColors.grey600, fontSize: 9.5),
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Row(
                        children: [
                          pw.Text('आरोपीचे नांव :- ', style: bold),
                          pw.Expanded(
                            child: pw.Container(
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(bottom: lightBorder),
                              ),
                              child: pw.Text(
                                accusedNameSig.isNotEmpty
                                    ? accusedNameSig
                                    : ' ',
                                style: accusedNameSig.isNotEmpty
                                    ? valueStyle
                                    : regular,
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Text('दिनांक व वेळ :- ', style: bold),
                          pw.Expanded(
                            child: pw.Container(
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(bottom: lightBorder),
                              ),
                              child: pw.Text(
                                accusedDateTime.isNotEmpty
                                    ? accusedDateTime
                                    : ' ',
                                style: accusedDateTime.isNotEmpty
                                    ? valueStyle
                                    : regular,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 36),

                // Right Column (Investigating Officer)
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'तपास अधिकारी स्वाक्षरी व शिक्का',
                        style: bold.copyWith(fontSize: 11.5),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Container(
                        height: 85,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                              color: PdfColors.grey500, width: 0.8),
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(3)),
                        ),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          '(तपास अधिकारी स्वाक्षरी व पोलीस स्टेशनचा शिक्का)',
                          style: regular.copyWith(
                              color: PdfColors.grey600, fontSize: 9.5),
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Row(
                        children: [
                          pw.Text('नाव व हुद्दा :- ', style: bold),
                          pw.Expanded(
                            child: pw.Container(
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(bottom: lightBorder),
                              ),
                              child: pw.Text(
                                ioNameRank.isNotEmpty ? ioNameRank : ' ',
                                style: ioNameRank.isNotEmpty
                                    ? valueStyle
                                    : regular,
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Text('पोलीस स्टेशन :- ', style: bold),
                          pw.Expanded(
                            child: pw.Container(
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(bottom: lightBorder),
                              ),
                              child: pw.Text(
                                ioPs.isNotEmpty ? ioPs : ' ',
                                style: ioPs.isNotEmpty ? valueStyle : regular,
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Text('ता. ', style: bold),
                          pw.Expanded(
                            flex: 5,
                            child: pw.Container(
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(bottom: lightBorder),
                              ),
                              child: pw.Text(
                                ioTaluka.isNotEmpty ? ioTaluka : ' ',
                                style:
                                    ioTaluka.isNotEmpty ? valueStyle : regular,
                              ),
                            ),
                          ),
                          pw.Text(' -जिल्हा ', style: bold),
                          pw.Expanded(
                            flex: 5,
                            child: pw.Container(
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(bottom: lightBorder),
                              ),
                              child: pw.Text(
                                ioDistrict.isNotEmpty ? ioDistrict : ' ',
                                style: ioDistrict.isNotEmpty
                                    ? valueStyle
                                    : regular,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  return pdf.save();
}

// ══════════════════════════════════════════════════════════════════════════════
// ── NATIVE FLUTTER WIDGET BUILDERS (100% Devanagari Font Shaping) ──
// ══════════════════════════════════════════════════════════════════════════════

class _PdfRuledLinesPainter extends CustomPainter {
  final double lineHeight;
  final Color lineColor;

  const _PdfRuledLinesPainter({
    this.lineHeight = 26.0,
    this.lineColor = const Color(0xFFD0D7DE),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.7
      ..style = PaintingStyle.stroke;

    final count = (size.height / lineHeight).floor();
    for (int i = 1; i <= count; i++) {
      final y = i * lineHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PdfRuledLinesPainter oldDelegate) => false;
}

Widget _buildPg1Widget(Map<String, dynamic> doc) {
  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  final outwardNo = v('outwardNo');
  final outwardYear = v('outwardYear');
  final policeStation = v('policeStation', v('subjectPs'));
  final taluka = v('taluka', v('ioTaluka'));
  final district = v('district', v('ioDistrict'));
  final noticeDate = v('noticeDate');
  final accusedNameAddress = v('accusedNameAddress');
  final subjectPs = v('subjectPs', policeStation);
  final subjectCrNo = v('subjectCrNo');
  final subjectSection = v('subjectSection');
  final ioName = v('ioName', v('ioNameRank'));

  final reg = FormImagePdfHelper.mReg(11, 1.5);
  final bld = FormImagePdfHelper.mBld(11, 1.5);
  final valStyle = FormImagePdfHelper.mBld(11, 1.5).copyWith(color: _kInkColor);
  final headerStyle = FormImagePdfHelper.mBld(12.5, 1.3);
  final titleStyle = FormImagePdfHelper.mBld(18, 1.2);

  return Container(
    width: FormImagePdfHelper.a4Width,
    height: FormImagePdfHelper.a4Height,
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 34),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            'भारतीय नागरीक सुरक्षा संहिता,२०२३ चे कलम ३५ (१)(ब)(ii) नुसार अन्वये',
            style: headerStyle,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            'सुचनापत्र',
            style: titleStyle,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),

        // Right-aligned dispatch details
        Align(
          alignment: Alignment.topRight,
          child: SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('जावक.क्रमांक- ', style: bld),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Color(0xFFB0BEC5), width: 0.8),
                          ),
                        ),
                        child: Text(
                          outwardNo.isNotEmpty
                              ? '$outwardNo / $outwardYear'
                              : '        /        ',
                          style: outwardNo.isNotEmpty ? valStyle : reg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text('पोलीस स्टेशन ', style: bld),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Color(0xFFB0BEC5), width: 0.8),
                          ),
                        ),
                        child: Text(
                          policeStation.isNotEmpty ? policeStation : ' ',
                          style: policeStation.isNotEmpty ? valStyle : reg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text('ता. ', style: bld),
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Color(0xFFB0BEC5), width: 0.8),
                          ),
                        ),
                        child: Text(
                          taluka.isNotEmpty ? taluka : ' ',
                          style: taluka.isNotEmpty ? valStyle : reg,
                        ),
                      ),
                    ),
                    Text(' -जिल्हा ', style: bld),
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Color(0xFFB0BEC5), width: 0.8),
                          ),
                        ),
                        child: Text(
                          district.isNotEmpty ? district : ' ',
                          style: district.isNotEmpty ? valStyle : reg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text('दिनांक:- ', style: bld),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Color(0xFFB0BEC5), width: 0.8),
                          ),
                        ),
                        child: Text(
                          noticeDate.isNotEmpty ? noticeDate : ' ',
                          style: noticeDate.isNotEmpty ? valStyle : reg,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Recipient block
        Text('प्रति,', style: bld),
        const SizedBox(height: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('नाव व पत्ता :- ', style: bld),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 22),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFB0BEC5), width: 0.8),
                  ),
                ),
                child: Text(
                  accusedNameAddress.isNotEmpty ? accusedNameAddress : ' ',
                  style: accusedNameAddress.isNotEmpty ? valStyle : reg,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Subject block
        RichText(
          textAlign: TextAlign.justify,
          text: TextSpan(
            style: reg,
            children: [
              const TextSpan(text: 'विषय:- पोलीस स्टेशन '),
              TextSpan(
                text: subjectPs.isNotEmpty ? ' $subjectPs ' : ' --------- ',
                style: subjectPs.isNotEmpty ? valStyle : bld,
              ),
              const TextSpan(text: ' गुन्हा रजि.क्र. '),
              TextSpan(
                text: subjectCrNo.isNotEmpty ? ' $subjectCrNo ' : ' ------- ',
                style: subjectCrNo.isNotEmpty ? valStyle : bld,
              ),
              const TextSpan(text: ' कलम '),
              TextSpan(
                text:
                    subjectSection.isNotEmpty ? ' $subjectSection ' : ' ----- ',
                style: subjectSection.isNotEmpty ? valStyle : bld,
              ),
              const TextSpan(
                text:
                    ' --- भा.न्या.स. नुसार दाखल असलेल्या गुन्ह्यांचे अनुषंगाने आरोपीस अटक करतांना अटक करण्यासाठी आधारभूत मुद्दे आणि अटकेची कारणे कळविणे बाबत.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Main Notice Paragraph
        RichText(
          textAlign: TextAlign.justify,
          text: TextSpan(
            style: reg,
            children: [
              const TextSpan(
                text:
                    '       आपणास या सुचनापत्राद्वारे कळविण्यात येते की, आपल्या विरुद्ध पोलीस ठाणे ',
              ),
              TextSpan(
                text: policeStation.isNotEmpty
                    ? ' $policeStation '
                    : ' ------------- ',
                style: policeStation.isNotEmpty ? valStyle : bld,
              ),
              const TextSpan(text: 'येथे गुन्हा रजि.क्र. '),
              TextSpan(
                text: subjectCrNo.isNotEmpty ? ' $subjectCrNo ' : ' ------- ',
                style: subjectCrNo.isNotEmpty ? valStyle : bld,
              ),
              const TextSpan(text: ' कलम '),
              TextSpan(
                text: subjectSection.isNotEmpty
                    ? ' $subjectSection '
                    : ' ------------ ',
                style: subjectSection.isNotEmpty ? valStyle : bld,
              ),
              const TextSpan(
                text:
                    ' भारतीय न्याय संहिता २०२३ अन्वये गुन्हा नोंद करण्यात आला असुन, आम्ही ',
              ),
              TextSpan(
                text: ioName.isNotEmpty ? ' $ioName ' : ' -------------- ',
                style: ioName.isNotEmpty ? valStyle : bld,
              ),
              const TextSpan(
                text:
                    'तपासी अधिकारी म्हणून सदर गुन्ह्यांचा तपास करीत आहोत. सदर गुन्ह्यांचे तपासकामी आपणास अटक करणे गरजेचे असून भारतीय नागरीक सुरक्षा संहिता २०२३ चे कलम ३५ (१)(ब)(ii) नुसार अटकेची कारणे खालील प्रमाणे आहेत.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Reasons Header
        Center(
          child: Text(
            'अटकेची कारणे (REASONS FOR ARREST)',
            style: bld.copyWith(fontSize: 12.5),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),

        // Reasons 1 to 5 (Ruled entry blocks)
        for (var i = 1; i <= 5; i++) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${['१', '२', '३', '४', '५'][i - 1]}. ',
                  style: bld,
                ),
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 52),
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: CustomPaint(
                            painter: _PdfRuledLinesPainter(
                              lineHeight: 26.0,
                              lineColor: Color(0xFFB0BEC5),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            v('reason$i').isNotEmpty ? v('reason$i') : ' ',
                            style: (v('reason$i').isNotEmpty ? valStyle : reg)
                                .copyWith(height: 26.0 / 11.0),
                            strutStyle: const StrutStyle(
                              fontSize: 11.0,
                              height: 26.0 / 11.0,
                              forceStrutHeight: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),

        // Bottom right continuation marker
        Align(
          alignment: Alignment.bottomRight,
          child: Text('२..', style: bld.copyWith(fontSize: 12)),
        ),
      ],
    ),
  );
}

Widget _buildPg2Widget(Map<String, dynamic> doc) {
  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  final relativeName = v('relativeName');
  final relativeAddress = v('relativeAddress');
  final relativePhone = v('relativePhone');
  final accusedSig = v('accusedSig');
  final accusedNameSig = v('accusedNameSig');
  final accusedDateTime = v('accusedDateTime');
  final ioNameRank = v('ioNameRank');
  final ioPs = v('ioPs');
  final ioTaluka = v('ioTaluka');
  final ioDistrict = v('ioDistrict');

  final reg = FormImagePdfHelper.mReg(11.5, 1.65);
  final bld = FormImagePdfHelper.mBld(11.5, 1.65);
  final valStyle =
      FormImagePdfHelper.mBld(11.5, 1.65).copyWith(color: _kInkColor);

  return Container(
    width: FormImagePdfHelper.a4Width,
    height: FormImagePdfHelper.a4Height,
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 34),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            '.. २ ..',
            style: FormImagePdfHelper.mBld(13),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),

        // Paragraph 1
        RichText(
          textAlign: TextAlign.justify,
          text: TextSpan(
            style: reg,
            children: const [
              TextSpan(
                text:
                    '       आपणास असेही कळविण्यांत येते की, नमुद गुन्हा हा दखलपात्र असुन अजामीनपात्र आहे आणि त्यामुळे आपण त्या गुन्ह्यात न्यायालयात जामिनाचा अर्ज सादर करुन न्यायालयाचे आदेशाने जामिनावर मुक्त होवु शकता.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Paragraph 2
        RichText(
          textAlign: TextAlign.justify,
          text: TextSpan(
            style: reg,
            children: [
              const TextSpan(
                text: '       आपल्या अटकेची माहीती आपले नातेवाईक/ मित्र ',
              ),
              TextSpan(
                text: relativeName.isNotEmpty
                    ? ' $relativeName '
                    : ' ----------------- ',
                style: relativeName.isNotEmpty ? valStyle : bld,
              ),
              const TextSpan(text: 'रा. '),
              TextSpan(
                text: relativeAddress.isNotEmpty
                    ? ' $relativeAddress '
                    : ' ------------------ ',
                style: relativeAddress.isNotEmpty ? valStyle : bld,
              ),
              const TextSpan(
                text: 'यांना लेखी सुचनेव्दारे/फोन क्रमांक ',
              ),
              TextSpan(
                text: relativePhone.isNotEmpty
                    ? ' $relativePhone '
                    : ' --------- ',
                style: relativePhone.isNotEmpty ? valStyle : bld,
              ),
              const TextSpan(
                text: 'यावर संपर्क करुन देण्यांत आली आहे.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Paragraph 3
        RichText(
          text: TextSpan(
            style: reg,
            children: const [
              TextSpan(
                text: '       याकरीता आपणास सुचनापत्र देण्यांत येत आहे.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Official Note Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFFB0BEC5), width: 0.8),
          ),
          child: Text(
            'टीप :- सदर सुचनापत्राची मूळ प्रत आरोपीस प्रत्यक्ष समजवून देऊन बजावण्यात आली असून, त्याची स्वाक्षरी / अंगठ्याचा ठसा घेऊन रीतसर पोच घेण्यात आली आहे. सदर दस्तऐवज तपास अभिलेखात समाविष्ट करण्यात आला आहे.',
            style: reg.copyWith(
                fontSize: 10.5, height: 1.5, color: Colors.black87),
            textAlign: TextAlign.justify,
          ),
        ),
        const SizedBox(height: 36),

        // Signatures (Two Dignified Columns with Official Signature Boxes)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column (Accused Acknowledgment)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'मला सुचनापत्र प्राप्त झाले (आरोपीची पोच)',
                    style: bld.copyWith(fontSize: 12.5),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 85,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: const Color(0xFF90A4AE), width: 0.8),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      accusedSig.isNotEmpty
                          ? accusedSig
                          : '(येथे आरोपीची सही / डाव्या हाताच्या अंगठ्याचा ठसा)',
                      style: accusedSig.isNotEmpty
                          ? valStyle
                          : reg.copyWith(color: Colors.black38, fontSize: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('आरोपीचे नांव :- ', style: bld),
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color: Color(0xFFB0BEC5), width: 0.8),
                            ),
                          ),
                          child: Text(
                            accusedNameSig.isNotEmpty ? accusedNameSig : ' ',
                            style: accusedNameSig.isNotEmpty ? valStyle : reg,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('दिनांक व वेळ :- ', style: bld),
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color: Color(0xFFB0BEC5), width: 0.8),
                            ),
                          ),
                          child: Text(
                            accusedDateTime.isNotEmpty ? accusedDateTime : ' ',
                            style: accusedDateTime.isNotEmpty ? valStyle : reg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 36),

            // Right Column (Investigating Officer)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'तपास अधिकारी स्वाक्षरी व शिक्का',
                    style: bld.copyWith(fontSize: 12.5),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 85,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: const Color(0xFF90A4AE), width: 0.8),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '(तपास अधिकारी स्वाक्षरी व पोलीस स्टेशनचा शिक्का)',
                      style: reg.copyWith(color: Colors.black38, fontSize: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('नाव व हुद्दा :- ', style: bld),
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color: Color(0xFFB0BEC5), width: 0.8),
                            ),
                          ),
                          child: Text(
                            ioNameRank.isNotEmpty ? ioNameRank : ' ',
                            style: ioNameRank.isNotEmpty ? valStyle : reg,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('पोलीस स्टेशन :- ', style: bld),
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color: Color(0xFFB0BEC5), width: 0.8),
                            ),
                          ),
                          child: Text(
                            ioPs.isNotEmpty ? ioPs : ' ',
                            style: ioPs.isNotEmpty ? valStyle : reg,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('ता. ', style: bld),
                      Expanded(
                        flex: 5,
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color: Color(0xFFB0BEC5), width: 0.8),
                            ),
                          ),
                          child: Text(
                            ioTaluka.isNotEmpty ? ioTaluka : ' ',
                            style: ioTaluka.isNotEmpty ? valStyle : reg,
                          ),
                        ),
                      ),
                      Text(' -जिल्हा ', style: bld),
                      Expanded(
                        flex: 5,
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color: Color(0xFFB0BEC5), width: 0.8),
                            ),
                          ),
                          child: Text(
                            ioDistrict.isNotEmpty ? ioDistrict : ' ',
                            style: ioDistrict.isNotEmpty ? valStyle : reg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
