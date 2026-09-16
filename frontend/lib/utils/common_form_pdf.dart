// lib/utils/common_form_pdf.dart
// Universal PDF for Khakhi Diary: CommonForm 17 sections + arbitrary extraMap.
// No screen imports, no Firebase.

import 'dart:typed_data';

// ignore_for_file: unused_shown_name
// Imports match project spec (`show BuildContext, TimeOfDay`); TimeOfDay is unused in this utility.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show BuildContext, TimeOfDay;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../screens/ad_form_screen.dart' show ACT_DATA;
import 'pdf_layout_constants.dart';
import 'pdf_unicode_fonts.dart';

// ══════════════════════════════════════════════════════════════════════════════
// COLORS & TOKENS (derived from PdfLayoutConstants)
// ══════════════════════════════════════════════════════════════════════════════

const _dark = PdfLayoutConstants.colorDark;
const _teal = PdfLayoutConstants.colorTeal;
const _green = PdfLayoutConstants.colorGreen;
const _red = PdfLayoutConstants.colorRed;
const _amber = PdfLayoutConstants.colorAmber;
const _sec = PdfLayoutConstants.colorSecondary;
const _muted = PdfLayoutConstants.colorMuted;
const _bg = PdfLayoutConstants.colorRowAltBg;
const _border = PdfLayoutConstants.colorBorder;
const _headerBg = PdfLayoutConstants.colorHeaderBg;
const _white = PdfLayoutConstants.colorWhite;

// ══════════════════════════════════════════════════════════════════════════════
// MAIN ENTRY POINTS
// ══════════════════════════════════════════════════════════════════════════════

/// Preview + share PDF. Call from any screen.
/// [commonMap] - CommonFormState.buildDocumentMap()
/// [extraMap] - Any extra fields from your form screen (optional, pass {} if none)
/// [formTitle] - e.g. 'CR FORM', 'AD FORM', 'VI FORM', 'DISPOSAL FORM'
/// [formSubtitle] - e.g. 'Crime Registration - Maharashtra Police'
Future<void> previewFormPdf(
  BuildContext context,
  Map<String, dynamic> commonMap, {
  Map<String, dynamic> extraMap = const {},
  String formTitle = 'CASE FORM',
  String formSubtitle = 'Khakhi Diary - Maharashtra Police',
}) async {
  if (!context.mounted) return;
  final bytes = await generateFormPdf(
    commonMap,
    extraMap: extraMap,
    formTitle: formTitle,
    formSubtitle: formSubtitle,
  );
  if (!context.mounted) return;
  final fileName =
      '${formTitle.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
  try {
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } else {
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);
    }
  } catch (_) {
    // Fallback path if browser print popup is blocked or layoutPdf fails.
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }
}

/// Returns raw PDF bytes. Save to file or share.
Future<Uint8List> generateFormPdf(
  Map<String, dynamic> commonMap, {
  Map<String, dynamic> extraMap = const {},
  String formTitle = 'CASE FORM',
  String formSubtitle = 'Khakhi Diary - Maharashtra Police',
}) async {
  final unicodeTheme = await PdfUnicodeFonts.openSansTheme();
  final pdf = pw.Document(theme: unicodeTheme);

  pdf.addPage(
    pw.MultiPage(
      maxPages: 1000,
      pageFormat: PdfPageFormat.a4,
      margin: PdfLayoutConstants.pageMargin,
      header: (ctx) => ctx.pageNumber == 1
          ? _header(ctx, formTitle, formSubtitle)
          : pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 6),
              padding: const pw.EdgeInsets.only(bottom: 3),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: _border,
                    width: PdfLayoutConstants.borderWidth,
                  ),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    _cleanText('$formTitle — $formSubtitle'),
                    style: const pw.TextStyle(
                      fontSize: PdfLayoutConstants.footerFontSize,
                      color: _sec,
                    ),
                  ),
                  pw.Text(
                    'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                    style: const pw.TextStyle(
                      fontSize: PdfLayoutConstants.footerFontSize,
                      color: _sec,
                    ),
                  ),
                ],
              ),
            ),
      footer: (ctx) => _footer(ctx),
      build: (_) => _buildAll(commonMap, extraMap),
    ),
  );

  return pdf.save();
}

// ══════════════════════════════════════════════════════════════════════════════
// HEADER & FOOTER
// ══════════════════════════════════════════════════════════════════════════════

pw.Widget _header(pw.Context ctx, String title, String subtitle) =>
    pw.Container(
      margin: const pw.EdgeInsets.only(bottom: PdfLayoutConstants.sectionGap),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: _border,
            width: PdfLayoutConstants.borderWidthBold,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _cleanText(title),
                style: pw.TextStyle(
                  fontSize: PdfLayoutConstants.titleFontSize,
                  fontWeight: pw.FontWeight.bold,
                  color: _dark,
                ),
              ),
              pw.SizedBox(height: 1.5),
              pw.Text(
                _cleanText(subtitle),
                style: const pw.TextStyle(
                  fontSize: PdfLayoutConstants.subtitleFontSize,
                  color: _sec,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: _red,
                    width: PdfLayoutConstants.borderWidth,
                  ),
                  borderRadius: pw.BorderRadius.circular(2),
                ),
                child: pw.Text(
                  'CONFIDENTIAL',
                  style: pw.TextStyle(
                    fontSize: PdfLayoutConstants.footerFontSize,
                    fontWeight: pw.FontWeight.bold,
                    color: _red,
                  ),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Date: ${_now()}',
                style: const pw.TextStyle(
                  fontSize: PdfLayoutConstants.footerFontSize,
                  color: _sec,
                ),
              ),
            ],
          ),
        ],
      ),
    );

pw.Widget _footer(pw.Context ctx) => pw.Container(
      margin: const pw.EdgeInsets.only(top: 6),
      padding: const pw.EdgeInsets.only(top: 3),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: _border,
            width: PdfLayoutConstants.borderWidth,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Khakhi Diary · Crime Monitoring & Case Record System',
            style: const pw.TextStyle(
              fontSize: PdfLayoutConstants.footerFontSize,
              color: _sec,
            ),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(
              fontSize: PdfLayoutConstants.footerFontSize,
              color: _sec,
            ),
          ),
        ],
      ),
    );

// ══════════════════════════════════════════════════════════════════════════════
// MASTER CONTENT BUILDER
// ══════════════════════════════════════════════════════════════════════════════

