import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../widgets/form_section_utils.dart';
import 'form_image_pdf_helper.dart';
import 'form_io_terminology.dart';
import 'pdf_font_cache.dart';

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
      width: FormImagePdfHelper.a4Width,
      height: FormImagePdfHelper.a4Height,
      fallbackPdfGenerator: () => generateInquestPanchanamaPdf(doc),
    );
    return;
  }
  if (active == 'Relative Summons 179') {
    await FormImagePdfHelper.previewImageBasedPdf(
      context,
      fileName: 'Relative_Summons_${DateTime.now().millisecondsSinceEpoch}.pdf',
      pages: [_buildRelativeSummonsWidget(doc)],
      width: FormImagePdfHelper.a4Width,
      height: FormImagePdfHelper.a4Height,
      fallbackPdfGenerator: () => generateInquestPanchanamaPdf(doc),
    );
    return;
  }
  if (active == 'Pancha Summons 195') {
    await FormImagePdfHelper.previewImageBasedPdf(
      context,
      fileName: 'Pancha_Summons_${DateTime.now().millisecondsSinceEpoch}.pdf',
      pages: [_buildPanchaSummonsWidget(doc)],
      width: FormImagePdfHelper.a4Width,
      height: FormImagePdfHelper.a4Height,
      fallbackPdfGenerator: () => generateInquestPanchanamaPdf(doc),
    );
    return;
  }
  if (active == 'Civil Surgeon PM Report' ||
      active == 'Police Report to Civil Surgeon for PM' ||
      (active != null && active.contains('Civil Surgeon'))) {
    await FormImagePdfHelper.previewImageBasedPdf(
      context,
      fileName:
          'Medical_Officer_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      pages: [
        _buildCivilSurgeonPg1Widget(doc),
        _buildCivilSurgeonPg2Widget(doc)
      ],
      width: FormImagePdfHelper.a4Width,
      height: FormImagePdfHelper.a4Height,
      fallbackPdfGenerator: () => generateInquestPanchanamaPdf(doc),
    );
    return;
  }
  if (active == '14 Kalmi Form' || active == '14-Kalmi Form with Inquest') {
    await FormImagePdfHelper.previewImageBasedPdf(
      context,
      fileName: '14_Kalmi_Form_${DateTime.now().millisecondsSinceEpoch}.pdf',
      pages: [_buildKalmi14Pg1Widget(doc), _buildKalmi14Pg2Widget(doc)],
      width: FormImagePdfHelper.a4Width,
      height: FormImagePdfHelper.a4Height,
      fallbackPdfGenerator: () => generateInquestPanchanamaPdf(doc),
    );
    return;
  }
  if (active == 'Dead Body Handover') {
    await FormImagePdfHelper.previewImageBasedPdf(
      context,
      fileName:
          'Dead_Body_Handover_${DateTime.now().millisecondsSinceEpoch}.pdf',
      pages: [_buildDeadBodyHandoverWidget(doc)],
      width: FormImagePdfHelper.a4Width,
      height: FormImagePdfHelper.a4Height,
      fallbackPdfGenerator: () => generateInquestPanchanamaPdf(doc),
    );
    return;
  }
  if (active == 'Duty Pass') {
    await FormImagePdfHelper.previewImageBasedPdf(
      context,
      fileName: 'Duty_Pass_${DateTime.now().millisecondsSinceEpoch}.pdf',
      pages: [_buildDutyPassWidget(doc)],
      width: FormImagePdfHelper.a4Width,
      height: FormImagePdfHelper.a4Height,
      fallbackPdfGenerator: () => generateInquestPanchanamaPdf(doc),
    );
    return;
  }
  if (active == 'Marananveshan Panchanama' ||
      active == 'Marananveshan' ||
      (active != null && active.contains('Marananveshan'))) {
    await FormImagePdfHelper.previewImageBasedPdf(
      context,
      fileName:
          'Marananveshan_Panchanama_${DateTime.now().millisecondsSinceEpoch}.pdf',
      pages: [
        _buildMarananveshanPg1Widget(doc),
        _buildMarananveshanPg2Widget(doc)
      ],
      width: FormImagePdfHelper.a4Width,
      height: FormImagePdfHelper.a4Height,
      fallbackPdfGenerator: () => generateInquestPanchanamaPdf(doc),
    );
    return;
  }
  if (active == 'Exhumation Panchanama' ||
      active == 'Exhumation' ||
      (active != null && active.contains('Exhumation'))) {
    await FormImagePdfHelper.previewImageBasedPdf(
      context,
      fileName:
          'Exhumation_Panchanama_${DateTime.now().millisecondsSinceEpoch}.pdf',
      pages: _buildExhumationPages(doc),
      width: FormImagePdfHelper.a4Width,
      height: FormImagePdfHelper.a4Height,
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
      _buildInquestMainPg2Widget(doc, isExhumation: false),
      _buildInquestMainPg3Widget(doc),
      _buildInquestMainPg4Widget(doc),
    ],
    width: FormImagePdfHelper.a4Width,
    height: FormImagePdfHelper.a4Height,
    fallbackPdfGenerator: () => generateInquestPanchanamaPdf(doc),
  );
}

Future<Uint8List> generateInquestPanchanamaPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();

  final loraRegular = await PdfFontCache.loraRegular();
  final loraBold = await PdfFontCache.loraBold();
  final devanagariRegular = await PdfFontCache.devanagariRegular();
  final devanagariBold = await PdfFontCache.devanagariBold();

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
    'Police Report to Civil Surgeon for PM',
    'Vinanti Arj',
    'Relative Summons 179',
    'Pancha Summons 195',
    'Marananveshan Panchanama',
    '14 Kalmi Form',
    'Dead Body Handover',
    'Duty Pass',
  };
  final activeSection = doc['formSection']?.toString();
  final isCivilSurgeon = activeSection == 'Civil Surgeon PM Report' ||
      activeSection == 'Police Report to Civil Surgeon for PM' ||
      (activeSection != null && activeSection.contains('Civil Surgeon'));

  bool showsSection(String sectionId) => showsFormSection(
        activeSection: activeSection,
        sectionId: sectionId,
        knownSectionIds: knownSectionIds,
      );

  pw.Widget underlineField(String text, {double? width, double minWidth = 20}) {
    return pw.Container(
      constraints: pw.BoxConstraints(minWidth: width ?? minWidth),
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
        maxLines: lines,
        overflow: pw.TextOverflow.clip,
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
  final isExhumation = activeSection == 'Exhumation Panchanama' ||
      activeSection == 'Exhumation' ||
      (activeSection != null && activeSection.contains('Exhumation'));
  if (isExhumation) {
    _generateExhumationVectorPdf(
      pdf,
      doc,
      loraRegular: loraRegular,
      loraBold: loraBold,
      devanagariRegular: devanagariRegular,
      devanagariBold: devanagariBold,
    );
    return pdf.save();
  }
  if (showsSection('Inquest Main') && !isCivilSurgeon) {
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
                  pw.Text(
                      isExhumation
                          ? 'EXHUMATION PANCHANAMA'
                          : 'INQUEST PANCHANAMA',
                      style:
                          engBold.copyWith(fontSize: isExhumation ? 12 : 13.5)),
                  pw.Text(
                      isExhumation
                          ? 'कबर खोदून शव बाहेर काढण्याचा पंचनामा (Exhumation Panchanama)'
                          : 'मरणोत्तर पंचनामा',
                      style:
                          mrBold.copyWith(fontSize: isExhumation ? 10 : 11.5)),
                  pw.SizedBox(height: 2),
                  pw.Text('(Under Section - 194 B.N.S.S.)',
                      style:
                          engBold.copyWith(fontSize: isExhumation ? 8.5 : 9.5)),
                  pw.Text(
                      '( भारतीय नागरिक सुरक्षा संहिता २०२३ कलम १९४ अन्वये.)',
                      style: mrBold.copyWith(fontSize: isExhumation ? 8 : 9.0)),
                ],
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Divider(color: PdfColors.black, thickness: 0.8),
            pw.SizedBox(height: 6),

            // 1) Dist, PS, Year, FIR
            if (isExhumation) ...[
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Text('1) Dist. :- ', style: engBold),
                            pw.Expanded(child: underlineField(v('dist'))),
                          ],
                        ),
                        pw.SizedBox(height: 2),
                        subLabel('   जिल्हा'),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Text('P.S. :- ', style: engBold),
                            pw.Expanded(child: underlineField(v('ps'))),
                          ],
                        ),
                        pw.SizedBox(height: 2),
                        subLabel('   पो.स्टे.'),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Text('Year :- 20', style: engBold),
                            pw.Expanded(child: underlineField(v('year'))),
                          ],
                        ),
                        pw.SizedBox(height: 2),
                        subLabel('   वर्ष'),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 6,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Text('FIR/AD/U.D.No :- ', style: engBold),
                            pw.Expanded(child: underlineField(v('firNo'))),
                          ],
                        ),
                        pw.SizedBox(height: 2),
                        subLabel('   पहिली खबर क्र./ अकस्मात मृत्यू क्र.'),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 24),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Text('Date :- ', style: engBold),
                            pw.Expanded(
                              child: underlineField(
                                v('firDate').isNotEmpty
                                    ? v('firDate')
                                    : v('date'),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 2),
                        subLabel('   दिनांक'),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 1.0),
                    child: pw.Text('1) Dist.:- ',
                        style: engBold.copyWith(fontSize: 10.0)),
                  ),
                  underlineField(v('dist'), width: 100),
                  pw.SizedBox(width: 16),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 1.0),
                    child: pw.Text('P.S.:- ',
                        style: engBold.copyWith(fontSize: 10.0)),
                  ),
                  pw.Expanded(child: underlineField(v('ps'))),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 1.0),
                    child: pw.Text('   Year:-20',
                        style: engBold.copyWith(fontSize: 10.0)),
                  ),
                  underlineField(v('year'), width: 50),
                  pw.SizedBox(width: 16),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 1.0),
                    child: pw.Text('FIR/AD/U.D.No:- ',
                        style: engBold.copyWith(fontSize: 10.0)),
                  ),
                  pw.Expanded(child: underlineField(v('firNo'))),
                ],
              ),
              pw.SizedBox(height: 4),
              subLabel(
                  '   जिल्हा - .........             पो.स्टे.             वर्ष                     पहिली खबर क्र./ अकस्मात मृत्यू क्र.'),
            ],
            pw.SizedBox(height: isExhumation ? 6 : 14),

            // 2) Act and Section
            pw.Row(
              children: [
                pw.Text('2) Act and Section: - ',
                    style: engBold.copyWith(fontSize: 10.0)),
                pw.Expanded(child: underlineField(v('actSections'))),
              ],
            ),
            pw.SizedBox(height: 3),
            subLabel('   अधिनियम व कलमे :-'),
            pw.SizedBox(height: isExhumation ? 6 : 14),

            // 3) Place where body found
            pw.Row(
              children: [
                pw.Text('3) Place From where Dead Body Found/Traced : ',
                    style: engBold.copyWith(fontSize: 10.0)),
                pw.Expanded(child: underlineField(v('deadBodyFoundPlace'))),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              spacing: 2,
              runSpacing: 2,
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.only(right: 8),
                  child: pw.Text('   Place:-',
                      style: engStyle.copyWith(fontSize: 9.5)),
                ),
                underlineField(v('foundPlace'), width: 100),
                pw.SizedBox(width: 10),
                pw.Text('Date:', style: engStyle.copyWith(fontSize: 9.5)),
                underlineField(v('foundDate'), width: 85),
                pw.SizedBox(width: 10),
                pw.Text(' time:', style: engStyle.copyWith(fontSize: 9.5)),
                underlineField(v('foundTime'), width: 65),
              ],
            ),
            pw.SizedBox(height: 3),
            subLabel('   प्रेत सापडल्याचे /मिळाल्याचे ठिकाण / जागा'),
            pw.SizedBox(height: isExhumation ? 6 : 14),

            // 4) By whom shown
            pw.Row(
              children: [
                pw.Text('4) By whom Dead Body Shown                   :',
                    style: engBold.copyWith(fontSize: 10.0)),
                pw.Expanded(child: underlineField(v('shownBy'))),
              ],
            ),
            pw.SizedBox(height: 3),
            subLabel('   प्रेत कोणी दाखविले :-'),
            pw.SizedBox(height: isExhumation ? 6 : 14),

            // 5) By whom identified
            pw.Row(
              children: [
                pw.Text('5) By whom Dead Body Identified              :',
                    style: engBold.copyWith(fontSize: 10.0)),
                pw.Expanded(child: underlineField(v('identifiedBy'))),
              ],
            ),
            pw.SizedBox(height: 3),
            subLabel('   प्रेत कोणी ओळखले :-'),
            pw.SizedBox(height: 4),
            multilineBox(v('identifiedBy2'), lines: 2),
            pw.SizedBox(height: isExhumation ? 6 : 14),

            // a) Male/Female
            pw.Row(
              children: [
                pw.Text('a) Dead Body Male/Female                     :',
                    style: engBold.copyWith(fontSize: 10.0)),
                pw.Expanded(child: underlineField(v('gender'))),
              ],
            ),
            pw.SizedBox(height: 2),
            subLabel('   अ) प्रेत स्त्री / पुरुष जातीचे :-'),
            pw.SizedBox(height: isExhumation ? 6 : 10),

            // 6) b) Married/Unmarried
            pw.Row(
              children: [
                pw.Text('6) b) Dead Body Married/Unmarried            :',
                    style: engBold.copyWith(fontSize: 10.0)),
                pw.Expanded(child: underlineField(v('married'))),
              ],
            ),
            pw.SizedBox(height: 2),
            subLabel('   ब) प्रेत विवाहीत /अविवाहीत आहे :-'),
            pw.SizedBox(height: isExhumation ? 6 : 10),

            // c) Age
            pw.Row(
              children: [
                pw.Text('c) Age of Dead Body                          :',
                    style: engBold.copyWith(fontSize: 10.0)),
                pw.Expanded(child: underlineField(v('age'))),
              ],
            ),
            pw.SizedBox(height: 2),
            subLabel('   क) प्रेताचे वय :-'),
            pw.SizedBox(height: isExhumation ? 6 : 10),

            // d) Date & Time of Death
            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              spacing: 2,
              runSpacing: 2,
              children: [
                subLabel('   ड) मृत्यूची तारीख वेळ :-                     '),
                pw.Text('Date : ', style: engStyle.copyWith(fontSize: 9.5)),
                underlineField(v('deathDate'), width: 90),
                pw.SizedBox(width: 16),
                pw.Text('Time : ', style: engStyle.copyWith(fontSize: 9.5)),
                underlineField(v('deathTime'), width: 65),
              ],
            ),
            pw.SizedBox(height: 2),
            subLabel(
                '                                                तारीख                                   वेळ'),
            pw.SizedBox(height: isExhumation ? 6 : 14),

            // 7) Position
            pw.Row(
              children: [
                pw.Text('7) Position of Dead Body                     :',
                    style: engBold.copyWith(fontSize: 10.0)),
                pw.Expanded(child: underlineField(v('positionOfBody'))),
              ],
            ),
            pw.SizedBox(height: 3),
            subLabel('   प्रेत ची स्थिती / अवस्था (जागा)'),
            pw.SizedBox(height: 4),
            multilineBox(v('positionOfBody2'), lines: 2),

            pw.SizedBox(height: 14),
            pw.Row(
              children: [
                pw.Text('8) Name and Address of Dead Body             :',
                    style: engBold.copyWith(fontSize: 10.0)),
                pw.Expanded(child: underlineField(v('nameAddressDeceased'))),
              ],
            ),
            pw.SizedBox(height: 3),
            subLabel('   प्रेताचे संपूर्ण नांव व पत्ता (माहित असल्यास)'),
            pw.SizedBox(height: 4),
            multilineBox(v('nameAddressDeceased2'), lines: 3),

            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('M.R.W',
                  style: engStyle.copyWith(
                      fontSize: isExhumation ? 8 : 9.5,
                      fontStyle: pw.FontStyle.italic)),
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
            // 9) Description of injuries
            pw.Row(
              children: [
                pw.Text(
                    '9) Description Of injuries Found on Dead Body if any :',
                    style:
                        engBold.copyWith(fontSize: isExhumation ? 8.5 : 10.0)),
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
  if (showsSection('Civil Surgeon PM Report') || isCivilSurgeon) {
    pw.Widget csPdfRow(
        String qNum, String qTextEn, String qTextMr, pw.Widget answerWidget,
        {double bottomPad = 8.5, double enSize = 10.0, double mrSize = 9.5}) {
      return pw.Padding(
        padding: pw.EdgeInsets.only(bottom: bottomPad),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 11,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('$qNum $qTextEn',
                      style: engBold.copyWith(fontSize: enSize)),
                  pw.SizedBox(height: 1),
                  pw.Text(qTextMr, style: mrBold.copyWith(fontSize: mrSize)),
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

    pw.Widget csPdfDateTimeAnswer(String dateVal, String timeVal,
        {double fontSize = 9.5}) {
      return pw.Wrap(
        crossAxisAlignment: pw.WrapCrossAlignment.center,
        spacing: 2,
        runSpacing: 2,
        children: [
          pw.Text(':- दिनांक ', style: mrBold.copyWith(fontSize: fontSize)),
          underlineField(dateVal, width: 70),
          pw.Text(' रोजी ', style: mrBold.copyWith(fontSize: fontSize)),
          underlineField(timeVal, width: 60),
          pw.Text(' वाजता.', style: mrBold.copyWith(fontSize: fontSize)),
        ],
      );
    }

    pw.Widget csSubLabel(String text, {double fontSize = 9.5}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 1),
        child: pw.Text('($text)', style: mrBold.copyWith(fontSize: fontSize)),
      );
    }

    // Page 5 - Civil Surgeon Page 1 (Questions 1 to 13)
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'नमुना सी-६१७ स्थानांतरण/सं-२७१-कालगुण-२७११-२,००,०००(पुस्तके ४ पो.स्टे.का. ४४\n(G.R.G.D No.352 dt 21-5-12 P.M. 35 M.C in MR vide L.No.L.89-B dt.18-4-69 form I.G of Police, M.S.Bombay)',
                    textAlign: pw.TextAlign.center,
                    style: mrBold.copyWith(fontSize: 7.5),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'शवविच्छेदन परिक्षेसाठी पाठविलेल्या प्रेताबरोबर जिल्हा शल्यचिकित्सकाकडे पाठवायचा पोलीस अहवाल',
                    textAlign: pw.TextAlign.center,
                    style: mrBold.copyWith(fontSize: 11.5),
                  ),
                  pw.Text(
                    'Police Report to be forwarded to the Civil Surgeon with Dead Bodies sent For Post-mortem examination',
                    textAlign: pw.TextAlign.center,
                    style: engBold.copyWith(fontSize: 10.0),
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
                      pw.Text('प्रश्न', style: mrBold.copyWith(fontSize: 10.0)),
                      pw.Text('Question',
                          style: engBold.copyWith(fontSize: 9.5)),
                    ],
                  ),
                ),
                pw.Container(width: 0.8, height: 22, color: PdfColors.grey500),
                pw.Expanded(
                  flex: 12,
                  child: pw.Column(
                    children: [
                      pw.Text('उत्तर', style: mrBold.copyWith(fontSize: 10.0)),
                      pw.Text('Answer', style: engBold.copyWith(fontSize: 9.5)),
                    ],
                  ),
                ),
              ],
            ),
            pw.Divider(color: PdfColors.black, thickness: 0.8),
            pw.SizedBox(height: 4),
            csPdfRow('1)', 'Name of Deceased', 'मृत व्यक्तीचे नांव',
                underlineField(v('csNameDeceased')),
                bottomPad: 8.5),
            csPdfRow('2)', 'Age', 'वय', underlineField(v('csAge')),
                bottomPad: 8.5),
            csPdfRow(
                '3)',
                'Married, Single, Widow or Widower',
                'विवाहीत, अविवाहीत, विधवा किंवा विधूर',
                underlineField(v('csMaritalStatus')),
                bottomPad: 8.5),
            csPdfRow('4)', 'Date and hour of death', 'मृत्युचा दिनांक आणि वेळ',
                csPdfDateTimeAnswer(v('csDeathDate'), v('csDeathTime')),
                bottomPad: 8.5),
            csPdfRow(
                '5)',
                'Describe condition of body when found, Position, Surroundings and any marks of Violence, bloodstains or vomited matters Which may have existed?',
                'प्रेत सापडले त्यावेळची अवस्था, स्थिती, भोवतालची परिस्थिती आणि उपलब्ध असलेल्या मारहाणीच्या खुणा रक्ताचे डाग किंवा वांतीबरोबर पडलेले पदार्थ यांचा तपशील दयावा.',
                multilineBox(v('csBodyCondition'), lines: 3),
                bottomPad: 8.5),
            csPdfRow(
                '6)',
                'Day and hour on which the body was seen by the officer making the report',
                'अहवाल पाठविणाऱ्या अधिकाऱ्याने प्रेत पाहिल्याचा दिनांक व वेळ (तास)',
                csPdfDateTimeAnswer(v('csSeenDate'), v('csSeenTime')),
                bottomPad: 8.5),
            csPdfRow(
                '7)',
                'Was the body cold or warm when found?',
                'प्रेत सापडले त्यावेळी थंड होते कि गरम',
                underlineField(v('csBodyColdWarm')),
                bottomPad: 8.5),
            csPdfRow(
                '8)',
                'Had the deceased suffered from recent Illness? If so, what? State duration and Describe the illness as far as Known.',
                'मृत व्यक्तीस अलिकडे काही आजार झाला होता काय असल्यास कोणता.',
                multilineBox(v('csRecentIllness'), lines: 2),
                bottomPad: 8.5),
            csPdfRow(
                '9)',
                'Had deceased suffered from accident Injury or if so, describe it.',
                'मृत व्यक्तीस कोणत्याही प्रकारचा अपघात, दुखापत किंवा मारहाण झाली होती काय ?',
                multilineBox(v('csAccidentInjury'), lines: 2),
                bottomPad: 8.5),
            csPdfRow(
                '10)',
                'If clothes, weapons, vomited matter of Other articles are forwarded, State why this Is done and what relation they bear to the Case? Describe them.',
                'कपडे, हत्यारे, वांतीबरोबर पडलेले पदार्थ किंवा इतर वस्तु पाठविल्या असल्यास तसे का केले व त्याचा प्रकरणाशी संबंध आहे ते लिहावे, त्याचा तपशील दयावा.',
                multilineBox(v('csArticlesForwarded'), lines: 3),
                bottomPad: 8.5),
            csPdfRow(
                '11)',
                'Is death supposed to have been due to Natural causes, accident, suicide or homicide? State briefly and plainly, any suspicions That may exist and why?',
                'मृत्यु नैसर्गिक कारणे, अपघात, आत्महत्या किंवा खून यापैकी कशामुळे घडला असे वाटते. काही संशय असल्यास ते थोडक्यात स्पष्टपणे नमुद करावे व कारणे दयावे.',
                multilineBox(v('csDeathReason'), lines: 3),
                bottomPad: 8.5),
            csPdfRow(
                '12)',
                'Is there suspicion of poisoning? If, so, is any particular poison supposed to have been employed? Mention any symptoms of poisoning which are reported to have existed during life and any appearances pointing to poisoning observed after death.',
                'विष प्रयोग केल्याचा संशय आहे, असल्यास विशिष्ट विषाचा वापर केला आहे वाटते काय? मृत व्यक्ती जिवंत असतांना विषबाधा झाल्याची लक्षणे दिसून आल्याचे कळविण्यात आले होते काय, व विषाचे बाबत मृत्यु नंतर दिसून आलेली चिन्हे नमुद करावी.',
                multilineBox(v('csPoisonSuspicion'), lines: 3),
                bottomPad: 8.5),
            csPdfRow(
                '13)',
                'In the case of a woman, is she supposed to be pregnant of to have been recently delivered ?',
                'स्त्रीच्या बाबतीत ती गरोदर असावी किंवा अलीकडे प्रसुती झाली असावी असे वाटते काय ?',
                multilineBox(v('csWomanPregnancy'), lines: 2),
                bottomPad: 5.0),
            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('M.R.W',
                  style: engStyle.copyWith(
                      fontSize: 8.5, fontStyle: pw.FontStyle.italic)),
            ),
          ],
        ),
      ),
    );

    // Page 6 - Civil Surgeon Page 2 (Questions 14 to 16, Extra Notes, IO Signature)
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 22),
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
                      pw.Text('प्रश्न', style: mrBold.copyWith(fontSize: 10.0)),
                      pw.Text('Question',
                          style: engBold.copyWith(fontSize: 10.0)),
                    ],
                  ),
                ),
                pw.Container(width: 0.8, height: 22, color: PdfColors.grey500),
                pw.Expanded(
                  flex: 12,
                  child: pw.Column(
                    children: [
                      pw.Text('उत्तर', style: mrBold.copyWith(fontSize: 10.0)),
                      pw.Text('Answer',
                          style: engBold.copyWith(fontSize: 10.0)),
                    ],
                  ),
                ),
              ],
            ),
            pw.Divider(color: PdfColors.black, thickness: 0.8),
            pw.SizedBox(height: 8),

            csPdfRow(
                '14)',
                'Is abortion or attempted abortion known or suspected? And if the former, has the focus been found?',
                'गर्भपात केला किंवा गर्भपात करण्याचा प्रयत्न केला या विषयी माहिती किंवा संशय आहे काय, गर्भपात केला असल्यास गर्भ सापडला काय.',
                multilineBox(v('csAbortion'), lines: 4),
                bottomPad: 22.0,
                enSize: 10.5,
                mrSize: 10.0),
            csPdfRow(
                '15)',
                'State the finding of the Jury (if any) and mention any reasons they may have given for their findings.',
                'ज्युरीचे निष्कर्ष असल्यास नमुद करावेत व निष्कर्षा बाबत त्यांनी काही कारणे दिली असल्यास त्याचा निर्देश करावा.',
                multilineBox(v('csJuryFindings'), lines: 4),
                bottomPad: 22.0,
                enSize: 10.5,
                mrSize: 10.0),
            csPdfRow(
                '16)',
                'Remarks. Under this head the Police Officer should give any information not included in the above question which he may consider likely to assist the Civil Surgeon informing an opinion of the cause of death.',
                'शेरा वरील प्रश्नात समाविष्ट न झालेली परंतु पोलीस अधिकाऱ्यांच्या मते जिल्हा शल्यचिकित्सकांना मृत्युच्या कारणाविषयी आपले मत बनविण्यास सहाय्यभूत होण्याचा संभव आहे अशी कोणत्याही प्रकारची माहिती या शीर्षका खाली दयावी.',
                multilineBox(v('csRemarks'), lines: 6),
                bottomPad: 22.0,
                enSize: 10.5,
                mrSize: 10.0),

            pw.SizedBox(height: 12),
            multilineBox(v('csExtraNotes'), lines: 4),
            pw.SizedBox(height: 28),

            // IO Signature Block
            pw.Row(
              children: [
                pw.Spacer(),
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      csSubLabel('तपासणी करणाऱ्या अधिकाऱ्यांची नांव व सही',
                          fontSize: 10.0),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        children: [
                          pw.Text('Name: ',
                              style: engBold.copyWith(fontSize: 10.5)),
                          pw.Expanded(child: underlineField(v('csIoName'))),
                        ],
                      ),
                      csSubLabel('नांव', fontSize: 9.5),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        children: [
                          pw.Text('Rank: ',
                              style: engBold.copyWith(fontSize: 10.5)),
                          underlineField(v('csIoRank'), width: 95),
                          pw.SizedBox(width: 8),
                          pw.Text('Number if any:',
                              style: engBold.copyWith(fontSize: 10.5)),
                          pw.Expanded(child: underlineField(v('csIoNo'))),
                        ],
                      ),
                      csSubLabel('पद                   बक्कल नंबर',
                          fontSize: 9.5),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        children: [
                          pw.Text('Posting and Address:',
                              style: engBold.copyWith(fontSize: 10.5)),
                          pw.Expanded(child: underlineField(v('csIoPosting'))),
                        ],
                      ),
                      csSubLabel('नेमणूक व पत्ता', fontSize: 9.5),
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
                      fontSize: 8.5, fontStyle: pw.FontStyle.italic)),
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
    pw.Widget marUnderline(String text,
        {double? width, double minWidth = 20, double fontSize = 10.0}) {
      return pw.Container(
        constraints: pw.BoxConstraints(minWidth: width ?? minWidth),
        padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.black, width: 0.8)),
        ),
        child: pw.Text(
          text.isEmpty ? ' ' : text,
          style: pw.TextStyle(
              font: devanagariBold,
              fontSize: fontSize,
              fontWeight: pw.FontWeight.bold),
        ),
      );
    }

    pw.Widget marMultiline(String text,
        {int lines = 2, double fontSize = 10.0}) {
      return pw.Container(
        width: double.infinity,
        constraints: pw.BoxConstraints(minHeight: lines * 15.0),
        padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.black, width: 0.8)),
        ),
        child: pw.Text(
          text.isEmpty ? ' ' : text,
          maxLines: lines,
          overflow: pw.TextOverflow.clip,
          style: pw.TextStyle(font: devanagariRegular, fontSize: fontSize),
        ),
      );
    }

    // PAGE 1 — मरणा-न्वेषण पंचनामा (१ ते १३)
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 22),
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
            pw.SizedBox(height: 10),

            // Top Right: ठिकाण, दिनांक, सुरू केल्याची वेळ
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.SizedBox(
                width: 270,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(children: [
                      pw.Text('ठिकाण : ',
                          style: mrBold.copyWith(fontSize: 10.5)),
                      pw.Expanded(
                          child: marUnderline(v('marThikan'), fontSize: 10.5)),
                    ]),
                    pw.SizedBox(height: 3),
                    pw.Row(children: [
                      pw.Text('दिनांक : ',
                          style: mrBold.copyWith(fontSize: 10.5)),
                      pw.Expanded(
                        child: marUnderline(
                          v('marDate').isEmpty
                              ? '......./ ......./ २०.........'
                              : v('marDate'),
                          fontSize: 10.5,
                        ),
                      ),
                    ]),
                    pw.SizedBox(height: 3),
                    pw.Row(children: [
                      pw.Text('सुरू केल्याची वेळ: ',
                          style: mrBold.copyWith(fontSize: 10.5)),
                      pw.Expanded(
                        child: marUnderline(
                          v('marTime').isEmpty
                              ? '........./ .........'
                              : v('marTime'),
                          fontSize: 10.5,
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 10),

            // १) पंचाचे नांव व पत्ता :-
            pw.Text('१) पंचाचे नांव व पत्ता :-',
                style: mrBold.copyWith(fontSize: 10.5)),
            pw.SizedBox(height: 1),
            marMultiline(v('marPanchNameAddress'), lines: 3, fontSize: 10.0),
            pw.SizedBox(height: 5),

            // २) पोलीस स्टेशन ________ जिल्हा : ________
            pw.Row(
              children: [
                pw.Text('२) पोलीस स्टेशन ',
                    style: mrBold.copyWith(fontSize: 10.5)),
                pw.Expanded(child: marUnderline(v('marPs'), fontSize: 10.5)),
                pw.SizedBox(width: 16),
                pw.Text('जिल्हा : ', style: mrBold.copyWith(fontSize: 10.5)),
                pw.Expanded(child: marUnderline(v('marDist'), fontSize: 10.5)),
              ],
            ),
            pw.SizedBox(height: 5),

            // ३) अकस्मात मृत्यु/गुन्हा/ठाणे दैनंदिनी क्र:-
            pw.Row(
              children: [
                pw.Text('३) अकस्मात मृत्यु/गुन्हा/ठाणे दैनंदिनी क्र:-',
                    style: mrBold.copyWith(fontSize: 10.5)),
                pw.Expanded(
                    child: marUnderline(v('marDiaryNo'), fontSize: 10.5)),
              ],
            ),
            pw.SizedBox(height: 5),

            // ४) अधिनियम व कलम :-
            pw.Row(
              children: [
                pw.Text('४) अधिनियम व कलम :-',
                    style: mrBold.copyWith(fontSize: 10.5)),
                pw.Expanded(
                    child: marUnderline(v('marActSec'), fontSize: 10.5)),
              ],
            ),
            pw.SizedBox(height: 5),

            // ५) अन्वेषण अधिकाऱ्याचे नांव, हुद्दा :-
            pw.Text('५) अन्वेषण अधिकाऱ्याचे नांव, हुद्दा :-',
                style: mrBold.copyWith(fontSize: 10.5)),
            pw.SizedBox(height: 1),
            marMultiline(v('marIoDetails'), lines: 2, fontSize: 10.0),
            pw.SizedBox(height: 5),

            // ६) फिर्यादीचे नांव :-
            pw.Text('६) फिर्यादीचे नांव :-',
                style: mrBold.copyWith(fontSize: 10.5)),
            pw.SizedBox(height: 1),
            marMultiline(v('marComplainantName'), lines: 2, fontSize: 10.0),
            pw.SizedBox(height: 5),

            // ७) मृतकाचे नांव व पत्ता :-
            pw.Text('७) मृतकाचे नांव व पत्ता :-',
                style: mrBold.copyWith(fontSize: 10.5)),
            pw.SizedBox(height: 1),
            marMultiline(v('marDeceasedNameAddress'), lines: 2, fontSize: 10.0),
            pw.SizedBox(height: 5),

            // ८) प्रेत दाखविणाऱ्याचे/ओळखणाऱ्याचे नांव :-
            pw.Text('८) प्रेत दाखविणाऱ्याचे/ओळखणाऱ्याचे नांव :-',
                style: mrBold.copyWith(fontSize: 10.5)),
            pw.SizedBox(height: 1),
            marMultiline(v('marShownByName'), lines: 2, fontSize: 10.0),
            pw.SizedBox(height: 5),

            // ९) प्रेत ठेवले आहे त्या ठिकाणाचे वर्णन :-
            pw.Text('९) प्रेत ठेवले आहे त्या ठिकाणाचे वर्णन :-',
                style: mrBold.copyWith(fontSize: 10.5)),
            pw.SizedBox(height: 1),
            marMultiline(v('marThikanDescription'), lines: 2, fontSize: 10.0),
            pw.SizedBox(height: 5),

            // १०) प्रेताची स्थिती:-
            pw.Text('१०) प्रेताची स्थिती:-',
                style: mrBold.copyWith(fontSize: 10.5)),
            pw.SizedBox(height: 1),
            marMultiline(v('marBodyCondition'), lines: 3, fontSize: 10.0),
            pw.SizedBox(height: 5),

            // ११) प्रेताचे अंगावरील कपड्याचे वर्णन :-
            pw.Text('११) प्रेताचे अंगावरील कपड्याचे वर्णन :-',
                style: mrBold.copyWith(fontSize: 10.5)),
            pw.SizedBox(height: 1),
            marMultiline(v('marBodyClothes'), lines: 2, fontSize: 10.0),
            pw.SizedBox(height: 5),

            // १२) प्रेताचे अंगावरील दागीने व इतर वस्तु :-
            pw.Text('१२) प्रेताचे अंगावरील दागीने व इतर वस्तु :-',
                style: mrBold.copyWith(fontSize: 10.5)),
            pw.SizedBox(height: 1),
            marMultiline(v('marBodyOrnaments'), lines: 2, fontSize: 10.0),
            pw.SizedBox(height: 5),

            // १३) मृतकाच्या शरीरावरील मार, जखमा इत्यादी :-
            pw.Text('१३) मृतकाच्या शरीरावरील मार, जखमा इत्यादी :-',
                style: mrBold.copyWith(fontSize: 10.5)),
            pw.SizedBox(height: 1),
            marMultiline(v('mar13Injuries'), lines: 3, fontSize: 10.0),

            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.bottomRight,
              child: pw.Text('M.R.W', style: engStyle.copyWith(fontSize: 9.5)),
            ),
          ],
        ),
      ),
    );

    // PAGE 2 — मरणा-न्वेषण पंचनामा (१४ ते १८ + सह्या)
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // १४) प्रेतावरील इतर खुणा...
            pw.Text(
              '१४) प्रेतावरील इतर खुणा, लघवी, विर्यपतन, विष्टा किंवा वांती झाली काय ? तपासणीकरीता नमुने घेतले काय सविस्तर उल्लेख करावा :-',
              style: mrBold.copyWith(fontSize: 10.5),
            ),
            pw.SizedBox(height: 2),
            marMultiline(v('mar14OtherMarks'), lines: 4, fontSize: 10.0),
            pw.SizedBox(height: 10),

            // १५) मृतकाचे अंगावरील दागीने...
            pw.Text(
              '१५) मृतकाचे अंगावरील दागीने व इतर वस्तुंची काय विल्हेवाट लावली :-',
              style: mrBold.copyWith(fontSize: 10.5),
            ),
            pw.SizedBox(height: 2),
            marMultiline(v('mar15OrnamentsDisposal'), lines: 3, fontSize: 10.0),
            pw.SizedBox(height: 10),

            // १६) पंच व अन्वेषण अधिकारी यांचा अभिप्राय :-
            pw.Text('१६) पंच व अन्वेषण अधिकारी यांचा अभिप्राय :-',
                style: mrBold.copyWith(fontSize: 10.5)),
            pw.SizedBox(height: 2),
            marMultiline(v('mar16Opinion'), lines: 3, fontSize: 10.0),
            pw.SizedBox(height: 10),

            // १७) प्रेताची काय विल्हेवाट लावली ? :-
            pw.Text('१७) प्रेताची काय विल्हेवाट लावली ? :-',
                style: mrBold.copyWith(fontSize: 10.5)),
            pw.SizedBox(height: 2),
            marMultiline(v('mar17BodyDisposal'), lines: 3, fontSize: 10.0),
            pw.SizedBox(height: 10),

            // १८) पंचनामा संपविल्याची दिनांक व वेळ :-
            pw.Text('१८) पंचनामा संपविल्याची दिनांक व वेळ :-',
                style: mrBold.copyWith(fontSize: 10.5)),
            pw.SizedBox(height: 2),
            marMultiline(v('mar18DateTime'), lines: 2, fontSize: 10.0),
            pw.SizedBox(height: 18),

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
                          style: mrBold.copyWith(fontSize: 11)),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Text('१)- ',
                              style: mrBold.copyWith(fontSize: 10.5)),
                          pw.Expanded(
                              child: marUnderline(v('mar11Panch1'),
                                  fontSize: 10.5)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        children: [
                          pw.Text('२)- ',
                              style: mrBold.copyWith(fontSize: 10.5)),
                          pw.Expanded(
                              child: marUnderline(v('mar11Panch2'),
                                  fontSize: 10.5)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        children: [
                          pw.Text('३)- ',
                              style: mrBold.copyWith(fontSize: 10.5)),
                          pw.Expanded(
                              child: marUnderline(v('mar11Panch3'),
                                  fontSize: 10.5)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        children: [
                          pw.Text('४)- ',
                              style: mrBold.copyWith(fontSize: 10.5)),
                          pw.Expanded(
                              child: marUnderline(v('mar11Panch4'),
                                  fontSize: 10.5)),
                        ],
                      ),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Text('प्रत सादर :- मा.वैद्यकीय अधिकारी ',
                              style: mrBold.copyWith(fontSize: 9.5)),
                          pw.Expanded(
                              child: marUnderline(v('mar11CopyTo'),
                                  fontSize: 10.5)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 28),

                // Right Column: तपासी अधिकारी नांव व सही शिक्का
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('तपासी अधिकारी नांव व सही शिक्का',
                          style: mrBold.copyWith(fontSize: 11)),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        children: [
                          pw.Text('नांव :- ',
                              style: mrBold.copyWith(fontSize: 10.5)),
                          pw.Expanded(
                              child: marUnderline(v('mar11IoName'),
                                  fontSize: 10.5)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        children: [
                          pw.Text('हुद्दा :- ',
                              style: mrBold.copyWith(fontSize: 10.5)),
                          pw.Expanded(
                              child: marUnderline(v('mar11IoRank'),
                                  fontSize: 10.5)),
                        ],
                      ),
                      pw.SizedBox(height: 6),
                      pw.Row(
                        children: [
                          pw.Text('पोलीस स्टेशन :- ',
                              style: mrBold.copyWith(fontSize: 10.5)),
                          pw.Expanded(
                              child:
                                  marUnderline(v('mar11IoPs'), fontSize: 10.5)),
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
              child: pw.Text('M.R.W', style: engStyle.copyWith(fontSize: 9.5)),
            ),
          ],
        ),
      ),
    );
  }

  if (showsSection('14 Kalmi Form') ||
      showsSection('14-Kalmi Form with Inquest')) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 26),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Text('Page 12 (१४-कलमी फॉर्म)',
                  style: mrBold.copyWith(fontSize: 9)),
            ),
            pw.Divider(thickness: 1.0),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                      '14-Clause Form (to be submitted with Inquest Panchanama)',
                      style: engBold.copyWith(fontSize: 11)),
                  pw.Text(
                      '१४ कलमी फॉर्म व इन्क्वेस्ट पंचनामा सोबत द्यावाचा फॉर्म',
                      style: mrBold.copyWith(fontSize: 10)),
                  pw.Text(
                      'Submitted to Medical Officer / मा.वैद्यकीय अधिकारी यांना सादर',
                      style: mrBold.copyWith(fontSize: 9)),
                ],
              ),
            ),
            pw.Divider(thickness: 0.8),
            pw.SizedBox(height: 6),
            pw.Text('1) Name and age of deceased (मृतकाचे नाव व वय):',
                style: engBold.copyWith(fontSize: 8.5)),
            underlineField(v('kal14NameAge')),
            pw.SizedBox(height: 5),
            pw.Text('2) Address of deceased (मृतकाचा पत्ता):',
                style: engBold.copyWith(fontSize: 8.5)),
            underlineField(v('kal14Address')),
            pw.SizedBox(height: 5),
            pw.Text(
                '3) When dead body was sent to P.M. (शवविच्छेदन करण्यास प्रेत केव्हा पाठविले):',
                style: engBold.copyWith(fontSize: 8.5)),
            underlineField(v('kal14ShavFrom')),
            pw.SizedBox(height: 5),
            pw.Text(
                '4) When dead body reached to Medical Officer (मा. वैद्यकीय अधिकारी यांचेकडे प्रेत केव्हा पोहोचले):',
                style: engBold.copyWith(fontSize: 8.5)),
            underlineField(v('kal14ShavTo')),
            pw.SizedBox(height: 5),
            pw.Text("5) Mother's name of deceased (मृतकाचे आईचे नाव):",
                style: engBold.copyWith(fontSize: 8.5)),
            underlineField(v('kal14AaiName')),
            pw.SizedBox(height: 5),
            pw.Text("6) Father's name of deceased (मृतकाचे वडीलांचे नाव):",
                style: engBold.copyWith(fontSize: 8.5)),
            underlineField(v('kal14BaapName')),
            pw.SizedBox(height: 5),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('7) Religion of deceased (मृतकाचा धर्म):',
                          style: engBold.copyWith(fontSize: 8.5)),
                      underlineField(v('kal14Dharm')),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('8) Occupation of deceased (मृतकाचा व्यवसाय):',
                          style: engBold.copyWith(fontSize: 8.5)),
                      underlineField(v('kal14Vyavsay')),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 5),
            pw.Text('9) Any Addiction/Habit (काही व्यसन होते काय?):',
                style: engBold.copyWith(fontSize: 8.5)),
            pw.Row(children: [
              pw.Text('१) सिगारेट / बिडी: ',
                  style: mrStyle.copyWith(fontSize: 8)),
              underlineField(
                  '${doc['kal14Cigarette'] == true ? 'होय' : 'नाही'} (दिवस: ${v('kal14CigaretteDays')})',
                  width: 140),
              pw.SizedBox(width: 12),
              pw.Text('२) दारू: ', style: mrStyle.copyWith(fontSize: 8)),
              underlineField(
                  '${doc['kal14Daru'] == true ? 'होय' : 'नाही'} (दिवस: ${v('kal14DaruDays')})',
                  width: 140),
            ]),
            pw.SizedBox(height: 3),
            pw.Row(children: [
              pw.Text('३) तंबाखु: ', style: mrStyle.copyWith(fontSize: 8)),
              underlineField(
                  '${doc['kal14Tambakhu'] == true ? 'होय' : 'नाही'} (दिवस: ${v('kal14TambakhuDays')})',
                  width: 140),
              pw.SizedBox(width: 12),
              pw.Text('४) पान मसाला / गुटखा: ',
                  style: mrStyle.copyWith(fontSize: 8)),
              underlineField(
                  '${doc['kal14PanMasala'] == true ? 'होय' : 'नाही'} (दिवस: ${v('kal14PanMasalaDays')})',
                  width: 140),
            ]),
            pw.SizedBox(height: 5),
            pw.Text('10) Any other disease (काही इतर आजार होता काय?):',
                style: engBold.copyWith(fontSize: 8.5)),
            underlineField(v('kal14Aajar')),
            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.bottomRight,
              child: pw.Text('M.R.W', style: engStyle.copyWith(fontSize: 8)),
            ),
          ],
        ),
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 26),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Text('Page 13 (१४-कलमी फॉर्म)',
                  style: mrBold.copyWith(fontSize: 9)),
            ),
            pw.Divider(thickness: 1.0),
            pw.SizedBox(height: 6),
            pw.Text(
                '11) In case of vehicular accident (वाहन अपघाताची घटना असल्यास):',
                style: engBold.copyWith(fontSize: 8.5)),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                      '(a) Vehicle type / वाहनाचा प्रकार: ${v('kal14VehicleName')}',
                      style: mrStyle.copyWith(fontSize: 8)),
                  pw.Text(
                      '(b) Driver / Passenger / चालक / प्रवासी: ${v('kal14DriverPass')}',
                      style: mrStyle.copyWith(fontSize: 8)),
                  pw.Text(
                      '(c) Pedestrian / पायी चालणारा: ${v('kal14Pedestrian')}',
                      style: mrStyle.copyWith(fontSize: 8)),
                ],
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
                '12) Detail information of accident / fall from height (अपघात कसा झाला / उंचीवरून पडल्याची माहिती):',
                style: engBold.copyWith(fontSize: 8.5)),
            underlineField(v('kal14AccidentHow')),
            pw.SizedBox(height: 4),
            pw.Text(
                'Accident Date & Time (अपघाताची दिनांक व वेळ): ${_formatDateTimeKal14(v('kal14AccidentDateTime').isNotEmpty ? v('kal14AccidentDateTime') : [
                    v('kal14AccidentDate'),
                    v('kal14AccidentTime')
                  ].where((s) => s.isNotEmpty).join(', '))}',
                style: mrStyle.copyWith(fontSize: 8)),
            pw.SizedBox(height: 4),
            underlineField(v('kal14FallInfo')),
            pw.SizedBox(height: 6),
            pw.Text('13) In case of female deceased (मृतक स्त्री असल्यास):',
                style: engBold.copyWith(fontSize: 8.5)),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                      '(a) Months of pregnancy / गरोदर असल्यास महिने: ${v('kal14PregnantMonths')}',
                      style: mrStyle.copyWith(fontSize: 8)),
                  pw.Text(
                      '(b) Delivery or abortion info / प्रसूती किंवा गर्भपात तपशील: ${v('kal14DeliveredAbortion')}',
                      style: mrStyle.copyWith(fontSize: 8)),
                  pw.Text(
                      '(c) Days passed / दिवस किती झाले: ${v('kal14PregnantDays')}',
                      style: mrStyle.copyWith(fontSize: 8)),
                ],
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
                '14) Name of person who identified dead body (शव ओळखणाऱ्याचे नाव):',
                style: engBold.copyWith(fontSize: 8.5)),
            underlineField(v('kal14IdentifierName')),
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.SizedBox(
                width: 250,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('तपासी अंमलदाराची सही / शिक्का',
                        style: mrBold.copyWith(fontSize: 9.5)),
                    pw.SizedBox(height: 6),
                    pw.Row(children: [
                      pw.Text('नांव : ', style: mrBold.copyWith(fontSize: 8.5)),
                      pw.Expanded(child: underlineField(v('kal14IoName'))),
                    ]),
                    pw.SizedBox(height: 4),
                    pw.Row(children: [
                      pw.Text('हुद्दा : ',
                          style: mrBold.copyWith(fontSize: 8.5)),
                      pw.Expanded(child: underlineField(v('kal14IoRank'))),
                    ]),
                    pw.SizedBox(height: 4),
                    pw.Row(children: [
                      pw.Text('पोलीस स्टेशन : ',
                          style: mrBold.copyWith(fontSize: 8.5)),
                      pw.Expanded(child: underlineField(v('kal14IoPs'))),
                    ]),
                  ],
                ),
              ),
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
    final dpDate = () {
      final d = v('dpDate');
      if (d.isNotEmpty) return d;
      final day = v('dpDateDay');
      final month = v('dpDateMonth');
      final year = v('dpDateYear');
      if (day.isNotEmpty && month.isNotEmpty) {
        final fullY =
            year.isNotEmpty ? (year.length == 2 ? '20$year' : year) : '';
        return '${day.padLeft(2, '0')}/${month.padLeft(2, '0')}/$fullY'
            .replaceAll(RegExp(r'/+$'), '');
      }
      return '';
    }();

    final dpDutyDate = () {
      final explicit = v('dpDutyDate');
      if (explicit.isNotEmpty) return explicit;
      final d = v('dpDutyDateDay');
      final m = v('dpDutyDateMonth');
      final y = v('dpDutyDateYear');
      if (d.isNotEmpty && m.isNotEmpty) {
        final fullY = y.isNotEmpty ? (y.length == 2 ? '20$y' : y) : '';
        return '${d.padLeft(2, '0')}/${m.padLeft(2, '0')}/$fullY'
            .replaceAll(RegExp(r'/+$'), '');
      }
      final combined = v('dpDutyDateTime');
      if (combined.isNotEmpty) {
        final dateMatch =
            RegExp(r'(\d{1,2}/\d{1,2}/\d{2,4})').firstMatch(combined);
        if (dateMatch != null) return dateMatch.group(1)!;
        if (combined.contains('रोजी')) {
          return combined.split('रोजी').first.trim();
        }
        return combined;
      }
      return '';
    }();

    final dpDutyTime = () {
      final explicit = v('dpDutyTime');
      if (explicit.isNotEmpty) return explicit;
      final h = v('dpDutyTimeHours');
      final min = v('dpDutyTimeMinutes');
      if (h.isNotEmpty || min.isNotEmpty) {
        return '${h.padLeft(2, '0')}:${min.padLeft(2, '0')}';
      }
      final combined = v('dpDutyDateTime');
      if (combined.isNotEmpty) {
        final timeMatch = RegExp(r'(\d{1,2}:\d{2})').firstMatch(combined);
        if (timeMatch != null) return timeMatch.group(1)!;
        if (combined.contains('रोजी चे') && combined.contains('वा')) {
          final part = combined.split('रोजी चे').last.split('वा').first.trim();
          if (part.isNotEmpty) return part;
        }
      }
      return '';
    }();

    pw.Widget pwDatePickerBox(String dateVal, double width) {
      final text = dateVal.isNotEmpty ? dateVal : 'DD/MM/YYYY';
      return pw.Container(
        width: width,
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(width: 0.8, color: PdfColors.black),
          ),
        ),
        padding: const pw.EdgeInsets.only(bottom: 2, left: 2, right: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              text,
              style: dateVal.isNotEmpty
                  ? mrBold.copyWith(fontSize: 9.5)
                  : mrStyle.copyWith(fontSize: 8.5, color: PdfColors.grey600),
            ),
            pw.Text('📅', style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
      );
    }

    pw.Widget pwTimePickerBox(String timeVal, double width) {
      final text = timeVal.isNotEmpty ? timeVal : 'HH:MM';
      return pw.Container(
        width: width,
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(width: 0.8, color: PdfColors.black),
          ),
        ),
        padding: const pw.EdgeInsets.only(bottom: 2, left: 2, right: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              text,
              style: timeVal.isNotEmpty
                  ? mrBold.copyWith(fontSize: 9.5)
                  : mrStyle.copyWith(fontSize: 8.5, color: PdfColors.grey600),
            ),
            pw.Text('🕒', style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
      );
    }

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
            pw.SizedBox(height: 16),
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.SizedBox(
                width: 270,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(children: [
                      pw.Text('पोलीस स्टेशन  : ',
                          style: mrBold.copyWith(fontSize: 10)),
                      pw.Expanded(child: underlineField(v('dpPs'))),
                    ]),
                    pw.SizedBox(height: 6),
                    pw.Row(children: [
                      pw.Text('कॅम्प            : ',
                          style: mrBold.copyWith(fontSize: 10)),
                      underlineField(v('dpCamp'), width: 140),
                    ]),
                    pw.SizedBox(height: 6),
                    pw.Row(children: [
                      pw.Text('दिनांक          : ',
                          style: mrBold.copyWith(fontSize: 10)),
                      pwDatePickerBox(dpDate, 120),
                    ]),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 18),
            pw.Row(children: [
              pw.Text('पो अंमलदाराचे नांव  : ',
                  style: mrBold.copyWith(fontSize: 10)),
              pw.Expanded(child: underlineField(v('dpAmaldaarName'))),
            ]),
            pw.SizedBox(height: 10),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 40),
              child: pw.Row(children: [
                pw.Text('पोलीस स्टेशन ', style: mrBold.copyWith(fontSize: 10)),
                underlineField(v('dpDutyPs'), width: 140),
                pw.SizedBox(width: 16),
                pw.Text('जिल्हा ', style: mrBold.copyWith(fontSize: 10)),
                underlineField(
                  v('dpDutyDist').isNotEmpty ? v('dpDutyDist') : v('district'),
                  width: 120,
                ),
              ]),
            ),
            pw.SizedBox(height: 10),
            pw.Row(children: [
              pw.Text('नोकरीचा दिनांक व वेळ    :- ',
                  style: mrBold.copyWith(fontSize: 10)),
              pwDatePickerBox(dpDutyDate, 110),
              pw.SizedBox(width: 12),
              pw.Text('रोजी चे ', style: mrBold.copyWith(fontSize: 10)),
              pwTimePickerBox(dpDutyTime, 70),
              pw.SizedBox(width: 6),
              pw.Text('वा', style: mrBold.copyWith(fontSize: 10)),
            ]),
            pw.SizedBox(height: 20),
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
                      text: (v('dpDeceasedTa').isNotEmpty
                                  ? '${v('dpDeceasedTa')} ${v('dpDeceasedDist')}'
                                      .trim()
                                  : v('dpDeceasedDist'))
                              .isEmpty
                          ? '-------------------'
                          : (v('dpDeceasedTa').isNotEmpty
                              ? '${v('dpDeceasedTa')} ${v('dpDeceasedDist')}'
                                  .trim()
                              : v('dpDeceasedDist')),
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
            pw.SizedBox(height: 32),
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
                      underlineField(v('dpAmaldaarSig'), width: 180),
                    ],
                  ),
                ),
                pw.SizedBox(width: 40),
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

