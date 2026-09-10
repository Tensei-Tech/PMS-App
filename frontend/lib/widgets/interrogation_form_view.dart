import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'form_paper_page.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';

/// चौकशी अहवाल — स्थानिक गुन्हे शाखा,उस्मानाबाद (7-Page Exact Table Format)
class InterrogationFormView extends StatefulWidget {
  final bool readOnly;
  final String? formSection;
  final String? pageRange;

  const InterrogationFormView({
    super.key,
    this.readOnly = false,
    this.formSection,
    this.pageRange,
  });

  @override
  State<InterrogationFormView> createState() => InterrogationFormViewState();
}

class InterrogationFormViewState extends State<InterrogationFormView> {
  // ── PAGE 1 CONTROLLERS (Rows 1–10) ──
  final _psCtrl = TextEditingController();
  final _gurNoCtrl = TextEditingController();
  final _gurYearCtrl = TextEditingController();
  final _kalamCtrl = TextEditingController();
  final _ioCtrl = TextEditingController();
  final _accusedCtrl = TextEditingController();
  final _arrestDtCtrl = TextEditingController();
  final _dobPlaceAgeCtrl = TextEditingController();

  static const _physicalFeatures = [
    'उंची',
    'बांधा',
    'केस',
    'भुवया',
    'कपाळ',
    'डोळे',
    'दृष्टी',
    'नाक',
    'ओंट',
    'छाती',
    'बोटे',
    'हनुवटी',
    'कान',
    'चेहरा',
    'वर्ण',
    'दाढी',
    'मिशा',
    'भाषा',
    'गाल',
    'पोशाख',
    'व्यसन',
  ];

  late final Map<String, TextEditingController> _physicalTableCtrls = {
    for (final f in _physicalFeatures) f: TextEditingController(),
  };

  final _idMarksCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _dharmaCtrl = TextEditingController();
  final _jatiCtrl = TextEditingController();

  // ── PAGE 2 CONTROLLERS (Rows 11–15) ──
  late final List<TextEditingController> _page2Rows =
      List.generate(5, (_) => TextEditingController());

  // ── PAGE 3 CONTROLLERS (Rows 16–21) ──
  late final List<TextEditingController> _page3Rows =
      List.generate(6, (_) => TextEditingController());

  // ── PAGE 4 CONTROLLERS (Rows 22–30) ──
  late final List<TextEditingController> _page4Rows =
      List.generate(9, (_) => TextEditingController());

  // ── PAGE 5 CONTROLLERS (Rows 31–36) ──
  late final List<TextEditingController> _page5Rows =
      List.generate(6, (_) => TextEditingController());

  // ── PAGE 6 CONTROLLERS (Rows 37–40 + Signatures) ──
  late final List<TextEditingController> _page6Rows =
      List.generate(4, (_) => TextEditingController());
  final _ioSigNameCtrl = TextEditingController();
  final _ioSigRankCtrl = TextEditingController();
  final _ioSigCodeCtrl = TextEditingController();
  final _ioSigPostingCtrl = TextEditingController();

  // ── PAGE 7 CONTROLLERS (मुद्दा क्रमांक ३७ ची अधिक माहिती) ──
  final _additional37Ctrl = TextEditingController();

  @override
  void dispose() {
    _psCtrl.dispose();
    _gurNoCtrl.dispose();
    _gurYearCtrl.dispose();
    _kalamCtrl.dispose();
    _ioCtrl.dispose();
    _accusedCtrl.dispose();
    _arrestDtCtrl.dispose();
    _dobPlaceAgeCtrl.dispose();
    _idMarksCtrl.dispose();
    _addressCtrl.dispose();
    _dharmaCtrl.dispose();
    _jatiCtrl.dispose();

    _ioSigNameCtrl.dispose();
    _ioSigRankCtrl.dispose();
    _ioSigCodeCtrl.dispose();
    _ioSigPostingCtrl.dispose();
    _additional37Ctrl.dispose();

    for (final c in _physicalTableCtrls.values) {
      c.dispose();
    }
    for (final c in _page2Rows) {
      c.dispose();
    }
    for (final c in _page3Rows) {
      c.dispose();
    }
    for (final c in _page4Rows) {
      c.dispose();
    }
    for (final c in _page5Rows) {
      c.dispose();
    }
    for (final c in _page6Rows) {
      c.dispose();
    }
    super.dispose();
  }

