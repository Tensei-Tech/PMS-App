import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../widgets/form_section_utils.dart';
import 'form_image_pdf_helper.dart';

Future<void> previewInquestPanchanamaPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final active = doc['formSection']?.toString().trim();
  if (active == 'Vinanti Arj') {
    await FormImagePdfHelper.previewImageBasedPdf(
      context,
      fileName: 'Vinanti_Arj_${DateTime.now().millisecondsSinceEpoch}.pdf',
      pages: [_buildVinantiArjWidget(doc)],
      fallbackPdfGenerator: () => generateInquestPanchanamaPdf(doc),
    );
    return;
  }
  if (active == 'Relative Summons 179') {
    await FormImagePdfHelper.previewImageBasedPdf(
      context,
      fileName: 'Relative_Summons_${DateTime.now().millisecondsSinceEpoch}.pdf',
      pages: [_buildRelativeSummonsWidget(doc)],
      fallbackPdfGenerator: () => generateInquestPanchanamaPdf(doc),
    );
    return;
  }
  if (active == 'Pancha Summons 195') {
    await FormImagePdfHelper.previewImageBasedPdf(
      context,
      fileName: 'Pancha_Summons_${DateTime.now().millisecondsSinceEpoch}.pdf',
      pages: [_buildPanchaSummonsWidget(doc)],
      fallbackPdfGenerator: () => generateInquestPanchanamaPdf(doc),
    );
    return;
  }
  if (active == 'Civil Surgeon PM Report' || active == '14 Kalmi Form') {
    await FormImagePdfHelper.previewImageBasedPdf(
      context,
      fileName: 'Medical_Officer_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      pages: [_buildCivilSurgeonPg1Widget(doc), _buildCivilSurgeonPg2Widget(doc)],
      fallbackPdfGenerator: () => generateInquestPanchanamaPdf(doc),
    );
    return;
  }
  if (active == 'Dead Body Handover') {
    await FormImagePdfHelper.previewImageBasedPdf(
      context,
      fileName: 'Dead_Body_Handover_${DateTime.now().millisecondsSinceEpoch}.pdf',
      pages: [_buildDeadBodyHandoverWidget(doc)],
      fallbackPdfGenerator: () => generateInquestPanchanamaPdf(doc),
    );
    return;
  }
  if (active == 'Duty Pass') {
    await FormImagePdfHelper.previewImageBasedPdf(
      context,
      fileName: 'Duty_Pass_${DateTime.now().millisecondsSinceEpoch}.pdf',
      pages: [_buildDutyPassWidget(doc)],
      fallbackPdfGenerator: () => generateInquestPanchanamaPdf(doc),
    );
    return;
  }
  if (active == 'Marananveshan Panchanama') {
    await FormImagePdfHelper.previewImageBasedPdf(
      context,
      fileName: 'Marananveshan_Panchanama_${DateTime.now().millisecondsSinceEpoch}.pdf',
      pages: [_buildMarananveshanPg1Widget(doc), _buildMarananveshanPg2Widget(doc)],
      fallbackPdfGenerator: () => generateInquestPanchanamaPdf(doc),
    );
    return;
  }
  if (active == 'Exhumation Panchanama') {
    await FormImagePdfHelper.previewImageBasedPdf(
      context,
      fileName: 'Exhumation_Panchanama_${DateTime.now().millisecondsSinceEpoch}.pdf',
      pages: [
        _buildInquestMainPg1Widget(doc, isExhumation: true),
        _buildInquestMainPg2Widget(doc),
        _buildInquestMainPg3Widget(doc),
        _buildInquestMainPg4Widget(doc),
      ],
      fallbackPdfGenerator: () => generateInquestPanchanamaPdf(doc),
    );
    return;
  }

  // Default / 'Inquest Main'
  await FormImagePdfHelper.previewImageBasedPdf(
    context,
    fileName: 'Inquest_Panchanama_${DateTime.now().millisecondsSinceEpoch}.pdf',
    pages: [
      _buildInquestMainPg1Widget(doc, isExhumation: false),
      _buildInquestMainPg2Widget(doc),
      _buildInquestMainPg3Widget(doc),
      _buildInquestMainPg4Widget(doc),
    ],
    fallbackPdfGenerator: () => generateInquestPanchanamaPdf(doc),
  );
}

Future<Uint8List> generateInquestPanchanamaPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();

  final loraRegular = await PdfGoogleFonts.loraRegular();
  final loraBold = await PdfGoogleFonts.loraBold();
  final devanagariRegular = await PdfGoogleFonts.notoSansDevanagariRegular();
  final devanagariBold = await PdfGoogleFonts.notoSansDevanagariBold();

  final engStyle = pw.TextStyle(font: loraRegular, fontSize: 8.5);
  final engBold = pw.TextStyle(
      font: loraBold, fontSize: 8.5, fontWeight: pw.FontWeight.bold);
  final mrStyle = pw.TextStyle(font: devanagariRegular, fontSize: 7.5);
  final mrBold = pw.TextStyle(
      font: devanagariBold, fontSize: 7.5, fontWeight: pw.FontWeight.bold);

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
        border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.black, width: 0.6)),
      ),
      child: pw.Text(
        text.isEmpty ? ' ' : text,
        style: pw.TextStyle(
            font: devanagariBold, fontSize: 8, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget multilineBox(String text, {int lines = 2}) {
    return pw.Container(
      width: double.infinity,
      constraints: pw.BoxConstraints(minHeight: lines * 12.0),
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.black, width: 0.6)),
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
                  pw.Text('INQUEST PANCHANAMA',
                      style: engBold.copyWith(fontSize: 12)),
                  pw.Text('मरणोत्तर पंचनामा',
                      style: mrBold.copyWith(fontSize: 10)),
                  pw.SizedBox(height: 1),
                  pw.Text('(Under Section - 194 B.N.S.S.)',
                      style: engBold.copyWith(fontSize: 8.5)),
                  pw.Text(
                      '( भारतीय नागरिक सुरक्षा संहिता २०२३ कलम १९४ अन्वये.)',
                      style: mrStyle.copyWith(fontSize: 8)),
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
            subLabel(
                '   जिल्हा - यवतमाळ             पो.स्टे.             वर्ष                     पहिली खबर क्र./ अकस्मात मृत्यू क्र.'),
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
                pw.Text('3) Place From where Dead Body Found/Traced : ',
                    style: engBold),
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
                pw.Text('4) By whom Dead Body Shown                   :',
                    style: engBold),
                pw.Expanded(child: underlineField(v('shownBy'))),
              ],
            ),
            subLabel('   प्रेत कोणी दाखविले :-'),
            pw.SizedBox(height: 6),

            // 5) By whom identified
            pw.Row(
              children: [
                pw.Text('5) By whom Dead Body Identified              :',
                    style: engBold),
                pw.Expanded(child: underlineField(v('identifiedBy'))),
              ],
            ),
            subLabel('   प्रेत कोणी ओळखले :-'),
            multilineBox(v('identifiedBy2'), lines: 2),
            pw.SizedBox(height: 6),

            // a) Male/Female
            pw.Row(
              children: [
                pw.Text('a) Dead Body Male/Female                     :',
                    style: engBold),
                pw.Expanded(child: underlineField(v('gender'))),
              ],
            ),
            subLabel('   अ) प्रेत स्त्री / पुरुष जातीचे :-'),
            pw.SizedBox(height: 6),

            // 6) b) Married/Unmarried
            pw.Row(
              children: [
                pw.Text('6) b) Dead Body Married/Unmarried            :',
                    style: engBold),
                pw.Expanded(child: underlineField(v('married'))),
              ],
            ),
            subLabel('   ब) प्रेत विवाहीत /अविवाहीत आहे :-'),
            pw.SizedBox(height: 6),

            // c) Age
            pw.Row(
              children: [
                pw.Text('c) Age of Dead Body                          :',
                    style: engBold),
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
            subLabel(
                '                                                तारीख                                   वेळ'),
            pw.SizedBox(height: 6),

            // 7) Position
            pw.Row(
              children: [
                pw.Text('7) Position of Dead Body                     :',
                    style: engBold),
                pw.Expanded(child: underlineField(v('positionOfBody'))),
              ],
            ),
            subLabel('   प्रेताची स्थिती / अवस्था (जागा)'),
            multilineBox(v('positionOfBody2'), lines: 2),

            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('M.R.W',
                  style: engStyle.copyWith(
                      fontSize: 8, fontStyle: pw.FontStyle.italic)),
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
                pw.Text('8) Name and Address of Dead Body             :',
                    style: engBold),
                pw.Expanded(child: underlineField(v('nameAddressDeceased'))),
              ],
            ),
            subLabel('   प्रेताचे संपूर्ण नांव व पत्ता (माहित असल्यास)'),
            multilineBox(v('nameAddressDeceased2'), lines: 3),
            pw.SizedBox(height: 8),

            // 9) Description of injuries
            pw.Row(
              children: [
                pw.Text(
                    '9) Description Of injuries Found on Dead Body if any :',
                    style: engBold),
                pw.Expanded(child: underlineField(v('injDescription'))),
              ],
            ),
            subLabel('   प्रेताचे अंगावर असल्यास त्याचे वर्णन :'),
            pw.SizedBox(height: 6),

            injuryRow('a) Head          :', 'अ) डोके        :', v('injHead')),
            injuryRow('b) Face          :', 'ब) चेहरा        :', v('injFace')),
            injuryRow('c) Neck          :', 'क) मान         :', v('injNeck')),
            injuryRow('d) Chest         :', 'ड) छाती        :', v('injChest')),
            injuryRow(
                'e) Stomac        :', 'इ) पोट         :', v('injStomach')),
            injuryRow(
                'f) Right Hand    :', 'फ) उजवा हात     :', v('injRightHand')),
            injuryRow(
                'g) Left Hand     :', 'ग) डावा हात     :', v('injLeftHand')),
            injuryRow(
                'h) Right Leg     :', 'ह) उजवा पाय     :', v('injRightLeg')),
            injuryRow(
                'i) Left Leg      :', 'ऐ) डावा पाय     :', v('injLeftLeg')),
            injuryRow('j) Private part  :', 'जे) गुप्त भाग     :',
                v('injPrivatePart')),
            injuryRow('k) Back          :', 'के) पाठ        :', v('injBack')),

            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('M.R.W',
                  style: engStyle.copyWith(
                      fontSize: 8, fontStyle: pw.FontStyle.italic)),
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
            pw.Text(
                '10)   Injuries of Dead Body Caused By Accidental/Violence :',
                style: engBold),
            pw.Row(
              children: [
                pw.Text('Homicide / Other Burn / (Fair / Tejab) ',
                    style: engBold.copyWith(fontSize: 8)),
                pw.Expanded(child: underlineField(v('injAccidentalViolence'))),
              ],
            ),
            subLabel('प्रेताचे अंगावरील जखमा अपघाताच्या घोक्यातील / इत्यादी'),
            subLabel('होण्यामुळे झाल्या'),
            pw.SizedBox(height: 6),

            // 11) Weapon / Means
            pw.Row(
              children: [
                pw.Text('11) Weapon / Means (if any)                  :',
                    style: engBold),
                pw.Expanded(child: underlineField(v('weaponMeans'))),
              ],
            ),
            subLabel('जखमा केलेल्या हत्यार/ साधन असल्यास           :'),
            pw.SizedBox(height: 6),

            // 12) Cool/Warm
            pw.Row(
              children: [
                pw.Text('12) Dead Body Cool / Warm                    :',
                    style: engBold),
                pw.Expanded(child: underlineField(v('bodyCoolWarm'))),
              ],
            ),
            subLabel('प्रेत थंड आहे/ गरम आहे.                       :'),
            pw.SizedBox(height: 6),

            // 13) Poisoning
            pw.Row(
              children: [
                pw.Text('13) Position Dead Body by Poisoning          :',
                    style: engBold),
                pw.Expanded(child: underlineField(v('poisoningPosition'))),
              ],
            ),
            subLabel('प्रेताची स्थिती विष प्राशन केलेला असल्यास       :'),
            pw.SizedBox(height: 6),

            // 14) Fingerprint & Photo
            pw.Text('14) (a) Finger Print has taken by Doctor Not taken Reason',
                style: engBold),
            pw.Row(
              children: [
                pw.Text('(In case of unidentified Dead Body)          :',
                    style: engStyle),
                pw.Expanded(child: underlineField(v('fingerprintReason'))),
              ],
            ),
            subLabel(
                'अनोळखी प्रेताचे डॉक्टरांकडून बोटांचे ठसे घेतले/ नाही कारण :'),
            pw.SizedBox(height: 4),

            pw.Text('(b) Photo has taken/not taken reason (In case of an',
                style: engBold),
            pw.Row(
              children: [
                pw.Text('Identified Dead Body)                        :',
                    style: engStyle),
                pw.Expanded(child: underlineField(v('photoReason'))),
              ],
            ),
            subLabel('अनोळखी प्रेताचे फोटो घेतले आहेत काय/नाही कारण :'),
            pw.SizedBox(height: 6),

            // 15) Dead Body sent to PM
            pw.Row(
              children: [
                pw.Text('15) Dead Body sent to P.M. / not reason: ',
                    style: engBold),
                pw.Expanded(child: underlineField(v('sentToPMReason'))),
              ],
            ),
            subLabel('प्रेत (पोस्ट मार्टम) शविच्छेदन करीता पाठविले/ नाही कारण'),
            pw.SizedBox(height: 4),

            pw.Row(
              children: [
                pw.Text('(a) At which Hospital Dead Body sent to P.M.:',
                    style: engBold),
                pw.Expanded(child: underlineField(v('hospitalName'))),
              ],
            ),
            subLabel('कोणत्या रूग्णालयात प्रेत पोस्ट मार्टूम करीता पाठविले :'),
            pw.SizedBox(height: 4),

            pw.Text('(b) With whom (Name No. and P.sm)            :',
                style: engBold),
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
            subLabel(
                'नांव                                        बक्कल नंबर                 पो.स्टे'),
            pw.SizedBox(height: 6),

            // 16) Opinion of Panchas
            pw.Row(
              children: [
                pw.Text('16) Opinion of Panchas and Police about Death: ',
                    style: engBold),
                pw.Expanded(child: underlineField(v('opinionPanchas'))),
              ],
            ),
            subLabel('पंच व पोलीसांचा मृत्यूविषयी अभिप्राय'),
            multilineBox(v('opinionPanchas2'), lines: 4),
            pw.SizedBox(height: 6),

            // 17) More info
            pw.Row(
              children: [
                pw.Text('17) More information if any                 : ',
                    style: engBold),
                pw.Expanded(child: underlineField(v('moreInfo'))),
              ],
            ),
            subLabel('अधिक माहिती असल्यास'),

            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('M.R.W',
                  style: engStyle.copyWith(
                      fontSize: 8, fontStyle: pw.FontStyle.italic)),
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
            subLabel(
                '    पंचनामा केल्याची               दिनांक : -                       वेळ : -                 ते'),
            pw.SizedBox(height: 10),

            // 19) Name of Panchas and Signature
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('19) Name of Panchas and Signature: -',
                          style: engBold),
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
                      pw.Text('Signature of Investigation Officer',
                          style: engBold),
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
              child: pw.Text('M.R.W',
                  style: engStyle.copyWith(
                      fontSize: 8, fontStyle: pw.FontStyle.italic)),
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
    pw.Widget csPdfRow(
        String qNum, String qTextEn, String qTextMr, pw.Widget answerWidget) {
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
                  pw.Text('$qNum $qTextEn',
                      style: engBold.copyWith(fontSize: 7.5)),
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
            csPdfRow('1)', 'Name of Deceased', 'मृत व्यक्तीचे नांव',
                underlineField(v('csNameDeceased'))),
            csPdfRow('2)', 'Age', 'वय', underlineField(v('csAge'))),
            csPdfRow(
                '3)',
                'Married, Single, Widow or Widower',
                'विवाहीत, अविवाहीत, विधवा किंवा विधूर',
                underlineField(v('csMaritalStatus'))),
            csPdfRow('4)', 'Date and hour of death', 'मृत्युचा दिनांक आणि वेळ',
                csPdfDateTimeAnswer(v('csDeathDate'), v('csDeathTime'))),
            csPdfRow(
                '5)',
                'Describe condition of body when found, Position, Surroundings and any marks of Violence, bloodstains or vomited matters Which may have existed?',
                'प्रेत सापडले त्यावेळची अवस्था, स्थिती, भोवतालची परिस्थिती आणि उपलब्ध असलेल्या मारहाणीच्या खुणा रक्ताचे डाग किंवा वांतीबरोबर पडलेले पदार्थ यांचा तपशील दयावा.',
                multilineBox(v('csBodyCondition'), lines: 3)),
            csPdfRow(
                '6)',
                'Day and hour on which the body was seen by the officer making the report',
                'अहवाल पाठविणाऱ्या अधिकाऱ्याने प्रेत पाहिल्याचा दिनांक व वेळ (तास)',
                csPdfDateTimeAnswer(v('csSeenDate'), v('csSeenTime'))),
            csPdfRow(
                '7)',
                'Was the body cold or warm when found?',
                'प्रेत सापडले त्यावेळी थंड होते कि गरम',
                underlineField(v('csBodyColdWarm'))),
            csPdfRow(
                '8)',
                'Had the deceased suffered from recent Illness? If so, what? State duration and Describe the illness as far as Known.',
                'मृत व्यक्तीस अलिकडे काही आजार झाला होता काय असल्यास कोणता.',
                multilineBox(v('csRecentIllness'), lines: 2)),
            csPdfRow(
                '9)',
                'Had deceased suffered from accident Injury or if so, describe it.',
                'मृत व्यक्तीस कोणत्याही प्रकारचा अपघात, दुखापत किंवा मारहाण झाली होती काय ?',
                multilineBox(v('csAccidentInjury'), lines: 2)),
            csPdfRow(
                '10)',
                'If clothes, weapons, vomited matter of Other articles are forwarded, State why this Is done and what relation they bear to the Case? Describe them.',
                'कपडे, हत्यारे, वांतीबरोबर पडलेले पदार्थ किंवा इतर वस्तु पाठविल्या असल्यास तसे का केले व त्याचा प्रकरणाशी संबंध आहे ते लिहावे, त्याचा तपशील दयावा.',
                multilineBox(v('csArticlesForwarded'), lines: 3)),
            csPdfRow(
                '11)',
                'Is death supposed to have been due to Natural causes, accident, suicide or homicide? State briefly and plainly, any suspicions That may exist and why?',
                'मृत्यु नैसर्गिक कारणे, अपघात, आत्महत्या किंवा खून यापैकी कशामुळे घडला असे वाटते. काही संशय असल्यास ते थोडक्यात स्पष्टपणे नमुद करावे व कारणे दयावे.',
                multilineBox(v('csDeathReason'), lines: 3)),
            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('M.R.W',
                  style: engStyle.copyWith(
                      fontSize: 7, fontStyle: pw.FontStyle.italic)),
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

            csPdfRow(
                '12)',
                'Is there suspicion of poisoning? If, so, is any particular poison supposed to have been employed? Mention any symptoms of poisoning which are reported to have existed during life and any appearances pointing to poisoning observed after death.',
                'विष प्रयोग केल्याचा संशय आहे, असल्यास विशिष्ट विषाचा वापर केला आहे वाटते काय? मृत व्यक्ती जिवंत असतांना विषबाधा झाल्याची लक्षणे दिसून आल्याचे कळविण्यात आले होते काय, व विषाचे बाबत मृत्यु नंतर दिसून आलेली चिन्हे नमुद करावी.',
                multilineBox(v('csPoisonSuspicion'), lines: 4)),
            csPdfRow(
                '13)',
                'In the case of a woman, is she supposed to be pregnant of to have been recently delivered ?',
                'स्त्रीच्या बाबतीत ती गरोदर असावी किंवा अलीकडे प्रसुती झाली असावी असे वाटते काय ?',
                multilineBox(v('csWomanPregnancy'), lines: 2)),
            csPdfRow(
                '14)',
                'Is abortion or attempted abortion known or suspected? And if the former, has the focus been found?',
                'गर्भपात केला किंवा गर्भपात करण्याचा प्रयत्न केला या विषयी माहिती किंवा संशय आहे काय, गर्भपात केला असल्यास गर्भ सापडला काय.',
                multilineBox(v('csAbortion'), lines: 2)),
            csPdfRow(
                '15)',
                'State the finding of the Jury (if any) and mention any reasons they may have given for their findings.',
                'ज्युरीचे निष्कर्ष असल्यास नमुद करावेत व निष्कर्षा बाबत त्यांनी काही कारणे दिली असल्यास त्याचा निर्देश करावा.',
                multilineBox(v('csJuryFindings'), lines: 2)),
            csPdfRow(
                '16)',
                'Remarks. Under this head the Police Officer should give any information not included in the above question which he may consider likely to assist the Civil Surgeon informing an opinion of the cause of death.',
                'शेरा वरील प्रश्नात समाविष्ट न झालेली परंतु पोलीस अधिकाऱ्यांच्या मते जिल्हा शल्यचिकित्सकांना मृत्युच्या कारणाविषयी आपले मत बनविण्यास सहाय्यभूत होण्याचा संभव आहे अशी कोणत्याही प्रकारची माहिती या शीर्षका खाली दयावी.',
                multilineBox(v('csRemarks'), lines: 4)),

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
              child: pw.Text('M.R.W',
                  style: engStyle.copyWith(
                      fontSize: 7, fontStyle: pw.FontStyle.italic)),
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
                        pw.Text('पोलीस स्टेशन',
                            style: mrBold.copyWith(fontSize: 8.5)),
                        underlineField(v('reqPs'), width: 100),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Wrap(
                      crossAxisAlignment: pw.WrapCrossAlignment.center,
                      children: [
                        pw.Text('दिनांक :- ',
                            style: mrBold.copyWith(fontSize: 8.5)),
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
                  pw.Text('मा. न्यायवैद्यक शास्त्र विभाग प्रमुख',
                      style: mrBold.copyWith(fontSize: 9)),
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
                pw.Text('पासुन  :-    पोलीस स्टेशन',
                    style: mrBold.copyWith(fontSize: 8.5)),
                underlineField(v('reqFromPs'), width: 110),
                pw.Text('  जिल्हा यवतमाळ.',
                    style: mrBold.copyWith(fontSize: 8.5)),
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
                          pw.Text('मृतक नामे ',
                              style: mrBold.copyWith(fontSize: 8.5)),
                          underlineField(v('reqSubjectName'), width: 280),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Wrap(
                        crossAxisAlignment: pw.WrapCrossAlignment.center,
                        children: [
                          pw.Text('पो.स्टे.',
                              style: mrBold.copyWith(fontSize: 8.5)),
                          underlineField(v('reqSubjectPs'), width: 80),
                          pw.Text('  ता-',
                              style: mrBold.copyWith(fontSize: 8.5)),
                          underlineField(v('reqSubjectTa'), width: 70),
                          pw.Text(
                              '  जिल्हा यवतमाळ हिचे/ ह्यांचे प्रेताचे पि.एम',
                              style: mrBold.copyWith(fontSize: 8.5)),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text('करून आपला अभिप्राय मिळणेबाबत.',
                          style: mrBold.copyWith(fontSize: 8.5)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Center(
                child: pw.Text('० ० ० ०',
                    style: mrStyle.copyWith(letterSpacing: 4, fontSize: 8))),
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
                  pw.Text('सविनय सेवेशी सादर आहे की, आज दिनांक ',
                      style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqMargDate'), width: 65),
                  pw.Text(' रोजी ', style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqMargTime'), width: 50),
                  pw.Text(' वाजता पोलीस स्टेशन ',
                      style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqMargPs'), width: 90),
                  pw.Text(' मर्ग/ स्टेशन डायरी क्र.',
                      style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqMargDiaryNo'), width: 55),
                  pw.Text('/२०', style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqMargYear'), width: 35),
                  pw.Text(
                      ' कलम १९४ बी.एन.एस.एस २०२३ चा मर्ग दाखल झाला असुन यातील मृतक नामे ',
                      style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqMargName'), width: 190),
                  pw.Text(' पो.स्टे.', style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqSubjectPs'), width: 80),
                  pw.Text(' ता-', style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqMargTa'), width: 70),
                  pw.Text(' जिल्हा यवतमाळ ही/ह्या ',
                      style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqHospitalName'), width: 140),
                  pw.Text(' येथे दिनांक ',
                      style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqAdmitDate'), width: 65),
                  pw.Text(' रोजी ', style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqAdmitTime'), width: 50),
                  pw.Text(
                      ' वाजता भरती झाला असुन औषधोपचारा दरम्यान/ गळफास लावुन/ विष प्राशन करून/अपघात/ ',
                      style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqReasonDetails'), width: 160),
                  pw.Text(' दिनांक ', style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqDeathDate'), width: 65),
                  pw.Text(' रोजी ', style: mrStyle.copyWith(fontSize: 8)),
                  underlineField(v('reqDeathTime'), width: 50),
                  pw.Text(' वाजता मरण पावला आहे.',
                      style: mrStyle.copyWith(fontSize: 8)),
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
                      pw.Text('सहपत्र : प्रश्नोत्तर फॉर्म',
                          style: mrBold.copyWith(fontSize: 8)),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 30.0),
                        child: pw.Text('इंक्वेस्ट पंचनामा',
                            style: mrBold.copyWith(fontSize: 8)),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Wrap(
                        crossAxisAlignment: pw.WrapCrossAlignment.center,
                        children: [
                          pw.Text('हस्ते : ',
                              style: mrBold.copyWith(fontSize: 8)),
                          underlineField(v('reqHasteName'), width: 100),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Wrap(
                        crossAxisAlignment: pw.WrapCrossAlignment.center,
                        children: [
                          pw.Text('पो.स्टे. : ',
                              style: mrBold.copyWith(fontSize: 8)),
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
                      pw.Text('तपासी अधिकारी नांव /सही शिक्या',
                          style: mrBold.copyWith(fontSize: 8)),
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
              child: pw.Text('M.R.W',
                  style: engStyle.copyWith(
                      fontSize: 7, fontStyle: pw.FontStyle.italic)),
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
                        pw.Text('पोलीस स्टेशन',
                            style: mrBold.copyWith(fontSize: 8.5)),
                        underlineField(v('relPs'), width: 100),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Wrap(
                      crossAxisAlignment: pw.WrapCrossAlignment.center,
                      children: [
                        pw.Text('कॅम्प :- ',
                            style: mrBold.copyWith(fontSize: 8.5)),
                        underlineField(v('relCamp'), width: 110),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Wrap(
                      crossAxisAlignment: pw.WrapCrossAlignment.center,
                      children: [
                        pw.Text('दिनांक :- ',
                            style: mrBold.copyWith(fontSize: 8.5)),
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
            pw.Center(
                child: pw.Text('० ० ० ०',
                    style: mrStyle.copyWith(letterSpacing: 4, fontSize: 8))),
            pw.SizedBox(height: 8),

            // Body Paragraph
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 8.0),
              child: pw.Wrap(
                crossAxisAlignment: pw.WrapCrossAlignment.center,
                runSpacing: 4,
                spacing: 2,
                children: [
                  pw.Text('आपणास या समन्सव्दारे कळविण्यात येते की, आम्ही ',
                      style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('relWeName'), width: 150),
                  pw.Text(' पोलीस स्टेशन ',
                      style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('relPsName'), width: 100),
                  pw.Text(' येथील अप/ मर्ग/ ठाणे दैनंदिनी क्रमांक ',
                      style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('relCrDiaryNo'), width: 55),
                  pw.Text('/२०', style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('relCrYear'), width: 35),
                  pw.Text(' कलम ', style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('relActSec'), width: 120),
                  pw.Text(' मधील मृतक नामे ',
                      style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('relDeceasedName'), width: 180),
                  pw.Text(' ता-', style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('relTa'), width: 75),
                  pw.Text(' जिल्हा ', style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('relDist'), width: 75),
                  pw.Text(
                      ' यांचे प्रेताचा इंन्क्वेस्ट पंचनामा करणार आहो. करीता आपण प्रेत ओळखुन देवून मृतकाचे नातेवाईक या नात्याने पंचनाम्याची कार्यवाही पूर्ण होईपर्यंत आमचे सोबत हजर राहावे.',
                      style: mrStyle.copyWith(fontSize: 8.5)),
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
                      pw.Text('तपासी अधिकारी नांव / सही शिक्या',
                          style: mrBold.copyWith(fontSize: 8.5)),
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
              child: pw.Text('M.R.W',
                  style: engStyle.copyWith(
                      fontSize: 7, fontStyle: pw.FontStyle.italic)),
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
                        pw.Text('पोलीस स्टेशन',
                            style: mrBold.copyWith(fontSize: 8.5)),
                        underlineField(v('panPs'), width: 100),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Wrap(
                      crossAxisAlignment: pw.WrapCrossAlignment.center,
                      children: [
                        pw.Text('कॅम्प :- ',
                            style: mrBold.copyWith(fontSize: 8.5)),
                        underlineField(v('panCamp'), width: 110),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Wrap(
                      crossAxisAlignment: pw.WrapCrossAlignment.center,
                      children: [
                        pw.Text('दिनांक :- ',
                            style: mrBold.copyWith(fontSize: 8.5)),
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
            pw.Center(
                child: pw.Text('० ० ० ०',
                    style: mrStyle.copyWith(letterSpacing: 4, fontSize: 8))),
            pw.SizedBox(height: 8),

            // Body Paragraph
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 8.0),
              child: pw.Wrap(
                crossAxisAlignment: pw.WrapCrossAlignment.center,
                runSpacing: 4,
                spacing: 2,
                children: [
                  pw.Text('आपणास या समन्सव्दारे कळविण्यात येते की, आम्ही ',
                      style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('panWeName'), width: 150),
                  pw.Text(' पोलीस स्टेशन ',
                      style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('panPsName'), width: 100),
                  pw.Text(' येथील अप/ मर्ग/ ठाणे दैनंदिनी क्रमांक ',
                      style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('panCrDiaryNo'), width: 55),
                  pw.Text('/२०', style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('panCrYear'), width: 35),
                  pw.Text(' कलम ', style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('panActSec'), width: 120),
                  pw.Text(' मधील मृतक नामे ',
                      style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('panDeceasedName'), width: 180),
                  pw.Text(' ता-', style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('panTa'), width: 75),
                  pw.Text(' जिल्हा ', style: mrStyle.copyWith(fontSize: 8.5)),
                  underlineField(v('panDist'), width: 75),
                  pw.Text(
                      ' यांचे प्रेताचा इंन्क्वेस्ट पंचनामा करणार आहो. करीता आपण पंचनाम्याची कार्यवाही पूर्ण होईपर्यंत पंच म्हणुन आमचे सोबत हजर राहावे.',
                      style: mrStyle.copyWith(fontSize: 8.5)),
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
                      pw.Text('तपासी अधिकारी नांव / सही शिक्या',
                          style: mrBold.copyWith(fontSize: 8.5)),
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
              child: pw.Text('M.R.W',
                  style: engStyle.copyWith(
                      fontSize: 7, fontStyle: pw.FontStyle.italic)),
            ),
          ],
        ),
      ),
    );
  }

  if (showsSection('Marananveshan Panchanama')) {
    // PAGE 1 — मरणा-न्वेषण पंचनामा (१ ते १२)
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 26),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'मरणा-न्वेषण पंचनामा',
                style: mrBold.copyWith(
                  fontSize: 16,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),
            pw.SizedBox(height: 12),

            // Top Right: ठिकाण, दिनांक, सुरू केल्याची वेळ
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.SizedBox(
                width: 250,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(children: [
                      pw.Text('ठिकाण : ',
                          style: mrBold.copyWith(fontSize: 9.5)),
                      pw.Expanded(child: underlineField(v('marThikan'))),
                    ]),
                    pw.SizedBox(height: 3),
                    pw.Row(children: [
                      pw.Text('दिनांक : ',
                          style: mrBold.copyWith(fontSize: 9.5)),
                      pw.Expanded(
                        child: underlineField(
                          v('marDate').isEmpty
                              ? '......./ ......./ २०.........'
                              : v('marDate'),
                        ),
                      ),
                    ]),
                    pw.SizedBox(height: 3),
                    pw.Row(children: [
                      pw.Text('सुरू केल्याची वेळ: ',
                          style: mrBold.copyWith(fontSize: 9.5)),
                      pw.Expanded(
                        child: underlineField(
                          v('marTime').isEmpty
                              ? '........./ .........'
                              : v('marTime'),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 14),

            // १) पंचाचे नांव व पत्ता :-
            pw.Text('१) पंचाचे नांव व पत्ता :-',
                style: mrBold.copyWith(fontSize: 9.5)),
            pw.SizedBox(height: 1),
            multilineBox(v('marPanchNameAddress'), lines: 4),
            pw.SizedBox(height: 5),

            // २) पोलीस स्टेशन ________ जिल्हा : ________
            pw.Row(
              children: [
                pw.Text('२) पोलीस स्टेशन ',
                    style: mrBold.copyWith(fontSize: 9.5)),
                pw.Expanded(child: underlineField(v('marPs'))),
                pw.SizedBox(width: 16),
                pw.Text('जिल्हा : ', style: mrBold.copyWith(fontSize: 9.5)),
                pw.Expanded(child: underlineField(v('marDist'))),
              ],
            ),
            pw.SizedBox(height: 5),

            // ३) अकस्मात मृत्यु/गुन्हा/ठाणे दैनंदिनी क्र:-
            pw.Row(
              children: [
                pw.Text('३) अकस्मात मृत्यु/गुन्हा/ठाणे दैनंदिनी क्र:-',
                    style: mrBold.copyWith(fontSize: 9.5)),
                pw.Expanded(child: underlineField(v('marDiaryNo'))),
              ],
            ),
            pw.SizedBox(height: 5),

            // ४) अधिनियम व कलम :-
            pw.Row(
              children: [
                pw.Text('४) अधिनियम व कलम :-',
                    style: mrBold.copyWith(fontSize: 9.5)),
                pw.Expanded(child: underlineField(v('marActSec'))),
              ],
            ),
            pw.SizedBox(height: 5),

            // ५) अन्वेषण अधिकाऱ्याचे नांव, हुद्दा :-
            pw.Text('५) अन्वेषण अधिकाऱ्याचे नांव, हुद्दा :-',
                style: mrBold.copyWith(fontSize: 9.5)),
            pw.SizedBox(height: 1),
            multilineBox(v('marIoDetails'), lines: 2),
            pw.SizedBox(height: 5),

            // ६) फिर्यादीचे नांव :-
            pw.Text('६) फिर्यादीचे नांव :-',
                style: mrBold.copyWith(fontSize: 9.5)),
            pw.SizedBox(height: 1),
            multilineBox(v('marComplainantName'), lines: 2),
            pw.SizedBox(height: 5),

            // ७) मृतकाचे नांव व पत्ता :-
            pw.Text('७) मृतकाचे नांव व पत्ता :-',
                style: mrBold.copyWith(fontSize: 9.5)),
            pw.SizedBox(height: 1),
            multilineBox(v('marDeceasedNameAddress'), lines: 2),
            pw.SizedBox(height: 5),

            // ८) प्रेत दाखविणाऱ्याचे/ओळखणाऱ्याचे नांव :-
            pw.Text('८) प्रेत दाखविणाऱ्याचे/ओळखणाऱ्याचे नांव :-',
                style: mrBold.copyWith(fontSize: 9.5)),
            pw.SizedBox(height: 1),
            multilineBox(v('marShownByName'), lines: 2),
            pw.SizedBox(height: 5),

            // ९) प्रेत ठेवले आहे त्या ठिकाणाचे वर्णन :-
            pw.Text('९) प्रेत ठेवले आहे त्या ठिकाणाचे वर्णन :-',
                style: mrBold.copyWith(fontSize: 9.5)),
            pw.SizedBox(height: 1),
            multilineBox(v('marThikanDescription'), lines: 3),
            pw.SizedBox(height: 5),

            // १०) प्रेताची स्थिती:-
            pw.Text('१०) प्रेताची स्थिती:-',
                style: mrBold.copyWith(fontSize: 9.5)),
            pw.SizedBox(height: 1),
            multilineBox(v('marBodyCondition'), lines: 4),
            pw.SizedBox(height: 5),

            // ११) प्रेताचे अंगावरील कपड्याचे वर्णन :-
            pw.Text('११) प्रेताचे अंगावरील कपड्याचे वर्णन :-',
                style: mrBold.copyWith(fontSize: 9.5)),
            pw.SizedBox(height: 1),
            multilineBox(v('marBodyClothes'), lines: 3),
            pw.SizedBox(height: 5),

            // १२) प्रेताचे अंगावरील दागीने व इतर वस्तु :-
            pw.Text('१२) प्रेताचे अंगावरील दागीने व इतर वस्तु :-',
                style: mrBold.copyWith(fontSize: 9.5)),
            pw.SizedBox(height: 1),
            multilineBox(v('marBodyOrnaments'), lines: 3),

            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.bottomRight,
              child: pw.Text('M.R.W', style: engStyle.copyWith(fontSize: 8)),
            ),
          ],
        ),
      ),
    );

    // PAGE 2 — मरणा-न्वेषण पंचनामा (१३ ते १८ + सह्या)
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 26),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // १३) मृतकाच्या शरीरावरील मार, जखमा इत्यादी :-
            pw.Text('१३) मृतकाच्या शरीरावरील मार, जखमा इत्यादी :-',
                style: mrBold.copyWith(fontSize: 9.5)),
            pw.SizedBox(height: 1),
            multilineBox(v('mar13Injuries'), lines: 4),
            pw.SizedBox(height: 6),

            // १४) प्रेतावरील इतर खुणा...
            pw.Text(
              '१४) प्रेतावरील इतर खुणा, लघवी, विर्यपतन, विष्टा किंवा वांती झाली काय ? तपासणीकरीता नमुने घेतले काय सविस्तर उल्लेख करावा :-',
              style: mrBold.copyWith(fontSize: 9.5),
            ),
            pw.SizedBox(height: 1),
            multilineBox(v('mar14OtherMarks'), lines: 4),
            pw.SizedBox(height: 6),

            // १५) मृतकाचे अंगावरील दागीने...
            pw.Text(
              '१५) मृतकाचे अंगावरील दागीने व इतर वस्तुंची काय विल्हेवाट लावली :-',
              style: mrBold.copyWith(fontSize: 9.5),
            ),
            pw.SizedBox(height: 1),
            multilineBox(v('mar15OrnamentsDisposal'), lines: 3),
            pw.SizedBox(height: 6),

            // १६) पंच व अन्वेषण अधिकारी यांचा अभिप्राय :-
            pw.Text('१६) पंच व अन्वेषण अधिकारी यांचा अभिप्राय :-',
                style: mrBold.copyWith(fontSize: 9.5)),
            pw.SizedBox(height: 1),
            multilineBox(v('mar16Opinion'), lines: 3),
            pw.SizedBox(height: 6),

            // १७) प्रेताची काय विल्हेवाट लावली ? :-
            pw.Text('१७) प्रेताची काय विल्हेवाट लावली ? :-',
                style: mrBold.copyWith(fontSize: 9.5)),
            pw.SizedBox(height: 1),
            multilineBox(v('mar17BodyDisposal'), lines: 3),
            pw.SizedBox(height: 6),

            // १८) पंचनामा संपविल्याची दिनांक व वेळ :-
            pw.Text('१८) पंचनामा संपविल्याची दिनांक व वेळ :-',
                style: mrBold.copyWith(fontSize: 9.5)),
            pw.SizedBox(height: 1),
            multilineBox(v('mar18DateTime'), lines: 2),
            pw.SizedBox(height: 14),

            // Signatures Section
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left Column: पंचाची सही
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('पंचाची सही',
                          style: mrBold.copyWith(fontSize: 10)),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Text('१)- ', style: mrBold.copyWith(fontSize: 9)),
                          pw.Expanded(child: underlineField(v('mar11Panch1'))),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        children: [
                          pw.Text('२)- ', style: mrBold.copyWith(fontSize: 9)),
                          pw.Expanded(child: underlineField(v('mar11Panch2'))),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        children: [
                          pw.Text('३)- ', style: mrBold.copyWith(fontSize: 9)),
                          pw.Expanded(child: underlineField(v('mar11Panch3'))),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        children: [
                          pw.Text('४)- ', style: mrBold.copyWith(fontSize: 9)),
                          pw.Expanded(child: underlineField(v('mar11Panch4'))),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Text('प्रत सादर :- मा.वैद्यकीय अधिकारी ',
                              style: mrBold.copyWith(fontSize: 8.5)),
                          pw.Expanded(child: underlineField(v('mar11CopyTo'))),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 32),

                // Right Column: तपासी अधिकारी नांव व सही शिक्का
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('तपासी अधिकारी नांव व सही शिक्का',
                          style: mrBold.copyWith(fontSize: 10)),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Text('नांव :- ',
                              style: mrBold.copyWith(fontSize: 9)),
                          pw.Expanded(child: underlineField(v('mar11IoName'))),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        children: [
                          pw.Text('हुद्दा :- ',
                              style: mrBold.copyWith(fontSize: 9)),
                          pw.Expanded(child: underlineField(v('mar11IoRank'))),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        children: [
                          pw.Text('पोलीस स्टेशन :- ',
                              style: mrBold.copyWith(fontSize: 9)),
                          pw.Expanded(child: underlineField(v('mar11IoPs'))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.bottomRight,
              child: pw.Text('M.R.W', style: engStyle.copyWith(fontSize: 8)),
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
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 26),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'प्रेत ताबा पावती',
                style: mrBold.copyWith(
                  fontSize: 16,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.SizedBox(
                width: 240,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(children: [
                      pw.Text('पोलीस स्टेशन  : ',
                          style: mrBold.copyWith(fontSize: 10)),
                      pw.Expanded(child: underlineField(v('ptpPs'))),
                    ]),
                    pw.SizedBox(height: 4),
                    pw.Row(children: [
                      pw.Text('कॅम्प            : ',
                          style: mrBold.copyWith(fontSize: 10)),
                      pw.Expanded(child: underlineField(v('ptpCamp'))),
                    ]),
                    pw.SizedBox(height: 4),
                    pw.Row(children: [
                      pw.Text('दिनांक          : ',
                          style: mrBold.copyWith(fontSize: 10)),
                      pw.Expanded(child: underlineField(v('ptpDate'))),
                    ]),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 18),
            pw.RichText(
              text: pw.TextSpan(
                style: mrStyle.copyWith(fontSize: 10, lineSpacing: 4),
                children: [
                  const pw.TextSpan(text: '       मी '),
                  pw.TextSpan(
                      text: v('ptpReceiverName').isEmpty
                          ? '---------------------------------------------------------'
                          : v('ptpReceiverName'),
                      style: mrBold.copyWith(fontSize: 10)),
                  const pw.TextSpan(text: ' रा. '),
                  pw.TextSpan(
                      text: v('ptpReceiverRa').isEmpty
                          ? '------------------------------------------'
                          : v('ptpReceiverRa'),
                      style: mrBold.copyWith(fontSize: 10)),
                  const pw.TextSpan(text: ' ता '),
                  pw.TextSpan(
                      text: v('ptpReceiverTa').isEmpty
                          ? '---------------'
                          : v('ptpReceiverTa'),
                      style: mrBold.copyWith(fontSize: 10)),
                  const pw.TextSpan(text: ' जिल्हा '),
                  pw.TextSpan(
                      text: v('ptpReceiverDist').isEmpty
                          ? '---------------------'
                          : v('ptpReceiverDist'),
                      style: mrBold.copyWith(fontSize: 10)),
                  const pw.TextSpan(text: ' मो नं '),
                  pw.TextSpan(
                      text: v('ptpMoNo').isEmpty
                          ? '......................................'
                          : v('ptpMoNo'),
                      style: mrBold.copyWith(fontSize: 10)),
                  const pw.TextSpan(
                      text: ' प्रेत ताबा पावती लिहुन देतो की, आज दिनांक '),
                  pw.TextSpan(
                      text: v('ptpReceiptDate').isEmpty
                          ? '....../ ......../ २०.....'
                          : v('ptpReceiptDate'),
                      style: mrBold.copyWith(fontSize: 10)),
                  const pw.TextSpan(text: ' रोजी मृतक नामे '),
                  pw.TextSpan(
                      text: v('ptpDeceasedName').isEmpty
                          ? '-------------------------------------------------'
                          : v('ptpDeceasedName'),
                      style: mrBold.copyWith(fontSize: 10)),
                  const pw.TextSpan(text: ' रा. '),
                  pw.TextSpan(
                      text: v('ptpDeceasedRa').isEmpty
                          ? '------------------------------'
                          : v('ptpDeceasedRa'),
                      style: mrBold.copyWith(fontSize: 10)),
                  const pw.TextSpan(text: ' ता आणि जिल्हा '),
                  pw.TextSpan(
                      text: v('ptpDeceasedDist').isEmpty
                          ? '-------------------'
                          : v('ptpDeceasedDist'),
                      style: mrBold.copyWith(fontSize: 10)),
                  const pw.TextSpan(
                      text:
                          ' हयाचे / हिचे प्रेत पोस्टमार्टम होवुन अंतिम संस्काराकरीता माझे ताब्यात मिळाले आहे. सदर प्रेत हे नमुद मृतकाचेच आहे. मी मृतकाचा वारसा या नात्याने ताब्यात घेतले आहे. माझी कोणत्याच प्रकारची तक्रार नाही.'),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 48),
              child: pw.Text(
                'करीता प्रेत ताबा पावती लिहून देत आहे.',
                style: mrStyle.copyWith(fontSize: 10),
              ),
            ),
            pw.SizedBox(height: 36),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'तपासी अधिकारी नांव व सही शिक्का',
                        style: mrBold.copyWith(fontSize: 10),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(children: [
                        pw.Text('नांव : ',
                            style: mrStyle.copyWith(fontSize: 10)),
                        pw.Expanded(child: underlineField(v('ptpIoName'))),
                      ]),
                      pw.SizedBox(height: 4),
                      pw.Row(children: [
                        pw.Text('हुद्दा : ',
                            style: mrStyle.copyWith(fontSize: 10)),
                        pw.Expanded(child: underlineField(v('ptpIoRank'))),
                      ]),
                      pw.SizedBox(height: 4),
                      pw.Row(children: [
                        pw.Text('पोलीस स्टेशन : ',
                            style: mrStyle.copyWith(fontSize: 10)),
                        pw.Expanded(child: underlineField(v('ptpIoPs'))),
                      ]),
                    ],
                  ),
                ),
                pw.SizedBox(width: 40),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'प्रेत ताब्यात घेणाऱ्याची सही',
                        style: mrBold.copyWith(fontSize: 10),
                      ),
                      pw.SizedBox(height: 30),
                      underlineField(v('ptpReceiverSig')),
                    ],
                  ),
                ),
              ],
            ),
            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.bottomRight,
              child: pw.Text(
                'M.R.W',
                style: engStyle.copyWith(fontSize: 9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  if (showsSection('Duty Pass')) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 26),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'ड्युटी पास',
                style: mrBold.copyWith(
                  fontSize: 16,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.SizedBox(
                width: 240,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(children: [
                      pw.Text('पोलीस स्टेशन  : ',
                          style: mrBold.copyWith(fontSize: 10)),
                      pw.Expanded(child: underlineField(v('dpPs'))),
                    ]),
                    pw.SizedBox(height: 4),
                    pw.Row(children: [
                      pw.Text('कॅम्प            : ',
                          style: mrBold.copyWith(fontSize: 10)),
                      pw.Expanded(child: underlineField(v('dpCamp'))),
                    ]),
                    pw.SizedBox(height: 4),
                    pw.Row(children: [
                      pw.Text('दिनांक          : ',
                          style: mrBold.copyWith(fontSize: 10)),
                      pw.Expanded(child: underlineField(v('dpDate'))),
                    ]),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Row(children: [
              pw.Text('पो अंमलदाराचे नांव  : ',
                  style: mrBold.copyWith(fontSize: 10)),
              pw.Expanded(child: underlineField(v('dpAmaldaarName'))),
            ]),
            pw.SizedBox(height: 8),
            pw.Row(children: [
              pw.SizedBox(width: 80),
              pw.Text('पोलीस स्टेशन ', style: mrBold.copyWith(fontSize: 10)),
              underlineField(v('dpDutyPs'), width: 140),
              pw.SizedBox(width: 14),
              pw.Text('जिल्हा ', style: mrBold.copyWith(fontSize: 10)),
              underlineField(
                  v('dpDutyDist').isEmpty ? 'यवतमाळ' : v('dpDutyDist'),
                  width: 110),
            ]),
            pw.SizedBox(height: 8),
            pw.Row(children: [
              pw.Text('नोकरीचा दिनांक व वेळ    :- ',
                  style: mrBold.copyWith(fontSize: 10)),
              underlineField(v('dpDutyDateTime'), width: 220),
            ]),
            pw.SizedBox(height: 18),
            pw.RichText(
              text: pw.TextSpan(
                style: mrStyle.copyWith(fontSize: 10, lineSpacing: 4),
                children: [
                  const pw.TextSpan(
                      text:
                          '       आपणास आदेश देण्यात येतो की, आपण अप/ मर्ग/ स्टे.डायरी क्रमांक '),
                  pw.TextSpan(
                      text: v('dpMargNo').isEmpty ? '.......' : v('dpMargNo'),
                      style: mrBold.copyWith(fontSize: 10)),
                  const pw.TextSpan(text: ' / २०'),
                  pw.TextSpan(
                      text: v('dpMargYear').isEmpty ? '....' : v('dpMargYear'),
                      style: mrBold.copyWith(fontSize: 10)),
                  const pw.TextSpan(text: ' कलम '),
                  pw.TextSpan(
                      text: v('dpKalam').isEmpty
                          ? '--------------------'
                          : v('dpKalam'),
                      style: mrBold.copyWith(fontSize: 10)),
                  const pw.TextSpan(text: ' मधील मृतक नामे '),
                  pw.TextSpan(
                      text: v('dpDeceasedName').isEmpty
                          ? '------------------------------'
                          : v('dpDeceasedName'),
                      style: mrBold.copyWith(fontSize: 10)),
                  const pw.TextSpan(text: ' रा. '),
                  pw.TextSpan(
                      text: v('dpDeceasedRa').isEmpty
                          ? '-------------------'
                          : v('dpDeceasedRa'),
                      style: mrBold.copyWith(fontSize: 10)),
                  const pw.TextSpan(text: ' ता आणि जिल्हा '),
                  pw.TextSpan(
                      text: '${v('dpDeceasedTa')} ${v('dpDeceasedDist')}'
                              .trim()
                              .isEmpty
                          ? '-------------------'
                          : '${v('dpDeceasedTa')} ${v('dpDeceasedDist')}'
                              .trim(),
                      style: mrBold.copyWith(fontSize: 10)),
                  const pw.TextSpan(
                      text:
                          ' हयाचे / हिचे प्रेत सोबत घेउन मा.वैद्यकीय अधिकारी '),
                  pw.TextSpan(
                      text: v('dpMedOfficerName').isEmpty
                          ? '----------------------------'
                          : v('dpMedOfficerName'),
                      style: mrBold.copyWith(fontSize: 10)),
                  const pw.TextSpan(
                      text:
                          ' यांचेकडे शवविच्छेदनाकरीता दाखल करावे. व शवविच्छेदनानंतर प्रेत मृतकाचे वारसदारास ताब्यात देउन मा. वैद्यकीय अधिकारी यांनी पि. एम दरम्यान व्हिसेरा कपडा बंडल दिल्यास ताब्यात घेउन तपासी अंमलदार यांचेकडे दाखल करावे.'),
                ],
              ),
            ),
            pw.Spacer(),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ड्युटी पास घेणाऱ्याची सही',
                          style: mrBold.copyWith(fontSize: 10)),
                      pw.SizedBox(height: 36),
                      underlineField(v('dpAmaldaarSig'), width: 140),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('तपासी अधिकारी नांव व सही शिक्का',
                          style: mrBold.copyWith(fontSize: 10)),
                      pw.SizedBox(height: 8),
                      pw.Row(children: [
                        pw.Text('नांव :- ',
                            style: mrBold.copyWith(fontSize: 9)),
                        pw.Expanded(child: underlineField(v('dpIoName'))),
                      ]),
                      pw.SizedBox(height: 4),
                      pw.Row(children: [
                        pw.Text('हुद्दा :- ',
                            style: mrBold.copyWith(fontSize: 9)),
                        pw.Expanded(child: underlineField(v('dpIoRank'))),
                      ]),
                      pw.SizedBox(height: 4),
                      pw.Row(children: [
                        pw.Text('पोलीस स्टेशन :- ',
                            style: mrBold.copyWith(fontSize: 9)),
                        pw.Expanded(child: underlineField(v('dpIoPs'))),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Align(
              alignment: pw.Alignment.bottomRight,
              child: pw.Text('M.R.W', style: engStyle.copyWith(fontSize: 8)),
            ),
          ],
        ),
      ),
    );
  }

  return pdf.save();
}

Widget _uField(String val, {double? width}) {
  final content = val.trim();
  return Container(
    width: width,
    padding: const EdgeInsets.only(bottom: 1, left: 3, right: 3),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(width: 0.8, color: Colors.black)),
    ),
    child: Text(
      content.isEmpty ? ' ' : content,
      style: FormImagePdfHelper.valStyle(9),
    ),
  );
}

Widget _subLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(top: 1),
    child: Text('($text)', style: FormImagePdfHelper.mReg(7, 1.1)),
  );
}

Widget _multilineBox(String text, {int lines = 3}) {
  final content = text.trim();
  final list = content.isEmpty ? [''] : content.split('\n');
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < lines; i++)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.only(bottom: 1, left: 3),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(width: 0.8, color: Colors.black)),
          ),
          child: Text(
            i < list.length ? list[i] : ' ',
            style: FormImagePdfHelper.valStyle(9),
          ),
        ),
    ],
  );
}

Widget _buildVinantiArjWidget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final mrB = FormImagePdfHelper.mBld(8.5, 1.35);
  final mrR = FormImagePdfHelper.mReg(8.5, 1.35);

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
    children: [
      Center(
        child: Text('विनंती अर्ज', style: FormImagePdfHelper.mBld(13)),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('पोलीस स्टेशन', style: mrB),
                  _uField(v('reqPs'), width: 110),
                ],
              ),
              const SizedBox(height: 2),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('दिनांक :- ', style: mrB),
                  _uField(v('reqDate'), width: 90),
                ],
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 10),
      Text('प्रति,', style: mrB),
      Padding(
        padding: const EdgeInsets.only(left: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('मा. न्यायवैद्यक शास्त्र विभाग प्रमुख', style: mrB),
            const SizedBox(height: 2),
            _uField(v('reqTo'), width: 240),
            const SizedBox(height: 2),
            _uField(v('reqTo2'), width: 240),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('पासुन  :-    पोलीस स्टेशन', style: mrB),
          _uField(v('reqFromPs'), width: 120),
          Text('  जिल्हा यवतमाळ.', style: mrB),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('विषय  :-    ', style: mrB),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('मृतक नामे ', style: mrB),
                    _uField(v('reqSubjectName'), width: 300),
                  ],
                ),
                const SizedBox(height: 3),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('पो.स्टे.', style: mrB),
                    _uField(v('reqSubjectPs'), width: 90),
                    Text('  ता-', style: mrB),
                    _uField(v('reqSubjectTa'), width: 80),
                    Text('  जिल्हा यवतमाळ हिचे/ ह्यांचे प्रेताचे पि.एम', style: mrB),
                  ],
                ),
                const SizedBox(height: 3),
                Text('करून आपला अभिप्राय मिळणेबाबत.', style: mrB),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Center(child: Text('० ० ० ०', style: mrR.copyWith(letterSpacing: 4))),
      const SizedBox(height: 6),
      Text('महोदय,', style: mrB),
      const SizedBox(height: 4),
      Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 4,
          spacing: 2,
          children: [
            Text('सविनय सेवेशी सादर आहे की, आज दिनांक ', style: mrR),
            _uField(v('reqMargDate'), width: 70),
            Text(' रोजी ', style: mrR),
            _uField(v('reqMargTime'), width: 55),
            Text(' वाजता पोलीस स्टेशन ', style: mrR),
            _uField(v('reqMargPs'), width: 95),
            Text(' मर्ग/ स्टेशन डायरी क्र.', style: mrR),
            _uField(v('reqMargDiaryNo'), width: 60),
            Text('/२०', style: mrR),
            _uField(v('reqMargYear'), width: 40),
            Text(' कलम १९४ बी.एन.एस.एस २०२३ चा मर्ग दाखल झाला असुन यातील मृतक नामे ', style: mrR),
            _uField(v('reqMargName'), width: 200),
            Text(' पो.स्टे.', style: mrR),
            _uField(v('reqSubjectPs'), width: 85),
            Text(' ता-', style: mrR),
            _uField(v('reqMargTa'), width: 75),
            Text(' जिल्हा यवतमाळ ही/ह्या ', style: mrR),
            _uField(v('reqHospitalName'), width: 150),
            Text(' येथे दिनांक ', style: mrR),
            _uField(v('reqAdmitDate'), width: 70),
            Text(' रोजी ', style: mrR),
            _uField(v('reqAdmitTime'), width: 55),
            Text(' वाजता भरती झाला असुन औषधोपचारा दरम्यान/ गळफास लावुन/ विष प्राशन करून/अपघात/ ', style: mrR),
            _uField(v('reqReasonDetails'), width: 170),
            Text(' दिनांक ', style: mrR),
            _uField(v('reqDeathDate'), width: 70),
            Text(' रोजी ', style: mrR),
            _uField(v('reqDeathTime'), width: 55),
            Text(' वाजता मरण पावला आहे.', style: mrR),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Text(
          'तरी सदर मृतकाचे मरणाचे निश्चीत कारण समजुन येणेकरीता सदर मृतकाचे प्रेताचे पी.एम करून आपला सविस्तर अभिप्राय मिळणेस विनंती आहे.',
          style: mrR,
        ),
      ),
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('सहपत्र : प्रश्नोत्तर फॉर्म', style: mrB),
                Padding(
                  padding: const EdgeInsets.only(left: 30.0),
                  child: Text('इंक्वेस्ट पंचनामा', style: mrB),
                ),
                const SizedBox(height: 10),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('हस्ते : ', style: mrB),
                    _uField(v('reqHasteName'), width: 110),
                  ],
                ),
                const SizedBox(height: 3),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('पो.स्टे. : ', style: mrB),
                    _uField(v('reqHastePs'), width: 110),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('तपासी अधिकारी नांव /सही शिक्या', style: mrB),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Name: ', style: FormImagePdfHelper.mBld(8.5)),
                    Expanded(child: _uField(v('reqIoName'))),
                  ],
                ),
                _subLabel('नांव'),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text('Rank: ', style: FormImagePdfHelper.mBld(8.5)),
                    _uField(v('reqIoRank'), width: 75),
                    const SizedBox(width: 4),
                    Text('No:', style: FormImagePdfHelper.mBld(8.5)),
                    Expanded(child: _uField(v('reqIoNo'))),
                  ],
                ),
                _subLabel('पद                   बक्कल नंबर'),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text('Posting: ', style: FormImagePdfHelper.mBld(8.5)),
                    Expanded(child: _uField(v('reqIoPosting'))),
                  ],
                ),
                _subLabel('नेमणूक व पत्ता'),
              ],
            ),
          ),
        ],
      ),
      const Spacer(),
      Align(
        alignment: Alignment.centerRight,
        child: Text('M.R.W', style: FormImagePdfHelper.mReg(7.5)),
      ),
    ],
  );
}