class _FullWidthUnderlinePainter extends CustomPainter {
  final List<ui.LineMetrics> metrics;
  final Color color;
  final double thickness;

  _FullWidthUnderlinePainter({
    required this.metrics,
    this.color = Colors.black,
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
        final y = (lineBottom + 1.0).clamp(1.0, size.height - 0.5);
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

Widget _uField(String val,
    {double? width,
    double? minWidth,
    double? maxWidth,
    double fontSize = 10.5,
    TextStyle? textStyle}) {
  final content = val.trim();
  final baseStyle = textStyle ?? FormImagePdfHelper.valStyle(fontSize);
  final style = baseStyle.copyWith(
    height: baseStyle.height ?? 1.75,
  );

  return LayoutBuilder(
    builder: (context, constraints) {
      double fieldWidth;
      if (width != null) {
        fieldWidth = width;
      } else if (maxWidth == null &&
          minWidth == null &&
          constraints.maxWidth.isFinite &&
          constraints.maxWidth > 0) {
        fieldWidth = constraints.maxWidth;
      } else {
        final effMinWidth = minWidth ?? 40.0;
        final effMaxWidth = maxWidth ?? effMinWidth;
        final probeTp = TextPainter(
          text: TextSpan(text: content.isEmpty ? ' ' : content, style: style),
          textDirection: TextDirection.ltr,
        )..layout();
        final textNeededWidth = probeTp.width + 4.0;
        fieldWidth = textNeededWidth.clamp(effMinWidth, effMaxWidth);
      }

      if (constraints.maxWidth.isFinite && constraints.maxWidth > 0) {
        fieldWidth = fieldWidth.clamp(0.0, constraints.maxWidth);
      }

      final textMaxWidth = (fieldWidth - 4.0).clamp(10.0, fieldWidth);
      final tp = TextPainter(
        text: TextSpan(text: content.isEmpty ? ' ' : content, style: style),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: textMaxWidth);

      final metrics = tp.computeLineMetrics();

      return SizedBox(
        width: fieldWidth,
        child: CustomPaint(
          painter: _FullWidthUnderlinePainter(
            metrics: metrics,
            color: Colors.black,
            thickness: 0.8,
          ),
          child: SizedBox(
            width: fieldWidth,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2, left: 2, right: 2),
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

Widget _uPoliceStationPdfField(
  String val, {
  double? width,
  double minWidth = 100,
  double? maxWidth,
  TextStyle? textStyle,
}) {
  return _uField(
    val,
    width: width,
    minWidth: minWidth,
    maxWidth: maxWidth,
    textStyle: textStyle,
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
  if (content.isEmpty) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines; i++)
          Container(
            width: double.infinity,
            height: 18,
            margin: const EdgeInsets.only(bottom: 2),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(width: 0.8, color: Colors.black)),
            ),
          ),
      ],
    );
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      final w = constraints.maxWidth.isFinite && constraints.maxWidth > 0
          ? constraints.maxWidth
          : 714.0;
      final baseStyle = FormImagePdfHelper.valStyle(10.5);
      final style = baseStyle.copyWith(
        height: baseStyle.height ?? 1.75,
      );
      final textMaxWidth = (w - 4.0).clamp(10.0, w);
      final tp = TextPainter(
        text: TextSpan(text: content, style: style),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: textMaxWidth);

      final metrics = tp.computeLineMetrics();
      final contentLines = metrics.length;
      final remainingLines = lines > contentLines ? lines - contentLines : 0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: w,
            child: CustomPaint(
              painter: _FullWidthUnderlinePainter(
                metrics: metrics,
                color: Colors.black,
                thickness: 0.8,
              ),
              child: SizedBox(
                width: w,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2, left: 2, right: 2),
                  child: Text(
                    content,
                    softWrap: true,
                    style: style,
                  ),
                ),
              ),
            ),
          ),
          for (var i = 0; i < remainingLines; i++)
            Container(
              width: double.infinity,
              height: 18,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(width: 0.8, color: Colors.black)),
              ),
            ),
        ],
      );
    },
  );
}

Widget _buildVinantiArjWidget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final mrB = FormImagePdfHelper.mBld(10.5, 1.35);
  final mrR = FormImagePdfHelper.mReg(10.5, 1.35);

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
          SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('पोलीस स्टेशन : ', style: mrB),
                    Expanded(
                      child: _uPoliceStationPdfField(v('reqPs'),
                          textStyle: FormImagePdfHelper.valStyle(10.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('दिनांक :- ', style: mrB),
                    _uField(v('reqDate'), width: 90, fontSize: 10.5),
                  ],
                ),
              ],
            ),
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
            _uField(v('reqTo'), width: 240, fontSize: 10.5),
            const SizedBox(height: 2),
            _uField(v('reqTo2'), width: 240, fontSize: 10.5),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('पासुन  :-    पोलीस स्टेशन', style: mrB),
          _uPoliceStationPdfField(v('reqFromPs'),
              width: 130, textStyle: FormImagePdfHelper.valStyle(10.5)),
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
                    _uField(v('reqSubjectName'), minWidth: 300, maxWidth: 450),
                  ],
                ),
                const SizedBox(height: 3),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('पो.स्टे.', style: mrB),
                    _uPoliceStationPdfField(v('reqSubjectPs'),
                        minWidth: 95, maxWidth: 450),
                    Text('  ता-', style: mrB),
                    _uField(v('reqSubjectTa'), minWidth: 80, maxWidth: 450),
                    Text('  जिल्हा ......... हिचे/ ह्यांचे प्रेताचे पि.एम',
                        style: mrB),
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
        child: Text.rich(
          TextSpan(
            style: mrR.copyWith(height: 1.8),
            children: [
              const TextSpan(text: 'सविनय सेवेशी सादर आहे की, आज दिनांक '),
              FormImagePdfHelper.inlineFieldSpan(v('reqMargDate'),
                  emptyWidth: 75),
              const TextSpan(text: ' रोजी '),
              FormImagePdfHelper.inlineFieldSpan(v('reqMargTime'),
                  emptyWidth: 50),
              const TextSpan(text: ' वाजता पोलीस स्टेशन '),
              FormImagePdfHelper.inlineFieldSpan(v('reqMargPs'),
                  emptyWidth: 100),
              const TextSpan(text: ' मर्ग/ स्टेशन डायरी क्र. '),
              FormImagePdfHelper.inlineFieldSpan(v('reqMargDiaryNo'),
                  emptyWidth: 60),
              const TextSpan(text: '/२०'),
              FormImagePdfHelper.inlineFieldSpan(v('reqMargYear'),
                  emptyWidth: 40),
              const TextSpan(
                  text:
                      ' कलम १९४ बी.एन.एस.एस २०२३ चा मर्ग दाखल झाला असुन यातील मृतक नामे '),
              FormImagePdfHelper.inlineFieldSpan(v('reqMargName'),
                  emptyWidth: 200),
              const TextSpan(text: ' पो.स्टे. '),
              FormImagePdfHelper.inlineFieldSpan(v('reqSubjectPs'),
                  emptyWidth: 95),
              const TextSpan(text: ' ता- '),
              FormImagePdfHelper.inlineFieldSpan(v('reqMargTa'),
                  emptyWidth: 75),
              const TextSpan(text: ' जिल्हा ......... ही/ह्या '),
              FormImagePdfHelper.inlineFieldSpan(v('reqHospitalName'),
                  emptyWidth: 150),
              const TextSpan(text: ' येथे दिनांक '),
              FormImagePdfHelper.inlineFieldSpan(v('reqAdmitDate'),
                  emptyWidth: 75),
              const TextSpan(text: ' रोजी '),
              FormImagePdfHelper.inlineFieldSpan(v('reqAdmitTime'),
                  emptyWidth: 50),
              const TextSpan(
                  text:
                      ' वाजता भरती झाला असुन औषधोपचारा दरम्यान/ गळफास लावुन/ विष प्राशन करून/अपघात/ '),
              FormImagePdfHelper.inlineFieldSpan(v('reqReasonDetails'),
                  emptyWidth: 170),
              const TextSpan(text: ' दिनांक '),
              FormImagePdfHelper.inlineFieldSpan(v('reqDeathDate'),
                  emptyWidth: 75),
              const TextSpan(text: ' रोजी '),
              FormImagePdfHelper.inlineFieldSpan(v('reqDeathTime'),
                  emptyWidth: 50),
              const TextSpan(text: ' वाजता मरण पावला आहे.'),
            ],
          ),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('हस्ते : ', style: mrB),
                    Expanded(child: _uField(v('reqHasteName'), fontSize: 10.5)),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('पो.स्टे. : ', style: mrB),
                    Expanded(
                        child: _uPoliceStationPdfField(v('reqHastePs'),
                            textStyle: FormImagePdfHelper.valStyle(10.5))),
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
                    Expanded(child: _uPoliceStationPdfField(v('reqIoPosting'))),
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
            Text('(कलम १७९ भारतीय नागरिक सुरक्षा संहिता २०२३ अन्वये)',
                style: mrB),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('पोलीस स्टेशन : ', style: mrB),
                    Expanded(
                      child: _uPoliceStationPdfField(v('relPs')),
                    ),
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
        child: Text.rich(
          TextSpan(
            style: mrR.copyWith(height: 1.8),
            children: [
              const TextSpan(
                  text: 'आपणास या समन्सव्दारे कळविण्यात येते की, आम्ही '),
              FormImagePdfHelper.inlineFieldSpan(v('relWeName'),
                  emptyWidth: 160),
              const TextSpan(text: ' पोलीस स्टेशन '),
              FormImagePdfHelper.inlineFieldSpan(v('relPsName'),
                  emptyWidth: 110),
              const TextSpan(text: ' येथील अप/ मर्ग/ ठाणे दैनंदिनी क्रमांक '),
              FormImagePdfHelper.inlineFieldSpan(v('relCrDiaryNo'),
                  emptyWidth: 60),
              const TextSpan(text: '/२०'),
              FormImagePdfHelper.inlineFieldSpan(v('relCrYear'),
                  emptyWidth: 40),
              const TextSpan(text: ' कलम '),
              FormImagePdfHelper.inlineFieldSpan(v('relActSec'),
                  emptyWidth: 130),
              const TextSpan(text: ' मधील मृतक नामे '),
              FormImagePdfHelper.inlineFieldSpan(v('relDeceasedName'),
                  emptyWidth: 190),
              const TextSpan(text: ' ता-'),
              FormImagePdfHelper.inlineFieldSpan(v('relTa'), emptyWidth: 80),
              const TextSpan(text: ' जिल्हा '),
              FormImagePdfHelper.inlineFieldSpan(v('relDist'), emptyWidth: 80),
              const TextSpan(
                text:
                    ' यांचे प्रेताचा इंन्क्वेस्ट पंचनामा करणार आहो. करीता आपण प्रेत ओळखुन देवून मृतकाचे नातेवाईक या नात्याने पंचनाम्याची कार्यवाही पूर्ण होईपर्यंत आमचे सोबत हजर राहावे.',
              ),
            ],
          ),
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
                Row(children: [
                  Text('१) ', style: mrB),
                  Expanded(child: _uField(v('relSig1')))
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Text('२) ', style: mrB),
                  Expanded(child: _uField(v('relSig2')))
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Text('३) ', style: mrB),
                  Expanded(child: _uField(v('relSig3')))
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Text('४) ', style: mrB),
                  Expanded(child: _uField(v('relSig4')))
                ]),
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
                Row(children: [
                  Text('Name: ', style: mrB),
                  Expanded(child: _uField(v('relIoName')))
                ]),
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
                Row(children: [
                  Text('Posting and Address:', style: mrB),
                  Expanded(child: _uPoliceStationPdfField(v('relIoPosting')))
                ]),
                _subLabel('नेमणूक व पत्ता'),
              ],
            ),
          ),
        ],
      ),
      const Spacer(),
      Align(
          alignment: Alignment.centerRight,
          child: Text('M.R.W', style: FormImagePdfHelper.mReg(7.5))),
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
            Text('(कलम १९५ भारतीय नागरिक सुरक्षा संहिता २०२३ अन्वये)',
                style: mrB),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('पोलीस स्टेशन : ', style: mrB),
                    Expanded(
                      child: _uPoliceStationPdfField(v('panPs')),
                    ),
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
        child: Text.rich(
          TextSpan(
            style: mrR.copyWith(height: 1.8),
            children: [
              const TextSpan(
                  text: 'आपणास या समन्सव्दारे कळविण्यात येते की, आम्ही '),
              FormImagePdfHelper.inlineFieldSpan(v('panWeName'),
                  emptyWidth: 160),
              const TextSpan(text: ' पोलीस स्टेशन '),
              FormImagePdfHelper.inlineFieldSpan(v('panPsName'),
                  emptyWidth: 110),
              const TextSpan(text: ' येथील अप/ मर्ग/ ठाणे दैनंदिनी क्रमांक '),
              FormImagePdfHelper.inlineFieldSpan(v('panCrDiaryNo'),
                  emptyWidth: 60),
              const TextSpan(text: '/२०'),
              FormImagePdfHelper.inlineFieldSpan(v('panCrYear'),
                  emptyWidth: 40),
              const TextSpan(text: ' कलम '),
              FormImagePdfHelper.inlineFieldSpan(v('panActSec'),
                  emptyWidth: 130),
              const TextSpan(text: ' मधील मृतक नामे '),
              FormImagePdfHelper.inlineFieldSpan(v('panDeceasedName'),
                  emptyWidth: 190),
              const TextSpan(text: ' ता-'),
              FormImagePdfHelper.inlineFieldSpan(v('panTa'), emptyWidth: 80),
              const TextSpan(text: ' जिल्हा '),
              FormImagePdfHelper.inlineFieldSpan(v('panDist'), emptyWidth: 80),
              const TextSpan(
                text:
                    ' यांचे प्रेताचा इंन्क्वेस्ट पंचनामा करणार आहो. करीता आपण पंचनाम्याची कार्यवाही पूर्ण होईपर्यंत पंच म्हणुन आमचे सोबत हजर राहावे.',
              ),
            ],
          ),
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
                Row(children: [
                  Text('१) ', style: mrB),
                  Expanded(child: _uField(v('panSig1')))
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Text('२) ', style: mrB),
                  Expanded(child: _uField(v('panSig2')))
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Text('३) ', style: mrB),
                  Expanded(child: _uField(v('panSig3')))
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Text('४) ', style: mrB),
                  Expanded(child: _uField(v('panSig4')))
                ]),
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
                Row(children: [
                  Text('Name: ', style: mrB),
                  Expanded(child: _uField(v('panIoName')))
                ]),
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
                Row(children: [
                  Text('Posting and Address:', style: mrB),
                  Expanded(child: _uPoliceStationPdfField(v('panIoPosting')))
                ]),
                _subLabel('नेमणूक व पत्ता'),
              ],
            ),
          ),
        ],
      ),
      const Spacer(),
      Align(
          alignment: Alignment.centerRight,
          child: Text('M.R.W', style: FormImagePdfHelper.mReg(7.5))),
    ],
  );
}

Widget _csPdfRow(
  String qNum,
  String qEn,
  String qMr,
  Widget ans, {
  double bottomPad = 10.5,
  double enSize = 10.5,
  double mrSize = 10.0,
}) {
  return Padding(
    padding: EdgeInsets.only(bottom: bottomPad),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 11,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$qNum $qEn',
                style: GoogleFonts.notoSans(
                  fontSize: enSize,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                qMr,
                style: GoogleFonts.notoSansDevanagari(
                  fontSize: mrSize,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(flex: 12, child: ans),
      ],
    ),
  );
}

Widget _csDateTimeAnswer(String d, String t, {double fontSize = 10.5}) {
  final mrB = GoogleFonts.notoSansDevanagari(
    fontSize: fontSize,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );
  return Wrap(
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 2,
    runSpacing: 2,
    children: [
      Text(':- दिनांक ', style: mrB),
      _uField(d, width: 80, fontSize: fontSize),
      Text(' रोजी ', style: mrB),
      _uField(t, width: 70, fontSize: fontSize),
      Text(' वाजता.', style: mrB),
    ],
  );
}

