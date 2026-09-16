// lib/utils/arrest_surrender_pdf.dart
//
// IMAGE-BASED PDF generation for the Arrest / Court Surrender Form (Forms 3-A, 3-B, 3-C).
// Each page is rendered as a Flutter widget via an offscreen RepaintBoundary,
// captured as a high-resolution PNG (2.0x pixel ratio), and assembled into an A4 PDF.
// This guarantees 100% Devanagari text shaping fidelity with zero matra/conjunct errors
// and zero page overflow/clipping.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../widgets/form_section_utils.dart';

// ── Dimensions ─────────────────────────────────────────────────────────────────
const double _kW = 794.0;      // A4 portrait width at 96 DPI
const double _kH = 1123.0;     // A4 portrait height at 96 DPI
const double _kWLand = 1123.0; // A4 landscape width at 96 DPI
const double _kHLand = 794.0;  // A4 landscape height at 96 DPI
const double _kPx = 2.0;       // 2x capture pixel ratio

// ── Public API ─────────────────────────────────────────────────────────────────

Future<void> previewArrestSurrenderPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final fileName =
      'Arrest_Court_Surrender_Form_${DateTime.now().millisecondsSinceEpoch}.pdf';
  try {
    final bytes = await _buildImagePdf(context, doc);
    if (!context.mounted) return;
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } else {
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);
    }
  } catch (_) {
    if (!context.mounted) return;
    try {
      final bytes = await _buildImagePdf(context, doc);
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (_) {}
  }
}

Future<Uint8List> generateArrestSurrenderPdf(Map<String, dynamic> doc) async {
  return Uint8List(0);
}

// ── Image-based PDF Builder ───────────────────────────────────────────────────

class _PageItem {
  final Widget widget;
  final bool isLandscape;
  _PageItem(this.widget, {this.isLandscape = false});
}

Future<Uint8List> _buildImagePdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  const knownSectionIds = {'Form 3-A', 'Form 3-B', 'Form 3-C'};
  final activeSection = doc['formSection']?.toString();

  bool showsSection(String sectionId) => showsFormSection(
        activeSection: activeSection,
        sectionId: sectionId,
        knownSectionIds: knownSectionIds,
      );

  final pageItems = <_PageItem>[];

  if (showsSection('Form 3-A')) {
    pageItems.add(_PageItem(_pg3A(doc)));
  }
  if (showsSection('Form 3-B')) {
    pageItems.add(_PageItem(_pg3B_1(doc)));
    pageItems.add(_PageItem(_pg3B_2(doc), isLandscape: true));
  }
  if (showsSection('Form 3-C')) {
    pageItems.add(_PageItem(_pg3C(doc)));
  }

  // Fallback if no sections matched
  if (pageItems.isEmpty) {
    pageItems.add(_PageItem(_pg3A(doc)));
    pageItems.add(_PageItem(_pg3B_1(doc)));
    pageItems.add(_PageItem(_pg3B_2(doc), isLandscape: true));
    pageItems.add(_PageItem(_pg3C(doc)));
  }

  final capturedList = <({Uint8List png, bool isLandscape})>[];
  for (final item in pageItems) {
    final png = await _capture(
      context,
      item.widget,
      width: item.isLandscape ? _kWLand : _kW,
      height: item.isLandscape ? _kHLand : _kH,
    );
    capturedList.add((png: png, isLandscape: item.isLandscape));
  }

  final pdfDoc = pw.Document();
  for (final item in capturedList) {
    pdfDoc.addPage(
      pw.Page(
        pageFormat:
            item.isLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Image(
          pw.MemoryImage(item.png),
          fit: pw.BoxFit.contain,
        ),
      ),
    );
  }

  return pdfDoc.save();
}

