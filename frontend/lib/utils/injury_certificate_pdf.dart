import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'form_image_pdf_helper.dart';

Future<void> previewInjuryCertificatePdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final fileName =
      'Injury_Certificate_${DateTime.now().millisecondsSinceEpoch}.pdf';
  await FormImagePdfHelper.previewImageBasedPdf(
    context,
    fileName: fileName,
    pages: [_buildPgWidget(doc)],
    fallbackPdfGenerator: () => generateInjuryCertificatePdf(doc),
  );
}

Future<Uint8List> generateInjuryCertificatePdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final loraRegular = await PdfGoogleFonts.loraRegular();
  final loraBold = await PdfGoogleFonts.loraBold();
  final devanagari = await PdfGoogleFonts.notoSansDevanagariRegular();
  final devanagariBold = await PdfGoogleFonts.notoSansDevanagariBold();

  final regular = pw.TextStyle(font: loraRegular, fontSize: 9.5);
  final bold = pw.TextStyle(
    font: loraBold,
    fontSize: 9.5,
    fontWeight: pw.FontWeight.bold,
  );
  final titleStyle = pw.TextStyle(
    font: loraBold,
    fontSize: 14,
    fontWeight: pw.FontWeight.bold,
    decoration: pw.TextDecoration.underline,
  );

  String v(String key) => doc[key]?.toString().trim() ?? '';

  pw.Widget underlineValue(String text, {double minWidth = 60}) {
    return pw.Container(
      constraints: pw.BoxConstraints(minWidth: minWidth),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
      ),
      padding: const pw.EdgeInsets.only(bottom: 1),
      child: pw.Text(
        text.isEmpty ? ' ' : text,
        style: regular,
      ),
    );
  }

  final rawInjuries = doc['injuries'];
  final List<Map<String, String>> injuryList = [];
  if (rawInjuries is List && rawInjuries.isNotEmpty) {
    for (final item in rawInjuries) {
      if (item is Map) {
        injuryList.add({
          'typeOfInjury': item['typeOfInjury']?.toString() ?? '',
          'siteOnBody': item['siteOnBody']?.toString() ?? '',
          'ageOfInjury': item['ageOfInjury']?.toString() ?? '',
          'size': item['size']?.toString() ?? '',
          'color': item['color']?.toString() ?? '',
          'probableWeapon': item['probableWeapon']?.toString() ?? '',
          'simpleGrievous': item['simpleGrievous']?.toString() ?? '',
          'remark': item['remark']?.toString() ?? '',
        });
      }
    }
  }
  while (injuryList.length < 6) {
    injuryList.add({
      'typeOfInjury': '',
      'siteOnBody': '',
      'ageOfInjury': '',
      'size': '',
      'color': '',
      'probableWeapon': '',
      'simpleGrievous': '',
      'remark': '',
    });
  }

  pdf.addPage(
    pw.MultiPage(
      theme: pw.ThemeData.withFont(
        base: loraRegular,
        bold: loraBold,
        fontFallback: [devanagari, devanagariBold],
      ),
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.bottomRight,
        child: pw.Text('M.R.W', style: bold.copyWith(fontSize: 8)),
      ),
      build: (ctx) => [
        pw.Center(
          child: pw.Text('INJURY CERTIFICATE', style: titleStyle),
        ),
        pw.SizedBox(height: 14),

        // ── TOP RIGHT MLC / DATE ──
        pw.Align(
          alignment: pw.Alignment.topRight,
          child: pw.Container(
            width: 220,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Text('MLC No.:-', style: bold),
                    pw.SizedBox(width: 4),
                    pw.Expanded(
                        child: underlineValue(v('mlcNo'), minWidth: 100)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text('Date. ', style: bold),
                    pw.SizedBox(width: 4),
                    pw.Expanded(
                        child: underlineValue(v('mlcDate'), minWidth: 100)),
                  ],
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 16),

        // ── CERTIFICATE BODY PARAGRAPH ──
        pw.RichText(
          text: pw.TextSpan(
            style: regular,
            children: [
              const pw.TextSpan(text: 'Certified that shri/smt  '),
              pw.TextSpan(
                text: v('patientName').isEmpty
                    ? '....................................................................................'
                    : v('patientName'),
                style: bold,
              ),
              const pw.TextSpan(text: '  age  '),
              pw.TextSpan(
                text: v('patientAge').isEmpty ? '..........' : v('patientAge'),
                style: bold,
              ),
              const pw.TextSpan(text: '  about years\n'),
              const pw.TextSpan(
                  text: 'bearing following identification mark R/O.  '),
              pw.TextSpan(
                text: v('idMarkAndAddress').isEmpty
                    ? '.......................................................'
                    : v('idMarkAndAddress'),
                style: bold,
              ),
              const pw.TextSpan(text: '  tah  '),
              pw.TextSpan(
                text: v('tah').isEmpty ? '...................' : v('tah'),
                style: bold,
              ),
              const pw.TextSpan(text: '  dist.  '),
              pw.TextSpan(
                text: v('dist').isEmpty
                    ? '...........................'
                    : v('dist'),
                style: bold,
              ),
              const pw.TextSpan(text: '\nbrought to this hospital by PC/HC.  '),
              pw.TextSpan(
                text: v('broughtBy').isEmpty
                    ? '..........................'
                    : v('broughtBy'),
                style: bold,
              ),
              const pw.TextSpan(text: '  B.No.  '),
              pw.TextSpan(
                text: v('buckleNo').isEmpty ? '.......' : v('buckleNo'),
                style: bold,
              ),
              const pw.TextSpan(text: '  Police station.  '),
              pw.TextSpan(
                text: v('policeStation').isEmpty
                    ? '.......................'
                    : v('policeStation'),
                style: bold,
              ),
              const pw.TextSpan(text: '\nat  '),
              pw.TextSpan(
                text: v('broughtTime').isEmpty ? '.......' : v('broughtTime'),
                style: bold,
              ),
              const pw.TextSpan(text: '  AM/PM on  '),
              pw.TextSpan(
                text: v('broughtDate').isEmpty
                    ? '....../....../20......'
                    : v('broughtDate'),
                style: bold,
              ),
              const pw.TextSpan(text: '  & examination by me on  '),
              pw.TextSpan(
                text: v('examDate').isEmpty
                    ? '....../....... /20.....'
                    : v('examDate'),
                style: bold,
              ),
              const pw.TextSpan(text: '  at  '),
              pw.TextSpan(
                text: v('examTime').isEmpty ? '....../.......' : v('examTime'),
                style: bold,
              ),
              const pw.TextSpan(text: '  AM/PM'),
            ],
          ),
        ),
        pw.SizedBox(height: 18),

        // ── 9-COLUMN TABLE ──
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
          columnWidths: {
            0: const pw.FixedColumnWidth(28),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2.2),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(1.2),
            5: const pw.FlexColumnWidth(1.2),
            6: const pw.FlexColumnWidth(2),
            7: const pw.FlexColumnWidth(1.6),
            8: const pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildPdfHeaderCell('Sr\nno', bold),
                _buildPdfHeaderCell('Type of\ninjury', bold),
                _buildPdfHeaderCell('Site on the part of\nbody', bold),
                _buildPdfHeaderCell('Age of\ninjury', bold),
                _buildPdfHeaderCell('Size', bold),
                _buildPdfHeaderCell('Color', bold),
                _buildPdfHeaderCell('Probable\nweapon used', bold),
                _buildPdfHeaderCell('Simpler\nGrievous', bold),
                _buildPdfHeaderCell('Remark', bold),
              ],
            ),
            for (int i = 0; i < injuryList.length; i++)
              pw.TableRow(
                children: [
                  pw.Container(
                    alignment: pw.Alignment.center,
                    padding: const pw.EdgeInsets.symmetric(vertical: 8),
                    child:
                        pw.Text('${i + 1}', style: bold.copyWith(fontSize: 8)),
                  ),
                  _buildPdfDataCell(
                      injuryList[i]['typeOfInjury'] ?? '', regular),
                  _buildPdfDataCell(injuryList[i]['siteOnBody'] ?? '', regular),
                  _buildPdfDataCell(
                      injuryList[i]['ageOfInjury'] ?? '', regular),
                  _buildPdfDataCell(injuryList[i]['size'] ?? '', regular),
                  _buildPdfDataCell(injuryList[i]['color'] ?? '', regular),
                  _buildPdfDataCell(
                      injuryList[i]['probableWeapon'] ?? '', regular),
                  _buildPdfDataCell(
                      injuryList[i]['simpleGrievous'] ?? '', regular),
                  _buildPdfDataCell(injuryList[i]['remark'] ?? '', regular),
                ],
              ),
          ],
        ),
        pw.SizedBox(height: 36),

        // ── FOOTER SECTION ──
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Row(
                children: [
                  pw.Text('Date:- ', style: bold),
                  underlineValue(v('footerDate'), minWidth: 80),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Row(
                children: [
                  pw.Text('Place:- ', style: bold),
                  underlineValue(v('footerPlace'), minWidth: 80),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Medical officer', style: bold),
                  pw.Text('Name and Sing', style: bold),
                  pw.SizedBox(height: 4),
                  underlineValue(v('moName'), minWidth: 100),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );

  return pdf.save();
}

pw.Widget _buildPdfHeaderCell(String text, pw.TextStyle style) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 6),
    child: pw.Center(
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: style.copyWith(fontSize: 8),
      ),
    ),
  );
}