Widget _csSubLabel(String text, {double fontSize = 10.0}) {
  return Padding(
    padding: const EdgeInsets.only(top: 1),
    child: Text(
      '($text)',
      style: GoogleFonts.notoSansDevanagari(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: Colors.black,
      ),
    ),
  );
}

Widget _csMultilineBox(String text,
    {int lines = 3, double lineHeight = 21.0, double fontSize = 10.5}) {
  final content = text.trim();
  if (content.isEmpty) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines; i++)
          Container(
            width: double.infinity,
            height: lineHeight,
            margin: const EdgeInsets.only(bottom: 2),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(width: 0.8, color: Colors.black)),
            ),
          ),
      ],
    );
  }

  return LayoutBuilder(
    builder: (context, constraints) {
      final w = constraints.maxWidth.isFinite && constraints.maxWidth > 0
          ? constraints.maxWidth
          : 714.0;
      final baseStyle = GoogleFonts.notoSansDevanagari(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      );
      final style = baseStyle.copyWith(
        height: 1.75,
      );
      final textMaxWidth = (w - 4.0).clamp(10.0, w);
      final tp = TextPainter(
        text: TextSpan(text: content, style: style),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: textMaxWidth);

      final metrics = tp.computeLineMetrics();
      final contentLines = metrics.length;
      final remainingLines = lines > contentLines ? lines - contentLines : 0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: w,
            child: CustomPaint(
              painter: _FullWidthUnderlinePainter(
                metrics: metrics,
                color: Colors.black,
                thickness: 0.8,
              ),
              child: SizedBox(
                width: w,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 2, left: 2, right: 2),
                  child: Text(
                    content,
                    softWrap: true,
                    style: style,
                  ),
                ),
              ),
            ),
          ),
          for (var i = 0; i < remainingLines; i++)
            Container(
              width: double.infinity,
              height: lineHeight,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(width: 0.8, color: Colors.black)),
              ),
            ),
        ],
      );
    },
  );
}

Widget _buildCivilSurgeonPg1Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
    children: [
      Center(
        child: Column(
          children: [
            Text(
              'नमुना सी-६१७ स्थानांतरण/सं-२७१-कालगुण-२७११-२,००,०००(पुस्तके ४ पो.स्टे.का. ४४\n(G.R.G.D No.352 dt 21-5-12 P.M. 35 M.C in MR vide L.No.L.89-B dt.18-4-69 form I.G of Police, M.S.Bombay)',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansDevanagari(
                fontSize: 8.5,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'शवविच्छेदन परिक्षेसाठी पाठविलेल्या प्रेताबरोबर जिल्हा शल्यचिकित्सकाकडे पाठवायचा पोलीस अहवाल',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansDevanagari(
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                height: 1.25,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Police Report to be forwarded to the Civil Surgeon with Dead Bodies sent For Post-mortem examination',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSans(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                height: 1.25,
                color: Colors.black,
              ),
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
                Text(
                  'प्रश्न',
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Question',
                  style: GoogleFonts.notoSans(
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 0.8, height: 26, color: Colors.grey.shade500),
          Expanded(
            flex: 12,
            child: Column(
              children: [
                Text(
                  'उत्तर',
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Answer',
                  style: GoogleFonts.notoSans(
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const Divider(color: Colors.black, thickness: 0.8),
      const SizedBox(height: 4),
      _csPdfRow('1)', 'Name of Deceased', 'मृत व्यक्तीचे नांव',
          _uField(v('csNameDeceased'), fontSize: 10.5),
          bottomPad: 10.5, enSize: 10.5, mrSize: 10.0),
      _csPdfRow('2)', 'Age', 'वय', _uField(v('csAge'), fontSize: 10.5),
          bottomPad: 10.5, enSize: 10.5, mrSize: 10.0),
      _csPdfRow(
          '3)',
          'Married, Single, Widow or Widower',
          'विवाहीत, अविवाहीत, विधवा किंवा विधूर',
          _uField(v('csMaritalStatus'), fontSize: 10.5),
          bottomPad: 10.5,
          enSize: 10.5,
          mrSize: 10.0),
      _csPdfRow('4)', 'Date and hour of death', 'मृत्युचा दिनांक आणि वेळ',
          _csDateTimeAnswer(v('csDeathDate'), v('csDeathTime'), fontSize: 10.5),
          bottomPad: 10.5, enSize: 10.5, mrSize: 10.0),
      _csPdfRow(
          '5)',
          'Describe condition of body when found, Position, Surroundings and any marks of Violence, bloodstains or vomited matters Which may have existed?',
          'प्रेत सापडले त्यावेळची अवस्था, स्थिती, भोवतालची परिस्थिती आणि उपलब्ध असलेल्या मारहाणीच्या खुणा रक्ताचे डाग किंवा वांतीबरोबर पडलेले पदार्थ यांचा तपशील दयावा.',
          _csMultilineBox(v('csBodyCondition'),
              lines: 3, lineHeight: 21.0, fontSize: 10.5),
          bottomPad: 10.5,
          enSize: 10.5,
          mrSize: 10.0),
      _csPdfRow(
          '6)',
          'Day and hour on which the body was seen by the officer making the report',
          'अहवाल पाठविणाऱ्या अधिकाऱ्याने प्रेत पाहिल्याचा दिनांक व वेळ (तास)',
          _csDateTimeAnswer(v('csSeenDate'), v('csSeenTime'), fontSize: 10.5),
          bottomPad: 10.5,
          enSize: 10.5,
          mrSize: 10.0),
      _csPdfRow(
          '7)',
          'Was the body cold or warm when found?',
          'प्रेत सापडले त्यावेळी थंड होते कि गरम',
          _uField(v('csBodyColdWarm'), fontSize: 10.5),
          bottomPad: 10.5,
          enSize: 10.5,
          mrSize: 10.0),
      _csPdfRow(
          '8)',
          'Had the deceased suffered from recent Illness? If so, what? State duration and Describe the illness as far as Known.',
          'मृत व्यक्तीस अलिकडे काही आजार झाला होता काय असल्यास कोणता.',
          _csMultilineBox(v('csRecentIllness'),
              lines: 2, lineHeight: 21.0, fontSize: 10.5),
          bottomPad: 10.5,
          enSize: 10.5,
          mrSize: 10.0),
      _csPdfRow(
          '9)',
          'Had deceased suffered from accident Injury or if so, describe it.',
          'मृत व्यक्तीस कोणत्याही प्रकारचा अपघात, दुखापत किंवा मारहाण झाली होती काय ?',
          _csMultilineBox(v('csAccidentInjury'),
              lines: 2, lineHeight: 21.0, fontSize: 10.5),
          bottomPad: 10.5,
          enSize: 10.5,
          mrSize: 10.0),
      _csPdfRow(
          '10)',
          'If clothes, weapons, vomited matter of Other articles are forwarded, State why this Is done and what relation they bear to the Case? Describe them.',
          'कपडे, हत्यारे, वांतीबरोबर पडलेले पदार्थ किंवा इतर वस्तु पाठविल्या असल्यास तसे का केले व त्याचा प्रकरणाशी संबंध आहे ते लिहावे, त्याचा तपशील दयावा.',
          _csMultilineBox(v('csArticlesForwarded'),
              lines: 3, lineHeight: 21.0, fontSize: 10.5),
          bottomPad: 10.5,
          enSize: 10.5,
          mrSize: 10.0),
      _csPdfRow(
          '11)',
          'Is death supposed to have been due to Natural causes, accident, suicide or homicide? State briefly and plainly, any suspicions That may exist and why?',
          'मृत्यु नैसर्गिक कारणे, अपघात, आत्महत्या किंवा खून यापैकी कशामुळे घडला असे वाटते. काही संशय असल्यास ते थोडक्यात स्पष्टपणे नमुद करावे व कारणे दयावे.',
          _csMultilineBox(v('csDeathReason'),
              lines: 3, lineHeight: 21.0, fontSize: 10.5),
          bottomPad: 10.5,
          enSize: 10.5,
          mrSize: 10.0),
      _csPdfRow(
          '12)',
          'Is there suspicion of poisoning? If, so, is any particular poison supposed to have been employed? Mention any symptoms of poisoning which are reported to have existed during life and any appearances pointing to poisoning observed after death.',
          'विष प्रयोग केल्याचा संशय आहे, असल्यास विशिष्ट विषाचा वापर केला आहे वाटते काय? मृत व्यक्ती जिवंत असतांना विषबाधा झाल्याची लक्षणे दिसून आल्याचे कळविण्यात आले होते काय, व विषाचे बाबत मृत्यु नंतर दिसून आलेली चिन्हे नमुद करावी.',
          _csMultilineBox(v('csPoisonSuspicion'),
              lines: 3, lineHeight: 21.0, fontSize: 10.5),
          bottomPad: 10.5,
          enSize: 10.5,
          mrSize: 10.0),
      _csPdfRow(
          '13)',
          'In the case of a woman, is she supposed to be pregnant of to have been recently delivered ?',
          'स्त्रीच्या बाबतीत ती गरोदर असावी किंवा अलीकडे प्रसुती झाली असावी असे वाटते काय ?',
          _csMultilineBox(v('csWomanPregnancy'),
              lines: 2, lineHeight: 21.0, fontSize: 10.5),
          bottomPad: 6.0,
          enSize: 10.5,
          mrSize: 10.0),
      const Spacer(),
      Align(
          alignment: Alignment.centerRight,
          child: Text('M.R.W',
              style: GoogleFonts.notoSans(
                fontSize: 9.0,
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ))),
    ],
  );
}

Widget _buildCivilSurgeonPg2Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
    children: [
      const Divider(color: Colors.black, thickness: 0.8),
      Row(
        children: [
          Expanded(
            flex: 11,
            child: Column(
              children: [
                Text(
                  'प्रश्न',
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Question',
                  style: GoogleFonts.notoSans(
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 0.8, height: 24, color: Colors.grey.shade500),
          Expanded(
            flex: 12,
            child: Column(
              children: [
                Text(
                  'उत्तर',
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Answer',
                  style: GoogleFonts.notoSans(
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const Divider(color: Colors.black, thickness: 0.8),
      const SizedBox(height: 6),
      _csPdfRow(
          '14)',
          'Is abortion or attempted abortion known or suspected? And if the former, has the focus been found?',
          'गर्भपात केला किंवा गर्भपात करण्याचा प्रयत्न केला या विषयी माहिती किंवा संशय आहे काय, गर्भपात केला असल्यास गर्भ सापडला काय.',
          _csMultilineBox(v('csAbortion'),
              lines: 3, lineHeight: 22.0, fontSize: 10.5),
          bottomPad: 18.0,
          enSize: 10.5,
          mrSize: 10.0),
      _csPdfRow(
          '15)',
          'State the finding of the Jury (if any) and mention any reasons they may have given for their findings.',
          'ज्युरीचे निष्कर्ष असल्यास नमुद करावेत व निष्कर्षा बाबत त्यांनी काही कारणे दिली असल्यास त्याचा निर्देश करावा.',
          _csMultilineBox(v('csJuryFindings'),
              lines: 3, lineHeight: 22.0, fontSize: 10.5),
          bottomPad: 18.0,
          enSize: 10.5,
          mrSize: 10.0),
      _csPdfRow(
          '16)',
          'Remarks. Under this head the Police Officer should give any information not included in the above question which he may consider likely to assist the Civil Surgeon informing an opinion of the cause of death.',
          'शेरा वरील प्रश्नात समाविष्ट न झालेली परंतु पोलीस अधिकाऱ्यांच्या मते जिल्हा शल्यचिकित्सकांना मृत्युच्या कारणाविषयी आपले मत बनविण्यास सहाय्यभूत होण्याचा संभव आहे अशी कोणत्याही प्रकारची माहिती या शीर्षका खाली दयावी.',
          _csMultilineBox(v('csRemarks'),
              lines: 4, lineHeight: 22.0, fontSize: 10.5),
          bottomPad: 18.0,
          enSize: 10.5,
          mrSize: 10.0),
      const SizedBox(height: 10),
      _csMultilineBox(v('csExtraNotes'),
          lines: 3, lineHeight: 22.0, fontSize: 10.5),
      const SizedBox(height: 20),

      // IO Signature Block (right-aligned)
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _csSubLabel('तपासणी करणाऱ्या अधिकाऱ्यांची नांव व सही',
                    fontSize: 10.0),
                const SizedBox(height: 6),
                Row(children: [
                  Text(
                    'Name: ',
                    style: GoogleFonts.notoSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Expanded(child: _uField(v('csIoName'), fontSize: 10.5))
                ]),
                _csSubLabel('नांव', fontSize: 9.5),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Rank: ',
                      style: GoogleFonts.notoSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    _uField(v('csIoRank'), width: 100, fontSize: 10.5),
                    const SizedBox(width: 8),
                    Text(
                      'Number if any:',
                      style: GoogleFonts.notoSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(child: _uField(v('csIoNo'), fontSize: 10.5)),
                  ],
                ),
                _csSubLabel('पद                   बक्कल नंबर', fontSize: 9.5),
                const SizedBox(height: 6),
                Row(children: [
                  Text(
                    'Posting and Address:',
                    style: GoogleFonts.notoSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(child: _uField(v('csIoPosting'), fontSize: 10.5))
                ]),
                _csSubLabel('नेमणूक व पत्ता', fontSize: 9.5),
              ],
            ),
          ),
          const SizedBox(width: 1), // keeps Expanded(flex:1) placeholder space
        ],
      ),

      const Spacer(),
      Align(
          alignment: Alignment.centerRight,
          child: Text('M.R.W',
              style: GoogleFonts.notoSans(
                fontSize: 9.0,
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ))),
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
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('पोलीस स्टेशन  : ', style: mrB),
                  Expanded(child: _uPoliceStationPdfField(v('ptpPs'))),
                ],
              ),
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
        textAlign: TextAlign.justify,
        TextSpan(
          style: mrR.copyWith(height: 2.2),
          children: [
            const TextSpan(text: '       मी '),
            FormImagePdfHelper.inlineFieldSpan(v('ptpReceiverName'),
                emptyWidth: 180),
            const TextSpan(text: ' रा. '),
            FormImagePdfHelper.inlineFieldSpan(v('ptpReceiverRa'),
                emptyWidth: 140),
            const TextSpan(text: ' ता '),
            FormImagePdfHelper.inlineFieldSpan(v('ptpReceiverTa'),
                emptyWidth: 80),
            const TextSpan(text: ' जिल्हा '),
            FormImagePdfHelper.inlineFieldSpan(v('ptpReceiverDist'),
                emptyWidth: 100),
            const TextSpan(text: ' मो नं '),
            FormImagePdfHelper.inlineFieldSpan(v('ptpMoNo'), emptyWidth: 110),
            const TextSpan(text: ' प्रेत ताबा पावती लिहुन देतो की, आज दिनांक '),
            FormImagePdfHelper.inlineFieldSpan(v('ptpReceiptDate'),
                emptyWidth: 110),
            const TextSpan(text: ' रोजी मृतक नामे '),
            FormImagePdfHelper.inlineFieldSpan(v('ptpDeceasedName'),
                emptyWidth: 180),
            const TextSpan(text: ' रा. '),
            FormImagePdfHelper.inlineFieldSpan(v('ptpDeceasedRa'),
                emptyWidth: 120),
            const TextSpan(text: ' ता आणि जिल्हा '),
            FormImagePdfHelper.inlineFieldSpan(v('ptpDeceasedDist'),
                emptyWidth: 100),
            const TextSpan(
              text:
                  ' हयाचे / हिचे प्रेत पोस्टमार्टम होवुन अंतिम संस्काराकरीता माझे ताब्यात मिळाले आहे. सदर प्रेत हे नमुद मृतकाचेच आहे. मी मृतकाचा वारसा या नात्याने ताब्यात घेतले आहे. माझी कोणत्याच प्रकारची तक्रार नाही.',
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
                Row(children: [
                  Text('नांव : ', style: mrR),
                  Expanded(child: _uField(v('ptpIoName')))
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Text('हुद्दा : ', style: mrR),
                  Expanded(child: _uField(v('ptpIoRank')))
                ]),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('पोलीस स्टेशन : ', style: mrR),
                    Expanded(child: _uPoliceStationPdfField(v('ptpIoPs'))),
                  ],
                ),
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

  final headerLabelStyle = FormImagePdfHelper.mBld(11.5, 1.4);
  final bodyTextStyle = FormImagePdfHelper.mReg(11.5, 1.85);
  final valStyle = FormImagePdfHelper.valStyle(11.5).copyWith(
    color: Colors.black,
    fontWeight: FontWeight.w600,
  );
  final titleStyle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    decoration: TextDecoration.underline,
    color: Colors.black87,
  );

  String resolveDate(String mainDate, String day, String month, String year) {
    if (mainDate.trim().isNotEmpty) return mainDate.trim();
    if (day.trim().isNotEmpty && month.trim().isNotEmpty) {
      final y = year.trim();
      final fullY = y.isNotEmpty ? (y.length == 2 ? '20$y' : y) : '';
      return '${day.trim().padLeft(2, '0')}/${month.trim().padLeft(2, '0')}/$fullY'
          .replaceAll(RegExp(r'/+$'), '');
    }
    return '';
  }

  final dpDate = resolveDate(
    v('dpDate'),
    v('dpDateDay'),
    v('dpDateMonth'),
    v('dpDateYear'),
  );

  final dpDutyDate = () {
    final explicit = v('dpDutyDate');
    if (explicit.isNotEmpty) return explicit;
    final fromParts = resolveDate(
        '', v('dpDutyDateDay'), v('dpDutyDateMonth'), v('dpDutyDateYear'));
    if (fromParts.isNotEmpty) return fromParts;
    final combined = v('dpDutyDateTime');
    if (combined.isNotEmpty) {
      final dateMatch =
          RegExp(r'(\d{1,2}/\d{1,2}/\d{2,4})').firstMatch(combined);
      if (dateMatch != null) return dateMatch.group(1)!;
      if (combined.contains('रोजी')) {
        return combined.split('रोजी').first.trim();
      }
      return combined;
    }
    return '';
  }();

  final dpDutyTime = () {
    final explicit = v('dpDutyTime');
    if (explicit.isNotEmpty) return explicit;
    final h = v('dpDutyTimeHours');
    final min = v('dpDutyTimeMinutes');
    if (h.isNotEmpty || min.isNotEmpty) {
      return '${h.padLeft(2, '0')}:${min.padLeft(2, '0')}';
    }
    final combined = v('dpDutyDateTime');
    if (combined.isNotEmpty) {
      final timeMatch = RegExp(r'(\d{1,2}:\d{2})').firstMatch(combined);
      if (timeMatch != null) return timeMatch.group(1)!;
      if (combined.contains('रोजी चे') && combined.contains('वा')) {
        final part = combined.split('रोजी चे').last.split('वा').first.trim();
        if (part.isNotEmpty) return part;
      }
    }
    return '';
  }();

  Widget pdfDatePickerField({
    required String value,
    required double width,
  }) {
    final hasValue = value.trim().isNotEmpty;
    final display = hasValue ? value.trim() : 'DD/MM/YYYY';
    final textStyle = hasValue
        ? valStyle
        : bodyTextStyle.copyWith(color: Colors.grey.shade400, fontSize: 11);

    return Container(
      width: width,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF333333), width: 1.0),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 2, top: 2, left: 2, right: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              display,
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.calendar_today_outlined,
            size: 15,
            color: Colors.black87,
          ),
        ],
      ),
    );
  }

  Widget pdfTimePickerField({
    required String value,
    required double width,
  }) {
    final hasValue = value.trim().isNotEmpty;
    final display = hasValue ? value.trim() : 'HH:MM';
    final textStyle = hasValue
        ? valStyle
        : bodyTextStyle.copyWith(color: Colors.grey.shade400, fontSize: 11);

    return Container(
      width: width,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF333333), width: 1.0),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 2, top: 2, left: 2, right: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              display,
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.access_time,
            size: 15,
            color: Colors.black87,
          ),
        ],
      ),
    );
  }

  Widget pdfInlineBlank({
    required String value,
    required double width,
    String? hintText,
  }) {
    final valText = value.trim();
    final probeTp = TextPainter(
      text: TextSpan(
        text: valText.isEmpty ? (hintText ?? ' ') : valText,
        style: valStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final measured = probeTp.width + 12.0;
    final calcWidth = measured > width ? measured : width;

    return Container(
      width: calcWidth,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF333333), width: 1.0),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 2, top: 1),
      child: Text(
        valText.isEmpty ? (hintText ?? ' ') : valText,
        style: valText.isEmpty
            ? bodyTextStyle.copyWith(color: Colors.grey.shade400, fontSize: 11)
            : valStyle,
      ),
    );
  }

  Widget pdfWrappingInput({
    required String value,
    double minWidth = 100,
    double? maxWidth,
  }) {
    return _uField(
      value,
      minWidth: minWidth,
      maxWidth: maxWidth,
      fontSize: 11.5,
      textStyle: valStyle,
    );
  }

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 36),
    children: [
      const SizedBox(height: 12),
      // Title centered
      Center(
        child: Text(
          'ड्युटी पास',
          style: titleStyle,
        ),
      ),
      const SizedBox(height: 16),

      // Top-right aligned Police Station / Camp / Date
      Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 380,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text('पोलीस स्टेशन  :', style: headerLabelStyle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _uPoliceStationPdfField(
                      v('dpPs'),
                      textStyle: valStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('कॅम्प            :', style: headerLabelStyle),
                  const SizedBox(width: 8),
                  pdfWrappingInput(
                    value: v('dpCamp'),
                    minWidth: 140,
                    maxWidth: 220,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('दिनांक          :', style: headerLabelStyle),
                  const SizedBox(width: 8),
                  pdfDatePickerField(
                    value: dpDate,
                    width: 140,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),

      // Upper info lines
      Row(
        children: [
          Text('पो अंमलदाराचे नांव  :', style: headerLabelStyle),
          const SizedBox(width: 8),
          Expanded(
            child: pdfWrappingInput(
              value: v('dpAmaldaarName'),
              minWidth: 160,
              maxWidth: 350,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.only(left: 60.0),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            Text('पोलीस स्टेशन ', style: headerLabelStyle),
            pdfWrappingInput(
              value: v('dpDutyPs'),
              minWidth: 140,
              maxWidth: 280,
            ),
            const SizedBox(width: 16),
            Text('जिल्हा ', style: headerLabelStyle),
            pdfWrappingInput(
              value:
                  v('dpDutyDist').isNotEmpty ? v('dpDutyDist') : v('district'),
              minWidth: 100,
              maxWidth: 200,
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          Text('नोकरीचा दिनांक व वेळ    :- ', style: headerLabelStyle),
          pdfDatePickerField(
            value: dpDutyDate,
            width: 140,
          ),
          const SizedBox(width: 12),
          Text('रोजी चे ', style: headerLabelStyle),
          pdfTimePickerField(
            value: dpDutyTime,
            width: 90,
          ),
          const SizedBox(width: 6),
          Text('वा', style: headerLabelStyle),
        ],
      ),
      const SizedBox(height: 24),

      // Main context paragraph
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 10,
        children: [
          Text(
            '       आपणास आदेश देण्यात येतो की, आपण अप/ मर्ग/ स्टे.डायरी क्रमांक ',
            style: bodyTextStyle,
          ),
          pdfInlineBlank(
            value: v('dpMargNo'),
            width: 100,
          ),
          Text('/ २०', style: bodyTextStyle),
          pdfInlineBlank(
            value: v('dpMargYear'),
            width: 44,
            hintText: 'YY',
          ),
          Text('कलम', style: bodyTextStyle),
          pdfWrappingInput(
            value: v('dpKalam'),
            minWidth: 140,
            maxWidth: 240,
          ),
          Text('मधील मृतक नामे ', style: bodyTextStyle),
          pdfWrappingInput(
            value: v('dpDeceasedName'),
            minWidth: 200,
            maxWidth: 350,
          ),
          Text('रा.', style: bodyTextStyle),
          pdfWrappingInput(
            value: v('dpDeceasedRa'),
            minWidth: 220,
            maxWidth: 450,
          ),
          Text('ता आणि जिल्हा', style: bodyTextStyle),
          pdfWrappingInput(
            value: v('dpDeceasedTa').isNotEmpty
                ? '${v('dpDeceasedTa')} ${v('dpDeceasedDist')}'.trim()
                : v('dpDeceasedDist'),
            minWidth: 140,
            maxWidth: 260,
          ),
          Text('हयाचे / हिचे प्रेत सोबत घेउन मा.वैद्यकीय अधिकारी',
              style: bodyTextStyle),
          pdfWrappingInput(
            value: v('dpMedOfficerName'),
            minWidth: 180,
            maxWidth: 320,
          ),
          Text(
            'यांचेकडे शवविच्छेदनाकरीता दाखल करावे. व शवविच्छेदनानंतर प्रेत मृतकाचे वारसदारास ताब्यात देउन मा. वैद्यकीय अधिकारी यांनी पि. एम दरम्यान व्हिसेरा कपडा बंडल दिल्यास ताब्यात घेउन तपासी अंमलदार यांचेकडे दाखल करावे.',
            style: bodyTextStyle,
          ),
        ],
      ),
      const SizedBox(height: 40),

      // Footer signatures
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ड्युटी पास घेणाऱ्याची सही',
                  style: headerLabelStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 36),
                _uField(
                  v('dpAmaldaarSig'),
                  width: 220,
                  textStyle: valStyle,
                  fontSize: 11.5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 40),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'तपासी अधिकारी नांव व सही शिक्का',
                  style: headerLabelStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('नांव :- ', style: bodyTextStyle),
                    Expanded(
                      child: _uField(
                        v('dpIoName'),
                        textStyle: valStyle,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('हुद्दा :- ', style: bodyTextStyle),
                    Expanded(
                      child: _uField(
                        v('dpIoRank'),
                        textStyle: valStyle,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('पोलीस स्टेशन :- ', style: bodyTextStyle),
                    Expanded(
                      child: _uPoliceStationPdfField(
                        v('dpIoPs'),
                        textStyle: valStyle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 36),

      // Bottom Right tag
      Align(
        alignment: Alignment.bottomRight,
        child: Text(
          'M.R.W',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}

Widget _buildInquestMainPg1Widget(Map<String, dynamic> doc,
    {bool isExhumation = false}) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final engBold = GoogleFonts.lora(
      fontSize: isExhumation ? 9.5 : 10.0,
      fontWeight: FontWeight.bold,
      color: Colors.black);
  final engStyle = GoogleFonts.lora(
      fontSize: isExhumation ? 9.0 : 9.5, color: Colors.black87);
  final mrStyle = isExhumation
      ? FormImagePdfHelper.mReg(8.5, 1.2)
      : FormImagePdfHelper.mBld(9.5, 1.25);

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
    children: [
      Center(
        child: Column(
          children: [
            Text(
              isExhumation ? 'EXHUMATION PANCHANAMA' : 'INQUEST PANCHANAMA',
              style: GoogleFonts.lora(
                  fontSize: isExhumation ? 13 : 13.5,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              isExhumation
                  ? 'कबर खोदून शव बाहेर काढण्याचा पंचनामा (Exhumation Panchanama)'
                  : 'मरणोत्तर पंचनामा',
              style: FormImagePdfHelper.mBld(isExhumation ? 10.5 : 11.5),
            ),
            const SizedBox(height: 2),
            Text('(Under Section - 194 B.N.S.S.)',
                style: GoogleFonts.lora(
                    fontSize: isExhumation ? 9.0 : 9.5,
                    fontWeight: FontWeight.bold)),
            Text('( भारतीय नागरिक सुरक्षा संहिता २०२३ कलम १९४ अन्वये.)',
                style: isExhumation
                    ? FormImagePdfHelper.mReg(8.5)
                    : FormImagePdfHelper.mBld(9.0)),
          ],
        ),
      ),
      SizedBox(height: isExhumation ? 6 : 6),
      const Divider(color: Colors.black, thickness: 0.8),
      SizedBox(height: isExhumation ? 6 : 6),
      if (!isExhumation) ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1.0),
              child: Text('1) Dist.:- ', style: engBold),
            ),
            _uField(v('dist'), width: 100, fontSize: 10.5),
            const SizedBox(width: 16),
            Padding(
              padding: const EdgeInsets.only(top: 1.0),
              child: Text('P.S.:- ', style: engBold),
            ),
            Expanded(child: _uField(v('ps'), fontSize: 10.5)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1.0),
              child: Text('   Year:-20', style: engBold),
            ),
            _uField(v('year'), width: 50, fontSize: 10.5),
            const SizedBox(width: 16),
            Padding(
              padding: const EdgeInsets.only(top: 1.0),
              child: Text('FIR/AD/U.D.No:- ', style: engBold),
            ),
            Expanded(child: _uField(v('firNo'), fontSize: 10.5)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
            '   जिल्हा - .........             पो.स्टे.             वर्ष                     पहिली खबर क्र./ अकस्मात मृत्यू क्र.',
            style: mrStyle),
      ] else ...[
        // EXHUMATION PANCHANAMA:
        // Row 1: Dist.    P.S.    Year
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dist.
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1.0),
                        child: Text('1) Dist. :- ', style: engBold),
                      ),
                      Expanded(child: _uField(v('dist'), fontSize: 10.0)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('जिल्हा', style: mrStyle),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // P.S.
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1.0),
                        child: Text('P.S. :- ', style: engBold),
                      ),
                      Expanded(child: _uField(v('ps'), fontSize: 10.0)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('पो.स्टे.', style: mrStyle),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Year
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1.0),
                        child: Text('Year :- 20', style: engBold),
                      ),
                      Expanded(child: _uField(v('year'), fontSize: 10.0)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('वर्ष', style: mrStyle),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Row 2: FIR/AD/U.D.No.    Date
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FIR/AD/U.D.No
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1.0),
                        child: Text('FIR/AD/U.D.No :- ', style: engBold),
                      ),
                      Expanded(child: _uField(v('firNo'), fontSize: 10.0)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('पहिली खबर क्र./ अकस्मात मृत्यू क्र.', style: mrStyle),
                ],
              ),
            ),
            const SizedBox(width: 24),

            // Date
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1.0),
                        child: Text('Date :- ', style: engBold),
                      ),
                      Expanded(
                        child: _uField(
                          v('firDate').isNotEmpty ? v('firDate') : v('date'),
                          fontSize: 10.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('दिनांक', style: mrStyle),
                ],
              ),
            ),
          ],
        ),
      ],
      SizedBox(height: isExhumation ? 12 : 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('2) Act and Section: - ', style: engBold),
          ),
          Expanded(
              child: _uField(v('actSections'),
                  fontSize: isExhumation ? 10.0 : 10.5)),
        ],
      ),
      const SizedBox(height: 3),
      Text('   अधिनियम व कलमे :-', style: mrStyle),
      SizedBox(height: isExhumation ? 12 : 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('3) Place From where Dead Body Found/Traced : ',
                style: engBold),
          ),
          Expanded(
              child: _uField(v('deadBodyFoundPlace'),
                  fontSize: isExhumation ? 10.0 : 10.5)),
        ],
      ),
      const SizedBox(height: 6),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('   Place:- ', style: engStyle),
          ),
          Expanded(
              child: _uField(v('foundPlace'),
                  fontSize: isExhumation ? 10.0 : 10.5)),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('Date: ', style: engStyle),
          ),
          _uField(v('foundDate'),
              width: 85, fontSize: isExhumation ? 10.0 : 10.5),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('time: ', style: engStyle),
          ),
          _uField(v('foundTime'),
              width: 65, fontSize: isExhumation ? 10.0 : 10.5),
        ],
      ),
      const SizedBox(height: 3),
      Text('   प्रेत सापडल्याचे /मिळाल्याचे ठिकाण / जागा', style: mrStyle),
      SizedBox(height: isExhumation ? 12 : 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('4) By whom Dead Body Shown                   :',
                style: engBold),
          ),
          Expanded(
              child:
                  _uField(v('shownBy'), fontSize: isExhumation ? 10.0 : 10.5)),
        ],
      ),
      const SizedBox(height: 3),
      Text('   प्रेत कोणी दाखविले :-', style: mrStyle),
      SizedBox(height: isExhumation ? 12 : 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('5) By whom Dead Body Identified              :',
                style: engBold),
          ),
          Expanded(
              child: _uField(v('identifiedBy'),
                  fontSize: isExhumation ? 10.0 : 10.5)),
        ],
      ),
      const SizedBox(height: 3),
      Text('   प्रेत कोणी ओळखले :-', style: mrStyle),
      const SizedBox(height: 4),
      _multilineBox(v('identifiedBy2'), lines: 2),
      SizedBox(height: isExhumation ? 12 : 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('a) Dead Body Male/Female                     :',
                style: engBold),
          ),
          Expanded(
              child:
                  _uField(v('gender'), fontSize: isExhumation ? 10.0 : 10.5)),
        ],
      ),
      const SizedBox(height: 2),
      Text('   अ) प्रेत स्त्री / पुरुष जातीचे :-', style: mrStyle),
      SizedBox(height: isExhumation ? 8 : 11),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('6) b) Dead Body Married/Unmarried            :',
                style: engBold),
          ),
          Expanded(
              child:
                  _uField(v('married'), fontSize: isExhumation ? 10.0 : 10.5)),
        ],
      ),
      const SizedBox(height: 2),
      Text('   ब) प्रेत विवाहीत /अविवाहीत आहे :-', style: mrStyle),
      SizedBox(height: isExhumation ? 8 : 11),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('c) Age of Dead Body                          :',
                style: engBold),
          ),
          Expanded(
              child: _uField(v('age'), fontSize: isExhumation ? 10.0 : 10.5)),
        ],
      ),
      const SizedBox(height: 2),
      Text('   क) प्रेताचे वय :-', style: mrStyle),
      SizedBox(height: isExhumation ? 8 : 11),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 2,
        runSpacing: 2,
        children: [
          Text('   ड) मृत्यूची तारीख वेळ :-                     ',
              style: mrStyle),
          Text('Date : ', style: engStyle),
          _uField(v('deathDate'),
              width: 90, fontSize: isExhumation ? 10.0 : 10.5),
          const SizedBox(width: 16),
          Text('Time : ', style: engStyle),
          _uField(v('deathTime'),
              width: 65, fontSize: isExhumation ? 10.0 : 10.5),
        ],
      ),
      const SizedBox(height: 2),
      Text(
          '                                                तारीख                                   वेळ',
          style: mrStyle),
      SizedBox(height: isExhumation ? 12 : 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('7) Position of Dead Body                     :',
                style: engBold),
          ),
          Expanded(
              child: _uField(v('positionOfBody'),
                  fontSize: isExhumation ? 10.0 : 10.5)),
        ],
      ),
      const SizedBox(height: 3),
      Text('   प्रेताची स्थिती / अवस्था (जागा)', style: mrStyle),
      const SizedBox(height: 4),
      _multilineBox(v('positionOfBody2'), lines: isExhumation ? 3 : 2),
      if (!isExhumation) ...[
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1.0),
              child: Text('8) Name and Address of Dead Body             :',
                  style: engBold),
            ),
            Expanded(child: _uField(v('nameAddressDeceased'), fontSize: 10.5)),
          ],
        ),
        const SizedBox(height: 3),
        Text('   प्रेताचे संपूर्ण नांव व पत्ता (माहित असल्यास)',
            style: mrStyle),
        const SizedBox(height: 4),
        _multilineBox(v('nameAddressDeceased2'), lines: 3),
      ],
      if (!isExhumation) const Spacer() else const SizedBox(height: 24),
      Align(
        alignment: Alignment.centerRight,
        child: Text('M.R.W',
            style: GoogleFonts.lora(
                fontSize: isExhumation ? 8.5 : 9.5,
                fontStyle: FontStyle.italic)),
      ),
    ],
  );
}

