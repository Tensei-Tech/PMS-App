import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bilingual_field.dart';
import 'form_paper_page.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';
import 'form_date_pickers.dart';

/// निल घरझडती पंचनामा (Nil House Search Panchanama)
class NilHouseSearchFormView extends StatefulWidget {
  final bool readOnly;
  final String? formSection;
  final String? pageRange;

  const NilHouseSearchFormView({
    super.key,
    this.readOnly = false,
    this.formSection,
    this.pageRange,
  });

  @override
  State<NilHouseSearchFormView> createState() => NilHouseSearchFormViewState();
}

class NilHouseSearchFormViewState extends State<NilHouseSearchFormView> {
  // Top right metadata
  final _psCtrl = TextEditingController();
  final _campCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _dateDayCtrl = TextEditingController();
  final _dateMonthCtrl = TextEditingController();
  final _dateYearCtrl = TextEditingController();

  String get _dateCombined {
    final d = _dateDayCtrl.text.trim();
    final m = _dateMonthCtrl.text.trim();
    final y = _dateYearCtrl.text.trim();
    if (d.isEmpty && m.isEmpty && y.isEmpty) {
      return _dateCtrl.text.trim();
    }
    final yFull = y.isNotEmpty ? (y.length == 2 ? '20$y' : y) : '';
    return '$d/$m/$yFull'.replaceAll(RegExp(r'/+$'), '');
  }

  // Panch names
  final _panch1Ctrl = TextEditingController();
  final _panch2Ctrl = TextEditingController();

  // Paragraph 1
  final _officerNameCtrl = TextEditingController();
  final _officerPsCtrl = TextEditingController();
  final _summonDateCtrl = TextEditingController();
  final _summonDateDayCtrl = TextEditingController();
  final _summonDateMonthCtrl = TextEditingController();
  final _summonDateYearCtrl = TextEditingController();

  String get _summonDateCombined {
    final d = _summonDateDayCtrl.text.trim();
    final m = _summonDateMonthCtrl.text.trim();
    final y = _summonDateYearCtrl.text.trim();
    if (d.isEmpty && m.isEmpty && y.isEmpty) {
      return _summonDateCtrl.text.trim();
    }
    final yFull = y.isNotEmpty ? (y.length == 2 ? '20$y' : y) : '';
    return '$d/$m/$yFull'.replaceAll(RegExp(r'/+$'), '');
  }

  final _mauzaCtrl = TextEditingController();
  final _firPsCtrl = TextEditingController();
  final _crimeNoCtrl = TextEditingController();
  final _crimeYearCtrl = TextEditingController();
  final _actSecCtrl = TextEditingController();
  final _accusedNameCtrl = TextEditingController();
  final _accusedTahCtrl = TextEditingController();
  final _accusedDistCtrl = TextEditingController();

  // Paragraph 2
  final _searchPlaceCtrl = TextEditingController();
  final _personFoundCtrl = TextEditingController();
  final _searchPremisesCtrl = TextEditingController();
  final _seizurePropertyCtrl = TextEditingController();

  // Paragraph 3 (Closing)
  final _panchDateCtrl = TextEditingController();
  final _panchDateDayCtrl = TextEditingController();
  final _panchDateMonthCtrl = TextEditingController();
  final _panchDateYearCtrl = TextEditingController();

  String get _panchDateCombined {
    final d = _panchDateDayCtrl.text.trim();
    final m = _panchDateMonthCtrl.text.trim();
    final y = _panchDateYearCtrl.text.trim();
    if (d.isEmpty && m.isEmpty && y.isEmpty) {
      return _panchDateCtrl.text.trim();
    }
    final yFull = y.isNotEmpty ? (y.length == 2 ? '20$y' : y) : '';
    return '$d/$m/$yFull'.replaceAll(RegExp(r'/+$'), '');
  }

  final _startTimeCtrl = TextEditingController();
  final _startTimeHoursCtrl = TextEditingController();
  final _startTimeMinutesCtrl = TextEditingController();

  String get _startTimeCombined {
    final h = _startTimeHoursCtrl.text.trim();
    final m = _startTimeMinutesCtrl.text.trim();
    if (h.isEmpty && m.isEmpty) return _startTimeCtrl.text.trim();
    return '$h/$m';
  }

  final _endTimeCtrl = TextEditingController();
  final _endTimeHoursCtrl = TextEditingController();
  final _endTimeMinutesCtrl = TextEditingController();

  String get _endTimeCombined {
    final h = _endTimeHoursCtrl.text.trim();
    final m = _endTimeMinutesCtrl.text.trim();
    if (h.isEmpty && m.isEmpty) return _endTimeCtrl.text.trim();
    return '$h/$m';
  }

