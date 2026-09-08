import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bilingual_field.dart';
import 'form_paper_page.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';
import 'responsive_field_row.dart';
import 'form_section_utils.dart';

class FinalReportFormView extends StatefulWidget {
  final bool readOnly;
  final Map<String, dynamic>? existingRecord;
  final String? formSection;
  final String? pageRange;

  const FinalReportFormView({
    super.key,
    this.readOnly = false,
    this.existingRecord,
    this.formSection,
    this.pageRange,
  });

  @override
  State<FinalReportFormView> createState() => FinalReportFormViewState();
}

class FinalReportFormViewState extends State<FinalReportFormView> {
  static const kPartI = 'Final Report Part I';
  static const kPartII = 'Final Report Part II';
  static const kPartIII = 'Final Report Part III';
  static const kPartIV = 'Final Report Part IV';
  static const _knownSectionIds = {kPartI, kPartII, kPartIII, kPartIV};

  bool _shows(String sectionId) => showsFormSection(
        activeSection: widget.formSection,
        sectionId: sectionId,
        knownSectionIds: _knownSectionIds,
      );

  bool get _showAll => showsAllFormSections(
        activeSection: widget.formSection,
        knownSectionIds: _knownSectionIds,
      );

  // ─── PAGE 1 CONTROLLERS (Sections 1–10) ──────────────────────────────────
  final _courtCtrl = TextEditingController();
  final _courtDistCtrl = TextEditingController(text: 'यवतमाळ');
  final _distCtrl = TextEditingController(text: 'यवतमाळ');
  final _psCtrl = TextEditingController();
  final _yearCtrl = TextEditingController(text: '24');
  final _firNoCtrl = TextEditingController();
  final _firYearSuffixCtrl = TextEditingController(text: '२०२४');
  final _headerDateCtrl = TextEditingController();
  final _reportNoCtrl = TextEditingController();
  final _reportYearSuffixCtrl = TextEditingController(text: '20');
  final _reportDateCtrl = TextEditingController();
  final _actCtrl = TextEditingController(text: 'भारतीय न्याय संहिता २०२३');
  final _sectionCtrl = TextEditingController();
  final _reportTypeCtrl = TextEditingController();
  final _reportTypeCustomCtrl =
      TextEditingController(text: 'आरोपपत्र दाखल केले');
  final _frUnoccurredCtrl = TextEditingController();
  final _chargeSheetedCtrl = TextEditingController(text: 'होय');
  final _originalSupplementaryCtrl = TextEditingController(text: 'मुळ');
  final _ioNameCtrl = TextEditingController();
  final _ioRankCtrl = TextEditingController();
  final _ioNoCtrl = TextEditingController();
  final _ioPsCtrl = TextEditingController();
  final _complainantNameCtrl = TextEditingController();
  final _complainantFatherCtrl = TextEditingController();

  int _propertyRowCount = 2;
  late final List<TextEditingController> _propDescCtrls;
  late final List<TextEditingController> _propValueCtrls;
  late final List<TextEditingController> _propRegCtrls;
  late final List<TextEditingController> _propFromCtrls;
  late final List<TextEditingController> _propDisposalCtrls;

  // ─── PAGE 2 CONTROLLERS (Sections 11–12) ─────────────────────────────────
  final _accNameCtrl = TextEditingController();
  final _accNameVerifiedCtrl = TextEditingController();
  final _accFatherCtrl = TextEditingController();
  final _accDobCtrl = TextEditingController();
  final _accAgeCtrl = TextEditingController();
  final _accSexCtrl = TextEditingController();
  final _accNationalityCtrl = TextEditingController();
  final _accPassportCtrl = TextEditingController(text: '---');
  final _accPassportDateCtrl = TextEditingController(text: '----');
  final _accPassportPlaceCtrl = TextEditingController(text: '----');
  final _accReligionCtrl = TextEditingController();
  final _accScStCtrl = TextEditingController(text: '--- --');
  final _accOccupationCtrl = TextEditingController();
  final _accAddressCtrl = TextEditingController();
  final _accAddressVerifiedCtrl = TextEditingController(text: 'होय');
  final _accProvCriminalNoCtrl = TextEditingController(text: '-----');
  final _accRegularCriminalNoCtrl = TextEditingController(text: '----');
  final _accArrestDateCtrl = TextEditingController();
  final _accArrestTimeCtrl = TextEditingController();
  final _accBailDateCtrl = TextEditingController();
  final _accForwardedCourtCtrl = TextEditingController(text: '-निरंक');
  final _accActsSectionsCtrl = TextEditingController();
  final _accBailersCtrl = TextEditingController();
  final _accPrevConvictionsCtrl = TextEditingController(text: '----');
  final _accStatusCtrl = TextEditingController(text: 'सुचनापत्र दिले.');
  final _notChargeSheetedCtrl = TextEditingController();

  // ─── PAGE 3 CONTROLLERS (Sections 13–15) ─────────────────────────────────
  final _witnessDescCtrl = TextEditingController();
  int _witnessRowCount = 7;
  late final List<TextEditingController> _witnessNameCtrls;
  late final List<TextEditingController> _witnessAgeCtrls;
  late final List<TextEditingController> _witnessOccupationCtrls;
  late final List<TextEditingController> _witnessAddressCtrls;
  late final List<TextEditingController> _witnessEvidenceCtrls;

  static const List<String> _defaultWitnessEvidence = [
    'तक्रारदार/ साक्षीदार',
    'पंच क्रमांक १',
    'पंच क्रमांक २',
    'साक्षीदार',
    'साक्षीदार',
    'गुन्हा दाखल करणार अधिकारी',
    'तपासी अधिकारी',
  ];

  static const List<String> _marathiNumbers = [
    '1.',
    '२.',
    '३.',
    '४.',
    '५.',
    '६.',
    '७.',
    '८.',
    '९.',
    '१०.',
  ];

  final _falseFirActionCtrl = TextEditingController();
  final _labAnalysisCtrl = TextEditingController(text: 'निरंक');

  // ─── PAGE 4 CONTROLLERS (Sections 16–18 & Signatures) ────────────────────
  final _briefFactsCtrl = TextEditingController();
  final _referNoticeServedCtrl = TextEditingController(text: 'Yes / No :');
  final _referNoticeDateCtrl = TextEditingController(text: '/ /2024');
  final _dispatchedOnCtrl = TextEditingController();
  final _shoNameCtrl = TextEditingController(text: 'श्री. संदिप नरसाळे');
  final _shoRankCtrl = TextEditingController(text: 'सहायक पोलीस निरीक्षक');
  final _shoNoCtrl = TextEditingController();
  final _shoPsCtrl = TextEditingController(text: 'पोलीस स्टेशन पारवा');
  final _submitIoNameCtrl =
      TextEditingController(text: 'श्री. गजानन दशरथ शेजुळकर');
  final _submitIoRankCtrl = TextEditingController(text: 'पोलीस उपनिरीक्षक');
  final _submitIoNoCtrl = TextEditingController(text: '---');
  final _submitIoPsCtrl = TextEditingController(text: 'पोलीस स्टेशन पारवा');