Widget _buildInquestMainPg2Widget(Map<String, dynamic> doc,
    {bool isExhumation = false}) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final engBold = GoogleFonts.lora(
      fontSize: isExhumation ? 8.5 : 10.0,
      fontWeight: FontWeight.bold,
      color: Colors.black);
  final mrStyle = isExhumation
      ? FormImagePdfHelper.mReg(7.5, 1.2)
      : FormImagePdfHelper.mBld(9.5, 1.25);

  Widget injuryRow(String labelEn, String labelMr, String val) {
    return Padding(
      padding: EdgeInsets.only(bottom: isExhumation ? 2.5 : 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1.0),
                child: SizedBox(
                    width: isExhumation ? 90 : 100,
                    child: Text(labelEn, style: engBold)),
              ),
              Expanded(
                  child: _uField(val, fontSize: isExhumation ? 8.5 : 10.5)),
            ],
          ),
          const SizedBox(height: 2),
          Text('   $labelMr', style: mrStyle),
        ],
      ),
    );
  }

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
    children: [
      if (isExhumation) ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1.0),
              child: Text('8) Name and Address of Dead Body             :',
                  style: engBold),
            ),
            Expanded(child: _uField(v('nameAddressDeceased'))),
          ],
        ),
        Text('   प्रेताचे संपूर्ण नांव व पत्ता (माहित असल्यास)',
            style: mrStyle),
        _multilineBox(v('nameAddressDeceased2'), lines: 3),
        const SizedBox(height: 6),
      ],
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text(
                '9) Description Of injuries Found on Dead Body if any :',
                style: engBold),
          ),
          Expanded(
              child: _uField(v('injDescription'),
                  fontSize: isExhumation ? 8.5 : 10.5)),
        ],
      ),
      const SizedBox(height: 2),
      Text('   प्रेताचे अंगावर असल्यास त्याचे वर्णन :', style: mrStyle),
      SizedBox(height: isExhumation ? 5 : 8),
      injuryRow('a) Head          :', 'अ) डोके        :', v('injHead')),
      injuryRow('b) Face          :', 'ब) चेहरा        :', v('injFace')),
      injuryRow('c) Neck          :', 'क) मान         :', v('injNeck')),
      injuryRow('d) Chest         :', 'ड) छाती        :', v('injChest')),
      injuryRow('e) Stomac        :', 'इ) पोट         :', v('injStomach')),
      injuryRow('f) Right Hand    :', 'फ) उजवा हात     :', v('injRightHand')),
      injuryRow('g) Left Hand     :', 'ग) डावा हात     :', v('injLeftHand')),
      injuryRow('h) Right Leg     :', 'ह) उजवा पाय     :', v('injRightLeg')),
      injuryRow('i) Left Leg      :', 'ऐ) डावा पाय     :', v('injLeftLeg')),
      injuryRow(
          'j) Private part  :', 'जे) गुप्त भाग     :', v('injPrivatePart')),
      injuryRow('k) Back          :', 'के) पाठ        :', v('injBack')),
      const Spacer(),
      Align(
        alignment: Alignment.centerRight,
        child: Text('M.R.W',
            style: GoogleFonts.lora(
                fontSize: isExhumation ? 8.5 : 9.5,
                fontStyle: FontStyle.italic)),
      ),
    ],
  );
}

Widget _buildInquestMainPg3Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final engBold = GoogleFonts.lora(
      fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.black);
  final engStyle = GoogleFonts.lora(fontSize: 8.5, color: Colors.black87);
  final mrStyle = FormImagePdfHelper.mReg(7.5, 1.2);

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
    children: [
      Text('10)   Injuries of Dead Body Caused By Accidental/Violence :',
          style: engBold),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('Homicide / Other Burn / (Fair / Tejab) ',
                style: engBold.copyWith(fontSize: 8)),
          ),
          Expanded(child: _uField(v('injAccidentalViolence'))),
        ],
      ),
      Text('प्रेताचे अंगावरील जखमा अपघाताच्या घोक्यातील / इत्यादी',
          style: mrStyle),
      Text('होण्यामुळे झाल्या', style: mrStyle),
      const SizedBox(height: 5),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('11) Weapon / Means (if any)                  :',
                style: engBold),
          ),
          Expanded(child: _uField(v('weaponMeans'))),
        ],
      ),
      Text('जखमा केलेल्या हत्यार/ साधन असल्यास           :', style: mrStyle),
      const SizedBox(height: 5),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('12) Dead Body Cool / Warm                    :',
                style: engBold),
          ),
          Expanded(child: _uField(v('bodyCoolWarm'))),
        ],
      ),
      Text('प्रेत थंड आहे/ गरम आहे.                       :', style: mrStyle),
      const SizedBox(height: 5),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('13) Position Dead Body by Poisoning          :',
                style: engBold),
          ),
          Expanded(child: _uField(v('poisoningPosition'))),
        ],
      ),
      Text('प्रेताची स्थिती विष प्राशन केलेला असल्यास       :', style: mrStyle),
      const SizedBox(height: 5),
      Text('14) (a) Finger Print has taken by Doctor Not taken Reason',
          style: engBold),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('(In case of unidentified Dead Body)          :',
                style: engStyle),
          ),
          Expanded(child: _uField(v('fingerprintReason'))),
        ],
      ),
      Text('अनोळखी प्रेताचे डॉक्टरांकडून बोटांचे ठसे घेतले/ नाही कारण :',
          style: mrStyle),
      const SizedBox(height: 3),
      Text('(b) Photo has taken/not taken reason (In case of an',
          style: engBold),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('Identified Dead Body)                        :',
                style: engStyle),
          ),
          Expanded(child: _uField(v('photoReason'))),
        ],
      ),
      Text('अनोळखी प्रेताचे फोटो घेतले आहेत काय/नाही कारण :', style: mrStyle),
      const SizedBox(height: 5),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('15) Dead Body sent to P.M. / not reason: ',
                style: engBold),
          ),
          Expanded(child: _uField(v('sentToPMReason'))),
        ],
      ),
      Text('प्रेत (पोस्ट मार्टम) शविच्छेदन करीता पाठविले/ नाही कारण',
          style: mrStyle),
      const SizedBox(height: 3),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('(a) At which Hospital Dead Body sent to P.M.:',
                style: engBold),
          ),
          Expanded(child: _uField(v('hospitalName'))),
        ],
      ),
      Text('कोणत्या रूग्णालयात प्रेत पोस्ट मार्टूम करीता पाठविले :',
          style: mrStyle),
      const SizedBox(height: 3),
      Text('(b) With whom (Name No. and P.sm)            :', style: engBold),
      Text('कोणा बरोबर पाठविले (नांव व पो.स्टे.)', style: mrStyle),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('Name : ', style: engStyle),
          ),
          _uField(v('sentOfficerName'), width: 150),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('B/No:- ', style: engStyle),
          ),
          _uField(v('sentOfficerBNo'), width: 65),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('P.S. : ', style: engStyle),
          ),
          Expanded(child: _uField(v('sentOfficerPs'))),
        ],
      ),
      Text(
          'नांव                                        बक्कल नंबर                 पो.स्टे',
          style: mrStyle),
      const SizedBox(height: 5),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('16) Opinion of Panchas and Police about Death: ',
                style: engBold),
          ),
          Expanded(child: _uField(v('opinionPanchas'))),
        ],
      ),
      Text('पंच व पोलीसांचा मृत्यूविषयी अभिप्राय', style: mrStyle),
      _multilineBox(v('opinionPanchas2'), lines: 3),
      const SizedBox(height: 5),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('17) More information if any                 : ',
                style: engBold),
          ),
          Expanded(child: _uField(v('moreInfo'))),
        ],
      ),
      Text('अधिक माहिती असल्यास', style: mrStyle),
      const Spacer(),
      Align(
        alignment: Alignment.centerRight,
        child: Text('M.R.W',
            style: GoogleFonts.lora(fontSize: 8, fontStyle: FontStyle.italic)),
      ),
    ],
  );
}

Widget _buildInquestMainPg4Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final engBold = GoogleFonts.lora(
      fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.black);
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
          _uField(v('panchanamaTime'), width: 50),
          Text('  To ', style: engStyle),
          _uField(v('panchanamaTimeTo'), width: 50),
        ],
      ),
      Text(
          '    पंचनामा केल्याची               दिनांक : -                       वेळ : -                 ते',
          style: mrStyle),
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
                Text('तपासणी करणाऱ्या अधिकाऱ्यांची नांव व सह्या',
                    style: mrStyle),
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
        child: Text('M.R.W',
            style: GoogleFonts.lora(fontSize: 8, fontStyle: FontStyle.italic)),
      ),
    ],
  );
}

Widget _buildMarananveshanPg1Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final mrB = GoogleFonts.notoSansDevanagari(
    fontSize: 11.2,
    fontWeight: FontWeight.w600,
    color: Colors.black,
    height: 1.35,
  );
  final titleStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 16.5,
    fontWeight: FontWeight.bold,
    color: Colors.black,
    decoration: TextDecoration.underline,
  );

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.only(left: 32, right: 32, top: 28, bottom: 20),
    children: [
      Center(
        child: Text(
          'मरणा-न्वेषण पंचनामा',
          style: titleStyle,
        ),
      ),
      const SizedBox(height: 14),

      // Top Right: ठिकाण, दिनांक, सुरू केल्याची वेळ
      Align(
        alignment: Alignment.topRight,
        child: SizedBox(
          width: 285,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('ठिकाण : ', style: mrB),
                Expanded(child: _uField(v('marThikan'), fontSize: 11.0)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Text('दिनांक : ', style: mrB),
                Expanded(
                  child: _uField(
                    v('marDate').isEmpty
                        ? '......./ ......./ २०.........'
                        : v('marDate'),
                    fontSize: 11.0,
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Text('सुरू केल्याची वेळ: ', style: mrB),
                Expanded(
                  child: _uField(
                    v('marTime').isEmpty
                        ? '........./ .........'
                        : v('marTime'),
                    fontSize: 11.0,
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),

      // १) पंचाचे नांव व पत्ता :-
      Text('१) पंचाचे नांव व पत्ता :-', style: mrB),
      const SizedBox(height: 2),
      _multilineBox(v('marPanchNameAddress'), lines: 3),
      const SizedBox(height: 6),

      // २) पोलीस स्टेशन ________ जिल्हा : ________
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('२) पोलीस स्टेशन ', style: mrB),
          ),
          Expanded(
            child: _uPoliceStationPdfField(
              v('marPs'),
              textStyle: FormImagePdfHelper.valStyle(11.0),
            ),
          ),
          const SizedBox(width: 16),
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('जिल्हा : ', style: mrB),
          ),
          Expanded(child: _uField(v('marDist'), fontSize: 11.0)),
        ],
      ),
      const SizedBox(height: 6),

      // ३) अकस्मात मृत्यु/गुन्हा/ठाणे दैनंदिनी क्र:-
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('३) अकस्मात मृत्यु/गुन्हा/ठाणे दैनंदिनी क्र:-',
                style: mrB),
          ),
          Expanded(child: _uField(v('marDiaryNo'), fontSize: 11.0)),
        ],
      ),
      const SizedBox(height: 6),

      // ४) अधिनियम व कलम :-
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('४) अधिनियम व कलम :-', style: mrB),
          ),
          Expanded(child: _uField(v('marActSec'), fontSize: 11.0)),
        ],
      ),
      const SizedBox(height: 6),

      // ५) अन्वेषण अधिकाऱ्याचे नांव, हुद्दा :-
      Text('५) अन्वेषण अधिकाऱ्याचे नांव, हुद्दा :-', style: mrB),
      const SizedBox(height: 2),
      _multilineBox(v('marIoDetails'), lines: 2),
      const SizedBox(height: 6),

      // ६) फिर्यादीचे नांव :-
      Text('६) फिर्यादीचे नांव :-', style: mrB),
      const SizedBox(height: 2),
      _multilineBox(v('marComplainantName'), lines: 2),
      const SizedBox(height: 6),

      // ७) मृतकाचे नांव व पत्ता :-
      Text('७) मृतकाचे नांव व पत्ता :-', style: mrB),
      const SizedBox(height: 2),
      _multilineBox(v('marDeceasedNameAddress'), lines: 2),
      const SizedBox(height: 6),

      // ८) प्रेत दाखविणाऱ्याचे/ओळखणाऱ्याचे नांव :-
      Text('८) प्रेत दाखविणाऱ्याचे/ओळखणाऱ्याचे नांव :-', style: mrB),
      const SizedBox(height: 2),
      _multilineBox(v('marShownByName'), lines: 2),
      const SizedBox(height: 6),

      // ९) प्रेत ठेवले आहे त्या ठिकाणाचे वर्णन :-
      Text('९) प्रेत ठेवले आहे त्या ठिकाणाचे वर्णन :-', style: mrB),
      const SizedBox(height: 2),
      _multilineBox(v('marThikanDescription'), lines: 2),
      const SizedBox(height: 6),

      // १०) प्रेताची स्थिती:-
      Text('१०) प्रेताची स्थिती:-', style: mrB),
      const SizedBox(height: 2),
      _multilineBox(v('marBodyCondition'), lines: 3),
      const SizedBox(height: 6),

      // ११) प्रेताचे अंगावरील कपड्याचे वर्णन :-
      Text('११) प्रेताचे अंगावरील कपड्याचे वर्णन :-', style: mrB),
      const SizedBox(height: 2),
      _multilineBox(v('marBodyClothes'), lines: 2),
      const SizedBox(height: 6),

      // १२) प्रेताचे अंगावरील दागीने व इतर वस्तु :-
      Text('१२) प्रेताचे अंगावरील दागीने व इतर वस्तु :-', style: mrB),
      const SizedBox(height: 2),
      _multilineBox(v('marBodyOrnaments'), lines: 2),
      const SizedBox(height: 6),

      // १३) मृतकाच्या शरीरावरील मार, जखमा इत्यादी :-
      Text('१३) मृतकाच्या शरीरावरील मार, जखमा इत्यादी :-', style: mrB),
      const SizedBox(height: 2),
      _multilineBox(v('mar13Injuries'), lines: 3),

      const Spacer(),
      Align(
        alignment: Alignment.bottomRight,
        child: Text(
          'M.R.W',
          style: GoogleFonts.notoSans(
            fontSize: 9.5,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      ),
    ],
  );
}

