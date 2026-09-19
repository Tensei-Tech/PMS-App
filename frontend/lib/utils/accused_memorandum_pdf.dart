// lib/utils/accused_memorandum_pdf.dart
//
// IMAGE-BASED PDF generation for ACCUSED MEMORANDUM FORM:
//   Part I:  Accused Memorandum (आरोपीचे निवेदन)
//   Part II: Further Panchanama (अधिक पंचनामा)
//
// Renders pages as native Flutter widgets offscreen and captures them at 2.0x DPI
// for 100% Devanagari/Marathi accuracy with zero edge cropping.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const double _kW = 794.0;
const double _kH = 1123.0;
const double _kPx = 2.0;

Future<void> previewAccusedMemorandumPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final fileName =
      'Accused_Memorandum_Form_${DateTime.now().millisecondsSinceEpoch}.pdf';
  try {
    final bytes = await _buildImagePdf(context, doc);
    if (!context.mounted) return;
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } else {
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);
    }
  } catch (e) {
    debugPrint('Error generating image-based Accused Memorandum PDF: $e');
    if (!context.mounted) return;
    try {
      final bytes = await generateAccusedMemorandumPdf(doc);
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (_) {}
  }
}

Future<Uint8List> _buildImagePdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final sectionStr = (doc['formSection'] ?? '').toString().toLowerCase().trim();
  final isPartIOnly = sectionStr == 'accused part i' ||
      (sectionStr.contains('part i') && !sectionStr.contains('part ii'));
  final isPartIIOnly =
      sectionStr == 'accused part ii' || sectionStr.contains('part ii');

  final pages = <Widget>[];
  if (!isPartIIOnly) pages.add(_pg1(doc));
  if (!isPartIOnly) pages.add(_pg2(doc));

  final pngs = <Uint8List>[];
  for (final p in pages) {
    pngs.add(await _capture(context, p));
  }

  final pdfDoc = pw.Document();
  for (final png in pngs) {
    pdfDoc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Image(
          pw.MemoryImage(png),
          fit: pw.BoxFit.contain,
        ),
      ),
    );
  }
  return pdfDoc.save();
}

Future<Uint8List> _capture(BuildContext ctx, Widget widget) async {
  final key = GlobalKey();
  final comp = Completer<Uint8List>();
  OverlayEntry? ent;

  ent = OverlayEntry(
    builder: (_) => Positioned(
      left: -(_kW + 80),
      top: 0,
      width: _kW,
      height: _kH,
      child: RepaintBoundary(
        key: key,
        child: Material(
          color: Colors.white,
          child: widget,
        ),
      ),
    ),
  );

  Overlay.of(ctx).insert(ent);

  await WidgetsBinding.instance.endOfFrame;
  await Future.delayed(const Duration(milliseconds: 700));

  try {
    final rb = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await rb.toImage(pixelRatio: _kPx);
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    comp.complete(bd!.buffer.asUint8List());
  } catch (e) {
    comp.completeError(e);
  } finally {
    ent.remove();
  }

  return comp.future;
}

String _v(Map<String, dynamic> doc, String key, [String fallback = '']) {
  final val = doc[key]?.toString().trim() ?? '';
  return val.isEmpty ? fallback : val;
}

TextStyle _eBld([double sz = 10]) => GoogleFonts.lora(
      fontSize: sz,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );

TextStyle _mBld([double sz = 9.5]) => GoogleFonts.notoSansDevanagari(
      fontSize: sz,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );

TextStyle _mReg([double sz = 9.5]) => GoogleFonts.notoSansDevanagari(
      fontSize: sz,
      color: Colors.black87,
    );

TextStyle _valStyle([double sz = 9.5]) => GoogleFonts.notoSansDevanagari(
      fontSize: sz,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF0D47A1),
    );

Widget _bilingualField(String eng, String mr, String val,
    {double? width, bool expand = false}) {
  final content = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(eng, style: _eBld(9.5)),
          const SizedBox(width: 4),
          Text('($mr)', style: _mBld(9)),
        ],
      ),
      const SizedBox(height: 2),
      Container(
        width: width,
        padding: const EdgeInsets.only(bottom: 2),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.black87, width: 0.8)),
        ),
        child: Text(
          val.isNotEmpty ? val : ' ',
          style: val.isNotEmpty ? _valStyle(9.5) : _mReg(9.5),
        ),
      ),
    ],
  );

  if (expand) return Expanded(child: content);
  if (width != null) return SizedBox(width: width, child: content);
  return content;
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 1: PART I (Accused Memorandum)
// ─────────────────────────────────────────────────────────────────────────────

