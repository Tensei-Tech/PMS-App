// lib/utils/house_property_search_seizure_pdf.dart
//
// IMAGE-BASED PDF generation for HOUSE/PROPERTY SEARCH & SEIZURE:
//   Page 1: Search & Seizure Form (Sections 1–10)
//   Page 2: Search & Seizure Panchanama (Sections 11–16)
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

import '../widgets/form_section_utils.dart';

const double _kW = 794.0;
const double _kH = 1123.0;
const double _kPx = 2.0;

Future<void> previewHousePropertySearchSeizurePdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final fileName =
      'House_Property_Search_Seizure_${DateTime.now().millisecondsSinceEpoch}.pdf';
  try {
    final bytes = await _buildImagePdf(context, doc);
    if (!context.mounted) return;
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } else {
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);
    }
  } catch (e) {
    debugPrint('Error generating image-based Search & Seizure PDF: $e');
    if (!context.mounted) return;
    try {
      final bytes = await generateHousePropertySearchSeizurePdf(doc);
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (_) {}
  }
}

Future<Uint8List> _buildImagePdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  const knownSectionIds = {'Search Seizure Form', 'Search Seizure Panchanama'};
  final activeSection = doc['formSection']?.toString();

  bool showsSection(String sectionId) => showsFormSection(
        activeSection: activeSection,
        sectionId: sectionId,
        knownSectionIds: knownSectionIds,
      );

  final showForm = showsSection('Search Seizure Form');
  final showPanchanama = showsSection('Search Seizure Panchanama');

  final pages = <Widget>[];
  if (showForm) pages.add(_pg1(doc));
  if (showPanchanama) pages.add(_pg2(doc));

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

TextStyle _eBld([double sz = 9.5]) => GoogleFonts.lora(
      fontSize: sz,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );

TextStyle _mBld([double sz = 9]) => GoogleFonts.notoSansDevanagari(
      fontSize: sz,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );

TextStyle _mReg([double sz = 9]) => GoogleFonts.notoSansDevanagari(
      fontSize: sz,
      color: Colors.black87,
    );

TextStyle _valStyle([double sz = 9]) => GoogleFonts.notoSansDevanagari(
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
          Text(eng, style: _eBld(9)),
          const SizedBox(width: 4),
          Text('($mr)', style: _mBld(8.5)),
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
          style: val.isNotEmpty ? _valStyle(9) : _mReg(9),
        ),
      ),
    ],
  );

  if (expand) return Expanded(child: content);
  if (width != null) return SizedBox(width: width, child: content);
  return content;
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 1: Search & Seizure Form (Sections 1–10)
// ─────────────────────────────────────────────────────────────────────────────

