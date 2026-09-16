// lib/utils/interrogation_form_pdf.dart
//
// IMAGE-BASED PDF generation for the Interrogation Form.
// Each page is rendered as a Flutter widget via an offscreen RepaintBoundary,
// captured as PNG, and assembled into a multi-page PDF using the pdf package.
// This guarantees pixel-perfect Devanagari/Marathi text rendering.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ── A4 layout constants ───────────────────────────────────────────────────────
const double _kW = 794.0;   // A4 width  at ~96 DPI
const double _kH = 1123.0;  // A4 height at ~96 DPI
const double _kM = 20.0;    // page margin
const double _kPx = 2.0;    // capture pixel ratio (2× = 1588×2246 px)

// ──────────────────────────────────────────────────────────────────────────────
// Public API — identical signatures to the previous implementation
// ──────────────────────────────────────────────────────────────────────────────

Future<void> previewInterrogationFormPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final name =
      'Interrogation_Form_${DateTime.now().millisecondsSinceEpoch}.pdf';
  try {
    final bytes = await _buildImagePdf(context, doc);
    if (!context.mounted) return;
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: name);
    } else {
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: name);
    }
  } catch (_) {
    if (!context.mounted) return;
    try {
      final bytes = await _buildImagePdf(context, doc);
      await Printing.sharePdf(bytes: bytes, filename: name);
    } catch (_) {}
  }
}

/// pw.* fallback — kept for API compatibility.
/// Full-fidelity image rendering is done via [previewInterrogationFormPdf].
Future<Uint8List> generateInterrogationFormPdf(
    Map<String, dynamic> doc) async {
  return _pwGenerate(doc);
}

// ──────────────────────────────────────────────────────────────────────────────
// Image-based PDF builder
// ──────────────────────────────────────────────────────────────────────────────

Future<Uint8List> _buildImagePdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final pageBuilders = [
    _pg1(doc),
    _pg2(doc),
    _pg3(doc),
    _pg4(doc),
    _pg5(doc),
    _pg6(doc),
    _pg7(doc),
  ];

  final pngs = <Uint8List>[];
  for (final page in pageBuilders) {
    pngs.add(await _capture(context, page));
  }

  final pdfDoc = pw.Document();
  for (final png in pngs) {
    pdfDoc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (_) => pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.contain),
    ));
  }
  return pdfDoc.save();
}

// ──────────────────────────────────────────────────────────────────────────────
// Widget → PNG via offscreen overlay
// ──────────────────────────────────────────────────────────────────────────────

Future<Uint8List> _capture(BuildContext ctx, Widget widget) async {
  final key = GlobalKey();
  final comp = Completer<Uint8List>();
  OverlayEntry? ent;

  ent = OverlayEntry(
    builder: (_) => Positioned(
      left: -(_kW + 60),
      top: 0,
      width: _kW,
      height: _kH,
      child: RepaintBoundary(
        key: key,
        child: Material(color: Colors.white, child: widget),
      ),
    ),
  );

  Overlay.of(ctx).insert(ent);

  // Allow layout + Google-font load + paint (≥2 frames + font fetch)
  await WidgetsBinding.instance.endOfFrame;
  await Future.delayed(const Duration(milliseconds: 800));

  try {
    final rb =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
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

// ──────────────────────────────────────────────────────────────────────────────
// Typography helpers
// ──────────────────────────────────────────────────────────────────────────────

const Color _kBk = Colors.black;

TextStyle _reg([double sz = 9.5]) =>
    GoogleFonts.notoSansDevanagari(fontSize: sz, color: _kBk);

TextStyle _bld([double sz = 9.5]) => GoogleFonts.notoSansDevanagari(
      fontSize: sz, fontWeight: FontWeight.bold, color: _kBk);

// ──────────────────────────────────────────────────────────────────────────────
// Border helpers
// ──────────────────────────────────────────────────────────────────────────────

const BorderSide _kBs = BorderSide(color: _kBk, width: 0.8);

BoxDecoration _bd({
  bool r = true,
  bool b = true,
  bool l = false,
  bool t = false,
}) =>
    BoxDecoration(
      border: Border(
        right:  r ? _kBs : BorderSide.none,
        bottom: b ? _kBs : BorderSide.none,
        left:   l ? _kBs : BorderSide.none,
        top:    t ? _kBs : BorderSide.none,
      ),
    );

// ──────────────────────────────────────────────────────────────────────────────
// Standard 3-column data row: srNo │ label │ value
// ──────────────────────────────────────────────────────────────────────────────

Widget _dr(String srNo, String label, String value, double h) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        width: 32, height: h,
        decoration: _bd(),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(4),
        child: Text(srNo, style: _bld()),
      ),
      Container(
        width: 170, height: h,
        decoration: _bd(),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(label, style: _bld()),
      ),
      Expanded(
        child: Container(
          height: h,
          decoration: _bd(r: false),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(value, style: _reg()),
        ),
      ),
    ],
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// Page shell — white A4 background + uniform margin
// ──────────────────────────────────────────────────────────────────────────────

Widget _shell(Widget body) => SizedBox(
      width: _kW,
      height: _kH,
      child: Material(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(_kM),
          child: body,
        ),
      ),
    );

// ── Outer bordered table container ───────────────────────────────────────────

