import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> previewGroundOfArrestPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final bytes = await generateGroundOfArrestPdf(doc);
  if (!context.mounted) return;
  final fileName =
      'Ground_of_Arrest_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

Future<Uint8List> generateGroundOfArrestPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final devanagari = await PdfGoogleFonts.notoSansDevanagariRegular();
  final devanagariBold = await PdfGoogleFonts.notoSansDevanagariBold();

  final regular = pw.TextStyle(
    font: devanagari,
    fontSize: 10.5,
    lineSpacing: 5.5,
  );
  final bold = pw.TextStyle(
    font: devanagariBold,
    fontSize: 10.5,
    fontWeight: pw.FontWeight.bold,
  );
  final headerTitle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 13.5,
    fontWeight: pw.FontWeight.bold,
  );

  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  // ══════════════════════════════════════════════════════════════════════
  // ── PAGE 1 (Image 1) ──
  // ══════════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 44, vertical: 40),
      build: (pw.Context context) {
        final outwardNo = v('outwardNo', '          ');
        final outwardYear = v('outwardYear', '२५');
        final policeStation = v('policeStation', '------------------');
        final taluka = v('taluka', '------------');
        final district = v('district', '--------------');
        final noticeDate = v('noticeDate', '     /       /२०२५');

        final accusedNameAddress = v(
          'accusedNameAddress',
          '---------------------------------------------------------------------------------------',
        );
        final accusedNameAddressLine2 = v(
          'accusedNameAddressLine2',
          '----------------------------------------------------------------------------------------------------',
        );

        final subjectPs = v('subjectPs', '----------');
        final subjectCrNo = v('subjectCrNo', '-------');
        final subjectSection = v('subjectSection', '----- ---');

        final firPs = v('firPs', '-------------------');
        final firCrNo = v('firCrNo', '-------');
        final firCrYear = v('firCrYear', '--');
        final firActSec = v('firActSec', '------------');
        final ioName = v('ioName', '--------------------');

        final briefDescription = v(
          'briefDescription',
          '----------------------------------------------------------------------',
        );
        final briefDescLine2 = v(
          'briefDescLine2',
          '----------------------------------------------------------------------------------------------------',
        );
        final briefDescLine3 = v(
          'briefDescLine3',
          '----------------------------------------------------------------------------------------------------',
        );
        final briefDescLine4 = v(
          'briefDescLine4',
          '----------------------------------------------------------------------------------------------------',
        );
        final briefDescLine5 = v(
          'briefDescLine5',
          '-------------------------------------------------',
        );

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Top Header
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'भारतीय नागरीक सुरक्षा संहिता, २०२३ चे कलम ४७ (१)(२) अन्वये',
                    style: headerTitle,
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text('सुचनापत्र', style: headerTitle),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Top Right Metadata Box
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Container(
                width: 260,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('जावक.क्रमांक- $outwardNo /२०$outwardYear',
                        style: regular),
                    pw.SizedBox(height: 2),
                    pw.Text('पोलीस स्टेशन $policeStation', style: regular),
                    pw.SizedBox(height: 2),
                    pw.Text('ता.-$taluka -जिल्हा-$district', style: regular),
                    pw.SizedBox(height: 2),
                    pw.Text('दिनांक:- $noticeDate', style: regular),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 18),

            // Recipient Section
            pw.Text('प्रति,', style: bold),
            pw.SizedBox(height: 4),
            pw.Text('नाव व पत्ता $accusedNameAddress', style: regular),
            pw.Text(accusedNameAddressLine2, style: regular),
            pw.SizedBox(height: 16),

            // Subject Section
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: regular,
                children: [
                  pw.TextSpan(
                    text:
                        'विषय:- पोलीस स्टेशन $subjectPs गुन्हा रजि.क्र.$subjectCrNo कलम $subjectSection भा.न्या.स.\n',
                    style: bold,
                  ),
                  const pw.TextSpan(
                    text:
                        '        नुसार दाखल असलेल्या गुन्ह्यांचे अनुषंगाने आरोपीस अटक करतांना अटक\n        करण्यासाठी आधारभूत मुद्दे आणि अटकेची कारणे कळविणे बाबत.',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Main Paragraph
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: regular,
                children: [
                  const pw.TextSpan(
                    text:
                        '        आपणास या सुचनापत्राद्वारे कळविण्यात येते की,आपल्या विरुद्ध पोलीस ठाणे ',
                  ),
                  pw.TextSpan(text: '$firPs ', style: bold),
                  const pw.TextSpan(text: 'येथे गुन्हा रजि.क्र.'),
                  pw.TextSpan(text: '$firCrNo/$firCrYear ', style: bold),
                  const pw.TextSpan(text: 'कलम '),
                  pw.TextSpan(text: '$firActSec ', style: bold),
                  const pw.TextSpan(
                    text:
                        'भारतीय न्याय संहिता २०२३ अन्वये गुन्हा नोंद करण्यात आला असुन, आम्ही ',
                  ),
                  pw.TextSpan(text: '$ioName ', style: bold),
                  const pw.TextSpan(
                    text:
                        'तपासी अधिकारी म्हणून सदर गुन्ह्यांचा तपास करीत आहोत.सदर गुन्ह्यांचे तपासकामी आपणास अटक करणे गरजेचे असून भारतीय नागरीक सुरक्षा संहिता २०२३ चे कलम ४७ (१)(२) नुसार आपणास अटक करण्यासाठी आधारभूत मुद्दे (भारतीय नागरीक सुरक्षा संहिता २०२३ चे कलम ४७ (१)(२) नुसार ) खालील प्रमाणे आहेत.',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // गुन्ह्यांचे संक्षीप्त विवरण
            pw.Text('गुन्ह्यांचे संक्षीप्त विवरण :- $briefDescription',
                style: regular),
            pw.Text(briefDescLine2, style: regular),
            pw.Text(briefDescLine3, style: regular),
            pw.Text(briefDescLine4, style: regular),
            pw.Text(briefDescLine5, style: regular),
            pw.SizedBox(height: 16),

            // Note & Page 2 Indicator
            pw.Text('(अधिक माहितीसाठी फिर्यादीची प्रत सोबत जोडली आहे)',
                style: regular),
            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.bottomRight,
              child: pw.Text('२..', style: bold),
            ),
          ],
        );
      },
    ),
  );

  // ══════════════════════════════════════════════════════════════════════
  // ── PAGE 2 (Image 2) ──
  // ══════════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 44, vertical: 40),
      build: (pw.Context context) {
        final ground1 = v('ground1',
            '-----------------------------------------------------------------------------------------------');
        final ground1Line2 = v('ground1Line2',
            '-----------------------------------------------------------------------------------------------');
        final ground2 = v('ground2',
            '-----------------------------------------------------------------------------------------------');
        final ground2Line2 = v('ground2Line2',
            '-----------------------------------------------------------------------------------------------');
        final ground3 = v('ground3',
            '-----------------------------------------------------------------------------------------------');
        final ground3Line2 = v('ground3Line2',
            '-----------------------------------------------------------------------------------------------');
        final ground4 = v('ground4',
            '-----------------------------------------------------------------------------------------------');
        final ground4Line2 = v('ground4Line2',
            '-----------------------------------------------------------------------------------------------');
        final ground5 = v('ground5',
            '-----------------------------------------------------------------------------------------------');
        final ground5Line2 = v('ground5Line2',
            '-----------------------------------------------------------------------------------------------');

        final relativeName = v('relativeName', '----------------');
        final relativeAddress = v('relativeAddress', '--------------------');
        final relativePhone = v('relativePhone', '---------');

        final accusedSig = v('accusedSig', '-----------------');
        final accusedName = v('accusedName', '----- ---------');
        final accusedDateTime = v('accusedDateTime', '-----------------');

        final ioSig = v('ioSig', '');
        final ioNameRank = v('ioNameRank', '------------');
        final ioPs = v('ioPs', '----------');
        final ioTah = v('ioTah', '-------');
        final ioDist = v('ioDist', '---------');

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Top Continuation Indicator
            pw.Center(
              child: pw.Text('..२..', style: bold),
            ),
            pw.SizedBox(height: 12),

            // Grounds Header
            pw.Center(
              child: pw.Text(
                'अटक करण्यासाठी आधारभूत मुद्दे (GROUNDS OF ARREST)',
                style: headerTitle,
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 18),

            // Grounds 1 to 5
            pw.Text('१. $ground1', style: regular),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 14),
              child: pw.Text(ground1Line2, style: regular),
            ),
            pw.SizedBox(height: 6),

            pw.Text('२. $ground2', style: regular),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 14),
              child: pw.Text(ground2Line2, style: regular),
            ),
            pw.SizedBox(height: 6),

            pw.Text('३. $ground3', style: regular),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 14),
              child: pw.Text(ground3Line2, style: regular),
            ),
            pw.SizedBox(height: 6),

            pw.Text('४. $ground4', style: regular),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 14),
              child: pw.Text(ground4Line2, style: regular),
            ),
            pw.SizedBox(height: 6),

            pw.Text('५. $ground5', style: regular),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 14),
              child: pw.Text(ground5Line2, style: regular),
            ),
            pw.SizedBox(height: 16),

            // Paragraph 1 (Bail Inform)
            pw.Text(
              '        आपणास असेही कळविण्यात येते की, नमुद गुन्हा हा दखलपात्र असुन अजामीनपात्र आहे आणि त्यामुळे आपण त्या गुन्ह्यात न्यायालयात जामिनाचा अर्ज सादर करुन न्यायालयाचे आदेशाने जामिनावर मुक्त होवु शकता.',
              style: regular,
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 12),

            // Paragraph 2 (Relative Inform)
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: regular,
                children: [
                  const pw.TextSpan(
                    text:
                        '        आपल्या अटकेची माहीती आपले नातेवाईक/ मित्र ',
                  ),
                  pw.TextSpan(text: '$relativeName ', style: bold),
                  const pw.TextSpan(text: 'रा.'),
                  pw.TextSpan(text: '$relativeAddress ', style: bold),
                  const pw.TextSpan(text: 'यांना लेखी सुचनेद्वारे/फोन क्रमांक '),
                  pw.TextSpan(text: '$relativePhone ', style: bold),
                  const pw.TextSpan(
                    text: 'यावर संपर्क करुन देण्यांत आली आहे.',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Paragraph 3 (Closing)
            pw.Text(
              '        याकरीता आपणास सुचनापत्र देण्यांत येत आहे.',
              style: regular,
            ),
            pw.Spacer(),

            // Signatures (2 columns)
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left Column
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('मला सुचनापत्र प्राप्त झाले', style: bold),
                      pw.SizedBox(height: 6),
                      pw.Text('(आरोपीची सही $accusedSig)', style: regular),
                      pw.SizedBox(height: 4),
                      pw.Text('आरोपीचे नांव $accusedName', style: regular),
                      pw.SizedBox(height: 4),
                      pw.Text('दिनांक:व वेळ $accusedDateTime', style: regular),
                    ],
                  ),
                ),
                pw.SizedBox(width: 32),

                // Right Column
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('तपास अधि सही/- $ioSig', style: bold),
                      pw.SizedBox(height: 6),
                      pw.Text('नाव/हुद्दा $ioNameRank', style: regular),
                      pw.SizedBox(height: 4),
                      pw.Text('पोलीस स्टेशन $ioPs', style: regular),
                      pw.SizedBox(height: 4),
                      pw.Text('ता.-$ioTah जिल्हा-$ioDist', style: regular),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}
