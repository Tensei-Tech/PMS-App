import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bilingual_field.dart';
import 'form_paper_page.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';
import 'form_section_utils.dart';

class InquestPanchanamaFormView extends StatefulWidget {
  final Map<String, dynamic>? existingRecord;
  final bool readOnly;
  final String? formSection;
  final String? pageRange;

  const InquestPanchanamaFormView({
    super.key,
    this.existingRecord,
    this.readOnly = false,
    this.formSection,
    this.pageRange,
  });

  @override
  State<InquestPanchanamaFormView> createState() => InquestPanchanamaFormViewState();
}

class InquestPanchanamaFormViewState extends State<InquestPanchanamaFormView> {
  /// Stable section IDs — must match [FormsSubSection.sectionId] in accordion.
  static const kMainInquest = 'Inquest Main';
  static const kCivilSurgeon = 'Civil Surgeon PM Report';
  static const kVinantiArj = 'Vinanti Arj';
  static const kRelativeSummons = 'Relative Summons 179';
  static const kPanchaSummons = 'Pancha Summons 195';
  static const kMarananveshan = 'Marananveshan Panchanama';
  static const kKalmi14 = '14 Kalmi Form';
  static const kBodyHandover = 'Dead Body Handover';
  static const kDutyPass = 'Duty Pass';
  static const _knownSectionIds = {
    kMainInquest,
    kCivilSurgeon,
    kVinantiArj,
    kRelativeSummons,
    kPanchaSummons,
    kMarananveshan,
    kKalmi14,
    kBodyHandover,
    kDutyPass,
  };

  bool _shows(String sectionId) => showsFormSection(
        activeSection: widget.formSection,
        sectionId: sectionId,
        knownSectionIds: _knownSectionIds,
      );

  // ── Part 1: Inquest Panchanama Controllers (Pages 1-4) ──
  // Page 1
  final _distCtrl = TextEditingController(text: 'YAVATMAL');
  final _psCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _firNoCtrl = TextEditingController();
  final _actSectionsCtrl = TextEditingController();
  final _deadBodyFoundPlaceCtrl = TextEditingController();
  final _foundPlaceCtrl = TextEditingController();
  final _foundDateCtrl = TextEditingController();
  final _foundTimeCtrl = TextEditingController();
  final _shownByCtrl = TextEditingController();
  final _identifiedByCtrl = TextEditingController();
  final _identifiedBy2Ctrl = TextEditingController();
  final _genderCtrl = TextEditingController();
  final _marriedCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _deathDateCtrl = TextEditingController();
  final _deathTimeCtrl = TextEditingController();
  final _positionOfBodyCtrl = TextEditingController();
  final _positionOfBody2Ctrl = TextEditingController();

  // Page 2
  final _nameAddressDeceasedCtrl = TextEditingController();
  final _nameAddressDeceased2Ctrl = TextEditingController();
  final _injDescriptionCtrl = TextEditingController();
  final _injHeadCtrl = TextEditingController();
  final _injFaceCtrl = TextEditingController();
  final _injNeckCtrl = TextEditingController();
  final _injChestCtrl = TextEditingController();
  final _injStomachCtrl = TextEditingController();
  final _injRightHandCtrl = TextEditingController();
  final _injLeftHandCtrl = TextEditingController();
  final _injRightLegCtrl = TextEditingController();
  final _injLeftLegCtrl = TextEditingController();
  final _injPrivatePartCtrl = TextEditingController();
  final _injBackCtrl = TextEditingController();

  // Page 3
  final _injAccidentalViolenceCtrl = TextEditingController();
  final _weaponMeansCtrl = TextEditingController();
  final _bodyCoolWarmCtrl = TextEditingController();
  final _poisoningPositionCtrl = TextEditingController();
  final _fingerprintReasonCtrl = TextEditingController();
  final _photoReasonCtrl = TextEditingController();
  final _sentToPMReasonCtrl = TextEditingController();
  final _hospitalNameCtrl = TextEditingController();
  final _sentOfficerNameCtrl = TextEditingController();
  final _sentOfficerBNoCtrl = TextEditingController();
  final _sentOfficerPsCtrl = TextEditingController();
  final _opinionPanchasCtrl = TextEditingController();
  final _opinionPanchas2Ctrl = TextEditingController();
  final _moreInfoCtrl = TextEditingController();

  // Page 4
  final _panchanamaDateCtrl = TextEditingController();
  final _panchanamaTimeCtrl = TextEditingController();
  final _panchanamaTimeToCtrl = TextEditingController();
  final _panch1Ctrl = TextEditingController();
  final _panch1SigCtrl = TextEditingController();
  final _panch2Ctrl = TextEditingController();
  final _panch2SigCtrl = TextEditingController();
  final _panch3Ctrl = TextEditingController();
  final _panch3SigCtrl = TextEditingController();
  final _ioNameCtrl = TextEditingController();
  final _ioRankCtrl = TextEditingController();
  final _ioNoCtrl = TextEditingController();
  final _ioPostingCtrl = TextEditingController();

  // ── Part 2: Police Report to Civil Surgeon (Page 5-6) ──
  final _csNameDeceasedCtrl = TextEditingController();
  final _csAgeCtrl = TextEditingController();
  final _csMaritalStatusCtrl = TextEditingController();
  final _csDeathDateCtrl = TextEditingController();
  final _csDeathTimeCtrl = TextEditingController();
  final _csBodyConditionCtrl = TextEditingController();
  final _csSeenDateCtrl = TextEditingController();
  final _csSeenTimeCtrl = TextEditingController();
  final _csSeenOfficerCtrl = TextEditingController();
  final _csBodyColdWarmCtrl = TextEditingController();
  final _csRecentIllnessCtrl = TextEditingController();
  final _csAccidentInjuryCtrl = TextEditingController();
  final _csArticlesForwardedCtrl = TextEditingController();
  final _csDeathReasonCtrl = TextEditingController();
  final _csPoisonSuspicionCtrl = TextEditingController();
  final _csWomanPregnancyCtrl = TextEditingController();
  final _csAbortionCtrl = TextEditingController();
  final _csJuryFindingsCtrl = TextEditingController();
  final _csRemarksCtrl = TextEditingController();
  final _csExtraNotesCtrl = TextEditingController();
  final _csIoNameCtrl = TextEditingController();
  final _csIoRankCtrl = TextEditingController();
  final _csIoNoCtrl = TextEditingController();
  final _csIoPostingCtrl = TextEditingController();

  // ── Page 7: Vinanti Arj ──
  final _reqPsCtrl = TextEditingController();
  final _reqDateCtrl = TextEditingController();
  final _reqToCtrl = TextEditingController();
  final _reqTo2Ctrl = TextEditingController();
  final _reqFromPsCtrl = TextEditingController();
  final _reqDistCtrl = TextEditingController();
  final _reqSubjectNameCtrl = TextEditingController();
  final _reqSubjectPsCtrl = TextEditingController();
  final _reqSubjectTaCtrl = TextEditingController();
  final _reqMargDateCtrl = TextEditingController();
  final _reqMargTimeCtrl = TextEditingController();
  final _reqMargPsCtrl = TextEditingController();
  final _reqMargDiaryNoCtrl = TextEditingController();
  final _reqMargYearCtrl = TextEditingController();
  final _reqMargNameCtrl = TextEditingController();
  final _reqMargTaCtrl = TextEditingController();
  final _reqDeceasedHeSheCtrl = TextEditingController();
  final _reqHospitalNameCtrl = TextEditingController();
  final _reqAdmitDateCtrl = TextEditingController();
  final _reqAdmitTimeCtrl = TextEditingController();
  final _reqReasonDetailsCtrl = TextEditingController();
  final _reqDeathDateCtrl = TextEditingController();
  final _reqDeathTimeCtrl = TextEditingController();
  final _reqHasteNameCtrl = TextEditingController();
  final _reqHastePsCtrl = TextEditingController();
  final _reqIoNameCtrl = TextEditingController();
  final _reqIoRankCtrl = TextEditingController();
  final _reqIoNoCtrl = TextEditingController();
  final _reqIoPostingCtrl = TextEditingController();

  // ── Page 8: Relatives Summon ──
  final _relPsCtrl = TextEditingController();
  final _relCampCtrl = TextEditingController();
  final _relDateCtrl = TextEditingController();
  final _relToNameCtrl = TextEditingController();
  final _relWeNameCtrl = TextEditingController();
  final _relPsNameCtrl = TextEditingController();
  final _relCrDiaryNoCtrl = TextEditingController();
  final _relCrYearCtrl = TextEditingController();
  final _relActSecCtrl = TextEditingController();
  final _relDeceasedNameCtrl = TextEditingController();
  final _relTaCtrl = TextEditingController();
  final _relDistCtrl = TextEditingController();
  final _relSig1Ctrl = TextEditingController();
  final _relSig2Ctrl = TextEditingController();
  final _relSig3Ctrl = TextEditingController();
  final _relSig4Ctrl = TextEditingController();
  final _relIoNameCtrl = TextEditingController();
  final _relIoRankCtrl = TextEditingController();
  final _relIoNoCtrl = TextEditingController();
  final _relIoPostingCtrl = TextEditingController();

  // ── Page 9: Panchas Summon ──
  final _panPsCtrl = TextEditingController();
  final _panCampCtrl = TextEditingController();
  final _panDateCtrl = TextEditingController();
  final _panToNameCtrl = TextEditingController();
  final _panWeNameCtrl = TextEditingController();
  final _panPsNameCtrl = TextEditingController();
  final _panCrDiaryNoCtrl = TextEditingController();
  final _panCrYearCtrl = TextEditingController();
  final _panActSecCtrl = TextEditingController();
  final _panDeceasedNameCtrl = TextEditingController();
  final _panTaCtrl = TextEditingController();
  final _panDistCtrl = TextEditingController();
  final _panSig1Ctrl = TextEditingController();
  final _panSig2Ctrl = TextEditingController();
  final _panSig3Ctrl = TextEditingController();
  final _panSig4Ctrl = TextEditingController();
  final _panIoNameCtrl = TextEditingController();
  final _panIoRankCtrl = TextEditingController();
  final _panIoNoCtrl = TextEditingController();
  final _panIoPostingCtrl = TextEditingController();

  // ── Page 10: Marananveshan ──
  final _marThikanCtrl = TextEditingController();
  final _marDateCtrl = TextEditingController();
  final _marTimeCtrl = TextEditingController();
  final _marPanchNameAddressCtrl = TextEditingController();
  final _marPsCtrl = TextEditingController();
  final _marDistCtrl = TextEditingController();
  final _marDiaryNoCtrl = TextEditingController();
  final _marActSecCtrl = TextEditingController();
  final _marIoDetailsCtrl = TextEditingController();
  final _marComplainantNameCtrl = TextEditingController();
  final _marDeceasedNameAddressCtrl = TextEditingController();
  final _marShownByNameCtrl = TextEditingController();
  final _marThikanDescriptionCtrl = TextEditingController();
  final _marBodyConditionCtrl = TextEditingController();
  final _marBodyClothesCtrl = TextEditingController();
  final _marBodyOrnamentsCtrl = TextEditingController();
  final _mar13InjuriesCtrl = TextEditingController();
  final _mar14OtherMarksCtrl = TextEditingController();
  final _mar15OrnamentsDisposalCtrl = TextEditingController();
  final _mar16OpinionCtrl = TextEditingController();
  final _mar17BodyDisposalCtrl = TextEditingController();
  final _mar18DateTimeCtrl = TextEditingController();
  final _mar11Panch1Ctrl = TextEditingController();
  final _mar11Panch2Ctrl = TextEditingController();
  final _mar11Panch3Ctrl = TextEditingController();
  final _mar11Panch4Ctrl = TextEditingController();
  final _mar11IoNameCtrl = TextEditingController();
  final _mar11IoRankCtrl = TextEditingController();
  final _mar11IoPsCtrl = TextEditingController();
  final _mar11CopyToCtrl = TextEditingController();

  // ── Page 12: 14-Kalami Form ──
  final _kal14NameAgeCtrl = TextEditingController();
  final _kal14AddressCtrl = TextEditingController();
  final _kal14ShavFromCtrl = TextEditingController();
  final _kal14ShavToCtrl = TextEditingController();
  final _kal14AaiNameCtrl = TextEditingController();
  final _kal14BaapNameCtrl = TextEditingController();
  final _kal14DharmCtrl = TextEditingController();
  final _kal14VyavsayCtrl = TextEditingController();
  bool _kal14Cigarette = false;
  final _kal14CigaretteDaysCtrl = TextEditingController();
  bool _kal14Daru = false;
  final _kal14DaruDaysCtrl = TextEditingController();
  bool _kal14Tambakhu = false;
  final _kal14TambakhuDaysCtrl = TextEditingController();
  bool _kal14PanMasala = false;
  final _kal14PanMasalaDaysCtrl = TextEditingController();
  final _kal14VehicleNameCtrl = TextEditingController();
  final _kal14DriverPassCtrl = TextEditingController();
  final _kal14PedestrianCtrl = TextEditingController();
  final _kal14AccidentHowCtrl = TextEditingController();
  final _kal14AccidentDateTimeCtrl = TextEditingController();
  final _kal14FallInfoCtrl = TextEditingController();
  final _kal14PregnantMonthsCtrl = TextEditingController();
  final _kal14DeliveredAbortionCtrl = TextEditingController();
  final _kal14PregnantDaysCtrl = TextEditingController();
  final _kal14IdentifierNameCtrl = TextEditingController();
  final _kal14IoNameCtrl = TextEditingController();
  final _kal14IoRankCtrl = TextEditingController();
  final _kal14IoPsCtrl = TextEditingController();

  // ── Page 14: Pret Taba Pavati ──
  final _ptpPsCtrl = TextEditingController();
  final _ptpCampCtrl = TextEditingController();
  final _ptpDateCtrl = TextEditingController();
  final _ptpReceiverNameCtrl = TextEditingController();
  final _ptpReceiverRaCtrl = TextEditingController();
  final _ptpReceiverTaCtrl = TextEditingController();
  final _ptpReceiverDistCtrl = TextEditingController();
  final _ptpMoNoCtrl = TextEditingController();
  final _ptpReceiptDateCtrl = TextEditingController();
  final _ptpDeceasedNameCtrl = TextEditingController();
  final _ptpDeceasedRaCtrl = TextEditingController();
  final _ptpDeceasedDistCtrl = TextEditingController();
  final _ptpReceiverSigCtrl = TextEditingController();
  final _ptpIoNameCtrl = TextEditingController();
  final _ptpIoRankCtrl = TextEditingController();
  final _ptpIoPsCtrl = TextEditingController();

