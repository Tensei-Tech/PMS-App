import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:google_fonts/google_fonts.dart';
import 'marathi_text_renderer.dart';
import 'pdf_font_cache.dart';
import '../widgets/form_section_utils.dart';
import 'form_image_pdf_helper.dart';

Future<void> previewFinalReportPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final fileName =
      'Final_Report_Form_${DateTime.now().millisecondsSinceEpoch}.pdf';
  final active = doc['formSection']?.toString().trim();
  List<Widget> pages;
  if (active == 'Final Report Part I') {
    pages = [_buildFrPg1Widget(doc)];
  } else if (active == 'Final Report Part II') {
    pages = [_buildFrPg2Widget(doc)];
  } else if (active == 'Final Report Part III') {
    pages = [_buildFrPg3Widget(doc)];
  } else if (active == 'Final Report Part IV') {
    pages = [_buildFrPg4Widget(doc)];
  } else {
    pages = [
      _buildFrPg1Widget(doc),
      _buildFrPg2Widget(doc),
      _buildFrPg3Widget(doc),
      _buildFrPg4Widget(doc),
    ];
  }

  await FormImagePdfHelper.previewImageBasedPdf(
    context,
    fileName: fileName,
    pages: pages,
    fallbackPdfGenerator: () => generateFinalReportPdf(doc),
  );
}