Widget _buildRelativeSummonsWidget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final mrB = FormImagePdfHelper.mBld(9, 1.35);
  final mrR = FormImagePdfHelper.mReg(9, 1.35);

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
    children: [
      Center(
        child: Column(
          children: [
            Text('नातेवाईकांना समन्स', style: FormImagePdfHelper.mBld(13)),
            const SizedBox(height: 2),
            Text('(कलम १७९ भारतीय नागरिक सुरक्षा संहिता २०२३ अन्वये)', style: mrB),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('पोलीस स्टेशन', style: mrB),
                  _uField(v('relPs'), width: 110),
                ],
              ),
              const SizedBox(height: 2),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('कॅम्प :- ', style: mrB),
                  _uField(v('relCamp'), width: 120),
                ],
              ),
              const SizedBox(height: 2),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('दिनांक :- ', style: mrB),
                  _uField(v('relDate'), width: 90),
                ],
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('नांव  :-   ', style: mrB),
          Expanded(child: _multilineBox(v('relToName'), lines: 4)),
        ],
      ),
      const SizedBox(height: 8),
      Center(child: Text('० ० ० ०', style: mrR.copyWith(letterSpacing: 4))),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 4,
          spacing: 2,
          children: [
            Text('आपणास या समन्सव्दारे कळविण्यात येते की, आम्ही ', style: mrR),
            _uField(v('relWeName'), width: 160),
            Text(' पोलीस स्टेशन ', style: mrR),
            _uField(v('relPsName'), width: 110),
            Text(' येथील अप/ मर्ग/ ठाणे दैनंदिनी क्रमांक ', style: mrR),
            _uField(v('relCrDiaryNo'), width: 60),
            Text('/२०', style: mrR),
            _uField(v('relCrYear'), width: 40),
            Text(' कलम ', style: mrR),
            _uField(v('relActSec'), width: 130),
            Text(' मधील मृतक नामे ', style: mrR),
            _uField(v('relDeceasedName'), width: 190),
            Text(' ता-', style: mrR),
            _uField(v('relTa'), width: 80),
            Text(' जिल्हा ', style: mrR),
            _uField(v('relDist'), width: 80),
            Text(
              ' यांचे प्रेताचा इंन्क्वेस्ट पंचनामा करणार आहो. करीता आपण प्रेत ओळखुन देवून मृतकाचे नातेवाईक या नात्याने पंचनाम्याची कार्यवाही पूर्ण होईपर्यंत आमचे सोबत हजर राहावे.',
              style: mrR,
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('सही', style: mrB),
                const SizedBox(height: 6),
                Row(children: [Text('१) ', style: mrB), Expanded(child: _uField(v('relSig1')))]),
                const SizedBox(height: 4),
                Row(children: [Text('२) ', style: mrB), Expanded(child: _uField(v('relSig2')))]),
                const SizedBox(height: 4),
                Row(children: [Text('३) ', style: mrB), Expanded(child: _uField(v('relSig3')))]),
                const SizedBox(height: 4),
                Row(children: [Text('४) ', style: mrB), Expanded(child: _uField(v('relSig4')))]),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('तपासी अधिकारी नांव / सही शिक्या', style: mrB),
                const SizedBox(height: 4),
                Row(children: [Text('Name: ', style: mrB), Expanded(child: _uField(v('relIoName')))]),
                _subLabel('नांव'),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text('Rank: ', style: mrB),
                    _uField(v('relIoRank'), width: 75),
                    const SizedBox(width: 4),
                    Text('Number if any:', style: mrB),
                    Expanded(child: _uField(v('relIoNo'))),
                  ],
                ),
                _subLabel('पद                   बक्कल नंबर'),
                const SizedBox(height: 3),
                Row(children: [Text('Posting and Address:', style: mrB), Expanded(child: _uField(v('relIoPosting')))]),
                _subLabel('नेमणूक व पत्ता'),
              ],
            ),
          ),
        ],
      ),
      const Spacer(),
      Align(alignment: Alignment.centerRight, child: Text('M.R.W', style: FormImagePdfHelper.mReg(7.5))),
    ],
  );
}

