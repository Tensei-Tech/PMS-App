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

  pw.Widget tableCell(String valKey, String? value,
      {pw.Alignment alignment = pw.Alignment.centerLeft}) {
    return pw.Container(
      alignment: alignment,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: renderText(valKey, value, valueStyle),
    );
  }

  pw.Widget tableHeader(String text,
      {pw.Alignment alignment = pw.Alignment.center}) {
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

  pw.Widget buildDescRow({
    required String lKey,
    required String vKey1,
    required String? vVal1,
    required String rKey,
    required String vKey2,
    required String? vVal2,
  }) {
    return pw.Row(
      children: [
        mLbl(lKey),
        pw.Expanded(child: tableCell(vKey1, vVal1)),
        mLbl(rKey),
        pw.Expanded(child: tableCell(vKey2, vVal2)),
      ],
    );
  }

  pw.Widget buildRelativeBlock({
    required int itemNum,
    required String titleKey,
    bool hasAccompliceRelation = false,
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
            tableCell('val_rel${num}Name',
                val('val_rel${num}Name', doc['rel${num}Name'])),
          ],
        ),
        pw.TableRow(
          children: [
            pw.SizedBox(),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: mLbl('lbl_occ'),
            ),
            tableCell('val_rel${num}Occ',
                val('val_rel${num}Occ', doc['rel${num}Occ'])),
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
              stateVal:
                  val('val_rel${num}CurrState', doc['rel${num}CurrState']),
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
              stateVal:
                  val('val_rel${num}PermState', doc['rel${num}PermState']),
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
            tableCell('val_rel${num}Prop',
                val('val_rel${num}Prop', doc['rel${num}Prop'])),
          ],
        ),
        pw.TableRow(
          children: [
            pw.SizedBox(),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: mLbl('lbl_phone_other'),
            ),
            tableCell('val_rel${num}Phone',
                val('val_rel${num}Phone', doc['rel${num}Phone'])),
          ],
        ),
        if (hasAccompliceRelation)
          pw.TableRow(
            children: [
              pw.SizedBox(),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: mLbl('lbl_accomplice_relation'),
              ),
              tableCell('val_rel${num}Relation',
                  val('val_rel${num}Relation', doc['rel${num}Relation'])),
            ],
          ),
      ],
    );
  }

  pw.TableRow buildSimplePdfRow(String num, String labelKey, String docKey) {
    return pw.TableRow(
      children: [
        tableHeader(num),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: mLbl(labelKey),
        ),
        tableCell('val_$docKey', val('val_$docKey', doc[docKey])),
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
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: mLbl('lbl_ps')),
                    tableCell('val_ps',
                        val('val_ps', doc['ps'] ?? doc['policeStation'])),
                  ],
                ),
                pw.TableRow(
                  children: [
                    tableHeader('2.'),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: mLbl('lbl_crime_sec')),
                    tableCell(
                        'val_crimeNoSection',
                        val('val_crimeNoSection',
                            doc['crimeNoSection'] ?? doc['crimeNo'])),
                  ],
                ),
                pw.TableRow(
                  children: [
                    tableHeader('3.'),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: mLbl('lbl_accused_name')),
                    tableCell(
                        'val_accusedFullName',
                        val('val_accusedFullName',
                            doc['accusedFullName'] ?? doc['accusedName'])),
                  ],
                ),
                pw.TableRow(
                  children: [
                    tableHeader('4.'),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: mLbl('lbl_alias')),
                    tableCell('val_accusedAlias',
                        val('val_accusedAlias', doc['accusedAlias'])),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.SizedBox(),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: mLbl('lbl_occ')),
                    tableCell('val_accusedOccupation',
                        val('val_accusedOccupation', doc['accusedOccupation'])),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.SizedBox(),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: mLbl('lbl_prop')),
                    tableCell('val_accusedProperty',
                        val('val_accusedProperty', doc['accusedProperty'])),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.SizedBox(),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: mLbl('lbl_farm_house')),
                    tableCell(
                        'val_accusedFarmHouseVehicle',
                        val('val_accusedFarmHouseVehicle',
                            doc['accusedFarmHouseVehicle'])),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.SizedBox(),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: mLbl('lbl_phone_other')),
                    tableCell('val_accusedPhoneOther',
                        val('val_accusedPhoneOther', doc['accusedPhoneOther'])),
                  ],
                ),
                pw.TableRow(
                  children: [
                    tableHeader('5.'),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: mLbl('lbl_curr_addr_full')),
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
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: mLbl('lbl_perm_addr_full')),
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
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: mLbl('lbl_desc')),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Column(
                        children: [
                          buildDescRow(
                              lKey: 'lbl_desc_color',
                              vKey1: 'val_descColor',
                              vVal1: val('val_descColor', doc['descColor']),
                              rKey: 'lbl_desc_height',
                              vKey2: 'val_descHeight',
                              vVal2: val('val_descHeight', doc['descHeight'])),
                          buildDescRow(
                              lKey: 'lbl_desc_caste',
                              vKey1: 'val_descCaste',
                              vVal1: val('val_descCaste', doc['descCaste']),
                              rKey: 'lbl_desc_deform',
                              vKey2: 'val_descDeformity',
                              vVal2: val(
                                  'val_descDeformity', doc['descDeformity'])),
                          buildDescRow(
                              lKey: 'lbl_desc_teeth',
                              vKey1: 'val_descTeeth',
                              vVal1: val('val_descTeeth', doc['descTeeth']),
                              rKey: 'lbl_desc_hair',
                              vKey2: 'val_descHair',
                              vVal2: val('val_descHair', doc['descHair'])),
                          buildDescRow(
                              lKey: 'lbl_desc_eyes',
                              vKey1: 'val_descEyes',
                              vVal1: val('val_descEyes', doc['descEyes']),
                              rKey: 'lbl_desc_dress',
                              vKey2: 'val_descDress',
                              vVal2: val('val_descDress', doc['descDress'])),
                          buildDescRow(
                              lKey: 'lbl_desc_voter',
                              vKey1: 'val_descVoterName',
                              vVal1: val(
                                  'val_descVoterName', doc['descVoterName']),
                              rKey: 'lbl_desc_boil',
                              vKey2: 'val_descBoil',
                              vVal2: val('val_descBoil', doc['descBoil'])),
                          buildDescRow(
                              lKey: 'lbl_desc_mole',
                              vKey1: 'val_descMole',
                              vVal1: val('val_descMole', doc['descMole']),
                              rKey: 'lbl_desc_tattoo',
                              vKey2: 'val_descTattoo',
                              vVal2: val('val_descTattoo', doc['descTattoo'])),
                          buildDescRow(
                              lKey: 'lbl_desc_ears',
                              vKey1: 'val_descEars',
                              vVal1: val('val_descEars', doc['descEars']),
                              rKey: 'lbl_desc_nose',
                              vKey2: 'val_descNose',
                              vVal2: val('val_descNose', doc['descNose'])),
                          buildDescRow(
                              lKey: 'lbl_desc_mustache',
                              vKey1: 'val_descMustache',
                              vVal1:
                                  val('val_descMustache', doc['descMustache']),
                              rKey: 'lbl_desc_face',
                              vKey2: 'val_descFace',
                              vVal2: val('val_descFace', doc['descFace'])),
                          buildDescRow(
                              lKey: 'lbl_desc_lang',
                              vKey1: 'val_descLanguage',
                              vVal1:
                                  val('val_descLanguage', doc['descLanguage']),
                              rKey: 'lbl_desc_dob',
                              vKey2: 'val_descDob',
                              vVal2: val('val_descDob', doc['descDob'])),
                          buildDescRow(
                              lKey: 'lbl_desc_complexion',
                              vKey1: 'val_descComplexion',
                              vVal1: val(
                                  'val_descComplexion', doc['descComplexion']),
                              rKey: 'lbl_desc_burn',
                              vKey2: 'val_descBurnMarks',
                              vVal2: val(
                                  'val_descBurnMarks', doc['descBurnMarks'])),
                          pw.Row(
                            children: [
                              mLbl('lbl_desc_main_id'),
                              pw.Expanded(
                                  child: renderText(
                                      'val_descMainIdMark',
                                      val('val_descMainIdMark',
                                          doc['descMainIdMark']),
                                      valueStyle)),
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
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: mLbl('lbl_birth_place')),
                    tableCell('val_accusedBirthPlace',
                        val('val_accusedBirthPlace', doc['accusedBirthPlace'])),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 6),
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
            pw.SizedBox(height: 8),
            buildRelativeBlock(itemNum: 11, titleKey: 'lbl_rel11_title'),
            pw.SizedBox(height: 8),
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
            pw.SizedBox(height: 8),
            buildRelativeBlock(itemNum: 18, titleKey: 'lbl_rel18_title'),
            pw.SizedBox(height: 8),
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
          ],
        );
      },
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 11 — ITEMS 44 TO 47 (Aatya & Close Friends / जिवलग मित्र)
  // ══════════════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            buildRelativeBlock(itemNum: 44, titleKey: 'lbl_rel44_title'),
            pw.SizedBox(height: 8),
            buildRelativeBlock(itemNum: 45, titleKey: 'lbl_rel45_title'),
            pw.SizedBox(height: 8),
            buildRelativeBlock(itemNum: 46, titleKey: 'lbl_rel46_title'),
            pw.SizedBox(height: 8),
            buildRelativeBlock(itemNum: 47, titleKey: 'lbl_rel47_title'),
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

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 12 — ITEMS 48 TO 56 (Friend, Education, Employment & Stay)
  // ══════════════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            buildRelativeBlock(itemNum: 48, titleKey: 'lbl_rel48_title'),
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
                  children: [
                    tableHeader('49.'),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: mLbl('lbl_edu')),
                    tableCell('val_edu', val('val_edu', doc['edu'])),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.SizedBox(),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: mLbl('lbl_edu_last_year')),
                    tableCell('val_eduLastYear',
                        val('val_eduLastYear', doc['eduLastYear'])),
                  ],
                ),
                buildSimplePdfRow(
                    '50.', 'lbl_school_name_addr', 'schoolNameAddr'),
                pw.TableRow(
                  children: [
                    tableHeader('51.'),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: mLbl('lbl_job_office')),
                    tableCell('val_jobOfficeName',
                        val('val_jobOfficeName', doc['jobOfficeName'])),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.SizedBox(),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: mLbl('lbl_job_salary')),
                    tableCell('val_jobSalary',
                        val('val_jobSalary', doc['jobSalary'])),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.SizedBox(),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: mLbl('lbl_job_duration')),
                    tableCell('val_jobDuration',
                        val('val_jobDuration', doc['jobDuration'])),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.SizedBox(),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: mLbl('lbl_job_stay_addr')),
                    tableCell('val_jobStayAddr',
                        val('val_jobStayAddr', doc['jobStayAddr'])),
                  ],
                ),
                pw.TableRow(
                  children: [
                    tableHeader('52.'),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: mLbl('lbl_prev_job_office')),
                    tableCell('val_prevJobOffice',
                        val('val_prevJobOffice', doc['prevJobOffice'])),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.SizedBox(),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: mLbl('lbl_prev_job_reason')),
                    tableCell(
                        'val_prevJobLeaveReason',
                        val('val_prevJobLeaveReason',
                            doc['prevJobLeaveReason'])),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.SizedBox(),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: mLbl('lbl_prev_job_duration')),
                    tableCell('val_prevJobDuration',
                        val('val_prevJobDuration', doc['prevJobDuration'])),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.SizedBox(),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: mLbl('lbl_prev_job_stay_addr')),
                    tableCell('val_prevJobStayAddr',
                        val('val_prevJobStayAddr', doc['prevJobStayAddr'])),
                  ],
                ),
                buildSimplePdfRow('53.', 'lbl_current_stay_duration_addr',
                    'currentStayDurationAddr'),
                buildSimplePdfRow('54.', 'lbl_prev_stay_addr', 'prevStayAddr'),
                buildSimplePdfRow(
                    '55.', 'lbl_bank_account', 'bankAccountDetails'),
                buildSimplePdfRow('56.', 'lbl_habits', 'habits'),
              ],
            ),
          ],
        );
      },
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 13 — ITEMS 57 TO 73 (Crime Details & Modus Operandi)
  // ══════════════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
              columnWidths: const {
                0: pw.FixedColumnWidth(28),
                1: pw.FlexColumnWidth(1.8),
                2: pw.FlexColumnWidth(4.2),
              },
              children: [
                buildSimplePdfRow('57.', 'lbl_alcohol_place', 'alcoholPlace'),
                buildSimplePdfRow('58.', 'lbl_prostitute_mistress',
                    'prostituteMistressDetails'),
                buildSimplePdfRow('59.', 'lbl_crime_motive', 'crimeMotive'),
                buildSimplePdfRow('60.', 'lbl_first_crime_accomplices',
                    'firstCrimeAccomplices'),
                buildSimplePdfRow('61.', 'lbl_prev_arrest_circumstances',
                    'prevArrestCircumstances'),
                buildSimplePdfRow(
                    '62.', 'lbl_prev_arrest_ps', 'prevArrestPoliceStations'),
                buildSimplePdfRow(
                    '63.', 'lbl_prev_arrest_crimes', 'prevArrestCrimeDetails'),
                buildSimplePdfRow(
                    '64.', 'lbl_bail_surety', 'bailSuretyNameAddrNative'),
                buildSimplePdfRow('65.', 'lbl_lawyer', 'advocateNameAddr'),
                buildSimplePdfRow(
                    '66.', 'lbl_conviction_status', 'convictionStatus'),
                buildSimplePdfRow(
                    '67.', 'lbl_conviction_duration', 'convictionDurationJail'),
                buildSimplePdfRow('68.', 'lbl_mo', 'modusOperandi'),
                buildSimplePdfRow('69.', 'lbl_recce_method', 'recceMethod'),
                buildSimplePdfRow('70.', 'lbl_informer', 'informerNameAddr'),
                buildSimplePdfRow('71.', 'lbl_rendezvous', 'rendezvousPlace'),
                buildSimplePdfRow('72.', 'lbl_solo', 'soloCrime'),
                buildSimplePdfRow('73.', 'lbl_gang', 'groupCrime'),
              ],
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

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 14 — ITEMS 74 TO 77 (Accomplices 1–4)
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
                itemNum: 74,
                titleKey: 'lbl_rel74_title',
                hasAccompliceRelation: true),
            pw.SizedBox(height: 8),
            buildRelativeBlock(
                itemNum: 75,
                titleKey: 'lbl_rel75_title',
                hasAccompliceRelation: true),
            pw.SizedBox(height: 8),
            buildRelativeBlock(
                itemNum: 76,
                titleKey: 'lbl_rel76_title',
                hasAccompliceRelation: true),
            pw.SizedBox(height: 8),
            buildRelativeBlock(
                itemNum: 77,
                titleKey: 'lbl_rel77_title',
                hasAccompliceRelation: true),
          ],
        );
      },
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 15 — ITEMS 78 TO 83 (Accomplices 5–6 & Gang/Travel info)
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
                itemNum: 78,
                titleKey: 'lbl_rel78_title',
                hasAccompliceRelation: true),
            pw.SizedBox(height: 8),
            buildRelativeBlock(
                itemNum: 79,
                titleKey: 'lbl_rel79_title',
                hasAccompliceRelation: true),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
              columnWidths: const {
                0: pw.FixedColumnWidth(28),
                1: pw.FlexColumnWidth(1.8),
                2: pw.FlexColumnWidth(4.2),
              },
              children: [
                buildSimplePdfRow('80.', 'lbl_fav_spot', 'favoriteCrimePlace'),
                buildSimplePdfRow('81.', 'lbl_gang_leader', 'gangLeaderName'),
                buildSimplePdfRow(
                    '82.', 'lbl_transit_to', 'travelToCrimeMethod'),
                buildSimplePdfRow(
                    '83.', 'lbl_transit_from', 'travelFromCrimeMethod'),
              ],
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

  pw.TableRow buildPdfFeatureRow(
      String k1, String lbl1, String k2, String lbl2) {
    final bool val1 = doc[k1] == true || doc[k1] == 'true';
    final bool val2 = doc[k2] == true || doc[k2] == 'true';
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
          child: pw.Row(
            children: [
              pw.Container(
                width: 8,
                height: 8,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 0.8),
                ),
                child: val1
                    ? pw.Center(
                        child: pw.Text('X',
                            style: pw.TextStyle(
                                fontSize: 6, fontWeight: pw.FontWeight.bold)),
                      )
                    : null,
              ),
              pw.SizedBox(width: 4),
              pw.Expanded(child: mLbl(lbl1)),
            ],
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
          child: pw.Row(
            children: [
              pw.Container(
                width: 8,
                height: 8,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 0.8),
                ),
                child: val2
                    ? pw.Center(
                        child: pw.Text('X',
                            style: pw.TextStyle(
                                fontSize: 6, fontWeight: pw.FontWeight.bold)),
                      )
                    : null,
              ),
              pw.SizedBox(width: 4),
              pw.Expanded(child: mLbl(lbl2)),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 16 — ITEMS 84 TO 93 (Weapons, Disposal, Features & Prep)
  // ══════════════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
              columnWidths: const {
                0: pw.FixedColumnWidth(28),
                1: pw.FlexColumnWidth(1.8),
                2: pw.FlexColumnWidth(4.2),
              },
              children: [
                buildSimplePdfRow(
                    '84.', 'lbl_weapons_vehicles', 'weaponsVehiclesUsed'),
                buildSimplePdfRow(
                    '85.', 'lbl_booty_distribution', 'bootyDistribution'),
                buildSimplePdfRow('86.', 'lbl_money_disposal', 'moneyDisposal'),
                buildSimplePdfRow(
                    '87.', 'lbl_valuables_disposal', 'valuablesDisposal'),
                pw.TableRow(
                  children: [
                    tableHeader('88.'),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: mLbl('lbl_features_header'),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(2),
                      child: pw.Table(
                        border: pw.TableBorder.all(
                            color: PdfColors.black, width: 0.5),
                        columnWidths: const {
                          0: pw.FlexColumnWidth(1),
                          1: pw.FlexColumnWidth(1),
                        },
                        children: [
                          buildPdfFeatureRow('feat_defecate', 'feat_defecate',
                              'feat_rape', 'feat_rape'),
                          buildPdfFeatureRow('feat_cook', 'feat_cook',
                              'feat_smoke_spit', 'feat_smoke_spit'),
                          buildPdfFeatureRow(
                              'feat_spray',
                              'feat_spray',
                              'feat_brought_weapon_assault',
                              'feat_brought_weapon_assault'),
                          buildPdfFeatureRow(
                              'feat_tie_victims',
                              'feat_tie_victims',
                              'feat_spot_weapon_assault',
                              'feat_spot_weapon_assault'),
                          buildPdfFeatureRow(
                              'feat_latch_neighbors',
                              'feat_latch_neighbors',
                              'feat_mask_handkerchief',
                              'feat_mask_handkerchief'),
                          buildPdfFeatureRow(
                              'feat_impersonate_police',
                              'feat_impersonate_police',
                              'feat_half_pant_baniyan',
                              'feat_half_pant_baniyan'),
                          buildPdfFeatureRow(
                              'feat_theft_with_inhabitants',
                              'feat_theft_with_inhabitants',
                              'feat_theft_locked_house',
                              'feat_theft_locked_house'),
                          buildPdfFeatureRow(
                              'feat_wall_hole_theft',
                              'feat_wall_hole_theft',
                              'feat_intercept_motorcycle',
                              'feat_intercept_motorcycle'),
                          buildPdfFeatureRow(
                              'feat_target_follow',
                              'feat_target_follow',
                              'feat_rope_across_road',
                              'feat_rope_across_road'),
                        ],
                      ),
                    ),
                  ],
                ),
                buildSimplePdfRow(
                    '89.', 'lbl_escape_routes', 'escapeRoutesTogetherOrApart'),
                buildSimplePdfRow(
                    '90.', 'lbl_police_arrival_plan', 'policeArrivalPlan'),
                buildSimplePdfRow(
                    '91.', 'lbl_people_wake_plan', 'peopleWakePlan'),
                buildSimplePdfRow(
                    '92.', 'lbl_resistance_plan', 'resistancePlan'),
                buildSimplePdfRow('93.', 'lbl_crime_language', 'crimeLanguage'),
              ],
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

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 17 — ITEMS 94 TO 101 (Rivals, Past Crimes & Signatures)
  // ══════════════════════════════════════════════════════════════════════════
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
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
                    tableHeader('94.'),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: mLbl('lbl_rival_accomplices'),
                    ),
                    pw.Column(
                      children: [
                        for (int i = 0; i < 5; i++)
                          pw.Container(
                            decoration: i < 4
                                ? const pw.BoxDecoration(
                                    border: pw.Border(
                                      bottom: pw.BorderSide(
                                          color: PdfColors.black, width: 0.5),
                                    ),
                                  )
                                : null,
                            child: pw.Row(
                              children: [
                                pw.Container(
                                  width: 20,
                                  alignment: pw.Alignment.center,
                                  padding: const pw.EdgeInsets.symmetric(
                                      vertical: 2),
                                  child: mLbl('lbl_dev_num_${i + 1}'),
                                ),
                                pw.Container(
                                    width: 0.5,
                                    height: 16,
                                    color: PdfColors.black),
                                pw.Expanded(
                                  child: tableCell(
                                    'val_rivalAccompliceReason${i + 1}',
                                    val('val_rivalAccompliceReason${i + 1}',
                                        doc['rivalAccompliceReason${i + 1}']),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                buildSimplePdfRow('95.', 'lbl_gang_merger', 'gangMerger'),
                buildSimplePdfRow(
                    '96.', 'lbl_rival_gang_dispute', 'rivalGangDisputeReason'),
                buildSimplePdfRow('97.', 'lbl_injured_accomplice_plan',
                    'injuredAccomplicePlan'),
                buildSimplePdfRow('98.', 'lbl_arrested_accomplice_plan',
                    'arrestedAccompliceReleasePlan'),
                buildSimplePdfRow(
                    '99.', 'lbl_favorable_season', 'favorableSeasonReason'),
                buildSimplePdfRow('100.', 'lbl_officers_recognizing',
                    'officersRecognizingCriminal'),
              ],
            ),
            pw.SizedBox(height: 8),

            // Item 101 Heading
            mLbl('lbl_past_crimes_title'),
            pw.SizedBox(height: 4),

            // Item 101 Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
              columnWidths: const {
                0: pw.FixedColumnWidth(24),
                1: pw.FlexColumnWidth(1.8),
                2: pw.FlexColumnWidth(1.8),
                3: pw.FlexColumnWidth(2.0),
                4: pw.FlexColumnWidth(2.8),
              },
              children: [
                pw.TableRow(
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: mLbl('lbl_tbl_sr')),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: mLbl('lbl_tbl_place')),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: mLbl('lbl_tbl_datetime')),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: mLbl('lbl_tbl_goods')),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: mLbl('lbl_tbl_accomplices')),
                  ],
                ),
                for (int i = 0; i < 10; i++)
                  pw.TableRow(
                    children: [
                      tableHeader('${i + 1}.'),
                      tableCell(
                          'val_pastCrimePlace${i + 1}',
                          val('val_pastCrimePlace${i + 1}',
                              doc['pastCrimePlace${i + 1}'])),
                      tableCell(
                          'val_pastCrimeDateTime${i + 1}',
                          val('val_pastCrimeDateTime${i + 1}',
                              doc['pastCrimeDateTime${i + 1}'])),
                      tableCell(
                          'val_pastCrimeGoods${i + 1}',
                          val('val_pastCrimeGoods${i + 1}',
                              doc['pastCrimeGoods${i + 1}'])),
                      tableCell(
                          'val_pastCrimeAccomplices${i + 1}',
                          val('val_pastCrimeAccomplices${i + 1}',
                              doc['pastCrimeAccomplices${i + 1}'])),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 8),

            // Note
            mLbl('lbl_footer_note'),
            pw.SizedBox(height: 16),

            // Investigating Officer Signature
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    tableCell(
                        'val_investigatingOfficerNameSign',
                        val('val_investigatingOfficerNameSign',
                            doc['investigatingOfficerNameSign'])),
                    pw.SizedBox(height: 2),
                    mLbl('lbl_investigating_officer'),
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
    'lbl_rel44_title': 'आरोपीच्या आत्याचे संपुर्ण नांव',
    'lbl_rel45_title': 'आरोपीच्या जिवलग मित्राचे संपुर्ण नांव',
    'lbl_rel46_title': 'आरोपीच्या जिवलग मित्राचे संपुर्ण नांव',
    'lbl_rel47_title': 'आरोपीच्या जिवलग मित्राचे संपुर्ण नांव',
    'lbl_rel48_title': 'आरोपीच्या जिवलग मित्राचे संपुर्ण नांव',
    'lbl_rel74_title': 'आरोपीच्या साथीदाराचे संपुर्ण नांव व पत्ता',
    'lbl_rel75_title': 'आरोपीच्या साथीदाराचे संपुर्ण नांव व पत्ता',
    'lbl_rel76_title': 'आरोपीच्या साथीदाराचे संपुर्ण नांव व पत्ता',
    'lbl_rel77_title': 'आरोपीच्या साथीदाराचे संपुर्ण नांव व पत्ता',
    'lbl_rel78_title': 'आरोपीच्या साथीदाराचे संपुर्ण नांव व पत्ता',
    'lbl_rel79_title': 'आरोपीच्या साथीदाराचे संपुर्ण नांव व पत्ता',
    'lbl_accomplice_relation': 'आरोपीचे साथीदाराशी नाते व संबंध',
    'lbl_edu': 'आरोपीचे शिक्षण',
    'lbl_edu_last_year': 'शेवटचे शैक्षणीक वर्ष',
    'lbl_school_name_addr': 'कोणत्या शाळेत शिकला त्याचे नांव व पत्ता',
    'lbl_job_office':
        'नोकरी असल्यास खाजगी मालकाचे किंवा सरकारी कार्यालयाचे संपुर्ण नांव',
    'lbl_job_salary': 'मिळणारा मासीक पगार',
    'lbl_job_duration': 'नोकरी केव्हा पासुन आहे नोकरीचा कालावधी',
    'lbl_job_stay_addr': 'नोकरी असतांना राहण्याचा पत्ता',
    'lbl_prev_job_office':
        'त्यापुर्वी नोकरीच्या मालकाचे / कार्यालयाचे नांव व पत्ता',
    'lbl_prev_job_reason': 'नोकरी सोडल्याचे कारण',
    'lbl_prev_job_duration': 'नोकरीचा कालावधी',
    'lbl_prev_job_stay_addr': 'नोकरीवर असतांना राहण्याचा पत्ता',
    'lbl_current_stay_duration_addr':
        'सध्या राहत असलेल्या जागी केव्हा पासुन राहत आहे त्या जागेचा पत्ता',
    'lbl_prev_stay_addr': 'पुर्वी राहत असलेल्या जागेचा पत्ता',
    'lbl_bank_account': 'बँक खाते आहे काय असल्यास बँकेचे नांव पत्ता',
    'lbl_habits': 'सवयी',
    'lbl_alcohol_place': 'नेहमी दारू पिण्याचे ठिकाण',
    'lbl_prostitute_mistress':
        'धंदेवाईक बाई/ रखेल/ प्रेयसी चे संपुर्ण नांव व पत्ता',
    'lbl_crime_motive': 'गुन्ह्यात प्रवृत्त होण्याचे कारण',
    'lbl_first_crime_accomplices': 'प्रथम केलेला गुन्हा व त्यातील साथीदार',
    'lbl_prev_arrest_circumstances':
        'पुर्वी अटक झाली आहे काय ? कुठल्या परिस्थितीत अटक झाली आहे.',
    'lbl_prev_arrest_ps': 'कोण कोणत्या पोलीस स्टेशनला अटक होता',
    'lbl_prev_arrest_crimes': 'कोण कोणत्या गुन्ह्यात अटक होता.',
    'lbl_bail_surety':
        'गुन्ह्यात जामीन घेणाऱ्या जामीनदारांचे नांव व संपुर्ण पत्ता मुळ गावासह',
    'lbl_lawyer': 'गुन्ह्यात लावलेल्या वकीलाचे नांव व पत्ता',
    'lbl_conviction_status': 'शिक्षा झाली आहे काय ?',
    'lbl_conviction_duration': 'शिक्षेचा कालावधी व कोणत्या कारागृहात',
    'lbl_mo': 'गुन्हा करण्याची पध्दत',
    'lbl_recce_method': 'गुन्हा करण्यापुर्वी जागेची माहिती कशी काढतो ?',
    'lbl_informer': 'बातमीदार मार्फत माहिती काढत असल्यास त्याचे नांव व पत्ता',
    'lbl_rendezvous':
        'गुन्हा करण्या अगोदर व केल्यानंतर आरोपींचे एकत्र जमण्याचे ठिकाण',
    'lbl_solo': 'गुन्हा एकटा करतो काय ?',
    'lbl_gang': 'साथीदारासह गुन्हा करतो काय ?',
    'lbl_fav_spot': 'गुन्हा करण्यासाठी जास्त आवडीचे ठिकाण',
    'lbl_gang_leader': 'गुन्हा करणाऱ्या टोळीतील सुत्रधाराचे नांव',
    'lbl_transit_to': 'गुन्हा करण्यासाठी जातांना प्रवास कशाने करतात',
    'lbl_transit_from': 'गुन्हा करून परत जातांना प्रवास कशाने करतात',
    'lbl_weapons_vehicles': 'गुन्ह्यात कोणत्या हत्याराचा व वाहनाचा वापर करतात',
    'lbl_booty_distribution':
        'गुन्ह्यात मिळालेल्या मुद्देमालाची वाटणी कोठे व कशी करतात.',
    'lbl_money_disposal': 'गुन्ह्यात मिळालेल्या पैश्याची विल्हेवाट',
    'lbl_valuables_disposal':
        'गुन्ह्यात मिळालेल्या मौल्यवान वस्तुंची विल्हेवाट चांदी/ सोने व इतर वस्तु',
    'lbl_features_header': 'गुन्ह्याचे वैशिष्टये लागे असल्यास मार्क करणे',
    'feat_defecate': 'घटनास्थळी संडास करणे',
    'feat_rape': 'घटनास्थळी स्त्रि /मुलीवर बलात्कार करणे',
    'feat_cook': 'स्वयंपाक करण्यास लावणे',
    'feat_smoke_spit': 'घटनास्थळी बीडी सिगारेट पिणे थुंकने',
    'feat_spray': 'फिर्यादीचे चेहऱ्यावर स्प्रे मारणे',
    'feat_brought_weapon_assault': 'सोबत आणलेल्या हत्याराने मारहाण करणे',
    'feat_tie_victims': 'घरातील लोकांना बांधुन ठेवणे',
    'feat_spot_weapon_assault': 'घटनास्थळावरील हत्यार घेवुन मारहाण करणे',
    'feat_latch_neighbors': 'शेजारच्या घरांना कड्या लावणे',
    'feat_mask_handkerchief': 'चेहऱ्यावर रूमाल बांधुन गुन्हा करणे',
    'feat_impersonate_police': 'पोलीस असल्याची बतावणी करणे',
    'feat_half_pant_baniyan': 'गुन्हा करतांना हाफ पॅन्ट व बनियान वापरणे',
    'feat_theft_with_inhabitants': 'घरात लोक असतांना चोरी करणे',
    'feat_theft_locked_house': 'घराला कुलुप असतांना चोरी करणे',
    'feat_wall_hole_theft': 'भिंतीला छिद्र पाडुन चोरी करणे',
    'feat_intercept_motorcycle': 'वाहनास मोटार सायकलवर येऊन अडवीणे',
    'feat_target_follow': 'सावज हेरून गुन्हा पाठलाग करणे',
    'feat_rope_across_road': 'दोर आडवा लावुन मोटार सायकल अडविणे',
    'lbl_escape_routes':
        'गुन्ह्याचे घटनास्थळा पासुन साथीदारांसह एकत्र जातात की वेगवेगळ्या दिशेने जातात',
    'lbl_police_arrival_plan': 'गुन्हा करतेवेळी पोलीस आल्यास कुठली तयारी असते',
    'lbl_people_wake_plan': 'गुन्हा करतांना लोक जागे झाल्यास कोणती तयारी असते',
    'lbl_resistance_plan': 'गुन्ह्यात लोकांनी प्रतिकार केल्यास कोणी तयारी असते',
    'lbl_crime_language': 'गुन्हा करतांना वापरावयाची भाषा',
    'lbl_rival_accomplices':
        'विरोधाकाचे व साथीदार यांचे नांव व पत्ता व विरोध करण्याचे त्याचे कारण',
    'lbl_dev_num_1': '१',
    'lbl_dev_num_2': '२',
    'lbl_dev_num_3': '३',
    'lbl_dev_num_4': '४',
    'lbl_dev_num_5': '५',
    'lbl_gang_merger': 'गुन्हा करतांना दोन टोळ्या एकत्र होतात काय',
    'lbl_rival_gang_dispute':
        'दुसऱ्या टोळी बरोबर वाद आहे काय असल्यास वादाचे कारण',
    'lbl_injured_accomplice_plan':
        'गुन्ह्यात एखादा साथीदार जखमी असल्यास कोणती तयारी असते',
    'lbl_arrested_accomplice_plan':
        'गुन्ह्यात एखादा साथीदार अटक झाल्यास त्याला कोणत्या पध्दतीने सोडवितात',
    'lbl_favorable_season':
        'कुठल्या हंगामात गुन्हा करण्याचे सोईचे जाते त्याचे कारण काय',
    'lbl_officers_recognizing':
        'गुन्हेगाराला ओळखणारे अधिकारी व कर्मचारी यांचे नांव व मो नं',
    'lbl_past_crimes_title':
        '101 आज पावेतो किती गुन्हे केले आहे त्याचे वर्णन :—',
    'lbl_tbl_sr': 'अ.क्र',
    'lbl_tbl_place': 'ठिकाण',
    'lbl_tbl_datetime': 'दिनांक व वेळ',
    'lbl_tbl_goods': 'मिळाला माल',
    'lbl_tbl_accomplices': 'साथीदारांचे नांव व माहिती',
    'lbl_footer_note':
        'टिप :— सावत्र आई किंवा इतर विशेष माहिती असल्यास त्याचे करीता पुरवणी कागद वापरावा',
    'lbl_investigating_officer': 'तपासी अधिकारी नांव व सही',
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
    for (int i = 9; i <= 48; i++) 'lbl_rel${i}_title',
    for (int i = 74; i <= 79; i++) 'lbl_rel${i}_title',
    'lbl_accomplice_relation',
    'lbl_edu',
    'lbl_edu_last_year',
    'lbl_school_name_addr',
    'lbl_job_office',
    'lbl_job_salary',
    'lbl_job_duration',
    'lbl_job_stay_addr',
    'lbl_prev_job_office',
    'lbl_prev_job_reason',
    'lbl_prev_job_duration',
    'lbl_prev_job_stay_addr',
    'lbl_current_stay_duration_addr',
    'lbl_prev_stay_addr',
    'lbl_bank_account',
    'lbl_habits',
    'lbl_alcohol_place',
    'lbl_prostitute_mistress',
    'lbl_crime_motive',
    'lbl_first_crime_accomplices',
    'lbl_prev_arrest_circumstances',
    'lbl_prev_arrest_ps',
    'lbl_prev_arrest_crimes',
    'lbl_bail_surety',
    'lbl_lawyer',
    'lbl_conviction_status',
    'lbl_conviction_duration',
    'lbl_mo',
    'lbl_recce_method',
    'lbl_informer',
    'lbl_rendezvous',
    'lbl_solo',
    'lbl_gang',
    'lbl_fav_spot',
    'lbl_gang_leader',
    'lbl_transit_to',
    'lbl_transit_from',
    'lbl_weapons_vehicles',
    'lbl_booty_distribution',
    'lbl_money_disposal',
    'lbl_valuables_disposal',
    'lbl_features_header',
    'lbl_escape_routes',
    'lbl_police_arrival_plan',
    'lbl_people_wake_plan',
    'lbl_resistance_plan',
    'lbl_crime_language',
    'lbl_rival_accomplices',
    'lbl_gang_merger',
    'lbl_rival_gang_dispute',
    'lbl_injured_accomplice_plan',
    'lbl_arrested_accomplice_plan',
    'lbl_favorable_season',
    'lbl_officers_recognizing',
    'lbl_past_crimes_title',
    'lbl_tbl_sr',
    'lbl_tbl_place',
    'lbl_tbl_datetime',
    'lbl_tbl_goods',
    'lbl_tbl_accomplices',
    'lbl_investigating_officer',
  };

  final cache = MarathiImageCache();
  await GoogleFonts.pendingFonts();

  for (final entry in pairs.entries) {
    final isBold = boldKeys.contains(entry.key);
    final double fs =
        entry.key == 'hdr_title' || entry.key == 'lbl_past_crimes_title'
            ? 12.0
            : (entry.key == 'hdr_subtitle' ? 10.5 : 8.0);
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
              entry.key == 'lbl_past_crimes_title'
          ? 500
          : 350,
    );
  }

  return cache;
}
