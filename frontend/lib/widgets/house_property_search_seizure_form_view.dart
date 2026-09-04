import 'package:flutter/material.dart';
import 'bilingual_field.dart';
import 'form_paper_page.dart';
import 'form_table_helpers.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';
import '../utils/form_io_terminology.dart';
import 'form_section_utils.dart';

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
  // Page 1
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

  // Page 3 / Seizure Date & Witnesses
  final List<TextEditingController> _propertyPackedControllers = [TextEditingController()];
  final _seizeDateCtrl = TextEditingController();
  final _seizeDateDayCtrl = TextEditingController();
  final _seizeDateMonthCtrl = TextEditingController();
  final _seizeDateYearCtrl = TextEditingController();
  final _seizeTimeFromCtrl = TextEditingController();
  final _seizeTimeToCtrl = TextEditingController();
  final _seizeTimeHoursCtrl = TextEditingController();
  final _seizeTimeMinutesCtrl = TextEditingController();
  final _witness1Line1Ctrl = TextEditingController();
  final _witness1Line2Ctrl = TextEditingController();
  final _witness1Line3Ctrl = TextEditingController();
  final _witness1SigCtrl = TextEditingController();
  final _witness2Line1Ctrl = TextEditingController();
  final _witness2Line2Ctrl = TextEditingController();
  final _witness2Line3Ctrl = TextEditingController();
  final _witness2SigCtrl = TextEditingController();
  final _witness1NameCtrl = TextEditingController();
  final _witness1FatherCtrl = TextEditingController();
  final _witness1SexCtrl = TextEditingController();
  final _witness1AgeCtrl = TextEditingController();
  final _witness1OccupationCtrl = TextEditingController();
  final _witness1AddressCtrl = TextEditingController();
  final _witness1AddressLine2Ctrl = TextEditingController();
  final _witness2NameCtrl = TextEditingController();
  final _witness2FatherCtrl = TextEditingController();
  final _witness2SexCtrl = TextEditingController();
  final _witness2AgeCtrl = TextEditingController();
  final _witness2OccupationCtrl = TextEditingController();
  final _witness2AddressCtrl = TextEditingController();
  final _witness2AddressLine2Ctrl = TextEditingController();
  final _sealSampleDateCtrl = TextEditingController();
  final _seizedPersonSigCtrl = TextEditingController();
  final _ioNameCtrl = TextEditingController();
  final _ioRankCtrl = TextEditingController();
  final _ioNoCtrl = TextEditingController();
  final _ioPostingCtrl = TextEditingController();

  String get _headerDateCombined {
    final d = _headerDateDayCtrl.text.trim();
    final m = _headerDateMonthCtrl.text.trim();
    final y = _headerDateYearCtrl.text.trim();
    if (d.isEmpty && m.isEmpty && y.isEmpty) {
      return _headerDateCtrl.text.trim();
    }
    final yFull = y.isNotEmpty ? (y.length == 2 ? '20$y' : y) : '';
    return '$d/$m/$yFull'.replaceAll(RegExp(r'/+$'), '');
  }

  String get _seizeDateCombined {
    final d = _seizeDateDayCtrl.text.trim();
    final m = _seizeDateMonthCtrl.text.trim();
    final y = _seizeDateYearCtrl.text.trim();
    if (d.isEmpty && m.isEmpty && y.isEmpty) {
      return _seizeDateCtrl.text.trim();
    }
    final yFull = y.isNotEmpty ? (y.length == 2 ? '20$y' : y) : '';
    return '$d/$m/$yFull'.replaceAll(RegExp(r'/+$'), '');
  }

  String get _seizeTimeCombined {
    final h = _seizeTimeHoursCtrl.text.trim();
    final m = _seizeTimeMinutesCtrl.text.trim();
    if (h.isEmpty && m.isEmpty) {
      return _seizeTimeFromCtrl.text.trim();
    }
    return '$h/$m';
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
    _witness1Line1Ctrl.dispose();
    _witness1Line2Ctrl.dispose();
    _witness1Line3Ctrl.dispose();
    _witness1SigCtrl.dispose();
    _witness2Line1Ctrl.dispose();
    _witness2Line2Ctrl.dispose();
    _witness2Line3Ctrl.dispose();
    _witness2SigCtrl.dispose();
    _witness1NameCtrl.dispose();
    _witness1FatherCtrl.dispose();
    _witness1SexCtrl.dispose();
    _witness1AgeCtrl.dispose();
    _witness1OccupationCtrl.dispose();
    _witness1AddressCtrl.dispose();
    _witness1AddressLine2Ctrl.dispose();
    _witness2NameCtrl.dispose();
    _witness2FatherCtrl.dispose();
    _witness2SexCtrl.dispose();
    _witness2AgeCtrl.dispose();
    _witness2OccupationCtrl.dispose();
    _witness2AddressCtrl.dispose();
    _witness2AddressLine2Ctrl.dispose();
    _sealSampleDateCtrl.dispose();
    _seizedPersonSigCtrl.dispose();
    _ioNameCtrl.dispose();
    _ioRankCtrl.dispose();
    _ioNoCtrl.dispose();
    _ioPostingCtrl.dispose();
    super.dispose();
  }

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
      if (data['propertyPackedList'] is List && (data['propertyPackedList'] as List).isNotEmpty) {
        for (final c in _propertyPackedControllers) {
          c.dispose();
        }
        _propertyPackedControllers.clear();
        for (final item in (data['propertyPackedList'] as List)) {
          _propertyPackedControllers.add(TextEditingController(text: item?.toString() ?? ''));
        }
      } else if (data['propertyPacked'] != null && data['propertyPacked'].toString().isNotEmpty) {
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
      if (_seizeTimeHoursCtrl.text.isEmpty && _seizeTimeFromCtrl.text.isNotEmpty) {
        final parts = _seizeTimeFromCtrl.text.split(RegExp(r'[/.:]'));
        if (parts.length >= 2) {
          _seizeTimeHoursCtrl.text = parts[0].trim();
          _seizeTimeMinutesCtrl.text = parts[1].trim();
        }
      }
      set(_witness1Line1Ctrl, 'witness1Line1');
      set(_witness1Line2Ctrl, 'witness1Line2');
      set(_witness1Line3Ctrl, 'witness1Line3');
      set(_witness1SigCtrl, 'witness1Sig');
      set(_witness2Line1Ctrl, 'witness2Line1');
      set(_witness2Line2Ctrl, 'witness2Line2');
      set(_witness2Line3Ctrl, 'witness2Line3');
      set(_witness2SigCtrl, 'witness2Sig');
      set(_witness1NameCtrl, 'witness1Name');
      set(_witness1FatherCtrl, 'witness1Father');
      set(_witness1SexCtrl, 'witness1Sex');
      set(_witness1AgeCtrl, 'witness1Age');
      set(_witness1OccupationCtrl, 'witness1Occupation');
      set(_witness1AddressCtrl, 'witness1Address');
      set(_witness1AddressLine2Ctrl, 'witness1AddressLine2');
      set(_witness2NameCtrl, 'witness2Name');
      set(_witness2FatherCtrl, 'witness2Father');
      set(_witness2SexCtrl, 'witness2Sex');
      set(_witness2AgeCtrl, 'witness2Age');
      set(_witness2OccupationCtrl, 'witness2Occupation');
      set(_witness2AddressCtrl, 'witness2Address');
      set(_witness2AddressLine2Ctrl, 'witness2AddressLine2');
      set(_sealSampleDateCtrl, 'sealSampleDate');
      set(_seizedPersonSigCtrl, 'seizedPersonSig');
      set(_ioNameCtrl, 'ioName');
      set(_ioRankCtrl, 'ioRank');
      set(_ioNoCtrl, 'ioNo');
      set(_ioPostingCtrl, 'ioPosting');
    });
  }

  Map<String, dynamic> collectData() {
    return {
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
      'witness1Name': _witness1NameCtrl.text.trim(),
      'witness1Father': _witness1FatherCtrl.text.trim(),
      'witness1Sex': _witness1SexCtrl.text.trim(),
      'witness1Age': _witness1AgeCtrl.text.trim(),
      'witness1Occupation': _witness1OccupationCtrl.text.trim(),
      'witness1Address': _witness1AddressCtrl.text.trim(),
      'witness1AddressLine2': _witness1AddressLine2Ctrl.text.trim(),
      'witness2Name': _witness2NameCtrl.text.trim(),
      'witness2Father': _witness2FatherCtrl.text.trim(),
      'witness2Sex': _witness2SexCtrl.text.trim(),
      'witness2Age': _witness2AgeCtrl.text.trim(),
      'witness2Occupation': _witness2OccupationCtrl.text.trim(),
      'witness2Address': _witness2AddressCtrl.text.trim(),
      'witness2AddressLine2': _witness2AddressLine2Ctrl.text.trim(),
      'perishableDisposal': _perishableDisposalCtrl.text.trim(),
      'valuableKeeping': _valuableKeepingCtrl.text.trim(),
      'identificationRequired': _identificationRequiredCtrl.text.trim(),
      'propertyDetails': _propertyDetailsCtrl.text.trim(),
      'propertyDetailsAttach': _propertyDetailsAttachCtrl.text.trim(),
      'circumstances': _circumstancesCtrl.text.trim(),
      'propertyPacked': _propertyPackedControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).join('\n---\n'),
      'propertyPackedList': _propertyPackedControllers.map((c) => c.text.trim()).toList(),
      'seizeDate': _seizeDateCombined,
      'seizeDateDay': _seizeDateDayCtrl.text.trim(),
      'seizeDateMonth': _seizeDateMonthCtrl.text.trim(),
      'seizeDateYear': _seizeDateYearCtrl.text.trim(),
      'seizeTime': _seizeTimeCombined,
      'seizeTimeHours': _seizeTimeHoursCtrl.text.trim(),
      'seizeTimeMinutes': _seizeTimeMinutesCtrl.text.trim(),
      'seizeTimeFrom': _seizeTimeFromCtrl.text.trim(),
      'seizeTimeTo': _seizeTimeToCtrl.text.trim(),
      'witness1Line1': _witness1Line1Ctrl.text.trim(),
      'witness1Line2': _witness1Line2Ctrl.text.trim(),
      'witness1Line3': _witness1Line3Ctrl.text.trim(),
      'witness1Sig': _witness1SigCtrl.text.trim(),
      'witness2Line1': _witness2Line1Ctrl.text.trim(),
      'witness2Line2': _witness2Line2Ctrl.text.trim(),
      'witness2Line3': _witness2Line3Ctrl.text.trim(),
      'witness2Sig': _witness2SigCtrl.text.trim(),
      'sealSampleDate': _sealSampleDateCtrl.text.trim(),
      'seizedPersonSig': _seizedPersonSigCtrl.text.trim(),
      'ioName': _ioNameCtrl.text.trim(),
      'ioRank': _ioRankCtrl.text.trim(),
      'ioNo': _ioNoCtrl.text.trim(),
      'ioPosting': _ioPostingCtrl.text.trim(),
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
    };
  }

  Widget _witnessBlock({
    required String number,
    required TextEditingController l1,
    required TextEditingController l2,
    required TextEditingController l3,
    required TextEditingController sig,
    required TextStyle serifStyle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              BilingualNumberedMethodField(number: number, controller: l1, serifStyle: serifStyle),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: BilingualSimpleUnderlineInput(controller: l2, serifStyle: serifStyle),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: BilingualSimpleUnderlineInput(controller: l3, serifStyle: serifStyle),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: BilingualNumberedMethodField(number: number, controller: sig, serifStyle: serifStyle),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle serifStyle = FormTypography.serifStyle();
    final TextStyle marathiLabelStyle = FormTypography.marathiLabelStyle();

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        if (_shows(kSearchForm)) ...[
              FormPaperPage(
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'PROPERTY SEACH & SEIZURE FORM',
                          style: serifStyle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'मालमत्ता शोध व जप्तीचा नमुना',
                          style: marathiLabelStyle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '(Search/ Production/ Recovery u/s 185 B.N.S.S)',
                          style: serifStyle.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '(कलम १८५ भारतीय नागरिक सुरक्षा संहिता २०२३ अन्वये झडती/हजर करणे/परत मिळविणे)',
                          style: marathiLabelStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDashedDivider(),
                  const SizedBox(height: 10),

                  // १) जिल्हा, पोलीस ठाणे, वर्ष, पहिली खबर क्र/कार्यवाही, दि.
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('१) *जिल्हा:', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 70,
                            child: BilingualSimpleUnderlineInput(
                              controller: _distCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('*पोलीस ठाणे:', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 90,
                            child: BilingualSimpleUnderlineInput(
                              controller: _psCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('वर्ष:', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 50,
                            child: BilingualSimpleUnderlineInput(
                              controller: _yearCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('*पहिली खबर क्र/कार्यवाही', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 50,
                            child: BilingualSimpleUnderlineInput(
                              controller: _firNoCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text('/', style: serifStyle),
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('*दि.', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 32,
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
                            width: 32,
                            child: BilingualSimpleUnderlineInput(
                              controller: _headerDateMonthCtrl,
                              serifStyle: serifStyle,
                              hintText: 'MM',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text('/२०', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(
                            width: 32,
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
                  const SizedBox(height: 10),

                  // २) अधिनियम व कलमे
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('२) अधिनियम व कलमे : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: BilingualSimpleUnderlineInput(
                          controller: _actSectionsCtrl,
                          serifStyle: serifStyle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ३) जप्त केलेले/मिळालेल्या मालमत्तेचे स्वरूप
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '३) *जप्त केलेले/मिळालेल्या मालमत्तेचे स्वरूप : चोरीला गेलेली/बेवारशी/बेकायदेशीर ताबा/अंतर्भूत/मृत्यू पत्राशिवाय.',
                        style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      BilingualSimpleUnderlineInput(
                        controller: _naturePropertyCtrl,
                        serifStyle: serifStyle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ४) जप्त केलेली मालमत्ता
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.end,
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          Text('४) जप्त केलेली मालमत्ता :', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('(अ) तारीख : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                              SizedBox(
                                width: 32,
                                child: BilingualSimpleUnderlineInput(
                                  controller: _seizeDateDayCtrl,
                                  serifStyle: serifStyle,
                                  hintText: 'DD',
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: Text('/', style: serifStyle),
                              ),
                              SizedBox(
                                width: 32,
                                child: BilingualSimpleUnderlineInput(
                                  controller: _seizeDateMonthCtrl,
                                  serifStyle: serifStyle,
                                  hintText: 'MM',
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: Text('/२०', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                              ),
                              SizedBox(
                                width: 32,
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
                              Text('(ब) वेळ : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                              SizedBox(
                                width: 32,
                                child: BilingualSimpleUnderlineInput(
                                  controller: _seizeTimeHoursCtrl,
                                  serifStyle: serifStyle,
                                  hintText: 'HH',
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: Text('/', style: serifStyle),
                              ),
                              SizedBox(
                                width: 32,
                                child: BilingualSimpleUnderlineInput(
                                  controller: _seizeTimeMinutesCtrl,
                                  serifStyle: serifStyle,
                                  hintText: 'MM',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('(क) जेथून जप्त केली/परत मिळवली ती जागा : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: BilingualSimpleUnderlineInput(
                              controller: _placeSeizedCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('(ड) जप्तींच्या/परत मिळवल्याच्या जागेचे वर्णन:', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      BilingualDynamicLinedTextField(
                        controller: _placeDescriptionCtrl,
                        minLines: 2,
                        serifStyle: serifStyle,
                        marathiLabelStyle: marathiLabelStyle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ५) कोणाकडून जप्त केली
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('५) कोणाकडून जप्त केली : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: BilingualSimpleUnderlineInput(
                              controller: _accusedNameAddressCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('*चोरीचा माल घेणारा धंदेवाईक : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 90,
                            child: BilingualSimpleUnderlineInput(
                              controller: _profReceiverCtrl,
                              serifStyle: serifStyle,
                              hintText: 'होय/नाही',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('नाव : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          Expanded(
                            flex: 4,
                            child: BilingualSimpleUnderlineInput(
                              controller: _personNameCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('पित्याचे/पतीचे नाव : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          Expanded(
                            flex: 4,
                            child: BilingualSimpleUnderlineInput(
                              controller: _personFatherCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('लिंग : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          SizedBox(
                            width: 50,
                            child: BilingualSimpleUnderlineInput(
                              controller: _personSexCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('वय : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          SizedBox(
                            width: 45,
                            child: BilingualSimpleUnderlineInput(
                              controller: _personAgeCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('व्यवसाय : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          SizedBox(
                            width: 100,
                            child: BilingualSimpleUnderlineInput(
                              controller: _personOccupationCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('पत्ता : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: BilingualSimpleUnderlineInput(
                              controller: _personAddressCtrl,
                              serifStyle: serifStyle,
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
                  const SizedBox(height: 10),

                  // ६) साक्षदार
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('६) साक्षदार', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      // Witness 1
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('(i) नाव : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          Expanded(
                            flex: 4,
                            child: BilingualSimpleUnderlineInput(
                              controller: _witness1NameCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('पित्याचे/पतीचे नाव : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          Expanded(
                            flex: 4,
                            child: BilingualSimpleUnderlineInput(
                              controller: _witness1FatherCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('लिंग : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          SizedBox(
                            width: 50,
                            child: BilingualSimpleUnderlineInput(
                              controller: _witness1SexCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('वय : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          SizedBox(
                            width: 45,
                            child: BilingualSimpleUnderlineInput(
                              controller: _witness1AgeCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('व्यवसाय : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          SizedBox(
                            width: 100,
                            child: BilingualSimpleUnderlineInput(
                              controller: _witness1OccupationCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('पत्ता : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: BilingualSimpleUnderlineInput(
                              controller: _witness1AddressCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      BilingualSimpleUnderlineInput(
                        controller: _witness1AddressLine2Ctrl,
                        serifStyle: serifStyle,
                      ),
                      const SizedBox(height: 12),
                      // Witness 2
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('(ii) नाव : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          Expanded(
                            flex: 4,
                            child: BilingualSimpleUnderlineInput(
                              controller: _witness2NameCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('पित्याचे/पतीचे नाव : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          Expanded(
                            flex: 4,
                            child: BilingualSimpleUnderlineInput(
                              controller: _witness2FatherCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('लिंग : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          SizedBox(
                            width: 50,
                            child: BilingualSimpleUnderlineInput(
                              controller: _witness2SexCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('वय : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          SizedBox(
                            width: 45,
                            child: BilingualSimpleUnderlineInput(
                              controller: _witness2AgeCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('व्यवसाय : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          SizedBox(
                            width: 100,
                            child: BilingualSimpleUnderlineInput(
                              controller: _witness2OccupationCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('पत्ता : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: BilingualSimpleUnderlineInput(
                              controller: _witness2AddressCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      BilingualSimpleUnderlineInput(
                        controller: _witness2AddressLine2Ctrl,
                        serifStyle: serifStyle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ७) नाशवंत मालमत्ता
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('७) नाशवंत मालमत्तेच्या विल्हेवाटीसाठी केलेली शिफारस/केलेली कार्यवाही : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: BilingualSimpleUnderlineInput(
                          controller: _perishableDisposalCtrl,
                          serifStyle: serifStyle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ८) मौल्यवान मालमत्ता
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('८) मौल्यवान मालमत्ता ठेवण्यासाठी केलेली शिफारस/केलेली कार्यवाही : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: BilingualSimpleUnderlineInput(
                          controller: _valuableKeepingCtrl,
                          serifStyle: serifStyle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ९) ओळख पटवावी लागली काय
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('९) ओळख पटवावी लागली काय : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 90,
                        child: BilingualSimpleUnderlineInput(
                          controller: _identificationRequiredCtrl,
                          serifStyle: serifStyle,
                          hintText: 'होय/नाही',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // १०) जप्त केलेल्या/परत मिळालेल्या मालाचे वर्णन
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('१०) जप्त केलेल्या/परत मिळालेल्या मालाचे वर्णन (योग्य नमुन्यात माहिती भरा व जोडा )', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      BilingualDynamicLinedTextField(
                        controller: _propertyDetailsCtrl,
                        minLines: 2,
                        serifStyle: serifStyle,
                        marathiLabelStyle: marathiLabelStyle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ११) जप्तीची परिस्थिती/कारणे
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('११) जप्तीची परिस्थिती/कारणे : ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      BilingualDynamicLinedTextField(
                        controller: _circumstancesCtrl,
                        minLines: 3,
                        serifStyle: serifStyle,
                        marathiLabelStyle: marathiLabelStyle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FormMrwFooter(serifStyle: serifStyle),
                ],
              ),
        ],
        if (_shows(kSearchForm) && (_shows(kPanchanama) || _showAll))
              const SizedBox(height: 24),
        if (_shows(kPanchanama))
              FormPaperPage(
                formLabel: widget.pageRange ?? 'Page 29',
                children: [
                  Text(
                    '11) The above mentioned properties were seized in accordance with the provisions of law in the presence of the below said witnesses** and a copy of the seizure memo was given to the person/occupant of the place from whom seized.',
                    style: serifStyle.copyWith(fontSize: 12),
                  ),
                  Text(
                    'वरील मालमत्ता खालील साक्षीदारांच्या समक्ष कायद्याच्या तरतुदीनुसार जप्त केली व ज्यांच्याकडून जप्त केली त्यांना/ त्या ठिकाणी राहणाऱ्यास जप्तीच्या पंचनाम्याची प्रत देण्यात आली.',
                    style: marathiLabelStyle.copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '12) The following properties were packed and/of sealed and the signature of the below said witnesses obtained thereon or on the body of the property.',
                    style: serifStyle.copyWith(fontSize: 12),
                  ),
                  Text(
                    'खालील मालमत्ता पोत्यात बंद/शिक्का मारून खालील साक्षीदारांची सही घेण्यात आली.',
                    style: marathiLabelStyle.copyWith(fontSize: 10),
                  ),
                  const SizedBox(height: 8),
                  Table(
                    border: TableBorder.all(color: Colors.black87),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: {
                      0: const FixedColumnWidth(60),
                      1: const FlexColumnWidth(1),
                      if (!widget.readOnly) 2: const FixedColumnWidth(50),
                    },
                    children: [
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(
                              'Sr.No.\nअनु.क्र',
                              style: serifStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(
                              'Property/ मालमत्ता',
                              style: serifStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (!widget.readOnly)
                            Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text(
                                'Action\nकृती',
                                style: serifStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                      ...List.generate(_propertyPackedControllers.length, (index) {
                        final ctrl = _propertyPackedControllers[index];
                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                              child: Text(
                                '${index + 1}',
                                style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(4),
                              child: BilingualDynamicLinedTextField(
                                controller: ctrl,
                                minLines: 1,
                                serifStyle: serifStyle,
                              ),
                            ),
                            if (!widget.readOnly)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Center(
                                  child: _propertyPackedControllers.length > 1
                                      ? IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                          tooltip: 'Remove Row (ओळ काढा)',
                                          onPressed: () {
                                            setState(() {
                                              final removed = _propertyPackedControllers.removeAt(index);
                                              removed.dispose();
                                            });
                                          },
                                        )
                                      : const SizedBox(height: 28),
                                ),
                              ),
                          ],
                        );
                      }),
                    ],
                  ),
                  if (!widget.readOnly) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _propertyPackedControllers.add(TextEditingController());
                            });
                          },
                          icon: const Icon(Icons.add, size: 16, color: Color(0xFF1E3A8A)),
                          label: Text(
                            'Add Row (ओळ जोडा)',
                            style: TextStyle(
                              fontFamily: serifStyle.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E3A8A),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFEFF4FA),
                            side: const BorderSide(color: Color(0xFFD6E4F0), width: 1),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                        if (_propertyPackedControllers.length > 1) ...[
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                final last = _propertyPackedControllers.removeLast();
                                last.dispose();
                              });
                            },
                            icon: const Icon(Icons.remove, size: 16, color: Color(0xFFB91C1C)),
                            label: Text(
                              'Remove Row (ओळ काढा)',
                              style: TextStyle(
                                fontFamily: serifStyle.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFB91C1C),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFFEEFEE),
                              side: const BorderSide(color: Color(0xFFFCDADA), width: 1),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  BilingualFieldRow(fields: [
                    BilingualField(label: '13) Property seized : (a) Date : ', marathiLabel: 'जप्त केलेली मालमत्ता दिनांक', controller: _seizeDateCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                    BilingualField(label: '(b) Time : ', marathiLabel: 'वेळ', controller: _seizeTimeFromCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                    BilingualField(label: 'To : ', marathiLabel: 'ते', controller: _seizeTimeToCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                  ]),
                  const SizedBox(height: 12),
                  BilingualSectionHeader(
                    label: '14) witness — / Signature:',
                    marathiLabel: 'साक्षीदारांचे नांव व पत्ता / सह्या',
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                  const SizedBox(height: 8),
                  _witnessBlock(number: '1', l1: _witness1Line1Ctrl, l2: _witness1Line2Ctrl, l3: _witness1Line3Ctrl, sig: _witness1SigCtrl, serifStyle: serifStyle),
                  const SizedBox(height: 12),
                  _witnessBlock(number: '2', l1: _witness2Line1Ctrl, l2: _witness2Line2Ctrl, l3: _witness2Line3Ctrl, sig: _witness2SigCtrl, serifStyle: serifStyle),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BilingualField(label: '15) शिक्याचा नमुना :- Date : ', marathiLabel: 'दिनांक', controller: _sealSampleDateCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                            const SizedBox(height: 12),
                            BilingualField(
                              label: '16) Signature of person from whom seized : ',
                              marathiLabel: 'ज्यांच्याकडून माल जप्त केला त्याची सही',
                              controller: _seizedPersonSigCtrl,
                              serifStyle: serifStyle,
                              marathiLabelStyle: marathiLabelStyle,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BilingualSectionHeader(
                              label: FormIoTerminology.englishSignatureHeader,
                              marathiLabel: FormIoTerminology.signatureHeader,
                              serifStyle: serifStyle,
                              marathiLabelStyle: marathiLabelStyle,
                            ),
                            const SizedBox(height: 8),
                            BilingualField(label: 'Name: ', marathiLabel: FormIoTerminology.name, controller: _ioNameCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                            BilingualFieldRow(fields: [
                              BilingualField(label: 'Rank: ', marathiLabel: FormIoTerminology.rank, controller: _ioRankCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                              BilingualField(label: 'Number if any: ', marathiLabel: 'बक्कल नंबर', controller: _ioNoCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                            ]),
                            BilingualWideField(label: 'Posting and Address: ', marathiLabel: 'नेमणूक व पत्ता', controller: _ioPostingCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '** In case the property is seized from such a place that no receipt is required to be given to anybody this portion of the sentence should be struck off.',
                    style: serifStyle.copyWith(fontSize: 9, fontStyle: FontStyle.italic),
                  ),
                  Text(
                    'जर मालमत्ता अशा ठिकाणीून जप्त केली की कोणालाही पावती देण्याची आवश्यकता नसेल तर वाक्याचा हा भाग काढून टाकावा.',
                    style: marathiLabelStyle.copyWith(fontSize: 9),
                  ),
                  const SizedBox(height: 8),
                  FormMrwFooter(serifStyle: serifStyle),
                ],
              ),
            ],
    );
  }
}
