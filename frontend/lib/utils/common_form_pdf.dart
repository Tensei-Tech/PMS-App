// lib/utils/common_form_pdf.dart
// Universal PDF for Khakhi Diary: CommonForm 17 sections + arbitrary extraMap.
// No screen imports, no Firebase.

import 'dart:typed_data';

// ignore_for_file: unused_shown_name
// Imports match project spec (`show BuildContext, TimeOfDay`); TimeOfDay is unused in this utility.

import 'package:flutter/material.dart' show BuildContext, TimeOfDay;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../services/backend_case_service.dart';
import 'pdf_layout_constants.dart';
import 'pdf_loading_helper.dart';
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
  await PdfLoadingHelper.runWithLoading(
    context: context,
    action: () async {
      final bytes = await generateFormPdf(
        commonMap,
        extraMap: extraMap,
        formTitle: formTitle,
        formSubtitle: formSubtitle,
      );
      final fileName =
          '${formTitle.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    },
  );
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
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}  ·  Generated: ${_now()}',
            style: const pw.TextStyle(
              fontSize: PdfLayoutConstants.footerFontSize,
              color: _sec,
            ),
          ),
        ],
      ),
    );

const _standardCommonFormKeys = {
  'crNo',
  'case_number',
  'caseNumber',
  'cr_number',
  'regDate',
  'incidentDate',
  'incident_date',
  'registered_datetime',
  'registeredDateTime',
  'occurrence_datetime',
  'incident_datetime',
  'occurrenceDate',
  'isUnknownUntraced',
  'is_unknown_accused',
  'isUnknownAccused',
  'firCopyPath',
  'charges',
  'sections',
  'acts',
  'act_name',
  'section',
  'spotVillage',
  'village_town',
  'spotArea',
  'area_name',
  'spotAddress',
  'crime_spot_address',
  'location',
  'full_address',
  'distance_from_ps',
  'direction_from_ps',
  'stolenProperties',
  'stolenProperty',
  'recoveredProperties',
  'recoveredProperty',
  'complainant',
  'complainant_name',
  'complainant_age',
  'complainant_gender',
  'complainant_occupation',
  'complainant_occ',
  'complainant_mobile',
  'complainant_aadhaar',
  'complainant_religion',
  'complainant_caste',
  'complainant_pan',
  'complainant_address',
  'isSexualOffence',
  'victim',
  'victim_name',
  'victim_age',
  'victim_gender',
  'victim_occupation',
  'victim_occ',
  'victim_mobile',
  'victim_aadhaar',
  'victim_religion',
  'victim_caste',
  'victim_pan',
  'victim_address',
  'deceased',
  'deceased_name',
  'isMurderCase',
  'isPocsoCase',
  'injured',
  'injured_name',
  'accused',
  'accused_name',
  'accused_age',
  'accused_gender',
  'accused_mobile',
  'accused_occupation',
  'accused_occ',
  'accused_address',
  'accused_aadhaar',
  'accused_pan',
  'accused_religion',
  'accused_caste',
  'suspectedAccused',
  'suspected_accused',
  'suspected_accused_name',
  'unidentifiedList',
  'unidentified_accused',
  'unknownList',
  'unknown_accused',
  'caseResponsibility',
  'io_designation',
  'ioDesig',
  'io_name',
  'ioName',
  'investigating_officer',
  'assigned_officer',
  'registered_by_designation',
  'regDesig',
  'registered_by_name',
  'regName',
  'cctvValue',
  'cctv_checked',
  'cctv_datetime',
  'cctvDateTime',
  'arrestRelease',
  'arrests',
  'arrest_records',
  'section8283Action',
  'proceduralChecks',
  'proceduralDates',
  'vehicleUsage',
  'spot_panchanama',
  'spot_panchanama_date',
  'seizure_panchanama',
  'seizure_panchanama_date',
  'inquest_panchanama',
  'inquest_panchanama_date',
  'eshakshValue',
  'eshakshDt',
  'eshakshReason',
  'e_shakshya',
  'fingerprint_taken',
  'seizures',
  'seizure_items',
  'object_name',
  'seizure_description',
  'seizure_from',
  'seizure_date',
  'seizure_location',
  'custodyInfo',
  'custody_records',
  'remand_custody',
  'cdrSent',
  'cdr_sent_date',
  'cdrRecv',
  'cdr_recv_date',
  'preventive',
  'preventive_actions',
  'dischargeByAccused',
  'dischargeDetails',
  'court',
  'charge_sheet_no',
  'charge_sheet_date',
  'scrutiny',
  'verdict',
  'cc_st_number',
  'final_summary',
  'quashed_by_high_court',
  'commonForm',
  'id',
  'category',
  'subCategory',
  'sub_category',
  'status',
  'priority',
  'title',
  'description',
  'stationName',
  'assignedOfficer',
  'briefFact',
  'updatedAt',
  'createdAt',
  'ncForm',
  'missingForm',
  'mpdaForm',
  'preventiveForm',
};

