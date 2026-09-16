// lib/utils/crime_detail_pdf.dart
//
// IMAGE-BASED PDF generation for CRIME DETAILS FORM:
//   Page 1: Form 2-A (Case & Occurrence)
//   Page 2: Form 2-B (Victims & Property)
//   Page 3: Form 2-C (Place, Map & Evidence)
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

Map<String, dynamic> mapToCrimeDetailDoc(Map<String, dynamic> source) {
  final out = Map<String, dynamic>.from(source);

  final firNo = source['crNo'] ??
      source['firNo'] ??
      source['caseNumber'] ??
      source['adNo'] ??
      source['ncNo'] ??
      '';
  out['firNo'] = firNo.toString();

  final regDateStr =
      source['regDate'] ?? source['date'] ?? source['incidentDate'] ?? '';
  out['date'] = regDateStr.toString();

  final comp = source['complainant'];
  if (comp is Map) {
    out['complainantName'] =
        comp['name']?.toString() ?? out['complainantName'] ?? '';
    out['complainantAge'] = comp['age']?.toString() ?? '';
    out['complainantGender'] = comp['gender']?.toString() ?? '';
    out['complainantOccupation'] = comp['occ']?.toString() ?? '';
    out['complainantMobile'] = comp['mobile']?.toString() ?? '';
    out['complainantAddress'] = comp['address']?.toString() ?? '';
  }

  final victim = source['victim'];
  if (victim is Map) {
    out['victimName'] = victim['name']?.toString() ?? out['victimName'] ?? '';
    out['victimAge'] = victim['age']?.toString() ?? '';
    out['victimGender'] = victim['gender']?.toString() ?? '';
    out['victimOccupation'] = victim['occ']?.toString() ?? '';
    out['victimMobile'] = victim['mobile']?.toString() ?? '';
    out['victimAddress'] = victim['address']?.toString() ?? '';
  }

  final village = source['spotVillage']?.toString() ?? '';
  final area = source['spotArea']?.toString() ?? '';
  final addr = source['spotAddress']?.toString() ?? '';
  final spotFull = [addr, area, village].where((s) => s.isNotEmpty).join(', ');
  if (spotFull.isNotEmpty) {
    out['placeAddress'] = spotFull;
    out['spotAddress'] = spotFull;
  }

  final caseResp = source['caseResponsibility'];
  if (caseResp is Map) {
    out['ioName'] = caseResp['ioName']?.toString() ?? out['ioName'] ?? '';
    out['ioDesig'] = caseResp['ioDesig']?.toString() ?? out['ioDesig'] ?? '';
    out['ioRank'] = caseResp['ioDesig']?.toString() ?? out['ioRank'] ?? '';
  }

  return out;
}

Future<void> previewCrimeDetailPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final fileName =
      'Crime_Detail_Form_${DateTime.now().millisecondsSinceEpoch}.pdf';
  try {
    final bytes = await _buildImagePdf(context, doc);
    if (!context.mounted) return;
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } else {
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);
    }
  } catch (e) {
    debugPrint('Error generating image-based Crime Detail PDF: $e');
    if (!context.mounted) return;
    try {
      final bytes = await generateCrimeDetailPdf(doc);
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (_) {}
  }
}

