import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart';
import 'marathi_text_renderer.dart';
import 'form_io_terminology.dart';
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

List<String> _splitTextIntoLines(String text, int maxChars) {
  if (text.isEmpty) return [];
  final paragraphs = text.split('\n');
  final result = <String>[];

  for (final para in paragraphs) {
    if (para.length <= maxChars) {
      result.add(para);
    } else {
      final words = para.split(' ');
      var current = '';
      for (final word in words) {
        if (current.isEmpty) {
          if (word.length > maxChars) {
            for (int i = 0; i < word.length; i += maxChars) {
              final end =
                  (i + maxChars < word.length) ? i + maxChars : word.length;
              result.add(word.substring(i, end));
            }
          } else {
            current = word;
          }
        } else if ('$current $word'.length <= maxChars) {
          current = '$current $word';
        } else {
          result.add(current);
          if (word.length > maxChars) {
            for (int i = 0; i < word.length; i += maxChars) {
              final end =
                  (i + maxChars < word.length) ? i + maxChars : word.length;
              result.add(word.substring(i, end));
            }
            current = '';
          } else {
            current = word;
          }
        }
      }
      if (current.isNotEmpty) {
        result.add(current);
      }
    }
  }
  return result;
}

Future<Uint8List> generateArrestSurrenderPdf(Map<String, dynamic> doc) async {
  final pdf = pw.Document();

  // Load fonts
  final loraRegular = await PdfGoogleFonts.loraRegular();
  final loraBold = await PdfGoogleFonts.loraBold();

  // Pre-render Marathi text blocks
  final cache = await _preRenderAllMarathi(doc);

  const knownSectionIds = {'Form 3-A', 'Form 3-B', 'Form 3-C'};
  final activeSection = doc['formSection']?.toString();

  bool showsSection(String sectionId) => showsFormSection(
        activeSection: activeSection,
        sectionId: sectionId,
        knownSectionIds: knownSectionIds,
      );

  final pw.TextStyle englishStyle = pw.TextStyle(
    font: loraRegular,
    fontSize: 9,
    color: PdfColors.black,
  );

  final pw.TextStyle englishBold = pw.TextStyle(
    font: loraBold,
    fontSize: 9,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.black,
  );

  final pw.TextStyle headerEnglishStyle = pw.TextStyle(
    font: loraBold,
    fontSize: 16,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.black,
  );

  pw.Widget renderText(String key, String? val, pw.TextStyle engStyle) {
    if (val == null || val.isEmpty) return pw.SizedBox();
    if (containsDevanagari(val)) {
      if (cache.has(key)) {
        return pw.Container(
          alignment: pw.Alignment.topLeft,
          child: cache.img(key),
        );
      }
    }
    return pw.Text(val, style: engStyle, maxLines: 1);
  }

  pw.Widget mLbl(String key) {
    if (cache.has(key)) return cache.img(key);
    return pw.SizedBox();
  }

  pw.Widget field(
    String labelText,
    String valKey,
    String? fallback, {
    double? width,
    bool expanded = false,
    int minLines = 1,
    int maxCharsPerLine = 50,
  }) {
    final cleanVal = fallback?.trim() ?? '';
    final lines = _splitTextIntoLines(cleanVal, maxCharsPerLine);
    final totalLines = lines.length < minLines ? minLines : lines.length;

    pw.Widget underlineBox;
    if (expanded && (totalLines > 1 || lines.isNotEmpty)) {
      underlineBox = pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < totalLines; i++) ...[
              if (i > 0) pw.SizedBox(height: 2),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.only(left: 4, right: 4, bottom: 2),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
                ),
                child: cache.has('${valKey}_$i')
                    ? cache.img('${valKey}_$i')
                    : (i == 0 && lines.length <= 1 && cache.has(valKey))
                        ? cache.img(valKey)
                        : pw.Text(
                            i < lines.length ? lines[i] : '',
                            style: englishStyle,
                            maxLines: 1,
                          ),
              ),
            ],
          ],
        ),
      );
    } else {
      final child = pw.Container(
        width: expanded ? null : width,
        padding: const pw.EdgeInsets.only(left: 4, right: 4, bottom: 2),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
        ),
        child: renderText(valKey, fallback, englishStyle),
      );
      underlineBox = expanded ? pw.Expanded(child: child) : child;
    }

    return pw.Row(
      mainAxisSize: expanded ? pw.MainAxisSize.max : pw.MainAxisSize.min,
      crossAxisAlignment: (totalLines > 1)
          ? pw.CrossAxisAlignment.start
          : pw.CrossAxisAlignment.end,
      children: [
        pw.Text(labelText, style: englishBold),
        pw.SizedBox(width: 4),
        underlineBox,
      ],
    );
  }

  pw.Widget buildInlineFieldWithMLbl(
    String enLabel,
    String mKey,
    String valKey,
    String? fallback, {
    double? width,
    bool expanded = false,
    int minLines = 1,
    int maxCharsPerLine = 50,
  }) {
    final cleanVal = fallback?.trim() ?? '';
    final lines = _splitTextIntoLines(cleanVal, maxCharsPerLine);
    final totalLines = lines.length < minLines ? minLines : lines.length;

    pw.Widget underlineBox;
    if (expanded && (totalLines > 1 || lines.isNotEmpty)) {
      underlineBox = pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < totalLines; i++) ...[
              if (i > 0) pw.SizedBox(height: 2),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.only(left: 4, right: 4, bottom: 2),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
                ),
                child: cache.has('${valKey}_$i')
                    ? cache.img('${valKey}_$i')
                    : (i == 0 && lines.length <= 1 && cache.has(valKey))
                        ? cache.img(valKey)
                        : pw.Text(
                            i < lines.length ? lines[i] : '',
                            style: englishStyle,
                            maxLines: 1,
                          ),
              ),
            ],
          ],
        ),
      );
    } else {
      final child = pw.Container(
        width: expanded ? null : width,
        padding: const pw.EdgeInsets.only(left: 4, right: 4, bottom: 2),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
        ),
        child: renderText(valKey, fallback, englishStyle),
      );
      underlineBox = expanded ? pw.Expanded(child: child) : child;
    }

    return pw.Row(
      mainAxisSize: expanded ? pw.MainAxisSize.max : pw.MainAxisSize.min,
      crossAxisAlignment: (totalLines > 1)
          ? pw.CrossAxisAlignment.start
          : pw.CrossAxisAlignment.end,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(enLabel, style: englishBold),
            mLbl(mKey),
          ],
        ),
        pw.SizedBox(width: 4),
        underlineBox,
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

  // --- PAGE 1 ---
  if (showsSection('Form 3-A')) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Title
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'ARREST/COURT SURRENDER FORM',
                      style: headerEnglishStyle,
                    ),
                    pw.SizedBox(height: 4),
                    mLbl('title_m1'),
                    mLbl('title_m2'),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      '(Separate Memo for each accused)',
                      style: englishBold,
                    ),
                    mLbl('title_m3'),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // 1. Dist & P.S. (Row 1)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: buildInlineFieldWithMLbl(
                      '1.Dist.',
                      'lbl_dist',
                      'val_dist',
                      doc['dist']?.toString() ?? '',
                      expanded: true,
                      maxCharsPerLine: 22,
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Expanded(
                    child: buildInlineFieldWithMLbl(
                      'P.S.:-',
                      'lbl_ps',
                      'val_ps',
                      doc['ps']?.toString() ?? '',
                      expanded: true,
                      maxCharsPerLine: 22,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              // Row 2: FIR/Proceeding/G.D.No, Year, Date
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 45,
                    child: buildInlineFieldWithMLbl(
                      'FIR/Proceeding/G.D.No:-',
                      'lbl_fir',
                      'val_fir',
                      doc['firNo']?.toString() ?? '',
                      expanded: true,
                      maxCharsPerLine: 16,
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  buildInlineFieldWithMLbl(
                    'Year:-20',
                    'lbl_year',
                    'val_year',
                    doc['year']?.toString() ?? '',
                    width: 35,
                  ),
                  pw.SizedBox(width: 12),
                  buildInlineFieldWithMLbl(
                    'Date',
                    'lbl_date',
                    'val_date',
                    doc['date']?.toString() ?? '',
                    width: 75,
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Alphanumeric Code of the Accused (Write A1 to A9 for the first 9 persons, B1 for 10 th person and so on)',
                        style: englishBold,
                      ),
                      pw.SizedBox(width: 8),
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.only(left: 4, right: 4, bottom: 2),
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
                          ),
                          child: renderText(
                            'val_code',
                            doc['accusedCode']?.toString(),
                            englishStyle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 2),
                  mLbl('lbl_code'),
                ],
              ),
              pw.SizedBox(height: 10),

              // 2. Date, Time & place of Arrest/surrender
              pw.Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: pw.WrapCrossAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        '2. Date, Time & place of Arrest/surrender :-',
                        style: englishBold,
                      ),
                      mLbl('lbl_arr_title'),
                    ],
                  ),
                  buildInlineFieldWithMLbl(
                    'Date',
                    'lbl_arr_date',
                    'val_arrDate',
                    doc['arrestDate']?.toString() ?? '',
                    width: 60,
                  ),
                  buildInlineFieldWithMLbl(
                    'Time',
                    'lbl_arr_time',
                    'val_arrTime',
                    doc['arrestTime']?.toString() ?? '',
                    width: 50,
                  ),
                  buildInlineFieldWithMLbl(
                    'G.D.No.',
                    'lbl_arr_gd',
                    'val_arrGd',
                    doc['arrestGdNo']?.toString() ?? '',
                    width: 60,
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: buildInlineFieldWithMLbl(
                      'Place of Arrest: - P.S.',
                      'lbl_arr_ps',
                      'val_arrPlace',
                      doc['arrestPlace']?.toString() ?? '',
                      expanded: true,
                      maxCharsPerLine: 13,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    flex: 3,
                    child: buildInlineFieldWithMLbl(
                      'Dist.',
                      'lbl_arr_dist',
                      'val_arrDist',
                      doc['arrestDist']?.toString() ?? '',
                      expanded: true,
                      maxCharsPerLine: 15,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    flex: 3,
                    child: buildInlineFieldWithMLbl(
                      'State.',
                      'lbl_arr_state',
                      'val_arrState',
                      doc['arrestState']?.toString() ?? '',
                      expanded: true,
                      maxCharsPerLine: 15,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // 3. Court name
              buildInlineFieldWithMLbl(
                '3. Name of the Court ( if surrendered) :- ',
                'lbl_court',
                'val_court',
                doc['courtName']?.toString() ?? '',
                expanded: true,
                minLines: 2,
                maxCharsPerLine: 45,
              ),
              pw.SizedBox(height: 8),

              // 4. Acts and sections
              buildInlineFieldWithMLbl(
                '4. Acts and sections:- ',
                'lbl_acts',
                'val_acts',
                doc['actsSections']?.toString() ?? '',
                expanded: true,
                minLines: 2,
                maxCharsPerLine: 45,
              ),
              pw.SizedBox(height: 10),

              // 5. Arrest status
              pw.Row(
                children: [
                  pw.Text('5) ', style: englishBold),
                  mLbl('lbl_5_title'),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  check(
                    'Arrested and forward',
                    doc['arrestedAndForwarded'] == true,
                  ),
                  check(
                    'Arrested and released on bail or PR bound',
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
              pw.SizedBox(height: 10),

              // 6. Particulars of the Accused
              pw.Row(
                children: [
                  pw.Text('6) Particulars of the Accused :- ', style: englishBold),
                  mLbl('lbl_6_title'),
                ],
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    buildInlineFieldWithMLbl(
                      '(i) Name (नांव) :- ',
                      'lbl_6i',
                      'val_accName',
                      doc['accusedName']?.toString() ?? '',
                      expanded: true,
                      minLines: 2,
                      maxCharsPerLine: 50,
                    ),
                    pw.SizedBox(height: 4),
                    buildInlineFieldWithMLbl(
                      '(ii) Father\'s/Husband\'s/Guardian\'s Name :- ',
                      'lbl_6ii',
                      'val_accFather',
                      doc['accusedFather']?.toString() ?? '',
                      expanded: true,
                      minLines: 2,
                      maxCharsPerLine: 45,
                    ),
                    pw.SizedBox(height: 4),
                    buildInlineFieldWithMLbl(
                      '(iii) First Alias (पहिले टोपण नांव) :- ',
                      'lbl_6iii',
                      'val_accAlias1',
                      doc['accusedAlias1']?.toString() ?? '',
                      expanded: true,
                      maxCharsPerLine: 40,
                    ),
                    pw.SizedBox(height: 4),
                    buildInlineFieldWithMLbl(
                      '(iv) Second Alias (दुसरे टोपण नांव) :- ',
                      'lbl_6iv',
                      'val_accAlias2',
                      doc['accusedAlias2']?.toString() ?? '',
                      expanded: true,
                      maxCharsPerLine: 40,
                    ),
                    pw.SizedBox(height: 4),
                    buildInlineFieldWithMLbl(
                      '(v) Nationality (राष्ट्रीयत्व) :- ',
                      'lbl_6v',
                      'val_accNat',
                      doc['accusedNationality']?.toString() ?? '',
                      expanded: true,
                      maxCharsPerLine: 40,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: buildInlineFieldWithMLbl(
                            '(vi) (a) Voter ID Card No: - ',
                            'lbl_6vi_a',
                            'val_accVoter',
                            doc['accusedVoter']?.toString() ?? '',
                            expanded: true,
                            maxCharsPerLine: 18,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: buildInlineFieldWithMLbl(
                            '(b) *Passport No: - ',
                            'lbl_6vi_b',
                            'val_accPass',
                            doc['accusedPassport']?.toString() ?? '',
                            expanded: true,
                            maxCharsPerLine: 18,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: buildInlineFieldWithMLbl(
                            '(c) Date of issue :- ',
                            'lbl_6vi_c',
                            'val_accDateIss',
                            doc['accusedDateIssue']?.toString() ?? '',
                            expanded: true,
                            maxCharsPerLine: 18,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: buildInlineFieldWithMLbl(
                            '(d) *Place of Issue :- ',
                            'lbl_6vi_d',
                            'val_accPlaceIss',
                            doc['accusedPlaceIssue']?.toString() ?? '',
                            expanded: true,
                            maxCharsPerLine: 18,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: buildInlineFieldWithMLbl(
                            '(vii) Religion: - ',
                            'lbl_6vii',
                            'val_accRelig',
                            doc['accusedReligion']?.toString() ?? '',
                            expanded: true,
                            maxCharsPerLine: 18,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: buildInlineFieldWithMLbl(
                            '(viii) *Cast/Tribe: - ',
                            'lbl_6viii',
                            'val_accCaste',
                            doc['accusedCaste']?.toString() ?? '',
                            expanded: true,
                            maxCharsPerLine: 18,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: buildInlineFieldWithMLbl(
                            '(ix) SC/ST/OBC :- ',
                            'lbl_6ix',
                            'val_accScSt',
                            doc['accusedScSt']?.toString() ?? '',
                            expanded: true,
                            maxCharsPerLine: 18,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: buildInlineFieldWithMLbl(
                            '(x) *Occupation :- ',
                            'lbl_6x',
                            'val_accOcc',
                            doc['accusedOccupation']?.toString() ?? '',
                            expanded: true,
                            maxCharsPerLine: 18,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    buildInlineFieldWithMLbl(
                      '(xi) Permanent Address :-',
                      'lbl_6xi',
                      'val_permAddr',
                      doc['permAddress']?.toString() ?? '',
                      expanded: true,
                      minLines: 2,
                      maxCharsPerLine: 50,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: buildInlineFieldWithMLbl(
                            'State :-',
                            'lbl_state',
                            'val_permState',
                            doc['permState']?.toString() ?? '',
                            expanded: true,
                            maxCharsPerLine: 16,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: buildInlineFieldWithMLbl(
                            'Dist.:-',
                            'lbl_dist2',
                            'val_permDist',
                            doc['permDist']?.toString() ?? '',
                            expanded: true,
                            maxCharsPerLine: 16,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: buildInlineFieldWithMLbl(
                            'P.S. :-',
                            'lbl_ps2',
                            'val_permPs',
                            doc['permPs']?.toString() ?? '',
                            expanded: true,
                            maxCharsPerLine: 16,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    buildInlineFieldWithMLbl(
                      '(xii) Present Address:-',
                      'lbl_6xii',
                      'val_presAddr',
                      doc['presAddress']?.toString() ?? '',
                      expanded: true,
                      minLines: 2,
                      maxCharsPerLine: 50,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: buildInlineFieldWithMLbl(
                            'State: -',
                            'lbl_state',
                            'val_presState',
                            doc['presState']?.toString() ?? '',
                            expanded: true,
                            maxCharsPerLine: 16,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: buildInlineFieldWithMLbl(
                            'Dist.:-',
                            'lbl_dist2',
                            'val_presDist',
                            doc['presDist']?.toString() ?? '',
                            expanded: true,
                            maxCharsPerLine: 16,
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          child: buildInlineFieldWithMLbl(
                            'P.S. :-',
                            'lbl_ps2',
                            'val_presPs',
                            doc['presPs']?.toString() ?? '',
                            expanded: true,
                            maxCharsPerLine: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // 7. Injuries
              pw.Text(
                '7) Injuries, cause of injuries and physical condition of the accused person (indicate if medically examined)',
                style: englishBold,
              ),
              mLbl('lbl_7_m1'),
              pw.SizedBox(height: 2),
              (){
                final injuriesClean = doc['injuries']?.toString().trim() ?? '';
                final injuriesLines = _splitTextIntoLines(injuriesClean, 70);
                final totalInjLines = injuriesLines.length < 2 ? 2 : injuriesLines.length;
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < totalInjLines; i++) ...[
                      if (i > 0) pw.SizedBox(height: 2),
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.only(left: 4, right: 4, bottom: 2),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
                        ),
                        child: cache.has('val_injuries_$i')
                            ? cache.img('val_injuries_$i')
                            : (i == 0 && injuriesLines.length <= 1 && cache.has('val_injuries'))
                                ? cache.img('val_injuries')
                                : pw.Text(
                                    i < injuriesLines.length ? injuriesLines[i] : '',
                                    style: englishStyle,
                                    maxLines: 1,
                                  ),
                      ),
                    ],
                  ],
                );
              }(),
            ],
          );
        },
      ),
    );
  }

  // --- PAGE 2 ---
  if (showsSection('Form 3-B')) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Form: 3-B', style: englishBold),
              ),
              pw.SizedBox(height: 8),

              // 8
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '8) The accused, after being informed of the grounds of arrest and legal rights, was duly taken into custody on :-',
                          style: englishBold,
                        ),
                        mLbl('lbl_8_title'),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: buildInlineFieldWithMLbl(
                      '(date) at :- ',
                      'lbl_8_date',
                      'val_cusDate',
                      doc['custodyDate']?.toString() ?? '',
                      expanded: true,
                      maxCharsPerLine: 18,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: buildInlineFieldWithMLbl(
                      '(hours) at :- ',
                      'lbl_8_hours',
                      'val_cusHours',
                      doc['custodyHours']?.toString() ?? '',
                      expanded: true,
                      maxCharsPerLine: 18,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: buildInlineFieldWithMLbl(
                      '(place). ',
                      'lbl_8_place',
                      'val_cusPlace',
                      doc['custodyPlace']?.toString() ?? '',
                      expanded: true,
                      maxCharsPerLine: 18,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),

              pw.Text(
                'The following article(s) was/were found on physical search conducted on the person of the accused and were taken into possession for which a receipt was given to the accused. **',
                style: englishBold,
              ),
              mLbl('lbl_8_m3'),
              pw.SizedBox(height: 8),

              pw.Row(
                children: [
                  pw.Expanded(
                    child: buildInlineFieldWithMLbl('1) ', 'lbl_art_1', 'val_art1', doc['article1']?.toString() ?? '', expanded: true, maxCharsPerLine: 25),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: buildInlineFieldWithMLbl('2) ', 'lbl_art_2', 'val_art2', doc['article2']?.toString() ?? '', expanded: true, maxCharsPerLine: 25),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: buildInlineFieldWithMLbl('3) ', 'lbl_art_3', 'val_art3', doc['article3']?.toString() ?? '', expanded: true, maxCharsPerLine: 25),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: buildInlineFieldWithMLbl('4) ', 'lbl_art_4', 'val_art4', doc['article4']?.toString() ?? '', expanded: true, maxCharsPerLine: 25),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: buildInlineFieldWithMLbl('5) ', 'lbl_art_5', 'val_art5', doc['article5']?.toString() ?? '', expanded: true, maxCharsPerLine: 25),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: buildInlineFieldWithMLbl('6) ', 'lbl_art_6', 'val_art6', doc['article6']?.toString() ?? '', expanded: true, maxCharsPerLine: 25),
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
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: buildInlineFieldWithMLbl(
                      'Intimation given to Name: ',
                      'lbl_8_m6',
                      'val_intName',
                      doc['intimationName']?.toString() ?? '',
                      expanded: true,
                      maxCharsPerLine: 25,
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: buildInlineFieldWithMLbl(
                      '(Relationship): ',
                      'lbl_8_m7',
                      'val_intRel',
                      doc['intimationRel']?.toString() ?? '',
                      expanded: true,
                      maxCharsPerLine: 25,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '** If no article found, NIL, may be indicated in the bland space provided below:-',
                style: englishBold,
              ),
              mLbl('lbl_8_m8'),
            ],
          );
        },
      ),
    );

    // --- PAGE 3: Physical Features (Landscape) ---
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Form: 3-B (cont.)', style: englishBold),
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
                  'Nose\nनाक',
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
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // --- PAGE 4 ---
  if (showsSection('Form 3-C')) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Form: 3-C', style: englishBold),
              ),
              pw.SizedBox(height: 8),

              // 10
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '10) Whether finger print taken or not? :-',
                        style: englishBold,
                      ),
                      mLbl('lbl_10_m1'),
                    ],
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Container(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
                      ),
                      child: pw.Text(
                        doc['fingerprintTaken'] == true ? 'Yes' : 'No',
                        style: englishStyle,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // 11
              pw.Row(
                children: [
                  pw.Text(
                    '11) Socio-economic profile of the accused showing.',
                    style: englishBold,
                  ),
                  pw.SizedBox(width: 6),
                  mLbl('lbl_11_title'),
                ],
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 16),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '(a) Living Status: - Living alone/Living with Family/with Associate in Pucca House/Hotel/ Hostel/',
                      style: englishBold,
                    ),
                    pw.Text(
                      '                                 Kachcha House / Thatched House / Slum/ Homeless/ Harbourer.',
                      style: englishBold,
                    ),
                    mLbl('lbl_11a_m1'),
                    mLbl('lbl_11a_m2'),
                    pw.Wrap(
                      spacing: 8,
                      runSpacing: 4,
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
                        check('Kachcha House', doc['livingKachcha'] == true),
                        check('Thatched House', doc['livingThatched'] == true),
                        check('Slum', doc['livingSlum'] == true),
                        check('Homeless', doc['livingHomeless'] == true),
                        check('Harbourer', doc['livingHarbourer'] == true),
                      ],
                    ),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      children: [
                        buildInlineFieldWithMLbl(
                          '(b) Educational qualification(s): ',
                          'lbl_11b_m1',
                          'val_edu',
                          doc['eduQual'],
                          width: 120,
                        ),
                        pw.SizedBox(width: 16),
                        buildInlineFieldWithMLbl(
                          '(c) occupation: ',
                          'lbl_11c_m1',
                          'val_occ2',
                          doc['occupation2'],
                          width: 120,
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      '(d) Income Group (उत्पन्न गट) :-',
                      style: englishBold,
                    ),
                    mLbl('lbl_11d_m1'),
                    pw.SizedBox(height: 4),
                    check(
                      '(i) Lower Income (Below Rs. 25000 P.Y.) = कमी उत्पन्न ( द.सा.रू २५००० पेक्ष कमी )',
                      doc['incomeLower'] == true,
                    ),
                    check(
                      '(ii) Lower Middle Income (From Rs. 25001 to 50000) = कमी मध्यम उत्पन्न ( २५००१ ते ५००००)',
                      doc['incomeLowerMid'] == true,
                    ),
                    check(
                      '(iii) Middle Income (From 50001 to 100000) = मध्यम उत्पन्न (२५,००१ ते १००,००० )',
                      doc['incomeMiddle'] == true,
                    ),
                    check(
                      '(iv) Upper Middle Income (/From 100000 to 200000)= उच्च मध्यम उत्पन्न ( १००,००१ ते  २००,०००)',
                      doc['incomeUpperMid'] == true,
                    ),
                    check(
                      '(v) Upper Middle Income (Rs. 200000 to 300000) = उच्च मध्यम उत्पन्न ( २००,००१ ते ३००,०००)',
                      doc['incomeUpperMid2'] == true,
                    ),
                    check(
                      '(vi) Upper Income (above 300000) =SSE = उच्च उत्पन्न ( ३००,०००)',
                      doc['incomeUpper'] == true,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // 12
              pw.Text(
                '12. Whether the accused person as per the observations and known police records:',
                style: englishBold,
              ),
              mLbl('lbl_12_m1'),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 16),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _yesNoRow(
                      '(a) Is dangerous ? (धोकादायक आहे किंवा कसे?)',
                      doc['isDangerous'] == true,
                      englishStyle,
                      englishBold,
                    ),
                    _yesNoRow(
                      '(b) Previously escaped any bail ? ( पुर्वी जामीनावर असतांना पळुन गेला किंवा काय ? )',
                      doc['prevEscaped'] == true,
                      englishStyle,
                      englishBold,
                    ),
                    _yesNoRow(
                      '(c) Is generally armed? ( नेहमी सशस्त्र असतो किंवा नसतो ?)',
                      doc['generallyArmed'] == true,
                      englishStyle,
                      englishBold,
                    ),
                    _yesNoRow(
                      '(d) Operates with accomplices? ( साथीदारासह काम करतो किंवा कसे ? )',
                      doc['operatesWithAccomplices'] == true,
                      englishStyle,
                      englishBold,
                    ),
                    _yesNoRow(
                      '(e) Has past criminal records ? (गुन्हेगारी पार्श्वभुमी आहे किंवा नाही ? )',
                      doc['pastCriminal'] == true,
                      englishStyle,
                      englishBold,
                    ),
                    _yesNoRow(
                      '(f) Is recidivism (वारंवार अपराध करतो किंवा काय ? )',
                      doc['isRecidivism'] == true,
                      englishStyle,
                      englishBold,
                    ),
                    _yesNoRow(
                      '(g) Is likely to escape bail ? (जामीनावर असतांना पळूनजाण्याचा संभव किंवा नाही ? )',
                      doc['likelyToEscape'] == true,
                      englishStyle,
                      englishBold,
                    ),
                    _yesNoRow(
                      '(h) Is released on bail. Likely to commit crime or threaten victims/witnesses.',
                      doc['releasedOnBail'] == true,
                      englishStyle,
                      englishBold,
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 16),
                      child: pw.Text(
                        '(जामीनावर साडल्यास लगेच दुसरा गुन्हा करण्याचा किंवा बळींना/ साक्षेदारांना धाकदपटशा दाखविण्याचा संभव आहे किंवा नाही?)',
                        style: englishStyle,
                      ),
                    ),
                    _yesNoRow(
                      '(i) Is wanted many other case? (दुसऱ्या कोणत्याही प्रकरणात पाहिजे किंवा काय ?)',
                      doc['wantedMany'] == true,
                      englishStyle,
                      englishBold,
                    ),
                    pw.Row(
                      children: [
                        pw.Text(
                          '(If yes give case ref. Sec.) ( जर होय असेल तर त्या प्रकरणाचा संदर्भ व कलमे दयवीत ?)',
                          style: englishStyle,
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
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // 13
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: buildInlineFieldWithMLbl(
                      '13. पंचाची नांवे (1) :',
                      'lbl_13_m1',
                      'val_p1Name',
                      doc['panch1Name'],
                      expanded: true,
                      minLines: 2,
                      maxCharsPerLine: 40,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: buildInlineFieldWithMLbl(
                      'पंचाच्या सहया (1) :',
                      'lbl_13_m2',
                      'val_p1Sig',
                      doc['panch1Sig'],
                      expanded: true,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Name and Address of the witnesses/Panchas\n(At Least one witness necessary)',
                    style: englishBold,
                  ),
                  pw.Text('Signature\n', style: englishBold),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: field(
                      '(2):',
                      'val_p2Name',
                      doc['panch2Name'],
                      expanded: true,
                      minLines: 2,
                      maxCharsPerLine: 40,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: buildInlineFieldWithMLbl(
                      'पंचाच्या सहया (2) :',
                      'lbl_13_m3',
                      'val_p2Sig',
                      doc['panch2Sig'],
                      expanded: true,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Text('(At Least one witness necessary)', style: englishBold),
              pw.SizedBox(height: 16),

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
                        pw.SizedBox(height: 16),
                        field(
                          ':',
                          'val_arrSig',
                          doc['arrestedPersonSig'],
                          width: 150,
                        ),
                        pw.SizedBox(height: 16),
                        pw.Text('15.', style: englishBold),
                        buildInlineFieldWithMLbl(
                          'Place: ',
                          'lbl_15_m1',
                          'val_fPlace',
                          doc['finalPlace'],
                          width: 100,
                        ),
                        pw.SizedBox(height: 8),
                        buildInlineFieldWithMLbl(
                          'Date: ',
                          'lbl_15_m2',
                          'val_fDate',
                          doc['finalDate'],
                          width: 100,
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
                        pw.SizedBox(height: 8),
                        field(
                          'Signature / सही :-',
                          'val_ioSig',
                          doc['ioSig'],
                          width: 150,
                        ),
                        pw.SizedBox(height: 16),
                        buildInlineFieldWithMLbl(
                          'Name: ',
                          'lbl_15_m3',
                          'val_fName',
                          doc['finalName'],
                          width: 150,
                        ),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          children: [
                            buildInlineFieldWithMLbl(
                              'Rank: ',
                              'lbl_15_m4',
                              'val_fRank',
                              doc['finalRank'],
                              width: 80,
                            ),
                            pw.SizedBox(width: 8),
                            buildInlineFieldWithMLbl(
                              'No: ',
                              'lbl_15_m5',
                              'val_fNo',
                              doc['finalNo'],
                              width: 60,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  return pdf.save();
}

pw.Widget _yesNoRow(
  String label,
  bool value,
  pw.TextStyle style,
  pw.TextStyle boldStyle,
) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(child: pw.Text(label, style: style)),
        pw.Text('Yes/No (होय/नाही) ', style: boldStyle),
        pw.Text(value ? '[Yes]' : '[No]', style: style),
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

Future<MarathiImageCache> _preRenderAllMarathi(Map<String, dynamic> doc) async {
  final cache = MarathiImageCache();
  try {
    final headerStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  final marathiLabelStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 9,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  final valueStyle = GoogleFonts.notoSansDevanagari(
    fontSize: 9,
    color: Colors.blue.shade900,
  );

  await GoogleFonts.pendingFonts();

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

  Future<void> addSplitVal(String key, String? val, int maxChars,
      {double maxWidth = 500}) async {
    final text = val?.trim() ?? '';
    if (text.isEmpty) return;
    if (containsDevanagari(text)) {
      final lines = _splitTextIntoLines(text, maxChars);
      for (var i = 0; i < lines.length; i++) {
        if (containsDevanagari(lines[i])) {
          await cache.add('${key}_$i', lines[i], valueStyle,
              maxWidth: maxWidth);
        }
      }
      await cache.add(key, text, valueStyle, maxWidth: maxWidth);
    }
  }

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
    'आरोपीचा सांकेतिक क्रमांक ( पहिल्या ९ व्यक्तींसाठी अ १ ते अ ९, दहाव्या व्यक्तीसाठी ब १ या प्रमाणे पुढे असे लिहावे )',
    marathiLabelStyle,
  );

  await addLbl('lbl_arr_title', 'अटकेची / स्वाधीन होण्याची तारीख वेळ', marathiLabelStyle);
  await addLbl('lbl_arr_date', 'दिनांक', marathiLabelStyle);
  await addLbl('lbl_arr_time', 'वेळ', marathiLabelStyle);
  await addLbl('lbl_arr_gd', 'ठाणे दैनंदिन क्रमांक', marathiLabelStyle);
  await addLbl('lbl_arr_ps', 'अटकेची जागा : पोलीस ठाणे', marathiLabelStyle);
  await addLbl('lbl_arr_dist', 'जिल्हा', marathiLabelStyle);
  await addLbl('lbl_arr_state', 'राज्य', marathiLabelStyle);

  await addLbl(
    'lbl_court',
    'न्यायालयाचे नाव ( स्वाधीन झाल्यास ) :-',
    marathiLabelStyle,
  );
  await addLbl('lbl_acts', 'अधिनियम व कलमे :', marathiLabelStyle);

  await addLbl('lbl_5_title', 'अटक / स्वाधीन स्थिती', marathiLabelStyle);

  await addLbl('lbl_6_title', 'आरोपीचा तपशील', marathiLabelStyle);
  await addLbl('lbl_6i', 'नांव', marathiLabelStyle);
  await addLbl('lbl_6ii', 'वडिलांचे/पतीचे/पालकाचे नांव', marathiLabelStyle);
  await addLbl('lbl_6iii', 'पहिले टोपण नांव', marathiLabelStyle);
  await addLbl('lbl_6iv', 'दुसरे टोपण नांव', marathiLabelStyle);
  await addLbl('lbl_6v', 'राष्ट्रीयत्व', marathiLabelStyle);
  await addLbl('lbl_6vi_a', 'मतदार ओळखपत्र क्र.', marathiLabelStyle);
  await addLbl('lbl_6vi_b', 'पासपोर्ट क्र.', marathiLabelStyle);
  await addLbl('lbl_6vi_c', 'जारी केल्याची तारीख', marathiLabelStyle);
  await addLbl('lbl_6vi_d', 'जारी केल्याचे ठिकाण', marathiLabelStyle);
  await addLbl('lbl_6vii', 'धर्म', marathiLabelStyle);
  await addLbl('lbl_6viii', 'जात/आदिवासी', marathiLabelStyle);
  await addLbl('lbl_6ix', 'अ.जा./अ.ज.ज./OBC', marathiLabelStyle);
  await addLbl('lbl_6x', 'व्यवसाय', marathiLabelStyle);
  await addLbl('lbl_6xi', 'स्थायी पत्ता', marathiLabelStyle);
  await addLbl('lbl_state', 'राज्य', marathiLabelStyle);
  await addLbl('lbl_dist2', 'जिल्हा', marathiLabelStyle);
  await addLbl('lbl_ps2', 'पो.स्टे.', marathiLabelStyle);
  await addLbl('lbl_6xii', 'सध्याचा पत्ता', marathiLabelStyle);

  await addLbl(
    'lbl_7_m1',
    'आरोपीच्या जखमा, जखमांचे कारण व शारीरिक स्थिती (वैद्यकीय तपासणी झाली असल्यास नमूद करावे)',
    marathiLabelStyle,
  );

  // Page 2
  await addLbl(
    'lbl_8_title',
    'अटकेचे कारण व कायदेशीर हक्क समजावून आरोपी योग्यरित्या ताब्यात घेतला',
    marathiLabelStyle,
  );
  await addLbl('lbl_8_date', 'दिनांक', marathiLabelStyle);
  await addLbl('lbl_8_hours', 'वेळ', marathiLabelStyle);
  await addLbl('lbl_8_place', 'ठिकाण', marathiLabelStyle);
  await addLbl(
    'lbl_8_m3',
    'आरोपीच्या अंगझडतीमध्ये खालील वस्तु आढळल्या. त्या ताब्यात घेण्यात आल्या आणि त्या बद्दल त्याची पोच देण्यात आली.',
    marathiLabelStyle,
  );
  await addLbl('lbl_art_1', '१', marathiLabelStyle);
  await addLbl('lbl_art_2', '२', marathiLabelStyle);
  await addLbl('lbl_art_3', '३', marathiLabelStyle);
  await addLbl('lbl_art_4', '४', marathiLabelStyle);
  await addLbl('lbl_art_5', '५', marathiLabelStyle);
  await addLbl('lbl_art_6', '६', marathiLabelStyle);
  await addLbl(
    'lbl_8_m4',
    'मानवी प्रतिष्ठेसाठी व शरीर झाकण्यासाठी आरोपीच्या अंगावर आवश्यक तेवढे कपडे ठेवण्यात आले होते.',
    marathiLabelStyle,
  );
  await addLbl(
    'lbl_8_m5',
    'ओळख पटण्याच्या प्रयोजनासाठी आरोपीला स्वतःला झाकुन घेण्याची ताकीद देण्यात आली होती.',
    marathiLabelStyle,
  );
  await addLbl('lbl_8_m6', 'सूचना दिली — नांव', marathiLabelStyle);
  await addLbl('lbl_8_m7', 'नाते', marathiLabelStyle);
  await addLbl(
    'lbl_8_m8',
    'जर कोणतीही वस्तु आढळली नाही तर खालील जागेत नाही असे नमुद करावे.',
    marathiLabelStyle,
  );

  await addLbl(
    'lbl_9_m1',
    'आरोपीची शारीरिक वैशिष्ट्ये, व्यंग व इतर तपशील',
    marathiLabelStyle,
  );

  // Page 3
  await addLbl(
    'lbl_10_m1',
    'बोटांचे ठसे घेतले किंवा नाही',
    marathiLabelStyle,
  );
  await addLbl('lbl_11_title', 'आरोपीचे सामाजिक-आर्थिक प्रोफाइल', marathiLabelStyle);
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
  await addLbl('lbl_11b_m1', 'शैक्षणिक पात्रता', marathiLabelStyle);
  await addLbl('lbl_11c_m1', 'व्यवसाय', marathiLabelStyle);
  await addLbl('lbl_11d_m1', ' उत्पन्न गट ', marathiLabelStyle);
  await addLbl(
    'lbl_12_m1',
    'निरीक्षणावरून आणि माहिती असलेल्या पोलीस अभिलेखानुसार आरोपी :-',
    marathiLabelStyle,
  );

  await addLbl('lbl_13_m1', 'पंचाची नांवे (1) :', marathiLabelStyle);
  await addLbl('lbl_13_m2', 'पंचाच्या सहया (1) :', marathiLabelStyle);
  await addLbl('lbl_13_m3', 'पंचाच्या सहया (2) :', marathiLabelStyle);

  await addLbl('lbl_14_m1', 'आरोपीची सही व आरोपीचा व अंगठा', marathiLabelStyle);

  await addLbl('lbl_15_m1', 'ठिकाण', marathiLabelStyle);
  await addLbl('lbl_15_m2', 'तारीख', marathiLabelStyle);
  await addLbl(
    'lbl_15_m3',
    FormIoTerminology.signatureHeader,
    marathiLabelStyle,
  );
  await addLbl('lbl_15_m4', FormIoTerminology.rank, marathiLabelStyle);
  await addLbl('lbl_15_m5', 'क्रमांक', marathiLabelStyle);

  // Table Headers
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
        // use j+1 because header lines loop starts at 1 if lines.length > 1
        await cache.add(
          'tbl_h_${entry.key}_${j + 1}',
          entry.value[j],
          tblHeaderStyle,
        );
      }
    }
  }

  // Values — cache keys must match renderText valKey arguments in the PDF layout
  const valueKeyMap = <String, String>{
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
  };

  for (final entry in valueKeyMap.entries) {
    await addVal(entry.key, doc[entry.value]?.toString());
  }

  await addSplitVal('val_dist', doc['dist']?.toString(), 22);
  await addSplitVal('val_ps', doc['ps']?.toString(), 22);
  await addSplitVal('val_fir', doc['firNo']?.toString(), 16);
  await addSplitVal('val_arrPlace', doc['arrestPlace']?.toString(), 13);
  await addSplitVal('val_arrDist', doc['arrestDist']?.toString(), 15);
  await addSplitVal('val_arrState', doc['arrestState']?.toString(), 15);
  await addSplitVal('val_court', doc['courtName']?.toString(), 45);
  await addSplitVal('val_acts', doc['actsSections']?.toString(), 45);
  await addSplitVal('val_accName', doc['accusedName']?.toString(), 50);
  await addSplitVal('val_accFather', doc['accusedFather']?.toString(), 45);
  await addSplitVal('val_accAlias1', doc['accusedAlias1']?.toString(), 40);
  await addSplitVal('val_accAlias2', doc['accusedAlias2']?.toString(), 40);
  await addSplitVal('val_accNat', doc['accusedNationality']?.toString(), 40);
  await addSplitVal('val_accVoter', doc['accusedVoter']?.toString(), 18);
  await addSplitVal('val_accPass', doc['accusedPassport']?.toString(), 18);
  await addSplitVal('val_accDateIss', doc['accusedDateIssue']?.toString(), 18);
  await addSplitVal('val_accPlaceIss', doc['accusedPlaceIssue']?.toString(), 18);
  await addSplitVal('val_accRelig', doc['accusedReligion']?.toString(), 18);
  await addSplitVal('val_accCaste', doc['accusedCaste']?.toString(), 18);
  await addSplitVal('val_accScSt', doc['accusedScSt']?.toString(), 18);
  await addSplitVal('val_accOcc', doc['accusedOccupation']?.toString(), 18);
  await addSplitVal('val_permAddr', doc['permAddress']?.toString(), 50);
  await addSplitVal('val_permState', doc['permState']?.toString(), 16);
  await addSplitVal('val_permDist', doc['permDist']?.toString(), 16);
  await addSplitVal('val_permPs', doc['permPs']?.toString(), 16);
  await addSplitVal('val_presAddr', doc['presAddress']?.toString(), 50);
  await addSplitVal('val_presState', doc['presState']?.toString(), 16);
  await addSplitVal('val_presDist', doc['presDist']?.toString(), 16);
  await addSplitVal('val_presPs', doc['presPs']?.toString(), 16);
  await addSplitVal('val_injuries', doc['injuries']?.toString(), 70);
  await addSplitVal('val_cusPlace', doc['custodyPlace']?.toString(), 18);
  await addSplitVal('val_art1', doc['article1']?.toString(), 25);
  await addSplitVal('val_art2', doc['article2']?.toString(), 25);
  await addSplitVal('val_art3', doc['article3']?.toString(), 25);
  await addSplitVal('val_art4', doc['article4']?.toString(), 25);
  await addSplitVal('val_art5', doc['article5']?.toString(), 25);
  await addSplitVal('val_art6', doc['article6']?.toString(), 25);
  await addSplitVal('val_intName', doc['intimationName']?.toString(), 25);
  await addSplitVal('val_intRel', doc['intimationRel']?.toString(), 25);
  await addSplitVal('val_otherFeatures', doc['otherFeatures']?.toString(), 70);
  await addSplitVal('val_edu', doc['eduQual']?.toString(), 35);
  await addSplitVal('val_occ2', doc['occupation2']?.toString(), 35);
  await addSplitVal('val_caseRef', doc['caseRefSec']?.toString(), 60);
  await addSplitVal('val_p1Name', doc['panch1Name']?.toString(), 40);
  await addSplitVal('val_p2Name', doc['panch2Name']?.toString(), 40);
  await addSplitVal('val_p1Sig', doc['panch1Sig']?.toString(), 40);
  await addSplitVal('val_p2Sig', doc['panch2Sig']?.toString(), 40);
  await addSplitVal('val_arrSig', doc['arrestedPersonSig']?.toString(), 40);
  await addSplitVal('val_ioSig', doc['ioSig']?.toString(), 40);
  await addSplitVal('val_fPlace', doc['finalPlace']?.toString(), 30);
  await addSplitVal('val_fDate', doc['finalDate']?.toString(), 30);
  await addSplitVal('val_fName', doc['finalName']?.toString(), 30);
  await addSplitVal('val_fRank', doc['finalRank']?.toString(), 25);
  await addSplitVal('val_fNo', doc['finalNo']?.toString(), 25);

  // Table values
  if (doc['physTable'] is Map) {
    final pt = doc['physTable'] as Map<String, dynamic>;
    for (int i = 1; i <= 26; i++) {
      await addVal('tbl_v_$i', pt[i.toString()]);
    }
  }
  } catch (_) {}

  return cache;
}
