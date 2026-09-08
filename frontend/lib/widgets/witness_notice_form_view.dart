import 'package:flutter/material.dart';

import 'bilingual_field.dart';
import 'form_paper_page.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';

/// Witness Notice (—:: साक्षीदार सुचनापत्र ::—).
class WitnessNoticeFormView extends StatefulWidget {
  final bool readOnly;
  final Map<String, dynamic>? existingRecord;
  final String? formSection;
  final String? pageRange;

  const WitnessNoticeFormView({
    super.key,
    this.readOnly = false,
    this.existingRecord,
    this.formSection,
    this.pageRange,
  });

  @override
  State<WitnessNoticeFormView> createState() => WitnessNoticeFormViewState();
}

class WitnessNoticeFormViewState extends State<WitnessNoticeFormView> {
  // Top Header
  final _policeStationCtrl = TextEditingController();
  final _noticeDateCtrl = TextEditingController();

  // Panch / Witness Details
  final _panchNameCtrl = TextEditingController();
  final _panchAddressLine1Ctrl = TextEditingController();
  final _panchAddressLine2Ctrl = TextEditingController();
  final _panchAddressLine3Ctrl = TextEditingController();

  // Notice Body Fields
  final _bodyPoliceStationCtrl = TextEditingController();
  final _crNoYearCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();
  final _appearanceDateCtrl = TextEditingController();
  final _appearanceTimeCtrl = TextEditingController();

  // IO Signature
  final _ioSignCtrl = TextEditingController();