Future<Uint8List> _buildImagePdf(
  BuildContext context,
  Map<String, dynamic> rawDoc,
) async {
  final doc = mapToCrimeDetailDoc(rawDoc);

  const knownSectionIds = {'Form 2-A', 'Form 2-B', 'Form 2-C'};
  final activeSection = doc['formSection']?.toString();

  bool showsSection(String sectionId) => showsFormSection(
        activeSection: activeSection,
        sectionId: sectionId,
        knownSectionIds: knownSectionIds,
      );

  final show2A = showsSection('Form 2-A');
  final show2B = showsSection('Form 2-B');
  final show2C = showsSection('Form 2-C');

  final pages = <Widget>[];
  if (show2A) pages.add(_pg1(doc));
  if (show2B) pages.add(_pg2(doc));
  if (show2C) pages.add(_pg3(doc));

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
// PAGE 1: Form 2-A (Case & Occurrence)
// ─────────────────────────────────────────────────────────────────────────────

Widget _pg1(Map<String, dynamic> doc) {
  final dist = _v(doc, 'district');
  final ps = _v(doc, 'ps');
  final year = _v(doc, 'year');
  final firNo = _v(doc, 'firNo');
  final firDate = _v(doc, 'date');

  final actSection = _v(doc, 'actSection');
  final shownByName = _v(doc, 'shownByName');
  final shownByFather = _v(doc, 'shownByFatherHusband');
  final shownByAddress = _v(doc, 'shownByAddress');

  final typeOfCrime = _v(doc, 'typeOfCrime');
  final majorHead = _v(doc, 'majorHead');
  final minorHead = _v(doc, 'minorHead');
  final method = _v(doc, 'method');
  final conveyances = _v(doc, 'conveyances');
  final characterAssumed = _v(doc, 'characterAssumed');
  final languageSlang = _v(doc, 'languageSlang');
  final specialFeatures = _v(doc, 'specialFeature1');
  final placeType = _v(doc, 'placeOfOccurrenceType');
  final propertyInvolved = _v(doc, 'propertyInvolved');

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
            'Form: 2-A',
            style: _eBld(11).copyWith(decoration: TextDecoration.underline),
          ),
        ),
        const SizedBox(height: 2),
        Center(
          child: Column(
            children: [
              Text(
                'CRIME DETAILS FORM',
                style: _eBld(15).copyWith(decoration: TextDecoration.underline),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                'गुन्ह्यांचा तपशील नमुना (भाग १)',
                style: _mBld(12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                '(First Information Report / प्रथम खबरी अहवाल)',
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
        const SizedBox(height: 6),

        // 2) Act & Section
        Row(
          children: [
            Text('2) ', style: _eBld(9.5)),
            _bilingualField('Acts & Sections:', 'अधिनियम व कलमे', actSection,
                expand: true),
          ],
        ),
        const SizedBox(height: 6),

        // 3) Crime Shown By
        Text(
            '3) Crime spot shown by (ज्या इसमाने घटनास्थळ दाखविले त्याचे नाव):',
            style: _eBld(9.5)),
        const SizedBox(height: 3),
        Row(
          children: [
            const SizedBox(width: 16),
            _bilingualField('Name:', 'नाव', shownByName, expand: true),
            const SizedBox(width: 12),
            _bilingualField('Father/Husband:', 'वडील/पतीचे नाव', shownByFather,
                width: 180),
          ],
        ),
        const SizedBox(height: 3),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: _bilingualField('Address:', 'पत्ता', shownByAddress,
              expand: true),
        ),
        const SizedBox(height: 6),

        // 4) Crime Classification & Modus Operandi
        Text('4) Modus Operandi & Details (गुन्ह्याची पद्धत व तपशील):',
            style: _eBld(9.5)),
        const SizedBox(height: 4),
        Row(
          children: [
            const SizedBox(width: 16),
            _bilingualField('Type of Crime:', 'गुन्हा प्रकार', typeOfCrime,
                width: 220),
            const SizedBox(width: 12),
            _bilingualField('Major Head:', 'मुख्य प्रकार', majorHead,
                width: 220),
            const SizedBox(width: 12),
            _bilingualField('Minor Head:', 'उप प्रकार', minorHead,
                expand: true),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const SizedBox(width: 16),
            _bilingualField('Method Used:', 'वापरलेली पद्धत', method,
                width: 220),
            const SizedBox(width: 12),
            _bilingualField('Conveyances:', 'वाहने', conveyances, width: 220),
            const SizedBox(width: 12),
            _bilingualField('Character Assumed:', 'सोंग', characterAssumed,
                expand: true),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const SizedBox(width: 16),
            _bilingualField('Language/Slang:', 'भाषा/बोली', languageSlang,
                width: 220),
            const SizedBox(width: 12),
            _bilingualField('Special Features:', 'विशेष खूण', specialFeatures,
                width: 220),
            const SizedBox(width: 12),
            _bilingualField('Place of Occurrence:', 'जागा प्रकार', placeType,
                expand: true),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: _bilingualField(
              'Property Involved:', 'मालमत्ता सहभाग', propertyInvolved,
              expand: true),
        ),
        const Spacer(),
        Align(
          alignment: Alignment.centerRight,
          child: Text('Page 1 of 3 — Form 2-A',
              style: GoogleFonts.lora(fontSize: 8.5, color: Colors.black54)),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 2: Form 2-B (Victims & Property)
// ─────────────────────────────────────────────────────────────────────────────

Widget _pg2(Map<String, dynamic> doc) {
  final cName = _v(doc, 'complainantName');
  final cFather = _v(doc, 'complainantFather');
  final cAge = _v(doc, 'complainantAge');
  final cSex = _v(doc, 'complainantGender');
  final cOcc = _v(doc, 'complainantOccupation');
  final cMob = _v(doc, 'complainantMobile');
  final cAddr = _v(doc, 'complainantAddress');

  final vName = _v(doc, 'victimName');
  final vFather = _v(doc, 'victimFather');
  final vAge = _v(doc, 'victimAge');
  final vSex = _v(doc, 'victimGender');
  final vOcc = _v(doc, 'victimOccupation');
  final vMob = _v(doc, 'victimMobile');
  final vAddr = _v(doc, 'victimAddress');

  final stolenProp = _v(doc, 'propertyStolenDesc');
  final stolenVal = _v(doc, 'propertyStolenValue');
  final recoveredVal = _v(doc, 'propertyRecoveredValue');
  final suspects = _v(doc, 'accusedDetails');

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
            'Form: 2-B',
            style: _eBld(11).copyWith(decoration: TextDecoration.underline),
          ),
        ),
        const SizedBox(height: 2),
        Center(
          child: Column(
            children: [
              Text(
                'CRIME DETAILS FORM (Part II)',
                style: _eBld(15).copyWith(decoration: TextDecoration.underline),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                'गुन्ह्यांचा तपशील नमुना (भाग २ - पीडित व मालमत्ता)',
                style: _mBld(12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Divider(color: Colors.black87, thickness: 0.8),
        const SizedBox(height: 6),

        // 5) Complainant KYC
        Text('5) Particulars of Complainant / Informant (तक्रारदार माहिती):',
            style: _eBld(9.5)),
        const SizedBox(height: 3),
        Row(
          children: [
            const SizedBox(width: 16),
            _bilingualField('Name:', 'नाव', cName, expand: true),
            const SizedBox(width: 8),
            _bilingualField('Father/Husband:', 'वडील/पती', cFather, width: 130),
            const SizedBox(width: 8),
            _bilingualField('Age:', 'वय', cAge, width: 50),
            const SizedBox(width: 8),
            _bilingualField('Sex:', 'लिंग', cSex, width: 50),
            const SizedBox(width: 8),
            _bilingualField('Mobile:', 'मोबाईल', cMob, width: 100),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            const SizedBox(width: 16),
            _bilingualField('Occupation:', 'व्यवसाय', cOcc, width: 180),
            const SizedBox(width: 12),
            _bilingualField('Address:', 'पत्ता', cAddr, expand: true),
          ],
        ),
        const SizedBox(height: 10),

        // 6) Victim KYC
        Text('6) Particulars of Victim (बळी पडलेल्या व्यक्तीची माहिती):',
            style: _eBld(9.5)),
        const SizedBox(height: 3),
        Row(
          children: [
            const SizedBox(width: 16),
            _bilingualField('Name:', 'नाव', vName, expand: true),
            const SizedBox(width: 8),
            _bilingualField('Father/Husband:', 'वडील/पती', vFather, width: 130),
            const SizedBox(width: 8),
            _bilingualField('Age:', 'वय', vAge, width: 50),
            const SizedBox(width: 8),
            _bilingualField('Sex:', 'लिंग', vSex, width: 50),
            const SizedBox(width: 8),
            _bilingualField('Mobile:', 'मोबाईल', vMob, width: 100),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            const SizedBox(width: 16),
            _bilingualField('Occupation:', 'व्यवसाय', vOcc, width: 180),
            const SizedBox(width: 12),
            _bilingualField('Address:', 'पत्ता', vAddr, expand: true),
          ],
        ),
        const SizedBox(height: 10),

        // 7) Property Stolen / Involved
        Text('7) Property Details (मालमत्ता तपशील):', style: _eBld(9.5)),
        const SizedBox(height: 3),
        Container(
          width: double.infinity,
          height: 90,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black87, width: 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            stolenProp.isNotEmpty ? stolenProp : 'मालमत्तेचे वर्णन...',
            style: stolenProp.isNotEmpty ? _valStyle(9) : _mReg(9),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _bilingualField(
                'Stolen Property Value (Rs.):', 'किंमत रु.', stolenVal,
                width: 220),
            const SizedBox(width: 24),
            _bilingualField(
                'Recovered Value (Rs.):', 'हस्तगत किंमत रु.', recoveredVal,
                width: 220),
          ],
        ),
        const SizedBox(height: 10),

        // 8) Accused / Suspects
        Text('8) Particulars of Accused / Suspects (संशयित / आरोपींची माहिती):',
            style: _eBld(9.5)),
        const SizedBox(height: 3),
        Container(
          width: double.infinity,
          height: 100,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black87, width: 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            suspects.isNotEmpty ? suspects : ' ',
            style: suspects.isNotEmpty ? _valStyle(9) : _mReg(9),
          ),
        ),
        const Spacer(),
        Align(
          alignment: Alignment.centerRight,
          child: Text('Page 2 of 3 — Form 2-B',
              style: GoogleFonts.lora(fontSize: 8.5, color: Colors.black54)),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE 3: Form 2-C (Place, Map & Evidence)
// ─────────────────────────────────────────────────────────────────────────────

Widget _pg3(Map<String, dynamic> doc) {
  final spotDesc = _v(doc, 'placeDescription', _v(doc, 'spotDescription'));
  final east = _v(doc, 'eastBoundary');
  final west = _v(doc, 'westBoundary');
  final north = _v(doc, 'northBoundary');
  final south = _v(doc, 'southBoundary');

  final panchnamaDate = _v(doc, 'panchnamaDate');
  final panchnamaTime = _v(doc, 'panchnamaTime');

  final p1Name = _v(doc, 'panch1Name');
  final p1Addr = _v(doc, 'panch1Address');
  final p1Sig = _v(doc, 'panch1Sig');

  final p2Name = _v(doc, 'panch2Name');
  final p2Addr = _v(doc, 'panch2Address');
  final p2Sig = _v(doc, 'panch2Sig');

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
            'Form: 2-C',
            style: _eBld(11).copyWith(decoration: TextDecoration.underline),
          ),
        ),
        const SizedBox(height: 2),
        Center(
          child: Column(
            children: [
              Text(
                'CRIME DETAILS FORM (Part III)',
                style: _eBld(15).copyWith(decoration: TextDecoration.underline),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                'गुन्ह्यांचा तपशील नमुना (भाग ३ - घटनास्थळ पंचनामा व सह्या)',
                style: _mBld(12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Divider(color: Colors.black87, thickness: 0.8),
        const SizedBox(height: 6),

        // 9) Spot Description & Boundaries
        Text('9) Description of Crime Spot & Boundaries (घटनास्थळ व चतुःसीमा):',
            style: _eBld(9.5)),
        const SizedBox(height: 3),
        Container(
          width: double.infinity,
          height: 100,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black87, width: 0.8),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            spotDesc.isNotEmpty ? spotDesc : 'घटनास्थळाचे सविस्तर वर्णन...',
            style: spotDesc.isNotEmpty ? _valStyle(9) : _mReg(9),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _bilingualField('East:', 'पूर्व', east, width: 160),
            const SizedBox(width: 12),
            _bilingualField('West:', 'पश्चिम', west, width: 160),
            const SizedBox(width: 12),
            _bilingualField('North:', 'उत्तर', north, width: 160),
            const SizedBox(width: 12),
            _bilingualField('South:', 'दक्षिण', south, expand: true),
          ],
        ),
        const SizedBox(height: 10),

        // 10) Panchanama Date & Time
        Row(
          children: [
            Text('10) ', style: _eBld(9.5)),
            _bilingualField(
                'Date of Panchanama:', 'पंचनामा तारीख', panchnamaDate,
                width: 180),
            const SizedBox(width: 24),
            _bilingualField('Time of Panchanama:', 'पंचनामा वेळ', panchnamaTime,
                width: 180),
          ],
        ),
        const SizedBox(height: 10),

        // 11) Panchas Table
        Text('11) Panch Witnesses (पंचांची माहिती व सह्या):',
            style: _eBld(9.5)),
        const SizedBox(height: 3),
        Table(
          border: TableBorder.all(color: Colors.black87, width: 0.8),
          columnWidths: const {
            0: FixedColumnWidth(30),
            1: FlexColumnWidth(2.5),
            2: FlexColumnWidth(3.5),
            3: FlexColumnWidth(1.8),
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
                  padding: const EdgeInsets.all(4),
                  child: Center(child: Text('१', style: _mBld(8.5))),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(p1Name,
                      style: p1Name.isNotEmpty ? _valStyle(8.5) : _mReg(8.5)),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(p1Addr,
                      style: p1Addr.isNotEmpty ? _valStyle(8.5) : _mReg(8.5)),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Center(
                    child: Text(p1Sig,
                        style: p1Sig.isNotEmpty ? _valStyle(8.5) : _mReg(8.5)),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Center(child: Text('२', style: _mBld(8.5))),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(p2Name,
                      style: p2Name.isNotEmpty ? _valStyle(8.5) : _mReg(8.5)),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(p2Addr,
                      style: p2Addr.isNotEmpty ? _valStyle(8.5) : _mReg(8.5)),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Center(
                    child: Text(p2Sig,
                        style: p2Sig.isNotEmpty ? _valStyle(8.5) : _mReg(8.5)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),

        // 12) Investigation Officer Block
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Signature of Investigation Officer', style: _eBld(9)),
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
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text('Page 3 of 3 — Form 2-C',
              style: GoogleFonts.lora(fontSize: 8.5, color: Colors.black54)),
        ),
      ],
    ),
  );
}

Future<Uint8List> generateCrimeDetailPdf(Map<String, dynamic> rawDoc) async {
  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Center(
        child: pw.Text('Crime Detail Form',
            style: const pw.TextStyle(fontSize: 12)),
      ),
    ),
  );
  return pdf.save();
}
