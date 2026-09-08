import 'package:flutter/material.dart';

import 'bilingual_field.dart';
import 'form_paper_page.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';

/// Item controllers for Muddemal Pavti table rows.
class MuddemalItemControllers {
  final TextEditingController description = TextEditingController();
  final TextEditingController estimatedValue = TextEditingController();
  final TextEditingController malNumber = TextEditingController();
  final TextEditingController seizedFrom = TextEditingController();

  void dispose() {
    description.dispose();
    estimatedValue.dispose();
    malNumber.dispose();
    seizedFrom.dispose();
  }
}

/// Muddemal Pavti (—:: मुद्देमाल पावती ::—).
class MuddemalPavtiFormView extends StatefulWidget {
  final bool readOnly;
  final Map<String, dynamic>? existingRecord;
  final String? formSection;
  final String? pageRange;

  const MuddemalPavtiFormView({
    super.key,
    this.readOnly = false,
    this.existingRecord,
    this.formSection,
    this.pageRange,
  });

  @override
  State<MuddemalPavtiFormView> createState() => MuddemalPavtiFormViewState();
}

class MuddemalPavtiFormViewState extends State<MuddemalPavtiFormView> {
  // Header details (१ to ५)
  final _policeStationCtrl = TextEditingController();
  final _districtCtrl = TextEditingController(text: 'यवतमाळ');
  final _crNoYearCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();
  final _investigatingOfficerCtrl = TextEditingController();
  final _ioPoliceStationCtrl = TextEditingController();
  final _ioDistrictCtrl = TextEditingController(text: 'यवतमाळ');
  final _accusedNameCtrl = TextEditingController();
  final _seizureDateCtrl = TextEditingController();
  final _malNumberCtrl = TextEditingController();

  // Table items
  final List<MuddemalItemControllers> _items = [];

  // Footer / Signatures
  final _headMoharirSignCtrl = TextEditingController();
  final _ioSignCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default with 4 rows
    for (int i = 0; i < 4; i++) {
      _items.add(MuddemalItemControllers());
    }