List<pw.Widget> _buildAll(Map<String, dynamic> m, Map<String, dynamic> extra) {
  final sections = <pw.Widget>[];
  final isUnknown = m['isUnknownUntraced'] == true ||
      m['is_unknown_accused'] == true ||
      m['isUnknownAccused'] == true;
  final extraMap = Map<String, dynamic>.from(extra);
  for (final key in _standardCommonFormKeys) {
    extraMap.remove(key);
  }

  int secNum = 1;

  final bool isMurder = m['isMurderCase'] == true ||
      (m['category']?.toString().toLowerCase().contains('murder') ?? false) ||
      (m['sub_category']?.toString().toLowerCase().contains('murder') ??
          false) ||
      (m['subCategory']?.toString().toLowerCase().contains('murder') ??
          false) ||
      (m['deceased'] is Map &&
          ((m['deceased'] as Map)['name']?.toString().trim().isNotEmpty ==
                  true ||
              (m['deceased'] as Map)['mobile']?.toString().trim().isNotEmpty ==
                  true ||
              (m['deceased'] as Map)['aadhaar']?.toString().trim().isNotEmpty ==
                  true));
  final bool isPocso = m['isPocsoCase'] == true;

  // ── §1 Crime Registration ─────────────────────────────────────────────────
  final crNo =
      _v(m['crNo'] ?? m['case_number'] ?? m['cr_number'] ?? m['caseNumber']);
  final regDate = _v(m['regDate'] ??
      m['registered_datetime'] ??
      m['registeredDateTime'] ??
      m['incident_date']);
  final occDate = _v(m['occurrence_datetime'] ??
      m['incident_datetime'] ??
      m['occurrenceDate']);
  final station = _v(m['stationName'] ?? m['police_station'] ?? m['station']);
  final district = _v(m['district']);
  final cat = _v(m['category'] ?? m['title']);
  final subCat = _v(m['subCategory'] ?? m['sub_category']);
  final firCopy = _v(m['firCopyPath']);

  sections.add(
    _card(
      secNum++,
      'CRIME REGISTRATION INFO',
      _teal,
      _grid2([
        _f('Cr. No.', crNo),
        _f('Registered Date', regDate),
        if (occDate.isNotEmpty) _f('Occurrence Date & Time', occDate),
        if (station.isNotEmpty) _f('Police Station', station),
        if (district.isNotEmpty) _f('District', district),
        if (cat.isNotEmpty && cat != crNo) _f('Category', cat),
        if (subCat.isNotEmpty && subCat != cat) _f('Sub-Category', subCat),
        _f('Unknown / Untraced', isUnknown ? 'Yes' : 'No'),
        if (firCopy.isNotEmpty && firCopy != 'Not uploaded' && firCopy != '-')
          _f('FIR Copy', firCopy, full: true),
      ]),
    ),
  );

  // ── §2 Acts & Sections Filed ───────────────────────────────────────────────
  final Map chargesMap;
  if (m['charges'] is Map && (m['charges'] as Map).isNotEmpty) {
    chargesMap = m['charges'] as Map;
  } else if (m['charges'] is List && (m['charges'] as List).isNotEmpty) {
    chargesMap = {};
    final cList = m['charges'] as List;
    for (int i = 0; i < cList.length; i++) {
      final c = cList[i];
      if (c is Map) {
        chargesMap['charge-${i + 1}'] = c;
      } else {
        chargesMap['charge-${i + 1}'] = {
          'act': 'Law',
          'sections': [c.toString()]
        };
      }
    }
  } else if (m['acts_sections'] is List &&
      (m['acts_sections'] as List).isNotEmpty) {
    chargesMap = {};
    final cList = m['acts_sections'] as List;
    for (int i = 0; i < cList.length; i++) {
      final c = cList[i];
      if (c is Map) {
        chargesMap['charge-${i + 1}'] = c;
      } else {
        chargesMap['charge-${i + 1}'] = {
          'act': 'Law',
          'sections': [c.toString()]
        };
      }
    }
  } else {
    chargesMap = {};
  }
  sections.add(
    _card(
      secNum++,
      'ACTS & SECTIONS FILED',
      _teal,
      chargesMap.isEmpty
          ? _empty('No charges added.')
          : pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: chargesMap.entries.toList().asMap().entries.map((e) {
                final chargeNum = e.key + 1;
                final data = (e.value.value is Map)
                    ? (e.value.value as Map)
                    : {'act': e.value.value.toString()};
                final act = _v(data['act'] ?? data['act_name']);
                final rawSecs = data['sections'] ?? data['section'];
                final secs = (rawSecs is List)
                    ? rawSecs.map((s) => s.toString()).toList()
                    : (rawSecs != null ? [rawSecs.toString()] : <String>[]);
                return _chargeBlock(chargeNum, act, secs);
              }).toList(),
            ),
    ),
  );

  // ── §3 Crime Spot ─────────────────────────────────────────────────────────
  final spotVillage = _v(m['spotVillage'] ?? m['village_town']);
  final spotArea = _v(m['spotArea'] ?? m['area_name']);
  final spotAddress = _v(m['spotAddress'] ??
      m['crime_spot_address'] ??
      m['location'] ??
      m['full_address']);
  final spotDist = _v(m['distance_from_ps']);
  final spotDir = _v(m['direction_from_ps']);
  sections.add(
    _card(
      secNum++,
      'CRIME SPOT',
      _teal,
      _grid2([
        _f('Village / Town', spotVillage),
        _f('Area Name', spotArea),
        _f('Address', spotAddress, full: true),
        if (spotDist.isNotEmpty) _f('Distance from PS', spotDist),
        if (spotDir.isNotEmpty) _f('Direction from PS', spotDir),
      ]),
    ),
  );

  final List<_FD> propWidgets = [];

  final spList =
      (m['stolenProperties'] is List) ? (m['stolenProperties'] as List) : null;
  if (spList != null && spList.isNotEmpty) {
    for (int i = 0; i < spList.length; i++) {
      final rawItem = spList[i];
      final item = rawItem is Map ? rawItem : {'property': rawItem.toString()};
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
    final Map spMap = (m['stolenProperty'] is Map)
        ? (m['stolenProperty'] as Map)
        : {'property': m['stolenProperty'].toString()};
    final prop = _v(spMap['property']).isNotEmpty
        ? _v(spMap['property'])
        : _v(spMap['description']);
    if (prop.isNotEmpty) {
      propWidgets.add(_f('Description', prop, full: true));
    }
    if (_v(spMap['quantity']).isNotEmpty) {
      propWidgets.add(_f('Quantity', _v(spMap['quantity'])));
    }
    if (_v(spMap['estValue']).isNotEmpty) {
      propWidgets.add(_f('Est. Value', _v(spMap['estValue'])));
    }
    if (_v(spMap['id']).isNotEmpty) {
      propWidgets.add(_f('ID / Serial No.', _v(spMap['id'])));
    }
    if (_v(spMap['date']).isNotEmpty) {
      propWidgets.add(_f('Date & Time', _v(spMap['date'])));
    }
    if (_v(spMap['from']).isNotEmpty) {
      propWidgets.add(_f('Stolen From', _v(spMap['from'])));
    }
  }

  final rpList = (m['recoveredProperties'] is List)
      ? (m['recoveredProperties'] as List)
      : null;
  if (rpList != null && rpList.isNotEmpty) {
    for (int i = 0; i < rpList.length; i++) {
      final rawItem = rpList[i];
      final item = rawItem is Map ? rawItem : {'property': rawItem.toString()};
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
    final Map? rpMap = (m['recoveredProperty'] is Map)
        ? (m['recoveredProperty'] as Map)
        : null;
    final Map? spMap =
        (m['stolenProperty'] is Map) ? (m['stolenProperty'] as Map) : null;
    final prop = rpMap != null
        ? _v(rpMap['property'])
        : (spMap != null
            ? _v(spMap['recovered'])
            : (m['recoveredProperty'] != null
                ? m['recoveredProperty'].toString()
                : ''));
    if (prop.isNotEmpty) {
      propWidgets.add(_f('Recovered Property', prop, full: true));
    }
    if (rpMap != null) {
      if (_v(rpMap['quantity']).isNotEmpty) {
        propWidgets.add(_f('Quantity', _v(rpMap['quantity'])));
      }
      if (_v(rpMap['estValue']).isNotEmpty) {
        propWidgets.add(_f('Est. Value', _v(rpMap['estValue'])));
      }
      if (_v(rpMap['date']).isNotEmpty) {
        propWidgets.add(_f('Date & Time', _v(rpMap['date'])));
      }
      if (_v(rpMap['from']).isNotEmpty) {
        propWidgets.add(_f('Recovered From', _v(rpMap['from'])));
      }
    }
  }

  if (propWidgets.isNotEmpty) {
    sections.add(
      _card(
        secNum++,
        'STOLEN & RECOVERED PROPERTY',
        _teal,
        _grid2(propWidgets),
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
  final Map<String, dynamic> comp;
  if (m['complainant'] is Map) {
    comp = Map<String, dynamic>.from(m['complainant'] as Map);
  } else if (m['complainant'] != null &&
      m['complainant'].toString().trim().isNotEmpty) {
    comp = {'name': m['complainant'].toString()};
  } else {
    comp = {};
  }
  if (_v(comp['name']).isEmpty && _v(m['complainant_name']).isNotEmpty) {
    comp['name'] = m['complainant_name'];
  }
  if (_v(comp['age']).isEmpty && _v(m['complainant_age']).isNotEmpty) {
    comp['age'] = m['complainant_age'];
  }
  if (_v(comp['gender']).isEmpty && _v(m['complainant_gender']).isNotEmpty) {
    comp['gender'] = m['complainant_gender'];
  }
  if (_v(comp['occ']).isEmpty &&
      _v(m['complainant_occupation'] ?? comp['occupation']).isNotEmpty) {
    comp['occ'] = m['complainant_occupation'] ?? comp['occupation'];
  }
  if (_v(comp['mobile']).isEmpty && _v(m['complainant_mobile']).isNotEmpty) {
    comp['mobile'] = m['complainant_mobile'];
  }
  if (_v(comp['aadhaar']).isEmpty && _v(m['complainant_aadhaar']).isNotEmpty) {
    comp['aadhaar'] = m['complainant_aadhaar'];
  }
  if (_v(comp['religion']).isEmpty &&
      _v(m['complainant_religion']).isNotEmpty) {
    comp['religion'] = m['complainant_religion'];
  }
  if (_v(comp['caste']).isEmpty && _v(m['complainant_caste']).isNotEmpty) {
    comp['caste'] = m['complainant_caste'];
  }
  if (_v(comp['pan']).isEmpty && _v(m['complainant_pan']).isNotEmpty) {
    comp['pan'] = m['complainant_pan'];
  }
  if (_v(comp['address']).isEmpty && _v(m['complainant_address']).isNotEmpty) {
    comp['address'] = m['complainant_address'];
  }

  final bool isSexualComp = m['isSexualOffence'] == true ||
      (comp['name']?.toString().contains('Protected') ?? false);
  sections.add(
    _card(
      secNum++,
      'COMPLAINANT KYC',
      _teal,
      comp.isEmpty || _v(comp['name']).isEmpty
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
              _f('Occupation', _v(comp['occ'] ?? comp['occupation'])),
              _f('Mobile', _v(comp['mobile'])),
              _f('Aadhaar', _v(comp['aadhaar'])),
              _f('Religion', _v(comp['religion'])),
              _f('Caste', _v(comp['caste'])),
              _f('PAN Number', _v(comp['pan'])),
              if (_v(comp['address']).isNotEmpty)
                _f('Address', _v(comp['address']), full: true),
            ]),
    ),
  );

  // ── §6 Victim KYC ──────────────────────────────────────────────────────────
  final Map victim = (m['victim'] is Map)
      ? (m['victim'] as Map)
      : (m['victim'] != null ? {'name': m['victim'].toString()} : {});
  final bool hasVictim = victim.isNotEmpty &&
      (_v(victim['name']).isNotEmpty ||
          _v(victim['mobile']).isNotEmpty ||
          _v(victim['aadhaar']).isNotEmpty);
  if (hasVictim || isPocso) {
    sections.add(
      _card(
        secNum++,
        'VICTIM KYC',
        _teal,
        victim.isEmpty
            ? _empty('No victim data.')
            : _grid2([
                _f('Name', _v(victim['name'])),
                _f('Age', _v(victim['age'])),
                _f('Gender', _v(victim['gender'])),
                _f('Occupation', _v(victim['occ'] ?? victim['occupation'])),
                _f('Mobile', _v(victim['mobile'])),
                _f('Aadhaar', _v(victim['aadhaar'])),
                _f('Religion', _v(victim['religion'])),
                _f('Caste', _v(victim['caste'])),
                _f('PAN Number', _v(victim['pan'])),
                if (_v(victim['address']).isNotEmpty)
                  _f('Address', _v(victim['address']), full: true),
              ]),
      ),
    );
  }

  // ── §7 Deceased KYC (Murder Cases) ─────────────────────────────────────────
  final Map deceased = (m['deceased'] is Map)
      ? (m['deceased'] as Map)
      : (m['deceased'] != null ? {'name': m['deceased'].toString()} : {});
  final bool hasDeceased = deceased.isNotEmpty &&
      (_v(deceased['name']).isNotEmpty ||
          _v(deceased['mobile']).isNotEmpty ||
          _v(deceased['aadhaar']).isNotEmpty);
  if (isMurder || hasDeceased) {
    sections.add(
      _card(
        secNum++,
        'DECEASED KYC',
        _teal,
        deceased.isEmpty
            ? _empty('No deceased data.')
            : _grid2([
                _f('Name', _v(deceased['name'])),
                _f('Age', _v(deceased['age'])),
                _f('Gender', _v(deceased['gender'])),
                _f('Occupation', _v(deceased['occ'] ?? deceased['occupation'])),
                _f('Mobile', _v(deceased['mobile'])),
                _f('Aadhaar', _v(deceased['aadhaar'])),
                _f('Religion', _v(deceased['religion'])),
                _f('Caste', _v(deceased['caste'])),
                _f('PAN Number', _v(deceased['pan'])),
                if (_v(deceased['address']).isNotEmpty)
                  _f('Address', _v(deceased['address']), full: true),
              ]),
      ),
    );
  }

  // ── §8 Injured Person KYC ─────────────────────────────────────────────
  final Map inj = (m['injured'] is Map)
      ? (m['injured'] as Map)
      : (m['injured'] != null ? {'name': m['injured'].toString()} : {});
  final hasInj = inj.isNotEmpty &&
      (inj['name']?.toString().trim().isNotEmpty == true ||
          inj['mobile']?.toString().trim().isNotEmpty == true ||
          inj['aadhaar']?.toString().trim().isNotEmpty == true ||
          inj['age']?.toString().trim().isNotEmpty == true);
  if (hasInj) {
    final isDied = inj['isDied'] == true;
    sections.add(
      _card(
        secNum++,
        'INJURED PERSON KYC',
        _teal,
        _grid2([
          _f('Name', _v(inj['name'])),
          _f('Age', _v(inj['age'])),
          _f('Gender', _v(inj['gender'])),
          _f('Occupation', _v(inj['occ'] ?? inj['occupation'])),
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
          if (_v(inj['address']).isNotEmpty)
            _f('Address', _v(inj['address']), full: true),
        ]),
      ),
    );
  }

  // ── §9 Accused Details ────────────────────────────────────────────────
  List<dynamic> accusedList = [];
  if (m['accused'] is List) {
    accusedList = m['accused'] as List;
  } else if (m['accused'] is Map) {
    accusedList = [m['accused']];
  } else if (m['accused'] != null &&
      m['accused'].toString().trim().isNotEmpty) {
    accusedList = [
      {
        'name': m['accused'].toString(),
        'age': m['accused_age'],
        'gender': m['accused_gender'],
        'mobile': m['accused_mobile'],
        'occupation': m['accused_occupation'] ?? m['accused_occ'],
        'address': m['accused_address'],
        'aadhaar': m['accused_aadhaar'],
        'pan': m['accused_pan'],
        'religion': m['accused_religion'],
        'caste': m['accused_caste'],
      }
    ];
  } else if (m['accused_name'] != null &&
      m['accused_name'].toString().trim().isNotEmpty) {
    accusedList = [
      {
        'name': m['accused_name'].toString(),
        'age': m['accused_age'],
        'gender': m['accused_gender'],
        'mobile': m['accused_mobile'],
        'occupation': m['accused_occupation'] ?? m['accused_occ'],
        'address': m['accused_address'],
        'aadhaar': m['accused_aadhaar'],
        'pan': m['accused_pan'],
        'religion': m['accused_religion'],
        'caste': m['accused_caste'],
      }
    ];
  }

  if (isUnknown) {
    sections.add(
      _card(
        secNum++,
        'ACCUSED DETAILS',
        _teal,
        _badge('Unknown / Untraced', _amber),
      ),
    );
  } else if (accusedList.isEmpty) {
    sections.add(
      _card(
        secNum++,
        'ACCUSED DETAILS',
        _teal,
        _empty('No accused added.'),
      ),
    );
  } else {
    const accusedChunkSize = 2;
    final int baseSec = secNum++;
    for (var i = 0; i < accusedList.length; i += accusedChunkSize) {
      final chunk = accusedList.sublist(
        i,
        (i + accusedChunkSize) > accusedList.length
            ? accusedList.length
            : (i + accusedChunkSize),
      );
      final isFirst = i == 0;
      sections.add(
        _card(
          isFirst ? baseSec : 0,
          isFirst ? 'ACCUSED DETAILS' : 'ACCUSED DETAILS (CONT.)',
          _teal,
          pw.Column(
            children: chunk.asMap().entries.map((e) {
              final idx = i + e.key;
              final Map<String, dynamic> itemMap = (e.value is Map)
                  ? Map<String, dynamic>.from(e.value as Map)
                  : {'name': e.value.toString()};
              return _personBlock(
                'Accused #${idx + 1}',
                itemMap,
              );
            }).toList(),
          ),
        ),
      );
    }
  }

  // ── §10 Suspected Accused ──────────────────────────────────────────────
  List<dynamic> suspectedList = [];
  if (m['suspectedAccused'] is List) {
    suspectedList = m['suspectedAccused'] as List;
  } else if (m['suspectedAccused'] is Map) {
    suspectedList = [m['suspectedAccused']];
  } else if (m['suspected_accused'] is List) {
    suspectedList = m['suspected_accused'] as List;
  } else if (m['suspected_accused_name'] != null &&
      m['suspected_accused_name'].toString().trim().isNotEmpty) {
    suspectedList = [
      {'name': m['suspected_accused_name'].toString()}
    ];
  }

  if (suspectedList.isNotEmpty && !isUnknown) {
    sections.add(
      _card(
        secNum++,
        'SUSPECTED ACCUSED',
        _teal,
        pw.Column(
          children: suspectedList.asMap().entries.map(
            (e) {
              final Map<String, dynamic> itemMap = (e.value is Map)
                  ? Map<String, dynamic>.from(e.value as Map)
                  : {'name': e.value.toString()};
              return _personBlock(
                'Suspected #${e.key + 1}',
                itemMap,
              );
            },
          ).toList(),
        ),
      ),
    );
  }

  // ── §11 Unidentified Criminal Description ───────────────────────────
  final List<dynamic> unidentifiedList = (m['unidentifiedList'] is List)
      ? (m['unidentifiedList'] as List)
      : ((m['unidentified_accused'] is List)
          ? (m['unidentified_accused'] as List)
          : []);
  if (unidentifiedList.isNotEmpty) {
    sections.add(
      _card(
        secNum++,
        'UNIDENTIFIED CRIMINAL DESCRIPTION',
        _amber,
        pw.Column(
          children: unidentifiedList.asMap().entries.map((e) {
            final Map u = (e.value is Map)
                ? (e.value as Map)
                : {'description': e.value.toString()};
            return _subCard(
              _grid2([
                _f('Gender', _v(u['gender'])),
                _f('Approx Age', _v(u['approxAge'] ?? u['approximate_age'])),
                _f('Skin Color', _v(u['skinColor'] ?? u['skin_colour'])),
                _f('Approx Height', _v(u['approxHeight'] ?? u['height'])),
                _f('Mobile (if known)', _v(u['mobile'])),
                _f('Occupation (possible)',
                    _v(u['occupation'] ?? u['possible_occupation'])),
                _f('Last Known Address',
                    _v(u['lastKnownAddress'] ?? u['address']),
                    full: true),
                _f(
                    'Other Physical Markers',
                    _v(u['otherPhysicalMarkers'] ??
                        u['identification_mark'] ??
                        u['description']),
                    full: true),
              ]),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── §12 Unknown Criminal Description ─────────────────────────────────
  final List<dynamic> unknownList = (m['unknownList'] is List)
      ? (m['unknownList'] as List)
      : ((m['unknown_accused'] is List) ? (m['unknown_accused'] as List) : []);
  if (unknownList.isNotEmpty) {
    sections.add(
      _card(
        secNum++,
        'UNKNOWN CRIMINAL DESCRIPTION',
        _amber,
        pw.Column(
          children: unknownList.asMap().entries.map((e) {
            final Map u = (e.value is Map)
                ? (e.value as Map)
                : {'description': e.value.toString()};
            return _subCard(
              _grid2([
                _f('Gender', _v(u['gender'])),
                _f('Approx Age', _v(u['approxAge'] ?? u['approximate_age'])),
                _f('Skin Color', _v(u['skinColor'] ?? u['skin_colour'])),
                _f('Approx Height', _v(u['approxHeight'] ?? u['height'])),
                _f('Mobile (if known)', _v(u['mobile'])),
                _f('Occupation (possible)',
                    _v(u['occupation'] ?? u['possible_occupation'])),
                _f('Last Known Address',
                    _v(u['lastKnownAddress'] ?? u['address']),
                    full: true),
                _f(
                    'Other Physical Markers',
                    _v(u['otherPhysicalMarkers'] ??
                        u['identification_mark'] ??
                        u['description']),
                    full: true),
              ]),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── §13 Case Responsibility ──────────────────────────────────────────
  final Map cr8;
  if (m['caseResponsibility'] is Map) {
    cr8 = m['caseResponsibility'] as Map;
  } else {
    cr8 = {
      'ioDesig': m['io_designation'] ?? m['ioDesig'] ?? '',
      'ioName': m['io_name'] ??
          m['ioName'] ??
          m['investigating_officer'] ??
          m['assigned_officer'] ??
          '',
      'regDesig': m['registered_by_designation'] ?? m['regDesig'] ?? '',
      'regName': m['registered_by_name'] ?? m['regName'] ?? '',
      'cctvValue':
          (m['cctv_checked'] == true || m['cctv_checked']?.toString() == 'true')
              ? 'Yes'
              : (m['cctvValue'] ?? 'No'),
      'cctvDateTime': m['cctv_datetime'] ?? m['cctvDateTime'] ?? '',
    };
  }
  sections.add(
    _card(
      secNum++,
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

  // ── §14 Arrest & Release Status ─────────────────────────────────────
  List<dynamic> arrests = [];
  if (m['arrestRelease'] is List) {
    arrests = m['arrestRelease'] as List;
  } else if (m['arrests'] is List) {
    arrests = m['arrests'] as List;
  } else if (m['arrest_records'] is List) {
    arrests = m['arrest_records'] as List;
  }
  final sec8283 = m['section8283Action']?.toString();
  final hasSec8283 = _v(sec8283).isNotEmpty &&
      _v(sec8283).toUpperCase() != 'NOT SET' &&
      _v(sec8283) != '-';
  if (arrests.isNotEmpty || hasSec8283) {
    final int arrestSec = secNum++;
    if (arrests.isEmpty) {
      sections.add(
        _card(
          arrestSec,
          'ARREST & RELEASE STATUS',
          _teal,
          _grid2([
            _f('Section 82/83 Action (if untraceable)',
                _v(sec8283).toUpperCase(),
                full: true),
          ]),
        ),
      );
    } else {
      const arrestChunkSize = 2;
      for (var i = 0; i < arrests.length; i += arrestChunkSize) {
        final chunk = arrests.sublist(
          i,
          (i + arrestChunkSize) > arrests.length
              ? arrests.length
              : (i + arrestChunkSize),
        );
        final isFirst = i == 0;
        sections.add(
          _card(
            isFirst ? arrestSec : 0,
            isFirst
                ? 'ARREST & RELEASE STATUS'
                : 'ARREST & RELEASE STATUS (CONT.)',
            _teal,
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (isFirst) ...[
                  _grid2([
                    _f(
                      'Section 82/83 Action (if untraceable)',
                      _v(sec8283, or: 'Not set').toUpperCase(),
                      full: true,
                    ),
                  ]),
                  pw.SizedBox(height: 6),
                ],
                ...chunk.map((r) {
                  final Map row =
                      (r is Map) ? r : {'accusedName': r.toString()};
                  return _subCard(
                    _grid2([
                      _f(
                          'Accused Name',
                          _v(row['accusedName'] ??
                              row['name'] ??
                              row['person_name'])),
                      _f('Arrest Date & Time',
                          _v(row['arrestDt'] ?? row['arrest_datetime'])),
                      _f('Release Date',
                          _v(row['releaseDt'] ?? row['release_date'])),
                      _f('Arrest Location',
                          _v(row['arrestLoc'] ?? row['arrest_location'])),
                      _f('Arresting Officer',
                          _v(row['arrestOfficer'] ?? row['arresting_officer'])),
                      _f('Relative Name',
                          _v(row['relName'] ?? row['relative_friend_name'])),
                      _f(
                          'Relationship',
                          _v(row['relationship'] ??
                              row['relative_friend_relation'])),
                      _f('Notice Issued?', _v(row['noticeIssued'], or: 'No')),
                      if (_v(row['noticeDt'] ??
                              row['release_on_notice_datetime'])
                          .isNotEmpty)
                        _f(
                            'Notice Date',
                            _v(row['noticeDt'] ??
                                row['release_on_notice_datetime'])),
                      if (_v(row['relOnNotice']).isNotEmpty)
                        _f('Released on Notice', _v(row['relOnNotice'])),
                      _f('Wanted / Absconding Status',
                          _v(row['wantedStatus'], or: 'Not Wanted')),
                      _f('Release Type', _v(row['releaseType'])),
                    ]),
                  );
                }),
              ],
            ),
          ),
        );
      }
    }
  }

  // ── §15 Procedural Details ──────────────────────────────────────────
  final procChecks =
      (m['proceduralChecks'] is Map) ? (m['proceduralChecks'] as Map) : {};
  final procDates =
      (m['proceduralDates'] is Map) ? (m['proceduralDates'] as Map) : {};
  final vuPdf = (m['vehicleUsage'] is Map) ? (m['vehicleUsage'] as Map) : {};
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
    final k = e.key;
    final name = e.value;
    final isChecked = procChecks[k] == true ||
        procChecks[name] == true ||
        m[k] == true ||
        m[k]?.toString().toLowerCase() == 'true' ||
        _v(procDates[k]).isNotEmpty ||
        _v(procDates[name]).isNotEmpty;
    if (isChecked) {
      final dateVal =
          _v(procDates[k], or: _v(procDates[name], or: 'Completed'));
      selectedProcedural.add(_f(name, dateVal));
    }
  }
  // Check for common snake_case panchanama keys
  if (selectedProcedural.isEmpty) {
    if (m['spot_panchanama'] == true ||
        m['spot_panchanama']?.toString() == 'true') {
      selectedProcedural.add(_f(
          'Spot Panchanama', _v(m['spot_panchanama_date'], or: 'Completed')));
    }
    if (m['seizure_panchanama'] == true ||
        m['seizure_panchanama']?.toString() == 'true') {
      selectedProcedural.add(_f('Seizure Panchanama',
          _v(m['seizure_panchanama_date'], or: 'Completed')));
    }
    if (m['inquest_panchanama'] == true ||
        m['inquest_panchanama']?.toString() == 'true') {
      selectedProcedural.add(_f('Inquest Panchanama',
          _v(m['inquest_panchanama_date'], or: 'Completed')));
    }
  }

  sections.add(
    _card(
      secNum++,
      'PROCEDURAL DETAILS',
      _teal,
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (selectedProcedural.isNotEmpty) ...[
            _grid2(selectedProcedural),
            pw.SizedBox(height: 6),
          ],
          _grid2([
            _f(
                'E-Shakshya',
                _v(m['eshakshValue'],
                    or: (m['e_shakshya'] == true ? 'Yes' : 'Not set'))),
            if (m['eshakshValue'] == 'yes' &&
                (m['eshakshDt']?.toString().isNotEmpty ?? false))
              _f('E-Shakshya Date & Time', _v(m['eshakshDt']))
            else if (m['eshakshValue'] == 'no' &&
                (m['eshakshReason']?.toString().isNotEmpty ?? false))
              _f('Reason for No E-Shakshya', _v(m['eshakshReason'])),
            if (m['fingerprint_taken'] == true ||
                m['fingerprint_taken']?.toString() == 'true')
              _f('Fingerprints Taken', 'Yes'),
            if (m['cctv_checked'] == true ||
                m['cctv_checked']?.toString() == 'true')
              _f('CCTV Footage Checked', 'Yes'),
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

  // ── §16 Seizure Records ─────────────────────────────────────────────
  List<dynamic> seizures = [];
  if (m['seizures'] is List) {
    seizures = m['seizures'] as List;
  } else if (m['seizure_items'] is List) {
    seizures = m['seizure_items'] as List;
  } else if (_v(m['object_name']).isNotEmpty ||
      _v(m['seizure_description']).isNotEmpty) {
    seizures = [
      {
        'desc': _v(m['seizure_description'], or: m['object_name']),
        'fromWhom': _v(m['seizure_from'], or: 'Crime Spot'),
        'recoveryDate': _v(m['seizure_date']),
        'custodyLoc': _v(m['seizure_location'], or: 'Police Station Malkhana'),
      }
    ];
  }

  if (seizures.isNotEmpty) {
    final int seizureSec = secNum++;
    const seizureChunkSize = 3;
    for (var i = 0; i < seizures.length; i += seizureChunkSize) {
      final chunk = seizures.sublist(
        i,
        (i + seizureChunkSize) > seizures.length
            ? seizures.length
            : (i + seizureChunkSize),
      );
      final isFirst = i == 0;
      sections.add(
        _card(
          isFirst ? seizureSec : 0,
          isFirst ? 'SEIZURE RECORDS' : 'SEIZURE RECORDS (CONT.)',
          _teal,
          pw.Column(
            children: chunk.asMap().entries.map((e) {
              final Map s = (e.value is Map)
                  ? (e.value as Map)
                  : {'desc': e.value.toString()};
              return _subCard(
                _grid2([
                  _f('Property Description', _v(s['desc'] ?? s['property']),
                      full: true),
                  _f('Seized From', _v(s['fromWhom'], or: '-')),
                  _f('Other Name', _v(s['otherName'])),
                  if (_v(s['quantity']).isNotEmpty)
                    _f('Quantity', _v(s['quantity'])),
                  if (_v(s['serialNo']).isNotEmpty)
                    _f('Serial / ID No.', _v(s['serialNo'])),
                  if (_v(s['estValue']).isNotEmpty)
                    _f('Est. Value', _v(s['estValue'])),
                  if (_v(s['status']).isNotEmpty) _f('Status', _v(s['status'])),
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
    }
  }

  // ── §17 Technical & Custody ─────────────────────────────────────────
  List<dynamic> custodyList = [];
  if (m['custodyInfo'] is List) {
    custodyList = m['custodyInfo'] as List;
  } else if (m['custody_records'] is List) {
    custodyList = m['custody_records'] as List;
  } else if (m['remand_custody'] is List) {
    custodyList = m['remand_custody'] as List;
  }

  final hasCdr = _v(m['cdrSent'] ?? m['cdr_sent_date']).isNotEmpty ||
      _v(m['cdrRecv'] ?? m['cdr_recv_date']).isNotEmpty;

  if (hasCdr || custodyList.isNotEmpty) {
    final int techSec = secNum++;
    if (custodyList.isEmpty) {
      sections.add(
        _card(
          techSec,
          'TECHNICAL & CUSTODY',
          _teal,
          _grid2([
            _f('CDR Sent Date', _v(m['cdrSent'] ?? m['cdr_sent_date'])),
            _f('CDR Received Date', _v(m['cdrRecv'] ?? m['cdr_recv_date'])),
          ]),
        ),
      );
    } else {
      for (var i = 0; i < custodyList.length; i++) {
        final c = custodyList[i];
        final isFirst = i == 0;
        final Map row = (c is Map) ? c : {'accusedName': c.toString()};
        final accName = _v(row['accusedName'],
            or: _v(row['suretyAccusedName'], or: 'Accused'));

        sections.add(
          _card(
            isFirst ? techSec : 0,
            isFirst ? 'TECHNICAL & CUSTODY' : 'TECHNICAL & CUSTODY (CONT.)',
            _teal,
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (isFirst && hasCdr) ...[
                  _grid2([
                    _f('CDR Sent Date', _v(m['cdrSent'] ?? m['cdr_sent_date'])),
                    _f('CDR Received Date',
                        _v(m['cdrRecv'] ?? m['cdr_recv_date'])),
                  ]),
                  pw.SizedBox(height: 6),
                ],
                _subCard(
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
                        _f('PCR Start',
                            _v(row['pcrStart'] ?? row['pcr_start_date'])),
                        _f('PCR End', _v(row['pcrEnd'] ?? row['pcr_end_date'])),
                        _f('PCR Days', _v(row['pcrDays'] ?? row['pcr_days'])),
                        _f('Court / Order Details',
                            _v(row['pcrDetails'] ?? row['pcr_details'])),
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
                        _f('MCR Start',
                            _v(row['mcrStart'] ?? row['mcr_start_date'])),
                        _f('MCR End', _v(row['mcrEnd'] ?? row['mcr_end_date'])),
                        _f('MCR Days', _v(row['mcrDays'] ?? row['mcr_days'])),
                        _f('Jail Name / Details',
                            _v(row['mcrJail'] ?? row['jail_date'])),
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
                        _f('PR Bond Date',
                            _v(row['prBondDate'] ?? row['pr_bond_date'])),
                        if (_v(row['prBondDetails']).isNotEmpty)
                          _f('PR Bond Amount / Details',
                              _v(row['prBondDetails']),
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
                        _f('Surety Name',
                            _v(row['suretyName'] ?? row['surety_name'])),
                        _f('Surety Age',
                            _v(row['suretyAge'] ?? row['surety_age'])),
                        _f('Surety Gender',
                            _v(row['suretyGender'] ?? row['surety_gender'])),
                        _f('Surety Relationship',
                            _v(row['suretyRel'] ?? row['surety_relation'])),
                        _f('Surety Occupation',
                            _v(row['suretyOcc'] ?? row['surety_occupation'])),
                        _f('Surety Mobile',
                            _v(row['suretyMobile'] ?? row['surety_mobile'])),
                        _f('Surety Aadhaar',
                            _v(row['suretyAadhaar'] ?? row['surety_aadhaar'])),
                        _f('Surety PAN',
                            _v(row['suretyPan'] ?? row['surety_pan'])),
                        _f('Surety Address',
                            _v(row['suretyAddress'] ?? row['surety_address']),
                            full: true),
                        if (_v(row['suretyDetails']).isNotEmpty)
                          _f('Surety Bond Details', _v(row['suretyDetails']),
                              full: true),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  // ── §18 Preventive & Bonds ──────────────────────────────────────────
  final Map prev = (m['preventive'] is Map)
      ? (m['preventive'] as Map)
      : ((m['preventive_actions'] is List &&
              (m['preventive_actions'] as List).isNotEmpty)
          ? ((m['preventive_actions'] as List).first is Map
              ? (m['preventive_actions'] as List).first as Map
              : {})
          : {});
  final isBondYes = (prev['preventiveBonds'] ?? prev['prBond']) == 'yes';
  final hasAction = _v(prev['action'] ?? prev['action_type']).isNotEmpty &&
      _v(prev['action'] ?? prev['action_type']) != 'Not set' &&
      _v(prev['action'] ?? prev['action_type']) != '-';
  final hasActionDate = _v(prev['actionDate']).isNotEmpty;

  if (isBondYes || hasAction || hasActionDate) {
    final prevFields = <_FD>[
      _f(
        'Preventive Bonds',
        _v(prev['preventiveBonds'] ?? prev['prBond'], or: 'No'),
      ),
    ];
    if (isBondYes) {
      prevFields.add(_f('PR Bond Date', _v(prev['bondDate'])));
      prevFields
          .add(_f('Bond Cancellation Date', _v(prev['bondCancellation'])));
      prevFields.add(_f('Reason for PR Bond', _v(prev['bondReason'])));
    }
    if (hasAction) {
      prevFields
          .add(_f('Action Type', _v(prev['action'] ?? prev['action_type'])));
    }
    if (hasActionDate) {
      prevFields.add(
        _f(
          '${prev['action'] ?? prev['action_type'] ?? 'Action Type'} Date & Time',
          _v(prev['actionDate']),
        ),
      );
    }
    sections.add(
      _card(
        secNum++,
        'PREVENTIVE & BONDS',
        _teal,
        _grid2(prevFields),
      ),
    );
  }

  // ── §19 Discharge Status ────────────────────────────────────────────
  final Map discharge =
      (m['dischargeByAccused'] is Map) ? (m['dischargeByAccused'] as Map) : {};
  final Map disDetails =
      (m['dischargeDetails'] is Map) ? (m['dischargeDetails'] as Map) : {};
  final hasDischarged = discharge.values.any((v) => v == true);
  if (hasDischarged) {
    sections.add(
      _card(
        secNum++,
        'DISCHARGE STATUS',
        _teal,
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: discharge.entries.where((e) => e.value == true).map((e) {
            final name = e.key.toString();
            final det =
                (disDetails[name] is Map) ? (disDetails[name] as Map) : {};
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      _checkbox(true, color: _green),
                      pw.SizedBox(width: 6),
                      pw.Text(
                        '$name - Discharged',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: _dark,
                        ),
                      ),
                    ],
                  ),
                  if (det.isNotEmpty) ...[
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
  }

  // ── §20 Court Filing ────────────────────────────────────────────────
  final Map court = (m['court'] is Map) ? (m['court'] as Map) : {};
  final csNo = _v(court['chargeSheetNumber'] ?? m['charge_sheet_no']);
  final csDate = _v(court['chargeSheetDate'] ?? m['charge_sheet_date']);
  if (csNo.isNotEmpty || csDate.isNotEmpty) {
    sections.add(
      _card(
        secNum++,
        'COURT FILING',
        _teal,
        _grid2([
          _f('Charge Sheet No.', csNo),
          _f('Charge Sheet Date', csDate),
        ]),
      ),
    );
  }

  // ── §21 Case Scrutiny Pipeline ──────────────────────────────────────
  final Map sc = (m['scrutiny'] is Map) ? (m['scrutiny'] as Map) : {};
  final hasScrutiny = _v(sc['sdpoSend']).isNotEmpty ||
      _v(sc['sdpoGrant']).isNotEmpty ||
      _v(sc['appSend']).isNotEmpty ||
      _v(sc['appGrant']).isNotEmpty ||
      _v(sc['dcpSend']).isNotEmpty ||
      _v(sc['dcpGrant']).isNotEmpty;
  if (hasScrutiny) {
    sections.add(
      _card(
        secNum++,
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
              sc['stepAppActive'] == true || _v(sc['appSend']).isNotEmpty,
              send: _v(sc['appSend']),
              grant: _v(sc['appGrant']),
              lockedMsg: 'Pending SDPO Approval',
            ),
            _scrutinyStep(
              3,
              'Addl SP / DCP / Addl CP',
              sc['stepDcpActive'] == true || _v(sc['dcpSend']).isNotEmpty,
              send: _v(sc['dcpSend']),
              grant: _v(sc['dcpGrant']),
              lockedMsg: 'Pending APP Scrutiny',
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  // ── §22 Final Verdict ───────────────────────────────────────────────
  final Map verdict = (m['verdict'] is Map) ? (m['verdict'] as Map) : {};
  final acquitted = (verdict['acquitted'] is List)
      ? (verdict['acquitted'] as List).map((x) => x.toString()).toList()
      : <String>[];
  final convicted = (verdict['convicted'] is List)
      ? (verdict['convicted'] as List).map((x) => x.toString()).toList()
      : <String>[];
  final ccSt = _v(court['ccStNumber'] ?? m['cc_st_number']);
  final fSummary = _v(court['finalSummary'] ?? m['final_summary']);
  final quashed = _v(court['quashedHighCourt'] ?? m['quashed_by_high_court']);

  final hasVerdict = acquitted.isNotEmpty ||
      convicted.isNotEmpty ||
      ccSt.isNotEmpty ||
      (fSummary.isNotEmpty && fSummary != 'Not set') ||
      quashed.isNotEmpty;

  if (hasVerdict) {
    sections.add(
      _card(
        secNum++,
        'FINAL VERDICT',
        _teal,
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _grid2([
              _f('CC / ST Number', ccSt),
              _f('Final Summary', fSummary.isEmpty ? '-' : fSummary),
              _f('Quashed by High Court', quashed),
            ]),
            if (acquitted.isNotEmpty || convicted.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                      child: _verdictCol('✓ ACQUITTED', acquitted, _green)),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                      child: _verdictCol('✗ CONVICTED', convicted, _red)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EXTRA FIELDS — 100% DYNAMIC (Module-specific only, standard keys filtered)
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
    if (e.value == null) continue;
    if (e.value is String && (e.value as String).trim().isEmpty) continue;
    if (e.value is Map && (e.value as Map).isEmpty) continue;
    if (e.value is List && (e.value as List).isEmpty) continue;
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
    pw.Container(
      margin: const pw.EdgeInsets.only(bottom: PdfLayoutConstants.sectionGap),
      decoration: pw.BoxDecoration(
        color: _white,
        borderRadius: pw.BorderRadius.circular(PdfLayoutConstants.borderRadius),
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
  var i = 0;
  while (i < fields.length) {
    final f = fields[i];
    if (f.full) {
      rows.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: PdfLayoutConstants.rowGap),
          child: _fWidget(f.label, f.value),
        ),
      );
      i++;
    } else {
      final left = f;
      final right =
          (i + 1 < fields.length && !fields[i + 1].full) ? fields[i + 1] : null;
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
      i += (right != null ? 2 : 1);
    }
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
            _f('Occupation', _v(person['occ'] ?? person['occupation'])),
            _f('Mobile', _v(person['mobile'])),
            _f('Aadhaar', _v(person['aadhaar'])),
            _f('Religion', _v(person['religion'])),
            _f('Caste', _v(person['caste'])),
            _f('PAN', _v(person['pan'])),
            if (_v(person['alias'] ?? person['nickname']).isNotEmpty)
              _f('Alias / Nickname', _v(person['alias'] ?? person['nickname'])),
            if (_v(person['address'] ?? person['full_address']).isNotEmpty)
              _f('Address', _v(person['address'] ?? person['full_address']),
                  full: true),
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

Map<String, String>? _actSectionMapCache;

Map<String, String> _getActSectionMap() {
  if (_actSectionMapCache != null) return _actSectionMapCache!;
  final Map<String, String> actSectionMap = {};
  for (final actEntry in BackendCaseService.cachedActData.entries) {
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
  _actSectionMapCache = actSectionMap;
  return actSectionMap;
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

  final actSectionMap = _getActSectionMap();

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
