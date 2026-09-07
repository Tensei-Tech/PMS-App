import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bilingual_field.dart';
import 'form_paper_page.dart';
import 'form_typography.dart';
import 'form_view_scaffold.dart';

/// Juvenile Social Background Report (विधीसंघर्षग्रस्त बालक याचा सामाजीक पार्श्वभुमी अहवाल).
class JuvenileSocialReportFormView extends StatefulWidget {
  final bool readOnly;
  final Map<String, dynamic>? existingRecord;
  final String? formSection;
  final String? pageRange;

  const JuvenileSocialReportFormView({
    super.key,
    this.readOnly = false,
    this.existingRecord,
    this.formSection,
    this.pageRange,
  });

  @override
  State<JuvenileSocialReportFormView> createState() =>
      JuvenileSocialReportFormViewState();
}

class JuvenileSocialReportFormViewState
    extends State<JuvenileSocialReportFormView> {
  static const kPartI = 'Juvenile Social Part I';
  static const kPartII = 'Juvenile Social Part II';
  static const kPartIII = 'Juvenile Social Part III';
  static const kPartIV = 'Juvenile Social Part IV';
  static const kPartV = 'Juvenile Social Part V';
  static const _knownSectionIds = {kPartI, kPartII, kPartIII, kPartIV, kPartV};

  String? _activePhase;

  bool _shows(String id) {
    final current = _activePhase?.trim();
    if (current == null ||
        current.isEmpty ||
        current == 'ALL' ||
        !_knownSectionIds.contains(current)) {
      return true;
    }
    if (current == kPartIV || current == kPartV) {
      return id == kPartIV || id == kPartV;
    }
    return current == id;
  }

  bool get _showAll {
    final current = _activePhase?.trim();
    return current == null ||
        current.isEmpty ||
        current == 'ALL' ||
        !_knownSectionIds.contains(current);
  }

  // ─── PAGE 1 CONTROLLERS (Items 1–7 & Child particulars) ──────────────────
  final _psDistCtrl = TextEditingController();
  final _crimeNoCtrl = TextEditingController();
  final _sectionActCtrl = TextEditingController();
  final _crimeDateTimeCtrl = TextEditingController();
  final _firDateTimeCtrl = TextEditingController();
  final _ioNameCtrl = TextEditingController();
  final _cwpoNameCtrl = TextEditingController();
  final _childNameCtrl = TextEditingController();
  final _fatherNameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _religionCtrl = TextEditingController();
  final _hasDisabilityCtrl = TextEditingController(text: 'नाही');
  final _deafCtrl = TextEditingController(text: 'नाही');
  final _dumbCtrl = TextEditingController(text: 'नाही');
  final _physicalDisabilityCtrl = TextEditingController(text: 'नाही');
  final _mentalDisabilityCtrl = TextEditingController(text: 'नाही');
  final _otherDisabilityCtrl = TextEditingController();

  // ─── PAGE 2 CONTROLLERS (Items 8–12: Family, Drop reason, Habits) ─────────
  int _familyRowCount = 5;
  late final List<TextEditingController> _famNameRelationCtrls;
  late final List<TextEditingController> _famAgeCtrls;
  late final List<TextEditingController> _famSexCtrls;
  late final List<TextEditingController> _famEduCtrls;
  late final List<TextEditingController> _famOccCtrls;
  late final List<TextEditingController> _famIncomeCtrls;
  late final List<TextEditingController> _famHealthCtrls;
  late final List<TextEditingController> _famMentalHistCtrls;
  late final List<TextEditingController> _famAddictionCtrls;

  final _schoolDropReasonPage2Ctrl = TextEditingController();
  final _familyInCrimeCtrl = TextEditingController();

  // Habits (अ) & Hobbies (ब)
  final Map<String, bool> _habitsChecked = {
    'smoking': false,
    'alcohol': false,
    'gambling': false,
    'begging': false,
    'tobacco_pan': false,
  };
  final _habitOtherCtrl = TextEditingController();

  final Map<String, bool> _hobbiesChecked = {
    'watching_tv': false,
    'playing_games': false,
    'reading_books': false,
    'drawing': false,
    'singing_art': false,
  };
  final _hobbyOtherCtrl = TextEditingController();

  final _childJobDetailsCtrl = TextEditingController();

  // ─── PAGE 3 CONTROLLERS (Items 13–17: Income usage, Education, Reasons) ──
  final _incomeUsageDetailsCtrl = TextEditingController();
  final _incomeUsageFamilyCtrl = TextEditingController(text: 'नाही');
  final _incomeUsageSelfCtrl = TextEditingController(text: 'नाही');
  final _incomeUsageClothesCtrl = TextEditingController(text: 'नाही');
  final _incomeUsageGamblingCtrl = TextEditingController(text: 'नाही');
  final _incomeUsageAddictionCtrl = TextEditingController(text: 'नाही');
  final _incomeUsageSavingsCtrl = TextEditingController(text: 'नाही');

  String _selectedEducationLevel = '';
  final Set<String> _schoolLeavingReasons = {};
  final _schoolLeavingOtherCtrl = TextEditingController();

  String _selectedSchoolType = '';
  final _vocationalTrainingCtrl = TextEditingController(text: 'नाही');

  // ─── PAGE 4 CONTROLLERS (Items 18–24: Friends, Abuse, Crime Reasons) ──────
  final Set<String> _friendTypes = {};
  final _friendsAddictedCtrl = TextEditingController(text: 'नाही');
  final _friendsCriminalCtrl = TextEditingController(text: 'नाही');

  final _childAbusedCtrl = TextEditingController(text: 'नाही');
  final _abuseVerbalCtrl = TextEditingController();
  final _abusePhysicalCtrl = TextEditingController();
  final _abuseSexualCtrl = TextEditingController();
  final _abuseOtherCtrl = TextEditingController();

  final _childVictimCtrl = TextEditingController(text: 'नाही');
  final _childDrugCarrierCtrl = TextEditingController(text: 'नाही');
  final _crimeReasonCtrl = TextEditingController();
  final _arrestCircumstancesCtrl = TextEditingController();
  final _propertyFromChildCtrl = TextEditingController();

  // ─── PAGE 5 CONTROLLERS (Items 25–26 & Signature Section) ─────────────────
  final _childRoleInCrimeCtrl = TextEditingController();
  final _cwpoInstructionsCtrl = TextEditingController();

  final _signOfficerNameCtrl = TextEditingController();
  final _signOfficerRankCtrl = TextEditingController();
  final _signOfficerBadgeCtrl = TextEditingController();
  final _signOfficerPostingCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _activePhase = widget.formSection;
    _famNameRelationCtrls =
        List.generate(_familyRowCount, (_) => TextEditingController());
    _famAgeCtrls =
        List.generate(_familyRowCount, (_) => TextEditingController());
    _famSexCtrls =
        List.generate(_familyRowCount, (_) => TextEditingController(text: 'स्त्रि/ पुरूष'));
    _famEduCtrls =
        List.generate(_familyRowCount, (_) => TextEditingController());
    _famOccCtrls =
        List.generate(_familyRowCount, (_) => TextEditingController());
    _famIncomeCtrls =
        List.generate(_familyRowCount, (_) => TextEditingController());
    _famHealthCtrls =
        List.generate(_familyRowCount, (_) => TextEditingController());
    _famMentalHistCtrls =
        List.generate(_familyRowCount, (_) => TextEditingController());
    _famAddictionCtrls =
        List.generate(_familyRowCount, (_) => TextEditingController());

    if (widget.existingRecord != null) {
      hydrateFrom(widget.existingRecord!);
    }
  }

  @override
  void didUpdateWidget(covariant JuvenileSocialReportFormView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.formSection != widget.formSection) {
      setState(() {
        _activePhase = widget.formSection;
      });
    }
  }

  @override
  void dispose() {
    _psDistCtrl.dispose();
    _crimeNoCtrl.dispose();
    _sectionActCtrl.dispose();
    _crimeDateTimeCtrl.dispose();
    _firDateTimeCtrl.dispose();
    _ioNameCtrl.dispose();
    _cwpoNameCtrl.dispose();
    _childNameCtrl.dispose();
    _fatherNameCtrl.dispose();
    _dobCtrl.dispose();
    _addressCtrl.dispose();
    _religionCtrl.dispose();
    _hasDisabilityCtrl.dispose();
    _deafCtrl.dispose();
    _dumbCtrl.dispose();
    _physicalDisabilityCtrl.dispose();
    _mentalDisabilityCtrl.dispose();
    _otherDisabilityCtrl.dispose();

    for (final c in [
      ..._famNameRelationCtrls,
      ..._famAgeCtrls,
      ..._famSexCtrls,
      ..._famEduCtrls,
      ..._famOccCtrls,
      ..._famIncomeCtrls,
      ..._famHealthCtrls,
      ..._famMentalHistCtrls,
      ..._famAddictionCtrls,
    ]) {
      c.dispose();
    }

    _schoolDropReasonPage2Ctrl.dispose();
    _familyInCrimeCtrl.dispose();
    _habitOtherCtrl.dispose();
    _hobbyOtherCtrl.dispose();
    _childJobDetailsCtrl.dispose();

    _incomeUsageDetailsCtrl.dispose();
    _incomeUsageFamilyCtrl.dispose();
    _incomeUsageSelfCtrl.dispose();
    _incomeUsageClothesCtrl.dispose();
    _incomeUsageGamblingCtrl.dispose();
    _incomeUsageAddictionCtrl.dispose();
    _incomeUsageSavingsCtrl.dispose();
    _schoolLeavingOtherCtrl.dispose();
    _vocationalTrainingCtrl.dispose();

    _friendsAddictedCtrl.dispose();
    _friendsCriminalCtrl.dispose();
    _childAbusedCtrl.dispose();
    _abuseVerbalCtrl.dispose();
    _abusePhysicalCtrl.dispose();
    _abuseSexualCtrl.dispose();
    _abuseOtherCtrl.dispose();
    _childVictimCtrl.dispose();
    _childDrugCarrierCtrl.dispose();
    _crimeReasonCtrl.dispose();
    _arrestCircumstancesCtrl.dispose();
    _propertyFromChildCtrl.dispose();

    _childRoleInCrimeCtrl.dispose();
    _cwpoInstructionsCtrl.dispose();
    _signOfficerNameCtrl.dispose();
    _signOfficerRankCtrl.dispose();
    _signOfficerBadgeCtrl.dispose();
    _signOfficerPostingCtrl.dispose();

    super.dispose();
  }

  void hydrateFrom(Map<String, dynamic> data) {
    setState(() {
      _psDistCtrl.text = data['psDist']?.toString() ?? data['policeStation']?.toString() ?? '';
      _crimeNoCtrl.text = data['crimeNo']?.toString() ?? data['crNo']?.toString() ?? '';
      _sectionActCtrl.text = data['sectionAct']?.toString() ?? data['section']?.toString() ?? '';
      _crimeDateTimeCtrl.text = data['crimeDateTime']?.toString() ?? '';
      _firDateTimeCtrl.text = data['firDateTime']?.toString() ?? '';
      _ioNameCtrl.text = data['ioName']?.toString() ?? '';
      _cwpoNameCtrl.text = data['cwpoName']?.toString() ?? '';
      _childNameCtrl.text = data['childName']?.toString() ?? data['juvenileName']?.toString() ?? '';
      _fatherNameCtrl.text = data['fatherName']?.toString() ?? data['guardianName']?.toString() ?? '';
      _dobCtrl.text = data['dob']?.toString() ?? data['juvenileAge']?.toString() ?? '';
      _addressCtrl.text = data['address']?.toString() ?? data['juvenileAddress']?.toString() ?? '';
      _religionCtrl.text = data['religion']?.toString() ?? '';
      _hasDisabilityCtrl.text = data['hasDisability']?.toString() ?? _hasDisabilityCtrl.text;
      _deafCtrl.text = data['deaf']?.toString() ?? _deafCtrl.text;
      _dumbCtrl.text = data['dumb']?.toString() ?? _dumbCtrl.text;
      _physicalDisabilityCtrl.text = data['physicalDisability']?.toString() ?? _physicalDisabilityCtrl.text;
      _mentalDisabilityCtrl.text = data['mentalDisability']?.toString() ?? _mentalDisabilityCtrl.text;
      _otherDisabilityCtrl.text = data['otherDisability']?.toString() ?? '';

      final savedFamCount = int.tryParse(data['familyRowCount']?.toString() ?? '');
      if (savedFamCount != null && savedFamCount > _familyRowCount) {
        while (_familyRowCount < savedFamCount) {
          _familyRowCount++;
          _famNameRelationCtrls.add(TextEditingController());
          _famAgeCtrls.add(TextEditingController());
          _famSexCtrls.add(TextEditingController(text: 'स्त्रि/ पुरूष'));
          _famEduCtrls.add(TextEditingController());
          _famOccCtrls.add(TextEditingController());
          _famIncomeCtrls.add(TextEditingController());
          _famHealthCtrls.add(TextEditingController());
          _famMentalHistCtrls.add(TextEditingController());
          _famAddictionCtrls.add(TextEditingController());
        }
      }

      for (var i = 0; i < _familyRowCount; i++) {
        final n = '${i + 1}';
        if (data.containsKey('fam${n}Name')) _famNameRelationCtrls[i].text = data['fam${n}Name']?.toString() ?? '';
        if (data.containsKey('fam${n}Age')) _famAgeCtrls[i].text = data['fam${n}Age']?.toString() ?? '';
        if (data.containsKey('fam${n}Sex')) _famSexCtrls[i].text = data['fam${n}Sex']?.toString() ?? '';
        if (data.containsKey('fam${n}Edu')) _famEduCtrls[i].text = data['fam${n}Edu']?.toString() ?? '';
        if (data.containsKey('fam${n}Occ')) _famOccCtrls[i].text = data['fam${n}Occ']?.toString() ?? '';
        if (data.containsKey('fam${n}Income')) _famIncomeCtrls[i].text = data['fam${n}Income']?.toString() ?? '';
        if (data.containsKey('fam${n}Health')) _famHealthCtrls[i].text = data['fam${n}Health']?.toString() ?? '';
        if (data.containsKey('fam${n}MentalHist')) _famMentalHistCtrls[i].text = data['fam${n}MentalHist']?.toString() ?? '';
        if (data.containsKey('fam${n}Addiction')) _famAddictionCtrls[i].text = data['fam${n}Addiction']?.toString() ?? '';
      }

      _schoolDropReasonPage2Ctrl.text = data['schoolDropReasonPage2']?.toString() ?? '';
      _familyInCrimeCtrl.text = data['familyInCrime']?.toString() ?? '';

      _habitsChecked['smoking'] = data['habit_smoking'] == true || data['habit_smoking'] == 'true';
      _habitsChecked['alcohol'] = data['habit_alcohol'] == true || data['habit_alcohol'] == 'true';
      _habitsChecked['gambling'] = data['habit_gambling'] == true || data['habit_gambling'] == 'true';
      _habitsChecked['begging'] = data['habit_begging'] == true || data['habit_begging'] == 'true';
      _habitsChecked['tobacco_pan'] = data['habit_tobacco_pan'] == true || data['habit_tobacco_pan'] == 'true';
      _habitOtherCtrl.text = data['habit_other']?.toString() ?? '';

      _hobbiesChecked['watching_tv'] = data['hobby_watching_tv'] == true || data['hobby_watching_tv'] == 'true';
      _hobbiesChecked['playing_games'] = data['hobby_playing_games'] == true || data['hobby_playing_games'] == 'true';
      _hobbiesChecked['reading_books'] = data['hobby_reading_books'] == true || data['hobby_reading_books'] == 'true';
      _hobbiesChecked['drawing'] = data['hobby_drawing'] == true || data['hobby_drawing'] == 'true';
      _hobbiesChecked['singing_art'] = data['hobby_singing_art'] == true || data['hobby_singing_art'] == 'true';
      _hobbyOtherCtrl.text = data['hobby_other']?.toString() ?? '';

      _childJobDetailsCtrl.text = data['childJobDetails']?.toString() ?? '';

      _incomeUsageDetailsCtrl.text = data['incomeUsageDetails']?.toString() ?? '';
      _incomeUsageFamilyCtrl.text = data['incomeUsageFamily']?.toString() ?? _incomeUsageFamilyCtrl.text;
      _incomeUsageSelfCtrl.text = data['incomeUsageSelf']?.toString() ?? _incomeUsageSelfCtrl.text;
      _incomeUsageClothesCtrl.text = data['incomeUsageClothes']?.toString() ?? _incomeUsageClothesCtrl.text;
      _incomeUsageGamblingCtrl.text = data['incomeUsageGambling']?.toString() ?? _incomeUsageGamblingCtrl.text;
      _incomeUsageAddictionCtrl.text = data['incomeUsageAddiction']?.toString() ?? _incomeUsageAddictionCtrl.text;
      _incomeUsageSavingsCtrl.text = data['incomeUsageSavings']?.toString() ?? _incomeUsageSavingsCtrl.text;

      _selectedEducationLevel = data['educationLevel']?.toString() ?? '';
      final savedReasons = data['schoolLeavingReasons'];
      if (savedReasons is List) {
        _schoolLeavingReasons.clear();
        _schoolLeavingReasons.addAll(savedReasons.map((e) => e.toString()));
      }
      _schoolLeavingOtherCtrl.text = data['schoolLeavingOther']?.toString() ?? '';
      _selectedSchoolType = data['schoolType']?.toString() ?? '';
      _vocationalTrainingCtrl.text = data['vocationalTraining']?.toString() ?? _vocationalTrainingCtrl.text;

      final savedFriends = data['friendTypes'];
      if (savedFriends is List) {
        _friendTypes.clear();
        _friendTypes.addAll(savedFriends.map((e) => e.toString()));
      }
      _friendsAddictedCtrl.text = data['friendsAddicted']?.toString() ?? _friendsAddictedCtrl.text;
      _friendsCriminalCtrl.text = data['friendsCriminal']?.toString() ?? _friendsCriminalCtrl.text;

      _childAbusedCtrl.text = data['childAbused']?.toString() ?? _childAbusedCtrl.text;
      _abuseVerbalCtrl.text = data['abuseVerbal']?.toString() ?? '';
      _abusePhysicalCtrl.text = data['abusePhysical']?.toString() ?? '';
      _abuseSexualCtrl.text = data['abuseSexual']?.toString() ?? '';
      _abuseOtherCtrl.text = data['abuseOther']?.toString() ?? '';

      _childVictimCtrl.text = data['childVictim']?.toString() ?? _childVictimCtrl.text;
      _childDrugCarrierCtrl.text = data['childDrugCarrier']?.toString() ?? _childDrugCarrierCtrl.text;
      _crimeReasonCtrl.text = data['crimeReason']?.toString() ?? '';
      _arrestCircumstancesCtrl.text = data['arrestCircumstances']?.toString() ?? '';
      _propertyFromChildCtrl.text = data['propertyFromChild']?.toString() ?? '';

      _childRoleInCrimeCtrl.text = data['childRoleInCrime']?.toString() ?? '';
      _cwpoInstructionsCtrl.text = data['cwpoInstructions']?.toString() ?? '';

      _signOfficerNameCtrl.text = data['signOfficerName']?.toString() ?? '';
      _signOfficerRankCtrl.text = data['signOfficerRank']?.toString() ?? '';
      _signOfficerBadgeCtrl.text = data['signOfficerBadge']?.toString() ?? '';
      _signOfficerPostingCtrl.text = data['signOfficerPosting']?.toString() ?? '';
    });
  }

  Map<String, dynamic> collectData() {
    final map = <String, dynamic>{
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'psDist': _psDistCtrl.text.trim(),
      'crimeNo': _crimeNoCtrl.text.trim(),
      'sectionAct': _sectionActCtrl.text.trim(),
      'crimeDateTime': _crimeDateTimeCtrl.text.trim(),
      'firDateTime': _firDateTimeCtrl.text.trim(),
      'ioName': _ioNameCtrl.text.trim(),
      'cwpoName': _cwpoNameCtrl.text.trim(),
      'childName': _childNameCtrl.text.trim(),
      'fatherName': _fatherNameCtrl.text.trim(),
      'dob': _dobCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'religion': _religionCtrl.text.trim(),
      'hasDisability': _hasDisabilityCtrl.text.trim(),
      'deaf': _deafCtrl.text.trim(),
      'dumb': _dumbCtrl.text.trim(),
      'physicalDisability': _physicalDisabilityCtrl.text.trim(),
      'mentalDisability': _mentalDisabilityCtrl.text.trim(),
      'otherDisability': _otherDisabilityCtrl.text.trim(),
      'familyRowCount': _familyRowCount,
      'schoolDropReasonPage2': _schoolDropReasonPage2Ctrl.text.trim(),
      'familyInCrime': _familyInCrimeCtrl.text.trim(),
      'habit_smoking': _habitsChecked['smoking'] ?? false,
      'habit_alcohol': _habitsChecked['alcohol'] ?? false,
      'habit_gambling': _habitsChecked['gambling'] ?? false,
      'habit_begging': _habitsChecked['begging'] ?? false,
      'habit_tobacco_pan': _habitsChecked['tobacco_pan'] ?? false,
      'habit_other': _habitOtherCtrl.text.trim(),
      'hobby_watching_tv': _hobbiesChecked['watching_tv'] ?? false,
      'hobby_playing_games': _hobbiesChecked['playing_games'] ?? false,
      'hobby_reading_books': _hobbiesChecked['reading_books'] ?? false,
      'hobby_drawing': _hobbiesChecked['drawing'] ?? false,
      'hobby_singing_art': _hobbiesChecked['singing_art'] ?? false,
      'hobby_other': _hobbyOtherCtrl.text.trim(),
      'childJobDetails': _childJobDetailsCtrl.text.trim(),
      'incomeUsageDetails': _incomeUsageDetailsCtrl.text.trim(),
      'incomeUsageFamily': _incomeUsageFamilyCtrl.text.trim(),
      'incomeUsageSelf': _incomeUsageSelfCtrl.text.trim(),
      'incomeUsageClothes': _incomeUsageClothesCtrl.text.trim(),
      'incomeUsageGambling': _incomeUsageGamblingCtrl.text.trim(),
      'incomeUsageAddiction': _incomeUsageAddictionCtrl.text.trim(),
      'incomeUsageSavings': _incomeUsageSavingsCtrl.text.trim(),
      'educationLevel': _selectedEducationLevel,
      'schoolLeavingReasons': _schoolLeavingReasons.toList(),
      'schoolLeavingOther': _schoolLeavingOtherCtrl.text.trim(),
      'schoolType': _selectedSchoolType,
      'vocationalTraining': _vocationalTrainingCtrl.text.trim(),
      'friendTypes': _friendTypes.toList(),
      'friendsAddicted': _friendsAddictedCtrl.text.trim(),
      'friendsCriminal': _friendsCriminalCtrl.text.trim(),
      'childAbused': _childAbusedCtrl.text.trim(),
      'abuseVerbal': _abuseVerbalCtrl.text.trim(),
      'abusePhysical': _abusePhysicalCtrl.text.trim(),
      'abuseSexual': _abuseSexualCtrl.text.trim(),
      'abuseOther': _abuseOtherCtrl.text.trim(),
      'childVictim': _childVictimCtrl.text.trim(),
      'childDrugCarrier': _childDrugCarrierCtrl.text.trim(),
      'crimeReason': _crimeReasonCtrl.text.trim(),
      'arrestCircumstances': _arrestCircumstancesCtrl.text.trim(),
      'propertyFromChild': _propertyFromChildCtrl.text.trim(),
      'childRoleInCrime': _childRoleInCrimeCtrl.text.trim(),
      'cwpoInstructions': _cwpoInstructionsCtrl.text.trim(),
      'signOfficerName': _signOfficerNameCtrl.text.trim(),
      'signOfficerRank': _signOfficerRankCtrl.text.trim(),
      'signOfficerBadge': _signOfficerBadgeCtrl.text.trim(),
      'signOfficerPosting': _signOfficerPostingCtrl.text.trim(),
    };

    for (var i = 0; i < _familyRowCount; i++) {
      final n = '${i + 1}';
      map['fam${n}Name'] = _famNameRelationCtrls[i].text.trim();
      map['fam${n}Age'] = _famAgeCtrls[i].text.trim();
      map['fam${n}Sex'] = _famSexCtrls[i].text.trim();
      map['fam${n}Edu'] = _famEduCtrls[i].text.trim();
      map['fam${n}Occ'] = _famOccCtrls[i].text.trim();
      map['fam${n}Income'] = _famIncomeCtrls[i].text.trim();
      map['fam${n}Health'] = _famHealthCtrls[i].text.trim();
      map['fam${n}MentalHist'] = _famMentalHistCtrls[i].text.trim();
      map['fam${n}Addiction'] = _famAddictionCtrls[i].text.trim();
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
      padding: const EdgeInsets.all(5),
      child: Text(
        text,
        style: serifStyle.copyWith(fontSize: 9.5, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _bulletOption({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
    required TextStyle style,
  }) {
    return InkWell(
      onTap: widget.readOnly ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.arrow_right,
              size: 18,
              color: isSelected ? const Color(0xFF1E3A8A) : Colors.black87,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: style.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF1E3A8A) : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle serifStyle = FormTypography.serifStyle();
    final TextStyle marathiLabelStyle = FormTypography.marathiLabelStyle();

    const marathiNumbers = ['१', '२', '३', '४', '५', '६', '७', '८', '९', '१०', '११', '१२'];

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        // ──────────────────────────────────────────────────────────────────
        // PHASE CLASSIFICATION SELECTOR BAR
        // ──────────────────────────────────────────────────────────────────
        _buildPhaseSelector(),

        // ══════════════════════════════════════════════════════════════════
        // PHASE 1 / PAGE 1 — SECTIONS 1 TO 7 & CHILD PARTICULARS
        // ══════════════════════════════════════════════════════════════════
        if (_shows(kPartI))
          FormPaperPage(
            formLabel: 'Page : 1 (Phase 1 — Personal)',
            children: [
              Center(
                child: Text(
                  '—:: विधीसंघर्षग्रस्त बालक याचा सामाजीक पार्श्वभुमी अहवाल ::—',
                  style: GoogleFonts.notoSansDevanagari(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              Table(
                border: TableBorder.all(color: Colors.black87),
                columnWidths: const {
                  0: FixedColumnWidth(44),
                  1: FlexColumnWidth(2.2),
                  2: FlexColumnWidth(3.8),
                },
                children: [
                  TableRow(
                    children: [
                      _tableHeader('अ.क्र.', serifStyle),
                      _tableHeader('विवरण', serifStyle),
                      _tableHeader('माहिती', serifStyle),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableHeader('1.', serifStyle),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text('पोलीस स्टेशन व जिल्हा', style: marathiLabelStyle),
                      ),
                      _tableCellInput(_psDistCtrl, serifStyle),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableHeader('2.', serifStyle),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text('अपराध क्रमांक', style: marathiLabelStyle),
                      ),
                      _tableCellInput(_crimeNoCtrl, serifStyle),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableHeader('3.', serifStyle),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text('कलम व अधिनियम', style: marathiLabelStyle),
                      ),
                      _tableCellInput(_sectionActCtrl, serifStyle),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableHeader('4.', serifStyle),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text('बालकास ताब्यात घेतल्याची तारीख व वेळ', style: marathiLabelStyle),
                      ),
                      _tableCellInput(_crimeDateTimeCtrl, serifStyle),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableHeader('5.', serifStyle),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text('बालकास बाल न्याय मंडळ/ बाल कल्याण समिती समोर हजर केल्याची तारीख व वेळ', style: marathiLabelStyle),
                      ),
                      _tableCellInput(_firDateTimeCtrl, serifStyle),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableHeader('6.', serifStyle),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text('तपास अंमलदाराचे नांव व हुद्दा', style: marathiLabelStyle),
                      ),
                      _tableCellInput(_ioNameCtrl, serifStyle),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableHeader('7.', serifStyle),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text('बाल कल्याण पोलीस अधिकारी यांचे नांव व हुद्दा', style: marathiLabelStyle),
                      ),
                      _tableCellInput(_cwpoNameCtrl, serifStyle),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Text(
                'बालकाचा तपशिल',
                style: marathiLabelStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('१) बालकाचे नाव :- ', style: marathiLabelStyle),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _childNameCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('२) बालकाचे वडिलांचे नाव व पत्ता :- ', style: marathiLabelStyle),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _fatherNameCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('३) जन्म तारीख व वय :- ', style: marathiLabelStyle),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _dobCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('४) सध्याचा पत्ता / कायमचा पत्ता :- ', style: marathiLabelStyle),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _addressCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('५) धर्म व जात (अ.जा./ अ.ज./ इ.मा.व./ इतर / खुला ) :- ', style: marathiLabelStyle),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _religionCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text('६) बालकामध्ये काही अपंगत्व / व्यंगत्व आहे काय ?', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),

              Table(
                border: TableBorder.all(color: Colors.black87),
                columnWidths: const {
                  0: FixedColumnWidth(36),
                  1: FlexColumnWidth(2.5),
                  2: FlexColumnWidth(3.5),
                },
                children: [
                  TableRow(
                    children: [
                      _tableHeader('अ.क्र.', serifStyle),
                      _tableHeader('अपंगत्व प्रकार', serifStyle),
                      _tableHeader('होय / नाही', serifStyle),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableHeader('1.', serifStyle),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text('अंधत्व', style: marathiLabelStyle),
                      ),
                      _tableCellInput(_hasDisabilityCtrl, serifStyle),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableHeader('2.', serifStyle),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text('कर्णबधीर', style: marathiLabelStyle),
                      ),
                      _tableCellInput(_deafCtrl, serifStyle),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableHeader('3.', serifStyle),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text('मुक', style: marathiLabelStyle),
                      ),
                      _tableCellInput(_dumbCtrl, serifStyle),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableHeader('4.', serifStyle),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text('शारीरीक अपंगत्व', style: marathiLabelStyle),
                      ),
                      _tableCellInput(_physicalDisabilityCtrl, serifStyle),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableHeader('5.', serifStyle),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text('मानसीक अपंगत्व', style: marathiLabelStyle),
                      ),
                      _tableCellInput(_mentalDisabilityCtrl, serifStyle),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableHeader('6.', serifStyle),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text('इतर', style: marathiLabelStyle),
                      ),
                      _tableCellInput(_otherDisabilityCtrl, serifStyle),
                    ],
                  ),
                ],
              ),

              if (!_showAll)
                _buildPhaseNavigationFooter(
                  onNext: () => setState(() => _activePhase = kPartII),
                  nextLabel: 'Go to Phase 2 (Family) →',
                ),
            ],
          ),

        if (_shows(kPartI) && (_shows(kPartII) || _showAll))
          const SizedBox(height: 24),

        // ══════════════════════════════════════════════════════════════════
        // PHASE 2 / PAGE 2 — SECTIONS 8 TO 12 (Family Table, Habits)
        // ══════════════════════════════════════════════════════════════════
        if (_shows(kPartII))
          FormPaperPage(
            formLabel: 'Page : 2 (Phase 2 — Family)',
            children: [
              Text(
                '७) बालकाच्या कुटुंबाचा तपशिल :-',
                style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Dynamic 10-column table
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  border: TableBorder.all(color: Colors.black87),
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                      children: [
                        _tableHeader('अ.क्र.', serifStyle),
                        _tableHeader('नाते संबंध', serifStyle),
                        _tableHeader('वय', serifStyle),
                        _tableHeader('लिंग', serifStyle),
                        _tableHeader('शिक्षण', serifStyle),
                        _tableHeader('व्यवसाय', serifStyle),
                        _tableHeader('मासिक उत्पन्न', serifStyle),
                        _tableHeader('आरोग्य स्थिती', serifStyle),
                        _tableHeader('मानसिक स्थिती', serifStyle),
                        _tableHeader('व्यसन प्रकार', serifStyle),
                      ],
                    ),
                    for (int i = 0; i < _familyRowCount; i++)
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(
                              i < marathiNumbers.length ? marathiNumbers[i] : '${i + 1}',
                              style: serifStyle.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(
                            width: 140,
                            child: _tableCellInput(_famNameRelationCtrls[i], serifStyle),
                          ),
                          SizedBox(
                            width: 50,
                            child: _tableCellInput(_famAgeCtrls[i], serifStyle, align: TextAlign.center),
                          ),
                          SizedBox(
                            width: 80,
                            child: _tableCellInput(_famSexCtrls[i], serifStyle, align: TextAlign.center),
                          ),
                          SizedBox(
                            width: 90,
                            child: _tableCellInput(_famEduCtrls[i], serifStyle),
                          ),
                          SizedBox(
                            width: 100,
                            child: _tableCellInput(_famOccCtrls[i], serifStyle),
                          ),
                          SizedBox(
                            width: 80,
                            child: _tableCellInput(_famIncomeCtrls[i], serifStyle),
                          ),
                          SizedBox(
                            width: 90,
                            child: _tableCellInput(_famHealthCtrls[i], serifStyle),
                          ),
                          SizedBox(
                            width: 90,
                            child: _tableCellInput(_famMentalHistCtrls[i], serifStyle),
                          ),
                          SizedBox(
                            width: 90,
                            child: _tableCellInput(_famAddictionCtrls[i], serifStyle),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              if (!widget.readOnly)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _familyRowCount++;
                          _famNameRelationCtrls.add(TextEditingController());
                          _famAgeCtrls.add(TextEditingController());
                          _famSexCtrls.add(TextEditingController(text: 'स्त्रि/ पुरूष'));
                          _famEduCtrls.add(TextEditingController());
                          _famOccCtrls.add(TextEditingController());
                          _famIncomeCtrls.add(TextEditingController());
                          _famHealthCtrls.add(TextEditingController());
                          _famMentalHistCtrls.add(TextEditingController());
                          _famAddictionCtrls.add(TextEditingController());
                        });
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: Text('+ ओळ जोडा (Add Row)', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    if (_familyRowCount > 1) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _familyRowCount--;
                            _famNameRelationCtrls.removeLast().dispose();
                            _famAgeCtrls.removeLast().dispose();
                            _famSexCtrls.removeLast().dispose();
                            _famEduCtrls.removeLast().dispose();
                            _famOccCtrls.removeLast().dispose();
                            _famIncomeCtrls.removeLast().dispose();
                            _famHealthCtrls.removeLast().dispose();
                            _famMentalHistCtrls.removeLast().dispose();
                            _famAddictionCtrls.removeLast().dispose();
                          });
                        },
                        icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.red),
                        label: Text('ओळ काढा (Remove)', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.red)),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('८) बालक शिकत असल्यास शाळेत जाणे का बंद केले :- ', style: marathiLabelStyle),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _schoolDropReasonPage2Ctrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('९) कुटुंबातील इतर व्यक्तीवर काही गुन्हे दाखल आहेत का :- ', style: marathiLabelStyle),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _familyInCrimeCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text('१०) बालकाच्या सवयी व छंद :-', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),

              Table(
                border: TableBorder.all(color: Colors.black87),
                columnWidths: const {
                  0: FixedColumnWidth(34),
                  1: FlexColumnWidth(1),
                  2: FixedColumnWidth(34),
                  3: FlexColumnWidth(1),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                    children: [
                      _tableHeader('अ', serifStyle),
                      _tableHeader('बालकाच्या सवयी', serifStyle),
                      _tableHeader('ब', serifStyle),
                      _tableHeader('बालकाचे छंद', serifStyle),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableHeader('1.', serifStyle),
                      _buildCheckboxCell('धुम्रपान करणे', 'smoking', _habitsChecked, marathiLabelStyle),
                      _tableHeader('1.', serifStyle),
                      _buildCheckboxCell('टी.व्ही. पाहणे', 'watching_tv', _hobbiesChecked, marathiLabelStyle),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableHeader('2.', serifStyle),
                      _buildCheckboxCell('मद्यपान करणे', 'alcohol', _habitsChecked, marathiLabelStyle),
                      _tableHeader('2.', serifStyle),
                      _buildCheckboxCell('मैदानी खेळ खेळणे', 'playing_games', _hobbiesChecked, marathiLabelStyle),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableHeader('3.', serifStyle),
                      _buildCheckboxCell('जुगार खेळणे', 'gambling', _habitsChecked, marathiLabelStyle),
                      _tableHeader('3.', serifStyle),
                      _buildCheckboxCell('पुस्तके वाचणे', 'reading_books', _hobbiesChecked, marathiLabelStyle),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableHeader('4.', serifStyle),
                      _buildCheckboxCell('भीक मागणे', 'begging', _habitsChecked, marathiLabelStyle),
                      _tableHeader('4.', serifStyle),
                      _buildCheckboxCell('चित्रे काढणे', 'drawing', _hobbiesChecked, marathiLabelStyle),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableHeader('5.', serifStyle),
                      _buildCheckboxCell('तंबाखु/पान खाणे', 'tobacco_pan', _habitsChecked, marathiLabelStyle),
                      _tableHeader('5.', serifStyle),
                      _buildCheckboxCell('गायन/कला', 'singing_art', _hobbiesChecked, marathiLabelStyle),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableHeader('6.', serifStyle),
                      _tableCellInput(_habitOtherCtrl, serifStyle),
                      _tableHeader('6.', serifStyle),
                      _tableCellInput(_hobbyOtherCtrl, serifStyle),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('११) बालकाचे नोकरीचा तपशील :- ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _childJobDetailsCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),

              if (!_showAll)
                _buildPhaseNavigationFooter(
                  onPrev: () => setState(() => _activePhase = kPartI),
                  prevLabel: '← Phase 1 (Personal)',
                  onNext: () => setState(() => _activePhase = kPartIII),
                  nextLabel: 'Go to Phase 3 (Social) →',
                ),
            ],
          ),

        if (_shows(kPartII) && (_shows(kPartIII) || _showAll))
          const SizedBox(height: 24),

        // ══════════════════════════════════════════════════════════════════
        // PHASE 3 / PAGE 3 — SECTIONS 13 TO 17 (Income, Education & Drop reasons)
        // ══════════════════════════════════════════════════════════════════
        if (_shows(kPartIII))
          FormPaperPage(
            formLabel: 'Page : 3 (Phase 3 — Social)',
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('१३) उत्पन्न वापराचा तपशिल :- ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _incomeUsageDetailsCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              _buildInlineToggleRow('➤ कौटुंबीक गरजा भागविण्यासाठी', _incomeUsageFamilyCtrl, marathiLabelStyle, serifStyle),
              _buildInlineToggleRow('➤ स्वतः साठी', _incomeUsageSelfCtrl, marathiLabelStyle, serifStyle),
              _buildInlineToggleRow('➤ कपडे खरेदी करीता', _incomeUsageClothesCtrl, marathiLabelStyle, serifStyle),
              _buildInlineToggleRow('➤ जुगार खेळण्यासाठी', _incomeUsageGamblingCtrl, marathiLabelStyle, serifStyle),
              _buildInlineToggleRow('➤ व्यसन नशा करण्याकरीता', _incomeUsageAddictionCtrl, marathiLabelStyle, serifStyle),
              _buildInlineToggleRow('➤ साठविणेसाठी', _incomeUsageSavingsCtrl, marathiLabelStyle, serifStyle),
              const SizedBox(height: 12),

              Text('१४) बालकाची शैक्षणीक माहिती   :-', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              for (final level in [
                'अशिक्षीत',
                'ईयत्ता ५ वी पर्यत',
                'ईयत्ता ५ वी पेक्षा जास्त परंतु ८ वी पर्यत',
                'ईयत्ता ८ वी पेक्षा जास्त परंतु १० वी पेक्षा कमी',
                'ईयत्ता १० वी पेक्षा जास्त परंतु १२ वी पेक्षा कमी',
                'ईयता १२ वी पेक्षा जास्त',
              ])
                _bulletOption(
                  text: '➤ $level',
                  isSelected: _selectedEducationLevel == level,
                  onTap: () => setState(() => _selectedEducationLevel = level),
                  style: marathiLabelStyle,
                ),
              const SizedBox(height: 12),

              Text('१५) शाळा सोडल्याचे कारण :-', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              for (final r in [
                'नापास झाल्यामुळे',
                'शालेय शिक्षणाची आवड कमी असल्यामुळे',
                'शिक्षणाचा बेपर्वा दृष्टीकोण असल्यामुळे',
                'सहकारी मुलांचे प्रभावामुळे',
                'कुटुंबाला आर्थीक मदत करण्यासाठी',
                'पालकांच्या अचानक मृत्युमुळे',
                'शाळेतील कडक/ शिस्तीचे वातावरणामुळे',
                'शाळेतील सततची अनुपस्थीती/ पळुन जाने',
                'वयाशी जुळणारी शाळा उपलब्ध नाही',
                'शाळेत छट अत्याचार गैरव्यवहार झाल्यामुळे',
                'शाळेमध्ये जाचक शिक्षा झाल्यामुळे',
                'शिकविण्याची भाषा',
              ])
                _bulletOption(
                  text: '➤ $r',
                  isSelected: _schoolLeavingReasons.contains(r),
                  onTap: () => setState(() {
                    if (_schoolLeavingReasons.contains(r)) {
                      _schoolLeavingReasons.remove(r);
                    } else {
                      _schoolLeavingReasons.add(r);
                    }
                  }),
                  style: marathiLabelStyle,
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('➤ इतर : ', style: marathiLabelStyle),
                  Expanded(
                    child: BilingualSimpleUnderlineInput(
                      controller: _schoolLeavingOtherCtrl,
                      serifStyle: serifStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text('१६) बालक शिकलेल्या शाळेचा तपशिल :-', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              for (final s in [
                'महानगरपालीका/ नगरपालीका/ पंचायत',
                'शासकीय',
                'खाजगी व्यवस्थापकीय',
                'राष्ट्रीय बाल प्रकल्प अंतर्गत शाळा',
              ])
                _bulletOption(
                  text: '➤ $s',
                  isSelected: _selectedSchoolType == s,
                  onTap: () => setState(() => _selectedSchoolType = s),
                  style: marathiLabelStyle,
                ),
              const SizedBox(height: 10),

              _buildInlineToggleRow('१७) व्यावसायीक प्रशिक्षण', _vocationalTrainingCtrl, marathiLabelStyle, serifStyle),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.bottomRight,
                child: Text('M.R.W', style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 10)),
              ),

              if (!_showAll)
                _buildPhaseNavigationFooter(
                  onPrev: () => setState(() => _activePhase = kPartII),
                  prevLabel: '← Phase 2 (Family)',
                  onNext: () => setState(() => _activePhase = kPartIV),
                  nextLabel: 'Go to Phase 4 (Reports & Signatures) →',
                ),
            ],
          ),

        if (_shows(kPartIII) && (_shows(kPartIV) || _showAll))
          const SizedBox(height: 24),

        // ══════════════════════════════════════════════════════════════════
        // PHASE 4 / PAGE 4 — SECTIONS 18 TO 24 (Friends, Abuse, Arrest Details)
        // ══════════════════════════════════════════════════════════════════
        if (_shows(kPartIV))
          FormPaperPage(
            formLabel: 'Page : 4 (Phase 4 — Reports & Circumstances)',
            children: [
              Text('१८) कोणत्या प्रकारचे मित्र जास्त आहेत :-', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              for (final f in [
                'शिक्षीत',
                'अशिक्षीत',
                'समवयस्क',
                'बालका पेक्षा वयाने लहान',
                'पुरूष मित्र नाही',
                'मैत्रीनी',
              ])
                _bulletOption(
                  text: '➤ $f',
                  isSelected: _friendTypes.contains(f),
                  onTap: () => setState(() {
                    if (_friendTypes.contains(f)) {
                      _friendTypes.remove(f);
                    } else {
                      _friendTypes.add(f);
                    }
                  }),
                  style: marathiLabelStyle,
                ),
              _buildInlineToggleRow('➤ व्यसनी', _friendsAddictedCtrl, marathiLabelStyle, serifStyle),
              _buildInlineToggleRow('➤ गुन्हेगारी पार्श्वभुमी असणारे', _friendsCriminalCtrl, marathiLabelStyle, serifStyle),
              const SizedBox(height: 12),

              _buildInlineToggleRow('१९) बालकावर कोणत्या प्रकारचा छळ अत्याचार झाला आहे काय ?', _childAbusedCtrl, marathiLabelStyle, serifStyle),
              const SizedBox(height: 6),

              Table(
                border: TableBorder.all(color: Colors.black87),
                columnWidths: const {
                  0: FixedColumnWidth(36),
                  1: FlexColumnWidth(2.8),
                  2: FlexColumnWidth(3.2),
                },
                children: [
                  TableRow(
                    children: [
                      _tableHeader('अ.क्र.', serifStyle),
                      _tableHeader('छळ अत्याचार प्रकार', serifStyle),
                      _tableHeader('शेरा', serifStyle),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableHeader('1.', serifStyle),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text('शाब्दीक छळ— पालक/ भावंडे/ नियोक्ता/ इतर नमुद करा', style: marathiLabelStyle),
                      ),
                      _tableCellInput(_abuseVerbalCtrl, serifStyle),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableHeader('2.', serifStyle),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text('शारीरीक छळ — नमुद करा', style: marathiLabelStyle),
                      ),
                      _tableCellInput(_abusePhysicalCtrl, serifStyle),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableHeader('3.', serifStyle),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text('लैंगीक छळ — पालक/ भावंडे/ नियोक्ता/ इतर नमुद करा', style: marathiLabelStyle),
                      ),
                      _tableCellInput(_abuseSexualCtrl, serifStyle),
                    ],
                  ),
                  TableRow(
                    children: [
                      _tableHeader('4.', serifStyle),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text('इतर — नमुद करा', style: marathiLabelStyle),
                      ),
                      _tableCellInput(_abuseOtherCtrl, serifStyle),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildInlineToggleRow('२०) बालक कोणत्या गुन्ह्यांचा बळी Victim आहे काय', _childVictimCtrl, marathiLabelStyle, serifStyle),
              const SizedBox(height: 8),

              _buildInlineToggleRow('२१) प्रौढ/ प्रौढांचा गट नशेचे साहित्य वाहतुकीसाठी बालकाचा वापर करतात काय ?', _childDrugCarrierCtrl, marathiLabelStyle, serifStyle),
              const SizedBox(height: 12),

              Text(
                '२२) बालकाचा आरोप असलेल्या गुन्ह्यामागे कारण जसे की, पालकाकडून दुर्लक्ष, सहकारी मित्राचा प्रभाव :-',
                style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              BilingualSimpleUnderlineInput(
                controller: _crimeReasonCtrl,
                serifStyle: serifStyle,
              ),
              const SizedBox(height: 10),

              Text('२३) कोणत्या परिस्थितीत / घटनेमध्ये बालकास पकडले आहे :-', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              BilingualSimpleUnderlineInput(
                controller: _arrestCircumstancesCtrl,
                serifStyle: serifStyle,
              ),
              const SizedBox(height: 10),

              Text('२४) बालकाकडुन मिळालेल्या मालमत्तेची माहिती :-', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              BilingualSimpleUnderlineInput(
                controller: _propertyFromChildCtrl,
                serifStyle: serifStyle,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.bottomRight,
                child: Text('M.R.W', style: serifStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),

        if (_shows(kPartIV) && (_shows(kPartV) || _showAll))
          const SizedBox(height: 24),

        // ══════════════════════════════════════════════════════════════════
        // PHASE 4 / PAGE 5 — SECTIONS 25 TO 26 & SIGNATURE ENTRY
        // ══════════════════════════════════════════════════════════════════
        if (_shows(kPartV))
          FormPaperPage(
            formLabel: 'Page : 5 (Phase 4 — Role & Signatures)',
            children: [
              Text('२५) बालकावर आरोप असलेल्या गुन्ह्यामध्ये बालकाची भुमीका :-', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 11.5)),
              const SizedBox(height: 4),
              BilingualSimpleUnderlineInput(
                controller: _childRoleInCrimeCtrl,
                serifStyle: serifStyle,
              ),
              const SizedBox(height: 20),

              Text('२६) बाल कल्याण पोलीस अधिकारी मार्फत बालका बाबत सुचना :-', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 11.5)),
              const SizedBox(height: 4),
              BilingualSimpleUnderlineInput(
                controller: _cwpoInstructionsCtrl,
                serifStyle: serifStyle,
              ),
              const SizedBox(height: 80),

              // Signature Block
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 320,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'अन्वेषण अधिकारी सही',
                          style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('नांव :- ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: BilingualSimpleUnderlineInput(
                              controller: _signOfficerNameCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('पद :- ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: BilingualSimpleUnderlineInput(
                              controller: _signOfficerRankCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                          Text('-ब.नं. ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          SizedBox(
                            width: 60,
                            child: BilingualSimpleUnderlineInput(
                              controller: _signOfficerBadgeCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('नेमणुक :- ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: BilingualSimpleUnderlineInput(
                              controller: _signOfficerPostingCtrl,
                              serifStyle: serifStyle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              if (!_showAll)
                _buildPhaseNavigationFooter(
                  onPrev: () => setState(() => _activePhase = kPartIII),
                  prevLabel: '← Phase 3 (Social)',
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildPhaseSelector() {
    final phases = [
      {'id': kPartI, 'label': 'Phase 1: Part I (Personal)', 'page': 'Page 1'},
      {'id': kPartII, 'label': 'Phase 2: Part II (Family)', 'page': 'Page 2'},
      {'id': kPartIII, 'label': 'Phase 3: Part III (Social)', 'page': 'Page 3'},
      {'id': kPartIV, 'label': 'Phase 4: Part IV (Reports & Signatures)', 'page': 'Pages 4–5'},
      {'id': 'ALL', 'label': 'All Phases (Pages 1–5)', 'page': 'All'},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD6E4F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: phases.map((phase) {
            final isSelected = phase['id'] == 'ALL'
                ? _showAll
                : _activePhase == phase['id'];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: ChoiceChip(
                label: Text(
                  '${phase['label']}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF1E3A8A),
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF1E3A8A),
                backgroundColor: const Color(0xFFF1F5F9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFCBD5E1),
                  ),
                ),
                onSelected: (selected) {
                  setState(() {
                    _activePhase = phase['id'];
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPhaseNavigationFooter({
    VoidCallback? onPrev,
    String? prevLabel,
    VoidCallback? onNext,
    String? nextLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (onPrev != null)
            ElevatedButton.icon(
              onPressed: onPrev,
              icon: const Icon(Icons.arrow_back, size: 15),
              label: Text(prevLabel ?? 'Previous', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1E3A8A),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            )
          else
            const SizedBox.shrink(),
          if (onNext != null)
            ElevatedButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward, size: 15),
              label: Text(nextLabel ?? 'Next Phase', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildInlineToggleRow(
    String label,
    TextEditingController ctrl,
    TextStyle marathiStyle,
    TextStyle serifStyle,
  ) {
    final val = ctrl.text.trim();
    final isHoy = val == 'होय';
    final isNahi = val == 'नाही' || val.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: marathiStyle)),
          const Text(' :-  ', style: TextStyle(fontWeight: FontWeight.bold)),
          if (widget.readOnly)
            Text(val.isEmpty ? 'नाही' : val, style: marathiStyle.copyWith(fontWeight: FontWeight.bold))
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => setState(() => ctrl.text = 'होय'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isHoy ? const Color(0xFF1E3A8A) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'होय',
                      style: marathiStyle.copyWith(
                        color: isHoy ? Colors.white : Colors.black87,
                        fontWeight: isHoy ? FontWeight.bold : FontWeight.normal,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('/'),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => setState(() => ctrl.text = 'नाही'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isNahi ? const Color(0xFF1E3A8A) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'नाही',
                      style: marathiStyle.copyWith(
                        color: isNahi ? Colors.white : Colors.black87,
                        fontWeight: isNahi ? FontWeight.bold : FontWeight.normal,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCheckboxCell(
    String label,
    String key,
    Map<String, bool> map,
    TextStyle marathiStyle,
  ) {
    final checked = map[key] ?? false;
    return InkWell(
      onTap: widget.readOnly
          ? null
          : () => setState(() => map[key] = !checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            Icon(
              checked ? Icons.check_box : Icons.check_box_outline_blank,
              size: 16,
              color: checked ? const Color(0xFF1E3A8A) : Colors.black54,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: marathiStyle.copyWith(
                  fontWeight: checked ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
