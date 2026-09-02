import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> previewTransitRemandPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final bytes = await generateTransitRemandPdf(doc);
  if (!context.mounted) return;
  final fileName = 'Transit_Remand_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

Future<Uint8List> generateTransitRemandPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final loraRegular = await PdfGoogleFonts.loraRegular();
  final loraBold = await PdfGoogleFonts.loraBold();

  final bodyStyle = pw.TextStyle(font: loraRegular, fontSize: 11, lineSpacing: 3);
  final boldStyle = pw.TextStyle(font: loraBold, fontSize: 11, fontWeight: pw.FontWeight.bold);
  final titleStyle = pw.TextStyle(font: loraBold, fontSize: 12, fontWeight: pw.FontWeight.bold);

  String v(String key) => doc[key]?.toString().trim() ?? '';

  final outwardNo = v('outwardNo');
  final outwardYear = v('outwardYear').isNotEmpty ? v('outwardYear') : '2021';
  final psName = v('psName').isNotEmpty ? v('psName') : 'Wakad Police Station,';
  final psCity = v('psCity').isNotEmpty ? v('psCity') : 'Pimpri Chichwad.';
  final date = v('date').isNotEmpty ? v('date') : '${v('dateDay')} ${v('dateMonthYear')}'.trim();

  final courtLine1 = v('courtLine1');
  final courtLine2 = v('courtLine2');

  final officerName = v('officerName').isNotEmpty ? v('officerName') : 'Jitendra S. Girnar';
  final officerRank = v('officerRank').isNotEmpty ? v('officerRank') : 'Police Sub Inpector';
  final officerPs = v('officerPs').isNotEmpty ? v('officerPs') : 'Wakad Police Station, Pimpri Chichwad.';
  final subjectHours = v('subjectHours').isNotEmpty ? v('subjectHours') : '72';

  final bodyText = v('body').isNotEmpty
      ? v('body')
      : '    Regarding the above mentioned subject, most humbly request that a complaint has been registered at Wakad Police Station, Pimpri Chinchwad with FIR No. 912/2021 u/s 377,498(A), 347,504,34 of IPC by complainant Mrs. Sushama Chalamalasetti, Age 31 years, Profession house wife, residing at B901, Titanium Park, Park Street, Wakad Pune. The name of the accused being 1) Mahesh Babu Gunukula, Age 36 ears profession Service, residing at D No. 4, 153, Gudlavaleru, Gudlavaleru MDL 521356, Crishna District Andhra Pradesh and 2) Shiva Prasad Gunukula, Age 63 years (relation father in law). Against he complainant the accused conspired to get the property of complainant at Mumbai which is joint name with her mother and the property in USA. On decline to transfer the property in accused husbands name they harassed her confired her in a room further mentally and physically harassed her. The accused no. 1 also had unnatural sexual offence against the wish of the complainant. The same has been registered under the above mention complainant and I am Investigating the same.\n\n'
          '    During Investigation I had arrest accuse no. 1) Mahesh Babu Gunukula, Age 36 ears profession Service, residing at D No. 4, 153, Gudlavaleru, Gudlavaleru MDL 521356, Crishna District Andhra Pradesh in --------- Police station at --------am/pm on dt.   /11/2021 wide station diary no. ----/21.\n\n'
          '    To produce accused before Hon. JMFC., No.09, Shivajinagar, Pune I want transit remand of accused for 2 hrs. so please give me transit remand of accused.';

  final signOffName = v('signOffName');

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 48),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header block left-aligned
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Outward No.  $outwardNo /$outwardYear', style: boldStyle),
              pw.SizedBox(height: 2),
              pw.Text(psName, style: boldStyle),
              pw.SizedBox(height: 2),
              pw.Text(psCity, style: boldStyle),
              pw.SizedBox(height: 2),
              pw.Text('Date -  $date', style: boldStyle),
            ],
          ),
          pw.SizedBox(height: 20),

          // To
          pw.Text('To,', style: titleStyle),
          pw.SizedBox(height: 6),
          pw.Text('Hon.- ${courtLine1.isEmpty ? '----------------------------------------' : courtLine1}', style: boldStyle),
          if (courtLine2.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(courtLine2, style: boldStyle),
          ],
          pw.SizedBox(height: 18),

          // Report
          pw.Text('Report- $officerName, $officerRank', style: boldStyle),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 45),
            child: pw.Text(officerPs, style: boldStyle),
          ),
          pw.SizedBox(height: 18),

          // Sub
          pw.Text('Sub- To get Transit Remand for $subjectHours hrs.', style: boldStyle),
          pw.SizedBox(height: 16),

          // ---000---
          pw.Text('---000---', style: boldStyle),
          pw.SizedBox(height: 14),

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
              if (signOffName.isNotEmpty) pw.Text(signOffName, style: boldStyle),
            ],
          ),
        ],
      ),
    ),
  );

  return pdf.save();
}
