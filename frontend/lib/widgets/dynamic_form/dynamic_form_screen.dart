// ignore_for_file: deprecated_member_use
// lib/widgets/dynamic_form/dynamic_form_screen.dart
// Single Source of Truth Dynamic Smart Form Screen driven by PostgreSQL Database.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../modules/core/models/base_record.dart';
import '../../providers/auth_provider.dart';
import '../../services/case_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/module_pdf_helper.dart';
import '../../screens/transfer_case_form_screen.dart';
import 'dynamic_control_factory.dart'
    show panInputFormatters, panValidationError;
import 'dynamic_field_model.dart';
import 'dynamic_repeater_value.dart';
import 'dynamic_section_builder.dart';
import '../repeating_cascading_charges_selector.dart';
import '../../services/dynamic_options_service.dart';
import '../age_digits_limit.dart';

class DynamicFormScreen extends StatefulWidget {
  final dynamic categoryId;
  final String moduleLabel;
  final String moduleKey;
  final String? subCategory;
  final ModuleRecord? existingRecord;
  final Map<String, dynamic>? initialData;
  final Future<Map<String, dynamic>?> Function(
      Map<String, dynamic> payload, bool isEdit)? onSubmitCustom;
  final bool readOnly;
  final List<dynamic>? copyOnTickRules;

  /// Rules {source_field, target_field, days}: when the source date changes,
  /// the target date is set to source + days (e.g. RTI Due Date).
  final List<dynamic>? dateOffsetRules;

  /// Optional per-field character limits from the module config (field_key -> max).
  final Map<String, int>? fieldMaxLengths;

  /// Draw sections strictly in the database display_order of their fields,
  /// instead of the fixed Common Form section order (used by independent
  /// modules such as N.C.). Default false keeps every existing form unchanged.
  final bool sectionsInDisplayOrder;

  /// Show a spinner while the form definition loads. False leaves the page
  /// empty until the fields arrive (used by A.D.). Default true keeps every
  /// existing form unchanged.
  final bool showLoadingSpinner;

  /// Show the 1, 2, 3... number badge on each section card. False shows the
  /// section icon instead (used by A.D.). Default true keeps every existing
  /// form unchanged.
  final bool showSectionNumbers;

  const DynamicFormScreen({
    super.key,
    this.categoryId,
    required this.moduleLabel,
    required this.moduleKey,
    this.subCategory,
    this.existingRecord,
    this.initialData,
    this.onSubmitCustom,
    this.readOnly = false,
    this.copyOnTickRules,
    this.dateOffsetRules,
    this.fieldMaxLengths,
    this.sectionsInDisplayOrder = false,
    this.showLoadingSpinner = true,
    this.showSectionNumbers = true,
  });

  @override
  State<DynamicFormScreen> createState() => _DynamicFormScreenState();
}

class _DynamicFormScreenState extends State<DynamicFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final CaseService _caseService = CaseService();

  DynamicFormDefinition? _formDef;
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _copyOnTickRules = [];
  final Map<String, dynamic> _previousValues = {};

  // Category questions (Kidnapping / Missing, Theft, Sand Theft, POCSO ...)
  // come from their database templates like any other field.

  // Controllers & Values keyed by fieldKey
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _values = {};

  // Every section starts open, in edit and view mode alike, so all entered
  // data is visible; a section stays closed only when the user closes it.
  final Set<String> _collapsedReadOnlySections = {};
  bool _readOnlyAllCollapsed = false;
  bool _isHydrated = false;
  bool _isGeneratingPdf = false;
  bool _isSubmitting = false;

  // Common form steps: 0 Case & people, 1 Investigation, 2 Court & closure
  int _formStep = 0;

  /// Sub-step shown within the current step (0 = x.1).
  int _formSub = 0;

  /// Step layout: section cards drop their own border and margin, since
  /// they sit inside the folder-tab panel.
  bool _flatSectionCards = false;

  /// Sections that had an empty required field at the last Submit (shown
  /// with a red ! in the section list until filled).
  final Set<String> _errorSections = {};

  /// Sub-steps from the last build, to jump to a section with an error.
  List<List<_SubStep>> _lastSteps = const [];

  final Map<int, GlobalKey> _stepTabKeys = {};

  void _goTo(int step, int sub) {
    setState(() {
      _formStep = step;
      _formSub = sub;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _stepTabKeys[step]?.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.5,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // Accused whose arrest & custody are shown; null = the first one
  String? _focusedAccused;

  /// Step layout shows one section at a time, so its sections are always
  /// open (closing one would only leave a blank page)
  bool get _sectionsAlwaysOpen => !widget.sectionsInDisplayOrder;

  bool _isSectionExpanded(String sectionKey) {
    if (_sectionsAlwaysOpen) return true;
    if (_readOnlyAllCollapsed) return false;
    return !_collapsedReadOnlySections.contains(sectionKey);
  }

  void _toggleSection(String sectionKey) {
    if (_sectionsAlwaysOpen) return;
    setState(() {
      if (_readOnlyAllCollapsed) {
        _readOnlyAllCollapsed = false;
        _collapsedReadOnlySections.clear();
      }
      if (_collapsedReadOnlySections.contains(sectionKey)) {
        _collapsedReadOnlySections.remove(sectionKey);
      } else {
        _collapsedReadOnlySections.add(sectionKey);
      }
    });
  }

  bool get _chargesSectionExpanded =>
      _isSectionExpanded('Acts & Sections Filed');
  bool get _accusedSectionExpanded => _isSectionExpanded('Accused');
  bool get _arrestSectionExpanded => _isSectionExpanded('Arrest');
  bool get _dischargeSectionExpanded => _isSectionExpanded('Discharge Accused');
  bool get _preventiveSectionExpanded =>
      _isSectionExpanded('Preventive Action');
  bool get _custodySectionExpanded => _isSectionExpanded('Remand & Custody');
  bool get _scrutinySectionExpanded => _isSectionExpanded('Scrutiny');

  // Legal charges state for Trigger B (Act -> Set of Section numbers)
  final Map<String, Set<String>> _selectedCharges = {};
  Timer? _triggerBDebounce;

  // Multiple Accused state
  final List<Map<String, dynamic>> _accusedList = [];

  // Suspected Accused state
  final List<Map<String, dynamic>> _suspectedAccusedList = [];

  // Unidentified Accused state
  final List<Map<String, dynamic>> _unidentifiedAccusedList = [];

  // Unknown Accused state
  final List<Map<String, dynamic>> _unknownAccusedList = [];

  // Accused types ticked in the Accused card's type dropdown. A type that
  // already has people in it counts as ticked even if not in this set.
  final Set<String> _pickedAccusedTypes = {};

  // The one accused type being added / edited now (the type dropdown picks
  // one at a time). People of other types are kept, just not shown.
  String? _activeAccusedType;

  // The accused-type person open for editing. Other filled people collapse
  // to their one-line header; adding a person opens it and folds the rest.
  Map<String, dynamic>? _openPerson;

  bool _personFilled(Map<String, dynamic> p) => [
        'name',
        'approximate_age',
        'height',
        'skin_colour',
        'identification_mark',
        'description',
      ].any((k) => (p[k]?.toString().trim() ?? '').isNotEmpty);

  /// Parent-controlled collapse for a person card (null = card decides,
  /// as in read-only view).
  bool? _personCollapsed(Map<String, dynamic> p) =>
      widget.readOnly ? null : _personFilled(p) && !identical(p, _openPerson);

  void _togglePerson(Map<String, dynamic> p) => setState(() {
        _openPerson = (_personCollapsed(p) ?? false) ? p : null;
      });

  // Arrest state
  final List<Map<String, dynamic>> _arrestRecordsList = [];

  // Discharged Accused state
  String? _selectedAccusedToDischarge;
  final List<String> _dischargedAccusedList = [];
  final Map<String, bool> _dischargedAccusedMap = {};
  final Map<String, TextEditingController> _dischargeDateControllers = {};

  // Preventive Action state
  String _selectedPreventiveType = '';
  final TextEditingController _preventiveDateCtrl = TextEditingController();
  final TextEditingController _preventiveOutwardCtrl = TextEditingController();
  final TextEditingController _preventiveBondDateCtrl = TextEditingController();
  final TextEditingController _preventiveBondCancelDateCtrl =
      TextEditingController();
  final List<Map<String, dynamic>> _preventiveActionsList = [];
  final Set<String> _customPreventivePersons = {};

  // Remand & Custody state
  String? _expandedCustodyAccused;
  final Set<String> _customCustodyPersons = {};
  final TextEditingController _pcrDaysCtrl = TextEditingController();
  final TextEditingController _prBondDateCtrl = TextEditingController();
  final TextEditingController _suretyNameCtrl = TextEditingController();
  final TextEditingController _suretyAgeCtrl = TextEditingController();
  final TextEditingController _suretyOccCtrl = TextEditingController();
  final TextEditingController _suretyMobileCtrl = TextEditingController();
  final TextEditingController _suretyAadhaarCtrl = TextEditingController();
  final TextEditingController _suretyPanCtrl = TextEditingController();
  final TextEditingController _suretyAddressCtrl = TextEditingController();
  final TextEditingController _jailDateCtrl = TextEditingController();
  final List<Map<String, dynamic>> _custodyRecordsList = [];
  List<String> _genderOptions = [];

  Future<void> _loadGenderOptions() async {
    try {
      final opts =
          await DynamicOptionsService().fetchOptions('/api/options/gender/');
      final relations = await DynamicOptionsService()
          .fetchOptions('/api/options/surety_relations/');
      final yesNo =
          await DynamicOptionsService().fetchOptions('/api/options/yes_no/');
      if (mounted) {
        setState(() {
          if (opts.isNotEmpty) _genderOptions = opts;
          if (relations.isNotEmpty) _suretyRelationChoices = relations;
          if (yesNo.isNotEmpty) _yesNoOptions = yesNo;
        });
      }
    } catch (_) {}
  }

  List<String> _suretyRelationChoices = [];

  /// Yes / No answers from the database (/api/options/yes_no/), first = Yes
  List<String> _yesNoOptions = [];

  final bool _hideEmptyInViewMode = true;
  List<String> _designationOptions = [];

  bool get isEdit =>
      widget.existingRecord != null ||
      (widget.initialData != null && !widget.readOnly);

  @override
  void initState() {
    super.initState();
    if (widget.copyOnTickRules != null) {
      _copyOnTickRules = List<dynamic>.from(widget.copyOnTickRules!);
    }
    _loadFormDefinition();
    _loadDesignations();
    _loadGenderOptions();
  }

  Future<void> _loadDesignations() async {
    try {
      final res = await _caseService.fetchDesignations();
      if (mounted && res.isNotEmpty) {
        final unique = <String>[];
        final seen = <String>{};
        for (final d in res) {
          final title = d['display_name']?.toString() ??
              d['title']?.toString() ??
              d['code']?.toString() ??
              '';
          final trimmed = title.trim();
          if (trimmed.isNotEmpty && seen.add(trimmed.toLowerCase())) {
            unique.add(trimmed);
          }
        }
        setState(() {
          _designationOptions = unique;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _triggerBDebounce?.cancel();
    _preventiveDateCtrl.dispose();
    _preventiveOutwardCtrl.dispose();
    _preventiveBondDateCtrl.dispose();
    _preventiveBondCancelDateCtrl.dispose();
    _pcrDaysCtrl.dispose();
    _prBondDateCtrl.dispose();
    _suretyNameCtrl.dispose();
    _suretyAgeCtrl.dispose();
    _suretyOccCtrl.dispose();
    _suretyMobileCtrl.dispose();
    _suretyAadhaarCtrl.dispose();
    _suretyPanCtrl.dispose();
    _suretyAddressCtrl.dispose();
    _jailDateCtrl.dispose();
    for (final c in _dischargeDateControllers.values) {
      c.dispose();
    }
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String get _targetCategoryParam {
    if (widget.categoryId != null &&
        widget.categoryId.toString().trim().isNotEmpty) {
      return widget.categoryId.toString();
    }
    if (widget.subCategory != null && widget.subCategory!.trim().isNotEmpty) {
      return widget.subCategory!;
    }
    return widget.moduleLabel;
  }

  Future<void> _loadFormDefinition({List<String>? chargedSections}) async {
    debugPrint(
        '[DFS] _loadFormDefinition called. category=$_targetCategoryParam, readOnly=${widget.readOnly}, isEdit=$isEdit, existingRecord=${widget.existingRecord?.id}');
    try {
      final json = await _caseService.fetchFormDefinition(
        _targetCategoryParam,
        caseId: widget.existingRecord?.id,
        sections: chargedSections,
      );

      if (!mounted) return;

      debugPrint(
          '[DFS] fetchFormDefinition returned: ${json != null ? 'has data, keys=${json.keys.toList()}' : 'NULL'}');
      if (json != null) {
        final def = DynamicFormDefinition.fromJson(json);
        debugPrint('[DFS] Parsed ${def.fields.length} fields');
        setState(() {
          _formDef = def;
          _isLoading = false;
          _errorMessage = null;

          if (def.preventiveItems.isNotEmpty &&
              !def.preventiveItems.contains(_selectedPreventiveType)) {
            _selectedPreventiveType = def.preventiveItems.first;
          }

          // Initialize controllers and values for any new fields
          for (final f in def.fields) {
            final ctrl = _controllers.putIfAbsent(
                f.fieldKey, () => TextEditingController());
            if (f.fieldType == 'checkbox') {
              _values.putIfAbsent(f.fieldKey, () => false);
              if (f.fieldKey.contains('same_as_complainant')) {
                final prefix = f.fieldKey.replaceAll('same_as_complainant', '');
                final pairs = [
                  'name',
                  'age',
                  'gender',
                  'occupation',
                  'mobile',
                  'aadhaar',
                  'pan',
                  'religion',
                  'caste',
                ];
                for (final p in pairs) {
                  final target = '${prefix}injured_$p';
                  if (!_copyOnTickRules.any((r) =>
                      r is Map &&
                      r['trigger_field'] == f.fieldKey &&
                      r['target_field'] == target)) {
                    _copyOnTickRules.add({
                      'trigger_field': f.fieldKey,
                      'source_field': 'complainant_$p',
                      'target_field': target,
                    });
                  }
                }
              }
            }
            if (!isEdit &&
                f.defaultValue != null &&
                f.defaultValue!.isNotEmpty) {
              if (_values[f.fieldKey] == null ||
                  _values[f.fieldKey].toString().isEmpty) {
                _values[f.fieldKey] = f.defaultValue;
                ctrl.text = f.defaultValue!;
              }
            }
          }
        });

        // If editing or existing record, hydrate fields once
        debugPrint('[DFS] isEdit=$isEdit, _isHydrated=$_isHydrated');
        if ((isEdit || widget.initialData != null) && !_isHydrated) {
          debugPrint('[DFS] Calling _hydrateFromExistingRecord...');
          _hydrateFromExistingRecord();
          _isHydrated = true;

          // Fetch latest full case details by ID to ensure all child table data and extra_fields are refreshed
          if (widget.existingRecord != null &&
              widget.existingRecord!.id.trim().isNotEmpty) {
            _caseService
                .fetchCaseDetailsMap(widget.existingRecord!.id)
                .then((caseDetail) {
              if (caseDetail != null && mounted) {
                if (caseDetail['extra_fields'] is Map) {
                  widget.existingRecord!.extraFields.addAll(
                    Map<String, dynamic>.from(
                        caseDetail['extra_fields'] as Map),
                  );
                }
                if (caseDetail['road_accident'] is Map) {
                  widget.existingRecord!.extraFields.addAll(
                    Map<String, dynamic>.from(
                        caseDetail['road_accident'] as Map),
                  );
                }
                _hydrateFromExistingRecord();
              }
            }).catchError((_) {});
          }
        } else {
          debugPrint(
              '[DFS] SKIPPED hydration! isEdit=$isEdit, _isHydrated=$_isHydrated');
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load form definition from database.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading form: $e';
      });
    }
  }

  void _hydrateFromExistingRecord() {
    final r = widget.existingRecord;
    final extra = r?.extraFields ?? widget.initialData ?? {};
    debugPrint(
        '[DFS] _hydrateFromExistingRecord: extraFields keys=${extra.keys.toList()}');
    debugPrint(
        '[DFS] extraFields sample: caseNumber=${r?.caseNumber}, title=${r?.title}, accused=${r?.accused}');
    final common =
        (extra['commonForm'] is Map) ? extra['commonForm'] as Map : {};
    debugPrint('[DFS] commonForm keys=${common.keys.toList()}');

    final safeAccused = r != null ? _sanitizeName(r.accused) : '';
    if (r != null) {
      // Standard root fields mapping
      _setField('cr_number', r.caseNumber);
      _setField('crNo', r.caseNumber);
      _setField('case_number', r.caseNumber);
      _setField('caseNumber', r.caseNumber);
      _setField('title', r.title);
      _setField('brief_description', r.description);
      _setField('description', r.description);
      _setField('complainant_name', r.complainant);
      _setField('accused_name', safeAccused);
      _setField('accused', safeAccused);
      _setField('crime_spot_address', r.location);
      _setField('spotAddress', r.location);
      _setField('location', r.location);
      final incDateStr = DateFormat('dd/MM/yyyy').format(r.incidentDate);
      final incDateTimeStr =
          DateFormat('dd/MM/yyyy HH:mm').format(r.incidentDate);
      _setField('incident_date', incDateStr);
      _setField('incident_datetime', incDateTimeStr);
      _setField('incidentDate', incDateStr);
      _setField('assigned_officer', r.assignedOfficer);
      _setField('investigating_officer', r.assignedOfficer);
      _setField('io_name', r.assignedOfficer);
      _setField('officer_name', r.assignedOfficer);
      _setField('priority', r.priority);
      _setField('status', r.status);
      _setField('police_station', r.stationName);
      _setField('station_name', r.stationName);
    }

    // Hydrate accused list
    _accusedList.clear();
    final accData = common['accused'] ?? extra['accused'];
    if (accData is List) {
      for (final item in accData) {
        if (item is Map) {
          final n =
              (item['name'] ?? item['accused_name'])?.toString().trim() ?? '';
          if (n.isNotEmpty) {
            _accusedList.add({
              'name': n,
              'age': item['age']?.toString() ?? '',
              'gender': item['gender']?.toString().isNotEmpty == true
                  ? item['gender'].toString()
                  : '',
              'occupation':
                  (item['occupation'] ?? item['occ'])?.toString() ?? '',
              'mobile': item['mobile']?.toString() ?? '',
              'aadhaar': item['aadhaar']?.toString() ?? '',
              'pan': item['pan']?.toString() ?? '',
              'religion': item['religion']?.toString() ?? '',
              'caste': item['caste']?.toString() ?? '',
              'address': item['address']?.toString() ?? '',
              'medical': item['medical']?.toString() ?? '',
              'medical_date': item['medical_date']?.toString() ?? '',
              'role': 'accused',
            });
          }
        } else if (item is String && item.trim().isNotEmpty) {
          _accusedList.add({
            'name': item.trim(),
            'gender': '',
            'role': 'accused',
          });
        }
      }
    }
    final persData = common['persons'] ?? extra['persons'];
    if (persData is List) {
      for (final p in persData) {
        if (p is Map) {
          final rRole = (p['role'] ?? '').toString().toLowerCase();
          final n = (p['name'] ?? '').toString().trim();
          if (rRole == 'accused' &&
              n.isNotEmpty &&
              !_accusedList.any((a) => a['name'] == n)) {
            _accusedList.add({
              'name': n,
              'age': p['age']?.toString() ?? '',
              'gender': p['gender']?.toString().isNotEmpty == true
                  ? p['gender'].toString()
                  : '',
              'occupation': (p['occupation'] ?? p['occ'])?.toString() ?? '',
              'mobile': p['mobile']?.toString() ?? '',
              'aadhaar': p['aadhaar']?.toString() ?? '',
              'pan': p['pan']?.toString() ?? '',
              'religion': p['religion']?.toString() ?? '',
              'caste': p['caste']?.toString() ?? '',
              'address': p['address']?.toString() ?? '',
              'medical': p['medical']?.toString() ?? '',
              'medical_date': p['medical_date']?.toString() ?? '',
              'role': 'accused',
            });
          }
        }
      }
    }
    if (_accusedList.isEmpty && safeAccused.isNotEmpty) {
      final names = safeAccused
          .split(RegExp(r'[,;]'))
          .map((s) => _sanitizeName(s))
          .where((s) => s.isNotEmpty);
      for (final n in names) {
        _accusedList.add({
          'name': n,
          'age': _controllers['accused_age']?.text ?? '',
          'gender': _values['accused_gender'] ?? '',
          'occupation': _controllers['accused_occupation']?.text ?? '',
          'mobile': _controllers['accused_mobile']?.text ?? '',
          'aadhaar': _controllers['accused_aadhaar']?.text ?? '',
          'pan': _controllers['accused_pan']?.text ?? '',
          'religion': _controllers['accused_religion']?.text ?? '',
          'caste': _controllers['accused_caste']?.text ?? '',
          'address': _controllers['accused_address']?.text ?? '',
          'role': 'accused',
        });
      }
    }
    _syncPrimaryAccusedControllers();

    // Check nested extra fields
    for (final entry in extra.entries) {
      _setField(entry.key, entry.value);
    }
    for (final entry in common.entries) {
      _setField(entry.key, entry.value);
    }

    // Hydrate charges
    final chargesData = common['charges'] ??
        extra['charges'] ??
        common['acts_sections'] ??
        extra['acts_sections'];
    if (chargesData is Map) {
      for (final e in chargesData.entries) {
        if (e.value is Map) {
          final act = (e.value as Map)['act']?.toString() ?? '';
          final secs = (e.value as Map)['sections'];
          if (act.isNotEmpty && secs is Iterable) {
            _selectedCharges[act] = secs.map((s) => s.toString()).toSet();
          }
        }
      }
    } else if (chargesData is List) {
      for (final item in chargesData) {
        if (item is Map) {
          final act =
              (item['act'] ?? item['act_name'] ?? item['act_id'])?.toString() ??
                  '';
          final sec =
              (item['section'] ?? item['section_number'] ?? item['section_id'])
                  ?.toString();
          if (act.isNotEmpty && sec != null && sec.isNotEmpty) {
            _selectedCharges.putIfAbsent(act, () => <String>{}).add(sec);
          }
        }
      }
    }

    // Hydrate discharged accused
    final disData = common['dischargeByAccused'] ?? extra['dischargeByAccused'];
    if (disData is Map) {
      for (final e in disData.entries) {
        if (e.value == true) {
          final n = e.key.toString().trim();
          if (n.isNotEmpty && !_dischargedAccusedList.contains(n)) {
            _dischargedAccusedList.add(n);
          }
          _dischargedAccusedMap[n] = true;
        }
      }
    }
    final disDetails = common['dischargeDetails'] ?? extra['dischargeDetails'];
    if (disDetails is Map) {
      for (final e in disDetails.entries) {
        final n = e.key.toString().trim();
        if (e.value is Map) {
          final dt = e.value['date'] ?? e.value['discharge_date'];
          if (dt != null && dt.toString().isNotEmpty) {
            _dischargeDateControllers
                .putIfAbsent(n, () => TextEditingController())
                .text = dt.toString();
          }
        }
      }
    }
    final disList = common['discharges'] ?? extra['discharges'];
    if (disList is List) {
      for (final item in disList) {
        if (item is Map) {
          final n =
              (item['name'] ?? item['typed_name'])?.toString().trim() ?? '';
          if (n.isNotEmpty) {
            if (!_dischargedAccusedList.contains(n)) {
              _dischargedAccusedList.add(n);
              _dischargedAccusedMap[n] = true;
            }
            final dt = item['discharge_date'] ?? item['date'];
            if (dt != null && dt.toString().isNotEmpty) {
              _dischargeDateControllers
                  .putIfAbsent(n, () => TextEditingController())
                  .text = dt.toString();
            }
          }
        } else if (item is String && item.trim().isNotEmpty) {
          final n = item.trim();
          if (!_dischargedAccusedList.contains(n)) {
            _dischargedAccusedList.add(n);
            _dischargedAccusedMap[n] = true;
          }
        }
      }
    }
    final personsList = common['persons'] ?? extra['persons'];
    if (personsList is List) {
      for (final p in personsList) {
        if (p is Map && p['discharge_status'] is Map) {
          final ds = p['discharge_status'] as Map;
          if (ds['is_discharged'] == true) {
            final n = (p['name'] ?? '').toString().trim();
            if (n.isNotEmpty) {
              if (!_dischargedAccusedList.contains(n)) {
                _dischargedAccusedList.add(n);
                _dischargedAccusedMap[n] = true;
              }
              final dt = ds['discharge_date'];
              if (dt != null && dt.toString().isNotEmpty) {
                _dischargeDateControllers
                    .putIfAbsent(n, () => TextEditingController())
                    .text = dt.toString();
              }
            }
          }
        }
      }
    }

    // Hydrate suspected accused
    _suspectedAccusedList.clear();
    final suspData = common['suspectedAccused'] ??
        extra['suspectedAccused'] ??
        common['suspects'] ??
        extra['suspects'] ??
        common['suspected_accused'] ??
        extra['suspected_accused'];
    if (suspData is List && suspData.isNotEmpty) {
      for (final it in suspData) {
        if (it is Map) {
          final n =
              (it['name'] ?? it['suspected_accused_name'] ?? it['suspect_name'])
                      ?.toString()
                      .trim() ??
                  '';
          if (n.isNotEmpty) {
            _suspectedAccusedList.add({
              'name': n,
              'age':
                  (it['age'] ?? it['suspected_accused_age'] ?? '').toString(),
              'gender': (it['gender'] ?? it['suspected_accused_gender'] ?? '')
                  .toString(),
              'occupation': (it['occupation'] ??
                      it['occ'] ??
                      it['suspected_accused_occupation'] ??
                      '')
                  .toString(),
              'mobile': (it['mobile'] ?? it['suspected_accused_mobile'] ?? '')
                  .toString(),
              'aadhaar':
                  (it['aadhaar'] ?? it['suspected_accused_aadhaar'] ?? '')
                      .toString(),
              'pan':
                  (it['pan'] ?? it['suspected_accused_pan'] ?? '').toString(),
              'religion':
                  (it['religion'] ?? it['suspected_accused_religion'] ?? '')
                      .toString(),
              'caste': (it['caste'] ?? it['suspected_accused_caste'] ?? '')
                  .toString(),
              'address':
                  (it['address'] ?? it['suspected_accused_address'] ?? '')
                      .toString(),
              'role': 'suspected_accused',
            });
          }
        } else if (it is String && it.trim().isNotEmpty) {
          _suspectedAccusedList.add({
            'name': it.trim(),
            'gender': '',
            'role': 'suspected_accused',
          });
        }
      }
    }
    final rawPersonsSource = common['persons'] ?? extra['persons'];
    if (rawPersonsSource is List) {
      for (final p in rawPersonsSource) {
        if (p is Map) {
          final rRole = (p['role'] ?? '').toString().toLowerCase();
          final n = (p['name'] ?? '').toString().trim();
          if ((rRole == 'suspected_accused' || rRole == 'suspect') &&
              n.isNotEmpty &&
              !_suspectedAccusedList.any((a) => a['name'] == n)) {
            _suspectedAccusedList.add({
              'name': n,
              'age': (p['age'] ?? '').toString(),
              'gender': (p['gender'] ?? '').toString(),
              'occupation': (p['occupation'] ?? p['occ'] ?? '').toString(),
              'mobile': (p['mobile'] ?? '').toString(),
              'aadhaar': (p['aadhaar'] ?? '').toString(),
              'pan': (p['pan'] ?? '').toString(),
              'religion': (p['religion'] ?? '').toString(),
              'caste': (p['caste'] ?? '').toString(),
              'address': (p['address'] ?? '').toString(),
              'role': 'suspected_accused',
            });
          }
        }
      }
    }
    if (_suspectedAccusedList.isEmpty) {
      final sName = (common['suspected_accused_name'] ??
              extra['suspected_accused_name'] ??
              common['suspected_name'] ??
              extra['suspected_name'])
          ?.toString()
          .trim();
      if (sName != null && sName.isNotEmpty) {
        _suspectedAccusedList.add({
          'name': sName,
          'age': (common['suspected_accused_age'] ??
                  extra['suspected_accused_age'] ??
                  '')
              .toString(),
          'gender': (common['suspected_accused_gender'] ??
                  extra['suspected_accused_gender'] ??
                  '')
              .toString(),
          'occupation': (common['suspected_accused_occupation'] ??
                  extra['suspected_accused_occupation'] ??
                  '')
              .toString(),
          'mobile': (common['suspected_accused_mobile'] ??
                  extra['suspected_accused_mobile'] ??
                  '')
              .toString(),
          'aadhaar': (common['suspected_accused_aadhaar'] ??
                  extra['suspected_accused_aadhaar'] ??
                  '')
              .toString(),
          'pan': (common['suspected_accused_pan'] ??
                  extra['suspected_accused_pan'] ??
                  '')
              .toString(),
          'religion': (common['suspected_accused_religion'] ??
                  extra['suspected_accused_religion'] ??
                  '')
              .toString(),
          'caste': (common['suspected_accused_caste'] ??
                  extra['suspected_accused_caste'] ??
                  '')
              .toString(),
          'address': (common['suspected_accused_address'] ??
                  extra['suspected_accused_address'] ??
                  '')
              .toString(),
          'role': 'suspected_accused',
        });
      }
    }
    _syncPrimarySuspectedAccusedControllers();

    // Hydrate unidentified accused
    _unidentifiedAccusedList.clear();
    final unidentData = common['unidentifiedList'] ??
        extra['unidentifiedList'] ??
        common['unidentified_accused'] ??
        extra['unidentified_accused'] ??
        common['unidentified'] ??
        extra['unidentified'];
    if (unidentData is List && unidentData.isNotEmpty) {
      for (final it in unidentData) {
        if (it is Map) {
          _unidentifiedAccusedList.add({
            'approximate_age':
                (it['approximate_age'] ?? it['approx_age'] ?? it['age'] ?? '')
                    .toString(),
            'gender': (it['gender'] ?? '').toString(),
            'skin_colour':
                (it['skin_colour'] ?? it['skinColor'] ?? '').toString(),
            'possible_occupation':
                (it['possible_occupation'] ?? it['occupation'] ?? '')
                    .toString(),
            'identification_mark': (it['identification_mark'] ??
                    it['identificationMarks'] ??
                    it['marks'] ??
                    '')
                .toString(),
            'height': (it['height'] ?? '').toString(),
            'description':
                (it['description'] ?? it['physical_description'] ?? '')
                    .toString(),
            'address': (it['address'] ?? it['area'] ?? '').toString(),
            'role': 'unidentified_accused',
          });
        }
      }
    }
    if (rawPersonsSource is List) {
      for (final p in rawPersonsSource) {
        if (p is Map) {
          final rRole = (p['role'] ?? '').toString().toLowerCase();
          if (rRole == 'unidentified' || rRole == 'unidentified_accused') {
            _unidentifiedAccusedList.add({
              'approximate_age':
                  (p['approximate_age'] ?? p['age'] ?? '').toString(),
              'gender': (p['gender'] ?? '').toString(),
              'skin_colour': (p['skin_colour'] ?? '').toString(),
              'possible_occupation':
                  (p['possible_occupation'] ?? p['occupation'] ?? '')
                      .toString(),
              'identification_mark':
                  (p['identification_mark'] ?? '').toString(),
              'height': (p['height'] ?? '').toString(),
              'description': (p['description'] ?? '').toString(),
              'address': (p['address'] ?? '').toString(),
              'role': 'unidentified_accused',
            });
          }
        }
      }
    }
    if (_unidentifiedAccusedList.isEmpty) {
      final approxAge =
          (common['approximate_age'] ?? extra['approximate_age'] ?? '')
              .toString()
              .trim();
      final skinCol = (common['skin_colour'] ?? extra['skin_colour'] ?? '')
          .toString()
          .trim();
      final identMark =
          (common['identification_mark'] ?? extra['identification_mark'] ?? '')
              .toString()
              .trim();
      final desc = (common['description'] ?? extra['description'] ?? '')
          .toString()
          .trim();
      if (approxAge.isNotEmpty ||
          skinCol.isNotEmpty ||
          identMark.isNotEmpty ||
          desc.isNotEmpty) {
        _unidentifiedAccusedList.add({
          'approximate_age': approxAge,
          'gender': (common['unidentified_gender'] ??
                  extra['unidentified_gender'] ??
                  '')
              .toString(),
          'skin_colour': skinCol,
          'possible_occupation': (common['possible_occupation'] ??
                  extra['possible_occupation'] ??
                  '')
              .toString(),
          'identification_mark': identMark,
          'height': (common['height'] ?? extra['height'] ?? '').toString(),
          'description': desc,
          'address': (common['unidentified_address'] ??
                  extra['unidentified_address'] ??
                  '')
              .toString(),
          'role': 'unidentified_accused',
        });
      }
    }
    _syncPrimaryUnidentifiedControllers();

    // Hydrate arrest records
    _arrestRecordsList.clear();
    final arrestSources = [
      common['arrests'],
      extra['arrests'],
      common['arrest_records'],
      extra['arrest_records'],
    ];
    for (final src in arrestSources) {
      if (src is List && src.isNotEmpty && _arrestRecordsList.isEmpty) {
        for (final it in src) {
          if (it is Map) {
            final pName = (it['arrested_person_name'] ??
                        it['person_name'] ??
                        it['name'] ??
                        it['accusedName'] ??
                        it['accused'])
                    ?.toString()
                    .trim() ??
                '';
            final dt =
                (it['arrest_datetime'] ?? it['arrest_date'] ?? '').toString();
            final isSec = it['sec_47_48_bnss'] == true ||
                it['sec_47_48_bnss'] == 'true' ||
                it['sec4748Bnss'] == true;
            final relName =
                (it['relative_friend_name'] ?? it['relativeFriendName'] ?? '')
                    .toString();
            final relRel = (it['relative_friend_relation'] ??
                    it['relativeFriendRelation'] ??
                    '')
                .toString();
            final isNotice = it['release_on_notice'] == true ||
                it['release_on_notice'] == 'true' ||
                it['releaseOnNotice'] == true;
            final noticeDt =
                (it['release_on_notice_datetime'] ?? it['noticeDateTime'] ?? '')
                    .toString();
            final isAntBail = it['anticipatory_bail'] == true ||
                it['anticipatory_bail'] == 'true' ||
                it['anticipatoryBail'] == true;
            final antBailDt = (it['anticipatory_bail_datetime'] ??
                    it['anticipatoryBailDateTime'] ??
                    '')
                .toString();
            final isDeath = it['death_of_accused'] == true ||
                it['death_of_accused'] == 'true' ||
                it['deathOfAccused'] == true;
            final deathDt = (it['death_of_accused_datetime'] ??
                    it['deathOfAccusedDateTime'] ??
                    '')
                .toString();

            if (pName.isNotEmpty ||
                dt.isNotEmpty ||
                isNotice ||
                isAntBail ||
                isDeath) {
              _arrestRecordsList.add({
                'arrested_person_name': pName,
                'person_name': pName,
                'name': pName,
                'arrest_datetime': dt,
                'sec_47_48_bnss': isSec,
                'relative_friend_name': relName,
                'relative_friend_relation': relRel,
                'release_on_notice': isNotice,
                'release_on_notice_datetime': noticeDt,
                'anticipatory_bail': isAntBail,
                'anticipatory_bail_datetime': antBailDt,
                'death_of_accused': isDeath,
                'death_of_accused_datetime': deathDt,
              });
            }
          }
        }
      }
    }
    if (_arrestRecordsList.isEmpty && rawPersonsSource is List) {
      for (final p in rawPersonsSource) {
        if (p is Map && p['arrest_status'] is Map) {
          final asMap = p['arrest_status'] as Map;
          final pName = (p['name'] ?? '').toString().trim();
          final dt =
              (asMap['arrest_datetime'] ?? asMap['date'] ?? '').toString();
          if (pName.isNotEmpty || dt.isNotEmpty) {
            _arrestRecordsList.add({
              'arrested_person_name': pName,
              'person_name': pName,
              'name': pName,
              'arrest_datetime': dt,
              'sec_47_48_bnss': asMap['sec_47_48_bnss'] == true,
              'relative_friend_name':
                  (asMap['relative_friend_name'] ?? '').toString(),
              'relative_friend_relation':
                  (asMap['relative_friend_relation'] ?? '').toString(),
              'release_on_notice': asMap['release_on_notice'] == true,
              'release_on_notice_datetime':
                  (asMap['release_on_notice_datetime'] ?? '').toString(),
              'anticipatory_bail': asMap['anticipatory_bail'] == true,
              'anticipatory_bail_datetime':
                  (asMap['anticipatory_bail_datetime'] ?? '').toString(),
              'death_of_accused': asMap['death_of_accused'] == true,
              'death_of_accused_datetime':
                  (asMap['death_of_accused_datetime'] ?? '').toString(),
            });
          }
        }
      }
    }
    if (_arrestRecordsList.isEmpty) {
      final arrName = (common['arrested_person_name'] ??
              extra['arrested_person_name'] ??
              '')
          .toString()
          .trim();
      final arrDt =
          (common['arrest_datetime'] ?? extra['arrest_datetime'] ?? '')
              .toString()
              .trim();
      if (arrName.isNotEmpty || arrDt.isNotEmpty) {
        _arrestRecordsList.add({
          'arrested_person_name': arrName.isNotEmpty
              ? arrName
              : (widget.existingRecord?.accused ?? ''),
          'person_name': arrName.isNotEmpty
              ? arrName
              : (widget.existingRecord?.accused ?? ''),
          'name': arrName.isNotEmpty
              ? arrName
              : (widget.existingRecord?.accused ?? ''),
          'arrest_datetime': arrDt,
          'sec_47_48_bnss': common['sec_47_48_bnss'] == true ||
              extra['sec_47_48_bnss'] == true,
          'relative_friend_name': (common['relative_friend_name'] ??
                  extra['relative_friend_name'] ??
                  '')
              .toString(),
          'relative_friend_relation': (common['relative_friend_relation'] ??
                  extra['relative_friend_relation'] ??
                  '')
              .toString(),
          'release_on_notice': common['release_on_notice'] == true ||
              extra['release_on_notice'] == true,
          'release_on_notice_datetime': (common['release_on_notice_datetime'] ??
                  extra['release_on_notice_datetime'] ??
                  '')
              .toString(),
          'anticipatory_bail': common['anticipatory_bail'] == true ||
              extra['anticipatory_bail'] == true,
          'anticipatory_bail_datetime': (common['anticipatory_bail_datetime'] ??
                  extra['anticipatory_bail_datetime'] ??
                  '')
              .toString(),
          'death_of_accused': common['death_of_accused'] == true ||
              extra['death_of_accused'] == true,
          'death_of_accused_datetime': (common['death_of_accused_datetime'] ??
                  extra['death_of_accused_datetime'] ??
                  '')
              .toString(),
        });
      }
    }
    _syncPrimaryArrestControllers();

    // Hydrate unknown accused
    final unkData = common['unknown_accused'] ??
        common['unknownAccused'] ??
        common['unknownList'] ??
        common['unknown_accused_list'] ??
        extra['unknown_accused'] ??
        extra['unknownAccused'] ??
        extra['unknownList'] ??
        extra['unknown_accused_list'];
    _unknownAccusedList.clear();
    if (unkData is List) {
      for (final it in unkData) {
        if (it is Map) {
          _unknownAccusedList.add(Map<String, dynamic>.from(it));
        } else if (it is String && it.trim().isNotEmpty) {
          _unknownAccusedList
              .add({'name': it.trim(), 'role': 'unknown_accused'});
        }
      }
    }
    final rawPersons = common['persons'] ?? extra['persons'];
    if (rawPersons is List) {
      for (final p in rawPersons) {
        if (p is Map &&
            (p['role'] == 'unknown_accused' || p['role'] == 'unknown')) {
          final pName = p['name']?.toString() ?? 'Unknown Accused';
          if (!_unknownAccusedList.any((it) => it['name'] == pName)) {
            _unknownAccusedList.add({
              'name': pName,
              'role': 'unknown_accused',
            });
          }
        }
      }
    }
    if (_unknownAccusedList.isEmpty) {
      final isUnk = common['is_unknown_accused'] ??
          common['isUnknownAccused'] ??
          common['isUnknownUntraced'] ??
          extra['is_unknown_accused'] ??
          extra['isUnknownAccused'] ??
          extra['isUnknownUntraced'];
      if (isUnk == true || isUnk.toString().toLowerCase() == 'true') {
        _unknownAccusedList.add({
          'name': 'Unknown Accused #1',
          'role': 'unknown_accused',
        });
      }
    }

    // Hydrate procedural checklists (Panchanama)
    final procList =
        common['procedural_checklists'] ?? extra['procedural_checklists'];
    if (procList is List) {
      for (final item in procList) {
        if (item is Map) {
          final itemName = item['item_name']?.toString() ?? '';
          final isChecked = item['is_checked'] == true ||
              item['is_checked']?.toString().toLowerCase() == 'true';
          final dt = item['event_datetime']?.toString() ?? '';
          for (final entry in _panchanamaKeyToName.entries) {
            if (entry.value.toLowerCase() == itemName.toLowerCase() ||
                entry.key.toLowerCase() == itemName.toLowerCase()) {
              if (isChecked) {
                _setField(entry.key, true);
                if (dt.isNotEmpty) {
                  _setField('${entry.key}_date', dt);
                }
              }
            }
          }
        }
      }
    }

    final procChecks = common['proceduralChecks'] ?? extra['proceduralChecks'];
    final procDates = common['proceduralDates'] ?? extra['proceduralDates'];
    if (procChecks is Map) {
      for (final e in procChecks.entries) {
        if (e.value == true || e.value?.toString().toLowerCase() == 'true') {
          final kName = e.key.toString();
          for (final entry in _panchanamaKeyToName.entries) {
            if (entry.value.toLowerCase() == kName.toLowerCase() ||
                entry.key.toLowerCase() == kName.toLowerCase()) {
              _setField(entry.key, true);
              final dVal =
                  (procDates is Map) ? procDates[e.key]?.toString() : null;
              if (dVal != null && dVal.isNotEmpty) {
                _setField('${entry.key}_date', dVal);
              }
            }
          }
        }
      }
    }

    const legacyMap = {
      'chkPanchSpot': 'spot_panchanama',
      'chkSeizurePanch': 'seizure_panchanama',
      'chkSearch': 'search_panchanama',
      'chkPersSearch': 'personal_search_panchanama',
      'chkMemo': 'memorandum_panchanama',
      'chkIdent': 'identification_panchanama',
      'chkIdParade': 'identification_parade_panchanama',
    };
    for (final leg in legacyMap.entries) {
      if (common[leg.key] == true || extra[leg.key] == true) {
        _setField(leg.value, true);
        final dt = common['${leg.key}Date'] ?? extra['${leg.key}Date'];
        if (dt != null && dt.toString().isNotEmpty) {
          _setField('${leg.value}_date', dt.toString());
        }
      }
    }

    for (final k in _panchanamaKeyToName.keys) {
      if (_values[k] == true || _controllers[k]?.text.toLowerCase() == 'true') {
        final curDate = _controllers['${k}_date']?.text.trim() ??
            _values['${k}_date']?.toString().trim() ??
            '';
        if (curDate.isEmpty) {
          final nowStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
          _setField('${k}_date', nowStr);
        }
      }
    }

    // Hydrate Preventive Action List
    _preventiveActionsList.clear();
    final prevItems = extra['preventive_actions'] ??
        common['preventive_actions'] ??
        extra['preventive_action_items'] ??
        common['preventive_action_items'] ??
        (extra['preventive'] is Map
            ? (extra['preventive'] as Map)['items'] ??
                (extra['preventive'] as Map)['actions']
            : null) ??
        (common['preventive'] is Map
            ? (common['preventive'] as Map)['items'] ??
                (common['preventive'] as Map)['actions']
            : null);

    if (prevItems is List && prevItems.isNotEmpty) {
      for (final it in prevItems) {
        if (it is Map) {
          final aType = it['action_type'] ?? it['action'];
          final aDate = it['action_date'] ?? it['actionDate'];
          final aOut = it['outward_number'] ?? it['outwardNumber'];
          final aNum = it['preventive_number'] ?? it['preventiveNumber'];
          final aName = _sanitizeName(it['name'] ??
              it['person_name'] ??
              it['accusedName'] ??
              it['person'] ??
              safeAccused);
          if (aType != null &&
              aType.toString().isNotEmpty &&
              aName.isNotEmpty) {
            _preventiveActionsList.add({
              'name': aName,
              'action_type': aType.toString(),
              'action_date': aDate?.toString() ?? '',
              'outward_number': aOut?.toString() ?? '',
              'preventive_number': aNum?.toString() ?? '',
              'bond_date':
                  (it['bond_date'] ?? it['bondDate'])?.toString() ?? '',
              'bond_cancellation_date':
                  (it['bond_cancellation_date'] ?? it['bondCancellationDate'])
                          ?.toString() ??
                      '',
            });
          }
        }
      }
    }

    // Fallback from legacy single fields if list was empty
    if (_preventiveActionsList.isEmpty) {
      final prevType = common['preventive_action_type'] ??
          extra['preventive_action_type'] ??
          (common['preventive'] is Map
              ? (common['preventive'] as Map)['action'] ??
                  (common['preventive'] as Map)['action_type']
              : null);
      final prevDate = common['preventive_action_date'] ??
          extra['preventive_action_date'] ??
          (common['preventive'] is Map
              ? (common['preventive'] as Map)['actionDate'] ??
                  (common['preventive'] as Map)['action_date']
              : null);
      final prevOutward = common['preventive_outward_no'] ??
          extra['preventive_outward_no'] ??
          common['preventive_action_outward_no'] ??
          extra['preventive_action_outward_no'] ??
          (common['preventive'] is Map
              ? (common['preventive'] as Map)['outwardNumber'] ??
                  (common['preventive'] as Map)['outward_number']
              : null);

      if (prevType != null &&
          prevType.toString().isNotEmpty &&
          safeAccused.isNotEmpty) {
        _preventiveActionsList.add({
          'name': safeAccused,
          'action_type': prevType.toString(),
          'action_date': prevDate?.toString() ?? '',
          'outward_number': prevOutward?.toString() ?? '',
        });
      }
    }

    if (_preventiveActionsList.isNotEmpty) {
      final first = _preventiveActionsList.first;
      _setField('preventive_action_type', first['action_type']);
      _setField('preventive_action_date', first['action_date']);
      _setField('preventive_outward_no', first['outward_number']);
    }

    // Hydrate Remand & Custody List
    _custodyRecordsList.clear();
    final custodySources = [
      extra['custody_records'],
      common['custody_records'],
      extra['remand_custody'],
      common['remand_custody'],
      extra['custodyInfo'],
      common['custodyInfo'],
      extra['custody'],
      common['custody'],
    ];

    for (final src in custodySources) {
      if (src is List && src.isNotEmpty && _custodyRecordsList.isEmpty) {
        for (final it in src) {
          if (it is Map) {
            final cName = _sanitizeName(it['name'] ??
                it['person_name'] ??
                it['accusedName'] ??
                it['accused_name'] ??
                it['person'] ??
                safeAccused);
            final pcr = it['pcr_days'] ?? it['pcrDays'] ?? '';
            final isMcr = it['mcr'] == true ||
                it['isMcr'] == true ||
                it['mcr'] == 'true' ||
                it['isMcr'] == 'true';
            final isPrBond = it['pr_bond'] == true ||
                it['isPrBond'] == true ||
                it['pr_bond'] == 'true' ||
                it['isPrBond'] == 'true';
            final prBondDt = it['pr_bond_date'] ?? it['prBondDate'] ?? '';
            final isBail = it['bail'] == true ||
                it['isBail'] == true ||
                it['bail'] == 'true' ||
                it['isBail'] == 'true';
            final suretyNm = it['surety_name'] ?? it['suretyName'] ?? '';
            final suretyAge = it['surety_age'] ?? it['suretyAge'] ?? '';
            final suretyGender =
                (it['surety_gender'] ?? it['suretyGender'] ?? '').toString();
            final suretyOcc =
                it['surety_occupation'] ?? it['suretyOccupation'] ?? '';
            final suretyMob = it['surety_mobile'] ??
                it['surety_mobile_no'] ??
                it['suretyMobile'] ??
                '';
            final suretyAadhaar = it['surety_aadhaar'] ??
                it['surety_aadhaar_no'] ??
                it['suretyAadhaar'] ??
                '';
            final suretyPan = it['surety_pan'] ??
                it['surety_pan_no'] ??
                it['suretyPan'] ??
                '';
            final suretyAddr =
                it['surety_address'] ?? it['suretyAddress'] ?? '';
            final suretyRel = (it['surety_relation'] ??
                    it['relation_with_accused'] ??
                    it['suretyRelation'] ??
                    '')
                .toString();
            final isJail = it['jail'] == true ||
                it['isJail'] == true ||
                it['jail'] == 'true' ||
                it['isJail'] == 'true';
            final jailDt = it['jail_date'] ?? it['jailDate'] ?? '';

            if (cName.toString().isNotEmpty ||
                pcr.toString().isNotEmpty ||
                isMcr ||
                isBail) {
              _custodyRecordsList.add({
                'name': cName.toString(),
                'person_name': cName.toString(),
                'accusedName': cName.toString(),
                'pcr_days': pcr.toString(),
                'mcr': isMcr,
                'pr_bond': isPrBond,
                'pr_bond_date': prBondDt.toString(),
                'bail': isBail,
                'surety_name': suretyNm.toString(),
                'surety_age': suretyAge.toString(),
                'surety_gender': suretyGender,
                'surety_occupation': suretyOcc.toString(),
                'surety_mobile': suretyMob.toString(),
                'surety_aadhaar': suretyAadhaar.toString(),
                'surety_pan': suretyPan.toString(),
                'surety_address': suretyAddr.toString(),
                'surety_relation': suretyRel,
                'jail': isJail,
                'jail_date': jailDt.toString(),
              });
            }
          }
        }
      }
    }

    // Also check case persons for remand_custody
    if (_custodyRecordsList.isEmpty) {
      final personsList = extra['persons'] ?? common['persons'];
      if (personsList is List) {
        for (final p in personsList) {
          if (p is Map && p['remand_custody'] is Map) {
            final rc = p['remand_custody'] as Map;
            final pName = p['name'] ?? rc['person_name'] ?? '';
            _custodyRecordsList.add({
              'name': pName.toString(),
              'person_name': pName.toString(),
              'accusedName': pName.toString(),
              'pcr_days': (rc['pcr_days'] ?? rc['pcrDays'] ?? '').toString(),
              'mcr': rc['mcr'] == true || rc['isMcr'] == true,
              'pr_bond': rc['pr_bond'] == true || rc['isPrBond'] == true,
              'pr_bond_date':
                  (rc['pr_bond_date'] ?? rc['prBondDate'] ?? '').toString(),
              'bail': rc['bail'] == true || rc['isBail'] == true,
              'surety_name':
                  (rc['surety_name'] ?? rc['suretyName'] ?? '').toString(),
              'surety_age':
                  (rc['surety_age'] ?? rc['suretyAge'] ?? '').toString(),
              'surety_gender':
                  (rc['surety_gender'] ?? rc['suretyGender'] ?? '').toString(),
              'surety_occupation':
                  (rc['surety_occupation'] ?? rc['suretyOccupation'] ?? '')
                      .toString(),
              'surety_mobile': (rc['surety_mobile'] ??
                      rc['surety_mobile_no'] ??
                      rc['suretyMobile'] ??
                      '')
                  .toString(),
              'surety_aadhaar': (rc['surety_aadhaar'] ??
                      rc['surety_aadhaar_no'] ??
                      rc['suretyAadhaar'] ??
                      '')
                  .toString(),
              'surety_pan': (rc['surety_pan'] ??
                      rc['surety_pan_no'] ??
                      rc['suretyPan'] ??
                      '')
                  .toString(),
              'surety_address':
                  (rc['surety_address'] ?? rc['suretyAddress'] ?? '')
                      .toString(),
              'surety_relation': (rc['surety_relation'] ??
                      rc['relation_with_accused'] ??
                      rc['suretyRelation'] ??
                      '')
                  .toString(),
              'jail': rc['jail'] == true || rc['isJail'] == true,
              'jail_date': (rc['jail_date'] ?? rc['jailDate'] ?? '').toString(),
            });
          }
        }
      }
    }

    // Fallback if legacy flat fields exist
    if (_custodyRecordsList.isEmpty) {
      final pcr = common['pcr_days'] ?? extra['pcr_days'];
      final isMcr = common['mcr'] == true ||
          extra['mcr'] == true ||
          common['mcr'] == 'true';
      final isPrBond = common['pr_bond'] == true ||
          extra['pr_bond'] == true ||
          common['pr_bond'] == 'true';
      final prBondDt = common['pr_bond_date'] ?? extra['pr_bond_date'] ?? '';
      final isBail = common['bail'] == true ||
          extra['bail'] == true ||
          common['bail'] == 'true';
      final suretyNm = common['surety_name'] ?? extra['surety_name'] ?? '';
      final suretyAge = common['surety_age'] ?? extra['surety_age'] ?? '';
      final suretyGender =
          (common['surety_gender'] ?? extra['surety_gender'] ?? '').toString();
      final suretyOcc =
          common['surety_occupation'] ?? extra['surety_occupation'] ?? '';
      final suretyMob = common['surety_mobile'] ?? extra['surety_mobile'] ?? '';
      final suretyAadhaar =
          common['surety_aadhaar'] ?? extra['surety_aadhaar'] ?? '';
      final suretyPan = common['surety_pan'] ?? extra['surety_pan'] ?? '';
      final suretyAddr =
          common['surety_address'] ?? extra['surety_address'] ?? '';
      final suretyRel =
          (common['surety_relation'] ?? extra['surety_relation'] ?? '')
              .toString();
      final isJail = common['jail'] == true ||
          extra['jail'] == true ||
          common['jail'] == 'true';
      final jailDt = common['jail_date'] ?? extra['jail_date'] ?? '';

      if ((pcr != null || isMcr || isBail) && safeAccused.isNotEmpty) {
        _custodyRecordsList.add({
          'name': safeAccused,
          'person_name': safeAccused,
          'accusedName': safeAccused,
          'pcr_days': pcr?.toString() ?? '',
          'mcr': isMcr,
          'pr_bond': isPrBond,
          'pr_bond_date': prBondDt.toString(),
          'bail': isBail,
          'surety_name': suretyNm.toString(),
          'surety_age': suretyAge.toString(),
          'surety_gender': suretyGender,
          'surety_occupation': suretyOcc.toString(),
          'surety_mobile': suretyMob.toString(),
          'surety_aadhaar': suretyAadhaar.toString(),
          'surety_pan': suretyPan.toString(),
          'surety_address': suretyAddr.toString(),
          'surety_relation': suretyRel,
          'jail': isJail,
          'jail_date': jailDt.toString(),
        });
      }
    }

    // Hydrate Scrutiny Pipeline
    final scr = common['scrutiny'] ??
        extra['scrutiny'] ??
        common['scrutiny_pipeline'] ??
        extra['scrutiny_pipeline'];
    if (scr is Map) {
      void hydrateKey(String fieldKey, List<String> aliases) {
        for (final a in aliases) {
          final v = scr[a]?.toString();
          if (v != null && v.isNotEmpty) {
            _setField(fieldKey, v);
            break;
          }
        }
      }

      hydrateKey('sdpo_acp_send_date', ['sdpo_acp_send_date', 'sdpoSend']);
      hydrateKey('sdpo_acp_grant_date', ['sdpo_acp_grant_date', 'sdpoGrant']);
      hydrateKey('addl_sp_dcp_send_date',
          ['addl_sp_dcp_send_date', 'spSend', 'dcpSend']);
      hydrateKey('addl_sp_dcp_grant_date',
          ['addl_sp_dcp_grant_date', 'spGrant', 'dcpGrant']);
      hydrateKey(
          'addl_cp_send_date', ['addl_cp_send_date', 'cpSend', 'addlCpSend']);
      hydrateKey('addl_cp_grant_date',
          ['addl_cp_grant_date', 'cpGrant', 'addlCpGrant']);
      hydrateKey('app_send_date', ['app_send_date', 'appSend']);
      hydrateKey('app_grant_date', ['app_grant_date', 'appGrant']);
    }

    // Hydrate dynamic repeating groups (MPDA, History Sheeter, Road Accident, etc.)
    if (_formDef != null) {
      for (final f in _formDef!.fields
          .where((fd) => fd.fieldType == 'repeating_group')) {
        final noPref =
            f.fieldKey.replaceFirst(RegExp(r'^(mpda_|hs_|rti_|acc_)'), '');
        final candidates = [
          f.fieldKey,
          noPref,
          if (f.fieldKey == 'mpda_accused') ...[
            'accused_persons',
            'accused',
            'accusedList'
          ],
          if (f.fieldKey == 'mpda_gang_members') ...[
            'gang_members',
            'gangMembers'
          ],
          if (f.fieldKey == 'mpda_crime_chart') ...[
            'crime_chart',
            'crime_chart_entries',
            'crimeChart'
          ],
          if (f.fieldKey == 'hs_associates') ...[
            'associates',
            'related_persons'
          ],
          if (f.fieldKey == 'hs_rivals') ...['rivals', 'related_persons'],
          if (f.fieldKey == 'hs_sureties') ...['sureties', 'related_persons'],
          if (f.fieldKey == 'hs_preventive_actions') ...[
            'preventive_actions',
            'preventiveActions'
          ],
          if (f.fieldKey == 'hs_crime_chart') ...[
            'crime_chart',
            'crimes',
            'crimeChart'
          ],
          if (f.fieldKey == 'acc_vehicles') ...[
            'vehicles',
            'accident_vehicles',
            'veh_list'
          ],
          if (f.fieldKey == 'acc_injured') ...[
            'injured',
            'injured_persons',
            'inj_list'
          ],
          if (f.fieldKey == 'acc_deceased') ...[
            'deceased',
            'deceased_persons',
            'dec_list'
          ],
        ];

        dynamic rawList;
        for (final cand in candidates) {
          if (extra[cand] is List && (extra[cand] as List).isNotEmpty) {
            rawList = extra[cand];
            break;
          }
        }

        if (rawList is List) {
          final children = _formDef!.fields
              .where((cf) => cf.parentFieldKey == f.fieldKey)
              .toList();

          final normalizedRows = <Map<String, dynamic>>[];
          for (final rawItem in rawList) {
            if (rawItem is Map) {
              final rowMap = Map<String, dynamic>.from(rawItem);
              for (final child in children) {
                if (rowMap[child.fieldKey] == null) {
                  final childNoPref = child.fieldKey.replaceFirst(
                    RegExp(
                        r'^(mpda_accused_|mpda_|hs_assoc_|hs_rival_|hs_surety_|hs_preventive_|hs_crime_|hs_|rti_|acc_veh_|acc_inj_|acc_dec_|acc_)'),
                    '',
                  );
                  dynamic foundVal = rowMap[childNoPref];
                  if (foundVal == null) {
                    if (childNoPref == 'cast' || childNoPref == 'caste') {
                      foundVal = rowMap['caste'] ?? rowMap['cast'];
                    } else if (childNoPref == 'action_type' ||
                        childNoPref == 'action') {
                      foundVal = rowMap['action_type'] ?? rowMap['action'];
                    } else if (childNoPref == 'cr_no' ||
                        childNoPref == 'crime_cr_no') {
                      foundVal = rowMap['cr_no'] ?? rowMap['crime_cr_no'];
                    } else if (childNoPref == 'mobile' ||
                        childNoPref == 'mobile_no') {
                      foundVal = rowMap['mobile_no'] ?? rowMap['mobile'];
                    } else if (childNoPref == 'number' ||
                        childNoPref == 'vehicle_number') {
                      foundVal = rowMap['vehicle_number'] ??
                          rowMap['veh_number'] ??
                          rowMap['number'];
                    } else if (childNoPref == 'name' ||
                        childNoPref == 'vehicle_name') {
                      foundVal = rowMap['vehicle_name'] ?? rowMap['name'];
                    } else if (childNoPref == 'company' ||
                        childNoPref == 'company_name') {
                      foundVal = rowMap['company_name'] ?? rowMap['company'];
                    } else if (childNoPref == 'company_other' ||
                        childNoPref == 'company_name_other') {
                      foundVal = rowMap['company_name_other'] ??
                          rowMap['company_other'];
                    } else if (childNoPref == 'owner_details' ||
                        childNoPref == 'owner_name_address') {
                      foundVal = rowMap['owner_name_address'] ??
                          rowMap['owner_details'] ??
                          rowMap['owner_name'];
                    } else if (childNoPref == 'driver_details' ||
                        childNoPref == 'driver_name_address') {
                      foundVal = rowMap['driver_name_address'] ??
                          rowMap['driver_details'] ??
                          rowMap['driver_name'];
                    } else if (childNoPref == 'aadhaar' ||
                        childNoPref == 'aadhaar_card') {
                      foundVal = rowMap['aadhaar_card'] ?? rowMap['aadhaar'];
                    } else if (childNoPref == 'pan' ||
                        childNoPref == 'pan_card') {
                      foundVal = rowMap['pan_card'] ?? rowMap['pan'];
                    } else if (childNoPref == 'death_date') {
                      foundVal =
                          rowMap['death_date_display'] ?? rowMap['death_date'];
                    } else if (childNoPref == 'post_mortem' ||
                        childNoPref == 'pm') {
                      foundVal = rowMap['post_mortem'] ?? rowMap['pm'];
                    }
                  }
                  if (foundVal != null) {
                    if (child.fieldType == 'date' ||
                        child.fieldType == 'datetime') {
                      final s = foundVal.toString().trim();
                      final isoMatch =
                          RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(s);
                      if (isoMatch != null) {
                        foundVal =
                            '${isoMatch.group(3)}/${isoMatch.group(2)}/${isoMatch.group(1)}';
                      }
                    }
                    rowMap[child.fieldKey] = foundVal;
                  }
                }
              }
              normalizedRows.add(rowMap);
            }
          }
          if (normalizedRows.isNotEmpty) {
            _values[f.fieldKey] = normalizedRows;
            _values[noPref] = normalizedRows;
          }
        }
      }
    }

    _applySumTotals('');

    if (mounted) {
      setState(() {});
    }
  }

  String _sanitizeName(dynamic val) {
    if (val == null) return '';
    final s = val.toString().trim();
    if (s.isEmpty) return '';
    if (s.startsWith('[{') ||
        s.startsWith('{') ||
        s.contains('name:') ||
        s == 'null' ||
        s == '[]') {
      return '';
    }
    return s;
  }

  void _setField(String key, dynamic val) {
    if (val == null) return;
    final cleanKey = key.trim();
    if (cleanKey.isEmpty) return;
    // A repeater's rows may come back as text (JSON, or the server's
    // Python-style text): read as rows; other text is an older typed answer
    final isRepeater = _formDef?.fields
            .any((f) => f.fieldKey == cleanKey && f.fieldType == 'repeater') ??
        false;
    if (isRepeater && val is String) {
      final saved = RepeaterValue.parse(val);
      val = saved.legacyText ?? saved.rows;
    }
    // Junk strings from older saves (serialized maps, 'null', '[]') are not shown
    if (!isRepeater && val is! List && val is! Map) {
      final rawTrimmed = val.toString().trim();
      if (rawTrimmed.startsWith('[{') ||
          rawTrimmed.startsWith('{') ||
          rawTrimmed.contains('name:') ||
          rawTrimmed == 'null' ||
          rawTrimmed == '[]') {
        return;
      }
    }

    final noPrefix =
        cleanKey.replaceFirst(RegExp(r'^(mpda_|hs_|rti_|acc_)'), '');
    final candidates = <String>{
      cleanKey,
      noPrefix,
      'mpda_$noPrefix',
      'hs_$noPrefix',
      'rti_$noPrefix',
      'acc_$noPrefix',
    };

    if (noPrefix == 'govt_confirmation' ||
        noPrefix == 'government_confirmation') {
      candidates.addAll([
        'government_confirmation',
        'govt_confirmation',
        'mpda_govt_confirmation'
      ]);
    } else if (noPrefix == 'order_revoked' ||
        noPrefix == 'detention_order_revoked') {
      candidates.addAll(
          ['detention_order_revoked', 'order_revoked', 'mpda_order_revoked']);
    } else if (noPrefix == 'io_post' || noPrefix == 'designation') {
      candidates.addAll(
          ['mpda_io_post', 'io_post', 'designation', 'mpda_designation']);
    } else if (noPrefix == 'serious_crimes' ||
        noPrefix == 'serious_crime' ||
        noPrefix == 'total_serious_crimes' ||
        noPrefix == 'total_serious_crime') {
      candidates.addAll([
        'mpda_serious_crimes',
        'serious_crimes',
        'serious_crime',
        'total_serious_crimes',
        'total_serious_crime',
        'mpda_total_serious_crime',
        'mpda_total_serious_crimes',
      ]);
    } else if (noPrefix == 'total_misc_crime' ||
        noPrefix == 'total_misc_crimes' ||
        noPrefix == 'misc_crimes' ||
        noPrefix == 'misc_crime') {
      candidates.addAll([
        'mpda_total_misc_crime',
        'total_misc_crime',
        'total_misc_crimes',
        'misc_crimes',
        'misc_crime',
        'mpda_misc_crimes',
        'mpda_total_misc_crimes',
      ]);
    } else if (noPrefix == 'category_type' || noPrefix == 'categories') {
      candidates.addAll(['categories', 'category_type', 'hs_category_type']);
    } else if (noPrefix == 'category_type_other' ||
        noPrefix == 'category_other') {
      candidates.addAll(
          ['category_other', 'category_type_other', 'hs_category_type_other']);
    } else if (noPrefix == 'nature_of_accident') {
      candidates.addAll(['acc_nature_of_accident', 'nature_of_accident']);
    } else if (noPrefix == 'nature_of_accident_other') {
      candidates
          .addAll(['acc_nature_of_accident_other', 'nature_of_accident_other']);
    } else if (noPrefix == 'vehicle_abandoned') {
      candidates.addAll(['acc_vehicle_abandoned', 'vehicle_abandoned']);
    } else if (noPrefix == 'driver_subsequently_traced') {
      candidates.addAll(
          ['acc_driver_subsequently_traced', 'driver_subsequently_traced']);
    } else if (noPrefix == 'victim_identity_established') {
      candidates.addAll(
          ['acc_victim_identity_established', 'victim_identity_established']);
    } else if (noPrefix == 'eyewitnesses_identity' ||
        noPrefix == 'eye_witnesses_identity') {
      candidates.addAll([
        'acc_eyewitnesses_identity',
        'eye_witnesses_identity',
        'eyewitnesses_identity'
      ]);
    } else if (noPrefix == 'irad') {
      candidates.addAll(['acc_irad', 'irad']);
    } else if (noPrefix == 'irad_date') {
      candidates.addAll(['acc_irad_date', 'irad_date']);
    } else if (noPrefix == 'dar') {
      candidates.addAll(['acc_dar', 'dar']);
    } else if (noPrefix == 'dar_date') {
      candidates.addAll(['acc_dar_date', 'dar_date']);
    }

    for (final k in candidates) {
      final fieldDef = _formDef?.fields.cast<DynamicFieldDef?>().firstWhere(
            (f) => f?.fieldKey == k,
            orElse: () => null,
          );

      String formattedStr = val.toString();
      if (val is List && fieldDef?.fieldType != 'repeating_group') {
        formattedStr = val.join(', ');
      } else if (fieldDef != null &&
          (fieldDef.fieldType == 'date' || fieldDef.fieldType == 'datetime')) {
        final s = val.toString().trim();
        final isoMatch =
            RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:[T\s](\d{2}):(\d{2}))?')
                .firstMatch(s);
        if (isoMatch != null) {
          final y = isoMatch.group(1);
          final m = isoMatch.group(2);
          final d = isoMatch.group(3);
          final hr = isoMatch.group(4);
          final min = isoMatch.group(5);
          if (hr != null && min != null && fieldDef.fieldType == 'datetime') {
            formattedStr = '$d/$m/$y $hr:$min';
          } else {
            formattedStr = '$d/$m/$y';
          }
        }
      }

      // An empty value never wipes a field that already has one
      final isEmptyVal =
          val is! List && val is! Map && formattedStr.trim().isEmpty;
      if (_controllers.containsKey(k)) {
        if (!isEmptyVal || _controllers[k]!.text.trim().isEmpty) {
          _controllers[k]!.text = formattedStr;
        }
      } else if (k == cleanKey && !isEmptyVal && val is! List && val is! Map) {
        _controllers[k] = TextEditingController(text: formattedStr);
      }

      if (fieldDef?.fieldType == 'checkbox') {
        _values[k] = (val == true ||
            val.toString().toLowerCase() == 'true' ||
            val.toString().toLowerCase() == 'yes');
      } else if (fieldDef?.fieldType == 'dropdown') {
        String sVal = val.toString().trim();
        if (sVal.toUpperCase() == 'Y') sVal = 'Yes';
        if (sVal.toUpperCase() == 'N') sVal = 'No';
        _values[k] = sVal;
        if (_controllers.containsKey(k)) {
          _controllers[k]!.text = sVal;
        }
      } else if (!isEmptyVal || !_values.containsKey(k)) {
        _values[k] = val;
      }
    }
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) {
      DynamicFieldDef? firstErrorField;
      for (final f in _formDef?.fields ?? <DynamicFieldDef>[]) {
        if (f.isRequired && _isFieldVisible(f)) {
          final ctrl = _controllers[f.fieldKey];
          final val = ctrl?.text.trim() ?? _values[f.fieldKey];
          final isEmpty = val == null ||
              (val is String && val.trim().isEmpty) ||
              (val is List && val.isEmpty);
          if (isEmpty) {
            firstErrorField = f;
            break;
          }
        }
      }

      final missingSections = <String>{
        for (final f in _formDef?.fields ?? <DynamicFieldDef>[])
          if (f.isRequired &&
              _isFieldVisible(f) &&
              _fieldEmpty(f) &&
              (f.section ?? '').isNotEmpty)
            f.section!,
      };
      setState(() => _errorSections
        ..clear()
        ..addAll(missingSections));

      if (firstErrorField != null) {
        final sec = firstErrorField.section;
        if (sec != null && sec.isNotEmpty) {
          setState(() {
            _collapsedReadOnlySections.remove(sec);
            _readOnlyAllCollapsed = false;
            _formStep = _stepOfSection(sec);
            _formSub = 0;
            for (var i = 0; i < _lastSteps.length; i++) {
              final j = _lastSteps[i].indexWhere((x) => x.keys.contains(sec));
              if (j >= 0) {
                _formStep = i;
                _formSub = j;
                break;
              }
            }
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            firstErrorField != null
                ? 'Please fill required field: ${firstErrorField.fieldLabel}'
                : 'Please fill the required fields and fix the ones marked in red.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final auth = context.read<AuthProvider>();
      final caseNo = _controllers['cr_number']?.text.trim() ??
          _controllers['crNo']?.text.trim() ??
          _controllers['case_number']?.text.trim() ??
          widget.existingRecord?.caseNumber ??
          'CR/${DateTime.now().millisecondsSinceEpoch}';

      final title = _controllers['title']?.text.trim().isNotEmpty == true
          ? _controllers['title']!.text.trim()
          : '${widget.subCategory ?? widget.moduleLabel} $caseNo';

      final loc = _controllers['crime_spot_address']?.text.trim() ??
          _controllers['spotAddress']?.text.trim() ??
          _controllers['location']?.text.trim() ??
          '';

      final complainant = _controllers['complainant_name']?.text.trim() ??
          _controllers['complainant']?.text.trim() ??
          '';

      final accused = _accusedList.isNotEmpty
          ? _accusedList
              .map((a) => _sanitizeName(a['name']))
              .where((n) => n.isNotEmpty)
              .join(', ')
          : _sanitizeName(_controllers['accused_name']?.text ??
              _controllers['accused']?.text);

      final List<Map<String, dynamic>> finalAccusedList = [];
      if (_accusedList.isNotEmpty) {
        for (final a in _accusedList) {
          finalAccusedList.add(Map<String, dynamic>.from(a));
        }
      } else if (accused.isNotEmpty) {
        finalAccusedList.add({
          'name': accused,
          'age': _controllers['accused_age']?.text.trim(),
          'gender': _values['accused_gender'] ??
              _controllers['accused_gender']?.text.trim() ??
              '',
          'occupation': _controllers['accused_occupation']?.text.trim(),
          'mobile': _controllers['accused_mobile']?.text.trim(),
          'aadhaar': _controllers['accused_aadhaar']?.text.trim(),
          'pan': _controllers['accused_pan']?.text.trim(),
          'religion': _controllers['accused_religion']?.text.trim(),
          'caste': _controllers['accused_caste']?.text.trim(),
          'address': _controllers['accused_address']?.text.trim(),
          'role': 'accused',
        });
      }

      // Prune any hidden fields before compiling payload
      _pruneHiddenFields();

      // Compile dynamic extra fields values (dropping hidden fields)
      final dynamicExtraVals = <String, dynamic>{};
      for (final f in _formDef?.fields ?? <DynamicFieldDef>[]) {
        if (f.fieldSource == 'custom' && _isFieldVisible(f)) {
          // A repeater's rows live in _values; its text box copy is not kept
          final val = f.fieldType == 'repeater'
              ? _values[f.fieldKey]
              : _controllers[f.fieldKey]?.text ?? _values[f.fieldKey];
          if (val != null) {
            dynamicExtraVals[f.fieldKey] = val;
          }
        }
      }

      // Capture all form field values (common and custom)
      final allFormFields = <String, dynamic>{};
      for (final entry in _controllers.entries) {
        allFormFields[entry.key] = entry.value.text;
      }
      for (final entry in _values.entries) {
        if (entry.value != null) {
          allFormFields[entry.key] = entry.value;
        }
      }

      // Arrest structure
      final List<Map<String, dynamic>> finalArrestsList = [];
      if (_arrestRecordsList.isNotEmpty) {
        for (final a in _arrestRecordsList) {
          finalArrestsList.add(Map<String, dynamic>.from(a));
        }
      } else {
        final arrestedPerson =
            _controllers['arrested_person_name']?.text.trim() ??
                _values['arrested_person_name']?.toString().trim() ??
                '';
        if (arrestedPerson.isNotEmpty) {
          finalArrestsList.add({
            'arrested_person_name': arrestedPerson,
            'person_name': arrestedPerson,
            'name': arrestedPerson,
            'arrest_datetime': _controllers['arrest_datetime']?.text.trim(),
            'sec_47_48_bnss': _values['sec_47_48_bnss'] == true ||
                _controllers['sec_47_48_bnss']?.text.toLowerCase() == 'true',
            'relative_friend_name':
                _controllers['relative_friend_name']?.text.trim(),
            'relative_friend_relation':
                _controllers['relative_friend_relation']?.text.trim(),
            'release_on_notice': _values['release_on_notice'] == true ||
                _controllers['release_on_notice']?.text.toLowerCase() == 'true',
            'release_on_notice_datetime':
                _controllers['release_on_notice_datetime']?.text.trim(),
            'anticipatory_bail': _values['anticipatory_bail'] == true ||
                _controllers['anticipatory_bail']?.text.toLowerCase() == 'true',
            'anticipatory_bail_datetime':
                _controllers['anticipatory_bail_datetime']?.text.trim(),
            'death_of_accused': _values['death_of_accused'] == true ||
                _controllers['death_of_accused']?.text.toLowerCase() == 'true',
            'death_of_accused_datetime':
                _controllers['death_of_accused_datetime']?.text.trim(),
          });
        }
      }

      if (finalArrestsList.isNotEmpty) {
        final first = finalArrestsList.first;
        allFormFields['arrested_person_name'] = first['arrested_person_name'];
        allFormFields['arrest_datetime'] = first['arrest_datetime'];
        allFormFields['sec_47_48_bnss'] = first['sec_47_48_bnss'];
        allFormFields['relative_friend_name'] = first['relative_friend_name'];
        allFormFields['relative_friend_relation'] =
            first['relative_friend_relation'];
        allFormFields['release_on_notice'] = first['release_on_notice'];
        allFormFields['release_on_notice_datetime'] =
            first['release_on_notice_datetime'];
        allFormFields['anticipatory_bail'] = first['anticipatory_bail'];
        allFormFields['anticipatory_bail_datetime'] =
            first['anticipatory_bail_datetime'];
        allFormFields['death_of_accused'] = first['death_of_accused'];
        allFormFields['death_of_accused_datetime'] =
            first['death_of_accused_datetime'];
      }
      allFormFields['arrests'] = finalArrestsList;
      allFormFields['arrest_records'] = finalArrestsList;

      // Charges structure
      final chargesMap = <String, Map<String, dynamic>>{};
      var chSeq = 1;
      for (final entry in _selectedCharges.entries) {
        if (entry.value.isNotEmpty) {
          chargesMap['charge-${chSeq++}'] = {
            'act': entry.key,
            'sections': entry.value.toList(),
          };
        }
      }

      // Discharged Accused data
      final dischargeByAccused = <String, bool>{};
      final dischargeDetails = <String, Map<String, dynamic>>{};
      final dischargesList = <Map<String, dynamic>>[];

      for (final name in _dischargedAccusedList) {
        final n = name.trim();
        if (n.isNotEmpty) {
          final dDate = _dischargeDateControllers[n]?.text.trim() ?? '';
          dischargeByAccused[n] = true;
          dischargeDetails[n] = {
            'date': dDate,
          };
          dischargesList.add({
            'name': n,
            'is_discharged': true,
            'discharge_date': dDate,
            'date': dDate,
          });
        }
      }

      final List<Map<String, dynamic>> finalSuspectedList = [];
      if (_suspectedAccusedList.isNotEmpty) {
        for (final s in _suspectedAccusedList) {
          finalSuspectedList.add(Map<String, dynamic>.from(s));
        }
      } else {
        final suspectedName =
            _controllers['suspected_accused_name']?.text.trim() ??
                _controllers['suspected_name']?.text.trim() ??
                '';
        if (suspectedName.isNotEmpty) {
          finalSuspectedList.add({
            'name': suspectedName,
            'age': _controllers['suspected_accused_age']?.text.trim(),
            'gender': _values['suspected_accused_gender'] ??
                _controllers['suspected_accused_gender']?.text.trim() ??
                '',
            'occupation':
                _controllers['suspected_accused_occupation']?.text.trim(),
            'mobile': _controllers['suspected_accused_mobile']?.text.trim(),
            'aadhaar': _controllers['suspected_accused_aadhaar']?.text.trim(),
            'pan': _controllers['suspected_accused_pan']?.text.trim(),
            'religion': _controllers['suspected_accused_religion']?.text.trim(),
            'caste': _controllers['suspected_accused_caste']?.text.trim(),
            'address': _controllers['suspected_accused_address']?.text.trim(),
            'role': 'suspected_accused',
          });
        }
      }
      if (finalSuspectedList.isNotEmpty) {
        final first = finalSuspectedList.first;
        allFormFields['suspected_accused_name'] = first['name'];
        allFormFields['suspected_accused_age'] = first['age'];
        allFormFields['suspected_accused_gender'] = first['gender'];
        allFormFields['suspected_accused_occupation'] = first['occupation'];
        allFormFields['suspected_accused_mobile'] = first['mobile'];
        allFormFields['suspected_accused_aadhaar'] = first['aadhaar'];
        allFormFields['suspected_accused_pan'] = first['pan'];
        allFormFields['suspected_accused_religion'] = first['religion'];
        allFormFields['suspected_accused_caste'] = first['caste'];
        allFormFields['suspected_accused_address'] = first['address'];
      }
      allFormFields['suspectedAccused'] = finalSuspectedList;
      allFormFields['suspected_accused'] = finalSuspectedList;

      // Unidentified Accused packaging
      final List<Map<String, dynamic>> finalUnidentifiedList = [];
      if (_unidentifiedAccusedList.isNotEmpty) {
        for (final u in _unidentifiedAccusedList) {
          finalUnidentifiedList.add(Map<String, dynamic>.from(u));
        }
      } else {
        final approxAge = _controllers['approximate_age']?.text.trim() ?? '';
        final skinCol = _controllers['skin_colour']?.text.trim() ?? '';
        final identMark =
            _controllers['identification_mark']?.text.trim() ?? '';
        final desc = _controllers['description']?.text.trim() ?? '';
        if (approxAge.isNotEmpty ||
            skinCol.isNotEmpty ||
            identMark.isNotEmpty ||
            desc.isNotEmpty) {
          finalUnidentifiedList.add({
            'approximate_age': approxAge,
            'gender': _values['unidentified_gender'] ??
                _controllers['unidentified_gender']?.text.trim() ??
                '',
            'skin_colour': skinCol,
            'possible_occupation':
                _controllers['possible_occupation']?.text.trim() ?? '',
            'identification_mark': identMark,
            'height': _controllers['height']?.text.trim() ?? '',
            'description': desc,
            'address': _controllers['unidentified_address']?.text.trim() ?? '',
            'role': 'unidentified_accused',
          });
        }
      }
      if (finalUnidentifiedList.isNotEmpty) {
        final first = finalUnidentifiedList.first;
        allFormFields['approximate_age'] = first['approximate_age'];
        allFormFields['unidentified_gender'] = first['gender'];
        allFormFields['skin_colour'] = first['skin_colour'];
        allFormFields['possible_occupation'] = first['possible_occupation'];
        allFormFields['identification_mark'] = first['identification_mark'];
        allFormFields['height'] = first['height'];
        allFormFields['description'] = first['description'];
      }
      allFormFields['unidentifiedList'] = finalUnidentifiedList;
      allFormFields['unidentified_accused'] = finalUnidentifiedList;

      final isUnknown = _unknownAccusedList.isNotEmpty ||
          _values['is_unknown_accused'] == true ||
          _controllers['is_unknown_accused']?.text.toLowerCase() == 'true';
      allFormFields['is_unknown_accused'] = isUnknown;
      allFormFields['isUnknownAccused'] = isUnknown;
      allFormFields['isUnknownUntraced'] = isUnknown;
      allFormFields['unknown_accused'] = _unknownAccusedList;
      allFormFields['unknownAccused'] = _unknownAccusedList;

      // Procedural checklists (Panchanama)
      final proceduralList = <Map<String, dynamic>>[];
      final proceduralChecks = <String, bool>{};
      final proceduralDates = <String, String>{};
      for (final entry in _panchanamaKeyToName.entries) {
        final key = entry.key;
        final name = entry.value;
        final isChecked = _values[key] == true ||
            _controllers[key]?.text.toLowerCase() == 'true' ||
            _values['chk$name'] == true;
        final dt = _controllers['${key}_date']?.text.trim() ??
            _values['${key}_date']?.toString().trim() ??
            '';
        if (isChecked) {
          final effectiveDt = dt.isNotEmpty
              ? dt
              : DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
          proceduralChecks[name] = true;
          proceduralDates[name] = effectiveDt;
          proceduralList.add({
            'item_name': name,
            'is_checked': true,
            'event_datetime': effectiveDt,
          });
        }
      }
      allFormFields['procedural_checklists'] = proceduralList;
      allFormFields['proceduralChecks'] = proceduralChecks;
      allFormFields['proceduralDates'] = proceduralDates;

      // Preventive Action packaging
      final List<Map<String, dynamic>> prevActionsToSubmit = [];
      for (final item in _preventiveActionsList) {
        final name = item['name']?.toString().trim() ?? '';
        final actType = item['action_type']?.toString().trim() ?? '';
        final actDate = item['action_date']?.toString().trim() ?? '';
        final outward = item['outward_number']?.toString().trim() ?? '';
        if (actType.isNotEmpty) {
          final effectiveDate = actDate.isNotEmpty ? actDate : '';
          prevActionsToSubmit.add({
            'name': name,
            'accusedName': name,
            'person_name': name,
            'existing_person_id':
                item['existing_person_id'] ?? item['person_id'],
            'person_id': item['person_id'],
            'action': actType,
            'action_type': actType,
            'actionDate': effectiveDate,
            'action_date': effectiveDate,
            'outwardNumber': outward,
            'outward_number': outward,
            'bond_date': item['bond_date'],
            'bondDate': item['bond_date'],
            'bond_cancellation_date': item['bond_cancellation_date'],
            'bondCancellationDate': item['bond_cancellation_date'],
            'preventive_number': item['preventive_number'],
            'preventiveNumber': item['preventive_number'],
          });
        }
      }

      // Fallback if list was empty but individual controllers were filled
      if (prevActionsToSubmit.isEmpty) {
        final prevType = _controllers['preventive_action_type']?.text.trim() ??
            _values['preventive_action_type']?.toString().trim() ??
            '';
        final prevDate = _controllers['preventive_action_date']?.text.trim() ??
            _values['preventive_action_date']?.toString().trim() ??
            '';
        final prevOutward =
            _controllers['preventive_outward_no']?.text.trim() ??
                _values['preventive_outward_no']?.toString().trim() ??
                '';
        if (prevType.isNotEmpty) {
          final effectiveDate = prevDate.isNotEmpty ? prevDate : '';
          prevActionsToSubmit.add({
            'name': accused,
            'accusedName': accused,
            'person_name': accused,
            'action': prevType,
            'action_type': prevType,
            'actionDate': effectiveDate,
            'action_date': effectiveDate,
            'outwardNumber': prevOutward,
            'outward_number': prevOutward,
          });
        }
      }

      if (prevActionsToSubmit.isNotEmpty) {
        final first = prevActionsToSubmit.first;
        allFormFields['preventive_action_type'] = first['action_type'];
        allFormFields['preventive_action_date'] = first['action_date'];
        allFormFields['preventive_outward_no'] = first['outward_number'];
        allFormFields['preventive_action_outward_no'] = first['outward_number'];
        allFormFields['preventive_actions'] = prevActionsToSubmit;
        allFormFields['preventive_action_items'] = prevActionsToSubmit;
        allFormFields['preventive'] = {
          'items': prevActionsToSubmit,
          'actions': prevActionsToSubmit,
          'action': first['action_type'],
          'action_type': first['action_type'],
          'actionDate': first['action_date'],
          'action_date': first['action_date'],
          'outwardNumber': first['outward_number'],
          'outward_number': first['outward_number'],
        };
      } else {
        allFormFields['preventive_actions'] = [];
        allFormFields['preventive_action_items'] = [];
      }

      // Remand & Custody packaging
      final List<Map<String, dynamic>> custodyToSubmit = [];
      for (final item in _custodyRecordsList) {
        final name = item['name']?.toString().trim() ?? '';
        if (name.isNotEmpty) {
          custodyToSubmit.add({
            'name': name,
            'accusedName': name,
            'person_name': name,
            'pcr_days': item['pcr_days']?.toString().trim(),
            'pcrDays': item['pcr_days']?.toString().trim(),
            'mcr': item['mcr'] == true,
            'isMcr': item['mcr'] == true,
            'pr_bond': item['pr_bond'] == true,
            'isPrBond': item['pr_bond'] == true,
            'pr_bond_date': item['pr_bond_date']?.toString().trim(),
            'prBondDate': item['pr_bond_date']?.toString().trim(),
            'bail': item['bail'] == true,
            'isBail': item['bail'] == true,
            'surety_name': item['surety_name']?.toString().trim(),
            'suretyName': item['surety_name']?.toString().trim(),
            'surety_age': item['surety_age']?.toString().trim(),
            'suretyAge': item['surety_age']?.toString().trim(),
            'surety_gender': item['surety_gender']?.toString().trim(),
            'suretyGender': item['surety_gender']?.toString().trim(),
            'surety_occupation': item['surety_occupation']?.toString().trim(),
            'suretyOccupation': item['surety_occupation']?.toString().trim(),
            'surety_mobile': item['surety_mobile']?.toString().trim(),
            'suretyMobile': item['surety_mobile']?.toString().trim(),
            'surety_aadhaar': item['surety_aadhaar']?.toString().trim(),
            'suretyAadhaar': item['surety_aadhaar']?.toString().trim(),
            'surety_pan': item['surety_pan']?.toString().trim(),
            'suretyPan': item['surety_pan']?.toString().trim(),
            'surety_address': item['surety_address']?.toString().trim(),
            'suretyAddress': item['surety_address']?.toString().trim(),
            'surety_relation': item['surety_relation']?.toString().trim(),
            'suretyRelation': item['surety_relation']?.toString().trim(),
            'relation_with_accused': item['surety_relation']?.toString().trim(),
            'jail': item['jail'] == true,
            'isJail': item['jail'] == true,
            'jail_date': item['jail_date']?.toString().trim(),
            'jailDate': item['jail_date']?.toString().trim(),
          });
        }
      }

      if (custodyToSubmit.isNotEmpty) {
        final first = custodyToSubmit.first;
        allFormFields['pcr_days'] = first['pcr_days'];
        allFormFields['mcr'] = first['mcr'];
        allFormFields['pr_bond'] = first['pr_bond'];
        allFormFields['pr_bond_date'] = first['pr_bond_date'];
        allFormFields['bail'] = first['bail'];
        allFormFields['surety_name'] = first['surety_name'];
        allFormFields['surety_age'] = first['surety_age'];
        allFormFields['surety_gender'] = first['surety_gender'];
        allFormFields['surety_occupation'] = first['surety_occupation'];
        allFormFields['surety_mobile'] = first['surety_mobile'];
        allFormFields['surety_aadhaar'] = first['surety_aadhaar'];
        allFormFields['surety_pan'] = first['surety_pan'];
        allFormFields['surety_address'] = first['surety_address'];
        allFormFields['surety_relation'] = first['surety_relation'];
        allFormFields['jail'] = first['jail'];
        allFormFields['jail_date'] = first['jail_date'];

        allFormFields['custody_records'] = custodyToSubmit;
        allFormFields['remand_custody'] = custodyToSubmit;
        allFormFields['custodyInfo'] = custodyToSubmit;
        allFormFields['custody'] = custodyToSubmit;
      } else {
        allFormFields['custody_records'] = [];
        allFormFields['remand_custody'] = [];
        allFormFields['custodyInfo'] = [];
        allFormFields['custody'] = [];
      }

      // Scrutiny Pipeline packaging
      final scrutinyMap = {
        'sdpo_acp_send_date': _controllers['sdpo_acp_send_date']?.text.trim() ??
            _values['sdpo_acp_send_date']?.toString().trim() ??
            '',
        'sdpoSend': _controllers['sdpo_acp_send_date']?.text.trim() ??
            _values['sdpo_acp_send_date']?.toString().trim() ??
            '',
        'sdpo_acp_grant_date':
            _controllers['sdpo_acp_grant_date']?.text.trim() ??
                _values['sdpo_acp_grant_date']?.toString().trim() ??
                '',
        'sdpoGrant': _controllers['sdpo_acp_grant_date']?.text.trim() ??
            _values['sdpo_acp_grant_date']?.toString().trim() ??
            '',
        'addl_sp_dcp_send_date':
            _controllers['addl_sp_dcp_send_date']?.text.trim() ??
                _values['addl_sp_dcp_send_date']?.toString().trim() ??
                '',
        'dcpSend': _controllers['addl_sp_dcp_send_date']?.text.trim() ??
            _values['addl_sp_dcp_send_date']?.toString().trim() ??
            '',
        'addl_sp_dcp_grant_date':
            _controllers['addl_sp_dcp_grant_date']?.text.trim() ??
                _values['addl_sp_dcp_grant_date']?.toString().trim() ??
                '',
        'dcpGrant': _controllers['addl_sp_dcp_grant_date']?.text.trim() ??
            _values['addl_sp_dcp_grant_date']?.toString().trim() ??
            '',
        'addl_cp_send_date': _controllers['addl_cp_send_date']?.text.trim() ??
            _values['addl_cp_send_date']?.toString().trim() ??
            '',
        'addlCpSend': _controllers['addl_cp_send_date']?.text.trim() ??
            _values['addl_cp_send_date']?.toString().trim() ??
            '',
        'addl_cp_grant_date': _controllers['addl_cp_grant_date']?.text.trim() ??
            _values['addl_cp_grant_date']?.toString().trim() ??
            '',
        'addlCpGrant': _controllers['addl_cp_grant_date']?.text.trim() ??
            _values['addl_cp_grant_date']?.toString().trim() ??
            '',
        'app_send_date': _controllers['app_send_date']?.text.trim() ??
            _values['app_send_date']?.toString().trim() ??
            '',
        'appSend': _controllers['app_send_date']?.text.trim() ??
            _values['app_send_date']?.toString().trim() ??
            '',
        'app_grant_date': _controllers['app_grant_date']?.text.trim() ??
            _values['app_grant_date']?.toString().trim() ??
            '',
        'appGrant': _controllers['app_grant_date']?.text.trim() ??
            _values['app_grant_date']?.toString().trim() ??
            '',
      };
      allFormFields['scrutiny'] = scrutinyMap;
      allFormFields['scrutiny_pipeline'] = scrutinyMap;

      // Build structured sub-documents
      final compData = <String, dynamic>{
        'name': complainant,
        'age': _controllers['complainant_age']?.text.trim() ?? '',
        'gender': _values['complainant_gender'] ??
            _controllers['complainant_gender']?.text.trim() ??
            'Male',
        'occupation': _controllers['complainant_occupation']?.text.trim() ?? '',
        'occ': _controllers['complainant_occupation']?.text.trim() ?? '',
        'mobile': _controllers['complainant_mobile']?.text.trim() ?? '',
        'aadhaar': _controllers['complainant_aadhaar']?.text.trim() ?? '',
        'pan': _controllers['complainant_pan']?.text.trim() ?? '',
        'religion': _controllers['complainant_religion']?.text.trim() ?? '',
        'caste': _controllers['complainant_caste']?.text.trim() ?? '',
        'address': _controllers['complainant_address']?.text.trim() ?? '',
      };

      final deceasedName = _controllers['deceased_name']?.text.trim() ?? '';
      final deceasedData = <String, dynamic>{
        'name': deceasedName,
        'age': _controllers['deceased_age']?.text.trim() ?? '',
        'gender': _values['deceased_gender'] ??
            _controllers['deceased_gender']?.text.trim() ??
            'Male',
        'occupation': _controllers['deceased_occupation']?.text.trim() ?? '',
        'occ': _controllers['deceased_occupation']?.text.trim() ?? '',
        'mobile': _controllers['deceased_mobile']?.text.trim() ?? '',
        'aadhaar': _controllers['deceased_aadhaar']?.text.trim() ?? '',
        'pan': _controllers['deceased_pan']?.text.trim() ?? '',
        'religion': _controllers['deceased_religion']?.text.trim() ?? '',
        'caste': _controllers['deceased_caste']?.text.trim() ?? '',
        'address': _controllers['deceased_address']?.text.trim() ?? '',
      };

      final caseRespData = <String, dynamic>{
        'ioDesig':
            _controllers['io_designation']?.text.trim().isNotEmpty == true
                ? _controllers['io_designation']!.text.trim()
                : 'PSI',
        'ioName': _controllers['io_name']?.text.trim().isNotEmpty == true
            ? _controllers['io_name']!.text.trim()
            : auth.displayName,
        'regDesig':
            _controllers['registered_by_designation']?.text.trim().isNotEmpty ==
                    true
                ? _controllers['registered_by_designation']!.text.trim()
                : 'HC',
        'regName':
            _controllers['registered_by_name']?.text.trim().isNotEmpty == true
                ? _controllers['registered_by_name']!.text.trim()
                : auth.displayName,
        'cctvValue': (_values['cctv_available'] == true ||
                _values['cctv_checked'] == true ||
                _controllers['cctv_available']?.text.toLowerCase() == 'true')
            ? 'Yes'
            : 'No',
        'cctvDateTime':
            _controllers['cctv_collected_datetime']?.text.trim() ?? '',
      };

      final courtData = <String, dynamic>{
        'chargeSheetNumber': _controllers['charge_sheet_no']?.text.trim() ?? '',
        'chargeSheetDate': _controllers['charge_sheet_date']?.text.trim() ?? '',
        'ccStNumber': _controllers['cc_st_number']?.text.trim() ?? '',
        'finalSummary': _values['final_summary'] ??
            _controllers['final_summary']?.text.trim() ??
            '',
        'quashedHighCourt':
            _controllers['quashed_high_court']?.text.trim() ?? 'No',
      };

      final List<Map<String, dynamic>> seizuresList = [];
      final seizedDesc =
          _controllers['seized_property_description']?.text.trim() ??
              _controllers['seized_property_type']?.text.trim() ??
              '';
      if (seizedDesc.isNotEmpty || _values['seized_property_type'] != null) {
        seizuresList.add({
          'desc': seizedDesc.isNotEmpty ? seizedDesc : 'Incriminating Articles',
          'property':
              seizedDesc.isNotEmpty ? seizedDesc : 'Incriminating Articles',
          'fromWhom':
              _controllers['seized_from_person']?.text.trim() ?? 'Crime Spot',
          'quantity': _controllers['seized_quantity']?.text.trim() ?? '1',
          'estValue': _controllers['seized_value']?.text.trim() ?? '5000',
          'status': _values['seized_status'] ??
              _controllers['seized_status']?.text.trim() ??
              'In Police Custody',
          'custodyLoc': 'Police Station Malkhana',
          'recoveryDate': DateFormat('dd/MM/yyyy').format(DateTime.now()),
        });
      }

      // Build commonForm document map for full backward compatibility
      final commonFormDoc = <String, dynamic>{
        ...allFormFields,
        'crNo': caseNo,
        'regDate': DateFormat('dd/MM/yyyy').format(
            isEdit ? widget.existingRecord!.incidentDate : DateTime.now()),
        'incidentDate': DateFormat('dd/MM/yyyy').format(
            isEdit ? widget.existingRecord!.incidentDate : DateTime.now()),
        'spotVillage':
            _controllers['village_town']?.text.trim().isNotEmpty == true
                ? _controllers['village_town']!.text.trim()
                : loc,
        'spotArea': _controllers['area_name']?.text.trim() ?? '',
        'spotAddress': loc,
        'charges': chargesMap,
        'complainant': compData,
        'deceased': deceasedData,
        'caseResponsibility': caseRespData,
        'court': courtData,
        'scrutiny': scrutinyMap,
        'accused': finalAccusedList,
        'suspectedAccused': finalSuspectedList,
        'unidentifiedList': finalUnidentifiedList,
        'unidentified_accused': finalUnidentifiedList,
        'isUnknownAccused': isUnknown,
        'is_unknown_accused': isUnknown,
        'isUnknownUntraced': isUnknown,
        'unknown_accused': _unknownAccusedList,
        'unknownAccused': _unknownAccusedList,
        'dischargeByAccused': dischargeByAccused,
        'dischargeDetails': dischargeDetails,
        'discharges': dischargesList,
        'arrests': finalArrestsList,
        'arrest_records': finalArrestsList,
        'arrestRelease': finalArrestsList,
        'preventive_actions': prevActionsToSubmit,
        'preventive_action_items': prevActionsToSubmit,
        'custody_records': custodyToSubmit,
        'remand_custody': custodyToSubmit,
        'custodyInfo': custodyToSubmit,
        'seizures': seizuresList,
        'proceduralChecks': proceduralChecks,
        'proceduralDates': proceduralDates,
        'dynamic_extra_fields': dynamicExtraVals,
      };

      final extraFields = Map<String, dynamic>.from(
        widget.existingRecord?.extraFields ?? {},
      );
      extraFields.addAll(allFormFields);
      extraFields['commonForm'] = commonFormDoc;
      extraFields['charges'] = chargesMap;
      extraFields['complainant'] = compData;
      extraFields['deceased'] = deceasedData;
      extraFields['caseResponsibility'] = caseRespData;
      extraFields['court'] = courtData;
      extraFields['scrutiny'] = scrutinyMap;
      extraFields['accused'] = finalAccusedList;
      extraFields['suspectedAccused'] = finalSuspectedList;
      extraFields['unidentifiedList'] = finalUnidentifiedList;
      extraFields['unidentified_accused'] = finalUnidentifiedList;
      extraFields['is_unknown_accused'] = isUnknown;
      extraFields['isUnknownAccused'] = isUnknown;
      extraFields['isUnknownUntraced'] = isUnknown;
      extraFields['unknown_accused'] = _unknownAccusedList;
      extraFields['unknownAccused'] = _unknownAccusedList;
      extraFields['extra_field_values'] = dynamicExtraVals;
      extraFields['dischargeByAccused'] = dischargeByAccused;
      extraFields['dischargeDetails'] = dischargeDetails;
      extraFields['discharges'] = dischargesList;
      extraFields['arrests'] = finalArrestsList;
      extraFields['arrest_records'] = finalArrestsList;
      extraFields['arrestRelease'] = finalArrestsList;
      extraFields['preventive_actions'] = prevActionsToSubmit;
      extraFields['preventive_action_items'] = prevActionsToSubmit;
      extraFields['custody_records'] = custodyToSubmit;
      extraFields['remand_custody'] = custodyToSubmit;
      extraFields['custodyInfo'] = custodyToSubmit;
      extraFields['seizures'] = seizuresList;
      extraFields['proceduralChecks'] = proceduralChecks;
      extraFields['proceduralDates'] = proceduralDates;
      extraFields['is_discharged'] = _dischargedAccusedList.isNotEmpty;
      extraFields['lastEditedBy'] = auth.displayName;
      extraFields['lastEditedAt'] = DateTime.now().toIso8601String();

      // Independent modules (N.C., RTI, MPDA, A.D. ...) save through their own API
      if (widget.onSubmitCustom != null) {
        try {
          final payload = Map<String, dynamic>.from(allFormFields);
          final res = await widget.onSubmitCustom!(payload, isEdit);
          if (!mounted) return;
          if (res != null && res.containsKey('error')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  res['error'].toString(),
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: AppColors.dangerRed,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isEdit ? 'Updated successfully!' : 'Saved successfully!',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: AppColors.successGreen,
              ),
            );
            Navigator.pop(context, true);
          }
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error saving: $e',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.dangerRed,
            ),
          );
        }
        return;
      }

      final record = ModuleRecord(
        id: isEdit
            ? widget.existingRecord!.id
            : '${DateTime.now().millisecondsSinceEpoch}',
        moduleKey: widget.moduleKey,
        title: title,
        caseNumber: caseNo,
        description: _controllers['brief_description']?.text ?? '',
        complainant: complainant,
        accused: accused,
        location: loc,
        incidentDate:
            isEdit ? widget.existingRecord!.incidentDate : DateTime.now(),
        priority: isEdit ? widget.existingRecord!.priority : 'Medium',
        status: isEdit ? widget.existingRecord!.status : 'Pending',
        assignedOfficer:
            isEdit ? widget.existingRecord!.assignedOfficer : auth.displayName,
        subCategory: widget.subCategory ?? widget.moduleLabel,
        createdAt: isEdit ? widget.existingRecord!.createdAt : DateTime.now(),
        extraFields: extraFields,
        stationName: auth.stationName,
        createdBy: auth.uid,
        assignedOfficerUid: auth.uid,
      );

      try {
        final success = await _caseService.saveCase(record, isCreate: !isEdit);
        if (!mounted) return;

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEdit
                    ? 'Case updated successfully!'
                    : 'Case registered in Database!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.successGreen,
            ),
          );
          Navigator.pop(context, record);
        } else {
          // The server's reason, e.g. a CR number already used in this tab
          throw Exception(
              _caseService.lastSaveError ?? 'Backend returned failure status.');
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save case: ${e.toString().replaceFirst('Exception: ', '')}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.navyDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.readOnly
                  ? (widget.existingRecord?.caseNumber.isNotEmpty == true
                      ? widget.existingRecord!.caseNumber
                      : '${widget.subCategory ?? widget.moduleLabel} Details')
                  : (isEdit
                      ? 'Edit ${widget.subCategory ?? widget.moduleLabel}'
                      : '${widget.subCategory ?? widget.moduleLabel} Registration'),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            Text(
              widget.subCategory ?? widget.moduleLabel,
              style: GoogleFonts.poppins(
                  fontSize: 11, color: AppColors.lightSubText),
            ),
          ],
        ),
        actions: [
          if (widget.existingRecord != null) ...[
            if (widget.readOnly)
              FilledButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    AppTheme.fadeSlideRoute(
                      page: DynamicFormScreen(
                        categoryId: widget.categoryId,
                        moduleLabel: widget.moduleLabel,
                        moduleKey: widget.moduleKey,
                        subCategory: widget.subCategory,
                        existingRecord: widget.existingRecord,
                        readOnly: false,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_note_rounded,
                    size: 16, color: Colors.white),
                label: Text(
                  'Edit',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navyMid,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    AppTheme.fadeSlideRoute(
                      page: DynamicFormScreen(
                        categoryId: widget.categoryId,
                        moduleLabel: widget.moduleLabel,
                        moduleKey: widget.moduleKey,
                        subCategory: widget.subCategory,
                        existingRecord: widget.existingRecord,
                        readOnly: true,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility_outlined,
                    size: 16, color: AppColors.navyMid),
                label: Text(
                  'View Entered Only',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navyMid,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navyMid,
                  side: const BorderSide(color: AppColors.navyMid),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            const SizedBox(width: 8),
          ],
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.goldPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(Icons.hub_rounded,
                    size: 14, color: AppColors.navyMid),
                const SizedBox(width: 4),
                Text(
                  widget.moduleKey.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyMid,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: widget.readOnly && widget.existingRecord != null
          ? _buildReadOnlyBottomActions(context)
          : null,
    );
  }

  Widget _buildReadOnlyBottomActions(BuildContext context) {
    final record = widget.existingRecord!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.lightBorder)),
      ),
      child: SafeArea(
        child: Center(
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: _isGeneratingPdf
                      ? null
                      : () async {
                          setState(() => _isGeneratingPdf = true);
                          try {
                            await ModulePdfHelper.generatePdf(record, context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to generate PDF: ${e.toString().replaceFirst("Exception: ", "")}',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: AppColors.dangerRed,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isGeneratingPdf = false);
                            }
                          }
                        },
                  icon: _isGeneratingPdf
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.grey,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf_rounded, size: 16),
                  label: Text(
                    _isGeneratingPdf ? 'Generating...' : 'Download PDF',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color:
                          _isGeneratingPdf ? Colors.grey : AppColors.navyDark,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navyDark,
                    side: BorderSide(
                      color: _isGeneratingPdf
                          ? Colors.grey.shade300
                          : const Color(0xFFCBD5E1),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      AppTheme.fadeSlideRoute(
                        page: DynamicFormScreen(
                          categoryId: widget.categoryId,
                          moduleLabel: widget.moduleLabel,
                          moduleKey: widget.moduleKey,
                          subCategory: widget.subCategory,
                          existingRecord: record,
                          readOnly: false,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: Text(
                    'Edit Record',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navyMid,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      _confirmDeleteReadOnlyRecord(context, record),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: AppColors.dangerRed,
                  ),
                  label: Text(
                    'Delete',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.dangerRed,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFEB2B2)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                if (record.status != 'Transferred Out')
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        AppTheme.fadeSlideRoute(
                          page: TransferCaseFormScreen(record: record),
                        ),
                      );
                    },
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: Text(
                      'Transfer Case',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navyDark,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteReadOnlyRecord(BuildContext context, ModuleRecord record) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Delete Record',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppColors.dangerRed,
          ),
        ),
        content: Text(
          'Delete "${record.title}"? This cannot be undone.',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await _caseService.deleteCase(record.id);
                await FirestoreService().deleteCase(
                  record.id,
                  moduleKey: record.moduleKey,
                );
              } catch (_) {}
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Record deleted successfully',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: AppColors.successGreen,
                ),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const Map<String, String> _panchanamaKeyToName = {
    'spot_panchanama': 'Spot Panchanama',
    'seizure_panchanama': 'Seizure Panchanama',
    'search_panchanama': 'Search Panchanama',
    'personal_search_panchanama': 'Personal Search Panchanama',
    'memorandum_panchanama': 'Memorandum Panchanama',
    'identification_panchanama': 'Identification Panchanama',
    'identification_parade_panchanama': 'Identification Parade Panchanama',
  };

  bool _isFieldVisible(DynamicFieldDef f, [Set<String>? visiting]) {
    if (f.dependsOnFieldKey == null || f.dependsOnFieldKey!.trim().isEmpty) {
      return true;
    }

    final parentKey = f.dependsOnFieldKey!.trim();
    final visitSet = visiting ?? <String>{};
    if (visitSet.contains(f.fieldKey)) {
      return false;
    }
    visitSet.add(f.fieldKey);

    final fields = _formDef?.fields ?? <DynamicFieldDef>[];
    final parentField =
        fields.where((item) => item.fieldKey == parentKey).firstOrNull;
    if (parentField != null) {
      final isParentVis = _isFieldVisible(parentField, visitSet);
      if (!isParentVis) return false;
    }

    final rawVal = _values[parentKey] ?? _controllers[parentKey]?.text;
    if (rawVal == null) return false;

    return dependsOnValueMatches(rawVal, f.dependsOnValue,
        parentIsMultiSelect: parentField?.fieldType == 'multi_select');
  }

  void _pruneHiddenFields() {
    final fields = _formDef?.fields ?? <DynamicFieldDef>[];
    for (final f in fields) {
      if (!_isFieldVisible(f)) {
        _values.remove(f.fieldKey);
        _controllers[f.fieldKey]?.clear();
        final dateKey = '${f.fieldKey}_date';
        _values.remove(dateKey);
        _controllers[dateKey]?.clear();
      }
    }
  }

  /// Recalculates every `sum:` total field that adds up [changedKey]
  /// (e.g. Total Crime = Serious + Miscellaneous, or repeating group row values).
  /// Empty parts count as 0; when every part is empty the total is cleared.
  /// If [changedKey] is empty, all sum fields are recalculated.
  void _applySumTotals(String changedKey) {
    for (final f in _formDef?.fields ?? const <DynamicFieldDef>[]) {
      final parts = f.sumOf;
      if (parts.isEmpty) continue;
      if (changedKey.isNotEmpty &&
          !parts.any((p) =>
              p == changedKey ||
              p.startsWith('$changedKey.') ||
              p.endsWith('.$changedKey'))) {
        continue;
      }
      num total = 0;
      var anyValue = false;
      for (final p in parts) {
        if (p.contains('.')) {
          final dotIdx = p.indexOf('.');
          final groupKey = p.substring(0, dotIdx);
          final childKey = p.substring(dotIdx + 1);
          final rows = _values[groupKey];
          if (rows is List) {
            for (final row in rows) {
              if (row is Map) {
                final raw =
                    (row[childKey] ?? '').toString().trim().replaceAll(',', '');
                final n = num.tryParse(raw);
                if (n != null) {
                  total += n;
                  anyValue = true;
                }
              }
            }
          }
        } else {
          final raw = (_controllers[p]?.text ?? _values[p]?.toString() ?? '')
              .trim()
              .replaceAll(',', '');
          final n = num.tryParse(raw);
          if (n != null) {
            total += n;
            anyValue = true;
          }
        }
      }
      final text =
          anyValue ? (total % 1 == 0 ? '${total.toInt()}' : '$total') : '';
      _controllers.putIfAbsent(f.fieldKey, () => TextEditingController());
      if (_controllers[f.fieldKey]!.text != text) {
        _controllers[f.fieldKey]!.text = text;
      }
      if (anyValue) {
        _values[f.fieldKey] = text;
      } else {
        _values.remove(f.fieldKey);
      }
      _previousValues[f.fieldKey] = anyValue ? text : null;
    }
  }

  void _applyDateOffsets(String sourceKey, dynamic value) {
    final rules = widget.dateOffsetRules;
    if (rules == null || rules.isEmpty) return;
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return;
    final fmt = DateFormat('dd/MM/yyyy');
    for (final rule in rules) {
      if (rule is! Map || rule['source_field']?.toString() != sourceKey) {
        continue;
      }
      final target = rule['target_field']?.toString() ?? '';
      final days = int.tryParse('${rule['days']}');
      if (target.isEmpty || days == null) continue;
      DateTime source;
      try {
        source = fmt.parseStrict(text);
      } catch (_) {
        continue;
      }
      final result = fmt.format(source.add(Duration(days: days)));
      _values[target] = result;
      _previousValues[target] = result;
      _controllers.putIfAbsent(target, () => TextEditingController()).text =
          result;
    }
  }

  void _onDynamicFieldValueChanged(String k, dynamic v) {
    setState(() {
      final oldVal = _previousValues[k];
      _previousValues[k] = v;
      _values[k] = v;
      if (v == null) {
        _values.remove(k);
        _controllers[k]?.clear();
      }
      _applySumTotals(k);
      _applyDateOffsets(k, v);
      _pruneHiddenFields();

      final wasTicked = (oldVal == true ||
          oldVal == 'true' ||
          oldVal == 1 ||
          oldVal == '1' ||
          oldVal == 'Yes');
      final isTicked =
          (v == true || v == 'true' || v == 1 || v == '1' || v == 'Yes');
      if (!wasTicked && isTicked && _copyOnTickRules.isNotEmpty) {
        for (final rule in _copyOnTickRules) {
          if (rule is! Map) continue;
          final tKey =
              (rule['trigger_field'] ?? rule['tick_field'])?.toString();
          if (tKey == k) {
            final sKey =
                (rule['source_field'] ?? rule['from_field'])?.toString();
            final tgtKey =
                (rule['target_field'] ?? rule['to_field'])?.toString();
            if (sKey != null &&
                tgtKey != null &&
                sKey.isNotEmpty &&
                tgtKey.isNotEmpty) {
              final sVal =
                  _controllers[sKey]?.text ?? _values[sKey]?.toString() ?? '';
              _values[tgtKey] = sVal;
              if (_controllers.containsKey(tgtKey)) {
                _controllers[tgtKey]?.text = sVal;
              } else {
                try {
                  _controllers.putIfAbsent(
                      tgtKey, () => TextEditingController(text: sVal));
                } catch (_) {}
              }
            }
          }
        }
      }
      if (_panchanamaKeyToName.containsKey(k) || k.contains('panchanama')) {
        final dateKey = '${k}_date';
        if (v == true) {
          final curDate = _controllers[dateKey]?.text.trim() ??
              _values[dateKey]?.toString().trim() ??
              '';
          if (curDate.isEmpty) {
            final nowStr =
                DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
            _values[dateKey] = nowStr;
            _controllers
                .putIfAbsent(dateKey, () => TextEditingController())
                .text = nowStr;
          }
        }
      }
      if (k == 'preventive_action_type' &&
          v != null &&
          v.toString().trim().isNotEmpty) {
        final curDate = _controllers['preventive_action_date']?.text.trim() ??
            _values['preventive_action_date']?.toString().trim() ??
            '';
        if (curDate.isEmpty &&
            (_formDef?.defaults['date_default'] == 'current_date')) {
          final nowStr = DateFormat('dd/MM/yyyy').format(DateTime.now());
          _values['preventive_action_date'] = nowStr;
          _controllers
              .putIfAbsent(
                  'preventive_action_date', () => TextEditingController())
              .text = nowStr;
        }
      }
      if (k == 'mcr' && v != true) {
        _values['pr_bond'] = false;
        _values['bail'] = false;
        _values['jail'] = false;
        _values['pr_bond_date'] = null;
        _controllers['pr_bond_date']?.clear();
        _values['surety_name'] = null;
        _controllers['surety_name']?.clear();
        _values['jail_date'] = null;
        _controllers['jail_date']?.clear();
      } else if (k == 'pr_bond' && v != true) {
        _values['pr_bond_date'] = null;
        _controllers['pr_bond_date']?.clear();
      } else if (k == 'bail' && v != true) {
        _values['surety_name'] = null;
        _controllers['surety_name']?.clear();
      } else if (k == 'jail' && v != true) {
        _values['jail_date'] = null;
        _controllers['jail_date']?.clear();
      }
    });
  }

  bool _recordHasCustodyData(Map<String, dynamic> record) {
    final pcr =
        (record['pcr_days'] ?? record['pcrDays'] ?? '').toString().trim();
    final mcr = record['mcr'] == true ||
        record['mcr'] == 'true' ||
        record['isMcr'] == true ||
        record['isMcr'] == 'true';
    final prBond = record['pr_bond'] == true ||
        record['pr_bond'] == 'true' ||
        record['isPrBond'] == true ||
        record['isPrBond'] == 'true';
    final prBondDate = (record['pr_bond_date'] ?? record['prBondDate'] ?? '')
        .toString()
        .trim();
    final bail = record['bail'] == true ||
        record['bail'] == 'true' ||
        record['isBail'] == true ||
        record['isBail'] == 'true';
    final jail = record['jail'] == true ||
        record['jail'] == 'true' ||
        record['isJail'] == true ||
        record['isJail'] == 'true';
    final jailDate =
        (record['jail_date'] ?? record['jailDate'] ?? '').toString().trim();
    final suretyName =
        (record['surety_name'] ?? record['suretyName'] ?? '').toString().trim();
    return (pcr.isNotEmpty && pcr != '0') ||
        mcr ||
        prBond ||
        prBondDate.isNotEmpty ||
        bail ||
        jail ||
        jailDate.isNotEmpty ||
        suretyName.isNotEmpty;
  }

  bool get _hasAnyCustodyData {
    if (_pcrDaysCtrl.text.trim().isNotEmpty &&
        _pcrDaysCtrl.text.trim() != '0') {
      return true;
    }
    if (_jailDateCtrl.text.trim().isNotEmpty) return true;
    return _custodyRecordsList.any(_recordHasCustodyData);
  }

  bool _recordHasArrestData(Map<String, dynamic> r) {
    final dt = (r['arrest_datetime'] ?? r['date'] ?? '').toString().trim();
    final sec47 = r['sec_47_48_bnss'] == true || r['sec_47_48_bnss'] == 'true';
    final relName = (r['relative_friend_name'] ?? '').toString().trim();
    final ron =
        r['release_on_notice'] == true || r['release_on_notice'] == 'true';
    final ab =
        r['anticipatory_bail'] == true || r['anticipatory_bail'] == 'true';
    final doa =
        r['death_of_accused'] == true || r['death_of_accused'] == 'true';
    return dt.isNotEmpty || sec47 || relName.isNotEmpty || ron || ab || doa;
  }

  bool get _hasAnyArrestData {
    return _arrestRecordsList.any(_recordHasArrestData);
  }

  bool get _hasAnyPreventiveData {
    if (_preventiveDateCtrl.text.trim().isNotEmpty ||
        _preventiveBondDateCtrl.text.trim().isNotEmpty) {
      return true;
    }
    return _preventiveActionsList.any((it) {
      final aType = (it['action_type'] ?? it['action'] ?? '').toString().trim();
      final aDate = (it['action_date'] ?? it['date'] ?? '').toString().trim();
      final aNum = (it['preventive_number'] ?? it['outward_number'] ?? '')
          .toString()
          .trim();
      return aType.isNotEmpty || aDate.isNotEmpty || aNum.isNotEmpty;
    });
  }

  bool get _hasAnyDischargeData {
    if (_dischargedAccusedList.isNotEmpty) return true;
    return _dischargeDateControllers.values
        .any((c) => c.text.trim().isNotEmpty);
  }

  bool get _hasAnyLegalCharges {
    final rawVal = _values['charges'];
    if (rawVal is List && rawVal.isNotEmpty) return true;
    if (rawVal is Map && rawVal.isNotEmpty) return true;
    if (_selectedCharges.isNotEmpty) return true;
    final extra = widget.initialData ?? const <String, dynamic>{};
    final common = (extra['common_form'] is Map)
        ? (extra['common_form'] as Map)
        : (extra['commonForm'] is Map)
            ? (extra['commonForm'] as Map)
            : null;
    final rawCharges = extra['charges'] ??
        extra['acts_sections'] ??
        common?['charges'] ??
        common?['acts_sections'];
    if (rawCharges is List && rawCharges.isNotEmpty) return true;
    if (rawCharges is Map && rawCharges.isNotEmpty) return true;
    return false;
  }

  bool get _hasAnyScrutinyData {
    return _getScrutinyVal('sdpo_acp_send_date').isNotEmpty ||
        _getScrutinyVal('sdpo_acp_grant_date').isNotEmpty ||
        _getScrutinyVal('addl_sp_dcp_send_date').isNotEmpty ||
        _getScrutinyVal('addl_sp_dcp_grant_date').isNotEmpty ||
        _getScrutinyVal('addl_cp_send_date').isNotEmpty ||
        _getScrutinyVal('addl_cp_grant_date').isNotEmpty ||
        _getScrutinyVal('app_send_date').isNotEmpty ||
        _getScrutinyVal('app_grant_date').isNotEmpty;
  }

  bool _isDynamicSectionEmpty(List<DynamicFieldDef> secFields) {
    for (final f in secFields) {
      final ctrl = _controllers[f.fieldKey];
      if (ctrl != null) {
        final txt = ctrl.text.trim();
        if (txt.isNotEmpty && txt.toLowerCase() != 'false') {
          return false;
        }
      }
      final val = _values[f.fieldKey];
      if (val != null) {
        if (val is bool) {
          if (val) return false;
        } else {
          final sVal = val.toString().trim();
          if (sVal.isNotEmpty && sVal.toLowerCase() != 'false') {
            return false;
          }
        }
      }
    }
    return true;
  }

  Widget _buildBody() {
    if (_isLoading) {
      if (!widget.showLoadingSpinner) return const SizedBox.shrink();
      return const Center(
        child: CircularProgressIndicator(color: AppColors.navyMid),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.dangerRed),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 14, color: AppColors.lightText),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadFormDefinition();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final fields = _formDef?.fields ?? [];
    final hasBundle = _formDef?.hasLinkedBundle ?? false;
    if (fields.isEmpty || !hasBundle) {
      debugPrint(
        'WARNING: No form configured for this tab: ${widget.subCategory ?? widget.moduleLabel} (empty fields or no linked bundle)',
      );
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.goldPrimary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.folder_off_outlined,
                  size: 48,
                  color: AppColors.navyMid,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No form configured for this tab',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This category does not have a linked form bundle configured.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.lightSubText,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                label: const Text('Go Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navyDark,
                  side: const BorderSide(color: AppColors.lightBorder),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group all fields by their database-defined section name (common or custom)
    final Map<String, List<DynamicFieldDef>> groupedBySection = {};
    for (final f in fields) {
      var sec = f.section?.trim() ?? '';
      if (f.fieldKey == 'is_unknown_accused') {
        sec = 'Unknown Accused';
      }
      if (sec.isEmpty) {
        sec = f.fieldSource == 'custom'
            ? 'Special Section / Template Details'
            : 'Crime Registration Info';
      } else if (sec == 'Case Responsibility' || sec == 'Responsibility') {
        sec = 'Officer';
      }
      groupedBySection.putIfAbsent(sec, () => []).add(f);
    }
    final customFields =
        groupedBySection['Special Section / Template Details'] ??
            const <DynamicFieldDef>[];

    final orderedSectionKeys = [
      'Crime Registration Info',
      'Acts & Sections Filed',
      'Crime Spot',
      'Special Section / Template Details',
      'Complainant',
      'Accused',
      'Suspected Accused',
      'Unidentified Accused',
      'Unknown Accused',
      'Officer',
      'Arrest',
      'Remand & Custody',
      'Absconding Accused',
      'CCTV and CDR Investigation',
      'All Panchnama',
      'Vehicle Log Book',
      'Evidence',
      'Seizure Records',
      'Preventive Action',
      'Discharge Accused',
      'Scrutiny',
      'Court Filing and Final Summary',
    ];

    final accusedOptions = _getAvailableAccusedNames();
    final auth = context.read<AuthProvider>();
    final currentStation =
        widget.existingRecord?.stationName ?? auth.stationName;
    int sectionCounter = 1;
    final sectionCards = <Widget>[];
    final hasBaseline = _formDef?.hasCommonFormBaseline ?? false;
    // Fixed Common Form sections only on forms that have the Common Form or
    // that define fields in that section
    bool showSection(String key) =>
        hasBaseline || (groupedBySection[key]?.isNotEmpty ?? false);

    if (widget.sectionsInDisplayOrder) {
      int firstOrder(List<DynamicFieldDef> fs) => fs.isEmpty
          ? 1 << 30
          : fs.map((f) => f.displayOrder).reduce((x, y) => x < y ? x : y);
      final sorted = groupedBySection.entries
          .where((e) => e.value.isNotEmpty)
          .toList()
        ..sort((x, y) => firstOrder(x.value).compareTo(firstOrder(y.value)));
      // Sections whose fields sharing the same field_config 'card' are grouped;
      // others each get their own card.
      String cardOf(List<DynamicFieldDef> fs) =>
          fs.first.fieldConfig?['card']?.toString().trim() ?? '';

      final cards = <MapEntry<String, List<DynamicFieldDef>>>[];
      final sectionsInCard = <String, int>{};
      for (final e in sorted) {
        if (widget.readOnly &&
            _hideEmptyInViewMode &&
            _isDynamicSectionEmpty(e.value)) {
          continue;
        }
        final card = cardOf(e.value);
        final i = card.isEmpty ? -1 : cards.indexWhere((c) => c.key == card);
        if (i >= 0) {
          cards[i].value.addAll(e.value);
          sectionsInCard[card] = (sectionsInCard[card] ?? 1) + 1;
        } else {
          cards.add(MapEntry(card.isEmpty ? e.key : card, [...e.value]));
        }
      }
      for (final entry in cards) {
        final idx = sectionCounter++;
        sectionCards.add(
          DynamicSectionCard(
            showToggle: !_sectionsAlwaysOpen,
            key: ValueKey('sec_${entry.key}'),
            sectionIndex: widget.showSectionNumbers ? idx : null,
            title: entry.key,
            icon: _iconForSection(entry.key),
            fields: entry.value,
            showSectionHeadings: (sectionsInCard[entry.key] ?? 1) > 1,
            controllers: _controllers,
            values: _values,
            onValueChanged: _onDynamicFieldValueChanged,
            readOnly: widget.readOnly,
            initiallyExpanded: true,
            accusedOptions: accusedOptions,
            hideEmptyFields: _hideEmptyInViewMode,
            designationOptions: _designationOptions,
            preventiveOptions: _formDef?.preventiveItems,
            stationId: currentStation,
            copyOnTickRules: _copyOnTickRules,
            fieldMaxLengths: widget.fieldMaxLengths,
            allFormFields: fields,
          ),
        );
      }
    }

    // Common form: each section card by its key, placed in rows below
    _flatSectionCards = !widget.sectionsInDisplayOrder;

    // Builders: each card is made once its sub-step number (1.2) is known
    final byKey = <String, Widget Function(Object? idx)>{};
    final extraCards = <MapEntry<String, Widget Function(Object? idx)>>[];
    for (final secKey in widget.sectionsInDisplayOrder
        ? const <String>[]
        : orderedSectionKeys) {
      if (secKey == 'Acts & Sections Filed') {
        if (showSection(secKey) &&
            !(widget.readOnly &&
                _hideEmptyInViewMode &&
                !_hasAnyLegalCharges)) {
          byKey[secKey] =
              (idx) => (_buildLegalChargesSection(sectionIndex: idx));
        }
      } else if (secKey == 'Special Section / Template Details') {
        final isEmpty = _isDynamicSectionEmpty(customFields);
        if (customFields.isNotEmpty &&
            !(widget.readOnly && _hideEmptyInViewMode && isEmpty)) {
          byKey[secKey] = (idx) => DynamicSectionCard(
                flat: _flatSectionCards,
                showToggle: !_sectionsAlwaysOpen,
                key: ValueKey('sec_$secKey'),
                sectionIndex: idx,
                title:
                    'Special Section / Template Details (${customFields.length})',
                icon: Icons.featured_play_list_rounded,
                fields: customFields,
                controllers: _controllers,
                values: _values,
                onValueChanged: _onDynamicFieldValueChanged,
                readOnly: widget.readOnly,
                isExpanded: _isSectionExpanded(secKey),
                onToggle: () => _toggleSection(secKey),
                accusedOptions: accusedOptions,
                hideEmptyFields: _hideEmptyInViewMode,
                designationOptions: _designationOptions,
                preventiveOptions: _formDef?.preventiveItems,
                stationId: currentStation,
                copyOnTickRules: _copyOnTickRules,
                fieldMaxLengths: widget.fieldMaxLengths,
                allFormFields: fields,
                columns: 4,
              );
        }
      } else if (secKey == 'Remand & Custody') {
        if (showSection(secKey) &&
            !(widget.readOnly && _hideEmptyInViewMode && !_hasAnyCustodyData)) {
          byKey[secKey] = (idx) => (_buildRemandCustodySection(
              sectionIndex: idx, onlyFor: _panelAccused()));
        }
      } else if (secKey == 'Preventive Action') {
        if (showSection(secKey) &&
            !(widget.readOnly &&
                _hideEmptyInViewMode &&
                !_hasAnyPreventiveData)) {
          byKey[secKey] =
              (idx) => (_buildPreventiveActionSection(sectionIndex: idx));
        }
      } else if (secKey == 'Discharge Accused') {
        if (showSection(secKey) &&
            !(widget.readOnly &&
                _hideEmptyInViewMode &&
                !_hasAnyDischargeData)) {
          byKey[secKey] =
              (idx) => (_buildDischargeAccusedSection(sectionIndex: idx));
        }
      } else if (secKey == 'Accused') {
        // One Accused card holds all four accused types, picked from a
        // multi-select dropdown inside it
        final types = _accusedTypeKeys.where(showSection).toList();
        if (types.isNotEmpty) {
          byKey[secKey] =
              (idx) => (_buildAccusedSection(sectionIndex: idx, types: types));
        }
      } else if (secKey == 'Suspected Accused' ||
          secKey == 'Unidentified Accused' ||
          secKey == 'Unknown Accused') {
        // Shown inside the Accused card
      } else if (secKey == 'Arrest') {
        if (showSection(secKey) &&
            !(widget.readOnly && _hideEmptyInViewMode && !_hasAnyArrestData)) {
          byKey[secKey] = (idx) => (_buildArrestSection(
              sectionIndex: idx, onlyFor: _panelAccused()));
        }
      } else if (secKey == 'Scrutiny') {
        if (showSection(secKey) &&
            !(widget.readOnly &&
                _hideEmptyInViewMode &&
                !_hasAnyScrutinyData)) {
          byKey[secKey] = (idx) => (_buildScrutinySection(sectionIndex: idx));
        }
      } else {
        final secFields = groupedBySection[secKey];
        if (secFields != null && secFields.isNotEmpty) {
          final isEmpty = _isDynamicSectionEmpty(secFields);
          if (!(widget.readOnly && _hideEmptyInViewMode && isEmpty)) {
            final displayTitle = secKey == 'Officer'
                ? 'IO / Registered By'
                : (secKey == 'Court Filing and Final Summary'
                    ? 'Court Filing & Final Summary'
                    : secKey);
            byKey[secKey] = (idx) => DynamicSectionCard(
                  flat: _flatSectionCards,
                  showToggle: !_sectionsAlwaysOpen,
                  key: ValueKey('sec_$secKey'),
                  sectionIndex: idx,
                  title: displayTitle,
                  icon: _iconForSection(secKey),
                  fields: secFields,
                  controllers: _controllers,
                  values: _values,
                  onValueChanged: _onDynamicFieldValueChanged,
                  readOnly: widget.readOnly,
                  isExpanded: _isSectionExpanded(secKey),
                  onToggle: () => _toggleSection(secKey),
                  accusedOptions: accusedOptions,
                  hideEmptyFields: _hideEmptyInViewMode,
                  designationOptions: _designationOptions,
                  preventiveOptions: _formDef?.preventiveItems,
                  stationId: currentStation,
                  copyOnTickRules: _copyOnTickRules,
                  fieldMaxLengths: widget.fieldMaxLengths,
                  allFormFields: fields,
                  // PC: three fields per line (Panchnama, Complainant four;
                  // IO / Registered By and Evidence two: IO on one line,
                  // Registered By below it; NAFIS below E-Shakshya)
                  columns: secKey == 'All Panchnama' || secKey == 'Complainant'
                      ? 4
                      : (secKey == 'Officer' || secKey == 'Evidence' ? 2 : 3),
                );
          }
        }
      }
    }

    // Append any extra/unmapped sections from DB that were not in standard list
    for (final entry in groupedBySection.entries) {
      if (!widget.sectionsInDisplayOrder &&
          !orderedSectionKeys.contains(entry.key) &&
          entry.value.isNotEmpty) {
        final lower = entry.key.toLowerCase();
        if (lower.contains('remand') ||
            lower.contains('custody') ||
            lower.contains('scrutiny') ||
            lower == 'bond') {
          continue;
        }
        final isEmpty = _isDynamicSectionEmpty(entry.value);
        if (widget.readOnly && _hideEmptyInViewMode && isEmpty) {
          continue;
        }
        extraCards.add(MapEntry(
          entry.key,
          (idx) => DynamicSectionCard(
            flat: _flatSectionCards,
            showToggle: !_sectionsAlwaysOpen,
            key: ValueKey('sec_${entry.key}'),
            sectionIndex: idx,
            title: entry.key,
            icon: _iconForSection(entry.key),
            fields: entry.value,
            controllers: _controllers,
            values: _values,
            onValueChanged: _onDynamicFieldValueChanged,
            readOnly: widget.readOnly,
            isExpanded: _isSectionExpanded(entry.key),
            onToggle: () => _toggleSection(entry.key),
            accusedOptions: accusedOptions,
            hideEmptyFields: _hideEmptyInViewMode,
            designationOptions: _designationOptions,
            preventiveOptions: _formDef?.preventiveItems,
            stationId: currentStation,
            copyOnTickRules: _copyOnTickRules,
            fieldMaxLengths: widget.fieldMaxLengths,
            allFormFields: fields,
            // Post-Mortem & FSL: two tick boxes (with their dates) per line
            columns: entry.key.toLowerCase().contains('post-mortem') ? 2 : 4,
          ),
        ));
      }
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 600;

    final useSteps = !widget.sectionsInDisplayOrder;
    final isWideLayout = screenWidth >= 1000;
    final steps = useSteps
        ? _commonFormSteps(byKey, extraCards, isWideLayout)
        : const <List<_SubStep>>[];
    _lastSteps = steps;
    final shownSteps = [
      for (var i = 0; i < steps.length; i++)
        if (steps[i].isNotEmpty) i,
    ];
    final step = shownSteps.contains(_formStep)
        ? _formStep
        : (shownSteps.isEmpty ? 0 : shownSteps.first);
    final sub = steps.isEmpty
        ? 0
        : _formSub.clamp(0, (steps[step].length - 1).clamp(0, 1 << 20));

    // Step layout fits the screen: step tabs and sub-step chips on top,
    // the section in the middle (scrolls on its own), and the Previous /
    // Submit / Next bar always visible at the bottom
    if (useSteps && shownSteps.isNotEmpty) {
      // Every sub-step stays built, so its fields keep their values and
      // still take part in validation while another is shown; only the
      // shown one is visible, and it scrolls on its own
      final sectionArea = Stack(
        // Full width for the shown section (the others are offstage)
        fit: StackFit.passthrough,
        children: [
          for (var i = 0; i < steps.length; i++)
            for (var j = 0; j < steps[i].length; j++)
              Visibility(
                key: ValueKey('substep_${i}_$j'),
                visible: i == step && j == sub,
                maintainState: true,
                child: steps[i][j].card,
              ),
        ],
      );
      final nav = _buildSubStepNav(steps, shownSteps, step, sub);
      final pad = isCompact ? 10.0 : AppSpacing.md;

      // Step tabs on top, then the section in a panel with folder tabs
      // (1.1, 1.2, ...), then the Previous / Submit / Next bar
      final Widget body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (shownSteps.length > 1)
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: (steps[step].isEmpty || isCompact)
                      ? 0
                      : _tabArrowGutter),
              child: _buildStepTabs(shownSteps, step, isCompact),
            ),
          // Box only as tall as its section, the bar right under it; a long
          // section scrolls inside the box and the bar stays on screen
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: steps[step].isEmpty
                        ? SingleChildScrollView(child: sectionArea)
                        : _buildFolderTabPanel(
                            steps[step], step, sub, sectionArea),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: steps[step].isEmpty ? 0 : _tabArrowGutter),
                    child: nav,
                  ),
                ],
              ),
            ),
          ),
        ],
      );

      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Form(
            key: _formKey,
            child: Padding(padding: EdgeInsets.all(pad), child: body),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        // Step layout: one section at a time in a centred, readable column
        constraints: BoxConstraints(maxWidth: useSteps ? 1080 : 1100),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 10.0 : AppSpacing.md,
              vertical: isCompact ? 12.0 : AppSpacing.lg,
            ),
            children: [
              if (!useSteps) ...sectionCards,
              SizedBox(height: isCompact ? 16 : 24),

              // Submit Button
              if (!widget.readOnly)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Container(
                      height: 52,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navyMid.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg)),
                        ),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_rounded,
                                color: Colors.white),
                        label: Text(
                          _isSubmitting
                              ? 'Saving...'
                              : (isEdit
                                  ? (widget.onSubmitCustom != null
                                      ? 'Save Changes'
                                      : 'Update Case Record')
                                  : 'Submit'),
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ── Common form layout: 3 steps, equal-width cards in rows ──────────────

  // Step labels in the step header (shown bold, without a title above)
  static const _stepHints = [
    'FIR',
    'Investigation',
    'Charge Sheet',
  ];

  /// Step that holds a section: 0 case & people, 1 investigation, 2 closure.
  int _stepOfSection(String section) {
    final s = section.toLowerCase();
    if (s.contains('scrutiny') ||
        s.contains('court') ||
        s.contains('final summary')) {
      return 2;
    }
    const caseAndPeople = [
      'crime registration',
      'acts & sections',
      'crime spot',
      'complainant',
      'accused',
      'officer',
      'responsibility',
      'registered by',
      'arrest',
      'remand',
      'custody',
    ];
    if (s.contains('discharge')) return 1;
    return caseAndPeople.any(s.contains) ? 0 : 1;
  }

  /// Everyone who can have an arrest or custody record, in form order.
  List<String> _panelPeople() {
    final people = <String>[];
    void add(String n) {
      final t = n.trim();
      if (t.isNotEmpty &&
          !people.any((x) => x.toLowerCase() == t.toLowerCase())) {
        people.add(t);
      }
    }

    _getAvailableAccusedNames().forEach(add);
    for (final r in _arrestRecordsList) {
      add((r['arrested_person_name'] ?? r['person_name'] ?? r['name'] ?? '')
          .toString());
    }
    _customCustodyPersons.forEach(add);
    for (final r in _custodyRecordsList) {
      add((r['name'] ?? r['person_name'] ?? '').toString());
    }
    return people;
  }

  /// The accused whose arrest & custody are shown (the first by default).
  String? _panelAccused() {
    final people = _panelPeople();
    if (people.isEmpty) return null;
    final f = _focusedAccused;
    if (f != null && people.any((p) => p.toLowerCase() == f.toLowerCase())) {
      return f;
    }
    return people.first;
  }

  /// Short names for the sub-step chips.
  static const _subStepNames = {
    'Crime Registration Info': 'Registration Info',
    'Acts & Sections Filed': 'Acts & Sections',
    'Officer': 'IO / Registered By',
    'Arrest': 'Arrest & Custody',
    'CCTV and CDR Investigation': 'CCTV & CDR',
    'All Panchnama': 'Panchnama',
    'Seizure Records': 'Seizure',
    'Special Section / Template Details': 'Special Section',
    'Court Filing and Final Summary': 'Court Filing & Summary',
  };

  /// The three steps, each split into numbered sub-steps (1.1, 1.2, ...),
  /// one section card per sub-step. Sections the form does not have are
  /// left out and the numbering closes up.
  List<List<_SubStep>> _commonFormSteps(
    Map<String, Widget Function(Object? idx)> byKey,
    List<MapEntry<String, Widget Function(Object? idx)>> extraCards,
    bool wide,
  ) {
    const plan = [
      [
        'Crime Registration Info',
        'Acts & Sections Filed',
        'Crime Spot',
        'Complainant',
        'Accused',
        'Officer',
        'Arrest',
        'Absconding Accused',
      ],
      [
        'CCTV and CDR Investigation',
        'Vehicle Log Book',
        'Evidence',
        'All Panchnama',
        'Seizure Records',
        'Preventive Action',
        'Discharge Accused',
        'Special Section / Template Details',
      ],
      ['Scrutiny', 'Court Filing and Final Summary'],
    ];

    final steps = <List<_SubStep>>[];
    for (var s = 0; s < plan.length; s++) {
      final subs = <_SubStep>[];
      String label() => '${s + 1}.${subs.length + 1}';
      for (final key in plan[s]) {
        if (key == 'Arrest') {
          // Arrest and Remand & Custody share one sub-step, for the accused
          // picked in the bar above them
          final arrest = byKey['Arrest'];
          final custody = byKey['Remand & Custody'];
          if (arrest == null && custody == null) continue;
          final l = label();
          subs.add(_SubStep(
            title: _subStepNames[key]!,
            keys: const ['Arrest', 'Remand & Custody'],
            card: _buildArrestCustodyPanel(arrest?.call(l), custody?.call(l)),
          ));
          continue;
        }
        final build = byKey[key];
        if (build == null) continue;
        subs.add(_SubStep(
          title: _subStepNames[key] ?? key,
          keys: key == 'Accused' ? _accusedTypeKeys : [key],
          card: build(label()),
        ));
      }
      if (s == 1) {
        for (final e in extraCards) {
          subs.add(
              _SubStep(title: e.key, keys: [e.key], card: e.value(label())));
        }
      }
      steps.add(subs);
    }
    return steps;
  }

  /// 1.7 Arrest & Custody: the accused on the left, and the picked one's
  /// arrest and custody stacked on the right. Phones keep the picker bar
  /// above the two cards.
  Widget _buildArrestCustodyPanel(Widget? arrest, Widget? custody) {
    final people = _panelPeople();
    final current = _panelAccused();
    // One record card for the picked accused: Arrest (with PCR / MCR) and
    // Release side by side. Without an accused, the old cards explain why.
    final Widget cards = (current != null && arrest != null)
        ? _buildArrestRecordCard(current, withCustody: custody != null)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (arrest != null) arrest,
              if (arrest != null && custody != null) const SizedBox(height: 10),
              if (custody != null) custody,
            ],
          );
    if (MediaQuery.sizeOf(context).width < 840 || people.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [_buildAccusedPicker(), cards],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 170, child: _buildAccusedListPanel(people)),
        const SizedBox(width: 14),
        Expanded(child: cards),
      ],
    );
  }

  /// A new arrest record for [name], with the same keys as before.
  Map<String, dynamic> _newArrestRecord(String name) => {
        'arrested_person_name': name,
        'person_name': name,
        'name': name,
        'arrest_datetime':
            DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
        'sec_47_48_bnss': false,
        'relative_friend_name': '',
        'relative_friend_relation': '',
        'release_on_notice': false,
        'release_on_notice_datetime': '',
        'anticipatory_bail': false,
        'anticipatory_bail_datetime': '',
        'death_of_accused': false,
        'death_of_accused_datetime': '',
      };

  int _arrestIndexOf(String name) => _arrestRecordsList.indexWhere((r) =>
      (r['arrested_person_name'] ?? r['person_name'] ?? r['name'] ?? '')
          .toString()
          .trim()
          .toLowerCase() ==
      name.toLowerCase());

  /// Arrested = the record has an arrest date. A record without one holds
  /// only a release option (not arrested; the backend counts arrests by
  /// arrest date too).
  bool _recordArrested(Map<String, dynamic>? r) =>
      r != null && (r['arrest_datetime']?.toString().trim() ?? '').isNotEmpty;

  bool _recordHasRelease(Map<String, dynamic> r) =>
      _releaseOptions.keys.any((k) => r[k] == true);

  void _clearArrestDetails(Map<String, dynamic> r) {
    r['arrest_datetime'] = '';
    r['sec_47_48_bnss'] = false;
    r['relative_friend_name'] = '';
    r['relative_friend_relation'] = '';
  }

  void _clearRelease(Map<String, dynamic> r) {
    for (final e in _releaseOptions.entries) {
      r[e.key] = false;
      r[e.value] = '';
    }
  }

  /// Arrest and Release & legal status: only one can be ticked. Ticking
  /// Arrest gives the record an arrest date and clears any release option;
  /// unticking it drops the record.
  void _setArrested(String name, bool on) {
    setState(() {
      final i = _arrestIndexOf(name);
      if (on) {
        _releaseOpen.remove(name.toLowerCase());
        if (i < 0) {
          _arrestRecordsList.add(_newArrestRecord(name));
        } else {
          final r = _arrestRecordsList[i];
          _clearRelease(r);
          r['arrest_datetime'] =
              DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
        }
      } else {
        if (i >= 0) _arrestRecordsList.removeAt(i);
        _dropCustody(name);
      }
      _syncPrimaryArrestControllers();
    });
  }

  /// PCR / MCR belong to an arrest: cleared when the arrest is unticked.
  void _dropCustody(String name) {
    final before = _custodyRecordsList.length;
    _custodyRecordsList.removeWhere((it) =>
        (it['name'] ?? it['person_name'] ?? '').toString().toLowerCase() ==
        name.toLowerCase());
    if (_custodyRecordsList.length != before) _syncPrimaryCustodyControllers();
  }

  /// Ticking Release & legal status unticks Arrest (its details are
  /// cleared) and opens the release options; unticking it clears them and
  /// drops the record when it holds nothing else.
  void _setRelease(String name, bool on) {
    setState(() {
      final key = name.toLowerCase();
      var i = _arrestIndexOf(name);
      if (on) {
        _releaseOpen.add(key);
        if (i < 0) {
          final r = _newArrestRecord(name);
          _clearArrestDetails(r);
          _arrestRecordsList.add(r);
        } else {
          _clearArrestDetails(_arrestRecordsList[i]);
        }
        _dropCustody(name);
      } else {
        _releaseOpen.remove(key);
        if (i >= 0) {
          final r = _arrestRecordsList[i];
          _clearRelease(r);
          if (!_recordArrested(r)) _arrestRecordsList.removeAt(i);
        }
      }
      _syncPrimaryArrestControllers();
    });
  }

  TextStyle get _arrestLabelStyle => GoogleFonts.poppins(
      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navyDark);

  /// Date & time box of an arrest record field; tap to pick.
  Widget _recordDateBox(Map<String, dynamic> record, String key, String hint,
      {String? inlineLabel}) {
    final raw = (record[key] ?? '').toString();
    final v =
        raw.isNotEmpty && inlineLabel != null ? '$inlineLabel: $raw' : raw;
    return InkWell(
      onTap: widget.readOnly
          ? null
          : () => _pickDateTimeForRecord(context, record, key),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                v.isNotEmpty ? v : hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: v.isNotEmpty
                      ? AppColors.navyDark
                      : const Color(0xFF94A3B8),
                ),
              ),
            ),
            const Icon(Icons.calendar_month_rounded,
                size: 18, color: AppColors.navyMid),
          ],
        ),
      ),
    );
  }

  /// Accused (lower-case names) whose Release & legal status box is ticked
  /// but no option is picked yet.
  final Set<String> _releaseOpen = {};

  /// Release options of an arrest record (flag key -> its date key). Only
  /// one can be picked at a time.
  static const _releaseOptions = {
    'release_on_notice': 'release_on_notice_datetime',
    'anticipatory_bail': 'anticipatory_bail_datetime',
    'death_of_accused': 'death_of_accused_datetime',
  };

  Widget _recordTextField(Map<String, dynamic> record, String key, String name,
      String label, String hint) {
    return TextFormField(
      key: ValueKey('${key}_$name'),
      initialValue: record[key]?.toString() ?? '',
      enabled: !widget.readOnly,
      style: GoogleFonts.poppins(fontSize: 13, color: AppColors.navyDark),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      onChanged: (val) {
        record[key] = val.trim();
        _syncPrimaryArrestControllers();
      },
    );
  }

  static const _relationOptions = [
    'Mother',
    'Father',
    'Husband',
    'Wife',
    'Sister',
    'Brother',
    'Friend',
    'Other',
  ];

  /// Accused (names) whose "Relation with Accused" is set to Other, so the
  /// type-in box stays open even while it is still empty.
  final Set<String> _relationOtherOpen = {};

  /// "Relation with Accused" dropdown, plus (when Other is picked) a box to
  /// type the relation; the typed text is what gets saved under [key].
  List<Widget> _relationWithAccusedFields(
      Map<String, dynamic> record, String key, String name) {
    final current = (record[key] ?? '').toString().trim();
    final match = _relationOptions.firstWhere(
        (o) => o != 'Other' && o.toLowerCase() == current.toLowerCase(),
        orElse: () => '');
    final isOther = match.isEmpty &&
        (current.isNotEmpty || _relationOtherOpen.contains(name));
    final selected = isOther ? 'Other' : (match.isEmpty ? null : match);

    InputDecoration deco(String label, {String? hint}) => InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        );

    final dropdown = DropdownButtonFormField<String>(
      key: ValueKey('${key}_dd_$name'),
      initialValue: selected,
      isExpanded: true,
      decoration: deco('Relation with Accused', hint: 'Select relation'),
      style: GoogleFonts.poppins(fontSize: 13, color: AppColors.navyDark),
      items: _relationOptions
          .map((o) => DropdownMenuItem(value: o, child: Text(o)))
          .toList(),
      onChanged: widget.readOnly
          ? null
          : (v) => setState(() {
                if (v == 'Other') {
                  _relationOtherOpen.add(name);
                  record[key] = '';
                } else {
                  _relationOtherOpen.remove(name);
                  record[key] = v ?? '';
                }
                _syncPrimaryArrestControllers();
              }),
    );

    if (!isOther) return [dropdown];
    return [
      dropdown,
      TextFormField(
        key: ValueKey('${key}_other_$name'),
        initialValue: current,
        enabled: !widget.readOnly,
        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.navyDark),
        decoration: deco('Specify relation', hint: 'e.g. Uncle / Neighbour'),
        onChanged: (val) {
          record[key] = val.trim();
          _syncPrimaryArrestControllers();
        },
      ),
    ];
  }

  /// Intimation fields side by side on wide screens, stacked otherwise.
  Widget _intimationFieldsLayout(List<Widget> fields, bool wide) {
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: fields[i]),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          fields[i],
        ],
      ],
    );
  }

  /// Light grey box for fields that open under a choice (Intimation
  /// details, the release date), so it is clear where they came from.
  Widget _subFieldsBox({required Widget child}) => Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: child,
      );

  Widget _subHeading(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.lightSubText),
        ),
      );

  /// Release / legal: one of Notice 35(3) BNSS, Anticipatory bail, Death of
  /// accused (side by side); the chosen one's date & time opens below.
  Widget _releaseChoices(Map<String, dynamic> record, double width) {
    const labels = {
      'release_on_notice': 'Notice 35(3) BNSS',
      'anticipatory_bail': 'Anticipatory bail',
      'death_of_accused': 'Death of accused',
    };
    String? picked;
    for (final k in _releaseOptions.keys) {
      if (record[k] == true) picked = k;
    }

    Widget choice(String flag) {
      final on = picked == flag;
      final dateKey = _releaseOptions[flag]!;
      return InkWell(
        onTap: widget.readOnly
            ? null
            : () => setState(() {
                  if (on) {
                    record[flag] = false;
                  } else {
                    for (final e in _releaseOptions.entries) {
                      if (e.key == flag) continue;
                      record[e.key] = false;
                      record[e.value] = '';
                    }
                    record[flag] = true;
                    if (record[dateKey]?.toString().isEmpty ?? true) {
                      record[dateKey] =
                          DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
                    }
                  }
                  _syncPrimaryArrestControllers();
                }),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color:
                on ? AppColors.navyMid.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
                color: on ? AppColors.navyMid : AppColors.lightBorder,
                width: on ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Icon(
                on
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: on ? AppColors.navyMid : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(labels[flag]!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _arrestLabelStyle),
              ),
            ],
          ),
        ),
      );
    }

    final flags = _releaseOptions.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (width >= 520)
          Row(children: [
            for (var i = 0; i < flags.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: choice(flags[i])),
            ],
          ])
        else
          for (final f in flags)
            Padding(
                padding: const EdgeInsets.only(bottom: 8), child: choice(f)),
        if (picked != null)
          _subFieldsBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _subHeading('${labels[picked]} date & time'),
                SizedBox(
                  width: width >= 520 ? width / 2 : double.infinity,
                  child: _recordDateBox(
                      record, _releaseOptions[picked]!, 'DD/MM/YYYY HH:mm'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Arrest & Custody record of one accused (only one status at a time):
  /// the name with an Arrest | Release / legal switch, then one full-width
  /// panel for the picked status:
  ///  - Arrest: Arrested date | Intimation 47/48 BNSS | PCR | MCR on one
  ///    line (stacked when narrow); Intimation opens the relative's name
  ///    and relation, MCR opens PR Bond / Jail / Bail and their details
  ///  - Release / legal: Notice 35(3) BNSS | Anticipatory bail | Death of
  ///    accused, the chosen one's date & time below
  /// Same fields and saved data as before; switching clears the other side.
  Widget _buildArrestRecordCard(String name, {required bool withCustody}) {
    final idx = _arrestIndexOf(name);
    final record = idx >= 0 ? _arrestRecordsList[idx] : null;
    final arrested = _recordArrested(record);
    final releaseOn = record != null &&
        !arrested &&
        (_releaseOpen.contains(name.toLowerCase()) ||
            _recordHasRelease(record));

    Widget segment(String label, bool on, VoidCallback onTap) {
      return Material(
        color: on ? Colors.white : Colors.transparent,
        elevation: on ? 1 : 0,
        shadowColor: AppColors.navyDark.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: on
              ? const BorderSide(color: AppColors.lightBorder)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: widget.readOnly ? null : onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // A tick box shows each side can be clicked
                Icon(
                    on
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    size: 19,
                    color: on ? AppColors.navyMid : const Color(0xFF94A3B8)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: on ? FontWeight.w700 : FontWeight.w600,
                    color: on ? AppColors.navyDark : AppColors.lightSubText,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final statusSwitch = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          segment('Arrest', arrested, () => _setArrested(name, !arrested)),
          const SizedBox(width: 3),
          segment('Release / legal', releaseOn,
              () => _setRelease(name, !releaseOn)),
        ],
      ),
    );

    Widget intimationBox(Map<String, dynamic> r) {
      final intimated = r['sec_47_48_bnss'] == true;
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: intimated
              ? AppColors.navyMid.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: intimated ? AppColors.navyMid : AppColors.lightBorder,
            width: intimated ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: intimated,
              activeColor: AppColors.navyMid,
              visualDensity: VisualDensity.compact,
              onChanged: widget.readOnly
                  ? null
                  : (v) => setState(() {
                        r['sec_47_48_bnss'] = v ?? false;
                        _syncPrimaryArrestControllers();
                      }),
            ),
            Expanded(
              child: Text(
                'Intimation 47/48 BNSS',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navyDark),
              ),
            ),
          ],
        ),
      );
    }

    Widget intimationDetails(Map<String, dynamic> r, double width) {
      final nameF = _recordTextField(r, 'relative_friend_name', name,
          'Relative / Friend Name', 'e.g. Ramesh');
      return _subFieldsBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _subHeading('Intimation given to'),
            _intimationFieldsLayout([
              nameF,
              ..._relationWithAccusedFields(
                  r, 'relative_friend_relation', name),
            ], width >= 420),
          ],
        ),
      );
    }

    Widget arrestPanel(Map<String, dynamic> r, double width) {
      final wide = width >= 640;
      final date = _recordDateBox(r, 'arrest_datetime', 'Arrested date',
          inlineLabel: 'Arrested');
      final intim = intimationBox(r);
      final details =
          r['sec_47_48_bnss'] == true ? intimationDetails(r, width) : null;
      if (!withCustody) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(child: date),
              const SizedBox(width: 14),
              Expanded(child: intim),
            ]),
            if (details != null) details,
          ],
        );
      }
      final ci = _custodyRecordsList.indexWhere((it) =>
          (it['name'] ?? it['person_name'] ?? '').toString().toLowerCase() ==
          name.toLowerCase());
      final custody = _CustodyAccusedCard(
        key: ValueKey('custody_bare_$name'),
        personName: name,
        isCustom: _customCustodyPersons.contains(name),
        readOnly: widget.readOnly,
        initialData: ci >= 0 ? _custodyRecordsList[ci] : null,
        genderOptions: _genderOptions,
        relationChoices: _suretyRelationChoices,
        isExpanded: true,
        onToggleExpand: () {},
        onChanged: (updated) => _onCustodyRecordChanged(name, updated),
        bare: true,
        // Wide: Arrested date | Intimation | PCR | MCR on one line
        leadingCells: wide ? [date, intim] : const [],
        belowFirstRow: wide ? details : null,
      );
      if (wide) return custody;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: date),
            const SizedBox(width: 12),
            Expanded(child: intim),
          ]),
          if (details != null) details,
          const SizedBox(height: 12),
          custody,
        ],
      );
    }

    final initials = name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _responsiveCardRadius(context),
        border: Border.all(color: AppColors.lightBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(builder: (context, c) {
        final header = [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: AppColors.navyMid),
            child: Text(
              initials,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDark),
            ),
          ),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (c.maxWidth >= 480)
              Row(children: [...header, statusSwitch])
            else ...[
              Row(children: header),
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerLeft, child: statusSwitch),
            ],
            const SizedBox(height: 12),
            if (arrested)
              arrestPanel(record!, c.maxWidth)
            else if (releaseOn)
              _releaseChoices(record, c.maxWidth)
            else
              Text(
                'Pick Arrest or Release / legal to record details.',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.lightSubText),
              ),
          ],
        );
      }),
    );
  }

  bool _personNamed(List<Map<String, dynamic>> list, String name) => list.any(
      (p) =>
          (p['name']?.toString().trim().toLowerCase() ?? '') ==
          name.toLowerCase());

  bool _isArrested(String name) {
    final i = _arrestIndexOf(name);
    return i >= 0 && _recordArrested(_arrestRecordsList[i]);
  }

  /// Narrow left list of the accused: a small initial, the name, and one
  /// line "Accused · Arrested" with a green (arrested) or grey dot. Tap one
  /// to show their arrest and custody.
  Widget _buildAccusedListPanel(List<String> people) {
    final current = _panelAccused();
    final arrested = people.where(_isArrested).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _responsiveCardRadius(context),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Accused',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                  ),
                ),
                Text(
                  '$arrested of ${people.length} arrested',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.lightSubText),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.lightBorder),
          Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final name in people)
                  Builder(builder: (context) {
                    final selected =
                        name.toLowerCase() == current?.toLowerCase();
                    final isArrested = _isArrested(name);
                    final type = _personNamed(_accusedList, name)
                        ? 'Accused'
                        : (_personNamed(_suspectedAccusedList, name)
                            ? 'Suspect'
                            : null);
                    final status = [
                      if (type != null) type,
                      isArrested ? 'Arrested' : 'Not arrested',
                    ].join(' · ');
                    final initials = name
                        .split(RegExp(r'\s+'))
                        .where((w) => w.isNotEmpty)
                        .take(2)
                        .map((w) => w[0].toUpperCase())
                        .join();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Material(
                        color: selected
                            ? AppColors.navyMid.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          onTap: () => setState(() => _focusedAccused = name),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 7),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: selected
                                    ? AppColors.navyMid.withValues(alpha: 0.35)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: selected
                                        ? AppColors.navyMid
                                        : const Color(0xFFF1F5F9),
                                  ),
                                  child: Text(
                                    initials,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? Colors.white
                                          : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.navyDark,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isArrested
                                                  ? const Color(0xFF16A34A)
                                                  : const Color(0xFF94A3B8),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              status,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.poppins(
                                                fontSize: 10.5,
                                                color: AppColors.lightSubText,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "Arrest & custody for" bar: one choice per accused.
  Widget _buildAccusedPicker() {
    final people = _panelPeople();
    if (people.length < 2) return const SizedBox.shrink();
    final current = _panelAccused();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _responsiveCardRadius(context),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Arrest & custody for',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.navyDark,
            ),
          ),
          for (final name in people)
            ChoiceChip(
              label: Text(name),
              selected: name.toLowerCase() == current?.toLowerCase(),
              onSelected: (_) => setState(() => _focusedAccused = name),
              showCheckmark: false,
              labelStyle: GoogleFonts.poppins(
                fontSize: 13,
                color: name.toLowerCase() == current?.toLowerCase()
                    ? Colors.white
                    : AppColors.navyDark,
              ),
              selectedColor: AppColors.navyMid,
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.lightBorder),
            ),
        ],
      ),
    );
  }

  /// Step header: the steps as segmented tabs in a soft grey bar. The
  /// current step is a raised white tab with a solid navy number; finished
  /// steps show a green tick; later ones a plain number. Same on PC and
  /// phone (narrow tabs shorten long names).
  Widget _buildStepTabs(List<int> shown, int current, bool isCompact) {
    const doneFg = Color(0xFF2E7D32);
    const doneBg = Color(0xFFE8F5E9);
    final at = shown.indexOf(current);

    if (isCompact) {
      Widget compactTab(int n) {
        final isOn = n == at;
        final isDone = n < at;
        final badge = Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOn ? AppColors.navyMid : (isDone ? doneBg : Colors.white),
            border: Border.all(
              color: isOn
                  ? AppColors.navyMid
                  : (isDone
                      ? doneFg.withValues(alpha: 0.5)
                      : AppColors.lightBorder),
            ),
          ),
          child: isDone
              ? const Icon(Icons.check_rounded, size: 14, color: doneFg)
              : Text(
                  '${n + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isOn ? Colors.white : AppColors.lightSubText,
                  ),
                ),
        );
        return KeyedSubtree(
          key: _stepTabKeys.putIfAbsent(shown[n], GlobalKey.new),
          child: Material(
            color: isOn ? Colors.white : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: isOn
                  ? const BorderSide(color: AppColors.lightBorder)
                  : BorderSide.none,
            ),
            elevation: isOn ? 1 : 0,
            shadowColor: AppColors.navyDark.withValues(alpha: 0.15),
            child: InkWell(
              onTap: () => _goTo(shown[n], 0),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    badge,
                    const SizedBox(width: 6),
                    Text(
                      _stepHints[shown[n]],
                      maxLines: 1,
                      softWrap: false,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: isOn ? FontWeight.w700 : FontWeight.w600,
                        color: isOn
                            ? AppColors.navyDark
                            : (isDone ? doneFg : AppColors.lightSubText),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var n = 0; n < shown.length; n++) ...[
                  if (n > 0) const SizedBox(width: 4),
                  compactTab(n),
                ],
              ],
            ),
          ),
        ),
      );
    }

    Widget tab(int n) {
      final isOn = n == at;
      final isDone = n < at;
      final badge = Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isOn ? AppColors.navyMid : (isDone ? doneBg : Colors.white),
          border: Border.all(
            color: isOn
                ? AppColors.navyMid
                : (isDone
                    ? doneFg.withValues(alpha: 0.5)
                    : AppColors.lightBorder),
          ),
        ),
        child: isDone
            ? const Icon(Icons.check_rounded, size: 15, color: doneFg)
            : Text(
                '${n + 1}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isOn ? Colors.white : AppColors.lightSubText,
                ),
              ),
      );
      return Expanded(
        child: Material(
          color: isOn ? Colors.white : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: isOn
                ? const BorderSide(color: AppColors.lightBorder)
                : BorderSide.none,
          ),
          elevation: isOn ? 1 : 0,
          shadowColor: AppColors.navyDark.withValues(alpha: 0.15),
          child: InkWell(
            onTap: () => _goTo(shown[n], 0),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 8, vertical: isCompact ? 8 : 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  badge,
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _stepHints[shown[n]],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: isCompact ? 12.5 : 13.5,
                        fontWeight: isOn ? FontWeight.w700 : FontWeight.w600,
                        color: isOn
                            ? AppColors.navyDark
                            : (isDone ? doneFg : AppColors.lightSubText),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            for (var n = 0; n < shown.length; n++) ...[
              if (n > 0) const SizedBox(width: 4),
              tab(n),
            ],
          ],
        ),
      ),
    );
  }

  // ── Step layout on wide screens: slim step bar, section list on the left
  // with a status mark per section, the section and its buttons on the right

  bool _fieldEmpty(DynamicFieldDef f) =>
      _isBlankValue(_controllers[f.fieldKey]?.text ?? _values[f.fieldKey]);

  /// Empty in the eyes of a user: nothing typed, unticked, or a table whose
  /// rows are all blank (a repeating group starts with one empty row, which
  /// is not "filled").
  bool _isBlankValue(dynamic val) {
    if (val == null || val == false) return true;
    if (val is String) {
      final t = val.trim();
      return t.isEmpty || t == 'Select' || t == '--';
    }
    if (val is List) return val.every(_isBlankValue);
    if (val is Map) return val.values.every(_isBlankValue);
    return false;
  }

  /// done / error / none for a sub-step, from its required fields (or, for
  /// a section without required fields, whether anything is filled in).
  _SubStatus _subStatus(_SubStep s) {
    final fields = (_formDef?.fields ?? const <DynamicFieldDef>[])
        .where((f) => s.keys.contains(f.section) && _isFieldVisible(f))
        .toList();
    final required = fields.where((f) => f.isRequired).toList();
    final missing = required.where(_fieldEmpty).length;

    var customFilled = false;
    if (s.keys.contains('Acts & Sections Filed')) {
      final c = _values['charges'];
      customFilled = c is List && c.isNotEmpty;
    }
    if (s.keys.contains('Accused')) {
      customFilled =
          _accusedTypeKeys.any((t) => _accusedTypeList(t).isNotEmpty);
    }

    if (missing > 0 && s.keys.any(_errorSections.contains)) {
      return _SubStatus.error;
    }
    if (required.isNotEmpty) {
      return missing == 0 ? _SubStatus.done : _SubStatus.none;
    }
    final anyFilled = customFilled || fields.any((f) => !_fieldEmpty(f));
    return anyFilled ? _SubStatus.done : _SubStatus.none;
  }

  static const double _folderTabHeight = 42;

  /// One key per folder tab, to scroll the open tab into first place.
  final Map<String, GlobalKey> _folderTabKeys = {};
  String? _folderTabShown;

  /// After the tabs are drawn: scroll the strip so the open tab is the
  /// first one in view (1.3 open -> 1.3 at the left edge).
  void _scrollOpenTabFirst(String id) {
    if (_folderTabShown == id) return;
    _folderTabShown = id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _folderTabKeys[id]?.currentContext;
      if (ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    });
  }

  /// Section panel with folder tabs on top (1.1 Registration Info, 1.2 Acts
  /// & Sections, ...): the open tab is white and joins the panel below it,
  /// the others sit behind in grey. The panel holds the shown section,
  /// which scrolls on its own.
  Widget _buildFolderTabPanel(
      List<_SubStep> subs, int step, int current, Widget sectionArea) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;
    const radius = Radius.circular(10);

    Widget tab(int j) {
      final selected = j == current;
      final error = _subStatus(subs[j]) == _SubStatus.error;
      return Padding(
        key: _folderTabKeys.putIfAbsent('${step}_$j', GlobalKey.new),
        padding: const EdgeInsets.only(right: 4),
        child: Align(
          alignment: Alignment.topCenter,
          child: Material(
            // Open tab: solid navy, like the section chips before
            color: selected ? AppColors.navyMid : const Color(0xFFEFF2F7),
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.vertical(top: radius),
              side: BorderSide(
                color: selected ? AppColors.navyMid : const Color(0xFFE2E8F0),
              ),
            ),
            child: InkWell(
              borderRadius: const BorderRadius.vertical(top: radius),
              onTap: () => _goTo(step, j),
              child: Container(
                height: _folderTabHeight,
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 12),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      subs[j].title,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        color:
                            selected ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                    if (error) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.error_rounded,
                          size: 15,
                          color: selected ? Colors.white : AppColors.dangerRed),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Small round arrow beside the tabs: previous / next section
    Widget arrow(IconData icon, String tip, VoidCallback? onTap) => Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Tooltip(
            message: tip,
            child: Material(
              color: Colors.white,
              shape: CircleBorder(
                side: BorderSide(
                  color: onTap == null
                      ? const Color(0xFFE2E8F0)
                      : AppColors.lightBorder,
                ),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(
                    icon,
                    size: 20,
                    color: onTap == null
                        ? const Color(0xFFCBD5E1)
                        : AppColors.navyMid,
                  ),
                ),
              ),
            ),
          ),
        );

    _scrollOpenTabFirst('${step}_$current');

    final panel = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Room after the last tab, so the strip can always slide the open
        // tab to the first place (even when all tabs would fit)
        SizedBox(
          height: _folderTabHeight,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var j = 0; j < subs.length; j++) tab(j),
                  if (current > 0) SizedBox(width: constraints.maxWidth),
                ],
              ),
            ),
          ),
        ),
        // The box: only as tall as the shown section; a long section
        // scrolls inside it
        Flexible(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.lightBorder),
              borderRadius: const BorderRadius.only(
                topRight: radius,
                bottomLeft: radius,
                bottomRight: radius,
              ),
            ),
            child: SingleChildScrollView(child: sectionArea),
          ),
        ),
      ],
    );

    // Arrows outside the panel, in gutters as wide as the indent of the
    // step header and the bottom bar, so all three line up.
    // The left arrow is hidden on the very first sub-step (current == 0)
    // so the user is not confused by a disabled back arrow on page 1.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _tabArrowGutter,
          child: current > 0
              ? Align(
                  alignment: Alignment.topLeft,
                  child: arrow(Icons.chevron_left_rounded, 'Previous section',
                      () => _goTo(step, current - 1)),
                )
              : const SizedBox.shrink(),
        ),
        Expanded(child: panel),
        SizedBox(
          width: _tabArrowGutter,
          child: Align(
            alignment: Alignment.topRight,
            child: arrow(
                Icons.chevron_right_rounded,
                'Next section',
                current < subs.length - 1
                    ? () => _goTo(step, current + 1)
                    : null),
          ),
        ),
      ],
    );
  }

  /// Side gutter for the ‹ › arrows beside the tab panel; the step header
  /// and the bottom bar are indented by the same amount.
  static const double _tabArrowGutter = 38;

  String get _submitLabel => _isSubmitting
      ? 'Saving...'
      : (isEdit
          ? (widget.onSubmitCustom != null
              ? 'Save Changes'
              : 'Update Case Record')
          : 'Submit');

  /// Bottom bar of the step layout, in a white card under the section:
  /// Previous on the left, where you are and a progress bar in the middle,
  /// Next on the right. Submit sits beside Next (and replaces it on the very
  /// last section), so it can be used at any time.
  Widget _buildSubStepNav(
      List<List<_SubStep>> steps, List<int> shown, int step, int sub,
      {bool inPanel = false}) {
    (int, int)? prev;
    (int, int)? next;
    if (sub > 0) {
      prev = (step, sub - 1);
    } else {
      final at = shown.indexOf(step);
      if (at > 0) prev = (shown[at - 1], steps[shown[at - 1]].length - 1);
    }
    if (sub < steps[step].length - 1) {
      next = (step, sub + 1);
    } else {
      final at = shown.indexOf(step);
      if (at >= 0 && at < shown.length - 1) next = (shown[at + 1], 0);
    }
    // Progress over all sections of all steps
    var total = 0, done = 0;
    for (final i in shown) {
      if (i < step) done += steps[i].length;
      total += steps[i].length;
    }
    done += sub + 1;

    final w = MediaQuery.sizeOf(context).width;
    final isDesktop = w >= 1000;
    final isPhone = w < 600;
    final isLast = next == null;

    final btnShape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md));
    final btnPad = EdgeInsets.symmetric(
        horizontal: isPhone ? 12 : 18, vertical: isPhone ? 10 : 13);
    final btnText =
        GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600);

    final prevBtn = prev == null
        ? null
        : OutlinedButton.icon(
            onPressed: () => _goTo(prev!.$1, prev.$2),
            icon: const Icon(Icons.arrow_back_rounded, size: 17),
            label: Text(isPhone ? 'Back' : 'Previous', style: btnText),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navyDark,
              side: const BorderSide(color: AppColors.lightBorder),
              shape: btnShape,
              padding: btnPad,
            ),
          );

    final nextBtn = next == null
        ? null
        : ElevatedButton.icon(
            onPressed: () => _goTo(next!.$1, next.$2),
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward_rounded, size: 17),
            label: Text(
              'Next',
              overflow: TextOverflow.ellipsis,
              style: btnText,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navyMid,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: btnShape,
              padding: btnPad,
            ),
          );

    final submitIcon = _isSubmitting
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2))
        : const Icon(Icons.check_circle_outline_rounded, size: 17);
    final Widget? submitBtn = widget.readOnly
        ? null
        : isLast
            ? ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitForm,
                icon: submitIcon,
                label: Text(_submitLabel, style: btnText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyMid,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: btnShape,
                  padding: btnPad,
                ),
              )
            : OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _submitForm,
                icon: submitIcon,
                label: Text(_submitLabel, style: btnText),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navyMid,
                  side: const BorderSide(color: AppColors.navyMid),
                  shape: btnShape,
                  padding: btnPad,
                ),
              );

    final progress = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Section $done of $total',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.navyDark,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: isDesktop ? 180 : 120,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              minHeight: 5,
              backgroundColor: const Color(0xFFE2E8F0),
              color: AppColors.navyMid,
            ),
          ),
        ),
      ],
    );

    final rightButtons = <Widget>[
      if (submitBtn != null && !isLast) ...[
        submitBtn,
        const SizedBox(width: 10),
      ],
      if (nextBtn != null) Flexible(child: nextBtn),
      if (isLast && submitBtn != null) submitBtn,
    ];

    return Container(
      margin: inPanel ? EdgeInsets.zero : const EdgeInsets.only(top: 10),
      padding: EdgeInsets.symmetric(
          horizontal: isPhone ? 10 : 16, vertical: isPhone ? 10 : 12),
      decoration: inPanel
          ? const BoxDecoration(color: Color(0xFFFAFBFC))
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.lightBorder),
            ),
      child: isPhone
          // Phone: progress on top, buttons on one line under it
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: progress),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (prevBtn != null) prevBtn,
                    const Spacer(),
                    ...rightButtons,
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: prevBtn ?? const SizedBox.shrink(),
                  ),
                ),
                progress,
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: rightButtons,
                  ),
                ),
              ],
            ),
    );
  }

  BoxDecoration _sectionCardDecoration(BuildContext context) {
    if (_flatSectionCards) return const BoxDecoration(color: Colors.white);
    return BoxDecoration(
      color: Colors.white,
      borderRadius: _responsiveCardRadius(context),
      border: Border.all(color: AppColors.lightBorder),
      boxShadow: [
        BoxShadow(
          color: AppColors.navyDark.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  EdgeInsets _responsiveCardMargin(BuildContext context) {
    if (_flatSectionCards) return EdgeInsets.zero;
    final w = MediaQuery.sizeOf(context).width;
    // PC: same spacing as the other section cards, so rows line up
    if (w >= 1000) return const EdgeInsets.only(bottom: 6);
    return EdgeInsets.only(bottom: w < 600 ? 10.0 : 14.0);
  }

  BorderRadius _responsiveCardRadius(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    return BorderRadius.circular(isCompact ? AppRadius.md : AppRadius.lg);
  }

  BorderRadius _responsiveHeaderBorderRadius(
      BuildContext context, bool isExpanded) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    final r = Radius.circular(isCompact ? AppRadius.md : AppRadius.lg);
    return BorderRadius.vertical(
      top: r,
      bottom: isExpanded ? Radius.zero : r,
    );
  }

  EdgeInsets _responsiveHeaderPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    // PC: same header height as the other section cards
    if (w >= 1000) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
    }
    final isCompact = w < 600;
    return EdgeInsets.symmetric(
      horizontal: isCompact ? 12 : 16,
      vertical: isCompact ? 11 : 14,
    );
  }

  EdgeInsets _responsiveBodyPadding(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    return EdgeInsets.all(isCompact ? 12.0 : 16.0);
  }

  Widget _buildSectionIndexBadge(Object? sectionIndex,
      [IconData? fallbackIcon]) {
    // PC: the same solid navy badge as the other section cards
    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;
    return Container(
      // Grows for a longer label like "2.10"
      constraints: BoxConstraints(
        minWidth: isDesktop ? 32 : 38,
        minHeight: isDesktop ? 32 : 38,
        maxHeight: isDesktop ? 32 : 38,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: isDesktop
            ? AppColors.navyMid
            : AppColors.navyMid.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(isDesktop ? 6 : 8),
      ),
      alignment: Alignment.center,
      child: sectionIndex != null
          ? Text(
              '$sectionIndex',
              style: GoogleFonts.poppins(
                fontSize: isDesktop ? 13.5 : 15,
                fontWeight: FontWeight.w700,
                color: isDesktop ? Colors.white : AppColors.navyDark,
              ),
            )
          : Icon(fallbackIcon ?? Icons.article_outlined,
              size: isDesktop ? 18 : 20,
              color: isDesktop ? Colors.white : AppColors.navyMid),
    );
  }

  Widget _buildLegalChargesSection({Object? sectionIndex}) {
    List<dynamic>? initialCharges;
    try {
      if (widget.existingRecord != null) {
        final extra = widget.existingRecord!.extraFields;
        final common =
            (extra['commonForm'] is Map) ? (extra['commonForm'] as Map) : null;
        final rawCharges = extra['charges'] ??
            extra['acts_sections'] ??
            common?['charges'] ??
            common?['acts_sections'];

        if (rawCharges is List) {
          initialCharges = rawCharges;
        } else if (rawCharges is Map) {
          final list = <Map<String, dynamic>>[];
          for (final entry in rawCharges.entries) {
            final val = entry.value;
            if (val is Map) {
              final act = val['act_id'] ?? val['act'] ?? val['act_name'];
              final actName = val['act_name']?.toString() ??
                  (val['act'] is String ? val['act']?.toString() : null);
              final secs = val['sections'] ??
                  val['section_ids'] ??
                  val['section_id'] ??
                  val['section'];
              if (secs is Iterable) {
                for (final s in secs) {
                  if (s is Map) {
                    list.add(Map<String, dynamic>.from(s));
                  } else {
                    list.add({
                      'act': act,
                      'act_id': val['act_id'] ?? val['act'],
                      'act_name': actName,
                      'section': s,
                      'section_number': s.toString(),
                    });
                  }
                }
              } else {
                list.add(Map<String, dynamic>.from(val));
              }
            }
          }
          if (list.isNotEmpty) {
            initialCharges = list;
          } else if (rawCharges.containsKey('act') ||
              rawCharges.containsKey('act_id') ||
              rawCharges.containsKey('section') ||
              rawCharges.containsKey('section_id')) {
            initialCharges = [Map<String, dynamic>.from(rawCharges)];
          }
        }
      }
    } catch (_) {
      initialCharges = null;
    }

    if ((initialCharges == null || initialCharges.isEmpty) &&
        _selectedCharges.isNotEmpty) {
      final list = <Map<String, dynamic>>[];
      for (final entry in _selectedCharges.entries) {
        for (final sec in entry.value) {
          list.add({
            'act': entry.key,
            'act_name': entry.key,
            'section': sec,
            'section_number': sec,
          });
        }
      }
      if (list.isNotEmpty) initialCharges = list;
    }

    int chargeCount = 0;
    final rawVal = _values['charges'];
    if (rawVal is List) {
      chargeCount = rawVal.length;
    } else if (rawVal is Map) {
      chargeCount = rawVal.length;
    } else if (initialCharges != null) {
      chargeCount = initialCharges.length;
    }
    final countSuffix = chargeCount > 0 ? ' ($chargeCount)' : '';

    if (widget.readOnly && _hideEmptyInViewMode && chargeCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      key: const ValueKey('sec_Acts & Sections Filed'),
      margin: _responsiveCardMargin(context),
      decoration: _sectionCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inside the tab panel the tab names the section: no header
          if (!_flatSectionCards)
            InkWell(
              onTap: () => _toggleSection('Acts & Sections Filed'),
              borderRadius: _responsiveHeaderBorderRadius(
                  context, _chargesSectionExpanded),
              child: Padding(
                padding: _responsiveHeaderPadding(context),
                child: Row(
                  children: [
                    _buildSectionIndexBadge(sectionIndex, Icons.gavel_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Acts & Sections Filed$countSuffix',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDark,
                        ),
                      ),
                    ),
                    // No collapse arrow in the step layout (sections stay open)
                    if (!_sectionsAlwaysOpen)
                      Tooltip(
                        message:
                            _chargesSectionExpanded ? 'Collapse' : 'Expand',
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: AnimatedRotation(
                            turns: _chargesSectionExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOutCubic,
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.navyMid,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_flatSectionCards)
                  const Divider(height: 1, color: AppColors.lightBorder),
                Padding(
                  padding: _responsiveBodyPadding(context),
                  child: RepeatingCascadingChargesSelector(
                    initialCharges: initialCharges,
                    readOnly: widget.readOnly,
                    onChargesChanged: (chargesList) {
                      _values['charges'] = chargesList;
                      _values['acts_sections'] = chargesList;
                    },
                    onSectionIdsChanged: widget.readOnly
                        ? null
                        : (sectionIds) {
                            _triggerBDebounce?.cancel();
                            _triggerBDebounce =
                                Timer(const Duration(milliseconds: 300), () {
                              final allSections =
                                  sectionIds.map((s) => s.toString()).toList();
                              _loadFormDefinition(chargedSections: allSections);
                            });
                          },
                  ),
                ),
              ],
            ),
            crossFadeState: _chargesSectionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOutCubic,
          ),
        ],
      ),
    );
  }

  List<String> _getAvailableAccusedNames() {
    final names = <String>{};

    void addName(String? raw) {
      final t = _sanitizeName(raw);
      if (t.isEmpty) return;
      if (t.contains(',')) {
        for (final p in t.split(',')) {
          final s = _sanitizeName(p);
          if (s.isNotEmpty) names.add(s);
        }
      } else {
        names.add(t);
      }
    }

    bool isNameFieldKey(String rawKey) {
      final k = rawKey.toLowerCase();
      if (!k.contains('accused') &&
          !k.contains('suspect') &&
          !k.contains('arrest')) {
        return false;
      }
      if (k.contains('discharge') ||
          k.contains('date') ||
          k.contains('time') ||
          k.contains('relation') ||
          k.contains('relative') ||
          k.contains('sec_') ||
          k.contains('age') ||
          k.contains('gender') ||
          k.contains('mobile') ||
          k.contains('aadhaar') ||
          k.contains('pan') ||
          k.contains('religion') ||
          k.contains('caste') ||
          k.contains('address') ||
          k.contains('occupation') ||
          k.contains('occ') ||
          k.contains('skin') ||
          k.contains('mark') ||
          k.contains('height') ||
          k.contains('desc')) {
        return false;
      }
      return k.endsWith('name') || k == 'accused' || k == 'suspect';
    }

    // From multiple accused list
    for (final it in _accusedList) {
      addName(it['name']?.toString());
    }

    // From suspected accused list
    for (final it in _suspectedAccusedList) {
      addName(it['name']?.toString());
    }

    // From arrest records list
    for (final it in _arrestRecordsList) {
      addName(it['arrested_person_name']?.toString() ??
          it['person_name']?.toString() ??
          it['name']?.toString());
    }

    // From current form controllers
    for (final entry in _controllers.entries) {
      if (isNameFieldKey(entry.key)) {
        addName(entry.value.text);
      }
    }

    // From current form values
    for (final entry in _values.entries) {
      if (isNameFieldKey(entry.key)) {
        if (entry.value is String) {
          addName(entry.value as String);
        }
      }
    }

    // From existing record
    if (widget.existingRecord != null) {
      addName(widget.existingRecord!.accused);

      final extra = widget.existingRecord!.extraFields;
      final common =
          (extra['commonForm'] is Map) ? extra['commonForm'] as Map : {};

      for (final src in [common, extra]) {
        final accList = src['accused'];
        if (accList is List) {
          for (final item in accList) {
            if (item is Map) {
              addName(
                  item['name']?.toString() ?? item['accused_name']?.toString());
            } else if (item is String) {
              addName(item);
            }
          }
        }
        final arrestList = src['arrests'] ?? src['arrest_records'];
        if (arrestList is List) {
          for (final item in arrestList) {
            if (item is Map) {
              addName(item['name']?.toString() ??
                  item['person_name']?.toString() ??
                  item['arrested_person_name']?.toString() ??
                  item['accused']?.toString());
            } else if (item is String) {
              addName(item);
            }
          }
        }
        final suspList = src['suspectedAccused'] ??
            src['suspected_accused'] ??
            src['suspects'];
        if (suspList is List) {
          for (final item in suspList) {
            if (item is Map) {
              addName(item['name']?.toString() ??
                  item['suspected_accused_name']?.toString() ??
                  item['suspect_name']?.toString());
            } else if (item is String) {
              addName(item);
            }
          }
        }
        final personsList = src['persons'];
        if (personsList is List) {
          for (final item in personsList) {
            if (item is Map) {
              final r = (item['role'] ?? '').toString().toLowerCase();
              if (r == 'accused' ||
                  r == 'suspected_accused' ||
                  r == 'suspect' ||
                  r == 'arrested') {
                addName(item['name']?.toString());
              }
            }
          }
        }
        final prevList =
            src['preventive_actions'] ?? src['preventive_action_items'];
        if (prevList is List) {
          for (final item in prevList) {
            if (item is Map) {
              addName(item['name']?.toString() ??
                  item['person_name']?.toString() ??
                  item['accusedName']?.toString());
            }
          }
        }
      }
    }

    // From already recorded preventive actions
    for (final it in _preventiveActionsList) {
      addName(it['name']?.toString());
    }

    // From already recorded custody records
    for (final it in _custodyRecordsList) {
      addName(it['name']?.toString() ?? it['person_name']?.toString());
    }

    // From already discharged keys
    for (final k in _dischargedAccusedMap.keys) {
      if (k.trim().isNotEmpty) names.add(k.trim());
    }

    return names.toList()..sort();
  }

  Widget _buildDischargeAccusedSection({Object? sectionIndex}) {
    if (widget.readOnly && _hideEmptyInViewMode && !_hasAnyDischargeData) {
      return const SizedBox.shrink();
    }
    final availableAccused = _getAvailableAccusedNames();

    return Container(
      margin: _responsiveCardMargin(context),
      decoration: _sectionCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          // Inside the tab panel the tab names the section: no header
          if (!_flatSectionCards)
            InkWell(
              onTap: () => _toggleSection('Discharge Accused'),
              borderRadius: _responsiveHeaderBorderRadius(
                  context, _dischargeSectionExpanded),
              child: Padding(
                padding: _responsiveHeaderPadding(context),
                child: Row(
                  children: [
                    _buildSectionIndexBadge(
                        sectionIndex, Icons.person_remove_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Discharge Accused',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _dischargedAccusedList.isNotEmpty
                            ? AppColors.dangerRed.withValues(alpha: 0.12)
                            : AppColors.navyMid.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _dischargedAccusedList.isNotEmpty
                            ? '${_dischargedAccusedList.length} discharged'
                            : '${availableAccused.length} available',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _dischargedAccusedList.isNotEmpty
                              ? AppColors.dangerRed
                              : AppColors.navyMid,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // No collapse arrow in the step layout (sections stay open)
                    if (!_sectionsAlwaysOpen)
                      Tooltip(
                        message:
                            _dischargeSectionExpanded ? 'Collapse' : 'Expand',
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: AnimatedRotation(
                            turns: _dischargeSectionExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOutCubic,
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.navyMid,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_flatSectionCards)
                  const Divider(height: 1, color: AppColors.lightBorder),
                Padding(
                  padding: _responsiveBodyPadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Single Field Row: Select Accused + Add Button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Select Accused to Discharge',
                                labelStyle: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.lightSubText),
                                prefixIcon: const Icon(
                                    Icons.person_search_rounded,
                                    size: 20,
                                    color: AppColors.navyMid),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  borderSide: const BorderSide(
                                      color: AppColors.lightBorder),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  borderSide: const BorderSide(
                                      color: AppColors.lightBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  borderSide: const BorderSide(
                                      color: AppColors.navyMid, width: 1.5),
                                ),
                              ),
                              hint: Text(
                                availableAccused.isEmpty
                                    ? 'No accused entered yet in form'
                                    : 'Choose an accused to discharge...',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.lightSubText),
                              ),
                              key: ValueKey(_selectedAccusedToDischarge),
                              initialValue: _selectedAccusedToDischarge,
                              isExpanded: true,
                              items: [
                                ...availableAccused
                                    .where((name) =>
                                        !_dischargedAccusedList.contains(name))
                                    .map((name) => DropdownMenuItem<String>(
                                          value: name,
                                          child: Text(
                                            name,
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.navyDark,
                                            ),
                                          ),
                                        )),
                                const DropdownMenuItem<String>(
                                  value: '__custom__',
                                  child: Text(
                                    '+ Type other accused name...',
                                    style: TextStyle(
                                      color: AppColors.navyMid,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: widget.readOnly
                                  ? null
                                  : (selectedName) {
                                      if (selectedName == '__custom__') {
                                        _showAddCustomAccusedDialog();
                                      } else if (selectedName != null) {
                                        setState(() {
                                          _selectedAccusedToDischarge =
                                              selectedName;
                                        });
                                      }
                                    },
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (!widget.readOnly)
                            ElevatedButton.icon(
                              onPressed: _selectedAccusedToDischarge == null
                                  ? null
                                  : () {
                                      final name = _selectedAccusedToDischarge!;
                                      if (!_dischargedAccusedList
                                          .contains(name)) {
                                        setState(() {
                                          _dischargedAccusedList.add(name);
                                          _dischargedAccusedMap[name] = true;
                                          _dischargeDateControllers.putIfAbsent(
                                              name,
                                              () => TextEditingController(
                                                  text: DateFormat('dd/MM/yyyy')
                                                      .format(DateTime.now())));
                                          _selectedAccusedToDischarge = null;
                                        });
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.navyMid,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 15),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.add_rounded,
                                  size: 18, color: Colors.white),
                              label: Text(
                                'Add',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white),
                              ),
                            ),
                        ],
                      ),

                      // Display added discharged accused with Discharge Date
                      if (_dischargedAccusedList.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ..._dischargedAccusedList.map((accName) {
                          final dateCtrl =
                              _dischargeDateControllers.putIfAbsent(
                            accName,
                            () => TextEditingController(
                              text: DateFormat('dd/MM/yyyy')
                                  .format(DateTime.now()),
                            ),
                          );

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Row: Accused Name + Discharged Badge + Delete
                                Row(
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFEE2E2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.person_remove_rounded,
                                        size: 16,
                                        color: AppColors.dangerRed,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(
                                            accName,
                                            style: GoogleFonts.poppins(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.navyDark,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF2F2),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                  color:
                                                      const Color(0xFFFECACA)),
                                            ),
                                            child: Text(
                                              'Discharged',
                                              style: GoogleFonts.poppins(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.dangerRed,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!widget.readOnly)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 19,
                                          color: AppColors.dangerRed,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _dischargedAccusedList
                                                .remove(accName);
                                            _dischargedAccusedMap[accName] =
                                                false;
                                            _dischargeDateControllers
                                                .remove(accName);
                                          });
                                        },
                                        tooltip: 'Remove',
                                        splashRadius: 18,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Discharge Date field
                                TextFormField(
                                  controller: dateCtrl,
                                  readOnly: true,
                                  onTap: widget.readOnly
                                      ? null
                                      : () => _pickDateForController(
                                          context, dateCtrl),
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.navyDark,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Discharge Date',
                                    hintText: 'DD/MM/YYYY',
                                    labelStyle: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColors.lightSubText),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    suffixIcon: IconButton(
                                      icon: const Icon(
                                        Icons.calendar_month_rounded,
                                        size: 20,
                                        color: AppColors.navyMid,
                                      ),
                                      onPressed: widget.readOnly
                                          ? null
                                          : () => _pickDateForController(
                                              context, dateCtrl),
                                      tooltip: 'Select date',
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md),
                                      borderSide: const BorderSide(
                                          color: AppColors.lightBorder),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md),
                                      borderSide: const BorderSide(
                                          color: AppColors.lightBorder),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md),
                                      borderSide: const BorderSide(
                                          color: AppColors.navyMid, width: 1.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: _dischargeSectionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOutCubic,
          ),
        ],
      ),
    );
  }

  void _showAddCustomAccusedDialog() {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(
          'Add Accused to Discharge',
          style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.navyDark),
        ),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Accused Name',
            hintText: 'Enter name...',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = textCtrl.text.trim();
              if (val.isNotEmpty && !_dischargedAccusedList.contains(val)) {
                setState(() {
                  _dischargedAccusedList.add(val);
                  _dischargedAccusedMap[val] = true;
                  _dischargeDateControllers.putIfAbsent(
                      val,
                      () => TextEditingController(
                          text:
                              DateFormat('dd/MM/yyyy').format(DateTime.now())));
                  _selectedAccusedToDischarge = null;
                });
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyMid),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // ── Multiple Accused Section & Helpers ─────────────────────────────
  void _syncPrimaryAccusedControllers() {
    if (_accusedList.isNotEmpty) {
      final first = _accusedList.first;
      _controllers['accused_name']?.text = first['name']?.toString() ?? '';
      _controllers['accused_age']?.text = first['age']?.toString() ?? '';
      _values['accused_gender'] = first['gender']?.toString() ?? '';
      _controllers['accused_gender']?.text = first['gender']?.toString() ?? '';
      _controllers['accused_occupation']?.text =
          first['occupation']?.toString() ?? '';
      _controllers['accused_mobile']?.text = first['mobile']?.toString() ?? '';
      _controllers['accused_aadhaar']?.text =
          first['aadhaar']?.toString() ?? '';
      _controllers['accused_pan']?.text = first['pan']?.toString() ?? '';
      _controllers['accused_religion']?.text =
          first['religion']?.toString() ?? '';
      _controllers['accused_caste']?.text = first['caste']?.toString() ?? '';
      _controllers['accused_address']?.text =
          first['address']?.toString() ?? '';
    }
  }

  Widget _accusedBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_accusedList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No accused persons added yet.',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: AppColors.lightSubText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          )
        else ...[
          ..._accusedList.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return _InlinePersonCard(
              genderOptions: _genderOptions,
              showMedical: true,
              yesNoOptions: _yesNoOptions,
              key: ObjectKey(item),
              index: idx,
              roleTitle: 'Accused',
              data: item,
              readOnly: widget.readOnly,
              canRemove: !widget.readOnly,
              collapsed: _personCollapsed(item),
              onToggle: widget.readOnly ? null : () => _togglePerson(item),
              onRemove: () {
                setState(() {
                  _accusedList.removeAt(idx);
                  _syncPrimaryAccusedControllers();
                });
              },
              onChanged: () {
                // Typing keeps this card open
                _openPerson = item;
                if (idx == 0) {
                  _syncPrimaryAccusedControllers();
                }
              },
            );
          }),
        ],
      ],
    );
  }

  Widget _suspectedAccusedBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_suspectedAccusedList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No suspected accused persons added yet.',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: AppColors.lightSubText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          )
        else ...[
          ..._suspectedAccusedList.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return _InlinePersonCard(
              genderOptions: _genderOptions,
              key: ObjectKey(item),
              index: idx,
              roleTitle: 'Suspect',
              data: item,
              readOnly: widget.readOnly,
              canRemove: !widget.readOnly,
              collapsed: _personCollapsed(item),
              onToggle: widget.readOnly ? null : () => _togglePerson(item),
              onRemove: () {
                setState(() {
                  _suspectedAccusedList.removeAt(idx);
                  _syncPrimarySuspectedAccusedControllers();
                });
              },
              onChanged: () {
                // Typing keeps this card open
                _openPerson = item;
                if (idx == 0) {
                  _syncPrimarySuspectedAccusedControllers();
                }
              },
            );
          }),
        ],
      ],
    );
  }

  Widget _unidentifiedAccusedBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_unidentifiedAccusedList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No unidentified accused persons added yet.',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: AppColors.lightSubText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          )
        else ...[
          ..._unidentifiedAccusedList.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return _InlineUnidentifiedAccusedCard(
              genderOptions: _genderOptions,
              key: ObjectKey(item),
              index: idx,
              data: item,
              readOnly: widget.readOnly,
              canRemove: !widget.readOnly,
              collapsed: _personCollapsed(item),
              onToggle: widget.readOnly ? null : () => _togglePerson(item),
              onRemove: () {
                setState(() {
                  _unidentifiedAccusedList.removeAt(idx);
                  _syncPrimaryUnidentifiedControllers();
                });
              },
              onChanged: () {
                // Typing keeps this card open
                _openPerson = item;
                if (idx == 0) {
                  _syncPrimaryUnidentifiedControllers();
                }
              },
            );
          }),
        ],
      ],
    );
  }

  Widget _unknownAccusedBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_unknownAccusedList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No unknown accused added yet. Click "+ Add" above to record unknown accused persons.',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AppColors.lightSubText,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ..._unknownAccusedList.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.navyMid.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${idx + 1}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyMid,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item['name']?.toString().isNotEmpty == true
                          ? item['name'].toString()
                          : 'Unknown Accused #${idx + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ),
                  if (!widget.readOnly)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 18, color: AppColors.dangerRed),
                      onPressed: () {
                        setState(() {
                          _unknownAccusedList.removeAt(idx);
                        });
                      },
                      tooltip: 'Remove',
                      splashRadius: 16,
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ── Accused card: one card for all four accused types ─────────────────
  static const _accusedTypeKeys = [
    'Accused',
    'Suspected Accused',
    'Unidentified Accused',
    'Unknown Accused',
  ];

  List<Map<String, dynamic>> _accusedTypeList(String type) {
    switch (type) {
      case 'Suspected Accused':
        return _suspectedAccusedList;
      case 'Unidentified Accused':
        return _unidentifiedAccusedList;
      case 'Unknown Accused':
        return _unknownAccusedList;
      default:
        return _accusedList;
    }
  }

  Widget _accusedTypeBody(String type) {
    switch (type) {
      case 'Suspected Accused':
        return _suspectedAccusedBody();
      case 'Unidentified Accused':
        return _unidentifiedAccusedBody();
      case 'Unknown Accused':
        return _unknownAccusedBody();
      default:
        return _accusedBody();
    }
  }

  void _syncAccusedType(String type) {
    switch (type) {
      case 'Suspected Accused':
        _syncPrimarySuspectedAccusedControllers();
      case 'Unidentified Accused':
        _syncPrimaryUnidentifiedControllers();
      case 'Unknown Accused':
        break;
      default:
        _syncPrimaryAccusedControllers();
    }
  }

  /// Adds a blank person of this accused type and opens it (folding the
  /// others), from the "+ Add" next to the type's heading.
  void _addAccusedOf(String type) {
    setState(() {
      final list = _accusedTypeList(type);
      if (type == 'Unknown Accused') {
        list.add({
          'name': 'Unknown Accused #${list.length + 1}',
          'role': 'unknown_accused',
        });
      } else if (type == 'Unidentified Accused') {
        list.add(_openPerson = {'approximate_age': '', 'gender': ''});
      } else {
        list.add(_openPerson = {'name': '', 'gender': ''});
      }
      _syncAccusedType(type);
    });
  }

  bool _isAccusedTypeShown(String type) =>
      _pickedAccusedTypes.contains(type) || _accusedTypeList(type).isNotEmpty;

  /// Ticks or unticks a type. Ticking opens it with one blank person;
  /// unticking a type that has people asks before clearing them.
  Future<void> _setAccusedType(String type, bool on) async {
    final list = _accusedTypeList(type);
    if (on) {
      setState(() {
        _pickedAccusedTypes.add(type);
        if (list.isEmpty) {
          list.add(type == 'Unknown Accused'
              ? {'name': 'Unknown Accused #1', 'role': 'unknown_accused'}
              : (_openPerson = {'name': '', 'gender': ''}));
          _syncAccusedType(type);
        }
      });
      return;
    }
    final hasData = list.any((p) => p.entries.any((e) =>
        e.key != 'role' &&
        e.value != null &&
        e.value.toString().trim().isNotEmpty &&
        !(type == 'Unknown Accused' && e.key == 'name')));
    if (hasData) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Remove $type?'),
          content: Text(
              'This removes the ${list.length} ${type.toLowerCase()} entered '
              'in this form.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.dangerRed),
                child: const Text('Remove')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    setState(() {
      _pickedAccusedTypes.remove(type);
      list.clear();
      _syncAccusedType(type);
    });
  }

  /// The accused type open in the card: the one picked, else the first type
  /// that has people, else none.
  String? _currentAccusedType(List<String> types) {
    if (_activeAccusedType != null && types.contains(_activeAccusedType)) {
      return _activeAccusedType;
    }
    for (final t in types) {
      if (_isAccusedTypeShown(t)) return t;
    }
    return null;
  }

  /// Picks the accused type to add now (one at a time). A type with no
  /// people yet opens with one blank person; other types keep theirs.
  void _pickAccusedType(String type) {
    setState(() => _activeAccusedType = type);
    if (_accusedTypeList(type).isEmpty) _setAccusedType(type, true);
  }

  /// Single-select dropdown: pick one accused type at a time. Each choice
  /// shows how many people it already has.
  Widget _buildAccusedTypePicker(List<String> types) {
    final current = _currentAccusedType(types);
    final picked = current == null ? const <String>[] : [current];
    final fieldText = current ?? 'Select accused type';
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md))),
      ),
      menuChildren: [
        for (final t in types)
          MenuItemButton(
            onPressed: () => _pickAccusedType(t),
            leadingIcon: Icon(
              t == current
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: t == current ? AppColors.navyMid : const Color(0xFF94A3B8),
            ),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                _accusedTypeList(t).isEmpty
                    ? t
                    : '$t (${_accusedTypeList(t).length})',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.navyDark),
              ),
            ),
          ),
      ],
      builder: (context, controller, _) => InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: widget.readOnly
            ? null
            : () => controller.isOpen ? controller.close() : controller.open(),
        child: InputDecorator(
          isFocused: controller.isOpen,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            suffixIcon: Icon(
              controller.isOpen
                  ? Icons.arrow_drop_up_rounded
                  : Icons.arrow_drop_down_rounded,
              color: AppColors.navyMid,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide:
                  const BorderSide(color: AppColors.navyMid, width: 1.5),
            ),
          ),
          child: Text(
            fieldText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: picked.isEmpty ? FontWeight.w400 : FontWeight.w500,
              color:
                  picked.isEmpty ? const Color(0xFF94A3B8) : AppColors.navyDark,
            ),
          ),
        ),
      ),
    );
  }

  /// "Added so far": everyone entered under any accused type, as chips
  /// ("Accused · Gauri", "Suspect · Ramesh"). The dropdown shows one type at
  /// a time; a chip switches to its type and opens that person, so people of
  /// other types stay in view. Hidden until someone has been filled in.
  Widget _buildAddedAccusedStrip(List<String> types, String? current) {
    const short = {
      'Accused': 'Accused',
      'Suspected Accused': 'Suspect',
      'Unidentified Accused': 'Unidentified',
      'Unknown Accused': 'Unknown',
    };
    final chips = <Widget>[];
    for (final type in types) {
      final list = _accusedTypeList(type);
      // Unknown Accused: one chip with how many ("Unknown · 2"); the others
      // one chip per filled person
      final entries = <(Map<String, dynamic>?, String)>[];
      if (type == 'Unknown Accused') {
        if (list.isNotEmpty) entries.add((null, '${list.length}'));
      } else {
        for (var i = 0; i < list.length; i++) {
          if (!_personFilled(list[i])) continue;
          final name = (list[i]['name']?.toString().trim() ?? '');
          entries.add((list[i], name.isNotEmpty ? name : '#${i + 1}'));
        }
      }
      for (final (person, label) in entries) {
        final isOpen =
            type == current && person != null && identical(person, _openPerson);
        chips.add(InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() {
            _activeAccusedType = type;
            _openPerson = person;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: type == current
                  ? AppColors.navyMid.withValues(alpha: 0.08)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isOpen
                    ? AppColors.navyMid
                    : (type == current
                        ? AppColors.navyMid.withValues(alpha: 0.35)
                        : AppColors.lightBorder),
              ),
            ),
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: '${short[type] ?? type} · ',
                  style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.lightSubText),
                ),
                TextSpan(
                  text: label,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navyDark),
                ),
              ]),
            ),
          ),
        ));
      }
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Added so far',
            style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155)),
          ),
          ...chips,
        ],
      ),
    );
  }

  /// Body of the Accused card: the type dropdown, then each ticked type's
  /// people under its own heading.
  Widget _mergedAccusedBody(List<String> types) {
    // Editing: only the type picked in the dropdown. Viewing: every type
    // that has people.
    final current = _currentAccusedType(types);
    final shown = widget.readOnly
        ? types.where(_isAccusedTypeShown).toList()
        : [if (current != null) current];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.readOnly) ...[
          Text(
            'Accused type',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          _buildAccusedTypePicker(types),
          _buildAddedAccusedStrip(types, current),
        ],
        if (shown.isEmpty && widget.readOnly)
          Text(
            'No accused added.',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: AppColors.lightSubText,
              fontStyle: FontStyle.italic,
            ),
          ),
        for (final t in shown) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.navyMid,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.navyMid,
                  ),
                ),
              ),
              Text(
                '${_accusedTypeList(t).length}',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightSubText,
                ),
              ),
              if (!widget.readOnly) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _addAccusedOf(t),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.navyMid,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    'Add',
                    style: GoogleFonts.poppins(
                        fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          _accusedTypeBody(t),
        ],
      ],
    );
  }

  Widget _buildAccusedSection(
      {Object? sectionIndex, List<String> types = const ['Accused']}) {
    final total = types.fold<int>(0, (n, t) => n + _accusedTypeList(t).length);
    return Container(
      margin: _responsiveCardMargin(context),
      decoration: _sectionCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          // Inside the tab panel the tab names the section: no header
          if (!_flatSectionCards)
            InkWell(
              onTap: () => _toggleSection('Accused'),
              borderRadius: _responsiveHeaderBorderRadius(
                  context, _accusedSectionExpanded),
              child: Padding(
                padding: _responsiveHeaderPadding(context),
                child: Row(
                  children: [
                    _buildSectionIndexBadge(
                        sectionIndex, Icons.person_pin_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Accused',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$total accused',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navyMid,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // No collapse arrow in the step layout (sections stay open)
                    if (!_sectionsAlwaysOpen)
                      Tooltip(
                        message:
                            _accusedSectionExpanded ? 'Collapse' : 'Expand',
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: AnimatedRotation(
                            turns: _accusedSectionExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOutCubic,
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.navyMid,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_flatSectionCards)
                  const Divider(height: 1, color: AppColors.lightBorder),
                Padding(
                  padding: _responsiveBodyPadding(context),
                  child: _mergedAccusedBody(types),
                ),
              ],
            ),
            crossFadeState: _accusedSectionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOutCubic,
          ),
        ],
      ),
    );
  }

  // ── Suspected Accused Section & Helpers ─────────────────────────────
  void _syncPrimarySuspectedAccusedControllers() {
    if (_suspectedAccusedList.isNotEmpty) {
      final first = _suspectedAccusedList.first;
      _controllers['suspected_accused_name']?.text =
          first['name']?.toString() ?? '';
      _controllers['suspected_accused_age']?.text =
          first['age']?.toString() ?? '';
      _values['suspected_accused_gender'] = first['gender']?.toString() ?? '';
      _controllers['suspected_accused_gender']?.text =
          first['gender']?.toString() ?? '';
      _controllers['suspected_accused_occupation']?.text =
          first['occupation']?.toString() ?? '';
      _controllers['suspected_accused_mobile']?.text =
          first['mobile']?.toString() ?? '';
      _controllers['suspected_accused_aadhaar']?.text =
          first['aadhaar']?.toString() ?? '';
      _controllers['suspected_accused_pan']?.text =
          first['pan']?.toString() ?? '';
      _controllers['suspected_accused_religion']?.text =
          first['religion']?.toString() ?? '';
      _controllers['suspected_accused_caste']?.text =
          first['caste']?.toString() ?? '';
      _controllers['suspected_accused_address']?.text =
          first['address']?.toString() ?? '';
    }
  }

  // ── Unidentified Accused Section & Helpers ───────────────────────────
  void _syncPrimaryUnidentifiedControllers() {
    if (_unidentifiedAccusedList.isNotEmpty) {
      final first = _unidentifiedAccusedList.first;
      _controllers['approximate_age']?.text =
          first['approximate_age']?.toString() ?? '';
      _values['unidentified_gender'] = first['gender']?.toString() ?? '';
      _controllers['unidentified_gender']?.text =
          first['gender']?.toString() ?? '';
      _controllers['skin_colour']?.text =
          first['skin_colour']?.toString() ?? '';
      _controllers['possible_occupation']?.text =
          first['possible_occupation']?.toString() ?? '';
      _controllers['identification_mark']?.text =
          first['identification_mark']?.toString() ?? '';
      _controllers['height']?.text = first['height']?.toString() ?? '';
      _controllers['description']?.text =
          first['description']?.toString() ?? '';
      _controllers['unidentified_address']?.text =
          first['address']?.toString() ?? '';
    }
  }

  // ── Arrest Section & Helpers ─────────────────────────────────────────
  void _syncPrimaryArrestControllers() {
    if (_arrestRecordsList.isNotEmpty) {
      final first = _arrestRecordsList.first;
      final pName = (first['arrested_person_name'] ??
                  first['person_name'] ??
                  first['name'])
              ?.toString() ??
          '';
      _controllers['arrested_person_name']?.text = pName;
      _values['arrested_person_name'] = pName;
      _controllers['arrest_datetime']?.text =
          first['arrest_datetime']?.toString() ?? '';
      _values['sec_47_48_bnss'] = first['sec_47_48_bnss'] == true;
      _controllers['relative_friend_name']?.text =
          first['relative_friend_name']?.toString() ?? '';
      _controllers['relative_friend_relation']?.text =
          first['relative_friend_relation']?.toString() ?? '';
      _values['release_on_notice'] = first['release_on_notice'] == true;
      _controllers['release_on_notice_datetime']?.text =
          first['release_on_notice_datetime']?.toString() ?? '';
      _values['anticipatory_bail'] = first['anticipatory_bail'] == true;
      _controllers['anticipatory_bail_datetime']?.text =
          first['anticipatory_bail_datetime']?.toString() ?? '';
      _values['death_of_accused'] = first['death_of_accused'] == true;
      _controllers['death_of_accused_datetime']?.text =
          first['death_of_accused_datetime']?.toString() ?? '';
    } else {
      _controllers['arrested_person_name']?.clear();
      _values.remove('arrested_person_name');
      _controllers['arrest_datetime']?.clear();
      _values.remove('arrest_datetime');
      _values['sec_47_48_bnss'] = false;
      _controllers['relative_friend_name']?.clear();
      _values.remove('relative_friend_name');
      _controllers['relative_friend_relation']?.clear();
      _values.remove('relative_friend_relation');
      _values['release_on_notice'] = false;
      _controllers['release_on_notice_datetime']?.clear();
      _values.remove('release_on_notice_datetime');
      _values['anticipatory_bail'] = false;
      _controllers['anticipatory_bail_datetime']?.clear();
      _values.remove('anticipatory_bail_datetime');
      _values['death_of_accused'] = false;
      _controllers['death_of_accused_datetime']?.clear();
      _values.remove('death_of_accused_datetime');
    }
  }

  // ignore: unused_element
  Future<void> _pickDateTime(
      BuildContext context, TextEditingController ctrl) async {
    DateTime initial = DateTime.now();
    TimeOfDay initialTime = TimeOfDay.now();
    final cur = ctrl.text.trim();
    if (cur.isNotEmpty) {
      final parts = cur.split(' ');
      if (parts.isNotEmpty) {
        final dParts = parts[0].split('/');
        if (dParts.length == 3) {
          final d = int.tryParse(dParts[0]) ?? initial.day;
          final m = int.tryParse(dParts[1]) ?? initial.month;
          final y = int.tryParse(dParts[2]) ?? initial.year;
          initial = DateTime(y, m, d);
        }
      }
      if (parts.length > 1) {
        final tParts = parts[1].split(':');
        if (tParts.length >= 2) {
          final hr = int.tryParse(tParts[0]) ?? initialTime.hour;
          final mn = int.tryParse(tParts[1]) ?? initialTime.minute;
          initialTime = TimeOfDay(hour: hr, minute: mn);
        }
      }
    }
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && context.mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );
      final finalDt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? initialTime.hour,
        pickedTime?.minute ?? initialTime.minute,
      );
      ctrl.text = DateFormat('dd/MM/yyyy HH:mm').format(finalDt);
    }
  }

  Future<void> _pickDateTimeForRecord(BuildContext context,
      Map<String, dynamic> record, String fieldKey) async {
    DateTime initial = DateTime.now();
    TimeOfDay initialTime = TimeOfDay.now();
    final cur = (record[fieldKey] ?? '').toString().trim();
    if (cur.isNotEmpty) {
      final parts = cur.split(' ');
      if (parts.isNotEmpty) {
        final dParts = parts[0].split('/');
        if (dParts.length == 3) {
          final d = int.tryParse(dParts[0]) ?? initial.day;
          final m = int.tryParse(dParts[1]) ?? initial.month;
          final y = int.tryParse(dParts[2]) ?? initial.year;
          initial = DateTime(y, m, d);
        }
      }
      if (parts.length > 1) {
        final tParts = parts[1].split(':');
        if (tParts.length >= 2) {
          final hr = int.tryParse(tParts[0]) ?? initialTime.hour;
          final mn = int.tryParse(tParts[1]) ?? initialTime.minute;
          initialTime = TimeOfDay(hour: hr, minute: mn);
        }
      }
    }
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && context.mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );
      final finalDt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? initialTime.hour,
        pickedTime?.minute ?? initialTime.minute,
      );
      setState(() {
        record[fieldKey] = DateFormat('dd/MM/yyyy HH:mm').format(finalDt);
        _syncPrimaryArrestControllers();
      });
    }
  }

  Widget _buildArrestSection({Object? sectionIndex, String? onlyFor}) {
    if (widget.readOnly && _hideEmptyInViewMode && !_hasAnyArrestData) {
      return const SizedBox.shrink();
    }
    // 1. Gather all unique accused/suspect names
    final availableAccused = _getAvailableAccusedNames();
    final allDisplayNames = <String>[...availableAccused];

    // Include any custom person already present in _arrestRecordsList
    for (final r in _arrestRecordsList) {
      final n = (r['arrested_person_name'] ?? r['person_name'] ?? r['name'])
              ?.toString()
              .trim() ??
          '';
      if (n.isNotEmpty &&
          !allDisplayNames.any((x) => x.toLowerCase() == n.toLowerCase())) {
        allDisplayNames.add(n);
      }
    }
    // Only the accused picked in the arrest & custody panel
    if (onlyFor != null) {
      allDisplayNames
          .retainWhere((n) => n.toLowerCase() == onlyFor.toLowerCase());
    }

    final displayNamesToRender = (widget.readOnly && _hideEmptyInViewMode)
        ? allDisplayNames.where((name) {
            final existingIdx = _arrestRecordsList.indexWhere(
              (it) =>
                  (it['arrested_person_name'] ??
                          it['person_name'] ??
                          it['name'] ??
                          '')
                      .toString()
                      .toLowerCase() ==
                  name.toLowerCase(),
            );
            if (existingIdx < 0) return false;
            return _recordHasArrestData(_arrestRecordsList[existingIdx]);
          }).toList()
        : allDisplayNames;

    return Container(
      margin: _responsiveCardMargin(context),
      decoration: _sectionCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          // Inside the tab panel the tab names the section: no header
          if (!_flatSectionCards)
            InkWell(
              onTap: () => _toggleSection('Arrest'),
              borderRadius: _responsiveHeaderBorderRadius(
                  context, _arrestSectionExpanded),
              child: Padding(
                padding: _responsiveHeaderPadding(context),
                child: Row(
                  children: [
                    _buildSectionIndexBadge(
                        sectionIndex, Icons.front_hand_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Arrest',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_arrestRecordsList.length} arrested',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navyMid,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // No collapse arrow in the step layout (sections stay open)
                    if (!_sectionsAlwaysOpen)
                      Tooltip(
                        message: _arrestSectionExpanded ? 'Collapse' : 'Expand',
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: AnimatedRotation(
                            turns: _arrestSectionExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOutCubic,
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.navyMid,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_flatSectionCards)
                  const Divider(height: 1, color: AppColors.lightBorder),
                Padding(
                  padding: _responsiveBodyPadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (allDisplayNames.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.lightBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  size: 20, color: AppColors.navyMid),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'No accused or suspected persons recorded yet. Please add accused persons in the Accused or Suspected Accused section above to record their arrest status.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    color: AppColors.lightSubText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        Text(
                          'SELECT ACCUSED TO RECORD ARREST STATUS',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...displayNamesToRender.map((name) {
                          final existingIdx = _arrestRecordsList.indexWhere(
                            (it) =>
                                (it['arrested_person_name'] ??
                                        it['person_name'] ??
                                        it['name'] ??
                                        '')
                                    .toString()
                                    .toLowerCase() ==
                                name.toLowerCase(),
                          );
                          final isArrested = existingIdx >= 0;
                          final record = isArrested
                              ? _arrestRecordsList[existingIdx]
                              : null;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: isArrested
                                    ? AppColors.navyMid
                                    : AppColors.lightBorder,
                                width: isArrested ? 1.5 : 1.0,
                              ),
                              boxShadow: isArrested
                                  ? [
                                      BoxShadow(
                                        color: AppColors.navyMid
                                            .withValues(alpha: 0.05),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header: Checkbox + Name + Status Tag
                                InkWell(
                                  onTap: widget.readOnly
                                      ? null
                                      : () {
                                          setState(() {
                                            if (isArrested) {
                                              _arrestRecordsList
                                                  .removeAt(existingIdx);
                                            } else {
                                              _arrestRecordsList.add({
                                                'arrested_person_name': name,
                                                'person_name': name,
                                                'name': name,
                                                'arrest_datetime': DateFormat(
                                                        'dd/MM/yyyy HH:mm')
                                                    .format(DateTime.now()),
                                                'sec_47_48_bnss': false,
                                                'relative_friend_name': '',
                                                'relative_friend_relation': '',
                                                'release_on_notice': false,
                                                'release_on_notice_datetime':
                                                    '',
                                                'anticipatory_bail': false,
                                                'anticipatory_bail_datetime':
                                                    '',
                                                'death_of_accused': false,
                                                'death_of_accused_datetime': '',
                                              });
                                            }
                                            _syncPrimaryArrestControllers();
                                          });
                                        },
                                  borderRadius: BorderRadius.vertical(
                                    top: const Radius.circular(AppRadius.md),
                                    bottom: Radius.circular(
                                        isArrested ? 0 : AppRadius.md),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: isArrested,
                                          activeColor: AppColors.navyMid,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          onChanged: widget.readOnly
                                              ? null
                                              : (val) {
                                                  setState(() {
                                                    if (val == true &&
                                                        !isArrested) {
                                                      _arrestRecordsList.add({
                                                        'arrested_person_name':
                                                            name,
                                                        'person_name': name,
                                                        'name': name,
                                                        'arrest_datetime':
                                                            DateFormat(
                                                                    'dd/MM/yyyy HH:mm')
                                                                .format(DateTime
                                                                    .now()),
                                                        'sec_47_48_bnss': false,
                                                        'relative_friend_name':
                                                            '',
                                                        'relative_friend_relation':
                                                            '',
                                                        'release_on_notice':
                                                            false,
                                                        'release_on_notice_datetime':
                                                            '',
                                                        'anticipatory_bail':
                                                            false,
                                                        'anticipatory_bail_datetime':
                                                            '',
                                                        'death_of_accused':
                                                            false,
                                                        'death_of_accused_datetime':
                                                            '',
                                                      });
                                                    } else if (val == false &&
                                                        isArrested) {
                                                      _arrestRecordsList
                                                          .removeAt(
                                                              existingIdx);
                                                    }
                                                    _syncPrimaryArrestControllers();
                                                  });
                                                },
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: (isArrested
                                                    ? AppColors.navyMid
                                                    : const Color(0xFF64748B))
                                                .withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.person_rounded,
                                            size: 16,
                                            color: isArrested
                                                ? AppColors.navyMid
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: GoogleFonts.poppins(
                                              fontSize: 13.5,
                                              fontWeight: isArrested
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: isArrested
                                                  ? AppColors.navyDark
                                                  : const Color(0xFF475569),
                                            ),
                                          ),
                                        ),
                                        if (isArrested)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Arrested',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF15803D),
                                              ),
                                            ),
                                          )
                                        else
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Not Arrested',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: const Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Inline Arrest Details Form (visible when arrested)
                                if (isArrested && record != null) ...[
                                  const Divider(
                                      height: 1, color: AppColors.lightBorder),
                                  Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // 1. Arrest Date & Time
                                        Text(
                                          'Arrest Date & Time',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.navyDark,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        InkWell(
                                          onTap: widget.readOnly
                                              ? null
                                              : () => _pickDateTimeForRecord(
                                                  context,
                                                  record,
                                                  'arrest_datetime'),
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.md),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 11),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAFC),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppRadius.md),
                                              border: Border.all(
                                                  color: AppColors.lightBorder),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                    Icons.access_time_rounded,
                                                    size: 18,
                                                    color: AppColors.navyMid),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    (record['arrest_datetime']
                                                                ?.toString()
                                                                .isNotEmpty ==
                                                            true)
                                                        ? record[
                                                                'arrest_datetime']
                                                            .toString()
                                                        : 'Select arrest date & time...',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 13,
                                                      color: (record['arrest_datetime']
                                                                  ?.toString()
                                                                  .isNotEmpty ==
                                                              true)
                                                          ? AppColors.navyDark
                                                          : const Color(
                                                              0xFF94A3B8),
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                const Icon(
                                                    Icons
                                                        .calendar_month_rounded,
                                                    size: 18,
                                                    color: AppColors.navyMid),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 14),

                                        // 2. Section 47/48 BNSS Intimation
                                        Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.md),
                                            border: Border.all(
                                                color: AppColors.lightBorder),
                                          ),
                                          child: Column(
                                            children: [
                                              CheckboxListTile(
                                                value:
                                                    record['sec_47_48_bnss'] ==
                                                        true,
                                                activeColor: AppColors.navyMid,
                                                title: Text(
                                                  'Intimation under Sec 47/48 BNSS',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.navyDark,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  'Information given to relative / friend',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    color:
                                                        AppColors.lightSubText,
                                                  ),
                                                ),
                                                controlAffinity:
                                                    ListTileControlAffinity
                                                        .leading,
                                                onChanged: widget.readOnly
                                                    ? null
                                                    : (val) {
                                                        setState(() {
                                                          record['sec_47_48_bnss'] =
                                                              val ?? false;
                                                          _syncPrimaryArrestControllers();
                                                        });
                                                      },
                                              ),
                                              if (record['sec_47_48_bnss'] ==
                                                  true) ...[
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          14, 0, 14, 14),
                                                  child: LayoutBuilder(
                                                    builder:
                                                        (context, constraints) {
                                                      final isWide =
                                                          constraints.maxWidth >
                                                              500;
                                                      final relNameField =
                                                          TextFormField(
                                                        key: ValueKey(
                                                            'rel_name_$name'),
                                                        initialValue: record[
                                                                    'relative_friend_name']
                                                                ?.toString() ??
                                                            '',
                                                        enabled:
                                                            !widget.readOnly,
                                                        style:
                                                            GoogleFonts.poppins(
                                                                fontSize: 13,
                                                                color: AppColors
                                                                    .navyDark),
                                                        decoration:
                                                            InputDecoration(
                                                          labelText:
                                                              'Relative / Friend Name',
                                                          hintText:
                                                              'e.g. Ramesh',
                                                          prefixIcon: const Icon(
                                                              Icons
                                                                  .person_outline_rounded,
                                                              size: 16,
                                                              color: AppColors
                                                                  .navyMid),
                                                          border: OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          AppRadius
                                                                              .md)),
                                                          filled: true,
                                                          fillColor:
                                                              Colors.white,
                                                          contentPadding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 10),
                                                        ),
                                                        onChanged: (val) {
                                                          record['relative_friend_name'] =
                                                              val.trim();
                                                          _syncPrimaryArrestControllers();
                                                        },
                                                      );
                                                      return _intimationFieldsLayout(
                                                          [
                                                            relNameField,
                                                            ..._relationWithAccusedFields(
                                                                record,
                                                                'relative_friend_relation',
                                                                name),
                                                          ],
                                                          isWide);
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 14),

                                        // 3. Release & Legal Status Options
                                        Text(
                                          'Release & Legal Status (Optional)',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.navyDark,
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // Release on Notice
                                        Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.md),
                                            border: Border.all(
                                              color: AppColors.lightBorder,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              CheckboxListTile(
                                                value: record[
                                                        'release_on_notice'] ==
                                                    true,
                                                activeColor: AppColors.navyMid,
                                                title: Text(
                                                  'Release on Notice',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.navyDark,
                                                  ),
                                                ),
                                                controlAffinity:
                                                    ListTileControlAffinity
                                                        .leading,
                                                onChanged: widget.readOnly
                                                    ? null
                                                    : (val) {
                                                        setState(() {
                                                          final active =
                                                              val ?? false;
                                                          record['release_on_notice'] =
                                                              active;
                                                          if (active &&
                                                              (record['release_on_notice_datetime']
                                                                      ?.toString()
                                                                      .isEmpty ??
                                                                  true)) {
                                                            record['release_on_notice_datetime'] =
                                                                DateFormat(
                                                                        'dd/MM/yyyy HH:mm')
                                                                    .format(DateTime
                                                                        .now());
                                                          }
                                                          _syncPrimaryArrestControllers();
                                                        });
                                                      },
                                              ),
                                              if (record['release_on_notice'] ==
                                                  true)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          14, 0, 14, 12),
                                                  child: InkWell(
                                                    onTap: widget.readOnly
                                                        ? null
                                                        : () => _pickDateTimeForRecord(
                                                            context,
                                                            record,
                                                            'release_on_notice_datetime'),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            AppRadius.md),
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12,
                                                          vertical: 10),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    AppRadius
                                                                        .md),
                                                        border: Border.all(
                                                            color: AppColors
                                                                .lightBorder),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                              Icons
                                                                  .access_time_rounded,
                                                              size: 16,
                                                              color: AppColors
                                                                  .navyMid),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                            child: Text(
                                                              (record['release_on_notice_datetime']
                                                                          ?.toString()
                                                                          .isNotEmpty ==
                                                                      true)
                                                                  ? 'Notice Release: ${record['release_on_notice_datetime']}'
                                                                  : 'Select notice release date & time...',
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: AppColors
                                                                    .navyDark,
                                                              ),
                                                            ),
                                                          ),
                                                          const Icon(
                                                              Icons
                                                                  .calendar_month_rounded,
                                                              size: 16,
                                                              color: AppColors
                                                                  .navyMid),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),

                                        // Anticipatory Bail
                                        Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.md),
                                            border: Border.all(
                                              color: AppColors.lightBorder,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              CheckboxListTile(
                                                value: record[
                                                        'anticipatory_bail'] ==
                                                    true,
                                                activeColor: AppColors.navyMid,
                                                title: Text(
                                                  'Anticipatory Bail',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.navyDark,
                                                  ),
                                                ),
                                                controlAffinity:
                                                    ListTileControlAffinity
                                                        .leading,
                                                onChanged: widget.readOnly
                                                    ? null
                                                    : (val) {
                                                        setState(() {
                                                          final active =
                                                              val ?? false;
                                                          record['anticipatory_bail'] =
                                                              active;
                                                          if (active &&
                                                              (record['anticipatory_bail_datetime']
                                                                      ?.toString()
                                                                      .isEmpty ??
                                                                  true)) {
                                                            record['anticipatory_bail_datetime'] =
                                                                DateFormat(
                                                                        'dd/MM/yyyy HH:mm')
                                                                    .format(DateTime
                                                                        .now());
                                                          }
                                                          _syncPrimaryArrestControllers();
                                                        });
                                                      },
                                              ),
                                              if (record['anticipatory_bail'] ==
                                                  true)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          14, 0, 14, 12),
                                                  child: InkWell(
                                                    onTap: widget.readOnly
                                                        ? null
                                                        : () => _pickDateTimeForRecord(
                                                            context,
                                                            record,
                                                            'anticipatory_bail_datetime'),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            AppRadius.md),
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12,
                                                          vertical: 10),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    AppRadius
                                                                        .md),
                                                        border: Border.all(
                                                            color: AppColors
                                                                .lightBorder),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                              Icons
                                                                  .access_time_rounded,
                                                              size: 16,
                                                              color: AppColors
                                                                  .navyMid),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                            child: Text(
                                                              (record['anticipatory_bail_datetime']
                                                                          ?.toString()
                                                                          .isNotEmpty ==
                                                                      true)
                                                                  ? 'Anticipatory Bail: ${record['anticipatory_bail_datetime']}'
                                                                  : 'Select anticipatory bail date & time...',
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: AppColors
                                                                    .navyDark,
                                                              ),
                                                            ),
                                                          ),
                                                          const Icon(
                                                              Icons
                                                                  .calendar_month_rounded,
                                                              size: 16,
                                                              color: AppColors
                                                                  .navyMid),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),

                                        // Death of Accused
                                        Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.md),
                                            border: Border.all(
                                              color: AppColors.lightBorder,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              CheckboxListTile(
                                                value: record[
                                                        'death_of_accused'] ==
                                                    true,
                                                activeColor: AppColors.navyMid,
                                                title: Text(
                                                  'Death of Accused',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.navyDark,
                                                  ),
                                                ),
                                                controlAffinity:
                                                    ListTileControlAffinity
                                                        .leading,
                                                onChanged: widget.readOnly
                                                    ? null
                                                    : (val) {
                                                        setState(() {
                                                          final active =
                                                              val ?? false;
                                                          record['death_of_accused'] =
                                                              active;
                                                          if (active &&
                                                              (record['death_of_accused_datetime']
                                                                      ?.toString()
                                                                      .isEmpty ??
                                                                  true)) {
                                                            record['death_of_accused_datetime'] =
                                                                DateFormat(
                                                                        'dd/MM/yyyy HH:mm')
                                                                    .format(DateTime
                                                                        .now());
                                                          }
                                                          _syncPrimaryArrestControllers();
                                                        });
                                                      },
                                              ),
                                              if (record['death_of_accused'] ==
                                                  true)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          14, 0, 14, 12),
                                                  child: InkWell(
                                                    onTap: widget.readOnly
                                                        ? null
                                                        : () => _pickDateTimeForRecord(
                                                            context,
                                                            record,
                                                            'death_of_accused_datetime'),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            AppRadius.md),
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12,
                                                          vertical: 10),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    AppRadius
                                                                        .md),
                                                        border: Border.all(
                                                            color: AppColors
                                                                .lightBorder),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                              Icons
                                                                  .access_time_rounded,
                                                              size: 16,
                                                              color: AppColors
                                                                  .navyMid),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                            child: Text(
                                                              (record['death_of_accused_datetime']
                                                                          ?.toString()
                                                                          .isNotEmpty ==
                                                                      true)
                                                                  ? 'Death: ${record['death_of_accused_datetime']}'
                                                                  : 'Select death date & time...',
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: AppColors
                                                                    .navyDark,
                                                              ),
                                                            ),
                                                          ),
                                                          const Icon(
                                                              Icons
                                                                  .calendar_month_rounded,
                                                              size: 16,
                                                              color: AppColors
                                                                  .navyMid),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: _arrestSectionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOutCubic,
          ),
        ],
      ),
    );
  }

  // ── Unknown Accused Repeating List Section ──────────────────────────────
  // ── Preventive Action for Multiple Accused Section ────────────────────────
  Widget _buildPreventiveActionSection({Object? sectionIndex}) {
    if (widget.readOnly && _hideEmptyInViewMode && !_hasAnyPreventiveData) {
      return const SizedBox.shrink();
    }
    final availableAccused = _getAvailableAccusedNames();
    final rawPeople = <String>{
      ...availableAccused,
      ..._customPreventivePersons,
      for (final it in _preventiveActionsList)
        if ((it['name'] ?? it['person_name'])?.toString().trim().isNotEmpty ==
            true)
          (it['name'] ?? it['person_name']).toString().trim(),
    }.toList();

    final allPeople = (widget.readOnly && _hideEmptyInViewMode)
        ? rawPeople.where((name) {
            final existingIdx = _preventiveActionsList.indexWhere(
              (it) =>
                  (it['name'] ?? it['person_name'] ?? '')
                      .toString()
                      .toLowerCase() ==
                  name.toLowerCase(),
            );
            if (existingIdx < 0) return false;
            final it = _preventiveActionsList[existingIdx];
            final aType =
                (it['action_type'] ?? it['action'] ?? '').toString().trim();
            final aDate =
                (it['action_date'] ?? it['date'] ?? '').toString().trim();
            final aNum = (it['preventive_number'] ?? it['outward_number'] ?? '')
                .toString()
                .trim();
            return aType.isNotEmpty || aDate.isNotEmpty || aNum.isNotEmpty;
          }).toList()
        : rawPeople;

    final choices = _formDef?.preventiveItems ?? const <String>[];

    return Container(
      key: const ValueKey('sec_Preventive Action'),
      margin: _responsiveCardMargin(context),
      decoration: _sectionCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with Toggle
          // Inside the tab panel the tab names the section: no header
          if (!_flatSectionCards)
            InkWell(
              onTap: () => _toggleSection('Preventive Action'),
              borderRadius: _responsiveHeaderBorderRadius(
                  context, _preventiveSectionExpanded),
              child: Padding(
                padding: _responsiveHeaderPadding(context),
                child: Row(
                  children: [
                    _buildSectionIndexBadge(sectionIndex, Icons.shield_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _formDef?.sectionTitles['preventive_action'] ??
                            _formDef?.preventiveConfig?['section_title'] ??
                            'Preventive Action',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _preventiveActionsList.isNotEmpty
                            ? AppColors.navyMid.withValues(alpha: 0.12)
                            : AppColors.navyMid.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _preventiveActionsList.isNotEmpty
                            ? '${_preventiveActionsList.length} action${_preventiveActionsList.length > 1 ? 's' : ''}'
                            : '${allPeople.length} accused',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navyMid,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // No collapse arrow in the step layout (sections stay open)
                    if (!_sectionsAlwaysOpen)
                      Tooltip(
                        message:
                            _preventiveSectionExpanded ? 'Collapse' : 'Expand',
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: AnimatedRotation(
                            turns: _preventiveSectionExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOutCubic,
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.navyMid,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_flatSectionCards)
                  const Divider(height: 1, color: AppColors.lightBorder),
                Padding(
                  padding: _responsiveBodyPadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (allPeople.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.lightBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  size: 20, color: AppColors.navyMid),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'No accused persons recorded in the form yet. Click below to add a person for preventive action.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    color: AppColors.lightSubText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        ...allPeople.map((name) {
                          final existingIdx = _preventiveActionsList.indexWhere(
                            (it) =>
                                (it['name'] ?? it['person_name'])
                                    ?.toString()
                                    .toLowerCase() ==
                                name.toLowerCase(),
                          );
                          final existingAction = existingIdx >= 0
                              ? _preventiveActionsList[existingIdx]
                              : null;
                          final isCustom =
                              _customPreventivePersons.contains(name);

                          return _PreventivePersonCard(
                            key: ValueKey('prev_person_$name'),
                            personName: name,
                            isCustom: isCustom,
                            readOnly: widget.readOnly,
                            initialAction: existingAction,
                            choices: choices,
                            onSaveAction: _savePreventiveActionForPerson,
                            onRemoveAction: () =>
                                _removePreventiveActionForPerson(name),
                            onRemovePerson: () {
                              setState(() {
                                _customPreventivePersons.remove(name);
                                _removePreventiveActionForPerson(name);
                              });
                            },
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: _preventiveSectionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOutCubic,
          ),
        ],
      ),
    );
  }

  void _savePreventiveActionForPerson(Map<String, dynamic> actionData) {
    setState(() {
      final pName = actionData['name']?.toString() ?? '';
      final idx = _preventiveActionsList.indexWhere(
        (it) =>
            (it['name'] ?? it['person_name'])?.toString().toLowerCase() ==
            pName.toLowerCase(),
      );
      if (idx >= 0) {
        _preventiveActionsList[idx] = actionData;
      } else {
        _preventiveActionsList.add(actionData);
      }
      _syncPreventiveControllers();
    });
  }

  void _removePreventiveActionForPerson(String personName) {
    setState(() {
      _preventiveActionsList.removeWhere(
        (it) =>
            (it['name'] ?? it['person_name'])?.toString().toLowerCase() ==
            personName.toLowerCase(),
      );
      _syncPreventiveControllers();
    });
  }

  void _syncPreventiveControllers() {
    if (_preventiveActionsList.isNotEmpty) {
      final first = _preventiveActionsList.first;
      _controllers
          .putIfAbsent('preventive_action_type', () => TextEditingController())
          .text = first['action_type'] ?? '';
      _values['preventive_action_type'] = first['action_type'];
      _controllers
          .putIfAbsent('preventive_action_date', () => TextEditingController())
          .text = first['action_date'] ?? '';
      _values['preventive_action_date'] = first['action_date'];
      _controllers
          .putIfAbsent('preventive_outward_no', () => TextEditingController())
          .text = first['outward_number'] ?? '';
      _values['preventive_outward_no'] = first['outward_number'];
    } else {
      _controllers['preventive_action_type']?.clear();
      _values.remove('preventive_action_type');
      _controllers['preventive_action_date']?.clear();
      _values.remove('preventive_action_date');
      _controllers['preventive_outward_no']?.clear();
      _values.remove('preventive_outward_no');
    }
  }

  /// dd/MM/yyyy -> date, or null.
  static DateTime? _parseDmy(String? text) {
    final parts = (text ?? '').trim().split('/');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    return DateTime(y, m, d);
  }

  Future<void> _pickDateForController(
      BuildContext context, TextEditingController ctrl,
      {DateTime? firstDate}) async {
    DateTime initial = DateTime.now();
    final cur = ctrl.text.trim();
    if (cur.isNotEmpty) {
      final parts = cur.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]) ?? initial.day;
        final m = int.tryParse(parts[1]) ?? initial.month;
        final y = int.tryParse(parts[2]) ?? initial.year;
        initial = DateTime(y, m, d);
      }
    }
    final first = firstDate ?? DateTime(1900);
    if (initial.isBefore(first)) initial = first;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      ctrl.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  // ── Remand & Custody for Multiple Accused Section ──────────────────────────
  Widget _buildRemandCustodySection({Object? sectionIndex, String? onlyFor}) {
    if (widget.readOnly && _hideEmptyInViewMode && !_hasAnyCustodyData) {
      return const SizedBox.shrink();
    }
    final availableAccused = _getAvailableAccusedNames();
    final allPeople = <String>{...availableAccused, ..._customCustodyPersons};
    for (final it in _custodyRecordsList) {
      final n = (it['name'] ?? it['person_name'] ?? '').toString().trim();
      if (n.isNotEmpty) allPeople.add(n);
    }
    final allPeopleList = allPeople.where((name) {
      if (onlyFor != null && name.toLowerCase() != onlyFor.toLowerCase()) {
        return false;
      }
      if (widget.readOnly && _hideEmptyInViewMode) {
        final existingIdx = _custodyRecordsList.indexWhere(
          (it) =>
              (it['name'] ?? it['person_name'] ?? '')
                  .toString()
                  .toLowerCase() ==
              name.toLowerCase(),
        );
        if (existingIdx < 0) return false;
        return _recordHasCustodyData(_custodyRecordsList[existingIdx]);
      }
      return true;
    }).toList();

    return Container(
      margin: _responsiveCardMargin(context),
      decoration: _sectionCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with Toggle
          // Inside the tab panel the tab names the section: no header
          if (!_flatSectionCards)
            InkWell(
              onTap: () => _toggleSection('Remand & Custody'),
              borderRadius: _responsiveHeaderBorderRadius(
                  context, _custodySectionExpanded),
              child: Padding(
                padding: _responsiveHeaderPadding(context),
                child: Row(
                  children: [
                    _buildSectionIndexBadge(
                        sectionIndex, Icons.lock_clock_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Custody & Remand',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _custodyRecordsList.isNotEmpty
                            ? AppColors.navyMid.withValues(alpha: 0.12)
                            : AppColors.navyMid.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _custodyRecordsList.isNotEmpty
                            ? '${_custodyRecordsList.length} recorded'
                            : '${allPeopleList.length} accused',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navyMid,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // No collapse arrow in the step layout (sections stay open)
                    if (!_sectionsAlwaysOpen)
                      Tooltip(
                        message:
                            _custodySectionExpanded ? 'Collapse' : 'Expand',
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: AnimatedRotation(
                            turns: _custodySectionExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOutCubic,
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.navyMid,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_flatSectionCards)
                  const Divider(height: 1, color: AppColors.lightBorder),
                Padding(
                  padding: _responsiveBodyPadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (allPeopleList.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.lightBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  size: 20, color: AppColors.navyMid),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Add accused above to set PCR / MCR custody details.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    color: AppColors.lightSubText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        ...allPeopleList.map((name) {
                          final existingIdx = _custodyRecordsList.indexWhere(
                            (it) =>
                                (it['name'] ?? it['person_name'] ?? '')
                                    .toString()
                                    .toLowerCase() ==
                                name.toLowerCase(),
                          );
                          final existingRecord = existingIdx >= 0
                              ? _custodyRecordsList[existingIdx]
                              : null;
                          final isCustom = _customCustodyPersons.contains(name);
                          final isExpanded = onlyFor != null ||
                              _expandedCustodyAccused == name;

                          return _CustodyAccusedCard(
                            key: ValueKey('custody_accused_$name'),
                            personName: name,
                            isCustom: isCustom,
                            readOnly: widget.readOnly,
                            initialData: existingRecord,
                            genderOptions: _genderOptions,
                            relationChoices: _suretyRelationChoices,
                            isExpanded: isExpanded,
                            onToggleExpand: () {
                              setState(() {
                                _expandedCustodyAccused =
                                    isExpanded ? null : name;
                              });
                            },
                            onChanged: (updated) =>
                                _onCustodyRecordChanged(name, updated),
                            onRemovePerson: isCustom
                                ? () => _removeCustodyPerson(name)
                                : null,
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: _custodySectionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOutCubic,
          ),
        ],
      ),
    );
  }

  void _onCustodyRecordChanged(String personName, Map<String, dynamic> record) {
    setState(() {
      final idx = _custodyRecordsList.indexWhere(
        (it) =>
            (it['name'] ?? it['person_name'] ?? '').toString().toLowerCase() ==
            personName.toLowerCase(),
      );
      if (idx >= 0) {
        _custodyRecordsList[idx] = record;
      } else {
        _custodyRecordsList.add(record);
      }
      _syncPrimaryCustodyControllers();
    });
  }

  void _removeCustodyPerson(String personName) {
    setState(() {
      _customCustodyPersons.remove(personName);
      _custodyRecordsList.removeWhere(
        (it) =>
            (it['name'] ?? it['person_name'] ?? '').toString().toLowerCase() ==
            personName.toLowerCase(),
      );
      if (_expandedCustodyAccused == personName) {
        _expandedCustodyAccused = null;
      }
      _syncPrimaryCustodyControllers();
    });
  }

  void _syncPrimaryCustodyControllers() {
    if (_custodyRecordsList.isNotEmpty) {
      final first = _custodyRecordsList.first;
      _controllers['pcr_days']?.text = first['pcr_days']?.toString() ?? '';
      _values['pcr_days'] = first['pcr_days'];
      _values['mcr'] = first['mcr'];
      _values['pr_bond'] = first['pr_bond'];
      _controllers['pr_bond_date']?.text =
          first['pr_bond_date']?.toString() ?? '';
      _values['pr_bond_date'] = first['pr_bond_date'];
      _values['bail'] = first['bail'];
      _controllers['surety_name']?.text =
          first['surety_name']?.toString() ?? '';
      _values['surety_name'] = first['surety_name'];
      _values['jail'] = first['jail'];
      _controllers['jail_date']?.text = first['jail_date']?.toString() ?? '';
      _values['jail_date'] = first['jail_date'];
    }
  }

  String _getScrutinyVal(String key) {
    final ctrl = _controllers[key];
    if (ctrl != null && ctrl.text.trim().isNotEmpty) {
      return ctrl.text.trim();
    }
    return _values[key]?.toString().trim() ?? '';
  }

  Widget _buildScrutinySection({Object? sectionIndex}) {
    if (widget.readOnly && _hideEmptyInViewMode && !_hasAnyScrutinyData) {
      return const SizedBox.shrink();
    }
    final sdpoSend = _getScrutinyVal('sdpo_acp_send_date');
    final sdpoGrant = _getScrutinyVal('sdpo_acp_grant_date');
    final dcpSend = _getScrutinyVal('addl_sp_dcp_send_date');
    final dcpGrant = _getScrutinyVal('addl_sp_dcp_grant_date');
    final cpSend = _getScrutinyVal('addl_cp_send_date');
    final cpGrant = _getScrutinyVal('addl_cp_grant_date');
    final appSend = _getScrutinyVal('app_send_date');
    final appGrant = _getScrutinyVal('app_grant_date');

    // Step 1: Always editable unless readOnly
    final step1HasDate = sdpoSend.isNotEmpty || sdpoGrant.isNotEmpty;

    // Step 2: Enabled only if Step 1 has a date entered; if Step 1 is cleared, Step 2 is re-disabled
    final step2Enabled = step1HasDate;
    final step2HasDate =
        step2Enabled && (dcpSend.isNotEmpty || dcpGrant.isNotEmpty);

    // Step 3: Enabled only if Step 2 has a date entered
    final step3Enabled = step2HasDate;
    final step3HasDate =
        step3Enabled && (cpSend.isNotEmpty || cpGrant.isNotEmpty);

    // Step 4: Enabled only if Step 3 has a date entered
    final step4Enabled = step3HasDate;
    final step4HasDate =
        step4Enabled && (appSend.isNotEmpty || appGrant.isNotEmpty);

    int activeCount = 0;
    if (step1HasDate) activeCount++;
    if (step2HasDate) activeCount++;
    if (step3HasDate) activeCount++;
    if (step4HasDate) activeCount++;

    return Container(
      key: const ValueKey('sec_Scrutiny'),
      margin: _responsiveCardMargin(context),
      decoration: _sectionCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          // Inside the tab panel the tab names the section: no header
          if (!_flatSectionCards)
            InkWell(
              onTap: () => _toggleSection('Scrutiny'),
              borderRadius: _responsiveHeaderBorderRadius(
                  context, _scrutinySectionExpanded),
              child: Padding(
                padding: _responsiveHeaderPadding(context),
                child: Row(
                  children: [
                    _buildSectionIndexBadge(
                        sectionIndex, Icons.rule_folder_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Scrutiny',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDark,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: activeCount > 0
                            ? AppColors.navyMid.withValues(alpha: 0.12)
                            : AppColors.navyMid.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        activeCount == 4
                            ? 'Completed (4/4)'
                            : '$activeCount of 4 Recorded',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navyMid,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // No collapse arrow in the step layout (sections stay open)
                    if (!_sectionsAlwaysOpen)
                      Tooltip(
                        message:
                            _scrutinySectionExpanded ? 'Collapse' : 'Expand',
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: AnimatedRotation(
                            turns: _scrutinySectionExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOutCubic,
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.navyMid,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Body Animated CrossFade
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_flatSectionCards)
                  const Divider(height: 1, color: AppColors.lightBorder),
                Padding(
                  padding: _responsiveBodyPadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stepper: Step 1
                      _buildScrutinyStepCard(
                        stepNumber: 1,
                        title: 'SDPO / ACP Approval',
                        subtitle: 'Sub-Divisional Police Officer / ACP',
                        isEnabled: !widget.readOnly,
                        hasDate: step1HasDate,
                        sendKey: 'sdpo_acp_send_date',
                        grantKey: 'sdpo_acp_grant_date',
                      ),

                      // Stepper: Step 2
                      _buildScrutinyStepCard(
                        stepNumber: 2,
                        title: 'Addl. SP / DCP Approval',
                        subtitle:
                            'Additional SP / Deputy Commissioner of Police',
                        isEnabled: step2Enabled && !widget.readOnly,
                        hasDate: step2HasDate,
                        sendKey: 'addl_sp_dcp_send_date',
                        grantKey: 'addl_sp_dcp_grant_date',
                      ),

                      // Stepper: Step 3
                      _buildScrutinyStepCard(
                        stepNumber: 3,
                        title: 'Addl. CP Approval',
                        subtitle: 'Additional Commissioner of Police',
                        isEnabled: step3Enabled && !widget.readOnly,
                        hasDate: step3HasDate,
                        sendKey: 'addl_cp_send_date',
                        grantKey: 'addl_cp_grant_date',
                      ),

                      // Stepper: Step 4
                      _buildScrutinyStepCard(
                        stepNumber: 4,
                        title: 'APP Scrutiny',
                        subtitle: 'Assistant Public Prosecutor Legal Review',
                        isEnabled: step4Enabled && !widget.readOnly,
                        hasDate: step4HasDate,
                        sendKey: 'app_send_date',
                        grantKey: 'app_grant_date',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: _scrutinySectionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildScrutinyStepCard({
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required bool hasDate,
    required String sendKey,
    required String grantKey,
    bool isLast = false,
  }) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    const muted = Color(0xFF94A3B8);

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isEnabled ? AppColors.navyDark : muted,
          ),
        ),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 10.5,
            color: isEnabled ? AppColors.lightSubText : muted,
          ),
        ),
      ],
    );

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: !isEnabled
            ? const Color(0xFFE2E8F0)
            : (hasDate
                ? const Color(0xFFE0F2FE)
                : AppColors.navyMid.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            !isEnabled
                ? Icons.lock_outline_rounded
                : (hasDate
                    ? Icons.check_circle_outline_rounded
                    : Icons.edit_calendar_rounded),
            size: 12,
            color: !isEnabled ? const Color(0xFF64748B) : AppColors.navyMid,
          ),
          const SizedBox(width: 3),
          Text(
            !isEnabled ? 'Locked' : (hasDate ? 'Recorded' : 'Active'),
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: !isEnabled ? const Color(0xFF64748B) : AppColors.navyMid,
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Step indicator badge & line
            SizedBox(
              width: 26,
              child: Column(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: hasDate
                          ? AppColors.navyMid
                          : (isEnabled
                              ? AppColors.navyMid.withValues(alpha: 0.1)
                              : const Color(0xFFE2E8F0)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isEnabled
                            ? AppColors.navyMid
                            : const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: hasDate
                          ? const Icon(Icons.check_rounded,
                              size: 15, color: Colors.white)
                          : Text(
                              '$stepNumber',
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isEnabled
                                    ? AppColors.navyMid
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isEnabled
                            ? AppColors.navyMid.withValues(alpha: 0.3)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Step Content Card: one line on PC (title | Send date |
            // Grant date | status); stacked on a phone
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 12, vertical: isCompact ? 8 : 6),
                decoration: BoxDecoration(
                  color: isEnabled ? Colors.white : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isEnabled
                        ? (hasDate
                            ? AppColors.navyMid.withValues(alpha: 0.35)
                            : AppColors.lightBorder)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: isCompact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: titleBlock),
                              badge,
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildScrutinyDateField(
                            label: 'Send Date',
                            fieldKey: sendKey,
                            enabled: isEnabled,
                          ),
                          const SizedBox(height: 6),
                          _buildScrutinyDateField(
                            label: 'Grant Date',
                            fieldKey: grantKey,
                            enabled: isEnabled,
                            afterKey: sendKey,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(flex: 5, child: titleBlock),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 4,
                            child: _buildScrutinyDateField(
                              label: 'Send date',
                              fieldKey: sendKey,
                              enabled: isEnabled,
                              inline: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: _buildScrutinyDateField(
                              label: 'Grant date',
                              fieldKey: grantKey,
                              enabled: isEnabled,
                              inline: true,
                              afterKey: sendKey,
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(width: 82, child: Center(child: badge)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Clears a Grant date that is no longer after its step's Send date
  /// (e.g. the Send date was moved later).
  void _dropGrantsNotAfterSend() {
    for (final e in _scrutinyGrantSendKeys.entries) {
      final grant = _parseDmy(_controllers[e.key]?.text);
      final send = _parseDmy(_controllers[e.value]?.text);
      if (grant != null && send != null && !grant.isAfter(send)) {
        _controllers[e.key]?.clear();
        _values[e.key] = '';
      }
    }
  }

  /// Grant date key -> its Send date key, filled as the steps are drawn.
  final Map<String, String> _scrutinyGrantSendKeys = {};

  /// [afterKey]: the Send date of the same step. A Grant date can only be
  /// picked once that is set, and only for a day after it.
  Widget _buildScrutinyDateField({
    required String label,
    required String fieldKey,
    required bool enabled,
    bool inline = false,
    String? afterKey,
  }) {
    final ctrl = _controllers.putIfAbsent(fieldKey, () {
      final v = _values[fieldKey]?.toString() ?? '';
      return TextEditingController(text: v);
    });
    final val = ctrl.text.trim();
    if (afterKey != null) _scrutinyGrantSendKeys[fieldKey] = afterKey;
    final afterDate = afterKey == null
        ? null
        : _parseDmy(
            _controllers[afterKey]?.text ?? _values[afterKey]?.toString());
    // Grant date waits for its Send date (a saved one stays shown)
    final waiting =
        enabled && afterKey != null && afterDate == null && val.isEmpty;
    if (waiting) enabled = false;
    // Inline (one-line card): no label above; the box reads "Send date"
    // until a date is picked, then "Send date: 23/11/2026"
    final shown = waiting
        ? 'Add send date first'
        : inline
            ? (val.isNotEmpty ? '$label: $val' : (enabled ? label : 'Locked'))
            : (val.isNotEmpty ? val : (enabled ? 'Select Date' : 'Locked'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!inline)
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: enabled ? AppColors.navyDark : const Color(0xFF94A3B8),
            ),
          ),
        if (!inline) const SizedBox(height: 3),
        InkWell(
          onTap: (enabled && !widget.readOnly)
              ? () async {
                  await _pickDateForController(context, ctrl,
                      firstDate: afterDate?.add(const Duration(days: 1)));
                  _values[fieldKey] = ctrl.text.trim();
                  _dropGrantsNotAfterSend();
                  setState(() {});
                }
              : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color:
                  enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color:
                    enabled ? AppColors.lightBorder : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: enabled ? AppColors.navyMid : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    shown,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight:
                          val.isNotEmpty ? FontWeight.w600 : FontWeight.w400,
                      color: enabled
                          ? (val.isNotEmpty
                              ? AppColors.navyDark
                              : AppColors.lightSubText)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                if (enabled && val.isNotEmpty && !widget.readOnly)
                  Tooltip(
                    message: 'Clear date',
                    child: InkWell(
                      onTap: () {
                        ctrl.clear();
                        _values[fieldKey] = '';
                        setState(() {});
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(2.0),
                        child: Icon(
                          Icons.clear_rounded,
                          size: 16,
                          color: AppColors.dangerRed,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _iconForSection(String section) {
    final s = section.toLowerCase();
    if (s.contains('application') || s.contains('applicant')) {
      return Icons.assignment_ind_rounded;
    }
    if (s.contains('registration')) return Icons.assignment_rounded;
    if (s.contains('acts') || s.contains('charges')) return Icons.gavel_rounded;
    if (s.contains('spot')) return Icons.location_on_rounded;
    if (s.contains('complainant')) return Icons.person_rounded;
    if (s.contains('suspected')) return Icons.person_search_rounded;
    if (s.contains('unidentified')) return Icons.help_outline_rounded;
    if (s.contains('unknown')) return Icons.question_mark_rounded;
    if (s.contains('accused')) return Icons.person_pin_rounded;
    if (s.contains('officer') || s.contains('responsibility')) {
      return Icons.badge_rounded;
    }
    if (s.contains('arrest')) return Icons.front_hand_rounded;
    if (s.contains('remand') || s.contains('custody')) {
      return Icons.lock_clock_rounded;
    }
    if (s.contains('cctv') || s.contains('cdr')) return Icons.videocam_rounded;
    if (s.contains('log book')) return Icons.menu_book_rounded;
    if (s.contains('absconding')) return Icons.person_off_rounded;
    if (s.contains('panchnama') || s.contains('checklist')) {
      return Icons.checklist_rounded;
    }
    if (s.contains('evidence') || s.contains('forensic')) {
      return Icons.biotech_rounded;
    }
    if (s.contains('seizure')) return Icons.inventory_2_rounded;
    if (s.contains('preventive action')) return Icons.shield_rounded;
    if (s.contains('bond')) return Icons.description_rounded;
    if (s.contains('discharge')) return Icons.person_remove_rounded;
    if (s.contains('scrutiny')) return Icons.rule_folder_rounded;
    if (s.contains('court') ||
        s.contains('summary') ||
        s.contains('verdict') ||
        s.contains('filing')) {
      return Icons.task_alt_rounded;
    }
    if (s.contains('special') || s.contains('template')) {
      return Icons.featured_play_list_rounded;
    }
    return Icons.folder_open_rounded;
  }
}

// ── Inline Person Card for Accused / Suspected Accused (No Popup Dialogs) ───
class _InlinePersonCard extends StatefulWidget {
  final int index;
  final String roleTitle;
  final Map<String, dynamic> data;
  final VoidCallback? onRemove;
  final VoidCallback? onChanged;
  final bool readOnly;
  final bool canRemove;

  /// When set, the parent decides whether the card is collapsed and
  /// [onToggle] is called on a header tap instead of toggling locally.
  final bool? collapsed;
  final VoidCallback? onToggle;

  /// Gender choices from the database (/api/options/gender/); empty uses the
  /// card's own list
  final List<String> genderOptions;

  /// Show Medical (an option of /api/options/yes_no/) and, when it is the
  /// group's first option (Yes), Medical Date
  final bool showMedical;
  final List<String> yesNoOptions;

  const _InlinePersonCard({
    super.key,
    required this.index,
    required this.roleTitle,
    required this.data,
    this.onRemove,
    this.onChanged,
    this.readOnly = false,
    this.canRemove = false,
    this.collapsed,
    this.onToggle,
    this.genderOptions = const [],
    this.showMedical = false,
    this.yesNoOptions = const [],
  });

  @override
  State<_InlinePersonCard> createState() => _InlinePersonCardState();
}

class _InlinePersonCardState extends State<_InlinePersonCard> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _occCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _aadhaarCtrl;
  late final TextEditingController _panCtrl;
  late final TextEditingController _religionCtrl;
  late final TextEditingController _casteCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _medicalDateCtrl;
  String _selectedGender = '';
  String _medical = '';
  bool _isCollapsed = false;
  bool get _collapsed => widget.collapsed ?? _isCollapsed;

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.index > 0;
    _nameCtrl =
        TextEditingController(text: widget.data['name']?.toString() ?? '');
    _ageCtrl =
        TextEditingController(text: widget.data['age']?.toString() ?? '');
    _occCtrl = TextEditingController(
        text: widget.data['occupation']?.toString() ?? '');
    _mobileCtrl =
        TextEditingController(text: widget.data['mobile']?.toString() ?? '');
    _aadhaarCtrl =
        TextEditingController(text: widget.data['aadhaar']?.toString() ?? '');
    _panCtrl =
        TextEditingController(text: widget.data['pan']?.toString() ?? '');
    _religionCtrl =
        TextEditingController(text: widget.data['religion']?.toString() ?? '');
    _casteCtrl =
        TextEditingController(text: widget.data['caste']?.toString() ?? '');
    _addressCtrl =
        TextEditingController(text: widget.data['address']?.toString() ?? '');

    final g = widget.data['gender']?.toString();
    _selectedGender = g ?? '';
    _medical = widget.data['medical']?.toString() ?? '';
    _medicalDateCtrl = TextEditingController(
        text: _displayDate(widget.data['medical_date']?.toString() ?? ''));

    _nameCtrl.addListener(() => _sync('name', _nameCtrl.text));
    _ageCtrl.addListener(() => _sync('age', _ageCtrl.text));
    _occCtrl.addListener(() => _sync('occupation', _occCtrl.text));
    _mobileCtrl.addListener(() => _sync('mobile', _mobileCtrl.text));
    _aadhaarCtrl.addListener(() => _sync('aadhaar', _aadhaarCtrl.text));
    _panCtrl.addListener(() => _sync('pan', _panCtrl.text));
    _religionCtrl.addListener(() => _sync('religion', _religionCtrl.text));
    _casteCtrl.addListener(() => _sync('caste', _casteCtrl.text));
    _addressCtrl.addListener(() => _sync('address', _addressCtrl.text));
    _medicalDateCtrl
        .addListener(() => _sync('medical_date', _medicalDateCtrl.text));
  }

  /// dd/MM/yyyy for a saved date that may come back as yyyy-MM-dd
  String _displayDate(String raw) {
    final iso = DateTime.tryParse(raw.trim());
    return iso != null && raw.contains('-')
        ? DateFormat('dd/MM/yyyy').format(iso)
        : raw;
  }

  bool get _medicalDone =>
      widget.yesNoOptions.isNotEmpty && _medical == widget.yesNoOptions.first;

  void _sync(String key, String val) {
    widget.data[key] = val;
    widget.onChanged?.call();
    if (mounted) setState(() {});
  }

  String _summaryText() {
    final n = _nameCtrl.text.trim();
    final a = _ageCtrl.text.trim();
    if (n.isNotEmpty) {
      return a.isNotEmpty ? '$n ($a yrs)' : n;
    }
    return _collapsed ? 'Tap to enter name' : '';
  }

  @override
  void didUpdateWidget(covariant _InlinePersonCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data['name'] != null && widget.data['name'] != _nameCtrl.text) {
      _nameCtrl.text = widget.data['name'].toString();
    }
    final g = widget.data['gender']?.toString();
    if (g != null && g.isNotEmpty && g != _selectedGender) {
      _selectedGender = g;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _occCtrl.dispose();
    _mobileCtrl.dispose();
    _aadhaarCtrl.dispose();
    _panCtrl.dispose();
    _religionCtrl.dispose();
    _casteCtrl.dispose();
    _addressCtrl.dispose();
    _medicalDateCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          GoogleFonts.poppins(fontSize: 12, color: AppColors.lightSubText),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: widget.readOnly ? const Color(0xFFF8FAFC) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.navyMid, width: 1.5),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isRequired = false,
    int maxLines = 1,
    int? minLines,
    TextInputType? keyboardType,
    bool isAge = false,
    bool isMobile = false,
    bool isAadhaar = false,
    bool isPan = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // PC: label above its box, like every other field
        final isWide = constraints.maxWidth >= 280 &&
            MediaQuery.sizeOf(context).width < 1000;
        final isMultiline = maxLines > 1;

        // Mobile / Aadhaar / PAN are optional, but when filled they must be
        // 10 digits / 12 digits / like ABCDE1234F
        String? digitsError(String? v, int count) {
          final value = v?.trim() ?? '';
          if (value.isEmpty) return null;
          return RegExp('^[0-9]{$count}\$').hasMatch(value)
              ? null
              : '$label must be exactly $count digits';
        }

        final List<TextInputFormatter>? checkedFormatters = isMobile
            ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ]
            : isAadhaar
                ? [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ]
                : isPan
                    ? panInputFormatters
                    : null;
        final FormFieldValidator<String>? checkedValidator = isMobile
            ? (v) => digitsError(v, 10)
            : isAadhaar
                ? (v) => digitsError(v, 12)
                : isPan
                    ? (v) => panValidationError(v, label)
                    : null;

        Widget box(List<TextInputFormatter>? formatters, String? errorText) =>
            TextFormField(
              controller: controller,
              readOnly: widget.readOnly,
              maxLines: maxLines,
              minLines: minLines,
              keyboardType: keyboardType,
              textCapitalization: isPan
                  ? TextCapitalization.characters
                  : TextCapitalization.none,
              inputFormatters: checkedFormatters ?? formatters,
              autovalidateMode: checkedValidator != null
                  ? AutovalidateMode.onUserInteraction
                  : null,
              validator: checkedValidator,
              style:
                  GoogleFonts.poppins(fontSize: 13, color: AppColors.lightText),
              decoration: _inputDeco(hint).copyWith(errorText: errorText),
            );
        // Ages: at most 3 digits, with the same message as every other tab
        final input = isAge
            ? AgeDigitsLimit(label: label, builder: box)
            : box(null, null);

        if (!isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyDark,
                      ),
                    ),
                    if (isRequired)
                      const Text(
                        ' *',
                        style: TextStyle(
                          color: AppColors.dangerRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
              input,
            ],
          );
        }

        return Row(
          crossAxisAlignment: isMultiline
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 105,
              child: Padding(
                padding: EdgeInsets.only(top: isMultiline ? 12 : 0),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navyDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isRequired)
                      const Text(
                        ' *',
                        style: TextStyle(
                          color: AppColors.dangerRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: input,
            ),
          ],
        );
      },
    );
  }

  /// Label beside (wide) or above (narrow) an input, like the card's other fields
  Widget _labeled(String label, Widget input) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final text = Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.navyDark,
          ),
        );
        // PC: label above its box, like every other field; the label sits
        // beside the box only on a tablet-width card
        final sideBySide = constraints.maxWidth >= 280 &&
            MediaQuery.sizeOf(context).width < 1000;
        if (!sideBySide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(bottom: 4), child: text),
              input,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 105, child: text),
            const SizedBox(width: 8),
            Expanded(child: input),
          ],
        );
      },
    );
  }

  Widget _buildMedicalField() {
    final options = widget.yesNoOptions;
    return _labeled(
      'Medical',
      DropdownButtonFormField<String>(
        key: ValueKey('medical_${options.length}'),
        initialValue: options.contains(_medical) ? _medical : null,
        items: options
            .map((o) => DropdownMenuItem(
                  value: o,
                  child: Text(o,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.lightText)),
                ))
            .toList(),
        onChanged: widget.readOnly
            ? null
            : (val) {
                if (val == null) return;
                setState(() => _medical = val);
                _sync('medical', val);
                // The date belongs to a done medical only
                if (!_medicalDone) _medicalDateCtrl.clear();
              },
        decoration: _inputDeco('Select'),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: AppColors.navyMid, size: 20),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }

  Widget _buildMedicalDateField() {
    return _labeled(
      'Medical Date',
      TextFormField(
        controller: _medicalDateCtrl,
        readOnly: true,
        onTap: widget.readOnly ? null : _pickMedicalDate,
        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.lightText),
        decoration: _inputDeco('dd/mm/yyyy').copyWith(
          suffixIcon: const Icon(Icons.calendar_today_rounded,
              size: 18, color: AppColors.navyMid),
        ),
      ),
    );
  }

  Future<void> _pickMedicalDate() async {
    DateTime initial = DateTime.now();
    try {
      initial = DateFormat('dd/MM/yyyy').parseStrict(_medicalDateCtrl.text);
    } catch (_) {}
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _medicalDateCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Widget _buildGenderField() {
    final genders = widget.genderOptions;
    return LayoutBuilder(
      builder: (context, constraints) {
        // PC: label above its box, like every other field
        final isWide = constraints.maxWidth >= 280 &&
            MediaQuery.sizeOf(context).width < 1000;
        if (!isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Gender',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navyDark,
                  ),
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue:
                    genders.contains(_selectedGender) ? _selectedGender : null,
                items: genders
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(g,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.lightText)),
                        ))
                    .toList(),
                onChanged: widget.readOnly
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() => _selectedGender = val);
                          _sync('gender', val);
                        }
                      },
                decoration: _inputDeco('Select Gender'),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.navyMid, size: 20),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 105,
              child: Text(
                'Gender',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue:
                    genders.contains(_selectedGender) ? _selectedGender : null,
                items: genders
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(g,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.lightText)),
                        ))
                    .toList(),
                onChanged: widget.readOnly
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() => _selectedGender = val);
                          _sync('gender', val);
                        }
                      },
                decoration: _inputDeco('Select Gender'),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.navyMid, size: 20),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: _collapsed ? 8 : 12),
      padding: _collapsed
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
          : const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: widget.onToggle ??
                () => setState(() => _isCollapsed = !_isCollapsed),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.navyMid.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${widget.roleTitle} #${widget.index + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyMid,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _summaryText(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _collapsed
                            ? AppColors.navyDark
                            : AppColors.lightSubText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Done: fold this filled card (like the charges)
                  if (!_collapsed &&
                      widget.onToggle != null &&
                      _nameCtrl.text.trim().isNotEmpty)
                    TextButton.icon(
                      onPressed: widget.onToggle,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.navyMid,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.check_rounded, size: 17),
                      label: Text(
                        'Done',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (widget.canRemove && !widget.readOnly)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 19, color: AppColors.dangerRed),
                      onPressed: widget.onRemove,
                      tooltip: 'Remove ${widget.roleTitle}',
                      splashRadius: 16,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    _collapsed
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    color: AppColors.navyMid,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (!_collapsed) ...[
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                // PC: two fields per line even in a one-third-width box
                final isWide = constraints.maxWidth >
                    (MediaQuery.sizeOf(context).width >= 1000 ? 300 : 550);
                final nameFld = _buildField(
                  label: 'Name',
                  controller: _nameCtrl,
                  hint: 'Full name',
                  isRequired: true,
                );
                final ageFld = _buildField(
                  label: 'Age',
                  controller: _ageCtrl,
                  hint: 'Years',
                  keyboardType: TextInputType.number,
                  isAge: true,
                );
                final genderFld = _buildGenderField();
                final occFld = _buildField(
                  label: 'Occupation',
                  controller: _occCtrl,
                  hint: 'Enter Occupation',
                );
                final mobileFld = _buildField(
                  label: 'Mobile Number',
                  controller: _mobileCtrl,
                  hint: '10-digit number',
                  keyboardType: TextInputType.phone,
                  isMobile: true,
                );
                final aadhaarFld = _buildField(
                  label: 'Aadhar Number',
                  controller: _aadhaarCtrl,
                  hint: 'XXXX XXXX XXXX',
                  keyboardType: TextInputType.number,
                  isAadhaar: true,
                );
                final panFld = _buildField(
                  label: 'PAN Number',
                  controller: _panCtrl,
                  hint: 'ABCDE1234F',
                  isPan: true,
                );
                final relFld = _buildField(
                  label: 'Religion',
                  controller: _religionCtrl,
                  hint: 'Enter Religion',
                );
                final casteFld = _buildField(
                  label: 'Caste',
                  controller: _casteCtrl,
                  hint: 'Enter Caste',
                );
                final addrFld = _buildField(
                  label: 'Address',
                  controller: _addressCtrl,
                  hint: 'House no., street, area, city',
                  maxLines: 2,
                );
                // Beside Medical: starts one line high (same as the boxes
                // next to it) and grows to three lines as the user types
                final addrLineFld = _buildField(
                  label: 'Address',
                  controller: _addressCtrl,
                  hint: 'House no., street, area, city',
                  maxLines: 3,
                  minLines: 1,
                );
                final medicalFlds = widget.showMedical
                    ? [
                        _buildMedicalField(),
                        if (_medicalDone) _buildMedicalDateField(),
                      ]
                    : const <Widget>[];

                final entries = <MapEntry<Widget, bool>>[
                  MapEntry(nameFld, _nameCtrl.text.trim().isNotEmpty),
                  MapEntry(ageFld, _ageCtrl.text.trim().isNotEmpty),
                  MapEntry(genderFld, _selectedGender.trim().isNotEmpty),
                  MapEntry(occFld, _occCtrl.text.trim().isNotEmpty),
                  MapEntry(mobileFld, _mobileCtrl.text.trim().isNotEmpty),
                  MapEntry(aadhaarFld, _aadhaarCtrl.text.trim().isNotEmpty),
                  MapEntry(panFld, _panCtrl.text.trim().isNotEmpty),
                  MapEntry(relFld, _religionCtrl.text.trim().isNotEmpty),
                  MapEntry(casteFld, _casteCtrl.text.trim().isNotEmpty),
                  if (medicalFlds.isNotEmpty)
                    MapEntry(medicalFlds.first, _medical.trim().isNotEmpty),
                  if (medicalFlds.length > 1)
                    MapEntry(medicalFlds[1],
                        _medicalDateCtrl.text.trim().isNotEmpty),
                  MapEntry(addrFld, _addressCtrl.text.trim().isNotEmpty),
                ];

                final visibleEntries = widget.readOnly
                    ? entries.where((e) => e.value).map((e) => e.key).toList()
                    : entries.map((e) => e.key).toList();

                if (visibleEntries.isEmpty) {
                  return const SizedBox.shrink();
                }

                if (widget.readOnly) {
                  if (!isWide || visibleEntries.length == 1) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < visibleEntries.length; i++) ...[
                          if (i > 0) const SizedBox(height: 12),
                          visibleEntries[i],
                        ],
                      ],
                    );
                  }

                  final rows = <Widget>[];
                  for (int i = 0; i < visibleEntries.length; i += 2) {
                    final first = visibleEntries[i];
                    final second = (i + 1 < visibleEntries.length)
                        ? visibleEntries[i + 1]
                        : null;
                    if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
                    rows.add(
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: first),
                          const SizedBox(width: 16),
                          Expanded(child: second ?? const SizedBox.shrink()),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: rows,
                  );
                }

                if (!isWide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      nameFld,
                      const SizedBox(height: 12),
                      ageFld,
                      const SizedBox(height: 12),
                      genderFld,
                      const SizedBox(height: 12),
                      mobileFld,
                      const SizedBox(height: 12),
                      aadhaarFld,
                      const SizedBox(height: 12),
                      panFld,
                      const SizedBox(height: 12),
                      relFld,
                      const SizedBox(height: 12),
                      casteFld,
                      const SizedBox(height: 12),
                      occFld,
                      const SizedBox(height: 12),
                      for (final f in medicalFlds) ...[
                        f,
                        const SizedBox(height: 12),
                      ],
                      addrFld,
                    ],
                  );
                }

                final perLine = _personPerLine(constraints.maxWidth);
                // Same order as the Complainant card: Occupation after Caste
                final cells = [
                  nameFld,
                  ageFld,
                  genderFld,
                  mobileFld,
                  aadhaarFld,
                  panFld,
                  relFld,
                  casteFld,
                  occFld,
                ];
                // Fields left over after the full lines share the last
                // line with Medical (and its date) and Address, which fills
                // the rest; each stays under its column
                final full = cells.length - cells.length % perLine;
                final last = [...cells.sublist(full), ...medicalFlds];
                final addrSlots = perLine - last.length % perLine;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._personFieldRows(cells.sublist(0, full), perLine),
                    if (last.length >= perLine)
                      ..._personFieldRows(
                          last.sublist(0, last.length - last.length % perLine),
                          perLine),
                    if (last.isEmpty)
                      addrFld
                    else
                      _personFlexRow([
                        for (final w in last
                            .sublist(last.length - last.length % perLine))
                          MapEntry(w, 1),
                        MapEntry(addrLineFld, addrSlots),
                      ]),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ── Inline Unidentified Accused Card (No Popup Dialogs) ──────────────────────
class _InlineUnidentifiedAccusedCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> data;
  final VoidCallback? onRemove;
  final VoidCallback? onChanged;
  final bool readOnly;
  final bool canRemove;

  /// When set, the parent decides whether the card is collapsed and
  /// [onToggle] is called on a header tap instead of toggling locally.
  final bool? collapsed;
  final VoidCallback? onToggle;

  /// Gender choices from the database (/api/options/gender/); empty uses the
  /// card's own list
  final List<String> genderOptions;

  const _InlineUnidentifiedAccusedCard({
    super.key,
    required this.index,
    required this.data,
    this.onRemove,
    this.onChanged,
    this.readOnly = false,
    this.canRemove = false,
    this.collapsed,
    this.onToggle,
    this.genderOptions = const [],
  });

  @override
  State<_InlineUnidentifiedAccusedCard> createState() =>
      _InlineUnidentifiedAccusedCardState();
}

class _InlineUnidentifiedAccusedCardState
    extends State<_InlineUnidentifiedAccusedCard> {
  late final TextEditingController _ageCtrl;
  late final TextEditingController _skinCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _occCtrl;
  late final TextEditingController _markCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _addressCtrl;
  String _selectedGender = '';
  bool _isCollapsed = false;
  bool get _collapsed => widget.collapsed ?? _isCollapsed;

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.index > 0;
    _ageCtrl = TextEditingController(
        text: widget.data['approximate_age']?.toString() ?? '');
    _skinCtrl = TextEditingController(
        text: widget.data['skin_colour']?.toString() ?? '');
    _heightCtrl =
        TextEditingController(text: widget.data['height']?.toString() ?? '');
    _occCtrl = TextEditingController(
        text: widget.data['possible_occupation']?.toString() ?? '');
    _markCtrl = TextEditingController(
        text: widget.data['identification_mark']?.toString() ?? '');
    _descCtrl = TextEditingController(
        text: widget.data['description']?.toString() ?? '');
    _addressCtrl =
        TextEditingController(text: widget.data['address']?.toString() ?? '');

    final g = widget.data['gender']?.toString();
    _selectedGender = g ?? '';

    _ageCtrl.addListener(() => _sync('approximate_age', _ageCtrl.text));
    _skinCtrl.addListener(() => _sync('skin_colour', _skinCtrl.text));
    _heightCtrl.addListener(() => _sync('height', _heightCtrl.text));
    _occCtrl.addListener(() => _sync('possible_occupation', _occCtrl.text));
    _markCtrl.addListener(() => _sync('identification_mark', _markCtrl.text));
    _descCtrl.addListener(() => _sync('description', _descCtrl.text));
    _addressCtrl.addListener(() => _sync('address', _addressCtrl.text));
  }

  void _sync(String key, String val) {
    widget.data[key] = val;
    widget.onChanged?.call();
    if (mounted) setState(() {});
  }

  String _summaryText() {
    final parts = <String>[];
    final a = _ageCtrl.text.trim();
    if (a.isNotEmpty) parts.add('approx $a yrs');
    final h = _heightCtrl.text.trim();
    if (h.isNotEmpty) parts.add(h);
    final s = _skinCtrl.text.trim();
    if (s.isNotEmpty) parts.add(s);
    if (parts.isEmpty) return _collapsed ? 'Tap to enter details' : '';
    return parts.join(' · ');
  }

  @override
  void didUpdateWidget(covariant _InlineUnidentifiedAccusedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final g = widget.data['gender']?.toString();
    if (g != null && g.isNotEmpty && g != _selectedGender) {
      _selectedGender = g;
    }
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _skinCtrl.dispose();
    _heightCtrl.dispose();
    _occCtrl.dispose();
    _markCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          GoogleFonts.poppins(fontSize: 12, color: AppColors.lightSubText),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: widget.readOnly ? const Color(0xFFF8FAFC) : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.navyMid, width: 1.5),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int? minLines,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.navyDark,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          readOnly: widget.readOnly,
          maxLines: maxLines,
          minLines: minLines,
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.lightText),
          decoration: _inputDeco(hint),
        ),
      ],
    );
  }

  Widget _buildGenderField() {
    final genders = widget.genderOptions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            'Gender',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.navyDark,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue:
              genders.contains(_selectedGender) ? _selectedGender : null,
          items: genders
              .map((g) => DropdownMenuItem(
                    value: g,
                    child: Text(g,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.lightText)),
                  ))
              .toList(),
          onChanged: widget.readOnly
              ? null
              : (val) {
                  if (val != null) {
                    setState(() => _selectedGender = val);
                    _sync('gender', val);
                  }
                },
          decoration: _inputDeco('Select Gender'),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.navyMid, size: 20),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: _collapsed ? 8 : 12),
      padding: _collapsed
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
          : const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: widget.onToggle ??
                () => setState(() => _isCollapsed = !_isCollapsed),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.navyMid.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Unidentified Accused #${widget.index + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyMid,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _summaryText(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _collapsed
                            ? AppColors.navyDark
                            : AppColors.lightSubText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Done: fold this filled card (like the charges)
                  if (!_collapsed &&
                      widget.onToggle != null &&
                      _summaryText().isNotEmpty)
                    TextButton.icon(
                      onPressed: widget.onToggle,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.navyMid,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.check_rounded, size: 17),
                      label: Text(
                        'Done',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (widget.canRemove && !widget.readOnly)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 19, color: AppColors.dangerRed),
                      onPressed: widget.onRemove,
                      tooltip: 'Remove Unidentified Accused',
                      splashRadius: 16,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    _collapsed
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    color: AppColors.navyMid,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (!_collapsed) ...[
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                // PC: two fields per line even in a one-third-width box
                final isWide = constraints.maxWidth >
                    (MediaQuery.sizeOf(context).width >= 1000 ? 300 : 550);
                final ageFld = _buildField(
                  label: 'Approximate Age',
                  controller: _ageCtrl,
                  hint: 'Enter Approximate Age',
                );
                final genderFld = _buildGenderField();
                final skinFld = _buildField(
                  label: 'Skin Colour / Complexion',
                  controller: _skinCtrl,
                  hint: 'Enter Skin Colour',
                );
                final heightFld = _buildField(
                  label: 'Height',
                  controller: _heightCtrl,
                  hint: 'Enter Height (e.g. 5\'8")',
                );
                final occFld = _buildField(
                  label: 'Possible Occupation',
                  controller: _occCtrl,
                  hint: 'Enter Possible Occupation',
                );
                final markFld = _buildField(
                  label: 'Identification Mark / Tattoos',
                  controller: _markCtrl,
                  hint: 'Enter Identification Marks',
                );
                final descFld = _buildField(
                  label: 'Physical Description / Clothing',
                  controller: _descCtrl,
                  hint: 'Enter description of appearance or clothing...',
                  maxLines: 2,
                );
                final addrFld = _buildField(
                  label: 'Place / Area Last Seen',
                  controller: _addressCtrl,
                  hint: 'Enter Place / Location...',
                  maxLines: 2,
                );

                final entries = <MapEntry<Widget, bool>>[
                  MapEntry(ageFld, _ageCtrl.text.trim().isNotEmpty),
                  MapEntry(genderFld, _selectedGender.trim().isNotEmpty),
                  MapEntry(skinFld, _skinCtrl.text.trim().isNotEmpty),
                  MapEntry(heightFld, _heightCtrl.text.trim().isNotEmpty),
                  MapEntry(occFld, _occCtrl.text.trim().isNotEmpty),
                  MapEntry(markFld, _markCtrl.text.trim().isNotEmpty),
                  MapEntry(descFld, _descCtrl.text.trim().isNotEmpty),
                  MapEntry(addrFld, _addressCtrl.text.trim().isNotEmpty),
                ];

                final visibleEntries = widget.readOnly
                    ? entries.where((e) => e.value).map((e) => e.key).toList()
                    : entries.map((e) => e.key).toList();

                if (visibleEntries.isEmpty) {
                  return const SizedBox.shrink();
                }

                if (!isWide || visibleEntries.length == 1) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < visibleEntries.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        visibleEntries[i],
                      ],
                    ],
                  );
                }

                if (widget.readOnly) {
                  final rows = <Widget>[];
                  for (int i = 0; i < visibleEntries.length; i += 2) {
                    final first = visibleEntries[i];
                    final second = (i + 1 < visibleEntries.length)
                        ? visibleEntries[i + 1]
                        : null;
                    if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
                    rows.add(
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: first),
                          const SizedBox(width: 16),
                          Expanded(child: second ?? const SizedBox.shrink()),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: rows,
                  );
                }

                // In the grid, Description and Place start one line high
                // (level with the boxes beside them) and grow to three
                final descLineFld = _buildField(
                  label: 'Physical Description / Clothing',
                  controller: _descCtrl,
                  hint: 'Appearance or clothing',
                  maxLines: 3,
                  minLines: 1,
                );
                final addrLineFld = _buildField(
                  label: 'Place / Area Last Seen',
                  controller: _addressCtrl,
                  hint: 'Enter Place / Location',
                  maxLines: 3,
                  minLines: 1,
                );
                final perLine = _personPerLine(constraints.maxWidth);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _personFieldRows([
                    ageFld,
                    genderFld,
                    skinFld,
                    heightFld,
                    occFld,
                    markFld,
                    descLineFld,
                    addrLineFld,
                  ], perLine),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ── Preventive Action Person Card (Inline Row + Dropdown + Expandable Details) ─
class _PreventivePersonCard extends StatefulWidget {
  final String personName;
  final bool isCustom;
  final bool readOnly;
  final Map<String, dynamic>? initialAction;
  final List<String> choices;
  final void Function(Map<String, dynamic> actionData) onSaveAction;
  final VoidCallback onRemoveAction;
  final VoidCallback? onRemovePerson;

  const _PreventivePersonCard({
    super.key,
    required this.personName,
    required this.isCustom,
    required this.readOnly,
    required this.initialAction,
    required this.choices,
    required this.onSaveAction,
    required this.onRemoveAction,
    this.onRemovePerson,
  });

  @override
  State<_PreventivePersonCard> createState() => _PreventivePersonCardState();
}

class _PreventivePersonCardState extends State<_PreventivePersonCard> {
  /// Dropdown value for "Other": the officer types the Section / Act.
  static const _otherValue = '__other__';

  String? _selectedSection;

  /// "Other" is picked; [_selectedSection] is then the typed text.
  bool _isOther = false;
  late TextEditingController _otherCtrl;
  late TextEditingController _dateCtrl;
  late TextEditingController _outwardCtrl;
  late TextEditingController _numberCtrl;
  late TextEditingController _bondDateCtrl;
  late TextEditingController _bondCancelDateCtrl;

  @override
  void initState() {
    super.initState();
    _initFromAction(widget.initialAction);
  }

  @override
  void didUpdateWidget(covariant _PreventivePersonCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialAction != widget.initialAction) {
      final a = widget.initialAction;
      // Our own save / remove coming back from the parent: the card already
      // shows it (and keeps "Other" open while its box is being cleared)
      if (identical(a, _lastSent) || (a == null && _selectedSection == null)) {
        return;
      }
      _initFromAction(a);
    }
  }

  void _initFromAction(Map<String, dynamic>? action) {
    _selectedSection =
        (action?['action_type'] ?? action?['action'])?.toString();
    if (_selectedSection != null && _selectedSection!.isEmpty) {
      _selectedSection = null;
    }
    // A saved provision that is not in the list was typed under "Other"
    _isOther = _selectedSection != null &&
        widget.choices.isNotEmpty &&
        !widget.choices.contains(_selectedSection);
    _otherCtrl = TextEditingController(text: _isOther ? _selectedSection : '');
    _dateCtrl = TextEditingController(
      text: (action?['action_date'] ?? action?['actionDate'])?.toString() ?? '',
    );
    _outwardCtrl = TextEditingController(
      text:
          (action?['outward_number'] ?? action?['outwardNumber'])?.toString() ??
              '',
    );
    _numberCtrl = TextEditingController(
      text: (action?['preventive_number'] ?? action?['preventiveNumber'])
              ?.toString() ??
          '',
    );
    _bondDateCtrl = TextEditingController(
      text: (action?['bond_date'] ?? action?['bondDate'])?.toString() ?? '',
    );
    _bondCancelDateCtrl = TextEditingController(
      text:
          (action?['bond_cancellation_date'] ?? action?['bondCancellationDate'])
                  ?.toString() ??
              '',
    );
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _outwardCtrl.dispose();
    _numberCtrl.dispose();
    _bondDateCtrl.dispose();
    _bondCancelDateCtrl.dispose();
    _otherCtrl.dispose();
    super.dispose();
  }

  /// The last action map this card sent up.
  Map<String, dynamic>? _lastSent;

  void _notifySave() {
    if (_selectedSection == null || _selectedSection!.isEmpty) return;
    widget.onSaveAction(_lastSent = {
      'name': widget.personName,
      'person_name': widget.personName,
      'accusedName': widget.personName,
      'action_type': _selectedSection!,
      'action': _selectedSection!,
      'action_date': _dateCtrl.text.trim(),
      'actionDate': _dateCtrl.text.trim(),
      'outward_number': _outwardCtrl.text.trim(),
      'outwardNumber': _outwardCtrl.text.trim(),
      'preventive_number': _numberCtrl.text.trim(),
      'preventiveNumber': _numberCtrl.text.trim(),
      'bond_date': _bondDateCtrl.text.trim(),
      'bondDate': _bondDateCtrl.text.trim(),
      'bond_cancellation_date': _bondCancelDateCtrl.text.trim(),
      'bondCancellationDate': _bondCancelDateCtrl.text.trim(),
    });
  }

  void _handleRemove() {
    setState(() {
      _selectedSection = null;
      _isOther = false;
      _otherCtrl.clear();
      _dateCtrl.clear();
      _outwardCtrl.clear();
      _numberCtrl.clear();
      _bondDateCtrl.clear();
      _bondCancelDateCtrl.clear();
    });
    widget.onRemoveAction();
    if (widget.isCustom && widget.onRemovePerson != null) {
      widget.onRemovePerson!();
    }
  }

  void _onSectionChanged(String? newSection) {
    if (widget.readOnly) return;
    if (newSection == null || newSection.isEmpty) {
      _handleRemove();
    } else {
      setState(() {
        _selectedSection = newSection;
      });
      _notifySave();
    }
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    if (widget.readOnly) return;
    DateTime initial = DateTime.now();
    final cur = ctrl.text.trim();
    if (cur.isNotEmpty) {
      final parts = cur.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]) ?? initial.day;
        final m = int.tryParse(parts[1]) ?? initial.month;
        final y = int.tryParse(parts[2]) ?? initial.year;
        initial = DateTime(y, m, d);
      }
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final formatted = DateFormat('dd/MM/yyyy').format(picked);
      setState(() {
        ctrl.text = formatted;
      });
      _notifySave();
    }
  }

  void _onDropdownChanged(String? v) {
    if (v == _otherValue) {
      final typed = _otherCtrl.text.trim();
      setState(() {
        _isOther = true;
        _selectedSection = typed.isEmpty ? null : typed;
      });
      if (typed.isEmpty) {
        widget.onRemoveAction();
      } else {
        _notifySave();
      }
      return;
    }
    setState(() => _isOther = false);
    _onSectionChanged(v);
  }

  void _onOtherTyped(String val) {
    final typed = val.trim();
    setState(() => _selectedSection = typed.isEmpty ? null : typed);
    if (typed.isEmpty) {
      widget.onRemoveAction();
    } else {
      _notifySave();
    }
  }

  /// Type-in box shown when "Other" is picked.
  Widget? _buildOtherField() {
    if (!_isOther) return null;
    return TextFormField(
      key: ValueKey('prev_other_${widget.personName}'),
      controller: _otherCtrl,
      readOnly: widget.readOnly,
      maxLength: 100,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.navyDark,
      ),
      onChanged: _onOtherTyped,
      decoration: InputDecoration(
        labelText: 'Specify Section / Act',
        hintText: 'e.g. 129 BNSS r/w ...',
        counterText: '',
        labelStyle:
            GoogleFonts.poppins(fontSize: 12, color: AppColors.lightSubText),
        hintStyle:
            GoogleFonts.poppins(fontSize: 12, color: AppColors.lightSubText),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.navyMid, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    final allChoices = List<String>.from(widget.choices);
    final String? currentVal = _isOther
        ? _otherValue
        : (allChoices.contains(_selectedSection) ? _selectedSection : null);
    return DropdownButtonFormField<String?>(
      key: ValueKey('drop_${widget.personName}_$currentVal'),
      initialValue: currentVal,
      isExpanded: true,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.navyDark,
      ),
      decoration: InputDecoration(
        labelText: 'Preventive Section / Act',
        hintText: 'Select Section / Act...',
        labelStyle:
            GoogleFonts.poppins(fontSize: 12, color: AppColors.lightSubText),
        hintStyle:
            GoogleFonts.poppins(fontSize: 12, color: AppColors.lightSubText),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.navyMid, width: 1.5),
        ),
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text(
            '-- None (No Preventive Action) --',
            style: TextStyle(
                color: AppColors.lightSubText, fontWeight: FontWeight.normal),
          ),
        ),
        ...allChoices.map((c) => DropdownMenuItem<String?>(
              value: c,
              child: Text(c),
            )),
        const DropdownMenuItem<String?>(
          value: _otherValue,
          child: Text('Other (type)'),
        ),
      ],
      onChanged: widget.readOnly ? null : _onDropdownChanged,
    );
  }

  /// Field name above its box, like the other form cards.
  Widget _labelled(String label, Widget field, {bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.navyDark,
            ),
            children: [
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: AppColors.dangerRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        field,
      ],
    );
  }

  Widget _buildDateField(String label, TextEditingController ctrl,
      {bool required = false}) {
    return _labelled(
        label,
        required: required,
        TextFormField(
          controller: ctrl,
          readOnly: true,
          onTap: widget.readOnly ? null : () => _pickDate(ctrl),
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.navyDark,
          ),
          decoration: InputDecoration(
            hintText: 'DD/MM/YYYY',
            hintStyle: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.lightSubText),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_month_rounded,
                  size: 20, color: AppColors.navyMid),
              onPressed: widget.readOnly ? null : () => _pickDate(ctrl),
              tooltip: 'Select date',
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide:
                  const BorderSide(color: AppColors.navyMid, width: 1.5),
            ),
          ),
        ));
  }

  Widget _buildOutwardField() {
    return _labelled(
        'Outward Number',
        TextFormField(
          controller: _outwardCtrl,
          readOnly: widget.readOnly,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.navyDark,
          ),
          onChanged: (_) => _notifySave(),
          decoration: InputDecoration(
            hintText: 'OUT/2026/102',
            hintStyle: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.lightSubText),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide:
                  const BorderSide(color: AppColors.navyMid, width: 1.5),
            ),
          ),
        ));
  }

  Widget _buildNumberField() {
    return _labelled(
        'Preventive Number',
        TextFormField(
          controller: _numberCtrl,
          readOnly: widget.readOnly,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.navyDark,
          ),
          onChanged: (_) => _notifySave(),
          decoration: InputDecoration(
            hintText: 'Enter preventive number',
            hintStyle: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.lightSubText),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide:
                  const BorderSide(color: AppColors.navyMid, width: 1.5),
            ),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final bool hasAction =
        _selectedSection != null && _selectedSection!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: hasAction
              ? AppColors.navyMid.withValues(alpha: 0.4)
              : AppColors.lightBorder,
          width: hasAction ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Line 1: In one line only, in front of name show dropdown + remove button ──
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 560;

                final removeButton = (!widget.readOnly &&
                        (hasAction || widget.isCustom))
                    ? IconButton(
                        onPressed: _handleRemove,
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.dangerRed, size: 22),
                        tooltip: hasAction ? 'Remove Action' : 'Remove Person',
                        splashRadius: 20,
                      )
                    : null;

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: hasAction
                                    ? AppColors.navyMid.withValues(alpha: 0.1)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: hasAction
                                      ? AppColors.navyMid.withValues(alpha: 0.3)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person_rounded,
                                    size: 16,
                                    color: hasAction
                                        ? AppColors.navyMid
                                        : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.personName,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: hasAction
                                            ? AppColors.navyDark
                                            : const Color(0xFF334155),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (removeButton != null) ...[
                            const SizedBox(width: 6),
                            removeButton,
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildDropdown(),
                      if (_buildOtherField() case final other?) ...[
                        const SizedBox(height: 8),
                        other,
                      ],
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Person Name badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: hasAction
                            ? AppColors.navyMid.withValues(alpha: 0.1)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: hasAction
                              ? AppColors.navyMid.withValues(alpha: 0.3)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 16,
                            color: hasAction
                                ? AppColors.navyMid
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                                minWidth: 80, maxWidth: 180),
                            child: Text(
                              widget.personName,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: hasAction
                                    ? AppColors.navyDark
                                    : const Color(0xFF334155),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDropdown()),
                    if (_buildOtherField() case final other?) ...[
                      const SizedBox(width: 12),
                      Expanded(child: other),
                    ],
                    if (removeButton != null) ...[
                      const SizedBox(width: 6),
                      removeButton,
                    ],
                  ],
                );
              },
            ),

            // ── Then after selecting one, show other details ──
            if (hasAction) ...[
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.lightBorder),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 650;
                  if (isWide) {
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: _buildDateField('Action Date', _dateCtrl,
                                    required: true)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildOutwardField()),
                            const SizedBox(width: 12),
                            Expanded(child: _buildNumberField()),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                                child: _buildDateField(
                                    'Bond Date', _bondDateCtrl)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildDateField('Bond Cancellation Date',
                                    _bondCancelDateCtrl)),
                            // Same 3 columns as the line above
                            const SizedBox(width: 12),
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                      ],
                    );
                  } else if (MediaQuery.sizeOf(context).width >= 1000 &&
                      constraints.maxWidth > 300) {
                    // PC, narrow box: two fields per line
                    Widget pair(Widget a, Widget b) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: a),
                              const SizedBox(width: 12),
                              Expanded(child: b),
                            ],
                          ),
                        );
                    return Column(
                      children: [
                        pair(
                            _buildDateField('Action Date', _dateCtrl,
                                required: true),
                            _buildOutwardField()),
                        pair(_buildNumberField(),
                            _buildDateField('Bond Date', _bondDateCtrl)),
                        pair(
                            _buildDateField(
                                'Bond Cancellation Date', _bondCancelDateCtrl),
                            const SizedBox()),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildDateField('Action Date', _dateCtrl,
                            required: true),
                        const SizedBox(height: 12),
                        _buildOutwardField(),
                        const SizedBox(height: 12),
                        _buildNumberField(),
                        const SizedBox(height: 12),
                        _buildDateField('Bond Date', _bondDateCtrl),
                        const SizedBox(height: 12),
                        _buildDateField(
                            'Bond Cancellation Date', _bondCancelDateCtrl),
                      ],
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CustodyAccusedCard extends StatefulWidget {
  final String personName;
  final bool isCustom;
  final bool readOnly;
  final Map<String, dynamic>? initialData;
  final List<String> genderOptions;
  final List<String> relationChoices;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback? onRemovePerson;

  /// Only the fields (PCR, MCR and what they reveal): no card or name
  /// header, for use inside the Arrest & Custody record.
  final bool bare;

  /// Cells placed before PCR on its line (e.g. Arrested date and
  /// Intimation), so the four share one line.
  final List<Widget> leadingCells;

  /// Shown right under that line (e.g. the Intimation details), above the
  /// MCR options.
  final Widget? belowFirstRow;

  const _CustodyAccusedCard({
    super.key,
    required this.personName,
    required this.isCustom,
    required this.readOnly,
    this.initialData,
    required this.genderOptions,
    required this.relationChoices,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onChanged,
    this.onRemovePerson,
    this.bare = false,
    this.leadingCells = const [],
    this.belowFirstRow,
  });

  @override
  State<_CustodyAccusedCard> createState() => _CustodyAccusedCardState();
}

class _CustodyAccusedCardState extends State<_CustodyAccusedCard> {
  late TextEditingController _pcrDaysCtrl;
  late TextEditingController _prBondDateCtrl;
  late TextEditingController _jailDateCtrl;
  late TextEditingController _suretyNameCtrl;
  late TextEditingController _suretyAgeCtrl;
  late TextEditingController _suretyOccCtrl;
  late TextEditingController _suretyMobileCtrl;
  late TextEditingController _suretyAadhaarCtrl;
  late TextEditingController _suretyPanCtrl;
  late TextEditingController _suretyAddressCtrl;

  bool _isMcr = false;
  bool _isPrBond = false;
  bool _isJail = false;
  bool _isBail = false;
  String _suretyGender = '';
  String _suretyRelation = '';

  @override
  void initState() {
    super.initState();
    _initFromData(widget.initialData);
  }

  @override
  void didUpdateWidget(covariant _CustodyAccusedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialData != widget.initialData) {
      _initFromData(widget.initialData);
    }
  }

  void _initFromData(Map<String, dynamic>? data) {
    _pcrDaysCtrl = TextEditingController(
      text: (data?['pcr_days'] ?? data?['pcrDays'])?.toString() ?? '',
    );
    _isMcr = data?['mcr'] == true || data?['isMcr'] == true;
    _isPrBond = data?['pr_bond'] == true || data?['isPrBond'] == true;
    _prBondDateCtrl = TextEditingController(
      text: (data?['pr_bond_date'] ?? data?['prBondDate'])?.toString() ?? '',
    );
    _isJail = data?['jail'] == true || data?['isJail'] == true;
    _jailDateCtrl = TextEditingController(
      text: (data?['jail_date'] ?? data?['jailDate'])?.toString() ?? '',
    );
    _isBail = data?['bail'] == true || data?['isBail'] == true;
    _suretyNameCtrl = TextEditingController(
      text: (data?['surety_name'] ?? data?['suretyName'])?.toString() ?? '',
    );
    _suretyAgeCtrl = TextEditingController(
      text: (data?['surety_age'] ?? data?['suretyAge'])?.toString() ?? '',
    );
    _suretyGender =
        (data?['surety_gender'] ?? data?['suretyGender'])?.toString() ?? '';
    _suretyOccCtrl = TextEditingController(
      text: (data?['surety_occupation'] ?? data?['suretyOccupation'])
              ?.toString() ??
          '',
    );
    _suretyMobileCtrl = TextEditingController(
      text: (data?['surety_mobile'] ?? data?['suretyMobile'])?.toString() ?? '',
    );
    _suretyAadhaarCtrl = TextEditingController(
      text:
          (data?['surety_aadhaar'] ?? data?['suretyAadhaar'])?.toString() ?? '',
    );
    _suretyPanCtrl = TextEditingController(
      text: (data?['surety_pan'] ?? data?['suretyPan'])?.toString() ?? '',
    );
    _suretyAddressCtrl = TextEditingController(
      text:
          (data?['surety_address'] ?? data?['suretyAddress'])?.toString() ?? '',
    );
    _suretyRelation = (data?['surety_relation'] ??
                data?['suretyRelation'] ??
                data?['relation_with_accused'])
            ?.toString() ??
        '';
  }

  @override
  void dispose() {
    _pcrDaysCtrl.dispose();
    _prBondDateCtrl.dispose();
    _jailDateCtrl.dispose();
    _suretyNameCtrl.dispose();
    _suretyAgeCtrl.dispose();
    _suretyOccCtrl.dispose();
    _suretyMobileCtrl.dispose();
    _suretyAadhaarCtrl.dispose();
    _suretyPanCtrl.dispose();
    _suretyAddressCtrl.dispose();
    super.dispose();
  }

  void _notifyChange() {
    final record = <String, dynamic>{
      'name': widget.personName,
      'person_name': widget.personName,
      'accusedName': widget.personName,
      'pcr_days': _pcrDaysCtrl.text.trim(),
      'pcrDays': _pcrDaysCtrl.text.trim(),
      'mcr': _isMcr,
      'isMcr': _isMcr,
      'pr_bond': _isPrBond,
      'isPrBond': _isPrBond,
      'pr_bond_date': _isPrBond ? _prBondDateCtrl.text.trim() : '',
      'prBondDate': _isPrBond ? _prBondDateCtrl.text.trim() : '',
      'bail': _isBail,
      'isBail': _isBail,
      'surety_name': _isBail ? _suretyNameCtrl.text.trim() : '',
      'suretyName': _isBail ? _suretyNameCtrl.text.trim() : '',
      'surety_age': _isBail ? _suretyAgeCtrl.text.trim() : '',
      'suretyAge': _isBail ? _suretyAgeCtrl.text.trim() : '',
      'surety_gender': _isBail ? _suretyGender : '',
      'suretyGender': _isBail ? _suretyGender : '',
      'surety_occupation': _isBail ? _suretyOccCtrl.text.trim() : '',
      'suretyOccupation': _isBail ? _suretyOccCtrl.text.trim() : '',
      'surety_mobile': _isBail ? _suretyMobileCtrl.text.trim() : '',
      'suretyMobile': _isBail ? _suretyMobileCtrl.text.trim() : '',
      'surety_aadhaar': _isBail ? _suretyAadhaarCtrl.text.trim() : '',
      'suretyAadhaar': _isBail ? _suretyAadhaarCtrl.text.trim() : '',
      'surety_pan': _isBail ? _suretyPanCtrl.text.trim() : '',
      'suretyPan': _isBail ? _suretyPanCtrl.text.trim() : '',
      'surety_address': _isBail ? _suretyAddressCtrl.text.trim() : '',
      'suretyAddress': _isBail ? _suretyAddressCtrl.text.trim() : '',
      'surety_relation': _isBail ? _suretyRelation : '',
      'suretyRelation': _isBail ? _suretyRelation : '',
      'relation_with_accused': _isBail ? _suretyRelation : '',
      'jail': _isJail,
      'isJail': _isJail,
      'jail_date': _isJail ? _jailDateCtrl.text.trim() : '',
      'jailDate': _isJail ? _jailDateCtrl.text.trim() : '',
    };
    widget.onChanged(record);
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    if (widget.readOnly) return;
    DateTime initial = DateTime.now();
    final cur = ctrl.text.trim();
    if (cur.isNotEmpty) {
      final parts = cur.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]) ?? initial.day;
        final m = int.tryParse(parts[1]) ?? initial.month;
        final y = int.tryParse(parts[2]) ?? initial.year;
        initial = DateTime(y, m, d);
      }
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final formatted = DateFormat('dd/MM/yyyy').format(picked);
      setState(() {
        ctrl.text = formatted;
      });
      _notifyChange();
    }
  }

  InputDecoration _fieldDeco(String label, [String? hint]) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle:
          GoogleFonts.poppins(fontSize: 12, color: AppColors.lightSubText),
      hintStyle:
          GoogleFonts.poppins(fontSize: 12, color: AppColors.lightSubText),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.navyMid, width: 1.5),
      ),
    );
  }

  String? _getStatusSummary() {
    final List<String> parts = [];
    final pcr = _pcrDaysCtrl.text.trim();
    if (pcr.isNotEmpty && pcr != '0') {
      parts.add('PCR: ${pcr}d');
    }
    if (_isMcr) {
      if (_isBail) {
        final sn = _suretyNameCtrl.text.trim();
        parts.add(sn.isNotEmpty ? 'Bail: $sn' : 'Bail');
      } else if (_isJail) {
        parts.add('Jail');
      } else if (_isPrBond) {
        parts.add('PR Bond');
      } else {
        parts.add('MCR');
      }
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// Bordered box of one custody option (PR Bond, Jail or Bail).
  Widget _custodyOptionBox(bool on, Widget child) => Container(
        decoration: BoxDecoration(
          color: on ? AppColors.navyMid.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: on ? AppColors.navyMid : AppColors.lightBorder,
            width: on ? 1.5 : 1.0,
          ),
        ),
        child: child,
      );

  /// Surety details (opened by Bail): three fields per line on a wide
  /// card (Name | Age | Gender, Occupation | Mobile | Aadhaar, PAN |
  /// Relation | Address), one per line when narrow. Labels sit above the
  /// boxes; Gender is a dropdown so every box is the same height.
  Widget _buildSuretyCard() {
    InputDecoration deco(String hint) => InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
              fontSize: 12.5, color: const Color(0xFF94A3B8)),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.lightBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.navyMid, width: 1.5),
          ),
        );
    final textStyle =
        GoogleFonts.poppins(fontSize: 13, color: AppColors.navyDark);

    Widget labelled(String label, Widget field) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155))),
            const SizedBox(height: 4),
            field,
          ],
        );

    Widget text(String label, TextEditingController ctrl, String hint,
            {TextInputType? keyboard,
            TextCapitalization caps = TextCapitalization.none}) =>
        labelled(
          label,
          TextFormField(
            controller: ctrl,
            readOnly: widget.readOnly,
            keyboardType: keyboard,
            textCapitalization: caps,
            style: textStyle,
            decoration: deco(hint),
            onChanged: (_) => _notifyChange(),
          ),
        );

    Widget dropdown(String label, String? value, List<String> items,
            String hint, ValueChanged<String> onPick) =>
        labelled(
          label,
          DropdownButtonFormField<String>(
            initialValue: items.contains(value) ? value : null,
            isExpanded: true,
            decoration: deco(hint),
            hint: Text(hint,
                style: GoogleFonts.poppins(
                    fontSize: 12.5, color: const Color(0xFF94A3B8))),
            items: items
                .map((v) => DropdownMenuItem<String>(
                    value: v, child: Text(v, style: textStyle)))
                .toList(),
            onChanged: widget.readOnly
                ? null
                : (v) {
                    if (v == null) return;
                    setState(() => onPick(v));
                    _notifyChange();
                  },
          ),
        );

    final genders = widget.genderOptions.isNotEmpty
        ? widget.genderOptions
        : const ['Male', 'Female', 'Transgender'];
    final cells = <Widget>[
      text('Name', _suretyNameCtrl, 'Full name'),
      text('Age', _suretyAgeCtrl, 'e.g. 45', keyboard: TextInputType.number),
      dropdown('Gender', _suretyGender, genders, 'Select gender',
          (v) => _suretyGender = v),
      text('Occupation', _suretyOccCtrl, 'Occupation'),
      text('Mobile', _suretyMobileCtrl, '10-digit number',
          keyboard: TextInputType.phone),
      text('Aadhaar', _suretyAadhaarCtrl, 'XXXX XXXX XXXX',
          keyboard: TextInputType.number),
      text('PAN', _suretyPanCtrl, 'ABCDE1234F',
          caps: TextCapitalization.characters),
      dropdown('Relation with accused', _suretyRelation, widget.relationChoices,
          'Select relation', (v) => _suretyRelation = v),
      text('Address', _suretyAddressCtrl, 'Residential address'),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.navyMid.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.verified_user_outlined,
                    size: 16, color: AppColors.navyMid),
              ),
              const SizedBox(width: 8),
              Text(
                'Surety details',
                style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, c) {
            final perLine = c.maxWidth >= 600 ? 3 : (c.maxWidth >= 380 ? 2 : 1);
            final rows = <Widget>[];
            for (var i = 0; i < cells.length; i += perLine) {
              rows.add(Padding(
                padding: EdgeInsets.only(
                    bottom: i + perLine < cells.length ? 10 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var j = 0; j < perLine; j++) ...[
                      if (j > 0) const SizedBox(width: 12),
                      Expanded(
                        child: i + j < cells.length
                            ? cells[i + j]
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ));
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rows,
            );
          }),
        ],
      ),
    );
  }

  /// PCR, MCR and the fields MCR reveals.
  Widget _inlineForm() => Padding(
        padding: EdgeInsets.all(widget.bare ? 0 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: [leading cells] PCR Days & MCR Toggle
            Row(
              children: [
                for (final cell in widget.leadingCells) ...[
                  Expanded(child: cell),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: TextFormField(
                    controller: _pcrDaysCtrl,
                    readOnly: widget.readOnly,
                    keyboardType: TextInputType.number,
                    // Optional; when filled, whole days up to 3 digits
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return null;
                      return RegExp(r'^\d{1,3}$').hasMatch(t)
                          ? null
                          : 'Enter up to 3 digits';
                    },
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: AppColors.navyDark),
                    decoration: _fieldDeco('PCR (00 Day)', 'e.g. 7'),
                    onChanged: (_) => _notifyChange(),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color:
                            _isMcr ? AppColors.navyMid : AppColors.lightBorder,
                        width: _isMcr ? 1.5 : 1.0,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: CheckboxListTile(
                        value: _isMcr,
                        activeColor: AppColors.navyMid,
                        title: Text(
                          'MCR',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navyDark,
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: widget.readOnly
                            ? null
                            : (val) {
                                setState(() {
                                  _isMcr = val ?? false;
                                  if (!_isMcr) {
                                    _isPrBond = false;
                                    _isJail = false;
                                    _isBail = false;
                                  }
                                });
                                _notifyChange();
                              },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (widget.belowFirstRow != null) widget.belowFirstRow!,

            // MCR Options
            if (_isMcr) ...[
              const SizedBox(height: 12),
              Text(
                'MCR OPTIONS',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),

              // PR Bond | Jail | Bail on one line (one can be
              // picked); the picked one's date or surety details
              // open below the line
              Row(
                children: [
                  Expanded(
                    child: _custodyOptionBox(
                      _isPrBond,
                      Material(
                        color: Colors.transparent,
                        child: RadioListTile<String>(
                          value: 'PR_BOND',
                          groupValue: _isPrBond
                              ? 'PR_BOND'
                              : (_isJail ? 'JAIL' : (_isBail ? 'BAIL' : null)),
                          activeColor: AppColors.navyMid,
                          title: Text(
                            'PR Bond',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navyDark),
                          ),
                          onChanged: widget.readOnly
                              ? null
                              : (v) {
                                  setState(() {
                                    final next = !_isPrBond;
                                    _isPrBond = next;
                                    if (next) {
                                      _isJail = false;
                                      _isBail = false;
                                      if (_prBondDateCtrl.text.isEmpty) {
                                        _prBondDateCtrl.text =
                                            DateFormat('dd/MM/yyyy')
                                                .format(DateTime.now());
                                      }
                                    } else {
                                      _prBondDateCtrl.clear();
                                    }
                                  });
                                  _notifyChange();
                                },
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                          contentPadding:
                              const EdgeInsets.only(left: 4, right: 8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _custodyOptionBox(
                      _isJail,
                      Material(
                        color: Colors.transparent,
                        child: RadioListTile<String>(
                          value: 'JAIL',
                          groupValue: _isPrBond
                              ? 'PR_BOND'
                              : (_isJail ? 'JAIL' : (_isBail ? 'BAIL' : null)),
                          activeColor: AppColors.navyMid,
                          title: Text(
                            'Jail',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navyDark),
                          ),
                          onChanged: widget.readOnly
                              ? null
                              : (v) {
                                  setState(() {
                                    final next = !_isJail;
                                    _isJail = next;
                                    if (next) {
                                      _isPrBond = false;
                                      _isBail = false;
                                      if (_jailDateCtrl.text.isEmpty) {
                                        _jailDateCtrl.text =
                                            DateFormat('dd/MM/yyyy')
                                                .format(DateTime.now());
                                      }
                                    } else {
                                      _jailDateCtrl.clear();
                                    }
                                  });
                                  _notifyChange();
                                },
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                          contentPadding:
                              const EdgeInsets.only(left: 4, right: 8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _custodyOptionBox(
                      _isBail,
                      Material(
                        color: Colors.transparent,
                        child: RadioListTile<String>(
                          value: 'BAIL',
                          groupValue: _isPrBond
                              ? 'PR_BOND'
                              : (_isJail ? 'JAIL' : (_isBail ? 'BAIL' : null)),
                          activeColor: AppColors.navyMid,
                          title: Text(
                            'Bail',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navyDark),
                          ),
                          onChanged: widget.readOnly
                              ? null
                              : (v) {
                                  setState(() {
                                    final next = !_isBail;
                                    _isBail = next;
                                    if (next) {
                                      _isPrBond = false;
                                      _isJail = false;
                                    }
                                  });
                                  _notifyChange();
                                },
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                          contentPadding:
                              const EdgeInsets.only(left: 4, right: 8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_isPrBond)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: InkWell(
                    onTap: widget.readOnly
                        ? null
                        : () => _pickDate(_prBondDateCtrl),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: IgnorePointer(
                      child: TextFormField(
                        controller: _prBondDateCtrl,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.navyDark),
                        decoration: _fieldDeco('Date (dd/mm/yyyy)').copyWith(
                          suffixIcon: const Icon(Icons.calendar_month_rounded,
                              size: 18, color: AppColors.navyMid),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_isJail)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: InkWell(
                    onTap:
                        widget.readOnly ? null : () => _pickDate(_jailDateCtrl),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: IgnorePointer(
                      child: TextFormField(
                        controller: _jailDateCtrl,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.navyDark),
                        decoration: _fieldDeco('Date (dd/mm/yyyy)').copyWith(
                          suffixIcon: const Icon(Icons.calendar_month_rounded,
                              size: 18, color: AppColors.navyMid),
                        ),
                      ),
                    ),
                  ),
                ),
              if (_isBail) _buildSuretyCard(),
            ],
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (widget.bare) return _inlineForm();
    final statusSummary = _getStatusSummary();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: widget.isExpanded
              ? AppColors.navyMid.withValues(alpha: 0.4)
              : AppColors.lightBorder,
          width: widget.isExpanded ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          InkWell(
            onTap: widget.onToggleExpand,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.navyMid.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded,
                        size: 16, color: AppColors.navyMid),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.personName,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ),
                  if (statusSummary != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Text(
                        statusSummary,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (widget.isCustom &&
                      !widget.readOnly &&
                      widget.onRemovePerson != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.dangerRed, size: 20),
                      tooltip: 'Remove Person',
                      splashRadius: 18,
                      onPressed: widget.onRemovePerson,
                    ),
                  Icon(
                    widget.isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.navyMid,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          // Inline Form
          if (widget.isExpanded) ...[
            const Divider(height: 1, color: AppColors.lightBorder),
            _inlineForm(),
          ],
        ],
      ),
    );
  }
}

/// One numbered sub-step of the common form (e.g. 1.2 Acts & Sections).
class _SubStep {
  final String title;

  /// Section names shown in it (to jump here when one has an error).
  final List<String> keys;
  final Widget card;

  const _SubStep({required this.title, required this.keys, required this.card});
}

enum _SubStatus { done, error, none }

/// Fields per line on a PC person card: four on a wide card, three on a
/// medium one, two otherwise.
int _personPerLine(double width) => width >= 900
    ? 4
    : width >= 700
        ? 3
        : 2;

/// One person card line of fields, each taking [MapEntry.value] grid slots,
/// 16px apart like [_personFieldRows].
Widget _personFlexRow(List<MapEntry<Widget, int>> cells) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < cells.length; i++) ...[
        if (i > 0) const SizedBox(width: 16),
        Expanded(flex: cells[i].value, child: cells[i].key),
      ],
    ],
  );
}

/// Person card fields in rows of [perLine], 12px apart; a short last row
/// keeps its empty slots so the columns stay aligned.
List<Widget> _personFieldRows(List<Widget> cells, int perLine) {
  final rows = <Widget>[];
  for (var i = 0; i < cells.length; i += perLine) {
    rows.add(Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var j = 0; j < perLine; j++) ...[
            if (j > 0) const SizedBox(width: 16),
            Expanded(
              child:
                  i + j < cells.length ? cells[i + j] : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    ));
  }
  return rows;
}
