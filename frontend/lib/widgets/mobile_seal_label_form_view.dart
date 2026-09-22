import 'package:flutter/material.dart';

import 'form_paper_page.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';

/// Mobile Seal Label (मोबाईल सिल लेबल नमुना / Exhibit च्या पाकीट वरील लेबल चा नमुना).
class MobileSealLabelFormView extends StatefulWidget {
  final bool readOnly;
  final Map<String, dynamic>? existingRecord;
  final String? formSection;
  final String? pageRange;

  const MobileSealLabelFormView({
    super.key,
    this.readOnly = false,
    this.existingRecord,
    this.formSection,
    this.pageRange,
  });

  @override
  State<MobileSealLabelFormView> createState() =>
      MobileSealLabelFormViewState();
}

class MobileSealLabelFormViewState extends State<MobileSealLabelFormView> {
  // General details
  final _psDistrictCtrl = TextEditingController();
  final _psCtrl = TextEditingController();
  final _distCtrl = TextEditingController();
  final _crimeNoSectionCtrl = TextEditingController();
  final _seizingOfficerCtrl = TextEditingController();
  final _seizedFromCtrl = TextEditingController();
  final _accusedNameCtrl = TextEditingController();
  final _seizurePlaceDateTimeCtrl = TextEditingController();
  final _seizurePlaceCtrl = TextEditingController();
  final _seizureDateCtrl = TextEditingController();
  final _seizureTimeCtrl = TextEditingController();

  // Mobile Specifications
  final _mobileCompanyCtrl = TextEditingController();
  final _imei1Ctrl = TextEditingController();
  final _imei2Ctrl = TextEditingController();
  final _mobileSerialNoCtrl = TextEditingController();
  final _passwordPatternPinCtrl = TextEditingController();
  final _mobileConditionCtrl = TextEditingController();
  final _switchOffStatusCtrl = TextEditingController();
  final _simCardPresentCtrl = TextEditingController();
  final _simCompanyCtrl = TextEditingController();
  final _simCallingNoCtrl = TextEditingController();
  final _simCardSerialNoCtrl = TextEditingController();
  final _memoryCardPresentCtrl = TextEditingController();
  final _memoryCardCompanyCtrl = TextEditingController();
  final _memoryCardCapacityCtrl = TextEditingController();
  final _memoryCardSerialNoCtrl = TextEditingController();

