import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> previewNilHouseSearchPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final bytes = await generateNilHouseSearchPdf(doc);
  if (!context.mounted) return;
  final fileName =
      'Nil_House_Search_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

Future<Uint8List> generateNilHouseSearchPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final loraRegular = await PdfGoogleFonts.loraRegular();
  final loraBold = await PdfGoogleFonts.loraBold();
  final devanagari = await PdfGoogleFonts.notoSansDevanagariRegular();
  final devanagariBold = await PdfGoogleFonts.notoSansDevanagariBold();

  final regular = pw.TextStyle(font: devanagari, fontSize: 10, lineSpacing: 3);
  final bold = pw.TextStyle(
    font: devanagariBold,
    fontSize: 10,
    fontWeight: pw.FontWeight.bold,
  );
  final titleStyle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 14,
    fontWeight: pw.FontWeight.bold,
    decoration: pw.TextDecoration.underline,
  );

  String v(String key) => doc[key]?.toString().trim() ?? '';

  pw.Widget underlineField(String label, String value,
      {double minWidth = 100}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(label, style: bold),
          pw.SizedBox(width: 4),
          pw.Expanded(
            child: pw.Container(
              constraints: pw.BoxConstraints(minWidth: minWidth),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
              ),
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(value.isEmpty ? ' ' : value, style: regular),
            ),
          ),
        ],
      ),
    );
  }

  pdf.addPage(
    pw.MultiPage(
      theme: pw.ThemeData.withFont(
        base: devanagari,
        bold: devanagariBold,
        fontFallback: [loraRegular, loraBold],
      ),
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.bottomRight,
        child: pw.Text('M.R.W', style: bold.copyWith(fontSize: 8)),
      ),
      build: (ctx) => [
        // ── TOP RIGHT HEADER ──
        pw.Align(
          alignment: pw.Alignment.topRight,
          child: pw.Container(
            width: 250,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                underlineField('पोलीस स्टेशन :', v('ps')),
                underlineField('कॅम्प :', v('camp')),
                underlineField('दिनांक :-', v('date')),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 12),

        // ── TITLE ──
        pw.Center(
          child: pw.Text('निल घरझडती पंचनामा', style: titleStyle),
        ),
        pw.SizedBox(height: 16),

        // ── PANCH NAMES ──
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('पंच नांव :-  ', style: bold),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  underlineField('१)', v('panch1')),
                  pw.SizedBox(height: 4),
                  underlineField('२)', v('panch2')),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 14),

        // ── PARAGRAPH 1 ──
        pw.RichText(
          text: pw.TextSpan(
            style: regular,
            children: [
              const pw.TextSpan(text: 'आम्ही  '),
              pw.TextSpan(
                text: v('officerName').isEmpty
                    ? '__________________________________________________'
                    : v('officerName'),
                style: bold,
              ),
              const pw.TextSpan(text: '  पोलीस स्टेशन  '),
              pw.TextSpan(
                text: v('officerPs').isEmpty
                    ? '__________________'
                    : v('officerPs'),
                style: bold,
              ),
              const pw.TextSpan(text: '  यांनी दिनांक  '),
              pw.TextSpan(
                text: v('summonDate').isEmpty
                    ? '...../ ....../ २०....'
                    : v('summonDate'),
                style: bold,
              ),
              const pw.TextSpan(text: '  रोजी वरील नमुद पंचांना मौजा  '),
              pw.TextSpan(
                text: v('mauza').isEmpty
                    ? '________________________'
                    : v('mauza'),
                style: bold,
              ),
              const pw.TextSpan(
                text: '  येथे बोलवून कळविले की, पो.स्टे.  ',
              ),
              pw.TextSpan(
                text: v('firPs').isEmpty ? '__________________' : v('firPs'),
                style: bold,
              ),
              const pw.TextSpan(text: '  येथे अप.क्र.  '),
              pw.TextSpan(
                text: v('crimeNo').isEmpty ? '.........' : v('crimeNo'),
                style: bold,
              ),
              const pw.TextSpan(text: ' / २०'),
              pw.TextSpan(
                text: v('crimeYear').isEmpty ? '....' : v('crimeYear'),
                style: bold,
              ),
              const pw.TextSpan(text: '  कलम  '),
              pw.TextSpan(
                text: v('actSec').isEmpty
                    ? '........................................'
                    : v('actSec'),
                style: bold,
              ),
              const pw.TextSpan(
                text:
                    '  भा.न्या.सं २०२३ अन्वये दाखल असुन चोरीच्या मालाबाबत/ अवैध प्रोहिबीशन बाबत सदर गुन्ह्यामध्ये आरोपी नामे  ',
              ),
              pw.TextSpan(
                text: v('accusedName').isEmpty
                    ? '__________________________________________________'
                    : v('accusedName'),
                style: bold,
              ),
              const pw.TextSpan(text: '  ता.-  '),
              pw.TextSpan(
                text: v('accusedTah').isEmpty
                    ? '__________________'
                    : v('accusedTah'),
                style: bold,
              ),
              const pw.TextSpan(text: '  जि '),
              pw.TextSpan(
                text: v('accusedDist').isEmpty ? 'यवतमाळ' : v('accusedDist'),
                style: bold,
              ),
              const pw.TextSpan(
                text:
                    ' याचे घराचे झडती घेणे असल्याने आपण पंच म्हणुन हजर राहावे. असे पंचाना कळवुन नमुद पंच सहमत होवून हजर आले.',
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 14),

        // ── PARAGRAPH 2 ──
        pw.RichText(
          text: pw.TextSpan(
            style: regular,
            children: [
              const pw.TextSpan(text: 'आम्ही स्वतः सोबत पंच व स्टाफसह  '),
              pw.TextSpan(
                text: v('searchPlace').isEmpty
                    ? '__________________________________________________'
                    : v('searchPlace'),
                style: bold,
              ),
              const pw.TextSpan(
                text: '  त्याचे घरी जावुन आवाज दिला असता त्याचे घरी  ',
              ),
              pw.TextSpan(
                text: v('personFound').isEmpty
                    ? '__________________________________________________'
                    : v('personFound'),
                style: bold,
              ),
              const pw.TextSpan(
                text:
                    '  हा हजर मिळाला त्याचे घरी येण्याचा उद्देश समजवून सांगुन व त्याचा नाव, गावाची खात्री करून त्याचे  ',
              ),
              pw.TextSpan(
                text: v('searchPremises').isEmpty
                    ? '__________________________________________________'
                    : v('searchPremises'),
                style: bold,
              ),
              const pw.TextSpan(
                text:
                    '  कायदेशीररित्या झडती घेतली असता त्याचे येथे सदर गुन्ह्यातील चोरी गेलेला माल/ मादक द्रव्य/ इतर संशयीत माल  ',
              ),
              pw.TextSpan(
                text: v('seizureProperty').isEmpty
                    ? '__________________________________________________'
                    : v('seizureProperty'),
                style: bold,
              ),
              const pw.TextSpan(
                text:
                    '  मिळुन आला आहे/ नाही. घर झडती दरम्यान घरामधील सामानाचे नुकसान किंवा घरातील लोकांच्या धार्मीक भावना दुखाविण्या सारखे/ धर्मा विरूध्द कोणतेही कृत्य करण्यात आले नाही.',
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 14),

        // ── CLOSING PARAGRAPH ──
        pw.RichText(
          text: pw.TextSpan(
            style: regular,
            children: [
              const pw.TextSpan(text: 'निल घरझडती पंचनामा आज दिनांक  '),
              pw.TextSpan(
                text: v('panchDate').isEmpty
                    ? '......./ ...../ २०....'
                    : v('panchDate'),
                style: bold,
              ),
              const pw.TextSpan(text: '  चे  '),
              pw.TextSpan(
                text: v('startTime').isEmpty
                    ? '....../ ........'
                    : v('startTime'),
                style: bold,
              ),
              const pw.TextSpan(text: '  वा सुरू करून  '),
              pw.TextSpan(
                text: v('endTime').isEmpty ? '...../ .....' : v('endTime'),
                style: bold,
              ),
              const pw.TextSpan(
                text:
                    '  वा मोक्यावर संपविला. पंचनामा पंचाना वाचुन दाखविला/ वाचुन पाहिला, बरोबर असल्याचे खात्री करून त्यावर त्यांनी सह्या केल्या.',
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 36),

        // ── SIGNATURES ──
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('ज्याचे घराचे झडती घेतली त्याची सही/अंगठा',
                      style: bold),
                  pw.SizedBox(height: 18),
                  pw.Container(
                    width: 200,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
                    ),
                    padding: const pw.EdgeInsets.only(bottom: 2),
                    child: pw.Text(
                      v('ownerSig').isEmpty ? ' ' : v('ownerSig'),
                      style: regular,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('समक्ष', style: bold),
                ],
              ),
            ),
            pw.SizedBox(width: 32),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('पंच सही', style: bold),
                  pw.SizedBox(height: 14),
                  underlineField('१)', v('panch1Sig'), minWidth: 150),
                  pw.SizedBox(height: 8),
                  underlineField('२)', v('panch2Sig'), minWidth: 150),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );

  return pdf.save();
}