  String get _physicalDescriptionSummary {
    final parts = <String>[];
    for (final key in _physicalFeatures) {
      final val = _physicalTableCtrls[key]?.text.trim() ?? '';
      if (val.isNotEmpty) {
        parts.add('$key: $val');
      }
    }
    return parts.join(', ');
  }

  Map<String, dynamic> collectData() {
    final gurCombined = _gurYearCtrl.text.trim().isNotEmpty
        ? '${_gurNoCtrl.text.trim()} / ${_gurYearCtrl.text.trim()}'
        : _gurNoCtrl.text.trim();

    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'ps': _psCtrl.text.trim(),
      'gurNo': gurCombined,
      'gurNumberOnly': _gurNoCtrl.text.trim(),
      'gurYear': _gurYearCtrl.text.trim(),
      'kalam': _kalamCtrl.text.trim(),
      'ioName': _ioCtrl.text.trim(),
      'accusedName': _accusedCtrl.text.trim(),
      'arrestDateTime': _arrestDtCtrl.text.trim(),
      'dobPlaceAge': _dobPlaceAgeCtrl.text.trim(),
      'physicalDescription': _physicalDescriptionSummary,
      'physicalTable': {
        for (final entry in _physicalTableCtrls.entries)
          entry.key: entry.value.text.trim(),
      },
      'idMarks': _idMarksCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'dharma': _dharmaCtrl.text.trim(),
      'jati': _jatiCtrl.text.trim(),
      'familyRows': [
        ..._page2Rows.map((c) => c.text.trim()),
        ..._page3Rows.map((c) => c.text.trim()),
      ],
      'page2Rows': _page2Rows.map((c) => c.text.trim()).toList(),
      'page3Rows': _page3Rows.map((c) => c.text.trim()).toList(),
      'idHistoryRows': _page4Rows.map((c) => c.text.trim()).toList(),
      'page4Rows': _page4Rows.map((c) => c.text.trim()).toList(),
      'crimeRows': [
        ..._page5Rows.map((c) => c.text.trim()),
        ..._page6Rows.map((c) => c.text.trim()),
      ],
      'page5Rows': _page5Rows.map((c) => c.text.trim()).toList(),
      'page6Rows': _page6Rows.map((c) => c.text.trim()).toList(),
      'ioSigName': _ioSigNameCtrl.text.trim(),
      'ioSigRank': _ioSigRankCtrl.text.trim(),
      'ioSigCode': _ioSigCodeCtrl.text.trim(),
      'ioSigPosting': _ioSigPostingCtrl.text.trim(),
      'additionalPoint37': _additional37Ctrl.text.trim(),
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    setState(() {
      _psCtrl.text = data['ps']?.toString() ?? '';
      final rawGur = data['gurNo']?.toString() ?? '';
      if (rawGur.contains('/')) {
        final p = rawGur.split('/');
        _gurNoCtrl.text = p[0].trim();
        _gurYearCtrl.text = p[1].trim();
      } else {
        _gurNoCtrl.text = data['gurNumberOnly']?.toString() ?? rawGur;
        _gurYearCtrl.text = data['gurYear']?.toString() ?? '';
      }
      _kalamCtrl.text = data['kalam']?.toString() ?? '';
      _ioCtrl.text = data['ioName']?.toString() ?? '';
      _accusedCtrl.text = data['accusedName']?.toString() ?? '';
      _arrestDtCtrl.text = data['arrestDateTime']?.toString() ?? '';
      _dobPlaceAgeCtrl.text = data['dobPlaceAge']?.toString() ?? '';
      _idMarksCtrl.text = data['idMarks']?.toString() ?? '';
      _addressCtrl.text = data['address']?.toString() ?? '';
      _dharmaCtrl.text = data['dharma']?.toString() ?? '';
      _jatiCtrl.text = data['jati']?.toString() ?? '';

      _ioSigNameCtrl.text = data['ioSigName']?.toString() ?? '';
      _ioSigRankCtrl.text = data['ioSigRank']?.toString() ?? '';
      _ioSigCodeCtrl.text = data['ioSigCode']?.toString() ?? '';
      _ioSigPostingCtrl.text = data['ioSigPosting']?.toString() ?? '';
      _additional37Ctrl.text = data['additionalPoint37']?.toString() ?? '';

      if (data['physicalTable'] is Map) {
        final tableData =
            Map<String, dynamic>.from(data['physicalTable'] as Map);
        for (final entry in _physicalTableCtrls.entries) {
          entry.value.text = tableData[entry.key]?.toString() ??
              (entry.key == 'ओट' ? (tableData['ओठ']?.toString() ?? '') : '');
        }
      } else if (data['physicalDescription'] != null) {
        final raw = data['physicalDescription'].toString();
        if (raw.contains(':')) {
          final pairs = raw.split(',');
          for (final pair in pairs) {
            final parts = pair.split(':');
            if (parts.length == 2) {
              final k = parts[0].trim();
              final v = parts[1].trim();
              if (_physicalTableCtrls.containsKey(k)) {
                _physicalTableCtrls[k]!.text = v;
              } else if (k == 'ओठ' && _physicalTableCtrls.containsKey('ओट')) {
                _physicalTableCtrls['ओट']!.text = v;
              }
            }
          }
        }
      }

      // Page 2 & 3
      if (data['page2Rows'] is List) {
        _hydrateList(data['page2Rows'], _page2Rows);
      } else if (data['familyRows'] is List) {
        final fam = data['familyRows'] as List;
        for (var i = 0; i < _page2Rows.length && i < fam.length; i++) {
          _page2Rows[i].text = fam[i]?.toString() ?? '';
        }
      }

      if (data['page3Rows'] is List) {
        _hydrateList(data['page3Rows'], _page3Rows);
      } else if (data['familyRows'] is List) {
        final fam = data['familyRows'] as List;
        for (var i = 0; i < _page3Rows.length; i++) {
          final idx = 5 + i;
          if (idx < fam.length) {
            _page3Rows[i].text = fam[idx]?.toString() ?? '';
          }
        }
      }

      // Page 4
      if (data['page4Rows'] is List) {
        _hydrateList(data['page4Rows'], _page4Rows);
      } else if (data['idHistoryRows'] is List) {
        _hydrateList(data['idHistoryRows'], _page4Rows);
      }

      // Page 5 & 6
      if (data['page5Rows'] is List) {
        _hydrateList(data['page5Rows'], _page5Rows);
      } else if (data['crimeRows'] is List) {
        final cr = data['crimeRows'] as List;
        for (var i = 0; i < _page5Rows.length && i < cr.length; i++) {
          _page5Rows[i].text = cr[i]?.toString() ?? '';
        }
      }

      if (data['page6Rows'] is List) {
        _hydrateList(data['page6Rows'], _page6Rows);
      } else if (data['crimeRows'] is List) {
        final cr = data['crimeRows'] as List;
        for (var i = 0; i < _page6Rows.length; i++) {
          final idx = 6 + i;
          if (idx < cr.length) {
            _page6Rows[i].text = cr[idx]?.toString() ?? '';
          }
        }
      }
    });
  }

