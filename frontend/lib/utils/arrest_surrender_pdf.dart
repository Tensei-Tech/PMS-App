import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart';
import 'marathi_text_renderer.dart';
import 'form_io_terminology.dart';
import 'pdf_font_cache.dart';
import '../widgets/form_section_utils.dart';

Future<void> previewArrestSurrenderPdf(
  BuildContext context,
  Map<String, dynamic> doc,
) async {
  final bytes = await generateArrestSurrenderPdf(doc);
  if (!context.mounted) return;
  final fileName =
      'Arrest_Court_Surrender_Form_${DateTime.now().millisecondsSinceEpoch}.pdf';
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

Future<Uint8List> generateArrestSurrenderPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();

  // Load fonts from cache
  final loraRegular = await PdfFontCache.loraRegular();
  final loraBold = await PdfFontCache.loraBold();

  const knownSectionIds = {'Form 3-A', 'Form 3-B', 'Form 3-C'};
  final activeSection = doc['formSection']?.toString();

  bool showsSection(String sectionId) => showsFormSection(
        activeSection: activeSection,
        sectionId: sectionId,
        knownSectionIds: knownSectionIds,
      );

  // Pre-render Marathi text blocks for the active form only
  final cache = await _preRenderAllMarathi(doc, showsSection: showsSection);

  final pw.TextStyle englishStyle = pw.TextStyle(
    font: loraRegular,
    fontSize: 8,
    color: PdfColors.black,
  );

  final pw.TextStyle englishBold = pw.TextStyle(
    font: loraBold,
    fontSize: 8,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.black,
  );

  final pw.TextStyle headerEnglishStyle = pw.TextStyle(
    font: loraBold,
    fontSize: 13,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.black,
  );

  pw.Widget renderText(
    String key,
    String? val,
    pw.TextStyle engStyle, {
    double? maxWidth,
  }) {
    if (val == null || val.isEmpty) return pw.SizedBox();
    if (containsDevanagari(val)) {
      if (cache.has(key)) {
        return pw.Container(
          alignment: pw.Alignment.topLeft,
          child: cache.img(key, maxWidth: maxWidth),
        );
      }
    }
    return pw.Text(val, style: engStyle);
  }

  pw.Widget mLbl(String key, {double? width, double? maxWidth}) {
    if (cache.has(key)) return cache.img(key, width: width, maxWidth: maxWidth);
    return pw.SizedBox();
  }

  pw.Widget field(
    String labelText,
    String valKey,
    dynamic fallback, {
    double? width,
  }) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(labelText, style: englishBold),
        pw.Container(
          width: width,
          padding: const pw.EdgeInsets.only(left: 2, right: 2, bottom: 1),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
          ),
          child: renderText(
            valKey,
            fallback?.toString(),
            englishStyle,
            maxWidth: width,
          ),
        ),
      ],
    );
  }

  pw.Widget buildInlineFieldWithMLbl(
    String enLabel,
    String mKey,
    String valKey,
    dynamic fallback, {
    double? width,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(enLabel, style: englishBold),
            pw.Container(
              width: width,
              padding: const pw.EdgeInsets.only(left: 2, right: 2, bottom: 1),
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
              ),
              child: renderText(
                valKey,
                fallback?.toString(),
                englishStyle,
                maxWidth: width,
              ),
            ),
          ],
        ),
        if (mKey.isNotEmpty)
          mLbl(mKey, maxWidth: width != null ? width + 60 : 240),
      ],
    );
  }

  pw.Widget buildFlexibleFieldWithMLbl(
    String enLabel,
    String mKey,
    String valKey,
    dynamic fallback,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            if (enLabel.isNotEmpty) pw.Text(enLabel, style: englishBold),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.only(left: 2, right: 2, bottom: 1),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
                ),
                child: renderText(
                  valKey,
                  fallback?.toString(),
                  englishStyle,
                  maxWidth: 220,
                ),
              ),
            ),
          ],
        ),
        if (mKey.isNotEmpty) mLbl(mKey, maxWidth: 240),
      ],
    );
  }

  pw.Widget buildStackedFieldWithMLbl(
    String enLabel,
    String mKey,
    String valKey,
    dynamic fallback, {
    double? width,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(enLabel, style: englishBold),
        pw.SizedBox(height: 1),
        if (mKey.isNotEmpty) mLbl(mKey, maxWidth: width ?? 250),
        pw.SizedBox(height: 2),
        pw.Container(
          width: width,
          padding: const pw.EdgeInsets.only(left: 2, right: 2, bottom: 1),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
          ),
          child: renderText(
            valKey,
            fallback?.toString(),
            englishStyle,
            maxWidth: width ?? 250,
          ),
        ),
      ],
    );
  }

  pw.Widget check(
    String text,
    bool value, {
    bool isMarathi = false,
    String? mKey,
  }) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 10,
          height: 10,
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
          child: value
              ? pw.Center(
                  child: pw.Text('X', style: englishBold.copyWith(fontSize: 8)),
                )
              : pw.SizedBox(),
        ),
        pw.SizedBox(width: 4),
        isMarathi && mKey != null
            ? mLbl(mKey)
            : pw.Text(text, style: englishStyle),
      ],
    );
  }

  pw.Widget buildIncomeItem(
    bool value,
    String mKey,
  ) {
    return pw.Expanded(
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 10,
            height: 10,
            margin: const pw.EdgeInsets.only(top: 1.5),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
            child: value
                ? pw.Center(
                    child:
                        pw.Text('X', style: englishBold.copyWith(fontSize: 8)),
                  )
                : pw.SizedBox(),
          ),
          pw.SizedBox(width: 4),
          pw.Expanded(
            child: mLbl(mKey, maxWidth: 240),
          ),
        ],
      ),
    );
  }

  // --- PAGE 1 ---
  if (showsSection('Form 3-A')) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        build: (pw.Context context) {
          return [
            // Title
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'ARREST/COURT SURRENDER FORM',
                    style: headerEnglishStyle,
                  ),
                  pw.SizedBox(height: 1),
                  mLbl('title_m1'),
                  mLbl('title_m2'),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '(Separate Memo for each accused)',
                    style: englishBold.copyWith(fontSize: 7.5),
                  ),
                  mLbl('title_m3'),
                ],
              ),
            ),
            pw.SizedBox(height: 5),

            // 1
            pw.Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [
                buildInlineFieldWithMLbl(
                  '1.Dist.',
                  'lbl_dist',
                  'val_dist',
                  doc['dist'],
                  width: 55,
                ),
                buildInlineFieldWithMLbl(
                  'P.S.:',
                  'lbl_ps',
                  'val_ps',
                  doc['ps'],
                  width: 55,
                ),
                buildInlineFieldWithMLbl(
                  'FIR/Proceeding/G.D.No:',
                  'lbl_fir',
                  'val_fir',
                  doc['firNo'],
                  width: 55,
                ),
                buildInlineFieldWithMLbl(
                  'Year:-20',
                  'lbl_year',
                  'val_year',
                  doc['year'],
                  width: 30,
                ),
                buildInlineFieldWithMLbl(
                  'Date',
                  'lbl_date',
                  'val_date',
                  doc['date'],
                  width: 55,
                ),
              ],
            ),
            pw.SizedBox(height: 3),
            buildStackedFieldWithMLbl(
              'Alphanumeric Code of the Accused (Write A1 to A9 for the first 9 persons, B1 for 10 th person and so on).',
              'lbl_code',
              'val_code',
              doc['accusedCode'],
              width: double.infinity,
            ),
            pw.SizedBox(height: 4),

            // 2
            pw.Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [
                buildInlineFieldWithMLbl(
                  '2. Date, Time & place of Arrest/surrender :- Date',
                  'lbl_arr_date',
                  'val_arrDate',
                  doc['arrestDate'],
                  width: 55,
                ),
                buildInlineFieldWithMLbl(
                  'Time',
                  'lbl_arr_time',
                  'val_arrTime',
                  doc['arrestTime'],
                  width: 50,
                ),
                buildInlineFieldWithMLbl(
                  'G.D.No.',
                  'lbl_arr_gd',
                  'val_arrGd',
                  doc['arrestGdNo'],
                  width: 50,
                ),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [
                buildInlineFieldWithMLbl(
                  'Place of Arrest: - P.S.',
                  'lbl_arr_ps',
                  'val_arrPlace',
                  doc['arrestPlace'],
                  width: 90,
                ),
                buildInlineFieldWithMLbl(
                  'Dist.',
                  'lbl_arr_dist',
                  'val_arrDist',
                  doc['arrestDist'],
                  width: 70,
                ),
                buildInlineFieldWithMLbl(
                  'State.',
                  'lbl_arr_state',
                  'val_arrState',
                  doc['arrestState'],
                  width: 70,
                ),
              ],
            ),
            pw.SizedBox(height: 4),

            // 3
            buildStackedFieldWithMLbl(
              '3. Name of the Court ( if surrendered) :-',
              'lbl_court',
              'val_court',
              doc['courtName'],
              width: double.infinity,
            ),
            pw.SizedBox(height: 4),

            // 4
            buildStackedFieldWithMLbl(
              '4. Acts and sections:-',
              'lbl_acts',
              'val_acts',
              doc['actsSections'],
              width: double.infinity,
            ),
            pw.SizedBox(height: 4),

            // 5
            pw.Text(
              '5. Arrested and forward / Arrested and released on bail or PR bound / Arrested but released on anticipatory bail/ Arrested and remanded to police Custody / Surrender in court and bailed out / Surrender in court and sent to judicial Custody / Surrender in court and remanded to police custody (tie applicable potion).',
              style: englishBold.copyWith(fontSize: 7.5),
            ),
            mLbl('lbl_5_m1'),
            mLbl('lbl_5_m2'),
            pw.SizedBox(height: 2),
            pw.Wrap(
              spacing: 8,
              runSpacing: 2,
              children: [
                check(
                  'Arrested and forward',
                  doc['arrestedAndForwarded'] == true,
                ),
                check(
                  'Arrested and released on bail',
                  doc['arrestedAndBailed'] == true,
                ),
                check(
                  'Arrested but released on anticipatory bail',
                  doc['arrestedButAnticipatory'] == true,
                ),
                check(
                  'Arrested and remanded to police Custody',
                  doc['arrestedAndRemandedPolice'] == true,
                ),
                check(
                  'Surrender in court and bailed out',
                  doc['surrenderBailed'] == true,
                ),
                check(
                  'Surrender in court and sent to judicial Custody',
                  doc['surrenderJudicial'] == true,
                ),
                check(
                  'Surrender in court and remanded to police custody',
                  doc['surrenderPolice'] == true,
                ),
              ],
            ),
            pw.SizedBox(height: 4),

            // 6
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('6. Particulars of the Accused :-', style: englishBold),
                mLbl('lbl_6_title_m1'),
              ],
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  buildStackedFieldWithMLbl(
                    '(i) Name :',
                    'lbl_6i_m1',
                    'val_accName',
                    doc['accusedName'],
                    width: double.infinity,
                  ),
                  pw.SizedBox(height: 2),
                  buildStackedFieldWithMLbl(
                    '(ii)Father\'s/Husband\'s/Guardian\'s Name :',
                    'lbl_6ii_m1',
                    'val_accFather',
                    doc['accusedFather'],
                    width: double.infinity,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: buildStackedFieldWithMLbl(
                          '(iii)First Alias :',
                          'lbl_6iii_m1',
                          'val_accAlias1',
                          doc['accusedAlias1'],
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: buildStackedFieldWithMLbl(
                          '(iv)Second Alias :',
                          'lbl_6iv_m1',
                          'val_accAlias2',
                          doc['accusedAlias2'],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 2),
                  buildStackedFieldWithMLbl(
                    '(v) Nationality :',
                    'lbl_6v_m1',
                    'val_accNat',
                    doc['accusedNationality'],
                    width: double.infinity,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: buildStackedFieldWithMLbl(
                          '(vi) (a) Voter ID Card No: -',
                          'lbl_6vi_m1',
                          'val_accVoter',
                          doc['accusedVoter'],
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: buildStackedFieldWithMLbl(
                          '(b) *Passport No: -',
                          'lbl_6vi_m2',
                          'val_accPass',
                          doc['accusedPassport'],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 2),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: buildStackedFieldWithMLbl(
                          '(c) Date of issue :-',
                          'lbl_6vi_m3',
                          'val_accDateIss',
                          doc['accusedDateIssue'],
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: buildStackedFieldWithMLbl(
                          '(d) *Place of Issue :-',
                          'lbl_6vi_m4',
                          'val_accPlaceIss',
                          doc['accusedPlaceIssue'],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 2),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: buildStackedFieldWithMLbl(
                          '(vii) Religion: -',
                          'lbl_6vii_m1',
                          'val_accRelig',
                          doc['accusedReligion'],
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: buildStackedFieldWithMLbl(
                          '(viii) *Cast/Tribe: -',
                          'lbl_6viii_m1',
                          'val_accCaste',
                          doc['accusedCaste'],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 2),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: buildStackedFieldWithMLbl(
                          '(ix) SC/ST/OBC :-',
                          'lbl_6ix_m1',
                          'val_accScSt',
                          doc['accusedScSt'],
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: buildStackedFieldWithMLbl(
                          '(x)*Occupation :-',
                          'lbl_6x_m1',
                          'val_accOcc',
                          doc['accusedOccupation'],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 2),
                  buildStackedFieldWithMLbl(
                    '(xi) Permanent Address :-',
                    'lbl_6xi_m1',
                    'val_permAddr',
                    doc['permAddress'],
                    width: double.infinity,
                  ),
                  pw.SizedBox(height: 1),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: buildInlineFieldWithMLbl(
                          'State :-',
                          'lbl_state',
                          'val_permState',
                          doc['permState'],
                          width: 70,
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: buildInlineFieldWithMLbl(
                          'Dist.:-',
                          'lbl_dist2',
                          'val_permDist',
                          doc['permDist'],
                          width: 70,
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: buildInlineFieldWithMLbl(
                          'P.S. :-',
                          'lbl_ps2',
                          'val_permPs',
                          doc['permPs'],
                          width: 70,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 2),
                  buildStackedFieldWithMLbl(
                    '(xii) Present Address:-',
                    'lbl_6xii_m1',
                    'val_presAddr',
                    doc['presAddress'],
                    width: double.infinity,
                  ),
                  pw.SizedBox(height: 1),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: buildInlineFieldWithMLbl(
                          'State: -',
                          'lbl_state',
                          'val_presState',
                          doc['presState'],
                          width: 70,
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: buildInlineFieldWithMLbl(
                          'Dist.:-',
                          'lbl_dist2',
                          'val_presDist',
                          doc['presDist'],
                          width: 70,
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: buildInlineFieldWithMLbl(
                          'P.S. :-',
                          'lbl_ps2',
                          'val_presPs',
                          doc['presPs'],
                          width: 70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 4),

            // 7
            buildStackedFieldWithMLbl(
              '7. Injuries, cause of injuries and physical condition of the accused person (indicate if medically examined)',
              'lbl_7_m1',
              'val_injuries',
              doc['injuries'],
              width: double.infinity,
            ),
          ];
        },
      ),
    );
  }

  // --- PAGE 2 ---
  if (showsSection('Form 3-B')) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        build: (pw.Context context) {
          return [
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('From: 3-B', style: englishBold),
            ),
            pw.SizedBox(height: 8),

            // 8
            pw.Text(
              '8. The accused, after vying informed of the grounds of arrest and his leagal rights, was duty taken. Into custody',
              style: englishBold,
            ),
            pw.Wrap(
              crossAxisAlignment: pw.WrapCrossAlignment.end,
              children: [
                pw.Text('on :', style: englishBold),
                pw.Container(
                  width: 80,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
                  ),
                  child: renderText(
                    'val_cusDate',
                    doc['custodyDate'],
                    englishStyle,
                  ),
                ),
                pw.Text(' (date) at :', style: englishBold),
                pw.Container(
                  width: 80,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
                  ),
                  child: renderText(
                    'val_cusHours',
                    doc['custodyHours'],
                    englishStyle,
                  ),
                ),
                pw.Text(' (hours) at :', style: englishBold),
                pw.Container(
                  width: 120,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
                  ),
                  child: renderText(
                    'val_cusPlace',
                    doc['custodyPlace'],
                    englishStyle,
                  ),
                ),
                pw.Text('(place).', style: englishBold),
              ],
            ),
            mLbl('lbl_8_m1'),
            mLbl('lbl_8_m2'),
            pw.SizedBox(height: 8),

            pw.Text(
              'The following article(s) was/were found on physical search. Conducted on the person of the accused. And were taken into possession for which a receipt was given to the accused. **',
              style: englishBold,
            ),
            mLbl('lbl_8_m3'),
            pw.SizedBox(height: 8),

            pw.Row(
              children: [
                pw.Expanded(
                  child: field('1 ', 'val_art1', doc['article1'], width: 150),
                ),
                pw.Expanded(
                  child: field('2 ', 'val_art2', doc['article2'], width: 150),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                pw.Expanded(
                  child: field('3 ', 'val_art3', doc['article3'], width: 150),
                ),
                pw.Expanded(
                  child: field('4 ', 'val_art4', doc['article4'], width: 150),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                pw.Expanded(
                  child: field('5 ', 'val_art5', doc['article5'], width: 150),
                ),
                pw.Expanded(
                  child: field('6 ', 'val_art6', doc['article6'], width: 150),
                ),
              ],
            ),
            pw.SizedBox(height: 12),

            pw.Text(
              'Necessary wearing apparels were left on the accused for the sake of human dignity and body protection',
              style: englishBold,
            ),
            mLbl('lbl_8_m4'),
            pw.SizedBox(height: 8),
            pw.Text(
              'The accused was cautioned to keep him/herself covered for purpose of identification.',
              style: englishBold,
            ),
            mLbl('lbl_8_m5'),
            pw.SizedBox(height: 8),

            pw.Row(
              children: [
                field(
                  'Intimation given to Name: ',
                  'val_intName',
                  doc['intimationName'],
                  width: 150,
                ),
                pw.SizedBox(width: 16),
                field(
                  '(Relationship):',
                  'val_intRel',
                  doc['intimationRel'],
                  width: 100,
                ),
              ],
            ),
            pw.Row(
              children: [
                mLbl('lbl_8_m6'),
                pw.SizedBox(width: 150),
                mLbl('lbl_8_m7'),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              '** If no article found, NIL, may be indicated in the bland space provided below:-',
              style: englishBold,
            ),
            mLbl('lbl_8_m8'),
          ];
        },
      ),
    );

    // --- PAGE 3: Physical Features (Landscape) ---
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        build: (pw.Context context) {
          return [
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('From: 3-B (cont.)', style: englishBold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              '9. Physical features, deformities and other details of the accused:-',
              style: englishBold,
            ),
            mLbl('lbl_9_m1'),
            pw.SizedBox(height: 8),
            _buildPdfTable(
              headers: [
                'Sr. No.\nअ.क्र.',
                'Sex\nलिंग',
                'Date/year of\nBirth\nजन्म तारीख/\nवर्ष',
                'Build\nबांधा',
                'Height in\nCms.\nउंची से.मी.',
                'Complexion\nवर्ण',
                'identification\n(Mark)\nओळखचिन्ह',
                'Deformities\nPeculiarities\nव्यंग व\nवैशिष्टे',
                'Teeth\nदात',
                'Hair\nकेस',
              ],
              colIndices: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
              doc: doc,
              cache: cache,
              englishStyle: englishStyle,
              englishBold: englishBold,
            ),
            pw.SizedBox(height: 10),
            _buildPdfTable(
              headers: [
                'Eye\nडोळे',
                'Habits\nसवयी',
                'Dress\nHabits\nपोषाखाच्या\nसवयी',
                'Languages\nबोली/ भाषा',
                'Burn Mark\nभाजल्याच्या\nखुणा',
                'Leucoderma\nकोळ',
                'Mole\nतिळ',
                'Scar\nवण',
                'Tattoo\nगोंदण',
                'Forehead\nकपाळ',
              ],
              colIndices: [11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
              doc: doc,
              cache: cache,
              englishStyle: englishStyle,
              englishBold: englishBold,
            ),
            pw.SizedBox(height: 10),
            _buildPdfTable(
              headers: [
                'Ear\nकान',
                'Noes\nनाक',
                'Moustaches\nमिशी',
                'Speech/voice\nबोलण्याची पध्दत',
                'Face\nचेहरा',
                'Lips\nओठ',
              ],
              colIndices: [21, 22, 23, 24, 25, 26],
              doc: doc,
              cache: cache,
              englishStyle: englishStyle,
              englishBold: englishBold,
            ),
            pw.SizedBox(height: 12),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Other features if any: ', style: englishBold),
                pw.Expanded(
                  child: pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
                    ),
                    child: renderText(
                      'val_otherFeatures',
                      doc['otherFeatures']?.toString(),
                      englishStyle,
                      maxWidth: 650,
                    ),
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );
  }

  // --- PAGE 4 ---
  if (showsSection('Form 3-C')) {
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        build: (pw.Context context) {
          return [
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('From: 3-C', style: englishBold),
            ),
            pw.SizedBox(height: 4),

            // 10
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  '10. Whether finger print taken or not? : ',
                  style: englishBold,
                ),
                pw.Container(
                  width: 50,
                  padding:
                      const pw.EdgeInsets.only(left: 2, right: 2, bottom: 1),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
                  ),
                  child: pw.Text(
                    doc['fingerprintTaken'] == true ? 'Yes' : 'No',
                    style: englishStyle,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 1),
            mLbl('lbl_10_m1', maxWidth: 500),
            pw.SizedBox(height: 5),

            // 11
            pw.Text(
              '11. Socio-economic profile of the accused showing.',
              style: englishBold,
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '(a) Living Status: - Living alone/Living with Family/with Associate in Pucca House/Hotel/ Hostel/',
                    style: englishBold.copyWith(fontSize: 7.5),
                  ),
                  pw.Text(
                    '                                 Kacheha House / Thatehed House / Slum/ Homeless/ Harbourer.',
                    style: englishBold.copyWith(fontSize: 7.5),
                  ),
                  mLbl('lbl_11a_m1'),
                  mLbl('lbl_11a_m2'),
                  pw.SizedBox(height: 2),
                  pw.Wrap(
                    spacing: 20,
                    runSpacing: 6,
                    children: [
                      check('Living alone', doc['livingAlone'] == true),
                      check(
                        'Living with Family',
                        doc['livingWithFamily'] == true,
                      ),
                      check(
                        'with Associate',
                        doc['livingWithAssociate'] == true,
                      ),
                      check('Pucca House', doc['livingPucca'] == true),
                      check('Hotel', doc['livingHotel'] == true),
                      check('Hostel', doc['livingHostel'] == true),
                      check('Kacheha House', doc['livingKachcha'] == true),
                      check('Thatehed House', doc['livingThatched'] == true),
                      check('Slum', doc['livingSlum'] == true),
                      check('Homeless', doc['livingHomeless'] == true),
                      check('Harbourer', doc['livingHarbourer'] == true),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: buildStackedFieldWithMLbl(
                          '(b)Educational qualifications(s)',
                          'lbl_11b_m1',
                          'val_edu',
                          doc['eduQual'],
                          width: double.infinity,
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: buildStackedFieldWithMLbl(
                          '(c) occupation',
                          'lbl_11c_m1',
                          'val_occ2',
                          doc['occupation2'],
                          width: double.infinity,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('(d) Income Group :-', style: englishBold),
                  mLbl('lbl_11d_m1'),
                  pw.SizedBox(height: 2),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      buildIncomeItem(
                          doc['incomeLower'] == true, 'lbl_11di_m1'),
                      pw.SizedBox(width: 8),
                      buildIncomeItem(
                          doc['incomeLowerMid'] == true, 'lbl_11dii_m1'),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      buildIncomeItem(
                          doc['incomeMiddle'] == true, 'lbl_11diii_m1'),
                      pw.SizedBox(width: 8),
                      buildIncomeItem(
                          doc['incomeUpperMid'] == true, 'lbl_11div_m1'),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      buildIncomeItem(
                          doc['incomeUpperMid2'] == true, 'lbl_11dv_m1'),
                      pw.SizedBox(width: 8),
                      buildIncomeItem(
                          doc['incomeUpper'] == true, 'lbl_11dvi_m1'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 5),

            // 12
            pw.Text(
              '12. Whether the accused person as per the observations and known police records:',
              style: englishBold,
            ),
            mLbl('lbl_12_m1'),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _yesNoRow(
                    '(a) Is dangerous ?',
                    'lbl_12a_m1',
                    doc['isDangerous'] == true,
                    englishStyle,
                    englishBold,
                    mLbl,
                  ),
                  _yesNoRow(
                    '(b) Previously escaped any bail ?',
                    'lbl_12b_m1',
                    doc['prevEscaped'] == true,
                    englishStyle,
                    englishBold,
                    mLbl,
                  ),
                  _yesNoRow(
                    '(c) Is generally armed?',
                    'lbl_12c_m1',
                    doc['generallyArmed'] == true,
                    englishStyle,
                    englishBold,
                    mLbl,
                  ),
                  _yesNoRow(
                    '(d) Operates with accomplices?',
                    'lbl_12d_m1',
                    doc['operatesWithAccomplices'] == true,
                    englishStyle,
                    englishBold,
                    mLbl,
                  ),
                  _yesNoRow(
                    '(e) Has past criminal records ?',
                    'lbl_12e_m1',
                    doc['pastCriminal'] == true,
                    englishStyle,
                    englishBold,
                    mLbl,
                  ),
                  _yesNoRow(
                    '(f) Is recidivism',
                    'lbl_12f_m1',
                    doc['isRecidivism'] == true,
                    englishStyle,
                    englishBold,
                    mLbl,
                  ),
                  _yesNoRow(
                    '(g) Is likely to escape bail ?',
                    'lbl_12g_m1',
                    doc['likelyToEscape'] == true,
                    englishStyle,
                    englishBold,
                    mLbl,
                  ),
                  _yesNoRow(
                    '(h) Is released on bail. Likely to commit crime or threaten victims/witnesses.',
                    '',
                    doc['releasedOnBail'] == true,
                    englishStyle,
                    englishBold,
                    mLbl,
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 8),
                    child: mLbl('lbl_12h_m1'),
                  ),
                  _yesNoRow(
                    '(i) Is wanted many other case?',
                    'lbl_12i_m1',
                    doc['wantedMany'] == true,
                    englishStyle,
                    englishBold,
                    mLbl,
                  ),
                  pw.Row(
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('(If yes give case ref. Sec.)',
                              style: englishStyle),
                          mLbl('lbl_12i_m2'),
                        ],
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: pw.Container(
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              bottom: pw.BorderSide(width: 0.5),
                            ),
                          ),
                          child: renderText(
                            'val_caseRef',
                            doc['caseRefSec'],
                            englishStyle,
                            maxWidth: 250,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 5),

            // 13
            pw.Row(
              children: [
                pw.Expanded(
                  child: buildFlexibleFieldWithMLbl(
                    '13. ',
                    'lbl_13_m1',
                    'val_p1Name',
                    doc['panch1Name'],
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: buildFlexibleFieldWithMLbl(
                    '',
                    'lbl_13_m2',
                    'val_p1Sig',
                    doc['panch1Sig'],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Name and Address of the witnesses/Panchas (At Least one witness necessary)',
                  style: englishBold.copyWith(fontSize: 7.5),
                ),
                pw.Text('Signature\n',
                    style: englishBold.copyWith(fontSize: 7.5)),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('(2):', style: englishBold),
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.only(
                              left: 2, right: 2, bottom: 1),
                          decoration: const pw.BoxDecoration(
                            border:
                                pw.Border(bottom: pw.BorderSide(width: 0.5)),
                          ),
                          child: renderText(
                            'val_p2Name',
                            doc['panch2Name']?.toString(),
                            englishStyle,
                            maxWidth: 220,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: buildFlexibleFieldWithMLbl(
                    '',
                    'lbl_13_m3',
                    'val_p2Sig',
                    doc['panch2Sig'],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 5),

            // 14 & 15
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '14. Signature and Thumb hapression of Arrested person',
                        style: englishBold,
                      ),
                      mLbl('lbl_14_m1'),
                      pw.SizedBox(height: 4),
                      field(
                        ':',
                        'val_arrSig',
                        doc['arrestedPersonSig'],
                        width: 130,
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text('15.', style: englishBold),
                      buildInlineFieldWithMLbl(
                        'Place: ',
                        'lbl_15_m1',
                        'val_fPlace',
                        doc['finalPlace'],
                        width: 90,
                      ),
                      pw.SizedBox(height: 3),
                      buildInlineFieldWithMLbl(
                        'Date: ',
                        'lbl_15_m2',
                        'val_fDate',
                        doc['finalDate'],
                        width: 90,
                      ),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Signature of the Investigation Officer with:',
                        style: englishBold,
                      ),
                      pw.SizedBox(height: 3),
                      buildInlineFieldWithMLbl(
                        'Signature / ',
                        'lbl_io_sig',
                        'val_ioSig',
                        doc['ioSig'],
                        width: 130,
                      ),
                      pw.SizedBox(height: 4),
                      buildInlineFieldWithMLbl(
                        'Name: ',
                        'lbl_15_m3',
                        'val_fName',
                        doc['finalName'],
                        width: 130,
                      ),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        children: [
                          buildInlineFieldWithMLbl(
                            'Rank: ',
                            'lbl_15_m4',
                            'val_fRank',
                            doc['finalRank'],
                            width: 70,
                          ),
                          pw.SizedBox(width: 8),
                          buildInlineFieldWithMLbl(
                            'No: ',
                            'lbl_15_m5',
                            'val_fNo',
                            doc['finalNo'],
                            width: 50,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );
  }

  return pdf.save();
}

pw.Widget _yesNoRow(
  String enLabel,
  String mKey,
  bool value,
  pw.TextStyle style,
  pw.TextStyle boldStyle,
  pw.Widget Function(String, {double? maxWidth, double? width}) mLbl,
) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 1),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
              pw.Text(enLabel, style: style),
              if (mKey.isNotEmpty) mLbl(mKey, maxWidth: 380),
            ])),
        pw.Row(children: [
          pw.Text('Yes/No ', style: boldStyle),
          mLbl('lbl_yes_no', maxWidth: 60),
          pw.Text(value ? ' [Yes]' : ' [No]', style: style),
        ]),
      ],
    ),
  );
}

pw.Widget _buildPdfTable({
  required List<String> headers,
  required List<int> colIndices,
  required Map<String, dynamic> doc,
  required MarathiImageCache cache,
  required pw.TextStyle englishStyle,
  required pw.TextStyle englishBold,
}) {
  final Map<String, dynamic> pt =
      doc['physTable'] is Map ? doc['physTable'] as Map<String, dynamic> : {};

  return pw.Table(
    border: pw.TableBorder.all(width: 1),
    columnWidths: {
      for (int i = 0; i < headers.length; i++) i: const pw.FlexColumnWidth(),
    },
    children: [
      pw.TableRow(
        children: List.generate(headers.length, (i) {
          final lines = headers[i].split('\n');
          return pw.Padding(
            padding: const pw.EdgeInsets.all(2),
            child: pw.Column(
              children: [
                pw.Text(
                  lines[0],
                  style: englishBold.copyWith(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
                if (lines.length > 1) ...[
                  for (int j = 1; j < lines.length; j++)
                    if (containsDevanagari(lines[j]))
                      cache.has('tbl_h_${colIndices[i]}_$j')
                          ? cache.img('tbl_h_${colIndices[i]}_$j')
                          : pw.SizedBox()
                    else
                      pw.Text(
                        lines[j],
                        style: englishBold.copyWith(fontSize: 8),
                        textAlign: pw.TextAlign.center,
                      ),
                ],
                pw.Divider(thickness: 0.5),
                pw.Text(
                  '${colIndices[i]}',
                  style: englishBold.copyWith(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          );
        }),
      ),
      pw.TableRow(
        children: List.generate(headers.length, (i) {
          final val = pt[colIndices[i].toString()]?.toString() ?? '';
          return pw.Container(
            height: 30, // Fixed height for input area
            padding: const pw.EdgeInsets.all(2),
            child: containsDevanagari(val)
                ? (cache.has('tbl_v_${colIndices[i]}')
                    ? cache.img('tbl_v_${colIndices[i]}')
                    : pw.SizedBox())
                : pw.Text(val, style: englishStyle.copyWith(fontSize: 8)),
          );
        }),
      ),
    ],
  );
}

Future<MarathiImageCache> _preRenderAllMarathi(
  Map<String, dynamic> doc, {
  bool Function(String section)? showsSection,
}) async {
  final cache = MarathiImageCache();

  final show3A = showsSection == null || showsSection('Form 3-A');
  final show3B = showsSection == null || showsSection('Form 3-B');
  final show3C = showsSection == null || showsSection('Form 3-C');

  final headerStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  final marathiLabelStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 7.5,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  final valueStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 8,
    color: Colors.black,
  );

  Future<void> addLbl(
    String key,
    String text,
    TextStyle style, {
    double maxWidth = 500,
  }) async {
    await cache.add(key, text, style, maxWidth: maxWidth);
  }

  Future<void> addVal(String key, String? val, {double maxWidth = 500}) async {
    final text = val?.trim() ?? '';
    if (containsDevanagari(text)) {
      await cache.add(key, text, valueStyle, maxWidth: maxWidth);
    }
  }

  if (show3A) {
    // Page 1
    await addLbl('title_m1', 'अटकेचा पंचनामा/ न्यायालयाच्या', headerStyle);
    await addLbl('title_m2', 'स्वाधीन होण्याचा नमुना', headerStyle);
    await addLbl(
      'title_m3',
      '(प्रत्येक आरोपीसाठी स्वतंत्र नमुना वापरावा)',
      marathiLabelStyle,
    );

    await addLbl('lbl_dist', 'जिल्हा :-', marathiLabelStyle);
    await addLbl('lbl_ps', 'पो.स्टे.', marathiLabelStyle);
    await addLbl('lbl_fir', 'पहिली खबर क्र/ कार्यवाही क्र.', marathiLabelStyle);
    await addLbl('lbl_year', 'वर्ष', marathiLabelStyle);
    await addLbl('lbl_date', 'दिनांक', marathiLabelStyle);
    await addLbl(
      'lbl_code',
      'आरोपीचा सांकेतीक क्रमांक ( पहिल्या ९ व्यक्तींसाठी अ १ ते अ ९, दहाव्या व्यक्तीसाठी ब १ या प्रमाणे पुढे असे लिहावे )',
      marathiLabelStyle,
    );

    await addLbl(
      'lbl_arr_date',
      'अटकेची / स्वाधीन होण्याची तारीख वेळ',
      marathiLabelStyle,
    );
    await addLbl('lbl_arr_time', 'दिनांक', marathiLabelStyle);
    await addLbl('lbl_arr_gd', 'वेळ ठाणे दैनंदिन क्रमांक', marathiLabelStyle);
    await addLbl('lbl_arr_ps', 'अटकेची जागा पोलीस ठाणे', marathiLabelStyle);
    await addLbl('lbl_arr_dist', 'जिल्हा', marathiLabelStyle);
    await addLbl('lbl_arr_state', 'राज्य', marathiLabelStyle);

    await addLbl(
      'lbl_court',
      'न्यायालयाचे नांव ( स्वाधीन झाल्यास ) :-',
      marathiLabelStyle,
    );
    await addLbl('lbl_acts', 'अधिनियम व कलमे :-', marathiLabelStyle);

    await addLbl(
      'lbl_5_m1',
      'अटक केली व न्यायालयात पाठविले/ अटक केली व जामीनावर सोडले किंवा वैयक्तीक जात मुचलक्यावर सोडले / अटक केली व अटकपूर्व जामीनावर सोडले/ अटक केले व पोलीस कोठडीत',
      marathiLabelStyle,
    );
    await addLbl(
      'lbl_5_m2',
      'पाठविले/ न्यायालयाचे स्वाधीन व जामीनावर / न्यायालयाचे स्वाधीन व न्यायालयीन कोठडीत पाठविले/ न्यायालयाचे स्वाधीन व पोलीस कोठडीत पाठविले',
      marathiLabelStyle,
    );

    await addLbl('lbl_6vi_m1', 'मतदान ओळखपत्र क्रमांक:-', marathiLabelStyle);
    await addLbl('lbl_6vi_m2', 'पारपत्र क्रमांक :-', marathiLabelStyle);
    await addLbl('lbl_6vi_m3', 'दिल्याची तारीख :-', marathiLabelStyle);
    await addLbl('lbl_6vi_m4', 'दिल्याचो जागा :-', marathiLabelStyle);
    await addLbl('lbl_6vii_m1', '(धर्म) :-', marathiLabelStyle);
    await addLbl('lbl_6viii_m1', '(जात जमात):-', marathiLabelStyle);
    await addLbl(
      'lbl_6ix_m1',
      '(अनु.जा/ अनु जमात/ इ.मा.व) :-',
      marathiLabelStyle,
    );
    await addLbl('lbl_6x_m1', '(व्यवसाय) :-', marathiLabelStyle);
    await addLbl('lbl_6xi_m1', '(कायमचा पत्ता) :-', marathiLabelStyle);
    await addLbl('lbl_state', 'राज्य', marathiLabelStyle);
    await addLbl('lbl_dist2', 'जिल्हा', marathiLabelStyle);
    await addLbl('lbl_ps2', 'पोलीस ठाणे', marathiLabelStyle);
    await addLbl('lbl_6xii_m1', '(सध्याचा पत्ता) :-', marathiLabelStyle);

    await addLbl(
      'lbl_7_m1',
      'जखम, जखमाची कारणे आणि आरोपीची शारीरीक अवस्था / (वैद्यकीय तपासणी केली असल्यास नमुद करणे)',
      marathiLabelStyle,
    );

    // Section 6 labels
    await addLbl('lbl_6_title_m1', '( आरोपीचा तपशील ) :-', marathiLabelStyle);
    await addLbl('lbl_6i_m1', '(नांव) :-', marathiLabelStyle);
    await addLbl(
        'lbl_6ii_m1', '(पित्याचे/पतीचे/पालकाचे नांव ) :-', marathiLabelStyle);
    await addLbl('lbl_6iii_m1', '(पहिले टोपण नांव ):-', marathiLabelStyle);
    await addLbl('lbl_6iv_m1', '(दुसरे टोपण नांव ):-', marathiLabelStyle);
    await addLbl('lbl_6v_m1', '(राष्ट्रीयत्व) :-', marathiLabelStyle);
  }

  if (show3B) {
    // Page 2
    await addLbl(
      'lbl_8_m1',
      'कायदेशीर अटकेची कारणे आणि त्याचे कायदेशीर अधिकार सांगीतल्यानंतर दि.:--------/--------/20……… रोजी ………/……….वाजता',
      marathiLabelStyle,
    );
    await addLbl(
      'lbl_8_m2',
      '____________________________________________________ (ठिकाण) येथे योग्य रित्या ताब्यात घेण्यात आले.',
      marathiLabelStyle,
    );
    await addLbl(
      'lbl_8_m3',
      'आरोपीच्या अंगझडतीमध्ये खालील वस्तु आढळल्या. त्या ताब्यात घेण्यात आल्या आणि त्या बद्दल त्याची पोच देण्यात आली.',
      marathiLabelStyle,
    );
    await addLbl(
      'lbl_8_m4',
      '(मानवी प्रतिष्ठेसाठी व शरीर झाकण्यासाठी आरोपीच्या अंगावर आवश्यक तेवढे कपडे ठेवण्यात आले होते.)',
      marathiLabelStyle,
    );
    await addLbl(
      'lbl_8_m5',
      'ओळख पटण्याच्या प्रयोजनासाठी आरोपीला स्वतःला झाकुन घेण्याची ताकीद देण्यात आली होती.',
      marathiLabelStyle,
    );
    await addLbl('lbl_8_m6', 'यांना खबरदेण्यात आली नांव', marathiLabelStyle);
    await addLbl('lbl_8_m7', '(नाते)', marathiLabelStyle);
    await addLbl(
      'lbl_8_m8',
      'जर कोणतीही वस्तु आढळली नाही तर खालील जागेत नाही असे नमुद करावे.',
      marathiLabelStyle,
    );

    await addLbl(
      'lbl_9_m1',
      'शारीरीक वैशिष्टे आणि आरोपीचा इतर तपशील :-',
      marathiLabelStyle,
    );

    // Table Headers for Physical features (Page 3)
    final tableHeaders = {
      1: ['अ.क्र.'],
      2: ['लिंग'],
      3: ['जन्म तारीख/', 'वर्ष'],
      4: ['बांधा'],
      5: ['उंची से.मी.'],
      6: ['वर्ण'],
      7: ['ओळखचिन्ह'],
      8: ['व्यंग व', 'वैशिष्टे'],
      9: ['दात'],
      10: ['केस'],
      11: ['डोळे'],
      12: ['सवयी'],
      13: ['पोषाखाच्या', 'सवयी'],
      14: ['बोली/ भाषा'],
      15: ['भाजल्याच्या', 'खुणा'],
      16: ['कोळ'],
      17: ['तिळ'],
      18: ['वण'],
      19: ['गोंदण'],
      20: ['कपाळ'],
      21: ['कान'],
      22: ['नाक'],
      23: ['मिशी'],
      24: ['बोलण्याची पध्दत'],
      25: ['चेहरा'],
      26: ['ओठ'],
    };

    final tblHeaderStyle = GoogleFonts.notoSansDevanagari(
      fontSize: 8,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

    for (final entry in tableHeaders.entries) {
      for (int j = 0; j < entry.value.length; j++) {
        if (containsDevanagari(entry.value[j])) {
          await cache.add(
            'tbl_h_${entry.key}_${j + 1}',
            entry.value[j],
            tblHeaderStyle,
          );
        }
      }
    }
  }

  if (show3C) {
    // Page 4
    await addLbl(
      'lbl_10_m1',
      'बोटाचे ठसे घेतले आहेत किंवा नाही असल्यास त्यांचा नंबर/ ठसे घेतले नसल्यास त्याचे कारण.',
      marathiLabelStyle,
    );
    await addLbl(
      'lbl_11a_m1',
      'राहणीमान :- एकटा कुटूंबीयासोबत/ सहकारी यांच्या बरोबर पक्या घरात/ हॉटेलात/ वसतीगृहात/ कच्च्या घरात/ गव्ती छपराच्या झोपडीत/',
      marathiLabelStyle,
    );
    await addLbl(
      'lbl_11a_m2',
      'गलीच्छ वस्तीत राहतो/ बेघर किंवा आश्रय घेतलेला नाही.',
      marathiLabelStyle,
    );
    await addLbl('lbl_11b_m1', '(शैक्षणीक अर्हता) :', marathiLabelStyle);
    await addLbl('lbl_11c_m1', '(व्यवसाय) :', marathiLabelStyle);
    await addLbl('lbl_11d_m1', ' उत्पन्न गट ', marathiLabelStyle);
    await addLbl(
      'lbl_12_m1',
      'निरीक्षणावरून आणि माहिती असलेल्या पोलीस अभिलेखानुसार आरोपी :-',
      marathiLabelStyle,
    );

    await addLbl('lbl_13_m1', 'पंचाची नांवे (1) :', marathiLabelStyle);
    await addLbl('lbl_13_m2', 'पंचाच्या सहया (1) :', marathiLabelStyle);
    await addLbl('lbl_13_m3', 'पंचाच्या सहया (2) :', marathiLabelStyle);

    await addLbl(
        'lbl_14_m1', 'आरोपीची सही व आरोपीचा व अंगठा', marathiLabelStyle);

    await addLbl(
        'lbl_11di_m1',
        '(i) Lower Income (Below Rs. 25000 P.Y.) = कमी उत्पन्न ( द.सा.रू २५००० पेक्ष कमी )',
        marathiLabelStyle,
        maxWidth: 240);
    await addLbl(
        'lbl_11dii_m1',
        '(ii) Lower Middle Income (From Rs. 25001 to 50000) = कमी मध्यम उत्पन्न ( २५००१ ते ५००००)',
        marathiLabelStyle,
        maxWidth: 240);
    await addLbl(
        'lbl_11diii_m1',
        '(iii) Middle Income (From 50001 to 100000) = मध्यम उत्पन्न (२५,००१ ते १००,००० )',
        marathiLabelStyle,
        maxWidth: 240);
    await addLbl(
        'lbl_11div_m1',
        '(iv) Upper Middle Income (/From 100000 to 200000)= उच्च मध्यम उत्पन्न ( १००,००१ ते  २००,०००)',
        marathiLabelStyle,
        maxWidth: 240);
    await addLbl(
        'lbl_11dv_m1',
        '(v) Upper Middle Income (Rs. 200000 to 300000) = उच्च मध्यम उत्पन्न ( २००,००१ ते ३००,०००)',
        marathiLabelStyle,
        maxWidth: 240);
    await addLbl(
        'lbl_11dvi_m1',
        '(vi) Upper Income (above 300000) =SSE = उच्च उत्पन्न ( ३००,०००)',
        marathiLabelStyle,
        maxWidth: 240);
    await addLbl('lbl_12a_m1', '(धोकादायक आहे किंवा कसे?)', marathiLabelStyle);
    await addLbl('lbl_12b_m1',
        '( पुर्वी जामीनावर असतांना पळुन गेला किंवा काय ? )', marathiLabelStyle);
    await addLbl(
        'lbl_12c_m1', '( नेहमी सशस्त्र असतो किंवा नसतो ?)', marathiLabelStyle);
    await addLbl(
        'lbl_12d_m1', '( साथीदारासह काम करतो किंवा कसे ? )', marathiLabelStyle);
    await addLbl('lbl_12e_m1', '(गुन्हेगारी पार्श्वभुमी आहे किंवा नाही ? )',
        marathiLabelStyle);
    await addLbl(
        'lbl_12f_m1', '(वारंवार अपराध करतो किंवा काय ? )', marathiLabelStyle);
    await addLbl(
        'lbl_12g_m1',
        '(जामीनावर असतांना पळूनजाण्याचा संभव किंवा नाही ? )',
        marathiLabelStyle);
    await addLbl(
        'lbl_12h_m1',
        '(जामीनावर साडल्यास लगेच दुसरा गुन्हा करण्याचा किंवा बळींना/ साक्षेदारांना धाकदपटशा दाखविण्याचा संभव आहे किंवा नाही?)',
        marathiLabelStyle);
    await addLbl('lbl_12i_m1',
        '(दुसऱ्या कोणत्याही प्रकरणात पाहिजे किंवा काय ?)', marathiLabelStyle);
    await addLbl(
        'lbl_12i_m2',
        '( जर होय असेल तर त्या प्रकरणाचा संदर्भ व कलमे दयवीत ?)',
        marathiLabelStyle);
    await addLbl('lbl_yes_no', '(होय/नाही)', marathiLabelStyle);
    await addLbl('lbl_io_sig', 'सही :-', marathiLabelStyle);

    await addLbl('lbl_15_m1', 'ठिकाण', marathiLabelStyle);
    await addLbl('lbl_15_m2', 'तारीख', marathiLabelStyle);
    await addLbl(
      'lbl_15_m3',
      FormIoTerminology.signatureHeader,
      marathiLabelStyle,
    );
    await addLbl('lbl_15_m4', FormIoTerminology.rank, marathiLabelStyle);
    await addLbl('lbl_15_m5', 'क्रमांक', marathiLabelStyle);
  }

  // Values — cache keys must match renderText valKey arguments in the PDF layout
  final valueKeyMap = <String, String>{
    if (show3A) ...{
      'val_dist': 'dist',
      'val_ps': 'ps',
      'val_fir': 'firNo',
      'val_year': 'year',
      'val_date': 'date',
      'val_code': 'accusedCode',
      'val_arrDate': 'arrestDate',
      'val_arrTime': 'arrestTime',
      'val_arrGd': 'arrestGdNo',
      'val_arrPlace': 'arrestPlace',
      'val_arrDist': 'arrestDist',
      'val_arrState': 'arrestState',
      'val_court': 'courtName',
      'val_acts': 'actsSections',
      'val_accName': 'accusedName',
      'val_accFather': 'accusedFather',
      'val_accAlias1': 'accusedAlias1',
      'val_accAlias2': 'accusedAlias2',
      'val_accNat': 'accusedNationality',
      'val_accVoter': 'accusedVoter',
      'val_accPass': 'accusedPassport',
      'val_accDateIss': 'accusedDateIssue',
      'val_accPlaceIss': 'accusedPlaceIssue',
      'val_accRelig': 'accusedReligion',
      'val_accCaste': 'accusedCaste',
      'val_accScSt': 'accusedScSt',
      'val_accOcc': 'accusedOccupation',
      'val_permAddr': 'permAddress',
      'val_permState': 'permState',
      'val_permDist': 'permDist',
      'val_permPs': 'permPs',
      'val_presAddr': 'presAddress',
      'val_presState': 'presState',
      'val_presDist': 'presDist',
      'val_presPs': 'presPs',
      'val_injuries': 'injuries',
    },
    if (show3B) ...{
      'val_cusDate': 'custodyDate',
      'val_cusHours': 'custodyHours',
      'val_cusPlace': 'custodyPlace',
      'val_art1': 'article1',
      'val_art2': 'article2',
      'val_art3': 'article3',
      'val_art4': 'article4',
      'val_art5': 'article5',
      'val_art6': 'article6',
      'val_intName': 'intimationName',
      'val_intRel': 'intimationRel',
    },
    if (show3C) ...{
      'val_edu': 'eduQual',
      'val_occ2': 'occupation2',
      'val_caseRef': 'caseRefSec',
      'val_p1Name': 'panch1Name',
      'val_p2Name': 'panch2Name',
      'val_p1Sig': 'panch1Sig',
      'val_p2Sig': 'panch2Sig',
      'val_arrSig': 'arrestedPersonSig',
      'val_ioSig': 'ioSig',
      'val_fPlace': 'finalPlace',
      'val_fDate': 'finalDate',
      'val_fName': 'finalName',
      'val_fRank': 'finalRank',
      'val_fNo': 'finalNo',
      'val_otherFeatures': 'otherFeatures',
    },
  };

  const twoColKeys = {
    'val_accAlias1',
    'val_accAlias2',
    'val_accVoter',
    'val_accPass',
    'val_accDateIss',
    'val_accPlaceIss',
    'val_accRelig',
    'val_accCaste',
    'val_accScSt',
    'val_accOcc',
    'val_edu',
    'val_occ2',
    'val_p1Name',
    'val_p1Sig',
    'val_p2Name',
    'val_p2Sig',
    'val_fRank',
    'val_fNo',
  };

  const threeColKeys = {
    'val_permState',
    'val_permDist',
    'val_permPs',
    'val_presState',
    'val_presDist',
    'val_presPs',
  };

  for (final entry in valueKeyMap.entries) {
    double maxW = 500.0;
    if (twoColKeys.contains(entry.key)) {
      maxW = 220.0;
    } else if (threeColKeys.contains(entry.key)) {
      maxW = 120.0;
    }
    await addVal(entry.key, doc[entry.value]?.toString(), maxWidth: maxW);
  }

  // Table values
  if (show3B && doc['physTable'] is Map) {
    final pt = doc['physTable'] as Map<String, dynamic>;
    for (int i = 1; i <= 26; i++) {
      await addVal('tbl_v_$i', pt[i.toString()], maxWidth: 70.0);
    }
  }

  return cache;
}
