import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'form_image_pdf_helper.dart';

Future<void> previewMedicalExamS51Pdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final fileName =
      'Medical_Exam_Request_${DateTime.now().millisecondsSinceEpoch}.pdf';
  await FormImagePdfHelper.previewImageBasedPdf(
    context,
    fileName: fileName,
    pages: [_buildPgWidget(doc)],
    fallbackPdfGenerator: () => generateMedicalExamS51Pdf(doc),
  );
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
        final outpost = v('outpost');
        final ps = v('policeStation');
        final dateStr = v('date', '......./ ......../२०...');

        final toOfficer = v('toOfficer', '________________________');
        final toHospital = v('toHospital', '________________________________');
        final toTahDist = v('toTahDist', '________________________');

        final fromLocation = v(
          'fromLocation',
          '________________________________________________________',
        );

        final subject = v(
          'subject',
          '________________________________________________________',
        );

        final victimName = v('victimName', '____________________________');
        final victimAge = v('victimAge', '..........');
        final victimResidence = v('victimResidence', '__________________');
        final victimTah = v('victimTah', '____________');
        final victimDist = v('victimDist', '____________');
        final assaultDetails =
            v('assaultDetails', '___________________________');

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
                    pw.Text(
                        outpost.isNotEmpty
                            ? 'पोलीस दुरक्षेत्र $outpost'
                            : 'पोलीस दुरक्षेत्र ',
                        style: regular),
                    pw.SizedBox(height: 2),
                    pw.Text(
                        ps.isNotEmpty ? 'पोलीस स्टेशन $ps' : 'पोलीस स्टेशन ',
                        style: regular),
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

// ══════════════════════════════════════════════════════════════════════════════
// ── NATIVE FLUTTER WIDGET BUILDER (100% Devanagari Font Shaping) ──
// ══════════════════════════════════════════════════════════════════════════════

