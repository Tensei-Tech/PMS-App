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
  final fileName = 'Ground_of_Arrest_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

  final regularStyle = pw.TextStyle(
    font: devanagari,
    fontSize: 10,
    lineSpacing: 2,
  );
  final boldStyle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 10.5,
    fontWeight: pw.FontWeight.bold,
  );
  final titleStyle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 12.5,
    fontWeight: pw.FontWeight.bold,
  );
  final headerStyle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 13,
    fontWeight: pw.FontWeight.bold,
  );

  String v(String key) => doc[key]?.toString().trim() ?? '';

  pw.Widget underlineField(String text, {double? width, double minWidth = 40}) {
    return pw.Container(
      width: width,
      constraints: pw.BoxConstraints(minWidth: minWidth),
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
        ),
      ),
      child: pw.Text(
        text.isEmpty ? ' ' : text,
        style: pw.TextStyle(
          font: devanagariBold,
          fontSize: 9.5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget multilineLines(String text, {int lines = 4}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
        ),
      ),
      child: pw.Text(
        text.isEmpty ? ' ' : text,
        style: pw.TextStyle(font: devanagari, fontSize: 9.5),
      ),
    );
  }

  final section = v('formSection').toLowerCase();
  final showPage1 = section.isEmpty || section.contains('main') || section.contains('page 1') || section.contains('1');
  final showPage2 = section.isEmpty || section.contains('continuation') || section.contains('page 2') || section.contains('2');

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 1 PDF
  // ══════════════════════════════════════════════════════════════════════════
  if (showPage1) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Header ──
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'भारतीय नागरीक सुरक्षा संहिता, २०२३ चे कलम ४७ (१)(२) अन्वये',
                    style: headerStyle,
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'सुचनापत्र',
                    style: titleStyle,
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ── Top Right Reference Details ──
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.SizedBox(
                width: 260,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text('जावक.क्रमांक- ', style: regularStyle),
                        pw.Expanded(child: underlineField(v('outwardNo'))),
                        pw.Text(' / २०२५', style: regularStyle),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      children: [
                        pw.Text('पोलीस स्टेशन - ', style: regularStyle),
                        pw.Expanded(child: underlineField(v('policeStation'))),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      children: [
                        pw.Text('ता.- ', style: regularStyle),
                        underlineField(v('taluka'), width: 75),
                        pw.Text(' -जिल्हा- ', style: regularStyle),
                        pw.Expanded(child: underlineField(v('district'))),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      children: [
                        pw.Text('दिनांक:- ', style: regularStyle),
                        underlineField(v('noticeDateDay'), width: 30),
                        pw.Text(' / ', style: regularStyle),
                        underlineField(v('noticeDateMonth'), width: 30),
                        pw.Text(' / २०२५', style: regularStyle),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 14),

            // ── To / Name & Address ──
            pw.Text('प्रति,', style: regularStyle),
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                pw.Text('नाव व पत्ता ', style: regularStyle),
                pw.Expanded(child: underlineField(v('accusedNameAddress'))),
              ],
            ),
            pw.SizedBox(height: 14),

            // ── Subject Paragraph ──
            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              spacing: 3,
              runSpacing: 4,
              children: [
                pw.Text('विषय:- पोलीस स्टेशन', style: boldStyle),
                underlineField(v('subjectPs'), width: 120),
                pw.Text('गुन्हा रजि.क्र.-', style: boldStyle),
                underlineField(v('subjectCrNo'), width: 70),
                pw.Text('-कलम', style: boldStyle),
                underlineField(v('subjectSection'), width: 90),
                pw.Text('भा.न्या.स.', style: boldStyle),
                pw.Text(
                  'नुसार दाखल असलेल्या गुन्ह्यांचे अनुषंगाने आरोपीस अटक करतांना अटक',
                  style: boldStyle,
                ),
                pw.Text(
                  'करण्यासाठी आधारभूत मुद्दे आणि अटकेची कारणे कळविणे बाबत.',
                  style: boldStyle,
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // ── Main Notice Paragraph ──
            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              spacing: 3,
              runSpacing: 5,
              children: [
                pw.Text('आपणास या सुचनापत्राद्वारे कळविण्यात येते की,आपल्या विरुध्द पोलीस ठाणे', style: regularStyle),
                underlineField(v('noticePs').isEmpty ? v('policeStation') : v('noticePs'), width: 140),
                pw.Text('येथे गुन्हा रजि.क्र.-', style: regularStyle),
                underlineField(v('noticeCrNo').isEmpty ? v('subjectCrNo') : v('noticeCrNo'), width: 60),
                pw.Text('/', style: regularStyle),
                underlineField(v('noticeCrYear'), width: 40),
                pw.Text('कलम', style: regularStyle),
                underlineField(v('noticeSection').isEmpty ? v('subjectSection') : v('noticeSection'), width: 110),
                pw.Text('भारतीय न्याय संहीता २०२३ अन्वये गुन्हा नोंद करण्यात आला असुन,आम्ही-', style: regularStyle),
                underlineField(v('ioName'), width: 160),
                pw.Text(
                  'तपासी अधिकारी म्हणून सदर गुन्हयांचा तपास करीत आहोत.सदर गुन्हयांचे तपासकामी आपणास अटक करणे गरजेचे असून भारतीय नागरीक सुरक्षा संहिता २०२३ चे कलम ४७ (१)(२) नुसार आपणास अटक करण्यासाठी आधारभूत मुद्दे (भारतीय नागरीक सुरक्षा संहिता २०२३ चे कलम ४७ (१)(२) नुसार ) खालील प्रमाणे आहेत.',
                  style: regularStyle,
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            // ── Brief Description Heading & Box ──
            pw.Text('गुन्हयांचे संक्षीप्त विवरण :-', style: boldStyle),
            pw.SizedBox(height: 4),
            multilineLines(v('offenceSummary').isEmpty ? v('briefDescription') : v('offenceSummary'), lines: 4),
            pw.Spacer(),

            // ── Bottom Notes ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('(अधिक माहितीसाठी फिर्यादीची प्रत सोबत जोडली आहे)', style: regularStyle),
                pw.Text('२..', style: boldStyle),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 2 PDF
  // ══════════════════════════════════════════════════════════════════════════
  if (showPage2) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Header Page 2 ──
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('..२..', style: boldStyle),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'अटक करण्यासाठी आधारभूत मुद्दे (GROUNDS OF ARREST)',
                    style: titleStyle,
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // ── Grounds 1 to 5 ──
            for (var i = 1; i <= 5; i++) ...[
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      i == 1 ? '१. ' : i == 2 ? '२. ' : i == 3 ? '३. ' : i == 4 ? '४. ' : '५. ',
                      style: boldStyle,
                    ),
                    pw.Expanded(
                      child: multilineLines(v('ground$i'), lines: 2),
                    ),
                  ],
                ),
              ),
            ],
            pw.SizedBox(height: 10),

            // ── Bail Rights Notice ──
            pw.Text(
              'आपणास असेही कळविण्यांत येते की, नमुद गुन्हा हा दखलपात्र असुन अजामीनपात्र आहे आणि त्यामुळे आपण त्या गुन्हयात न्यायालयात जामिनाचा अर्ज सादर करुन न्यायालयाचे आदेशाने जामिनावर मुक्त होवु शकता.',
              style: regularStyle,
            ),
            pw.SizedBox(height: 12),

            // ── Relative / Friend Intimation ──
            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              spacing: 3,
              runSpacing: 4,
              children: [
                pw.Text('आपल्या अटकेची माहीती आपले नातेवाईक/ मित्र', style: regularStyle),
                underlineField(v('relativeName'), width: 140),
                pw.Text('रा.', style: regularStyle),
                underlineField(v('relativeResiding').isEmpty ? v('relativeAddress') : v('relativeResiding'), width: 90),
                pw.Text('यांना लेखी सुचनेव्दारे/फोन क्रमांक', style: regularStyle),
                underlineField(v('relativePhone'), width: 110),
                pw.Text('यावर संपर्क करुन देण्यांत आली आहे.', style: regularStyle),
              ],
            ),
            pw.SizedBox(height: 10),

            // ── Closing line ──
            pw.Text('याकरीता आपणास सुचनापत्र देण्यांत येत आहे.', style: regularStyle),
            pw.SizedBox(height: 24),

            // ── Signatures 2-Column Row ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left Column: Accused Sign
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('मला सुचनापत्र प्राप्त झाले', style: boldStyle),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Text('(आरोपीची सही ', style: regularStyle),
                          pw.Expanded(child: underlineField(v('accusedSig'))),
                          pw.Text(')', style: regularStyle),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Text('आरोपीचे नांव ', style: regularStyle),
                          pw.Expanded(child: underlineField(v('accusedName').isEmpty ? v('accusedNameSig') : v('accusedName'))),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Text('दिनांक:व वेळ ', style: regularStyle),
                          pw.Expanded(child: underlineField(v('accusedDateTime'))),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 30),

                // Right Column: IO Sign
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('तपास अधि सही/-', style: boldStyle),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Text('नाव/हुद्दा ', style: regularStyle),
                          pw.Expanded(child: underlineField(v('ioNameRank'))),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Text('पोलीस स्टेशन ', style: regularStyle),
                          pw.Expanded(child: underlineField(v('ioPs').isEmpty ? v('policeStation') : v('ioPs'))),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Text('ता.- ', style: regularStyle),
                          underlineField(v('ioTaluka').isEmpty ? v('taluka') : v('ioTaluka'), width: 60),
                          pw.Text(' -जिल्हा- ', style: regularStyle),
                          pw.Expanded(child: underlineField(v('ioDistrict').isEmpty ? v('district') : v('ioDistrict'))),
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
