// lib/widgets/dynamic_form/dynamic_form_screen.dart
// Single Source of Truth Dynamic Smart Form Screen driven by PostgreSQL Database.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../modules/core/models/base_record.dart';
import '../../providers/auth_provider.dart';
import '../../services/case_service.dart';
import '../../theme/app_theme.dart';
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

  // Discharged Accused state
  bool _dischargeSectionExpanded = true;
  String? _selectedAccusedToDischarge;
  final List<String> _dischargedAccusedList = [];
  final Map<String, bool> _dischargedAccusedMap = {};

  bool get isEdit => widget.existingRecord != null;

  @override
  void initState() {
    super.initState();
    _loadFormDefinition();
  }

  @override
  void dispose() {
    _triggerBDebounce?.cancel();
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
    final disList = common['discharges'] ?? extra['discharges'];
    if (disList is List) {
      for (final item in disList) {
        if (item is Map) {
          final n =
              (item['name'] ?? item['typed_name'])?.toString().trim() ?? '';
          if (n.isNotEmpty && !_dischargedAccusedList.contains(n)) {
            _dischargedAccusedList.add(n);
            _dischargedAccusedMap[n] = true;
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

    // Hydrate suspected accused
    final suspData = common['suspectedAccused'] ?? extra['suspectedAccused'];
    if (suspData is List && suspData.isNotEmpty) {
      final first = suspData.first;
      if (first is Map) {
        _setField('suspected_accused_name',
            first['name'] ?? first['suspected_accused_name']);
        _setField('suspected_accused_age',
            first['age'] ?? first['suspected_accused_age']);
        _setField('suspected_accused_gender',
            first['gender'] ?? first['suspected_accused_gender']);
        _setField(
            'suspected_accused_occupation',
            first['occupation'] ??
                first['occ'] ??
                first['suspected_accused_occupation']);
        _setField('suspected_accused_mobile',
            first['mobile'] ?? first['suspected_accused_mobile']);
        _setField('suspected_accused_aadhaar',
            first['aadhaar'] ?? first['suspected_accused_aadhaar']);
        _setField('suspected_accused_pan',
            first['pan'] ?? first['suspected_accused_pan']);
        _setField('suspected_accused_religion',
            first['religion'] ?? first['suspected_accused_religion']);
        _setField('suspected_accused_caste',
            first['caste'] ?? first['suspected_accused_caste']);
        _setField('suspected_accused_address',
            first['address'] ?? first['suspected_accused_address']);
      }
    }

    // Hydrate unknown accused
    final isUnk = common['is_unknown_accused'] ??
        common['isUnknownAccused'] ??
        common['isUnknownUntraced'] ??
        extra['is_unknown_accused'] ??
        extra['isUnknownAccused'] ??
        extra['isUnknownUntraced'];
    if (isUnk != null) {
      final b = isUnk == true || isUnk.toString().toLowerCase() == 'true';
      _setField('is_unknown_accused', b);
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

    final accused = _controllers['accused_name']?.text.trim() ??
        _controllers['accused']?.text.trim() ??
        '';

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
    final arrestedPerson = _controllers['arrested_person_name']?.text.trim() ??
        _values['arrested_person_name']?.toString().trim() ??
        '';
    final arrestsList = <Map<String, dynamic>>[];
    if (arrestedPerson.isNotEmpty) {
      arrestsList.add({
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
    final dischargesList = <Map<String, dynamic>>[];

    for (final name in _dischargedAccusedList) {
      final n = name.trim();
      if (n.isNotEmpty) {
        dischargeByAccused[n] = true;
        dischargesList.add({
          'name': n,
          'is_discharged': true,
        });
      }
    }

    final suspectedName = _controllers['suspected_accused_name']?.text.trim() ??
        _controllers['suspected_name']?.text.trim() ??
        '';
    final suspectedList = <Map<String, dynamic>>[];
    if (suspectedName.isNotEmpty) {
      suspectedList.add({
        'name': suspectedName,
        'age': _controllers['suspected_accused_age']?.text.trim(),
        'gender': _values['suspected_accused_gender'] ??
            _controllers['suspected_accused_gender']?.text.trim(),
        'occupation': _controllers['suspected_accused_occupation']?.text.trim(),
        'mobile': _controllers['suspected_accused_mobile']?.text.trim(),
        'aadhaar': _controllers['suspected_accused_aadhaar']?.text.trim(),
        'pan': _controllers['suspected_accused_pan']?.text.trim(),
        'religion': _controllers['suspected_accused_religion']?.text.trim(),
        'caste': _controllers['suspected_accused_caste']?.text.trim(),
        'address': _controllers['suspected_accused_address']?.text.trim(),
      });
    }

    final isUnknown = _values['is_unknown_accused'] == true ||
        _controllers['is_unknown_accused']?.text.toLowerCase() == 'true';
    allFormFields['is_unknown_accused'] = isUnknown;
    allFormFields['isUnknownAccused'] = isUnknown;
    allFormFields['isUnknownUntraced'] = isUnknown;

    // Build commonForm document map for full backward compatibility
    final commonFormDoc = <String, dynamic>{
      'crNo': caseNo,
      'charges': chargesMap,
      'spotAddress': loc,
      'complainant': {'name': complainant},
      'accused': [
        {'name': accused}
      ],
      'suspectedAccused': suspectedList,
      'isUnknownAccused': isUnknown,
      'is_unknown_accused': isUnknown,
      'isUnknownUntraced': isUnknown,
      'dischargeByAccused': dischargeByAccused,
      'discharges': dischargesList,
      'arrests': arrestsList,
      'dynamic_extra_fields': dynamicExtraVals,
      ...allFormFields,
    };

    final extraFields = Map<String, dynamic>.from(
      widget.existingRecord?.extraFields ?? {},
    );
    extraFields.addAll(allFormFields);
    extraFields['commonForm'] = commonFormDoc;
    extraFields['suspectedAccused'] = suspectedList;
    extraFields['is_unknown_accused'] = isUnknown;
    extraFields['isUnknownAccused'] = isUnknown;
    extraFields['isUnknownUntraced'] = isUnknown;
    extraFields['extra_field_values'] = dynamicExtraVals;
    extraFields['dischargeByAccused'] = dischargeByAccused;
    extraFields['discharges'] = dischargesList;
    extraFields['arrests'] = arrestsList;
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


  void _onDynamicFieldValueChanged(String k, dynamic v) {
    setState(() {
      _values[k] = v;
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
      'Bond',
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
      } else if (secKey == 'Discharge Accused') {
        sectionCards.add(_buildDischargeAccusedSection());
      } else if (secKey == 'Suspected Accused') {
        final secFields = (groupedBySection['Suspected Accused'] != null &&
                groupedBySection['Suspected Accused']!.isNotEmpty)
            ? groupedBySection['Suspected Accused']!
            : const [
                DynamicFieldDef(
                  fieldDefId: 9290,
                  fieldLabel: 'Name',
                  fieldKey: 'suspected_accused_name',
                  fieldSource: 'common',
                  fieldType: 'text',
                  isRequired: false,
                  section: 'Suspected Accused',
                  displayOrder: 290,
                ),
                DynamicFieldDef(
                  fieldDefId: 9300,
                  fieldLabel: 'Age',
                  fieldKey: 'suspected_accused_age',
                  fieldSource: 'common',
                  fieldType: 'number',
                  isRequired: false,
                  section: 'Suspected Accused',
                  displayOrder: 300,
                ),
                DynamicFieldDef(
                  fieldDefId: 9310,
                  fieldLabel: 'Gender',
                  fieldKey: 'suspected_accused_gender',
                  fieldSource: 'common',
                  fieldType: 'gender_toggle',
                  isRequired: false,
                  section: 'Suspected Accused',
                  displayOrder: 310,
                ),
                DynamicFieldDef(
                  fieldDefId: 9320,
                  fieldLabel: 'Occupation',
                  fieldKey: 'suspected_accused_occupation',
                  fieldSource: 'common',
                  fieldType: 'text',
                  isRequired: false,
                  section: 'Suspected Accused',
                  displayOrder: 320,
                ),
                DynamicFieldDef(
                  fieldDefId: 9330,
                  fieldLabel: 'Mobile Number',
                  fieldKey: 'suspected_accused_mobile',
                  fieldSource: 'common',
                  fieldType: 'text',
                  isRequired: false,
                  section: 'Suspected Accused',
                  displayOrder: 330,
                ),
                DynamicFieldDef(
                  fieldDefId: 9340,
                  fieldLabel: 'Aadhar Number',
                  fieldKey: 'suspected_accused_aadhaar',
                  fieldSource: 'common',
                  fieldType: 'text',
                  isRequired: false,
                  section: 'Suspected Accused',
                  displayOrder: 340,
                ),
                DynamicFieldDef(
                  fieldDefId: 9350,
                  fieldLabel: 'PAN Number',
                  fieldKey: 'suspected_accused_pan',
                  fieldSource: 'common',
                  fieldType: 'text',
                  isRequired: false,
                  section: 'Suspected Accused',
                  displayOrder: 350,
                ),
                DynamicFieldDef(
                  fieldDefId: 9360,
                  fieldLabel: 'Religion',
                  fieldKey: 'suspected_accused_religion',
                  fieldSource: 'common',
                  fieldType: 'text',
                  isRequired: false,
                  section: 'Suspected Accused',
                  displayOrder: 360,
                ),
                DynamicFieldDef(
                  fieldDefId: 9370,
                  fieldLabel: 'Caste',
                  fieldKey: 'suspected_accused_caste',
                  fieldSource: 'common',
                  fieldType: 'text',
                  isRequired: false,
                  section: 'Suspected Accused',
                  displayOrder: 370,
                ),
                DynamicFieldDef(
                  fieldDefId: 9380,
                  fieldLabel: 'Address',
                  fieldKey: 'suspected_accused_address',
                  fieldSource: 'common',
                  fieldType: 'textarea',
                  isRequired: false,
                  section: 'Suspected Accused',
                  displayOrder: 380,
                ),
              ];
        for (final f in secFields) {
          _controllers.putIfAbsent(f.fieldKey, () => TextEditingController());
        }
        sectionCards.add(
          DynamicSectionCard(
            title: 'Suspected Accused',
            icon: Icons.person_search_rounded,
            fields: secFields,
            controllers: _controllers,
            values: _values,
            onValueChanged: _onDynamicFieldValueChanged,
            readOnly: widget.readOnly,
            accusedOptions: accusedOptions,
            headerAction: widget.readOnly
                ? null
                : InkWell(
                    onTap: () {
                      setState(() {
                        _controllers['suspected_accused_name']?.text =
                            _controllers['accused_name']?.text ?? '';
                        _controllers['suspected_accused_age']?.text =
                            _controllers['accused_age']?.text ?? '';
                        _values['suspected_accused_gender'] =
                            _values['accused_gender'] ??
                                _controllers['accused_gender']?.text;
                        _controllers['suspected_accused_gender']?.text =
                            _controllers['accused_gender']?.text ?? '';
                        _controllers['suspected_accused_occupation']?.text =
                            _controllers['accused_occupation']?.text ?? '';
                        _controllers['suspected_accused_mobile']?.text =
                            _controllers['accused_mobile']?.text ?? '';
                        _controllers['suspected_accused_aadhaar']?.text =
                            _controllers['accused_aadhaar']?.text ?? '';
                        _controllers['suspected_accused_pan']?.text =
                            _controllers['accused_pan']?.text ?? '';
                        _controllers['suspected_accused_religion']?.text =
                            _controllers['accused_religion']?.text ?? '';
                        _controllers['suspected_accused_caste']?.text =
                            _controllers['accused_caste']?.text ?? '';
                        _controllers['suspected_accused_address']?.text =
                            _controllers['accused_address']?.text ?? '';
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.navyMid.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.navyMid.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.copy_rounded,
                            size: 11,
                            color: AppColors.navyMid,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Same as Accused',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navyMid,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        );
      } else if (secKey == 'Unidentified Accused') {
        final secFields = (groupedBySection['Unidentified Accused'] != null &&
                groupedBySection['Unidentified Accused']!.isNotEmpty)
            ? groupedBySection['Unidentified Accused']!
            : const [
                DynamicFieldDef(
                  fieldDefId: 770,
                  fieldLabel: 'Approximate Age',
                  fieldKey: 'approximate_age',
                  fieldSource: 'common',
                  fieldType: 'text',
                  isRequired: false,
                  section: 'Unidentified Accused',
                  displayOrder: 390,
                ),
                DynamicFieldDef(
                  fieldDefId: 771,
                  fieldLabel: 'Skin Colour',
                  fieldKey: 'skin_colour',
                  fieldSource: 'common',
                  fieldType: 'text',
                  isRequired: false,
                  section: 'Unidentified Accused',
                  displayOrder: 400,
                ),
                DynamicFieldDef(
                  fieldDefId: 772,
                  fieldLabel: 'Possible Occupation',
                  fieldKey: 'possible_occupation',
                  fieldSource: 'common',
                  fieldType: 'text',
                  isRequired: false,
                  section: 'Unidentified Accused',
                  displayOrder: 410,
                ),
                DynamicFieldDef(
                  fieldDefId: 773,
                  fieldLabel: 'Identification Mark',
                  fieldKey: 'identification_mark',
                  fieldSource: 'common',
                  fieldType: 'textarea',
                  isRequired: false,
                  section: 'Unidentified Accused',
                  displayOrder: 420,
                ),
                DynamicFieldDef(
                  fieldDefId: 774,
                  fieldLabel: 'Height',
                  fieldKey: 'height',
                  fieldSource: 'common',
                  fieldType: 'text',
                  isRequired: false,
                  section: 'Unidentified Accused',
                  displayOrder: 430,
                ),
                DynamicFieldDef(
                  fieldDefId: 775,
                  fieldLabel: 'Physical Description',
                  fieldKey: 'description',
                  fieldSource: 'common',
                  fieldType: 'textarea',
                  isRequired: false,
                  section: 'Unidentified Accused',
                  displayOrder: 440,
                ),
              ];
        for (final f in secFields) {
          _controllers.putIfAbsent(f.fieldKey, () => TextEditingController());
        }
        sectionCards.add(
          DynamicSectionCard(
            title: 'Unidentified Accused',
            icon: Icons.fingerprint_rounded,
            fields: secFields,
            controllers: _controllers,
            values: _values,
            onValueChanged: _onDynamicFieldValueChanged,
            readOnly: widget.readOnly,
            accusedOptions: accusedOptions,
          ),
        );
      } else if (secKey == 'Unknown Accused') {
        final secFields = (groupedBySection['Unknown Accused'] != null &&
                groupedBySection['Unknown Accused']!.isNotEmpty)
            ? groupedBySection['Unknown Accused']!
            : const [
                DynamicFieldDef(
                  fieldDefId: 744,
                  fieldLabel: 'Unknown Accused Involved (✓) / अज्ञात आरोपी',
                  fieldKey: 'is_unknown_accused',
                  fieldSource: 'common',
                  fieldType: 'checkbox',
                  isRequired: false,
                  section: 'Unknown Accused',
                  displayOrder: 445,
                ),
              ];
        for (final f in secFields) {
          _controllers.putIfAbsent(f.fieldKey, () => TextEditingController());
        }
        sectionCards.add(
          DynamicSectionCard(
            title: 'Unknown Accused',
            icon: Icons.help_outline_rounded,
            fields: secFields,
            controllers: _controllers,
            values: _values,
            onValueChanged: _onDynamicFieldValueChanged,
            readOnly: widget.readOnly,
            accusedOptions: accusedOptions,
          ),
        );
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

    // From current form controllers
    for (final entry in _controllers.entries) {
      final k = entry.key.toLowerCase();
      if ((k.contains('accused') || k.contains('suspect')) && !k.contains('discharge')) {
        addName(entry.value.text);
      }
    }

    // From current form values
    for (final entry in _values.entries) {
      final k = entry.key.toLowerCase();
      if ((k.contains('accused') || k.contains('suspect')) && !k.contains('discharge')) {
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
                  item['accused']?.toString());
            } else if (item is String) {
              addName(item);
            }
          }
        }
        final suspList = src['suspectedAccused'] ?? src['suspected_accused'] ?? src['suspects'];
        if (suspList is List) {
          for (final item in suspList) {
            if (item is Map) {
              addName(item['name']?.toString() ?? item['suspected_accused_name']?.toString() ?? item['suspect_name']?.toString());
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
              if (r == 'accused' || r == 'suspected_accused' || r == 'suspect') {
                addName(item['name']?.toString());
              }
            }
          }
        }
      }
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

                  // Display added discharged accused as clean chips
                  if (_dischargedAccusedList.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _dischargedAccusedList.map((accName) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_remove_rounded,
                                  size: 16, color: AppColors.dangerRed),
                              const SizedBox(width: 6),
                              Text(
                                accName,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.dangerRed,
                                ),
                              ),
                              if (!widget.readOnly) ...[
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _dischargedAccusedList.remove(accName);
                                      _dischargedAccusedMap[accName] = false;
                                    });
                                  },
                                  child: const Icon(Icons.close_rounded,
                                      size: 16, color: AppColors.dangerRed),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
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