Widget _buildMarananveshanPg2Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final mrB = GoogleFonts.notoSansDevanagari(
    fontSize: 11.2,
    fontWeight: FontWeight.w600,
    color: Colors.black,
    height: 1.35,
  );
  final headerStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 12.0,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.only(left: 32, right: 32, top: 28, bottom: 20),
    children: [
      // १४) प्रेतावरील इतर खुणा...
      Text(
        '१४) प्रेतावरील इतर खुणा, लघवी, विर्यपतन, विष्टा किंवा वांती झाली काय ? तपासणीकरीता नमुने घेतले काय सविस्तर उल्लेख करावा :-',
        style: mrB,
      ),
      const SizedBox(height: 3),
      _multilineBox(v('mar14OtherMarks'), lines: 5),
      const SizedBox(height: 16),

      // १५) मृतकाचे अंगावरील दागीने...
      Text(
        '१५) मृतकाचे अंगावरील दागीने व इतर वस्तुंची काय विल्हेवाट लावली :-',
        style: mrB,
      ),
      const SizedBox(height: 3),
      _multilineBox(v('mar15OrnamentsDisposal'), lines: 4),
      const SizedBox(height: 16),

      // १६) पंच व अन्वेषण अधिकारी यांचा अभिप्राय :-
      Text('१६) पंच व अन्वेषण अधिकारी यांचा अभिप्राय :-', style: mrB),
      const SizedBox(height: 3),
      _multilineBox(v('mar16Opinion'), lines: 4),
      const SizedBox(height: 16),

      // १७) प्रेताची काय विल्हेवाट लावली ? :-
      Text('१७) प्रेताची काय विल्हेवाट लावली ? :-', style: mrB),
      const SizedBox(height: 3),
      _multilineBox(v('mar17BodyDisposal'), lines: 4),
      const SizedBox(height: 16),

      // १८) पंचनामा संपविल्याची दिनांक व वेळ :-
      Text('१८) पंचनामा संपविल्याची दिनांक व वेळ :-', style: mrB),
      const SizedBox(height: 3),
      _multilineBox(v('mar18DateTime'), lines: 3),
      const SizedBox(height: 24),

      // Signatures Section
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: पंचाची सही
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('पंचाची सही', style: headerStyle),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('१)- ', style: mrB),
                    Expanded(child: _uField(v('mar11Panch1'), fontSize: 11.0)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('२)- ', style: mrB),
                    Expanded(child: _uField(v('mar11Panch2'), fontSize: 11.0)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('३)- ', style: mrB),
                    Expanded(child: _uField(v('mar11Panch3'), fontSize: 11.0)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('४)- ', style: mrB),
                    Expanded(child: _uField(v('mar11Panch4'), fontSize: 11.0)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('प्रत सादर :- मा.वैद्यकीय अधिकारी ',
                        style: mrB.copyWith(fontSize: 10.5)),
                    Expanded(child: _uField(v('mar11CopyTo'), fontSize: 11.0)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 28),

          // Right Column: तपासी अधिकारी नांव व सही शिक्का
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('तपासी अधिकारी नांव व सही शिक्का', style: headerStyle),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('नांव :- ', style: mrB),
                    Expanded(child: _uField(v('mar11IoName'), fontSize: 11.0)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('हुद्दा :- ', style: mrB),
                    Expanded(child: _uField(v('mar11IoRank'), fontSize: 11.0)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('पोलीस स्टेशन :- ', style: mrB),
                    Expanded(
                      child: _uPoliceStationPdfField(
                        v('mar11IoPs'),
                        textStyle: FormImagePdfHelper.valStyle(11.0),
                      ),
                    ),
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
        child: Text(
          'M.R.W',
          style: GoogleFonts.notoSans(
            fontSize: 9.5,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// EXHUMATION PANCHANAMA (कबर खोदून शव बाहेर काढण्याचा पंचनामा) - DEDICATED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// EXHUMATION PANCHANAMA (कबर खोदून शव बाहेर काढण्याचा पंचनामा) - DYNAMIC LAYOUT
// ─────────────────────────────────────────────────────────────────────────────

void _generateExhumationVectorPdf(
  pw.Document pdf,
  Map<String, dynamic> doc, {
  required pw.Font loraRegular,
  required pw.Font loraBold,
  required pw.Font devanagariRegular,
  required pw.Font devanagariBold,
}) {
  String v(String key) => doc[key]?.toString().trim() ?? '';

  final engBold = pw.TextStyle(
    font: loraBold,
    fontSize: 9.5,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.black,
  );
  final engStyle = pw.TextStyle(
    font: loraRegular,
    fontSize: 9.0,
    color: PdfColors.black,
  );
  final mrStyle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 10.0,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.black,
  );
  final mrBold = pw.TextStyle(
    font: devanagariBold,
    fontSize: 10.5,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.black,
  );

  pw.Widget underlineField(String text,
      {double? width, double minWidth = 20, double fontSize = 9.0}) {
    return pw.Container(
      constraints: pw.BoxConstraints(minWidth: width ?? minWidth),
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 0.6),
        ),
      ),
      child: pw.Text(
        text.isEmpty ? ' ' : text,
        style: pw.TextStyle(
          font: devanagariBold,
          fontSize: fontSize,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget multilineBox(String text, {int lines = 2, double fontSize = 9.0}) {
    return pw.Container(
      width: double.infinity,
      constraints: pw.BoxConstraints(minHeight: lines * 13.0),
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 0.6),
        ),
      ),
      child: pw.Text(
        text.isEmpty ? ' ' : text,
        maxLines: lines,
        overflow: pw.TextOverflow.clip,
        style: pw.TextStyle(
          font: devanagariBold,
          fontSize: fontSize,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget subLabel(String text) {
    return pw.Text(text, style: mrStyle);
  }

  pw.Widget injuryRow(String labelEn, String labelMr, String val) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2.5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.SizedBox(
                width: 90,
                child: pw.Text(labelEn, style: engBold),
              ),
              pw.Expanded(child: underlineField(val, fontSize: 9.0)),
            ],
          ),
          subLabel('   $labelMr'),
        ],
      ),
    );
  }

  pw.Widget secHeaderAndPoints1To8() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'EXHUMATION PANCHANAMA',
                style: engBold.copyWith(fontSize: 12),
              ),
              pw.Text(
                'कबर खोदून शव बाहेर काढण्याचा पंचनामा (Exhumation Panchanama)',
                style: mrBold.copyWith(fontSize: 11.5),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                '(Under Section - 194 B.N.S.S.)',
                style: engBold.copyWith(fontSize: 8.5),
              ),
              pw.Text(
                '( भारतीय नागरिक सुरक्षा संहिता २०२३ कलम १९४ अन्वये.)',
                style: mrBold.copyWith(fontSize: 9.5),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Divider(color: PdfColors.black, thickness: 0.8),
        pw.SizedBox(height: 5),

        // 1) Dist, PS, Year, FIR, Date
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 4,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Text('1) Dist. :- ', style: engBold),
                      pw.Expanded(child: underlineField(v('dist'))),
                    ],
                  ),
                  pw.SizedBox(height: 1),
                  subLabel('   जिल्हा'),
                ],
              ),
            ),
            pw.SizedBox(width: 14),
            pw.Expanded(
              flex: 4,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Text('P.S. :- ', style: engBold),
                      pw.Expanded(child: underlineField(v('ps'))),
                    ],
                  ),
                  pw.SizedBox(height: 1),
                  subLabel('   पो.स्टे.'),
                ],
              ),
            ),
            pw.SizedBox(width: 14),
            pw.Expanded(
              flex: 2,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Text('Year :- 20', style: engBold),
                      pw.Expanded(child: underlineField(v('year'))),
                    ],
                  ),
                  pw.SizedBox(height: 1),
                  subLabel('   वर्ष'),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 5),

        // Row 2: FIR/AD/U.D.No, Date
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 6,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Text('FIR/AD/U.D.No :- ', style: engBold),
                      pw.Expanded(child: underlineField(v('firNo'))),
                    ],
                  ),
                  pw.SizedBox(height: 1),
                  subLabel('   पहिली खबर क्र./ अकस्मात मृत्यू क्र.'),
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              flex: 4,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Text('Date :- ', style: engBold),
                      pw.Expanded(
                        child: underlineField(
                          v('firDate').isNotEmpty ? v('firDate') : v('date'),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 1),
                  subLabel('   दिनांक'),
                ],
              ),
            ),
          ],
        ),
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

        // 3) Place
        pw.Row(
          children: [
            pw.Text('3) Place From where Dead Body Found/Traced : ',
                style: engBold),
            pw.Expanded(child: underlineField(v('deadBodyFoundPlace'))),
          ],
        ),
        pw.SizedBox(height: 2),
        pw.Row(
          children: [
            pw.Text('   Place:- ', style: engStyle),
            pw.Expanded(child: underlineField(v('foundPlace'))),
            pw.SizedBox(width: 8),
            pw.Text('Date: ', style: engStyle),
            underlineField(v('foundDate'), width: 75),
            pw.SizedBox(width: 8),
            pw.Text('time: ', style: engStyle),
            underlineField(v('foundTime'), width: 50),
          ],
        ),
        subLabel('   प्रेत सापडल्याचे /मिळाल्याचे ठिकाण / जागा'),
        pw.SizedBox(height: 6),

        // 4) Shown
        pw.Row(
          children: [
            pw.Text('4) By whom Dead Body Shown                   :',
                style: engBold),
            pw.Expanded(child: underlineField(v('shownBy'))),
          ],
        ),
        subLabel('   प्रेत कोणी दाखविले :-'),
        pw.SizedBox(height: 6),

        // 5) Identified
        pw.Row(
          children: [
            pw.Text('5) By whom Dead Body Identified              :',
                style: engBold),
            pw.Expanded(child: underlineField(v('identifiedBy'))),
          ],
        ),
        subLabel('   प्रेत कोणी ओळखले :-'),
        pw.SizedBox(height: 2),
        multilineBox(v('identifiedBy2'), lines: 2),
        pw.SizedBox(height: 6),

        // 6) gender, married, age, death date/time
        pw.Row(
          children: [
            pw.Text('6) a) Dead Body Male/Female                     :',
                style: engBold),
            pw.Expanded(child: underlineField(v('gender'))),
          ],
        ),
        subLabel('   अ) प्रेत स्त्री / पुरुष जातीचे :-'),
        pw.SizedBox(height: 3),
        pw.Row(
          children: [
            pw.Text('   b) Dead Body Married/Unmarried            :',
                style: engBold),
            pw.Expanded(child: underlineField(v('married'))),
          ],
        ),
        subLabel('   ब) प्रेत विवाहीत /अविवाहीत आहे :-'),
        pw.SizedBox(height: 3),
        pw.Row(
          children: [
            pw.Text('   c) Age of Dead Body                          :',
                style: engBold),
            pw.Expanded(child: underlineField(v('age'))),
          ],
        ),
        subLabel('   क) प्रेताचे वय :-'),
        pw.SizedBox(height: 3),
        pw.Row(
          children: [
            pw.Text('   d) Date & Time of Death                      : Date: ',
                style: engBold),
            underlineField(v('deathDate'), width: 80),
            pw.SizedBox(width: 8),
            pw.Text('Time: ', style: engStyle),
            underlineField(v('deathTime'), width: 55),
          ],
        ),
        subLabel('   ड) मृत्यूची तारीख वेळ :-'),
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
        pw.SizedBox(height: 2),
        multilineBox(v('positionOfBody2'), lines: 2),
        pw.SizedBox(height: 6),

        // 8) Name & Address
        pw.Row(
          children: [
            pw.Text('8) Name and Address of Dead Body             :',
                style: engBold),
            pw.Expanded(child: underlineField(v('nameAddressDeceased'))),
          ],
        ),
        subLabel('   प्रेताचे संपूर्ण नांव व पत्ता (माहित असल्यास)'),
        pw.SizedBox(height: 2),
        multilineBox(v('nameAddressDeceased2'), lines: 3),
      ],
    );
  }

  pw.Widget secPoint9() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Text(
              '9) Description Of injuries Found on Dead Body if any :',
              style: engBold,
            ),
            pw.Expanded(child: underlineField(v('injDescription'))),
          ],
        ),
        subLabel('   प्रेताचे अंगावर असल्यास त्याचे वर्णन :'),
        pw.SizedBox(height: 4),
        injuryRow('a) Head          :', 'अ) डोके        :', v('injHead')),
        injuryRow('b) Face          :', 'ब) चेहरा        :', v('injFace')),
        injuryRow('c) Neck          :', 'क) मान         :', v('injNeck')),
        injuryRow('d) Chest         :', 'ड) छाती        :', v('injChest')),
        injuryRow('e) Stomac        :', 'इ) पोट         :', v('injStomach')),
        injuryRow('f) Right Hand    :', 'फ) उजवा हात     :', v('injRightHand')),
        injuryRow('g) Left Hand     :', 'ग) डावा हात     :', v('injLeftHand')),
        injuryRow('h) Right Leg     :', 'ह) उजवा पाय     :', v('injRightLeg')),
        injuryRow('i) Left Leg      :', 'ऐ) डावा पाय     :', v('injLeftLeg')),
        injuryRow(
            'j) Private part  :', 'जे) गुप्त भाग     :', v('injPrivatePart')),
        injuryRow('k) Back          :', 'के) पाठ        :', v('injBack')),
      ],
    );
  }

  pw.Widget secPoints10To13() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('10)   Injuries of Dead Body Caused By Accidental/Violence :',
            style: engBold),
        pw.Row(
          children: [
            pw.Text('Homicide / Other Burn / (Fair / Tejab) ',
                style: engBold.copyWith(fontSize: 8.5)),
            pw.Expanded(child: underlineField(v('injAccidentalViolence'))),
          ],
        ),
        subLabel(
            'प्रेताचे अंगावरील जखमा अपघाताच्या घोक्यातील / इत्यादी होण्यामुळे झाल्या'),
        pw.SizedBox(height: 5),
        pw.Row(
          children: [
            pw.Text('11) Weapon / Means (if any)                  :',
                style: engBold),
            pw.Expanded(child: underlineField(v('weaponMeans'))),
          ],
        ),
        subLabel('जखमा केलेल्या हत्यार/ साधन असल्यास           :'),
        pw.SizedBox(height: 5),
        pw.Row(
          children: [
            pw.Text('12) Dead Body Cool / Warm                    :',
                style: engBold),
            pw.Expanded(child: underlineField(v('bodyCoolWarm'))),
          ],
        ),
        subLabel('प्रेत थंड आहे/ गरम आहे.                       :'),
        pw.SizedBox(height: 5),
        pw.Row(
          children: [
            pw.Text('13) Position Dead Body by Poisoning          :',
                style: engBold),
            pw.Expanded(child: underlineField(v('poisoningPosition'))),
          ],
        ),
        subLabel('प्रेताची स्थिती विष प्राशन केलेला असल्यास       :'),
      ],
    );
  }

  pw.Widget secPoints14To17() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('14) (a) Finger Print has taken by Doctor Not taken Reason',
            style: engBold),
        pw.Row(
          children: [
            pw.Text('(In case of unidentified Dead Body)          :',
                style: engStyle),
            pw.Expanded(child: underlineField(v('fingerprintReason'))),
          ],
        ),
        subLabel('अनोळखी प्रेताचे डॉक्टरांकडून बोटांचे ठसे घेतले/ नाही कारण :'),
        pw.SizedBox(height: 3),
        pw.Text(
            '(b) Photo has taken/not taken reason (In case of an Identified Dead Body) :',
            style: engBold),
        underlineField(v('photoReason')),
        subLabel('अनोळखी प्रेताचे फोटो घेतले आहेत काय/नाही कारण :'),
        pw.SizedBox(height: 5),
        pw.Row(
          children: [
            pw.Text('15) Dead Body sent to P.M. / not reason: ',
                style: engBold),
            pw.Expanded(child: underlineField(v('sentToPMReason'))),
          ],
        ),
        subLabel('प्रेत (पोस्ट मार्टम) शविच्छेदन करीता पाठविले/ नाही कारण'),
        pw.SizedBox(height: 3),
        pw.Row(
          children: [
            pw.Text('(a) At which Hospital Dead Body sent to P.M.:',
                style: engBold),
            pw.Expanded(child: underlineField(v('hospitalName'))),
          ],
        ),
        subLabel('कोणत्या रूग्णालयात प्रेत पोस्ट मार्टूम करीता पाठविले :'),
        pw.SizedBox(height: 3),
        pw.Text('(b) With whom (Name No. and P.sm)            :',
            style: engBold),
        subLabel('कोणा बरोबर पाठविले (नांव व पो.स्टे.)'),
        pw.Row(
          children: [
            pw.Text('Name : ', style: engStyle),
            underlineField(v('sentOfficerName'), width: 140),
            pw.SizedBox(width: 8),
            pw.Text('B/No:- ', style: engStyle),
            underlineField(v('sentOfficerBNo'), width: 60),
            pw.SizedBox(width: 8),
            pw.Text('P.S. : ', style: engStyle),
            pw.Expanded(child: underlineField(v('sentOfficerPs'))),
          ],
        ),
        subLabel(
            'नांव                                        बक्कल नंबर                 पो.स्टे'),
        pw.SizedBox(height: 5),
        pw.Row(
          children: [
            pw.Text('16) Opinion of Panchas and Police about Death: ',
                style: engBold),
            pw.Expanded(child: underlineField(v('opinionPanchas'))),
          ],
        ),
        subLabel('पंच व पोलीसांचा मृत्यूविषयी अभिप्राय'),
        pw.SizedBox(height: 2),
        multilineBox(v('opinionPanchas2'), lines: 3),
        pw.SizedBox(height: 5),
        pw.Row(
          children: [
            pw.Text('17) More information if any                 : ',
                style: engBold),
            pw.Expanded(child: underlineField(v('moreInfo'))),
          ],
        ),
        subLabel('अधिक माहिती असल्यास'),
      ],
    );
  }

  pw.Widget secPoints10To17() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        secPoints10To13(),
        pw.SizedBox(height: 5),
        secPoints14To17(),
      ],
    );
  }

  pw.Widget secPoints18To19AndIo() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Text('18) Date and Time of panchanama    Date : -',
                style: engBold),
            underlineField(v('panchanamaDate'), width: 80),
            pw.SizedBox(width: 8),
            pw.Text('Time:', style: engStyle),
            underlineField(v('panchanamaTime'), width: 45),
            pw.Text('  To ', style: engStyle),
            underlineField(v('panchanamaTimeTo'), width: 45),
          ],
        ),
        subLabel(
            '    पंचनामा केल्याची               दिनांक : -                       वेळ : -                 ते'),
        pw.SizedBox(height: 8),

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
            pw.SizedBox(width: 14),
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
        pw.SizedBox(height: 4),

        // Panch 1
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Row(
                children: [
                  pw.Text('1) ', style: engBold),
                  pw.Expanded(child: multilineBox(v('panch1'), lines: 2)),
                ],
              ),
            ),
            pw.SizedBox(width: 14),
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
        pw.SizedBox(height: 4),

        // Panch 2
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Row(
                children: [
                  pw.Text('2) ', style: engBold),
                  pw.Expanded(child: multilineBox(v('panch2'), lines: 2)),
                ],
              ),
            ),
            pw.SizedBox(width: 14),
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
        pw.SizedBox(height: 4),

        // Panch 3
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Row(
                children: [
                  pw.Text('3) ', style: engBold),
                  pw.Expanded(child: multilineBox(v('panch3'), lines: 2)),
                ],
              ),
            ),
            pw.SizedBox(width: 14),
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
        pw.SizedBox(height: 10),

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
                  pw.SizedBox(height: 3),
                  pw.Row(
                    children: [
                      pw.Text('Name: ', style: engStyle),
                      pw.Expanded(child: underlineField(v('ioName'))),
                    ],
                  ),
                  subLabel('नांव'),
                  pw.SizedBox(height: 2),
                  pw.Row(
                    children: [
                      pw.Text('Rank: ', style: engStyle),
                      underlineField(v('ioRank'), width: 70),
                      pw.SizedBox(width: 4),
                      pw.Text('Number if any:', style: engStyle),
                      pw.Expanded(child: underlineField(v('ioNo'))),
                    ],
                  ),
                  subLabel('पद                   बक्कल नंबर'),
                  pw.SizedBox(height: 2),
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
      ],
    );
  }

  void addExhumationPage(List<pw.Widget> children, {double topMargin = 32.0}) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin:
            pw.EdgeInsets.only(left: 36, right: 36, top: topMargin, bottom: 26),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            ...children,
            pw.Spacer(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'M.R.W',
                style: pw.TextStyle(
                  font: loraRegular,
                  fontSize: 8.5,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dynamic Height Calculation in Vector Points (Usable page height = 750.0 pt)
  int lines(String text, int charsPerLine) {
    if (text.isEmpty) return 1;
    final spl = text.split('\n');
    int count = 0;
    for (final s in spl) {
      count += (s.length / charsPerLine).ceil().clamp(1, 10);
    }
    return count;
  }

  const double maxSafeContentPt = 745.0;

  final double hSec1 = 75.0 + // Header
      36.0 +
      38.0 +
      38.0 +
      60.0 +
      38.0 +
      24.0 +
      (lines(v('identifiedBy2'), 50) * 12.0).clamp(16.0, 40.0) +
      36.0 +
      36.0 +
      36.0 +
      38.0 +
      36.0 +
      36.0 +
      38.0 +
      24.0 +
      (lines(v('nameAddressDeceased2'), 50) * 12.0)
          .clamp(24.0, 50.0); // ~530 pt

  const double hSec2 = 28.0 + (11 * 17.0); // ~215 pt
  const double hSec3A = 34.0 + 22.0 + 22.0 + 22.0; // ~100 pt
  final double hSec3B = 34.0 +
      36.0 +
      24.0 +
      24.0 +
      50.0 +
      24.0 +
      (lines(v('opinionPanchas2'), 50) * 12.0).clamp(24.0, 50.0) +
      22.0; // ~238 pt
  const double hSec4 = 28.0 + 110.0 + 95.0; // ~233 pt

  if (hSec1 + 6.0 + hSec2 <= maxSafeContentPt) {
    // If Point 9 can fit on Page 1
    addExhumationPage([
      secHeaderAndPoints1To8(),
      pw.SizedBox(height: 6),
      secPoint9(),
    ]);

    if (hSec3A + 5.0 + hSec3B + 8.0 + hSec4 <= maxSafeContentPt) {
      addExhumationPage([
        secPoints10To17(),
        pw.SizedBox(height: 8),
        secPoints18To19AndIo(),
      ]);
    } else {
      addExhumationPage([secPoints10To17()]);
      addExhumationPage([secPoints18To19AndIo()]);
    }
  } else {
    // Point 9 does not fit on Page 1 -> Page 1 gets ONLY Header + Points 1 to 8
    addExhumationPage([secHeaderAndPoints1To8()]);

    if (hSec2 + 6.0 + hSec3A + 5.0 + hSec3B <= maxSafeContentPt) {
      addExhumationPage([
        secPoint9(),
        pw.SizedBox(height: 6),
        secPoints10To17(),
      ], topMargin: 36.0);
      addExhumationPage([secPoints18To19AndIo()]);
    } else if (hSec2 + 6.0 + hSec3A <= maxSafeContentPt) {
      addExhumationPage([
        secPoint9(),
        pw.SizedBox(height: 6),
        secPoints10To13(),
      ], topMargin: 36.0);
      if (hSec3B + 8.0 + hSec4 <= maxSafeContentPt) {
        addExhumationPage([
          secPoints14To17(),
          pw.SizedBox(height: 8),
          secPoints18To19AndIo(),
        ]);
      } else {
        addExhumationPage([secPoints14To17()]);
        addExhumationPage([secPoints18To19AndIo()]);
      }
    } else {
      addExhumationPage([secPoint9()], topMargin: 36.0);
      addExhumationPage([secPoints10To17()]);
      addExhumationPage([secPoints18To19AndIo()]);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EXHUMATION PANCHANAMA - FLUTTER WIDGET BUILDERS (IMAGE-BASED PREVIEW / PDF)
// ─────────────────────────────────────────────────────────────────────────────

Widget _buildExhumationPageWidget(
  Map<String, dynamic> doc, {
  required List<Widget> children,
  double topPadding = 32.0,
}) {
  return FormImagePdfHelper.buildA4Page(
    padding: EdgeInsets.only(left: 36, right: 36, top: topPadding, bottom: 26),
    children: [
      ...children,
      const Spacer(),
      Align(
        alignment: Alignment.centerRight,
        child: Text(
          'M.R.W',
          style: GoogleFonts.lora(
            fontSize: 9.5,
            fontStyle: FontStyle.italic,
            color: Colors.black87,
          ),
        ),
      ),
    ],
  );
}

Widget _buildExhumationHeaderWidget(Map<String, dynamic> doc) {
  return Center(
    child: Column(
      children: [
        Text(
          'EXHUMATION PANCHANAMA',
          style: GoogleFonts.lora(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'कबर खोदून शव बाहेर काढण्याचा पंचनामा (Exhumation Panchanama)',
          style: GoogleFonts.notoSansDevanagari(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '(Under Section - 194 B.N.S.S.)',
          style: GoogleFonts.lora(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          '( भारतीय नागरिक सुरक्षा संहिता २०२३ कलम १९४ अन्वये.)',
          style: GoogleFonts.notoSansDevanagari(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        const Divider(color: Colors.black, thickness: 0.8),
        const SizedBox(height: 6),
      ],
    ),
  );
}

Widget _buildExhumationPoints1To8Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final engBold = GoogleFonts.lora(
    fontSize: 10.0,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );
  final engStyle = GoogleFonts.lora(
    fontSize: 9.5,
    color: Colors.black87,
  );
  final mrStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 11.2,
    fontWeight: FontWeight.w600,
    color: Colors.black,
    height: 1.2,
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 1) Dist, PS, Year
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1.0),
                      child: Text('1) Dist. :- ', style: engBold),
                    ),
                    Expanded(child: _uField(v('dist'), fontSize: 10.5)),
                  ],
                ),
                const SizedBox(height: 1),
                Text('जिल्हा', style: mrStyle),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1.0),
                      child: Text('P.S. :- ', style: engBold),
                    ),
                    Expanded(child: _uField(v('ps'), fontSize: 10.5)),
                  ],
                ),
                const SizedBox(height: 1),
                Text('पो.स्टे.', style: mrStyle),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1.0),
                      child: Text('Year :- 20', style: engBold),
                    ),
                    Expanded(child: _uField(v('year'), fontSize: 10.5)),
                  ],
                ),
                const SizedBox(height: 1),
                Text('वर्ष', style: mrStyle),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),

      // Row 2: FIR/AD/U.D.No, Date
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1.0),
                      child: Text('FIR/AD/U.D.No :- ', style: engBold),
                    ),
                    Expanded(child: _uField(v('firNo'), fontSize: 10.5)),
                  ],
                ),
                const SizedBox(height: 1),
                Text('पहिली खबर क्र./ अकस्मात मृत्यू क्र.', style: mrStyle),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1.0),
                      child: Text('Date :- ', style: engBold),
                    ),
                    Expanded(
                      child: _uField(
                        v('firDate').isNotEmpty ? v('firDate') : v('date'),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text('दिनांक', style: mrStyle),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 7),

      // 2) Act and Section
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('2) Act and Section: - ', style: engBold),
          ),
          Expanded(child: _uField(v('actSections'), fontSize: 10.5)),
        ],
      ),
      const SizedBox(height: 1),
      Text('   अधिनियम व कलमे :-', style: mrStyle),
      const SizedBox(height: 7),

      // 3) Place
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('3) Place From where Dead Body Found/Traced : ',
                style: engBold),
          ),
          Expanded(child: _uField(v('deadBodyFoundPlace'), fontSize: 10.5)),
        ],
      ),
      const SizedBox(height: 3),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('   Place:- ', style: engStyle),
          ),
          Expanded(child: _uField(v('foundPlace'), fontSize: 10.5)),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('Date: ', style: engStyle),
          ),
          _uField(v('foundDate'), width: 85, fontSize: 10.5),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('time: ', style: engStyle),
          ),
          _uField(v('foundTime'), width: 60, fontSize: 10.5),
        ],
      ),
      const SizedBox(height: 1),
      Text('   प्रेत सापडल्याचे /मिळाल्याचे ठिकाण / जागा', style: mrStyle),
      const SizedBox(height: 7),

      // 4) Shown
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('4) By whom Dead Body Shown                   :',
                style: engBold),
          ),
          Expanded(child: _uField(v('shownBy'), fontSize: 10.5)),
        ],
      ),
      const SizedBox(height: 1),
      Text('   प्रेत कोणी दाखविले :-', style: mrStyle),
      const SizedBox(height: 7),

      // 5) Identified
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('5) By whom Dead Body Identified              :',
                style: engBold),
          ),
          Expanded(child: _uField(v('identifiedBy'), fontSize: 10.5)),
        ],
      ),
      const SizedBox(height: 1),
      Text('   प्रेत कोणी ओळखले :-', style: mrStyle),
      const SizedBox(height: 2),
      _multilineBox(v('identifiedBy2'), lines: 2),
      const SizedBox(height: 7),

      // 6) gender, married, age, death date/time
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('6) a) Dead Body Male/Female                     :',
                style: engBold),
          ),
          Expanded(child: _uField(v('gender'), fontSize: 10.5)),
        ],
      ),
      const SizedBox(height: 1),
      Text('   अ) प्रेत स्त्री / पुरुष जातीचे :-', style: mrStyle),
      const SizedBox(height: 4),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('   b) Dead Body Married/Unmarried            :',
                style: engBold),
          ),
          Expanded(child: _uField(v('married'), fontSize: 10.5)),
        ],
      ),
      const SizedBox(height: 1),
      Text('   ब) प्रेत विवाहीत /अविवाहीत आहे :-', style: mrStyle),
      const SizedBox(height: 4),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('   c) Age of Dead Body                          :',
                style: engBold),
          ),
          Expanded(child: _uField(v('age'), fontSize: 10.5)),
        ],
      ),
      const SizedBox(height: 1),
      Text('   क) प्रेताचे वय :-', style: mrStyle),
      const SizedBox(height: 4),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 2,
        runSpacing: 2,
        children: [
          Text('   ड) मृत्यूची तारीख वेळ :-                     ',
              style: mrStyle),
          Text('Date : ', style: engStyle),
          _uField(v('deathDate'), width: 90, fontSize: 10.5),
          const SizedBox(width: 14),
          Text('Time : ', style: engStyle),
          _uField(v('deathTime'), width: 65, fontSize: 10.5),
        ],
      ),
      const SizedBox(height: 1),
      Text(
        '                                                तारीख                                   वेळ',
        style: mrStyle,
      ),
      const SizedBox(height: 7),

      // 7) Position
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('7) Position of Dead Body                     :',
                style: engBold),
          ),
          Expanded(child: _uField(v('positionOfBody'), fontSize: 10.5)),
        ],
      ),
      const SizedBox(height: 1),
      Text('   प्रेताची स्थिती / अवस्था (जागा)', style: mrStyle),
      const SizedBox(height: 2),
      _multilineBox(v('positionOfBody2'), lines: 2),
      const SizedBox(height: 7),

      // 8) Name & Address
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('8) Name and Address of Dead Body             :',
                style: engBold),
          ),
          Expanded(child: _uField(v('nameAddressDeceased'), fontSize: 10.5)),
        ],
      ),
      const SizedBox(height: 1),
      Text('   प्रेताचे संपूर्ण नांव व पत्ता (माहित असल्यास)', style: mrStyle),
      const SizedBox(height: 2),
      _multilineBox(v('nameAddressDeceased2'), lines: 3),
    ],
  );
}