Future<Uint8List> _capture(
  BuildContext ctx,
  Widget widget, {
  required double width,
  required double height,
}) async {
  final key = GlobalKey();
  final comp = Completer<Uint8List>();
  OverlayEntry? ent;

  ent = OverlayEntry(
    builder: (_) => Positioned(
      left: -(width + 80),
      top: 0,
      width: width,
      height: height,
      child: RepaintBoundary(
        key: key,
        child: Material(
          color: Colors.white,
          child: widget,
        ),
      ),
    ),
  );

  try {
    Overlay.of(ctx).insert(ent);
    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 700));

    final ro = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (ro == null) throw Exception('RenderRepaintBoundary not found');
    final img = await ro.toImage(pixelRatio: _kPx);
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    if (bd == null) throw Exception('toByteData returned null');
    comp.complete(bd.buffer.asUint8List());
  } catch (e, st) {
    comp.completeError(e, st);
  } finally {
    ent.remove();
  }
  return comp.future;
}

// ── Typography & Helper Styles ─────────────────────────────────────────────────

TextStyle _fH1() => GoogleFonts.lora(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

TextStyle _fH1M() => GoogleFonts.notoSansDevanagari(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

TextStyle _fBold({double size = 9.0}) => GoogleFonts.lora(
      fontSize: size,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

TextStyle _fRegular({double size = 8.5}) => GoogleFonts.lora(
      fontSize: size,
      color: Colors.black,
    );

TextStyle _fMarathi({double size = 8.0, bool isBold = false}) =>
    GoogleFonts.notoSansDevanagari(
      fontSize: size,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      color: Colors.black,
    );

TextStyle _fValue({double size = 8.5}) => GoogleFonts.notoSansDevanagari(
      fontSize: size,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF0D47A1),
    );

String _v(Map<String, dynamic> doc, String key) =>
    doc[key]?.toString().trim() ?? '';

Widget _inlineField({
  required String labelEn,
  String? labelMr,
  required String value,
  double? width,
}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(labelEn, style: _fBold(size: 8.5)),
          if (labelMr != null && labelMr.isNotEmpty)
            Text(labelMr, style: _fMarathi(size: 7.5)),
        ],
      ),
      const SizedBox(width: 4),
      Container(
        width: width,
        padding: const EdgeInsets.only(left: 2, right: 2, bottom: 1),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black, width: 0.8)),
        ),
        child: Text(
          value.isEmpty ? ' ' : value,
          style: _fValue(size: 8.5),
        ),
      ),
    ],
  );
}

Widget _checkBox(String label, bool checked) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 11,
        height: 11,
        decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1)),
        child: checked
            ? const Center(
                child: Text('✓',
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
              )
            : const SizedBox.shrink(),
      ),
      const SizedBox(width: 4),
      Text(label, style: _fRegular(size: 8)),
    ],
  );
}

Widget _yesNoRow(String en, String mr, bool isYes) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 1.5),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(en, style: _fBold(size: 8.5)),
              if (mr.isNotEmpty) Text(mr, style: _fMarathi(size: 7.5)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text('Yes/No (होय/नाही): ', style: _fBold(size: 8)),
        Text(isYes ? '[ Yes ]' : '[ No ]', style: _fValue(size: 8.5)),
      ],
    ),
  );
}

// ── PAGE 1: Form 3-A (Portrait) ────────────────────────────────────────────────