  // Exhibit & Signatures
  final _exhibitNoLetterCtrl = TextEditingController();
  final _seizedPersonSignCtrl = TextEditingController();
  final _panch1SignCtrl = TextEditingController();
  final _panch2SignCtrl = TextEditingController();
  final _ioNameSignStampCtrl = TextEditingController();
  final _sealSampleCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _seizurePlaceCtrl.addListener(_updateCombinedSeizurePlaceDateTime);
    _psCtrl.addListener(_updateCombinedPsDistrict);
    _distCtrl.addListener(_updateCombinedPsDistrict);
    if (widget.existingRecord != null) {
      hydrateFrom(widget.existingRecord!);
    }
  }

  void _updateCombinedPsDistrict() {
    final ps = _psCtrl.text.trim();
    final dist = _distCtrl.text.trim();
    if (ps.isNotEmpty && dist.isNotEmpty) {
      _psDistrictCtrl.text = '$ps, $dist';
    } else if (ps.isNotEmpty) {
      _psDistrictCtrl.text = ps;
    } else if (dist.isNotEmpty) {
      _psDistrictCtrl.text = dist;
    }
  }

  void _updateCombinedSeizurePlaceDateTime() {
    final place = _seizurePlaceCtrl.text.trim();
    final date = _seizureDateCtrl.text.trim();
    final time = _seizureTimeCtrl.text.trim();
    final parts = <String>[];
    if (place.isNotEmpty) parts.add(place);
    if (date.isNotEmpty) parts.add('दि. $date');
    if (time.isNotEmpty) parts.add('वेळ $time');
    _seizurePlaceDateTimeCtrl.text = parts.join(', ');
  }

  Future<void> _pickDateForController(
    TextEditingController controller, {
    VoidCallback? onChanged,
  }) async {
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
      onChanged?.call();
    }
  }

  Future<void> _pickTimeForController(
    TextEditingController controller, {
    VoidCallback? onChanged,
  }) async {
    if (widget.readOnly) return;
    TimeOfDay initial = TimeOfDay.now();
    final raw = controller.text.trim();
    if (raw.isNotEmpty) {
      final parts = raw.split(':');
      if (parts.length >= 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) {
          initial = TimeOfDay(hour: h, minute: m);
        }
      }
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF1A365D),
                onPrimary: Colors.white,
                onSurface: Colors.black87,
              ),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      setState(() {
        controller.text = '$h:$m';
      });
      onChanged?.call();
    }
  }

  Widget _datePickerField({
    required TextEditingController controller,
    double width = 130,
    String hintText = 'DD/MM/YYYY',
    VoidCallback? onChanged,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => _pickDateForController(controller, onChanged: onChanged),
        style: FormTypography.marathiLabelStyle(
            fontSize: 12, fontWeight: FontWeight.normal, color: Colors.black87),
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          hintText: hintText,
          hintStyle: FormTypography.marathiLabelStyle(
              fontSize: 11,
              fontWeight: FontWeight.normal,
              color: Colors.grey.shade400),
          suffixIcon: InkWell(
            onTap: () =>
                _pickDateForController(controller, onChanged: onChanged),
            child: const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 2),
              child: Icon(Icons.calendar_today_outlined,
                  size: 15, color: Color(0xFF1A365D)),
            ),
          ),
          suffixIconConstraints:
              const BoxConstraints(minWidth: 20, minHeight: 20),
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

  Widget _timePickerField({
    required TextEditingController controller,
    double width = 95,
    String hintText = 'HH:MM',
    VoidCallback? onChanged,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => _pickTimeForController(controller, onChanged: onChanged),
        style: FormTypography.marathiLabelStyle(
            fontSize: 12, fontWeight: FontWeight.normal, color: Colors.black87),
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
          hintText: hintText,
          hintStyle: FormTypography.marathiLabelStyle(
              fontSize: 11,
              fontWeight: FontWeight.normal,
              color: Colors.grey.shade400),
          suffixIcon: InkWell(
            onTap: () =>
                _pickTimeForController(controller, onChanged: onChanged),
            child: const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 2),
              child:
                  Icon(Icons.access_time, size: 15, color: Color(0xFF1A365D)),
            ),
          ),
          suffixIconConstraints:
              const BoxConstraints(minWidth: 20, minHeight: 20),
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

  @override
  void dispose() {
    _seizurePlaceCtrl.removeListener(_updateCombinedSeizurePlaceDateTime);
    _psCtrl.removeListener(_updateCombinedPsDistrict);
    _distCtrl.removeListener(_updateCombinedPsDistrict);
    _seizurePlaceCtrl.dispose();
    _seizureDateCtrl.dispose();
    _seizureTimeCtrl.dispose();
    _psDistrictCtrl.dispose();
    _psCtrl.dispose();
    _distCtrl.dispose();
    _crimeNoSectionCtrl.dispose();
    _seizingOfficerCtrl.dispose();
    _seizedFromCtrl.dispose();
    _accusedNameCtrl.dispose();
    _seizurePlaceDateTimeCtrl.dispose();

    _mobileCompanyCtrl.dispose();
    _imei1Ctrl.dispose();
    _imei2Ctrl.dispose();
    _mobileSerialNoCtrl.dispose();
    _passwordPatternPinCtrl.dispose();
    _mobileConditionCtrl.dispose();
    _switchOffStatusCtrl.dispose();
    _simCardPresentCtrl.dispose();
    _simCompanyCtrl.dispose();
    _simCallingNoCtrl.dispose();
    _simCardSerialNoCtrl.dispose();
    _memoryCardPresentCtrl.dispose();
    _memoryCardCompanyCtrl.dispose();
    _memoryCardCapacityCtrl.dispose();
    _memoryCardSerialNoCtrl.dispose();

    _exhibitNoLetterCtrl.dispose();
    _seizedPersonSignCtrl.dispose();
    _panch1SignCtrl.dispose();
    _panch2SignCtrl.dispose();
    _ioNameSignStampCtrl.dispose();
    _sealSampleCtrl.dispose();

    super.dispose();
  }

  void hydrateFrom(Map<String, dynamic> data) {
    setState(() {
      final psVal = data['policeStation']?.toString() ?? '';
      final distVal = data['district']?.toString() ?? '';
      final psDistVal = data['psDistrict']?.toString() ?? '';
      if (psVal.isNotEmpty || distVal.isNotEmpty) {
        _psCtrl.text = psVal;
        _distCtrl.text = distVal;
        _psDistrictCtrl.text =
            [psVal, distVal].where((s) => s.isNotEmpty).join(', ');
      } else if (psDistVal.isNotEmpty) {
        _psDistrictCtrl.text = psDistVal;
        if (psDistVal.contains(',')) {
          final parts = psDistVal.split(',');
          _psCtrl.text = parts[0].trim();
          _distCtrl.text = parts.sublist(1).join(',').trim();
        } else {
          _psCtrl.text = psDistVal;
          _distCtrl.text = '';
        }
      } else {
        _psCtrl.text = '';
        _distCtrl.text = '';
        _psDistrictCtrl.text = '';
      }

      _crimeNoSectionCtrl.text = data['crimeNoSection']?.toString() ??
          (data['crNo'] != null
              ? '${data['crNo']} ${data['section'] ?? ''}'.trim()
              : '');
      _seizingOfficerCtrl.text = data['seizingOfficer']?.toString() ??
          data['ioName']?.toString() ??
          '';
      _seizedFromCtrl.text = data['seizedFrom']?.toString() ?? '';
      _accusedNameCtrl.text = data['accusedName']?.toString() ?? '';
      _seizurePlaceCtrl.text = data['seizurePlace']?.toString() ?? '';
      _seizureDateCtrl.text = data['seizureDate']?.toString() ?? '';
      _seizureTimeCtrl.text = data['seizureTime']?.toString() ?? '';
      _seizurePlaceDateTimeCtrl.text =
          data['seizurePlaceDateTime']?.toString() ??
              data['seizedDate']?.toString() ??
              '';

      _mobileCompanyCtrl.text = data['mobileCompany']?.toString() ??
          data['mobileMake']?.toString() ??
          '';
      _imei1Ctrl.text = data['imei1']?.toString() ?? '';
      _imei2Ctrl.text = data['imei2']?.toString() ?? '';
      _mobileSerialNoCtrl.text = data['mobileSerialNo']?.toString() ??
          data['mobileModel']?.toString() ??
          '';
      _passwordPatternPinCtrl.text =
          data['passwordPatternPin']?.toString() ?? '';
      _mobileConditionCtrl.text = data['mobileCondition']?.toString() ?? '';
      _switchOffStatusCtrl.text = data['switchOffStatus']?.toString() ?? '';
      _simCardPresentCtrl.text = data['simCardPresent']?.toString() ?? '';
      _simCompanyCtrl.text = data['simCompany']?.toString() ?? '';
      _simCallingNoCtrl.text =
          data['simCallingNo']?.toString() ?? data['simNo']?.toString() ?? '';
      _simCardSerialNoCtrl.text = data['simCardSerialNo']?.toString() ?? '';
      _memoryCardPresentCtrl.text = data['memoryCardPresent']?.toString() ?? '';
      _memoryCardCompanyCtrl.text = data['memoryCardCompany']?.toString() ?? '';
      _memoryCardCapacityCtrl.text =
          data['memoryCardCapacity']?.toString() ?? '';
      _memoryCardSerialNoCtrl.text =
          data['memoryCardSerialNo']?.toString() ?? '';

      _exhibitNoLetterCtrl.text = data['exhibitNoLetter']?.toString() ??
          data['labelNo']?.toString() ??
          '';
      _seizedPersonSignCtrl.text = data['seizedPersonSign']?.toString() ?? '';
      _panch1SignCtrl.text = data['panch1Sign']?.toString() ?? '';
      _panch2SignCtrl.text = data['panch2Sign']?.toString() ?? '';
      _ioNameSignStampCtrl.text = data['ioNameSignStamp']?.toString() ??
          data['ioName']?.toString() ??
          '';
      _sealSampleCtrl.text =
          data['sealSample']?.toString() ?? data['remarks']?.toString() ?? '';
    });
  }

  Map<String, dynamic> collectData() {
    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'psDistrict': _psDistrictCtrl.text.trim().isNotEmpty
          ? _psDistrictCtrl.text.trim()
          : [_psCtrl.text.trim(), _distCtrl.text.trim()]
              .where((s) => s.isNotEmpty)
              .join(', '),
      'policeStation': _psCtrl.text.trim().isNotEmpty
          ? _psCtrl.text.trim()
          : _psDistrictCtrl.text.trim(),
      'district': _distCtrl.text.trim(),
      'crimeNoSection': _crimeNoSectionCtrl.text.trim(),
      'seizingOfficer': _seizingOfficerCtrl.text.trim(),
      'seizedFrom': _seizedFromCtrl.text.trim(),
      'accusedName': _accusedNameCtrl.text.trim(),
      'seizurePlace': _seizurePlaceCtrl.text.trim(),
      'seizureDate': _seizureDateCtrl.text.trim(),
      'seizureTime': _seizureTimeCtrl.text.trim(),
      'seizurePlaceDateTime': _seizurePlaceDateTimeCtrl.text.trim(),
      'mobileCompany': _mobileCompanyCtrl.text.trim(),
      'mobileMake': _mobileCompanyCtrl.text.trim(),
      'imei1': _imei1Ctrl.text.trim(),
      'imei2': _imei2Ctrl.text.trim(),
      'mobileSerialNo': _mobileSerialNoCtrl.text.trim(),
      'passwordPatternPin': _passwordPatternPinCtrl.text.trim(),
      'mobileCondition': _mobileConditionCtrl.text.trim(),
      'switchOffStatus': _switchOffStatusCtrl.text.trim(),
      'simCardPresent': _simCardPresentCtrl.text.trim(),
      'simCompany': _simCompanyCtrl.text.trim(),
      'simCallingNo': _simCallingNoCtrl.text.trim(),
      'simCardSerialNo': _simCardSerialNoCtrl.text.trim(),
      'memoryCardPresent': _memoryCardPresentCtrl.text.trim(),
      'memoryCardCompany': _memoryCardCompanyCtrl.text.trim(),
      'memoryCardCapacity': _memoryCardCapacityCtrl.text.trim(),
      'memoryCardSerialNo': _memoryCardSerialNoCtrl.text.trim(),
      'exhibitNoLetter': _exhibitNoLetterCtrl.text.trim(),
      'seizedPersonSign': _seizedPersonSignCtrl.text.trim(),
      'panch1Sign': _panch1SignCtrl.text.trim(),
      'panch2Sign': _panch2SignCtrl.text.trim(),
      'ioNameSignStamp': _ioNameSignStampCtrl.text.trim(),
      'ioName': _ioNameSignStampCtrl.text.trim(),
      'sealSample': _sealSampleCtrl.text.trim(),
    };
  }

  Widget _tableCellInput(
    TextEditingController ctrl,
    TextStyle serifStyle, {
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: TextFormField(
        controller: ctrl,
        readOnly: widget.readOnly,
        minLines: 1,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        style: serifStyle.copyWith(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0D47A1),
          height: 1.35,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.only(bottom: 4, top: 2),
          hintText: hintText,
          hintStyle: serifStyle.copyWith(
            color: Colors.grey.shade400,
            fontSize: 11.5,
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
  }

  TableRow _buildFormRow(
    String label,
    TextEditingController ctrl,
    TextStyle marathiStyle,
    TextStyle serifStyle, {
    String? hintText,
  }) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(label, style: marathiStyle),
        ),
        _tableCellInput(ctrl, serifStyle, hintText: hintText),
      ],
    );
  }

  TableRow _buildSubRow(
    String label,
    TextEditingController ctrl,
    TextStyle marathiStyle,
    TextStyle serifStyle, {
    String? hintText,
  }) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(label, style: marathiStyle.copyWith(fontSize: 12)),
        ),
        _tableCellInput(ctrl, serifStyle, hintText: hintText),
      ],
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
          formLabel: widget.pageRange ?? 'Mobile Seal Label',
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Text(
                    'मोबाईल सिल लेबल नमुना',
                    style: marathi.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Exhibit च्या पाकीट वरील लेबल चा नमुना',
                    style: marathi.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'सुचना :— जप्ती नंतर हॅश व्हॅल्यु किंवा निरीक्षण पंचनामा झाला असेल तर मुद्देमालाच्या लेबल व पहिल्या जप्तीची तारीख त्यानंतर झालेली पंचनामा नंतर सिलबंद केल्याचा तारखा नमुद कराव्यात',
                    style: marathi.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Main Table
            Table(
              border: TableBorder.all(color: Colors.black87),
              columnWidths: const {
                0: FlexColumnWidth(1.8),
                1: FlexColumnWidth(3.2),
              },
              children: [
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Text('पोलीस स्टेशन व जिल्हा', style: marathi),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'पोस्टे : ',
                              style: marathi.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: _tableCellInput(
                              _psCtrl,
                              serif,
                              hintText: 'पोलीस स्टेशन...',
                            ),
                          ),
                          const SizedBox(width: 24),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'जिल्हा : ',
                              style: marathi.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 130,
                            child: _tableCellInput(
                              _distCtrl,
                              serif,
                              hintText: 'जिल्हा...',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                _buildFormRow(
                    'अपराध क्रमांक व कलम', _crimeNoSectionCtrl, marathi, serif),
                _buildFormRow('जप्त करणारे अधिकारी नांव हुद्दा पोस्टे',
                    _seizingOfficerCtrl, marathi, serif),
                _buildFormRow('कोणाकडुन जप्त केले त्याचे नांव पत्ता',
                    _seizedFromCtrl, marathi, serif),
                _buildFormRow('आरोपीचे नाव', _accusedNameCtrl, marathi, serif),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Text('जप्तीचे ठिकाण तारीख वेळ', style: marathi),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _seizurePlaceCtrl,
                            readOnly: widget.readOnly,
                            minLines: 1,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            style: serif.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                              color: const Color(0xFF0D47A1),
                              height: 1.35,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: false,
                              fillColor: Colors.transparent,
                              contentPadding:
                                  const EdgeInsets.only(bottom: 4, top: 2),
                              hintText: 'ठिकाण (Place of seizure)...',
                              hintStyle: serif.copyWith(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                              border: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color(0xFF333333), width: 1.0),
                              ),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color(0xFF555555), width: 1.0),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color(0xFF1976D2), width: 1.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _datePickerField(
                                controller: _seizureDateCtrl,
                                width: 130,
                                hintText: 'DD/MM/YYYY',
                                onChanged: _updateCombinedSeizurePlaceDateTime,
                              ),
                              _timePickerField(
                                controller: _seizureTimeCtrl,
                                width: 95,
                                hintText: 'HH:MM',
                                onChanged: _updateCombinedSeizurePlaceDateTime,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Mobile Specs with Left Stamp Column
                TableRow(
                  children: [
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 120),
                      child: Text(
                        'पोलीस स्टेशन शिक्का',
                        style: marathi.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Table(
                      border: TableBorder.all(color: Colors.black54),
                      columnWidths: const {
                        0: FlexColumnWidth(2.0),
                        1: FlexColumnWidth(2.0),
                      },
                      children: [
                        TableRow(
                          decoration:
                              BoxDecoration(color: Colors.grey.shade100),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text(
                                'जप्त मालाचे वर्णन जप्तीपत्रकानुसार मोबाईलच्या बाबतीत',
                                style: marathi.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(),
                          ],
                        ),
                        _buildSubRow(
                            'मो कंपनी', _mobileCompanyCtrl, marathi, serif),
                        _buildSubRow('IMEI 1', _imei1Ctrl, marathi, serif),
                        _buildSubRow('IMEI 2', _imei2Ctrl, marathi, serif),
                        _buildSubRow('मोबाईल सिरियल क्र.', _mobileSerialNoCtrl,
                            marathi, serif),
                        _buildSubRow('पासवर्ड/ पॅटर्न/ पिन',
                            _passwordPatternPinCtrl, marathi, serif,
                            hintText: 'असल्यास नमूद करणे'),
                        _buildSubRow('मोबाईल स्थिती', _mobileConditionCtrl,
                            marathi, serif,
                            hintText: 'चालु / बंद'),
                        _buildSubRow(
                            'स्विच ऑफ', _switchOffStatusCtrl, marathi, serif,
                            hintText: 'होय / नाही'),
                        _buildSubRow(
                            'सिम कार्ड आहे किं नाही असल्यास खालील माहिती',
                            _simCardPresentCtrl,
                            marathi,
                            serif,
                            hintText: 'होय / नाही'),
                        _buildSubRow(
                            'सिम कंपनी', _simCompanyCtrl, marathi, serif),
                        _buildSubRow('सिमचा कॉलींग क्रमांक', _simCallingNoCtrl,
                            marathi, serif),
                        _buildSubRow('सिमकार्डवर दिसणारा सीरीयल क्र',
                            _simCardSerialNoCtrl, marathi, serif),
                        _buildSubRow(
                            'मेमरी कार्ड आहे किं नाही असल्यास खालील माहिती',
                            _memoryCardPresentCtrl,
                            marathi,
                            serif,
                            hintText: 'होय / नाही'),
                        _buildSubRow('मेमरीकार्ड कंपनी नांव',
                            _memoryCardCompanyCtrl, marathi, serif),
                        _buildSubRow('मेमरी कार्ड ची क्षमता',
                            _memoryCardCapacityCtrl, marathi, serif),
                        _buildSubRow('मेमरी कार्डवर दिसणारा सिरीयल क्र',
                            _memoryCardSerialNoCtrl, marathi, serif),
                      ],
                    ),
                  ],
                ),

                // Exhibit Row
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: Text(
                        'एक्झिबीट क्र तपासी अधिकारी यांच्या पत्रानुसार',
                        style: marathi,
                      ),
                    ),
                    _tableCellInput(_exhibitNoLetterCtrl, serif,
                        hintText: 'उदा “Exhibit – A”'),
                  ],
                ),

                // Seized Person & Panch Signatures Row
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('ज्यांचेकडुन जप्त केले त्यांची सही',
                              style: marathi, textAlign: TextAlign.center),
                          const SizedBox(height: 36),
                          _tableCellInput(_seizedPersonSignCtrl, serif),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text('पंचाच्या सह्या',
                                style: marathi, textAlign: TextAlign.center),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text('१) ', style: marathi),
                              Expanded(
                                  child:
                                      _tableCellInput(_panch1SignCtrl, serif)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text('२) ', style: marathi),
                              Expanded(
                                  child:
                                      _tableCellInput(_panch2SignCtrl, serif)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // IO Signature & Seal Sample
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('तपासी अधिकारी यांचे नाव सही शिक्का',
                              style: marathi, textAlign: TextAlign.center),
                          const SizedBox(height: 36),
                          _tableCellInput(_ioNameSignStampCtrl, serif),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('सिल नमुना',
                              style: marathi, textAlign: TextAlign.center),
                          const SizedBox(height: 36),
                          _tableCellInput(_sealSampleCtrl, serif),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