Widget _buildExhumationPoint9Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final engBold = GoogleFonts.lora(
    fontSize: 10.0,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );
  final mrStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 11.2,
    fontWeight: FontWeight.w600,
    color: Colors.black,
    height: 1.2,
  );

  Widget injuryRow(String labelEn, String labelMr, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1.0),
                child: SizedBox(
                  width: 100,
                  child: Text(labelEn, style: engBold),
                ),
              ),
              Expanded(child: _uField(val, fontSize: 10.5)),
            ],
          ),
          const SizedBox(height: 1),
          Text('   $labelMr', style: mrStyle),
        ],
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text(
              '9) Description Of injuries Found on Dead Body if any :',
              style: engBold,
            ),
          ),
          Expanded(child: _uField(v('injDescription'), fontSize: 10.5)),
        ],
      ),
      const SizedBox(height: 1),
      Text('   प्रेताचे अंगावर असल्यास त्याचे वर्णन :', style: mrStyle),
      const SizedBox(height: 6),
      injuryRow('a) Head          :', 'अ) डोके        :', v('injHead')),
      injuryRow('b) Face          :', 'ब) चेहरा        :', v('injFace')),
      injuryRow('c) Neck          :', 'क) मान         :', v('injNeck')),
      injuryRow('d) Chest         :', 'ड) छाती        :', v('injChest')),
      injuryRow('e) Stomac        :', 'इ) पोट         :', v('injStomach')),
      injuryRow('f) Right Hand    :', 'फ) उजवा हात     :', v('injRightHand')),
      injuryRow('g) Left Hand     :', 'ग) डावा हात     :', v('injLeftHand')),
      injuryRow('h) Right Leg     :', 'ह) उजवा पाय     :', v('injRightLeg')),
      injuryRow('i) Left Leg      :', 'ऐ) डावा पाय     :', v('injLeftLeg')),
      injuryRow(
          'j) Private part  :', 'जे) गुप्त भाग     :', v('injPrivatePart')),
      injuryRow('k) Back          :', 'के) पाठ        :', v('injBack')),
    ],
  );
}

Widget _buildExhumationPoints10To13Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final engBold = GoogleFonts.lora(
    fontSize: 10.0,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );
  final mrStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 11.2,
    fontWeight: FontWeight.w600,
    color: Colors.black,
    height: 1.2,
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('10)   Injuries of Dead Body Caused By Accidental/Violence :',
          style: engBold),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('Homicide / Other Burn / (Fair / Tejab) ',
                style: engBold.copyWith(fontSize: 8.5)),
          ),
          Expanded(child: _uField(v('injAccidentalViolence'), fontSize: 10.0)),
        ],
      ),
      Text(
          'प्रेताचे अंगावरील जखमा अपघाताच्या घोक्यातील / इत्यादी होण्यामुळे झाल्या',
          style: mrStyle),
      const SizedBox(height: 5),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('11) Weapon / Means (if any)                  :',
                style: engBold),
          ),
          Expanded(child: _uField(v('weaponMeans'), fontSize: 10.0)),
        ],
      ),
      Text('जखमा केलेल्या हत्यार/ साधन असल्यास           :', style: mrStyle),
      const SizedBox(height: 5),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('12) Dead Body Cool / Warm                    :',
                style: engBold),
          ),
          Expanded(child: _uField(v('bodyCoolWarm'), fontSize: 10.0)),
        ],
      ),
      Text('प्रेत थंड आहे/ गरम आहे.                       :', style: mrStyle),
      const SizedBox(height: 5),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('13) Position Dead Body by Poisoning          :',
                style: engBold),
          ),
          Expanded(child: _uField(v('poisoningPosition'), fontSize: 10.0)),
        ],
      ),
      Text('प्रेताची स्थिती विष प्राशन केलेला असल्यास       :', style: mrStyle),
    ],
  );
}

Widget _buildExhumationPoints14To17Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final engBold = GoogleFonts.lora(
    fontSize: 10.0,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );
  final engStyle = GoogleFonts.lora(
    fontSize: 9.5,
    color: Colors.black87,
  );
  final mrStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 11.2,
    fontWeight: FontWeight.w600,
    color: Colors.black,
    height: 1.2,
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('14) (a) Finger Print has taken by Doctor Not taken Reason',
          style: engBold),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('(In case of unidentified Dead Body)          :',
                style: engStyle),
          ),
          Expanded(child: _uField(v('fingerprintReason'), fontSize: 10.0)),
        ],
      ),
      Text('अनोळखी प्रेताचे डॉक्टरांकडून बोटांचे ठसे घेतले/ नाही कारण :',
          style: mrStyle),
      const SizedBox(height: 3),
      Text(
          '(b) Photo has taken/not taken reason (In case of an Identified Dead Body) :',
          style: engBold),
      _uField(v('photoReason'), fontSize: 10.0),
      Text('अनोळखी प्रेताचे फोटो घेतले आहेत काय/नाही कारण :', style: mrStyle),
      const SizedBox(height: 5),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('15) Dead Body sent to P.M. / not reason: ',
                style: engBold),
          ),
          Expanded(child: _uField(v('sentToPMReason'), fontSize: 10.0)),
        ],
      ),
      Text('प्रेत (पोस्ट मार्टम) शविच्छेदन करीता पाठविले/ नाही कारण',
          style: mrStyle),
      const SizedBox(height: 3),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('(a) At which Hospital Dead Body sent to P.M.:',
                style: engBold),
          ),
          Expanded(child: _uField(v('hospitalName'), fontSize: 10.0)),
        ],
      ),
      Text('कोणत्या रूग्णालयात प्रेत पोस्ट मार्टूम करीता पाठविले :',
          style: mrStyle),
      const SizedBox(height: 3),
      Text('(b) With whom (Name No. and P.sm)            :', style: engBold),
      Text('कोणा बरोबर पाठविले (नांव व पो.स्टे.)', style: mrStyle),
      const SizedBox(height: 2),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('Name : ', style: engStyle),
          ),
          _uField(v('sentOfficerName'), width: 150, fontSize: 10.0),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('B/No:- ', style: engStyle),
          ),
          _uField(v('sentOfficerBNo'), width: 65, fontSize: 10.0),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('P.S. : ', style: engStyle),
          ),
          Expanded(child: _uField(v('sentOfficerPs'), fontSize: 10.0)),
        ],
      ),
      Text(
          'नांव                                        बक्कल नंबर                 पो.स्टे',
          style: mrStyle),
      const SizedBox(height: 5),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('16) Opinion of Panchas and Police about Death: ',
                style: engBold),
          ),
          Expanded(child: _uField(v('opinionPanchas'), fontSize: 10.0)),
        ],
      ),
      Text('पंच व पोलीसांचा मृत्यूविषयी अभिप्राय', style: mrStyle),
      const SizedBox(height: 2),
      _multilineBox(v('opinionPanchas2'), lines: 3),
      const SizedBox(height: 5),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Text('17) More information if any                 : ',
                style: engBold),
          ),
          Expanded(child: _uField(v('moreInfo'), fontSize: 10.0)),
        ],
      ),
      Text('अधिक माहिती असल्यास', style: mrStyle),
    ],
  );
}

Widget _buildExhumationPoints10To17Widget(Map<String, dynamic> doc) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildExhumationPoints10To13Widget(doc),
      const SizedBox(height: 5),
      _buildExhumationPoints14To17Widget(doc),
    ],
  );
}

Widget _buildExhumationPoints18To19AndIoWidget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final engBold = GoogleFonts.lora(
    fontSize: 10.0,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );
  final engStyle = GoogleFonts.lora(
    fontSize: 9.5,
    color: Colors.black87,
  );
  final mrStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 11.2,
    fontWeight: FontWeight.w600,
    color: Colors.black,
    height: 1.2,
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 2,
        runSpacing: 2,
        children: [
          Text('18) Date and Time of panchanama    ', style: engBold),
          Text('Date : -', style: engStyle),
          _uField(v('panchanamaDate'), width: 80, fontSize: 10.0),
          const SizedBox(width: 8),
          Text('Time:', style: engStyle),
          _uField(v('panchanamaTime'), width: 50, fontSize: 10.0),
          Text('  To ', style: engStyle),
          _uField(v('panchanamaTimeTo'), width: 50, fontSize: 10.0),
        ],
      ),
      Text(
        '    पंचनामा केल्याची               दिनांक : -                       वेळ : -                 ते',
        style: mrStyle,
      ),
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
          const SizedBox(width: 14),
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
      const SizedBox(height: 4),

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
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              children: [
                Text('1) ', style: engBold),
                Expanded(child: _uField(v('panch1Sig'), fontSize: 10.0)),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),

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
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              children: [
                Text('2) ', style: engBold),
                Expanded(child: _uField(v('panch2Sig'), fontSize: 10.0)),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),

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
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              children: [
                Text('3) ', style: engBold),
                Expanded(child: _uField(v('panch3Sig'), fontSize: 10.0)),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),

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
                Text('तपासणी करणाऱ्या अधिकाऱ्यांची नांव व सह्या',
                    style: mrStyle),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text('Name: ', style: engStyle),
                    Expanded(child: _uField(v('ioName'), fontSize: 10.0)),
                  ],
                ),
                Text('नांव', style: mrStyle),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('Rank: ', style: engStyle),
                    _uField(v('ioRank'), width: 80, fontSize: 10.0),
                    const SizedBox(width: 4),
                    Text('Number if any:', style: engStyle),
                    Expanded(child: _uField(v('ioNo'), fontSize: 10.0)),
                  ],
                ),
                Text('पद                   बक्कल नंबर', style: mrStyle),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('Posting and Address:', style: engStyle),
                    Expanded(child: _uField(v('ioPosting'), fontSize: 10.0)),
                  ],
                ),
                Text('नेमणूक व पत्ता', style: mrStyle),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}

