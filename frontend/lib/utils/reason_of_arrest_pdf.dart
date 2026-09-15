import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> previewReasonOfArrestPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final bytes = await generateReasonOfArrestPdf(doc);
  if (!context.mounted) return;
  final fileName =
      'Reason_of_Arrest_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

Future<Uint8List> generateReasonOfArrestPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final devanagari = await PdfGoogleFonts.notoSansDevanagariRegular();
  final devanagariBold = await PdfGoogleFonts.notoSansDevanagariBold();

  final regular = pw.TextStyle(
    font: devanagari,
    fontSize: 10.5,
    lineSpacing: 2,
  );
  final bold = pw.TextStyle(
    font: devanagariBold,
    fontSize: 10.5,
    fontWeight: pw.FontWeight.bold,
  );
  final headerStyle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 11,
    fontWeight: pw.FontWeight.bold,
  );
  final titleStyle = pw.TextStyle(
    font: devanagariBold,
    fontSize: 14.5,
    fontWeight: pw.FontWeight.bold,
  );

  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  final outwardNo = v('outwardNo');
  final outwardYear = v('outwardYear', '२०२५');
  final policeStation = v('policeStation', v('subjectPs'));
  final taluka = v('taluka', v('ioTaluka'));
  final district = v('district', v('ioDistrict'));
  final noticeDate = v('noticeDate');
  final accusedNameAddress = v('accusedNameAddress');
  final subjectPs = v('subjectPs', policeStation);
  final subjectCrNo = v('subjectCrNo');
  final subjectSection = v('subjectSection');
  final ioName = v('ioName', v('ioNameRank'));

  final section = v('formSection').toLowerCase();
  final showMain = section.isEmpty ||
      (section.contains('main') && !section.contains('continuation'));
  final showCont = section.isEmpty || section.contains('continuation');

  if (showMain) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 26),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Top Header
            pw.Center(
              child: pw.Text(
                'भारतीय नागरीक सुरक्षा संहिता,२०२३ चे कलम ३५ (१)(ब)(ii) नुसार अन्वये',
                style: headerStyle,
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 5),

            // Title
            pw.Center(
              child: pw.Text(
                'सुचनापत्र',
                style: titleStyle,
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 8),

            // Right-aligned dispatch details
            pw.Align(
              alignment: pw.Alignment.topRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.RichText(
                    text: pw.TextSpan(
                      style: regular,
                      children: [
                        const pw.TextSpan(text: 'जावक.क्रमांक- '),
                        pw.TextSpan(
                          text: outwardNo.isNotEmpty
                              ? '  $outwardNo  '
                              : '          ',
                          style: bold,
                        ),
                        pw.TextSpan(text: '/$outwardYear'),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.RichText(
                    text: pw.TextSpan(
                      style: regular,
                      children: [
                        const pw.TextSpan(text: 'पोलीस स्टेशन '),
                        pw.TextSpan(
                          text: policeStation.isNotEmpty
                              ? policeStation
                              : '-------------',
                          style: bold,
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.RichText(
                    text: pw.TextSpan(
                      style: regular,
                      children: [
                        const pw.TextSpan(text: 'ता.'),
                        pw.TextSpan(
                          text: taluka.isNotEmpty ? taluka : '---------',
                          style: bold,
                        ),
                        const pw.TextSpan(text: ' -जिल्हा'),
                        pw.TextSpan(
                          text: district.isNotEmpty ? district : '----------',
                          style: bold,
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.RichText(
                    text: pw.TextSpan(
                      style: regular,
                      children: [
                        const pw.TextSpan(text: 'दिनांक:- '),
                        pw.TextSpan(
                          text: noticeDate.isNotEmpty
                              ? noticeDate
                              : '    /    /२०२५',
                          style: bold,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            // Recipient block
            pw.Text('प्रति,', style: bold),
            pw.SizedBox(height: 2),
            pw.RichText(
              text: pw.TextSpan(
                style: regular,
                children: [
                  const pw.TextSpan(text: 'नाव व पत्ता '),
                  pw.TextSpan(
                    text: accusedNameAddress.isNotEmpty
                        ? accusedNameAddress
                        : '---------------------------------------------------------------------------------------------------------------------------------------------------',
                    style: accusedNameAddress.isNotEmpty ? bold : regular,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            // Subject block
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: regular,
                children: [
                  const pw.TextSpan(text: 'विषय:- पोलीस स्टेशन '),
                  pw.TextSpan(
                    text: subjectPs.isNotEmpty ? subjectPs : '---------',
                    style: bold,
                  ),
                  const pw.TextSpan(text: ' गुन्हा रजि.क्र.'),
                  pw.TextSpan(
                    text: subjectCrNo.isNotEmpty ? subjectCrNo : '-------',
                    style: bold,
                  ),
                  const pw.TextSpan(text: 'कलम '),
                  pw.TextSpan(
                    text: subjectSection.isNotEmpty ? subjectSection : '-----',
                    style: bold,
                  ),
                  const pw.TextSpan(
                    text:
                        ' --- भा.न्या.स. नुसार दाखल असलेल्या गुन्ह्यांचे अनुषंगाने आरोपीस अटक करतांना अटक करण्यासाठी आधारभूत मुद्दे आणि अटकेची कारणे कळविणे बाबत.',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            // Main Notice Paragraph (Flowing paragraph)
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: regular,
                children: [
                  const pw.TextSpan(
                    text:
                        '       आपणास या सुचनापत्राद्वारे कळविण्यात येते की,आपल्या विरुद्ध पोलीस ठाणे ',
                  ),
                  pw.TextSpan(
                    text: policeStation.isNotEmpty
                        ? policeStation
                        : '-------------',
                    style: bold,
                  ),
                  const pw.TextSpan(text: 'येथे गुन्हा रजि.क्र.'),
                  pw.TextSpan(
                    text: subjectCrNo.isNotEmpty ? subjectCrNo : '-------',
                    style: bold,
                  ),
                  const pw.TextSpan(text: '/-- कलम '),
                  pw.TextSpan(
                    text: subjectSection.isNotEmpty
                        ? subjectSection
                        : '------------',
                    style: bold,
                  ),
                  const pw.TextSpan(
                    text:
                        ' भारतीय न्याय संहिता २०२३ अन्वये गुन्हा नोंद करण्यात आला असुन,आम्ही',
                  ),
                  pw.TextSpan(
                    text: ioName.isNotEmpty ? ioName : '--------------',
                    style: bold,
                  ),
                  const pw.TextSpan(
                    text:
                        ' तपासी अधिकारी म्हणून सदर गुन्ह्यांचा तपास करीत आहोत.सदर गुन्ह्यांचे तपासकामी आपणास अटक करणे गरजेचे असून भारतीय नागरीक सुरक्षा संहिता २०२३ चे कलम ३५ (१)(ब)(ii) नुसार ) अटकेची कारणे खालील प्रमाणे आहेत.',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Reasons Header
            pw.Center(
              child: pw.Text(
                'अटकेची कारणे (REASONS FOR ARREST)',
                style: bold.copyWith(fontSize: 10.5),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 8),

            // Reasons 1 to 5
            for (var i = 1; i <= 5; i++) ...[
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.RichText(
                  text: pw.TextSpan(
                    style: regular,
                    children: [
                      pw.TextSpan(
                        text: '${['१', '२', '३', '४', '५'][i - 1]}. ',
                        style: bold,
                      ),
                      pw.TextSpan(
                        text: v('reason$i').isNotEmpty
                            ? v('reason$i')
                            : '---------------------------------------------------------------------------------------------------------------------------------------------------',
                        style: v('reason$i').isNotEmpty ? bold : regular,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            pw.Spacer(),

            // Bottom Right continuation marker
            pw.Align(
              alignment: pw.Alignment.bottomRight,
              child: pw.Text('२..', style: bold),
            ),
          ],
        ),
      ),
    );
  }

  if (showCont) {
    final relativeName = v('relativeName');
    final relativeAddress = v('relativeAddress');
    final relativePhone = v('relativePhone');
    final accusedSig = v('accusedSig');
    final accusedNameSig = v('accusedNameSig');
    final accusedDateTime = v('accusedDateTime');
    final ioNameRank = v('ioNameRank');
    final ioPs = v('ioPs');
    final ioTaluka = v('ioTaluka');
    final ioDistrict = v('ioDistrict');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 26),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                '..२..',
                style: bold.copyWith(fontSize: 12),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 18),

            // Paragraph 1
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: regular,
                children: const [
                  pw.TextSpan(
                    text:
                        '       आपणास असेही कळविण्यांत येते की, नमुद गुन्हा हा दखलपात्र असुन अजामीनपात्र आहे आणि त्यामुळे आपण त्या गुन्ह्यात न्यायालयात जामिनाचा अर्ज सादर करुन न्यायालयाचे आदेशाने जामिनावर मुक्त होवु शकता.',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Paragraph 2
            pw.RichText(
              textAlign: pw.TextAlign.justify,
              text: pw.TextSpan(
                style: regular,
                children: [
                  const pw.TextSpan(
                    text: '       आपल्या अटकेची माहीती आपले नातेवाईक/ मित्र ',
                  ),
                  pw.TextSpan(
                    text: relativeName.isNotEmpty
                        ? relativeName
                        : '-----------------',
                    style: bold,
                  ),
                  const pw.TextSpan(text: 'रा.'),
                  pw.TextSpan(
                    text: relativeAddress.isNotEmpty
                        ? relativeAddress
                        : '------------------',
                    style: bold,
                  ),
                  const pw.TextSpan(
                    text: 'यांना लेखी सुचनेव्दारे/फोन क्रमांक ',
                  ),
                  pw.TextSpan(
                    text:
                        relativePhone.isNotEmpty ? relativePhone : '---------',
                    style: bold,
                  ),
                  const pw.TextSpan(
                    text: 'यावर संपर्क करुन देण्यांत आली आहे.',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Paragraph 3
            pw.RichText(
              text: pw.TextSpan(
                style: regular,
                children: const [
                  pw.TextSpan(
                    text: '       याकरीता आपणास सुचनापत्र देण्यांत येत आहे.',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 36),

            // Signatures (Two Columns)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left Column (Accused)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('मला सुचनापत्र प्राप्त झाले', style: bold),
                    pw.SizedBox(height: 16),
                    pw.RichText(
                      text: pw.TextSpan(
                        style: bold,
                        children: [
                          const pw.TextSpan(text: '(आरोपीची सही'),
                          pw.TextSpan(
                            text: accusedSig.isNotEmpty
                                ? ' $accusedSig '
                                : '-----------------',
                            style: bold,
                          ),
                          const pw.TextSpan(text: ')'),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.RichText(
                      text: pw.TextSpan(
                        style: bold,
                        children: [
                          const pw.TextSpan(text: 'आरोपीचे नांव '),
                          pw.TextSpan(
                            text: accusedNameSig.isNotEmpty
                                ? accusedNameSig
                                : '----- ---------',
                            style: bold,
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.RichText(
                      text: pw.TextSpan(
                        style: bold,
                        children: [
                          const pw.TextSpan(text: 'दिनांक:व वेळ '),
                          pw.TextSpan(
                            text: accusedDateTime.isNotEmpty
                                ? accusedDateTime
                                : '----------------------',
                            style: bold,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Right Column (IO)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('तपास अधि सही/-', style: bold),
                    pw.SizedBox(height: 16),
                    pw.RichText(
                      text: pw.TextSpan(
                        style: bold,
                        children: [
                          const pw.TextSpan(text: 'नाव/हुद्दा'),
                          pw.TextSpan(
                            text: ioNameRank.isNotEmpty
                                ? ' $ioNameRank'
                                : '----------',
                            style: bold,
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.RichText(
                      text: pw.TextSpan(
                        style: bold,
                        children: [
                          const pw.TextSpan(text: 'पोलीस स्टेशन'),
                          pw.TextSpan(
                            text: ioPs.isNotEmpty ? ' $ioPs' : '-----------',
                            style: bold,
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.RichText(
                      text: pw.TextSpan(
                        style: bold,
                        children: [
                          const pw.TextSpan(text: 'ता.'),
                          pw.TextSpan(
                            text:
                                ioTaluka.isNotEmpty ? ' $ioTaluka ' : '-------',
                            style: bold,
                          ),
                          const pw.TextSpan(text: ' जिल्हा'),
                          pw.TextSpan(
                            text: ioDistrict.isNotEmpty
                                ? ' $ioDistrict'
                                : '---------',
                            style: bold,
                          ),
                        ],
                      ),
                    ),
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
