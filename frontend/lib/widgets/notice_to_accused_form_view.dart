import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'form_paper_page.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';
import 'form_date_pickers.dart';

/// -:: आरोपीस सुचनापत्र ::- (भारतीय नागरी सुरक्षा संहिता २०२३ कलम ४७ (१)(२))
class NoticeToAccusedFormView extends StatefulWidget {
  final bool readOnly;
  final String? formSection;
  final String? pageRange;

  const NoticeToAccusedFormView({
    super.key,
    this.readOnly = false,
    this.formSection,
    this.pageRange,
  });

  @override
  State<NoticeToAccusedFormView> createState() =>
      NoticeToAccusedFormViewState();
}

class NoticeToAccusedFormViewState extends State<NoticeToAccusedFormView> {
  // ── TOP HEADER ──
  final _psCtrl = TextEditingController();
  final _dateDayCtrl = TextEditingController();
  final _dateMonthCtrl = TextEditingController();
  final _dateYearCtrl = TextEditingController(text: '२५');
  final _dateCtrl = TextEditingController();

  String get _dateCombined {
    if (_dateCtrl.text.trim().isNotEmpty) {
      return _dateCtrl.text.trim();
    }
    final d = _dateDayCtrl.text.trim();
    final m = _dateMonthCtrl.text.trim();
    final y = _dateYearCtrl.text.trim();
    if (d.isEmpty && m.isEmpty && y.isEmpty) {
      return '';
    }
    final yFull = y.isNotEmpty ? (y.length == 2 ? '20$y' : y) : '';
    return '$d/$m/$yFull'.replaceAll(RegExp(r'/+$'), '');
  }

  // ── ACCUSED DETAILS ──
  final _accusedNameLine1Ctrl = TextEditingController();
  final _accusedNameLine2Ctrl = TextEditingController();
  final _mobileNoCtrl = TextEditingController();
  final _aadhaarNoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // ── PARAGRAPH 1 ──
  final _firPsCtrl = TextEditingController();
  final _firDistCtrl = TextEditingController();
  final _crimeNoCtrl = TextEditingController();
  final _crimeYearCtrl = TextEditingController(text: '२५');
  final _actSecCtrl = TextEditingController();
  final _actSecLine2Ctrl = TextEditingController();
  final _coActSecCtrl = TextEditingController();
  final _coActSecLine2Ctrl = TextEditingController();

  final _firDayCtrl = TextEditingController();
  final _firMonthCtrl = TextEditingController();
  final _firYearCtrl = TextEditingController(text: '२५');
  final _firDateCtrl = TextEditingController();

  String get _firDateCombined {
    if (_firDateCtrl.text.trim().isNotEmpty) {
      return _firDateCtrl.text.trim();
    }
    final d = _firDayCtrl.text.trim();
    final m = _firMonthCtrl.text.trim();
    final y = _firYearCtrl.text.trim();
    if (d.isEmpty && m.isEmpty && y.isEmpty) {
      return '';
    }
    final yFull = y.isNotEmpty ? (y.length == 2 ? '20$y' : y) : '';
    return '$d/$m/$yFull'.replaceAll(RegExp(r'/+$'), '');
  }

  // ── PARAGRAPH 2 ──
  final _bailTypeCtrl = TextEditingController(text: 'अजमीनपात्र/ जामीनपात्र');
  final _relativeDetailsLine1Ctrl = TextEditingController();
  final _relativeDetailsLine2Ctrl = TextEditingController();

  // ── SIGNATURES ──
  final _accusedSigCtrl = TextEditingController();
  final _ioNameSigCtrl = TextEditingController();

