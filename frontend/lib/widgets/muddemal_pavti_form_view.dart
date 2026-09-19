import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'form_paper_page.dart';
import 'form_table_helpers.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';

/// -:: मुद्देमाल पावती ::- (Muddemal Pavti)
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
      'malNumber': propertyNo.text,
      'seizedFrom': seizedFrom.text,
    };
  }
}

class MuddemalPavtiFormViewState extends State<MuddemalPavtiFormView> {
  final _psCtrl = TextEditingController();
  final _distCtrl = TextEditingController();

  final _crimeNoCtrl = TextEditingController();
  final _actSecCtrl = TextEditingController();

  final _ioNameCtrl = TextEditingController();
  final _ioPsCtrl = TextEditingController();
  final _ioDistCtrl = TextEditingController();

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
    if (widget.existingRecord != null) {
      hydrateFrom(widget.existingRecord!);
    }
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

  Future<void> _pickDateForController(TextEditingController controller) async {
    if (widget.readOnly) return;
    DateTime initial = DateTime.now();
    final raw = controller.text.trim();
    if (raw.isNotEmpty) {
      final parts = raw.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          initial = DateTime(y, m, d);
        }
      }
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A365D),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final day = picked.day.toString().padLeft(2, '0');
      final month = picked.month.toString().padLeft(2, '0');
      final year = picked.year.toString();
      setState(() {
        controller.text = '$day/$month/$year';
      });
    }
  }

  Widget _datePickerField({
    required TextEditingController controller,
    double width = 140,
    String hintText = 'DD/MM/YYYY',
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => _pickDateForController(controller),
        style: GoogleFonts.notoSansDevanagari(fontSize: 13, color: Colors.black87),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          hintText: hintText,
          hintStyle: GoogleFonts.notoSansDevanagari(fontSize: 12, color: Colors.grey.shade400),
          suffixIcon: InkWell(
            onTap: () => _pickDateForController(controller),
            child: const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 2),
              child: Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF1A365D)),
            ),
          ),
          suffixIconConstraints: const BoxConstraints(minWidth: 20, minHeight: 20),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black54, width: 0.8),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF1A365D), width: 1.5),
          ),
        ),
      ),
    );
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
    final itemsList = _safeRows.map((r) => r.toMap()).toList();
    final firstRow = _safeRows.isNotEmpty ? _safeRows.first : null;
    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'policeStation': _psCtrl.text.trim(),
      'district': _distCtrl.text.trim(),
      'crimeNo': _crimeNoCtrl.text.trim(),
      'crNoYear': _crimeNoCtrl.text.trim(),
      'crNo': _crimeNoCtrl.text.trim(),
      'actSec': _actSecCtrl.text.trim(),
      'section': _actSecCtrl.text.trim(),
      'ioName': _ioNameCtrl.text.trim(),
      'investigatingOfficer': _ioNameCtrl.text.trim(),
      'ioPs': _ioPsCtrl.text.trim(),
      'ioPoliceStation': _ioPsCtrl.text.trim(),
      'ioDist': _ioDistCtrl.text.trim(),
      'ioDistrict': _ioDistCtrl.text.trim(),
      'accusedName': _accusedNameCtrl.text.trim(),
      'seizureDate': _seizureDateCtrl.text.trim(),
      'seizedDate': _seizureDateCtrl.text.trim(),
      'propertyNo': _propertyNoCtrl.text.trim(),
      'malNumber': _propertyNoCtrl.text.trim(),
      'items': itemsList,
      'muddemalItems': itemsList,
      'propertyDescription': firstRow?.description.text.trim() ?? '',
      'propertyValue': firstRow?.estimatedValue.text.trim() ?? '',
      'seizedFrom': firstRow?.seizedFrom.text.trim() ?? '',
      'headMohararSig': _headMohararSigCtrl.text.trim(),
      'headMoharirSign': _headMohararSigCtrl.text.trim(),
      'investigatingOfficerSig': _investigatingOfficerSigCtrl.text.trim(),
      'ioSign': _investigatingOfficerSigCtrl.text.trim(),
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    _psCtrl.text = data['policeStation']?.toString() ?? '';
    _distCtrl.text = data['district']?.toString() ?? '';
    _crimeNoCtrl.text =
        (data['crimeNo'] ?? data['crNoYear'] ?? data['crNo'])?.toString() ?? '';
    _actSecCtrl.text = (data['actSec'] ?? data['section'])?.toString() ?? '';
    _ioNameCtrl.text =
        (data['ioName'] ?? data['investigatingOfficer'])?.toString() ?? '';
    _ioPsCtrl.text =
        (data['ioPs'] ?? data['ioPoliceStation'] ?? data['policeStation'])
                ?.toString() ??
            '';
    _ioDistCtrl.text = (data['ioDist'] ?? data['ioDistrict'])?.toString() ?? '';
    _accusedNameCtrl.text = data['accusedName']?.toString() ?? '';
    _seizureDateCtrl.text =
        (data['seizureDate'] ?? data['seizedDate'] ?? data['date'])
                ?.toString() ??
            '';
    _propertyNoCtrl.text =
        (data['propertyNo'] ?? data['malNumber'] ?? data['receiptNo'])
                ?.toString() ??
            '';

    final dynamic rawList = data['items'] ?? data['muddemalItems'];
    if (rawList is List && rawList.isNotEmpty) {
      if (_rows != null) {
        for (final r in _rows!) {
          r.dispose();
        }
      }
      _rows = [];
      for (final item in rawList) {
        if (item is Map) {
          _rows!.add(
            MuddemalPropertyRow(
              description: item['description']?.toString() ?? '',
              estimatedValue: item['estimatedValue']?.toString() ?? '',
              propertyNo:
                  (item['propertyNo'] ?? item['malNumber'])?.toString() ?? '',
              seizedFrom: item['seizedFrom']?.toString() ?? '',
            ),
          );
        }
      }
      if (_rows!.isEmpty) {
        _rows!.add(MuddemalPropertyRow(propertyNo: '......./२०....'));
      }
    } else if (data['propertyDescription'] != null ||
        data['propertyValue'] != null) {
      if (_rows != null) {
        for (final r in _rows!) {
          r.dispose();
        }
      }
      _rows = [
        MuddemalPropertyRow(
          description: data['propertyDescription']?.toString() ?? '',
          estimatedValue: data['propertyValue']?.toString() ?? '',
          propertyNo:
              (data['propertyNo'] ?? data['malNumber'])?.toString() ?? '',
          seizedFrom: data['seizedFrom']?.toString() ?? '',
        ),
      ];
    }

    _headMohararSigCtrl.text = (data['headMohararSig'] ??
                data['headMoharirSign'] ??
                data['receiverName'])
            ?.toString() ??
        '';
    _investigatingOfficerSigCtrl.text =
        (data['investigatingOfficerSig'] ?? data['ioSign'] ?? data['ioName'])
                ?.toString() ??
            '';

    if (mounted) setState(() {});
  }

  Widget _wrappingUnderlineInput({
    required TextEditingController controller,
    required TextStyle style,
    double minWidth = 100,
    double? maxWidth,
    String? hintText,
    TextInputType? keyboardType,
  }) {
    final effectiveMin = minWidth;
    final effectiveMax = maxWidth ?? 800.0;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final text = controller.text.isEmpty ? (hintText ?? '') : controller.text;
        final tp = TextPainter(
          text: TextSpan(
            text: text,
            style: style.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();
        final measured = tp.width + 20.0;
        final calcWidth = measured < effectiveMin
            ? effectiveMin
            : (measured > effectiveMax ? effectiveMax : measured);

        return SizedBox(
          width: calcWidth,
          child: TextFormField(
            controller: controller,
            readOnly: widget.readOnly,
            maxLines: 1,
            keyboardType: keyboardType ?? TextInputType.text,
            style: style.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              color: const Color(0xFF0D47A1),
              height: 1.35,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: false,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.only(bottom: 4, top: 2),
              hintText: hintText,
              hintStyle: style.copyWith(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF333333), width: 1.0),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF555555), width: 1.0),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF1976D2), width: 1.5),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _policeStationField({
    required TextEditingController controller,
    required TextStyle style,
    double minWidth = 140,
    double? maxWidth,
    String? hintText,
  }) {
    final baseMin = minWidth;
    final baseMax = maxWidth ?? 600.0;
    const double baseFontSize = 13.5;
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasFiniteWidth = constraints.maxWidth.isFinite;
        final availableWidth = hasFiniteWidth ? constraints.maxWidth : baseMax;

        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final text = controller.text.isEmpty ? (hintText ?? '') : controller.text;
            final tp = TextPainter(
              text: TextSpan(
                text: text,
                style: style.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: baseFontSize,
                ),
              ),
              textDirection: TextDirection.ltr,
              maxLines: 1,
            )..layout();

            double effectiveFontSize = baseFontSize;
            final double textW = tp.width + 12.0;

            if (hasFiniteWidth && textW > availableWidth && availableWidth > 30) {
              final scale = ((availableWidth - 8.0) / tp.width).clamp(0.60, 1.0);
              effectiveFontSize = (baseFontSize * scale).clamp(8.5, baseFontSize);
            }

            final double computedWidth = hasFiniteWidth
                ? availableWidth
                : (textW < baseMin ? baseMin : (textW > baseMax ? baseMax : textW));

            return SizedBox(
              width: computedWidth,
              child: TextFormField(
                controller: controller,
                readOnly: widget.readOnly,
                maxLines: 1,
                scrollPhysics: const ClampingScrollPhysics(),
                style: style.copyWith(
                  fontSize: effectiveFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  hintText: hintText,
                  hintStyle: style.copyWith(
                    color: Colors.grey.shade400,
                    fontSize: effectiveFontSize,
                  ),
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF333333), width: 1.0),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF555555), width: 1.0),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1976D2), width: 2.0),
                  ),
                ),
              ),
            );
          },
        );
      },
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
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 10,
              children: [
                Text(
                  '१) पोलीस स्टेशन   :-  ',
                  style: marathi.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                _policeStationField(
                  controller: _psCtrl,
                  style: serif,
                  minWidth: 150,
                  maxWidth: 350,
                ),
                const SizedBox(width: 8),
                Text(
                  'जिल्हा :- ',
                  style: marathi.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                _wrappingUnderlineInput(
                  controller: _distCtrl,
                  style: serif,
                  minWidth: 120,
                  maxWidth: 300,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── ROW 2: अप क्रमांक व कलम ──
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 10,
              children: [
                Text(
                  '२) अप क्रमांक :- ',
                  style: marathi.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                _wrappingUnderlineInput(
                  controller: _crimeNoCtrl,
                  style: serif,
                  minWidth: 120,
                  maxWidth: 260,
                  hintText: '........../२०......',
                ),
                const SizedBox(width: 12),
                Text(
                  'कलम ',
                  style: marathi.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                _wrappingUnderlineInput(
                  controller: _actSecCtrl,
                  style: serif,
                  minWidth: 200,
                  maxWidth: 600,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── ROW 3: अन्वेषन अधिकारी ──
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 10,
              children: [
                Text(
                  '३) अन्वेषन अधिकारी:- ',
                  style: marathi.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                _wrappingUnderlineInput(
                  controller: _ioNameCtrl,
                  style: serif,
                  minWidth: 160,
                  maxWidth: 350,
                ),
                const SizedBox(width: 8),
                Text(
                  'पोलीस स्टेशन ',
                  style: marathi.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                _policeStationField(
                  controller: _ioPsCtrl,
                  style: serif,
                  minWidth: 130,
                  maxWidth: 300,
                ),
                const SizedBox(width: 8),
                Text(
                  'जिल्हा :- ',
                  style: marathi.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                _wrappingUnderlineInput(
                  controller: _ioDistCtrl,
                  style: serif,
                  minWidth: 120,
                  maxWidth: 260,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── ROW 4: आरोपी नांव ──
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 10,
              children: [
                Text(
                  '४) आरोपी नांव :- ',
                  style: marathi.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                _wrappingUnderlineInput(
                  controller: _accusedNameCtrl,
                  style: serif,
                  minWidth: 260,
                  maxWidth: 700,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── ROW 5: जप्त माल दिनांक व माल नंबर ──
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 10,
              children: [
                Text(
                  '५) जप्त माल दिनांक :- ',
                  style: marathi.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                _datePickerField(
                  controller: _seizureDateCtrl,
                  width: 140,
                ),
                const SizedBox(width: 24),
                Text(
                  'माल नंबर :- ',
                  style: marathi.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                _wrappingUnderlineInput(
                  controller: _propertyNoCtrl,
                  style: serif,
                  minWidth: 120,
                  maxWidth: 260,
                  hintText: '........../२०......',
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
                                    right: BorderSide(
                                        color: Colors.black, width: 1),
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
                                    right: BorderSide(
                                        color: Colors.black, width: 1),
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
                                    right: BorderSide(
                                        color: Colors.black, width: 1),
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
                      _wrappingUnderlineInput(
                        controller: _headMohararSigCtrl,
                        style: serif,
                        minWidth: 160,
                        maxWidth: 200,
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
                      _wrappingUnderlineInput(
                        controller: _investigatingOfficerSigCtrl,
                        style: serif,
                        minWidth: 160,
                        maxWidth: 200,
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