List<Widget> _buildExhumationPages(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';

  int lines(String text, int charsPerLine) {
    if (text.isEmpty) return 1;
    final spl = text.split('\n');
    int count = 0;
    for (final s in spl) {
      count += (s.length / charsPerLine).ceil().clamp(1, 10);
    }
    return count;
  }

  // Realistic heights in logical pixels:
  // Total A4 height is 1123.0 px.
  // Padding: top 32, bottom 26 -> 58 px.
  // M.R.W is ~20 px.
  // Usable height is 1123 - 58 - 20 = 1045.0 px.
  // Safe ceiling of 1005.0 px ensures zero bottom overflow under all conditions.
  const double maxSafeContentPx = 1005.0;

  // Sec 1: Header + Points 1 to 8 (Base ~836 px + dynamic multi-line fields)
  final double hSec1 = 88.0 + // Header
      43.0 + // 1) Dist, PS, Year
      45.0 + // 2) FIR/AD/UD No, Date
      45.0 + // 2) Act and Section
      73.0 + // 3) Place from where Found
      45.0 + // 4) Shown by
      40.0 +
      (lines(v('identifiedBy2'), 50) * 18.0)
          .clamp(36.0, 90.0) + // 5) Identified by
      42.0 +
      42.0 +
      42.0 +
      45.0 + // 6) Gender, Married, Age, Death date/time
      42.0 +
      42.0 +
      45.0 + // 7) Complexion, Height/Build, ID marks
      40.0 +
      (lines(v('nameAddressDeceased2'), 50) * 18.0)
          .clamp(54.0, 110.0); // 8) Name/Address

  // Sec 2: Point 9 (Injuries Title + 11 injury items)
  const double hSec2 = 44.0 + (11 * 39.5); // ~478.5 px

  // Sec 3A: Points 10 to 13
  const double hSec3A = 55.0 + 39.0 + 39.0 + 39.0; // ~172.0 px

  // Sec 3B: Points 14 to 17
  final double hSec3B = 53.0 +
      55.0 +
      37.0 +
      37.0 +
      73.0 +
      38.0 +
      (lines(v('opinionPanchas2'), 50) * 18.0).clamp(54.0, 110.0) +
      34.0; // ~381.0 px

  // Sec 4: Points 18 to 19 + IO Signature Block
  const double hSec4 = 44.0 + 36.0 + 48.0 + 48.0 + 54.0 + 153.0; // ~383.0 px

  final pages = <Widget>[];

  // PAGE 1: Header + Points 1 to 8
  // Check if Point 9 can fit on Page 1:
  if (hSec1 + 6.0 + hSec2 <= maxSafeContentPx) {
    // Fits (theoretically only if doc were drastically smaller, but safe guard)
    pages.add(_buildExhumationPageWidget(
      doc,
      children: [
        _buildExhumationHeaderWidget(doc),
        _buildExhumationPoints1To8Widget(doc),
        const SizedBox(height: 6),
        _buildExhumationPoint9Widget(doc),
      ],
    ));

    // Handle remaining sections on subsequent pages
    if (hSec3A + 5.0 + hSec3B + 8.0 + hSec4 <= maxSafeContentPx) {
      pages.add(_buildExhumationPageWidget(
        doc,
        children: [
          _buildExhumationPoints10To17Widget(doc),
          const SizedBox(height: 8),
          _buildExhumationPoints18To19AndIoWidget(doc),
        ],
      ));
    } else {
      pages.add(_buildExhumationPageWidget(
        doc,
        children: [_buildExhumationPoints10To17Widget(doc)],
      ));
      pages.add(_buildExhumationPageWidget(
        doc,
        children: [_buildExhumationPoints18To19AndIoWidget(doc)],
      ));
    }
  } else {
    // Point 9 does NOT fit on Page 1 -> Page 1 gets ONLY Header + Points 1 to 8.
    pages.add(_buildExhumationPageWidget(
      doc,
      children: [
        _buildExhumationHeaderWidget(doc),
        _buildExhumationPoints1To8Widget(doc),
      ],
    ));

    // PAGE 2: Point 9 automatically starts on Page 2 with proper top margin.
    // Check what fits with Point 9 on Page 2:
    if (hSec2 + 6.0 + hSec3A + 5.0 + hSec3B <= maxSafeContentPx) {
      // Points 10 to 17 fits completely on Page 2 with Point 9!
      pages.add(_buildExhumationPageWidget(
        doc,
        topPadding: 40.0,
        children: [
          _buildExhumationPoint9Widget(doc),
          const SizedBox(height: 6),
          _buildExhumationPoints10To17Widget(doc),
        ],
      ));

      // PAGE 3: Points 18 to 19 + IO Signature Block
      pages.add(_buildExhumationPageWidget(
        doc,
        children: [
          _buildExhumationPoints18To19AndIoWidget(doc),
        ],
      ));
    } else if (hSec2 + 6.0 + hSec3A <= maxSafeContentPx) {
      // Points 10 to 13 fits on Page 2 with Point 9; Points 14 to 17 moves to Page 3
      pages.add(_buildExhumationPageWidget(
        doc,
        topPadding: 40.0,
        children: [
          _buildExhumationPoint9Widget(doc),
          const SizedBox(height: 6),
          _buildExhumationPoints10To13Widget(doc),
        ],
      ));

      // Check if Points 14 to 17 + Points 18 to 19 and IO fit on Page 3:
      if (hSec3B + 8.0 + hSec4 <= maxSafeContentPx) {
        pages.add(_buildExhumationPageWidget(
          doc,
          children: [
            _buildExhumationPoints14To17Widget(doc),
            const SizedBox(height: 8),
            _buildExhumationPoints18To19AndIoWidget(doc),
          ],
        ));
      } else {
        pages.add(_buildExhumationPageWidget(
          doc,
          children: [_buildExhumationPoints14To17Widget(doc)],
        ));
        pages.add(_buildExhumationPageWidget(
          doc,
          children: [_buildExhumationPoints18To19AndIoWidget(doc)],
        ));
      }
    } else {
      // Point 9 alone on Page 2
      pages.add(_buildExhumationPageWidget(
        doc,
        topPadding: 40.0,
        children: [_buildExhumationPoint9Widget(doc)],
      ));

      if (hSec3A + 5.0 + hSec3B + 8.0 + hSec4 <= maxSafeContentPx) {
        pages.add(_buildExhumationPageWidget(
          doc,
          children: [
            _buildExhumationPoints10To17Widget(doc),
            const SizedBox(height: 8),
            _buildExhumationPoints18To19AndIoWidget(doc),
          ],
        ));
      } else {
        pages.add(_buildExhumationPageWidget(
          doc,
          children: [_buildExhumationPoints10To17Widget(doc)],
        ));
        pages.add(_buildExhumationPageWidget(
          doc,
          children: [_buildExhumationPoints18To19AndIoWidget(doc)],
        ));
      }
    }
  }

  return pages;
}

@visibleForTesting
List<Widget> buildExhumationPagesForTesting(Map<String, dynamic> doc) =>
    _buildExhumationPages(doc);

// ─────────────────────────────────────────────────────────────────────────────
// 14-Point Medical Officer Form (१४-कलमी फॉर्म) Helpers & Pages
// ─────────────────────────────────────────────────────────────────────────────

String _formatDateTimeKal14(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';

  // 1. Check for ISO format: YYYY-MM-DD[T or space]HH:MM[:SS]
  final isoMatch = RegExp(
    r'^(\d{4})-(\d{1,2})-(\d{1,2})(?:[T\s]+(\d{1,2}):(\d{1,2}))?',
  ).firstMatch(trimmed);
  if (isoMatch != null) {
    final y = isoMatch.group(1)!;
    final m = isoMatch.group(2)!.padLeft(2, '0');
    final d = isoMatch.group(3)!.padLeft(2, '0');
    final hh = isoMatch.group(4);
    final mm = isoMatch.group(5);
    final timeStr = hh != null && mm != null
        ? ', ${hh.padLeft(2, '0')}:${mm.padLeft(2, '0')}'
        : '';
    return '$d/$m/$y$timeStr';
  }

  // 2. Check for DD-MM-YYYY or DD/MM/YYYY with optional time
  final dmyMatch = RegExp(
    r'^(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})(?:[,\s]+(\d{1,2}):(\d{1,2}))?',
  ).firstMatch(trimmed);
  if (dmyMatch != null) {
    final d = dmyMatch.group(1)!.padLeft(2, '0');
    final m = dmyMatch.group(2)!.padLeft(2, '0');
    var y = dmyMatch.group(3)!;
    if (y.length == 2) y = '20$y';
    final hh = dmyMatch.group(4);
    final mm = dmyMatch.group(5);
    final timeStr = hh != null && mm != null
        ? ', ${hh.padLeft(2, '0')}:${mm.padLeft(2, '0')}'
        : '';
    return '$d/$m/$y$timeStr';
  }

  // 3. Check for Time only: HH:MM
  final timeOnly = RegExp(r'^(\d{1,2}):(\d{1,2})$').firstMatch(trimmed);
  if (timeOnly != null) {
    return '${timeOnly.group(1)!.padLeft(2, '0')}:${timeOnly.group(2)!.padLeft(2, '0')}';
  }

  return trimmed;
}

class _Kal14LinedText extends StatelessWidget {
  final String text;
  final int minLines;
  final double lineHeight;
  final TextStyle textStyle;

  const _Kal14LinedText({
    required this.text,
    this.minLines = 1,
    this.lineHeight = 23.0,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final val = text.trim();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : 714.0;

        int lines = minLines;
        if (val.isNotEmpty) {
          final tp = TextPainter(
            text: TextSpan(
              text: val,
              style: textStyle.copyWith(
                height: lineHeight / (textStyle.fontSize ?? 11.5),
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: (width - 8) > 0 ? (width - 8) : 100);

          final measuredLines = tp.computeLineMetrics().length;
          final newlineCount = '\n'.allMatches(val).length + 1;
          final contentLines =
              measuredLines > newlineCount ? measuredLines : newlineCount;
          if (contentLines > lines) {
            lines = contentLines;
          }
        }

        final totalHeight = lines * lineHeight;

        return SizedBox(
          width: width,
          height: totalHeight,
          child: CustomPaint(
            painter: _Kal14LinePainter(
              lines: lines,
              lineHeight: lineHeight,
              lineColor: Colors.black54,
            ),
            child: SizedBox(
              width: width,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  val.isEmpty ? ' ' : val,
                  softWrap: true,
                  style: textStyle.copyWith(
                    height: lineHeight / (textStyle.fontSize ?? 11.5),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Kal14LinePainter extends CustomPainter {
  final int lines;
  final double lineHeight;
  final Color lineColor;

  const _Kal14LinePainter({
    required this.lines,
    required this.lineHeight,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= lines; i++) {
      final y = ((i * lineHeight) - 1.0).clamp(1.0, size.height - 0.5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _Kal14LinePainter oldDelegate) {
    return oldDelegate.lines != lines ||
        oldDelegate.lineHeight != lineHeight ||
        oldDelegate.lineColor != lineColor;
  }
}

Widget _kal14FieldBlock({
  required String labelEn,
  required String labelMr,
  required String value,
  int minLines = 1,
  double lineHeight = 23.0,
  required TextStyle engStyle,
  required TextStyle mrStyle,
  required TextStyle valStyle,
  double bottomSpacing = 10.0,
}) {
  return Padding(
    padding: EdgeInsets.only(bottom: bottomSpacing),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (labelEn.isNotEmpty) Text(labelEn, style: engStyle),
        if (labelMr.isNotEmpty) ...[
          const SizedBox(height: 1),
          Text(labelMr, style: mrStyle),
        ],
        const SizedBox(height: 3),
        _Kal14LinedText(
          text: value,
          minLines: minLines,
          lineHeight: lineHeight,
          textStyle: valStyle,
        ),
      ],
    ),
  );
}

Widget _kal14HabitRow({
  required String labelEn,
  required String labelMr,
  required dynamic checkedVal,
  required String daysVal,
  required TextStyle engStyle,
  required TextStyle mrStyle,
  required TextStyle valStyle,
  double bottomSpacing = 8.0,
}) {
  final isChecked = checkedVal == true ||
      checkedVal?.toString().toLowerCase() == 'true' ||
      checkedVal?.toString() == 'होय' ||
      checkedVal?.toString() == 'yes';
  final days = daysVal.trim();

  return Padding(
    padding: EdgeInsets.only(bottom: bottomSpacing),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(labelEn, style: engStyle.copyWith(fontSize: 10.0)),
              const SizedBox(height: 1),
              Text(labelMr, style: mrStyle.copyWith(fontSize: 9.5)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            border: Border.all(
              color: isChecked ? Colors.green.shade800 : Colors.grey.shade400,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(4),
            color: isChecked ? Colors.green.shade50 : Colors.grey.shade50,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'होय',
                style: GoogleFonts.notoSansDevanagari(
                  fontSize: 10.0,
                  fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                  color: isChecked ? Colors.green.shade900 : Colors.black54,
                  decoration: isChecked ? TextDecoration.underline : null,
                ),
              ),
              Text(
                ' / ',
                style: GoogleFonts.poppins(
                  fontSize: 10.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              Text(
                'नाही',
                style: GoogleFonts.notoSansDevanagari(
                  fontSize: 10.0,
                  fontWeight: !isChecked ? FontWeight.bold : FontWeight.normal,
                  color: !isChecked ? Colors.black87 : Colors.black54,
                  decoration: !isChecked ? TextDecoration.underline : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 140,
          child: Row(
            children: [
              Text(
                'दिवस / Days: ',
                style: mrStyle.copyWith(fontSize: 9.5),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _Kal14LinedText(
                  text: days,
                  minLines: 1,
                  lineHeight: 21.0,
                  textStyle: valStyle.copyWith(fontSize: 10.5),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildKalmi14Pg1Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';

  final engBold = GoogleFonts.poppins(
    fontSize: 10.5,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  final mrBold = GoogleFonts.notoSansDevanagari(
    fontSize: 10.0,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
    height: 1.25,
  );
  final valStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 11.0,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 22),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Top Tag
      const Align(
        alignment: Alignment.centerRight,
        child: Text(
          'Page 12 (१४-कलमी फॉर्म)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
      const SizedBox(height: 2),
      const Divider(color: Colors.black, thickness: 1.0, height: 6),
      const SizedBox(height: 4),

      // Form Heading
      Center(
        child: Column(
          children: [
            Text(
              '14-Clause Form (to be submitted with Inquest Panchanama)',
              style: GoogleFonts.poppins(
                fontSize: 13.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              '१४ कलमी फॉर्म व इन्क्वेस्ट पंचनामा सोबत द्यावाचा फॉर्म',
              style: GoogleFonts.notoSansDevanagari(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              'Submitted to Medical Officer / मा.वैद्यकीय अधिकारी यांना सादर',
              style: GoogleFonts.notoSansDevanagari(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 4),
      const Divider(color: Colors.black, thickness: 0.8, height: 6),
      const SizedBox(height: 6),

      // 1) Name and age
      _kal14FieldBlock(
        labelEn: '1) Name and age of deceased :-',
        labelMr: '१) मृतकाचे नांव व वय :',
        value: v('kal14NameAge'),
        minLines: 1,
        lineHeight: 23.0,
        engStyle: engBold,
        mrStyle: mrBold,
        valStyle: valStyle,
        bottomSpacing: 8,
      ),

      // 2) Full address
      _kal14FieldBlock(
        labelEn: '2) Full address of deceased (village, taluka, district) :-',
        labelMr: '२) मृतकाचा पूर्ण पत्ता गांव तालुका जिल्हा:',
        value: v('kal14Address'),
        minLines: 2,
        lineHeight: 23.0,
        engStyle: engBold,
        mrStyle: mrBold,
        valStyle: valStyle,
        bottomSpacing: 8,
      ),

      // 3) Shav From & To
      _kal14FieldBlock(
        labelEn: '3) Place from where dead body was brought :-',
        labelMr:
            '३) मृतकाचे शव (प्रेत) ज्या ठिकाणाहुन आणले त्या जागेचे नांव पत्ता :',
        value: v('kal14ShavFrom'),
        minLines: 2,
        lineHeight: 23.0,
        engStyle: engBold,
        mrStyle: mrBold,
        valStyle: valStyle,
        bottomSpacing: 6,
      ),
      _kal14FieldBlock(
        labelEn: 'Place to which dead body was brought :-',
        labelMr: 'आणले त्या जागेचे नांव पत्ता :',
        value: v('kal14ShavTo'),
        minLines: 2,
        lineHeight: 23.0,
        engStyle: engBold,
        mrStyle: mrBold,
        valStyle: valStyle,
        bottomSpacing: 8,
      ),

      // 4) Mother's Name & Address
      _kal14FieldBlock(
        labelEn: "4) Full name and address of deceased's mother :-",
        labelMr: '४) मृतकाचे आईचे पूर्ण नांव व पत्ता :',
        value: v('kal14AaiName'),
        minLines: 2,
        lineHeight: 23.0,
        engStyle: engBold,
        mrStyle: mrBold,
        valStyle: valStyle,
        bottomSpacing: 8,
      ),

      // 5) Father's Name & Address
      _kal14FieldBlock(
        labelEn: "5) Full name and address of deceased's father :-",
        labelMr: '५) मृतकाचे वडीलांचे पूर्ण नांव व पत्ता :',
        value: v('kal14BaapName'),
        minLines: 2,
        lineHeight: 23.0,
        engStyle: engBold,
        mrStyle: mrBold,
        valStyle: valStyle,
        bottomSpacing: 8,
      ),

      // 6) Religion & Occupation
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('6) Religion of deceased :-', style: engBold),
                  const SizedBox(height: 1),
                  Text('६) मृतकाचा धर्म :', style: mrBold),
                  const SizedBox(height: 3),
                  _Kal14LinedText(
                    text: v('kal14Dharm'),
                    minLines: 1,
                    lineHeight: 23.0,
                    textStyle: valStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Occupation of deceased :-', style: engBold),
                  const SizedBox(height: 1),
                  Text('मृतकाचा व्यवसाय :', style: mrBold),
                  const SizedBox(height: 3),
                  _Kal14LinedText(
                    text: v('kal14Vyavsay'),
                    minLines: 1,
                    lineHeight: 23.0,
                    textStyle: valStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Habits (7 to 10)
      _kal14HabitRow(
        labelEn:
            '7) Did the deceased smoke cigarettes? If yes, since how many days :-',
        labelMr: '७) मृतक हा सिगरेट पित होता काय असल्यास किती दिवसांपासुन :',
        checkedVal: doc['kal14Cigarette'],
        daysVal: v('kal14CigaretteDays'),
        engStyle: engBold,
        mrStyle: mrBold,
        valStyle: valStyle,
        bottomSpacing: 6,
      ),
      _kal14HabitRow(
        labelEn:
            '8) Did the deceased have alcohol addiction? If yes, since how many days :-',
        labelMr: '८) मृतकाला दारूचे व्यसन होते काय असल्यास किती दिवसांपासुन :',
        checkedVal: doc['kal14Daru'],
        daysVal: v('kal14DaruDays'),
        engStyle: engBold,
        mrStyle: mrBold,
        valStyle: valStyle,
        bottomSpacing: 6,
      ),
      _kal14HabitRow(
        labelEn:
            '9) Did the deceased have tobacco addiction? If yes, since how many days :-',
        labelMr:
            '९) मृतकाला तंबाखुचे व्यसन होते काय असल्यास किती दिवसांपासुन :',
        checkedVal: doc['kal14Tambakhu'],
        daysVal: v('kal14TambakhuDays'),
        engStyle: engBold,
        mrStyle: mrBold,
        valStyle: valStyle,
        bottomSpacing: 6,
      ),
      _kal14HabitRow(
        labelEn:
            '10) Did the deceased have habit of pan masala, supari? If yes, since how many days :-',
        labelMr:
            '१०) मृतकाला पान मसाला, सुपारी खाण्याची सवय होती काय ? असल्यास किती दिवसांपासुन :',
        checkedVal: doc['kal14PanMasala'],
        daysVal: v('kal14PanMasalaDays'),
        engStyle: engBold,
        mrStyle: mrBold,
        valStyle: valStyle,
        bottomSpacing: 6,
      ),

      const Spacer(),
      Align(
        alignment: Alignment.bottomRight,
        child: Text(
          'M.R.W',
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.black54),
        ),
      ),
    ],
  );
}

Widget _buildKalmi14Pg2Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';

  final engBold = GoogleFonts.poppins(
    fontSize: 10.5,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  final mrBold = GoogleFonts.notoSansDevanagari(
    fontSize: 10.0,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
    height: 1.25,
  );
  final valStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 11.0,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 22),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Top Tag
      const Align(
        alignment: Alignment.centerRight,
        child: Text(
          'Page 13 (१४-कलमी फॉर्म)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        ),
      ),
      const SizedBox(height: 2),
      const Divider(color: Colors.black, thickness: 1.0, height: 6),
      const SizedBox(height: 6),

      // 11) Vehicle accident
      Text('11) In case of vehicle accident :-', style: engBold),
      const SizedBox(height: 1),
      Text('११) वाहन अपघाताची केस असल्यास :', style: mrBold),
      const SizedBox(height: 6),

      _kal14FieldBlock(
        labelEn: 'a) Name of vehicle involved in accident :-',
        labelMr: 'अ) अपघात झालेल्या वाहनाचे नांव :',
        value: v('kal14VehicleName'),
        minLines: 1,
        lineHeight: 23.0,
        engStyle: engBold,
        mrStyle: mrBold,
        valStyle: valStyle,
        bottomSpacing: 6,
      ),
      _kal14FieldBlock(
        labelEn: 'b) Deceased was driver or passenger :-',
        labelMr: 'ब) मृतक ड्रायव्हर किंवा पॅसेंजर :',
        value: v('kal14DriverPass'),
        minLines: 1,
        lineHeight: 23.0,
        engStyle: engBold,
        mrStyle: mrBold,
        valStyle: valStyle,
        bottomSpacing: 6,
      ),
      _kal14FieldBlock(
        labelEn: 'c) Or pedestrian (specify) :-',
        labelMr: 'क) किंवा पादचारी या पैकी काय होता :',
        value: v('kal14Pedestrian'),
        minLines: 1,
        lineHeight: 23.0,
        engStyle: engBold,
        mrStyle: mrBold,
        valStyle: valStyle,
        bottomSpacing: 6,
      ),
      _kal14FieldBlock(
        labelEn: 'd) How the accident occurred :-',
        labelMr: 'ड) अपघात कसा झाला :',
        value: v('kal14AccidentHow'),
        minLines: 2,
        lineHeight: 23.0,
        engStyle: engBold,
        mrStyle: mrBold,
        valStyle: valStyle,
        bottomSpacing: 6,
      ),
      _kal14FieldBlock(
        labelEn: 'Date and time of accident :-',
        labelMr: 'अपघात झाल्याची तारीख व वेळ :',
        value: _formatDateTimeKal14(
          v('kal14AccidentDateTime').isNotEmpty
              ? v('kal14AccidentDateTime')
              : [v('kal14AccidentDate'), v('kal14AccidentTime')]
                  .where((s) => s.isNotEmpty)
                  .join(', '),
        ),
        minLines: 1,
        lineHeight: 23.0,
        engStyle: engBold,
        mrStyle: mrBold,
        valStyle: valStyle,
        bottomSpacing: 8,
      ),

      // 12) Fall Info
      _kal14FieldBlock(
        labelEn: '12) If death was due to fall, give details :-',
        labelMr: '१२) मृत्यू हा पडून झाला असल्यास त्याबाबत माहिती :',
        value: v('kal14FallInfo'),
        minLines: 2,
        lineHeight: 23.0,
        engStyle: engBold,
        mrStyle: mrBold,
        valStyle: valStyle,
        bottomSpacing: 8,
      ),

      // 13) Female Deceased pregnancy / abortion
      _kal14FieldBlock(
        labelEn:
            '13) If deceased is female — was she pregnant? If yes, how many months?',
        labelMr:
            '१३) मृतक ही स्त्री असल्यास ती गरोदर होती काय? असल्यास किती महिने?',
        value: v('kal14PregnantMonths'),
        minLines: 1,
        lineHeight: 23.0,
        engStyle: engBold,
        mrStyle: mrBold,
        valStyle: valStyle,
        bottomSpacing: 6,
      ),
      _kal14FieldBlock(
        labelEn: 'If female — had delivery or abortion occurred?',
        labelMr:
            'मृतक ही स्त्री असल्यास ती बाळांत झाली होती काय किंवा तिचे अबोर्शिन झाले होते काय?',
        value: v('kal14DeliveredAbortion'),
        minLines: 2,
        lineHeight: 23.0,
        engStyle: engBold,
        mrStyle: mrBold,
        valStyle: valStyle,
        bottomSpacing: 6,
      ),
      _kal14FieldBlock(
        labelEn: 'If yes, since how many days?',
        labelMr: 'असल्यास किती दिवसांपासून ?',
        value: v('kal14PregnantDays'),
        minLines: 1,
        lineHeight: 23.0,
        engStyle: engBold,
        mrStyle: mrBold,
        valStyle: valStyle,
        bottomSpacing: 8,
      ),

      // 14) Identifier name & relation
      _kal14FieldBlock(
        labelEn:
            '14) Name, address and relationship of person identifying the deceased :-',
        labelMr:
            '१४) मृतकाची ओळख पटविणाऱ्याचे नांव व पत्ता व मृतकाशी त्याचे काय संबंध नाते आहे (लिहावे) :',
        value: v('kal14IdentifierName'),
        minLines: 2,
        lineHeight: 23.0,
        engStyle: engBold,
        mrStyle: mrBold,
        valStyle: valStyle,
        bottomSpacing: 12,
      ),

      // IO Signature
      Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'I.O. Name, Rank & Signature / Seal',
                style: engBold.copyWith(fontSize: 11.0),
              ),
              const SizedBox(height: 1),
              Text(
                FormIoTerminology.signatureHeaderSeal,
                style: mrBold.copyWith(fontSize: 10.5),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${FormIoTerminology.name} : ',
                    style: mrBold,
                  ),
                  Expanded(
                    child: _Kal14LinedText(
                      text: v('kal14IoName'),
                      minLines: 1,
                      lineHeight: 22.0,
                      textStyle: valStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${FormIoTerminology.rank} : ',
                    style: mrBold,
                  ),
                  Expanded(
                    child: _Kal14LinedText(
                      text: v('kal14IoRank'),
                      minLines: 1,
                      lineHeight: 22.0,
                      textStyle: valStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'पोलीस स्टेशन : ',
                    style: mrBold,
                  ),
                  Expanded(
                    child: _Kal14LinedText(
                      text: v('kal14IoPs'),
                      minLines: 1,
                      lineHeight: 22.0,
                      textStyle: valStyle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      const Spacer(),
      Align(
        alignment: Alignment.bottomRight,
        child: Text(
          'M.R.W',
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.black54),
        ),
      ),
    ],
  );
}
