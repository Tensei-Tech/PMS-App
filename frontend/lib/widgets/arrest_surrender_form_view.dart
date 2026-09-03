import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'form_paper_page.dart';
import 'form_view_scaffold.dart';
import 'form_section_utils.dart';

/// Arrest/Court Surrender Form (Forms 3-A, 3-B, 3-C)
class ArrestSurrenderFormView extends StatefulWidget {
  final bool readOnly;
  final dynamic existingRecord;
  final String? formSection;
  final String? pageRange;

  const ArrestSurrenderFormView({
    super.key,
    this.readOnly = false,
    this.existingRecord,
    this.formSection,
    this.pageRange,
  });

  @override
  State<ArrestSurrenderFormView> createState() => ArrestSurrenderFormViewState();
}

class ArrestSurrenderFormViewState extends State<ArrestSurrenderFormView> {
  static const kForm3A = 'Form 3-A';
  static const kForm3B = 'Form 3-B';
  static const kForm3C = 'Form 3-C';
  static const _knownSectionIds = {kForm3A, kForm3B, kForm3C};

  bool _shows(String sectionId) => showsFormSection(
        activeSection: widget.formSection,
        sectionId: sectionId,
        knownSectionIds: _knownSectionIds,
      );

  // ── Page 1 (Form: 3-A) Controllers ──
  final _distCtrl = TextEditingController();
  final _psCtrl = TextEditingController();
  final _firNoCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _accusedCodeCtrl = TextEditingController();

  final _arrestDateCtrl = TextEditingController();
  final _arrestTimeCtrl = TextEditingController();
  final _arrestGdNoCtrl = TextEditingController();
  final _arrestPlaceCtrl = TextEditingController();
  final _arrestDistCtrl = TextEditingController();
  final _arrestStateCtrl = TextEditingController();

  final _courtNameCtrl = TextEditingController();
  final _actsSectionsCtrl = TextEditingController();

  // 5. Checkboxes
  bool _arrestedAndForwarded = false;
  bool _arrestedAndBailed = false;
  bool _arrestedButAnticipatory = false;
  bool _arrestedAndRemandedPolice = false;
  bool _surrenderBailed = false;
  bool _surrenderJudicial = false;
  bool _surrenderPolice = false;

  // 6. Particulars of the Accused
  final _accusedNameCtrl = TextEditingController();
  final _accusedFatherCtrl = TextEditingController();
  final _accusedAlias1Ctrl = TextEditingController();
  final _accusedAlias2Ctrl = TextEditingController();
  final _accusedNationalityCtrl = TextEditingController();
  final _accusedVoterCtrl = TextEditingController();
  final _accusedPassportCtrl = TextEditingController();
  final _accusedDateIssueCtrl = TextEditingController();
  final _accusedPlaceIssueCtrl = TextEditingController();
  final _accusedReligionCtrl = TextEditingController();
  final _accusedCasteCtrl = TextEditingController();
  final _accusedScStCtrl = TextEditingController();
  final _accusedOccupationCtrl = TextEditingController();

  final _permAddressCtrl = TextEditingController();
  final _permStateCtrl = TextEditingController();
  final _permDistCtrl = TextEditingController();
  final _permPsCtrl = TextEditingController();

  final _presAddressCtrl = TextEditingController();
  final _presStateCtrl = TextEditingController();
  final _presDistCtrl = TextEditingController();
  final _presPsCtrl = TextEditingController();

  final _injuriesCtrl = TextEditingController();

  // ── Page 2 (Form: 3-B) Controllers ──
  final _custodyDateCtrl = TextEditingController();
  final _custodyHoursCtrl = TextEditingController();
  final _custodyPlaceCtrl = TextEditingController();

  final _article1Ctrl = TextEditingController();
  final _article2Ctrl = TextEditingController();
  final _article3Ctrl = TextEditingController();
  final _article4Ctrl = TextEditingController();
  final _article5Ctrl = TextEditingController();
  final _article6Ctrl = TextEditingController();

  final _intimationNameCtrl = TextEditingController();
  final _intimationRelCtrl = TextEditingController();

  // 9. Physical features — 3 independent tables with dynamic rows
  List<Map<String, TextEditingController>> _t1Rows = [];
  List<Map<String, TextEditingController>> _t2Rows = [];
  List<Map<String, TextEditingController>> _t3Rows = [];
  final _otherFeaturesCtrl = TextEditingController();

  // ── Page 3 (Form: 3-C) Controllers ──
  final _fingerprintCtrl = TextEditingController();

  // 11(a) Living Status checkboxes
  bool _livingAlone = false;
  bool _livingWithFamily = false;
  bool _livingWithAssociate = false;
  bool _livingPucca = false;
  bool _livingHotel = false;
  bool _livingHostel = false;
  bool _livingKachcha = false;
  bool _livingThatched = false;
  bool _livingSlum = false;
  bool _livingHomeless = false;
  bool _livingHarbourer = false;

  final _eduQualCtrl = TextEditingController();
  final _occupation2Ctrl = TextEditingController();

  // 11(d) Income Group
  bool _incomeLower = false;
  bool _incomeLowerMid = false;
  bool _incomeMiddle = false;
  bool _incomeUpperMid = false;
  bool _incomeUpperMid2 = false;
  bool _incomeUpper = false;

  // 12. Records
  bool _isDangerous = false;
  bool _prevEscaped = false;
  bool _generallyArmed = false;
  bool _operatesWithAccomplices = false;
  bool _pastCriminal = false;
  bool _isRecidivism = false;
  bool _likelyToEscape = false;
  bool _releasedOnBail = false;
  bool _wantedMany = false;
  final _caseRefSecCtrl = TextEditingController();

  // 13. Panch witnesses
  final _panch1NameCtrl = TextEditingController();
  final _panch2NameCtrl = TextEditingController();
  final _panch1SigCtrl = TextEditingController();
  final _panch2SigCtrl = TextEditingController();

  // 14. Signatures
  final _arrestedPersonSigCtrl = TextEditingController();
  final _ioSigCtrl = TextEditingController();

  // 15. Place/Date & IO details
  final _finalPlaceCtrl = TextEditingController();
  final _finalDateCtrl = TextEditingController();
  final _finalNameCtrl = TextEditingController();
  final _finalRankCtrl = TextEditingController();
  final _finalNoCtrl = TextEditingController();

  Map<String, TextEditingController> _createRow(List<int> indices, [Map<String, dynamic>? initial]) {
    final map = <String, TextEditingController>{};
    for (final i in indices) {
      final key = i.toString();
      map[key] = TextEditingController(text: initial?[key]?.toString() ?? '');
    }
    return map;
  }

  void _ensureRows() {
    try {
      if (_t1Rows.isEmpty) {
        _t1Rows = [_createRow([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])];
      }
      if (_t2Rows.isEmpty) {
        _t2Rows = [_createRow([11, 12, 13, 14, 15, 16, 17, 18, 19, 20])];
      }
      if (_t3Rows.isEmpty) {
        _t3Rows = [_createRow([21, 22, 23, 24, 25, 26])];
      }
    } catch (_) {
      _t1Rows = [_createRow([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])];
      _t2Rows = [_createRow([11, 12, 13, 14, 15, 16, 17, 18, 19, 20])];
      _t3Rows = [_createRow([21, 22, 23, 24, 25, 26])];
    }
  }

  void _addT1Row() {
    setState(() {
      _t1Rows.add(_createRow([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]));
    });
  }

  void _removeT1Row() {
    if (_t1Rows.length <= 1) return;
    setState(() {
      final removed = _t1Rows.removeLast();
      for (final c in removed.values) {
        c.dispose();
      }
    });
  }

  void _addT2Row() {
    setState(() {
      _t2Rows.add(_createRow([11, 12, 13, 14, 15, 16, 17, 18, 19, 20]));
    });
  }

  void _removeT2Row() {
    if (_t2Rows.length <= 1) return;
    setState(() {
      final removed = _t2Rows.removeLast();
      for (final c in removed.values) {
        c.dispose();
      }
    });
  }