  void _hydrateList(dynamic raw, List<TextEditingController> ctrls) {
    if (raw is! List) return;
    for (var i = 0; i < ctrls.length && i < raw.length; i++) {
      ctrls[i].text = raw[i]?.toString() ?? '';
    }
  }

  // ── HELPER STYLES & BORDERS ──
  static const _borderColor = Colors.black87;
  static const _borderWidth = 1.0;
  static const _borderSide =
      BorderSide(color: _borderColor, width: _borderWidth);

  Widget _cellInput(
    TextEditingController controller, {
    int minLines = 1,
    int? maxLines,
    String? hintText,
    TextAlign textAlign = TextAlign.start,
  }) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines ?? (minLines > 1 ? null : 1),
      textAlign: textAlign,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.blue.shade900,
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey.shade400,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Text(
            '-० चौकशी अहवाल ०-',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'स्थानिक गुन्हे शाखा,उस्मानाबाद',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow({
    required String srNo,
    required String label,
    required Widget child,
    double minHeight = 56,
    bool isLast = false,
  }) {
    final marathi = FormTypography.marathiLabelStyle();

    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: _borderSide),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sr No
            Container(
              width: 44,
              decoration: const BoxDecoration(
                border: Border(right: _borderSide),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                srNo,
                style: marathi.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            // Label
            Container(
              width: 220,
              decoration: const BoxDecoration(
                border: Border(right: _borderSide),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: marathi.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
            ),
            // Value
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                alignment: Alignment.centerLeft,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final marathi = FormTypography.marathiLabelStyle();

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        // ══════════════════════════════════════════════════════════
        // ── PAGE 1 (Image 1: Rows 1–10) ──
        // ══════════════════════════════════════════════════════════
        FormPaperPage(
          minHeight: 1180,
          children: [
            const SizedBox(height: 10),
            _buildHeader(),
            const SizedBox(height: 16),

            // Outer Table Page 1
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: _borderColor, width: _borderWidth),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── ROWS 1 TO 6 (WITH PHOTO BOX ON RIGHT) ──
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left 2 Columns (Sr No + Label + Input for Rows 1–6)
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildSubRow(
                                srNo: '१',
                                label: 'पोलीस ठाणे',
                                child: _cellInput(_psCtrl),
                              ),
                              _buildSubRow(
                                srNo: '२',
                                label: 'गुरनं / कलम',
                                minHeight: 60,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text('गुरनं - ',
                                            style: marathi.copyWith(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600)),
                                        SizedBox(
                                          width: 80,
                                          child: _cellInput(_gurNoCtrl),
                                        ),
                                        Text('/',
                                            style: marathi.copyWith(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold)),
                                        SizedBox(
                                          width: 60,
                                          child: _cellInput(_gurYearCtrl),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text('कलम - ',
                                            style: marathi.copyWith(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600)),
                                        Expanded(
                                          child: _cellInput(_kalamCtrl),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              _buildSubRow(
                                srNo: '३',
                                label: 'तपासी अधिका-याचे\nनांव व हुद्दा',
                                minHeight: 52,
                                child: _cellInput(_ioCtrl, minLines: 2),
                              ),
                              _buildSubRow(
                                srNo: '४',
                                label: 'गुन्हेगाराचे नांव व\nटोपन नांव',
                                minHeight: 52,
                                child: _cellInput(_accusedCtrl, minLines: 2),
                              ),
                              _buildSubRow(
                                srNo: '५',
                                label: 'अटक तारीख व वेळ',
                                child: _cellInput(_arrestDtCtrl),
                              ),
                              _buildSubRow(
                                srNo: '६',
                                label: 'जन्म तारीख,\nजन्माठिकाण,वय',
                                minHeight: 52,
                                hasBottomBorder: false,
                                child:
                                    _cellInput(_dobPlaceAgeCtrl, minLines: 2),
                              ),
                            ],
                          ),
                        ),

                        // Right Box: आरोपींचा फोटो (Spanning Rows 1–6)
                        Expanded(
                          flex: 3,
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(left: _borderSide),
                            ),
                            padding: const EdgeInsets.only(top: 8),
                            alignment: Alignment.topCenter,
                            child: Text(
                              'आरोपींचा फोटो',
                              style: marathi.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── ROW 7: चेहरे पट्टी माहीती (INNER GRID) ──
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(top: _borderSide, bottom: _borderSide),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                width: 44,
                                decoration: const BoxDecoration(
                                  border: Border(right: _borderSide),
                                ),
                                alignment: Alignment.center,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  '७',
                                  style: marathi.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'चेहरे पट्टी माहीती',
                                    style: marathi.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(top: _borderSide),
                          ),
                          child: Column(
                            children: [
                              _buildCheharePattiRow([
                                ('उंची', _physicalTableCtrls['उंची']!),
                                ('बांधा', _physicalTableCtrls['बांधा']!),
                                ('केस', _physicalTableCtrls['केस']!),
                                ('भुवया', _physicalTableCtrls['भुवया']!),
                              ]),
                              _buildCheharePattiRow([
                                ('कपाळ', _physicalTableCtrls['कपाळ']!),
                                ('डोळे', _physicalTableCtrls['डोळे']!),
                                ('दृष्टी', _physicalTableCtrls['दृष्टी']!),
                                ('नाक', _physicalTableCtrls['नाक']!),
                              ]),
                              _buildCheharePattiRow([
                                ('ओंट', _physicalTableCtrls['ओंट']!),
                                ('छाती', _physicalTableCtrls['छाती']!),
                                ('बोटे', _physicalTableCtrls['बोटे']!),
                                ('हनुवटी', _physicalTableCtrls['हनुवटी']!),
                              ]),
                              _buildCheharePattiRow([
                                ('कान', _physicalTableCtrls['कान']!),
                                ('चेहरा', _physicalTableCtrls['चेहरा']!),
                                ('वर्ण', _physicalTableCtrls['वर्ण']!),
                                ('दाढी', _physicalTableCtrls['दाढी']!),
                              ]),
                              _buildCheharePattiRow([
                                ('मिशा', _physicalTableCtrls['मिशा']!),
                                ('भाषा', _physicalTableCtrls['भाषा']!),
                                ('गाल', _physicalTableCtrls['गाल']!),
                                ('पोशाख', _physicalTableCtrls['पोशाख']!),
                              ]),
                              _buildCheharePattiRow([
                                ('व्यसन', _physicalTableCtrls['व्यसन']!),
                                ('', null),
                                ('', null),
                                ('', null),
                              ], isLast: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── ROW 8 ──
                  _buildTableRow(
                    srNo: '८',
                    label: 'ओळखोच्या खुणा ( तीळ,\nमार,जखम,गोंदन,अपंगत्व )',
                    minHeight: 64,
                    child: _cellInput(_idMarksCtrl, minLines: 2),
                  ),

                  // ── ROW 9 ──
                  _buildTableRow(
                    srNo: '९',
                    label:
                        'सध्याचा मुळ पत्ता घर\nक्र,इमारतीचे नांव,परीसराचे\nनांव,रस्ता,शहर राज्य ,मोबाईल\nनंबर',
                    minHeight: 80,
                    child: _cellInput(_addressCtrl, minLines: 3),
                  ),

                  // ── ROW 10 ──
                  Container(
                    constraints: const BoxConstraints(minHeight: 52),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 44,
                            decoration: const BoxDecoration(
                              border: Border(right: _borderSide),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '१०',
                              style: marathi.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            width: 220,
                            decoration: const BoxDecoration(
                              border: Border(right: _borderSide),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'धर्म/जात',
                              style: marathi.copyWith(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                children: [
                                  Text('धर्म - ',
                                      style: marathi.copyWith(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600)),
                                  Expanded(child: _cellInput(_dharmaCtrl)),
                                  const SizedBox(width: 16),
                                  Text('जात - ',
                                      style: marathi.copyWith(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600)),
                                  Expanded(child: _cellInput(_jatiCtrl)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 56),

        // ══════════════════════════════════════════════════════════
        // ── PAGE 2 (Image 2: Rows 11–15) ──
        // ══════════════════════════════════════════════════════════
        FormPaperPage(
          minHeight: 1180,
          children: [
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: _borderColor, width: _borderWidth),
              ),
              child: Column(
                children: [
                  _buildTableRow(
                    srNo: '११',
                    label: 'व्यवसाय/काम यापुर्वीचा\nव्यवसाय',
                    minHeight: 180,
                    child: _cellInput(_page2Rows[0], minLines: 6),
                  ),
                  _buildTableRow(
                    srNo: '१२',
                    label:
                        'वडीलाचे /आईचे नांव,वय,\nपत्ता,व्यवसाय,फोन व इतर\nआवश्यक माहिती',
                    minHeight: 180,
                    child: _cellInput(_page2Rows[1], minLines: 6),
                  ),
                  _buildTableRow(
                    srNo: '१३',
                    label:
                        'मुले/मुलीचे नांव,वय,पत्ता,\nव्यवसाय,फोन व इतर\nआवश्यक माहीती',
                    minHeight: 180,
                    child: _cellInput(_page2Rows[2], minLines: 6),
                  ),
                  _buildTableRow(
                    srNo: '१४',
                    label:
                        'भावाचे/बहीणींचे नांव ,वय,\nपत्ता,व्यवसाय,फोन व इतर\nआवश्यक माहीती',
                    minHeight: 180,
                    child: _cellInput(_page2Rows[3], minLines: 6),
                  ),
                  _buildTableRow(
                    srNo: '१५',
                    label:
                        'बहीण/ भाऊजींचे नांव ,वय,\nपत्ता,व्यवसाय,फोन व इतर\nआवश्यक माहीती',
                    minHeight: 180,
                    isLast: true,
                    child: _cellInput(_page2Rows[4], minLines: 6),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 56),

        // ══════════════════════════════════════════════════════════
        // ── PAGE 3 (Image 3: Rows 16–21) ──
        // ══════════════════════════════════════════════════════════
        FormPaperPage(
          minHeight: 1180,
          children: [
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: _borderColor, width: _borderWidth),
              ),
              child: Column(
                children: [
                  _buildTableRow(
                    srNo: '१६',
                    label:
                        'सासु/सासऱ्याचे नांव,वय,पत्ता,\nव्यवसाय,फोन व इतर\nआवश्यक माहीती',
                    minHeight: 155,
                    child: _cellInput(_page3Rows[0], minLines: 5),
                  ),
                  _buildTableRow(
                    srNo: '१७',
                    label:
                        'मेव्हणा/मेव्हणींची नावे वय,\nपत्ता, व्यवसाय,फोन व इतर\nआवश्यक माहीती',
                    minHeight: 155,
                    child: _cellInput(_page3Rows[1], minLines: 5),
                  ),
                  _buildTableRow(
                    srNo: '१८',
                    label:
                        'मामा/मामीचे नांव ,वय,\nपत्ता,व्यवसाय,फोन व इतर\nआवश्यक माहीती',
                    minHeight: 155,
                    child: _cellInput(_page3Rows[2], minLines: 5),
                  ),
                  _buildTableRow(
                    srNo: '१९',
                    label:
                        'काका/ मावशींचे नांव ,वय,\nपत्ता,व्यवसाय,फोन व इतर\nआवश्यक माहीती',
                    minHeight: 155,
                    child: _cellInput(_page3Rows[3], minLines: 5),
                  ),
                  _buildTableRow(
                    srNo: '२०',
                    label:
                        'चुलता/चुलतीचे नांव ,वय,\nपत्ता,व्यवसाय,फोन व इतर\nआवश्यक माहीती',
                    minHeight: 155,
                    child: _cellInput(_page3Rows[4], minLines: 5),
                  ),
                  _buildTableRow(
                    srNo: '२१',
                    label:
                        'आत्याचे / मामाचे नांव ,वय,\nपत्ता,व्यवसाय,फोन व इतर\nआवश्यक माहीती',
                    minHeight: 155,
                    isLast: true,
                    child: _cellInput(_page3Rows[5], minLines: 5),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 56),

        // ══════════════════════════════════════════════════════════
        // ── PAGE 4 (Image 4: Rows 22–30) ──
        // ══════════════════════════════════════════════════════════
        FormPaperPage(
          minHeight: 1180,
          children: [
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: _borderColor, width: _borderWidth),
              ),
              child: Column(
                children: [
                  _buildTableRow(
                    srNo: '२२',
                    label:
                        'शिक्षण/शाळा/ कॉलेज\n(पत्ता) तसेच संगणकाचे ज्ञान\nआहे काय?',
                    minHeight: 85,
                    child: _cellInput(_page4Rows[0], minLines: 2),
                  ),
                  _buildTableRow(
                    srNo: '२३',
                    label: 'नोकरीस असल्यास पुर्वीचे\nकार्यालयाचा पत्ता',
                    minHeight: 65,
                    child: _cellInput(_page4Rows[1], minLines: 2),
                  ),
                  _buildTableRow(
                    srNo: '२४',
                    label: 'आधारकार्ड क्रमांक',
                    minHeight: 46,
                    child: _cellInput(_page4Rows[2]),
                  ),
                  _buildTableRow(
                    srNo: '२५',
                    label: 'पॅनकार्ड क्रमांक',
                    minHeight: 46,
                    child: _cellInput(_page4Rows[3]),
                  ),
                  _buildTableRow(
                    srNo: '२६',
                    label: 'वाहन परवाना',
                    minHeight: 46,
                    child: _cellInput(_page4Rows[4]),
                  ),
                  _buildTableRow(
                    srNo: '२७',
                    label: 'रेशन कार्ड',
                    minHeight: 46,
                    child: _cellInput(_page4Rows[5]),
                  ),
                  _buildTableRow(
                    srNo: '२८',
                    label: 'मालमत्ता (अंदाजे)',
                    minHeight: 65,
                    child: _cellInput(_page4Rows[6], minLines: 2),
                  ),
                  _buildTableRow(
                    srNo: '२९',
                    label:
                        'यापुर्वी झालेली शिक्षा (पोलीस\nठाणे,पत्ता गु.नो.क्र,कलम\nसाथीदार,फरार\nआरोपी )',
                    minHeight: 110,
                    child: _cellInput(_page4Rows[7], minLines: 4),
                  ),
                  _buildTableRow(
                    srNo: '३०',
                    label:
                        'या गुन्ह्यातील आरोपींचे\nसाथीदारांची नावे पुर्ण पत्ता\nमोबाईल नंबर सह',
                    minHeight: 150,
                    isLast: true,
                    child: _cellInput(_page4Rows[8], minLines: 5),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 56),

        // ══════════════════════════════════════════════════════════
        // ── PAGE 5 (Image 5: Rows 31–36) ──
        // ══════════════════════════════════════════════════════════
        FormPaperPage(
          minHeight: 1180,
          children: [
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: _borderColor, width: _borderWidth),
              ),
              child: Column(
                children: [
                  _buildTableRow(
                    srNo: '३१',
                    label: 'बसण्या - उठण्याच्या जागा',
                    minHeight: 140,
                    child: _cellInput(_page5Rows[0], minLines: 4),
                  ),
                  _buildTableRow(
                    srNo: '३२',
                    label:
                        'नमुद आरोपीस गुन्ह्याचे ठिकाणची (स्थळ,ईमारत)\nयाबाबत माहीती मिळालेली उगमस्थाने (रेखी ) (गुन्हा\nकरण्याचे स्थळा बाबत माहीती कोठून व कशी मिळवली)',
                    minHeight: 150,
                    child: _cellInput(_page5Rows[1], minLines: 4),
                  ),
                  _buildTableRow(
                    srNo: '३३',
                    label: 'गुन्हा करतेवेळी आरोपी यांनी वापरलेली वाहने',
                    minHeight: 140,
                    child: _cellInput(_page5Rows[2], minLines: 4),
                  ),
                  _buildTableRow(
                    srNo: '३४',
                    label:
                        'गुन्हा करते वेळी वापरलेली हत्यारे\n(काठी,कटवणी,पक्कड, पाने,कटर,गॅस कटर, व इतर )',
                    minHeight: 150,
                    child: _cellInput(_page5Rows[3], minLines: 4),
                  ),
                  _buildTableRow(
                    srNo: '३५',
                    label: 'गुन्हा करते वेळी येण्याची दिशा व रस्ते',
                    minHeight: 150,
                    child: _cellInput(_page5Rows[4], minLines: 4),
                  ),
                  _buildTableRow(
                    srNo: '३६',
                    label: 'गुन्हा करुन जातेवेळीची दिशा व रस्ते',
                    minHeight: 150,
                    isLast: true,
                    child: _cellInput(_page5Rows[5], minLines: 4),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 56),

        // ══════════════════════════════════════════════════════════
        // ── PAGE 6 (New Image 1: Rows 37–40 + IO Signature) ──
        // ══════════════════════════════════════════════════════════
        FormPaperPage(
          minHeight: 1180,
          children: [
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: _borderColor, width: _borderWidth),
              ),
              child: Column(
                children: [
                  _buildTableRow(
                    srNo: '३७',
                    label: 'गुन्हा करण्याची पध्दत',
                    minHeight: 170,
                    child: _cellInput(_page6Rows[0], minLines: 5),
                  ),
                  _buildTableRow(
                    srNo: '३८',
                    label:
                        'गुन्ह्यातील चोरलेल्या मुद्देमालाबाबत आरोपीने\nसांगितलेली माहीती\n(साथीदार यांना वाटप,विक्री तसेच ईतर प्रकारे विल्हेवाट\nसंपूर्ण हकिकत)',
                    minHeight: 220,
                    child: _cellInput(_page6Rows[1], minLines: 7),
                  ),
                  _buildTableRow(
                    srNo: '३९',
                    label: 'आरोपीस ओळखणारे पोलीस अधिकारी/अंमलदार,पोलीस\nपाटील',
                    minHeight: 120,
                    child: _cellInput(_page6Rows[2], minLines: 3),
                  ),
                  _buildTableRow(
                    srNo: '४०',
                    label: 'Advisorries',
                    minHeight: 150,
                    isLast: true,
                    child: _cellInput(_page6Rows[3], minLines: 4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // ── SIGNATURE BLOCK (RIGHT) ──
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'तपासणी अधिकाऱ्याची सही',
                        style: marathi.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text('नांव :- ',
                            style: marathi.copyWith(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        Expanded(child: _cellInput(_ioSigNameCtrl)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('पदनाम :- ',
                            style: marathi.copyWith(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        Expanded(child: _cellInput(_ioSigRankCtrl)),
                        const SizedBox(width: 8),
                        Text('कोड नंबर :- ',
                            style: marathi.copyWith(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        SizedBox(width: 70, child: _cellInput(_ioSigCodeCtrl)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('नेमणुक :- ',
                            style: marathi.copyWith(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        Expanded(child: _cellInput(_ioSigPostingCtrl)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 56),

        // ══════════════════════════════════════════════════════════
        // ── PAGE 7 (New Image 2: मुद्दा क्रमांक ३७ ची अधिक माहिती) ──
        // ══════════════════════════════════════════════════════════
        FormPaperPage(
          minHeight: 1180,
          children: [
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: _borderColor, width: _borderWidth),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Bar
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(bottom: _borderSide),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Column(
                      children: [
                        Text(
                          'मुद्दा क्रमांक ३७ ची अधिक माहिती',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'गुन्हा करण्याची पध्दत,रेखी,कार्यप्रणाली, मालाची विल्हेवाट व इतर उपयुक्त माहिती:-',
                          style: marathi.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Large Multiline Content Area
                  Container(
                    constraints: const BoxConstraints(minHeight: 900),
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _additional37Ctrl,
                      minLines: 30,
                      maxLines: null,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        height: 1.8,
                        color: Colors.blue.shade900,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubRow({
    required String srNo,
    required String label,
    required Widget child,
    double minHeight = 44,
    bool hasBottomBorder = true,
  }) {
    final marathi = FormTypography.marathiLabelStyle();

    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        border: hasBottomBorder ? const Border(bottom: _borderSide) : null,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 44,
              decoration: const BoxDecoration(
                border: Border(right: _borderSide),
              ),
              alignment: Alignment.center,
              child: Text(
                srNo,
                style: marathi.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              width: 155,
              decoration: const BoxDecoration(
                border: Border(right: _borderSide),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: marathi.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                alignment: Alignment.centerLeft,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheharePattiRow(
    List<(String, TextEditingController?)> cols, {
    bool isLast = false,
  }) {
    final marathi = FormTypography.marathiLabelStyle();

    return Container(
      height: 32,
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: _borderSide),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cols.length; i++) ...[
            Container(
              width: 65,
              decoration: BoxDecoration(
                border: Border(
                  left: i > 0 ? _borderSide : BorderSide.none,
                  right: _borderSide,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                cols[i].$1,
                style: marathi.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Expanded(
              child: cols[i].$2 != null
                  ? _cellInput(cols[i].$2!)
                  : const SizedBox(),
            ),
          ],
        ],
      ),
    );
  }
}