Widget _pg1(Map<String, dynamic> doc) {
  final dist = _v(doc, 'dist').isNotEmpty ? _v(doc, 'dist') : _v(doc, 'district');
  final ps = _v(doc, 'ps').isNotEmpty ? _v(doc, 'ps') : _v(doc, 'policeStation');
  final year = _v(doc, 'year');
  final firNo = _v(doc, 'firNo');
  final firDate = _v(doc, 'firDate');

  final accusedName = _v(doc, 'accusedName');
  final accusedAge = _v(doc, 'accusedAge');
  final accusedSex = _v(doc, 'accusedSex');

  final arrestDate = _v(doc, 'arrestDate');
  final arrestTime = _v(doc, 'arrestTime');

  final memo = _v(doc, 'accusedMemorandum');
  final placeMemo = _v(doc, 'placeOfMemorandum');
  final memDate = _v(doc, 'memDate');
  final memTime = _v(doc, 'memTime');

  final panch1 = _v(doc, 'panch1NameAddr');
  final panch1Sig = _v(doc, 'panch1Sig');
  final panch2 = _v(doc, 'panch2NameAddr');
  final panch2Sig = _v(doc, 'panch2Sig');

  final part1AccusedSig = _v(doc, 'part1AccusedSig');
  final ioName = _v(doc, 'part1IoName');
  final ioRank = _v(doc, 'part1IoRank');
  final ioNo = _v(doc, 'part1IoNo');
  final ioPosting = _v(doc, 'part1IoPosting');

  return Container(
    width: _kW,
    height: _kH,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
    color: Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top right Form Label
        Align(
          alignment: Alignment.topRight,
          child: Text(
            'Form: 2-E',
            style: _eBld(11).copyWith(decoration: TextDecoration.underline),
          ),
        ),
        const SizedBox(height: 4),

        // Title Header
        Center(
          child: Column(
            children: [
              Text(
                'ACCUSED MEMORANDUM FORM',
                style: _eBld(15).copyWith(decoration: TextDecoration.underline),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                'गुन्ह्यांच्या तपशीलाचा नमुना/ आरोपीचे निवेदन पंचनामा',
                style: _mBld(12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                '(Panchanama u/s 23(2) Bhartiya Saksh Adhiniyam, 2023 कलम २३ (२) भारतीय साक्ष अधिनियम २०२३)',
                style: _eBld(9.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Divider(color: Colors.black87, thickness: 1),
        const SizedBox(height: 6),

        // Section 1: Case Details
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1) ', style: _eBld(10)),
            _bilingualField('District:', 'जिल्हा', dist, width: 95),
            const SizedBox(width: 20),
            _bilingualField('P.S.:', 'पोलीस ठाणे', ps, width: 135),
            const SizedBox(width: 8),
            _bilingualField('Year:', 'वर्ष', year, width: 65),
            const SizedBox(width: 8),
            _bilingualField('FIR No:', 'गु.र.क्र.', firNo, width: 110),
            const SizedBox(width: 8),
            _bilingualField('Date:', 'दिनांक', firDate, expand: true),
          ],
        ),
        const SizedBox(height: 8),

        // Section 2: Accused Particulars
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('2) ', style: _eBld(10)),
            _bilingualField('Name of Accused:', 'आरोपीचे नाव', accusedName,
                expand: true),
            const SizedBox(width: 12),
            _bilingualField('Age:', 'वय', accusedAge, width: 70),
            const SizedBox(width: 12),
            _bilingualField('Sex:', 'लिंग', accusedSex, width: 70),
          ],
        ),
        const SizedBox(height: 8),

        // Section 3: Date & Time of Arrest
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('3) ', style: _eBld(10)),
            _bilingualField('Date of Arrest:', 'अटक तारीख', arrestDate,
                width: 180),
            const SizedBox(width: 16),
            _bilingualField('Time of Arrest:', 'अटक वेळ', arrestTime,
                width: 180),
          ],
        ),
        const SizedBox(height: 8),

        // Section 4: Memorandum Text
        Row(
          children: [
            Text('4) Memorandum made by Accused: - ', style: _eBld(9.5)),
            Text('(आरोपीने केलेले निवेदन: -)', style: _mBld(9.5)),
          ],
        ),
        const SizedBox(height: 3),
        Container(
          width: double.infinity,
          height: 120,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black87, width: 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            memo.isNotEmpty ? memo : ' ',
            style: memo.isNotEmpty ? _valStyle(9.5) : _mReg(9.5),
          ),
        ),
        const SizedBox(height: 8),

        // Section 5: Place & Time of Memorandum
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('5) ', style: _eBld(10)),
            _bilingualField(
                'Place of Memorandum:', 'निवेदनाचे ठिकाण', placeMemo,
                expand: true),
            const SizedBox(width: 12),
            _bilingualField('Date:', 'दिनांक', memDate, width: 110),
            const SizedBox(width: 12),
            _bilingualField('Time:', 'वेळ', memTime, width: 110),
          ],
        ),
        const SizedBox(height: 8),

        // Section 6: Panchas
        Row(
          children: [
            Text('6) Name & Address of Panchas & Signatures: ',
                style: _eBld(9.5)),
            Text('(पंचांची नावे, पत्ते व सह्या)', style: _mBld(9.5)),
          ],
        ),
        const SizedBox(height: 3),
        Table(
          border: TableBorder.all(color: Colors.black87, width: 0.8),
          columnWidths: const {
            0: FixedColumnWidth(30),
            1: FlexColumnWidth(3),
            2: FlexColumnWidth(2),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              children: [
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Center(child: Text('क्र.', style: _mBld(9))),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text('पंचाचे नाव व पत्ता', style: _mBld(9)),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Center(child: Text('पंचाची सही', style: _mBld(9))),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Center(child: Text('१', style: _mBld(9))),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(panch1.isNotEmpty ? panch1 : ' ',
                      style: panch1.isNotEmpty ? _valStyle(9) : _mReg(9)),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Center(
                    child: Text(panch1Sig.isNotEmpty ? panch1Sig : ' ',
                        style: panch1Sig.isNotEmpty ? _valStyle(9) : _mReg(9)),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Center(child: Text('२', style: _mBld(9))),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(panch2.isNotEmpty ? panch2 : ' ',
                      style: panch2.isNotEmpty ? _valStyle(9) : _mReg(9)),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Center(
                    child: Text(panch2Sig.isNotEmpty ? panch2Sig : ' ',
                        style: panch2Sig.isNotEmpty ? _valStyle(9) : _mReg(9)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),

        // Section 7: Signatures (Part I)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('7) Accused Signature and Thumb', style: _eBld(9.5)),
                Text('   आरोपीची सही व अंगठा', style: _mBld(9)),
                const SizedBox(height: 18),
                Text(
                  part1AccusedSig.isNotEmpty
                      ? part1AccusedSig
                      : '_______________________',
                  style:
                      part1AccusedSig.isNotEmpty ? _valStyle(9.5) : _mReg(9.5),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Signature of Investigation Officer', style: _eBld(9.5)),
                Text('तपासणी करणाऱ्या अधिकाऱ्याची सही व हुद्दा',
                    style: _mBld(9)),
                const SizedBox(height: 4),
                Text('नाव: ${ioName.isNotEmpty ? ioName : '____________'}',
                    style: ioName.isNotEmpty ? _valStyle(9) : _mReg(9)),
                Text(
                    'हुद्दा: ${ioRank.isNotEmpty ? ioRank : '_______'}  क्र.: ${ioNo.isNotEmpty ? ioNo : '______'}',
                    style: _mReg(9)),
                Text(
                    'नेमणूक: ${ioPosting.isNotEmpty ? ioPosting : '________________'}',
                    style: ioPosting.isNotEmpty ? _valStyle(9) : _mReg(9)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 2: PART II (Further Panchanama)
// ─────────────────────────────────────────────────────────────────────────────

Widget _pg2(Map<String, dynamic> doc) {
  final further = _v(doc, 'furtherPanchanama');
  final furtherDate = _v(doc, 'furtherDate');
  final furtherTime = _v(doc, 'furtherTime');

  final panch1 = _v(doc, 'furtherPanch1NameAddr');
  final panch1Sig = _v(doc, 'furtherPanch1Sig');
  final panch2 = _v(doc, 'furtherPanch2NameAddr');
  final panch2Sig = _v(doc, 'furtherPanch2Sig');

  final accusedSig = _v(doc, 'accusedSig');
  final ioName = _v(doc, 'ioName');
  final ioRank = _v(doc, 'ioRank');
  final ioNo = _v(doc, 'ioNo');
  final ioPosting = _v(doc, 'ioPosting');

  return Container(
    width: _kW,
    height: _kH,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
    color: Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top right Form Label
        Align(
          alignment: Alignment.topRight,
          child: Text(
            'Form: 2-E (Part II)',
            style: _eBld(11).copyWith(decoration: TextDecoration.underline),
          ),
        ),
        const SizedBox(height: 4),

        // Title Header
        Center(
          child: Column(
            children: [
              Text(
                'ACCUSED MEMORANDUM FORM (Part II)',
                style: _eBld(15).copyWith(decoration: TextDecoration.underline),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                'अधिक पंचनामा (Part II)',
                style: _mBld(12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                '(Panchanama u/s 23(2) Bhartiya Saksh Adhiniyam, 2023 कलम २३ (२) भारतीय साक्ष अधिनियम २०२३)',
                style: _eBld(9.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Divider(color: Colors.black87, thickness: 1),
        const SizedBox(height: 8),

        // Section 8: Details of Further Panchanama
        Row(
          children: [
            Text('8) Details of Further Panchanama: ', style: _eBld(10)),
            Text('(पंचनाम्याचा पुढील भाग):-', style: _mBld(10)),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          height: 320,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black87, width: 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            further.isNotEmpty ? further : ' ',
            style: further.isNotEmpty ? _valStyle(9.8) : _mReg(9.8),
          ),
        ),
        const SizedBox(height: 12),

        // Date & Time
        Row(
          children: [
            _bilingualField('Date:', 'दिनांक', furtherDate, width: 140),
            const SizedBox(width: 24),
            _bilingualField('Time:', 'वेळ', furtherTime, width: 140),
          ],
        ),
        const SizedBox(height: 14),

        // Section 9: Panchas (Part II)
        Row(
          children: [
            Text('9) Name & Address of Panchas & Signatures: ',
                style: _eBld(9.5)),
            Text('(पंचांची नावे, पत्ते व सह्या)', style: _mBld(9.5)),
          ],
        ),
        const SizedBox(height: 3),
        Table(
          border: TableBorder.all(color: Colors.black87, width: 0.8),
          columnWidths: const {
            0: FixedColumnWidth(30),
            1: FlexColumnWidth(3),
            2: FlexColumnWidth(2),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              children: [
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Center(child: Text('क्र.', style: _mBld(9))),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text('पंचाचे नाव व पत्ता', style: _mBld(9)),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Center(child: Text('पंचाची सही', style: _mBld(9))),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Center(child: Text('१', style: _mBld(9))),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(panch1.isNotEmpty ? panch1 : ' ',
                      style: panch1.isNotEmpty ? _valStyle(9) : _mReg(9)),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Center(
                    child: Text(panch1Sig.isNotEmpty ? panch1Sig : ' ',
                        style: panch1Sig.isNotEmpty ? _valStyle(9) : _mReg(9)),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Center(child: Text('२', style: _mBld(9))),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(panch2.isNotEmpty ? panch2 : ' ',
                      style: panch2.isNotEmpty ? _valStyle(9) : _mReg(9)),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Center(
                    child: Text(panch2Sig.isNotEmpty ? panch2Sig : ' ',
                        style: panch2Sig.isNotEmpty ? _valStyle(9) : _mReg(9)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),

        // Section 10: Signatures (Part II)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('10) Accused Signature and Thumb', style: _eBld(9.5)),
                Text('    आरोपीची सही व अंगठा', style: _mBld(9)),
                const SizedBox(height: 18),
                Text(
                  accusedSig.isNotEmpty
                      ? accusedSig
                      : '_______________________',
                  style: accusedSig.isNotEmpty ? _valStyle(9.5) : _mReg(9.5),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Signature of Investigation Officer', style: _eBld(9.5)),
                Text('तपासणी करणाऱ्या अधिकाऱ्याची सही व हुद्दा',
                    style: _mBld(9)),
                const SizedBox(height: 4),
                Text('नाव: ${ioName.isNotEmpty ? ioName : '____________'}',
                    style: ioName.isNotEmpty ? _valStyle(9) : _mReg(9)),
                Text(
                    'हुद्दा: ${ioRank.isNotEmpty ? ioRank : '_______'}  क्र.: ${ioNo.isNotEmpty ? ioNo : '______'}',
                    style: _mReg(9)),
                Text(
                    'नेमणूक: ${ioPosting.isNotEmpty ? ioPosting : '________________'}',
                    style: ioPosting.isNotEmpty ? _valStyle(9) : _mReg(9)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    ),
  );
}

Future<Uint8List> generateAccusedMemorandumPdf(
  Map<String, dynamic> doc,
) async {
  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Center(
        child: pw.Text('Accused Memorandum',
            style: const pw.TextStyle(fontSize: 12)),
      ),
    ),
  );
  return pdf.save();
}
