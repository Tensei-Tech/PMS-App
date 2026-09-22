import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'form_paper_page.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';
import 'form_date_pickers.dart';

/// —:: पंच सुचनापत्र ::— (कलम १७९ भारतीय नागरीक सुरक्षा संहिता २०२३ अन्वये)
/// Form 1: घटनास्थळाचा / जप्ती पंचनामा सुचनापत्र (गुन्हा/मर्ग/अप)
/// Form 2: दारूबाबत प्रोहिबीशन रेड सुचनापत्र
class BnssPanchNoticeFormView extends StatefulWidget {
  final bool readOnly;
  final String? formSection;
  final String? pageRange;
  final String? initialNoticeType;

  const BnssPanchNoticeFormView({
    super.key,
    this.readOnly = false,
    this.formSection,
    this.pageRange,
    this.initialNoticeType,
  });

  @override
  State<BnssPanchNoticeFormView> createState() =>
      BnssPanchNoticeFormViewState();
}

class BnssPanchNoticeFormViewState extends State<BnssPanchNoticeFormView> {
  // ══════════════════════════════════════════════════════════
  // ── FORM 1 CONTROLLERS (घटनास्थळ / जप्ती पंचनामा) ──
  // ══════════════════════════════════════════════════════════
  final _p1PsCtrl = TextEditingController();
  final _p1DateCtrl = TextEditingController();
  final _p1DateDayCtrl = TextEditingController();
  final _p1DateMonthCtrl = TextEditingController();
  final _p1DateYearCtrl = TextEditingController();

  String get _p1DateCombined {
    if (_p1DateCtrl.text.trim().isNotEmpty) {
      return _p1DateCtrl.text.trim();
    }
    final d = _p1DateDayCtrl.text.trim();
    final m = _p1DateMonthCtrl.text.trim();
    final y = _p1DateYearCtrl.text.trim();
    if (d.isEmpty && m.isEmpty && y.isEmpty) {
      return '';
    }
    final yFull = y.isNotEmpty ? (y.length == 2 ? '20$y' : y) : '';
    return '$d/$m/$yFull'.replaceAll(RegExp(r'/+$'), '');
  }

