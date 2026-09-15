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

Future<Uint8List> generateDraftGroundOfArrestPdf(
  Map<String, dynamic> doc,
) async {
  final pdf = pw.Document();
  final devanagari = await PdfGoogleFonts.notoSansDevanagariRegular();
  final devanagariBold = await PdfGoogleFonts.notoSansDevanagariBold();

  final regular = pw.TextStyle(
    font: devanagari,
    fontSize: 9,
    lineSpacing: 2.5,
  );
  final bold = pw.TextStyle(
    font: devanagariBold,
    fontSize: 9,
    fontWeight: pw.FontWeight.bold,
  );
  final tableRegular = pw.TextStyle(
    font: devanagari,
    fontSize: 8.5,
    lineSpacing: 2,
  );
  final tableBold = pw.TextStyle(
    font: devanagariBold,
    fontSize: 8.5,
    fontWeight: pw.FontWeight.bold,
  );
  final titleStyle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 12.5,
    fontWeight: pw.FontWeight.bold,
  );
  final subtitleStyle = pw.TextStyle(
    font: devanagari,
    fontSize: 7.8,
    lineSpacing: 1.5,
  );

  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  bool b(String key, [bool defaultVal = true]) {
    final val = doc[key];
    if (val is bool) return val;
    return defaultVal;
  }

  // Accused details
  final accusedName = v('accusedName');
  final accusedAge = v('accusedAge');
  final accusedAddress = v('accusedAddress');
  final psName = v('psName');
  final crNo = v('crNo');
  final bnsSection = v('bnsSection');
  final arrestDate = v('arrestDate');
  final arrestTime = v('arrestTime');
  final briefFacts = v('briefFacts');

  // Recipient / Relative details
  final relativeName = v('relativeName', v('s48RelativeName'));
  final relativeAge = v('relativeAge', v('s48RelativeAge'));
  final relativeAddress = v('relativeAddress', v('s48RelativeAddress'));
  final relationship = v('relationship', v('s48Relationship'));

  // Detention location
  final custodyPs = v('custodyPs', v('s48CustodyPs', psName));

  // Grounds of arrest
  final g1Fir = b('g1Fir', b('s48G1', true));
  final g2Witness = b('g2Witness', b('s48G2', true));
  final witnessName = v('witnessName', v('s48WitnessName'));
  final g3Cctv = b('g3Cctv', b('s48G3', true));
  final g4Recovery = b('g4Recovery', true);
  final g5Confession = b('g5Confession', b('s48G5', true));
  final g6CoAccused = b('g6CoAccused', b('s48G6', true));
  final coAccusedName = v('coAccusedName', v('s48CoAccused'));
  final g7Cdr = b('g7Cdr', true);

  // Footer details
  final noticeDate = v('noticeDate', v('s48Date'));
  final noticePlace = v('noticePlace', v('s48Place'));
  final officerName = v('officerName', v('s48OfficerSig'));
  final relativeSig = v('relativeSig', v('s48RelativeSig'));

  pw.Widget buildTopHeader(String pageLabel) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(width: 110),
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 4),
          child: pw.Text(
            pageLabel,
            style: pw.TextStyle(font: devanagariBold, fontSize: 9.5),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 0.8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('Gaware Ashok',
                  style: pw.TextStyle(font: devanagariBold, fontSize: 8)),
              pw.Text('Public Prosecutor A.Nagar',
                  style: pw.TextStyle(font: devanagari, fontSize: 7)),
              pw.Text('9823911047',
                  style: pw.TextStyle(font: devanagari, fontSize: 7)),
            ],
          ),
        ),
      ],
    );
  }

  final section = v('formSection').toLowerCase();
  final p9Match = section.contains('9') ||
      section.contains('47') ||
      section.contains('आधार');
  final p10Match = section.contains('10') ||
      section.contains('48') ||
      section.contains('नातेवाईक');
  final p11Match = section.contains('11') ||
      section.contains('35') ||
      section.contains('कारणे');
  final showAll = section.isEmpty ||
      section.contains('complete') ||
      (!p9Match && !p10Match && !p11Match);

  final showP9 = showAll || p9Match;
  final showP10 = showAll || p10Match;
  final showP11 = showAll || p11Match;

  // ══════════════════════════════════════════════════════════════════════════
  // ── PAGE 1: अटकेचा आधार (कलम ४७ BNSS) — Page 9 of 13 ──
  // ══════════════════════════════════════════════════════════════════════════
  if (showP9) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 22),
        build: (pw.Context context) {
          final p9GroundRows = <pw.TableRow>[
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      vertical: 2.5, horizontal: 4),
                  alignment: pw.Alignment.center,
                  child: pw.Text('अ.क्र.', style: tableBold),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      vertical: 2.5, horizontal: 6),
                  child: pw.Text('अटकेचे आधार ( Ground of Arrest )',
                      style: tableBold),
                ),
              ],
            ),
          ];

          if (g1Fir) {
            p9GroundRows.add(
              pw.TableRow(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 2.5, horizontal: 4),
                    alignment: pw.Alignment.center,
                    child: pw.Text('१', style: tableBold),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 2.5, horizontal: 6),
                    child: pw.Text(
                        'फिर्यादीने दाखल केलेल्या FIR मध्ये तुमचे विरुद्ध आरोप केलेले आहेत.',
                        style: tableRegular),
                  ),
                ],
              ),
            );
          }

          if (g2Witness) {
            p9GroundRows.add(
              pw.TableRow(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 2.5, horizontal: 4),
                    alignment: pw.Alignment.center,
                    child: pw.Text('२', style: tableBold),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 2.5, horizontal: 6),
                    child: pw.RichText(
                      text: pw.TextSpan(
                        style: tableRegular,
                        children: [
                          const pw.TextSpan(text: 'प्रत्यक्षदर्शी साक्षीदार '),
                          pw.TextSpan(
                            text:
                                witnessName.isNotEmpty ? witnessName : '[नाव]',
                            style: tableBold,
                          ),
                          const pw.TextSpan(
                              text:
                                  ' यांनी दिलेल्या जबाबानुसार गुन्ह्यामध्ये तुमचा थेट सहभाग असल्याचे निष्पन्न झाले आहे.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (g3Cctv) {
            p9GroundRows.add(
              pw.TableRow(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 2.5, horizontal: 4),
                    alignment: pw.Alignment.center,
                    child: pw.Text('३', style: tableBold),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 2.5, horizontal: 6),
                    child: pw.Text(
                      'घटनास्थळावरील पुराव्यांच्या (CCTV / डिजिटल रेकॉर्ड / मोबाईल व्हिडिओ ) आधारे गुन्ह्यामध्ये तुमचा थेट सहभाग असल्याचे निष्पन्न झाले आहे.',
                      style: tableRegular,
                    ),
                  ),
                ],
              ),
            );
          }

          if (g4Recovery) {
            p9GroundRows.add(
              pw.TableRow(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 2.5, horizontal: 4),
                    alignment: pw.Alignment.center,
                    child: pw.Text('4', style: tableBold),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 2.5, horizontal: 6),
                    child: pw.Text(
                      'गुन्ह्यात वापरलेले हत्यार / चोरीची मालमत्ता / गुन्ह्याशी संबंधित महत्त्वाचे दस्तऐवज हे केवळ तुमच्याकडे असलेल्या माहितीच्या आधारे आणि तुमच्या ताब्यातून हस्तगत करण्यात आले आहेत.',
                      style: tableRegular,
                    ),
                  ),
                ],
              ),
            );
          }

          if (g5Confession) {
            p9GroundRows.add(
              pw.TableRow(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 2.5, horizontal: 4),
                    alignment: pw.Alignment.center,
                    child: pw.Text('५', style: tableBold),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 2.5, horizontal: 6),
                    child: pw.Text('तुम्ही गुन्हा केल्याची कबुली दिली आहे.',
                        style: tableRegular),
                  ),
                ],
              ),
            );
          }

          if (g6CoAccused) {
            p9GroundRows.add(
              pw.TableRow(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 2.5, horizontal: 4),
                    alignment: pw.Alignment.center,
                    child: pw.Text('६', style: tableBold),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 2.5, horizontal: 6),
                    child: pw.RichText(
                      text: pw.TextSpan(
                        style: tableRegular,
                        children: [
                          const pw.TextSpan(text: 'गुन्ह्यातील सहआरोपी '),
                          pw.TextSpan(
                            text: coAccusedName.isNotEmpty
                                ? coAccusedName
                                : '___________',
                            style: tableBold,
                          ),
                          const pw.TextSpan(
                              text:
                                  ' यांनी तुम्ही गुन्ह्यामध्ये सहभागी असल्याचे कबुल केले आहे.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (g7Cdr) {
            p9GroundRows.add(
              pw.TableRow(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 2.5, horizontal: 4),
                    alignment: pw.Alignment.center,
                    child: pw.Text('७', style: tableBold),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 2.5, horizontal: 6),
                    child: pw.Text(
                      'मोबाईल CDR वरून घटनेच्या दिवशी तुमचे tower location घटनास्थळाजवळ असल्याचे दिसून आले आहे.',
                      style: tableRegular,
                    ),
                  ),
                ],
              ),
            );
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildTopHeader('Page 9 of 13'),
              pw.SizedBox(height: 6),

              // Title
              pw.Center(
                child: pw.Text(
                  'अटकेचा आधार (कलम ४७ BNSS)',
                  style: titleStyle.copyWith(
                      decoration: pw.TextDecoration.underline),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 3),

              // Subtitle
              pw.Center(
                child: pw.Text(
                  '(भारतीय नागरिक सुरक्षा संहिता, २०२३ च्या कलम ४७ आणि भारतीय संविधान कलम २२(१) अन्वये तसेच माननीय सर्वोच्च न्यायालयाच्या \'पंकज बन्सल\', \'प्रबीर पुरकायस्थ\', \'विद्वान कुमार\' आणि \'मिहीर शाह\' निवाड्यांमधील मार्गदर्शक तत्त्वांच्या अधीन)',
                  style: subtitleStyle,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 6),

              // Recipient block
              pw.Text('प्रति,', style: bold),
              pw.SizedBox(height: 1),
              pw.RichText(
                text: pw.TextSpan(
                  style: regular,
                  children: [
                    pw.TextSpan(
                        text: 'अटक केलेल्या आरोपीचे नाव: ', style: bold),
                    pw.TextSpan(
                      text: accusedName.isNotEmpty
                          ? accusedName
                          : '___________________________________________________________________',
                      style: accusedName.isNotEmpty ? bold : regular,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 2),
              pw.RichText(
                text: pw.TextSpan(
                  style: regular,
                  children: [
                    pw.TextSpan(text: 'वय: ', style: bold),
                    pw.TextSpan(
                      text: accusedAge.isNotEmpty ? accusedAge : '____________',
                      style: accusedAge.isNotEmpty ? bold : regular,
                    ),
                    pw.TextSpan(text: ' वर्ष, पत्ता: ', style: bold),
                    pw.TextSpan(
                      text: accusedAddress.isNotEmpty
                          ? accusedAddress
                          : '______________________________________________________________',
                      style: accusedAddress.isNotEmpty ? bold : regular,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 2),

              // Notice text
              pw.RichText(
                textAlign: pw.TextAlign.justify,
                text: pw.TextSpan(
                  style: regular,
                  children: [
                    const pw.TextSpan(
                      text:
                          'या नोटीसद्वारे तुम्हाला माहिती करण्यात येते की, तुम्हाला पोलीस ठाणे ',
                    ),
                    pw.TextSpan(
                      text: psName.isNotEmpty ? psName : '_________',
                      style: psName.isNotEmpty ? bold : regular,
                    ),
                    const pw.TextSpan(
                      text: ' येथे दाखल असलेल्या गुन्हा रजिस्टर क्रमांक ',
                    ),
                    pw.TextSpan(
                      text: crNo.isNotEmpty ? crNo : '______________',
                      style: crNo.isNotEmpty ? bold : regular,
                    ),
                    const pw.TextSpan(
                      text:
                          ', अंतर्गत भारतीय न्याय संहिता, २०२३ (BNS) च्या कलम ',
                    ),
                    pw.TextSpan(
                      text:
                          bnsSection.isNotEmpty ? bnsSection : '_____________',
                      style: bnsSection.isNotEmpty ? bold : regular,
                    ),
                    const pw.TextSpan(
                      text: ' अन्वये नोंदवलेल्या गुन्ह्यात आज दिनांक ',
                    ),
                    pw.TextSpan(
                      text:
                          arrestDate.isNotEmpty ? arrestDate : '______________',
                      style: arrestDate.isNotEmpty ? bold : regular,
                    ),
                    const pw.TextSpan(text: ' रोजी वेळ '),
                    pw.TextSpan(
                      text:
                          arrestTime.isNotEmpty ? arrestTime : '_____________',
                      style: arrestTime.isNotEmpty ? bold : regular,
                    ),
                    const pw.TextSpan(text: ' वाजता अटक करण्यात आली आहे.'),
                  ],
                ),
              ),
              pw.SizedBox(height: 5),

              // Brief facts
              pw.Text('गुन्ह्याची थोडक्यात हकीकत :-', style: bold),
              pw.SizedBox(height: 1),
              if (briefFacts.isNotEmpty) ...[
                pw.Text(briefFacts,
                    style: regular, textAlign: pw.TextAlign.justify),
                pw.SizedBox(height: 3),
              ] else ...[
                pw.Container(
                    height: 0.6,
                    color: PdfColors.black,
                    margin: const pw.EdgeInsets.symmetric(vertical: 4)),
                pw.Container(
                    height: 0.6,
                    color: PdfColors.black,
                    margin: const pw.EdgeInsets.symmetric(vertical: 4)),
              ],
              pw.SizedBox(height: 4),

              // Table 1 Header
              pw.Text('अटकेचा आधार :-', style: bold),
              pw.SizedBox(height: 2),

              // Table 1: Grounds
              pw.Table(
                border: const pw.TableBorder(
                  left: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  right: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  top: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  horizontalInside:
                      pw.BorderSide(color: PdfColors.black, width: 0.8),
                  verticalInside:
                      pw.BorderSide(color: PdfColors.black, width: 0.8),
                ),
                columnWidths: const {
                  0: pw.FixedColumnWidth(30),
                  1: pw.FlexColumnWidth(1),
                },
                children: p9GroundRows,
              ),
              pw.SizedBox(height: 6),

              // Table 2 Header
              pw.Text('आरोपीचे हक्क /अधिकार :-', style: bold),
              pw.SizedBox(height: 2),

              // Table 2: Rights
              pw.Table(
                border: const pw.TableBorder(
                  left: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  right: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  top: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  horizontalInside:
                      pw.BorderSide(color: PdfColors.black, width: 0.8),
                  verticalInside:
                      pw.BorderSide(color: PdfColors.black, width: 0.8),
                ),
                columnWidths: const {
                  0: pw.FixedColumnWidth(30),
                  1: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 2.5, horizontal: 4),
                        alignment: pw.Alignment.center,
                        child: pw.Text('अ.क्र.', style: tableBold),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 2.5, horizontal: 6),
                        child: pw.Text('आरोपींचे हक्क', style: tableBold),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 2.5, horizontal: 4),
                        alignment: pw.Alignment.center,
                        child: pw.Text('१', style: tableBold),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 2.5, horizontal: 6),
                        child: pw.Text(
                          'तुम्हाला माननीय न्यायालयासमोर हजर केल्यावर जामीन अर्ज सादर करण्याचा पूर्ण कायदेशीर अधिकार आहे.',
                          style: tableRegular,
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 2.5, horizontal: 4),
                        alignment: pw.Alignment.center,
                        child: pw.Text('२', style: tableBold),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 2.5, horizontal: 6),
                        child: pw.Text(
                          'तुमच्या पसंतीच्या कायदेशीर सल्लागाराचा (वकिलाचा) सल्ला घेण्याचा, त्यांना पोलीस कोठडीत भेटण्याचा आणि माननीय न्यायालयासमोर रिमांडला कायदेशीर विरोध करण्याचा पूर्ण अधिकार आहे.',
                          style: tableRegular,
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 2.5, horizontal: 4),
                        alignment: pw.Alignment.center,
                        child: pw.Text('३', style: tableBold),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 2.5, horizontal: 6),
                        child: pw.RichText(
                          text: pw.TextSpan(
                            style: tableRegular,
                            children: [
                              const pw.TextSpan(
                                text:
                                    'तुमच्या अटकेची आणि तुम्हाला ज्या ठिकाणी कोठडीत ठेवण्यात आले आहे त्या ठिकाणाची माहिती तुमच्याद्वारे नामांकित केलेले नातेवाईक/मित्र ',
                              ),
                              pw.TextSpan(
                                text: relativeName.isNotEmpty
                                    ? relativeName
                                    : '____________________________',
                                style: relativeName.isNotEmpty
                                    ? tableBold
                                    : tableRegular,
                              ),
                              const pw.TextSpan(
                                  text: ' यांना देण्यात आली आहे.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'दिनांक :- ${noticeDate.isNotEmpty ? noticeDate : '______________'}',
                        style: regular,
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (officerName.isNotEmpty) ...[
                        pw.Text(officerName, style: bold),
                        pw.SizedBox(height: 10),
                      ] else ...[
                        pw.SizedBox(height: 16),
                      ],
                      pw.Text('पोलीस अधिकारी नाव, हुद्दा सही शिक्का',
                          style: regular),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (accusedName.isNotEmpty) ...[
                        pw.Text(accusedName, style: bold),
                        pw.SizedBox(height: 10),
                      ] else ...[
                        pw.SizedBox(height: 16),
                      ],
                      pw.Text('आरोपीचे नाव , सही, अंगठा', style: regular),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── PAGE 2: नातेवाईक/ मित्रांसाठी अटकेची नोटीस (कलम ४८ BNSS) — Page 10 ──
  // ══════════════════════════════════════════════════════════════════════════
  if (showP10) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 22),
        build: (pw.Context context) {
          final p10GroundRows = <pw.TableRow>[
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      vertical: 2.5, horizontal: 4),
                  alignment: pw.Alignment.center,
                  child: pw.Text('अ.क्र.', style: tableBold),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      vertical: 2.5, horizontal: 6),
                  child: pw.Text('अटकेचे आधार (Ground of Arrest )',
                      style: tableBold),
                ),
              ],
            ),
          ];

          if (g1Fir) {
            p10GroundRows.add(
              pw.TableRow(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 2.5, horizontal: 4),
                    alignment: pw.Alignment.center,
                    child: pw.Text('१', style: tableBold),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 2.5, horizontal: 6),
                    child: pw.Text(
                        'FIR मध्ये आरोपीने सदर गुन्हा केल्याचा उल्लेख आहे.',
                        style: tableRegular),
                  ),
                ],
              ),
            );
          }

          if (g2Witness) {
            p10GroundRows.add(
              pw.TableRow(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 2.5, horizontal: 4),
                    alignment: pw.Alignment.center,
                    child: pw.Text('२', style: tableBold),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 2.5, horizontal: 6),
                    child: pw.RichText(
                      text: pw.TextSpan(
                        style: tableRegular,
                        children: [
                          const pw.TextSpan(text: 'प्रत्यक्षदर्शी साक्षीदार '),
                          pw.TextSpan(
                            text:
                                witnessName.isNotEmpty ? witnessName : '[नाव]',
                            style: tableBold,
                          ),
                          const pw.TextSpan(
                            text:
                                ' यांनी दिलेल्या जबाबानुसार गुन्ह्यामध्ये आरोपीचा थेट सहभाग असल्याचे निष्पन्न झाले आहे.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (g3Cctv) {
            p10GroundRows.add(
              pw.TableRow(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 2.5, horizontal: 4),
                    alignment: pw.Alignment.center,
                    child: pw.Text('३', style: tableBold),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 2.5, horizontal: 6),
                    child: pw.Text(
                      'घटनास्थळावरील पुराव्यांच्या CCTV/डिजिटल रेकॉर्ड आधारे गुन्ह्यामध्ये थेट सहभाग असल्याचे निष्पन्न झाले आहे.',
                      style: tableRegular,
                    ),
                  ),
                ],
              ),
            );
          }

          if (g5Confession) {
            p10GroundRows.add(
              pw.TableRow(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 2.5, horizontal: 4),
                    alignment: pw.Alignment.center,
                    child: pw.Text('५', style: tableBold),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 2.5, horizontal: 6),
                    child: pw.Text('आरोपीने गुन्हा केल्याची कबुली दिली आहे.',
                        style: tableRegular),
                  ),
                ],
              ),
            );
          }

          if (g6CoAccused) {
            p10GroundRows.add(
              pw.TableRow(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 2.5, horizontal: 4),
                    alignment: pw.Alignment.center,
                    child: pw.Text('६', style: tableBold),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        vertical: 2.5, horizontal: 6),
                    child: pw.RichText(
                      text: pw.TextSpan(
                        style: tableRegular,
                        children: [
                          const pw.TextSpan(text: 'गुन्ह्यातील सहआरोपी '),
                          pw.TextSpan(
                            text: coAccusedName.isNotEmpty
                                ? coAccusedName
                                : '_________________',
                            style: tableBold,
                          ),
                          const pw.TextSpan(
                            text:
                                ' यांनी गुन्ह्यामध्ये आरोपी सहभागी असल्याचे कबुल केले आहे.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildTopHeader('Page 10 of 13'),
              pw.SizedBox(height: 6),

              // Main Title
              pw.Center(
                child: pw.Text(
                  'नातेवाईक/ मित्रांसाठी अटकेच्या माहितीची नोटीस ( कलम ४८ BNSS)',
                  style: titleStyle.copyWith(
                      decoration: pw.TextDecoration.underline),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 3),

              // Subtitle
              pw.Center(
                child: pw.Text(
                  '(भारतीय नागरिक सुरक्षा संहिता, २०२३ च्या कलम ४८(१) अन्वये माननीय सर्वोच्च न्यायालयाच्या \'पंकज बन्सल\', \'प्रबीर पुरकायस्थ\', \'विद्वान कुमार\' आणि \'मिहीर शाह\' निवाड्यांमधील मार्गदर्शक तत्त्वांच्या अधीन)',
                  style: subtitleStyle,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 6),

              // Recipient block
              pw.Text('प्रति,', style: bold),
              pw.SizedBox(height: 1),
              pw.RichText(
                text: pw.TextSpan(
                  style: regular,
                  children: [
                    pw.TextSpan(text: 'नातेवाईक/मित्राचे नाव:- ', style: bold),
                    pw.TextSpan(
                      text: relativeName.isNotEmpty
                          ? relativeName
                          : '_____________________',
                      style: relativeName.isNotEmpty ? bold : regular,
                    ),
                    pw.TextSpan(text: '   वय :- ', style: bold),
                    pw.TextSpan(
                      text: relativeAge.isNotEmpty ? relativeAge : '_____',
                      style: relativeAge.isNotEmpty ? bold : regular,
                    ),
                    pw.TextSpan(text: '   पत्ता:- ', style: bold),
                    pw.TextSpan(
                      text: relativeAddress.isNotEmpty
                          ? relativeAddress
                          : '____________________',
                      style: relativeAddress.isNotEmpty ? bold : regular,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 2),
              pw.RichText(
                text: pw.TextSpan(
                  style: regular,
                  children: [
                    pw.TextSpan(text: 'आरोपीशी असलेले नाते: ', style: bold),
                    pw.TextSpan(
                      text: relationship.isNotEmpty
                          ? relationship
                          : '_________________________________________________',
                      style: relationship.isNotEmpty ? bold : regular,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 4),

              // Main notice paragraph
              pw.RichText(
                textAlign: pw.TextAlign.justify,
                text: pw.TextSpan(
                  style: regular,
                  children: [
                    const pw.TextSpan(
                      text:
                          'या नोटीसद्वारे तुम्हाला, भारतीय नागरिक सुरक्षा संहिता, २०२३ (BNSS) च्या कलम ४८(१) मधील कायदेशीर तरतुदींनुसार अधिकृतपणे सूचित करण्यात येते की, तुमचे/तुमच्या आरोपीचे नाव: ',
                    ),
                    pw.TextSpan(
                      text: accusedName.isNotEmpty
                          ? accusedName
                          : '_________________________',
                      style: accusedName.isNotEmpty ? bold : regular,
                    ),
                    const pw.TextSpan(text: ' वय: '),
                    pw.TextSpan(
                      text: accusedAge.isNotEmpty ? accusedAge : '_____',
                      style: accusedAge.isNotEmpty ? bold : regular,
                    ),
                    const pw.TextSpan(text: ' वर्ष, पत्ता:- '),
                    pw.TextSpan(
                      text: accusedAddress.isNotEmpty
                          ? accusedAddress
                          : '_________________',
                      style: accusedAddress.isNotEmpty ? bold : regular,
                    ),
                    const pw.TextSpan(text: ' यांना पोलीस ठाणे '),
                    pw.TextSpan(
                      text: psName.isNotEmpty ? psName : '__________________',
                      style: psName.isNotEmpty ? bold : regular,
                    ),
                    const pw.TextSpan(
                      text:
                          ' येथे दाखल असलेल्या गुन्हा रजिस्टर क्रमांक (Cr.No.) ',
                    ),
                    pw.TextSpan(
                      text: crNo.isNotEmpty ? crNo : '________________',
                      style: crNo.isNotEmpty ? bold : regular,
                    ),
                    const pw.TextSpan(
                      text:
                          ', अंतर्गत भारतीय न्याय संहिता, २०२३ (BNS) च्या कलम ',
                    ),
                    pw.TextSpan(
                      text: bnsSection.isNotEmpty
                          ? bnsSection
                          : '__________________',
                      style: bnsSection.isNotEmpty ? bold : regular,
                    ),
                    const pw.TextSpan(
                      text:
                          ' अन्वये नोंदवलेल्या गुन्ह्याच्या तपासाच्या अनुषंगाने आज दिनांक ',
                    ),
                    pw.TextSpan(
                      text: arrestDate.isNotEmpty
                          ? arrestDate
                          : '_______________',
                      style: arrestDate.isNotEmpty ? bold : regular,
                    ),
                    const pw.TextSpan(text: ' रोजी वेळ '),
                    pw.TextSpan(
                      text:
                          arrestTime.isNotEmpty ? arrestTime : '_____________',
                      style: arrestTime.isNotEmpty ? bold : regular,
                    ),
                    const pw.TextSpan(
                        text: ' वाजता कायदेशीररीत्या अटक करण्यात आली आहे.'),
                  ],
                ),
              ),
              pw.SizedBox(height: 5),

              // Brief facts
              pw.Text('गुन्ह्याची थोडक्यात हकीकत :-', style: bold),
              pw.SizedBox(height: 1),
              if (briefFacts.isNotEmpty) ...[
                pw.Text(briefFacts,
                    style: regular, textAlign: pw.TextAlign.justify),
                pw.SizedBox(height: 3),
              ] else ...[
                pw.Container(
                    height: 0.6,
                    color: PdfColors.black,
                    margin: const pw.EdgeInsets.symmetric(vertical: 4)),
                pw.Container(
                    height: 0.6,
                    color: PdfColors.black,
                    margin: const pw.EdgeInsets.symmetric(vertical: 4)),
              ],
              pw.SizedBox(height: 4),

              // Table intro
              pw.Text(
                'आरोपीच्या अटकेबाबत तुम्हाला खालील बाबींची लेखी माहिती देण्यात येत आहे:-',
                style: bold,
              ),
              pw.SizedBox(height: 2),

              // Table 1: Information regarding arrest
              pw.Table(
                border: const pw.TableBorder(
                  left: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  right: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  top: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  horizontalInside:
                      pw.BorderSide(color: PdfColors.black, width: 0.8),
                  verticalInside:
                      pw.BorderSide(color: PdfColors.black, width: 0.8),
                ),
                columnWidths: const {
                  0: pw.FixedColumnWidth(30),
                  1: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 2.5, horizontal: 4),
                        alignment: pw.Alignment.center,
                        child: pw.Text('अ.क्र.', style: tableBold),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 2.5, horizontal: 6),
                        child: pw.Text('अटकेबाबत माहिती', style: tableBold),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 2.5, horizontal: 4),
                        alignment: pw.Alignment.center,
                        child: pw.Text('१.', style: tableBold),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 2.5, horizontal: 6),
                        child: pw.RichText(
                          textAlign: pw.TextAlign.justify,
                          text: pw.TextSpan(
                            style: tableRegular,
                            children: [
                              const pw.TextSpan(text: 'आरोपी नाव '),
                              pw.TextSpan(
                                text: accusedName.isNotEmpty
                                    ? accusedName
                                    : '___________________',
                                style: accusedName.isNotEmpty
                                    ? tableBold
                                    : tableRegular,
                              ),
                              const pw.TextSpan(
                                  text: ' यांना गुन्हा रजिस्टर क्रमांक '),
                              pw.TextSpan(
                                text:
                                    crNo.isNotEmpty ? crNo : '_______________',
                                style:
                                    crNo.isNotEmpty ? tableBold : tableRegular,
                              ),
                              const pw.TextSpan(
                                  text:
                                      ', अंतर्गत भारतीय न्याय संहिता, २०२३ (BNS) च्या कलम '),
                              pw.TextSpan(
                                text: bnsSection.isNotEmpty
                                    ? bnsSection
                                    : '__________________',
                                style: bnsSection.isNotEmpty
                                    ? tableBold
                                    : tableRegular,
                              ),
                              const pw.TextSpan(
                                text:
                                    ' अन्वये नोंदवलेल्या गुन्ह्याच्या तपासाच्या अनुषंगाने कायदेशीररीत्या अटक करण्यात आली असून सदर आरोपीला सध्या [पोलीस ठाण्याचे नाव ',
                              ),
                              pw.TextSpan(
                                text: custodyPs.isNotEmpty
                                    ? custodyPs
                                    : (psName.isNotEmpty
                                        ? psName
                                        : '________________________'),
                                style: tableBold,
                              ),
                              const pw.TextSpan(
                                  text: '] येथे ठेवण्यात आले आहे.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 2.5, horizontal: 4),
                        alignment: pw.Alignment.center,
                        child: pw.Text('२.', style: tableBold),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 2.5, horizontal: 6),
                        child: pw.Text(
                          'आरोपीला माननीय न्यायालयासमोर हजर केल्यावर जामीन अर्ज सादर करण्याचा पूर्ण कायदेशीर अधिकार आहे.',
                          style: tableRegular,
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 2.5, horizontal: 4),
                        alignment: pw.Alignment.center,
                        child: pw.Text('३.', style: tableBold),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 2.5, horizontal: 6),
                        child: pw.Text(
                          'तुमच्या पसंतीच्या कायदेशीर सल्लागाराचा (वकिलाचा) सल्ला घेण्याचा, त्यांना पोलीस कोठडीत भेटण्याचा आणि माननीय न्यायालयासमोर रिमांडला कायदेशीर विरोध करण्याचा पूर्ण अधिकार आहे.',
                          style: tableRegular,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Table 2: Grounds of arrest
              pw.Table(
                border: const pw.TableBorder(
                  left: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  right: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  horizontalInside:
                      pw.BorderSide(color: PdfColors.black, width: 0.8),
                  verticalInside:
                      pw.BorderSide(color: PdfColors.black, width: 0.8),
                ),
                columnWidths: const {
                  0: pw.FixedColumnWidth(30),
                  1: pw.FlexColumnWidth(1),
                },
                children: p10GroundRows,
              ),
              pw.SizedBox(height: 10),

              // Footer signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'दिनांक :- ${noticeDate.isNotEmpty ? noticeDate : '________________'}',
                        style: regular,
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'ठिकाण :- ${noticePlace.isNotEmpty ? noticePlace : '________________'}',
                        style: regular,
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (officerName.isNotEmpty) ...[
                        pw.Text(officerName, style: bold),
                        pw.SizedBox(height: 10),
                      ] else ...[
                        pw.SizedBox(height: 16),
                      ],
                      pw.Text('पोलीस अधिकारी नाव सही शिक्का', style: regular),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (relativeSig.isNotEmpty) ...[
                        pw.Text(relativeSig, style: bold),
                        pw.SizedBox(height: 10),
                      ] else ...[
                        pw.SizedBox(height: 16),
                      ],
                      pw.Text('नातेवाईक/ मित्र यांचे नाव , सही, अंगठा',
                          style: regular),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── PAGE 3: अटकेचे कारणे [कलम ३५(१)(ब) BNSS ] — Page 11 of 13 ──
  // ══════════════════════════════════════════════════════════════════════════
  if (showP11) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 22),
        build: (pw.Context context) {
          final List<pw.TableRow> p11ReasonRows = [
            pw.TableRow(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      vertical: 2.5, horizontal: 4),
                  alignment: pw.Alignment.center,
                  child: pw.Text('अ.क्र.', style: tableBold),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      vertical: 2.5, horizontal: 6),
                  alignment: pw.Alignment.center,
                  child: pw.Text('अटकेचे कारणे ( Reason of Arrest )',
                      style: tableBold),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                  alignment: pw.Alignment.center,
                  child: pw.Text('१', style: tableBold),
                ),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                  child: pw.Text(
                    'या पुढे कोणताही गुन्हा करण्यास प्रतिबंध करण्यासाठी अटक करण्यात आली आहे.',
                    style: tableRegular,
                  ),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                  alignment: pw.Alignment.center,
                  child: pw.Text('२', style: tableBold),
                ),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                  child: pw.Text(
                    'गुन्ह्याचा योग्य तपास / अन्वेषण करण्यासाठी .',
                    style: tableRegular,
                  ),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                  alignment: pw.Alignment.center,
                  child: pw.Text('३', style: tableBold),
                ),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                  child: pw.Text(
                    'गुन्ह्यातील पुरावा नष्ट किंवा पुराव्यांशी छेडछाड / फेरफार करण्यापासून रोखण्यासाठी',
                    style: tableRegular,
                  ),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                  alignment: pw.Alignment.center,
                  child: pw.Text('४', style: tableBold),
                ),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                  child: pw.Text(
                    'गुन्ह्यातील साक्षीदारांना धाक, धाकदपटशा, वचन किंवा प्रलोभन देण्यापासून रोखणे, धमकावण्यापासून रोखण्यासाठी',
                    style: tableRegular,
                  ),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                  alignment: pw.Alignment.center,
                  child: pw.Text('५', style: tableBold),
                ),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                  child: pw.Text(
                    'न्यायालयातील उपस्थिती निश्चित करण्यासाठी अटक न केल्यास तुम्ही तपासातून आणि न्यायालयाच्या प्रक्रियेतून फरार होण्याची शक्यता आहे',
                    style: tableRegular,
                  ),
                ),
              ],
            ),
          ];

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildTopHeader('Page 11 of 13'),
              pw.SizedBox(height: 6),

              // Title
              pw.Center(
                child: pw.Text(
                  'अटकेचे कारणे [कलम ३५(१)(ब) BNSS ]',
                  style: titleStyle.copyWith(
                      decoration: pw.TextDecoration.underline),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 3),

              // Subtitle
              pw.Center(
                child: pw.Text(
                  '(भारतीय नागरिक सुरक्षा संहिता,२०२३ कलम ३५(१)(ब) अन्वये मा.सर्वोच्च न्यायालयाच्या मार्गदर्शक तत्त्वांच्या निकषांच्या अधीन)',
                  style: subtitleStyle,
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 6),

              // Recipient block
              pw.Text('प्रति,', style: bold),
              pw.SizedBox(height: 1),
              pw.RichText(
                text: pw.TextSpan(
                  style: regular,
                  children: [
                    pw.TextSpan(
                        text: 'अटक केलेल्या आरोपीचे नाव:- ', style: bold),
                    pw.TextSpan(
                      text: accusedName.isNotEmpty
                          ? accusedName
                          : '___________________________________________________________________',
                      style: accusedName.isNotEmpty ? bold : regular,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 2),
              pw.RichText(
                text: pw.TextSpan(
                  style: regular,
                  children: [
                    pw.TextSpan(text: 'वय:- ', style: bold),
                    pw.TextSpan(
                      text:
                          accusedAge.isNotEmpty ? accusedAge : '______________',
                      style: accusedAge.isNotEmpty ? bold : regular,
                    ),
                    pw.TextSpan(text: ' वर्ष, पत्ता:- ', style: bold),
                    pw.TextSpan(
                      text: accusedAddress.isNotEmpty
                          ? accusedAddress
                          : '______________________________________________________________',
                      style: accusedAddress.isNotEmpty ? bold : regular,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),

              // Notice text
              pw.RichText(
                textAlign: pw.TextAlign.justify,
                text: pw.TextSpan(
                  style: regular,
                  children: [
                    const pw.TextSpan(
                      text:
                          'या नोटीसद्वारे तुम्हाला सूचित करण्यात येते की, पोलीस ठाणे ',
                    ),
                    pw.TextSpan(
                      text: psName.isNotEmpty
                          ? '[ $psName ]'
                          : '[पोलीस ठाण्याचे नाव]',
                      style: psName.isNotEmpty ? bold : regular,
                    ),
                    const pw.TextSpan(
                      text: ' येथे दाखल असलेल्या गुन्हा रजिस्टर क्रमांक ',
                    ),
                    pw.TextSpan(
                      text: crNo.isNotEmpty ? crNo : '______________',
                      style: crNo.isNotEmpty ? bold : regular,
                    ),
                    const pw.TextSpan(
                      text:
                          ', अंतर्गत भारतीय न्याय संहिता, २०२३ (BNS) च्या कलम ',
                    ),
                    pw.TextSpan(
                      text:
                          bnsSection.isNotEmpty ? bnsSection : '______________',
                      style: bnsSection.isNotEmpty ? bold : regular,
                    ),
                    const pw.TextSpan(
                      text:
                          ' अन्वये नोंदवलेल्या गुन्ह्यात तपासाच्या अनुषंगाने आज दिनांक ',
                    ),
                    pw.TextSpan(
                      text: arrestDate.isNotEmpty ? arrestDate : '____________',
                      style: arrestDate.isNotEmpty ? bold : regular,
                    ),
                    const pw.TextSpan(text: ' रोजी वेळ '),
                    pw.TextSpan(
                      text:
                          arrestTime.isNotEmpty ? arrestTime : '_____________',
                      style: arrestTime.isNotEmpty ? bold : regular,
                    ),
                    const pw.TextSpan(text: ' वाजता अटक करण्यात आली आहे.'),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),

              // Brief facts
              pw.Text(
                'गुन्ह्याची थोडक्यात हकीकत :-',
                style: bold.copyWith(decoration: pw.TextDecoration.underline),
              ),
              pw.SizedBox(height: 1),
              if (briefFacts.isNotEmpty) ...[
                pw.Text(briefFacts,
                    style: regular, textAlign: pw.TextAlign.justify),
                pw.SizedBox(height: 3),
              ] else ...[
                pw.Container(
                    height: 0.6,
                    color: PdfColors.black,
                    margin: const pw.EdgeInsets.symmetric(vertical: 4)),
                pw.Container(
                    height: 0.6,
                    color: PdfColors.black,
                    margin: const pw.EdgeInsets.symmetric(vertical: 4)),
                pw.Container(
                    height: 0.6,
                    color: PdfColors.black,
                    margin: const pw.EdgeInsets.symmetric(vertical: 4)),
              ],
              pw.SizedBox(height: 5),

              // Table intro
              pw.Text(
                'अटकेची कारणे (Reasons for Arrest) खालीलप्रमाणे लिखित स्वरूपात पुरवण्यात येत आहेत:-',
                style: bold.copyWith(decoration: pw.TextDecoration.underline),
              ),
              pw.SizedBox(height: 3),

              // Reasons of Arrest Table
              pw.Table(
                border: const pw.TableBorder(
                  left: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  right: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  top: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                  horizontalInside:
                      pw.BorderSide(color: PdfColors.black, width: 0.8),
                  verticalInside:
                      pw.BorderSide(color: PdfColors.black, width: 0.8),
                ),
                columnWidths: const {
                  0: pw.FixedColumnWidth(30),
                  1: pw.FlexColumnWidth(1),
                },
                children: p11ReasonRows,
              ),
              pw.SizedBox(height: 14),

              // Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'दिनांक :- ${noticeDate.isNotEmpty ? noticeDate : '______________'}',
                        style: regular,
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'ठिकाण ${noticePlace.isNotEmpty ? ':- $noticePlace' : ''}',
                        style: regular,
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (officerName.isNotEmpty) ...[
                        pw.Text(officerName, style: bold),
                        pw.SizedBox(height: 10),
                      ] else ...[
                        pw.SizedBox(height: 16),
                      ],
                      pw.Text('पोलिस अधिकारी नाव सही शिक्का', style: regular),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (accusedName.isNotEmpty) ...[
                        pw.Text(accusedName, style: bold),
                        pw.SizedBox(height: 10),
                      ] else ...[
                        pw.SizedBox(height: 16),
                      ],
                      pw.Text('आरोपीचे नाव , सही, अंगठा', style: regular),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  return pdf.save();
}