Widget _buildPanchaSummonsWidget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final mrB = FormImagePdfHelper.mBld(9, 1.35);
  final mrR = FormImagePdfHelper.mReg(9, 1.35);

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
    children: [
      Center(
        child: Column(
          children: [
            Text('पंचांना समन्स', style: FormImagePdfHelper.mBld(13)),
            const SizedBox(height: 2),
            Text('(कलम १९५ भारतीय नागरिक सुरक्षा संहिता २०२३ अन्वये)', style: mrB),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('पोलीस स्टेशन', style: mrB),
                  _uField(v('panPs'), width: 110),
                ],
              ),
              const SizedBox(height: 2),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('कॅम्प :- ', style: mrB),
                  _uField(v('panCamp'), width: 120),
                ],
              ),
              const SizedBox(height: 2),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('दिनांक :- ', style: mrB),
                  _uField(v('panDate'), width: 90),
                ],
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('नांव  :-   ', style: mrB),
          Expanded(child: _multilineBox(v('panToName'), lines: 4)),
        ],
      ),
      const SizedBox(height: 8),
      Center(child: Text('० ० ० ०', style: mrR.copyWith(letterSpacing: 4))),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 4,
          spacing: 2,
          children: [
            Text('आपणास या समन्सव्दारे कळविण्यात येते की, आम्ही ', style: mrR),
            _uField(v('panWeName'), width: 160),
            Text(' पोलीस स्टेशन ', style: mrR),
            _uField(v('panPsName'), width: 110),
            Text(' येथील अप/ मर्ग/ ठाणे दैनंदिनी क्रमांक ', style: mrR),
            _uField(v('panCrDiaryNo'), width: 60),
            Text('/२०', style: mrR),
            _uField(v('panCrYear'), width: 40),
            Text(' कलम ', style: mrR),
            _uField(v('panActSec'), width: 130),
            Text(' मधील मृतक नामे ', style: mrR),
            _uField(v('panDeceasedName'), width: 190),
            Text(' ता-', style: mrR),
            _uField(v('panTa'), width: 80),
            Text(' जिल्हा ', style: mrR),
            _uField(v('panDist'), width: 80),
            Text(
              ' यांचे प्रेताचा इंन्क्वेस्ट पंचनामा करणार आहो. करीता आपण पंचनाम्याची कार्यवाही पूर्ण होईपर्यंत पंच म्हणुन आमचे सोबत हजर राहावे.',
              style: mrR,
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('पंच सही', style: mrB),
                const SizedBox(height: 6),
                Row(children: [Text('१) ', style: mrB), Expanded(child: _uField(v('panSig1')))]),
                const SizedBox(height: 4),
                Row(children: [Text('२) ', style: mrB), Expanded(child: _uField(v('panSig2')))]),
                const SizedBox(height: 4),
                Row(children: [Text('३) ', style: mrB), Expanded(child: _uField(v('panSig3')))]),
                const SizedBox(height: 4),
                Row(children: [Text('४) ', style: mrB), Expanded(child: _uField(v('panSig4')))]),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('तपासी अधिकारी नांव / सही शिक्या', style: mrB),
                const SizedBox(height: 4),
                Row(children: [Text('Name: ', style: mrB), Expanded(child: _uField(v('panIoName')))]),
                _subLabel('नांव'),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text('Rank: ', style: mrB),
                    _uField(v('panIoRank'), width: 75),
                    const SizedBox(width: 4),
                    Text('Number if any:', style: mrB),
                    Expanded(child: _uField(v('panIoNo'))),
                  ],
                ),
                _subLabel('पद                   बक्कल नंबर'),
                const SizedBox(height: 3),
                Row(children: [Text('Posting and Address:', style: mrB), Expanded(child: _uField(v('panIoPosting')))]),
                _subLabel('नेमणूक व पत्ता'),
              ],
            ),
          ),
        ],
      ),
      const Spacer(),
      Align(alignment: Alignment.centerRight, child: Text('M.R.W', style: FormImagePdfHelper.mReg(7.5))),
    ],
  );
}

