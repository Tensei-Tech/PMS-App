import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../widgets/form_section_utils.dart';

Future<void> previewInquestPanchanamaPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final bytes = await generateInquestPanchanamaPdf(doc);
  if (!context.mounted) return;
  final fileName = 'Inquest_Panchanama_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

Future<Uint8List> generateInquestPanchanamaPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();

  final loraRegular = await PdfGoogleFonts.loraRegular();
  final loraBold = await PdfGoogleFonts.loraBold();
  final devanagariRegular = await PdfGoogleFonts.notoSansDevanagariRegular();
  final devanagariBold = await PdfGoogleFonts.notoSansDevanagariBold();

  final engStyle = pw.TextStyle(font: loraRegular, fontSize: 8.5);
  final engBold = pw.TextStyle(font: loraBold, fontSize: 8.5, fontWeight: pw.FontWeight.bold);
  final mrStyle = pw.TextStyle(font: devanagariRegular, fontSize: 7.5);
  final mrBold = pw.TextStyle(font: devanagariBold, fontSize: 7.5, fontWeight: pw.FontWeight.bold);

  String v(String key) => doc[key]?.toString().trim() ?? '';

  const knownSectionIds = {
    'Inquest Main',
    'Civil Surgeon PM Report',
    'Vinanti Arj',
    'Relative Summons 179',
    'Pancha Summons 195',
    'Marananveshan Panchanama',
    '14 Kalmi Form',
    'Dead Body Handover',
    'Duty Pass',
  };
  final activeSection = doc['formSection']?.toString();

  bool showsSection(String sectionId) => showsFormSection(
        activeSection: activeSection,
        sectionId: sectionId,
        knownSectionIds: knownSectionIds,
      );

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
      constraints: pw.BoxConstraints(minHeight: lines * 12.0),
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

  pw.Widget injuryRow(String labelEn, String labelMr, String val) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.SizedBox(
                width: 90,
                child: pw.Text(labelEn, style: engBold),
              ),
              pw.Expanded(child: underlineField(val)),
            ],
          ),
          pw.Text('   $labelMr', style: mrStyle),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 1 — INQUEST MAIN
  // ══════════════════════════════════════════════════════════════════════════
  if (showsSection('Inquest Main')) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 22),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('INQUEST PANCHANAMA', style: engBold.copyWith(fontSize: 12)),
                  pw.Text('मरणोत्तर पंचनामा', style: mrBold.copyWith(fontSize: 10)),
                  pw.SizedBox(height: 1),
                  pw.Text('(Under Section - 194 B.N.S.S.)', style: engBold.copyWith(fontSize: 8.5)),
                  pw.Text('( भारतीय नागरिक सुरक्षा संहिता २०२३ कलम १९४ अन्वये.)', style: mrStyle.copyWith(fontSize: 8)),
                ],
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Divider(color: PdfColors.black, thickness: 0.8),
            pw.SizedBox(height: 6),

            // 1) Dist, PS, Year, FIR
            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              spacing: 2,
              runSpacing: 2,
              children: [
                pw.Text('1) Dist. (YAVATMAL)', style: engBold),
                pw.SizedBox(width: 20),
                pw.Text('P.S.:-', style: engBold),
                underlineField(v('ps'), width: 100),
                pw.Text('Year:-20', style: engBold),
                underlineField(v('year'), width: 35),
                pw.SizedBox(width: 10),
                pw.Text('FIR/AD/U.D.No:-', style: engBold),
                underlineField(v('firNo'), width: 90),
              ],
            ),
            subLabel('   जिल्हा - यवतमाळ             पो.स्टे.             वर्ष                     पहिली खबर क्र./ अकस्मात मृत्यू क्र.'),
            pw.SizedBox(height: 6),

            // 2) Act and Section
            pw.Row(
              children: [
                pw.Text('2) Act and Section: - ', style: engBold),
                pw.Expanded(child: underlineField(v('actSections'))),
              ],
            ),
            subLabel('   अधिनियम व कलमे :-'),
            pw.SizedBox(height: 6),

            // 3) Place where body found
            pw.Row(
              children: [
                pw.Text('3) Place From where Dead Body Found/Traced : ', style: engBold),
                pw.Expanded(child: underlineField(v('deadBodyFoundPlace'))),
              ],
            ),
            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              spacing: 2,
              runSpacing: 2,
              children: [
                subLabel('   प्रेत सापडल्याचे /मिळाल्याचे ठिकाण / जागा     '),
                pw.Text('Place:-', style: engStyle),
                underlineField(v('foundPlace'), width: 100),
                pw.Text('Date:', style: engStyle),
                underlineField(v('foundDate'), width: 65),
                pw.Text(' time:', style: engStyle),
                underlineField(v('foundTime'), width: 55),
              ],
            ),
            pw.SizedBox(height: 6),

            // 4) By whom shown
            pw.Row(
              children: [
                pw.Text('4) By whom Dead Body Shown                   :', style: engBold),
                pw.Expanded(child: underlineField(v('shownBy'))),
              ],
            ),
            subLabel('   प्रेत कोणी दाखविले :-'),
            pw.SizedBox(height: 6),

            // 5) By whom identified
            pw.Row(
              children: [
                pw.Text('5) By whom Dead Body Identified              :', style: engBold),
                pw.Expanded(child: underlineField(v('identifiedBy'))),
              ],
            ),
            subLabel('   प्रेत कोणी ओळखले :-'),
            multilineBox(v('identifiedBy2'), lines: 2),
            pw.SizedBox(height: 6),

            // a) Male/Female
            pw.Row(
              children: [
                pw.Text('a) Dead Body Male/Female                     :', style: engBold),
                pw.Expanded(child: underlineField(v('gender'))),
              ],
            ),
            subLabel('   अ) प्रेत स्त्री / पुरुष जातीचे :-'),
            pw.SizedBox(height: 6),

            // 6) b) Married/Unmarried
            pw.Row(
              children: [
                pw.Text('6) b) Dead Body Married/Unmarried            :', style: engBold),
                pw.Expanded(child: underlineField(v('married'))),
              ],
            ),
            subLabel('   ब) प्रेत विवाहीत /अविवाहीत आहे :-'),
            pw.SizedBox(height: 6),

            // c) Age
            pw.Row(
              children: [
                pw.Text('c) Age of Dead Body                          :', style: engBold),
                pw.Expanded(child: underlineField(v('age'))),
              ],
            ),
            subLabel('   क) प्रेताचे वय :-'),
            pw.SizedBox(height: 6),

            // d) Date & Time of Death
            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              spacing: 2,
              runSpacing: 2,
              children: [
                subLabel('   ड) मृत्यूची तारीख वेळ :-                     '),
                pw.Text('Date : ', style: engStyle),
                underlineField(v('deathDate'), width: 90),
                pw.SizedBox(width: 15),
                pw.Text('Time : ', style: engStyle),
                underlineField(v('deathTime'), width: 90),
              ],
            ),
            subLabel('                                                तारीख                                   वेळ'),
            pw.SizedBox(height: 6),

            // 7) Position
            pw.Row(
              children: [
                pw.Text('7) Position of Dead Body                     :', style: engBold),
                pw.Expanded(child: underlineField(v('positionOfBody'))),
              ],
            ),
            subLabel('   प्रेताची स्थिती / अवस्था (जागा)'),
            multilineBox(v('positionOfBody2'), lines: 2),

            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('M.R.W', style: engStyle.copyWith(fontSize: 8, fontStyle: pw.FontStyle.italic)),
            ),
          ],
        ),
      ),
    );

    // ══════════════════════════════════════════════════════════════════════════
    // PAGE 2 — INQUEST MAIN
    // ══════════════════════════════════════════════════════════════════════════
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 22),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // 8) Name & Address
            pw.Row(
              children: [
                pw.Text('8) Name and Address of Dead Body             :', style: engBold),
                pw.Expanded(child: underlineField(v('nameAddressDeceased'))),
              ],
            ),
            subLabel('   प्रेताचे संपूर्ण नांव व पत्ता (माहित असल्यास)'),
            multilineBox(v('nameAddressDeceased2'), lines: 3),
            pw.SizedBox(height: 8),

            // 9) Description of injuries
            pw.Row(
              children: [
                pw.Text('9) Description Of injuries Found on Dead Body if any :', style: engBold),
                pw.Expanded(child: underlineField(v('injDescription'))),
              ],
            ),
            subLabel('   प्रेताचे अंगावर असल्यास त्याचे वर्णन :'),
            pw.SizedBox(height: 6),

            injuryRow('a) Head          :', 'अ) डोके        :', v('injHead')),
            injuryRow('b) Face          :', 'ब) चेहरा        :', v('injFace')),
            injuryRow('c) Neck          :', 'क) मान         :', v('injNeck')),
            injuryRow('d) Chest         :', 'ड) छाती        :', v('injChest')),
            injuryRow('e) Stomac        :', 'इ) पोट         :', v('injStomach')),
            injuryRow('f) Right Hand    :', 'फ) उजवा हात     :', v('injRightHand')),
            injuryRow('g) Left Hand     :', 'ग) डावा हात     :', v('injLeftHand')),
            injuryRow('h) Right Leg     :', 'ह) उजवा पाय     :', v('injRightLeg')),
            injuryRow('i) Left Leg      :', 'ऐ) डावा पाय     :', v('injLeftLeg')),
            injuryRow('j) Private part  :', 'जे) गुप्त भाग     :', v('injPrivatePart')),
            injuryRow('k) Back          :', 'के) पाठ        :', v('injBack')),

            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('M.R.W', style: engStyle.copyWith(fontSize: 8, fontStyle: pw.FontStyle.italic)),
            ),
          ],
        ),
      ),
    );

    // ══════════════════════════════════════════════════════════════════════════
    // PAGE 3 — INQUEST MAIN
    // ══════════════════════════════════════════════════════════════════════════
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 22),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // 10) Injuries Accidental/Violence
            pw.Text('10)   Injuries of Dead Body Caused By Accidental/Violence :', style: engBold),
            pw.Row(
              children: [
                pw.Text('Homicide / Other Burn / (Fair / Tejab) ', style: engBold.copyWith(fontSize: 8)),
                pw.Expanded(child: underlineField(v('injAccidentalViolence'))),
              ],
            ),
            subLabel('प्रेताचे अंगावरील जखमा अपघाताच्या घोक्यातील / इत्यादी'),
            subLabel('होण्यामुळे झाल्या'),
            pw.SizedBox(height: 6),

            // 11) Weapon / Means
            pw.Row(
              children: [
                pw.Text('11) Weapon / Means (if any)                  :', style: engBold),
                pw.Expanded(child: underlineField(v('weaponMeans'))),
              ],
            ),
            subLabel('जखमा केलेल्या हत्यार/ साधन असल्यास           :'),
            pw.SizedBox(height: 6),

            // 12) Cool/Warm
            pw.Row(
              children: [
                pw.Text('12) Dead Body Cool / Warm                    :', style: engBold),
                pw.Expanded(child: underlineField(v('bodyCoolWarm'))),
              ],
            ),
            subLabel('प्रेत थंड आहे/ गरम आहे.                       :'),
            pw.SizedBox(height: 6),

            // 13) Poisoning
            pw.Row(
              children: [
                pw.Text('13) Position Dead Body by Poisoning          :', style: engBold),
                pw.Expanded(child: underlineField(v('poisoningPosition'))),
              ],
            ),
            subLabel('प्रेताची स्थिती विष प्राशन केलेला असल्यास       :'),
            pw.SizedBox(height: 6),

            // 14) Fingerprint & Photo
            pw.Text('14) (a) Finger Print has taken by Doctor Not taken Reason', style: engBold),
            pw.Row(
              children: [
                pw.Text('(In case of unidentified Dead Body)          :', style: engStyle),
                pw.Expanded(child: underlineField(v('fingerprintReason'))),
              ],
            ),
            subLabel('अनोळखी प्रेताचे डॉक्टरांकडून बोटांचे ठसे घेतले/ नाही कारण :'),
            pw.SizedBox(height: 4),

            pw.Text('(b) Photo has taken/not taken reason (In case of an', style: engBold),
            pw.Row(
              children: [
                pw.Text('Identified Dead Body)                        :', style: engStyle),
                pw.Expanded(child: underlineField(v('photoReason'))),
              ],
            ),
            subLabel('अनोळखी प्रेताचे फोटो घेतले आहेत काय/नाही कारण :'),
            pw.SizedBox(height: 6),

            // 15) Dead Body sent to PM
            pw.Row(
              children: [
                pw.Text('15) Dead Body sent to P.M. / not reason: ', style: engBold),
                pw.Expanded(child: underlineField(v('sentToPMReason'))),
              ],
            ),
            subLabel('प्रेत (पोस्ट मार्टम) शविच्छेदन करीता पाठविले/ नाही कारण'),
            pw.SizedBox(height: 4),

            pw.Row(
              children: [
                pw.Text('(a) At which Hospital Dead Body sent to P.M.:', style: engBold),
                pw.Expanded(child: underlineField(v('hospitalName'))),
              ],
            ),
            subLabel('कोणत्या रूग्णालयात प्रेत पोस्ट मार्टूम करीता पाठविले :'),
            pw.SizedBox(height: 4),

            pw.Text('(b) With whom (Name No. and P.sm)            :', style: engBold),
            subLabel('कोणा बरोबर पाठविले (नांव व पो.स्टे.)'),
            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              spacing: 2,
              runSpacing: 2,
              children: [
                pw.Text('Name : ', style: engStyle),
                underlineField(v('sentOfficerName'), width: 160),
                pw.Text('B/No:-', style: engStyle),
                underlineField(v('sentOfficerBNo'), width: 70),
                pw.Text('P.S. : ', style: engStyle),
                underlineField(v('sentOfficerPs'), width: 100),
              ],
            ),
            subLabel('नांव                                        बक्कल नंबर                 पो.स्टे'),
            pw.SizedBox(height: 6),

            // 16) Opinion of Panchas
            pw.Row(
              children: [
                pw.Text('16) Opinion of Panchas and Police about Death: ', style: engBold),
                pw.Expanded(child: underlineField(v('opinionPanchas'))),
              ],
            ),
            subLabel('पंच व पोलीसांचा मृत्यूविषयी अभिप्राय'),
            multilineBox(v('opinionPanchas2'), lines: 4),
            pw.SizedBox(height: 6),

            // 17) More info
            pw.Row(
              children: [
                pw.Text('17) More information if any                 : ', style: engBold),
                pw.Expanded(child: underlineField(v('moreInfo'))),
              ],
            ),
            subLabel('अधिक माहिती असल्यास'),

            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('M.R.W', style: engStyle.copyWith(fontSize: 8, fontStyle: pw.FontStyle.italic)),
            ),
          ],
        ),
      ),
    );

    // ══════════════════════════════════════════════════════════════════════════
    // PAGE 4 — INQUEST MAIN
    // ══════════════════════════════════════════════════════════════════════════
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 22),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // 18) Date and Time of panchanama
            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              spacing: 2,
              runSpacing: 2,
              children: [
                pw.Text('18) Date and Time of panchanama    ', style: engBold),
                pw.Text('Date : -', style: engStyle),
                underlineField(v('panchanamaDate'), width: 80),
                pw.SizedBox(width: 10),
                pw.Text('Time:', style: engStyle),
                underlineField(v('panchanamaTime'), width: 55),
                pw.Text('  To ', style: engStyle),
                underlineField(v('panchanamaTimeTo'), width: 55),
              ],
            ),
            subLabel('    पंचनामा केल्याची               दिनांक : -                       वेळ : -                 ते'),
            pw.SizedBox(height: 10),

            // 19) Name of Panchas and Signature
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('19) Name of Panchas and Signature: -', style: engBold),
                      subLabel('    पंचनामा करणाऱ्या पंचांची नांवे : -'),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Signature: -', style: engBold),
                      subLabel('सह्या : -'),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 6),

            // Panch 1
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Row(
                    children: [
                      pw.Text('1) ', style: engBold),
                      pw.Expanded(child: multilineBox(v('panch1'), lines: 2)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Row(
                    children: [
                      pw.Text('1) ', style: engBold),
                      pw.Expanded(child: underlineField(v('panch1Sig'))),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 6),

            // Panch 2
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Row(
                    children: [
                      pw.Text('2) ', style: engBold),
                      pw.Expanded(child: multilineBox(v('panch2'), lines: 2)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Row(
                    children: [
                      pw.Text('2) ', style: engBold),
                      pw.Expanded(child: underlineField(v('panch2Sig'))),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 6),

            // Panch 3
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Row(
                    children: [
                      pw.Text('3) ', style: engBold),
                      pw.Expanded(child: multilineBox(v('panch3'), lines: 2)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Row(
                    children: [
                      pw.Text('3) ', style: engBold),
                      pw.Expanded(child: underlineField(v('panch3Sig'))),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // IO Signature Block
            pw.Row(
              children: [
                pw.Spacer(),
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Signature of Investigation Officer', style: engBold),
                      subLabel('तपासणी करणाऱ्या अधिकाऱ्यांची नांव व सह्या'),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text('Name: ', style: engStyle),
                          pw.Expanded(child: underlineField(v('ioName'))),
                        ],
                      ),
                      subLabel('नांव'),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text('Rank: ', style: engStyle),
                          underlineField(v('ioRank'), width: 80),
                          pw.SizedBox(width: 4),
                          pw.Text('Number if any:', style: engStyle),
                          pw.Expanded(child: underlineField(v('ioNo'))),
                        ],
                      ),
                      subLabel('पद                   बक्कल नंबर'),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text('Posting and Address:', style: engStyle),
                          pw.Expanded(child: underlineField(v('ioPosting'))),
                        ],
                      ),
                      subLabel('नेमणूक व पत्ता'),
                    ],
                  ),
                ),
              ],
            ),

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
  // ADDITIONAL SECTIONS (Civil Surgeon, Vinanti Arj, Summons, 14-Kalmi, etc.)
  // ══════════════════════════════════════════════════════════════════════════
  if (showsSection('Civil Surgeon PM Report')) {
    pw.Widget csPdfRow(String qNum, String qTextEn, String qTextMr, pw.Widget answerWidget) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3.5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 11,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('$qNum $qTextEn', style: engBold.copyWith(fontSize: 7.5)),
                  pw.SizedBox(height: 0.5),
                  pw.Text(qTextMr, style: mrStyle.copyWith(fontSize: 6.5)),
                ],
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              flex: 12,
              child: answerWidget,
            ),
          ],
        ),
      );
    }

    pw.Widget csPdfDateTimeAnswer(String dateVal, String timeVal) {
      return pw.Wrap(
        crossAxisAlignment: pw.WrapCrossAlignment.center,
        spacing: 2,
        runSpacing: 2,
        children: [
          pw.Text(':- दिनांक ', style: mrBold.copyWith(fontSize: 7)),
          underlineField(dateVal, width: 60),
          pw.Text(' रोजी ', style: mrBold.copyWith(fontSize: 7)),
          underlineField(timeVal, width: 50),
          pw.Text(' वाजता.', style: mrBold.copyWith(fontSize: 7)),
        ],
      );
    }

    // Page 5
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'नमुना सी-६१७ स्थानांतरण/सं-२७१-कालगुण-२७११-२,००,०००(पुस्तके ४ पो.स्टे.का. ४४\n(G.R.G.D No.352 dt 21-5-12 P.M. 35 M.C in MR vide L.No.L.89-B dt.18-4-69 form I.G of Police, M.S.Bombay)',
                    textAlign: pw.TextAlign.center,
                    style: mrStyle.copyWith(fontSize: 6),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'शवविच्छेदन परिक्षेसाठी पाठविलेल्या प्रेताबरोबर जिल्हा शल्यचिकित्सकाकडे पाठवायचा पोलीस अहवाल',
                    textAlign: pw.TextAlign.center,
                    style: mrBold.copyWith(fontSize: 9),
                  ),
                  pw.Text(
                    'Police Report to be forwarded to the Civil Surgeon with Dead Bodies sent For Post-mortem examination',
                    textAlign: pw.TextAlign.center,
                    style: engBold.copyWith(fontSize: 8),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Divider(color: PdfColors.black, thickness: 0.8),
            pw.Row(
              children: [
                pw.Expanded(
                  flex: 11,
                  child: pw.Column(
                    children: [
                      pw.Text('प्रश्न', style: mrBold.copyWith(fontSize: 8)),
                      pw.Text('Question', style: engBold.copyWith(fontSize: 8)),
                    ],
                  ),
                ),
                pw.Container(width: 0.8, height: 20, color: PdfColors.grey500),
                pw.Expanded(
                  flex: 12,
                  child: pw.Column(
                    children: [
                      pw.Text('उत्तर', style: mrBold.copyWith(fontSize: 8)),
                      pw.Text('Answer', style: engBold.copyWith(fontSize: 8)),
                    ],
                  ),
                ),
              ],
            ),
            pw.Divider(color: PdfColors.black, thickness: 0.8),
            pw.SizedBox(height: 4),

            csPdfRow('1)', 'Name of Deceased', 'मृत व्यक्तीचे नांव', underlineField(v('csNameDeceased'))),
            csPdfRow('2)', 'Age', 'वय', underlineField(v('csAge'))),
            csPdfRow('3)', 'Married, Single, Widow or Widower', 'विवाहीत, अविवाहीत, विधवा किंवा विधूर', underlineField(v('csMaritalStatus'))),
            csPdfRow('4)', 'Date and hour of death', 'मृत्युचा दिनांक आणि वेळ', csPdfDateTimeAnswer(v('csDeathDate'), v('csDeathTime'))),
            csPdfRow('5)', 'Describe condition of body when found, Position, Surroundings and any marks of Violence, bloodstains or vomited matters Which may have existed?', 'प्रेत सापडले त्यावेळची अवस्था, स्थिती, भोवतालची परिस्थिती आणि उपलब्ध असलेल्या मारहाणीच्या खुणा रक्ताचे डाग किंवा वांतीबरोबर पडलेले पदार्थ यांचा तपशील दयावा.', multilineBox(v('csBodyCondition'), lines: 3)),
            csPdfRow('6)', 'Day and hour on which the body was seen by the officer making the report', 'अहवाल पाठविणाऱ्या अधिकाऱ्याने प्रेत पाहिल्याचा दिनांक व वेळ (तास)', csPdfDateTimeAnswer(v('csSeenDate'), v('csSeenTime'))),
            csPdfRow('7)', 'Was the body cold or warm when found?', 'प्रेत सापडले त्यावेळी थंड होते कि गरम', underlineField(v('csBodyColdWarm'))),
            csPdfRow('8)', 'Had the deceased suffered from recent Illness? If so, what? State duration and Describe the illness as far as Known.', 'मृत व्यक्तीस अलिकडे काही आजार झाला होता काय असल्यास कोणता.', multilineBox(v('csRecentIllness'), lines: 2)),
            csPdfRow('9)', 'Had deceased suffered from accident Injury or if so, describe it.', 'मृत व्यक्तीस कोणत्याही प्रकारचा अपघात, दुखापत किंवा मारहाण झाली होती काय ?', multilineBox(v('csAccidentInjury'), lines: 2)),
            csPdfRow('10)', 'If clothes, weapons, vomited matter of Other articles are forwarded, State why this Is done and what relation they bear to the Case? Describe them.', 'कपडे, हत्यारे, वांतीबरोबर पडलेले पदार्थ किंवा इतर वस्तु पाठविल्या असल्यास तसे का केले व त्याचा प्रकरणाशी संबंध आहे ते लिहावे, त्याचा तपशील दयावा.', multilineBox(v('csArticlesForwarded'), lines: 3)),
            csPdfRow('11)', 'Is death supposed to have been due to Natural causes, accident, suicide or homicide? State briefly and plainly, any suspicions That may exist and why?', 'मृत्यु नैसर्गिक कारणे, अपघात, आत्महत्या किंवा खून यापैकी कशामुळे घडला असे वाटते. काही संशय असल्यास ते थोडक्यात स्पष्टपणे नमुद करावे व कारणे दयावे.', multilineBox(v('csDeathReason'), lines: 3)),

            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('M.R.W', style: engStyle.copyWith(fontSize: 7, fontStyle: pw.FontStyle.italic)),
            ),
          ],
        ),
      ),
    );

    // Page 6
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Divider(color: PdfColors.black, thickness: 0.8),
            pw.Row(
              children: [
                pw.Expanded(
                  flex: 11,
                  child: pw.Column(
                    children: [
                      pw.Text('प्रश्न', style: mrBold.copyWith(fontSize: 8)),
                      pw.Text('Question', style: engBold.copyWith(fontSize: 8)),
                    ],
                  ),
                ),
                pw.Container(width: 0.8, height: 20, color: PdfColors.grey500),
                pw.Expanded(
                  flex: 12,
                  child: pw.Column(
                    children: [
                      pw.Text('उत्तर', style: mrBold.copyWith(fontSize: 8)),
                      pw.Text('Answer', style: engBold.copyWith(fontSize: 8)),
                    ],
                  ),
                ),
              ],
            ),
            pw.Divider(color: PdfColors.black, thickness: 0.8),
            pw.SizedBox(height: 4),

            csPdfRow('12)', 'Is there suspicion of poisoning? If, so, is any particular poison supposed to have been employed? Mention any symptoms of poisoning which are reported to have existed during life and any appearances pointing to poisoning observed after death.', 'विष प्रयोग केल्याचा संशय आहे, असल्यास विशिष्ट विषाचा वापर केला आहे वाटते काय? मृत व्यक्ती जिवंत असतांना विषबाधा झाल्याची लक्षणे दिसून आल्याचे कळविण्यात आले होते काय, व विषाचे बाबत मृत्यु नंतर दिसून आलेली चिन्हे नमुद करावी.', multilineBox(v('csPoisonSuspicion'), lines: 4)),
            csPdfRow('13)', 'In the case of a woman, is she supposed to be pregnant of to have been recently delivered ?', 'स्त्रीच्या बाबतीत ती गरोदर असावी किंवा अलीकडे प्रसुती झाली असावी असे वाटते काय ?', multilineBox(v('csWomanPregnancy'), lines: 2)),
            csPdfRow('14)', 'Is abortion or attempted abortion known or suspected? And if the former, has the focus been found?', 'गर्भपात केला किंवा गर्भपात करण्याचा प्रयत्न केला या विषयी माहिती किंवा संशय आहे काय, गर्भपात केला असल्यास गर्भ सापडला काय.', multilineBox(v('csAbortion'), lines: 2)),
            csPdfRow('15)', 'State the finding of the Jury (if any) and mention any reasons they may have given for their findings.', 'ज्युरीचे निष्कर्ष असल्यास नमुद करावेत व निष्कर्षा बाबत त्यांनी काही कारणे दिली असल्यास त्याचा निर्देश करावा.', multilineBox(v('csJuryFindings'), lines: 2)),
            csPdfRow('16)', 'Remarks. Under this head the Police Officer should give any information not included in the above question which he may consider likely to assist the Civil Surgeon informing an opinion of the cause of death.', 'शेरा वरील प्रश्नात समाविष्ट न झालेली परंतु पोलीस अधिकाऱ्यांच्या मते जिल्हा शल्यचिकित्सकांना मृत्युच्या कारणाविषयी आपले मत बनविण्यास सहाय्यभूत होण्याचा संभव आहे अशी कोणत्याही प्रकारची माहिती या शीर्षका खाली दयावी.', multilineBox(v('csRemarks'), lines: 4)),

            pw.SizedBox(height: 6),
            multilineBox(v('csExtraNotes'), lines: 1),
            pw.SizedBox(height: 14),

            // IO Signature Block
            pw.Row(
              children: [
                pw.Spacer(),
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      subLabel('तपासणी करणाऱ्या अधिकाऱ्यांची नांव व सही'),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        children: [
                          pw.Text('Name: ', style: engStyle),
                          pw.Expanded(child: underlineField(v('csIoName'))),
                        ],
                      ),
                      subLabel('नांव'),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        children: [
                          pw.Text('Rank: ', style: engStyle),
                          underlineField(v('csIoRank'), width: 70),
                          pw.SizedBox(width: 4),
                          pw.Text('Number if any:', style: engStyle),
                          pw.Expanded(child: underlineField(v('csIoNo'))),
                        ],
                      ),
                      subLabel('पद                   बक्कल नंबर'),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        children: [
                          pw.Text('Posting and Address:', style: engStyle),
                          pw.Expanded(child: underlineField(v('csIoPosting'))),
                        ],
                      ),
                      subLabel('नेमणूक व पत्ता'),
                    ],
                  ),
                ),
              ],
            ),

            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('M.R.W', style: engStyle.copyWith(fontSize: 7, fontStyle: pw.FontStyle.italic)),
            ),
          ],
        ),
      ),
    );
  }

  if (showsSection('Vinanti Arj')) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Title
            pw.Center(
              child: pw.Text(
                'विनंती अर्ज',
                style: mrBold.copyWith(fontSize: 12),
              ),
            ),
            pw.SizedBox(height: 8),

            // Top Right: PS / Date
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Wrap(
                      crossAxisAlignment: pw.WrapCrossAlignment.center,
                      children: [
                        pw.Text('पोलीस स्टेशन', style: mrBold.copyWith(fontSize: 8.5)),
                        underlineField(v('reqPs'), width: 100),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Wrap(
                      crossAxisAlignment: pw.WrapCrossAlignment.center,
                      children: [
                        pw.Text('दिनांक :- ', style: mrBold.copyWith(fontSize: 8.5)),
                        underlineField(v('reqDate'), width: 80),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),

            // Recipient (प्रति)
            pw.Text('प्रति,', style: mrBold.copyWith(fontSize: 9)),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 24.0),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('मा. न्यायवैद्यक शास्त्र विभाग प्रमुख', style: mrBold.copyWith(fontSize: 9)),
                  pw.SizedBox(height: 2),
                  underlineField(v('reqTo'), width: 220),
                  pw.SizedBox(height: 2),
                  underlineField(v('reqTo2'), width: 220),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // From (पासुन)
            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              children: [
                pw.Text('पासुन  :-    पोलीस स्टेशन', style: mrBold.copyWith(fontSize: 8.5)),
                underlineField(v('reqFromPs'), width: 110),
                pw.Text('  जिल्हा यवतमाळ.', style: mrBold.copyWith(fontSize: 8.5)),
              ],
            ),
            pw.SizedBox(height: 12),

            // Subject (विषय)
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('विषय  :-    ', style: mrBold.copyWith(fontSize: 8.5)),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Wrap(
                        crossAxisAlignment: pw.WrapCrossAlignment.center,
                        children: [
                          pw.Text('मृतक नामे ', style: mrBold.copyWith(fontSize: 8.5)),
                          underlineField(v('reqSubjectName'), width: 280),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Wrap(
                        crossAxisAlignment: pw.WrapCrossAlignment.center,
                        children: [
                          pw.Text('पो.स्टे.', style: mrBold.copyWith(fontSize: 8.5)),
                          underlineField(v('reqSubjectPs'), width: 80),
                          pw.Text('  ता-', style: mrBold.copyWith(fontSize: 8.5)),
                          underlineField(v('reqSubjectTa'), width: 70),
                          pw.Text('  जिल्हा यवतमाळ हिचे/ ह्यांचे प्रेताचे पि.एम', style: mrBold.copyWith(fontSize: 8.5)),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text('करून आपला अभिप्राय मिळणेबाबत.', style: mrBold.copyWith(fontSize: 8.5)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Center(child: pw.Text('० ० ० ०', style: mrStyle.copyWith(letterSpacing: 4, fontSize: 8))),
            pw.SizedBox(height: 6),

            // Body (महोदय)
            pw.Text('महोदय,', style: mrBold.copyWith(fontSize: 8.5)),
            pw.SizedBox(height: 4),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 12.0),
              child: pw.Wrap(
                crossAxisAlignment: pw.WrapCrossAlignment.center,
                runSpacing: 4,
                spacing: 2,
                children: [
                  pw.Text('सविनय सेवेशी सादर आहे की, आज दिनांक ', style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqMargDate'), width: 65),
                  pw.Text(' रोजी ', style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqMargTime'), width: 50),
                  pw.Text(' वाजता पोलीस स्टेशन ', style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqMargPs'), width: 90),
                  pw.Text(' मर्ग/ स्टेशन डायरी क्र.', style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqMargDiaryNo'), width: 55),
                  pw.Text('/२०', style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqMargYear'), width: 35),
                  pw.Text(' कलम १९४ बी.एन.एस.एस २०२३ चा मर्ग दाखल झाला असुन यातील मृतक नामे ', style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqMargName'), width: 190),
                  pw.Text(' पो.स्टे.', style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqSubjectPs'), width: 80),
                  pw.Text(' ता-', style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqMargTa'), width: 70),
                  pw.Text(' जिल्हा यवतमाळ ही/ह्या ', style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqHospitalName'), width: 140),
                  pw.Text(' येथे दिनांक ', style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqAdmitDate'), width: 65),
                  pw.Text(' रोजी ', style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqAdmitTime'), width: 50),
                  pw.Text(' वाजता भरती झाला असुन औषधोपचारा दरम्यान/ गळफास लावुन/ विष प्राशन करून/अपघात/ ', style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqReasonDetails'), width: 160),
                  pw.Text(' दिनांक ', style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqDeathDate'), width: 65),
                  pw.Text(' रोजी ', style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqDeathTime'), width: 50),
                  pw.Text(' वाजता मरण पावला आहे.', style: mrStyle.copyWith(fontSize: 8)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 12.0),
              child: pw.Text(
                'तरी सदर मृतकाचे मरणाचे निश्चीत कारण समजुन येणेकरीता सदर मृतकाचे प्रेताचे पी.एम करून आपला सविस्तर अभिप्राय मिळणेस विनंती आहे.',
                style: mrStyle.copyWith(fontSize: 8),
              ),
            ),
            pw.SizedBox(height: 16),

            // Bottom: Attachments on left | Signature on right
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left: सहपत्र & हस्ते
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('सहपत्र : प्रश्नोत्तर फॉर्म', style: mrBold.copyWith(fontSize: 8)),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 30.0),
                        child: pw.Text('इंक्वेस्ट पंचनामा', style: mrBold.copyWith(fontSize: 8)),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Wrap(
                        crossAxisAlignment: pw.WrapCrossAlignment.center,
                        children: [
                          pw.Text('हस्ते : ', style: mrBold.copyWith(fontSize: 8)),
                          underlineField(v('reqHasteName'), width: 100),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Wrap(
                        crossAxisAlignment: pw.WrapCrossAlignment.center,
                        children: [
                          pw.Text('पो.स्टे. : ', style: mrBold.copyWith(fontSize: 8)),
                          underlineField(v('reqHastePs'), width: 100),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                // Right: IO Signature
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('तपासी अधिकारी नांव /सही शिक्या', style: mrBold.copyWith(fontSize: 8)),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text('Name: ', style: engStyle),
                          pw.Expanded(child: underlineField(v('reqIoName'))),
                        ],
                      ),
                      subLabel('नांव'),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        children: [
                          pw.Text('Rank: ', style: engStyle),
                          underlineField(v('reqIoRank'), width: 70),
                          pw.SizedBox(width: 4),
                          pw.Text('No:', style: engStyle),
                          pw.Expanded(child: underlineField(v('reqIoNo'))),
                        ],
                      ),
                      subLabel('पद                   बक्कल नंबर'),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        children: [
                          pw.Text('Posting:', style: engStyle),
                          pw.Expanded(child: underlineField(v('reqIoPosting'))),
                        ],
                      ),
                      subLabel('नेमणूक व पत्ता'),
                    ],
                  ),
                ),
              ],
            ),

            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('M.R.W', style: engStyle.copyWith(fontSize: 7, fontStyle: pw.FontStyle.italic)),
            ),
          ],
        ),
      ),
    );
  }

  if (showsSection('Relative Summons 179')) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Title
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'नातेवाईकांना समन्स',
                    style: mrBold.copyWith(fontSize: 12),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '(कलम १७९ भारतीय नागरिक सुरक्षा संहिता २०२३ अन्वये)',
                    style: mrBold.copyWith(fontSize: 9),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Top Right: PS / Camp / Date
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Wrap(
                      crossAxisAlignment: pw.WrapCrossAlignment.center,
                      children: [
                        pw.Text('पोलीस स्टेशन', style: mrBold.copyWith(fontSize: 8.5)),
                        underlineField(v('relPs'), width: 100),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Wrap(
                      crossAxisAlignment: pw.WrapCrossAlignment.center,
                      children: [
                        pw.Text('कॅम्प :- ', style: mrBold.copyWith(fontSize: 8.5)),
                        underlineField(v('relCamp'), width: 110),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Wrap(
                      crossAxisAlignment: pw.WrapCrossAlignment.center,
                      children: [
                        pw.Text('दिनांक :- ', style: mrBold.copyWith(fontSize: 8.5)),
                        underlineField(v('relDate'), width: 80),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Recipient (नांव :-)
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('नांव  :-   ', style: mrBold.copyWith(fontSize: 9)),
                pw.Expanded(
                  child: multilineBox(v('relToName'), lines: 4),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Center(child: pw.Text('० ० ० ०', style: mrStyle.copyWith(letterSpacing: 4, fontSize: 8))),
            pw.SizedBox(height: 8),

            // Body Paragraph
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 8.0),
              child: pw.Wrap(
                crossAxisAlignment: pw.WrapCrossAlignment.center,
                runSpacing: 4,
                spacing: 2,
                children: [
                  pw.Text('आपणास या समन्सव्दारे कळविण्यात येते की, आम्ही ', style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('relWeName'), width: 150),
                  pw.Text(' पोलीस स्टेशन ', style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('relPsName'), width: 100),
                  pw.Text(' येथील अप/ मर्ग/ ठाणे दैनंदिनी क्रमांक ', style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('relCrDiaryNo'), width: 55),
                  pw.Text('/२०', style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('relCrYear'), width: 35),
                  pw.Text(' कलम ', style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('relActSec'), width: 120),
                  pw.Text(' मधील मृतक नामे ', style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('relDeceasedName'), width: 180),
                  pw.Text(' ता-', style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('relTa'), width: 75),
                  pw.Text(' जिल्हा ', style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('relDist'), width: 75),
                  pw.Text(' यांचे प्रेताचा इंन्क्वेस्ट पंचनामा करणार आहो. करीता आपण प्रेत ओळखुन देवून मृतकाचे नातेवाईक या नात्याने पंचनाम्याची कार्यवाही पूर्ण होईपर्यंत आमचे सोबत हजर राहावे.', style: mrStyle.copyWith(fontSize: 8.5)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Bottom: सही on Left | IO Signature on Right
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left: सही
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('सही', style: mrBold.copyWith(fontSize: 9)),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        children: [
                          pw.Text('१) ', style: mrBold.copyWith(fontSize: 8.5)),
                          pw.Expanded(child: underlineField(v('relSig1'))),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text('२) ', style: mrBold.copyWith(fontSize: 8.5)),
                          pw.Expanded(child: underlineField(v('relSig2'))),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text('३) ', style: mrBold.copyWith(fontSize: 8.5)),
                          pw.Expanded(child: underlineField(v('relSig3'))),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text('४) ', style: mrBold.copyWith(fontSize: 8.5)),
                          pw.Expanded(child: underlineField(v('relSig4'))),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                // Right: IO Signature
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('तपासी अधिकारी नांव / सही शिक्या', style: mrBold.copyWith(fontSize: 8.5)),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text('Name: ', style: engStyle),
                          pw.Expanded(child: underlineField(v('relIoName'))),
                        ],
                      ),
                      subLabel('नांव'),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        children: [
                          pw.Text('Rank: ', style: engStyle),
                          underlineField(v('relIoRank'), width: 70),
                          pw.SizedBox(width: 4),
                          pw.Text('Number if any:', style: engStyle),
                          pw.Expanded(child: underlineField(v('relIoNo'))),
                        ],
                      ),
                      subLabel('पद                   बक्कल नंबर'),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        children: [
                          pw.Text('Posting and Address:', style: engStyle),
                          pw.Expanded(child: underlineField(v('relIoPosting'))),
                        ],
                      ),
                      subLabel('नेमणूक व पत्ता'),
                    ],
                  ),
                ),
              ],
            ),

            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('M.R.W', style: engStyle.copyWith(fontSize: 7, fontStyle: pw.FontStyle.italic)),
            ),
          ],
        ),
      ),
    );
  }

  if (showsSection('Pancha Summons 195')) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Title
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'पंचांना समन्स',
                    style: mrBold.copyWith(fontSize: 12),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '(कलम १९५ भारतीय नागरिक सुरक्षा संहिता २०२३ अन्वये)',
                    style: mrBold.copyWith(fontSize: 9),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Top Right: PS / Camp / Date
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Wrap(
                      crossAxisAlignment: pw.WrapCrossAlignment.center,
                      children: [
                        pw.Text('पोलीस स्टेशन', style: mrBold.copyWith(fontSize: 8.5)),
                        underlineField(v('panPs'), width: 100),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Wrap(
                      crossAxisAlignment: pw.WrapCrossAlignment.center,
                      children: [
                        pw.Text('कॅम्प :- ', style: mrBold.copyWith(fontSize: 8.5)),
                        underlineField(v('panCamp'), width: 110),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Wrap(
                      crossAxisAlignment: pw.WrapCrossAlignment.center,
                      children: [
                        pw.Text('दिनांक :- ', style: mrBold.copyWith(fontSize: 8.5)),
                        underlineField(v('panDate'), width: 80),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // Recipient (नांव :-)
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('नांव  :-   ', style: mrBold.copyWith(fontSize: 9)),
                pw.Expanded(
                  child: multilineBox(v('panToName'), lines: 4),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Center(child: pw.Text('० ० ० ०', style: mrStyle.copyWith(letterSpacing: 4, fontSize: 8))),
            pw.SizedBox(height: 8),

            // Body Paragraph
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 8.0),
              child: pw.Wrap(
                crossAxisAlignment: pw.WrapCrossAlignment.center,
                runSpacing: 4,
                spacing: 2,
                children: [
                  pw.Text('आपणास या समन्सव्दारे कळविण्यात येते की, आम्ही ', style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('panWeName'), width: 150),
                  pw.Text(' पोलीस स्टेशन ', style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('panPsName'), width: 100),
                  pw.Text(' येथील अप/ मर्ग/ ठाणे दैनंदिनी क्रमांक ', style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('panCrDiaryNo'), width: 55),
                  pw.Text('/२०', style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('panCrYear'), width: 35),
                  pw.Text(' कलम ', style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('panActSec'), width: 120),
                  pw.Text(' मधील मृतक नामे ', style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('panDeceasedName'), width: 180),
                  pw.Text(' ता-', style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('panTa'), width: 75),
                  pw.Text(' जिल्हा ', style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('panDist'), width: 75),
                  pw.Text(' यांचे प्रेताचा इंन्क्वेस्ट पंचनामा करणार आहो. करीता आपण पंचनाम्याची कार्यवाही पूर्ण होईपर्यंत पंच म्हणुन आमचे सोबत हजर राहावे.', style: mrStyle.copyWith(fontSize: 8.5)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Bottom: पंच सही on Left | IO Signature on Right
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left: पंच सही
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('पंच सही', style: mrBold.copyWith(fontSize: 9)),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        children: [
                          pw.Text('१) ', style: mrBold.copyWith(fontSize: 8.5)),
                          pw.Expanded(child: underlineField(v('panSig1'))),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text('२) ', style: mrBold.copyWith(fontSize: 8.5)),
                          pw.Expanded(child: underlineField(v('panSig2'))),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text('३) ', style: mrBold.copyWith(fontSize: 8.5)),
                          pw.Expanded(child: underlineField(v('panSig3'))),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text('४) ', style: mrBold.copyWith(fontSize: 8.5)),
                          pw.Expanded(child: underlineField(v('panSig4'))),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 20),
                // Right: IO Signature
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('तपासी अधिकारी नांव / सही शिक्या', style: mrBold.copyWith(fontSize: 8.5)),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        children: [
                          pw.Text('Name: ', style: engStyle),
                          pw.Expanded(child: underlineField(v('panIoName'))),
                        ],
                      ),
                      subLabel('नांव'),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        children: [
                          pw.Text('Rank: ', style: engStyle),
                          underlineField(v('panIoRank'), width: 70),
                          pw.SizedBox(width: 4),
                          pw.Text('Number if any:', style: engStyle),
                          pw.Expanded(child: underlineField(v('panIoNo'))),
                        ],
                      ),
                      subLabel('पद                   बक्कल नंबर'),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        children: [
                          pw.Text('Posting and Address:', style: engStyle),
                          pw.Expanded(child: underlineField(v('panIoPosting'))),
                        ],
                      ),
                      subLabel('नेमणूक व पत्ता'),
                    ],
                  ),
                ),
              ],
            ),

            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('M.R.W', style: engStyle.copyWith(fontSize: 7, fontStyle: pw.FontStyle.italic)),
            ),
          ],
        ),
      ),
    );
  }

  if (showsSection('Dead Body Handover')) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 22),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('PRET TABA PAVATI (DEAD BODY HANDOVER RECEIPT)', style: engBold.copyWith(fontSize: 11)),
                  pw.Text('प्रेत ताबा पावती', style: mrBold.copyWith(fontSize: 10)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Row(children: [pw.Text('Police Station: ', style: engBold), underlineField(v('ptpPs'), width: 120), pw.SizedBox(width: 12), pw.Text('Date: ', style: engBold), pw.Expanded(child: underlineField(v('ptpDate')))]),
            pw.SizedBox(height: 4),
            pw.Row(children: [pw.Text('Receiver Name: ', style: engBold), pw.Expanded(child: underlineField(v('ptpReceiverName')))]),
            pw.SizedBox(height: 4),
            pw.Row(children: [pw.Text('R/o: ', style: engBold), underlineField(v('ptpReceiverRa'), width: 120), pw.SizedBox(width: 8), pw.Text('Dist: ', style: engBold), underlineField(v('ptpReceiverDist'), width: 80), pw.SizedBox(width: 8), pw.Text('Mo: ', style: engBold), pw.Expanded(child: underlineField(v('ptpMoNo')))]),
            pw.SizedBox(height: 4),
            pw.Row(children: [pw.Text('Deceased Name: ', style: engBold), pw.Expanded(child: underlineField(v('ptpDeceasedName')))]),
            pw.SizedBox(height: 12),
            pw.Row(children: [pw.Text('Signature of Receiver: ', style: engBold), pw.Expanded(child: underlineField(v('ptpReceiverSig')))]),
          ],
        ),
      ),
    );
  }

  if (showsSection('Duty Pass')) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 22),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('DUTY PASS (FOR POLICE ACCOMPANYING BODY)', style: engBold.copyWith(fontSize: 11)),
                  pw.Text('ड्युटी पास (शवासोबत जाणाऱ्या अंमलदारासाठी)', style: mrBold.copyWith(fontSize: 10)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Row(children: [pw.Text('Police Station: ', style: engBold), underlineField(v('dpPs'), width: 120), pw.SizedBox(width: 12), pw.Text('Date: ', style: engBold), pw.Expanded(child: underlineField(v('dpDate')))]),
            pw.SizedBox(height: 4),
            pw.Row(children: [pw.Text('Amaldaar Name: ', style: engBold), pw.Expanded(child: underlineField(v('dpAmaldaarName')))]),
            pw.SizedBox(height: 4),
            pw.Row(children: [pw.Text('Duty PS: ', style: engBold), underlineField(v('dpDutyPs'), width: 120), pw.SizedBox(width: 10), pw.Text('Date & Time: ', style: engBold), pw.Expanded(child: underlineField(v('dpDutyDateTime')))]),
            pw.SizedBox(height: 4),
            pw.Row(children: [pw.Text('Marg No: ', style: engBold), underlineField(v('dpMargNo'), width: 80), pw.SizedBox(width: 8), pw.Text('Year: 20', style: engBold), underlineField(v('dpMargYear'), width: 40), pw.SizedBox(width: 8), pw.Text('Section: ', style: engBold), pw.Expanded(child: underlineField(v('dpKalam')))]),
            pw.SizedBox(height: 4),
            pw.Row(children: [pw.Text('Deceased Name: ', style: engBold), pw.Expanded(child: underlineField(v('dpDeceasedName')))]),
            pw.SizedBox(height: 12),
            pw.Row(children: [pw.Text('Amaldaar Signature: ', style: engBold), pw.Expanded(child: underlineField(v('dpAmaldaarSig')))]),
          ],
        ),
      ),
    );
  }

  return pdf.save();
}