  @override
  void initState() {
    super.initState();
    _propDescCtrls =
        List.generate(_propertyRowCount, (_) => TextEditingController());
    _propValueCtrls =
        List.generate(_propertyRowCount, (_) => TextEditingController());
    _propRegCtrls =
        List.generate(_propertyRowCount, (_) => TextEditingController());
    _propFromCtrls =
        List.generate(_propertyRowCount, (_) => TextEditingController());
    _propDisposalCtrls =
        List.generate(_propertyRowCount, (_) => TextEditingController());

    _witnessNameCtrls =
        List.generate(_witnessRowCount, (_) => TextEditingController());
    _witnessAgeCtrls =
        List.generate(_witnessRowCount, (_) => TextEditingController());
    _witnessOccupationCtrls =
        List.generate(_witnessRowCount, (_) => TextEditingController());
    _witnessAddressCtrls =
        List.generate(_witnessRowCount, (_) => TextEditingController());
    _witnessEvidenceCtrls = List.generate(
      _witnessRowCount,
      (i) => TextEditingController(
        text: i < _defaultWitnessEvidence.length
            ? _defaultWitnessEvidence[i]
            : '',
      ),
    );

    if (widget.existingRecord != null) {
      hydrateFrom(widget.existingRecord!);
    }
  }

  @override
  void dispose() {
    _courtCtrl.dispose();
    _courtDistCtrl.dispose();
    _distCtrl.dispose();
    _psCtrl.dispose();
    _yearCtrl.dispose();
    _firNoCtrl.dispose();
    _firYearSuffixCtrl.dispose();
    _headerDateCtrl.dispose();
    _reportNoCtrl.dispose();
    _reportYearSuffixCtrl.dispose();
    _reportDateCtrl.dispose();
    _actCtrl.dispose();
    _sectionCtrl.dispose();
    _reportTypeCtrl.dispose();
    _reportTypeCustomCtrl.dispose();
    _frUnoccurredCtrl.dispose();
    _chargeSheetedCtrl.dispose();
    _originalSupplementaryCtrl.dispose();
    _ioNameCtrl.dispose();
    _ioRankCtrl.dispose();
    _ioNoCtrl.dispose();
    _ioPsCtrl.dispose();
    _complainantNameCtrl.dispose();
    _complainantFatherCtrl.dispose();

    for (final c in [
      ..._propDescCtrls,
      ..._propValueCtrls,
      ..._propRegCtrls,
      ..._propFromCtrls,
      ..._propDisposalCtrls,
      ..._witnessNameCtrls,
      ..._witnessAgeCtrls,
      ..._witnessOccupationCtrls,
      ..._witnessAddressCtrls,
      ..._witnessEvidenceCtrls,
    ]) {
      c.dispose();
    }

    _accNameCtrl.dispose();
    _accNameVerifiedCtrl.dispose();
    _accFatherCtrl.dispose();
    _accDobCtrl.dispose();
    _accAgeCtrl.dispose();
    _accSexCtrl.dispose();
    _accNationalityCtrl.dispose();
    _accPassportCtrl.dispose();
    _accPassportDateCtrl.dispose();
    _accPassportPlaceCtrl.dispose();
    _accReligionCtrl.dispose();
    _accScStCtrl.dispose();
    _accOccupationCtrl.dispose();
    _accAddressCtrl.dispose();
    _accAddressVerifiedCtrl.dispose();
    _accProvCriminalNoCtrl.dispose();
    _accRegularCriminalNoCtrl.dispose();
    _accArrestDateCtrl.dispose();
    _accArrestTimeCtrl.dispose();
    _accBailDateCtrl.dispose();
    _accForwardedCourtCtrl.dispose();
    _accActsSectionsCtrl.dispose();
    _accBailersCtrl.dispose();
    _accPrevConvictionsCtrl.dispose();
    _accStatusCtrl.dispose();
    _notChargeSheetedCtrl.dispose();

    _witnessDescCtrl.dispose();
    _falseFirActionCtrl.dispose();
    _labAnalysisCtrl.dispose();

    _briefFactsCtrl.dispose();
    _referNoticeServedCtrl.dispose();
    _referNoticeDateCtrl.dispose();
    _dispatchedOnCtrl.dispose();
    _shoNameCtrl.dispose();
    _shoRankCtrl.dispose();
    _shoNoCtrl.dispose();
    _shoPsCtrl.dispose();
    _submitIoNameCtrl.dispose();
    _submitIoRankCtrl.dispose();
    _submitIoNoCtrl.dispose();
    _submitIoPsCtrl.dispose();
    super.dispose();
  }