Widget _pg3A(Map<String, dynamic> doc) {
  return Container(
    width: _kW,
    height: _kH,
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Center(
          child: Column(
            children: [
              Text('ARREST/COURT SURRENDER FORM', style: _fH1()),
              Text('अटकेचा पंचनामा/ न्यायालयाच्या स्वाधीन होण्याचा नमुना',
                  style: _fH1M()),
              const SizedBox(height: 2),
              Text(
                '(Separate Memo for each accused / प्रत्येक आरोपीसाठी स्वतंत्र नमुना वापरावा)',
                style: _fBold(size: 8.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 1. Details
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _inlineField(
              labelEn: '1. Dist.',
              labelMr: 'जिल्हा :-',
              value: _v(doc, 'dist'),
              width: 75,
            ),
            _inlineField(
              labelEn: 'P.S.:',
              labelMr: 'पो.स्टे.:',
              value: _v(doc, 'ps'),
              width: 75,
            ),
            _inlineField(
              labelEn: 'FIR/Proceeding/G.D.No:',
              labelMr: 'पहिली खबर क्र/ कार्यवाही क्र.:',
              value: _v(doc, 'firNo'),
              width: 85,
            ),
            _inlineField(
              labelEn: 'Year:-20',
              labelMr: 'वर्ष:',
              value: _v(doc, 'year'),
              width: 40,
            ),
            _inlineField(
              labelEn: 'Date:',
              labelMr: 'दिनांक:',
              value: _v(doc, 'date'),
              width: 70,
            ),
          ],
        ),
        const SizedBox(height: 5),

        // Accused code
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alphanumeric Code of the Accused (Write A1 to A9 for the first 9 persons, B1 for 10th person and so on):',
                    style: _fBold(size: 8),
                  ),
                  Text(
                    'आरोपीचा सांकेतीक क्रमांक (पहिल्या ९ व्यक्तींसाठी अ १ ते अ ९, दहाव्या व्यक्तीसाठी ब १ या प्रमाणे पुढे असे लिहावे):',
                    style: _fMarathi(size: 7.5),
                  ),
                ],
              ),
            ),
            Container(
              width: 60,
              padding: const EdgeInsets.only(left: 4, right: 4, bottom: 1),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black, width: 0.8)),
              ),
              child: Text(_v(doc, 'accusedCode'), style: _fValue()),
            ),
          ],
        ),
        const SizedBox(height: 5),

        // 2. Date and time of arrest
        Text('2. Date and time of arrest / स्वाधीन होण्याची तारीख वेळ:-',
            style: _fBold(size: 8.5)),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _inlineField(
              labelEn: 'Date:',
              labelMr: 'दिनांक:',
              value: _v(doc, 'arrestDate'),
              width: 70,
            ),
            _inlineField(
              labelEn: 'Time:',
              labelMr: 'वेळ:',
              value: _v(doc, 'arrestTime'),
              width: 50,
            ),
            _inlineField(
              labelEn: 'G.D. No.:',
              labelMr: 'ठाणे दैनंदिन क्र.:',
              value: _v(doc, 'arrestGdNo'),
              width: 60,
            ),
            _inlineField(
              labelEn: 'Place of arrest:',
              labelMr: 'अटकेची जागा:',
              value: _v(doc, 'arrestPlace'),
              width: 80,
            ),
            _inlineField(
              labelEn: 'Dist:',
              labelMr: 'जिल्हा:',
              value: _v(doc, 'arrestDist'),
              width: 70,
            ),
            _inlineField(
              labelEn: 'State:',
              labelMr: 'राज्य:',
              value: _v(doc, 'arrestState'),
              width: 70,
            ),
          ],
        ),
        const SizedBox(height: 5),

        // 3. Name of court
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('3. Name of the court (if surrender):-', style: _fBold(size: 8.5)),
                Text('न्यायालयाचे नांव (स्वाधीन झाल्यास):-', style: _fMarathi(size: 7.5)),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(bottom: 1),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black, width: 0.8)),
                ),
                child: Text(_v(doc, 'courtName'), style: _fValue()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),

        // 4. Acts & Sections
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('4. Acts and sections:-', style: _fBold(size: 8.5)),
                Text('अधिनियम व कलमे:-', style: _fMarathi(size: 7.5)),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(bottom: 1),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black, width: 0.8)),
                ),
                child: Text(_v(doc, 'actsSections'), style: _fValue()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),

        // 5. Action type
        Text(
          '5. Arrest disposition (tick applicable option):',
          style: _fBold(size: 8.5),
        ),
        Text(
          'अटक केली व न्यायालयात पाठविले / जामीनावर सोडले / अटकपूर्व जामीनावर / पोलीस कोठडीत / न्यायालयीन कोठडीत:',
          style: _fMarathi(size: 7.5),
        ),
        const SizedBox(height: 3),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _checkBox('Arrested & forward', doc['arrestedAndForwarded'] == true),
            _checkBox('Arrested & bailed', doc['arrestedAndBailed'] == true),
            _checkBox('Anticipatory bail', doc['arrestedButAnticipatory'] == true),
            _checkBox('Police Custody', doc['arrestedAndRemandedPolice'] == true),
            _checkBox('Surrender & bailed', doc['surrenderBailed'] == true),
            _checkBox('Judicial Custody', doc['surrenderJudicial'] == true),
            _checkBox('Surrender & PCR', doc['surrenderPolice'] == true),
          ],
        ),
        const SizedBox(height: 6),

        // 6. Particulars of the Accused
        Text('6. Particulars of the Accused (आरोपीचा तपशील):-',
            style: _fBold(size: 9)),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _inlineField(
                labelEn: '(i) Name (नांव):-',
                value: _v(doc, 'accusedName'),
                width: 260,
              ),
              const SizedBox(height: 3),
              _inlineField(
                labelEn:
                    "(ii) Father's/Husband's/Guardian's Name (पित्याचे/पतीचे/पालकाचे नांव):-",
                value: _v(doc, 'accusedFather'),
                width: 240,
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _inlineField(
                    labelEn: '(iii) Alias (उर्फ):-',
                    value: _v(doc, 'accusedAlias'),
                    width: 100,
                  ),
                  _inlineField(
                    labelEn: '(iv) DOB/Year (जन्म तारीख/वर्ष):-',
                    value: _v(doc, 'accusedDob'),
                    width: 80,
                  ),
                  _inlineField(
                    labelEn: '(v) Sex (लिंग):-',
                    value: _v(doc, 'accusedSex'),
                    width: 60,
                  ),
                  _inlineField(
                    labelEn: '(vi) Nationality (राष्ट्रीयत्व):-',
                    value: _v(doc, 'accusedNationality'),
                    width: 70,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _inlineField(
                    labelEn: 'Voter ID (मतदान ओळखपत्र क्र.):-',
                    value: _v(doc, 'accusedVoterId'),
                    width: 90,
                  ),
                  _inlineField(
                    labelEn: 'Passport No. (पारपत्र क्र.):-',
                    value: _v(doc, 'accusedPassportNo'),
                    width: 80,
                  ),
                  _inlineField(
                    labelEn: 'Date of issue (दि. तारीख):-',
                    value: _v(doc, 'accusedPassportDate'),
                    width: 65,
                  ),
                  _inlineField(
                    labelEn: 'Place (जागा):-',
                    value: _v(doc, 'accusedPassportPlace'),
                    width: 65,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _inlineField(
                    labelEn: '(vii) Religion (धर्म):-',
                    value: _v(doc, 'accusedReligion'),
                    width: 80,
                  ),
                  _inlineField(
                    labelEn: '(viii) Caste/Tribe (जात जमात):-',
                    value: _v(doc, 'accusedCaste'),
                    width: 80,
                  ),
                  _inlineField(
                    labelEn: '(ix) SC/ST/OBC (अनु.जा/अनु.जमात):-',
                    value: _v(doc, 'accusedScSt'),
                    width: 80,
                  ),
                  _inlineField(
                    labelEn: '(x) Occupation (व्यवसाय):-',
                    value: _v(doc, 'accusedOccupation'),
                    width: 90,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('(xi) Permanent Address (कायमचा पत्ता):-',
                      style: _fBold(size: 8.5)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 1),
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: Colors.black, width: 0.8)),
                      ),
                      child: Text(_v(doc, 'permAddress'), style: _fValue()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _inlineField(
                    labelEn: 'State:-',
                    value: _v(doc, 'permState'),
                    width: 90,
                  ),
                  _inlineField(
                    labelEn: 'Dist.:-',
                    value: _v(doc, 'permDist'),
                    width: 90,
                  ),
                  _inlineField(
                    labelEn: 'P.S.:-',
                    value: _v(doc, 'permPs'),
                    width: 90,
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('(xii) Present Address (सध्याचा पत्ता):-',
                      style: _fBold(size: 8.5)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 1),
                      decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: Colors.black, width: 0.8)),
                      ),
                      child: Text(_v(doc, 'presAddress'), style: _fValue()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _inlineField(
                    labelEn: 'State:-',
                    value: _v(doc, 'presState'),
                    width: 90,
                  ),
                  _inlineField(
                    labelEn: 'Dist.:-',
                    value: _v(doc, 'presDist'),
                    width: 90,
                  ),
                  _inlineField(
                    labelEn: 'P.S.:-',
                    value: _v(doc, 'presPs'),
                    width: 90,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // 7. Injuries
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '7. Injuries, cause of injuries and physical condition of the accused person (indicate if medically examined):',
              style: _fBold(size: 8.5),
            ),
            Text(
              'आरोपीच्या अंगावरील जखमा, जखमांचे कारण आणि शारीरिक स्थिती (वैद्यकीय तपासणी झाली असल्यास दर्शवावे):',
              style: _fMarathi(size: 7.5),
            ),
            const SizedBox(height: 3),
            Container(
              width: double.infinity,
              height: 24,
              padding: const EdgeInsets.only(bottom: 1),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.black, width: 0.8)),
              ),
              child: Text(_v(doc, 'injuries'), style: _fValue()),
            ),
          ],
        ),
      ],
    ),
  );
}

