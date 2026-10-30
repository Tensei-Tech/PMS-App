// lib/modules/preventive/widgets/preventive_form.dart
// Backend-Driven Dynamic Preventive & Istegasha Entry Form matching Form 1 to 5 styling.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../services/backend_case_service.dart';
import '../../../services/case_service.dart';
import '../../../services/dynamic_options_service.dart';
import '../../../services/preventive_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/common_form/pocso_voice_banner.dart';
import '../../../widgets/dynamic_form/dynamic_field_model.dart';
import '../../../widgets/voice_dictation_button.dart';

// ── Palette matching Form 1 to 5 design system ──────────────────────────────
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

const _tsLabel = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.w600,
  color: _kDark,
  letterSpacing: 0.3,
);

/// Accused entry model for Preventive Form
class PreventiveAccusedEntry {
  final TextEditingController name = TextEditingController();
  String actionType = '';
  String bondTaken = '';
  final TextEditingController bondDetails = TextEditingController();

  PreventiveAccusedEntry({String? defaultActionType, String? defaultBondTaken}) {
    actionType = defaultActionType ??
        (PreventiveService().accusedActionTypes.isNotEmpty
            ? PreventiveService().accusedActionTypes.first
            : '');
    bondTaken = defaultBondTaken ??
        (PreventiveService().yesNoOptions.isNotEmpty
            ? PreventiveService().yesNoOptions.last
            : '');
  }

  void dispose() {
    name.dispose();
    bondDetails.dispose();
  }

  void clear([String? defaultActionType, String? defaultBondTaken]) {
    name.clear();
    actionType = defaultActionType ??
        (PreventiveService().accusedActionTypes.isNotEmpty
            ? PreventiveService().accusedActionTypes.first
            : '');
    bondTaken = defaultBondTaken ??
        (PreventiveService().yesNoOptions.isNotEmpty
            ? PreventiveService().yesNoOptions.last
            : '');
    bondDetails.clear();
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name.text.trim(),
      'actionType': actionType,
      'bondTaken': bondTaken,
      'bondDetails': bondDetails.text.trim(),
    };
  }

  void fromMap(Map<String, dynamic> m) {
    name.text = m['name']?.toString() ?? '';
    actionType = m['actionType']?.toString() ??
        (PreventiveService().accusedActionTypes.isNotEmpty
            ? PreventiveService().accusedActionTypes.first
            : '');
    bondTaken = m['bondTaken']?.toString() ??
        (PreventiveService().yesNoOptions.isNotEmpty
            ? PreventiveService().yesNoOptions.last
            : '');
    bondDetails.text = m['bondDetails']?.toString() ?? '';
  }
}

class PreventiveForm extends StatefulWidget {
  final dynamic categoryId;
  final VoidCallback? onSave;
  final VoidCallback? onExportPdf;
  final bool readOnly;

  const PreventiveForm({
    super.key,
    this.categoryId,
    this.onSave,
    this.onExportPdf,
    this.readOnly = false,
  });

  @override
  State<PreventiveForm> createState() => PreventiveFormState();
}

class PreventiveFormState extends State<PreventiveForm> {
  late final ScrollController _scroll = ScrollController();
  final ValueNotifier<double> scrollProgress = ValueNotifier(0);
  String saveBarText = 'All changes unsaved';

  // ── Dynamic State & Definitions ───────────────────────────────────────────
  bool _isLoading = true;
  String? _errorMessage;
  DynamicFormDefinition? _formDef;
  Map<String, dynamic>? _pendingHydrateDoc;

  // Dynamically populated collections from backend APIs and DB master
  List<String> _crimeCategories = [];
  List<String> _caseStatuses = PreventiveService().caseStatuses;
  List<String> _preventiveActsList = [];
  List<String> _riskFlags = PreventiveService().riskFlags;
  List<String> _actionStatuses = PreventiveService().actionStatuses;
  List<String> _accusedActionTypes = PreventiveService().accusedActionTypes;
  List<String> _yesNoOptions = PreventiveService().yesNoOptions;
  Map<String, dynamic> _backendDefaults = {};
  Map<String, Map<String, dynamic>> _actsData = {};
  List<DynamicFieldDef> _templateFields = [];

  // Controllers for any additional dynamic fields from backend template
  final Map<String, TextEditingController> _dynamicFieldControllers = {};
  final Map<String, dynamic> _dynamicFieldValues = {};

  // 1. Case & Crime Reference
  final _crimeNoCtrl = TextEditingController();
  final _regDateCtrl = TextEditingController();
  String _crimeCategory = '';
  final _customCrimeCategoryCtrl = TextEditingController();
  late String _caseStatus = _caseStatuses.isNotEmpty ? _caseStatuses.first : '';

  // 2. Sections & Acts
  String _selectedAct = '';
  final List<String> _selectedSections = [];
  final _sectionSearchCtrl = TextEditingController();
  final _otherSectionsCtrl = TextEditingController();

  Map<String, Map<String, dynamic>> get _activeActsData =>
      _actsData.isNotEmpty ? _actsData : BackendCaseService.cachedActData;
  List<String> get _activePreventiveSectionActs => _preventiveActsList;

  // 3. Accused list
  final List<PreventiveAccusedEntry> _accusedEntries = [
    PreventiveAccusedEntry()
  ];

  // 4. Preventive / Istegasha Details
  String _hasPreventiveNo = 'No';
  String _preventiveSectionAct = '';
  final _customPreventiveSectionActCtrl = TextEditingController();
  final _preventiveNoCtrl = TextEditingController();
  final _preventiveDateCtrl = TextEditingController();
  final _outwardNoCtrl = TextEditingController();
  final _ioNameCtrl = TextEditingController();

  // 5. Risk Flag & Action Status
  late String _riskFlag = _riskFlags.isNotEmpty ? _riskFlags.first : '';
  late String _preventiveActionStatus =
      _actionStatuses.isNotEmpty ? _actionStatuses.first : '';
  final _remarksCtrl = TextEditingController();

  // Active Voice Dictation State
  String? _activeVoiceFieldLabel = 'Crime No. / FIR No. / NC no. *';
  TextEditingController? _activeVoiceController;
  String? _activeVoiceSectionName = 'Case & Crime Reference';

