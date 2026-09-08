import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> previewMedicalExamS51Pdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final bytes = await generateMedicalExamS51Pdf(doc);
  if (!context.mounted) return;
  final fileName =
      'Medical_Exam_Request_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

Future<Uint8List> generateMedicalExamS51Pdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final devanagari = await PdfGoogleFonts.notoSansDevanagariRegular();
  final devanagariBold = await PdfGoogleFonts.notoSansDevanagariBold();

  final regular = pw.TextStyle(
    font: devanagari,
    fontSize: 11,
    lineSpacing: 4,
  );
  final bold = pw.TextStyle(
    font: devanagariBold,
    fontSize: 11,
    fontWeight: pw.FontWeight.bold,
  );
  final headerTitle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 14,
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

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 48),
      build: (pw.Context context) {
        final outpost = v('outpost', 'सावळी');
        final ps = v('policeStation', 'पारवा');
        final dateStr = v('date', '......./ ......../२०...');

        final toOfficer = v('toOfficer', 'मा. वैद्यकीय अधिकारी');
        final toHospital = v('toHospital', 'प्राथमकी आरोग्य केंद्र सावळी सदोबा');
        final toTahDist = v('toTahDist', 'ता आर्णी जिल्हा यवतमाळ.');

        final fromLocation = v(
          'fromLocation',
          'पोलीस दुरक्षेत्र सावळी सदोबा पोलीस स्टेशन पारवा जिल्हा यवतमाळ',
        );

        final subject = v(
          'subject',
          'जखमी यांचे माराची वैद्यकीय तपासणी करून अहवाल मिळणेबाबत.',
        );

        final victimName = v('victimName', '____________________________');
        final victimAge = v('victimAge', '..........');
        final victimResidence = v('victimResidence', '__________________');
        final victimTah = v('victimTah', '____________');
        final victimDist = v('victimDist', 'यवतमाळ');
        final assaultDetails = v('assaultDetails', '___________________________');

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ── HEADER ──
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('वैद्यकीय तपासणी', style: headerTitle),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '(भारतीय नागरीक सुरक्षा संहिता २०२३ कलम ५१)',
                    style: headerSub,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // ── TOP RIGHT ──
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Container(
                width: 220,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('पोलीस दुरक्षेत्र $outpost', style: regular),
                    pw.SizedBox(height: 2),
                    pw.Text('पोलीस स्टेशन $ps', style: regular),
                    pw.SizedBox(height: 2),
                    pw.Text('दिनांक : $dateStr', style: regular),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // ── RECIPIENT ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 60,
                  child: pw.Text('प्रति,', style: bold),
                ),
              ],
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 60),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(toOfficer, style: bold),
                  pw.SizedBox(height: 2),
                  pw.Text(toHospital, style: bold),
                  pw.SizedBox(height: 2),
                  pw.Text(toTahDist, style: bold),
                ],
              ),
            ),
            pw.SizedBox(height: 18),

            // ── SENDER ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 60,
                  child: pw.Text('पासुन :-', style: regular),
                ),
                pw.Expanded(
                  child: pw.Text(fromLocation, style: regular),
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            // ── SUBJECT ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 60,
                  child: pw.Text('विषय :-', style: bold),
                ),
                pw.Expanded(
                  child: pw.Text(subject, style: bold),
                ),
              ],
            ),
            pw.SizedBox(height: 18),

            // ── DECORATIVE OOOO ──
            pw.Center(
              child: pw.Text(
                '००००',
                style: pw.TextStyle(
                  font: devanagariBold,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ),
            pw.SizedBox(height: 18),

            // ── BODY PARAGRAPH ──
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: regular.copyWith(lineSpacing: 6, fontSize: 11),
                children: [
                  const pw.TextSpan(
                    text: '        उपरोक्त विषयान्वये सादर आहे की, जखमी नामे ',
                  ),
                  pw.TextSpan(
                    text: '$victimName, ',
                    style: bold,
                  ),
                  const pw.TextSpan(text: 'वय '),
                  pw.TextSpan(text: '$victimAge ', style: bold),
                  const pw.TextSpan(text: 'वर्ष रा '),
                  pw.TextSpan(text: '$victimResidence ', style: bold),
                  const pw.TextSpan(text: 'ता '),
                  pw.TextSpan(text: '$victimTah ', style: bold),
                  const pw.TextSpan(text: 'जिल्हा '),
                  pw.TextSpan(text: '$victimDist ', style: bold),
                  const pw.TextSpan(
                    text:
                        'यांना गैरअर्जदार/ आरोपी यांनी भांडणात मारहाण केल्याचे ',
                  ),
                  pw.TextSpan(text: '$assaultDetails ', style: bold),
                  const pw.TextSpan(
                    text:
                        'मारलागल्याचे सांगत आहे. तरी मार कशाचा व किती वेळ पुर्विचा आहे, सदर माराची तपासणी होउन आपला अभिप्राय मिळणेस विनंती आहे.',
                  ),
                ],
              ),
            ),
            pw.Spacer(),

            // ── FOOTER ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'M.R.W',
                  style: pw.TextStyle(
                    font: devanagari,
                    fontSize: 8,
                    color: PdfColors.grey700,
                  ),
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
