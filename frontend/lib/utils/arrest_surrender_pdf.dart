import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../widgets/form_section_utils.dart';

Future<void> previewArrestSurrenderPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final bytes = await generateArrestSurrenderPdf(doc);
  if (!context.mounted) return;
  final fileName = 'Arrest_Court_Surrender_Form_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

Future<Uint8List> generateArrestSurrenderPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();

  // Load fonts
  final loraRegular = await PdfGoogleFonts.loraRegular();
  final loraBold = await PdfGoogleFonts.loraBold();
  final devanagariRegular = await PdfGoogleFonts.notoSansDevanagariRegular();
  final devanagariBold = await PdfGoogleFonts.notoSansDevanagariBold();

  const knownSectionIds = {'Form 3-A', 'Form 3-B', 'Form 3-C'};
  final activeSection = doc['formSection']?.toString();

  bool showsSection(String sectionId) => showsFormSection(
        activeSection: activeSection,
        sectionId: sectionId,
        knownSectionIds: knownSectionIds,
      );

  final engStyle = pw.TextStyle(font: loraRegular, fontSize: 8.5);
  final engBold = pw.TextStyle(font: loraBold, fontSize: 8.5, fontWeight: pw.FontWeight.bold);
  final mrStyle = pw.TextStyle(font: devanagariRegular, fontSize: 7.5);
  final mrBold = pw.TextStyle(font: devanagariBold, fontSize: 7.5, fontWeight: pw.FontWeight.bold);

  String v(String key) => doc[key]?.toString().trim() ?? '';
  bool b(String key) => doc[key] == true || doc[key] == 'true' || doc[key] == '1';

  List<Map<String, dynamic>> parseRows(String key, List<int> indices) {
    final list = <Map<String, dynamic>>[];
    if (doc[key] is List && (doc[key] as List).isNotEmpty) {
      for (final r in doc[key] as List) {
        if (r is Map) list.add(Map<String, dynamic>.from(r));
      }
    }
    if (list.isEmpty && doc['physRows'] is List && (doc['physRows'] as List).isNotEmpty) {
      for (final r in doc['physRows'] as List) {
        if (r is Map) list.add(Map<String, dynamic>.from(r));
      }
    }
    if (list.isEmpty && doc['physTable'] is Map) {
      list.add(Map<String, dynamic>.from(doc['physTable'] as Map));
    }
    if (list.isEmpty) {
      list.add({});
    }
    return list;
  }

  final t1Rows = parseRows('t1Rows', [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  final t2Rows = parseRows('t2Rows', [11, 12, 13, 14, 15, 16, 17, 18, 19, 20]);
  final t3Rows = parseRows('t3Rows', [21, 22, 23, 24, 25, 26]);

  pw.Widget underlineField(String text, {double? width, double minWidth = 20}) {
    return pw.Container(
      width: width,
      constraints: pw.BoxConstraints(minWidth: minWidth),
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.6)),
      ),
      child: pw.Text(
        text.isEmpty ? ' ' : text,
        style: pw.TextStyle(font: devanagariBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget multilineBox(String text, {int lines = 2}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.6)),
      ),
      child: pw.Text(
        text.isEmpty ? ' ' : text,
        style: pw.TextStyle(font: devanagariRegular, fontSize: 8),
      ),
    );
  }

  pw.Widget subLabel(String text) {
    return pw.Text(text, style: mrStyle);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 1 — FORM 3-A PDF
  // ══════════════════════════════════════════════════════════════════════════
  if (showsSection('Form 3-A')) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 22),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('From: 3-A', style: engBold.copyWith(fontSize: 10)),
            ),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('ARREST/COURT SURRENDER FORM', style: engBold.copyWith(fontSize: 11)),
                  pw.Text('अटकेचा पंचनामा/ न्यायालयाच्या स्वाधीन होण्याचा नमुना', style: mrBold.copyWith(fontSize: 9.5)),
                  pw.Text('(Separate Memo for each accused)', style: engBold.copyWith(fontSize: 8)),
                  pw.Text('(प्रत्येक आरोपीसाठी स्वतंत्र नमुना वापरावा)', style: mrStyle.copyWith(fontSize: 7.5)),
                ],
              ),
            ),
            pw.SizedBox(height: 6),

            // 1. Dist, P.S., FIR, Year, Date
            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              spacing: 2,
              runSpacing: 2,
              children: [
                pw.Text('1.Dist.(YAVATMAL)P.S.:', style: engStyle),
                underlineField(v('ps'), width: 85),
                pw.Text('FIR/Proceeding/G.D.No:-', style: engStyle),
                underlineField(v('firNo'), width: 75),
                pw.Text('Year:-20', style: engStyle),
                underlineField(v('year'), width: 30),
                pw.Text('Date....', style: engStyle),
                underlineField(v('date'), width: 65),
              ],
            ),
            subLabel('   जिल्हा                    पो.स्टे.                 पहिली खबर क्र./ कार्यवाही क्र.             वर्ष          दिनांक'),
            pw.SizedBox(height: 3),

            pw.Row(
              children: [
                pw.Text('Alphanumeric Code of the Accused (Write A1 to A9 for the first 9 persons, B1 for 10 th person and so on).', style: engStyle.copyWith(fontSize: 7.5)),
                pw.Expanded(child: underlineField(v('accusedCode'))),
              ],
            ),
            subLabel('आरोपीचा मुळाक्षरी संकेत (पहिल्या ९ व्यक्तीसाठी अ १ ते अ ९, दहाव्या व्यक्तीसाठी ब १ या प्रमाणे पुढे असे लिहावे )'),
            pw.SizedBox(height: 5),

            // 2. Date, Time & place
            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              spacing: 2,
              runSpacing: 2,
              children: [
                pw.Text('2. Date, Time & place of Arrest/surrender :- Date ', style: engStyle),
                underlineField(v('arrestDate'), width: 60),
                pw.Text(' Time ', style: engStyle),
                underlineField(v('arrestTime'), width: 50),
                pw.Text(' G.D.No. ', style: engStyle),
                underlineField(v('arrestGdNo'), width: 60),
              ],
            ),
            subLabel('   अटकेची / स्वाधीन होण्याची तारीख वेळ              दिनांक                  वेळ               ठाणे दैनंदिन क्रमांक'),
            pw.SizedBox(height: 2),

            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              spacing: 2,
              runSpacing: 2,
              children: [
                pw.Text('Place of Arrest: - P.S. ', style: engStyle),
                underlineField(v('arrestPlace'), width: 110),
                pw.Text(' Dist. ', style: engStyle),
                underlineField(v('arrestDist'), width: 90),
                pw.Text(' State ', style: engStyle),
                underlineField(v('arrestState'), width: 90),
              ],
            ),
            subLabel('   अटकेची जागा         पोलीस ठाणे                   जिल्हा                       राज्य'),
            pw.SizedBox(height: 4),

            // 3. Name of court
            pw.Row(
              children: [
                pw.Text('3. Name of the Court (if surrendered) :- ', style: engStyle),
                pw.Expanded(child: underlineField(v('courtName'))),
              ],
            ),
            subLabel('   न्यायालयाचे नांव ( स्वाधीन झाल्यास ) :-'),
            pw.SizedBox(height: 4),

            // 4. Acts and sections
            pw.Row(
              children: [
                pw.Text('4. Acts and sections:- ', style: engStyle),
                pw.Expanded(child: underlineField(v('actsSections'))),
              ],
            ),
            subLabel('   अधिनियम व कलमे :-'),
            pw.SizedBox(height: 5),

            // 5. Checkboxes text
            pw.Text(
              '5. Arrested and forward / Arrested and released on bail or PR bound / Arrested but released on anticipatory bail/ Arrested and remanded to police Custody / Surrender in court and bailed out / Surrender in court and sent to judicial Custody / Surrender in court and remanded to police custody (tie applicable potion).',
              style: engBold.copyWith(fontSize: 7.5),
            ),
            pw.Text(
              'अटक केली व न्यायालयात पाठविले / अटक केली व जामिनावर सोडले किंवा वैयक्तिक जात मुचलक्यावर सोडले / अटक केली व अटकपूर्व जामिनावर सोडले / अटक केले व पोलीस कोठडीत पाठविले/ न्यायालयात स्वाधीन व जामीनावर / न्यायालयाचे स्वाधीन व न्यायालयीन कोठडीत पाठविले / न्यायालयाचे स्वाधीन व पोलीस कोठडीत पाठविले (लागू असेल त्या भागावर [v] अशी खूण करावी )',
              style: mrStyle.copyWith(fontSize: 7),
            ),
            pw.SizedBox(height: 2),

            pw.Row(children: [
              pw.Text(b('arrestedAndForwarded') ? '[v] ' : '[  ] ', style: engBold),
              pw.Text('Arrested & forward (अटक केली व न्यायालयात पाठविले)    ', style: engStyle),
              pw.Text(b('arrestedAndBailed') ? '[v] ' : '[  ] ', style: engBold),
              pw.Text('Released on bail/PR (जामिनावर सोडले)', style: engStyle),
            ]),
            pw.Row(children: [
              pw.Text(b('arrestedButAnticipatory') ? '[v] ' : '[  ] ', style: engBold),
              pw.Text('Anticipatory bail (अटकपूर्व जामिनावर)    ', style: engStyle),
              pw.Text(b('arrestedAndRemandedPolice') ? '[v] ' : '[  ] ', style: engBold),
              pw.Text('Remanded police custody (पोलीस कोठडीत)', style: engStyle),
            ]),
            pw.Row(children: [
              pw.Text(b('surrenderBailed') ? '[v] ' : '[  ] ', style: engBold),
              pw.Text('Surrender in court & bailed out (स्वाधीन व जामीनावर)    ', style: engStyle),
              pw.Text(b('surrenderJudicial') ? '[v] ' : '[  ] ', style: engBold),
              pw.Text('Judicial custody (न्यायालयीन कोठडीत)', style: engStyle),
            ]),
            pw.Row(children: [
              pw.Text(b('surrenderPolice') ? '[v] ' : '[  ] ', style: engBold),
              pw.Text('Surrender in court & remanded to police custody (स्वाधीन व पोलीस कोठडीत पाठविले)', style: engStyle),
            ]),
            pw.SizedBox(height: 5),

            // 6. Particulars of Accused
            pw.Text('6. Particulars of the Accused (आरोपीचा तपशील ) :-', style: engBold),
            pw.SizedBox(height: 2),

            pw.Row(children: [
              pw.Text('(i) Name (नाव) : ', style: engStyle),
              pw.Expanded(child: underlineField(v('accusedName'))),
            ]),
            pw.SizedBox(height: 2),

            pw.Row(children: [
              pw.Text("(ii) Father's/Husband's/Guardian's Name (पित्याचे/पतीचे/पालकाचे नांव ) : ", style: engStyle),
              pw.Expanded(child: underlineField(v('accusedFather'))),
            ]),
            pw.SizedBox(height: 2),

            pw.Row(children: [
              pw.Text('(iii) Fist Alias (पहिले टोपण नांव ) : ', style: engStyle),
              pw.Expanded(child: underlineField(v('accusedAlias1'))),
            ]),
            pw.SizedBox(height: 2),

            pw.Row(children: [
              pw.Text('(iv) Second Alias (दुसरे टोपण नांव ) : ', style: engStyle),
              pw.Expanded(child: underlineField(v('accusedAlias2'))),
            ]),
            pw.SizedBox(height: 2),

            pw.Row(children: [
              pw.Text('(v) Nationality (राष्ट्रीयत्व) : ', style: engStyle),
              pw.Expanded(child: underlineField(v('accusedNationality'))),
            ]),
            pw.SizedBox(height: 2),

            pw.Row(children: [
              pw.Text('(vi) (a) Voter ID. Card No: - ', style: engStyle),
              pw.Expanded(child: underlineField(v('accusedVoter'))),
              pw.SizedBox(width: 8),
              pw.Text('(b) *Passport No: - ', style: engStyle),
              pw.Expanded(child: underlineField(v('accusedPassport'))),
            ]),
            subLabel('         मतदान ओळखपत्र क्रमांक:-                                पारपत्र क्रमांक :-'),
            pw.SizedBox(height: 2),

            pw.Row(children: [
              pw.Text('(c) Date of issue : - ', style: engStyle),
              pw.Expanded(child: underlineField(v('accusedDateIssue'))),
              pw.SizedBox(width: 8),
              pw.Text('(d) *Place or Issue :- ', style: engStyle),
              pw.Expanded(child: underlineField(v('accusedPlaceIssue'))),
            ]),
            subLabel('         दिल्याची तारीख :-                                      दिल्याची जागा :-'),
            pw.SizedBox(height: 2),

            pw.Row(children: [
              pw.Text('(vii) Religion: - ', style: engStyle),
              pw.Expanded(child: underlineField(v('accusedReligion'))),
              pw.SizedBox(width: 8),
              pw.Text('(viii) *Cast/Tribe: - ', style: engStyle),
              pw.Expanded(child: underlineField(v('accusedCaste'))),
            ]),
            subLabel('      धर्म :-                                                   जात/जमात :-'),
            pw.SizedBox(height: 2),

            pw.Row(children: [
              pw.Text('(ix) SC/ST/OBC :- ', style: engStyle),
              pw.Expanded(child: underlineField(v('accusedScSt'))),
              pw.SizedBox(width: 8),
              pw.Text('(x) *Occupation :- ', style: engStyle),
              pw.Expanded(child: underlineField(v('accusedOccupation'))),
            ]),
            subLabel('      (अ.जा./अ.ज./इ.मा.व.) :-                                    व्यवसाय :-'),
            pw.SizedBox(height: 3),

            pw.Row(children: [
              pw.Text('(xi) Permanent Address : ', style: engStyle),
              pw.Expanded(child: underlineField(v('permAddress'))),
            ]),
            subLabel('      कायमचा पत्ता :-'),
            pw.Row(children: [
              pw.Text('      State : - ', style: engStyle),
              underlineField(v('permState'), width: 80),
              pw.Text(' Dist.:- ', style: engStyle),
              underlineField(v('permDist'), width: 80),
              pw.Text(' P.S. : - ', style: engStyle),
              pw.Expanded(child: underlineField(v('permPs'))),
            ]),
            subLabel('      राज्य                             जिल्हा                          पोलीस ठाणे'),
            pw.SizedBox(height: 3),

            pw.Row(children: [
              pw.Text('(xii) Present Address : ', style: engStyle),
              pw.Expanded(child: underlineField(v('presAddress'))),
            ]),
            subLabel('      हल्लीचा पत्ता :-'),
            pw.Row(children: [
              pw.Text('      State : - ', style: engStyle),
              underlineField(v('presState'), width: 80),
              pw.Text(' Dist.:- ', style: engStyle),
              underlineField(v('presDist'), width: 80),
              pw.Text(' P.S. : - ', style: engStyle),
              pw.Expanded(child: underlineField(v('presPs'))),
            ]),
            subLabel('      राज्य                             जिल्हा                          पोलीस ठाणे'),
            pw.SizedBox(height: 4),

            // 7. Injuries
            pw.Text('7. Injuries, cause of injuries and physical condition of the accused person (indicate if medically examined)', style: engBold),
            subLabel('जखमा, जखमांची कारणे आणि आरोपीची शारीरिक स्थिती / (वैद्यकीय तपासणी केली असल्यास नमूद करणे)'),
            multilineBox(v('injuries'), lines: 2),

            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('M.R.W', style: engStyle.copyWith(fontSize: 8, fontStyle: pw.FontStyle.italic)),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 2 — FORM 3-B PDF
  // ══════════════════════════════════════════════════════════════════════════
  if (showsSection('Form 3-B')) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 22),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('From: 3-B', style: engBold.copyWith(fontSize: 10)),
            ),
            pw.SizedBox(height: 4),

            // 8. Custody notice
            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              spacing: 2,
              runSpacing: 2,
              children: [
                pw.Text('8. The accused, after vying informed of the grounds of arrest and his leagal rights, was duty taken. Into custody on :- ', style: engStyle),
                underlineField(v('custodyDate'), width: 65),
                pw.Text('(date) at :- ', style: engStyle),
                underlineField(v('custodyHours'), width: 50),
                pw.Text('(hours) at :- ', style: engStyle),
                underlineField(v('custodyPlace'), width: 90),
                pw.Text('(place).', style: engStyle),
              ],
            ),
            subLabel('कायदेशीर अटकेची कारणे आणि त्याचे कायदेशीर अधिकार सांगीतल्यानंतर दि. ----/----/20.... रोजी ..../.... वाजता (ठिकाण) येथे योग्य रित्या ताब्यात घेण्यात आले.'),
            pw.SizedBox(height: 6),

            pw.Text(
              'The following article(s) was/were found on physical search. Conducted on the person of the accused. And were taken into possession for which a receipt was given to the accused. **',
              style: engBold,
            ),
            subLabel('आरोपीच्या अंगझडतीमध्ये खालील वस्तु आढळल्या, त्या ताब्यात घेण्यात आल्या आणि त्या बद्दल त्याची पोच देण्यात आली.'),
            pw.SizedBox(height: 4),

            pw.Row(children: [
              pw.Text('1 ', style: engStyle),
              pw.Expanded(child: underlineField(v('article1'))),
              pw.SizedBox(width: 12),
              pw.Text('2 ', style: engStyle),
              pw.Expanded(child: underlineField(v('article2'))),
            ]),
            pw.SizedBox(height: 3),
            pw.Row(children: [
              pw.Text('3 ', style: engStyle),
              pw.Expanded(child: underlineField(v('article3'))),
              pw.SizedBox(width: 12),
              pw.Text('4 ', style: engStyle),
              pw.Expanded(child: underlineField(v('article4'))),
            ]),
            pw.SizedBox(height: 3),
            pw.Row(children: [
              pw.Text('5 ', style: engStyle),
              pw.Expanded(child: underlineField(v('article5'))),
              pw.SizedBox(width: 12),
              pw.Text('6 ', style: engStyle),
              pw.Expanded(child: underlineField(v('article6'))),
            ]),
            pw.SizedBox(height: 5),

            pw.Text('Necessary wearing apparels were left on the accused for the sake of human dignity and body protection', style: engStyle),
            subLabel('(मानवी प्रतिष्ठेसाठी व शरीर झाकण्यासाठी आरोपीच्या अंगावर आवश्यक येवढे कपडे ठेवण्यात आले होते.)'),
            pw.SizedBox(height: 3),

            pw.Text('The accused was cautioned to keep him/herself covered for purpose of identification.', style: engStyle),
            subLabel('ओळख पटण्याच्या प्रयोजनासाठी आरोपीला स्वतःला झाकून ठेवण्याची ताकीद देण्यात आली होती.'),
            pw.SizedBox(height: 4),

            pw.Row(children: [
              pw.Text('Intimation given to Name: ', style: engStyle),
              pw.Expanded(child: underlineField(v('intimationName'))),
              pw.SizedBox(width: 8),
              pw.Text('(Relationship): ', style: engStyle),
              pw.Expanded(child: underlineField(v('intimationRel'))),
            ]),
            subLabel('यांना खबरदेण्यात आली नांव                                            (नाते)'),
            pw.SizedBox(height: 4),

            pw.Text('** If no article found, NIL, may be indicated in the bland space provided below:-', style: engBold.copyWith(fontSize: 7.5)),
            subLabel('जर कोणतीही वस्तु आढळली नाही तर खालील जागेत काही नाही असे नमुद करावे.'),
            pw.SizedBox(height: 8),

            // 9. Physical features
            pw.Text('9. Physical features, deformities and other details of the accused:-', style: engBold),
            subLabel('शारीरिक वैशिष्ट्ये आणि आरोपीचा इतर तपशील :-'),
            pw.SizedBox(height: 4),

            // Table 1 (1-10)
            _buildPdfPhysicalTable(
              headers: [
                ('Sr. No.', 'अ.क्र.', '1.'),
                ('Sex', 'लिंग', '2.'),
                ('Date/year of\nBirth', 'जन्म तारीख/\nवर्ष', '3.'),
                ('Build', 'बांधा', '4.'),
                ('Height in\nCms.', 'उंची से.मी.', '5.'),
                ('Complexion', 'वर्ण', '6.'),
                ('identification\n(Mark)', 'ओळखचिन्ह', '7.'),
                ('Deformities\nPeculiarities', 'व्यंग व\nवैशिष्ट्ये', '8.'),
                ('Teeth', 'दात', '9.'),
                ('Hair', 'केस', '10.'),
              ],
              indices: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
              rows: t1Rows,
              engStyle: engStyle,
              mrStyle: mrStyle,
            ),
            pw.SizedBox(height: 4),

            // Table 2 (11-20)
            _buildPdfPhysicalTable(
              headers: [
                ('Eye', 'डोळे', '11'),
                ('Habits', 'सवयी', '12'),
                ('Dress\nHabits', 'पोषाखाच्या\nसवयी', '13'),
                ('Languages', 'बोली/ भाषा', '14'),
                ('Burn Mark', 'भाजल्याच्या\nखुणा', '15'),
                ('Leucoderma', 'कोड', '16'),
                ('Mole', 'तिळ', '17'),
                ('Scar', 'व्रण', '18'),
                ('Tattoo', 'गोंदण', '19'),
                ('Forehead', 'कपाळ', '20'),
              ],
              indices: [11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
              rows: t2Rows,
              engStyle: engStyle,
              mrStyle: mrStyle,
            ),
            pw.SizedBox(height: 4),

            // Table 3 (21-26)
            _buildPdfPhysicalTable(
              headers: [
                ('Ear', 'कान', '21'),
                ('Noes', 'नाक', '22'),
                ('Moustaches', 'मिशी', '23'),
                ('Speech/voice', 'बोलण्याची पद्धत', '24'),
                ('Face', 'चेहरा', '25'),
                ('Lips', 'ओठ', '26'),
              ],
              indices: [21, 22, 23, 24, 25, 26],
              rows: t3Rows,
              engStyle: engStyle,
              mrStyle: mrStyle,
            ),
            pw.SizedBox(height: 4),

            pw.Row(children: [
              pw.Text('Other features if any: ', style: engStyle),
              pw.Expanded(child: underlineField(v('otherFeatures'))),
            ]),

            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('M.R.W', style: engStyle.copyWith(fontSize: 8, fontStyle: pw.FontStyle.italic)),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 3 — FORM 3-C PDF
  // ══════════════════════════════════════════════════════════════════════════
  if (showsSection('Form 3-C')) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 22),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('From: 3-C', style: engBold.copyWith(fontSize: 10)),
            ),
            pw.SizedBox(height: 4),

            // 10. Fingerprints
            pw.Row(children: [
              pw.Text('10. Whether finger print taken or not? :- ', style: engBold),
              pw.Expanded(child: underlineField(v('fingerprint'))),
            ]),
            subLabel('बोटांचे ठसे घेतले आहेत किंवा नाही असल्यास त्यांचा नंबर / ठसे घेतले नसल्यास त्याचे कारण.'),
            pw.SizedBox(height: 6),

            // 11. Socio-economic profile
            pw.Text('11. Socio-economic profile of the accused showing.', style: engBold),
            pw.Text(
              '(a) Living Status: - Living alone/Living with Family/with Associate in Pucca House/Hotel/ Hostel/ Kacheha House / Thatched House / Slum/ Homeless/ Harbourer.',
              style: engStyle.copyWith(fontSize: 7.5),
            ),
            subLabel('राहणीमान :- एकटा कुटुंबासोबत/ सहकारी यांच्या बरोबर पक्का घरात/ हॉटेलात/ वसतीगृहात/ कच्चा घरात/ गवतानी छपरच्या झोपडीत गरीबांच्या वस्तीत राहतो/ बेघर किंवा आसरा देणारेच नाही.'),
            pw.SizedBox(height: 2),

            pw.Wrap(
              spacing: 6,
              runSpacing: 2,
              children: [
                _pdfSmallCheck('Living alone (एकटा)', b('livingAlone'), engStyle),
                _pdfSmallCheck('With Family (कुटुंब)', b('livingWithFamily'), engStyle),
                _pdfSmallCheck('Pucca (पक्के)', b('livingPucca'), engStyle),
                _pdfSmallCheck('Hotel (हॉटेल)', b('livingHotel'), engStyle),
                _pdfSmallCheck('Kachcha (कच्चे)', b('livingKachcha'), engStyle),
                _pdfSmallCheck('Slum (झोपडपट्टी)', b('livingSlum'), engStyle),
                _pdfSmallCheck('Homeless (बेघर)', b('livingHomeless'), engStyle),
              ],
            ),
            pw.SizedBox(height: 4),

            pw.Row(children: [
              pw.Text('(b) Educational qualifications(s) (शैक्षणिक अर्हता) : ', style: engStyle),
              underlineField(v('eduQual'), width: 110),
              pw.SizedBox(width: 8),
              pw.Text('(c) occupation (व्यवसाय) : ', style: engStyle),
              pw.Expanded(child: underlineField(v('occupation2'))),
            ]),
            pw.SizedBox(height: 4),

            pw.Text('(d) Income Group (उत्पन्न गट ) :-', style: engBold),
            _pdfIncomeRow('(i) Lower Income (Below Rs. 25000 P.Y.)', 'कमी उत्पन्न (रु. २५००० पेक्षा कमी )', b('incomeLower'), engStyle, mrStyle),
            _pdfIncomeRow('(ii) Lower Middle Income (From Rs. 25001 to 50000)', 'कमी मध्यम उत्पन्न ( २५,००१ ते ५०,०००)', b('incomeLowerMid'), engStyle, mrStyle),
            _pdfIncomeRow('(iii) Middle Income (From 50001 to 100000)', 'मध्यम उत्पन्न (५०,००१ ते १,००,००० )', b('incomeMiddle'), engStyle, mrStyle),
            _pdfIncomeRow('(iv) Upper Middle Income (/From 100000 to 200000)', 'उच्च मध्यम उत्पन्न ( १,००,००१ ते २,००,०००)', b('incomeUpperMid'), engStyle, mrStyle),
            _pdfIncomeRow('(v) Upper Middle Income (Rs. 200000 to 300000)', 'उच्च मध्यम उत्पन्न ( २,००,००१ ते ३,००,०००)', b('incomeUpperMid2'), engStyle, mrStyle),
            _pdfIncomeRow('(vi) Upper Income (above 300000) =SSE', 'उच्च उत्पन्न ( ३,००,०००+)', b('incomeUpper'), engStyle, mrStyle),
            pw.SizedBox(height: 6),

            // 12. Police records
            pw.Text('12. Whether the accused person as per the observations and known police records:', style: engBold),
            subLabel('निरीक्षणावरून आणि माहिती असलेल्या पोलीस अभिलेखानुसार आरोपी :-'),
            pw.SizedBox(height: 2),

            _pdfYesNo('(a)', 'Is dangerous ? (धोकादायक आहे किंवा कसे?)', b('isDangerous'), engStyle),
            _pdfYesNo('(b)', 'Previously escaped any bail ? (पूर्वी जामिनावर असताना पळून गेला किंवा काय ?)', b('prevEscaped'), engStyle),
            _pdfYesNo('(c)', 'Is generally armed? (नेहमी सशस्त्र असतो किंवा कसे ?)', b('generallyArmed'), engStyle),
            _pdfYesNo('(d)', 'Operates with accomplices? (साथीदारासह कृत्य करतो किंवा कसे ?)', b('operatesWithAccomplices'), engStyle),
            _pdfYesNo('(e)', 'Has past criminal records ? (गुन्हेगारी पार्श्वभूमी आहे किंवा नाही ?)', b('pastCriminal'), engStyle),
            _pdfYesNo('(f)', 'Is recidivism (वारंवार अपराध करणे किंवा काय ?)', b('isRecidivism'), engStyle),
            _pdfYesNo('(g)', 'Is likely to escape bail ? (जामिनावर असताना पळून जाण्याची पूर्वा आहे किंवा नाही ?)', b('likelyToEscape'), engStyle),
            _pdfYesNo('(h)', 'Is released on bail. Likely to commit crime / threaten victims (धाकदाखवण्याचा पूर्वा)', b('releasedOnBail'), engStyle),
            _pdfYesNo('(i)', 'Is wanted many other case? (इतर गुन्ह्यामध्ये पाहिजे किंवा काय ?)', b('wantedMany'), engStyle),

            pw.Row(children: [
              pw.Text('(If yes give case ref. Sec.) ', style: engStyle),
              pw.Expanded(child: underlineField(v('caseRefSec'))),
            ]),
            subLabel('( जर होय असेल तर त्या प्रकरणाचा संदर्भ व कलमे याबद्दल ?)'),
            pw.SizedBox(height: 5),

            // 13. Panch witnesses
            pw.Row(children: [
              pw.Expanded(
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Row(children: [
                    pw.Text('13. पंच साक्षी (१) : ', style: mrBold),
                    pw.Expanded(child: underlineField(v('panch1Name'))),
                  ]),
                  pw.Text('Name and Address of witness (1)', style: engStyle.copyWith(fontSize: 7)),
                ]),
              ),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Row(children: [
                    pw.Text('पंचांच्या सह्या (१) : ', style: mrBold),
                    pw.Expanded(child: underlineField(v('panch1Sig'))),
                  ]),
                  pw.Text('Signature', style: engStyle.copyWith(fontSize: 7)),
                ]),
              ),
            ]),
            pw.SizedBox(height: 3),

            pw.Row(children: [
              pw.Expanded(
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Row(children: [
                    pw.Text('      पंच साक्षी (२) : ', style: mrBold),
                    pw.Expanded(child: underlineField(v('panch2Name'))),
                  ]),
                  pw.Text('Name and Address of witness (2)', style: engStyle.copyWith(fontSize: 7)),
                ]),
              ),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Row(children: [
                    pw.Text('पंचांच्या सह्या (२) : ', style: mrBold),
                    pw.Expanded(child: underlineField(v('panch2Sig'))),
                  ]),
                  pw.Text('Signature (2)', style: engStyle.copyWith(fontSize: 7)),
                ]),
              ),
            ]),
            pw.SizedBox(height: 6),

            // 14. Signatures
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Expanded(
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('14. Signature and Thumb Impression of Arrested person', style: engBold.copyWith(fontSize: 7.5)),
                  subLabel('आरोपीची सही व आरोपीचा डा अंगठा'),
                  underlineField(v('arrestedPersonSig')),
                ]),
              ),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('Signature of the Investigation Officer with:', style: engBold.copyWith(fontSize: 7.5)),
                  subLabel('तपासणी अधिकाऱ्याचे नांव व सही'),
                  underlineField(v('ioSig')),
                ]),
              ),
            ]),
            pw.SizedBox(height: 5),

            // 15. Place/Date & IO details
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Expanded(
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Row(children: [
                    pw.Text('15. Place: ', style: engStyle),
                    pw.Expanded(child: underlineField(v('finalPlace'))),
                  ]),
                  subLabel('    ठिकाण'),
                  pw.Row(children: [
                    pw.Text('    Date: ', style: engStyle),
                    pw.Expanded(child: underlineField(v('finalDate'))),
                  ]),
                  subLabel('    तारीख'),
                ]),
              ),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Row(children: [
                    pw.Text('Name: ', style: engStyle),
                    pw.Expanded(child: underlineField(v('finalName'))),
                  ]),
                  subLabel('तपासणी अधिकाऱ्याचे नांव'),
                  pw.Row(children: [
                    pw.Text('Rank: ', style: engStyle),
                    underlineField(v('finalRank'), width: 60),
                    pw.Text(' No: ', style: engStyle),
                    pw.Expanded(child: underlineField(v('finalNo'))),
                  ]),
                  subLabel('पद                         क्रमांक'),
                ]),
              ),
            ]),

            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('M.R.W', style: engStyle.copyWith(fontSize: 8, fontStyle: pw.FontStyle.italic)),
            ),
          ],
        ),
      ),
    );
  }

  return pdf.save();
}

