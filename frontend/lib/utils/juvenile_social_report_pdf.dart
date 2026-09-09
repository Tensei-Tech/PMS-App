import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart';
import 'marathi_text_renderer.dart';

Future<void> previewJuvenileSocialReportPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final bytes = await generateJuvenileSocialReportPdf(doc);
  if (!context.mounted) return;
  final fileName =
      'Juvenile_Social_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

Future<Uint8List> generateJuvenileSocialReportPdf(
    Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final loraRegular = await PdfGoogleFonts.loraRegular();
  final loraBold = await PdfGoogleFonts.loraBold();
  final cache = await _preRenderJuvenileMarathi(doc);

  final englishStyle = pw.TextStyle(
    font: loraRegular,
    fontSize: 8.5,
    color: PdfColors.black,
  );
  final englishBold = pw.TextStyle(
    font: loraBold,
    fontSize: 8.5,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.black,
  );
  final headerStyle = pw.TextStyle(
    font: loraBold,
    fontSize: 12,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.black,
  );
  final valueStyle = pw.TextStyle(
    font: loraRegular,
    fontSize: 8.5,
    color: PdfColors.blue900,
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

  // ══════════════════════════════════════════════════════════════════
  // PAGE 1 — Personal & Disability
  // ══════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: cache.has('main_title_mr')
                ? cache.img('main_title_mr')
                : pw.Text(
                    '—:: विधीसंघर्षग्रस्त बालक याचा सामाजीक पार्श्वभुमी अहवाल ::—',
                    style: headerStyle),
          ),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
            columnWidths: const {
              0: pw.FixedColumnWidth(30),
              1: pw.FlexColumnWidth(2.2),
              2: pw.FlexColumnWidth(3.8),
            },
            children: [
              pw.TableRow(
                children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text('अ.क्र.',
                          style: englishBold, textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text('विवरण',
                          style: englishBold, textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Text('माहिती',
                          style: englishBold, textAlign: pw.TextAlign.center)),
                ],
              ),
              _pdfTableRow(
                  '1.',
                  'पोलीस स्टेशन व जिल्हा',
                  val(
                      'val_psDist',
                      doc['psDist']?.toString() ??
                          doc['policeStation']?.toString()),
                  englishBold),
              _pdfTableRow(
                  '2.',
                  'अपराध क्रमांक',
                  val('val_crimeNo',
                      doc['crimeNo']?.toString() ?? doc['crNo']?.toString()),
                  englishBold),
              _pdfTableRow(
                  '3.',
                  'कलम व अधिनियम',
                  val(
                      'val_sectionAct',
                      doc['sectionAct']?.toString() ??
                          doc['section']?.toString()),
                  englishBold),
              _pdfTableRow(
                  '4.',
                  'गुन्हा घडला ता व वेळ',
                  val('val_crimeDateTime', doc['crimeDateTime']?.toString()),
                  englishBold),
              _pdfTableRow(
                  '5.',
                  'गुन्हा दाखल ता व वेळ',
                  val('val_firDateTime', doc['firDateTime']?.toString()),
                  englishBold),
              _pdfTableRow('6.', 'तपासी अधिकारी यांचे नांव',
                  val('val_ioName', doc['ioName']?.toString()), englishBold),
              _pdfTableRow(
                  '7.',
                  'बाल कल्याण पोलीस अधिकारी नांव',
                  val('val_cwpoName', doc['cwpoName']?.toString()),
                  englishBold),
              _pdfTableRow(
                  '',
                  'बालक',
                  val(
                      'val_childName',
                      doc['childName']?.toString() ??
                          doc['juvenileName']?.toString()),
                  englishBold),
              _pdfTableRow(
                  '',
                  'वडील',
                  val(
                      'val_fatherName',
                      doc['fatherName']?.toString() ??
                          doc['guardianName']?.toString()),
                  englishBold),
              _pdfTableRow(
                  '',
                  'जन्म तारीख',
                  val('val_dob',
                      doc['dob']?.toString() ?? doc['juvenileAge']?.toString()),
                  englishBold),
              _pdfTableRow(
                  '',
                  'पत्ता',
                  val(
                      'val_address',
                      doc['address']?.toString() ??
                          doc['juvenileAddress']?.toString()),
                  englishBold),
              _pdfTableRow(
                  '',
                  'धर्म',
                  val('val_religion', doc['religion']?.toString()),
                  englishBold),
              _pdfTableRow(
                  '',
                  'बालकास अपंगत्व आहे काय ?',
                  val('val_hasDisability',
                      doc['hasDisability']?.toString() ?? 'नाही'),
                  englishBold),
              _pdfTableRow(
                  '',
                  'कर्णबधीर',
                  val('val_deaf', doc['deaf']?.toString() ?? 'नाही'),
                  englishBold),
              _pdfTableRow(
                  '',
                  'मुक',
                  val('val_dumb', doc['dumb']?.toString() ?? 'नाही'),
                  englishBold),
              _pdfTableRow(
                  '',
                  'शारीरीक अपंगत्व',
                  val('val_physicalDisability',
                      doc['physicalDisability']?.toString() ?? 'नाही'),
                  englishBold),
              _pdfTableRow(
                  '',
                  'मानसीक अपंगत्व',
                  val('val_mentalDisability',
                      doc['mentalDisability']?.toString() ?? 'नाही'),
                  englishBold),
              _pdfTableRow(
                  '',
                  'इतर',
                  val('val_otherDisability',
                      doc['otherDisability']?.toString()),
                  englishBold),
            ],
          ),
        ],
      ),
    ),
  );

  // ══════════════════════════════════════════════════════════════════
  // PAGE 2 — Family & Habits
  // ══════════════════════════════════════════════════════════════════
  final famCount = int.tryParse(doc['familyRowCount']?.toString() ?? '') ?? 5;

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('८) कौटुंबीक माहिती :-', style: englishBold),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
            columnWidths: const {
              0: pw.FixedColumnWidth(24),
              1: pw.FlexColumnWidth(1.8),
              2: pw.FixedColumnWidth(28),
              3: pw.FixedColumnWidth(40),
              4: pw.FlexColumnWidth(1.2),
              5: pw.FlexColumnWidth(1.2),
              6: pw.FlexColumnWidth(1.1),
              7: pw.FlexColumnWidth(1.2),
              8: pw.FlexColumnWidth(1.4),
              9: pw.FlexColumnWidth(1.4),
            },
            children: [
              pw.TableRow(
                children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(2),
                      child: pw.Text('अ.क्र',
                          style: englishBold, textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(2),
                      child: pw.Text('नांव व नाते',
                          style: englishBold, textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(2),
                      child: pw.Text('वय',
                          style: englishBold, textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(2),
                      child: pw.Text('लिंग',
                          style: englishBold, textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(2),
                      child: pw.Text('शिक्षण',
                          style: englishBold, textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(2),
                      child: pw.Text('व्यवसाय',
                          style: englishBold, textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(2),
                      child: pw.Text('उत्पन्न',
                          style: englishBold, textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(2),
                      child: pw.Text('आरोग्य',
                          style: englishBold, textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(2),
                      child: pw.Text('मनसिक इतिहास',
                          style: englishBold, textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(2),
                      child: pw.Text('व्यसनाधिनता',
                          style: englishBold, textAlign: pw.TextAlign.center)),
                ],
              ),
              for (var i = 1; i <= famCount; i++)
                pw.TableRow(
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: pw.Text('$i',
                            style: englishBold,
                            textAlign: pw.TextAlign.center)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: val(
                            'val_fam${i}Name', doc['fam${i}Name']?.toString())),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: val(
                            'val_fam${i}Age', doc['fam${i}Age']?.toString())),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: val(
                            'val_fam${i}Sex', doc['fam${i}Sex']?.toString())),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: val(
                            'val_fam${i}Edu', doc['fam${i}Edu']?.toString())),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: val(
                            'val_fam${i}Occ', doc['fam${i}Occ']?.toString())),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: val('val_fam${i}Income',
                            doc['fam${i}Income']?.toString())),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: val('val_fam${i}Health',
                            doc['fam${i}Health']?.toString())),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: val('val_fam${i}MentalHist',
                            doc['fam${i}MentalHist']?.toString())),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(2),
                        child: val('val_fam${i}Addiction',
                            doc['fam${i}Addiction']?.toString())),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 10),
          field('९) शाळा सोडल्याचे कारण :- ', 'val_schoolDropReasonPage2',
              doc['schoolDropReasonPage2']?.toString()),
          field('१०) कुटुंब सदस्य यांचा गुन्ह्यामध्ये सहभाग आहे काय :- ',
              'val_familyInCrime', doc['familyInCrime']?.toString()),
          pw.SizedBox(height: 8),
          pw.Text('११) बालकाला असलेल्या सवई व्यसन :-', style: englishBold),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
            columnWidths: const {
              0: pw.FixedColumnWidth(26),
              1: pw.FlexColumnWidth(1),
              2: pw.FixedColumnWidth(26),
              3: pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(2),
                      child: pw.Text('अ.क्र.',
                          style: englishBold, textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(2),
                      child: pw.Text('अ (सवयी / व्यसने)', style: englishBold)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(2),
                      child: pw.Text('अ.क्र.',
                          style: englishBold, textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(2),
                      child: pw.Text('ब (छंद / आवडी)', style: englishBold)),
                ],
              ),
              _pdfDualRow(
                  '1.',
                  'धुम्रपान',
                  doc['habit_smoking'] == true,
                  '1.',
                  'टि.व्ही पाहणे',
                  doc['hobby_watching_tv'] == true,
                  englishStyle,
                  englishBold),
              _pdfDualRow(
                  '2.',
                  'दारू',
                  doc['habit_alcohol'] == true,
                  '2.',
                  'खेळ खेळणे',
                  doc['hobby_playing_games'] == true,
                  englishStyle,
                  englishBold),
              _pdfDualRow(
                  '3.',
                  'जुगार',
                  doc['habit_gambling'] == true,
                  '3.',
                  'पुस्तक वाचणे',
                  doc['hobby_reading_books'] == true,
                  englishStyle,
                  englishBold),
              _pdfDualRow(
                  '4.',
                  'भिक मागणे',
                  doc['habit_begging'] == true,
                  '4.',
                  'चित्र काढणे',
                  doc['hobby_drawing'] == true,
                  englishStyle,
                  englishBold),
              _pdfDualRow(
                  '5.',
                  'खराॅ/ पान मसाला',
                  doc['habit_tobacco_pan'] == true,
                  '5.',
                  'कला गायन',
                  doc['hobby_singing_art'] == true,
                  englishStyle,
                  englishBold),
              pw.TableRow(
                children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(2),
                      child: pw.Text('6.',
                          style: englishBold, textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(2),
                      child: val(
                          'val_habit_other', doc['habit_other']?.toString())),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(2),
                      child: pw.Text('6.',
                          style: englishBold, textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(2),
                      child: val(
                          'val_hobby_other', doc['hobby_other']?.toString())),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          field('१२) बालकाचे नोकरीचा तपशील :- ', 'val_childJobDetails',
              doc['childJobDetails']?.toString()),
        ],
      ),
    ),
  );

  // ══════════════════════════════════════════════════════════════════
  // PAGE 3 — Income usage, Education, Reasons
  // ══════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          field('१३) उत्पन्न वापराचा तपशिल :- ', 'val_incomeUsageDetails',
              doc['incomeUsageDetails']?.toString()),
          _pdfBulletRow(
              'कौटुंबीक गरजा भागविण्यासाठी :- ',
              doc['incomeUsageFamily']?.toString() ?? 'नाही',
              englishBold,
              valueStyle),
          _pdfBulletRow(
              'स्वतः साठी :- ',
              doc['incomeUsageSelf']?.toString() ?? 'नाही',
              englishBold,
              valueStyle),
          _pdfBulletRow(
              'कपडे खरेदी करीता :- ',
              doc['incomeUsageClothes']?.toString() ?? 'नाही',
              englishBold,
              valueStyle),
          _pdfBulletRow(
              'जुगार खेळण्यासाठी :- ',
              doc['incomeUsageGambling']?.toString() ?? 'नाही',
              englishBold,
              valueStyle),
          _pdfBulletRow(
              'व्यसन नशा करण्याकरीता :- ',
              doc['incomeUsageAddiction']?.toString() ?? 'नाही',
              englishBold,
              valueStyle),
          _pdfBulletRow(
              'साठविणेसाठी :- ',
              doc['incomeUsageSavings']?.toString() ?? 'नाही',
              englishBold,
              valueStyle),
          pw.SizedBox(height: 8),
          pw.Text('१४) बालकाची शैक्षणीक माहिती :-', style: englishBold),
          field('   निवड: ', 'val_educationLevel',
              doc['educationLevel']?.toString()),
          pw.SizedBox(height: 8),
          pw.Text('१५) शाळा सोडल्याचे कारण :-', style: englishBold),
          if (doc['schoolLeavingReasons'] is List)
            for (final r in (doc['schoolLeavingReasons'] as List))
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 10, bottom: 2),
                child: pw.Text('• $r', style: englishStyle),
              ),
          field('   इतर: ', 'val_schoolLeavingOther',
              doc['schoolLeavingOther']?.toString()),
          pw.SizedBox(height: 8),
          pw.Text('१६) बालक शिकलेल्या शाळेचा तपशिल :-', style: englishBold),
          field('   शाळेचा प्रकार: ', 'val_schoolType',
              doc['schoolType']?.toString()),
          pw.SizedBox(height: 8),
          field('१७) व्यावसायीक प्रशिक्षण :- ', 'val_vocationalTraining',
              doc['vocationalTraining']?.toString() ?? 'नाही'),
          pw.Spacer(),
          pw.Align(
              alignment: pw.Alignment.bottomRight,
              child: pw.Text('M.R.W', style: englishBold)),
        ],
      ),
    ),
  );

  // ══════════════════════════════════════════════════════════════════
  // PAGE 4 — Friends, Abuse, Circumstances
  // ══════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('१८) कोणत्या प्रकारचे मित्र जास्त आहेत :-',
              style: englishBold),
          if (doc['friendTypes'] is List)
            for (final f in (doc['friendTypes'] as List))
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 10, bottom: 2),
                child: pw.Text('• $f', style: englishStyle),
              ),
          _pdfBulletRow(
              'व्यसनी :- ',
              doc['friendsAddicted']?.toString() ?? 'नाही',
              englishBold,
              valueStyle),
          _pdfBulletRow(
              'गुन्हेगारी पार्श्वभुमी असणारे :- ',
              doc['friendsCriminal']?.toString() ?? 'नाही',
              englishBold,
              valueStyle),
          pw.SizedBox(height: 8),
          field('१९) बालकावर कोणत्या प्रकारचा छळ अत्याचार झाला आहे काय ? :- ',
              'val_childAbused', doc['childAbused']?.toString() ?? 'नाही'),
          pw.SizedBox(height: 4),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
            columnWidths: const {
              0: pw.FixedColumnWidth(26),
              1: pw.FlexColumnWidth(2.6),
              2: pw.FlexColumnWidth(3.4),
            },
            children: [
              pw.TableRow(
                children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(2),
                      child: pw.Text('अ.क्र.',
                          style: englishBold, textAlign: pw.TextAlign.center)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(2),
                      child: pw.Text('छळ अत्याचार प्रकार', style: englishBold)),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(2),
                      child: pw.Text('शेरा', style: englishBold)),
                ],
              ),
              _pdfTableRow(
                  '1.',
                  'शाब्दीक छळ- पालक/ भावंडे/ नियोक्ता/ इतर',
                  val('val_abuseVerbal', doc['abuseVerbal']?.toString()),
                  englishBold),
              _pdfTableRow(
                  '2.',
                  'शारीरीक छळ - नमुद करा',
                  val('val_abusePhysical', doc['abusePhysical']?.toString()),
                  englishBold),
              _pdfTableRow(
                  '3.',
                  'लैंगीक छळ - पालक/ भावंडे/ नियोक्ता/ इतर',
                  val('val_abuseSexual', doc['abuseSexual']?.toString()),
                  englishBold),
              _pdfTableRow(
                  '4.',
                  'इतर - नमुद करा',
                  val('val_abuseOther', doc['abuseOther']?.toString()),
                  englishBold),
            ],
          ),
          pw.SizedBox(height: 8),
          field('२०) बालक कोणत्या गुन्ह्यांचा बळी Victim आहे काय :- ',
              'val_childVictim', doc['childVictim']?.toString() ?? 'नाही'),
          field(
              '२१) प्रौढ/ प्रौढांचा गट नशेचे साहित्य वाहतुकीसाठी बालकाचा वापर करतात काय ? :- ',
              'val_childDrugCarrier',
              doc['childDrugCarrier']?.toString() ?? 'नाही'),
          field(
              '२२) बालकाचा आरोप असलेल्या गुन्ह्यामागे कारण (पालकाकडुन दुर्लक्ष, मित्र) :- ',
              'val_crimeReason',
              doc['crimeReason']?.toString()),
          field(
              '२३) कोणत्या परिस्थितीत / घटनेमध्ये बालकास पकडले आहे :- ',
              'val_arrestCircumstances',
              doc['arrestCircumstances']?.toString()),
          field('२४) बालकाकडुन मिळालेल्या मालमत्तेची माहिती :- ',
              'val_propertyFromChild', doc['propertyFromChild']?.toString()),
          pw.Spacer(),
          pw.Align(
              alignment: pw.Alignment.bottomRight,
              child: pw.Text('M.R.W', style: englishBold)),
        ],
      ),
    ),
  );

  // ══════════════════════════════════════════════════════════════════
  // PAGE 5 — Child role, CWPO instructions & Signatures
  // ══════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('२५) बालकावर आरोप असलेल्या गुन्ह्यामध्ये बालकाची भुमीका :-',
              style: englishBold),
          field('   ', 'val_childRoleInCrime',
              doc['childRoleInCrime']?.toString()),
          pw.SizedBox(height: 14),
          pw.Text('२६) बाल कल्याण पोलीस अधिकारी मार्फत बालका बाबत सुचना :-',
              style: englishBold),
          field('   ', 'val_cwpoInstructions',
              doc['cwpoInstructions']?.toString()),
          pw.SizedBox(height: 60),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 250,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Text('अन्वेषण अधिकारी सही', style: englishBold),
                  ),
                  pw.SizedBox(height: 12),
                  field('नांव :- ', 'val_signOfficerName',
                      doc['signOfficerName']?.toString()),
                  pw.Row(
                    children: [
                      pw.Expanded(
                          child: field('पद :- ', 'val_signOfficerRank',
                              doc['signOfficerRank']?.toString())),
                      pw.SizedBox(width: 4),
                      pw.SizedBox(
                          width: 60,
                          child: field('-ब.नं. ', 'val_signOfficerBadge',
                              doc['signOfficerBadge']?.toString())),
                    ],
                  ),
                  field('नेमणुक :- ', 'val_signOfficerPosting',
                      doc['signOfficerPosting']?.toString()),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  return pdf.save();
}

