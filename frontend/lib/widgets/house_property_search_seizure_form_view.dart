import 'package:flutter/material.dart';

import 'bilingual_field.dart';
import 'form_paper_page.dart';
import 'form_section_utils.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';

class HousePropertySearchSeizureFormView extends StatefulWidget {
  final bool readOnly;
  final Map<String, dynamic>? existingRecord;
  final String? formSection;
  final String? pageRange;

  const HousePropertySearchSeizureFormView({
    super.key,
    this.readOnly = false,
    this.existingRecord,
    this.formSection,
    this.pageRange,
  });

  @override
  State<HousePropertySearchSeizureFormView> createState() =>
      HousePropertySearchSeizureFormViewState();
}

class HousePropertySearchSeizureFormViewState
    extends State<HousePropertySearchSeizureFormView> {
  static const kSearchForm = 'Search Seizure Form';
  static const kPanchanama = 'Search Seizure Panchanama';
  static const _knownSectionIds = {kSearchForm, kPanchanama};

  bool _shows(String sectionId) => showsFormSection(
        activeSection: widget.formSection,
        sectionId: sectionId,
        knownSectionIds: _knownSectionIds,
      );

  bool get _showAll => showsAllFormSections(
        activeSection: widget.formSection,
        knownSectionIds: _knownSectionIds,
      );

  // ══════════════════════════════════════════════════════════════════════════
  // CONTROLLERS — Page 1 (Sections 1–10)
  // ══════════════════════════════════════════════════════════════════════════
  final _distCtrl = TextEditingController();
  final _psCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _firNoCtrl = TextEditingController();
  final _firYearSuffixCtrl = TextEditingController();
  final _headerDateCtrl = TextEditingController();
  final _headerDateDayCtrl = TextEditingController();
  final _headerDateMonthCtrl = TextEditingController();
  final _headerDateYearCtrl = TextEditingController();

  final _actSectionsCtrl = TextEditingController();
  final _naturePropertyCtrl = TextEditingController();

  final _accusedNameAddressCtrl = TextEditingController();
  final _placeSeizedCtrl = TextEditingController();
  final _placeDescriptionCtrl = TextEditingController();

  final _profReceiverCtrl = TextEditingController();
  final _personNameCtrl = TextEditingController();
  final _personFatherCtrl = TextEditingController();
  final _personSexCtrl = TextEditingController();
  final _personAgeCtrl = TextEditingController();
  final _personOccupationCtrl = TextEditingController();
  final _personAddressCtrl = TextEditingController();
  final _personAddressLine2Ctrl = TextEditingController();

  final _perishableDisposalCtrl = TextEditingController();
  final _valuableKeepingCtrl = TextEditingController();
  final _identificationRequiredCtrl = TextEditingController();

  final _propertyDetailsCtrl = TextEditingController();
  final _propertyDetailsAttachCtrl = TextEditingController();
  final _circumstancesCtrl = TextEditingController();

  // ══════════════════════════════════════════════════════════════════════════
  // CONTROLLERS — Page 2 (Sections 11–16)
  // ══════════════════════════════════════════════════════════════════════════
  final List<TextEditingController> _propertyPackedControllers = [
    TextEditingController()
  ];

  final _seizeDateCtrl = TextEditingController();
  final _seizeDateDayCtrl = TextEditingController();
  final _seizeDateMonthCtrl = TextEditingController();
  final _seizeDateYearCtrl = TextEditingController();

  final _seizeTimeFromCtrl = TextEditingController();
  final _seizeTimeToCtrl = TextEditingController();
  final _seizeTimeHoursCtrl = TextEditingController();
  final _seizeTimeMinutesCtrl = TextEditingController();
  final _seizeTimeToHoursCtrl = TextEditingController();
  final _seizeTimeToMinutesCtrl = TextEditingController();

  final _witness1Line1Ctrl = TextEditingController();
  final _witness1Line2Ctrl = TextEditingController();
  final _witness1Line3Ctrl = TextEditingController();
  final _witness1SigCtrl = TextEditingController();

  final _witness2Line1Ctrl = TextEditingController();
  final _witness2Line2Ctrl = TextEditingController();
  final _witness2Line3Ctrl = TextEditingController();
  final _witness2SigCtrl = TextEditingController();

  final _sealSampleDateCtrl = TextEditingController();
  final _sealSampleDateDayCtrl = TextEditingController();
  final _sealSampleDateMonthCtrl = TextEditingController();
  final _sealSampleDateYearCtrl = TextEditingController();

  final _seizedPersonSigCtrl = TextEditingController();

  final _ioNameCtrl = TextEditingController();
  final _ioRankCtrl = TextEditingController();
  final _ioNoCtrl = TextEditingController();
  final _ioPostingCtrl = TextEditingController();
  final _ioSigCtrl = TextEditingController();

  // ══════════════════════════════════════════════════════════════════════════
  // COMBINED GETTERS
  // ══════════════════════════════════════════════════════════════════════════
  String get _headerDateCombined {
    final d = _headerDateDayCtrl.text.trim();
    final m = _headerDateMonthCtrl.text.trim();
    final y = _headerDateYearCtrl.text.trim();
    if (d.isEmpty && m.isEmpty && y.isEmpty) return _headerDateCtrl.text.trim();
    final fullY = y.length == 2 ? '20$y' : y;
    return '${d.padLeft(2, '0')}/${m.padLeft(2, '0')}/$fullY';
  }

  String get _seizeDateCombined {
    final d = _seizeDateDayCtrl.text.trim();
    final m = _seizeDateMonthCtrl.text.trim();
    final y = _seizeDateYearCtrl.text.trim();
    if (d.isEmpty && m.isEmpty && y.isEmpty) return _seizeDateCtrl.text.trim();
    final fullY = y.length == 2 ? '20$y' : y;
    return '${d.padLeft(2, '0')}/${m.padLeft(2, '0')}/$fullY';
  }

  String get _sealSampleDateCombined {
    final d = _sealSampleDateDayCtrl.text.trim();
    final m = _sealSampleDateMonthCtrl.text.trim();
    final y = _sealSampleDateYearCtrl.text.trim();
    if (d.isEmpty && m.isEmpty && y.isEmpty) return _sealSampleDateCtrl.text.trim();
    final fullY = y.length == 2 ? '20$y' : y;
    return '${d.padLeft(2, '0')}/${m.padLeft(2, '0')}/$fullY';
  }

  String get _seizeTimeFromCombined {
    final fromH = _seizeTimeHoursCtrl.text.trim();
    final fromM = _seizeTimeMinutesCtrl.text.trim();
    if (fromH.isEmpty && fromM.isEmpty) return _seizeTimeFromCtrl.text.trim();
    return '${fromH.padLeft(2, '0')}:${fromM.padLeft(2, '0')}';
  }

  String get _seizeTimeToCombined {
    final toH = _seizeTimeToHoursCtrl.text.trim();
    final toM = _seizeTimeToMinutesCtrl.text.trim();
    if (toH.isEmpty && toM.isEmpty) return _seizeTimeToCtrl.text.trim();
    return '${toH.padLeft(2, '0')}:${toM.padLeft(2, '0')}';
  }

  String get _seizeTimeCombined {
    final fromH = _seizeTimeHoursCtrl.text.trim();
    final fromM = _seizeTimeMinutesCtrl.text.trim();
    final toH = _seizeTimeToHoursCtrl.text.trim();
    final toM = _seizeTimeToMinutesCtrl.text.trim();
    if (fromH.isEmpty && fromM.isEmpty && toH.isEmpty && toM.isEmpty) {
      if (_seizeTimeFromCtrl.text.isNotEmpty && _seizeTimeToCtrl.text.isNotEmpty) {
        return '${_seizeTimeFromCtrl.text.trim()} to ${_seizeTimeToCtrl.text.trim()}';
      }
      return _seizeTimeFromCtrl.text.trim();
    }
    final fromStr = '${fromH.padLeft(2, '0')}:${fromM.padLeft(2, '0')}';
    final toStr = '${toH.padLeft(2, '0')}:${toM.padLeft(2, '0')}';
    return '$fromStr to $toStr';
  }

  Widget _buildDashedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const dashSpace = 2.0;
        final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(count, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black87),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingRecord != null) {
      hydrateFrom(widget.existingRecord!);
    }
  }

  @override
  void dispose() {
    _distCtrl.dispose();
    _psCtrl.dispose();
    _yearCtrl.dispose();
    _firNoCtrl.dispose();
    _firYearSuffixCtrl.dispose();
    _headerDateCtrl.dispose();
    _headerDateDayCtrl.dispose();
    _headerDateMonthCtrl.dispose();
    _headerDateYearCtrl.dispose();
    _actSectionsCtrl.dispose();
    _naturePropertyCtrl.dispose();
    _accusedNameAddressCtrl.dispose();
    _placeSeizedCtrl.dispose();
    _placeDescriptionCtrl.dispose();
    _profReceiverCtrl.dispose();
    _personNameCtrl.dispose();
    _personFatherCtrl.dispose();
    _personSexCtrl.dispose();
    _personAgeCtrl.dispose();
    _personOccupationCtrl.dispose();
    _personAddressCtrl.dispose();
    _personAddressLine2Ctrl.dispose();
    _perishableDisposalCtrl.dispose();
    _valuableKeepingCtrl.dispose();
    _identificationRequiredCtrl.dispose();
    _propertyDetailsCtrl.dispose();
    _propertyDetailsAttachCtrl.dispose();
    _circumstancesCtrl.dispose();

    for (final c in _propertyPackedControllers) {
      c.dispose();
    }

    _seizeDateCtrl.dispose();
    _seizeDateDayCtrl.dispose();
    _seizeDateMonthCtrl.dispose();
    _seizeDateYearCtrl.dispose();
    _seizeTimeFromCtrl.dispose();
    _seizeTimeToCtrl.dispose();
    _seizeTimeHoursCtrl.dispose();
    _seizeTimeMinutesCtrl.dispose();
    _seizeTimeToHoursCtrl.dispose();
    _seizeTimeToMinutesCtrl.dispose();
    _witness1Line1Ctrl.dispose();
    _witness1Line2Ctrl.dispose();
    _witness1Line3Ctrl.dispose();
    _witness1SigCtrl.dispose();
    _witness2Line1Ctrl.dispose();
    _witness2Line2Ctrl.dispose();
    _witness2Line3Ctrl.dispose();
    _witness2SigCtrl.dispose();
    _sealSampleDateCtrl.dispose();
    _sealSampleDateDayCtrl.dispose();
    _sealSampleDateMonthCtrl.dispose();
    _sealSampleDateYearCtrl.dispose();
    _seizedPersonSigCtrl.dispose();
    _ioNameCtrl.dispose();
    _ioRankCtrl.dispose();
    _ioNoCtrl.dispose();
    _ioPostingCtrl.dispose();
    _ioSigCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HYDRATE
  // ══════════════════════════════════════════════════════════════════════════
  void hydrateFrom(Map<String, dynamic> data) {
    setState(() {
      void set(TextEditingController c, String key) {
        c.text = data[key]?.toString() ?? '';
      }

      set(_distCtrl, 'dist');
      set(_psCtrl, 'ps');
      set(_yearCtrl, 'year');
      set(_firNoCtrl, 'firNo');
      set(_firYearSuffixCtrl, 'firYearSuffix');
      set(_headerDateCtrl, 'headerDate');
      set(_headerDateDayCtrl, 'headerDateDay');
      set(_headerDateMonthCtrl, 'headerDateMonth');
      set(_headerDateYearCtrl, 'headerDateYear');
      if (_headerDateDayCtrl.text.isEmpty && _headerDateCtrl.text.isNotEmpty) {
        final parts = _headerDateCtrl.text.split(RegExp(r'[/.-]'));
        if (parts.length >= 3) {
          _headerDateDayCtrl.text = parts[0].trim();
          _headerDateMonthCtrl.text = parts[1].trim();
          var yr = parts[2].trim();
          if (yr.startsWith('20') && yr.length == 4) yr = yr.substring(2);
          _headerDateYearCtrl.text = yr;
        }
      }

      set(_actSectionsCtrl, 'actSections');
      set(_naturePropertyCtrl, 'natureProperty');
      set(_accusedNameAddressCtrl, 'accusedNameAddress');
      set(_placeSeizedCtrl, 'placeSeized');
      set(_placeDescriptionCtrl, 'placeDescription');
      set(_profReceiverCtrl, 'profReceiver');
      set(_personNameCtrl, 'personName');
      set(_personFatherCtrl, 'personFather');
      set(_personSexCtrl, 'personSex');
      set(_personAgeCtrl, 'personAge');
      set(_personOccupationCtrl, 'personOccupation');
      set(_personAddressCtrl, 'personAddress');
      set(_personAddressLine2Ctrl, 'personAddressLine2');
      set(_perishableDisposalCtrl, 'perishableDisposal');
      set(_valuableKeepingCtrl, 'valuableKeeping');
      set(_identificationRequiredCtrl, 'identificationRequired');
      set(_propertyDetailsCtrl, 'propertyDetails');
      set(_propertyDetailsAttachCtrl, 'propertyDetailsAttach');
      set(_circumstancesCtrl, 'circumstances');

      // Property table
      if (data['propertyPackedList'] is List &&
          (data['propertyPackedList'] as List).isNotEmpty) {
        for (final c in _propertyPackedControllers) {
          c.dispose();
        }
        _propertyPackedControllers.clear();
        for (final item in (data['propertyPackedList'] as List)) {
          _propertyPackedControllers
              .add(TextEditingController(text: item?.toString() ?? ''));
        }
      } else if (data['propertyPacked'] != null &&
          data['propertyPacked'].toString().isNotEmpty) {
        final text = data['propertyPacked'].toString();
        for (final c in _propertyPackedControllers) {
          c.dispose();
        }
        _propertyPackedControllers.clear();
        if (text.contains('\n---\n')) {
          for (final part in text.split('\n---\n')) {
            _propertyPackedControllers.add(TextEditingController(text: part));
          }
        } else {
          _propertyPackedControllers.add(TextEditingController(text: text));
        }
      }
      if (_propertyPackedControllers.isEmpty) {
        _propertyPackedControllers.add(TextEditingController());
      }

      set(_seizeDateCtrl, 'seizeDate');
      set(_seizeDateDayCtrl, 'seizeDateDay');
      set(_seizeDateMonthCtrl, 'seizeDateMonth');
      set(_seizeDateYearCtrl, 'seizeDateYear');
      if (_seizeDateDayCtrl.text.isEmpty && _seizeDateCtrl.text.isNotEmpty) {
        final parts = _seizeDateCtrl.text.split(RegExp(r'[/.-]'));
        if (parts.length >= 3) {
          _seizeDateDayCtrl.text = parts[0].trim();
          _seizeDateMonthCtrl.text = parts[1].trim();
          var yr = parts[2].trim();
          if (yr.startsWith('20') && yr.length == 4) yr = yr.substring(2);
          _seizeDateYearCtrl.text = yr;
        }
      }

      set(_seizeTimeFromCtrl, 'seizeTimeFrom');
      set(_seizeTimeToCtrl, 'seizeTimeTo');
      set(_seizeTimeHoursCtrl, 'seizeTimeHours');
      set(_seizeTimeMinutesCtrl, 'seizeTimeMinutes');
      set(_seizeTimeToHoursCtrl, 'seizeTimeToHours');
      set(_seizeTimeToMinutesCtrl, 'seizeTimeToMinutes');
      if (_seizeTimeHoursCtrl.text.isEmpty && _seizeTimeFromCtrl.text.isNotEmpty) {
        final parts = _seizeTimeFromCtrl.text.split(RegExp(r'[/.:]'));
        if (parts.length >= 2) {
          _seizeTimeHoursCtrl.text = parts[0].trim();
          _seizeTimeMinutesCtrl.text = parts[1].trim();
        }
      }
      if (_seizeTimeToHoursCtrl.text.isEmpty && _seizeTimeToCtrl.text.isNotEmpty) {
        final parts = _seizeTimeToCtrl.text.split(RegExp(r'[/.:]'));
        if (parts.length >= 2) {
          _seizeTimeToHoursCtrl.text = parts[0].trim();
          _seizeTimeToMinutesCtrl.text = parts[1].trim();
        }
      }

      set(_witness1Line1Ctrl, 'witness1Line1');
      set(_witness1Line2Ctrl, 'witness1Line2');
      set(_witness1Line3Ctrl, 'witness1Line3');
      set(_witness1SigCtrl, 'witness1Sig');
      if (_witness1Line1Ctrl.text.isEmpty && data['witness1Name'] != null) {
        _witness1Line1Ctrl.text = data['witness1Name']?.toString() ?? '';
      }
      if (_witness1Line2Ctrl.text.isEmpty && data['witness1Address'] != null) {
        _witness1Line2Ctrl.text = data['witness1Address']?.toString() ?? '';
      }

      set(_witness2Line1Ctrl, 'witness2Line1');
      set(_witness2Line2Ctrl, 'witness2Line2');
      set(_witness2Line3Ctrl, 'witness2Line3');
      set(_witness2SigCtrl, 'witness2Sig');
      if (_witness2Line1Ctrl.text.isEmpty && data['witness2Name'] != null) {
        _witness2Line1Ctrl.text = data['witness2Name']?.toString() ?? '';
      }
      if (_witness2Line2Ctrl.text.isEmpty && data['witness2Address'] != null) {
        _witness2Line2Ctrl.text = data['witness2Address']?.toString() ?? '';
      }

      set(_sealSampleDateCtrl, 'sealSampleDate');
      set(_sealSampleDateDayCtrl, 'sealSampleDateDay');
      set(_sealSampleDateMonthCtrl, 'sealSampleDateMonth');
      set(_sealSampleDateYearCtrl, 'sealSampleDateYear');
      if (_sealSampleDateDayCtrl.text.isEmpty && _sealSampleDateCtrl.text.isNotEmpty) {
        final parts = _sealSampleDateCtrl.text.split(RegExp(r'[/.-]'));
        if (parts.length >= 3) {
          _sealSampleDateDayCtrl.text = parts[0].trim();
          _sealSampleDateMonthCtrl.text = parts[1].trim();
          var yr = parts[2].trim();
          if (yr.startsWith('20') && yr.length == 4) yr = yr.substring(2);
          _sealSampleDateYearCtrl.text = yr;
        }
      }

      set(_seizedPersonSigCtrl, 'seizedPersonSig');
      set(_ioNameCtrl, 'ioName');
      set(_ioRankCtrl, 'ioRank');
      set(_ioNoCtrl, 'ioNo');
      set(_ioPostingCtrl, 'ioPosting');
      set(_ioSigCtrl, 'ioSig');
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // COLLECT DATA
  // ══════════════════════════════════════════════════════════════════════════
  Map<String, dynamic> collectData() {
    final fromTime = _seizeTimeFromCombined;
    final toTime = _seizeTimeToCombined;

    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'dist': _distCtrl.text.trim(),
      'ps': _psCtrl.text.trim(),
      'year': _yearCtrl.text.trim(),
      'firNo': _firNoCtrl.text.trim(),
      'firYearSuffix': _firYearSuffixCtrl.text.trim(),
      'headerDate': _headerDateCombined,
      'headerDateDay': _headerDateDayCtrl.text.trim(),
      'headerDateMonth': _headerDateMonthCtrl.text.trim(),
      'headerDateYear': _headerDateYearCtrl.text.trim(),
      'actSections': _actSectionsCtrl.text.trim(),
      'natureProperty': _naturePropertyCtrl.text.trim(),
      'accusedNameAddress': _accusedNameAddressCtrl.text.trim(),
      'placeSeized': _placeSeizedCtrl.text.trim(),
      'placeDescription': _placeDescriptionCtrl.text.trim(),
      'profReceiver': _profReceiverCtrl.text.trim(),
      'personName': _personNameCtrl.text.trim(),
      'personFather': _personFatherCtrl.text.trim(),
      'personSex': _personSexCtrl.text.trim(),
      'personAge': _personAgeCtrl.text.trim(),
      'personOccupation': _personOccupationCtrl.text.trim(),
      'personAddress': _personAddressCtrl.text.trim(),
      'personAddressLine2': _personAddressLine2Ctrl.text.trim(),
      'perishableDisposal': _perishableDisposalCtrl.text.trim(),
      'valuableKeeping': _valuableKeepingCtrl.text.trim(),
      'identificationRequired': _identificationRequiredCtrl.text.trim(),
      'propertyDetails': _propertyDetailsCtrl.text.trim(),
      'propertyDetailsAttach': _propertyDetailsAttachCtrl.text.trim(),
      'circumstances': _circumstancesCtrl.text.trim(),

      'propertyPacked': _propertyPackedControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .join('\n---\n'),
      'propertyPackedList':
          _propertyPackedControllers.map((c) => c.text.trim()).toList(),

      'seizeDate': _seizeDateCombined,
      'seizeDateDay': _seizeDateDayCtrl.text.trim(),
      'seizeDateMonth': _seizeDateMonthCtrl.text.trim(),
      'seizeDateYear': _seizeDateYearCtrl.text.trim(),
      'seizeTime': _seizeTimeCombined,
      'seizeTimeHours': _seizeTimeHoursCtrl.text.trim(),
      'seizeTimeMinutes': _seizeTimeMinutesCtrl.text.trim(),
      'seizeTimeToHours': _seizeTimeToHoursCtrl.text.trim(),
      'seizeTimeToMinutes': _seizeTimeToMinutesCtrl.text.trim(),
      'seizeTimeFrom': fromTime,
      'seizeTimeTo': toTime,

      'witness1Line1': _witness1Line1Ctrl.text.trim(),
      'witness1Line2': _witness1Line2Ctrl.text.trim(),
      'witness1Line3': _witness1Line3Ctrl.text.trim(),
      'witness1Sig': _witness1SigCtrl.text.trim(),
      'witness2Line1': _witness2Line1Ctrl.text.trim(),
      'witness2Line2': _witness2Line2Ctrl.text.trim(),
      'witness2Line3': _witness2Line3Ctrl.text.trim(),
      'witness2Sig': _witness2SigCtrl.text.trim(),

      'sealSampleDate': _sealSampleDateCombined,
      'sealSampleDateDay': _sealSampleDateDayCtrl.text.trim(),
      'sealSampleDateMonth': _sealSampleDateMonthCtrl.text.trim(),
      'sealSampleDateYear': _sealSampleDateYearCtrl.text.trim(),

      'seizedPersonSig': _seizedPersonSigCtrl.text.trim(),

      'ioName': _ioNameCtrl.text.trim(),
      'ioRank': _ioRankCtrl.text.trim(),
      'ioNo': _ioNoCtrl.text.trim(),
      'ioPosting': _ioPostingCtrl.text.trim(),
      'ioSig': _ioSigCtrl.text.trim(),
    };
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD METHOD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final serifStyle = FormTypography.serifStyle();
    final marathiLabelStyle = FormTypography.marathiLabelStyle();

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        // ─────────────────────────────────────────────────────────────────
        // PAGE 1: Sections 1–10 (Search Seizure Form)
        // ─────────────────────────────────────────────────────────────────
        if (_shows(kSearchForm)) ...[
          FormPaperPage(
            formLabel: 'Page 1 — Search Seizure Form (§§ 1–10)',
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    Text(
                      'HOUSE/PROPERTY SEARCH & SEIZURI FORM',
                      style: serifStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'घरझडती पंचनामा/ मालमत्ता शोध व जप्तीचा पंचनामा',
                      style: marathiLabelStyle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '(Search/Production/Recovery U/s 185 B.N.S.S. 2023)',
                      style: serifStyle.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '(कलम १८५ भारतीय नागरी संरक्षण अधिनियम २०२३ अन्वये झडती/हजर करणे/परत मिळवणे)',
                      style: marathiLabelStyle.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _buildDashedDivider(),
              const SizedBox(height: 12),

              // 1) District, P.S., Year, FIR No, Date
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 12,
                runSpacing: 8,
                children: [
                  // District
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('1) District:', style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                          Text('जिल्हा', style: marathiLabelStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 90,
                        child: BilingualSimpleUnderlineInput(
                          controller: _distCtrl,
                          serifStyle: serifStyle,
                        ),
                      ),
                    ],
                  ),
                  // P.S.
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('P.S.:', style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                          Text('पोलीस स्टेशन', style: marathiLabelStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 110,
                        child: BilingualSimpleUnderlineInput(
                          controller: _psCtrl,
                          serifStyle: serifStyle,
                        ),
                      ),
                    ],
                  ),
                  // Year
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Year:---------', style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                          Text('वर्ष', style: marathiLabelStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 55,
                        child: BilingualSimpleUnderlineInput(
                          controller: _yearCtrl,
                          serifStyle: serifStyle,
                          hintText: 'YYYY',
                        ),
                      ),
                    ],
                  ),
                  // FIR No
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('FIR No:---------', style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                          Text('पहिली खबर क्र.', style: marathiLabelStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 55,
                        child: BilingualSimpleUnderlineInput(
                          controller: _firNoCtrl,
                          serifStyle: serifStyle,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text('/20', style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(
                        width: 35,
                        child: BilingualSimpleUnderlineInput(
                          controller: _firYearSuffixCtrl,
                          serifStyle: serifStyle,
                          hintText: 'YY',
                        ),
                      ),
                    ],
                  ),
                  // Date
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date:...../......./20.......', style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                          Text('तारीख', style: marathiLabelStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 34,
                        child: BilingualSimpleUnderlineInput(
                          controller: _headerDateDayCtrl,
                          serifStyle: serifStyle,
                          hintText: 'DD',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text('/', style: serifStyle),
                      ),
                      SizedBox(
                        width: 34,
                        child: BilingualSimpleUnderlineInput(
                          controller: _headerDateMonthCtrl,
                          serifStyle: serifStyle,
                          hintText: 'MM',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text('/20', style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(
                        width: 34,
                        child: BilingualSimpleUnderlineInput(
                          controller: _headerDateYearCtrl,
                          serifStyle: serifStyle,
                          hintText: 'YY',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 2) Act and Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2) Act and Section: -',
                    style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'अधिनियम व कलमे :-',
                    style: marathiLabelStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  BilingualSimpleUnderlineInput(
                    controller: _actSectionsCtrl,
                    serifStyle: serifStyle,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 3) Nature of property seized/Recover
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '3) *Nature of property seized/Recover: Stolen/Unclaimed/Unlawful procession/Involved/Intestate.',
                    style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'जप्त केलेल्या / मिळवलेल्या मालमत्तेचे स्वरूप: चोरीला गेलेली / बेवारशी / बेकायदेशीर ताबा / अंतर्भूत / मृत्युपत्राशिवाय',
                    style: marathiLabelStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  if (!widget.readOnly)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        'चोरीला गेलेली (Stolen)',
                        'बेवारशी (Unclaimed)',
                        'बेकायदेशीर ताबा (Unlawful)',
                        'अंतर्भूत (Involved)',
                        'मृत्युपत्राशिवाय (Intestate)',
                      ].map((chip) {
                        return ActionChip(
                          visualDensity: VisualDensity.compact,
                          label: Text(chip, style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            setState(() {
                              _naturePropertyCtrl.text = chip;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 4),
                  BilingualSimpleUnderlineInput(
                    controller: _naturePropertyCtrl,
                    serifStyle: serifStyle,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 4) Name And Address of accused & sub-fields
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '4) Name And Address of accused :',
                    style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'आरोपीचे नांव व पत्ता',
                    style: marathiLabelStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  BilingualSimpleUnderlineInput(
                    controller: _accusedNameAddressCtrl,
                    serifStyle: serifStyle,
                  ),
                  const SizedBox(height: 10),

                  // (a) Place from where seized/recovered
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '(a) Place from where seized/recovered :-',
                          style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'जेथून जप्त केली / परत मिळवली ती जागा :',
                          style: marathiLabelStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        BilingualSimpleUnderlineInput(
                          controller: _placeSeizedCtrl,
                          serifStyle: serifStyle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // (b) Description of the place of seizure/recovery
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '(b) Description of the place of seizure/recovery :',
                          style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'जप्तीच्या परत मिळवण्याच्या जागेचे वर्णन /चतुः सिमा',
                          style: marathiLabelStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        BilingualDynamicLinedTextField(
                          controller: _placeDescriptionCtrl,
                          minLines: 3,
                          serifStyle: serifStyle,
                          marathiLabelStyle: marathiLabelStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 5) Person from whom seized
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '5) Person form whom seized - (ज्याच्याकडून जप्त केली) :-',
                    style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // *Professional Receiver of Stolen Property
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '*Professional Receiver of Stolen Property: -   Yes/No.',
                            style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'चोरीचा माल घेणारा सराईत                     :-   होय/ नाही',
                            style: marathiLabelStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: BilingualSimpleUnderlineInput(
                          controller: _profReceiverCtrl,
                          serifStyle: serifStyle,
                          hintText: 'होय / नाही',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Name, Father's Name, Sex
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Name : -', style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                            Text('नांव', style: marathiLabelStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                            BilingualSimpleUnderlineInput(
                              controller: _personNameCtrl,
                              serifStyle: serifStyle,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Father's/Husband's Name :", style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                            Text('वडील/ पतीचे नांव', style: marathiLabelStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                            BilingualSimpleUnderlineInput(
                              controller: _personFatherCtrl,
                              serifStyle: serifStyle,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sex', style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                            Text('लिंग', style: marathiLabelStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                            BilingualSimpleUnderlineInput(
                              controller: _personSexCtrl,
                              serifStyle: serifStyle,
                              hintText: 'M/F',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Age, Occupation, Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 60,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Age :', style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                            Text('वय', style: marathiLabelStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                            BilingualSimpleUnderlineInput(
                              controller: _personAgeCtrl,
                              serifStyle: serifStyle,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 120,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Occupation :', style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                            Text('व्यवसाय', style: marathiLabelStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                            BilingualSimpleUnderlineInput(
                              controller: _personOccupationCtrl,
                              serifStyle: serifStyle,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Address :', style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                            Text('पत्ता', style: marathiLabelStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                            BilingualSimpleUnderlineInput(
                              controller: _personAddressCtrl,
                              serifStyle: serifStyle,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  BilingualSimpleUnderlineInput(
                    controller: _personAddressLine2Ctrl,
                    serifStyle: serifStyle,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 6) Action taken/recommended for disposal of perishable property
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '6) Action taken/recommended for disposal of perishable property:',
                    style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'नाशवंत मालमत्तेच्या विल्हेवाटीसाठी केलेली शिफारस / केलेली कार्यवाही :',
                    style: marathiLabelStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  BilingualSimpleUnderlineInput(
                    controller: _perishableDisposalCtrl,
                    serifStyle: serifStyle,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 7) Action taken/recommended for keeping of valuable property
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '7) Action taken/recommended for keeping of valuable property :-',
                    style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'मौल्यवान मालमत्ता ठेवण्यासाठी केलेली शिफारस / केलेली कार्यवाही :',
                    style: marathiLabelStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  BilingualSimpleUnderlineInput(
                    controller: _valuableKeepingCtrl,
                    serifStyle: serifStyle,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 8) Identification repuired
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '8) Identification repuired   : -   Yes / No.',
                        style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'ओळख पटवावी लागली काय     : -   होय/ नाही',
                        style: marathiLabelStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: BilingualSimpleUnderlineInput(
                      controller: _identificationRequiredCtrl,
                      serifStyle: serifStyle,
                      hintText: 'होय / नाही',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 9) Details of property seized/recovered
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '9) Details of property seized/recovered (Use prescribed form (8) and attach):',
                    style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'जप्त केलेल्या / परत मिळालेल्या मालाचे वर्णन (योग्य नमुन्यात माहिती भरा व जोडा) :',
                    style: marathiLabelStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  BilingualSimpleUnderlineInput(
                    controller: _propertyDetailsCtrl,
                    serifStyle: serifStyle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '(1) (Attach separate sheet, if required) :-',
                    style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  BilingualSimpleUnderlineInput(
                    controller: _propertyDetailsAttachCtrl,
                    serifStyle: serifStyle,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 10) Circumstances/Grounds for seizures
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '10) Circumstances/Grounds for seizures :-',
                    style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'जप्तीची परिस्थिती / कारणे :',
                    style: marathiLabelStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  BilingualDynamicLinedTextField(
                    controller: _circumstancesCtrl,
                    minLines: 3,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Bottom Right Footer
              Align(
                alignment: Alignment.centerRight,
                child: Text('M.R.W', style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
        ],

        if (_shows(kSearchForm) && (_shows(kPanchanama) || _showAll))
          const SizedBox(height: 24),

        // ─────────────────────────────────────────────────────────────────
        // PAGE 2: Sections 11–16 (Search Seizure Panchanama)
        // ─────────────────────────────────────────────────────────────────
        if (_shows(kPanchanama)) ...[
          FormPaperPage(
            formLabel: 'Page 2 — Search Seizure Panchanama (§§ 11–16)',
            children: [
              // 11) Clause
              Text(
                '11) The above mentioned properties were seized in accordance with the provisions of law in the presence of the below said witnesses** and a copy of the seizure memo was given to the person/the occupant of the place from whom seized.',
                style: serifStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w600, height: 1.4),
              ),
              const SizedBox(height: 2),
              Text(
                'वर नमूद करण्यात आलेली मालमत्ता पुढील साक्षीदारांच्या समक्ष कायद्यातील तरतुदींनुसार जप्त करण्यात आली,** आणि जप्तीच्या सूचनांची प्रत ज्यांच्याकडून मालमत्ता जप्त करण्यात आली त्या इसमास/ जागेत राहणाऱ्यास देण्यात आली.',
                style: marathiLabelStyle.copyWith(fontSize: 11, height: 1.4),
              ),
              const SizedBox(height: 16),

              // 12) Clause
              Text(
                '12) The following properties were packed and/of sealed and the signature of the below said witnesses obtained thereon or on the body of the property.',
                style: serifStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w600, height: 1.4),
              ),
              const SizedBox(height: 2),
              Text(
                'खालील मालमत्ता अबंधिष्ठित आणि/ किंवा मोहरबंद करण्यात आली आणि त्यावर किंवा मालमत्तेवर पुढील साक्षीदारांच्या सह्या घेण्यात आल्या.',
                style: marathiLabelStyle.copyWith(fontSize: 11, height: 1.4),
              ),
              const SizedBox(height: 12),

              // Table: Sr.No. (1) | Property/ मालमत्ता (2)
              Table(
                border: TableBorder.all(color: Colors.black87, width: 1.2),
                columnWidths: {
                  0: const FixedColumnWidth(70),
                  1: const FlexColumnWidth(),
                  if (!widget.readOnly) 2: const FixedColumnWidth(48),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade100),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        child: Column(
                          children: [
                            Text('Sr.No.', style: serifStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold)),
                            Text('अनु.क्र', style: marathiLabelStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                            Text('1', style: serifStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Property/ मालमत्ता', style: serifStyle.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text('2', style: serifStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      if (!widget.readOnly) const SizedBox(),
                    ],
                  ),
                  for (var i = 0; i < _propertyPackedControllers.length; i++)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            '${i + 1}',
                            style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: TextField(
                            controller: _propertyPackedControllers[i],
                            readOnly: widget.readOnly,
                            maxLines: null,
                            style: serifStyle.copyWith(fontSize: 12),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: 'मालमत्तेचे तपशील...',
                            ),
                          ),
                        ),
                        if (!widget.readOnly)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            onPressed: _propertyPackedControllers.length > 1
                                ? () {
                                    setState(() {
                                      _propertyPackedControllers.removeAt(i).dispose();
                                    });
                                  }
                                : null,
                          ),
                      ],
                    ),
                ],
              ),
              if (!widget.readOnly) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _propertyPackedControllers.add(TextEditingController());
                      });
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('मालमत्ता जोडा (+ Add Property Row)'),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // 13) Property seized Date & Time
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 16,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('13) Property seized : (a) Date :', style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                          Text('जप्त केलेली मालमत्ता   दिनांक', style: marathiLabelStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 34,
                        child: BilingualSimpleUnderlineInput(
                          controller: _seizeDateDayCtrl,
                          serifStyle: serifStyle,
                          hintText: 'DD',
                        ),
                      ),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Text('/', style: serifStyle)),
                      SizedBox(
                        width: 34,
                        child: BilingualSimpleUnderlineInput(
                          controller: _seizeDateMonthCtrl,
                          serifStyle: serifStyle,
                          hintText: 'MM',
                        ),
                      ),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Text('/20', style: serifStyle.copyWith(fontWeight: FontWeight.bold))),
                      SizedBox(
                        width: 34,
                        child: BilingualSimpleUnderlineInput(
                          controller: _seizeDateYearCtrl,
                          serifStyle: serifStyle,
                          hintText: 'YY',
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('(b) Time :', style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                          Text('वेळ', style: marathiLabelStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 32,
                        child: BilingualSimpleUnderlineInput(
                          controller: _seizeTimeHoursCtrl,
                          serifStyle: serifStyle,
                          hintText: 'HH',
                        ),
                      ),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 1), child: Text(':', style: serifStyle)),
                      SizedBox(
                        width: 32,
                        child: BilingualSimpleUnderlineInput(
                          controller: _seizeTimeMinutesCtrl,
                          serifStyle: serifStyle,
                          hintText: 'MM',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          children: [
                            Text('to', style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                            Text('ते', style: marathiLabelStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        child: BilingualSimpleUnderlineInput(
                          controller: _seizeTimeToHoursCtrl,
                          serifStyle: serifStyle,
                          hintText: 'HH',
                        ),
                      ),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 1), child: Text(':', style: serifStyle)),
                      SizedBox(
                        width: 32,
                        child: BilingualSimpleUnderlineInput(
                          controller: _seizeTimeToMinutesCtrl,
                          serifStyle: serifStyle,
                          hintText: 'MM',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // 14) witness —
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('14) witness –', style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                            Text('साक्षीदारांचे नांव व पत्ता', style: marathiLabelStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Signature:', style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                            Text('सह्या', style: marathiLabelStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Witness 1
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('1) ', style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: BilingualSimpleUnderlineInput(
                                    controller: _witness1Line1Ctrl,
                                    serifStyle: serifStyle,
                                    hintText: 'नाव व पत्ता (Line 1)',
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 18),
                              child: BilingualSimpleUnderlineInput(
                                controller: _witness1Line2Ctrl,
                                serifStyle: serifStyle,
                                hintText: 'पत्ता (Line 2)',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 4,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('1) ', style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: BilingualSimpleUnderlineInput(
                                controller: _witness1SigCtrl,
                                serifStyle: serifStyle,
                                hintText: 'सही / Signature',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Witness 2
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('2) ', style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: BilingualSimpleUnderlineInput(
                                    controller: _witness2Line1Ctrl,
                                    serifStyle: serifStyle,
                                    hintText: 'नाव व पत्ता (Line 1)',
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 18),
                              child: BilingualSimpleUnderlineInput(
                                controller: _witness2Line2Ctrl,
                                serifStyle: serifStyle,
                                hintText: 'पत्ता (Line 2)',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 4,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('2) ', style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: BilingualSimpleUnderlineInput(
                                controller: _witness2SigCtrl,
                                serifStyle: serifStyle,
                                hintText: 'सही / Signature',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 15 & 16 / Investigation Officer Block (Two Columns)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column: 15) शिक्क्याचा नमुना & 16) ज्याच्याकडून माल जप्त केला त्याची सही
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 15
                        Text(
                          '15) शिक्क्याचा नमुना :-',
                          style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('दिनांक :- ', style: marathiLabelStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                            SizedBox(
                              width: 32,
                              child: BilingualSimpleUnderlineInput(
                                controller: _sealSampleDateDayCtrl,
                                serifStyle: serifStyle,
                                hintText: 'DD',
                              ),
                            ),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 1), child: Text('/', style: serifStyle)),
                            SizedBox(
                              width: 32,
                              child: BilingualSimpleUnderlineInput(
                                controller: _sealSampleDateMonthCtrl,
                                serifStyle: serifStyle,
                                hintText: 'MM',
                              ),
                            ),
                            Padding(padding: const EdgeInsets.symmetric(horizontal: 1), child: Text('/२०', style: marathiLabelStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold))),
                            SizedBox(
                              width: 32,
                              child: BilingualSimpleUnderlineInput(
                                controller: _sealSampleDateYearCtrl,
                                serifStyle: serifStyle,
                                hintText: 'YY',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 16
                        Text(
                          '16) ज्याच्याकडून माल जप्त केला त्याची सही',
                          style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Signature: ', style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: BilingualSimpleUnderlineInput(
                                controller: _seizedPersonSigCtrl,
                                serifStyle: serifStyle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Right column: Signature of Investigation Officer
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Signature of Investigation Officer',
                          style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          'तपासणी करणाऱ्या अधिकाऱ्याची नांव व सह्या',
                          style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                        const SizedBox(height: 8),

                        // Name
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Name:', style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                                Text('नाव', style: marathiLabelStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: BilingualSimpleUnderlineInput(
                                controller: _ioNameCtrl,
                                serifStyle: serifStyle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Rank & Number
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Rank:', style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                                Text('पद', style: marathiLabelStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              flex: 5,
                              child: BilingualSimpleUnderlineInput(
                                controller: _ioRankCtrl,
                                serifStyle: serifStyle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Number if any:', style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                                Text('अंमलदार नंबर', style: marathiLabelStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              flex: 4,
                              child: BilingualSimpleUnderlineInput(
                                controller: _ioNoCtrl,
                                serifStyle: serifStyle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Posting and Address
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Posting and Address:', style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                                Text('नेमणूक व पत्ता', style: marathiLabelStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: BilingualSimpleUnderlineInput(
                                controller: _ioPostingCtrl,
                                serifStyle: serifStyle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Footnote
              Text(
                '** In case the property is seized from such a place that no receipt is required to be given to anybody this portion of the sentence should be struck off.',
                style: serifStyle.copyWith(fontSize: 10, fontStyle: FontStyle.italic),
              ),
              Text(
                '** कोणालाही पोच पावती देण्याची आवश्यकता नसेल अशा जागेतून माल जप्त केला असेल हे वाक्य खोडून टाकावे.',
                style: marathiLabelStyle.copyWith(fontSize: 10),
              ),
              const SizedBox(height: 24),

              // Bottom Right Footer
              Align(
                alignment: Alignment.centerRight,
                child: Text('M.R.W', style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