pw.Widget _buildPdfPhysicalTable({
  required List<(String, String, String)> headers,
  required List<int> indices,
  required List<Map<String, dynamic>> rows,
  required pw.TextStyle engStyle,
  required pw.TextStyle mrStyle,
}) {
  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: headers.map((h) {
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 1),
            child: pw.Column(
              children: [
                pw.Text(h.$1, textAlign: pw.TextAlign.center, style: pw.TextStyle(font: engStyle.font, fontSize: 6.5, fontWeight: pw.FontWeight.bold)),
                pw.Text(h.$2, textAlign: pw.TextAlign.center, style: pw.TextStyle(font: mrStyle.font, fontSize: 6)),
                pw.Divider(color: PdfColors.grey600, height: 2, thickness: 0.4),
                pw.Text(h.$3, textAlign: pw.TextAlign.center, style: pw.TextStyle(font: engStyle.font, fontSize: 6.5, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          );
        }).toList(),
      ),
      ...rows.map((row) {
        return pw.TableRow(
          children: indices.map((idx) {
            final val = row[idx.toString()]?.toString().trim() ?? '';
            return pw.Padding(
              padding: const pw.EdgeInsets.all(1.5),
              child: pw.Text(
                val.isEmpty ? ' ' : val,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(font: mrStyle.font, fontSize: 7, fontWeight: pw.FontWeight.bold),
              ),
            );
          }).toList(),
        );
      }),
    ],
  );
}