Widget _csPdfRow(String qNum, String qEn, String qMr, Widget ans) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 3.5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 11,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$qNum $qEn', style: FormImagePdfHelper.mBld(7.5, 1.25)),
              const SizedBox(height: 1),
              Text(qMr, style: FormImagePdfHelper.mReg(7, 1.25)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(flex: 12, child: ans),
      ],
    ),
  );
}

Widget _csDateTimeAnswer(String d, String t) {
  final mrB = FormImagePdfHelper.mBld(7.5);
  return Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 2,
    runSpacing: 2,
    children: [
      Text(':- दिनांक ', style: mrB),
      _uField(d, width: 65),
      Text(' रोजी ', style: mrB),
      _uField(t, width: 55),
      Text(' वाजता.', style: mrB),
    ],
  );
}

Widget _buildCivilSurgeonPg1Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
    children: [
      Center(
        child: Column(
          children: [
            Text(
              'नमुना सी-६१७ स्थानांतरण/सं-२७१-कालगुण-२७११-२,००,०००(पुस्तके ४ पो.स्टे.का. ४४\n(G.R.G.D No.352 dt 21-5-12 P.M. 35 M.C in MR vide L.No.L.89-B dt.18-4-69 form I.G of Police, M.S.Bombay)',
              textAlign: TextAlign.center,
              style: FormImagePdfHelper.mReg(6.5, 1.2),
            ),
            const SizedBox(height: 2),
            Text(
              'शवविच्छेदन परिक्षेसाठी पाठविलेल्या प्रेताबरोबर जिल्हा शल्यचिकित्सकाकडे पाठवायचा पोलीस अहवाल',
              textAlign: TextAlign.center,
              style: FormImagePdfHelper.mBld(9.5),
            ),
            Text(
              'Police Report to be forwarded to the Civil Surgeon with Dead Bodies sent For Post-mortem examination',
              textAlign: TextAlign.center,
              style: FormImagePdfHelper.mBld(8),
            ),
          ],
        ),
      ),
      const SizedBox(height: 4),
      const Divider(color: Colors.black, thickness: 0.8),
      Row(
        children: [
          Expanded(
            flex: 11,
            child: Column(
              children: [
                Text('प्रश्न', style: FormImagePdfHelper.mBld(8)),
                Text('Question', style: FormImagePdfHelper.mBld(8)),
              ],
            ),
          ),
          Container(width: 0.8, height: 20, color: Colors.grey.shade500),
          Expanded(
            flex: 12,
            child: Column(
              children: [
                Text('उत्तर', style: FormImagePdfHelper.mBld(8)),
                Text('Answer', style: FormImagePdfHelper.mBld(8)),
              ],
            ),
          ),
        ],
      ),
      const Divider(color: Colors.black, thickness: 0.8),
      const SizedBox(height: 4),
      _csPdfRow('1)', 'Name of Deceased', 'मृत व्यक्तीचे नांव', _uField(v('csNameDeceased'))),
      _csPdfRow('2)', 'Age', 'वय', _uField(v('csAge'))),
      _csPdfRow('3)', 'Married, Single, Widow or Widower', 'विवाहीत, अविवाहीत, विधवा किंवा विधूर', _uField(v('csMaritalStatus'))),
      _csPdfRow('4)', 'Date and hour of death', 'मृत्युचा दिनांक आणि वेळ', _csDateTimeAnswer(v('csDeathDate'), v('csDeathTime'))),
      _csPdfRow('5)', 'Describe condition of body when found, Position, Surroundings and any marks of Violence, bloodstains or vomited matters Which may have existed?', 'प्रेत सापडले त्यावेळची अवस्था, स्थिती, भोवतालची परिस्थिती आणि उपलब्ध असलेल्या मारहाणीच्या खुणा रक्ताचे डाग किंवा वांतीबरोबर पडलेले पदार्थ यांचा तपशील दयावा.', _multilineBox(v('csBodyCondition'), lines: 3)),
      _csPdfRow('6)', 'Day and hour on which the body was seen by the officer making the report', 'अहवाल पाठविणाऱ्या अधिकाऱ्याने प्रेत पाहिल्याचा दिनांक व वेळ (तास)', _csDateTimeAnswer(v('csSeenDate'), v('csSeenTime'))),
      _csPdfRow('7)', 'Was the body cold or warm when found?', 'प्रेत सापडले त्यावेळी थंड होते कि गरम', _uField(v('csBodyColdWarm'))),
      _csPdfRow('8)', 'Had the deceased suffered from recent Illness? If so, what? State duration and Describe the illness as far as Known.', 'मृत व्यक्तीस अलिकडे काही आजार झाला होता काय असल्यास कोणता.', _multilineBox(v('csRecentIllness'), lines: 2)),
      _csPdfRow('9)', 'Had deceased suffered from accident Injury or if so, describe it.', 'मृत व्यक्तीस कोणत्याही प्रकारचा अपघात, दुखापत किंवा मारहाण झाली होती काय ?', _multilineBox(v('csAccidentInjury'), lines: 2)),
      _csPdfRow('10)', 'If clothes, weapons, vomited matter of Other articles are forwarded, State why this Is done and what relation they bear to the Case? Describe them.', 'कपडे, हत्यारे, वांतीबरोबर पडलेले पदार्थ किंवा इतर वस्तु पाठविल्या असल्यास तसे का केले व त्याचा प्रकरणाशी संबंध आहे ते लिहावे, त्याचा तपशील दयावा.', _multilineBox(v('csArticlesForwarded'), lines: 3)),
      _csPdfRow('11)', 'Is death supposed to have been due to Natural causes, accident, suicide or homicide? State briefly and plainly, any suspicions That may exist and why?', 'मृत्यु नैसर्गिक कारणे, अपघात, आत्महत्या किंवा खून यापैकी कशामुळे घडला असे वाटते. काही संशय असल्यास ते थोडक्यात स्पष्टपणे नमुद करावे व कारणे दयावे.', _multilineBox(v('csDeathReason'), lines: 3)),
      const Spacer(),
      Align(alignment: Alignment.centerRight, child: Text('M.R.W', style: FormImagePdfHelper.mReg(7.5))),
    ],
  );
}

