// lib/utils/property_seizure_pdf.dart
//
// IMAGE-BASED PDF generation for PROPERTY SEARCH & SEIZURE FORM:
//   Page 1: Seizure Memo Body (Sections 1–11)
//   Page 2: Seizure Memo Signatures (Sections 12–14)
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

Future<void> previewPropertySeizurePdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final fileName =
      'Property_Seizure_Form_${DateTime.now().millisecondsSinceEpoch}.pdf';
  try {
    final bytes = await _buildImagePdf(context, doc);
    if (!context.mounted) return;
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } else {
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);
    }
  } catch (e) {
    debugPrint('Error generating image-based Property Seizure PDF: $e');
    if (!context.mounted) return;
    try {
      final bytes = await generatePropertySeizurePdf(doc);
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (_) {}
  }
}

Future<Uint8List> _buildImagePdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  const knownSectionIds = {'Seizure Memo Body', 'Seizure Memo Signatures'};
  final activeSection = doc['formSection']?.toString();

  bool showsSection(String sectionId) => showsFormSection(
        activeSection: activeSection,
        sectionId: sectionId,
        knownSectionIds: knownSectionIds,
      );

  final showBody = showsSection('Seizure Memo Body');
  final showSignatures = showsSection('Seizure Memo Signatures');

  final pages = <Widget>[];
  if (showBody) pages.add(_pg1(doc));
  if (showSignatures) pages.add(_pg2(doc));

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
// PAGE 1: Seizure Memo Body (Sections 1–11)
// ─────────────────────────────────────────────────────────────────────────────