pw.Widget _pdfSmallCheck(String label, bool value, pw.TextStyle style) {
  return pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.Text(value ? '[v] ' : '[  ] ', style: pw.TextStyle(font: style.font, fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
      pw.Text(label, style: pw.TextStyle(font: style.font, fontSize: 7)),
    ],
  );
}

pw.Widget _pdfIncomeRow(String en, String mr, bool value, pw.TextStyle engStyle, pw.TextStyle mrStyle) {
  return pw.Row(
    children: [
      pw.Text(value ? '[v] ' : '[  ] ', style: pw.TextStyle(font: engStyle.font, fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
      pw.Text('$en = ', style: pw.TextStyle(font: engStyle.font, fontSize: 7)),
      pw.Text(mr, style: pw.TextStyle(font: mrStyle.font, fontSize: 7)),
    ],
  );
}

pw.Widget _pdfYesNo(String numStr, String q, bool value, pw.TextStyle style) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Expanded(
        child: pw.Text('$numStr $q', style: pw.TextStyle(font: style.font, fontSize: 7)),
      ),
      pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(value ? '[v] Yes (होय)' : '[  ] Yes (होय)', style: pw.TextStyle(font: style.font, fontSize: 6.5)),
          pw.SizedBox(width: 6),
          pw.Text(!value ? '[v] No (नाही)' : '[  ] No (नाही)', style: pw.TextStyle(font: style.font, fontSize: 6.5)),
        ],
      ),
    ],
  );
}