Future<Uint8List> generateFinalReportPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final loraRegular = await PdfFontCache.loraRegular();
  final loraBold = await PdfFontCache.loraBold();
  final devanagariRegular = await PdfFontCache.devanagariRegular();
  final devanagariBold = await PdfFontCache.devanagariBold();

  const knownSectionIds = {
    'Final Report Part I',
    'Final Report Part II',
    'Final Report Part III',
    'Final Report Part IV',
  };
  final activeSection = doc['formSection']?.toString();

  bool showsSection(String sectionId) => showsFormSection(
        activeSection: activeSection,
        sectionId: sectionId,
        knownSectionIds: knownSectionIds,
      );

  final cache = await _preRenderAllMarathi(doc, showsSection: showsSection);

  final englishStyle = pw.TextStyle(
    font: loraRegular,
    fontSize: 8,
    color: PdfColors.black,
  );
  final englishBold = pw.TextStyle(
    font: loraBold,
    fontSize: 8,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.black,
  );
  final mrRegular = pw.TextStyle(
    font: devanagariRegular,
    fontSize: 8,
    color: PdfColors.black,
  );
  final mrBold = pw.TextStyle(
    font: devanagariBold,
    fontSize: 8,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.black,
  );
  final headerStyle = pw.TextStyle(
    font: loraBold,
    fontSize: 13,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.black,
  );
  final valueStyle = pw.TextStyle(
    font: loraRegular,
    fontSize: 8,
    color: PdfColors.black,
  );

  pw.Widget val(String key, String? text) {
    final t = text?.trim() ?? '';
    if (t.isEmpty) return pw.SizedBox();
    if (containsDevanagari(t)) {
      if (cache.has(key)) return cache.img(key);
      return pw.Text(t, style: mrRegular);
    }
    return pw.Text(t, style: valueStyle);
  }

  pw.Widget field(String label, String key, String? fallback,
      {double width = 0}) {
    final isMr = containsDevanagari(label);
    final child = pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
      ),
      padding: const pw.EdgeInsets.only(left: 3, bottom: 1),
      child: val(key, fallback),
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        mainAxisSize: width > 0 ? pw.MainAxisSize.min : pw.MainAxisSize.max,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(label, style: isMr ? mrBold : englishBold),
          if (width > 0)
            pw.SizedBox(width: width, child: child)
          else
            pw.Expanded(child: child),
        ],
      ),
    );
  }

  pw.Widget multiline(String label, String key, String? text, {int lines = 4}) {
    final content = text?.trim() ?? '';
    final split = _splitLines(content, 90);
    final count = split.length > lines ? split.length : lines;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: englishBold),
        pw.SizedBox(height: 2),
        for (var i = 0; i < count; i++)
          pw.Container(
            width: double.infinity,
            margin: const pw.EdgeInsets.only(bottom: 2),
            padding: const pw.EdgeInsets.only(left: 4, bottom: 1),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
            ),
            child: i < split.length
                ? val('${key}_$i', split[i])
                : pw.SizedBox(height: 9),
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // PAGE 1 — Sections 1 to 10
  // ══════════════════════════════════════════════════════════════════
  if (showsSection('Final Report Part I')) {
    final propCount =
        int.tryParse(doc['propertyRowCount']?.toString() ?? '') ?? 2;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(child: pw.Text('FINAL REPORT FORM', style: headerStyle)),
            pw.Center(
              child: cache.has('title_mr')
                  ? cache.img('title_mr')
                  : pw.Text('अंतिम अहवाल नमुना', style: englishStyle),
            ),
            pw.Center(
              child: pw.Text('( UNDER SECTION 193 B.N.S.S.2023 )',
                  style: englishBold),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('IN THE COURT OF : ', style: englishBold),
                if (cache.has('label_court_mr')) cache.img('label_court_mr'),
                pw.Expanded(
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
                    ),
                    padding: const pw.EdgeInsets.only(left: 3, bottom: 1),
                    child: val('val_court', doc['court']?.toString()),
                  ),
                ),
                pw.SizedBox(width: 6),
                if (cache.has('label_dist_mr')) cache.img('label_dist_mr'),
                pw.SizedBox(
                  width: 80,
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
                    ),
                    padding: const pw.EdgeInsets.only(left: 3, bottom: 1),
                    child: val('val_courtDist', doc['courtDist']?.toString()),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 5),
            // Row 1: Dist + P.S + Year
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('1.Dist : ', style: englishBold),
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                    child: val('val_dist', doc['dist']?.toString()),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Text('P.S: ', style: englishBold),
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                    child: val('val_ps', doc['ps']?.toString()),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Text('Year : 20', style: englishBold),
                pw.SizedBox(
                  width: 30,
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                    child: val('val_year', doc['year']?.toString()),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            // Row 2: FIR No + Date
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('FIRNo : ', style: englishBold),
                pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                    child: val('val_firNo', doc['firNo']?.toString()),
                  ),
                ),
                pw.Text('/', style: englishBold),
                pw.SizedBox(
                  width: 45,
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                    child: val(
                        'val_firYearSuffix', doc['firYearSuffix']?.toString()),
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Text('Date : ', style: englishBold),
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                    child: val('val_headerDate', doc['headerDate']?.toString()),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 5),
            pw.Row(
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('2. Final Report/Charge Sheet No. ',
                          style: englishBold),
                      pw.Expanded(
                        child: pw.Container(
                          decoration: const pw.BoxDecoration(
                              border:
                                  pw.Border(bottom: pw.BorderSide(width: 0.5))),
                          child:
                              val('val_reportNo', doc['reportNo']?.toString()),
                        ),
                      ),
                      pw.Text('/20', style: englishBold),
                      pw.SizedBox(
                        width: 25,
                        child: pw.Container(
                          decoration: const pw.BoxDecoration(
                              border:
                                  pw.Border(bottom: pw.BorderSide(width: 0.5))),
                          child: val('val_reportYearSuffix',
                              doc['reportYearSuffix']?.toString()),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  flex: 2,
                  child: field('3.Date: ', 'val_reportDate',
                      doc['reportDate']?.toString()),
                ),
              ],
            ),
            pw.SizedBox(height: 5),
            pw.Row(
              children: [
                pw.Expanded(
                    flex: 3,
                    child:
                        field('4. Act : ', 'val_act', doc['act']?.toString())),
                pw.SizedBox(width: 12),
                pw.Expanded(
                    flex: 2,
                    child: field('Section: ', 'val_section',
                        doc['section']?.toString())),
              ],
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              '5. Type of Final Form /Report : Charge Sheeted/Not charge sheeted for want of evidence/ FR Undetect/FR untraced/FR offence abated/FR Unoccured :',
              style: englishBold,
            ),
            field('   ', 'val_reportType', doc['reportType']?.toString()),
            pw.SizedBox(height: 4),
            pw.Text(
              '6. If F.R. Unoccured : False/Mistake of Fact/Mistake of Law/Non-cognizable/Civil Nature :',
              style: englishBold,
            ),
            field('   ', 'val_frUnoccurred', doc['frUnoccurred']?.toString()),
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                pw.Expanded(
                  child: field('7. If Charge Sheeted : ( जर आरोपपत्र ठेवले ) ',
                      'val_chargeSheeted', doc['chargeSheeted']?.toString()),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: field('Original Supplementary ( मुळ/पुरवणी ) : ',
                      'val_origSupp', doc['originalSupplementary']?.toString()),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                pw.Expanded(
                    flex: 3,
                    child: field('8. Name of the I.O : ', 'val_ioName',
                        doc['ioName']?.toString())),
                pw.SizedBox(width: 8),
                pw.Expanded(
                    flex: 2,
                    child: field(
                        'Rank : ', 'val_ioRank', doc['ioRank']?.toString())),
                pw.SizedBox(width: 8),
                pw.SizedBox(
                    width: 65,
                    child:
                        field('No. : ', 'val_ioNo', doc['ioNo']?.toString())),
              ],
            ),
            field('   Police Station / पोलीस स्टेशन: ', 'val_ioPs',
                doc['ioPs']?.toString()),
            pw.SizedBox(height: 4),
            field('9. (a) Name of Complainant/Informant : ',
                'val_complainantName', doc['complainantName']?.toString()),
            field('   (b) Father\'s/Husband\'s Name : ',
                'val_complainantFather', doc['complainantFather']?.toString()),
            pw.SizedBox(height: 6),
            pw.Text(
              '10. Details of Properties/Articles/Documents recovered/seized during investigation and relied upon : Enclosed with C/S.( separate list can be attached, if necessary )',
              style: englishBold,
            ),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
              columnWidths: const {
                0: pw.FixedColumnWidth(28),
                1: pw.FlexColumnWidth(2.6),
                2: pw.FlexColumnWidth(1.4),
                3: pw.FlexColumnWidth(1.6),
                4: pw.FlexColumnWidth(2.2),
                5: pw.FlexColumnWidth(1.4),
              },
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text('Sr.No\nअ.क्र',
                            style: englishBold,
                            textAlign: pw.TextAlign.center)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text('Property Description\nमालमत्तेचे वर्णन',
                            style: englishBold,
                            textAlign: pw.TextAlign.center)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text('Estimated Value\n(in Rs.)',
                            style: englishBold,
                            textAlign: pw.TextAlign.center)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text('P.S. Property\nRegister No.',
                            style: englishBold,
                            textAlign: pw.TextAlign.center)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text('From whom/where\nRecovered or Seized',
                            style: englishBold,
                            textAlign: pw.TextAlign.center)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text('Disposal\nविल्हेवाट',
                            style: englishBold,
                            textAlign: pw.TextAlign.center)),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text('1',
                            style: englishBold,
                            textAlign: pw.TextAlign.center)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text('2',
                            style: englishBold,
                            textAlign: pw.TextAlign.center)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text('3',
                            style: englishBold,
                            textAlign: pw.TextAlign.center)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text('4',
                            style: englishBold,
                            textAlign: pw.TextAlign.center)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text('5',
                            style: englishBold,
                            textAlign: pw.TextAlign.center)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text('6',
                            style: englishBold,
                            textAlign: pw.TextAlign.center)),
                  ],
                ),
                for (var i = 1; i <= propCount; i++)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Text('$i.',
                              style: englishBold,
                              textAlign: pw.TextAlign.center)),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: val('val_prop${i}Desc',
                              doc['prop${i}Desc']?.toString())),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: val('val_prop${i}Value',
                              doc['prop${i}Value']?.toString())),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: val('val_prop${i}Reg',
                              doc['prop${i}Reg']?.toString())),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: val('val_prop${i}From',
                              doc['prop${i}From']?.toString())),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: val('val_prop${i}Disposal',
                              doc['prop${i}Disposal']?.toString())),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // PAGE 2 — Sections 11 & 12
  // ══════════════════════════════════════════════════════════════════
  if (showsSection('Final Report Part II')) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Align(
                alignment: pw.Alignment.topRight,
                child: pw.Text('Page : 2', style: englishBold)),
            pw.SizedBox(height: 4),
            pw.Text(
              '11. i) Particulars of accused persons charge-sheeted ( use separate sheet for each accused ) : आरोपपत्र ठेवलेल्या आरोपीचा तपशिल ( प्रत्येक आरोपीसाठी स्वतंत्र कागद वापरावा ) :',
              style: englishBold,
            ),
            pw.SizedBox(height: 6),
            pw.Row(
              children: [
                pw.Expanded(
                    flex: 3,
                    child: field('(i) Name : ', 'val_accName',
                        doc['accName']?.toString())),
                pw.SizedBox(width: 10),
                pw.Expanded(
                    flex: 2,
                    child: field('Where verified : ', 'val_accNameVerified',
                        doc['accNameVerified']?.toString())),
              ],
            ),
            field('(ii) Father\'s/Husband\'s Name : ', 'val_accFather',
                doc['accFather']?.toString()),
            pw.Row(
              children: [
                pw.Expanded(
                    flex: 3,
                    child: field('(iii) Date/Year of Birth ( जन्मतारीख ) : ',
                        'val_accDob', doc['accDob']?.toString())),
                pw.SizedBox(width: 10),
                pw.SizedBox(
                    width: 80,
                    child: field('Age / वय : ', 'val_accAge',
                        doc['accAge']?.toString())),
              ],
            ),
            pw.Row(
              children: [
                pw.Expanded(
                    child: field('(iv) Sex / लिंग : ', 'val_accSex',
                        doc['accSex']?.toString())),
                pw.SizedBox(width: 10),
                pw.Expanded(
                    child: field(
                        '(v) Nationality / राष्ट्रीयत्व : ',
                        'val_accNationality',
                        doc['accNationality']?.toString())),
              ],
            ),
            pw.Row(
              children: [
                pw.Expanded(
                    child: field('(vi) Passport No. : ', 'val_accPassport',
                        doc['accPassport']?.toString())),
                pw.SizedBox(width: 8),
                pw.Expanded(
                    child: field('Date of issue : ', 'val_accPassportDate',
                        doc['accPassportDate']?.toString())),
                pw.SizedBox(width: 8),
                pw.Expanded(
                    child: field('Place of Issue : ', 'val_accPassportPlace',
                        doc['accPassportPlace']?.toString())),
              ],
            ),
            pw.Row(
              children: [
                pw.Expanded(
                    child: field('(vii) Religion / धर्म : ', 'val_accReligion',
                        doc['accReligion']?.toString())),
                pw.SizedBox(width: 10),
                pw.Expanded(
                    child: field('(viii) Whether SC/ST : ', 'val_accScSt',
                        doc['accScSt']?.toString())),
              ],
            ),
            field('(ix) Occupation (व्यवसाय) : ', 'val_accOccupation',
                doc['accOccupation']?.toString()),
            field('(x) Address ( पत्ता ) : ', 'val_accAddress',
                doc['accAddress']?.toString()),
            field(
                '    Whether verified (पडताळला किंवा काय) : ',
                'val_accAddressVerified',
                doc['accAddressVerified']?.toString()),
            field('(xi) Provisional Criminal No. (तात्पूरता गुन्हेगार क्र.) : ',
                'val_accProvCriminalNo', doc['accProvCriminalNo']?.toString()),
            field(
                '(xii) Regular Criminal No. ( नियमित गुन्हेगार क्र.) : ',
                'val_accRegularCriminalNo',
                doc['accRegularCriminalNo']?.toString()),
            pw.Row(
              children: [
                pw.Expanded(
                    child: field(
                        '(xiii) Date of Arrest (अटकेची तारीख.) : दिनांक ',
                        'val_accArrestDate',
                        doc['accArrestDate']?.toString())),
                pw.SizedBox(width: 8),
                pw.SizedBox(
                    width: 110,
                    child: field('वाजता : ', 'val_accArrestTime',
                        doc['accArrestTime']?.toString())),
              ],
            ),
            field(
                '(xiv) Date of release on bail (जामीनावर सोडल्याची तारीख.) : ',
                'val_accBailDate',
                doc['accBailDate']?.toString()),
            field(
                '(xv) Date on which forwarded to court (न्यायालयात पाठविल्याची तारीख.): ',
                'val_accForwardedCourt',
                doc['accForwardedCourt']?.toString()),
            field(
                '(xvi) Under Acts & Section ( कोणत्या अधिनियमाखाली व कलमाखाली ) : ',
                'val_accActsSections',
                doc['accActsSections']?.toString()),
            field(
                '(xvii) Name (s) of bailers/sureties and Address ( जामीनदारांची नांवे व पत्ते ) : ',
                'val_accBailers',
                doc['accBailers']?.toString()),
            field(
                '(xviii) Previous convictions with case reference : ',
                'val_accPrevConvictions',
                doc['accPrevConvictions']?.toString()),
            field('(xix) Status of the accused (आरोपीची स्थिती) : ',
                'val_accStatus', doc['accStatus']?.toString()),
            pw.Text(
              'Forwarded/Bailed by Police/In Police Custody/Bailed by Court/In Judicial Custody/Absconding/Proclaimed Offender',
              style: englishStyle,
            ),
            pw.SizedBox(height: 8),
            field('12. आरोप पत्र न ठेवलेल्या आरोपीचा तपशिल: ',
                'val_notChargeSheeted', doc['notChargeSheeted']?.toString()),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // PAGE 3 — Sections 13 to 15
  // ══════════════════════════════════════════════════════════════════
  if (showsSection('Final Report Part III')) {
    final witnessCount =
        int.tryParse(doc['witnessRowCount']?.toString() ?? '') ?? 7;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Align(
                alignment: pw.Alignment.topRight,
                child: pw.Text('Page : 3', style: englishBold)),
            pw.SizedBox(height: 4),
            field('13. पडताळलेल्या साक्षटारांचे विवरण: ', 'val_witnessDesc',
                doc['witnessDesc']?.toString()),
            pw.SizedBox(height: 4),
            pw.Center(
              child: cache.has('witness_header_mr')
                  ? cache.img('witness_header_mr')
                  : pw.Text('साक्षीदारांची यादी.', style: englishBold),
            ),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
              columnWidths: const {
                0: pw.FixedColumnWidth(28),
                1: pw.FlexColumnWidth(2.4),
                2: pw.FixedColumnWidth(40),
                3: pw.FlexColumnWidth(1.4),
                4: pw.FlexColumnWidth(2.6),
                5: pw.FlexColumnWidth(2.2),
              },
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text('अ.क्र',
                            style: englishBold,
                            textAlign: pw.TextAlign.center)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text('साक्षीदारांचे नांव',
                            style: englishBold,
                            textAlign: pw.TextAlign.center)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text('वय',
                            style: englishBold,
                            textAlign: pw.TextAlign.center)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text('व्यवसाय',
                            style: englishBold,
                            textAlign: pw.TextAlign.center)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text('राहण्याचा पत्ता',
                            style: englishBold,
                            textAlign: pw.TextAlign.center)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text('सादर करावयाच्या\nपुराव्याचा प्रकार',
                            style: englishBold,
                            textAlign: pw.TextAlign.center)),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text('1',
                            style: englishBold,
                            textAlign: pw.TextAlign.center)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text('2',
                            style: englishBold,
                            textAlign: pw.TextAlign.center)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text('3',
                            style: englishBold,
                            textAlign: pw.TextAlign.center)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text('4',
                            style: englishBold,
                            textAlign: pw.TextAlign.center)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text('5',
                            style: englishBold,
                            textAlign: pw.TextAlign.center)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text('6',
                            style: englishBold,
                            textAlign: pw.TextAlign.center)),
                  ],
                ),
                for (var i = 1; i <= witnessCount; i++)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: pw.Text('$i.',
                              style: englishBold,
                              textAlign: pw.TextAlign.center)),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: val('val_witness${i}Name',
                              doc['witness${i}Name']?.toString())),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: val('val_witness${i}Age',
                              doc['witness${i}Age']?.toString())),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: val('val_witness${i}Occupation',
                              doc['witness${i}Occupation']?.toString())),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: val('val_witness${i}Address',
                              doc['witness${i}Address']?.toString())),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(3),
                          child: val('val_witness${i}Evidence',
                              doc['witness${i}Evidence']?.toString())),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              '14. If F. I. R. is False, indicate action taken or proposed to be taken u/s 182/211 I. P. C.',
              style: englishBold,
            ),
            pw.Text(
              '(तकार खोटी असेल तर भादंवि १८२/२११ अन्वये केलेली किंवा करावयाची कार्यवाही नमुद करावी.)',
              style: englishStyle,
            ),
            field(
                '   ', 'val_falseFirAction', doc['falseFirAction']?.toString()),
            pw.SizedBox(height: 8),
            field(
                '15. Result of laboratory analysis (प्रयोगशाळा विश्लेषकाचा निष्कर्ष) : ',
                'val_labAnalysis',
                doc['labAnalysis']?.toString()),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // PAGE 4 — Sections 16 to 18 & Signatures (Form : 5 E)
  // ══════════════════════════════════════════════════════════════════
  if (showsSection('Final Report Part IV') ||
      showsSection('Final Report Part III')) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Align(
                alignment: pw.Alignment.topRight,
                child: pw.Text('Form : 5 E', style: englishBold)),
            pw.SizedBox(height: 4),
            pw.Text(
              '16. Brief Facts of the Case (Add separate sheet, if necessary.)',
              style: englishBold,
            ),
            pw.Text(
              '    थोडक्यात माहिती ( आवश्यक असल्यास वेगळा कागद जोडावा. ) :',
              style: englishStyle,
            ),
            pw.Text('महोदय,', style: englishBold),
            pw.SizedBox(height: 4),
            multiline('', 'briefFacts', doc['briefFacts']?.toString(),
                lines: 14),
            pw.SizedBox(height: 8),
            pw.Text('टिप :-', style: englishBold),
            pw.Row(
              children: [
                pw.Expanded(
                    child: field(
                        '17. Refer Notice Served : ',
                        'val_referNoticeServed',
                        doc['referNoticeServed']?.toString())),
                pw.SizedBox(width: 12),
                pw.SizedBox(
                    width: 140,
                    child: field('Date : ', 'val_referNoticeDate',
                        doc['referNoticeDate']?.toString())),
              ],
            ),
            pw.Text('    ( Acknowledgement to be placed )',
                style: englishStyle),
            pw.SizedBox(height: 6),
            field('18. Dispatched on : ', 'val_dispatchedOn',
                doc['dispatchedOn']?.toString()),
            pw.SizedBox(height: 20),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                          'Forwarded by Station House\nOfficer/officer in-charge',
                          style: englishBold),
                      pw.SizedBox(height: 8),
                      field(
                          'Name : ', 'val_shoName', doc['shoName']?.toString()),
                      pw.Row(
                        children: [
                          pw.Expanded(
                              child: field('Rank : ', 'val_shoRank',
                                  doc['shoRank']?.toString())),
                          pw.SizedBox(width: 6),
                          pw.SizedBox(
                              width: 50,
                              child: field('No : ', 'val_shoNo',
                                  doc['shoNo']?.toString())),
                        ],
                      ),
                      field('', 'val_shoPs', doc['shoPs']?.toString()),
                    ],
                  ),
                ),
                pw.SizedBox(width: 24),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Signature of the Investigation Officer\nsubmitting the Final Report/Charge\nSheet.',
                        style: englishBold,
                      ),
                      pw.SizedBox(height: 8),
                      field('Name : ', 'val_submitIoName',
                          doc['submitIoName']?.toString()),
                      pw.Row(
                        children: [
                          pw.Expanded(
                              child: field('Rank : ', 'val_submitIoRank',
                                  doc['submitIoRank']?.toString())),
                          pw.SizedBox(width: 6),
                          pw.SizedBox(
                              width: 50,
                              child: field('No. : ', 'val_submitIoNo',
                                  doc['submitIoNo']?.toString())),
                        ],
                      ),
                      field(
                          '', 'val_submitIoPs', doc['submitIoPs']?.toString()),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  return pdf.save();
}

