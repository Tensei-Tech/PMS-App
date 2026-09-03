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
import 'package:image_picker/image_picker.dart';

import '../../modules/core/models/base_record.dart';
import '../../screens/ad_form_screen.dart' show ACT_DATA;
import '../../utils/app_constants.dart';
import '../../utils/crime_detail_pdf.dart';
import '../../utils/translation_helper.dart';
import '../../utils/validators.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
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
      ..color =
          const Color(0xFFFFD54F) // Bright yellow border
      ..style = PaintingStyle.fill;
    canvas.drawPath(outerPath, outerPaint);

    // Inner warm golden amber triangle
    final innerPath = Path()
      ..moveTo(w * 0.50, h * 0.22)
      ..lineTo(w * 0.84, h * 0.84)
      ..lineTo(w * 0.16, h * 0.84)
      ..close();

    final innerPaint = Paint()
      ..color =
          const Color(0xFFF59E0B) // Warm golden amber
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
  'chkPanchSpot': 'Spot Panchanama ',
  'chkMemo': 'Memorandum Panchanama',
  'chkInquest': 'Inquest',
  'chkIdent': 'Identification',
  'chkSearch': 'Search',
  'chkPersSearch': 'Personal Search',
  'chkIdParade': 'Identification Parade',
  'chkExhumation': 'Exhumation',
};

const _kFinalSummaryItems = [
  'A – True but undetected',
  'B – False',
  'C – Mistake of fact',
  'Abeted Summary',
];
const _kPreventiveItems = ['BNSS 126', 'BNSS 129', 'Bond Cancellation'];
const _kReleaseTypes = ['Anticipatory', 'Regular'];

// ─────────────────────────────────────────────────────────────────────────────
// CommonForm widget
// ─────────────────────────────────────────────────────────────────────────────
class CommonForm extends StatefulWidget {
  const CommonForm({
    super.key,
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

  bool get _isMurderCase {
    if (widget.isMurder == true) return true;
    final sub = (widget.subCategory ?? '').toLowerCase();
    final mod = (widget.moduleKey ?? '').toLowerCase();
    if (sub.contains('murder') || mod.contains('murder')) {
      if (!sub.contains('attempt') && !mod.contains('attempt')) return true;
    }

    for (final charge in _chargeData.values) {
      final act = charge['act']?.toString() ?? '';
      final secs = (charge['sections'] as Set<String>?) ?? {};
      for (final s in secs) {
        if (s == '101' ||
            s == '103' ||
            s == '104' ||
            s == '105' ||
            s == '300' ||
            s == '302' ||
            s == '303' ||
            s == '304') {
          return true;
        }
        final label = _secLabel(act, s).toLowerCase();
        if ((label.contains('murder') && !label.contains('attempt')) ||
            label.contains('culpable homicide') ||
            label.contains('death by negligence') ||
            label.contains('dowry death')) {
          return true;
        }
      }
    }
    return false;
  }

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

  // ── §6 Accused ────────────────────────────────────────────────────────────
  bool _isUnknown = false;
  final List<Map<String, dynamic>> _accused = [];
  final List<Map<String, dynamic>> _suspected = [];

  // ── §7 Unidentified ───────────────────────────────────────────────────────
  String _unidGender = 'Male';
  final _unidAge = TextEditingController();
  final _unidSkin = TextEditingController();
  final _unidHeight = TextEditingController();
  final _unidMobile = TextEditingController();
  final _unidOcc = TextEditingController();
  final _unidAddress = TextEditingController();
  final _unidMarkers = TextEditingController();

  // ── §8 Case Responsibility ────────────────────────────────────────────────
  String _ioDesig = 'PSI';
  String _regDesig = 'HC';
  final _ioName = TextEditingController();
  final _regName = TextEditingController();
  String? _cctvVal;
  final _cctvDt = TextEditingController();

  // ── §9 Arrest / Release ───────────────────────────────────────────────────
  final List<Map<String, dynamic>> _arrestRows = [];

  // ── §10 Procedural ────────────────────────────────────────────────────────
  final Map<String, bool> _procChecks = {
    for (final k in _kProceduralKeys.keys) k: false,
  };
  final Map<String, TextEditingController> _procDates = {
    for (final k in _kProceduralKeys.keys) k: TextEditingController(),
  };
  String? _eshaksh;
  TextEditingController? _eshakshDt;
  TextEditingController? _eshakshReason;

  TextEditingController get _eDt => _eshakshDt ??= TextEditingController();
  TextEditingController get _eReason =>
      _eshakshReason ??= TextEditingController();

  // ── §11 Seizure ───────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _seizures = [];

  // ── §12 Technical ─────────────────────────────────────────────────────────
  final _cdrSent = TextEditingController();
  final _cdrRecv = TextEditingController();
  final _pcrDays = TextEditingController();
  final _mcrDays = TextEditingController();

  // ── §13 Preventive & Bonds ────────────────────────────────────────────────
  String? _prevBondsVal = 'no';
  final _outward = TextEditingController();
  final _bondDate = TextEditingController();
  final _bondCancel = TextEditingController();
  TextEditingController? _bondReason;
  TextEditingController get _bReason => _bondReason ??= TextEditingController();
  String? _prevAction = 'BNSS 129';
  TextEditingController? _prevActionDateCtrl;
  TextEditingController get _prevActionDt =>
      _prevActionDateCtrl ??= TextEditingController();

  // ── §14 Discharge ─────────────────────────────────────────────────────────
  Map<String, bool>? _dischargeMap;
  Map<String, bool> get _discharge => _dischargeMap ??= {};
  Map<String, TextEditingController>? _dischargeDatesMap;
  Map<String, TextEditingController> get _dischargeDates =>
      _dischargeDatesMap ??= {};
  Map<String, TextEditingController>? _dischargeReasonsMap;
  Map<String, TextEditingController> get _dischargeReasons =>
      _dischargeReasonsMap ??= {};

  TextEditingController _getDischargeDateCtrl(String name) =>
      _dischargeDates.putIfAbsent(name, () => TextEditingController());

  TextEditingController _getDischargeReasonCtrl(String name) =>
      _dischargeReasons.putIfAbsent(name, () => TextEditingController());

  // ── §15 Court Filing ──────────────────────────────────────────────────────
  final _csNumber = TextEditingController();
  TextEditingController? _csDateCtrl;
  TextEditingController get _csDate => _csDateCtrl ??= TextEditingController();
  final _ccStNumber = TextEditingController();
  String? _finalSummary;
  final _quashDate = TextEditingController();

  // ── §16 Verdict ───────────────────────────────────────────────────────────
  final List<String> _acquitted = [];
  final List<String> _convicted = [];

  // ── §17 Scrutiny ──────────────────────────────────────────────────────────
  final _sdpoSend = TextEditingController();
  final _sdpoGrant = TextEditingController();
  final _appSend = TextEditingController();
  final _appGrant = TextEditingController();
  final _dcpSend = TextEditingController();
  final _dcpGrant = TextEditingController();
  bool _stepApp = false;
  bool _stepDcp = false;

  // ── Derived ───────────────────────────────────────────────────────────────
  List<String> allAccusedNames = [];

  // ─── lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _ownsScroll = widget.scrollController == null;
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
      _pcrDays,
      _mcrDays,
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
  }

  void _disposePeople(List<Map<String, dynamic>> list) {
    for (final p in list) {
      _disposeMap(p);
    }
    list.clear();
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
        _rebuildDischarge();
        _pruneVerdict();
        for (final s in _seizures) {
          final fw = s['fromWhom'] as String?;
          if (fw != null && !allAccusedNames.contains(fw)) {
            s['fromWhom'] = allAccusedNames.isEmpty
                ? null
                : allAccusedNames.first;
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
        'releaseType': 'Regular',
        'releaseDt': TextEditingController(),
      });
    }
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
  }

