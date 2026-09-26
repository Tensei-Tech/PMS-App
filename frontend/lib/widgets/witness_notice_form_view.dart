import 'package:flutter/material.dart';

import 'form_paper_page.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';
import 'form_date_pickers.dart';

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
        final text =
            controller.text.isEmpty ? (hintText ?? '') : controller.text;

        double calcWidth = effectiveMin;
        if (text.isNotEmpty && (text.length * 12.0 + 20.0 > effectiveMin)) {
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
          calcWidth = measured < effectiveMin
              ? effectiveMin
              : (measured > effectiveMax ? effectiveMax : measured);
        }

        return RepaintBoundary(
          child: SizedBox(
            width: calcWidth,
            child: TextFormField(
              controller: controller,
              readOnly: widget.readOnly,
              maxLines: null,
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
            final text =
                controller.text.isEmpty ? (hintText ?? '') : controller.text;

            double effectiveFontSize = baseFontSize;
            double computedWidth = hasFiniteWidth ? availableWidth : baseMin;

            if (text.isNotEmpty &&
                (!hasFiniteWidth ||
                    (text.length * 12.0 + 12.0 > availableWidth))) {
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

              final double textW = tp.width + 12.0;

              if (hasFiniteWidth &&
                  textW > availableWidth &&
                  availableWidth > 30) {
                final scale =
                    ((availableWidth - 8.0) / tp.width).clamp(0.60, 1.0);
                effectiveFontSize =
                    (baseFontSize * scale).clamp(8.5, baseFontSize);
              }

              computedWidth = hasFiniteWidth
                  ? availableWidth
                  : (textW < baseMin
                      ? baseMin
                      : (textW > baseMax ? baseMax : textW));
            }

            return RepaintBoundary(
              child: SizedBox(
                width: computedWidth,
                child: TextFormField(
                  controller: controller,
                  readOnly: widget.readOnly,
                  maxLines: null,
                  scrollPhysics: const ClampingScrollPhysics(),
                  style: style.copyWith(
                    fontSize: effectiveFontSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0D47A1),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    hintText: hintText,
                    hintStyle: style.copyWith(
                      color: Colors.grey.shade400,
                      fontSize: effectiveFontSize,
                      fontStyle: FontStyle.italic,
                    ),
                    border: const UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF333333), width: 1.0),
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF555555), width: 1.0),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF1976D2), width: 2.0),
                    ),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text('पोलीस स्टेशन',
                              style: marathi.copyWith(
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _policeStationField(
                            controller: _policeStationCtrl,
                            style: serif,
                            minWidth: 100,
                          ),
                        ),
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
                        formDatePickerField(
                          context,
                          controller: _noticeDateCtrl,
                          width: 140,
                          readOnly: widget.readOnly,
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
                  child: _wrappingUnderlineInput(
                    controller: _panchNameCtrl,
                    style: serif,
                    minWidth: 260,
                    maxWidth: 700,
                    hintText: 'नाव',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _wrappingUnderlineInput(
              controller: _panchAddressLine1Ctrl,
              style: serif,
              minWidth: 260,
              maxWidth: 700,
              hintText: 'पत्ता / व्यवसाय / वय ओळ १',
            ),
            const SizedBox(height: 12),
            _wrappingUnderlineInput(
              controller: _panchAddressLine2Ctrl,
              style: serif,
              minWidth: 260,
              maxWidth: 700,
              hintText: 'ओळ २',
            ),
            const SizedBox(height: 12),
            _wrappingUnderlineInput(
              controller: _panchAddressLine3Ctrl,
              style: serif,
              minWidth: 260,
              maxWidth: 700,
              hintText: 'ओळ ३',
            ),
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
              spacing: 4,
              runSpacing: 10,
              children: [
                Text(
                  'आपणास या सुचनापत्र देण्यात येते की, पोलीस स्टेशन ',
                  style: marathi.copyWith(fontSize: 13.5, height: 1.8),
                ),
                _policeStationField(
                  controller: _bodyPoliceStationCtrl,
                  style: serif,
                  minWidth: 140,
                  maxWidth: 300,
                  hintText: _policeStationCtrl.text.isNotEmpty
                      ? _policeStationCtrl.text
                      : null,
                ),
                Text(
                  ' येथे अपराध क्रमांक ',
                  style: marathi.copyWith(fontSize: 13.5, height: 1.8),
                ),
                _wrappingUnderlineInput(
                  controller: _crNoYearCtrl,
                  style: serif,
                  minWidth: 120,
                  maxWidth: 240,
                  hintText: '......... / २०.....',
                ),
                Text(
                  ' कलम ',
                  style: marathi.copyWith(fontSize: 13.5, height: 1.8),
                ),
                _wrappingUnderlineInput(
                  controller: _sectionCtrl,
                  style: serif,
                  minWidth: 160,
                  maxWidth: 500,
                  hintText: 'कलम',
                ),
                Text(
                  ' अन्वये गुन्हा नोंद असुन सदर गुन्ह्याचे तपासकामी आपणाकडे चौकशी करून आपला जबाब नोंदविणे आवश्यक असल्याने, आपण दिनांक : ',
                  style: marathi.copyWith(fontSize: 13.5, height: 1.8),
                ),
                formDatePickerField(
                  context,
                  controller: _appearanceDateCtrl,
                  width: 140,
                  readOnly: widget.readOnly,
                ),
                Text(
                  ' रोजी ',
                  style: marathi.copyWith(fontSize: 13.5, height: 1.8),
                ),
                formTimePickerField(
                  context,
                  controller: _appearanceTimeCtrl,
                  width: 100,
                  readOnly: widget.readOnly,
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
                  _wrappingUnderlineInput(
                    controller: _ioSignCtrl,
                    style: serif,
                    minWidth: 160,
                    maxWidth: 220,
                    hintText: 'नाव / सही',
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
                _wrappingUnderlineInput(
                  controller: _ackLine1Ctrl,
                  style: serif,
                  minWidth: 160,
                  maxWidth: 260,
                  hintText: 'स्वाक्षरी / नाव',
                ),
                const SizedBox(height: 8),
                _wrappingUnderlineInput(
                  controller: _ackLine2Ctrl,
                  style: serif,
                  minWidth: 160,
                  maxWidth: 260,
                  hintText: 'दिनांक व वेळ',
                ),
                const SizedBox(height: 8),
                _wrappingUnderlineInput(
                  controller: _ackLine3Ctrl,
                  style: serif,
                  minWidth: 160,
                  maxWidth: 260,
                ),
                const SizedBox(height: 8),
                _wrappingUnderlineInput(
                  controller: _ackLine4Ctrl,
                  style: serif,
                  minWidth: 160,
                  maxWidth: 260,
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