List<pw.Widget> _buildAll(Map<String, dynamic> m, Map<String, dynamic> extra) {
  final sections = <pw.Widget>[];
  final isUnknown = m['isUnknownUntraced'] == true;
  final extraMap = Map<String, dynamic>.from(extra);

  final bool isMurder = m['isMurderCase'] == true ||
      (m['deceased'] is Map &&
          ((m['deceased'] as Map)['name']?.toString().trim().isNotEmpty == true ||
           (m['deceased'] as Map)['mobile']?.toString().trim().isNotEmpty == true ||
           (m['deceased'] as Map)['aadhaar']?.toString().trim().isNotEmpty == true));
  final bool isPocso = m['isPocsoCase'] == true;

  // ── §1 Crime Registration ─────────────────────────────────────────────────
  sections.add(
    _card(
      1,
      'CRIME REGISTRATION INFO',
      _teal,
      _grid2([
        _f('Cr. No.', _v(m['crNo'])),
        _f('Registered Date', _v(m['regDate'])),
        _f('Unknown / Untraced', isUnknown ? 'Yes' : 'No'),
        _f('FIR Copy', _v(m['firCopyPath'], or: 'Not uploaded'), full: true),
      ]),
    ),
  );

  // ── §2 Acts & Sections Filed ───────────────────────────────────────────────
  final charges = m['charges'] as Map? ?? {};
  sections.add(
    _card(
      2,
      'ACTS & SECTIONS FILED',
      _teal,
      charges.isEmpty
          ? _empty('No charges added.')
          : pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: charges.entries.toList().asMap().entries.map((e) {
                final chargeNum = e.key + 1;
                final data = e.value.value as Map? ?? {};
                final act = _v(data['act']);
                final secs = (data['sections'] as List?)
                        ?.map((s) => s.toString())
                        .toList() ??
                    [];
                return _chargeBlock(chargeNum, act, secs);
              }).toList(),
            ),
    ),
  );

  // ── §3 Crime Spot ─────────────────────────────────────────────────────────
  sections.add(
    _card(
      3,
      'CRIME SPOT',
      _teal,
      _grid2([
        _f('Village / Town', _v(m['spotVillage'])),
        _f('Area Name', _v(m['spotArea'])),
        _f('Full Address', _v(m['spotAddress']), full: true),
      ]),
    ),
  );

  final List<_FD> propWidgets = [];

  final spList = m['stolenProperties'] as List?;
  if (spList != null && spList.isNotEmpty) {
    for (int i = 0; i < spList.length; i++) {
      final item = spList[i] as Map;
      propWidgets.add(
          _f('Stolen Property #${i + 1}', _v(item['property']), full: true));
      if (_v(item['quantity']).isNotEmpty) {
        propWidgets.add(_f('Quantity', _v(item['quantity'])));
      }
      if (_v(item['estValue']).isNotEmpty) {
        propWidgets.add(_f('Est. Value', _v(item['estValue'])));
      }
      if (_v(item['id']).isNotEmpty) {
        propWidgets.add(_f('ID / Serial No.', _v(item['id'])));
      }
      if (_v(item['date']).isNotEmpty) {
        propWidgets.add(_f('Date & Time', _v(item['date'])));
      }
      if (_v(item['from']).isNotEmpty) {
        propWidgets.add(_f('Stolen From', _v(item['from'])));
      }
    }
  } else if (m['stolenProperty'] != null) {
    final prop = _v(m['stolenProperty']['property']).isNotEmpty
        ? _v(m['stolenProperty']['property'])
        : _v(m['stolenProperty']['description']);
    if (prop.isNotEmpty) {
      propWidgets.add(_f('Description', prop, full: true));
    }
    if (_v(m['stolenProperty']['quantity']).isNotEmpty) {
      propWidgets.add(_f('Quantity', _v(m['stolenProperty']['quantity'])));
    }
    if (_v(m['stolenProperty']['estValue']).isNotEmpty) {
      propWidgets.add(_f('Est. Value', _v(m['stolenProperty']['estValue'])));
    }
    if (_v(m['stolenProperty']['id']).isNotEmpty) {
      propWidgets.add(_f('ID / Serial No.', _v(m['stolenProperty']['id'])));
    }
    if (_v(m['stolenProperty']['date']).isNotEmpty) {
      propWidgets.add(_f('Date & Time', _v(m['stolenProperty']['date'])));
    }
    if (_v(m['stolenProperty']['from']).isNotEmpty) {
      propWidgets.add(_f('Stolen From', _v(m['stolenProperty']['from'])));
    }
  }

  final rpList = m['recoveredProperties'] as List?;
  if (rpList != null && rpList.isNotEmpty) {
    for (int i = 0; i < rpList.length; i++) {
      final item = rpList[i] as Map;
      propWidgets.add(
          _f('Recovered Property #${i + 1}', _v(item['property']), full: true));
      if (_v(item['quantity']).isNotEmpty) {
        propWidgets.add(_f('Quantity', _v(item['quantity'])));
      }
      if (_v(item['estValue']).isNotEmpty) {
        propWidgets.add(_f('Est. Value', _v(item['estValue'])));
      }
      if (_v(item['date']).isNotEmpty) {
        propWidgets.add(_f('Date & Time', _v(item['date'])));
      }
      if (_v(item['from']).isNotEmpty) {
        propWidgets.add(_f('Recovered From', _v(item['from'])));
      }
    }
  } else {
    final prop = m['recoveredProperty'] != null
        ? _v(m['recoveredProperty']['property'])
        : (m['stolenProperty'] != null
            ? _v(m['stolenProperty']['recovered'])
            : '');
    if (prop.isNotEmpty) {
      propWidgets.add(_f('Recovered Property', prop, full: true));
    }
    if (m['recoveredProperty'] != null) {
      if (_v(m['recoveredProperty']['quantity']).isNotEmpty) {
        propWidgets.add(_f('Quantity', _v(m['recoveredProperty']['quantity'])));
      }
      if (_v(m['recoveredProperty']['estValue']).isNotEmpty) {
        propWidgets
            .add(_f('Est. Value', _v(m['recoveredProperty']['estValue'])));
      }
      if (_v(m['recoveredProperty']['date']).isNotEmpty) {
        propWidgets.add(_f('Date & Time', _v(m['recoveredProperty']['date'])));
      }
      if (_v(m['recoveredProperty']['from']).isNotEmpty) {
        propWidgets
            .add(_f('Recovered From', _v(m['recoveredProperty']['from'])));
      }
    }
  }

  if (!isPocso || propWidgets.isNotEmpty) {
    sections.add(
      _card(
        4,
        'STOLEN & RECOVERED PROPERTY',
        _teal,
        propWidgets.isEmpty
            ? _empty('No stolen or recovered property recorded.')
            : _grid2(propWidgets),
      ),
    );
  }

  // ── MODULE EXTRA SECTIONS (auto between Crime Spot and Complainant) ───────
  final middleExtras = <String, dynamic>{};
  for (final e in extraMap.entries.toList()) {
    if (e.key.toLowerCase().endsWith('_extra')) {
      middleExtras[e.key] = e.value;
      extraMap.remove(e.key);
    }
  }
  if (middleExtras.isNotEmpty) {
    sections.add(_extraSection(middleExtras));
  }

  // ── §5 Complainant KYC ────────────────────────────────────────────────────
  final comp = m['complainant'] as Map? ?? {};
  final bool isSexualComp = m['isSexualOffence'] == true ||
      (comp['name']?.toString().contains('Protected') ?? false);
  sections.add(
    _card(
      5,
      'COMPLAINANT KYC',
      _teal,
      comp.isEmpty
          ? _empty('No complainant data.')
          : _grid2([
              _f(
                'Name',
                isSexualComp
                    ? '[Victim Identity Protected - Sec 228A IPC / Sec 72 BNS]'
                    : _v(comp['name']),
              ),
              _f('Age', _v(comp['age'])),
              _f('Gender', _v(comp['gender'])),
              _f('Occupation', _v(comp['occ'])),
              _f('Mobile', _v(comp['mobile'])),
              _f('Aadhaar', _v(comp['aadhaar'])),
              _f('Religion', _v(comp['religion'])),
              _f('Caste', _v(comp['caste'])),
              _f('PAN Number', _v(comp['pan'])),
            ]),
    ),
  );

  // ── §6 Victim KYC ──────────────────────────────────────────────────────────
  final victim = m['victim'] as Map? ?? {};
  if (!isPocso || victim.isNotEmpty) {
    sections.add(
      _card(
        6,
        'VICTIM KYC',
        _teal,
        victim.isEmpty
            ? _empty('No victim data.')
            : _grid2([
                _f('Name', _v(victim['name'])),
                _f('Age', _v(victim['age'])),
                _f('Gender', _v(victim['gender'])),
                _f('Occupation', _v(victim['occ'])),
                _f('Mobile', _v(victim['mobile'])),
                _f('Aadhaar', _v(victim['aadhaar'])),
                _f('Religion', _v(victim['religion'])),
                _f('Caste', _v(victim['caste'])),
                _f('PAN Number', _v(victim['pan'])),
              ]),
      ),
    );
  }

  // ── §7 Deceased KYC (Murder Cases) ─────────────────────────────────────────
  final deceased = m['deceased'] as Map? ?? {};
  if (isMurder || deceased.isNotEmpty) {
    sections.add(
      _card(
        7,
        'DECEASED KYC',
        _teal,
        deceased.isEmpty
            ? _empty('No deceased data.')
            : _grid2([
                _f('Name', _v(deceased['name'])),
                _f('Age', _v(deceased['age'])),
                _f('Gender', _v(deceased['gender'])),
                _f('Occupation', _v(deceased['occ'])),
                _f('Mobile', _v(deceased['mobile'])),
                _f('Aadhaar', _v(deceased['aadhaar'])),
                _f('Religion', _v(deceased['religion'])),
                _f('Caste', _v(deceased['caste'])),
                _f('PAN Number', _v(deceased['pan'])),
              ]),
      ),
    );
  }

  // ── §7 / §8 Injured Person KYC ─────────────────────────────────────────────
  final inj = m['injured'] as Map? ?? {};
  final hasInj = inj.isNotEmpty &&
      (inj['name']?.toString().trim().isNotEmpty == true ||
          inj['mobile']?.toString().trim().isNotEmpty == true ||
          inj['aadhaar']?.toString().trim().isNotEmpty == true ||
          inj['age']?.toString().trim().isNotEmpty == true);
  if (!isPocso || hasInj) {
    final isDied = inj['isDied'] == true;
    sections.add(
      _card(
        isMurder ? 8 : 7,
        'INJURED PERSON KYC',
        _teal,
        !hasInj
            ? _empty('No injured person data.')
            : _grid2([
                _f('Name', _v(inj['name'])),
                _f('Age', _v(inj['age'])),
                _f('Gender', _v(inj['gender'])),
                _f('Occupation', _v(inj['occ'])),
                _f('Mobile', _v(inj['mobile'])),
                _f('Aadhaar', _v(inj['aadhaar'])),
                _f('Religion', _v(inj['religion'])),
                _f('Caste', _v(inj['caste'])),
                _f('PAN Number', _v(inj['pan'])),
                _f('Person Status', isDied ? 'Died / Deceased (मयत)' : 'Alive'),
                if (isDied) ...[
                  _f('Date of Death', _v(inj['deathDate'])),
                  _f('Time of Death', _v(inj['deathTime'])),
                ],
              ]),
      ),
    );
  }

  // ── §8 / §9 Accused Details ────────────────────────────────────────────────
  final accusedList = (m['accused'] as List?) ?? [];
  sections.add(
    _card(
      isMurder ? 9 : 8,
      'ACCUSED DETAILS',
      _teal,
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (isUnknown) _badge('Unknown / Untraced', _amber),
          if (!isUnknown)
            accusedList.isEmpty
                ? _empty('No accused added.')
                : pw.Column(
                    children: accusedList
                        .asMap()
                        .entries
                        .map(
                          (e) => _personBlock(
                            'Accused #${e.key + 1}',
                            Map<String, dynamic>.from(e.value as Map),
                          ),
                        )
                        .toList(),
                  ),
        ],
      ),
    ),
  );

  // ── §9 / §10 Suspected Accused ──────────────────────────────────────────────
  final suspectedList = (m['suspectedAccused'] as List?) ?? [];
  sections.add(
    _card(
      isMurder ? 10 : 9,
      'SUSPECTED ACCUSED',
      _teal,
      isUnknown
          ? _badge('Hidden - Unknown/Untraced ON', _muted)
          : suspectedList.isEmpty
              ? _empty('No suspected accused added.')
              : pw.Column(
                  children: suspectedList
                      .asMap()
                      .entries
                      .map(
                        (e) => _personBlock(
                          'Suspected #${e.key + 1}',
                          Map<String, dynamic>.from(e.value as Map),
                        ),
                      )
                      .toList(),
                ),
    ),
  );

  // ── §10 / §11 Unidentified Criminal Description ───────────────────────────
  final unidentifiedList = (m['unidentifiedList'] as List?) ?? [];
  sections.add(
    _card(
      isMurder ? 11 : 10,
      'UNIDENTIFIED CRIMINAL DESCRIPTION',
      _amber,
      unidentifiedList.isEmpty
          ? _empty('No unidentified criminal added.')
          : pw.Column(
              children: unidentifiedList.asMap().entries.map((e) {
                final u = e.value as Map;
                return _subCard(
                  _grid2([
                    _f('Gender', _v(u['gender'])),
                    _f('Approx Age', _v(u['approxAge'])),
                    _f('Skin Color', _v(u['skinColor'])),
                    _f('Approx Height', _v(u['approxHeight'])),
                    _f('Mobile (if known)', _v(u['mobile'])),
                    _f('Occupation (possible)', _v(u['occupation'])),
                    _f('Last Known Address', _v(u['lastKnownAddress']),
                        full: true),
                    _f('Other Physical Markers', _v(u['otherPhysicalMarkers']),
                        full: true),
                  ]),
                );
              }).toList(),
            ),
    ),
  );

  // ── §11 / §12 Unknown Criminal Description ─────────────────────────────────
  final unknownList = (m['unknownList'] as List?) ?? [];
  sections.add(
    _card(
      isMurder ? 12 : 11,
      'UNKNOWN CRIMINAL DESCRIPTION',
      _amber,
      unknownList.isEmpty
          ? _empty('No unknown criminal added.')
          : pw.Column(
              children: unknownList.asMap().entries.map((e) {
                final u = e.value as Map;
                return _subCard(
                  _grid2([
                    _f('Gender', _v(u['gender'])),
                    _f('Approx Age', _v(u['approxAge'])),
                    _f('Skin Color', _v(u['skinColor'])),
                    _f('Approx Height', _v(u['approxHeight'])),
                    _f('Mobile (if known)', _v(u['mobile'])),
                    _f('Occupation (possible)', _v(u['occupation'])),
                    _f('Last Known Address', _v(u['lastKnownAddress']),
                        full: true),
                    _f('Other Physical Markers', _v(u['otherPhysicalMarkers']),
                        full: true),
                  ]),
                );
              }).toList(),
            ),
    ),
  );

  // ── §12 / §13 Case Responsibility ──────────────────────────────────────────
  final cr8 = m['caseResponsibility'] as Map? ?? {};
  sections.add(
    _card(
      isMurder ? 13 : 12,
      'CASE RESPONSIBILITY',
      _teal,
      _grid2([
        _f('IO Designation', _v(cr8['ioDesig'])),
        _f('IO Name', _v(cr8['ioName'])),
        _f('Reg. By Desig.', _v(cr8['regDesig'])),
        _f('Registrar Name', _v(cr8['regName'])),
        _f('CCTV', _v(cr8['cctvValue'], or: 'Not set')),
        _f('CCTV Date & Time', _v(cr8['cctvDateTime'])),
      ]),
    ),
  );

  // ── §13 / §14 Arrest & Release Status ─────────────────────────────────────
  final arrests = (m['arrestRelease'] as List?) ?? [];
  final sec8283 = m['section8283Action']?.toString();
  sections.add(
    _card(
      isMurder ? 14 : 13,
      'ARREST & RELEASE STATUS',
      _teal,
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _grid2([
            _f(
              'Section 82/83 Action (if untraceable)',
              _v(sec8283, or: 'Not set').toUpperCase(),
              full: true,
            ),
          ]),
          pw.SizedBox(height: 6),
          if (arrests.isEmpty)
            _empty('No arrest records. Add accused names first.')
          else
            pw.Column(
              children: arrests.map((r) {
                final row = r as Map;
                return _subCard(
                  _grid2([
                    _f('Accused Name', _v(row['accusedName'])),
                    _f('Arrest Date & Time', _v(row['arrestDt'])),
                    _f('Release Date', _v(row['releaseDt'])),
                    _f('Arrest Location', _v(row['arrestLoc'])),
                    _f('Arresting Officer', _v(row['arrestOfficer'])),
                    _f('Relative Name', _v(row['relName'])),
                    _f('Relationship', _v(row['relationship'])),
                    _f('Notice Issued?', _v(row['noticeIssued'], or: 'No')),
                    if (_v(row['noticeDt']).isNotEmpty)
                      _f('Notice Date', _v(row['noticeDt'])),
                    if (_v(row['relOnNotice']).isNotEmpty)
                      _f('Released on Notice', _v(row['relOnNotice'])),
                    _f('Wanted / Absconding Status', _v(row['wantedStatus'], or: 'Not Wanted')),
                    _f('Release Type', _v(row['releaseType'])),
                  ]),
                );
              }).toList(),
            ),
        ],
      ),
    ),
  );

  // ── §14 / §15 Procedural Details ──────────────────────────────────────────
  final procChecks = (m['proceduralChecks'] as Map?) ?? {};
  final procDates = (m['proceduralDates'] as Map?) ?? {};
  final vuPdf = (m['vehicleUsage'] as Map?) ?? {};
  const procLabels = {
    'chkPanchSpot': 'Spot Panchanama',
    'chkMemo': 'Memorandum Panchanama',
    'chkInquest': 'Inquest Panchanama',
    'chkIdent': 'Identification Panchanama',
    'chkSearch': 'Search Panchanama',
    'chkPersSearch': 'Personal Search Panchanama',
    'chkIdParade': 'Identification Parade Panchanama',
    'chkExhumation': 'Exhumation Panchanama',
  };

  final selectedProcedural = <_FD>[];
  for (final e in procLabels.entries) {
    if (procChecks[e.key] == true || _v(procDates[e.key]).isNotEmpty) {
      final dateVal = _v(procDates[e.key], or: 'Selected (Date not recorded)');
      selectedProcedural.add(_f(e.value, dateVal));
    }
  }

  sections.add(
    _card(
      isMurder ? 15 : 14,
      'PROCEDURAL DETAILS',
      _teal,
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (selectedProcedural.isEmpty)
            _empty('No procedural panchanama selected.')
          else
            _grid2(selectedProcedural),
          pw.SizedBox(height: 6),
          _grid2([
            _f('E-Shakshya', _v(m['eshakshValue'], or: 'Not set')),
            if (m['eshakshValue'] == 'yes' &&
                (m['eshakshDt']?.toString().isNotEmpty ?? false))
              _f('E-Shakshya Date & Time', _v(m['eshakshDt']))
            else if (m['eshakshValue'] == 'no' &&
                (m['eshakshReason']?.toString().isNotEmpty ?? false))
              _f('Reason for No E-Shakshya', _v(m['eshakshReason'])),
          ]),
          pw.SizedBox(height: 8),
          pw.Text(
            'GOVERNMENT VEHICLE USAGE',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _dark,
            ),
          ),
          pw.SizedBox(height: 4),
          _grid2([
            _f(
              'SD Entry of Vehicle No & Time',
              _v(vuPdf['sdEntry'], or: 'Not set').toUpperCase(),
            ),
            _f(
              'Log Book of Vehicle Entry',
              _v(vuPdf['logBookEntry'], or: 'Not set').toUpperCase(),
            ),
            _f(
              'Case Diary Vehicle Entry',
              _v(vuPdf['caseDiaryEntry'], or: 'Not set').toUpperCase(),
            ),
          ]),
        ],
      ),
    ),
  );

  // ── §15 / §16 Seizure Records ─────────────────────────────────────────────
  final seizures = (m['seizures'] as List?) ?? [];
  sections.add(
    _card(
      isMurder ? 16 : 15,
      'SEIZURE RECORDS',
      _teal,
      seizures.isEmpty
          ? _empty('No seizure records added.')
          : pw.Column(
              children: seizures.asMap().entries.map((e) {
                final s = e.value as Map;
                return _subCard(
                  _grid2([
                    _f('Property Description', _v(s['desc']), full: true),
                    _f('Seized From', _v(s['fromWhom'], or: '-')),
                    _f('Other Name', _v(s['otherName'])),
                    if (_v(s['quantity']).isNotEmpty)
                      _f('Quantity', _v(s['quantity'])),
                    if (_v(s['serialNo']).isNotEmpty)
                      _f('Serial / ID No.', _v(s['serialNo'])),
                    if (_v(s['estValue']).isNotEmpty)
                      _f('Est. Value', _v(s['estValue'])),
                    if (_v(s['status']).isNotEmpty)
                      _f('Status', _v(s['status'])),
                    if (_v(s['recoveryDate']).isNotEmpty)
                      _f('Recovery Date', _v(s['recoveryDate'])),
                    if (_v(s['custodyLoc']).isNotEmpty)
                      _f('Custody Location', _v(s['custodyLoc'])),
                    if (_v(s['seizureDetails']).isNotEmpty)
                      _f('Seizure Details', _v(s['seizureDetails']), full: true),
                  ]),
                );
              }).toList(),
            ),
    ),
  );

  // ── §16 / §17 Technical & Custody ─────────────────────────────────────────
  final custodyList = (m['custodyInfo'] as List?) ?? [];
  sections.add(
    _card(
      isMurder ? 17 : 16,
      'TECHNICAL & CUSTODY',
      _teal,
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _grid2([
            _f('CDR Sent Date', _v(m['cdrSent'])),
            _f('CDR Received Date', _v(m['cdrRecv'])),
          ]),
          if (custodyList.isEmpty) ...[
            pw.SizedBox(height: 4),
            _empty('No custody records added.'),
          ] else ...[
            pw.SizedBox(height: 6),
            ...custodyList.map((c) {
              final row = c as Map;
              final accName = _v(row['accusedName'],
                  or: _v(row['suretyAccusedName'], or: 'Accused'));
              return _subCard(
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'ACCUSED: ${accName.toUpperCase()}',
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: _teal,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'POLICE CUSTODY REMAND (PCR)',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: _dark,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    _grid2([
                      _f('PCR Start', _v(row['pcrStart'])),
                      _f('PCR End', _v(row['pcrEnd'])),
                      _f('PCR Days', _v(row['pcrDays'])),
                      _f('Court / Order Details', _v(row['pcrDetails'])),
                    ]),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'MAGISTERIAL CUSTODY REMAND (MCR)',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: _dark,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    _grid2([
                      _f('MCR Start', _v(row['mcrStart'])),
                      _f('MCR End', _v(row['mcrEnd'])),
                      _f('MCR Days', _v(row['mcrDays'])),
                      _f('Jail Name / Details', _v(row['mcrJail'])),
                    ]),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'BAIL DETAILS',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: _dark,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    _grid2([
                      _f('Bail Type', _v(row['bailType'], or: 'None')),
                      if (_v(row['bailDate']).isNotEmpty)
                        _f('Bail Date', _v(row['bailDate'])),
                      if (_v(row['bailDetails']).isNotEmpty)
                        _f('Bail Details / Order', _v(row['bailDetails']),
                            full: true),
                    ]),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'PR BOND',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: _dark,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    _grid2([
                      _f('PR Bond Status',
                          _v(row['prBondStatus'], or: 'Pending')),
                      _f('PR Bond Date', _v(row['prBondDate'])),
                      if (_v(row['prBondDetails']).isNotEmpty)
                        _f('PR Bond Amount / Details', _v(row['prBondDetails']),
                            full: true),
                    ]),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'SURETY DETAILS',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: _dark,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    _grid2([
                      _f('Surety Name', _v(row['suretyName'])),
                      _f('Surety Age', _v(row['suretyAge'])),
                      _f('Surety Gender', _v(row['suretyGender'])),
                      _f('Surety Relationship', _v(row['suretyRel'])),
                      _f('Surety Occupation', _v(row['suretyOcc'])),
                      _f('Surety Mobile', _v(row['suretyMobile'])),
                      _f('Surety Aadhaar', _v(row['suretyAadhaar'])),
                      _f('Surety PAN', _v(row['suretyPan'])),
                      _f('Surety Address', _v(row['suretyAddress']),
                          full: true),
                      if (_v(row['suretyDetails']).isNotEmpty)
                        _f('Surety Bond Details', _v(row['suretyDetails']),
                            full: true),
                    ]),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    ),
  );

  // ── §17 / §18 Preventive & Bonds ──────────────────────────────────────────
  final prev = m['preventive'] as Map? ?? {};
  final isBondYes = (prev['preventiveBonds'] ?? prev['prBond']) == 'yes';
  final prevFields = <_FD>[
    _f(
      'Preventive Bonds',
      _v(prev['preventiveBonds'] ?? prev['prBond'], or: 'No'),
    ),
  ];
  if (isBondYes) {
    prevFields.add(_f('PR Bond Date', _v(prev['bondDate'])));
    prevFields.add(_f('Bond Cancellation Date', _v(prev['bondCancellation'])));
    prevFields.add(_f('Reason for PR Bond', _v(prev['bondReason'])));
  }
  prevFields.add(_f('Action Type', _v(prev['action'], or: 'Not set')));
  if (prev['actionDate'] != null && prev['actionDate'].toString().isNotEmpty) {
    prevFields.add(
      _f(
        '${prev['action'] ?? 'Action Type'} Date & Time',
        _v(prev['actionDate']),
      ),
    );
  }
  sections.add(
    _card(
      isMurder ? 18 : 17,
      'PREVENTIVE & BONDS',
      _teal,
      _grid2(prevFields),
    ),
  );

  // ── §18 / §19 Discharge Status ────────────────────────────────────────────
  final discharge = (m['dischargeByAccused'] as Map?) ?? {};
  final disDetails = (m['dischargeDetails'] as Map?) ?? {};
  sections.add(
    _card(
      isMurder ? 19 : 18,
      'DISCHARGE STATUS',
      _teal,
      discharge.isEmpty
          ? _empty('No discharge data. Add accused names first.')
          : pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: discharge.entries.map((e) {
                final discharged = e.value == true;
                final name = e.key.toString();
                final det = (disDetails[name] as Map?) ?? {};
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          _checkbox(discharged, color: _green),
                          pw.SizedBox(width: 6),
                          pw.Text(
                            '$name - ${discharged ? "Discharged" : "Not discharged"}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: discharged ? _dark : _muted,
                            ),
                          ),
                        ],
                      ),
                      if (discharged && det.isNotEmpty) ...[
                        if (det['date'] != null &&
                            det['date'].toString().isNotEmpty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(left: 18, top: 2),
                            child: pw.Text(
                              'Discharge Date: ${det['date']}',
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: _dark,
                              ),
                            ),
                          ),
                        if (det['reason'] != null &&
                            det['reason'].toString().isNotEmpty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(left: 18, top: 2),
                            child: pw.Text(
                              'Reason: ${det['reason']}',
                              style: const pw.TextStyle(
                                fontSize: 9,
                                color: _muted,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
    ),
  );

  // ── §19 / §20 Court Filing ────────────────────────────────────────────────
  final court = m['court'] as Map? ?? {};
  sections.add(
    _card(
      isMurder ? 20 : 19,
      'COURT FILING',
      _teal,
      _grid2([
        _f('Charge Sheet No.', _v(court['chargeSheetNumber'])),
        _f('Charge Sheet Date', _v(court['chargeSheetDate'])),
      ]),
    ),
  );

  // ── §20 / §21 Case Scrutiny Pipeline ──────────────────────────────────────
  final sc = m['scrutiny'] as Map? ?? {};
  sections.add(
    _card(
      isMurder ? 21 : 20,
      'CASE SCRUTINY PIPELINE',
      _teal,
      pw.Column(
        children: [
          _scrutinyStep(
            1,
            'SDPO / ACP Approval',
            true,
            send: _v(sc['sdpoSend']),
            grant: _v(sc['sdpoGrant']),
          ),
          _scrutinyStep(
            2,
            'APP Scrutiny',
            sc['stepAppActive'] == true,
            send: _v(sc['appSend']),
            grant: _v(sc['appGrant']),
            lockedMsg: 'Unlocks when SDPO Send Date is filled',
          ),
          _scrutinyStep(
            3,
            'Addl SP / DCP / Addl CP',
            sc['stepDcpActive'] == true,
            send: _v(sc['dcpSend']),
            grant: _v(sc['dcpGrant']),
            lockedMsg: 'Unlocks when APP Send Date is filled',
            isLast: true,
          ),
          pw.SizedBox(height: 10),
          _grid2([
            _f(
              'stepAppActive (scrutiny)',
              sc['stepAppActive'] == true ? 'Yes' : 'No',
            ),
            _f(
              'stepDcpActive (scrutiny)',
              sc['stepDcpActive'] == true ? 'Yes' : 'No',
            ),
          ]),
        ],
      ),
    ),
  );

  // ── §21 / §22 Final Verdict ───────────────────────────────────────────────
  final verdict = m['verdict'] as Map? ?? {};
  final acquitted =
      (verdict['acquitted'] as List?)?.map((x) => x.toString()).toList() ?? [];
  final convicted =
      (verdict['convicted'] as List?)?.map((x) => x.toString()).toList() ?? [];
  sections.add(
    _card(
      isMurder ? 22 : 21,
      'FINAL VERDICT',
      _teal,
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _grid2([
            _f('CC / ST Number', _v(court['ccStNumber'])),
            _f('Final Summary', _v(court['finalSummary'], or: 'Not set')),
            _f('Quashed by High Court', _v(court['quashedHighCourt'])),
          ]),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _verdictCol('✓ ACQUITTED', acquitted, _green)),
              pw.SizedBox(width: 10),
              pw.Expanded(child: _verdictCol('✗ CONVICTED', convicted, _red)),
            ],
          ),
        ],
      ),
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // EXTRA FIELDS — 100% DYNAMIC
  // ══════════════════════════════════════════════════════════════════════════
  if (extraMap.isNotEmpty) {
    sections.add(_extraSection(extraMap));
  }

  return sections;
}

// ══════════════════════════════════════════════════════════════════════════════
// EXTRA SECTION BUILDER — reads ANY map structure
// ══════════════════════════════════════════════════════════════════════════════

pw.Widget _extraSection(Map<String, dynamic> extra) {
  final flatFields = <MapEntry<String, dynamic>>[];
  final subSections = <MapEntry<String, dynamic>>[];

  for (final e in extra.entries) {
    if (e.value is Map) {
      subSections.add(e);
    } else {
      flatFields.add(e);
    }
  }

  final widgets = <pw.Widget>[];

  if (flatFields.isNotEmpty) {
    widgets.add(
      _card(
        0,
        'FORM SPECIFIC FIELDS',
        _amber,
        _grid2(
          flatFields
              .map((e) => _f(_labelify(e.key), _anyToString(e.value)))
              .toList(),
        ),
      ),
    );
  }

  for (final e in subSections) {
    if (e.key == 'kidnapping_extra' && e.value is Map) {
      widgets.addAll(
        _kidnappingExtraCards(Map<dynamic, dynamic>.from(e.value as Map)),
      );
      continue;
    }

    final title = _labelify(e.key).toUpperCase();
    final mapValue = Map<dynamic, dynamic>.from(e.value as Map);

    // Prevent TooManyPagesException by splitting large flat maps
    // (e.g. kidnapping_extra) into smaller cards.
    final isFlat = mapValue.values.every((v) => v is! Map && v is! List);
    if (isFlat) {
      final fields = mapValue.entries
          .map(
            (entry) =>
                _f(_labelify(entry.key.toString()), _anyToString(entry.value)),
          )
          .toList();
      const chunkSize = 14;
      for (var i = 0; i < fields.length; i += chunkSize) {
        final chunk = fields.sublist(
          i,
          (i + chunkSize) > fields.length ? fields.length : (i + chunkSize),
        );
        widgets.add(
          _card(0, i == 0 ? title : '$title (CONT.)', _amber, _grid2(chunk)),
        );
      }
      continue;
    }

    widgets.add(_card(0, title, _amber, _buildAnyMap(mapValue)));
  }

  return pw.Column(children: widgets);
}

List<pw.Widget> _kidnappingExtraCards(Map<dynamic, dynamic> data) {
  const ordered = <MapEntry<String, String>>[
    // 1) Kidnapped Person KYC
    MapEntry('kidnappedName', 'Kidnapped Name'),
    MapEntry('kidnappedAge', 'Kidnapped Age'),
    MapEntry('kidnappedGender', 'Kidnapped Gender'),
    MapEntry('kidnappedOccupation', 'Kidnapped Occupation'),
    MapEntry('kidnappedMobile', 'Kidnapped Mobile'),
    MapEntry('kidnappedAadhaar', 'Kidnapped Aadhaar'),
    MapEntry('kidnappedReligion', 'Kidnapped Religion'),
    MapEntry('kidnappedCaste', 'Kidnapped Caste'),
    MapEntry('kidnappedRelation', 'Relation with Complainant'),

    // 2) Found Status
    MapEntry('personFound', 'Person Found'),
    MapEntry('foundDate', 'Found Date'),
    MapEntry('foundTime', 'Found Time'),
    MapEntry('foundSdNo', 'SD No. / Station Diary No.'),
    MapEntry('statementRecorded', 'Statement Recorded'),
    MapEntry('statementDate', 'Statement Date'),
    MapEntry('statementTime', 'Statement Time'),
    MapEntry('custodyTo', 'Custody Given To'),
    MapEntry('custodyOtherText', 'Custody Other (Specify)'),
    MapEntry('custodyName', 'Custody Name'),
    MapEntry('custodyAge', 'Custody Age'),
    MapEntry('custodyGender', 'Custody Gender'),
    MapEntry('custodyMobile', 'Custody Mobile'),
    MapEntry('custodyAadhaar', 'Custody Aadhaar'),
    MapEntry('custodyRelation', 'Custody Relationship'),
    MapEntry('custodyAddress', 'Custody Full Address'),

    // 3) 183 BNSS
    MapEntry('bnss183Recorded', 'Statement Recorded under 183 BNSS'),
    MapEntry('bnssDate', 'BNSS Date'),
    MapEntry('bnssTime', 'BNSS Time'),

    // 4) CWC Statement
    MapEntry('cwcRecorded', 'CWC Statement Recorded'),
    MapEntry('cwcDate', 'CWC Date'),
    MapEntry('cwcTime', 'CWC Time'),

    // 5) Medical Examination
    MapEntry('medicalExamDone', 'Medical Examination Conducted'),
    MapEntry('medicalDate', 'Medical Date'),
    MapEntry('medicalTime', 'Medical Time'),

    // 6) In-Camera Statement
    MapEntry('inCameraRecorded', 'In-Camera Statement Recorded'),
    MapEntry('inCameraDate', 'In-Camera Date'),
    MapEntry('inCameraTime', 'In-Camera Time'),
  ];

  final fields = <_FD>[];
  for (final pair in ordered) {
    fields.add(_f(pair.value, _anyToString(data[pair.key])));
  }

  // Keep cards small enough to avoid orphan headers / bad page spacing.
  const chunkSize = 8;
  final cards = <pw.Widget>[];
  for (var i = 0; i < fields.length; i += chunkSize) {
    final chunk = fields.sublist(
      i,
      (i + chunkSize) > fields.length ? fields.length : (i + chunkSize),
    );
    cards.add(
      _card(
        0,
        i == 0 ? 'KIDNAPPING EXTRA FIELDS' : 'KIDNAPPING EXTRA FIELDS (CONT.)',
        _amber,
        _grid2(chunk),
      ),
    );
  }
  return cards;
}

pw.Widget _buildAnyMap(Map<dynamic, dynamic> m) {
  final flatFields = <MapEntry<dynamic, dynamic>>[];
  final listFields = <MapEntry<dynamic, dynamic>>[];
  final subMaps = <MapEntry<dynamic, dynamic>>[];

  for (final e in m.entries) {
    if (e.value is Map) {
      subMaps.add(e);
    } else if (e.value is List) {
      listFields.add(e);
    } else {
      flatFields.add(e);
    }
  }

  final widgets = <pw.Widget>[];

  if (flatFields.isNotEmpty) {
    widgets.add(
      _grid2(
        flatFields
            .map((e) => _f(_labelify(e.key.toString()), _anyToString(e.value)))
            .toList(),
      ),
    );
  }

  for (final e in listFields) {
    final list = e.value as List;
    widgets.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 6, bottom: 4),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              _labelify(e.key.toString()).toUpperCase(),
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _sec,
                letterSpacing: 0.5,
              ),
            ),
            pw.SizedBox(height: 4),
            if (list.isEmpty)
              _empty('No entries.')
            else
              pw.Column(
                children: list.asMap().entries.map((item) {
                  if (item.value is Map) {
                    return _subCard(
                      _buildAnyMap(
                        Map<dynamic, dynamic>.from(item.value as Map),
                      ),
                    );
                  }
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 4,
                          height: 4,
                          margin: const pw.EdgeInsets.only(right: 6),
                          decoration: const pw.BoxDecoration(
                            color: _amber,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            _anyToString(item.value),
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: _dark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  for (final e in subMaps) {
    widgets.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              _labelify(e.key.toString()).toUpperCase(),
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: _sec,
                letterSpacing: 0.5,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: _bg,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: _border, width: 0.5),
              ),
              child: _buildAnyMap(Map<dynamic, dynamic>.from(e.value as Map)),
            ),
          ],
        ),
      ),
    );
  }

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: widgets,
  );
}