Widget _pg1(Map<String, dynamic> doc) {
  final dist = _v(doc, 'district');
  final ps = _v(doc, 'ps');
  final year = _v(doc, 'year');
  final firNo = _v(doc, 'firNo');
  final firDate = _v(doc, 'date');

  final actSection = _v(doc, 'actSection');
  final natureOfProperty = _v(doc, 'natureOfProperty');
  final propertyDetails = _v(doc, 'propertyDetails');
  final seizureDate = _v(doc, 'seizureDate');
  final seizureTime = _v(doc, 'seizureTime');
  final seizurePlace = _v(doc, 'seizurePlace');
  final seizurePlaceDesc = _v(doc, 'seizurePlaceDesc');
  final seizedFrom = _v(doc, 'seizedFrom');
  final isProfReceiver = _v(doc, 'isProfessionalReceiver');

  final pName = _v(doc, 'personName');
  final pFather = _v(doc, 'personFather');
  final pSex = _v(doc, 'personSex');
  final pAge = _v(doc, 'personAge');
  final pOcc = _v(doc, 'personOccupation');
  final pAddr = _v(doc, 'personAddress');

  final w1Name = _v(doc, 'w1Name');
  final w1Father = _v(doc, 'w1Father');
  final w1Age = _v(doc, 'w1Age');
  final w1Sex = _v(doc, 'w1Sex');
  final w1Occ = _v(doc, 'w1Occupation');
  final w1Addr = _v(doc, 'w1Address');

  final w2Name = _v(doc, 'w2Name');
  final w2Father = _v(doc, 'w2Father');
  final w2Age = _v(doc, 'w2Age');
  final w2Sex = _v(doc, 'w2Sex');
  final w2Occ = _v(doc, 'w2Occupation');
  final w2Addr = _v(doc, 'w2Address');

  final perishable = _v(doc, 'perishableDisposal');
  final valuable = _v(doc, 'valuableKeeping');
  final identification = _v(doc, 'identificationRequired');

  return Container(
    width: _kW,
    height: _kH,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
    color: Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Text(
                'PROPERTY SEARCH & SEIZURE FORM',
                style: _eBld(14).copyWith(decoration: TextDecoration.underline),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                'मालमत्ता झडती व जप्ती नमुना',
                style: _mBld(12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                '(Search/ Production/ Recovery u/s. 185 B.N.S.S)',
                style: _eBld(9),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Divider(color: Colors.black87, thickness: 0.8),
        const SizedBox(height: 4),

        // 1) Case Details
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
        const SizedBox(height: 5),

        // 2) Act & Section
        Row(
          children: [
            Text('2) ', style: _eBld(9.5)),
            _bilingualField('Acts & Sections:', 'अधिनियम व कलमे', actSection,
                expand: true),
          ],
        ),
        const SizedBox(height: 5),

        // 3) Nature of Property
        Row(
          children: [
            Text('3) ', style: _eBld(9.5)),
            _bilingualField('Nature of Property Seized:', 'जप्त मालमत्तेचे स्वरूप',
                natureOfProperty, expand: true),
          ],
        ),
        const SizedBox(height: 5),

        // 4) Details of Property
        Row(
          children: [
            Text('4) ', style: _eBld(9.5)),
            _bilingualField('Details of Property Seized:', 'जप्त मालमत्तेचा तपशील',
                propertyDetails, expand: true),
          ],
        ),
        const SizedBox(height: 5),

        // 5 & 6) Date, Time, Place
        Row(
          children: [
            Text('5) ', style: _eBld(9.5)),
            _bilingualField('Date of Seizure:', 'जप्ती तारीख', seizureDate,
                width: 120),
            const SizedBox(width: 8),
            _bilingualField('Time:', 'वेळ', seizureTime, width: 90),
            const SizedBox(width: 8),
            _bilingualField('Place:', 'ठिकाण', seizurePlace, width: 160),
            const SizedBox(width: 8),
            Text('6) ', style: _eBld(9.5)),
            _bilingualField(
                'Description:', 'जागेचे वर्णन', seizurePlaceDesc, expand: true),
          ],
        ),
        const SizedBox(height: 5),

        // 7 & 8) Seized From & Prof Receiver
        Row(
          children: [
            Text('7) ', style: _eBld(9.5)),
            _bilingualField(
                'Seized from:', 'कोणाकडून जप्त करण्यात आली', seizedFrom,
                width: 250),
            const SizedBox(width: 12),
            Text('8) ', style: _eBld(9.5)),
            _bilingualField('Professional receiver?:', 'सराईत मालमत्ता घेणारा?',
                isProfReceiver, expand: true),
          ],
        ),
        const SizedBox(height: 5),

        // 9) Particulars of Person
        Text('9) Person from whom seized (ज्या इसमाकडून मालमत्ता जप्त केली):',
            style: _eBld(9.5)),
        const SizedBox(height: 2),
        Row(
          children: [
            const SizedBox(width: 16),
            _bilingualField('Name:', 'नाव', pName, expand: true),
            const SizedBox(width: 8),
            _bilingualField('Father/Husband:', 'वडील/पती', pFather, width: 130),
            const SizedBox(width: 8),
            _bilingualField('Age:', 'वय', pAge, width: 50),
            const SizedBox(width: 8),
            _bilingualField('Sex:', 'लिंग', pSex, width: 50),
            const SizedBox(width: 8),
            _bilingualField('Occupation:', 'व्यवसाय', pOcc, width: 100),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: _bilingualField('Address:', 'पत्ता', pAddr, expand: true),
        ),
        const SizedBox(height: 5),

        // 10) Witnesses Table
        Text('10) Particulars of Witnesses / Panchas (पंचांची माहिती):',
            style: _eBld(9.5)),
        const SizedBox(height: 3),
        Table(
          border: TableBorder.all(color: Colors.black87, width: 0.8),
          columnWidths: const {
            0: FixedColumnWidth(26),
            1: FlexColumnWidth(2.5),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(0.8),
            4: FlexColumnWidth(0.8),
            5: FlexColumnWidth(1.2),
            6: FlexColumnWidth(2.5),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              children: [
                Padding(
                  padding: const EdgeInsets.all(2),
                  child: Center(child: Text('क्र.', style: _mBld(8))),
                ),
                Padding(
                  padding: const EdgeInsets.all(2),
                  child: Text('नाव', style: _mBld(8)),
                ),
                Padding(
                  padding: const EdgeInsets.all(2),
                  child: Text('वडील/पती', style: _mBld(8)),
                ),
                Padding(
                  padding: const EdgeInsets.all(2),
                  child: Center(child: Text('वय', style: _mBld(8))),
                ),
                Padding(
                  padding: const EdgeInsets.all(2),
                  child: Center(child: Text('लिंग', style: _mBld(8))),
                ),
                Padding(
                  padding: const EdgeInsets.all(2),
                  child: Text('व्यवसाय', style: _mBld(8)),
                ),
                Padding(
                  padding: const EdgeInsets.all(2),
                  child: Text('पत्ता', style: _mBld(8)),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Center(child: Text('१', style: _mBld(8))),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text(w1Name,
                      style: w1Name.isNotEmpty ? _valStyle(8) : _mReg(8)),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text(w1Father,
                      style: w1Father.isNotEmpty ? _valStyle(8) : _mReg(8)),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Center(
                    child: Text(w1Age,
                        style: w1Age.isNotEmpty ? _valStyle(8) : _mReg(8)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Center(
                    child: Text(w1Sex,
                        style: w1Sex.isNotEmpty ? _valStyle(8) : _mReg(8)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text(w1Occ,
                      style: w1Occ.isNotEmpty ? _valStyle(8) : _mReg(8)),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text(w1Addr,
                      style: w1Addr.isNotEmpty ? _valStyle(8) : _mReg(8)),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Center(child: Text('२', style: _mBld(8))),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text(w2Name,
                      style: w2Name.isNotEmpty ? _valStyle(8) : _mReg(8)),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text(w2Father,
                      style: w2Father.isNotEmpty ? _valStyle(8) : _mReg(8)),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Center(
                    child: Text(w2Age,
                        style: w2Age.isNotEmpty ? _valStyle(8) : _mReg(8)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Center(
                    child: Text(w2Sex,
                        style: w2Sex.isNotEmpty ? _valStyle(8) : _mReg(8)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text(w2Occ,
                      style: w2Occ.isNotEmpty ? _valStyle(8) : _mReg(8)),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text(w2Addr,
                      style: w2Addr.isNotEmpty ? _valStyle(8) : _mReg(8)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 5),

        // 11) Disposal
        Text('11) Custody & Disposal (मालमत्तेची विल्हेवाट):', style: _eBld(9.5)),
        const SizedBox(height: 2),
        Row(
          children: [
            const SizedBox(width: 16),
            _bilingualField('Perishable item disposal:', 'नाशवंत वस्तू विल्हेवाट',
                perishable, width: 220),
            const SizedBox(width: 12),
            _bilingualField('Valuable item custody:', 'मौल्यवान वस्तू सुरक्षा',
                valuable, width: 220),
            const SizedBox(width: 12),
            _bilingualField('Identification required?:', 'ओळखपरेड आवश्यक?:',
                identification, expand: true),
          ],
        ),
        const Spacer(),
        Align(
          alignment: Alignment.centerRight,
          child: Text('Page 1 of 2 — Seizure Memo Body',
              style: GoogleFonts.lora(fontSize: 8.5, color: Colors.black54)),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 2: Seizure Memo Signatures (Sections 12–14)
// ─────────────────────────────────────────────────────────────────────────────

Widget _pg2(Map<String, dynamic> doc) {
  final circumstances = _v(doc, 'circumstances');
  final packingDetails = _v(doc, 'packingDetails');

  final w1Sig = _v(doc, 'w1Sig');
  final w2Sig = _v(doc, 'w2Sig');
  final personSig = _v(doc, 'personSig');

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
        Center(
          child: Column(
            children: [
              Text(
                'PROPERTY SEARCH & SEIZURE FORM (Signatures)',
                style: _eBld(13.5).copyWith(decoration: TextDecoration.underline),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                'मालमत्ता झडती व जप्ती नमुना (सह्यांचा भाग)',
                style: _mBld(11.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Divider(color: Colors.black87, thickness: 0.8),
        const SizedBox(height: 6),

        // 12) Circumstances
        Text(
          '12) Circumstances under which property was recovered/seized (जप्तीची परिस्थिती):',
          style: _eBld(9.5),
        ),
        const SizedBox(height: 3),
        Container(
          width: double.infinity,
          height: 200,
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
        const SizedBox(height: 10),

        // 13) Packing & Sealing Details
        Text(
          '13) Details of properties packed and sealed (सिलबंद केल्याचा तपशील):',
          style: _eBld(9.5),
        ),
        const SizedBox(height: 3),
        Container(
          width: double.infinity,
          height: 180,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black87, width: 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            packingDetails.isNotEmpty ? packingDetails : ' ',
            style: packingDetails.isNotEmpty ? _valStyle(9) : _mReg(9),
          ),
        ),
        const SizedBox(height: 14),

        // 14) Signatures
        Text('14) Signatures / सह्या:', style: _eBld(10)),
        const SizedBox(height: 8),

        // Panch 1 and Panch 2 signatures
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Panch 1 Signature (पंचाची सही):', style: _eBld(9)),
                const SizedBox(height: 12),
                Text(w1Sig.isNotEmpty ? w1Sig : '_______________________',
                    style: w1Sig.isNotEmpty ? _valStyle(9) : _mReg(9)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Panch 2 Signature (दुसऱ्या पंचाची सही):',
                    style: _eBld(9)),
                const SizedBox(height: 12),
                Text(w2Sig.isNotEmpty ? w2Sig : '_______________________',
                    style: w2Sig.isNotEmpty ? _valStyle(9) : _mReg(9)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Person and IO
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Signature of Person from whom seized:', style: _eBld(9)),
                Text('ज्याच्याकडून जप्त केले त्याची सही / अंगठा',
                    style: _mBld(8.5)),
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
                Text('Investigating Officer Signature', style: _eBld(9)),
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
        const Spacer(),
        Align(
          alignment: Alignment.centerRight,
          child: Text('Page 2 of 2 — Seizure Memo Signatures',
              style: GoogleFonts.lora(fontSize: 8.5, color: Colors.black54)),
        ),
      ],
    ),
  );
}

Future<Uint8List> generatePropertySeizurePdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Center(
        child: pw.Text('Property Seizure Form',
            style: const pw.TextStyle(fontSize: 12)),
      ),
    ),
  );
  return pdf.save();
}