  void _onActChange(String id, String act) {
    _chargeData[id]!['act'] = act;
    _chargeData[id]!['sections'] = <String>{};
    setState(() {});
  }

  void _addSection(String id, String val) {
    (_chargeData[id]!['sections'] as Set<String>).add(val);
    setState(() {});
  }

  void _removeSection(String id, String val) {
    (_chargeData[id]!['sections'] as Set<String>).remove(val);
    setState(() {});
  }

  // ─── accused / suspected helpers ───────────────────────────────────────────
  void addPersonAccused() {
    setState(() => _accused.add(_newPerson()));
    _syncNames();
  }

  void addPersonSuspected() {
    setState(() => _suspected.add(_newPerson()));
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

  void toggleUnknownUntraced(bool v) {
    if (v) {
      _disposePeople(_accused);
      _disposePeople(_suspected);
    }
    setState(() => _isUnknown = v);
    _syncNames();
  }

  void _copyPersonData(Map<String, dynamic> src, Map<String, dynamic> dst) {
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

        final srcAge = (src['age'] as TextEditingController?)?.text ?? '';
        final srcOcc = (src['occ'] as TextEditingController?)?.text ?? '';
        final srcMob = (src['mobile'] as TextEditingController?)?.text ?? '';
        final srcAadh = (src['aadhaar'] as TextEditingController?)?.text ?? '';
        final srcRel = (src['religion'] as TextEditingController?)?.text ?? '';
        final srcCaste = (src['caste'] as TextEditingController?)?.text ?? '';
        final srcPan = (src['pan'] as TextEditingController?)?.text ?? '';

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

  // ─── procedural helpers ────────────────────────────────────────────────────
  void toggleProcedural(String key, bool v) {
    setState(() {
      _procChecks[key] = v;
      if (!v) _procDates[key]!.clear();
    });
  }

  // ─── scrutiny ──────────────────────────────────────────────────────────────
  void _checkScrutiny() {
    setState(() {
      _stepApp = _sdpoSendHasText;
      _stepDcp = _appSendHasText;
    });
  }

  bool get _sdpoSendHasText => _sdpoSend.text.trim().isNotEmpty;
  bool get _appSendHasText => _appSend.text.trim().isNotEmpty;

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
      _pcrDays,
      _mcrDays,
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
    ]) {
      c.clear();
    }
    for (final c in _procDates.values) {
      c.clear();
    }
    for (final k in _procChecks.keys) {
      _procChecks[k] = false;
    }