Widget _pg1(Map<String, dynamic> doc) {
  final dist = _v(doc, 'dist');
  final ps = _v(doc, 'ps');
  final year = _v(doc, 'year');
  final firNo = _v(doc, 'firNo');
  final firDate = _v(doc, 'headerDate');

  final actSections = _v(doc, 'actSections');
  final natureProperty = _v(doc, 'natureProperty');
  final propertyDetails = _v(doc, 'propertyDetails');
  final placeSeized = _v(doc, 'placeSeized');
  final placeDescription = _v(doc, 'placeDescription');
  final profReceiver = _v(doc, 'profReceiver');

  final personName = _v(doc, 'personName');
  final personFather = _v(doc, 'personFather');
  final personAge = _v(doc, 'personAge');
  final personSex = _v(doc, 'personSex');
  final personOccupation = _v(doc, 'personOccupation');
  final personAddress = _v(doc, 'personAddress');

  final perishableDisposal = _v(doc, 'perishableDisposal');
  final valuableKeeping = _v(doc, 'valuableKeeping');
  final identificationRequired = _v(doc, 'identificationRequired');
  final circumstances = _v(doc, 'circumstances');

  return Container(
    width: _kW,
    height: _kH,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
    color: Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: Text(
            'Form: 2-D',
            style: _eBld(11).copyWith(decoration: TextDecoration.underline),
          ),
        ),
        const SizedBox(height: 3),
        Center(
          child: Column(
            children: [
              Text(
                'HOUSE/PROPERTY SEARCH & SEIZURE FORM',
                style: _eBld(14).copyWith(decoration: TextDecoration.underline),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                'घर / मालमत्ता झडती व जप्ती नमुना',
                style: _mBld(12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                '[Section 105, 106, 185(1) of B.N.S.S. 2023 / बी.एन.एस.एस. २०२३ चे कलम १०५, १०६, १८५(१)]',
                style: _eBld(9),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Divider(color: Colors.black87, thickness: 0.8),
        const SizedBox(height: 4),

        // 1) Case Info
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1) ', style: _eBld(9.5)),
            _bilingualField('District:', 'जिल्हा', dist, width: 110),
            const SizedBox(width: 8),
            _bilingualField('P.S.:', 'पोलीस ठाणे', ps, width: 120),
            const SizedBox(width: 8),
            _bilingualField('Year:', 'वर्ष', year, width: 60),
            const SizedBox(width: 8),
            _bilingualField('FIR No:', 'गु.र.क्र.', firNo, width: 110),
            const SizedBox(width: 8),
            _bilingualField('Date:', 'दिनांक', firDate, expand: true),
          ],
        ),
        const SizedBox(height: 6),

        // 2) Acts & Sections
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('2) ', style: _eBld(9.5)),
            _bilingualField('Acts & Sections:', 'अधिनियम व कलमे', actSections,
                expand: true),
          ],
        ),
        const SizedBox(height: 6),

        // 3) Nature of Property
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('3) ', style: _eBld(9.5)),
            _bilingualField('Nature of Property Seized:',
                'जप्त मालमत्तेचे स्वरूप', natureProperty,
                expand: true),
          ],
        ),
        const SizedBox(height: 6),

        // 4) Details of Property
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('4) ', style: _eBld(9.5)),
            _bilingualField('Details of Property Seized:',
                'जप्त मालमत्तेचा तपशील', propertyDetails,
                expand: true),
          ],
        ),
        const SizedBox(height: 6),

        // 5 & 6) Place seized & Description
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('5) ', style: _eBld(9.5)),
            _bilingualField('Place where seized:', 'जप्तीचे ठिकाण', placeSeized,
                width: 320),
            const SizedBox(width: 12),
            Text('6) ', style: _eBld(9.5)),
            _bilingualField(
                'Description of place:', 'जागेचे वर्णन', placeDescription,
                expand: true),
          ],
        ),
        const SizedBox(height: 6),

        // 7) Professional receiver
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('7) ', style: _eBld(9.5)),
            _bilingualField('Professional receiver of stolen property?:',
                'सराईत मालमत्ता घेणारा आहे काय?', profReceiver,
                expand: true),
          ],
        ),
        const SizedBox(height: 6),

        // 8) Person Details
        Text('8) Person from whom seized (ज्या इसमाकडून मालमत्ता जप्त केली):',
            style: _eBld(9.5)),
        const SizedBox(height: 3),
        Row(
          children: [
            const SizedBox(width: 16),
            _bilingualField('Name:', 'नाव', personName, expand: true),
            const SizedBox(width: 8),
            _bilingualField('Father/Husband:', 'वडील/पती', personFather,
                width: 140),
            const SizedBox(width: 8),
            _bilingualField('Age:', 'वय', personAge, width: 50),
            const SizedBox(width: 8),
            _bilingualField('Sex:', 'लिंग', personSex, width: 50),
            const SizedBox(width: 8),
            _bilingualField('Occupation:', 'व्यवसाय', personOccupation,
                width: 110),
          ],
        ),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child:
              _bilingualField('Address:', 'पत्ता', personAddress, expand: true),
        ),
        const SizedBox(height: 6),

        // 9) Disposal
        Text('9) Custody / Disposal of Property (मालमत्तेची विल्हेवाट):',
            style: _eBld(9.5)),
        const SizedBox(height: 3),
        Row(
          children: [
            const SizedBox(width: 16),
            _bilingualField('Perishable item disposal:',
                'नाशवंत वस्तू विल्हेवाट', perishableDisposal,
                width: 220),
            const SizedBox(width: 12),
            _bilingualField('Valuable item safekeeping:',
                'मौल्यवान वस्तू सुरक्षा', valuableKeeping,
                width: 220),
            const SizedBox(width: 12),
            _bilingualField('Identification required?:', 'ओळखपरेड आवश्यक?:',
                identificationRequired,
                expand: true),
          ],
        ),
        const SizedBox(height: 6),

        // 10) Circumstances
        Text('10) Circumstances of Seizure (जप्तीची परिस्थिती):',
            style: _eBld(9.5)),
        const SizedBox(height: 2),
        Container(
          width: double.infinity,
          height: 120,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black87, width: 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            circumstances.isNotEmpty ? circumstances : ' ',
            style: circumstances.isNotEmpty ? _valStyle(9) : _mReg(9),
          ),
        ),
        const Spacer(),
        Align(
          alignment: Alignment.centerRight,
          child: Text('Page 1 of 2 — Form 2-D',
              style: GoogleFonts.lora(fontSize: 8.5, color: Colors.black54)),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 2: Search & Seizure Panchanama (Sections 11–16)
// ─────────────────────────────────────────────────────────────────────────────

Widget _pg2(Map<String, dynamic> doc) {
  final packedDetails = _v(doc, 'propertyPackedDetails');
  final seizeDate = _v(doc, 'seizeDate');
  final seizeTime = _v(doc, 'seizeTime');

  final w1Name = _v(doc, 'witness1Name');
  final w1Age = _v(doc, 'witness1Age');
  final w1Occ = _v(doc, 'witness1Occupation');
  final w1Addr = _v(doc, 'witness1Address');
  final w1Sig = _v(doc, 'witness1Sig');

  final w2Name = _v(doc, 'witness2Name');
  final w2Age = _v(doc, 'witness2Age');
  final w2Occ = _v(doc, 'witness2Occupation');
  final w2Addr = _v(doc, 'witness2Address');
  final w2Sig = _v(doc, 'witness2Sig');

  final personSig = _v(doc, 'seizedPersonSig');
  final ioName = _v(doc, 'ioName');
  final ioRank = _v(doc, 'ioRank');
  final ioNo = _v(doc, 'ioNo');
  final ioPosting = _v(doc, 'ioPosting');

  return Container(
    width: _kW,
    height: _kH,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
    color: Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: Text(
            'Form: 2-D (Panchanama)',
            style: _eBld(11).copyWith(decoration: TextDecoration.underline),
          ),
        ),
        const SizedBox(height: 3),
        Center(
          child: Column(
            children: [
              Text(
                'SEARCH & SEIZURE PANCHANAMA',
                style: _eBld(14).copyWith(decoration: TextDecoration.underline),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                'झडती व जप्ती पंचनामा',
                style: _mBld(12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Divider(color: Colors.black87, thickness: 0.8),
        const SizedBox(height: 6),

        // 11) Packed & Sealed
        Text(
          '11) Details of properties packed and sealed (सिलबंद केलेल्या मालमत्तेचा तपशील):',
          style: _eBld(9.5),
        ),
        const SizedBox(height: 3),
        Container(
          width: double.infinity,
          height: 140,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black87, width: 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            packedDetails.isNotEmpty ? packedDetails : ' ',
            style: packedDetails.isNotEmpty ? _valStyle(9) : _mReg(9),
          ),
        ),
        const SizedBox(height: 8),

        // 12) Date & Time
        Row(
          children: [
            Text('12) ', style: _eBld(9.5)),
            _bilingualField('Date of Seizure:', 'जप्तीची तारीख', seizeDate,
                width: 150),
            const SizedBox(width: 24),
            _bilingualField('Time of Seizure:', 'जप्तीची वेळ', seizeTime,
                width: 180),
          ],
        ),
        const SizedBox(height: 8),

        // 13 & 14) Witnesses
        Text('13 & 14) Panch / Witness Particulars (पंचांची नावे व माहिती):',
            style: _eBld(9.5)),
        const SizedBox(height: 4),
        Table(
          border: TableBorder.all(color: Colors.black87, width: 0.8),
          columnWidths: const {
            0: FixedColumnWidth(30),
            1: FlexColumnWidth(3),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1.2),
            4: FlexColumnWidth(2.5),
            5: FlexColumnWidth(1.8),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              children: [
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Center(child: Text('क्र.', style: _mBld(8.5))),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text('पंचाचे नाव', style: _mBld(8.5)),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Center(child: Text('वय', style: _mBld(8.5))),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Center(child: Text('व्यवसाय', style: _mBld(8.5))),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text('पत्ता', style: _mBld(8.5)),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Center(child: Text('सही', style: _mBld(8.5))),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Center(child: Text('१', style: _mBld(8.5))),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text(w1Name,
                      style: w1Name.isNotEmpty ? _valStyle(8.5) : _mReg(8.5)),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Center(
                    child: Text(w1Age,
                        style: w1Age.isNotEmpty ? _valStyle(8.5) : _mReg(8.5)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Center(
                    child: Text(w1Occ,
                        style: w1Occ.isNotEmpty ? _valStyle(8.5) : _mReg(8.5)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text(w1Addr,
                      style: w1Addr.isNotEmpty ? _valStyle(8.5) : _mReg(8.5)),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Center(
                    child: Text(w1Sig,
                        style: w1Sig.isNotEmpty ? _valStyle(8.5) : _mReg(8.5)),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Center(child: Text('२', style: _mBld(8.5))),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text(w2Name,
                      style: w2Name.isNotEmpty ? _valStyle(8.5) : _mReg(8.5)),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Center(
                    child: Text(w2Age,
                        style: w2Age.isNotEmpty ? _valStyle(8.5) : _mReg(8.5)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Center(
                    child: Text(w2Occ,
                        style: w2Occ.isNotEmpty ? _valStyle(8.5) : _mReg(8.5)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text(w2Addr,
                      style: w2Addr.isNotEmpty ? _valStyle(8.5) : _mReg(8.5)),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Center(
                    child: Text(w2Sig,
                        style: w2Sig.isNotEmpty ? _valStyle(8.5) : _mReg(8.5)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),

        // 15 & 16) Signatures
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('15) Signature of Person Seized', style: _eBld(9)),
                Text('ज्या इसमाकडून जप्त केले त्याची सही', style: _mBld(8.5)),
                const SizedBox(height: 14),
                Text(
                  personSig.isNotEmpty ? personSig : '_______________________',
                  style: personSig.isNotEmpty ? _valStyle(9) : _mReg(9),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('16) Investigating Officer Signature', style: _eBld(9)),
                Text('तपासणी अधिकारी सही व हुद्दा', style: _mBld(8.5)),
                const SizedBox(height: 4),
                Text('नाव: ${ioName.isNotEmpty ? ioName : '____________'}',
                    style: ioName.isNotEmpty ? _valStyle(9) : _mReg(9)),
                Text(
                    'हुद्दा: ${ioRank.isNotEmpty ? ioRank : '_______'}  ब.नं.: ${ioNo.isNotEmpty ? ioNo : '______'}',
                    style: _mReg(9)),
                Text(
                    'पोलीस ठाणे: ${ioPosting.isNotEmpty ? ioPosting : '________________'}',
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

Future<Uint8List> generateHousePropertySearchSeizurePdf(
  Map<String, dynamic> doc,
) async {
  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Center(
        child: pw.Text('House/Property Search & Seizure',
            style: const pw.TextStyle(fontSize: 12)),
      ),
    ),
  );
  return pdf.save();
}
