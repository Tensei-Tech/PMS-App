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
        // ══════════════════════════════════════════════════════════════════
        // PAGE 1 — SECTIONS 1 TO 7 & CHILD PARTICULARS
        // ══════════════════════════════════════════════════════════════════
        FormPaperPage(
          formLabel: 'Page : 1',
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
                      child: Text('गुन्हा घडला ता व वेळ', style: marathiLabelStyle),
                    ),
                    _tableCellInput(_crimeDateTimeCtrl, serifStyle),
                  ],
                ),
                TableRow(
                  children: [
                    _tableHeader('5.', serifStyle),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('गुन्हा दाखल ता व वेळ', style: marathiLabelStyle),
                    ),
                    _tableCellInput(_firDateTimeCtrl, serifStyle),
                  ],
                ),
                TableRow(
                  children: [
                    _tableHeader('6.', serifStyle),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('तपासी अधिकारी यांचे नांव', style: marathiLabelStyle),
                    ),
                    _tableCellInput(_ioNameCtrl, serifStyle),
                  ],
                ),
                TableRow(
                  children: [
                    _tableHeader('7.', serifStyle),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('बाल कल्याण पोलीस अधिकारी नांव', style: marathiLabelStyle),
                    ),
                    _tableCellInput(_cwpoNameCtrl, serifStyle),
                  ],
                ),
                TableRow(
                  children: [
                    const SizedBox(),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('बालक', style: marathiLabelStyle),
                    ),
                    _tableCellInput(_childNameCtrl, serifStyle),
                  ],
                ),
                TableRow(
                  children: [
                    const SizedBox(),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('वडील', style: marathiLabelStyle),
                    ),
                    _tableCellInput(_fatherNameCtrl, serifStyle),
                  ],
                ),
                TableRow(
                  children: [
                    const SizedBox(),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('जन्म तारीख', style: marathiLabelStyle),
                    ),
                    _tableCellInput(_dobCtrl, serifStyle),
                  ],
                ),
                TableRow(
                  children: [
                    const SizedBox(),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('पत्ता', style: marathiLabelStyle),
                    ),
                    _tableCellInput(_addressCtrl, serifStyle),
                  ],
                ),
                TableRow(
                  children: [
                    const SizedBox(),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('धर्म', style: marathiLabelStyle),
                    ),
                    _tableCellInput(_religionCtrl, serifStyle),
                  ],
                ),
                TableRow(
                  children: [
                    const SizedBox(),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('बालकास अपंगत्व आहे काय ?', style: marathiLabelStyle),
                    ),
                    _tableCellInput(_hasDisabilityCtrl, serifStyle),
                  ],
                ),
                TableRow(
                  children: [
                    const SizedBox(),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('कर्णबधीर', style: marathiLabelStyle),
                    ),
                    _tableCellInput(_deafCtrl, serifStyle),
                  ],
                ),
                TableRow(
                  children: [
                    const SizedBox(),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('मुक', style: marathiLabelStyle),
                    ),
                    _tableCellInput(_dumbCtrl, serifStyle),
                  ],
                ),
                TableRow(
                  children: [
                    const SizedBox(),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('शारीरीक अपंगत्व', style: marathiLabelStyle),
                    ),
                    _tableCellInput(_physicalDisabilityCtrl, serifStyle),
                  ],
                ),
                TableRow(
                  children: [
                    const SizedBox(),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('मानसीक अपंगत्व', style: marathiLabelStyle),
                    ),
                    _tableCellInput(_mentalDisabilityCtrl, serifStyle),
                  ],
                ),
                TableRow(
                  children: [
                    const SizedBox(),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text('इतर', style: marathiLabelStyle),
                    ),
                    _tableCellInput(_otherDisabilityCtrl, serifStyle),
                  ],
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ══════════════════════════════════════════════════════════════════
        // PAGE 2 — SECTIONS 8 TO 12 (Family Table, Drop reasons, Habits)
        // ══════════════════════════════════════════════════════════════════
        FormPaperPage(
          formLabel: 'Page : 2',
          children: [
            Text(
              '८) कौटुंबीक माहिती :-',
              style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 6),

            Table(
              border: TableBorder.all(color: Colors.black87),
              columnWidths: const {
                0: FixedColumnWidth(28),
                1: FlexColumnWidth(1.8),
                2: FixedColumnWidth(34),
                3: FixedColumnWidth(55),
                4: FlexColumnWidth(1.2),
                5: FlexColumnWidth(1.2),
                6: FlexColumnWidth(1.1),
                7: FlexColumnWidth(1.2),
                8: FlexColumnWidth(1.4),
                9: FlexColumnWidth(1.4),
              },
              children: [
                TableRow(
                  children: [
                    _tableHeader('अ.क्र', serifStyle),
                    _tableHeader('नांव व नाते', serifStyle),
                    _tableHeader('वय', serifStyle),
                    _tableHeader('लिंग', serifStyle),
                    _tableHeader('शिक्षण', serifStyle),
                    _tableHeader('व्यवसाय', serifStyle),
                    _tableHeader('उत्पन्न', serifStyle),
                    _tableHeader('आरोग्य\nस्थिती', serifStyle),
                    _tableHeader('मनसिक आजाराचा\nइतिहास असल्यास', serifStyle),
                    _tableHeader('व्यसनाधिनता\nअसल्यास', serifStyle),
                  ],
                ),
                for (var i = 0; i < _familyRowCount; i++)
                  TableRow(
                    children: [
                      _tableHeader(i < marathiNumbers.length ? marathiNumbers[i] : '${i + 1}', serifStyle),
                      _tableCellInput(_famNameRelationCtrls[i], serifStyle),
                      _tableCellInput(_famAgeCtrls[i], serifStyle, align: TextAlign.center),
                      _tableCellInput(_famSexCtrls[i], serifStyle, align: TextAlign.center),
                      _tableCellInput(_famEduCtrls[i], serifStyle),
                      _tableCellInput(_famOccCtrls[i], serifStyle),
                      _tableCellInput(_famIncomeCtrls[i], serifStyle),
                      _tableCellInput(_famHealthCtrls[i], serifStyle),
                      _tableCellInput(_famMentalHistCtrls[i], serifStyle),
                      _tableCellInput(_famAddictionCtrls[i], serifStyle),
                    ],
                  ),
              ],
            ),
            if (!widget.readOnly) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
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
                    icon: const Icon(Icons.add, size: 14, color: Color(0xFF1E3A8A)),
                    label: Text('Add Member (सदस्य जोडा)', style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF1E3A8A))),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFF4FA),
                      side: const BorderSide(color: Color(0xFFD6E4F0), width: 1),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('९) शाळा सोडल्याचे कारण :- ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _schoolDropReasonPage2Ctrl,
                    serifStyle: serifStyle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('१०) कुटुंब सदस्य यांचा गुन्ह्यामध्ये सहभाग आहे काय :- ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _familyInCrimeCtrl,
                    serifStyle: serifStyle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text('११) बालकाला असलेल्या सवई व्यसन :-', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),

            Table(
              border: TableBorder.all(color: Colors.black87),
              columnWidths: const {
                0: FixedColumnWidth(36),
                1: FlexColumnWidth(1),
                2: FixedColumnWidth(36),
                3: FlexColumnWidth(1),
              },
              children: [
                TableRow(
                  children: [
                    _tableHeader('अ.क्र.', serifStyle),
                    _tableHeader('अ', serifStyle),
                    _tableHeader('अ.क्र.', serifStyle),
                    _tableHeader('ब', serifStyle),
                  ],
                ),
                TableRow(
                  children: [
                    _tableHeader('1.', serifStyle),
                    _buildCheckboxCell('धुम्रपान', 'smoking', _habitsChecked, marathiLabelStyle),
                    _tableHeader('1.', serifStyle),
                    _buildCheckboxCell('टि.व्ही पाहणे', 'watching_tv', _hobbiesChecked, marathiLabelStyle),
                  ],
                ),
                TableRow(
                  children: [
                    _tableHeader('2.', serifStyle),
                    _buildCheckboxCell('दारू', 'alcohol', _habitsChecked, marathiLabelStyle),
                    _tableHeader('2.', serifStyle),
                    _buildCheckboxCell('खेळ खेळणे', 'playing_games', _hobbiesChecked, marathiLabelStyle),
                  ],
                ),
                TableRow(
                  children: [
                    _tableHeader('3.', serifStyle),
                    _buildCheckboxCell('जुगार', 'gambling', _habitsChecked, marathiLabelStyle),
                    _tableHeader('3.', serifStyle),
                    _buildCheckboxCell('पुस्तक वाचणे', 'reading_books', _hobbiesChecked, marathiLabelStyle),
                  ],
                ),
                TableRow(
                  children: [
                    _tableHeader('4.', serifStyle),
                    _buildCheckboxCell('भिक मागणे', 'begging', _habitsChecked, marathiLabelStyle),
                    _tableHeader('4.', serifStyle),
                    _buildCheckboxCell('चित्र काढणे', 'drawing', _hobbiesChecked, marathiLabelStyle),
                  ],
                ),
                TableRow(
                  children: [
                    _tableHeader('5.', serifStyle),
                    _buildCheckboxCell('खराॅ/ पान मसाला', 'tobacco_pan', _habitsChecked, marathiLabelStyle),
                    _tableHeader('5.', serifStyle),
                    _buildCheckboxCell('कला गायन', 'singing_art', _hobbiesChecked, marathiLabelStyle),
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
                Text('१२) बालकाचे नोकरीचा तपशील :- ', style: marathiLabelStyle.copyWith(fontWeight: FontWeight.bold)),
                Expanded(
                  child: BilingualSimpleUnderlineInput(
                    controller: _childJobDetailsCtrl,
                    serifStyle: serifStyle,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ══════════════════════════════════════════════════════════════════
        // PAGE 3 — SECTIONS 13 TO 17 (Income, Education & Drop reasons)
        // ══════════════════════════════════════════════════════════════════
        FormPaperPage(
          formLabel: 'Page : 3',
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
          ],
        ),

        const SizedBox(height: 24),

        // ══════════════════════════════════════════════════════════════════
        // PAGE 4 — SECTIONS 18 TO 24 (Friends, Abuse, Arrest Details)
        // ══════════════════════════════════════════════════════════════════
        FormPaperPage(
          formLabel: 'Page : 4',
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

        const SizedBox(height: 24),

        // ══════════════════════════════════════════════════════════════════
        // PAGE 5 — SECTIONS 25 TO 26 & SIGNATURE ENTRY (Part 5 Signature)
        // ══════════════════════════════════════════════════════════════════
        FormPaperPage(
          formLabel: 'Page : 5',
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
          ],
        ),
      ],
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