pw.Widget _buildPdfDataCell(String text, pw.TextStyle style) {
  return pw.Container(
    constraints: const pw.BoxConstraints(minHeight: 28),
    padding: const pw.EdgeInsets.all(3),
    child: pw.Text(
      text,
      style: style.copyWith(fontSize: 8),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// ── NATIVE FLUTTER WIDGET BUILDER (100% Devanagari Font Shaping) ──
// ══════════════════════════════════════════════════════════════════════════════

Widget _buildPgWidget(Map<String, dynamic> doc) {
  String v(String key) => doc[key]?.toString().trim() ?? '';

  Widget underlineValue(String text, {double minWidth = 60}) {
    return Container(
      constraints: BoxConstraints(minWidth: minWidth),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(width: 0.8, color: Colors.black87)),
      ),
      padding: const EdgeInsets.only(bottom: 1),
      child: Text(
        text.isEmpty ? ' ' : text,
        style: FormImagePdfHelper.valStyle(10.5),
      ),
    );
  }

  final rawInjuries = doc['injuries'];
  final List<Map<String, String>> injuryList = [];
  if (rawInjuries is List && rawInjuries.isNotEmpty) {
    for (final item in rawInjuries) {
      if (item is Map) {
        injuryList.add({
          'typeOfInjury': item['typeOfInjury']?.toString() ?? '',
          'siteOnBody': item['siteOnBody']?.toString() ?? '',
          'ageOfInjury': item['ageOfInjury']?.toString() ?? '',
          'size': item['size']?.toString() ?? '',
          'color': item['color']?.toString() ?? '',
          'probableWeapon': item['probableWeapon']?.toString() ?? '',
          'simpleGrievous': item['simpleGrievous']?.toString() ?? '',
          'remark': item['remark']?.toString() ?? '',
        });
      }
    }
  }
  while (injuryList.length < 6) {
    injuryList.add({
      'typeOfInjury': '',
      'siteOnBody': '',
      'ageOfInjury': '',
      'size': '',
      'color': '',
      'probableWeapon': '',
      'simpleGrievous': '',
      'remark': '',
    });
  }

  Widget headerCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: FormImagePdfHelper.mBld(8.5),
      ),
    );
  }

  Widget dataCell(String text) {
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: FormImagePdfHelper.valStyle(8.5),
      ),
    );
  }

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
    children: [
      Center(
        child: Text(
          'INJURY CERTIFICATE',
          style: FormImagePdfHelper.mBld(16).copyWith(
            decoration: TextDecoration.underline,
          ),
        ),
      ),
      const SizedBox(height: 14),

      // Top Right MLC / Date
      Align(
        alignment: Alignment.topRight,
        child: SizedBox(
          width: 240,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('MLC No.:-', style: FormImagePdfHelper.mBld(11)),
                  const SizedBox(width: 4),
                  Expanded(child: underlineValue(v('mlcNo'), minWidth: 100)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('Date. ', style: FormImagePdfHelper.mBld(11)),
                  const SizedBox(width: 4),
                  Expanded(child: underlineValue(v('mlcDate'), minWidth: 100)),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),

      // Certificate Body Paragraph
      Text.rich(
        TextSpan(
          style: FormImagePdfHelper.mReg(10.5, 1.45),
          children: [
            const TextSpan(text: 'Certified that shri/smt  '),
            TextSpan(
              text: v('patientName').isEmpty
                  ? '....................................................................................'
                  : v('patientName'),
              style: FormImagePdfHelper.mBld(10.5),
            ),
            const TextSpan(text: '  age  '),
            TextSpan(
              text: v('patientAge').isEmpty ? '..........' : v('patientAge'),
              style: FormImagePdfHelper.mBld(10.5),
            ),
            const TextSpan(text: '  about years\n'),
            const TextSpan(text: 'bearing following identification mark R/O.  '),
            TextSpan(
              text: v('idMarkAndAddress').isEmpty
                  ? '.......................................................'
                  : v('idMarkAndAddress'),
              style: FormImagePdfHelper.mBld(10.5),
            ),
            const TextSpan(text: '  tah  '),
            TextSpan(
              text: v('tah').isEmpty ? '...................' : v('tah'),
              style: FormImagePdfHelper.mBld(10.5),
            ),
            const TextSpan(text: '  dist.  '),
            TextSpan(
              text: v('dist').isEmpty ? '...........................' : v('dist'),
              style: FormImagePdfHelper.mBld(10.5),
            ),
            const TextSpan(text: '\nbrought to this hospital by PC/HC.  '),
            TextSpan(
              text: v('broughtBy').isEmpty ? '..........................' : v('broughtBy'),
              style: FormImagePdfHelper.mBld(10.5),
            ),
            const TextSpan(text: '  B.No.  '),
            TextSpan(
              text: v('buckleNo').isEmpty ? '.......' : v('buckleNo'),
              style: FormImagePdfHelper.mBld(10.5),
            ),
            const TextSpan(text: '  Police station.  '),
            TextSpan(
              text: v('policeStation').isEmpty ? '.......................' : v('policeStation'),
              style: FormImagePdfHelper.mBld(10.5),
            ),
            const TextSpan(text: '\nat  '),
            TextSpan(
              text: v('broughtTime').isEmpty ? '.......' : v('broughtTime'),
              style: FormImagePdfHelper.mBld(10.5),
            ),
            const TextSpan(text: '  AM/PM on  '),
            TextSpan(
              text: v('broughtDate').isEmpty ? '....../....../20......' : v('broughtDate'),
              style: FormImagePdfHelper.mBld(10.5),
            ),
            const TextSpan(text: '  & examination by me on  '),
            TextSpan(
              text: v('examDate').isEmpty ? '....../....... /20.....' : v('examDate'),
              style: FormImagePdfHelper.mBld(10.5),
            ),
            const TextSpan(text: '  at  '),
            TextSpan(
              text: v('examTime').isEmpty ? '....../.......' : v('examTime'),
              style: FormImagePdfHelper.mBld(10.5),
            ),
            const TextSpan(text: '  AM/PM'),
          ],
        ),
      ),
      const SizedBox(height: 14),

      // 9-Column Table
      Table(
        border: TableBorder.all(color: Colors.black, width: 0.8),
        columnWidths: const {
          0: FixedColumnWidth(28),
          1: FlexColumnWidth(2),
          2: FlexColumnWidth(2.2),
          3: FlexColumnWidth(1.5),
          4: FlexColumnWidth(1.2),
          5: FlexColumnWidth(1.2),
          6: FlexColumnWidth(2),
          7: FlexColumnWidth(1.6),
          8: FlexColumnWidth(1.5),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
            children: [
              headerCell('Sr\nno'),
              headerCell('Type of\ninjury'),
              headerCell('Site on\nbody'),
              headerCell('Age of\ninjury'),
              headerCell('Size'),
              headerCell('Color'),
              headerCell('Probable\nweapon'),
              headerCell('Simple/\nGrievous'),
              headerCell('Remark'),
            ],
          ),
          for (int i = 0; i < injuryList.length; i++)
            TableRow(
              children: [
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('${i + 1}', style: FormImagePdfHelper.mBld(8.5)),
                ),
                dataCell(injuryList[i]['typeOfInjury'] ?? ''),
                dataCell(injuryList[i]['siteOnBody'] ?? ''),
                dataCell(injuryList[i]['ageOfInjury'] ?? ''),
                dataCell(injuryList[i]['size'] ?? ''),
                dataCell(injuryList[i]['color'] ?? ''),
                dataCell(injuryList[i]['probableWeapon'] ?? ''),
                dataCell(injuryList[i]['simpleGrievous'] ?? ''),
                dataCell(injuryList[i]['remark'] ?? ''),
              ],
            ),
        ],
      ),
      const SizedBox(height: 30),

      // Footer Section
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              children: [
                Text('Date:- ', style: FormImagePdfHelper.mBld(11)),
                underlineValue(v('footerDate'), minWidth: 80),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Text('Place:- ', style: FormImagePdfHelper.mBld(11)),
                underlineValue(v('footerPlace'), minWidth: 80),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Medical officer', style: FormImagePdfHelper.mBld(11)),
                Text('Name and Sign', style: FormImagePdfHelper.mBld(11)),
                const SizedBox(height: 4),
                underlineValue(v('moName'), minWidth: 100),
              ],
            ),
          ),
        ],
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

