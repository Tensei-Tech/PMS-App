import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'marathi_text_renderer.dart';

Future<void> previewAccusedMemorandumPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final bytes = await generateAccusedMemorandumPdf(doc);
  if (!context.mounted) return;
  final fileName =
      'Accused_Memorandum_Form_${DateTime.now().millisecondsSinceEpoch}.pdf';
  try {
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } else {
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);
    }
  } catch (_) {
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }
}

Future<Uint8List> generateAccusedMemorandumPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();

  // Load fonts
  final loraBold = await PdfGoogleFonts.loraBold();
  final devanagariRegular = await PdfGoogleFonts.notoSansDevanagariRegular();
  final devanagariBold = await PdfGoogleFonts.notoSansDevanagariBold();

  // Pre-render Marathi text blocks using Skia/HarfBuzz
  final cache = await _preRenderAllMarathi(doc);

  final pw.TextStyle engBold = pw.TextStyle(
    font: loraBold,
    fontSize: 9.5,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.black,
  );

  final pw.TextStyle valStyle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 9.5,
    color: PdfColors.blue900,
  );

  final pw.TextStyle valRegular = pw.TextStyle(
    font: devanagariRegular,
    fontSize: 9,
    color: PdfColors.blue900,
  );

  final sectionStr = doc['formSection']?.toString().toLowerCase().trim() ?? '';
  final isPartIOnly = sectionStr == 'accused part i' ||
      (sectionStr.contains('part i') && !sectionStr.contains('part ii'));
  final isPartIIOnly =
      sectionStr == 'accused part ii' || sectionStr.contains('part ii');

  // Helper to render Marathi or English value
  pw.Widget renderVal(String key, String? val, {pw.TextStyle? style}) {
    final text = val?.trim() ?? '';
    if (text.isEmpty) return pw.SizedBox();
    if (containsDevanagari(text) && cache.has(key)) {
      return cache.img(key);
    }
    return pw.Text(text, style: style ?? valStyle);
  }

  // Helper for dashed / dotted underline fill
  pw.Widget underlineField({
    required pw.Widget label,
    required String valKey,
    required String? value,
    double? width,
    bool expand = false,
  }) {
    final v = value?.trim() ?? '';
    final valWidget = v.isNotEmpty ? renderVal(valKey, v) : pw.SizedBox();

    final content = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            label,
            pw.SizedBox(width: 4),
            pw.Expanded(
              child: pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(
                      color: PdfColors.black,
                      width: 0.8,
                      style: pw.BorderStyle.solid,
                    ),
                  ),
                ),
                padding: const pw.EdgeInsets.only(bottom: 1),
                child: valWidget,
              ),
            ),
          ],
        ),
      ],
    );

    if (expand) return pw.Expanded(child: content);
    if (width != null) return pw.SizedBox(width: width, child: content);
    return content;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PAGE 1: PART I (Image 1)
  // ──────────────────────────────────────────────────────────────────────────
  if (!isPartIIOnly) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 26),
        build: (pw.Context context) {
          final memoText = doc['accusedMemorandum']?.toString().trim() ?? '';
          final memoLines = _splitTextIntoLines(memoText, 95);

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Title Header ───────────────────────────────────────────
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Accused Memorandum Form',
                      style: engBold.copyWith(fontSize: 16),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 1),
                    if (cache.has('title_mr'))
                      cache.img('title_mr')
                    else
                      pw.Text(
                        '(आरोपीचे निवेदन पंचनामा)',
                        style: valStyle.copyWith(
                            fontSize: 12, color: PdfColors.black),
                      ),
                    pw.SizedBox(height: 2),
                    if (cache.has('subtitle_panchanama'))
                      cache.img('subtitle_panchanama')
                    else
                      pw.Text(
                        '( Panchanama u/s 23 (2) Bhartiya Saksh Adhiniyam, 2023 कलम २३ (२) भारतीय साक्ष अधिनियम २०२३ )',
                        style: engBold.copyWith(fontSize: 9.5),
                        textAlign: pw.TextAlign.center,
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Divider(thickness: 1.2, color: PdfColors.black),
              pw.SizedBox(height: 8),

              // ── 1) District, P.S., Year, FIR No., Date ─────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('1) ', style: engBold),
                  underlineField(
                    label: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('District:', style: engBold),
                        cache.has('lbl_dist')
                            ? cache.img('lbl_dist')
                            : pw.SizedBox(),
                      ],
                    ),
                    valKey: 'val_dist',
                    value: doc['dist'],
                    width: 105,
                  ),
                  pw.SizedBox(width: 8),
                  underlineField(
                    label: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('P.S.:', style: engBold),
                        cache.has('lbl_ps')
                            ? cache.img('lbl_ps')
                            : pw.SizedBox(),
                      ],
                    ),
                    valKey: 'val_ps',
                    value: doc['ps'],
                    width: 110,
                  ),
                  pw.SizedBox(width: 8),
                  underlineField(
                    label: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Year:', style: engBold),
                        cache.has('lbl_year')
                            ? cache.img('lbl_year')
                            : pw.SizedBox(),
                      ],
                    ),
                    valKey: 'val_year',
                    value: doc['year'],
                    width: 65,
                  ),
                  pw.SizedBox(width: 8),
                  underlineField(
                    label: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('FIR No:', style: engBold),
                        cache.has('lbl_firNo')
                            ? cache.img('lbl_firNo')
                            : pw.SizedBox(),
                      ],
                    ),
                    valKey: 'val_firNo',
                    value: doc['firNo'],
                    width: 95,
                  ),
                  pw.SizedBox(width: 8),
                  underlineField(
                    label: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Date:', style: engBold),
                        cache.has('lbl_date')
                            ? cache.img('lbl_date')
                            : pw.SizedBox(),
                      ],
                    ),
                    valKey: 'val_firDate',
                    value: doc['firDate'],
                    expand: true,
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              // ── 2) Name of Accused, Age, Sex ───────────────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('2) ', style: engBold),
                  underlineField(
                    label: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Name Of Accused :', style: engBold),
                        cache.has('lbl_accusedName')
                            ? cache.img('lbl_accusedName')
                            : pw.SizedBox(),
                      ],
                    ),
                    valKey: 'val_accusedName',
                    value: doc['accusedName'],
                    expand: true,
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 18),
                child: pw.Row(
                  children: [
                    underlineField(
                      label: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Age:', style: engBold),
                          cache.has('lbl_age')
                              ? cache.img('lbl_age')
                              : pw.SizedBox(),
                        ],
                      ),
                      valKey: 'val_accusedAge',
                      value: doc['accusedAge'],
                      width: 90,
                    ),
                    pw.SizedBox(width: 40),
                    underlineField(
                      label: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Sex:', style: engBold),
                          cache.has('lbl_sex')
                              ? cache.img('lbl_sex')
                              : pw.SizedBox(),
                        ],
                      ),
                      valKey: 'val_accusedSex',
                      value: doc['accusedSex'],
                      width: 110,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),

              // ── 3) Date and Time of Arrest ─────────────────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('3) ', style: engBold),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Date and Time of Arrest :-', style: engBold),
                      cache.has('lbl_arrestDateTime')
                          ? cache.img('lbl_arrestDateTime')
                          : pw.SizedBox(),
                    ],
                  ),
                  pw.SizedBox(width: 20),
                  underlineField(
                    label: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Date:', style: engBold),
                        cache.has('lbl_date_s')
                            ? cache.img('lbl_date_s')
                            : pw.SizedBox(),
                      ],
                    ),
                    valKey: 'val_arrestDate',
                    value: doc['arrestDate'],
                    width: 110,
                  ),
                  pw.SizedBox(width: 24),
                  underlineField(
                    label: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Time :', style: engBold),
                        cache.has('lbl_time')
                            ? cache.img('lbl_time')
                            : pw.SizedBox(),
                      ],
                    ),
                    valKey: 'val_arrestTime',
                    value: doc['arrestTime'],
                    width: 110,
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              // ── 4) Memorandum made by Accused ──────────────────────────
              pw.Row(
                children: [
                  pw.Text('4) Memorandum made by Accused: - ', style: engBold),
                  if (cache.has('lbl_memo_made'))
                    cache.img('lbl_memo_made')
                  else
                    pw.Text('(आरोपीने केलेले निवेदन: -)', style: valStyle),
                ],
              ),
              pw.SizedBox(height: 3),

              // Ruled Lines Box (~16 lines)
              pw.Column(
                children: List.generate(15, (index) {
                  final lineContent =
                      index < memoLines.length ? memoLines[index] : '';
                  final isCached = cache.has('memo_line_$index');

                  return pw.Container(
                    height: 16.5,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColors.grey600,
                          width: 0.6,
                        ),
                      ),
                    ),
                    alignment: pw.Alignment.bottomLeft,
                    child: lineContent.isNotEmpty
                        ? (isCached
                            ? cache.img('memo_line_$index')
                            : pw.Text(lineContent, style: valRegular))
                        : pw.SizedBox(),
                  );
                }),
              ),
              pw.SizedBox(height: 8),

              // ── 5) Place of Memorandum, Date, Time ─────────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('5) ', style: engBold),
                  underlineField(
                    label: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Place of Memorandum :-', style: engBold),
                        cache.has('lbl_place_memo')
                            ? cache.img('lbl_place_memo')
                            : pw.SizedBox(),
                      ],
                    ),
                    valKey: 'val_placeOfMemorandum',
                    value: doc['placeOfMemorandum'],
                    expand: true,
                  ),
                ],
              ),
              pw.SizedBox(height: 3),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 18),
                child: pw.Row(
                  children: [
                    underlineField(
                      label: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Date:', style: engBold),
                          cache.has('lbl_date_s')
                              ? cache.img('lbl_date_s')
                              : pw.SizedBox(),
                        ],
                      ),
                      valKey: 'val_memDate',
                      value: doc['memDate'],
                      width: 110,
                    ),
                    pw.SizedBox(width: 16),
                    underlineField(
                      label: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Time :', style: engBold),
                          cache.has('lbl_time_from')
                              ? cache.img('lbl_time_from')
                              : pw.SizedBox(),
                        ],
                      ),
                      valKey: 'val_memTimeFrom',
                      value: doc['memTimeFrom'],
                      width: 90,
                    ),
                    pw.SizedBox(width: 10),
                    underlineField(
                      label: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('to', style: engBold),
                          cache.has('lbl_time_to')
                              ? cache.img('lbl_time_to')
                              : pw.SizedBox(),
                        ],
                      ),
                      valKey: 'val_memTimeTo',
                      value: doc['memTimeTo'],
                      width: 90,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),

              // ── 6) Name and Address of Panchas & Signatures ────────────
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
                            pw.Text('6) Name and Address of Panchas: ',
                                style: engBold),
                            if (cache.has('lbl_panch_header'))
                              cache.img('lbl_panch_header')
                            else
                              pw.Text('(पंचांचे नांव व पत्ता)',
                                  style: valStyle),
                          ],
                        ),
                        pw.SizedBox(height: 3),
                        underlineField(
                          label: pw.Text('1) ', style: engBold),
                          valKey: 'val_panch1NameAddr',
                          value: doc['panch1NameAddr'],
                          expand: true,
                        ),
                        pw.SizedBox(height: 5),
                        underlineField(
                          label: pw.Text('2) ', style: engBold),
                          valKey: 'val_panch2NameAddr',
                          value: doc['panch2NameAddr'],
                          expand: true,
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Text('Signature: - ', style: engBold),
                            if (cache.has('lbl_sig_header'))
                              cache.img('lbl_sig_header')
                            else
                              pw.Text('(स्वाक्षरी)', style: valStyle),
                          ],
                        ),
                        pw.SizedBox(height: 3),
                        underlineField(
                          label: pw.Text('1) ', style: engBold),
                          valKey: 'val_panch1Sig',
                          value: doc['panch1Sig'],
                          expand: true,
                        ),
                        pw.SizedBox(height: 5),
                        underlineField(
                          label: pw.Text('2) ', style: engBold),
                          valKey: 'val_panch2Sig',
                          value: doc['panch2Sig'],
                          expand: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // ── 7) Signatures: Accused & Investigation Officer ─────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('7) Accused Signature and Thump',
                            style: engBold),
                        if (cache.has('lbl_accused_sig_thumb'))
                          cache.img('lbl_accused_sig_thumb')
                        else
                          pw.Text('   आरोपीची सही व अंगठा', style: valStyle),
                        pw.SizedBox(height: 25),
                        pw.Container(
                          height: 18,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(
                                  color: PdfColors.black, width: 0.8),
                            ),
                          ),
                          alignment: pw.Alignment.bottomCenter,
                          child: renderVal(
                              'val_part1AccusedSig', doc['part1AccusedSig']),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 30),
                  pw.Expanded(
                    flex: 6,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Signature of Investigation Officer',
                            style: engBold),
                        if (cache.has('lbl_io_header'))
                          cache.img('lbl_io_header')
                        else
                          pw.Text('तपासणी करणाऱ्या अधिकाऱ्याची नांव व सह्या',
                              style: valStyle),
                        pw.SizedBox(height: 3),
                        underlineField(
                          label: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Name:', style: engBold),
                              cache.has('lbl_name_mr')
                                  ? cache.img('lbl_name_mr')
                                  : pw.SizedBox(),
                            ],
                          ),
                          valKey: 'val_part1IoName',
                          value: doc['part1IoName'],
                          expand: true,
                        ),
                        pw.SizedBox(height: 3),
                        pw.Row(
                          children: [
                            underlineField(
                              label: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('Rank:', style: engBold),
                                  cache.has('lbl_rank_mr')
                                      ? cache.img('lbl_rank_mr')
                                      : pw.SizedBox(),
                                ],
                              ),
                              valKey: 'val_part1IoRank',
                              value: doc['part1IoRank'],
                              width: 100,
                            ),
                            pw.SizedBox(width: 8),
                            underlineField(
                              label: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('Number if any:', style: engBold),
                                  cache.has('lbl_no_mr')
                                      ? cache.img('lbl_no_mr')
                                      : pw.SizedBox(),
                                ],
                              ),
                              valKey: 'val_part1IoNo',
                              value: doc['part1IoNo'],
                              expand: true,
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 3),
                        underlineField(
                          label: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Posting and Address:', style: engBold),
                              cache.has('lbl_posting_mr')
                                  ? cache.img('lbl_posting_mr')
                                  : pw.SizedBox(),
                            ],
                          ),
                          valKey: 'val_part1IoPosting',
                          value: doc['part1IoPosting'],
                          expand: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PAGE 2: PART II (Image 3)
  // ──────────────────────────────────────────────────────────────────────────
  if (!isPartIOnly) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 26),
        build: (pw.Context context) {
          final furtherText = doc['furtherPanchanama']?.toString().trim() ?? '';
          final furtherLines = _splitTextIntoLines(furtherText, 95);

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── 8) Details of Further Panchanama ───────────────────────
              pw.Row(
                children: [
                  pw.Text('8) Details of Further Panchanama: ',
                      style: engBold.copyWith(fontSize: 10.5)),
                  if (cache.has('lbl_further_header'))
                    cache.img('lbl_further_header')
                  else
                    pw.Text('(पंचनाम्याचा पुढील भाग):-', style: valStyle),
                ],
              ),
              pw.SizedBox(height: 5),

              // Ruled Lines Box (~20 lines)
              pw.Column(
                children: List.generate(20, (index) {
                  final lineContent =
                      index < furtherLines.length ? furtherLines[index] : '';
                  final isCached = cache.has('further_line_$index');

                  return pw.Container(
                    height: 18.0,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColors.grey600,
                          width: 0.6,
                        ),
                      ),
                    ),
                    alignment: pw.Alignment.bottomLeft,
                    child: lineContent.isNotEmpty
                        ? (isCached
                            ? cache.img('further_line_$index')
                            : pw.Text(lineContent, style: valRegular))
                        : pw.SizedBox(),
                  );
                }),
              ),
              pw.SizedBox(height: 10),

              // Date and Time Row
              pw.Row(
                children: [
                  underlineField(
                    label: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Date:', style: engBold),
                        cache.has('lbl_date_s')
                            ? cache.img('lbl_date_s')
                            : pw.SizedBox(),
                      ],
                    ),
                    valKey: 'val_furtherDate',
                    value: doc['furtherDate'],
                    width: 120,
                  ),
                  pw.SizedBox(width: 24),
                  underlineField(
                    label: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Time :', style: engBold),
                        cache.has('lbl_time_from')
                            ? cache.img('lbl_time_from')
                            : pw.SizedBox(),
                      ],
                    ),
                    valKey: 'val_furtherTimeFrom',
                    value: doc['furtherTimeFrom'],
                    width: 95,
                  ),
                  pw.SizedBox(width: 10),
                  underlineField(
                    label: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('to', style: engBold),
                        cache.has('lbl_time_to')
                            ? cache.img('lbl_time_to')
                            : pw.SizedBox(),
                      ],
                    ),
                    valKey: 'val_furtherTimeTo',
                    value: doc['furtherTimeTo'],
                    width: 95,
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // ── 9) Name and Address of Panchas & Signatures ────────────
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
                            pw.Text('9) Name and Address of Panchas:- ',
                                style: engBold),
                            if (cache.has('lbl_panch_header'))
                              cache.img('lbl_panch_header')
                            else
                              pw.Text('(पंचांचे नांव व पत्ता)',
                                  style: valStyle),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        underlineField(
                          label: pw.Text('1) ', style: engBold),
                          valKey: 'val_furtherPanch1NameAddr',
                          value: doc['furtherPanch1NameAddr'],
                          expand: true,
                        ),
                        pw.SizedBox(height: 6),
                        underlineField(
                          label: pw.Text('2) ', style: engBold),
                          valKey: 'val_furtherPanch2NameAddr',
                          value: doc['furtherPanch2NameAddr'],
                          expand: true,
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          children: [
                            pw.Text('Signature: - ', style: engBold),
                            if (cache.has('lbl_sig_header'))
                              cache.img('lbl_sig_header')
                            else
                              pw.Text('(स्वाक्षरी)', style: valStyle),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        underlineField(
                          label: pw.Text('1) ', style: engBold),
                          valKey: 'val_furtherPanch1Sig',
                          value: doc['furtherPanch1Sig'],
                          expand: true,
                        ),
                        pw.SizedBox(height: 6),
                        underlineField(
                          label: pw.Text('2) ', style: engBold),
                          valKey: 'val_furtherPanch2Sig',
                          value: doc['furtherPanch2Sig'],
                          expand: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 18),

              // ── 10) Signatures: Accused & Investigation Officer ────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 5,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('10) Accused Signature and Thump',
                            style: engBold),
                        if (cache.has('lbl_accused_sig_thumb'))
                          cache.img('lbl_accused_sig_thumb')
                        else
                          pw.Text('    आरोपीची सही व अंगठा', style: valStyle),
                        pw.SizedBox(height: 30),
                        pw.Container(
                          height: 18,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(
                                  color: PdfColors.black, width: 0.8),
                            ),
                          ),
                          alignment: pw.Alignment.bottomCenter,
                          child: renderVal('val_accusedSig', doc['accusedSig']),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 30),
                  pw.Expanded(
                    flex: 6,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Signature of Investigation Officer',
                            style: engBold),
                        if (cache.has('lbl_io_header'))
                          cache.img('lbl_io_header')
                        else
                          pw.Text('तपासणी करणाऱ्या अधिकाऱ्याची नांव व सह्या',
                              style: valStyle),
                        pw.SizedBox(height: 4),
                        underlineField(
                          label: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Name:', style: engBold),
                              cache.has('lbl_name_mr')
                                  ? cache.img('lbl_name_mr')
                                  : pw.SizedBox(),
                            ],
                          ),
                          valKey: 'val_ioName',
                          value: doc['ioName'],
                          expand: true,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          children: [
                            underlineField(
                              label: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('Rank:', style: engBold),
                                  cache.has('lbl_rank_mr')
                                      ? cache.img('lbl_rank_mr')
                                      : pw.SizedBox(),
                                ],
                              ),
                              valKey: 'val_ioRank',
                              value: doc['ioRank'],
                              width: 100,
                            ),
                            pw.SizedBox(width: 8),
                            underlineField(
                              label: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('Number if any:', style: engBold),
                                  cache.has('lbl_no_mr')
                                      ? cache.img('lbl_no_mr')
                                      : pw.SizedBox(),
                                ],
                              ),
                              valKey: 'val_ioNo',
                              value: doc['ioNo'],
                              expand: true,
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        underlineField(
                          label: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Posting and Address:', style: engBold),
                              cache.has('lbl_posting_mr')
                                  ? cache.img('lbl_posting_mr')
                                  : pw.SizedBox(),
                            ],
                          ),
                          valKey: 'val_ioPosting',
                          value: doc['ioPosting'],
                          expand: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.bottomRight,
                child: pw.Text('M.R.W', style: engBold.copyWith(fontSize: 8)),
              ),
            ],
          );
        },
      ),
    );
  }

  return pdf.save();
}

