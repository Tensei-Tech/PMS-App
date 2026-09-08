import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bilingual_field.dart';
import 'form_paper_page.dart';
import 'form_table_helpers.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';

/// -:: मुद्देमाल पावती ::- (Muddemal Pavti)
class MuddemalPavtiFormView extends StatefulWidget {
  final bool readOnly;
  final String? formSection;
  final String? pageRange;

  const MuddemalPavtiFormView({
    super.key,
    this.readOnly = false,
    this.formSection,
    this.pageRange,
  });

  @override
  State<MuddemalPavtiFormView> createState() => MuddemalPavtiFormViewState();
}

class MuddemalPropertyRow {
  final TextEditingController description;
  final TextEditingController estimatedValue;
  final TextEditingController propertyNo;
  final TextEditingController seizedFrom;

  MuddemalPropertyRow({
    String description = '',
    String estimatedValue = '',
    String propertyNo = '',
    String seizedFrom = '',
  })  : description = TextEditingController(text: description),
        estimatedValue = TextEditingController(text: estimatedValue),
        propertyNo = TextEditingController(text: propertyNo),
        seizedFrom = TextEditingController(text: seizedFrom);

  void dispose() {
    description.dispose();
    estimatedValue.dispose();
    propertyNo.dispose();
    seizedFrom.dispose();
  }

  Map<String, String> toMap() {
    return {
      'description': description.text,
      'estimatedValue': estimatedValue.text,
      'propertyNo': propertyNo.text,
      'seizedFrom': seizedFrom.text,
    };
  }
}

class MuddemalPavtiFormViewState extends State<MuddemalPavtiFormView> {
  final _psCtrl = TextEditingController();
  final _distCtrl = TextEditingController(text: 'यवतमाळ');

  final _crimeNoCtrl = TextEditingController();
  final _actSecCtrl = TextEditingController();

  final _ioNameCtrl = TextEditingController();
  final _ioPsCtrl = TextEditingController();
  final _ioDistCtrl = TextEditingController(text: 'यवतमाळ');

  final _accusedNameCtrl = TextEditingController();

  final _seizureDateCtrl = TextEditingController();
  final _propertyNoCtrl = TextEditingController();

  List<MuddemalPropertyRow>? _rows;
  List<MuddemalPropertyRow> get _safeRows {
    if (_rows == null || _rows!.isEmpty) {
      _rows = [MuddemalPropertyRow(propertyNo: '......./२०....')];
    }
    return _rows!;
  }

