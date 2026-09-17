import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart';
import 'form_image_pdf_helper.dart';
import 'marathi_text_renderer.dart';

Future<void> previewMobileSealLabelPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final fileName =
      'Mobile_Seal_Label_${DateTime.now().millisecondsSinceEpoch}.pdf';
  await FormImagePdfHelper.previewImageBasedPdf(
    context,
    fileName: fileName,
    pages: [_buildPgWidget(doc)],
    fallbackPdfGenerator: () => generateMobileSealLabelPdf(doc),
  );
}

Future<Uint8List> generateMobileSealLabelPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final loraBold = await PdfGoogleFonts.loraBold();
  final cache = await _preRenderAllMarathi(doc);

  final pw.TextStyle valueStyle = pw.TextStyle(
    font: loraBold,
    fontSize: 8.5,
    color: PdfColors.blue900,
  );

  pw.Widget renderText(String key, String? val, pw.TextStyle engStyle) {
    final text = val?.trim() ?? '';
    if (text.isEmpty) return pw.SizedBox();
    if (containsDevanagari(text)) {
      if (cache.has(key)) {
        return pw.Container(
          alignment: pw.Alignment.topLeft,
          child: cache.img(key),
        );
      }
    }
    return pw.Text(text, style: engStyle);
  }

  pw.Widget mLbl(String key) {
    if (cache.has(key)) return cache.img(key);
    return pw.SizedBox();
  }

  String? val(String key, dynamic v) => v?.toString();

  pw.Widget tableCell(String valKey, String? value,
      {pw.Alignment alignment = pw.Alignment.centerLeft}) {
    return pw.Container(
      alignment: alignment,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: renderText(valKey, value, valueStyle),
    );
  }

  pw.TableRow buildFormRow(String labelKey, String valKey, String? value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: mLbl(labelKey),
        ),
        tableCell(valKey, val(valKey, value)),
      ],
    );
  }

  pw.TableRow buildSubRow(String labelKey, String valKey, String? value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2.5),
          child: mLbl(labelKey),
        ),
        tableCell(valKey, val(valKey, value)),
      ],
    );
  }

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Header
            pw.Center(
              child: mLbl('hdr_title'),
            ),
            pw.SizedBox(height: 2),
            pw.Center(
              child: mLbl('hdr_subtitle'),
            ),
            pw.SizedBox(height: 6),
            mLbl('hdr_notice'),
            pw.SizedBox(height: 8),

            // Main Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.8),
                1: pw.FlexColumnWidth(3.2),
              },
              children: [
                buildFormRow('lbl_ps_district', 'val_psDistrict',
                    doc['psDistrict'] ?? doc['policeStation']),
                buildFormRow(
                    'lbl_crime_sec',
                    'val_crimeNoSection',
                    doc['crimeNoSection'] ??
                        '${doc['crNo'] ?? ''} ${doc['section'] ?? ''}'.trim()),
                buildFormRow('lbl_seizing_officer', 'val_seizingOfficer',
                    doc['seizingOfficer'] ?? doc['ioName']),
                buildFormRow(
                    'lbl_seized_from', 'val_seizedFrom', doc['seizedFrom']),
                buildFormRow(
                    'lbl_accused_name', 'val_accusedName', doc['accusedName']),
                buildFormRow(
                    'lbl_seizure_place_datetime',
                    'val_seizurePlaceDateTime',
                    doc['seizurePlaceDateTime'] ?? doc['seizedDate']),

                // Mobile Description with Police Station Stamp Box
                pw.TableRow(
                  children: [
                    pw.Container(
                      alignment: pw.Alignment.center,
                      padding: const pw.EdgeInsets.all(8),
                      child: mLbl('lbl_ps_stamp'),
                    ),
                    pw.Table(
                      border: pw.TableBorder.all(
                          color: PdfColors.black, width: 0.5),
                      columnWidths: const {
                        0: pw.FlexColumnWidth(1.8),
                        1: pw.FlexColumnWidth(1.8),
                      },
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(3),
                              child: mLbl('lbl_mobile_section_hdr'),
                            ),
                            pw.SizedBox(),
                          ],
                        ),
                        buildSubRow('lbl_mobile_company', 'val_mobileCompany',
                            doc['mobileCompany'] ?? doc['mobileMake']),
                        buildSubRow('lbl_imei_1', 'val_imei1', doc['imei1']),
                        buildSubRow('lbl_imei_2', 'val_imei2', doc['imei2']),
                        buildSubRow('lbl_mobile_serial', 'val_mobileSerialNo',
                            doc['mobileSerialNo'] ?? doc['mobileModel']),
                        buildSubRow(
                            'lbl_password_pattern',
                            'val_passwordPatternPin',
                            doc['passwordPatternPin']),
                        buildSubRow('lbl_mobile_condition',
                            'val_mobileCondition', doc['mobileCondition']),
                        buildSubRow('lbl_switch_off', 'val_switchOffStatus',
                            doc['switchOffStatus']),
                        buildSubRow('lbl_sim_present', 'val_simCardPresent',
                            doc['simCardPresent']),
                        buildSubRow('lbl_sim_company', 'val_simCompany',
                            doc['simCompany']),
                        buildSubRow('lbl_sim_calling_no', 'val_simCallingNo',
                            doc['simCallingNo'] ?? doc['simNo']),
                        buildSubRow('lbl_sim_serial', 'val_simCardSerialNo',
                            doc['simCardSerialNo']),
                        buildSubRow('lbl_memory_present',
                            'val_memoryCardPresent', doc['memoryCardPresent']),
                        buildSubRow('lbl_memory_company',
                            'val_memoryCardCompany', doc['memoryCardCompany']),
                        buildSubRow(
                            'lbl_memory_capacity',
                            'val_memoryCardCapacity',
                            doc['memoryCardCapacity']),
                        buildSubRow(
                            'lbl_memory_serial',
                            'val_memoryCardSerialNo',
                            doc['memoryCardSerialNo']),
                      ],
                    ),
                  ],
                ),

                // Exhibit Row
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: mLbl('lbl_exhibit_ref'),
                    ),
                    tableCell(
                        'val_exhibitNoLetter',
                        val('val_exhibitNoLetter',
                            doc['exhibitNoLetter'] ?? doc['labelNo'])),
                  ],
                ),

                // Signatures
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          mLbl('lbl_seized_person_sign'),
                          pw.SizedBox(height: 24),
                          tableCell(
                              'val_seizedPersonSign',
                              val('val_seizedPersonSign',
                                  doc['seizedPersonSign'])),
                        ],
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Center(child: mLbl('lbl_panch_signs')),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            children: [
                              mLbl('lbl_panch_1'),
                              pw.Expanded(
                                  child: tableCell(
                                      'val_panch1Sign',
                                      val('val_panch1Sign',
                                          doc['panch1Sign']))),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            children: [
                              mLbl('lbl_panch_2'),
                              pw.Expanded(
                                  child: tableCell(
                                      'val_panch2Sign',
                                      val('val_panch2Sign',
                                          doc['panch2Sign']))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // IO Signature & Seal Sample
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          mLbl('lbl_io_sign_stamp'),
                          pw.SizedBox(height: 24),
                          tableCell(
                              'val_ioNameSignStamp',
                              val('val_ioNameSignStamp',
                                  doc['ioNameSignStamp'] ?? doc['ioName'])),
                        ],
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          mLbl('lbl_seal_sample'),
                          pw.SizedBox(height: 24),
                          tableCell(
                              'val_sealSample',
                              val('val_sealSample',
                                  doc['sealSample'] ?? doc['remarks'])),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

Future<MarathiImageCache> _preRenderAllMarathi(Map<String, dynamic> doc) async {
  final pairs = <String, String>{
    'hdr_title': 'मोबाईल सिल लेबल नमुना',
    'hdr_subtitle': 'Exhibit च्या पाकीट वरील लेबल चा नमुना',
    'hdr_notice':
        'सुचना :— जप्ती नंतर हॅश व्हॅल्यु किंवा निरीक्षण पंचनामा झाला असेल तर मुद्देमालाच्या लेबल व पहिल्या जप्तीची तारीख त्यानंतर झालेली पंचनामा नंतर सिलबंद केल्याचा तारखा नमुद कराव्यात',
    'lbl_ps_district': 'पोलीस स्टेशन जिल्हा',
    'lbl_crime_sec': 'अपराध क्रमांक व कलम',
    'lbl_seizing_officer': 'जप्त करणारे अधिकारी नांव हुद्दा पोस्टे',
    'lbl_seized_from': 'कोणाकडुन जप्त केले त्याचे नांव पत्ता',
    'lbl_accused_name': 'आरोपीचे नाव',
    'lbl_seizure_place_datetime': 'जप्तीचे ठिकाण तारीख वेळ',
    'lbl_ps_stamp': 'पोलीस स्टेशन शिक्का',
    'lbl_mobile_section_hdr':
        'जप्त मालाचे वर्णन जप्तीपत्रकानुसार मोबाईलच्या बाबतीत',
    'lbl_mobile_company': 'मो कंपनी',
    'lbl_imei_1': 'IMEI 1',
    'lbl_imei_2': 'IMEI 2',
    'lbl_mobile_serial': 'मोबाईल सिरियल क्र.',
    'lbl_password_pattern': 'पासवर्ड/ पॅटर्न/ पिन (असल्यास नमूद करणे)',
    'lbl_mobile_condition': 'मोबाईल स्थिती (चालु / बंद)',
    'lbl_switch_off': 'स्विच ऑफ (होय / नाही)',
    'lbl_sim_present':
        'सिम कार्ड आहे किं नाही असल्यास खालील माहिती (होय / नाही)',
    'lbl_sim_company': 'सिम कंपनी',
    'lbl_sim_calling_no': 'सिमचा कॉलींग क्रमांक',
    'lbl_sim_serial': 'सिमकार्डवर दिसणारा सीरीयल क्र',
    'lbl_memory_present':
        'मेमरी कार्ड आहे किं नाही असल्यास खालील माहिती (होय / नाही)',
    'lbl_memory_company': 'मेमरीकार्ड कंपनी नांव',
    'lbl_memory_capacity': 'मेमरी कार्ड ची क्षमता',
    'lbl_memory_serial': 'मेमरी कार्डवर दिसणारा सिरीयल क्र',
    'lbl_exhibit_ref':
        'एक्झिबीट क्र तपासी अधिकारी यांच्या पत्रानुसार (उदा “Exhibit – A”)',
    'lbl_seized_person_sign': 'ज्यांचेकडुन जप्त केले त्यांची सही',
    'lbl_panch_signs': 'पंचाच्या सह्या',
    'lbl_panch_1': '१) ',
    'lbl_panch_2': '२) ',
    'lbl_io_sign_stamp': 'तपासी अधिकारी यांचे नाव सही शिक्का',
    'lbl_seal_sample': 'सिल नमुना',
  };

  void addIfDevanagari(String k, dynamic v) {
    final s = v?.toString() ?? '';
    if (s.isNotEmpty && containsDevanagari(s)) {
      pairs[k] = s;
    }
  }

  doc.forEach((key, value) {
    addIfDevanagari('val_$key', value);
  });

  final boldKeys = {
    'hdr_title',
    'hdr_subtitle',
    'lbl_ps_district',
    'lbl_crime_sec',
    'lbl_seizing_officer',
    'lbl_seized_from',
    'lbl_accused_name',
    'lbl_seizure_place_datetime',
    'lbl_ps_stamp',
    'lbl_mobile_section_hdr',
    'lbl_exhibit_ref',
    'lbl_seized_person_sign',
    'lbl_panch_signs',
    'lbl_io_sign_stamp',
    'lbl_seal_sample',
  };

  final cache = MarathiImageCache();
  await GoogleFonts.pendingFonts();

  for (final entry in pairs.entries) {
    final isBold = boldKeys.contains(entry.key);
    final double fs = entry.key == 'hdr_title'
        ? 13.0
        : (entry.key == 'hdr_subtitle'
            ? 11.0
            : (entry.key == 'hdr_notice' ? 8.0 : 8.5));
    final color =
        entry.key.startsWith('val_') ? const Color(0xFF0D47A1) : Colors.black87;

    await cache.add(
      entry.key,
      entry.value,
      GoogleFonts.notoSansDevanagari(
        fontSize: fs,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        color: color,
      ),
      maxWidth: entry.key == 'hdr_title' ||
              entry.key == 'hdr_subtitle' ||
              entry.key == 'hdr_notice'
          ? 520
          : 350,
    );
  }

  return cache;
}

Widget _buildPgWidget(Map<String, dynamic> doc) {
  String v(String key, [String fallback = '']) {
    final val = doc[key]?.toString().trim() ?? '';
    return val.isEmpty ? fallback : val;
  }

  final reg = FormImagePdfHelper.mReg(8.5, 1.3);
  final bld = FormImagePdfHelper.mBld(8.5, 1.3);
  final valStyle = FormImagePdfHelper.valStyle(8.5);

  Widget cell(Widget child,
      {EdgeInsets padding = const EdgeInsets.all(4),
      Alignment alignment = Alignment.centerLeft}) {
    return Container(
      alignment: alignment,
      padding: padding,
      child: child,
    );
  }

  TableRow formRow(String label, String value) {
    return TableRow(
      children: [
        cell(Text(label, style: bld)),
        cell(Text(value, style: valStyle)),
      ],
    );
  }

  TableRow subRow(String label, String value) {
    return TableRow(
      children: [
        cell(Text(label, style: bld),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2)),
        cell(Text(value, style: valStyle),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2)),
      ],
    );
  }

  final psDist = v('psDistrict', v('policeStation'));
  final crimeSec = v('crimeNoSection', '${v('crNo')} ${v('section')}'.trim());
  final seizingOff = v('seizingOfficer', v('ioName'));
  final seizedFrom = v('seizedFrom');
  final accusedName = v('accusedName');
  final seizurePlaceDt = v('seizurePlaceDateTime', v('seizedDate'));
  final exhibitNo = v('exhibitNoLetter', v('labelNo'));
  final seizedPersonSign = v('seizedPersonSign');
  final panch1Sign = v('panch1Sign');
  final panch2Sign = v('panch2Sign');
  final ioSignStamp = v('ioNameSignStamp', v('ioName'));
  final sealSample = v('sealSample', v('remarks'));

  return FormImagePdfHelper.buildA4Page(
    padding: const EdgeInsets.all(24),
    children: [
      Center(
        child:
            Text('मोबाईल सिल लेबल नमुना', style: FormImagePdfHelper.mBld(13)),
      ),
      const SizedBox(height: 2),
      Center(
        child: Text('Exhibit च्या पाकीट वरील लेबल चा नमुना',
            style: FormImagePdfHelper.mBld(11)),
      ),
      const SizedBox(height: 6),
      Text(
        'सुचना :— जप्ती नंतर हॅश व्हॅल्यु किंवा निरीक्षण पंचनामा झाला असेल तर मुद्देमालाच्या लेबल व पहिल्या जप्तीची तारीख त्यानंतर झालेली पंचनामा नंतर सिलबंद केल्याचा तारखा नमुद कराव्यात',
        style: reg.copyWith(fontSize: 8),
      ),
      const SizedBox(height: 8),
      Table(
        border: TableBorder.all(color: Colors.black, width: 0.6),
        columnWidths: const {
          0: FlexColumnWidth(1.8),
          1: FlexColumnWidth(3.2),
        },
        children: [
          formRow('पोलीस स्टेशन जिल्हा', psDist),
          formRow('अपराध क्रमांक व कलम', crimeSec),
          formRow('जप्त करणारे अधिकारी नांव हुद्दा पोस्टे', seizingOff),
          formRow('कोणाकडुन जप्त केले त्याचे नांव पत्ता', seizedFrom),
          formRow('आरोपीचे नाव', accusedName),
          formRow('जप्तीचे ठिकाण तारीख वेळ', seizurePlaceDt),
          TableRow(
            children: [
              Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(8),
                child: Text('पोलीस स्टेशन शिक्का',
                    style: bld, textAlign: TextAlign.center),
              ),
              Table(
                border: TableBorder.all(color: Colors.black, width: 0.5),
                columnWidths: const {
                  0: FlexColumnWidth(1.8),
                  1: FlexColumnWidth(1.8),
                },
                children: [
                  TableRow(
                    children: [
                      cell(
                          Text(
                              'जप्त मालाचे वर्णन जप्तीपत्रकानुसार मोबाईलच्या बाबतीत',
                              style: bld),
                          padding: const EdgeInsets.all(3)),
                      const SizedBox(),
                    ],
                  ),
                  subRow('मो कंपनी', v('mobileCompany', v('mobileMake'))),
                  subRow('IMEI 1', v('imei1')),
                  subRow('IMEI 2', v('imei2')),
                  subRow('मोबाईल सिरियल क्र.',
                      v('mobileSerialNo', v('mobileModel'))),
                  subRow('पासवर्ड/ पॅटर्न/ पिन (असल्यास नमूद करणे)',
                      v('passwordPatternPin')),
                  subRow('मोबाईल स्थिती (चालु / बंद)', v('mobileCondition')),
                  subRow('स्विच ऑफ (होय / नाही)', v('switchOffStatus')),
                  subRow(
                      'सिम कार्ड आहे किं नाही असल्यास खालील माहिती (होय / नाही)',
                      v('simCardPresent')),
                  subRow('सिम कंपनी', v('simCompany')),
                  subRow('सिमचा कॉलींग क्रमांक', v('simCallingNo', v('simNo'))),
                  subRow('सिमकार्डवर दिसणारा सीरीयल क्र', v('simCardSerialNo')),
                  subRow(
                      'मेमरी कार्ड आहे किं नाही असल्यास खालील माहिती (होय / नाही)',
                      v('memoryCardPresent')),
                  subRow('मेमरीकार्ड कंपनी नांव', v('memoryCardCompany')),
                  subRow('मेमरी कार्ड ची क्षमता', v('memoryCardCapacity')),
                  subRow('मेमरी कार्डवर दिसणारा सिरीयल क्र',
                      v('memoryCardSerialNo')),
                ],
              ),
            ],
          ),
          formRow(
              'एक्झिबीट क्र तपासी अधिकारी यांच्या पत्रानुसार (उदा “Exhibit – A”)',
              exhibitNo),
          TableRow(
            children: [
              cell(
                Column(
                  children: [
                    Text('ज्यांचेकडुन जप्त केले त्यांची सही',
                        style: bld, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    Text(seizedPersonSign, style: valStyle),
                  ],
                ),
                padding: const EdgeInsets.all(6),
                alignment: Alignment.center,
              ),
              cell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Text('पंचाच्या सह्या', style: bld)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('१) ', style: bld),
                        Expanded(child: Text(panch1Sign, style: valStyle)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('२) ', style: bld),
                        Expanded(child: Text(panch2Sign, style: valStyle)),
                      ],
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(6),
              ),
            ],
          ),
          TableRow(
            children: [
              cell(
                Column(
                  children: [
                    Text('तपासी अधिकारी यांचे नाव सही शिक्का',
                        style: bld, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    Text(ioSignStamp, style: valStyle),
                  ],
                ),
                padding: const EdgeInsets.all(6),
                alignment: Alignment.center,
              ),
              cell(
                Column(
                  children: [
                    Text('सिल नमुना', style: bld, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    Text(sealSample, style: valStyle),
                  ],
                ),
                padding: const EdgeInsets.all(6),
                alignment: Alignment.center,
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
