import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart';
import 'marathi_text_renderer.dart';
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
  final loraRegular = await PdfGoogleFonts.loraRegular();
  final loraBold = await PdfGoogleFonts.loraBold();
  final cache = await _preRenderAllMarathi(doc);

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
    if (containsDevanagari(t) && cache.has(key)) return cache.img(key);
    return pw.Text(t, style: valueStyle);
  }

  pw.Widget field(String label, String key, String? fallback,
      {double width = 0}) {
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
          pw.Text(label, style: englishBold),
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
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('1.Dist : ', style: englishBold),
                pw.SizedBox(
                  width: 70,
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                    child: val('val_dist', doc['dist']?.toString()),
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Text('P.S: ', style: englishBold),
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                    child: val('val_ps', doc['ps']?.toString()),
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Text('Year : 20', style: englishBold),
                pw.SizedBox(
                  width: 25,
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                    child: val('val_year', doc['year']?.toString()),
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Text('FIRNo : ', style: englishBold),
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                    child: val('val_firNo', doc['firNo']?.toString()),
                  ),
                ),
                pw.Text('/', style: englishBold),
                pw.SizedBox(
                  width: 35,
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                    child: val(
                        'val_firYearSuffix', doc['firYearSuffix']?.toString()),
                  ),
                ),
                pw.SizedBox(width: 6),
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

Future<MarathiImageCache> _preRenderAllMarathi(Map<String, dynamic> doc) async {
  final cache = MarathiImageCache();
  final labelStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 9,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );
  final valueStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 9,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );
  await GoogleFonts.pendingFonts();
  await cache.add('title_mr', 'अंतिम अहवाल नमुना', labelStyle);
  await cache.add('label_court_mr',
      'मा.वि.न्यायदंडाधिकारी प्रथम श्रेणी,न्यायालय ', labelStyle);
  await cache.add('label_dist_mr', 'जिल्हा ', labelStyle);
  await cache.add('witness_header_mr', 'साक्षीदारांची यादी.', labelStyle);

  Future<void> addVal(String key, String? v) async {
    final t = v?.trim() ?? '';
    if (containsDevanagari(t)) {
      await cache.add(key, t, valueStyle, maxWidth: 480);
    }
  }

  final keys = [
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
  for (final k in keys) {
    await addVal('val_$k', doc[k]?.toString());
  }
  for (var i = 1; i <= 10; i++) {
    for (final col in ['Desc', 'Value', 'Reg', 'From', 'Disposal']) {
      await addVal('val_prop$i$col', doc['prop$i$col']?.toString());
    }
  }
  for (var i = 1; i <= 20; i++) {
    for (final col in ['Name', 'Age', 'Occupation', 'Address', 'Evidence']) {
      await addVal('val_witness$i$col', doc['witness$i$col']?.toString());
    }
  }
  for (final entry in [
    ('reportType', doc['reportType']?.toString() ?? ''),
    ('frUnoccurred', doc['frUnoccurred']?.toString() ?? ''),
    ('notChargeSheeted', doc['notChargeSheeted']?.toString() ?? ''),
    ('falseFirAction', doc['falseFirAction']?.toString() ?? ''),
    ('briefFacts', doc['briefFacts']?.toString() ?? ''),
  ]) {
    final lines = _splitLines(entry.$2, 90);
    for (var i = 0; i < lines.length; i++) {
      if (containsDevanagari(lines[i])) {
        await cache.add('${entry.$1}_$i', lines[i], valueStyle, maxWidth: 480);
      }
    }
  }
  return cache;
}

Widget _frUnderline(String text, {double? width}) {
  final content = text.trim();
  return Container(
    width: width,
    padding: const EdgeInsets.only(bottom: 1, left: 2, right: 2),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(width: 0.6, color: Colors.black)),
    ),
    child: Text(
      content.isEmpty ? ' ' : content,
      style: FormImagePdfHelper.valStyle(8),
    ),
  );
}