  final _headMohararSigCtrl = TextEditingController();
  final _investigatingOfficerSigCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rows ??= [MuddemalPropertyRow(propertyNo: '......./२०....')];
  }

  @override
  void dispose() {
    _psCtrl.dispose();
    _distCtrl.dispose();
    _crimeNoCtrl.dispose();
    _actSecCtrl.dispose();
    _ioNameCtrl.dispose();
    _ioPsCtrl.dispose();
    _ioDistCtrl.dispose();
    _accusedNameCtrl.dispose();
    _seizureDateCtrl.dispose();
    _propertyNoCtrl.dispose();
    if (_rows != null) {
      for (final row in _rows!) {
        row.dispose();
      }
    }
    _headMohararSigCtrl.dispose();
    _investigatingOfficerSigCtrl.dispose();
    super.dispose();
  }

  void _addRow() {
    if (widget.readOnly) return;
    setState(() {
      _safeRows.add(MuddemalPropertyRow(propertyNo: '......./२०....'));
    });
  }

  void _removeRow(int index) {
    if (widget.readOnly || _safeRows.length <= 1) return;
    setState(() {
      final r = _safeRows.removeAt(index);
      r.dispose();
    });
  }

  Map<String, dynamic> collectData() {
    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'policeStation': _psCtrl.text,
      'district': _distCtrl.text,
      'crimeNo': _crimeNoCtrl.text,
      'actSec': _actSecCtrl.text,
      'ioName': _ioNameCtrl.text,
      'ioPs': _ioPsCtrl.text,
      'ioDist': _ioDistCtrl.text,
      'accusedName': _accusedNameCtrl.text,
      'seizureDate': _seizureDateCtrl.text,
      'propertyNo': _propertyNoCtrl.text,
      'items': _safeRows.map((r) => r.toMap()).toList(),
      'headMohararSig': _headMohararSigCtrl.text,
      'investigatingOfficerSig': _investigatingOfficerSigCtrl.text,
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    _psCtrl.text = data['policeStation']?.toString() ?? '';
    _distCtrl.text = data['district']?.toString() ?? 'यवतमाळ';
    _crimeNoCtrl.text = data['crimeNo']?.toString() ?? '';
    _actSecCtrl.text = data['actSec']?.toString() ?? '';
    _ioNameCtrl.text = data['ioName']?.toString() ?? '';
    _ioPsCtrl.text = data['ioPs']?.toString() ?? '';
    _ioDistCtrl.text = data['ioDist']?.toString() ?? 'यवतमाळ';
    _accusedNameCtrl.text = data['accusedName']?.toString() ?? '';
    _seizureDateCtrl.text = data['seizureDate']?.toString() ?? '';
    _propertyNoCtrl.text = data['propertyNo']?.toString() ?? '';

    if (data['items'] is List) {
      for (final r in _safeRows) {
        r.dispose();
      }
      _safeRows.clear();
      final list = data['items'] as List;
      for (final item in list) {
        if (item is Map) {
          _safeRows.add(
            MuddemalPropertyRow(
              description: item['description']?.toString() ?? '',
              estimatedValue: item['estimatedValue']?.toString() ?? '',
              propertyNo: item['propertyNo']?.toString() ?? '',
              seizedFrom: item['seizedFrom']?.toString() ?? '',
            ),
          );
        }
      }
      if (_safeRows.isEmpty) {
        _safeRows.add(MuddemalPropertyRow(propertyNo: '......./२०....'));
      }
    }

    _headMohararSigCtrl.text = data['headMohararSig']?.toString() ?? '';
    _investigatingOfficerSigCtrl.text =
        data['investigatingOfficerSig']?.toString() ?? '';

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final serif = FormTypography.serifStyle();
    final marathi = FormTypography.marathiLabelStyle();

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        FormPaperPage(
          formLabel: widget.pageRange,
          children: [
            // ── TITLE ──
            Center(
              child: Text(
                '-:: मुद्देमाल पावती ::-',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── ROW 1: पोलीस स्टेशन ──
            Row(
              children: [
                Text(
                  '१) पोलीस स्टेशन   :-  ',
                  style: marathi.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _psCtrl,
                    serifStyle: serif,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'जिल्हा यवतमाळ',
                  style: marathi.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── ROW 2: अप क्रमांक व कलम ──
            Row(
              children: [
                Text(
                  '२) अप क्रमांक :- ',
                  style: marathi.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: BilingualSimpleUnderlineInput(
                    controller: _crimeNoCtrl,
                    serifStyle: serif,
                    hintText: '........../२०......',
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'कलम ',
                  style: marathi.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _actSecCtrl,
                    serifStyle: serif,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── ROW 3: अन्वेषन अधिकारी ──
            Row(
              children: [
                Text(
                  '३) अन्वेषन अधिकारी:- ',
                  style: marathi.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _ioNameCtrl,
                    serifStyle: serif,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'पोलीस स्टेशन ',
                  style: marathi.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: BilingualSimpleUnderlineInput(
                    controller: _ioPsCtrl,
                    serifStyle: serif,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'जिल्हा यवतमाळ',
                  style: marathi.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── ROW 4: आरोपी नांव ──
            Row(
              children: [
                Text(
                  '४) आरोपी नांव :- ',
                  style: marathi.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _accusedNameCtrl,
                    serifStyle: serif,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── ROW 5: जप्त माल दिनांक व माल नंबर ──
            Row(
              children: [
                Text(
                  '५) जप्त माल दिनांक :- ',
                  style: marathi.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: BilingualSimpleUnderlineInput(
                    controller: _seizureDateCtrl,
                    serifStyle: serif,
                    hintText: '......./ ........./२०.....',
                  ),
                ),
                const SizedBox(width: 24),
                Text(
                  'माल नंबर :- ',
                  style: marathi.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: BilingualSimpleUnderlineInput(
                    controller: _propertyNoCtrl,
                    serifStyle: serif,
                    hintText: '........../२०......',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── MAIN TABLE ──
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1.2),
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black, width: 1.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              border: Border(
                                right:
                                    BorderSide(color: Colors.black, width: 1),
                              ),
                            ),
                            child: Text(
                              'जप्त मालाचे विवरण',
                              style: marathi.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              border: Border(
                                right:
                                    BorderSide(color: Colors.black, width: 1),
                              ),
                            ),
                            child: Text(
                              'मुल्य अंदाजे',
                              style: marathi.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              border: Border(
                                right:
                                    BorderSide(color: Colors.black, width: 1),
                              ),
                            ),
                            child: Text(
                              'माल नंबर',
                              style: marathi.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                            alignment: Alignment.center,
                            child: Text(
                              'कोणाकडुन जप्त केले',
                              style: marathi.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Table Rows
                  for (int i = 0; i < _safeRows.length; i++)
                    IntrinsicHeight(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 180),
                        decoration: BoxDecoration(
                          border: i < _safeRows.length - 1
                              ? const Border(
                                  bottom:
                                      BorderSide(color: Colors.black, width: 1),
                                )
                              : null,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                          Expanded(
                            flex: 4,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                border: Border(
                                  right:
                                      BorderSide(color: Colors.black, width: 1),
                                ),
                              ),
                              child: TextField(
                                controller: _safeRows[i].description,
                                readOnly: widget.readOnly,
                                minLines: 6,
                                maxLines: null,
                                style: serif.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'मालाचे संपूर्ण वर्णन...',
                                  hintStyle: serif.copyWith(
                                      color: Colors.grey.shade400,
                                      fontSize: 11),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                border: Border(
                                  right:
                                      BorderSide(color: Colors.black, width: 1),
                                ),
                              ),
                              child: TextField(
                                controller: _safeRows[i].estimatedValue,
                                readOnly: widget.readOnly,
                                minLines: 2,
                                maxLines: null,
                                style: serif.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'अंदाजे किंमत...',
                                  hintStyle: serif.copyWith(
                                      color: Colors.grey.shade400,
                                      fontSize: 11),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                border: Border(
                                  right:
                                      BorderSide(color: Colors.black, width: 1),
                                ),
                              ),
                              child: TextField(
                                controller: _safeRows[i].propertyNo,
                                readOnly: widget.readOnly,
                                style: serif.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '......./२०....',
                                  hintStyle: serif.copyWith(
                                      color: Colors.grey.shade400,
                                      fontSize: 11),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: TextField(
                                controller: _safeRows[i].seizedFrom,
                                readOnly: widget.readOnly,
                                minLines: 4,
                                maxLines: null,
                                style: serif.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'व्यक्तीचे नाव व पत्ता...',
                                  hintStyle: serif.copyWith(
                                      color: Colors.grey.shade400,
                                      fontSize: 11),
                                ),
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

            if (!widget.readOnly) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _addRow,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('माल नोंद जोडा'),
                  ),
                  if (_safeRows.length > 1) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _removeRow(_safeRows.length - 1),
                      icon: const Icon(Icons.remove, size: 16),
                      label: const Text('शेवटची नोंद काढा'),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 36),

            // ── SIGNATURES ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      Text(
                        'हेडमोहरर सही',
                        style: marathi.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      BilingualSimpleUnderlineInput(
                        controller: _headMohararSigCtrl,
                        serifStyle: serif,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      Text(
                        'तपास अधिकारी',
                        style: marathi.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      BilingualSimpleUnderlineInput(
                        controller: _investigatingOfficerSigCtrl,
                        serifStyle: serif,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            FormMrwFooter(serifStyle: serif),
          ],
        ),
      ],
    );
  }
}
