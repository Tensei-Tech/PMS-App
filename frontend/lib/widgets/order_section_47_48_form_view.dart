import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'form_paper_page.dart';
import 'form_section_utils.dart';
import 'form_view_scaffold.dart';

/// Order Section 47 & 48 Form View — 100% Faithful Marathi implementation with custom header logo picker
class OrderSection4748FormView extends StatefulWidget {
  final dynamic existingRecord;
  final bool readOnly;
  final String? formSection;
  final String? pageRange;

  const OrderSection4748FormView({
    super.key,
    this.existingRecord,
    this.readOnly = false,
    this.formSection,
    this.pageRange,
  });

  @override
  State<OrderSection4748FormView> createState() =>
      OrderSection4748FormViewState();
}

class OrderSection4748FormViewState extends State<OrderSection4748FormView> {
  static const kNotice47 = 'Notice BNSS 47(1)';
  static const kNotice48 = 'Notice BNSS 48';
  static const _knownSectionIds = {kNotice47, kNotice48};

  bool _shows(String id) {
    if (widget.formSection == null || widget.formSection!.isEmpty) return true;
    final s = widget.formSection!.toLowerCase();
    if (id == kNotice47) {
      return s.contains('47') || s.contains('main') || s.contains('page 1') || s.contains('1');
    }
    if (id == kNotice48) {
      return s.contains('48') || s.contains('continuation') || s.contains('page 2') || s.contains('2');
    }
    return showsFormSection(
      activeSection: widget.formSection,
      sectionId: id,
      knownSectionIds: _knownSectionIds,
    );
  }

  // ── Header Data (Shared) ──
  String? _leftLogoBase64;
  String? _rightLogoBase64;
  final _headerStationCtrl =
      TextEditingController(text: 'म्हाळुंगे M.I.D.C. पोलीस स्टेशन');
  final _headerCommissionerateCtrl =
      TextEditingController(text: 'पिंपरी चिंचवड पोलीस आयुक्तालय');
  final _headerAddress1Ctrl = TextEditingController(
      text: 'पत्ता- एम.आय.डी.सी.चौक,चाकण-तळेगाव दाभाडे रोड,');
  final _headerAddress2Ctrl =
      TextEditingController(text: 'म्हाळुंगे (इंगळे), ता-खेड, जि-पुणे ४१०५०१');
  final _headerEmailCtrl =
      TextEditingController(text: 'मेल आय.डी. pimahalunge.pcpc-mh@gov.in');
  final _headerPhoneCtrl =
      TextEditingController(text: 'संपर्क क्रमांक - ७०२८५३५३२३');

  // Top header bar fields
  final _outwardNoCtrl = TextEditingController();
  final _noticeDateDayCtrl = TextEditingController();
  final _noticeDateMonthCtrl = TextEditingController();
  final _noticeDateYearCtrl = TextEditingController();

  // ── Page 1: Section 47(1) Controllers ──
  final _n47ToCtrl = TextEditingController();
  final _n47PsCtrl =
      TextEditingController(text: 'म्हाळुंगे एम.आय.डी.सी.पोलीस स्टेशन');
  final _n47CrNoCtrl = TextEditingController();
  final _n47CrYearCtrl = TextEditingController();
  final _n47SectionCtrl = TextEditingController();
  final _n47ArrestDayCtrl = TextEditingController();
  final _n47ArrestMonthCtrl = TextEditingController();
  final _n47ArrestYearCtrl = TextEditingController();
  final _n47ArrestTimeCtrl = TextEditingController();
  final _n47OffenceFactsCtrl = TextEditingController();
  final _n47Ground1Ctrl = TextEditingController();
  final _n47Ground2Ctrl = TextEditingController();
  final _n47Ground3Ctrl = TextEditingController();
  final _n47Ground4Ctrl = TextEditingController();
  final _n47Ground5Ctrl = TextEditingController();
  final _n47Reason1Ctrl = TextEditingController();
  final _n47Reason2Ctrl = TextEditingController();
  final _n47Reason3Ctrl = TextEditingController();
  final _n47Reason4Ctrl = TextEditingController();
  final _n47Reason5Ctrl = TextEditingController();
  final _n47BailableCtrl = TextEditingController(
      text:
          'सदर गुन्हा हा जामीनपात्र/अजामीनपात्र आहे. गुन्हा जामीनपात्र असल्याने आपण योग्य तो जामीन दिल्यास आपणास जामीनावर मुक्त करण्यात येईल.');
  final _n47RemandDayCtrl = TextEditingController();
  final _n47RemandMonthCtrl = TextEditingController();
  final _n47RemandYearCtrl = TextEditingController();
  final _n47AccusedSigCtrl = TextEditingController();
  final _n47IoSigCtrl = TextEditingController();