Widget _frField(String label, String val, {double width = 0}) {
  final content = val.trim();
  final valChild = Container(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(width: 0.6, color: Colors.black)),
    ),
    padding: const EdgeInsets.only(left: 3, bottom: 1),
    child: Text(
      content.isEmpty ? ' ' : content,
      style: FormImagePdfHelper.valStyle(8),
    ),
  );

  return Padding(
    padding: const EdgeInsets.only(bottom: 2.5),
    child: Row(
      mainAxisSize: width > 0 ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: FormImagePdfHelper.mBld(8, 1.2)),
        if (width > 0)
          SizedBox(width: width, child: valChild)
        else
          Expanded(child: valChild),
      ],
    ),
  );
}

Widget _frMultiline(String label, String text, {int lines = 4}) {
  final content = text.trim();
  final split = _splitLines(content, 90);
  final count = split.length > lines ? split.length : lines;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (label.isNotEmpty) Text(label, style: FormImagePdfHelper.mBld(8, 1.2)),
      if (label.isNotEmpty) const SizedBox(height: 2),
      for (var i = 0; i < count; i++)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.only(left: 4, bottom: 1),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(width: 0.6, color: Colors.black)),
          ),
          child: Text(
            i < split.length ? split[i] : ' ',
            style: FormImagePdfHelper.valStyle(8),
          ),
        ),
    ],
  );
}

