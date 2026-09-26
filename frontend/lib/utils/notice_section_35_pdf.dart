import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'form_image_pdf_helper.dart';
import 'pdf_font_cache.dart';

Future<void> previewNoticeSection35Pdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  final formSection = v('formSection');
  final showP1 = formSection.isEmpty ||
      formSection == 'Notice Section 35 Main' ||
      formSection == 'Notice Section 35';
  final showP2 = formSection.isEmpty ||
      formSection == 'Notice Section 35 Continuation' ||
      formSection == 'Notice Section 35';

  final pages = <Widget>[];
  if (showP1) pages.add(_buildPg1Widget(doc));
  if (showP2) pages.add(_buildPg2Widget(doc));

  final fileName =
      'Notice_Section_35_${DateTime.now().millisecondsSinceEpoch}.pdf';
  await FormImagePdfHelper.previewImageBasedPdf(
    context,
    fileName: fileName,
    pages: pages,
    fallbackPdfGenerator: () => generateNoticeSection35Pdf(doc),
  );
}

List<String> _splitTextIntoLines(String text, {int approxCharsPerLine = 65}) {
  final content = text.trim();
  if (content.isEmpty) return [''];

  final rawLines = content.split('\n');
  final lines = <String>[];

  for (final rawLine in rawLines) {
    final words = rawLine.trim().split(RegExp(r'\s+'));
    var currentLine = '';

    for (final word in words) {
      if (word.isEmpty) continue;
      if (currentLine.isEmpty) {
        currentLine = word;
      } else if ((currentLine.length + 1 + word.length) <= approxCharsPerLine) {
        currentLine += ' $word';
      } else {
        lines.add(currentLine);
        currentLine = word;
      }
    }
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }
  }

  return lines.isEmpty ? [''] : lines;
}

pw.Widget _pwDynamicRecipientLines({
  required String text,
  required pw.TextStyle style,
  double fullWidth = 515,
}) {
  final lines = _splitTextIntoLines(text, approxCharsPerLine: 65);
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: lines.map((line) {
      return pw.Container(
        width: fullWidth,
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(
              color: PdfColors.black,
              width: 0.8,
            ),
          ),
        ),
        padding: const pw.EdgeInsets.only(bottom: 2, top: 2),
        margin: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Text(
          line.isNotEmpty ? line : ' ',
          style: style,
        ),
      );
    }).toList(),
  );
}