Widget _buildCivilSurgeonPg2Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
    children: [
      const Divider(color: Colors.black, thickness: 0.8),
      Row(
        children: [
          Expanded(
            flex: 11,
            child: Column(
              children: [
                Text('प्रश्न', style: FormImagePdfHelper.mBld(8)),
                Text('Question', style: FormImagePdfHelper.mBld(8)),
              ],
            ),
          ),
          Container(width: 0.8, height: 20, color: Colors.grey.shade500),
          Expanded(
            flex: 12,
            child: Column(
              children: [
                Text('उत्तर', style: FormImagePdfHelper.mBld(8)),
                Text('Answer', style: FormImagePdfHelper.mBld(8)),
              ],
            ),
          ),
        ],
      ),
      const Divider(color: Colors.black, thickness: 0.8),
      const SizedBox(height: 4),
      _csPdfRow('12)', 'Is there suspicion of poisoning? If, so, is any particular poison supposed to have been employed? Mention any symptoms of poisoning which are reported to have existed during life and any appearances pointing to poisoning observed after death.', 'विष प्रयोग केल्याचा संशय आहे, असल्यास विशिष्ट विषाचा वापर केला आहे वाटते काय? मृत व्यक्ती जिवंत असतांना विषबाधा झाल्याची लक्षणे दिसून आल्याचे कळविण्यात आले होते काय, व विषाचे बाबत मृत्यु नंतर दिसून आलेली चिन्हे नमुद करावी.', _multilineBox(v('csPoisonSuspicion'), lines: 4)),
      _csPdfRow('13)', 'In the case of a woman, is she supposed to be pregnant of to have been recently delivered ?', 'स्त्रीच्या बाबतीत ती गरोदर असावी किंवा अलीकडे प्रसुती झाली असावी असे वाटते काय ?', _multilineBox(v('csWomanPregnancy'), lines: 2)),
      _csPdfRow('14)', 'Is abortion or attempted abortion known or suspected? And if the former, has the focus been found?', 'गर्भपात केला किंवा गर्भपात करण्याचा प्रयत्न केला या विषयी माहिती किंवा संशय आहे काय, गर्भपात केला असल्यास गर्भ सापडला काय.', _multilineBox(v('csAbortion'), lines: 2)),
      _csPdfRow('15)', 'State the finding of the Jury (if any) and mention any reasons they may have given for their findings.', 'ज्युरीचे निष्कर्ष असल्यास नमुद करावेत व निष्कर्षा बाबत त्यांनी काही कारणे दिली असल्यास त्याचा निर्देश करावा.', _multilineBox(v('csJuryFindings'), lines: 2)),
      _csPdfRow('16)', 'Remarks. Under this head the Police Officer should give any information not included in the above question which he may consider likely to assist the Civil Surgeon informing an opinion of the cause of death.', 'शेरा वरील प्रश्नात समाविष्ट न झालेली परंतु पोलीस अधिकाऱ्यांच्या मते जिल्हा शल्यचिकित्सकांना मृत्युच्या कारणाविषयी आपले मत बनविण्यास सहाय्यभूत होण्याचा संभव आहे अशी कोणत्याही प्रकारची माहिती या शीर्षका खाली दयावी.', _multilineBox(v('csRemarks'), lines: 4)),
      const SizedBox(height: 6),
      _multilineBox(v('csExtraNotes'), lines: 1),
      const SizedBox(height: 14),
      Row(
        children: [
          const Spacer(),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _subLabel('तपासणी करणाऱ्या अधिकाऱ्यांची नांव व सही'),
                const SizedBox(height: 3),
                Row(children: [Text('Name: ', style: FormImagePdfHelper.mBld(8)), Expanded(child: _uField(v('csIoName')))]),
                _subLabel('नांव'),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text('Rank: ', style: FormImagePdfHelper.mBld(8)),
                    _uField(v('csIoRank'), width: 75),
                    const SizedBox(width: 4),
                    Text('Number if any:', style: FormImagePdfHelper.mBld(8)),
                    Expanded(child: _uField(v('csIoNo'))),
                  ],
                ),
                _subLabel('पद                   बक्कल नंबर'),
                const SizedBox(height: 3),
                Row(children: [Text('Posting and Address:', style: FormImagePdfHelper.mBld(8)), Expanded(child: _uField(v('csIoPosting')))]),
                _subLabel('नेमणूक व पत्ता'),
              ],
            ),
          ),
        ],
      ),
      const Spacer(),
      Align(alignment: Alignment.centerRight, child: Text('M.R.W', style: FormImagePdfHelper.mReg(7.5))),
    ],
  );
}

Widget _buildDeadBodyHandoverWidget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final mrB = FormImagePdfHelper.mBld(10, 1.45);
  final mrR = FormImagePdfHelper.mReg(10, 1.45);

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 26),
    children: [
      Center(
        child: Text(
          'प्रेत ताबा पावती',
          style: FormImagePdfHelper.mBld(16).copyWith(
            decoration: TextDecoration.underline,
          ),
        ),
      ),
      const SizedBox(height: 14),
      Align(
        alignment: Alignment.topRight,
        child: SizedBox(
          width: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('पोलीस स्टेशन  : ', style: mrB),
                Expanded(child: _uField(v('ptpPs'))),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Text('कॅम्प            : ', style: mrB),
                Expanded(child: _uField(v('ptpCamp'))),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Text('दिनांक          : ', style: mrB),
                Expanded(child: _uField(v('ptpDate'))),
              ]),
            ],
          ),
        ),
      ),
      const SizedBox(height: 18),
      Text.rich(
        TextSpan(
          style: mrR,
          children: [
            const TextSpan(text: '       मी '),
            TextSpan(
              text: v('ptpReceiverName').isEmpty ? '---------------------------------------------------------' : v('ptpReceiverName'),
              style: mrB,
            ),
            const TextSpan(text: ' रा. '),
            TextSpan(
              text: v('ptpReceiverRa').isEmpty ? '------------------------------------------' : v('ptpReceiverRa'),
              style: mrB,
            ),
            const TextSpan(text: ' ता '),
            TextSpan(
              text: v('ptpReceiverTa').isEmpty ? '---------------' : v('ptpReceiverTa'),
              style: mrB,
            ),
            const TextSpan(text: ' जिल्हा '),
            TextSpan(
              text: v('ptpReceiverDist').isEmpty ? '---------------------' : v('ptpReceiverDist'),
              style: mrB,
            ),
            const TextSpan(text: ' मो नं '),
            TextSpan(
              text: v('ptpMoNo').isEmpty ? '......................................' : v('ptpMoNo'),
              style: mrB,
            ),
            const TextSpan(text: ' प्रेत ताबा पावती लिहुन देतो की, आज दिनांक '),
            TextSpan(
              text: v('ptpReceiptDate').isEmpty ? '....../ ......../ २०.....' : v('ptpReceiptDate'),
              style: mrB,
            ),
            const TextSpan(text: ' रोजी मृतक नामे '),
            TextSpan(
              text: v('ptpDeceasedName').isEmpty ? '-------------------------------------------------' : v('ptpDeceasedName'),
              style: mrB,
            ),
            const TextSpan(text: ' रा. '),
            TextSpan(
              text: v('ptpDeceasedRa').isEmpty ? '------------------------------' : v('ptpDeceasedRa'),
              style: mrB,
            ),
            const TextSpan(text: ' ता आणि जिल्हा '),
            TextSpan(
              text: v('ptpDeceasedDist').isEmpty ? '-------------------' : v('ptpDeceasedDist'),
              style: mrB,
            ),
            const TextSpan(
              text: ' हयाचे / हिचे प्रेत पोस्टमार्टम होवुन अंतिम संस्काराकरीता माझे ताब्यात मिळाले आहे. सदर प्रेत हे नमुद मृतकाचेच आहे. मी मृतकाचा वारसा या नात्याने ताब्यात घेतले आहे. माझी कोणत्याच प्रकारची तक्रार नाही.',
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.only(left: 48),
        child: Text('करीता प्रेत ताबा पावती लिहून देत आहे.', style: mrR),
      ),
      const SizedBox(height: 36),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('तपासी अधिकारी नांव व सही शिक्का', style: mrB),
                const SizedBox(height: 10),
                Row(children: [Text('नांव : ', style: mrR), Expanded(child: _uField(v('ptpIoName')))]),
                const SizedBox(height: 4),
                Row(children: [Text('हुद्दा : ', style: mrR), Expanded(child: _uField(v('ptpIoRank')))]),
                const SizedBox(height: 4),
                Row(children: [Text('पोलीस स्टेशन : ', style: mrR), Expanded(child: _uField(v('ptpIoPs')))]),
              ],
            ),
          ),
          const SizedBox(width: 40),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('प्रेत ताब्यात घेणाऱ्याची सही', style: mrB),
                const SizedBox(height: 30),
                _uField(v('ptpReceiverSig')),
              ],
            ),
          ),
        ],
      ),
      const Spacer(),
      Align(
        alignment: Alignment.bottomRight,
        child: Text('M.R.W', style: FormImagePdfHelper.mReg(9)),
      ),
    ],
  );
}