  void hydrateFrom(Map<String, dynamic> data) {
    setState(() {
      _courtCtrl.text = data['court']?.toString() ?? _courtCtrl.text;
      _courtDistCtrl.text =
          data['courtDist']?.toString() ?? _courtDistCtrl.text;
      _distCtrl.text = data['dist']?.toString() ?? _distCtrl.text;
      _psCtrl.text = data['ps']?.toString() ?? _psCtrl.text;
      _yearCtrl.text = data['year']?.toString() ?? _yearCtrl.text;
      _firNoCtrl.text = data['firNo']?.toString() ?? _firNoCtrl.text;
      _firYearSuffixCtrl.text =
          data['firYearSuffix']?.toString() ?? _firYearSuffixCtrl.text;
      _headerDateCtrl.text =
          data['headerDate']?.toString() ?? _headerDateCtrl.text;
      _reportNoCtrl.text = data['reportNo']?.toString() ?? _reportNoCtrl.text;
      _reportYearSuffixCtrl.text =
          data['reportYearSuffix']?.toString() ?? _reportYearSuffixCtrl.text;
      _reportDateCtrl.text =
          data['reportDate']?.toString() ?? _reportDateCtrl.text;
      _actCtrl.text = data['act']?.toString() ?? _actCtrl.text;
      _sectionCtrl.text = data['section']?.toString() ?? _sectionCtrl.text;
      _reportTypeCtrl.text =
          data['reportType']?.toString() ?? _reportTypeCtrl.text;
      _reportTypeCustomCtrl.text =
          data['reportTypeCustom']?.toString() ?? _reportTypeCustomCtrl.text;
      _frUnoccurredCtrl.text =
          data['frUnoccurred']?.toString() ?? _frUnoccurredCtrl.text;
      _chargeSheetedCtrl.text =
          data['chargeSheeted']?.toString() ?? _chargeSheetedCtrl.text;
      _originalSupplementaryCtrl.text =
          data['originalSupplementary']?.toString() ??
              _originalSupplementaryCtrl.text;
      _ioNameCtrl.text = data['ioName']?.toString() ?? _ioNameCtrl.text;
      _ioRankCtrl.text = data['ioRank']?.toString() ?? _ioRankCtrl.text;
      _ioNoCtrl.text = data['ioNo']?.toString() ?? _ioNoCtrl.text;
      _ioPsCtrl.text = data['ioPs']?.toString() ?? _ioPsCtrl.text;
      _complainantNameCtrl.text =
          data['complainantName']?.toString() ?? _complainantNameCtrl.text;
      _complainantFatherCtrl.text =
          data['complainantFather']?.toString() ?? _complainantFatherCtrl.text;

      final savedPropCount =
          int.tryParse(data['propertyRowCount']?.toString() ?? '');
      if (savedPropCount != null && savedPropCount > _propertyRowCount) {
        while (_propertyRowCount < savedPropCount) {
          _propertyRowCount++;
          _propDescCtrls.add(TextEditingController());
          _propValueCtrls.add(TextEditingController());
          _propRegCtrls.add(TextEditingController());
          _propFromCtrls.add(TextEditingController());
          _propDisposalCtrls.add(TextEditingController());
        }
      }
      for (var i = 0; i < _propertyRowCount; i++) {
        final n = '${i + 1}';
        if (data.containsKey('prop${n}Desc')) {
          _propDescCtrls[i].text = data['prop${n}Desc']?.toString() ?? '';
        }
        if (data.containsKey('prop${n}Value')) {
          _propValueCtrls[i].text = data['prop${n}Value']?.toString() ?? '';
        }
        if (data.containsKey('prop${n}Reg')) {
          _propRegCtrls[i].text = data['prop${n}Reg']?.toString() ?? '';
        }
        if (data.containsKey('prop${n}From')) {
          _propFromCtrls[i].text = data['prop${n}From']?.toString() ?? '';
        }
        if (data.containsKey('prop${n}Disposal')) {
          _propDisposalCtrls[i].text =
              data['prop${n}Disposal']?.toString() ?? '';
        }
      }

      _accNameCtrl.text = data['accName']?.toString() ?? _accNameCtrl.text;
      _accNameVerifiedCtrl.text =
          data['accNameVerified']?.toString() ?? _accNameVerifiedCtrl.text;
      _accFatherCtrl.text =
          data['accFather']?.toString() ?? _accFatherCtrl.text;
      _accDobCtrl.text = data['accDob']?.toString() ?? _accDobCtrl.text;
      _accAgeCtrl.text = data['accAge']?.toString() ?? _accAgeCtrl.text;
      _accSexCtrl.text = data['accSex']?.toString() ?? _accSexCtrl.text;
      _accNationalityCtrl.text =
          data['accNationality']?.toString() ?? _accNationalityCtrl.text;
      _accPassportCtrl.text =
          data['accPassport']?.toString() ?? _accPassportCtrl.text;
      _accPassportDateCtrl.text =
          data['accPassportDate']?.toString() ?? _accPassportDateCtrl.text;
      _accPassportPlaceCtrl.text =
          data['accPassportPlace']?.toString() ?? _accPassportPlaceCtrl.text;
      _accReligionCtrl.text =
          data['accReligion']?.toString() ?? _accReligionCtrl.text;
      _accScStCtrl.text = data['accScSt']?.toString() ?? _accScStCtrl.text;
      _accOccupationCtrl.text =
          data['accOccupation']?.toString() ?? _accOccupationCtrl.text;
      _accAddressCtrl.text =
          data['accAddress']?.toString() ?? _accAddressCtrl.text;
      _accAddressVerifiedCtrl.text = data['accAddressVerified']?.toString() ??
          _accAddressVerifiedCtrl.text;
      _accProvCriminalNoCtrl.text =
          data['accProvCriminalNo']?.toString() ?? _accProvCriminalNoCtrl.text;
      _accRegularCriminalNoCtrl.text =
          data['accRegularCriminalNo']?.toString() ??
              _accRegularCriminalNoCtrl.text;
      _accArrestDateCtrl.text =
          data['accArrestDate']?.toString() ?? _accArrestDateCtrl.text;
      _accArrestTimeCtrl.text =
          data['accArrestTime']?.toString() ?? _accArrestTimeCtrl.text;
      _accBailDateCtrl.text =
          data['accBailDate']?.toString() ?? _accBailDateCtrl.text;
      _accForwardedCourtCtrl.text =
          data['accForwardedCourt']?.toString() ?? _accForwardedCourtCtrl.text;
      _accActsSectionsCtrl.text =
          data['accActsSections']?.toString() ?? _accActsSectionsCtrl.text;
      _accBailersCtrl.text =
          data['accBailers']?.toString() ?? _accBailersCtrl.text;
      _accPrevConvictionsCtrl.text = data['accPrevConvictions']?.toString() ??
          _accPrevConvictionsCtrl.text;
      _accStatusCtrl.text =
          data['accStatus']?.toString() ?? _accStatusCtrl.text;
      _notChargeSheetedCtrl.text =
          data['notChargeSheeted']?.toString() ?? _notChargeSheetedCtrl.text;

      _witnessDescCtrl.text =
          data['witnessDesc']?.toString() ?? _witnessDescCtrl.text;
      final savedWitnessCount =
          int.tryParse(data['witnessRowCount']?.toString() ?? '');
      if (savedWitnessCount != null && savedWitnessCount > _witnessRowCount) {
        while (_witnessRowCount < savedWitnessCount) {
          _witnessRowCount++;
          _witnessNameCtrls.add(TextEditingController());
          _witnessAgeCtrls.add(TextEditingController());
          _witnessOccupationCtrls.add(TextEditingController());
          _witnessAddressCtrls.add(TextEditingController());
          _witnessEvidenceCtrls.add(TextEditingController());
        }
      }
      for (var i = 0; i < _witnessRowCount; i++) {
        final n = '${i + 1}';
        if (data.containsKey('witness${n}Name')) {
          _witnessNameCtrls[i].text = data['witness${n}Name']?.toString() ?? '';
        }
        if (data.containsKey('witness${n}Age')) {
          _witnessAgeCtrls[i].text = data['witness${n}Age']?.toString() ?? '';
        }
        if (data.containsKey('witness${n}Occupation')) {
          _witnessOccupationCtrls[i].text =
              data['witness${n}Occupation']?.toString() ?? '';
        }
        if (data.containsKey('witness${n}Address')) {
          _witnessAddressCtrls[i].text =
              data['witness${n}Address']?.toString() ?? '';
        }
        if (data.containsKey('witness${n}Evidence')) {
          _witnessEvidenceCtrls[i].text =
              data['witness${n}Evidence']?.toString() ?? '';
        }
      }

      _falseFirActionCtrl.text =
          data['falseFirAction']?.toString() ?? _falseFirActionCtrl.text;
      _labAnalysisCtrl.text =
          data['labAnalysis']?.toString() ?? _labAnalysisCtrl.text;

      _briefFactsCtrl.text =
          data['briefFacts']?.toString() ?? _briefFactsCtrl.text;
      _referNoticeServedCtrl.text =
          data['referNoticeServed']?.toString() ?? _referNoticeServedCtrl.text;
      _referNoticeDateCtrl.text =
          data['referNoticeDate']?.toString() ?? _referNoticeDateCtrl.text;
      _dispatchedOnCtrl.text =
          data['dispatchedOn']?.toString() ?? _dispatchedOnCtrl.text;
      _shoNameCtrl.text = data['shoName']?.toString() ?? _shoNameCtrl.text;
      _shoRankCtrl.text = data['shoRank']?.toString() ?? _shoRankCtrl.text;
      _shoNoCtrl.text = data['shoNo']?.toString() ?? _shoNoCtrl.text;
      _shoPsCtrl.text = data['shoPs']?.toString() ?? _shoPsCtrl.text;
      _submitIoNameCtrl.text =
          data['submitIoName']?.toString() ?? _submitIoNameCtrl.text;
      _submitIoRankCtrl.text =
          data['submitIoRank']?.toString() ?? _submitIoRankCtrl.text;
      _submitIoNoCtrl.text =
          data['submitIoNo']?.toString() ?? _submitIoNoCtrl.text;
      _submitIoPsCtrl.text =
          data['submitIoPs']?.toString() ?? _submitIoPsCtrl.text;
    });
  }

