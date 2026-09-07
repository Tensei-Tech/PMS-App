import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'marathi_text_renderer.dart';

Future<void> previewMuddemalPavtiPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final bytes = await generateMuddemalPavtiPdf(doc);
  if (!context.mounted) return;
  final fileName =
      'Muddemal_Pavti_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

Future<Uint8List> generateMuddemalPavtiPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final lora = await PdfGoogleFonts.loraRegular();
  final loraBold = await PdfGoogleFonts.loraBold();
  final cache = await _preRenderAllMarathi(doc);

  final pw.TextStyle englishValueStyle = pw.TextStyle(
    font: loraBold,
    fontSize: 9.5,
    color: PdfColors.blue900,
  );

  pw.Widget renderField(String key, String? val) {
    final text = val?.trim() ?? '';
    if (text.isEmpty) {
      return pw.SizedBox();
    }
    if (cache.has(key)) {
      return cache.img(key);
    }
    return pw.Text(text, style: englishValueStyle);
  }

  pw.Widget mLbl(String key) {
    if (cache.has(key)) return cache.img(key);
    return pw.SizedBox();
  }

  // Retrieve raw items
  final List<dynamic> rawItems = (doc['muddemalItems'] is List)
      ? (doc['muddemalItems'] as List)
      : [];

  final List<Map<String, String>> items = [];
  if (rawItems.isNotEmpty) {
    for (int i = 0; i < rawItems.length; i++) {
      final m = rawItems[i];
      if (m is Map) {
        items.add({
          'description': m['description']?.toString() ?? '',
          'estimatedValue': m['estimatedValue']?.toString() ?? '',
          'malNumber': m['malNumber']?.toString() ?? '',
          'seizedFrom': m['seizedFrom']?.toString() ?? '',
        });
      }
    }
  } else if ((doc['propertyDescription']?.toString() ?? '').isNotEmpty ||
      (doc['propertyValue']?.toString() ?? '').isNotEmpty) {
    items.add({
      'description': doc['propertyDescription']?.toString() ?? '',
      'estimatedValue': doc['propertyValue']?.toString() ?? '',
      'malNumber': doc['malNumber']?.toString() ?? '',
      'seizedFrom': doc['seizedFrom']?.toString() ?? '',
    });
  }

  // Ensure at least 4 rows for proper visual receipt layout
  while (items.length < 4) {
    items.add({
      'description': '',
      'estimatedValue': '',
      'malNumber': '',
      'seizedFrom': '',
    });
  }

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Centered Title
            pw.Center(
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  mLbl('title'),
                  pw.SizedBox(height: 2),
                  pw.Container(
                    width: 140,
                    height: 1,
                    color: PdfColors.black,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 22),

            // 1) Police Station & District
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                mLbl('lbl_1_ps'),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                      ),
                    ),
                    padding: const pw.EdgeInsets.only(bottom: 2, left: 4),
                    child: renderField('val_policeStation', doc['policeStation']?.toString()),
                  ),
                ),
                pw.SizedBox(width: 10),
                mLbl('lbl_1_district'),
                pw.SizedBox(width: 6),
                pw.Container(
                  width: 90,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                    ),
                  ),
                  padding: const pw.EdgeInsets.only(bottom: 2, left: 4),
                  child: renderField('val_district', doc['district']?.toString() ?? 'यवतमाळ'),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // 2) Crime No & Section
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                mLbl('lbl_2_cr_no'),
                pw.SizedBox(width: 6),
                pw.Container(
                  width: 120,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                    ),
                  ),
                  padding: const pw.EdgeInsets.only(bottom: 2, left: 4),
                  child: renderField(
                    'val_crNoYear',
                    doc['crNoYear']?.toString() ?? doc['crNo']?.toString(),
                  ),
                ),
                pw.SizedBox(width: 12),
                mLbl('lbl_2_section'),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                      ),
                    ),
                    padding: const pw.EdgeInsets.only(bottom: 2, left: 4),
                    child: renderField('val_section', doc['section']?.toString()),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // 3) Investigating Officer, Police Station & District
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                mLbl('lbl_3_io'),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                      ),
                    ),
                    padding: const pw.EdgeInsets.only(bottom: 2, left: 4),
                    child: renderField(
                      'val_investigatingOfficer',
                      doc['investigatingOfficer']?.toString() ?? doc['ioName']?.toString(),
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                mLbl('lbl_3_ps'),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                      ),
                    ),
                    padding: const pw.EdgeInsets.only(bottom: 2, left: 4),
                    child: renderField(
                      'val_ioPoliceStation',
                      doc['ioPoliceStation']?.toString() ?? doc['policeStation']?.toString(),
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                mLbl('lbl_3_district'),
                pw.SizedBox(width: 6),
                pw.Container(
                  width: 80,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                    ),
                  ),
                  padding: const pw.EdgeInsets.only(bottom: 2, left: 4),
                  child: renderField(
                    'val_ioDistrict',
                    doc['ioDistrict']?.toString() ?? 'यवतमाळ',
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // 4) Accused Name
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                mLbl('lbl_4_accused'),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                      ),
                    ),
                    padding: const pw.EdgeInsets.only(bottom: 2, left: 4),
                    child: renderField('val_accusedName', doc['accusedName']?.toString()),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // 5) Seizure Date & Mal Number
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                mLbl('lbl_5_date'),
                pw.SizedBox(width: 6),
                pw.Container(
                  width: 140,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                    ),
                  ),
                  padding: const pw.EdgeInsets.only(bottom: 2, left: 4),
                  child: renderField(
                    'val_seizureDate',
                    doc['seizureDate']?.toString() ?? doc['seizedDate']?.toString() ?? doc['date']?.toString(),
                  ),
                ),
                pw.SizedBox(width: 20),
                mLbl('lbl_5_mal_no'),
                pw.SizedBox(width: 6),
                pw.Container(
                  width: 130,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
                    ),
                  ),
                  padding: const pw.EdgeInsets.only(bottom: 2, left: 4),
                  child: renderField(
                    'val_malNumber',
                    doc['malNumber']?.toString() ?? doc['receiptNo']?.toString(),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 22),

            // Table of Seized Goods
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
              columnWidths: const {
                0: pw.FlexColumnWidth(3.4),
                1: pw.FlexColumnWidth(1.4),
                2: pw.FlexColumnWidth(1.4),
                3: pw.FlexColumnWidth(2.6),
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Container(
                      alignment: pw.Alignment.center,
                      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: mLbl('th_desc'),
                    ),
                    pw.Container(
                      alignment: pw.Alignment.center,
                      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: mLbl('th_val'),
                    ),
                    pw.Container(
                      alignment: pw.Alignment.center,
                      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      child: pw.Column(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          mLbl('th_mal_no'),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            '....../२०....',
                            style: pw.TextStyle(font: lora, fontSize: 8.5, color: PdfColors.grey700),
                          ),
                        ],
                      ),
                    ),
                    pw.Container(
                      alignment: pw.Alignment.center,
                      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: mLbl('th_seized_from'),
                    ),
                  ],
                ),

                // Data Rows
                for (int i = 0; i < items.length; i++)
                  pw.TableRow(
                    children: [
                      pw.Container(
                        constraints: const pw.BoxConstraints(minHeight: 38),
                        padding: const pw.EdgeInsets.all(4),
                        alignment: pw.Alignment.topLeft,
                        child: renderField('item_${i}_desc', items[i]['description']),
                      ),
                      pw.Container(
                        constraints: const pw.BoxConstraints(minHeight: 38),
                        padding: const pw.EdgeInsets.all(4),
                        alignment: pw.Alignment.topLeft,
                        child: renderField('item_${i}_val', items[i]['estimatedValue']),
                      ),
                      pw.Container(
                        constraints: const pw.BoxConstraints(minHeight: 38),
                        padding: const pw.EdgeInsets.all(4),
                        alignment: pw.Alignment.topLeft,
                        child: renderField('item_${i}_mal', items[i]['malNumber']),
                      ),
                      pw.Container(
                        constraints: const pw.BoxConstraints(minHeight: 38),
                        padding: const pw.EdgeInsets.all(4),
                        alignment: pw.Alignment.topLeft,
                        child: renderField('item_${i}_from', items[i]['seizedFrom']),
                      ),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 50),

            // Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // Head Moharir
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 150,
                      alignment: pw.Alignment.center,
                      child: renderField(
                        'val_headMoharirSign',
                        doc['headMoharirSign']?.toString() ?? doc['receiverName']?.toString(),
                      ),
                    ),
                    pw.Container(
                      width: 150,
                      height: 0.8,
                      color: PdfColors.black,
                      margin: const pw.EdgeInsets.only(top: 2, bottom: 6),
                    ),
                    mLbl('sig_head_moharir'),
                  ],
                ),

                // Investigating Officer
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 150,
                      alignment: pw.Alignment.center,
                      child: renderField(
                        'val_ioSign',
                        doc['ioSign']?.toString() ?? doc['ioName']?.toString(),
                      ),
                    ),
                    pw.Container(
                      width: 150,
                      height: 0.8,
                      color: PdfColors.black,
                      margin: const pw.EdgeInsets.only(top: 2, bottom: 6),
                    ),
                    mLbl('sig_io'),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