List<String> _splitLines(String text, int maxChars) {
  if (text.isEmpty) return [];
  final result = <String>[];
  for (final para in text.split('\n')) {
    if (para.isEmpty) {
      result.add('');
      continue;
    }
    var line = '';
    for (final word in para.split(' ')) {
      if (line.isEmpty) {
        line = word;
      } else if ('$line $word'.length <= maxChars) {
        line = '$line $word';
      } else {
        result.add(line);
        line = word;
      }
    }
    if (line.isNotEmpty) result.add(line);
  }
  return result;
}

Future<MarathiImageCache> _preRenderAllMarathi(
  Map<String, dynamic> doc, {
  bool Function(String section)? showsSection,
}) async {
  final cache = MarathiImageCache();
  final showPart1 = showsSection == null || showsSection('Final Report Part I');
  final showPart2 = showsSection == null || showsSection('Final Report Part II');
  final showPart3 = showsSection == null || showsSection('Final Report Part III');
  final showPart4 = showsSection == null || showsSection('Final Report Part IV');

  final labelStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 9,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  ).copyWith(
    fontFamilyFallback: kMarathiFallbackFonts,
  );
  final valueStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 9,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  ).copyWith(
    fontFamilyFallback: kMarathiFallbackFonts,
  );

  if (showPart1) {
    await cache.add('title_mr', 'अंतिम अहवाल नमुना', labelStyle);
    await cache.add('label_court_mr',
        'मा.वि.न्यायदंडाधिकारी प्रथम श्रेणी,न्यायालय ', labelStyle);
    await cache.add('label_dist_mr', 'जिल्हा ', labelStyle);
  }
  if (showPart4) {
    await cache.add('witness_header_mr', 'साक्षीदारांची यादी.', labelStyle);
  }

  Future<void> addVal(String key, String? v) async {
    final t = v?.trim() ?? '';
    if (containsDevanagari(t)) {
      await cache.add(key, t, valueStyle, maxWidth: 480);
    }
  }

  final part1Keys = [
    'court',
    'courtDist',
    'dist',
    'ps',
    'year',
    'firNo',
    'firYearSuffix',
    'headerDate',
    'reportNo',
    'reportYearSuffix',
    'reportDate',
    'act',
    'section',
    'reportType',
    'reportTypeCustom',
    'frUnoccurred',
    'chargeSheeted',
    'originalSupplementary',
    'ioName',
    'ioRank',
    'ioNo',
    'ioPs',
    'complainantName',
    'complainantFather',
  ];
  final part2Keys = [
    'accName',
    'accNameVerified',
    'accFather',
    'accDob',
    'accAge',
    'accSex',
    'accNationality',
    'accPassport',
    'accPassportDate',
    'accPassportPlace',
    'accReligion',
    'accScSt',
    'accOccupation',
    'accAddress',
    'accAddressVerified',
    'accProvCriminalNo',
    'accRegularCriminalNo',
    'accArrestDate',
    'accArrestTime',
    'accBailDate',
    'accForwardedCourt',
    'accActsSections',
    'accBailers',
    'accPrevConvictions',
    'accStatus',
    'notChargeSheeted',
  ];
  final part4Keys = [
    'witnessDesc',
    'falseFirAction',
    'labAnalysis',
    'referNoticeServed',
    'referNoticeDate',
    'dispatchedOn',
    'shoName',
    'shoRank',
    'shoNo',
    'shoPs',
    'submitIoName',
    'submitIoRank',
    'submitIoNo',
    'submitIoPs',
  ];

  if (showPart1) {
    for (final k in part1Keys) {
      await addVal('val_$k', doc[k]?.toString());
    }
  }
  if (showPart2) {
    for (final k in part2Keys) {
      await addVal('val_$k', doc[k]?.toString());
    }
  }
  if (showPart3) {
    for (var i = 1; i <= 10; i++) {
      for (final col in ['Desc', 'Value', 'Reg', 'From', 'Disposal']) {
        await addVal('val_prop$i$col', doc['prop$i$col']?.toString());
      }
    }
  }
  if (showPart4) {
    for (final k in part4Keys) {
      await addVal('val_$k', doc[k]?.toString());
    }
    for (var i = 1; i <= 20; i++) {
      for (final col in ['Name', 'Age', 'Occupation', 'Address', 'Evidence']) {
        await addVal('val_witness$i$col', doc['witness$i$col']?.toString());
      }
    }
  }

  final multilineEntries = [
    if (showPart1) ...[
      ('reportType', doc['reportType']?.toString() ?? ''),
      ('frUnoccurred', doc['frUnoccurred']?.toString() ?? ''),
    ],
    if (showPart2) ...[
      ('notChargeSheeted', doc['notChargeSheeted']?.toString() ?? ''),
    ],
    if (showPart4) ...[
      ('falseFirAction', doc['falseFirAction']?.toString() ?? ''),
      ('briefFacts', doc['briefFacts']?.toString() ?? ''),
    ],
  ];
  for (final entry in multilineEntries) {
    final lines = _splitLines(entry.$2, 90);
    for (var i = 0; i < lines.length; i++) {
      if (containsDevanagari(lines[i])) {
        await cache.add('${entry.$1}_$i', lines[i], valueStyle, maxWidth: 480);
      }
    }
  }
  return cache;
}