pw.TableRow _pdfTableRow(
    String num, String label, pw.Widget valueWidget, pw.TextStyle boldStyle) {
  return pw.TableRow(
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.all(3),
        child: pw.Text(num, style: boldStyle, textAlign: pw.TextAlign.center),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(3),
        child: pw.Text(label, style: boldStyle),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(3),
        child: valueWidget,
      ),
    ],
  );
}

pw.TableRow _pdfDualRow(
  String num1,
  String label1,
  bool checked1,
  String num2,
  String label2,
  bool checked2,
  pw.TextStyle regular,
  pw.TextStyle bold,
) {
  return pw.TableRow(
    children: [
      pw.Padding(
          padding: const pw.EdgeInsets.all(2),
          child: pw.Text(num1, style: bold, textAlign: pw.TextAlign.center)),
      pw.Padding(
        padding: const pw.EdgeInsets.all(2),
        child: pw.Row(
          children: [
            pw.Text(checked1 ? '[x] ' : '[ ] ', style: bold),
            pw.Text(label1, style: regular),
          ],
        ),
      ),
      pw.Padding(
          padding: const pw.EdgeInsets.all(2),
          child: pw.Text(num2, style: bold, textAlign: pw.TextAlign.center)),
      pw.Padding(
        padding: const pw.EdgeInsets.all(2),
        child: pw.Row(
          children: [
            pw.Text(checked2 ? '[x] ' : '[ ] ', style: bold),
            pw.Text(label2, style: regular),
          ],
        ),
      ),
    ],
  );
}