  Map<String, dynamic> collectData() {
    final map = <String, dynamic>{
      'court': _courtCtrl.text.trim(),
      'courtDist': _courtDistCtrl.text.trim(),
      'dist': _distCtrl.text.trim(),
      'ps': _psCtrl.text.trim(),
      'year': _yearCtrl.text.trim(),
      'firNo': _firNoCtrl.text.trim(),
      'firYearSuffix': _firYearSuffixCtrl.text.trim(),
      'headerDate': _headerDateCtrl.text.trim(),
      'reportNo': _reportNoCtrl.text.trim(),
      'reportYearSuffix': _reportYearSuffixCtrl.text.trim(),
      'reportDate': _reportDateCtrl.text.trim(),
      'act': _actCtrl.text.trim(),
      'section': _sectionCtrl.text.trim(),
      'reportType': _reportTypeCtrl.text.trim(),
      'reportTypeCustom': _reportTypeCustomCtrl.text.trim(),
      'frUnoccurred': _frUnoccurredCtrl.text.trim(),
      'chargeSheeted': _chargeSheetedCtrl.text.trim(),
      'originalSupplementary': _originalSupplementaryCtrl.text.trim(),
      'ioName': _ioNameCtrl.text.trim(),
      'ioRank': _ioRankCtrl.text.trim(),
      'ioNo': _ioNoCtrl.text.trim(),
      'ioPs': _ioPsCtrl.text.trim(),
      'complainantName': _complainantNameCtrl.text.trim(),
      'complainantFather': _complainantFatherCtrl.text.trim(),
      'propertyRowCount': _propertyRowCount,
      'accName': _accNameCtrl.text.trim(),
      'accNameVerified': _accNameVerifiedCtrl.text.trim(),
      'accFather': _accFatherCtrl.text.trim(),
      'accDob': _accDobCtrl.text.trim(),
      'accAge': _accAgeCtrl.text.trim(),
      'accSex': _accSexCtrl.text.trim(),
      'accNationality': _accNationalityCtrl.text.trim(),
      'accPassport': _accPassportCtrl.text.trim(),
      'accPassportDate': _accPassportDateCtrl.text.trim(),
      'accPassportPlace': _accPassportPlaceCtrl.text.trim(),
      'accReligion': _accReligionCtrl.text.trim(),
      'accScSt': _accScStCtrl.text.trim(),
      'accOccupation': _accOccupationCtrl.text.trim(),
      'accAddress': _accAddressCtrl.text.trim(),
      'accAddressVerified': _accAddressVerifiedCtrl.text.trim(),
      'accProvCriminalNo': _accProvCriminalNoCtrl.text.trim(),
      'accRegularCriminalNo': _accRegularCriminalNoCtrl.text.trim(),
      'accArrestDate': _accArrestDateCtrl.text.trim(),
      'accArrestTime': _accArrestTimeCtrl.text.trim(),
      'accBailDate': _accBailDateCtrl.text.trim(),
      'accForwardedCourt': _accForwardedCourtCtrl.text.trim(),
      'accActsSections': _accActsSectionsCtrl.text.trim(),
      'accBailers': _accBailersCtrl.text.trim(),
      'accPrevConvictions': _accPrevConvictionsCtrl.text.trim(),
      'accStatus': _accStatusCtrl.text.trim(),
      'notChargeSheeted': _notChargeSheetedCtrl.text.trim(),
      'witnessDesc': _witnessDescCtrl.text.trim(),
      'witnessRowCount': _witnessRowCount,
      'falseFirAction': _falseFirActionCtrl.text.trim(),
      'labAnalysis': _labAnalysisCtrl.text.trim(),
      'briefFacts': _briefFactsCtrl.text.trim(),
      'referNoticeServed': _referNoticeServedCtrl.text.trim(),
      'referNoticeDate': _referNoticeDateCtrl.text.trim(),
      'dispatchedOn': _dispatchedOnCtrl.text.trim(),
      'shoName': _shoNameCtrl.text.trim(),
      'shoRank': _shoRankCtrl.text.trim(),
      'shoNo': _shoNoCtrl.text.trim(),
      'shoPs': _shoPsCtrl.text.trim(),
      'submitIoName': _submitIoNameCtrl.text.trim(),
      'submitIoRank': _submitIoRankCtrl.text.trim(),
      'submitIoNo': _submitIoNoCtrl.text.trim(),
      'submitIoPs': _submitIoPsCtrl.text.trim(),
    };

    for (var i = 0; i < _propertyRowCount; i++) {
      final n = '${i + 1}';
      map['prop${n}Desc'] = _propDescCtrls[i].text.trim();
      map['prop${n}Value'] = _propValueCtrls[i].text.trim();
      map['prop${n}Reg'] = _propRegCtrls[i].text.trim();
      map['prop${n}From'] = _propFromCtrls[i].text.trim();
      map['prop${n}Disposal'] = _propDisposalCtrls[i].text.trim();
    }

    for (var i = 0; i < _witnessRowCount; i++) {
      final n = '${i + 1}';
      map['witness${n}Name'] = _witnessNameCtrls[i].text.trim();
      map['witness${n}Age'] = _witnessAgeCtrls[i].text.trim();
      map['witness${n}Occupation'] = _witnessOccupationCtrls[i].text.trim();
      map['witness${n}Address'] = _witnessAddressCtrls[i].text.trim();
      map['witness${n}Evidence'] = _witnessEvidenceCtrls[i].text.trim();
    }

    return map;
  }

  Widget _tableCellInput(TextEditingController ctrl, TextStyle serifStyle,
      {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: BilingualSimpleUnderlineInput(
        controller: ctrl,
        serifStyle: serifStyle.copyWith(fontSize: 11),
      ),
    );
  }

