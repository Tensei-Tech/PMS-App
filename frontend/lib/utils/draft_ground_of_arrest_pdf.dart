import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> previewDraftGroundOfArrestPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final bytes = await generateDraftGroundOfArrestPdf(doc);
  if (!context.mounted) return;
  final fileName =
      'Draft_Ground_of_Arrest_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

int? _activeSection(String section) {
  final s = section.toLowerCase().trim();
  if (s.isEmpty) return null;
  if (s.contains('pcr') || s.contains('police custody')) return 4;
  if (s.contains('reason of arrest') || s.contains('reason for arrest') || s.contains('page 11')) {
    return 3;
  }
  if (s.contains('relative notice') || s.contains('नातेवाईक') || s.contains('page 10')) {
    return 2;
  }
  if (s.contains('ground of arrest') || s.contains('अटकेचा आधार') || s.contains('page 9')) {
    return 1;
  }
  if (s.contains('ref') || s.contains('guide')) {
    return 0;
  }
  return null;
}

Future<Uint8List> generateDraftGroundOfArrestPdf(
  Map<String, dynamic> doc,
) async {
  final pdf = pw.Document();
  final devanagari = await PdfGoogleFonts.notoSansDevanagariRegular();
  final devanagariBold = await PdfGoogleFonts.notoSansDevanagariBold();

  final regularStyle = pw.TextStyle(
    font: devanagari,
    fontSize: 9.5,
    lineSpacing: 1.5,
  );
  final boldStyle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 9.5,
    fontWeight: pw.FontWeight.bold,
  );
  final titleStyle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 12.5,
    fontWeight: pw.FontWeight.bold,
    decoration: pw.TextDecoration.underline,
  );

  String v(String key) => doc[key]?.toString().trim() ?? '';
  bool b(String key) => doc[key] == true || doc[key] == 'true' || doc[key] == '1';

  pw.Widget underlineField(String text, {double? width, double minWidth = 35}) {
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
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget multilineUnderline(String text, {int lines = 2}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
        ),
      ),
      child: pw.Text(
        text.isEmpty ? ' ' : text,
        style: regularStyle,
      ),
    );
  }

  pw.Widget prosecutorBox() {
    return pw.Align(
      alignment: pw.Alignment.topRight,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('Gaware Ashok', style: pw.TextStyle(font: devanagariBold, fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
            pw.Text('Public Prosecutor A.Nagar', style: pw.TextStyle(font: devanagariBold, fontSize: 8)),
            pw.Text('9823911047', style: pw.TextStyle(font: devanagariBold, fontSize: 8)),
          ],
        ),
      ),
    );
  }

  pw.TableRow tableHeaderRow(String col1, String col2) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: pw.Text(
            col1,
            textAlign: pw.TextAlign.center,
            style: boldStyle,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: pw.Text(
            col2,
            textAlign: pw.TextAlign.center,
            style: boldStyle,
          ),
        ),
      ],
    );
  }

  pw.TableRow checkTableRow(String srNo, bool checked, pw.Widget content) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(checked ? '[v] ' : '[  ] ', style: boldStyle),
              pw.Text(srNo, style: boldStyle),
            ],
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: content,
        ),
      ],
    );
  }

  pw.TableRow simpleTableRow(String srNo, pw.Widget content) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: pw.Text(
            srNo,
            textAlign: pw.TextAlign.center,
            style: boldStyle,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: content,
        ),
      ],
    );
  }

  final section = _activeSection(v('formSection'));
  final showPage9 = section == null || section == 1;
  final showPage10 = section == null || section == 2;
  final showPage11 = section == null || section == 3;
  final showPage12 = section == 4;

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 9 OF 13 PDF
  // ══════════════════════════════════════════════════════════════════════════
  if (showPage9) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 28),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            prosecutorBox(),
            pw.SizedBox(height: 4),
            pw.Center(child: pw.Text('Page 9 of 13', style: boldStyle)),
            pw.SizedBox(height: 3),
            pw.Center(child: pw.Text('अटकेचा आधार (कलम ४७ BNSS)', style: titleStyle, textAlign: pw.TextAlign.center)),
            pw.SizedBox(height: 6),
            pw.Text(
              '(भारतीय नागरिक सुरक्षा संहिता, २०२३ च्या कलम ४७ आणि भारतीय संविधान कलम २२(१) अन्वये तसेच माननीय सर्वोच्च न्यायालयाच्या \'पंकज बन्सल\', \'प्रबीर पुरकायस्थ\', \'विहान कुमार\' आणि \'मिहीर शाह\' निवाड्यांमधील मार्गदर्शक तत्त्वांच्या अधीन)',
              textAlign: pw.TextAlign.center,
              style: regularStyle.copyWith(fontSize: 8),
            ),
            pw.SizedBox(height: 8),

            pw.Text('प्रति,', style: boldStyle),
            pw.SizedBox(height: 3),
            pw.Row(
              children: [
                pw.Text('अटक केलेल्या आरोपीचे नाव: ', style: regularStyle),
                pw.Expanded(child: underlineField(v('accusedName'))),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                pw.Text('वय: ', style: regularStyle),
                underlineField(v('accusedAge'), width: 45),
                pw.Text(' वर्ष, पत्ता: ', style: regularStyle),
                pw.Expanded(child: underlineField(v('accusedAddress'))),
              ],
            ),
            pw.SizedBox(height: 5),

            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              spacing: 2,
              runSpacing: 3,
              children: [
                pw.Text('या नोटीसीद्वारे तुम्हाला माहिती करण्यात येते की, तुम्हाला पोलीस ठाणे', style: regularStyle),
                underlineField(v('psName'), width: 110),
                pw.Text('येथे दाखल असलेल्या गुन्हा रजिस्टर क्रमांक', style: regularStyle),
                underlineField(v('crNo'), width: 70),
                pw.Text(', अंतर्गत भारतीय न्याय संहिता, २०२३ (BNS) च्या कलम', style: regularStyle),
                underlineField(v('bnsSection'), width: 85),
                pw.Text('अन्वये नोंदवलेल्या गुन्ह्यात आज दिनांक', style: regularStyle),
                underlineField(v('arrestDate'), width: 70),
                pw.Text('रोजी वेळ', style: regularStyle),
                underlineField(v('arrestTime'), width: 50),
                pw.Text('वाजता अटक करण्यात आली आहे.', style: regularStyle),
              ],
            ),
            pw.SizedBox(height: 6),

            pw.Text('गुन्ह्याची थोडक्यात हकीकत :-', style: boldStyle),
            pw.SizedBox(height: 2),
            multilineUnderline(v('briefFacts'), lines: 2),
            pw.SizedBox(height: 6),

            pw.Text('अटकेचा आधार :-', style: boldStyle),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
              columnWidths: const {
                0: pw.FixedColumnWidth(48),
                1: pw.FlexColumnWidth(1),
              },
              children: [
                tableHeaderRow('अ.क्र.', 'अटकेचे आधार ( Ground of Arrest )'),
                checkTableRow('१', b('goaG1'), pw.Text('फिर्यादीने दाखल केलेल्या FIR मध्ये तुमचे विरुद्ध आरोप केलेले आहेत.', style: regularStyle)),
                checkTableRow('२', b('goaG2'), pw.Wrap(
                  crossAxisAlignment: pw.WrapCrossAlignment.center,
                  children: [
                    pw.Text('प्रत्यक्षदर्शी साक्षीदार [नाव] ', style: regularStyle),
                    underlineField(v('goaWitnessName'), width: 90),
                    pw.Text(' यांनी दिलेल्या जबाबानुसार गुन्ह्यामध्ये तुमचा थेट सहभाग असल्याचे निष्पन्न झाले आहे.', style: regularStyle),
                  ],
                )),
                checkTableRow('३', b('goaG3'), pw.Text('घटनास्थळावरील पुराव्यांच्या (CCTV / डिजिटल रेकॉर्ड / मोबाईल व्हिडिओ ) आधारे गुन्ह्यामध्ये तुमचा थेट सहभाग असल्याचे निष्पन्न झाले आहे.', style: regularStyle)),
                checkTableRow('४', b('goaG4'), pw.Text('गुन्ह्यात वापरलेले हत्यार / चोरीची मालमत्ता / गुन्ह्याशी संबंधित महत्त्वाचे दस्तऐवज हे केवळ तुमच्याकडे असलेल्या माहितीच्या आधारे आणि तुमच्या ताब्यातून हस्तगत करण्यात आले आहेत.', style: regularStyle)),
                checkTableRow('५', b('goaG5'), pw.Text('तुम्ही गुन्हा केल्याची कबुली दिली आहे.', style: regularStyle)),
                checkTableRow('६', b('goaG6'), pw.Wrap(
                  crossAxisAlignment: pw.WrapCrossAlignment.center,
                  children: [
                    pw.Text('गुन्ह्यातील सहआरोपी ', style: regularStyle),
                    underlineField(v('goaCoAccused'), width: 90),
                    pw.Text(' यांनी तुम्ही गुन्ह्यामध्ये सहभागी असल्याचे कबुल केले आहे.', style: regularStyle),
                  ],
                )),
                checkTableRow('७', b('goaG7'), pw.Text('मोबाईल CDR वरून घटनेच्या दिवशी तुमचे tower location घटनास्थळाजवळ असल्याचे दिसून आले आहे.', style: regularStyle)),
              ],
            ),
            pw.SizedBox(height: 6),

            pw.Text('आरोपींचे हक्क /अधिकार :-', style: boldStyle),
            pw.SizedBox(height: 3),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
              columnWidths: const {
                0: pw.FixedColumnWidth(48),
                1: pw.FlexColumnWidth(1),
              },
              children: [
                tableHeaderRow('अ.क्र.', 'आरोपींचे हक्क'),
                simpleTableRow('१', pw.Text('तुम्हाला माननीय न्यायालयासमोर हजर केल्यावर जामीन अर्ज सादर करण्याचा पूर्ण कायदेशीर अधिकार आहे.', style: regularStyle)),
                simpleTableRow('२', pw.Text('तुमच्या पसंतीच्या कायदेशीर सल्लागाराचा (वकिलाचा) सल्ला घेण्याचा, त्यांना पोलीस कोठडीत भेटण्याचा आणि माननीय न्यायालयासमोर रिमांडला कायदेशीर विरोध करण्याचा पूर्ण अधिकार आहे.', style: regularStyle)),
                simpleTableRow('३', pw.Wrap(
                  crossAxisAlignment: pw.WrapCrossAlignment.center,
                  children: [
                    pw.Text('तुमच्या अटकेची आणि तुम्हाला ज्या ठिकाणी कोठडीत ठेवण्यात आले आहे त्या ठिकाणाची माहिती तुमच्याद्वारे नामांकित केलेले नातेवाईक/मित्र ', style: regularStyle),
                    underlineField(v('goaKinName'), width: 110),
                    pw.Text(' यांना देण्यात आली आहे.', style: regularStyle),
                  ],
                )),
              ],
            ),
            pw.Spacer(),

            // Footer
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Row(
                    children: [
                      pw.Text('दिनांक :- ', style: regularStyle),
                      pw.Expanded(child: underlineField(v('goaFooterDate'))),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Text('पोलीस अधिकारी नाव, हुद्दा सही शिक्का', style: boldStyle, textAlign: pw.TextAlign.center),
                      underlineField(v('goaOfficerNameRank').isEmpty ? v('goaOfficerName') : v('goaOfficerNameRank')),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Text('आरोपीचे नाव , सही, अंगठा', style: boldStyle, textAlign: pw.TextAlign.center),
                      underlineField(v('goaAccusedSig')),
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

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 10 OF 13 PDF
  // ══════════════════════════════════════════════════════════════════════════
  if (showPage10) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 28),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            prosecutorBox(),
            pw.SizedBox(height: 4),
            pw.Center(child: pw.Text('Page 10 of 13', style: boldStyle)),
            pw.SizedBox(height: 3),
            pw.Center(child: pw.Text('नातेवाईक/ मित्रांसाठी अटकेच्या माहितीची नोटीस ( कलम ४८ BNSS)', style: titleStyle, textAlign: pw.TextAlign.center)),
            pw.SizedBox(height: 6),
            pw.Text(
              '(भारतीय नागरिक सुरक्षा संहिता, २०२३ च्या कलम ४८(१) अन्वये माननीय सर्वोच्च न्यायालयाच्या \'पंकज बन्सल\', \'प्रबीर पुरकायस्थ\', \'विहान कुमार\' आणि \'मिहीर शाह\' निवाड्यांमधील मार्गदर्शक तत्त्वांच्या अधीन)',
              textAlign: pw.TextAlign.center,
              style: regularStyle.copyWith(fontSize: 8),
            ),
            pw.SizedBox(height: 8),

            pw.Text('प्रति,', style: boldStyle),
            pw.SizedBox(height: 3),
            pw.Row(
              children: [
                pw.Text('नातेवाईक/मित्राचे नाव:- ', style: regularStyle),
                pw.Expanded(flex: 3, child: underlineField(v('s48RelativeName'))),
                pw.Text(' वय :- ', style: regularStyle),
                underlineField(v('s48RelativeAge'), width: 35),
                pw.Text(' पत्ता:- ', style: regularStyle),
                pw.Expanded(flex: 3, child: underlineField(v('s48RelativeAddress'))),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                pw.Text('आरोपीशी असलेले नाते: ', style: regularStyle),
                pw.Expanded(child: underlineField(v('s48Relationship'))),
              ],
            ),
            pw.SizedBox(height: 5),

            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              spacing: 2,
              runSpacing: 3,
              children: [
                pw.Text('या नोटीसीद्वारे तुम्हाला, भारतीय नागरिक सुरक्षा संहिता, २०२३ (BNSS) च्या कलम ४८(१) मधील कायदेशीर तरतुदींनुसार अधिकृतपणे सूचित करण्यात येते की, तुमचे/तुमच्या आरोपीचे नाव:', style: regularStyle),
                underlineField(v('s48AccusedName').isEmpty ? v('accusedName') : v('s48AccusedName'), width: 110),
                pw.Text('वय:', style: regularStyle),
                underlineField(v('s48AccusedAge').isEmpty ? v('accusedAge') : v('s48AccusedAge'), width: 35),
                pw.Text('वर्ष, पत्ता:-', style: regularStyle),
                underlineField(v('s48AccusedAddress').isEmpty ? v('accusedAddress') : v('s48AccusedAddress'), width: 110),
                pw.Text('यांना पोलीस ठाणे', style: regularStyle),
                underlineField(v('psName'), width: 100),
                pw.Text('येथे दाखल असलेल्या गुन्हा रजिस्टर क्रमांक (Cr.No.)', style: regularStyle),
                underlineField(v('crNo'), width: 65),
                pw.Text(', अंतर्गत भारतीय न्याय संहिता, २०२३ (BNS) च्या कलम', style: regularStyle),
                underlineField(v('bnsSection'), width: 75),
                pw.Text('अन्वये नोंदवलेल्या गुन्ह्याच्या तपासाच्या अनुषंगाने आज दिनांक', style: regularStyle),
                underlineField(v('arrestDate'), width: 65),
                pw.Text('रोजी वेळ', style: regularStyle),
                underlineField(v('arrestTime'), width: 45),
                pw.Text('वाजता कायदेशीररीत्या अटक करण्यात आली आहे.', style: regularStyle),
              ],
            ),
            pw.SizedBox(height: 6),

            pw.Text('गुन्ह्याची थोडक्यात हकीकत :-', style: boldStyle),
            pw.SizedBox(height: 2),
            multilineUnderline(v('briefFacts'), lines: 2),
            pw.SizedBox(height: 6),

            pw.Text('आरोपींच्या अटकेबाबत तुम्हाला खालील बाबींची लेखी माहिती देण्यात येत आहे:-', style: boldStyle),
            pw.SizedBox(height: 3),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
              columnWidths: const {
                0: pw.FixedColumnWidth(48),
                1: pw.FlexColumnWidth(1),
              },
              children: [
                tableHeaderRow('अ.क्र.', 'अटकेबाबत माहिती'),
                simpleTableRow('१.', pw.Wrap(
                  crossAxisAlignment: pw.WrapCrossAlignment.center,
                  children: [
                    pw.Text('आरोपी नाव ', style: regularStyle),
                    underlineField(v('s48AccusedName').isEmpty ? v('accusedName') : v('s48AccusedName'), width: 90),
                    pw.Text(' यांना गुन्हा रजिस्टर क्रमांक ', style: regularStyle),
                    underlineField(v('crNo'), width: 55),
                    pw.Text(', अंतर्गत भारतीय न्याय संहिता, २०२३ (BNS) च्या कलम ', style: regularStyle),
                    underlineField(v('bnsSection'), width: 65),
                    pw.Text(' अन्वये नोंदवलेल्या गुन्ह्याच्या तपासाच्या अनुषंगाने कायदेशीररीत्या अटक करण्यात आली असून सदर आरोपीला सध्या [पोलीस ठाण्याचे नाव ', style: regularStyle),
                    underlineField(v('s48CustodyPs').isEmpty ? v('psName') : v('s48CustodyPs'), width: 90),
                    pw.Text('] येथे ठेवण्यात आले आहे.', style: regularStyle),
                  ],
                )),
                simpleTableRow('२.', pw.Text('आरोपीला माननीय न्यायालयासमोर हजर केल्यावर जामीन अर्ज सादर करण्याचा पूर्ण कायदेशीर अधिकार आहे.', style: regularStyle)),
                simpleTableRow('३.', pw.Text('तुमच्या पसंतीच्या कायदेशीर सल्लागाराचा (वकिलाचा) सल्ला घेण्याचा, त्यांना पोलीस कोठडीत भेटण्याचा आणि माननीय न्यायालयासमोर रिमांडला कायदेशीर विरोध करण्याचा पूर्ण अधिकार आहे.', style: regularStyle)),
              ],
            ),
            pw.SizedBox(height: 6),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
              columnWidths: const {
                0: pw.FixedColumnWidth(48),
                1: pw.FlexColumnWidth(1),
              },
              children: [
                tableHeaderRow('अ.क्र.', 'अटकेचे आधार ( Ground of Arrest )'),
                checkTableRow('१', b('s48G1'), pw.Text('FIR मध्ये आरोपीने सदर गुन्हा केल्याचा उल्लेख आहे.', style: regularStyle)),
                checkTableRow('२', b('s48G2'), pw.Wrap(
                  crossAxisAlignment: pw.WrapCrossAlignment.center,
                  children: [
                    pw.Text('प्रत्यक्षदर्शी साक्षीदार [नाव] ', style: regularStyle),
                    underlineField(v('s48WitnessName'), width: 90),
                    pw.Text(' यांनी दिलेल्या जबाबानुसार गुन्ह्यामध्ये आरोपीचा थेट सहभाग असल्याचे निष्पन्न झाले आहे.', style: regularStyle),
                  ],
                )),
                checkTableRow('३', b('s48G3'), pw.Text('घटनास्थळावरील पुराव्यांच्या CCTV / डिजिटल रेकॉर्ड आधारे गुन्ह्यामध्ये थेट सहभाग असल्याचे निष्पन्न झाले आहे.', style: regularStyle)),
                checkTableRow('५', b('s48G5'), pw.Text('आरोपीने गुन्हा केल्याची कबुली दिली आहे.', style: regularStyle)),
                checkTableRow('६', b('s48G6'), pw.Wrap(
                  crossAxisAlignment: pw.WrapCrossAlignment.center,
                  children: [
                    pw.Text('गुन्ह्यातील सहआरोपी ', style: regularStyle),
                    underlineField(v('s48CoAccused'), width: 90),
                    pw.Text(' यांनी गुन्ह्यामध्ये आरोपी सहभागी असल्याचे कबुल केले आहे.', style: regularStyle),
                  ],
                )),
              ],
            ),
            pw.Spacer(),

            // Footer Signatures
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text('दिनांक :- ', style: regularStyle),
                          pw.Expanded(child: underlineField(v('s48Date'))),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        children: [
                          pw.Text('ठिकाण :- ', style: regularStyle),
                          pw.Expanded(child: underlineField(v('s48Place'))),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Text('पोलीस अधिकारी नाव सही शिक्का', style: boldStyle, textAlign: pw.TextAlign.center),
                      underlineField(v('s48OfficerSig')),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Text('नातेवाईक/ मित्र यांचे नाव , सही, अंगठा', style: boldStyle, textAlign: pw.TextAlign.center),
                      underlineField(v('s48RelativeSig')),
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

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 11 OF 13 PDF
  // ══════════════════════════════════════════════════════════════════════════
  if (showPage11) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 28),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            prosecutorBox(),
            pw.SizedBox(height: 4),
            pw.Center(child: pw.Text('Page 11 of 13', style: boldStyle)),
            pw.SizedBox(height: 3),
            pw.Center(child: pw.Text('अटकेचे कारणे [कलम ३५(१)(ब) BNSS ]', style: titleStyle, textAlign: pw.TextAlign.center)),
            pw.SizedBox(height: 6),
            pw.Text(
              '(भारतीय नागरिक सुरक्षा संहिता, २०२३ कलम ३५(१)(ब) अन्वये मा. सर्वोच्च न्यायालयाच्या मार्गदर्शक तत्त्वांच्या निकषांच्या अधीन)',
              textAlign: pw.TextAlign.center,
              style: regularStyle.copyWith(fontSize: 8),
            ),
            pw.SizedBox(height: 8),

            pw.Text('प्रति,', style: boldStyle),
            pw.SizedBox(height: 3),
            pw.Row(
              children: [
                pw.Text('अटक केलेल्या आरोपीचे नाव:- ', style: regularStyle),
                pw.Expanded(child: underlineField(v('accusedName'))),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                pw.Text('वय:- ', style: regularStyle),
                underlineField(v('accusedAge'), width: 45),
                pw.Text(' वर्ष, पत्ता:- ', style: regularStyle),
                pw.Expanded(child: underlineField(v('accusedAddress'))),
              ],
            ),
            pw.SizedBox(height: 5),

            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              spacing: 2,
              runSpacing: 3,
              children: [
                pw.Text('या नोटीसीद्वारे तुम्हाला सूचित करण्यात येते की, पोलीस ठाणे [पोलीस ठाण्याचे नाव]', style: regularStyle),
                underlineField(v('psName'), width: 110),
                pw.Text('येथे दाखल असलेल्या गुन्हा रजिस्टर क्रमांक', style: regularStyle),
                underlineField(v('crNo'), width: 70),
                pw.Text(', अंतर्गत भारतीय न्याय संहिता, २०२३ (BNS) च्या कलम', style: regularStyle),
                underlineField(v('bnsSection'), width: 85),
                pw.Text('अन्वये नोंदवलेल्या गुन्ह्यात तपासाच्या अनुषंगाने आज दिनांक', style: regularStyle),
                underlineField(v('arrestDate'), width: 70),
                pw.Text('रोजी वेळ', style: regularStyle),
                underlineField(v('arrestTime'), width: 50),
                pw.Text('वाजता अटक करण्यात आली आहे.', style: regularStyle),
              ],
            ),
            pw.SizedBox(height: 6),

            pw.Text('गुन्ह्याची थोडक्यात हकीकत :-', style: boldStyle),
            pw.SizedBox(height: 2),
            multilineUnderline(v('briefFacts'), lines: 2),
            pw.SizedBox(height: 6),

            pw.Text('अटकेची कारणे (Reasons for Arrest) खालीलप्रमाणे लिखित स्वरूपात पुरवण्यात येत आहेत:-', style: boldStyle),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
              columnWidths: const {
                0: pw.FixedColumnWidth(48),
                1: pw.FlexColumnWidth(1),
              },
              children: [
                tableHeaderRow('अ.क्र.', 'अटकेचे कारणे ( Reason of Arrest )'),
                checkTableRow('१', b('roaR1'), pw.Text('या पुढे कोणताही गुन्हा करण्यास प्रतिबंध करण्यासाठी अटक करण्यात आली आहे.', style: regularStyle)),
                checkTableRow('२', b('roaR2'), pw.Text('गुन्ह्याचा योग्य तपास / अन्वेषण करण्यासाठी .', style: regularStyle)),
                checkTableRow('३', b('roaR3'), pw.Text('गुन्ह्यातील पुरावा नष्ट किंवा पुराव्यांशी छेडछाड / फेरफार करण्यापासून रोखण्यासाठी', style: regularStyle)),
                checkTableRow('४', b('roaR4'), pw.Text('गुन्ह्यातील साक्षीदारांना धाक, धाकडपटशा, वचन किंवा प्रलोभन देण्यापासून रोखणे, धमकावण्यापासून रोखण्यासाठी', style: regularStyle)),
                checkTableRow('५', b('roaR5'), pw.Text('न्यायालयातील उपस्थिती निश्चित करण्यासाठी अटक न केल्यास तुम्ही तपासातून आणि न्यायालयाच्या प्रक्रियेतून फरार होण्याची शक्यता आहे', style: regularStyle)),
              ],
            ),
            pw.Spacer(),

            // Footer Signatures
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text('दिनांक :- ', style: regularStyle),
                          pw.Expanded(child: underlineField(v('roaDate'))),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        children: [
                          pw.Text('ठिकाण :- ', style: regularStyle),
                          pw.Expanded(child: underlineField(v('roaPlace'))),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Text('पोलीस अधिकारी नाव सही शिक्का', style: boldStyle, textAlign: pw.TextAlign.center),
                      underlineField(v('roaOfficerSig')),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Text('आरोपीचे नाव , सही, अंगठा', style: boldStyle, textAlign: pw.TextAlign.center),
                      underlineField(v('roaAccusedSig')),
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

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 12 (PCR REASONS — Optional)
  // ══════════════════════════════════════════════════════════════════════════
  if (showPage12) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 28),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            prosecutorBox(),
            pw.SizedBox(height: 4),
            pw.Center(child: pw.Text('Page 12 of 13', style: boldStyle)),
            pw.SizedBox(height: 3),
            pw.Center(child: pw.Text('पोलिस कोठडीची कारणे (Reason for PCR)', style: titleStyle, textAlign: pw.TextAlign.center)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
              columnWidths: const {
                0: pw.FixedColumnWidth(48),
                1: pw.FlexColumnWidth(1),
              },
              children: [
                tableHeaderRow('अ.क्र.', 'कोठडीची कारणे'),
                checkTableRow('१', b('pcr1'), pw.Text('गुन्ह्यात वापरलेले हत्यार जप्त करणे बाकी आहे.', style: regularStyle)),
                checkTableRow('२', b('pcr2'), pw.Text('गुन्हा करण्यामागील हेतू माहित करावयाचा आहे.', style: regularStyle)),
                checkTableRow('३', b('pcr3'), pw.Text('अजून कोणी आरोपी आहेत का याची माहिती घ्यावयाची आहे.', style: regularStyle)),
                checkTableRow('४', b('pcr4'), pw.Text('चोरी गेलेली रक्कम, सोन्याचे अलंकार जप्त करावयाचे आहेत.', style: regularStyle)),
                checkTableRow('५', b('pcr5'), pw.Text('गुन्ह्यात वापरलेले वाहन जप्त करावयाचे आहे.', style: regularStyle)),
                checkTableRow('६', b('pcr6'), pw.Text('आरोपीचे कपडे जप्त करावयाचे आहेत.', style: regularStyle)),
                checkTableRow('७', b('pcr7'), pw.Text('आरोपीचे ब्लड सॅम्पल घेणे बाकी आहे.', style: regularStyle)),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text('८) इतर कारणे (इत्यादी) :-', style: boldStyle),
            pw.SizedBox(height: 2),
            multilineUnderline(v('pcrOther'), lines: 2),
          ],
        ),
      ),
    );
  }

  return pdf.save();
}