TextStyle _serifStyle([
  double sz = 12.0,
  FontWeight fw = FontWeight.w600,
]) =>
    GoogleFonts.lora(
      fontSize: sz,
      fontWeight: fw,
      color: Colors.black87,
    ).copyWith(
      fontFamilyFallback: [
        GoogleFonts.notoSansDevanagari().fontFamily!,
        ...kMarathiFallbackFonts,
      ],
    );

TextStyle _eBld([double sz = 11.0]) => GoogleFonts.lora(
      fontSize: sz,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    ).copyWith(
      fontFamilyFallback: [
        GoogleFonts.notoSansDevanagari().fontFamily!,
        ...kMarathiFallbackFonts,
      ],
    );

TextStyle _mBld([double sz = 10.0]) => GoogleFonts.notoSansDevanagari(
      fontSize: sz,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    ).copyWith(
      fontFamilyFallback: kMarathiFallbackFonts,
    );

TextStyle _valStyle([double sz = 10.5]) => GoogleFonts.notoSansDevanagari(
      fontSize: sz,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    ).copyWith(
      fontFamilyFallback: kMarathiFallbackFonts,
    );


class _FullWidthUnderlinePainter extends CustomPainter {
  final int lineCount;
  final double lineHeight;

  const _FullWidthUnderlinePainter({
    required this.lineCount,
    this.lineHeight = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final count = lineCount > 0 ? lineCount : 1;
    for (int i = 1; i <= count; i++) {
      final y = (i * lineHeight - 1.0).clamp(0.0, size.height);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FullWidthUnderlinePainter oldDelegate) {
    return oldDelegate.lineCount != lineCount ||
        oldDelegate.lineHeight != lineHeight;
  }
}

class _PdfUnderlineField extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const _PdfUnderlineField({
    required this.text,
    this.style,
  });

  static const double _lineHeight = 20.0;

  @override
  Widget build(BuildContext context) {
    final fontSize = style?.fontSize ?? 10.5;
    final effectiveStyle = GoogleFonts.notoSansDevanagari(
      fontSize: fontSize,
      fontWeight: style?.fontWeight ?? FontWeight.w600,
      color: style?.color ?? Colors.black87,
      height: _lineHeight / fontSize,
    ).copyWith(
      fontFamilyFallback: kMarathiFallbackFonts,
    );

    final raw = text.trim();
    if (raw.isEmpty) {
      return const SizedBox(
        height: _lineHeight,
        child: CustomPaint(
          size: Size(double.infinity, _lineHeight),
          painter: _FullWidthUnderlinePainter(lineCount: 1, lineHeight: _lineHeight),
        ),
      );
    }

    String displayText = raw;
    if (raw.contains('\n')) {
      displayText = raw;
    } else if (raw.contains(' / ')) {
      final parts = raw.split(' / ');
      displayText =
          '${parts[0].trim()}\n${parts.sublist(1).join(' / ').trim()}';
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : 100.0;

        final tp = TextPainter(
          text: TextSpan(text: displayText, style: effectiveStyle),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.start,
        );
        tp.layout(maxWidth: availableWidth);
        final metrics = tp.computeLineMetrics();
        final lineCount = metrics.isNotEmpty ? metrics.length : 1;
        final totalHeight = lineCount * _lineHeight;

        return SizedBox(
          width: constraints.maxWidth.isFinite ? constraints.maxWidth : null,
          height: totalHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _FullWidthUnderlinePainter(
                    lineCount: lineCount,
                    lineHeight: _lineHeight,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 2,
                right: 2,
                child: Text(
                  displayText,
                  textAlign: TextAlign.start,
                  style: effectiveStyle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget _pdfDatePickerField(String date, {double? width}) {
  return Container(
    width: width,
    padding: const EdgeInsets.only(bottom: 2, top: 2),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.black54, width: 1.0)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            date.trim(),
            style: _valStyle(10.5),
          ),
        ),
        const Icon(
          Icons.calendar_today,
          size: 14,
          color: Color(0xFF1976D2),
        ),
      ],
    ),
  );
}

Widget _pdfPoint1DateField(String date, {TextStyle? style}) {
  const double lineHeight = 20.0;
  final fontSize = style?.fontSize ?? 10.5;
  final effectiveStyle = GoogleFonts.notoSansDevanagari(
    fontSize: fontSize,
    fontWeight: style?.fontWeight ?? FontWeight.w600,
    color: style?.color ?? Colors.black87,
    height: lineHeight / fontSize,
  ).copyWith(
    fontFamilyFallback: kMarathiFallbackFonts,
  );

  return SizedBox(
    height: lineHeight,
    child: Stack(
      children: [
        const Positioned.fill(
          child: CustomPaint(
            painter: _FullWidthUnderlinePainter(
              lineCount: 1,
              lineHeight: lineHeight,
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(left: 2, right: 2, bottom: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    date.trim(),
                    textAlign: TextAlign.start,
                    style: effectiveStyle,
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  size: 13,
                  color: Color(0xFF1976D2),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _pdfTimePickerField(String time, {double? width}) {
  return Container(
    width: width,
    padding: const EdgeInsets.only(bottom: 2, top: 2),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.black54, width: 1.0)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            time.trim(),
            style: _valStyle(10.5),
          ),
        ),
        const Icon(
          Icons.access_time,
          size: 14,
          color: Color(0xFF1976D2),
        ),
      ],
    ),
  );
}

Widget _pdfTableCell(
  String text,
  TextStyle style, {
  TextAlign align = TextAlign.left,
}) {
  final clean = text.trim();
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    child: Text(
      clean.isEmpty ? ' ' : clean,
      textAlign: align,
      style: _valStyle(10.0),
    ),
  );
}

Widget _pdfTableHeader(String text, TextStyle style) {
  return Padding(
    padding: const EdgeInsets.all(5),
    child: Text(
      text,
      style: _mBld(9.5),
      textAlign: TextAlign.center,
    ),
  );
}

const _marathiNumbers = [
  '१.',
  '२.',
  '३.',
  '४.',
  '५.',
  '६.',
  '७.',
  '८.',
  '९.',
  '१०.',
  '११.',
  '१२.',
  '१३.',
  '१४.',
  '१५.',
  '१६.',
  '१७.',
  '१८.',
  '१९.',
  '२०.',
];

Widget _buildFrPageContainer({
  required List<Widget> children,
  String? formLabel,
  TextStyle? formLabelStyle,
}) {
  return Container(
    width: FormImagePdfHelper.a4Width,
    height: FormImagePdfHelper.a4Height,
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (formLabel != null)
          Align(
            alignment: Alignment.topRight,
            child: Text(
              formLabel,
              style: (formLabelStyle ?? _eBld(13))
                  .copyWith(decoration: TextDecoration.underline),
            ),
          ),
        if (formLabel != null) const SizedBox(height: 6),
        ...children,
      ],
    ),
  );
}

Widget _buildFrPg1Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final propCount =
      int.tryParse(doc['propertyRowCount']?.toString() ?? '') ?? 2;

  final serifStyle = _serifStyle(12.0);
  final marathiLabelStyle = _mBld(10.0);

  return _buildFrPageContainer(
    formLabel: 'Page : 1',
    formLabelStyle: serifStyle.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.bold,
    ),
    children: [
      Center(
        child: Column(
          children: [
            Text(
              'FINAL REPORT FORM',
              style: serifStyle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'अंतिम अहवाल नमुना',
              style: GoogleFonts.notoSansDevanagari(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '( UNDER SECTION 193 B.N.S.S.2023 )',
              style: serifStyle.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // IN THE COURT OF line
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'IN THE COURT OF : ',
            style: serifStyle.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            'मा.वि.न्यायदंडाधिकारी प्रथम श्रेणी,न्यायालय ',
            style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: _PdfUnderlineField(
              text: v('court'),
              style: serifStyle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'जिल्हा ',
            style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(
            width: 100,
            child: _PdfUnderlineField(
              text: v('courtDist'),
              style: serifStyle,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),

      // 1. Dist / P.S / Year / FIR No / Date
      // Row 1: District + Police Station + Year
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Dist
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('1.Dist : ',
                        style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: _PdfUnderlineField(
                        text: v('dist'),
                        style: serifStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '   जिल्हा—',
                  style: marathiLabelStyle.copyWith(fontSize: 9.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // P.S:
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('P.S: ',
                        style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: _PdfUnderlineField(
                        text: v('ps'),
                        style: serifStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'पोलीस ठाणे-',
                  style: marathiLabelStyle.copyWith(fontSize: 9.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Year : 20
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Year : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Text('20', style: serifStyle),
                  SizedBox(
                    width: 35,
                    child: _PdfUnderlineField(
                      text: v('year'),
                      style: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'वर्ष:-२०',
                style: marathiLabelStyle.copyWith(fontSize: 9.5),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 8),

      // Row 2: FIR No. + Date
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FIRNo :
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('FIRNo : ',
                        style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: _PdfUnderlineField(
                        text: v('firNo'),
                        style: serifStyle,
                      ),
                    ),
                    Text('/', style: serifStyle),
                    SizedBox(
                      width: 45,
                      child: _PdfUnderlineField(
                        text: v('firYearSuffix'),
                        style: serifStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'पहिली खबर क्र. /२०',
                  style: marathiLabelStyle.copyWith(fontSize: 9.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Date :
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Date : ',
                        style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: _pdfPoint1DateField(v('headerDate'), style: serifStyle),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'तारीख',
                  style: marathiLabelStyle.copyWith(fontSize: 9.5),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),

      // 2. Final Report / Charge Sheet No & 3. Date
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '2. Final Report/Charge Sheet No. ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: _PdfUnderlineField(
                        text: v('reportNo'),
                        style: serifStyle,
                      ),
                    ),
                    Text('/20', style: serifStyle),
                    SizedBox(
                      width: 32,
                      child: _PdfUnderlineField(
                        text: v('reportYearSuffix'),
                        style: serifStyle,
                      ),
                    ),
                  ],
                ),
                Text(
                  '   अंतिम अहवाल/आरोप पत्र क्र.',
                  style: marathiLabelStyle.copyWith(
                      fontSize: 9.5, color: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '3.Date: ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: _pdfDatePickerField(v('reportDate')),
                    ),
                  ],
                ),
                Text(
                  '   दिनांक:',
                  style: marathiLabelStyle.copyWith(
                      fontSize: 9.5, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),

      // 4. Act & Section
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '4. Act : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: _PdfUnderlineField(
                        text: v('act'),
                        style: serifStyle,
                      ),
                    ),
                  ],
                ),
                Text(
                  '   भारतीय न्याय संहिता २०२३',
                  style: marathiLabelStyle.copyWith(
                      fontSize: 9.5, color: Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Section: ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: _PdfUnderlineField(
                        text: v('section'),
                        style: serifStyle,
                      ),
                    ),
                  ],
                ),
                Text(
                  '   कलम',
                  style: marathiLabelStyle.copyWith(
                      fontSize: 9.5, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),

      // 5. Type of Final Form / Report
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '5. Type of Final Form /Report :',
            style: serifStyle.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Charge Sheeted/Not charge sheeted for want of evidence/ FR Undetect/FR untraced/FR offence abated/FR Unoccured :',
                  style: serifStyle.copyWith(fontSize: 10.0),
                ),
              ),
              SizedBox(
                width: 120,
                child: _PdfUnderlineField(
                  text: v('reportType'),
                  style: serifStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'अंतिम अहवालाचा प्रकार :आरोपपत्र दाखल केले/पुराव्या अभावी आरोपपत्र दाखल केले नाही/तपारा लागला नाही/ शोध लागला नाही/शपविला/घडलाच नाही :-',
                  style: marathiLabelStyle.copyWith(fontSize: 9.5),
                ),
              ),
              SizedBox(
                width: 160,
                child: _PdfUnderlineField(
                  text: v('reportTypeCustom'),
                  style: serifStyle,
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 10),

      // 6. If F.R. Unoccured
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '6. If F.R. Unoccured : False/Mistake of Fact/Mistake of Law/Non-cognizable/Civil Nature :',
                  style: serifStyle.copyWith(
                      fontWeight: FontWeight.bold, fontSize: 10.5),
                ),
              ),
              SizedBox(
                width: 120,
                child: _PdfUnderlineField(
                  text: v('frUnoccurred'),
                  style: serifStyle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'जर अंतिम अहवालाचा प्रकार घडला नाही : खोटी/वस्तुस्थितीची चूक/कायद्याची चूक/अदखलपात्र/दिवाणी स्वरूप........................................',
            style: marathiLabelStyle.copyWith(fontSize: 9.5),
          ),
        ],
      ),
      const SizedBox(height: 10),

      // 7. If Charge Sheeted
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '7. If Charge Sheeted : ( जर आरोपपत्र ठेवले ) ',
            style: serifStyle.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(
            width: 70,
            child: _PdfUnderlineField(
              text: v('chargeSheeted'),
              style: serifStyle,
            ),
          ),
          const SizedBox(width: 24),
          Text(
            'Original Supplementary ( मुळ/पुरवणी ) : ',
            style: serifStyle.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(
            width: 80,
            child: _PdfUnderlineField(
              text: v('originalSupplementary'),
              style: serifStyle,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),

      // 8. Name of the I.O / Rank / No / PS
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('8. Name of the I.O : ',
              style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            flex: 3,
            child: _PdfUnderlineField(
              text: v('ioName'),
              style: serifStyle,
            ),
          ),
          const SizedBox(width: 12),
          Text('Rank : ',
              style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            flex: 2,
            child: _PdfUnderlineField(
              text: v('ioRank'),
              style: serifStyle,
            ),
          ),
          const SizedBox(width: 12),
          Text('No. : ',
              style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(
            width: 60,
            child: _PdfUnderlineField(
              text: v('ioNo'),
              style: serifStyle,
            ),
          ),
        ],
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '   तपासणी अधिकाऱ्याचे नाव:  ',
            style: marathiLabelStyle.copyWith(fontSize: 9.5),
          ),
          const Spacer(flex: 3),
          Text(
            'पदनाम:       ',
            style: marathiLabelStyle.copyWith(fontSize: 9.5),
          ),
          const Spacer(flex: 2),
          Text(
            'पोलीस स्टेशन: ',
            style: marathiLabelStyle.copyWith(fontSize: 9.5),
          ),
          SizedBox(
            width: 130,
            child: _PdfUnderlineField(
              text: v('ioPs'),
              style: serifStyle,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),

      // 9. Complainant Name & Father's Name
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '9. (a) Name of Complainant/Informant : ',
            style: serifStyle.copyWith(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: _PdfUnderlineField(
              text: v('complainantName'),
              style: serifStyle,
            ),
          ),
        ],
      ),
      Text(
        '   तक्रारदाराचे/खबरीचे नांव :',
        style: marathiLabelStyle.copyWith(fontSize: 9.5),
      ),
      const SizedBox(height: 4),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '   (b) Father\'s/Husband\'s Name : ',
            style: serifStyle.copyWith(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: _PdfUnderlineField(
              text: v('complainantFather'),
              style: serifStyle,
            ),
          ),
        ],
      ),
      Text(
        '   पित्याचे / पतीचे नांव :',
        style: marathiLabelStyle.copyWith(fontSize: 9.5),
      ),
      const SizedBox(height: 12),

      // 10. Details of Properties recovered/seized Table
      Text(
        '10. Details of Properties/Articles/Documents recovered/seized during investigation and relied upon : Enclosed with C/S.( separate list can be attached, if necessary )',
        style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 10.5),
      ),
      Text(
        'तपासणीच्या वेळी परत मिळविलेल्या/जप्त केलेल्या आणि अवलंबून राहीलेल्या मालमत्तेचा/वस्तूंचा तपशील:\n(आवश्यक असेल तर स्वतंत्र यादी सोबत जोडण्यात येईल )',
        style: marathiLabelStyle.copyWith(fontSize: 9.5),
      ),
      const SizedBox(height: 6),
      Table(
        border: TableBorder.all(color: Colors.black87),
        columnWidths: const {
          0: FixedColumnWidth(44),
          1: FlexColumnWidth(2.6),
          2: FlexColumnWidth(1.4),
          3: FlexColumnWidth(1.6),
          4: FlexColumnWidth(2.2),
          5: FlexColumnWidth(1.4),
        },
        children: [
          TableRow(
            children: [
              _pdfTableHeader('Sr.No\nअ.क्र', serifStyle),
              _pdfTableHeader(
                  'Property Description\nमालमत्तेचे वर्णन', serifStyle),
              _pdfTableHeader(
                  'Estimated\nValue\n( in Rs.)\nअंदाजित मूल्य\n(रुपयात )',
                  serifStyle),
              _pdfTableHeader(
                  'P.S.\nProperty\nRegister No.\nपोलीस ठाणे\nमालमत्ता नोंदवही\nक्रमांक',
                  serifStyle),
              _pdfTableHeader(
                  'From whom/\nwhere Recovered\nor Seized\nकोणाकडून/कोठून परत\nमिळविली किंवा जप्त केली.',
                  serifStyle),
              _pdfTableHeader('Disposal\nविल्हेवाट', serifStyle),
            ],
          ),
          TableRow(
            children: [
              _pdfTableHeader('1', serifStyle),
              _pdfTableHeader('2', serifStyle),
              _pdfTableHeader('3', serifStyle),
              _pdfTableHeader('4', serifStyle),
              _pdfTableHeader('5', serifStyle),
              _pdfTableHeader('6', serifStyle),
            ],
          ),
          for (var i = 0; i < propCount; i++)
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    '${i + 1}.',
                    textAlign: TextAlign.center,
                    style: serifStyle.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _pdfTableCell(v('prop${i + 1}Desc'), serifStyle),
                _pdfTableCell(v('prop${i + 1}Value'), serifStyle,
                    align: TextAlign.right),
                _pdfTableCell(v('prop${i + 1}Reg'), serifStyle),
                _pdfTableCell(v('prop${i + 1}From'), serifStyle),
                _pdfTableCell(v('prop${i + 1}Disposal'), serifStyle),
              ],
            ),
        ],
      ),
    ],
  );
}