  Widget _tableHeader(String text, TextStyle serifStyle) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        text,
        style: serifStyle.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle serifStyle = FormTypography.serifStyle();
    final TextStyle marathiLabelStyle = FormTypography.marathiLabelStyle();

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        // ══════════════════════════════════════════════════════════════════
        // PAGE 1 — SECTIONS 1 TO 10
        // ══════════════════════════════════════════════════════════════════
        if (_shows(kPartI))
          FormPaperPage(
            formLabel: 'Page : 1',
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      'FINAL REPORT FORM',
                      style: serifStyle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'अंतिम अहवाल नमुना',
                      style: GoogleFonts.notoSansDevanagari(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '( UNDER SECTION 193 B.N.S.S.2023 )',
                      style: serifStyle.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // IN THE COURT OF line
              ResponsiveFieldRow(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'IN THE COURT OF : ',
                    style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'मा.वि.न्यायदंडाधिकारी प्रथम श्रेणी,न्यायालय ',
                    style:
                        marathiLabelStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _courtCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'जिल्हा ',
                    style:
                        marathiLabelStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    width: 100,
                    child: BilingualSimpleUnderlineInput(
                      controller: _courtDistCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 1. Dist / P.S / Year / FIR No / Date
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('1.Dist : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(
                    width: 90,
                    child: BilingualSimpleUnderlineInput(
                      controller: _distCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('P.S: ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    flex: 2,
                    child: BilingualSimpleUnderlineInput(
                      controller: _psCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Year : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Text('20', style: serifStyle),
                  SizedBox(
                    width: 35,
                    child: BilingualSimpleUnderlineInput(
                      controller: _yearCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('FIRNo : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    flex: 2,
                    child: BilingualSimpleUnderlineInput(
                      controller: _firNoCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                  Text('/', style: serifStyle),
                  SizedBox(
                    width: 50,
                    child: BilingualSimpleUnderlineInput(
                      controller: _firYearSuffixCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Date : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    flex: 2,
                    child: BilingualSimpleUnderlineInput(
                      controller: _headerDateCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'जिल्हा— यवतमाळ पोलीस ठाणे- ------- वर्ष:-२०.....पहिली खबर क्र......../२०२४ तारीख...../...../२०.....',
                style: marathiLabelStyle.copyWith(
                    fontSize: 9.5, color: Colors.black87),
              ),
              const SizedBox(height: 12),

              // 2. Final Report / Charge Sheet No & 3. Date
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '2. Final Report/Charge Sheet No. ',
                              style: serifStyle.copyWith(
                                  fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                              child: BilingualSimpleUnderlineInput(
                                controller: _reportNoCtrl,
                                serifStyle: serifStyle,
                              ),
                            ),
                            Text('/20', style: serifStyle),
                            SizedBox(
                              width: 35,
                              child: BilingualSimpleUnderlineInput(
                                controller: _reportYearSuffixCtrl,
                                serifStyle: serifStyle,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '   अंतिम अहवाल/आरोप पत्र क्र.',
                          style: marathiLabelStyle.copyWith(
                              fontSize: 10, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '3.Date: ',
                              style: serifStyle.copyWith(
                                  fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                              child: BilingualSimpleUnderlineInput(
                                controller: _reportDateCtrl,
                                serifStyle: serifStyle,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '   दिनांक:',
                          style: marathiLabelStyle.copyWith(
                              fontSize: 10, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4. Act & Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '4. Act : ',
                              style: serifStyle.copyWith(
                                  fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                              child: BilingualSimpleUnderlineInput(
                                controller: _actCtrl,
                                serifStyle: serifStyle,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '   भारतीय न्याय संहिता २०२३',
                          style: marathiLabelStyle.copyWith(
                              fontSize: 10, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Section: ',
                              style: serifStyle.copyWith(
                                  fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                              child: BilingualSimpleUnderlineInput(
                                controller: _sectionCtrl,
                                serifStyle: serifStyle,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '   कलम',
                          style: marathiLabelStyle.copyWith(
                              fontSize: 10, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 5. Type of Final Form / Report
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '5. Type of Final Form /Report :',
                    style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          'Charge Sheeted/Not charge sheeted for want of evidence/ FR Undetect/FR untraced/FR offence abated/FR Unoccured :',
                          style: serifStyle.copyWith(fontSize: 10.5),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: BilingualSimpleUnderlineInput(
                          controller: _reportTypeCtrl,
                          serifStyle: serifStyle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          'अंतिम अहवालाचा प्रकार :आरोपपत्र दाखल केले/पुराव्या अभावी आरोपपत्र दाखल केले नाही/तपारा लागला नाही/ शोध लागला नाही/शपविला/घडलाच नाही :-',
                          style: marathiLabelStyle.copyWith(fontSize: 9.5),
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: BilingualSimpleUnderlineInput(
                          controller: _reportTypeCustomCtrl,
                          serifStyle: serifStyle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 6. If F.R. Unoccured
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          '6. If F.R. Unoccured : False/Mistake of Fact/Mistake of Law/Non-cognizable/Civil Nature :',
                          style: serifStyle.copyWith(
                              fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: BilingualSimpleUnderlineInput(
                          controller: _frUnoccurredCtrl,
                          serifStyle: serifStyle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'जर अंतिम अहवालाचा प्रकार घडला नाही : खोटी/वस्तुस्थितीची चूक/कायद्याची चूक/अदखलपात्र/दिवाणी स्वरूप........................................',
                    style: marathiLabelStyle.copyWith(fontSize: 9.5),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 7. If Charge Sheeted
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '7. If Charge Sheeted : ( जर आरोपपत्र ठेवले ) ',
                    style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    width: 70,
                    child: BilingualSimpleUnderlineInput(
                      controller: _chargeSheetedCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    'Original Supplementary ( मुळ/पुरवणी ) : ',
                    style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    width: 80,
                    child: BilingualSimpleUnderlineInput(
                      controller: _originalSupplementaryCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 8. Name of the I.O / Rank / No / PS
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('8. Name of the I.O : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    flex: 3,
                    child: BilingualSimpleUnderlineInput(
                      controller: _ioNameCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Rank : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    flex: 2,
                    child: BilingualSimpleUnderlineInput(
                      controller: _ioRankCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('No. : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(
                    width: 60,
                    child: BilingualSimpleUnderlineInput(
                      controller: _ioNoCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '   तपासणी अधिकाऱ्याचे नाव:  ',
                    style: marathiLabelStyle.copyWith(fontSize: 10),
                  ),
                  const Spacer(flex: 3),
                  Text(
                    'पदनाम:       ',
                    style: marathiLabelStyle.copyWith(fontSize: 10),
                  ),
                  const Spacer(flex: 2),
                  Text(
                    'पोलीस स्टेशन: ',
                    style: marathiLabelStyle.copyWith(fontSize: 10),
                  ),
                  SizedBox(
                    width: 130,
                    child: BilingualSimpleUnderlineInput(
                      controller: _ioPsCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 9. Complainant Name & Father's Name
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '9. (a) Name of Complainant/Informant : ',
                    style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _complainantNameCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              Text(
                '   तक्रारदाराचे/खबरीचे नांव :',
                style: marathiLabelStyle.copyWith(fontSize: 10),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '   (b) Father\'s/Husband\'s Name : ',
                    style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _complainantFatherCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              Text(
                '   पित्याचे / पतीचे नांव :',
                style: marathiLabelStyle.copyWith(fontSize: 10),
              ),
              const SizedBox(height: 14),

              // 10. Details of Properties recovered/seized Table
              Text(
                '10. Details of Properties/Articles/Documents recovered/seized during investigation and relied upon : Enclosed with C/S.( separate list can be attached, if necessary )',
                style: serifStyle.copyWith(
                    fontWeight: FontWeight.bold, fontSize: 11),
              ),
              Text(
                'तपासणीच्या वेळी परत मिळविलेल्या/जप्त केलेल्या आणि अवलंबून राहीलेल्या मालमत्तेचा/वस्तूंचा तपशील:\n(आवश्यक असेल तर स्वतंत्र यादी सोबत जोडण्यात येईल )',
                style: marathiLabelStyle.copyWith(fontSize: 9.5),
              ),
              const SizedBox(height: 6),
              Table(
                border: TableBorder.all(color: Colors.black87),
                columnWidths: const {
                  0: FixedColumnWidth(44),
                  1: FlexColumnWidth(2.6),
                  2: FlexColumnWidth(1.4),
                  3: FlexColumnWidth(1.6),
                  4: FlexColumnWidth(2.2),
                  5: FlexColumnWidth(1.4),
                },
                children: [
                  TableRow(
                    children: [
                      _tableHeader('Sr.No\nअ.क्र', serifStyle),
                      _tableHeader(
                          'Property Description\nमालमत्तेचे वर्णन', serifStyle),
                      _tableHeader(
                          'Estimated\nValue\n( in Rs.)\nअंदाजित मूल्य\n(रुपयात )',
                          serifStyle),
                      _tableHeader(
                          'P.S.\nProperty\nRegister No.\nपोलीस ठाणे\nमालमत्ता नोंदवही\nक्रमांक',
                          serifStyle),
                      _tableHeader(
                          'From whom/\nwhere Recovered\nor Seized\nकोणाकडून/कोठून परत\nमिळविली किंवा जप्त केली.',
                          serifStyle),
                      _tableHeader('Disposal\nविल्हेवाट', serifStyle),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableHeader('1', serifStyle),
                      _tableHeader('2', serifStyle),
                      _tableHeader('3', serifStyle),
                      _tableHeader('4', serifStyle),
                      _tableHeader('5', serifStyle),
                      _tableHeader('6', serifStyle),
                    ],
                  ),
                  for (var i = 0; i < _propertyRowCount; i++)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text('${i + 1}.',
                              textAlign: TextAlign.center,
                              style: serifStyle.copyWith(
                                  fontWeight: FontWeight.bold)),
                        ),
                        _tableCellInput(_propDescCtrls[i], serifStyle),
                        _tableCellInput(_propValueCtrls[i], serifStyle,
                            align: TextAlign.right),
                        _tableCellInput(_propRegCtrls[i], serifStyle),
                        _tableCellInput(_propFromCtrls[i], serifStyle),
                        _tableCellInput(_propDisposalCtrls[i], serifStyle),
                      ],
                    ),
                ],
              ),
              if (!widget.readOnly) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _propertyRowCount++;
                          _propDescCtrls.add(TextEditingController());
                          _propValueCtrls.add(TextEditingController());
                          _propRegCtrls.add(TextEditingController());
                          _propFromCtrls.add(TextEditingController());
                          _propDisposalCtrls.add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add,
                          size: 15, color: Color(0xFF1E3A8A)),
                      label: Text(
                        'Add Row (ओळ जोडा)',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFEFF4FA),
                        side: const BorderSide(
                            color: Color(0xFFD6E4F0), width: 1),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                      ),
                    ),
                    if (_propertyRowCount > 1) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _propertyRowCount--;
                            _propDescCtrls.removeLast().dispose();
                            _propValueCtrls.removeLast().dispose();
                            _propRegCtrls.removeLast().dispose();
                            _propFromCtrls.removeLast().dispose();
                            _propDisposalCtrls.removeLast().dispose();
                          });
                        },
                        icon: const Icon(Icons.remove,
                            size: 15, color: Color(0xFFB91C1C)),
                        label: Text(
                          'Remove Row (ओळ काढा)',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFB91C1C),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFFEEFEE),
                          side: const BorderSide(
                              color: Color(0xFFFCDADA), width: 1),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),

        if (_shows(kPartI) && (_shows(kPartII) || _showAll))
          const SizedBox(height: 24),

        // ══════════════════════════════════════════════════════════════════
        // PAGE 2 — SECTIONS 11 & 12
        // ══════════════════════════════════════════════════════════════════
        if (_shows(kPartII))
          FormPaperPage(
            formLabel: 'Page : 2',
            children: [
              Text(
                '11. i) Particulars of accused persons charge-sheeted ( use separate sheet for each accused ) : आरोपपत्र ठेवलेल्या आरोपीचा तपशिल ( प्रत्येक आरोपीसाठी स्वतंत्र कागद वापरावा ) :',
                style: serifStyle.copyWith(
                    fontWeight: FontWeight.bold, fontSize: 11),
              ),
              const SizedBox(height: 12),

              // (i) Name & Where verified
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('(i)  Name : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    flex: 3,
                    child: BilingualSimpleUnderlineInput(
                      controller: _accNameCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('Where verified : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    flex: 2,
                    child: BilingualSimpleUnderlineInput(
                      controller: _accNameVerifiedCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text('     नाव : )',
                      style: marathiLabelStyle.copyWith(fontSize: 10)),
                  const Spacer(flex: 3),
                  Text('पडताळले किंवा काय',
                      style: marathiLabelStyle.copyWith(fontSize: 10)),
                  const Spacer(flex: 2),
                ],
              ),
              const SizedBox(height: 8),

              // (ii) Father's/Husband's Name
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('(ii) Father\'s/Husband\'s Name : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _accFatherCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              Text('     पित्याचे/पतीचे नाव',
                  style: marathiLabelStyle.copyWith(fontSize: 10)),
              const SizedBox(height: 8),

              // (iii) Date/Year of Birth / Age
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('(iii) Date/Year of Birth ( जन्मतारीख ) : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _accDobCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('वय ',
                      style: marathiLabelStyle.copyWith(
                          fontWeight: FontWeight.bold)),
                  SizedBox(
                    width: 50,
                    child: BilingualSimpleUnderlineInput(
                      controller: _accAgeCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                  Text(' वर्ष',
                      style: marathiLabelStyle.copyWith(
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),

              // (iv) Sex & (v) Nationality
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('(iv) Sex : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _accSexCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('(v) Nationality : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _accNationalityCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text('     लिंग',
                      style: marathiLabelStyle.copyWith(fontSize: 10)),
                  const Spacer(),
                  Text('राष्ट्रीयत्व',
                      style: marathiLabelStyle.copyWith(fontSize: 10)),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 8),

              // (vi) Passport No / Date / Place
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('(vi) Passport No. : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _accPassportCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Date of issue : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _accPassportDateCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Place of Issue : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _accPassportPlaceCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text('     पारपत्र क्र.',
                      style: marathiLabelStyle.copyWith(fontSize: 10)),
                  const Spacer(),
                  Text('दिल्याची तारीख',
                      style: marathiLabelStyle.copyWith(fontSize: 10)),
                  const Spacer(),
                  Text('दिल्याचे ठिकाण',
                      style: marathiLabelStyle.copyWith(fontSize: 10)),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 8),

              // (vii) Religion & (viii) SC/ST
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('(vii) Religion : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _accReligionCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('(viii) Whether SC/ST : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _accScStCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text('     धर्म',
                      style: marathiLabelStyle.copyWith(fontSize: 10)),
                  const Spacer(),
                  Text('अनुसूचित जातीचा/जमातीचा आहे का',
                      style: marathiLabelStyle.copyWith(fontSize: 10)),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 8),

              // (ix) Occupation
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('(ix) Occupation (व्यवसाय) : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _accOccupationCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // (x) Address & Whether verified
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('(x)  Address ( पत्ता ) : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _accAddressCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('     Whether verified (पडताळला किंवा काय) : ',
                      style: marathiLabelStyle.copyWith(fontSize: 10)),
                  SizedBox(
                    width: 70,
                    child: BilingualSimpleUnderlineInput(
                      controller: _accAddressVerifiedCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // (xi) Provisional Criminal No
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                      '(xi) Provisional Criminal No. (तात्पूरता गुन्हेगार क्र.) ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _accProvCriminalNoCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // (xii) Regular Criminal No
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                      '(xii) Regular Criminal No. (if known) ( नियमित गुन्हेगार क्र.) (माहीत असल्यास) : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _accRegularCriminalNoCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // (xiii) Date of Arrest
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('(xiii) Date of Arrest (अटकेची तारीख.) : दिनांक ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _accArrestDateCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                  Text(' चे ', style: marathiLabelStyle),
                  SizedBox(
                    width: 80,
                    child: BilingualSimpleUnderlineInput(
                      controller: _accArrestTimeCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                  Text(' वाजता', style: marathiLabelStyle),
                ],
              ),
              const SizedBox(height: 8),

              // (xiv) Date of release on bail
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                      '(xiv) Date of release on bail (जामीनावर सोडल्याची तारीख.) : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _accBailDateCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // (xv) Date on which forwarded to court
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                      '(xv) Date on which forwarded to court (न्यायालयात पाठविल्याची तारीख.): ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _accForwardedCourtCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // (xvi) Under Acts & Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('(xvi) Under Acts & Section : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _accActsSectionsCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              Text(
                '      ( कोणत्या अधिनियमाखाली व कलमाखाली ) :- भारतीय न्याय संहिता २०२३ कलम',
                style: marathiLabelStyle.copyWith(fontSize: 10),
              ),
              const SizedBox(height: 8),

              // (xvii) Name (s) of bailers/sureties and Address
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                      '(xvii) Name (s) of bailers/sureties and Address ( मे ) : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _accBailersCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              Text('       जामीनदारांची नांवे व पत्ते :',
                  style: marathiLabelStyle.copyWith(fontSize: 10)),
              const SizedBox(height: 8),

              // (xviii) Previous convictions
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                      '(xviii) Previous convictions with case reference (प्रकरणाच्या संदर्भासह पूर्वीची अपराधीही) : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _accPrevConvictionsCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // (xix) Status of the accused
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('(xix) Status of the accused (आरोपीची स्थिती) : ',
                      style: serifStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _accStatusCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Forwarded/Bailed by Police/In Police Custody/Bailed by Court/In Judicial Custody/Absconding/Proclaimed Offender : पुढे पाठवले/पोलीसांनी जामीनावर सोडले/पोलीस कोठडीत/न्यायालयाने जामीन मंजूर केला/न्यायालयीन कोठडीत/फरारी/उद्घोषित अपराधी',
                style: serifStyle.copyWith(fontSize: 9.5),
              ),
              const SizedBox(height: 14),

              // 12. Accused not charge-sheeted
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '12. आरोप पत्र न ठेवलेल्या आरोपीचा तपशिल: ',
                    style: marathiLabelStyle.copyWith(
                        fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _notChargeSheetedCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
            ],
          ),

        if (_shows(kPartII) && (_shows(kPartIII) || _showAll))
          const SizedBox(height: 24),

        // ══════════════════════════════════════════════════════════════════
        // PAGE 3 — SECTIONS 13 TO 15
        // ══════════════════════════════════════════════════════════════════
        if (_shows(kPartIII))
          FormPaperPage(
            formLabel: 'Page : 3',
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '13. पडताळलेल्या साक्षटारांचे विवरण: ',
                    style: marathiLabelStyle.copyWith(
                        fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _witnessDescCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'साक्षीदारांची यादी.',
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Table(
                border: TableBorder.all(color: Colors.black87),
                columnWidths: const {
                  0: FixedColumnWidth(40),
                  1: FlexColumnWidth(2.4),
                  2: FixedColumnWidth(55),
                  3: FlexColumnWidth(1.4),
                  4: FlexColumnWidth(2.6),
                  5: FlexColumnWidth(2.4),
                },
                children: [
                  TableRow(
                    children: [
                      _tableHeader('अ.क्र', serifStyle),
                      _tableHeader('साक्षीदारांचे नांव', serifStyle),
                      _tableHeader('वय', serifStyle),
                      _tableHeader('व्यवसाय', serifStyle),
                      _tableHeader('राहण्याचा पत्ता', serifStyle),
                      _tableHeader(
                          'सादर करावयाच्या\nपुराव्याचा प्रकार', serifStyle),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableHeader('1', serifStyle),
                      _tableHeader('2', serifStyle),
                      _tableHeader('3', serifStyle),
                      _tableHeader('4', serifStyle),
                      _tableHeader('5', serifStyle),
                      _tableHeader('6', serifStyle),
                    ],
                  ),
                  for (var i = 0; i < _witnessRowCount; i++)
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            i < _marathiNumbers.length
                                ? _marathiNumbers[i]
                                : '${i + 1}.',
                            textAlign: TextAlign.center,
                            style: marathiLabelStyle.copyWith(
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        _tableCellInput(_witnessNameCtrls[i], serifStyle),
                        _tableCellInput(_witnessAgeCtrls[i], serifStyle,
                            align: TextAlign.center),
                        _tableCellInput(_witnessOccupationCtrls[i], serifStyle),
                        _tableCellInput(_witnessAddressCtrls[i], serifStyle),
                        _tableCellInput(_witnessEvidenceCtrls[i], serifStyle),
                      ],
                    ),
                ],
              ),
              if (!widget.readOnly) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _witnessRowCount++;
                          _witnessNameCtrls.add(TextEditingController());
                          _witnessAgeCtrls.add(TextEditingController());
                          _witnessOccupationCtrls.add(TextEditingController());
                          _witnessAddressCtrls.add(TextEditingController());
                          _witnessEvidenceCtrls.add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add,
                          size: 15, color: Color(0xFF1E3A8A)),
                      label: Text(
                        'Add Row (ओळ जोडा)',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFEFF4FA),
                        side: const BorderSide(
                            color: Color(0xFFD6E4F0), width: 1),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                      ),
                    ),
                    if (_witnessRowCount > 1) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _witnessRowCount--;
                            _witnessNameCtrls.removeLast().dispose();
                            _witnessAgeCtrls.removeLast().dispose();
                            _witnessOccupationCtrls.removeLast().dispose();
                            _witnessAddressCtrls.removeLast().dispose();
                            _witnessEvidenceCtrls.removeLast().dispose();
                          });
                        },
                        icon: const Icon(Icons.remove,
                            size: 15, color: Color(0xFFB91C1C)),
                        label: Text(
                          'Remove Row (ओळ काढा)',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFB91C1C),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFFEEFEE),
                          side: const BorderSide(
                              color: Color(0xFFFCDADA), width: 1),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 18),

              // 14. If FIR is False
              Text(
                '14. If F. I. R. is False, indicate action taken or proposed to be taken u/s 182/211 I. P. C.',
                style: serifStyle.copyWith(
                    fontWeight: FontWeight.bold, fontSize: 11),
              ),
              Text(
                '(तकार खोटी असेल तर भादंवि १८२/२११ अन्वये केलेली किंवा करावयाची कार्यवाही नमुद करावी.)',
                style: marathiLabelStyle.copyWith(fontSize: 10),
              ),
              const SizedBox(height: 4),
              BilingualSimpleUnderlineInput(
                controller: _falseFirActionCtrl,
                serifStyle: serifStyle,
              ),
              const SizedBox(height: 14),

              // 15. Result of laboratory analysis
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '15. Result of laboratory analysis : ',
                    style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _labAnalysisCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              Text(
                '     प्रयोगशाळा विश्लेषकाचा निष्कर्ष :',
                style: marathiLabelStyle.copyWith(fontSize: 10),
              ),
            ],
          ),

        if (_shows(kPartIII) && (_shows(kPartIV) || _showAll))
          const SizedBox(height: 24),

        // ══════════════════════════════════════════════════════════════════
        // PAGE 4 — SECTIONS 16 TO 18 & SIGNATURES (Form : 5 E)
        // ══════════════════════════════════════════════════════════════════
        if (_shows(kPartIV) || _showAll)
          FormPaperPage(
            formLabel: 'Form : 5 E',
            children: [
              // 16. Brief Facts of the Case
              Text(
                '16. Brief Facts of the Case (Add separate sheet, if necessary.)',
                style: serifStyle.copyWith(
                    fontWeight: FontWeight.bold, fontSize: 12),
              ),
              Text(
                '     थोडक्यात माहिती ( आवश्यक असल्यास वेगळा कागद जोडावा. ) :',
                style: marathiLabelStyle.copyWith(fontSize: 10.5),
              ),
              const SizedBox(height: 8),
              Text(
                'महोदय,',
                style: marathiLabelStyle.copyWith(
                    fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black26),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(8),
                child: TextField(
                  controller: _briefFactsCtrl,
                  readOnly: widget.readOnly,
                  minLines: 8,
                  maxLines: 18,
                  style: serifStyle.copyWith(fontSize: 12, height: 1.6),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText:
                        'येथे घटनेची थोडक्यात माहिती व तपासाचे विवरण लिहा...',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'टिप :-',
                style: marathiLabelStyle.copyWith(
                    fontWeight: FontWeight.bold, fontSize: 11),
              ),
              const SizedBox(height: 6),

              // 17. Refer Notice Served
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '17. Refer Notice Served : ',
                    style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    width: 90,
                    child: BilingualSimpleUnderlineInput(
                      controller: _referNoticeServedCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    'Date : ',
                    style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    width: 120,
                    child: BilingualSimpleUnderlineInput(
                      controller: _referNoticeDateCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              Text(
                '     ( Acknowledgement to be placed )',
                style: serifStyle.copyWith(fontSize: 10),
              ),
              const SizedBox(height: 10),

              // 18. Dispatched on
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '18. Dispatched on : ',
                    style: serifStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _dispatchedOnCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Footer: Two Officer Columns Side-by-Side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Forwarded by Station House Officer
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Forwarded by Station House\nOfficer/officer in-charge',
                          style: serifStyle.copyWith(
                              fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Name : ',
                                style: serifStyle.copyWith(
                                    fontWeight: FontWeight.bold)),
                            Expanded(
                              child: BilingualSimpleUnderlineInput(
                                controller: _shoNameCtrl,
                                serifStyle: serifStyle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Rank : ',
                                style: serifStyle.copyWith(
                                    fontWeight: FontWeight.bold)),
                            Expanded(
                              child: BilingualSimpleUnderlineInput(
                                controller: _shoRankCtrl,
                                serifStyle: serifStyle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('No : ',
                                style: serifStyle.copyWith(
                                    fontWeight: FontWeight.bold)),
                            SizedBox(
                              width: 45,
                              child: BilingualSimpleUnderlineInput(
                                controller: _shoNoCtrl,
                                serifStyle: serifStyle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        BilingualSimpleUnderlineInput(
                          controller: _shoPsCtrl,
                          serifStyle: serifStyle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),

                  // Right: Signature of Investigation Officer
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Signature of the Investigation Officer\nsubmitting the Final Report/Charge\nSheet.',
                          style: serifStyle.copyWith(
                              fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Name : ',
                                style: serifStyle.copyWith(
                                    fontWeight: FontWeight.bold)),
                            Expanded(
                              child: BilingualSimpleUnderlineInput(
                                controller: _submitIoNameCtrl,
                                serifStyle: serifStyle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Rank : ',
                                style: serifStyle.copyWith(
                                    fontWeight: FontWeight.bold)),
                            Expanded(
                              child: BilingualSimpleUnderlineInput(
                                controller: _submitIoRankCtrl,
                                serifStyle: serifStyle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('No. : ',
                                style: serifStyle.copyWith(
                                    fontWeight: FontWeight.bold)),
                            SizedBox(
                              width: 45,
                              child: BilingualSimpleUnderlineInput(
                                controller: _submitIoNoCtrl,
                                serifStyle: serifStyle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        BilingualSimpleUnderlineInput(
                          controller: _submitIoPsCtrl,
                          serifStyle: serifStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
      ],
    );
  }
}