  // ── Page 2: Section 48 Controllers ──
  final _n48ToCtrl = TextEditingController();
  final _n48PsCtrl =
      TextEditingController(text: 'म्हाळुंगे एम.आय.डी.सी.पोलीस स्टेशन');
  final _n48CrNoCtrl = TextEditingController();
  final _n48CrYearCtrl = TextEditingController();
  final _n48SectionCtrl = TextEditingController();
  final _n48RelativeNameCtrl = TextEditingController();
  final _n48ArrestDayCtrl = TextEditingController();
  final _n48ArrestMonthCtrl = TextEditingController();
  final _n48ArrestYearCtrl = TextEditingController();
  final _n48ArrestTimeCtrl = TextEditingController();
  final _n48OffenceFactsCtrl = TextEditingController();
  final _n48Ground1Ctrl = TextEditingController();
  final _n48Ground2Ctrl = TextEditingController();
  final _n48Ground3Ctrl = TextEditingController();
  final _n48Ground4Ctrl = TextEditingController();
  final _n48Ground5Ctrl = TextEditingController();
  final _n48Reason1Ctrl = TextEditingController();
  final _n48Reason2Ctrl = TextEditingController();
  final _n48Reason3Ctrl = TextEditingController();
  final _n48Reason4Ctrl = TextEditingController();
  final _n48Reason5Ctrl = TextEditingController();
  final _n48BailableCtrl = TextEditingController(
      text:
          'सदर गुन्हा हा जामीनपात्र/अजामीनपात्र आहे. गुन्हा जामीनपात्र असल्याने योग्य तो जामीन दिल्यास अटक व्यक्तीस जामीनावर मुक्त करण्यात येईल.');
  final _n48RemandDayCtrl = TextEditingController();
  final _n48RemandMonthCtrl = TextEditingController();
  final _n48RemandYearCtrl = TextEditingController();
  final _n48RelativeSigCtrl = TextEditingController();
  final _n48IoSigCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.existingRecord != null && widget.existingRecord is Map) {
      hydrateFrom(Map<String, dynamic>.from(widget.existingRecord as Map));
    }
  }

  @override
  void dispose() {
    for (final c in [
      _headerStationCtrl,
      _headerCommissionerateCtrl,
      _headerAddress1Ctrl,
      _headerAddress2Ctrl,
      _headerEmailCtrl,
      _headerPhoneCtrl,
      _outwardNoCtrl,
      _noticeDateDayCtrl,
      _noticeDateMonthCtrl,
      _noticeDateYearCtrl,
      _n47ToCtrl,
      _n47PsCtrl,
      _n47CrNoCtrl,
      _n47CrYearCtrl,
      _n47SectionCtrl,
      _n47ArrestDayCtrl,
      _n47ArrestMonthCtrl,
      _n47ArrestYearCtrl,
      _n47ArrestTimeCtrl,
      _n47OffenceFactsCtrl,
      _n47Ground1Ctrl,
      _n47Ground2Ctrl,
      _n47Ground3Ctrl,
      _n47Ground4Ctrl,
      _n47Ground5Ctrl,
      _n47Reason1Ctrl,
      _n47Reason2Ctrl,
      _n47Reason3Ctrl,
      _n47Reason4Ctrl,
      _n47Reason5Ctrl,
      _n47BailableCtrl,
      _n47RemandDayCtrl,
      _n47RemandMonthCtrl,
      _n47RemandYearCtrl,
      _n47AccusedSigCtrl,
      _n47IoSigCtrl,
      _n48ToCtrl,
      _n48PsCtrl,
      _n48CrNoCtrl,
      _n48CrYearCtrl,
      _n48SectionCtrl,
      _n48RelativeNameCtrl,
      _n48ArrestDayCtrl,
      _n48ArrestMonthCtrl,
      _n48ArrestYearCtrl,
      _n48ArrestTimeCtrl,
      _n48OffenceFactsCtrl,
      _n48Ground1Ctrl,
      _n48Ground2Ctrl,
      _n48Ground3Ctrl,
      _n48Ground4Ctrl,
      _n48Ground5Ctrl,
      _n48Reason1Ctrl,
      _n48Reason2Ctrl,
      _n48Reason3Ctrl,
      _n48Reason4Ctrl,
      _n48Reason5Ctrl,
      _n48BailableCtrl,
      _n48RemandDayCtrl,
      _n48RemandMonthCtrl,
      _n48RemandYearCtrl,
      _n48RelativeSigCtrl,
      _n48IoSigCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickLogo(bool isLeft) async {
    if (widget.readOnly) return;
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (xFile == null) return;
      final bytes = await xFile.readAsBytes();
      final b64 = base64Encode(bytes);
      setState(() {
        if (isLeft) {
          _leftLogoBase64 = b64;
        } else {
          _rightLogoBase64 = b64;
        }
      });
    } catch (e) {
      debugPrint('Error picking logo: $e');
    }
  }

  Map<String, dynamic> collectData() {
    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'leftLogoBase64': _leftLogoBase64 ?? '',
      'rightLogoBase64': _rightLogoBase64 ?? '',
      'headerStation': _headerStationCtrl.text.trim(),
      'headerCommissionerate': _headerCommissionerateCtrl.text.trim(),
      'headerAddress1': _headerAddress1Ctrl.text.trim(),
      'headerAddress2': _headerAddress2Ctrl.text.trim(),
      'headerEmail': _headerEmailCtrl.text.trim(),
      'headerPhone': _headerPhoneCtrl.text.trim(),
      'outwardNo': _outwardNoCtrl.text.trim(),
      'noticeDateDay': _noticeDateDayCtrl.text.trim(),
      'noticeDateMonth': _noticeDateMonthCtrl.text.trim(),
      'noticeDateYear': _noticeDateYearCtrl.text.trim(),

      // Section 47(1)
      'n47To': _n47ToCtrl.text.trim(),
      'n47Ps': _n47PsCtrl.text.trim(),
      'n47CrNo': _n47CrNoCtrl.text.trim(),
      'n47CrYear': _n47CrYearCtrl.text.trim(),
      'n47Section': _n47SectionCtrl.text.trim(),
      'n47ArrestDay': _n47ArrestDayCtrl.text.trim(),
      'n47ArrestMonth': _n47ArrestMonthCtrl.text.trim(),
      'n47ArrestYear': _n47ArrestYearCtrl.text.trim(),
      'n47ArrestTime': _n47ArrestTimeCtrl.text.trim(),
      'n47OffenceFacts': _n47OffenceFactsCtrl.text.trim(),
      'n47Ground1': _n47Ground1Ctrl.text.trim(),
      'n47Ground2': _n47Ground2Ctrl.text.trim(),
      'n47Ground3': _n47Ground3Ctrl.text.trim(),
      'n47Ground4': _n47Ground4Ctrl.text.trim(),
      'n47Ground5': _n47Ground5Ctrl.text.trim(),
      'n47Reason1': _n47Reason1Ctrl.text.trim(),
      'n47Reason2': _n47Reason2Ctrl.text.trim(),
      'n47Reason3': _n47Reason3Ctrl.text.trim(),
      'n47Reason4': _n47Reason4Ctrl.text.trim(),
      'n47Reason5': _n47Reason5Ctrl.text.trim(),
      'n47Bailable': _n47BailableCtrl.text.trim(),
      'n47RemandDay': _n47RemandDayCtrl.text.trim(),
      'n47RemandMonth': _n47RemandMonthCtrl.text.trim(),
      'n47RemandYear': _n47RemandYearCtrl.text.trim(),
      'n47AccusedSig': _n47AccusedSigCtrl.text.trim(),
      'n47IoSig': _n47IoSigCtrl.text.trim(),

      // Section 48
      'n48To': _n48ToCtrl.text.trim(),
      'n48Ps': _n48PsCtrl.text.trim(),
      'n48CrNo': _n48CrNoCtrl.text.trim(),
      'n48CrYear': _n48CrYearCtrl.text.trim(),
      'n48Section': _n48SectionCtrl.text.trim(),
      'n48RelativeName': _n48RelativeNameCtrl.text.trim(),
      'n48ArrestDay': _n48ArrestDayCtrl.text.trim(),
      'n48ArrestMonth': _n48ArrestMonthCtrl.text.trim(),
      'n48ArrestYear': _n48ArrestYearCtrl.text.trim(),
      'n48ArrestTime': _n48ArrestTimeCtrl.text.trim(),
      'n48OffenceFacts': _n48OffenceFactsCtrl.text.trim(),
      'n48Ground1': _n48Ground1Ctrl.text.trim(),
      'n48Ground2': _n48Ground2Ctrl.text.trim(),
      'n48Ground3': _n48Ground3Ctrl.text.trim(),
      'n48Ground4': _n48Ground4Ctrl.text.trim(),
      'n48Ground5': _n48Ground5Ctrl.text.trim(),
      'n48Reason1': _n48Reason1Ctrl.text.trim(),
      'n48Reason2': _n48Reason2Ctrl.text.trim(),
      'n48Reason3': _n48Reason3Ctrl.text.trim(),
      'n48Reason4': _n48Reason4Ctrl.text.trim(),
      'n48Reason5': _n48Reason5Ctrl.text.trim(),
      'n48Bailable': _n48BailableCtrl.text.trim(),
      'n48RemandDay': _n48RemandDayCtrl.text.trim(),
      'n48RemandMonth': _n48RemandMonthCtrl.text.trim(),
      'n48RemandYear': _n48RemandYearCtrl.text.trim(),
      'n48RelativeSig': _n48RelativeSigCtrl.text.trim(),
      'n48IoSig': _n48IoSigCtrl.text.trim(),
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    setState(() {
      _leftLogoBase64 = data['leftLogoBase64']?.toString();
      _rightLogoBase64 = data['rightLogoBase64']?.toString();
      if (data['headerStation'] != null) {
        _headerStationCtrl.text = data['headerStation'].toString();
      }
      if (data['headerCommissionerate'] != null) {
        _headerCommissionerateCtrl.text =
            data['headerCommissionerate'].toString();
      }
      if (data['headerAddress1'] != null) {
        _headerAddress1Ctrl.text = data['headerAddress1'].toString();
      }
      if (data['headerAddress2'] != null) {
        _headerAddress2Ctrl.text = data['headerAddress2'].toString();
      }
      if (data['headerEmail'] != null) {
        _headerEmailCtrl.text = data['headerEmail'].toString();
      }
      if (data['headerPhone'] != null) {
        _headerPhoneCtrl.text = data['headerPhone'].toString();
      }

      _outwardNoCtrl.text = data['outwardNo']?.toString() ?? '';
      _noticeDateDayCtrl.text = data['noticeDateDay']?.toString() ?? '';
      _noticeDateMonthCtrl.text = data['noticeDateMonth']?.toString() ?? '';
      _noticeDateYearCtrl.text = data['noticeDateYear']?.toString() ?? '';

      // 47(1)
      _n47ToCtrl.text = data['n47To']?.toString() ?? '';
      _n47PsCtrl.text = data['n47Ps']?.toString() ??
          _headerStationCtrl.text;
      _n47CrNoCtrl.text = data['n47CrNo']?.toString() ?? '';
      _n47CrYearCtrl.text = data['n47CrYear']?.toString() ?? '';
      _n47SectionCtrl.text = data['n47Section']?.toString() ?? '';
      _n47ArrestDayCtrl.text = data['n47ArrestDay']?.toString() ?? '';
      _n47ArrestMonthCtrl.text = data['n47ArrestMonth']?.toString() ?? '';
      _n47ArrestYearCtrl.text = data['n47ArrestYear']?.toString() ?? '';
      _n47ArrestTimeCtrl.text = data['n47ArrestTime']?.toString() ?? '';
      _n47OffenceFactsCtrl.text = data['n47OffenceFacts']?.toString() ?? '';
      _n47Ground1Ctrl.text = data['n47Ground1']?.toString() ?? '';
      _n47Ground2Ctrl.text = data['n47Ground2']?.toString() ?? '';
      _n47Ground3Ctrl.text = data['n47Ground3']?.toString() ?? '';
      _n47Ground4Ctrl.text = data['n47Ground4']?.toString() ?? '';
      _n47Ground5Ctrl.text = data['n47Ground5']?.toString() ?? '';
      _n47Reason1Ctrl.text = data['n47Reason1']?.toString() ?? '';
      _n47Reason2Ctrl.text = data['n47Reason2']?.toString() ?? '';
      _n47Reason3Ctrl.text = data['n47Reason3']?.toString() ?? '';
      _n47Reason4Ctrl.text = data['n47Reason4']?.toString() ?? '';
      _n47Reason5Ctrl.text = data['n47Reason5']?.toString() ?? '';
      if (data['n47Bailable'] != null) {
        _n47BailableCtrl.text = data['n47Bailable'].toString();
      }
      _n47RemandDayCtrl.text = data['n47RemandDay']?.toString() ?? '';
      _n47RemandMonthCtrl.text = data['n47RemandMonth']?.toString() ?? '';
      _n47RemandYearCtrl.text = data['n47RemandYear']?.toString() ?? '';
      _n47AccusedSigCtrl.text = data['n47AccusedSig']?.toString() ?? '';
      _n47IoSigCtrl.text = data['n47IoSig']?.toString() ?? '';

      // 48
      _n48ToCtrl.text = data['n48To']?.toString() ?? '';
      _n48PsCtrl.text = data['n48Ps']?.toString() ??
          _headerStationCtrl.text;
      _n48CrNoCtrl.text = data['n48CrNo']?.toString() ?? '';
      _n48CrYearCtrl.text = data['n48CrYear']?.toString() ?? '';
      _n48SectionCtrl.text = data['n48Section']?.toString() ?? '';
      _n48RelativeNameCtrl.text = data['n48RelativeName']?.toString() ?? '';
      _n48ArrestDayCtrl.text = data['n48ArrestDay']?.toString() ?? '';
      _n48ArrestMonthCtrl.text = data['n48ArrestMonth']?.toString() ?? '';
      _n48ArrestYearCtrl.text = data['n48ArrestYear']?.toString() ?? '';
      _n48ArrestTimeCtrl.text = data['n48ArrestTime']?.toString() ?? '';
      _n48OffenceFactsCtrl.text = data['n48OffenceFacts']?.toString() ?? '';
      _n48Ground1Ctrl.text = data['n48Ground1']?.toString() ?? '';
      _n48Ground2Ctrl.text = data['n48Ground2']?.toString() ?? '';
      _n48Ground3Ctrl.text = data['n48Ground3']?.toString() ?? '';
      _n48Ground4Ctrl.text = data['n48Ground4']?.toString() ?? '';
      _n48Ground5Ctrl.text = data['n48Ground5']?.toString() ?? '';
      _n48Reason1Ctrl.text = data['n48Reason1']?.toString() ?? '';
      _n48Reason2Ctrl.text = data['n48Reason2']?.toString() ?? '';
      _n48Reason3Ctrl.text = data['n48Reason3']?.toString() ?? '';
      _n48Reason4Ctrl.text = data['n48Reason4']?.toString() ?? '';
      _n48Reason5Ctrl.text = data['n48Reason5']?.toString() ?? '';
      if (data['n48Bailable'] != null) {
        _n48BailableCtrl.text = data['n48Bailable'].toString();
      }
      _n48RemandDayCtrl.text = data['n48RemandDay']?.toString() ?? '';
      _n48RemandMonthCtrl.text = data['n48RemandMonth']?.toString() ?? '';
      _n48RemandYearCtrl.text = data['n48RemandYear']?.toString() ?? '';
      _n48RelativeSigCtrl.text = data['n48RelativeSig']?.toString() ?? '';
      _n48IoSigCtrl.text = data['n48IoSig']?.toString() ?? '';
    });
  }

  // ── Helper Inputs ──

  Widget _inlineBlank({
    required TextEditingController controller,
    required TextStyle style,
    double? width,
    bool readOnly = false,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        readOnly: widget.readOnly || readOnly,
        style: style.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: const Color(0xFF0D47A1),
        ),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF333333), width: 1.2),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF555555), width: 1.0),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF1976D2), width: 2.0),
          ),
        ),
      ),
    );
  }

  Widget _multilineBlankBox({
    required TextEditingController controller,
    required TextStyle style,
    int minLines = 3,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: widget.readOnly,
      minLines: minLines,
      maxLines: null,
      style: style.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 15,
        height: 1.5,
        color: const Color(0xFF0D47A1),
      ),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF555555), width: 1.0),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF555555), width: 1.0),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF1976D2), width: 2.0),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER WIDGET (Image Header Table with Logo Uploaders)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildOfficialHeader(TextStyle mrStyle) {
    Uint8List? leftBytes;
    if (_leftLogoBase64 != null && _leftLogoBase64!.isNotEmpty) {
      try {
        leftBytes = base64Decode(_leftLogoBase64!);
      } catch (_) {}
    }

    Uint8List? rightBytes;
    if (_rightLogoBase64 != null && _rightLogoBase64!.isNotEmpty) {
      try {
        rightBytes = base64Decode(_rightLogoBase64!);
      } catch (_) {}
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Left Logo Area ──
                Container(
                  width: 140,
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Colors.black, width: 1.2),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: leftBytes != null
                            ? Image.memory(leftBytes, fit: BoxFit.contain)
                            : Image.asset(
                                'assets/images/police_logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.shield_outlined,
                                  size: 48,
                                  color: Color(0xFF1565C0),
                                ),
                              ),
                      ),
                      if (!widget.readOnly)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () => _pickLogo(true),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1976D2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Center Police Station Details ──
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _headerStationCtrl.text,
                          textAlign: TextAlign.center,
                          style: mrStyle.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _headerCommissionerateCtrl.text,
                          textAlign: TextAlign.center,
                          style: mrStyle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _headerAddress1Ctrl.text,
                          textAlign: TextAlign.center,
                          style: mrStyle.copyWith(fontSize: 13),
                        ),
                        Text(
                          _headerAddress2Ctrl.text,
                          textAlign: TextAlign.center,
                          style: mrStyle.copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _headerEmailCtrl.text,
                          textAlign: TextAlign.center,
                          style: mrStyle.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _headerPhoneCtrl.text,
                          textAlign: TextAlign.center,
                          style: mrStyle.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Right Logo Area ──
                Container(
                  width: 140,
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Colors.black, width: 1.2),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: rightBytes != null
                            ? Image.memory(rightBytes, fit: BoxFit.contain)
                            : Image.asset(
                                'assets/images/maharashtra_police_logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.account_balance,
                                  size: 48,
                                  color: Color(0xFFD32F2F),
                                ),
                              ),
                      ),
                      if (!widget.readOnly)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () => _pickLogo(false),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1976D2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom Reference Bar ──
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.black, width: 1.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Text('जावक क्रमांक - ',
                            style: mrStyle.copyWith(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: _inlineBlank(
                            controller: _outwardNoCtrl,
                            style: mrStyle,
                          ),
                        ),
                        Text(' / ',
                            style: mrStyle.copyWith(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1.2,
                  height: 36,
                  color: Colors.black,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('दि. ',
                            style: mrStyle.copyWith(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        _inlineBlank(
                          controller: _noticeDateDayCtrl,
                          style: mrStyle,
                          width: 40,
                        ),
                        Text(' / ',
                            style: mrStyle.copyWith(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        _inlineBlank(
                          controller: _noticeDateMonthCtrl,
                          style: mrStyle,
                          width: 40,
                        ),
                        Text(' / ',
                            style: mrStyle.copyWith(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        _inlineBlank(
                          controller: _noticeDateYearCtrl,
                          style: mrStyle,
                          width: 50,
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
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 1: बी.एन.एस.एस.कलम ४७(१) — Exactly matching Image 1
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildNotice47Page(TextStyle mrStyle) {
    return FormPaperPage(
      formLabel: widget.pageRange ?? 'Notice BNSS 47(1)',
      children: [
        // ── Official Header ──
        _buildOfficialHeader(mrStyle),
        const SizedBox(height: 20),

        // ── Centered Notice Titles ──
        Center(
          child: Column(
            children: [
              Text(
                'नोटीस',
                style: mrStyle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'बी.एन.एस.एस.कलम ४७(१)',
                style: mrStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── To Block (प्रति,) ──
        Text('प्रति,',
            style:
                mrStyle.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        _multilineBlankBox(
          controller: _n47ToCtrl,
          style: mrStyle,
          minLines: 3,
        ),
        const SizedBox(height: 16),

        // ── Subject (विषय) ──
        Text(
          'विषय :- गुन्ह्याचे तपास कामी अटक करण्याचा आधार व कारणांबाबत...',
          style: mrStyle.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // ── Main Notice Body Paragraph ──
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 8,
          children: [
            Text('आपणास याद्वारे कळविण्यात येते की,',
                style: mrStyle.copyWith(fontSize: 15)),
            _inlineBlank(
              controller: _n47PsCtrl,
              style: mrStyle,
              width: 220,
            ),
            Text('गुन्हा रजि.नंबर', style: mrStyle.copyWith(fontSize: 15)),
            _inlineBlank(
              controller: _n47CrNoCtrl,
              style: mrStyle,
              width: 80,
            ),
            Text('/२०', style: mrStyle.copyWith(fontSize: 15)),
            _inlineBlank(
              controller: _n47CrYearCtrl,
              style: mrStyle,
              width: 45,
            ),
            Text('भा.न्या.सं.कलम', style: mrStyle.copyWith(fontSize: 15)),
            _inlineBlank(
              controller: _n47SectionCtrl,
              style: mrStyle,
              width: 280,
            ),
            Text(
                'या गुन्ह्यात तपास कामी दि.',
                style: mrStyle.copyWith(fontSize: 15)),
            _inlineBlank(
              controller: _n47ArrestDayCtrl,
              style: mrStyle,
              width: 40,
            ),
            Text('/', style: mrStyle.copyWith(fontSize: 15)),
            _inlineBlank(
              controller: _n47ArrestMonthCtrl,
              style: mrStyle,
              width: 40,
            ),
            Text('/२०', style: mrStyle.copyWith(fontSize: 15)),
            _inlineBlank(
              controller: _n47ArrestYearCtrl,
              style: mrStyle,
              width: 45,
            ),
            Text('रोजी', style: mrStyle.copyWith(fontSize: 15)),
            _inlineBlank(
              controller: _n47ArrestTimeCtrl,
              style: mrStyle,
              width: 80,
            ),
            Text(
                'वा. खालील आधारावर व कारणांसाठी अटक करण्यात येत आहे.',
                style: mrStyle.copyWith(fontSize: 15, height: 1.5)),
          ],
        ),
        const SizedBox(height: 18),

        // ── अ) गुन्ह्याची थोडक्यात हकीगत :- ──
        Text(
          'अ) गुन्ह्याची थोडक्यात हकीगत :-',
          style: mrStyle.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        _multilineBlankBox(
          controller: _n47OffenceFactsCtrl,
          style: mrStyle,
          minLines: 4,
        ),
        const SizedBox(height: 18),

        // ── ब) अटक करण्यासंबंधाने आधार :- ──
        Text(
          'ब) अटक करण्यासंबंधाने आधार :-',
          style: mrStyle.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        for (final item in [
          ('१)', _n47Ground1Ctrl),
          ('२)', _n47Ground2Ctrl),
          ('३)', _n47Ground3Ctrl),
          ('४)', _n47Ground4Ctrl),
          ('५)', _n47Ground5Ctrl),
        ]) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(item.$1,
                    style: mrStyle.copyWith(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Expanded(
                  child: _inlineBlank(
                    controller: item.$2,
                    style: mrStyle,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),

        // ── क) अटकेची कारणे :- ──
        Text(
          'क) अटकेची कारणे :-',
          style: mrStyle.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        for (final item in [
          ('१)', _n47Reason1Ctrl),
          ('२)', _n47Reason2Ctrl),
          ('३)', _n47Reason3Ctrl),
          ('४)', _n47Reason4Ctrl),
          ('५)', _n47Reason5Ctrl),
        ]) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(item.$1,
                    style: mrStyle.copyWith(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Expanded(
                  child: _inlineBlank(
                    controller: item.$2,
                    style: mrStyle,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),

        // ── ड) जामीन माहिती ──
        Text(
          'ड) ${_n47BailableCtrl.text}',
          style: mrStyle.copyWith(fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 16),

        // ── इ) रिमांड हजर माहिती ──
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 6,
          children: [
            Text('इ) आपणास दिनांक', style: mrStyle.copyWith(fontSize: 15)),
            _inlineBlank(
              controller: _n47RemandDayCtrl,
              style: mrStyle,
              width: 40,
            ),
            Text('/', style: mrStyle.copyWith(fontSize: 15)),
            _inlineBlank(
              controller: _n47RemandMonthCtrl,
              style: mrStyle,
              width: 40,
            ),
            Text('/२०', style: mrStyle.copyWith(fontSize: 15)),
            _inlineBlank(
              controller: _n47RemandYearCtrl,
              style: mrStyle,
              width: 45,
            ),
            Text(
              'रोजी मा.प्रथम वर्ग न्यायदंडाधिकारी यांचे समक्ष रिमांडसाठी हजर करण्यात येणार आहे.',
              style: mrStyle.copyWith(fontSize: 15, height: 1.5),
            ),
          ],
        ),
        const SizedBox(height: 36),

        // ── Signatures 2-Column Row ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _inlineBlank(
                  controller: _n47AccusedSigCtrl,
                  style: mrStyle,
                  width: 220,
                ),
                const SizedBox(height: 4),
                Text(
                  'आरोपीची दिनांकीत सही',
                  style: mrStyle.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'कळावे,',
                  style: mrStyle.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _inlineBlank(
                  controller: _n47IoSigCtrl,
                  style: mrStyle,
                  width: 220,
                ),
                const SizedBox(height: 4),
                Text(
                  'तपासी अधिकारी/अंमलदार',
                  style: mrStyle.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 2: बी.एन.एस.एस.कलम ४८ — Exactly matching Image 2
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildNotice48Page(TextStyle mrStyle) {
    return FormPaperPage(
      formLabel: widget.pageRange ?? 'Notice BNSS 48',
      children: [
        // ── Official Header ──
        _buildOfficialHeader(mrStyle),
        const SizedBox(height: 20),

        // ── Centered Notice Titles ──
        Center(
          child: Column(
            children: [
              Text(
                'नोटीस',
                style: mrStyle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'बी.एन.एस.एस.कलम ४८',
                style: mrStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── To Block (प्रति,) ──
        Text('प्रति,',
            style:
                mrStyle.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        _multilineBlankBox(
          controller: _n48ToCtrl,
          style: mrStyle,
          minLines: 3,
        ),
        const SizedBox(height: 16),

        // ── Subject (विषय) ──
        Text(
          'विषय :- गुन्ह्याचे तपास कामी अटक केले संबंधी अवगत केले बाबत...',
          style: mrStyle.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // ── Main Notice Body Paragraph ──
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 8,
          children: [
            Text('आपणास याद्वारे कळविण्यात येते की,',
                style: mrStyle.copyWith(fontSize: 15)),
            _inlineBlank(
              controller: _n48PsCtrl,
              style: mrStyle,
              width: 220,
            ),
            Text('गुन्हा रजि.नंबर', style: mrStyle.copyWith(fontSize: 15)),
            _inlineBlank(
              controller: _n48CrNoCtrl,
              style: mrStyle,
              width: 80,
            ),
            Text('/२०', style: mrStyle.copyWith(fontSize: 15)),
            _inlineBlank(
              controller: _n48CrYearCtrl,
              style: mrStyle,
              width: 45,
            ),
            Text('भा.न्या.सं.कलम', style: mrStyle.copyWith(fontSize: 15)),
            _inlineBlank(
              controller: _n48SectionCtrl,
              style: mrStyle,
              width: 280,
            ),
            Text(
                'या गुन्ह्यात आपले नातेवाईक / मित्र / आप्तेष्ट नामे',
                style: mrStyle.copyWith(fontSize: 15)),
            _inlineBlank(
              controller: _n48RelativeNameCtrl,
              style: mrStyle,
              width: 280,
            ),
            Text('यांना दिनांक', style: mrStyle.copyWith(fontSize: 15)),
            _inlineBlank(
              controller: _n48ArrestDayCtrl,
              style: mrStyle,
              width: 40,
            ),
            Text('/', style: mrStyle.copyWith(fontSize: 15)),
            _inlineBlank(
              controller: _n48ArrestMonthCtrl,
              style: mrStyle,
              width: 40,
            ),
            Text('/२०', style: mrStyle.copyWith(fontSize: 15)),
            _inlineBlank(
              controller: _n48ArrestYearCtrl,
              style: mrStyle,
              width: 45,
            ),
            Text('रोजी', style: mrStyle.copyWith(fontSize: 15)),
            _inlineBlank(
              controller: _n48ArrestTimeCtrl,
              style: mrStyle,
              width: 80,
            ),
            Text(
                'वा. अटक करण्यात आली आहे.',
                style: mrStyle.copyWith(fontSize: 15, height: 1.5)),
          ],
        ),
        const SizedBox(height: 18),

        // ── अ) गुन्ह्याची थोडक्यात हकीगत :- ──
        Text(
          'अ) गुन्ह्याची थोडक्यात हकीगत :-',
          style: mrStyle.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        _multilineBlankBox(
          controller: _n48OffenceFactsCtrl,
          style: mrStyle,
          minLines: 4,
        ),
        const SizedBox(height: 18),

        // ── ब) अटक करण्यासंबंधाने आधार :- ──
        Text(
          'ब) अटक करण्यासंबंधाने आधार :-',
          style: mrStyle.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        for (final item in [
          ('१)', _n48Ground1Ctrl),
          ('२)', _n48Ground2Ctrl),
          ('३)', _n48Ground3Ctrl),
          ('४)', _n48Ground4Ctrl),
          ('५)', _n48Ground5Ctrl),
        ]) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(item.$1,
                    style: mrStyle.copyWith(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Expanded(
                  child: _inlineBlank(
                    controller: item.$2,
                    style: mrStyle,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),

        // ── क) अटकेची कारणे :- ──
        Text(
          'क) अटकेची कारणे :-',
          style: mrStyle.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        for (final item in [
          ('१)', _n48Reason1Ctrl),
          ('२)', _n48Reason2Ctrl),
          ('३)', _n48Reason3Ctrl),
          ('४)', _n48Reason4Ctrl),
          ('५)', _n48Reason5Ctrl),
        ]) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(item.$1,
                    style: mrStyle.copyWith(
                        fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Expanded(
                  child: _inlineBlank(
                    controller: item.$2,
                    style: mrStyle,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),

        // ── ड) जामीन माहिती ──
        Text(
          'ड) ${_n48BailableCtrl.text}',
          style: mrStyle.copyWith(fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 16),

        // ── इ) रिमांड हजर माहिती ──
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 6,
          children: [
            Text('इ) अटक व्यक्तीला दिनांक',
                style: mrStyle.copyWith(fontSize: 15)),
            _inlineBlank(
              controller: _n48RemandDayCtrl,
              style: mrStyle,
              width: 40,
            ),
            Text('/', style: mrStyle.copyWith(fontSize: 15)),
            _inlineBlank(
              controller: _n48RemandMonthCtrl,
              style: mrStyle,
              width: 40,
            ),
            Text('/२०', style: mrStyle.copyWith(fontSize: 15)),
            _inlineBlank(
              controller: _n48RemandYearCtrl,
              style: mrStyle,
              width: 45,
            ),
            Text(
              'रोजी मा.प्रथम वर्ग न्यायदंडाधिकारी यांचे समक्ष रिमांडसाठी हजर करण्यात येणार आहे.',
              style: mrStyle.copyWith(fontSize: 15, height: 1.5),
            ),
          ],
        ),
        const SizedBox(height: 36),

        // ── Signatures 2-Column Row ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _inlineBlank(
                  controller: _n48RelativeSigCtrl,
                  style: mrStyle,
                  width: 220,
                ),
                const SizedBox(height: 4),
                Text(
                  'नातेवाईकाची दिनांकीत सही',
                  style: mrStyle.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'कळावे,',
                  style: mrStyle.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _inlineBlank(
                  controller: _n48IoSigCtrl,
                  style: mrStyle,
                  width: 220,
                ),
                const SizedBox(height: 4),
                Text(
                  'तपासी अधिकारी/अंमलदार',
                  style: mrStyle.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mrStyle = GoogleFonts.notoSansDevanagari(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: Colors.black87,
    );

    final show47 = _shows(kNotice47);
    final show48 = _shows(kNotice48);

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        if (show47) _buildNotice47Page(mrStyle),
        if (show47 && show48) const SizedBox(height: 24),
        if (show48) _buildNotice48Page(mrStyle),
      ],
    );
  }
}
