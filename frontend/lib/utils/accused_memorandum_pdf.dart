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
    required int itemNum,
    required String titleKey,
  }) {
    final num = itemNum;
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
            tableHeader('$num.'),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: mLbl(titleKey),
            ),
            tableCell('val_rel${num}Name', val('val_rel${num}Name', doc['rel${num}Name'])),
          ],
        ),
        pw.TableRow(
          children: [
            pw.SizedBox(),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: mLbl('lbl_occ'),
            ),
            tableCell('val_rel${num}Occ', val('val_rel${num}Occ', doc['rel${num}Occ'])),
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
              resKey: 'val_rel${num}CurrAddr',
              resVal: val('val_rel${num}CurrAddr', doc['rel${num}CurrAddr']),
              talKey: 'val_rel${num}CurrTal',
              talVal: val('val_rel${num}CurrTal', doc['rel${num}CurrTal']),
              distKey: 'val_rel${num}CurrDist',
              distVal: val('val_rel${num}CurrDist', doc['rel${num}CurrDist']),
              stateKey: 'val_rel${num}CurrState',
              stateVal: val('val_rel${num}CurrState', doc['rel${num}CurrState']),
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
              resKey: 'val_rel${num}PermAddr',
              resVal: val('val_rel${num}PermAddr', doc['rel${num}PermAddr']),
              talKey: 'val_rel${num}PermTal',
              talVal: val('val_rel${num}PermTal', doc['rel${num}PermTal']),
              distKey: 'val_rel${num}PermDist',
              distVal: val('val_rel${num}PermDist', doc['rel${num}PermDist']),
              stateKey: 'val_rel${num}PermState',
              stateVal: val('val_rel${num}PermState', doc['rel${num}PermState']),
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
            tableCell('val_rel${num}Prop', val('val_rel${num}Prop', doc['rel${num}Prop'])),
          ],
        ),
        pw.TableRow(
          children: [
            pw.SizedBox(),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: mLbl('lbl_phone_other'),
            ),
            tableCell('val_rel${num}Phone', val('val_rel${num}Phone', doc['rel${num}Phone'])),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 1 — PARTICULARS & DESCRIPTION & MOTHER (Item 9)
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

            buildRelativeBlock(itemNum: 9, titleKey: 'lbl_rel9_title'),
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
            buildRelativeBlock(itemNum: 10, titleKey: 'lbl_rel10_title'),
            pw.SizedBox(height: 10),
            buildRelativeBlock(itemNum: 11, titleKey: 'lbl_rel11_title'),
            pw.SizedBox(height: 10),
            buildRelativeBlock(itemNum: 12, titleKey: 'lbl_rel12_title'),
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
            buildRelativeBlock(itemNum: 13, titleKey: 'lbl_rel13_title'),
            pw.SizedBox(height: 8),
            buildRelativeBlock(itemNum: 14, titleKey: 'lbl_rel14_title'),
            pw.SizedBox(height: 8),
            buildRelativeBlock(itemNum: 15, titleKey: 'lbl_rel15_title'),
            pw.SizedBox(height: 8),
            buildRelativeBlock(itemNum: 16, titleKey: 'lbl_rel16_title'),
          ],
        );
      },
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 4 — ITEMS 17 TO 19 (Spouse & In-Laws)
  // ══════════════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            buildRelativeBlock(itemNum: 17, titleKey: 'lbl_rel17_title'),
            pw.SizedBox(height: 10),
            buildRelativeBlock(itemNum: 18, titleKey: 'lbl_rel18_title'),
            pw.SizedBox(height: 10),
            buildRelativeBlock(itemNum: 19, titleKey: 'lbl_rel19_title'),
          ],
        );
      },
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 5 — ITEMS 20 TO 23 (Children Part 1)
  // ══════════════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            buildRelativeBlock(itemNum: 20, titleKey: 'lbl_rel20_title'),
            pw.SizedBox(height: 8),
            buildRelativeBlock(itemNum: 21, titleKey: 'lbl_rel21_title'),
            pw.SizedBox(height: 8),
            buildRelativeBlock(itemNum: 22, titleKey: 'lbl_rel22_title'),
            pw.SizedBox(height: 8),
            buildRelativeBlock(itemNum: 23, titleKey: 'lbl_rel23_title'),
          ],
        );
      },
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 6 — ITEMS 24 TO 27 (Daughters & Sisters-in-law)
  // ══════════════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            buildRelativeBlock(itemNum: 24, titleKey: 'lbl_rel24_title'),
            pw.SizedBox(height: 8),
            buildRelativeBlock(itemNum: 25, titleKey: 'lbl_rel25_title'),
            pw.SizedBox(height: 8),
            buildRelativeBlock(itemNum: 26, titleKey: 'lbl_rel26_title'),
            pw.SizedBox(height: 8),
            buildRelativeBlock(itemNum: 27, titleKey: 'lbl_rel27_title'),
          ],
        );
      },
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 7 — ITEMS 28 TO 31 (Sali & Sala)
  // ══════════════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            buildRelativeBlock(itemNum: 28, titleKey: 'lbl_rel28_title'),
            pw.SizedBox(height: 8),
            buildRelativeBlock(itemNum: 29, titleKey: 'lbl_rel29_title'),
            pw.SizedBox(height: 8),
            buildRelativeBlock(itemNum: 30, titleKey: 'lbl_rel30_title'),
            pw.SizedBox(height: 8),
            buildRelativeBlock(itemNum: 31, titleKey: 'lbl_rel31_title'),
          ],
        );
      },
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 8 — ITEMS 32 TO 35 (Maternal Uncles — Mama)
  // ══════════════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            buildRelativeBlock(itemNum: 32, titleKey: 'lbl_rel32_title'),
            pw.SizedBox(height: 8),
            buildRelativeBlock(itemNum: 33, titleKey: 'lbl_rel33_title'),
            pw.SizedBox(height: 8),
            buildRelativeBlock(itemNum: 34, titleKey: 'lbl_rel34_title'),
            pw.SizedBox(height: 8),
            buildRelativeBlock(itemNum: 35, titleKey: 'lbl_rel35_title'),
          ],
        );
      },
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 9 — ITEMS 36 TO 39 (Maternal Aunts — Mavashi & Paternal Uncle — Kaka)
  // ══════════════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            buildRelativeBlock(itemNum: 36, titleKey: 'lbl_rel36_title'),
            pw.SizedBox(height: 8),
            buildRelativeBlock(itemNum: 37, titleKey: 'lbl_rel37_title'),
            pw.SizedBox(height: 8),
            buildRelativeBlock(itemNum: 38, titleKey: 'lbl_rel38_title'),
            pw.SizedBox(height: 8),
            buildRelativeBlock(itemNum: 39, titleKey: 'lbl_rel39_title'),
          ],
        );
      },
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 10 — ITEMS 40 TO 43 (Kaka & Aatya)
  // ══════════════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            buildRelativeBlock(itemNum: 40, titleKey: 'lbl_rel40_title'),
            pw.SizedBox(height: 8),
            buildRelativeBlock(itemNum: 41, titleKey: 'lbl_rel41_title'),
            pw.SizedBox(height: 8),
            buildRelativeBlock(itemNum: 42, titleKey: 'lbl_rel42_title'),
            pw.SizedBox(height: 8),
            buildRelativeBlock(itemNum: 43, titleKey: 'lbl_rel43_title'),
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
    'lbl_rel24_title': 'आरोपीच्या मुलीचे संपुर्ण नांव',
    'lbl_rel25_title': 'आरोपीच्या मुलीचे संपुर्ण नांव',
    'lbl_rel26_title': 'आरोपीच्या सालीचे संपुर्ण नांव (बायकोच्या बहिणीचे)',
    'lbl_rel27_title': 'आरोपीच्या सालीचे संपुर्ण नांव (बायकोच्या बहिणीचे)',
    'lbl_rel28_title': 'आरोपीच्या सालीचे संपुर्ण नांव (बायकोच्या बहिणीचे)',
    'lbl_rel29_title': 'आरोपीच्या साळयाचे संपुर्ण नांव (बायकोच्या भावाचे)',
    'lbl_rel30_title': 'आरोपीच्या साळयाचे संपुर्ण नांव (बायकोच्या भावाचे)',
    'lbl_rel31_title': 'आरोपीच्या साळयाचे संपुर्ण नांव (बायकोच्या भावाचे)',
    'lbl_rel32_title': 'आरोपीच्या मामाचे संपुर्ण नांव',
    'lbl_rel33_title': 'आरोपीच्या मामाचे संपुर्ण नांव',
    'lbl_rel34_title': 'आरोपीच्या मामाचे संपुर्ण नांव',
    'lbl_rel35_title': 'आरोपीच्या मामाचे संपुर्ण नांव',
    'lbl_rel36_title': 'आरोपीच्या मावशीचे संपुर्ण नांव',
    'lbl_rel37_title': 'आरोपीच्या मावशीचे संपुर्ण नांव',
    'lbl_rel38_title': 'आरोपीच्या मावशीचे संपुर्ण नांव',
    'lbl_rel39_title': 'आरोपीच्या काकाचे संपुर्ण नांव',
    'lbl_rel40_title': 'आरोपीच्या काकाचे संपुर्ण नांव',
    'lbl_rel41_title': 'आरोपीच्या काकाचे संपुर्ण नांव',
    'lbl_rel42_title': 'आरोपीच्या आत्याचे संपुर्ण नांव',
    'lbl_rel43_title': 'आरोपीच्या आत्याचे संपुर्ण नांव',
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
    for (int i = 9; i <= 43; i++) 'lbl_rel${i}_title',
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