Widget _buildDutyPassWidget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final mrB = FormImagePdfHelper.mBld(10, 1.45);
  final mrR = FormImagePdfHelper.mReg(10, 1.45);

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 26),
    children: [
      Center(
        child: Text(
          'ड्युटी पास',
          style: FormImagePdfHelper.mBld(16).copyWith(
            decoration: TextDecoration.underline,
          ),
        ),
      ),
      const SizedBox(height: 14),
      Align(
        alignment: Alignment.topRight,
        child: SizedBox(
          width: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('पोलीस स्टेशन  : ', style: mrB),
                Expanded(child: _uField(v('dpPs'))),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Text('कॅम्प            : ', style: mrB),
                Expanded(child: _uField(v('dpCamp'))),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Text('दिनांक          : ', style: mrB),
                Expanded(child: _uField(v('dpDate'))),
              ]),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Text('पो अंमलदाराचे नांव  : ', style: mrB),
        Expanded(child: _uField(v('dpAmaldaarName'))),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        const SizedBox(width: 80),
        Text('पोलीस स्टेशन ', style: mrB),
        _uField(v('dpDutyPs'), width: 140),
        const SizedBox(width: 14),
        Text('जिल्हा ', style: mrB),
        _uField(v('dpDutyDist').isEmpty ? 'यवतमाळ' : v('dpDutyDist'), width: 110),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Text('नोकरीचा दिनांक व वेळ    :- ', style: mrB),
        _uField(v('dpDutyDateTime'), width: 230),
      ]),
      const SizedBox(height: 18),
      Text.rich(
        TextSpan(
          style: mrR,
          children: [
            const TextSpan(text: '       आपणास आदेश देण्यात येतो की, आपण अप/ मर्ग/ स्टे.डायरी क्रमांक '),
            TextSpan(
              text: v('dpMargNo').isEmpty ? '.......' : v('dpMargNo'),
              style: mrB,
            ),
            const TextSpan(text: ' / २०'),
            TextSpan(
              text: v('dpMargYear').isEmpty ? '....' : v('dpMargYear'),
              style: mrB,
            ),
            const TextSpan(text: ' कलम '),
            TextSpan(
              text: v('dpKalam').isEmpty ? '--------------------' : v('dpKalam'),
              style: mrB,
            ),
            const TextSpan(text: ' मधील मृतक नामे '),
            TextSpan(
              text: v('dpDeceasedName').isEmpty ? '------------------------------' : v('dpDeceasedName'),
              style: mrB,
            ),
            const TextSpan(text: ' रा. '),
            TextSpan(
              text: v('dpDeceasedRa').isEmpty ? '-------------------' : v('dpDeceasedRa'),
              style: mrB,
            ),
            const TextSpan(text: ' ता आणि जिल्हा '),
            TextSpan(
              text: '${v('dpDeceasedTa')} ${v('dpDeceasedDist')}'.trim().isEmpty
                  ? '-------------------'
                  : '${v('dpDeceasedTa')} ${v('dpDeceasedDist')}'.trim(),
              style: mrB,
            ),
            const TextSpan(text: ' हयाचे / हिचे प्रेत सोबत घेउन मा.वैद्यकीय अधिकारी '),
            TextSpan(
              text: v('dpMedOfficerName').isEmpty ? '----------------------------' : v('dpMedOfficerName'),
              style: mrB,
            ),
            const TextSpan(
              text: ' यांचेकडे शवविच्छेदनाकरीता दाखल करावे. व शवविच्छेदनानंतर प्रेत मृतकाचे वारसदारास ताब्यात देउन मा. वैद्यकीय अधिकारी यांनी पि. एम दरम्यान व्हिसेरा कपडा बंडल दिल्यास ताब्यात घेउन तपासी अंमलदार यांचेकडे दाखल करावे.',
            ),
          ],
        ),
      ),
      const Spacer(),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ड्युटी पास घेणाऱ्याची सही', style: mrB),
                const SizedBox(height: 36),
                _uField(v('dpAmaldaarSig'), width: 140),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('तपासी अधिकारी नांव व सही शिक्का', style: mrB),
                const SizedBox(height: 8),
                Row(children: [Text('नांव :- ', style: mrB), Expanded(child: _uField(v('dpIoName')))]),
                const SizedBox(height: 4),
                Row(children: [Text('हुद्दा :- ', style: mrB), Expanded(child: _uField(v('dpIoRank')))]),
                const SizedBox(height: 4),
                Row(children: [Text('पोलीस स्टेशन :- ', style: mrB), Expanded(child: _uField(v('dpIoPs')))]),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.bottomRight,
        child: Text('M.R.W', style: FormImagePdfHelper.mReg(8)),
      ),
    ],
  );
}

Widget _buildInquestMainPg1Widget(Map<String, dynamic> doc, {bool isExhumation = false}) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final engBold = GoogleFonts.lora(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.black);
  final engStyle = GoogleFonts.lora(fontSize: 8.5, color: Colors.black87);
  final mrStyle = FormImagePdfHelper.mReg(7.5, 1.2);

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
    children: [
      Center(
        child: Column(
          children: [
            Text(
              isExhumation ? 'EXHUMATION PANCHANAMA' : 'INQUEST PANCHANAMA',
              style: GoogleFonts.lora(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              isExhumation ? 'कबर खोदून शव बाहेर काढण्याचा पंचनामा (Exhumation Panchanama)' : 'मरणोत्तर पंचनामा',
              style: FormImagePdfHelper.mBld(10),
            ),
            const SizedBox(height: 1),
            Text('(Under Section - 194 B.N.S.S.)', style: GoogleFonts.lora(fontSize: 8.5, fontWeight: FontWeight.bold)),
            Text('( भारतीय नागरिक सुरक्षा संहिता २०२३ कलम १९४ अन्वये.)', style: FormImagePdfHelper.mReg(8)),
          ],
        ),
      ),
      const SizedBox(height: 4),
      const Divider(color: Colors.black, thickness: 0.8),
      const SizedBox(height: 4),

      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 2,
        runSpacing: 2,
        children: [
          Text('1) Dist. (YAVATMAL)', style: engBold),
          const SizedBox(width: 16),
          Text('P.S.:-', style: engBold),
          _uField(v('ps'), width: 100),
          Text('Year:-20', style: engBold),
          _uField(v('year'), width: 35),
          const SizedBox(width: 8),
          Text('FIR/AD/U.D.No:-', style: engBold),
          _uField(v('firNo'), width: 90),
        ],
      ),
      Text('   जिल्हा - यवतमाळ             पो.स्टे.             वर्ष                     पहिली खबर क्र./ अकस्मात मृत्यू क्र.', style: mrStyle),
      const SizedBox(height: 5),

      Row(
        children: [
          Text('2) Act and Section: - ', style: engBold),
          Expanded(child: _uField(v('actSections'))),
        ],
      ),
      Text('   अधिनियम व कलमे :-', style: mrStyle),
      const SizedBox(height: 5),

      Row(
        children: [
          Text('3) Place From where Dead Body Found/Traced : ', style: engBold),
          Expanded(child: _uField(v('deadBodyFoundPlace'))),
        ],
      ),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 2,
        runSpacing: 2,
        children: [
          Text('   प्रेत सापडल्याचे /मिळाल्याचे ठिकाण / जागा     ', style: mrStyle),
          Text('Place:-', style: engStyle),
          _uField(v('foundPlace'), width: 100),
          Text('Date:', style: engStyle),
          _uField(v('foundDate'), width: 65),
          Text(' time:', style: engStyle),
          _uField(v('foundTime'), width: 55),
        ],
      ),
      const SizedBox(height: 5),

      Row(
        children: [
          Text('4) By whom Dead Body Shown                   :', style: engBold),
          Expanded(child: _uField(v('shownBy'))),
        ],
      ),
      Text('   प्रेत कोणी दाखविले :-', style: mrStyle),
      const SizedBox(height: 5),

      Row(
        children: [
          Text('5) By whom Dead Body Identified              :', style: engBold),
          Expanded(child: _uField(v('identifiedBy'))),
        ],
      ),
      Text('   प्रेत कोणी ओळखले :-', style: mrStyle),
      _multilineBox(v('identifiedBy2'), lines: 2),
      const SizedBox(height: 5),

      Row(
        children: [
          Text('a) Dead Body Male/Female                     :', style: engBold),
          Expanded(child: _uField(v('gender'))),
        ],
      ),
      Text('   अ) प्रेत स्त्री / पुरुष जातीचे :-', style: mrStyle),
      const SizedBox(height: 5),

      Row(
        children: [
          Text('6) b) Dead Body Married/Unmarried            :', style: engBold),
          Expanded(child: _uField(v('married'))),
        ],
      ),
      Text('   ब) प्रेत विवाहीत /अविवाहीत आहे :-', style: mrStyle),
      const SizedBox(height: 5),

      Row(
        children: [
          Text('c) Age of Dead Body                          :', style: engBold),
          Expanded(child: _uField(v('age'))),
        ],
      ),
      Text('   क) प्रेताचे वय :-', style: mrStyle),
      const SizedBox(height: 5),

      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 2,
        runSpacing: 2,
        children: [
          Text('   ड) मृत्यूची तारीख वेळ :-                     ', style: mrStyle),
          Text('Date : ', style: engStyle),
          _uField(v('deathDate'), width: 90),
          const SizedBox(width: 15),
          Text('Time : ', style: engStyle),
          _uField(v('deathTime'), width: 90),
        ],
      ),
      Text('                                                तारीख                                   वेळ', style: mrStyle),
      const SizedBox(height: 5),

      Row(
        children: [
          Text('7) Position of Dead Body                     :', style: engBold),
          Expanded(child: _uField(v('positionOfBody'))),
        ],
      ),
      Text('   प्रेताची स्थिती / अवस्था (जागा)', style: mrStyle),
      _multilineBox(v('positionOfBody2'), lines: 2),

      const Spacer(),
      Align(
        alignment: Alignment.centerRight,
        child: Text('M.R.W', style: GoogleFonts.lora(fontSize: 8, fontStyle: FontStyle.italic)),
      ),
    ],
  );
}

Widget _buildInquestMainPg2Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final engBold = GoogleFonts.lora(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.black);
  final mrStyle = FormImagePdfHelper.mReg(7.5, 1.2);

  Widget injuryRow(String labelEn, String labelMr, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(width: 90, child: Text(labelEn, style: engBold)),
              Expanded(child: _uField(val)),
            ],
          ),
          Text('   $labelMr', style: mrStyle),
        ],
      ),
    );
  }

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
    children: [
      Row(
        children: [
          Text('8) Name and Address of Dead Body             :', style: engBold),
          Expanded(child: _uField(v('nameAddressDeceased'))),
        ],
      ),
      Text('   प्रेताचे संपूर्ण नांव व पत्ता (माहित असल्यास)', style: mrStyle),
      _multilineBox(v('nameAddressDeceased2'), lines: 3),
      const SizedBox(height: 6),

      Row(
        children: [
          Text('9) Description Of injuries Found on Dead Body if any :', style: engBold),
          Expanded(child: _uField(v('injDescription'))),
        ],
      ),
      Text('   प्रेताचे अंगावर असल्यास त्याचे वर्णन :', style: mrStyle),
      const SizedBox(height: 5),

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

      const Spacer(),
      Align(
        alignment: Alignment.centerRight,
        child: Text('M.R.W', style: GoogleFonts.lora(fontSize: 8, fontStyle: FontStyle.italic)),
      ),
    ],
  );
}

Widget _buildInquestMainPg3Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final engBold = GoogleFonts.lora(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.black);
  final engStyle = GoogleFonts.lora(fontSize: 8.5, color: Colors.black87);
  final mrStyle = FormImagePdfHelper.mReg(7.5, 1.2);

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
    children: [
      Text('10)   Injuries of Dead Body Caused By Accidental/Violence :', style: engBold),
      Row(
        children: [
          Text('Homicide / Other Burn / (Fair / Tejab) ', style: engBold.copyWith(fontSize: 8)),
          Expanded(child: _uField(v('injAccidentalViolence'))),
        ],
      ),
      Text('प्रेताचे अंगावरील जखमा अपघाताच्या घोक्यातील / इत्यादी', style: mrStyle),
      Text('होण्यामुळे झाल्या', style: mrStyle),
      const SizedBox(height: 5),

      Row(
        children: [
          Text('11) Weapon / Means (if any)                  :', style: engBold),
          Expanded(child: _uField(v('weaponMeans'))),
        ],
      ),
      Text('जखमा केलेल्या हत्यार/ साधन असल्यास           :', style: mrStyle),
      const SizedBox(height: 5),

      Row(
        children: [
          Text('12) Dead Body Cool / Warm                    :', style: engBold),
          Expanded(child: _uField(v('bodyCoolWarm'))),
        ],
      ),
      Text('प्रेत थंड आहे/ गरम आहे.                       :', style: mrStyle),
      const SizedBox(height: 5),

      Row(
        children: [
          Text('13) Position Dead Body by Poisoning          :', style: engBold),
          Expanded(child: _uField(v('poisoningPosition'))),
        ],
      ),
      Text('प्रेताची स्थिती विष प्राशन केलेला असल्यास       :', style: mrStyle),
      const SizedBox(height: 5),

      Text('14) (a) Finger Print has taken by Doctor Not taken Reason', style: engBold),
      Row(
        children: [
          Text('(In case of unidentified Dead Body)          :', style: engStyle),
          Expanded(child: _uField(v('fingerprintReason'))),
        ],
      ),
      Text('अनोळखी प्रेताचे डॉक्टरांकडून बोटांचे ठसे घेतले/ नाही कारण :', style: mrStyle),
      const SizedBox(height: 3),

      Text('(b) Photo has taken/not taken reason (In case of an', style: engBold),
      Row(
        children: [
          Text('Identified Dead Body)                        :', style: engStyle),
          Expanded(child: _uField(v('photoReason'))),
        ],
      ),
      Text('अनोळखी प्रेताचे फोटो घेतले आहेत काय/नाही कारण :', style: mrStyle),
      const SizedBox(height: 5),

      Row(
        children: [
          Text('15) Dead Body sent to P.M. / not reason: ', style: engBold),
          Expanded(child: _uField(v('sentToPMReason'))),
        ],
      ),
      Text('प्रेत (पोस्ट मार्टम) शविच्छेदन करीता पाठविले/ नाही कारण', style: mrStyle),
      const SizedBox(height: 3),

      Row(
        children: [
          Text('(a) At which Hospital Dead Body sent to P.M.:', style: engBold),
          Expanded(child: _uField(v('hospitalName'))),
        ],
      ),
      Text('कोणत्या रूग्णालयात प्रेत पोस्ट मार्टूम करीता पाठविले :', style: mrStyle),
      const SizedBox(height: 3),

      Text('(b) With whom (Name No. and P.sm)            :', style: engBold),
      Text('कोणा बरोबर पाठविले (नांव व पो.स्टे.)', style: mrStyle),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 2,
        runSpacing: 2,
        children: [
          Text('Name : ', style: engStyle),
          _uField(v('sentOfficerName'), width: 160),
          Text('B/No:-', style: engStyle),
          _uField(v('sentOfficerBNo'), width: 70),
          Text('P.S. : ', style: engStyle),
          _uField(v('sentOfficerPs'), width: 100),
        ],
      ),
      Text('नांव                                        बक्कल नंबर                 पो.स्टे', style: mrStyle),
      const SizedBox(height: 5),

      Row(
        children: [
          Text('16) Opinion of Panchas and Police about Death: ', style: engBold),
          Expanded(child: _uField(v('opinionPanchas'))),
        ],
      ),
      Text('पंच व पोलीसांचा मृत्यूविषयी अभिप्राय', style: mrStyle),
      _multilineBox(v('opinionPanchas2'), lines: 3),
      const SizedBox(height: 5),

      Row(
        children: [
          Text('17) More information if any                 : ', style: engBold),
          Expanded(child: _uField(v('moreInfo'))),
        ],
      ),
      Text('अधिक माहिती असल्यास', style: mrStyle),

      const Spacer(),
      Align(
        alignment: Alignment.centerRight,
        child: Text('M.R.W', style: GoogleFonts.lora(fontSize: 8, fontStyle: FontStyle.italic)),
      ),
    ],
  );
}

