import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'form_image_pdf_helper.dart';

const Color _kInkBlue = Color(0xFF0D47A1);
final PdfColor _kPdfInkBlue = PdfColor.fromHex('#0D47A1');

// ─────────────────────────────────────────────────────────────────────────────
// Public Entrypoint
// ─────────────────────────────────────────────────────────────────────────────

Future<void> previewTransitRemandPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final fileName =
      'Transit_Remand_${DateTime.now().millisecondsSinceEpoch}.pdf';
  await FormImagePdfHelper.previewImageBasedPdf(
    context,
    fileName: fileName,
    pages: [_buildPgWidget(doc)],
    height: null,
    fallbackPdfGenerator: () => generateTransitRemandPdf(doc),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Typography Helpers for Widget Rendering
// ─────────────────────────────────────────────────────────────────────────────

TextStyle _lblBold([double sz = 12.0]) => GoogleFonts.lora(
      fontSize: sz,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );

TextStyle _valBlue([
  double sz = 12.0,
  FontWeight fw = FontWeight.w600,
  double ht = 1.4,
]) =>
    GoogleFonts.lora(
      fontSize: sz,
      height: ht,
      fontWeight: fw,
      color: _kInkBlue,
    );

Widget _buildUnderlineValue(
  String text, {
  double? width,
  double minWidth = 36,
  TextAlign textAlign = TextAlign.start,
  double fontSize = 12.0,
  FontWeight fontWeight = FontWeight.w600,
  bool expand = false,
}) {
  final content = Container(
    width: width,
    constraints: BoxConstraints(minWidth: minWidth),
    padding: const EdgeInsets.only(bottom: 2, left: 3, right: 3),
    decoration: const BoxDecoration(
      border: Border(
        bottom: BorderSide(color: Colors.black54, width: 0.85),
      ),
    ),
    child: Text(
      text.isNotEmpty ? text : ' ',
      textAlign: textAlign,
      style: _valBlue(fontSize, fontWeight),
      overflow: TextOverflow.ellipsis,
    ),
  );

  if (expand) {
    return Expanded(child: content);
  }
  return content;
}

// ─────────────────────────────────────────────────────────────────────────────
// Native Flutter Widget Builder (100% Devanagari & Latin Shaping)
// ─────────────────────────────────────────────────────────────────────────────

Widget _buildPgWidget(Map<String, dynamic> doc) {
  String v(String key) => doc[key]?.toString().trim() ?? '';

  final outwardNo = v('outwardNo');
  final outwardYear = v('outwardYear').isNotEmpty ? v('outwardYear') : '2021';
  final psName = v('psName').isNotEmpty ? v('psName') : 'Wakad Police Station,';
  final psCity = v('psCity').isNotEmpty ? v('psCity') : 'Pimpri Chichwad.';
  final date = v('date').isNotEmpty
      ? v('date')
      : '${v('dateDay')} ${v('dateMonthYear')}'.trim();

  final courtLine1 = v('courtLine1');
  final courtLine2 = v('courtLine2');

  final officerName =
      v('officerName').isNotEmpty ? v('officerName') : 'Jitendra S. Girnar';
  final officerRank =
      v('officerRank').isNotEmpty ? v('officerRank') : 'Police Sub Inpector';
  final officerPs = v('officerPs').isNotEmpty
      ? v('officerPs')
      : 'Wakad Police Station, Pimpri Chichwad.';
  final subjectHours = v('subjectHours').isNotEmpty ? v('subjectHours') : '72';

  final bodyText = v('body').isNotEmpty
      ? v('body')
      : '    Regarding the above mentioned subject, most humbly request that a complaint has been registered at Wakad Police Station, Pimpri Chinchwad with FIR No. 912/2021 u/s 377,498(A), 347,504,34 of IPC by complainant Mrs. Sushama Chalamalasetti, Age 31 years, Profession house wife, residing at B901, Titanium Park, Park Street, Wakad Pune. The name of the accused being 1) Mahesh Babu Gunukula, Age 36 ears profession Service, residing at D No. 4, 153, Gudlavaleru, Gudlavaleru MDL 521356, Crishna District Andhra Pradesh and 2) Shiva Prasad Gunukula, Age 63 years (relation father in law). Against he complainant the accused conspired to get the property of complainant at Mumbai which is joint name with her mother and the property in USA. On decline to transfer the property in accused husbands name they harassed her confired her in a room further mentally and physically harassed her. The accused no. 1 also had unnatural sexual offence against the wish of the complainant. The same has been registered under the above mention complainant and I am Investigating the same.\n\n'
          '    During Investigation I had arrest accuse no. 1) Mahesh Babu Gunukula, Age 36 ears profession Service, residing at D No. 4, 153, Gudlavaleru, Gudlavaleru MDL 521356, Crishna District Andhra Pradesh in --------- Police station at --------am/pm on dt.   /11/2021 wide station diary no. ----/21.\n\n'
          '    To produce accused before Hon. JMFC., No.09, Shivajinagar, Pune I want transit remand of accused for 2 hrs. so please give me transit remand of accused.';

  final signOffName =
      v('signOffName').isNotEmpty ? v('signOffName') : officerName;

  return Container(
    width: FormImagePdfHelper.a4Width,
    constraints: const BoxConstraints(minHeight: FormImagePdfHelper.a4Height),
    padding: const EdgeInsets.symmetric(horizontal: 54, vertical: 46),
    color: Colors.white,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header Block (Left-Aligned) ──
        SizedBox(
          width: 310,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Outward No.  ', style: _lblBold(12)),
                  Expanded(
                    child: _buildUnderlineValue(
                      outwardNo,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(' / ', style: _lblBold(12)),
                  SizedBox(
                    width: 54,
                    child: _buildUnderlineValue(
                      outwardYear,
                      textAlign: TextAlign.center,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              _buildUnderlineValue(
                psName,
                width: double.infinity,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 7),
              _buildUnderlineValue(
                psCity,
                width: double.infinity,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 7),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Date -  ', style: _lblBold(12)),
                  _buildUnderlineValue(
                    date,
                    width: 150,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── To Section ──
        Text('To,', style: _lblBold(13.5)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Hon.- ', style: _lblBold(12)),
            Expanded(
              child: _buildUnderlineValue(
                courtLine1,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        _buildUnderlineValue(
          courtLine2,
          width: double.infinity,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),

        const SizedBox(height: 22),

        // ── Report Section ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report- ', style: _lblBold(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildUnderlineValue(
                          officerName,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(' , ', style: _lblBold(12)),
                      Expanded(
                        flex: 3,
                        child: _buildUnderlineValue(
                          officerRank,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  _buildUnderlineValue(
                    officerPs,
                    width: double.infinity,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // ── Subject Section ──
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Sub- To get Transit Remand for ', style: _lblBold(12)),
            _buildUnderlineValue(
              subjectHours,
              width: 50,
              textAlign: TextAlign.center,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            Text(' hrs.', style: _lblBold(12)),
          ],
        ),

        const SizedBox(height: 18),

        // ── Center Symbol ──
        Text(
          '---000---',
          style: _lblBold(12.5).copyWith(letterSpacing: 2.5),
        ),

        const SizedBox(height: 18),

        // ── Respected Sir ──
        Text('Respected Sir,', style: _lblBold(12)),
        const SizedBox(height: 10),

        // ── Body Text ──
        Text(
          bodyText,
          style: _valBlue(11.5, FontWeight.normal, 1.6),
          textAlign: TextAlign.left,
        ),

        const SizedBox(height: 40),

        // ── Your Faithfully & Sign-Off ──
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Faithfully', style: _lblBold(12)),
                const SizedBox(height: 28),
                _buildUnderlineValue(
                  signOffName,
                  width: double.infinity,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Direct PDF Document Generator (Fallback / Native PDF)
// ─────────────────────────────────────────────────────────────────────────────

Future<Uint8List> generateTransitRemandPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final loraRegular = await PdfGoogleFonts.loraRegular();
  final loraBold = await PdfGoogleFonts.loraBold();

  final bodyStyle = pw.TextStyle(
    font: loraRegular,
    fontSize: 11,
    lineSpacing: 3,
    color: _kPdfInkBlue,
  );
  final boldStyle = pw.TextStyle(
    font: loraBold,
    fontSize: 11.5,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.black,
  );
  final titleStyle = pw.TextStyle(
    font: loraBold,
    fontSize: 13,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.black,
  );

  pw.Widget underlineField(
    String text, {
    double? width,
    double minWidth = 36,
    pw.TextAlign textAlign = pw.TextAlign.left,
    pw.FontWeight fontWeight = pw.FontWeight.bold,
  }) {
    return pw.Container(
      constraints: pw.BoxConstraints(minWidth: width ?? minWidth),
      padding: const pw.EdgeInsets.only(bottom: 2, left: 3, right: 3),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey700, width: 0.85),
        ),
      ),
      child: pw.Text(
        text.isNotEmpty ? text : ' ',
        textAlign: textAlign,
        style: pw.TextStyle(
          font: fontWeight == pw.FontWeight.bold ? loraBold : loraRegular,
          fontSize: 11.5,
          color: _kPdfInkBlue,
        ),
      ),
    );
  }

  String v(String key) => doc[key]?.toString().trim() ?? '';

  final outwardNo = v('outwardNo');
  final outwardYear = v('outwardYear').isNotEmpty ? v('outwardYear') : '2021';
  final psName = v('psName').isNotEmpty ? v('psName') : 'Wakad Police Station,';
  final psCity = v('psCity').isNotEmpty ? v('psCity') : 'Pimpri Chichwad.';
  final date = v('date').isNotEmpty
      ? v('date')
      : '${v('dateDay')} ${v('dateMonthYear')}'.trim();

  final courtLine1 = v('courtLine1');
  final courtLine2 = v('courtLine2');

  final officerName =
      v('officerName').isNotEmpty ? v('officerName') : 'Jitendra S. Girnar';
  final officerRank =
      v('officerRank').isNotEmpty ? v('officerRank') : 'Police Sub Inpector';
  final officerPs = v('officerPs').isNotEmpty
      ? v('officerPs')
      : 'Wakad Police Station, Pimpri Chichwad.';
  final subjectHours = v('subjectHours').isNotEmpty ? v('subjectHours') : '72';

  final bodyText = v('body').isNotEmpty
      ? v('body')
      : '    Regarding the above mentioned subject, most humbly request that a complaint has been registered at Wakad Police Station, Pimpri Chinchwad with FIR No. 912/2021 u/s 377,498(A), 347,504,34 of IPC by complainant Mrs. Sushama Chalamalasetti, Age 31 years, Profession house wife, residing at B901, Titanium Park, Park Street, Wakad Pune. The name of the accused being 1) Mahesh Babu Gunukula, Age 36 ears profession Service, residing at D No. 4, 153, Gudlavaleru, Gudlavaleru MDL 521356, Crishna District Andhra Pradesh and 2) Shiva Prasad Gunukula, Age 63 years (relation father in law). Against he complainant the accused conspired to get the property of complainant at Mumbai which is joint name with her mother and the property in USA. On decline to transfer the property in accused husbands name they harassed her confired her in a room further mentally and physically harassed her. The accused no. 1 also had unnatural sexual offence against the wish of the complainant. The same has been registered under the above mention complainant and I am Investigating the same.\n\n'
          '    During Investigation I had arrest accuse no. 1) Mahesh Babu Gunukula, Age 36 ears profession Service, residing at D No. 4, 153, Gudlavaleru, Gudlavaleru MDL 521356, Crishna District Andhra Pradesh in --------- Police station at --------am/pm on dt.   /11/2021 wide station diary no. ----/21.\n\n'
          '    To produce accused before Hon. JMFC., No.09, Shivajinagar, Pune I want transit remand of accused for 2 hrs. so please give me transit remand of accused.';

  final signOffName =
      v('signOffName').isNotEmpty ? v('signOffName') : officerName;

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 50, vertical: 46),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header block
          pw.SizedBox(
            width: 300,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Outward No.  ', style: boldStyle),
                    pw.Expanded(
                      child: underlineField(outwardNo),
                    ),
                    pw.Text(' / ', style: boldStyle),
                    pw.SizedBox(
                      width: 50,
                      child: underlineField(
                        outwardYear,
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                underlineField(psName, width: double.infinity),
                pw.SizedBox(height: 6),
                underlineField(psCity, width: double.infinity),
                pw.SizedBox(height: 6),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Date -  ', style: boldStyle),
                    underlineField(date, width: 140),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 22),

          // To
          pw.Text('To,', style: titleStyle),
          pw.SizedBox(height: 7),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Hon.- ', style: boldStyle),
              pw.Expanded(
                child: underlineField(courtLine1),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          underlineField(courtLine2, width: double.infinity),

          pw.SizedBox(height: 20),

          // Report
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Report- ', style: boldStyle),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: underlineField(officerName),
                        ),
                        pw.Text(' , ', style: boldStyle),
                        pw.Expanded(
                          flex: 3,
                          child: underlineField(officerRank),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    underlineField(officerPs, width: double.infinity),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // Sub
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Sub- To get Transit Remand for ', style: boldStyle),
              underlineField(
                subjectHours,
                width: 48,
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(' hrs.', style: boldStyle),
            ],
          ),

          pw.SizedBox(height: 16),

          // ---000---
          pw.Text('---000---', style: boldStyle),

          pw.SizedBox(height: 16),

          // Respected Sir
          pw.Text('Respected Sir,', style: boldStyle),
          pw.SizedBox(height: 8),

          // Body
          pw.Text(
            bodyText,
            style: bodyStyle,
            textAlign: pw.TextAlign.left,
          ),

          pw.SizedBox(height: 36),

          // Your Faithfully
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Your Faithfully', style: boldStyle),
              pw.SizedBox(height: 24),
              underlineField(signOffName, width: 220),
            ],
          ),
        ],
      ),
    ),
  );

  return pdf.save();
}
