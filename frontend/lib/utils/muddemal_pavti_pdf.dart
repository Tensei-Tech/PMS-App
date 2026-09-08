import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
  final devanagari = await PdfGoogleFonts.notoSansDevanagariRegular();
  final devanagariBold = await PdfGoogleFonts.notoSansDevanagariBold();

  final regular = pw.TextStyle(
    font: devanagari,
    fontSize: 10.5,
    lineSpacing: 4,
  );
  final bold = pw.TextStyle(
    font: devanagariBold,
    fontSize: 10.5,
    fontWeight: pw.FontWeight.bold,
  );
  final headerTitle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 15,
    fontWeight: pw.FontWeight.bold,
    decoration: pw.TextDecoration.underline,
  );

  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  final ps = v('policeStation');
  final dist = v('district', 'यवतमाळ');
  final crimeNo = v('crimeNo', '........../२०......');
  final actSec =
      v('actSec', '________________________________________________');
  final ioName = v('ioName');
  final ioPs = v('ioPs');
  final ioDist = v('ioDist', 'यवतमाळ');
  final accusedName = v('accusedName',
      '____________________________________________________________________');
  final seizureDate = v('seizureDate', '......./ ........./२०.....');
  final propertyNo = v('propertyNo', '........../२०......');

  final items = (doc['items'] is List) ? (doc['items'] as List) : [];

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ── TITLE ──
            pw.Center(
              child: pw.Text('-:: मुद्देमाल पावती ::-', style: headerTitle),
            ),
            pw.SizedBox(height: 24),

            // ── ROW 1: पोलीस स्टेशन ──
            pw.Row(
              children: [
                pw.Text('१) पोलीस स्टेशन   :-  ', style: bold),
                pw.Expanded(
                  child: pw.Text(
                    ps.isNotEmpty ? ps : '______________________',
                    style: regular,
                  ),
                ),
                pw.Text('जिल्हा $dist', style: bold),
              ],
            ),
            pw.SizedBox(height: 12),

            // ── ROW 2: अप क्रमांक व कलम ──
            pw.Row(
              children: [
                pw.Text('२) अप क्रमांक :- ', style: bold),
                pw.Text(crimeNo, style: regular),
                pw.SizedBox(width: 16),
                pw.Text('कलम ', style: bold),
                pw.Expanded(
                  child: pw.Text(actSec, style: regular),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // ── ROW 3: अन्वेषन अधिकारी ──
            pw.Row(
              children: [
                pw.Text('३) अन्वेषन अधिकारी:- ', style: bold),
                pw.Expanded(
                  child: pw.Text(
                    ioName.isNotEmpty ? ioName : '______________________',
                    style: regular,
                  ),
                ),
                pw.Text('पोलीस स्टेशन ', style: bold),
                pw.Text(
                  ioPs.isNotEmpty ? ioPs : '________',
                  style: regular,
                ),
                pw.SizedBox(width: 8),
                pw.Text('जिल्हा $ioDist', style: bold),
              ],
            ),
            pw.SizedBox(height: 12),

            // ── ROW 4: आरोपी नांव ──
            pw.Row(
              children: [
                pw.Text('४) आरोपी नांव :- ', style: bold),
                pw.Expanded(
                  child: pw.Text(accusedName, style: regular),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // ── ROW 5: जप्त माल दिनांक व माल नंबर ──
            pw.Row(
              children: [
                pw.Text('५) जप्त माल दिनांक :- ', style: bold),
                pw.Text(seizureDate, style: regular),
                pw.SizedBox(width: 32),
                pw.Text('माल नंबर :- ', style: bold),
                pw.Text(propertyNo, style: regular),
              ],
            ),
            pw.SizedBox(height: 20),

            // ── MAIN TABLE ──
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 1),
              columnWidths: const {
                0: pw.FlexColumnWidth(4),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(2),
                3: pw.FlexColumnWidth(3),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                  ),
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 6, horizontal: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text('जप्त मालाचे विवरण', style: bold),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 6, horizontal: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text('मुल्य अंदाजे', style: bold),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 6, horizontal: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text('माल नंबर', style: bold),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          vertical: 6, horizontal: 4),
                      alignment: pw.Alignment.center,
                      child: pw.Text('कोणाकडुन जप्त केले', style: bold),
                    ),
                  ],
                ),

                // Property Rows
                if (items.isEmpty)
                  pw.TableRow(
                    children: [
                      pw.Container(
                        height: 240,
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('', style: regular),
                      ),
                      pw.Container(
                        height: 240,
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('', style: regular),
                      ),
                      pw.Container(
                        height: 240,
                        padding: const pw.EdgeInsets.all(6),
                        alignment: pw.Alignment.topCenter,
                        child: pw.Text('......./२०....', style: regular),
                      ),
                      pw.Container(
                        height: 240,
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('', style: regular),
                      ),
                    ],
                  )
                else
                  for (final item in items)
                    pw.TableRow(
                      children: [
                        pw.Container(
                          constraints: const pw.BoxConstraints(minHeight: 180),
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            item['description']?.toString() ?? '',
                            style: regular,
                          ),
                        ),
                        pw.Container(
                          constraints: const pw.BoxConstraints(minHeight: 180),
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            item['estimatedValue']?.toString() ?? '',
                            style: regular,
                          ),
                        ),
                        pw.Container(
                          constraints: const pw.BoxConstraints(minHeight: 180),
                          padding: const pw.EdgeInsets.all(6),
                          alignment: pw.Alignment.topCenter,
                          child: pw.Text(
                            (item['propertyNo']?.toString().isNotEmpty ?? false)
                                ? item['propertyNo'].toString()
                                : '......./२०....',
                            style: regular,
                          ),
                        ),
                        pw.Container(
                          constraints: const pw.BoxConstraints(minHeight: 180),
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            item['seizedFrom']?.toString() ?? '',
                            style: regular,
                          ),
                        ),
                      ],
                    ),
              ],
            ),
            pw.Spacer(),

            // ── SIGNATURES ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Text('हेडमोहरर सही', style: bold),
                    if (v('headMohararSig').isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(v('headMohararSig'), style: regular),
                    ],
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('तपास अधिकारी', style: bold),
                    if (v('investigatingOfficerSig').isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(v('investigatingOfficerSig'), style: regular),
                    ],
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            // ── MRW FOOTER ──
            pw.Align(
              alignment: pw.Alignment.bottomRight,
              child: pw.Text(
                'M.R.W',
                style: pw.TextStyle(
                  font: devanagari,
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}