pw.Widget _pdfBulletRow(
    String label, String val, pw.TextStyle bold, pw.TextStyle valStyle) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(left: 10, bottom: 2),
    child: pw.Row(
      children: [
        pw.Text('➤ $label', style: bold),
        pw.Text(val, style: valStyle),
      ],
    ),
  );
}

Future<MarathiImageCache> _preRenderJuvenileMarathi(
    Map<String, dynamic> doc) async {
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
  await cache.add(
      'main_title_mr',
      '—:: विधीसंघर्षग्रस्त बालक याचा सामाजीक पार्श्वभुमी अहवाल ::—',
      labelStyle);

  Future<void> addVal(String key, String? v) async {
    final t = v?.trim() ?? '';
    if (containsDevanagari(t)) {
      await cache.add(key, t, valueStyle, maxWidth: 480);
    }
  }

  final keys = [
    'psDist',
    'crimeNo',
    'sectionAct',
    'crimeDateTime',
    'firDateTime',
    'ioName',
    'cwpoName',
    'childName',
    'fatherName',
    'dob',
    'address',
    'religion',
    'hasDisability',
    'deaf',
    'dumb',
    'physicalDisability',
    'mentalDisability',
    'otherDisability',
    'schoolDropReasonPage2',
    'familyInCrime',
    'habit_other',
    'hobby_other',
    'childJobDetails',
    'incomeUsageDetails',
    'educationLevel',
    'schoolLeavingOther',
    'schoolType',
    'vocationalTraining',
    'abuseVerbal',
    'abusePhysical',
    'abuseSexual',
    'abuseOther',
    'crimeReason',
    'arrestCircumstances',
    'propertyFromChild',
    'childRoleInCrime',
    'cwpoInstructions',
    'signOfficerName',
    'signOfficerRank',
    'signOfficerBadge',
    'signOfficerPosting',
  ];
  for (final k in keys) {
    await addVal('val_$k', doc[k]?.toString());
  }

  for (var i = 1; i <= 10; i++) {
    for (final col in [
      'Name',
      'Age',
      'Sex',
      'Edu',
      'Occ',
      'Income',
      'Health',
      'MentalHist',
      'Addiction'
    ]) {
      await addVal('val_fam$i$col', doc['fam$i$col']?.toString());
    }
  }

  return cache;
}
