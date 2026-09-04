import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bilingual_field.dart';
import 'form_paper_page.dart';
import 'form_table_helpers.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';

/// Medico-legal examination — Female survivor (13 pp) + Male accused (4 pp).
class Medical376FormView extends StatefulWidget {
  final bool readOnly;
  final String? formSection;
  final String? pageRange;

  const Medical376FormView({
    super.key,
    this.readOnly = false,
    this.formSection,
    this.pageRange,
  });

  @override
  State<Medical376FormView> createState() => Medical376FormViewState();
}

class Medical376FormViewState extends State<Medical376FormView> {
  bool get _showFemale {
    final s = widget.formSection?.toLowerCase() ?? '';
    if (s.isEmpty) return true;
    return s.contains('female');
  }

  bool get _showMale {
    final s = widget.formSection?.toLowerCase() ?? '';
    if (s.isEmpty) return false;
    return s.contains('male') && !s.contains('female');
  }

  // ── Female (survivor) — key identification fields ──
  final _fHospitalCtrl = TextEditingController();
  final _fOpdCtrl = TextEditingController();
  final _fInpatientCtrl = TextEditingController();
  final _fNameCtrl = TextEditingController();
  final _fParentCtrl = TextEditingController();
  final _fAddressCtrl = TextEditingController();
  final _fAgeCtrl = TextEditingController();
  final _fDobCtrl = TextEditingController();
  final _fSexCtrl = TextEditingController();
  final _fArrivalDtCtrl = TextEditingController();
  final _fExamStartCtrl = TextEditingController();
  final _fBroughtByCtrl = TextEditingController();
  final _fMlcCtrl = TextEditingController();
  final _fPsCtrl = TextEditingController();
  final _fConsciousCtrl = TextEditingController();
  final _fDisabilityCtrl = TextEditingController();
  final _fConsentCtrl = TextEditingController();
  final _fConsentNameCtrl = TextEditingController();
  final _fConsentParentCtrl = TextEditingController();
  final _fConsentTreatmentCtrl = TextEditingController();
  final _fConsentMedicoLegalCtrl = TextEditingController();
  final _fConsentSampleCtrl = TextEditingController();
  final _fConsentPoliceInfoCtrl = TextEditingController();
  final _fConsentLanguageCtrl = TextEditingController();
  final _fConsentSupportRoleCtrl = TextEditingController();
  final _fConsentHelperSigCtrl = TextEditingController();
  final _fSurvivorSigCtrl = TextEditingController();
  final _fWitnessSigCtrl = TextEditingController();
  final _fIdMark1Ctrl = TextEditingController();
  final _fIdMark2Ctrl = TextEditingController();
  final _fMenarcheYesNoCtrl = TextEditingController();
  final _fMenarcheAgeCtrl = TextEditingController();
  final _fMenstrualCycleCtrl = TextEditingController();
  final _fLastMenstrualPeriodCtrl = TextEditingController();
  final _fMenstruationAtIncidentCtrl = TextEditingController();
  final _fMenstruationAtExamCtrl = TextEditingController();
  final _fPregnantAtIncidentCtrl = TextEditingController();
  final _fPregnancyDurationCtrl = TextEditingController();
  final _fContraceptionUseCtrl = TextEditingController();
  final _fContraceptionMethodCtrl = TextEditingController();
  final _fVaccinationTetanusCtrl = TextEditingController();
  final _fVaccinationHepBCtrl = TextEditingController();
  final _fMedHistoryCtrl = TextEditingController();
  final _fViolenceHistoryCtrl = TextEditingController();
  final _fIncidentDateCtrl = TextEditingController();
  final _fIncidentTimeCtrl = TextEditingController();
  final _fIncidentLocationCtrl = TextEditingController();
  final _fEstimatedDurationCtrl = TextEditingController();
  final _fEpisodeCtrl = TextEditingController();
  final _fAssailantCountAndNamesCtrl = TextEditingController();
  final _fAssailantSexCtrl = TextEditingController();
  final _fAssailantAgeCtrl = TextEditingController();
  final _fAssailantRelationshipCtrl = TextEditingController();
  final _fNarratorDetailsCtrl = TextEditingController();
  final _fHitWithCtrl = TextEditingController();
  final _fBurnedWithCtrl = TextEditingController();
  final _fBitingCtrl = TextEditingController();
  final _fKickingCtrl = TextEditingController();
  final _fPinchingCtrl = TextEditingController();
  final _fPullingHairCtrl = TextEditingController();
  final _fViolentShakingCtrl = TextEditingController();
  final _fBangingHeadCtrl = TextEditingController();
  final _fPhysicalViolenceCtrl = TextEditingController();
  final _fEmotionalAbuseCtrl = TextEditingController();
  final _fSexualViolenceDetailCtrl = TextEditingController();
  final _f15cEmotionalAbuseCtrl = TextEditingController();
  final _f15cRestraintsCtrl = TextEditingController();
  final _f15cWeaponsCtrl = TextEditingController();
  final _f15cVerbalThreatsCtrl = TextEditingController();
  final _f15cLuringCtrl = TextEditingController();
  final _f15cAnyOtherCtrl = TextEditingController();
  final _f15dIntoxicationCtrl = TextEditingController();
  final _f15dUnconsciousCtrl = TextEditingController();
  final _f15eAssailantInjuryCtrl = TextEditingController();
  final _fPenGenitaliaPenisCtrl = TextEditingController();
  final _fPenGenitaliaBodyPartCtrl = TextEditingController();
  final _fPenGenitaliaObjectCtrl = TextEditingController();
  final _fEmissionGenitaliaCtrl = TextEditingController();
  final _fPenAnusPenisCtrl = TextEditingController();
  final _fPenAnusBodyPartCtrl = TextEditingController();
  final _fPenAnusObjectCtrl = TextEditingController();
  final _fEmissionAnusCtrl = TextEditingController();
  final _fPenMouthPenisCtrl = TextEditingController();
  final _fPenMouthBodyPartCtrl = TextEditingController();
  final _fPenMouthObjectCtrl = TextEditingController();
  final _fEmissionMouthCtrl = TextEditingController();
  final _fOralSexPerformedCtrl = TextEditingController();
  final _fForcedMasturbationSelfCtrl = TextEditingController();
  final _fMasturbationAssailantCtrl = TextEditingController();
  final _fExhibitionismCtrl = TextEditingController();
  final _fEjaculationOutsideCtrl = TextEditingController();
  final _fEjaculationWhereBodyCtrl = TextEditingController();
  final _fKissingLickingSuckingCtrl = TextEditingController();
  final _fKissingLickingDescCtrl = TextEditingController();
  final _fTouchingFondlingCtrl = TextEditingController();
  final _fTouchingFondlingDescCtrl = TextEditingController();
  final _fCondomUsedCtrl = TextEditingController();
  final _fCondomStatusCtrl = TextEditingController();
  final _fLubricantUsedCtrl = TextEditingController();
  final _fLubricantKindDescCtrl = TextEditingController();
  final _fObjectUsedDescCtrl = TextEditingController();
  final _fOtherSexualViolenceFormsCtrl = TextEditingController();
  final _fPostChangedClothesCtrl = TextEditingController();
  final _fPostChangedClothesRemCtrl = TextEditingController();
  final _fPostChangedUndergarmentsCtrl = TextEditingController();
  final _fPostChangedUndergarmentsRemCtrl = TextEditingController();
  final _fPostCleanedClothesCtrl = TextEditingController();
  final _fPostCleanedClothesRemCtrl = TextEditingController();
  final _fPostCleanedUndergarmentsCtrl = TextEditingController();
  final _fPostCleanedUndergarmentsRemCtrl = TextEditingController();
  final _fPostBathedCtrl = TextEditingController();
  final _fPostBathedRemCtrl = TextEditingController();
  final _fPostDouchedCtrl = TextEditingController();
  final _fPostDouchedRemCtrl = TextEditingController();
  final _fPostPassedUrineCtrl = TextEditingController();
  final _fPostPassedUrineRemCtrl = TextEditingController();
  final _fPostPassedStoolsCtrl = TextEditingController();
  final _fPostPassedStoolsRemCtrl = TextEditingController();
  final _fPostRinsingMouthCtrl = TextEditingController();
  final _fPostRinsingMouthRemCtrl = TextEditingController();
  final _fTimeSinceIncidentCtrl = TextEditingController();
  final _fBleedingPriorIncidentCtrl = TextEditingController();
  final _fBleedingSinceIncidentCtrl = TextEditingController();
  final _fPainSinceIncidentCtrl = TextEditingController();
  final _fExamIsFirstCtrl = TextEditingController();
  final _fExamPulseCtrl = TextEditingController();
  final _fExamBpCtrl = TextEditingController();
  final _fExamTempCtrl = TextEditingController();
  final _fExamRespRateCtrl = TextEditingController();
  final _fExamPupilsCtrl = TextEditingController();
  final _fExamGeneralWellbeingCtrl = TextEditingController();
  final _fPostIncidentCtrl = TextEditingController();
  final _fGeneralExamCtrl = TextEditingController();
  final _fBodyFrontNotesCtrl = TextEditingController();
  final _fBodyBackNotesCtrl = TextEditingController();
  final _fGenitalExamCtrl = TextEditingController();
  final _fSystemicExamCtrl = TextEditingController();
  final List<TextEditingController> _fGenitalPartFindings =
      List.generate(12, (_) => TextEditingController());
  final List<TextEditingController> _fGenitalPartNotes =
      List.generate(12, (_) => TextEditingController());
  final _fPsFindingsCtrl = TextEditingController();
  final _fPvFindingsCtrl = TextEditingController();
  final _fPvPsReasonsCtrl = TextEditingController();
  final _fAnusRectumEncircledCtrl = TextEditingController();
  final _fAnusRectumNotesCtrl = TextEditingController();
  final _fOralCavityEncircledCtrl = TextEditingController();
  final _fOralCavityNotesCtrl = TextEditingController();
  final _fSysCnsCtrl = TextEditingController();
  final _fSysCvsCtrl = TextEditingController();
  final _fSysRespCtrl = TextEditingController();
  final _fSysChestCtrl = TextEditingController();
  final _fSysAbdomenCtrl = TextEditingController();
  final _fSampleBloodHivCtrl = TextEditingController();
  final _fSampleUrinePregCtrl = TextEditingController();
  final _fSampleUsgCtrl = TextEditingController();
  final _fSampleXrayCtrl = TextEditingController();
  final _fFslDebrisCtrl = TextEditingController();
  final _fClothingDetailsCtrl = TextEditingController();
  final List<TextEditingController> _fFslSampleCollected =
      List.generate(11, (_) => TextEditingController());
  final List<TextEditingController> _fFslSampleReasons =
      List.generate(11, (_) => TextEditingController());
  final List<TextEditingController> _fGenitalEvidenceCollected =
      List.generate(10, (_) => TextEditingController());
  final List<TextEditingController> _fGenitalEvidenceReasons =
      List.generate(10, (_) => TextEditingController());
  final _fProvSurvivorNameCtrl = TextEditingController();
  final _fProvGenderCtrl = TextEditingController();
  final _fProvAgeCtrl = TextEditingController();
  final _fProvCircumstancesCtrl = TextEditingController();
  final _fProvTimeAfterIncidentCtrl = TextEditingController();
  final _fProvBathedDouchedCtrl = TextEditingController();
  final _fProvFslSamplesCtrl = TextEditingController();
  final _fProvHospSamplesCtrl = TextEditingController();
  final _fProvClinicalFindingsCtrl = TextEditingController();
  final _fProvAdditionalObsCtrl = TextEditingController();
  final _fGenitalDiagramNotesCtrl = TextEditingController();
  final _fLabSamplesCtrl = TextEditingController();
  final _fFslSamplesCtrl = TextEditingController();
  final _fGenitalEvidenceCtrl = TextEditingController();
  final _fProvisionalOpinionCtrl = TextEditingController();
  final List<TextEditingController> _fTreatmentChoice =
      List.generate(8, (_) => TextEditingController());
  final List<TextEditingController> _fTreatmentComments =
      List.generate(8, (_) => TextEditingController());
  final _fCompletionDateTimeCtrl = TextEditingController();
  final _fReportSheetsCountCtrl = TextEditingController();
  final _fReportEnvelopesCountCtrl = TextEditingController();
  final _fCompletionPlaceCtrl = TextEditingController();
  final _fDoctorNameCtrl = TextEditingController();
  final _fDoctorSealCtrl = TextEditingController();
  final _fFinalOpinionPersonCtrl = TextEditingController();
  final _fFinalOpinionTimeCtrl = TextEditingController();
  final _fFinalOpinionTextCtrl = TextEditingController();
  final _fFinalOpinionPlaceCtrl = TextEditingController();
  final _fFinalDoctorNameCtrl = TextEditingController();
  final _fFinalDoctorSealCtrl = TextEditingController();
  final _fTreatmentCtrl = TextEditingController();
  final _fCompletionCtrl = TextEditingController();
  final _fFinalOpinionCtrl = TextEditingController();

  final List<TextEditingController> _fInjuryRows =
      List.generate(12, (_) => TextEditingController());