  void _addT3Row() {
    setState(() {
      _t3Rows.add(_createRow([21, 22, 23, 24, 25, 26]));
    });
  }

  void _removeT3Row() {
    if (_t3Rows.length <= 1) return;
    setState(() {
      final removed = _t3Rows.removeLast();
      for (final c in removed.values) {
        c.dispose();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _ensureRows();
    if (widget.existingRecord != null && widget.existingRecord is Map) {
      hydrateFrom(Map<String, dynamic>.from(widget.existingRecord as Map));
    }
  }

  @override
  void dispose() {
    _distCtrl.dispose();
    _psCtrl.dispose();
    _firNoCtrl.dispose();
    _yearCtrl.dispose();
    _dateCtrl.dispose();
    _accusedCodeCtrl.dispose();
    _arrestDateCtrl.dispose();
    _arrestTimeCtrl.dispose();
    _arrestGdNoCtrl.dispose();
    _arrestPlaceCtrl.dispose();
    _arrestDistCtrl.dispose();
    _arrestStateCtrl.dispose();
    _courtNameCtrl.dispose();
    _actsSectionsCtrl.dispose();
    _accusedNameCtrl.dispose();
    _accusedFatherCtrl.dispose();
    _accusedAlias1Ctrl.dispose();
    _accusedAlias2Ctrl.dispose();
    _accusedNationalityCtrl.dispose();
    _accusedVoterCtrl.dispose();
    _accusedPassportCtrl.dispose();
    _accusedDateIssueCtrl.dispose();
    _accusedPlaceIssueCtrl.dispose();
    _accusedReligionCtrl.dispose();
    _accusedCasteCtrl.dispose();
    _accusedScStCtrl.dispose();
    _accusedOccupationCtrl.dispose();
    _permAddressCtrl.dispose();
    _permStateCtrl.dispose();
    _permDistCtrl.dispose();
    _permPsCtrl.dispose();
    _presAddressCtrl.dispose();
    _presStateCtrl.dispose();
    _presDistCtrl.dispose();
    _presPsCtrl.dispose();
    _injuriesCtrl.dispose();
    _custodyDateCtrl.dispose();
    _custodyHoursCtrl.dispose();
    _custodyPlaceCtrl.dispose();
    _article1Ctrl.dispose();
    _article2Ctrl.dispose();
    _article3Ctrl.dispose();
    _article4Ctrl.dispose();
    _article5Ctrl.dispose();
    _article6Ctrl.dispose();
    _intimationNameCtrl.dispose();
    _intimationRelCtrl.dispose();
    try {
      for (final row in _t1Rows) {
        for (final c in row.values) {
          c.dispose();
        }
      }
      for (final row in _t2Rows) {
        for (final c in row.values) {
          c.dispose();
        }
      }
      for (final row in _t3Rows) {
        for (final c in row.values) {
          c.dispose();
        }
      }
    } catch (_) {}
    _otherFeaturesCtrl.dispose();
    _fingerprintCtrl.dispose();
    _eduQualCtrl.dispose();
    _occupation2Ctrl.dispose();
    _caseRefSecCtrl.dispose();
    _panch1NameCtrl.dispose();
    _panch2NameCtrl.dispose();
    _panch1SigCtrl.dispose();
    _panch2SigCtrl.dispose();
    _arrestedPersonSigCtrl.dispose();
    _ioSigCtrl.dispose();
    _finalPlaceCtrl.dispose();
    _finalDateCtrl.dispose();
    _finalNameCtrl.dispose();
    _finalRankCtrl.dispose();
    _finalNoCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> collectData() {
    _ensureRows();

    final t1List = _t1Rows.map((row) {
      final map = <String, String>{};
      row.forEach((k, v) => map[k] = v.text.trim());
      return map;
    }).toList();

    final t2List = _t2Rows.map((row) {
      final map = <String, String>{};
      row.forEach((k, v) => map[k] = v.text.trim());
      return map;
    }).toList();

    final t3List = _t3Rows.map((row) {
      final map = <String, String>{};
      row.forEach((k, v) => map[k] = v.text.trim());
      return map;
    }).toList();

    final pt0 = <String, String>{};
    if (_t1Rows.isNotEmpty) {
      _t1Rows.first.forEach((k, v) => pt0[k] = v.text.trim());
    }
    if (_t2Rows.isNotEmpty) {
      _t2Rows.first.forEach((k, v) => pt0[k] = v.text.trim());
    }
    if (_t3Rows.isNotEmpty) {
      _t3Rows.first.forEach((k, v) => pt0[k] = v.text.trim());
    }

    return {
      'formSection': widget.formSection ?? '',
      'pageRange': widget.pageRange ?? '',
      'dist': _distCtrl.text.trim(),
      'ps': _psCtrl.text.trim(),
      'firNo': _firNoCtrl.text.trim(),
      'year': _yearCtrl.text.trim(),
      'date': _dateCtrl.text.trim(),
      'accusedCode': _accusedCodeCtrl.text.trim(),
      'arrestDate': _arrestDateCtrl.text.trim(),
      'arrestTime': _arrestTimeCtrl.text.trim(),
      'arrestGdNo': _arrestGdNoCtrl.text.trim(),
      'arrestPlace': _arrestPlaceCtrl.text.trim(),
      'arrestDist': _arrestDistCtrl.text.trim(),
      'arrestState': _arrestStateCtrl.text.trim(),
      'courtName': _courtNameCtrl.text.trim(),
      'actsSections': _actsSectionsCtrl.text.trim(),
      'arrestedAndForwarded': _arrestedAndForwarded,
      'arrestedAndBailed': _arrestedAndBailed,
      'arrestedButAnticipatory': _arrestedButAnticipatory,
      'arrestedAndRemandedPolice': _arrestedAndRemandedPolice,
      'surrenderBailed': _surrenderBailed,
      'surrenderJudicial': _surrenderJudicial,
      'surrenderPolice': _surrenderPolice,
      'accusedName': _accusedNameCtrl.text.trim(),
      'accusedFather': _accusedFatherCtrl.text.trim(),
      'accusedAlias1': _accusedAlias1Ctrl.text.trim(),
      'accusedAlias2': _accusedAlias2Ctrl.text.trim(),
      'accusedNationality': _accusedNationalityCtrl.text.trim(),
      'accusedVoter': _accusedVoterCtrl.text.trim(),
      'accusedPassport': _accusedPassportCtrl.text.trim(),
      'accusedDateIssue': _accusedDateIssueCtrl.text.trim(),
      'accusedPlaceIssue': _accusedPlaceIssueCtrl.text.trim(),
      'accusedReligion': _accusedReligionCtrl.text.trim(),
      'accusedCaste': _accusedCasteCtrl.text.trim(),
      'accusedScSt': _accusedScStCtrl.text.trim(),
      'accusedOccupation': _accusedOccupationCtrl.text.trim(),
      'permAddress': _permAddressCtrl.text.trim(),
      'permState': _permStateCtrl.text.trim(),
      'permDist': _permDistCtrl.text.trim(),
      'permPs': _permPsCtrl.text.trim(),
      'presAddress': _presAddressCtrl.text.trim(),
      'presState': _presStateCtrl.text.trim(),
      'presDist': _presDistCtrl.text.trim(),
      'presPs': _presPsCtrl.text.trim(),
      'injuries': _injuriesCtrl.text.trim(),
      'custodyDate': _custodyDateCtrl.text.trim(),
      'custodyHours': _custodyHoursCtrl.text.trim(),
      'custodyPlace': _custodyPlaceCtrl.text.trim(),
      'article1': _article1Ctrl.text.trim(),
      'article2': _article2Ctrl.text.trim(),
      'article3': _article3Ctrl.text.trim(),
      'article4': _article4Ctrl.text.trim(),
      'article5': _article5Ctrl.text.trim(),
      'article6': _article6Ctrl.text.trim(),
      'intimationName': _intimationNameCtrl.text.trim(),
      'intimationRel': _intimationRelCtrl.text.trim(),
      't1Rows': t1List,
      't2Rows': t2List,
      't3Rows': t3List,
      'physTable': pt0,
      'otherFeatures': _otherFeaturesCtrl.text.trim(),
      'fingerprint': _fingerprintCtrl.text.trim(),
      'livingAlone': _livingAlone,
      'livingWithFamily': _livingWithFamily,
      'livingWithAssociate': _livingWithAssociate,
      'livingPucca': _livingPucca,
      'livingHotel': _livingHotel,
      'livingHostel': _livingHostel,
      'livingKachcha': _livingKachcha,
      'livingThatched': _livingThatched,
      'livingSlum': _livingSlum,
      'livingHomeless': _livingHomeless,
      'livingHarbourer': _livingHarbourer,
      'eduQual': _eduQualCtrl.text.trim(),
      'occupation2': _occupation2Ctrl.text.trim(),
      'incomeLower': _incomeLower,
      'incomeLowerMid': _incomeLowerMid,
      'incomeMiddle': _incomeMiddle,
      'incomeUpperMid': _incomeUpperMid,
      'incomeUpperMid2': _incomeUpperMid2,
      'incomeUpper': _incomeUpper,
      'isDangerous': _isDangerous,
      'prevEscaped': _prevEscaped,
      'generallyArmed': _generallyArmed,
      'operatesWithAccomplices': _operatesWithAccomplices,
      'pastCriminal': _pastCriminal,
      'isRecidivism': _isRecidivism,
      'likelyToEscape': _likelyToEscape,
      'releasedOnBail': _releasedOnBail,
      'wantedMany': _wantedMany,
      'caseRefSec': _caseRefSecCtrl.text.trim(),
      'panch1Name': _panch1NameCtrl.text.trim(),
      'panch2Name': _panch2NameCtrl.text.trim(),
      'panch1Sig': _panch1SigCtrl.text.trim(),
      'panch2Sig': _panch2SigCtrl.text.trim(),
      'arrestedPersonSig': _arrestedPersonSigCtrl.text.trim(),
      'ioSig': _ioSigCtrl.text.trim(),
      'finalPlace': _finalPlaceCtrl.text.trim(),
      'finalDate': _finalDateCtrl.text.trim(),
      'finalName': _finalNameCtrl.text.trim(),
      'finalRank': _finalRankCtrl.text.trim(),
      'finalNo': _finalNoCtrl.text.trim(),
    };
  }

  // Backward-compatibility alias
  Map<String, dynamic> extractData() => collectData();

  void hydrateFrom(Map<String, dynamic> data) {
    void set(TextEditingController c, String key) {
      c.text = data[key]?.toString() ?? '';
    }

    void setBool(void Function(bool) setter, String key) {
      final v = data[key];
      if (v is bool) {
        setter(v);
      } else if (v is String) {
        setter(v == 'true' || v == '1');
      }
    }

    setState(() {
      set(_distCtrl, 'dist');
      set(_psCtrl, 'ps');
      set(_firNoCtrl, 'firNo');
      set(_yearCtrl, 'year');
      set(_dateCtrl, 'date');
      set(_accusedCodeCtrl, 'accusedCode');
      set(_arrestDateCtrl, 'arrestDate');
      set(_arrestTimeCtrl, 'arrestTime');
      set(_arrestGdNoCtrl, 'arrestGdNo');
      set(_arrestPlaceCtrl, 'arrestPlace');
      set(_arrestDistCtrl, 'arrestDist');
      set(_arrestStateCtrl, 'arrestState');
      set(_courtNameCtrl, 'courtName');
      set(_actsSectionsCtrl, 'actsSections');

      setBool((v) => _arrestedAndForwarded = v, 'arrestedAndForwarded');
      setBool((v) => _arrestedAndBailed = v, 'arrestedAndBailed');
      setBool((v) => _arrestedButAnticipatory = v, 'arrestedButAnticipatory');
      setBool((v) => _arrestedAndRemandedPolice = v, 'arrestedAndRemandedPolice');
      setBool((v) => _surrenderBailed = v, 'surrenderBailed');
      setBool((v) => _surrenderJudicial = v, 'surrenderJudicial');
      setBool((v) => _surrenderPolice = v, 'surrenderPolice');

      set(_accusedNameCtrl, 'accusedName');
      set(_accusedFatherCtrl, 'accusedFather');
      set(_accusedAlias1Ctrl, 'accusedAlias1');
      set(_accusedAlias2Ctrl, 'accusedAlias2');
      set(_accusedNationalityCtrl, 'accusedNationality');
      set(_accusedVoterCtrl, 'accusedVoter');
      set(_accusedPassportCtrl, 'accusedPassport');
      set(_accusedDateIssueCtrl, 'accusedDateIssue');
      set(_accusedPlaceIssueCtrl, 'accusedPlaceIssue');
      set(_accusedReligionCtrl, 'accusedReligion');
      set(_accusedCasteCtrl, 'accusedCaste');
      set(_accusedScStCtrl, 'accusedScSt');
      set(_accusedOccupationCtrl, 'accusedOccupation');

      set(_permAddressCtrl, 'permAddress');
      set(_permStateCtrl, 'permState');
      set(_permDistCtrl, 'permDist');
      set(_permPsCtrl, 'permPs');

      set(_presAddressCtrl, 'presAddress');
      set(_presStateCtrl, 'presState');
      set(_presDistCtrl, 'presDist');
      set(_presPsCtrl, 'presPs');

      set(_injuriesCtrl, 'injuries');

      set(_custodyDateCtrl, 'custodyDate');
      set(_custodyHoursCtrl, 'custodyHours');
      set(_custodyPlaceCtrl, 'custodyPlace');

      set(_article1Ctrl, 'article1');
      set(_article2Ctrl, 'article2');
      set(_article3Ctrl, 'article3');
      set(_article4Ctrl, 'article4');
      set(_article5Ctrl, 'article5');
      set(_article6Ctrl, 'article6');

      set(_intimationNameCtrl, 'intimationName');
      set(_intimationRelCtrl, 'intimationRel');

      // Hydrate Table 1
      final t1Data = data['t1Rows'];
      if (t1Data is List && t1Data.isNotEmpty) {
        for (final row in _t1Rows) {
          for (final c in row.values) {
            c.dispose();
          }
        }
        _t1Rows.clear();
        for (final r in t1Data) {
          if (r is Map) {
            _t1Rows.add(_createRow([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], Map<String, dynamic>.from(r)));
          }
        }
      }

      // Hydrate Table 2
      final t2Data = data['t2Rows'];
      if (t2Data is List && t2Data.isNotEmpty) {
        for (final row in _t2Rows) {
          for (final c in row.values) {
            c.dispose();
          }
        }
        _t2Rows.clear();
        for (final r in t2Data) {
          if (r is Map) {
            _t2Rows.add(_createRow([11, 12, 13, 14, 15, 16, 17, 18, 19, 20], Map<String, dynamic>.from(r)));
          }
        }
      }

      // Hydrate Table 3
      final t3Data = data['t3Rows'];
      if (t3Data is List && t3Data.isNotEmpty) {
        for (final row in _t3Rows) {
          for (final c in row.values) {
            c.dispose();
          }
        }
        _t3Rows.clear();
        for (final r in t3Data) {
          if (r is Map) {
            _t3Rows.add(_createRow([21, 22, 23, 24, 25, 26], Map<String, dynamic>.from(r)));
          }
        }
      }

      // Fallback for single physTable / legacy physRows
      if ((t1Data == null || (t1Data is List && t1Data.isEmpty)) && data['physTable'] is Map) {
        final pt = data['physTable'] as Map;
        _ensureRows();
        pt.forEach((k, v) {
          final ks = k.toString();
          if (_t1Rows.first.containsKey(ks)) _t1Rows.first[ks]!.text = v?.toString() ?? '';
          if (_t2Rows.first.containsKey(ks)) _t2Rows.first[ks]!.text = v?.toString() ?? '';
          if (_t3Rows.first.containsKey(ks)) _t3Rows.first[ks]!.text = v?.toString() ?? '';
        });
      }

      set(_otherFeaturesCtrl, 'otherFeatures');
      set(_fingerprintCtrl, 'fingerprint');

      setBool((v) => _livingAlone = v, 'livingAlone');
      setBool((v) => _livingWithFamily = v, 'livingWithFamily');
      setBool((v) => _livingWithAssociate = v, 'livingWithAssociate');
      setBool((v) => _livingPucca = v, 'livingPucca');
      setBool((v) => _livingHotel = v, 'livingHotel');
      setBool((v) => _livingHostel = v, 'livingHostel');
      setBool((v) => _livingKachcha = v, 'livingKachcha');
      setBool((v) => _livingThatched = v, 'livingThatched');
      setBool((v) => _livingSlum = v, 'livingSlum');
      setBool((v) => _livingHomeless = v, 'livingHomeless');
      setBool((v) => _livingHarbourer = v, 'livingHarbourer');

      set(_eduQualCtrl, 'eduQual');
      set(_occupation2Ctrl, 'occupation2');

      setBool((v) => _incomeLower = v, 'incomeLower');
      setBool((v) => _incomeLowerMid = v, 'incomeLowerMid');
      setBool((v) => _incomeMiddle = v, 'incomeMiddle');
      setBool((v) => _incomeUpperMid = v, 'incomeUpperMid');
      setBool((v) => _incomeUpperMid2 = v, 'incomeUpperMid2');
      setBool((v) => _incomeUpper = v, 'incomeUpper');

      setBool((v) => _isDangerous = v, 'isDangerous');
      setBool((v) => _prevEscaped = v, 'prevEscaped');
      setBool((v) => _generallyArmed = v, 'generallyArmed');
      setBool((v) => _operatesWithAccomplices = v, 'operatesWithAccomplices');
      setBool((v) => _pastCriminal = v, 'pastCriminal');
      setBool((v) => _isRecidivism = v, 'isRecidivism');
      setBool((v) => _likelyToEscape = v, 'likelyToEscape');
      setBool((v) => _releasedOnBail = v, 'releasedOnBail');
      setBool((v) => _wantedMany = v, 'wantedMany');
      set(_caseRefSecCtrl, 'caseRefSec');

      set(_panch1NameCtrl, 'panch1Name');
      set(_panch2NameCtrl, 'panch2Name');
      set(_panch1SigCtrl, 'panch1Sig');
      set(_panch2SigCtrl, 'panch2Sig');

      set(_arrestedPersonSigCtrl, 'arrestedPersonSig');
      set(_ioSigCtrl, 'ioSig');

      set(_finalPlaceCtrl, 'finalPlace');
      set(_finalDateCtrl, 'finalDate');
      set(_finalNameCtrl, 'finalName');
      set(_finalRankCtrl, 'finalRank');
      set(_finalNoCtrl, 'finalNo');
    });
  }

  // ── Input Helper Widgets ──

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
          hintStyle: style.copyWith(
            fontSize: 11,
            color: Colors.grey.shade400,
            fontStyle: FontStyle.italic,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          border: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF333333), width: 1.0),
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF555555), width: 1.0),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF1976D2), width: 2.0),
          ),
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
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF555555), width: 1.0),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF555555), width: 1.0),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF1976D2), width: 2.0),
        ),
      ),
    );
  }

  Widget _subLabel(String text, TextStyle marathiStyle) {
    return Text(
      text,
      style: marathiStyle.copyWith(
        fontSize: 10,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildCheckOption(String textEn, String textMr, bool value, ValueChanged<bool?> onChanged, TextStyle style, TextStyle marathiStyle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: widget.readOnly ? null : onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: textEn, style: style.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.black87)),
                    if (textMr.isNotEmpty)
                      TextSpan(text: '\n$textMr', style: marathiStyle.copyWith(fontSize: 11, color: Colors.black87)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYesNoRow(String numStr, String qEn, String qMr, bool val, ValueChanged<bool?> onChanged, TextStyle style, TextStyle marathiStyle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$numStr $qEn', style: style.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600)),
                Text(qMr, style: marathiStyle.copyWith(fontSize: 11)),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Yes (होय)', style: style.copyWith(fontSize: 11)),
              Checkbox(
                value: val,
                onChanged: widget.readOnly ? null : (v) => onChanged(true),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              Text('No (नाही)', style: style.copyWith(fontSize: 11)),
              Checkbox(
                value: !val,
                onChanged: widget.readOnly ? null : (v) => onChanged(false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 1 — FORM 3-A
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPage1(TextStyle style, TextStyle marathiStyle) {
    return FormPaperPage(
      formLabel: 'Form 3-A',
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text('From: 3-A', style: style.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        const SizedBox(height: 4),

        Center(
          child: Column(
            children: [
              Text(
                'ARREST/COURT SURRENDER FORM',
                textAlign: TextAlign.center,
                style: style.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                'अटकेचा पंचनामा/ न्यायालयाच्या स्वाधीन होण्याचा नमुना',
                textAlign: TextAlign.center,
                style: marathiStyle.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '(Separate Memo for each accused)',
                style: style.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                '(प्रत्येक आरोपीसाठी स्वतंत्र नमुना वापरावा)',
                style: marathiStyle.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Line 1: Dist, P.S., FIR, Year, Date
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 3,
          runSpacing: 4,
          children: [
            Text('1.Dist.(YAVATMAL)P.S.:', style: style),
            _inlineBlank(controller: _psCtrl, style: style, width: 110),
            Text('FIR/Proceeding/G.D.No:-', style: style),
            _inlineBlank(controller: _firNoCtrl, style: style, width: 90),
            Text('Year:-20', style: style),
            _inlineBlank(controller: _yearCtrl, style: style, width: 40),
            Text('Date.....', style: style),
            _inlineBlank(controller: _dateCtrl, style: style, width: 90),
          ],
        ),
        Row(
          children: [
            _subLabel('   जिल्हा                    पो.स्टे.                 पहिली खबर क्र./ कार्यवाही क्र.             वर्ष          दिनांक', marathiStyle),
          ],
        ),
        const SizedBox(height: 6),

        // Alphanumeric code
        Row(
          children: [
            Text('Alphanumeric Code of the Accused (Write A1 to A9 for the first 9 persons, B1 for 10 th person and so on).', style: style.copyWith(fontSize: 11.5)),
            Expanded(child: _inlineBlank(controller: _accusedCodeCtrl, style: style)),
          ],
        ),
        _subLabel('आरोपीचा मुळाक्षरी संकेत (पहिल्या ९ व्यक्तीसाठी अ १ ते अ ९, दहाव्या व्यक्तीसाठी ब १ या प्रमाणे पुढे असे लिहावे )', marathiStyle),
        const SizedBox(height: 10),

        // 2. Date, Time & place of Arrest/surrender
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 3,
          runSpacing: 4,
          children: [
            Text('2. Date, Time & place of Arrest/surrender :- Date ', style: style),
            _inlineBlank(controller: _arrestDateCtrl, style: style, width: 80),
            Text(' Time ', style: style),
            _inlineBlank(controller: _arrestTimeCtrl, style: style, width: 70),
            Text(' G.D.No. ', style: style),
            _inlineBlank(controller: _arrestGdNoCtrl, style: style, width: 80),
          ],
        ),
        _subLabel('   अटकेची / स्वाधीन होण्याची तारीख वेळ              दिनांक                  वेळ               ठाणे दैनंदिन क्रमांक', marathiStyle),
        const SizedBox(height: 4),

        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 3,
          runSpacing: 4,
          children: [
            Text('Place of Arrest: - P.S. ', style: style),
            _inlineBlank(controller: _arrestPlaceCtrl, style: style, width: 140),
            Text(' Dist. ', style: style),
            _inlineBlank(controller: _arrestDistCtrl, style: style, width: 120),
            Text(' State ', style: style),
            _inlineBlank(controller: _arrestStateCtrl, style: style, width: 120),
          ],
        ),
        _subLabel('   अटकेची जागा         पोलीस ठाणे                   जिल्हा                       राज्य', marathiStyle),
        const SizedBox(height: 8),

        // 3. Name of Court
        Row(
          children: [
            Text('3. Name of the Court (if surrendered) :- ', style: style),
            Expanded(child: _inlineBlank(controller: _courtNameCtrl, style: style)),
          ],
        ),
        _subLabel('   न्यायालयाचे नांव ( स्वाधीन झाल्यास ) :-', marathiStyle),
        const SizedBox(height: 8),

        // 4. Acts & sections
        Row(
          children: [
            Text('4. Acts and sections:- ', style: style),
            Expanded(child: _inlineBlank(controller: _actsSectionsCtrl, style: style)),
          ],
        ),
        _subLabel('   अधिनियम व कलमे :-', marathiStyle),
        const SizedBox(height: 8),

        // 5. 7 Action Checkboxes
        Text(
          '5. Arrested and forward / Arrested and released on bail or PR bound / Arrested but released on anticipatory bail/ Arrested and remanded to police Custody / Surrender in court and bailed out / Surrender in court and sent to judicial Custody / Surrender in court and remanded to police custody (tie applicable potion).',
          style: style.copyWith(fontSize: 11.5, fontWeight: FontWeight.bold),
        ),
        Text(
          'अटक केली व न्यायालयात पाठविले / अटक केली व जामिनावर सोडले किंवा वैयक्तिक जात मुचलक्यावर सोडले / अटक केली व अटकपूर्व जामिनावर सोडले / अटक केले व पोलीस कोठडीत पाठविले/ न्यायालयात स्वाधीन व जामीनावर / न्यायालयाचे स्वाधीन व न्यायालयीन कोठडीत पाठविले / न्यायालयाचे स्वाधीन व पोलीस कोठडीत पाठविले (लागू असेल त्या भागावर [v] अशी खूण करावी )',
          style: marathiStyle.copyWith(fontSize: 10.5),
        ),
        const SizedBox(height: 4),

        _buildCheckOption('Arrested and forward', 'अटक केली व न्यायालयात पाठविले', _arrestedAndForwarded, (v) => setState(() => _arrestedAndForwarded = v ?? false), style, marathiStyle),
        _buildCheckOption('Arrested and released on bail or PR bound', 'अटक केली व जामिनावर सोडले किंवा वैयक्तिक जात मुचलक्यावर सोडले', _arrestedAndBailed, (v) => setState(() => _arrestedAndBailed = v ?? false), style, marathiStyle),
        _buildCheckOption('Arrested but released on anticipatory bail', 'अटक केली व अटकपूर्व जामिनावर सोडले', _arrestedButAnticipatory, (v) => setState(() => _arrestedButAnticipatory = v ?? false), style, marathiStyle),
        _buildCheckOption('Arrested and remanded to police Custody', 'अटक केले व पोलीस कोठडीत पाठविले', _arrestedAndRemandedPolice, (v) => setState(() => _arrestedAndRemandedPolice = v ?? false), style, marathiStyle),
        _buildCheckOption('Surrender in court and bailed out', 'न्यायालयात स्वाधीन व जामीनावर', _surrenderBailed, (v) => setState(() => _surrenderBailed = v ?? false), style, marathiStyle),
        _buildCheckOption('Surrender in court and sent to judicial Custody', 'न्यायालयाचे स्वाधीन व न्यायालयीन कोठडीत पाठविले', _surrenderJudicial, (v) => setState(() => _surrenderJudicial = v ?? false), style, marathiStyle),
        _buildCheckOption('Surrender in court and remanded to police custody', 'न्यायालयाचे स्वाधीन व पोलीस कोठडीत पाठविले', _surrenderPolice, (v) => setState(() => _surrenderPolice = v ?? false), style, marathiStyle),
        const SizedBox(height: 10),

        // 6. Particulars of the Accused
        Text('6. Particulars of the Accused (आरोपीचा तपशील ) :-', style: style.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),

        Row(
          children: [
            Text('(i) Name (नाव) : ', style: style),
            Expanded(child: _inlineBlank(controller: _accusedNameCtrl, style: style)),
          ],
        ),
        const SizedBox(height: 6),

        Row(
          children: [
            Text("(ii) Father's/Husband's/Guardian's Name (पित्याचे/पतीचे/पालकाचे नांव ) : ", style: style),
            Expanded(child: _inlineBlank(controller: _accusedFatherCtrl, style: style)),
          ],
        ),
        const SizedBox(height: 6),

        Row(
          children: [
            Text('(iii) Fist Alias (पहिले टोपण नांव ) : ', style: style),
            Expanded(child: _inlineBlank(controller: _accusedAlias1Ctrl, style: style)),
          ],
        ),
        const SizedBox(height: 6),

        Row(
          children: [
            Text('(iv) Second Alias (दुसरे टोपण नांव ) : ', style: style),
            Expanded(child: _inlineBlank(controller: _accusedAlias2Ctrl, style: style)),
          ],
        ),
        const SizedBox(height: 6),

        Row(
          children: [
            Text('(v) Nationality (राष्ट्रीयत्व) : ', style: style),
            Expanded(child: _inlineBlank(controller: _accusedNationalityCtrl, style: style)),
          ],
        ),
        const SizedBox(height: 6),

        Row(
          children: [
            Text('(vi) (a) Voter ID. Card No: - ', style: style),
            Expanded(child: _inlineBlank(controller: _accusedVoterCtrl, style: style)),
            const SizedBox(width: 10),
            Text('(b) *Passport No: - ', style: style),
            Expanded(child: _inlineBlank(controller: _accusedPassportCtrl, style: style)),
          ],
        ),
        _subLabel('         मतदान ओळखपत्र क्रमांक:-                                पारपत्र क्रमांक :-', marathiStyle),
        const SizedBox(height: 4),

        Row(
          children: [
            Text('(c) Date of issue : - ', style: style),
            Expanded(child: _inlineBlank(controller: _accusedDateIssueCtrl, style: style)),
            const SizedBox(width: 10),
            Text('(d) *Place or Issue :- ', style: style),
            Expanded(child: _inlineBlank(controller: _accusedPlaceIssueCtrl, style: style)),
          ],
        ),
        _subLabel('         दिल्याची तारीख :-                                      दिल्याची जागा :-', marathiStyle),
        const SizedBox(height: 4),

        Row(
          children: [
            Text('(vii) Religion: - ', style: style),
            Expanded(child: _inlineBlank(controller: _accusedReligionCtrl, style: style)),
            const SizedBox(width: 10),
            Text('(viii) *Cast/Tribe: - ', style: style),
            Expanded(child: _inlineBlank(controller: _accusedCasteCtrl, style: style)),
          ],
        ),
        _subLabel('      धर्म :-                                                   जात/जमात :-', marathiStyle),
        const SizedBox(height: 4),

        Row(
          children: [
            Text('(ix) SC/ST/OBC :- ', style: style),
            Expanded(child: _inlineBlank(controller: _accusedScStCtrl, style: style)),
            const SizedBox(width: 10),
            Text('(x) *Occupation :- ', style: style),
            Expanded(child: _inlineBlank(controller: _accusedOccupationCtrl, style: style)),
          ],
        ),
        _subLabel('      (अ.जा./अ.ज./इ.मा.व.) :-                                    व्यवसाय :-', marathiStyle),
        const SizedBox(height: 6),

        Row(
          children: [
            Text('(xi) Permanent Address : ', style: style),
            Expanded(child: _inlineBlank(controller: _permAddressCtrl, style: style)),
          ],
        ),
        _subLabel('      कायमचा पत्ता :-', marathiStyle),
        const SizedBox(height: 4),

        Row(
          children: [
            Text('      State : - ', style: style),
            Expanded(child: _inlineBlank(controller: _permStateCtrl, style: style)),
            const SizedBox(width: 8),
            Text('Dist.:- ', style: style),
            Expanded(child: _inlineBlank(controller: _permDistCtrl, style: style)),
            const SizedBox(width: 8),
            Text('P.S. : - ', style: style),
            Expanded(child: _inlineBlank(controller: _permPsCtrl, style: style)),
          ],
        ),
        _subLabel('      राज्य                             जिल्हा                          पोलीस ठाणे', marathiStyle),
        const SizedBox(height: 6),

        Row(
          children: [
            Text('(xii) Present Address : ', style: style),
            Expanded(child: _inlineBlank(controller: _presAddressCtrl, style: style)),
          ],
        ),
        _subLabel('      हल्लीचा पत्ता :-', marathiStyle),
        const SizedBox(height: 4),

        Row(
          children: [
            Text('      State : - ', style: style),
            Expanded(child: _inlineBlank(controller: _presStateCtrl, style: style)),
            const SizedBox(width: 8),
            Text('Dist.:- ', style: style),
            Expanded(child: _inlineBlank(controller: _presDistCtrl, style: style)),
            const SizedBox(width: 8),
            Text('P.S. : - ', style: style),
            Expanded(child: _inlineBlank(controller: _presPsCtrl, style: style)),
          ],
        ),
        _subLabel('      राज्य                             जिल्हा                          पोलीस ठाणे', marathiStyle),
        const SizedBox(height: 10),

        // 7. Injuries
        Text('7. Injuries, cause of injuries and physical condition of the accused person (indicate if medically examined)', style: style.copyWith(fontWeight: FontWeight.bold)),
        _subLabel('जखमा, जखमांची कारणे आणि आरोपीची शारीरिक स्थिती / (वैद्यकीय तपासणी केली असल्यास नमूद करणे)', marathiStyle),
        _multilineBlankBox(controller: _injuriesCtrl, style: style, minLines: 2),

        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Text('M.R.W', style: style.copyWith(fontSize: 10, fontStyle: FontStyle.italic)),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 2 — FORM 3-B
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPage2(TextStyle style, TextStyle marathiStyle) {
    _ensureRows();

    return FormPaperPage(
      formLabel: 'Form 3-B',
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text('From: 3-B', style: style.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        const SizedBox(height: 6),

        // 8. Custody paragraph
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 3,
          runSpacing: 4,
          children: [
            Text('8. The accused, after vying informed of the grounds of arrest and his leagal rights, was duty taken. Into custody on :- ', style: style.copyWith(fontSize: 12.5)),
            _inlineBlank(controller: _custodyDateCtrl, style: style, width: 100),
            Text('(date) at :- ', style: style.copyWith(fontSize: 12.5)),
            _inlineBlank(controller: _custodyHoursCtrl, style: style, width: 80),
            Text('(hours) at :- ', style: style.copyWith(fontSize: 12.5)),
            _inlineBlank(controller: _custodyPlaceCtrl, style: style, width: 130),
            Text('(place).', style: style.copyWith(fontSize: 12.5)),
          ],
        ),
        _subLabel('कायदेशीर अटकेची कारणे आणि त्याचे कायदेशीर अधिकार सांगीतल्यानंतर दि. ----/----/20.... रोजी ..../.... वाजता (ठिकाण) येथे योग्य रित्या ताब्यात घेण्यात आले.', marathiStyle),
        const SizedBox(height: 10),

        Text(
          'The following article(s) was/were found on physical search. Conducted on the person of the accused. And were taken into possession for which a receipt was given to the accused. **',
          style: style.copyWith(fontWeight: FontWeight.bold, fontSize: 12.5),
        ),
        _subLabel('आरोपीच्या अंगझडतीमध्ये खालील वस्तु आढळल्या, त्या ताब्यात घेण्यात आल्या आणि त्या बद्दल त्याची पोच देण्यात आली.', marathiStyle),
        const SizedBox(height: 6),

        Row(
          children: [
            Text('1 ', style: style),
            Expanded(child: _inlineBlank(controller: _article1Ctrl, style: style)),
            const SizedBox(width: 14),
            Text('2 ', style: style),
            Expanded(child: _inlineBlank(controller: _article2Ctrl, style: style)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text('3 ', style: style),
            Expanded(child: _inlineBlank(controller: _article3Ctrl, style: style)),
            const SizedBox(width: 14),
            Text('4 ', style: style),
            Expanded(child: _inlineBlank(controller: _article4Ctrl, style: style)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text('5 ', style: style),
            Expanded(child: _inlineBlank(controller: _article5Ctrl, style: style)),
            const SizedBox(width: 14),
            Text('6 ', style: style),
            Expanded(child: _inlineBlank(controller: _article6Ctrl, style: style)),
          ],
        ),
        const SizedBox(height: 10),

        Text('Necessary wearing apparels were left on the accused for the sake of human dignity and body protection', style: style.copyWith(fontSize: 12.5)),
        _subLabel('(मानवी प्रतिष्ठेसाठी व शरीर झाकण्यासाठी आरोपीच्या अंगावर आवश्यक येवढे कपडे ठेवण्यात आले होते.)', marathiStyle),
        const SizedBox(height: 6),

        Text('The accused was cautioned to keep him/herself covered for purpose of identification.', style: style.copyWith(fontSize: 12.5)),
        _subLabel('ओळख पटण्याच्या प्रयोजनासाठी आरोपीला स्वतःला झाकून ठेवण्याची ताकीद देण्यात आली होती.', marathiStyle),
        const SizedBox(height: 8),

        Row(
          children: [
            Text('Intimation given to Name: ', style: style),
            Expanded(child: _inlineBlank(controller: _intimationNameCtrl, style: style)),
            const SizedBox(width: 10),
            Text('(Relationship): ', style: style),
            Expanded(child: _inlineBlank(controller: _intimationRelCtrl, style: style)),
          ],
        ),
        _subLabel('यांना खबरदेण्यात आली नांव                                            (नाते)', marathiStyle),
        const SizedBox(height: 8),

        Text('** If no article found, NIL, may be indicated in the bland space provided below:-', style: style.copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
        _subLabel('जर कोणतीही वस्तु आढळली नाही तर खालील जागेत काही नाही असे नमुद करावे.', marathiStyle),
        const SizedBox(height: 12),

        // 9. Physical features
        Text('9. Physical features, deformities and other details of the accused:-', style: style.copyWith(fontWeight: FontWeight.bold)),
        _subLabel('शारीरिक वैशिष्ट्ये आणि आरोपीचा इतर तपशील :-', marathiStyle),
        const SizedBox(height: 8),

        // ── Table 1 (Cols 1-10) ──
        _buildCleanTable(
          headers: [
            ('Sr. No.', 'अ.क्र.', '1.'),
            ('Sex', 'लिंग', '2.'),
            ('Date/year of\nBirth', 'जन्म तारीख/\nवर्ष', '3.'),
            ('Build', 'बांधा', '4.'),
            ('Height in\nCms.', 'उंची से.मी.', '5.'),
            ('Complexion', 'वर्ण', '6.'),
            ('identification\n(Mark)', 'ओळखचिन्ह', '7.'),
            ('Deformities\nPeculiarities', 'व्यंग व\nवैशिष्ट्ये', '8.'),
            ('Teeth', 'दात', '9.'),
            ('Hair', 'केस', '10.'),
          ],
          indices: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
          rows: _t1Rows,
          style: style,
          marathiStyle: marathiStyle,
        ),
        if (!widget.readOnly) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              OutlinedButton(
                onPressed: _addT1Row,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(36, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  side: const BorderSide(color: Color(0xFF0D47A1), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Icon(Icons.add, size: 18, color: Color(0xFF0D47A1)),
              ),
              if (_t1Rows.length > 1) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _removeT1Row,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(36, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    side: const BorderSide(color: Colors.red, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Icon(Icons.remove, size: 18, color: Colors.red),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 10),

        // ── Table 2 (Cols 11-20) ──
        _buildCleanTable(
          headers: [
            ('Eye', 'डोळे', '11'),
            ('Habits', 'सवयी', '12'),
            ('Dress\nHabits', 'पोषाखाच्या\nसवयी', '13'),
            ('Languages', 'बोली/ भाषा', '14'),
            ('Burn Mark', 'भाजल्याच्या\nखुणा', '15'),
            ('Leucoderma', 'कोड', '16'),
            ('Mole', 'तिळ', '17'),
            ('Scar', 'व्रण', '18'),
            ('Tattoo', 'गोंदण', '19'),
            ('Forehead', 'कपाळ', '20'),
          ],
          indices: [11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
          rows: _t2Rows,
          style: style,
          marathiStyle: marathiStyle,
        ),
        if (!widget.readOnly) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              OutlinedButton(
                onPressed: _addT2Row,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(36, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  side: const BorderSide(color: Color(0xFF0D47A1), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Icon(Icons.add, size: 18, color: Color(0xFF0D47A1)),
              ),
              if (_t2Rows.length > 1) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _removeT2Row,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(36, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    side: const BorderSide(color: Colors.red, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Icon(Icons.remove, size: 18, color: Colors.red),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 10),

        // ── Table 3 (Cols 21-26) ──
        _buildCleanTable(
          headers: [
            ('Ear', 'कान', '21'),
            ('Noes', 'नाक', '22'),
            ('Moustaches', 'मिशी', '23'),
            ('Speech/voice', 'बोलण्याची पद्धत', '24'),
            ('Face', 'चेहरा', '25'),
            ('Lips', 'ओठ', '26'),
          ],
          indices: [21, 22, 23, 24, 25, 26],
          rows: _t3Rows,
          style: style,
          marathiStyle: marathiStyle,
        ),
        if (!widget.readOnly) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              OutlinedButton(
                onPressed: _addT3Row,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(36, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  side: const BorderSide(color: Color(0xFF0D47A1), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Icon(Icons.add, size: 18, color: Color(0xFF0D47A1)),
              ),
              if (_t3Rows.length > 1) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _removeT3Row,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(36, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    side: const BorderSide(color: Colors.red, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Icon(Icons.remove, size: 18, color: Colors.red),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 12),

        Row(
          children: [
            Text('Other features if any: ', style: style),
            Expanded(child: _inlineBlank(controller: _otherFeaturesCtrl, style: style)),
          ],
        ),

        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Text('M.R.W', style: style.copyWith(fontSize: 10, fontStyle: FontStyle.italic)),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PAGE 3 — FORM 3-C
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPage3(TextStyle style, TextStyle marathiStyle) {
    return FormPaperPage(
      formLabel: 'Form 3-C',
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text('From: 3-C', style: style.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        const SizedBox(height: 6),

        // 10. Fingerprints
        Row(
          children: [
            Text('10. Whether finger print taken or not? :- ', style: style.copyWith(fontWeight: FontWeight.bold)),
            Expanded(child: _inlineBlank(controller: _fingerprintCtrl, style: style)),
          ],
        ),
        _subLabel('बोटांचे ठसे घेतले आहेत किंवा नाही असल्यास त्यांचा नंबर / ठसे घेतले नसल्यास त्याचे कारण.', marathiStyle),
        const SizedBox(height: 12),

        // 11. Socio-economic profile
        Text('11. Socio-economic profile of the accused showing.', style: style.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),

        Text(
          '(a) Living Status: - Living alone/Living with Family/with Associate in Pucca House/Hotel/ Hostel/ Kacheha House / Thatched House / Slum/ Homeless/ Harbourer.',
          style: style.copyWith(fontSize: 12.5),
        ),
        _subLabel('राहणीमान :- एकटा कुटुंबासोबत/ सहकारी यांच्या बरोबर पक्का घरात/ हॉटेलात/ वसतीगृहात/ कच्चा घरात/ गवतानी छपरच्या झोपडीत गरीबांच्या वस्तीत राहतो/ बेघर किंवा आसरा देणारेच नाही.', marathiStyle),
        const SizedBox(height: 4),

        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            _buildSmallCheckbox('Living alone (एकटा)', _livingAlone, (v) => setState(() => _livingAlone = v ?? false), style),
            _buildSmallCheckbox('With Family (कुटुंबासोबत)', _livingWithFamily, (v) => setState(() => _livingWithFamily = v ?? false), style),
            _buildSmallCheckbox('With Associate (सहकारी बरोबर)', _livingWithAssociate, (v) => setState(() => _livingWithAssociate = v ?? false), style),
            _buildSmallCheckbox('Pucca House (पक्के घर)', _livingPucca, (v) => setState(() => _livingPucca = v ?? false), style),
            _buildSmallCheckbox('Hotel (हॉटेलात)', _livingHotel, (v) => setState(() => _livingHotel = v ?? false), style),
            _buildSmallCheckbox('Hostel (वसतीगृह)', _livingHostel, (v) => setState(() => _livingHostel = v ?? false), style),
            _buildSmallCheckbox('Kachcha House (कच्चे घर)', _livingKachcha, (v) => setState(() => _livingKachcha = v ?? false), style),
            _buildSmallCheckbox('Thatched House (छपराचे घर)', _livingThatched, (v) => setState(() => _livingThatched = v ?? false), style),
            _buildSmallCheckbox('Slum (झोपडपट्टी)', _livingSlum, (v) => setState(() => _livingSlum = v ?? false), style),
            _buildSmallCheckbox('Homeless (बेघर)', _livingHomeless, (v) => setState(() => _livingHomeless = v ?? false), style),
            _buildSmallCheckbox('Harbourer (आसरा देणारा)', _livingHarbourer, (v) => setState(() => _livingHarbourer = v ?? false), style),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Text('(b) Educational qualifications(s) (शैक्षणिक अर्हता) : ', style: style),
            Expanded(child: _inlineBlank(controller: _eduQualCtrl, style: style)),
            const SizedBox(width: 8),
            Text('(c) occupation (व्यवसाय) : ', style: style),
            Expanded(child: _inlineBlank(controller: _occupation2Ctrl, style: style)),
          ],
        ),
        const SizedBox(height: 8),

        Text('(d) Income Group (उत्पन्न गट ) :-', style: style.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        _buildCheckOption('(i) Lower Income (Below Rs. 25000 P.Y.)', 'कमी उत्पन्न (रु. २५००० पेक्षा कमी )', _incomeLower, (v) => setState(() => _incomeLower = v ?? false), style, marathiStyle),
        _buildCheckOption('(ii) Lower Middle Income (From Rs. 25001 to 50000)', 'कमी मध्यम उत्पन्न ( २५,००१ ते ५०,०००)', _incomeLowerMid, (v) => setState(() => _incomeLowerMid = v ?? false), style, marathiStyle),
        _buildCheckOption('(iii) Middle Income (From 50001 to 100000)', 'मध्यम उत्पन्न (५०,००१ ते १,००,००० )', _incomeMiddle, (v) => setState(() => _incomeMiddle = v ?? false), style, marathiStyle),
        _buildCheckOption('(iv) Upper Middle Income (/From 100000 to 200000)', 'उच्च मध्यम उत्पन्न ( १,००,००१ ते २,००,०००)', _incomeUpperMid, (v) => setState(() => _incomeUpperMid = v ?? false), style, marathiStyle),
        _buildCheckOption('(v) Upper Middle Income (Rs. 200000 to 300000)', 'उच्च मध्यम उत्पन्न ( २,००,००१ ते ३,००,०००)', _incomeUpperMid2, (v) => setState(() => _incomeUpperMid2 = v ?? false), style, marathiStyle),
        _buildCheckOption('(vi) Upper Income (above 300000) =SSE', 'उच्च उत्पन्न ( ३,००,०००+)', _incomeUpper, (v) => setState(() => _incomeUpper = v ?? false), style, marathiStyle),
        const SizedBox(height: 12),

        // 12. Police records
        Text('12. Whether the accused person as per the observations and known police records:', style: style.copyWith(fontWeight: FontWeight.bold)),
        _subLabel('निरीक्षणावरून आणि माहिती असलेल्या पोलीस अभिलेखानुसार आरोपी :-', marathiStyle),
        const SizedBox(height: 6),

        _buildYesNoRow('(a)', 'Is dangerous ?', '(धोकादायक आहे किंवा कसे?)', _isDangerous, (v) => setState(() => _isDangerous = v ?? false), style, marathiStyle),
        _buildYesNoRow('(b)', 'Previously escaped any bail ?', '(पूर्वी जामिनावर असताना पळून गेला किंवा काय ?)', _prevEscaped, (v) => setState(() => _prevEscaped = v ?? false), style, marathiStyle),
        _buildYesNoRow('(c)', 'Is generally armed?', '(नेहमी सशस्त्र असतो किंवा कसे ?)', _generallyArmed, (v) => setState(() => _generallyArmed = v ?? false), style, marathiStyle),
        _buildYesNoRow('(d)', 'Operates with accomplices?', '(साथीदारासह कृत्य करतो किंवा कसे ?)', _operatesWithAccomplices, (v) => setState(() => _operatesWithAccomplices = v ?? false), style, marathiStyle),
        _buildYesNoRow('(e)', 'Has past criminal records ?', '(गुन्हेगारी पार्श्वभूमी आहे किंवा नाही ?)', _pastCriminal, (v) => setState(() => _pastCriminal = v ?? false), style, marathiStyle),
        _buildYesNoRow('(f)', 'Is recidivism', '(वारंवार अपराध करणे किंवा काय ?)', _isRecidivism, (v) => setState(() => _isRecidivism = v ?? false), style, marathiStyle),
        _buildYesNoRow('(g)', 'Is likely to escape bail ?', '(जामिनावर असताना पळून जाण्याची पूर्वा आहे किंवा नाही ?)', _likelyToEscape, (v) => setState(() => _likelyToEscape = v ?? false), style, marathiStyle),
        _buildYesNoRow('(h)', 'Is released on bail. Likely to commit crime or threaten victims/witnesses.', '(जामिनावर सोडल्यास तसेच गुन्हा करण्याचा किंवा संशयित / साक्षीदारांना धाकदाखवण्याचा पूर्वा आहे किंवा नाही ?)', _releasedOnBail, (v) => setState(() => _releasedOnBail = v ?? false), style, marathiStyle),
        _buildYesNoRow('(i)', 'Is wanted many other case?', '(इतर गुन्ह्यामध्ये पाहिजे किंवा काय ?)', _wantedMany, (v) => setState(() => _wantedMany = v ?? false), style, marathiStyle),

        Row(
          children: [
            Text('(If yes give case ref. Sec.) ', style: style),
            Expanded(child: _inlineBlank(controller: _caseRefSecCtrl, style: style)),
          ],
        ),
        _subLabel('( जर होय असेल तर त्या प्रकरणाचा संदर्भ व कलमे याबद्दल ?)', marathiStyle),
        const SizedBox(height: 14),

        // 13. Panch witnesses
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('13. पंच साक्षी (१) : ', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                      Expanded(child: _inlineBlank(controller: _panch1NameCtrl, style: style)),
                    ],
                  ),
                  _subLabel('Name and Address of the witnesses/Panchas (At Least one witness necessary)', style),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('पंचांच्या सह्या (१) : ', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                      Expanded(child: _inlineBlank(controller: _panch1SigCtrl, style: style)),
                    ],
                  ),
                  _subLabel('Signature', style),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('      पंच साक्षी (२) : ', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                      Expanded(child: _inlineBlank(controller: _panch2NameCtrl, style: style)),
                    ],
                  ),
                  _subLabel('Name and Address of witness (2)', style),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('पंचांच्या सह्या (२) : ', style: marathiStyle.copyWith(fontWeight: FontWeight.bold)),
                      Expanded(child: _inlineBlank(controller: _panch2SigCtrl, style: style)),
                    ],
                  ),
                  _subLabel('Signature (2)', style),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 14. Signatures
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('14. Signature and Thumb Impression of Arrested person', style: style.copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
                  _subLabel('आरोपीची सही व आरोपीचा डा अंगठा', marathiStyle),
                  _inlineBlank(controller: _arrestedPersonSigCtrl, style: style),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Signature of the Investigation Officer with:', style: style.copyWith(fontWeight: FontWeight.bold, fontSize: 12)),
                  _subLabel('तपासणी अधिकाऱ्याचे नांव व सही', marathiStyle),
                  _inlineBlank(controller: _ioSigCtrl, style: style),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 15. Place/Date & IO details
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('15. Place: ', style: style),
                      Expanded(child: _inlineBlank(controller: _finalPlaceCtrl, style: style)),
                    ],
                  ),
                  _subLabel('    ठिकाण', marathiStyle),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('    Date: ', style: style),
                      Expanded(child: _inlineBlank(controller: _finalDateCtrl, style: style)),
                    ],
                  ),
                  _subLabel('    तारीख', marathiStyle),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Name: ', style: style),
                      Expanded(child: _inlineBlank(controller: _finalNameCtrl, style: style)),
                    ],
                  ),
                  _subLabel('तपासणी अधिकाऱ्याचे नांव', marathiStyle),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Rank: ', style: style),
                      Expanded(child: _inlineBlank(controller: _finalRankCtrl, style: style)),
                      const SizedBox(width: 8),
                      Text('No: ', style: style),
                      Expanded(child: _inlineBlank(controller: _finalNoCtrl, style: style)),
                    ],
                  ),
                  _subLabel('पद                         क्रमांक', marathiStyle),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Text('M.R.W', style: style.copyWith(fontSize: 10, fontStyle: FontStyle.italic)),
        ),
      ],
    );
  }

  // ── Clean Table Builder (No blue box inside cells, supports multiple rows) ──

  Widget _buildCleanTable({
    required List<(String, String, String)> headers,
    required List<int> indices,
    required List<Map<String, TextEditingController>> rows,
    required TextStyle style,
    required TextStyle marathiStyle,
  }) {
    return Table(
      border: TableBorder.all(color: Colors.black87, width: 1.0),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade200),
          children: headers.map((h) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Column(
                children: [
                  Text(h.$1, textAlign: TextAlign.center, style: style.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(h.$2, textAlign: TextAlign.center, style: marathiStyle.copyWith(fontSize: 9, fontWeight: FontWeight.w600)),
                  const Divider(color: Colors.black54, height: 4, thickness: 0.5),
                  Text(h.$3, textAlign: TextAlign.center, style: style.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }).toList(),
        ),
        ...rows.map((rowMap) {
          return TableRow(
            children: indices.map((idx) {
              final ctrl = rowMap[idx.toString()]!;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
                child: TextFormField(
                  controller: ctrl,
                  readOnly: widget.readOnly,
                  minLines: 1,
                  maxLines: 4,
                  textAlign: TextAlign.start,
                  style: style.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0D47A1),
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    filled: false,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  Widget _buildSmallCheckbox(String label, bool value, ValueChanged<bool?> onChanged, TextStyle style) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: widget.readOnly ? null : onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        Text(label, style: style.copyWith(fontSize: 11.5)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureRows();

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

    return FormViewScaffold(
      readOnly: widget.readOnly,
      children: [
        if (_shows(kForm3A)) _buildPage1(style, marathiStyle),
        if (_shows(kForm3A) && _shows(kForm3B)) const SizedBox(height: 24),
        if (_shows(kForm3B)) _buildPage2(style, marathiStyle),
        if (_shows(kForm3B) && _shows(kForm3C)) const SizedBox(height: 24),
        if (_shows(kForm3C)) _buildPage3(style, marathiStyle),
      ],
    );
  }
}