Widget _buildFrPg1Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final propCount =
      int.tryParse(doc['propertyRowCount']?.toString() ?? '') ?? 2;
  final bld = FormImagePdfHelper.mBld(8, 1.25);

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
    children: [
      Center(
          child: Text('FINAL REPORT FORM', style: FormImagePdfHelper.mBld(12))),
      Center(
          child:
              Text('अंतिम अहवाल नमुना', style: FormImagePdfHelper.mBld(9.5))),
      Center(child: Text('( UNDER SECTION 193 B.N.S.S.2023 )', style: bld)),
      const SizedBox(height: 6),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('IN THE COURT OF : ', style: bld),
          Text('न्यायालय : ', style: bld),
          Expanded(child: _frUnderline(v('court'))),
          const SizedBox(width: 6),
          Text('Dist / जिल्हा : ', style: bld),
          SizedBox(width: 80, child: _frUnderline(v('courtDist'))),
        ],
      ),
      const SizedBox(height: 4),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('1.Dist : ', style: bld),
          SizedBox(width: 70, child: _frUnderline(v('dist'))),
          const SizedBox(width: 6),
          Text('P.S: ', style: bld),
          Expanded(flex: 2, child: _frUnderline(v('ps'))),
          const SizedBox(width: 6),
          Text('Year: ', style: bld),
          SizedBox(width: 45, child: _frUnderline(v('year'))),
          const SizedBox(width: 6),
          Text('FIR No : ', style: bld),
          SizedBox(width: 50, child: _frUnderline(v('firNo'))),
          Text(' /20', style: bld),
          SizedBox(width: 25, child: _frUnderline(v('firYearSuffix'))),
          const SizedBox(width: 6),
          Text('Date : ', style: bld),
          SizedBox(width: 65, child: _frUnderline(v('headerDate'))),
        ],
      ),
      const SizedBox(height: 4),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('2.Final Report/Charge Sheet No. : ', style: bld),
          SizedBox(width: 50, child: _frUnderline(v('reportNo'))),
          Text(' /20', style: bld),
          SizedBox(width: 25, child: _frUnderline(v('reportYearSuffix'))),
          const SizedBox(width: 8),
          Text('Date : ', style: bld),
          SizedBox(width: 70, child: _frUnderline(v('reportDate'))),
        ],
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          Expanded(flex: 2, child: _frField('3. (a) Act : ', v('act'))),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: _frField('(b) Section : ', v('section'))),
        ],
      ),
      _frField(
          '4. Type of Final Report ( अंतिम अहवालाचा प्रकार ) : ',
          v('reportType') +
              (v('reportTypeCustom').isNotEmpty
                  ? ' - ${v('reportTypeCustom')}'
                  : '')),
      _frMultiline(
          '5. If Final Report unoccurred / false / mistake of fact or law / undetected (जर अंतिम अहवाल अदखलपात्र, खोटा, वस्तुस्थितीची किंवा कायद्याची चूक / निष्पन्न न झालेला असेल तर ) :',
          v('frUnoccurred'),
          lines: 2),
      Row(
        children: [
          Expanded(
              flex: 3,
              child: _frField('6. If Charge sheeted ( आरोपपत्र ठेवल्यास ) : ',
                  v('chargeSheeted'))),
          const SizedBox(width: 8),
          Expanded(
              flex: 2,
              child: _frField(
                  'Original / Supplementary : ', v('originalSupplementary'))),
        ],
      ),
      Row(
        children: [
          Expanded(
              flex: 3, child: _frField('7. Name of the I.O. : ', v('ioName'))),
          const SizedBox(width: 8),
          SizedBox(width: 110, child: _frField('Rank : ', v('ioRank'))),
          const SizedBox(width: 8),
          SizedBox(width: 65, child: _frField('No. : ', v('ioNo'))),
        ],
      ),
      _frField('   Police Station / पोलीस स्टेशन: ', v('ioPs')),
      const SizedBox(height: 3),
      _frField('9. (a) Name of Complainant/Informant : ', v('complainantName')),
      _frField('   (b) Father\'s/Husband\'s Name : ', v('complainantFather')),
      const SizedBox(height: 4),
      Text(
        '10. Details of Properties/Articles/Documents recovered/seized during investigation and relied upon : Enclosed with C/S.( separate list can be attached, if necessary )',
        style: bld,
      ),
      const SizedBox(height: 3),
      Table(
        border: TableBorder.all(color: Colors.black, width: 0.5),
        columnWidths: const {
          0: FixedColumnWidth(28),
          1: FlexColumnWidth(2.6),
          2: FlexColumnWidth(1.4),
          3: FlexColumnWidth(1.6),
          4: FlexColumnWidth(2.2),
          5: FlexColumnWidth(1.4),
        },
        children: [
          TableRow(
            children: [
              Padding(
                  padding: const EdgeInsets.all(2),
                  child: Text('Sr.\nअ.क्र',
                      style: bld, textAlign: TextAlign.center)),
              Padding(
                  padding: const EdgeInsets.all(2),
                  child: Text('Property Description\nमालाचे वर्णन',
                      style: bld, textAlign: TextAlign.center)),
              Padding(
                  padding: const EdgeInsets.all(2),
                  child: Text('Estimated Value\nअंदाजे किंमत',
                      style: bld, textAlign: TextAlign.center)),
              Padding(
                  padding: const EdgeInsets.all(2),
                  child: Text('Ps Property Register No\nमुददेमाल नोंद वही क्र',
                      style: bld, textAlign: TextAlign.center)),
              Padding(
                  padding: const EdgeInsets.all(2),
                  child: Text('From Whom Recovered\nकोणाकडून हस्तगत',
                      style: bld, textAlign: TextAlign.center)),
              Padding(
                  padding: const EdgeInsets.all(2),
                  child: Text('Disposal\nविल्हेवाट',
                      style: bld, textAlign: TextAlign.center)),
            ],
          ),
          for (var i = 1; i <= propCount; i++)
            TableRow(
              children: [
                Padding(
                    padding: const EdgeInsets.all(2),
                    child:
                        Text('$i.', style: bld, textAlign: TextAlign.center)),
                Padding(
                    padding: const EdgeInsets.all(2),
                    child: Text(v('prop${i}Desc'),
                        style: FormImagePdfHelper.valStyle(7.5))),
                Padding(
                    padding: const EdgeInsets.all(2),
                    child: Text(v('prop${i}Value'),
                        style: FormImagePdfHelper.valStyle(7.5))),
                Padding(
                    padding: const EdgeInsets.all(2),
                    child: Text(v('prop${i}Reg'),
                        style: FormImagePdfHelper.valStyle(7.5))),
                Padding(
                    padding: const EdgeInsets.all(2),
                    child: Text(v('prop${i}From'),
                        style: FormImagePdfHelper.valStyle(7.5))),
                Padding(
                    padding: const EdgeInsets.all(2),
                    child: Text(v('prop${i}Disposal'),
                        style: FormImagePdfHelper.valStyle(7.5))),
              ],
            ),
        ],
      ),
      const Spacer(),
      Align(
          alignment: Alignment.bottomRight,
          child: Text('Page 1', style: FormImagePdfHelper.mReg(7.5))),
    ],
  );
}