  // ── Male (accused) ──
  final _mHospitalCtrl = TextEditingController();
  final _mOpdCtrl = TextEditingController();
  final _mDateCtrl = TextEditingController();
  final _mMlcCtrl = TextEditingController();
  final _mMlcDateCtrl = TextEditingController();
  final _mAccusedNameCtrl = TextEditingController();
  final _mAgeCtrl = TextEditingController();
  final _mDobCtrl = TextEditingController();
  final _mReligionCtrl = TextEditingController();
  final _mMaritalCtrl = TextEditingController();
  final _mAddressCtrl = TextEditingController();
  final _mPoliceNameCtrl = TextEditingController();
  final _mBuckleCtrl = TextEditingController();
  final _mPsCtrl = TextEditingController();
  final _mCrNoCtrl = TextEditingController();
  final _mSectionCtrl = TextEditingController();
  final _mConsentCtrl = TextEditingController();
  final _mIdMark1Ctrl = TextEditingController();
  final _mIdMark2Ctrl = TextEditingController();
  final _mExamDateTimeCtrl = TextEditingController();
  final _mDoctorCtrl = TextEditingController();
  final _mAssaultHistoryCtrl = TextEditingController();
  final _mWitnessSigCtrl = TextEditingController();
  final _mAccusedSigCtrl = TextEditingController();
  final _mMedSurgicalHistoryCtrl = TextEditingController();
  final _mGeneralPhysicalCtrl = TextEditingController();
  final _mLocalExamCtrl = TextEditingController();
  final _mSystemicExamCtrl = TextEditingController();
  final _mAdditionalFindingsCtrl = TextEditingController();
  final _mLabSamplesCtrl = TextEditingController();
  final _mLab7CollectedCtrl = TextEditingController();
  final _mLab8CollectedCtrl = TextEditingController();
  final _mLab9CollectedCtrl = TextEditingController();
  final _mLab10CollectedCtrl = TextEditingController();
  final _mLab11SampleCtrl = TextEditingController();
  final _mLab11TestCtrl = TextEditingController();
  final _mLab11PackingCtrl = TextEditingController();
  final _mLab11CollectedCtrl = TextEditingController();
  final _mFslNoteCtrl = TextEditingController();
  final _mOpinionTimeElapsedCtrl = TextEditingController();
  final _mProvisionalOpinionCtrl = TextEditingController();
  final _mOpinionDateCtrl = TextEditingController();
  final _mReportPagesCountCtrl = TextEditingController();
  final _mDoctorSigCtrl = TextEditingController();
  final _mDoctorNameCtrl = TextEditingController();
  final _mDoctorDeptDesigCtrl = TextEditingController();
  final _mReceiptPoliceCtrl = TextEditingController();
  final _mReceiptPoliceNameCtrl = TextEditingController();
  final _mReceiptBuckleNoCtrl = TextEditingController();
  final _mReceiptPsCtrl = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _fHospitalCtrl,
      _fOpdCtrl,
      _fInpatientCtrl,
      _fNameCtrl,
      _fParentCtrl,
      _fAddressCtrl,
      _fAgeCtrl,
      _fDobCtrl,
      _fSexCtrl,
      _fArrivalDtCtrl,
      _fExamStartCtrl,
      _fBroughtByCtrl,
      _fMlcCtrl,
      _fPsCtrl,
      _fConsciousCtrl,
      _fDisabilityCtrl,
      _fConsentCtrl,
      _fConsentNameCtrl,
      _fConsentParentCtrl,
      _fConsentTreatmentCtrl,
      _fConsentMedicoLegalCtrl,
      _fConsentSampleCtrl,
      _fConsentPoliceInfoCtrl,
      _fConsentLanguageCtrl,
      _fConsentSupportRoleCtrl,
      _fConsentHelperSigCtrl,
      _fSurvivorSigCtrl,
      _fWitnessSigCtrl,
      _fIdMark1Ctrl,
      _fIdMark2Ctrl,
      _fMenarcheYesNoCtrl,
      _fMenarcheAgeCtrl,
      _fMenstrualCycleCtrl,
      _fLastMenstrualPeriodCtrl,
      _fMenstruationAtIncidentCtrl,
      _fMenstruationAtExamCtrl,
      _fPregnantAtIncidentCtrl,
      _fPregnancyDurationCtrl,
      _fContraceptionUseCtrl,
      _fContraceptionMethodCtrl,
      _fVaccinationTetanusCtrl,
      _fVaccinationHepBCtrl,
      _fMedHistoryCtrl,
      _fViolenceHistoryCtrl,
      _fIncidentDateCtrl,
      _fIncidentTimeCtrl,
      _fIncidentLocationCtrl,
      _fEstimatedDurationCtrl,
      _fEpisodeCtrl,
      _fAssailantCountAndNamesCtrl,
      _fAssailantSexCtrl,
      _fAssailantAgeCtrl,
      _fAssailantRelationshipCtrl,
      _fNarratorDetailsCtrl,
      _fHitWithCtrl,
      _fBurnedWithCtrl,
      _fBitingCtrl,
      _fKickingCtrl,
      _fPinchingCtrl,
      _fPullingHairCtrl,
      _fViolentShakingCtrl,
      _fBangingHeadCtrl,
      _fPhysicalViolenceCtrl,
      _fEmotionalAbuseCtrl,
      _fSexualViolenceDetailCtrl,
      _f15cEmotionalAbuseCtrl,
      _f15cRestraintsCtrl,
      _f15cWeaponsCtrl,
      _f15cVerbalThreatsCtrl,
      _f15cLuringCtrl,
      _f15cAnyOtherCtrl,
      _f15dIntoxicationCtrl,
      _f15dUnconsciousCtrl,
      _f15eAssailantInjuryCtrl,
      _fPenGenitaliaPenisCtrl,
      _fPenGenitaliaBodyPartCtrl,
      _fPenGenitaliaObjectCtrl,
      _fEmissionGenitaliaCtrl,
      _fPenAnusPenisCtrl,
      _fPenAnusBodyPartCtrl,
      _fPenAnusObjectCtrl,
      _fEmissionAnusCtrl,
      _fPenMouthPenisCtrl,
      _fPenMouthBodyPartCtrl,
      _fPenMouthObjectCtrl,
      _fEmissionMouthCtrl,
      _fOralSexPerformedCtrl,
      _fForcedMasturbationSelfCtrl,
      _fMasturbationAssailantCtrl,
      _fExhibitionismCtrl,
      _fEjaculationOutsideCtrl,
      _fEjaculationWhereBodyCtrl,
      _fKissingLickingSuckingCtrl,
      _fKissingLickingDescCtrl,
      _fTouchingFondlingCtrl,
      _fTouchingFondlingDescCtrl,
      _fCondomUsedCtrl,
      _fCondomStatusCtrl,
      _fLubricantUsedCtrl,
      _fLubricantKindDescCtrl,
      _fObjectUsedDescCtrl,
      _fOtherSexualViolenceFormsCtrl,
      _fPostChangedClothesCtrl,
      _fPostChangedClothesRemCtrl,
      _fPostChangedUndergarmentsCtrl,
      _fPostChangedUndergarmentsRemCtrl,
      _fPostCleanedClothesCtrl,
      _fPostCleanedClothesRemCtrl,
      _fPostCleanedUndergarmentsCtrl,
      _fPostCleanedUndergarmentsRemCtrl,
      _fPostBathedCtrl,
      _fPostBathedRemCtrl,
      _fPostDouchedCtrl,
      _fPostDouchedRemCtrl,
      _fPostPassedUrineCtrl,
      _fPostPassedUrineRemCtrl,
      _fPostPassedStoolsCtrl,
      _fPostPassedStoolsRemCtrl,
      _fPostRinsingMouthCtrl,
      _fPostRinsingMouthRemCtrl,
      _fTimeSinceIncidentCtrl,
      _fBleedingPriorIncidentCtrl,
      _fBleedingSinceIncidentCtrl,
      _fPainSinceIncidentCtrl,
      _fExamIsFirstCtrl,
      _fExamPulseCtrl,
      _fExamBpCtrl,
      _fExamTempCtrl,
      _fExamRespRateCtrl,
      _fExamPupilsCtrl,
      _fExamGeneralWellbeingCtrl,
      _fPostIncidentCtrl,
      _fGeneralExamCtrl,
      _fBodyFrontNotesCtrl,
      _fBodyBackNotesCtrl,
      _fGenitalExamCtrl,
      _fSystemicExamCtrl,
      ..._fGenitalPartFindings,
      ..._fGenitalPartNotes,
      _fPsFindingsCtrl,
      _fPvFindingsCtrl,
      _fPvPsReasonsCtrl,
      _fAnusRectumEncircledCtrl,
      _fAnusRectumNotesCtrl,
      _fOralCavityEncircledCtrl,
      _fOralCavityNotesCtrl,
      _fSysCnsCtrl,
      _fSysCvsCtrl,
      _fSysRespCtrl,
      _fSysChestCtrl,
      _fSysAbdomenCtrl,
      _fSampleBloodHivCtrl,
      _fSampleUrinePregCtrl,
      _fSampleUsgCtrl,
      _fSampleXrayCtrl,
      _fFslDebrisCtrl,
      _fClothingDetailsCtrl,
      ..._fFslSampleCollected,
      ..._fFslSampleReasons,
      ..._fGenitalEvidenceCollected,
      ..._fGenitalEvidenceReasons,
      _fProvSurvivorNameCtrl,
      _fProvGenderCtrl,
      _fProvAgeCtrl,
      _fProvCircumstancesCtrl,
      _fProvTimeAfterIncidentCtrl,
      _fProvBathedDouchedCtrl,
      _fProvFslSamplesCtrl,
      _fProvHospSamplesCtrl,
      _fProvClinicalFindingsCtrl,
      _fProvAdditionalObsCtrl,
      _fGenitalDiagramNotesCtrl,
      _fLabSamplesCtrl,
      _fFslSamplesCtrl,
      _fGenitalEvidenceCtrl,
      _fProvisionalOpinionCtrl,
      ..._fTreatmentChoice,
      ..._fTreatmentComments,
      _fCompletionDateTimeCtrl,
      _fReportSheetsCountCtrl,
      _fReportEnvelopesCountCtrl,
      _fCompletionPlaceCtrl,
      _fDoctorNameCtrl,
      _fDoctorSealCtrl,
      _fFinalOpinionPersonCtrl,
      _fFinalOpinionTimeCtrl,
      _fFinalOpinionTextCtrl,
      _fFinalOpinionPlaceCtrl,
      _fFinalDoctorNameCtrl,
      _fFinalDoctorSealCtrl,
      _fTreatmentCtrl,
      _fCompletionCtrl,
      _fFinalOpinionCtrl,
      ..._fInjuryRows,
      _mHospitalCtrl,
      _mOpdCtrl,
      _mDateCtrl,
      _mMlcCtrl,
      _mMlcDateCtrl,
      _mAccusedNameCtrl,
      _mAgeCtrl,
      _mDobCtrl,
      _mReligionCtrl,
      _mMaritalCtrl,
      _mAddressCtrl,
      _mPoliceNameCtrl,
      _mBuckleCtrl,
      _mPsCtrl,
      _mCrNoCtrl,
      _mSectionCtrl,
      _mConsentCtrl,
      _mIdMark1Ctrl,
      _mIdMark2Ctrl,
      _mExamDateTimeCtrl,
      _mDoctorCtrl,
      _mAssaultHistoryCtrl,
      _mWitnessSigCtrl,
      _mAccusedSigCtrl,
      _mMedSurgicalHistoryCtrl,
      _mGeneralPhysicalCtrl,
      _mLocalExamCtrl,
      _mSystemicExamCtrl,
      _mAdditionalFindingsCtrl,
      _mLabSamplesCtrl,
      _mLab7CollectedCtrl,
      _mLab8CollectedCtrl,
      _mLab9CollectedCtrl,
      _mLab10CollectedCtrl,
      _mLab11SampleCtrl,
      _mLab11TestCtrl,
      _mLab11PackingCtrl,
      _mLab11CollectedCtrl,
      _mFslNoteCtrl,
      _mOpinionTimeElapsedCtrl,
      _mProvisionalOpinionCtrl,
      _mOpinionDateCtrl,
      _mReportPagesCountCtrl,
      _mDoctorSigCtrl,
      _mDoctorNameCtrl,
      _mDoctorDeptDesigCtrl,
      _mReceiptPoliceCtrl,
      _mReceiptPoliceNameCtrl,
      _mReceiptBuckleNoCtrl,
      _mReceiptPsCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> collectData() {
    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'variant': _showFemale && _showMale
          ? 'both'
          : _showFemale
              ? 'female'
              : 'male',
      'f_hospital': _fHospitalCtrl.text.trim(),
      'f_opd': _fOpdCtrl.text.trim(),
      'f_inpatient': _fInpatientCtrl.text.trim(),
      'f_name': _fNameCtrl.text.trim(),
      'f_parent': _fParentCtrl.text.trim(),
      'f_address': _fAddressCtrl.text.trim(),
      'f_age': _fAgeCtrl.text.trim(),
      'f_dob': _fDobCtrl.text.trim(),
      'f_sex': _fSexCtrl.text.trim(),
      'f_arrival': _fArrivalDtCtrl.text.trim(),
      'f_examStart': _fExamStartCtrl.text.trim(),
      'f_broughtBy': _fBroughtByCtrl.text.trim(),
      'f_mlc': _fMlcCtrl.text.trim(),
      'f_ps': _fPsCtrl.text.trim(),
      'f_conscious': _fConsciousCtrl.text.trim(),
      'f_disability': _fDisabilityCtrl.text.trim(),
      'f_consent': _fConsentCtrl.text.trim(),
      'f_consentName': _fConsentNameCtrl.text.trim(),
      'f_consentParent': _fConsentParentCtrl.text.trim(),
      'f_consentTreatment': _fConsentTreatmentCtrl.text.trim(),
      'f_consentMedicoLegal': _fConsentMedicoLegalCtrl.text.trim(),
      'f_consentSample': _fConsentSampleCtrl.text.trim(),
      'f_consentPoliceInfo': _fConsentPoliceInfoCtrl.text.trim(),
      'f_consentLanguage': _fConsentLanguageCtrl.text.trim(),
      'f_consentSupportRole': _fConsentSupportRoleCtrl.text.trim(),
      'f_consentHelperSig': _fConsentHelperSigCtrl.text.trim(),
      'f_survivorSig': _fSurvivorSigCtrl.text.trim(),
      'f_witnessSig': _fWitnessSigCtrl.text.trim(),
      'f_idMark1': _fIdMark1Ctrl.text.trim(),
      'f_idMark2': _fIdMark2Ctrl.text.trim(),
      'f_menarcheYesNo': _fMenarcheYesNoCtrl.text.trim(),
      'f_menarcheAge': _fMenarcheAgeCtrl.text.trim(),
      'f_menstrualCycle': _fMenstrualCycleCtrl.text.trim(),
      'f_lastMenstrualPeriod': _fLastMenstrualPeriodCtrl.text.trim(),
      'f_menstruationAtIncident': _fMenstruationAtIncidentCtrl.text.trim(),
      'f_menstruationAtExam': _fMenstruationAtExamCtrl.text.trim(),
      'f_pregnantAtIncident': _fPregnantAtIncidentCtrl.text.trim(),
      'f_pregnancyDuration': _fPregnancyDurationCtrl.text.trim(),
      'f_contraceptionUse': _fContraceptionUseCtrl.text.trim(),
      'f_contraceptionMethod': _fContraceptionMethodCtrl.text.trim(),
      'f_vaccinationTetanus': _fVaccinationTetanusCtrl.text.trim(),
      'f_vaccinationHepB': _fVaccinationHepBCtrl.text.trim(),
      'f_medHistory': _fMedHistoryCtrl.text.trim(),
      'f_violenceHistory': _fViolenceHistoryCtrl.text.trim(),
      'f_incidentDate': _fIncidentDateCtrl.text.trim(),
      'f_incidentTime': _fIncidentTimeCtrl.text.trim(),
      'f_incidentLocation': _fIncidentLocationCtrl.text.trim(),
      'f_estimatedDuration': _fEstimatedDurationCtrl.text.trim(),
      'f_episode': _fEpisodeCtrl.text.trim(),
      'f_assailantCountAndNames': _fAssailantCountAndNamesCtrl.text.trim(),
      'f_assailantSex': _fAssailantSexCtrl.text.trim(),
      'f_assailantAge': _fAssailantAgeCtrl.text.trim(),
      'f_assailantRelationship': _fAssailantRelationshipCtrl.text.trim(),
      'f_narratorDetails': _fNarratorDetailsCtrl.text.trim(),
      'f_hitWith': _fHitWithCtrl.text.trim(),
      'f_burnedWith': _fBurnedWithCtrl.text.trim(),
      'f_biting': _fBitingCtrl.text.trim(),
      'f_kicking': _fKickingCtrl.text.trim(),
      'f_pinching': _fPinchingCtrl.text.trim(),
      'f_pullingHair': _fPullingHairCtrl.text.trim(),
      'f_violentShaking': _fViolentShakingCtrl.text.trim(),
      'f_bangingHead': _fBangingHeadCtrl.text.trim(),
      'f_physicalViolence': _fPhysicalViolenceCtrl.text.trim(),
      'f_emotionalAbuse': _fEmotionalAbuseCtrl.text.trim(),
      'f_sexualViolenceDetail': _fSexualViolenceDetailCtrl.text.trim(),
      'f_15cEmotionalAbuse': _f15cEmotionalAbuseCtrl.text.trim(),
      'f_15cRestraints': _f15cRestraintsCtrl.text.trim(),
      'f_15cWeapons': _f15cWeaponsCtrl.text.trim(),
      'f_15cVerbalThreats': _f15cVerbalThreatsCtrl.text.trim(),
      'f_15cLuring': _f15cLuringCtrl.text.trim(),
      'f_15cAnyOther': _f15cAnyOtherCtrl.text.trim(),
      'f_15dIntoxication': _f15dIntoxicationCtrl.text.trim(),
      'f_15dUnconscious': _f15dUnconsciousCtrl.text.trim(),
      'f_15eAssailantInjury': _f15eAssailantInjuryCtrl.text.trim(),
      'f_penGenitaliaPenis': _fPenGenitaliaPenisCtrl.text.trim(),
      'f_penGenitaliaBodyPart': _fPenGenitaliaBodyPartCtrl.text.trim(),
      'f_penGenitaliaObject': _fPenGenitaliaObjectCtrl.text.trim(),
      'f_emissionGenitalia': _fEmissionGenitaliaCtrl.text.trim(),
      'f_penAnusPenis': _fPenAnusPenisCtrl.text.trim(),
      'f_penAnusBodyPart': _fPenAnusBodyPartCtrl.text.trim(),
      'f_penAnusObject': _fPenAnusObjectCtrl.text.trim(),
      'f_emissionAnus': _fEmissionAnusCtrl.text.trim(),
      'f_penMouthPenis': _fPenMouthPenisCtrl.text.trim(),
      'f_penMouthBodyPart': _fPenMouthBodyPartCtrl.text.trim(),
      'f_penMouthObject': _fPenMouthObjectCtrl.text.trim(),
      'f_emissionMouth': _fEmissionMouthCtrl.text.trim(),
      'f_oralSexPerformed': _fOralSexPerformedCtrl.text.trim(),
      'f_forcedMasturbationSelf': _fForcedMasturbationSelfCtrl.text.trim(),
      'f_masturbationAssailant': _fMasturbationAssailantCtrl.text.trim(),
      'f_exhibitionism': _fExhibitionismCtrl.text.trim(),
      'f_ejaculationOutside': _fEjaculationOutsideCtrl.text.trim(),
      'f_ejaculationWhereBody': _fEjaculationWhereBodyCtrl.text.trim(),
      'f_kissingLickingSucking': _fKissingLickingSuckingCtrl.text.trim(),
      'f_kissingLickingDesc': _fKissingLickingDescCtrl.text.trim(),
      'f_touchingFondling': _fTouchingFondlingCtrl.text.trim(),
      'f_touchingFondlingDesc': _fTouchingFondlingDescCtrl.text.trim(),
      'f_condomUsed': _fCondomUsedCtrl.text.trim(),
      'f_condomStatus': _fCondomStatusCtrl.text.trim(),
      'f_lubricantUsed': _fLubricantUsedCtrl.text.trim(),
      'f_lubricantKindDesc': _fLubricantKindDescCtrl.text.trim(),
      'f_objectUsedDesc': _fObjectUsedDescCtrl.text.trim(),
      'f_otherSexualViolenceForms': _fOtherSexualViolenceFormsCtrl.text.trim(),
      'f_postChangedClothes': _fPostChangedClothesCtrl.text.trim(),
      'f_postChangedClothesRem': _fPostChangedClothesRemCtrl.text.trim(),
      'f_postChangedUndergarments': _fPostChangedUndergarmentsCtrl.text.trim(),
      'f_postChangedUndergarmentsRem':
          _fPostChangedUndergarmentsRemCtrl.text.trim(),
      'f_postCleanedClothes': _fPostCleanedClothesCtrl.text.trim(),
      'f_postCleanedClothesRem': _fPostCleanedClothesRemCtrl.text.trim(),
      'f_postCleanedUndergarments': _fPostCleanedUndergarmentsCtrl.text.trim(),
      'f_postCleanedUndergarmentsRem':
          _fPostCleanedUndergarmentsRemCtrl.text.trim(),
      'f_postBathed': _fPostBathedCtrl.text.trim(),
      'f_postBathedRem': _fPostBathedRemCtrl.text.trim(),
      'f_postDouched': _fPostDouchedCtrl.text.trim(),
      'f_postDouchedRem': _fPostDouchedRemCtrl.text.trim(),
      'f_postPassedUrine': _fPostPassedUrineCtrl.text.trim(),
      'f_postPassedUrineRem': _fPostPassedUrineRemCtrl.text.trim(),
      'f_postPassedStools': _fPostPassedStoolsCtrl.text.trim(),
      'f_postPassedStoolsRem': _fPostPassedStoolsRemCtrl.text.trim(),
      'f_postRinsingMouth': _fPostRinsingMouthCtrl.text.trim(),
      'f_postRinsingMouthRem': _fPostRinsingMouthRemCtrl.text.trim(),
      'f_timeSinceIncident': _fTimeSinceIncidentCtrl.text.trim(),
      'f_bleedingPriorIncident': _fBleedingPriorIncidentCtrl.text.trim(),
      'f_bleedingSinceIncident': _fBleedingSinceIncidentCtrl.text.trim(),
      'f_painSinceIncident': _fPainSinceIncidentCtrl.text.trim(),
      'f_examIsFirst': _fExamIsFirstCtrl.text.trim(),
      'f_examPulse': _fExamPulseCtrl.text.trim(),
      'f_examBp': _fExamBpCtrl.text.trim(),
      'f_examTemp': _fExamTempCtrl.text.trim(),
      'f_examRespRate': _fExamRespRateCtrl.text.trim(),
      'f_examPupils': _fExamPupilsCtrl.text.trim(),
      'f_examGeneralWellbeing': _fExamGeneralWellbeingCtrl.text.trim(),
      'f_postIncident': _fPostIncidentCtrl.text.trim(),
      'f_generalExam': _fGeneralExamCtrl.text.trim(),
      'f_bodyFrontNotes': _fBodyFrontNotesCtrl.text.trim(),
      'f_bodyBackNotes': _fBodyBackNotesCtrl.text.trim(),
      'f_genitalExam': _fGenitalExamCtrl.text.trim(),
      'f_systemicExam': _fSystemicExamCtrl.text.trim(),
      'f_genitalPartFindings':
          _fGenitalPartFindings.map((c) => c.text.trim()).toList(),
      'f_genitalPartNotes':
          _fGenitalPartNotes.map((c) => c.text.trim()).toList(),
      'f_psFindings': _fPsFindingsCtrl.text.trim(),
      'f_pvFindings': _fPvFindingsCtrl.text.trim(),
      'f_pvPsReasons': _fPvPsReasonsCtrl.text.trim(),
      'f_anusRectumEncircled': _fAnusRectumEncircledCtrl.text.trim(),
      'f_anusRectumNotes': _fAnusRectumNotesCtrl.text.trim(),
      'f_oralCavityEncircled': _fOralCavityEncircledCtrl.text.trim(),
      'f_oralCavityNotes': _fOralCavityNotesCtrl.text.trim(),
      'f_sysCns': _fSysCnsCtrl.text.trim(),
      'f_sysCvs': _fSysCvsCtrl.text.trim(),
      'f_sysResp': _fSysRespCtrl.text.trim(),
      'f_sysChest': _fSysChestCtrl.text.trim(),
      'f_sysAbdomen': _fSysAbdomenCtrl.text.trim(),
      'f_sampleBloodHiv': _fSampleBloodHivCtrl.text.trim(),
      'f_sampleUrinePreg': _fSampleUrinePregCtrl.text.trim(),
      'f_sampleUsg': _fSampleUsgCtrl.text.trim(),
      'f_sampleXray': _fSampleXrayCtrl.text.trim(),
      'f_fslDebris': _fFslDebrisCtrl.text.trim(),
      'f_clothingDetails': _fClothingDetailsCtrl.text.trim(),
      'f_fslSampleCollected':
          _fFslSampleCollected.map((c) => c.text.trim()).toList(),
      'f_fslSampleReasons':
          _fFslSampleReasons.map((c) => c.text.trim()).toList(),
      'f_genitalEvidenceCollected':
          _fGenitalEvidenceCollected.map((c) => c.text.trim()).toList(),
      'f_genitalEvidenceReasons':
          _fGenitalEvidenceReasons.map((c) => c.text.trim()).toList(),
      'f_provSurvivorName': _fProvSurvivorNameCtrl.text.trim(),
      'f_provGender': _fProvGenderCtrl.text.trim(),
      'f_provAge': _fProvAgeCtrl.text.trim(),
      'f_provCircumstances': _fProvCircumstancesCtrl.text.trim(),
      'f_provTimeAfterIncident': _fProvTimeAfterIncidentCtrl.text.trim(),
      'f_provBathedDouched': _fProvBathedDouchedCtrl.text.trim(),
      'f_provFslSamples': _fProvFslSamplesCtrl.text.trim(),
      'f_provHospSamples': _fProvHospSamplesCtrl.text.trim(),
      'f_provClinicalFindings': _fProvClinicalFindingsCtrl.text.trim(),
      'f_provAdditionalObs': _fProvAdditionalObsCtrl.text.trim(),
      'f_genitalDiagramNotes': _fGenitalDiagramNotesCtrl.text.trim(),
      'f_labSamples': _fLabSamplesCtrl.text.trim(),
      'f_fslSamples': _fFslSamplesCtrl.text.trim(),
      'f_genitalEvidence': _fGenitalEvidenceCtrl.text.trim(),
      'f_provisionalOpinion': _fProvisionalOpinionCtrl.text.trim(),
      'f_treatmentChoice': _fTreatmentChoice.map((c) => c.text.trim()).toList(),
      'f_treatmentComments':
          _fTreatmentComments.map((c) => c.text.trim()).toList(),
      'f_completionDateTime': _fCompletionDateTimeCtrl.text.trim(),
      'f_reportSheetsCount': _fReportSheetsCountCtrl.text.trim(),
      'f_reportEnvelopesCount': _fReportEnvelopesCountCtrl.text.trim(),
      'f_completionPlace': _fCompletionPlaceCtrl.text.trim(),
      'f_doctorName': _fDoctorNameCtrl.text.trim(),
      'f_doctorSeal': _fDoctorSealCtrl.text.trim(),
      'f_finalOpinionPerson': _fFinalOpinionPersonCtrl.text.trim(),
      'f_finalOpinionTime': _fFinalOpinionTimeCtrl.text.trim(),
      'f_finalOpinionText': _fFinalOpinionTextCtrl.text.trim(),
      'f_finalOpinionPlace': _fFinalOpinionPlaceCtrl.text.trim(),
      'f_finalDoctorName': _fFinalDoctorNameCtrl.text.trim(),
      'f_finalDoctorSeal': _fFinalDoctorSealCtrl.text.trim(),
      'f_treatment': _fTreatmentCtrl.text.trim(),
      'f_completion': _fCompletionCtrl.text.trim(),
      'f_finalOpinion': _fFinalOpinionCtrl.text.trim(),
      'f_injuryRows': _fInjuryRows.map((c) => c.text.trim()).toList(),
      'm_hospital': _mHospitalCtrl.text.trim(),
      'm_opd': _mOpdCtrl.text.trim(),
      'm_date': _mDateCtrl.text.trim(),
      'm_mlc': _mMlcCtrl.text.trim(),
      'm_mlcDate': _mMlcDateCtrl.text.trim(),
      'm_accusedName': _mAccusedNameCtrl.text.trim(),
      'm_age': _mAgeCtrl.text.trim(),
      'm_dob': _mDobCtrl.text.trim(),
      'm_religion': _mReligionCtrl.text.trim(),
      'm_marital': _mMaritalCtrl.text.trim(),
      'm_address': _mAddressCtrl.text.trim(),
      'm_policeName': _mPoliceNameCtrl.text.trim(),
      'm_buckle': _mBuckleCtrl.text.trim(),
      'm_ps': _mPsCtrl.text.trim(),
      'm_crNo': _mCrNoCtrl.text.trim(),
      'm_section': _mSectionCtrl.text.trim(),
      'm_consent': _mConsentCtrl.text.trim(),
      'm_idMark1': _mIdMark1Ctrl.text.trim(),
      'm_idMark2': _mIdMark2Ctrl.text.trim(),
      'm_examDateTime': _mExamDateTimeCtrl.text.trim(),
      'm_doctor': _mDoctorCtrl.text.trim(),
      'm_assaultHistory': _mAssaultHistoryCtrl.text.trim(),
      'm_witnessSig': _mWitnessSigCtrl.text.trim(),
      'm_accusedSig': _mAccusedSigCtrl.text.trim(),
      'm_medSurgicalHistory': _mMedSurgicalHistoryCtrl.text.trim(),
      'm_generalPhysical': _mGeneralPhysicalCtrl.text.trim(),
      'm_localExam': _mLocalExamCtrl.text.trim(),
      'm_systemicExam': _mSystemicExamCtrl.text.trim(),
      'm_additionalFindings': _mAdditionalFindingsCtrl.text.trim(),
      'm_labSamples': _mLabSamplesCtrl.text.trim(),
      'm_lab7Collected': _mLab7CollectedCtrl.text.trim(),
      'm_lab8Collected': _mLab8CollectedCtrl.text.trim(),
      'm_lab9Collected': _mLab9CollectedCtrl.text.trim(),
      'm_lab10Collected': _mLab10CollectedCtrl.text.trim(),
      'm_lab11Sample': _mLab11SampleCtrl.text.trim(),
      'm_lab11Test': _mLab11TestCtrl.text.trim(),
      'm_lab11Packing': _mLab11PackingCtrl.text.trim(),
      'm_lab11Collected': _mLab11CollectedCtrl.text.trim(),
      'm_fslNote': _mFslNoteCtrl.text.trim(),
      'm_opinionTimeElapsed': _mOpinionTimeElapsedCtrl.text.trim(),
      'm_provisionalOpinion': _mProvisionalOpinionCtrl.text.trim(),
      'm_opinionDate': _mOpinionDateCtrl.text.trim(),
      'm_reportPagesCount': _mReportPagesCountCtrl.text.trim(),
      'm_doctorSig': _mDoctorSigCtrl.text.trim(),
      'm_doctorName': _mDoctorNameCtrl.text.trim(),
      'm_doctorDeptDesig': _mDoctorDeptDesigCtrl.text.trim(),
      'm_receiptPolice': _mReceiptPoliceCtrl.text.trim(),
      'm_receiptPoliceName': _mReceiptPoliceNameCtrl.text.trim(),
      'm_receiptBuckleNo': _mReceiptBuckleNoCtrl.text.trim(),
      'm_receiptPs': _mReceiptPsCtrl.text.trim(),
    };
  }

  void hydrateFrom(Map<String, dynamic> data) {
    setState(() {
      void set(TextEditingController c, String key) {
        c.text = data[key]?.toString() ?? '';
      }

      set(_fHospitalCtrl, 'f_hospital');
      set(_fOpdCtrl, 'f_opd');
      set(_fInpatientCtrl, 'f_inpatient');
      set(_fNameCtrl, 'f_name');
      set(_fParentCtrl, 'f_parent');
      set(_fAddressCtrl, 'f_address');
      set(_fAgeCtrl, 'f_age');
      set(_fDobCtrl, 'f_dob');
      set(_fSexCtrl, 'f_sex');
      set(_fArrivalDtCtrl, 'f_arrival');
      set(_fExamStartCtrl, 'f_examStart');
      set(_fBroughtByCtrl, 'f_broughtBy');
      set(_fMlcCtrl, 'f_mlc');
      set(_fPsCtrl, 'f_ps');
      set(_fConsciousCtrl, 'f_conscious');
      set(_fDisabilityCtrl, 'f_disability');
      set(_fConsentCtrl, 'f_consent');
      set(_fConsentNameCtrl, 'f_consentName');
      set(_fConsentParentCtrl, 'f_consentParent');
      set(_fConsentTreatmentCtrl, 'f_consentTreatment');
      set(_fConsentMedicoLegalCtrl, 'f_consentMedicoLegal');
      set(_fConsentSampleCtrl, 'f_consentSample');
      set(_fConsentPoliceInfoCtrl, 'f_consentPoliceInfo');
      set(_fConsentLanguageCtrl, 'f_consentLanguage');
      set(_fConsentSupportRoleCtrl, 'f_consentSupportRole');
      set(_fConsentHelperSigCtrl, 'f_consentHelperSig');
      set(_fSurvivorSigCtrl, 'f_survivorSig');
      set(_fWitnessSigCtrl, 'f_witnessSig');
      set(_fIdMark1Ctrl, 'f_idMark1');
      set(_fIdMark2Ctrl, 'f_idMark2');
      set(_fMenarcheYesNoCtrl, 'f_menarcheYesNo');
      set(_fMenarcheAgeCtrl, 'f_menarcheAge');
      set(_fMenstrualCycleCtrl, 'f_menstrualCycle');
      set(_fLastMenstrualPeriodCtrl, 'f_lastMenstrualPeriod');
      set(_fMenstruationAtIncidentCtrl, 'f_menstruationAtIncident');
      set(_fMenstruationAtExamCtrl, 'f_menstruationAtExam');
      set(_fPregnantAtIncidentCtrl, 'f_pregnantAtIncident');
      set(_fPregnancyDurationCtrl, 'f_pregnancyDuration');
      set(_fContraceptionUseCtrl, 'f_contraceptionUse');
      set(_fContraceptionMethodCtrl, 'f_contraceptionMethod');
      set(_fVaccinationTetanusCtrl, 'f_vaccinationTetanus');
      set(_fVaccinationHepBCtrl, 'f_vaccinationHepB');
      set(_fMedHistoryCtrl, 'f_medHistory');
      set(_fViolenceHistoryCtrl, 'f_violenceHistory');
      set(_fIncidentDateCtrl, 'f_incidentDate');
      set(_fIncidentTimeCtrl, 'f_incidentTime');
      set(_fIncidentLocationCtrl, 'f_incidentLocation');
      set(_fEstimatedDurationCtrl, 'f_estimatedDuration');
      set(_fEpisodeCtrl, 'f_episode');
      set(_fAssailantCountAndNamesCtrl, 'f_assailantCountAndNames');
      set(_fAssailantSexCtrl, 'f_assailantSex');
      set(_fAssailantAgeCtrl, 'f_assailantAge');
      set(_fAssailantRelationshipCtrl, 'f_assailantRelationship');
      set(_fNarratorDetailsCtrl, 'f_narratorDetails');
      set(_fHitWithCtrl, 'f_hitWith');
      set(_fBurnedWithCtrl, 'f_burnedWith');
      set(_fBitingCtrl, 'f_biting');
      set(_fKickingCtrl, 'f_kicking');
      set(_fPinchingCtrl, 'f_pinching');
      set(_fPullingHairCtrl, 'f_pullingHair');
      set(_fViolentShakingCtrl, 'f_violentShaking');
      set(_fBangingHeadCtrl, 'f_bangingHead');
      set(_fPhysicalViolenceCtrl, 'f_physicalViolence');
      set(_fEmotionalAbuseCtrl, 'f_emotionalAbuse');
      set(_fSexualViolenceDetailCtrl, 'f_sexualViolenceDetail');
      set(_f15cEmotionalAbuseCtrl, 'f_15cEmotionalAbuse');
      set(_f15cRestraintsCtrl, 'f_15cRestraints');
      set(_f15cWeaponsCtrl, 'f_15cWeapons');
      set(_f15cVerbalThreatsCtrl, 'f_15cVerbalThreats');
      set(_f15cLuringCtrl, 'f_15cLuring');
      set(_f15cAnyOtherCtrl, 'f_15cAnyOther');
      set(_f15dIntoxicationCtrl, 'f_15dIntoxication');
      set(_f15dUnconsciousCtrl, 'f_15dUnconscious');
      set(_f15eAssailantInjuryCtrl, 'f_15eAssailantInjury');
      set(_fPenGenitaliaPenisCtrl, 'f_penGenitaliaPenis');
      set(_fPenGenitaliaBodyPartCtrl, 'f_penGenitaliaBodyPart');
      set(_fPenGenitaliaObjectCtrl, 'f_penGenitaliaObject');
      set(_fEmissionGenitaliaCtrl, 'f_emissionGenitalia');
      set(_fPenAnusPenisCtrl, 'f_penAnusPenis');
      set(_fPenAnusBodyPartCtrl, 'f_penAnusBodyPart');
      set(_fPenAnusObjectCtrl, 'f_penAnusObject');
      set(_fEmissionAnusCtrl, 'f_emissionAnus');
      set(_fPenMouthPenisCtrl, 'f_penMouthPenis');
      set(_fPenMouthBodyPartCtrl, 'f_penMouthBodyPart');
      set(_fPenMouthObjectCtrl, 'f_penMouthObject');
      set(_fEmissionMouthCtrl, 'f_emissionMouth');
      set(_fOralSexPerformedCtrl, 'f_oralSexPerformed');
      set(_fForcedMasturbationSelfCtrl, 'f_forcedMasturbationSelf');
      set(_fMasturbationAssailantCtrl, 'f_masturbationAssailant');
      set(_fExhibitionismCtrl, 'f_exhibitionism');
      set(_fEjaculationOutsideCtrl, 'f_ejaculationOutside');
      set(_fEjaculationWhereBodyCtrl, 'f_ejaculationWhereBody');
      set(_fKissingLickingSuckingCtrl, 'f_kissingLickingSucking');
      set(_fKissingLickingDescCtrl, 'f_kissingLickingDesc');
      set(_fTouchingFondlingCtrl, 'f_touchingFondling');
      set(_fTouchingFondlingDescCtrl, 'f_touchingFondlingDesc');
      set(_fCondomUsedCtrl, 'f_condomUsed');
      set(_fCondomStatusCtrl, 'f_condomStatus');
      set(_fLubricantUsedCtrl, 'f_lubricantUsed');
      set(_fLubricantKindDescCtrl, 'f_lubricantKindDesc');
      set(_fObjectUsedDescCtrl, 'f_objectUsedDesc');
      set(_fOtherSexualViolenceFormsCtrl, 'f_otherSexualViolenceForms');
      set(_fPostChangedClothesCtrl, 'f_postChangedClothes');
      set(_fPostChangedClothesRemCtrl, 'f_postChangedClothesRem');
      set(_fPostChangedUndergarmentsCtrl, 'f_postChangedUndergarments');
      set(_fPostChangedUndergarmentsRemCtrl, 'f_postChangedUndergarmentsRem');
      set(_fPostCleanedClothesCtrl, 'f_postCleanedClothes');
      set(_fPostCleanedClothesRemCtrl, 'f_postCleanedClothesRem');
      set(_fPostCleanedUndergarmentsCtrl, 'f_postCleanedUndergarments');
      set(_fPostCleanedUndergarmentsRemCtrl, 'f_postCleanedUndergarmentsRem');
      set(_fPostBathedCtrl, 'f_postBathed');
      set(_fPostBathedRemCtrl, 'f_postBathedRem');
      set(_fPostDouchedCtrl, 'f_postDouched');
      set(_fPostDouchedRemCtrl, 'f_postDouchedRem');
      set(_fPostPassedUrineCtrl, 'f_postPassedUrine');
      set(_fPostPassedUrineRemCtrl, 'f_postPassedUrineRem');
      set(_fPostPassedStoolsCtrl, 'f_postPassedStools');
      set(_fPostPassedStoolsRemCtrl, 'f_postPassedStoolsRem');
      set(_fPostRinsingMouthCtrl, 'f_postRinsingMouth');
      set(_fPostRinsingMouthRemCtrl, 'f_postRinsingMouthRem');
      set(_fTimeSinceIncidentCtrl, 'f_timeSinceIncident');
      set(_fBleedingPriorIncidentCtrl, 'f_bleedingPriorIncident');
      set(_fBleedingSinceIncidentCtrl, 'f_bleedingSinceIncident');
      set(_fPainSinceIncidentCtrl, 'f_painSinceIncident');
      set(_fExamIsFirstCtrl, 'f_examIsFirst');
      set(_fExamPulseCtrl, 'f_examPulse');
      set(_fExamBpCtrl, 'f_examBp');
      set(_fExamTempCtrl, 'f_examTemp');
      set(_fExamRespRateCtrl, 'f_examRespRate');
      set(_fExamPupilsCtrl, 'f_examPupils');
      set(_fExamGeneralWellbeingCtrl, 'f_examGeneralWellbeing');
      set(_fPostIncidentCtrl, 'f_postIncident');
      set(_fGeneralExamCtrl, 'f_generalExam');
      set(_fBodyFrontNotesCtrl, 'f_bodyFrontNotes');
      set(_fBodyBackNotesCtrl, 'f_bodyBackNotes');
      set(_fGenitalExamCtrl, 'f_genitalExam');
      set(_fSystemicExamCtrl, 'f_systemicExam');
      final genFindings = data['f_genitalPartFindings'];
      if (genFindings is List) {
        for (var i = 0;
            i < _fGenitalPartFindings.length && i < genFindings.length;
            i++) {
          _fGenitalPartFindings[i].text = genFindings[i]?.toString() ?? '';
        }
      }
      final genNotes = data['f_genitalPartNotes'];
      if (genNotes is List) {
        for (var i = 0;
            i < _fGenitalPartNotes.length && i < genNotes.length;
            i++) {
          _fGenitalPartNotes[i].text = genNotes[i]?.toString() ?? '';
        }
      }
      set(_fPsFindingsCtrl, 'f_psFindings');
      set(_fPvFindingsCtrl, 'f_pvFindings');
      set(_fPvPsReasonsCtrl, 'f_pvPsReasons');
      set(_fAnusRectumEncircledCtrl, 'f_anusRectumEncircled');
      set(_fAnusRectumNotesCtrl, 'f_anusRectumNotes');
      set(_fOralCavityEncircledCtrl, 'f_oralCavityEncircled');
      set(_fOralCavityNotesCtrl, 'f_oralCavityNotes');
      set(_fSysCnsCtrl, 'f_sysCns');
      set(_fSysCvsCtrl, 'f_sysCvs');
      set(_fSysRespCtrl, 'f_sysResp');
      set(_fSysChestCtrl, 'f_sysChest');
      set(_fSysAbdomenCtrl, 'f_sysAbdomen');
      set(_fSampleBloodHivCtrl, 'f_sampleBloodHiv');
      set(_fSampleUrinePregCtrl, 'f_sampleUrinePreg');
      set(_fSampleUsgCtrl, 'f_sampleUsg');
      set(_fSampleXrayCtrl, 'f_sampleXray');
      set(_fFslDebrisCtrl, 'f_fslDebris');
      set(_fClothingDetailsCtrl, 'f_clothingDetails');
      final fslCollected = data['f_fslSampleCollected'];
      if (fslCollected is List) {
        for (var i = 0;
            i < _fFslSampleCollected.length && i < fslCollected.length;
            i++) {
          _fFslSampleCollected[i].text = fslCollected[i]?.toString() ?? '';
        }
      }
      final fslReasons = data['f_fslSampleReasons'];
      if (fslReasons is List) {
        for (var i = 0;
            i < _fFslSampleReasons.length && i < fslReasons.length;
            i++) {
          _fFslSampleReasons[i].text = fslReasons[i]?.toString() ?? '';
        }
      }
      final genEvCollected = data['f_genitalEvidenceCollected'];
      if (genEvCollected is List) {
        for (var i = 0;
            i < _fGenitalEvidenceCollected.length && i < genEvCollected.length;
            i++) {
          _fGenitalEvidenceCollected[i].text =
              genEvCollected[i]?.toString() ?? '';
        }
      }
      final genEvReasons = data['f_genitalEvidenceReasons'];
      if (genEvReasons is List) {
        for (var i = 0;
            i < _fGenitalEvidenceReasons.length && i < genEvReasons.length;
            i++) {
          _fGenitalEvidenceReasons[i].text = genEvReasons[i]?.toString() ?? '';
        }
      }
      set(_fProvSurvivorNameCtrl, 'f_provSurvivorName');
      set(_fProvGenderCtrl, 'f_provGender');
      set(_fProvAgeCtrl, 'f_provAge');
      set(_fProvCircumstancesCtrl, 'f_provCircumstances');
      set(_fProvTimeAfterIncidentCtrl, 'f_provTimeAfterIncident');
      set(_fProvBathedDouchedCtrl, 'f_provBathedDouched');
      set(_fProvFslSamplesCtrl, 'f_provFslSamples');
      set(_fProvHospSamplesCtrl, 'f_provHospSamples');
      set(_fProvClinicalFindingsCtrl, 'f_provClinicalFindings');
      set(_fProvAdditionalObsCtrl, 'f_provAdditionalObs');
      set(_fGenitalDiagramNotesCtrl, 'f_genitalDiagramNotes');
      set(_fLabSamplesCtrl, 'f_labSamples');
      set(_fFslSamplesCtrl, 'f_fslSamples');
      set(_fGenitalEvidenceCtrl, 'f_genitalEvidence');
      set(_fProvisionalOpinionCtrl, 'f_provisionalOpinion');
      final trChoice = data['f_treatmentChoice'];
      if (trChoice is List) {
        for (var i = 0;
            i < _fTreatmentChoice.length && i < trChoice.length;
            i++) {
          _fTreatmentChoice[i].text = trChoice[i]?.toString() ?? '';
        }
      }
      final trComm = data['f_treatmentComments'];
      if (trComm is List) {
        for (var i = 0;
            i < _fTreatmentComments.length && i < trComm.length;
            i++) {
          _fTreatmentComments[i].text = trComm[i]?.toString() ?? '';
        }
      }
      set(_fCompletionDateTimeCtrl, 'f_completionDateTime');
      set(_fReportSheetsCountCtrl, 'f_reportSheetsCount');
      set(_fReportEnvelopesCountCtrl, 'f_reportEnvelopesCount');
      set(_fCompletionPlaceCtrl, 'f_completionPlace');
      set(_fDoctorNameCtrl, 'f_doctorName');
      set(_fDoctorSealCtrl, 'f_doctorSeal');
      set(_fFinalOpinionPersonCtrl, 'f_finalOpinionPerson');
      set(_fFinalOpinionTimeCtrl, 'f_finalOpinionTime');
      set(_fFinalOpinionTextCtrl, 'f_finalOpinionText');
      set(_fFinalOpinionPlaceCtrl, 'f_finalOpinionPlace');
      set(_fFinalDoctorNameCtrl, 'f_finalDoctorName');
      set(_fFinalDoctorSealCtrl, 'f_finalDoctorSeal');
      set(_fTreatmentCtrl, 'f_treatment');
      set(_fCompletionCtrl, 'f_completion');
      set(_fFinalOpinionCtrl, 'f_finalOpinion');

      final injuries = data['f_injuryRows'];
      if (injuries is List) {
        for (var i = 0; i < _fInjuryRows.length && i < injuries.length; i++) {
          _fInjuryRows[i].text = injuries[i]?.toString() ?? '';
        }
      }

      set(_mHospitalCtrl, 'm_hospital');
      set(_mOpdCtrl, 'm_opd');
      set(_mDateCtrl, 'm_date');
      set(_mMlcCtrl, 'm_mlc');
      set(_mMlcDateCtrl, 'm_mlcDate');
      set(_mAccusedNameCtrl, 'm_accusedName');
      set(_mAgeCtrl, 'm_age');
      set(_mDobCtrl, 'm_dob');
      set(_mReligionCtrl, 'm_religion');
      set(_mMaritalCtrl, 'm_marital');
      set(_mAddressCtrl, 'm_address');
      set(_mPoliceNameCtrl, 'm_policeName');
      set(_mBuckleCtrl, 'm_buckle');
      set(_mPsCtrl, 'm_ps');
      set(_mCrNoCtrl, 'm_crNo');
      set(_mSectionCtrl, 'm_section');
      set(_mConsentCtrl, 'm_consent');
      set(_mIdMark1Ctrl, 'm_idMark1');
      set(_mIdMark2Ctrl, 'm_idMark2');
      set(_mExamDateTimeCtrl, 'm_examDateTime');
      set(_mDoctorCtrl, 'm_doctor');
      set(_mAssaultHistoryCtrl, 'm_assaultHistory');
      set(_mWitnessSigCtrl, 'm_witnessSig');
      set(_mAccusedSigCtrl, 'm_accusedSig');
      set(_mMedSurgicalHistoryCtrl, 'm_medSurgicalHistory');
      set(_mGeneralPhysicalCtrl, 'm_generalPhysical');
      set(_mLocalExamCtrl, 'm_localExam');
      set(_mSystemicExamCtrl, 'm_systemicExam');
      set(_mAdditionalFindingsCtrl, 'm_additionalFindings');
      set(_mLabSamplesCtrl, 'm_labSamples');
      set(_mLab7CollectedCtrl, 'm_lab7Collected');
      set(_mLab8CollectedCtrl, 'm_lab8Collected');
      set(_mLab9CollectedCtrl, 'm_lab9Collected');
      set(_mLab10CollectedCtrl, 'm_lab10Collected');
      set(_mLab11SampleCtrl, 'm_lab11Sample');
      set(_mLab11TestCtrl, 'm_lab11Test');
      set(_mLab11PackingCtrl, 'm_lab11Packing');
      set(_mLab11CollectedCtrl, 'm_lab11Collected');
      set(_mFslNoteCtrl, 'm_fslNote');
      set(_mOpinionTimeElapsedCtrl, 'm_opinionTimeElapsed');
      set(_mProvisionalOpinionCtrl, 'm_provisionalOpinion');
      set(_mOpinionDateCtrl, 'm_opinionDate');
      set(_mReportPagesCountCtrl, 'm_reportPagesCount');
      set(_mDoctorSigCtrl, 'm_doctorSig');
      set(_mDoctorNameCtrl, 'm_doctorName');
      set(_mDoctorDeptDesigCtrl, 'm_doctorDeptDesig');
      set(_mReceiptPoliceCtrl, 'm_receiptPolice');
      set(_mReceiptPoliceNameCtrl, 'm_receiptPoliceName');
      set(_mReceiptBuckleNoCtrl, 'm_receiptBuckleNo');
      set(_mReceiptPsCtrl, 'm_receiptPs');
    });
  }

  Widget _bilingualSection(
      String en, String mr, TextStyle serif, TextStyle marathi) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: BilingualSectionHeader(
        label: en,
        marathiLabel: mr,
        serifStyle: serif.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
        marathiLabelStyle: marathi,
      ),
    );
  }

  Widget _buildNoteBullet(
    String en,
    String mr,
    TextStyle style,
    TextStyle marathi,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• ',
            style: style.copyWith(fontSize: 11, fontWeight: FontWeight.bold)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(en, style: style.copyWith(fontSize: 10, height: 1.35)),
              const SizedBox(height: 2),
              Text(mr, style: marathi.copyWith(fontSize: 9, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConsentYesNoRow({
    required String labelEn,
    required String labelMr,
    required TextEditingController controller,
    required TextStyle serifStyle,
    required TextStyle marathiStyle,
  }) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        final val = controller.text.trim().toLowerCase();
        final isYes = val == 'yes';
        final isNo = val == 'no';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(labelEn, style: serifStyle.copyWith(fontSize: 12)),
                    if (labelMr.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(labelMr, style: marathiStyle.copyWith(fontSize: 10)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: widget.readOnly
                    ? null
                    : () {
                        setState(() {
                          controller.text = isYes ? '' : 'Yes';
                        });
                        setLocalState(() {});
                      },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Yes',
                        style: serifStyle.copyWith(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isYes ? Colors.blue.shade900 : Colors.black87,
                          width: 1.3,
                        ),
                        color: Colors.transparent,
                      ),
                      padding: const EdgeInsets.all(2.5),
                      child: isYes
                          ? Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.shade900,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: widget.readOnly
                    ? null
                    : () {
                        setState(() {
                          controller.text = isNo ? '' : 'No';
                        });
                        setLocalState(() {});
                      },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('No',
                        style: serifStyle.copyWith(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isNo ? Colors.blue.shade900 : Colors.black87,
                          width: 1.3,
                        ),
                        color: Colors.transparent,
                      ),
                      padding: const EdgeInsets.all(2.5),
                      child: isNo
                          ? Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.shade900,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInlineYesNo(
      TextEditingController controller, TextStyle serifStyle) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        final val = controller.text.trim().toLowerCase();
        final isYes = val == 'yes';
        final isNo = val == 'no';

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: widget.readOnly
                  ? null
                  : () {
                      setState(() {
                        controller.text = isYes ? '' : 'Yes';
                      });
                      setLocalState(() {});
                    },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Yes',
                      style: serifStyle.copyWith(
                          fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 3),
                  Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isYes ? Colors.blue.shade900 : Colors.black87,
                        width: 1.2,
                      ),
                      color: Colors.transparent,
                    ),
                    padding: const EdgeInsets.all(2.5),
                    child: isYes
                        ? Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.shade900,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: widget.readOnly
                  ? null
                  : () {
                      setState(() {
                        controller.text = isNo ? '' : 'No';
                      });
                      setLocalState(() {});
                    },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('No',
                      style: serifStyle.copyWith(
                          fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 3),
                  Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isNo ? Colors.blue.shade900 : Colors.black87,
                        width: 1.2,
                      ),
                      color: Colors.transparent,
                    ),
                    padding: const EdgeInsets.all(2.5),
                    child: isNo
                        ? Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.shade900,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCheckOption({
    required String label,
    required TextEditingController controller,
    required TextStyle serifStyle,
  }) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        final isSelected =
            controller.text.trim().toLowerCase() == label.trim().toLowerCase();

        return InkWell(
          onTap: widget.readOnly
              ? null
              : () {
                  setState(() {
                    controller.text = isSelected ? '' : label;
                  });
                  setLocalState(() {});
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: serifStyle.copyWith(fontSize: 11)),
                const SizedBox(width: 4),
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.blue.shade900 : Colors.black87,
                      width: 1.2,
                    ),
                    color: Colors.transparent,
                  ),
                  padding: const EdgeInsets.all(2.5),
                  child: isSelected
                      ? Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.shade900,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhysicalViolenceItem({
    required String labelEn,
    required TextEditingController controller,
    required TextStyle serifStyle,
  }) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        final isChecked = controller.text.isNotEmpty;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                onTap: widget.readOnly
                    ? null
                    : () {
                        setState(() {
                          controller.text = isChecked ? '' : 'Yes';
                        });
                        setLocalState(() {});
                      },
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black87, width: 1.2),
                    borderRadius: BorderRadius.circular(2),
                    color:
                        isChecked ? Colors.blue.shade900 : Colors.transparent,
                  ),
                  child: isChecked
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  labelEn,
                  style: serifStyle.copyWith(
                    fontSize: 11,
                    fontWeight: isChecked ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildYNCell({
    required String code,
    required TextEditingController controller,
    required TextStyle serifStyle,
  }) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        final isSelected =
            controller.text.trim().toUpperCase() == code.toUpperCase();

        return InkWell(
          onTap: widget.readOnly
              ? null
              : () {
                  setState(() {
                    controller.text = isSelected ? '' : code;
                  });
                  setLocalState(() {});
                },
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
            color: isSelected ? Colors.blue.shade50 : Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(code,
                    style: serifStyle.copyWith(
                        fontSize: 10,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal)),
                const SizedBox(width: 3),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.blue.shade900 : Colors.black87,
                      width: 1.3,
                    ),
                    color: Colors.transparent,
                  ),
                  padding: const EdgeInsets.all(2.5),
                  child: isSelected
                      ? Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.shade900,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildYNDNKSelector({
    required TextEditingController controller,
    required TextStyle serifStyle,
  }) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        final val = controller.text.trim().toUpperCase();

        Widget opt(String code) {
          final isSelected = val == code;
          return InkWell(
            onTap: widget.readOnly
                ? null
                : () {
                    setState(() {
                      controller.text = isSelected ? '' : code;
                    });
                    setLocalState(() {});
                  },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    code,
                    style: serifStyle.copyWith(
                      fontSize: 9.5,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isSelected ? Colors.blue.shade900 : Colors.black87,
                        width: 1.2,
                      ),
                      color: Colors.transparent,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: isSelected
                        ? Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.shade900,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 1.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              opt('Y'),
              const SizedBox(width: 3),
              opt('N'),
              const SizedBox(width: 3),
              opt('DNK'),
            ],
          ),
        );
      },
    );
  }

  TableRow _buildPostIncidentRow({
    required String label,
    required TextEditingController choiceCtrl,
    required TextEditingController remarksCtrl,
    required TextStyle serifStyle,
  }) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(6.0),
          child: Text(label, style: serifStyle.copyWith(fontSize: 10.5)),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: _buildYNDNKSelector(
            controller: choiceCtrl,
            serifStyle: serifStyle,
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: BilingualSimpleUnderlineInput(
              controller: remarksCtrl,
              serifStyle: serifStyle,
              hintText: 'Remarks',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEncircleOptions({
    required List<String> options,
    required TextEditingController controller,
    required TextStyle serifStyle,
  }) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        final currentTokens = controller.text
            .split(',')
            .map((s) => s.trim().toLowerCase())
            .where((s) => s.isNotEmpty)
            .toSet();

        return Wrap(
          spacing: 8,
          runSpacing: 4,
          children: options.map((opt) {
            final isSelected = currentTokens.contains(opt.toLowerCase());
            return InkWell(
              onTap: widget.readOnly
                  ? null
                  : () {
                      if (isSelected) {
                        currentTokens.remove(opt.toLowerCase());
                      } else {
                        currentTokens.add(opt.toLowerCase());
                      }
                      setState(() {
                        controller.text = currentTokens.join(', ');
                      });
                      setLocalState(() {});
                    },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? Colors.blue.shade900
                        : Colors.grey.shade400,
                    width: isSelected ? 1.6 : 1.0,
                  ),
                  color: isSelected ? Colors.blue.shade50 : Colors.transparent,
                ),
                child: Text(
                  opt,
                  style: serifStyle.copyWith(
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.blue.shade900 : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCollectedToggle({
    required TextEditingController controller,
    required TextStyle serifStyle,
  }) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        final val = controller.text.trim().toLowerCase();
        final isCollected = val == 'collected';
        final isNotCollected = val == 'not collected';

        Widget btn(String label, String code, bool isSel) {
          return InkWell(
            onTap: widget.readOnly
                ? null
                : () {
                    setState(() {
                      controller.text = isSel ? '' : code;
                    });
                    setLocalState(() {});
                  },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: serifStyle.copyWith(
                    fontSize: 9.5,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    color: isSel ? Colors.blue.shade900 : Colors.black87,
                  ),
                ),
                const SizedBox(width: 3),
                Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSel ? Colors.blue.shade900 : Colors.black87,
                      width: 1.2,
                    ),
                    color: Colors.transparent,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: isSel
                      ? Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.shade900,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              btn('Collected', 'Collected', isCollected),
              const SizedBox(height: 3),
              btn('Not Collected', 'Not Collected', isNotCollected),
            ],
          ),
        );
      },
    );
  }

  TableCell _buildTableRadioCell({
    required String code,
    required TextEditingController controller,
    required TextStyle serifStyle,
  }) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: StatefulBuilder(
        builder: (context, setLocalState) {
          final isSelected =
              controller.text.trim().toLowerCase() == code.toLowerCase();
          return Center(
            child: InkWell(
              onTap: widget.readOnly
                  ? null
                  : () {
                      setState(() {
                        controller.text = isSelected ? '' : code;
                      });
                      setLocalState(() {});
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.blue.shade900 : Colors.black87,
                      width: 1.3,
                    ),
                    color: Colors.transparent,
                  ),
                  padding: const EdgeInsets.all(2.5),
                  child: isSelected
                      ? Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.shade900,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _bilingualField(
    String labelEn,
    String labelMr,
    TextEditingController controller,
    TextStyle serif,
    TextStyle marathi, {
    int minLines = 1,
  }) {
    if (minLines > 1) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: BilingualMultilineField(
          label: labelEn,
          marathiLabel: labelMr,
          controller: controller,
          minLines: minLines,
          serifStyle: serif,
          marathiLabelStyle: marathi,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BilingualField(
        label: labelEn,
        marathiLabel: labelMr,
        controller: controller,
        serifStyle: serif,
        marathiLabelStyle: marathi,
      ),
    );
  }

  Widget _buildTableTextCell(
    String text,
    TextStyle style, {
    bool bold = false,
    TextAlign align = TextAlign.start,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: Text(
        text,
        textAlign: align,
        style: style.copyWith(
          fontSize: 11,
          fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTableInputCell(
    TextEditingController controller,
    TextStyle style, {
    String? hintText,
    TextAlign align = TextAlign.start,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
      child: TextField(
        controller: controller,
        textAlign: align,
        style: style.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade900,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 6.0),
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: style.copyWith(
            color: Colors.grey.shade400,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildMaleSectionVIII(TextStyle style, TextStyle marathi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'VIII) Sample collection for Hospital/ Clinical Laboratory: Samples can be taken according to requirement of a case advice investigations/ test according to case presentations & signs:',
          style: style.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '८) रुग्णालय / क्लिनिकल प्रयोगशाळेसाठी नमुने गोळा करणे: प्रकरणाच्या आवश्यकतेनुसार नमुने घेतले जाऊ शकतात / प्रकरणातील लक्षणे व चिन्हांनुसार चाचण्यांचा सल्ला दिला जातो:',
          style: marathi.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 8),
        Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder.all(color: Colors.black87, width: 1.0),
          columnWidths: const {
            0: FixedColumnWidth(48),
            1: FlexColumnWidth(2.6),
            2: FlexColumnWidth(2.8),
            3: FlexColumnWidth(2.2),
            4: FixedColumnWidth(95),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade100),
              children: [
                _buildTableTextCell('Sr No', style,
                    bold: true, align: TextAlign.center),
                _buildTableTextCell('Sample name', style, bold: true),
                _buildTableTextCell('Test for', style, bold: true),
                _buildTableTextCell('Preservative/\nPacking', style,
                    bold: true),
                _buildTableTextCell('Collected?\nYes/No', style,
                    bold: true, align: TextAlign.center),
              ],
            ),
            TableRow(
              children: [
                _buildTableTextCell('7', style,
                    bold: true, align: TextAlign.center),
                _buildTableTextCell('Urethral Swab', style),
                _buildTableTextCell('Microscopy & Culture', style),
                _buildTableTextCell('Plain Sterile Bulb', style),
                _buildTableInputCell(_mLab7CollectedCtrl, style,
                    hintText: 'Yes / No', align: TextAlign.center),
              ],
            ),
            TableRow(
              children: [
                _buildTableTextCell('8', style,
                    bold: true, align: TextAlign.center),
                _buildTableTextCell(
                    'Swab (Sterile Cotton) from discharge', style),
                _buildTableTextCell('Microscopy & Culture', style),
                _buildTableTextCell('Plain Sterile Bulb', style),
                _buildTableInputCell(_mLab8CollectedCtrl, style,
                    hintText: 'Yes / No', align: TextAlign.center),
              ],
            ),
            TableRow(
              children: [
                _buildTableTextCell('9', style,
                    bold: true, align: TextAlign.center),
                _buildTableTextCell('Blood', style),
                _buildTableTextCell(
                    'Serology (for syphilis, HIV & Hepatitis B)', style),
                _buildTableTextCell('Plain Sterile Bulb', style),
                _buildTableInputCell(_mLab9CollectedCtrl, style,
                    hintText: 'Yes / No', align: TextAlign.center),
              ],
            ),
            TableRow(
              children: [
                _buildTableTextCell('10', style,
                    bold: true, align: TextAlign.center),
                _buildTableTextCell('Urine (midstream)', style),
                _buildTableTextCell('Microscopy & Culture', style),
                _buildTableTextCell('Plain Sterile Bulb', style),
                _buildTableInputCell(_mLab10CollectedCtrl, style,
                    hintText: 'Yes / No', align: TextAlign.center),
              ],
            ),
            TableRow(
              children: [
                _buildTableTextCell('11', style,
                    bold: true, align: TextAlign.center),
                _buildTableInputCell(_mLab11SampleCtrl, style,
                    hintText: 'Sample name...'),
                _buildTableInputCell(_mLab11TestCtrl, style,
                    hintText: 'Test for...'),
                _buildTableInputCell(_mLab11PackingCtrl, style,
                    hintText: 'Preservative...'),
                _buildTableInputCell(_mLab11CollectedCtrl, style,
                    hintText: 'Yes / No', align: TextAlign.center),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  static const _femaleInjuryLabels = [
    (
      'Scalp examination for areas of tenderness\n(if hair pulled out/ dragged by hair)',
      'टाळू — संवेदनशीलता तपासणी (केस उपटले/ओढले असल्यास)'
    ),
    (
      'Facial bone injury: orbital blackening, tenderness',
      'चेहऱ्याच्या हाडांवर जखम: डोळ्याभोवती काळे पडणे, संवेदनशीलता'
    ),
    (
      'Petechial haemorrhage in eyes and other places',
      'डोळ्यांमध्ये व इतर ठिकाणी पेटेकियल रक्तस्त्राव'
    ),
    ('Lips and Buccal Mucosa / Gums', 'ओठ व गालाची आतली बाजू / दात-हिरड्या'),
    ('Behind the ears', 'कानामागे'),
    ('Ear drum', 'कानाचे पडदे'),
    ('Neck, Shoulders and Breast', 'मान, खांदे व स्तन'),
    ('Upper limb', 'वरचे अवयव / हात'),
    ('Inner aspect of upper arms', 'वरच्या हाताच्या आतील बाजू'),
    ('Inner aspect of thighs', 'मांड्यांच्या आतील बाजू'),
    ('Lower limb / Buttocks', 'खालचे अवयव / पाय / नितंब'),
    ('Other, please specify', 'इतर (कृपया नमूद करा)'),
  ];

  static const _femaleGenitalPartLabels = [
    'Urethral meatus & vestibule',
    'Labia majora',
    'Labia minora',
    'Fourchette & Introitus',
    'Hymen Perineum',
    'External Urethral Meatus',
    'Penis',
    'Scrotum',
    'Testes',
    'Clitoropenis',
    'Labioscrotum',
    'Any Other',
  ];

  static const _femaleFslSampleLabels = [
    'Swabs from Stains on the body (blood, semen, foreign material, others)',
    'Scalp hair (10-15 strands)',
    'Head hair combing',
    'Nail scrapings (both hands separately)',
    'Nail clippings (both hands separately)',
    'Oral swab',
    'Blood for grouping, testing drug/alcohol intoxication (plain vial)',
    'Blood for alcohol levels (Sodium fluoride vial)',
    'Blood for DNA analysis (EDTA vial)',
    'Urine (drug testing)',
    'Any other (tampon/sanitary napkin/condom/object)',
  ];

  static const _femaleGenitalEvidenceLabels = [
    'Matted pubic hair',
    'Pubic hair combing (mention if shaved)',
    'Cutting of pubic hair (mention if shaved)',
    'Two Vulval swabs (for semen examination and DNA testing)',
    'Two Vaginal swabs (for semen examination and DNA testing)',
    'Two Anal swabs (for semen examination and DNA testing)',
    'Vaginal smear (air-dried) for semen examination',
    'Vaginal washing',
    'Urethral swab',
    'Swab from glans of penis/clitoropenis',
  ];

  static const _femaleTreatmentLabels = [
    'STI prevention treatment',
    'Emergency contraception',
    'Wound treatment',
    'Tetanus prophylaxis',
    'Hepatitis B vaccination',
    'Post exposure prophylaxis for HIV',
    'Counselling',
    'Other',
  ];

  Widget _buildFemalePages(TextStyle style, TextStyle marathi) {
    return Column(
      children: [
        FormPaperPage(
          formLabel: 'Pages 1–2 / पृ. १–२',
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black54),
              ),
              child: Text(
                'महाराष्ट्र शासन — सार्वजनिक आरोग्य विभाग. परिपत्रक क्रमांक: संकीर्ण-२०१४/प्र.क्र.२७०/आरोग्य-३. '
                'दिनांक: ०७ ऑगस्ट, २०१५.',
                style:
                    GoogleFonts.notoSansDevanagari(fontSize: 9, height: 1.35),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('CONFIDENTIAL',
                      style: style.copyWith(fontWeight: FontWeight.bold)),
                  Text('गोपनीय',
                      style: marathi.copyWith(
                          fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Column(
                children: [
                  Text(
                    'Medico-legal Examination Report of Sexual Violence',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lora(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  Text(
                    'लैंगिक हिंसाचाराचा वैद्यकीय-कायदेशीर तपासणी अहवाल',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansDevanagari(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _bilingualSection('1–11. Basic Information', '१–११. मूलभूत माहिती',
                style, marathi),
            BilingualFieldRow(fields: [
              _bilingualField('1. Hospital', '१. रुग्णालयाचे नाव',
                  _fHospitalCtrl, style, marathi),
              _bilingualField(
                  'OPD No.', 'बाह्य रुग्ण क्र.', _fOpdCtrl, style, marathi),
            ]),
            _bilingualField('Inpatient No.', 'अंतर्गत रुग्ण क्र.',
                _fInpatientCtrl, style, marathi),
            _bilingualField('2. Name', '२. नाव', _fNameCtrl, style, marathi),
            _bilingualField('D/o or S/o (where known)',
                'मुलगी / मुलगा (माहित असल्यास)', _fParentCtrl, style, marathi),
            _bilingualField(
                '3. Address', '३. पत्ता', _fAddressCtrl, style, marathi,
                minLines: 2),
            BilingualFieldRow(fields: [
              _bilingualField('4. Age (as reported)', '४. वय (सांगितले)',
                  _fAgeCtrl, style, marathi),
              _bilingualField(
                  'Date of Birth', 'जन्मतारीख', _fDobCtrl, style, marathi),
            ]),
            _bilingualField('5. Sex (M/F/Others)', '५. लिंग (पु/स्त्री/इ.)',
                _fSexCtrl, style, marathi),
            _bilingualField(
                '6. Date and Time of arrival',
                '६. रुग्णालयात आगमन दिनांक व वेळ',
                _fArrivalDtCtrl,
                style,
                marathi),
            _bilingualField('7. Date and Time of commencement of examination',
                '७. तपासणी सुरू दिनांक व वेळ', _fExamStartCtrl, style, marathi),
            _bilingualField('8. Brought by (Name & signatures)',
                '८. कोणी आणले (नाव व सही)', _fBroughtByCtrl, style, marathi),
            BilingualFieldRow(fields: [
              _bilingualField(
                  '9. MLC No.', '९. एम.एल.सी. क्र.', _fMlcCtrl, style, marathi),
              _bilingualField(
                  'Police Station', 'पोलीस ठाणे', _fPsCtrl, style, marathi),
            ]),
            _bilingualField(
              '10. Whether conscious, oriented in time and place and person',
              '१०. जागरूक, वेळ/ठिकाण/व्यक्ती ओळखणारी आहे का',
              _fConsciousCtrl,
              style,
              marathi,
            ),
            _bilingualField(
              '11. Any physical/intellectual/psychosocial disability',
              '११. शारीरिक / बौद्धिक / मानसिक अपंगत्व',
              _fDisabilityCtrl,
              style,
              marathi,
              minLines: 2,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '(Interpreters or special educators will be needed where the survivor has special needs such as hearing/speech disability, language barriers, intellectual or psychosocial disability.)',
                style: style.copyWith(fontSize: 9, fontStyle: FontStyle.italic),
              ),
            ),
            Text(
              '(श्रवण/वाक् अपंगत्व, भाषा अडथळा, बौद्धिक/मानसिक अपंगत्व असल्यास दुभाषी / विशेष शिक्षक आवश्यक.)',
              style: marathi.copyWith(fontSize: 9),
            ),
            _bilingualSection('12. Informed Consent/refusal',
                '१२. माहितीपूर्ण संमती / नकार', style, marathi),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('I ',
                    style: style.copyWith(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                Expanded(
                  flex: 5,
                  child: BilingualSimpleUnderlineInput(
                    controller: _fConsentNameCtrl,
                    serifStyle: style,
                    hintText: 'Name of survivor',
                  ),
                ),
                const SizedBox(width: 8),
                Text(' D/o or S/o ',
                    style: style.copyWith(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                Expanded(
                  flex: 5,
                  child: BilingualSimpleUnderlineInput(
                    controller: _fConsentParentCtrl,
                    serifStyle: style,
                    hintText: 'Father / Mother / Guardian name',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'मी ... मुलगी किंवा मुलगा ... यांची',
              style: marathi.copyWith(fontSize: 10),
            ),
            const SizedBox(height: 6),
            Text(
              'hereby give my consent for / येथे खालील बाबींसाठी संमती देतो/देते:',
              style: style.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildConsentYesNoRow(
              labelEn: 'a)  medical examination for treatment',
              labelMr: 'अ)  उपचारासाठी वैद्यकीय तपासणी',
              controller: _fConsentTreatmentCtrl,
              serifStyle: style,
              marathiStyle: marathi,
            ),
            _buildConsentYesNoRow(
              labelEn: 'b)  this medico legal examination',
              labelMr: 'ब)  ही वैद्यकीय-कायदेशीर तपासणी',
              controller: _fConsentMedicoLegalCtrl,
              serifStyle: style,
              marathiStyle: marathi,
            ),
            _buildConsentYesNoRow(
              labelEn:
                  'c)  sample collection for clinical & forensic examination',
              labelMr: 'क)  नैदानिक व फॉरेन्सिक नमुने गोळा करणे',
              controller: _fConsentSampleCtrl,
              serifStyle: style,
              marathiStyle: marathi,
            ),
            const SizedBox(height: 10),
            Text(
              'I also understand that as per law the hospital is required to inform police and this has been explained to me.',
              style: style.copyWith(fontSize: 11, height: 1.35),
            ),
            const SizedBox(height: 2),
            Text(
              'कायद्यानुसार रुग्णालयाने पोलिसांना कळवणे आवश्यक आहे आणि हे मला समजावून सांगितले आहे हे मला समजते.',
              style: marathi.copyWith(fontSize: 10, height: 1.35),
            ),
            const SizedBox(height: 8),
            _buildConsentYesNoRow(
              labelEn: 'I want the information to be revealed to the police',
              labelMr: 'माहिती पोलिसांना दिली जावी अशी माझी इच्छा आहे',
              controller: _fConsentPoliceInfoCtrl,
              serifStyle: style,
              marathiStyle: marathi,
            ),
            const SizedBox(height: 10),
            Text(
              'I have understood the purpose and the procedure of the examination including the risk and benefit, explained to me by the examining doctor. My right to refuse the examination at any stage and the consequence of such refusal, including that my medical treatment will not be affected by my refusal, has also been explained and may be recorded.',
              style: style.copyWith(fontSize: 11, height: 1.35),
            ),
            const SizedBox(height: 2),
            Text(
              'तपासणीचा उद्देश, कार्यपद्धती, धोके आणि फायदे तपासणी करणाऱ्या डॉक्टरांनी मला समजावून सांगितले असून ते मला समजले आहेत. कोणत्याही टप्प्यावर तपासणी नाकारण्याचा माझा अधिकार आणि अशा नकाराचा परिणाम, ज्यामध्ये माझ्या वैद्यकीय उपचारांवर परिणाम होणार नाही, हे देखील मला समजावून सांगितले आहे.',
              style: marathi.copyWith(fontSize: 10, height: 1.35),
            ),
            const SizedBox(height: 6),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Contents of the above have been explained to me in ',
                  style: style.copyWith(fontSize: 11),
                ),
                SizedBox(
                  width: 140,
                  child: BilingualSimpleUnderlineInput(
                    controller: _fConsentLanguageCtrl,
                    serifStyle: style,
                    hintText: 'e.g. Marathi / Hindi',
                  ),
                ),
                Text(
                  ' language with the help of a special educator/interpreter/support person (circle as appropriate) ',
                  style: style.copyWith(fontSize: 11),
                ),
                SizedBox(
                  width: 160,
                  child: BilingualSimpleUnderlineInput(
                    controller: _fConsentSupportRoleCtrl,
                    serifStyle: style,
                    hintText: 'Role / Person details',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'वरील मजकूर मला विशेष शिक्षक / दुभाषी / मदतनीस यांच्या मदतीने वरील भाषेत समजावून सांगितला गेला आहे.',
              style: marathi.copyWith(fontSize: 10),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'If special educator/interpreter/support person has helped, then his/her name and signature:',
                        style: style.copyWith(
                            fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'विशेष शिक्षक/दुभाषी/मदतनीस यांनी मदत केली असल्यास त्यांचे नाव व सही:',
                        style: marathi.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: BilingualSimpleUnderlineInput(
                    controller: _fConsentHelperSigCtrl,
                    serifStyle: style,
                    hintText: 'Name & Signature',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _bilingualSection(
              'Name & signature of survivor or parent/Guardian/person in whom the child reposes trust in case of child (<12 yrs)',
              'पीडित किंवा पालक/पाल्य (<१२ वर्षे असल्यास ज्या व्यक्तीवर विश्वास आहे) यांचे नाव व सही',
              style,
              marathi,
            ),
            BilingualDynamicLinedTextField(
              controller: _fSurvivorSigCtrl,
              minLines: 3,
              serifStyle: style,
            ),
            const SizedBox(height: 2),
            Text(
              'With date, time & place / दिनांक, वेळ आणि ठिकाणासह',
              style: style.copyWith(fontSize: 10, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),
            _bilingualSection(
              'Name & signature/thumb impression of Witness',
              'साक्षीदाराचे नाव आणि सही / अंगठ्याचा ठसा',
              style,
              marathi,
            ),
            BilingualDynamicLinedTextField(
              controller: _fWitnessSigCtrl,
              minLines: 3,
              serifStyle: style,
            ),
            const SizedBox(height: 2),
            Text(
              'With Date, time and place / दिनांक, वेळ आणि ठिकाणासह',
              style: style.copyWith(fontSize: 10, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            _bilingualSection(
              '13. Marks of identification (Any scar/mole)',
              '१३. ओळखीच्या खुणा (कोणताही व्रण/तीळ)',
              style,
              marathi,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 7,
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('(1) ',
                              style: style.copyWith(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: BilingualSimpleUnderlineInput(
                              controller: _fIdMark1Ctrl,
                              serifStyle: style,
                              hintText: 'First identification mark',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('(2) ',
                              style: style.copyWith(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: BilingualSimpleUnderlineInput(
                              controller: _fIdMark2Ctrl,
                              serifStyle: style,
                              hintText: 'Second identification mark',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Column(
                  children: [
                    Container(
                      width: 140,
                      height: 70,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black87, width: 1.0),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Left Thumb impression',
                      style: style.copyWith(
                          fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'डाव्या हाताचा अंगठ्याचा ठसा',
                      style: marathi.copyWith(fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _bilingualSection(
              '14. Relevant Medical/Surgical history',
              '१४. संबंधित वैद्यकीय / शस्त्रक्रिया इतिहास',
              style,
              marathi,
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black87, width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Onset of menarche (in case of girls)  ',
                        style: style.copyWith(fontSize: 11),
                      ),
                      _buildInlineYesNo(_fMenarcheYesNoCtrl, style),
                      const SizedBox(width: 24),
                      Text('  Age of onset: ',
                          style: style.copyWith(fontSize: 11)),
                      SizedBox(
                        width: 110,
                        child: BilingualSimpleUnderlineInput(
                          controller: _fMenarcheAgeCtrl,
                          serifStyle: style,
                          hintText: 'e.g. 13 years',
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.black26, height: 16),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Menstrual history – Cycle length and duration: ',
                        style: style.copyWith(fontSize: 11),
                      ),
                      SizedBox(
                        width: 130,
                        child: BilingualSimpleUnderlineInput(
                          controller: _fMenstrualCycleCtrl,
                          serifStyle: style,
                          hintText: 'e.g. 28 days / 4-5 days',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Last menstrual period (LMP): ',
                        style: style.copyWith(fontSize: 11),
                      ),
                      SizedBox(
                        width: 120,
                        child: BilingualSimpleUnderlineInput(
                          controller: _fLastMenstrualPeriodCtrl,
                          serifStyle: style,
                          hintText: 'DD/MM/YYYY',
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.black26, height: 16),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Menstruation at the time of incident - ',
                        style: style.copyWith(fontSize: 11),
                      ),
                      _buildInlineYesNo(_fMenstruationAtIncidentCtrl, style),
                      const SizedBox(width: 20),
                      Text(
                        'Menstruation at the time of examination - ',
                        style: style.copyWith(fontSize: 11),
                      ),
                      _buildInlineYesNo(_fMenstruationAtExamCtrl, style),
                    ],
                  ),
                  const Divider(color: Colors.black26, height: 16),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Was the survivor pregnant at time of incident - ',
                        style: style.copyWith(fontSize: 11),
                      ),
                      _buildInlineYesNo(_fPregnantAtIncidentCtrl, style),
                      const SizedBox(width: 16),
                      Text(
                        'If yes, duration of pregnancy: ',
                        style: style.copyWith(fontSize: 11),
                      ),
                      SizedBox(
                        width: 90,
                        child: BilingualSimpleUnderlineInput(
                          controller: _fPregnancyDurationCtrl,
                          serifStyle: style,
                          hintText: '... weeks',
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.black26, height: 16),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Contraception use: ',
                          style: style.copyWith(fontSize: 11)),
                      _buildInlineYesNo(_fContraceptionUseCtrl, style),
                      const SizedBox(width: 16),
                      Text('  If yes – method used: ',
                          style: style.copyWith(fontSize: 11)),
                      SizedBox(
                        width: 200,
                        child: BilingualSimpleUnderlineInput(
                          controller: _fContraceptionMethodCtrl,
                          serifStyle: style,
                          hintText: 'OCP / Copper-T / Barrier / etc.',
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.black26, height: 16),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Vaccination status – Tetanus: ',
                        style: style.copyWith(fontSize: 11),
                      ),
                      SizedBox(
                        width: 150,
                        child: BilingualSimpleUnderlineInput(
                          controller: _fVaccinationTetanusCtrl,
                          serifStyle: style,
                          hintText: 'Vaccinated / Not vaccinated',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Hepatitis B: ',
                        style: style.copyWith(fontSize: 11),
                      ),
                      SizedBox(
                        width: 150,
                        child: BilingualSimpleUnderlineInput(
                          controller: _fVaccinationHepBCtrl,
                          serifStyle: style,
                          hintText: 'Vaccinated / Not vaccinated',
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
        FormPaperPage(
          formLabel: 'Pages 3–5 / पृ. ३–५',
          children: [
            _bilingualSection('15 A. History of Sexual Violence',
                '१५ अ. लैंगिक हिंसाचाराचा इतिहास', style, marathi),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black87, width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Row 1: Date, Time, Location Table
                  Table(
                    border: const TableBorder(
                      verticalInside:
                          BorderSide(color: Colors.black87, width: 0.8),
                      bottom: BorderSide(color: Colors.black87, width: 0.8),
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade100),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text(
                              '(i) Date of incident/s being reported',
                              style: style.copyWith(
                                  fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text(
                              '(ii) Time of incident/s',
                              style: style.copyWith(
                                  fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text(
                              '(iii) Location/s',
                              style: style.copyWith(
                                  fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6.0, vertical: 4.0),
                            child: BilingualSimpleUnderlineInput(
                              controller: _fIncidentDateCtrl,
                              serifStyle: style,
                              hintText: 'DD/MM/YYYY',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6.0, vertical: 4.0),
                            child: BilingualSimpleUnderlineInput(
                              controller: _fIncidentTimeCtrl,
                              serifStyle: style,
                              hintText: 'HH:MM',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6.0, vertical: 4.0),
                            child: BilingualSimpleUnderlineInput(
                              controller: _fIncidentLocationCtrl,
                              serifStyle: style,
                              hintText: 'Location',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Row 2: Duration and Episode
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '(iv)Estimated duration : ',
                              style: style.copyWith(
                                  fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            _buildCheckOption(
                                label: '1-7 days',
                                controller: _fEstimatedDurationCtrl,
                                serifStyle: style),
                            _buildCheckOption(
                                label: '1 week to 2 months',
                                controller: _fEstimatedDurationCtrl,
                                serifStyle: style),
                            _buildCheckOption(
                                label: '2-6 months',
                                controller: _fEstimatedDurationCtrl,
                                serifStyle: style),
                            _buildCheckOption(
                                label: '>6 months',
                                controller: _fEstimatedDurationCtrl,
                                serifStyle: style),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Episode: ',
                              style: style.copyWith(
                                  fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            _buildCheckOption(
                                label: 'One',
                                controller: _fEpisodeCtrl,
                                serifStyle: style),
                            _buildCheckOption(
                                label: 'Multiple',
                                controller: _fEpisodeCtrl,
                                serifStyle: style),
                            _buildCheckOption(
                                label: 'Chronic (>6 months)',
                                controller: _fEpisodeCtrl,
                                serifStyle: style),
                            _buildCheckOption(
                                label: 'Unknown',
                                controller: _fEpisodeCtrl,
                                serifStyle: style),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                      color: Colors.black87, height: 1, thickness: 0.8),
                  // Row 3: Assailant details
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '(v) Number of Assailant(s) and name/s: ',
                              style: style.copyWith(fontSize: 11),
                            ),
                            Expanded(
                              child: BilingualSimpleUnderlineInput(
                                controller: _fAssailantCountAndNamesCtrl,
                                serifStyle: style,
                                hintText: 'Count & names',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '(vi) Sex of assailant(s): ',
                              style: style.copyWith(fontSize: 11),
                            ),
                            SizedBox(
                              width: 100,
                              child: BilingualSimpleUnderlineInput(
                                controller: _fAssailantSexCtrl,
                                serifStyle: style,
                                hintText: 'Sex',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Approx. Age of assailant(s): ',
                              style: style.copyWith(fontSize: 11),
                            ),
                            SizedBox(
                              width: 100,
                              child: BilingualSimpleUnderlineInput(
                                controller: _fAssailantAgeCtrl,
                                serifStyle: style,
                                hintText: 'Age',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'If known to the survivor – relationship with the survivor: ',
                              style: style.copyWith(fontSize: 11),
                            ),
                            Expanded(
                              child: BilingualSimpleUnderlineInput(
                                controller: _fAssailantRelationshipCtrl,
                                serifStyle: style,
                                hintText: 'Relationship',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                      color: Colors.black87, height: 1, thickness: 0.8),
                  // Row 4: Description of incident
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '(vii) Description of incident in the words of the narrator:',
                          style: style.copyWith(
                              fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Narrator of the incident: survivor/informant (specify name and relation to survivor): ',
                              style: style.copyWith(fontSize: 11),
                            ),
                            Expanded(
                              child: BilingualSimpleUnderlineInput(
                                controller: _fNarratorDetailsCtrl,
                                serifStyle: style,
                                hintText:
                                    'Survivor / Informant name & relation',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        BilingualDynamicLinedTextField(
                          controller: _fViolenceHistoryCtrl,
                          minLines: 8,
                          serifStyle: style,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'If this space is insufficient use extra page / ही जागा अपुरी असल्यास अतिरिक्त पान वापरा',
                          style: style.copyWith(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _bilingualSection(
              '15 B. Type of physical violence used if any (Describe):',
              '१५ ब. शारीरिक हिंसाचाराचा प्रकार (वर्णन करा):',
              style,
              marathi,
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black87, width: 1.0),
              ),
              child: Table(
                border: const TableBorder(
                  verticalInside: BorderSide(color: Colors.black54, width: 0.8),
                  horizontalInside:
                      BorderSide(color: Colors.black26, width: 0.5),
                ),
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    children: [
                      _buildPhysicalViolenceItem(
                        labelEn:
                            'Hit with (Hand, fist, blunt object, sharp object)',
                        controller: _fHitWithCtrl,
                        serifStyle: style,
                      ),
                      _buildPhysicalViolenceItem(
                        labelEn: 'Burned with',
                        controller: _fBurnedWithCtrl,
                        serifStyle: style,
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      _buildPhysicalViolenceItem(
                        labelEn: 'Biting',
                        controller: _fBitingCtrl,
                        serifStyle: style,
                      ),
                      _buildPhysicalViolenceItem(
                        labelEn: 'Kicking',
                        controller: _fKickingCtrl,
                        serifStyle: style,
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      _buildPhysicalViolenceItem(
                        labelEn: 'Pinching',
                        controller: _fPinchingCtrl,
                        serifStyle: style,
                      ),
                      _buildPhysicalViolenceItem(
                        labelEn: 'Pulling Hair',
                        controller: _fPullingHairCtrl,
                        serifStyle: style,
                      ),
                    ],
                  ),
                  TableRow(
                    children: [
                      _buildPhysicalViolenceItem(
                        labelEn: 'Violent shaking',
                        controller: _fViolentShakingCtrl,
                        serifStyle: style,
                      ),
                      _buildPhysicalViolenceItem(
                        labelEn: 'Banging head',
                        controller: _fBangingHeadCtrl,
                        serifStyle: style,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '15 C.',
              style: style.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        'i. Emotional abuse or violence if any (insulting, cursing, belittling, terrorizing):',
                        style: style.copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ),
                BilingualSimpleUnderlineInput(
                  controller: _f15cEmotionalAbuseCtrl,
                  serifStyle: style,
                  hintText: 'Details of emotional abuse or violence',
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('ii. Use of restraints if any: ',
                        style: style.copyWith(fontSize: 11)),
                    Expanded(
                      child: BilingualSimpleUnderlineInput(
                        controller: _f15cRestraintsCtrl,
                        serifStyle: style,
                        hintText: 'e.g. rope, cloth, handcuffs',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                        'iii. Used or threatened the use of weapon(s) or objects if any: ',
                        style: style.copyWith(fontSize: 11)),
                    Expanded(
                      child: BilingualSimpleUnderlineInput(
                        controller: _f15cWeaponsCtrl,
                        serifStyle: style,
                        hintText: 'Weapon / object details',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'iv. Verbal threats (for example, threats of killing or hurting survivor or any other person in whom the survivor is interested; use of photographs for blackmailing, etc.) if any:',
                      style: style.copyWith(fontSize: 11),
                    ),
                    BilingualSimpleUnderlineInput(
                      controller: _f15cVerbalThreatsCtrl,
                      serifStyle: style,
                      hintText: 'Verbal threats details',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('v. Luring (sweets, chocolates, money, job) if any: ',
                        style: style.copyWith(fontSize: 11)),
                    Expanded(
                      child: BilingualSimpleUnderlineInput(
                        controller: _f15cLuringCtrl,
                        serifStyle: style,
                        hintText: 'e.g. money, job, etc.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('vi. Any other: ',
                        style: style.copyWith(fontSize: 11)),
                    Expanded(
                      child: BilingualSimpleUnderlineInput(
                        controller: _f15cAnyOtherCtrl,
                        serifStyle: style,
                        hintText: 'Other details',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '15 D.',
              style: style.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('i. Any H/O drug/alcohol intoxication: ',
                    style: style.copyWith(fontSize: 11)),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _f15dIntoxicationCtrl,
                    serifStyle: style,
                    hintText: 'Yes/No & details',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                    'ii. Whether sleeping or unconscious at the time of the incident: ',
                    style: style.copyWith(fontSize: 11)),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _f15dUnconsciousCtrl,
                    serifStyle: style,
                    hintText: 'Yes/No & details',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '15 E.',
              style: style.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'If survivor has left any marks of injury on assailant/s, enter details: ',
                  style: style.copyWith(fontSize: 11),
                ),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _f15eAssailantInjuryCtrl,
                    serifStyle: style,
                    hintText:
                        'Injury marks on assailant (scratches, bites, etc.)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '15 F. Details regarding sexual violence:',
              style: style.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Was penetration by penis, fingers or object or other body parts (Write Y=Yes, N=No, DNK=Don’t know) Mention and describe body part/s and/or object/s used for penetration.',
              style: style.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            // Table 1: Penetration & Emission of Semen
            Table(
              border: TableBorder.all(color: Colors.black87, width: 0.8),
              columnWidths: const {
                0: FlexColumnWidth(1.6),
                1: FlexColumnWidth(1.1),
                2: FlexColumnWidth(2.0),
                3: FlexColumnWidth(1.1),
                4: FlexColumnWidth(0.8),
                5: FlexColumnWidth(0.8),
                6: FlexColumnWidth(1.1),
              },
              children: [
                // Header Row 1
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text('Orifice of Victim',
                          style: style.copyWith(
                              fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text('Penetration\nBy Penis',
                          textAlign: TextAlign.center,
                          style: style.copyWith(
                              fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                          'By body part of self / assailant / 3rd party',
                          textAlign: TextAlign.center,
                          style: style.copyWith(
                              fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text('Penetration\nBy Object',
                          textAlign: TextAlign.center,
                          style: style.copyWith(
                              fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text('Emission\nYes',
                          textAlign: TextAlign.center,
                          style: style.copyWith(
                              fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text('Emission\nNO',
                          textAlign: TextAlign.center,
                          style: style.copyWith(
                              fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text('Emission\nDon’t know',
                          textAlign: TextAlign.center,
                          style: style.copyWith(
                              fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                // Data Row 1: Genitalia
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text('Genitalia\n(Vagina and/or urethra)',
                          style: style.copyWith(
                              fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                    _buildYNDNKSelector(
                        controller: _fPenGenitaliaPenisCtrl, serifStyle: style),
                    _buildYNDNKSelector(
                        controller: _fPenGenitaliaBodyPartCtrl,
                        serifStyle: style),
                    _buildYNDNKSelector(
                        controller: _fPenGenitaliaObjectCtrl,
                        serifStyle: style),
                    _buildYNCell(
                        code: 'Yes',
                        controller: _fEmissionGenitaliaCtrl,
                        serifStyle: style),
                    _buildYNCell(
                        code: 'No',
                        controller: _fEmissionGenitaliaCtrl,
                        serifStyle: style),
                    _buildYNCell(
                        code: 'DNK',
                        controller: _fEmissionGenitaliaCtrl,
                        serifStyle: style),
                  ],
                ),
                // Data Row 2: Anus
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text('Anus',
                          style: style.copyWith(
                              fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                    _buildYNDNKSelector(
                        controller: _fPenAnusPenisCtrl, serifStyle: style),
                    _buildYNDNKSelector(
                        controller: _fPenAnusBodyPartCtrl, serifStyle: style),
                    _buildYNDNKSelector(
                        controller: _fPenAnusObjectCtrl, serifStyle: style),
                    _buildYNCell(
                        code: 'Yes',
                        controller: _fEmissionAnusCtrl,
                        serifStyle: style),
                    _buildYNCell(
                        code: 'No',
                        controller: _fEmissionAnusCtrl,
                        serifStyle: style),
                    _buildYNCell(
                        code: 'DNK',
                        controller: _fEmissionAnusCtrl,
                        serifStyle: style),
                  ],
                ),
                // Data Row 3: Mouth
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text('Mouth',
                          style: style.copyWith(
                              fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                    _buildYNDNKSelector(
                        controller: _fPenMouthPenisCtrl, serifStyle: style),
                    _buildYNDNKSelector(
                        controller: _fPenMouthBodyPartCtrl, serifStyle: style),
                    _buildYNDNKSelector(
                        controller: _fPenMouthObjectCtrl, serifStyle: style),
                    _buildYNCell(
                        code: 'Yes',
                        controller: _fEmissionMouthCtrl,
                        serifStyle: style),
                    _buildYNCell(
                        code: 'No',
                        controller: _fEmissionMouthCtrl,
                        serifStyle: style),
                    _buildYNCell(
                        code: 'DNK',
                        controller: _fEmissionMouthCtrl,
                        serifStyle: style),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Table 2: Activity / Question table
            Table(
              border: TableBorder.all(color: Colors.black87, width: 0.8),
              columnWidths: const {
                0: FlexColumnWidth(5.5),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(1.4),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text('Activity / Question',
                          style: style.copyWith(
                              fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text('Y',
                          textAlign: TextAlign.center,
                          style: style.copyWith(
                              fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text('N',
                          textAlign: TextAlign.center,
                          style: style.copyWith(
                              fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text('DNK',
                          textAlign: TextAlign.center,
                          style: style.copyWith(
                              fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text('Oral sex performed by assailant on survivor',
                          style: style.copyWith(fontSize: 10.5)),
                    ),
                    _buildYNCell(
                        code: 'Y',
                        controller: _fOralSexPerformedCtrl,
                        serifStyle: style),
                    _buildYNCell(
                        code: 'N',
                        controller: _fOralSexPerformedCtrl,
                        serifStyle: style),
                    _buildYNCell(
                        code: 'DNK',
                        controller: _fOralSexPerformedCtrl,
                        serifStyle: style),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text('Forced Masturbation of self by survivor',
                          style: style.copyWith(fontSize: 10.5)),
                    ),
                    _buildYNCell(
                        code: 'Y',
                        controller: _fForcedMasturbationSelfCtrl,
                        serifStyle: style),
                    _buildYNCell(
                        code: 'N',
                        controller: _fForcedMasturbationSelfCtrl,
                        serifStyle: style),
                    _buildYNCell(
                        code: 'DNK',
                        controller: _fForcedMasturbationSelfCtrl,
                        serifStyle: style),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                          'Masturbation of Assailant by Survivor,\nForced Manipulation of genitals of assailant by survivor',
                          style: style.copyWith(fontSize: 10.5)),
                    ),
                    _buildYNCell(
                        code: 'Y',
                        controller: _fMasturbationAssailantCtrl,
                        serifStyle: style),
                    _buildYNCell(
                        code: 'N',
                        controller: _fMasturbationAssailantCtrl,
                        serifStyle: style),
                    _buildYNCell(
                        code: 'DNK',
                        controller: _fMasturbationAssailantCtrl,
                        serifStyle: style),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                          'Exhibitionism (perpetrator displaying genitals)',
                          style: style.copyWith(fontSize: 10.5)),
                    ),
                    _buildYNCell(
                        code: 'Y',
                        controller: _fExhibitionismCtrl,
                        serifStyle: style),
                    _buildYNCell(
                        code: 'N',
                        controller: _fExhibitionismCtrl,
                        serifStyle: style),
                    _buildYNCell(
                        code: 'DNK',
                        controller: _fExhibitionismCtrl,
                        serifStyle: style),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                          'Did ejaculation occur outside body orifice (vagina/anus/mouth/urethra)?',
                          style: style.copyWith(fontSize: 10.5)),
                    ),
                    _buildYNCell(
                        code: 'Y',
                        controller: _fEjaculationOutsideCtrl,
                        serifStyle: style),
                    _buildYNCell(
                        code: 'N',
                        controller: _fEjaculationOutsideCtrl,
                        serifStyle: style),
                    _buildYNCell(
                        code: 'DNK',
                        controller: _fEjaculationOutsideCtrl,
                        serifStyle: style),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        'If yes, describe where on the body',
                        style: style.copyWith(fontSize: 10.5),
                      ),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: BilingualSimpleUnderlineInput(
                          controller: _fEjaculationWhereBodyCtrl,
                          serifStyle: style,
                          hintText: 'Where on body',
                        ),
                      ),
                    ),
                    const TableCell(child: SizedBox()),
                    const TableCell(child: SizedBox()),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        'Kissing, licking or sucking any part of survivor’s body',
                        style: style.copyWith(fontSize: 10.5),
                      ),
                    ),
                    _buildYNCell(
                        code: 'Y',
                        controller: _fKissingLickingSuckingCtrl,
                        serifStyle: style),
                    _buildYNCell(
                        code: 'N',
                        controller: _fKissingLickingSuckingCtrl,
                        serifStyle: style),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: BilingualSimpleUnderlineInput(
                          controller: _fKissingLickingDescCtrl,
                          serifStyle: style,
                          hintText: 'If Yes, describe',
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        'Touching/Fondling',
                        style: style.copyWith(fontSize: 10.5),
                      ),
                    ),
                    _buildYNCell(
                        code: 'Y',
                        controller: _fTouchingFondlingCtrl,
                        serifStyle: style),
                    _buildYNCell(
                        code: 'N',
                        controller: _fTouchingFondlingCtrl,
                        serifStyle: style),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: BilingualSimpleUnderlineInput(
                          controller: _fTouchingFondlingDescCtrl,
                          serifStyle: style,
                          hintText: 'If Yes, describe',
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        'Condom used*',
                        style: style.copyWith(fontSize: 10.5),
                      ),
                    ),
                    _buildYNCell(
                        code: 'Y',
                        controller: _fCondomUsedCtrl,
                        serifStyle: style),
                    _buildYNCell(
                        code: 'N',
                        controller: _fCondomUsedCtrl,
                        serifStyle: style),
                    _buildYNCell(
                        code: 'DNK',
                        controller: _fCondomUsedCtrl,
                        serifStyle: style),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        'If yes status of condom',
                        style: style.copyWith(fontSize: 10.5),
                      ),
                    ),
                    _buildYNCell(
                        code: 'Y',
                        controller: _fCondomStatusCtrl,
                        serifStyle: style),
                    _buildYNCell(
                        code: 'N',
                        controller: _fCondomStatusCtrl,
                        serifStyle: style),
                    _buildYNCell(
                        code: 'DNK',
                        controller: _fCondomStatusCtrl,
                        serifStyle: style),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        'Lubricant used*',
                        style: style.copyWith(fontSize: 10.5),
                      ),
                    ),
                    _buildYNCell(
                        code: 'Y',
                        controller: _fLubricantUsedCtrl,
                        serifStyle: style),
                    _buildYNCell(
                        code: 'N',
                        controller: _fLubricantUsedCtrl,
                        serifStyle: style),
                    _buildYNCell(
                        code: 'DNK',
                        controller: _fLubricantUsedCtrl,
                        serifStyle: style),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        'If yes, describe kind of lubricant used',
                        style: style.copyWith(fontSize: 10.5),
                      ),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: BilingualSimpleUnderlineInput(
                          controller: _fLubricantKindDescCtrl,
                          serifStyle: style,
                          hintText: 'Kind of lubricant',
                        ),
                      ),
                    ),
                    const TableCell(child: SizedBox()),
                    const TableCell(child: SizedBox()),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        'If object used, describe object:',
                        style: style.copyWith(fontSize: 10.5),
                      ),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: BilingualSimpleUnderlineInput(
                          controller: _fObjectUsedDescCtrl,
                          serifStyle: style,
                          hintText: 'Object description',
                        ),
                      ),
                    ),
                    const TableCell(child: SizedBox()),
                    const TableCell(child: SizedBox()),
                  ],
                ),
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        'Any other forms of sexual violence',
                        style: style.copyWith(fontSize: 10.5),
                      ),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: BilingualSimpleUnderlineInput(
                          controller: _fOtherSexualViolenceFormsCtrl,
                          serifStyle: style,
                          hintText: 'Other forms details',
                        ),
                      ),
                    ),
                    const TableCell(child: SizedBox()),
                    const TableCell(child: SizedBox()),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '* Explain what condom and lubricant is to the survivor',
              style: style.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '4',
                style:
                    style.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            // Page 5 Begins:
            Table(
              border: TableBorder.all(color: Colors.black87, width: 0.8),
              columnWidths: const {
                0: FlexColumnWidth(4.0),
                1: FlexColumnWidth(2.5),
                2: FlexColumnWidth(3.5),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        'Post incident has the survivor',
                        style: style.copyWith(
                            fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        'Yes/No/Do Not know',
                        textAlign: TextAlign.center,
                        style: style.copyWith(
                            fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        'Remarks',
                        textAlign: TextAlign.center,
                        style: style.copyWith(
                            fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                _buildPostIncidentRow(
                  label: 'Changed clothes',
                  choiceCtrl: _fPostChangedClothesCtrl,
                  remarksCtrl: _fPostChangedClothesRemCtrl,
                  serifStyle: style,
                ),
                _buildPostIncidentRow(
                  label: 'Changed undergarments',
                  choiceCtrl: _fPostChangedUndergarmentsCtrl,
                  remarksCtrl: _fPostChangedUndergarmentsRemCtrl,
                  serifStyle: style,
                ),
                _buildPostIncidentRow(
                  label: 'Cleaned/washed clothes',
                  choiceCtrl: _fPostCleanedClothesCtrl,
                  remarksCtrl: _fPostCleanedClothesRemCtrl,
                  serifStyle: style,
                ),
                _buildPostIncidentRow(
                  label: 'Cleaned/washed undergarments',
                  choiceCtrl: _fPostCleanedUndergarmentsCtrl,
                  remarksCtrl: _fPostCleanedUndergarmentsRemCtrl,
                  serifStyle: style,
                ),
                _buildPostIncidentRow(
                  label: 'Bathed',
                  choiceCtrl: _fPostBathedCtrl,
                  remarksCtrl: _fPostBathedRemCtrl,
                  serifStyle: style,
                ),
                _buildPostIncidentRow(
                  label: 'Douched',
                  choiceCtrl: _fPostDouchedCtrl,
                  remarksCtrl: _fPostDouchedRemCtrl,
                  serifStyle: style,
                ),
                _buildPostIncidentRow(
                  label: 'Passed urine',
                  choiceCtrl: _fPostPassedUrineCtrl,
                  remarksCtrl: _fPostPassedUrineRemCtrl,
                  serifStyle: style,
                ),
                _buildPostIncidentRow(
                  label: 'Passed stools',
                  choiceCtrl: _fPostPassedStoolsCtrl,
                  remarksCtrl: _fPostPassedStoolsRemCtrl,
                  serifStyle: style,
                ),
                _buildPostIncidentRow(
                  label:
                      'Rinsing of mouth/Brushing/ Vomiting\n(Circle any or all as appropriate)',
                  choiceCtrl: _fPostRinsingMouthCtrl,
                  remarksCtrl: _fPostRinsingMouthRemCtrl,
                  serifStyle: style,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Time since incident: ',
                    style: style.copyWith(fontSize: 11)),
                Expanded(
                  flex: 3,
                  child: BilingualSimpleUnderlineInput(
                    controller: _fTimeSinceIncidentCtrl,
                    serifStyle: style,
                    hintText: 'e.g. 12 hrs / 2 days',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'H/o vaginal/anal/oral bleeding/discharge prior to the incident of sexual violence: ',
                        style: style.copyWith(fontSize: 10.5),
                      ),
                      BilingualSimpleUnderlineInput(
                        controller: _fBleedingPriorIncidentCtrl,
                        serifStyle: style,
                        hintText: 'Details / None',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'H/o vaginal/anal/oral bleeding/discharge since the incident of sexual violence: ',
                  style: style.copyWith(fontSize: 10.5),
                ),
                BilingualSimpleUnderlineInput(
                  controller: _fBleedingSinceIncidentCtrl,
                  serifStyle: style,
                  hintText: 'Bleeding / discharge details since incident',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'H/o painful urination/ painful defecation/ fissures/ abdominal pain/pain in genitals or any other part since the incident of sexual violence: ',
                  style: style.copyWith(fontSize: 10.5),
                ),
                BilingualSimpleUnderlineInput(
                  controller: _fPainSinceIncidentCtrl,
                  serifStyle: style,
                  hintText: 'Pain / fissures / abdominal pain details',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _bilingualSection(
              '16. General Physical Examination-',
              '१६. सामान्य शारीरिक तपासणी-',
              style,
              marathi,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('i. Is this the first examination: ',
                    style: style.copyWith(fontSize: 11)),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _fExamIsFirstCtrl,
                    serifStyle: style,
                    hintText: 'Yes / No',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('ii. Pulse: ', style: style.copyWith(fontSize: 11)),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _fExamPulseCtrl,
                    serifStyle: style,
                    hintText: '... /min',
                  ),
                ),
                const SizedBox(width: 16),
                Text('BP: ', style: style.copyWith(fontSize: 11)),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _fExamBpCtrl,
                    serifStyle: style,
                    hintText: '... mm Hg',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('iii. Temp: ', style: style.copyWith(fontSize: 11)),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _fExamTempCtrl,
                    serifStyle: style,
                    hintText: '... °F',
                  ),
                ),
                const SizedBox(width: 16),
                Text('Resp. Rate: ', style: style.copyWith(fontSize: 11)),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _fExamRespRateCtrl,
                    serifStyle: style,
                    hintText: '... /min',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('iv. Pupils: ', style: style.copyWith(fontSize: 11)),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _fExamPupilsCtrl,
                    serifStyle: style,
                    hintText: 'Size, reaction to light, etc.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'v. Any observation in terms of general physical wellbeing of the survivor: ',
                  style: style.copyWith(fontSize: 11),
                ),
                BilingualSimpleUnderlineInput(
                  controller: _fExamGeneralWellbeingCtrl,
                  serifStyle: style,
                  hintText: 'General wellbeing observation',
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '5',
                style:
                    style.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
        const SizedBox(height: 24),
        FormPaperPage(
          formLabel: 'Pages 6–8 / पृ. ६–८',
          children: [
            Text(
              '17. Examination for injuries on the body if any',
              style: style.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'The pattern of injuries sustained during an incident of sexual violence may show considerable variation. This may range from complete absence of injuries (more frequently) to grievous injuries (very rare).',
              style: style.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '(Look for bruises, physical torture injuries, nail abrasions, teeth bite marks, cuts, lacerations, fracture, tenderness, any other injury, boils, lesions, discharge specially on the scalp, face, neck, shoulders, breast, wrists, forearms, medial aspect of upper arms, thighs and buttocks) Note the Injury type, site, size, shape, colour, swelling signs of healing simple/grievous, dimensions.)',
              style: style.copyWith(
                fontSize: 10.5,
                color: Colors.black87,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Table(
              border: TableBorder.all(color: Colors.black87, width: 0.8),
              columnWidths: const {
                0: FlexColumnWidth(1.2),
                1: FlexColumnWidth(1.1),
              },
              children: [
                for (var i = 0; i < _femaleInjuryLabels.length; i++)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _femaleInjuryLabels[i].$1,
                              style:
                                  style.copyWith(fontSize: 10.5, height: 1.3),
                            ),
                            if (_femaleInjuryLabels[i].$2.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                _femaleInjuryLabels[i].$2,
                                style: marathi.copyWith(
                                    fontSize: 9.5, color: Colors.black54),
                              ),
                            ],
                          ],
                        ),
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          child: TextField(
                            controller: _fInjuryRows[i],
                            readOnly: widget.readOnly,
                            maxLines: null,
                            minLines: 1,
                            style: style.copyWith(fontSize: 11),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: 'Injury details if any',
                              hintStyle: TextStyle(
                                color: Colors.black38,
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        FormPaperPage(
          formLabel: 'Pages 9–10 / पृ. ९–१०',
          children: [
            Text(
              '18. Local examination of genital parts/other orifices*:',
              style: style.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'A. External Genitalia: Record findings and state NA where not applicable.',
              style: style.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Table(
              border: TableBorder.all(color: Colors.black87, width: 0.8),
              columnWidths: const {
                0: FlexColumnWidth(2.8),
                1: FlexColumnWidth(2.6),
                2: FlexColumnWidth(2.6),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        'Body parts to be examined',
                        style: style.copyWith(
                            fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        'Findings',
                        textAlign: TextAlign.center,
                        style: style.copyWith(
                            fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: SizedBox(),
                    ),
                  ],
                ),
                for (var i = 0; i < _femaleGenitalPartLabels.length; i++)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 6.0),
                        child: Text(
                          _femaleGenitalPartLabels[i],
                          style: style.copyWith(fontSize: 10.5),
                        ),
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: TextField(
                            controller: _fGenitalPartFindings[i],
                            readOnly: widget.readOnly,
                            style: style.copyWith(fontSize: 10.5),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: 'Findings / NA',
                              hintStyle: TextStyle(
                                  color: Colors.black38, fontSize: 9.5),
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                            ),
                          ),
                        ),
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: TextField(
                            controller: _fGenitalPartNotes[i],
                            readOnly: widget.readOnly,
                            style: style.copyWith(fontSize: 10.5),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: 'Remarks / Notes',
                              hintStyle: TextStyle(
                                  color: Colors.black38, fontSize: 9.5),
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '* Per/Vaginum /Per Speculum examination should not be done unless required for detection of injuries or for medical treatment.',
              style: style.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('P/S findings if performed: ',
                    style: style.copyWith(fontSize: 10.5)),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _fPsFindingsCtrl,
                    serifStyle: style,
                    hintText: 'P/S findings or NA',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('P/V findings if performed: ',
                    style: style.copyWith(fontSize: 10.5)),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _fPvFindingsCtrl,
                    serifStyle: style,
                    hintText: 'P/V findings or NA',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Record reasons if P/V of P/S examination performed: ',
                    style: style.copyWith(fontSize: 10.5)),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _fPvPsReasonsCtrl,
                    serifStyle: style,
                    hintText: 'Reasons for P/V or P/S',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'C. Anus and Rectum (encircle the relevant):',
              style: style.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            _buildEncircleOptions(
              options: [
                'Bleeding',
                'Tear',
                'Discharge',
                'Oedema',
                'Tenderness'
              ],
              controller: _fAnusRectumEncircledCtrl,
              serifStyle: style,
            ),
            const SizedBox(height: 4),
            BilingualSimpleUnderlineInput(
              controller: _fAnusRectumNotesCtrl,
              serifStyle: style,
              hintText: 'Additional anus and rectum findings/notes',
            ),
            const SizedBox(height: 12),
            Text(
              'D. Oral Cavity - (encircle the relevant):',
              style: style.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            _buildEncircleOptions(
              options: [
                'Bleeding',
                'Discharge',
                'Tear',
                'Oedema',
                'Tenderness'
              ],
              controller: _fOralCavityEncircledCtrl,
              serifStyle: style,
            ),
            const SizedBox(height: 4),
            BilingualSimpleUnderlineInput(
              controller: _fOralCavityNotesCtrl,
              serifStyle: style,
              hintText: 'Additional oral cavity findings/notes',
            ),
            const SizedBox(height: 16),
            Text(
              '19. Systemic examination:',
              style: style.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Central Nervous System: ',
                    style: style.copyWith(fontSize: 10.5)),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _fSysCnsCtrl,
                    serifStyle: style,
                    hintText: 'CNS findings (e.g. conscious, oriented)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Cardio Vascular System: ',
                    style: style.copyWith(fontSize: 10.5)),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _fSysCvsCtrl,
                    serifStyle: style,
                    hintText: 'CVS findings (e.g. S1 S2 heard)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Respiratory System: ',
                    style: style.copyWith(fontSize: 10.5)),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _fSysRespCtrl,
                    serifStyle: style,
                    hintText: 'RS findings (e.g. AEBE clear)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Chest: ', style: style.copyWith(fontSize: 10.5)),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _fSysChestCtrl,
                    serifStyle: style,
                    hintText: 'Chest examination findings',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Abdomen: ', style: style.copyWith(fontSize: 10.5)),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _fSysAbdomenCtrl,
                    serifStyle: style,
                    hintText: 'Abdomen findings (e.g. soft, non-tender)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '9',
                style:
                    style.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '20. Sample collection/investigations for hospital laboratory/ Clinical laboratory',
              style: style.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('1) Blood for HIV, VDRL, HbsAg: ',
                    style: style.copyWith(fontSize: 11)),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _fSampleBloodHivCtrl,
                    serifStyle: style,
                    hintText: 'Collected / Findings / Sent to Lab',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('2) Urine test for Pregnancy/: ',
                    style: style.copyWith(fontSize: 11)),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _fSampleUrinePregCtrl,
                    serifStyle: style,
                    hintText: 'Positive / Negative / Sent',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('3) Ultrasound for pregnancy/internal injury: ',
                    style: style.copyWith(fontSize: 11)),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _fSampleUsgCtrl,
                    serifStyle: style,
                    hintText: 'USG findings / Advised',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('4) X-ray for Injury: ',
                    style: style.copyWith(fontSize: 11)),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _fSampleXrayCtrl,
                    serifStyle: style,
                    hintText: 'X-ray findings / Region',
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        FormPaperPage(
          formLabel: 'Pages 11–13 / पृ. ११–१३',
          children: [
            Text(
              '21. Samples Collection for Central/ State Forensic Science Laboratory',
              style: style.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('1) Debris collectionpaper: ',
                    style: style.copyWith(fontSize: 11)),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _fFslDebrisCtrl,
                    serifStyle: style,
                    hintText: 'Collected / Sealed / NA',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '2) Clothing evidence where available – (to be packed in separate paper bags after air drying)',
              style: style.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black87, width: 0.8),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'List and Details of clothing worn by the survivor at time of incident of sexual violence',
                    style: style.copyWith(
                        fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _fClothingDetailsCtrl,
                    readOnly: widget.readOnly,
                    maxLines: null,
                    minLines: 4,
                    style: style.copyWith(fontSize: 11),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText:
                          'Describe clothing items, color, stains, tears, preserved status...',
                      hintStyle: TextStyle(
                          color: Colors.black38,
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '3) Body evidence samples as appropriate (duly labeled and packed separately)',
              style:
                  style.copyWith(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Table(
              border: TableBorder.all(color: Colors.black87, width: 0.8),
              columnWidths: const {
                0: FlexColumnWidth(3.4),
                1: FlexColumnWidth(2.2),
                2: FlexColumnWidth(3.2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: SizedBox(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        'Collected/Not Collected',
                        textAlign: TextAlign.center,
                        style: style.copyWith(
                            fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        'Reason for not collecting',
                        textAlign: TextAlign.center,
                        style: style.copyWith(
                            fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                for (var i = 0; i < _femaleFslSampleLabels.length; i++)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 6.0),
                        child: Text(
                          _femaleFslSampleLabels[i],
                          style: style.copyWith(fontSize: 10.5),
                        ),
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: _buildCollectedToggle(
                          controller: _fFslSampleCollected[i],
                          serifStyle: style,
                        ),
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: BilingualSimpleUnderlineInput(
                            controller: _fFslSampleReasons[i],
                            serifStyle: style,
                            hintText: 'Reason if not collected',
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '4) Genital and Anal evidence (Each sample to be packed, sealed, and labeled separately-to be placed in a bag)',
              style:
                  style.copyWith(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '* Swab sticks for collecting samples should be moistened with distilled water provided.',
              style: style.copyWith(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Table(
              border: TableBorder.all(color: Colors.black87, width: 0.8),
              columnWidths: const {
                0: FlexColumnWidth(3.4),
                1: FlexColumnWidth(2.2),
                2: FlexColumnWidth(3.2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: SizedBox(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        'Collected/Not Collected',
                        textAlign: TextAlign.center,
                        style: style.copyWith(
                            fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        'Reason for not collecting',
                        textAlign: TextAlign.center,
                        style: style.copyWith(
                            fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                for (var i = 0; i < _femaleGenitalEvidenceLabels.length; i++)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 6.0),
                        child: Text(
                          _femaleGenitalEvidenceLabels[i],
                          style: style.copyWith(fontSize: 10.5),
                        ),
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: _buildCollectedToggle(
                          controller: _fGenitalEvidenceCollected[i],
                          serifStyle: style,
                        ),
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: BilingualSimpleUnderlineInput(
                            controller: _fGenitalEvidenceReasons[i],
                            serifStyle: style,
                            hintText: 'Reason if not collected',
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '*Samples to be preserved as directed till handed over to police along with duly attested sample seal.',
              style: style.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
            ),
            const SizedBox(height: 18),
            Text(
              '22. Provisional medical opinion',
              style: style.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('I have examined (name of survivor) ',
                    style: style.copyWith(fontSize: 11)),
                SizedBox(
                  width: 170,
                  child: BilingualSimpleUnderlineInput(
                    controller: _fProvSurvivorNameCtrl,
                    serifStyle: style,
                    hintText: 'Name of survivor',
                  ),
                ),
                Text(' M/F/Other ', style: style.copyWith(fontSize: 11)),
                SizedBox(
                  width: 60,
                  child: BilingualSimpleUnderlineInput(
                    controller: _fProvGenderCtrl,
                    serifStyle: style,
                    hintText: 'Gender',
                  ),
                ),
                Text(' aged ', style: style.copyWith(fontSize: 11)),
                SizedBox(
                  width: 60,
                  child: BilingualSimpleUnderlineInput(
                    controller: _fProvAgeCtrl,
                    serifStyle: style,
                    hintText: 'Age',
                  ),
                ),
                Text(' reporting_ (type of sexual violence and circumstances) ',
                    style: style.copyWith(fontSize: 11)),
                SizedBox(
                  width: 200,
                  child: BilingualSimpleUnderlineInput(
                    controller: _fProvCircumstancesCtrl,
                    serifStyle: style,
                    hintText: 'Type / circumstances',
                  ),
                ),
                Text(', ', style: style.copyWith(fontSize: 11)),
                SizedBox(
                  width: 90,
                  child: BilingualSimpleUnderlineInput(
                    controller: _fProvTimeAfterIncidentCtrl,
                    serifStyle: style,
                    hintText: 'XYZ hrs/days',
                  ),
                ),
                Text(' after the incident, after having (bathed/douched etc) ',
                    style: style.copyWith(fontSize: 11)),
                SizedBox(
                  width: 150,
                  child: BilingualSimpleUnderlineInput(
                    controller: _fProvBathedDouchedCtrl,
                    serifStyle: style,
                    hintText: 'Bathed/douched etc',
                  ),
                ),
                Text('. My findings are as follows:',
                    style: style.copyWith(fontSize: 11)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ',
                    style: style.copyWith(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Samples collected (for FSL), awaiting reports:',
                          style: style.copyWith(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                      BilingualSimpleUnderlineInput(
                        controller: _fProvFslSamplesCtrl,
                        serifStyle: style,
                        hintText: 'Details of FSL samples awaiting reports',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ',
                    style: style.copyWith(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Samples collected (for hospital laboratory):',
                          style: style.copyWith(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                      BilingualSimpleUnderlineInput(
                        controller: _fProvHospSamplesCtrl,
                        serifStyle: style,
                        hintText: 'Hospital lab sample details',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ',
                    style: style.copyWith(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Clinical findings:',
                          style: style.copyWith(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                      BilingualSimpleUnderlineInput(
                        controller: _fProvClinicalFindingsCtrl,
                        serifStyle: style,
                        hintText: 'Summary of clinical findings',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ',
                    style: style.copyWith(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Additional observations (if any):',
                          style: style.copyWith(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                      BilingualSimpleUnderlineInput(
                        controller: _fProvAdditionalObsCtrl,
                        serifStyle: style,
                        hintText: 'Additional observations',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '23. Treatment prescribed:',
              style: style.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Table(
              border: TableBorder.all(color: Colors.black87, width: 0.8),
              columnWidths: const {
                0: FlexColumnWidth(3.8),
                1: FlexColumnWidth(1.1),
                2: FlexColumnWidth(1.1),
                3: FlexColumnWidth(4.0),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade100),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        'Treatment',
                        style: style.copyWith(
                            fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        'Yes',
                        textAlign: TextAlign.center,
                        style: style.copyWith(
                            fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        'NO',
                        textAlign: TextAlign.center,
                        style: style.copyWith(
                            fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        'Type and comments',
                        textAlign: TextAlign.center,
                        style: style.copyWith(
                            fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                for (var i = 0; i < _femaleTreatmentLabels.length; i++)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 6.0),
                        child: Text(
                          _femaleTreatmentLabels[i],
                          style: style.copyWith(fontSize: 10.5),
                        ),
                      ),
                      _buildTableRadioCell(
                        code: 'Yes',
                        controller: _fTreatmentChoice[i],
                        serifStyle: style,
                      ),
                      _buildTableRadioCell(
                        code: 'No',
                        controller: _fTreatmentChoice[i],
                        serifStyle: style,
                      ),
                      TableCell(
                        verticalAlignment: TableCellVerticalAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: TextField(
                            controller: _fTreatmentComments[i],
                            readOnly: widget.readOnly,
                            style: style.copyWith(fontSize: 10.5),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: 'Comments / details',
                              hintStyle: TextStyle(
                                  color: Colors.black38, fontSize: 9.5),
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '24. Date and time of completion of examination: ',
                  style:
                      style.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _fCompletionDateTimeCtrl,
                    serifStyle: style,
                    hintText: 'DD/MM/YYYY, HH:MM AM/PM',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('This report contains ',
                    style: style.copyWith(fontSize: 11)),
                SizedBox(
                  width: 120,
                  child: BilingualSimpleUnderlineInput(
                    controller: _fReportSheetsCountCtrl,
                    serifStyle: style,
                    hintText: 'No. of sheets',
                  ),
                ),
                Text(' number of sheets and ',
                    style: style.copyWith(fontSize: 11)),
                SizedBox(
                  width: 120,
                  child: BilingualSimpleUnderlineInput(
                    controller: _fReportEnvelopesCountCtrl,
                    serifStyle: style,
                    hintText: 'No. of envelopes',
                  ),
                ),
                Text(' number of envelopes.',
                    style: style.copyWith(fontSize: 11)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Place: ',
                          style: style.copyWith(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                      Expanded(
                        child: BilingualSimpleUnderlineInput(
                          controller: _fCompletionPlaceCtrl,
                          serifStyle: style,
                          hintText: 'Place / City',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Signature of Examining Doctor',
                          style: style.copyWith(
                              fontSize: 10.5, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Name: ',
                              style: style.copyWith(
                                  fontSize: 10.5, fontWeight: FontWeight.w600)),
                          Expanded(
                            child: BilingualSimpleUnderlineInput(
                              controller: _fDoctorNameCtrl,
                              serifStyle: style,
                              hintText: 'Name of Examining Doctor',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Seal: ',
                              style: style.copyWith(
                                  fontSize: 10.5, fontWeight: FontWeight.w600)),
                          Expanded(
                            child: BilingualSimpleUnderlineInput(
                              controller: _fDoctorSealCtrl,
                              serifStyle: style,
                              hintText: 'Doctor seal / Reg. No.',
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
            Text(
              '25. Final Opinion (After receiving Lab reports)',
              style: style.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Findings in support of the above opinion, ',
                  style:
                      style.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                Text(
                  'taking into account the history, clinical examination findings and Laboratory reports of ',
                  style: style.copyWith(fontSize: 11),
                ),
                SizedBox(
                  width: 170,
                  child: BilingualSimpleUnderlineInput(
                    controller: _fFinalOpinionPersonCtrl,
                    serifStyle: style,
                    hintText: 'Name of survivor',
                  ),
                ),
                Text(
                  ' bearing identification marks described above, ',
                  style: style.copyWith(fontSize: 11),
                ),
                SizedBox(
                  width: 100,
                  child: BilingualSimpleUnderlineInput(
                    controller: _fFinalOpinionTimeCtrl,
                    serifStyle: style,
                    hintText: 'XYZ hours/days',
                  ),
                ),
                Text(
                  ' after the incident of sexual violence, I am of the opinion that:',
                  style: style.copyWith(fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black54, width: 0.8),
              ),
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _fFinalOpinionTextCtrl,
                readOnly: widget.readOnly,
                maxLines: null,
                minLines: 6,
                style: style.copyWith(fontSize: 11),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Enter final opinion details after lab reports...',
                  hintStyle: TextStyle(
                      color: Colors.black38,
                      fontSize: 10.5,
                      fontStyle: FontStyle.italic),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Place: ',
                          style: style.copyWith(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                      Expanded(
                        child: BilingualSimpleUnderlineInput(
                          controller: _fFinalOpinionPlaceCtrl,
                          serifStyle: style,
                          hintText: 'Place / City',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Signature of Examining Doctor',
                          style: style.copyWith(
                              fontSize: 10.5, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Name: ',
                              style: style.copyWith(
                                  fontSize: 10.5, fontWeight: FontWeight.w600)),
                          Expanded(
                            child: BilingualSimpleUnderlineInput(
                              controller: _fFinalDoctorNameCtrl,
                              serifStyle: style,
                              hintText: 'Name of Examining Doctor',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Seal: ',
                              style: style.copyWith(
                                  fontSize: 10.5, fontWeight: FontWeight.w600)),
                          Expanded(
                            child: BilingualSimpleUnderlineInput(
                              controller: _fFinalDoctorSealCtrl,
                              serifStyle: style,
                              hintText: 'Doctor seal / Reg. No.',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'COPY OF THE ENTIRE MEDICAL REPORT MUST BE GIVEN TO THE SURVIVOR/\nVICTIM FREE OF COST IMMEDIATELY',
              style: style.copyWith(
                  fontWeight: FontWeight.bold, fontSize: 10.5, height: 1.3),
            ),
            const SizedBox(height: 4),
            Text(
              'संपूर्ण वैद्यकीय अहवालाची प्रत पीडित/पीडितेला त्वरित विनामूल्य द्यावी',
              style:
                  marathi.copyWith(fontWeight: FontWeight.bold, fontSize: 9.5),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMalePages(TextStyle style, TextStyle marathi) {
    return Column(
      children: [
        FormPaperPage(
          formLabel: 'Page 1 / पृ. १',
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    'FORENSIC MEDICAL EXAMINATION OF ALLEGED ACCUSED\nFOR EVIDENCE OF SEXUAL ASSAULT',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lora(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  Text(
                    'लैंगिक अत्याचाराच्या पुराव्यासाठी\nआरोपीची फॉरेन्सिक वैद्यकीय तपासणी',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansDevanagari(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _bilingualSection('(I) Preliminary information and consent',
                '(१) प्राथमिक माहिती व संमती', style, marathi),
            _bilingualField('1. Name of the hospital', '१. रुग्णालयाचे नाव',
                _mHospitalCtrl, style, marathi),
            BilingualFieldRow(fields: [
              _bilingualField('2. OPD/IPD No.', '२. बाह्य/अंतर्गत क्र.',
                  _mOpdCtrl, style, marathi),
              _bilingualField('Date', 'दिनांक', _mDateCtrl, style, marathi),
            ]),
            BilingualFieldRow(fields: [
              _bilingualField(
                  'MLC No.', 'एम.एल.सी. क्र.', _mMlcCtrl, style, marathi),
              _bilingualField('MLC Date', 'एम.एल.सी. दिनांक', _mMlcDateCtrl,
                  style, marathi),
            ]),
            _bilingualField('3. Name of the alleged Accused', '३. आरोपीचे नाव',
                _mAccusedNameCtrl, style, marathi),
            BilingualFieldRow(fields: [
              _bilingualField('4. Age', '४. वय', _mAgeCtrl, style, marathi),
              _bilingualField(
                  'Date of Birth', 'जन्मतारीख', _mDobCtrl, style, marathi),
              _bilingualField(
                  'Religion', 'धर्म', _mReligionCtrl, style, marathi),
            ]),
            _bilingualField('5. Married/Single/Divorced',
                '५. विवाहित/अविवाहित/घटस्फोट', _mMaritalCtrl, style, marathi),
            _bilingualField(
                '6. Address', '६. पत्ता', _mAddressCtrl, style, marathi,
                minLines: 3),
            _bilingualField(
              '7. Brought by — Name of police / B No. / Police Station / C.R.No / U/s',
              '७. कोणी आणले — पोलीस नाव / बक्कल / ठाणे / गु.नो. / कलम',
              _mPoliceNameCtrl,
              style,
              marathi,
              minLines: 2,
            ),
            BilingualFieldRow(fields: [
              _bilingualField(
                  'Buckle No.', 'बक्कल क्र.', _mBuckleCtrl, style, marathi),
              _bilingualField('P.S.', 'पो.ठ.', _mPsCtrl, style, marathi),
            ]),
            BilingualFieldRow(fields: [
              _bilingualField('C.R.No', 'गु.नो.', _mCrNoCtrl, style, marathi),
              _bilingualField('U/s', 'कलम', _mSectionCtrl, style, marathi),
            ]),
            _bilingualSection('8. CONSENT', '८. संमती', style, marathi),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'I … hereby voluntarily consent to: (a) medical examination and examination of genitals and other body parts (b) collection of samples for medical and forensic examination and treatment. All this has been explained to me in the manner and language which I can understand.',
                    style: style.copyWith(fontSize: 10, height: 1.35),
                  ),
                  Text(
                    'मी … येथे स्वेच्छेने संमती देतो: (अ) वैद्यकीय व गुप्तांग/शरीर तपासणी (ब) वैद्यकीय व फॉरेन्सिक नमुने व उपचार. हे मला समजेल अशा भाषेत समजावले.',
                    style: marathi.copyWith(fontSize: 9, height: 1.35),
                  ),
                ],
              ),
            ),
            _bilingualField('Consent details / signature block',
                'संमती तपशील / सही', _mConsentCtrl, style, marathi,
                minLines: 6),
            _bilingualSection(
                '9. Identification Marks', '९. ओळखीच्या खुणा', style, marathi),
            BilingualFieldRow(fields: [
              _bilingualField('(1)', '(१)', _mIdMark1Ctrl, style, marathi),
              _bilingualField('(2) Left thumb impression',
                  '(२) डाव्या हाताचा अंगठा', _mIdMark2Ctrl, style, marathi),
            ]),
            _bilingualField('10. Date & time of examination',
                '१०. तपासणी दिनांक व वेळ', _mExamDateTimeCtrl, style, marathi),
            _bilingualField(
                '11. Name/s of doctor who conducted examination',
                '११. तपासणी केलेल्या डॉक्टराचे नाव',
                _mDoctorCtrl,
                style,
                marathi),
            _bilingualSection(
                '(II) History of alleged sexual assault as stated by Accused',
                '(२) आरोपीने सांगितलेला अत्याचाराचा इतिहास',
                style,
                marathi),
            _bilingualField(
                '', 'आरोपीचे वर्णन', _mAssaultHistoryCtrl, style, marathi,
                minLines: 10),
            BilingualFieldRow(fields: [
              _bilingualField('Signature & name of witness',
                  'साक्षीदार सही व नाव', _mWitnessSigCtrl, style, marathi),
              _bilingualField('Signature & name of accused/guardian',
                  'आरोपी/पालक सही व नाव', _mAccusedSigCtrl, style, marathi),
            ]),
          ],
        ),
        const SizedBox(height: 24),
        FormPaperPage(
          formLabel: 'Page 2 / पृ. २',
          children: [
            _bilingualSection('(III) Medical and Surgical History',
                '(३) वैद्यकीय व शस्त्रक्रिया इतिहास', style, marathi),
            _bilingualField(
                '', 'वैद्यकीय इतिहास', _mMedSurgicalHistoryCtrl, style, marathi,
                minLines: 12),
            _bilingualSection('(IV) General physical examination',
                '(४) सामान्य शारीरिक तपासणी', style, marathi),
            _bilingualField(
                '', 'सामान्य तपासणी', _mGeneralPhysicalCtrl, style, marathi,
                minLines: 12),
            _bilingualSection('(V) Local Examination: Perineum and Genitals',
                '(५) स्थानिक तपासणी: गुदद्वार व गुप्तांग', style, marathi),
            _bilingualField(
                '', 'स्थानिक तपासणी', _mLocalExamCtrl, style, marathi,
                minLines: 10),
          ],
        ),
        const SizedBox(height: 24),
        FormPaperPage(
          formLabel: 'Page 3 / पृ. ३',
          children: [
            _bilingualSection('(VI) Systemic Examination',
                '(६) प्रणालीगत तपासणी', style, marathi),
            _bilingualField(
                '', 'प्रणालीगत तपासणी', _mSystemicExamCtrl, style, marathi,
                minLines: 4),
            _bilingualSection('(VII) Additional findings / referral',
                '(७) अतिरिक्त निष्कर्ष / संदर्भ', style, marathi),
            _bilingualField('', 'अतिरिक्त निष्कर्ष', _mAdditionalFindingsCtrl,
                style, marathi,
                minLines: 4),
            _buildMaleSectionVIII(style, marathi),
            _bilingualSection(
              '(IX) Samples/ Forensic Evidence preserved for FSL:',
              '(९) एफ.एस.एल.साठी जतन केलेला फॉरेन्सिक पुरावा / नमुने :',
              style,
              marathi,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The samples must be collected as per time elapsed between assault and examination, history and physical findings. This will avoid unnecessary sample collection. The list of samples to be preserved is annexed herewith in triplicate, which is the part of requisition to FSL for relevant examination. Here it must be remembered that specific mention in words as to which samples are collected & which are not collected is very necessary.',
                    style: style.copyWith(
                      fontSize: 11,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'अत्याचार आणि तपासणी दरम्यान उलटून गेलेल्या वेळेनुसार, इतिहास आणि शारीरिक निष्कर्षांनुसार नमुने गोळा केले पाहिजेत. यामुळे अनावश्यक नमुने गोळा करणे टाळता येईल. जतन करावयाच्या नमुन्यांची यादी तीन प्रतीत सोबत जोडलेली आहे, जी संबंधित तपासणीसाठी एफ.एस.एल.कडे मागणीचा भाग आहे. येथे हे लक्षात ठेवले पाहिजे की कोणते नमुने गोळा केले गेले आहेत आणि कोणते गोळा केले गेले नाहीत याचा शब्दात विशिष्ट उल्लेख करणे अत्यंत आवश्यक आहे.',
                    style: marathi.copyWith(
                      fontSize: 10,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            _bilingualField(
              'Note (If any)',
              'टिपणी (असल्यास)',
              _mFslNoteCtrl,
              style,
              marathi,
              minLines: 6,
            ),
          ],
        ),
        const SizedBox(height: 24),
        FormPaperPage(
          formLabel: 'Page 4 / पृ. ४',
          children: [
            _bilingualSection(
              'PROVISIONAL OPINION: **',
              'तात्पुरते वैद्यकीय मत: **',
              style,
              marathi,
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'After examining the person bearing above mentioned identification marks, ',
                  style: style.copyWith(fontSize: 11),
                ),
                SizedBox(
                  width: 140,
                  child: BilingualSimpleUnderlineInput(
                    controller: _mOpinionTimeElapsedCtrl,
                    serifStyle: style,
                    hintText: 'e.g. 2 days / 6 hrs',
                  ),
                ),
                Text(
                  ' days/hours after the incident, I/We is/are of the opinion that:',
                  style: style.copyWith(fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'वर नमूद केलेल्या ओळखीच्या खुणा असलेल्या व्यक्तीची तपासणी केल्यानंतर, घटनेनंतर ... दिवस/तासांनी, माझे/आमचे असे मत आहे की:',
              style: marathi.copyWith(fontSize: 10),
            ),
            const SizedBox(height: 8),
            BilingualDynamicLinedTextField(
              controller: _mProvisionalOpinionCtrl,
              minLines: 8,
              serifStyle: style,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Date: ',
                    style: style.copyWith(
                        fontSize: 11, fontWeight: FontWeight.bold)),
                SizedBox(
                  width: 130,
                  child: BilingualSimpleUnderlineInput(
                    controller: _mOpinionDateCtrl,
                    serifStyle: style,
                    hintText: 'DD/MM/YYYY',
                  ),
                ),
                const Spacer(),
                Text('(Report contains ', style: style.copyWith(fontSize: 11)),
                SizedBox(
                  width: 40,
                  child: BilingualSimpleUnderlineInput(
                    controller: _mReportPagesCountCtrl,
                    serifStyle: style,
                    hintText: '4',
                  ),
                ),
                Text(' pages each signed by doctor)',
                    style: style.copyWith(fontSize: 11)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 130,
                  height: 65,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black54, width: 1.2),
                    borderRadius: BorderRadius.circular(35),
                  ),
                  child: Center(
                    child: Text(
                      'Stamp / शिक्का',
                      style: style.copyWith(
                        fontSize: 11,
                        color: Colors.black45,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text('Signature:',
                                style: style.copyWith(fontSize: 11)),
                          ),
                          Expanded(
                            child: BilingualSimpleUnderlineInput(
                              controller: _mDoctorSigCtrl,
                              serifStyle: style,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text('Name of Dr.:',
                                style: style.copyWith(fontSize: 11)),
                          ),
                          Expanded(
                            child: BilingualSimpleUnderlineInput(
                              controller: _mDoctorNameCtrl,
                              serifStyle: style,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text('Dept/ Designation :',
                                style: style.copyWith(fontSize: 11)),
                          ),
                          Expanded(
                            child: BilingualSimpleUnderlineInput(
                              controller: _mDoctorDeptDesigCtrl,
                              serifStyle: style,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50.withValues(alpha: 0.4),
                border: Border.all(color: Colors.amber.shade200, width: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IMPORTANT NOTE** / महत्त्वाची टिपणी** :',
                    style: style.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown.shade900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildNoteBullet(
                    'The provisional opinion must be in the form of general opinion / impression about possibility of sexual intercourse, after taking into account positive findings in relation to genitals and the body in general. As mentioned above the provisional opinion must include the fact of capacity of the accused to perform sexual act. In absence of these findings, opinion must be reserved till receipt of results of accessory examination.',
                    'तात्पुरते मत हे गुप्तांग आणि शरीरावरील सकारात्मक निष्कर्ष लक्षात घेऊन, लैंगिक संबंधाच्या शक्यतेबद्दल सामान्य मत / निष्कर्षाच्या स्वरूपात असणे आवश्यक आहे. वर नमूद केल्याप्रमाणे तात्पुरत्या मतामध्ये आरोपीच्या लैंगिक संबंध ठेवण्याच्या क्षमतेचा समावेश असावा. हे निष्कर्ष नसल्यास, सहाय्यक तपासणीचे निकाल येईपर्यंत मत राखीव ठेवले पाहिजे.',
                    style,
                    marathi,
                  ),
                  const SizedBox(height: 6),
                  _buildNoteBullet(
                    'Precisely brief justification (reasons) in support of your opinion must be given.',
                    'आपल्या मताच्या समर्थनार्थ थोडक्यात नेमके समर्थन (कारणे) देणे आवश्यक आहे.',
                    style,
                    marathi,
                  ),
                  const SizedBox(height: 6),
                  _buildNoteBullet(
                    '* The accused can be examined physically without consent as per Cr.P.C 53 & 53 a, if he denies consent.',
                    '* आरोपीने संमती नाकारल्यास, Cr.P.C ५३ आणि ५३ ए नुसार संमतीशिवाय त्याची शारीरिक तपासणी केली जाऊ शकते.',
                    style,
                    marathi,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.black54, thickness: 1),
            const SizedBox(height: 8),
            _bilingualSection(
              'RECEIPT (by police official):',
              'पोलीस अधिकाऱ्याची पावती :',
              style,
              marathi,
            ),
            Text(
              'Received forensic medical examination report: / फॉरेन्सिक वैद्यकीय तपासणी अहवाल मिळाला:',
              style: style.copyWith(fontSize: 11, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Text('Signature: ', style: style.copyWith(fontSize: 11)),
                      Expanded(
                        child: BilingualSimpleUnderlineInput(
                          controller: _mReceiptPoliceCtrl,
                          serifStyle: style,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      Text('Name of police:- ',
                          style: style.copyWith(fontSize: 11)),
                      Expanded(
                        child: BilingualSimpleUnderlineInput(
                          controller: _mReceiptPoliceNameCtrl,
                          serifStyle: style,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Text('Buckle No. : ',
                          style: style.copyWith(fontSize: 11)),
                      Expanded(
                        child: BilingualSimpleUnderlineInput(
                          controller: _mReceiptBuckleNoCtrl,
                          serifStyle: style,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Police station:- ', style: style.copyWith(fontSize: 11)),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _mReceiptPsCtrl,
                    serifStyle: style,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FormMrwFooter(serifStyle: style, fontSize: 10),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = FormTypography.serifStyle();
    final marathi = FormTypography.marathiLabelStyle();

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        if (_showFemale) _buildFemalePages(style, marathi),
        if (_showFemale && _showMale) const SizedBox(height: 24),
        if (_showMale) _buildMalePages(style, marathi),
      ],
    );
  }
}