  // Acknowledgement Section
  final _ackLine1Ctrl = TextEditingController();
  final _ackLine2Ctrl = TextEditingController();
  final _ackLine3Ctrl = TextEditingController();
  final _ackLine4Ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingRecord != null) {
      hydrateFrom(widget.existingRecord!);
    }
  }

  @override
  void dispose() {
    _policeStationCtrl.dispose();
    _noticeDateCtrl.dispose();
    _panchNameCtrl.dispose();
    _panchAddressLine1Ctrl.dispose();
    _panchAddressLine2Ctrl.dispose();
    _panchAddressLine3Ctrl.dispose();
    _bodyPoliceStationCtrl.dispose();
    _crNoYearCtrl.dispose();
    _sectionCtrl.dispose();
    _appearanceDateCtrl.dispose();
    _appearanceTimeCtrl.dispose();
    _ioSignCtrl.dispose();
    _ackLine1Ctrl.dispose();
    _ackLine2Ctrl.dispose();
    _ackLine3Ctrl.dispose();
    _ackLine4Ctrl.dispose();
    super.dispose();
  }

  void hydrateFrom(Map<String, dynamic> data) {
    setState(() {
      _policeStationCtrl.text = data['policeStation']?.toString() ?? '';
      _noticeDateCtrl.text =
          data['noticeDate']?.toString() ?? data['date']?.toString() ?? '';

      _panchNameCtrl.text = data['panchName']?.toString() ??
          data['witnessName']?.toString() ??
          data['witnessNameAddress']?.toString() ??
          '';
      _panchAddressLine1Ctrl.text = data['panchAddressLine1']?.toString() ??
          data['address']?.toString() ??
          '';
      _panchAddressLine2Ctrl.text = data['panchAddressLine2']?.toString() ?? '';
      _panchAddressLine3Ctrl.text = data['panchAddressLine3']?.toString() ?? '';

      _bodyPoliceStationCtrl.text = data['bodyPoliceStation']?.toString() ??
          data['policeStation']?.toString() ??
          '';
      _crNoYearCtrl.text =
          data['crNoYear']?.toString() ?? data['crNo']?.toString() ?? '';
      _sectionCtrl.text = data['section']?.toString() ?? '';
      _appearanceDateCtrl.text = data['appearanceDate']?.toString() ?? '';
      _appearanceTimeCtrl.text = data['appearanceTime']?.toString() ?? '';

      _ioSignCtrl.text =
          data['ioSign']?.toString() ?? data['ioName']?.toString() ?? '';

      _ackLine1Ctrl.text =
          data['ackLine1']?.toString() ?? data['witnessSig']?.toString() ?? '';
      _ackLine2Ctrl.text = data['ackLine2']?.toString() ??
          data['witnessReceiptDate']?.toString() ??
          '';
      _ackLine3Ctrl.text = data['ackLine3']?.toString() ?? '';
      _ackLine4Ctrl.text = data['ackLine4']?.toString() ?? '';
    });
  }

  Map<String, dynamic> collectData() {
    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'policeStation': _policeStationCtrl.text.trim(),
      'noticeDate': _noticeDateCtrl.text.trim(),
      'date': _noticeDateCtrl.text.trim(),
      'panchName': _panchNameCtrl.text.trim(),
      'witnessName': _panchNameCtrl.text.trim(),
      'witnessNameAddress': _panchNameCtrl.text.trim(),
      'panchAddressLine1': _panchAddressLine1Ctrl.text.trim(),
      'panchAddressLine2': _panchAddressLine2Ctrl.text.trim(),
      'panchAddressLine3': _panchAddressLine3Ctrl.text.trim(),
      'bodyPoliceStation': _bodyPoliceStationCtrl.text.trim().isNotEmpty
          ? _bodyPoliceStationCtrl.text.trim()
          : _policeStationCtrl.text.trim(),
      'crNoYear': _crNoYearCtrl.text.trim(),
      'crNo': _crNoYearCtrl.text.trim(),
      'section': _sectionCtrl.text.trim(),
      'appearanceDate': _appearanceDateCtrl.text.trim(),
      'appearanceTime': _appearanceTimeCtrl.text.trim(),
      'ioSign': _ioSignCtrl.text.trim(),
      'ioName': _ioSignCtrl.text.trim(),
      'ackLine1': _ackLine1Ctrl.text.trim(),
      'ackLine2': _ackLine2Ctrl.text.trim(),
      'ackLine3': _ackLine3Ctrl.text.trim(),
      'ackLine4': _ackLine4Ctrl.text.trim(),
      'witnessSig': _ackLine1Ctrl.text.trim(),
      'witnessReceiptDate': _ackLine2Ctrl.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final serif = FormTypography.serifStyle();
    final marathi = FormTypography.marathiLabelStyle();

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        FormPaperPage(
          formLabel: widget.pageRange ?? 'Witness Notice',
          children: [
            // Top Right: Police Station & Date
            Align(
              alignment: Alignment.topRight,
              child: SizedBox(
                width: 250,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('पोलीस स्टेशन',
                            style:
                                marathi.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        Expanded(
                            child: _inlineInput(_policeStationCtrl, serif)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('दिनांक :',
                            style:
                                marathi.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _inlineInput(
                            _noticeDateCtrl,
                            serif,
                            hintText: '......./......./२०...',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Center(
              child: Column(
                children: [
                  Text(
                    '—:: साक्षीदार सुचनापत्र ::—',
                    style: marathi.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Container(
                    width: 190,
                    height: 1,
                    margin: const EdgeInsets.only(top: 2),
                    color: Colors.black87,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Panch / Witness Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('पंच नांव',
                    style: marathi.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Text(':—', style: marathi),
                const SizedBox(width: 8),
                Expanded(
                    child:
                        _inlineInput(_panchNameCtrl, serif, hintText: 'नाव')),
              ],
            ),
            const SizedBox(height: 12),
            _inlineInput(_panchAddressLine1Ctrl, serif,
                hintText: 'पत्ता / व्यवसाय / वय ओळ १'),
            const SizedBox(height: 12),
            _inlineInput(_panchAddressLine2Ctrl, serif, hintText: 'ओळ २'),
            const SizedBox(height: 12),
            _inlineInput(_panchAddressLine3Ctrl, serif, hintText: 'ओळ ३'),
            const SizedBox(height: 24),

            // Centered Symbol "००००"
            Center(
              child: Text(
                '० ० ० ०',
                style: marathi.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Body Paragraph with Inline Fields
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'आपणास या सुचनापत्र देण्यात येते की, पोलीस स्टेशन ',
                  style: marathi.copyWith(fontSize: 13.5, height: 1.8),
                ),
                SizedBox(
                  width: 160,
                  child: _inlineInput(
                    _bodyPoliceStationCtrl,
                    serif,
                    hintText: _policeStationCtrl.text.isNotEmpty
                        ? _policeStationCtrl.text
                        : 'पोलीस स्टेशन',
                  ),
                ),
                Text(
                  ' येथे अपराध क्रमांक ',
                  style: marathi.copyWith(fontSize: 13.5, height: 1.8),
                ),
                SizedBox(
                  width: 140,
                  child: _inlineInput(
                    _crNoYearCtrl,
                    serif,
                    hintText: '......... / २०.....',
                  ),
                ),
                Text(
                  ' कलम ',
                  style: marathi.copyWith(fontSize: 13.5, height: 1.8),
                ),
                SizedBox(
                  width: 220,
                  child: _inlineInput(_sectionCtrl, serif, hintText: 'कलम'),
                ),
                Text(
                  ' अन्वये गुन्हा नोंद असुन सदर गुन्ह्याचे तपासकामी आपणाकडे चौकशी करून आपला जबाब नोंदविणे आवश्यक असल्याने, आपण दिनांक : ',
                  style: marathi.copyWith(fontSize: 13.5, height: 1.8),
                ),
                SizedBox(
                  width: 150,
                  child: _inlineInput(
                    _appearanceDateCtrl,
                    serif,
                    hintText: '......./......./२०.....',
                  ),
                ),
                Text(
                  ' रोजी ',
                  style: marathi.copyWith(fontSize: 13.5, height: 1.8),
                ),
                SizedBox(
                  width: 110,
                  child: _inlineInput(
                    _appearanceTimeCtrl,
                    serif,
                    hintText: '......./.......',
                  ),
                ),
                Text(
                  ' वाजता आमचे समक्ष न चुकता हजर राहावे.',
                  style: marathi.copyWith(fontSize: 13.5, height: 1.8),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Closing line
            Text(
              'करीता सुचनापत्र देण्यात येत आहे.',
              style: marathi.copyWith(fontSize: 13.5),
            ),
            const SizedBox(height: 36),

            // IO Signature
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    child:
                        _inlineInput(_ioSignCtrl, serif, hintText: 'नाव / सही'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'तपासी अधिकारी नांव व सही',
                    style: marathi.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Acknowledgement Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'सुचनापत्र मिळाले आहे.',
                  style: marathi.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 220,
                  child: _inlineInput(_ackLine1Ctrl, serif,
                      hintText: 'स्वाक्षरी / नाव'),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 220,
                  child: _inlineInput(_ackLine2Ctrl, serif,
                      hintText: 'दिनांक व वेळ'),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 220,
                  child: _inlineInput(_ackLine3Ctrl, serif),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 220,
                  child: _inlineInput(_ackLine4Ctrl, serif),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ],
    );
  }
}
