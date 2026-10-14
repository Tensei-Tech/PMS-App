// ignore_for_file: deprecated_member_use
// lib/widgets/dynamic_form/dynamic_form_screen.dart
// Single Source of Truth Dynamic Smart Form Screen driven by PostgreSQL Database.

import 'dart:async';
import 'package:flutter/material.dart';
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
import 'dynamic_control_factory.dart';
import 'dynamic_field_model.dart';
import 'dynamic_section_builder.dart';
import '../repeating_cascading_charges_selector.dart';

class DynamicFormScreen extends StatefulWidget {
  final dynamic categoryId;
  final String moduleLabel;
  final String moduleKey;
  final String? subCategory;
  final ModuleRecord? existingRecord;
  final bool readOnly;

  const DynamicFormScreen({
    super.key,
    this.categoryId,
    required this.moduleLabel,
    required this.moduleKey,
    this.subCategory,
    this.existingRecord,
    this.readOnly = false,
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

  // Controllers & Values keyed by fieldKey
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _values = {};

  // Accordion state: in Edit mode, single section open at a time.
  // In View / Read-Only mode, all sections start expanded so the entire case record is immediately visible.
  String? _expandedSectionKey;
  final Set<String> _collapsedReadOnlySections = {};
  bool _readOnlyAllCollapsed = false;
  bool _isHydrated = false;
  bool _isGeneratingPdf = false;

  bool _isSectionExpanded(String sectionKey) {
    if (widget.readOnly) {
      if (_readOnlyAllCollapsed) return false;
      return !_collapsedReadOnlySections.contains(sectionKey);
    }
    return _expandedSectionKey == sectionKey;
  }

  void _toggleSection(String sectionKey) {
    setState(() {
      if (widget.readOnly) {
        if (_readOnlyAllCollapsed) {
          _readOnlyAllCollapsed = false;
          _collapsedReadOnlySections.clear();
        }
        if (_collapsedReadOnlySections.contains(sectionKey)) {
          _collapsedReadOnlySections.remove(sectionKey);
        } else {
          _collapsedReadOnlySections.add(sectionKey);
        }
      } else {
        if (_expandedSectionKey == sectionKey) {
          _expandedSectionKey = null; // Collapse if tapped again
        } else {
          _expandedSectionKey =
              sectionKey; // Open this section, auto-collapse all others
        }
      }
    });
  }

  bool get _chargesSectionExpanded =>
      _isSectionExpanded('Acts & Sections Filed');
  bool get _accusedSectionExpanded => _isSectionExpanded('Accused');
  bool get _suspectedAccusedSectionExpanded =>
      _isSectionExpanded('Suspected Accused');
  bool get _unidentifiedAccusedSectionExpanded =>
      _isSectionExpanded('Unidentified Accused');
  bool get _unknownAccusedSectionExpanded =>
      _isSectionExpanded('Unknown Accused');
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

  // Arrest state
  final List<Map<String, dynamic>> _arrestRecordsList = [];

  // Discharged Accused state
  String? _selectedAccusedToDischarge;
  final List<String> _dischargedAccusedList = [];
  final Map<String, bool> _dischargedAccusedMap = {};
  final Map<String, TextEditingController> _dischargeDateControllers = {};

  // Preventive Action state
  String _selectedPreventiveType =
      DynamicControlFactory.preventiveActionChoices.first;
  final TextEditingController _preventiveDateCtrl = TextEditingController();
  final TextEditingController _preventiveOutwardCtrl = TextEditingController();
  final TextEditingController _preventiveBondDateCtrl = TextEditingController();
  final TextEditingController _preventiveBondCancelDateCtrl =
      TextEditingController();
  final List<Map<String, dynamic>> _preventiveActionsList = [];
  final Set<String> _customPreventivePersons = {};

  // Remand & Custody state
  String? _selectedCustodyAccused;
  final TextEditingController _pcrDaysCtrl = TextEditingController();
  String? _custodyType; // 'PCR' or 'MCR' (mutually exclusive)
  bool _isMcr = false;
  bool _isPrBond = false;
  final TextEditingController _prBondDateCtrl = TextEditingController();
  bool _isBail = false;
  final TextEditingController _suretyNameCtrl = TextEditingController();
  final TextEditingController _suretyAgeCtrl = TextEditingController();
  String _suretyGender = 'Male';
  final TextEditingController _suretyOccCtrl = TextEditingController();
  final TextEditingController _suretyMobileCtrl = TextEditingController();
  final TextEditingController _suretyAadhaarCtrl = TextEditingController();
  final TextEditingController _suretyPanCtrl = TextEditingController();
  final TextEditingController _suretyAddressCtrl = TextEditingController();
  String _suretyRelation = 'Father';
  bool _isJail = false;
  final TextEditingController _jailDateCtrl = TextEditingController();
  final List<Map<String, dynamic>> _custodyRecordsList = [];

  static const List<String> _suretyRelationChoices = [
    'Father',
    'Mother',
    'Brother',
    'Sister',
    'Spouse',
    'Son',
    'Daughter',
    'Uncle',
    'Aunt',
    'Friend',
    'Relative',
    'Neighbour',
    'Employer',
    'Colleague',
    'Advocate',
    'Other',
  ];

  final bool _hideEmptyInViewMode = true;
  List<String> _designationOptions = [];

  bool get isEdit => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    _loadFormDefinition();
    _loadDesignations();
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
            _controllers.putIfAbsent(f.fieldKey, () => TextEditingController());
            if (f.fieldType == 'checkbox') {
              _values.putIfAbsent(f.fieldKey, () => false);
            }
          }
        });

        // If editing or existing record, hydrate fields once
        debugPrint('[DFS] isEdit=$isEdit, _isHydrated=$_isHydrated');
        if (isEdit && !_isHydrated) {
          debugPrint('[DFS] Calling _hydrateFromExistingRecord...');
          _hydrateFromExistingRecord();
          _isHydrated = true;
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
    final r = widget.existingRecord!;
    final extra = r.extraFields;
    debugPrint(
        '[DFS] _hydrateFromExistingRecord: extraFields keys=${extra.keys.toList()}');
    debugPrint(
        '[DFS] extraFields sample: caseNumber=${r.caseNumber}, title=${r.title}, accused=${r.accused}');
    final common =
        (extra['commonForm'] is Map) ? extra['commonForm'] as Map : {};
    debugPrint('[DFS] commonForm keys=${common.keys.toList()}');

    // Standard root fields mapping
    _setField('cr_number', r.caseNumber);
    _setField('crNo', r.caseNumber);
    _setField('case_number', r.caseNumber);
    _setField('caseNumber', r.caseNumber);
    _setField('title', r.title);
    _setField('brief_description', r.description);
    _setField('description', r.description);
    _setField('complainant_name', r.complainant);
    final safeAccused = _sanitizeName(r.accused);
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
                  : 'Male',
              'occupation':
                  (item['occupation'] ?? item['occ'])?.toString() ?? '',
              'mobile': item['mobile']?.toString() ?? '',
              'aadhaar': item['aadhaar']?.toString() ?? '',
              'pan': item['pan']?.toString() ?? '',
              'religion': item['religion']?.toString() ?? '',
              'caste': item['caste']?.toString() ?? '',
              'address': item['address']?.toString() ?? '',
              'role': 'accused',
            });
          }
        } else if (item is String && item.trim().isNotEmpty) {
          _accusedList.add({
            'name': item.trim(),
            'gender': 'Male',
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
                  : 'Male',
              'occupation': (p['occupation'] ?? p['occ'])?.toString() ?? '',
              'mobile': p['mobile']?.toString() ?? '',
              'aadhaar': p['aadhaar']?.toString() ?? '',
              'pan': p['pan']?.toString() ?? '',
              'religion': p['religion']?.toString() ?? '',
              'caste': p['caste']?.toString() ?? '',
              'address': p['address']?.toString() ?? '',
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
          'gender': _values['accused_gender'] ?? 'Male',
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
              'gender':
                  (it['gender'] ?? it['suspected_accused_gender'] ?? 'Male')
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
            'gender': 'Male',
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
              'gender': (p['gender'] ?? 'Male').toString(),
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
                  'Male')
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
            'gender': (it['gender'] ?? 'Male').toString(),
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
              'gender': (p['gender'] ?? 'Male').toString(),
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
                  'Male')
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
    final procList = common['procedural_checklists'] ??
        extra['procedural_checklists'] ??
        r.extraFields['procedural_checklists'];
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
          'action_date': prevDate?.toString() ??
              DateFormat('dd/MM/yyyy').format(DateTime.now()),
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
                (it['surety_gender'] ?? it['suretyGender'] ?? 'Male')
                    .toString();
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
                    'Father')
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
                  (rc['surety_gender'] ?? rc['suretyGender'] ?? 'Male')
                      .toString(),
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
                      'Father')
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
          (common['surety_gender'] ?? extra['surety_gender'] ?? 'Male')
              .toString();
      final suretyOcc =
          common['surety_occupation'] ?? extra['surety_occupation'] ?? '';
      final suretyMob = common['surety_mobile'] ?? extra['surety_mobile'] ?? '';
      final suretyAadhaar =
          common['surety_aadhaar'] ?? extra['surety_aadhaar'] ?? '';
      final suretyPan = common['surety_pan'] ?? extra['surety_pan'] ?? '';
      final suretyAddr =
          common['surety_address'] ?? extra['surety_address'] ?? '';
      final suretyRel =
          (common['surety_relation'] ?? extra['surety_relation'] ?? 'Father')
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
    if (val is List || val is Map) {
      _values[key] = val;
      return;
    }
    final rawTrimmed = val.toString().trim();
    if (rawTrimmed.startsWith('[{') ||
        rawTrimmed.startsWith('{') ||
        rawTrimmed.contains('name:') ||
        rawTrimmed == 'null' ||
        rawTrimmed == '[]') {
      return;
    }
    final strVal = val.toString();
    if (_controllers.containsKey(key)) {
      if (strVal.trim().isNotEmpty || _controllers[key]!.text.trim().isEmpty) {
        _controllers[key]!.text = strVal;
      }
    } else {
      if (strVal.trim().isNotEmpty) {
        _controllers[key] = TextEditingController(text: strVal);
      }
    }
    if (strVal.trim().isNotEmpty || !_values.containsKey(key)) {
      _values[key] = val;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill all required fields.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final caseNo = _controllers['cr_number']?.text.trim() ??
        _controllers['crNo']?.text.trim() ??
        _controllers['case_number']?.text.trim() ??
        (isEdit
            ? widget.existingRecord!.caseNumber
            : 'CR/${DateTime.now().millisecondsSinceEpoch}');

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
            'Male',
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

    // Compile dynamic extra fields values
    final dynamicExtraVals = <String, dynamic>{};
    for (final f in _formDef?.fields ?? <DynamicFieldDef>[]) {
      if (f.fieldSource == 'custom') {
        dynamicExtraVals[f.fieldKey] =
            _controllers[f.fieldKey]?.text ?? _values[f.fieldKey];
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
              'Male',
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
      final identMark = _controllers['identification_mark']?.text.trim() ?? '';
      final desc = _controllers['description']?.text.trim() ?? '';
      if (approxAge.isNotEmpty ||
          skinCol.isNotEmpty ||
          identMark.isNotEmpty ||
          desc.isNotEmpty) {
        finalUnidentifiedList.add({
          'approximate_age': approxAge,
          'gender': _values['unidentified_gender'] ??
              _controllers['unidentified_gender']?.text.trim() ??
              'Male',
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
        final effectiveDate = actDate.isNotEmpty
            ? actDate
            : DateFormat('dd/MM/yyyy').format(DateTime.now());
        prevActionsToSubmit.add({
          'name': name,
          'accusedName': name,
          'person_name': name,
          'existing_person_id': item['existing_person_id'] ?? item['person_id'],
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
      final prevOutward = _controllers['preventive_outward_no']?.text.trim() ??
          _values['preventive_outward_no']?.toString().trim() ??
          '';
      if (prevType.isNotEmpty) {
        final effectiveDate = prevDate.isNotEmpty
            ? prevDate
            : DateFormat('dd/MM/yyyy').format(DateTime.now());
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
      'sdpo_acp_grant_date': _controllers['sdpo_acp_grant_date']?.text.trim() ??
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

    // Build commonForm document map for full backward compatibility
    final commonFormDoc = <String, dynamic>{
      'crNo': caseNo,
      'charges': chargesMap,
      'spotAddress': loc,
      'complainant': {'name': complainant},
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
      'preventive_actions': prevActionsToSubmit,
      'preventive_action_items': prevActionsToSubmit,
      'custody_records': custodyToSubmit,
      'remand_custody': custodyToSubmit,
      'custodyInfo': custodyToSubmit,
      'dynamic_extra_fields': dynamicExtraVals,
      ...allFormFields,
    };

    final extraFields = Map<String, dynamic>.from(
      widget.existingRecord?.extraFields ?? {},
    );
    extraFields.addAll(allFormFields);
    extraFields['commonForm'] = commonFormDoc;
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
    extraFields['preventive_actions'] = prevActionsToSubmit;
    extraFields['preventive_action_items'] = prevActionsToSubmit;
    extraFields['is_discharged'] = _dischargedAccusedList.isNotEmpty;
    extraFields['lastEditedBy'] = auth.displayName;
    extraFields['lastEditedAt'] = DateTime.now().toIso8601String();

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
      stationName:
          auth.stationName.isNotEmpty ? auth.stationName : 'Default Station',
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
        throw Exception('Backend returned failure status.');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save case: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.dangerRed,
        ),
      );
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

  void _onDynamicFieldValueChanged(String k, dynamic v) {
    setState(() {
      _values[k] = v;
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
        if (curDate.isEmpty) {
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

  Widget _buildBody() {
    if (_isLoading) {
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
    if (fields.isEmpty) {
      return const Center(
          child: Text('No fields configured in database for this category.'));
    }

    final customFields =
        fields.where((f) => f.fieldSource == 'custom').toList();

    // Group common fields by their exact database-defined section
    final Map<String, List<DynamicFieldDef>> groupedBySection = {};
    for (final f in fields) {
      if (f.fieldSource == 'custom') continue;
      var sec = f.section ?? 'Crime Registration Info';
      if (f.fieldKey == 'is_unknown_accused') {
        sec = 'Unknown Accused';
      }
      if (sec == 'Case Responsibility' || sec == 'Responsibility') {
        sec = 'Officer';
      }
      groupedBySection.putIfAbsent(sec, () => []).add(f);
    }

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
      'CCTV and CDR Investigation',
      'All Panchnama',
      'Evidence',
      'Seizure Records',
      'Preventive Action',
      'Discharge Accused',
      'Scrutiny',
      'Court Filing and Final Summary',
    ];

    final accusedOptions = _getAvailableAccusedNames();
    int sectionCounter = 1;
    final sectionCards = <Widget>[];

    for (final secKey in orderedSectionKeys) {
      if (secKey == 'Acts & Sections Filed') {
        final idx = sectionCounter++;
        sectionCards.add(_buildLegalChargesSection(sectionIndex: idx));
      } else if (secKey == 'Special Section / Template Details') {
        if (customFields.isNotEmpty) {
          final idx = sectionCounter++;
          sectionCards.add(
            DynamicSectionCard(
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
            ),
          );
        }
      } else if (secKey == 'Remand & Custody') {
        final idx = sectionCounter++;
        sectionCards.add(_buildRemandCustodySection(sectionIndex: idx));
      } else if (secKey == 'Preventive Action') {
        final idx = sectionCounter++;
        sectionCards.add(_buildPreventiveActionSection(sectionIndex: idx));
      } else if (secKey == 'Discharge Accused') {
        final idx = sectionCounter++;
        sectionCards.add(_buildDischargeAccusedSection(sectionIndex: idx));
      } else if (secKey == 'Accused') {
        final idx = sectionCounter++;
        sectionCards.add(_buildAccusedSection(sectionIndex: idx));
      } else if (secKey == 'Suspected Accused') {
        final idx = sectionCounter++;
        sectionCards.add(_buildSuspectedAccusedSection(sectionIndex: idx));
      } else if (secKey == 'Unidentified Accused') {
        final idx = sectionCounter++;
        sectionCards.add(_buildUnidentifiedAccusedSection(sectionIndex: idx));
      } else if (secKey == 'Unknown Accused') {
        final idx = sectionCounter++;
        sectionCards.add(_buildUnknownAccusedSection(sectionIndex: idx));
      } else if (secKey == 'Arrest') {
        final idx = sectionCounter++;
        sectionCards.add(_buildArrestSection(sectionIndex: idx));
      } else if (secKey == 'Scrutiny') {
        final idx = sectionCounter++;
        sectionCards.add(_buildScrutinySection(sectionIndex: idx));
      } else {
        final secFields = groupedBySection[secKey];
        if (secFields != null && secFields.isNotEmpty) {
          final idx = sectionCounter++;
          final displayTitle = secKey == 'Officer'
              ? 'Case Responsibility (Officer)'
              : (secKey == 'Court Filing and Final Summary'
                  ? 'Court Filing & Final Summary'
                  : secKey);
          sectionCards.add(
            DynamicSectionCard(
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
            ),
          );
        }
      }
    }

    // Append any extra/unmapped sections from DB that were not in standard list
    for (final entry in groupedBySection.entries) {
      if (!orderedSectionKeys.contains(entry.key) && entry.value.isNotEmpty) {
        final lower = entry.key.toLowerCase();
        if (lower.contains('remand') ||
            lower.contains('custody') ||
            lower.contains('scrutiny') ||
            lower == 'bond') {
          continue;
        }
        final idx = sectionCounter++;
        sectionCards.add(
          DynamicSectionCard(
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
          ),
        );
      }
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 600;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 10.0 : AppSpacing.md,
              vertical: isCompact ? 12.0 : AppSpacing.lg,
            ),
            children: [
              ...sectionCards,
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
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg)),
                        ),
                        icon: const Icon(Icons.check_circle_rounded,
                            color: Colors.white),
                        label: Text(
                          isEdit ? 'Update Case Record' : 'Submit',
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

  EdgeInsets _responsiveCardMargin(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    return EdgeInsets.only(bottom: isCompact ? 10.0 : 14.0);
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
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    return EdgeInsets.symmetric(
      horizontal: isCompact ? 12 : 16,
      vertical: isCompact ? 11 : 14,
    );
  }

  EdgeInsets _responsiveBodyPadding(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 600;
    return EdgeInsets.all(isCompact ? 12.0 : 16.0);
  }

  Widget _buildSectionIndexBadge(int? sectionIndex, [IconData? fallbackIcon]) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.navyMid.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: sectionIndex != null
          ? Text(
              '$sectionIndex',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            )
          : Icon(fallbackIcon ?? Icons.article_outlined,
              size: 20, color: AppColors.navyMid),
    );
  }

  Widget _buildLegalChargesSection({int? sectionIndex}) {
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

    return Container(
      key: const ValueKey('sec_Acts & Sections Filed'),
      margin: _responsiveCardMargin(context),
      decoration: BoxDecoration(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _toggleSection('Acts & Sections Filed'),
            borderRadius:
                _responsiveHeaderBorderRadius(context, _chargesSectionExpanded),
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
                  Tooltip(
                    message: _chargesSectionExpanded ? 'Collapse' : 'Expand',
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

  Widget _buildDischargeAccusedSection({int? sectionIndex}) {
    final availableAccused = _getAvailableAccusedNames();

    return Container(
      margin: _responsiveCardMargin(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _responsiveCardRadius(context),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                  Tooltip(
                    message: _dischargeSectionExpanded ? 'Collapse' : 'Expand',
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
      _values['accused_gender'] = first['gender']?.toString() ?? 'Male';
      _controllers['accused_gender']?.text =
          first['gender']?.toString() ?? 'Male';
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

  Widget _buildAccusedSection({int? sectionIndex}) {
    return Container(
      margin: _responsiveCardMargin(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _responsiveCardRadius(context),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          InkWell(
            onTap: () => _toggleSection('Accused'),
            borderRadius:
                _responsiveHeaderBorderRadius(context, _accusedSectionExpanded),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_accusedList.length} accused',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyMid,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: _accusedSectionExpanded ? 'Collapse' : 'Expand',
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
                const Divider(height: 1, color: AppColors.lightBorder),
                Padding(
                  padding: _responsiveBodyPadding(context),
                  child: Column(
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
                              if (!widget.readOnly)
                                OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _accusedList
                                          .add({'name': '', 'gender': 'Male'});
                                      _syncPrimaryAccusedControllers();
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.navyMid,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.md)),
                                    side: const BorderSide(
                                        color: AppColors.navyMid),
                                  ),
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: Text(
                                    'Add Accused',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                            ],
                          ),
                        )
                      else ...[
                        ..._accusedList.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          return _InlinePersonCard(
                            key: ObjectKey(item),
                            index: idx,
                            roleTitle: 'Accused',
                            data: item,
                            readOnly: widget.readOnly,
                            canRemove: !widget.readOnly,
                            onRemove: () {
                              setState(() {
                                _accusedList.removeAt(idx);
                                _syncPrimaryAccusedControllers();
                              });
                            },
                            onChanged: () {
                              if (idx == 0) {
                                _syncPrimaryAccusedControllers();
                              }
                            },
                          );
                        }),
                        if (!widget.readOnly) ...[
                          const SizedBox(height: 4),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _accusedList
                                    .add({'name': '', 'gender': 'Male'});
                                _syncPrimaryAccusedControllers();
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.navyMid,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md)),
                              side: const BorderSide(color: AppColors.navyMid),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(
                              'Add Another Accused',
                              style: GoogleFonts.poppins(
                                  fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
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
      _values['suspected_accused_gender'] =
          first['gender']?.toString() ?? 'Male';
      _controllers['suspected_accused_gender']?.text =
          first['gender']?.toString() ?? 'Male';
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

  Widget _buildSuspectedAccusedSection({int? sectionIndex}) {
    return Container(
      margin: _responsiveCardMargin(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _responsiveCardRadius(context),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          InkWell(
            onTap: () => _toggleSection('Suspected Accused'),
            borderRadius: _responsiveHeaderBorderRadius(
                context, _suspectedAccusedSectionExpanded),
            child: Padding(
              padding: _responsiveHeaderPadding(context),
              child: Row(
                children: [
                  _buildSectionIndexBadge(
                      sectionIndex, Icons.person_search_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Suspected Accused',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_suspectedAccusedList.length} suspected',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyMid,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: _suspectedAccusedSectionExpanded
                        ? 'Collapse'
                        : 'Expand',
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: AnimatedRotation(
                        turns: _suspectedAccusedSectionExpanded ? 0.5 : 0.0,
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
                const Divider(height: 1, color: AppColors.lightBorder),
                Padding(
                  padding: _responsiveBodyPadding(context),
                  child: Column(
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
                              if (!widget.readOnly)
                                OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _suspectedAccusedList
                                          .add({'name': '', 'gender': 'Male'});
                                      _syncPrimarySuspectedAccusedControllers();
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.navyMid,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.md)),
                                    side: const BorderSide(
                                        color: AppColors.navyMid),
                                  ),
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: Text(
                                    'Add Suspected Accused',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                            ],
                          ),
                        )
                      else ...[
                        ..._suspectedAccusedList.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          return _InlinePersonCard(
                            key: ObjectKey(item),
                            index: idx,
                            roleTitle: 'Suspect',
                            data: item,
                            readOnly: widget.readOnly,
                            canRemove: !widget.readOnly,
                            onRemove: () {
                              setState(() {
                                _suspectedAccusedList.removeAt(idx);
                                _syncPrimarySuspectedAccusedControllers();
                              });
                            },
                            onChanged: () {
                              if (idx == 0) {
                                _syncPrimarySuspectedAccusedControllers();
                              }
                            },
                          );
                        }),
                        if (!widget.readOnly) ...[
                          const SizedBox(height: 4),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _suspectedAccusedList
                                    .add({'name': '', 'gender': 'Male'});
                                _syncPrimarySuspectedAccusedControllers();
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.navyMid,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md)),
                              side: const BorderSide(color: AppColors.navyMid),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(
                              'Add Another Suspected Accused',
                              style: GoogleFonts.poppins(
                                  fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: _suspectedAccusedSectionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOutCubic,
          ),
        ],
      ),
    );
  }

  // ── Unidentified Accused Section & Helpers ───────────────────────────
  void _syncPrimaryUnidentifiedControllers() {
    if (_unidentifiedAccusedList.isNotEmpty) {
      final first = _unidentifiedAccusedList.first;
      _controllers['approximate_age']?.text =
          first['approximate_age']?.toString() ?? '';
      _values['unidentified_gender'] = first['gender']?.toString() ?? 'Male';
      _controllers['unidentified_gender']?.text =
          first['gender']?.toString() ?? 'Male';
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

  Widget _buildUnidentifiedAccusedSection({int? sectionIndex}) {
    return Container(
      margin: _responsiveCardMargin(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _responsiveCardRadius(context),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          InkWell(
            onTap: () => _toggleSection('Unidentified Accused'),
            borderRadius: _responsiveHeaderBorderRadius(
                context, _unidentifiedAccusedSectionExpanded),
            child: Padding(
              padding: _responsiveHeaderPadding(context),
              child: Row(
                children: [
                  _buildSectionIndexBadge(
                      sectionIndex, Icons.fingerprint_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Unidentified Accused',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_unidentifiedAccusedList.length} unidentified',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyMid,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: _unidentifiedAccusedSectionExpanded
                        ? 'Collapse'
                        : 'Expand',
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: AnimatedRotation(
                        turns: _unidentifiedAccusedSectionExpanded ? 0.5 : 0.0,
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
                const Divider(height: 1, color: AppColors.lightBorder),
                Padding(
                  padding: _responsiveBodyPadding(context),
                  child: Column(
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
                              if (!widget.readOnly)
                                OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _unidentifiedAccusedList.add({
                                        'approximate_age': '',
                                        'gender': 'Male'
                                      });
                                      _syncPrimaryUnidentifiedControllers();
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.navyMid,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.md)),
                                    side: const BorderSide(
                                        color: AppColors.navyMid),
                                  ),
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: Text(
                                    'Add Unidentified Accused',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                            ],
                          ),
                        )
                      else ...[
                        ..._unidentifiedAccusedList
                            .asMap()
                            .entries
                            .map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          return _InlineUnidentifiedAccusedCard(
                            key: ObjectKey(item),
                            index: idx,
                            data: item,
                            readOnly: widget.readOnly,
                            canRemove: !widget.readOnly,
                            onRemove: () {
                              setState(() {
                                _unidentifiedAccusedList.removeAt(idx);
                                _syncPrimaryUnidentifiedControllers();
                              });
                            },
                            onChanged: () {
                              if (idx == 0) {
                                _syncPrimaryUnidentifiedControllers();
                              }
                            },
                          );
                        }),
                        if (!widget.readOnly) ...[
                          const SizedBox(height: 4),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _unidentifiedAccusedList.add(
                                    {'approximate_age': '', 'gender': 'Male'});
                                _syncPrimaryUnidentifiedControllers();
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.navyMid,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md)),
                              side: const BorderSide(color: AppColors.navyMid),
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: Text(
                              'Add Another Unidentified Accused',
                              style: GoogleFonts.poppins(
                                  fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: _unidentifiedAccusedSectionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOutCubic,
          ),
        ],
      ),
    );
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

  Widget _buildArrestSection({int? sectionIndex}) {
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

    return Container(
      margin: _responsiveCardMargin(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _responsiveCardRadius(context),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          InkWell(
            onTap: () => _toggleSection('Arrest'),
            borderRadius:
                _responsiveHeaderBorderRadius(context, _arrestSectionExpanded),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        ...allDisplayNames.map((name) {
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
                                                      final relRelationField =
                                                          TextFormField(
                                                        key: ValueKey(
                                                            'rel_rel_$name'),
                                                        initialValue: record[
                                                                    'relative_friend_relation']
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
                                                              'Relation with Accused',
                                                          hintText:
                                                              'e.g. Brother / Father',
                                                          prefixIcon: const Icon(
                                                              Icons
                                                                  .family_restroom_rounded,
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
                                                          record['relative_friend_relation'] =
                                                              val.trim();
                                                          _syncPrimaryArrestControllers();
                                                        },
                                                      );

                                                      if (isWide) {
                                                        return Row(
                                                          children: [
                                                            Expanded(
                                                                child:
                                                                    relNameField),
                                                            const SizedBox(
                                                                width: 12),
                                                            Expanded(
                                                                child:
                                                                    relRelationField),
                                                          ],
                                                        );
                                                      } else {
                                                        return Column(
                                                          children: [
                                                            relNameField,
                                                            const SizedBox(
                                                                height: 10),
                                                            relRelationField,
                                                          ],
                                                        );
                                                      }
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
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.md),
                                            border: Border.all(
                                              color:
                                                  record['release_on_notice'] ==
                                                          true
                                                      ? const Color(0xFFD97706)
                                                      : AppColors.lightBorder,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              CheckboxListTile(
                                                value: record[
                                                        'release_on_notice'] ==
                                                    true,
                                                activeColor:
                                                    const Color(0xFFD97706),
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
                                                        color: const Color(
                                                            0xFFFEF3C7),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    AppRadius
                                                                        .md),
                                                        border: Border.all(
                                                            color: const Color(
                                                                0xFFFCD34D)),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                              Icons
                                                                  .access_time_rounded,
                                                              size: 16,
                                                              color: Color(
                                                                  0xFFD97706)),
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
                                                                color: const Color(
                                                                    0xFF92400E),
                                                              ),
                                                            ),
                                                          ),
                                                          const Icon(
                                                              Icons
                                                                  .calendar_month_rounded,
                                                              size: 16,
                                                              color: Color(
                                                                  0xFFD97706)),
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
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.md),
                                            border: Border.all(
                                              color:
                                                  record['anticipatory_bail'] ==
                                                          true
                                                      ? const Color(0xFF9333EA)
                                                      : AppColors.lightBorder,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              CheckboxListTile(
                                                value: record[
                                                        'anticipatory_bail'] ==
                                                    true,
                                                activeColor:
                                                    const Color(0xFF9333EA),
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
                                                        color: const Color(
                                                            0xFFF3E8FF),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    AppRadius
                                                                        .md),
                                                        border: Border.all(
                                                            color: const Color(
                                                                0xFFD8B4FE)),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                              Icons
                                                                  .access_time_rounded,
                                                              size: 16,
                                                              color: Color(
                                                                  0xFF9333EA)),
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
                                                                color: const Color(
                                                                    0xFF6B21A8),
                                                              ),
                                                            ),
                                                          ),
                                                          const Icon(
                                                              Icons
                                                                  .calendar_month_rounded,
                                                              size: 16,
                                                              color: Color(
                                                                  0xFF9333EA)),
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
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.md),
                                            border: Border.all(
                                              color:
                                                  record['death_of_accused'] ==
                                                          true
                                                      ? AppColors.dangerRed
                                                      : AppColors.lightBorder,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              CheckboxListTile(
                                                value: record[
                                                        'death_of_accused'] ==
                                                    true,
                                                activeColor:
                                                    AppColors.dangerRed,
                                                title: Text(
                                                  'Death of Accused',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.dangerRed,
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
                                                        color: const Color(
                                                            0xFFFEE2E2),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                                    AppRadius
                                                                        .md),
                                                        border: Border.all(
                                                            color: const Color(
                                                                0xFFFCA5A5)),
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          const Icon(
                                                              Icons
                                                                  .access_time_rounded,
                                                              size: 16,
                                                              color: AppColors
                                                                  .dangerRed),
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
                                                                color: const Color(
                                                                    0xFF991B1B),
                                                              ),
                                                            ),
                                                          ),
                                                          const Icon(
                                                              Icons
                                                                  .calendar_month_rounded,
                                                              size: 16,
                                                              color: AppColors
                                                                  .dangerRed),
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
  Widget _buildUnknownAccusedSection({int? sectionIndex}) {
    return Container(
      margin: _responsiveCardMargin(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _responsiveCardRadius(context),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          InkWell(
            onTap: () => _toggleSection('Unknown Accused'),
            borderRadius: _responsiveHeaderBorderRadius(
                context, _unknownAccusedSectionExpanded),
            child: Padding(
              padding: _responsiveHeaderPadding(context),
              child: Row(
                children: [
                  _buildSectionIndexBadge(
                      sectionIndex, Icons.help_outline_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Unknown Accused',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_unknownAccusedList.length} unknown accused',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyMid,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message:
                        _unknownAccusedSectionExpanded ? 'Collapse' : 'Expand',
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: AnimatedRotation(
                        turns: _unknownAccusedSectionExpanded ? 0.5 : 0.0,
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
                const Divider(height: 1, color: AppColors.lightBorder),
                Padding(
                  padding: _responsiveBodyPadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_unknownAccusedList.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No unknown accused added yet. Click "+ Add Unknown Accused" below to record unknown accused persons.',
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
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
                                    color: AppColors.navyMid
                                        .withValues(alpha: 0.1),
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
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: AppColors.dangerRed),
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
                      if (!widget.readOnly) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _unknownAccusedList.add({
                                'name':
                                    'Unknown Accused #${_unknownAccusedList.length + 1}',
                                'role': 'unknown_accused',
                              });
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.navyMid,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            side: const BorderSide(color: AppColors.navyMid),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: Text(
                            'Add Unknown Accused',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: _unknownAccusedSectionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOutCubic,
          ),
        ],
      ),
    );
  }

  // ── Preventive Action for Multiple Accused Section ────────────────────────
  Widget _buildPreventiveActionSection({int? sectionIndex}) {
    final availableAccused = _getAvailableAccusedNames();
    final allPeople = <String>{
      ...availableAccused,
      ..._customPreventivePersons,
      for (final it in _preventiveActionsList)
        if ((it['name'] ?? it['person_name'])?.toString().trim().isNotEmpty ==
            true)
          (it['name'] ?? it['person_name']).toString().trim(),
    }.toList();

    const defaultChoices = [
      '107 CrPC / 126 BNSS',
      '109 CrPC / 128 BNSS',
      '110 CrPC / 129 BNSS',
      '110(e) CrPC / 129(e) BNSS',
      '110(g) CrPC / 129(g) BNSS',
      '144 CrPC / 163 BNSS',
      '149 CrPC / 168 BNSS',
      '151(1) CrPC / 170(1) BNSS',
      '151(3) CrPC / 170(3) BNSS',
      '55 MPA (Externment)',
      '56 MPA (Externment)',
      '57 MPA (Externment)',
      '122 MPA',
      '124 MPA',
      'MPDA (Dangerous Person)',
      '93 Prohibition Act',
      'MCOCA (Section 3)',
      'Other',
    ];

    final choices = (_formDef != null && _formDef!.preventiveItems.isNotEmpty)
        ? _formDef!.preventiveItems
        : defaultChoices;

    return Container(
      key: const ValueKey('sec_Preventive Action'),
      margin: _responsiveCardMargin(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _responsiveCardRadius(context),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with Toggle
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
                      'Preventive Action',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDark,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                  Tooltip(
                    message: _preventiveSectionExpanded ? 'Collapse' : 'Expand',
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

  Future<void> _pickDateForController(
      BuildContext context, TextEditingController ctrl) async {
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
      ctrl.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  // ── Remand & Custody for Multiple Accused Section ──────────────────────────
  Widget _buildRemandCustodySection({int? sectionIndex}) {
    final availableAccused = _getAvailableAccusedNames();

    // Ensure selected accused is a valid option in the dropdown
    final dropdownItems = <String>{...availableAccused};
    if (_selectedCustodyAccused != null &&
        _selectedCustodyAccused!.isNotEmpty) {
      dropdownItems.add(_selectedCustodyAccused!);
    }

    return Container(
      margin: _responsiveCardMargin(context),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _responsiveCardRadius(context),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with Toggle
          InkWell(
            onTap: () => _toggleSection('Remand & Custody'),
            borderRadius:
                _responsiveHeaderBorderRadius(context, _custodySectionExpanded),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _custodyRecordsList.isNotEmpty
                          ? AppColors.navyMid.withValues(alpha: 0.12)
                          : AppColors.navyMid.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _custodyRecordsList.isNotEmpty
                          ? '${_custodyRecordsList.length} recorded'
                          : '${availableAccused.length} accused',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyMid,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: _custodySectionExpanded ? 'Collapse' : 'Expand',
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
                const Divider(height: 1, color: AppColors.lightBorder),
                Padding(
                  padding: _responsiveBodyPadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dropdown to select accused or arrested person
                      if (!widget.readOnly) ...[
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Select Accused / Arrested Person',
                            labelStyle: GoogleFonts.poppins(
                                fontSize: 12, color: AppColors.lightSubText),
                            prefixIcon: const Icon(Icons.person_search_rounded,
                                size: 20, color: AppColors.navyMid),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              borderSide: const BorderSide(
                                  color: AppColors.lightBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              borderSide: const BorderSide(
                                  color: AppColors.lightBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              borderSide: const BorderSide(
                                  color: AppColors.navyMid, width: 1.5),
                            ),
                          ),
                          hint: Text(
                            availableAccused.isEmpty
                                ? 'No accused entered yet — or click "+ Type other..."'
                                : 'Choose an accused or arrested person...',
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: AppColors.lightSubText),
                          ),
                          key: ValueKey(_selectedCustodyAccused),
                          initialValue: _selectedCustodyAccused,
                          isExpanded: true,
                          items: [
                            ...dropdownItems
                                .map((name) => DropdownMenuItem<String>(
                                      value: name,
                                      child: Row(
                                        children: [
                                          const Icon(
                                              Icons.person_outline_rounded,
                                              size: 16,
                                              color: AppColors.navyMid),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.navyDark,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                            const DropdownMenuItem<String>(
                              value: '__custom__',
                              child: Text(
                                '+ Type other accused / arrested person name...',
                                style: TextStyle(
                                  color: AppColors.navyMid,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                          onChanged: _onCustodyAccusedSelected,
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Form controls when an accused is selected
                      if (_selectedCustodyAccused != null &&
                          _selectedCustodyAccused!.isNotEmpty &&
                          !widget.readOnly) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                                color:
                                    AppColors.navyMid.withValues(alpha: 0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header banner showing selected accused
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.navyMid
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.lock_clock_rounded,
                                        size: 16, color: AppColors.navyMid),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: AppColors.navyDark),
                                        children: [
                                          const TextSpan(
                                              text: 'Remand & Custody for: '),
                                          TextSpan(
                                            text: _selectedCustodyAccused!,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.navyMid,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => setState(
                                        () => _selectedCustodyAccused = null),
                                    icon: const Icon(Icons.close_rounded,
                                        size: 18,
                                        color: AppColors.lightSubText),
                                    tooltip: 'Cancel selection',
                                    splashRadius: 16,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // 1. PCR / MCR Mutually Exclusive Radio Selector
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _custodyType = (_custodyType == 'PCR'
                                              ? null
                                              : 'PCR');
                                          _isMcr = false;
                                          _isPrBond = false;
                                          _isBail = false;
                                          _isJail = false;
                                        });
                                      },
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: _custodyType == 'PCR'
                                              ? AppColors.navyMid
                                                  .withValues(alpha: 0.08)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.md),
                                          border: Border.all(
                                            color: _custodyType == 'PCR'
                                                ? AppColors.navyMid
                                                : AppColors.lightBorder,
                                            width:
                                                _custodyType == 'PCR' ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Radio<String>(
                                              value: 'PCR',
                                              groupValue: _custodyType,
                                              activeColor: AppColors.navyMid,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              visualDensity:
                                                  VisualDensity.compact,
                                              onChanged: (val) {
                                                setState(() {
                                                  _custodyType = val;
                                                  _isMcr = false;
                                                  _isPrBond = false;
                                                  _isBail = false;
                                                  _isJail = false;
                                                });
                                              },
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'PCR',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: _custodyType ==
                                                              'PCR'
                                                          ? AppColors.navyMid
                                                          : AppColors.navyDark,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Police Custody Remand',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 10,
                                                      color: AppColors
                                                          .lightSubText,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _custodyType = (_custodyType == 'MCR'
                                              ? null
                                              : 'MCR');
                                          _isMcr = (_custodyType == 'MCR');
                                          _pcrDaysCtrl.clear();
                                        });
                                      },
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: _custodyType == 'MCR'
                                              ? AppColors.navyMid
                                                  .withValues(alpha: 0.08)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.md),
                                          border: Border.all(
                                            color: _custodyType == 'MCR'
                                                ? AppColors.navyMid
                                                : AppColors.lightBorder,
                                            width:
                                                _custodyType == 'MCR' ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Radio<String>(
                                              value: 'MCR',
                                              groupValue: _custodyType,
                                              activeColor: AppColors.navyMid,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                              visualDensity:
                                                  VisualDensity.compact,
                                              onChanged: (val) {
                                                setState(() {
                                                  _custodyType = val;
                                                  _isMcr = true;
                                                  _pcrDaysCtrl.clear();
                                                });
                                              },
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'MCR',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: _custodyType ==
                                                              'MCR'
                                                          ? AppColors.navyMid
                                                          : AppColors.navyDark,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Magisterial Custody Remand',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 10,
                                                      color: AppColors
                                                          .lightSubText,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // 2. PCR Days Input (visible only when PCR is chosen)
                              if (_custodyType == 'PCR') ...[
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _pcrDaysCtrl,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.navyDark,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'PCR Days',
                                    hintText: 'e.g. 3, 7, 14',
                                    labelStyle: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppColors.lightSubText),
                                    prefixIcon: const Icon(Icons.timer_outlined,
                                        size: 20, color: AppColors.navyMid),
                                    filled: true,
                                    fillColor: Colors.white,
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
                                ),
                              ],

                              // 3. MCR Sub-options: PR Bond, Jail, Bail (Mutually Exclusive Radio Options)
                              if (_custodyType == 'MCR') ...[
                                const SizedBox(height: 14),
                                Text(
                                  'MCR Status / Outcome (Select One)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.navyDark,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // PR Bond Option (Radio)
                                Builder(
                                  builder: (context) {
                                    final selectedMcr = _isPrBond
                                        ? 'PR_BOND'
                                        : (_isJail
                                            ? 'JAIL'
                                            : (_isBail ? 'BAIL' : null));
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: _isPrBond
                                            ? AppColors.navyMid
                                                .withValues(alpha: 0.04)
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.md),
                                        border: Border.all(
                                          color: _isPrBond
                                              ? AppColors.navyMid
                                              : AppColors.lightBorder,
                                          width: _isPrBond ? 1.5 : 1.0,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Material(
                                            color: Colors.transparent,
                                            child: RadioListTile<String>(
                                              value: 'PR_BOND',
                                              groupValue: selectedMcr,
                                              activeColor: AppColors.navyMid,
                                              title: Text(
                                                'PR Bond',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.navyDark,
                                                ),
                                              ),
                                              onChanged: (v) {
                                                setState(() {
                                                  _isPrBond = true;
                                                  _isJail = false;
                                                  _isBail = false;
                                                  if (_prBondDateCtrl
                                                      .text.isEmpty) {
                                                    _prBondDateCtrl.text =
                                                        DateFormat('dd/MM/yyyy')
                                                            .format(
                                                                DateTime.now());
                                                  }
                                                });
                                              },
                                              controlAffinity:
                                                  ListTileControlAffinity
                                                      .leading,
                                            ),
                                          ),
                                          if (_isPrBond)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      14, 0, 14, 14),
                                              child: _buildCustodyDatePicker(
                                                context: context,
                                                controller: _prBondDateCtrl,
                                                label: 'PR Bond Date',
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Jail Option (Radio)
                                Builder(
                                  builder: (context) {
                                    final selectedMcr = _isPrBond
                                        ? 'PR_BOND'
                                        : (_isJail
                                            ? 'JAIL'
                                            : (_isBail ? 'BAIL' : null));
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: _isJail
                                            ? AppColors.navyMid
                                                .withValues(alpha: 0.04)
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.md),
                                        border: Border.all(
                                          color: _isJail
                                              ? AppColors.navyMid
                                              : AppColors.lightBorder,
                                          width: _isJail ? 1.5 : 1.0,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Material(
                                            color: Colors.transparent,
                                            child: RadioListTile<String>(
                                              value: 'JAIL',
                                              groupValue: selectedMcr,
                                              activeColor: AppColors.navyMid,
                                              title: Text(
                                                'Jail',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.navyDark,
                                                ),
                                              ),
                                              onChanged: (v) {
                                                setState(() {
                                                  _isPrBond = false;
                                                  _isJail = true;
                                                  _isBail = false;
                                                  if (_jailDateCtrl
                                                      .text.isEmpty) {
                                                    _jailDateCtrl.text =
                                                        DateFormat('dd/MM/yyyy')
                                                            .format(
                                                                DateTime.now());
                                                  }
                                                });
                                              },
                                              controlAffinity:
                                                  ListTileControlAffinity
                                                      .leading,
                                            ),
                                          ),
                                          if (_isJail)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      14, 0, 14, 14),
                                              child: _buildCustodyDatePicker(
                                                context: context,
                                                controller: _jailDateCtrl,
                                                label: 'Jail Date',
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Bail Option with Collapsible Surety Card (exact design from user screenshot)
                                _buildBailOptionCard(),
                              ],

                              const SizedBox(height: 16),

                              // Save / Update Custody Button
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _saveCustodyRecord,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.navyMid,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.md)),
                                      elevation: 0,
                                    ),
                                    icon: const Icon(Icons.check_circle_rounded,
                                        size: 18, color: Colors.white),
                                    label: Text(
                                      _custodyRecordsList.any((r) =>
                                              r['name'] ==
                                              _selectedCustodyAccused)
                                          ? 'Update Custody Record'
                                          : 'Save Custody Record',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedCustodyAccused = null;
                                        _clearCustodyFormFields();
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.md)),
                                      side: const BorderSide(
                                          color: AppColors.lightBorder),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: AppColors.lightSubText,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Placeholder when no accused is currently selected
                      if ((_selectedCustodyAccused == null ||
                              _selectedCustodyAccused!.isEmpty) &&
                          !widget.readOnly) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                                color: AppColors.lightBorder,
                                style: BorderStyle.solid),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  size: 20, color: AppColors.navyMid),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Select an accused or arrested person from the dropdown above to open and configure PCR, MCR, Bail, Surety KYC, and Jail details.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.lightSubText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Display list of added custody items
                      if (_custodyRecordsList.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.playlist_add_check_rounded,
                                size: 18, color: AppColors.navyMid),
                            const SizedBox(width: 6),
                            Text(
                              'Recorded Remand & Custody (${_custodyRecordsList.length})',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _custodyRecordsList.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, idx) {
                            final it = _custodyRecordsList[idx];
                            final name =
                                it['name'] ?? it['person_name'] ?? 'Accused';
                            final pcr = it['pcr_days']?.toString() ?? '';
                            final isMcr = it['mcr'] == true;
                            final isPrBond = it['pr_bond'] == true;
                            final prBondDt =
                                it['pr_bond_date']?.toString() ?? '';
                            final isBail = it['bail'] == true;
                            final suretyNm =
                                it['surety_name']?.toString() ?? '';
                            final suretyRel =
                                it['surety_relation']?.toString() ?? '';
                            final suretyAge =
                                it['surety_age']?.toString() ?? '';
                            final suretyGender =
                                it['surety_gender']?.toString() ?? '';
                            final suretyMob =
                                it['surety_mobile']?.toString() ?? '';
                            final suretyAadhaar =
                                it['surety_aadhaar']?.toString() ?? '';
                            final suretyPan =
                                it['surety_pan']?.toString() ?? '';
                            final suretyAddr =
                                it['surety_address']?.toString() ?? '';
                            final isJail = it['jail'] == true;
                            final jailDt = it['jail_date']?.toString() ?? '';

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                border:
                                    Border.all(color: AppColors.lightBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: AppColors.navyMid
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.person_rounded,
                                            size: 18, color: AppColors.navyMid),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.navyDark,
                                          ),
                                        ),
                                      ),
                                      if (!widget.readOnly) ...[
                                        IconButton(
                                          icon: const Icon(Icons.edit_rounded,
                                              size: 18,
                                              color: AppColors.navyMid),
                                          tooltip: 'Edit record',
                                          splashRadius: 18,
                                          onPressed: () =>
                                              _editCustodyRecord(idx),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                              color: AppColors.dangerRed),
                                          tooltip: 'Remove',
                                          splashRadius: 18,
                                          onPressed: () =>
                                              _removeCustodyRecord(idx),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Status chips
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      if (pcr.isNotEmpty && pcr != '0')
                                        _buildStatusBadge(
                                          label: 'PCR: $pcr Days',
                                          color: const Color(0xFF0284C7),
                                          bgColor: const Color(0xFFE0F2FE),
                                        ),
                                      if (isMcr)
                                        _buildStatusBadge(
                                          label: 'MCR Active',
                                          color: const Color(0xFF4F46E5),
                                          bgColor: const Color(0xFFEEF2FF),
                                        ),
                                      if (isPrBond)
                                        _buildStatusBadge(
                                          label: prBondDt.isNotEmpty
                                              ? 'PR Bond ($prBondDt)'
                                              : 'PR Bond',
                                          color: const Color(0xFFD97706),
                                          bgColor: const Color(0xFFFEF3C7),
                                        ),
                                      if (isJail)
                                        _buildStatusBadge(
                                          label: jailDt.isNotEmpty
                                              ? 'Jail ($jailDt)'
                                              : 'Jail Remand',
                                          color: const Color(0xFFDC2626),
                                          bgColor: const Color(0xFFFEE2E2),
                                        ),
                                      if (isBail)
                                        _buildStatusBadge(
                                          label: suretyNm.isNotEmpty
                                              ? 'Bail: $suretyNm ($suretyRel)'
                                              : 'Bail Granted',
                                          color: const Color(0xFF059669),
                                          bgColor: const Color(0xFFD1FAE5),
                                        ),
                                    ],
                                  ),

                                  // If Bail details exist, show compact summary
                                  if (isBail && suretyNm.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.sm),
                                        border: Border.all(
                                            color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Surety KYC: $suretyNm ($suretyRel)${suretyAge.isNotEmpty ? ' · $suretyAge yrs' : ''}${suretyGender.isNotEmpty ? ' · $suretyGender' : ''}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.navyDark,
                                            ),
                                          ),
                                          if (suretyMob.isNotEmpty ||
                                              suretyAadhaar.isNotEmpty ||
                                              suretyPan.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              [
                                                if (suretyMob.isNotEmpty)
                                                  'Mob: $suretyMob',
                                                if (suretyAadhaar.isNotEmpty)
                                                  'Aadhaar: $suretyAadhaar',
                                                if (suretyPan.isNotEmpty)
                                                  'PAN: $suretyPan',
                                              ].join('  |  '),
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: AppColors.lightSubText,
                                              ),
                                            ),
                                          ],
                                          if (suretyAddr.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Address: $suretyAddr',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: AppColors.lightSubText,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
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

  Widget _buildBailOptionCard() {
    final selectedMcr =
        _isPrBond ? 'PR_BOND' : (_isJail ? 'JAIL' : (_isBail ? 'BAIL' : null));
    return Container(
      decoration: BoxDecoration(
        color:
            _isBail ? AppColors.navyMid.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: _isBail ? AppColors.navyMid : AppColors.lightBorder,
          width: _isBail ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: RadioListTile<String>(
              value: 'BAIL',
              groupValue: selectedMcr,
              activeColor: AppColors.navyMid,
              title: Text(
                'Bail',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyDark,
                ),
              ),
              onChanged: (v) {
                setState(() {
                  _isPrBond = false;
                  _isJail = false;
                  _isBail = true;
                  _isMcr = true;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),

          // Collapsible Surety KYC Fields (opens when Bail is clicked!)
          if (_isBail) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SURETY NAME',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Row 1: Surety Name
                    TextFormField(
                      controller: _suretyNameCtrl,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.navyDark),
                      decoration: _suretyInputDeco('Surety Name'),
                    ),
                    const SizedBox(height: 12),

                    // Row 2: Surety Age & Surety Gender
                    LayoutBuilder(
                      builder: (context, c) {
                        final isWide = c.maxWidth > 500;
                        final ageField = TextFormField(
                          controller: _suretyAgeCtrl,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: AppColors.navyDark),
                          decoration: _suretyInputDeco('Surety Age'),
                        );
                        final genderSelector = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Surety Gender',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: ['Male', 'Female', 'Other'].map((g) {
                                final isSelected = _suretyGender == g;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: InkWell(
                                    onTap: () =>
                                        setState(() => _suretyGender = g),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFE0F2FE)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF0EA5E9)
                                              : const Color(0xFFE2E8F0),
                                          width: isSelected ? 1.8 : 1.0,
                                        ),
                                      ),
                                      child: Text(
                                        g,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? const Color(0xFF0284C7)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        );

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: ageField),
                              const SizedBox(width: 14),
                              Expanded(child: genderSelector),
                            ],
                          );
                        } else {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ageField,
                              const SizedBox(height: 10),
                              genderSelector,
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Row 3: Surety Occupation & Surety Mobile No.
                    LayoutBuilder(
                      builder: (context, c) {
                        final isWide = c.maxWidth > 500;
                        final occField = TextFormField(
                          controller: _suretyOccCtrl,
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: AppColors.navyDark),
                          decoration: _suretyInputDeco('Surety Occupation'),
                        );
                        final mobField = TextFormField(
                          controller: _suretyMobileCtrl,
                          keyboardType: TextInputType.phone,
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: AppColors.navyDark),
                          decoration: _suretyInputDeco('Surety Mobile No.'),
                        );
                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(child: occField),
                              const SizedBox(width: 14),
                              Expanded(child: mobField),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              occField,
                              const SizedBox(height: 12),
                              mobField,
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Row 4: Surety Aadhaar No. & Surety PAN No.
                    LayoutBuilder(
                      builder: (context, c) {
                        final isWide = c.maxWidth > 500;
                        final aadhField = TextFormField(
                          controller: _suretyAadhaarCtrl,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: AppColors.navyDark),
                          decoration: _suretyInputDeco('Surety Aadhaar No.'),
                        );
                        final panField = TextFormField(
                          controller: _suretyPanCtrl,
                          textCapitalization: TextCapitalization.characters,
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: AppColors.navyDark),
                          decoration: _suretyInputDeco('Surety PAN No.'),
                        );
                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(child: aadhField),
                              const SizedBox(width: 14),
                              Expanded(child: panField),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              aadhField,
                              const SizedBox(height: 12),
                              panField,
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Row 5: Surety Address
                    TextFormField(
                      controller: _suretyAddressCtrl,
                      maxLines: 2,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.navyDark),
                      decoration: _suretyInputDeco('Surety Address'),
                    ),
                    const SizedBox(height: 12),

                    // Row 6: Relation with Accused
                    DropdownButtonFormField<String>(
                      initialValue:
                          _suretyRelationChoices.contains(_suretyRelation)
                              ? _suretyRelation
                              : null,
                      decoration: _suretyInputDeco('Relation with Accused'),
                      hint: Text(
                        'Relation with Accused',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: const Color(0xFF94A3B8)),
                      ),
                      isExpanded: true,
                      items: _suretyRelationChoices
                          .map((r) => DropdownMenuItem<String>(
                                value: r,
                                child: Text(r,
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: AppColors.navyDark)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _suretyRelation = val);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _suretyInputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: 13,
        color: const Color(0xFF94A3B8),
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
      ),
    );
  }

  Widget _buildCustodyDatePicker({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.navyDark,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.poppins(fontSize: 12, color: AppColors.lightSubText),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_month_rounded,
              size: 20, color: AppColors.navyMid),
          onPressed: () => _pickCustodyDate(context, controller),
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
          borderSide: const BorderSide(color: AppColors.navyMid, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildStatusBadge({
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _onCustodyAccusedSelected(String? selectedName) {
    if (selectedName == '__custom__') {
      _showAddCustomCustodyAccusedDialog();
    } else if (selectedName != null && selectedName.isNotEmpty) {
      setState(() {
        _selectedCustodyAccused = selectedName;
        _populateCustodyFormForAccused(selectedName);
      });
    }
  }

  void _populateCustodyFormForAccused(String name) {
    final existing = _custodyRecordsList.firstWhere(
      (it) =>
          (it['name'] ?? it['person_name'] ?? '').toString().toLowerCase() ==
          name.toLowerCase(),
      orElse: () => <String, dynamic>{},
    );

    if (existing.isNotEmpty) {
      _pcrDaysCtrl.text = existing['pcr_days']?.toString() ?? '';
      _isMcr = existing['mcr'] == true || existing['isMcr'] == true;
      if (_isMcr) {
        _custodyType = 'MCR';
      } else if (_pcrDaysCtrl.text.isNotEmpty && _pcrDaysCtrl.text != '0') {
        _custodyType = 'PCR';
      } else {
        _custodyType = null;
      }
      _isPrBond = existing['pr_bond'] == true || existing['isPrBond'] == true;
      _prBondDateCtrl.text = existing['pr_bond_date']?.toString() ?? '';
      _isBail = existing['bail'] == true || existing['isBail'] == true;
      _suretyNameCtrl.text = existing['surety_name']?.toString() ?? '';
      _suretyAgeCtrl.text = existing['surety_age']?.toString() ?? '';
      _suretyGender = existing['surety_gender']?.toString().isNotEmpty == true
          ? existing['surety_gender'].toString()
          : 'Male';
      _suretyOccCtrl.text = existing['surety_occupation']?.toString() ?? '';
      _suretyMobileCtrl.text = existing['surety_mobile']?.toString() ?? '';
      _suretyAadhaarCtrl.text = existing['surety_aadhaar']?.toString() ?? '';
      _suretyPanCtrl.text = existing['surety_pan']?.toString() ?? '';
      _suretyAddressCtrl.text = existing['surety_address']?.toString() ?? '';
      _suretyRelation =
          existing['surety_relation']?.toString().isNotEmpty == true
              ? existing['surety_relation'].toString()
              : 'Father';
      _isJail = existing['jail'] == true || existing['isJail'] == true;
      _jailDateCtrl.text = existing['jail_date']?.toString() ?? '';
    } else {
      _clearCustodyFormFields();
    }
  }

  void _clearCustodyFormFields() {
    _custodyType = null;
    _pcrDaysCtrl.clear();
    _isMcr = false;
    _isPrBond = false;
    _prBondDateCtrl.clear();
    _isBail = false;
    _suretyNameCtrl.clear();
    _suretyAgeCtrl.clear();
    _suretyGender = 'Male';
    _suretyOccCtrl.clear();
    _suretyMobileCtrl.clear();
    _suretyAadhaarCtrl.clear();
    _suretyPanCtrl.clear();
    _suretyAddressCtrl.clear();
    _suretyRelation = 'Father';
    _isJail = false;
    _jailDateCtrl.clear();
  }

  Future<void> _pickCustodyDate(
      BuildContext context, TextEditingController ctrl) async {
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
    }
  }

  void _saveCustodyRecord() {
    final accusedName = _selectedCustodyAccused?.trim() ?? '';
    if (accusedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an accused or arrested person first.'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    final pcrDays = _pcrDaysCtrl.text.trim();
    final prBondDate = _prBondDateCtrl.text.trim();
    final jailDate = _jailDateCtrl.text.trim();

    final record = <String, dynamic>{
      'name': accusedName,
      'person_name': accusedName,
      'accusedName': accusedName,
      'pcr_days': pcrDays,
      'pcrDays': pcrDays,
      'mcr': _isMcr,
      'isMcr': _isMcr,
      'pr_bond': _isPrBond,
      'isPrBond': _isPrBond,
      'pr_bond_date': _isPrBond ? prBondDate : '',
      'prBondDate': _isPrBond ? prBondDate : '',
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
      'jail_date': _isJail ? jailDate : '',
      'jailDate': _isJail ? jailDate : '',
    };

    setState(() {
      final existingIndex = _custodyRecordsList.indexWhere(
        (it) =>
            (it['name'] ?? it['person_name'] ?? '').toString().toLowerCase() ==
            accusedName.toLowerCase(),
      );

      if (existingIndex >= 0) {
        _custodyRecordsList[existingIndex] = record;
      } else {
        _custodyRecordsList.add(record);
      }

      // Sync top-level dynamic controllers/values if this is first record
      if (_custodyRecordsList.isNotEmpty) {
        final first = _custodyRecordsList.first;
        _controllers['pcr_days']?.text = first['pcr_days'] ?? '';
        _values['pcr_days'] = first['pcr_days'];
        _values['mcr'] = first['mcr'];
        _values['pr_bond'] = first['pr_bond'];
        _controllers['pr_bond_date']?.text = first['pr_bond_date'] ?? '';
        _values['pr_bond_date'] = first['pr_bond_date'];
        _values['bail'] = first['bail'];
        _controllers['surety_name']?.text = first['surety_name'] ?? '';
        _values['surety_name'] = first['surety_name'];
        _values['jail'] = first['jail'];
        _controllers['jail_date']?.text = first['jail_date'] ?? '';
        _values['jail_date'] = first['jail_date'];
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Remand & Custody record saved for $accusedName'),
        backgroundColor: AppColors.navyMid,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removeCustodyRecord(int index) {
    setState(() {
      final removed = _custodyRecordsList.removeAt(index);
      if (_selectedCustodyAccused == removed['name']) {
        _selectedCustodyAccused = null;
        _clearCustodyFormFields();
      }
      if (_custodyRecordsList.isNotEmpty) {
        final first = _custodyRecordsList.first;
        _controllers['pcr_days']?.text = first['pcr_days'] ?? '';
        _values['pcr_days'] = first['pcr_days'];
        _values['mcr'] = first['mcr'];
        _values['pr_bond'] = first['pr_bond'];
        _controllers['pr_bond_date']?.text = first['pr_bond_date'] ?? '';
        _values['pr_bond_date'] = first['pr_bond_date'];
        _values['bail'] = first['bail'];
        _controllers['surety_name']?.text = first['surety_name'] ?? '';
        _values['surety_name'] = first['surety_name'];
        _values['jail'] = first['jail'];
        _controllers['jail_date']?.text = first['jail_date'] ?? '';
        _values['jail_date'] = first['jail_date'];
      } else {
        _controllers['pcr_days']?.clear();
        _values.remove('pcr_days');
        _values.remove('mcr');
        _values.remove('pr_bond');
        _controllers['pr_bond_date']?.clear();
        _values.remove('pr_bond_date');
        _values.remove('bail');
        _controllers['surety_name']?.clear();
        _values.remove('surety_name');
        _values.remove('jail');
        _controllers['jail_date']?.clear();
        _values.remove('jail_date');
      }
    });
  }

  void _editCustodyRecord(int index) {
    final it = _custodyRecordsList[index];
    final name = it['name']?.toString() ?? '';
    setState(() {
      _selectedCustodyAccused = name;
      _populateCustodyFormForAccused(name);
      _expandedSectionKey = 'Remand & Custody';
    });
  }

  void _showAddCustomCustodyAccusedDialog() {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(
          'Add Accused / Arrested Person',
          style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.navyDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the name of the accused or arrested person for Remand & Custody:',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.lightSubText),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textCtrl,
              autofocus: true,
              style:
                  GoogleFonts.poppins(fontSize: 14, color: AppColors.navyDark),
              decoration: InputDecoration(
                hintText: 'e.g. Rahul Sharma',
                prefixIcon: const Icon(Icons.person_outline_rounded,
                    size: 20, color: AppColors.navyMid),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppColors.lightSubText)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = textCtrl.text.trim();
              if (val.isNotEmpty) {
                setState(() {
                  _selectedCustodyAccused = val;
                  _populateCustodyFormForAccused(val);
                });
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyMid),
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  String _getScrutinyVal(String key) {
    final ctrl = _controllers[key];
    if (ctrl != null && ctrl.text.trim().isNotEmpty) {
      return ctrl.text.trim();
    }
    return _values[key]?.toString().trim() ?? '';
  }

  Widget _buildScrutinySection({int? sectionIndex}) {
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _responsiveCardRadius(context),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDark.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                  Tooltip(
                    message: _scrutinySectionExpanded ? 'Collapse' : 'Expand',
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

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
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
            // Step Content Card
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  boxShadow: isEnabled
                      ? [
                          BoxShadow(
                            color: AppColors.navyDark.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Status Badge
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isEnabled
                                      ? AppColors.navyDark
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                              Text(
                                subtitle,
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  color: isEnabled
                                      ? AppColors.lightSubText
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: !isEnabled
                                ? const Color(0xFFE2E8F0)
                                : (hasDate
                                    ? const Color(0xFFE0F2FE)
                                    : AppColors.navyMid
                                        .withValues(alpha: 0.08)),
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
                                color: !isEnabled
                                    ? const Color(0xFF64748B)
                                    : AppColors.navyMid,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                !isEnabled
                                    ? 'Locked'
                                    : (hasDate ? 'Recorded' : 'Active'),
                                style: GoogleFonts.poppins(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: !isEnabled
                                      ? const Color(0xFF64748B)
                                      : AppColors.navyMid,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Date picker fields row
                    if (isCompact)
                      Column(
                        children: [
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
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _buildScrutinyDateField(
                              label: 'Send Date',
                              fieldKey: sendKey,
                              enabled: isEnabled,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildScrutinyDateField(
                              label: 'Grant Date',
                              fieldKey: grantKey,
                              enabled: isEnabled,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrutinyDateField({
    required String label,
    required String fieldKey,
    required bool enabled,
  }) {
    final ctrl = _controllers.putIfAbsent(fieldKey, () {
      final v = _values[fieldKey]?.toString() ?? '';
      return TextEditingController(text: v);
    });
    final val = ctrl.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: enabled ? AppColors.navyDark : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 3),
        InkWell(
          onTap: (enabled && !widget.readOnly)
              ? () async {
                  await _pickCustodyDate(context, ctrl);
                  _values[fieldKey] = ctrl.text.trim();
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
                    val.isNotEmpty ? val : (enabled ? 'Select Date' : 'Locked'),
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

  const _InlinePersonCard({
    super.key,
    required this.index,
    required this.roleTitle,
    required this.data,
    this.onRemove,
    this.onChanged,
    this.readOnly = false,
    this.canRemove = false,
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
  String _selectedGender = 'Male';
  bool _isCollapsed = false;

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
    _selectedGender = (g != null && g.isNotEmpty) ? g : 'Male';

    _nameCtrl.addListener(() => _sync('name', _nameCtrl.text));
    _ageCtrl.addListener(() => _sync('age', _ageCtrl.text));
    _occCtrl.addListener(() => _sync('occupation', _occCtrl.text));
    _mobileCtrl.addListener(() => _sync('mobile', _mobileCtrl.text));
    _aadhaarCtrl.addListener(() => _sync('aadhaar', _aadhaarCtrl.text));
    _panCtrl.addListener(() => _sync('pan', _panCtrl.text));
    _religionCtrl.addListener(() => _sync('religion', _religionCtrl.text));
    _casteCtrl.addListener(() => _sync('caste', _casteCtrl.text));
    _addressCtrl.addListener(() => _sync('address', _addressCtrl.text));
  }

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
    return _isCollapsed ? 'Tap to enter name' : '';
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
    TextInputType? keyboardType,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 280;
        final isMultiline = maxLines > 1;

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
              TextFormField(
                controller: controller,
                readOnly: widget.readOnly,
                maxLines: maxLines,
                keyboardType: keyboardType,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.lightText),
                decoration: _inputDeco(hint),
              ),
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
              child: TextFormField(
                controller: controller,
                readOnly: widget.readOnly,
                maxLines: maxLines,
                keyboardType: keyboardType,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.lightText),
                decoration: _inputDeco(hint),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGenderField() {
    final genders = ['Male', 'Female', 'Transgender', 'Other'];
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 280;
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
                initialValue: genders.contains(_selectedGender)
                    ? _selectedGender
                    : 'Male',
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
                initialValue: genders.contains(_selectedGender)
                    ? _selectedGender
                    : 'Male',
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isCollapsed = !_isCollapsed),
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
                        color: _isCollapsed
                            ? AppColors.navyDark
                            : AppColors.lightSubText,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                    _isCollapsed
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    color: AppColors.navyMid,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (!_isCollapsed) ...[
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 550;
                final nameFld = _buildField(
                  label: 'Name',
                  controller: _nameCtrl,
                  hint: 'Enter Name',
                  isRequired: true,
                );
                final ageFld = _buildField(
                  label: 'Age',
                  controller: _ageCtrl,
                  hint: 'Enter Age',
                  keyboardType: TextInputType.number,
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
                  hint: 'Enter Mobile Number',
                  keyboardType: TextInputType.phone,
                );
                final aadhaarFld = _buildField(
                  label: 'Aadhar Number',
                  controller: _aadhaarCtrl,
                  hint: 'Enter Aadhar Number',
                  keyboardType: TextInputType.number,
                );
                final panFld = _buildField(
                  label: 'PAN Number',
                  controller: _panCtrl,
                  hint: 'Enter PAN Number',
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
                  hint: 'Enter Address',
                  maxLines: 2,
                );

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
                      occFld,
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
                      addrFld,
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: nameFld),
                        const SizedBox(width: 16),
                        Expanded(child: ageFld),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: genderFld),
                        const SizedBox(width: 16),
                        Expanded(child: occFld),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: mobileFld),
                        const SizedBox(width: 16),
                        Expanded(child: aadhaarFld),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: panFld),
                        const SizedBox(width: 16),
                        Expanded(child: relFld),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: casteFld),
                        const SizedBox(width: 16),
                        const Expanded(child: SizedBox.shrink()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    addrFld,
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

  const _InlineUnidentifiedAccusedCard({
    super.key,
    required this.index,
    required this.data,
    this.onRemove,
    this.onChanged,
    this.readOnly = false,
    this.canRemove = false,
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
  String _selectedGender = 'Male';
  bool _isCollapsed = false;

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
    _selectedGender = (g != null && g.isNotEmpty) ? g : 'Male';

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
    if (parts.isEmpty) return _isCollapsed ? 'Tap to enter details' : '';
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
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.lightText),
          decoration: _inputDeco(hint),
        ),
      ],
    );
  }

  Widget _buildGenderField() {
    final genders = ['Male', 'Female', 'Transgender', 'Other'];
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
              genders.contains(_selectedGender) ? _selectedGender : 'Male',
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isCollapsed = !_isCollapsed),
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
                        color: _isCollapsed
                            ? AppColors.navyDark
                            : AppColors.lightSubText,
                      ),
                      overflow: TextOverflow.ellipsis,
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
                    _isCollapsed
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    color: AppColors.navyMid,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (!_isCollapsed) ...[
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 550;
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

                if (!isWide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ageFld,
                      const SizedBox(height: 12),
                      genderFld,
                      const SizedBox(height: 12),
                      skinFld,
                      const SizedBox(height: 12),
                      heightFld,
                      const SizedBox(height: 12),
                      occFld,
                      const SizedBox(height: 12),
                      markFld,
                      const SizedBox(height: 12),
                      descFld,
                      const SizedBox(height: 12),
                      addrFld,
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: ageFld),
                        const SizedBox(width: 16),
                        Expanded(child: genderFld),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: skinFld),
                        const SizedBox(width: 16),
                        Expanded(child: heightFld),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: occFld),
                        const SizedBox(width: 16),
                        Expanded(child: markFld),
                      ],
                    ),
                    const SizedBox(height: 12),
                    descFld,
                    const SizedBox(height: 12),
                    addrFld,
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
  String? _selectedSection;
  late TextEditingController _dateCtrl;
  late TextEditingController _outwardCtrl;
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
      _initFromAction(widget.initialAction);
    }
  }

  void _initFromAction(Map<String, dynamic>? action) {
    _selectedSection =
        (action?['action_type'] ?? action?['action'])?.toString();
    if (_selectedSection != null && _selectedSection!.isEmpty) {
      _selectedSection = null;
    }
    _dateCtrl = TextEditingController(
      text: (action?['action_date'] ?? action?['actionDate'])?.toString() ?? '',
    );
    _outwardCtrl = TextEditingController(
      text:
          (action?['outward_number'] ?? action?['outwardNumber'])?.toString() ??
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
    _bondDateCtrl.dispose();
    _bondCancelDateCtrl.dispose();
    super.dispose();
  }

  void _notifySave() {
    if (_selectedSection == null || _selectedSection!.isEmpty) return;
    widget.onSaveAction({
      'name': widget.personName,
      'person_name': widget.personName,
      'accusedName': widget.personName,
      'action_type': _selectedSection!,
      'action': _selectedSection!,
      'action_date': _dateCtrl.text.trim().isNotEmpty
          ? _dateCtrl.text.trim()
          : DateFormat('dd/MM/yyyy').format(DateTime.now()),
      'actionDate': _dateCtrl.text.trim().isNotEmpty
          ? _dateCtrl.text.trim()
          : DateFormat('dd/MM/yyyy').format(DateTime.now()),
      'outward_number': _outwardCtrl.text.trim(),
      'outwardNumber': _outwardCtrl.text.trim(),
      'bond_date': _bondDateCtrl.text.trim(),
      'bondDate': _bondDateCtrl.text.trim(),
      'bond_cancellation_date': _bondCancelDateCtrl.text.trim(),
      'bondCancellationDate': _bondCancelDateCtrl.text.trim(),
    });
  }

  void _handleRemove() {
    setState(() {
      _selectedSection = null;
      _dateCtrl.clear();
      _outwardCtrl.clear();
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
        if (_dateCtrl.text.trim().isEmpty) {
          _dateCtrl.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
        }
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

  Widget _buildDropdown() {
    final allChoices = List<String>.from(widget.choices);
    if (_selectedSection != null &&
        _selectedSection!.isNotEmpty &&
        !allChoices.contains(_selectedSection)) {
      allChoices.insert(0, _selectedSection!);
    }
    final currentVal =
        allChoices.contains(_selectedSection) ? _selectedSection : null;
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
      ],
      onChanged: widget.readOnly ? null : _onSectionChanged,
    );
  }

  Widget _buildDateField(String label, TextEditingController ctrl,
      {bool required = false}) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      onTap: widget.readOnly ? null : () => _pickDate(ctrl),
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.navyDark,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.poppins(fontSize: 12, color: AppColors.lightSubText),
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
          borderSide: const BorderSide(color: AppColors.navyMid, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildOutwardField() {
    return TextFormField(
      controller: _outwardCtrl,
      readOnly: widget.readOnly,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.navyDark,
      ),
      onChanged: (_) => _notifySave(),
      decoration: InputDecoration(
        labelText: 'Outward Number (Optional)',
        hintText: 'e.g. OUT/2026/102',
        labelStyle:
            GoogleFonts.poppins(fontSize: 12, color: AppColors.lightSubText),
        hintStyle:
            GoogleFonts.poppins(fontSize: 12, color: AppColors.lightSubText),
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
          borderSide: const BorderSide(color: AppColors.navyMid, width: 1.5),
        ),
      ),
    );
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
                                child: _buildDateField(
                                    'Action Date *', _dateCtrl,
                                    required: true)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildOutwardField()),
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
                          ],
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildDateField('Action Date *', _dateCtrl,
                            required: true),
                        const SizedBox(height: 12),
                        _buildOutwardField(),
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