  @override
  void dispose() {
    _psCtrl.dispose();
    _dateDayCtrl.dispose();
    _dateMonthCtrl.dispose();
    _dateYearCtrl.dispose();
    _dateCtrl.dispose();

    _accusedNameLine1Ctrl.dispose();
    _accusedNameLine2Ctrl.dispose();
    _mobileNoCtrl.dispose();
    _aadhaarNoCtrl.dispose();
    _emailCtrl.dispose();

    _firPsCtrl.dispose();
    _firDistCtrl.dispose();
    _crimeNoCtrl.dispose();
    _crimeYearCtrl.dispose();
    _actSecCtrl.dispose();
    _actSecLine2Ctrl.dispose();
    _coActSecCtrl.dispose();
    _coActSecLine2Ctrl.dispose();

    _firDayCtrl.dispose();
    _firMonthCtrl.dispose();
    _firYearCtrl.dispose();
    _firDateCtrl.dispose();

    _bailTypeCtrl.dispose();
    _relativeDetailsLine1Ctrl.dispose();
    _relativeDetailsLine2Ctrl.dispose();

    _accusedSigCtrl.dispose();
    _ioNameSigCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> collectData() {
    final accusedCombined = [
      _accusedNameLine1Ctrl.text.trim(),
      _accusedNameLine2Ctrl.text.trim(),
    ].where((e) => e.isNotEmpty).join('\n');

    final actSecCombined = [
      _actSecCtrl.text.trim(),
      _actSecLine2Ctrl.text.trim(),
    ].where((e) => e.isNotEmpty).join(' ');

    final coActSecCombined = [
      _coActSecCtrl.text.trim(),
      _coActSecLine2Ctrl.text.trim(),
    ].where((e) => e.isNotEmpty).join(' ');

    final relativeCombined = [
      _relativeDetailsLine1Ctrl.text.trim(),
      _relativeDetailsLine2Ctrl.text.trim(),
    ].where((e) => e.isNotEmpty).join('\n');

    final crCombined = _crimeYearCtrl.text.trim().isNotEmpty
        ? '${_crimeNoCtrl.text.trim()}/${_crimeYearCtrl.text.trim()}'
        : _crimeNoCtrl.text.trim();

    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'policeStation': _psCtrl.text.trim(),
      'date': _dateCombined,
      'dateDay': _dateDayCtrl.text.trim(),
      'dateMonth': _dateMonthCtrl.text.trim(),
      'dateYear': _dateYearCtrl.text.trim(),
      'accusedName': _accusedNameLine1Ctrl.text.trim(),
      'accusedNameLine2': _accusedNameLine2Ctrl.text.trim(),
      'accusedNameAddress': accusedCombined,
      'mobileNo': _mobileNoCtrl.text.trim(),
      'aadhaarNo': _aadhaarNoCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'firPs': _firPsCtrl.text.trim(),
      'firDist': _firDistCtrl.text.trim(),
      'crimeNo': crCombined,
      'crimeNumberOnly': _crimeNoCtrl.text.trim(),
      'crimeYear': _crimeYearCtrl.text.trim(),
      'actSec': actSecCombined,
      'actSecLine1': _actSecCtrl.text.trim(),
      'actSecLine2': _actSecLine2Ctrl.text.trim(),
      'coActSec': coActSecCombined,
      'coActSecLine1': _coActSecCtrl.text.trim(),
      'coActSecLine2': _coActSecLine2Ctrl.text.trim(),
      'firDate': _firDateCombined,
      'firDay': _firDayCtrl.text.trim(),
      'firMonth': _firMonthCtrl.text.trim(),
      'firYear': _firYearCtrl.text.trim(),
      'bailType': _bailTypeCtrl.text.trim(),
      'relativeDetails': relativeCombined,
      'relativeDetailsLine1': _relativeDetailsLine1Ctrl.text.trim(),
      'relativeDetailsLine2': _relativeDetailsLine2Ctrl.text.trim(),
      'accusedSig': _accusedSigCtrl.text.trim(),
      'ioNameSig': _ioNameSigCtrl.text.trim(),
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    setState(() {
      _psCtrl.text =
          data['policeStation']?.toString() ?? data['ps']?.toString() ?? '';

      _dateCtrl.text = data['date']?.toString() ?? '';
      _dateDayCtrl.text = data['dateDay']?.toString() ?? '';
      _dateMonthCtrl.text = data['dateMonth']?.toString() ?? '';
      _dateYearCtrl.text = data['dateYear']?.toString() ?? '';
      if (_dateDayCtrl.text.isEmpty && _dateCtrl.text.isNotEmpty) {
        final parts = _dateCtrl.text.split(RegExp(r'[/.-]'));
        if (parts.length >= 3) {
          _dateDayCtrl.text = parts[0].trim();
          _dateMonthCtrl.text = parts[1].trim();
          var yr = parts[2].trim();
          if (yr.startsWith('20') && yr.length == 4) yr = yr.substring(2);
          _dateYearCtrl.text = yr;
        }
      }

      final rawAccused = data['accusedNameAddress']?.toString() ??
          data['accusedName']?.toString() ??
          '';
      if (rawAccused.contains('\n')) {
        final p = rawAccused.split('\n');
        _accusedNameLine1Ctrl.text = p[0].trim();
        _accusedNameLine2Ctrl.text = p.sublist(1).join(' ').trim();
      } else {
        _accusedNameLine1Ctrl.text =
            data['accusedName']?.toString() ?? rawAccused;
        _accusedNameLine2Ctrl.text = data['accusedNameLine2']?.toString() ?? '';
      }

      _mobileNoCtrl.text = data['mobileNo']?.toString() ?? '';
      _aadhaarNoCtrl.text = data['aadhaarNo']?.toString() ?? '';
      _emailCtrl.text = data['email']?.toString() ?? '';

      _firPsCtrl.text = data['firPs']?.toString() ?? '';
      _firDistCtrl.text = data['firDist']?.toString() ?? '';

      final rawCr = data['crimeNo']?.toString() ?? '';
      if (rawCr.contains('/')) {
        final p = rawCr.split('/');
        _crimeNoCtrl.text = p[0].trim();
        var y = p[1].trim();
        if (y.startsWith('20') && y.length == 4) y = y.substring(2);
        _crimeYearCtrl.text = y;
      } else {
        _crimeNoCtrl.text = data['crimeNumberOnly']?.toString() ?? rawCr;
        _crimeYearCtrl.text = data['crimeYear']?.toString() ?? '२५';
      }

      _actSecCtrl.text =
          data['actSecLine1']?.toString() ?? data['actSec']?.toString() ?? '';
      _actSecLine2Ctrl.text = data['actSecLine2']?.toString() ?? '';

      _coActSecCtrl.text = data['coActSecLine1']?.toString() ??
          data['coActSec']?.toString() ??
          '';
      _coActSecLine2Ctrl.text = data['coActSecLine2']?.toString() ?? '';

      _firDateCtrl.text = data['firDate']?.toString() ?? '';
      _firDayCtrl.text = data['firDay']?.toString() ?? '';
      _firMonthCtrl.text = data['firMonth']?.toString() ?? '';
      _firYearCtrl.text = data['firYear']?.toString() ?? '';
      if (_firDayCtrl.text.isEmpty && _firDateCtrl.text.isNotEmpty) {
        final parts = _firDateCtrl.text.split(RegExp(r'[/.-]'));
        if (parts.length >= 3) {
          _firDayCtrl.text = parts[0].trim();
          _firMonthCtrl.text = parts[1].trim();
          var yr = parts[2].trim();
          if (yr.startsWith('20') && yr.length == 4) yr = yr.substring(2);
          _firYearCtrl.text = yr;
        }
      }

      _bailTypeCtrl.text =
          data['bailType']?.toString() ?? 'अजमीनपात्र/ जामीनपात्र';

      final rawRel = data['relativeDetails']?.toString() ?? '';
      if (rawRel.contains('\n')) {
        final p = rawRel.split('\n');
        _relativeDetailsLine1Ctrl.text = p[0].trim();
        _relativeDetailsLine2Ctrl.text = p.sublist(1).join(' ').trim();
      } else {
        _relativeDetailsLine1Ctrl.text =
            data['relativeDetailsLine1']?.toString() ?? rawRel;
        _relativeDetailsLine2Ctrl.text =
            data['relativeDetailsLine2']?.toString() ?? '';
      }

      _accusedSigCtrl.text = data['accusedSig']?.toString() ?? '';
      _ioNameSigCtrl.text = data['ioNameSig']?.toString() ?? '';
    });
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
                (!hasFiniteWidth || (text.length * 12.0 + 12.0 > availableWidth))) {
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
                  maxLines: 1,
                  scrollPhysics: const ClampingScrollPhysics(),
                  style: style.copyWith(
                    fontSize: effectiveFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    hintText: hintText,
                    hintStyle: style.copyWith(
                      color: Colors.grey.shade400,
                      fontSize: effectiveFontSize,
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

    final bodyTextStyle = marathi.copyWith(
      fontSize: 14.5,
      height: 2.2,
      color: Colors.black87,
    );
    final headerLabelStyle = marathi.copyWith(
      fontSize: 14.5,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    );

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        FormPaperPage(
          minHeight: 1180,
          formLabel: widget.pageRange ?? 'आरोपीस सुचनापत्र',
          children: [
            const SizedBox(height: 12),

            // ── TOP RIGHT POLICE STATION & DATE ──
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 320,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('पोलीस स्टेशन', style: headerLabelStyle),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _policeStationField(
                            controller: _psCtrl,
                            style: serif,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('दिनांक :', style: headerLabelStyle),
                        const SizedBox(width: 6),
                        formDatePickerField(
                          context,
                          controller: _dateCtrl,
                          dayCtrl: _dateDayCtrl,
                          monthCtrl: _dateMonthCtrl,
                          yearCtrl: _dateYearCtrl,
                          width: 140,
                          readOnly: widget.readOnly,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── TITLE ──
            Center(
              child: Column(
                children: [
                  Text(
                    '-:: आरोपीस सुचनापत्र ::-',
                    style: GoogleFonts.poppins(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '(भारतीय नागरी सुरक्षा संहिता २०२३ कलम ४७ (१)(२))',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // ── ACCUSED DETAILS ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 60,
                  child: Text('नांव :-', style: headerLabelStyle),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _wrappingUnderlineInput(
                        controller: _accusedNameLine1Ctrl,
                        style: serif,
                        minWidth: 260,
                        maxWidth: 700,
                        hintText: 'नाव व पत्ता ओळ १',
                      ),
                      const SizedBox(height: 10),
                      _wrappingUnderlineInput(
                        controller: _accusedNameLine2Ctrl,
                        style: serif,
                        minWidth: 260,
                        maxWidth: 700,
                        hintText: 'ओळ २',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Mobile & Aadhaar
            Row(
              children: [
                Text('मो.नं.:-', style: headerLabelStyle),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: _wrappingUnderlineInput(
                    controller: _mobileNoCtrl,
                    style: serif,
                    minWidth: 120,
                    maxWidth: 250,
                  ),
                ),
                const SizedBox(width: 24),
                Text('आधार क्र :-', style: headerLabelStyle),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: _wrappingUnderlineInput(
                    controller: _aadhaarNoCtrl,
                    style: serif,
                    minWidth: 120,
                    maxWidth: 250,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Email
            Row(
              children: [
                Text('ईमेल :-', style: headerLabelStyle),
                const SizedBox(width: 8),
                Expanded(
                  child: _wrappingUnderlineInput(
                    controller: _emailCtrl,
                    style: serif,
                    minWidth: 200,
                    maxWidth: 450,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),

            // ── PARAGRAPH 1 ──
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 12,
              children: [
                Text(
                  '        आपणास याद्वारे सुचीत करण्यात येते की,आपणा विरूध्द पोलीस स्टेशन',
                  style: bodyTextStyle,
                ),
                _policeStationField(
                  controller: _firPsCtrl,
                  style: serif,
                  minWidth: 140,
                  maxWidth: 280,
                ),
                Text('जिल्हा', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _firDistCtrl,
                  style: serif,
                  minWidth: 90,
                  maxWidth: 180,
                ),
                Text('येथे अपराध क्रमांक', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _crimeNoCtrl,
                  style: serif,
                  minWidth: 80,
                  maxWidth: 140,
                  hintText: '............',
                ),
                Text('/ २०', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _crimeYearCtrl,
                  style: serif,
                  minWidth: 40,
                  maxWidth: 80,
                  hintText: 'YY',
                ),
                Text('कलम', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _actSecCtrl,
                  style: serif,
                  minWidth: 180,
                  maxWidth: 350,
                ),
                _wrappingUnderlineInput(
                  controller: _actSecLine2Ctrl,
                  style: serif,
                  minWidth: 160,
                  maxWidth: 300,
                ),
                Text('भा.न्या.संहिता २०२३ व सह कलम', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _coActSecCtrl,
                  style: serif,
                  minWidth: 180,
                  maxWidth: 300,
                ),
                _wrappingUnderlineInput(
                  controller: _coActSecLine2Ctrl,
                  style: serif,
                  minWidth: 160,
                  maxWidth: 300,
                ),
                Text('प्रमाणे दिनांक ', style: bodyTextStyle),
                formDatePickerField(
                  context,
                  controller: _firDateCtrl,
                  dayCtrl: _firDayCtrl,
                  monthCtrl: _firMonthCtrl,
                  yearCtrl: _firYearCtrl,
                  width: 140,
                  readOnly: widget.readOnly,
                ),
                const SizedBox(width: 4),
                Text(
                  'गुन्हा दाखल असुन सदर गुन्ह्याचा तपास आम्ही स्वतः करत आहोत. सदर गुन्ह्याच्या तपासकामी आपणास अटक करण्यात येत आहे.',
                  style: bodyTextStyle,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── PARAGRAPH 2 ──
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 12,
              children: [
                Text('        सदर गुन्हा दखलपात्र असुन', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _bailTypeCtrl,
                  style: serif,
                  minWidth: 160,
                  maxWidth: 260,
                ),
                Text(
                  'आहे. आपल्या अटकेबाबतची माहित भारतीय नागरीक सुरक्षा संहिता २०२३ कलम (४८) प्रमाणे आपले नातेवाईक/ मित्र.....',
                  style: bodyTextStyle,
                ),
                _wrappingUnderlineInput(
                  controller: _relativeDetailsLine1Ctrl,
                  style: serif,
                  minWidth: 260,
                  maxWidth: 700,
                  hintText: 'नातेवाईक नांव, पत्ता व मो.नं.',
                ),
                _wrappingUnderlineInput(
                  controller: _relativeDetailsLine2Ctrl,
                  style: serif,
                  minWidth: 260,
                  maxWidth: 700,
                ),
                Text(
                  'यांना समक्ष/फोनद्वारे देण्यात आली असुन अटक पंचनाम्यावर त्यांची स्वाक्षरी घेण्यात आली आहे.',
                  style: bodyTextStyle,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── PARAGRAPH 3 (Closing Line) ──
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Text(
                'करीता आपणास सुचनापत्र देण्यात येत आहे.',
                style: bodyTextStyle,
              ),
            ),
            const SizedBox(height: 64),

            // ── SIGNATURES ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 220,
                  child: Column(
                    children: [
                      Text('आरोपीची स्वाक्षरी', style: headerLabelStyle),
                      const SizedBox(height: 10),
                      _wrappingUnderlineInput(
                        controller: _accusedSigCtrl,
                        style: serif,
                        minWidth: 180,
                        maxWidth: 220,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 270,
                  child: Column(
                    children: [
                      Text('तपासी अधिकारी नांव व सही', style: headerLabelStyle),
                      const SizedBox(height: 10),
                      _wrappingUnderlineInput(
                        controller: _ioNameSigCtrl,
                        style: serif,
                        minWidth: 200,
                        maxWidth: 270,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),

            // ── MRW FOOTER ──
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'M.R.W',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