  // ── Page 15: Duty Pass ──
  final _dpPsCtrl = TextEditingController();
  final _dpCampCtrl = TextEditingController();
  final _dpDateCtrl = TextEditingController();
  final _dpAmaldaarNameCtrl = TextEditingController();
  final _dpDutyPsCtrl = TextEditingController();
  final _dpDutyDistCtrl = TextEditingController();
  final _dpDutyDateTimeCtrl = TextEditingController();
  final _dpMargNoCtrl = TextEditingController();
  final _dpMargYearCtrl = TextEditingController();
  final _dpKalamCtrl = TextEditingController();
  final _dpDeceasedNameCtrl = TextEditingController();
  final _dpDeceasedRaCtrl = TextEditingController();
  final _dpDeceasedTaCtrl = TextEditingController();
  final _dpDeceasedDistCtrl = TextEditingController();
  final _dpMedOfficerNameCtrl = TextEditingController();
  final _dpAmaldaarSigCtrl = TextEditingController();
  final _dpIoNameCtrl = TextEditingController();
  final _dpIoRankCtrl = TextEditingController();
  final _dpIoPsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingRecord != null) {
      hydrateFrom(widget.existingRecord!);
    }
  }

  void hydrateFrom(Map<String, dynamic> doc) {
    void set(TextEditingController c, String key) {
      c.text = doc[key]?.toString() ?? '';
    }

    _distCtrl.text = doc['dist']?.toString() ?? 'YAVATMAL';
    set(_psCtrl, 'ps');
    set(_yearCtrl, 'year');
    set(_firNoCtrl, 'firNo');
    set(_actSectionsCtrl, 'actSections');
    set(_deadBodyFoundPlaceCtrl, 'deadBodyFoundPlace');
    set(_foundPlaceCtrl, 'foundPlace');
    set(_foundDateCtrl, 'foundDate');
    set(_foundTimeCtrl, 'foundTime');
    set(_shownByCtrl, 'shownBy');
    set(_identifiedByCtrl, 'identifiedBy');
    set(_identifiedBy2Ctrl, 'identifiedBy2');
    set(_genderCtrl, 'gender');
    set(_marriedCtrl, 'married');
    set(_ageCtrl, 'age');
    set(_deathDateCtrl, 'deathDate');
    set(_deathTimeCtrl, 'deathTime');
    set(_positionOfBodyCtrl, 'positionOfBody');
    set(_positionOfBody2Ctrl, 'positionOfBody2');

    set(_nameAddressDeceasedCtrl, 'nameAddressDeceased');
    set(_nameAddressDeceased2Ctrl, 'nameAddressDeceased2');
    set(_injDescriptionCtrl, 'injDescription');
    set(_injHeadCtrl, 'injHead');
    set(_injFaceCtrl, 'injFace');
    set(_injNeckCtrl, 'injNeck');
    set(_injChestCtrl, 'injChest');
    set(_injStomachCtrl, 'injStomach');
    set(_injRightHandCtrl, 'injRightHand');
    set(_injLeftHandCtrl, 'injLeftHand');
    set(_injRightLegCtrl, 'injRightLeg');
    set(_injLeftLegCtrl, 'injLeftLeg');
    set(_injPrivatePartCtrl, 'injPrivatePart');
    set(_injBackCtrl, 'injBack');

    set(_injAccidentalViolenceCtrl, 'injAccidentalViolence');
    set(_weaponMeansCtrl, 'weaponMeans');
    set(_bodyCoolWarmCtrl, 'bodyCoolWarm');
    set(_poisoningPositionCtrl, 'poisoningPosition');
    set(_fingerprintReasonCtrl, 'fingerprintReason');
    set(_photoReasonCtrl, 'photoReason');
    set(_sentToPMReasonCtrl, 'sentToPMReason');
    set(_hospitalNameCtrl, 'hospitalName');
    set(_sentOfficerNameCtrl, 'sentOfficerName');
    set(_sentOfficerBNoCtrl, 'sentOfficerBNo');
    set(_sentOfficerPsCtrl, 'sentOfficerPs');
    set(_opinionPanchasCtrl, 'opinionPanchas');
    set(_opinionPanchas2Ctrl, 'opinionPanchas2');
    set(_moreInfoCtrl, 'moreInfo');

    set(_panchanamaDateCtrl, 'panchanamaDate');
    set(_panchanamaTimeCtrl, 'panchanamaTime');
    set(_panchanamaTimeToCtrl, 'panchanamaTimeTo');
    set(_panch1Ctrl, 'panch1');
    set(_panch1SigCtrl, 'panch1Sig');
    set(_panch2Ctrl, 'panch2');
    set(_panch2SigCtrl, 'panch2Sig');
    set(_panch3Ctrl, 'panch3');
    set(_panch3SigCtrl, 'panch3Sig');
    set(_ioNameCtrl, 'ioName');
    set(_ioRankCtrl, 'ioRank');
    set(_ioNoCtrl, 'ioNo');
    set(_ioPostingCtrl, 'ioPosting');

    // Page 5-6
    set(_csNameDeceasedCtrl, 'csNameDeceased');
    set(_csAgeCtrl, 'csAge');
    set(_csMaritalStatusCtrl, 'csMaritalStatus');
    set(_csDeathDateCtrl, 'csDeathDate');
    set(_csDeathTimeCtrl, 'csDeathTime');
    set(_csBodyConditionCtrl, 'csBodyCondition');
    set(_csSeenDateCtrl, 'csSeenDate');
    set(_csSeenTimeCtrl, 'csSeenTime');
    set(_csSeenOfficerCtrl, 'csSeenOfficer');
    set(_csBodyColdWarmCtrl, 'csBodyColdWarm');
    set(_csRecentIllnessCtrl, 'csRecentIllness');
    set(_csAccidentInjuryCtrl, 'csAccidentInjury');
    set(_csArticlesForwardedCtrl, 'csArticlesForwarded');
    set(_csDeathReasonCtrl, 'csDeathReason');
    set(_csPoisonSuspicionCtrl, 'csPoisonSuspicion');
    set(_csWomanPregnancyCtrl, 'csWomanPregnancy');
    set(_csAbortionCtrl, 'csAbortion');
    set(_csJuryFindingsCtrl, 'csJuryFindings');
    set(_csRemarksCtrl, 'csRemarks');
    set(_csExtraNotesCtrl, 'csExtraNotes');
    set(_csIoNameCtrl, 'csIoName');
    set(_csIoRankCtrl, 'csIoRank');
    set(_csIoNoCtrl, 'csIoNo');
    set(_csIoPostingCtrl, 'csIoPosting');

    // Page 7
    set(_reqPsCtrl, 'reqPs');
    set(_reqDateCtrl, 'reqDate');
    set(_reqToCtrl, 'reqTo');
    set(_reqTo2Ctrl, 'reqTo2');
    set(_reqFromPsCtrl, 'reqFromPs');
    set(_reqDistCtrl, 'reqDist');
    set(_reqSubjectNameCtrl, 'reqSubjectName');
    set(_reqSubjectPsCtrl, 'reqSubjectPs');
    set(_reqSubjectTaCtrl, 'reqSubjectTa');
    set(_reqMargDateCtrl, 'reqMargDate');
    set(_reqMargTimeCtrl, 'reqMargTime');
    set(_reqMargPsCtrl, 'reqMargPs');
    set(_reqMargDiaryNoCtrl, 'reqMargDiaryNo');
    set(_reqMargYearCtrl, 'reqMargYear');
    set(_reqMargNameCtrl, 'reqMargName');
    set(_reqMargTaCtrl, 'reqMargTa');
    set(_reqDeceasedHeSheCtrl, 'reqDeceasedHeShe');
    set(_reqHospitalNameCtrl, 'reqHospitalName');
    set(_reqAdmitDateCtrl, 'reqAdmitDate');
    set(_reqAdmitTimeCtrl, 'reqAdmitTime');
    set(_reqReasonDetailsCtrl, 'reqReasonDetails');
    set(_reqDeathDateCtrl, 'reqDeathDate');
    set(_reqDeathTimeCtrl, 'reqDeathTime');
    set(_reqHasteNameCtrl, 'reqHasteName');
    set(_reqHastePsCtrl, 'reqHastePs');
    set(_reqIoNameCtrl, 'reqIoName');
    set(_reqIoRankCtrl, 'reqIoRank');
    set(_reqIoNoCtrl, 'reqIoNo');
    set(_reqIoPostingCtrl, 'reqIoPosting');

    // Page 8
    set(_relPsCtrl, 'relPs');
    set(_relCampCtrl, 'relCamp');
    set(_relDateCtrl, 'relDate');
    set(_relToNameCtrl, 'relToName');
    set(_relWeNameCtrl, 'relWeName');
    set(_relPsNameCtrl, 'relPsName');
    set(_relCrDiaryNoCtrl, 'relCrDiaryNo');
    set(_relCrYearCtrl, 'relCrYear');
    set(_relActSecCtrl, 'relActSec');
    set(_relDeceasedNameCtrl, 'relDeceasedName');
    set(_relTaCtrl, 'relTa');
    set(_relDistCtrl, 'relDist');
    set(_relSig1Ctrl, 'relSig1');
    set(_relSig2Ctrl, 'relSig2');
    set(_relSig3Ctrl, 'relSig3');
    set(_relSig4Ctrl, 'relSig4');
    set(_relIoNameCtrl, 'relIoName');
    set(_relIoRankCtrl, 'relIoRank');
    set(_relIoNoCtrl, 'relIoNo');
    set(_relIoPostingCtrl, 'relIoPosting');

    // Page 9
    set(_panPsCtrl, 'panPs');
    set(_panCampCtrl, 'panCamp');
    set(_panDateCtrl, 'panDate');
    set(_panToNameCtrl, 'panToName');
    set(_panWeNameCtrl, 'panWeName');
    set(_panPsNameCtrl, 'panPsName');
    set(_panCrDiaryNoCtrl, 'panCrDiaryNo');
    set(_panCrYearCtrl, 'panCrYear');
    set(_panActSecCtrl, 'panActSec');
    set(_panDeceasedNameCtrl, 'panDeceasedName');
    set(_panTaCtrl, 'panTa');
    set(_panDistCtrl, 'panDist');
    set(_panSig1Ctrl, 'panSig1');
    set(_panSig2Ctrl, 'panSig2');
    set(_panSig3Ctrl, 'panSig3');
    set(_panSig4Ctrl, 'panSig4');
    set(_panIoNameCtrl, 'panIoName');
    set(_panIoRankCtrl, 'panIoRank');
    set(_panIoNoCtrl, 'panIoNo');
    set(_panIoPostingCtrl, 'panIoPosting');

    // Page 10-11
    set(_marThikanCtrl, 'marThikan');
    set(_marDateCtrl, 'marDate');
    set(_marTimeCtrl, 'marTime');
    set(_marPanchNameAddressCtrl, 'marPanchNameAddress');
    set(_marPsCtrl, 'marPs');
    set(_marDistCtrl, 'marDist');
    set(_marDiaryNoCtrl, 'marDiaryNo');
    set(_marActSecCtrl, 'marActSec');
    set(_marIoDetailsCtrl, 'marIoDetails');
    set(_marComplainantNameCtrl, 'marComplainantName');
    set(_marDeceasedNameAddressCtrl, 'marDeceasedNameAddress');
    set(_marShownByNameCtrl, 'marShownByName');
    set(_marThikanDescriptionCtrl, 'marThikanDescription');
    set(_marBodyConditionCtrl, 'marBodyCondition');
    set(_marBodyClothesCtrl, 'marBodyClothes');
    set(_marBodyOrnamentsCtrl, 'marBodyOrnaments');
    set(_mar13InjuriesCtrl, 'mar13Injuries');
    set(_mar14OtherMarksCtrl, 'mar14OtherMarks');
    set(_mar15OrnamentsDisposalCtrl, 'mar15OrnamentsDisposal');
    set(_mar16OpinionCtrl, 'mar16Opinion');
    set(_mar17BodyDisposalCtrl, 'mar17BodyDisposal');
    set(_mar18DateTimeCtrl, 'mar18DateTime');
    set(_mar11Panch1Ctrl, 'mar11Panch1');
    set(_mar11Panch2Ctrl, 'mar11Panch2');
    set(_mar11Panch3Ctrl, 'mar11Panch3');
    set(_mar11Panch4Ctrl, 'mar11Panch4');
    set(_mar11IoNameCtrl, 'mar11IoName');
    set(_mar11IoRankCtrl, 'mar11IoRank');
    set(_mar11IoPsCtrl, 'mar11IoPs');
    set(_mar11CopyToCtrl, 'mar11CopyTo');

    // Page 12-13
    set(_kal14NameAgeCtrl, 'kal14NameAge');
    set(_kal14AddressCtrl, 'kal14Address');
    set(_kal14ShavFromCtrl, 'kal14ShavFrom');
    set(_kal14ShavToCtrl, 'kal14ShavTo');
    set(_kal14AaiNameCtrl, 'kal14AaiName');
    set(_kal14BaapNameCtrl, 'kal14BaapName');
    set(_kal14DharmCtrl, 'kal14Dharm');
    set(_kal14VyavsayCtrl, 'kal14Vyavsay');
    _kal14Cigarette = doc['kal14Cigarette'] == true || doc['kal14Cigarette'] == 'true';
    set(_kal14CigaretteDaysCtrl, 'kal14CigaretteDays');
    _kal14Daru = doc['kal14Daru'] == true || doc['kal14Daru'] == 'true';
    set(_kal14DaruDaysCtrl, 'kal14DaruDays');
    _kal14Tambakhu = doc['kal14Tambakhu'] == true || doc['kal14Tambakhu'] == 'true';
    set(_kal14TambakhuDaysCtrl, 'kal14TambakhuDays');
    _kal14PanMasala = doc['kal14PanMasala'] == true || doc['kal14PanMasala'] == 'true';
    set(_kal14PanMasalaDaysCtrl, 'kal14PanMasalaDays');
    set(_kal14VehicleNameCtrl, 'kal14VehicleName');
    set(_kal14DriverPassCtrl, 'kal14DriverPass');
    set(_kal14PedestrianCtrl, 'kal14Pedestrian');
    set(_kal14AccidentHowCtrl, 'kal14AccidentHow');
    set(_kal14AccidentDateTimeCtrl, 'kal14AccidentDateTime');
    set(_kal14FallInfoCtrl, 'kal14FallInfo');
    set(_kal14PregnantMonthsCtrl, 'kal14PregnantMonths');
    set(_kal14DeliveredAbortionCtrl, 'kal14DeliveredAbortion');
    set(_kal14PregnantDaysCtrl, 'kal14PregnantDays');
    set(_kal14IdentifierNameCtrl, 'kal14IdentifierName');
    set(_kal14IoNameCtrl, 'kal14IoName');
    set(_kal14IoRankCtrl, 'kal14IoRank');
    set(_kal14IoPsCtrl, 'kal14IoPs');

    // Page 14
    set(_ptpPsCtrl, 'ptpPs');
    set(_ptpCampCtrl, 'ptpCamp');
    set(_ptpDateCtrl, 'ptpDate');
    set(_ptpReceiverNameCtrl, 'ptpReceiverName');
    set(_ptpReceiverRaCtrl, 'ptpReceiverRa');
    set(_ptpReceiverTaCtrl, 'ptpReceiverTa');
    set(_ptpReceiverDistCtrl, 'ptpReceiverDist');
    set(_ptpMoNoCtrl, 'ptpMoNo');
    set(_ptpReceiptDateCtrl, 'ptpReceiptDate');
    set(_ptpDeceasedNameCtrl, 'ptpDeceasedName');
    set(_ptpDeceasedRaCtrl, 'ptpDeceasedRa');
    set(_ptpDeceasedDistCtrl, 'ptpDeceasedDist');
    set(_ptpReceiverSigCtrl, 'ptpReceiverSig');
    set(_ptpIoNameCtrl, 'ptpIoName');
    set(_ptpIoRankCtrl, 'ptpIoRank');
    set(_ptpIoPsCtrl, 'ptpIoPs');

    // Page 15
    set(_dpPsCtrl, 'dpPs');
    set(_dpCampCtrl, 'dpCamp');
    set(_dpDateCtrl, 'dpDate');
    set(_dpAmaldaarNameCtrl, 'dpAmaldaarName');
    set(_dpDutyPsCtrl, 'dpDutyPs');
    set(_dpDutyDistCtrl, 'dpDutyDist');
    set(_dpDutyDateTimeCtrl, 'dpDutyDateTime');
    set(_dpMargNoCtrl, 'dpMargNo');
    set(_dpMargYearCtrl, 'dpMargYear');
    set(_dpKalamCtrl, 'dpKalam');
    set(_dpDeceasedNameCtrl, 'dpDeceasedName');
    set(_dpDeceasedRaCtrl, 'dpDeceasedRa');
    set(_dpDeceasedTaCtrl, 'dpDeceasedTa');
    set(_dpDeceasedDistCtrl, 'dpDeceasedDist');
    set(_dpMedOfficerNameCtrl, 'dpMedOfficerName');
    set(_dpAmaldaarSigCtrl, 'dpAmaldaarSig');
    set(_dpIoNameCtrl, 'dpIoName');
    set(_dpIoRankCtrl, 'dpIoRank');
    set(_dpIoPsCtrl, 'dpIoPs');
  }

  Map<String, dynamic> extractData() {
    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'dist': _distCtrl.text.trim(),
      'ps': _psCtrl.text.trim(),
      'year': _yearCtrl.text.trim(),
      'firNo': _firNoCtrl.text.trim(),
      'actSections': _actSectionsCtrl.text.trim(),
      'deadBodyFoundPlace': _deadBodyFoundPlaceCtrl.text.trim(),
      'foundPlace': _foundPlaceCtrl.text.trim(),
      'foundDate': _foundDateCtrl.text.trim(),
      'foundTime': _foundTimeCtrl.text.trim(),
      'shownBy': _shownByCtrl.text.trim(),
      'identifiedBy': _identifiedByCtrl.text.trim(),
      'identifiedBy2': _identifiedBy2Ctrl.text.trim(),
      'gender': _genderCtrl.text.trim(),
      'married': _marriedCtrl.text.trim(),
      'age': _ageCtrl.text.trim(),
      'deathDate': _deathDateCtrl.text.trim(),
      'deathTime': _deathTimeCtrl.text.trim(),
      'positionOfBody': _positionOfBodyCtrl.text.trim(),
      'positionOfBody2': _positionOfBody2Ctrl.text.trim(),

      'nameAddressDeceased': _nameAddressDeceasedCtrl.text.trim(),
      'nameAddressDeceased2': _nameAddressDeceased2Ctrl.text.trim(),
      'injDescription': _injDescriptionCtrl.text.trim(),
      'injHead': _injHeadCtrl.text.trim(),
      'injFace': _injFaceCtrl.text.trim(),
      'injNeck': _injNeckCtrl.text.trim(),
      'injChest': _injChestCtrl.text.trim(),
      'injStomach': _injStomachCtrl.text.trim(),
      'injRightHand': _injRightHandCtrl.text.trim(),
      'injLeftHand': _injLeftHandCtrl.text.trim(),
      'injRightLeg': _injRightLegCtrl.text.trim(),
      'injLeftLeg': _injLeftLegCtrl.text.trim(),
      'injPrivatePart': _injPrivatePartCtrl.text.trim(),
      'injBack': _injBackCtrl.text.trim(),

      'injAccidentalViolence': _injAccidentalViolenceCtrl.text.trim(),
      'weaponMeans': _weaponMeansCtrl.text.trim(),
      'bodyCoolWarm': _bodyCoolWarmCtrl.text.trim(),
      'poisoningPosition': _poisoningPositionCtrl.text.trim(),
      'fingerprintReason': _fingerprintReasonCtrl.text.trim(),
      'photoReason': _photoReasonCtrl.text.trim(),
      'sentToPMReason': _sentToPMReasonCtrl.text.trim(),
      'hospitalName': _hospitalNameCtrl.text.trim(),
      'sentOfficerName': _sentOfficerNameCtrl.text.trim(),
      'sentOfficerBNo': _sentOfficerBNoCtrl.text.trim(),
      'sentOfficerPs': _sentOfficerPsCtrl.text.trim(),
      'opinionPanchas': _opinionPanchasCtrl.text.trim(),
      'opinionPanchas2': _opinionPanchas2Ctrl.text.trim(),
      'moreInfo': _moreInfoCtrl.text.trim(),

      'panchanamaDate': _panchanamaDateCtrl.text.trim(),
      'panchanamaTime': _panchanamaTimeCtrl.text.trim(),
      'panchanamaTimeTo': _panchanamaTimeToCtrl.text.trim(),
      'panch1': _panch1Ctrl.text.trim(),
      'panch1Sig': _panch1SigCtrl.text.trim(),
      'panch2': _panch2Ctrl.text.trim(),
      'panch2Sig': _panch2SigCtrl.text.trim(),
      'panch3': _panch3Ctrl.text.trim(),
      'panch3Sig': _panch3SigCtrl.text.trim(),
      'ioName': _ioNameCtrl.text.trim(),
      'ioRank': _ioRankCtrl.text.trim(),
      'ioNo': _ioNoCtrl.text.trim(),
      'ioPosting': _ioPostingCtrl.text.trim(),

      // CS
      'csNameDeceased': _csNameDeceasedCtrl.text.trim(),
      'csAge': _csAgeCtrl.text.trim(),
      'csMaritalStatus': _csMaritalStatusCtrl.text.trim(),
      'csDeathDate': _csDeathDateCtrl.text.trim(),
      'csDeathTime': _csDeathTimeCtrl.text.trim(),
      'csBodyCondition': _csBodyConditionCtrl.text.trim(),
      'csSeenDate': _csSeenDateCtrl.text.trim(),
      'csSeenTime': _csSeenTimeCtrl.text.trim(),
      'csSeenOfficer': _csSeenOfficerCtrl.text.trim(),
      'csBodyColdWarm': _csBodyColdWarmCtrl.text.trim(),
      'csRecentIllness': _csRecentIllnessCtrl.text.trim(),
      'csAccidentInjury': _csAccidentInjuryCtrl.text.trim(),
      'csArticlesForwarded': _csArticlesForwardedCtrl.text.trim(),
      'csDeathReason': _csDeathReasonCtrl.text.trim(),
      'csPoisonSuspicion': _csPoisonSuspicionCtrl.text.trim(),
      'csWomanPregnancy': _csWomanPregnancyCtrl.text.trim(),
      'csAbortion': _csAbortionCtrl.text.trim(),
      'csJuryFindings': _csJuryFindingsCtrl.text.trim(),
      'csRemarks': _csRemarksCtrl.text.trim(),
      'csExtraNotes': _csExtraNotesCtrl.text.trim(),
      'csIoName': _csIoNameCtrl.text.trim(),
      'csIoRank': _csIoRankCtrl.text.trim(),
      'csIoNo': _csIoNoCtrl.text.trim(),
      'csIoPosting': _csIoPostingCtrl.text.trim(),

      // Page 7
      'reqPs': _reqPsCtrl.text.trim(),
      'reqDate': _reqDateCtrl.text.trim(),
      'reqTo': _reqToCtrl.text.trim(),
      'reqTo2': _reqTo2Ctrl.text.trim(),
      'reqFromPs': _reqFromPsCtrl.text.trim(),
      'reqDist': _reqDistCtrl.text.trim(),
      'reqSubjectName': _reqSubjectNameCtrl.text.trim(),
      'reqSubjectPs': _reqSubjectPsCtrl.text.trim(),
      'reqSubjectTa': _reqSubjectTaCtrl.text.trim(),
      'reqMargDate': _reqMargDateCtrl.text.trim(),
      'reqMargTime': _reqMargTimeCtrl.text.trim(),
      'reqMargPs': _reqMargPsCtrl.text.trim(),
      'reqMargDiaryNo': _reqMargDiaryNoCtrl.text.trim(),
      'reqMargYear': _reqMargYearCtrl.text.trim(),
      'reqMargName': _reqMargNameCtrl.text.trim(),
      'reqMargTa': _reqMargTaCtrl.text.trim(),
      'reqDeceasedHeShe': _reqDeceasedHeSheCtrl.text.trim(),
      'reqHospitalName': _reqHospitalNameCtrl.text.trim(),
      'reqAdmitDate': _reqAdmitDateCtrl.text.trim(),
      'reqAdmitTime': _reqAdmitTimeCtrl.text.trim(),
      'reqReasonDetails': _reqReasonDetailsCtrl.text.trim(),
      'reqDeathDate': _reqDeathDateCtrl.text.trim(),
      'reqDeathTime': _reqDeathTimeCtrl.text.trim(),
      'reqHasteName': _reqHasteNameCtrl.text.trim(),
      'reqHastePs': _reqHastePsCtrl.text.trim(),
      'reqIoName': _reqIoNameCtrl.text.trim(),
      'reqIoRank': _reqIoRankCtrl.text.trim(),
      'reqIoNo': _reqIoNoCtrl.text.trim(),
      'reqIoPosting': _reqIoPostingCtrl.text.trim(),

      // Page 8
      'relPs': _relPsCtrl.text.trim(),
      'relCamp': _relCampCtrl.text.trim(),
      'relDate': _relDateCtrl.text.trim(),
      'relToName': _relToNameCtrl.text.trim(),
      'relWeName': _relWeNameCtrl.text.trim(),
      'relPsName': _relPsNameCtrl.text.trim(),
      'relCrDiaryNo': _relCrDiaryNoCtrl.text.trim(),
      'relCrYear': _relCrYearCtrl.text.trim(),
      'relActSec': _relActSecCtrl.text.trim(),
      'relDeceasedName': _relDeceasedNameCtrl.text.trim(),
      'relTa': _relTaCtrl.text.trim(),
      'relDist': _relDistCtrl.text.trim(),
      'relSig1': _relSig1Ctrl.text.trim(),
      'relSig2': _relSig2Ctrl.text.trim(),
      'relSig3': _relSig3Ctrl.text.trim(),
      'relSig4': _relSig4Ctrl.text.trim(),
      'relIoName': _relIoNameCtrl.text.trim(),
      'relIoRank': _relIoRankCtrl.text.trim(),
      'relIoNo': _relIoNoCtrl.text.trim(),
      'relIoPosting': _relIoPostingCtrl.text.trim(),

      // Page 9
      'panPs': _panPsCtrl.text.trim(),
      'panCamp': _panCampCtrl.text.trim(),
      'panDate': _panDateCtrl.text.trim(),
      'panToName': _panToNameCtrl.text.trim(),
      'panWeName': _panWeNameCtrl.text.trim(),
      'panPsName': _panPsNameCtrl.text.trim(),
      'panCrDiaryNo': _panCrDiaryNoCtrl.text.trim(),
      'panCrYear': _panCrYearCtrl.text.trim(),
      'panActSec': _panActSecCtrl.text.trim(),
      'panDeceasedName': _panDeceasedNameCtrl.text.trim(),
      'panTa': _panTaCtrl.text.trim(),
      'panDist': _panDistCtrl.text.trim(),
      'panSig1': _panSig1Ctrl.text.trim(),
      'panSig2': _panSig2Ctrl.text.trim(),
      'panSig3': _panSig3Ctrl.text.trim(),
      'panSig4': _panSig4Ctrl.text.trim(),
      'panIoName': _panIoNameCtrl.text.trim(),
      'panIoRank': _panIoRankCtrl.text.trim(),
      'panIoNo': _panIoNoCtrl.text.trim(),
      'panIoPosting': _panIoPostingCtrl.text.trim(),

      // Page 10
      'marThikan': _marThikanCtrl.text.trim(),
      'marDate': _marDateCtrl.text.trim(),
      'marTime': _marTimeCtrl.text.trim(),
      'marPanchNameAddress': _marPanchNameAddressCtrl.text.trim(),
      'marPs': _marPsCtrl.text.trim(),
      'marDist': _marDistCtrl.text.trim(),
      'marDiaryNo': _marDiaryNoCtrl.text.trim(),
      'marActSec': _marActSecCtrl.text.trim(),
      'marIoDetails': _marIoDetailsCtrl.text.trim(),
      'marComplainantName': _marComplainantNameCtrl.text.trim(),
      'marDeceasedNameAddress': _marDeceasedNameAddressCtrl.text.trim(),
      'marShownByName': _marShownByNameCtrl.text.trim(),
      'marThikanDescription': _marThikanDescriptionCtrl.text.trim(),
      'marBodyCondition': _marBodyConditionCtrl.text.trim(),
      'marBodyClothes': _marBodyClothesCtrl.text.trim(),
      'marBodyOrnaments': _marBodyOrnamentsCtrl.text.trim(),

      // Page 11
      'mar13Injuries': _mar13InjuriesCtrl.text.trim(),
      'mar14OtherMarks': _mar14OtherMarksCtrl.text.trim(),
      'mar15OrnamentsDisposal': _mar15OrnamentsDisposalCtrl.text.trim(),
      'mar16Opinion': _mar16OpinionCtrl.text.trim(),
      'mar17BodyDisposal': _mar17BodyDisposalCtrl.text.trim(),
      'mar18DateTime': _mar18DateTimeCtrl.text.trim(),
      'mar11Panch1': _mar11Panch1Ctrl.text.trim(),
      'mar11Panch2': _mar11Panch2Ctrl.text.trim(),
      'mar11Panch3': _mar11Panch3Ctrl.text.trim(),
      'mar11Panch4': _mar11Panch4Ctrl.text.trim(),
      'mar11IoName': _mar11IoNameCtrl.text.trim(),
      'mar11IoRank': _mar11IoRankCtrl.text.trim(),
      'mar11IoPs': _mar11IoPsCtrl.text.trim(),
      'mar11CopyTo': _mar11CopyToCtrl.text.trim(),

      // Page 12
      'kal14NameAge': _kal14NameAgeCtrl.text.trim(),
      'kal14Address': _kal14AddressCtrl.text.trim(),
      'kal14ShavFrom': _kal14ShavFromCtrl.text.trim(),
      'kal14ShavTo': _kal14ShavToCtrl.text.trim(),
      'kal14AaiName': _kal14AaiNameCtrl.text.trim(),
      'kal14BaapName': _kal14BaapNameCtrl.text.trim(),
      'kal14Dharm': _kal14DharmCtrl.text.trim(),
      'kal14Vyavsay': _kal14VyavsayCtrl.text.trim(),
      'kal14Cigarette': _kal14Cigarette,
      'kal14CigaretteDays': _kal14CigaretteDaysCtrl.text.trim(),
      'kal14Daru': _kal14Daru,
      'kal14DaruDays': _kal14DaruDaysCtrl.text.trim(),
      'kal14Tambakhu': _kal14Tambakhu,
      'kal14TambakhuDays': _kal14TambakhuDaysCtrl.text.trim(),
      'kal14PanMasala': _kal14PanMasala,
      'kal14PanMasalaDays': _kal14PanMasalaDaysCtrl.text.trim(),

      // Page 13
      'kal14VehicleName': _kal14VehicleNameCtrl.text.trim(),
      'kal14DriverPass': _kal14DriverPassCtrl.text.trim(),
      'kal14Pedestrian': _kal14PedestrianCtrl.text.trim(),
      'kal14AccidentHow': _kal14AccidentHowCtrl.text.trim(),
      'kal14AccidentDateTime': _kal14AccidentDateTimeCtrl.text.trim(),
      'kal14FallInfo': _kal14FallInfoCtrl.text.trim(),
      'kal14PregnantMonths': _kal14PregnantMonthsCtrl.text.trim(),
      'kal14DeliveredAbortion': _kal14DeliveredAbortionCtrl.text.trim(),
      'kal14PregnantDays': _kal14PregnantDaysCtrl.text.trim(),
      'kal14IdentifierName': _kal14IdentifierNameCtrl.text.trim(),
      'kal14IoName': _kal14IoNameCtrl.text.trim(),
      'kal14IoRank': _kal14IoRankCtrl.text.trim(),
      'kal14IoPs': _kal14IoPsCtrl.text.trim(),

      // Page 14
      'ptpPs': _ptpPsCtrl.text.trim(),
      'ptpCamp': _ptpCampCtrl.text.trim(),
      'ptpDate': _ptpDateCtrl.text.trim(),
      'ptpReceiverName': _ptpReceiverNameCtrl.text.trim(),
      'ptpReceiverRa': _ptpReceiverRaCtrl.text.trim(),
      'ptpReceiverTa': _ptpReceiverTaCtrl.text.trim(),
      'ptpReceiverDist': _ptpReceiverDistCtrl.text.trim(),
      'ptpMoNo': _ptpMoNoCtrl.text.trim(),
      'ptpReceiptDate': _ptpReceiptDateCtrl.text.trim(),
      'ptpDeceasedName': _ptpDeceasedNameCtrl.text.trim(),
      'ptpDeceasedRa': _ptpDeceasedRaCtrl.text.trim(),
      'ptpDeceasedDist': _ptpDeceasedDistCtrl.text.trim(),
      'ptpReceiverSig': _ptpReceiverSigCtrl.text.trim(),
      'ptpIoName': _ptpIoNameCtrl.text.trim(),
      'ptpIoRank': _ptpIoRankCtrl.text.trim(),
      'ptpIoPs': _ptpIoPsCtrl.text.trim(),

      // Page 15
      'dpPs': _dpPsCtrl.text.trim(),
      'dpCamp': _dpCampCtrl.text.trim(),
      'dpDate': _dpDateCtrl.text.trim(),
      'dpAmaldaarName': _dpAmaldaarNameCtrl.text.trim(),
      'dpDutyPs': _dpDutyPsCtrl.text.trim(),
      'dpDutyDist': _dpDutyDistCtrl.text.trim(),
      'dpDutyDateTime': _dpDutyDateTimeCtrl.text.trim(),
      'dpMargNo': _dpMargNoCtrl.text.trim(),
      'dpMargYear': _dpMargYearCtrl.text.trim(),
      'dpKalam': _dpKalamCtrl.text.trim(),
      'dpDeceasedName': _dpDeceasedNameCtrl.text.trim(),
      'dpDeceasedRa': _dpDeceasedRaCtrl.text.trim(),
      'dpDeceasedTa': _dpDeceasedTaCtrl.text.trim(),
      'dpDeceasedDist': _dpDeceasedDistCtrl.text.trim(),
      'dpMedOfficerName': _dpMedOfficerNameCtrl.text.trim(),
      'dpAmaldaarSig': _dpAmaldaarSigCtrl.text.trim(),
      'dpIoName': _dpIoNameCtrl.text.trim(),
      'dpIoRank': _dpIoRankCtrl.text.trim(),
      'dpIoPs': _dpIoPsCtrl.text.trim(),
    };
  }

  // Helper input widgets
  Widget _inlineBlank({
    required TextEditingController controller,
    required TextStyle style,
    double? width,
    String? hintText,
  }) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        readOnly: widget.readOnly,
        style: style.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
          color: const Color(0xFF0D47A1),
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          fillColor: Colors.transparent,
          hintText: hintText,
          hintStyle: style.copyWith(fontSize: 11, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          border: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF333333), width: 1.0)),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF555555), width: 1.0)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1976D2), width: 2.0)),
        ),
      ),
    );
  }

  Widget _multilineBlankBox({
    required TextEditingController controller,
    required TextStyle style,
    int minLines = 2,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: widget.readOnly,
      minLines: minLines,
      maxLines: null,
      style: style.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 13.5,
        height: 1.4,
        color: const Color(0xFF0D47A1),
      ),
      decoration: const InputDecoration(
        isDense: true,
        filled: false,
        fillColor: Colors.transparent,
        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF555555), width: 1.0)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF555555), width: 1.0)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF1976D2), width: 2.0)),
      ),
    );
  }

  Widget _subLabel(String text, TextStyle marathiStyle) {
    return Text(
      text,
      style: marathiStyle.copyWith(
        fontSize: 10.5,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInjuryRow(String labelEn, String labelMr, TextEditingController ctrl, TextStyle style, TextStyle marathiStyle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 140,
                child: Text(labelEn, style: style.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              Expanded(child: _inlineBlank(controller: ctrl, style: style)),
            ],
          ),
          _subLabel('   $labelMr', marathiStyle),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 1 (Inquest Main)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildInquestPage1(TextStyle style, TextStyle marathiStyle) {
    return FormPaperPage(
      formLabel: 'Page 1',
      children: [
        Center(
          child: Column(
            children: [
              Text(
                'INQUEST PANCHANAMA',
                textAlign: TextAlign.center,
                style: style.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'मरणोत्तर पंचनामा',
                textAlign: TextAlign.center,
                style: marathiStyle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '(Under Section - 194 B.N.S.S.)',
                textAlign: TextAlign.center,
                style: style.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              Text(
                '( भारतीय नागरिक सुरक्षा संहिता २०२३ कलम १९४ अन्वये.)',
                textAlign: TextAlign.center,
                style: marathiStyle.copyWith(fontSize: 11.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Divider(color: Colors.black87, thickness: 1.2),
        const SizedBox(height: 8),

        // 1) Dist. (YAVATMAL) P.S.:... Year:-20... FIR/AD/U.D.No:...
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 3,
          runSpacing: 4,
          children: [
            Text('1) Dist. (YAVATMAL)', style: style.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(width: 30),
            Text('P.S.:-', style: style.copyWith(fontWeight: FontWeight.bold)),
            _inlineBlank(controller: _psCtrl, style: style, width: 140),
            Text('Year:-20', style: style.copyWith(fontWeight: FontWeight.bold)),
            _inlineBlank(controller: _yearCtrl, style: style, width: 50),
            const SizedBox(width: 16),
            Text('FIR/AD/U.D.No:-', style: style.copyWith(fontWeight: FontWeight.bold)),
            _inlineBlank(controller: _firNoCtrl, style: style, width: 130),
          ],
        ),
        Row(
          children: [
            _subLabel('   जिल्हा - यवतमाळ             पो.स्टे.             वर्ष                     पहिली खबर क्र./ अकस्मात मृत्यू क्र.', marathiStyle),
          ],
        ),
        const SizedBox(height: 12),

        // 2) Act and Section: -
        Row(
          children: [
            Text('2) Act and Section: - ', style: style.copyWith(fontWeight: FontWeight.bold)),
            Expanded(child: _inlineBlank(controller: _actSectionsCtrl, style: style)),
          ],
        ),
        _subLabel('   अधिनियम व कलमे :-', marathiStyle),
        const SizedBox(height: 12),

        // 3) Place From where Dead Body Found/Traced :
        Row(
          children: [
            Text('3) Place From where Dead Body Found/Traced : ', style: style.copyWith(fontWeight: FontWeight.bold)),
            Expanded(child: _inlineBlank(controller: _deadBodyFoundPlaceCtrl, style: style)),
          ],
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 3,
          runSpacing: 4,
          children: [
            _subLabel('   प्रेत सापडल्याचे /मिळाल्याचे ठिकाण / जागा     ', marathiStyle),
            Text('Place:-', style: style),
            _inlineBlank(controller: _foundPlaceCtrl, style: style, width: 130),
            Text('Date:', style: style),
            _inlineBlank(controller: _foundDateCtrl, style: style, width: 90),
            Text(' time:', style: style),
            _inlineBlank(controller: _foundTimeCtrl, style: style, width: 80),
          ],
        ),
        const SizedBox(height: 12),

        // 4) By whom Dead Body Shown :
        Row(
          children: [
            Text('4) By whom Dead Body Shown                   :', style: style.copyWith(fontWeight: FontWeight.bold)),
            Expanded(child: _inlineBlank(controller: _shownByCtrl, style: style)),
          ],
        ),
        _subLabel('   प्रेत कोणी दाखविले :-', marathiStyle),
        const SizedBox(height: 12),

        // 5) By whom Dead Body Identified :
        Row(
          children: [
            Text('5) By whom Dead Body Identified              :', style: style.copyWith(fontWeight: FontWeight.bold)),
            Expanded(child: _inlineBlank(controller: _identifiedByCtrl, style: style)),
          ],
        ),
        _subLabel('   प्रेत कोणी ओळखले :-', marathiStyle),
        _multilineBlankBox(controller: _identifiedBy2Ctrl, style: style, minLines: 2),
        const SizedBox(height: 12),

        // a) Dead Body Male/Female :
        Row(
          children: [
            Text('a) Dead Body Male/Female                     :', style: style.copyWith(fontWeight: FontWeight.bold)),
            Expanded(child: _inlineBlank(controller: _genderCtrl, style: style)),
          ],
        ),
        _subLabel('   अ) प्रेत स्त्री / पुरुष जातीचे :-', marathiStyle),
        const SizedBox(height: 12),

        // 6) b) Dead Body Married/Unmarried :
        Row(
          children: [
            Text('6) b) Dead Body Married/Unmarried            :', style: style.copyWith(fontWeight: FontWeight.bold)),
            Expanded(child: _inlineBlank(controller: _marriedCtrl, style: style)),
          ],
        ),
        _subLabel('   ब) प्रेत विवाहीत /अविवाहीत आहे :-', marathiStyle),
        const SizedBox(height: 12),

        // c) Age of Dead Body :
        Row(
          children: [
            Text('c) Age of Dead Body                          :', style: style.copyWith(fontWeight: FontWeight.bold)),
            Expanded(child: _inlineBlank(controller: _ageCtrl, style: style)),
          ],
        ),
        _subLabel('   क) प्रेताचे वय :-', marathiStyle),
        const SizedBox(height: 12),

        // d) Date and Time of Dead :
        Row(
          children: [
            Text('d) Date and Time of Dead                     :', style: style.copyWith(fontWeight: FontWeight.bold)),
            Expanded(child: _inlineBlank(controller: _deathDateCtrl, style: style)),
          ],
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 3,
          runSpacing: 4,
          children: [
            _subLabel('   ड) मृत्यूची तारीख वेळ :-                     ', marathiStyle),
            Text('Date : ', style: style),
            _inlineBlank(controller: _deathDateCtrl, style: style, width: 130),
            const SizedBox(width: 20),
            Text('Time : ', style: style),
            _inlineBlank(controller: _deathTimeCtrl, style: style, width: 130),
          ],
        ),
        Row(
          children: [
            _subLabel('                                                तारीख                                   वेळ', marathiStyle),
          ],
        ),
        const SizedBox(height: 12),

        // 7) Position of Dead Body :
        Row(
          children: [
            Text('7) Position of Dead Body                     :', style: style.copyWith(fontWeight: FontWeight.bold)),
            Expanded(child: _inlineBlank(controller: _positionOfBodyCtrl, style: style)),
          ],
        ),
        _subLabel('   प्रेताची स्थिती / अवस्था (जागा)', marathiStyle),
        _multilineBlankBox(controller: _positionOfBody2Ctrl, style: style, minLines: 2),

        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Text('M.R.W', style: style.copyWith(fontSize: 10, fontStyle: FontStyle.italic)),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 2 (Inquest Main)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildInquestPage2(TextStyle style, TextStyle marathiStyle) {
    return FormPaperPage(
      formLabel: 'Page 2',
      children: [
        // 8) Name and Address of Dead Body
        Row(
          children: [
            Text('8) Name and Address of Dead Body             :', style: style.copyWith(fontWeight: FontWeight.bold)),
            Expanded(child: _inlineBlank(controller: _nameAddressDeceasedCtrl, style: style)),
          ],
        ),
        _subLabel('   प्रेताचे संपूर्ण नांव व पत्ता (माहित असल्यास)', marathiStyle),
        _multilineBlankBox(controller: _nameAddressDeceased2Ctrl, style: style, minLines: 4),
        const SizedBox(height: 14),

        // 9) Description Of injuries Found on Dead Body if any :
        Row(
          children: [
            Text('9) Description Of injuries Found on Dead Body if any :', style: style.copyWith(fontWeight: FontWeight.bold)),
            Expanded(child: _inlineBlank(controller: _injDescriptionCtrl, style: style)),
          ],
        ),
        _subLabel('   प्रेताचे अंगावर असल्यास त्याचे वर्णन :', marathiStyle),
        const SizedBox(height: 10),

        // Sub-items a) to k)
        _buildInjuryRow('a) Head          :', 'अ) डोके        :', _injHeadCtrl, style, marathiStyle),
        _buildInjuryRow('b) Face          :', 'ब) चेहरा        :', _injFaceCtrl, style, marathiStyle),
        _buildInjuryRow('c) Neck          :', 'क) मान         :', _injNeckCtrl, style, marathiStyle),
        _buildInjuryRow('d) Chest         :', 'ड) छाती        :', _injChestCtrl, style, marathiStyle),
        _buildInjuryRow('e) Stomac        :', 'इ) पोट         :', _injStomachCtrl, style, marathiStyle),
        _buildInjuryRow('f) Right Hand    :', 'फ) उजवा हात     :', _injRightHandCtrl, style, marathiStyle),
        _buildInjuryRow('g) Left Hand     :', 'ग) डावा हात     :', _injLeftHandCtrl, style, marathiStyle),
        _buildInjuryRow('h) Right Leg     :', 'ह) उजवा पाय     :', _injRightLegCtrl, style, marathiStyle),
        _buildInjuryRow('i) Left Leg      :', 'ऐ) डावा पाय     :', _injLeftLegCtrl, style, marathiStyle),
        _buildInjuryRow('j) Private part  :', 'जे) गुप्त भाग     :', _injPrivatePartCtrl, style, marathiStyle),
        _buildInjuryRow('k) Back          :', 'के) पाठ        :', _injBackCtrl, style, marathiStyle),

        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Text('M.R.W', style: style.copyWith(fontSize: 10, fontStyle: FontStyle.italic)),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 3 (Inquest Main)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildInquestPage3(TextStyle style, TextStyle marathiStyle) {
    return FormPaperPage(
      formLabel: 'Page 3',
      children: [
        // 10) Injuries of Dead Body Caused By Accidental/Violence
        Text('10)   Injuries of Dead Body Caused By Accidental/Violence :', style: style.copyWith(fontWeight: FontWeight.bold)),
        Row(
          children: [
            Text('Homicide / Other Burn / (Fair / Tejab) ', style: style.copyWith(fontWeight: FontWeight.w600)),
            Expanded(child: _inlineBlank(controller: _injAccidentalViolenceCtrl, style: style)),
          ],
        ),
        _subLabel('प्रेताचे अंगावरील जखमा अपघाताच्या घोक्यातील / इत्यादी', marathiStyle),
        _subLabel('होण्यामुळे झाल्या', marathiStyle),
        const SizedBox(height: 12),

        // 11) Weapon / Means (if any)
        Row(
          children: [
            Text('11) Weapon / Means (if any)                  :', style: style.copyWith(fontWeight: FontWeight.bold)),
            Expanded(child: _inlineBlank(controller: _weaponMeansCtrl, style: style)),
          ],
        ),
        _subLabel('जखमा केलेल्या हत्यार/ साधन असल्यास           :', marathiStyle),
        const SizedBox(height: 12),

        // 12) Dead Body Cool / Warm
        Row(
          children: [
            Text('12) Dead Body Cool / Warm                    :', style: style.copyWith(fontWeight: FontWeight.bold)),
            Expanded(child: _inlineBlank(controller: _bodyCoolWarmCtrl, style: style)),
          ],
        ),
        _subLabel('प्रेत थंड आहे/ गरम आहे.                       :', marathiStyle),
        const SizedBox(height: 12),

        // 13) Position Dead Body by Poisoning
        Row(
          children: [
            Text('13) Position Dead Body by Poisoning          :', style: style.copyWith(fontWeight: FontWeight.bold)),
            Expanded(child: _inlineBlank(controller: _poisoningPositionCtrl, style: style)),
          ],
        ),
        _subLabel('प्रेताची स्थिती विष प्राशन केलेला असल्यास       :', marathiStyle),
        const SizedBox(height: 12),

        // 14) (a) Finger Print has taken by Doctor Not taken Reason
        Text('14) (a) Finger Print has taken by Doctor Not taken Reason', style: style.copyWith(fontWeight: FontWeight.bold)),
        Row(
          children: [
            Text('(In case of unidentified Dead Body)          :', style: style.copyWith(fontWeight: FontWeight.w600)),
            Expanded(child: _inlineBlank(controller: _fingerprintReasonCtrl, style: style)),
          ],
        ),
        _subLabel('अनोळखी प्रेताचे डॉक्टरांकडून बोटांचे ठसे घेतले/ नाही कारण :', marathiStyle),
        const SizedBox(height: 8),

        // (b) Photo has taken/not taken reason
        Text('(b) Photo has taken/not taken reason (In case of an', style: style.copyWith(fontWeight: FontWeight.bold)),
        Row(
          children: [
            Text('Identified Dead Body)                        :', style: style.copyWith(fontWeight: FontWeight.w600)),
            Expanded(child: _inlineBlank(controller: _photoReasonCtrl, style: style)),
          ],
        ),
        _subLabel('अनोळखी प्रेताचे फोटो घेतले आहेत काय/नाही कारण :', marathiStyle),
        const SizedBox(height: 12),

        // 15) Dead Body sent to P.M. / not reason:
        Row(
          children: [
            Text('15) Dead Body sent to P.M. / not reason: ', style: style.copyWith(fontWeight: FontWeight.bold)),
            Expanded(child: _inlineBlank(controller: _sentToPMReasonCtrl, style: style)),
          ],
        ),
        _subLabel('प्रेत (पोस्ट मार्टम) शविच्छेदन करीता पाठविले/ नाही कारण', marathiStyle),
        const SizedBox(height: 6),

        // (a) At which Hospital Dead Body sent to P.M.:
        Row(
          children: [
            Text('(a) At which Hospital Dead Body sent to P.M.:', style: style.copyWith(fontWeight: FontWeight.bold)),
            Expanded(child: _inlineBlank(controller: _hospitalNameCtrl, style: style)),
          ],
        ),
        _subLabel('कोणत्या रूग्णालयात प्रेत पोस्ट मार्टूम करीता पाठविले :', marathiStyle),
        const SizedBox(height: 6),

        // (b) With whom (Name No. and P.sm)
        Text('(b) With whom (Name No. and P.sm)            :', style: style.copyWith(fontWeight: FontWeight.bold)),
        _subLabel('कोणा बरोबर पाठविले (नांव व पो.स्टे.)', marathiStyle),
        const SizedBox(height: 4),

        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 3,
          runSpacing: 4,
          children: [
            Text('Name : ', style: style),
            _inlineBlank(controller: _sentOfficerNameCtrl, style: style, width: 220),
            Text('B/No:-', style: style),
            _inlineBlank(controller: _sentOfficerBNoCtrl, style: style, width: 110),
            Text('P.S. : ', style: style),
            _inlineBlank(controller: _sentOfficerPsCtrl, style: style, width: 140),
          ],
        ),
        Row(
          children: [
            _subLabel('नांव                                        बक्कल नंबर                 पो.स्टे', marathiStyle),
          ],
        ),
        const SizedBox(height: 12),

        // 16) Opinion of Panchas and Police about Death:
        Row(
          children: [
            Text('16) Opinion of Panchas and Police about Death: ', style: style.copyWith(fontWeight: FontWeight.bold)),
            Expanded(child: _inlineBlank(controller: _opinionPanchasCtrl, style: style)),
          ],
        ),
        _subLabel('पंच व पोलीसांचा मृत्यूविषयी अभिप्राय', marathiStyle),
        _multilineBlankBox(controller: _opinionPanchas2Ctrl, style: style, minLines: 6),
        const SizedBox(height: 12),

        // 17) More information if any
        Row(
          children: [
            Text('17) More information if any                 : ', style: style.copyWith(fontWeight: FontWeight.bold)),
            Expanded(child: _inlineBlank(controller: _moreInfoCtrl, style: style)),
          ],
        ),
        _subLabel('अधिक माहिती असल्यास', marathiStyle),

        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Text('M.R.W', style: style.copyWith(fontSize: 10, fontStyle: FontStyle.italic)),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 4 (Inquest Main)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildInquestPage4(TextStyle style, TextStyle marathiStyle) {
    return FormPaperPage(
      formLabel: 'Page 4',
      children: [
        // 18) Date and Time of panchanama
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 3,
          runSpacing: 4,
          children: [
            Text('18) Date and Time of panchanama    ', style: style.copyWith(fontWeight: FontWeight.bold)),
            Text('Date : -', style: style),
            _inlineBlank(controller: _panchanamaDateCtrl, style: style, width: 110),
            const SizedBox(width: 14),
            Text('Time:', style: style),
            _inlineBlank(controller: _panchanamaTimeCtrl, style: style, width: 75),
            Text('  To ', style: style),
            _inlineBlank(controller: _panchanamaTimeToCtrl, style: style, width: 75),
          ],
        ),
        Row(
          children: [
            _subLabel('    पंचनामा केल्याची               दिनांक : -                       वेळ : -                 ते', marathiStyle),
          ],
        ),
        const SizedBox(height: 16),

        // 19) Name of Panchas and Signature: -
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('19) Name of Panchas and Signature: -', style: style.copyWith(fontWeight: FontWeight.bold)),
                  _subLabel('    पंचनामा करणाऱ्या पंचांची नांवे : -', marathiStyle),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Signature: -', style: style.copyWith(fontWeight: FontWeight.bold)),
                  _subLabel('सह्या : -', marathiStyle),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Panch 1
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                children: [
                  Text('1) ', style: style.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(child: _multilineBlankBox(controller: _panch1Ctrl, style: style, minLines: 2)),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Row(
                children: [
                  Text('1) ', style: style.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(child: _inlineBlank(controller: _panch1SigCtrl, style: style)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Panch 2
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                children: [
                  Text('2) ', style: style.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(child: _multilineBlankBox(controller: _panch2Ctrl, style: style, minLines: 2)),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Row(
                children: [
                  Text('2) ', style: style.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(child: _inlineBlank(controller: _panch2SigCtrl, style: style)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Panch 3
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                children: [
                  Text('3) ', style: style.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(child: _multilineBlankBox(controller: _panch3Ctrl, style: style, minLines: 2)),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Row(
                children: [
                  Text('3) ', style: style.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(child: _inlineBlank(controller: _panch3SigCtrl, style: style)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // IO Signature Section
        Row(
          children: [
            const Spacer(),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Signature of Investigation Officer', style: style.copyWith(fontWeight: FontWeight.bold)),
                  _subLabel('तपासणी करणाऱ्या अधिकाऱ्यांची नांव व सह्या', marathiStyle),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Name: ', style: style),
                      Expanded(child: _inlineBlank(controller: _ioNameCtrl, style: style)),
                    ],
                  ),
                  _subLabel('नांव', marathiStyle),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Rank: ', style: style),
                      _inlineBlank(controller: _ioRankCtrl, style: style, width: 110),
                      const SizedBox(width: 6),
                      Text('Number if any:', style: style),
                      Expanded(child: _inlineBlank(controller: _ioNoCtrl, style: style)),
                    ],
                  ),
                  _subLabel('पद                   बक्कल नंबर', marathiStyle),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Posting and Address:', style: style),
                      Expanded(child: _inlineBlank(controller: _ioPostingCtrl, style: style)),
                    ],
                  ),
                  _subLabel('नेमणूक व पत्ता', marathiStyle),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Text('M.R.W', style: style.copyWith(fontSize: 10, fontStyle: FontStyle.italic)),
        ),
      ],
    );
  }

  Widget _buildCsRow({
    required String qNum,
    required String qTextEn,
    required String qTextMr,
    required Widget answerWidget,
    required TextStyle style,
    required TextStyle marathiStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 11,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$qNum $qTextEn',
                  style: style.copyWith(fontWeight: FontWeight.bold, fontSize: 13, height: 1.25),
                ),
                const SizedBox(height: 2),
                Text(
                  qTextMr,
                  style: marathiStyle.copyWith(fontSize: 10.5, color: Colors.black87, height: 1.25),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 12,
            child: answerWidget,
          ),
        ],
      ),
    );
  }

  Widget _buildCsDateTimeAnswer({
    required TextEditingController dateCtrl,
    required TextEditingController timeCtrl,
    required TextStyle style,
    required TextStyle marathiStyle,
  }) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 2,
      runSpacing: 4,
      children: [
        Text(':- दिनांक ', style: marathiStyle.copyWith(fontSize: 11.5, fontWeight: FontWeight.bold)),
        _inlineBlank(controller: dateCtrl, style: style, width: 85, hintText: 'DD/MM/YY'),
        Text(' रोजी ', style: marathiStyle.copyWith(fontSize: 11.5, fontWeight: FontWeight.bold)),
        _inlineBlank(controller: timeCtrl, style: style, width: 75, hintText: 'HH:MM'),
        Text(' वाजता.', style: marathiStyle.copyWith(fontSize: 11.5, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 5 (Police Report to Civil Surgeon - Page 1)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCivilSurgeonPage5(TextStyle style, TextStyle marathiStyle) {
    return FormPaperPage(
      formLabel: 'Page 5',
      children: [
        Text(
          'नमुना सी-६१७ स्थानांतरण/सं-२७१-कालगुण-२७११-२,००,०००(पुस्तके ४ पो.स्टे.का. ४४\n(G.R.G.D No.352 dt 21-5-12 P.M. 35 M.C in MR vide L.No.L.89-B dt.18-4-69 form I.G of Police, M.S.Bombay)',
          textAlign: TextAlign.center,
          style: marathiStyle.copyWith(fontSize: 9.5, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(
          'शवविच्छेदन परिक्षेसाठी पाठविलेल्या प्रेताबरोबर जिल्हा शल्यचिकित्सकाकडे पाठवायचा पोलीस अहवाल',
          textAlign: TextAlign.center,
          style: marathiStyle.copyWith(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        Text(
          'Police Report to be forwarded to the Civil Surgeon with Dead Bodies sent For Post-mortem examination',
          textAlign: TextAlign.center,
          style: style.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Divider(color: Colors.black87, thickness: 1.0),
        Row(
          children: [
            Expanded(
              flex: 11,
              child: Column(
                children: [
                  Text('प्रश्न', style: marathiStyle.copyWith(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  Text('Question', style: style.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Container(width: 1, height: 30, color: Colors.black26),
            Expanded(
              flex: 12,
              child: Column(
                children: [
                  Text('उत्तर', style: marathiStyle.copyWith(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  Text('Answer', style: style.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        const Divider(color: Colors.black87, thickness: 1.0),
        const SizedBox(height: 8),

        // 1) Name of Deceased
        _buildCsRow(
          qNum: '1)',
          qTextEn: 'Name of Deceased',
          qTextMr: 'मृत व्यक्तीचे नांव',
          answerWidget: _inlineBlank(controller: _csNameDeceasedCtrl, style: style),
          style: style,
          marathiStyle: marathiStyle,
        ),

        // 2) Age
        _buildCsRow(
          qNum: '2)',
          qTextEn: 'Age',
          qTextMr: 'वय',
          answerWidget: _inlineBlank(controller: _csAgeCtrl, style: style),
          style: style,
          marathiStyle: marathiStyle,
        ),

        // 3) Married, Single, Widow or Widower
        _buildCsRow(
          qNum: '3)',
          qTextEn: 'Married, Single, Widow or Widower',
          qTextMr: 'विवाहीत, अविवाहीत, विधवा किंवा विधूर',
          answerWidget: _inlineBlank(controller: _csMaritalStatusCtrl, style: style),
          style: style,
          marathiStyle: marathiStyle,
        ),

        // 4) Date and hour of death
        _buildCsRow(
          qNum: '4)',
          qTextEn: 'Date and hour of death',
          qTextMr: 'मृत्युचा दिनांक आणि वेळ',
          answerWidget: _buildCsDateTimeAnswer(
            dateCtrl: _csDeathDateCtrl,
            timeCtrl: _csDeathTimeCtrl,
            style: style,
            marathiStyle: marathiStyle,
          ),
          style: style,
          marathiStyle: marathiStyle,
        ),

        // 5) Describe condition of body when found...
        _buildCsRow(
          qNum: '5)',
          qTextEn: 'Describe condition of body when found, Position, Surroundings and any marks of Violence, bloodstains or vomited matters Which may have existed?',
          qTextMr: 'प्रेत सापडले त्यावेळची अवस्था, स्थिती, भोवतालची परिस्थिती आणि उपलब्ध असलेल्या मारहाणीच्या खुणा रक्ताचे डाग किंवा वांतीबरोबर पडलेले पदार्थ यांचा तपशील दयावा.',
          answerWidget: _multilineBlankBox(controller: _csBodyConditionCtrl, style: style, minLines: 4),
          style: style,
          marathiStyle: marathiStyle,
        ),

        // 6) Day and hour on which the body was seen...
        _buildCsRow(
          qNum: '6)',
          qTextEn: 'Day and hour on which the body was seen by the officer making the report',
          qTextMr: 'अहवाल पाठविणाऱ्या अधिकाऱ्याने प्रेत पाहिल्याचा दिनांक व वेळ (तास)',
          answerWidget: _buildCsDateTimeAnswer(
            dateCtrl: _csSeenDateCtrl,
            timeCtrl: _csSeenTimeCtrl,
            style: style,
            marathiStyle: marathiStyle,
          ),
          style: style,
          marathiStyle: marathiStyle,
        ),

        // 7) Was the body cold or warm when found?
        _buildCsRow(
          qNum: '7)',
          qTextEn: 'Was the body cold or warm when found?',
          qTextMr: 'प्रेत सापडले त्यावेळी थंड होते कि गरम',
          answerWidget: _inlineBlank(controller: _csBodyColdWarmCtrl, style: style),
          style: style,
          marathiStyle: marathiStyle,
        ),

        // 8) Had the deceased suffered from recent Illness?
        _buildCsRow(
          qNum: '8)',
          qTextEn: 'Had the deceased suffered from recent Illness? If so, what? State duration and Describe the illness as far as Known.',
          qTextMr: 'मृत व्यक्तीस अलिकडे काही आजार झाला होता काय असल्यास कोणता.',
          answerWidget: _multilineBlankBox(controller: _csRecentIllnessCtrl, style: style, minLines: 3),
          style: style,
          marathiStyle: marathiStyle,
        ),

        // 9) Had deceased suffered from accident Injury...
        _buildCsRow(
          qNum: '9)',
          qTextEn: 'Had deceased suffered from accident Injury or if so, describe it.',
          qTextMr: 'मृत व्यक्तीस कोणत्याही प्रकारचा अपघात, दुखापत किंवा मारहाण झाली होती काय ?',
          answerWidget: _multilineBlankBox(controller: _csAccidentInjuryCtrl, style: style, minLines: 2),
          style: style,
          marathiStyle: marathiStyle,
        ),

        // 10) If clothes, weapons, vomited matter...
        _buildCsRow(
          qNum: '10)',
          qTextEn: 'If clothes, weapons, vomited matter of Other articles are forwarded, State why this Is done and what relation they bear to the Case? Describe them.',
          qTextMr: 'कपडे, हत्यारे, वांतीबरोबर पडलेले पदार्थ किंवा इतर वस्तु पाठविल्या असल्यास तसे का केले व त्याचा प्रकरणाशी संबंध आहे ते लिहावे, त्याचा तपशील दयावा.',
          answerWidget: _multilineBlankBox(controller: _csArticlesForwardedCtrl, style: style, minLines: 4),
          style: style,
          marathiStyle: marathiStyle,
        ),

        // 11) Is death supposed to have been due to Natural causes...
        _buildCsRow(
          qNum: '11)',
          qTextEn: 'Is death supposed to have been due to Natural causes, accident, suicide or homicide? State briefly and plainly, any suspicions That may exist and why?',
          qTextMr: 'मृत्यु नैसर्गिक कारणे, अपघात, आत्महत्या किंवा खून यापैकी कशामुळे घडला असे वाटते. काही संशय असल्यास ते थोडक्यात स्पष्टपणे नमुद करावे व कारणे दयावे.',
          answerWidget: _multilineBlankBox(controller: _csDeathReasonCtrl, style: style, minLines: 4),
          style: style,
          marathiStyle: marathiStyle,
        ),

        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Text('M.R.W', style: style.copyWith(fontSize: 10, fontStyle: FontStyle.italic)),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 6 (Police Report to Civil Surgeon - Page 2)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCivilSurgeonPage6(TextStyle style, TextStyle marathiStyle) {
    return FormPaperPage(
      formLabel: 'Page 6',
      children: [
        const Divider(color: Colors.black87, thickness: 1.0),
        Row(
          children: [
            Expanded(
              flex: 11,
              child: Column(
                children: [
                  Text('प्रश्न', style: marathiStyle.copyWith(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  Text('Question', style: style.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Container(width: 1, height: 30, color: Colors.black26),
            Expanded(
              flex: 12,
              child: Column(
                children: [
                  Text('उत्तर', style: marathiStyle.copyWith(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  Text('Answer', style: style.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        const Divider(color: Colors.black87, thickness: 1.0),
        const SizedBox(height: 8),

        // 12) Is there suspicion of poisoning?
        _buildCsRow(
          qNum: '12)',
          qTextEn: 'Is there suspicion of poisoning? If, so, is any particular poison supposed to have been employed? Mention any symptoms of poisoning which are reported to have existed during life and any appearances pointing to poisoning observed after death.',
          qTextMr: 'विष प्रयोग केल्याचा संशय आहे, असल्यास विशिष्ट विषाचा वापर केला आहे वाटते काय? मृत व्यक्ती जिवंत असतांना विषबाधा झाल्याची लक्षणे दिसून आल्याचे कळविण्यात आले होते काय, व विषाचे बाबत मृत्यु नंतर दिसून आलेली चिन्हे नमुद करावी.',
          answerWidget: _multilineBlankBox(controller: _csPoisonSuspicionCtrl, style: style, minLines: 5),
          style: style,
          marathiStyle: marathiStyle,
        ),

        // 13) In the case of a woman...
        _buildCsRow(
          qNum: '13)',
          qTextEn: 'In the case of a woman, is she supposed to be pregnant of to have been recently delivered ?',
          qTextMr: 'स्त्रीच्या बाबतीत ती गरोदर असावी किंवा अलीकडे प्रसुती झाली असावी असे वाटते काय ?',
          answerWidget: _multilineBlankBox(controller: _csWomanPregnancyCtrl, style: style, minLines: 2),
          style: style,
          marathiStyle: marathiStyle,
        ),

        // 14) Is abortion or attempted abortion...
        _buildCsRow(
          qNum: '14)',
          qTextEn: 'Is abortion or attempted abortion known or suspected? And if the former, has the focus been found?',
          qTextMr: 'गर्भपात केला किंवा गर्भपात करण्याचा प्रयत्न केला या विषयी माहिती किंवा संशय आहे काय, गर्भपात केला असल्यास गर्भ सापडला काय.',
          answerWidget: _multilineBlankBox(controller: _csAbortionCtrl, style: style, minLines: 2),
          style: style,
          marathiStyle: marathiStyle,
        ),

        // 15) State the finding of the Jury...
        _buildCsRow(
          qNum: '15)',
          qTextEn: 'State the finding of the Jury (if any) and mention any reasons they may have given for their findings.',
          qTextMr: 'ज्युरीचे निष्कर्ष असल्यास नमुद करावेत व निष्कर्षा बाबत त्यांनी काही कारणे दिली असल्यास त्याचा निर्देश करावा.',
          answerWidget: _multilineBlankBox(controller: _csJuryFindingsCtrl, style: style, minLines: 2),
          style: style,
          marathiStyle: marathiStyle,
        ),

        // 16) Remarks
        _buildCsRow(
          qNum: '16)',
          qTextEn: 'Remarks. Under this head the Police Officer should give any information not included in the above question which he may consider likely to assist the Civil Surgeon informing an opinion of the cause of death.',
          qTextMr: 'शेरा वरील प्रश्नात समाविष्ट न झालेली परंतु पोलीस अधिकाऱ्यांच्या मते जिल्हा शल्यचिकित्सकांना मृत्युच्या कारणाविषयी आपले मत बनविण्यास सहाय्यभूत होण्याचा संभव आहे अशी कोणत्याही प्रकारची माहिती या शीर्षका खाली दयावी.',
          answerWidget: _multilineBlankBox(controller: _csRemarksCtrl, style: style, minLines: 5),
          style: style,
          marathiStyle: marathiStyle,
        ),

        const SizedBox(height: 12),
        _multilineBlankBox(controller: _csExtraNotesCtrl, style: style, minLines: 1),
        const SizedBox(height: 24),

        // IO Signature Section
        Row(
          children: [
            const Spacer(),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _subLabel('तपासणी करणाऱ्या अधिकाऱ्यांची नांव व सही', marathiStyle),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Name: ', style: style),
                      Expanded(child: _inlineBlank(controller: _csIoNameCtrl, style: style)),
                    ],
                  ),
                  _subLabel('नांव', marathiStyle),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Rank: ', style: style),
                      _inlineBlank(controller: _csIoRankCtrl, style: style, width: 110),
                      const SizedBox(width: 6),
                      Text('Number if any:', style: style),
                      Expanded(child: _inlineBlank(controller: _csIoNoCtrl, style: style)),
                    ],
                  ),
                  _subLabel('पद                   बक्कल नंबर', marathiStyle),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Posting and Address:', style: style),
                      Expanded(child: _inlineBlank(controller: _csIoPostingCtrl, style: style)),
                    ],
                  ),
                  _subLabel('नेमणूक व पत्ता', marathiStyle),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Text('M.R.W', style: style.copyWith(fontSize: 10, fontStyle: FontStyle.italic)),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 7 (Vinanti Arj / Post Mortem Request Application)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildVinantiArjPage7(TextStyle style, TextStyle marathiStyle) {
    return FormPaperPage(
      formLabel: 'Page 7',
      children: [
        // Title
        Center(
          child: Column(
            children: [
              Text(
                'विनंती अर्ज',
                style: marathiStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dotted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Top Right: पोलीस स्टेशन / दिनांक
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('पोलीस स्टेशन', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                    _inlineBlank(controller: _reqPsCtrl, style: style, width: 140),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('दिनांक :- ', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                    _inlineBlank(controller: _reqDateCtrl, style: style, width: 110, hintText: 'DD/MM/20YY'),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Recipient (प्रति)
        Text('प्रति,', style: marathiStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
        Padding(
          padding: const EdgeInsets.only(left: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('मा. न्यायवैद्यक शास्त्र विभाग प्रमुख', style: marathiStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              _inlineBlank(controller: _reqToCtrl, style: style, width: 280),
              const SizedBox(height: 4),
              _inlineBlank(controller: _reqTo2Ctrl, style: style, width: 280),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // From (पासुन)
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('पासुन  :-    पोलीस स्टेशन', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
            _inlineBlank(controller: _reqFromPsCtrl, style: style, width: 140),
            Text('  जिल्हा यवतमाळ.', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),

        // Subject (विषय)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('विषय  :-    ', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('मृतक नामे ', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                      _inlineBlank(controller: _reqSubjectNameCtrl, style: style, width: 340),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('पो.स्टे.', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                      _inlineBlank(controller: _reqSubjectPsCtrl, style: style, width: 110),
                      Text('  ता-', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                      _inlineBlank(controller: _reqSubjectTaCtrl, style: style, width: 100),
                      Text('  जिल्हा यवतमाळ हिचे/ ह्यांचे प्रेताचे पि.एम', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('करून आपला अभिप्राय मिळणेबाबत.', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(child: Text('० ० ० ०', style: marathiStyle.copyWith(letterSpacing: 4))),
        const SizedBox(height: 8),

        // Body (महोदय)
        Text('महोदय,', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 6,
            spacing: 2,
            children: [
              Text('सविनय सेवेशी सादर आहे की, आज दिनांक ', style: marathiStyle),
              _inlineBlank(controller: _reqMargDateCtrl, style: style, width: 85, hintText: 'DD/MM/YY'),
              Text(' रोजी ', style: marathiStyle),
              _inlineBlank(controller: _reqMargTimeCtrl, style: style, width: 65, hintText: 'HH:MM'),
              Text(' वाजता पोलीस स्टेशन ', style: marathiStyle),
              _inlineBlank(controller: _reqMargPsCtrl, style: style, width: 120),
              Text(' मर्ग/ स्टेशन डायरी क्र.', style: marathiStyle),
              _inlineBlank(controller: _reqMargDiaryNoCtrl, style: style, width: 75),
              Text('/२०', style: marathiStyle),
              _inlineBlank(controller: _reqMargYearCtrl, style: style, width: 45),
              Text(' कलम १९४ बी.एन.एस.एस २०२३ चा मर्ग दाखल झाला असुन यातील मृतक नामे ', style: marathiStyle),
              _inlineBlank(controller: _reqMargNameCtrl, style: style, width: 260),
              Text(' पो.स्टे.', style: marathiStyle),
              _inlineBlank(controller: _reqSubjectPsCtrl, style: style, width: 110),
              Text(' ता-', style: marathiStyle),
              _inlineBlank(controller: _reqMargTaCtrl, style: style, width: 100),
              Text(' जिल्हा यवतमाळ ही/ह्या ', style: marathiStyle),
              _inlineBlank(controller: _reqHospitalNameCtrl, style: style, width: 180, hintText: 'दवाखान्याचे नांव'),
              Text(' येथे दिनांक ', style: marathiStyle),
              _inlineBlank(controller: _reqAdmitDateCtrl, style: style, width: 85, hintText: 'DD/MM/YY'),
              Text(' रोजी ', style: marathiStyle),
              _inlineBlank(controller: _reqAdmitTimeCtrl, style: style, width: 65, hintText: 'HH:MM'),
              Text(' वाजता भरती झाला असुन औषधोपचारा दरम्यान/ गळफास लावुन/ विष प्राशन करून/अपघात/ ', style: marathiStyle),
              _inlineBlank(controller: _reqReasonDetailsCtrl, style: style, width: 220),
              Text(' दिनांक ', style: marathiStyle),
              _inlineBlank(controller: _reqDeathDateCtrl, style: style, width: 85, hintText: 'DD/MM/YY'),
              Text(' रोजी ', style: marathiStyle),
              _inlineBlank(controller: _reqDeathTimeCtrl, style: style, width: 65, hintText: 'HH:MM'),
              Text(' वाजता मरण पावला आहे.', style: marathiStyle),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Text(
            'तरी सदर मृतकाचे मरणाचे निश्चीत कारण समजुन येणेकरीता सदर मृतकाचे प्रेताचे पी.एम करून आपला सविस्तर अभिप्राय मिळणेस विनंती आहे.',
            style: marathiStyle.copyWith(height: 1.4),
          ),
        ),
        const SizedBox(height: 20),

        // Bottom Row: Attachments on Left | IO Signature on Right
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: सहपत्र & हस्ते
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('सहपत्र : प्रश्नोत्तर फॉर्म', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                  Padding(
                    padding: const EdgeInsets.only(left: 45.0),
                    child: Text('इंक्वेस्ट पंचनामा', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('हस्ते : ', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                      _inlineBlank(controller: _reqHasteNameCtrl, style: style, width: 140),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('पो.स्टे. : ', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                      _inlineBlank(controller: _reqHastePsCtrl, style: style, width: 140),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Right: IO Signature
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('तपासी अधिकारी नांव /सही शिक्या', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Name: ', style: style),
                      Expanded(child: _inlineBlank(controller: _reqIoNameCtrl, style: style)),
                    ],
                  ),
                  _subLabel('नांव', marathiStyle),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Rank: ', style: style),
                      _inlineBlank(controller: _reqIoRankCtrl, style: style, width: 100),
                      const SizedBox(width: 4),
                      Text('No:', style: style),
                      Expanded(child: _inlineBlank(controller: _reqIoNoCtrl, style: style)),
                    ],
                  ),
                  _subLabel('पद                   बक्कल नंबर', marathiStyle),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Posting:', style: style),
                      Expanded(child: _inlineBlank(controller: _reqIoPostingCtrl, style: style)),
                    ],
                  ),
                  _subLabel('नेमणूक व पत्ता', marathiStyle),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Text('M.R.W', style: style.copyWith(fontSize: 10, fontStyle: FontStyle.italic)),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 8 (Relative Summons / नातेवाईकांना समन्स)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildRelativeSummonsPage8(TextStyle style, TextStyle marathiStyle) {
    return FormPaperPage(
      formLabel: 'Page 8',
      children: [
        // Title
        Center(
          child: Column(
            children: [
              Text(
                'नातेवाईकांना समन्स',
                style: marathiStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dotted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '(कलम १७९ भारतीय नागरिक सुरक्षा संहिता २०२३ अन्वये)',
                style: marathiStyle.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dotted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Top Right: पोलीस स्टेशन / कॅम्प / दिनांक
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('पोलीस स्टेशन', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                    _inlineBlank(controller: _relPsCtrl, style: style, width: 140),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('कॅम्प :- ', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                    _inlineBlank(controller: _relCampCtrl, style: style, width: 155),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('दिनांक :- ', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                    _inlineBlank(controller: _relDateCtrl, style: style, width: 110, hintText: 'DD/MM/20YY'),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Recipient (नांव :-)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('नांव  :-   ', style: marathiStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
            Expanded(
              child: _multilineBlankBox(controller: _relToNameCtrl, style: style, minLines: 4),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(child: Text('० ० ० ०', style: marathiStyle.copyWith(letterSpacing: 4))),
        const SizedBox(height: 12),

        // Body Paragraph
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 6,
            spacing: 2,
            children: [
              Text('आपणास या समन्सव्दारे कळविण्यात येते की, आम्ही ', style: marathiStyle),
              _inlineBlank(controller: _relWeNameCtrl, style: style, width: 220),
              Text(' पोलीस स्टेशन ', style: marathiStyle),
              _inlineBlank(controller: _relPsNameCtrl, style: style, width: 140),
              Text(' येथील अप/ मर्ग/ ठाणे दैनंदिनी क्रमांक ', style: marathiStyle),
              _inlineBlank(controller: _relCrDiaryNoCtrl, style: style, width: 75),
              Text('/२०', style: marathiStyle),
              _inlineBlank(controller: _relCrYearCtrl, style: style, width: 45),
              Text(' कलम ', style: marathiStyle),
              _inlineBlank(controller: _relActSecCtrl, style: style, width: 180),
              Text(' मधील मृतक नामे ', style: marathiStyle),
              _inlineBlank(controller: _relDeceasedNameCtrl, style: style, width: 260),
              Text(' ता-', style: marathiStyle),
              _inlineBlank(controller: _relTaCtrl, style: style, width: 110),
              Text(' जिल्हा ', style: marathiStyle),
              _inlineBlank(controller: _relDistCtrl, style: style, width: 110),
              Text(' यांचे प्रेताचा इंन्क्वेस्ट पंचनामा करणार आहो. करीता आपण प्रेत ओळखुन देवून मृतकाचे नातेवाईक या नात्याने पंचनाम्याची कार्यवाही पूर्ण होईपर्यंत आमचे सोबत हजर राहावे.', style: marathiStyle),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Bottom Row: सही on Left | IO Signature on Right
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: सही (१, २, ३, ४)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('सही', style: marathiStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('१) ', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                      Expanded(child: _inlineBlank(controller: _relSig1Ctrl, style: style)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('२) ', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                      Expanded(child: _inlineBlank(controller: _relSig2Ctrl, style: style)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('३) ', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                      Expanded(child: _inlineBlank(controller: _relSig3Ctrl, style: style)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('४) ', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                      Expanded(child: _inlineBlank(controller: _relSig4Ctrl, style: style)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Right: IO Signature
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('तपासी अधिकारी नांव / सही शिक्या', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Name: ', style: style),
                      Expanded(child: _inlineBlank(controller: _relIoNameCtrl, style: style)),
                    ],
                  ),
                  _subLabel('नांव', marathiStyle),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Rank: ', style: style),
                      _inlineBlank(controller: _relIoRankCtrl, style: style, width: 100),
                      const SizedBox(width: 4),
                      Text('Number if any:', style: style),
                      Expanded(child: _inlineBlank(controller: _relIoNoCtrl, style: style)),
                    ],
                  ),
                  _subLabel('पद                   बक्कल नंबर', marathiStyle),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Posting and Address:', style: style),
                      Expanded(child: _inlineBlank(controller: _relIoPostingCtrl, style: style)),
                    ],
                  ),
                  _subLabel('नेमणूक व पत्ता', marathiStyle),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Text('M.R.W', style: style.copyWith(fontSize: 10, fontStyle: FontStyle.italic)),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 9 (Pancha Summons / पंचांना समन्स)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPanchaSummonsPage9(TextStyle style, TextStyle marathiStyle) {
    return FormPaperPage(
      formLabel: 'Page 9',
      children: [
        // Title
        Center(
          child: Column(
            children: [
              Text(
                'पंचांना समन्स',
                style: marathiStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dotted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '(कलम १९५ भारतीय नागरिक सुरक्षा संहिता २०२३ अन्वये)',
                style: marathiStyle.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  decorationStyle: TextDecorationStyle.dotted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Top Right: पोलीस स्टेशन / कॅम्प / दिनांक
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('पोलीस स्टेशन', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                    _inlineBlank(controller: _panPsCtrl, style: style, width: 140),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('कॅम्प :- ', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                    _inlineBlank(controller: _panCampCtrl, style: style, width: 155),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('दिनांक :- ', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                    _inlineBlank(controller: _panDateCtrl, style: style, width: 110, hintText: 'DD/MM/20YY'),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Recipient (नांव :-)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('नांव  :-   ', style: marathiStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
            Expanded(
              child: _multilineBlankBox(controller: _panToNameCtrl, style: style, minLines: 4),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(child: Text('० ० ० ०', style: marathiStyle.copyWith(letterSpacing: 4))),
        const SizedBox(height: 12),

        // Body Paragraph
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 6,
            spacing: 2,
            children: [
              Text('आपणास या समन्सव्दारे कळविण्यात येते की, आम्ही ', style: marathiStyle),
              _inlineBlank(controller: _panWeNameCtrl, style: style, width: 220),
              Text(' पोलीस स्टेशन ', style: marathiStyle),
              _inlineBlank(controller: _panPsNameCtrl, style: style, width: 140),
              Text(' येथील अप/ मर्ग/ ठाणे दैनंदिनी क्रमांक ', style: marathiStyle),
              _inlineBlank(controller: _panCrDiaryNoCtrl, style: style, width: 75),
              Text('/२०', style: marathiStyle),
              _inlineBlank(controller: _panCrYearCtrl, style: style, width: 45),
              Text(' कलम ', style: marathiStyle),
              _inlineBlank(controller: _panActSecCtrl, style: style, width: 180),
              Text(' मधील मृतक नामे ', style: marathiStyle),
              _inlineBlank(controller: _panDeceasedNameCtrl, style: style, width: 260),
              Text(' ता-', style: marathiStyle),
              _inlineBlank(controller: _panTaCtrl, style: style, width: 110),
              Text(' जिल्हा ', style: marathiStyle),
              _inlineBlank(controller: _panDistCtrl, style: style, width: 110),
              Text(' यांचे प्रेताचा इंन्क्वेस्ट पंचनामा करणार आहो. करीता आपण पंचनाम्याची कार्यवाही पूर्ण होईपर्यंत पंच म्हणुन आमचे सोबत हजर राहावे.', style: marathiStyle),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Bottom Row: पंच सही on Left | IO Signature on Right
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: पंच सही (१, २, ३, ४)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('पंच सही', style: marathiStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('१) ', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                      Expanded(child: _inlineBlank(controller: _panSig1Ctrl, style: style)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('२) ', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                      Expanded(child: _inlineBlank(controller: _panSig2Ctrl, style: style)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('३) ', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                      Expanded(child: _inlineBlank(controller: _panSig3Ctrl, style: style)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('४) ', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                      Expanded(child: _inlineBlank(controller: _panSig4Ctrl, style: style)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Right: IO Signature
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('तपासी अधिकारी नांव / सही शिक्या', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Name: ', style: style),
                      Expanded(child: _inlineBlank(controller: _panIoNameCtrl, style: style)),
                    ],
                  ),
                  _subLabel('नांव', marathiStyle),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Rank: ', style: style),
                      _inlineBlank(controller: _panIoRankCtrl, style: style, width: 100),
                      const SizedBox(width: 4),
                      Text('Number if any:', style: style),
                      Expanded(child: _inlineBlank(controller: _panIoNoCtrl, style: style)),
                    ],
                  ),
                  _subLabel('पद                   बक्कल नंबर', marathiStyle),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('Posting and Address:', style: style),
                      Expanded(child: _inlineBlank(controller: _panIoPostingCtrl, style: style)),
                    ],
                  ),
                  _subLabel('नेमणूक व पत्ता', marathiStyle),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Text('M.R.W', style: style.copyWith(fontSize: 10, fontStyle: FontStyle.italic)),
        ),
      ],
    );
  }

  Widget _buildHabitRow({
    required String label,
    required String marathiLabel,
    required bool checked,
    required ValueChanged<bool?> onChanged,
    required TextEditingController daysController,
    required TextStyle serifStyle,
    required TextStyle marathiLabelStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: BilingualSectionHeader(
                  label: label,
                  marathiLabel: marathiLabel,
                  serifStyle: serifStyle,
                  marathiLabelStyle: marathiLabelStyle,
                ),
              ),
              Checkbox(
                value: checked,
                onChanged: widget.readOnly ? null : onChanged,
              ),
              Text('Yes / होय', style: serifStyle.copyWith(fontSize: 12)),
            ],
          ),
          BilingualField(
            label: 'If yes, since how many days :-',
            marathiLabel: 'असल्यास किती दिवसांपासून',
            controller: daysController,
            serifStyle: serifStyle,
            marathiLabelStyle: marathiLabelStyle,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.lora(
      fontSize: 13.5,
      fontWeight: FontWeight.normal,
      color: Colors.black87,
    );
    final marathiStyle = GoogleFonts.notoSansDevanagari(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: Colors.black87,
    );
    final TextStyle serifStyle = FormTypography.serifStyle();
    final TextStyle marathiLabelStyle = FormTypography.marathiLabelStyle();

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        if (_shows(kMainInquest)) ...[
          _buildInquestPage1(style, marathiStyle),
          const SizedBox(height: 24),
          _buildInquestPage2(style, marathiStyle),
          const SizedBox(height: 24),
          _buildInquestPage3(style, marathiStyle),
          const SizedBox(height: 24),
          _buildInquestPage4(style, marathiStyle),
        ],
        if (_shows(kMainInquest) && (_shows(kCivilSurgeon) || widget.formSection?.isEmpty == true))
          const SizedBox(height: 24),
        if (_shows(kCivilSurgeon)) ...[
          _buildCivilSurgeonPage5(style, marathiStyle),
          const SizedBox(height: 24),
          _buildCivilSurgeonPage6(style, marathiStyle),
        ],
        if (_shows(kVinantiArj))
          _buildVinantiArjPage7(style, marathiStyle),
        if (_shows(kRelativeSummons))
          _buildRelativeSummonsPage8(style, marathiStyle),
        if (_shows(kPanchaSummons))
          _buildPanchaSummonsPage9(style, marathiStyle),
        if (_shows(kMarananveshan))
          FormPaperPage(
            formLabel: 'Page 10',
            children: [
              BilingualSectionHeader(
                label: 'MARANANVESHAN PANCHANAMA (SIMPLIFIED MARATHI INQUEST)',
                marathiLabel: 'मरणान्वेषण पंचनामा (मराठी नमुना)',
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              const SizedBox(height: 12),
              BilingualFieldRow(fields: [
                BilingualField(label: '1) Place :-', marathiLabel: '१) ठिकाण', controller: _marThikanCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'Date :-', marathiLabel: 'दिनांक', controller: _marDateCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'Time :-', marathiLabel: 'वेळ', controller: _marTimeCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              ]),
              BilingualMultilineField(label: '2) Panch Name & Address :-', marathiLabel: '२) पंचांचे नांव व पत्ता', controller: _marPanchNameAddressCtrl, minLines: 2, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              BilingualFieldRow(fields: [
                BilingualField(label: '3) Police Station :-', marathiLabel: '३) पोलीस ठाणे', controller: _marPsCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'Dist. :-', marathiLabel: 'जिल्हा', controller: _marDistCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              ]),
              BilingualFieldRow(fields: [
                BilingualField(label: '4) Diary No. :-', marathiLabel: '४) डायरी क्र.', controller: _marDiaryNoCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'Act & Sec. :-', marathiLabel: 'कलम', controller: _marActSecCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              ]),
              BilingualField(label: '5) Investigation Officer :-', marathiLabel: '५) तपासणी अधिकारी', controller: _marIoDetailsCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              BilingualField(label: '6) Complainant Name :-', marathiLabel: '६) फिर्यादीचे नांव', controller: _marComplainantNameCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              BilingualMultilineField(label: '7) Deceased Name & Address :-', marathiLabel: '७) मृताचे नांव व पत्ता', controller: _marDeceasedNameAddressCtrl, minLines: 2, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              BilingualField(label: '8) Body Shown By :-', marathiLabel: '८) प्रेत दाखविणारा', controller: _marShownByNameCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              BilingualMultilineField(label: '9) Place Description :-', marathiLabel: '९) ठिकाणाचे वर्णन', controller: _marThikanDescriptionCtrl, minLines: 2, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              BilingualMultilineField(label: '10) Body Position & Condition :-', marathiLabel: '१०) प्रेताची स्थिती व अवस्था', controller: _marBodyConditionCtrl, minLines: 2, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              BilingualMultilineField(label: '11) Clothes on Body :-', marathiLabel: '११) प्रेताच्या अंगावरील कपडे', controller: _marBodyClothesCtrl, minLines: 2, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              BilingualMultilineField(label: '12) Ornaments on Body :-', marathiLabel: '१२) प्रेताच्या अंगावरील दागिने', controller: _marBodyOrnamentsCtrl, minLines: 2, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
            ],
          ),
        if (_shows(kMarananveshan))
          FormPaperPage(
            formLabel: 'Page 11',
            children: [
              BilingualSectionHeader(
                label: 'MARANANVESHAN PANCHANAMA (Continuation)',
                marathiLabel: 'मरणान्वेषण पंचनामा (पुढे चालू)',
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              const SizedBox(height: 12),
              BilingualMultilineField(label: '13) Injuries on Body :-', marathiLabel: '१३) प्रेताच्या अंगावरील जखमा', controller: _mar13InjuriesCtrl, minLines: 2, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              BilingualMultilineField(label: '14) Other Identification Marks :-', marathiLabel: '१४) इतर ओळखचिन्हे', controller: _mar14OtherMarksCtrl, minLines: 2, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              BilingualMultilineField(label: '15) Disposal of Ornaments / Articles :-', marathiLabel: '१५) दागिने / वस्तूंची विल्हेवाट', controller: _mar15OrnamentsDisposalCtrl, minLines: 2, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              BilingualMultilineField(label: '16) Panchas Opinion on Cause of Death :-', marathiLabel: '१६) मृत्यूच्या कारणाबाबत पंचांचे मत', controller: _mar16OpinionCtrl, minLines: 3, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              BilingualMultilineField(label: '17) Body Sent to PM / Handover :-', marathiLabel: '१७) प्रेत शवविच्छेदनासाठी पाठविले / ताब्यात दिले', controller: _mar17BodyDisposalCtrl, minLines: 2, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              BilingualField(label: '18) Panchanama Completion Date & Time :-', marathiLabel: '१८) पंचनामा पूर्ण झाल्याची तारीख व वेळ', controller: _mar18DateTimeCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              const SizedBox(height: 12),
              BilingualSectionHeader(label: 'Signatures of Panchas :-', marathiLabel: 'पंचांच्या सह्या', serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              BilingualFieldRow(fields: [
                BilingualField(label: '1) :-', marathiLabel: '१)', controller: _mar11Panch1Ctrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: '2) :-', marathiLabel: '२)', controller: _mar11Panch2Ctrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              ]),
              BilingualFieldRow(fields: [
                BilingualField(label: '3) :-', marathiLabel: '३)', controller: _mar11Panch3Ctrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: '4) :-', marathiLabel: '४)', controller: _mar11Panch4Ctrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              ]),
              const SizedBox(height: 16),
              BilingualFieldRow(fields: [
                BilingualField(label: 'IO Name :-', marathiLabel: 'तपासणी अधिकारी', controller: _mar11IoNameCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'Rank :-', marathiLabel: 'पद', controller: _mar11IoRankCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'P.S. :-', marathiLabel: 'पो.स्टे.', controller: _mar11IoPsCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              ]),
              BilingualField(label: 'Copy Sent to (Court / Magistrate) :-', marathiLabel: 'प्रत रवाना (न्यायालय / दंडाधिकारी)', controller: _mar11CopyToCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
            ],
          ),
        if (_shows(kKalmi14))
          FormPaperPage(
            formLabel: 'Page 12',
            children: [
              BilingualSectionHeader(
                label: '14-KALAMI FORM (INFORMATION TO MEDICAL OFFICER)',
                marathiLabel: '१४ कलमी फॉर्म (वैद्यकीय अधिकाऱ्यास माहिती)',
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              const SizedBox(height: 12),
              BilingualField(label: '1) Name and Age of Deceased :-', marathiLabel: '१) मृताचे नांव व वय', controller: _kal14NameAgeCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              BilingualMultilineField(label: '2) Address :-', marathiLabel: '२) पत्ता', controller: _kal14AddressCtrl, minLines: 2, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              BilingualFieldRow(fields: [
                BilingualField(label: '3) Body Brought From :-', marathiLabel: '३) मृतदेह कुठून आणला', controller: _kal14ShavFromCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'To :-', marathiLabel: 'कुठे नेला', controller: _kal14ShavToCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              ]),
              BilingualFieldRow(fields: [
                BilingualField(label: "4) Mother's Name :-", marathiLabel: '४) आईचे नांव', controller: _kal14AaiNameCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: "Father's Name :-", marathiLabel: 'वडिलांचे नांव', controller: _kal14BaapNameCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              ]),
              BilingualFieldRow(fields: [
                BilingualField(label: '5) Religion :-', marathiLabel: '५) धर्म', controller: _kal14DharmCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: '6) Occupation :-', marathiLabel: '६) व्यवसाय', controller: _kal14VyavsayCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              ]),
              const SizedBox(height: 8),
              BilingualSectionHeader(label: '7–10) Habits of the Deceased :-', marathiLabel: '७–१०) मृताच्या सवयी', serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              _buildHabitRow(label: '7) Smoking / Cigarette :-', marathiLabel: '७) धुम्रपान / विडी-सिगारेट', checked: _kal14Cigarette, onChanged: (v) => setState(() => _kal14Cigarette = v ?? false), daysController: _kal14CigaretteDaysCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              _buildHabitRow(label: '8) Alcohol / Liquor :-', marathiLabel: '८) दारूचे सेवन', checked: _kal14Daru, onChanged: (v) => setState(() => _kal14Daru = v ?? false), daysController: _kal14DaruDaysCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              _buildHabitRow(label: '9) Tobacco :-', marathiLabel: '९) तंबाखू', checked: _kal14Tambakhu, onChanged: (v) => setState(() => _kal14Tambakhu = v ?? false), daysController: _kal14TambakhuDaysCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              _buildHabitRow(label: '10) Pan Masala / Gutkha :-', marathiLabel: '१०) पान मसाला / गुटखा', checked: _kal14PanMasala, onChanged: (v) => setState(() => _kal14PanMasala = v ?? false), daysController: _kal14PanMasalaDaysCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
            ],
          ),
        if (_shows(kKalmi14))
          FormPaperPage(
            formLabel: 'Page 13',
            children: [
              BilingualSectionHeader(
                label: '14-KALAMI FORM (Continuation - Q11 to Q14)',
                marathiLabel: '१४ कलमी फॉर्म (पुढे चालू - प्रश्न ११ ते १४)',
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              const SizedBox(height: 12),
              BilingualField(label: '11) (a) Vehicle Involved :-', marathiLabel: '११) (अ) अपघातातील वाहन', controller: _kal14VehicleNameCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              BilingualFieldRow(fields: [
                BilingualField(label: '(b) Driver / Passenger :-', marathiLabel: '(ब) चालक / प्रवासी', controller: _kal14DriverPassCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: '(c) Pedestrian :-', marathiLabel: '(क) पादचारी', controller: _kal14PedestrianCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              ]),
              BilingualMultilineField(label: '(d) How Accident Occurred :-', marathiLabel: '(ड) अपघात कसा घडला', controller: _kal14AccidentHowCtrl, minLines: 2, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              BilingualField(label: '(e) Date & Time of Accident :-', marathiLabel: '(इ) अपघाताची तारीख व वेळ', controller: _kal14AccidentDateTimeCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              BilingualMultilineField(label: '12) Fall from Height Details (if applicable) :-', marathiLabel: '१२) उंचावरून पडल्याचा तपशील', controller: _kal14FallInfoCtrl, minLines: 2, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              BilingualFieldRow(fields: [
                BilingualField(label: '13) (a) If pregnant, months :-', marathiLabel: '१३) (अ) गरोदर असल्यास, महिने', controller: _kal14PregnantMonthsCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: '(b) Delivery / Abortion :-', marathiLabel: '(ब) प्रसूती / गर्भपात', controller: _kal14DeliveredAbortionCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: '(c) Days :-', marathiLabel: '(क) दिवस', controller: _kal14PregnantDaysCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              ]),
              BilingualField(label: '14) Body Identified By :-', marathiLabel: '१४) मृतदेह ओळखणारा', controller: _kal14IdentifierNameCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              const SizedBox(height: 24),
              BilingualFieldRow(fields: [
                BilingualField(label: 'IO Name :-', marathiLabel: 'तपासणी अधिकारी', controller: _kal14IoNameCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'Rank :-', marathiLabel: 'पद', controller: _kal14IoRankCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'P.S. :-', marathiLabel: 'पो.स्टे.', controller: _kal14IoPsCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              ]),
            ],
          ),
        if (_shows(kBodyHandover))
          FormPaperPage(
            formLabel: 'Page 14',
            children: [
              BilingualSectionHeader(
                label: 'PRET TABA PAVATI (DEAD BODY HANDOVER RECEIPT)',
                marathiLabel: 'प्रेत ताबा पावती',
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              const SizedBox(height: 12),
              BilingualFieldRow(fields: [
                BilingualField(label: 'Police Station :-', marathiLabel: 'पोलीस ठाणे', controller: _ptpPsCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'Camp :-', marathiLabel: 'मुक्काम', controller: _ptpCampCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'Date :-', marathiLabel: 'दिनांक', controller: _ptpDateCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              ]),
              BilingualField(label: 'Receiver Name (Whom body handed over) :-', marathiLabel: 'ताबा घेणारा (ज्यांच्या ताब्यात प्रेत दिले)', controller: _ptpReceiverNameCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              BilingualFieldRow(fields: [
                BilingualField(label: 'R/o (पत्ता) :-', marathiLabel: 'रा.', controller: _ptpReceiverRaCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'Ta. :-', marathiLabel: 'ता.', controller: _ptpReceiverTaCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'Dist. :-', marathiLabel: 'जिल्हा', controller: _ptpReceiverDistCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              ]),
              BilingualFieldRow(fields: [
                BilingualField(label: 'Mobile No. :-', marathiLabel: 'मो.नं.', controller: _ptpMoNoCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'Receipt Date :-', marathiLabel: 'पावती तारीख', controller: _ptpReceiptDateCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              ]),
              BilingualField(label: 'Deceased Name :-', marathiLabel: 'मृताचे नांव', controller: _ptpDeceasedNameCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              BilingualFieldRow(fields: [
                BilingualField(label: 'Deceased R/o :-', marathiLabel: 'मृताचा पत्ता', controller: _ptpDeceasedRaCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'Dist. :-', marathiLabel: 'जिल्हा', controller: _ptpDeceasedDistCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              ]),
              const SizedBox(height: 16),
              BilingualField(label: 'Signature / Thumb of Receiver :-', marathiLabel: 'ताबा घेणाऱ्याची सही / अंगठा', controller: _ptpReceiverSigCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              const SizedBox(height: 24),
              BilingualFieldRow(fields: [
                BilingualField(label: 'IO Name :-', marathiLabel: 'तपासणी अधिकारी', controller: _ptpIoNameCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'Rank :-', marathiLabel: 'पद', controller: _ptpIoRankCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'P.S. :-', marathiLabel: 'पो.स्टे.', controller: _ptpIoPsCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              ]),
            ],
          ),
        if (_shows(kDutyPass))
          FormPaperPage(
            formLabel: 'Page 15',
            children: [
              BilingualSectionHeader(
                label: 'DUTY PASS (FOR POLICE CONSTABLE ACCOMPANYING BODY)',
                marathiLabel: 'ड्युटी पास (शवासोबत जाणाऱ्या अंमलदारासाठी)',
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              const SizedBox(height: 12),
              BilingualFieldRow(fields: [
                BilingualField(label: 'Police Station :-', marathiLabel: 'पोलीस ठाणे', controller: _dpPsCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'Camp :-', marathiLabel: 'मुक्काम', controller: _dpCampCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'Date :-', marathiLabel: 'दिनांक', controller: _dpDateCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              ]),
              BilingualField(label: 'Amaldaar / Officer Name :-', marathiLabel: 'अंमलदाराचे नांव', controller: _dpAmaldaarNameCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              BilingualFieldRow(fields: [
                BilingualField(label: 'Duty Police Station :-', marathiLabel: 'पोलीस ठाणे', controller: _dpDutyPsCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'Dist. :-', marathiLabel: 'जिल्हा', controller: _dpDutyDistCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'Date & Time :-', marathiLabel: 'दिनांक व वेळ', controller: _dpDutyDateTimeCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              ]),
              BilingualFieldRow(fields: [
                BilingualField(label: 'Marg No. :-', marathiLabel: 'मर्ग क्र.', controller: _dpMargNoCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'Year :- 20', marathiLabel: 'वर्ष', controller: _dpMargYearCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'Section :-', marathiLabel: 'कलम', controller: _dpKalamCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              ]),
              BilingualField(label: 'Deceased Name :-', marathiLabel: 'मृताचे नांव', controller: _dpDeceasedNameCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              BilingualFieldRow(fields: [
                BilingualField(label: 'R/o :-', marathiLabel: 'रा.', controller: _dpDeceasedRaCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'Ta. :-', marathiLabel: 'ता.', controller: _dpDeceasedTaCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'Dist. :-', marathiLabel: 'जिल्हा', controller: _dpDeceasedDistCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              ]),
              BilingualField(label: 'Medical Officer / Hospital :-', marathiLabel: 'वैद्यकीय अधिकारी / दवाखाना', controller: _dpMedOfficerNameCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              const SizedBox(height: 16),
              BilingualField(label: 'Amaldaar Signature :-', marathiLabel: 'अंमलदाराची सही', controller: _dpAmaldaarSigCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              const SizedBox(height: 24),
              BilingualFieldRow(fields: [
                BilingualField(label: 'IO Name :-', marathiLabel: 'तपासणी अधिकारी', controller: _dpIoNameCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'Rank :-', marathiLabel: 'पद', controller: _dpIoRankCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
                BilingualField(label: 'P.S. :-', marathiLabel: 'पो.स्टे.', controller: _dpIoPsCtrl, serifStyle: serifStyle, marathiLabelStyle: marathiLabelStyle),
              ]),
            ],
          ),
      ],
    );
  }
}
