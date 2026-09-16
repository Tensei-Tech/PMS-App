// lib/utils/form_e_pdf.dart
//
// IMAGE-BASED PDF generation for FORM "E":
// Modus Operandi Bureau Information (मोडस ऑपरेंडी ब्युरोला पुरविण्यात यावयाची माहिती).
//
// Renders pages as native Flutter widgets offscreen and captures them at 2.0x DPI
// for 100% Devanagari/Marathi accuracy with zero edge cropping.
// The visual layout, typography, headers, and labels strictly match FormEView.

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

Future<void> previewFormEPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final fileName = 'Form_E_${DateTime.now().millisecondsSinceEpoch}.pdf';
  try {
    final bytes = await _buildImagePdf(context, doc);
    if (!context.mounted) return;
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } else {
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);
    }
  } catch (e) {
    debugPrint('Error generating image-based Form E PDF: $e');
    if (!context.mounted) return;
    try {
      final bytes = await generateFormEPdf(doc);
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (_) {}
  }
}

Future<Uint8List> _buildImagePdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final pages = [
    _buildPage1(doc),
    _buildPage2(doc),
  ];

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

// ── Exact field definitions matching FormEView ────────────────────────────────
const _fields = [
  (
    1,
    'Police Station: ',
    'पोलीस स्टेशन',
  ),
  (
    2,
    'Name and Address of Complainant: ',
    'तक्रार दाखल करणाऱ्याचे नांव व पत्ता',
  ),
  (
    3,
    'City or Village of Crime: ',
    'गुन्हा घडला ते शहर अथवा गांव ई.',
  ),
  (
    4,
    'Date of Crime: ',
    'गुन्हा घडल्याची तारीख',
  ),
  (
    5,
    'Crime No. & Section: ',
    'अप क्रमांक व कलम',
  ),
  (
    6,
    'Value of Stolen Property: ',
    'चोरीस गेलेल्या मालमत्तेची किंमत',
  ),
  (
    7,
    'Value of Recovered Property: ',
    'परत मिळालेल्या मालमत्तेची किंमत (मालमत्ता कोणाकडून व कोणत्या ठिकाणी परत मिळाली)',
  ),
  (
    8,
    'Class of Person/Property Attacked: ',
    'ज्याच्यावर हल्ला करण्यात आला त्या ईसमाचा अथवा मिळकतीचा वर्ग',
  ),
  (
    9,
    'Means used to reach Crime Scene: ',
    'गुन्ह्याच्या जागी पोहचण्याकरीता उपयोगात आणलेले साधन',
  ),
  (
    10,
    'Method used to commit crime: ',
    'गुन्हा करण्यासाठी वापरलेली रीत',
  ),
  (
    11,
    'Instrument Used: ',
    'गुन्हा करण्यासाठी वापरलेले साधन',
  ),
  (
    12,
    'Time of Day: ',
    'दिवसाचा वेळ',
  ),
  (
    13,
    'Accomplices: ',
    'साथीदार',
  ),
  (
    14,
    'Vehicle: ',
    'वाहन',
  ),
  (
    15,
    'Specific Identification Mark: ',
    'विशीष्ट निदर्शक खुण',
  ),
  (
    16,
    'Style/Modus Operandi: ',
    'शैली',
  ),
  (
    17,
    'Fabricated Story / Motive: ',
    'रचुन सांगीतलेली हकीकत, गुन्ह्याकरण्याबाबत केलेले हेतुनिवेदन',
  ),
  (
    18,
    'Brief Facts of the Case: ',
    'गुन्ह्यासंबंधीत थोडक्यात हकीकत',
  ),
];

TableRow _buildTableRow(int index, Map<String, dynamic> doc) {
  final item = _fields[index - 1];
  final enLabel = item.$2;
  final mrLabel = item.$3;
  final val = (doc['field$index'] ?? '').toString().trim();

  return TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Text(
          '$index.',
          style: GoogleFonts.lora(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (enLabel.trim().isNotEmpty)
              Text(
                enLabel,
                style: GoogleFonts.lora(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            Text(
              mrLabel,
              style: GoogleFonts.notoSansDevanagari(
                fontSize: 10,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Text(
          val.isNotEmpty ? val : '—',
          style: GoogleFonts.notoSansDevanagari(
            fontSize: 10.5,
            color: val.isNotEmpty ? const Color(0xFF0D47A1) : Colors.black45,
            fontWeight: val.isNotEmpty ? FontWeight.w500 : FontWeight.normal,
            height: 1.35,
          ),
        ),
      ),
    ],
  );
}

Widget _buildHeader() {
  return Center(
    child: Column(
      children: [
        Text(
          'FORM "E"',
          style: GoogleFonts.lora(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.black87,
                style: BorderStyle.solid,
                width: 1.0,
              ),
            ),
          ),
          child: Text(
            'मोडस ऑपरेंडी ब्युरोला पुरविण्यात',
            style: GoogleFonts.notoSansDevanagari(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.black87,
                style: BorderStyle.solid,
                width: 1.0,
              ),
            ),
          ),
          child: Text(
            'यावयाची माहिती',
            style: GoogleFonts.notoSansDevanagari(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    ),
  );
}

Widget _buildPage1(Map<String, dynamic> doc) {
  return Container(
    width: _kW,
    height: _kH,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
    color: Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        Table(
          border: TableBorder.all(color: Colors.black87, width: 1.0),
          columnWidths: const {
            0: FixedColumnWidth(40),
            1: FixedColumnWidth(270),
            2: FlexColumnWidth(1),
          },
          children: [
            for (int i = 1; i <= 9; i++) _buildTableRow(i, doc),
          ],
        ),
        const Spacer(),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Page 1 of 2',
            style: GoogleFonts.lora(fontSize: 9.5, color: Colors.black54),
          ),
        ),
      ],
    ),
  );
}

Widget _buildPage2(Map<String, dynamic> doc) {
  return Container(
    width: _kW,
    height: _kH,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
    color: Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'FORM "E" (Continued)',
              style: GoogleFonts.lora(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'Page 2 of 2',
              style: GoogleFonts.lora(fontSize: 9.5, color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Table(
          border: TableBorder.all(color: Colors.black87, width: 1.0),
          columnWidths: const {
            0: FixedColumnWidth(40),
            1: FixedColumnWidth(270),
            2: FlexColumnWidth(1),
          },
          children: [
            for (int i = 10; i <= 18; i++) _buildTableRow(i, doc),
          ],
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'तारीख: ____________',
              style: GoogleFonts.notoSansDevanagari(
                fontSize: 10.5,
                color: Colors.black87,
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 24),
                Text(
                  'तपास अंमलदार सही व हुद्दा',
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    ),
  );
}

Future<Uint8List> generateFormEPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Center(
        child: pw.Text('Form E', style: const pw.TextStyle(fontSize: 12)),
      ),
    ),
  );
  return pdf.save();
}