Widget _buildFrPg2Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final bld = FormImagePdfHelper.mBld(8, 1.2);

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
    children: [
      Align(alignment: Alignment.topRight, child: Text('Page : 2', style: bld)),
      const SizedBox(height: 3),
      Text(
        '11. i) Particulars of accused persons charge-sheeted ( use separate sheet for each accused ) : आरोपपत्र ठेवलेल्या आरोपीचा तपशिल ( प्रत्येक आरोपीसाठी स्वतंत्र कागद वापरावा ) :',
        style: bld,
      ),
      const SizedBox(height: 4),
      Row(
        children: [
          Expanded(flex: 3, child: _frField('(i) Name : ', v('accName'))),
          const SizedBox(width: 10),
          Expanded(
              flex: 2,
              child: _frField('Where verified : ', v('accNameVerified'))),
        ],
      ),
      _frField('(ii) Father\'s/Husband\'s Name : ', v('accFather')),
      Row(
        children: [
          Expanded(
              flex: 3,
              child: _frField(
                  '(iii) Date/Year of Birth ( जन्मतारीख ) : ', v('accDob'))),
          const SizedBox(width: 10),
          SizedBox(width: 80, child: _frField('Age : ', v('accAge'))),
          const SizedBox(width: 10),
          SizedBox(width: 90, child: _frField('(iv) Sex : ', v('accSex'))),
        ],
      ),
      _frField('(v) Nationality ( राष्ट्रीयत्व ) : ', v('accNationality')),
      Row(
        children: [
          Expanded(
              flex: 3,
              child: _frField('(vi) Passport No. : ', v('accPassport'))),
          const SizedBox(width: 8),
          Expanded(
              flex: 2,
              child: _frField('Date of issue : ', v('accPassportDate'))),
          const SizedBox(width: 8),
          Expanded(
              flex: 2,
              child: _frField('Place of issue : ', v('accPassportPlace'))),
        ],
      ),
      Row(
        children: [
          Expanded(
              flex: 2,
              child: _frField('(vii) Religion ( धर्म ) : ', v('accReligion'))),
          const SizedBox(width: 10),
          Expanded(
              flex: 3, child: _frField('Whether SC/ST/OBC : ', v('accScSt'))),
        ],
      ),
      _frField('(viii) Occupation ( धंदा ) : ', v('accOccupation')),
      Row(
        children: [
          Expanded(
              flex: 4,
              child: _frField('(ix) Address ( पत्ता ) : ', v('accAddress'))),
          const SizedBox(width: 10),
          Expanded(
              flex: 2,
              child: _frField('Whether verified : ', v('accAddressVerified'))),
        ],
      ),
      Row(
        children: [
          Expanded(
              child: _frField(
                  '(x) Provisional Criminal No. : ', v('accProvCriminalNo'))),
          const SizedBox(width: 10),
          Expanded(
              child: _frField(
                  'Regular Criminal No. : ', v('accRegularCriminalNo'))),
        ],
      ),
      Row(
        children: [
          Expanded(
              flex: 2,
              child: _frField('(xi) Date of Arrest : ', v('accArrestDate'))),
          const SizedBox(width: 8),
          SizedBox(width: 90, child: _frField('Time : ', v('accArrestTime'))),
          const SizedBox(width: 8),
          Expanded(
              flex: 2,
              child:
                  _frField('(xii) Date on which bailed : ', v('accBailDate'))),
        ],
      ),
      _frField(
          '(xiii) Date on which forwarded to Court : ', v('accForwardedCourt')),
      _frField('(xiv) Under Acts & Sections : ', v('accActsSections')),
      _frMultiline(
          '(xv) Name & Address of Bailers / Sureties ( जामीनदारांचे नांव व पत्ता ) :',
          v('accBailers'),
          lines: 2),
      _frMultiline('(xvi) Previous convictions with case references : ',
          v('accPrevConvictions'),
          lines: 2),
      _frField('(xvii) Status of the accused ( आरोपीची सद्यस्थिती ) : ',
          v('accStatus')),
      const SizedBox(height: 6),
      Text(
        '12. Particulars of accused persons not charge-sheeted ( Suspect ) ( Use separate sheet for each person ) आरोपपत्र न ठेवलेल्या आरोपीचा तपशिल ( संशयित ) ( प्रत्येक व्यक्तीसाठी स्वतंत्र कागद वापरावा ) :',
        style: bld,
      ),
      const SizedBox(height: 2),
      _frMultiline('', v('notChargeSheeted'), lines: 4),
      const Spacer(),
      Align(
          alignment: Alignment.bottomRight,
          child: Text('Page 2', style: FormImagePdfHelper.mReg(7.5))),
    ],
  );
}

