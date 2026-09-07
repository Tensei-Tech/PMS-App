import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bilingual_field.dart';
import 'form_paper_page.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';
import 'form_section_utils.dart';
import 'form_io_signature_block.dart';
import '../utils/form_io_terminology.dart';

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
  State<InquestPanchanamaFormView> createState() =>
      InquestPanchanamaFormViewState();
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

  // Part 1: Inquest Panchanama Controllers (Pages 1-4)
  final _distCtrl = TextEditingController();
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
  final _genderCtrl = TextEditingController();
  final _marriedCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _deathDateCtrl = TextEditingController();
  final _deathTimeCtrl = TextEditingController();
  final _positionOfBodyCtrl = TextEditingController();
  final _nameAddressDeceasedCtrl = TextEditingController();

  // Injuries
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

  final _injAccidentalViolenceCtrl = TextEditingController();
  final _weaponMeansCtrl = TextEditingController();
  final _bodyCoolWarmCtrl = TextEditingController();
  final _poisoningPositionCtrl = TextEditingController();

  // Fingerprint / Photo
  final _fingerprintReasonCtrl = TextEditingController();
  final _photoReasonCtrl = TextEditingController();

  // PM
  final _sentToPMReasonCtrl = TextEditingController();
  final _hospitalNameCtrl = TextEditingController();
  final _sentOfficerNameCtrl = TextEditingController();
  final _sentOfficerBNoCtrl = TextEditingController();
  final _sentOfficerPsCtrl = TextEditingController();

  final _opinionPanchasCtrl = TextEditingController();
  final _moreInfoCtrl = TextEditingController();

  // Date and Time of Panchanama
  final _panchanamaDateCtrl = TextEditingController();
  final _panchanamaTimeCtrl = TextEditingController();
  final _panchanamaTimeToCtrl = TextEditingController();

  // Panchas
  final _panch1Ctrl = TextEditingController();
  final _panch1SigCtrl = TextEditingController();
  final _panch2Ctrl = TextEditingController();
  final _panch2SigCtrl = TextEditingController();
  final _panch3Ctrl = TextEditingController();
  final _panch3SigCtrl = TextEditingController();

  // Investigation Officer
  final _ioNameCtrl = TextEditingController();
  final _ioRankCtrl = TextEditingController();
  final _ioNoCtrl = TextEditingController();
  final _ioPostingCtrl = TextEditingController();

  // Part 2: Police Report to Civil Surgeon (Page 5)
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

  // Page 6 (Continuation of Civil Surgeon Report)
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

  // Page 7: Vinanti Arj (Request Application)
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

  // Page 8: Relatives Summon
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

  // Page 9: Panchas Summon
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

  // Page 10: Simplified Marathi Inquest
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

  // Page 11: Maranaveshan Panchanama continuation (Sections 13-18)
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

  // Page 12: 14-Kalami Form to Medical Officer (Q1-Q10)
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

  // Page 13: 14-Kalami Form continuation (Q11-Q14)
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

  // Page 14: Pret Taba Pavati (Body Custody Receipt)
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

  // Page 15: Duty Pass
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
    _distCtrl.text = doc['dist'] ?? '';
    _psCtrl.text = doc['ps'] ?? '';
    _yearCtrl.text = doc['year'] ?? '';
    _firNoCtrl.text = doc['firNo'] ?? '';
    _actSectionsCtrl.text = doc['actSections'] ?? '';
    _deadBodyFoundPlaceCtrl.text = doc['deadBodyFoundPlace'] ?? '';
    _foundPlaceCtrl.text = doc['foundPlace'] ?? '';
    _foundDateCtrl.text = doc['foundDate'] ?? '';
    _foundTimeCtrl.text = doc['foundTime'] ?? '';
    _shownByCtrl.text = doc['shownBy'] ?? '';
    _identifiedByCtrl.text = doc['identifiedBy'] ?? '';
    _genderCtrl.text = doc['gender'] ?? '';
    _marriedCtrl.text = doc['married'] ?? '';
    _ageCtrl.text = doc['age'] ?? '';
    _deathDateCtrl.text = doc['deathDate'] ?? '';
    _deathTimeCtrl.text = doc['deathTime'] ?? '';
    _positionOfBodyCtrl.text = doc['positionOfBody'] ?? '';
    _nameAddressDeceasedCtrl.text = doc['nameAddressDeceased'] ?? '';

    _injHeadCtrl.text = doc['injHead'] ?? '';
    _injFaceCtrl.text = doc['injFace'] ?? '';
    _injNeckCtrl.text = doc['injNeck'] ?? '';
    _injChestCtrl.text = doc['injChest'] ?? '';
    _injStomachCtrl.text = doc['injStomach'] ?? '';
    _injRightHandCtrl.text = doc['injRightHand'] ?? '';
    _injLeftHandCtrl.text = doc['injLeftHand'] ?? '';
    _injRightLegCtrl.text = doc['injRightLeg'] ?? '';
    _injLeftLegCtrl.text = doc['injLeftLeg'] ?? '';
    _injPrivatePartCtrl.text = doc['injPrivatePart'] ?? '';
    _injBackCtrl.text = doc['injBack'] ?? '';

    _injAccidentalViolenceCtrl.text = doc['injAccidentalViolence'] ?? '';
    _weaponMeansCtrl.text = doc['weaponMeans'] ?? '';
    _bodyCoolWarmCtrl.text = doc['bodyCoolWarm'] ?? '';
    _poisoningPositionCtrl.text = doc['poisoningPosition'] ?? '';

    _fingerprintReasonCtrl.text = doc['fingerprintReason'] ?? '';
    _photoReasonCtrl.text = doc['photoReason'] ?? '';

    _sentToPMReasonCtrl.text = doc['sentToPMReason'] ?? '';
    _hospitalNameCtrl.text = doc['hospitalName'] ?? '';
    _sentOfficerNameCtrl.text = doc['sentOfficerName'] ?? '';
    _sentOfficerBNoCtrl.text = doc['sentOfficerBNo'] ?? '';
    _sentOfficerPsCtrl.text = doc['sentOfficerPs'] ?? '';

    _opinionPanchasCtrl.text = doc['opinionPanchas'] ?? '';
    _moreInfoCtrl.text = doc['moreInfo'] ?? '';

    _panchanamaDateCtrl.text = doc['panchanamaDate'] ?? '';
    _panchanamaTimeCtrl.text = doc['panchanamaTime'] ?? '';
    _panchanamaTimeToCtrl.text = doc['panchanamaTimeTo'] ?? '';

    _panch1Ctrl.text = doc['panch1'] ?? '';
    _panch1SigCtrl.text = doc['panch1Sig'] ?? '';
    _panch2Ctrl.text = doc['panch2'] ?? '';
    _panch2SigCtrl.text = doc['panch2Sig'] ?? '';
    _panch3Ctrl.text = doc['panch3'] ?? '';
    _panch3SigCtrl.text = doc['panch3Sig'] ?? '';

    _ioNameCtrl.text = doc['ioName'] ?? '';
    _ioRankCtrl.text = doc['ioRank'] ?? '';
    _ioNoCtrl.text = doc['ioNo'] ?? '';
    _ioPostingCtrl.text = doc['ioPosting'] ?? '';

    // CS
    _csNameDeceasedCtrl.text = doc['csNameDeceased'] ?? '';
    _csAgeCtrl.text = doc['csAge'] ?? '';
    _csMaritalStatusCtrl.text = doc['csMaritalStatus'] ?? '';
    _csDeathDateCtrl.text = doc['csDeathDate'] ?? '';
    _csDeathTimeCtrl.text = doc['csDeathTime'] ?? '';
    _csBodyConditionCtrl.text = doc['csBodyCondition'] ?? '';
    _csSeenDateCtrl.text = doc['csSeenDate'] ?? '';
    _csSeenTimeCtrl.text = doc['csSeenTime'] ?? '';
    _csSeenOfficerCtrl.text = doc['csSeenOfficer'] ?? '';
    _csBodyColdWarmCtrl.text = doc['csBodyColdWarm'] ?? '';
    _csRecentIllnessCtrl.text = doc['csRecentIllness'] ?? '';
    _csAccidentInjuryCtrl.text = doc['csAccidentInjury'] ?? '';
    _csArticlesForwardedCtrl.text = doc['csArticlesForwarded'] ?? '';
    _csDeathReasonCtrl.text = doc['csDeathReason'] ?? '';

    // CS Page 6
    _csPoisonSuspicionCtrl.text = doc['csPoisonSuspicion'] ?? '';
    _csWomanPregnancyCtrl.text = doc['csWomanPregnancy'] ?? '';
    _csAbortionCtrl.text = doc['csAbortion'] ?? '';
    _csJuryFindingsCtrl.text = doc['csJuryFindings'] ?? '';
    _csRemarksCtrl.text = doc['csRemarks'] ?? '';
    _csExtraNotesCtrl.text = doc['csExtraNotes'] ?? '';
    _csIoNameCtrl.text = doc['csIoName'] ?? '';
    _csIoRankCtrl.text = doc['csIoRank'] ?? '';
    _csIoNoCtrl.text = doc['csIoNo'] ?? '';
    _csIoPostingCtrl.text = doc['csIoPosting'] ?? '';

    // Page 7
    _reqPsCtrl.text = doc['reqPs'] ?? '';
    _reqDateCtrl.text = doc['reqDate'] ?? '';
    _reqToCtrl.text = doc['reqTo'] ?? '';
    _reqTo2Ctrl.text = doc['reqTo2'] ?? '';
    _reqFromPsCtrl.text = doc['reqFromPs'] ?? '';
    _reqDistCtrl.text = doc['reqDist'] ?? '';
    _reqSubjectNameCtrl.text = doc['reqSubjectName'] ?? '';
    _reqSubjectPsCtrl.text = doc['reqSubjectPs'] ?? '';
    _reqSubjectTaCtrl.text = doc['reqSubjectTa'] ?? '';
    _reqMargDateCtrl.text = doc['reqMargDate'] ?? '';
    _reqMargTimeCtrl.text = doc['reqMargTime'] ?? '';
    _reqMargPsCtrl.text = doc['reqMargPs'] ?? '';
    _reqMargDiaryNoCtrl.text = doc['reqMargDiaryNo'] ?? '';
    _reqMargYearCtrl.text = doc['reqMargYear'] ?? '';
    _reqMargNameCtrl.text = doc['reqMargName'] ?? '';
    _reqMargTaCtrl.text = doc['reqMargTa'] ?? '';
    _reqDeceasedHeSheCtrl.text = doc['reqDeceasedHeShe'] ?? '';
    _reqHospitalNameCtrl.text = doc['reqHospitalName'] ?? '';
    _reqAdmitDateCtrl.text = doc['reqAdmitDate'] ?? '';
    _reqAdmitTimeCtrl.text = doc['reqAdmitTime'] ?? '';
    _reqReasonDetailsCtrl.text = doc['reqReasonDetails'] ?? '';
    _reqDeathDateCtrl.text = doc['reqDeathDate'] ?? '';
    _reqDeathTimeCtrl.text = doc['reqDeathTime'] ?? '';
    _reqHasteNameCtrl.text = doc['reqHasteName'] ?? '';
    _reqHastePsCtrl.text = doc['reqHastePs'] ?? '';
    _reqIoNameCtrl.text = doc['reqIoName'] ?? '';
    _reqIoRankCtrl.text = doc['reqIoRank'] ?? '';
    _reqIoNoCtrl.text = doc['reqIoNo'] ?? '';
    _reqIoPostingCtrl.text = doc['reqIoPosting'] ?? '';

    // Page 8
    _relPsCtrl.text = doc['relPs'] ?? '';
    _relCampCtrl.text = doc['relCamp'] ?? '';
    _relDateCtrl.text = doc['relDate'] ?? '';
    _relToNameCtrl.text = doc['relToName'] ?? '';
    _relWeNameCtrl.text = doc['relWeName'] ?? '';
    _relPsNameCtrl.text = doc['relPsName'] ?? '';
    _relCrDiaryNoCtrl.text = doc['relCrDiaryNo'] ?? '';
    _relCrYearCtrl.text = doc['relCrYear'] ?? '';
    _relActSecCtrl.text = doc['relActSec'] ?? '';
    _relDeceasedNameCtrl.text = doc['relDeceasedName'] ?? '';
    _relTaCtrl.text = doc['relTa'] ?? '';
    _relDistCtrl.text = doc['relDist'] ?? '';
    _relSig1Ctrl.text = doc['relSig1'] ?? '';
    _relSig2Ctrl.text = doc['relSig2'] ?? '';
    _relSig3Ctrl.text = doc['relSig3'] ?? '';
    _relSig4Ctrl.text = doc['relSig4'] ?? '';
    _relIoNameCtrl.text = doc['relIoName'] ?? '';
    _relIoRankCtrl.text = doc['relIoRank'] ?? '';
    _relIoNoCtrl.text = doc['relIoNo'] ?? '';
    _relIoPostingCtrl.text = doc['relIoPosting'] ?? '';

    // Page 9
    _panPsCtrl.text = doc['panPs'] ?? '';
    _panCampCtrl.text = doc['panCamp'] ?? '';
    _panDateCtrl.text = doc['panDate'] ?? '';
    _panToNameCtrl.text = doc['panToName'] ?? '';
    _panWeNameCtrl.text = doc['panWeName'] ?? '';
    _panPsNameCtrl.text = doc['panPsName'] ?? '';
    _panCrDiaryNoCtrl.text = doc['panCrDiaryNo'] ?? '';
    _panCrYearCtrl.text = doc['panCrYear'] ?? '';
    _panActSecCtrl.text = doc['panActSec'] ?? '';
    _panDeceasedNameCtrl.text = doc['panDeceasedName'] ?? '';
    _panTaCtrl.text = doc['panTa'] ?? '';
    _panDistCtrl.text = doc['panDist'] ?? '';
    _panSig1Ctrl.text = doc['panSig1'] ?? '';
    _panSig2Ctrl.text = doc['panSig2'] ?? '';
    _panSig3Ctrl.text = doc['panSig3'] ?? '';
    _panSig4Ctrl.text = doc['panSig4'] ?? '';
    _panIoNameCtrl.text = doc['panIoName'] ?? '';
    _panIoRankCtrl.text = doc['panIoRank'] ?? '';
    _panIoNoCtrl.text = doc['panIoNo'] ?? '';
    _panIoPostingCtrl.text = doc['panIoPosting'] ?? '';

    // Page 10
    _marThikanCtrl.text = doc['marThikan'] ?? '';
    _marDateCtrl.text = doc['marDate'] ?? '';
    _marTimeCtrl.text = doc['marTime'] ?? '';
    _marPanchNameAddressCtrl.text = doc['marPanchNameAddress'] ?? '';
    _marPsCtrl.text = doc['marPs'] ?? '';
    _marDistCtrl.text = doc['marDist'] ?? '';
    _marDiaryNoCtrl.text = doc['marDiaryNo'] ?? '';
    _marActSecCtrl.text = doc['marActSec'] ?? '';
    _marIoDetailsCtrl.text = doc['marIoDetails'] ?? '';
    _marComplainantNameCtrl.text = doc['marComplainantName'] ?? '';
    _marDeceasedNameAddressCtrl.text = doc['marDeceasedNameAddress'] ?? '';
    _marShownByNameCtrl.text = doc['marShownByName'] ?? '';
    _marThikanDescriptionCtrl.text = doc['marThikanDescription'] ?? '';
    _marBodyConditionCtrl.text = doc['marBodyCondition'] ?? '';
    _marBodyClothesCtrl.text = doc['marBodyClothes'] ?? '';
    _marBodyOrnamentsCtrl.text = doc['marBodyOrnaments'] ?? '';

    // Page 11
    _mar13InjuriesCtrl.text = doc['mar13Injuries'] ?? '';
    _mar14OtherMarksCtrl.text = doc['mar14OtherMarks'] ?? '';
    _mar15OrnamentsDisposalCtrl.text = doc['mar15OrnamentsDisposal'] ?? '';
    _mar16OpinionCtrl.text = doc['mar16Opinion'] ?? '';
    _mar17BodyDisposalCtrl.text = doc['mar17BodyDisposal'] ?? '';
    _mar18DateTimeCtrl.text = doc['mar18DateTime'] ?? '';
    _mar11Panch1Ctrl.text = doc['mar11Panch1'] ?? '';
    _mar11Panch2Ctrl.text = doc['mar11Panch2'] ?? '';
    _mar11Panch3Ctrl.text = doc['mar11Panch3'] ?? '';
    _mar11Panch4Ctrl.text = doc['mar11Panch4'] ?? '';
    _mar11IoNameCtrl.text = doc['mar11IoName'] ?? '';
    _mar11IoRankCtrl.text = doc['mar11IoRank'] ?? '';
    _mar11IoPsCtrl.text = doc['mar11IoPs'] ?? '';
    _mar11CopyToCtrl.text = doc['mar11CopyTo'] ?? '';

    // Page 12
    _kal14NameAgeCtrl.text = doc['kal14NameAge'] ?? '';
    _kal14AddressCtrl.text = doc['kal14Address'] ?? '';
    _kal14ShavFromCtrl.text = doc['kal14ShavFrom'] ?? '';
    _kal14ShavToCtrl.text = doc['kal14ShavTo'] ?? '';
    _kal14AaiNameCtrl.text = doc['kal14AaiName'] ?? '';
    _kal14BaapNameCtrl.text = doc['kal14BaapName'] ?? '';
    _kal14DharmCtrl.text = doc['kal14Dharm'] ?? '';
    _kal14VyavsayCtrl.text = doc['kal14Vyavsay'] ?? '';
    _kal14Cigarette = doc['kal14Cigarette'] == true;
    _kal14CigaretteDaysCtrl.text = doc['kal14CigaretteDays'] ?? '';
    _kal14Daru = doc['kal14Daru'] == true;
    _kal14DaruDaysCtrl.text = doc['kal14DaruDays'] ?? '';
    _kal14Tambakhu = doc['kal14Tambakhu'] == true;
    _kal14TambakhuDaysCtrl.text = doc['kal14TambakhuDays'] ?? '';
    _kal14PanMasala = doc['kal14PanMasala'] == true;
    _kal14PanMasalaDaysCtrl.text = doc['kal14PanMasalaDays'] ?? '';

    // Page 13
    _kal14VehicleNameCtrl.text = doc['kal14VehicleName'] ?? '';
    _kal14DriverPassCtrl.text = doc['kal14DriverPass'] ?? '';
    _kal14PedestrianCtrl.text = doc['kal14Pedestrian'] ?? '';
    _kal14AccidentHowCtrl.text = doc['kal14AccidentHow'] ?? '';
    _kal14AccidentDateTimeCtrl.text = doc['kal14AccidentDateTime'] ?? '';
    _kal14FallInfoCtrl.text = doc['kal14FallInfo'] ?? '';
    _kal14PregnantMonthsCtrl.text = doc['kal14PregnantMonths'] ?? '';
    _kal14DeliveredAbortionCtrl.text = doc['kal14DeliveredAbortion'] ?? '';
    _kal14PregnantDaysCtrl.text = doc['kal14PregnantDays'] ?? '';
    _kal14IdentifierNameCtrl.text = doc['kal14IdentifierName'] ?? '';
    _kal14IoNameCtrl.text = doc['kal14IoName'] ?? '';
    _kal14IoRankCtrl.text = doc['kal14IoRank'] ?? '';
    _kal14IoPsCtrl.text = doc['kal14IoPs'] ?? '';

    // Page 14
    _ptpPsCtrl.text = doc['ptpPs'] ?? '';
    _ptpCampCtrl.text = doc['ptpCamp'] ?? '';
    _ptpDateCtrl.text = doc['ptpDate'] ?? '';
    _ptpReceiverNameCtrl.text = doc['ptpReceiverName'] ?? '';
    _ptpReceiverRaCtrl.text = doc['ptpReceiverRa'] ?? '';
    _ptpReceiverTaCtrl.text = doc['ptpReceiverTa'] ?? '';
    _ptpReceiverDistCtrl.text = doc['ptpReceiverDist'] ?? '';
    _ptpMoNoCtrl.text = doc['ptpMoNo'] ?? '';
    _ptpReceiptDateCtrl.text = doc['ptpReceiptDate'] ?? '';
    _ptpDeceasedNameCtrl.text = doc['ptpDeceasedName'] ?? '';
    _ptpDeceasedRaCtrl.text = doc['ptpDeceasedRa'] ?? '';
    _ptpDeceasedDistCtrl.text = doc['ptpDeceasedDist'] ?? '';
    _ptpReceiverSigCtrl.text = doc['ptpReceiverSig'] ?? '';
    _ptpIoNameCtrl.text = doc['ptpIoName'] ?? '';
    _ptpIoRankCtrl.text = doc['ptpIoRank'] ?? '';
    _ptpIoPsCtrl.text = doc['ptpIoPs'] ?? '';

    // Page 15
    _dpPsCtrl.text = doc['dpPs'] ?? '';
    _dpCampCtrl.text = doc['dpCamp'] ?? '';
    _dpDateCtrl.text = doc['dpDate'] ?? '';
    _dpAmaldaarNameCtrl.text = doc['dpAmaldaarName'] ?? '';
    _dpDutyPsCtrl.text = doc['dpDutyPs'] ?? '';
    _dpDutyDistCtrl.text = doc['dpDutyDist'] ?? '';
    _dpDutyDateTimeCtrl.text = doc['dpDutyDateTime'] ?? '';
    _dpMargNoCtrl.text = doc['dpMargNo'] ?? '';
    _dpMargYearCtrl.text = doc['dpMargYear'] ?? '';
    _dpKalamCtrl.text = doc['dpKalam'] ?? '';
    _dpDeceasedNameCtrl.text = doc['dpDeceasedName'] ?? '';
    _dpDeceasedRaCtrl.text = doc['dpDeceasedRa'] ?? '';
    _dpDeceasedTaCtrl.text = doc['dpDeceasedTa'] ?? '';
    _dpDeceasedDistCtrl.text = doc['dpDeceasedDist'] ?? '';
    _dpMedOfficerNameCtrl.text = doc['dpMedOfficerName'] ?? '';
    _dpAmaldaarSigCtrl.text = doc['dpAmaldaarSig'] ?? '';
    _dpIoNameCtrl.text = doc['dpIoName'] ?? '';
    _dpIoRankCtrl.text = doc['dpIoRank'] ?? '';
    _dpIoPsCtrl.text = doc['dpIoPs'] ?? '';
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
      'gender': _genderCtrl.text.trim(),
      'married': _marriedCtrl.text.trim(),
      'age': _ageCtrl.text.trim(),
      'deathDate': _deathDateCtrl.text.trim(),
      'deathTime': _deathTimeCtrl.text.trim(),
      'positionOfBody': _positionOfBodyCtrl.text.trim(),
      'nameAddressDeceased': _nameAddressDeceasedCtrl.text.trim(),

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

      // CS Page 6
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

  @override
  void dispose() {
    _distCtrl.dispose();
    _psCtrl.dispose();
    _yearCtrl.dispose();
    _firNoCtrl.dispose();
    _actSectionsCtrl.dispose();
    _deadBodyFoundPlaceCtrl.dispose();
    _foundPlaceCtrl.dispose();
    _foundDateCtrl.dispose();
    _foundTimeCtrl.dispose();
    _shownByCtrl.dispose();
    _identifiedByCtrl.dispose();
    _genderCtrl.dispose();
    _marriedCtrl.dispose();
    _ageCtrl.dispose();
    _deathDateCtrl.dispose();
    _deathTimeCtrl.dispose();
    _positionOfBodyCtrl.dispose();
    _nameAddressDeceasedCtrl.dispose();

    _injHeadCtrl.dispose();
    _injFaceCtrl.dispose();
    _injNeckCtrl.dispose();
    _injChestCtrl.dispose();
    _injStomachCtrl.dispose();
    _injRightHandCtrl.dispose();
    _injLeftHandCtrl.dispose();
    _injRightLegCtrl.dispose();
    _injLeftLegCtrl.dispose();
    _injPrivatePartCtrl.dispose();
    _injBackCtrl.dispose();

    _injAccidentalViolenceCtrl.dispose();
    _weaponMeansCtrl.dispose();
    _bodyCoolWarmCtrl.dispose();
    _poisoningPositionCtrl.dispose();

    _fingerprintReasonCtrl.dispose();
    _photoReasonCtrl.dispose();

    _sentToPMReasonCtrl.dispose();
    _hospitalNameCtrl.dispose();
    _sentOfficerNameCtrl.dispose();
    _sentOfficerBNoCtrl.dispose();
    _sentOfficerPsCtrl.dispose();

    _opinionPanchasCtrl.dispose();
    _moreInfoCtrl.dispose();

    _panchanamaDateCtrl.dispose();
    _panchanamaTimeCtrl.dispose();
    _panchanamaTimeToCtrl.dispose();

    _panch1Ctrl.dispose();
    _panch1SigCtrl.dispose();
    _panch2Ctrl.dispose();
    _panch2SigCtrl.dispose();
    _panch3Ctrl.dispose();
    _panch3SigCtrl.dispose();

    _ioNameCtrl.dispose();
    _ioRankCtrl.dispose();
    _ioNoCtrl.dispose();
    _ioPostingCtrl.dispose();

    _csNameDeceasedCtrl.dispose();
    _csAgeCtrl.dispose();
    _csMaritalStatusCtrl.dispose();
    _csDeathDateCtrl.dispose();
    _csDeathTimeCtrl.dispose();
    _csBodyConditionCtrl.dispose();
    _csSeenDateCtrl.dispose();
    _csSeenTimeCtrl.dispose();
    _csSeenOfficerCtrl.dispose();
    _csBodyColdWarmCtrl.dispose();
    _csRecentIllnessCtrl.dispose();
    _csAccidentInjuryCtrl.dispose();
    _csArticlesForwardedCtrl.dispose();
    _csDeathReasonCtrl.dispose();

    // CS Page 6
    _csPoisonSuspicionCtrl.dispose();
    _csWomanPregnancyCtrl.dispose();
    _csAbortionCtrl.dispose();
    _csJuryFindingsCtrl.dispose();
    _csRemarksCtrl.dispose();
    _csExtraNotesCtrl.dispose();
    _csIoNameCtrl.dispose();
    _csIoRankCtrl.dispose();
    _csIoNoCtrl.dispose();
    _csIoPostingCtrl.dispose();

    // Page 7
    _reqPsCtrl.dispose();
    _reqDateCtrl.dispose();
    _reqToCtrl.dispose();
    _reqTo2Ctrl.dispose();
    _reqFromPsCtrl.dispose();
    _reqDistCtrl.dispose();
    _reqSubjectNameCtrl.dispose();
    _reqSubjectPsCtrl.dispose();
    _reqSubjectTaCtrl.dispose();
    _reqMargDateCtrl.dispose();
    _reqMargTimeCtrl.dispose();
    _reqMargPsCtrl.dispose();
    _reqMargDiaryNoCtrl.dispose();
    _reqMargYearCtrl.dispose();
    _reqMargNameCtrl.dispose();
    _reqMargTaCtrl.dispose();
    _reqDeceasedHeSheCtrl.dispose();
    _reqHospitalNameCtrl.dispose();
    _reqAdmitDateCtrl.dispose();
    _reqAdmitTimeCtrl.dispose();
    _reqReasonDetailsCtrl.dispose();
    _reqDeathDateCtrl.dispose();
    _reqDeathTimeCtrl.dispose();
    _reqHasteNameCtrl.dispose();
    _reqHastePsCtrl.dispose();
    _reqIoNameCtrl.dispose();
    _reqIoRankCtrl.dispose();
    _reqIoNoCtrl.dispose();
    _reqIoPostingCtrl.dispose();

    // Page 8
    _relPsCtrl.dispose();
    _relCampCtrl.dispose();
    _relDateCtrl.dispose();
    _relToNameCtrl.dispose();
    _relWeNameCtrl.dispose();
    _relPsNameCtrl.dispose();
    _relCrDiaryNoCtrl.dispose();
    _relCrYearCtrl.dispose();
    _relActSecCtrl.dispose();
    _relDeceasedNameCtrl.dispose();
    _relTaCtrl.dispose();
    _relDistCtrl.dispose();
    _relSig1Ctrl.dispose();
    _relSig2Ctrl.dispose();
    _relSig3Ctrl.dispose();
    _relSig4Ctrl.dispose();
    _relIoNameCtrl.dispose();
    _relIoRankCtrl.dispose();
    _relIoNoCtrl.dispose();
    _relIoPostingCtrl.dispose();

    // Page 9
    _panPsCtrl.dispose();
    _panCampCtrl.dispose();
    _panDateCtrl.dispose();
    _panToNameCtrl.dispose();
    _panWeNameCtrl.dispose();
    _panPsNameCtrl.dispose();
    _panCrDiaryNoCtrl.dispose();
    _panCrYearCtrl.dispose();
    _panActSecCtrl.dispose();
    _panDeceasedNameCtrl.dispose();
    _panTaCtrl.dispose();
    _panDistCtrl.dispose();
    _panSig1Ctrl.dispose();
    _panSig2Ctrl.dispose();
    _panSig3Ctrl.dispose();
    _panSig4Ctrl.dispose();
    _panIoNameCtrl.dispose();
    _panIoRankCtrl.dispose();
    _panIoNoCtrl.dispose();
    _panIoPostingCtrl.dispose();

    // Page 10
    _marThikanCtrl.dispose();
    _marDateCtrl.dispose();
    _marTimeCtrl.dispose();
    _marPanchNameAddressCtrl.dispose();
    _marPsCtrl.dispose();
    _marDistCtrl.dispose();
    _marDiaryNoCtrl.dispose();
    _marActSecCtrl.dispose();
    _marIoDetailsCtrl.dispose();
    _marComplainantNameCtrl.dispose();
    _marDeceasedNameAddressCtrl.dispose();
    _marShownByNameCtrl.dispose();
    _marThikanDescriptionCtrl.dispose();
    _marBodyConditionCtrl.dispose();
    _marBodyClothesCtrl.dispose();
    _marBodyOrnamentsCtrl.dispose();

    // Page 11
    _mar13InjuriesCtrl.dispose();
    _mar14OtherMarksCtrl.dispose();
    _mar15OrnamentsDisposalCtrl.dispose();
    _mar16OpinionCtrl.dispose();
    _mar17BodyDisposalCtrl.dispose();
    _mar18DateTimeCtrl.dispose();
    _mar11Panch1Ctrl.dispose();
    _mar11Panch2Ctrl.dispose();
    _mar11Panch3Ctrl.dispose();
    _mar11Panch4Ctrl.dispose();
    _mar11IoNameCtrl.dispose();
    _mar11IoRankCtrl.dispose();
    _mar11IoPsCtrl.dispose();
    _mar11CopyToCtrl.dispose();

    // Page 12
    _kal14NameAgeCtrl.dispose();
    _kal14AddressCtrl.dispose();
    _kal14ShavFromCtrl.dispose();
    _kal14ShavToCtrl.dispose();
    _kal14AaiNameCtrl.dispose();
    _kal14BaapNameCtrl.dispose();
    _kal14DharmCtrl.dispose();
    _kal14VyavsayCtrl.dispose();
    _kal14CigaretteDaysCtrl.dispose();
    _kal14DaruDaysCtrl.dispose();
    _kal14TambakhuDaysCtrl.dispose();
    _kal14PanMasalaDaysCtrl.dispose();

    // Page 13
    _kal14VehicleNameCtrl.dispose();
    _kal14DriverPassCtrl.dispose();
    _kal14PedestrianCtrl.dispose();
    _kal14AccidentHowCtrl.dispose();
    _kal14AccidentDateTimeCtrl.dispose();
    _kal14FallInfoCtrl.dispose();
    _kal14PregnantMonthsCtrl.dispose();
    _kal14DeliveredAbortionCtrl.dispose();
    _kal14PregnantDaysCtrl.dispose();
    _kal14IdentifierNameCtrl.dispose();
    _kal14IoNameCtrl.dispose();
    _kal14IoRankCtrl.dispose();
    _kal14IoPsCtrl.dispose();

    // Page 14
    _ptpPsCtrl.dispose();
    _ptpCampCtrl.dispose();
    _ptpDateCtrl.dispose();
    _ptpReceiverNameCtrl.dispose();
    _ptpReceiverRaCtrl.dispose();
    _ptpReceiverTaCtrl.dispose();
    _ptpReceiverDistCtrl.dispose();
    _ptpMoNoCtrl.dispose();
    _ptpReceiptDateCtrl.dispose();
    _ptpDeceasedNameCtrl.dispose();
    _ptpDeceasedRaCtrl.dispose();
    _ptpDeceasedDistCtrl.dispose();
    _ptpReceiverSigCtrl.dispose();
    _ptpIoNameCtrl.dispose();
    _ptpIoRankCtrl.dispose();
    _ptpIoPsCtrl.dispose();

    // Page 15
    _dpPsCtrl.dispose();
    _dpCampCtrl.dispose();
    _dpDateCtrl.dispose();
    _dpAmaldaarNameCtrl.dispose();
    _dpDutyPsCtrl.dispose();
    _dpDutyDistCtrl.dispose();
    _dpDutyDateTimeCtrl.dispose();
    _dpMargNoCtrl.dispose();
    _dpMargYearCtrl.dispose();
    _dpKalamCtrl.dispose();
    _dpDeceasedNameCtrl.dispose();
    _dpDeceasedRaCtrl.dispose();
    _dpDeceasedTaCtrl.dispose();
    _dpDeceasedDistCtrl.dispose();
    _dpMedOfficerNameCtrl.dispose();
    _dpAmaldaarSigCtrl.dispose();
    _dpIoNameCtrl.dispose();
    _dpIoRankCtrl.dispose();
    _dpIoPsCtrl.dispose();

    super.dispose();
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
            Text('   जिल्हा ', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
            _inlineBlank(controller: _reqDistCtrl, style: style, width: 120, hintText: 'जिल्हा'),
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
              Text('   मयत (तो / ती) ', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
              _inlineBlank(controller: _reqDeceasedHeSheCtrl, style: style, width: 80, hintText: 'तो/ती'),
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


  @override
  Widget build(BuildContext context) {
    final TextStyle serifStyle = FormTypography.serifStyle();
    final TextStyle marathiLabelStyle = FormTypography.marathiLabelStyle();

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        if (_shows(kMainInquest))
          FormPaperPage(
            formLabel: widget.pageRange ?? 'Pages 12–15',
            children: [
              // HEADER
              Center(
                child: Column(
                  children: [
                    Text(
                      'INQUEST PANCHANAMA',
                      style: serifStyle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'मरणोत्तर पंचनामा',
                      style: GoogleFonts.notoSansDevanagari(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '(Under Section - 194 B.N.S.S.)',
                      style: serifStyle.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '( भारतीय नागरीक सुरक्षा संहिता २०२३ कलम १९४ अन्वये. )',
                      style: marathiLabelStyle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 1) Dist, PS, Year, FIR No
              BilingualFieldRow(
                fields: [
                  BilingualField(
                    label: '1) Dist. :-',
                    marathiLabel: 'जिल्हा',
                    controller: _distCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                  BilingualField(
                    label: 'P.S. :-',
                    marathiLabel: 'पो.स्टे.',
                    controller: _psCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                  BilingualField(
                    label: 'Year :- 20',
                    marathiLabel: 'वर्ष',
                    controller: _yearCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                  BilingualField(
                    label: 'FIR/AD/U.D.No :-',
                    marathiLabel: 'पहिली खबर क्र / अकस्मात मृत्यू क्र.',
                    controller: _firNoCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2) Act and Section
              BilingualWideField(
                label: '2) Act and Section :-',
                marathiLabel: 'अधिनियम व कलमे',
                controller: _actSectionsCtrl,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              const SizedBox(height: 12),

              // 3) Place where body found
              BilingualSectionHeader(
                label: '3) Place From where Dead Body Found/Traced :-',
                marathiLabel: 'प्रेत पाहिल्याचे / मिळाल्याचे ठिकाण / जागा',
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              BilingualFieldRow(
                fields: [
                  BilingualField(
                    label: 'Place :-',
                    marathiLabel: 'जागा',
                    controller: _foundPlaceCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                  BilingualField(
                    label: 'Date :-',
                    marathiLabel: 'तारीख',
                    controller: _foundDateCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                  BilingualField(
                    label: 'Time :-',
                    marathiLabel: 'वेळ',
                    controller: _foundTimeCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4) By whom body shown
              BilingualWideField(
                label: '4) By whom Dead Body Shown :-',
                marathiLabel: 'प्रेत कोणी दाखविले',
                controller: _shownByCtrl,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              const SizedBox(height: 12),

              // 5) By whom identified
              BilingualWideField(
                label: '5) By whom Dead Body Identified :-',
                marathiLabel: 'प्रेत कोणी ओळखले',
                controller: _identifiedByCtrl,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              const SizedBox(height: 12),

              // a) Male/Female
              BilingualField(
                label: 'a) Dead Body Male/Female :-',
                marathiLabel: 'अ) प्रेत स्त्री / पुरुष जातीचे',
                controller: _genderCtrl,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              const SizedBox(height: 12),

              // 6) b) Married/Unmarried
              BilingualField(
                label: '6) b) Dead Body Married/Unmarried :-',
                marathiLabel: 'ब) प्रेत विवाहीत / अविवाहित आहे',
                controller: _marriedCtrl,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              const SizedBox(height: 12),

              // c) Age
              BilingualField(
                label: 'c) Age of Dead Body :-',
                marathiLabel: 'क) प्रेताचे वय',
                controller: _ageCtrl,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              const SizedBox(height: 12),

              // d) Date & Time of Death
              BilingualSectionHeader(
                label: 'd) Date and Time of Death :-',
                marathiLabel: 'ड) मृत्यूची तारीख व वेळ',
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              BilingualFieldRow(
                fields: [
                  BilingualField(
                    label: 'Date :-',
                    marathiLabel: 'तारीख',
                    controller: _deathDateCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                  BilingualField(
                    label: 'Time :-',
                    marathiLabel: 'वेळ',
                    controller: _deathTimeCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 7) Position of body
              BilingualMultilineField(
                label: '7) Position of Dead Body :-',
                marathiLabel: 'प्रेताची स्थिती / अवस्था (दशा)',
                controller: _positionOfBodyCtrl,
                minLines: 2,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              const SizedBox(height: 24),

              // PAGE BREAK EQUIVALENT
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Page 2',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const Divider(color: Colors.black45),
              const SizedBox(height: 12),

              // 8) Name & Address
              BilingualMultilineField(
                label: '8) Name and Address of Dead Body :-',
                marathiLabel: 'प्रेताचे संपूर्ण नांव व पत्ता (माहित असल्यास)',
                controller: _nameAddressDeceasedCtrl,
                minLines: 2,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              const SizedBox(height: 16),

              // 9) Description of injuries
              BilingualSectionHeader(
                label:
                    '9) Description of injuries found on dead body (if any) :-',
                marathiLabel: 'प्रेताचे जखमा असल्यास त्याचे वर्णन',
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Column(
                  children: [
                    BilingualField(
                      label: 'a) Head :-',
                      marathiLabel: 'अ) डोके',
                      controller: _injHeadCtrl,
                      serifStyle: serifStyle,
                      marathiLabelStyle: marathiLabelStyle,
                    ),
                    BilingualField(
                      label: 'b) Face :-',
                      marathiLabel: 'ब) चेहरा',
                      controller: _injFaceCtrl,
                      serifStyle: serifStyle,
                      marathiLabelStyle: marathiLabelStyle,
                    ),
                    BilingualField(
                      label: 'c) Neck :-',
                      marathiLabel: 'क) मान',
                      controller: _injNeckCtrl,
                      serifStyle: serifStyle,
                      marathiLabelStyle: marathiLabelStyle,
                    ),
                    BilingualField(
                      label: 'd) Chest :-',
                      marathiLabel: 'ड) छाती',
                      controller: _injChestCtrl,
                      serifStyle: serifStyle,
                      marathiLabelStyle: marathiLabelStyle,
                    ),
                    BilingualField(
                      label: 'e) Stomach :-',
                      marathiLabel: 'इ) पोट',
                      controller: _injStomachCtrl,
                      serifStyle: serifStyle,
                      marathiLabelStyle: marathiLabelStyle,
                    ),
                    BilingualField(
                      label: 'f) Right Hand :-',
                      marathiLabel: 'ई) उजवा हात',
                      controller: _injRightHandCtrl,
                      serifStyle: serifStyle,
                      marathiLabelStyle: marathiLabelStyle,
                    ),
                    BilingualField(
                      label: 'g) Left Hand :-',
                      marathiLabel: 'उ) डावा हात',
                      controller: _injLeftHandCtrl,
                      serifStyle: serifStyle,
                      marathiLabelStyle: marathiLabelStyle,
                    ),
                    BilingualField(
                      label: 'h) Right Leg :-',
                      marathiLabel: 'ऊ) उजवा पाय',
                      controller: _injRightLegCtrl,
                      serifStyle: serifStyle,
                      marathiLabelStyle: marathiLabelStyle,
                    ),
                    BilingualField(
                      label: 'i) Left Leg :-',
                      marathiLabel: 'ए) डावा पाय',
                      controller: _injLeftLegCtrl,
                      serifStyle: serifStyle,
                      marathiLabelStyle: marathiLabelStyle,
                    ),
                    BilingualField(
                      label: 'j) Private part :-',
                      marathiLabel: 'ऐ) गुप्त भाग',
                      controller: _injPrivatePartCtrl,
                      serifStyle: serifStyle,
                      marathiLabelStyle: marathiLabelStyle,
                    ),
                    BilingualField(
                      label: 'k) Back :-',
                      marathiLabel: 'ओ) पाठ',
                      controller: _injBackCtrl,
                      serifStyle: serifStyle,
                      marathiLabelStyle: marathiLabelStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // PAGE BREAK EQUIVALENT
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Page 3',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const Divider(color: Colors.black45),
              const SizedBox(height: 12),

              // 10) Injuries by Accidental/Violence
              BilingualMultilineField(
                label:
                    '10) Injuries caused by accidental/violence on dead body :-',
                marathiLabel:
                    'प्रेताचे अंगावरील जखमा अपघाताच्या / दंग्याशील / इतरानी केल्यामुळे झाल्या',
                controller: _injAccidentalViolenceCtrl,
                minLines: 2,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Homicide / Other Burn / (Fair / Tejab)',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 12),

              // 11) Weapon/Means
              BilingualField(
                label: '11) Weapon / Means (if any) :-',
                marathiLabel: 'जखमा केलेल्या हत्यार / साधन असल्यास',
                controller: _weaponMeansCtrl,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              const SizedBox(height: 12),

              // 12) Cool/Warm
              BilingualField(
                label: '12) Dead Body Cool / Warm :-',
                marathiLabel: 'प्रेत थंड आहे / गरम आहे',
                controller: _bodyCoolWarmCtrl,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              const SizedBox(height: 12),

              // 13) Poisoning
              BilingualField(
                label: '13) Position of dead body if poisoning suspected :-',
                marathiLabel: 'प्रेताची स्थिती विष प्राशन प्रयोग झाला असल्यास',
                controller: _poisoningPositionCtrl,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              const SizedBox(height: 12),

              // 14) Finger print & Photo
              BilingualField(
                label:
                    '14) (a) Finger print taken / not taken — reason (unidentified body) :-',
                marathiLabel:
                    'अनोळखी प्रेताचे डॉक्टरकडून बोटाचे ठसे घेतले / नाही — कारण',
                controller: _fingerprintReasonCtrl,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              const SizedBox(height: 8),
              BilingualField(
                label:
                    '(b) Photo taken / not taken — reason (identified body) :-',
                marathiLabel:
                    'अनोळखी प्रेताचे फोटो घेतले आहेत काय / नाही — कारण',
                controller: _photoReasonCtrl,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              const SizedBox(height: 12),

              // 15) Dead Body sent to PM
              BilingualField(
                label: '15) Dead body sent to P.M. / not — reason :-',
                marathiLabel:
                    'प्रेत (पोस्ट मार्टम) शल्य चिकित्सा करीता पाठविले / नाही — कारण',
                controller: _sentToPMReasonCtrl,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              BilingualField(
                label: '(a) Hospital where body sent for P.M. :-',
                marathiLabel:
                    'कोणत्या दवाखान्यात प्रेत पोस्ट मार्टम करीता पाठविले',
                controller: _hospitalNameCtrl,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              const SizedBox(height: 8),
              BilingualSectionHeader(
                label: '(b) With whom (Name, No. and P.S.) :-',
                marathiLabel: 'कोणा बरोबर पाठविले (नांव व पो.स्टे)',
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              BilingualFieldRow(
                fields: [
                  BilingualField(
                    label: 'Name :-',
                    marathiLabel: 'नांव',
                    controller: _sentOfficerNameCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                  BilingualField(
                    label: 'B/No :-',
                    marathiLabel: 'बक्कल नंबर',
                    controller: _sentOfficerBNoCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                  BilingualField(
                    label: 'P.S. :-',
                    marathiLabel: 'पो.स्टे',
                    controller: _sentOfficerPsCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 16) Opinion of Panchas
              BilingualMultilineField(
                label: '16) Opinion of Panchas and Police about death :-',
                marathiLabel: 'पंच व पोलीसांचा मृत्युविषयी अभिप्राय',
                controller: _opinionPanchasCtrl,
                minLines: 3,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              const SizedBox(height: 12),

              // 17) More Info
              BilingualMultilineField(
                label: '17) More information if any :-',
                marathiLabel: 'अधिक माहिती असल्यास',
                controller: _moreInfoCtrl,
                minLines: 2,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              const SizedBox(height: 24),

              // PAGE BREAK EQUIVALENT
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Page 4',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const Divider(color: Colors.black45),
              const SizedBox(height: 12),

              // 18) Date and Time of panchanama
              BilingualSectionHeader(
                label: '18) Date and Time of panchanama :-',
                marathiLabel: 'पंचनामा केल्याची दिनांक व वेळ',
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              BilingualFieldRow(
                fields: [
                  BilingualField(
                    label: 'Date :-',
                    marathiLabel: 'दिनांक',
                    controller: _panchanamaDateCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                  BilingualField(
                    label: 'Time :-',
                    marathiLabel: 'वेळ',
                    controller: _panchanamaTimeCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                  BilingualField(
                    label: 'To :-',
                    marathiLabel: 'ते',
                    controller: _panchanamaTimeToCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 19) Name of Panchas & Signature
              BilingualSectionHeader(
                label: '19) Name of Panchas and Signature :-',
                marathiLabel: 'पंचनामा करणाऱ्या पंचाची नांवे',
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        BilingualField(
                          label: 'Panch 1) :-',
                          marathiLabel: '१)',
                          controller: _panch1Ctrl,
                          serifStyle: serifStyle,
                          marathiLabelStyle: marathiLabelStyle,
                        ),
                        BilingualField(
                          label: 'Panch 2) :-',
                          marathiLabel: '२)',
                          controller: _panch2Ctrl,
                          serifStyle: serifStyle,
                          marathiLabelStyle: marathiLabelStyle,
                        ),
                        BilingualField(
                          label: 'Panch 3) :-',
                          marathiLabel: '३)',
                          controller: _panch3Ctrl,
                          serifStyle: serifStyle,
                          marathiLabelStyle: marathiLabelStyle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  Expanded(
                    child: Column(
                      children: [
                        BilingualField(
                          label: 'Signature 1) :-',
                          marathiLabel: 'सह्या १)',
                          controller: _panch1SigCtrl,
                          serifStyle: serifStyle,
                          marathiLabelStyle: marathiLabelStyle,
                        ),
                        BilingualField(
                          label: 'Signature 2) :-',
                          marathiLabel: 'सह्या २)',
                          controller: _panch2SigCtrl,
                          serifStyle: serifStyle,
                          marathiLabelStyle: marathiLabelStyle,
                        ),
                        BilingualField(
                          label: 'Signature 3) :-',
                          marathiLabel: 'सह्या ३)',
                          controller: _panch3SigCtrl,
                          serifStyle: serifStyle,
                          marathiLabelStyle: marathiLabelStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Investigation Officer Sign
              FormIoSignatureBlock(
                nameCtrl: _ioNameCtrl,
                rankCtrl: _ioRankCtrl,
                numberCtrl: _ioNoCtrl,
                postingCtrl: _ioPostingCtrl,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
                marathiLabel: FormIoTerminology.signatureOnly,
              ),
            ],
          ),
        if (_shows(kMainInquest) &&
            (_shows(kCivilSurgeon) || widget.formSection?.isEmpty == true))
          const SizedBox(height: 24),
        if (_shows(kCivilSurgeon)) ...[
          _buildCivilSurgeonPage5(serifStyle, marathiLabelStyle),
          _buildCivilSurgeonPage6(serifStyle, marathiLabelStyle),
        ],
        if (_shows(kCivilSurgeon) &&
            (_shows(kVinantiArj) || widget.formSection?.isEmpty == true))
          const SizedBox(height: 24),
        if (_shows(kVinantiArj)) ...[
          _buildVinantiArjPage7(serifStyle, marathiLabelStyle),
        ],
        if (_shows(kVinantiArj) &&
            (_shows(kRelativeSummons) || widget.formSection?.isEmpty == true))
          const SizedBox(height: 24),
        if (_shows(kRelativeSummons)) ...[
          _buildRelativeSummonsPage8(serifStyle, marathiLabelStyle),
        ],
        if (_shows(kRelativeSummons) &&
            (_shows(kPanchaSummons) || widget.formSection?.isEmpty == true))
          const SizedBox(height: 24),
        if (_shows(kPanchaSummons)) ...[
          _buildPanchaSummonsPage9(serifStyle, marathiLabelStyle),
        ],
        if (_shows(kPanchaSummons) &&
            (_shows(kMarananveshan) || widget.formSection?.isEmpty == true))
          const SizedBox(height: 24),
        if (_shows(kMarananveshan))
          FormPaperPage(
            formLabel: widget.pageRange ?? 'Pages 21–22',
            children: [
              // SIMPLIFIED MARATHI PANCHANAMA (Page 10)
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Page 10 (मरणांवेषण पंचनामा)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const Divider(color: Colors.black, thickness: 1.5),
              const SizedBox(height: 12),

              Center(
                child: Column(
                  children: [
                    Text(
                      'Maran Anveshan Panchanama',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    Text(
                      'मरणांवेषण पंचनामा',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 420,
                  child: Column(
                    children: [
                      BilingualField(
                        label: 'Place :-',
                        marathiLabel: 'ठिकाण',
                        controller: _marThikanCtrl,
                        serifStyle: serifStyle,
                        marathiLabelStyle: marathiLabelStyle,
                      ),
                      BilingualField(
                        label: 'Date :-',
                        marathiLabel: 'दिनांक',
                        controller: _marDateCtrl,
                        serifStyle: serifStyle,
                        marathiLabelStyle: marathiLabelStyle,
                      ),
                      BilingualField(
                        label: 'Start time :-',
                        marathiLabel: 'सुरु केल्याची वेळ',
                        controller: _marTimeCtrl,
                        serifStyle: serifStyle,
                        marathiLabelStyle: marathiLabelStyle,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              BilingualField(
                label: '1) Panch name and address :-',
                marathiLabel: '१) पंचाचे नांव व पत्ता',
                controller: _marPanchNameAddressCtrl,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              BilingualFieldRow(
                fields: [
                  BilingualField(
                    label: '2) Police Station :-',
                    marathiLabel: '२) पोलीस स्टेशन',
                    controller: _marPsCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                  BilingualField(
                    label: 'District :-',
                    marathiLabel: 'जिल्हा',
                    controller: _marDistCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                ],
              ),
              BilingualField(
                label: '3) Accidental death / crime / station diary no. :-',
                marathiLabel: '३) अकस्मात मृत्यू/गुन्हा/ठाणे दैनंदिनी क्र',
                controller: _marDiaryNoCtrl,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              BilingualWideField(
                label: '4) Act and Section :-',
                marathiLabel: '४) अधिनियम व कलम',
                controller: _marActSecCtrl,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              BilingualField(
                label: '5) I.O. name and rank :-',
                marathiLabel:
                    '५) ${FormIoTerminology.officer} — ${FormIoTerminology.name}, ${FormIoTerminology.rank}',
                controller: _marIoDetailsCtrl,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              BilingualField(
                label: '6) Complainant name :-',
                marathiLabel: '६) फिर्यादीचे नांव',
                controller: _marComplainantNameCtrl,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              BilingualField(
                label: '7) Deceased name and address :-',
                marathiLabel: '७) मृतकाचे नांव व पत्ता',
                controller: _marDeceasedNameAddressCtrl,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              BilingualField(
                label: '8) Name of person who showed/identified body :-',
                marathiLabel: '८) प्रेत दाखविणाऱ्याचे/ओळखणाऱ्याचे नांव',
                controller: _marShownByNameCtrl,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),

              BilingualMultilineField(
                label: '9) Description of place where body is kept :-',
                marathiLabel: '९) प्रेत ठेवले आहे त्या ठिकाणाचे वर्णन',
                controller: _marThikanDescriptionCtrl,
                minLines: 2,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              BilingualMultilineField(
                label: '10) Condition of the body :-',
                marathiLabel: '१०) प्रेताची स्थिती',
                controller: _marBodyConditionCtrl,
                minLines: 2,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              BilingualMultilineField(
                label: '11) Description of clothes on body :-',
                marathiLabel: '११) प्रेताचे अंगावरील कपड्याचे वर्णन',
                controller: _marBodyClothesCtrl,
                minLines: 2,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              BilingualMultilineField(
                label: '12) Ornaments and other articles on body :-',
                marathiLabel: '१२) प्रेताचे अंगावरील दागिने व इतर वस्तु',
                controller: _marBodyOrnamentsCtrl,
                minLines: 2,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              _buildPage11(
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
            ],
          ),
        if (_shows(kMarananveshan) &&
            (_shows(kKalmi14) || widget.formSection?.isEmpty == true))
          const SizedBox(height: 24),
        if (_shows(kKalmi14))
          FormPaperPage(
            formLabel: widget.pageRange ?? 'Page 23',
            children: [
              _buildPage12(
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              _buildPage13(
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
            ],
          ),
        if (_shows(kKalmi14) &&
            (_shows(kBodyHandover) || widget.formSection?.isEmpty == true))
          const SizedBox(height: 24),
        if (_shows(kBodyHandover))
          FormPaperPage(
            formLabel: widget.pageRange ?? 'Page 25',
            children: [
              _buildPage14(
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
            ],
          ),
        if (_shows(kBodyHandover) &&
            (_shows(kDutyPass) || widget.formSection?.isEmpty == true))
          const SizedBox(height: 24),
        if (_shows(kDutyPass))
          FormPaperPage(
            formLabel: widget.pageRange ?? 'Page 26',
            children: [
              _buildPage15(
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
            ],
          ),
      ],
    );
  }




  // ─────────────────────────────────────────────────────────────────
  // PAGE 11 — मरणांवेषण पंचनामा (Sections 13-18 + Signatures)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildPage11({
    required TextStyle serifStyle,
    required TextStyle marathiLabelStyle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Page 11 (मरणांवेषण — cont.)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const Divider(color: Colors.black, thickness: 1.5),
        const SizedBox(height: 12),
        Center(
          child: Column(
            children: [
              Text(
                'Maran Anveshan Panchanama (continued)',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'मरणांवेषण पंचनामा (पुढे चालू)',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        BilingualMultilineField(
          label: '13) Injuries / marks on the body of the deceased :-',
          marathiLabel: '१३) मृतकाच्या शरीरावरील मार, जखमा इत्यादी :',
          controller: _mar13InjuriesCtrl,
          minLines: 4,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualMultilineField(
          label:
              '14) Other marks, stains, decomposition, poison or injection — samples taken for examination (details) :-',
          marathiLabel:
              '१४) प्रेतावरील इतर खुणा, लच्छवी, विरघळन, विषा किंवा वांती झाली काय ? तपासणीकरीता नमुने घेतले काय सविस्तर उल्लेख करावा :',
          controller: _mar14OtherMarksCtrl,
          minLines: 4,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualMultilineField(
          label:
              '15) Disposal of ornaments and other articles on the body of the deceased :-',
          marathiLabel:
              '१५) मृतकाचे अंगावरील दागिने व इतर वस्तूंची काय विल्लेवाट लावली :',
          controller: _mar15OrnamentsDisposalCtrl,
          minLines: 3,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualMultilineField(
          label: '16) Opinion of Panchas and Investigating Officer :-',
          marathiLabel:
              '१६) पंच व ${FormIoTerminology.officer} यांचा अभिप्राय :',
          controller: _mar16OpinionCtrl,
          minLines: 3,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualMultilineField(
          label: '17) Disposal of the dead body :-',
          marathiLabel: '१७) प्रेताची काय विल्लेवाट लावली ?',
          controller: _mar17BodyDisposalCtrl,
          minLines: 3,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualMultilineField(
          label: '18) Date and time of completion of Panchanama :-',
          marathiLabel: '१८) पंचनामा संपविल्याची दिनांक व वेळ :',
          controller: _mar18DateTimeCtrl,
          minLines: 2,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Signature of Panchas',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text('पंचाची सही', style: marathiLabelStyle),
                  const SizedBox(height: 10),
                  BilingualField(
                    label: '1)',
                    marathiLabel: '१)',
                    controller: _mar11Panch1Ctrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                  BilingualField(
                    label: '2)',
                    marathiLabel: '२)',
                    controller: _mar11Panch2Ctrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                  BilingualField(
                    label: '3)',
                    marathiLabel: '३)',
                    controller: _mar11Panch3Ctrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                  BilingualField(
                    label: '4)',
                    marathiLabel: '४)',
                    controller: _mar11Panch4Ctrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                  const SizedBox(height: 12),
                  BilingualField(
                    label: 'Copy submitted to Medical Officer :-',
                    marathiLabel: 'प्रत सादर :- मा.वैद्यकीय अधिकारी—',
                    controller: _mar11CopyToCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
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
                    'I.O. Name, Rank & Signature / Seal',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    FormIoTerminology.signatureHeaderSeal,
                    style: marathiLabelStyle,
                  ),
                  const SizedBox(height: 10),
                  BilingualField(
                    label: 'Name :-',
                    marathiLabel: '${FormIoTerminology.name} :',
                    controller: _mar11IoNameCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                  BilingualField(
                    label: 'Rank :-',
                    marathiLabel: '${FormIoTerminology.rank} :',
                    controller: _mar11IoRankCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                  BilingualField(
                    label: 'Police Station :-',
                    marathiLabel: 'पोलीस स्टेशन :',
                    controller: _mar11IoPsCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // PAGE 12 — १४ कलमी फॉर्म (Q1–Q10)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildPage12({
    required TextStyle serifStyle,
    required TextStyle marathiLabelStyle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Page 12 (१४-कलमी फॉर्म)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const Divider(color: Colors.black, thickness: 1.5),
        const SizedBox(height: 12),
        Center(
          child: Column(
            children: [
              Text(
                '14-Clause Form (to be submitted with Inquest Panchanama)',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                '१४ कलमी फॉर्म व इन्क्वेस्ट पंचनामा सोबत द्यावाचा फॉर्म',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Submitted to Medical Officer',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'मा.वैद्यकीय अधिकारी यांना सादर',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        BilingualField(
          label: '1) Name and age of deceased :-',
          marathiLabel: '१) मृतकाचे नांव व वय :',
          controller: _kal14NameAgeCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualMultilineField(
          label: '2) Full address of deceased (village, taluka, district) :-',
          marathiLabel: '२) मृतकाचा पूर्ण पत्ता गांव तालुका जिल्हा:',
          controller: _kal14AddressCtrl,
          minLines: 2,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualMultilineField(
          label: '3) Place from where dead body was brought :-',
          marathiLabel:
              '३) मृतकाचे शव (प्रेत) ज्या ठिकाणाहुन आणले त्या जागेचे नांव पत्ता :',
          controller: _kal14ShavFromCtrl,
          minLines: 2,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualMultilineField(
          label: 'Place to which dead body was brought :-',
          marathiLabel: 'आणले त्या जागेचे नांव पत्ता',
          controller: _kal14ShavToCtrl,
          minLines: 2,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualMultilineField(
          label: '4) Full name and address of deceased\'s mother :-',
          marathiLabel: '४) मृतकाचे आईचे पूर्ण नांव व पत्ता :',
          controller: _kal14AaiNameCtrl,
          minLines: 2,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualMultilineField(
          label: '5) Full name and address of deceased\'s father :-',
          marathiLabel: '५) मृतकाचे बदोलचे पूर्ण नांव व पत्ता :',
          controller: _kal14BaapNameCtrl,
          minLines: 2,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualFieldRow(
          fields: [
            BilingualField(
              label: '6) Religion of deceased :-',
              marathiLabel: '६) मृतकाचा धर्म :',
              controller: _kal14DharmCtrl,
              serifStyle: serifStyle,
              marathiLabelStyle: marathiLabelStyle,
            ),
            BilingualField(
              label: 'Occupation of deceased :-',
              marathiLabel: 'मृतकाचा व्यवसाय :',
              controller: _kal14VyavsayCtrl,
              serifStyle: serifStyle,
              marathiLabelStyle: marathiLabelStyle,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildHabitRow(
          label:
              '7) Did the deceased smoke cigarettes? If yes, since how many days?',
          marathiLabel:
              '७) मृतक हा सिगरेट पित होता काय? असल्यास किती दिवसांपासून',
          checked: _kal14Cigarette,
          onChanged: (v) => setState(() => _kal14Cigarette = v ?? false),
          daysController: _kal14CigaretteDaysCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        _buildHabitRow(
          label:
              '8) Did the deceased have alcohol addiction? If yes, since how many days?',
          marathiLabel:
              '८) मृतकाला दारूचे व्यसन होते काय? असल्यास किती दिवसांपासून',
          checked: _kal14Daru,
          onChanged: (v) => setState(() => _kal14Daru = v ?? false),
          daysController: _kal14DaruDaysCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        _buildHabitRow(
          label:
              '9) Did the deceased have tobacco addiction? If yes, since how many days?',
          marathiLabel:
              '९) मृतकाला तंबाखूचे व्यसन होते काय? असल्यास किती दिवसांपासून',
          checked: _kal14Tambakhu,
          onChanged: (v) => setState(() => _kal14Tambakhu = v ?? false),
          daysController: _kal14TambakhuDaysCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        _buildHabitRow(
          label:
              '10) Did the deceased have habit of pan masala / supari? If yes, since how many days?',
          marathiLabel:
              '१०) मृतकाला पान मसाला, सुपारी खाण्याची सवय होती काय? असल्यास किती दिवसांपासून',
          checked: _kal14PanMasala,
          onChanged: (v) => setState(() => _kal14PanMasala = v ?? false),
          daysController: _kal14PanMasalaDaysCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // PAGE 13 — १४ कलमी फॉर्म (Q11–Q14) + IO Signature
  // ─────────────────────────────────────────────────────────────────
  Widget _buildPage13({
    required TextStyle serifStyle,
    required TextStyle marathiLabelStyle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Page 13 (१४-कलमी — cont.)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const Divider(color: Colors.black, thickness: 1.5),
        const SizedBox(height: 12),
        Center(
          child: Column(
            children: [
              Text(
                '14-Clause Form (continued)',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '१४ कलमी फॉर्म (पुढे चालू)',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '11) In case of vehicle accident :-',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Text('११) वाहन अपघाताची केस असल्यास :', style: marathiLabelStyle),
        const SizedBox(height: 8),
        BilingualField(
          label: 'a) Name of vehicle involved in accident :-',
          marathiLabel: 'अ) अपघात झालेल्या वाहनाचे नांव :',
          controller: _kal14VehicleNameCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualField(
          label: 'b) Deceased was driver or passenger :-',
          marathiLabel: 'ब) मृतक ड्रायव्हर किंवा पॅसेंजर :',
          controller: _kal14DriverPassCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualField(
          label: 'c) Or pedestrian (specify) :-',
          marathiLabel: 'क) किंवा पादचारी या पैकी काय होता :',
          controller: _kal14PedestrianCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualField(
          label: 'd) How the accident occurred :-',
          marathiLabel: 'ड) अपघात कसा झाला :',
          controller: _kal14AccidentHowCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualField(
          label: 'Date and time of accident :-',
          marathiLabel:
              'अपघात झाल्याची तारीख व वेळ (दिनांक ....../....../२०...... रोजी चे ...../....... वा दरम्यान)',
          controller: _kal14AccidentDateTimeCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        const SizedBox(height: 8),
        BilingualMultilineField(
          label: '12) If death was due to fall, give details :-',
          marathiLabel: '१२) मृत्यू हा पडून झाला असल्यास त्याबाबत माहिती :',
          controller: _kal14FallInfoCtrl,
          minLines: 3,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualField(
          label:
              '13) If deceased is female — was she pregnant? If yes, how many months?',
          marathiLabel:
              '१३) मृतक ही स्त्री असल्यास ती गरोदर होती काय? असल्यास किती महिने?',
          controller: _kal14PregnantMonthsCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualMultilineField(
          label: 'If female — had delivery or abortion occurred?',
          marathiLabel:
              'मृतक ही स्त्री असल्यास ती बाळांत झाली होती काय किंवा तिचे अबोर्शिन झाले होते काय?',
          controller: _kal14DeliveredAbortionCtrl,
          minLines: 2,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualField(
          label: 'If yes, since how many days?',
          marathiLabel: 'असल्यास किती दिवसांपासून ?',
          controller: _kal14PregnantDaysCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualMultilineField(
          label:
              '14) Name, address and relationship of person identifying the deceased :-',
          marathiLabel:
              '१४) मृतकाची ओळख पटविणाऱ्याचे नांव व पत्ता व मृतकाशी त्याचे काय संबंध नाते आहे (लिहावे)',
          controller: _kal14IdentifierNameCtrl,
          minLines: 3,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'I.O. Name, Rank & Signature / Seal',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                FormIoTerminology.signatureHeaderSeal,
                style: marathiLabelStyle,
              ),
              const SizedBox(height: 8),
              BilingualField(
                label: 'Name :-',
                marathiLabel: '${FormIoTerminology.name} :',
                controller: _kal14IoNameCtrl,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              BilingualField(
                label: 'Rank :-',
                marathiLabel: '${FormIoTerminology.rank} :',
                controller: _kal14IoRankCtrl,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
              BilingualField(
                label: 'Police Station :-',
                marathiLabel: 'पोलीस स्टेशन :',
                controller: _kal14IoPsCtrl,
                serifStyle: serifStyle,
                marathiLabelStyle: marathiLabelStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // PAGE 14 — प्रेत ताबा पावती (Body Custody Receipt)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildPage14({
    required TextStyle serifStyle,
    required TextStyle marathiLabelStyle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Page 14 (प्रेत ताबा पावती)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const Divider(color: Colors.black, thickness: 1.5),
        const SizedBox(height: 12),
        Center(
          child: Column(
            children: [
              Text(
                'Body Custody Receipt',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
              Text(
                'प्रेत ताबा पावती',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 420,
            child: Column(
              children: [
                BilingualField(
                  label: 'Police Station :-',
                  marathiLabel: 'पोलीस स्टेशन :',
                  controller: _ptpPsCtrl,
                  serifStyle: serifStyle,
                  marathiLabelStyle: marathiLabelStyle,
                ),
                BilingualField(
                  label: 'Camp :-',
                  marathiLabel: 'कॅम्प :',
                  controller: _ptpCampCtrl,
                  serifStyle: serifStyle,
                  marathiLabelStyle: marathiLabelStyle,
                ),
                BilingualField(
                  label: 'Date :-',
                  marathiLabel: 'दिनांक :',
                  controller: _ptpDateCtrl,
                  serifStyle: serifStyle,
                  marathiLabelStyle: marathiLabelStyle,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'I hereby give this body custody receipt that on the date mentioned below, I have received custody of the dead body for post-mortem and final rites. I confirm the body is of the deceased named below. I have taken custody as heir/representative and have no objection.',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 4),
        const Text(
          'मी प्रेत ताबा पावती लिहून देतो की, आज दिनांक ... रोजी मृतक नामे ... हयाचे / हिचे प्रेत पोस्टमार्टम होवुन अंतिम संस्काराकरीता माझे ताब्यात मिळाले आहे. सदर प्रेत हे नमुद मृतकाचेच आहे. मी मृतकाचा वारसा या नात्याने ताब्यात घेतले आहे. माझी कोणत्याच प्रकारची तक्रार नाही.',
          style: TextStyle(fontSize: 11, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        BilingualField(
          label: 'I (Receiver name) :-',
          marathiLabel: 'मी (प्रेत ताब्यात घेणाऱ्याचे नांव) :',
          controller: _ptpReceiverNameCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualFieldRow(
          fields: [
            BilingualField(
              label: 'Village (R.) :-',
              marathiLabel: 'र. :',
              controller: _ptpReceiverRaCtrl,
              serifStyle: serifStyle,
              marathiLabelStyle: marathiLabelStyle,
            ),
            BilingualField(
              label: 'Taluka (Ta.) :-',
              marathiLabel: 'ता :',
              controller: _ptpReceiverTaCtrl,
              serifStyle: serifStyle,
              marathiLabelStyle: marathiLabelStyle,
            ),
            BilingualField(
              label: 'District :-',
              marathiLabel: 'जिल्हा :',
              controller: _ptpReceiverDistCtrl,
              serifStyle: serifStyle,
              marathiLabelStyle: marathiLabelStyle,
            ),
          ],
        ),
        BilingualField(
          label: 'Mobile No. :-',
          marathiLabel: 'मो नं :',
          controller: _ptpMoNoCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualField(
          label: 'Receipt date :-',
          marathiLabel: 'प्रेत ताबा पावती दिनांक :',
          controller: _ptpReceiptDateCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualField(
          label: 'Deceased name :-',
          marathiLabel: 'मृतक नामे :',
          controller: _ptpDeceasedNameCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualFieldRow(
          fields: [
            BilingualField(
              label: 'Deceased village (R.) :-',
              marathiLabel: 'र. :',
              controller: _ptpDeceasedRaCtrl,
              serifStyle: serifStyle,
              marathiLabelStyle: marathiLabelStyle,
            ),
            BilingualField(
              label: 'Taluka & District :-',
              marathiLabel: 'ता आणी जिल्हा :',
              controller: _ptpDeceasedDistCtrl,
              serifStyle: serifStyle,
              marathiLabelStyle: marathiLabelStyle,
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Issuing body custody receipt accordingly.',
          style: TextStyle(fontSize: 13),
        ),
        Text('करीता प्रेत ताबा पावती लिहून देत आहे.', style: marathiLabelStyle),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'I.O. Name, Rank & Signature / Seal',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    FormIoTerminology.signatureHeaderSeal,
                    style: marathiLabelStyle,
                  ),
                  const SizedBox(height: 8),
                  BilingualField(
                    label: 'Name :-',
                    marathiLabel: '${FormIoTerminology.name} :',
                    controller: _ptpIoNameCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                  BilingualField(
                    label: 'Rank :-',
                    marathiLabel: '${FormIoTerminology.rank} :',
                    controller: _ptpIoRankCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                  BilingualField(
                    label: 'Police Station :-',
                    marathiLabel: 'पोलीस स्टेशन :',
                    controller: _ptpIoPsCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Signature of body receiver',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'प्रेत ताब्यात घेणाऱ्याची सही',
                    style: marathiLabelStyle,
                  ),
                  const SizedBox(height: 8),
                  BilingualField(
                    label: 'Signature :-',
                    marathiLabel: 'सही :',
                    controller: _ptpReceiverSigCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // PAGE 15 — ड्युटी पास (Duty Pass)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildPage15({
    required TextStyle serifStyle,
    required TextStyle marathiLabelStyle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Page 15 (ड्युटी पास)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const Divider(color: Colors.black, thickness: 1.5),
        const SizedBox(height: 12),
        Center(
          child: Column(
            children: [
              Text(
                'Duty Pass',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
              Text(
                'ड्युटी पास',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 420,
            child: Column(
              children: [
                BilingualField(
                  label: 'Police Station :-',
                  marathiLabel: 'पोलीस स्टेशन :',
                  controller: _dpPsCtrl,
                  serifStyle: serifStyle,
                  marathiLabelStyle: marathiLabelStyle,
                ),
                BilingualField(
                  label: 'Camp :-',
                  marathiLabel: 'कॅम्प :',
                  controller: _dpCampCtrl,
                  serifStyle: serifStyle,
                  marathiLabelStyle: marathiLabelStyle,
                ),
                BilingualField(
                  label: 'Date :-',
                  marathiLabel: 'दिनांक :',
                  controller: _dpDateCtrl,
                  serifStyle: serifStyle,
                  marathiLabelStyle: marathiLabelStyle,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        BilingualField(
          label: 'Name of Police Constable :-',
          marathiLabel: 'पो अंमलदाराचे नांव :',
          controller: _dpAmaldaarNameCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualField(
          label: 'Police Station (duty) :-',
          marathiLabel: 'पोलीस स्टेशन :',
          controller: _dpDutyPsCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualField(
          label: 'District :-',
          marathiLabel: 'जिल्हा',
          controller: _dpDutyDistCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualField(
          label: 'Duty date and time :-',
          marathiLabel: 'नोकरीचा दिनांक व वेळ :-',
          controller: _dpDutyDateTimeCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        const SizedBox(height: 12),
        const Text(
          'You are hereby ordered to take the dead body along with you and produce it before the Medical Officer for post-mortem examination.',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 4),
        const Text(
          'आपणास आदेश देण्यात येतो की, आपण ... हयाचे / हिचे प्रेत सोबत घेवून मा.वैद्यकीय अधिकारी यांचेकडे शवविच्छेदनाकरीता दाखल करावे.',
          style: TextStyle(fontSize: 11, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        BilingualFieldRow(
          fields: [
            BilingualField(
              label: 'Accidental / Death / Station Diary No. :-',
              marathiLabel: 'अप/ मर्ग/ स्टे.डायरी क्रमांक :',
              controller: _dpMargNoCtrl,
              serifStyle: serifStyle,
              marathiLabelStyle: marathiLabelStyle,
            ),
            BilingualField(
              label: 'Year :-',
              marathiLabel: 'वर्ष :',
              controller: _dpMargYearCtrl,
              serifStyle: serifStyle,
              marathiLabelStyle: marathiLabelStyle,
            ),
          ],
        ),
        BilingualField(
          label: 'Section (Kalam) :-',
          marathiLabel: 'कलम :',
          controller: _dpKalamCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualField(
          label: 'Deceased name :-',
          marathiLabel: 'मधील मृतक नामे :',
          controller: _dpDeceasedNameCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        BilingualFieldRow(
          fields: [
            BilingualField(
              label: 'Village (R.) :-',
              marathiLabel: 'र. :',
              controller: _dpDeceasedRaCtrl,
              serifStyle: serifStyle,
              marathiLabelStyle: marathiLabelStyle,
            ),
            BilingualField(
              label: 'Taluka (Ta.) :-',
              marathiLabel: 'ता :',
              controller: _dpDeceasedTaCtrl,
              serifStyle: serifStyle,
              marathiLabelStyle: marathiLabelStyle,
            ),
            BilingualField(
              label: 'District :-',
              marathiLabel: 'जिल्हा :',
              controller: _dpDeceasedDistCtrl,
              serifStyle: serifStyle,
              marathiLabelStyle: marathiLabelStyle,
            ),
          ],
        ),
        BilingualField(
          label: 'Medical Officer (for post-mortem) :-',
          marathiLabel: 'मा.वैद्यकीय अधिकारी :',
          controller: _dpMedOfficerNameCtrl,
          serifStyle: serifStyle,
          marathiLabelStyle: marathiLabelStyle,
        ),
        const SizedBox(height: 8),
        const Text(
          'After post-mortem, hand over the body to the heir of the deceased. If clothing bundle is given by M.O. during P.M., take custody and hand over to investigating constable.',
          style: TextStyle(fontSize: 12),
        ),
        Text(
          'शवविच्छेदनांनतर प्रेत मृतकाचे वारसदारास ताब्यात देवन मा. वैद्यकीय अधिकारी यांनी पी.एम दरम्यान दिलेला कपडा बंडल दिल्यास ताब्यात घेवून तपासी अंमलदार यांचेकडे दाखल करावे.',
          style: marathiLabelStyle,
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Signature of duty pass holder',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text('ड्युटी पास घेणाऱ्याची सही', style: marathiLabelStyle),
                  const SizedBox(height: 8),
                  BilingualField(
                    label: 'Signature :-',
                    marathiLabel: 'सही :',
                    controller: _dpAmaldaarSigCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'I.O. Name, Rank & Signature / Seal',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    FormIoTerminology.signatureHeaderSeal,
                    style: marathiLabelStyle,
                  ),
                  const SizedBox(height: 8),
                  BilingualField(
                    label: 'Name :-',
                    marathiLabel: '${FormIoTerminology.name} :',
                    controller: _dpIoNameCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                  BilingualField(
                    label: 'Rank :-',
                    marathiLabel: '${FormIoTerminology.rank} :',
                    controller: _dpIoRankCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                  BilingualField(
                    label: 'Police Station :-',
                    marathiLabel: 'पोलीस स्टेशन :',
                    controller: _dpIoPsCtrl,
                    serifStyle: serifStyle,
                    marathiLabelStyle: marathiLabelStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
