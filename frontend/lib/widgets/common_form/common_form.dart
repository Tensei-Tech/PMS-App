// lib/widgets/common_form/common_form.dart
// ─────────────────────────────────────────────────────────────────────────────
// KHAKHI DIARY — Shared Common Form (Sections 1–17)
// • No DropdownButtonFormField anywhere — all selectors use _ChipSelector or
//   _SegmentedPicker (horizontal scrollable chips)
// • Compact: font sizes 11–13 pt, dense input decoration, 8px vertical spacing
// • All fields from the original HTML form are present — zero omissions
// • Name-sync engine: accused/suspected names propagate to Arrest (§9),
//   Discharge (§14), Verdict (§16), Seizure dropdowns (§11) reactively
// • saveDraft / clearForm / hydrateFromDocumentMap / buildDocumentMap intact
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../modules/core/models/base_record.dart';
import '../../screens/ad_form_screen.dart' show ACT_DATA;
import '../../services/case_service.dart';
import '../../utils/app_constants.dart';
import '../../utils/common_form_pdf.dart';
import '../../utils/crime_detail_pdf.dart';
import '../../utils/translation_helper.dart';
import '../../utils/validators.dart';
import 'pocso_voice_banner.dart';
import '../person_select_or_custom_field.dart';

// ── Palette ──
const Color _kDark = Color(0xFF0f172a);
const Color _kMid = Color(0xFF1e293b);
const Color _kTeal = Color(0xFF0ea5e9);
const Color _kGreen = Color(0xFF10b981);
const Color _kRed = Color(0xFFef4444);
const Color _kAmber = Color(0xFFf59e0b);
const Color _kSec = Color(0xFF64748b);
const Color _kMuted = Color(0xFF94a3b8);
const Color _kInputBg = Color(0xFFf8fafc);
const Color _kBorder = Color(0xFFe2e8f0);
const Color _kCardBg = Color(0xFFffffff);
const Color _kPageBg = Color(0xFFf4f7f9);

// ── Text styles (compact) ─────────────────────────────────────────────────────
const _tsLabel = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: _kDark,
  letterSpacing: 0.3,
);
const _tsSection = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w800,
  color: _kDark,
  letterSpacing: 0.5,
);
const _tsMuted = TextStyle(fontSize: 11, color: _kMuted);
const _tsBody = TextStyle(fontSize: 12, color: _kDark);

// ── Constants ─────────────────────────────────────────────────────────────────
const _kGenders = ['Male', 'Female', 'Other'];

// ── Warning Triangle Icon (Image 3) ─────────────────────────────────────────
class WarningTrianglePainter extends CustomPainter {
  const WarningTrianglePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Outer bright yellow triangle
    final outerPath = Path()
      ..moveTo(w * 0.50, h * 0.06)
      ..lineTo(w * 0.95, h * 0.88)
      ..arcToPoint(Offset(w * 0.88, h * 0.95), radius: const Radius.circular(3))
      ..lineTo(w * 0.12, h * 0.95)
      ..arcToPoint(Offset(w * 0.05, h * 0.88), radius: const Radius.circular(3))
      ..close();

    final outerPaint = Paint()
      ..color = const Color(0xFFFFD54F) // Bright yellow border
      ..style = PaintingStyle.fill;
    canvas.drawPath(outerPath, outerPaint);

    // Inner warm golden amber triangle
    final innerPath = Path()
      ..moveTo(w * 0.50, h * 0.22)
      ..lineTo(w * 0.84, h * 0.84)
      ..lineTo(w * 0.16, h * 0.84)
      ..close();

    final innerPaint = Paint()
      ..color = const Color(0xFFF59E0B) // Warm golden amber
      ..style = PaintingStyle.fill;
    canvas.drawPath(innerPath, innerPaint);

    // Dark charcoal exclamation mark
    final exPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    // Top vertical bar (rounded)
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.45, h * 0.38, w * 0.10, h * 0.26),
      const Radius.circular(2),
    );
    canvas.drawRRect(barRect, exPaint);

    // Bottom dot
    canvas.drawCircle(Offset(w * 0.50, h * 0.74), w * 0.055, exPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WarningTriangleIcon extends StatelessWidget {
  final double size;
  const WarningTriangleIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: WarningTrianglePainter()),
    );
  }
}

const _kProceduralKeys = {
  'chkPanchSpot': 'Spot Panchanama',
  'chkSeizurePanch': 'Seizure Panchanama',
  'chkSearch': 'Search Panchanama',
  'chkPersSearch': 'Personal Search Panchanama',
  'chkMemo': 'Memorandum Panchanama',
  'chkIdent': 'Identification Panchanama',
  'chkIdParade': 'Identification Parade Panchanama',
};

const _kPreventiveItems = [
  '107 Crpc / 126 BNSS',
  '109 Crpc / 128 BNSS',
  '110 Crpc / 129 BNSS',
  '151(3) Crpc / 170 BNSS',
  '144 Crpc / 163 BNSS',
  '149 Crpc / 168 BNSS',
  '55 MPA',
  '56 MPA',
  '57 MPA',
  '122 MPA',
  '93 Prohibition Act',
];

// CommonForm widget
// ─────────────────────────────────────────────────────────────────────────────
class CommonForm extends StatefulWidget {
  const CommonForm({
    super.key,
    this.categoryId,
    this.moduleKey,
    this.moduleLabel,
    this.subCategory,
    this.middleSlot,
    this.trailingSlotsBySection,
    this.onDraftSaved,
    this.onCleared,
    this.scrollController,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.isMurder,
  });

  final dynamic categoryId;
  final String? moduleKey;
  final String? moduleLabel;
  final String? subCategory;
  final Widget? middleSlot;
  final Map<int, List<Widget>>? trailingSlotsBySection;
  final ValueChanged<Map<String, dynamic>>? onDraftSaved;
  final VoidCallback? onCleared;
  final ScrollController? scrollController;
  final EdgeInsets padding;
  final bool? isMurder;

  @override
  State<CommonForm> createState() => CommonFormState();
}

class CommonFormState extends State<CommonForm> {
  late final ScrollController _scroll =
      widget.scrollController ?? ScrollController();
  final ValueNotifier<double> scrollProgress = ValueNotifier(0);
  Timer? _syncDebounce;
  bool _ownsScroll = false;

  String saveBarText = 'All changes unsaved';

  // ── Crime / Sexual Offence Sensitivity ─────────────────────────────────────
  bool get _hasSexualOffenceAct {
    const sexualSections = {
      // BNS, 2023 - Rape & sexual offences
      '63',
      '64',
      '65',
      '66',
      '67',
      '68',
      '69',
      '70',
      '71',
      '72',
      '74',
      '75',
      '76',
      '77',
      '78',
      '79',
      // IPC, 1860 - Rape & sexual offences
      '376',
      '376A',
      '376AB',
      '376B',
      '376C',
      '376D',
      '376DA',
      '376DB',
      '376E',
      '354',
      '354A',
      '354B',
      '354C',
      '354D',
      '509',
      // POCSO Act
      '3', '4', '5', '6', '7', '8', '9', '10', '11', '12',
    };
    for (final ch in _chargeData.values) {
      final act = (ch['act'] ?? '').toString().toUpperCase();
      final secs = (ch['sections'] as Set<String>?) ?? {};
      if (act == 'POCSO' && secs.isNotEmpty) return true;
      for (final s in secs) {
        final clean = s.trim().toUpperCase();
        if (sexualSections.contains(clean)) return true;
        final lower = clean.toLowerCase();
        if (lower.contains('rape') ||
            lower.contains('sexual') ||
            lower.contains('modesty') ||
            lower.contains('pocso') ||
            lower.contains('stalk') ||
            lower.contains('voyeur')) {
          return true;
        }
      }
    }
    return false;
  }

  bool get _isVoiceEnabled {
    final key = (widget.moduleKey ?? '').trim().toLowerCase();
    final sub = (widget.subCategory ?? '').trim().toLowerCase();
    final label = (widget.moduleLabel ?? '').trim().toLowerCase();
    if (key == 'form_1_5' ||
        key == 'form_6' ||
        key == 'forms' ||
        key == 'i to v' ||
        key == 'vi' ||
        sub.contains('form i') ||
        sub.contains('form 1') ||
        sub.contains('form vi') ||
        sub.contains('form 6') ||
        label.contains('form i') ||
        label.contains('form 1') ||
        label.contains('form vi') ||
        label.contains('form 6')) {
      return false;
    }
    return true;
  }

  // ── Live Voice Dictation State ──────────────────────────────────────────
  String _activeVoiceFieldLabel = 'CR Number';
  String _activeVoiceSectionName = '§1 Crime Registration';
  TextEditingController? _activeVoiceController;

  void setActiveVoiceField(String label, TextEditingController ctrl,
      [String section = '']) {
    if (!_isVoiceEnabled) return;
    if (_activeVoiceController != ctrl || _activeVoiceFieldLabel != label) {
      setState(() {
        _activeVoiceFieldLabel = label;
        _activeVoiceController = ctrl;
        _activeVoiceSectionName = section;
      });
    }
  }

  void _setActiveVoiceField(String label, TextEditingController ctrl,
          [String section = '']) =>
      setActiveVoiceField(label, ctrl, section);

  // ── §1 Crime Registration ─────────────────────────────────────────────────
  final _crNo = TextEditingController();
  final _regDate = TextEditingController();
  String? _firPath;

  // ── §2 Acts & Sections ────────────────────────────────────────────────────
  int _chargeSeq = 0;
  final Map<String, Map<String, dynamic>> _chargeData = {};

  // ── §3 Crime Spot ─────────────────────────────────────────────────────────
  final _spotVillage = TextEditingController();
  final _spotArea = TextEditingController();
  final _spotAddress = TextEditingController();
  final _occurrenceDateTime = TextEditingController();
  final List<Map<String, dynamic>> _stolenProperties = [];
  final List<Map<String, dynamic>> _recoveredProperties = [];

  // ── 2-4 Wheeler Stolen Details (in §4 Stolen Property) ───────────────────
  bool _isTwoFourWheelerTheft = false;
  final _vehicleEngineNumber = TextEditingController();
  final _vehicleChassisNumber = TextEditingController();
  final _vehicleRegNumber = TextEditingController();
  final _vehicleUniqueIdMark = TextEditingController();
  final _vehiclePurchaseDate = TextEditingController();
  bool _vehiclePhoto = false;
  bool _vehicleOwnershipDoc = false;

  // ── §4 Complainant KYC ────────────────────────────────────────────────────
  final _compName = TextEditingController();
  final _compAge = TextEditingController();
  String _compGender = 'Male';
  final _compOcc = TextEditingController();
  final _compMobile = TextEditingController();
  final _compAadhaar = TextEditingController();
  final _compReligion = TextEditingController();
  final _compCaste = TextEditingController();
  final _compPan = TextEditingController();
  final _compAddress = TextEditingController();
  final _compStatement = TextEditingController();

  // ── §5 Victim KYC ─────────────────────────────────────────────────────────
  TextEditingController? _victimName;
  TextEditingController? _victimAge;
  String? _victimGender;
  TextEditingController? _victimOcc;
  TextEditingController? _victimMobile;
  TextEditingController? _victimAadhaar;
  TextEditingController? _victimReligion;
  TextEditingController? _victimCaste;
  TextEditingController? _victimPan;

  TextEditingController get _vName => _victimName ??= TextEditingController();
  TextEditingController get _vAge => _victimAge ??= TextEditingController();
  String get _vGender => _victimGender ??= 'Male';
  set _vGender(String v) => _victimGender = v;
  TextEditingController get _vOcc => _victimOcc ??= TextEditingController();
  TextEditingController get _vMobile =>
      _victimMobile ??= TextEditingController();
  TextEditingController get _vAadhaar =>
      _victimAadhaar ??= TextEditingController();
  TextEditingController get _vReligion =>
      _victimReligion ??= TextEditingController();
  TextEditingController get _vCaste => _victimCaste ??= TextEditingController();
  TextEditingController get _vPan => _victimPan ??= TextEditingController();

  TextEditingController? _victimAddress;
  TextEditingController? _victimMedicalExam;
  TextEditingController get _vAddress =>
      _victimAddress ??= TextEditingController();
  TextEditingController get _vMedicalExam =>
      _victimMedicalExam ??= TextEditingController();

  // ── §5b Deceased KYC (Murder cases) ───────────────────────────────────────
  TextEditingController? _deceasedName;
  TextEditingController? _deceasedAge;
  String? _deceasedGender;
  TextEditingController? _deceasedOcc;
  TextEditingController? _deceasedMobile;
  TextEditingController? _deceasedAadhaar;
  TextEditingController? _deceasedReligion;
  TextEditingController? _deceasedCaste;
  TextEditingController? _deceasedPan;

  TextEditingController get _dName => _deceasedName ??= TextEditingController();
  TextEditingController get _dAge => _deceasedAge ??= TextEditingController();
  String get _dGender => _deceasedGender ??= 'Male';
  set _dGender(String v) => _deceasedGender = v;
  TextEditingController get _dOcc => _deceasedOcc ??= TextEditingController();
  TextEditingController get _dMobile =>
      _deceasedMobile ??= TextEditingController();
  TextEditingController get _dAadhaar =>
      _deceasedAadhaar ??= TextEditingController();
  TextEditingController get _dReligion =>
      _deceasedReligion ??= TextEditingController();
  TextEditingController get _dCaste =>
      _deceasedCaste ??= TextEditingController();
  TextEditingController get _dPan => _deceasedPan ??= TextEditingController();

  TextEditingController? _deceasedAddress;
  TextEditingController get _dAddress =>
      _deceasedAddress ??= TextEditingController();

  // ── §5c Injured KYC ────────────────────────────────────────────────────────
  TextEditingController? _injuredName;
  TextEditingController? _injuredAge;
  String? _injuredGender;
  TextEditingController? _injuredOcc;
  TextEditingController? _injuredMobile;
  TextEditingController? _injuredAadhaar;
  TextEditingController? _injuredReligion;
  TextEditingController? _injuredCaste;
  TextEditingController? _injuredPan;
  bool _injIsDied = false;
  TextEditingController? _injuredDeathDate;
  TextEditingController? _injuredDeathTime;

  TextEditingController get _injName =>
      _injuredName ??= TextEditingController();
  TextEditingController get _injAge => _injuredAge ??= TextEditingController();
  String get _injGender => _injuredGender ??= 'Male';
  set _injGender(String v) => _injuredGender = v;
  TextEditingController get _injOcc => _injuredOcc ??= TextEditingController();
  TextEditingController get _injMobile =>
      _injuredMobile ??= TextEditingController();
  TextEditingController get _injAadhaar =>
      _injuredAadhaar ??= TextEditingController();
  TextEditingController get _injReligion =>
      _injuredReligion ??= TextEditingController();
  TextEditingController get _injCaste =>
      _injuredCaste ??= TextEditingController();
  TextEditingController get _injPan => _injuredPan ??= TextEditingController();
  TextEditingController get _injDeathDate =>
      _injuredDeathDate ??= TextEditingController();
  TextEditingController get _injDeathTime =>
      _injuredDeathTime ??= TextEditingController();

  TextEditingController? _injuredAddress;
  TextEditingController? _injuredMedicalExam;
  TextEditingController get _injAddress =>
      _injuredAddress ??= TextEditingController();
  TextEditingController get _injMedicalExam =>
      _injuredMedicalExam ??= TextEditingController();

  bool get _isRapeCase {
    final sub = (widget.subCategory ?? '').toLowerCase();
    final mod = (widget.moduleKey ?? '').toLowerCase();
    if (sub.contains('rape') ||
        mod.contains('rape') ||
        sub.contains('376') ||
        mod.contains('376')) {
      return true;
    }

    for (final charge in _chargeData.values) {
      final act = charge['act']?.toString().toLowerCase() ?? '';
      final secs = (charge['sections'] as Set<String>?) ?? {};
      if (act.contains('rape')) return true;
      for (final s in secs) {
        final secLower = s.toLowerCase();
        // IPC 376 series (Rape)
        if (secLower.startsWith('376')) {
          return true;
        }
        // BNS 64, 65, 66, 67, 68, 70, 71 (Rape & Gang Rape sections)
        if (secLower == '64' ||
            secLower == '65' ||
            secLower == '66' ||
            secLower == '67' ||
            secLower == '68' ||
            secLower == '70' ||
            secLower == '71') {
          return true;
        }
        final label = _secLabel(
          charge['act']?.toString() ?? '',
          s,
        ).toLowerCase();
        if (label.contains('rape')) {
          return true;
        }
      }
    }
    return false;
  }

  bool get _isTwoFourWheeler {
    final k = (widget.moduleKey ?? '').toLowerCase();
    final l = (widget.moduleLabel ?? '').toLowerCase();
    final s = (widget.subCategory ?? '').toLowerCase();
    return k == 'two_four_wheeler' ||
        k.contains('wheeler') ||
        l.contains('wheeler') ||
        s.contains('wheeler');
  }

  // ── §6 Accused ────────────────────────────────────────────────────────────
  bool _isUnknown = false;
  final List<Map<String, dynamic>> _accused = [];
  final List<Map<String, dynamic>> _suspected = [];

  // ── §7 Unidentified ───────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _unidentified = [];

  TextEditingController? _unidentifiedAge;
  TextEditingController? _unidentifiedSkin;
  TextEditingController? _unidentifiedHeight;
  TextEditingController? _unidentifiedMobile;
  TextEditingController? _unidentifiedOcc;
  TextEditingController? _unidentifiedAddress;
  TextEditingController? _unidentifiedMarkers;

  TextEditingController get _unidAge =>
      _unidentifiedAge ??= TextEditingController();
  TextEditingController get _unidSkin =>
      _unidentifiedSkin ??= TextEditingController();
  TextEditingController get _unidHeight =>
      _unidentifiedHeight ??= TextEditingController();
  TextEditingController get _unidMobile =>
      _unidentifiedMobile ??= TextEditingController();
  TextEditingController get _unidOcc =>
      _unidentifiedOcc ??= TextEditingController();
  TextEditingController get _unidAddress =>
      _unidentifiedAddress ??= TextEditingController();
  TextEditingController get _unidMarkers =>
      _unidentifiedMarkers ??= TextEditingController();

  // ── §7b Unknown ───────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _unknown = [];