List<String> _splitTextIntoLines(String text, int maxCharsPerLine) {
  if (text.isEmpty) return [];
  final rawLines = text.split('\n');
  final result = <String>[];
  for (final raw in rawLines) {
    if (raw.length <= maxCharsPerLine) {
      result.add(raw);
    } else {
      final words = raw.split(' ');
      var current = '';
      for (final word in words) {
        if (current.isEmpty) {
          current = word;
        } else if ((current.length + word.length + 1) <= maxCharsPerLine) {
          current += ' $word';
        } else {
          result.add(current);
          current = word;
        }
      }
      if (current.isNotEmpty) result.add(current);
    }
  }
  return result;
}

Future<MarathiImageCache> _preRenderAllMarathi(Map<String, dynamic> doc) async {
  final cache = MarathiImageCache();

  final headerStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  final labelStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 9.5,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  final subLabelStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 7.5,
    fontWeight: FontWeight.normal,
    color: Colors.black87,
  );

  final valueStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 9.5,
    fontWeight: FontWeight.bold,
    color: Colors.blue.shade900,
  );

  await GoogleFonts.pendingFonts();

  Future<void> addLbl(String key, String text, TextStyle style,
      {double maxWidth = 500}) async {
    await cache.add(key, text, style, maxWidth: maxWidth);
  }

  Future<void> addVal(String key, String? val, {double maxWidth = 500}) async {
    final text = val?.trim() ?? '';
    if (containsDevanagari(text)) {
      await cache.add(key, text, valueStyle, maxWidth: maxWidth);
    }
  }

  // Headers
  await addLbl('title_mr', '(आरोपीचे निवेदन पंचनामा)', headerStyle);
  await addLbl(
    'subtitle_panchanama',
    '( Panchanama u/s 23 (2) Bhartiya Saksh Adhiniyam, 2023 कलम २३ (२) भारतीय साक्ष अधिनियम २०२३ )',
    labelStyle.copyWith(fontSize: 8.5),
  );

  // Sub-labels for Section 1
  await addLbl('lbl_dist', 'जिल्हा', subLabelStyle);
  await addLbl('lbl_ps', 'पोलीस ठाणे', subLabelStyle);
  await addLbl('lbl_year', 'वर्ष', subLabelStyle);
  await addLbl('lbl_firNo', 'गुन्हा क्र.', subLabelStyle);
  await addLbl('lbl_date', 'दिनांक', subLabelStyle);

  // Sub-labels for Section 2 & 3
  await addLbl('lbl_accusedName', 'आरोपीचे नाव व पत्ता', subLabelStyle);
  await addLbl('lbl_age', 'वय', subLabelStyle);
  await addLbl('lbl_sex', 'लिंग', subLabelStyle);
  await addLbl('lbl_arrestDateTime', 'अटकेची तारीख व वेळ', subLabelStyle);
  await addLbl('lbl_date_s', 'तारीख', subLabelStyle);
  await addLbl('lbl_time', 'वेळ', subLabelStyle);

  // Section 4
  await addLbl('lbl_memo_made', '(आरोपीने केलेले निवेदन: -)', labelStyle);

  // Section 5
  await addLbl(
      'lbl_place_memo', 'पंचनाम्याचे / निवेदनाचे ठिकाण', subLabelStyle);
  await addLbl('lbl_time_from', 'वेळ पासून', subLabelStyle);
  await addLbl('lbl_time_to', 'वेळ पर्यंत', subLabelStyle);

  // Section 6 & 9 (Panchas)
  await addLbl('lbl_panch_header', '(पंचांचे नांव व पत्ता)', labelStyle);
  await addLbl('lbl_sig_header', '(स्वाक्षरी)', labelStyle);

  // Section 7 & 10 (Signatures)
  await addLbl('lbl_accused_sig_thumb', 'आरोपीची सही व अंगठा', subLabelStyle);
  await addLbl(
      'lbl_io_header', 'तपासणी करणाऱ्या अधिकाऱ्याची नांव व सह्या', labelStyle);
  await addLbl('lbl_name_mr', 'नांव', subLabelStyle);
  await addLbl('lbl_rank_mr', 'पद', subLabelStyle);
  await addLbl('lbl_no_mr', 'बकल क्र.', subLabelStyle);
  await addLbl('lbl_posting_mr', 'नेमणूक व पत्ता', subLabelStyle);

  // Section 8
  await addLbl('lbl_further_header', '(पंचनाम्याचा पुढील भाग):-', labelStyle);

  // Values (Devanagari inputs)
  await addVal('val_dist', doc['dist']);
  await addVal('val_ps', doc['ps']);
  await addVal('val_year', doc['year']);
  await addVal('val_firNo', doc['firNo']);
  await addVal('val_firDate', doc['firDate']);
  await addVal('val_accusedName', doc['accusedName']);
  await addVal('val_accusedAge', doc['accusedAge']);
  await addVal('val_accusedSex', doc['accusedSex']);
  await addVal('val_arrestDate', doc['arrestDate']);
  await addVal('val_arrestTime', doc['arrestTime']);
  await addVal('val_placeOfMemorandum', doc['placeOfMemorandum']);
  await addVal('val_memDate', doc['memDate']);
  await addVal('val_memTimeFrom', doc['memTimeFrom']);
  await addVal('val_memTimeTo', doc['memTimeTo']);
  await addVal('val_panch1NameAddr', doc['panch1NameAddr']);
  await addVal('val_panch1Sig', doc['panch1Sig']);
  await addVal('val_panch2NameAddr', doc['panch2NameAddr']);
  await addVal('val_panch2Sig', doc['panch2Sig']);
  await addVal('val_part1AccusedSig', doc['part1AccusedSig']);
  await addVal('val_part1IoName', doc['part1IoName']);
  await addVal('val_part1IoRank', doc['part1IoRank']);
  await addVal('val_part1IoNo', doc['part1IoNo']);
  await addVal('val_part1IoPosting', doc['part1IoPosting']);

  await addVal('val_furtherDate', doc['furtherDate']);
  await addVal('val_furtherTimeFrom', doc['furtherTimeFrom']);
  await addVal('val_furtherTimeTo', doc['furtherTimeTo']);
  await addVal('val_furtherPanch1NameAddr', doc['furtherPanch1NameAddr']);
  await addVal('val_furtherPanch1Sig', doc['furtherPanch1Sig']);
  await addVal('val_furtherPanch2NameAddr', doc['furtherPanch2NameAddr']);
  await addVal('val_furtherPanch2Sig', doc['furtherPanch2Sig']);
  await addVal('val_accusedSig', doc['accusedSig']);
  await addVal('val_ioName', doc['ioName']);
  await addVal('val_ioRank', doc['ioRank']);
  await addVal('val_ioNo', doc['ioNo']);
  await addVal('val_ioPosting', doc['ioPosting']);

  // Multiline text rendering
  final memoText = doc['accusedMemorandum']?.toString().trim() ?? '';
  final memoLines = _splitTextIntoLines(memoText, 95);
  for (int i = 0; i < memoLines.length; i++) {
    final line = memoLines[i];
    if (containsDevanagari(line)) {
      await cache.add('memo_line_$i', line, valueStyle, maxWidth: 500);
    }
  }

  final furtherText = doc['furtherPanchanama']?.toString().trim() ?? '';
  final furtherLines = _splitTextIntoLines(furtherText, 95);
  for (int i = 0; i < furtherLines.length; i++) {
    final line = furtherLines[i];
    if (containsDevanagari(line)) {
      await cache.add('further_line_$i', line, valueStyle, maxWidth: 500);
    }
  }

  return cache;
}