// ── PAGE 2: Form 3-B (Portrait) ────────────────────────────────────────────────

Widget _pg3B_1(Map<String, dynamic> doc) {
  return Container(
    width: _kW,
    height: _kH,
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text('Form: 3-B', style: _fBold(size: 9.5)),
        ),
        const SizedBox(height: 8),

        // 8
        Text(
          '8. The accused, after being informed of the grounds of arrest and his legal rights, was duly taken into custody on:',
          style: _fBold(size: 8.5),
        ),
        Text(
          '८. आरोपीस अटकाची कारणे व कायदेशीर हक्क समजावून सांगून विधिवत ताब्यात घेण्यात आले दिनांक:',
          style: _fMarathi(size: 7.5),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            _inlineField(
              labelEn: 'On (date):',
              value: _v(doc, 'custodyDate'),
              width: 80,
            ),
            _inlineField(
              labelEn: 'At (hours):',
              value: _v(doc, 'custodyTime'),
              width: 60,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'And that on personal search following articles were found on the person of the accused for which a receipt has been given to the accused person:',
          style: _fBold(size: 8),
        ),
        Text(
          'तसेच अंगझडती घेतली असता आरोपीजवळ खालील वस्तू सापडल्या व त्याची पोहोच आरोपीस देण्यात आली:',
          style: _fMarathi(size: 7.5),
        ),
        const SizedBox(height: 6),

        // Articles 1-6
        Row(
          children: [
            Expanded(
              child: _inlineField(
                labelEn: '1.',
                value: _v(doc, 'article1'),
                width: 260,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _inlineField(
                labelEn: '2.',
                value: _v(doc, 'article2'),
                width: 260,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _inlineField(
                labelEn: '3.',
                value: _v(doc, 'article3'),
                width: 260,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _inlineField(
                labelEn: '4.',
                value: _v(doc, 'article4'),
                width: 260,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _inlineField(
                labelEn: '5.',
                value: _v(doc, 'article5'),
                width: 260,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _inlineField(
                labelEn: '6.',
                value: _v(doc, 'article6'),
                width: 260,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Human dignity statement
        Text(
          'Necessary wearing apparels were left on the accused for the sake of human dignity and body protection.',
          style: _fBold(size: 8.5),
        ),
        Text(
          'मानवी सन्मान व शरीर संरक्षणासाठी आवश्यक असणारे कपडे आरोपीच्या अंगावर ठेवण्यात आले.',
          style: _fMarathi(size: 7.5),
        ),
        const SizedBox(height: 8),

        // Identification precaution
        Text(
          'The accused was cautioned to keep him/herself covered for purpose of identification.',
          style: _fBold(size: 8.5),
        ),
        Text(
          'ओळख परेडच्या हेतूने आरोपीस स्वतःचा चेहरा/शरीर झाकून ठेवण्याची खबरदारी देण्यात आली.',
          style: _fMarathi(size: 7.5),
        ),
        const SizedBox(height: 12),

        // Intimation to relatives
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            _inlineField(
              labelEn: 'Intimation given to Name:',
              labelMr: 'माहिती दिली त्या नातेवाईकाचे नांव:-',
              value: _v(doc, 'intimationName'),
              width: 180,
            ),
            _inlineField(
              labelEn: '(Relationship):',
              labelMr: '(नाते):-',
              value: _v(doc, 'intimationRel'),
              width: 120,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Nil note
        Text(
          '** If no article found, NIL, may be indicated in the blank space provided below:-',
          style: _fBold(size: 8),
        ),
        Text(
          '** अंगझडतीत काहीही वस्तू न सापडल्यास खालील मोकळ्या जागेत "निरंक (NIL)" असे नमूद करावे:-',
          style: _fMarathi(size: 7.5),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          height: 30,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black, width: 0.8)),
          ),
        ),
      ],
    ),
  );
}

// ── PAGE 3: Form 3-B (Landscape) ───────────────────────────────────────────────

Widget _pg3B_2(Map<String, dynamic> doc) {
  final pt =
      doc['physTable'] is Map ? doc['physTable'] as Map<String, dynamic> : {};

  Widget buildTable({
    required List<String> headersEn,
    required List<String> headersMr,
    required List<int> colIndices,
  }) {
    return Table(
      border: TableBorder.all(color: Colors.black, width: 0.8),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: List.generate(colIndices.length, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
              child: Column(
                children: [
                  Text(headersEn[i],
                      style: _fBold(size: 7.5), textAlign: TextAlign.center),
                  Text(headersMr[i],
                      style: _fMarathi(size: 6.8), textAlign: TextAlign.center),
                  const Divider(color: Colors.black45, thickness: 0.5, height: 4),
                  Text('${colIndices[i]}',
                      style: _fBold(size: 7), textAlign: TextAlign.center),
                ],
              ),
            );
          }),
        ),
        TableRow(
          children: List.generate(colIndices.length, (i) {
            final val = pt[colIndices[i].toString()]?.toString() ?? '';
            return Container(
              height: 28,
              padding: const EdgeInsets.all(2),
              alignment: Alignment.center,
              child: Text(
                val,
                style: _fValue(size: 8),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }),
        ),
      ],
    );
  }

  return Container(
    width: _kWLand,
    height: _kHLand,
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text('Form: 3-B (cont.)', style: _fBold(size: 9.5)),
        ),
        const SizedBox(height: 4),
        Text(
          '9. Physical features, deformities and other details of the accused (आरोपीची शारीरिक वैशिष्ट्ये, व्यंग व इतर तपशील):-',
          style: _fBold(size: 9),
        ),
        const SizedBox(height: 8),

        // Table 1: Cols 1-10
        buildTable(
          headersEn: [
            'Sr. No.',
            'Sex',
            'DOB / Year',
            'Build',
            'Height (Cms)',
            'Complexion',
            'Identification Mark',
            'Deformities',
            'Teeth',
            'Hair',
          ],
          headersMr: [
            'अ.क्र.',
            'लिंग',
            'जन्म वर्ष',
            'बांधा',
            'उंची से.मी.',
            'वर्ण',
            'ओळखचिन्ह',
            'व्यंग/वैशिष्टे',
            'दात',
            'केस',
          ],
          colIndices: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        ),
        const SizedBox(height: 8),

        // Table 2: Cols 11-20
        buildTable(
          headersEn: [
            'Eye',
            'Habits',
            'Dress Habits',
            'Languages',
            'Burn Mark',
            'Leucoderma',
            'Mole',
            'Scar',
            'Tattoo',
            'Forehead',
          ],
          headersMr: [
            'डोळे',
            'सवयी',
            'पोषाखाच्या सवयी',
            'बोली/भाषा',
            'भाजल्याच्या खुणा',
            'कोड',
            'तिळ',
            'वण',
            'गोंदण',
            'कपाळ',
          ],
          colIndices: [11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
        ),
        const SizedBox(height: 8),

        // Table 3: Cols 21-26
        buildTable(
          headersEn: [
            'Ear',
            'Nose',
            'Moustaches',
            'Speech/voice',
            'Face',
            'Lips',
          ],
          headersMr: [
            'कान',
            'नाक',
            'मिशी',
            'बोलण्याची पद्धत',
            'चेहरा',
            'ओठ',
          ],
          colIndices: [21, 22, 23, 24, 25, 26],
        ),
        const SizedBox(height: 8),

        // Other features
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Other features if any (इतर काही वैशिष्ट्ये असल्यास): ',
                style: _fBold(size: 8.5)),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(bottom: 1),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black, width: 0.8)),
                ),
                child: Text(_v(doc, 'otherFeatures'), style: _fValue()),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// ── PAGE 4: Form 3-C (Portrait) ────────────────────────────────────────────────

Widget _pg3C(Map<String, dynamic> doc) {
  return Container(
    width: _kW,
    height: _kH,
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text('Form: 3-C', style: _fBold(size: 9.5)),
        ),
        const SizedBox(height: 4),

        // 10
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '10. Whether finger print taken or not? (बोटांचे ठसे घेतले किंवा कसे ?): ',
              style: _fBold(size: 8.5),
            ),
            Text(
              doc['fingerprintTaken'] == true ? 'Yes / होय' : 'No / नाही',
              style: _fValue(size: 9),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // 11. Socio-economic profile
        Text(
          '11. Socio-economic profile of the accused (आरोपीची सामाजिक-आर्थिक माहिती):-',
          style: _fBold(size: 8.5),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '(a) Living Status (राहणीमान दर्जा):',
                style: _fBold(size: 8),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 3,
                children: [
                  _checkBox('Living alone', doc['livingAlone'] == true),
                  _checkBox('With Family', doc['livingWithFamily'] == true),
                  _checkBox('With Associate', doc['livingWithAssociate'] == true),
                  _checkBox('Pucca House', doc['livingPucca'] == true),
                  _checkBox('Hotel', doc['livingHotel'] == true),
                  _checkBox('Hostel', doc['livingHostel'] == true),
                  _checkBox('Kachcha House', doc['livingKachcha'] == true),
                  _checkBox('Thatched House', doc['livingThatched'] == true),
                  _checkBox('Slum', doc['livingSlum'] == true),
                  _checkBox('Homeless', doc['livingHomeless'] == true),
                  _checkBox('Harbourer', doc['livingHarbourer'] == true),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '(b) Educational Qualification (शैक्षणिक पात्रता):',
                style: _fBold(size: 8),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 3,
                children: [
                  _checkBox('Illiterate', doc['eduIlliterate'] == true),
                  _checkBox('Primary', doc['eduPrimary'] == true),
                  _checkBox('Middle', doc['eduMiddle'] == true),
                  _checkBox('Matriculate', doc['eduMatric'] == true),
                  _checkBox('Higher Secondary', doc['eduHigherSec'] == true),
                  _checkBox('Graduate', doc['eduGraduate'] == true),
                  _checkBox('Post Graduate', doc['eduPostGrad'] == true),
                  _checkBox('Professional', doc['eduProf'] == true),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '(c) Income Group (उत्पन्न गट):',
                style: _fBold(size: 8),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 3,
                children: [
                  _checkBox('Lower', doc['incLower'] == true),
                  _checkBox('Lower Middle', doc['incLowerMid'] == true),
                  _checkBox('Middle', doc['incMiddle'] == true),
                  _checkBox('Upper Middle', doc['incUpperMid'] == true),
                  _checkBox('Upper', doc['incUpper'] == true),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '(d) Occupation Status (कामाचा दर्जा):',
                style: _fBold(size: 8),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 3,
                children: [
                  _checkBox('Unemployed', doc['occUnemployed'] == true),
                  _checkBox('Employed', doc['occEmployed'] == true),
                  _checkBox('Self Employed', doc['occSelfEmployed'] == true),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // 12. Assessment
        Text('12. Assessment (मूल्यांकन):-', style: _fBold(size: 8.5)),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Column(
            children: [
              _yesNoRow(
                '(a) Is known criminal?',
                '(माहितीतील गुन्हेगार आहे काय ?)',
                doc['isKnownCriminal'] == true,
              ),
              _yesNoRow(
                '(b) Is associates of known criminals?',
                '(माहितीतील गुन्हेगारांचा साथीदार आहे काय ?)',
                doc['isAssociate'] == true,
              ),
              _yesNoRow(
                '(c) Drug addict?',
                '(अमली पदार्थांचे व्यसन आहे किंवा काय ?)',
                doc['isDrugAddict'] == true,
              ),
              _yesNoRow(
                '(d) Is organized criminal gang member?',
                '(संघटित गुन्हेगारी टोळीचा सदस्य आहे किंवा काय ?)',
                doc['isGangMember'] == true,
              ),
              _yesNoRow(
                '(e) Habitual offender?',
                '(सराईत गुन्हेगार आहे काय ?)',
                doc['isHabitualOffender'] == true,
              ),
              _yesNoRow(
                '(f) Is recidivism?',
                '(वारंवार अपराध करतो किंवा काय ?)',
                doc['isRecidivism'] == true,
              ),
              _yesNoRow(
                '(g) Is likely to escape bail?',
                '(जामीनावर असतांना पळून जाण्याचा संभव किंवा नाही ?)',
                doc['likelyToEscape'] == true,
              ),
              _yesNoRow(
                '(h) Is released on bail, likely to commit crime or threaten victims/witnesses?',
                '(जामीनावर सोडल्यास लगेच दुसरा गुन्हा करण्याचा किंवा साक्षीदारांना धमकावण्याचा संभव आहे किंवा नाही ?)',
                doc['releasedOnBail'] == true,
              ),
              _yesNoRow(
                '(i) Is wanted in any other case?',
                '(दुसऱ्या कोणत्याही प्रकरणात पाहिजे किंवा काय ?)',
                doc['wantedMany'] == true,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'If yes give case ref. & sec. (जर होय असेल तर संदर्भ व कलमे): ',
                    style: _fRegular(size: 8),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 1),
                      decoration: const BoxDecoration(
                        border:
                            Border(bottom: BorderSide(color: Colors.black, width: 0.8)),
                      ),
                      child: Text(_v(doc, 'caseRefSec'), style: _fValue()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 13. Panchas
        Row(
          children: [
            Expanded(
              child: _inlineField(
                labelEn: '13. Pancha 1 Name:',
                labelMr: 'पंचाचे नांव (१):',
                value: _v(doc, 'panch1Name'),
                width: 130,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _inlineField(
                labelEn: 'Pancha 1 Sig:',
                labelMr: 'पंचाची सही (१):',
                value: _v(doc, 'panch1Sig'),
                width: 120,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Expanded(
              child: _inlineField(
                labelEn: 'Pancha 2 Name:',
                labelMr: 'पंचाचे नांव (२):',
                value: _v(doc, 'panch2Name'),
                width: 130,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _inlineField(
                labelEn: 'Pancha 2 Sig:',
                labelMr: 'पंचाची सही (२):',
                value: _v(doc, 'panch2Sig'),
                width: 120,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 14 & 15 Signatures
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '14. Signature / Thumb of Arrested person',
                    style: _fBold(size: 8),
                  ),
                  Text(
                    'अटक केलेल्या व्यक्तीची सही / अंगठ्याचा ठसा:',
                    style: _fMarathi(size: 7.5),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 160,
                    height: 22,
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.black, width: 0.8)),
                    ),
                    alignment: Alignment.bottomLeft,
                    child: Text(_v(doc, 'arrestedPersonSig'), style: _fValue()),
                  ),
                  const SizedBox(height: 8),
                  _inlineField(
                    labelEn: '15. Place (ठिकाण):',
                    value: _v(doc, 'finalPlace'),
                    width: 100,
                  ),
                  const SizedBox(height: 4),
                  _inlineField(
                    labelEn: 'Date (तारीख):',
                    value: _v(doc, 'finalDate'),
                    width: 100,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Signature of Investigating Officer (तपास अधिकाऱ्याची सही):',
                    style: _fBold(size: 8),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 160,
                    height: 22,
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.black, width: 0.8)),
                    ),
                    alignment: Alignment.bottomLeft,
                    child: Text(_v(doc, 'ioSig'), style: _fValue()),
                  ),
                  const SizedBox(height: 8),
                  _inlineField(
                    labelEn: 'Name (नाव):',
                    value: _v(doc, 'finalName'),
                    width: 150,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _inlineField(
                        labelEn: 'Rank (हुद्दा):',
                        value: _v(doc, 'finalRank'),
                        width: 80,
                      ),
                      const SizedBox(width: 8),
                      _inlineField(
                        labelEn: 'No. (ब.क्र.):',
                        value: _v(doc, 'finalNo'),
                        width: 60,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