  // ── §8 Case Responsibility ────────────────────────────────────────────────
  String _ioDesig = 'PSI';
  String _regDesig = 'HC';
  final _ioName = TextEditingController();
  final _regName = TextEditingController();
  String? _cctvVal;
  final _cctvDt = TextEditingController();

  // ── §9 Arrest / Release ───────────────────────────────────────────────────
  final List<Map<String, dynamic>> _arrestRows = [];
  // ── §10 Custody & Remand ──────────────────────────────────────────────────
  final List<Map<String, dynamic>> _custodyRows = [];

  // ── §11 Technical (CCTV & CDR) ─────────────────────────────────────────────
  bool _cctvChecked = false;
  final _cdrSent = TextEditingController();
  final _cdrRecv = TextEditingController();

  // ── §12 All Panchanama ─────────────────────────────────────────────────────
  final Map<String, bool> _procChecks = {
    for (final k in _kProceduralKeys.keys) k: false,
  };
  final Map<String, TextEditingController> _procDates = {
    for (final k in _kProceduralKeys.keys) k: TextEditingController(),
  };

  // ── §13 Evidence & Seizure ─────────────────────────────────────────────────
  String? _eshaksh;
  TextEditingController? _eshakshDt;
  TextEditingController? _eshakshReason;

  TextEditingController get _eDt => _eshakshDt ??= TextEditingController();
  TextEditingController get _eReason =>
      _eshakshReason ??= TextEditingController();

  String? _fingerprintVal;
  final _fingerprintDate = TextEditingController();
  final _fingerprintReason = TextEditingController();
  String? _nafisFingerprint;

  final List<Map<String, dynamic>> _seizures = [];

  // ── §14 Preventive Action & Bonds ──────────────────────────────────────────
  String? _prevBondsVal = 'no';
  final _outward = TextEditingController();
  final _bondDate = TextEditingController();
  final _bondCancel = TextEditingController();
  TextEditingController? _bondReason;
  TextEditingController get _bReason => _bondReason ??= TextEditingController();
  String? _prevAction = '107 Crpc / 126 BNSS';
  TextEditingController? _prevActionDateCtrl;
  TextEditingController get _prevActionDt =>
      _prevActionDateCtrl ??= TextEditingController();

  // ── §15 Discharge Accused ──────────────────────────────────────────────────
  Map<String, bool>? _dischargeMap;
  Map<String, bool> get _discharge => _dischargeMap ??= {};
  Map<String, TextEditingController>? _dischargeDatesMap;
  Map<String, TextEditingController> get _dischargeDates =>
      _dischargeDatesMap ??= {};
  Map<String, TextEditingController>? _dischargeReasonsMap;
  Map<String, TextEditingController> get _dischargeReasons =>
      _dischargeReasonsMap ??= {};
  final List<Map<String, dynamic>> _customDischargeList = [];

  TextEditingController _getDischargeDateCtrl(String name) =>
      _dischargeDates.putIfAbsent(name, () => TextEditingController());

  TextEditingController _getDischargeReasonCtrl(String name) =>
      _dischargeReasons.putIfAbsent(name, () => TextEditingController());

  // ── §16 Scrutiny ───────────────────────────────────────────────────────────
  final _sdpoSend = TextEditingController();
  final _sdpoGrant = TextEditingController();
  final _dcpSend = TextEditingController();
  final _dcpGrant = TextEditingController();
  final _addlCpSend = TextEditingController();
  final _addlCpGrant = TextEditingController();
  final _appSend = TextEditingController();
  final _appGrant = TextEditingController();
  bool _stepApp = false;
  bool _stepDcp = false;

  // ── §17 Court Filing & Final Summary ───────────────────────────────────────
  final _csNumber = TextEditingController();
  TextEditingController? _csDateCtrl;
  TextEditingController get _csDate => _csDateCtrl ??= TextEditingController();
  final _aFinalNo = TextEditingController();
  final _bFinalNo = TextEditingController();
  final _cFinalNo = TextEditingController();
  final _ncFinalNo = TextEditingController();
  final _abatedSummaryNo = TextEditingController();
  final _ccStNumber = TextEditingController();
  final _stayHighCourtDate = TextEditingController();
  Map<String, String> _finalSummary = {};
  final _quashDate = TextEditingController();

  // ── Verdict ────────────────────────────────────────────────────────────────
  final List<String> _acquitted = [];
  final List<String> _convicted = [];

  // ── Derived ───────────────────────────────────────────────────────────────
  List<String> allAccusedNames = [];

  // ── Collapsible Card Sections (Shutter UI) ─────────────────────────────────
  Set<String>? _openSectionKeysSet;
  Set<String> get _openSectionKeys => _openSectionKeysSet ??= <String>{};

  Set<String>? _initializedSectionKeysSet;
  Set<String> get _initializedSectionKeys =>
      _initializedSectionKeysSet ??= <String>{};

  // ── Dynamic Field Engine Data (Backend API) ──────────────────────────────
  Map<String, Map<String, dynamic>> _actsData = {};
  Map<String, String> _proceduralKeys = Map.from(_kProceduralKeys);
  List<String> _preventiveItems = List.from(_kPreventiveItems);
  List<Map<String, dynamic>> _extraFields = [];
  final Map<String, TextEditingController> _dynamicControllers = {};
  final Map<String, dynamic> _dynamicValues = {};
  bool _isUsingFallback = false;

  Map<String, Map<String, dynamic>> get _activeActsData =>
      _actsData.isNotEmpty ? _actsData : ACT_DATA;
  Map<String, String> get _activeProceduralKeys =>
      _proceduralKeys.isNotEmpty ? _proceduralKeys : _kProceduralKeys;
  List<String> get _activePreventiveItems =>
      _preventiveItems.isNotEmpty ? _preventiveItems : _kPreventiveItems;