  void _setActiveVoiceField(String label, TextEditingController ctrl,
      {String? section}) {
    if (_activeVoiceController != ctrl || _activeVoiceFieldLabel != label) {
      setState(() {
        _activeVoiceFieldLabel = label;
        _activeVoiceController = ctrl;
        if (section != null) _activeVoiceSectionName = section;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _activeVoiceController = _crimeNoCtrl;
    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      scrollProgress.value =
          max > 0 ? (_scroll.offset / max).clamp(0.0, 1.0) : 0;
    });

    _loadFormDefinition();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _crimeNoCtrl.dispose();
    _regDateCtrl.dispose();
    _customCrimeCategoryCtrl.dispose();
    _sectionSearchCtrl.dispose();
    _otherSectionsCtrl.dispose();
    for (final a in _accusedEntries) {
      a.dispose();
    }
    _customPreventiveSectionActCtrl.dispose();
    _preventiveNoCtrl.dispose();
    _preventiveDateCtrl.dispose();
    _outwardNoCtrl.dispose();
    _ioNameCtrl.dispose();
    _remarksCtrl.dispose();
    for (final c in _dynamicFieldControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Dynamic Definition & Options Loader ─────────────────────────────────────
  Future<void> _loadFormDefinition({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final catId = widget.categoryId ?? 'Preventive';

      // 1. Fetch form definition from backend API (GET /api/categories/{id}/form-definition/)
      final def = await CaseService().fetchFormDefinition(
        catId,
        forceRefresh: forceRefresh,
      );

      // 2. Fetch preventive configuration from dedicated endpoint /api/preventive/config/
      final prevConfig = await PreventiveService().fetchConfig(forceRefresh: forceRefresh);

      // 3. Fetch master categories from backend API (GET /api/categories/)
      final allCategories = await CaseService().fetchAllCategories(
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;

      if (def != null) {
        final formDef = DynamicFormDefinition.fromJson(def);
        _formDef = formDef;
        _templateFields = formDef.fields;

        // Dynamic statutory sections from database (Act & ActSection tables)
        if (formDef.actsSections.isNotEmpty) {
          _actsData = formDef.actsSections.map(
            (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
          );
        } else {
          final acts = await CaseService().fetchActs();
          final actSections = await CaseService().fetchActSections();
          final actsMap = <String, Map<String, dynamic>>{};
          for (final a in acts) {
            final code = (a['code'] ?? a['act_name'] ?? '').toString().trim();
            if (code.isNotEmpty) {
              final secs = actSections
                  .where((s) => s['act_id'] == a['id'] || s['act_code'] == code)
                  .map((s) => {
                        'val': s['section_number']?.toString() ?? '',
                        'label': s['title']?.toString() ??
                            s['section_number']?.toString() ??
                            '',
                      })
                  .toList();
              actsMap[code] = {
                'label': a['act_name']?.toString() ?? code,
                'sections': secs,
              };
            }
          }
          if (actsMap.isNotEmpty) _actsData = actsMap;
        }

        // Dynamic legal provisions from OptionValue (preventive_action_types)
        if (formDef.preventiveItems.isNotEmpty) {
          _preventiveActsList = List<String>.from(formDef.preventiveItems);
        } else {
          final prevOpts = await DynamicOptionsService().fetchOptions(
            '/api/options/preventive_action_types/',
            forceRefresh: forceRefresh,
          );
          if (prevOpts.isNotEmpty) {
            _preventiveActsList = List<String>.from(prevOpts);
          }
        }
        if (!_preventiveActsList.contains('Other')) {
          _preventiveActsList.add('Other');
        }

        // Dynamic Crime Categories from backend database categories
        if (allCategories.isNotEmpty) {
          final catNames = allCategories
              .map((c) =>
                  (c['category_name'] ?? c['name'] ?? '').toString().trim())
              .where((n) => n.isNotEmpty && n != 'Preventive')
              .toSet()
              .toList();
          if (catNames.isNotEmpty) {
            _crimeCategories = catNames;
          }
        }
        if (!_crimeCategories.contains('Other')) {
          _crimeCategories.add('Other');
        }

        // Dynamic dropdown options from backend config / OptionValue
        _caseStatuses = formDef.caseStatuses.isNotEmpty
            ? formDef.caseStatuses
            : PreventiveService().caseStatuses;
        _riskFlags = formDef.riskFlags.isNotEmpty
            ? formDef.riskFlags
            : PreventiveService().riskFlags;
        _actionStatuses = formDef.actionStatuses.isNotEmpty
            ? formDef.actionStatuses
            : PreventiveService().actionStatuses;
        _accusedActionTypes = formDef.accusedActionTypes.isNotEmpty
            ? formDef.accusedActionTypes
            : PreventiveService().accusedActionTypes;
        _yesNoOptions = formDef.yesNoOptions.isNotEmpty
            ? formDef.yesNoOptions
            : PreventiveService().yesNoOptions;

        final defs = Map<String, dynamic>.from(formDef.defaults);
        if (prevConfig['defaults'] is Map) {
          defs.addAll(Map<String, dynamic>.from(prevConfig['defaults'] as Map));
        }
        _backendDefaults = defs;

        // Apply backend defaults if not editing / hydrating
        if (_crimeCategory.isEmpty) {
          final defCat = defs['crime_category']?.toString() ?? '';
          _crimeCategory = defCat.isNotEmpty && _crimeCategories.contains(defCat)
              ? defCat
              : (_crimeCategories.isNotEmpty ? _crimeCategories.first : '');
        }
        if (_caseStatus.isEmpty) {
          final defStatus = defs['case_status']?.toString() ?? '';
          _caseStatus = defStatus.isNotEmpty && _caseStatuses.contains(defStatus)
              ? defStatus
              : (_caseStatuses.isNotEmpty ? _caseStatuses.first : '');
        }
        if (_selectedAct.isEmpty) {
          final defAct = defs['act']?.toString() ?? '';
          _selectedAct = defAct.isNotEmpty && _actsData.containsKey(defAct)
              ? defAct
              : (_actsData.isNotEmpty ? _actsData.keys.first : '');
        }
        if (_preventiveSectionAct.isEmpty) {
          final defPsa = defs['section']?.toString() ?? '';
          _preventiveSectionAct = defPsa.isNotEmpty && _preventiveActsList.contains(defPsa)
              ? defPsa
              : (_preventiveActsList.isNotEmpty ? _preventiveActsList.first : '');
        }
        if (_riskFlag.isEmpty) {
          final defRisk = defs['risk_flag']?.toString() ?? '';
          _riskFlag = defRisk.isNotEmpty && _riskFlags.contains(defRisk)
              ? defRisk
              : (_riskFlags.isNotEmpty ? _riskFlags.first : '');
        }
        if (_preventiveActionStatus.isEmpty) {
          final defActionStatus = defs['action_status']?.toString() ?? '';
          _preventiveActionStatus = defActionStatus.isNotEmpty && _actionStatuses.contains(defActionStatus)
              ? defActionStatus
              : (_actionStatuses.isNotEmpty ? _actionStatuses.first : '');
        }
        _hasPreventiveNo = defs['has_preventive_no']?.toString() ?? _hasPreventiveNo;

        // Date defaults: only set today's date if backend defaults explicitly declare current_date
        if (defs['date_default'] == 'current_date') {
          final now = DateTime.now();
          if (_regDateCtrl.text.isEmpty) {
            _regDateCtrl.text = DateFormat('dd/MM/yyyy').format(now);
          }
          if (_preventiveDateCtrl.text.isEmpty && _hasPreventiveNo == 'Yes') {
            _preventiveDateCtrl.text = DateFormat('dd/MM/yyyy').format(now);
          }
        }

        // Dynamic field controllers & options from backend template
        for (final f in formDef.fields) {
          if (f.fieldKey == 'preventive_action_status' && f.options.isNotEmpty) {
            _actionStatuses = f.options;
          }
          if (f.fieldKey == 'has_preventive_no' && f.options.isNotEmpty) {
            _yesNoOptions = f.options;
          }
          _dynamicFieldControllers.putIfAbsent(
              f.fieldKey, () => TextEditingController());
          if (f.fieldType == 'checkbox') {
            _dynamicFieldValues.putIfAbsent(f.fieldKey, () => false);
          }
        }

        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });

        // Hydrate pending record if available
        if (_pendingHydrateDoc != null) {
          hydrateFromDocumentMap(_pendingHydrateDoc!);
          _pendingHydrateDoc = null;
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Failed to retrieve Preventive form definition from backend database.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading Preventive form definition: $e';
      });
    }
  }

  // ── Accused list helpers ───────────────────────────────────────────────────
  void _addAccused() {
    if (widget.readOnly) return;
    setState(() {
      _accusedEntries.add(PreventiveAccusedEntry());
      _markUnsaved();
    });
  }

  void _removeAccused(int index) {
    if (widget.readOnly || _accusedEntries.length <= 1) return;
    setState(() {
      final removed = _accusedEntries.removeAt(index);
      removed.dispose();
      _markUnsaved();
    });
  }

  void _markUnsaved() {
    if (saveBarText != 'All changes unsaved') {
      setState(() => saveBarText = 'All changes unsaved');
    }
  }

  // ── Public Data Serialization & Hydration ──────────────────────────────────
  Map<String, dynamic> buildDocumentMap() {
    final effectiveCategory = _crimeCategory == 'Other' &&
            _customCrimeCategoryCtrl.text.trim().isNotEmpty
        ? _customCrimeCategoryCtrl.text.trim()
        : _crimeCategory;

    final effectivePrevSectionAct = _preventiveSectionAct == 'Other' &&
            _customPreventiveSectionActCtrl.text.trim().isNotEmpty
        ? _customPreventiveSectionActCtrl.text.trim()
        : _preventiveSectionAct;

    final out = <String, dynamic>{
      'caseRef': {
        'crimeNo': _crimeNoCtrl.text.trim(),
        'regDate': _regDateCtrl.text.trim(),
        'crimeCategory': effectiveCategory,
        'caseStatus': _caseStatus,
      },
      'sections': {
        'act': _selectedAct,
        'selectedSections': List<String>.from(_selectedSections),
        'otherSections': _otherSectionsCtrl.text.trim(),
      },
      'accusedList': _accusedEntries.map((a) => a.toMap()).toList(),
      'istegasha': {
        'hasPreventiveNo': _hasPreventiveNo,
        'preventiveSectionAct': effectivePrevSectionAct,
        'preventiveNo': _preventiveNoCtrl.text.trim(),
        'preventiveDate': _preventiveDateCtrl.text.trim(),
        'outwardNo': _outwardNoCtrl.text.trim(),
        'ioName': _ioNameCtrl.text.trim(),
      },
      'riskAndStatus': {
        'riskFlag': _riskFlag,
        'actionStatus': _preventiveActionStatus,
        'remarks': _remarksCtrl.text.trim(),
      },
      // Backend template field direct mappings
      'has_preventive_no': _hasPreventiveNo,
      'preventive_no': _preventiveNoCtrl.text.trim(),
      'preventive_date': _preventiveDateCtrl.text.trim(),
      'preventive_action_status': _preventiveActionStatus,
      // Convenience root fields for instant list indexing & views
      'crimeNo': _crimeNoCtrl.text.trim(),
      'caseNumber': _crimeNoCtrl.text.trim(),
      'preventiveSectionAct': effectivePrevSectionAct,
      'preventiveSecAct': effectivePrevSectionAct,
      'preventiveAct': effectivePrevSectionAct,
      'act': effectivePrevSectionAct,
      'accusedNames': _accusedEntries
          .map((a) => a.name.text.trim())
          .where((n) => n.isNotEmpty)
          .join(', '),
      'ioName': _ioNameCtrl.text.trim(),
      'assignedOfficer': _ioNameCtrl.text.trim(),
      'priority': _riskFlag,
      'status': _caseStatus,
      'actionStatus': _preventiveActionStatus,
    };

    // Serialize any dynamic field controllers
    for (final entry in _dynamicFieldControllers.entries) {
      final val = entry.value.text.trim();
      if (val.isNotEmpty) {
        out[entry.key] = val;
      }
    }
    for (final entry in _dynamicFieldValues.entries) {
      out[entry.key] = entry.value;
    }

    return out;
  }

  void hydrateFromDocumentMap(Map<String, dynamic> doc) {
    if (_isLoading) {
      _pendingHydrateDoc = doc;
    }

    final formMap = (doc['preventiveForm'] is Map<String, dynamic>)
        ? doc['preventiveForm'] as Map<String, dynamic>
        : (doc['preventiveForm'] is Map)
            ? Map<String, dynamic>.from(doc['preventiveForm'] as Map)
            : doc;

    final caseRef = formMap['caseRef'] as Map<String, dynamic>? ??
        (formMap['caseRef'] is Map
            ? Map<String, dynamic>.from(formMap['caseRef'] as Map)
            : {});
    final sections = formMap['sections'] as Map<String, dynamic>? ??
        (formMap['sections'] is Map
            ? Map<String, dynamic>.from(formMap['sections'] as Map)
            : {});
    final accusedList = formMap['accusedList'] as List<dynamic>? ?? [];
    final istegasha = formMap['istegasha'] as Map<String, dynamic>? ??
        (formMap['istegasha'] is Map
            ? Map<String, dynamic>.from(formMap['istegasha'] as Map)
            : {});
    final riskAndStatus = formMap['riskAndStatus'] as Map<String, dynamic>? ??
        (formMap['riskAndStatus'] is Map
            ? Map<String, dynamic>.from(formMap['riskAndStatus'] as Map)
            : {});

    setState(() {
      _crimeNoCtrl.text = caseRef['crimeNo']?.toString() ??
          doc['crimeNo']?.toString() ??
          doc['caseNumber']?.toString() ??
          doc['case_number']?.toString() ??
          '';
      _regDateCtrl.text = caseRef['regDate']?.toString() ?? '';

      final cat = caseRef['crimeCategory']?.toString() ??
          doc['crimeCategory']?.toString() ??
          doc['subCategory']?.toString() ??
          '';
      if (cat.isNotEmpty) {
        if (_crimeCategories.contains(cat)) {
          _crimeCategory = cat;
          _customCrimeCategoryCtrl.clear();
        } else if (_crimeCategories.isEmpty) {
          _crimeCategory = cat;
          _customCrimeCategoryCtrl.clear();
        } else {
          _crimeCategory = 'Other';
          _customCrimeCategoryCtrl.text = cat;
        }
      } else if (_crimeCategories.isNotEmpty) {
        _crimeCategory = _crimeCategories.first;
        _customCrimeCategoryCtrl.clear();
      }

      final st =
          caseRef['caseStatus']?.toString() ?? doc['status']?.toString() ?? '';
      if (st.isNotEmpty) {
        _caseStatus = st;
      } else if (_caseStatuses.isNotEmpty) {
        _caseStatus = _caseStatuses.first;
      }

      final psa = istegasha['preventiveSectionAct']?.toString() ??
          formMap['preventiveSectionAct']?.toString() ??
          formMap['preventiveSecAct']?.toString() ??
          doc['preventiveSectionAct']?.toString() ??
          doc['preventiveSecAct']?.toString() ??
          doc['preventiveAct']?.toString() ??
          istegasha['act']?.toString() ??
          '';
      if (psa.isNotEmpty) {
        if (_preventiveActsList.contains(psa)) {
          _preventiveSectionAct = psa;
          _customPreventiveSectionActCtrl.clear();
        } else {
          _preventiveSectionAct = 'Other';
          _customPreventiveSectionActCtrl.text = psa;
        }
      } else if (_preventiveActsList.isNotEmpty) {
        _preventiveSectionAct = _preventiveActsList.first;
        _customPreventiveSectionActCtrl.clear();
      }

      _selectedAct = sections['act']?.toString() ??
          (_actsData.isNotEmpty ? _actsData.keys.first : '');
      _selectedSections.clear();
      if (sections['selectedSections'] is List) {
        _selectedSections.addAll(
          (sections['selectedSections'] as List).map((e) => e.toString()),
        );
      }
      _otherSectionsCtrl.text = sections['otherSections']?.toString() ?? '';

      for (final a in _accusedEntries) {
        a.dispose();
      }
      _accusedEntries.clear();
      if (accusedList.isNotEmpty) {
        for (final item in accusedList) {
          if (item is Map) {
            final entry = PreventiveAccusedEntry();
            entry.fromMap(Map<String, dynamic>.from(item));
            _accusedEntries.add(entry);
          }
        }
      }
      if (_accusedEntries.isEmpty) {
        final legacyAccused =
            doc['accused']?.toString() ?? doc['accusedNames']?.toString() ?? '';
        final entry = PreventiveAccusedEntry();
        entry.name.text = legacyAccused;
        _accusedEntries.add(entry);
      }

      _hasPreventiveNo = istegasha['hasPreventiveNo']?.toString() ??
          doc['has_preventive_no']?.toString() ??
          _backendDefaults['has_preventive_no']?.toString() ??
          (_yesNoOptions.isNotEmpty ? _yesNoOptions.first : 'No');
      _preventiveNoCtrl.text = istegasha['preventiveNo']?.toString() ??
          doc['preventive_no']?.toString() ??
          doc['preventiveNo']?.toString() ??
          '';
      _preventiveDateCtrl.text = istegasha['preventiveDate']?.toString() ??
          doc['preventive_date']?.toString() ??
          '';
      _outwardNoCtrl.text = istegasha['outwardNo']?.toString() ?? '';
      _ioNameCtrl.text = istegasha['ioName']?.toString() ??
          doc['assignedOfficer']?.toString() ??
          doc['assigned_officer']?.toString() ??
          '';

      final rf = riskAndStatus['riskFlag']?.toString() ??
          doc['priority']?.toString() ??
          '';
      if (rf.isNotEmpty) {
        if (_riskFlags.contains(rf)) {
          _riskFlag = rf;
        } else {
          final match = _riskFlags.firstWhere(
            (opt) =>
                opt.toLowerCase().contains(rf.toLowerCase()) ||
                rf.toLowerCase().contains(opt.toLowerCase()),
            orElse: () => rf,
          );
          _riskFlag = match;
        }
      } else if (_riskFlags.isNotEmpty) {
        _riskFlag = _riskFlags.first;
      }

      final actSt = riskAndStatus['actionStatus']?.toString() ??
          doc['preventive_action_status']?.toString() ??
          doc['actionStatus']?.toString() ??
          '';
      if (actSt.isNotEmpty) {
        if (_actionStatuses.contains(actSt)) {
          _preventiveActionStatus = actSt;
        } else {
          final match = _actionStatuses.firstWhere(
            (opt) =>
                opt.toLowerCase().contains(actSt.toLowerCase()) ||
                actSt.toLowerCase().contains(opt.toLowerCase()),
            orElse: () => actSt,
          );
          _preventiveActionStatus = match;
        }
      } else if (_actionStatuses.isNotEmpty) {
        _preventiveActionStatus = _actionStatuses.first;
      }

      _remarksCtrl.text = riskAndStatus['remarks']?.toString() ??
          doc['description']?.toString() ??
          '';

      // Hydrate dynamic field controllers
      for (final f in _templateFields) {
        final val = doc[f.fieldKey] ?? formMap[f.fieldKey];
        if (val != null) {
          if (_dynamicFieldControllers.containsKey(f.fieldKey)) {
            _dynamicFieldControllers[f.fieldKey]!.text = val.toString();
          }
          if (_dynamicFieldValues.containsKey(f.fieldKey)) {
            _dynamicFieldValues[f.fieldKey] = val;
          }
        }
      }

      saveBarText = 'Saved';
    });
  }

  void clearForm() {
    if (widget.readOnly) return;
    setState(() {
      _crimeNoCtrl.clear();
      if (_backendDefaults['date_default'] == 'current_date') {
        _regDateCtrl.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
      } else {
        _regDateCtrl.clear();
      }
      final defCat = _backendDefaults['crime_category']?.toString() ?? '';
      _crimeCategory = defCat.isNotEmpty && _crimeCategories.contains(defCat)
          ? defCat
          : (_crimeCategories.isNotEmpty ? _crimeCategories.first : '');
      _customCrimeCategoryCtrl.clear();

      final defStatus = _backendDefaults['case_status']?.toString() ?? '';
      _caseStatus = defStatus.isNotEmpty && _caseStatuses.contains(defStatus)
          ? defStatus
          : (_caseStatuses.isNotEmpty ? _caseStatuses.first : '');

      final defPsa = _backendDefaults['section']?.toString() ?? '';
      _preventiveSectionAct = defPsa.isNotEmpty && _preventiveActsList.contains(defPsa)
          ? defPsa
          : (_preventiveActsList.isNotEmpty ? _preventiveActsList.first : '');
      _customPreventiveSectionActCtrl.clear();

      final defAct = _backendDefaults['act']?.toString() ?? '';
      _selectedAct = defAct.isNotEmpty && _actsData.containsKey(defAct)
          ? defAct
          : (_actsData.isNotEmpty ? _actsData.keys.first : '');
      _selectedSections.clear();
      _sectionSearchCtrl.clear();
      _otherSectionsCtrl.clear();

      for (final a in _accusedEntries) {
        a.dispose();
      }
      _accusedEntries.clear();
      _accusedEntries.add(PreventiveAccusedEntry());

      _hasPreventiveNo = _backendDefaults['has_preventive_no']?.toString() ??
          (_yesNoOptions.isNotEmpty ? _yesNoOptions.last : 'No');
      _preventiveNoCtrl.clear();
      if (_hasPreventiveNo == 'Yes' && _backendDefaults['date_default'] == 'current_date') {
        _preventiveDateCtrl.text =
            DateFormat('dd/MM/yyyy').format(DateTime.now());
      } else {
        _preventiveDateCtrl.clear();
      }
      _outwardNoCtrl.clear();
      _ioNameCtrl.clear();

      final defRisk = _backendDefaults['risk_flag']?.toString() ?? '';
      _riskFlag = defRisk.isNotEmpty && _riskFlags.contains(defRisk)
          ? defRisk
          : (_riskFlags.isNotEmpty ? _riskFlags.first : '');

      final defAction = _backendDefaults['action_status']?.toString() ?? '';
      _preventiveActionStatus = defAction.isNotEmpty && _actionStatuses.contains(defAction)
          ? defAction
          : (_actionStatuses.isNotEmpty ? _actionStatuses.first : '');
      _remarksCtrl.clear();
      for (final c in _dynamicFieldControllers.values) {
        c.clear();
      }
      saveBarText = 'Form cleared';
    });
  }

  // ── Date Picker Helper ─────────────────────────────────────────────────────
  Future<void> _pickDate(TextEditingController ctrl) async {
    if (widget.readOnly) return;
    DateTime initial = DateTime.now();
    try {
      if (ctrl.text.trim().isNotEmpty) {
        final parts = ctrl.text.trim().split('/');
        if (parts.length == 3) {
          initial = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1980),
      lastDate: DateTime(2040),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _kTeal,
              onPrimary: Colors.white,
              onSurface: _kDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        ctrl.text = DateFormat('dd/MM/yyyy').format(picked);
        _markUnsaved();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: _kPageBg,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_kTeal),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading Preventive form definition from server...',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kMid,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Fetching statutory sections, legal provisions, and template configuration',
                style: GoogleFonts.inter(fontSize: 11, color: _kSec),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        color: _kPageBg,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded,
                      size: 48, color: _kRed),
                  const SizedBox(height: 12),
                  Text(
                    'Form Definition Load Failed',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 12, color: _kSec),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _loadFormDefinition(forceRefresh: true),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_formDef == null) {
      return Container(
        color: _kPageBg,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 44, color: _kSec),
                  const SizedBox(height: 12),
                  Text(
                    'No Form Definition Available',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The server returned an empty form definition for the Preventive module.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 12, color: _kSec),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () => _loadFormDefinition(forceRefresh: true),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        PocsoVoiceBanner(
          activeFieldLabel: _activeVoiceFieldLabel,
          activeController: _activeVoiceController,
          activeSectionName: _activeVoiceSectionName,
        ),
        // Top Progress Bar
        ValueListenableBuilder<double>(
          valueListenable: scrollProgress,
          builder: (_, p, __) => LinearProgressIndicator(
            value: p,
            minHeight: 3,
            backgroundColor: _kBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(_kTeal),
          ),
        ),

        // Sub-Header Bar (Save state + Quick Action buttons)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  saveBarText,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _kSec,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                if (!widget.readOnly) ...[
                  OutlinedButton.icon(
                    onPressed: clearForm,
                    icon: const Icon(Icons.refresh_rounded,
                        size: 14, color: _kSec),
                    label: Text('Clear',
                        style: GoogleFonts.inter(fontSize: 12, color: _kSec)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _kBorder),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() => saveBarText = 'Draft saved locally');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Draft saved locally'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.save_as_rounded,
                        size: 14, color: _kTeal),
                    label: Text('Save Draft',
                        style: GoogleFonts.inter(fontSize: 12, color: _kTeal)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _kTeal),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                OutlinedButton.icon(
                  onPressed: widget.onExportPdf,
                  icon: const Icon(Icons.picture_as_pdf_rounded,
                      size: 14, color: _kTeal),
                  label: Text('Generate Preventive Form PDF',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _kTeal,
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _kTeal, width: 1.2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
        ),

        const Divider(height: 1, color: _kBorder),

        // Scrollable Form Content
        Expanded(
          child: Container(
            color: _kPageBg,
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section 1: Case & Crime Reference
                      _buildCard(
                        secNum: '1',
                        title: _formDef?.sectionTitles['case_ref'] ?? 'Case & Crime Reference',
                        marathiTitle: 'गुन्हा व खटला संदर्भ',
                        icon: Icons.folder_copy_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildTextField(
                                    label: 'Crime No. / FIR No. / NC no. *',
                                    hint: 'e.g. 142/2026 or NC 88/2026',
                                    controller: _crimeNoCtrl,
                                    required: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: _buildDateField(
                                    label: 'Arrest Date (अटक तारीख) *',
                                    controller: _regDateCtrl,
                                    onTap: () => _pickDate(_regDateCtrl),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildDropdownField(
                                    label: 'Crime Category (गुन्ह्याचा प्रकार) *',
                                    value: _crimeCategories.contains(_crimeCategory)
                                        ? _crimeCategory
                                        : (_crimeCategories.isNotEmpty
                                            ? _crimeCategories.first
                                            : ''),
                                    items: _crimeCategories,
                                    required: true,
                                    onChanged: (val) {
                                      setState(() {
                                        _crimeCategory = val ??
                                            (_crimeCategories.isNotEmpty
                                                ? _crimeCategories.first
                                                : '');
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Case Status (खटल्याची स्थिती)'),
                                      const SizedBox(height: 5),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: _caseStatuses.map((st) {
                                          final isSelected = _caseStatus == st;
                                          return ChoiceChip(
                                            label: Text(st),
                                            selected: isSelected,
                                            onSelected: widget.readOnly
                                                ? null
                                                : (val) {
                                                    if (val) {
                                                      setState(() {
                                                        _caseStatus = st;
                                                        _markUnsaved();
                                                      });
                                                    }
                                                  },
                                            selectedColor:
                                                const Color(0xFFE0E7FF),
                                            backgroundColor: _kInputBg,
                                            side: BorderSide(
                                              color: isSelected
                                                  ? const Color(0xFF4F46E5)
                                                  : _kBorder,
                                              width: isSelected ? 1.5 : 1,
                                            ),
                                            labelStyle: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? const Color(0xFF4F46E5)
                                                  : _kDark,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_crimeCategory == 'Other') ...[
                              const SizedBox(height: 10),
                              _buildTextField(
                                label: 'Specify Other Category',
                                hint: 'Enter crime category',
                                controller: _customCrimeCategoryCtrl,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Section 2: Sections & Acts Filter
                      _buildCard(
                        secNum: '2',
                        title: 'Sections & Acts (filter by section)',
                        marathiTitle: 'कलमे व कायदे (BNS / इतर कायदे)',
                        icon: Icons.gavel_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Act Selector Chips from backend DB
                            _buildLabel('Select Act / कायदे निवडा'),
                            const SizedBox(height: 6),
                            if (_activeActsData.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline,
                                        size: 16, color: _kRed),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Error: Failed to load acts and sections from server.',
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: _kRed,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              )
                            else
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _activeActsData.keys.map((actKey) {
                                    final actInfo = _activeActsData[actKey];
                                    final label = actInfo?['label'] ?? actKey;
                                    final isSelected = _selectedAct == actKey;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: FilterChip(
                                        label: Text(label),
                                        selected: isSelected,
                                        onSelected: widget.readOnly
                                            ? null
                                            : (val) {
                                                if (val) {
                                                  setState(() {
                                                    _selectedAct = actKey;
                                                    _markUnsaved();
                                                  });
                                                }
                                              },
                                        selectedColor:
                                            _kTeal.withValues(alpha: 0.15),
                                        backgroundColor: _kInputBg,
                                        side: BorderSide(
                                          color: isSelected ? _kTeal : _kBorder,
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                        labelStyle: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected ? _kTeal : _kDark,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            const SizedBox(height: 12),

                            // Filter / Search section
                            _buildTextField(
                              label: 'Search Sections in $_selectedAct',
                              hint:
                                  'Type section number or name to filter (e.g. 100, 303, hurt)...',
                              controller: _sectionSearchCtrl,
                              onChanged: (_) => setState(() {}),
                              prefixIcon: Icons.search_rounded,
                            ),
                            const SizedBox(height: 10),

                            // Filtered Sections Grid / Chips
                            _buildSectionPickerChips(),
                            const SizedBox(height: 12),

                            // Selected Sections Badges
                            if (_selectedSections.isNotEmpty) ...[
                              _buildLabel('Selected Sections:'),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _selectedSections.map((sec) {
                                  return Chip(
                                    label: Text(
                                      '$_selectedAct $sec',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _kDark,
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFFEEF2FF),
                                    side: const BorderSide(
                                        color: Color(0xFFC7D2FE)),
                                    deleteIcon: widget.readOnly
                                        ? null
                                        : const Icon(Icons.close_rounded,
                                            size: 14, color: _kRed),
                                    onDeleted: widget.readOnly
                                        ? null
                                        : () {
                                            setState(() {
                                              _selectedSections.remove(sec);
                                              _markUnsaved();
                                            });
                                          },
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Other Acts / Custom Sections textfield
                            _buildTextField(
                              label: 'Other Acts / Custom Sections (इतर कलमे)',
                              hint:
                                  'e.g. Sec 110/117 BNSS, Sec 107 CrPC, Sec 56/57 MP Act',
                              controller: _otherSectionsCtrl,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Section 3: Accused & Action Details
                      _buildCard(
                        secNum: '3',
                        title: _formDef?.sectionTitles['accused'] ?? 'Accused & Preventive Action Details',
                        marathiTitle: 'आरोपी व प्रतिबंधक कारवाई तपशील',
                        icon: Icons.people_alt_rounded,
                        trailing: widget.readOnly
                            ? null
                            : ElevatedButton.icon(
                                onPressed: _addAccused,
                                icon: const Icon(Icons.person_add_alt_1_rounded,
                                    size: 14, color: Colors.white),
                                label: Text(
                                  '+ Add Accused',
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _kTeal,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6)),
                                ),
                              ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < _accusedEntries.length; i++)
                              _buildAccusedRowCard(i, _accusedEntries[i]),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Section 4: Preventive & Istegasha Details
                      _buildCard(
                        secNum: '4',
                        title: _formDef?.sectionTitles['istegasha'] ?? 'Preventive & Istegasha Details',
                        marathiTitle: 'प्रतिबंधक / इस्तेगाशा तपशील',
                        icon: Icons.shield_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: _buildDropdownField(
                                    label:
                                        'Preventive Section Act (प्रतिबंधक कलम / कायदा) *',
                                    value: _activePreventiveSectionActs
                                            .contains(_preventiveSectionAct)
                                        ? _preventiveSectionAct
                                        : (_activePreventiveSectionActs
                                                .isNotEmpty
                                            ? _activePreventiveSectionActs.first
                                            : ''),
                                    items: _activePreventiveSectionActs,
                                    required: true,
                                    onChanged: (val) {
                                      setState(() {
                                        _preventiveSectionAct = val ??
                                            (_activePreventiveSectionActs
                                                    .isNotEmpty
                                                ? _activePreventiveSectionActs
                                                    .first
                                                : '');
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: _buildDropdownField(
                                    label: 'Has Prev No.? *',
                                    value: _hasPreventiveNo,
                                    items: _yesNoOptions,
                                    required: true,
                                    onChanged: (val) {
                                      setState(() {
                                        _hasPreventiveNo = val ??
                                            _backendDefaults['has_preventive_no']?.toString() ??
                                            (_yesNoOptions.isNotEmpty ? _yesNoOptions.first : 'No');
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 4,
                                  child: _buildTextField(
                                    label: 'Preventive No. / इस्तेगाशा नंबर *',
                                    hint: 'e.g. IST/04/2026 or Prev No. 12',
                                    controller: _preventiveNoCtrl,
                                    required: _hasPreventiveNo == 'Yes',
                                  ),
                                ),
                              ],
                            ),
                            if (_preventiveSectionAct == 'Other') ...[
                              const SizedBox(height: 12),
                              _buildTextField(
                                label:
                                    'Specify Preventive Section Act (इतर प्रतिबंधक कलम / कायदा) *',
                                hint: 'Enter custom section act e.g. 107 CrPC',
                                controller: _customPreventiveSectionActCtrl,
                                required: true,
                              ),
                            ],
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildDateField(
                                    label:
                                        'Date of Preventive (प्रतिबंधक तारीख) *',
                                    controller: _preventiveDateCtrl,
                                    onTap: () => _pickDate(_preventiveDateCtrl),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    label: 'Outward Number (जावक क्रमांक)',
                                    hint: 'e.g. OW/PS/452/2026',
                                    controller: _outwardNoCtrl,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              label: 'Investigating Officer (IO) / अमलदार',
                              hint: 'e.g. PSI Patil / ASI Deshmukh',
                              controller: _ioNameCtrl,
                              suffix: VoiceDictationButton(
                                controller: _ioNameCtrl,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Section 5: Risk Flag & Action Status
                      _buildCard(
                        secNum: '5',
                        title: _formDef?.sectionTitles['risk_status'] ?? 'Risk Flag & Preventive Action Status',
                        marathiTitle: 'जोखीम ध्वज व कारवाई स्थिती',
                        icon: Icons.warning_amber_rounded,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Dynamic Risk Flag Chips from backend
                            _buildLabel('Risk Flag (जोखीम वर्ग)'),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: _riskFlags.map((flag) {
                                final isSelected = _riskFlag == flag;
                                final isHigh = flag.contains('High');
                                final isSensitive = flag.contains('Sensitive');

                                Color activeBg = _kTeal.withValues(alpha: 0.12);
                                Color activeBorder = _kTeal;
                                Color activeText = _kTeal;

                                if (isHigh) {
                                  activeBg = const Color(0xFFFEE2E2);
                                  activeBorder = _kRed;
                                  activeText = _kRed;
                                } else if (isSensitive) {
                                  activeBg = const Color(0xFFFEF3C7);
                                  activeBorder = _kAmber;
                                  activeText = const Color(0xFFD97706);
                                }

                                return ChoiceChip(
                                  label: Text(flag),
                                  selected: isSelected,
                                  onSelected: widget.readOnly
                                      ? null
                                      : (val) {
                                          if (val) {
                                            setState(() {
                                              _riskFlag = flag;
                                              _markUnsaved();
                                            });
                                          }
                                        },
                                  selectedColor: activeBg,
                                  backgroundColor: _kInputBg,
                                  side: BorderSide(
                                    color: isSelected ? activeBorder : _kBorder,
                                    width: isSelected ? 1.8 : 1,
                                  ),
                                  labelStyle: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected ? activeText : _kDark,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),

                            // Dynamic Action Status Options from backend
                            _buildLabel(
                                'Preventive Action Status (कारवाई स्थिती)'),
                            const SizedBox(height: 6),
                            Column(
                              children: _actionStatuses.map((actionSt) {
                                final isSelected =
                                    _preventiveActionStatus == actionSt;
                                final isCompleted =
                                    actionSt.contains('Completed');
                                final isPartial =
                                    actionSt.contains('Partially');
                                final isNoAction =
                                    actionSt.contains('No Preventive');

                                Color borderColor = _kBorder;
                                Color bg = _kInputBg;
                                if (isSelected) {
                                  if (isCompleted) {
                                    borderColor = _kGreen;
                                    bg = const Color(0xFFECFDF5);
                                  } else if (isPartial) {
                                    borderColor = _kAmber;
                                    bg = const Color(0xFFFFFBEB);
                                  } else if (isNoAction) {
                                    borderColor = _kRed;
                                    bg = const Color(0xFFFEF2F2);
                                  }
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: InkWell(
                                    onTap: widget.readOnly
                                        ? null
                                        : () {
                                            setState(() {
                                              _preventiveActionStatus =
                                                  actionSt;
                                              _markUnsaved();
                                            });
                                          },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: bg,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border(
                                          top: BorderSide(
                                              color: borderColor,
                                              width: isSelected ? 1.5 : 1),
                                          bottom: BorderSide(
                                              color: borderColor,
                                              width: isSelected ? 1.5 : 1),
                                          left: BorderSide(
                                              color: borderColor,
                                              width: isSelected ? 3.5 : 1),
                                          right: BorderSide(
                                              color: borderColor,
                                              width: isSelected ? 1.5 : 1),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isSelected
                                                ? Icons
                                                    .radio_button_checked_rounded
                                                : Icons
                                                    .radio_button_off_rounded,
                                            size: 18,
                                            color: isSelected
                                                ? (isCompleted
                                                    ? _kGreen
                                                    : isPartial
                                                        ? _kAmber
                                                        : _kRed)
                                                : _kMuted,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              actionSt,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: isSelected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: _kDark,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),

                            // Remarks
                            _buildTextField(
                              label:
                                  'Remarks / Action Summary (तपशील व टिप्पण्या)',
                              hint:
                                  'Enter preventive order details, court hearing or bond conditions...',
                              controller: _remarksCtrl,
                              maxLines: 3,
                              suffix: VoiceDictationButton(
                                controller: _remarksCtrl,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Accused Individual Row Card ───────────────────────────────────────────
  Widget _buildAccusedRowCard(int index, PreventiveAccusedEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kInputBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kMid,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Accused ${index + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              if (!widget.readOnly && _accusedEntries.length > 1)
                IconButton(
                  onPressed: () => _removeAccused(index),
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: _kRed),
                  tooltip: 'Remove Accused',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Accused Name
          _buildTextField(
            label: 'Accused Name (आरोपीचे नाव) *',
            hint: 'Enter full name of accused ${index + 1}',
            controller: entry.name,
            required: true,
            suffix: VoiceDictationButton(
              controller: entry.name,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dynamic Accused Action / Status from backend
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Action / Status'),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _accusedActionTypes.map((type) {
                        final isSel = entry.actionType == type;
                        return ChoiceChip(
                          label: Text(type),
                          selected: isSel,
                          onSelected: widget.readOnly
                              ? null
                              : (val) {
                                  if (val) {
                                    setState(() {
                                      entry.actionType = type;
                                      _markUnsaved();
                                    });
                                  }
                                },
                          selectedColor: const Color(0xFFDCFCE7),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSel ? _kGreen : _kBorder,
                            width: isSel ? 1.5 : 1,
                          ),
                          labelStyle: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight:
                                isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? const Color(0xFF15803D) : _kDark,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Dynamic Bond Taken Y/N from backend options
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Bond Taken (जामीन/बंधपत्र)'),
                    const SizedBox(height: 4),
                    Row(
                      children: _yesNoOptions.map((b) {
                        final isSel = entry.bondTaken == b;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(b),
                            selected: isSel,
                            onSelected: widget.readOnly
                                ? null
                                : (val) {
                                    if (val) {
                                      setState(() {
                                        entry.bondTaken = b;
                                        _markUnsaved();
                                      });
                                    }
                                  },
                            selectedColor: isSel && b == 'Yes'
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF1F5F9),
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSel
                                  ? (b == 'Yes' ? _kGreen : _kSec)
                                  : _kBorder,
                              width: isSel ? 1.5 : 1,
                            ),
                            labelStyle: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight:
                                  isSel ? FontWeight.w700 : FontWeight.w500,
                              color: isSel ? _kDark : _kMuted,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (entry.bondTaken == 'Yes') ...[
            const SizedBox(height: 8),
            _buildTextField(
              label: 'Bond Amount / Surety Details',
              hint: 'e.g. ₹15,000 personal bond with one surety',
              controller: entry.bondDetails,
            ),
          ],
        ],
      ),
    );
  }

  // ── Section Picker Chips ───────────────────────────────────────────────────
  Widget _buildSectionPickerChips() {
    if (_activeActsData.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.error_outline, size: 16, color: _kRed),
            const SizedBox(width: 6),
            Text(
              'Error: Failed to load acts and sections from server.',
              style: GoogleFonts.inter(
                  fontSize: 12, color: _kRed, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }
    final actInfo = _activeActsData[_selectedAct];
    final sections = (actInfo?['sections'] as List<dynamic>?) ?? const [];
    final filterQuery = _sectionSearchCtrl.text.trim().toLowerCase();

    final filtered = sections
        .where((sec) {
          if (sec is! Map) return false;
          final val = sec['val']?.toString().toLowerCase() ?? '';
          final label = sec['label']?.toString().toLowerCase() ?? '';
          return filterQuery.isEmpty ||
              val.contains(filterQuery) ||
              label.contains(filterQuery);
        })
        .take(15)
        .toList();

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          'No matching sections found for "$filterQuery". You can type in custom sections below.',
          style: GoogleFonts.inter(fontSize: 11, color: _kMuted),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _kInputBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kBorder),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: filtered.map((sec) {
          final val = sec['val']?.toString() ?? '';
          final label = sec['label']?.toString() ?? val;
          final isSelected = _selectedSections.contains(val);

          return ActionChip(
            label: Text(label),
            backgroundColor:
                isSelected ? const Color(0xFFC7D2FE) : Colors.white,
            side: BorderSide(
              color: isSelected ? const Color(0xFF4F46E5) : _kBorder,
            ),
            labelStyle: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? const Color(0xFF312E81) : _kDark,
            ),
            avatar: isSelected
                ? const Icon(Icons.check, size: 12, color: Color(0xFF312E81))
                : const Icon(Icons.add, size: 12, color: _kSec),
            onPressed: widget.readOnly
                ? null
                : () {
                    setState(() {
                      if (isSelected) {
                        _selectedSections.remove(val);
                      } else {
                        _selectedSections.add(val);
                      }
                      _markUnsaved();
                    });
                  },
          );
        }).toList(),
      ),
    );
  }

  // ── Card Container ─────────────────────────────────────────────────────────
  Widget _buildCard({
    required String secNum,
    required String title,
    required String marathiTitle,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: _kBorder)),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _kMid,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    secNum,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(icon, size: 18, color: _kTeal),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kDark,
                        ),
                      ),
                      Text(
                        marathiTitle,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _kSec,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),

          // Section Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  // ── Inputs Builders ────────────────────────────────────────────────────────
  Widget _buildLabel(String text, {bool required = false}) {
    final cleanText = text.trim().endsWith('*')
        ? text.trim().substring(0, text.trim().length - 1).trim()
        : text.trim();
    return RichText(
      text: TextSpan(
        text: cleanText,
        style: _tsLabel,
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: _kRed,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool required = false,
    int maxLines = 1,
    IconData? prefixIcon,
    Widget? suffix,
    ValueChanged<String>? onChanged,
    VoidCallback? onTap,
    String? section,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, required: required),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          readOnly: widget.readOnly,
          maxLines: maxLines,
          style: GoogleFonts.inter(fontSize: 12, color: _kDark),
          onTap: () {
            _setActiveVoiceField(label, controller, section: section);
            if (onTap != null) onTap();
          },
          onChanged: (val) {
            _markUnsaved();
            if (onChanged != null) onChanged(val);
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(fontSize: 11, color: _kMuted),
            isDense: true,
            filled: true,
            fillColor: _kInputBg,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 16, color: _kSec)
                : null,
            suffixIcon: suffix,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: _kTeal, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, required: required),
        const SizedBox(height: 5),
        InkWell(
          onTap: widget.readOnly ? null : onTap,
          borderRadius: BorderRadius.circular(6),
          child: IgnorePointer(
            child: TextField(
              controller: controller,
              style: GoogleFonts.inter(fontSize: 12, color: _kDark),
              decoration: InputDecoration(
                hintText: 'DD/MM/YYYY',
                hintStyle: GoogleFonts.inter(fontSize: 11, color: _kMuted),
                isDense: true,
                filled: true,
                fillColor: _kInputBg,
                suffixIcon: const Icon(Icons.calendar_month_rounded,
                    size: 18, color: _kTeal),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: _kBorder),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool required = false,
  }) {
    final effectiveVal = items.contains(value) ? value : items.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, required: required),
        const SizedBox(height: 5),
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: _kInputBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _kBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: effectiveVal,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 20, color: _kSec),
              style: GoogleFonts.inter(fontSize: 12, color: _kDark),
              onChanged: widget.readOnly
                  ? null
                  : (val) {
                      if (val != null) {
                        _markUnsaved();
                        onChanged(val);
                      }
                    },
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight:
                          item == value ? FontWeight.w600 : FontWeight.w500,
                      color: _kDark,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