Widget _buildFrPg3Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final witnessCount =
      int.tryParse(doc['witnessRowCount']?.toString() ?? '') ?? 3;
  final bld = FormImagePdfHelper.mBld(8, 1.2);

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
    children: [
      Align(alignment: Alignment.topRight, child: Text('Page : 3', style: bld)),
      const SizedBox(height: 3),
      Text(
        '13. Particulars of witnesses to be examined ( तपासावयाच्या साक्षीदारांचा तपशील ) :',
        style: bld,
      ),
      const SizedBox(height: 4),
      Table(
        border: TableBorder.all(color: Colors.black, width: 0.5),
        columnWidths: const {
          0: FixedColumnWidth(26),
          1: FlexColumnWidth(2.8),
          2: FlexColumnWidth(1.0),
          3: FlexColumnWidth(1.4),
          4: FlexColumnWidth(2.6),
          5: FlexColumnWidth(2.2),
        },
        children: [
          TableRow(
            children: [
              Padding(
                  padding: const EdgeInsets.all(2),
                  child:
                      Text('अ.क्र', style: bld, textAlign: TextAlign.center)),
              Padding(
                  padding: const EdgeInsets.all(2),
                  child: Text('साक्षीदारांचे नांव',
                      style: bld, textAlign: TextAlign.center)),
              Padding(
                  padding: const EdgeInsets.all(2),
                  child: Text('वय', style: bld, textAlign: TextAlign.center)),
              Padding(
                  padding: const EdgeInsets.all(2),
                  child:
                      Text('व्यवसाय', style: bld, textAlign: TextAlign.center)),
              Padding(
                  padding: const EdgeInsets.all(2),
                  child: Text('राहण्याचा पत्ता',
                      style: bld, textAlign: TextAlign.center)),
              Padding(
                  padding: const EdgeInsets.all(2),
                  child: Text('सादर करावयाच्या\nपुराव्याचा प्रकार',
                      style: bld, textAlign: TextAlign.center)),
            ],
          ),
          TableRow(
            children: [
              Padding(
                  padding: const EdgeInsets.all(1),
                  child: Text('1', style: bld, textAlign: TextAlign.center)),
              Padding(
                  padding: const EdgeInsets.all(1),
                  child: Text('2', style: bld, textAlign: TextAlign.center)),
              Padding(
                  padding: const EdgeInsets.all(1),
                  child: Text('3', style: bld, textAlign: TextAlign.center)),
              Padding(
                  padding: const EdgeInsets.all(1),
                  child: Text('4', style: bld, textAlign: TextAlign.center)),
              Padding(
                  padding: const EdgeInsets.all(1),
                  child: Text('5', style: bld, textAlign: TextAlign.center)),
              Padding(
                  padding: const EdgeInsets.all(1),
                  child: Text('6', style: bld, textAlign: TextAlign.center)),
            ],
          ),
          for (var i = 1; i <= witnessCount; i++)
            TableRow(
              children: [
                Padding(
                    padding: const EdgeInsets.all(2),
                    child:
                        Text('$i.', style: bld, textAlign: TextAlign.center)),
                Padding(
                    padding: const EdgeInsets.all(2),
                    child: Text(v('witness${i}Name'),
                        style: FormImagePdfHelper.valStyle(7.5))),
                Padding(
                    padding: const EdgeInsets.all(2),
                    child: Text(v('witness${i}Age'),
                        style: FormImagePdfHelper.valStyle(7.5))),
                Padding(
                    padding: const EdgeInsets.all(2),
                    child: Text(v('witness${i}Occupation'),
                        style: FormImagePdfHelper.valStyle(7.5))),
                Padding(
                    padding: const EdgeInsets.all(2),
                    child: Text(v('witness${i}Address'),
                        style: FormImagePdfHelper.valStyle(7.5))),
                Padding(
                    padding: const EdgeInsets.all(2),
                    child: Text(v('witness${i}Evidence'),
                        style: FormImagePdfHelper.valStyle(7.5))),
              ],
            ),
        ],
      ),
      const SizedBox(height: 10),
      Text(
        '14. If F.I.R. is false and in case of malicious prosecution, action taken or proposed to be taken under section 182 / 211 I.P.C. should be mentioned :',
        style: bld,
      ),
      Text(
        '(तकार खोटी असेल तर भादंवि १८२/२११ अन्वये केलेली किंवा करावयाची कार्यवाही नमुद करावी.)',
        style: FormImagePdfHelper.mReg(7.5),
      ),
      _frField('   ', v('falseFirAction')),
      const SizedBox(height: 8),
      _frField(
          '15. Result of laboratory analysis (प्रयोगशाळा विश्लेषकाचा निष्कर्ष) : ',
          v('labAnalysis')),
      const Spacer(),
      Align(
          alignment: Alignment.bottomRight,
          child: Text('Page 3', style: FormImagePdfHelper.mReg(7.5))),
    ],
  );
}

