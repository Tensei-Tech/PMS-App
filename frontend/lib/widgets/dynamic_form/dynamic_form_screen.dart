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
import '../../theme/app_theme.dart';
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

  // Legal charges state for Trigger B (Act -> Set of Section numbers)
  final Map<String, Set<String>> _selectedCharges = {};
  Timer? _triggerBDebounce;

  // Multiple Accused state
  bool _accusedSectionExpanded = true;
  final List<Map<String, dynamic>> _accusedList = [];

  // Suspected Accused state
  bool _suspectedAccusedSectionExpanded = true;
  final List<Map<String, dynamic>> _suspectedAccusedList = [];

  // Unidentified Accused state
  bool _unidentifiedAccusedSectionExpanded = true;
  final List<Map<String, dynamic>> _unidentifiedAccusedList = [];

  // Arrest state
  bool _arrestSectionExpanded = true;
  final List<Map<String, dynamic>> _arrestRecordsList = [];

  // Discharged Accused state
  bool _dischargeSectionExpanded = true;
  String? _selectedAccusedToDischarge;
  final List<String> _dischargedAccusedList = [];
  final Map<String, bool> _dischargedAccusedMap = {};
  final Map<String, TextEditingController> _dischargeDateControllers = {};

  // Preventive Action state
  bool _preventiveSectionExpanded = true;
  String? _selectedPreventiveAccused;
  String _selectedPreventiveType =
      DynamicControlFactory.preventiveActionChoices.first;
  final TextEditingController _preventiveDateCtrl = TextEditingController();
  final TextEditingController _preventiveOutwardCtrl = TextEditingController();
  final TextEditingController _preventiveBondDateCtrl = TextEditingController();
  final TextEditingController _preventiveBondCancelDateCtrl =
      TextEditingController();
  final List<Map<String, dynamic>> _preventiveActionsList = [];
  final List<Map<String, dynamic>> _unknownAccusedList = [];

  // Remand & Custody state
  bool _custodySectionExpanded = true;
  String? _selectedCustodyAccused;
  final TextEditingController _pcrDaysCtrl = TextEditingController();
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

  bool get isEdit => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    _loadFormDefinition();
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
    try {
      final json = await _caseService.fetchFormDefinition(
        _targetCategoryParam,
        caseId: widget.existingRecord?.id,
        sections: chargedSections,
      );

      if (!mounted) return;

      if (json != null) {
        final def = DynamicFormDefinition.fromJson(json);
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
        if (isEdit && _selectedCharges.isEmpty) {
          _hydrateFromExistingRecord();
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
    final common =
        (extra['commonForm'] is Map) ? extra['commonForm'] as Map : {};

    // Standard root fields mapping
    _setField('cr_number', r.caseNumber);
    _setField('crNo', r.caseNumber);
    _setField('title', r.title);
    _setField('brief_description', r.description);
    _setField('complainant_name', r.complainant);
    _setField('accused_name', r.accused);
    _setField('crime_spot_address', r.location);
    _setField('spotAddress', r.location);

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
    if (_accusedList.isEmpty && r.accused.trim().isNotEmpty) {
      final names = r.accused
          .split(RegExp(r'[,;]'))
          .map((s) => s.trim())
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
    final chargesData = common['charges'] ?? extra['charges'];
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
          final aName = it['name'] ??
              it['person_name'] ??
              it['accusedName'] ??
              it['person'] ??
              widget.existingRecord?.accused ??
              '';
          if (aType != null && aType.toString().isNotEmpty) {
            _preventiveActionsList.add({
              'name': aName.toString(),
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

      if (prevType != null && prevType.toString().isNotEmpty) {
        _preventiveActionsList.add({
          'name': widget.existingRecord?.accused ?? '',
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
            final cName = it['name'] ??
                it['person_name'] ??
                it['accusedName'] ??
                it['accused_name'] ??
                it['person'] ??
                widget.existingRecord?.accused ??
                '';
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

      if (pcr != null || isMcr || isBail) {
        _custodyRecordsList.add({
          'name': widget.existingRecord?.accused ?? '',
          'person_name': widget.existingRecord?.accused ?? '',
          'accusedName': widget.existingRecord?.accused ?? '',
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
  }

  void _setField(String key, dynamic val) {
    if (val == null) return;
    if (_controllers.containsKey(key)) {
      _controllers[key]!.text = val.toString();
    }
    _values[key] = val;
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
        ? _accusedList.map((a) => a['name']).join(', ')
        : (_controllers['accused_name']?.text.trim() ??
            _controllers['accused']?.text.trim() ??
            '');

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
              isEdit
                  ? 'Edit ${widget.subCategory ?? widget.moduleLabel}'
                  : '${widget.subCategory ?? widget.moduleLabel} Registration',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navyDark,
              ),
            ),
            Text(
              widget.moduleLabel,
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
    final sectionCards = <Widget>[];

    for (final secKey in orderedSectionKeys) {
      if (secKey == 'Acts & Sections Filed') {
        sectionCards.add(_buildLegalChargesSection());
      } else if (secKey == 'Special Section / Template Details') {
        if (customFields.isNotEmpty) {
          sectionCards.add(
            DynamicSectionCard(
              title:
                  'Special Section / Template Details (${customFields.length})',
              icon: Icons.featured_play_list_rounded,
              fields: customFields,
              controllers: _controllers,
              values: _values,
              onValueChanged: _onDynamicFieldValueChanged,
              readOnly: widget.readOnly,
              accusedOptions: accusedOptions,
            ),
          );
        }
      } else if (secKey == 'Remand & Custody') {
        sectionCards.add(_buildRemandCustodySection());
      } else if (secKey == 'Preventive Action') {
        sectionCards.add(_buildPreventiveActionSection());
      } else if (secKey == 'Discharge Accused') {
        sectionCards.add(_buildDischargeAccusedSection());
      } else if (secKey == 'Accused') {
        sectionCards.add(_buildAccusedSection());
      } else if (secKey == 'Suspected Accused') {
        sectionCards.add(_buildSuspectedAccusedSection());
      } else if (secKey == 'Unidentified Accused') {
        sectionCards.add(_buildUnidentifiedAccusedSection());
      } else if (secKey == 'Unknown Accused') {
        sectionCards.add(_buildUnknownAccusedSection());
      } else if (secKey == 'Arrest') {
        sectionCards.add(_buildArrestSection());
      } else {
        final secFields = groupedBySection[secKey];
        if (secFields != null && secFields.isNotEmpty) {
          sectionCards.add(
            DynamicSectionCard(
              title: secKey,
              icon: _iconForSection(secKey),
              fields: secFields,
              controllers: _controllers,
              values: _values,
              onValueChanged: _onDynamicFieldValueChanged,
              readOnly: widget.readOnly,
              accusedOptions: accusedOptions,
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
            lower == 'bond') {
          continue;
        }
        sectionCards.add(
          DynamicSectionCard(
            title: entry.key,
            icon: _iconForSection(entry.key),
            fields: entry.value,
            controllers: _controllers,
            values: _values,
            onValueChanged: _onDynamicFieldValueChanged,
            readOnly: widget.readOnly,
            accusedOptions: accusedOptions,
          ),
        );
      }
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          ...sectionCards,
          const SizedBox(height: 20),

          // Submit Button
          if (!widget.readOnly)
            Container(
              height: 54,
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
                      borderRadius: BorderRadius.circular(AppRadius.lg)),
                ),
                icon:
                    const Icon(Icons.check_circle_rounded, color: Colors.white),
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
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLegalChargesSection() {
    List<dynamic>? initialCharges;
    if (widget.existingRecord != null) {
      final extra = widget.existingRecord!.extraFields;
      initialCharges = (extra['charges'] is List)
          ? extra['charges'] as List
          : ((extra['acts_sections'] is List)
              ? extra['acts_sections'] as List
              : ((extra['commonForm'] is Map)
                  ? (extra['commonForm'] as Map)['charges'] as List?
                  : null));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.navyMid.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.gavel_rounded,
                    size: 20, color: AppColors.navyMid),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Acts & Sections Filed',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.lightBorder),
          RepeatingCascadingChargesSelector(
            initialCharges: initialCharges,
            readOnly: widget.readOnly,
            onChargesChanged: (chargesList) {
              _values['charges'] = chargesList;
              _values['acts_sections'] = chargesList;
            },
            onSectionIdsChanged: (sectionIds) {
              _triggerBDebounce?.cancel();
              _triggerBDebounce = Timer(const Duration(milliseconds: 300), () {
                final allSections =
                    sectionIds.map((s) => s.toString()).toList();
                _loadFormDefinition(chargedSections: allSections);
              });
            },
          ),
        ],
      ),
    );
  }

  List<String> _getAvailableAccusedNames() {
    final names = <String>{};

    void addName(String? raw) {
      if (raw == null) return;
      final t = raw.trim();
      if (t.isEmpty) return;
      if (t.contains(',')) {
        for (final p in t.split(',')) {
          final s = p.trim();
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

  Widget _buildDischargeAccusedSection() {
    final availableAccused = _getAvailableAccusedNames();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
            onTap: () => setState(
                () => _dischargeSectionExpanded = !_dischargeSectionExpanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(AppRadius.lg),
              bottom:
                  Radius.circular(_dischargeSectionExpanded ? 0 : AppRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.navyMid.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_remove_rounded,
                        size: 20, color: AppColors.navyMid),
                  ),
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
                  const SizedBox(width: 8),
                  Icon(
                    _dischargeSectionExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.lightSubText,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_dischargeSectionExpanded) ...[
            const Divider(height: 1, color: AppColors.lightBorder),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
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
                                ? 'No accused entered yet in form'
                                : 'Choose an accused to discharge...',
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: AppColors.lightSubText),
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
                                  if (!_dischargedAccusedList.contains(name)) {
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
                      final dateCtrl = _dischargeDateControllers.putIfAbsent(
                        accName,
                        () => TextEditingController(
                          text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
                        ),
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
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
                                              color: const Color(0xFFFECACA)),
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
                                        _dischargedAccusedList.remove(accName);
                                        _dischargedAccusedMap[accName] = false;
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
                                  : () =>
                                      _pickDateForController(context, dateCtrl),
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

  void _showAddEditAccusedDialog({int? editIndex}) {
    final isEditing =
        editIndex != null && editIndex >= 0 && editIndex < _accusedList.length;
    final initial = isEditing ? _accusedList[editIndex] : <String, dynamic>{};

    final nameCtrl =
        TextEditingController(text: initial['name']?.toString() ?? '');
    final ageCtrl =
        TextEditingController(text: initial['age']?.toString() ?? '');
    var selectedGender = initial['gender']?.toString().isNotEmpty == true
        ? initial['gender'].toString()
        : 'Male';
    final occCtrl =
        TextEditingController(text: initial['occupation']?.toString() ?? '');
    final mobileCtrl =
        TextEditingController(text: initial['mobile']?.toString() ?? '');
    final aadhaarCtrl =
        TextEditingController(text: initial['aadhaar']?.toString() ?? '');
    final panCtrl =
        TextEditingController(text: initial['pan']?.toString() ?? '');
    final religionCtrl =
        TextEditingController(text: initial['religion']?.toString() ?? '');
    final casteCtrl =
        TextEditingController(text: initial['caste']?.toString() ?? '');
    final addressCtrl =
        TextEditingController(text: initial['address']?.toString() ?? '');

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg)),
            title: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.navyMid.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_pin_rounded,
                      size: 18, color: AppColors.navyMid),
                ),
                const SizedBox(width: 10),
                Text(
                  isEditing ? 'Edit Accused' : 'Add Accused',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDark,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name (Required)
                      TextFormField(
                        controller: nameCtrl,
                        autofocus: !isEditing,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.navyDark),
                        decoration: InputDecoration(
                          labelText: 'Accused Name *',
                          hintText: 'Enter full name...',
                          prefixIcon: const Icon(Icons.person_outline_rounded,
                              size: 18, color: AppColors.navyMid),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter accused name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Age & Gender Row
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: TextFormField(
                              controller: ageCtrl,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.navyDark),
                              decoration: InputDecoration(
                                labelText: 'Age',
                                hintText: 'Years',
                                prefixIcon: const Icon(Icons.cake_outlined,
                                    size: 18, color: AppColors.navyMid),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 6,
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedGender,
                              decoration: InputDecoration(
                                labelText: 'Gender',
                                prefixIcon: const Icon(Icons.wc_rounded,
                                    size: 18, color: AppColors.navyMid),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md)),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'Male', child: Text('Male')),
                                DropdownMenuItem(
                                    value: 'Female', child: Text('Female')),
                                DropdownMenuItem(
                                    value: 'Other', child: Text('Other')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDlgState(() => selectedGender = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Occupation & Mobile Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: occCtrl,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.navyDark),
                              decoration: InputDecoration(
                                labelText: 'Occupation',
                                hintText: 'e.g. Business / Driver',
                                prefixIcon: const Icon(
                                    Icons.work_outline_rounded,
                                    size: 18,
                                    color: AppColors.navyMid),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: mobileCtrl,
                              keyboardType: TextInputType.phone,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.navyDark),
                              decoration: InputDecoration(
                                labelText: 'Mobile Number',
                                hintText: '10 digits',
                                prefixIcon: const Icon(
                                    Icons.phone_iphone_rounded,
                                    size: 18,
                                    color: AppColors.navyMid),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Aadhaar & PAN Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: aadhaarCtrl,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.navyDark),
                              decoration: InputDecoration(
                                labelText: 'Aadhaar Number',
                                hintText: '12 digits',
                                prefixIcon: const Icon(
                                    Icons.credit_card_rounded,
                                    size: 18,
                                    color: AppColors.navyMid),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: panCtrl,
                              textCapitalization: TextCapitalization.characters,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.navyDark),
                              decoration: InputDecoration(
                                labelText: 'PAN Number',
                                hintText: '10 chars',
                                prefixIcon: const Icon(Icons.badge_outlined,
                                    size: 18, color: AppColors.navyMid),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Religion & Caste Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: religionCtrl,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.navyDark),
                              decoration: InputDecoration(
                                labelText: 'Religion',
                                prefixIcon: const Icon(
                                    Icons.account_balance_outlined,
                                    size: 18,
                                    color: AppColors.navyMid),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: casteCtrl,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.navyDark),
                              decoration: InputDecoration(
                                labelText: 'Caste',
                                prefixIcon: const Icon(
                                    Icons.people_outline_rounded,
                                    size: 18,
                                    color: AppColors.navyMid),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Address
                      TextFormField(
                        controller: addressCtrl,
                        maxLines: 2,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.navyDark),
                        decoration: InputDecoration(
                          labelText: 'Address',
                          hintText: 'Residential or last known address...',
                          prefixIcon: const Icon(Icons.home_outlined,
                              size: 18, color: AppColors.navyMid),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: GoogleFonts.poppins(color: AppColors.lightSubText)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    final item = {
                      'name': nameCtrl.text.trim(),
                      'age': ageCtrl.text.trim(),
                      'gender': selectedGender,
                      'occupation': occCtrl.text.trim(),
                      'mobile': mobileCtrl.text.trim(),
                      'aadhaar': aadhaarCtrl.text.trim(),
                      'pan': panCtrl.text.trim(),
                      'religion': religionCtrl.text.trim(),
                      'caste': casteCtrl.text.trim(),
                      'address': addressCtrl.text.trim(),
                      'role': 'accused',
                    };

                    setState(() {
                      if (isEditing) {
                        _accusedList[editIndex] = item;
                      } else {
                        _accusedList.add(item);
                      }
                      _syncPrimaryAccusedControllers();
                    });

                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyMid),
                child: Text(isEditing ? 'Save Changes' : 'Add Accused'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAccusedSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
            onTap: () => setState(
                () => _accusedSectionExpanded = !_accusedSectionExpanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(AppRadius.lg),
              bottom:
                  Radius.circular(_accusedSectionExpanded ? 0 : AppRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.navyMid.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_pin_rounded,
                        size: 20, color: AppColors.navyMid),
                  ),
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
                  const SizedBox(width: 8),
                  Icon(
                    _accusedSectionExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.lightSubText,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_accusedSectionExpanded) ...[
            const Divider(height: 1, color: AppColors.lightBorder),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_accusedList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No accused persons added yet. Click "+ Add Accused" below to record accused persons for this case.',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: AppColors.lightSubText,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    ..._accusedList.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      final name =
                          item['name']?.toString() ?? 'Accused #${idx + 1}';
                      final age = item['age']?.toString() ?? '';
                      final gender = item['gender']?.toString() ?? '';
                      final mobile = item['mobile']?.toString() ?? '';
                      final occ = item['occupation']?.toString() ?? '';
                      final address = item['address']?.toString() ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                  child: Center(
                                    child: Text(
                                      '${idx + 1}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.navyMid,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.navyDark,
                                    ),
                                  ),
                                ),
                                if (!widget.readOnly) ...[
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded,
                                        size: 18, color: AppColors.navyMid),
                                    onPressed: () => _showAddEditAccusedDialog(
                                        editIndex: idx),
                                    tooltip: 'Edit Accused',
                                    splashRadius: 16,
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: AppColors.dangerRed),
                                    onPressed: () {
                                      setState(() {
                                        _accusedList.removeAt(idx);
                                        _syncPrimaryAccusedControllers();
                                      });
                                    },
                                    tooltip: 'Remove',
                                    splashRadius: 16,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (age.isNotEmpty)
                                  _buildMiniTag(
                                      'Age: $age', Icons.cake_outlined),
                                if (gender.isNotEmpty)
                                  _buildMiniTag(gender, Icons.wc_rounded),
                                if (mobile.isNotEmpty)
                                  _buildMiniTag(
                                      mobile, Icons.phone_iphone_rounded),
                                if (occ.isNotEmpty)
                                  _buildMiniTag(
                                      occ, Icons.work_outline_rounded),
                                if (address.isNotEmpty)
                                  _buildMiniTag(
                                      address, Icons.location_on_outlined),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  if (!widget.readOnly) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _showAddEditAccusedDialog(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navyMid,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md)),
                        side: const BorderSide(color: AppColors.navyMid),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        _accusedList.isEmpty
                            ? 'Add Accused'
                            : 'Add Another Accused',
                        style: GoogleFonts.poppins(
                            fontSize: 12.5, fontWeight: FontWeight.w600),
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
  }

  Widget _buildMiniTag(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.navyMid),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: AppColors.navyDark,
              ),
            ),
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

  void _showAddEditSuspectedAccusedDialog({int? editIndex}) {
    final isEditing = editIndex != null &&
        editIndex >= 0 &&
        editIndex < _suspectedAccusedList.length;
    final initial =
        isEditing ? _suspectedAccusedList[editIndex] : <String, dynamic>{};

    final nameCtrl =
        TextEditingController(text: initial['name']?.toString() ?? '');
    final ageCtrl =
        TextEditingController(text: initial['age']?.toString() ?? '');
    var selectedGender = initial['gender']?.toString().isNotEmpty == true
        ? initial['gender'].toString()
        : 'Male';
    final occCtrl =
        TextEditingController(text: initial['occupation']?.toString() ?? '');
    final mobileCtrl =
        TextEditingController(text: initial['mobile']?.toString() ?? '');
    final aadhaarCtrl =
        TextEditingController(text: initial['aadhaar']?.toString() ?? '');
    final panCtrl =
        TextEditingController(text: initial['pan']?.toString() ?? '');
    final religionCtrl =
        TextEditingController(text: initial['religion']?.toString() ?? '');
    final casteCtrl =
        TextEditingController(text: initial['caste']?.toString() ?? '');
    final addressCtrl =
        TextEditingController(text: initial['address']?.toString() ?? '');

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg)),
            title: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.navyMid.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_search_rounded,
                      size: 18, color: AppColors.navyMid),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isEditing
                        ? 'Edit Suspected Accused'
                        : 'Add Suspected Accused',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                    ),
                  ),
                ),
                if (!isEditing && _accusedList.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      final firstAcc = _accusedList.first;
                      setDlgState(() {
                        nameCtrl.text = firstAcc['name']?.toString() ?? '';
                        ageCtrl.text = firstAcc['age']?.toString() ?? '';
                        selectedGender =
                            firstAcc['gender']?.toString().isNotEmpty == true
                                ? firstAcc['gender'].toString()
                                : 'Male';
                        occCtrl.text = firstAcc['occupation']?.toString() ?? '';
                        mobileCtrl.text = firstAcc['mobile']?.toString() ?? '';
                        aadhaarCtrl.text =
                            firstAcc['aadhaar']?.toString() ?? '';
                        panCtrl.text = firstAcc['pan']?.toString() ?? '';
                        religionCtrl.text =
                            firstAcc['religion']?.toString() ?? '';
                        casteCtrl.text = firstAcc['caste']?.toString() ?? '';
                        addressCtrl.text =
                            firstAcc['address']?.toString() ?? '';
                      });
                    },
                    icon: const Icon(Icons.copy_rounded, size: 14),
                    label: Text(
                      'Copy Accused',
                      style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.navyMid,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                    ),
                  ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name (Required)
                      TextFormField(
                        controller: nameCtrl,
                        autofocus: !isEditing,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.navyDark),
                        decoration: InputDecoration(
                          labelText: 'Suspected Accused Name *',
                          hintText: 'Enter full name...',
                          prefixIcon: const Icon(Icons.person_outline_rounded,
                              size: 18, color: AppColors.navyMid),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md)),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter suspected accused name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Age & Gender Row
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: TextFormField(
                              controller: ageCtrl,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.navyDark),
                              decoration: InputDecoration(
                                labelText: 'Age',
                                hintText: 'Years',
                                prefixIcon: const Icon(Icons.cake_outlined,
                                    size: 18, color: AppColors.navyMid),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 6,
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedGender,
                              decoration: InputDecoration(
                                labelText: 'Gender',
                                prefixIcon: const Icon(Icons.wc_rounded,
                                    size: 18, color: AppColors.navyMid),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md)),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'Male', child: Text('Male')),
                                DropdownMenuItem(
                                    value: 'Female', child: Text('Female')),
                                DropdownMenuItem(
                                    value: 'Other', child: Text('Other')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDlgState(() => selectedGender = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Occupation & Mobile Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: occCtrl,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.navyDark),
                              decoration: InputDecoration(
                                labelText: 'Occupation',
                                hintText: 'e.g. Business / Driver',
                                prefixIcon: const Icon(
                                    Icons.work_outline_rounded,
                                    size: 18,
                                    color: AppColors.navyMid),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: mobileCtrl,
                              keyboardType: TextInputType.phone,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.navyDark),
                              decoration: InputDecoration(
                                labelText: 'Mobile Number',
                                hintText: '10 digits',
                                prefixIcon: const Icon(
                                    Icons.phone_iphone_rounded,
                                    size: 18,
                                    color: AppColors.navyMid),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Aadhaar & PAN Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: aadhaarCtrl,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.navyDark),
                              decoration: InputDecoration(
                                labelText: 'Aadhaar Number',
                                hintText: '12 digits',
                                prefixIcon: const Icon(
                                    Icons.credit_card_rounded,
                                    size: 18,
                                    color: AppColors.navyMid),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: panCtrl,
                              textCapitalization: TextCapitalization.characters,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.navyDark),
                              decoration: InputDecoration(
                                labelText: 'PAN Number',
                                hintText: '10 chars',
                                prefixIcon: const Icon(Icons.badge_outlined,
                                    size: 18, color: AppColors.navyMid),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Religion & Caste Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: religionCtrl,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.navyDark),
                              decoration: InputDecoration(
                                labelText: 'Religion',
                                prefixIcon: const Icon(
                                    Icons.account_balance_outlined,
                                    size: 18,
                                    color: AppColors.navyMid),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: casteCtrl,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.navyDark),
                              decoration: InputDecoration(
                                labelText: 'Caste',
                                prefixIcon: const Icon(
                                    Icons.people_outline_rounded,
                                    size: 18,
                                    color: AppColors.navyMid),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Address
                      TextFormField(
                        controller: addressCtrl,
                        maxLines: 2,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.navyDark),
                        decoration: InputDecoration(
                          labelText: 'Address',
                          hintText: 'Residential or last known address...',
                          prefixIcon: const Icon(Icons.home_outlined,
                              size: 18, color: AppColors.navyMid),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: GoogleFonts.poppins(color: AppColors.lightSubText)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    final item = {
                      'name': nameCtrl.text.trim(),
                      'age': ageCtrl.text.trim(),
                      'gender': selectedGender,
                      'occupation': occCtrl.text.trim(),
                      'mobile': mobileCtrl.text.trim(),
                      'aadhaar': aadhaarCtrl.text.trim(),
                      'pan': panCtrl.text.trim(),
                      'religion': religionCtrl.text.trim(),
                      'caste': casteCtrl.text.trim(),
                      'address': addressCtrl.text.trim(),
                      'role': 'suspected_accused',
                    };

                    setState(() {
                      if (isEditing) {
                        _suspectedAccusedList[editIndex] = item;
                      } else {
                        _suspectedAccusedList.add(item);
                      }
                      _syncPrimarySuspectedAccusedControllers();
                    });

                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyMid),
                child:
                    Text(isEditing ? 'Save Changes' : 'Add Suspected Accused'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSuspectedAccusedSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
            onTap: () => setState(() => _suspectedAccusedSectionExpanded =
                !_suspectedAccusedSectionExpanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(AppRadius.lg),
              bottom: Radius.circular(
                  _suspectedAccusedSectionExpanded ? 0 : AppRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.navyMid.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person_search_rounded,
                        size: 20, color: AppColors.navyMid),
                  ),
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
                  const SizedBox(width: 8),
                  Icon(
                    _suspectedAccusedSectionExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.lightSubText,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_suspectedAccusedSectionExpanded) ...[
            const Divider(height: 1, color: AppColors.lightBorder),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_suspectedAccusedList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No suspected accused persons added yet. Click "+ Add Suspected Accused" below to record suspected persons.',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: AppColors.lightSubText,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    ..._suspectedAccusedList.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      final name = item['name']?.toString() ??
                          'Suspected Accused #${idx + 1}';
                      final age = item['age']?.toString() ?? '';
                      final gender = item['gender']?.toString() ?? '';
                      final mobile = item['mobile']?.toString() ?? '';
                      final occ = item['occupation']?.toString() ?? '';
                      final address = item['address']?.toString() ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                  child: Center(
                                    child: Text(
                                      '${idx + 1}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.navyMid,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.navyDark,
                                    ),
                                  ),
                                ),
                                if (!widget.readOnly) ...[
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded,
                                        size: 18, color: AppColors.navyMid),
                                    onPressed: () =>
                                        _showAddEditSuspectedAccusedDialog(
                                            editIndex: idx),
                                    tooltip: 'Edit Suspected Accused',
                                    splashRadius: 16,
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: AppColors.dangerRed),
                                    onPressed: () {
                                      setState(() {
                                        _suspectedAccusedList.removeAt(idx);
                                        _syncPrimarySuspectedAccusedControllers();
                                      });
                                    },
                                    tooltip: 'Remove',
                                    splashRadius: 16,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (age.isNotEmpty)
                                  _buildMiniTag(
                                      'Age: $age', Icons.cake_outlined),
                                if (gender.isNotEmpty)
                                  _buildMiniTag(gender, Icons.wc_rounded),
                                if (mobile.isNotEmpty)
                                  _buildMiniTag(
                                      mobile, Icons.phone_iphone_rounded),
                                if (occ.isNotEmpty)
                                  _buildMiniTag(
                                      occ, Icons.work_outline_rounded),
                                if (address.isNotEmpty)
                                  _buildMiniTag(
                                      address, Icons.location_on_outlined),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  if (!widget.readOnly) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _showAddEditSuspectedAccusedDialog(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navyMid,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md)),
                        side: const BorderSide(color: AppColors.navyMid),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        _suspectedAccusedList.isEmpty
                            ? 'Add Suspected Accused'
                            : 'Add Another Suspected Accused',
                        style: GoogleFonts.poppins(
                            fontSize: 12.5, fontWeight: FontWeight.w600),
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

  void _showAddEditUnidentifiedAccusedDialog({int? editIndex}) {
    final isEditing = editIndex != null &&
        editIndex >= 0 &&
        editIndex < _unidentifiedAccusedList.length;
    final initial =
        isEditing ? _unidentifiedAccusedList[editIndex] : <String, dynamic>{};

    final ageCtrl = TextEditingController(
        text: initial['approximate_age']?.toString() ?? '');
    var selectedGender = initial['gender']?.toString().isNotEmpty == true
        ? initial['gender'].toString()
        : 'Male';
    final skinCtrl =
        TextEditingController(text: initial['skin_colour']?.toString() ?? '');
    final heightCtrl =
        TextEditingController(text: initial['height']?.toString() ?? '');
    final occCtrl = TextEditingController(
        text: initial['possible_occupation']?.toString() ?? '');
    final markCtrl = TextEditingController(
        text: initial['identification_mark']?.toString() ?? '');
    final descCtrl =
        TextEditingController(text: initial['description']?.toString() ?? '');
    final addrCtrl =
        TextEditingController(text: initial['address']?.toString() ?? '');

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg)),
            title: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.navyMid.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fingerprint_rounded,
                      size: 18, color: AppColors.navyMid),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isEditing
                        ? 'Edit Unidentified Accused'
                        : 'Add Unidentified Accused',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Age & Gender Row
                      Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: TextFormField(
                              controller: ageCtrl,
                              autofocus: !isEditing,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.navyDark),
                              decoration: InputDecoration(
                                labelText: 'Approximate Age',
                                hintText: 'e.g. 25-30 yrs',
                                prefixIcon: const Icon(Icons.cake_outlined,
                                    size: 18, color: AppColors.navyMid),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 5,
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedGender,
                              decoration: InputDecoration(
                                labelText: 'Gender',
                                prefixIcon: const Icon(Icons.wc_rounded,
                                    size: 18, color: AppColors.navyMid),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md)),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'Male', child: Text('Male')),
                                DropdownMenuItem(
                                    value: 'Female', child: Text('Female')),
                                DropdownMenuItem(
                                    value: 'Other', child: Text('Other')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDlgState(() => selectedGender = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Skin Colour & Height Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: skinCtrl,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.navyDark),
                              decoration: InputDecoration(
                                labelText: 'Skin Colour / Complexion',
                                hintText: 'e.g. Fair / Wheatish / Dark',
                                prefixIcon: const Icon(Icons.palette_outlined,
                                    size: 18, color: AppColors.navyMid),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: heightCtrl,
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.navyDark),
                              decoration: InputDecoration(
                                labelText: 'Height',
                                hintText: "e.g. 5'8\" or 170cm",
                                prefixIcon: const Icon(Icons.height_rounded,
                                    size: 18, color: AppColors.navyMid),
                                border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.md)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Possible Occupation
                      TextFormField(
                        controller: occCtrl,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.navyDark),
                        decoration: InputDecoration(
                          labelText: 'Possible Occupation',
                          hintText: 'e.g. Driver / Laborer / Student',
                          prefixIcon: const Icon(Icons.work_outline_rounded,
                              size: 18, color: AppColors.navyMid),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Identification Mark
                      TextFormField(
                        controller: markCtrl,
                        maxLines: 2,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.navyDark),
                        decoration: InputDecoration(
                          labelText: 'Identification Mark(s)',
                          hintText:
                              'Scars, tattoos, mole, burn marks, deformities...',
                          prefixIcon: const Icon(Icons.visibility_outlined,
                              size: 18, color: AppColors.navyMid),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Physical Description
                      TextFormField(
                        controller: descCtrl,
                        maxLines: 2,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.navyDark),
                        decoration: InputDecoration(
                          labelText: 'Physical Description / Clothing',
                          hintText:
                              'Build, hair, facial features, clothes worn, language...',
                          prefixIcon: const Icon(Icons.description_outlined,
                              size: 18, color: AppColors.navyMid),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Address / Area
                      TextFormField(
                        controller: addrCtrl,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.navyDark),
                        decoration: InputDecoration(
                          labelText: 'Last Seen Location / Area',
                          hintText: 'Area or locality where last spotted...',
                          prefixIcon: const Icon(Icons.location_on_outlined,
                              size: 18, color: AppColors.navyMid),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: GoogleFonts.poppins(color: AppColors.lightSubText)),
              ),
              ElevatedButton(
                onPressed: () {
                  final item = {
                    'approximate_age': ageCtrl.text.trim(),
                    'gender': selectedGender,
                    'skin_colour': skinCtrl.text.trim(),
                    'height': heightCtrl.text.trim(),
                    'possible_occupation': occCtrl.text.trim(),
                    'identification_mark': markCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'address': addrCtrl.text.trim(),
                    'role': 'unidentified_accused',
                  };

                  setState(() {
                    if (isEditing) {
                      _unidentifiedAccusedList[editIndex] = item;
                    } else {
                      _unidentifiedAccusedList.add(item);
                    }
                    _syncPrimaryUnidentifiedControllers();
                  });

                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyMid),
                child: Text(
                    isEditing ? 'Save Changes' : 'Add Unidentified Accused'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUnidentifiedAccusedSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
            onTap: () => setState(() => _unidentifiedAccusedSectionExpanded =
                !_unidentifiedAccusedSectionExpanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(AppRadius.lg),
              bottom: Radius.circular(
                  _unidentifiedAccusedSectionExpanded ? 0 : AppRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.navyMid.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fingerprint_rounded,
                        size: 20, color: AppColors.navyMid),
                  ),
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
                  const SizedBox(width: 8),
                  Icon(
                    _unidentifiedAccusedSectionExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.lightSubText,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_unidentifiedAccusedSectionExpanded) ...[
            const Divider(height: 1, color: AppColors.lightBorder),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_unidentifiedAccusedList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No unidentified accused persons added yet. Click "+ Add Unidentified Accused" below to record physical descriptors and marks.',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: AppColors.lightSubText,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    ..._unidentifiedAccusedList.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      final age = item['approximate_age']?.toString() ?? '';
                      final gender = item['gender']?.toString() ?? '';
                      final skin = item['skin_colour']?.toString() ?? '';
                      final height = item['height']?.toString() ?? '';
                      final occ = item['possible_occupation']?.toString() ?? '';
                      final mark =
                          item['identification_mark']?.toString() ?? '';
                      final desc = item['description']?.toString() ?? '';
                      final address = item['address']?.toString() ?? '';

                      final titleStr = (age.isNotEmpty || gender.isNotEmpty)
                          ? 'Unidentified Accused #${idx + 1} (${[
                              age,
                              gender
                            ].where((s) => s.isNotEmpty).join(', ')})'
                          : 'Unidentified Accused #${idx + 1}';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                  child: Center(
                                    child: Text(
                                      '${idx + 1}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.navyMid,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    titleStr,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.navyDark,
                                    ),
                                  ),
                                ),
                                if (!widget.readOnly) ...[
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded,
                                        size: 18, color: AppColors.navyMid),
                                    onPressed: () =>
                                        _showAddEditUnidentifiedAccusedDialog(
                                            editIndex: idx),
                                    tooltip: 'Edit Unidentified Accused',
                                    splashRadius: 16,
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: AppColors.dangerRed),
                                    onPressed: () {
                                      setState(() {
                                        _unidentifiedAccusedList.removeAt(idx);
                                        _syncPrimaryUnidentifiedControllers();
                                      });
                                    },
                                    tooltip: 'Remove',
                                    splashRadius: 16,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (age.isNotEmpty)
                                  _buildMiniTag(
                                      'Age: $age', Icons.cake_outlined),
                                if (gender.isNotEmpty)
                                  _buildMiniTag(gender, Icons.wc_rounded),
                                if (skin.isNotEmpty)
                                  _buildMiniTag(
                                      'Skin: $skin', Icons.palette_outlined),
                                if (height.isNotEmpty)
                                  _buildMiniTag(
                                      'Height: $height', Icons.height_rounded),
                                if (occ.isNotEmpty)
                                  _buildMiniTag(
                                      occ, Icons.work_outline_rounded),
                                if (mark.isNotEmpty)
                                  _buildMiniTag(
                                      'Mark: $mark', Icons.visibility_outlined),
                                if (desc.isNotEmpty)
                                  _buildMiniTag('Desc: $desc',
                                      Icons.description_outlined),
                                if (address.isNotEmpty)
                                  _buildMiniTag(
                                      address, Icons.location_on_outlined),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  if (!widget.readOnly) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _showAddEditUnidentifiedAccusedDialog(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navyMid,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md)),
                        side: const BorderSide(color: AppColors.navyMid),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        _unidentifiedAccusedList.isEmpty
                            ? 'Add Unidentified Accused'
                            : 'Add Another Unidentified Accused',
                        style: GoogleFonts.poppins(
                            fontSize: 12.5, fontWeight: FontWeight.w600),
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
    }
  }

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

  void _showAddEditArrestDialog({int? editIndex}) {
    final isEditing = editIndex != null &&
        editIndex >= 0 &&
        editIndex < _arrestRecordsList.length;
    final initial =
        isEditing ? _arrestRecordsList[editIndex] : <String, dynamic>{};

    final availableNames = _getAvailableAccusedNames();
    String? selectedName = (initial['arrested_person_name'] ??
            initial['person_name'] ??
            initial['name'])
        ?.toString();
    if (selectedName != null && selectedName.isEmpty) selectedName = null;

    final customNameCtrl = TextEditingController(
        text: (selectedName != null && !availableNames.contains(selectedName))
            ? selectedName
            : '');
    bool isCustomName = selectedName != null &&
        !availableNames.contains(selectedName) &&
        selectedName != '__custom__';

    final nowStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final arrestDateCtrl = TextEditingController(
        text: initial['arrest_datetime']?.toString().isNotEmpty == true
            ? initial['arrest_datetime'].toString()
            : nowStr);

    bool isSec4748 = initial['sec_47_48_bnss'] == true;
    final relNameCtrl = TextEditingController(
        text: initial['relative_friend_name']?.toString() ?? '');
    final relRelationCtrl = TextEditingController(
        text: initial['relative_friend_relation']?.toString() ?? '');

    bool isReleaseOnNotice = initial['release_on_notice'] == true;
    final noticeDateCtrl = TextEditingController(
        text: initial['release_on_notice_datetime']?.toString() ?? '');

    bool isAnticipatoryBail = initial['anticipatory_bail'] == true;
    final antBailDateCtrl = TextEditingController(
        text: initial['anticipatory_bail_datetime']?.toString() ?? '');

    bool isDeath = initial['death_of_accused'] == true;
    final deathDateCtrl = TextEditingController(
        text: initial['death_of_accused_datetime']?.toString() ?? '');

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg)),
            title: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.navyMid.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.front_hand_rounded,
                      size: 18, color: AppColors.navyMid),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isEditing ? 'Edit Arrest Record' : 'Add Arrest Record',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDark,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Arrested Person Name Selector
                      if (!isCustomName) ...[
                        DropdownButtonFormField<String>(
                          initialValue: (selectedName != null &&
                                  availableNames.contains(selectedName))
                              ? selectedName
                              : null,
                          decoration: InputDecoration(
                            labelText: 'Arrested Person Name *',
                            prefixIcon: const Icon(Icons.person_pin_rounded,
                                size: 18, color: AppColors.navyMid),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md)),
                          ),
                          hint: const Text('Select Accused / Suspect...'),
                          items: [
                            ...availableNames.map((n) => DropdownMenuItem(
                                  value: n,
                                  child: Text(n),
                                )),
                            const DropdownMenuItem(
                              value: '__custom__',
                              child: Text(
                                '+ Type other name...',
                                style: TextStyle(
                                    color: AppColors.navyMid,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val == '__custom__') {
                              setDlgState(() {
                                isCustomName = true;
                                selectedName = null;
                              });
                            } else {
                              setDlgState(() {
                                selectedName = val;
                              });
                            }
                          },
                          validator: (val) {
                            if (!isCustomName &&
                                (selectedName == null ||
                                    selectedName!.trim().isEmpty)) {
                              return 'Please select or enter arrested person name';
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: customNameCtrl,
                                autofocus: true,
                                style: GoogleFonts.poppins(
                                    fontSize: 13, color: AppColors.navyDark),
                                decoration: InputDecoration(
                                  labelText: 'Arrested Person Name *',
                                  hintText: 'Enter full name...',
                                  prefixIcon: const Icon(
                                      Icons.person_outline_rounded,
                                      size: 18,
                                      color: AppColors.navyMid),
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md)),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter arrested person name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            if (availableNames.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.list_alt_rounded,
                                    color: AppColors.navyMid),
                                tooltip: 'Pick from list',
                                onPressed: () {
                                  setDlgState(() {
                                    isCustomName = false;
                                    selectedName = availableNames.first;
                                  });
                                },
                              ),
                            ],
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Arrest Date & Time
                      TextFormField(
                        controller: arrestDateCtrl,
                        readOnly: true,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.navyDark),
                        decoration: InputDecoration(
                          labelText: 'Arrest Date & Time',
                          prefixIcon: const Icon(Icons.access_time_rounded,
                              size: 18, color: AppColors.navyMid),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_month_rounded,
                                size: 18, color: AppColors.navyMid),
                            onPressed: () =>
                                _pickDateTime(context, arrestDateCtrl),
                          ),
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Section 47/48 BNSS Intimation
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CheckboxListTile(
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
                                    color: AppColors.lightSubText),
                              ),
                              value: isSec4748,
                              activeColor: AppColors.navyMid,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (val) {
                                setDlgState(() => isSec4748 = val ?? false);
                              },
                            ),
                            if (isSec4748) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: relNameCtrl,
                                      style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: AppColors.navyDark),
                                      decoration: InputDecoration(
                                        labelText: 'Relative / Friend Name',
                                        hintText: 'e.g. Ramesh',
                                        prefixIcon: const Icon(
                                            Icons.person_outline_rounded,
                                            size: 16,
                                            color: AppColors.navyMid),
                                        border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.md)),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      controller: relRelationCtrl,
                                      style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: AppColors.navyDark),
                                      decoration: InputDecoration(
                                        labelText: 'Relation with Accused',
                                        hintText: 'e.g. Father / Brother',
                                        prefixIcon: const Icon(
                                            Icons.family_restroom_rounded,
                                            size: 16,
                                            color: AppColors.navyMid),
                                        border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.md)),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Release on Notice under BNSS
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CheckboxListTile(
                              title: Text(
                                'Release on Notice',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navyDark,
                                ),
                              ),
                              value: isReleaseOnNotice,
                              activeColor: AppColors.navyMid,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (val) {
                                setDlgState(() {
                                  isReleaseOnNotice = val ?? false;
                                  if (isReleaseOnNotice &&
                                      noticeDateCtrl.text.isEmpty) {
                                    noticeDateCtrl.text =
                                        DateFormat('dd/MM/yyyy HH:mm')
                                            .format(DateTime.now());
                                  }
                                });
                              },
                            ),
                            if (isReleaseOnNotice) ...[
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: noticeDateCtrl,
                                readOnly: true,
                                style: GoogleFonts.poppins(
                                    fontSize: 13, color: AppColors.navyDark),
                                decoration: InputDecoration(
                                  labelText: 'Release on Notice Date & Time',
                                  prefixIcon: const Icon(
                                      Icons.access_time_rounded,
                                      size: 16,
                                      color: AppColors.navyMid),
                                  suffixIcon: IconButton(
                                    icon: const Icon(
                                        Icons.calendar_month_rounded,
                                        size: 16,
                                        color: AppColors.navyMid),
                                    onPressed: () =>
                                        _pickDateTime(context, noticeDateCtrl),
                                  ),
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Anticipatory Bail
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CheckboxListTile(
                              title: Text(
                                'Anticipatory Bail',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navyDark,
                                ),
                              ),
                              value: isAnticipatoryBail,
                              activeColor: AppColors.navyMid,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (val) {
                                setDlgState(() {
                                  isAnticipatoryBail = val ?? false;
                                  if (isAnticipatoryBail &&
                                      antBailDateCtrl.text.isEmpty) {
                                    antBailDateCtrl.text =
                                        DateFormat('dd/MM/yyyy HH:mm')
                                            .format(DateTime.now());
                                  }
                                });
                              },
                            ),
                            if (isAnticipatoryBail) ...[
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: antBailDateCtrl,
                                readOnly: true,
                                style: GoogleFonts.poppins(
                                    fontSize: 13, color: AppColors.navyDark),
                                decoration: InputDecoration(
                                  labelText: 'Anticipatory Bail Date & Time',
                                  prefixIcon: const Icon(
                                      Icons.access_time_rounded,
                                      size: 16,
                                      color: AppColors.navyMid),
                                  suffixIcon: IconButton(
                                    icon: const Icon(
                                        Icons.calendar_month_rounded,
                                        size: 16,
                                        color: AppColors.navyMid),
                                    onPressed: () =>
                                        _pickDateTime(context, antBailDateCtrl),
                                  ),
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Death of Accused
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CheckboxListTile(
                              title: Text(
                                'Death of Accused',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.dangerRed,
                                ),
                              ),
                              value: isDeath,
                              activeColor: AppColors.dangerRed,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (val) {
                                setDlgState(() {
                                  isDeath = val ?? false;
                                  if (isDeath && deathDateCtrl.text.isEmpty) {
                                    deathDateCtrl.text =
                                        DateFormat('dd/MM/yyyy HH:mm')
                                            .format(DateTime.now());
                                  }
                                });
                              },
                            ),
                            if (isDeath) ...[
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: deathDateCtrl,
                                readOnly: true,
                                style: GoogleFonts.poppins(
                                    fontSize: 13, color: AppColors.navyDark),
                                decoration: InputDecoration(
                                  labelText: 'Death Date & Time',
                                  prefixIcon: const Icon(
                                      Icons.access_time_rounded,
                                      size: 16,
                                      color: AppColors.dangerRed),
                                  suffixIcon: IconButton(
                                    icon: const Icon(
                                        Icons.calendar_month_rounded,
                                        size: 16,
                                        color: AppColors.dangerRed),
                                    onPressed: () =>
                                        _pickDateTime(context, deathDateCtrl),
                                  ),
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md)),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: GoogleFonts.poppins(color: AppColors.lightSubText)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    final finalName = isCustomName
                        ? customNameCtrl.text.trim()
                        : (selectedName ?? '').trim();

                    final item = {
                      'arrested_person_name': finalName,
                      'person_name': finalName,
                      'name': finalName,
                      'arrest_datetime': arrestDateCtrl.text.trim(),
                      'sec_47_48_bnss': isSec4748,
                      'relative_friend_name':
                          isSec4748 ? relNameCtrl.text.trim() : '',
                      'relative_friend_relation':
                          isSec4748 ? relRelationCtrl.text.trim() : '',
                      'release_on_notice': isReleaseOnNotice,
                      'release_on_notice_datetime':
                          isReleaseOnNotice ? noticeDateCtrl.text.trim() : '',
                      'anticipatory_bail': isAnticipatoryBail,
                      'anticipatory_bail_datetime':
                          isAnticipatoryBail ? antBailDateCtrl.text.trim() : '',
                      'death_of_accused': isDeath,
                      'death_of_accused_datetime':
                          isDeath ? deathDateCtrl.text.trim() : '',
                    };

                    setState(() {
                      if (isEditing) {
                        _arrestRecordsList[editIndex] = item;
                      } else {
                        _arrestRecordsList.add(item);
                      }
                      _syncPrimaryArrestControllers();
                    });

                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyMid),
                child: Text(isEditing ? 'Save Changes' : 'Add Arrest Record'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildArrestSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
            onTap: () => setState(
                () => _arrestSectionExpanded = !_arrestSectionExpanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(AppRadius.lg),
              bottom:
                  Radius.circular(_arrestSectionExpanded ? 0 : AppRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.navyMid.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.front_hand_rounded,
                        size: 20, color: AppColors.navyMid),
                  ),
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
                      '${_arrestRecordsList.length} arrests',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyMid,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _arrestSectionExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.lightSubText,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_arrestSectionExpanded) ...[
            const Divider(height: 1, color: AppColors.lightBorder),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_arrestRecordsList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No arrest records added yet. Click "+ Add Arrest Record" below to record arrest, notice release, or bail details.',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: AppColors.lightSubText,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    ..._arrestRecordsList.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      final name = (item['arrested_person_name'] ??
                                  item['person_name'] ??
                                  item['name'])
                              ?.toString() ??
                          'Person #${idx + 1}';
                      final arrestDt =
                          item['arrest_datetime']?.toString() ?? '';
                      final isSec4748 = item['sec_47_48_bnss'] == true;
                      final relName =
                          item['relative_friend_name']?.toString() ?? '';
                      final relRel =
                          item['relative_friend_relation']?.toString() ?? '';
                      final isNotice = item['release_on_notice'] == true;
                      final noticeDt =
                          item['release_on_notice_datetime']?.toString() ?? '';
                      final isAntBail = item['anticipatory_bail'] == true;
                      final antBailDt =
                          item['anticipatory_bail_datetime']?.toString() ?? '';
                      final isDeath = item['death_of_accused'] == true;
                      final deathDt =
                          item['death_of_accused_datetime']?.toString() ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                  child: Center(
                                    child: Text(
                                      '${idx + 1}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.navyMid,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.navyDark,
                                    ),
                                  ),
                                ),
                                if (!widget.readOnly) ...[
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded,
                                        size: 18, color: AppColors.navyMid),
                                    onPressed: () => _showAddEditArrestDialog(
                                        editIndex: idx),
                                    tooltip: 'Edit Arrest Record',
                                    splashRadius: 16,
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: AppColors.dangerRed),
                                    onPressed: () {
                                      setState(() {
                                        _arrestRecordsList.removeAt(idx);
                                        _syncPrimaryArrestControllers();
                                      });
                                    },
                                    tooltip: 'Remove',
                                    splashRadius: 16,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (arrestDt.isNotEmpty)
                                  _buildMiniTag('Arrest: $arrestDt',
                                      Icons.access_time_rounded),
                                if (isSec4748)
                                  _buildStatusBadge(
                                    label: relName.isNotEmpty
                                        ? 'Sec 47/48 BNSS: $relName ($relRel)'
                                        : 'Sec 47/48 BNSS Intimation Given',
                                    color: const Color(0xFF16A34A),
                                    bgColor: const Color(0xFFDCFCE7),
                                  ),
                                if (isNotice)
                                  _buildStatusBadge(
                                    label: noticeDt.isNotEmpty
                                        ? 'Notice Release: $noticeDt'
                                        : 'Released on Notice',
                                    color: const Color(0xFFD97706),
                                    bgColor: const Color(0xFFFEF3C7),
                                  ),
                                if (isAntBail)
                                  _buildStatusBadge(
                                    label: antBailDt.isNotEmpty
                                        ? 'Anticipatory Bail: $antBailDt'
                                        : 'Anticipatory Bail Granted',
                                    color: const Color(0xFF9333EA),
                                    bgColor: const Color(0xFFF3E8FF),
                                  ),
                                if (isDeath)
                                  _buildStatusBadge(
                                    label: deathDt.isNotEmpty
                                        ? 'Deceased: $deathDt'
                                        : 'Deceased',
                                    color: AppColors.dangerRed,
                                    bgColor: const Color(0xFFFEE2E2),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  if (!widget.readOnly) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _showAddEditArrestDialog(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navyMid,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md)),
                        side: const BorderSide(color: AppColors.navyMid),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        _arrestRecordsList.isEmpty
                            ? 'Add Arrest Record'
                            : 'Add Another Arrest Record',
                        style: GoogleFonts.poppins(
                            fontSize: 12.5, fontWeight: FontWeight.w600),
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
  }

  // ── Unknown Accused Repeating List Section ──────────────────────────────
  Widget _buildUnknownAccusedSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.navyMid.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.help_outline_rounded,
                      size: 20, color: AppColors.navyMid),
                ),
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
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.lightBorder),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
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
    );
  }

  // ── Preventive Action for Multiple Accused Section ────────────────────────
  Widget _buildPreventiveActionSection() {
    final availableAccused = _getAvailableAccusedNames();

    // Ensure selected accused is valid option for dropdown if set
    final dropdownItems = <String>{...availableAccused};
    if (_selectedPreventiveAccused != null &&
        _selectedPreventiveAccused!.isNotEmpty) {
      dropdownItems.add(_selectedPreventiveAccused!);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
            onTap: () => setState(
                () => _preventiveSectionExpanded = !_preventiveSectionExpanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(AppRadius.lg),
              bottom: Radius.circular(
                  _preventiveSectionExpanded ? 0 : AppRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.navyMid.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shield_rounded,
                        size: 20, color: AppColors.navyMid),
                  ),
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
                          : '${availableAccused.length} accused',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyMid,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _preventiveSectionExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.lightSubText,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_preventiveSectionExpanded) ...[
            const Divider(height: 1, color: AppColors.lightBorder),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
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
                          borderSide:
                              const BorderSide(color: AppColors.lightBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide:
                              const BorderSide(color: AppColors.lightBorder),
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
                      key: ValueKey(_selectedPreventiveAccused),
                      initialValue: _selectedPreventiveAccused,
                      isExpanded: true,
                      items: [
                        ...dropdownItems.map((name) => DropdownMenuItem<String>(
                              value: name,
                              child: Row(
                                children: [
                                  const Icon(Icons.person_outline_rounded,
                                      size: 16, color: AppColors.navyMid),
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
                      onChanged: _onPreventiveAccusedSelected,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Opened fields when an accused is selected
                  if (_selectedPreventiveAccused != null &&
                      _selectedPreventiveAccused!.isNotEmpty &&
                      !widget.readOnly) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                            color: AppColors.navyMid.withValues(alpha: 0.25)),
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
                                  color:
                                      AppColors.navyMid.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.shield_rounded,
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
                                          text: 'Preventive Action for: '),
                                      TextSpan(
                                        text: _selectedPreventiveAccused!,
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
                                    () => _selectedPreventiveAccused = null),
                                icon: const Icon(Icons.close_rounded,
                                    size: 18, color: AppColors.lightSubText),
                                tooltip: 'Cancel selection',
                                splashRadius: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // The Preventive Action fields
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth > 650;
                              if (isWide) {
                                return Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildPreventiveTypeDropdown(),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildPreventiveDateField(
                                              context),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildPreventiveOutwardField(),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildPreventiveBondDateField(
                                              context),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child:
                                              _buildPreventiveBondCancelDateField(
                                                  context),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton.icon(
                                          onPressed: _addPreventiveAction,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.navyMid,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 15),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppRadius.md)),
                                            elevation: 0,
                                          ),
                                          icon: const Icon(Icons.add_rounded,
                                              size: 18, color: Colors.white),
                                          label: Text(
                                            'Add Action',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              } else {
                                return Column(
                                  children: [
                                    _buildPreventiveTypeDropdown(),
                                    const SizedBox(height: 12),
                                    _buildPreventiveDateField(context),
                                    const SizedBox(height: 12),
                                    _buildPreventiveOutwardField(),
                                    const SizedBox(height: 12),
                                    _buildPreventiveBondDateField(context),
                                    const SizedBox(height: 12),
                                    _buildPreventiveBondCancelDateField(
                                        context),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: _addPreventiveAction,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.navyMid,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppRadius.md)),
                                        ),
                                        icon: const Icon(Icons.add_rounded,
                                            size: 18),
                                        label: Text(
                                          'Add Action',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Display list of added preventive action items
                  if (_preventiveActionsList.isNotEmpty) ...[
                    Row(
                      children: [
                        Text(
                          'Recorded Preventive Actions (${_preventiveActionsList.length})',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ..._preventiveActionsList.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      final pName =
                          item['name']?.toString() ?? 'Unknown Accused';
                      final pType = item['action_type']?.toString() ?? '';
                      final pDate = item['action_date']?.toString() ?? '';
                      final pOut = item['outward_number']?.toString() ?? '';

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
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.navyMid.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_rounded,
                                  size: 18, color: AppColors.navyMid),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        pName,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.navyDark,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.navyMid,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          pType,
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded,
                                          size: 12,
                                          color: AppColors.lightSubText),
                                      const SizedBox(width: 4),
                                      Text(
                                        pDate.isNotEmpty ? pDate : 'No date',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: AppColors.lightSubText,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (pOut.isNotEmpty) ...[
                                        const SizedBox(width: 12),
                                        const Icon(Icons.tag_rounded,
                                            size: 12,
                                            color: AppColors.lightSubText),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Outward: $pOut',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: AppColors.lightSubText,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (!widget.readOnly)
                              IconButton(
                                onPressed: () => _removePreventiveAction(idx),
                                icon: const Icon(Icons.delete_outline_rounded,
                                    size: 20, color: AppColors.dangerRed),
                                tooltip: 'Remove action',
                                splashRadius: 18,
                              ),
                          ],
                        ),
                      );
                    }),
                  ] else if (_selectedPreventiveAccused == null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.lightBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 18, color: AppColors.lightSubText),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Select an accused or arrested person from the dropdown above to open and configure preventive action details.',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: AppColors.lightSubText),
                            ),
                          ),
                        ],
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
  }

  Widget _buildPreventiveTypeDropdown() {
    final choices = (_formDef != null && _formDef!.preventiveItems.isNotEmpty)
        ? _formDef!.preventiveItems
        : DynamicControlFactory.preventiveActionChoices;

    final currentVal = choices.contains(_selectedPreventiveType)
        ? _selectedPreventiveType
        : choices.firstOrNull;

    return DropdownButtonFormField<String>(
      key: ValueKey(currentVal),
      initialValue: currentVal,
      decoration: InputDecoration(
        labelText: 'Preventive Action Type',
        labelStyle:
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
      items: choices
          .map((type) => DropdownMenuItem<String>(
                value: type,
                child: Text(
                  type,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.navyDark,
                  ),
                ),
              ))
          .toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedPreventiveType = val;
            if (_preventiveDateCtrl.text.isEmpty) {
              _preventiveDateCtrl.text =
                  DateFormat('dd/MM/yyyy').format(DateTime.now());
            }
          });
        }
      },
    );
  }

  Widget _buildPreventiveDateField(BuildContext context) {
    return TextFormField(
      controller: _preventiveDateCtrl,
      readOnly: true,
      onTap: () => _pickPreventiveDate(context),
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.navyDark,
      ),
      decoration: InputDecoration(
        labelText: 'Preventive Action Date',
        labelStyle:
            GoogleFonts.poppins(fontSize: 12, color: AppColors.lightSubText),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_month_rounded,
              size: 20, color: AppColors.navyMid),
          onPressed: () => _pickPreventiveDate(context),
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

  Widget _buildPreventiveOutwardField() {
    return TextFormField(
      controller: _preventiveOutwardCtrl,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.navyDark,
      ),
      decoration: InputDecoration(
        labelText: 'Preventive Action Outward No',
        hintText: 'Enter Outward Number...',
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

  Widget _buildPreventiveBondDateField(BuildContext context) {
    return TextFormField(
      controller: _preventiveBondDateCtrl,
      readOnly: true,
      onTap: () => _pickDateForController(context, _preventiveBondDateCtrl),
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.navyDark,
      ),
      decoration: InputDecoration(
        labelText: 'Bond Date',
        labelStyle:
            GoogleFonts.poppins(fontSize: 12, color: AppColors.lightSubText),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_month_rounded,
              size: 20, color: AppColors.navyMid),
          onPressed: () =>
              _pickDateForController(context, _preventiveBondDateCtrl),
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

  Widget _buildPreventiveBondCancelDateField(BuildContext context) {
    return TextFormField(
      controller: _preventiveBondCancelDateCtrl,
      readOnly: true,
      onTap: () =>
          _pickDateForController(context, _preventiveBondCancelDateCtrl),
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.navyDark,
      ),
      decoration: InputDecoration(
        labelText: 'Bond Cancellation Date',
        labelStyle:
            GoogleFonts.poppins(fontSize: 12, color: AppColors.lightSubText),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_month_rounded,
              size: 20, color: AppColors.navyMid),
          onPressed: () =>
              _pickDateForController(context, _preventiveBondCancelDateCtrl),
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

  void _onPreventiveAccusedSelected(String? selectedName) {
    if (selectedName == '__custom__') {
      _showAddCustomPreventiveAccusedDialog();
    } else if (selectedName != null && selectedName.isNotEmpty) {
      setState(() {
        _selectedPreventiveAccused = selectedName;
        if (_preventiveDateCtrl.text.isEmpty) {
          _preventiveDateCtrl.text =
              DateFormat('dd/MM/yyyy').format(DateTime.now());
        }
      });
    }
  }

  Future<void> _pickPreventiveDate(BuildContext context) async {
    DateTime initial = DateTime.now();
    final cur = _preventiveDateCtrl.text.trim();
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
        _preventiveDateCtrl.text = formatted;
      });
    }
  }

  void _addPreventiveAction() {
    final accusedName = _selectedPreventiveAccused?.trim() ?? '';
    if (accusedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an accused or arrested person first.'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }
    final actType = _selectedPreventiveType.trim();
    if (actType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a preventive action type.'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }
    final actDate = _preventiveDateCtrl.text.trim().isNotEmpty
        ? _preventiveDateCtrl.text.trim()
        : DateFormat('dd/MM/yyyy').format(DateTime.now());
    final outward = _preventiveOutwardCtrl.text.trim();
    final bDate = _preventiveBondDateCtrl.text.trim();
    final bCancelDate = _preventiveBondCancelDateCtrl.text.trim();

    setState(() {
      final existingIndex = _preventiveActionsList.indexWhere(
        (it) => it['name'] == accusedName && it['action_type'] == actType,
      );

      final itemMap = {
        'name': accusedName,
        'person_name': accusedName,
        'action_type': actType,
        'action_date': actDate,
        'outward_number': outward,
        'bond_date': bDate,
        'bond_cancellation_date': bCancelDate,
      };

      if (existingIndex >= 0) {
        _preventiveActionsList[existingIndex] = itemMap;
      } else {
        _preventiveActionsList.add(itemMap);
      }

      _preventiveOutwardCtrl.clear();
      _preventiveBondDateCtrl.clear();
      _preventiveBondCancelDateCtrl.clear();

      // Sync first action into controllers for backward compatibility
      if (_preventiveActionsList.isNotEmpty) {
        final first = _preventiveActionsList.first;
        _controllers
            .putIfAbsent(
                'preventive_action_type', () => TextEditingController())
            .text = first['action_type'] ?? '';
        _values['preventive_action_type'] = first['action_type'];
        _controllers
            .putIfAbsent(
                'preventive_action_date', () => TextEditingController())
            .text = first['action_date'] ?? '';
        _values['preventive_action_date'] = first['action_date'];
        _controllers
            .putIfAbsent('preventive_outward_no', () => TextEditingController())
            .text = first['outward_number'] ?? '';
        _values['preventive_outward_no'] = first['outward_number'];
      }

      _preventiveOutwardCtrl.clear();
      _selectedPreventiveAccused = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Preventive action recorded for $accusedName'),
        backgroundColor: AppColors.navyMid,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removePreventiveAction(int index) {
    setState(() {
      _preventiveActionsList.removeAt(index);
      if (_preventiveActionsList.isNotEmpty) {
        final first = _preventiveActionsList.first;
        _controllers['preventive_action_type']?.text =
            first['action_type'] ?? '';
        _values['preventive_action_type'] = first['action_type'];
        _controllers['preventive_action_date']?.text =
            first['action_date'] ?? '';
        _values['preventive_action_date'] = first['action_date'];
        _controllers['preventive_outward_no']?.text =
            first['outward_number'] ?? '';
        _values['preventive_outward_no'] = first['outward_number'];
      } else {
        _controllers['preventive_action_type']?.clear();
        _values.remove('preventive_action_type');
        _controllers['preventive_action_date']?.clear();
        _values.remove('preventive_action_date');
        _controllers['preventive_outward_no']?.clear();
        _values.remove('preventive_outward_no');
      }
    });
  }

  void _showAddCustomPreventiveAccusedDialog() {
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
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Person Name',
            hintText: 'Enter accused / arrested name...',
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
              if (val.isNotEmpty) {
                setState(() {
                  _selectedPreventiveAccused = val;
                  if (_preventiveDateCtrl.text.isEmpty) {
                    _preventiveDateCtrl.text =
                        DateFormat('dd/MM/yyyy').format(DateTime.now());
                  }
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

  // ── Remand & Custody for Multiple Accused Section ──────────────────────────
  Widget _buildRemandCustodySection() {
    final availableAccused = _getAvailableAccusedNames();

    // Ensure selected accused is a valid option in the dropdown
    final dropdownItems = <String>{...availableAccused};
    if (_selectedCustodyAccused != null &&
        _selectedCustodyAccused!.isNotEmpty) {
      dropdownItems.add(_selectedCustodyAccused!);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
            onTap: () => setState(
                () => _custodySectionExpanded = !_custodySectionExpanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(AppRadius.lg),
              bottom:
                  Radius.circular(_custodySectionExpanded ? 0 : AppRadius.lg),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.navyMid.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.lock_clock_rounded,
                        size: 20, color: AppColors.navyMid),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Remand & Custody',
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
                  const SizedBox(width: 8),
                  Icon(
                    _custodySectionExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.lightSubText,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_custodySectionExpanded) ...[
            const Divider(height: 1, color: AppColors.lightBorder),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
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
                          borderSide:
                              const BorderSide(color: AppColors.lightBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide:
                              const BorderSide(color: AppColors.lightBorder),
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
                        ...dropdownItems.map((name) => DropdownMenuItem<String>(
                              value: name,
                              child: Row(
                                children: [
                                  const Icon(Icons.person_outline_rounded,
                                      size: 16, color: AppColors.navyMid),
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
                            color: AppColors.navyMid.withValues(alpha: 0.25)),
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
                                  color:
                                      AppColors.navyMid.withValues(alpha: 0.1),
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
                                    size: 18, color: AppColors.lightSubText),
                                tooltip: 'Cancel selection',
                                splashRadius: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 1. PCR Days
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
                                  fontSize: 12, color: AppColors.lightSubText),
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
                          const SizedBox(height: 14),

                          // 2. MCR Toggle Switch Container
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: _isMcr
                                    ? AppColors.navyMid.withValues(alpha: 0.4)
                                    : AppColors.lightBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.account_balance_rounded,
                                  size: 20,
                                  color: _isMcr
                                      ? AppColors.navyMid
                                      : AppColors.lightSubText,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'MCR',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.navyDark,
                                    ),
                                  ),
                                ),
                                Switch.adaptive(
                                  value: _isMcr,
                                  activeTrackColor: AppColors.navyMid,
                                  onChanged: (val) {
                                    setState(() {
                                      _isMcr = val;
                                      if (!val) {
                                        _isPrBond = false;
                                        _isBail = false;
                                        _isJail = false;
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),

                          // 3. MCR Sub-options: PR Bond, Bail, Jail
                          if (_isMcr) ...[
                            const SizedBox(height: 14),

                            // PR Bond Option
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                  color: _isPrBond
                                      ? AppColors.navyMid.withValues(alpha: 0.4)
                                      : AppColors.lightBorder,
                                ),
                              ),
                              child: Column(
                                children: [
                                  CheckboxListTile(
                                    value: _isPrBond,
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
                                        _isPrBond = v ?? false;
                                        if (_isPrBond &&
                                            _prBondDateCtrl.text.isEmpty) {
                                          _prBondDateCtrl.text =
                                              DateFormat('dd/MM/yyyy')
                                                  .format(DateTime.now());
                                        }
                                      });
                                    },
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                  ),
                                  if (_isPrBond)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          14, 0, 14, 14),
                                      child: _buildCustodyDatePicker(
                                        context: context,
                                        controller: _prBondDateCtrl,
                                        label: 'PR Bond Date',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Jail Option
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                border: Border.all(
                                  color: _isJail
                                      ? AppColors.navyMid.withValues(alpha: 0.4)
                                      : AppColors.lightBorder,
                                ),
                              ),
                              child: Column(
                                children: [
                                  CheckboxListTile(
                                    value: _isJail,
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
                                        _isJail = v ?? false;
                                        if (_isJail &&
                                            _jailDateCtrl.text.isEmpty) {
                                          _jailDateCtrl.text =
                                              DateFormat('dd/MM/yyyy')
                                                  .format(DateTime.now());
                                        }
                                      });
                                    },
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                  ),
                                  if (_isJail)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          14, 0, 14, 14),
                                      child: _buildCustodyDatePicker(
                                        context: context,
                                        controller: _jailDateCtrl,
                                        label: 'Jail Date',
                                      ),
                                    ),
                                ],
                              ),
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
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md)),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.check_circle_rounded,
                                    size: 18, color: Colors.white),
                                label: Text(
                                  _custodyRecordsList.any((r) =>
                                          r['name'] == _selectedCustodyAccused)
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
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md)),
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
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, idx) {
                        final it = _custodyRecordsList[idx];
                        final name =
                            it['name'] ?? it['person_name'] ?? 'Accused';
                        final pcr = it['pcr_days']?.toString() ?? '';
                        final isMcr = it['mcr'] == true;
                        final isPrBond = it['pr_bond'] == true;
                        final prBondDt = it['pr_bond_date']?.toString() ?? '';
                        final isBail = it['bail'] == true;
                        final suretyNm = it['surety_name']?.toString() ?? '';
                        final suretyRel =
                            it['surety_relation']?.toString() ?? '';
                        final suretyAge = it['surety_age']?.toString() ?? '';
                        final suretyGender =
                            it['surety_gender']?.toString() ?? '';
                        final suretyMob = it['surety_mobile']?.toString() ?? '';
                        final suretyAadhaar =
                            it['surety_aadhaar']?.toString() ?? '';
                        final suretyPan = it['surety_pan']?.toString() ?? '';
                        final suretyAddr =
                            it['surety_address']?.toString() ?? '';
                        final isJail = it['jail'] == true;
                        final jailDt = it['jail_date']?.toString() ?? '';

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.lightBorder),
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
                                          size: 18, color: AppColors.navyMid),
                                      tooltip: 'Edit record',
                                      splashRadius: 18,
                                      onPressed: () => _editCustodyRecord(idx),
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
        ],
      ),
    );
  }

  // ── Bail & Surety Card Widget (exact match with user's screenshot) ─────────
  Widget _buildBailOptionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isBail ? const Color(0xFF0EA5E9) : const Color(0xFFE2E8F0),
          width: _isBail ? 1.8 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bail Toggle Row (matches "(O) Bail" in user screenshot)
          InkWell(
            onTap: () {
              setState(() {
                _isBail = !_isBail;
                if (_isBail) {
                  _isMcr =
                      true; // Auto-activate MCR to satisfy legal constraint
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isBail
                            ? const Color(0xFF0EA5E9)
                            : const Color(0xFF94A3B8),
                        width: 2.0,
                      ),
                      color: _isBail ? Colors.white : Colors.transparent,
                    ),
                    child: _isBail
                        ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF0EA5E9),
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Bail',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isBail
                          ? AppColors.navyDark
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
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
      _custodySectionExpanded = true;
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