Future<MarathiImageCache> _preRenderAllMarathi(Map<String, dynamic> doc) async {
  final pairs = <String, String>{
    'title': '—:: मुद्देमाल पावती ::—',
    'lbl_1_ps': '१) पोलीस स्टेशन :—',
    'lbl_1_district': 'जिल्हा',
    'lbl_2_cr_no': '२) अप क्रमांक :—',
    'lbl_2_section': 'कलम',
    'lbl_3_io': '३) अन्वेषन अधिकारी:—',
    'lbl_3_ps': 'पोलीस स्टेशन',
    'lbl_3_district': 'जिल्हा',
    'lbl_4_accused': '४) आरोपी नांव :—',
    'lbl_5_date': '५) जप्त माल दिनांक :—',
    'lbl_5_mal_no': 'माल नंबर :—',
    'th_desc': 'जप्त मालाचे विवरण',
    'th_val': 'मुल्य अंदाजे',
    'th_mal_no': 'माल नंबर',
    'th_seized_from': 'कोणाकडुन जप्त केले',
    'sig_head_moharir': 'हेडमोहरर सही',
    'sig_io': 'तपास अधिकारी',
  };

  void addIfDevanagari(String k, dynamic v) {
    final s = v?.toString().trim() ?? '';
    if (s.isNotEmpty && containsDevanagari(s)) {
      pairs[k] = s;
    }
  }

  // Header / Form values
  addIfDevanagari('val_policeStation', doc['policeStation']);
  addIfDevanagari('val_district', doc['district'] ?? 'यवतमाळ');
  addIfDevanagari('val_crNoYear', doc['crNoYear'] ?? doc['crNo']);
  addIfDevanagari('val_section', doc['section']);
  addIfDevanagari('val_investigatingOfficer', doc['investigatingOfficer'] ?? doc['ioName']);
  addIfDevanagari('val_ioPoliceStation', doc['ioPoliceStation'] ?? doc['policeStation']);
  addIfDevanagari('val_ioDistrict', doc['ioDistrict'] ?? 'यवतमाळ');
  addIfDevanagari('val_accusedName', doc['accusedName']);
  addIfDevanagari('val_seizureDate', doc['seizureDate'] ?? doc['seizedDate'] ?? doc['date']);
  addIfDevanagari('val_malNumber', doc['malNumber'] ?? doc['receiptNo']);
  addIfDevanagari('val_headMoharirSign', doc['headMoharirSign'] ?? doc['receiverName']);
  addIfDevanagari('val_ioSign', doc['ioSign'] ?? doc['ioName']);

  // Table items
  final List<dynamic> rawItems = (doc['muddemalItems'] is List)
      ? (doc['muddemalItems'] as List)
      : [];

  if (rawItems.isNotEmpty) {
    for (int i = 0; i < rawItems.length; i++) {
      final m = rawItems[i];
      if (m is Map) {
        addIfDevanagari('item_${i}_desc', m['description']);
        addIfDevanagari('item_${i}_val', m['estimatedValue']);
        addIfDevanagari('item_${i}_mal', m['malNumber']);
        addIfDevanagari('item_${i}_from', m['seizedFrom']);
      }
    }
  } else {
    addIfDevanagari('item_0_desc', doc['propertyDescription']);
    addIfDevanagari('item_0_val', doc['propertyValue']);
    addIfDevanagari('item_0_mal', doc['malNumber']);
    addIfDevanagari('item_0_from', doc['seizedFrom']);
  }

  final boldKeys = {
    'title',
    'lbl_1_ps',
    'lbl_1_district',
    'lbl_2_cr_no',
    'lbl_2_section',
    'lbl_3_io',
    'lbl_3_ps',
    'lbl_3_district',
    'lbl_4_accused',
    'lbl_5_date',
    'lbl_5_mal_no',
    'th_desc',
    'th_val',
    'th_mal_no',
    'th_seized_from',
    'sig_head_moharir',
    'sig_io',
  };

  final cache = MarathiImageCache();
  await GoogleFonts.pendingFonts();

  for (final entry in pairs.entries) {
    final isBold = boldKeys.contains(entry.key);
    final double fs = entry.key == 'title'
        ? 14.0
        : (entry.key.startsWith('th_')
            ? 10.5
            : (entry.key.startsWith('sig_') ? 11.0 : 9.5));

    final color = entry.key.startsWith('val_') || entry.key.startsWith('item_')
        ? const Color(0xFF0D47A1)
        : Colors.black87;

    final double maxW = entry.key == 'title'
        ? 300
        : (entry.key.contains('desc')
            ? 220
            : (entry.key.contains('from') ? 160 : 180));

    await cache.add(
      entry.key,
      entry.value,
      GoogleFonts.notoSansDevanagari(
        fontSize: fs,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        color: color,
      ),
      maxWidth: maxW,
    );
  }

  return cache;
}