Widget _buildFrPg4Widget(Map<String, dynamic> doc) {
  String v(String k) => doc[k]?.toString().trim() ?? '';
  final bld = FormImagePdfHelper.mBld(8, 1.25);
  final mrR = FormImagePdfHelper.mReg(8, 1.25);

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
    children: [
      Align(
          alignment: Alignment.topRight, child: Text('Form : 5 E', style: bld)),
      const SizedBox(height: 4),
      Text('16. Brief Facts of the Case (Add separate sheet, if necessary.)',
          style: bld),
      Text('    थोडक्यात माहिती ( आवश्यक असल्यास वेगळा कागद जोडावा. ) :',
          style: mrR),
      const SizedBox(height: 2),
      Text('महोदय,', style: bld),
      const SizedBox(height: 2),
      _frMultiline('', v('briefFacts'), lines: 14),
      const SizedBox(height: 8),
      Text('टिप :-', style: bld),
      Row(
        children: [
          Expanded(
              child: _frField(
                  '17. Refer Notice Served: ', v('referNoticeServed'))),
          const SizedBox(width: 8),
          Expanded(child: _frField('Date: ', v('referNoticeDate'))),
          const SizedBox(width: 8),
          Expanded(child: _frField('Dispatched on: ', v('dispatchedOn'))),
        ],
      ),
      const SizedBox(height: 14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Signature of the Officer Incharge,', style: bld),
                Text('Police Station / पो.स्टे. प्रभारी अधिकाऱ्याची सही',
                    style: mrR),
                const SizedBox(height: 4),
                _frField('Name : ', v('shoName')),
                Row(
                  children: [
                    Expanded(child: _frField('Rank : ', v('shoRank'))),
                    const SizedBox(width: 4),
                    Expanded(child: _frField('No. : ', v('shoNo'))),
                  ],
                ),
                _frField('Police Station : ', v('shoPs')),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Signature of Investigating Officer,', style: bld),
                Text('तपासी अंमलदाराची सही', style: mrR),
                const SizedBox(height: 4),
                _frField(
                    'Name : ',
                    v('submitIoName').isNotEmpty
                        ? v('submitIoName')
                        : v('ioName')),
                Row(
                  children: [
                    Expanded(
                        child: _frField(
                            'Rank : ',
                            v('submitIoRank').isNotEmpty
                                ? v('submitIoRank')
                                : v('ioRank'))),
                    const SizedBox(width: 4),
                    Expanded(
                        child: _frField(
                            'No. : ',
                            v('submitIoNo').isNotEmpty
                                ? v('submitIoNo')
                                : v('ioNo'))),
                  ],
                ),
                _frField('Police Station : ',
                    v('submitIoPs').isNotEmpty ? v('submitIoPs') : v('ioPs')),
              ],
            ),
          ),
        ],
      ),
      const Spacer(),
      Align(
          alignment: Alignment.bottomRight,
          child: Text('Page 4', style: FormImagePdfHelper.mReg(7.5))),
    ],
  );
}
