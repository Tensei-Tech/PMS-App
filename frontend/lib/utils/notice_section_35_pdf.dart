import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> previewNoticeSection35Pdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final bytes = await generateNoticeSection35Pdf(doc);
  if (!context.mounted) return;
  final fileName =
      'Notice_Section_35_${DateTime.now().millisecondsSinceEpoch}.pdf';
  try {
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } else {
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);
    }
  } catch (_) {
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }
}

Future<Uint8List> generateNoticeSection35Pdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final devanagari = await PdfGoogleFonts.notoSansDevanagariRegular();
  final devanagariBold = await PdfGoogleFonts.notoSansDevanagariBold();

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
    final p1Ps = v('p1PoliceStation', v('policeStation', '_______________'));
    final p1Date = v('p1NoticeDate', v('noticeDate', '......./ ......./२०...'));
    final p1Recipient1 = v(
        'p1RecipientLine1',
        v('recipientLine1',
            '____________________________________________________________________'));
    final p1Recipient2 = v(
        'p1RecipientLine2',
        v('recipientLine2',
            '____________________________________________________________________'));
    final p1Recipient3 = v(
        'p1RecipientLine3',
        v('recipientLine3',
            '____________________________________________________________________'));
    final p1Aadhaar =
        v('p1AadhaarNo', v('aadhaarNo', '___________________________'));
    final p1Email = v('p1Email', v('email', '_______________________________'));

    final p1IncDate =
        v('p1IncidentDate', v('incidentDate', '....../ ....../२०.....'));
    final p1IncPs = v('p1IncidentPs', v('incidentPs', '------------------'));
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
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text('पोलीस स्टेशन ', style: bold),
                        pw.Text(p1Ps, style: regular),
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
              pw.SizedBox(height: 2),
              pw.Text(p1Recipient1, style: regular),
              pw.SizedBox(height: 2),
              pw.Text(p1Recipient2, style: regular),
              pw.SizedBox(height: 2),
              pw.Text(p1Recipient3, style: regular),
              pw.SizedBox(height: 8),

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
    final p2Ps = v('p2PoliceStation', v('policeStation', '_______________'));
    final p2Date = v('p2NoticeDate', v('noticeDate', '......./ ......./२०...'));
    final p2Recipient1 = v(
        'p2RecipientLine1',
        v('recipientLine1',
            '____________________________________________________________________'));
    final p2Recipient2 = v(
        'p2RecipientLine2',
        v('recipientLine2',
            '____________________________________________________________________'));
    final p2Recipient3 = v(
        'p2RecipientLine3',
        v('recipientLine3',
            '____________________________________________________________________'));

    final p2IncPs = v('p2IncidentPs', v('incidentPs', '------------------'));
    final p2Dist = v('p2District', v('district', 'यवतमाळ'));
    final p2CrimeNo = v('p2CrimeNo', v('crimeNo', '........./२०........'));
    final p2ActSec = v(
        'p2ActSec',
        v('actSec',
            '.................................................................................'));

    final p2CourtDate =
        v('p2CourtDate', v('courtDate', '......./ ......./२०.....'));
    final p2CourtTime = v('p2CourtTime', '१०:३०');
    final p2CourtPs = v('p2CourtPs', v('courtPs', '------------------'));
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
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text('पोलीस स्टेशन ', style: bold),
                        pw.Text(p2Ps, style: regular),
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
              pw.SizedBox(height: 4),
              pw.Text(p2Recipient1, style: regular),
              pw.SizedBox(height: 4),
              pw.Text(p2Recipient2, style: regular),
              pw.SizedBox(height: 4),
              pw.Text(p2Recipient3, style: regular),
              pw.SizedBox(height: 24),

              // ── PARAGRAPH 1 ──
              pw.Paragraph(
                text:
                    '        आपणास या नोटीस व्दारे कळविण्यात येते की, आपना विरूध्द पोलीस स्टेशन $p2IncPs जिल्हा $p2Dist येथे अपराध क्रमांक $p2CrimeNo कलम $p2ActSec अन्वये गुन्हा नोंद करण्यात आलेला आहे. सदर अपराधा मध्ये शिक्षा ७ वर्षा पेक्षा कमी आहे किंवा ७ वर्षा पर्यंत द्रव्यदंडा सह किंवा त्या व्यतिरीक्त होवू शकते त्यामुळे सध्या आपनास अटक करणे गरजेचे वाटत नाही.',
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