String _labelify(String key) {
  var result = key.replaceAll('_', ' ');
  result = result.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (m) => '${m.group(1)} ${m.group(2)}',
  );
  if (result.isNotEmpty) {
    result = result[0].toUpperCase() + result.substring(1);
  }
  return result;
}

String _anyToString(dynamic v) {
  if (v == null) return '-';
  if (v is bool) return v ? 'Yes' : 'No';
  if (v is List) return v.isEmpty ? '-' : v.map(_anyToString).join(', ');
  if (v is Map) {
    return v.isEmpty
        ? '-'
        : v.entries
            .map(
              (e) => '${_labelify(e.key.toString())}: ${_anyToString(e.value)}',
            )
            .join(' | ');
  }
  final s = v.toString().trim();
  return s.isEmpty ? '-' : s;
}

// ══════════════════════════════════════════════════════════════════════════════
// COMPONENT BUILDERS
// ══════════════════════════════════════════════════════════════════════════════

pw.Widget _card(
  dynamic num,
  String title,
  PdfColor accent,
  pw.Widget body,
) =>
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.NewPage(freeSpace: 60),
        pw.Container(
          margin:
              const pw.EdgeInsets.only(bottom: PdfLayoutConstants.sectionGap),
          decoration: pw.BoxDecoration(
            color: _white,
            borderRadius:
                pw.BorderRadius.circular(PdfLayoutConstants.borderRadius),
            border: pw.Border.all(
              color: _border,
              width: PdfLayoutConstants.borderWidth,
            ),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3.5,
                ),
                decoration: const pw.BoxDecoration(
                  color: _headerBg,
                  borderRadius: pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(3),
                    topRight: pw.Radius.circular(3),
                  ),
                ),
                child: pw.Row(
                  children: [
                    if (num.toString() != '0') ...[
                      pw.Container(
                        width: 13,
                        height: 13,
                        alignment: pw.Alignment.center,
                        decoration: pw.BoxDecoration(
                          color: _dark,
                          borderRadius: pw.BorderRadius.circular(2),
                        ),
                        child: pw.Text(
                          '$num',
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                            color: _white,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 5),
                    ],
                    pw.Expanded(
                      child: pw.Text(
                        _cleanText(title),
                        style: pw.TextStyle(
                          fontSize: PdfLayoutConstants.sectionTitleFontSize,
                          fontWeight: pw.FontWeight.bold,
                          color: _dark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.Padding(
                padding: PdfLayoutConstants.cardPadding,
                child: body,
              ),
            ],
          ),
        ),
      ],
    );

class _FD {
  const _FD(this.label, this.value, {this.full = false});
  final String label;
  final String value;
  final bool full;
}

_FD _f(String label, String value, {bool full = false}) =>
    _FD(label, value, full: full);

pw.Widget _grid2(List<_FD> fields) {
  final rows = <pw.Widget>[];
  final regular = fields.where((f) => !f.full).toList();
  final fullList = fields.where((f) => f.full).toList();

  for (var i = 0; i < regular.length; i += 2) {
    final left = regular[i];
    final right = i + 1 < regular.length ? regular[i + 1] : null;
    rows.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: PdfLayoutConstants.rowGap),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _fWidget(left.label, left.value)),
            pw.SizedBox(width: PdfLayoutConstants.fieldGap),
            pw.Expanded(
              child: right != null
                  ? _fWidget(right.label, right.value)
                  : pw.SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
  for (final f in fullList) {
    rows.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: PdfLayoutConstants.rowGap),
        child: _fWidget(f.label, f.value),
      ),
    );
  }
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: rows,
  );
}

