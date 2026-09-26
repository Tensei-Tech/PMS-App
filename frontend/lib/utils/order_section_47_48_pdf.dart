import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'form_image_pdf_helper.dart';
import 'marathi_text_renderer.dart';
import 'pdf_font_cache.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Font Caching & Preloading
// ──────────────────────────────────────────────────────────────────────────────

pw.Font? _cachedDevanagariRegular;
pw.Font? _cachedDevanagariBold;

Future<void> preloadOrderSection4748PdfFonts() async {
  try {
    _cachedDevanagariRegular ??= await PdfFontCache.devanagariRegular();
    _cachedDevanagariBold ??= await PdfFontCache.devanagariBold();
  } catch (_) {}
}

const _kInkColor = Color(0xFF0D47A1);
final _kPdfInkColor = PdfColor.fromHex('#0D47A1');

// ──────────────────────────────────────────────────────────────────────────────
// Public API: Image-Based A4 PDF Export (Matches On-Screen Layout 1:1)
// ──────────────────────────────────────────────────────────────────────────────

Future<void> previewOrderSection4748Pdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final fileName =
      'Order_Section_47_48_${DateTime.now().millisecondsSinceEpoch}.pdf';
  try {
    await GoogleFonts.pendingFonts();
  } catch (_) {}

  String fld(List<String> keys, [String fallback = '']) {
    for (final k in keys) {
      final val = doc[k]?.toString().trim() ?? '';
      if (val.isNotEmpty) return val;
    }
    return fallback;
  }

  final section = fld(['formSection']).toLowerCase();
  final isP1Explicit = section.contains('47') ||
      section.contains('main') ||
      section.contains('1');
  final isP2Explicit = section.contains('48') || section.contains('2');
  final showP1 = section.isEmpty ||
      section.contains('complete') ||
      isP1Explicit ||
      !isP2Explicit;
  final showP2 = section.isEmpty ||
      section.contains('complete') ||
      isP2Explicit ||
      !isP1Explicit;

  final pages = <Widget>[];
  if (showP1) pages.add(_buildPg1Widget(doc));
  if (showP2) pages.add(_buildPg2Widget(doc));

  if (!context.mounted) return;
  await FormImagePdfHelper.previewImageBasedPdf(
    context,
    fileName: fileName,
    pages: pages,
    fallbackPdfGenerator: () => generateOrderSection4748Pdf(doc),
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// Pre-Render All Devanagari & Dynamic Fields via Skia / HarfBuzz
// ──────────────────────────────────────────────────────────────────────────────

Future<MarathiImageCache> _preRenderAllSection4748Marathi(
    Map<String, dynamic> doc) async {
  final cache = MarathiImageCache(pixelRatio: 2.5);
  await GoogleFonts.pendingFonts();

  final titleStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  ).copyWith(fontFamilyFallback: kMarathiFallbackFonts);

  final subTitleStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 14.5,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  ).copyWith(fontFamilyFallback: kMarathiFallbackFonts);

  final boldLabelStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 12.5,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  ).copyWith(fontFamilyFallback: kMarathiFallbackFonts);

  final regularTextStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 11.5,
    height: 1.45,
    color: Colors.black87,
  ).copyWith(fontFamilyFallback: kMarathiFallbackFonts);

  final valueStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 11.5,
    fontWeight: FontWeight.bold,
    color: _kInkColor,
  ).copyWith(fontFamilyFallback: kMarathiFallbackFonts);

  final valueUnderlineStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 11.5,
    fontWeight: FontWeight.bold,
    color: _kInkColor,
    decoration: TextDecoration.underline,
  ).copyWith(fontFamilyFallback: kMarathiFallbackFonts);

  final watermarkStyle = GoogleFonts.lora(
    fontSize: 12.5,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
    decoration: TextDecoration.underline,
  );

  String fld(List<String> keys, [String fallback = '']) {
    for (final k in keys) {
      final val = doc[k]?.toString().trim() ?? '';
      if (val.isNotEmpty) return val;
    }
    return fallback;
  }

  final pageRange = fld(['pageRange', 'formLabel']);

  // Pre-render static labels
  await cache.add('p1_title', 'नोटीस', titleStyle, textAlign: TextAlign.center);
  await cache.add('p1_sub', 'बी.एन.एस.एस.कलम ४७(१)', subTitleStyle,
      textAlign: TextAlign.center);
  await cache.add('p2_sub', 'बी.एन.एस.एस.कलम ४८', subTitleStyle,
      textAlign: TextAlign.center);
  await cache.add(
    'badge_p1',
    pageRange.isNotEmpty ? pageRange : 'Page 1 — नोटीस बी.एन.एस.एस.कलम ४७(१)',
    watermarkStyle,
  );
  await cache.add(
    'badge_p2',
    pageRange.isNotEmpty ? pageRange : 'Page 2 — नोटीस बी.एन.एस.एस.कलम ४८',
    watermarkStyle,
  );
  await cache.add('lbl_to', 'प्रति,', boldLabelStyle);
  await cache.add(
      'p1_sub_line',
      'विषय :- गुन्ह्याचे तपास कामी अटक करण्याचा आधार व कारणांबाबत...',
      boldLabelStyle);
  await cache.add(
      'p2_sub_line',
      'विषय :- गुन्ह्याचे तपास कामी अटक केले संबंधी अवगत केले बाबत...',
      boldLabelStyle);
  await cache.add('lbl_a', 'अ) गुन्ह्याची थोडक्यात हकीगत :-', boldLabelStyle);
  await cache.add('lbl_b', 'ब) अटक करण्यासंबंधाने आधार :-', boldLabelStyle);
  await cache.add('lbl_c', 'क) अटकेची कारणे :-', boldLabelStyle);
  for (final n in ['१)', '२)', '३)', '४)', '५)']) {
    await cache.add('num_$n', n, boldLabelStyle);
  }
  await cache.add(
    'p1_clause_d',
    'ड) सदर गुन्हा हा जामीनपात्र/अजामीनपात्र आहे. गुन्हा जामीनपात्र असल्याने आपण योग्य तो जामीन दिल्यास आपणास जामीनावर मुक्त करण्यात येईल.',
    regularTextStyle,
    maxWidth: 515,
  );
  await cache.add(
    'p2_clause_d',
    'ड) सदर गुन्हा हा जामीनपात्र/अजामीनपात्र आहे. गुन्हा जामीनपात्र असल्याने योग्य तो जामीन दिल्यास अटक व्यक्तीस जामीनावर मुक्त करण्यात येईल.',
    regularTextStyle,
    maxWidth: 515,
  );
  await cache.add('lbl_closing', 'कळावे,', boldLabelStyle);
  await cache.add(
    'lbl_thumb_box',
    '(सही / डाव्या हाताच्या अंगठ्याचा ठसा)',
    regularTextStyle.copyWith(fontSize: 10, color: Colors.black54),
    textAlign: TextAlign.center,
  );
  await cache.add(
    'lbl_stamp_box',
    '(स्वाक्षरी व पोलीस स्टेशन शिक्का)',
    regularTextStyle.copyWith(fontSize: 10, color: Colors.black54),
    textAlign: TextAlign.center,
  );
  await cache.add('p1_sig_accused', 'आरोपीची स्वाक्षरी / अंगठा', boldLabelStyle,
      textAlign: TextAlign.center);
  await cache.add(
      'p2_sig_relative', 'नातेवाईकाची स्वाक्षरी / अंगठा', boldLabelStyle,
      textAlign: TextAlign.center);
  await cache.add('lbl_sig_io', 'तपासणी अधिकारी / अंमलदार', boldLabelStyle,
      textAlign: TextAlign.center);

  final policeStation = fld(['policeStation', 'ps', 'n47PoliceStation']);
  final crNo = fld(['crNo', 'firNo', 'n47CrNo']);
  final crYear = fld(['crYear', 'firYear', 'n47CrYear']);
  final bnsSection = fld(['bnsSection', 'section', 'actSection', 'n47Section']);
  final arrestDate = fld(['arrestDate', 'date', 'n47Date']);
  final arrestTime = fld(['arrestTime', 'time', 'n47Time']);
  final ioName = fld(['ioName', 'shoName', 'n47IoName']);

  // Page 1 fields
  final p1To1 = fld(['p1To1', 'accusedName', 'n47To']);
  final p1RemandDate = fld(['p1RemandDate', 'arrestDate'], arrestDate);
  final p1AccusedSig =
      fld(['p1AccusedSig', 'n47AccusedSig', 'n47AccusedName'], p1To1);
  final p1IoSig = fld(['p1IoSig', 'n47IoName', 'ioName'], ioName);

  // Page 2 fields
  final p2To1 = fld(['p2To1', 'n48To']);
  final p2AccusedName = fld(['p2AccusedName', 'accusedName', 'p1To1'], p1To1);
  final p2RemandDate =
      fld(['p2RemandDate', 'p1RemandDate', 'arrestDate'], p1RemandDate);
  final p2RelativeSig = fld(['p2RelativeSig', 'n48RelativeSig'], p2To1);
  final p2IoSig = fld(['p2IoSig', 'n48IoName', 'ioName'], ioName);

  // Flowing Notice Paragraph Spans with underlined values
  final p1NoticeSpan = TextSpan(
    style: regularTextStyle,
    children: [
      const TextSpan(text: '        आपणास याद्वारे कळविण्यात येते की, '),
      TextSpan(
        text: policeStation.isNotEmpty
            ? '  $policeStation  '
            : '                                          ',
        style: valueUnderlineStyle,
      ),
      const TextSpan(text: ' पोलीस स्टेशन, गुन्हा रजि.नंबर '),
      TextSpan(
        text: crNo.isNotEmpty
            ? (crYear.isNotEmpty ? '  $crNo / $crYear  ' : '  $crNo  ')
            : '        / २०  ',
        style: valueUnderlineStyle,
      ),
      const TextSpan(text: ' भा.न्या.सं.कलम '),
      TextSpan(
        text: bnsSection.isNotEmpty
            ? '  $bnsSection  '
            : '                        ',
        style: valueUnderlineStyle,
      ),
      const TextSpan(
          text:
              ' या गुन्ह्याचे तपासात निष्पन्न झालेल्या पुराव्यावरून आपणास दिनांक '),
      TextSpan(
        text: arrestDate.isNotEmpty ? '  $arrestDate  ' : '    /    /२०  ',
        style: valueUnderlineStyle,
      ),
      const TextSpan(text: ' रोजी '),
      TextSpan(
        text: arrestTime.isNotEmpty ? '  $arrestTime  ' : '      :      ',
        style: valueUnderlineStyle,
      ),
      const TextSpan(
          text: ' वा. खालील आधारावर व कारणांसाठी अटक करण्यात येत आहे :-'),
    ],
  );
  await cache.addSpan('p1_notice_para', p1NoticeSpan,
      maxWidth: 515, textAlign: TextAlign.justify);

  final p1RemandSpan = TextSpan(
    style: regularTextStyle,
    children: [
      const TextSpan(text: 'इ) आपणास दिनांक '),
      TextSpan(
        text: p1RemandDate.isNotEmpty ? '  $p1RemandDate  ' : '    /    /२०  ',
        style: valueUnderlineStyle,
      ),
      const TextSpan(
          text:
              ' रोजी मा.प्रथम वर्ग न्यायदंडाधिकारी यांचे समक्ष रिमांडसाठी हजर करण्यात येणार आहे.'),
    ],
  );
  await cache.addSpan('p1_remand_clause', p1RemandSpan,
      maxWidth: 515, textAlign: TextAlign.left);

  final p2NoticeSpan = TextSpan(
    style: regularTextStyle,
    children: [
      const TextSpan(text: '        आपणास याद्वारे कळविण्यात येते की, '),
      TextSpan(
        text: policeStation.isNotEmpty
            ? '  $policeStation  '
            : '                                          ',
        style: valueUnderlineStyle,
      ),
      const TextSpan(text: ' पोलीस स्टेशन, गुन्हा रजि.नंबर '),
      TextSpan(
        text: crNo.isNotEmpty
            ? (crYear.isNotEmpty ? '  $crNo / $crYear  ' : '  $crNo  ')
            : '        / २०  ',
        style: valueUnderlineStyle,
      ),
      const TextSpan(text: ' भा.न्या.सं.कलम '),
      TextSpan(
        text: bnsSection.isNotEmpty
            ? '  $bnsSection  '
            : '                        ',
        style: valueUnderlineStyle,
      ),
      const TextSpan(
          text: ' या गुन्ह्यात आपले नातेवाईक / मित्र / आप्तेष्ठ नामे '),
      TextSpan(
        text: p2AccusedName.isNotEmpty
            ? '  $p2AccusedName  '
            : '                                    ',
        style: valueUnderlineStyle,
      ),
      const TextSpan(text: ' यांना दिनांक '),
      TextSpan(
        text: arrestDate.isNotEmpty ? '  $arrestDate  ' : '    /    /२०  ',
        style: valueUnderlineStyle,
      ),
      const TextSpan(text: ' रोजी '),
      TextSpan(
        text: arrestTime.isNotEmpty ? '  $arrestTime  ' : '      :      ',
        style: valueUnderlineStyle,
      ),
      const TextSpan(text: ' वा. अटक करण्यात आली आहे.'),
    ],
  );
  await cache.addSpan('p2_notice_para', p2NoticeSpan,
      maxWidth: 515, textAlign: TextAlign.justify);

  final p2RemandSpan = TextSpan(
    style: regularTextStyle,
    children: [
      const TextSpan(text: 'इ) अटक व्यक्तीला दिनांक '),
      TextSpan(
        text: p2RemandDate.isNotEmpty ? '  $p2RemandDate  ' : '    /    /२०  ',
        style: valueUnderlineStyle,
      ),
      const TextSpan(
          text:
              ' रोजी मा.प्रथम वर्ग न्यायदंडाधिकारी यांचे समक्ष रिमांडसाठी हजर करण्यात येणार आहे.'),
    ],
  );
  await cache.addSpan('p2_remand_clause', p2RemandSpan,
      maxWidth: 515, textAlign: TextAlign.left);

  // Dynamic user-filled values
  Future<void> addVal(String key, String val, {double maxWidth = 480}) async {
    final text = val.trim();
    if (text.isEmpty) return;
    await cache.add(key, text, valueStyle, maxWidth: maxWidth);
  }

  // Page 1 fields
  await addVal('val_p1To1', p1To1);
  await addVal('val_p1To2', fld(['p1To2']));
  await addVal('val_p1To3', fld(['p1To3']));
  await addVal('val_p1Fact1', fld(['p1Fact1', 'orderBody', 'n47Body']));
  await addVal('val_p1Fact2', fld(['p1Fact2']));
  await addVal('val_p1Fact3', fld(['p1Fact3']));
  await addVal('val_p1Ground1', fld(['p1Ground1']));
  await addVal('val_p1Ground2', fld(['p1Ground2']));
  await addVal('val_p1Ground3', fld(['p1Ground3']));
  await addVal('val_p1Ground4', fld(['p1Ground4']));
  await addVal('val_p1Ground5', fld(['p1Ground5']));
  await addVal('val_p1Reason1', fld(['p1Reason1']));
  await addVal('val_p1Reason2', fld(['p1Reason2']));
  await addVal('val_p1Reason3', fld(['p1Reason3']));
  await addVal('val_p1Reason4', fld(['p1Reason4']));
  await addVal('val_p1Reason5', fld(['p1Reason5']));
  await addVal('val_p1AccusedSig', p1AccusedSig, maxWidth: 210);
  await addVal('val_p1IoSig', p1IoSig, maxWidth: 210);

  // Page 2 fields
  await addVal('val_p2To1', p2To1);
  await addVal('val_p2To2', fld(['p2To2']));
  await addVal('val_p2To3', fld(['p2To3']));
  await addVal('val_p2Fact1', fld(['p2Fact1', 'p1Fact1', 'orderBody']));
  await addVal('val_p2Fact2', fld(['p2Fact2', 'p1Fact2']));
  await addVal('val_p2Fact3', fld(['p2Fact3', 'p1Fact3']));
  await addVal('val_p2Ground1', fld(['p2Ground1', 'p1Ground1']));
  await addVal('val_p2Ground2', fld(['p2Ground2', 'p1Ground2']));
  await addVal('val_p2Ground3', fld(['p2Ground3', 'p1Ground3']));
  await addVal('val_p2Ground4', fld(['p2Ground4', 'p1Ground4']));
  await addVal('val_p2Ground5', fld(['p2Ground5', 'p1Ground5']));
  await addVal('val_p2Reason1', fld(['p2Reason1', 'p1Reason1']));
  await addVal('val_p2Reason2', fld(['p2Reason2', 'p1Reason2']));
  await addVal('val_p2Reason3', fld(['p2Reason3', 'p1Reason3']));
  await addVal('val_p2Reason4', fld(['p2Reason4', 'p1Reason4']));
  await addVal('val_p2Reason5', fld(['p2Reason5', 'p1Reason5']));
  await addVal('val_p2RelativeSig', p2RelativeSig, maxWidth: 210);
  await addVal('val_p2IoSig', p2IoSig, maxWidth: 210);

  return cache;
}

