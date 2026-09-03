import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final regularStyle = pw.TextStyle(
    font: devanagari,
    fontSize: 9.5,
    lineSpacing: 1.5,
  );
  final boldStyle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 10,
    fontWeight: pw.FontWeight.bold,
  );
  final titleStyle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 12.5,
    fontWeight: pw.FontWeight.bold,
  );
  final headerMainStyle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 10.5,
    fontWeight: pw.FontWeight.bold,
  );

  String v(String key) => doc[key]?.toString().trim() ?? '';

  pw.Widget underlineField(String text, {double? width, double minWidth = 40}) {
    return pw.Container(
      width: width,
      constraints: pw.BoxConstraints(minWidth: minWidth),
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
        ),
      ),
      child: pw.Text(
        text.isEmpty ? ' ' : text,
        style: pw.TextStyle(
          font: devanagariBold,
          fontSize: 9.5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget multilineLines(String text, {int lines = 4}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
        ),
      ),
      child: pw.Text(
        text.isEmpty ? ' ' : text,
        style: pw.TextStyle(font: devanagari, fontSize: 9.5),
      ),
    );
  }

  // Load Logos
  pw.MemoryImage? leftImage;
  final leftB64 = v('leftLogoBase64');
  if (leftB64.isNotEmpty) {
    try {
      leftImage = pw.MemoryImage(base64Decode(leftB64));
    } catch (_) {}
  }
  if (leftImage == null) {
    try {
      final bytes = await rootBundle.load('assets/images/police_logo.png');
      leftImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}
  }

  pw.MemoryImage? rightImage;
  final rightB64 = v('rightLogoBase64');
  if (rightB64.isNotEmpty) {
    try {
      rightImage = pw.MemoryImage(base64Decode(rightB64));
    } catch (_) {}
  }
  if (rightImage == null) {
    try {
      final bytes =
          await rootBundle.load('assets/images/maharashtra_police_logo.png');
      rightImage = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}
  }

  pw.Widget buildPdfHeader() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1.2),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 90,
                height: 80,
                padding: const pw.EdgeInsets.all(4),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    right: pw.BorderSide(color: PdfColors.black, width: 1.0),
                  ),
                ),
                child: leftImage != null
                    ? pw.Image(leftImage, fit: pw.BoxFit.contain)
                    : pw.Container(),
              ),
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        v('headerStation').isEmpty
                            ? 'म्हाळुंगे M.I.D.C. पोलीस स्टेशन'
                            : v('headerStation'),
                        style: headerMainStyle,
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        v('headerCommissionerate').isEmpty
                            ? 'पिंपरी चिंचवड पोलीस आयुक्तालय'
                            : v('headerCommissionerate'),
                        style: boldStyle,
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        v('headerAddress1').isEmpty
                            ? 'पत्ता- एम.आय.डी.सी.चौक,चाकण-तळेगाव दाभाडे रोड,'
                            : v('headerAddress1'),
                        style: regularStyle,
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        v('headerAddress2').isEmpty
                            ? 'म्हाळुंगे (इंगळे), ता-खेड, जि-पुणे ४१०५०१'
                            : v('headerAddress2'),
                        style: regularStyle,
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        v('headerEmail').isEmpty
                            ? 'मेल आय.डी. pimahalunge.pcpc-mh@gov.in'
                            : v('headerEmail'),
                        style: boldStyle,
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        v('headerPhone').isEmpty
                            ? 'संपर्क क्रमांक - ७०२८५३५३२३'
                            : v('headerPhone'),
                        style: boldStyle,
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              pw.Container(
                width: 90,
                height: 80,
                padding: const pw.EdgeInsets.all(4),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    left: pw.BorderSide(color: PdfColors.black, width: 1.0),
                  ),
                ),
                child: rightImage != null
                    ? pw.Image(rightImage, fit: pw.BoxFit.contain)
                    : pw.Container(),
              ),
            ],
          ),
          pw.Container(
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.black, width: 1.0),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    child: pw.Row(
                      children: [
                        pw.Text('जावक क्रमांक - ', style: boldStyle),
                        pw.Expanded(child: underlineField(v('outwardNo'))),
                        pw.Text(' / ', style: boldStyle),
                      ],
                    ),
                  ),
                ),
                pw.Container(width: 1.0, height: 20, color: PdfColors.black),
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text('दि. ', style: boldStyle),
                        underlineField(v('noticeDateDay'), width: 25),
                        pw.Text(' / ', style: boldStyle),
                        underlineField(v('noticeDateMonth'), width: 25),
                        pw.Text(' / ', style: boldStyle),
                        underlineField(v('noticeDateYear'), width: 35),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  final section = v('formSection').toLowerCase();
  final show47 = section.isEmpty ||
      section.contains('47') ||
      section.contains('main') ||
      section.contains('page 1') ||
      section.contains('1');
  final show48 = section.isEmpty ||
      section.contains('48') ||
      section.contains('continuation') ||
      section.contains('page 2') ||
      section.contains('2');

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 1: बी.एन.एस.एस.कलम ४७(१)
  // ══════════════════════════════════════════════════════════════════════════
  if (show47) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 30),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            buildPdfHeader(),
            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('नोटीस', style: titleStyle),
                  pw.Text('बी.एन.एस.एस.कलम ४७(१)', style: boldStyle),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('प्रति,', style: boldStyle),
            underlineField(v('n47To'), width: double.infinity),
            pw.SizedBox(height: 10),
            pw.Text(
              'विषय :- गुन्ह्याचे तपास कामी अटक करण्याचा आधार व कारणांबाबत...',
              style: boldStyle,
            ),
            pw.SizedBox(height: 10),
            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              spacing: 2,
              runSpacing: 3,
              children: [
                pw.Text('आपणास याद्वारे कळविण्यात येते की, ',
                    style: regularStyle),
                underlineField(
                    v('n47Ps').isEmpty
                        ? 'म्हाळुंगे एम.आय.डी.सी.पोलीस स्टेशन'
                        : v('n47Ps'),
                    width: 170),
                pw.Text(' गुन्हा रजि.नंबर ', style: regularStyle),
                underlineField(v('n47CrNo'), width: 60),
                pw.Text('/२०', style: regularStyle),
                underlineField(v('n47CrYear'), width: 35),
                pw.Text(' भा.न्या.सं.कलम ', style: regularStyle),
                underlineField(v('n47Section'), width: 200),
                pw.Text(' या गुन्ह्यात तपास कामी दि. ', style: regularStyle),
                underlineField(v('n47ArrestDay'), width: 25),
                pw.Text('/', style: regularStyle),
                underlineField(v('n47ArrestMonth'), width: 25),
                pw.Text('/२०', style: regularStyle),
                underlineField(v('n47ArrestYear'), width: 35),
                pw.Text(' रोजी ', style: regularStyle),
                underlineField(v('n47ArrestTime'), width: 55),
                pw.Text(' वा. खालील आधारावर व कारणांसाठी अटक करण्यात येत आहे.',
                    style: regularStyle),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Text('अ) गुन्ह्याची थोडक्यात हकीगत :-', style: boldStyle),
            pw.SizedBox(height: 2),
            multilineLines(v('n47OffenceFacts'), lines: 3),
            pw.SizedBox(height: 8),
            pw.Text('ब) अटक करण्यासंबंधाने आधार :-', style: boldStyle),
            for (var i = 1; i <= 5; i++)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Row(
                  children: [
                    pw.Text('$i) ', style: boldStyle),
                    pw.Expanded(child: underlineField(v('n47Ground$i'))),
                  ],
                ),
              ),
            pw.SizedBox(height: 8),
            pw.Text('क) अटकेची कारणे :-', style: boldStyle),
            for (var i = 1; i <= 5; i++)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Row(
                  children: [
                    pw.Text('$i) ', style: boldStyle),
                    pw.Expanded(child: underlineField(v('n47Reason$i'))),
                  ],
                ),
              ),
            pw.SizedBox(height: 8),
            pw.Text(
              'ड) ${v('n47Bailable').isEmpty ? 'सदर गुन्हा हा जामीनपात्र/अजामीनपात्र आहे. गुन्हा जामीनपात्र असल्याने आपण योग्य तो जामीन दिल्यास आपणास जामीनावर मुक्त करण्यात येईल।' : v('n47Bailable')}',
              style: regularStyle,
            ),
            pw.SizedBox(height: 6),
            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              spacing: 2,
              runSpacing: 2,
              children: [
                pw.Text('इ) आपणास दिनांक ', style: regularStyle),
                underlineField(v('n47RemandDay'), width: 25),
                pw.Text('/', style: regularStyle),
                underlineField(v('n47RemandMonth'), width: 25),
                pw.Text('/२०', style: regularStyle),
                underlineField(v('n47RemandYear'), width: 35),
                pw.Text(
                    ' रोजी मा.प्रथम वर्ग न्यायदंडाधिकारी यांचे समक्ष रिमांडसाठी हजर करण्यात येणार आहे.',
                    style: regularStyle),
              ],
            ),
            pw.Spacer(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    underlineField(v('n47AccusedSig'), width: 160),
                    pw.SizedBox(height: 2),
                    pw.Text('आरोपीची दिनांकीत सही', style: boldStyle),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('कळावे,', style: boldStyle),
                    pw.SizedBox(height: 16),
                    underlineField(v('n47IoSig'), width: 160),
                    pw.SizedBox(height: 2),
                    pw.Text('तपासी अधिकारी/अंमलदार', style: boldStyle),
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
  // PAGE 2: बी.एन.एस.एस.कलम ४८
  // ══════════════════════════════════════════════════════════════════════════
  if (show48) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 30),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            buildPdfHeader(),
            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('नोटीस', style: titleStyle),
                  pw.Text('बी.एन.एस.एस.कलम ४८', style: boldStyle),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('प्रति,', style: boldStyle),
            underlineField(v('n48To'), width: double.infinity),
            pw.SizedBox(height: 10),
            pw.Text(
              'विषय :- गुन्ह्याचे तपास कामी अटक केले संबंधी अवगत केले बाबत...',
              style: boldStyle,
            ),
            pw.SizedBox(height: 10),
            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              spacing: 2,
              runSpacing: 3,
              children: [
                pw.Text('आपणास याद्वारे कळविण्यात येते की, ',
                    style: regularStyle),
                underlineField(
                    v('n48Ps').isEmpty
                        ? 'म्हाळुंगे एम.आय.डी.सी.पोलीस स्टेशन'
                        : v('n48Ps'),
                    width: 170),
                pw.Text(' गुन्हा रजि.नंबर ', style: regularStyle),
                underlineField(v('n48CrNo'), width: 60),
                pw.Text('/२०', style: regularStyle),
                underlineField(v('n48CrYear'), width: 35),
                pw.Text(' भा.न्या.सं.कलम ', style: regularStyle),
                underlineField(v('n48Section'), width: 200),
                pw.Text(' या गुन्ह्यात आपले नातेवाईक / मित्र / आप्तेष्ट नामे ',
                    style: regularStyle),
                underlineField(v('n48RelativeName'), width: 180),
                pw.Text(' यांना दिनांक ', style: regularStyle),
                underlineField(v('n48ArrestDay'), width: 25),
                pw.Text('/', style: regularStyle),
                underlineField(v('n48ArrestMonth'), width: 25),
                pw.Text('/२०', style: regularStyle),
                underlineField(v('n48ArrestYear'), width: 35),
                pw.Text(' रोजी ', style: regularStyle),
                underlineField(v('n48ArrestTime'), width: 55),
                pw.Text(' वा. अटक करण्यात आली आहे.', style: regularStyle),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Text('अ) गुन्ह्याची थोडक्यात हकीगत :-', style: boldStyle),
            pw.SizedBox(height: 2),
            multilineLines(v('n48OffenceFacts'), lines: 3),
            pw.SizedBox(height: 8),
            pw.Text('ब) अटक करण्यासंबंधाने आधार :-', style: boldStyle),
            for (var i = 1; i <= 5; i++)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Row(
                  children: [
                    pw.Text('$i) ', style: boldStyle),
                    pw.Expanded(child: underlineField(v('n48Ground$i'))),
                  ],
                ),
              ),
            pw.SizedBox(height: 8),
            pw.Text('क) अटकेची कारणे :-', style: boldStyle),
            for (var i = 1; i <= 5; i++)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Row(
                  children: [
                    pw.Text('$i) ', style: boldStyle),
                    pw.Expanded(child: underlineField(v('n48Reason$i'))),
                  ],
                ),
              ),
            pw.SizedBox(height: 8),
            pw.Text(
              'ड) ${v('n48Bailable').isEmpty ? 'सदर गुन्हा हा जामीनपात्र/अजामीनपात्र आहे. गुन्हा जामीनपात्र असल्याने योग्य तो जामीन दिल्यास अटक व्यक्तीस जामीनावर मुक्त करण्यात येईल।' : v('n48Bailable')}',
              style: regularStyle,
            ),
            pw.SizedBox(height: 6),
            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.center,
              spacing: 2,
              runSpacing: 2,
              children: [
                pw.Text('इ) अटक व्यक्तीला दिनांक ', style: regularStyle),
                underlineField(v('n48RemandDay'), width: 25),
                pw.Text('/', style: regularStyle),
                underlineField(v('n48RemandMonth'), width: 25),
                pw.Text('/२०', style: regularStyle),
                underlineField(v('n48RemandYear'), width: 35),
                pw.Text(
                    ' रोजी मा.प्रथम वर्ग न्यायदंडाधिकारी यांचे समक्ष रिमांडसाठी हजर करण्यात येणार आहे.',
                    style: regularStyle),
              ],
            ),
            pw.Spacer(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    underlineField(v('n48RelativeSig'), width: 160),
                    pw.SizedBox(height: 2),
                    pw.Text('नातेवाईकाची दिनांकीत सही', style: boldStyle),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('कळावे,', style: boldStyle),
                    pw.SizedBox(height: 16),
                    underlineField(v('n48IoSig'), width: 160),
                    pw.SizedBox(height: 2),
                    pw.Text('तपासी अधिकारी/अंमलदार', style: boldStyle),
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