pw.Widget _fWidget(String label, String value) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          _cleanText(label).toUpperCase(),
          style: pw.TextStyle(
            fontSize: PdfLayoutConstants.labelFontSize,
            fontWeight: pw.FontWeight.bold,
            color: _sec,
            letterSpacing: 0.3,
          ),
        ),
        pw.SizedBox(height: PdfLayoutConstants.labelValueGap),
        pw.Container(
          width: double.infinity,
          padding: PdfLayoutConstants.cellPadding,
          decoration: pw.BoxDecoration(
            color: _bg,
            borderRadius: pw.BorderRadius.circular(2.5),
            border: pw.Border.all(
              color: _border,
              width: PdfLayoutConstants.borderWidth,
            ),
          ),
          child: pw.Text(
            _cleanText(value),
            style: pw.TextStyle(
              fontSize: PdfLayoutConstants.valueFontSize,
              color: (value.isEmpty || value == '-' || value == '—')
                  ? _muted
                  : _dark,
            ),
          ),
        ),
      ],
    );

pw.Widget _subCard(pw.Widget child) => pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4),
      padding: const pw.EdgeInsets.all(5),
      decoration: pw.BoxDecoration(
        color: _bg,
        borderRadius: pw.BorderRadius.circular(3),
        border: pw.Border.all(
          color: _border,
          width: PdfLayoutConstants.borderWidth,
        ),
      ),
      child: child,
    );

