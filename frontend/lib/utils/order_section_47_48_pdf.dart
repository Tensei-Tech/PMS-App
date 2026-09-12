import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> previewOrderSection4748Pdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final bytes = await generateOrderSection4748Pdf(doc);
  if (!context.mounted) return;
  final fileName =
      'Order_Section_47_48_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

Future<Uint8List> generateOrderSection4748Pdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final devanagari = await PdfGoogleFonts.notoSansDevanagariRegular();
  final devanagariBold = await PdfGoogleFonts.notoSansDevanagariBold();

  final regular = pw.TextStyle(
    font: devanagari,
    fontSize: 9,
    lineSpacing: 1.4,
  );
  final bold = pw.TextStyle(
    font: devanagariBold,
    fontSize: 9,
    fontWeight: pw.FontWeight.bold,
  );
  final headerStyle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 13,
    fontWeight: pw.FontWeight.bold,
  );
  final subHeaderStyle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 11,
    fontWeight: pw.FontWeight.bold,
  );
  final sectionHeader = pw.TextStyle(
    font: devanagariBold,
    fontSize: 9.5,
    fontWeight: pw.FontWeight.bold,
  );

  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  final policeStation = v('policeStation', 'म्हाळुंगे एम.आय.डी.सी.');
  final crNo = v('crNo');
  final crYear = v('crYear', '२५');
  final bnsSection = v('bnsSection', v('section'));
  final arrestDate = v('arrestDate');
  final arrestTime = v('arrestTime');
  final ioName = v('ioName', v('shoName'));

  // Page 1 fields
  final p1To1 = v('p1To1', v('accusedName'));
  final p1To2 = v('p1To2');
  final p1To3 = v('p1To3');
  final p1Fact1 = v('p1Fact1', v('orderBody'));
  final p1Fact2 = v('p1Fact2');
  final p1Fact3 = v('p1Fact3');
  final p1Ground1 = v('p1Ground1');
  final p1Ground2 = v('p1Ground2');
  final p1Ground3 = v('p1Ground3');
  final p1Ground4 = v('p1Ground4');
  final p1Ground5 = v('p1Ground5');
  final p1Reason1 = v('p1Reason1');
  final p1Reason2 = v('p1Reason2');
  final p1Reason3 = v('p1Reason3');
  final p1Reason4 = v('p1Reason4');
  final p1Reason5 = v('p1Reason5');
  final p1RemandDate = v('p1RemandDate', arrestDate);
  final p1AccusedSig = v('p1AccusedSig');
  final p1IoSig = v('p1IoSig', ioName);

  // Page 2 fields
  final p2To1 = v('p2To1');
  final p2To2 = v('p2To2');
  final p2To3 = v('p2To3');
  final p2AccusedName = v('p2AccusedName', p1To1);
  final p2Fact1 = v('p2Fact1', p1Fact1);
  final p2Fact2 = v('p2Fact2', p1Fact2);
  final p2Fact3 = v('p2Fact3', p1Fact3);
  final p2Ground1 = v('p2Ground1', p1Ground1);
  final p2Ground2 = v('p2Ground2', p1Ground2);
  final p2Ground3 = v('p2Ground3', p1Ground3);
  final p2Ground4 = v('p2Ground4', p1Ground4);
  final p2Ground5 = v('p2Ground5', p1Ground5);
  final p2Reason1 = v('p2Reason1', p1Reason1);
  final p2Reason2 = v('p2Reason2', p1Reason2);
  final p2Reason3 = v('p2Reason3', p1Reason3);
  final p2Reason4 = v('p2Reason4', p1Reason4);
  final p2Reason5 = v('p2Reason5', p1Reason5);
  final p2RemandDate = v('p2RemandDate', p1RemandDate);
  final p2RelativeSig = v('p2RelativeSig');
  final p2IoSig = v('p2IoSig', ioName);

  final section = v('formSection').toLowerCase();
  final isP1Explicit = section.contains('47') || section.contains('main') || section.contains('1');
  final isP2Explicit = section.contains('48') || section.contains('2');
  final showP1 = section.isEmpty || section.contains('complete') || isP1Explicit || !isP2Explicit;
  final showP2 = section.isEmpty || section.contains('complete') || isP2Explicit || !isP1Explicit;

  const longLine = '-----------------------------------------------------------------------------------------------------------------';
  const mediumLine = '---------------------------------------------------------------------------';

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 1: नोटीस बी.एन.एस.एस.कलम ४७(१)
  // ══════════════════════════════════════════════════════════════════════════
  if (showP1) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Top Center Header
            pw.Center(child: pw.Text('नोटीस', style: headerStyle)),
            pw.SizedBox(height: 2),
            pw.Center(child: pw.Text('बी.एन.एस.एस.कलम ४७(१)', style: subHeaderStyle)),
            pw.SizedBox(height: 10),

            // Recipient block
            pw.Text('प्रति,', style: bold),
            pw.SizedBox(height: 1),
            pw.Text(p1To1.isNotEmpty ? p1To1 : mediumLine, style: p1To1.isNotEmpty ? bold : regular),
            pw.SizedBox(height: 1),
            pw.Text(p1To2.isNotEmpty ? p1To2 : mediumLine, style: p1To2.isNotEmpty ? bold : regular),
            pw.SizedBox(height: 1),
            pw.Text(p1To3.isNotEmpty ? p1To3 : mediumLine, style: p1To3.isNotEmpty ? bold : regular),
            pw.SizedBox(height: 8),

            // Subject
            pw.Text(
              'विषय :- गुन्ह्याचे तपास कामी अटक करण्याचा आधार व कारणांबाबत...',
              style: bold,
            ),
            pw.SizedBox(height: 8),

            // Notice Paragraph
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: regular,
                children: [
                  const pw.TextSpan(text: '        आपणास याद्वारे कळविण्यात येते की, '),
                  pw.TextSpan(
                    text: policeStation.isNotEmpty ? policeStation : 'म्हाळुंगे एम.आय.डी.सी.',
                    style: bold,
                  ),
                  const pw.TextSpan(text: ' पोलीस स्टेशन गुन्हा रजि.नंबर '),
                  pw.TextSpan(
                    text: crNo.isNotEmpty ? crNo : '......',
                    style: bold,
                  ),
                  pw.TextSpan(text: '/$crYear भा.न्या.सं.कलम '),
                  pw.TextSpan(
                    text: bnsSection.isNotEmpty
                        ? bnsSection
                        : '....................................................................................',
                    style: bold,
                  ),
                  const pw.TextSpan(text: ' या गुन्ह्यात तपास कामी दि. '),
                  pw.TextSpan(
                    text: arrestDate.isNotEmpty ? arrestDate : '   /   /२०  ',
                    style: bold,
                  ),
                  const pw.TextSpan(text: ' रोजी '),
                  pw.TextSpan(
                    text: arrestTime.isNotEmpty ? arrestTime : '..........',
                    style: bold,
                  ),
                  const pw.TextSpan(text: ' वा. खालील आधारावर व कारणांसाठी अटक करण्यात येत आहे.'),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            // अ) गुन्ह्याची थोडक्यात हकीगत :-
            pw.Text('अ) गुन्ह्याची थोडक्यात हकीगत :-', style: sectionHeader),
            pw.SizedBox(height: 2),
            pw.Text(p1Fact1.isNotEmpty ? p1Fact1 : longLine, style: p1Fact1.isNotEmpty ? bold : regular),
            pw.SizedBox(height: 2),
            pw.Text(p1Fact2.isNotEmpty ? p1Fact2 : longLine, style: p1Fact2.isNotEmpty ? bold : regular),
            pw.SizedBox(height: 2),
            pw.Text(p1Fact3.isNotEmpty ? p1Fact3 : longLine, style: p1Fact3.isNotEmpty ? bold : regular),
            pw.SizedBox(height: 8),

            // ब) अटक करण्यासंबंधाने आधार :-
            pw.Text('ब) अटक करण्यासंबंधाने आधार :-', style: sectionHeader),
            pw.SizedBox(height: 2),
            for (final item in [
              ('१)', p1Ground1),
              ('२)', p1Ground2),
              ('३)', p1Ground3),
              ('४)', p1Ground4),
              ('५)', p1Ground5),
            ]) ...[
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${item.$1} ', style: bold),
                    pw.Expanded(
                      child: pw.Text(
                        item.$2.isNotEmpty ? item.$2 : longLine,
                        style: item.$2.isNotEmpty ? bold : regular,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            pw.SizedBox(height: 8),

            // क) अटकेची कारणे :-
            pw.Text('क) अटकेची कारणे :-', style: sectionHeader),
            pw.SizedBox(height: 2),
            for (final item in [
              ('१)', p1Reason1),
              ('२)', p1Reason2),
              ('३)', p1Reason3),
              ('४)', p1Reason4),
              ('५)', p1Reason5),
            ]) ...[
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${item.$1} ', style: bold),
                    pw.Expanded(
                      child: pw.Text(
                        item.$2.isNotEmpty ? item.$2 : longLine,
                        style: item.$2.isNotEmpty ? bold : regular,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            pw.SizedBox(height: 8),

            // ड)
            pw.Text(
              'ड) सदर गुन्हा हा जामीनपात्र/अजामीनपात्र आहे. गुन्हा जामीनपात्र असल्याने आपण योग्य तो जामीन दिल्यास आपणास जामीनावर मुक्त करण्यात येईल.',
              style: regular,
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 6),

            // इ)
            pw.RichText(
              text: pw.TextSpan(
                style: regular,
                children: [
                  const pw.TextSpan(text: 'इ) आपणास दिनांक '),
                  pw.TextSpan(
                    text: p1RemandDate.isNotEmpty ? p1RemandDate : '   /   /२०  ',
                    style: bold,
                  ),
                  const pw.TextSpan(
                    text: ' रोजी मा.प्रथम वर्ग न्यायदंडाधिकारी यांचे समक्ष रिमांडसाठी हजर करण्यात येणार आहे.',
                  ),
                ],
              ),
            ),
            pw.Spacer(),

            // Footer
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(right: 24),
                child: pw.Text('कळावे,', style: bold),
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // Left: Accused signature
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (p1AccusedSig.isNotEmpty)
                      pw.Text(p1AccusedSig, style: bold)
                    else
                      pw.SizedBox(height: 12),
                    pw.Text('आरोपीची दिनांकीत सही', style: bold),
                  ],
                ),

                // Right: IO signature
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (p1IoSig.isNotEmpty)
                      pw.Text(p1IoSig, style: bold)
                    else
                      pw.SizedBox(height: 12),
                    pw.Text('तपासी अधिकारी/अंमलदार', style: bold),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 2: नोटीस बी.एन.एस.एस.कलम ४८
  // ══════════════════════════════════════════════════════════════════════════
  if (showP2) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Top Center Header
            pw.Center(child: pw.Text('नोटीस', style: headerStyle)),
            pw.SizedBox(height: 2),
            pw.Center(child: pw.Text('बी.एन.एस.एस.कलम ४८', style: subHeaderStyle)),
            pw.SizedBox(height: 10),

            // Recipient block
            pw.Text('प्रति,', style: bold),
            pw.SizedBox(height: 1),
            pw.Text(p2To1.isNotEmpty ? p2To1 : mediumLine, style: p2To1.isNotEmpty ? bold : regular),
            pw.SizedBox(height: 1),
            pw.Text(p2To2.isNotEmpty ? p2To2 : mediumLine, style: p2To2.isNotEmpty ? bold : regular),
            pw.SizedBox(height: 1),
            pw.Text(p2To3.isNotEmpty ? p2To3 : mediumLine, style: p2To3.isNotEmpty ? bold : regular),
            pw.SizedBox(height: 8),

            // Subject
            pw.Text(
              'विषय :- गुन्ह्याचे तपास कामी अटक केले संबंधी अवगत केले बाबत...',
              style: bold,
            ),
            pw.SizedBox(height: 8),

            // Notice Paragraph
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: regular,
                children: [
                  const pw.TextSpan(text: '        आपणास याद्वारे कळविण्यात येते की, '),
                  pw.TextSpan(
                    text: policeStation.isNotEmpty ? policeStation : 'म्हाळुंगे एम.आय.डी.सी.',
                    style: bold,
                  ),
                  const pw.TextSpan(text: ' पोलीस स्टेशन,गुन्हा रजि.नंबर '),
                  pw.TextSpan(
                    text: crNo.isNotEmpty ? crNo : '.....',
                    style: bold,
                  ),
                  pw.TextSpan(text: '/$crYear भा.न्या.सं.कलम '),
                  pw.TextSpan(
                    text: bnsSection.isNotEmpty
                        ? bnsSection
                        : '....................................................................................',
                    style: bold,
                  ),
                  const pw.TextSpan(text: ' या गुन्ह्यात आपले नातेवाईक / मित्र / आप्तेष्ठ नामे '),
                  pw.TextSpan(
                    text: p2AccusedName.isNotEmpty
                        ? p2AccusedName
                        : '........................................................................................',
                    style: bold,
                  ),
                  const pw.TextSpan(text: ' यांना दिनांक '),
                  pw.TextSpan(
                    text: arrestDate.isNotEmpty ? arrestDate : '   /   /२०  ',
                    style: bold,
                  ),
                  const pw.TextSpan(text: ' रोजी '),
                  pw.TextSpan(
                    text: arrestTime.isNotEmpty ? arrestTime : '.......',
                    style: bold,
                  ),
                  const pw.TextSpan(text: ' वा. अटक करण्यात आली आहे.'),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            // अ) गुन्ह्याची थोडक्यात हकीगत :-
            pw.Text('अ) गुन्ह्याची थोडक्यात हकीगत :-', style: sectionHeader),
            pw.SizedBox(height: 2),
            pw.Text(p2Fact1.isNotEmpty ? p2Fact1 : longLine, style: p2Fact1.isNotEmpty ? bold : regular),
            pw.SizedBox(height: 2),
            pw.Text(p2Fact2.isNotEmpty ? p2Fact2 : longLine, style: p2Fact2.isNotEmpty ? bold : regular),
            pw.SizedBox(height: 2),
            pw.Text(p2Fact3.isNotEmpty ? p2Fact3 : longLine, style: p2Fact3.isNotEmpty ? bold : regular),
            pw.SizedBox(height: 8),

            // ब) अटक करण्यासंबंधाने आधार :-
            pw.Text('ब) अटक करण्यासंबंधाने आधार :-', style: sectionHeader),
            pw.SizedBox(height: 2),
            for (final item in [
              ('१)', p2Ground1),
              ('२)', p2Ground2),
              ('३)', p2Ground3),
              ('४)', p2Ground4),
              ('५)', p2Ground5),
            ]) ...[
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${item.$1} ', style: bold),
                    pw.Expanded(
                      child: pw.Text(
                        item.$2.isNotEmpty ? item.$2 : longLine,
                        style: item.$2.isNotEmpty ? bold : regular,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            pw.SizedBox(height: 8),

            // क) अटकेची कारणे :-
            pw.Text('क) अटकेची कारणे :-', style: sectionHeader),
            pw.SizedBox(height: 2),
            for (final item in [
              ('१)', p2Reason1),
              ('२)', p2Reason2),
              ('३)', p2Reason3),
              ('४)', p2Reason4),
              ('५)', p2Reason5),
            ]) ...[
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${item.$1} ', style: bold),
                    pw.Expanded(
                      child: pw.Text(
                        item.$2.isNotEmpty ? item.$2 : longLine,
                        style: item.$2.isNotEmpty ? bold : regular,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            pw.SizedBox(height: 8),

            // ड)
            pw.Text(
              'ड) सदर गुन्हा हा जामीनपात्र/अजामीनपात्र आहे. गुन्हा जामीनपात्र असल्याने योग्य तो जामीन दिल्यास अटक व्यक्तीस जामीनावर मुक्त करण्यात येईल.',
              style: regular,
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 6),

            // इ)
            pw.RichText(
              text: pw.TextSpan(
                style: regular,
                children: [
                  const pw.TextSpan(text: 'इ) अटक व्यक्तीला दिनांक '),
                  pw.TextSpan(
                    text: p2RemandDate.isNotEmpty ? p2RemandDate : '   /   /२०  ',
                    style: bold,
                  ),
                  const pw.TextSpan(
                    text: ' रोजी मा.प्रथम वर्ग न्यायदंडाधिकारी यांचे समक्ष रिमांडसाठी हजर करण्यात येणार आहे.',
                  ),
                ],
              ),
            ),
            pw.Spacer(),

            // Footer
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(right: 24),
                child: pw.Text('कळावे,', style: bold),
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // Left: Relative signature
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (p2RelativeSig.isNotEmpty)
                      pw.Text(p2RelativeSig, style: bold)
                    else
                      pw.SizedBox(height: 12),
                    pw.Text('नातेवाईकाची दिनांकीत सही', style: bold),
                  ],
                ),

                // Right: IO signature
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (p2IoSig.isNotEmpty)
                      pw.Text(p2IoSig, style: bold)
                    else
                      pw.SizedBox(height: 12),
                    pw.Text('तपासी अधिकारी/अंमलदार', style: bold),
                  ],
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
