import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> previewAbFormPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final bytes = await generateAbFormPdf(doc);
  if (!context.mounted) return;
  final fileName = 'AB_Form_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

Future<Uint8List> generateAbFormPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final loraRegular = await PdfGoogleFonts.loraRegular();
  final loraBold = await PdfGoogleFonts.loraBold();

  final regularStyle = pw.TextStyle(font: loraRegular, fontSize: 10.5, lineSpacing: 2);
  final boldStyle = pw.TextStyle(font: loraBold, fontSize: 11, fontWeight: pw.FontWeight.bold);
  final titleStyle = pw.TextStyle(font: loraBold, fontSize: 15, fontWeight: pw.FontWeight.bold);
  final italicStyle = pw.TextStyle(font: loraRegular, fontSize: 9.5, fontStyle: pw.FontStyle.italic);
  final valueStyle = pw.TextStyle(font: loraBold, fontSize: 10.5, color: PdfColors.blue900);

  String v(String key) => doc[key]?.toString().trim() ?? '';

  pw.Widget underlineField(String value, {double? width, double minWidth = 60, bool fillAvailable = false}) {
    final textWidget = pw.Text(
      value.isEmpty ? '..................................................' : value,
      style: value.isEmpty
          ? pw.TextStyle(font: loraRegular, fontSize: 10, color: PdfColors.grey600)
          : valueStyle,
    );

    if (fillAvailable) {
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8)),
          ),
          child: textWidget,
        ),
      );
    }

    return pw.Container(
      width: width,
      constraints: pw.BoxConstraints(minWidth: minWidth),
      padding: const pw.EdgeInsets.symmetric(horizontal: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8)),
      ),
      child: textWidget,
    );
  }

  final section = v('formSection').toLowerCase();
  final showA = section.isEmpty ||
      section.contains('main') ||
      section.contains('form a') ||
      section.contains('page 1') ||
      section.contains('certificate');
  final showB = section.isEmpty ||
      section.contains('continuation') ||
      section.contains('form b') ||
      section.contains('page 2') ||
      section.contains('testing') ||
      section.contains('requisition');

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 1 — FORM A (Rule 3) matching Image 1
  // ══════════════════════════════════════════════════════════════════════════
  if (showA) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Form A Title ──
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'Form A',
                    style: titleStyle.copyWith(
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text('(See Rule No 3)', style: boldStyle.copyWith(fontSize: 10.5)),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Certificate by registered medical practioner aboving where person examined by him has  or\nhas not consumed an intoxicant.',
                    textAlign: pw.TextAlign.center,
                    style: boldStyle.copyWith(fontSize: 10.5, lineSpacing: 1.5),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // ── Serial No ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Serial No : ', style: boldStyle),
                underlineField(v('serialNo'), width: 120),
              ],
            ),
            pw.SizedBox(height: 12),

            // ── Dispensary / Hospital ──
            pw.Text('(Name and location of the Dispensary of Hospital)', style: boldStyle.copyWith(fontSize: 10.5)),
            pw.SizedBox(height: 2),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8)),
              ),
              child: pw.Text(
                v('dispensary').isEmpty ? '..................................................................................................................................................' : v('dispensary'),
                style: v('dispensary').isEmpty
                    ? pw.TextStyle(font: loraRegular, fontSize: 10, color: PdfColors.grey600)
                    : valueStyle,
              ),
            ),
            pw.SizedBox(height: 12),

            // ── Certified that Shri/Smt/Kumari Body ──
            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 6,
              children: [
                pw.Text('•  Certified that Shri/Smt/Kumari', style: regularStyle),
                underlineField(v('personName'), width: 280),
                pw.Text('was brought to this hospital /dispensary by', style: regularStyle),
                underlineField(v('broughtBy'), width: 220),
                pw.Text('(here state name and designation of the officer)', style: italicStyle),
                pw.Text('on', style: regularStyle),
                underlineField(v('broughtDate'), width: 90),
                pw.Text('at', style: regularStyle),
                underlineField(v('broughtTime'), width: 80),
                pw.Text('(a.m./p.m. and was examined by MO )', style: regularStyle),
                pw.Text('on', style: regularStyle),
                underlineField(v('examinedDate'), width: 90),
                pw.Text('at', style: regularStyle),
                underlineField(v('examinedTime'), width: 80),
                pw.Text('a.m./p.m.', style: regularStyle),
              ],
            ),
            pw.SizedBox(height: 16),

            // ── Clinical Examination Header ──
            pw.Text(
              'A clinical examination of the above named person disclosed the following :-',
              style: boldStyle.copyWith(fontSize: 11),
            ),
            pw.SizedBox(height: 8),

            // Age & Weight
            pw.Row(
              children: [
                pw.SizedBox(width: 80, child: pw.Text('Age :', style: boldStyle)),
                underlineField(v('age'), width: 140),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Row(
              children: [
                pw.SizedBox(width: 80, child: pw.Text('Weight:', style: boldStyle)),
                underlineField(v('weight'), width: 140),
              ],
            ),
            pw.SizedBox(height: 6),

            // Breath
            pw.Row(
              children: [
                pw.SizedBox(width: 80, child: pw.Text('Breath :', style: boldStyle)),
                underlineField(v('breath'), width: 140),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Text('smelling/Not smelling of Alcohol/Opium/Charas/Ganja/Bhang', style: regularStyle),
                ),
              ],
            ),
            pw.SizedBox(height: 6),

            // Speech
            pw.Row(
              children: [
                pw.SizedBox(width: 80, child: pw.Text('Speech :', style: boldStyle)),
                underlineField(v('speech'), width: 140),
                pw.SizedBox(width: 8),
                pw.Text('Incoherent/Normal', style: regularStyle),
              ],
            ),
            pw.SizedBox(height: 6),

            // Gait
            pw.Row(
              children: [
                pw.SizedBox(width: 80, child: pw.Text('Gait :', style: boldStyle)),
                underlineField(v('gait'), width: 140),
                pw.SizedBox(width: 8),
                pw.Text('unstead/Steady.', style: regularStyle),
              ],
            ),
            pw.SizedBox(height: 6),

            // Pupils
            pw.Row(
              children: [
                pw.SizedBox(width: 80, child: pw.Text('Pupiles. :', style: boldStyle)),
                underlineField(v('pupils'), width: 140),
                pw.SizedBox(width: 8),
                pw.Text('Dilated/Normal', style: regularStyle),
              ],
            ),
            pw.SizedBox(height: 6),

            // Additional remarks
            pw.Row(
              children: [
                pw.Text('Additional remarks any ', style: boldStyle),
                underlineField(v('additionalRemarks'), fillAvailable: true),
              ],
            ),
            pw.SizedBox(height: 14),

            // ── Findings Statement ──
            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                pw.Text('I find that the above named person', style: regularStyle),
                underlineField(v('consumed'), width: 130),
                underlineField(v('intoxicantType'), width: 160),
                pw.Text('I also find that he', style: regularStyle),
                underlineField(v('underInfluence'), width: 80),
                pw.Text('under the Influence of alcohol', style: regularStyle),
              ],
            ),
            pw.SizedBox(height: 10),

            // ── N.B. Blood Collected ──
            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              spacing: 4,
              children: [
                pw.Text('(N.B.', style: boldStyle),
                underlineField(v('bloodCollected'), width: 70),
                pw.Text(
                  'Blood from the body of the above named was/was not collected by MO for Chemical examination )',
                  style: regularStyle,
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // ── 2-Column Signatures ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text('Dated : ', style: boldStyle),
                          underlineField(v('formADated'), width: 120),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        children: [
                          pw.Text('Time : ', style: boldStyle),
                          underlineField(v('formATime'), width: 120),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text('Signature : ', style: boldStyle),
                          underlineField(v('moSignature'), width: 130),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        children: [
                          pw.Text('Designation : ', style: boldStyle),
                          underlineField(v('moDesignation'), width: 130),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // ── Signature/Thumb impression of person examined ──
            pw.Text('Signature/Thumb impression of the person examined', style: boldStyle),
            pw.SizedBox(height: 2),
            underlineField(v('examinedSignature'), fillAvailable: true),
            pw.SizedBox(height: 12),

            // ── Marks of Identification ──
            pw.Text(
              'Marks of Identification of the person examined in case he refuses to given his signature /Thumb impression',
              style: boldStyle.copyWith(fontSize: 10),
            ),
            pw.SizedBox(height: 2),
            underlineField(v('identificationMarks'), fillAvailable: true),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 2 — FORM "B" (Rule 4(2)) matching Image 2
  // ══════════════════════════════════════════════════════════════════════════
  if (showB) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Header ──
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('FORM "B"', style: titleStyle),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    '(See rule 4 (2))',
                    style: boldStyle.copyWith(
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // ── No. ......................... ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('No. ', style: boldStyle),
                underlineField(v('formBNo'), width: 160),
              ],
            ),
            pw.SizedBox(height: 8),

            // ── From, Address ──
            pw.Text('From,', style: boldStyle),
            pw.Text('(Name, Designation and address of the registred medical practioner)', style: italicStyle),
            pw.SizedBox(height: 2),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8)),
              ),
              child: pw.Text(
                v('fromPractitioner').isEmpty ? '..................................................................................................................................................' : v('fromPractitioner'),
                style: v('fromPractitioner').isEmpty
                    ? pw.TextStyle(font: loraRegular, fontSize: 10, color: PdfColors.grey600)
                    : valueStyle,
              ),
            ),
            pw.SizedBox(height: 10),

            // ── To, Address ──
            pw.Text('To,', style: boldStyle),
            pw.Text('(Name and address of the Testing Officer)', style: italicStyle),
            pw.SizedBox(height: 2),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8)),
              ),
              child: pw.Text(
                v('toTestingOfficer').isEmpty ? '..................................................................................................................................................' : v('toTestingOfficer'),
                style: v('toTestingOfficer').isEmpty
                    ? pw.TextStyle(font: loraRegular, fontSize: 10, color: PdfColors.grey600)
                    : valueStyle,
              ),
            ),
            pw.SizedBox(height: 8),

            // ── Date :- ──
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Date :- ', style: boldStyle),
                underlineField(v('formBDate'), width: 130),
              ],
            ),
            pw.SizedBox(height: 10),

            // ── Sir, ──
            pw.Text('Sir,', style: boldStyle),
            pw.SizedBox(height: 6),

            // ── Body Paragraph ──
            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 8,
              children: [
                pw.Text('I forward here with by post / with Shri.', style: regularStyle),
                underlineField(v('messengerName'), width: 160),
                pw.Text('of', style: regularStyle),
                underlineField(v('policeStationName'), width: 130),
                pw.Text('Police station a phial bearing serial No.', style: regularStyle),
                underlineField(v('phialSerial'), width: 120),
                pw.Text('containing', style: regularStyle),
                underlineField(v('bloodAmountCc'), width: 50),
                pw.Text('c.c. of venues blood collected by me on', style: regularStyle),
                underlineField(v('collectionDate'), width: 90),
                pw.Text('at', style: regularStyle),
                underlineField(v('collectionTime'), width: 80),
                pw.Text('a.m./p.m. from the body of Shri/Smt/Kumari', style: regularStyle),
                underlineField(v('subjectName'), width: 220),
                pw.Text('of', style: regularStyle),
                underlineField(v('subjectAddress'), width: 260),
                pw.Text('who was produced before me for medical examination and / or collection of blood from his / her body by', style: regularStyle),
                underlineField(v('producedBy'), width: 220),
                pw.Text('and request you to test the blood and issue a certificate ( in duplicates ) regarding the result of the test.', style: regularStyle),
              ],
            ),
            pw.SizedBox(height: 24),

            // ── Yours Faithfully Signoff ──
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Yours Faithfully,', style: boldStyle),
                  pw.SizedBox(height: 18),
                  underlineField(v('formBSignature'), width: 220),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Signature and designation of the registered medical\npractioner.',
                    textAlign: pw.TextAlign.right,
                    style: regularStyle.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // ── Monogram / Seal Box ──
            pw.Text('Fascimile of the seal or Monogram', style: boldStyle.copyWith(fontSize: 10.5)),
            pw.Text('used for sealing the phial containing the blood.', style: regularStyle.copyWith(fontSize: 10)),
            pw.SizedBox(height: 4),
            pw.Container(
              height: 50,
              width: double.infinity,
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey700, width: 0.8),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
              ),
              child: pw.Text(
                v('sealFacsimile').isEmpty ? '(Seal / Monogram Impression)' : v('sealFacsimile'),
                style: v('sealFacsimile').isEmpty
                    ? pw.TextStyle(font: loraRegular, fontSize: 9.5, color: PdfColors.grey500, fontStyle: pw.FontStyle.italic)
                    : valueStyle.copyWith(fontSize: 9.5),
              ),
            ),
            pw.SizedBox(height: 20),

            // ── Divider & Footnotes ──
            pw.Container(height: 1, width: double.infinity, color: PdfColors.black),
            pw.SizedBox(height: 6),
            pw.Text(
              'Here specify the name, designation and address of the messenger with whom the phial containing the blood is forwarded for delivery to the Testing.',
              style: regularStyle.copyWith(fontSize: 9.5),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              'Strike off, if these words are not required.',
              style: regularStyle.copyWith(fontSize: 9.5),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              'Here state the name and designation of the officer by whom the said person was produced for collection of blood.',
              style: regularStyle.copyWith(fontSize: 9.5),
            ),
          ],
        ),
      ),
    );
  }

  return pdf.save();
}