Widget _buildFrPg2Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';

  final serifStyle = _serifStyle(12.0);
  final marathiLabelStyle = _mBld(10.0);

  return _buildFrPageContainer(
    formLabel: 'Page : 2',
    formLabelStyle: serifStyle.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.bold,
    ),
    children: [
      Text(
        '11. i) Particulars of accused persons charge-sheeted ( use separate sheet for each accused ) : आरोपपत्र ठेवलेल्या आरोपीचा तपशिल ( प्रत्येक आरोपीसाठी स्वतंत्र कागद वापरावा ) :',
        style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 10.5),
      ),
      const SizedBox(height: 10),

      // (i) Name & Where verified
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('(i)  Name : ',
              style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            flex: 3,
            child: _PdfUnderlineField(
              text: v('accName'),
              style: serifStyle,
            ),
          ),
          const SizedBox(width: 16),
          Text('Where verified : ',
              style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            flex: 2,
            child: _PdfUnderlineField(
              text: v('accNameVerified'),
              style: serifStyle,
            ),
          ),
        ],
      ),
      Row(
        children: [
          Text('     नाव : )',
              style: marathiLabelStyle.copyWith(fontSize: 9.5)),
          const Spacer(flex: 3),
          Text('पडताळले किंवा काय',
              style: marathiLabelStyle.copyWith(fontSize: 9.5)),
          const Spacer(flex: 2),
        ],
      ),
      const SizedBox(height: 7),

      // (ii) Father's/Husband's Name
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('(ii) Father\'s/Husband\'s Name : ',
              style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: _PdfUnderlineField(
              text: v('accFather'),
              style: serifStyle,
            ),
          ),
        ],
      ),
      Text('     पित्याचे/पतीचे नाव',
          style: marathiLabelStyle.copyWith(fontSize: 9.5)),
      const SizedBox(height: 7),

      // (iii) Date/Year of Birth / Age
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('(iii) Date/Year of Birth ( जन्मतारीख ) : ',
              style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: _pdfDatePickerField(v('accDob')),
          ),
          const SizedBox(width: 12),
          Text('वय ',
              style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(
            width: 50,
            child: _PdfUnderlineField(
              text: v('accAge'),
              style: serifStyle,
            ),
          ),
          Text(' वर्ष',
              style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
      const SizedBox(height: 7),

      // (iv) Sex & (v) Nationality
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('(iv) Sex : ',
              style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: _PdfUnderlineField(
              text: v('accSex'),
              style: serifStyle,
            ),
          ),
          const SizedBox(width: 16),
          Text('(v) Nationality : ',
              style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: _PdfUnderlineField(
              text: v('accNationality'),
              style: serifStyle,
            ),
          ),
        ],
      ),
      Row(
        children: [
          Text('     लिंग', style: marathiLabelStyle.copyWith(fontSize: 9.5)),
          const Spacer(),
          Text('राष्ट्रीयत्व',
              style: marathiLabelStyle.copyWith(fontSize: 9.5)),
          const Spacer(),
        ],
      ),
      const SizedBox(height: 7),

      // (vi) Passport No / Date / Place
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('(vi) Passport No. : ',
              style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: _PdfUnderlineField(
              text: v('accPassport'),
              style: serifStyle,
            ),
          ),
          const SizedBox(width: 12),
          Text('Date of issue : ',
              style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: _pdfDatePickerField(v('accPassportDate')),
          ),
          const SizedBox(width: 12),
          Text('Place of Issue : ',
              style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: _PdfUnderlineField(
              text: v('accPassportPlace'),
              style: serifStyle,
            ),
          ),
        ],
      ),
      Row(
        children: [
          Text('     पारपत्र क्र.',
              style: marathiLabelStyle.copyWith(fontSize: 9.5)),
          const Spacer(),
          Text('दिल्याची तारीख',
              style: marathiLabelStyle.copyWith(fontSize: 9.5)),
          const Spacer(),
          Text('दिल्याचे ठिकाण',
              style: marathiLabelStyle.copyWith(fontSize: 9.5)),
          const Spacer(),
        ],
      ),
      const SizedBox(height: 7),

      // (vii) Religion & (viii) SC/ST
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('(vii) Religion : ',
              style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: _PdfUnderlineField(
              text: v('accReligion'),
              style: serifStyle,
            ),
          ),
          const SizedBox(width: 16),
          Text('(viii) Whether SC/ST : ',
              style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: _PdfUnderlineField(
              text: v('accScSt'),
              style: serifStyle,
            ),
          ),
        ],
      ),
      Row(
        children: [
          Text('     धर्म', style: marathiLabelStyle.copyWith(fontSize: 9.5)),
          const Spacer(),
          Text('अनुसूचित जातीचा/जमातीचा आहे का',
              style: marathiLabelStyle.copyWith(fontSize: 9.5)),
          const Spacer(),
        ],
      ),
      const SizedBox(height: 7),

      // (ix) Occupation
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('(ix) Occupation (व्यवसाय) : ',
              style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: _PdfUnderlineField(
              text: v('accOccupation'),
              style: serifStyle,
            ),
          ),
        ],
      ),
      const SizedBox(height: 7),

      // (x) Address & Whether verified
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('(x)  Address ( पत्ता ) : ',
              style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: _PdfUnderlineField(
              text: v('accAddress'),
              style: serifStyle,
            ),
          ),
        ],
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('     Whether verified (पडताळला किंवा काय) : ',
              style: marathiLabelStyle.copyWith(fontSize: 9.5)),
          SizedBox(
            width: 70,
            child: _PdfUnderlineField(
              text: v('accAddressVerified'),
              style: serifStyle,
            ),
          ),
        ],
      ),
      const SizedBox(height: 7),

      // (xi) Provisional Criminal No
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('(xi) Provisional Criminal No. (तात्पूरता गुन्हेगार क्र.) ',
              style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: _PdfUnderlineField(
              text: v('accProvCriminalNo'),
              style: serifStyle,
            ),
          ),
        ],
      ),
      const SizedBox(height: 7),

      // (xii) Regular Criminal No
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
              '(xii) Regular Criminal No. (if known) ( नियमित गुन्हेगार क्र.) (माहीत असल्यास) : ',
              style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: _PdfUnderlineField(
              text: v('accRegularCriminalNo'),
              style: serifStyle,
            ),
          ),
        ],
      ),
      const SizedBox(height: 7),

      // (xiii) Date of Arrest
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('(xiii) Date of Arrest (अटकेची तारीख.) : दिनांक ',
              style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: _pdfDatePickerField(v('accArrestDate')),
          ),
          Text(' चे ', style: marathiLabelStyle),
          SizedBox(
            width: 80,
            child: _pdfTimePickerField(v('accArrestTime')),
          ),
          Text(' वाजता', style: marathiLabelStyle),
        ],
      ),
      const SizedBox(height: 7),

      // (xiv) Date of release on bail
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('(xiv) Date of release on bail (जामीनावर सोडल्याची तारीख.) : ',
              style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: _pdfDatePickerField(v('accBailDate')),
          ),
        ],
      ),
      const SizedBox(height: 7),

      // (xv) Date on which forwarded to court
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
              '(xv) Date on which forwarded to court (न्यायालयात पाठविल्याची तारीख.): ',
              style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: _PdfUnderlineField(
              text: v('accForwardedCourt'),
              style: serifStyle,
            ),
          ),
        ],
      ),
      const SizedBox(height: 7),

      // (xvi) Under Acts & Section
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('(xvi) Under Acts & Section : ',
              style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: _PdfUnderlineField(
              text: v('accActsSections'),
              style: serifStyle,
            ),
          ),
        ],
      ),
      Text(
        '      ( कोणत्या अधिनियमाखाली व कलमाखाली ) :- भारतीय न्याय संहिता २०२३ कलम',
        style: marathiLabelStyle.copyWith(fontSize: 9.5),
      ),
      const SizedBox(height: 7),

      // (xvii) Name (s) of bailers/sureties and Address
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('(xvii) Name (s) of bailers/sureties and Address ( मे ) : ',
              style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: _PdfUnderlineField(
              text: v('accBailers'),
              style: serifStyle,
            ),
          ),
        ],
      ),
      Text('       जामीनदारांची नांवे व पत्ते :',
          style: marathiLabelStyle.copyWith(fontSize: 9.5)),
      const SizedBox(height: 7),

      // (xviii) Previous convictions
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
              '(xviii) Previous convictions with case reference (प्रकरणाच्या संदर्भासह पूर्वीची अपराधीही) : ',
              style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: _PdfUnderlineField(
              text: v('accPrevConvictions'),
              style: serifStyle,
            ),
          ),
        ],
      ),
      const SizedBox(height: 7),

      // (xix) Status of the accused
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('(xix) Status of the accused (आरोपीची स्थिती) : ',
              style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: _PdfUnderlineField(
              text: v('accStatus'),
              style: serifStyle,
            ),
          ),
        ],
      ),
      const SizedBox(height: 2),
      Text(
        'Forwarded/Bailed by Police/In Police Custody/Bailed by Court/In Judicial Custody/Absconding/Proclaimed Offender : पुढे पाठवले/पोलीसांनी जामीनावर सोडले/पोलीस कोठडीत/न्यायालयाने जामीन मंजूर केला/न्यायालयीन कोठडीत/फरारी/उद्घोषित अपराधी',
        style: serifStyle.copyWith(fontSize: 9.5),
      ),
      const SizedBox(height: 12),

      // 12. Accused not charge-sheeted
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '12. आरोप पत्र न ठेवलेल्या आरोपीचा तपशिल: ',
            style: marathiLabelStyle.copyWith(
                fontWeight: FontWeight.bold, fontSize: 10.5),
          ),
          Expanded(
            child: _PdfUnderlineField(
              text: v('notChargeSheeted'),
              style: serifStyle,
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _buildFrPg3Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final witnessCount =
      int.tryParse(doc['witnessRowCount']?.toString() ?? '') ?? 3;

  final serifStyle = _serifStyle(12.0);
  final marathiLabelStyle = _mBld(10.0);

  return _buildFrPageContainer(
    formLabel: 'Page : 3',
    formLabelStyle: serifStyle.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.bold,
    ),
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '13. पडताळलेल्या साक्षटारांचे विवरण: ',
            style: marathiLabelStyle.copyWith(
                fontWeight: FontWeight.bold, fontSize: 10.5),
          ),
          Expanded(
            child: _PdfUnderlineField(
              text: v('witnessDesc'),
              style: serifStyle,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Center(
        child: Text(
          'साक्षीदारांची यादी.',
          style: GoogleFonts.notoSansDevanagari(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(height: 6),

      Table(
        border: TableBorder.all(color: Colors.black87),
        columnWidths: const {
          0: FixedColumnWidth(40),
          1: FlexColumnWidth(2.4),
          2: FixedColumnWidth(55),
          3: FlexColumnWidth(1.4),
          4: FlexColumnWidth(2.6),
          5: FlexColumnWidth(2.4),
        },
        children: [
          TableRow(
            children: [
              _pdfTableHeader('अ.क्र', serifStyle),
              _pdfTableHeader('साक्षीदारांचे नांव', serifStyle),
              _pdfTableHeader('वय', serifStyle),
              _pdfTableHeader('व्यवसाय', serifStyle),
              _pdfTableHeader('राहण्याचा पत्ता', serifStyle),
              _pdfTableHeader('सादर करावयाच्या\nपुराव्याचा प्रकार', serifStyle),
            ],
          ),
          TableRow(
            children: [
              _pdfTableHeader('1', serifStyle),
              _pdfTableHeader('2', serifStyle),
              _pdfTableHeader('3', serifStyle),
              _pdfTableHeader('4', serifStyle),
              _pdfTableHeader('5', serifStyle),
              _pdfTableHeader('6', serifStyle),
            ],
          ),
          for (var i = 0; i < witnessCount; i++)
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    i < _marathiNumbers.length
                        ? _marathiNumbers[i]
                        : '${i + 1}.',
                    textAlign: TextAlign.center,
                    style: marathiLabelStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 10.5,
                    ),
                  ),
                ),
                _pdfTableCell(v('witness${i + 1}Name'), serifStyle),
                _pdfTableCell(v('witness${i + 1}Age'), serifStyle,
                    align: TextAlign.center),
                _pdfTableCell(v('witness${i + 1}Occupation'), serifStyle),
                _pdfTableCell(v('witness${i + 1}Address'), serifStyle),
                _pdfTableCell(v('witness${i + 1}Evidence'), serifStyle),
              ],
            ),
        ],
      ),
      const SizedBox(height: 16),

      // 14. If FIR is False
      Text(
        '14. If F. I. R. is False, indicate action taken or proposed to be taken u/s 182/211 I. P. C.',
        style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 10.5),
      ),
      Text(
        '(तकार खोटी असेल तर भादंवि १८२/२११ अन्वये केलेली किंवा करावयाची कार्यवाही नमुद करावी.)',
        style: marathiLabelStyle.copyWith(fontSize: 9.5),
      ),
      const SizedBox(height: 4),
      _PdfUnderlineField(
        text: v('falseFirAction'),
        style: serifStyle,
      ),
      const SizedBox(height: 12),

      // 15. Result of laboratory analysis
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '15. Result of laboratory analysis : ',
            style: serifStyle.copyWith(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: _PdfUnderlineField(
              text: v('labAnalysis'),
              style: serifStyle,
            ),
          ),
        ],
      ),
      Text(
        '     प्रयोगशाळा विश्लेषकाचा निष्कर्ष :',
        style: marathiLabelStyle.copyWith(fontSize: 9.5),
      ),
    ],
  );
}

