import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'form_image_pdf_helper.dart';

Future<void> previewAbFormPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  final section = v('formSection').toLowerCase();
  final isAExplicit = section.contains('main') ||
      section.contains('form a') ||
      section.contains('1');
  final isBExplicit = section.contains('continuation') ||
      section.contains('form b') ||
      section.contains('2');
  final showA = section.isEmpty ||
      section.contains('complete') ||
      isAExplicit ||
      !isBExplicit;
  final showB = section.isEmpty ||
      section.contains('complete') ||
      isBExplicit ||
      !isAExplicit;

  final pages = <Widget>[];
  if (showA) pages.add(_buildPg1Widget(doc));
  if (showB) pages.add(_buildPg2Widget(doc));

  final fileName = 'AB_Form_${DateTime.now().millisecondsSinceEpoch}.pdf';
  await FormImagePdfHelper.previewImageBasedPdf(
    context,
    fileName: fileName,
    pages: pages,
    height: null,
    fallbackPdfGenerator: () => generateAbFormPdf(doc),
  );
}

Future<Uint8List> generateAbFormPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final loraRegular = await PdfGoogleFonts.loraRegular();
  final loraBold = await PdfGoogleFonts.loraBold();

  final body = pw.TextStyle(
    font: loraRegular,
    fontSize: 9,
    lineSpacing: 1.3,
  );
  final bold = pw.TextStyle(
    font: loraBold,
    fontSize: 9,
    fontWeight: pw.FontWeight.bold,
  );
  final titleStyle = pw.TextStyle(
    font: loraBold,
    fontSize: 13,
    fontWeight: pw.FontWeight.bold,
  );
  final subTitleStyle = pw.TextStyle(
    font: loraBold,
    fontSize: 10.5,
    fontWeight: pw.FontWeight.bold,
  );

  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  // ── Form A Values ──
  final serialNo = v('serialNo');
  final dispensary = v('dispensary');
  final personName = v('personName');
  final personNameCont = v('personNameCont');
  final broughtBy = v('broughtBy');
  final broughtOfficerTitle = v('broughtOfficerTitle');
  final broughtDate = v('broughtDate');
  final broughtTime = v('broughtTime');
  final examinedDate = v('examinedDate');
  final examinedTime = v('examinedTime');
  final age = v('age');
  final weight = v('weight');
  final breath = v('breath');
  final speech = v('speech');
  final gait = v('gait');
  final pupils = v('pupils');
  final additionalRemarks = v('additionalRemarks');
  final consumed = v('consumed');
  final bloodCollected = v('bloodCollected');
  final formADated = v('formADated');
  final formATime = v('formATime');
  final moSignature = v('moSignature');
  final moDesignation = v('moDesignation');
  final examinedSignature = v('examinedSignature');
  final identificationMarks = v('identificationMarks');

  // ── Form B Values ──
  final formBNo = v('formBNo');
  final fromPractitionerLine1 =
      v('fromPractitionerLine1', v('fromPractitioner', moSignature));
  final fromPractitionerLine2 = v('fromPractitionerLine2', dispensary);
  final toTestingOfficerLine1 =
      v('toTestingOfficerLine1', v('toTestingOfficer'));
  final toTestingOfficerLine2 = v('toTestingOfficerLine2');
  final formBDate = v('formBDate', formADated);
  final messengerName = v('messengerName');
  final policeStation = v('policeStation');
  final phialSerial = v('phialSerial', serialNo);
  final bloodAmountCc = v('bloodAmountCc', '5');
  final collectionDate = v('collectionDate', examinedDate);
  final collectionTime = v('collectionTime', examinedTime);
  final subjectName = v('subjectName', personName);
  final subjectNameCont = v('subjectNameCont', personNameCont);
  final subjectAddress = v('subjectAddress');
  final producedBy = v('producedBy', broughtBy);
  final producedByCont = v('producedByCont');
  final formBSignature = v('formBSignature', moSignature);

  final section = v('formSection').toLowerCase();
  final isAExplicit = section.contains('main') ||
      section.contains('form a') ||
      section.contains('1');
  final isBExplicit = section.contains('continuation') ||
      section.contains('form b') ||
      section.contains('2');
  final showA = section.isEmpty ||
      section.contains('complete') ||
      isAExplicit ||
      !isBExplicit;
  final showB = section.isEmpty ||
      section.contains('complete') ||
      isBExplicit ||
      !isAExplicit;

  const line =
      '------------------------------------------------------------------------------------------------------------------';
  const midLine =
      '--------------------------------------------------------------------';

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 1: Form A
  // ══════════════════════════════════════════════════════════════════════════
  if (showA) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Top Center Title
            pw.Center(
              child: pw.Text(
                'Form A',
                style: titleStyle.copyWith(
                    decoration: pw.TextDecoration.underline),
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Center(child: pw.Text('(See Rule No 3)', style: subTitleStyle)),
            pw.SizedBox(height: 6),

            // Certificate Description
            pw.Center(
              child: pw.Text(
                'Certificate by registered medical practioner aboving where person examined by him has or has not consumed an intoxicant.',
                style: bold.copyWith(fontSize: 9.5),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 6),

            // Serial No
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.RichText(
                text: pw.TextSpan(
                  style: bold,
                  children: [
                    const pw.TextSpan(text: 'Serial No : '),
                    pw.TextSpan(
                      text: serialNo.isNotEmpty
                          ? serialNo
                          : '....................',
                      style: serialNo.isNotEmpty ? bold : body,
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 6),

            // Hospital / Dispensary
            pw.Text('(Name and location of the Dispensary of Hospital)',
                style: bold),
            pw.SizedBox(height: 1),
            pw.Text(dispensary.isNotEmpty ? dispensary : line,
                style: dispensary.isNotEmpty ? bold : body),
            pw.SizedBox(height: 6),

            // Main Certification Paragraph
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: body,
                children: [
                  const pw.TextSpan(
                      text: '•   Certified that Shri/Smt/Kumari '),
                  pw.TextSpan(
                    text: personName.isNotEmpty
                        ? personName
                        : '...........................................................................................',
                    style: personName.isNotEmpty ? bold : body,
                  ),
                  if (personNameCont.isNotEmpty) ...[
                    pw.TextSpan(text: ' $personNameCont'),
                  ],
                  const pw.TextSpan(
                      text: ' was brought to this hospital /dispensary by '),
                  pw.TextSpan(
                    text: broughtBy.isNotEmpty
                        ? broughtBy
                        : '.................................',
                    style: broughtBy.isNotEmpty ? bold : body,
                  ),
                  pw.TextSpan(
                    text: broughtOfficerTitle.isNotEmpty
                        ? ' ($broughtOfficerTitle) '
                        : ' (here state name and designation of the officer) ',
                    style: broughtOfficerTitle.isNotEmpty ? bold : body,
                  ),
                  const pw.TextSpan(text: 'on '),
                  pw.TextSpan(
                    text: broughtDate.isNotEmpty ? broughtDate : '',
                    style: broughtDate.isNotEmpty ? bold : body,
                  ),
                  const pw.TextSpan(text: ' at '),
                  pw.TextSpan(
                    text: broughtTime.isNotEmpty ? broughtTime : '',
                    style: broughtTime.isNotEmpty ? bold : body,
                  ),
                  const pw.TextSpan(
                      text: ' (a.m./p.m. and was examined by MO ) on '),
                  pw.TextSpan(
                    text: examinedDate.isNotEmpty ? examinedDate : '',
                    style: examinedDate.isNotEmpty ? bold : body,
                  ),
                  const pw.TextSpan(text: ' at '),
                  pw.TextSpan(
                    text: examinedTime.isNotEmpty ? examinedTime : '',
                    style: examinedTime.isNotEmpty ? bold : body,
                  ),
                  const pw.TextSpan(text: ' a.m./p.m.'),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            // Clinical Examination Title
            pw.Text(
              'A clinical examination of the above named person disclosed the following :-',
              style: bold,
            ),
            pw.SizedBox(height: 4),

            // Exam items
            _pdfExamRow('Age :', age, bold, body),
            pw.SizedBox(height: 3),
            _pdfExamRow('Weight:', weight, bold, body),
            pw.SizedBox(height: 3),
            _pdfExamRow('Breath :', breath, bold, body,
                suffix:
                    'smelling/Not smelling of Alcohol/Opium/Charas/Ganja/Bhang'),
            pw.SizedBox(height: 3),
            _pdfExamRow('Speech :', speech, bold, body,
                suffix: 'Incoherent/Normal'),
            pw.SizedBox(height: 3),
            _pdfExamRow('Gait  :', gait, bold, body, suffix: 'unstead/Steady.'),
            pw.SizedBox(height: 3),
            _pdfExamRow('Pupiles.', pupils, bold, body,
                suffix: 'Dilated/Normal'),
            pw.SizedBox(height: 3),
            pw.RichText(
              text: pw.TextSpan(
                style: bold,
                children: [
                  const pw.TextSpan(text: 'Additional remarks any '),
                  pw.TextSpan(
                    text: additionalRemarks.isNotEmpty
                        ? additionalRemarks
                        : '.........................................................................',
                    style: additionalRemarks.isNotEmpty ? bold : body,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            // Finding Paragraph
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: bold,
                children: const [
                  pw.TextSpan(
                    text:
                        '        I find that the above named person has consumed/has not consumed Alcohol/Opium/\nCharas/Ganja/Bhang/any toxicant I also find that he is/is not under the Influence of alcohol',
                  ),
                ],
              ),
            ),
            if (consumed.isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.Text('Remarks: $consumed', style: bold),
            ],
            pw.SizedBox(height: 6),

            // N.B. Blood collection
            pw.RichText(
              text: pw.TextSpan(
                style: bold,
                children: [
                  const pw.TextSpan(text: '(N.B. '),
                  pw.TextSpan(
                    text: bloodCollected.isNotEmpty
                        ? bloodCollected
                        : '.............',
                    style: bloodCollected.isNotEmpty ? bold : body,
                  ),
                  const pw.TextSpan(
                    text:
                        ' Blood from the body of the above named was/was not collected by MO for Chemical examination )',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Dated / Time and Signature / Designation
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.RichText(
                      text: pw.TextSpan(
                        style: bold,
                        children: [
                          const pw.TextSpan(text: 'Dated '),
                          pw.TextSpan(
                            text: formADated.isNotEmpty
                                ? formADated
                                : '.................................................',
                            style: formADated.isNotEmpty ? bold : body,
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.RichText(
                      text: pw.TextSpan(
                        style: bold,
                        children: [
                          const pw.TextSpan(text: 'Time  '),
                          pw.TextSpan(
                            text: formATime.isNotEmpty
                                ? formATime
                                : '.................................................',
                            style: formATime.isNotEmpty ? bold : body,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.RichText(
                      text: pw.TextSpan(
                        style: bold,
                        children: [
                          const pw.TextSpan(text: 'Signature '),
                          pw.TextSpan(
                            text: moSignature.isNotEmpty
                                ? moSignature
                                : '.................................................',
                            style: moSignature.isNotEmpty ? bold : body,
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.RichText(
                      text: pw.TextSpan(
                        style: bold,
                        children: [
                          const pw.TextSpan(text: 'Designation '),
                          pw.TextSpan(
                            text: moDesignation.isNotEmpty
                                ? moDesignation
                                : '.................................................',
                            style: moDesignation.isNotEmpty ? bold : body,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),

            // Person examined signature & ID marks
            pw.Text('Signature/Thumb impression of the person examined',
                style: bold),
            pw.SizedBox(height: 1),
            pw.Text(examinedSignature.isNotEmpty ? examinedSignature : line,
                style: examinedSignature.isNotEmpty ? bold : body),
            pw.SizedBox(height: 6),
            pw.Text(
              'Marks of Identification of the person examined in case he refuses to given his signature\n/Thumb impression',
              style: bold,
            ),
            pw.SizedBox(height: 1),
            pw.Text(identificationMarks.isNotEmpty ? identificationMarks : line,
                style: identificationMarks.isNotEmpty ? bold : body),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 2: FORM "B"
  // ══════════════════════════════════════════════════════════════════════════
  if (showB) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Top Center Title
            pw.Center(
              child: pw.Text(
                'FORM "B"',
                style: titleStyle.copyWith(
                    decoration: pw.TextDecoration.underline),
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Center(child: pw.Text('(See rule 4 (2))', style: subTitleStyle)),
            pw.SizedBox(height: 6),

            // No.
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.RichText(
                text: pw.TextSpan(
                  style: bold,
                  children: [
                    const pw.TextSpan(text: 'No. '),
                    pw.TextSpan(
                      text: formBNo.isNotEmpty
                          ? formBNo
                          : '........................................',
                      style: formBNo.isNotEmpty ? bold : body,
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 4),

            // From
            pw.Text('From,', style: bold),
            pw.SizedBox(height: 1),
            pw.Text(
                '(Name, Designation and address of the registred medical practioner)',
                style: bold),
            pw.SizedBox(height: 1),
            pw.Text(
                fromPractitionerLine1.isNotEmpty
                    ? fromPractitionerLine1
                    : midLine,
                style: fromPractitionerLine1.isNotEmpty ? bold : body),
            pw.SizedBox(height: 1),
            pw.Text(
                fromPractitionerLine2.isNotEmpty
                    ? fromPractitionerLine2
                    : midLine,
                style: fromPractitionerLine2.isNotEmpty ? bold : body),
            pw.SizedBox(height: 6),

            // To
            pw.Text('To,', style: bold),
            pw.SizedBox(height: 1),
            pw.Text('(Name and address of the Testing Officer)', style: bold),
            pw.SizedBox(height: 1),
            pw.Text(
                toTestingOfficerLine1.isNotEmpty
                    ? toTestingOfficerLine1
                    : midLine,
                style: toTestingOfficerLine1.isNotEmpty ? bold : body),
            pw.SizedBox(height: 1),
            pw.Text(
                toTestingOfficerLine2.isNotEmpty
                    ? toTestingOfficerLine2
                    : midLine,
                style: toTestingOfficerLine2.isNotEmpty ? bold : body),
            pw.SizedBox(height: 6),

            // Date
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.RichText(
                text: pw.TextSpan(
                  style: bold,
                  children: [
                    const pw.TextSpan(text: 'Date :- '),
                    pw.TextSpan(
                      text: formBDate.isNotEmpty
                          ? formBDate
                          : '....................',
                      style: formBDate.isNotEmpty ? bold : body,
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 4),

            // Salutation
            pw.Text('Sir,', style: bold),
            pw.SizedBox(height: 6),

            // Body Paragraph
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: body,
                children: [
                  const pw.TextSpan(
                      text:
                          '        I forward here with by post / with Shri. '),
                  pw.TextSpan(
                    text: messengerName.isNotEmpty
                        ? messengerName
                        : '..............................................',
                    style: messengerName.isNotEmpty ? bold : body,
                  ),
                  const pw.TextSpan(text: ' of '),
                  pw.TextSpan(
                    text: policeStation.isNotEmpty ? policeStation : '',
                    style: policeStation.isNotEmpty ? bold : body,
                  ),
                  const pw.TextSpan(
                      text: ' Police station a phial bearing serial No. '),
                  pw.TextSpan(
                    text: phialSerial.isNotEmpty
                        ? phialSerial
                        : '........................................',
                    style: phialSerial.isNotEmpty ? bold : body,
                  ),
                  pw.TextSpan(
                      text:
                          ' containing ${bloodAmountCc.isNotEmpty ? bloodAmountCc : '.....'} c.c. of venues blood collected by me on '),
                  pw.TextSpan(
                    text: collectionDate.isNotEmpty ? collectionDate : '',
                    style: collectionDate.isNotEmpty ? bold : body,
                  ),
                  const pw.TextSpan(text: ' at '),
                  pw.TextSpan(
                    text: collectionTime.isNotEmpty
                        ? collectionTime
                        : '.....................',
                    style: collectionTime.isNotEmpty ? bold : body,
                  ),
                  const pw.TextSpan(
                      text: ' a.m./p.m. from the body of Shri/smt/Kumari '),
                  pw.TextSpan(
                    text: subjectName.isNotEmpty
                        ? subjectName
                        : '.......................................',
                    style: subjectName.isNotEmpty ? bold : body,
                  ),
                  if (subjectNameCont.isNotEmpty) ...[
                    pw.TextSpan(text: ' $subjectNameCont'),
                  ],
                  const pw.TextSpan(text: ' of '),
                  pw.TextSpan(
                    text: subjectAddress.isNotEmpty
                        ? subjectAddress
                        : '...........................................................',
                    style: subjectAddress.isNotEmpty ? bold : body,
                  ),
                  const pw.TextSpan(
                      text:
                          ' who was produced before me for medical examination and / or collection of blood from his / her body by '),
                  pw.TextSpan(
                    text: producedBy.isNotEmpty
                        ? producedBy
                        : '...................',
                    style: producedBy.isNotEmpty ? bold : body,
                  ),
                  if (producedByCont.isNotEmpty) ...[
                    pw.TextSpan(text: ' $producedByCont'),
                  ],
                  const pw.TextSpan(
                      text:
                          ' and request you to test the blood and issue a certificate ( in duplicates ) regarding the result of the test.'),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Yours Faithfully
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(right: 24),
                child: pw.Text('Yours Faithfully,', style: bold),
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (formBSignature.isNotEmpty)
                    pw.Text(formBSignature, style: bold)
                  else
                    pw.SizedBox(height: 12),
                  pw.Text(
                    'Signature and designation of the registered medical\npractioner.',
                    style: bold,
                    textAlign: pw.TextAlign.right,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Seal Box
            pw.Text(
              'Fascimile of the seal or Monogram\nused for sealing the phial containing the blood.',
              style: bold,
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              width: 120,
              height: 50,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey600, width: 0.8),
              ),
              child: pw.Center(
                child: pw.Text('[ SEAL ]',
                    style: const pw.TextStyle(
                        color: PdfColors.grey600, fontSize: 8)),
              ),
            ),
            pw.SizedBox(height: 10),

            // Divider
            pw.Divider(color: PdfColors.black, thickness: 0.8),
            pw.SizedBox(height: 4),

            // Footnotes
            pw.Text(
              'Here specify the name, designation and address of the messenger with whom the phial containing the blood is forwarded for delivery to the Testing.',
              style: body.copyWith(fontSize: 7.5),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Strike off, if these words are not required.',
              style: body.copyWith(fontSize: 7.5),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Here state the name and designation of the officer by whom the said person was produced for collection of blood.',
              style: body.copyWith(fontSize: 7.5),
            ),
          ],
        ),
      ),
    );
  }

  return pdf.save();
}

pw.Widget _pdfExamRow(
  String label,
  String value,
  pw.TextStyle bold,
  pw.TextStyle body, {
  String? suffix,
}) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(
        width: 60,
        child: pw.Text(label, style: bold),
      ),
      pw.Text(
        value.isNotEmpty
            ? '  $value  '
            : '................................... ',
        style: value.isNotEmpty ? bold : body,
      ),
      if (suffix != null) ...[
        pw.Expanded(child: pw.Text(suffix, style: bold)),
      ],
    ],
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// ── NATIVE FLUTTER WIDGET BUILDERS (100% Devanagari & Latin Layout Match) ──
// ══════════════════════════════════════════════════════════════════════════════

Widget _underlineField(
  String value, {
  double? width,
  double minWidth = 40,
  String? hintText,
  TextAlign textAlign = TextAlign.start,
  double fontSize = 12.5,
  FontWeight fontWeight = FontWeight.w600,
  bool fullWidth = false,
}) {
  final hasVal = value.trim().isNotEmpty;
  return Container(
    width: fullWidth ? double.infinity : width,
    constraints: BoxConstraints(minWidth: minWidth),
    padding: const EdgeInsets.only(bottom: 2, left: 3, right: 3),
    decoration: const BoxDecoration(
      border: Border(
        bottom: BorderSide(color: Colors.black54, width: 1.0),
      ),
    ),
    child: Text(
      hasVal ? value : (hintText ?? ' '),
      textAlign: textAlign,
      style: GoogleFonts.lora(
        fontSize: fontSize,
        fontWeight: hasVal ? fontWeight : FontWeight.normal,
        color: hasVal ? const Color(0xFF0D47A1) : Colors.black38,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );
}

Widget _buildExamRow(
  String label,
  String value, {
  double width = 140,
  String? suffix,
  required TextStyle boldStyle,
  TextStyle? bodyStyle,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      SizedBox(
        width: 75,
        child: Text(label, style: boldStyle),
      ),
      _underlineField(value, width: width),
      if (suffix != null) ...[
        const SizedBox(width: 8),
        Expanded(child: Text(suffix, style: bodyStyle ?? boldStyle)),
      ],
    ],
  );
}

Widget _buildPg1Widget(Map<String, dynamic> doc) {
  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  final serialNo = v('serialNo');
  final dispensary = v('dispensary');
  final personName = v('personName');
  final personNameCont = v('personNameCont');
  final broughtBy = v('broughtBy');
  final broughtOfficerTitle = v('broughtOfficerTitle');
  final broughtDate = v('broughtDate');
  final broughtTime = v('broughtTime');
  final examinedDate = v('examinedDate');
  final examinedTime = v('examinedTime');
  final age = v('age');
  final weight = v('weight');
  final breath = v('breath');
  final speech = v('speech');
  final gait = v('gait');
  final pupils = v('pupils');
  final additionalRemarks = v('additionalRemarks');
  final consumed = v('consumed');
  final bloodCollected = v('bloodCollected');
  final formADated = v('formADated');
  final formATime = v('formATime');
  final moSignature = v('moSignature');
  final moDesignation = v('moDesignation');
  final examinedSignature = v('examinedSignature');
  final identificationMarks = v('identificationMarks');

  final bodyStyle = GoogleFonts.lora(
    fontSize: 12.5,
    fontWeight: FontWeight.normal,
    color: Colors.black87,
    height: 1.45,
  );
  final boldStyle = GoogleFonts.lora(
    fontSize: 12.5,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
    height: 1.4,
  );

  return Container(
    width: FormImagePdfHelper.a4Width,
    constraints: const BoxConstraints(minHeight: FormImagePdfHelper.a4Height),
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 34),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Right Page Label
        Align(
          alignment: Alignment.topRight,
          child: Text(
            'Page 1 — Form A (See Rule No 3)',
            style: boldStyle.copyWith(
              fontSize: 13,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Top Center Title
        Center(
          child: Column(
            children: [
              Text(
                'Form A',
                style: boldStyle.copyWith(
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                '(See Rule No 3)',
                style: boldStyle.copyWith(fontSize: 12.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Subtitle
        Center(
          child: Text(
            'Certificate by registered medical practioner aboving where person examined by him has or has not consumed an intoxicant.',
            style: boldStyle.copyWith(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),

        // Serial No (Right Aligned)
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Serial No : ', style: boldStyle),
              _underlineField(serialNo, width: 140),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Hospital / Dispensary
        Text('(Name and location of the Dispensary of Hospital)', style: boldStyle),
        const SizedBox(height: 2),
        _underlineField(dispensary, fullWidth: true),
        const SizedBox(height: 10),

        // Certified that Shri/Smt/Kumari Paragraph
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 6,
          children: [
            Text('•   Certified that Shri/Smt/Kumari', style: boldStyle),
            _underlineField(personName, width: 320),
          ],
        ),
        const SizedBox(height: 4),
        _underlineField(personNameCont, fullWidth: true),
        const SizedBox(height: 4),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 6,
          children: [
            Text('was brought to this hospital /dispensary by', style: bodyStyle),
            _underlineField(broughtBy, width: 250),
          ],
        ),
        const SizedBox(height: 4),
        _underlineField(
          broughtOfficerTitle,
          fullWidth: true,
          hintText: '(here state name and designation of the officer)',
        ),
        const SizedBox(height: 4),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 6,
          children: [
            Text('on', style: bodyStyle),
            _underlineField(broughtDate, width: 140),
            Text('at', style: bodyStyle),
            _underlineField(broughtTime, width: 110),
            Text('(and was examined by MO )', style: bodyStyle),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 6,
          children: [
            Text('on', style: bodyStyle),
            _underlineField(examinedDate, width: 140),
            Text('at', style: bodyStyle),
            _underlineField(examinedTime, width: 110),
          ],
        ),
        const SizedBox(height: 12),

        // Clinical Examination Heading
        Text(
          'A clinical examination of the above named person disclosed the following :-',
          style: boldStyle,
        ),
        const SizedBox(height: 6),

        // Examination Items
        _buildExamRow('Age :', age, width: 140, boldStyle: boldStyle),
        const SizedBox(height: 5),
        _buildExamRow('Weight:', weight, width: 140, boldStyle: boldStyle),
        const SizedBox(height: 5),
        _buildExamRow(
          'Breath :',
          breath,
          width: 140,
          suffix: 'smelling/Not smelling of Alcohol/Opium/Charas/Ganja/Bhang',
          boldStyle: boldStyle,
          bodyStyle: bodyStyle,
        ),
        const SizedBox(height: 5),
        _buildExamRow(
          'Speech :',
          speech,
          width: 140,
          suffix: 'Incoherent/Normal',
          boldStyle: boldStyle,
          bodyStyle: bodyStyle,
        ),
        const SizedBox(height: 5),
        _buildExamRow(
          'Gait  :',
          gait,
          width: 140,
          suffix: 'unstead/Steady.',
          boldStyle: boldStyle,
          bodyStyle: bodyStyle,
        ),
        const SizedBox(height: 5),
        _buildExamRow(
          'Pupiles.',
          pupils,
          width: 140,
          suffix: 'Dilated/Normal',
          boldStyle: boldStyle,
          bodyStyle: bodyStyle,
        ),
        const SizedBox(height: 5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Additional remarks any ', style: boldStyle),
            Expanded(child: _underlineField(additionalRemarks, fullWidth: true)),
          ],
        ),
        const SizedBox(height: 10),

        // Finding Paragraph
        Text(
          '        I find that the above named person has consumed/has not consumed Alcohol/Opium/\nCharas/Ganja/Bhang/any toxicant I also find that he is/is not under the influence of alcohol',
          style: boldStyle.copyWith(height: 1.35),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('Finding / Remarks: ', style: boldStyle),
            Expanded(
              child: _underlineField(
                consumed,
                fullWidth: true,
                hintText: '[consumed / has not consumed / under influence]',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // N.B. Blood collection
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: [
            Text('(N.B.', style: boldStyle),
            _underlineField(bloodCollected, width: 100, hintText: 'was / was not'),
            Text(
              'Blood from the body of the above named was/was not collected by MO for Chemical examination )',
              style: boldStyle,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Dated / Time & Signature / Designation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Dated  ', style: boldStyle),
                    _underlineField(formADated, width: 160),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Time   ', style: boldStyle),
                    _underlineField(formATime, width: 160),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Signature ', style: boldStyle),
                    _underlineField(moSignature, width: 160),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Designation ', style: boldStyle),
                    _underlineField(moDesignation, width: 160),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Signature/Thumb impression of person examined
        Text('Signature/Thumb impression of the person examined', style: boldStyle),
        const SizedBox(height: 2),
        _underlineField(examinedSignature, fullWidth: true),
        const SizedBox(height: 8),

        // Marks of identification
        Text(
          'Marks of Identification of the person examined in case he refuses to given his signature /Thumb impression',
          style: boldStyle.copyWith(height: 1.25),
        ),
        const SizedBox(height: 2),
        _underlineField(identificationMarks, fullWidth: true),
      ],
    ),
  );
}

Widget _buildPg2Widget(Map<String, dynamic> doc) {
  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  final formADated = v('formADated');
  final examinedDate = v('examinedDate');
  final examinedTime = v('examinedTime');
  final personName = v('personName');
  final personNameCont = v('personNameCont');
  final broughtBy = v('broughtBy');
  final serialNo = v('serialNo');
  final dispensary = v('dispensary');
  final moSignature = v('moSignature');

  final formBNo = v('formBNo');
  final fromPractitionerLine1 =
      v('fromPractitionerLine1', v('fromPractitioner', moSignature));
  final fromPractitionerLine2 = v('fromPractitionerLine2', dispensary);
  final toTestingOfficerLine1 =
      v('toTestingOfficerLine1', v('toTestingOfficer'));
  final toTestingOfficerLine2 = v('toTestingOfficerLine2');
  final formBDate = v('formBDate', formADated);
  final messengerName = v('messengerName');
  final policeStation = v('policeStation');
  final phialSerial = v('phialSerial', serialNo);
  final bloodAmountCc = v('bloodAmountCc', '5');
  final collectionDate = v('collectionDate', examinedDate);
  final collectionTime = v('collectionTime', examinedTime);
  final subjectName = v('subjectName', personName);
  final subjectNameCont = v('subjectNameCont', personNameCont);
  final subjectAddress = v('subjectAddress');
  final producedBy = v('producedBy', broughtBy);
  final producedByCont = v('producedByCont');
  final formBSignature = v('formBSignature', moSignature);

  final bodyStyle = GoogleFonts.lora(
    fontSize: 12.5,
    fontWeight: FontWeight.normal,
    color: Colors.black87,
    height: 1.45,
  );
  final boldStyle = GoogleFonts.lora(
    fontSize: 12.5,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
    height: 1.4,
  );

  return Container(
    width: FormImagePdfHelper.a4Width,
    constraints: const BoxConstraints(minHeight: FormImagePdfHelper.a4Height),
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 34),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Right Page Label
        Align(
          alignment: Alignment.topRight,
          child: Text(
            'Page 2 — FORM "B" (See rule 4 (2))',
            style: boldStyle.copyWith(
              fontSize: 13,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Top Center Title
        Center(
          child: Column(
            children: [
              Text(
                'FORM "B"',
                style: boldStyle.copyWith(
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                '(See rule 4 (2))',
                style: boldStyle.copyWith(fontSize: 12.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // No. (Top Right)
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No. ', style: boldStyle),
              _underlineField(formBNo, width: 180),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // From
        Text('From,', style: boldStyle),
        const SizedBox(height: 2),
        Text(
          '(Name, Designation and address of the registred medical practioner)',
          style: boldStyle,
        ),
        const SizedBox(height: 2),
        _underlineField(fromPractitionerLine1, fullWidth: true),
        const SizedBox(height: 4),
        _underlineField(fromPractitionerLine2, fullWidth: true),
        const SizedBox(height: 8),

        // To
        Text('To,', style: boldStyle),
        const SizedBox(height: 2),
        Text(
          '(Name and address of the Testing Officer)',
          style: boldStyle,
        ),
        const SizedBox(height: 2),
        _underlineField(toTestingOfficerLine1, fullWidth: true),
        const SizedBox(height: 4),
        _underlineField(toTestingOfficerLine2, fullWidth: true),
        const SizedBox(height: 8),

        // Date (Right Aligned)
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Date :- ', style: boldStyle),
              _underlineField(formBDate, width: 140),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Salutation
        Text('Sir,', style: boldStyle),
        const SizedBox(height: 6),

        // Flowing Main Body Paragraph
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 6,
          children: [
            const SizedBox(width: 32), // Indent
            Text('I forward here with by post / with Shri.', style: bodyStyle),
            _underlineField(messengerName, width: 180),
            Text('of', style: bodyStyle),
            _underlineField(policeStation, width: 170),
            Text('Police station a phial bearing serial No.', style: bodyStyle),
            _underlineField(phialSerial, width: 130),
            Text('containing', style: bodyStyle),
            _underlineField(bloodAmountCc.isNotEmpty ? bloodAmountCc : '5', width: 60),
            Text('c.c. of venues blood collected by me on', style: bodyStyle),
            _underlineField(collectionDate, width: 130),
            Text('at', style: bodyStyle),
            _underlineField(collectionTime, width: 110, hintText: 'Time'),
            Text('from the body of Shri/smt/Kumari', style: bodyStyle),
            _underlineField(subjectName, width: 200),
          ],
        ),
        const SizedBox(height: 4),
        _underlineField(subjectNameCont, fullWidth: true),
        const SizedBox(height: 4),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 6,
          children: [
            Text('of', style: bodyStyle),
            _underlineField(subjectAddress, width: 260),
            Text(
              'who was produced before me for medical examination and / or collection of blood from his / her body by',
              style: bodyStyle,
            ),
            _underlineField(producedBy, width: 180),
          ],
        ),
        const SizedBox(height: 4),
        _underlineField(producedByCont, fullWidth: true),
        const SizedBox(height: 6),
        Text(
          'and request you to test the blood and issue a certificate ( in duplicates ) regarding the result of the test.',
          style: bodyStyle,
        ),
        const SizedBox(height: 14),

        // Yours Faithfully & Signature
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 32),
            child: Text('Yours Faithfully,', style: boldStyle),
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _underlineField(
                formBSignature,
                width: 250,
                hintText: '[Signature & Designation]',
              ),
              const SizedBox(height: 4),
              Text(
                'Signature and designation of the registered medical\npractioner.',
                style: boldStyle,
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Facsimile Seal Box
        Text(
          'Fascimile of the seal or Monogram\nused for sealing the phial containing the blood.',
          style: boldStyle,
        ),
        const SizedBox(height: 6),
        Container(
          width: 140,
          height: 65,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black54, width: 1),
          ),
          child: const Center(
            child: Text(
              '[ SEAL / STAMP ]',
              style: TextStyle(color: Colors.black38, fontSize: 11),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Horizontal Divider Line
        const Divider(color: Colors.black87, thickness: 1),
        const SizedBox(height: 6),

        // Footnotes
        Text(
          'Here specify the name, designation and address of the messenger with whom the phial containing the blood is forwarded for delivery to the Testing.',
          style: bodyStyle.copyWith(fontSize: 10.5),
        ),
        const SizedBox(height: 4),
        Text(
          'Strike off, if these words are not required.',
          style: bodyStyle.copyWith(fontSize: 10.5),
        ),
        const SizedBox(height: 4),
        Text(
          'Here state the name and designation of the officer by whom the said person was produced for collection of blood.',
          style: bodyStyle.copyWith(fontSize: 10.5),
        ),
      ],
    ),
  );
}