Widget _buildInquestMainPg4Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final engBold = GoogleFonts.lora(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.black);
  final engStyle = GoogleFonts.lora(fontSize: 8.5, color: Colors.black87);
  final mrStyle = FormImagePdfHelper.mReg(7.5, 1.2);

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
    children: [
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 2,
        runSpacing: 2,
        children: [
          Text('18) Date and Time of panchanama    ', style: engBold),
          Text('Date : -', style: engStyle),
          _uField(v('panchanamaDate'), width: 80),
          const SizedBox(width: 10),
          Text('Time:', style: engStyle),
          _uField(v('panchanamaTime'), width: 55),
          Text('  To ', style: engStyle),
          _uField(v('panchanamaTimeTo'), width: 55),
        ],
      ),
      Text('    पंचनामा केल्याची               दिनांक : -                       वेळ : -                 ते', style: mrStyle),
      const SizedBox(height: 8),

      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('19) Name of Panchas and Signature: -', style: engBold),
                Text('    पंचनामा करणाऱ्या पंचांची नांवे : -', style: mrStyle),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Signature: -', style: engBold),
                Text('सह्या : -', style: mrStyle),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),

      // Panch 1
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                Text('1) ', style: engBold),
                Expanded(child: _multilineBox(v('panch1'), lines: 2)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Text('1) ', style: engBold),
                Expanded(child: _uField(v('panch1Sig'))),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),

      // Panch 2
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                Text('2) ', style: engBold),
                Expanded(child: _multilineBox(v('panch2'), lines: 2)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Text('2) ', style: engBold),
                Expanded(child: _uField(v('panch2Sig'))),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),

      // Panch 3
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                Text('3) ', style: engBold),
                Expanded(child: _multilineBox(v('panch3'), lines: 2)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Text('3) ', style: engBold),
                Expanded(child: _uField(v('panch3Sig'))),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),

      // IO Signature Block
      Row(
        children: [
          const Spacer(),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Signature of Investigation Officer', style: engBold),
                Text('तपासणी करणाऱ्या अधिकाऱ्यांची नांव व सह्या', style: mrStyle),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Name: ', style: engStyle),
                    Expanded(child: _uField(v('ioName'))),
                  ],
                ),
                Text('नांव', style: mrStyle),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text('Rank: ', style: engStyle),
                    _uField(v('ioRank'), width: 80),
                    const SizedBox(width: 4),
                    Text('Number if any:', style: engStyle),
                    Expanded(child: _uField(v('ioNo'))),
                  ],
                ),
                Text('पद                   बक्कल नंबर', style: mrStyle),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text('Posting and Address:', style: engStyle),
                    Expanded(child: _uField(v('ioPosting'))),
                  ],
                ),
                Text('नेमणूक व पत्ता', style: mrStyle),
              ],
            ),
          ),
        ],
      ),

      const Spacer(),
      Align(
        alignment: Alignment.centerRight,
        child: Text('M.R.W', style: GoogleFonts.lora(fontSize: 8, fontStyle: FontStyle.italic)),
      ),
    ],
  );
}

Widget _buildMarananveshanPg1Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final mrB = FormImagePdfHelper.mBld(8.5, 1.25);

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
    children: [
      Center(
        child: Text(
          'मरणा-न्वेषण पंचनामा',
          style: FormImagePdfHelper.mBld(14).copyWith(
            decoration: TextDecoration.underline,
          ),
        ),
      ),
      const SizedBox(height: 8),

      // Top Right: ठिकाण, दिनांक, सुरू केल्याची वेळ
      Align(
        alignment: Alignment.topRight,
        child: SizedBox(
          width: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('ठिकाण : ', style: mrB),
                Expanded(child: _uField(v('marThikan'))),
              ]),
              const SizedBox(height: 2),
              Row(children: [
                Text('दिनांक : ', style: mrB),
                Expanded(
                  child: _uField(
                    v('marDate').isEmpty
                        ? '......./ ......./ २०.........'
                        : v('marDate'),
                  ),
                ),
              ]),
              const SizedBox(height: 2),
              Row(children: [
                Text('सुरू केल्याची वेळ: ', style: mrB),
                Expanded(
                  child: _uField(
                    v('marTime').isEmpty
                        ? '........./ .........'
                        : v('marTime'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),

      // १) पंचाचे नांव व पत्ता :-
      Text('१) पंचाचे नांव व पत्ता :-', style: mrB),
      const SizedBox(height: 1),
      _multilineBox(v('marPanchNameAddress'), lines: 3),
      const SizedBox(height: 4),

      // २) पोलीस स्टेशन ________ जिल्हा : ________
      Row(
        children: [
          Text('२) पोलीस स्टेशन ', style: mrB),
          Expanded(child: _uField(v('marPs'))),
          const SizedBox(width: 16),
          Text('जिल्हा : ', style: mrB),
          Expanded(child: _uField(v('marDist'))),
        ],
      ),
      const SizedBox(height: 4),

      // ३) अकस्मात मृत्यु/गुन्हा/ठाणे दैनंदिनी क्र:-
      Row(
        children: [
          Text('३) अकस्मात मृत्यु/गुन्हा/ठाणे दैनंदिनी क्र:-', style: mrB),
          Expanded(child: _uField(v('marDiaryNo'))),
        ],
      ),
      const SizedBox(height: 4),

      // ४) अधिनियम व कलम :-
      Row(
        children: [
          Text('४) अधिनियम व कलम :-', style: mrB),
          Expanded(child: _uField(v('marActSec'))),
        ],
      ),
      const SizedBox(height: 4),

      // ५) अन्वेषण अधिकाऱ्याचे नांव, हुद्दा :-
      Text('५) अन्वेषण अधिकाऱ्याचे नांव, हुद्दा :-', style: mrB),
      const SizedBox(height: 1),
      _multilineBox(v('marIoDetails'), lines: 2),
      const SizedBox(height: 4),

      // ६) फिर्यादीचे नांव :-
      Text('६) फिर्यादीचे नांव :-', style: mrB),
      const SizedBox(height: 1),
      _multilineBox(v('marComplainantName'), lines: 2),
      const SizedBox(height: 4),

      // ७) मृतकाचे नांव व पत्ता :-
      Text('७) मृतकाचे नांव व पत्ता :-', style: mrB),
      const SizedBox(height: 1),
      _multilineBox(v('marDeceasedNameAddress'), lines: 2),
      const SizedBox(height: 4),

      // ८) प्रेत दाखविणाऱ्याचे/ओळखणाऱ्याचे नांव :-
      Text('८) प्रेत दाखविणाऱ्याचे/ओळखणाऱ्याचे नांव :-', style: mrB),
      const SizedBox(height: 1),
      _multilineBox(v('marShownByName'), lines: 2),
      const SizedBox(height: 4),

      // ९) प्रेत ठेवले आहे त्या ठिकाणाचे वर्णन :-
      Text('९) प्रेत ठेवले आहे त्या ठिकाणाचे वर्णन :-', style: mrB),
      const SizedBox(height: 1),
      _multilineBox(v('marThikanDescription'), lines: 2),
      const SizedBox(height: 4),

      // १०) प्रेताची स्थिती:-
      Text('१०) प्रेताची स्थिती:-', style: mrB),
      const SizedBox(height: 1),
      _multilineBox(v('marBodyCondition'), lines: 3),
      const SizedBox(height: 4),

      // ११) प्रेताचे अंगावरील कपड्याचे वर्णन :-
      Text('११) प्रेताचे अंगावरील कपड्याचे वर्णन :-', style: mrB),
      const SizedBox(height: 1),
      _multilineBox(v('marBodyClothes'), lines: 2),
      const SizedBox(height: 4),

      // १२) प्रेताचे अंगावरील दागीने व इतर वस्तु :-
      Text('१२) प्रेताचे अंगावरील दागीने व इतर वस्तु :-', style: mrB),
      const SizedBox(height: 1),
      _multilineBox(v('marBodyOrnaments'), lines: 2),

      const Spacer(),
      Align(
        alignment: Alignment.bottomRight,
        child: Text('M.R.W', style: FormImagePdfHelper.mReg(8)),
      ),
    ],
  );
}

Widget _buildMarananveshanPg2Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final mrB = FormImagePdfHelper.mBld(8.5, 1.25);

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
    children: [
      // १३) मृतकाच्या शरीरावरील मार, जखमा इत्यादी :-
      Text('१३) मृतकाच्या शरीरावरील मार, जखमा इत्यादी :-', style: mrB),
      const SizedBox(height: 1),
      _multilineBox(v('mar13Injuries'), lines: 4),
      const SizedBox(height: 6),

      // १४) प्रेतावरील इतर खुणा...
      Text(
        '१४) प्रेतावरील इतर खुणा, लघवी, विर्यपतन, विष्टा किंवा वांती झाली काय ? तपासणीकरीता नमुने घेतले काय सविस्तर उल्लेख करावा :-',
        style: mrB,
      ),
      const SizedBox(height: 1),
      _multilineBox(v('mar14OtherMarks'), lines: 4),
      const SizedBox(height: 6),

      // १५) मृतकाचे अंगावरील दागीने...
      Text(
        '१५) मृतकाचे अंगावरील दागीने व इतर वस्तुंची काय विल्हेवाट लावली :-',
        style: mrB,
      ),
      const SizedBox(height: 1),
      _multilineBox(v('mar15OrnamentsDisposal'), lines: 3),
      const SizedBox(height: 6),

      // १६) पंच व अन्वेषण अधिकारी यांचा अभिप्राय :-
      Text('१६) पंच व अन्वेषण अधिकारी यांचा अभिप्राय :-', style: mrB),
      const SizedBox(height: 1),
      _multilineBox(v('mar16Opinion'), lines: 3),
      const SizedBox(height: 6),

      // १७) प्रेताची काय विल्हेवाट लावली ? :-
      Text('१७) प्रेताची काय विल्हेवाट लावली ? :-', style: mrB),
      const SizedBox(height: 1),
      _multilineBox(v('mar17BodyDisposal'), lines: 3),
      const SizedBox(height: 6),

      // १८) पंचनामा संपविल्याची दिनांक व वेळ :-
      Text('१८) पंचनामा संपविल्याची दिनांक व वेळ :-', style: mrB),
      const SizedBox(height: 1),
      _multilineBox(v('mar18DateTime'), lines: 2),
      const SizedBox(height: 14),

      // Signatures Section
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: पंचाची सही
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('पंचाची सही', style: FormImagePdfHelper.mBld(9.5)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('१)- ', style: mrB),
                    Expanded(child: _uField(v('mar11Panch1'))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('२)- ', style: mrB),
                    Expanded(child: _uField(v('mar11Panch2'))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('३)- ', style: mrB),
                    Expanded(child: _uField(v('mar11Panch3'))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('४)- ', style: mrB),
                    Expanded(child: _uField(v('mar11Panch4'))),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('प्रत सादर :- मा.वैद्यकीय अधिकारी ', style: FormImagePdfHelper.mBld(8)),
                    Expanded(child: _uField(v('mar11CopyTo'))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),

          // Right Column: तपासी अधिकारी नांव व सही शिक्का
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('तपासी अधिकारी नांव व सही शिक्का', style: FormImagePdfHelper.mBld(9.5)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('नांव :- ', style: mrB),
                    Expanded(child: _uField(v('mar11IoName'))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('हुद्दा :- ', style: mrB),
                    Expanded(child: _uField(v('mar11IoRank'))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('पोलीस स्टेशन :- ', style: mrB),
                    Expanded(child: _uField(v('mar11IoPs'))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),

      const Spacer(),
      Align(
        alignment: Alignment.bottomRight,
        child: Text('M.R.W', style: FormImagePdfHelper.mReg(8)),
      ),
    ],
  );
}