  // Signatures
  final _ownerSigCtrl = TextEditingController();
  final _panch1SigCtrl = TextEditingController();
  final _panch2SigCtrl = TextEditingController();

  @override
  void dispose() {
    _psCtrl.dispose();
    _campCtrl.dispose();
    _dateCtrl.dispose();
    _dateDayCtrl.dispose();
    _dateMonthCtrl.dispose();
    _dateYearCtrl.dispose();
    _panch1Ctrl.dispose();
    _panch2Ctrl.dispose();
    _officerNameCtrl.dispose();
    _officerPsCtrl.dispose();
    _summonDateCtrl.dispose();
    _summonDateDayCtrl.dispose();
    _summonDateMonthCtrl.dispose();
    _summonDateYearCtrl.dispose();
    _mauzaCtrl.dispose();
    _firPsCtrl.dispose();
    _crimeNoCtrl.dispose();
    _crimeYearCtrl.dispose();
    _actSecCtrl.dispose();
    _accusedNameCtrl.dispose();
    _accusedTahCtrl.dispose();
    _accusedDistCtrl.dispose();
    _searchPlaceCtrl.dispose();
    _personFoundCtrl.dispose();
    _searchPremisesCtrl.dispose();
    _seizurePropertyCtrl.dispose();
    _panchDateCtrl.dispose();
    _panchDateDayCtrl.dispose();
    _panchDateMonthCtrl.dispose();
    _panchDateYearCtrl.dispose();
    _startTimeCtrl.dispose();
    _startTimeHoursCtrl.dispose();
    _startTimeMinutesCtrl.dispose();
    _endTimeCtrl.dispose();
    _endTimeHoursCtrl.dispose();
    _endTimeMinutesCtrl.dispose();
    _ownerSigCtrl.dispose();
    _panch1SigCtrl.dispose();
    _panch2SigCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> collectData() {
    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'ps': _psCtrl.text.trim(),
      'camp': _campCtrl.text.trim(),
      'date': _dateCombined,
      'dateDay': _dateDayCtrl.text.trim(),
      'dateMonth': _dateMonthCtrl.text.trim(),
      'dateYear': _dateYearCtrl.text.trim(),
      'panch1': _panch1Ctrl.text.trim(),
      'panch2': _panch2Ctrl.text.trim(),
      'officerName': _officerNameCtrl.text.trim(),
      'officerPs': _officerPsCtrl.text.trim(),
      'summonDate': _summonDateCombined,
      'summonDateDay': _summonDateDayCtrl.text.trim(),
      'summonDateMonth': _summonDateMonthCtrl.text.trim(),
      'summonDateYear': _summonDateYearCtrl.text.trim(),
      'mauza': _mauzaCtrl.text.trim(),
      'firPs': _firPsCtrl.text.trim(),
      'crimeNo': _crimeNoCtrl.text.trim(),
      'crimeYear': _crimeYearCtrl.text.trim(),
      'actSec': _actSecCtrl.text.trim(),
      'accusedName': _accusedNameCtrl.text.trim(),
      'accusedTah': _accusedTahCtrl.text.trim(),
      'accusedDist': _accusedDistCtrl.text.trim(),
      'searchPlace': _searchPlaceCtrl.text.trim(),
      'personFound': _personFoundCtrl.text.trim(),
      'searchPremises': _searchPremisesCtrl.text.trim(),
      'seizureProperty': _seizurePropertyCtrl.text.trim(),
      'panchDate': _panchDateCombined,
      'panchDateDay': _panchDateDayCtrl.text.trim(),
      'panchDateMonth': _panchDateMonthCtrl.text.trim(),
      'panchDateYear': _panchDateYearCtrl.text.trim(),
      'startTime': _startTimeCombined,
      'startTimeHours': _startTimeHoursCtrl.text.trim(),
      'startTimeMinutes': _startTimeMinutesCtrl.text.trim(),
      'endTime': _endTimeCombined,
      'endTimeHours': _endTimeHoursCtrl.text.trim(),
      'endTimeMinutes': _endTimeMinutesCtrl.text.trim(),
      'ownerSig': _ownerSigCtrl.text.trim(),
      'panch1Sig': _panch1SigCtrl.text.trim(),
      'panch2Sig': _panch2SigCtrl.text.trim(),
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    _psCtrl.text = data['ps']?.toString() ?? '';
    _campCtrl.text = data['camp']?.toString() ?? '';
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

    _panch1Ctrl.text = data['panch1']?.toString() ?? '';
    _panch2Ctrl.text = data['panch2']?.toString() ?? '';
    _officerNameCtrl.text = data['officerName']?.toString() ?? '';
    _officerPsCtrl.text = data['officerPs']?.toString() ?? '';
    _summonDateCtrl.text = data['summonDate']?.toString() ?? '';
    _summonDateDayCtrl.text = data['summonDateDay']?.toString() ?? '';
    _summonDateMonthCtrl.text = data['summonDateMonth']?.toString() ?? '';
    _summonDateYearCtrl.text = data['summonDateYear']?.toString() ?? '';
    if (_summonDateDayCtrl.text.isEmpty && _summonDateCtrl.text.isNotEmpty) {
      final parts = _summonDateCtrl.text.split(RegExp(r'[/.-]'));
      if (parts.length >= 3) {
        _summonDateDayCtrl.text = parts[0].trim();
        _summonDateMonthCtrl.text = parts[1].trim();
        var yr = parts[2].trim();
        if (yr.startsWith('20') && yr.length == 4) yr = yr.substring(2);
        _summonDateYearCtrl.text = yr;
      }
    }

    _mauzaCtrl.text = data['mauza']?.toString() ?? '';
    _firPsCtrl.text = data['firPs']?.toString() ?? '';
    _crimeNoCtrl.text = data['crimeNo']?.toString() ?? '';
    _crimeYearCtrl.text = data['crimeYear']?.toString() ?? '';
    _actSecCtrl.text = data['actSec']?.toString() ?? '';
    _accusedNameCtrl.text = data['accusedName']?.toString() ?? '';
    _accusedTahCtrl.text = data['accusedTah']?.toString() ?? '';
    _accusedDistCtrl.text = data['accusedDist']?.toString() ?? '';
    _searchPlaceCtrl.text = data['searchPlace']?.toString() ?? '';
    _personFoundCtrl.text = data['personFound']?.toString() ?? '';
    _searchPremisesCtrl.text = data['searchPremises']?.toString() ?? '';
    _seizurePropertyCtrl.text = data['seizureProperty']?.toString() ?? '';

    _panchDateCtrl.text = data['panchDate']?.toString() ?? '';
    _panchDateDayCtrl.text = data['panchDateDay']?.toString() ?? '';
    _panchDateMonthCtrl.text = data['panchDateMonth']?.toString() ?? '';
    _panchDateYearCtrl.text = data['panchDateYear']?.toString() ?? '';
    if (_panchDateDayCtrl.text.isEmpty && _panchDateCtrl.text.isNotEmpty) {
      final parts = _panchDateCtrl.text.split(RegExp(r'[/.-]'));
      if (parts.length >= 3) {
        _panchDateDayCtrl.text = parts[0].trim();
        _panchDateMonthCtrl.text = parts[1].trim();
        var yr = parts[2].trim();
        if (yr.startsWith('20') && yr.length == 4) yr = yr.substring(2);
        _panchDateYearCtrl.text = yr;
      }
    }

    _startTimeCtrl.text = data['startTime']?.toString() ?? '';
    _startTimeHoursCtrl.text = data['startTimeHours']?.toString() ?? '';
    _startTimeMinutesCtrl.text = data['startTimeMinutes']?.toString() ?? '';
    if (_startTimeHoursCtrl.text.isEmpty && _startTimeCtrl.text.isNotEmpty) {
      final parts = _startTimeCtrl.text.split(RegExp(r'[/.:]'));
      if (parts.isNotEmpty) _startTimeHoursCtrl.text = parts[0].trim();
      if (parts.length > 1) _startTimeMinutesCtrl.text = parts[1].trim();
    }

    _endTimeCtrl.text = data['endTime']?.toString() ?? '';
    _endTimeHoursCtrl.text = data['endTimeHours']?.toString() ?? '';
    _endTimeMinutesCtrl.text = data['endTimeMinutes']?.toString() ?? '';
    if (_endTimeHoursCtrl.text.isEmpty && _endTimeCtrl.text.isNotEmpty) {
      final parts = _endTimeCtrl.text.split(RegExp(r'[/.:]'));
      if (parts.isNotEmpty) _endTimeHoursCtrl.text = parts[0].trim();
      if (parts.length > 1) _endTimeMinutesCtrl.text = parts[1].trim();
    }

    _ownerSigCtrl.text = data['ownerSig']?.toString() ?? '';
    _panch1SigCtrl.text = data['panch1Sig']?.toString() ?? '';
    _panch2SigCtrl.text = data['panch2Sig']?.toString() ?? '';
    if (mounted) setState(() {});
  }

  Widget _wrappingUnderlineInput({
    required TextEditingController controller,
    required TextStyle style,
    double? minWidth,
    double? maxWidth,
    String? hintText,
  }) {
    final effectiveMin = minWidth ?? 100.0;
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
              : (measured > 800.0 ? 800.0 : measured);
        }

        return RepaintBoundary(
          child: SizedBox(
            width: calcWidth,
            child: TextFormField(
              controller: controller,
              readOnly: widget.readOnly,
              maxLines: 1,
              keyboardType: TextInputType.text,
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

  Widget _inlineBlank({
    required TextEditingController controller,
    required TextStyle style,
    double? width,
    String? hintText,
  }) {
    return SizedBox(
      width: width,
      child: BilingualSimpleUnderlineInput(
        controller: controller,
        serifStyle: style,
        hintText: hintText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final serif = FormTypography.serifStyle();
    final marathi = FormTypography.marathiLabelStyle();

    final bodyTextStyle = marathi.copyWith(
      fontSize: 13,
      height: 2.0,
      color: Colors.black87,
    );
    final headerLabelStyle = marathi.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    );

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        FormPaperPage(
          formLabel: widget.pageRange,
          children: [
            const SizedBox(height: 8),

            // ── TOP RIGHT POLICE STATION / CAMP / DATE ──
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 380,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('पोलीस स्टेशन  :', style: headerLabelStyle),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _policeStationField(
                            controller: _psCtrl,
                            style: serif,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('कॅम्प            :', style: headerLabelStyle),
                        const SizedBox(width: 8),
                        _wrappingUnderlineInput(
                          controller: _campCtrl,
                          style: serif,
                          minWidth: 140,
                          maxWidth: 220,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('दिनांक          :-', style: headerLabelStyle),
                        const SizedBox(width: 6),
                        formDatePickerField(
                          context,
                          controller: _dateCtrl,
                          width: 140,
                          dayCtrl: _dateDayCtrl,
                          monthCtrl: _dateMonthCtrl,
                          yearCtrl: _dateYearCtrl,
                          readOnly: widget.readOnly,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── TITLE ──
            Center(
              child: Text(
                'निल घरझडती पंचनामा',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── PANCH NAMES ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'पंच नांव    :-',
                  style: headerLabelStyle,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('१)', style: headerLabelStyle),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _wrappingUnderlineInput(
                              controller: _panch1Ctrl,
                              style: serif,
                              minWidth: 200,
                              maxWidth: 650,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('२)', style: headerLabelStyle),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _wrappingUnderlineInput(
                              controller: _panch2Ctrl,
                              style: serif,
                              minWidth: 200,
                              maxWidth: 650,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── PARAGRAPH 1 ──
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 10,
              children: [
                Text('       आम्ही ', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _officerNameCtrl,
                  style: serif,
                  minWidth: 200,
                  maxWidth: 350,
                ),
                Text('पोलीस स्टेशन ', style: bodyTextStyle),
                _policeStationField(
                  controller: _officerPsCtrl,
                  style: serif,
                  minWidth: 140,
                  maxWidth: 280,
                ),
                Text('यांनी दिनांक ', style: bodyTextStyle),
                formDatePickerField(
                  context,
                  controller: _summonDateCtrl,
                  width: 140,
                  dayCtrl: _summonDateDayCtrl,
                  monthCtrl: _summonDateMonthCtrl,
                  yearCtrl: _summonDateYearCtrl,
                  readOnly: widget.readOnly,
                ),
                Text('रोजी वरील नमुद पंचांना मौजा', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _mauzaCtrl,
                  style: serif,
                  minWidth: 140,
                  maxWidth: 250,
                ),
                Text('येथे बोलावुन कळविले की, पो.स्टे.', style: bodyTextStyle),
                _policeStationField(
                  controller: _firPsCtrl,
                  style: serif,
                  minWidth: 140,
                  maxWidth: 280,
                ),
                Text('येथे अप.क्र.', style: bodyTextStyle),
                _inlineBlank(
                  controller: _crimeNoCtrl,
                  style: serif,
                  width: 90,
                ),
                Text('/ २०', style: bodyTextStyle),
                _inlineBlank(
                  controller: _crimeYearCtrl,
                  style: serif,
                  width: 44,
                  hintText: 'YY',
                ),
                Text('कलम', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _actSecCtrl,
                  style: serif,
                  minWidth: 140,
                  maxWidth: 250,
                ),
                Text(
                  'भा.न्या.सं २०२३ अन्वये दाखल असुन चोरीच्या मालाबाबत/ अवैध प्रोहिबीशन बाबत सदर गुन्ह्यामध्ये आरोपी नामे',
                  style: bodyTextStyle,
                ),
                _wrappingUnderlineInput(
                  controller: _accusedNameCtrl,
                  style: serif,
                  minWidth: 200,
                  maxWidth: 350,
                ),
                Text('ता.-', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _accusedTahCtrl,
                  style: serif,
                  minWidth: 90,
                  maxWidth: 180,
                ),
                Text('जि', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _accusedDistCtrl,
                  style: serif,
                  minWidth: 90,
                  maxWidth: 180,
                ),
                Text(
                  'याचे घराचे झडती घेणे असल्याने आपण पंच म्हणुन हजर राहावे. असे पंचाना कळवुन नमुद पंच सहमत होवून हजर आले.',
                  style: bodyTextStyle,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── PARAGRAPH 2 ──
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 10,
              children: [
                Text('       आम्ही स्वतः सोबत पंच व स्टाफसह ',
                    style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _searchPlaceCtrl,
                  style: serif,
                  minWidth: 200,
                  maxWidth: 350,
                ),
                Text('त्याचे घरी जावुन आवाज दिला असता त्याचे घरी ',
                    style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _personFoundCtrl,
                  style: serif,
                  minWidth: 180,
                  maxWidth: 300,
                ),
                Text(
                  'हा हजर मिळाला त्याचे घरी येण्याचा उद्देश समजवून सांगुन व त्याचा नाव, गावाची खात्री करून त्याचे ',
                  style: bodyTextStyle,
                ),
                _wrappingUnderlineInput(
                  controller: _searchPremisesCtrl,
                  style: serif,
                  minWidth: 200,
                  maxWidth: 350,
                ),
                Text(
                  'कायदेशीररित्या झडती घेतली असता त्याचे येथे सदर गुन्ह्यातील चोरी गेलेला माल/ मादक द्रव्य/ इतर संशयीत माल ',
                  style: bodyTextStyle,
                ),
                _wrappingUnderlineInput(
                  controller: _seizurePropertyCtrl,
                  style: serif,
                  minWidth: 220,
                  maxWidth: 400,
                ),
                Text(
                  'मिळुन आला आहे/ नाही. घर झडती दरम्यान घरामधील सामानाचे नुकसान किंवा घरातील लोकांच्या धार्मीक भावना दुखाविण्या सारखे/ धर्मा विरूध्द कोणतेही कृत्य करण्यात आले नाही.',
                  style: bodyTextStyle,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── PARAGRAPH 3 (CLOSING) ──
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 10,
              children: [
                Text('       निल घरझडती पंचनामा आज दिनांक ',
                    style: bodyTextStyle),
                formDatePickerField(
                  context,
                  controller: _panchDateCtrl,
                  width: 140,
                  dayCtrl: _panchDateDayCtrl,
                  monthCtrl: _panchDateMonthCtrl,
                  yearCtrl: _panchDateYearCtrl,
                  readOnly: widget.readOnly,
                ),
                Text('चे ', style: bodyTextStyle),
                formTimePickerField(
                  context,
                  controller: _startTimeCtrl,
                  width: 90,
                  readOnly: widget.readOnly,
                ),
                Text('वा सुरू करून ', style: bodyTextStyle),
                formTimePickerField(
                  context,
                  controller: _endTimeCtrl,
                  width: 90,
                  readOnly: widget.readOnly,
                ),
                Text(
                  'वा मोक्यावर संपविला. पंचनामा पंचाना वाचुन दाखविला/ वाचुन पाहिला, बरोबर असल्याचे खात्री करून त्यावर त्यांनी सह्या केल्या.',
                  style: bodyTextStyle,
                ),
              ],
            ),
            const SizedBox(height: 48),

            // ── SIGNATURES ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ज्याचे घराचे झडती घेतली त्याची सही/अंगठा',
                        style: headerLabelStyle,
                      ),
                      const SizedBox(height: 36),
                      SizedBox(
                        width: 220,
                        child: BilingualSimpleUnderlineInput(
                          controller: _ownerSigCtrl,
                          serifStyle: serif,
                          hintText: 'सही / अंगठा',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'समक्ष',
                        style: headerLabelStyle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'पंच सही',
                        style: headerLabelStyle,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text('१)', style: bodyTextStyle),
                          const SizedBox(width: 6),
                          Expanded(
                            child: BilingualSimpleUnderlineInput(
                              controller: _panch1SigCtrl,
                              serifStyle: serif,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text('२)', style: bodyTextStyle),
                          const SizedBox(width: 6),
                          Expanded(
                            child: BilingualSimpleUnderlineInput(
                              controller: _panch2SigCtrl,
                              serifStyle: serif,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),

            // ── BOTTOM RIGHT M.R.W ──
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'M.R.W',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