  Future<void> _loadFormDefinition({List<dynamic>? chargedSections}) async {
    final catId = widget.categoryId ??
        widget.subCategory ??
        widget.moduleLabel ??
        widget.moduleKey;
    if (catId == null ||
        catId == 'form_1_5' ||
        catId == 'form_iv' ||
        catId == 'form_vi' ||
        catId == 'standalone') {
      return;
    }
    final def = await CaseService().fetchFormDefinition(
      catId,
      sections: chargedSections,
    );
    if (!mounted) return;
    if (def != null) {
      setState(() {
        _isUsingFallback = false;
        if (def['acts_sections'] is Map) {
          final acts = Map<String, dynamic>.from(def['acts_sections'] as Map);
          _actsData = acts.map(
              (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)));
        }
        if (def['procedural_items'] is Map) {
          _proceduralKeys = (def['procedural_items'] as Map)
              .map((k, v) => MapEntry(k.toString(), v.toString()));
          for (final k in _proceduralKeys.keys) {
            _procChecks.putIfAbsent(k, () => false);
            _procDates.putIfAbsent(k, () => TextEditingController());
          }
        }
        if (def['preventive_items'] is List) {
          _preventiveItems =
              (def['preventive_items'] as List).map((e) => e.toString()).toList();
        }
        if (def['fields'] is List) {
          final rawFields = (def['fields'] as List)
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
          _extraFields = rawFields
              .where((f) => f['field_source'] != 'common')
              .toList();

          for (final f in _extraFields) {
            final key = f['field_key']?.toString() ?? '';
            if (key.isEmpty) continue;
            final type = f['field_type']?.toString().toLowerCase() ?? 'text';
            if (type == 'checkbox') {
              _dynamicValues.putIfAbsent(key, () => false);
            } else if (type == 'dropdown') {
              _dynamicValues.putIfAbsent(key, () => null);
            } else {
              _dynamicControllers.putIfAbsent(
                key,
                () => TextEditingController()..addListener(_debouncedSync),
              );
            }
          }
        }
      });
    } else {
      if (mounted) {
        setState(() {
          _isUsingFallback = true;
        });
      }
    }
  }

  void _syncDynamicFieldsForCharges() {
    final allSecs = _chargeData.values
        .expand((r) => (r['sections'] as Set<String>? ?? <String>{}))
        .toList();
    _loadFormDefinition(chargedSections: allSecs);
  }

  @visibleForTesting
  Future<void> loadFormDefinitionForTest(List<dynamic> sections) =>
      _loadFormDefinition(chargedSections: sections);

  // ─── lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _ownsScroll = widget.scrollController == null;
    _isTwoFourWheelerTheft = _isTwoFourWheeler;
    _loadFormDefinition();
  }

  @override
  void dispose() {
    _syncDebounce?.cancel();
    if (_ownsScroll) _scroll.dispose();
    scrollProgress.dispose();
    _disposeAll();
    super.dispose();
  }

  void _disposeAll() {
    for (final c in [
      _crNo,
      _regDate,
      _spotVillage,
      _spotArea,
      _spotAddress,
      _occurrenceDateTime,
      _compName,
      _compAge,
      _compOcc,
      _compMobile,
      _compAadhaar,
      _compReligion,
      _compCaste,
      _vName,
      _vAge,
      _vOcc,
      _vMobile,
      _vAadhaar,
      _vReligion,
      _vCaste,
      _vPan,
      _dName,
      _dAge,
      _dOcc,
      _dMobile,
      _dAadhaar,
      _dReligion,
      _dCaste,
      _dPan,
      _injName,
      _injAge,
      _injOcc,
      _injMobile,
      _injAadhaar,
      _injReligion,
      _injCaste,
      _injPan,
      _injDeathDate,
      _injDeathTime,
      _unidAge,
      _unidSkin,
      _unidHeight,
      _unidMobile,
      _unidOcc,
      _unidAddress,
      _unidMarkers,
      _ioName,
      _regName,
      _cctvDt,
      _eDt,
      _eReason,
      _cdrSent,
      _vehicleEngineNumber,
      _vehicleChassisNumber,
      _vehicleRegNumber,
      _vehicleUniqueIdMark,
      _vehiclePurchaseDate,
      _cdrRecv,
      _outward,
      _prevActionDt,
      _bondDate,
      _bReason,
      _bondCancel,
      _csNumber,
      _csDate,
      _ccStNumber,
      _quashDate,
      _sdpoSend,
      _sdpoGrant,
      _appSend,
      _appGrant,
      _dcpSend,
      _dcpGrant,
      _compAddress,
      _compStatement,
      if (_victimAddress != null) _vAddress,
      if (_victimMedicalExam != null) _vMedicalExam,
      if (_deceasedAddress != null) _dAddress,
      if (_injuredAddress != null) _injAddress,
      if (_injuredMedicalExam != null) _injMedicalExam,
      _fingerprintDate,
      _fingerprintReason,
    ]) {
      c.dispose();
    }
    _disposePeople(_accused);
    _disposePeople(_suspected);
    for (final r in _arrestRows) {
      _disposeMap(r);
    }
    for (final s in _seizures) {
      _disposeMap(s);
    }
    for (final c in _procDates.values) {
      c.dispose();
    }
    for (final c in _dischargeDates.values) {
      c.dispose();
    }
    for (final c in _dischargeReasons.values) {
      c.dispose();
    }
    for (final c in _dynamicControllers.values) {
      c.dispose();
    }
  }

  void _disposePeople(List<Map<String, dynamic>> list) {
    for (final p in list) {
      _disposeMap(p);
    }
    list.clear();
  }

  void _disposeUnidRow(Map<String, dynamic> m) {
    (m['age'] as TextEditingController).dispose();
    (m['height'] as TextEditingController).dispose();
    (m['skin'] as TextEditingController).dispose();
    (m['mobile'] as TextEditingController).dispose();
    (m['occ'] as TextEditingController).dispose();
    (m['address'] as TextEditingController).dispose();
    (m['markers'] as TextEditingController).dispose();
  }

  void _disposeMap(Map<String, dynamic> m) {
    for (final v in m.values) {
      if (v is TextEditingController) v.dispose();
    }
  }

  // ─── scroll progress ───────────────────────────────────────────────────────
  bool _onScroll(ScrollNotification n) {
    final mx = n.metrics.maxScrollExtent;
    if (mx <= 0) {
      scrollProgress.value = 0;
      return false;
    }
    final p = (n.metrics.pixels / mx).clamp(0.0, 1.0);
    if ((p - scrollProgress.value).abs() > 0.004) scrollProgress.value = p;
    return false;
  }

  // ─── name sync ─────────────────────────────────────────────────────────────
  void _debouncedSync() {
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 100), _syncNames);
  }

  void _syncNames() {
    final names = [..._accused, ..._suspected]
        .map((p) => (p['name'] as TextEditingController).text.trim())
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();

    if (!listEquals(names, allAccusedNames)) {
      setState(() {
        allAccusedNames = List<String>.from(names);
        _rebuildArrests();
        _rebuildCustody();
        _rebuildDischarge();
        _pruneVerdict();
        for (final s in _seizures) {
          final fw = s['fromWhom'] as String?;
          if (fw != null && !allAccusedNames.contains(fw)) {
            s['fromWhom'] =
                allAccusedNames.isEmpty ? null : allAccusedNames.first;
          }
        }
      });
    }
  }

  void _rebuildArrests() {
    for (final r in _arrestRows) {
      _disposeMap(r);
    }
    _arrestRows.clear();
    for (final n in allAccusedNames) {
      _arrestRows.add({
        'accusedName': n,
        'arrestDt': TextEditingController(),
        'sec47_48': false,
        'relName': TextEditingController(),
        'relationship': TextEditingController(),
        'relOnNotice': false,
        'anticipatoryBail': false,
        'isDeceased': false,
        'deathDt': TextEditingController(),
      });
    }
  }

  void _rebuildCustody() {
    for (final r in _custodyRows) {
      _disposeMap(r);
    }
    _custodyRows.clear();
    for (final n in allAccusedNames) {
      _custodyRows.add({
        'accusedName': n,
        'pcrDays': TextEditingController(),
        'isMcr': false,
        'isPrBond': false,
        'isBail': false,
        'isJail': false,
        'mcrJail': TextEditingController(),
        'suretyName': TextEditingController(),
        'suretyAge': TextEditingController(),
        'suretyGender': 'Male',
        'suretyOcc': TextEditingController(),
        'suretyMobile': TextEditingController(),
        'suretyAadhaar': TextEditingController(),
        'suretyPan': TextEditingController(),
        'suretyAddress': TextEditingController(),
        'suretyRel': TextEditingController(),
      });
    }
  }

  void addCustomDischarge() {
    setState(() {
      _customDischargeList.add({
        'name': TextEditingController(),
        'date': TextEditingController(),
        'reason': TextEditingController(),
      });
    });
  }

  void removeCustomDischarge(int i) {
    final item = _customDischargeList.removeAt(i);
    _disposeMap(item);
    setState(() {});
  }

  void _rebuildDischarge() {
    final next = <String, bool>{};
    for (final n in allAccusedNames) {
      next[n] = _discharge[n] ?? false;
    }
    _discharge
      ..clear()
      ..addAll(next);
  }

  void _pruneVerdict() {
    final set = allAccusedNames.toSet();
    _acquitted.removeWhere((n) => !set.contains(n));
    _convicted.removeWhere((n) => !set.contains(n));
  }

  // ─── person factory ────────────────────────────────────────────────────────
  Map<String, dynamic> _newPerson() => {
        'name': TextEditingController()..addListener(_debouncedSync),
        'age': TextEditingController(),
        'gender': 'Male',
        'occ': TextEditingController(),
        'mobile': TextEditingController(),
        'aadhaar': TextEditingController(),
        'religion': TextEditingController(),
        'caste': TextEditingController(),
        'pan': TextEditingController(),
        'address': TextEditingController(),
      };

  // ─── charge helpers ────────────────────────────────────────────────────────
  void addChargeRow() {
    _chargeSeq++;
    _chargeData['charge-$_chargeSeq'] = {'act': '', 'sections': <String>{}};
    setState(() {});
  }

  void _removeCharge(String id) {
    _chargeData.remove(id);
    setState(() {});
    _syncDynamicFieldsForCharges();
  }

  void _onActChange(String id, String act) {
    _chargeData[id]!['act'] = act;
    _chargeData[id]!['sections'] = <String>{};
    setState(() {});
    _syncDynamicFieldsForCharges();
  }

  void _addSection(String id, String val) {
    (_chargeData[id]!['sections'] as Set<String>).add(val);
    setState(() {});
    _syncDynamicFieldsForCharges();
  }

  void _removeSection(String id, String val) {
    (_chargeData[id]!['sections'] as Set<String>).remove(val);
    setState(() {});
    _syncDynamicFieldsForCharges();
  }

  String _secLabel(String actKey, String val) {
    final secs = _activeActsData[actKey]?['sections'] as List<dynamic>? ?? [];
    for (final raw in secs) {
      if (raw is Map && raw['val'] == val) {
        return raw['label'] as String? ?? val;
      }
    }
    return val;
  }

  Map<String, dynamic> _createStolenPropRow(Map<dynamic, dynamic> data) => {
        'property': TextEditingController(text: _s(data['property'])),
        'quantity': TextEditingController(text: _s(data['quantity'])),
        'estValue': TextEditingController(text: _s(data['estValue'])),
        'id': TextEditingController(text: _s(data['id'])),
        'date': TextEditingController(text: _s(data['date'])),
        'from': TextEditingController(text: _s(data['from'])),
        'isTwoFourWheeler': data['isTwoFourWheeler'] == true,
        'engineNumber': TextEditingController(text: _s(data['engineNumber'])),
        'chassisNumber': TextEditingController(text: _s(data['chassisNumber'])),
        'regNumber': TextEditingController(text: _s(data['regNumber'])),
        'uniqueIdMark': TextEditingController(text: _s(data['uniqueIdMark'])),
        'purchaseDate': TextEditingController(text: _s(data['purchaseDate'])),
        'photo': data['photo'] == true,
        'ownershipDoc': data['ownershipDoc'] == true,
      };

  Map<String, dynamic> _createRecoveredPropRow(Map<dynamic, dynamic> data) => {
        'property': TextEditingController(text: _s(data['property'])),
        'quantity': TextEditingController(text: _s(data['quantity'])),
        'estValue': TextEditingController(text: _s(data['estValue'])),
        'date': TextEditingController(text: _s(data['date'])),
        'from': TextEditingController(text: _s(data['from'])),
      };

  // ─── accused / suspected helpers ───────────────────────────────────────────
  void addPersonAccused() {
    setState(() {
      _accused.add(_newPerson());
      _openSectionKeys.add('6');
    });
    _syncNames();
  }

  void addPersonSuspected() {
    setState(() {
      _suspected.add(_newPerson());
      _openSectionKeys.add('7');
    });
  }

  void removePersonAccused(int i) {
    _disposeMap(_accused.removeAt(i));
    _syncNames();
    setState(() {});
  }

  void removePersonSuspected(int i) {
    _disposeMap(_suspected.removeAt(i));
    setState(() {});
  }

  void addUnidentified() {
    setState(() {
      _unidentified.add({
        'age': TextEditingController(),
        'gender': 'Male',
        'skin': TextEditingController(),
        'occ': TextEditingController(),
        'markers': TextEditingController(),
        'height': TextEditingController(),
        'address': TextEditingController(),
        'desc': TextEditingController(),
      });
      _openSectionKeys.add('8');
    });
  }

  void removeUnidentified(int i) {
    _disposeUnidRow(_unidentified.removeAt(i));
    setState(() {});
  }

  void addUnknown() {
    setState(() {
      _unknown.add({
        'name': TextEditingController(),
        'gender': 'Male',
        'age': TextEditingController(),
        'height': TextEditingController(),
        'skin': TextEditingController(),
        'mobile': TextEditingController(),
        'occ': TextEditingController(),
        'address': TextEditingController(),
        'markers': TextEditingController(),
      });
    });
  }

  void removeUnknown(int i) {
    _disposeUnidRow(_unknown.removeAt(i));
    setState(() {});
  }

  void _copyPersonData(Map<String, dynamic> src, Map<String, dynamic> dst) {
    dst['name'] ??= TextEditingController()..addListener(_debouncedSync);
    dst['age'] ??= TextEditingController();
    dst['gender'] ??= 'Male';
    dst['occ'] ??= TextEditingController();
    dst['mobile'] ??= TextEditingController();
    dst['aadhaar'] ??= TextEditingController();
    dst['religion'] ??= TextEditingController();
    dst['caste'] ??= TextEditingController();
    dst['pan'] ??= TextEditingController();
    dst['address'] ??= TextEditingController();

    setState(() {
      (dst['name'] as TextEditingController).text =
          (src['name'] as TextEditingController?)?.text ?? '';
      (dst['age'] as TextEditingController).text =
          (src['age'] as TextEditingController?)?.text ?? '';
      dst['gender'] = src['gender'] ?? 'Male';
      (dst['occ'] as TextEditingController).text =
          (src['occ'] as TextEditingController?)?.text ?? '';
      (dst['mobile'] as TextEditingController).text =
          (src['mobile'] as TextEditingController?)?.text ?? '';
      (dst['aadhaar'] as TextEditingController).text =
          (src['aadhaar'] as TextEditingController?)?.text ?? '';
      (dst['religion'] as TextEditingController).text =
          (src['religion'] as TextEditingController?)?.text ?? '';
      (dst['caste'] as TextEditingController).text =
          (src['caste'] as TextEditingController?)?.text ?? '';
      (dst['pan'] as TextEditingController).text =
          (src['pan'] as TextEditingController?)?.text ?? '';
      (dst['address'] as TextEditingController).text =
          (src['address'] as TextEditingController?)?.text ?? '';
    });
    _syncNames();
  }

  void _checkAndAutoFillPerson(
    Map<String, dynamic> row,
    List<Map<String, dynamic>> sourceList,
  ) {
    final name = (row['name'] as TextEditingController?)?.text.trim() ?? '';
    if (name.isEmpty) return;

    for (final src in sourceList) {
      final srcName =
          (src['name'] as TextEditingController?)?.text.trim() ?? '';
      if (srcName.isNotEmpty && srcName.toLowerCase() == name.toLowerCase()) {
        final ageCtrl = row['age'] as TextEditingController?;
        final occCtrl = row['occ'] as TextEditingController?;
        final mobCtrl = row['mobile'] as TextEditingController?;
        final aadhCtrl = row['aadhaar'] as TextEditingController?;
        final relCtrl = row['religion'] as TextEditingController?;
        final casteCtrl = row['caste'] as TextEditingController?;
        final panCtrl = row['pan'] as TextEditingController?;
        final addrCtrl = row['address'] as TextEditingController?;

        final srcAge = (src['age'] as TextEditingController?)?.text ?? '';
        final srcOcc = (src['occ'] as TextEditingController?)?.text ?? '';
        final srcMob = (src['mobile'] as TextEditingController?)?.text ?? '';
        final srcAadh = (src['aadhaar'] as TextEditingController?)?.text ?? '';
        final srcRel = (src['religion'] as TextEditingController?)?.text ?? '';
        final srcCaste = (src['caste'] as TextEditingController?)?.text ?? '';
        final srcPan = (src['pan'] as TextEditingController?)?.text ?? '';
        final srcAddr = (src['address'] as TextEditingController?)?.text ?? '';

        setState(() {
          if (ageCtrl != null && ageCtrl.text.isEmpty && srcAge.isNotEmpty) {
            ageCtrl.text = srcAge;
          }
          if ((row['gender'] == null || row['gender'] == 'Male') &&
              src['gender'] != null) {
            row['gender'] = src['gender'];
          }
          if (occCtrl != null && occCtrl.text.isEmpty && srcOcc.isNotEmpty) {
            occCtrl.text = srcOcc;
          }
          if (mobCtrl != null && mobCtrl.text.isEmpty && srcMob.isNotEmpty) {
            mobCtrl.text = srcMob;
          }
          if (aadhCtrl != null && aadhCtrl.text.isEmpty && srcAadh.isNotEmpty) {
            aadhCtrl.text = srcAadh;
          }
          if (relCtrl != null && relCtrl.text.isEmpty && srcRel.isNotEmpty) {
            relCtrl.text = srcRel;
          }
          if (casteCtrl != null &&
              casteCtrl.text.isEmpty &&
              srcCaste.isNotEmpty) {
            casteCtrl.text = srcCaste;
          }
          if (panCtrl != null && panCtrl.text.isEmpty && srcPan.isNotEmpty) {
            panCtrl.text = srcPan;
          }
          if (addrCtrl != null && addrCtrl.text.isEmpty && srcAddr.isNotEmpty) {
            addrCtrl.text = srcAddr;
          }
        });
        break;
      }
    }
  }

  // ─── seizure helpers ───────────────────────────────────────────────────────
  void addSeizure() {
    setState(
      () => _seizures.add({
        'desc': TextEditingController(),
        'quantity': TextEditingController(),
        'serialNo': TextEditingController(),
        'estValue': TextEditingController(),
        'status': 'Recovered',
        'recoveryDate': TextEditingController(),
        'seizureDetails': TextEditingController(),
        'custodyLoc': TextEditingController(),
        'fromWhom': allAccusedNames.isEmpty ? null : allAccusedNames.first,
        'otherName': TextEditingController(),
      }),
    );
  }

  void removeSeizure(int i) {
    _disposeMap(_seizures.removeAt(i));
    setState(() {});
  }

  // ─── verdict helpers ───────────────────────────────────────────────────────
  void removeFromVerdictAcquitted(String n) =>
      setState(() => _acquitted.remove(n));
  void removeFromVerdictConvicted(String n) =>
      setState(() => _convicted.remove(n));

  void addToVerdictAcquitted(String n) {
    if (n.isEmpty || _acquitted.contains(n)) return;
    setState(() {
      _convicted.remove(n);
      _acquitted.add(n);
    });
  }

  void addToVerdictConvicted(String n) {
    if (n.isEmpty || _convicted.contains(n)) return;
    setState(() {
      _acquitted.remove(n);
      _convicted.add(n);
    });
  }

  void setVictimName(String name) {
    setState(() {
      _vName.text = name;
    });
  }

  // ─── procedural helpers ────────────────────────────────────────────────────
  void toggleProcedural(String key, bool v) {
    setState(() {
      _procChecks[key] = v;
      if (!v) _procDates[key]!.clear();
    });
  }

  // ─── FIR pick ──────────────────────────────────────────────────────────────
  Future<void> pickFirCopy() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (x != null) setState(() => _firPath = x.path);
  }

  // ─── saveDraft / clearForm ─────────────────────────────────────────────────
  void saveDraft() {
    final m = buildDocumentMap();
    setState(
      () => saveBarText = 'Draft saved · ${TimeOfDay.now().format(context)}',
    );
    widget.onDraftSaved?.call(m);
  }

  void clearForm() {
    _chargeData.clear();
    _chargeSeq = 0;
    _disposePeople(_accused);
    _disposePeople(_suspected);
    for (final r in _arrestRows) {
      _disposeMap(r);
    }
    _arrestRows.clear();
    for (final s in _seizures) {
      _disposeMap(s);
    }
    _seizures.clear();

    for (final c in [
      _crNo,
      _regDate,
      _spotVillage,
      _spotArea,
      _spotAddress,
      _occurrenceDateTime,
      _compName,
      _compAge,
      _compOcc,
      _compMobile,
      _compAadhaar,
      _compReligion,
      _compCaste,
      _compPan,
      _vName,
      _vAge,
      _vOcc,
      _vMobile,
      _vAadhaar,
      _vReligion,
      _vCaste,
      _vPan,
      _dName,
      _dAge,
      _dOcc,
      _dMobile,
      _dAadhaar,
      _dReligion,
      _dCaste,
      _dPan,
      _injName,
      _injAge,
      _injOcc,
      _injMobile,
      _injAadhaar,
      _injReligion,
      _injCaste,
      _injPan,
      _injDeathDate,
      _injDeathTime,
      _unidAge,
      _unidSkin,
      _unidHeight,
      _unidMobile,
      _unidOcc,
      _unidAddress,
      _unidMarkers,
      _ioName,
      _regName,
      _cctvDt,
      _eDt,
      _eReason,
      _cdrSent,
      _cdrRecv,
      _outward,
      _prevActionDt,
      _bondDate,
      _bReason,
      _bondCancel,
      _csNumber,
      _csDate,
      _ccStNumber,
      _quashDate,
      _sdpoSend,
      _sdpoGrant,
      _appSend,
      _appGrant,
      _dcpSend,
      _dcpGrant,
      _vehicleEngineNumber,
      _vehicleChassisNumber,
      _vehicleRegNumber,
      _vehicleUniqueIdMark,
      _vehiclePurchaseDate,
      _addlCpSend,
      _addlCpGrant,
      _aFinalNo,
      _bFinalNo,
      _cFinalNo,
      _ncFinalNo,
      _abatedSummaryNo,
      _stayHighCourtDate,
    ]) {
      c.clear();
    }
    for (final c in _procDates.values) {
      c.clear();
    }
    for (final k in _procChecks.keys) {
      _procChecks[k] = false;
    }
    for (final item in _customDischargeList) {
      _disposeMap(item);
    }
    _customDischargeList.clear();

    _firPath = null;
    _compGender = 'Male';
    _vGender = 'Male';
    _dGender = 'Male';
    _injGender = 'Male';
    _injIsDied = false;
    _ioDesig = 'PSI';
    _regDesig = 'HC';
    _cctvVal = null;
    _cctvChecked = false;
    _eshaksh = null;
    _nafisFingerprint = null;
    _prevAction = '107 Crpc / 126 BNSS';
    _prevBondsVal = 'no';
    _finalSummary.clear();
    _discharge.clear();
    for (final c in _dischargeDates.values) {
      c.clear();
    }
    for (final c in _dischargeReasons.values) {
      c.clear();
    }
    _acquitted.clear();
    _convicted.clear();
    allAccusedNames = [];
    _stepApp = false;
    _stepDcp = false;
    _vehiclePhoto = false;
    _vehicleOwnershipDoc = false;
    _isTwoFourWheelerTheft = _isTwoFourWheeler;
    saveBarText = 'All changes unsaved';
    setState(() {});
    widget.onCleared?.call();
  }

  // ─── buildDocumentMap ──────────────────────────────────────────────────────
  Map<String, dynamic> buildDocumentMap() {
    List<Map<String, dynamic>> pplRows(List<Map<String, dynamic>> src) => src
        .map(
          (p) => {
            'name': (p['name'] as TextEditingController).text,
            'age': (p['age'] as TextEditingController).text,
            'gender': p['gender'],
            'occ': (p['occ'] as TextEditingController).text,
            'mobile': (p['mobile'] as TextEditingController).text,
            'aadhaar': (p['aadhaar'] as TextEditingController).text,
            'religion': (p['religion'] as TextEditingController).text,
            'caste': (p['caste'] as TextEditingController).text,
            'pan': (p['pan'] as TextEditingController).text,
            'address': (p['address'] as TextEditingController?)?.text ?? '',
          },
        )
        .toList();

    List<Map<String, dynamic>> unidRows(List<Map<String, dynamic>> src) => src
        .map(
          (p) => {
            'approxAge': (p['age'] as TextEditingController?)?.text ?? '',
            'gender': p['gender'] ?? 'Male',
            'skinColor': (p['skin'] as TextEditingController?)?.text ?? '',
            'occupation': (p['occ'] as TextEditingController?)?.text ?? '',
            'otherPhysicalMarkers':
                (p['markers'] as TextEditingController?)?.text ?? '',
            'approxHeight': (p['height'] as TextEditingController?)?.text ?? '',
            'lastKnownAddress':
                (p['address'] as TextEditingController?)?.text ?? '',
            'description': (p['desc'] as TextEditingController?)?.text ?? '',
          },
        )
        .toList();

    return {
      'crNo': _crNo.text,
      'regDate': _regDate.text,
      'firCopyPath': _firPath,
      'charges': _chargeData.map(
        (k, v) => MapEntry(k, {
          'act': v['act'],
          'sections': (v['sections'] as Set<String>).toList(),
        }),
      ),
      'spotVillage': _spotVillage.text,
      'spotArea': _spotArea.text,
      'spotAddress': _spotAddress.text,
      'occurrenceDateTime': _occurrenceDateTime.text,
      'stolenProperties': _stolenProperties
          .map((e) => {
                'property': (e['property'] as TextEditingController).text,
                'quantity': (e['quantity'] as TextEditingController).text,
                'estValue': (e['estValue'] as TextEditingController).text,
                'id': (e['id'] as TextEditingController).text,
                'date': (e['date'] as TextEditingController).text,
                'from': (e['from'] as TextEditingController).text,
                'isTwoFourWheeler': e['isTwoFourWheeler'] as bool? ?? false,
                'engineNumber':
                    (e['engineNumber'] as TextEditingController?)?.text ?? '',
                'chassisNumber':
                    (e['chassisNumber'] as TextEditingController?)?.text ?? '',
                'regNumber':
                    (e['regNumber'] as TextEditingController?)?.text ?? '',
                'uniqueIdMark':
                    (e['uniqueIdMark'] as TextEditingController?)?.text ?? '',
                'purchaseDate':
                    (e['purchaseDate'] as TextEditingController?)?.text ?? '',
                'photo': e['photo'] as bool? ?? false,
                'ownershipDoc': e['ownershipDoc'] as bool? ?? false,
              })
          .toList(),
      'recoveredProperties': _recoveredProperties
          .map((e) => {
                'property': (e['property'] as TextEditingController).text,
                'quantity': (e['quantity'] as TextEditingController).text,
                'estValue': (e['estValue'] as TextEditingController).text,
                'date': (e['date'] as TextEditingController).text,
                'from': (e['from'] as TextEditingController).text,
              })
          .toList(),
      'isTwoFourWheelerTheft': _isTwoFourWheelerTheft,
      'vehicleEngineNumber': _vehicleEngineNumber.text.trim(),
      'vehicleChassisNumber': _vehicleChassisNumber.text.trim(),
      'vehicleRegNumber': _vehicleRegNumber.text.trim(),
      'vehicleUniqueIdMark': _vehicleUniqueIdMark.text.trim(),
      'vehiclePurchaseDate': _vehiclePurchaseDate.text.trim(),
      'vehiclePhoto': _vehiclePhoto,
      'vehicleOwnershipDoc': _vehicleOwnershipDoc,
      'isSexualOffence': _hasSexualOffenceAct,
      'complainant': {
        'name': _hasSexualOffenceAct
            ? '[Victim Identity Protected]'
            : _compName.text,
        'age': _compAge.text,
        'gender': _compGender,
        'occ': _compOcc.text,
        'mobile': _compMobile.text,
        'aadhaar': _compAadhaar.text,
        'religion': _compReligion.text,
        'caste': _compCaste.text,
        'pan': _compPan.text,
        'address': _compAddress.text,
        'statement': _compStatement.text,
      },
      'victim': {
        'name': _vName.text,
        'age': _vAge.text,
        'gender': _vGender,
        'occ': _vOcc.text,
        'mobile': _vMobile.text,
        'aadhaar': _vAadhaar.text,
        'religion': _vReligion.text,
        'caste': _vCaste.text,
        'pan': _vPan.text,
        'address': _vAddress.text,
        'medicalExam': _vMedicalExam.text,
      },
      'deceased': {
        'name': _dName.text,
        'age': _dAge.text,
        'gender': _dGender,
        'occ': _dOcc.text,
        'mobile': _dMobile.text,
        'aadhaar': _dAadhaar.text,
        'religion': _dReligion.text,
        'caste': _dCaste.text,
        'pan': _dPan.text,
        'address': _dAddress.text,
      },
      'injured': {
        'name': _injName.text,
        'age': _injAge.text,
        'gender': _injGender,
        'occ': _injOcc.text,
        'mobile': _injMobile.text,
        'aadhaar': _injAadhaar.text,
        'religion': _injReligion.text,
        'caste': _injCaste.text,
        'pan': _injPan.text,
        'isDied': _injIsDied,
        'deathDate': _injDeathDate.text,
        'deathTime': _injDeathTime.text,
        'address': _injAddress.text,
        'medicalExam': _injMedicalExam.text,
      },
      'accused': pplRows(_accused),
      'suspectedAccused': pplRows(_suspected),
      'allAccusedNames': allAccusedNames,
      'unidentifiedList': unidRows(_unidentified),
      'unknownList': unidRows(_unknown),
      'caseResponsibility': {
        'ioDesig': _ioDesig,
        'ioName': _ioName.text,
        'regDesig': _regDesig,
        'regName': _regName.text,
        'cctvValue': _cctvVal,
        'cctvDateTime': _cctvDt.text,
      },
      'arrestRelease': _arrestRows
          .map(
            (r) => {
              'accusedName': r['accusedName'],
              'arrestDt': (r['arrestDt'] as TextEditingController?)?.text ?? '',
              'sec47_48': r['sec47_48'] == true,
              'relName': (r['relName'] as TextEditingController?)?.text ?? '',
              'relationship':
                  (r['relationship'] as TextEditingController?)?.text ?? '',
              'relOnNotice': r['relOnNotice'] == true,
              'anticipatoryBail': r['anticipatoryBail'] == true,
              'isDeceased': r['isDeceased'] == true,
              'deathDt': (r['deathDt'] as TextEditingController?)?.text ?? '',
            },
          )
          .toList(),
      'cctvChecked': _cctvChecked,
      'cdrSent': _cdrSent.text,
      'cdrRecv': _cdrRecv.text,
      'proceduralChecks': Map<String, bool>.from(_procChecks),
      'proceduralDates': _procDates.map((k, v) => MapEntry(k, v.text)),
      'eshakshValue': _eshaksh,
      'eshakshDt': _eDt.text,
      'eshakshReason': _eReason.text,
      'investigationNotes': {
        'fingerprintVal': _fingerprintVal,
        'fingerprintDate': _fingerprintDate.text,
        'fingerprintReason': _fingerprintReason.text,
        'nafisFingerprint': _nafisFingerprint,
      },
      'seizures': _seizures
          .map(
            (s) => {
              'desc': (s['desc'] as TextEditingController).text,
              'quantity': (s['quantity'] as TextEditingController).text,
              'serialNo': (s['serialNo'] as TextEditingController).text,
              'estValue': (s['estValue'] as TextEditingController).text,
              'status': s['status'],
              'recoveryDate': (s['recoveryDate'] as TextEditingController).text,
              'seizureDetails':
                  (s['seizureDetails'] as TextEditingController).text,
              'custodyLoc': (s['custodyLoc'] as TextEditingController).text,
              'fromWhom': s['fromWhom'],
              'otherName': (s['otherName'] as TextEditingController).text,
            },
          )
          .toList(),
      'custodyInfo': _custodyRows
          .map(
            (c) => {
              'accusedName': c['accusedName'],
              'pcrDays': (c['pcrDays'] as TextEditingController?)?.text ?? '',
              'isMcr': c['isMcr'] == true,
              'isPrBond': c['isPrBond'] == true,
              'isBail': c['isBail'] == true,
              'isJail': c['isJail'] == true,
              'mcrJail': (c['mcrJail'] as TextEditingController?)?.text ?? '',
              'suretyName':
                  (c['suretyName'] as TextEditingController?)?.text ?? '',
              'suretyAge':
                  (c['suretyAge'] as TextEditingController?)?.text ?? '',
              'suretyGender': c['suretyGender'] ?? 'Male',
              'suretyOcc':
                  (c['suretyOcc'] as TextEditingController?)?.text ?? '',
              'suretyMobile':
                  (c['suretyMobile'] as TextEditingController?)?.text ?? '',
              'suretyAadhaar':
                  (c['suretyAadhaar'] as TextEditingController?)?.text ?? '',
              'suretyPan':
                  (c['suretyPan'] as TextEditingController?)?.text ?? '',
              'suretyAddress':
                  (c['suretyAddress'] as TextEditingController?)?.text ?? '',
              'suretyRel':
                  (c['suretyRel'] as TextEditingController?)?.text ?? '',
            },
          )
          .toList(),
      'preventive': {
        'preventiveBonds': _prevBondsVal,
        'action': _prevAction,
        'actionDate': _prevActionDt.text,
        'outwardNumber': _outward.text,
        'bondDate': _bondDate.text,
        'bondReason': _bReason.text,
        'bondCancellation': _bondCancel.text,
      },
      'dischargeByAccused': Map<String, bool>.from(_discharge),
      'dischargeDetails': {
        for (final n in allAccusedNames)
          if (_discharge[n] == true)
            n: {
              'date': _dischargeDates[n]?.text ?? '',
              'reason': _dischargeReasons[n]?.text ?? '',
            },
      },
      'customDischargeList': _customDischargeList
          .map(
            (e) => {
              'name': (e['name'] as TextEditingController).text,
              'date': (e['date'] as TextEditingController).text,
              'reason': (e['reason'] as TextEditingController).text,
            },
          )
          .toList(),
      'court': {
        'chargeSheetNumber': _csNumber.text,
        'chargeSheetDate': _csDate.text,
        'aFinalNo': _aFinalNo.text,
        'bFinalNo': _bFinalNo.text,
        'cFinalNo': _cFinalNo.text,
        'ncFinalNo': _ncFinalNo.text,
        'abatedSummaryNo': _abatedSummaryNo.text,
        'ccStNumber': _ccStNumber.text,
        'stayHighCourtDate': _stayHighCourtDate.text,
        'finalSummary': _finalSummary,
        'quashedHighCourt': _quashDate.text,
      },
      'verdict': {
        'acquitted': List<String>.from(_acquitted),
        'convicted': List<String>.from(_convicted),
      },
      'scrutiny': {
        'sdpoSend': _sdpoSend.text,
        'sdpoGrant': _sdpoGrant.text,
        'dcpSend': _dcpSend.text,
        'dcpGrant': _dcpGrant.text,
        'addlCpSend': _addlCpSend.text,
        'addlCpGrant': _addlCpGrant.text,
        'appSend': _appSend.text,
        'appGrant': _appGrant.text,
        'stepAppActive': _stepApp,
        'stepDcpActive': _stepDcp,
      },
      'dynamic_extra_fields': {
        for (final entry in _dynamicControllers.entries)
          entry.key: entry.value.text,
        for (final entry in _dynamicValues.entries)
          entry.key: entry.value,
      },
    };
  }

  // ─── hydrateFromDocumentMap ────────────────────────────────────────────────
  String _s(dynamic v) {
    if (v == null) return '';
    if (v is Timestamp) {
      final d = v.toDate();
      return '${d.day}/${d.month}/${d.year}';
    }
    return v.toString();
  }

  void hydrateFromDocumentMap(Map<String, dynamic> m) {
    clearForm();
    _crNo.text = _s(m['crNo']);
    _regDate.text = _s(m['regDate']);
    _firPath = m['firCopyPath'] as String?;

    final ch = m['charges'];
    if (ch is Map) {
      for (final e in ch.entries) {
        _chargeSeq++;
        final id = 'charge-$_chargeSeq';
        final raw = e.value as Map?;
        if (raw == null) continue;
        final secs = raw['sections'];
        _chargeData[id] = {
          'act': _s(raw['act']),
          'sections': <String>{
            if (secs is Iterable)
              for (final s in secs) s.toString(),
          },
        };
      }
    }

    _spotVillage.text = _s(m['spotVillage']);
    _spotArea.text = _s(m['spotArea']);
    _spotAddress.text = _s(m['spotAddress']);
    _occurrenceDateTime.text =
        _s(m['occurrenceDateTime'] ?? m['occurrenceDate']);

    _stolenProperties.clear();
    final spList = m['stolenProperties'] as List?;
    if (spList != null && spList.isNotEmpty) {
      for (final sp in spList) {
        if (sp is Map) _stolenProperties.add(_createStolenPropRow(sp));
      }
    } else {
      // Backwards compatibility
      final sp = m['stolenProperty'] as Map?;
      final propDet = m['propertyDetails'] as Map?;
      if (sp != null || propDet != null) {
        final stMap = _createStolenPropRow({});
        (stMap['property'] as TextEditingController).text =
            _s(sp?['property']) != ''
                ? _s(sp?['property'])
                : _s(sp?['description']);
        (stMap['quantity'] as TextEditingController).text =
            _s(sp?['quantity']) != ''
                ? _s(sp?['quantity'])
                : _s(propDet?['quantity']);
        (stMap['estValue'] as TextEditingController).text =
            _s(sp?['estValue']) != ''
                ? _s(sp?['estValue'])
                : _s(propDet?['estValue']);
        (stMap['id'] as TextEditingController).text =
            _s(sp?['id']) != '' ? _s(sp?['id']) : _s(propDet?['id']);
        (stMap['date'] as TextEditingController).text = _s(sp?['date']);
        (stMap['from'] as TextEditingController).text = _s(sp?['from']);

        if (m['vehicleEngineNumber'] != null || m['engineNumber'] != null) {
          stMap['isTwoFourWheeler'] = true;
          (stMap['engineNumber'] as TextEditingController).text =
              _s(m['vehicleEngineNumber'] ?? m['engineNumber']);
          (stMap['chassisNumber'] as TextEditingController).text =
              _s(m['vehicleChassisNumber'] ?? m['chassisNumber']);
          (stMap['regNumber'] as TextEditingController).text =
              _s(m['vehicleRegNumber'] ?? m['regNumber']);
          (stMap['uniqueIdMark'] as TextEditingController).text =
              _s(m['vehicleUniqueIdMark'] ?? m['uniqueIdMark']);
          (stMap['purchaseDate'] as TextEditingController).text =
              _s(m['vehiclePurchaseDate'] ?? m['purchaseDate']);
          stMap['photo'] = m['vehiclePhoto'] == true || m['photo'] == true;
          stMap['ownershipDoc'] =
              m['vehicleOwnershipDoc'] == true || m['ownershipDoc'] == true;
        }
        _stolenProperties.add(stMap);
      }
    }

    _recoveredProperties.clear();
    final rpList = m['recoveredProperties'] as List?;
    if (rpList != null && rpList.isNotEmpty) {
      for (final rp in rpList) {
        if (rp is Map) _recoveredProperties.add(_createRecoveredPropRow(rp));
      }
    } else {
      // Backwards compatibility
      final rp = m['recoveredProperty'] as Map?;
      final propDet = m['propertyDetails'] as Map?;
      final sp = m['stolenProperty'] as Map?;
      if (rp != null ||
          propDet != null ||
          (sp != null && _s(sp['recovered']).isNotEmpty)) {
        final recMap = _createRecoveredPropRow({});
        (recMap['property'] as TextEditingController).text =
            _s(rp?['property']) != ''
                ? _s(rp?['property'])
                : _s(sp?['recovered']);
        (recMap['quantity'] as TextEditingController).text =
            _s(rp?['quantity']);
        (recMap['estValue'] as TextEditingController).text =
            _s(rp?['estValue']);
        (recMap['date'] as TextEditingController).text =
            _s(rp?['date']) != '' ? _s(rp?['date']) : _s(propDet?['recDate']);
        (recMap['from'] as TextEditingController).text =
            _s(rp?['from']) != '' ? _s(rp?['from']) : _s(propDet?['recFrom']);
        _recoveredProperties.add(recMap);
      }
    }

    _isTwoFourWheelerTheft = m['isTwoFourWheelerTheft'] == true ||
        m['isTwoFourWheelerTheft'] == 'true' ||
        (m['vehicleEngineNumber']?.toString().isNotEmpty == true) ||
        (m['vehicleChassisNumber']?.toString().isNotEmpty == true) ||
        (m['vehicleRegNumber']?.toString().isNotEmpty == true) ||
        _isTwoFourWheeler;
    _vehicleEngineNumber.text =
        _s(m['vehicleEngineNumber'] ?? m['engineNumber']);
    _vehicleChassisNumber.text =
        _s(m['vehicleChassisNumber'] ?? m['chassisNumber']);
    _vehicleRegNumber.text = _s(m['vehicleRegNumber'] ?? m['regNumber']);
    _vehicleUniqueIdMark.text =
        _s(m['vehicleUniqueIdMark'] ?? m['uniqueIdMark']);
    _vehiclePurchaseDate.text =
        _s(m['vehiclePurchaseDate'] ?? m['purchaseDate']);
    _vehiclePhoto = m['vehiclePhoto'] == true || m['photo'] == true;
    _vehicleOwnershipDoc =
        m['vehicleOwnershipDoc'] == true || m['ownershipDoc'] == true;

    final comp = m['complainant'] as Map?;
    if (comp != null) {
      final n = _s(comp['name']);
      _compName.text = n.contains('Protected') ? '' : n;
      _compAge.text = _s(comp['age']);
      final g = comp['gender']?.toString();
      if (g != null && _kGenders.contains(g)) _compGender = g;
      _compOcc.text = _s(comp['occ']);
      _compMobile.text = _s(comp['mobile']);
      _compAadhaar.text = _s(comp['aadhaar']);
      _compReligion.text = _s(comp['religion']);
      _compCaste.text = _s(comp['caste']);
      _compPan.text = _s(comp['pan']);
      _compAddress.text = _s(comp['address']);
      _compStatement.text = _s(comp['statement']);
    }

    final victim = m['victim'] as Map?;
    if (victim != null) {
      _vName.text = _s(victim['name']);
      _vAge.text = _s(victim['age']);
      final g = victim['gender']?.toString();
      if (g != null && _kGenders.contains(g)) _vGender = g;
      _vOcc.text = _s(victim['occ']);
      _vMobile.text = _s(victim['mobile']);
      _vAadhaar.text = _s(victim['aadhaar']);
      _vReligion.text = _s(victim['religion']);
      _vCaste.text = _s(victim['caste']);
      _vPan.text = _s(victim['pan']);
      _vAddress.text = _s(victim['address']);
    }

    final deceased = m['deceased'] as Map?;
    if (deceased != null) {
      _dName.text = _s(deceased['name']);
      _dAge.text = _s(deceased['age']);
      final g = deceased['gender']?.toString();
      if (g != null && _kGenders.contains(g)) _dGender = g;
      _dOcc.text = _s(deceased['occ']);
      _dMobile.text = _s(deceased['mobile']);
      _dAadhaar.text = _s(deceased['aadhaar']);
      _dReligion.text = _s(deceased['religion']);
      _dCaste.text = _s(deceased['caste']);
      _dPan.text = _s(deceased['pan']);
      _dAddress.text = _s(deceased['address']);
    }

    final inj = m['injured'] as Map?;
    if (inj != null) {
      _injName.text = _s(inj['name']);
      _injAge.text = _s(inj['age']);
      final g = inj['gender']?.toString();
      if (g != null && _kGenders.contains(g)) _injGender = g;
      _injOcc.text = _s(inj['occ']);
      _injMobile.text = _s(inj['mobile']);
      _injAadhaar.text = _s(inj['aadhaar']);
      _injReligion.text = _s(inj['religion']);
      _injCaste.text = _s(inj['caste']);
      _injPan.text = _s(inj['pan']);
      _injIsDied = inj['isDied'] == true;
      _injDeathDate.text = _s(inj['deathDate']);
      _injDeathTime.text = _s(inj['deathTime']);
      _injAddress.text = _s(inj['address']);
    }

    void applyPerson(Map<String, dynamic> row, Map raw) {
      row['name'] ??= TextEditingController()..addListener(_debouncedSync);
      row['age'] ??= TextEditingController();
      row['gender'] ??= 'Male';
      row['occ'] ??= TextEditingController();
      row['mobile'] ??= TextEditingController();
      row['aadhaar'] ??= TextEditingController();
      row['religion'] ??= TextEditingController();
      row['caste'] ??= TextEditingController();
      row['pan'] ??= TextEditingController();
      row['address'] ??= TextEditingController();

      (row['name'] as TextEditingController).text = _s(raw['name']);
      (row['age'] as TextEditingController).text = _s(raw['age']);
      final g = raw['gender']?.toString();
      if (g != null && _kGenders.contains(g)) row['gender'] = g;
      (row['occ'] as TextEditingController).text = _s(raw['occ']);
      (row['mobile'] as TextEditingController).text = _s(raw['mobile']);
      (row['aadhaar'] as TextEditingController).text = _s(raw['aadhaar']);
      (row['religion'] as TextEditingController).text = _s(raw['religion']);
      (row['caste'] as TextEditingController).text = _s(raw['caste']);
      (row['pan'] as TextEditingController).text = _s(raw['pan']);
      (row['address'] as TextEditingController).text = _s(raw['address']);
    }

    void applyUnid(Map<String, dynamic> row, Map raw) {
      final g = raw['gender']?.toString();
      if (g != null && _kGenders.contains(g)) row['gender'] = g;
      (row['age'] as TextEditingController).text = _s(raw['approxAge']);
      (row['height'] as TextEditingController).text = _s(raw['approxHeight']);
      (row['skin'] as TextEditingController).text = _s(raw['skinColor']);
      (row['occ'] as TextEditingController).text = _s(raw['occupation']);
      (row['markers'] as TextEditingController).text =
          _s(raw['otherPhysicalMarkers']);
      (row['address'] as TextEditingController).text =
          _s(raw['lastKnownAddress']);
      (row['desc'] as TextEditingController).text = _s(raw['description']);
    }

    for (final item in (m['accused'] as List? ?? [])) {
      if (item is! Map) continue;
      addPersonAccused();
      applyPerson(_accused.last, item);
    }
    for (final item in (m['suspectedAccused'] as List? ?? [])) {
      if (item is! Map) continue;
      addPersonSuspected();
      applyPerson(_suspected.last, item);
    }

    for (final item in (m['unidentifiedList'] as List? ?? [])) {
      if (item is! Map) continue;
      addUnidentified();
      applyUnid(_unidentified.last, item);
    }
    for (final item in (m['unknownList'] as List? ?? [])) {
      if (item is! Map) continue;
      addUnknown();
      applyUnid(_unknown.last, item);
    }

    final u = m['unidentified'] as Map?;
    if (u != null && _unidentified.isEmpty) {
      addUnidentified();
      applyUnid(_unidentified.last, u);
    }
    _syncNames();

    final cr = m['caseResponsibility'] as Map?;
    if (cr != null) {
      final iod = cr['ioDesig']?.toString();
      if (iod != null && PoliceDesignations.ioDesignations.contains(iod)) {
        _ioDesig = iod;
      }
      _ioName.text = _s(cr['ioName']);
      final rd = cr['regDesig']?.toString();
      if (rd != null && PoliceDesignations.formIoAndReg.contains(rd)) {
        _regDesig = rd;
      }
      _regName.text = _s(cr['regName']);
      _cctvVal = cr['cctvValue'] as String?;
      _cctvDt.text = _s(cr['cctvDateTime']);
    }

    for (final r0 in (m['arrestRelease'] as List? ?? [])) {
      if (r0 is! Map) continue;
      final name = _s(r0['accusedName']);
      final row = _arrestRows.firstWhere(
        (r) => r['accusedName'] == name,
        orElse: () => {},
      );
      if (row.isEmpty) continue;
      (row['arrestDt'] as TextEditingController?)?.text = _s(r0['arrestDt']);
      row['sec47_48'] = r0['sec47_48'] == true || r0['sec47_48'] == 'true';
      (row['relName'] as TextEditingController?)?.text = _s(r0['relName']);
      (row['relationship'] as TextEditingController?)?.text =
          _s(r0['relationship']);
      row['relOnNotice'] = r0['relOnNotice'] == true ||
          r0['relOnNotice'] == 'true' ||
          r0['relOnNotice'] == 'yes';
      row['anticipatoryBail'] = r0['anticipatoryBail'] == true ||
          r0['anticipatoryBail'] == 'true' ||
          r0['releaseType'] == 'Anticipatory';
      row['isDeceased'] =
          r0['isDeceased'] == true || r0['isDeceased'] == 'true';
      (row['deathDt'] as TextEditingController?)?.text =
          _s(r0['deathDt'] ?? r0['dateOfDeath']);
    }

    _cctvChecked = m['cctvChecked'] == true ||
        m['cctvChecked'] == 'true' ||
        m['cctvChecked'] == 'yes';

    final pc = m['proceduralChecks'] as Map?;
    if (pc != null) {
      for (final e in pc.entries) {
        final k = e.key.toString();
        if (_procChecks.containsKey(k) && e.value is bool) {
          _procChecks[k] = e.value as bool;
        }
      }
    }
    final pd = m['proceduralDates'] as Map?;
    if (pd != null) {
      for (final e in pd.entries) {
        final k = e.key.toString();
        if (_procDates.containsKey(k)) _procDates[k]!.text = _s(e.value);
      }
    }
    _eshaksh = m['eshakshValue'] as String?;
    _eDt.text = _s(m['eshakshDt']);
    _eReason.text = _s(m['eshakshReason']);

    final inv = m['investigationNotes'] as Map?;
    if (inv != null) {
      _fingerprintVal = inv['fingerprintVal'] as String?;
      _fingerprintDate.text = _s(inv['fingerprintDate']);
      _fingerprintReason.text = _s(inv['fingerprintReason']);
      _nafisFingerprint = inv['nafisFingerprint'] as String?;
      if (_fingerprintVal == null && inv['fingerprint'] != null) {
        _fingerprintReason.text = _s(inv['fingerprint']);
        _fingerprintVal = 'no';
      }
    }

    for (final s0 in (m['seizures'] as List? ?? [])) {
      if (s0 is! Map) continue;
      _seizures.add({
        'desc': TextEditingController(text: _s(s0['desc'])),
        'quantity': TextEditingController(text: _s(s0['quantity'])),
        'serialNo': TextEditingController(text: _s(s0['serialNo'])),
        'estValue': TextEditingController(text: _s(s0['estValue'])),
        'status': s0['status'] as String? ?? 'Recovered',
        'recoveryDate': TextEditingController(text: _s(s0['recoveryDate'])),
        'seizureDetails': TextEditingController(text: _s(s0['seizureDetails'])),
        'custodyLoc': TextEditingController(text: _s(s0['custodyLoc'])),
        'fromWhom': s0['fromWhom'] as String?,
        'otherName': TextEditingController(text: _s(s0['otherName'])),
      });
    }

    _cdrSent.text = _s(m['cdrSent']);
    _cdrRecv.text = _s(m['cdrRecv']);

    for (final c0 in (m['custodyInfo'] as List? ?? [])) {
      if (c0 is! Map) continue;
      final name = _s(c0['accusedName']);
      final row = _custodyRows.firstWhere(
        (r) => r['accusedName'] == name,
        orElse: () => {},
      );
      if (row.isEmpty) continue;
      (row['pcrDays'] as TextEditingController).text =
          _s(c0['pcrDays'] ?? c0['pcr']);
      row['isMcr'] = c0['isMcr'] == true ||
          c0['isMcr'] == 'true' ||
          (c0['mcrDays'] != null && _s(c0['mcrDays']).isNotEmpty) ||
          (c0['mcrJail'] != null && _s(c0['mcrJail']).isNotEmpty);
      row['isPrBond'] = c0['isPrBond'] == true ||
          c0['isPrBond'] == 'true' ||
          (c0['prBondDate'] != null && _s(c0['prBondDate']).isNotEmpty);
      row['isBail'] = c0['isBail'] == true ||
          c0['isBail'] == 'true' ||
          (c0['bailType'] != null && c0['bailType'] != 'None') ||
          (c0['suretyName'] != null && _s(c0['suretyName']).isNotEmpty);
      row['isJail'] = c0['isJail'] == true ||
          c0['isJail'] == 'true' ||
          (c0['mcrJail'] != null && _s(c0['mcrJail']).isNotEmpty);
      (row['mcrJail'] as TextEditingController).text = _s(c0['mcrJail']);
      (row['suretyName'] as TextEditingController).text = _s(c0['suretyName']);
      (row['suretyAge'] as TextEditingController).text = _s(c0['suretyAge']);
      row['suretyGender'] = c0['suretyGender'] as String? ?? 'Male';
      (row['suretyOcc'] as TextEditingController).text = _s(c0['suretyOcc']);
      (row['suretyMobile'] as TextEditingController).text =
          _s(c0['suretyMobile']);
      (row['suretyAadhaar'] as TextEditingController).text =
          _s(c0['suretyAadhaar']);
      (row['suretyPan'] as TextEditingController).text = _s(c0['suretyPan']);
      (row['suretyAddress'] as TextEditingController).text =
          _s(c0['suretyAddress']);
      (row['suretyRel'] as TextEditingController).text = _s(c0['suretyRel']);
    }

    final pr = m['preventive'] as Map?;
    if (pr != null) {
      _prevBondsVal =
          (pr['preventiveBonds'] ?? pr['prBond']) as String? ?? 'no';
      _prevAction = pr['action'] as String? ?? '107 Crpc / 126 BNSS';
      _prevActionDt.text = _s(pr['actionDate']);
      _outward.text = _s(pr['outwardNumber']);
      _bondDate.text = _s(pr['bondDate']);
      _bReason.text = _s(pr['bondReason']);
      _bondCancel.text = _s(pr['bondCancellation']);
    }

    final dis = m['dischargeByAccused'] as Map?;
    if (dis != null) {
      for (final e in dis.entries) {
        _discharge[e.key.toString()] = e.value == true;
      }
    }
    final disDet = m['dischargeDetails'] as Map?;
    if (disDet != null) {
      for (final e in disDet.entries) {
        final k = e.key.toString();
        if (e.value is Map) {
          final dm = e.value as Map;
          _getDischargeDateCtrl(k).text = _s(dm['date']);
          _getDischargeReasonCtrl(k).text = _s(dm['reason']);
        }
      }
    }

    final customDis = m['customDischargeList'] as List?;
    if (customDis != null) {
      for (final cd in customDis) {
        if (cd is Map) {
          _customDischargeList.add({
            'name': TextEditingController(text: _s(cd['name'])),
            'date': TextEditingController(text: _s(cd['date'])),
            'reason': TextEditingController(text: _s(cd['reason'])),
          });
        }
      }
    }

    final ct = m['court'] as Map?;
    if (ct != null) {
      _csNumber.text = _s(ct['chargeSheetNumber']);
      _csDate.text = _s(ct['chargeSheetDate']);
      _aFinalNo.text = _s(ct['aFinalNo']);
      _bFinalNo.text = _s(ct['bFinalNo']);
      _cFinalNo.text = _s(ct['cFinalNo']);
      _ncFinalNo.text = _s(ct['ncFinalNo']);
      _abatedSummaryNo.text = _s(ct['abatedSummaryNo']);
      _ccStNumber.text = _s(ct['ccStNumber']);
      _stayHighCourtDate.text = _s(ct['stayHighCourtDate']);
      final fsRaw = ct['finalSummary'];
      if (fsRaw is Map) {
        _finalSummary =
            fsRaw.map((k, v) => MapEntry(k.toString(), v.toString()));
      } else {
        _finalSummary = {};
      }
      _quashDate.text = _s(ct['quashedHighCourt']);
    }

    final ver = m['verdict'] as Map?;
    if (ver != null) {
      final aq = ver['acquitted'] as List?;
      if (aq != null) {
        _acquitted.addAll(
          aq.map((x) => x.toString()).where((s) => s.isNotEmpty),
        );
      }
      final cv = ver['convicted'] as List?;
      if (cv != null) {
        _convicted.addAll(
          cv.map((x) => x.toString()).where((s) => s.isNotEmpty),
        );
      }
    }

    final sc = m['scrutiny'] as Map?;
    if (sc != null) {
      _sdpoSend.text = _s(sc['sdpoSend']);
      _sdpoGrant.text = _s(sc['sdpoGrant']);
      _dcpSend.text = _s(sc['dcpSend']);
      _dcpGrant.text = _s(sc['dcpGrant']);
      _addlCpSend.text = _s(sc['addlCpSend']);
      _addlCpGrant.text = _s(sc['addlCpGrant']);
      _appSend.text = _s(sc['appSend']);
      _appGrant.text = _s(sc['appGrant']);
      if (sc['stepAppActive'] is bool) _stepApp = sc['stepAppActive'] as bool;
      if (sc['stepDcpActive'] is bool) _stepDcp = sc['stepDcpActive'] as bool;
    }

    saveBarText = 'Loaded from record';
    setState(() {});
  }

  void hydrateFromModuleRecordBasics(ModuleRecord r) {
    clearForm();
    _crNo.text = r.caseNumber;
    _regDate.text =
        '${r.incidentDate.day}/${r.incidentDate.month}/${r.incidentDate.year}';
    _compName.text = r.complainant;
    _spotAddress.text = r.location;
    final acc = r.accused.trim();
    if (acc.isNotEmpty) {
      addPersonAccused();
      (_accused.last['name'] as TextEditingController).text = acc;
      _syncNames();
    }
    setState(() {});
  }

  // ══════════════════════════════════════════════════════════════════════════
  // UI
  // ══════════════════════════════════════════════════════════════════════════

  // ─── shared decorations ────────────────────────────────────────────────────
  InputDecoration _d(String label) => InputDecoration(
        labelText: TranslationHelper.translate(context, label),
        labelStyle: _tsLabel,
        floatingLabelStyle: _tsLabel.copyWith(color: _kTeal),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: _kInputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kTeal, width: 1.5),
        ),
      );

  // ─── section card ──────────────────────────────────────────────────────────
  Widget _card(
    dynamic idx,
    String title,
    Widget body, {
    bool startOpen = false,
    bool isCollapsible = false,
    Widget? headerAction,
  }) {
    List<Widget>? trailing;
    if (idx is int) {
      trailing = widget.trailingSlotsBySection?[idx];
    }
    final keyStr = '$idx-$title';
    if (!_initializedSectionKeys.contains(keyStr)) {
      _initializedSectionKeys.add(keyStr);
      if (startOpen) {
        _openSectionKeys.add(keyStr);
      }
    }
    final isOpen = !isCollapsible || _openSectionKeys.contains(keyStr);

    final leadingBadge = Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: _kMid,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          '$idx',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: _kCardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: isCollapsible
                ? () {
                    setState(() {
                      if (_openSectionKeys.contains(keyStr)) {
                        _openSectionKeys.remove(keyStr);
                      } else {
                        _openSectionKeys.add(keyStr);
                      }
                    });
                  }
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (idx.toString() != '0') ...[
                    leadingBadge,
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      TranslationHelper.translate(context, title),
                      style: _tsSection,
                    ),
                  ),
                  if (headerAction != null && (!isCollapsible || isOpen)) ...[
                    headerAction,
                    if (isCollapsible) const SizedBox(width: 8),
                  ],
                  if (isCollapsible)
                    Icon(
                      isOpen
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: _kSec,
                    ),
                ],
              ),
            ),
          ),
          if (isOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [body, if (trailing != null) ...trailing],
              ),
            ),
        ],
      ),
    );
  }

  // ─── chip selector (replaces all DropdownButtonFormField) ─────────────────
  Widget _chipSelector({
    required String label,
    required List<String> items,
    required String? selected,
    required ValueChanged<String> onSelect,
    Color activeColor = _kTeal,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(TranslationHelper.translate(context, label), style: _tsLabel),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items.map((item) {
              final active = selected == item;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => onSelect(item),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? activeColor.withValues(alpha: 0.1)
                          : _kInputBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? activeColor : _kBorder,
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      TranslationHelper.translate(context, item),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? activeColor : _kSec,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── yes/no toggle ─────────────────────────────────────────────────────────
  Widget _yesNo(String label, String? val, void Function(String) onPick) {
    return Column(
      key: ValueKey(label),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(TranslationHelper.translate(context, label), style: _tsLabel),
        const SizedBox(height: 6),
        Row(
          children: [
            _yesNoChip('Yes', val == 'yes', _kGreen, () => onPick('yes')),
            const SizedBox(width: 8),
            _yesNoChip('No', val == 'no', _kRed, () => onPick('no')),
          ],
        ),
      ],
    );
  }

  Widget _yesNoChip(
    String label,
    bool active,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.1) : _kInputBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color : _kBorder,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          TranslationHelper.translate(context, label),
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? color : _kSec,
          ),
        ),
      ),
    );
  }

  // ─── compact field row ─────────────────────────────────────────────────────
  Widget _row(List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: children.length == 1
            ? children.first
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: children[i]),
                  ],
                ],
              ),
      );

  Widget _tf(
    String label,
    TextEditingController ctrl, {
    int? maxLines,
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
    VoidCallback? onTap,
    bool enabled = true,
    String? hintText,
    String? helperText,
    Color? helperColor,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    AutovalidateMode? autovalidateMode,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      enabled: enabled,
      inputFormatters: inputFormatters,
      onTap: () {
        if (_isVoiceEnabled) {
          _setActiveVoiceField(label, ctrl);
        }
        onTap?.call();
      },
      validator: validator != null
          ? (v) {
              final res = validator(v);
              if (res != null) {
                return TranslationHelper.translate(context, res);
              }
              return null;
            }
          : null,
      autovalidateMode: autovalidateMode ?? AutovalidateMode.onUserInteraction,
      style: enabled
          ? _tsBody
          : _tsBody.copyWith(color: _kSec, fontStyle: FontStyle.italic),
      onChanged: onChanged,
      decoration: _d(label).copyWith(
        hintText: hintText != null
            ? TranslationHelper.translate(context, hintText)
            : null,
        helperText: helperText != null
            ? TranslationHelper.translate(context, helperText)
            : null,
        helperMaxLines: 2,
        errorMaxLines: 2,
        helperStyle: helperText != null
            ? TextStyle(
                fontSize: 10,
                color: helperColor ?? _kAmber,
                fontWeight: FontWeight.w600,
              )
            : null,
        fillColor: enabled ? _kInputBg : _kBorder.withValues(alpha: 0.35),
      ),
    );
  }

  Widget _relationField(String label, TextEditingController ctrl) {
    return _RelationField(
      label: TranslationHelper.translate(context, label),
      ctrl: ctrl,
      decoration: _d(label).copyWith(fillColor: _kInputBg),
      style: _tsBody,
      otherLabel: TranslationHelper.translate(context, 'Specify Relationship'),
    );
  }

  String _formatDateDdMmYyyy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  DateTime? _parseDateDdMmYyyy(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    final p = s.split('/');
    if (p.length != 3) return null;
    final d = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final y = int.tryParse(p[2]);
    if (d == null || m == null || y == null) return null;
    try {
      final dt = DateTime(y, m, d);
      if (dt.year != y || dt.month != m || dt.day != d) return null;
      return dt;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickDateOnly(
    TextEditingController ctrl, {
    void Function(String)? onChanged,
  }) async {
    final now = DateTime.now();
    final parsed = _parseDateDdMmYyyy(ctrl.text);
    final initial = parsed != null &&
            !parsed.isBefore(DateTime(2000)) &&
            !parsed.isAfter(now)
        ? parsed
        : now;
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDate: initial,
    );
    if (!mounted || picked == null) return;
    setState(() {
      ctrl.text = _formatDateDdMmYyyy(picked);
      onChanged?.call(ctrl.text);
    });
  }

  Widget _dateField(
    String label,
    TextEditingController ctrl, {
    void Function(String)? onChanged,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      enabled: enabled,
      style: enabled
          ? _tsBody
          : _tsBody.copyWith(color: _kSec, fontStyle: FontStyle.italic),
      decoration: _d(label).copyWith(
        fillColor: enabled ? _kInputBg : _kBorder.withValues(alpha: 0.35),
        suffixIcon: IconButton(
          icon: Icon(
            Icons.calendar_today_rounded,
            size: 16,
            color: enabled ? _kTeal : _kBorder,
          ),
          tooltip: enabled ? 'Pick date' : null,
          onPressed:
              enabled ? () => _pickDateOnly(ctrl, onChanged: onChanged) : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minHeight: 36,
            minWidth: 36,
            maxHeight: 36,
            maxWidth: 36,
          ),
        ),
        suffixIconConstraints: const BoxConstraints(
          minHeight: 36,
          minWidth: 36,
          maxHeight: 36,
          maxWidth: 36,
        ),
      ),
      onTap: enabled ? () => _pickDateOnly(ctrl, onChanged: onChanged) : null,
    );
  }

  Widget _radioOptionTile({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color activeColor = _kTeal,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.06) : _kInputBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? activeColor : _kBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: isSelected ? activeColor : _kSec,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                TranslationHelper.translate(context, label),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (activeColor == _kRed ? _kRed : _kDark)
                      : _kDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTimeDdMmYyyyHhMm(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  DateTime? _parseDateTimeDdMmYyyyHhMm(String raw) {
    final s = raw.trim();
    final m = RegExp(
      r'^(\d{2})/(\d{2})/(\d{4})\s+(\d{1,2}):(\d{2})$',
    ).firstMatch(s);
    if (m == null) return null;
    final dd = int.tryParse(m.group(1)!);
    final mo = int.tryParse(m.group(2)!);
    final yy = int.tryParse(m.group(3)!);
    final hh = int.tryParse(m.group(4)!);
    final mm = int.tryParse(m.group(5)!);
    if (dd == null || mo == null || yy == null || hh == null || mm == null) {
      return null;
    }
    if (hh > 23 || mm > 59) return null;
    try {
      final dt = DateTime(yy, mo, dd, hh, mm);
      if (dt.year != yy || dt.month != mo || dt.day != dd) return null;
      return dt;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickDateTimeFor(
    TextEditingController ctrl, {
    void Function(String)? onChanged,
  }) async {
    final now = DateTime.now();
    final parsedExisting = _parseDateTimeDdMmYyyyHhMm(ctrl.text);

    DateTime initialDateDay() {
      if (parsedExisting != null) {
        final dt = parsedExisting;
        if (!dt.isBefore(DateTime(2000)) && !dt.isAfter(now)) return dt;
      }
      return now;
    }

    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDate: initialDateDay(),
    );
    if (!mounted || pickedDate == null) return;

    final p0 = _parseDateTimeDdMmYyyyHhMm(ctrl.text);
    final initialTod = p0 != null &&
            p0.year == pickedDate.year &&
            p0.month == pickedDate.month &&
            p0.day == pickedDate.day
        ? TimeOfDay(hour: p0.hour, minute: p0.minute)
        : TimeOfDay.now();

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTod,
    );
    if (!mounted || pickedTime == null) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    setState(() {
      ctrl.text = _formatDateTimeDdMmYyyyHhMm(combined);
      onChanged?.call(ctrl.text);
    });
  }

  Widget _dateTimeField(
    String label,
    TextEditingController ctrl, {
    String? hintText,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      style: _tsBody,
      decoration: _d(label).copyWith(
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 12, color: _kSec),
        suffixIcon: IconButton(
          icon: const Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: Color(0xFF0284C7),
          ),
          tooltip: 'Pick date & time',
          onPressed: () => _pickDateTimeFor(ctrl, onChanged: onChanged),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minHeight: 36,
            minWidth: 36,
            maxHeight: 36,
            maxWidth: 36,
          ),
        ),
        suffixIconConstraints: const BoxConstraints(
          minHeight: 36,
          minWidth: 36,
          maxHeight: 36,
          maxWidth: 36,
        ),
      ),
      onTap: () => _pickDateTimeFor(ctrl, onChanged: onChanged),
    );
  }

  // ─── section header (inside content) ──────────────────────────────────────
  Widget _subHeader(String t) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text(
          t,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: _kSec,
            letterSpacing: 1,
            textBaseline: TextBaseline.alphabetic,
          ),
        ),
      );

  Widget _divider() =>
      const Divider(height: 20, thickness: 0.5, color: _kBorder);

  // ─── header action button ──────────────────────────────────────────────────
  Widget _headerBtn(
    String label,
    VoidCallback onTap, {
    IconData icon = Icons.add,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _kTeal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _kTeal.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: _kTeal),
              const SizedBox(width: 4),
              Text(
                TranslationHelper.translate(context, label),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _kTeal,
                ),
              ),
            ],
          ),
        ),
      );

  // ─── empty hint ────────────────────────────────────────────────────────────
  Widget _emptyBox(String t) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kInputBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBorder, style: BorderStyle.solid),
        ),
        child: Text(
          TranslationHelper.translate(context, t),
          textAlign: TextAlign.center,
          style: _tsMuted,
        ),
      );

  // ══════════════════════════════════════════════════════════════════════════
  // ROOT BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _kPageBg,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: Column(
          children: [
            // ── scroll progress bar
            ValueListenableBuilder<double>(
              valueListenable: scrollProgress,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 3,
                color: _kTeal,
                backgroundColor: _kBorder,
              ),
            ),
            // ── save bar
            Container(
              color: _kCardBg,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      saveBarText.startsWith('Draft saved')
                          ? '${TranslationHelper.translate(context, 'Draft saved')} ${saveBarText.replaceFirst('Draft saved', '').trim()}'
                          : TranslationHelper.translate(context, saveBarText),
                      style: _tsMuted,
                    ),
                  ),
                  _barBtn('Clear', Icons.refresh_outlined, clearForm, _kRed),
                  const SizedBox(width: 6),
                  _barBtn('Save Draft', Icons.save_outlined, saveDraft, _kTeal),
                  const SizedBox(width: 6),
                  _barBtn(
                    _pdfButtonLabel,
                    Icons.picture_as_pdf_outlined,
                    _generatePdf,
                    const Color(0xFF0284C7),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _kBorder),
            if (_isVoiceEnabled)
              Container(
                color: _kPageBg,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: PocsoVoiceBanner(
                      activeFieldLabel: _activeVoiceFieldLabel,
                      activeSectionName: _activeVoiceSectionName,
                      activeController: _activeVoiceController ?? _crNo,
                    ),
                  ),
                ),
              ),
            // ── form
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: widget.padding,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (kDebugMode && _isUsingFallback)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                border: Border.all(color: Colors.amber.shade700),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color: Colors.amber.shade900, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '[DEV ONLY] Offline fallback data in use (form-definition endpoint unavailable).',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.amber.shade900,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          _card(
                            1,
                            'Crime Registration Info',
                            _s1(),
                            startOpen: true,
                          ),
                          _card(
                            2,
                            'Acts & Sections',
                            _s2(),
                            startOpen: true,
                            headerAction: _headerBtn(
                              'Add',
                              addChargeRow,
                            ),
                          ),
                          _card(3, 'Crime Spot', _s3()),
                          if (widget.middleSlot != null) widget.middleSlot!,
                          if (_extraFields.isNotEmpty)
                            _card(
                              'extra_fields',
                              'Special Section / Template Details (${_extraFields.length})',
                              _sExtraFields(),
                              startOpen: true,
                            ),
                          _card(
                            4,
                            'Complainant',
                            _s4(),
                            isCollapsible: true,
                            startOpen: false,
                          ),
                          _card(
                            5,
                            'Accused',
                            _s5(),
                            isCollapsible: true,
                            startOpen: false,
                            headerAction: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_suspected.isNotEmpty) ...[
                                  _headerBtn('Same as Suspected', () {
                                    if (_accused.isEmpty) {
                                      addPersonAccused();
                                    }
                                    _copyPersonData(
                                      _suspected.first,
                                      _accused.last,
                                    );
                                  }, icon: Icons.copy_rounded),
                                  const SizedBox(width: 6),
                                ],
                                _headerBtn(
                                  'Add Accused',
                                  addPersonAccused,
                                ),
                              ],
                            ),
                          ),
                          _card(
                            6,
                            'Suspected Accused',
                            _s6(),
                            isCollapsible: true,
                            startOpen: false,
                            headerAction: !_isUnknown
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_accused.isNotEmpty) ...[
                                        _headerBtn('Same as Accused', () {
                                          if (_suspected.isEmpty) {
                                            addPersonSuspected();
                                          }
                                          _copyPersonData(
                                            _accused.first,
                                            _suspected.last,
                                          );
                                        }, icon: Icons.copy_rounded),
                                        const SizedBox(width: 6),
                                      ],
                                      _headerBtn(
                                        'Add Suspected',
                                        addPersonSuspected,
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                          _card(
                            7,
                            'Unidentified Accused',
                            _s7(),
                            isCollapsible: true,
                            startOpen: false,
                            headerAction: _headerBtn(
                              'Add Unidentified',
                              addUnidentified,
                            ),
                          ),
                          _card(
                            8,
                            'Unknown Accused',
                            _sUnknown(),
                          ),
                          _card(
                            9,
                            'Case Responsibility',
                            _s8(),
                          ),
                          _card(
                            10,
                            'Arrest',
                            _s9(),
                          ),
                          _card(
                            11,
                            'Custody & Remand (PCR / MCR)',
                            _s10(),
                          ),
                          _card(
                            12,
                            'CCTV & CDR Investigation',
                            _s11(),
                          ),
                          _card(
                            13,
                            'All Panchanama',
                            _s12(),
                          ),
                          _card(
                            14,
                            'Evidence & Seizure',
                            _s13(),
                          ),
                          _card(
                            15,
                            'Preventive Action & Bonds',
                            _s14(),
                          ),
                          _card(
                            16,
                            'Discharge Accused',
                            _s15(),
                            headerAction: _headerBtn(
                              'Add Name',
                              addCustomDischarge,
                            ),
                          ),
                          _card(
                            17,
                            'Scrutiny',
                            _s16(),
                          ),
                          _card(
                            18,
                            'Court Filing & Final Summary',
                            _s17(),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _pdfButtonLabel {
    final label = widget.moduleLabel?.trim() ?? '';
    final sub = widget.subCategory?.trim() ?? '';
    if (label.isNotEmpty) {
      if (label.toLowerCase().endsWith('form')) {
        return 'Generate $label PDF';
      }
      return 'Generate $label Form PDF';
    }
    if (sub.isNotEmpty) {
      if (sub.toLowerCase().endsWith('form')) {
        return 'Generate $sub PDF';
      }
      return 'Generate $sub Form PDF';
    }
    return 'Generate Form PDF';
  }

  Future<void> _generatePdf() async {
    try {
      final doc = buildDocumentMap();
      final label = widget.moduleLabel?.trim() ?? '';
      final sub = widget.subCategory?.trim() ?? '';

      final isCrimeDetail = (widget.moduleKey == 'crime_detail') ||
          label.toLowerCase().contains('crime detail') ||
          sub.toLowerCase().contains('crime detail');

      if (isCrimeDetail) {
        await previewCrimeDetailPdf(context, doc);
      } else {
        final formTitle = label.isNotEmpty
            ? '${label.toUpperCase()} FORM'
            : (sub.isNotEmpty ? '${sub.toUpperCase()} FORM' : 'CASE FORM');
        final formSubtitle = sub.isNotEmpty
            ? '$sub · ${label.isNotEmpty ? label : 'Khakhi Diary'} — Maharashtra Police'
            : '${label.isNotEmpty ? label : 'Khakhi Diary'} — Maharashtra Police';

        await previewFormPdf(
          context,
          doc,
          formTitle: formTitle,
          formSubtitle: formSubtitle,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: $e'),
          backgroundColor: _kRed,
        ),
      );
    }
  }

  Widget _barBtn(String label, IconData icon, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              TranslationHelper.translate(context, label),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SECTION BUILDERS
  // ══════════════════════════════════════════════════════════════════════════

  // ── §1 Crime Registration Info ─────────────────────────────────────────────
  Widget _s1() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row([
            _tf('Cr. No.', _crNo),
            _dateField('Registered Date (dd/mm/yyyy)', _regDate),
          ]),
        ],
      );

  // ── §2 Acts & Sections Filed ───────────────────────────────────────────────
  Widget _s2() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_chargeData.isEmpty)
            _emptyBox('No charges. Tap + Add to begin.')
          else ...[
            ..._chargeData.entries.toList().asMap().entries.map((e) {
              final id = e.value.key;
              final data = e.value.value;
              final num = e.key + 1;
              return _chargeCard(id, num, data);
            }),
            _divider(),
            _subHeader('CHARGE SUMMARY'),
            ..._chargeData.entries.toList().asMap().entries.map((e) {
              final num = e.key + 1;
              final data = e.value.value;
              final act = data['act']?.toString() ?? '';
              final secs = (data['sections'] as Set<String>?) ?? {};
              final actLabel = act.isNotEmpty
                  ? (_activeActsData[act]?['label'] as String? ?? act)
                  : '—';
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2, right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _kDark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#$num',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            actLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _kDark,
                            ),
                          ),
                          if (secs.isNotEmpty)
                            Text(
                              secs.join(', '),
                              style: const TextStyle(
                                fontSize: 10,
                                color: _kSec,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      );

  Widget _chargeCard(String id, int num, Map<String, dynamic> data) {
    final actKey = data['act']?.toString() ?? '';
    final hasAct = actKey.isNotEmpty && _activeActsData.containsKey(actKey);
    final secs = (data['sections'] as Set<String>?) ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Charge #$num',
                    style: _tsSection.copyWith(fontSize: 11)),
              ),
              GestureDetector(
                onTap: () => _removeCharge(id),
                child: const Icon(Icons.close, size: 16, color: _kRed),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: hasAct ? actKey : null,
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(8),
            menuMaxHeight: 320,
            isExpanded: true,
            decoration: _d('Act / Law'),
            style: _tsBody,
            icon: const Icon(Icons.arrow_drop_down, color: _kTeal),
            hint: Text(
              TranslationHelper.translate(context, 'Select Act / Law'),
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            items: _activeActsData.entries.map((e) {
              return DropdownMenuItem<String>(
                value: e.key,
                child: Text(
                  e.value['label'] as String,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                ),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) {
                _onActChange(id, v);
              }
            },
          ),
          if (hasAct) ...[
            const SizedBox(height: 4),
            Text(
              _activeActsData[actKey]?['hint'] as String? ?? '',
              style: const TextStyle(
                  fontSize: 10, color: _kAmber, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            const Text('Section(s) — tap to add', style: _tsLabel),
            const SizedBox(height: 4),
            _SectionSearchPicker(
              actKey: actKey,
              selected: secs,
              actsData: _activeActsData,
              onAdd: (v) => _addSection(id, v),
              onRemove: (v) => _removeSection(id, v),
            ),
          ],
        ],
      ),
    );
  }

  // ── §3 Crime Spot ─────────────────────────────────────────────────────────
  Widget _s3() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row([
            _tf('Village', _spotVillage),
            _tf('Area', _spotArea),
          ]),
          _row([
            _tf('Spot Address', _spotAddress),
          ]),
          _dateTimeField(
            'Date & Time of Occurrence',
            _occurrenceDateTime,
          ),
        ],
      );

  // ── Dynamic Extra Template Fields (Backend Form-Definition Engine) ──────────
  Widget _buildDynamicField(Map<String, dynamic> f) {
    final key = f['field_key']?.toString() ?? '';
    final label = f['field_label']?.toString() ?? key;
    final type = f['field_type']?.toString().toLowerCase() ?? 'text';
    final isReq = f['is_required'] == true;
    final displayLabel = isReq ? '$label *' : label;

    if (type == 'textarea') {
      final ctrl = _dynamicControllers[key] ??= TextEditingController();
      return _tf(displayLabel, ctrl, maxLines: 3);
    } else if (type == 'number') {
      final ctrl = _dynamicControllers[key] ??= TextEditingController();
      return _tf(displayLabel, ctrl, keyboardType: TextInputType.number);
    } else if (type == 'date') {
      final ctrl = _dynamicControllers[key] ??= TextEditingController();
      return _dateField(displayLabel, ctrl);
    } else if (type == 'datetime') {
      final ctrl = _dynamicControllers[key] ??= TextEditingController();
      return _dateTimeField(displayLabel, ctrl);
    } else if (type == 'checkbox') {
      final isChecked = _dynamicValues[key] == true;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isChecked ? _kTeal.withValues(alpha: 0.06) : _kInputBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isChecked ? _kTeal : _kBorder),
        ),
        child: Row(
          children: [
            Checkbox(
              value: isChecked,
              activeColor: _kTeal,
              onChanged: (v) => setState(() => _dynamicValues[key] = v ?? false),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                TranslationHelper.translate(context, displayLabel),
                style: _tsBody.copyWith(
                  fontWeight: isChecked ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (type == 'dropdown') {
      final currentVal = _dynamicValues[key]?.toString();
      final isGender = key.toLowerCase().contains('gender');
      final options = isGender ? ['Male', 'Female', 'Other'] : ['Yes', 'No', 'Other'];
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: DropdownButtonFormField<String>(
          initialValue: options.contains(currentVal) ? currentVal : null,
          decoration: _d(displayLabel),
          items: options
              .map((o) => DropdownMenuItem(
                    value: o,
                    child: Text(TranslationHelper.translate(context, o), style: _tsBody),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _dynamicValues[key] = v),
        ),
      );
    } else {
      final ctrl = _dynamicControllers[key] ??= TextEditingController();
      return _tf(displayLabel, ctrl);
    }
  }

  Widget _sExtraFields() {
    if (_extraFields.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: _emptyBox('No additional fields required for this category.'),
      );
    }

    final List<Widget> children = [];
    int i = 0;
    while (i < _extraFields.length) {
      final f1 = _extraFields[i];
      final type1 = f1['field_type']?.toString().toLowerCase() ?? 'text';
      if (type1 == 'textarea' || type1 == 'checkbox' || i == _extraFields.length - 1) {
        children.add(_buildDynamicField(f1));
        i++;
      } else {
        final f2 = _extraFields[i + 1];
        final type2 = f2['field_type']?.toString().toLowerCase() ?? 'text';
        if (type2 == 'textarea' || type2 == 'checkbox') {
          children.add(_buildDynamicField(f1));
          i++;
        } else {
          children.add(_row([
            _buildDynamicField(f1),
            _buildDynamicField(f2),
          ]));
          i += 2;
        }
      }
      if (i < _extraFields.length) {
        children.add(const SizedBox(height: 8));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _victimIdentityProtectionWarning(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _kRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 15, color: _kRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              TranslationHelper.translate(
                context,
                'You cannot enter victim details in sexual offence',
              ),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _kRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── §4 Complainant ────────────────────────────────────────────────────────
  Widget _s4() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isRapeCase) _victimIdentityProtectionWarning(context),
          _row([
            _tf(
              'Name',
              _compName,
              enabled: !_isRapeCase,
              hintText: _isRapeCase ? 'Identity Protected by Law' : null,
            ),
            _tf('Age', _compAge, keyboardType: TextInputType.number),
          ]),
          _row([
            _chipSelector(
              label: 'Gender',
              items: _kGenders,
              selected: _compGender,
              onSelect: (v) => setState(() => _compGender = v),
            ),
          ]),
          _row([
            _tf('Occupation', _compOcc),
            _tf(
              'Mobile Number',
              _compMobile,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (v) => AppValidators.indianMobile(v, required: true),
            ),
          ]),
          _row([
            _tf(
              'Aadhaar Number',
              _compAadhaar,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              validator: AppValidators.aadhaar,
            ),
            _tf(
              'PAN Number',
              _compPan,
              inputFormatters: [
                UpperCaseTextFormatter(),
                LengthLimitingTextInputFormatter(10),
              ],
              validator: AppValidators.pan,
            ),
          ]),
          _row([_tf('Religion', _compReligion), _tf('Caste', _compCaste)]),
          _row([_tf('Address', _compAddress, maxLines: 2)]),
        ],
      );

  // ── §6 Accused ────────────────────────────────────────────────────────────
  Widget _s5() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_accused.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _emptyBox('No accused added.'),
            )
          else
            ..._accused.asMap().entries.map(
                  (e) => _personCard(
                    title: 'Accused #${e.key + 1}',
                    row: e.value,
                    onRemove: () => removePersonAccused(e.key),
                    otherList: _suspected,
                    otherLabel: 'Suspected',
                  ),
                ),
        ],
      );

  // ── §6 Suspected Accused ──────────────────────────────────────────────────
  Widget _s6() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_suspected.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _emptyBox('No suspected accused added.'),
            )
          else
            ..._suspected.asMap().entries.map(
                  (e) => _personCard(
                    title: 'Suspected #${e.key + 1}',
                    row: e.value,
                    onRemove: () => removePersonSuspected(e.key),
                    otherList: _accused,
                    otherLabel: 'Accused',
                  ),
                ),
        ],
      );

  // ─── person card (used in §5 & §6) ────────────────────────────────────────
  Widget _personCard({
    required String title,
    required Map<String, dynamic> row,
    required VoidCallback onRemove,
    List<Map<String, dynamic>>? otherList,
    String? otherLabel,
  }) {
    row['name'] ??= TextEditingController()..addListener(_debouncedSync);
    row['age'] ??= TextEditingController();
    row['gender'] ??= 'Male';
    row['occ'] ??= TextEditingController();
    row['mobile'] ??= TextEditingController();
    row['aadhaar'] ??= TextEditingController();
    row['pan'] ??= TextEditingController();
    row['religion'] ??= TextEditingController();
    row['caste'] ??= TextEditingController();
    row['address'] ??= TextEditingController();

    final availableOthers = (otherList ?? [])
        .where(
          (src) =>
              (src['name'] as TextEditingController?)?.text.trim().isNotEmpty ==
                  true ||
              (src['age'] as TextEditingController?)?.text.trim().isNotEmpty ==
                  true ||
              (src['mobile'] as TextEditingController?)
                      ?.text
                      .trim()
                      .isNotEmpty ==
                  true,
        )
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kTeal.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: _tsSection.copyWith(fontSize: 11)),
              ),
              if (availableOthers.isNotEmpty && otherLabel != null) ...[
                if (availableOthers.length == 1)
                  InkWell(
                    onTap: () => _copyPersonData(availableOthers.first, row),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _kTeal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _kTeal.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.copy_rounded,
                            size: 11,
                            color: _kTeal,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            TranslationHelper.translate(
                              context,
                              'Same as $otherLabel',
                            ),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _kTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  PopupMenuButton<int>(
                    tooltip: 'Copy details from $otherLabel',
                    onSelected: (idx) =>
                        _copyPersonData(availableOthers[idx], row),
                    itemBuilder: (ctx) => availableOthers.asMap().entries.map((
                      entry,
                    ) {
                      final n = (entry.value['name'] as TextEditingController?)
                              ?.text
                              .trim() ??
                          '';
                      final displayName =
                          n.isNotEmpty ? n : '$otherLabel #${entry.key + 1}';
                      return PopupMenuItem<int>(
                        value: entry.key,
                        child: Text(
                          '${TranslationHelper.translate(ctx, 'Copy from')} $displayName',
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: _kTeal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _kTeal.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.copy_rounded,
                            size: 11,
                            color: _kTeal,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            TranslationHelper.translate(
                              context,
                              'Copy from $otherLabel',
                            ),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _kTeal,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            size: 14,
                            color: _kTeal,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              TextButton(
                onPressed: onRemove,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: Size.zero,
                  foregroundColor: _kRed,
                ),
                child: const Text(
                  '✕ Remove',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (row['isRepeatOffender'] == true)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 14, color: Colors.red),
                  SizedBox(width: 4),
                  Text(
                    'Repeat Offender',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          _row([
            _tf(
              'Name',
              row['name'] as TextEditingController,
              onChanged: (val) {
                _debouncedSync();
                if (otherList != null && otherList.isNotEmpty) {
                  _checkAndAutoFillPerson(row, otherList);
                }
                final valUpper = val.trim().toUpperCase();
                setState(() {
                  row['isRepeatOffender'] = (valUpper == 'JOHN DOE' ||
                      valUpper == 'REPEAT OFFENDER' ||
                      valUpper == 'TEST');
                });
              },
            ),
            _tf(
              'Age',
              row['age'] as TextEditingController,
              keyboardType: TextInputType.number,
            ),
          ]),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _chipSelector(
              label: 'Gender',
              items: _kGenders,
              selected: row['gender'] as String?,
              onSelect: (v) => setState(() => row['gender'] = v),
            ),
          ),
          _row([
            _tf('Occupation', row['occ'] as TextEditingController),
            _tf(
              'Mobile Number',
              row['mobile'] as TextEditingController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (v) => AppValidators.indianMobile(v, required: false),
            ),
          ]),
          _row([
            _tf(
              'Aadhaar Number',
              row['aadhaar'] as TextEditingController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              validator: AppValidators.aadhaar,
            ),
            _tf(
              'PAN Number',
              row['pan'] as TextEditingController,
              inputFormatters: [
                UpperCaseTextFormatter(),
                LengthLimitingTextInputFormatter(10),
              ],
              validator: AppValidators.pan,
            ),
          ]),
          _row([
            _tf('Religion', row['religion'] as TextEditingController),
            _tf('Caste', row['caste'] as TextEditingController),
          ]),
          _row([
            _tf('Address', row['address'] as TextEditingController,
                maxLines: 2),
          ]),
        ],
      ),
    );
  }

  Widget _unidCard({
    required String title,
    required Map<String, dynamic> row,
    required VoidCallback onRemove,
  }) {
    row['age'] ??= TextEditingController();
    row['gender'] ??= 'Male';
    row['skin'] ??= TextEditingController();
    row['occ'] ??= TextEditingController();
    row['markers'] ??= TextEditingController();
    row['height'] ??= TextEditingController();
    row['address'] ??= TextEditingController();
    row['desc'] ??= TextEditingController();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kTeal.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: _tsSection.copyWith(fontSize: 11),
              ),
              TextButton(
                onPressed: onRemove,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: Size.zero,
                  foregroundColor: _kRed,
                ),
                child: const Text(
                  '✕ Remove',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _row([
            _tf(
              'Approximate age',
              row['age'] as TextEditingController,
              keyboardType: TextInputType.number,
            ),
            _tf('Height', row['height'] as TextEditingController),
          ]),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _chipSelector(
              label: 'Gender',
              items: _kGenders,
              selected: row['gender'] as String?,
              onSelect: (v) => setState(() => row['gender'] = v),
            ),
          ),
          _row([
            _tf('Skin colour', row['skin'] as TextEditingController),
            _tf('Possible occupation', row['occ'] as TextEditingController),
          ]),
          _row([
            _tf('Identification mark', row['markers'] as TextEditingController),
          ]),
          _row([
            _tf('Address', row['address'] as TextEditingController,
                maxLines: 2),
          ]),
          _row([
            _tf('Description', row['desc'] as TextEditingController,
                maxLines: 2),
          ]),
        ],
      ),
    );
  }

  // ── §7 Unidentified Accused ───────────────────────────────────────────────
  Widget _s7() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_unidentified.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _emptyBox('No unidentified accused added.'),
            )
          else
            ..._unidentified.asMap().entries.map(
                  (e) => _unidCard(
                    title: 'Unidentified Accused #${e.key + 1}',
                    row: e.value,
                    onRemove: () => removeUnidentified(e.key),
                  ),
                ),
        ],
      );

  // ── §7b Unknown Accused (✓) ───────────────────────────────────────────────
  Widget _sUnknown() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _isUnknown ? _kTeal.withValues(alpha: 0.08) : _kInputBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isUnknown ? _kTeal : _kBorder,
            width: _isUnknown ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              _isUnknown = !_isUnknown;
            });
            _debouncedSync();
          },
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              Checkbox(
                value: _isUnknown,
                activeColor: _kTeal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onChanged: (v) {
                  setState(() {
                    _isUnknown = v ?? false;
                  });
                  _debouncedSync();
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  TranslationHelper.translate(
                    context,
                    'Unknown Accused (✓) / अज्ञात आरोपी',
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _isUnknown ? _kTeal : _kDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  // ── §8 Case Responsibility ─────────────────────────────────────────────────
  Widget _s8() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row([
            DropdownButtonFormField<String>(
              initialValue: PoliceDesignations.ioDesignations.contains(_ioDesig)
                  ? _ioDesig
                  : null,
              dropdownColor: Colors.white,
              isExpanded: true,
              decoration: _d('IO Designation'),
              style: _tsBody,
              icon: const Icon(Icons.arrow_drop_down, color: _kTeal),
              items: PoliceDesignations.ioDesignations.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    TranslationHelper.translate(context, item),
                    style: _tsBody,
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _ioDesig = v);
              },
            ),
            _tf('IO Name', _ioName),
          ]),
          _divider(),
          _row([
            DropdownButtonFormField<String>(
              initialValue: PoliceDesignations.formIoAndReg.contains(_regDesig)
                  ? _regDesig
                  : null,
              dropdownColor: Colors.white,
              isExpanded: true,
              decoration: _d('Registered By Designation'),
              style: _tsBody,
              icon: const Icon(Icons.arrow_drop_down, color: _kTeal),
              items: PoliceDesignations.formIoAndReg.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    TranslationHelper.translate(context, item),
                    style: _tsBody,
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _regDesig = v);
              },
            ),
            _tf('Name', _regName),
          ]),
        ],
      );

  // ── §9 Arrest ─────────────────────────────────────────────────────────────
  Widget _s9() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (allAccusedNames.isEmpty)
          _emptyBox(
            'Add accused/suspected names above to see arrest fields.',
          )
        else
          for (final r in _arrestRows)
            Builder(
              builder: (context) {
                r['arrestDt'] ??= TextEditingController();
                r['sec47_48'] ??= false;
                r['relName'] ??= TextEditingController();
                r['relationship'] ??= TextEditingController();
                r['relOnNotice'] ??= false;
                r['anticipatoryBail'] ??= false;
                r['isDeceased'] ??= false;
                r['deathDt'] ??= TextEditingController();
                final name = r['accusedName'] as String;
                final isSec47 = r['sec47_48'] == true;
                final isRelNotice = r['relOnNotice'] == true;
                final isAnticipatory = r['anticipatoryBail'] == true;
                final isDeceased = r['isDeceased'] == true;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kBorder),
                    color: _kCardBg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Accused name badge
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _kTeal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_rounded,
                                size: 16, color: _kTeal),
                            const SizedBox(width: 8),
                            Text(
                              'Accused: $name',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _kTeal,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Arrest date/time
                      _dateTimeField(
                        'Arrest Date & Time (dd/mm/yyyy hh:mm)',
                        r['arrestDt'] as TextEditingController,
                      ),
                      const SizedBox(height: 12),
                      _divider(),
                      const SizedBox(height: 4),

                      // Information of arrest
                      Text(
                        TranslationHelper.translate(
                            context, 'Information of arrest'),
                        style: _tsSection.copyWith(fontSize: 11, color: _kSec),
                      ),
                      const SizedBox(height: 8),
                      // sec. 47/48 BNSS checkbox
                      InkWell(
                        onTap: () => setState(() => r['sec47_48'] = !isSec47),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSec47
                                ? _kTeal.withValues(alpha: 0.06)
                                : _kInputBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSec47 ? _kTeal : _kBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isSec47,
                                activeColor: _kTeal,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (v) =>
                                    setState(() => r['sec47_48'] = v ?? false),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  TranslationHelper.translate(
                                      context, 'sec. 47/48 BNSS'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSec47
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSec47 ? _kTeal : _kDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _row([
                        _tf(
                          'Relative or friend name',
                          r['relName'] as TextEditingController,
                        ),
                        _relationField(
                          'Relation',
                          r['relationship'] as TextEditingController,
                        ),
                      ]),
                      const SizedBox(height: 10),
                      _divider(),
                      const SizedBox(height: 4),

                      // Release on notice (✓) / Anticipatory bail (✓) / Death of Accused (✓) - Radio Group
                      _radioOptionTile(
                        label: 'Release on notice (✓)',
                        isSelected: isRelNotice,
                        activeColor: _kTeal,
                        onTap: () => setState(() {
                          final next = !isRelNotice;
                          r['relOnNotice'] = next;
                          if (next) {
                            r['anticipatoryBail'] = false;
                            r['isDeceased'] = false;
                            (r['deathDt'] as TextEditingController).clear();
                          }
                        }),
                      ),
                      const SizedBox(height: 8),
                      _radioOptionTile(
                        label: 'Anticipatory bail (✓)',
                        isSelected: isAnticipatory,
                        activeColor: _kTeal,
                        onTap: () => setState(() {
                          final next = !isAnticipatory;
                          r['anticipatoryBail'] = next;
                          if (next) {
                            r['relOnNotice'] = false;
                            r['isDeceased'] = false;
                            (r['deathDt'] as TextEditingController).clear();
                          }
                        }),
                      ),
                      const SizedBox(height: 8),
                      _radioOptionTile(
                        label: 'Death of Accused (✓)',
                        isSelected: isDeceased,
                        activeColor: _kRed,
                        onTap: () => setState(() {
                          final next = !isDeceased;
                          r['isDeceased'] = next;
                          if (next) {
                            r['relOnNotice'] = false;
                            r['anticipatoryBail'] = false;
                          } else {
                            (r['deathDt'] as TextEditingController).clear();
                          }
                        }),
                      ),

                      // When Death of Accused is checked -> show date/time
                      if (isDeceased) ...[
                        const SizedBox(height: 6),
                        _dateTimeField(
                          'Date & Time of Death — $name',
                          r['deathDt'] as TextEditingController,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
      ],
    );
  }

  // ── §10 (Card 11) Custody & Remand (PCR / MCR) ───────────────────────────
  Widget _s10() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_custodyRows.isEmpty)
            _emptyBox('Add accused above to set PCR / MCR custody details.')
          else
            ...List.generate(_custodyRows.length, (idx) {
              final row = _custodyRows[idx];
              final name =
                  (row['accusedName'] as String?) ?? 'Accused #${idx + 1}';
              final pcrCtrl = row['pcrDays'] as TextEditingController;
              final isMcr = row['isMcr'] == true;
              final isPrBond = row['isPrBond'] == true;
              final isBail = row['isBail'] == true;
              final isJail = row['isJail'] == true;
              final jailCtrl = row['mcrJail'] as TextEditingController;
              final suretyNameCtrl = row['suretyName'] as TextEditingController;
              final suretyAgeCtrl = row['suretyAge'] as TextEditingController;
              final suretyGender = (row['suretyGender'] as String?) ?? 'Male';
              final suretyOccCtrl = row['suretyOcc'] as TextEditingController;
              final suretyMobileCtrl =
                  row['suretyMobile'] as TextEditingController;
              final suretyAadhaarCtrl =
                  row['suretyAadhaar'] as TextEditingController;
              final suretyPanCtrl = row['suretyPan'] as TextEditingController;
              final suretyAddressCtrl =
                  row['suretyAddress'] as TextEditingController;
              final suretyRelCtrl = row['suretyRel'] as TextEditingController;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kInputBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _kDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _row([
                      _tf(
                        'PCR (00 Day)',
                        pcrCtrl,
                        keyboardType: TextInputType.number,
                      ),
                      _checkboxTile(
                        'MCR (✓)',
                        isMcr,
                        (v) => setState(() => row['isMcr'] = v),
                      ),
                    ]),
                    if (isMcr) ...[
                      const SizedBox(height: 8),
                      _row([
                        _checkboxTile(
                          'PR bond (✓)',
                          isPrBond,
                          (v) => setState(() => row['isPrBond'] = v),
                        ),
                        _checkboxTile(
                          'Jail (✓)',
                          isJail,
                          (v) => setState(() => row['isJail'] = v),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      _yesNo(
                        'Bail(✓) Y/N',
                        isBail ? 'yes' : 'no',
                        (v) => setState(() => row['isBail'] = (v == 'yes')),
                      ),
                      if (isBail) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _kTeal.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _subHeader('SURETY NAME (—KYC -)'),
                              _tf('Surety Name', suretyNameCtrl),
                              const SizedBox(height: 8),
                              _row([
                                _tf(
                                  'Surety Age',
                                  suretyAgeCtrl,
                                  keyboardType: TextInputType.number,
                                ),
                                _chipSelector(
                                  label: 'Surety Gender',
                                  items: _kGenders,
                                  selected: suretyGender,
                                  onSelect: (v) =>
                                      setState(() => row['suretyGender'] = v),
                                ),
                              ]),
                              const SizedBox(height: 8),
                              _row([
                                _tf('Surety Occupation', suretyOccCtrl),
                                _tf(
                                  'Surety Mobile No.',
                                  suretyMobileCtrl,
                                  keyboardType: TextInputType.phone,
                                ),
                              ]),
                              const SizedBox(height: 8),
                              _row([
                                _tf(
                                  'Surety Aadhaar No.',
                                  suretyAadhaarCtrl,
                                  keyboardType: TextInputType.number,
                                ),
                                _tf('Surety PAN No.', suretyPanCtrl),
                              ]),
                              const SizedBox(height: 8),
                              _tf(
                                'Surety Address',
                                suretyAddressCtrl,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 8),
                              _relationField(
                                'Relation with Accused',
                                suretyRelCtrl,
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (isJail) ...[
                        const SizedBox(height: 8),
                        _tf('Jail Name / Details', jailCtrl),
                      ],
                    ],
                  ],
                ),
              );
            }),
        ],
      );

  int _countWords(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  Widget _checkboxTile(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: value ? _kTeal.withValues(alpha: 0.05) : _kInputBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? _kTeal : _kBorder,
            width: value ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: value ? _kTeal : _kSec,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                TranslationHelper.translate(context, label),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: value ? FontWeight.w700 : FontWeight.w500,
                  color: value ? _kDark : _kSec,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── §11 (Card 12) CCTV & CDR Investigation ────────────────────────────────
  Widget _s11() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _checkboxTile(
            'CCTV checked ✔️',
            _cctvChecked,
            (v) => setState(() => _cctvChecked = v),
          ),
          const SizedBox(height: 12),
          _row([
            _dateField('CDR send Date', _cdrSent),
            _dateField('CDR Received date', _cdrRecv),
          ]),
        ],
      );

  // ── §12 (Card 13) All Panchanama ──────────────────────────────────────────
  Widget _s12() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _subHeader('ALL PANCHANAMA (SELECT TO ADD DATE & TIME)'),
          ..._activeProceduralKeys.entries.map((e) {
            final on = _procChecks[e.key] ?? false;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: on ? _kTeal.withValues(alpha: 0.04) : _kInputBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: on ? _kTeal : _kBorder,
                    width: on ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => toggleProcedural(e.key, !on),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              on
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              size: 18,
                              color: on ? _kTeal : _kSec,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                TranslationHelper.translate(context, e.value),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      on ? FontWeight.w700 : FontWeight.w500,
                                  color: on ? _kDark : _kSec,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (on) ...[
                      const SizedBox(height: 8),
                      _dateTimeField(
                        'Date & Time — ${e.value}',
                        _procDates[e.key]!,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      );

  // ── §13 (Card 14) Evidence & Seizure ──────────────────────────────────────
  Widget _s13() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _yesNo(
            'E Shaksh',
            _eshaksh,
            (v) => setState(() => _eshaksh = v),
          ),
          if (_eshaksh == 'yes') ...[
            const SizedBox(height: 10),
            _dateTimeField('E-Shakshya Date & Time', _eDt),
          ] else if (_eshaksh == 'no') ...[
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tf(
                  'Reason for No E-Shakshya (minimum 30 words)',
                  _eReason,
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 4),
                Builder(
                  builder: (ctx) {
                    final words = _countWords(_eReason.text);
                    final isComplete = words >= 30;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isComplete
                              ? TranslationHelper.translate(
                                  ctx,
                                  'Word requirement met',
                                )
                              : '$words / 30 words',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isComplete ? _kGreen : _kAmber,
                          ),
                        ),
                        if (!isComplete)
                          Text(
                            '${30 - words} more words needed',
                            style: const TextStyle(
                              fontSize: 10,
                              color: _kAmber,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _row([
            _yesNo(
              'Fingerprint taken',
              _fingerprintVal,
              (v) => setState(() => _fingerprintVal = v),
            ),
            _yesNo(
              'Nafis Fingerprint',
              _nafisFingerprint,
              (v) => setState(() => _nafisFingerprint = v),
            ),
          ]),
          _divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _subHeader('SEIZURE PROPERTY DETAILS'),
              _headerBtn(
                'Add Seized Property',
                addSeizure,
              ),
            ],
          ),
          if (_seizures.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                TranslationHelper.translate(
                  context,
                  'No seizure items added yet. Click "Add Seized Property" to add property.',
                ),
                style: _tsMuted,
              ),
            ),
          ...List.generate(_seizures.length, (i) {
            final s = _seizures[i];
            final descCtrl = s['desc'] as TextEditingController;
            final otherNameCtrl = s['otherName'] as TextEditingController;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kInputBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${TranslationHelper.translate(context, 'Item')} #${i + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _kDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: _kRed, size: 18),
                        onPressed: () => removeSeizure(i),
                        tooltip:
                            TranslationHelper.translate(context, 'Remove Item'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _tf('Seizure description', descCtrl),
                  const SizedBox(height: 10),
                  _PersonSelectOrCustomField(
                    label: 'From whom - name',
                    options: allAccusedNames,
                    ctrl: otherNameCtrl,
                    decoration:
                        _d('From whom - name').copyWith(fillColor: _kInputBg),
                    style: _tsBody,
                    otherLabel: 'Type new name',
                    onChanged: (v) {
                      s['fromWhom'] = v;
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      );

  // ── §14 (Card 15) Preventive Action & Bonds ───────────────────────────────
  Widget _s14() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              initialValue:
                  _activePreventiveItems.contains(_prevAction) ? _prevAction : null,
              dropdownColor: Colors.white,
              isExpanded: true,
              decoration: _d('Preventive Action'),
              style: _tsBody,
              icon: const Icon(Icons.arrow_drop_down, color: _kTeal),
              items: _activePreventiveItems.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    TranslationHelper.translate(context, item),
                    style: _tsBody,
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _prevAction = v),
            ),
          ),
          _row([
            _dateField('Action Date', _prevActionDt),
            _tf('Outward Number (Optional)', _outward),
          ]),
          _divider(),
          _row([
            _dateField('Bond date', _bondDate),
            _dateField('Bond cancellation date', _bondCancel),
          ]),
          const SizedBox(height: 10),
          _tf(
            'Reason for PR Bond',
            _bReason,
            maxLines: 2,
          ),
        ],
      );

  // ── §15 (Card 16) Discharge Accused ───────────────────────────────────────
  Widget _s15() {
    final arrested = <String>[];
    for (final r in _arrestRows) {
      final name = (r['accusedName'] as String?)?.trim() ?? '';
      final dt = (r['arrestDt'] as TextEditingController?)?.text.trim() ?? '';
      final hasArrest = dt.isNotEmpty ||
          r['sec47_48'] == true ||
          r['relOnNotice'] == true ||
          r['anticipatoryBail'] == true;
      if (name.isNotEmpty && hasArrest) {
        arrested.add(name);
      }
    }
    final availableAccused = arrested.isNotEmpty ? arrested : allAccusedNames;
    final dischargedAccused = allAccusedNames.where((n) => _discharge[n] == true).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _subHeader('DISCHARGE ACCUSED (FROM ARREST)'),
        if (availableAccused.isEmpty)
          Text(
            TranslationHelper.translate(
              context,
              'No accused registered in Accused section.',
            ),
            style: _tsMuted,
          )
        else ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              dropdownColor: Colors.white,
              isExpanded: true,
              decoration: _d('Select Arrested Accused to Discharge'),
              style: _tsBody,
              icon: const Icon(Icons.arrow_drop_down, color: _kTeal),
              hint: Text(
                TranslationHelper.translate(
                  context,
                  'Select Arrested Accused to Discharge',
                ),
                style: _tsMuted,
              ),
              items: availableAccused.map((name) {
                final isAlreadyDischarged = _discharge[name] == true;
                return DropdownMenuItem<String>(
                  value: name,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: _tsBody),
                      if (isAlreadyDischarged)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _kTeal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            TranslationHelper.translate(context, 'Discharged'),
                            style: const TextStyle(
                              fontSize: 11,
                              color: _kTeal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (selectedName) {
                if (selectedName != null) {
                  setState(() {
                    _discharge[selectedName] = true;
                  });
                }
              },
            ),
          ),
          if (dischargedAccused.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                TranslationHelper.translate(
                  context,
                  'No accused currently marked as discharged. Select an accused from the dropdown above to discharge.',
                ),
                style: _tsMuted,
              ),
            )
          else
            ...dischargedAccused.map((name) {
              final dateCtrl = _getDischargeDateCtrl(name);
              final reasonCtrl = _getDischargeReasonCtrl(name);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kTeal.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kTeal),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 18, color: _kTeal),
                            const SizedBox(width: 8),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _kDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _kTeal.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                TranslationHelper.translate(context, 'Discharged'),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: _kTeal,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: _kRed),
                          tooltip: TranslationHelper.translate(context, 'Remove Discharge'),
                          onPressed: () {
                            setState(() {
                              _discharge[name] = false;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _row([
                      _dateField('Discharge Date', dateCtrl),
                      _tf('Discharge Reason', reasonCtrl),
                    ]),
                  ],
                ),
              );
            }),
        ],
          _divider(),
          _subHeader('ADDITIONAL DISCHARGED PERSONS'),
          if (_customDischargeList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                TranslationHelper.translate(
                  context,
                  'No custom persons added. Click "+ Add Name" on top to add more.',
                ),
                style: _tsMuted,
              ),
            ),
          ...List.generate(_customDischargeList.length, (idx) {
            final item = _customDischargeList[idx];
            final nameCtrl = item['name'] as TextEditingController;
            final dateCtrl = item['date'] as TextEditingController;
            final reasonCtrl = item['reason'] as TextEditingController;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kInputBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${TranslationHelper.translate(context, 'Person')} #${idx + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _kDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: _kRed, size: 18),
                        onPressed: () => removeCustomDischarge(idx),
                        tooltip: TranslationHelper.translate(
                            context, 'Remove Person'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _tf('Person Name', nameCtrl),
                  const SizedBox(height: 8),
                  _row([
                    _dateField('Discharge Date', dateCtrl),
                    _tf('Discharge Reason', reasonCtrl),
                  ]),
                ],
              ),
            );
          }),
        ],
      );
  }

  // ── §16 (Card 17) Scrutiny ────────────────────────────────────────────────
  Widget _s16() {
    final sdpoSendOk = _sdpoSend.text.trim().isNotEmpty;
    final sdpoGrantOk = _sdpoGrant.text.trim().isNotEmpty;
    final dcpSendOk = _dcpSend.text.trim().isNotEmpty;
    final dcpGrantOk = _dcpGrant.text.trim().isNotEmpty;
    final addlCpSendOk = _addlCpSend.text.trim().isNotEmpty;
    final addlCpGrantOk = _addlCpGrant.text.trim().isNotEmpty;
    final appSendOk = _appSend.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _scrutinyStep(
          step: 1,
          title: 'SDPO / ACP',
          active: true,
          sendCtrl: _sdpoSend,
          grantCtrl: _sdpoGrant,
          sendEnabled: true,
          grantEnabled: sdpoSendOk,
          onSendChanged: (_) => setState(() {}),
          onGrantChanged: (_) => setState(() {}),
        ),
        _scrutinyStep(
          step: 2,
          title: 'Addl. SP / DCP',
          active: sdpoGrantOk,
          sendCtrl: _dcpSend,
          grantCtrl: _dcpGrant,
          sendEnabled: sdpoGrantOk,
          grantEnabled: dcpSendOk,
          onSendChanged: (_) => setState(() {}),
          onGrantChanged: (_) => setState(() {}),
        ),
        _scrutinyStep(
          step: 3,
          title: 'Addl. CP',
          active: dcpGrantOk,
          sendCtrl: _addlCpSend,
          grantCtrl: _addlCpGrant,
          sendEnabled: dcpGrantOk,
          grantEnabled: addlCpSendOk,
          onSendChanged: (_) => setState(() {}),
          onGrantChanged: (_) => setState(() {}),
        ),
        _scrutinyStep(
          step: 4,
          title: 'APP',
          active: addlCpGrantOk,
          sendCtrl: _appSend,
          grantCtrl: _appGrant,
          sendEnabled: addlCpGrantOk,
          grantEnabled: appSendOk,
          onSendChanged: (_) => setState(() {}),
          onGrantChanged: (_) => setState(() {}),
          isLast: true,
        ),
      ],
    );
  }

  // ── §17 (Card 18) Court Filing & Final Summary ────────────────────────────
  Widget _s17() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row([
            _tf('Charge Sheet No', _csNumber),
            _dateField('Charge Sheet Date', _csDate),
          ]),
          const SizedBox(height: 10),
          _row([
            _tf('A Final Number', _aFinalNo),
            _tf('B Final Number', _bFinalNo),
          ]),
          const SizedBox(height: 10),
          _row([
            _tf('C Final Number', _cFinalNo),
            _tf('NC Final Number', _ncFinalNo),
          ]),
          const SizedBox(height: 10),
          _tf('Abeted summary no.', _abatedSummaryNo),
          _divider(),
          _row([
            _dateField('Stay by High Court Date', _stayHighCourtDate),
            _dateField('Quashed by High Court', _quashDate),
          ]),
        ],
      );

  Widget _scrutinyStep({
    required int step,
    required String title,
    required bool active,
    required TextEditingController sendCtrl,
    required TextEditingController grantCtrl,
    bool sendEnabled = true,
    bool grantEnabled = true,
    void Function(String)? onSendChanged,
    void Function(String)? onGrantChanged,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: active ? _kTeal : _kBorder,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$step',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: active ? _kTeal.withValues(alpha: 0.3) : _kBorder,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TranslationHelper.translate(context, title),
                    style: _tsSection.copyWith(
                      fontSize: 11,
                      color: active ? _kDark : _kSec,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _row([
                    _dateField(
                      'Send Date',
                      sendCtrl,
                      enabled: sendEnabled,
                      onChanged: onSendChanged,
                    ),
                    _dateField(
                      'Grant date',
                      grantCtrl,
                      enabled: grantEnabled,
                      onChanged: onGrantChanged,
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _PersonSelectOrCustomField — dropdown of persons (accused) with custom option
// ══════════════════════════════════════════════════════════════════════════════
typedef _PersonSelectOrCustomField = PersonSelectOrCustomField;

// ══════════════════════════════════════════════════════════════════════════════
// _RelationField — relationship dropdown with 'Other' option
// ══════════════════════════════════════════════════════════════════════════════
class _RelationField extends StatefulWidget {
  const _RelationField({
    required this.label,
    required this.ctrl,
    required this.decoration,
    required this.style,
    required this.otherLabel,
  });
  final String label;
  final TextEditingController ctrl;
  final InputDecoration decoration;
  final TextStyle style;
  final String otherLabel;

  @override
  State<_RelationField> createState() => _RelationFieldState();
}

class _RelationFieldState extends State<_RelationField> {
  static const _options = [
    'Father',
    'Mother',
    'Husband',
    'Wife',
    'Son',
    'Daughter',
    'Brother',
    'Sister',
    'Other'
  ];
  String? _selected;
  final _otherCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initSelected();
  }

  void _initSelected() {
    final t = widget.ctrl.text.trim();
    if (t.isEmpty) {
      _selected = null;
    } else if (_options.contains(t)) {
      _selected = t;
    } else {
      _selected = 'Other';
      _otherCtrl.text = t;
    }
  }

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOther = _selected == 'Other';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selected,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(8),
          menuMaxHeight: 300,
          isExpanded: true,
          decoration: widget.decoration.copyWith(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          style: widget.style,
          icon: const Icon(Icons.arrow_drop_down,
              size: 20, color: Color(0xFF64748B)),
          items: _options
              .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: const TextStyle(fontSize: 12))))
              .toList(),
          onChanged: (v) {
            setState(() {
              _selected = v;
              if (v != 'Other') {
                widget.ctrl.text = v ?? '';
              } else {
                widget.ctrl.text = _otherCtrl.text;
              }
            });
          },
        ),
        if (isOther) ...[
          const SizedBox(height: 10),
          TextFormField(
            controller: _otherCtrl,
            style: widget.style,
            decoration: widget.decoration.copyWith(
              hintText: widget.otherLabel,
              labelText: widget.otherLabel,
            ),
            onChanged: (v) {
              widget.ctrl.text = v;
            },
          ),
        ]
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// _SectionSearchPicker — searchable sections (replaces Select2 from web form)
// ══════════════════════════════════════════════════════════════════════════════
class _SectionSearchPicker extends StatefulWidget {
  const _SectionSearchPicker({
    required this.actKey,
    required this.selected,
    required this.onAdd,
    required this.onRemove,
    this.actsData,
  });
  final String actKey;
  final Set<String> selected;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final Map<String, Map<String, dynamic>>? actsData;

  @override
  State<_SectionSearchPicker> createState() => _SectionSearchPickerState();
}

class _SectionSearchPickerState extends State<_SectionSearchPicker> {
  final _ctrl = TextEditingController();
  String _query = '';
  bool _open = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final acts = widget.actsData ?? ACT_DATA;
    final sections =
        (acts[widget.actKey]?['sections'] as List<dynamic>? ?? [])
            .map((r) => r as Map<String, dynamic>)
            .toList();

    final filtered = _query.isEmpty
        ? sections
        : sections.where((s) {
            final lbl = (s['label'] as String? ?? '').toLowerCase();
            final val = (s['val'] as String? ?? '').toLowerCase();
            final q = _query.toLowerCase();
            return lbl.contains(q) || val.contains(q);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: null,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(8),
          menuMaxHeight: 320,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: TranslationHelper.translate(context, 'Select Section'),
            labelStyle: _tsLabel,
            floatingLabelStyle: _tsLabel.copyWith(color: _kTeal),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            filled: true,
            fillColor: _kInputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kTeal, width: 1.5),
            ),
          ),
          style: _tsBody,
          icon: const Icon(Icons.arrow_drop_down, color: _kTeal),
          hint: Text(
            TranslationHelper.translate(
                context, 'Select Section from dropdown'),
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          items: sections.map((s) {
            final val = s['val'] as String;
            final lbl = s['label'] as String? ?? val;
            final isSelected = widget.selected.contains(val);
            return DropdownMenuItem<String>(
              value: val,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      lbl,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? _kTeal : const Color(0xFF1E293B),
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check, size: 14, color: _kTeal),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) {
              if (widget.selected.contains(v)) {
                widget.onRemove(v);
              } else {
                widget.onAdd(v);
              }
            }
          },
        ),
        if (widget.selected.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: widget.selected.map((v) {
              final sec = sections.firstWhere(
                (s) => s['val'] == v,
                orElse: () => {'val': v, 'label': v, 'cat': ''},
              );
              return InputChip(
                label: Text(
                  sec['val'] as String,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                tooltip: sec['label'] as String? ?? v,
                onDeleted: () => widget.onRemove(v),
                deleteIconColor: _kSec,
                backgroundColor: _kTeal.withValues(alpha: 0.08),
                side: const BorderSide(color: _kTeal, width: 0.8),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                labelPadding: const EdgeInsets.symmetric(horizontal: 2),
              );
            }).toList(),
          ),
        ],
        const SizedBox(height: 6),
        TextFormField(
          controller: _ctrl,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText:
                TranslationHelper.translate(context, 'Or search section…'),
            hintStyle: _tsMuted,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            filled: true,
            fillColor: _kInputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kTeal, width: 1.5),
            ),
            prefixIcon: const Icon(Icons.search, size: 15, color: _kSec),
          ),
          onChanged: (v) => setState(() {
            _query = v;
            _open = v.isNotEmpty;
          }),
          onTap: () => setState(() => _open = true),
        ),
        if (_open && filtered.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 2),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: filtered.length.clamp(0, 50),
              itemBuilder: (_, i) {
                final s = filtered[i];
                final v = s['val'] as String;
                final isSelected = widget.selected.contains(v);
                return InkWell(
                  onTap: isSelected
                      ? () {
                          widget.onRemove(v);
                          setState(() {});
                        }
                      : () {
                          widget.onAdd(v);
                          _ctrl.clear();
                          setState(() {
                            _query = '';
                            _open = false;
                          });
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? _kTeal.withValues(alpha: 0.07) : null,
                      border: const Border(
                        bottom: BorderSide(color: _kBorder, width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          margin: const EdgeInsets.only(right: 8),
                          child: Text(
                            v,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? _kTeal : _kSec,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            s['label'] as String? ?? v,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? _kTeal : _kDark,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check, size: 14, color: _kTeal),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Helper for parents
Map<String, dynamic> commonFormDocumentMapFromState(CommonFormState s) =>
    s.buildDocumentMap();
