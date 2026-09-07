import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart';
import 'marathi_text_renderer.dart';
import '../widgets/form_section_utils.dart';

Future<void> previewFinalReportPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final bytes = await generateFinalReportPdf(doc);
  if (!context.mounted) return;
  final fileName =
      'Final_Report_Form_${DateTime.now().millisecondsSinceEpoch}.pdf';
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
    color: PdfColors.blue900,
  );

  pw.Widget val(String key, String? text) {
    final t = text?.trim() ?? '';
    if (t.isEmpty) return pw.SizedBox();
    if (containsDevanagari(t) && cache.has(key)) return cache.img(key);
    return pw.Text(t, style: valueStyle);
  }

  pw.Widget field(String label, String key, String? fallback, {double width = 0}) {
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
    final propCount = int.tryParse(doc['propertyRowCount']?.toString() ?? '') ?? 2;

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
              child: pw.Text('( UNDER SECTION 193 B.N.S.S.2023 )', style: englishBold),
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
                    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                    child: val('val_dist', doc['dist']?.toString()),
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Text('P.S: ', style: englishBold),
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                    child: val('val_ps', doc['ps']?.toString()),
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Text('Year : 20', style: englishBold),
                pw.SizedBox(
                  width: 25,
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                    child: val('val_year', doc['year']?.toString()),
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Text('FIRNo : ', style: englishBold),
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                    child: val('val_firNo', doc['firNo']?.toString()),
                  ),
                ),
                pw.Text('/', style: englishBold),
                pw.SizedBox(
                  width: 35,
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                    child: val('val_firYearSuffix', doc['firYearSuffix']?.toString()),
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Text('Date : ', style: englishBold),
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
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
                      pw.Text('2. Final Report/Charge Sheet No. ', style: englishBold),
                      pw.Expanded(
                        child: pw.Container(
                          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                          child: val('val_reportNo', doc['reportNo']?.toString()),
                        ),
                      ),
                      pw.Text('/20', style: englishBold),
                      pw.SizedBox(
                        width: 25,
                        child: pw.Container(
                          decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.5))),
                          child: val('val_reportYearSuffix', doc['reportYearSuffix']?.toString()),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  flex: 2,
                  child: field('3.Date: ', 'val_reportDate', doc['reportDate']?.toString()),
                ),
              ],
            ),
            pw.SizedBox(height: 5),

            pw.Row(
              children: [
                pw.Expanded(flex: 3, child: field('4. Act : ', 'val_act', doc['act']?.toString())),
                pw.SizedBox(width: 12),
                pw.Expanded(flex: 2, child: field('Section: ', 'val_section', doc['section']?.toString())),
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
                  child: field('7. If Charge Sheeted : ( जर आरोपपत्र ठेवले ) ', 'val_chargeSheeted', doc['chargeSheeted']?.toString()),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: field('Original Supplementary ( मुळ/पुरवणी ) : ', 'val_origSupp', doc['originalSupplementary']?.toString()),
                ),
              ],
            ),
            pw.SizedBox(height: 4),

            pw.Row(
              children: [
                pw.Expanded(flex: 3, child: field('8. Name of the I.O : ', 'val_ioName', doc['ioName']?.toString())),
                pw.SizedBox(width: 8),
                pw.Expanded(flex: 2, child: field('Rank : ', 'val_ioRank', doc['ioRank']?.toString())),
                pw.SizedBox(width: 8),
                pw.SizedBox(width: 65, child: field('No. : ', 'val_ioNo', doc['ioNo']?.toString())),
              ],
            ),
            field('   Police Station / पोलीस स्टेशन: ', 'val_ioPs', doc['ioPs']?.toString()),
            pw.SizedBox(height: 4),

            field('9. (a) Name of Complainant/Informant : ', 'val_complainantName', doc['complainantName']?.toString()),
            field('   (b) Father\'s/Husband\'s Name : ', 'val_complainantFather', doc['complainantFather']?.toString()),
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
                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Sr.No\nअ.क्र', style: englishBold, textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Property Description\nमालमत्तेचे वर्णन', style: englishBold, textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Estimated Value\n(in Rs.)', style: englishBold, textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('P.S. Property\nRegister No.', style: englishBold, textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('From whom/where\nRecovered or Seized', style: englishBold, textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Disposal\nविल्हेवाट', style: englishBold, textAlign: pw.TextAlign.center)),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('1', style: englishBold, textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('2', style: englishBold, textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('3', style: englishBold, textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('4', style: englishBold, textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('5', style: englishBold, textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('6', style: englishBold, textAlign: pw.TextAlign.center)),
                  ],
                ),
                for (var i = 1; i <= propCount; i++)
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('$i.', style: englishBold, textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: val('val_prop${i}Desc', doc['prop${i}Desc']?.toString())),
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: val('val_prop${i}Value', doc['prop${i}Value']?.toString())),
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: val('val_prop${i}Reg', doc['prop${i}Reg']?.toString())),
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: val('val_prop${i}From', doc['prop${i}From']?.toString())),
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: val('val_prop${i}Disposal', doc['prop${i}Disposal']?.toString())),
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
            pw.Align(alignment: pw.Alignment.topRight, child: pw.Text('Page : 2', style: englishBold)),
            pw.SizedBox(height: 4),
            pw.Text(
              '11. i) Particulars of accused persons charge-sheeted ( use separate sheet for each accused ) : आरोपपत्र ठेवलेल्या आरोपीचा तपशिल ( प्रत्येक आरोपीसाठी स्वतंत्र कागद वापरावा ) :',
              style: englishBold,
            ),
            pw.SizedBox(height: 6),
            pw.Row(
              children: [
                pw.Expanded(flex: 3, child: field('(i) Name : ', 'val_accName', doc['accName']?.toString())),
                pw.SizedBox(width: 10),
                pw.Expanded(flex: 2, child: field('Where verified : ', 'val_accNameVerified', doc['accNameVerified']?.toString())),
              ],
            ),
            field('(ii) Father\'s/Husband\'s Name : ', 'val_accFather', doc['accFather']?.toString()),
            pw.Row(
              children: [
                pw.Expanded(flex: 3, child: field('(iii) Date/Year of Birth ( जन्मतारीख ) : ', 'val_accDob', doc['accDob']?.toString())),
                pw.SizedBox(width: 10),
                pw.SizedBox(width: 80, child: field('Age / वय : ', 'val_accAge', doc['accAge']?.toString())),
              ],
            ),
            pw.Row(
              children: [
                pw.Expanded(child: field('(iv) Sex / लिंग : ', 'val_accSex', doc['accSex']?.toString())),
                pw.SizedBox(width: 10),
                pw.Expanded(child: field('(v) Nationality / राष्ट्रीयत्व : ', 'val_accNationality', doc['accNationality']?.toString())),
              ],
            ),
            pw.Row(
              children: [
                pw.Expanded(child: field('(vi) Passport No. : ', 'val_accPassport', doc['accPassport']?.toString())),
                pw.SizedBox(width: 8),
                pw.Expanded(child: field('Date of issue : ', 'val_accPassportDate', doc['accPassportDate']?.toString())),
                pw.SizedBox(width: 8),
                pw.Expanded(child: field('Place of Issue : ', 'val_accPassportPlace', doc['accPassportPlace']?.toString())),
              ],
            ),
            pw.Row(
              children: [
                pw.Expanded(child: field('(vii) Religion / धर्म : ', 'val_accReligion', doc['accReligion']?.toString())),
                pw.SizedBox(width: 10),
                pw.Expanded(child: field('(viii) Whether SC/ST : ', 'val_accScSt', doc['accScSt']?.toString())),
              ],
            ),
            field('(ix) Occupation (व्यवसाय) : ', 'val_accOccupation', doc['accOccupation']?.toString()),
            field('(x) Address ( पत्ता ) : ', 'val_accAddress', doc['accAddress']?.toString()),
            field('    Whether verified (पडताळला किंवा काय) : ', 'val_accAddressVerified', doc['accAddressVerified']?.toString()),
            field('(xi) Provisional Criminal No. (तात्पूरता गुन्हेगार क्र.) : ', 'val_accProvCriminalNo', doc['accProvCriminalNo']?.toString()),
            field('(xii) Regular Criminal No. ( नियमित गुन्हेगार क्र.) : ', 'val_accRegularCriminalNo', doc['accRegularCriminalNo']?.toString()),
            pw.Row(
              children: [
                pw.Expanded(child: field('(xiii) Date of Arrest (अटकेची तारीख.) : दिनांक ', 'val_accArrestDate', doc['accArrestDate']?.toString())),
                pw.SizedBox(width: 8),
                pw.SizedBox(width: 110, child: field('वाजता : ', 'val_accArrestTime', doc['accArrestTime']?.toString())),
              ],
            ),
            field('(xiv) Date of release on bail (जामीनावर सोडल्याची तारीख.) : ', 'val_accBailDate', doc['accBailDate']?.toString()),
            field('(xv) Date on which forwarded to court (न्यायालयात पाठविल्याची तारीख.): ', 'val_accForwardedCourt', doc['accForwardedCourt']?.toString()),
            field('(xvi) Under Acts & Section ( कोणत्या अधिनियमाखाली व कलमाखाली ) : ', 'val_accActsSections', doc['accActsSections']?.toString()),
            field('(xvii) Name (s) of bailers/sureties and Address ( जामीनदारांची नांवे व पत्ते ) : ', 'val_accBailers', doc['accBailers']?.toString()),
            field('(xviii) Previous convictions with case reference : ', 'val_accPrevConvictions', doc['accPrevConvictions']?.toString()),
            field('(xix) Status of the accused (आरोपीची स्थिती) : ', 'val_accStatus', doc['accStatus']?.toString()),
            pw.Text(
              'Forwarded/Bailed by Police/In Police Custody/Bailed by Court/In Judicial Custody/Absconding/Proclaimed Offender',
              style: englishStyle,
            ),
            pw.SizedBox(height: 8),
            field('12. आरोप पत्र न ठेवलेल्या आरोपीचा तपशिल: ', 'val_notChargeSheeted', doc['notChargeSheeted']?.toString()),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // PAGE 3 — Sections 13 to 15
  // ══════════════════════════════════════════════════════════════════
  if (showsSection('Final Report Part III')) {
    final witnessCount = int.tryParse(doc['witnessRowCount']?.toString() ?? '') ?? 7;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Align(alignment: pw.Alignment.topRight, child: pw.Text('Page : 3', style: englishBold)),
            pw.SizedBox(height: 4),
            field('13. पडताळलेल्या साक्षटारांचे विवरण: ', 'val_witnessDesc', doc['witnessDesc']?.toString()),
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
                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('अ.क्र', style: englishBold, textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('साक्षीदारांचे नांव', style: englishBold, textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('वय', style: englishBold, textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('व्यवसाय', style: englishBold, textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('राहण्याचा पत्ता', style: englishBold, textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('सादर करावयाच्या\nपुराव्याचा प्रकार', style: englishBold, textAlign: pw.TextAlign.center)),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('1', style: englishBold, textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('2', style: englishBold, textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('3', style: englishBold, textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('4', style: englishBold, textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('5', style: englishBold, textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.all(2), child: pw.Text('6', style: englishBold, textAlign: pw.TextAlign.center)),
                  ],
                ),
                for (var i = 1; i <= witnessCount; i++)
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('$i.', style: englishBold, textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: val('val_witness${i}Name', doc['witness${i}Name']?.toString())),
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: val('val_witness${i}Age', doc['witness${i}Age']?.toString())),
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: val('val_witness${i}Occupation', doc['witness${i}Occupation']?.toString())),
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: val('val_witness${i}Address', doc['witness${i}Address']?.toString())),
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: val('val_witness${i}Evidence', doc['witness${i}Evidence']?.toString())),
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
            field('   ', 'val_falseFirAction', doc['falseFirAction']?.toString()),
            pw.SizedBox(height: 8),
            field('15. Result of laboratory analysis (प्रयोगशाळा विश्लेषकाचा निष्कर्ष) : ', 'val_labAnalysis', doc['labAnalysis']?.toString()),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // PAGE 4 — Sections 16 to 18 & Signatures (Form : 5 E)
  // ══════════════════════════════════════════════════════════════════
  if (showsSection('Final Report Part IV') || showsSection('Final Report Part III')) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Align(alignment: pw.Alignment.topRight, child: pw.Text('Form : 5 E', style: englishBold)),
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
            multiline('', 'briefFacts', doc['briefFacts']?.toString(), lines: 14),
            pw.SizedBox(height: 8),
            pw.Text('टिप :-', style: englishBold),
            pw.Row(
              children: [
                pw.Expanded(child: field('17. Refer Notice Served : ', 'val_referNoticeServed', doc['referNoticeServed']?.toString())),
                pw.SizedBox(width: 12),
                pw.SizedBox(width: 140, child: field('Date : ', 'val_referNoticeDate', doc['referNoticeDate']?.toString())),
              ],
            ),
            pw.Text('    ( Acknowledgement to be placed )', style: englishStyle),
            pw.SizedBox(height: 6),
            field('18. Dispatched on : ', 'val_dispatchedOn', doc['dispatchedOn']?.toString()),
            pw.SizedBox(height: 20),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Forwarded by Station House\nOfficer/officer in-charge', style: englishBold),
                      pw.SizedBox(height: 8),
                      field('Name : ', 'val_shoName', doc['shoName']?.toString()),
                      pw.Row(
                        children: [
                          pw.Expanded(child: field('Rank : ', 'val_shoRank', doc['shoRank']?.toString())),
                          pw.SizedBox(width: 6),
                          pw.SizedBox(width: 50, child: field('No : ', 'val_shoNo', doc['shoNo']?.toString())),
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
                      field('Name : ', 'val_submitIoName', doc['submitIoName']?.toString()),
                      pw.Row(
                        children: [
                          pw.Expanded(child: field('Rank : ', 'val_submitIoRank', doc['submitIoRank']?.toString())),
                          pw.SizedBox(width: 6),
                          pw.SizedBox(width: 50, child: field('No. : ', 'val_submitIoNo', doc['submitIoNo']?.toString())),
                        ],
                      ),
                      field('', 'val_submitIoPs', doc['submitIoPs']?.toString()),
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
    color: Colors.blue.shade900,
  );
  await GoogleFonts.pendingFonts();
  await cache.add('title_mr', 'अंतिम अहवाल नमुना', labelStyle);
  await cache.add('label_court_mr', 'मा.वि.न्यायदंडाधिकारी प्रथम श्रेणी,न्यायालय ', labelStyle);
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