// ──────────────────────────────────────────────────────────────────────────────
// Vector PDF Generator with HarfBuzz Image Cache & Safe Boundaries
// ──────────────────────────────────────────────────────────────────────────────

Future<Uint8List> generateOrderSection4748Pdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();

  final loraBold = await PdfFontCache.loraBold();
  pw.Font? devanagariFont;
  try {
    devanagariFont =
        _cachedDevanagariBold ?? await PdfFontCache.devanagariBold();
  } catch (_) {}
  final cache = await _preRenderAllSection4748Marathi(doc);

  final englishValStyle = pw.TextStyle(
    font: loraBold,
    fontFallback: devanagariFont != null ? [devanagariFont] : const [],
    fontSize: 11.0,
    fontWeight: pw.FontWeight.bold,
    color: _kPdfInkColor,
  );

  pw.Widget mLbl(String key) {
    if (cache.has(key)) return cache.img(key);
    return pw.SizedBox();
  }

  pw.Widget renderVal(String key, String val,
      {double height = 13.5, double? maxWidth}) {
    final text = val.trim();
    if (text.isEmpty) return pw.SizedBox();
    pw.Widget content;
    if (cache.has(key)) {
      content =
          cache.img(key, height: height, alignment: pw.Alignment.bottomLeft);
    } else {
      content = pw.Text(text, style: englishValStyle);
    }
    if (maxWidth != null) {
      return pw.ConstrainedBox(
        constraints: pw.BoxConstraints(maxWidth: maxWidth),
        child: pw.ClipRect(child: content),
      );
    }
    return content;
  }

  pw.Widget buildRuledLine(String prefixKey, String valKey, String val) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          if (prefixKey.isNotEmpty && cache.has(prefixKey))
            pw.Padding(
              padding: const pw.EdgeInsets.only(right: 5),
              child: cache.img(prefixKey,
                  height: 12.0, alignment: pw.Alignment.bottomLeft),
            ),
          pw.Expanded(
            child: pw.Container(
              height: 18.0,
              alignment: pw.Alignment.bottomLeft,
              padding: const pw.EdgeInsets.only(bottom: 1.5, left: 2),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey700, width: 0.7),
                ),
              ),
              child: renderVal(valKey, val, height: 13.5),
            ),
          ),
        ],
      ),
    );
  }

  String fld(List<String> keys, [String fallback = '']) {
    for (final k in keys) {
      final val = doc[k]?.toString().trim() ?? '';
      if (val.isNotEmpty) return val;
    }
    return fallback;
  }

  final ioName = fld(['ioName', 'shoName', 'n47IoName']);

  // Page 1 fields
  final p1To1 = fld(['p1To1', 'accusedName', 'n47To']);
  final p1To2 = fld(['p1To2']);
  final p1To3 = fld(['p1To3']);
  final p1Fact1 = fld(['p1Fact1', 'orderBody', 'n47Body']);
  final p1Fact2 = fld(['p1Fact2']);
  final p1Fact3 = fld(['p1Fact3']);
  final p1Ground1 = fld(['p1Ground1']);
  final p1Ground2 = fld(['p1Ground2']);
  final p1Ground3 = fld(['p1Ground3']);
  final p1Ground4 = fld(['p1Ground4']);
  final p1Ground5 = fld(['p1Ground5']);
  final p1Reason1 = fld(['p1Reason1']);
  final p1Reason2 = fld(['p1Reason2']);
  final p1Reason3 = fld(['p1Reason3']);
  final p1Reason4 = fld(['p1Reason4']);
  final p1Reason5 = fld(['p1Reason5']);
  final p1AccusedSig =
      fld(['p1AccusedSig', 'n47AccusedSig', 'n47AccusedName'], p1To1);
  final p1IoSig = fld(['p1IoSig', 'n47IoName', 'ioName'], ioName);

  // Page 2 fields
  final p2To1 = fld(['p2To1', 'n48To']);
  final p2To2 = fld(['p2To2']);
  final p2To3 = fld(['p2To3']);
  final p2Fact1 = fld(['p2Fact1', 'p1Fact1', 'orderBody']);
  final p2Fact2 = fld(['p2Fact2', 'p1Fact2']);
  final p2Fact3 = fld(['p2Fact3', 'p1Fact3']);
  final p2Ground1 = fld(['p2Ground1', 'p1Ground1']);
  final p2Ground2 = fld(['p2Ground2', 'p1Ground2']);
  final p2Ground3 = fld(['p2Ground3', 'p1Ground3']);
  final p2Ground4 = fld(['p2Ground4', 'p1Ground4']);
  final p2Ground5 = fld(['p2Ground5', 'p1Ground5']);
  final p2Reason1 = fld(['p2Reason1', 'p1Reason1']);
  final p2Reason2 = fld(['p2Reason2', 'p1Reason2']);
  final p2Reason3 = fld(['p2Reason3', 'p1Reason3']);
  final p2Reason4 = fld(['p2Reason4', 'p1Reason4']);
  final p2Reason5 = fld(['p2Reason5', 'p1Reason5']);
  final p2RelativeSig = fld(['p2RelativeSig', 'n48RelativeSig'], p2To1);
  final p2IoSig = fld(['p2IoSig', 'n48IoName', 'ioName'], ioName);

  final section = fld(['formSection']).toLowerCase();
  final isP1Explicit = section.contains('47') ||
      section.contains('main') ||
      section.contains('1');
  final isP2Explicit = section.contains('48') || section.contains('2');
  final showP1 = section.isEmpty ||
      section.contains('complete') ||
      isP1Explicit ||
      !isP2Explicit;
  final showP2 = section.isEmpty ||
      section.contains('complete') ||
      isP2Explicit ||
      !isP1Explicit;

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 1: नोटीस बी.एन.एस.एस.कलम ४७(१)
  // ══════════════════════════════════════════════════════════════════════════
  if (showP1) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 26),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Top Right Badge
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: mLbl('badge_p1'),
            ),
            pw.SizedBox(height: 2),

            // Top Center Header
            pw.Center(child: mLbl('p1_title')),
            pw.SizedBox(height: 2),
            pw.Center(child: mLbl('p1_sub')),
            pw.SizedBox(height: 8),

            // Recipient block
            mLbl('lbl_to'),
            pw.SizedBox(height: 3),
            buildRuledLine('', 'val_p1To1', p1To1),
            buildRuledLine('', 'val_p1To2', p1To2),
            buildRuledLine('', 'val_p1To3', p1To3),
            pw.SizedBox(height: 6),

            // Subject
            mLbl('p1_sub_line'),
            pw.SizedBox(height: 6),

            // Notice Paragraph
            mLbl('p1_notice_para'),
            pw.SizedBox(height: 8),

            // अ) गुन्ह्याची थोडक्यात हकीगत :-
            mLbl('lbl_a'),
            pw.SizedBox(height: 3),
            buildRuledLine('', 'val_p1Fact1', p1Fact1),
            buildRuledLine('', 'val_p1Fact2', p1Fact2),
            buildRuledLine('', 'val_p1Fact3', p1Fact3),
            pw.SizedBox(height: 6),

            // ब) अटक करण्यासंबंधाने आधार :-
            mLbl('lbl_b'),
            pw.SizedBox(height: 3),
            buildRuledLine('num_१)', 'val_p1Ground1', p1Ground1),
            buildRuledLine('num_२)', 'val_p1Ground2', p1Ground2),
            buildRuledLine('num_३)', 'val_p1Ground3', p1Ground3),
            buildRuledLine('num_४)', 'val_p1Ground4', p1Ground4),
            buildRuledLine('num_५)', 'val_p1Ground5', p1Ground5),
            pw.SizedBox(height: 6),

            // क) अटकेची कारणे :-
            mLbl('lbl_c'),
            pw.SizedBox(height: 3),
            buildRuledLine('num_१)', 'val_p1Reason1', p1Reason1),
            buildRuledLine('num_२)', 'val_p1Reason2', p1Reason2),
            buildRuledLine('num_३)', 'val_p1Reason3', p1Reason3),
            buildRuledLine('num_४)', 'val_p1Reason4', p1Reason4),
            buildRuledLine('num_५)', 'val_p1Reason5', p1Reason5),
            pw.SizedBox(height: 6),

            // ड)
            mLbl('p1_clause_d'),
            pw.SizedBox(height: 5),

            // इ)
            mLbl('p1_remand_clause'),

            // Breathing room pushing footer gracefully down
            pw.Spacer(),

            // Footer
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(right: 36),
                child: mLbl('lbl_closing'),
              ),
            ),
            pw.SizedBox(height: 6),

            // Dual Signature & Seal Block
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // Left: Accused
                pw.Container(
                  width: 220,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        height: 54,
                        width: 205,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                              color: PdfColors.grey600, width: 0.8),
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(3)),
                        ),
                        alignment: pw.Alignment.center,
                        child: mLbl('lbl_thumb_box'),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Center(
                        child: renderVal(
                          'val_p1AccusedSig',
                          p1AccusedSig.isNotEmpty ? p1AccusedSig : p1To1,
                          height: 13.0,
                          maxWidth: 205,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      mLbl('p1_sig_accused'),
                    ],
                  ),
                ),

                // Right: IO
                pw.Container(
                  width: 220,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        height: 54,
                        width: 205,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                              color: PdfColors.grey600, width: 0.8),
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(3)),
                        ),
                        alignment: pw.Alignment.center,
                        child: mLbl('lbl_stamp_box'),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Center(
                        child: renderVal(
                          'val_p1IoSig',
                          p1IoSig.isNotEmpty ? p1IoSig : ioName,
                          height: 13.0,
                          maxWidth: 205,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      mLbl('lbl_sig_io'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 2: नोटीस बी.एन.एस.एस.कलम ४८
  // ══════════════════════════════════════════════════════════════════════════
  if (showP2) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 26),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Top Right Badge
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: mLbl('badge_p2'),
            ),
            pw.SizedBox(height: 2),

            // Top Center Header
            pw.Center(child: mLbl('p1_title')),
            pw.SizedBox(height: 2),
            pw.Center(child: mLbl('p2_sub')),
            pw.SizedBox(height: 8),

            // Recipient block
            mLbl('lbl_to'),
            pw.SizedBox(height: 3),
            buildRuledLine('', 'val_p2To1', p2To1),
            buildRuledLine('', 'val_p2To2', p2To2),
            buildRuledLine('', 'val_p2To3', p2To3),
            pw.SizedBox(height: 6),

            // Subject
            mLbl('p2_sub_line'),
            pw.SizedBox(height: 6),

            // Notice Paragraph
            mLbl('p2_notice_para'),
            pw.SizedBox(height: 8),

            // अ) गुन्ह्याची थोडक्यात हकीगत :-
            mLbl('lbl_a'),
            pw.SizedBox(height: 3),
            buildRuledLine('', 'val_p2Fact1', p2Fact1),
            buildRuledLine('', 'val_p2Fact2', p2Fact2),
            buildRuledLine('', 'val_p2Fact3', p2Fact3),
            pw.SizedBox(height: 6),

            // ब) अटक करण्यासंबंधाने आधार :-
            mLbl('lbl_b'),
            pw.SizedBox(height: 3),
            buildRuledLine('num_१)', 'val_p2Ground1', p2Ground1),
            buildRuledLine('num_२)', 'val_p2Ground2', p2Ground2),
            buildRuledLine('num_३)', 'val_p2Ground3', p2Ground3),
            buildRuledLine('num_४)', 'val_p2Ground4', p2Ground4),
            buildRuledLine('num_५)', 'val_p2Ground5', p2Ground5),
            pw.SizedBox(height: 6),

            // क) अटकेची कारणे :-
            mLbl('lbl_c'),
            pw.SizedBox(height: 3),
            buildRuledLine('num_१)', 'val_p2Reason1', p2Reason1),
            buildRuledLine('num_२)', 'val_p2Reason2', p2Reason2),
            buildRuledLine('num_३)', 'val_p2Reason3', p2Reason3),
            buildRuledLine('num_४)', 'val_p2Reason4', p2Reason4),
            buildRuledLine('num_५)', 'val_p2Reason5', p2Reason5),
            pw.SizedBox(height: 6),

            // ड)
            mLbl('p2_clause_d'),
            pw.SizedBox(height: 5),

            // इ)
            mLbl('p2_remand_clause'),

            // Breathing room pushing footer gracefully down
            pw.Spacer(),

            // Footer
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(right: 36),
                child: mLbl('lbl_closing'),
              ),
            ),
            pw.SizedBox(height: 6),

            // Dual Signature & Seal Block
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // Left: Relative
                pw.Container(
                  width: 220,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        height: 54,
                        width: 205,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                              color: PdfColors.grey600, width: 0.8),
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(3)),
                        ),
                        alignment: pw.Alignment.center,
                        child: mLbl('lbl_thumb_box'),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Center(
                        child: renderVal(
                          'val_p2RelativeSig',
                          p2RelativeSig.isNotEmpty ? p2RelativeSig : p2To1,
                          height: 13.0,
                          maxWidth: 205,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      mLbl('p2_sig_relative'),
                    ],
                  ),
                ),

                // Right: IO
                pw.Container(
                  width: 220,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        height: 54,
                        width: 205,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                              color: PdfColors.grey600, width: 0.8),
                          borderRadius:
                              const pw.BorderRadius.all(pw.Radius.circular(3)),
                        ),
                        alignment: pw.Alignment.center,
                        child: mLbl('lbl_stamp_box'),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Center(
                        child: renderVal(
                          'val_p2IoSig',
                          p2IoSig.isNotEmpty ? p2IoSig : ioName,
                          height: 13.0,
                          maxWidth: 205,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      mLbl('lbl_sig_io'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  return pdf.save();
}

// ══════════════════════════════════════════════════════════════════════════════
// ── NATIVE FLUTTER WIDGET BUILDERS (100% Devanagari Font Shaping & Form Match)
// ══════════════════════════════════════════════════════════════════════════════

Widget _buildPg1Widget(Map<String, dynamic> doc) {
  String fld(List<String> keys, [String fallback = '']) {
    for (final k in keys) {
      final val = doc[k]?.toString().trim() ?? '';
      if (val.isNotEmpty) return val;
    }
    return fallback;
  }

  final policeStation = fld(['policeStation', 'ps', 'n47PoliceStation']);
  final crNo = fld(['crNo', 'firNo', 'n47CrNo']);
  final crYear = fld(['crYear', 'firYear', 'n47CrYear']);
  final bnsSection = fld(['bnsSection', 'section', 'actSection', 'n47Section']);
  final arrestDate = fld(['arrestDate', 'date', 'n47Date']);
  final arrestTime = fld(['arrestTime', 'time', 'n47Time']);
  final ioName = fld(['ioName', 'shoName', 'n47IoName']);

  final pageRange = fld(['pageRange', 'formLabel']);

  final p1To1 = fld(['p1To1', 'accusedName', 'n47To']);
  final p1To2 = fld(['p1To2']);
  final p1To3 = fld(['p1To3']);
  final p1Fact1 = fld(['p1Fact1', 'orderBody', 'n47Body']);
  final p1Fact2 = fld(['p1Fact2']);
  final p1Fact3 = fld(['p1Fact3']);
  final p1Ground1 = fld(['p1Ground1']);
  final p1Ground2 = fld(['p1Ground2']);
  final p1Ground3 = fld(['p1Ground3']);
  final p1Ground4 = fld(['p1Ground4']);
  final p1Ground5 = fld(['p1Ground5']);
  final p1Reason1 = fld(['p1Reason1']);
  final p1Reason2 = fld(['p1Reason2']);
  final p1Reason3 = fld(['p1Reason3']);
  final p1Reason4 = fld(['p1Reason4']);
  final p1Reason5 = fld(['p1Reason5']);
  final p1RemandDate = fld(['p1RemandDate', 'arrestDate'], arrestDate);
  final p1AccusedSig =
      fld(['p1AccusedSig', 'n47AccusedSig', 'n47AccusedName'], p1To1);
  final p1IoSig = fld(['p1IoSig', 'n47IoName', 'ioName'], ioName);

  final titleStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );
  final subTitleStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 14.5,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );
  final boldLabelStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  final bodyStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 12.5,
    height: 1.45,
    color: Colors.black87,
  );
  final valStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: _kInkColor,
  );
  final badgeStyle = GoogleFonts.lora(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
    decoration: TextDecoration.underline,
  );

  Widget buildRuledLine(String prefix, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (prefix.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 2, right: 6),
              child: Text(prefix, style: boldLabelStyle),
            ),
          Expanded(
            child: Container(
              height: 22,
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.only(bottom: 2, left: 3),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF757575), width: 0.85),
                ),
              ),
              child: Text(
                value,
                style: valStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildUnderlineField(
    String value, {
    double? width,
    String? hint,
    TextAlign textAlign = TextAlign.start,
    IconData? icon,
  }) {
    return Container(
      constraints: BoxConstraints(minWidth: width ?? 0),
      height: 22,
      alignment: textAlign == TextAlign.center
          ? Alignment.bottomCenter
          : Alignment.bottomLeft,
      padding: const EdgeInsets.only(bottom: 2, left: 3, right: 3),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF616161), width: 0.85),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: textAlign == TextAlign.center
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              value.isNotEmpty ? value : (hint ?? ''),
              style: value.isNotEmpty
                  ? valStyle
                  : GoogleFonts.notoSansDevanagari(
                      fontSize: 11,
                      color: Colors.black38,
                    ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: textAlign,
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 4),
            Icon(icon, size: 13, color: const Color(0xFF1976D2)),
          ],
        ],
      ),
    );
  }

  return Container(
    width: FormImagePdfHelper.a4Width,
    height: FormImagePdfHelper.a4Height,
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(42, 28, 42, 26),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: FormImagePdfHelper.a4Width - 84,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Text(
                pageRange.isNotEmpty
                    ? pageRange
                    : 'Page 1 — नोटीस बी.एन.एस.एस.कलम ४७(१)',
                style: badgeStyle,
              ),
            ),
            const SizedBox(height: 3),
            Center(child: Text('नोटीस', style: titleStyle)),
            const SizedBox(height: 2),
            Center(child: Text('बी.एन.एस.एस.कलम ४७(१)', style: subTitleStyle)),
            const SizedBox(height: 10),
            Text('प्रति,', style: boldLabelStyle),
            const SizedBox(height: 4),
            buildRuledLine('', p1To1),
            buildRuledLine('', p1To2),
            buildRuledLine('', p1To3),
            const SizedBox(height: 8),
            Text(
              'विषय :- गुन्ह्याचे तपास कामी अटक करण्याचा आधार व कारणांबाबत...',
              style: boldLabelStyle,
            ),
            const SizedBox(height: 8),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 7,
              children: [
                const SizedBox(width: 24),
                Text('आपणास याद्वारे कळविण्यात येते की,', style: bodyStyle),
                buildUnderlineField(policeStation,
                    width: 175, hint: 'पोलीस स्टेशन नाव'),
                Text('पोलीस स्टेशन, गुन्हा रजि.नंबर', style: bodyStyle),
                buildUnderlineField(crNo,
                    width: 85, hint: 'गु.र.नं.', textAlign: TextAlign.center),
                Text('/', style: bodyStyle),
                buildUnderlineField(crYear,
                    width: 50, hint: 'वर्ष', textAlign: TextAlign.center),
                Text('भा.न्या.सं.कलम', style: bodyStyle),
                buildUnderlineField(bnsSection,
                    width: 190, hint: 'उदा. १०३, ३(५)'),
                Text(
                    'या गुन्ह्याचे तपासात निष्पन्न झालेल्या पुराव्यावरून आपणास दिनांक',
                    style: bodyStyle),
                buildUnderlineField(arrestDate,
                    width: 130, hint: 'दिनांक', icon: Icons.calendar_today),
                Text('रोजी', style: bodyStyle),
                buildUnderlineField(arrestTime,
                    width: 100, hint: 'वेळ', icon: Icons.access_time),
                Text('वा. खालील आधारावर व कारणांसाठी अटक करण्यात येत आहे :-',
                    style: bodyStyle),
              ],
            ),
            const SizedBox(height: 8),
            Text('अ) गुन्ह्याची थोडक्यात हकीगत :-', style: boldLabelStyle),
            const SizedBox(height: 4),
            buildRuledLine('', p1Fact1),
            buildRuledLine('', p1Fact2),
            buildRuledLine('', p1Fact3),
            const SizedBox(height: 8),
            Text('ब) अटक करण्यासंबंधाने आधार :-', style: boldLabelStyle),
            const SizedBox(height: 4),
            buildRuledLine('१)', p1Ground1),
            buildRuledLine('२)', p1Ground2),
            buildRuledLine('३)', p1Ground3),
            buildRuledLine('४)', p1Ground4),
            buildRuledLine('५)', p1Ground5),
            const SizedBox(height: 8),
            Text('क) अटकेची कारणे :-', style: boldLabelStyle),
            const SizedBox(height: 4),
            buildRuledLine('१)', p1Reason1),
            buildRuledLine('२)', p1Reason2),
            buildRuledLine('३)', p1Reason3),
            buildRuledLine('४)', p1Reason4),
            buildRuledLine('५)', p1Reason5),
            const SizedBox(height: 8),
            Text(
              'ड) सदर गुन्हा हा जामीनपात्र/अजामीनपात्र आहे. गुन्हा जामीनपात्र असल्याने आपण योग्य तो जामीन दिल्यास आपणास जामीनावर मुक्त करण्यात येईल.',
              style: bodyStyle,
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 6),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 6,
              children: [
                Text('इ) आपणास दिनांक', style: bodyStyle),
                buildUnderlineField(p1RemandDate,
                    width: 130, hint: 'दिनांक', icon: Icons.calendar_today),
                Text(
                  'रोजी मा.प्रथम वर्ग न्यायदंडाधिकारी यांचे समक्ष रिमांडसाठी हजर करण्यात येणार आहे.',
                  style: bodyStyle,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 36),
                child: Text('कळावे,', style: boldLabelStyle),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 225,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 56,
                        width: 220,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border:
                              Border.all(color: Colors.black54, width: 0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '(सही / डाव्या हाताच्या अंगठ्याचा ठसा)',
                          style: GoogleFonts.notoSansDevanagari(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 220,
                        height: 20,
                        alignment: Alignment.bottomCenter,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Color(0xFF616161), width: 0.85),
                          ),
                        ),
                        child: Text(
                          p1AccusedSig.isNotEmpty
                              ? p1AccusedSig
                              : (p1To1.isNotEmpty ? p1To1 : ''),
                          style: valStyle.copyWith(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('आरोपीची स्वाक्षरी / अंगठा',
                          style: boldLabelStyle.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 225,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 56,
                        width: 220,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border:
                              Border.all(color: Colors.black54, width: 0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '(स्वाक्षरी व पोलीस स्टेशन शिक्का)',
                          style: GoogleFonts.notoSansDevanagari(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 220,
                        height: 20,
                        alignment: Alignment.bottomCenter,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Color(0xFF616161), width: 0.85),
                          ),
                        ),
                        child: Text(
                          p1IoSig.isNotEmpty
                              ? p1IoSig
                              : (ioName.isNotEmpty ? ioName : ''),
                          style: valStyle.copyWith(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('तपासणी अधिकारी / अंमलदार',
                          style: boldLabelStyle.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildPg2Widget(Map<String, dynamic> doc) {
  String fld(List<String> keys, [String fallback = '']) {
    for (final k in keys) {
      final val = doc[k]?.toString().trim() ?? '';
      if (val.isNotEmpty) return val;
    }
    return fallback;
  }

  final policeStation = fld(['policeStation', 'ps', 'n47PoliceStation']);
  final crNo = fld(['crNo', 'firNo', 'n47CrNo']);
  final crYear = fld(['crYear', 'firYear', 'n47CrYear']);
  final bnsSection = fld(['bnsSection', 'section', 'actSection', 'n47Section']);
  final arrestDate = fld(['arrestDate', 'date', 'n47Date']);
  final arrestTime = fld(['arrestTime', 'time', 'n47Time']);
  final ioName = fld(['ioName', 'shoName', 'n47IoName']);

  final pageRange = fld(['pageRange', 'formLabel']);

  final p1To1 = fld(['p1To1', 'accusedName', 'n47To']);
  final p1Fact1 = fld(['p1Fact1', 'orderBody', 'n47Body']);
  final p1Fact2 = fld(['p1Fact2']);
  final p1Fact3 = fld(['p1Fact3']);
  final p1Ground1 = fld(['p1Ground1']);
  final p1Ground2 = fld(['p1Ground2']);
  final p1Ground3 = fld(['p1Ground3']);
  final p1Ground4 = fld(['p1Ground4']);
  final p1Ground5 = fld(['p1Ground5']);
  final p1Reason1 = fld(['p1Reason1']);
  final p1Reason2 = fld(['p1Reason2']);
  final p1Reason3 = fld(['p1Reason3']);
  final p1Reason4 = fld(['p1Reason4']);
  final p1Reason5 = fld(['p1Reason5']);
  final p1RemandDate = fld(['p1RemandDate', 'arrestDate'], arrestDate);

  final p2To1 = fld(['p2To1', 'n48To']);
  final p2To2 = fld(['p2To2']);
  final p2To3 = fld(['p2To3']);
  final p2AccusedName = fld(['p2AccusedName', 'accusedName', 'p1To1'], p1To1);
  final p2Fact1 = fld(['p2Fact1', 'p1Fact1', 'orderBody'], p1Fact1);
  final p2Fact2 = fld(['p2Fact2', 'p1Fact2'], p1Fact2);
  final p2Fact3 = fld(['p2Fact3', 'p1Fact3'], p1Fact3);
  final p2Ground1 = fld(['p2Ground1', 'p1Ground1'], p1Ground1);
  final p2Ground2 = fld(['p2Ground2', 'p1Ground2'], p1Ground2);
  final p2Ground3 = fld(['p2Ground3', 'p1Ground3'], p1Ground3);
  final p2Ground4 = fld(['p2Ground4', 'p1Ground4'], p1Ground4);
  final p2Ground5 = fld(['p2Ground5', 'p1Ground5'], p1Ground5);
  final p2Reason1 = fld(['p2Reason1', 'p1Reason1'], p1Reason1);
  final p2Reason2 = fld(['p2Reason2', 'p1Reason2'], p1Reason2);
  final p2Reason3 = fld(['p2Reason3', 'p1Reason3'], p1Reason3);
  final p2Reason4 = fld(['p2Reason4', 'p1Reason4'], p1Reason4);
  final p2Reason5 = fld(['p2Reason5', 'p1Reason5'], p1Reason5);
  final p2RemandDate =
      fld(['p2RemandDate', 'p1RemandDate', 'arrestDate'], p1RemandDate);
  final p2RelativeSig = fld(['p2RelativeSig', 'n48RelativeSig'], p2To1);
  final p2IoSig = fld(['p2IoSig', 'n48IoName', 'ioName'], ioName);

  final titleStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );
  final subTitleStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 14.5,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );
  final boldLabelStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );
  final bodyStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 12.5,
    height: 1.45,
    color: Colors.black87,
  );
  final valStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: _kInkColor,
  );
  final badgeStyle = GoogleFonts.lora(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
    decoration: TextDecoration.underline,
  );

  Widget buildRuledLine(String prefix, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (prefix.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 2, right: 6),
              child: Text(prefix, style: boldLabelStyle),
            ),
          Expanded(
            child: Container(
              height: 22,
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.only(bottom: 2, left: 3),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF757575), width: 0.85),
                ),
              ),
              child: Text(
                value,
                style: valStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildUnderlineField(
    String value, {
    double? width,
    String? hint,
    TextAlign textAlign = TextAlign.start,
    IconData? icon,
  }) {
    return Container(
      constraints: BoxConstraints(minWidth: width ?? 0),
      height: 22,
      alignment: textAlign == TextAlign.center
          ? Alignment.bottomCenter
          : Alignment.bottomLeft,
      padding: const EdgeInsets.only(bottom: 2, left: 3, right: 3),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF616161), width: 0.85),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: textAlign == TextAlign.center
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              value.isNotEmpty ? value : (hint ?? ''),
              style: value.isNotEmpty
                  ? valStyle
                  : GoogleFonts.notoSansDevanagari(
                      fontSize: 11,
                      color: Colors.black38,
                    ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: textAlign,
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 4),
            Icon(icon, size: 13, color: const Color(0xFF1976D2)),
          ],
        ],
      ),
    );
  }

  return Container(
    width: FormImagePdfHelper.a4Width,
    height: FormImagePdfHelper.a4Height,
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(42, 28, 42, 26),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: FormImagePdfHelper.a4Width - 84,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Text(
                pageRange.isNotEmpty
                    ? pageRange
                    : 'Page 2 — नोटीस बी.एन.एस.एस.कलम ४८',
                style: badgeStyle,
              ),
            ),
            const SizedBox(height: 3),
            Center(child: Text('नोटीस', style: titleStyle)),
            const SizedBox(height: 2),
            Center(child: Text('बी.एन.एस.एस.कलम ४८', style: subTitleStyle)),
            const SizedBox(height: 10),
            Text('प्रति,', style: boldLabelStyle),
            const SizedBox(height: 4),
            buildRuledLine('', p2To1),
            buildRuledLine('', p2To2),
            buildRuledLine('', p2To3),
            const SizedBox(height: 8),
            Text(
              'विषय :- गुन्ह्याचे तपास कामी अटक केले संबंधी अवगत केले बाबत...',
              style: boldLabelStyle,
            ),
            const SizedBox(height: 8),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 7,
              children: [
                const SizedBox(width: 24),
                Text('आपणास याद्वारे कळविण्यात येते की,', style: bodyStyle),
                buildUnderlineField(policeStation,
                    width: 175, hint: 'पोलीस स्टेशन नाव'),
                Text('पोलीस स्टेशन, गुन्हा रजि.नंबर', style: bodyStyle),
                buildUnderlineField(crNo,
                    width: 85, hint: 'गु.र.नं.', textAlign: TextAlign.center),
                Text('/', style: bodyStyle),
                buildUnderlineField(crYear,
                    width: 50, hint: 'वर्ष', textAlign: TextAlign.center),
                Text('भा.न्या.सं.कलम', style: bodyStyle),
                buildUnderlineField(bnsSection,
                    width: 190, hint: 'उदा. १०३, ३(५)'),
                Text('या गुन्ह्यात आपले नातेवाईक / मित्र / आप्तेष्ठ नामे',
                    style: bodyStyle),
                buildUnderlineField(p2AccusedName,
                    width: 230, hint: 'अटक व्यक्तीचे नाव'),
                Text('यांना दिनांक', style: bodyStyle),
                buildUnderlineField(arrestDate,
                    width: 130, hint: 'दिनांक', icon: Icons.calendar_today),
                Text('रोजी', style: bodyStyle),
                buildUnderlineField(arrestTime,
                    width: 100, hint: 'वेळ', icon: Icons.access_time),
                Text('वा. अटक करण्यात आली आहे.', style: bodyStyle),
              ],
            ),
            const SizedBox(height: 8),
            Text('अ) गुन्ह्याची थोडक्यात हकीगत :-', style: boldLabelStyle),
            const SizedBox(height: 4),
            buildRuledLine('', p2Fact1),
            buildRuledLine('', p2Fact2),
            buildRuledLine('', p2Fact3),
            const SizedBox(height: 8),
            Text('ब) अटक करण्यासंबंधाने आधार :-', style: boldLabelStyle),
            const SizedBox(height: 4),
            buildRuledLine('१)', p2Ground1),
            buildRuledLine('२)', p2Ground2),
            buildRuledLine('३)', p2Ground3),
            buildRuledLine('४)', p2Ground4),
            buildRuledLine('५)', p2Ground5),
            const SizedBox(height: 8),
            Text('क) अटकेची कारणे :-', style: boldLabelStyle),
            const SizedBox(height: 4),
            buildRuledLine('१)', p2Reason1),
            buildRuledLine('२)', p2Reason2),
            buildRuledLine('३)', p2Reason3),
            buildRuledLine('४)', p2Reason4),
            buildRuledLine('५)', p2Reason5),
            const SizedBox(height: 8),
            Text(
              'ड) सदर गुन्हा हा जामीनपात्र/अजामीनपात्र आहे. गुन्हा जामीनपात्र असल्याने योग्य तो जामीन दिल्यास अटक व्यक्तीस जामीनावर मुक्त करण्यात येईल.',
              style: bodyStyle,
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 6),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 6,
              children: [
                Text('इ) अटक व्यक्तीला दिनांक', style: bodyStyle),
                buildUnderlineField(p2RemandDate,
                    width: 130, hint: 'दिनांक', icon: Icons.calendar_today),
                Text(
                  'रोजी मा.प्रथम वर्ग न्यायदंडाधिकारी यांचे समक्ष रिमांडसाठी हजर करण्यात येणार आहे.',
                  style: bodyStyle,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 36),
                child: Text('कळावे,', style: boldLabelStyle),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 225,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 56,
                        width: 220,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border:
                              Border.all(color: Colors.black54, width: 0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '(सही / डाव्या हाताच्या अंगठ्याचा ठसा)',
                          style: GoogleFonts.notoSansDevanagari(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 220,
                        height: 20,
                        alignment: Alignment.bottomCenter,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Color(0xFF616161), width: 0.85),
                          ),
                        ),
                        child: Text(
                          p2RelativeSig.isNotEmpty
                              ? p2RelativeSig
                              : (p2To1.isNotEmpty ? p2To1 : ''),
                          style: valStyle.copyWith(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('नातेवाईकाची स्वाक्षरी / अंगठा',
                          style: boldLabelStyle.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 225,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 56,
                        width: 220,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border:
                              Border.all(color: Colors.black54, width: 0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '(स्वाक्षरी व पोलीस स्टेशन शिक्का)',
                          style: GoogleFonts.notoSansDevanagari(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 220,
                        height: 20,
                        alignment: Alignment.bottomCenter,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Color(0xFF616161), width: 0.85),
                          ),
                        ),
                        child: Text(
                          p2IoSig.isNotEmpty
                              ? p2IoSig
                              : (ioName.isNotEmpty ? ioName : ''),
                          style: valStyle.copyWith(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('तपासणी अधिकारी / अंमलदार',
                          style: boldLabelStyle.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
