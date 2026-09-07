import 'package:flutter/material.dart';

import 'bilingual_field.dart';
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
  final _crimeNoSectionCtrl = TextEditingController();
  final _seizingOfficerCtrl = TextEditingController();
  final _seizedFromCtrl = TextEditingController();
  final _accusedNameCtrl = TextEditingController();
  final _seizurePlaceDateTimeCtrl = TextEditingController();

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
    if (widget.existingRecord != null) {
      hydrateFrom(widget.existingRecord!);
    }
  }

  @override
  void dispose() {
    _psDistrictCtrl.dispose();
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
      _psDistrictCtrl.text = data['psDistrict']?.toString() ??
          data['policeStation']?.toString() ??
          '';
      _crimeNoSectionCtrl.text = data['crimeNoSection']?.toString() ??
          (data['crNo'] != null
              ? '${data['crNo']} ${data['section'] ?? ''}'.trim()
              : '');
      _seizingOfficerCtrl.text = data['seizingOfficer']?.toString() ??
          data['ioName']?.toString() ??
          '';
      _seizedFromCtrl.text = data['seizedFrom']?.toString() ?? '';
      _accusedNameCtrl.text = data['accusedName']?.toString() ?? '';
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
      _simCallingNoCtrl.text = data['simCallingNo']?.toString() ??
          data['simNo']?.toString() ??
          '';
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
      _sealSampleCtrl.text = data['sealSample']?.toString() ??
          data['remarks']?.toString() ??
          '';
    });
  }

  Map<String, dynamic> collectData() {
    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'psDistrict': _psDistrictCtrl.text.trim(),
      'policeStation': _psDistrictCtrl.text.trim(),
      'crimeNoSection': _crimeNoSectionCtrl.text.trim(),
      'seizingOfficer': _seizingOfficerCtrl.text.trim(),
      'seizedFrom': _seizedFromCtrl.text.trim(),
      'accusedName': _accusedNameCtrl.text.trim(),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: BilingualSimpleUnderlineInput(
        controller: ctrl,
        hintText: hintText,
        serifStyle: serifStyle.copyWith(fontSize: 12),
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
                _buildFormRow('पोलीस स्टेशन जिल्हा', _psDistrictCtrl, marathi, serif),
                _buildFormRow('अपराध क्रमांक व कलम', _crimeNoSectionCtrl, marathi, serif),
                _buildFormRow('जप्त करणारे अधिकारी नांव हुद्दा पोस्टे', _seizingOfficerCtrl, marathi, serif),
                _buildFormRow('कोणाकडुन जप्त केले त्याचे नांव पत्ता', _seizedFromCtrl, marathi, serif),
                _buildFormRow('आरोपीचे नाव', _accusedNameCtrl, marathi, serif),
                _buildFormRow('जप्तीचे ठिकाण तारीख वेळ', _seizurePlaceDateTimeCtrl, marathi, serif),

                // Mobile Specs with Left Stamp Column
                TableRow(
                  children: [
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 120),
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
                          decoration: BoxDecoration(color: Colors.grey.shade100),
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
                        _buildSubRow('मो कंपनी', _mobileCompanyCtrl, marathi, serif),
                        _buildSubRow('IMEI 1', _imei1Ctrl, marathi, serif),
                        _buildSubRow('IMEI 2', _imei2Ctrl, marathi, serif),
                        _buildSubRow('मोबाईल सिरियल क्र.', _mobileSerialNoCtrl, marathi, serif),
                        _buildSubRow('पासवर्ड/ पॅटर्न/ पिन', _passwordPatternPinCtrl, marathi, serif, hintText: 'असल्यास नमूद करणे'),
                        _buildSubRow('मोबाईल स्थिती', _mobileConditionCtrl, marathi, serif, hintText: 'चालु / बंद'),
                        _buildSubRow('स्विच ऑफ', _switchOffStatusCtrl, marathi, serif, hintText: 'होय / नाही'),
                        _buildSubRow('सिम कार्ड आहे किं नाही असल्यास खालील माहिती', _simCardPresentCtrl, marathi, serif, hintText: 'होय / नाही'),
                        _buildSubRow('सिम कंपनी', _simCompanyCtrl, marathi, serif),
                        _buildSubRow('सिमचा कॉलींग क्रमांक', _simCallingNoCtrl, marathi, serif),
                        _buildSubRow('सिमकार्डवर दिसणारा सीरीयल क्र', _simCardSerialNoCtrl, marathi, serif),
                        _buildSubRow('मेमरी कार्ड आहे किं नाही असल्यास खालील माहिती', _memoryCardPresentCtrl, marathi, serif, hintText: 'होय / नाही'),
                        _buildSubRow('मेमरीकार्ड कंपनी नांव', _memoryCardCompanyCtrl, marathi, serif),
                        _buildSubRow('मेमरी कार्ड ची क्षमता', _memoryCardCapacityCtrl, marathi, serif),
                        _buildSubRow('मेमरी कार्डवर दिसणारा सिरीयल क्र', _memoryCardSerialNoCtrl, marathi, serif),
                      ],
                    ),
                  ],
                ),

                // Exhibit Row
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Text(
                        'एक्झिबीट क्र तपासी अधिकारी यांच्या पत्रानुसार',
                        style: marathi,
                      ),
                    ),
                    _tableCellInput(_exhibitNoLetterCtrl, serif, hintText: 'उदा “Exhibit – A”'),
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
                          Text('ज्यांचेकडुन जप्त केले त्यांची सही', style: marathi, textAlign: TextAlign.center),
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
                            child: Text('पंचाच्या सह्या', style: marathi, textAlign: TextAlign.center),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text('१) ', style: marathi),
                              Expanded(child: _tableCellInput(_panch1SignCtrl, serif)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text('२) ', style: marathi),
                              Expanded(child: _tableCellInput(_panch2SignCtrl, serif)),
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
                          Text('तपासी अधिकारी यांचे नाव सही शिक्का', style: marathi, textAlign: TextAlign.center),
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
                          Text('सिल नमुना', style: marathi, textAlign: TextAlign.center),
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