  Widget _wrappingUnderlineInput({
    required TextEditingController controller,
    double minWidth = 100,
    double maxWidth = 350,
    String? hintText,
    TextInputType? keyboardType,
  }) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final text =
            controller.text.isEmpty ? (hintText ?? '') : controller.text;
        final style = FormTypography.serifStyle().copyWith(fontSize: 13);
        final tp = TextPainter(
          text: TextSpan(
            text: text,
            style: style,
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();

        final measured = tp.width + 20.0;
        final calcWidth = measured < minWidth
            ? minWidth
            : (measured > 800.0 ? 800.0 : measured);

        return SizedBox(
          width: calcWidth,
          child: TextFormField(
            controller: controller,
            readOnly: widget.readOnly,
            maxLines: 1,
            keyboardType: keyboardType ?? TextInputType.text,
            style: style,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              hintText: hintText,
              hintStyle: style.copyWith(
                fontSize: 12,
                color: Colors.black38,
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black87, width: 1.0),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue, width: 1.5),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _policeStationField({
    required TextEditingController controller,
    double minWidth = 100,
    double? maxWidth,
    String? hintText,
  }) {
    final baseMin = minWidth;
    final baseMax = maxWidth ?? 600.0;
    const double baseFontSize = 13.0;
    final style = FormTypography.serifStyle().copyWith(fontSize: baseFontSize);

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasFiniteWidth = constraints.maxWidth.isFinite;
        final availableWidth = hasFiniteWidth ? constraints.maxWidth : baseMax;

        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final text =
                controller.text.isEmpty ? (hintText ?? '') : controller.text;

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

            if (hasFiniteWidth &&
                textW > availableWidth &&
                availableWidth > 30) {
              final scale =
                  ((availableWidth - 8.0) / tp.width).clamp(0.60, 1.0);
              effectiveFontSize =
                  (baseFontSize * scale).clamp(8.5, baseFontSize);
            }

            final double computedWidth = hasFiniteWidth
                ? availableWidth
                : (textW < baseMin
                    ? baseMin
                    : (textW > baseMax ? baseMax : textW));

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
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
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
            );
          },
        );
      },
    );
  }

  final _p1Panch1Line1Ctrl = TextEditingController();
  final _p1Panch1Line2Ctrl = TextEditingController();
  final _p1Panch2Line1Ctrl = TextEditingController();
  final _p1Panch2Line2Ctrl = TextEditingController();

  final _p1FirPsCtrl = TextEditingController();
  final _p1CrimeNoCtrl = TextEditingController();
  final _p1CrimeYearCtrl = TextEditingController();
  final _p1ActSecCtrl = TextEditingController();
  final _p1ComplainantNameCtrl = TextEditingController();
  final _p1ComplainantResidenceCtrl = TextEditingController();
  final _p1ComplainantTahCtrl = TextEditingController();
  final _p1ComplainantDistCtrl = TextEditingController();
  final _p1IoNameSigCtrl = TextEditingController();
  final _p1Panch1ReceiptCtrl = TextEditingController();
  final _p1Panch2ReceiptCtrl = TextEditingController();

  // ══════════════════════════════════════════════════════════
  // ── FORM 2 CONTROLLERS (दारू प्रोहिबीशन रेड) ──
  // ══════════════════════════════════════════════════════════
  final _p2PsCtrl = TextEditingController();
  final _p2DateCtrl = TextEditingController();
  final _p2DateDayCtrl = TextEditingController();
  final _p2DateMonthCtrl = TextEditingController();
  final _p2DateYearCtrl = TextEditingController();

  String get _p2DateCombined {
    if (_p2DateCtrl.text.trim().isNotEmpty) {
      return _p2DateCtrl.text.trim();
    }
    final d = _p2DateDayCtrl.text.trim();
    final m = _p2DateMonthCtrl.text.trim();
    final y = _p2DateYearCtrl.text.trim();
    if (d.isEmpty && m.isEmpty && y.isEmpty) {
      return '';
    }
    final yFull = y.isNotEmpty ? (y.length == 2 ? '20$y' : y) : '';
    return '$d/$m/$yFull'.replaceAll(RegExp(r'/+$'), '');
  }

  final _p2Panch1Line1Ctrl = TextEditingController();
  final _p2Panch1Line2Ctrl = TextEditingController();
  final _p2Panch2Line1Ctrl = TextEditingController();
  final _p2Panch2Line2Ctrl = TextEditingController();

  final _p2RaidDateCtrl = TextEditingController();
  final _p2RaidDayCtrl = TextEditingController();
  final _p2RaidMonthCtrl = TextEditingController();
  final _p2RaidYearCtrl = TextEditingController();

  String get _p2RaidDateCombined {
    if (_p2RaidDateCtrl.text.trim().isNotEmpty) {
      return _p2RaidDateCtrl.text.trim();
    }
    final d = _p2RaidDayCtrl.text.trim();
    final m = _p2RaidMonthCtrl.text.trim();
    final y = _p2RaidYearCtrl.text.trim();
    if (d.isEmpty && m.isEmpty && y.isEmpty) {
      return '';
    }
    final yFull = y.isNotEmpty ? (y.length == 2 ? '20$y' : y) : '';
    return '$d/$m/$yFull'.replaceAll(RegExp(r'/+$'), '');
  }

  final _p2VillageCtrl = TextEditingController();
  final _p2SuspectNameCtrl = TextEditingController();
  final _p2SuspectAgeCtrl = TextEditingController();
  final _p2SuspectResidenceCtrl = TextEditingController();
  final _p2SuspectTahCtrl = TextEditingController();
  final _p2SuspectDistCtrl = TextEditingController();
  final _p2IoNameSigCtrl = TextEditingController();
  final _p2Panch1ReceiptCtrl = TextEditingController();
  final _p2Panch2ReceiptCtrl = TextEditingController();

  @override
  void dispose() {
    _p1PsCtrl.dispose();
    _p1DateCtrl.dispose();
    _p1DateDayCtrl.dispose();
    _p1DateMonthCtrl.dispose();
    _p1DateYearCtrl.dispose();
    _p1Panch1Line1Ctrl.dispose();
    _p1Panch1Line2Ctrl.dispose();
    _p1Panch2Line1Ctrl.dispose();
    _p1Panch2Line2Ctrl.dispose();
    _p1FirPsCtrl.dispose();
    _p1CrimeNoCtrl.dispose();
    _p1CrimeYearCtrl.dispose();
    _p1ActSecCtrl.dispose();
    _p1ComplainantNameCtrl.dispose();
    _p1ComplainantResidenceCtrl.dispose();
    _p1ComplainantTahCtrl.dispose();
    _p1ComplainantDistCtrl.dispose();
    _p1IoNameSigCtrl.dispose();
    _p1Panch1ReceiptCtrl.dispose();
    _p1Panch2ReceiptCtrl.dispose();

    _p2PsCtrl.dispose();
    _p2DateCtrl.dispose();
    _p2DateDayCtrl.dispose();
    _p2DateMonthCtrl.dispose();
    _p2DateYearCtrl.dispose();
    _p2Panch1Line1Ctrl.dispose();
    _p2Panch1Line2Ctrl.dispose();
    _p2Panch2Line1Ctrl.dispose();
    _p2Panch2Line2Ctrl.dispose();
    _p2RaidDateCtrl.dispose();
    _p2RaidDayCtrl.dispose();
    _p2RaidMonthCtrl.dispose();
    _p2RaidYearCtrl.dispose();
    _p2VillageCtrl.dispose();
    _p2SuspectNameCtrl.dispose();
    _p2SuspectAgeCtrl.dispose();
    _p2SuspectResidenceCtrl.dispose();
    _p2SuspectTahCtrl.dispose();
    _p2SuspectDistCtrl.dispose();
    _p2IoNameSigCtrl.dispose();
    _p2Panch1ReceiptCtrl.dispose();
    _p2Panch2ReceiptCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> collectData() {
    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      // Page 1
      'p1_policeStation': _p1PsCtrl.text.trim(),
      'p1_date': _p1DateCombined,
      'p1_dateDay': _p1DateDayCtrl.text.trim(),
      'p1_dateMonth': _p1DateMonthCtrl.text.trim(),
      'p1_dateYear': _p1DateYearCtrl.text.trim(),
      'p1_panch1': _p1Panch1Line1Ctrl.text.trim(),
      'p1_panch1Line2': _p1Panch1Line2Ctrl.text.trim(),
      'p1_panch2': _p1Panch2Line1Ctrl.text.trim(),
      'p1_panch2Line2': _p1Panch2Line2Ctrl.text.trim(),
      'p1_firPs': _p1FirPsCtrl.text.trim(),
      'p1_crimeNo': _p1CrimeNoCtrl.text.trim(),
      'p1_crimeYear': _p1CrimeYearCtrl.text.trim(),
      'p1_actSec': _p1ActSecCtrl.text.trim(),
      'p1_complainantName': _p1ComplainantNameCtrl.text.trim(),
      'p1_complainantResidence': _p1ComplainantResidenceCtrl.text.trim(),
      'p1_complainantTah': _p1ComplainantTahCtrl.text.trim(),
      'p1_complainantDist': _p1ComplainantDistCtrl.text.trim(),
      'p1_ioNameSig': _p1IoNameSigCtrl.text.trim(),
      'p1_panch1Receipt': _p1Panch1ReceiptCtrl.text.trim(),
      'p1_panch2Receipt': _p1Panch2ReceiptCtrl.text.trim(),

      // Page 2
      'p2_policeStation': _p2PsCtrl.text.trim(),
      'p2_date': _p2DateCombined,
      'p2_dateDay': _p2DateDayCtrl.text.trim(),
      'p2_dateMonth': _p2DateMonthCtrl.text.trim(),
      'p2_dateYear': _p2DateYearCtrl.text.trim(),
      'p2_panch1': _p2Panch1Line1Ctrl.text.trim(),
      'p2_panch1Line2': _p2Panch1Line2Ctrl.text.trim(),
      'p2_panch2': _p2Panch2Line1Ctrl.text.trim(),
      'p2_panch2Line2': _p2Panch2Line2Ctrl.text.trim(),
      'p2_raidDate': _p2RaidDateCombined,
      'p2_raidDay': _p2RaidDayCtrl.text.trim(),
      'p2_raidMonth': _p2RaidMonthCtrl.text.trim(),
      'p2_raidYear': _p2RaidYearCtrl.text.trim(),
      'p2_village': _p2VillageCtrl.text.trim(),
      'p2_suspectName': _p2SuspectNameCtrl.text.trim(),
      'p2_suspectAge': _p2SuspectAgeCtrl.text.trim(),
      'p2_suspectResidence': _p2SuspectResidenceCtrl.text.trim(),
      'p2_suspectTah': _p2SuspectTahCtrl.text.trim(),
      'p2_suspectDist': _p2SuspectDistCtrl.text.trim(),
      'p2_ioNameSig': _p2IoNameSigCtrl.text.trim(),
      'p2_panch1Receipt': _p2Panch1ReceiptCtrl.text.trim(),
      'p2_panch2Receipt': _p2Panch2ReceiptCtrl.text.trim(),
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    // Page 1
    _p1PsCtrl.text = data['p1_policeStation']?.toString() ??
        data['policeStation']?.toString() ??
        '';
    _p1DateCtrl.text =
        data['p1_date']?.toString() ?? data['date']?.toString() ?? '';
    _p1DateDayCtrl.text = data['p1_dateDay']?.toString() ?? '';
    _p1DateMonthCtrl.text = data['p1_dateMonth']?.toString() ?? '';
    _p1DateYearCtrl.text = data['p1_dateYear']?.toString() ?? '';
    if (_p1DateDayCtrl.text.isEmpty && _p1DateCtrl.text.isNotEmpty) {
      final parts = _p1DateCtrl.text.split(RegExp(r'[/.-]'));
      if (parts.length >= 3) {
        _p1DateDayCtrl.text = parts[0].trim();
        _p1DateMonthCtrl.text = parts[1].trim();
        var yr = parts[2].trim();
        if (yr.startsWith('20') && yr.length == 4) yr = yr.substring(2);
        _p1DateYearCtrl.text = yr;
      }
    } else if (_p1DateCtrl.text.isEmpty && _p1DateDayCtrl.text.isNotEmpty) {
      final d = _p1DateDayCtrl.text.trim();
      final m = _p1DateMonthCtrl.text.trim();
      final y = _p1DateYearCtrl.text.trim();
      final yFull = y.isNotEmpty ? (y.length == 2 ? '20$y' : y) : '';
      _p1DateCtrl.text = '$d/$m/$yFull';
    }

    _p1Panch1Line1Ctrl.text =
        data['p1_panch1']?.toString() ?? data['panch1']?.toString() ?? '';
    _p1Panch1Line2Ctrl.text = data['p1_panch1Line2']?.toString() ?? '';
    _p1Panch2Line1Ctrl.text =
        data['p1_panch2']?.toString() ?? data['panch2']?.toString() ?? '';
    _p1Panch2Line2Ctrl.text = data['p1_panch2Line2']?.toString() ?? '';

    _p1FirPsCtrl.text =
        data['p1_firPs']?.toString() ?? data['firPs']?.toString() ?? '';
    _p1CrimeNoCtrl.text =
        data['p1_crimeNo']?.toString() ?? data['crimeNo']?.toString() ?? '';
    _p1CrimeYearCtrl.text = data['p1_crimeYear']?.toString() ?? '';
    if (_p1CrimeNoCtrl.text.contains('/')) {
      final p = _p1CrimeNoCtrl.text.split('/');
      _p1CrimeNoCtrl.text = p[0].trim();
      if (p.length > 1 && _p1CrimeYearCtrl.text.isEmpty) {
        var y = p[1].trim();
        if (y.startsWith('20') && y.length == 4) y = y.substring(2);
        _p1CrimeYearCtrl.text = y;
      }
    }

    _p1ActSecCtrl.text =
        data['p1_actSec']?.toString() ?? data['actSec']?.toString() ?? '';
    _p1ComplainantNameCtrl.text = data['p1_complainantName']?.toString() ??
        data['complainantName']?.toString() ??
        '';
    _p1ComplainantResidenceCtrl.text =
        data['p1_complainantResidence']?.toString() ??
            data['complainantResidence']?.toString() ??
            '';
    _p1ComplainantTahCtrl.text = data['p1_complainantTah']?.toString() ??
        data['complainantTah']?.toString() ??
        '';
    _p1ComplainantDistCtrl.text = data['p1_complainantDist']?.toString() ??
        data['complainantDist']?.toString() ??
        '';
    _p1IoNameSigCtrl.text =
        data['p1_ioNameSig']?.toString() ?? data['ioNameSig']?.toString() ?? '';
    _p1Panch1ReceiptCtrl.text = data['p1_panch1Receipt']?.toString() ??
        data['panch1Receipt']?.toString() ??
        '';
    _p1Panch2ReceiptCtrl.text = data['p1_panch2Receipt']?.toString() ??
        data['panch2Receipt']?.toString() ??
        '';

    // Page 2
    _p2PsCtrl.text = data['p2_policeStation']?.toString() ??
        data['policeStation']?.toString() ??
        '';
    _p2DateCtrl.text =
        data['p2_date']?.toString() ?? data['date']?.toString() ?? '';
    _p2DateDayCtrl.text = data['p2_dateDay']?.toString() ?? '';
    _p2DateMonthCtrl.text = data['p2_dateMonth']?.toString() ?? '';
    _p2DateYearCtrl.text = data['p2_dateYear']?.toString() ?? '';
    if (_p2DateDayCtrl.text.isEmpty && _p2DateCtrl.text.isNotEmpty) {
      final parts = _p2DateCtrl.text.split(RegExp(r'[/.-]'));
      if (parts.length >= 3) {
        _p2DateDayCtrl.text = parts[0].trim();
        _p2DateMonthCtrl.text = parts[1].trim();
        var yr = parts[2].trim();
        if (yr.startsWith('20') && yr.length == 4) yr = yr.substring(2);
        _p2DateYearCtrl.text = yr;
      }
    } else if (_p2DateCtrl.text.isEmpty && _p2DateDayCtrl.text.isNotEmpty) {
      final d = _p2DateDayCtrl.text.trim();
      final m = _p2DateMonthCtrl.text.trim();
      final y = _p2DateYearCtrl.text.trim();
      final yFull = y.isNotEmpty ? (y.length == 2 ? '20$y' : y) : '';
      _p2DateCtrl.text = '$d/$m/$yFull';
    }

    _p2Panch1Line1Ctrl.text =
        data['p2_panch1']?.toString() ?? data['panch1']?.toString() ?? '';
    _p2Panch1Line2Ctrl.text = data['p2_panch1Line2']?.toString() ?? '';
    _p2Panch2Line1Ctrl.text =
        data['p2_panch2']?.toString() ?? data['panch2']?.toString() ?? '';
    _p2Panch2Line2Ctrl.text = data['p2_panch2Line2']?.toString() ?? '';

    _p2RaidDateCtrl.text =
        data['p2_raidDate']?.toString() ?? data['raidDate']?.toString() ?? '';
    _p2RaidDayCtrl.text = data['p2_raidDay']?.toString() ?? '';
    _p2RaidMonthCtrl.text = data['p2_raidMonth']?.toString() ?? '';
    _p2RaidYearCtrl.text = data['p2_raidYear']?.toString() ?? '';
    if (_p2RaidDayCtrl.text.isEmpty && _p2RaidDateCtrl.text.isNotEmpty) {
      final parts = _p2RaidDateCtrl.text.split(RegExp(r'[/.-]'));
      if (parts.length >= 3) {
        _p2RaidDayCtrl.text = parts[0].trim();
        _p2RaidMonthCtrl.text = parts[1].trim();
        var yr = parts[2].trim();
        if (yr.startsWith('20') && yr.length == 4) yr = yr.substring(2);
        _p2RaidYearCtrl.text = yr;
      }
    } else if (_p2RaidDateCtrl.text.isEmpty && _p2RaidDayCtrl.text.isNotEmpty) {
      final d = _p2RaidDayCtrl.text.trim();
      final m = _p2RaidMonthCtrl.text.trim();
      final y = _p2RaidYearCtrl.text.trim();
      final yFull = y.isNotEmpty ? (y.length == 2 ? '20$y' : y) : '';
      _p2RaidDateCtrl.text = '$d/$m/$yFull';
    }

    _p2VillageCtrl.text =
        data['p2_village']?.toString() ?? data['village']?.toString() ?? '';
    _p2SuspectNameCtrl.text = data['p2_suspectName']?.toString() ??
        data['suspectName']?.toString() ??
        '';
    _p2SuspectAgeCtrl.text = data['p2_suspectAge']?.toString() ??
        data['suspectAge']?.toString() ??
        '';
    _p2SuspectResidenceCtrl.text = data['p2_suspectResidence']?.toString() ??
        data['suspectResidence']?.toString() ??
        '';
    _p2SuspectTahCtrl.text = data['p2_suspectTah']?.toString() ??
        data['suspectTah']?.toString() ??
        '';
    _p2SuspectDistCtrl.text = data['p2_suspectDist']?.toString() ??
        data['suspectDist']?.toString() ??
        '';
    _p2IoNameSigCtrl.text =
        data['p2_ioNameSig']?.toString() ?? data['ioNameSig']?.toString() ?? '';
    _p2Panch1ReceiptCtrl.text = data['p2_panch1Receipt']?.toString() ??
        data['panch1Receipt']?.toString() ??
        '';
    _p2Panch2ReceiptCtrl.text = data['p2_panch2Receipt']?.toString() ??
        data['panch2Receipt']?.toString() ??
        '';

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final serif = FormTypography.serifStyle();
    final marathi = FormTypography.marathiLabelStyle();

    final bodyTextStyle = marathi.copyWith(
      fontSize: 14,
      height: 2.3,
      color: Colors.black87,
    );
    final headerLabelStyle = marathi.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    );

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        // ══════════════════════════════════════════════════════════
        // ── FORM 1: घटनास्थळ / जप्ती पंचनामा सुचनापत्र (Image 1) ──
        // ══════════════════════════════════════════════════════════
        FormPaperPage(
          minHeight: 1180,
          formLabel: 'फॉर्म १ : घटनास्थळाचा / जप्ती पंचनामा सुचनापत्र',
          children: [
            const SizedBox(height: 12),

            // ── TOP RIGHT POLICE STATION / DATE ──
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 380,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('पोलीस स्टेशन', style: headerLabelStyle),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _policeStationField(
                            controller: _p1PsCtrl,
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
                          controller: _p1DateCtrl,
                          dayCtrl: _p1DateDayCtrl,
                          monthCtrl: _p1DateMonthCtrl,
                          yearCtrl: _p1DateYearCtrl,
                          width: 140,
                          readOnly: widget.readOnly,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── TITLE ──
            Center(
              child: Column(
                children: [
                  Text(
                    '—:: पंच सुचनापत्र ::—',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '(कलम १७९ भारतीय नागरीक सुरक्षा संहिता २०२३ अन्वये)',
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
            const SizedBox(height: 32),

            // ── PANCH NAMES ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 95,
                  child: Text('पंच नांव', style: headerLabelStyle),
                ),
                Text(':-', style: headerLabelStyle),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      // Panch 1
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('१)', style: headerLabelStyle),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _wrappingUnderlineInput(
                              controller: _p1Panch1Line1Ctrl,
                              minWidth: 200,
                              maxWidth: 500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: _wrappingUnderlineInput(
                          controller: _p1Panch1Line2Ctrl,
                          minWidth: 200,
                          maxWidth: 500,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Panch 2
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('२)', style: headerLabelStyle),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _wrappingUnderlineInput(
                              controller: _p1Panch2Line1Ctrl,
                              minWidth: 200,
                              maxWidth: 500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: _wrappingUnderlineInput(
                          controller: _p1Panch2Line2Ctrl,
                          minWidth: 200,
                          maxWidth: 500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── CENTER oooo ──
            Center(
              child: Text(
                '००००',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 5,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── MAIN PARAGRAPH ──
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 12,
              children: [
                Text(
                  '        आपणास या सुचनापत्र देण्यात येते की, पोलीस स्टेशन',
                  style: bodyTextStyle,
                ),
                _policeStationField(
                  controller: _p1FirPsCtrl,
                  minWidth: 120,
                  maxWidth: 300,
                ),
                Text('येथील अप / मर्ग/ स्टे.डा क्रमांक', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _p1CrimeNoCtrl,
                  minWidth: 60,
                  maxWidth: 120,
                  hintText: '........',
                ),
                Text('/ २०', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _p1CrimeYearCtrl,
                  minWidth: 40,
                  maxWidth: 80,
                  hintText: '.....',
                ),
                Text('कलम', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _p1ActSecCtrl,
                  minWidth: 180,
                  maxWidth: 450,
                ),
                Text('मधील फिर्यादी नामे', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _p1ComplainantNameCtrl,
                  minWidth: 200,
                  maxWidth: 450,
                ),
                Text('रा', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _p1ComplainantResidenceCtrl,
                  minWidth: 120,
                  maxWidth: 300,
                ),
                Text('ता', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _p1ComplainantTahCtrl,
                  minWidth: 100,
                  maxWidth: 250,
                ),
                Text('जिल्हा', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _p1ComplainantDistCtrl,
                  minWidth: 100,
                  maxWidth: 250,
                ),
                Text(
                  'यांनी तक्रार दिली वरून सदरचा गुन्हा नोंद होउन तपासात आहे. तरी सदर गुन्ह्यामधील घटनास्थळाचा/ जप्ती पंचनामा करावयाचा असल्याने आपण पंच म्हणुन हजर राहा असे सांगीतल्या वरून पंच हजर आले आहे.',
                  style: bodyTextStyle,
                ),
              ],
            ),
            const SizedBox(height: 36),

            // ── CLOSING LINE ──
            Center(
              child: Text(
                'करीता सुचनापत्र देण्यात येत आहे.',
                style: bodyTextStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 48),

            // ── SIGNATURE (RIGHT) ──
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 240,
                child: Column(
                  children: [
                    Text('तपासी अधिकारी नांव व सही', style: headerLabelStyle),
                    const SizedBox(height: 10),
                    _wrappingUnderlineInput(
                      controller: _p1IoNameSigCtrl,
                      minWidth: 180,
                      maxWidth: 240,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── RECEIPT ACKNOWLEDGEMENT (LEFT) ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('सुचनापत्र मिळाले आहे.', style: headerLabelStyle),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('१)', style: headerLabelStyle),
                    const SizedBox(width: 8),
                    _wrappingUnderlineInput(
                      controller: _p1Panch1ReceiptCtrl,
                      minWidth: 200,
                      maxWidth: 400,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('२)', style: headerLabelStyle),
                    const SizedBox(width: 8),
                    _wrappingUnderlineInput(
                      controller: _p1Panch2ReceiptCtrl,
                      minWidth: 200,
                      maxWidth: 400,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 48),

            // ── MRW FOOTER ──
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'M.R.W',
                style: serif.copyWith(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        // ══════════════════════════════════════════════════════════
        // ── SPACING & DIVIDER BETWEEN FORM 1 AND FORM 2 ──
        // ══════════════════════════════════════════════════════════
        const SizedBox(height: 56),

        // ══════════════════════════════════════════════════════════
        // ── FORM 2: दारूबाबत प्रोहिबीशन रेड सुचनापत्र (Image 2) ──
        // ══════════════════════════════════════════════════════════
        FormPaperPage(
          minHeight: 1180,
          formLabel: 'फॉर्म २ : दारूबाबत प्रोहिबीशन रेड सुचनापत्र',
          children: [
            const SizedBox(height: 12),

            // ── TOP RIGHT POLICE STATION / DATE ──
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 380,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('पोलीस स्टेशन', style: headerLabelStyle),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _policeStationField(
                            controller: _p2PsCtrl,
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
                          controller: _p2DateCtrl,
                          dayCtrl: _p2DateDayCtrl,
                          monthCtrl: _p2DateMonthCtrl,
                          yearCtrl: _p2DateYearCtrl,
                          width: 140,
                          readOnly: widget.readOnly,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── TITLE ──
            Center(
              child: Column(
                children: [
                  Text(
                    '—:: पंच सुचनापत्र ::—',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '(कलम १७९ भारतीय नागरीक सुरक्षा संहिता २०२३ अन्वये)',
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
            const SizedBox(height: 32),

            // ── PANCH NAMES ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 95,
                  child: Text('पंच नांव', style: headerLabelStyle),
                ),
                Text(':-', style: headerLabelStyle),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      // Panch 1
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('१)', style: headerLabelStyle),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _wrappingUnderlineInput(
                              controller: _p2Panch1Line1Ctrl,
                              minWidth: 200,
                              maxWidth: 500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: _wrappingUnderlineInput(
                          controller: _p2Panch1Line2Ctrl,
                          minWidth: 200,
                          maxWidth: 500,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Panch 2
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('२)', style: headerLabelStyle),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _wrappingUnderlineInput(
                              controller: _p2Panch2Line1Ctrl,
                              minWidth: 200,
                              maxWidth: 500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 24),
                        child: _wrappingUnderlineInput(
                          controller: _p2Panch2Line2Ctrl,
                          minWidth: 200,
                          maxWidth: 500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── CENTER oooo ──
            Center(
              child: Text(
                '००००',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 5,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── MAIN PARAGRAPH ──
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 12,
              children: [
                Text(
                  '        आपणास या सुचनापत्र देण्यात येते की, आज दिनांक:',
                  style: bodyTextStyle,
                ),
                formDatePickerField(
                  context,
                  controller: _p2RaidDateCtrl,
                  dayCtrl: _p2RaidDayCtrl,
                  monthCtrl: _p2RaidMonthCtrl,
                  yearCtrl: _p2RaidYearCtrl,
                  width: 140,
                  readOnly: widget.readOnly,
                ),
                Text('रोजी ग्राम', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _p2VillageCtrl,
                  minWidth: 120,
                  maxWidth: 300,
                ),
                Text('येथीलनामे', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _p2SuspectNameCtrl,
                  minWidth: 200,
                  maxWidth: 450,
                ),
                Text('वय', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _p2SuspectAgeCtrl,
                  minWidth: 40,
                  maxWidth: 80,
                  hintText: '........',
                  keyboardType: TextInputType.number,
                ),
                Text('वर्ष', style: bodyTextStyle),
                Text('----------- रा.', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _p2SuspectResidenceCtrl,
                  minWidth: 120,
                  maxWidth: 300,
                ),
                Text('ता', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _p2SuspectTahCtrl,
                  minWidth: 100,
                  maxWidth: 250,
                ),
                Text('जिल्हा', style: bodyTextStyle),
                _wrappingUnderlineInput(
                  controller: _p2SuspectDistCtrl,
                  minWidth: 100,
                  maxWidth: 250,
                ),
                Text(
                  'हा त्याचे घरी दारू विक्री करतो अशा माहिती वरून त्याचे घरी दारूबाबत प्रोहिबीशन रेड करावयाचा असल्याने आपण जप्त पंच म्हणुन सोबत चला व हजर राहावे.',
                  style: bodyTextStyle,
                ),
              ],
            ),
            const SizedBox(height: 36),

            // ── CLOSING LINE ──
            Center(
              child: Text(
                'करीता सुचनापत्र देण्यात येत आहे.',
                style: bodyTextStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 48),

            // ── SIGNATURE (RIGHT) ──
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 240,
                child: Column(
                  children: [
                    Text('तपासी अधिकारी नांव व सही', style: headerLabelStyle),
                    const SizedBox(height: 10),
                    _wrappingUnderlineInput(
                      controller: _p2IoNameSigCtrl,
                      minWidth: 180,
                      maxWidth: 240,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── RECEIPT ACKNOWLEDGEMENT (LEFT) ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('सुचनापत्र मिळाले आहे.', style: headerLabelStyle),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('१)', style: headerLabelStyle),
                    const SizedBox(width: 8),
                    _wrappingUnderlineInput(
                      controller: _p2Panch1ReceiptCtrl,
                      minWidth: 200,
                      maxWidth: 400,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('२)', style: headerLabelStyle),
                    const SizedBox(width: 8),
                    _wrappingUnderlineInput(
                      controller: _p2Panch2ReceiptCtrl,
                      minWidth: 200,
                      maxWidth: 400,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 48),

            // ── MRW FOOTER ──
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'M.R.W',
                style: serif.copyWith(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