pw.Widget _personBlock(String title, Map<String, dynamic> person) =>
    pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4),
      padding: const pw.EdgeInsets.all(5),
      decoration: pw.BoxDecoration(
        color: _bg,
        borderRadius: pw.BorderRadius.circular(3),
        border: pw.Border.all(
          color: _border,
          width: PdfLayoutConstants.borderWidth,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _cleanText(title),
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: _dark,
            ),
          ),
          pw.SizedBox(height: 3),
          _grid2([
            _f('Name', _v(person['name'])),
            _f('Age', _v(person['age'])),
            _f('Gender', _v(person['gender'])),
            _f('Occupation', _v(person['occ'])),
            _f('Mobile', _v(person['mobile'])),
            _f('Aadhaar', _v(person['aadhaar'])),
            _f('Religion', _v(person['religion'])),
            _f('Caste', _v(person['caste'])),
            _f('PAN', _v(person['pan'])),
          ]),
        ],
      ),
    );

pw.Widget _chargeBlock(int num, String act, List<String> secs) => pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4),
      padding: const pw.EdgeInsets.all(5),
      decoration: pw.BoxDecoration(
        color: _bg,
        borderRadius: pw.BorderRadius.circular(3),
        border: pw.Border.all(
          color: _border,
          width: PdfLayoutConstants.borderWidth,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Charge #$num: ${_cleanText(act.isEmpty ? "No act selected" : act)}',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: _dark,
            ),
          ),
          pw.SizedBox(height: 3),
          secs.isEmpty
              ? pw.Text(
                  'No sections selected',
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    color: _muted,
                    fontStyle: pw.FontStyle.italic,
                  ),
                )
              : pw.Wrap(
                  spacing: 4,
                  runSpacing: 3,
                  children: secs.map((s) {
                    final resolved = _resolveSectionFullName(act, s);
                    return pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 4.5,
                        vertical: 2,
                      ),
                      decoration: pw.BoxDecoration(
                        color: _white,
                        borderRadius: pw.BorderRadius.circular(2.5),
                        border: pw.Border.all(
                          color: _border,
                          width: PdfLayoutConstants.borderWidth,
                        ),
                      ),
                      child: pw.Text(
                        _cleanText(resolved),
                        style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                          color: _dark,
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );

pw.Widget _verdictCol(String title, List<String> names, PdfColor color) =>
    pw.Container(
      padding: const pw.EdgeInsets.all(5),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(3),
        border: pw.Border.all(
          color: color,
          width: PdfLayoutConstants.borderWidth,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _cleanText(title),
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 2.5),
          pw.Divider(color: color, thickness: 0.5),
          pw.SizedBox(height: 2.5),
          names.isEmpty
              ? pw.Text(
                  'None',
                  style: pw.TextStyle(
                    fontSize: 7.5,
                    color: _muted,
                    fontStyle: pw.FontStyle.italic,
                  ),
                )
              : pw.Column(
                  children: names
                      .map(
                        (n) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 2),
                          child: pw.Row(
                            children: [
                              pw.Container(
                                width: 4,
                                height: 4,
                                margin: const pw.EdgeInsets.only(right: 4),
                                decoration: pw.BoxDecoration(
                                  color: color,
                                  shape: pw.BoxShape.circle,
                                ),
                              ),
                              pw.Expanded(
                                child: pw.Text(
                                  _cleanText(n),
                                  style: const pw.TextStyle(
                                    fontSize: 7.5,
                                    color: _dark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
        ],
      ),
    );

pw.Widget _scrutinyStep(
  int step,
  String title,
  bool active, {
  required String send,
  required String grant,
  String? lockedMsg,
  bool isLast = false,
}) =>
    pw.Padding(
      padding: pw.EdgeInsets.only(bottom: isLast ? 0 : 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            children: [
              pw.Container(
                width: 16,
                height: 16,
                decoration: pw.BoxDecoration(
                  color: active ? _teal : _border,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    '$step',
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      fontWeight: pw.FontWeight.bold,
                      color: _white,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                pw.Container(
                  width: 1.5,
                  height: 18,
                  color: active ? _teal : _border,
                ),
            ],
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Padding(
              padding: pw.EdgeInsets.only(bottom: isLast ? 0 : 2),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _cleanText(title),
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: active ? _dark : _muted,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  if (!active && lockedMsg != null)
                    pw.Text(
                      _cleanText(lockedMsg),
                      style: pw.TextStyle(
                        fontSize: 7,
                        color: _muted,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    )
                  else
                    _grid2([_f('Send Date', send), _f('Grant Date', grant)]),
                ],
              ),
            ),
          ),
        ],
      ),
    );

pw.Widget _checkbox(bool checked, {PdfColor color = _teal}) => pw.Container(
      width: 10,
      height: 10,
      decoration: pw.BoxDecoration(
        color: checked ? color : _bg,
        borderRadius: pw.BorderRadius.circular(2),
        border: pw.Border.all(
          color: checked ? color : _border,
          width: PdfLayoutConstants.borderWidth,
        ),
      ),
      child: checked
          ? pw.Center(
              child: pw.Text(
                '✓',
                style: pw.TextStyle(
                  fontSize: 6.5,
                  color: _white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            )
          : pw.SizedBox(),
    );

pw.Widget _badge(String label, PdfColor color) => pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 4),
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(
          color: color,
          width: PdfLayoutConstants.borderWidth,
        ),
      ),
      child: pw.Text(
        _cleanText(label),
        style: pw.TextStyle(
          fontSize: PdfLayoutConstants.badgeFontSize,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );

pw.Widget _empty(String text) => pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(
        color: _bg,
        borderRadius: pw.BorderRadius.circular(3),
        border: pw.Border.all(
          color: _border,
          width: PdfLayoutConstants.borderWidth,
        ),
      ),
      child: pw.Text(
        _cleanText(text),
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 7.5,
          color: _muted,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    );

// ══════════════════════════════════════════════════════════════════════════════
// HELPERS
// ══════════════════════════════════════════════════════════════════════════════

String _cleanText(dynamic v) {
  if (v == null) return '-';
  var s = v.toString().trim();
  if (s.isEmpty) return '-';
  s = s
      .replaceAll(
        RegExp(
          r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{200D}\u{FE0F}\u{2611}\u{2610}\u{2705}\u{274C}]',
          unicode: true,
        ),
        '',
      )
      .replaceAll('—', '-')
      .trim();
  return s.isEmpty ? '-' : s;
}

/// Resolves raw section numbers (e.g. "302", "25") to their full descriptive titles
String _resolveSectionFullName(String? actKey, dynamic rawSections) {
  if (rawSections == null) return '-';

  List<String> sectionList = [];
  if (rawSections is List) {
    sectionList = rawSections
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();
  } else {
    final s = rawSections.toString().trim();
    if (s.isEmpty || s == '-' || s == '—') return '-';
    sectionList =
        s.split(RegExp(r'[,;]\s*')).where((e) => e.trim().isNotEmpty).toList();
  }

  if (sectionList.isEmpty) return '-';

  final Map<String, String> actSectionMap = {};
  for (final actEntry in ACT_DATA.entries) {
    final act = actEntry.key.toUpperCase();
    final secList = actEntry.value['sections'] as List<dynamic>? ?? [];
    for (final sec in secList) {
      if (sec is Map) {
        final val = sec['val']?.toString().trim() ?? '';
        final label = sec['label']?.toString().trim() ?? '';
        if (val.isNotEmpty && label.isNotEmpty) {
          actSectionMap['$act:$val'.toUpperCase()] = label;
          actSectionMap['$act $val'.toUpperCase()] = label;
          actSectionMap[val.toUpperCase()] = label;
        }
      }
    }
  }

  final normalizedAct = (actKey ?? '').trim().toUpperCase();

  final resolved = sectionList.map((sec) {
    final cleanSec = sec.trim();
    if (cleanSec.contains(' - ')) return cleanSec;

    final keyWithAct = '$normalizedAct:$cleanSec'.toUpperCase();
    if (actSectionMap.containsKey(keyWithAct)) {
      return actSectionMap[keyWithAct]!;
    }

    final rawKey =
        cleanSec.replaceAll(RegExp(r'^[A-Za-z_]+\s*'), '').trim().toUpperCase();
    final keyWithActStripped = '$normalizedAct:$rawKey'.toUpperCase();
    if (actSectionMap.containsKey(keyWithActStripped)) {
      return actSectionMap[keyWithActStripped]!;
    }

    if (actSectionMap.containsKey(cleanSec.toUpperCase())) {
      return actSectionMap[cleanSec.toUpperCase()]!;
    }

    if (actSectionMap.containsKey(rawKey)) {
      return actSectionMap[rawKey]!;
    }

    return cleanSec;
  }).toList();

  return resolved.join(', ');
}

String _v(dynamic v, {String or = ''}) {
  if (v == null) return or;
  final s = v.toString().trim();
  return s.isEmpty ? or : _cleanText(s);
}

String _now() {
  final d = DateTime.now();
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
