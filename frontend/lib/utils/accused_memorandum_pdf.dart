import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart';
import 'marathi_text_renderer.dart';

Future<void> previewAccusedMemorandumPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final bytes = await generateAccusedMemorandumPdf(doc);
  if (!context.mounted) return;
  final fileName =
      'Accused_Interrogation_Form_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

Future<Uint8List> generateAccusedMemorandumPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();
  final loraBold = await PdfGoogleFonts.loraBold();
  final cache = await _preRenderAllMarathi(doc);

  final pw.TextStyle englishBold = pw.TextStyle(
    font: loraBold,
    fontSize: 8.5,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.black,
  );

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

  pw.Widget tableCell(String valKey, String? value, {pw.Alignment alignment = pw.Alignment.centerLeft}) {
    return pw.Container(
      alignment: alignment,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: renderText(valKey, value, valueStyle),
    );
  }

  pw.Widget tableHeader(String text, {pw.Alignment alignment = pw.Alignment.center}) {
    return pw.Container(
      alignment: alignment,
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text, style: englishBold, textAlign: pw.TextAlign.center),
    );
  }

  pw.Widget buildAddressSubGrid({
    required String resKey,
    required String? resVal,
    required String talKey,
    required String? talVal,
    required String distKey,
    required String? distVal,
    required String stateKey,
    required String? stateVal,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              mLbl('lbl_ra'),
              pw.SizedBox(width: 4),
              pw.Expanded(flex: 3, child: tableCell(resKey, resVal)),
              pw.SizedBox(width: 6),
              mLbl('lbl_ta'),
              pw.SizedBox(width: 4),
              pw.Expanded(flex: 2, child: tableCell(talKey, talVal)),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Row(
            children: [
              mLbl('lbl_dist'),
              pw.SizedBox(width: 4),
              pw.Expanded(child: tableCell(distKey, distVal)),
              pw.SizedBox(width: 6),
              mLbl('lbl_state'),
              pw.SizedBox(width: 4),
              pw.Expanded(child: tableCell(stateKey, stateVal)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget buildRelativeBlock({
    required String number,
    required String titleKey,
    required String nameKey,
    required String? nameVal,
    required String occKey,
    required String? occVal,
    required String currAddrKey,
    required String? currAddrVal,
    required String currTalKey,
    required String? currTalVal,
    required String currDistKey,
    required String? currDistVal,
    required String currStateKey,
    required String? currStateVal,
    required String permAddrKey,
    required String? permAddrVal,
    required String permTalKey,
    required String? permTalVal,
    required String permDistKey,
    required String? permDistVal,
    required String permStateKey,
    required String? permStateVal,
    required String propKey,
    required String? propVal,
    required String phoneKey,
    required String? phoneVal,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
      columnWidths: const {
        0: pw.FixedColumnWidth(28),
        1: pw.FlexColumnWidth(1.8),
        2: pw.FlexColumnWidth(4.2),
      },
      children: [
        pw.TableRow(
          children: [
            tableHeader(number),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: mLbl(titleKey),
            ),
            tableCell(nameKey, nameVal),
          ],
        ),
        pw.TableRow(
          children: [
            pw.SizedBox(),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: mLbl('lbl_occ'),
            ),
            tableCell(occKey, occVal),
          ],
        ),
        pw.TableRow(
          children: [
            pw.SizedBox(),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: mLbl('lbl_curr_addr'),
            ),
            buildAddressSubGrid(
              resKey: currAddrKey,
              resVal: currAddrVal,
              talKey: currTalKey,
              talVal: currTalVal,
              distKey: currDistKey,
              distVal: currDistVal,
              stateKey: currStateKey,
              stateVal: currStateVal,
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.SizedBox(),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: mLbl('lbl_perm_addr'),
            ),
            buildAddressSubGrid(
              resKey: permAddrKey,
              resVal: permAddrVal,
              talKey: permTalKey,
              talVal: permTalVal,
              distKey: permDistKey,
              distVal: permDistVal,
              stateKey: permStateKey,
              stateVal: permStateVal,
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.SizedBox(),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: mLbl('lbl_prop'),
            ),
            tableCell(propKey, propVal),
          ],
        ),
        pw.TableRow(
          children: [
            pw.SizedBox(),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: mLbl('lbl_phone_other'),
            ),
            tableCell(phoneKey, phoneVal),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 1 — PARTICULARS & DESCRIPTION & MOTHER
  // ══════════════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(child: mLbl('hdr_title')),
            pw.SizedBox(height: 2),
            pw.Center(child: mLbl('hdr_subtitle')),
            pw.SizedBox(height: 8),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
              columnWidths: const {
                0: pw.FixedColumnWidth(28),
                1: pw.FlexColumnWidth(1.8),
                2: pw.FlexColumnWidth(4.2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    tableHeader('अ.क्र'),
                    tableHeader('विवरण'),
                    tableHeader('माहिती'),
                  ],
                ),
                pw.TableRow(
                  children: [
                    tableHeader('1.'),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: mLbl('lbl_ps')),
                    tableCell('val_ps', val('val_ps', doc['ps'])),
                  ],
                ),
                pw.TableRow(
                  children: [
                    tableHeader('2.'),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: mLbl('lbl_crime_sec')),
                    tableCell('val_crimeNoSection', val('val_crimeNoSection', doc['crimeNoSection'])),
                  ],
                ),
                pw.TableRow(
                  children: [
                    tableHeader('3.'),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: mLbl('lbl_accused_name')),
                    tableCell('val_accusedFullName', val('val_accusedFullName', doc['accusedFullName'])),
                  ],
                ),
                pw.TableRow(
                  children: [
                    tableHeader('4.'),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: mLbl('lbl_alias')),
                    tableCell('val_accusedAlias', val('val_accusedAlias', doc['accusedAlias'])),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.SizedBox(),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: mLbl('lbl_occ')),
                    tableCell('val_accusedOccupation', val('val_accusedOccupation', doc['accusedOccupation'])),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.SizedBox(),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: mLbl('lbl_prop')),
                    tableCell('val_accusedProperty', val('val_accusedProperty', doc['accusedProperty'])),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.SizedBox(),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: mLbl('lbl_farm_house')),
                    tableCell('val_accusedFarmHouseVehicle', val('val_accusedFarmHouseVehicle', doc['accusedFarmHouseVehicle'])),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.SizedBox(),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: mLbl('lbl_phone_other')),
                    tableCell('val_accusedPhoneOther', val('val_accusedPhoneOther', doc['accusedPhoneOther'])),
                  ],
                ),
                pw.TableRow(
                  children: [
                    tableHeader('5.'),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: mLbl('lbl_curr_addr_full')),
                    buildAddressSubGrid(
                      resKey: 'val_currResAddr',
                      resVal: val('val_currResAddr', doc['currResAddr']),
                      talKey: 'val_currTaluka',
                      talVal: val('val_currTaluka', doc['currTaluka']),
                      distKey: 'val_currDistrict',
                      distVal: val('val_currDistrict', doc['currDistrict']),
                      stateKey: 'val_currState',
                      stateVal: val('val_currState', doc['currState']),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    tableHeader('6.'),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: mLbl('lbl_perm_addr_full')),
                    buildAddressSubGrid(
                      resKey: 'val_permResAddr',
                      resVal: val('val_permResAddr', doc['permResAddr']),
                      talKey: 'val_permTaluka',
                      talVal: val('val_permTaluka', doc['permTaluka']),
                      distKey: 'val_permDistrict',
                      distVal: val('val_permDistrict', doc['permDistrict']),
                      stateKey: 'val_permState',
                      stateVal: val('val_permState', doc['permState']),
                    ),
                  ],
                ),
              ],
            ),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
              columnWidths: const {
                0: pw.FixedColumnWidth(28),
                1: pw.FlexColumnWidth(1.8),
                2: pw.FlexColumnWidth(4.2),
              },
              children: [
                pw.TableRow(
                  children: [
                    tableHeader('7.'),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: mLbl('lbl_desc')),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Column(
                        children: [
                          pw.Row(
                            children: [
                              mLbl('lbl_desc_color'),
                              pw.Expanded(child: tableCell('val_descColor', val('val_descColor', doc['descColor']))),
                              mLbl('lbl_desc_height'),
                              pw.Expanded(child: tableCell('val_descHeight', val('val_descHeight', doc['descHeight']))),
                              mLbl('lbl_desc_caste'),
                              pw.Expanded(child: tableCell('val_descCaste', val('val_descCaste', doc['descCaste']))),
                            ],
                          ),
                          pw.Row(
                            children: [
                              mLbl('lbl_desc_deform'),
                              pw.Expanded(child: tableCell('val_descDeformity', val('val_descDeformity', doc['descDeformity']))),
                              mLbl('lbl_desc_teeth'),
                              pw.Expanded(child: tableCell('val_descTeeth', val('val_descTeeth', doc['descTeeth']))),
                              mLbl('lbl_desc_hair'),
                              pw.Expanded(child: tableCell('val_descHair', val('val_descHair', doc['descHair']))),
                            ],
                          ),
                          pw.Row(
                            children: [
                              mLbl('lbl_desc_eyes'),
                              pw.Expanded(child: tableCell('val_descEyes', val('val_descEyes', doc['descEyes']))),
                              mLbl('lbl_desc_dress'),
                              pw.Expanded(child: tableCell('val_descDress', val('val_descDress', doc['descDress']))),
                            ],
                          ),
                          pw.Row(
                            children: [
                              mLbl('lbl_desc_voter'),
                              pw.Expanded(child: tableCell('val_descVoterName', val('val_descVoterName', doc['descVoterName']))),
                            ],
                          ),
                          pw.Row(
                            children: [
                              mLbl('lbl_desc_boil'),
                              pw.Expanded(child: tableCell('val_descBoil', val('val_descBoil', doc['descBoil']))),
                              mLbl('lbl_desc_mole'),
                              pw.Expanded(child: tableCell('val_descMole', val('val_descMole', doc['descMole']))),
                              mLbl('lbl_desc_tattoo'),
                              pw.Expanded(child: tableCell('val_descTattoo', val('val_descTattoo', doc['descTattoo']))),
                            ],
                          ),
                          pw.Row(
                            children: [
                              mLbl('lbl_desc_ears'),
                              pw.Expanded(child: tableCell('val_descEars', val('val_descEars', doc['descEars']))),
                              mLbl('lbl_desc_nose'),
                              pw.Expanded(child: tableCell('val_descNose', val('val_descNose', doc['descNose']))),
                              mLbl('lbl_desc_mustache'),
                              pw.Expanded(child: tableCell('val_descMustache', val('val_descMustache', doc['descMustache']))),
                            ],
                          ),
                          pw.Row(
                            children: [
                              mLbl('lbl_desc_face'),
                              pw.Expanded(child: tableCell('val_descFace', val('val_descFace', doc['descFace']))),
                              mLbl('lbl_desc_lang'),
                              pw.Expanded(child: tableCell('val_descLanguage', val('val_descLanguage', doc['descLanguage']))),
                              mLbl('lbl_desc_dob'),
                              pw.Expanded(child: tableCell('val_descDob', val('val_descDob', doc['descDob']))),
                            ],
                          ),
                          pw.Row(
                            children: [
                              mLbl('lbl_desc_complexion'),
                              pw.Expanded(child: tableCell('val_descComplexion', val('val_descComplexion', doc['descComplexion']))),
                              mLbl('lbl_desc_burn'),
                              pw.Expanded(child: tableCell('val_descBurnMarks', val('val_descBurnMarks', doc['descBurnMarks']))),
                            ],
                          ),
                          pw.Row(
                            children: [
                              mLbl('lbl_desc_main_id'),
                              pw.Expanded(child: tableCell('val_descMainIdMark', val('val_descMainIdMark', doc['descMainIdMark']))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    tableHeader('8.'),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: mLbl('lbl_birth_place')),
                    tableCell('val_accusedBirthPlace', val('val_accusedBirthPlace', doc['accusedBirthPlace'])),
                  ],
                ),
              ],
            ),

            buildRelativeBlock(
              number: '9.',
              titleKey: 'lbl_rel9_title',
              nameKey: 'val_rel9Name',
              nameVal: val('val_rel9Name', doc['rel9Name']),
              occKey: 'val_rel9Occ',
              occVal: val('val_rel9Occ', doc['rel9Occ']),
              currAddrKey: 'val_rel9CurrAddr',
              currAddrVal: val('val_rel9CurrAddr', doc['rel9CurrAddr']),
              currTalKey: 'val_rel9CurrTal',
              currTalVal: val('val_rel9CurrTal', doc['rel9CurrTal']),
              currDistKey: 'val_rel9CurrDist',
              currDistVal: val('val_rel9CurrDist', doc['rel9CurrDist']),
              currStateKey: 'val_rel9CurrState',
              currStateVal: val('val_rel9CurrState', doc['rel9CurrState']),
              permAddrKey: 'val_rel9PermAddr',
              permAddrVal: val('val_rel9PermAddr', doc['rel9PermAddr']),
              permTalKey: 'val_rel9PermTal',
              permTalVal: val('val_rel9PermTal', doc['rel9PermTal']),
              permDistKey: 'val_rel9PermDist',
              permDistVal: val('val_rel9PermDist', doc['rel9PermDist']),
              permStateKey: 'val_rel9PermState',
              permStateVal: val('val_rel9PermState', doc['rel9PermState']),
              propKey: 'val_rel9Prop',
              propVal: val('val_rel9Prop', doc['rel9Prop']),
              phoneKey: 'val_rel9Phone',
              phoneVal: val('val_rel9Phone', doc['rel9Phone']),
            ),
          ],
        );
      },
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 2 — ITEMS 10 TO 12 (Grandparents & Father)
  // ══════════════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            buildRelativeBlock(
              number: '10.',
              titleKey: 'lbl_rel10_title',
              nameKey: 'val_rel10Name',
              nameVal: val('val_rel10Name', doc['rel10Name']),
              occKey: 'val_rel10Occ',
              occVal: val('val_rel10Occ', doc['rel10Occ']),
              currAddrKey: 'val_rel10CurrAddr',
              currAddrVal: val('val_rel10CurrAddr', doc['rel10CurrAddr']),
              currTalKey: 'val_rel10CurrTal',
              currTalVal: val('val_rel10CurrTal', doc['rel10CurrTal']),
              currDistKey: 'val_rel10CurrDist',
              currDistVal: val('val_rel10CurrDist', doc['rel10CurrDist']),
              currStateKey: 'val_rel10CurrState',
              currStateVal: val('val_rel10CurrState', doc['rel10CurrState']),
              permAddrKey: 'val_rel10PermAddr',
              permAddrVal: val('val_rel10PermAddr', doc['rel10PermAddr']),
              permTalKey: 'val_rel10PermTal',
              permTalVal: val('val_rel10PermTal', doc['rel10PermTal']),
              permDistKey: 'val_rel10PermDist',
              permDistVal: val('val_rel10PermDist', doc['rel10PermDist']),
              permStateKey: 'val_rel10PermState',
              permStateVal: val('val_rel10PermState', doc['rel10PermState']),
              propKey: 'val_rel10Prop',
              propVal: val('val_rel10Prop', doc['rel10Prop']),
              phoneKey: 'val_rel10Phone',
              phoneVal: val('val_rel10Phone', doc['rel10Phone']),
            ),
            pw.SizedBox(height: 10),

            buildRelativeBlock(
              number: '11.',
              titleKey: 'lbl_rel11_title',
              nameKey: 'val_rel11Name',
              nameVal: val('val_rel11Name', doc['rel11Name']),
              occKey: 'val_rel11Occ',
              occVal: val('val_rel11Occ', doc['rel11Occ']),
              currAddrKey: 'val_rel11CurrAddr',
              currAddrVal: val('val_rel11CurrAddr', doc['rel11CurrAddr']),
              currTalKey: 'val_rel11CurrTal',
              currTalVal: val('val_rel11CurrTal', doc['rel11CurrTal']),
              currDistKey: 'val_rel11CurrDist',
              currDistVal: val('val_rel11CurrDist', doc['rel11CurrDist']),
              currStateKey: 'val_rel11CurrState',
              currStateVal: val('val_rel11CurrState', doc['rel11CurrState']),
              permAddrKey: 'val_rel11PermAddr',
              permAddrVal: val('val_rel11PermAddr', doc['rel11PermAddr']),
              permTalKey: 'val_rel11PermTal',
              permTalVal: val('val_rel11PermTal', doc['rel11PermTal']),
              permDistKey: 'val_rel11PermDist',
              permDistVal: val('val_rel11PermDist', doc['rel11PermDist']),
              permStateKey: 'val_rel11PermState',
              permStateVal: val('val_rel11PermState', doc['rel11PermState']),
              propKey: 'val_rel11Prop',
              propVal: val('val_rel11Prop', doc['rel11Prop']),
              phoneKey: 'val_rel11Phone',
              phoneVal: val('val_rel11Phone', doc['rel11Phone']),
            ),
            pw.SizedBox(height: 10),

            buildRelativeBlock(
              number: '12.',
              titleKey: 'lbl_rel12_title',
              nameKey: 'val_rel12Name',
              nameVal: val('val_rel12Name', doc['rel12Name']),
              occKey: 'val_rel12Occ',
              occVal: val('val_rel12Occ', doc['rel12Occ']),
              currAddrKey: 'val_rel12CurrAddr',
              currAddrVal: val('val_rel12CurrAddr', doc['rel12CurrAddr']),
              currTalKey: 'val_rel12CurrTal',
              currTalVal: val('val_rel12CurrTal', doc['rel12CurrTal']),
              currDistKey: 'val_rel12CurrDist',
              currDistVal: val('val_rel12CurrDist', doc['rel12CurrDist']),
              currStateKey: 'val_rel12CurrState',
              currStateVal: val('val_rel12CurrState', doc['rel12CurrState']),
              permAddrKey: 'val_rel12PermAddr',
              permAddrVal: val('val_rel12PermAddr', doc['rel12PermAddr']),
              permTalKey: 'val_rel12PermTal',
              permTalVal: val('val_rel12PermTal', doc['rel12PermTal']),
              permDistKey: 'val_rel12PermDist',
              permDistVal: val('val_rel12PermDist', doc['rel12PermDist']),
              permStateKey: 'val_rel12PermState',
              permStateVal: val('val_rel12PermState', doc['rel12PermState']),
              propKey: 'val_rel12Prop',
              propVal: val('val_rel12Prop', doc['rel12Prop']),
              phoneKey: 'val_rel12Phone',
              phoneVal: val('val_rel12Phone', doc['rel12Phone']),
            ),
          ],
        );
      },
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 3 — ITEMS 13 TO 16 (Siblings)
  // ══════════════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            buildRelativeBlock(
              number: '13.',
              titleKey: 'lbl_rel13_title',
              nameKey: 'val_rel13Name',
              nameVal: val('val_rel13Name', doc['rel13Name']),
              occKey: 'val_rel13Occ',
              occVal: val('val_rel13Occ', doc['rel13Occ']),
              currAddrKey: 'val_rel13CurrAddr',
              currAddrVal: val('val_rel13CurrAddr', doc['rel13CurrAddr']),
              currTalKey: 'val_rel13CurrTal',
              currTalVal: val('val_rel13CurrTal', doc['rel13CurrTal']),
              currDistKey: 'val_rel13CurrDist',
              currDistVal: val('val_rel13CurrDist', doc['rel13CurrDist']),
              currStateKey: 'val_rel13CurrState',
              currStateVal: val('val_rel13CurrState', doc['rel13CurrState']),
              permAddrKey: 'val_rel13PermAddr',
              permAddrVal: val('val_rel13PermAddr', doc['rel13PermAddr']),
              permTalKey: 'val_rel13PermTal',
              permTalVal: val('val_rel13PermTal', doc['rel13PermTal']),
              permDistKey: 'val_rel13PermDist',
              permDistVal: val('val_rel13PermDist', doc['rel13PermDist']),
              permStateKey: 'val_rel13PermState',
              permStateVal: val('val_rel13PermState', doc['rel13PermState']),
              propKey: 'val_rel13Prop',
              propVal: val('val_rel13Prop', doc['rel13Prop']),
              phoneKey: 'val_rel13Phone',
              phoneVal: val('val_rel13Phone', doc['rel13Phone']),
            ),
            pw.SizedBox(height: 8),

            buildRelativeBlock(
              number: '14.',
              titleKey: 'lbl_rel14_title',
              nameKey: 'val_rel14Name',
              nameVal: val('val_rel14Name', doc['rel14Name']),
              occKey: 'val_rel14Occ',
              occVal: val('val_rel14Occ', doc['rel14Occ']),
              currAddrKey: 'val_rel14CurrAddr',
              currAddrVal: val('val_rel14CurrAddr', doc['rel14CurrAddr']),
              currTalKey: 'val_rel14CurrTal',
              currTalVal: val('val_rel14CurrTal', doc['rel14CurrTal']),
              currDistKey: 'val_rel14CurrDist',
              currDistVal: val('val_rel14CurrDist', doc['rel14CurrDist']),
              currStateKey: 'val_rel14CurrState',
              currStateVal: val('val_rel14CurrState', doc['rel14CurrState']),
              permAddrKey: 'val_rel14PermAddr',
              permAddrVal: val('val_rel14PermAddr', doc['rel14PermAddr']),
              permTalKey: 'val_rel14PermTal',
              permTalVal: val('val_rel14PermTal', doc['rel14PermTal']),
              permDistKey: 'val_rel14PermDist',
              permDistVal: val('val_rel14PermDist', doc['rel14PermDist']),
              permStateKey: 'val_rel14PermState',
              permStateVal: val('val_rel14PermState', doc['rel14PermState']),
              propKey: 'val_rel14Prop',
              propVal: val('val_rel14Prop', doc['rel14Prop']),
              phoneKey: 'val_rel14Phone',
              phoneVal: val('val_rel14Phone', doc['rel14Phone']),
            ),
            pw.SizedBox(height: 8),

            buildRelativeBlock(
              number: '15.',
              titleKey: 'lbl_rel15_title',
              nameKey: 'val_rel15Name',
              nameVal: val('val_rel15Name', doc['rel15Name']),
              occKey: 'val_rel15Occ',
              occVal: val('val_rel15Occ', doc['rel15Occ']),
              currAddrKey: 'val_rel15CurrAddr',
              currAddrVal: val('val_rel15CurrAddr', doc['rel15CurrAddr']),
              currTalKey: 'val_rel15CurrTal',
              currTalVal: val('val_rel15CurrTal', doc['rel15CurrTal']),
              currDistKey: 'val_rel15CurrDist',
              currDistVal: val('val_rel15CurrDist', doc['rel15CurrDist']),
              currStateKey: 'val_rel15CurrState',
              currStateVal: val('val_rel15CurrState', doc['rel15CurrState']),
              permAddrKey: 'val_rel15PermAddr',
              permAddrVal: val('val_rel15PermAddr', doc['rel15PermAddr']),
              permTalKey: 'val_rel15PermTal',
              permTalVal: val('val_rel15PermTal', doc['rel15PermTal']),
              permDistKey: 'val_rel15PermDist',
              permDistVal: val('val_rel15PermDist', doc['rel15PermDist']),
              permStateKey: 'val_rel15PermState',
              permStateVal: val('val_rel15PermState', doc['rel15PermState']),
              propKey: 'val_rel15Prop',
              propVal: val('val_rel15Prop', doc['rel15Prop']),
              phoneKey: 'val_rel15Phone',
              phoneVal: val('val_rel15Phone', doc['rel15Phone']),
            ),
            pw.SizedBox(height: 8),

            buildRelativeBlock(
              number: '16.',
              titleKey: 'lbl_rel16_title',
              nameKey: 'val_rel16Name',
              nameVal: val('val_rel16Name', doc['rel16Name']),
              occKey: 'val_rel16Occ',
              occVal: val('val_rel16Occ', doc['rel16Occ']),
              currAddrKey: 'val_rel16CurrAddr',
              currAddrVal: val('val_rel16CurrAddr', doc['rel16CurrAddr']),
              currTalKey: 'val_rel16CurrTal',
              currTalVal: val('val_rel16CurrTal', doc['rel16CurrTal']),
              currDistKey: 'val_rel16CurrDist',
              currDistVal: val('val_rel16CurrDist', doc['rel16CurrDist']),
              currStateKey: 'val_rel16CurrState',
              currStateVal: val('val_rel16CurrState', doc['rel16CurrState']),
              permAddrKey: 'val_rel16PermAddr',
              permAddrVal: val('val_rel16PermAddr', doc['rel16PermAddr']),
              permTalKey: 'val_rel16PermTal',
              permTalVal: val('val_rel16PermTal', doc['rel16PermTal']),
              permDistKey: 'val_rel16PermDist',
              permDistVal: val('val_rel16PermDist', doc['rel16PermDist']),
              permStateKey: 'val_rel16PermState',
              permStateVal: val('val_rel16PermState', doc['rel16PermState']),
              propKey: 'val_rel16Prop',
              propVal: val('val_rel16Prop', doc['rel16Prop']),
              phoneKey: 'val_rel16Phone',
              phoneVal: val('val_rel16Phone', doc['rel16Phone']),
            ),
          ],
        );
      },
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 4 — ITEMS 17 TO 19 (Wife, Second Wife, Father-in-law)
  // ══════════════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            buildRelativeBlock(
              number: '17.',
              titleKey: 'lbl_rel17_title',
              nameKey: 'val_rel17Name',
              nameVal: val('val_rel17Name', doc['rel17Name']),
              occKey: 'val_rel17Occ',
              occVal: val('val_rel17Occ', doc['rel17Occ']),
              currAddrKey: 'val_rel17CurrAddr',
              currAddrVal: val('val_rel17CurrAddr', doc['rel17CurrAddr']),
              currTalKey: 'val_rel17CurrTal',
              currTalVal: val('val_rel17CurrTal', doc['rel17CurrTal']),
              currDistKey: 'val_rel17CurrDist',
              currDistVal: val('val_rel17CurrDist', doc['rel17CurrDist']),
              currStateKey: 'val_rel17CurrState',
              currStateVal: val('val_rel17CurrState', doc['rel17CurrState']),
              permAddrKey: 'val_rel17PermAddr',
              permAddrVal: val('val_rel17PermAddr', doc['rel17PermAddr']),
              permTalKey: 'val_rel17PermTal',
              permTalVal: val('val_rel17PermTal', doc['rel17PermTal']),
              permDistKey: 'val_rel17PermDist',
              permDistVal: val('val_rel17PermDist', doc['rel17PermDist']),
              permStateKey: 'val_rel17PermState',
              permStateVal: val('val_rel17PermState', doc['rel17PermState']),
              propKey: 'val_rel17Prop',
              propVal: val('val_rel17Prop', doc['rel17Prop']),
              phoneKey: 'val_rel17Phone',
              phoneVal: val('val_rel17Phone', doc['rel17Phone']),
            ),
            pw.SizedBox(height: 10),

            buildRelativeBlock(
              number: '18.',
              titleKey: 'lbl_rel18_title',
              nameKey: 'val_rel18Name',
              nameVal: val('val_rel18Name', doc['rel18Name']),
              occKey: 'val_rel18Occ',
              occVal: val('val_rel18Occ', doc['rel18Occ']),
              currAddrKey: 'val_rel18CurrAddr',
              currAddrVal: val('val_rel18CurrAddr', doc['rel18CurrAddr']),
              currTalKey: 'val_rel18CurrTal',
              currTalVal: val('val_rel18CurrTal', doc['rel18CurrTal']),
              currDistKey: 'val_rel18CurrDist',
              currDistVal: val('val_rel18CurrDist', doc['rel18CurrDist']),
              currStateKey: 'val_rel18CurrState',
              currStateVal: val('val_rel18CurrState', doc['rel18CurrState']),
              permAddrKey: 'val_rel18PermAddr',
              permAddrVal: val('val_rel18PermAddr', doc['rel18PermAddr']),
              permTalKey: 'val_rel18PermTal',
              permTalVal: val('val_rel18PermTal', doc['rel18PermTal']),
              permDistKey: 'val_rel18PermDist',
              permDistVal: val('val_rel18PermDist', doc['rel18PermDist']),
              permStateKey: 'val_rel18PermState',
              permStateVal: val('val_rel18PermState', doc['rel18PermState']),
              propKey: 'val_rel18Prop',
              propVal: val('val_rel18Prop', doc['rel18Prop']),
              phoneKey: 'val_rel18Phone',
              phoneVal: val('val_rel18Phone', doc['rel18Phone']),
            ),
            pw.SizedBox(height: 10),

            buildRelativeBlock(
              number: '19.',
              titleKey: 'lbl_rel19_title',
              nameKey: 'val_rel19Name',
              nameVal: val('val_rel19Name', doc['rel19Name']),
              occKey: 'val_rel19Occ',
              occVal: val('val_rel19Occ', doc['rel19Occ']),
              currAddrKey: 'val_rel19CurrAddr',
              currAddrVal: val('val_rel19CurrAddr', doc['rel19CurrAddr']),
              currTalKey: 'val_rel19CurrTal',
              currTalVal: val('val_rel19CurrTal', doc['rel19CurrTal']),
              currDistKey: 'val_rel19CurrDist',
              currDistVal: val('val_rel19CurrDist', doc['rel19CurrDist']),
              currStateKey: 'val_rel19CurrState',
              currStateVal: val('val_rel19CurrState', doc['rel19CurrState']),
              permAddrKey: 'val_rel19PermAddr',
              permAddrVal: val('val_rel19PermAddr', doc['rel19PermAddr']),
              permTalKey: 'val_rel19PermTal',
              permTalVal: val('val_rel19PermTal', doc['rel19PermTal']),
              permDistKey: 'val_rel19PermDist',
              permDistVal: val('val_rel19PermDist', doc['rel19PermDist']),
              permStateKey: 'val_rel19PermState',
              permStateVal: val('val_rel19PermState', doc['rel19PermState']),
              propKey: 'val_rel19Prop',
              propVal: val('val_rel19Prop', doc['rel19Prop']),
              phoneKey: 'val_rel19Phone',
              phoneVal: val('val_rel19Phone', doc['rel19Phone']),
            ),
          ],
        );
      },
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 5 — ITEMS 20 TO 23 (Children)
  // ══════════════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            buildRelativeBlock(
              number: '20.',
              titleKey: 'lbl_rel20_title',
              nameKey: 'val_rel20Name',
              nameVal: val('val_rel20Name', doc['rel20Name']),
              occKey: 'val_rel20Occ',
              occVal: val('val_rel20Occ', doc['rel20Occ']),
              currAddrKey: 'val_rel20CurrAddr',
              currAddrVal: val('val_rel20CurrAddr', doc['rel20CurrAddr']),
              currTalKey: 'val_rel20CurrTal',
              currTalVal: val('val_rel20CurrTal', doc['rel20CurrTal']),
              currDistKey: 'val_rel20CurrDist',
              currDistVal: val('val_rel20CurrDist', doc['rel20CurrDist']),
              currStateKey: 'val_rel20CurrState',
              currStateVal: val('val_rel20CurrState', doc['rel20CurrState']),
              permAddrKey: 'val_rel20PermAddr',
              permAddrVal: val('val_rel20PermAddr', doc['rel20PermAddr']),
              permTalKey: 'val_rel20PermTal',
              permTalVal: val('val_rel20PermTal', doc['rel20PermTal']),
              permDistKey: 'val_rel20PermDist',
              permDistVal: val('val_rel20PermDist', doc['rel20PermDist']),
              permStateKey: 'val_rel20PermState',
              permStateVal: val('val_rel20PermState', doc['rel20PermState']),
              propKey: 'val_rel20Prop',
              propVal: val('val_rel20Prop', doc['rel20Prop']),
              phoneKey: 'val_rel20Phone',
              phoneVal: val('val_rel20Phone', doc['rel20Phone']),
            ),
            pw.SizedBox(height: 8),

            buildRelativeBlock(
              number: '21.',
              titleKey: 'lbl_rel21_title',
              nameKey: 'val_rel21Name',
              nameVal: val('val_rel21Name', doc['rel21Name']),
              occKey: 'val_rel21Occ',
              occVal: val('val_rel21Occ', doc['rel21Occ']),
              currAddrKey: 'val_rel21CurrAddr',
              currAddrVal: val('val_rel21CurrAddr', doc['rel21CurrAddr']),
              currTalKey: 'val_rel21CurrTal',
              currTalVal: val('val_rel21CurrTal', doc['rel21CurrTal']),
              currDistKey: 'val_rel21CurrDist',
              currDistVal: val('val_rel21CurrDist', doc['rel21CurrDist']),
              currStateKey: 'val_rel21CurrState',
              currStateVal: val('val_rel21CurrState', doc['rel21CurrState']),
              permAddrKey: 'val_rel21PermAddr',
              permAddrVal: val('val_rel21PermAddr', doc['rel21PermAddr']),
              permTalKey: 'val_rel21PermTal',
              permTalVal: val('val_rel21PermTal', doc['rel21PermTal']),
              permDistKey: 'val_rel21PermDist',
              permDistVal: val('val_rel21PermDist', doc['rel21PermDist']),
              permStateKey: 'val_rel21PermState',
              permStateVal: val('val_rel21PermState', doc['rel21PermState']),
              propKey: 'val_rel21Prop',
              propVal: val('val_rel21Prop', doc['rel21Prop']),
              phoneKey: 'val_rel21Phone',
              phoneVal: val('val_rel21Phone', doc['rel21Phone']),
            ),
            pw.SizedBox(height: 8),

            buildRelativeBlock(
              number: '22.',
              titleKey: 'lbl_rel22_title',
              nameKey: 'val_rel22Name',
              nameVal: val('val_rel22Name', doc['rel22Name']),
              occKey: 'val_rel22Occ',
              occVal: val('val_rel22Occ', doc['rel22Occ']),
              currAddrKey: 'val_rel22CurrAddr',
              currAddrVal: val('val_rel22CurrAddr', doc['rel22CurrAddr']),
              currTalKey: 'val_rel22CurrTal',
              currTalVal: val('val_rel22CurrTal', doc['rel22CurrTal']),
              currDistKey: 'val_rel22CurrDist',
              currDistVal: val('val_rel22CurrDist', doc['rel22CurrDist']),
              currStateKey: 'val_rel22CurrState',
              currStateVal: val('val_rel22CurrState', doc['rel22CurrState']),
              permAddrKey: 'val_rel22PermAddr',
              permAddrVal: val('val_rel22PermAddr', doc['rel22PermAddr']),
              permTalKey: 'val_rel22PermTal',
              permTalVal: val('val_rel22PermTal', doc['rel22PermTal']),
              permDistKey: 'val_rel22PermDist',
              permDistVal: val('val_rel22PermDist', doc['rel22PermDist']),
              permStateKey: 'val_rel22PermState',
              permStateVal: val('val_rel22PermState', doc['rel22PermState']),
              propKey: 'val_rel22Prop',
              propVal: val('val_rel22Prop', doc['rel22Prop']),
              phoneKey: 'val_rel22Phone',
              phoneVal: val('val_rel22Phone', doc['rel22Phone']),
            ),
            pw.SizedBox(height: 8),

            buildRelativeBlock(
              number: '23.',
              titleKey: 'lbl_rel23_title',
              nameKey: 'val_rel23Name',
              nameVal: val('val_rel23Name', doc['rel23Name']),
              occKey: 'val_rel23Occ',
              occVal: val('val_rel23Occ', doc['rel23Occ']),
              currAddrKey: 'val_rel23CurrAddr',
              currAddrVal: val('val_rel23CurrAddr', doc['rel23CurrAddr']),
              currTalKey: 'val_rel23CurrTal',
              currTalVal: val('val_rel23CurrTal', doc['rel23CurrTal']),
              currDistKey: 'val_rel23CurrDist',
              currDistVal: val('val_rel23CurrDist', doc['rel23CurrDist']),
              currStateKey: 'val_rel23CurrState',
              currStateVal: val('val_rel23CurrState', doc['rel23CurrState']),
              permAddrKey: 'val_rel23PermAddr',
              permAddrVal: val('val_rel23PermAddr', doc['rel23PermAddr']),
              permTalKey: 'val_rel23PermTal',
              permTalVal: val('val_rel23PermTal', doc['rel23PermTal']),
              permDistKey: 'val_rel23PermDist',
              permDistVal: val('val_rel23PermDist', doc['rel23PermDist']),
              permStateKey: 'val_rel23PermState',
              permStateVal: val('val_rel23PermState', doc['rel23PermState']),
              propKey: 'val_rel23Prop',
              propVal: val('val_rel23Prop', doc['rel23Prop']),
              phoneKey: 'val_rel23Phone',
              phoneVal: val('val_rel23Phone', doc['rel23Phone']),
            ),
            pw.SizedBox(height: 12),

            pw.Align(
              alignment: pw.Alignment.bottomRight,
              child: pw.Text('M.R.W', style: englishBold),
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
    'hdr_title': '-:: अटक आरोपीचा इंट्रोगेशन फॉर्म ::-',
    'hdr_subtitle': '(संपुर्ण वैयक्तीक माहिती)',
    'lbl_ps': 'पोलीस स्टेशन',
    'lbl_crime_sec': 'अप.क्रमांक व कलम',
    'lbl_accused_name': 'आरोपीचे संपुर्ण नांव',
    'lbl_alias': 'आरोपीचे टोपण नांव',
    'lbl_occ': 'धंदा',
    'lbl_prop': 'स्थावर/ जंगम मालमत्ता',
    'lbl_farm_house': 'शेती, घर व वाहन',
    'lbl_phone_other': 'फोन नंबर व इतर माहिती',
    'lbl_curr_addr_full': 'आरोपीचा संपूर्ण पत्ता व राज्य',
    'lbl_perm_addr_full': 'आरोपीचा मुळ गांवचा संपूर्ण पत्ता व राज्य',
    'lbl_ra': 'रा.',
    'lbl_ta': 'ता',
    'lbl_dist': 'जिल्हा',
    'lbl_state': 'राज्य',
    'lbl_desc': 'आरोपीचे वर्णन',
    'lbl_desc_color': 'रंग— ',
    'lbl_desc_height': 'उंच— ',
    'lbl_desc_caste': 'जात— ',
    'lbl_desc_deform': 'व्यंग— ',
    'lbl_desc_teeth': 'दात— ',
    'lbl_desc_hair': 'केस— ',
    'lbl_desc_eyes': 'डोळे— ',
    'lbl_desc_dress': 'पोषख— ',
    'lbl_desc_voter': 'मतदार यादिलीत नांव— ',
    'lbl_desc_boil': 'फोड— ',
    'lbl_desc_mole': 'तिळ— ',
    'lbl_desc_tattoo': 'गोदने— ',
    'lbl_desc_ears': 'कान— ',
    'lbl_desc_nose': 'नाक— ',
    'lbl_desc_mustache': 'मिशी— ',
    'lbl_desc_face': 'चेहरा— ',
    'lbl_desc_lang': 'भाषा— ',
    'lbl_desc_dob': 'जन्म तारीख— ',
    'lbl_desc_complexion': 'वर्ण— ',
    'lbl_desc_burn': 'भाजल्याच्या खुणा— ',
    'lbl_desc_main_id': 'मुख्य ओळख चिन्ह: ',
    'lbl_birth_place': 'आरोपीचे जन्म ठिकाण',

    'lbl_curr_addr': 'ह.मुक्काम संपुर्ण पत्ता',
    'lbl_perm_addr': 'मुळ गावचा संपुर्ण पत्ता',

    'lbl_rel9_title': 'आरोपीच्या आईचे संपुर्ण नांव',
    'lbl_rel10_title': 'आईचे वडीलांचे संपुर्ण नांव',
    'lbl_rel11_title': 'आरोपीच्या वडीलांचे संपुर्ण नांव',
    'lbl_rel12_title': 'आरोपीच्या वडीलांचे वडील यांचे संपुर्ण नांव (आजा)',
    'lbl_rel13_title': 'आरोपीच्या भावाचे संपुर्ण नांव',
    'lbl_rel14_title': 'आरोपीच्या भावाचे संपुर्ण नांव',
    'lbl_rel15_title': 'आरोपीच्या बहिणीचे संपुर्ण नांव',
    'lbl_rel16_title': 'आरोपीच्या बहिणीचे संपुर्ण नांव',
    'lbl_rel17_title': 'आरोपीच्या पत्नीचे संपुर्ण नांव',
    'lbl_rel18_title': 'आरोपीच्या दुसऱ्या पत्नीचे संपुर्ण नांव',
    'lbl_rel19_title': 'आरोपीच्या सासऱ्याचे संपुर्ण नांव',
    'lbl_rel20_title': 'आरोपीच्या मुलाचे संपुर्ण नांव',
    'lbl_rel21_title': 'आरोपीच्या मुलाचे संपुर्ण नांव',
    'lbl_rel22_title': 'आरोपीच्या मुलाचे संपुर्ण नांव',
    'lbl_rel23_title': 'आरोपीच्या मुलीचे संपुर्ण नांव',
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
    'lbl_ps',
    'lbl_crime_sec',
    'lbl_accused_name',
    'lbl_alias',
    'lbl_occ',
    'lbl_prop',
    'lbl_farm_house',
    'lbl_phone_other',
    'lbl_curr_addr_full',
    'lbl_perm_addr_full',
    'lbl_ra',
    'lbl_ta',
    'lbl_dist',
    'lbl_state',
    'lbl_desc',
    'lbl_birth_place',
    'lbl_curr_addr',
    'lbl_perm_addr',
    'lbl_rel9_title',
    'lbl_rel10_title',
    'lbl_rel11_title',
    'lbl_rel12_title',
    'lbl_rel13_title',
    'lbl_rel14_title',
    'lbl_rel15_title',
    'lbl_rel16_title',
    'lbl_rel17_title',
    'lbl_rel18_title',
    'lbl_rel19_title',
    'lbl_rel20_title',
    'lbl_rel21_title',
    'lbl_rel22_title',
    'lbl_rel23_title',
  };

  final cache = MarathiImageCache();
  await GoogleFonts.pendingFonts();

  for (final entry in pairs.entries) {
    final isBold = boldKeys.contains(entry.key);
    final double fs = entry.key == 'hdr_title'
        ? 13.0
        : (entry.key == 'hdr_subtitle' ? 10.5 : 8.5);
    final color = entry.key.startsWith('val_') ? const Color(0xFF0D47A1) : Colors.black87;

    await cache.add(
      entry.key,
      entry.value,
      GoogleFonts.notoSansDevanagari(
        fontSize: fs,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        color: color,
      ),
      maxWidth: entry.key == 'hdr_title' || entry.key == 'hdr_subtitle' ? 500 : 350,
    );
  }

  return cache;
}
