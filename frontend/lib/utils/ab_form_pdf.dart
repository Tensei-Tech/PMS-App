import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
                    text: broughtDate.isNotEmpty
                        ? broughtDate
                        : '............................................................',
                    style: broughtDate.isNotEmpty ? bold : body,
                  ),
                  const pw.TextSpan(text: ' at '),
                  pw.TextSpan(
                    text: broughtTime.isNotEmpty
                        ? broughtTime
                        : '..............................',
                    style: broughtTime.isNotEmpty ? bold : body,
                  ),
                  const pw.TextSpan(
                      text: ' (a.m./p.m. and was examined by MO ) on '),
                  pw.TextSpan(
                    text: examinedDate.isNotEmpty
                        ? examinedDate
                        : '.........................',
                    style: examinedDate.isNotEmpty ? bold : body,
                  ),
                  const pw.TextSpan(text: ' at '),
                  pw.TextSpan(
                    text: examinedTime.isNotEmpty
                        ? examinedTime
                        : '................',
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
                  pw.TextSpan(
                      text:
                          ' of ${policeStation.isNotEmpty ? policeStation : '....................................'} Police station a phial bearing serial No. '),
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
                    text: collectionDate.isNotEmpty
                        ? collectionDate
                        : '.......................................',
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
// ── NATIVE FLUTTER WIDGET BUILDERS (100% Devanagari Font Shaping) ──
// ══════════════════════════════════════════════════════════════════════════════

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

  const line =
      '------------------------------------------------------------------------------------------------------------------';

  Widget examRow(String label, String value, {String? suffix}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: FormImagePdfHelper.mBld(10)),
        ),
        Text(
          value.isNotEmpty
              ? '  $value  '
              : '................................... ',
          style: value.isNotEmpty
              ? FormImagePdfHelper.valStyle(10)
              : FormImagePdfHelper.mReg(10),
        ),
        if (suffix != null) ...[
          Expanded(child: Text(suffix, style: FormImagePdfHelper.mBld(10))),
        ],
      ],
    );
  }

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 26),
    children: [
      Center(
        child: Text(
          'Form A',
          style: FormImagePdfHelper.mBld(15).copyWith(
            decoration: TextDecoration.underline,
          ),
        ),
      ),
      const SizedBox(height: 2),
      Center(
        child: Text('(See Rule No 3)', style: FormImagePdfHelper.mBld(11)),
      ),
      const SizedBox(height: 6),
      Center(
        child: Text(
          'Certificate by registered medical practioner aboving where person examined by him has or has not consumed an intoxicant.',
          style: FormImagePdfHelper.mBld(10),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 6),
      Align(
        alignment: Alignment.centerRight,
        child: Text.rich(
          TextSpan(
            style: FormImagePdfHelper.mBld(10.5),
            children: [
              const TextSpan(text: 'Serial No : '),
              TextSpan(
                text: serialNo.isNotEmpty ? serialNo : '....................',
                style: serialNo.isNotEmpty
                    ? FormImagePdfHelper.valStyle(10.5)
                    : FormImagePdfHelper.mReg(10.5),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text('(Name and location of the Dispensary of Hospital)',
          style: FormImagePdfHelper.mBld(10)),
      const SizedBox(height: 1),
      Text(
        dispensary.isNotEmpty ? dispensary : line,
        style: dispensary.isNotEmpty
            ? FormImagePdfHelper.valStyle(10)
            : FormImagePdfHelper.mReg(10),
      ),
      const SizedBox(height: 6),
      Text.rich(
        TextSpan(
          style: FormImagePdfHelper.mReg(10, 1.4),
          children: [
            const TextSpan(text: '•   Certified that Shri/Smt/Kumari '),
            TextSpan(
              text: personName.isNotEmpty
                  ? personName
                  : '...........................................................................................',
              style: personName.isNotEmpty
                  ? FormImagePdfHelper.valStyle(10)
                  : FormImagePdfHelper.mReg(10),
            ),
            if (personNameCont.isNotEmpty) ...[
              TextSpan(text: ' $personNameCont'),
            ],
            const TextSpan(
                text: ' was brought to this hospital /dispensary by '),
            TextSpan(
              text: broughtBy.isNotEmpty
                  ? broughtBy
                  : '.................................',
              style: broughtBy.isNotEmpty
                  ? FormImagePdfHelper.valStyle(10)
                  : FormImagePdfHelper.mReg(10),
            ),
            TextSpan(
              text: broughtOfficerTitle.isNotEmpty
                  ? ' ($broughtOfficerTitle) '
                  : ' (here state name and designation of the officer) ',
              style: broughtOfficerTitle.isNotEmpty
                  ? FormImagePdfHelper.mBld(10)
                  : FormImagePdfHelper.mReg(10),
            ),
            const TextSpan(text: 'on '),
            TextSpan(
              text: broughtDate.isNotEmpty
                  ? broughtDate
                  : '............................................................',
              style: broughtDate.isNotEmpty
                  ? FormImagePdfHelper.valStyle(10)
                  : FormImagePdfHelper.mReg(10),
            ),
            const TextSpan(text: ' at '),
            TextSpan(
              text: broughtTime.isNotEmpty
                  ? broughtTime
                  : '..............................',
              style: broughtTime.isNotEmpty
                  ? FormImagePdfHelper.valStyle(10)
                  : FormImagePdfHelper.mReg(10),
            ),
            const TextSpan(text: ' (a.m./p.m. and was examined by MO ) on '),
            TextSpan(
              text: examinedDate.isNotEmpty
                  ? examinedDate
                  : '.........................',
              style: examinedDate.isNotEmpty
                  ? FormImagePdfHelper.valStyle(10)
                  : FormImagePdfHelper.mReg(10),
            ),
            const TextSpan(text: ' at '),
            TextSpan(
              text: examinedTime.isNotEmpty ? examinedTime : '................',
              style: examinedTime.isNotEmpty
                  ? FormImagePdfHelper.valStyle(10)
                  : FormImagePdfHelper.mReg(10),
            ),
            const TextSpan(text: ' a.m./p.m.'),
          ],
        ),
        textAlign: TextAlign.justify,
      ),
      const SizedBox(height: 8),
      Text(
        'A clinical examination of the above named person disclosed the following :-',
        style: FormImagePdfHelper.mBld(10.5),
      ),
      const SizedBox(height: 4),
      examRow('Age :', age),
      const SizedBox(height: 3),
      examRow('Weight:', weight),
      const SizedBox(height: 3),
      examRow('Breath :', breath,
          suffix: 'smelling/Not smelling of Alcohol/Opium/Charas/Ganja/Bhang'),
      const SizedBox(height: 3),
      examRow('Speech :', speech, suffix: 'Incoherent/Normal'),
      const SizedBox(height: 3),
      examRow('Gait  :', gait, suffix: 'unstead/Steady.'),
      const SizedBox(height: 3),
      examRow('Pupiles.', pupils, suffix: 'Dilated/Normal'),
      const SizedBox(height: 3),
      Text.rich(
        TextSpan(
          style: FormImagePdfHelper.mBld(10),
          children: [
            const TextSpan(text: 'Additional remarks any '),
            TextSpan(
              text: additionalRemarks.isNotEmpty
                  ? additionalRemarks
                  : '.........................................................................',
              style: additionalRemarks.isNotEmpty
                  ? FormImagePdfHelper.valStyle(10)
                  : FormImagePdfHelper.mReg(10),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '        I find that the above named person has consumed/has not consumed Alcohol/Opium/\nCharas/Ganja/Bhang/any toxicant I also find that he is/is not under the Influence of alcohol',
        style: FormImagePdfHelper.mBld(10),
      ),
      if (consumed.isNotEmpty) ...[
        const SizedBox(height: 2),
        Text('Remarks: $consumed', style: FormImagePdfHelper.valStyle(10)),
      ],
      const SizedBox(height: 6),
      Text.rich(
        TextSpan(
          style: FormImagePdfHelper.mBld(10),
          children: [
            const TextSpan(text: '(N.B. '),
            TextSpan(
              text:
                  bloodCollected.isNotEmpty ? bloodCollected : '.............',
              style: bloodCollected.isNotEmpty
                  ? FormImagePdfHelper.valStyle(10)
                  : FormImagePdfHelper.mReg(10),
            ),
            const TextSpan(
              text:
                  ' Blood from the body of the above named was/was not collected by MO for Chemical examination )',
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  style: FormImagePdfHelper.mBld(10),
                  children: [
                    const TextSpan(text: 'Dated '),
                    TextSpan(
                      text: formADated.isNotEmpty
                          ? formADated
                          : '.................................................',
                      style: formADated.isNotEmpty
                          ? FormImagePdfHelper.valStyle(10)
                          : FormImagePdfHelper.mReg(10),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  style: FormImagePdfHelper.mBld(10),
                  children: [
                    const TextSpan(text: 'Time  '),
                    TextSpan(
                      text: formATime.isNotEmpty
                          ? formATime
                          : '.................................................',
                      style: formATime.isNotEmpty
                          ? FormImagePdfHelper.valStyle(10)
                          : FormImagePdfHelper.mReg(10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  style: FormImagePdfHelper.mBld(10),
                  children: [
                    const TextSpan(text: 'Signature '),
                    TextSpan(
                      text: moSignature.isNotEmpty
                          ? moSignature
                          : '.................................................',
                      style: moSignature.isNotEmpty
                          ? FormImagePdfHelper.valStyle(10)
                          : FormImagePdfHelper.mReg(10),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  style: FormImagePdfHelper.mBld(10),
                  children: [
                    const TextSpan(text: 'Designation '),
                    TextSpan(
                      text: moDesignation.isNotEmpty
                          ? moDesignation
                          : '.................................................',
                      style: moDesignation.isNotEmpty
                          ? FormImagePdfHelper.valStyle(10)
                          : FormImagePdfHelper.mReg(10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 10),
      Text('Signature/Thumb impression of the person examined',
          style: FormImagePdfHelper.mBld(10)),
      const SizedBox(height: 1),
      Text(
        examinedSignature.isNotEmpty ? examinedSignature : line,
        style: examinedSignature.isNotEmpty
            ? FormImagePdfHelper.valStyle(10)
            : FormImagePdfHelper.mReg(10),
      ),
      const SizedBox(height: 6),
      Text(
        'Marks of Identification of the person examined in case he refuses to given his signature\n/Thumb impression',
        style: FormImagePdfHelper.mBld(10),
      ),
      const SizedBox(height: 1),
      Text(
        identificationMarks.isNotEmpty ? identificationMarks : line,
        style: identificationMarks.isNotEmpty
            ? FormImagePdfHelper.valStyle(10)
            : FormImagePdfHelper.mReg(10),
      ),
    ],
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

  const midLine =
      '--------------------------------------------------------------------';

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 26),
    children: [
      Center(
        child: Text(
          'FORM "B"',
          style: FormImagePdfHelper.mBld(15).copyWith(
            decoration: TextDecoration.underline,
          ),
        ),
      ),
      const SizedBox(height: 2),
      Center(
        child: Text('(See rule 4 (2))', style: FormImagePdfHelper.mBld(11)),
      ),
      const SizedBox(height: 6),
      Align(
        alignment: Alignment.centerRight,
        child: Text.rich(
          TextSpan(
            style: FormImagePdfHelper.mBld(10),
            children: [
              const TextSpan(text: 'No. '),
              TextSpan(
                text: formBNo.isNotEmpty
                    ? formBNo
                    : '........................................',
                style: formBNo.isNotEmpty
                    ? FormImagePdfHelper.valStyle(10)
                    : FormImagePdfHelper.mReg(10),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text('From,', style: FormImagePdfHelper.mBld(10.5)),
      const SizedBox(height: 1),
      Text(
          '(Name, Designation and address of the registred medical practioner)',
          style: FormImagePdfHelper.mBld(10)),
      const SizedBox(height: 1),
      Text(
        fromPractitionerLine1.isNotEmpty ? fromPractitionerLine1 : midLine,
        style: fromPractitionerLine1.isNotEmpty
            ? FormImagePdfHelper.valStyle(10)
            : FormImagePdfHelper.mReg(10),
      ),
      const SizedBox(height: 1),
      Text(
        fromPractitionerLine2.isNotEmpty ? fromPractitionerLine2 : midLine,
        style: fromPractitionerLine2.isNotEmpty
            ? FormImagePdfHelper.valStyle(10)
            : FormImagePdfHelper.mReg(10),
      ),
      const SizedBox(height: 6),
      Text('To,', style: FormImagePdfHelper.mBld(10.5)),
      const SizedBox(height: 1),
      Text('(Name and address of the Testing Officer)',
          style: FormImagePdfHelper.mBld(10)),
      const SizedBox(height: 1),
      Text(
        toTestingOfficerLine1.isNotEmpty ? toTestingOfficerLine1 : midLine,
        style: toTestingOfficerLine1.isNotEmpty
            ? FormImagePdfHelper.valStyle(10)
            : FormImagePdfHelper.mReg(10),
      ),
      const SizedBox(height: 1),
      Text(
        toTestingOfficerLine2.isNotEmpty ? toTestingOfficerLine2 : midLine,
        style: toTestingOfficerLine2.isNotEmpty
            ? FormImagePdfHelper.valStyle(10)
            : FormImagePdfHelper.mReg(10),
      ),
      const SizedBox(height: 6),
      Align(
        alignment: Alignment.centerRight,
        child: Text.rich(
          TextSpan(
            style: FormImagePdfHelper.mBld(10),
            children: [
              const TextSpan(text: 'Date :- '),
              TextSpan(
                text: formBDate.isNotEmpty ? formBDate : '....................',
                style: formBDate.isNotEmpty
                    ? FormImagePdfHelper.valStyle(10)
                    : FormImagePdfHelper.mReg(10),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text('Sir,', style: FormImagePdfHelper.mBld(10.5)),
      const SizedBox(height: 6),
      Text.rich(
        TextSpan(
          style: FormImagePdfHelper.mReg(10, 1.4),
          children: [
            const TextSpan(
                text: '        I forward here with by post / with Shri. '),
            TextSpan(
              text: messengerName.isNotEmpty
                  ? messengerName
                  : '..............................................',
              style: messengerName.isNotEmpty
                  ? FormImagePdfHelper.valStyle(10)
                  : FormImagePdfHelper.mReg(10),
            ),
            TextSpan(
                text:
                    ' of ${policeStation.isNotEmpty ? policeStation : '....................................'} Police station a phial bearing serial No. '),
            TextSpan(
              text: phialSerial.isNotEmpty
                  ? phialSerial
                  : '........................................',
              style: phialSerial.isNotEmpty
                  ? FormImagePdfHelper.valStyle(10)
                  : FormImagePdfHelper.mReg(10),
            ),
            TextSpan(
                text:
                    ' containing ${bloodAmountCc.isNotEmpty ? bloodAmountCc : '.....'} c.c. of venues blood collected by me on '),
            TextSpan(
              text: collectionDate.isNotEmpty
                  ? collectionDate
                  : '.......................................',
              style: collectionDate.isNotEmpty
                  ? FormImagePdfHelper.valStyle(10)
                  : FormImagePdfHelper.mReg(10),
            ),
            const TextSpan(text: ' at '),
            TextSpan(
              text: collectionTime.isNotEmpty
                  ? collectionTime
                  : '.....................',
              style: collectionTime.isNotEmpty
                  ? FormImagePdfHelper.valStyle(10)
                  : FormImagePdfHelper.mReg(10),
            ),
            const TextSpan(
                text: ' a.m./p.m. from the body of Shri/smt/Kumari '),
            TextSpan(
              text: subjectName.isNotEmpty
                  ? subjectName
                  : '.......................................',
              style: subjectName.isNotEmpty
                  ? FormImagePdfHelper.valStyle(10)
                  : FormImagePdfHelper.mReg(10),
            ),
            if (subjectNameCont.isNotEmpty) ...[
              TextSpan(text: ' $subjectNameCont'),
            ],
            const TextSpan(text: ' of '),
            TextSpan(
              text: subjectAddress.isNotEmpty
                  ? subjectAddress
                  : '...........................................................',
              style: subjectAddress.isNotEmpty
                  ? FormImagePdfHelper.valStyle(10)
                  : FormImagePdfHelper.mReg(10),
            ),
            const TextSpan(
                text:
                    ' who was produced before me for medical examination and / or collection of blood from his / her body by '),
            TextSpan(
              text: producedBy.isNotEmpty ? producedBy : '...................',
              style: producedBy.isNotEmpty
                  ? FormImagePdfHelper.valStyle(10)
                  : FormImagePdfHelper.mReg(10),
            ),
            if (producedByCont.isNotEmpty) ...[
              TextSpan(text: ' $producedByCont'),
            ],
            const TextSpan(
                text:
                    ' and request you to test the blood and issue a certificate ( in duplicates ) regarding the result of the test.'),
          ],
        ),
        textAlign: TextAlign.justify,
      ),
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 24),
          child: Text('Yours Faithfully,', style: FormImagePdfHelper.mBld(10)),
        ),
      ),
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerRight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (formBSignature.isNotEmpty)
              Text(formBSignature, style: FormImagePdfHelper.valStyle(10))
            else
              const SizedBox(height: 12),
            Text(
              'Signature and designation of the registered medical\npractioner.',
              style: FormImagePdfHelper.mBld(10),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Text(
        'Fascimile of the seal or Monogram\nused for sealing the phial containing the blood.',
        style: FormImagePdfHelper.mBld(10),
      ),
      const SizedBox(height: 4),
      Container(
        width: 120,
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade600, width: 0.8),
        ),
        child: const Center(
          child: Text('[ SEAL ]',
              style: TextStyle(color: Colors.grey, fontSize: 9)),
        ),
      ),
      const SizedBox(height: 10),
      const Divider(color: Colors.black, thickness: 0.8),
      const SizedBox(height: 4),
      Text(
        'Here specify the name, designation and address of the messenger with whom the phial containing the blood is forwarded for delivery to the Testing.',
        style: FormImagePdfHelper.mReg(8),
      ),
      const SizedBox(height: 2),
      Text(
        'Strike off, if these words are not required.',
        style: FormImagePdfHelper.mReg(8),
      ),
      const SizedBox(height: 2),
      Text(
        'Here state the name and designation of the officer by whom the said person was produced for collection of blood.',
        style: FormImagePdfHelper.mReg(8),
      ),
    ],
  );
}