Widget _buildPgWidget(Map<String, dynamic> doc) {
  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  final rawOutpost = v('outpost');
  final outpost = rawOutpost;
  final rawPs = v('policeStation');
  final ps = rawPs;
  final rawDate = v('date');
  final dateStr = rawDate.isNotEmpty ? rawDate : '......./ ......../२०...';

  final rawToOfficer = v('toOfficer');
  final toOfficer =
      rawToOfficer.isNotEmpty ? rawToOfficer : '________________________';
  final rawToHospital = v('toHospital');
  final toHospital = rawToHospital.isNotEmpty
      ? rawToHospital
      : '________________________________';
  final rawToTahDist = v('toTahDist');
  final toTahDist =
      rawToTahDist.isNotEmpty ? rawToTahDist : '________________________';

  final rawFromLocation = v('fromLocation');
  final fromLocation = rawFromLocation.isNotEmpty
      ? rawFromLocation
      : '________________________________________________________';

  final rawSubject = v('subject');
  final subject = rawSubject.isNotEmpty
      ? rawSubject
      : '________________________________________________________';

  final rawVictimName = v('victimName');
  final victimName =
      rawVictimName.isNotEmpty ? rawVictimName : '____________________________';
  final rawVictimAge = v('victimAge');
  final victimAge = rawVictimAge.isNotEmpty ? rawVictimAge : '..........';
  final rawVictimResidence = v('victimResidence');
  final victimResidence =
      rawVictimResidence.isNotEmpty ? rawVictimResidence : '__________________';
  final rawVictimTah = v('victimTah');
  final victimTah = rawVictimTah.isNotEmpty ? rawVictimTah : '____________';
  final rawVictimDist = v('victimDist');
  final victimDist = rawVictimDist.isNotEmpty ? rawVictimDist : '____________';
  final rawAssaultDetails = v('assaultDetails');
  final assaultDetails = rawAssaultDetails.isNotEmpty
      ? rawAssaultDetails
      : '___________________________';

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 48),
    children: [
      // Header
      Center(
        child: Column(
          children: [
            Text('वैद्यकीय तपासणी', style: FormImagePdfHelper.mBld(16)),
            const SizedBox(height: 3),
            Text(
              '(भारतीय नागरीक सुरक्षा संहिता २०२३ कलम ५१)',
              style: FormImagePdfHelper.mBld(12),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),

      // Top Right
      Align(
        alignment: Alignment.topRight,
        child: SizedBox(
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1.0),
                    child: Text('पोलीस दुरक्षेत्र ',
                        style: FormImagePdfHelper.mReg(11.5)),
                  ),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(width: 0.8, color: Colors.black87),
                        ),
                      ),
                      padding: const EdgeInsets.only(bottom: 1),
                      child: Text(
                        outpost.isEmpty ? ' ' : outpost,
                        softWrap: true,
                        style: FormImagePdfHelper.mBld(11.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1.0),
                    child: Text('पोलीस स्टेशन : ',
                        style: FormImagePdfHelper.mReg(11.5)),
                  ),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(width: 0.8, color: Colors.black87),
                        ),
                      ),
                      padding: const EdgeInsets.only(bottom: 1),
                      child: Text(
                        ps.isEmpty ? ' ' : ps,
                        softWrap: true,
                        style: FormImagePdfHelper.mBld(11.5).copyWith(
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.black87,
                          decorationThickness: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('दिनांक : ', style: FormImagePdfHelper.mReg(11.5)),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(width: 0.8, color: Colors.black87),
                        ),
                      ),
                      padding: const EdgeInsets.only(bottom: 1),
                      child: Text(
                        dateStr,
                        style: FormImagePdfHelper.mBld(11.5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),

      // Recipient
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text('प्रति,', style: FormImagePdfHelper.mBld(12)),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(left: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              toOfficer,
              style: FormImagePdfHelper.mBld(12).copyWith(
                decoration: rawToOfficer.isNotEmpty
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              toHospital,
              style: FormImagePdfHelper.mBld(12).copyWith(
                decoration: rawToHospital.isNotEmpty
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              toTahDist,
              style: FormImagePdfHelper.mBld(12).copyWith(
                decoration: rawToTahDist.isNotEmpty
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),

      // Sender
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: SizedBox(
              width: 65,
              child: Text('पासुन :-', style: FormImagePdfHelper.mReg(11.5)),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(width: 0.8, color: Colors.black87),
                ),
              ),
              padding: const EdgeInsets.only(bottom: 1),
              child: Text(
                fromLocation.isEmpty ? ' ' : fromLocation,
                softWrap: true,
                style: FormImagePdfHelper.mReg(11.5).copyWith(
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.black87,
                  decorationThickness: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // Subject
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 65,
            child: Text('विषय :-', style: FormImagePdfHelper.mBld(12)),
          ),
          Expanded(
            child: Text(
              subject,
              style: FormImagePdfHelper.mBld(12).copyWith(
                decoration: rawSubject.isNotEmpty
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),

      // Decorative ००००
      Center(
        child: Text(
          '००००',
          style: FormImagePdfHelper.mBld(13).copyWith(letterSpacing: 4),
        ),
      ),
      const SizedBox(height: 20),

      // Body Paragraph
      Text.rich(
        TextSpan(
          style: FormImagePdfHelper.mReg(12, 1.8),
          children: [
            const TextSpan(
              text: '        उपरोक्त विषयान्वये सादर आहे की, जखमी नामे ',
            ),
            TextSpan(
              text: '$victimName, ',
              style: FormImagePdfHelper.mBld(12).copyWith(
                decoration: rawVictimName.isNotEmpty
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
            ),
            const TextSpan(text: 'वय '),
            TextSpan(
              text: '$victimAge ',
              style: FormImagePdfHelper.mBld(12).copyWith(
                decoration: rawVictimAge.isNotEmpty
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
            ),
            const TextSpan(text: 'वर्ष रा '),
            TextSpan(
              text: '$victimResidence ',
              style: FormImagePdfHelper.mBld(12).copyWith(
                decoration: rawVictimResidence.isNotEmpty
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
            ),
            const TextSpan(text: 'ता '),
            TextSpan(
              text: '$victimTah ',
              style: FormImagePdfHelper.mBld(12).copyWith(
                decoration: rawVictimTah.isNotEmpty
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
            ),
            const TextSpan(text: 'जिल्हा '),
            TextSpan(
              text: '$victimDist ',
              style: FormImagePdfHelper.mBld(12).copyWith(
                decoration: rawVictimDist.isNotEmpty
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
            ),
            const TextSpan(
              text: 'यांना गैरअर्जदार/ आरोपी यांनी भांडणात मारहाण केल्याचे ',
            ),
            TextSpan(
              text: '$assaultDetails ',
              style: FormImagePdfHelper.mBld(12).copyWith(
                decoration: rawAssaultDetails.isNotEmpty
                    ? TextDecoration.underline
                    : TextDecoration.none,
              ),
            ),
            const TextSpan(
              text:
                  'मारलागल्याचे सांगत आहे. तरी मार कशाचा व किती वेळ पुर्विचा आहे, सदर माराची तपासणी होउन आपला अभिप्राय मिळणेस विनंती आहे.',
            ),
          ],
        ),
        textAlign: TextAlign.justify,
      ),
      const Spacer(),

      // Footer
      Align(
        alignment: Alignment.bottomRight,
        child: Text(
          'M.R.W',
          style: FormImagePdfHelper.mReg(8).copyWith(color: Colors.black54),
        ),
      ),
    ],
  );
}