    if (widget.existingRecord != null) {
      hydrateFrom(widget.existingRecord!);
    }
  }

  @override
  void dispose() {
    _policeStationCtrl.dispose();
    _districtCtrl.dispose();
    _crNoYearCtrl.dispose();
    _sectionCtrl.dispose();
    _investigatingOfficerCtrl.dispose();
    _ioPoliceStationCtrl.dispose();
    _ioDistrictCtrl.dispose();
    _accusedNameCtrl.dispose();
    _seizureDateCtrl.dispose();
    _malNumberCtrl.dispose();

    for (final item in _items) {
      item.dispose();
    }

    _headMoharirSignCtrl.dispose();
    _ioSignCtrl.dispose();

    super.dispose();
  }

  void _addItemRow() {
    setState(() {
      _items.add(MuddemalItemControllers());
    });
  }

  void _removeItemRow(int index) {
    if (_items.length <= 1) return;
    setState(() {
      final removed = _items.removeAt(index);
      removed.dispose();
    });
  }

  void hydrateFrom(Map<String, dynamic> data) {
    setState(() {
      _policeStationCtrl.text = data['policeStation']?.toString() ?? '';
      _districtCtrl.text = data['district']?.toString() ?? 'यवतमाळ';
      _crNoYearCtrl.text =
          data['crNoYear']?.toString() ?? data['crNo']?.toString() ?? '';
      _sectionCtrl.text = data['section']?.toString() ?? '';
      _investigatingOfficerCtrl.text =
          data['investigatingOfficer']?.toString() ??
              data['ioName']?.toString() ??
              '';
      _ioPoliceStationCtrl.text = data['ioPoliceStation']?.toString() ??
          data['policeStation']?.toString() ??
          '';
      _ioDistrictCtrl.text = data['ioDistrict']?.toString() ?? 'यवतमाळ';
      _accusedNameCtrl.text = data['accusedName']?.toString() ?? '';
      _seizureDateCtrl.text = data['seizureDate']?.toString() ??
          data['seizedDate']?.toString() ??
          data['date']?.toString() ??
          '';
      _malNumberCtrl.text =
          data['malNumber']?.toString() ?? data['receiptNo']?.toString() ?? '';

      final dynamic rawItems = data['muddemalItems'];
      if (rawItems is List && rawItems.isNotEmpty) {
        while (_items.length < rawItems.length) {
          _items.add(MuddemalItemControllers());
        }
        while (_items.length > rawItems.length && _items.length > 1) {
          final item = _items.removeLast();
          item.dispose();
        }
        for (int i = 0; i < rawItems.length; i++) {
          final itemMap = rawItems[i] as Map<String, dynamic>;
          _items[i].description.text = itemMap['description']?.toString() ?? '';
          _items[i].estimatedValue.text =
              itemMap['estimatedValue']?.toString() ?? '';
          _items[i].malNumber.text = itemMap['malNumber']?.toString() ?? '';
          _items[i].seizedFrom.text = itemMap['seizedFrom']?.toString() ?? '';
        }
      } else if (data['propertyDescription'] != null ||
          data['propertyValue'] != null) {
        if (_items.isNotEmpty) {
          _items[0].description.text =
              data['propertyDescription']?.toString() ?? '';
          _items[0].estimatedValue.text =
              data['propertyValue']?.toString() ?? '';
          _items[0].malNumber.text = data['malNumber']?.toString() ?? '';
          _items[0].seizedFrom.text = data['seizedFrom']?.toString() ?? '';
        }
      }

      _headMoharirSignCtrl.text = data['headMoharirSign']?.toString() ??
          data['receiverName']?.toString() ??
          '';
      _ioSignCtrl.text =
          data['ioSign']?.toString() ?? data['ioName']?.toString() ?? '';
    });
  }

  Map<String, dynamic> collectData() {
    final itemsData = _items
        .map((item) => {
              'description': item.description.text.trim(),
              'estimatedValue': item.estimatedValue.text.trim(),
              'malNumber': item.malNumber.text.trim(),
              'seizedFrom': item.seizedFrom.text.trim(),
            })
        .toList();

    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'policeStation': _policeStationCtrl.text.trim(),
      'district': _districtCtrl.text.trim(),
      'crNoYear': _crNoYearCtrl.text.trim(),
      'crNo': _crNoYearCtrl.text.trim(),
      'section': _sectionCtrl.text.trim(),
      'investigatingOfficer': _investigatingOfficerCtrl.text.trim(),
      'ioName': _investigatingOfficerCtrl.text.trim(),
      'ioPoliceStation': _ioPoliceStationCtrl.text.trim(),
      'ioDistrict': _ioDistrictCtrl.text.trim(),
      'accusedName': _accusedNameCtrl.text.trim(),
      'seizureDate': _seizureDateCtrl.text.trim(),
      'seizedDate': _seizureDateCtrl.text.trim(),
      'malNumber': _malNumberCtrl.text.trim(),
      'muddemalItems': itemsData,
      'propertyDescription':
          _items.isNotEmpty ? _items[0].description.text.trim() : '',
      'propertyValue':
          _items.isNotEmpty ? _items[0].estimatedValue.text.trim() : '',
      'seizedFrom': _items.isNotEmpty ? _items[0].seizedFrom.text.trim() : '',
      'headMoharirSign': _headMoharirSignCtrl.text.trim(),
      'ioSign': _ioSignCtrl.text.trim(),
    };
  }

  Widget _inlineInput(
    TextEditingController ctrl,
    TextStyle serifStyle, {
    String? hintText,
    double minWidth = 100,
  }) {
    return Container(
      constraints: BoxConstraints(minWidth: minWidth),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: BilingualSimpleUnderlineInput(
        controller: ctrl,
        hintText: hintText,
        serifStyle: serifStyle.copyWith(fontSize: 13),
      ),
    );
  }

  Widget _tableCellInput(
    TextEditingController ctrl,
    TextStyle serifStyle, {
    String? hintText,
    int minLines = 1,
    int maxLines = 4,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: TextField(
        controller: ctrl,
        readOnly: widget.readOnly,
        minLines: minLines,
        maxLines: maxLines,
        style: serifStyle.copyWith(fontSize: 12),
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 11),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
        ),
      ),
    );
  }

  Widget _tableHeader(String text, TextStyle marathiStyle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        text,
        style: marathiStyle.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 12.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final serif = FormTypography.serifStyle();
    final marathi = FormTypography.marathiLabelStyle();

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        FormPaperPage(
          formLabel: widget.pageRange ?? 'Muddemal Pavti',
          children: [
            // Title
            Center(
              child: Column(
                children: [
                  Text(
                    '—:: मुद्देमाल पावती ::—',
                    style: marathi.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Container(
                    width: 180,
                    height: 1,
                    margin: const EdgeInsets.only(top: 2),
                    color: Colors.black87,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Item 1: Police Station & District
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('१) पोलीस स्टेशन',
                    style: marathi.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text(':—', style: marathi),
                const SizedBox(width: 6),
                Expanded(child: _inlineInput(_policeStationCtrl, serif)),
                const SizedBox(width: 12),
                Text('जिल्हा',
                    style: marathi.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                SizedBox(width: 120, child: _inlineInput(_districtCtrl, serif)),
              ],
            ),
            const SizedBox(height: 14),

            // Item 2: Crime No & Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('२) अप क्रमांक :—',
                    style: marathi.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                SizedBox(
                  width: 140,
                  child: _inlineInput(_crNoYearCtrl, serif,
                      hintText: '......../२०......'),
                ),
                const SizedBox(width: 16),
                Text('कलम',
                    style: marathi.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(child: _inlineInput(_sectionCtrl, serif)),
              ],
            ),
            const SizedBox(height: 14),

            // Item 3: Investigating Officer, Police Station & District
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('३) अन्वेषन अधिकारी:—',
                    style: marathi.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Expanded(
                    flex: 3,
                    child: _inlineInput(_investigatingOfficerCtrl, serif)),
                const SizedBox(width: 10),
                Text('पोलीस स्टेशन',
                    style: marathi.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Expanded(
                    flex: 2, child: _inlineInput(_ioPoliceStationCtrl, serif)),
                const SizedBox(width: 10),
                Text('जिल्हा',
                    style: marathi.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                SizedBox(
                    width: 110, child: _inlineInput(_ioDistrictCtrl, serif)),
              ],
            ),
            const SizedBox(height: 14),

            // Item 4: Accused Name
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('४) आरोपी नांव :—',
                    style: marathi.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Expanded(child: _inlineInput(_accusedNameCtrl, serif)),
              ],
            ),
            const SizedBox(height: 14),

            // Item 5: Seizure Date & Mal Number
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('५) जप्त माल दिनांक :—',
                    style: marathi.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                SizedBox(
                  width: 150,
                  child: _inlineInput(_seizureDateCtrl, serif,
                      hintText: '....../....../२०....'),
                ),
                const SizedBox(width: 24),
                Text('माल नंबर :—',
                    style: marathi.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                SizedBox(
                  width: 150,
                  child: _inlineInput(_malNumberCtrl, serif,
                      hintText: '......../२०......'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Seized Goods Table
            Table(
              border: TableBorder.all(color: Colors.black87),
              columnWidths: const {
                0: FlexColumnWidth(3.4),
                1: FlexColumnWidth(1.4),
                2: FlexColumnWidth(1.4),
                3: FlexColumnWidth(2.6),
              },
              children: [
                // Header Row
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: [
                    _tableHeader('जप्त मालाचे विवरण', marathi),
                    _tableHeader('मुल्य अंदाजे', marathi),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 6),
                      child: Column(
                        children: [
                          Text('माल नंबर',
                              style: marathi.copyWith(
                                  fontWeight: FontWeight.bold, fontSize: 12.5),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 2),
                          Text('....../२०....',
                              style: serif.copyWith(
                                  fontSize: 10, color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                    _tableHeader('कोणाकडुन जप्त केले', marathi),
                  ],
                ),

                // Data Rows
                for (int i = 0; i < _items.length; i++)
                  TableRow(
                    children: [
                      _tableCellInput(_items[i].description, serif,
                          minLines: 2, maxLines: 5),
                      _tableCellInput(_items[i].estimatedValue, serif,
                          minLines: 2, maxLines: 5),
                      _tableCellInput(_items[i].malNumber, serif,
                          minLines: 2, maxLines: 5),
                      _tableCellInput(_items[i].seizedFrom, serif,
                          minLines: 2, maxLines: 5),
                    ],
                  ),
              ],
            ),

            if (!widget.readOnly) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _addItemRow,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text('आणखी ओळ जोडा (Add Row)',
                        style: marathi.copyWith(fontSize: 11)),
                  ),
                  if (_items.length > 1)
                    TextButton.icon(
                      onPressed: () => _removeItemRow(_items.length - 1),
                      icon: const Icon(Icons.remove, size: 16),
                      label: Text('शेवटची ओळ काढा',
                          style: marathi.copyWith(
                              fontSize: 11, color: Colors.red.shade700)),
                    ),
                ],
              ),
            ],

            const SizedBox(height: 48),

            // Signatures
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Head Moharir
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      child: _inlineInput(_headMoharirSignCtrl, serif,
                          hintText: 'नाव / सही'),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'हेडमोहरर सही',
                      style: marathi.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                // Investigating Officer
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      child: _inlineInput(_ioSignCtrl, serif,
                          hintText: 'नाव / सही'),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'तपास अधिकारी',
                      style: marathi.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ],
    );
  }
}