Widget _outerTable(List<Widget> rows) => Container(
      decoration:
          BoxDecoration(border: Border.all(color: _kBk, width: 0.8)),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
    );

// ── Doc value helper ──────────────────────────────────────────────────────────

String _gv(Map<String, dynamic> d, String k, [String fb = '']) {
  final v = d[k]?.toString().trim() ?? '';
  return v.isEmpty ? fb : v;
}

/// Extracts an ordered string list from [doc], trying [primary] key first,
/// then falling back to [fallback] with optional skip/take.
List<String> _lst(
  Map<String, dynamic> doc,
  String primary,
  String fallback,
  int take,
  int skip,
) {
  if (doc[primary] is List) {
    return List<String>.from(
        (doc[primary] as List).map((e) => e?.toString() ?? ''));
  }
  if (doc[fallback] is List) {
    return List<String>.from((doc[fallback] as List)
        .skip(skip)
        .take(take)
        .map((e) => e?.toString() ?? ''));
  }
  return [];
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE 1 — Header + Rows 1-10
// ══════════════════════════════════════════════════════════════════════════════

Widget _pg1(Map<String, dynamic> doc) {
  final ps       = _gv(doc, 'ps');
  final gurNo    = _gv(doc, 'gurNo');
  final kalam    = _gv(doc, 'kalam');
  final ioName   = _gv(doc, 'ioName');
  final accused  = _gv(doc, 'accusedName');
  final arrestDt = _gv(doc, 'arrestDateTime');
  final dob      = _gv(doc, 'dobPlaceAge');
  final idMarks  = _gv(doc, 'idMarks');
  final address  = _gv(doc, 'address');
  final dharma   = _gv(doc, 'dharma');
  final jati     = _gv(doc, 'jati');

  final phys = doc['physicalTable'] is Map
      ? Map<String, dynamic>.from(doc['physicalTable'] as Map)
      : <String, dynamic>{};
  String pv(String k) => phys[k]?.toString().trim() ?? '';

  // ── Helper: one row in the top (140-wide label) section ────────────────────
  Widget smallRow(String n, String lbl, Widget val, double h) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 32, height: h, decoration: _bd(),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(4),
          child: Text(n, style: _bld()),
        ),
        Container(
          width: 140, height: h, decoration: _bd(),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(lbl, style: _bld(8.5)),
        ),
        Expanded(
          child: Container(
            height: h, decoration: _bd(r: false),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: val,
          ),
        ),
      ],
    );
  }

  // ── Helper: one row in the physical-attributes grid ─────────────────────────
  Widget physPairRow(List<(String, String)> pairs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: pairs
          .map((p) => Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      height: 20, width: 44, decoration: _bd(),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(p.$1,
                          style: _bld(7.5),
                          overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      child: Container(
                        height: 20, decoration: _bd(),
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        alignment: Alignment.centerLeft,
                        child: Text(p.$2,
                            style: _reg(7.5),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  return _shell(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Title ─────────────────────────────────────────────────────────
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('-० चौकशी अहवाल ०-', style: _bld(13)),
              const SizedBox(height: 2),
              Text('स्थानिक गुन्हे शाखा,उस्मानाबाद', style: _bld(11)),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ── Main outer bordered box ────────────────────────────────────────
        Container(
          decoration: BoxDecoration(border: Border.all(color: _kBk, width: 0.8)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Rows 1-6 (left) + Photo box (right) ──────────────────────
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          smallRow('१', 'पोलीस ठाणे',
                              Text(ps, style: _reg()), 26),
                          smallRow(
                            '२',
                            'गुरनं / कलम',
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('गुरनं - $gurNo', style: _reg()),
                                Text('कलम - $kalam', style: _reg()),
                              ],
                            ),
                            40,
                          ),
                          smallRow('३',
                              'तपासी अधिका-याचे नांव व हुद्दा',
                              Text(ioName, style: _reg()), 28),
                          smallRow('४',
                              'गुन्हेगाराचे नांव व टोपन नांव',
                              Text(accused, style: _reg()), 28),
                          smallRow('५', 'अटक तारीख व वेळ',
                              Text(arrestDt, style: _reg()), 24),
                          smallRow('६', 'जन्म तारीख,जन्माठिकाण,वय',
                              Text(dob, style: _reg()), 28),
                        ],
                      ),
                    ),
                    // Photo box
                    Container(
                      width: 155,
                      decoration: _bd(l: true, b: false, r: false),
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('आरोपींचा फोटो', style: _bld()),
                    ),
                  ],
                ),
              ),

              // ── Row 7: Physical attributes ────────────────────────────────
              Container(
                decoration: _bd(r: false, b: false, l: false, t: true),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Row 7 header
                    Row(children: [
                      Container(
                        width: 32, height: 20,
                        decoration: _bd(b: false),
                        alignment: Alignment.center,
                        child: Text('७', style: _bld()),
                      ),
                      Expanded(
                        child: Container(
                          height: 20,
                          decoration: _bd(r: false, b: false),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text('चेहरे पट्टी माहीती', style: _bld()),
                        ),
                      ),
                    ]),
                    // Physical attribute grid
                    physPairRow([
                      ('उंची', pv('उंची')),
                      ('बांधा', pv('बांधा')),
                      ('केस', pv('केस')),
                      ('भुवया', pv('भुवया')),
                    ]),
                    physPairRow([
                      ('कपाळ', pv('कपाळ')),
                      ('डोळे', pv('डोळे')),
                      ('दृष्टी', pv('दृष्टी')),
                      ('नाक', pv('नाक')),
                    ]),
                    physPairRow([
                      ('ओंट', pv('ओंट')),
                      ('छाती', pv('छाती')),
                      ('बोटे', pv('बोटे')),
                      ('हनुवटी', pv('हनुवटी')),
                    ]),
                    physPairRow([
                      ('कान', pv('कान')),
                      ('चेहरा', pv('चेहरा')),
                      ('वर्ण', pv('वर्ण')),
                      ('दाढी', pv('दाढी')),
                    ]),
                    physPairRow([
                      ('मिशा', pv('मिशा')),
                      ('भाषा', pv('भाषा')),
                      ('गाल', pv('गाल')),
                      ('पोशाख', pv('पोशाख')),
                    ]),
                    physPairRow([
                      ('व्यसन', pv('व्यसन')),
                      ('', ''),
                      ('', ''),
                      ('', ''),
                    ]),
                  ],
                ),
              ),

              // ── Rows 8-10 ─────────────────────────────────────────────────
              _dr('८',
                  'ओळखोच्या खुणा ( तीळ,\nमार,जखम,गोंदन,अपंगत्व )',
                  idMarks, 46),
              _dr('९',
                  'सध्याचा मुळ पत्ता घर क्र,इमारतीचे नांव,परीसराचे नांव,रस्ता,शहर राज्य ,मोबाईल नंबर',
                  address, 52),
              // Row 10 (dharma + jati inline)
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 32, height: 32, decoration: _bd(),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(4),
                    child: Text('१०', style: _bld()),
                  ),
                  Container(
                    width: 170, height: 32, decoration: _bd(),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Text('धर्म/जात', style: _bld()),
                  ),
                  Expanded(
                    child: Container(
                      height: 32, decoration: _bd(r: false),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(children: [
                        Text('धर्म - $dharma', style: _reg()),
                        const SizedBox(width: 24),
                        Text('जात - $jati', style: _reg()),
                      ]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE 2 — Rows 11-15
// ══════════════════════════════════════════════════════════════════════════════

Widget _pg2(Map<String, dynamic> doc) {
  final rows = _lst(doc, 'page2Rows', 'familyRows', 5, 0);
  String p(int i) => i < rows.length ? rows[i] : '';

  return _shell(_outerTable([
    _dr('११', 'व्यवसाय/काम यापुर्वीचा व्यवसाय', p(0), 140),
    _dr('१२', 'वडीलाचे /आईचे नांव,वय, पत्ता,व्यवसाय,फोन व इतर आवश्यक माहिती', p(1), 140),
    _dr('१३', 'मुले/मुलीचे नांव,वय,पत्ता, व्यवसाय,फोन व इतर आवश्यक माहीती', p(2), 140),
    _dr('१४', 'भावाचे/बहीणींचे नांव ,वय, पत्ता,व्यवसाय,फोन व इतर आवश्यक माहीती', p(3), 140),
    _dr('१५', 'बहीण/ भाऊजींचे नांव ,वय, पत्ता,व्यवसाय,फोन व इतर आवश्यक माहीती', p(4), 140),
  ]));
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE 3 — Rows 16-21
// ══════════════════════════════════════════════════════════════════════════════

Widget _pg3(Map<String, dynamic> doc) {
  final rows = _lst(doc, 'page3Rows', 'familyRows', 6, 5);
  String p(int i) => i < rows.length ? rows[i] : '';

  return _shell(_outerTable([
    _dr('१६', 'सासु/सासऱ्याचे नांव,वय,पत्ता, व्यवसाय,फोन व इतर आवश्यक माहीती', p(0), 115),
    _dr('१७', 'मेव्हणा/मेव्हणींची नावे वय, पत्ता, व्यवसाय,फोन व इतर आवश्यक माहीती', p(1), 115),
    _dr('१८', 'मामा/मामीचे नांव ,वय, पत्ता,व्यवसाय,फोन व इतर आवश्यक माहीती', p(2), 115),
    _dr('१९', 'काका/ मावशींचे नांव ,वय, पत्ता,व्यवसाय,फोन व इतर आवश्यक माहीती', p(3), 115),
    _dr('२०', 'चुलता/चुलतीचे नांव ,वय, पत्ता,व्यवसाय,फोन व इतर आवश्यक माहीती', p(4), 115),
    _dr('२१', 'आत्याचे / मामाचे नांव ,वय, पत्ता,व्यवसाय,फोन व इतर आवश्यक माहीती', p(5), 115),
  ]));
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE 4 — Rows 22-30
// ══════════════════════════════════════════════════════════════════════════════

Widget _pg4(Map<String, dynamic> doc) {
  final rows = _lst(doc, 'page4Rows', 'idHistoryRows', 9, 0);
  String p(int i) => i < rows.length ? rows[i] : '';

  return _shell(_outerTable([
    _dr('२२', 'शिक्षण/शाळा/ कॉलेज (पत्ता) तसेच संगणकाचे ज्ञान आहे काय?', p(0), 65),
    _dr('२३', 'नोकरीस असल्यास पुर्वीचे कार्यालयाचा पत्ता', p(1), 55),
    _dr('२४', 'आधारकार्ड क्रमांक', p(2), 36),
    _dr('२५', 'पॅनकार्ड क्रमांक', p(3), 36),
    _dr('२६', 'वाहन परवाना', p(4), 36),
    _dr('२७', 'रेशन कार्ड', p(5), 36),
    _dr('२८', 'मालमत्ता (अंदाजे)', p(6), 55),
    _dr('२९',
        'यापुर्वी झालेली शिक्षा (पोलीस ठाणे,पत्ता गु.नो.क्र,कलम साथीदार,फरार आरोपी )',
        p(7), 95),
    _dr('३०',
        'या गुन्ह्यातील आरोपींचे साथीदारांची नावे पुर्ण पत्ता मोबाईल नंबर सह',
        p(8), 140),
  ]));
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE 5 — Rows 31-36
// ══════════════════════════════════════════════════════════════════════════════

Widget _pg5(Map<String, dynamic> doc) {
  final rows = _lst(doc, 'page5Rows', 'crimeRows', 6, 0);
  String p(int i) => i < rows.length ? rows[i] : '';

  return _shell(_outerTable([
    _dr('३१', 'बसण्या - उठण्याच्या जागा', p(0), 110),
    _dr('३२',
        'नमुद आरोपीस गुन्ह्याचे ठिकाणची (स्थळ,ईमारत) याबाबत माहीती मिळालेली उगमस्थाने (रेखी ) (गुन्हा करण्याचे स्थळा बाबत माहीती कोठून व कशी मिळवली)',
        p(1), 125),
    _dr('३३', 'गुन्हा करतेवेळी आरोपी यांनी वापरलेली वाहने', p(2), 110),
    _dr('३४',
        'गुन्हा करते वेळी वापरलेली हत्यारे (काठी,कटवणी,पक्कड, पाने,कटर,गॅस कटर, व इतर )',
        p(3), 125),
    _dr('३५', 'गुन्हा करते वेळी येण्याची दिशा व रस्ते', p(4), 125),
    _dr('३६', 'गुन्हा करुन जातेवेळीची दिशा व रस्ते', p(5), 125),
  ]));
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE 6 — Rows 37-40 + IO Signature block
// ══════════════════════════════════════════════════════════════════════════════

Widget _pg6(Map<String, dynamic> doc) {
  final rows = _lst(doc, 'page6Rows', 'crimeRows', 4, 6);
  String p(int i) => i < rows.length ? rows[i] : '';

  final ioName    = _gv(doc, 'ioSigName');
  final ioRank    = _gv(doc, 'ioSigRank');
  final ioCode    = _gv(doc, 'ioSigCode');
  final ioPosting = _gv(doc, 'ioSigPosting');

  return _shell(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _outerTable([
          _dr('३७', 'गुन्हा करण्याची पध्दत', p(0), 140),
          _dr('३८',
              'गुन्ह्यातील चोरलेल्या मुद्देमालाबाबत आरोपीने सांगितलेली माहीती\n(साथीदार यांना वाटप,विक्री तसेच ईतर प्रकारे विल्हेवाट संपूर्ण हकिकत)',
              p(1), 180),
          _dr('३९',
              'आरोपीस ओळखणारे पोलीस अधिकारी/अंमलदार,पोलीस पाटील',
              p(2), 90),
          _dr('४०', 'Advisorries', p(3), 110),
        ]),
        const SizedBox(height: 36),
        // IO Signature
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Text('तपासणी अधिकाऱ्याची सही', style: _bld())),
                const SizedBox(height: 16),
                Text('नांव :- $ioName', style: _reg()),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(
                      child: Text('पदनाम :- $ioRank', style: _reg())),
                  Text('कोड नंबर :- $ioCode', style: _reg()),
                ]),
                const SizedBox(height: 6),
                Text('नेमणुक :- $ioPosting', style: _reg()),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// PAGE 7 — Additional detail for Row 37
// ══════════════════════════════════════════════════════════════════════════════

Widget _pg7(Map<String, dynamic> doc) {
  final a37 = _gv(doc, 'additionalPoint37');
  final text = a37.isNotEmpty ? a37 : _gv(doc, 'additional37');

  return _shell(
    Container(
      decoration:
          BoxDecoration(border: Border.all(color: _kBk, width: 0.8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            decoration: _bd(r: false, b: true, l: false, t: false),
            padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Column(children: [
              Text(
                'मुद्दा क्रमांक ३७ ची अधिक माहिती',
                style: _bld(11)
                    .copyWith(decoration: TextDecoration.underline),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Text(
                'गुन्हा करण्याची पध्दत,रेखी,कार्यप्रणाली, मालाची विल्हेवाट व इतर उपयुक्त माहिती:-',
                style: _bld(9),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              text,
              style: _reg().copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// pw.* fallback — kept for generateInterrogationFormPdf() API compatibility
// (already fixed: uses height: N instead of BoxConstraints(minHeight: N))
// ══════════════════════════════════════════════════════════════════════════════

Future<Uint8List> _pwGenerate(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final devanagari = await PdfGoogleFonts.notoSansDevanagariRegular();
  final devanagariBold = await PdfGoogleFonts.notoSansDevanagariBold();

  final regular = pw.TextStyle(font: devanagari, fontSize: 9.5);
  final bold = pw.TextStyle(
    font: devanagariBold,
    fontSize: 9.5,
    fontWeight: pw.FontWeight.bold,
  );
  final headerTitle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 13,
    fontWeight: pw.FontWeight.bold,
  );
  final headerSub = pw.TextStyle(
    font: devanagariBold,
    fontSize: 11,
    fontWeight: pw.FontWeight.bold,
  );

  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  const border = pw.BorderSide(color: PdfColors.black, width: 0.8);

  // Fixed height is used instead of minHeight constraints to avoid
  // "BoxConstraints forces an infinite height" in the pdf package when
  // FlexColumnWidth is combined with BoxConstraints(minHeight: N).
  pw.Widget cellCenter(String text, {double height = 36}) {
    return pw.SizedBox(
      height: height,
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text(text, style: bold),
        ),
      ),
    );
  }

  pw.Widget cellLeft(
    String text, {
    double height = 36,
    bool isBold = false,
  }) {
    return pw.SizedBox(
      height: height,
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: pw.Align(
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(text, style: isBold ? bold : regular),
        ),
      ),
    );
  }

  pw.TableRow buildTableDataRow({
    required String srNo,
    required String label,
    required String value,
    double height = 40,
  }) {
    return pw.TableRow(
      children: [
        cellCenter(srNo, height: height),
        cellLeft(label, height: height, isBold: true),
        cellLeft(value, height: height),
      ],
    );
  }

  // ── PAGE 1 ─────────────────────────────────────────────────────────────────
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
      build: (pw.Context context) {
        final ps = v('ps');
        final gurNo = v('gurNo');
        final kalam = v('kalam');
        final ioName = v('ioName');
        final accusedName = v('accusedName');
        final arrestDt = v('arrestDateTime');
        final dobPlaceAge = v('dobPlaceAge');
        final idMarks = v('idMarks');
        final address = v('address');
        final dharma = v('dharma');
        final jati = v('jati');

        final phys = doc['physicalTable'] is Map
            ? Map<String, dynamic>.from(doc['physicalTable'] as Map)
            : <String, dynamic>{};
        String pVal(String key) => phys[key]?.toString().trim() ?? '';

        pw.TableRow chehareTableRow(List<(String, String)> cols) {
          return pw.TableRow(
            children: [
              for (final col in cols) ...[
                pw.Container(
                  height: 22,
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 2),
                  child: pw.Text(col.$1, style: bold),
                ),
                pw.Container(
                  height: 22,
                  alignment: pw.Alignment.centerLeft,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                  child: pw.Text(col.$2, style: regular),
                ),
              ],
            ],
          );
        }

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('-० चौकशी अहवाल ०-', style: headerTitle),
                  pw.SizedBox(height: 2),
                  pw.Text('स्थानिक गुन्हे शाखा,उस्मानाबाद',
                      style: headerSub),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                    color: PdfColors.black, width: border.width),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        flex: 5,
                        child: pw.Table(
                          border: const pw.TableBorder(
                            horizontalInside: border,
                            verticalInside: border,
                          ),
                          columnWidths: const {
                            0: pw.FixedColumnWidth(32),
                            1: pw.FixedColumnWidth(140),
                            2: pw.FlexColumnWidth(1),
                          },
                          children: [
                            pw.TableRow(children: [
                              cellCenter('१', height: 28),
                              cellLeft('पोलीस ठाणे', height: 28, isBold: true),
                              cellLeft(ps, height: 28),
                            ]),
                            pw.TableRow(children: [
                              cellCenter('२', height: 44),
                              cellLeft('गुरनं / कलम', height: 44, isBold: true),
                              pw.SizedBox(
                                height: 44,
                                child: pw.Padding(
                                  padding: const pw.EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 4),
                                  child: pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Text('गुरनं - $gurNo', style: regular),
                                      pw.Text('कलम - $kalam', style: regular),
                                    ],
                                  ),
                                ),
                              ),
                            ]),
                            pw.TableRow(children: [
                              cellCenter('३', height: 32),
                              cellLeft('तपासी अधिका-याचे नांव व हुद्दा',
                                  height: 32, isBold: true),
                              cellLeft(ioName, height: 32),
                            ]),
                            pw.TableRow(children: [
                              cellCenter('४', height: 32),
                              cellLeft('गुन्हेगाराचे नांव व टोपन नांव',
                                  height: 32, isBold: true),
                              cellLeft(accusedName, height: 32),
                            ]),
                            pw.TableRow(children: [
                              cellCenter('५', height: 28),
                              cellLeft('अटक तारीख व वेळ',
                                  height: 28, isBold: true),
                              cellLeft(arrestDt, height: 28),
                            ]),
                            pw.TableRow(children: [
                              cellCenter('६', height: 32),
                              cellLeft('जन्म तारीख,जन्माठिकाण,वय',
                                  height: 32, isBold: true),
                              cellLeft(dobPlaceAge, height: 32),
                            ]),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Container(
                          height: 190,
                          decoration: const pw.BoxDecoration(
                              border: pw.Border(left: border)),
                          padding: const pw.EdgeInsets.only(top: 8),
                          alignment: pw.Alignment.topCenter,
                          child: pw.Text('आरोपींचा फोटो', style: bold),
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    decoration: const pw.BoxDecoration(
                        border: pw.Border(top: border)),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        pw.Table(
                          border: const pw.TableBorder(
                            bottom: border,
                            verticalInside: border,
                          ),
                          columnWidths: const {
                            0: pw.FixedColumnWidth(32),
                            1: pw.FlexColumnWidth(1),
                          },
                          children: [
                            pw.TableRow(children: [
                              pw.Container(
                                  height: 22,
                                  alignment: pw.Alignment.center,
                                  child: pw.Text('७', style: bold)),
                              pw.Container(
                                height: 22,
                                alignment: pw.Alignment.centerLeft,
                                padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 6),
                                child:
                                    pw.Text('चेहरे पट्टी माहीती', style: bold),
                              ),
                            ]),
                          ],
                        ),
                        pw.Table(
                          border: const pw.TableBorder(
                            horizontalInside: border,
                            verticalInside: border,
                          ),
                          columnWidths: const {
                            0: pw.FixedColumnWidth(46),
                            1: pw.FlexColumnWidth(1),
                            2: pw.FixedColumnWidth(46),
                            3: pw.FlexColumnWidth(1),
                            4: pw.FixedColumnWidth(46),
                            5: pw.FlexColumnWidth(1),
                            6: pw.FixedColumnWidth(46),
                            7: pw.FlexColumnWidth(1),
                          },
                          children: [
                            chehareTableRow([
                              ('उंची', pVal('उंची')),
                              ('बांधा', pVal('बांधा')),
                              ('केस', pVal('केस')),
                              ('भुवया', pVal('भुवया')),
                            ]),
                            chehareTableRow([
                              ('कपाळ', pVal('कपाळ')),
                              ('डोळे', pVal('डोळे')),
                              ('दृष्टी', pVal('दृष्टी')),
                              ('नाक', pVal('नाक')),
                            ]),
                            chehareTableRow([
                              ('ओंट', pVal('ओंट')),
                              ('छाती', pVal('छाती')),
                              ('बोटे', pVal('बोटे')),
                              ('हनुवटी', pVal('हनुवटी')),
                            ]),
                            chehareTableRow([
                              ('कान', pVal('कान')),
                              ('चेहरा', pVal('चेहरा')),
                              ('वर्ण', pVal('वर्ण')),
                              ('दाढी', pVal('दाढी')),
                            ]),
                            chehareTableRow([
                              ('मिशा', pVal('मिशा')),
                              ('भाषा', pVal('भाषा')),
                              ('गाल', pVal('गाल')),
                              ('पोशाख', pVal('पोशाख')),
                            ]),
                            chehareTableRow([
                              ('व्यसन', pVal('व्यसन')),
                              ('', ''),
                              ('', ''),
                              ('', ''),
                            ]),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.Table(
                    border: const pw.TableBorder(
                      top: border,
                      horizontalInside: border,
                      verticalInside: border,
                    ),
                    columnWidths: const {
                      0: pw.FixedColumnWidth(32),
                      1: pw.FixedColumnWidth(170),
                      2: pw.FlexColumnWidth(1),
                    },
                    children: [
                      pw.TableRow(children: [
                        cellCenter('८', height: 48),
                        cellLeft(
                            'ओळखोच्या खुणा ( तीळ,\nमार,जखम,गोंदन,अपंगत्व )',
                            height: 48, isBold: true),
                        cellLeft(idMarks, height: 48),
                      ]),
                      pw.TableRow(children: [
                        cellCenter('९', height: 56),
                        cellLeft(
                            'सध्याचा मुळ पत्ता घर क्र,इमारतीचे नांव,परीसराचे नांव,रस्ता,शहर राज्य ,मोबाईल नंबर',
                            height: 56, isBold: true),
                        cellLeft(address, height: 56),
                      ]),
                      pw.TableRow(children: [
                        cellCenter('१०', height: 36),
                        cellLeft('धर्म/जात', height: 36, isBold: true),
                        pw.SizedBox(
                          height: 36,
                          child: pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: pw.Align(
                              alignment: pw.Alignment.centerLeft,
                              child: pw.Row(children: [
                                pw.Text('धर्म - $dharma', style: regular),
                                pw.SizedBox(width: 24),
                                pw.Text('जात - $jati', style: regular),
                              ]),
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  // ── PAGE 2 ─────────────────────────────────────────────────────────────────
  final page2List = doc['page2Rows'] is List
      ? (doc['page2Rows'] as List).map((e) => e?.toString() ?? '').toList()
      : (doc['familyRows'] is List
          ? (doc['familyRows'] as List)
              .take(5)
              .map((e) => e?.toString() ?? '')
              .toList()
          : <String>[]);
  String p2Val(int idx) => idx < page2List.length ? page2List[idx] : '';

  pdf.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
    build: (pw.Context context) {
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.black, width: border.width),
        columnWidths: const {
          0: pw.FixedColumnWidth(32),
          1: pw.FixedColumnWidth(170),
          2: pw.FlexColumnWidth(1),
        },
        children: [
          buildTableDataRow(srNo: '११', label: 'व्यवसाय/काम यापुर्वीचा व्यवसाय', value: p2Val(0), height: 140),
          buildTableDataRow(srNo: '१२', label: 'वडीलाचे /आईचे नांव,वय, पत्ता,व्यवसाय,फोन व इतर आवश्यक माहिती', value: p2Val(1), height: 140),
          buildTableDataRow(srNo: '१३', label: 'मुले/मुलीचे नांव,वय,पत्ता, व्यवसाय,फोन व इतर आवश्यक माहीती', value: p2Val(2), height: 140),
          buildTableDataRow(srNo: '१४', label: 'भावाचे/बहीणींचे नांव ,वय, पत्ता,व्यवसाय,फोन व इतर आवश्यक माहीती', value: p2Val(3), height: 140),
          buildTableDataRow(srNo: '१५', label: 'बहीण/ भाऊजींचे नांव ,वय, पत्ता,व्यवसाय,फोन व इतर आवश्यक माहीती', value: p2Val(4), height: 140),
        ],
      );
    },
  ));

  // ── PAGE 3 ─────────────────────────────────────────────────────────────────
  final page3List = doc['page3Rows'] is List
      ? (doc['page3Rows'] as List).map((e) => e?.toString() ?? '').toList()
      : (doc['familyRows'] is List
          ? (doc['familyRows'] as List)
              .skip(5)
              .take(6)
              .map((e) => e?.toString() ?? '')
              .toList()
          : <String>[]);
  String p3Val(int idx) => idx < page3List.length ? page3List[idx] : '';

  pdf.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
    build: (pw.Context context) {
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.black, width: border.width),
        columnWidths: const {
          0: pw.FixedColumnWidth(32),
          1: pw.FixedColumnWidth(170),
          2: pw.FlexColumnWidth(1),
        },
        children: [
          buildTableDataRow(srNo: '१६', label: 'सासु/सासऱ्याचे नांव,वय,पत्ता, व्यवसाय,फोन व इतर आवश्यक माहीती', value: p3Val(0), height: 115),
          buildTableDataRow(srNo: '१७', label: 'मेव्हणा/मेव्हणींची नावे वय, पत्ता, व्यवसाय,फोन व इतर आवश्यक माहीती', value: p3Val(1), height: 115),
          buildTableDataRow(srNo: '१८', label: 'मामा/मामीचे नांव ,वय, पत्ता,व्यवसाय,फोन व इतर आवश्यक माहीती', value: p3Val(2), height: 115),
          buildTableDataRow(srNo: '१९', label: 'काका/ मावशींचे नांव ,वय, पत्ता,व्यवसाय,फोन व इतर आवश्यक माहीती', value: p3Val(3), height: 115),
          buildTableDataRow(srNo: '२०', label: 'चुलता/चुलतीचे नांव ,वय, पत्ता,व्यवसाय,फोन व इतर आवश्यक माहीती', value: p3Val(4), height: 115),
          buildTableDataRow(srNo: '२१', label: 'आत्याचे / मामाचे नांव ,वय, पत्ता,व्यवसाय,फोन व इतर आवश्यक माहीती', value: p3Val(5), height: 115),
        ],
      );
    },
  ));

  // ── PAGE 4 ─────────────────────────────────────────────────────────────────
  final page4List = doc['page4Rows'] is List
      ? (doc['page4Rows'] as List).map((e) => e?.toString() ?? '').toList()
      : (doc['idHistoryRows'] is List
          ? (doc['idHistoryRows'] as List)
              .map((e) => e?.toString() ?? '')
              .toList()
          : <String>[]);
  String p4Val(int idx) => idx < page4List.length ? page4List[idx] : '';

  pdf.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
    build: (pw.Context context) {
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.black, width: border.width),
        columnWidths: const {
          0: pw.FixedColumnWidth(32),
          1: pw.FixedColumnWidth(170),
          2: pw.FlexColumnWidth(1),
        },
        children: [
          buildTableDataRow(srNo: '२२', label: 'शिक्षण/शाळा/ कॉलेज (पत्ता) तसेच संगणकाचे ज्ञान आहे काय?', value: p4Val(0), height: 65),
          buildTableDataRow(srNo: '२३', label: 'नोकरीस असल्यास पुर्वीचे कार्यालयाचा पत्ता', value: p4Val(1), height: 55),
          buildTableDataRow(srNo: '२४', label: 'आधारकार्ड क्रमांक', value: p4Val(2), height: 36),
          buildTableDataRow(srNo: '२५', label: 'पॅनकार्ड क्रमांक', value: p4Val(3), height: 36),
          buildTableDataRow(srNo: '२६', label: 'वाहन परवाना', value: p4Val(4), height: 36),
          buildTableDataRow(srNo: '२७', label: 'रेशन कार्ड', value: p4Val(5), height: 36),
          buildTableDataRow(srNo: '२८', label: 'मालमत्ता (अंदाजे)', value: p4Val(6), height: 55),
          buildTableDataRow(srNo: '२९', label: 'यापुर्वी झालेली शिक्षा (पोलीस ठाणे,पत्ता गु.नो.क्र,कलम साथीदार,फरार आरोपी )', value: p4Val(7), height: 95),
          buildTableDataRow(srNo: '३०', label: 'या गुन्ह्यातील आरोपींचे साथीदारांची नावे पुर्ण पत्ता मोबाईल नंबर सह', value: p4Val(8), height: 140),
        ],
      );
    },
  ));

  // ── PAGE 5 ─────────────────────────────────────────────────────────────────
  final page5List = doc['page5Rows'] is List
      ? (doc['page5Rows'] as List).map((e) => e?.toString() ?? '').toList()
      : (doc['crimeRows'] is List
          ? (doc['crimeRows'] as List).map((e) => e?.toString() ?? '').toList()
          : <String>[]);
  String p5Val(int idx) => idx < page5List.length ? page5List[idx] : '';

  pdf.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
    build: (pw.Context context) {
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.black, width: border.width),
        columnWidths: const {
          0: pw.FixedColumnWidth(32),
          1: pw.FixedColumnWidth(170),
          2: pw.FlexColumnWidth(1),
        },
        children: [
          buildTableDataRow(srNo: '३१', label: 'बसण्या - उठण्याच्या जागा', value: p5Val(0), height: 110),
          buildTableDataRow(srNo: '३२', label: 'नमुद आरोपीस गुन्ह्याचे ठिकाणची (स्थळ,ईमारत) याबाबत माहीती मिळालेली उगमस्थाने (रेखी ) (गुन्हा करण्याचे स्थळा बाबत माहीती कोठून व कशी मिळवली)', value: p5Val(1), height: 125),
          buildTableDataRow(srNo: '३३', label: 'गुन्हा करतेवेळी आरोपी यांनी वापरलेली वाहने', value: p5Val(2), height: 110),
          buildTableDataRow(srNo: '३४', label: 'गुन्हा करते वेळी वापरलेली हत्यारे (काठी,कटवणी,पक्कड, पाने,कटर,गॅस कटर, व इतर )', value: p5Val(3), height: 125),
          buildTableDataRow(srNo: '३५', label: 'गुन्हा करते वेळी येण्याची दिशा व रस्ते', value: p5Val(4), height: 125),
          buildTableDataRow(srNo: '३६', label: 'गुन्हा करुन जातेवेळीची दिशा व रस्ते', value: p5Val(5), height: 125),
        ],
      );
    },
  ));

  // ── PAGE 6 ─────────────────────────────────────────────────────────────────
  final page6List = doc['page6Rows'] is List
      ? (doc['page6Rows'] as List).map((e) => e?.toString() ?? '').toList()
      : (doc['crimeRows'] is List
          ? (doc['crimeRows'] as List)
              .skip(6)
              .take(4)
              .map((e) => e?.toString() ?? '')
              .toList()
          : <String>[]);
  String p6Val(int idx) => idx < page6List.length ? page6List[idx] : '';

  pdf.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
    build: (pw.Context context) {
      final ioName    = v('ioSigName');
      final ioRank    = v('ioSigRank');
      final ioCode    = v('ioSigCode');
      final ioPosting = v('ioSigPosting');

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: border.width),
            columnWidths: const {
              0: pw.FixedColumnWidth(32),
              1: pw.FixedColumnWidth(170),
              2: pw.FlexColumnWidth(1),
            },
            children: [
              buildTableDataRow(srNo: '३७', label: 'गुन्हा करण्याची पध्दत', value: p6Val(0), height: 140),
              buildTableDataRow(srNo: '३८', label: 'गुन्ह्यातील चोरलेल्या मुद्देमालाबाबत आरोपीने सांगितलेली माहीती\n(साथीदार यांना वाटप,विक्री तसेच ईतर प्रकारे विल्हेवाट संपूर्ण हकिकत)', value: p6Val(1), height: 180),
              buildTableDataRow(srNo: '३९', label: 'आरोपीस ओळखणारे पोलीस अधिकारी/अंमलदार,पोलीस पाटील', value: p6Val(2), height: 90),
              buildTableDataRow(srNo: '४०', label: 'Advisorries', value: p6Val(3), height: 110),
            ],
          ),
          pw.SizedBox(height: 36),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 260,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(child: pw.Text('तपासणी अधिकाऱ्याची सही', style: bold)),
                  pw.SizedBox(height: 16),
                  pw.Text('नांव :- $ioName', style: regular),
                  pw.SizedBox(height: 6),
                  pw.Row(children: [
                    pw.Expanded(child: pw.Text('पदनाम :- $ioRank', style: regular)),
                    pw.Text('कोड नंबर :- $ioCode', style: regular),
                  ]),
                  pw.SizedBox(height: 6),
                  pw.Text('नेमणुक :- $ioPosting', style: regular),
                ],
              ),
            ),
          ),
        ],
      );
    },
  ));

  // ── PAGE 7 ─────────────────────────────────────────────────────────────────
  final additional37 = v('additionalPoint37', v('additional37'));

  pdf.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
    build: (pw.Context context) {
      return pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: border.width),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: border)),
              padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              child: pw.Column(children: [
                pw.Text(
                  'मुद्दा क्रमांक ३७ ची अधिक माहिती',
                  style: headerSub.copyWith(
                      decoration: pw.TextDecoration.underline),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'गुन्हा करण्याची पध्दत,रेखी,कार्यप्रणाली, मालाची विल्हेवाट व इतर उपयुक्त माहिती:-',
                  style: bold.copyWith(fontSize: 9),
                  textAlign: pw.TextAlign.center,
                ),
              ]),
            ),
            pw.SizedBox(
              height: 650,
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(10),
                child: pw.Align(
                  alignment: pw.Alignment.topLeft,
                  child: pw.Text(additional37,
                      style: regular.copyWith(lineSpacing: 2)),
                ),
              ),
            ),
          ],
        ),
      );
    },
  ));

  return pdf.save();
}