Widget _buildFrPg4Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';

  final serifStyle = _serifStyle(12.0);
  final marathiLabelStyle = _mBld(10.0);

  return _buildFrPageContainer(
    formLabel: 'Form : 5 E',
    formLabelStyle: serifStyle.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.bold,
    ),
    children: [
      // 16. Brief Facts of the Case
      Text(
        '16. Brief Facts of the Case (Add separate sheet, if necessary.)',
        style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 11.5),
      ),
      Text(
        '     थोडक्यात माहिती ( आवश्यक असल्यास वेगळा कागद जोडावा. ) :',
        style: marathiLabelStyle.copyWith(fontSize: 10.0),
      ),
      const SizedBox(height: 6),
      Text(
        'महोदय,',
        style: marathiLabelStyle.copyWith(
            fontWeight: FontWeight.bold, fontSize: 11.5),
      ),
      const SizedBox(height: 6),
      Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 180),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black26),
          borderRadius: BorderRadius.circular(4),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(8),
        child: Text(
          v('briefFacts').trim().isEmpty ? ' ' : v('briefFacts').trim(),
          style: GoogleFonts.notoSansDevanagari(
            fontSize: 11.5,
            height: 1.5,
            color: Colors.black87,
          ).copyWith(
            fontFamilyFallback: kMarathiFallbackFonts,
          ),
        ),
      ),
      const SizedBox(height: 14),

      Text(
        'टिप :-',
        style: marathiLabelStyle.copyWith(
            fontWeight: FontWeight.bold, fontSize: 10.5),
      ),
      const SizedBox(height: 6),

      // 17. Refer Notice Served
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '17. Refer Notice Served : ',
            style: serifStyle.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(
            width: 90,
            child: _PdfUnderlineField(
              text: v('referNoticeServed'),
              style: serifStyle,
            ),
          ),
          const SizedBox(width: 24),
          Text(
            'Date : ',
            style: serifStyle.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(
            width: 120,
            child: _pdfDatePickerField(v('referNoticeDate')),
          ),
        ],
      ),
      Text(
        '     ( Acknowledgement to be placed )',
        style: serifStyle.copyWith(fontSize: 9.5),
      ),
      const SizedBox(height: 10),

      // 18. Dispatched on
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '18. Dispatched on : ',
            style: serifStyle.copyWith(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: _pdfDatePickerField(v('dispatchedOn')),
          ),
        ],
      ),
      const SizedBox(height: 24),

      // Footer: Two Officer Columns Side-by-Side
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Forwarded by Station House Officer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Forwarded by Station House\nOfficer/officer in-charge',
                  style: serifStyle.copyWith(
                      fontWeight: FontWeight.bold, fontSize: 10.5),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Name : ',
                        style:
                            serifStyle.copyWith(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: _PdfUnderlineField(
                        text: v('shoName'),
                        style: serifStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Rank : ',
                        style:
                            serifStyle.copyWith(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: _PdfUnderlineField(
                        text: v('shoRank'),
                        style: serifStyle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('No : ',
                        style:
                            serifStyle.copyWith(fontWeight: FontWeight.bold)),
                    SizedBox(
                      width: 45,
                      child: _PdfUnderlineField(
                        text: v('shoNo'),
                        style: serifStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _PdfUnderlineField(
                  text: v('shoPs'),
                  style: serifStyle,
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),

          // Right: Signature of Investigation Officer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Signature of the Investigation Officer\nsubmitting the Final Report/Charge\nSheet.',
                  style: serifStyle.copyWith(
                      fontWeight: FontWeight.bold, fontSize: 10.5),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Name : ',
                        style:
                            serifStyle.copyWith(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: _PdfUnderlineField(
                        text: v('submitIoName'),
                        style: serifStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Rank : ',
                        style:
                            serifStyle.copyWith(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: _PdfUnderlineField(
                        text: v('submitIoRank'),
                        style: serifStyle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('No. : ',
                        style:
                            serifStyle.copyWith(fontWeight: FontWeight.bold)),
                    SizedBox(
                      width: 45,
                      child: _PdfUnderlineField(
                        text: v('submitIoNo'),
                        style: serifStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _PdfUnderlineField(
                  text: v('submitIoPs'),
                  style: serifStyle,
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
    ],
  );
}
