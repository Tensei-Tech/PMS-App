import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> previewInterrogationFormPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final bytes = await generateInterrogationFormPdf(doc);
  if (!context.mounted) return;
  final fileName =
      'Interrogation_Form_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

Future<Uint8List> generateInterrogationFormPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final devanagari = await PdfGoogleFonts.notoSansDevanagariRegular();
  final devanagariBold = await PdfGoogleFonts.notoSansDevanagariBold();

  final regular = pw.TextStyle(font: devanagari, fontSize: 9.5);
  final bold = pw.TextStyle(
    font: devanagariBold,
    fontSize: 9.5,
    fontWeight: pw.FontWeight.bold,
  );
  final headerTitle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 13,
    fontWeight: pw.FontWeight.bold,
  );
  final headerSub = pw.TextStyle(
    font: devanagariBold,
    fontSize: 11,
    fontWeight: pw.FontWeight.bold,
  );

  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  const border = pw.BorderSide(color: PdfColors.black, width: 0.8);

  pw.Widget buildTableRow({
    required String srNo,
    required String label,
    required String value,
    double minHeight = 40,
    bool isLast = false,
  }) {
    return pw.Container(
      constraints: pw.BoxConstraints(minHeight: minHeight),
      decoration: pw.BoxDecoration(
        border: isLast
            ? null
            : const pw.BoxDecoration(border: pw.Border(bottom: border)).border,
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            width: 32,
            decoration: const pw.BoxDecoration(border: pw.Border(right: border)),
            alignment: pw.Alignment.center,
            child: pw.Text(srNo, style: bold),
          ),
          pw.Container(
            width: 170,
            decoration: const pw.BoxDecoration(border: pw.Border(right: border)),
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(label, style: bold),
          ),
          pw.Expanded(
            child: pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(value, style: regular),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // ── PAGE 1 (Image 1: Rows 1–10) ──
  // ══════════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
      build: (pw.Context context) {
        final ps = v('ps');
        final gurNo = v('gurNo');
        final kalam = v('kalam');
        final ioName = v('ioName');
        final accusedName = v('accusedName');
        final arrestDt = v('arrestDateTime');
        final dobPlaceAge = v('dobPlaceAge');
        final idMarks = v('idMarks');
        final address = v('address');
        final dharma = v('dharma');
        final jati = v('jati');

        final phys = doc['physicalTable'] is Map
            ? Map<String, dynamic>.from(doc['physicalTable'] as Map)
            : <String, dynamic>{};

        String pVal(String key) => phys[key]?.toString().trim() ?? '';

        pw.Widget subRow({
          required String srNo,
          required String label,
          required pw.Widget child,
          double minHeight = 28,
          bool hasBottomBorder = true,
        }) {
          return pw.Container(
            constraints: pw.BoxConstraints(minHeight: minHeight),
            decoration: pw.BoxDecoration(
              border: hasBottomBorder
                  ? const pw.Border(bottom: border)
                  : const pw.Border(),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Container(
                  width: 32,
                  decoration:
                      const pw.BoxDecoration(border: pw.Border(right: border)),
                  alignment: pw.Alignment.center,
                  child: pw.Text(srNo, style: bold),
                ),
                pw.Container(
                  width: 140,
                  decoration:
                      const pw.BoxDecoration(border: pw.Border(right: border)),
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(label, style: bold),
                ),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
                    alignment: pw.Alignment.centerLeft,
                    child: child,
                  ),
                ),
              ],
            ),
          );
        }

        pw.Widget chehareRow(
          List<(String, String)> cols, {
          bool isLast = false,
        }) {
          return pw.Container(
            height: 24,
            decoration: pw.BoxDecoration(
              border: isLast
                  ? const pw.Border()
                  : const pw.Border(bottom: border),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cols.length; i++) ...[
                  pw.Container(
                    width: 48,
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        left: i > 0 ? border : pw.BorderSide.none,
                        right: border,
                      ),
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text(cols[i].$1, style: bold),
                  ),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4),
                      alignment: pw.Alignment.centerLeft,
                      child: pw.Text(cols[i].$2, style: regular),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('-० चौकशी अहवाल ०-', style: headerTitle),
                  pw.SizedBox(height: 2),
                  pw.Text('स्थानिक गुन्हे शाखा,उस्मानाबाद', style: headerSub),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Main Table
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                    color: PdfColors.black, width: border.width),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // Rows 1-6 + Photo Box
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Expanded(
                        flex: 5,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            subRow(
                              srNo: '१',
                              label: 'पोलीस ठाणे',
                              child: pw.Text(ps, style: regular),
                            ),
                            subRow(
                              srNo: '२',
                              label: 'गुरनं / कलम',
                              minHeight: 38,
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('गुरनं - $gurNo', style: regular),
                                  pw.Text('कलम - $kalam', style: regular),
                                ],
                              ),
                            ),
                            subRow(
                              srNo: '३',
                              label: 'तपासी अधिका-याचे नांव व हुद्दा',
                              minHeight: 32,
                              child: pw.Text(ioName, style: regular),
                            ),
                            subRow(
                              srNo: '४',
                              label: 'गुन्हेगाराचे नांव व टोपन नांव',
                              minHeight: 32,
                              child: pw.Text(accusedName, style: regular),
                            ),
                            subRow(
                              srNo: '५',
                              label: 'अटक तारीख व वेळ',
                              child: pw.Text(arrestDt, style: regular),
                            ),
                            subRow(
                              srNo: '६',
                              label: 'जन्म तारीख,जन्माठिकाण,वय',
                              minHeight: 32,
                              hasBottomBorder: false,
                              child: pw.Text(dobPlaceAge, style: regular),
                            ),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Container(
                          decoration: const pw.BoxDecoration(
                              border: pw.Border(left: border)),
                          padding: const pw.EdgeInsets.only(top: 8),
                          alignment: pw.Alignment.topCenter,
                          child: pw.Text('आरोपींचा फोटो', style: bold),
                        ),
                      ),
                    ],
                  ),

                  // Row 7: चेहरे पट्टी माहीती
                  pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(top: border, bottom: border),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        pw.Row(
                          children: [
                            pw.Container(
                              width: 32,
                              height: 22,
                              decoration: const pw.BoxDecoration(
                                  border: pw.Border(right: border)),
                              alignment: pw.Alignment.center,
                              child: pw.Text('७', style: bold),
                            ),
                            pw.Expanded(
                              child: pw.Container(
                                padding:
                                    const pw.EdgeInsets.symmetric(horizontal: 6),
                                child: pw.Text('चेहरे पट्टी माहीती', style: bold),
                              ),
                            ),
                          ],
                        ),
                        pw.Container(
                          decoration: const pw.BoxDecoration(
                              border: pw.Border(top: border)),
                          child: pw.Column(
                            children: [
                              chehareRow([
                                ('उंची', pVal('उंची')),
                                ('बांधा', pVal('बांधा')),
                                ('केस', pVal('केस')),
                                ('भुवया', pVal('भुवया')),
                              ]),
                              chehareRow([
                                ('कपाळ', pVal('कपाळ')),
                                ('डोळे', pVal('डोळे')),
                                ('दृष्टी', pVal('दृष्टी')),
                                ('नाक', pVal('नाक')),
                              ]),
                              chehareRow([
                                ('ओंट', pVal('ओंट')),
                                ('छाती', pVal('छाती')),
                                ('बोटे', pVal('बोटे')),
                                ('हनुवटी', pVal('हनुवटी')),
                              ]),
                              chehareRow([
                                ('कान', pVal('कान')),
                                ('चेहरा', pVal('चेहरा')),
                                ('वर्ण', pVal('वर्ण')),
                                ('दाढी', pVal('दाढी')),
                              ]),
                              chehareRow([
                                ('मिशा', pVal('मिशा')),
                                ('भाषा', pVal('भाषा')),
                                ('गाल', pVal('गाल')),
                                ('पोशाख', pVal('पोशाख')),
                              ]),
                              chehareRow([
                                ('व्यसन', pVal('व्यसन')),
                                ('', ''),
                                ('', ''),
                                ('', ''),
                              ], isLast: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Row 8
                  buildTableRow(
                    srNo: '८',
                    label: 'ओळखोच्या खुणा ( तीळ,\nमार,जखम,गोंदन,अपंगत्व )',
                    value: idMarks,
                    minHeight: 48,
                  ),

                  // Row 9
                  buildTableRow(
                    srNo: '९',
                    label:
                        'सध्याचा मुळ पत्ता घर क्र,इमारतीचे नांव,परीसराचे नांव,रस्ता,शहर राज्य ,मोबाईल नंबर',
                    value: address,
                    minHeight: 56,
                  ),

                  // Row 10
                  pw.Container(
                    height: 38,
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        pw.Container(
                          width: 32,
                          decoration: const pw.BoxDecoration(
                              border: pw.Border(right: border)),
                          alignment: pw.Alignment.center,
                          child: pw.Text('१०', style: bold),
                        ),
                        pw.Container(
                          width: 170,
                          decoration: const pw.BoxDecoration(
                              border: pw.Border(right: border)),
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          alignment: pw.Alignment.centerLeft,
                          child: pw.Text('धर्म/जात', style: bold),
                        ),
                        pw.Expanded(
                          child: pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 6, vertical: 4),
                            child: pw.Row(
                              children: [
                                pw.Text('धर्म - $dharma', style: regular),
                                pw.SizedBox(width: 24),
                                pw.Text('जात - $jati', style: regular),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  // ══════════════════════════════════════════════════════════════════════
  // ── PAGE 2 (Image 2: Rows 11–15) ──
  // ══════════════════════════════════════════════════════════════════════
  final page2List = doc['page2Rows'] is List
      ? (doc['page2Rows'] as List).map((e) => e?.toString() ?? '').toList()
      : (doc['familyRows'] is List
          ? (doc['familyRows'] as List).take(5).map((e) => e?.toString() ?? '').toList()
          : <String>[]);

  String p2Val(int idx) => idx < page2List.length ? page2List[idx] : '';

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
      build: (pw.Context context) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            border:
                pw.Border.all(color: PdfColors.black, width: border.width),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              buildTableRow(
                srNo: '११',
                label: 'व्यवसाय/काम यापुर्वीचा व्यवसाय',
                value: p2Val(0),
                minHeight: 140,
              ),
              buildTableRow(
                srNo: '१२',
                label:
                    'वडीलाचे /आईचे नांव,वय, पत्ता,व्यवसाय,फोन व इतर आवश्यक माहिती',
                value: p2Val(1),
                minHeight: 140,
              ),
              buildTableRow(
                srNo: '१३',
                label:
                    'मुले/मुलीचे नांव,वय,पत्ता, व्यवसाय,फोन व इतर आवश्यक माहीती',
                value: p2Val(2),
                minHeight: 140,
              ),
              buildTableRow(
                srNo: '१४',
                label:
                    'भावाचे/बहीणींचे नांव ,वय, पत्ता,व्यवसाय,फोन व इतर आवश्यक माहीती',
                value: p2Val(3),
                minHeight: 140,
              ),
              buildTableRow(
                srNo: '१५',
                label:
                    'बहीण/ भाऊजींचे नांव ,वय, पत्ता,व्यवसाय,फोन व इतर आवश्यक माहीती',
                value: p2Val(4),
                minHeight: 140,
                isLast: true,
              ),
            ],
          ),
        );
      },
    ),
  );

  // ══════════════════════════════════════════════════════════════════════
  // ── PAGE 3 (Image 3: Rows 16–21) ──
  // ══════════════════════════════════════════════════════════════════════
  final page3List = doc['page3Rows'] is List
      ? (doc['page3Rows'] as List).map((e) => e?.toString() ?? '').toList()
      : (doc['familyRows'] is List
          ? (doc['familyRows'] as List).skip(5).take(6).map((e) => e?.toString() ?? '').toList()
          : <String>[]);

  String p3Val(int idx) => idx < page3List.length ? page3List[idx] : '';

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
      build: (pw.Context context) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            border:
                pw.Border.all(color: PdfColors.black, width: border.width),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              buildTableRow(
                srNo: '१६',
                label:
                    'सासु/सासऱ्याचे नांव,वय,पत्ता, व्यवसाय,फोन व इतर आवश्यक माहीती',
                value: p3Val(0),
                minHeight: 115,
              ),
              buildTableRow(
                srNo: '१७',
                label:
                    'मेव्हणा/मेव्हणींची नावे वय, पत्ता, व्यवसाय,फोन व इतर आवश्यक माहीती',
                value: p3Val(1),
                minHeight: 115,
              ),
              buildTableRow(
                srNo: '१८',
                label:
                    'मामा/मामीचे नांव ,वय, पत्ता,व्यवसाय,फोन व इतर आवश्यक माहीती',
                value: p3Val(2),
                minHeight: 115,
              ),
              buildTableRow(
                srNo: '१९',
                label:
                    'काका/ मावशींचे नांव ,वय, पत्ता,व्यवसाय,फोन व इतर आवश्यक माहीती',
                value: p3Val(3),
                minHeight: 115,
              ),
              buildTableRow(
                srNo: '२०',
                label:
                    'चुलता/चुलतीचे नांव ,वय, पत्ता,व्यवसाय,फोन व इतर आवश्यक माहीती',
                value: p3Val(4),
                minHeight: 115,
              ),
              buildTableRow(
                srNo: '२१',
                label:
                    'आत्याचे / मामाचे नांव ,वय, पत्ता,व्यवसाय,फोन व इतर आवश्यक माहीती',
                value: p3Val(5),
                minHeight: 115,
                isLast: true,
              ),
            ],
          ),
        );
      },
    ),
  );

  // ══════════════════════════════════════════════════════════════════════
  // ── PAGE 4 (Image 4: Rows 22–30) ──
  // ══════════════════════════════════════════════════════════════════════
  final page4List = doc['page4Rows'] is List
      ? (doc['page4Rows'] as List).map((e) => e?.toString() ?? '').toList()
      : (doc['idHistoryRows'] is List
          ? (doc['idHistoryRows'] as List).map((e) => e?.toString() ?? '').toList()
          : <String>[]);

  String p4Val(int idx) => idx < page4List.length ? page4List[idx] : '';

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
      build: (pw.Context context) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            border:
                pw.Border.all(color: PdfColors.black, width: border.width),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              buildTableRow(
                srNo: '२२',
                label:
                    'शिक्षण/शाळा/ कॉलेज (पत्ता) तसेच संगणकाचे ज्ञान आहे काय?',
                value: p4Val(0),
                minHeight: 65,
              ),
              buildTableRow(
                srNo: '२३',
                label: 'नोकरीस असल्यास पुर्वीचे कार्यालयाचा पत्ता',
                value: p4Val(1),
                minHeight: 55,
              ),
              buildTableRow(
                srNo: '२४',
                label: 'आधारकार्ड क्रमांक',
                value: p4Val(2),
                minHeight: 36,
              ),
              buildTableRow(
                srNo: '२५',
                label: 'पॅनकार्ड क्रमांक',
                value: p4Val(3),
                minHeight: 36,
              ),
              buildTableRow(
                srNo: '२६',
                label: 'वाहन परवाना',
                value: p4Val(4),
                minHeight: 36,
              ),
              buildTableRow(
                srNo: '२७',
                label: 'रेशन कार्ड',
                value: p4Val(5),
                minHeight: 36,
              ),
              buildTableRow(
                srNo: '२८',
                label: 'मालमत्ता (अंदाजे)',
                value: p4Val(6),
                minHeight: 55,
              ),
              buildTableRow(
                srNo: '२९',
                label:
                    'यापुर्वी झालेली शिक्षा (पोलीस ठाणे,पत्ता गु.नो.क्र,कलम साथीदार,फरार आरोपी )',
                value: p4Val(7),
                minHeight: 95,
              ),
              buildTableRow(
                srNo: '३०',
                label:
                    'या गुन्ह्यातील आरोपींचे साथीदारांची नावे पुर्ण पत्ता मोबाईल नंबर सह',
                value: p4Val(8),
                minHeight: 140,
                isLast: true,
              ),
            ],
          ),
        );
      },
    ),
  );

  // ══════════════════════════════════════════════════════════════════════
  // ── PAGE 5 (Image 5: Rows 31–36) ──
  // ══════════════════════════════════════════════════════════════════════
  final page5List = doc['page5Rows'] is List
      ? (doc['page5Rows'] as List).map((e) => e?.toString() ?? '').toList()
      : (doc['crimeRows'] is List
          ? (doc['crimeRows'] as List).map((e) => e?.toString() ?? '').toList()
          : <String>[]);

  String p5Val(int idx) => idx < page5List.length ? page5List[idx] : '';

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
      build: (pw.Context context) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            border:
                pw.Border.all(color: PdfColors.black, width: border.width),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              buildTableRow(
                srNo: '३१',
                label: 'बसण्या - उठण्याच्या जागा',
                value: p5Val(0),
                minHeight: 110,
              ),
              buildTableRow(
                srNo: '३२',
                label:
                    'नमुद आरोपीस गुन्ह्याचे ठिकाणची (स्थळ,ईमारत) याबाबत माहीती मिळालेली उगमस्थाने (रेखी ) (गुन्हा करण्याचे स्थळा बाबत माहीती कोठून व कशी मिळवली)',
                value: p5Val(1),
                minHeight: 125,
              ),
              buildTableRow(
                srNo: '३३',
                label: 'गुन्हा करतेवेळी आरोपी यांनी वापरलेली वाहने',
                value: p5Val(2),
                minHeight: 110,
              ),
              buildTableRow(
                srNo: '३४',
                label:
                    'गुन्हा करते वेळी वापरलेली हत्यारे (काठी,कटवणी,पक्कड, पाने,कटर,गॅस कटर, व इतर )',
                value: p5Val(3),
                minHeight: 125,
              ),
              buildTableRow(
                srNo: '३५',
                label: 'गुन्हा करते वेळी येण्याची दिशा व रस्ते',
                value: p5Val(4),
                minHeight: 125,
              ),
              buildTableRow(
                srNo: '३६',
                label: 'गुन्हा करुन जातेवेळीची दिशा व रस्ते',
                value: p5Val(5),
                minHeight: 125,
                isLast: true,
              ),
            ],
          ),
        );
      },
    ),
  );

  // ══════════════════════════════════════════════════════════════════════
  // ── PAGE 6 (New Image 1: Rows 37–40 + IO Signature) ──
  // ══════════════════════════════════════════════════════════════════════
  final page6List = doc['page6Rows'] is List
      ? (doc['page6Rows'] as List).map((e) => e?.toString() ?? '').toList()
      : (doc['crimeRows'] is List
          ? (doc['crimeRows'] as List).skip(6).take(4).map((e) => e?.toString() ?? '').toList()
          : <String>[]);

  String p6Val(int idx) => idx < page6List.length ? page6List[idx] : '';

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
      build: (pw.Context context) {
        final ioName = v('ioSigName');
        final ioRank = v('ioSigRank');
        final ioCode = v('ioSigCode');
        final ioPosting = v('ioSigPosting');

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              decoration: pw.BoxDecoration(
                border:
                    pw.Border.all(color: PdfColors.black, width: border.width),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  buildTableRow(
                    srNo: '३७',
                    label: 'गुन्हा करण्याची पध्दत',
                    value: p6Val(0),
                    minHeight: 140,
                  ),
                  buildTableRow(
                    srNo: '३८',
                    label:
                        'गुन्ह्यातील चोरलेल्या मुद्देमालाबाबत आरोपीने सांगितलेली माहीती\n(साथीदार यांना वाटप,विक्री तसेच ईतर प्रकारे विल्हेवाट संपूर्ण हकिकत)',
                    value: p6Val(1),
                    minHeight: 180,
                  ),
                  buildTableRow(
                    srNo: '३९',
                    label:
                        'आरोपीस ओळखणारे पोलीस अधिकारी/अंमलदार,पोलीस पाटील',
                    value: p6Val(2),
                    minHeight: 90,
                  ),
                  buildTableRow(
                    srNo: '४०',
                    label: 'Advisorries',
                    value: p6Val(3),
                    minHeight: 110,
                    isLast: true,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 36),

            // IO Signature Block (Right)
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 260,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Center(
                      child: pw.Text('तपासणी अधिकाऱ्याची सही', style: bold),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Text('नांव :- $ioName', style: regular),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: pw.Text('पदनाम :- $ioRank', style: regular),
                        ),
                        pw.Text('कोड नंबर :- $ioCode', style: regular),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('नेमणुक :- $ioPosting', style: regular),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  // ══════════════════════════════════════════════════════════════════════
  // ── PAGE 7 (New Image 2: मुद्दा क्रमांक ३७ ची अधिक माहिती) ──
  // ══════════════════════════════════════════════════════════════════════
  final additional37 = v('additionalPoint37', v('additional37'));

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
      build: (pw.Context context) {
        return pw.Container(
          decoration: pw.BoxDecoration(
            border:
                pw.Border.all(color: PdfColors.black, width: border.width),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: border),
                ),
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'मुद्दा क्रमांक ३७ ची अधिक माहिती',
                      style: headerSub.copyWith(
                        decoration: pw.TextDecoration.underline,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'गुन्हा करण्याची पध्दत,रेखी,कार्यप्रणाली, मालाची विल्हेवाट व इतर उपयुक्त माहिती:-',
                      style: bold.copyWith(fontSize: 9),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Content Area
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  alignment: pw.Alignment.topLeft,
                  child: pw.Text(
                    additional37,
                    style: regular.copyWith(lineSpacing: 2),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  return pdf.save();
}
