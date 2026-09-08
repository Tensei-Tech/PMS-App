import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> previewCheharePattiPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final bytes = await generateCheharePattiPdf(doc);
  if (!context.mounted) return;
  final fileName = 'Chehare_Patti_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

Future<Uint8List> generateCheharePattiPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final devanagari = await PdfGoogleFonts.notoSansDevanagariRegular();
  final devanagariBold = await PdfGoogleFonts.notoSansDevanagariBold();

  final regular = pw.TextStyle(
    font: devanagari,
    fontSize: 8.5,
  );
  final bold = pw.TextStyle(
    font: devanagariBold,
    fontSize: 8.5,
    fontWeight: pw.FontWeight.bold,
  );
  final titleStyle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 13,
    fontWeight: pw.FontWeight.bold,
    decoration: pw.TextDecoration.underline,
  );

  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  pw.TableRow buildRow(String no, String title, pw.Widget content,
      {bool isHeader = false}) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
        ),
      ),
      children: [
        pw.Container(
          width: 28,
          padding: const pw.EdgeInsets.symmetric(vertical: 2.2, horizontal: 2),
          alignment: pw.Alignment.center,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              right: pw.BorderSide(color: PdfColors.black, width: 0.5),
            ),
          ),
          child: pw.Text(no, style: isHeader ? bold : regular),
        ),
        pw.Container(
          width: 175,
          padding: const pw.EdgeInsets.symmetric(vertical: 2.2, horizontal: 4),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              right: pw.BorderSide(color: PdfColors.black, width: 0.5),
            ),
          ),
          child: pw.Text(title, style: isHeader ? bold : bold),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.2, horizontal: 4),
          child: content,
        ),
      ],
    );
  }

  pw.TableRow buildSimpleTextRow(String no, String title, String key) {
    return buildRow(
      no,
      title,
      pw.Text(v(key), style: regular),
    );
  }

  final dateStr = v('date', '......./ ...../ २०.......');
  final ps = v('policeStation');
  final district = v('district', 'यवतमाळ');

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      build: (pw.Context context) {
        return [
          // ── TOP BAR ──
          pw.Stack(
            children: [
              pw.Align(
                alignment: pw.Alignment.topRight,
                child: pw.Text('दिनांक $dateStr', style: regular),
              ),
              pw.Center(
                child: pw.Text('चेहरे पट्टी', style: titleStyle),
              ),
            ],
          ),
          pw.SizedBox(height: 6),

          // ── SUBHEADER ──
          pw.Center(
            child: pw.Text(
              'पोलीस स्टेशन :- ____________________जिल्हा $district'.replaceAll(
                '____________________',
                ps.isNotEmpty ? ps : '____________________',
              ),
              style: bold.copyWith(fontSize: 9.5),
            ),
          ),
          pw.SizedBox(height: 8),

          // ── TABLE ──
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
            columnWidths: const {
              0: pw.FixedColumnWidth(28),
              1: pw.FixedColumnWidth(175),
              2: pw.FlexColumnWidth(),
            },
            children: [
              // Header
              buildRow('अ.क्र.', 'विवरण', pw.Text('', style: bold), isHeader: true),

              // 1. CR No & Section
              buildRow(
                '१.',
                'अप.क्र. व कलम',
                pw.Row(
                  children: [
                    pw.Text(
                      v('crNo', '........./२०.....'),
                      style: regular,
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text('कलम ', style: bold),
                    pw.Expanded(
                      child: pw.Text(
                        v('actSec', '....................................................'),
                        style: regular,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Accused Details
              buildRow(
                '२.',
                'आरोपीचे नांव व पत्ता मो नं',
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      v('accusedDetails', '___________________________________________________________________\n___________________________________________________________________\n___________________________________________________________________'),
                      style: regular,
                    ),
                  ],
                ),
              ),

              // 3-33 Rows
              buildSimpleTextRow('३.', 'लिंग', 'gender'),
              buildSimpleTextRow('४.', 'धर्म', 'religion'),
              buildSimpleTextRow('५.', 'जात', 'caste'),
              buildSimpleTextRow('६.', 'वय', 'age'),
              buildSimpleTextRow('७.', 'शिक्षण', 'education'),
              buildSimpleTextRow('८.', 'व्यवसाय', 'occupation'),
              buildSimpleTextRow('९.', 'शारिर बांधा', 'physique'),
              buildSimpleTextRow('१०.', 'उंची सें मी', 'height'),
              buildSimpleTextRow('११.', 'दाढी', 'beard'),
              buildSimpleTextRow('१२.', 'रंग', 'complexion'),
              buildSimpleTextRow('१३.', 'व्यंग शरिरावर', 'disability'),
              buildSimpleTextRow('१४.', 'डोळे', 'eyes'),
              buildSimpleTextRow('१५.', 'चेहरा', 'face'),
              buildSimpleTextRow('१६.', 'केसाची ठेवण', 'hairStyle'),
              buildSimpleTextRow('१७.', 'मिशी', 'mustache'),
              buildSimpleTextRow('१८.', 'नाक', 'nose'),
              buildSimpleTextRow('१९.', 'कान', 'ears'),
              buildSimpleTextRow('२०.', 'दात', 'teeth'),
              buildSimpleTextRow('२१.', 'भाजल्याच्या खुना', 'burnMarks'),
              buildSimpleTextRow('२२.', 'कोळ डाग', 'blackSpots'),
              buildSimpleTextRow('२३.', 'तिळ', 'moles'),
              buildSimpleTextRow('२४.', 'जुण्या जखमाचे व्रण व इतर खुणा', 'scars'),
              buildSimpleTextRow('२५.', 'गोंदलेले', 'tattoo'),
              buildSimpleTextRow('२६.', 'सवयी', 'habits'),
              buildSimpleTextRow('२७.', 'बोलण्याची पध्दत', 'speech'),
              buildSimpleTextRow('२८.', 'कपडे कसे घालतो', 'clothing'),
              buildSimpleTextRow('२९.', 'अटकेचा दिनांक व वेळ', 'arrestDateTime'),
              buildSimpleTextRow('३०.', 'अटक करणारे अंमलदार', 'arrestingOfficer'),
              buildSimpleTextRow('३१.', 'जमीनावर सोडला असल्यास जामीनदाराचे नांव', 'surety'),
              buildSimpleTextRow('३२.', 'गुन्हेगारास अगोदर शिक्षा झाली काय व किती', 'pastConviction'),
              buildSimpleTextRow('३३.', 'केंसचा निकाल', 'caseResult'),
            ],
          ),
          pw.SizedBox(height: 12),

          // ── SIGNATURES ──
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Text('आरोपीची स्वाक्षरी', style: bold),
                  if (v('accusedSig').isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(v('accusedSig'), style: regular),
                  ],
                ],
              ),
              pw.Column(
                children: [
                  pw.Text('तपासी अंमलदार सही', style: bold),
                  if (v('ioSig').isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(v('ioSig'), style: regular),
                  ],
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 6),

          // ── MRW FOOTER ──
          pw.Align(
            alignment: pw.Alignment.bottomRight,
            child: pw.Text(
              'M.R.W',
              style: pw.TextStyle(
                font: devanagari,
                fontSize: 7,
                color: PdfColors.grey700,
              ),
            ),
          ),
        ];
      },
    ),
  );

  return pdf.save();
}