Future<Uint8List> generateNoticeSection35Pdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final devanagari = await PdfFontCache.devanagariRegular();
  final devanagariBold = await PdfFontCache.devanagariBold();

  final regular = pw.TextStyle(
    font: devanagari,
    fontSize: 9.5,
    lineSpacing: 3,
  );
  final bold = pw.TextStyle(
    font: devanagariBold,
    fontSize: 9.5,
    fontWeight: pw.FontWeight.bold,
  );
  final headerTitle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 14,
    fontWeight: pw.FontWeight.bold,
    decoration: pw.TextDecoration.underline,
  );
  final subTitle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 10,
    fontWeight: pw.FontWeight.bold,
  );

  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  final formSection = v('formSection');
  final showP1 = formSection.isEmpty ||
      formSection == 'Notice Section 35 Main' ||
      formSection == 'Notice Section 35';
  final showP2 = formSection.isEmpty ||
      formSection == 'Notice Section 35 Continuation' ||
      formSection == 'Notice Section 35';

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 1 (Main: तपास व ९ अटी सूचनापत्र)
  // ═══════════════════════════════════════════════════════════════════════════
  if (showP1) {
    final p1Ps = v('p1PoliceStation', v('policeStation'));
    final p1Date = v('p1NoticeDate', v('noticeDate', '......./ ......./२०...'));
    final p1Recipient1 = v('p1RecipientLine1', v('recipientLine1'));
    final p1Recipient2 = v('p1RecipientLine2', v('recipientLine2'));
    final p1Recipient3 = v('p1RecipientLine3', v('recipientLine3'));
    final rawP1Recipient = v('p1Recipient', v('recipient'));
    final p1RecipientText = rawP1Recipient.isNotEmpty
        ? rawP1Recipient
        : joinRecipientParts([p1Recipient1, p1Recipient2, p1Recipient3]);
    final p1Aadhaar =
        v('p1AadhaarNo', v('aadhaarNo', '___________________________'));
    final p1Email = v('p1Email', v('email', '_______________________________'));

    final p1IncDate =
        v('p1IncidentDate', v('incidentDate', '....../ ....../२०.....'));
    final p1IncPs = v('p1IncidentPs', v('incidentPs'));
    final p1CrimeNo = v('p1CrimeNo', v('crimeNo', '........./२०....'));
    final p1ActSec = v('p1ActSec',
        v('actSec', '............. ...................................'));
    final p1AppDate =
        v('p1AppearanceDate', v('appearanceDate', '....../ ....../२०.....'));
    final p1AppTime =
        v('p1AppearanceTime', v('appearanceTime', '......../ .......'));

    final p1AccusedSig = v('p1AccusedSig', v('accusedSig'));
    final p1IoSig = v('p1IoSig', v('investigatingOfficerSig'));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ── TOP RIGHT ──
              pw.Align(
                alignment: pw.Alignment.topRight,
                child: pw.SizedBox(
                  width: 250,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 1.0),
                            child: pw.Text('पोलीस स्टेशन ', style: bold),
                          ),
                          pw.Expanded(
                            child: pw.Text(p1Ps,
                                style: regular.copyWith(
                                    decoration: pw.TextDecoration.underline),
                                softWrap: true),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text('दिनांक : ', style: bold),
                          pw.Text(p1Date, style: regular),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 12),

              // ── TITLE ──
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('-:: नोटीस ::-', style: headerTitle),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '( कलम ३५ (३) भारतीय नागरी संरक्षण संहिता सन २०२३ अन्वये)',
                      style: subTitle,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // ── RECIPIENT ──
              pw.Text('प्रति,', style: bold),
              pw.SizedBox(height: 4),
              _pwDynamicRecipientLines(text: p1RecipientText, style: regular),
              pw.SizedBox(height: 10),

              pw.Row(
                children: [
                  pw.Text('आधार क :- ', style: bold),
                  pw.Text(p1Aadhaar, style: regular),
                ],
              ),
              pw.SizedBox(height: 4),

              pw.Row(
                children: [
                  pw.Text('ईमेल:- ', style: bold),
                  pw.Text(p1Email, style: regular),
                ],
              ),
              pw.SizedBox(height: 12),

              // ── PARAGRAPH 1 ──
              pw.Paragraph(
                text:
                    '        भारतीय नागरी संरक्षण संहिता सन २०२३ मधील कलम ३५ (३) अन्वये प्रदान केलेल्या अधिकाराचा वापर करून मी खाली स्वाक्षरी करणार निर्देशित करतो की, दिनांक $p1IncDate रोजी पोलीस स्टेशन $p1IncPs येथे दाखल असलेला अपराध क्रमांक $p1CrimeNo कलम $p1ActSec तपासा दरम्यान हे निष्पन्न झाले की, या गुन्हयाच्या तपासाच्या अनुषंगाने तथ्य आणि वस्तुस्थिती जाणून घेण्यासाठी तुमच्याकडे विचारपुस करण्यासाठी सबळ व वाजवी कारणे आहेत. त्यामुळे तुम्हास दिनांक $p1AppDate रोजी $p1AppTime वाजता ठाण्यात माझे समक्ष न चुकता उपस्थित राहण्याचे निर्देश देण्यात येत आहे.',
                style: regular,
                textAlign: pw.TextAlign.justify,
              ),
              pw.SizedBox(height: 6),

              pw.Paragraph(
                text:
                    '        त्याच प्रमाणे तुम्हास खालील निर्देश काटेकोर पालन करण्याच्या सुचना देण्यात येत आहेत.',
                style: regular,
              ),
              pw.SizedBox(height: 6),

              // ── CLAUSES 1 TO 9 ──
              pw.Text('१) भवीष्यात तुम्ही कोणताही गुन्हा करणार नाही.',
                  style: regular),
              pw.SizedBox(height: 3),
              pw.Text(
                  '२) तुम्ही या गुन्हया संदर्भातील कोणत्याही पुराव्या मध्ये बदल/ छेड-छाड करणार नाहीत.',
                  style: regular),
              pw.SizedBox(height: 3),
              pw.Text(
                  '३) या गुन्हयाच्या तथ्यांशी परिचित असलेल्या कोणत्याही व्यक्तीला तो अशी तथ्ये पोलीस अथवा न्यायालया समोर उघड करण्यापासुन परावृत्त होण्याची शक्यता आहे. अशा प्रकारे तुम्ही कोणतीही धमकी, प्रलोभन, किंवा आश्वासन देणार नाहीत.',
                  style: regular),
              pw.SizedBox(height: 3),
              pw.Text(
                  '४) जेव्हा आवश्यक असेल/ आदेशीत करण्यात येईल तेव्हा तुम्ही न चुकता न्यायालया समोर हजर व्हाल.',
                  style: regular),
              pw.SizedBox(height: 3),
              pw.Text(
                  '५) सदर गुन्हयाच्या तपासा दरम्यान आपण निर्देशित केल्यानंतर न चुकता दिलेल्या ठिकाणी वेळेत हजर राहाल व तपासा दरम्यान पूर्ण सहकार्य कराल.',
                  style: regular),
              pw.SizedBox(height: 3),
              pw.Text(
                  '६) गुन्हयाच्या तपासा दरम्यान योग्य निष्कर्शा पर्यंत पोहोचण्यासाठी आपण कोणतेही बाब न लपविता सर्व तथ्ये सत्यतेने उघड कराल.',
                  style: regular),
              pw.SizedBox(height: 3),
              pw.Text(
                  '७) तुम्ही तपासासाठी आवश्यक सर्व दस्तऐवज/ इतर साहित्य तपासी अधिकारी यांना उपलब्ध करून द्याल.',
                  style: regular),
              pw.SizedBox(height: 3),
              pw.Text(
                  '८) गुन्हयातील सहभागी इतर कोणत्याही आरोपींना अटक करणे आवश्यक असल्यास आपण सर्वतोपरी सहकार्य कराल.',
                  style: regular),
              pw.SizedBox(height: 3),
              pw.Text(
                  '९) याव्यतिरीक्त तपासी अधिकाऱ्यांनी दिलेल्या सर्व कायदेशीर निर्देश आपण काटेकोरपणे पाल कराल.',
                  style: regular),
              pw.SizedBox(height: 8),

              // ── WARNING PARAGRAPH ──
              pw.Paragraph(
                text:
                    '        इतर कोणत्याही अटी, ज्या तपास अधिकाऱ्याने लादल्या जाउ शकतात/ प्रकरणातील वस्तुस्थितीनुसार भा.ना.सु.सं.कलम ३५ (४) च्या सुचनेच्या अटींचे पालन करण्यात/ हजर राहण्यात अयशस्वी झाल्यास भारतीय नागरीक सुरक्षा संहिता २०२३ चे कलम ३५ (६) अंतर्गत अटक करण्यासाठी तुम्हाला जबाबदार धरले जाउ शकते.',
                style: regular,
                textAlign: pw.TextAlign.justify,
              ),
              pw.Spacer(),

              // ── SIGNATURES ──
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('आरोपीची स्वाक्षरी', style: bold),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        p1AccusedSig.isNotEmpty
                            ? p1AccusedSig
                            : '________________________',
                        style: regular,
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('तपासी अधिकारी नांव स्वाक्षरी', style: bold),
                      if (p1IoSig.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(p1IoSig, style: regular),
                      ],
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // ── MRW FOOTER ──
              pw.Align(
                alignment: pw.Alignment.bottomRight,
                child: pw.Text(
                  'M.R.W',
                  style: pw.TextStyle(
                    font: devanagari,
                    fontSize: 7.5,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PAGE 2 (Rights & Signatures: दोषारोपपत्र न्यायप्रविष्ठ नोटीस)
  // ═══════════════════════════════════════════════════════════════════════════
  if (showP2) {
    final p2Ps = v('p2PoliceStation', v('policeStation'));
    final p2Date = v('p2NoticeDate', v('noticeDate', '......./ ......./२०...'));
    final p2Recipient1 = v('p2RecipientLine1', v('recipientLine1'));
    final p2Recipient2 = v('p2RecipientLine2', v('recipientLine2'));
    final p2Recipient3 = v('p2RecipientLine3', v('recipientLine3'));
    final rawP2Recipient = v('p2Recipient', v('recipient'));
    final p2RecipientText = rawP2Recipient.isNotEmpty
        ? rawP2Recipient
        : joinRecipientParts([p2Recipient1, p2Recipient2, p2Recipient3]);

    final p2IncPs = v('p2IncidentPs', v('incidentPs'));
    final p2Dist = v('p2District', v('district'));
    final p2CrimeNo = v('p2CrimeNo', v('crimeNo', '........./२०........'));
    final p2ActSec = v(
        'p2ActSec',
        v('actSec',
            '.................................................................................'));

    final p2CourtDate =
        v('p2CourtDate', v('courtDate', '......./ ......./२०.....'));
    final p2CourtTime = v('p2CourtTime', '१०:३०');
    final p2CourtPs = v('p2CourtPs', v('courtPs'));
    final p2CourtName = v('p2CourtName', v('courtName', '------------------'));

    final p2IoSig = v('p2IoSig', v('investigatingOfficerSig'));
    final p2AccusedAckSig = v('p2AccusedAckSig');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ── TOP RIGHT ──
              pw.Align(
                alignment: pw.Alignment.topRight,
                child: pw.SizedBox(
                  width: 250,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 1.0),
                            child: pw.Text('पोलीस स्टेशन ', style: bold),
                          ),
                          pw.Expanded(
                            child: pw.Text(p2Ps,
                                style: regular.copyWith(
                                    decoration: pw.TextDecoration.underline),
                                softWrap: true),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text('दिनांक : ', style: bold),
                          pw.Text(p2Date, style: regular),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 18),

              // ── TITLE ──
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('-:: नोटीस ::-', style: headerTitle),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '( कलम ३५ (३) भारतीय नागरी संरक्षण संहिता सन २०२३ अन्वये)',
                      style: subTitle,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // ── RECIPIENT ──
              pw.Text('प्रति,', style: bold),
              pw.SizedBox(height: 6),
              _pwDynamicRecipientLines(text: p2RecipientText, style: regular),
              pw.SizedBox(height: 16),

              // ── PARAGRAPH 1 ──
              pw.Paragraph(
                text:
                    '        आपणास या नोटीस व्दारे कळविण्यात येते की, आपना विरूध्द पोलीस स्टेशन ${p2IncPs.isNotEmpty ? '$p2IncPs  ' : ''}जिल्हा $p2Dist येथे अपराध क्रमांक $p2CrimeNo कलम $p2ActSec अन्वये गुन्हा नोंद करण्यात आलेला आहे. सदर अपराधा मध्ये शिक्षा ७ वर्षा पेक्षा कमी आहे किंवा ७ वर्षा पर्यंत द्रव्यदंडा सह किंवा त्या व्यतिरीक्त होवू शकते त्यामुळे सध्या आपनास अटक करणे गरजेचे वाटत नाही.',
                style: regular,
                textAlign: pw.TextAlign.justify,
              ),
              pw.SizedBox(height: 16),

              // ── PARAGRAPH 2 ──
              pw.Paragraph(
                text:
                    '        तरी वरील अपराधा मध्ये दोषारोपपत्र न्यायप्रविष्ठ करावयाचा असल्याने आपण दिनांक :. $p2CourtDate रोजी $p2CourtTime वाजता पोलीस स्टेशन $p2CourtPs येथे हजर यावे त्यानंतर मा.वि.न्यायदंडाधिकारी साहेब प्रथम श्रेणी कोर्ट $p2CourtName येथील न्यायालयात जामीनदारासह न चुकता हजर राहावे.',
                style: regular,
                textAlign: pw.TextAlign.justify,
              ),
              pw.SizedBox(height: 36),

              // ── IO SIGNATURE (RIGHT) ──
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('तपासी अधिकारी नांव व सही', style: bold),
                    if (p2IoSig.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(p2IoSig, style: regular),
                    ],
                  ],
                ),
              ),
              pw.SizedBox(height: 48),

              // ── ACCUSED ACKNOWLEDGMENT (LEFT) ──
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('सुचनापत्र मिळाले आहे.', style: bold),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      p2AccusedAckSig.isNotEmpty
                          ? p2AccusedAckSig
                          : '___________________________',
                      style: regular,
                    ),
                  ],
                ),
              ),
              pw.Spacer(),

              // ── MRW FOOTER ──
              pw.Align(
                alignment: pw.Alignment.bottomRight,
                child: pw.Text(
                  'M.R.W',
                  style: pw.TextStyle(
                    font: devanagari,
                    fontSize: 7.5,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  return pdf.save();
}

// ══════════════════════════════════════════════════════════════════════════════
// ── NATIVE FLUTTER WIDGET BUILDERS (100% Devanagari Font Shaping) ──
// ══════════════════════════════════════════════════════════════════════════════

class _FullWidthUnderlinePainter extends CustomPainter {
  final List<ui.LineMetrics> metrics;
  final Color color;
  final double thickness;

  _FullWidthUnderlinePainter({
    required this.metrics,
    this.color = const Color(0xFF333333),
    this.thickness = 0.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    if (metrics.isNotEmpty) {
      for (final m in metrics) {
        final lineBottom = m.baseline + m.descent;
        final y = (lineBottom + 1.5).clamp(1.0, size.height - 0.5);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else {
      canvas.drawLine(
        Offset(0, size.height - 0.5),
        Offset(size.width, size.height - 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FullWidthUnderlinePainter oldDelegate) => true;
}

String joinRecipientParts(List<String> rawParts) {
  final clean =
      rawParts.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  if (clean.isEmpty) return '';
  final sb = StringBuffer();
  for (int i = 0; i < clean.length; i++) {
    if (i > 0) {
      final prev = sb.toString().trimRight();
      if (!prev.endsWith(',') && !prev.endsWith(';') && !prev.endsWith('-')) {
        sb.write(', ');
      } else {
        sb.write(' ');
      }
    }
    sb.write(clean[i]);
  }
  return sb.toString();
}

Widget _dynamicRecipientUnderlineField(String text, {double fontSize = 11.5}) {
  final content = text.trim();
  final baseStyle = FormImagePdfHelper.valStyle(fontSize);
  final style = baseStyle.copyWith(
    height: 1.85,
    color: Colors.black,
    fontWeight: FontWeight.w600,
  );

  return LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth.isFinite && constraints.maxWidth > 0
          ? constraints.maxWidth
          : 706.0;
      final textMaxWidth = (width - 4.0).clamp(10.0, width);

      final tp = TextPainter(
        text: TextSpan(
          text: content.isEmpty ? ' ' : content,
          style: style,
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: textMaxWidth);

      final metrics = tp.computeLineMetrics();

      return SizedBox(
        width: width,
        child: CustomPaint(
          painter: _FullWidthUnderlinePainter(
            metrics: metrics,
            color: const Color(0xFF333333),
            thickness: 0.8,
          ),
          child: SizedBox(
            width: width,
            child: Padding(
              padding: const EdgeInsets.only(left: 2, right: 2, bottom: 2),
              child: Text(
                content.isEmpty ? ' ' : content,
                softWrap: true,
                style: style,
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildPg1Widget(Map<String, dynamic> doc) {
  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  final p1Ps = v('p1PoliceStation', v('policeStation'));
  final p1Date = v('p1NoticeDate', v('noticeDate'));
  final p1Recipient1 = v('p1RecipientLine1', v('recipientLine1'));
  final p1Recipient2 = v('p1RecipientLine2', v('recipientLine2'));
  final p1Recipient3 = v('p1RecipientLine3', v('recipientLine3'));
  final rawP1Recipient = v('p1Recipient', v('recipient'));
  final p1RecipientText = rawP1Recipient.isNotEmpty
      ? rawP1Recipient
      : joinRecipientParts([p1Recipient1, p1Recipient2, p1Recipient3]);
  final p1Aadhaar = v('p1AadhaarNo', v('aadhaarNo'));
  final p1Email = v('p1Email', v('email'));

  final p1IncDate = v('p1IncidentDate', v('incidentDate'));
  final p1IncPs = v('p1IncidentPs', v('incidentPs'));
  final p1CrimeNo = v('p1CrimeNo', v('crimeNo'));
  final p1ActSec = v('p1ActSec', v('actSec'));
  final p1AppDate = v('p1AppearanceDate', v('appearanceDate'));
  final p1AppTime = v('p1AppearanceTime', v('appearanceTime'));

  final p1AccusedSig = v('p1AccusedSig', v('accusedSig'));
  final p1IoSig = v('p1IoSig', v('investigatingOfficerSig'));

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 36),
    children: [
      // Top Right
      Align(
        alignment: Alignment.topRight,
        child: SizedBox(
          width: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1.0),
                    child: Text('पोलीस स्टेशन ',
                        style: FormImagePdfHelper.mBld(11)),
                  ),
                  Expanded(
                    child: Text(
                      p1Ps.isEmpty ? ' ' : p1Ps,
                      softWrap: true,
                      style: FormImagePdfHelper.valStyle(11).copyWith(
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.black87,
                        decorationThickness: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('दिनांक : ', style: FormImagePdfHelper.mBld(11)),
                  Text(
                    p1Date.isEmpty ? ' ' : p1Date,
                    style: FormImagePdfHelper.valStyle(11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),

      // Title
      Center(
        child: Column(
          children: [
            Text(
              '-:: नोटीस ::-',
              style: FormImagePdfHelper.mBld(15).copyWith(
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '( कलम ३५ (३) भारतीय नागरी संरक्षण संहिता सन २०२३ अन्वये)',
              style: FormImagePdfHelper.mBld(11),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // Recipient
      Text('प्रति,', style: FormImagePdfHelper.mBld(11)),
      const SizedBox(height: 4),
      _dynamicRecipientUnderlineField(p1RecipientText),
      const SizedBox(height: 10),

      Row(
        children: [
          Text('आधार क :- ', style: FormImagePdfHelper.mBld(10.5)),
          Text(p1Aadhaar, style: FormImagePdfHelper.valStyle(10.5)),
        ],
      ),
      const SizedBox(height: 4),

      Row(
        children: [
          Text('ईमेल:- ', style: FormImagePdfHelper.mBld(10.5)),
          Text(p1Email, style: FormImagePdfHelper.valStyle(10.5)),
        ],
      ),
      const SizedBox(height: 10),

      // Paragraph 1
      Text(
        '        भारतीय नागरी संरक्षण संहिता सन २०२३ मधील कलम ३५ (३) अन्वये प्रदान केलेल्या अधिकाराचा वापर करून मी खाली स्वाक्षरी करणार निर्देशित करतो की, दिनांक $p1IncDate रोजी पोलीस स्टेशन $p1IncPs येथे दाखल असलेला अपराध क्रमांक $p1CrimeNo कलम $p1ActSec तपासा दरम्यान हे निष्पन्न झाले की, या गुन्हयाच्या तपासाच्या अनुषंगाने तथ्य आणि वस्तुस्थिती जाणून घेण्यासाठी तुमच्याकडे विचारपुस करण्यासाठी सबळ व वाजवी कारणे आहेत. त्यामुळे तुम्हास दिनांक $p1AppDate रोजी $p1AppTime वाजता ठाण्यात माझे समक्ष न चुकता उपस्थित राहण्याचे निर्देश देण्यात येत आहे.',
        style: FormImagePdfHelper.mReg(10.5, 1.45),
        textAlign: TextAlign.justify,
      ),
      const SizedBox(height: 6),

      Text(
        '        त्याच प्रमाणे तुम्हास खालील निर्देश काटेकोर पालन करण्याच्या सुचना देण्यात येत आहेत.',
        style: FormImagePdfHelper.mReg(10.5, 1.45),
      ),
      const SizedBox(height: 6),

      // Clauses 1 to 9
      Text('१) भवीष्यात तुम्ही कोणताही गुन्हा करणार नाही.',
          style: FormImagePdfHelper.mReg(10.5, 1.35)),
      const SizedBox(height: 3),
      Text(
          '२) तुम्ही या गुन्हया संदर्भातील कोणत्याही पुराव्या मध्ये बदल/ छेड-छाड करणार नाहीत.',
          style: FormImagePdfHelper.mReg(10.5, 1.35)),
      const SizedBox(height: 3),
      Text(
          '३) या गुन्हयाच्या तथ्यांशी परिचित असलेल्या कोणत्याही व्यक्तीला तो अशी तथ्ये पोलीस अथवा न्यायालया समोर उघड करण्यापासुन परावृत्त होण्याची शक्यता आहे. अशा प्रकारे तुम्ही कोणतीही धमकी, प्रलोभन, किंवा आश्वासन देणार नाहीत.',
          style: FormImagePdfHelper.mReg(10.5, 1.35)),
      const SizedBox(height: 3),
      Text(
          '४) जेव्हा आवश्यक असेल/ आदेशीत करण्यात येईल तेव्हा तुम्ही न चुकता न्यायालया समोर हजर व्हाल.',
          style: FormImagePdfHelper.mReg(10.5, 1.35)),
      const SizedBox(height: 3),
      Text(
          '५) सदर गुन्हयाच्या तपासा दरम्यान आपण निर्देशित केल्यानंतर न चुकता दिलेल्या ठिकाणी वेळेत हजर राहाल व तपासा दरम्यान पूर्ण सहकार्य कराल.',
          style: FormImagePdfHelper.mReg(10.5, 1.35)),
      const SizedBox(height: 3),
      Text(
          '६) गुन्हयाच्या तपासा दरम्यान योग्य निष्कर्शा पर्यंत पोहोचण्यासाठी आपण कोणतेही बाब न लपविता सर्व तथ्ये सत्यतेने उघड कराल.',
          style: FormImagePdfHelper.mReg(10.5, 1.35)),
      const SizedBox(height: 3),
      Text(
          '७) तुम्ही तपासासाठी आवश्यक सर्व दस्तऐवज/ इतर साहित्य तपासी अधिकारी यांना उपलब्ध करून द्याल.',
          style: FormImagePdfHelper.mReg(10.5, 1.35)),
      const SizedBox(height: 3),
      Text(
          '८) गुन्हयातील सहभागी इतर कोणत्याही आरोपींना अटक करणे आवश्यक असल्यास आपण सर्वतोपरी सहकार्य कराल.',
          style: FormImagePdfHelper.mReg(10.5, 1.35)),
      const SizedBox(height: 3),
      Text(
          '९) याव्यतिरीक्त तपासी अधिकाऱ्यांनी दिलेल्या सर्व कायदेशीर निर्देश आपण काटेकोरपणे पाल कराल.',
          style: FormImagePdfHelper.mReg(10.5, 1.35)),
      const SizedBox(height: 8),

      // Warning Paragraph
      Text(
        '        इतर कोणत्याही अटी, ज्या तपास अधिकाऱ्याने लादल्या जाउ शकतात/ प्रकरणातील वस्तुस्थितीनुसार भा.ना.सु.सं.कलम ३५ (४) च्या सुचनेच्या अटींचे पालन करण्यात/ हजर राहण्यात अयशस्वी झाल्यास भारतीय नागरीक सुरक्षा संहिता २०२३ चे कलम ३५ (६) अंतर्गत अटक करण्यासाठी तुम्हाला जबाबदार धरले जाउ शकते.',
        style: FormImagePdfHelper.mReg(10.5, 1.45),
        textAlign: TextAlign.justify,
      ),
      const Spacer(),

      // Signatures
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('आरोपीची स्वाक्षरी', style: FormImagePdfHelper.mBld(11)),
              const SizedBox(height: 4),
              Text(
                p1AccusedSig.isNotEmpty
                    ? p1AccusedSig
                    : '________________________',
                style: FormImagePdfHelper.valStyle(11),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('तपासी अधिकारी नांव स्वाक्षरी',
                  style: FormImagePdfHelper.mBld(11)),
              if (p1IoSig.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(p1IoSig, style: FormImagePdfHelper.valStyle(11)),
              ],
            ],
          ),
        ],
      ),
      const SizedBox(height: 10),

      Align(
        alignment: Alignment.bottomRight,
        child: Text(
          'M.R.W',
          style: FormImagePdfHelper.mReg(8).copyWith(color: Colors.black54),
        ),
      ),
    ],
  );
}

Widget _buildPg2Widget(Map<String, dynamic> doc) {
  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  final p2Ps = v('p2PoliceStation', v('policeStation'));
  final p2Date = v('p2NoticeDate', v('noticeDate'));
  final p2Recipient1 = v('p2RecipientLine1', v('recipientLine1'));
  final p2Recipient2 = v('p2RecipientLine2', v('recipientLine2'));
  final p2Recipient3 = v('p2RecipientLine3', v('recipientLine3'));
  final rawP2Recipient = v('p2Recipient', v('recipient'));
  final p2RecipientText = rawP2Recipient.isNotEmpty
      ? rawP2Recipient
      : joinRecipientParts([p2Recipient1, p2Recipient2, p2Recipient3]);

  final p2IncPs = v('p2IncidentPs', v('incidentPs'));
  final p2Dist = v('p2District', v('district'));
  final p2CrimeNo = v('p2CrimeNo', v('crimeNo'));
  final p2ActSec = v('p2ActSec', v('actSec'));

  final p2CourtDate = v('p2CourtDate', v('courtDate'));
  final p2CourtTime = v('p2CourtTime', '१०:३०');
  final p2CourtPs = v('p2CourtPs', v('courtPs'));
  final p2CourtName = v('p2CourtName', v('courtName'));

  final p2IoSig = v('p2IoSig', v('investigatingOfficerSig'));
  final p2AccusedAckSig = v('p2AccusedAckSig');

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 40),
    children: [
      // Top Right
      Align(
        alignment: Alignment.topRight,
        child: SizedBox(
          width: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1.0),
                    child: Text('पोलीस स्टेशन ',
                        style: FormImagePdfHelper.mBld(11)),
                  ),
                  Expanded(
                    child: Text(
                      p2Ps.isEmpty ? ' ' : p2Ps,
                      softWrap: true,
                      style: FormImagePdfHelper.valStyle(11).copyWith(
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.black87,
                        decorationThickness: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('दिनांक : ', style: FormImagePdfHelper.mBld(11)),
                  Text(
                    p2Date.isEmpty ? ' ' : p2Date,
                    style: FormImagePdfHelper.valStyle(11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 18),

      // Title
      Center(
        child: Column(
          children: [
            Text(
              '-:: नोटीस ::-',
              style: FormImagePdfHelper.mBld(15).copyWith(
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '( कलम ३५ (३) भारतीय नागरी संरक्षण संहिता सन २०२३ अन्वये)',
              style: FormImagePdfHelper.mBld(11),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),

      // Recipient
      Text('प्रति,', style: FormImagePdfHelper.mBld(11)),
      const SizedBox(height: 6),
      _dynamicRecipientUnderlineField(p2RecipientText),
      const SizedBox(height: 20),

      // Paragraph 1
      Text(
        '        आपणास या नोटीस व्दारे कळविण्यात येते की, आपना विरूध्द पोलीस स्टेशन ${p2IncPs.isNotEmpty ? '$p2IncPs  ' : ''}जिल्हा $p2Dist येथे अपराध क्रमांक $p2CrimeNo कलम $p2ActSec अन्वये गुन्हा नोंद करण्यात आलेला आहे. सदर अपराधा मध्ये शिक्षा ७ वर्षा पेक्षा कमी आहे किंवा ७ वर्षा पर्यंत द्रव्यदंडा सह किंवा त्या व्यतिरीक्त होवू शकते त्यामुळे सध्या आपनास अटक करणे गरजेचे वाटत नाही.',
        style: FormImagePdfHelper.mReg(11, 1.5),
        textAlign: TextAlign.justify,
      ),
      const SizedBox(height: 16),

      // Paragraph 2
      Text(
        '        तरी वरील अपराधा मध्ये दोषारोपपत्र न्यायप्रविष्ठ करावयाचा असल्याने आपण दिनांक :. $p2CourtDate रोजी $p2CourtTime वाजता पोलीस स्टेशन $p2CourtPs येथे हजर यावे त्यानंतर मा.वि.न्यायदंडाधिकारी साहेब प्रथम श्रेणी कोर्ट $p2CourtName येथील न्यायालयात जामीनदारासह न चुकता हजर राहावे.',
        style: FormImagePdfHelper.mReg(11, 1.5),
        textAlign: TextAlign.justify,
      ),
      const SizedBox(height: 36),

      // IO Signature (Right)
      Align(
        alignment: Alignment.centerRight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('तपासी अधिकारी नांव व सही',
                style: FormImagePdfHelper.mBld(11)),
            if (p2IoSig.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(p2IoSig, style: FormImagePdfHelper.valStyle(11)),
            ],
          ],
        ),
      ),
      const SizedBox(height: 48),

      // Accused Acknowledgment (Left)
      Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('सुचनापत्र मिळाले आहे.', style: FormImagePdfHelper.mBld(11)),
            const SizedBox(height: 4),
            Text(
              p2AccusedAckSig.isNotEmpty
                  ? p2AccusedAckSig
                  : '___________________________',
              style: FormImagePdfHelper.valStyle(11),
            ),
          ],
        ),
      ),
      const Spacer(),

      // Footer
      Align(
        alignment: Alignment.bottomRight,
        child: Text(
          'M.R.W',
          style: FormImagePdfHelper.mReg(8).copyWith(color: Colors.black54),
        ),
      ),
    ],
  );
}