    _firPath = null;
    _isUnknown = false;
    _compGender = 'Male';
    _vGender = 'Male';
    _dGender = 'Male';
    _unidGender = 'Male';
    _ioDesig = 'PSI';
    _regDesig = 'HC';
    _cctvVal = null;
    _eshaksh = null;
    _prevAction = 'BNSS 129';
    _prevBondsVal = 'no';
    _finalSummary = null;
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
      },
      'isUnknownUntraced': _isUnknown,
      'accused': pplRows(_accused),
      'suspectedAccused': pplRows(_suspected),
      'unidentified': {
        'gender': _unidGender,
        'approxAge': _unidAge.text,
        'skinColor': _unidSkin.text,
        'approxHeight': _unidHeight.text,
        'mobile': _unidMobile.text,
        'occupation': _unidOcc.text,
        'lastKnownAddress': _unidAddress.text,
        'otherPhysicalMarkers': _unidMarkers.text,
      },
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
              'arrestDt': (r['arrestDt'] as TextEditingController).text,
              'releaseType': r['releaseType'],
              'releaseDt': (r['releaseDt'] as TextEditingController).text,
            },
          )
          .toList(),
      'proceduralChecks': Map<String, bool>.from(_procChecks),
      'proceduralDates': _procDates.map((k, v) => MapEntry(k, v.text)),
      'eshakshValue': _eshaksh,
      'eshakshDt': _eDt.text,
      'eshakshReason': _eReason.text,
      'seizures': _seizures
          .map(
            (s) => {
              'desc': (s['desc'] as TextEditingController).text,
              'fromWhom': s['fromWhom'],
              'otherName': (s['otherName'] as TextEditingController).text,
            },
          )
          .toList(),
      'cdrSent': _cdrSent.text,
      'cdrRecv': _cdrRecv.text,
      'pcrDays': _pcrDays.text,
      'mcrDays': _mcrDays.text,
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
      'court': {
        'chargeSheetNumber': _csNumber.text,
        'chargeSheetDate': _csDate.text,
        'ccStNumber': _ccStNumber.text,
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
        'appSend': _appSend.text,
        'appGrant': _appGrant.text,
        'dcpSend': _dcpSend.text,
        'dcpGrant': _dcpGrant.text,
        'stepAppActive': _stepApp,
        'stepDcpActive': _stepDcp,
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
    }

    _isUnknown = m['isUnknownUntraced'] == true;

    void applyPerson(Map<String, dynamic> row, Map raw) {
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
    }

    if (!_isUnknown) {
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
    } else {
      final u = m['unidentified'] as Map?;
      if (u != null) {
        final g = u['gender']?.toString();
        if (g != null && _kGenders.contains(g)) _unidGender = g;
        _unidAge.text = _s(u['approxAge']);
        _unidSkin.text = _s(u['skinColor']);
        _unidHeight.text = _s(u['approxHeight']);
        _unidMobile.text = _s(u['mobile']);
        _unidOcc.text = _s(u['occupation']);
        _unidAddress.text = _s(u['lastKnownAddress']);
        _unidMarkers.text = _s(u['otherPhysicalMarkers']);
      }
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
      (row['arrestDt'] as TextEditingController).text = _s(r0['arrestDt']);
      final rt = r0['releaseType']?.toString();
      if (rt != null) row['releaseType'] = rt;
      (row['releaseDt'] as TextEditingController).text = _s(r0['releaseDt']);
    }

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

    for (final s0 in (m['seizures'] as List? ?? [])) {
      if (s0 is! Map) continue;
      _seizures.add({
        'desc': TextEditingController(text: _s(s0['desc'])),
        'fromWhom': s0['fromWhom'] as String?,
        'otherName': TextEditingController(text: _s(s0['otherName'])),
      });
    }

    _cdrSent.text = _s(m['cdrSent']);
    _cdrRecv.text = _s(m['cdrRecv']);
    _pcrDays.text = _s(m['pcrDays']);
    _mcrDays.text = _s(m['mcrDays']);

    final pr = m['preventive'] as Map?;
    if (pr != null) {
      _prevBondsVal =
          (pr['preventiveBonds'] ?? pr['prBond']) as String? ?? 'no';
      _prevAction = pr['action'] as String? ?? 'BNSS 129';
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

    final ct = m['court'] as Map?;
    if (ct != null) {
      _csNumber.text = _s(ct['chargeSheetNumber']);
      _csDate.text = _s(ct['chargeSheetDate']);
      _ccStNumber.text = _s(ct['ccStNumber']);
      _finalSummary = ct['finalSummary'] as String?;
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
      _appSend.text = _s(sc['appSend']);
      _appGrant.text = _s(sc['appGrant']);
      _dcpSend.text = _s(sc['dcpSend']);
      _dcpGrant.text = _s(sc['dcpGrant']);
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
    int idx,
    String title,
    Widget body, {
    bool startOpen = false,
    Widget? headerAction,
  }) {
    final trailing = widget.trailingSlotsBySection?[idx];
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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                leadingBadge,
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    TranslationHelper.translate(context, title),
                    style: _tsSection,
                  ),
                ),
                if (headerAction != null) headerAction,
              ],
            ),
          ),
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
    final initial =
        parsed != null &&
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
  }) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      style: _tsBody,
      decoration: _d(label).copyWith(
        suffixIcon: IconButton(
          icon: const Icon(
            Icons.calendar_today_rounded,
            size: 16,
            color: _kTeal,
          ),
          tooltip: 'Pick date',
          onPressed: () => _pickDateOnly(ctrl, onChanged: onChanged),
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
      onTap: () => _pickDateOnly(ctrl, onChanged: onChanged),
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
    final initialTod =
        p0 != null &&
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
        floatingLabelBehavior: FloatingLabelBehavior.always,
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
  }) => InkWell(
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
                    'Generate Crime Detail Form PDF',
                    Icons.picture_as_pdf_outlined,
                    _generateCrimeDetailPdf,
                    const Color(0xFF0284C7),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _kBorder),
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
                          _card(
                            1,
                            'Crime Registration Info',
                            _s1(),
                            startOpen: true,
                          ),
                          _card(
                            2,
                            'Acts & Sections Filed',
                            _s2(),
                            startOpen: true,
                            headerAction: _headerBtn(
                              'Add Charge',
                              addChargeRow,
                            ),
                          ),
                          _card(3, 'Crime Spot', _s3()),
                          if (widget.middleSlot != null) widget.middleSlot!,
                          _card(4, 'Complainant KYC', _s4()),
                          _card(
                            5,
                            'Victim KYC',
                            _sVictim(),
                            headerAction: _headerBtn(
                              'Same as Complainant',
                              _copyComplainantToVictim,
                              icon: Icons.copy_rounded,
                            ),
                          ),
                          if (_isMurderCase)
                            _card(
                              6,
                              'Deceased KYC',
                              _sDeceased(),
                              headerAction: _headerBtn(
                                'Same as Victim',
                                _copyVictimToDeceased,
                                icon: Icons.copy_rounded,
                              ),
                            ),
                          _card(
                            _isMurderCase ? 7 : 6,
                            'Accused Details',
                            _s5(),
                            headerAction: !_isUnknown
                                ? Row(
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
                                  )
                                : null,
                          ),
                          _card(
                            _isMurderCase ? 8 : 7,
                            'Suspected Accused',
                            _s6(),
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
                          if (_isUnknown)
                            _card(
                              _isMurderCase ? 9 : 8,
                              'Unidentified Criminal Description',
                              _s7(),
                            ),
                          _card(
                            _isMurderCase ? 10 : 9,
                            'Case Responsibility',
                            _s8(),
                          ),
                          _card(
                            _isMurderCase ? 11 : 10,
                            'Arrest & Release Status',
                            _s9(),
                          ),
                          _card(
                            _isMurderCase ? 12 : 11,
                            'Procedural Details',
                            _s10(),
                          ),
                          _card(
                            _isMurderCase ? 13 : 12,
                            'Seizure Records',
                            _s11(),
                            headerAction: _headerBtn(
                              'Add Seized Property',
                              addSeizure,
                            ),
                          ),
                          _card(
                            _isMurderCase ? 14 : 13,
                            'Technical & Custody',
                            _s12(),
                          ),
                          _card(
                            _isMurderCase ? 15 : 14,
                            'Preventive & Bonds',
                            _s13(),
                          ),
                          _card(
                            _isMurderCase ? 16 : 15,
                            'Discharge Status',
                            _s14(),
                          ),
                          _card(
                            _isMurderCase ? 17 : 16,
                            'Court Filing',
                            _s15(),
                          ),
                          _card(
                            _isMurderCase ? 18 : 17,
                            'Final Verdict',
                            _s16(),
                          ),
                          _card(
                            _isMurderCase ? 19 : 18,
                            'Case Scrutiny Pipeline',
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

  Future<void> _generateCrimeDetailPdf() async {
    try {
      final doc = buildDocumentMap();
      await previewCrimeDetailPdf(context, doc);
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
      GestureDetector(
        onTap: pickFirCopy,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _kInputBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.upload_file_outlined, size: 16, color: _kTeal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _firPath == null
                      ? TranslationHelper.translate(
                          context,
                          'Upload FIR Copy (tap to select)',
                        )
                      : '${TranslationHelper.translate(context, 'FIR')}: $_firPath',
                  style: _tsBody.copyWith(
                    color: _firPath == null ? _kSec : _kDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  // ── §2 Acts & Sections Filed ───────────────────────────────────────────────
  Widget _s2() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_chargeData.isEmpty)
        _emptyBox('No charges. Tap + Add Charge to begin.')
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
              ? (ACT_DATA[act]?['label'] as String? ?? act)
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
                          fontWeight: FontWeight.w700,
                          color: _kDark,
                        ),
                      ),
                      if (secs.isEmpty)
                        const Text('No sections selected', style: _tsMuted)
                      else
                        Wrap(
                          spacing: 4,
                          children: secs
                              .map(
                                (v) => Text(
                                  _secLabel(act, v),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: _kTeal,
                                  ),
                                ),
                              )
                              .toList(),
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

  String _secLabel(String actKey, String val) {
    final secs = ACT_DATA[actKey]?['sections'] as List<dynamic>? ?? [];
    for (final raw in secs) {
      final m = raw as Map<String, dynamic>;
      if (m['val'] == val) return m['label'] as String? ?? val;
    }
    return val;
  }

  Widget _chargeCard(String id, int num, Map<String, dynamic> data) {
    final actKey = data['act']?.toString() ?? '';
    final hasAct = actKey.isNotEmpty && ACT_DATA.containsKey(actKey);
    final secs = (data['sections'] as Set<String>?) ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kInputBg.withValues(alpha: 0.5),
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Charge #$num',
                  style: _tsSection.copyWith(fontSize: 11),
                ),
              ),
              GestureDetector(
                onTap: () => _removeCharge(id),
                child: const Icon(Icons.close, size: 16, color: _kRed),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Act selector — horizontal scrollable chips
          _chipSelector(
            label: 'Act / Law',
            items: ACT_DATA.keys
                .map((k) => ACT_DATA[k]!['label'] as String)
                .toList(),
            selected: hasAct ? (ACT_DATA[actKey]!['label'] as String) : null,
            onSelect: (label) {
              final key = ACT_DATA.entries
                  .firstWhere((e) => e.value['label'] == label)
                  .key;
              _onActChange(id, key);
            },
          ),
          // Act hint
          if (hasAct) ...[
            const SizedBox(height: 6),
            Text(
              ACT_DATA[actKey]?['hint'] as String? ?? '',
              style: const TextStyle(
                fontSize: 10,
                color: _kAmber,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 10),
            // Section search list
            const Text('Section(s) — tap to add', style: _tsLabel),
            const SizedBox(height: 6),
            _SectionSearchPicker(
              actKey: actKey,
              selected: secs,
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
    children: [
      _row([_tf('Village/Town', _spotVillage), _tf('Area Name', _spotArea)]),
      _tf('Full Address', _spotAddress, maxLines: 3),
    ],
  );

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

  // ── §4 Complainant KYC ────────────────────────────────────────────────────
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
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _chipSelector(
          label: 'Gender',
          items: _kGenders,
          selected: _compGender,
          onSelect: (v) => setState(() => _compGender = v),
        ),
      ),
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
    ],
  );

  void _copyComplainantToVictim() {
    setState(() {
      if (!_isRapeCase) {
        _vName.value = TextEditingValue(
          text: _compName.text,
          selection: TextSelection.collapsed(offset: _compName.text.length),
        );
      }
      _vAge.value = TextEditingValue(
        text: _compAge.text,
        selection: TextSelection.collapsed(offset: _compAge.text.length),
      );
      _vGender = _compGender.isNotEmpty ? _compGender : 'Female';
      _vOcc.value = TextEditingValue(
        text: _compOcc.text,
        selection: TextSelection.collapsed(offset: _compOcc.text.length),
      );
      _vMobile.value = TextEditingValue(
        text: _compMobile.text,
        selection: TextSelection.collapsed(offset: _compMobile.text.length),
      );
      _vAadhaar.value = TextEditingValue(
        text: _compAadhaar.text,
        selection: TextSelection.collapsed(offset: _compAadhaar.text.length),
      );
      _vReligion.value = TextEditingValue(
        text: _compReligion.text,
        selection: TextSelection.collapsed(offset: _compReligion.text.length),
      );
      _vCaste.value = TextEditingValue(
        text: _compCaste.text,
        selection: TextSelection.collapsed(offset: _compCaste.text.length),
      );
      _vPan.value = TextEditingValue(
        text: _compPan.text,
        selection: TextSelection.collapsed(offset: _compPan.text.length),
      );
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          TranslationHelper.translate(
            context,
            'Copied Complainant details to Victim KYC',
          ),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: _kTeal,
      ),
    );
  }

  // ── §5 Victim KYC ──────────────────────────────────────────────────────────
  Widget _sVictim() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_isRapeCase) _victimIdentityProtectionWarning(context),
      _row([
        _tf(
          'Name',
          _vName,
          enabled: !_isRapeCase,
          hintText: _isRapeCase ? 'Identity Protected by Law' : null,
        ),
        _tf('Age', _vAge, keyboardType: TextInputType.number),
      ]),
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _chipSelector(
          label: 'Gender',
          items: _kGenders,
          selected: _vGender,
          onSelect: (v) => setState(() => _vGender = v),
        ),
      ),
      _row([
        _tf('Occupation', _vOcc),
        _tf(
          'Mobile Number',
          _vMobile,
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
          _vAadhaar,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
          validator: AppValidators.aadhaar,
        ),
        _tf(
          'PAN Number',
          _vPan,
          inputFormatters: [
            UpperCaseTextFormatter(),
            LengthLimitingTextInputFormatter(10),
          ],
          validator: AppValidators.pan,
        ),
      ]),
      _row([_tf('Religion', _vReligion), _tf('Caste', _vCaste)]),
    ],
  );

  void _copyVictimToDeceased() {
    setState(() {
      _dName.value = TextEditingValue(
        text: _vName.text,
        selection: TextSelection.collapsed(offset: _vName.text.length),
      );
      _dAge.value = TextEditingValue(
        text: _vAge.text,
        selection: TextSelection.collapsed(offset: _vAge.text.length),
      );
      _dGender = _vGender.isNotEmpty ? _vGender : 'Male';
      _dOcc.value = TextEditingValue(
        text: _vOcc.text,
        selection: TextSelection.collapsed(offset: _vOcc.text.length),
      );
      _dMobile.value = TextEditingValue(
        text: _vMobile.text,
        selection: TextSelection.collapsed(offset: _vMobile.text.length),
      );
      _dAadhaar.value = TextEditingValue(
        text: _vAadhaar.text,
        selection: TextSelection.collapsed(offset: _vAadhaar.text.length),
      );
      _dReligion.value = TextEditingValue(
        text: _vReligion.text,
        selection: TextSelection.collapsed(offset: _vReligion.text.length),
      );
      _dCaste.value = TextEditingValue(
        text: _vCaste.text,
        selection: TextSelection.collapsed(offset: _vCaste.text.length),
      );
      _dPan.value = TextEditingValue(
        text: _vPan.text,
        selection: TextSelection.collapsed(offset: _vPan.text.length),
      );
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          TranslationHelper.translate(
            context,
            'Copied Victim details to Deceased KYC',
          ),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: _kTeal,
      ),
    );
  }

  // ── Deceased KYC (Murder Cases) ───────────────────────────────────────────
  Widget _sDeceased() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _row([
        _tf('Name', _dName),
        _tf('Age', _dAge, keyboardType: TextInputType.number),
      ]),
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _chipSelector(
          label: 'Gender',
          items: _kGenders,
          selected: _dGender,
          onSelect: (v) => setState(() => _dGender = v),
        ),
      ),
      _row([
        _tf('Occupation', _dOcc),
        _tf(
          'Mobile Number',
          _dMobile,
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
          _dAadhaar,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
          validator: AppValidators.aadhaar,
        ),
        _tf(
          'PAN Number',
          _dPan,
          inputFormatters: [
            UpperCaseTextFormatter(),
            LengthLimitingTextInputFormatter(10),
          ],
          validator: AppValidators.pan,
        ),
      ]),
      _row([_tf('Religion', _dReligion), _tf('Caste', _dCaste)]),
    ],
  );

  // ── §6 Accused Details ────────────────────────────────────────────────────
  Widget _s5() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Unknown/Untraced toggle
      _UnknownToggle(value: _isUnknown, onChanged: toggleUnknownUntraced),
      if (!_isUnknown) ...[
        if (_accused.isEmpty)
          _emptyBox('No accused added.')
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
    ],
  );

  // ── §6 Suspected Accused ──────────────────────────────────────────────────
  Widget _s6() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_isUnknown)
        _emptyBox('Suspected accused hidden while Unknown/Untraced is ON.')
      else ...[
        if (_suspected.isEmpty)
          _emptyBox('No suspected accused added.')
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
    final availableOthers = (otherList ?? [])
        .where(
          (src) =>
              (src['name'] as TextEditingController?)?.text.trim().isNotEmpty ==
                  true ||
              (src['age'] as TextEditingController?)?.text.trim().isNotEmpty ==
                  true ||
              (src['mobile'] as TextEditingController?)?.text
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
                      final n =
                          (entry.value['name'] as TextEditingController?)?.text
                              .trim() ??
                          '';
                      final displayName = n.isNotEmpty
                          ? n
                          : '$otherLabel #${entry.key + 1}';
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
          _row([
            _tf(
              'Name',
              row['name'] as TextEditingController,
              onChanged: (val) {
                _debouncedSync();
                if (otherList != null && otherList.isNotEmpty) {
                  _checkAndAutoFillPerson(row, otherList);
                }
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
              'Mobile',
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
              'Aadhaar',
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
        ],
      ),
    );
  }

  // ── §7 Unidentified Criminal Description ──────────────────────────────────
  Widget _s7() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _chipSelector(
          label: 'Gender',
          items: _kGenders,
          selected: _unidGender,
          onSelect: (v) => setState(() => _unidGender = v),
        ),
      ),
      _row([
        _tf('Approx Age', _unidAge, keyboardType: TextInputType.number),
        _tf('Approx Height', _unidHeight),
      ]),
      _row([
        _tf('Skin Color', _unidSkin),
        _tf(
          'Mobile (if known)',
          _unidMobile,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          validator: (v) => AppValidators.indianMobile(v, required: false),
        ),
      ]),
      _row([
        _tf('Occupation (possible)', _unidOcc),
        _tf('Last Known Address', _unidAddress),
      ]),
      _tf('Other Physical Markers', _unidMarkers, maxLines: 3),
    ],
  );

  // ── §8 Case Responsibility ─────────────────────────────────────────────────
  Widget _s8() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _subHeader('INVESTIGATING OFFICER'),
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _chipSelector(
          label: 'IO Designation',
          items: PoliceDesignations.ioDesignations,
          selected: _ioDesig,
          onSelect: (v) => setState(() => _ioDesig = v),
        ),
      ),
      _row([_tf('IO Name', _ioName)]),
      _divider(),
      _subHeader('REGISTRAR'),
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _chipSelector(
          label: 'Registered By Designation',
          items: PoliceDesignations.formIoAndReg,
          selected: _regDesig,
          onSelect: (v) => setState(() => _regDesig = v),
        ),
      ),
      _row([_tf('Registrar Name', _regName)]),
      _divider(),
      _yesNo('CCTV', _cctvVal, (v) => setState(() => _cctvVal = v)),
      if (_cctvVal == 'yes') ...[
        const SizedBox(height: 10),
        _dateTimeField('CCTV Date & Time (dd/mm/yyyy hh:mm)', _cctvDt),
      ],
    ],
  );

  // ── §9 Arrest & Release Status ────────────────────────────────────────────
  Widget _s9() {
    if (allAccusedNames.isEmpty) {
      return _emptyBox(
        'Add accused/suspected names above to see arrest fields.',
      );
    }
    return Column(
      children: _arrestRows.map((r) {
        final name = r['accusedName'] as String;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: _tsSection.copyWith(fontSize: 11)),
              const SizedBox(height: 10),
              _row([
                _dateTimeField(
                  'Arrest Date & Time (dd/mm/yyyy hh:mm)',
                  r['arrestDt'] as TextEditingController,
                ),
                _dateField(
                  'Release Date',
                  r['releaseDt'] as TextEditingController,
                ),
              ]),
              _chipSelector(
                label: 'Release Type',
                items: _kReleaseTypes,
                selected: r['releaseType'] as String?,
                onSelect: (v) => setState(() => r['releaseType'] = v),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── §10 Procedural Details ────────────────────────────────────────────────
  Widget _s10() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _subHeader('SELECT TO ADD DATE/TIME'),
      ..._kProceduralKeys.entries.map((e) {
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
                          on ? Icons.check_box : Icons.check_box_outline_blank,
                          size: 18,
                          color: on ? _kTeal : _kSec,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.value,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: on
                                  ? FontWeight.w700
                                  : FontWeight.w500,
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
      _divider(),
      _yesNo('E-Shakshya', _eshaksh, (v) => setState(() => _eshaksh = v)),
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
                          : '${TranslationHelper.translate(ctx, 'Minimum 30 words required')} (${30 - words} ${TranslationHelper.translate(ctx, 'more needed')})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isComplete ? _kGreen : _kRed,
                      ),
                    ),
                    Text(
                      '$words / 30 ${TranslationHelper.translate(ctx, 'words')}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isComplete ? _kGreen : _kRed,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    ],
  );

  int _countWords(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  // ── §11 Seizure Records ────────────────────────────────────────────────────
  Widget _s11() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_seizures.isEmpty)
        _emptyBox('No seizure records added.')
      else
        ..._seizures.asMap().entries.map((e) {
          final s = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: _kBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Seizure #${e.key + 1}',
                        style: _tsSection.copyWith(fontSize: 11),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => removeSeizure(e.key),
                      child: const Icon(Icons.close, size: 16, color: _kRed),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _row([
                  _tf(
                    'Property Description',
                    s['desc'] as TextEditingController,
                    maxLines: 2,
                  ),
                ]),
                if (allAccusedNames.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Add accused names to populate "Seized From"',
                      style: _tsMuted,
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _chipSelector(
                      label: 'Seized From (Accused)',
                      items: allAccusedNames,
                      selected: s['fromWhom'] as String?,
                      onSelect: (v) => setState(() => s['fromWhom'] = v),
                    ),
                  ),
                _tf(
                  'Other Name (if not in list)',
                  s['otherName'] as TextEditingController,
                ),
              ],
            ),
          );
        }),
    ],
  );

  // ── §12 Technical & Custody ────────────────────────────────────────────────
  Widget _s12() => Column(
    children: [
      _row([
        _dateField('CDR Sent Date', _cdrSent),
        _dateField('CDR Received Date', _cdrRecv),
      ]),
      _row([
        _tf('PCR (Days)', _pcrDays, keyboardType: TextInputType.number),
        _tf('MCR (Days)', _mcrDays, keyboardType: TextInputType.number),
      ]),
    ],
  );

  // ── §13 Preventive & Bonds ─────────────────────────────────────────────────
  Widget _s13() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _subHeader('PREVENTIVE BONDS'),
      _yesNo(
        'Preventive Bonds',
        _prevBondsVal ?? 'no',
        (v) => setState(() => _prevBondsVal = v),
      ),
      if (_prevBondsVal == 'yes') ...[
        const SizedBox(height: 10),
        _row([
          _dateField('PR Bond Date', _bondDate),
          _dateField('Bond Cancellation Date', _bondCancel),
        ]),
        _row([_tf('Reason for PR Bond', _bReason)]),
      ],
      const SizedBox(height: 14),
      _subHeader('PREVENTIVE ACTIONS'),
      _chipSelector(
        label: 'Action Type',
        items: _kPreventiveItems,
        selected: _prevAction ?? 'BNSS 129',
        onSelect: (v) => setState(() => _prevAction = v),
        activeColor: const Color(0xFF0284C7),
      ),
      const SizedBox(height: 10),
      _row([
        _dateTimeField(
          '${_prevAction ?? 'BNSS 129'} Date & Time',
          _prevActionDt,
          hintText: 'dd/mm/yyyy hh:mm',
        ),
      ]),
    ],
  );

  // ── §14 Discharge Status ───────────────────────────────────────────────────
  Widget _s14() {
    if (allAccusedNames.isEmpty) {
      return _emptyBox('Add accused/suspected names to manage discharge.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: allAccusedNames.map((n) {
        final v = _discharge[n] ?? false;
        final dateCtrl = _getDischargeDateCtrl(n);
        final reasonCtrl = _getDischargeReasonCtrl(n);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: v ? _kTeal.withValues(alpha: 0.04) : _kInputBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: v ? _kTeal.withValues(alpha: 0.4) : _kBorder,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => setState(() => _discharge[n] = !v),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        v ? Icons.check_box : Icons.check_box_outline_blank,
                        size: 20,
                        color: v ? _kTeal : _kSec,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$n ${TranslationHelper.translate(context, '(Discharged)')}',
                          style: _tsBody.copyWith(
                            fontWeight: v ? FontWeight.w700 : FontWeight.w500,
                            color: v ? _kTeal : _kDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (v) ...[
                const SizedBox(height: 10),
                _row([_dateField('Discharge Date', dateCtrl)]),
                _tf(
                  'Reason for Discharge (minimum 20 words)',
                  reasonCtrl,
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 4),
                Builder(
                  builder: (ctx) {
                    final words = _countWords(reasonCtrl.text);
                    final isComplete = words >= 20;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isComplete
                              ? TranslationHelper.translate(
                                  ctx,
                                  'Word requirement met',
                                )
                              : '${TranslationHelper.translate(ctx, 'Minimum 20 words required')} (${20 - words} ${TranslationHelper.translate(ctx, 'more needed')})',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isComplete ? _kGreen : _kRed,
                          ),
                        ),
                        Text(
                          '$words / 20 ${TranslationHelper.translate(ctx, 'words')}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isComplete ? _kGreen : _kRed,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── §15 Court Filing ───────────────────────────────────────────────────────
  Widget _s15() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _row([
        _tf('Charge Sheet Number', _csNumber),
        _dateField('Charge Sheet Date', _csDate),
      ]),
    ],
  );

  // ── §16 Final Verdict ──────────────────────────────────────────────────────
  Widget _s16() {
    final unAssigned = allAccusedNames
        .where((n) => !_acquitted.contains(n) && !_convicted.contains(n))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row([
          _tf('CC Number / ST Number', _ccStNumber),
          _dateField('Quashed by High Court Date', _quashDate),
        ]),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _chipSelector(
            label: 'Final Summary',
            items: _kFinalSummaryItems,
            selected: _finalSummary,
            onSelect: (v) => setState(() => _finalSummary = v),
          ),
        ),
        if (allAccusedNames.isEmpty)
          _emptyBox('Add accused/suspected names above to classify verdict.')
        else ...[
          if (unAssigned.isNotEmpty) ...[
            _subHeader('UNASSIGNED — TAP TO CLASSIFY'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: unAssigned
                  .map(
                    (n) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _verdictChip(
                          n,
                          'Acquitted',
                          _kGreen,
                          () => addToVerdictAcquitted(n),
                        ),
                        const SizedBox(width: 4),
                        _verdictChip(
                          n,
                          'Convicted',
                          _kRed,
                          () => addToVerdictConvicted(n),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
            _divider(),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _verdictCol(
                  '✓ Acquitted',
                  _acquitted,
                  _kGreen,
                  removeFromVerdictAcquitted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _verdictCol(
                  '✗ Convicted',
                  _convicted,
                  _kRed,
                  removeFromVerdictConvicted,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _verdictChip(
    String name,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          '$name → $label',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _verdictCol(
    String title,
    List<String> names,
    Color color,
    void Function(String) onRemove,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          if (names.isEmpty)
            const Text('None', style: _tsMuted)
          else
            ...names.map(
              (n) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        n,
                        style: const TextStyle(fontSize: 11, color: _kDark),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => onRemove(n),
                      child: Icon(Icons.close, size: 14, color: color),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── §17 Case Scrutiny Pipeline ─────────────────────────────────────────────
  Widget _s17() => Column(
    children: [
      _scrutinyStep(
        step: 1,
        title: 'SDPO / ACP Approval',
        active: true,
        sendCtrl: _sdpoSend,
        grantCtrl: _sdpoGrant,
        onSendChanged: (_) => _checkScrutiny(),
      ),
      _scrutinyStep(
        step: 2,
        title: 'APP Scrutiny',
        active: _stepApp,
        sendCtrl: _appSend,
        grantCtrl: _appGrant,
        onSendChanged: (_) => _checkScrutiny(),
        lockedMsg: 'Unlocks when SDPO Send Date is filled',
      ),
      _scrutinyStep(
        step: 3,
        title: 'Addl SP / DCP / Addl CP',
        active: _stepDcp,
        sendCtrl: _dcpSend,
        grantCtrl: _dcpGrant,
        lockedMsg: 'Unlocks when APP Send Date is filled',
        isLast: true,
      ),
    ],
  );

  Widget _scrutinyStep({
    required int step,
    required String title,
    required bool active,
    required TextEditingController sendCtrl,
    required TextEditingController grantCtrl,
    void Function(String)? onSendChanged,
    String? lockedMsg,
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
                  Text(title, style: _tsSection.copyWith(fontSize: 11)),
                  const SizedBox(height: 6),
                  if (!active && lockedMsg != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _kInputBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _kBorder,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Text(lockedMsg, style: _tsMuted),
                    )
                  else ...[
                    _row([
                      _dateField(
                        'Send Date',
                        sendCtrl,
                        onChanged: onSendChanged,
                      ),
                      _dateField('Grant Date', grantCtrl),
                    ]),
                  ],
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
// _UnknownToggle — toggle chip for Unknown/Untraced
// ══════════════════════════════════════════════════════════════════════════════
class _UnknownToggle extends StatelessWidget {
  const _UnknownToggle({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value ? _kAmber.withValues(alpha: 0.1) : _kInputBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? _kAmber : _kBorder,
            width: value ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_box : Icons.check_box_outline_blank,
              size: 16,
              color: value ? _kAmber : _kSec,
            ),
            const SizedBox(width: 8),
            Text(
              'Unknown / Untraced',
              style: TextStyle(
                fontSize: 12,
                fontWeight: value ? FontWeight.w700 : FontWeight.w400,
                color: value ? _kAmber : _kSec,
              ),
            ),
          ],
        ),
      ),
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
  });
  final String actKey;
  final Set<String> selected;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

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
    final sections =
        (ACT_DATA[widget.actKey]?['sections'] as List<dynamic>? ?? [])
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
        // Selected chips
        if (widget.selected.isNotEmpty)
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
                  '§${sec['val']}',
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
        const SizedBox(height: 6),
        // Search field
        TextFormField(
          controller: _ctrl,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Search sections…',
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
        // Results list
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
                      ? null
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
                            '§$v',
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
