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
import 'dynamic_field_model.dart';
import 'dynamic_section_builder.dart';
import 'dynamic_control_factory.dart';

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
  final Set<String> _addedActs = {};
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
            _addedActs.add(act);
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
  }

  void _setField(String key, dynamic val) {
    if (val == null) return;
    if (_controllers.containsKey(key)) {
      _controllers[key]!.text = val.toString();
    }
    _values[key] = val;
  }

  void _onChargeSectionToggled(
      String actKey, String sectionNum, bool selected) {
    if (widget.readOnly) return;
    setState(() {
      final set = _selectedCharges.putIfAbsent(actKey, () => <String>{});
      if (selected) {
        set.add(sectionNum);
      } else {
        set.remove(sectionNum);
      }
    });

    // Trigger B: Debounced call to unlock extra section fields from database
    _triggerBDebounce?.cancel();
    _triggerBDebounce = Timer(const Duration(milliseconds: 300), () {
      final allSections = <String>[];
      for (final sSet in _selectedCharges.values) {
        allSections.addAll(sSet);
      }
      _loadFormDefinition(chargedSections: allSections);
    });
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

    // Build commonForm document map for full backward compatibility
    final commonFormDoc = <String, dynamic>{
      'crNo': caseNo,
      'charges': chargesMap,
      'spotAddress': loc,
      'complainant': {'name': complainant},
      'accused': [
        {'name': accused}
      ],
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
              'Database-Driven Smart Form Engine',
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
                  'DB SOURCE',
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
      final sec = f.section ?? 'Crime Registration Info';
      groupedBySection.putIfAbsent(sec, () => []).add(f);
    }

    final orderedSectionKeys = [
      'Crime Registration Info',
      'Acts & Sections Filed',
      'Crime Spot',
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
      'Evidence & Seizure',
      'Preventive Action',
      'Discharge Accused',
      'Scrutiny',
      'Court Filing and Final Summary',
    ];

    final accusedOptions = _getAvailableAccusedNames();
    final sectionCards = <Widget>[];

    int sectionIndex = 1;

    for (final secKey in orderedSectionKeys) {
      if (secKey == 'Acts & Sections Filed') {
        sectionCards.add(_buildLegalChargesSection(sectionIndex++));
      } else if (secKey == 'Accused') {
        sectionCards.add(
          _AccusedBlock(
            index: sectionIndex++,
            values: _values,
            onValueChanged: (k, v) => setState(() => _values[k] = v),
            readOnly: widget.readOnly,
          ),
        );
      } else if (secKey == 'Discharge Accused') {
        sectionCards.add(_buildDischargeAccusedSection(sectionIndex++));
      } else if (secKey == 'Suspected Accused') {
        sectionCards.add(
          _SuspectedAccusedBlock(
            index: sectionIndex++,
            values: _values,
            onValueChanged: (k, v) => setState(() => _values[k] = v),
            readOnly: widget.readOnly,
          ),
        );
      } else if (secKey == 'Unidentified Accused') {
        sectionCards.add(
          _UnidentifiedAccusedBlock(
            index: sectionIndex++,
            values: _values,
            onValueChanged: (k, v) => setState(() => _values[k] = v),
            readOnly: widget.readOnly,
          ),
        );
      } else if (secKey == 'Unknown Accused') {
        sectionCards.add(
          DynamicSectionCard(
            index: sectionIndex++,
            title: secKey,
            icon: _iconForSection(secKey),
            fields: [
              DynamicFieldDef(
                  fieldDefId: -1,
                  fieldKey: 'is_unknown_accused',
                  fieldLabel: 'Unknown Accused',
                  fieldSource: 'common',
                  fieldType: 'checkbox',
                  isRequired: false,
                  displayOrder: 1)
            ],
            controllers: _controllers,
            values: _values,
            onValueChanged: (k, v) => setState(() => _values[k] = v),
            readOnly: widget.readOnly,
          ),
        );
      } else if (secKey == 'Arrest') {
        sectionCards.add(
          DynamicSectionCard(
            index: sectionIndex++,
            title: secKey,
            icon: _iconForSection(secKey),
            fields: const [],
            controllers: _controllers,
            values: _values,
            onValueChanged: (k, v) => setState(() => _values[k] = v),
            readOnly: widget.readOnly,
            isCollapsible: false,
            customBody: accusedOptions.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: accusedOptions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final name = entry.value;
                        final suffix = index == 0 ? '' : '_$index';

                        return _ArrestPerAccusedBlock(
                          accusedName: name,
                          suffix: suffix,
                          controllers: _controllers,
                          values: _values,
                          onValueChanged: (k, v) =>
                              setState(() => _values[k] = v),
                          readOnly: widget.readOnly,
                        );
                      }).toList(),
                    ),
                  ),
          ),
        );
      } else if (secKey == 'Remand & Custody') {
        sectionCards.add(
          DynamicSectionCard(
            index: sectionIndex++,
            title: secKey,
            icon: _iconForSection(secKey),
            fields: const [],
            controllers: _controllers,
            values: _values,
            onValueChanged: (k, v) => setState(() => _values[k] = v),
            readOnly: widget.readOnly,
            isCollapsible: false,
            customBody: accusedOptions.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: accusedOptions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final name = entry.value;
                        final suffix = index == 0 ? '' : '_$index';

                        return _CustodyPerAccusedBlock(
                          accusedName: name,
                          suffix: suffix,
                          controllers: _controllers,
                          values: _values,
                          onValueChanged: (k, v) =>
                              setState(() => _values[k] = v),
                          readOnly: widget.readOnly,
                        );
                      }).toList(),
                    ),
                  ),
          ),
        );
      } else if (secKey == 'All Panchnama') {
        final secFields = groupedBySection[secKey];
        if (secFields != null && secFields.isNotEmpty) {
          sectionCards.add(
            DynamicSectionCard(
              index: sectionIndex++,
              title: secKey,
              icon: _iconForSection(secKey),
              fields: const [],
              controllers: _controllers,
              values: _values,
              onValueChanged: (k, v) => setState(() => _values[k] = v),
              readOnly: widget.readOnly,
              isCollapsible: true,
              customBody: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: secFields.map((field) {
                    return _buildPanchnamaCheckbox(field);
                  }).toList(),
                ),
              ),
            ),
          );
        }
      } else if (secKey == 'Evidence & Seizure') {
        sectionCards.add(
          DynamicSectionCard(
            index: sectionIndex++,
            title: secKey,
            icon: Icons.biotech_rounded,
            fields: const [],
            controllers: _controllers,
            values: _values,
            onValueChanged: (k, v) => setState(() => _values[k] = v),
            readOnly: widget.readOnly,
            isCollapsible: true,
            customBody: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: _EvidenceAndSeizureBlock(
                controllers: _controllers,
                values: _values,
                onValueChanged: (k, v) => setState(() => _values[k] = v),
                readOnly: widget.readOnly,
                accusedOptions: accusedOptions,
              ),
            ),
          ),
        );
      } else if (secKey == 'Preventive Action') {
        final preventiveFields = [
          DynamicFieldDef(
              fieldDefId: -1,
              fieldKey: 'preventive_action_type',
              fieldLabel: 'Preventive Action Type',
              fieldSource: 'common',
              fieldType: 'dropdown',
              isRequired: false,
              options: [
                '107 Crpc /126 BNSS',
                '109Crpc /128 BNSS',
                '110 Crpc/129 BNSS',
                '151(3)Crpc/170 BNSS',
                '144 Crpc/163 BNSS',
                '149 Crpc/168 BNSS',
                '55 MPA',
                '56 MPA',
                '57 MPA',
                '122 MPA',
                '93 prohibition act'
              ],
              displayOrder: 1),
          DynamicFieldDef(
              fieldDefId: -1,
              fieldKey: 'preventive_action_date',
              fieldLabel: 'Preventive Action Date',
              fieldSource: 'common',
              fieldType: 'date',
              isRequired: true,
              displayOrder: 2),
          DynamicFieldDef(
              fieldDefId: -1,
              fieldKey: 'preventive_action_outward_no',
              fieldLabel: 'Preventive Action Outward No',
              fieldSource: 'common',
              fieldType: 'text',
              isRequired: false,
              displayOrder: 3),
          DynamicFieldDef(
              fieldDefId: -1,
              fieldKey: 'bond_date',
              fieldLabel: 'Bond date',
              fieldSource: 'common',
              fieldType: 'date',
              isRequired: false,
              displayOrder: 4),
          DynamicFieldDef(
              fieldDefId: -1,
              fieldKey: 'bond_cancellation_date',
              fieldLabel: 'Bond cancellation date',
              fieldSource: 'common',
              fieldType: 'date',
              isRequired: false,
              displayOrder: 5),
        ];

        for (final f in preventiveFields) {
          _controllers.putIfAbsent(
              f.fieldKey,
              () => TextEditingController(
                  text: _values[f.fieldKey]?.toString() ?? ''));
        }

        sectionCards.add(
          DynamicSectionCard(
            index: sectionIndex++,
            title: secKey,
            icon: Icons.shield_rounded,
            fields: preventiveFields,
            controllers: _controllers,
            values: _values,
            onValueChanged: (k, v) => setState(() => _values[k] = v),
            readOnly: widget.readOnly,
          ),
        );
      } else if (secKey == 'Scrutiny') {
        sectionCards.add(
          _ScrutinyBlock(
            index: sectionIndex++,
            values: _values,
            onValueChanged: (k, v) => setState(() => _values[k] = v),
            readOnly: widget.readOnly,
          ),
        );
      } else if (secKey == 'Court Filing and Final Summary') {
        final courtFilingFields = [
          DynamicFieldDef(
              fieldDefId: -1,
              fieldKey: 'charge_sheet_no',
              fieldLabel: 'Charge Sheet No',
              fieldSource: 'common',
              fieldType: 'text',
              isRequired: false,
              displayOrder: 1),
          DynamicFieldDef(
              fieldDefId: -1,
              fieldKey: 'charge_sheet_date',
              fieldLabel: 'Charge Sheet Date',
              fieldSource: 'common',
              fieldType: 'date',
              isRequired: false,
              displayOrder: 2),
          DynamicFieldDef(
              fieldDefId: -1,
              fieldKey: 'a_final_number',
              fieldLabel: 'A Final Number',
              fieldSource: 'common',
              fieldType: 'text',
              isRequired: false,
              displayOrder: 3),
          DynamicFieldDef(
              fieldDefId: -1,
              fieldKey: 'b_final_number',
              fieldLabel: 'B Final Number',
              fieldSource: 'common',
              fieldType: 'text',
              isRequired: false,
              displayOrder: 4),
          DynamicFieldDef(
              fieldDefId: -1,
              fieldKey: 'c_final_number',
              fieldLabel: 'C Final Number',
              fieldSource: 'common',
              fieldType: 'text',
              isRequired: false,
              displayOrder: 5),
          DynamicFieldDef(
              fieldDefId: -1,
              fieldKey: 'nc_final_number',
              fieldLabel: 'NC Final Number',
              fieldSource: 'common',
              fieldType: 'text',
              isRequired: false,
              displayOrder: 6),
          DynamicFieldDef(
              fieldDefId: -1,
              fieldKey: 'cc_st_number',
              fieldLabel: 'CC / ST Number',
              fieldSource: 'common',
              fieldType: 'full_text',
              isRequired: false,
              displayOrder: 7),
          DynamicFieldDef(
              fieldDefId: -1,
              fieldKey: 'abeted_summary_no',
              fieldLabel: 'Abeted summary no.',
              fieldSource: 'common',
              fieldType: 'full_text',
              isRequired: false,
              displayOrder: 8),
          DynamicFieldDef(
              fieldDefId: -1,
              fieldKey: 'stay_by_high_court_date',
              fieldLabel: 'Stay by High Court Date',
              fieldSource: 'common',
              fieldType: 'date',
              isRequired: false,
              displayOrder: 9),
          DynamicFieldDef(
              fieldDefId: -1,
              fieldKey: 'quashed_by_high_court_date',
              fieldLabel: 'Quashed by High Court',
              fieldSource: 'common',
              fieldType: 'date',
              isRequired: false,
              displayOrder: 10),
        ];

        for (final f in courtFilingFields) {
          _controllers.putIfAbsent(
              f.fieldKey,
              () => TextEditingController(
                  text: _values[f.fieldKey]?.toString() ?? ''));
        }

        sectionCards.add(
          DynamicSectionCard(
            index: sectionIndex++,
            title: 'Court Filing & Final Summary',
            icon: Icons.gavel_rounded,
            fields: courtFilingFields,
            controllers: _controllers,
            values: _values,
            onValueChanged: (k, v) => setState(() => _values[k] = v),
            readOnly: widget.readOnly,
          ),
        );
      } else {
        final secFields = groupedBySection[secKey];
        if (secFields != null && secFields.isNotEmpty) {
          sectionCards.add(
            DynamicSectionCard(
              index: sectionIndex++,
              title: secKey,
              icon: _iconForSection(secKey),
              fields: secFields,
              controllers: _controllers,
              values: _values,
              onValueChanged: (k, v) => setState(() => _values[k] = v),
              readOnly: widget.readOnly,
              accusedOptions: accusedOptions,
            ),
          );
        }
      }
    }

    // Append any extra/unmapped sections from DB that were not in standard list
    for (final entry in groupedBySection.entries) {
      if (!orderedSectionKeys.contains(entry.key) &&
          entry.value.isNotEmpty &&
          entry.key != 'Evidence' &&
          entry.key != 'Seizure Records' &&
          entry.key != 'Bond') {
        sectionCards.add(
          DynamicSectionCard(
            index: sectionIndex++,
            title: entry.key,
            icon: _iconForSection(entry.key),
            fields: entry.value,
            controllers: _controllers,
            values: _values,
            onValueChanged: (k, v) => setState(() => _values[k] = v),
            readOnly: widget.readOnly,
            accusedOptions: accusedOptions,
          ),
        );
      }
    }

    return Center(
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Form(
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
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg)),
                        ),
                        icon: const Icon(Icons.check_circle_rounded,
                            color: Colors.white),
                        label: Text(
                          isEdit
                              ? 'Update Case Record'
                              : 'Submit Case to Database',
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
            )));
  }

  void _showAddActDialog(Map actsMap) {
    if (widget.readOnly) return;

    final Set<String> tempAddedActs = Set.from(_addedActs);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Select Acts',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 16),
              ),
              content: SizedBox(
                width: 400,
                child: ListView(
                  shrinkWrap: true,
                  children: actsMap.entries.map((entry) {
                    final actKey = entry.key;
                    final actData = entry.value as Map<String, dynamic>;
                    final actLabel = actData['label']?.toString() ?? actKey;
                    return CheckboxListTile(
                      title: Text(actLabel,
                          style: GoogleFonts.poppins(fontSize: 13)),
                      value: tempAddedActs.contains(actKey),
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            tempAddedActs.add(actKey);
                          } else {
                            tempAddedActs.remove(actKey);
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel',
                      style:
                          GoogleFonts.poppins(color: AppColors.lightSubText)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _addedActs.clear();
                      _addedActs.addAll(tempAddedActs);
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyMid),
                  child: Text('Add Selected',
                      style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLegalChargesSection(int index) {
    final actsMap = _formDef?.actsSections ?? {};

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
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyMid,
                  ),
                ),
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
              if (!widget.readOnly)
                TextButton.icon(
                  onPressed: () => _showAddActDialog(actsMap),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text('Add Act',
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.navyMid,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
          const Divider(height: 24, color: AppColors.lightBorder),
          if (actsMap.isEmpty)
            Text(
              'No Acts loaded from database.',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.lightSubText),
            )
          else if (_addedActs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No acts added. Click "+ Add Act" to select acts.',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.lightSubText),
                ),
              ),
            )
          else
            ...actsMap.entries
                .where((entry) => _addedActs.contains(entry.key))
                .map((entry) {
              final actKey = entry.key;
              final actData = entry.value as Map<String, dynamic>;
              final actLabel = actData['label']?.toString() ?? actKey;
              final sections = (actData['sections'] is List)
                  ? actData['sections'] as List
                  : [];
              final selectedSet = _selectedCharges[actKey] ?? <String>{};

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.lightBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      actLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyMid,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: sections.map((sec) {
                        final secVal = (sec is Map)
                            ? sec['val']?.toString() ?? ''
                            : sec.toString();
                        final secLabel = (sec is Map)
                            ? sec['label']?.toString() ?? secVal
                            : secVal;
                        final isSelected = selectedSet.contains(secVal);

                        return FilterChip(
                          label: Text(secLabel),
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color:
                                isSelected ? Colors.white : AppColors.lightText,
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.navyMid,
                          backgroundColor: Colors.white,
                          onSelected: widget.readOnly
                              ? null
                              : (sel) =>
                                  _onChargeSectionToggled(actKey, secVal, sel),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }),
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
      if (k.contains('accused') && !k.contains('discharge')) {
        addName(entry.value.text);
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
        final suspList = src['suspectedAccused'];
        if (suspList is List) {
          for (final item in suspList) {
            if (item is Map) {
              addName(item['name']?.toString());
            } else if (item is String) {
              addName(item);
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

  Widget _buildDischargeAccusedSection(int index) {
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
                    alignment: Alignment.center,
                    child: Text(
                      '$index',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyMid,
                      ),
                    ),
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
                  if (availableAccused.isEmpty)
                    Text(
                      'No accused entered yet in form',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.lightSubText),
                    )
                  else
                    ...availableAccused.map((accName) {
                      final isChecked =
                          _dischargedAccusedList.contains(accName);
                      return CheckboxListTile(
                        value: isChecked,
                        onChanged: widget.readOnly
                            ? null
                            : (val) {
                                setState(() {
                                  if (val == true) {
                                    if (!_dischargedAccusedList
                                        .contains(accName)) {
                                      _dischargedAccusedList.add(accName);
                                    }
                                    _dischargedAccusedMap[accName] = true;
                                  } else {
                                    _dischargedAccusedList.remove(accName);
                                    _dischargedAccusedMap[accName] = false;
                                  }
                                });
                              },
                        title: Text(
                          accName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.navyDark,
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        activeColor: AppColors.navyMid,
                        checkColor: Colors.white,
                        visualDensity:
                            const VisualDensity(horizontal: -4, vertical: -4),
                      );
                    }),
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

  Widget _buildPanchnamaCheckbox(DynamicFieldDef field) {
    final isChecked = (_values[field.fieldKey] == true) ||
        (_controllers[field.fieldKey]?.text.toLowerCase() == 'true') ||
        (_controllers[field.fieldKey]?.text.toLowerCase() == 'yes');

    final dateKey = '${field.fieldKey}_datetime';
    _controllers.putIfAbsent(dateKey,
        () => TextEditingController(text: _values[dateKey]?.toString() ?? ''));

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isChecked ? const Color(0xFFF0F9FF) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isChecked ? const Color(0xFF0288D1) : const Color(0xFFE2E8F0),
          width: isChecked ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isChecked,
            activeColor: const Color(0xFF0288D1),
            onChanged: widget.readOnly
                ? null
                : (newVal) {
                    final b = newVal ?? false;
                    setState(() {
                      _values[field.fieldKey] = b;
                      _controllers[field.fieldKey]?.text = b.toString();
                    });
                  },
          ),
          const SizedBox(width: 8),
          if (isChecked)
            Text(
              field.fieldLabel,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0288D1),
              ),
            )
          else
            Expanded(
              child: Text(
                field.fieldLabel,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
          if (isChecked) ...[
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 38,
                child: TextFormField(
                  controller: _controllers[dateKey],
                  readOnly: true,
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: const Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    hintText: 'Date & Time',
                    hintStyle: GoogleFonts.poppins(
                        fontSize: 12, color: const Color(0xFF94A3B8)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    suffixIcon: const Icon(Icons.access_time_rounded,
                        size: 16, color: Color(0xFF0288D1)),
                    filled: true,
                    fillColor: widget.readOnly
                        ? const Color(0xFFF8FAFC)
                        : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(
                          color: Color(0xFF0288D1), width: 1.2),
                    ),
                  ),
                  onTap: widget.readOnly
                      ? null
                      : () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1970),
                            lastDate: DateTime(2050),
                          );
                          if (pickedDate != null) {
                            if (!mounted) return;
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (pickedTime != null) {
                              final dt = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                              final val =
                                  DateFormat('dd/MM/yyyy HH:mm').format(dt);
                              setState(() {
                                _controllers[dateKey]?.text = val;
                                _values[dateKey] = val;
                              });
                            }
                          }
                        },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ArrestPerAccusedBlock extends StatefulWidget {
  final String accusedName;
  final String suffix;
  final Map<String, TextEditingController> controllers;
  final Map<String, dynamic> values;
  final Function(String, dynamic) onValueChanged;
  final bool readOnly;

  const _ArrestPerAccusedBlock({
    Key? key,
    required this.accusedName,
    required this.suffix,
    required this.controllers,
    required this.values,
    required this.onValueChanged,
    required this.readOnly,
  }) : super(key: key);

  @override
  State<_ArrestPerAccusedBlock> createState() => _ArrestPerAccusedBlockState();
}

class _ArrestPerAccusedBlockState extends State<_ArrestPerAccusedBlock> {
  bool _expanded = true;

  String get kArrestDateTime => 'arrest_arrest_datetime${widget.suffix}';
  String get kSec47 => 'arrest_sec_47_48_bnss${widget.suffix}';
  String get kRelName => 'arrest_relative_friend_name${widget.suffix}';
  String get kRelRelation => 'arrest_relative_friend_relation${widget.suffix}';
  String get kRelease => 'arrest_release_on_notice${widget.suffix}';
  String get kAnticipatory => 'arrest_anticipatory_bail${widget.suffix}';
  String get kDeath => 'arrest_death_of_accused${widget.suffix}';

  @override
  void initState() {
    super.initState();
    for (final k in [kArrestDateTime, kRelName, kRelRelation]) {
      widget.controllers.putIfAbsent(
          k,
          () =>
              TextEditingController(text: widget.values[k]?.toString() ?? ''));
    }
    for (final k in [kSec47, kRelease, kAnticipatory, kDeath]) {
      widget.values.putIfAbsent(k, () => false);
    }
  }

  void _onRadioChanged(String selectedKey) {
    setState(() {
      widget.values[kRelease] = (selectedKey == kRelease);
      widget.values[kAnticipatory] = (selectedKey == kAnticipatory);
      widget.values[kDeath] = (selectedKey == kDeath);

      widget.onValueChanged(kRelease, widget.values[kRelease]);
      widget.onValueChanged(kAnticipatory, widget.values[kAnticipatory]);
      widget.onValueChanged(kDeath, widget.values[kDeath]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFE1F5FE),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(11),
                    topRight: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFF0288D1), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Accused: ${widget.accusedName}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0288D1),
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFF0288D1),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DynamicControlFactory(
                    fieldDef: DynamicFieldDef(
                      fieldDefId: -1,
                      fieldKey: kArrestDateTime,
                      fieldLabel: 'Arrest Date & Time (dd/mm/yyyy hh:mm)',
                      fieldSource: 'common',
                      fieldType: 'datetime',
                      isRequired: false,
                      displayOrder: 1,
                    ),
                    controller: widget.controllers[kArrestDateTime],
                    value: widget.values[kArrestDateTime],
                    onChanged: (v) => widget.onValueChanged(kArrestDateTime, v),
                    readOnly: widget.readOnly,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Information of arrest',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCheckbox('sec. 47/48 BNSS', kSec47),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DynamicControlFactory(
                          fieldDef: DynamicFieldDef(
                            fieldDefId: -1,
                            fieldKey: kRelName,
                            fieldLabel: 'Relative or friend name',
                            fieldSource: 'common',
                            fieldType: 'text',
                            isRequired: false,
                            displayOrder: 3,
                          ),
                          controller: widget.controllers[kRelName],
                          value: widget.values[kRelName],
                          onChanged: (v) => widget.onValueChanged(kRelName, v),
                          readOnly: widget.readOnly,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DynamicControlFactory(
                          fieldDef: DynamicFieldDef(
                            fieldDefId: -1,
                            fieldKey: kRelRelation,
                            fieldLabel: 'Relation',
                            fieldSource: 'common',
                            fieldType: 'dropdown',
                            isRequired: false,
                            displayOrder: 4,
                            options: const [
                              'Father',
                              'Mother',
                              'Brother',
                              'Sister',
                              'Spouse',
                              'Friend',
                              'Other'
                            ],
                          ),
                          controller: widget.controllers[kRelRelation],
                          value: widget.values[kRelRelation],
                          onChanged: (v) =>
                              widget.onValueChanged(kRelRelation, v),
                          readOnly: widget.readOnly,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildRadioButton('Release on notice (✓)', kRelease),
                  const SizedBox(height: 8),
                  _buildRadioButton('Anticipatory bail (✓)', kAnticipatory),
                  const SizedBox(height: 8),
                  _buildRadioButton('Death of Accused (✓)', kDeath),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRadioButton(String label, String key) {
    final isSelected = widget.values[key] == true;
    return InkWell(
      onTap: widget.readOnly ? null : () => _onRadioChanged(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? const Color(0xFF0288D1)
                  : const Color(0xFF94A3B8),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox(String label, String key) {
    final isSelected = widget.values[key] == true;
    return InkWell(
      onTap: widget.readOnly
          ? null
          : () {
              setState(() {
                widget.values[key] = !isSelected;
                widget.onValueChanged(key, widget.values[key]);
              });
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              color: isSelected
                  ? const Color(0xFF0288D1)
                  : const Color(0xFF94A3B8),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustodyPerAccusedBlock extends StatefulWidget {
  final String accusedName;
  final String suffix;
  final Map<String, TextEditingController> controllers;
  final Map<String, dynamic> values;
  final Function(String, dynamic) onValueChanged;
  final bool readOnly;

  const _CustodyPerAccusedBlock({
    super.key,
    required this.accusedName,
    required this.suffix,
    required this.controllers,
    required this.values,
    required this.onValueChanged,
    required this.readOnly,
  });

  @override
  State<_CustodyPerAccusedBlock> createState() =>
      _CustodyPerAccusedBlockState();
}

class _CustodyPerAccusedBlockState extends State<_CustodyPerAccusedBlock> {
  bool _expanded = false;

  late String kPcrDay;
  late String kMcr;
  late String kPrBond;
  late String kJail;
  late String kBail;
  late String kCustodyDate;

  late String kSuretyName;
  late String kSuretyAge;
  late String kSuretyGender;
  late String kSuretyOccupation;
  late String kSuretyMobile;
  late String kSuretyAadhaar;
  late String kSuretyPan;
  late String kSuretyAddress;
  late String kSuretyRelation;

  @override
  void initState() {
    super.initState();
    kPcrDay = 'custody_pcr_day${widget.suffix}';
    kMcr = 'custody_mcr${widget.suffix}';
    kPrBond = 'custody_pr_bond${widget.suffix}';
    kJail = 'custody_jail${widget.suffix}';
    kBail = 'custody_bail${widget.suffix}';
    kCustodyDate = 'custody_date${widget.suffix}';

    kSuretyName = 'custody_surety_name${widget.suffix}';
    kSuretyAge = 'custody_surety_age${widget.suffix}';
    kSuretyGender = 'custody_surety_gender${widget.suffix}';
    kSuretyOccupation = 'custody_surety_occupation${widget.suffix}';
    kSuretyMobile = 'custody_surety_mobile${widget.suffix}';
    kSuretyAadhaar = 'custody_surety_aadhaar${widget.suffix}';
    kSuretyPan = 'custody_surety_pan${widget.suffix}';
    kSuretyAddress = 'custody_surety_address${widget.suffix}';
    kSuretyRelation = 'custody_surety_relation${widget.suffix}';

    _ensureController(kPcrDay);
    _ensureController(kCustodyDate);
    _ensureController(kSuretyName);
    _ensureController(kSuretyAge);
    _ensureController(kSuretyOccupation);
    _ensureController(kSuretyMobile);
    _ensureController(kSuretyAadhaar);
    _ensureController(kSuretyPan);
    _ensureController(kSuretyAddress);

    // Default bail
    if (widget.values[kPrBond] == null &&
        widget.values[kJail] == null &&
        widget.values[kBail] == null) {
      widget.values[kBail] = false;
    }
  }

  void _ensureController(String key) {
    if (!widget.controllers.containsKey(key)) {
      widget.controllers[key] =
          TextEditingController(text: widget.values[key]?.toString() ?? '');
    }
  }

  void _onRadioChanged(String selectedKey) {
    setState(() {
      widget.values[kPrBond] = (selectedKey == kPrBond);
      widget.values[kJail] = (selectedKey == kJail);
      widget.values[kBail] = (selectedKey == kBail);

      widget.onValueChanged(kPrBond, widget.values[kPrBond]);
      widget.onValueChanged(kJail, widget.values[kJail]);
      widget.onValueChanged(kBail, widget.values[kBail]);
    });
  }

  Widget _buildRadioButton(String label, String key) {
    final isSelected = widget.values[key] == true;
    final showDate = isSelected && (key == kPrBond || key == kJail);

    return InkWell(
      onTap: widget.readOnly ? null : () => _onRadioChanged(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F9FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF0288D1) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? const Color(0xFF0288D1)
                  : const Color(0xFF94A3B8),
              size: 20,
            ),
            const SizedBox(width: 12),
            if (showDate)
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF0288D1)
                      : const Color(0xFF475569),
                ),
              )
            else
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF0288D1)
                        : const Color(0xFF475569),
                  ),
                ),
              ),
            if (showDate) ...[
              const SizedBox(width: 16),
              Expanded(
                child: _buildCompactDate(kCustodyDate),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactDate(String key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Date (dd/mm/yyyy)',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 38, // very compact
          child: TextFormField(
            controller: widget.controllers[key],
            readOnly: true,
            style: GoogleFonts.poppins(
                fontSize: 13, color: const Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: 'DD/MM/YYYY',
              hintStyle: GoogleFonts.poppins(
                  fontSize: 12, color: const Color(0xFF94A3B8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              suffixIcon: const Icon(Icons.calendar_today_rounded,
                  size: 16, color: Color(0xFF0288D1)),
              filled: true,
              fillColor:
                  widget.readOnly ? const Color(0xFFF8FAFC) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide:
                    const BorderSide(color: Color(0xFF0288D1), width: 1.2),
              ),
            ),
            onTap: widget.readOnly
                ? null
                : () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1970),
                      lastDate: DateTime(2050),
                    );
                    if (picked != null) {
                      final val = DateFormat('dd/MM/yyyy').format(picked);
                      widget.controllers[key]?.text = val;
                      widget.onValueChanged(key, val);
                    }
                  },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBailSelected = widget.values[kBail] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(11),
                    topRight: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Color(0xFF475569), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.accusedName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFF475569),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 1,
                        child: DynamicControlFactory(
                          fieldDef: DynamicFieldDef(
                            fieldDefId: -1,
                            fieldKey: kPcrDay,
                            fieldLabel: 'PCR (00 Day)',
                            fieldSource: 'common',
                            fieldType: 'text',
                            isRequired: false,
                            displayOrder: 1,
                          ),
                          controller: widget.controllers[kPcrDay],
                          value: widget.values[kPcrDay],
                          onChanged: (v) => widget.onValueChanged(kPcrDay, v),
                          readOnly: widget.readOnly,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.only(top: 8),
                          child: InkWell(
                            onTap: widget.readOnly
                                ? null
                                : () {
                                    final current = widget.values[kMcr] == true;
                                    widget.values[kMcr] = !current;
                                    widget.onValueChanged(kMcr, !current);
                                    setState(() {});
                                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: widget.values[kMcr] == true
                                    ? const Color(0xFFF0F9FF)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: widget.values[kMcr] == true
                                      ? const Color(0xFF0288D1)
                                      : const Color(0xFFE2E8F0),
                                  width: widget.values[kMcr] == true ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    widget.values[kMcr] == true
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                    color: widget.values[kMcr] == true
                                        ? const Color(0xFF0288D1)
                                        : const Color(0xFF94A3B8),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'MCR',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Visibility(
                    visible: widget.values[kMcr] == true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildRadioButton('PR bond', kPrBond),
                        const SizedBox(height: 8),
                        _buildRadioButton('Jail', kJail),
                        const SizedBox(height: 8),
                        _buildRadioButton('Bail', kBail),
                        if (isBailSelected)
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFFBBE1FA), width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SURETY NAME',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                DynamicControlFactory(
                                  fieldDef: DynamicFieldDef(
                                    fieldDefId: -1,
                                    fieldKey: kSuretyName,
                                    fieldLabel: 'Surety Name',
                                    fieldSource: 'common',
                                    fieldType: 'text',
                                    isRequired: false,
                                    displayOrder: 1,
                                  ),
                                  controller: widget.controllers[kSuretyName],
                                  value: widget.values[kSuretyName],
                                  onChanged: (v) =>
                                      widget.onValueChanged(kSuretyName, v),
                                  readOnly: widget.readOnly,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DynamicControlFactory(
                                        fieldDef: DynamicFieldDef(
                                          fieldDefId: -1,
                                          fieldKey: kSuretyAge,
                                          fieldLabel: 'Surety Age',
                                          fieldSource: 'common',
                                          fieldType: 'text',
                                          isRequired: false,
                                          displayOrder: 2,
                                        ),
                                        controller:
                                            widget.controllers[kSuretyAge],
                                        value: widget.values[kSuretyAge],
                                        onChanged: (v) => widget.onValueChanged(
                                            kSuretyAge, v),
                                        readOnly: widget.readOnly,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: DynamicControlFactory(
                                        fieldDef: DynamicFieldDef(
                                          fieldDefId: -1,
                                          fieldKey: kSuretyGender,
                                          fieldLabel: 'Surety Gender',
                                          fieldSource: 'common',
                                          fieldType: 'gender_toggle',
                                          isRequired: false,
                                          displayOrder: 3,
                                        ),
                                        controller: null,
                                        value: widget.values[kSuretyGender],
                                        onChanged: (v) => widget.onValueChanged(
                                            kSuretyGender, v),
                                        readOnly: widget.readOnly,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DynamicControlFactory(
                                        fieldDef: DynamicFieldDef(
                                          fieldDefId: -1,
                                          fieldKey: kSuretyOccupation,
                                          fieldLabel: 'Surety Occupation',
                                          fieldSource: 'common',
                                          fieldType: 'text',
                                          isRequired: false,
                                          displayOrder: 4,
                                        ),
                                        controller: widget
                                            .controllers[kSuretyOccupation],
                                        value: widget.values[kSuretyOccupation],
                                        onChanged: (v) => widget.onValueChanged(
                                            kSuretyOccupation, v),
                                        readOnly: widget.readOnly,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: DynamicControlFactory(
                                        fieldDef: DynamicFieldDef(
                                          fieldDefId: -1,
                                          fieldKey: kSuretyMobile,
                                          fieldLabel: 'Surety Mobile No.',
                                          fieldSource: 'common',
                                          fieldType: 'text',
                                          isRequired: false,
                                          displayOrder: 5,
                                        ),
                                        controller:
                                            widget.controllers[kSuretyMobile],
                                        value: widget.values[kSuretyMobile],
                                        onChanged: (v) => widget.onValueChanged(
                                            kSuretyMobile, v),
                                        readOnly: widget.readOnly,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DynamicControlFactory(
                                        fieldDef: DynamicFieldDef(
                                          fieldDefId: -1,
                                          fieldKey: kSuretyAadhaar,
                                          fieldLabel: 'Surety Aadhaar No.',
                                          fieldSource: 'common',
                                          fieldType: 'text',
                                          isRequired: false,
                                          displayOrder: 6,
                                        ),
                                        controller:
                                            widget.controllers[kSuretyAadhaar],
                                        value: widget.values[kSuretyAadhaar],
                                        onChanged: (v) => widget.onValueChanged(
                                            kSuretyAadhaar, v),
                                        readOnly: widget.readOnly,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: DynamicControlFactory(
                                        fieldDef: DynamicFieldDef(
                                          fieldDefId: -1,
                                          fieldKey: kSuretyPan,
                                          fieldLabel: 'Surety PAN No.',
                                          fieldSource: 'common',
                                          fieldType: 'text',
                                          isRequired: false,
                                          displayOrder: 7,
                                        ),
                                        controller:
                                            widget.controllers[kSuretyPan],
                                        value: widget.values[kSuretyPan],
                                        onChanged: (v) => widget.onValueChanged(
                                            kSuretyPan, v),
                                        readOnly: widget.readOnly,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                DynamicControlFactory(
                                  fieldDef: DynamicFieldDef(
                                    fieldDefId: -1,
                                    fieldKey: kSuretyAddress,
                                    fieldLabel: 'Surety Address',
                                    fieldSource: 'common',
                                    fieldType: 'text',
                                    isRequired: false,
                                    displayOrder: 8,
                                  ),
                                  controller:
                                      widget.controllers[kSuretyAddress],
                                  value: widget.values[kSuretyAddress],
                                  onChanged: (v) =>
                                      widget.onValueChanged(kSuretyAddress, v),
                                  readOnly: widget.readOnly,
                                ),
                                const SizedBox(height: 16),
                                DynamicControlFactory(
                                  fieldDef: DynamicFieldDef(
                                    fieldDefId: -1,
                                    fieldKey: kSuretyRelation,
                                    fieldLabel: 'Relation with Accused',
                                    fieldSource: 'common',
                                    fieldType: 'dropdown',
                                    isRequired: false,
                                    displayOrder: 9,
                                    options: const [
                                      'Father',
                                      'Mother',
                                      'Brother',
                                      'Sister',
                                      'Spouse',
                                      'Friend',
                                      'Other'
                                    ],
                                  ),
                                  controller: null,
                                  value: widget.values[kSuretyRelation],
                                  onChanged: (v) =>
                                      widget.onValueChanged(kSuretyRelation, v),
                                  readOnly: widget.readOnly,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EvidenceAndSeizureBlock extends StatefulWidget {
  final Map<String, TextEditingController> controllers;
  final Map<String, dynamic> values;
  final Function(String key, dynamic value) onValueChanged;
  final bool readOnly;
  final List<String>? accusedOptions;

  const _EvidenceAndSeizureBlock({
    Key? key,
    required this.controllers,
    required this.values,
    required this.onValueChanged,
    required this.readOnly,
    this.accusedOptions,
  }) : super(key: key);

  @override
  State<_EvidenceAndSeizureBlock> createState() =>
      _EvidenceAndSeizureBlockState();
}

class _EvidenceAndSeizureBlockState extends State<_EvidenceAndSeizureBlock> {
  // Keys
  static const kEShakshDateTime = 'e_shaksh_datetime';
  static const kFingerprintTaken = 'fingerprint_taken';
  static const kNafisFingerprint = 'nafis_fingerprint';
  static const kSeizedObjects = 'seized_objects';

  @override
  void initState() {
    super.initState();
    widget.controllers.putIfAbsent(
        kEShakshDateTime,
        () => TextEditingController(
            text: widget.values[kEShakshDateTime]?.toString() ?? ''));

    if (widget.values[kSeizedObjects] == null) {
      widget.values[kSeizedObjects] = <Map<String, dynamic>>[];
    }
  }

  void _addSeizedProperty() {
    setState(() {
      (widget.values[kSeizedObjects] as List).add({
        'name': '',
        'from_whom': '',
        'description': '',
      });
    });
    widget.onValueChanged(kSeizedObjects, widget.values[kSeizedObjects]);
  }

  void _removeSeizedProperty(int index) {
    setState(() {
      (widget.values[kSeizedObjects] as List).removeAt(index);
    });
    widget.onValueChanged(kSeizedObjects, widget.values[kSeizedObjects]);
  }

  Widget _buildYesNoButtons(String key, String title) {
    final val = widget.values[key];
    final isYes = val == true || val == 'Yes';
    final isNo = val == false || val == 'No';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            InkWell(
              onTap: widget.readOnly
                  ? null
                  : () {
                      setState(() {
                        widget.values[key] = 'Yes';
                        widget.onValueChanged(key, 'Yes');
                      });
                    },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isYes ? const Color(0xFFF0F9FF) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isYes
                        ? const Color(0xFF0288D1)
                        : const Color(0xFFE2E8F0),
                    width: isYes ? 1.5 : 1,
                  ),
                ),
                child: Text('Yes',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isYes
                            ? const Color(0xFF0288D1)
                            : const Color(0xFF64748B))),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: widget.readOnly
                  ? null
                  : () {
                      setState(() {
                        widget.values[key] = 'No';
                        widget.onValueChanged(key, 'No');
                      });
                    },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isNo ? const Color(0xFFFEF2F2) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isNo
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFE2E8F0),
                    width: isNo ? 1.5 : 1,
                  ),
                ),
                child: Text('No',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isNo
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF64748B))),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final seizedObjects = (widget.values[kSeizedObjects] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'E Shaksh',
                    style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: TextFormField(
                      controller: widget.controllers[kEShakshDateTime],
                      readOnly: true,
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: const Color(0xFF1E293B)),
                      decoration: InputDecoration(
                        hintText: 'Date & Time',
                        hintStyle: GoogleFonts.poppins(
                            fontSize: 12, color: const Color(0xFF94A3B8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 0),
                        suffixIcon: const Icon(Icons.calendar_month_rounded,
                            size: 16, color: Color(0xFF0288D1)),
                        filled: true,
                        fillColor: widget.readOnly
                            ? const Color(0xFFF8FAFC)
                            : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                          borderSide: const BorderSide(
                              color: Color(0xFF0288D1), width: 1.2),
                        ),
                      ),
                      onTap: widget.readOnly
                          ? null
                          : () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1970),
                                lastDate: DateTime(2050),
                              );
                              if (pickedDate != null) {
                                if (!mounted) return;
                                final pickedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (pickedTime != null) {
                                  final dt = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                  final val =
                                      DateFormat('dd/MM/yyyy HH:mm').format(dt);
                                  setState(() {
                                    widget.controllers[kEShakshDateTime]?.text =
                                        val;
                                    widget.values[kEShakshDateTime] = val;
                                    widget.onValueChanged(
                                        kEShakshDateTime, val);
                                  });
                                }
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: _buildYesNoButtons(kFingerprintTaken, 'Fingerprint taken'),
            ),
            Expanded(
              flex: 1,
              child: _buildYesNoButtons(kNafisFingerprint, 'Nafis Fingerprint'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Seizure Property Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SEIZURE PROPERTY DETAILS',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
            if (!widget.readOnly)
              InkWell(
                onTap: _addSeizedProperty,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add, size: 14, color: Color(0xFF0288D1)),
                      const SizedBox(width: 4),
                      Text(
                        'Add Seized Property',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0288D1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Seized Property List
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(16),
          child: seizedObjects.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'No seized properties added.',
                      style: GoogleFonts.poppins(
                          color: const Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ),
                )
              : Column(
                  children: List.generate(seizedObjects.length, (index) {
                    final obj = seizedObjects[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Object #${index + 1}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            if (!widget.readOnly)
                              InkWell(
                                onTap: () => _removeSeizedProperty(index),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: TextFormField(
                                  initialValue: obj['name'],
                                  readOnly: widget.readOnly,
                                  onChanged: (val) {
                                    obj['name'] = val;
                                    widget.onValueChanged(kSeizedObjects,
                                        widget.values[kSeizedObjects]);
                                  },
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: const Color(0xFF1E293B)),
                                  decoration: InputDecoration(
                                    hintText: 'Object Name',
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF0288D1), width: 1.2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: DropdownButtonFormField<String>(
                                  value: widget.accusedOptions
                                              ?.contains(obj['from_whom']) ==
                                          true
                                      ? obj['from_whom']
                                      : null,
                                  items: widget.accusedOptions?.map((o) {
                                    return DropdownMenuItem(
                                      value: o,
                                      child: Text(o,
                                          style: GoogleFonts.poppins(
                                              fontSize: 13)),
                                    );
                                  }).toList(),
                                  onChanged: widget.readOnly
                                      ? null
                                      : (val) {
                                          setState(() {
                                            obj['from_whom'] = val ?? '';
                                          });
                                          widget.onValueChanged(kSeizedObjects,
                                              widget.values[kSeizedObjects]);
                                        },
                                  decoration: InputDecoration(
                                    labelText: 'From whom - name',
                                    labelStyle: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: const Color(0xFF0288D1)),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFE2E8F0)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF0288D1), width: 1.2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: obj['description'],
                          readOnly: widget.readOnly,
                          onChanged: (val) {
                            obj['description'] = val;
                            widget.onValueChanged(
                                kSeizedObjects, widget.values[kSeizedObjects]);
                          },
                          maxLines: 2,
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: const Color(0xFF1E293B)),
                          decoration: InputDecoration(
                            hintText: 'Description',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(
                                  color: Color(0xFF0288D1), width: 1.2),
                            ),
                          ),
                        ),
                        if (index < seizedObjects.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Divider(color: Color(0xFFE2E8F0), height: 1),
                          ),
                      ],
                    );
                  }),
                ),
        ),
      ],
    );
  }
}

class _ScrutinyBlock extends StatefulWidget {
  final int index;
  final Map<String, dynamic> values;
  final Function(String key, dynamic value) onValueChanged;
  final bool readOnly;

  const _ScrutinyBlock({
    Key? key,
    required this.index,
    required this.values,
    required this.onValueChanged,
    this.readOnly = false,
  }) : super(key: key);

  @override
  State<_ScrutinyBlock> createState() => _ScrutinyBlockState();
}

class _ScrutinyBlockState extends State<_ScrutinyBlock> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
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
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(AppRadius.lg),
              bottom: Radius.circular(_expanded ? 0 : AppRadius.lg),
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
                    alignment: Alignment.center,
                    child: Text(
                      '${widget.index}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyMid,
                      ),
                    ),
                  ),
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
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.lightSubText,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.lightBorder),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _buildStepperForm(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepperForm() {
    final steps = [
      {
        'title': 'SDPO / ACP',
        'sendKey': 'sdpo_acp_send_date',
        'grantKey': 'sdpo_acp_grant_date',
      },
      {
        'title': 'Addl. SP / DCP',
        'sendKey': 'addl_sp_dcp_send_date',
        'grantKey': 'addl_sp_dcp_grant_date',
      },
      {
        'title': 'Addl. CP',
        'sendKey': 'addl_cp_send_date',
        'grantKey': 'addl_cp_grant_date',
      },
      {
        'title': 'APP',
        'sendKey': 'app_send_date',
        'grantKey': 'app_grant_date',
      },
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;

        // Logic for unlocking:
        // A send date is enabled if the PREVIOUS step's grant date is filled (or it is the 1st step)
        // A grant date is enabled if THIS step's send date is filled.

        bool sendEnabled = false;
        if (index == 0) {
          sendEnabled = true;
        } else {
          final prevGrantKey = steps[index - 1]['grantKey']!;
          final prevGrantVal = widget.values[prevGrantKey]?.toString();
          sendEnabled =
              (prevGrantVal != null && prevGrantVal.trim().isNotEmpty);
        }

        final currentSendKey = step['sendKey']!;
        final currentSendVal = widget.values[currentSendKey]?.toString();
        bool grantEnabled =
            (currentSendVal != null && currentSendVal.trim().isNotEmpty);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stepper Line & Circle
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: sendEnabled
                            ? const Color(0xFF0288D1)
                            : const Color(0xFFE2E8F0),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.poppins(
                          color: sendEnabled
                              ? Colors.white
                              : const Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Fields
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title']!,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCompactDatePicker(
                              currentSendKey,
                              'Send Date',
                              enabled: sendEnabled && !widget.readOnly,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildCompactDatePicker(
                              step['grantKey']!,
                              'Grant date',
                              enabled: grantEnabled && !widget.readOnly,
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
        );
      }),
    );
  }

  Widget _buildCompactDatePicker(String key, String label,
      {required bool enabled}) {
    final value = widget.values[key]?.toString() ?? '';
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: enabled
            ? () async {
                final dt = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (dt != null) {
                  final formatted =
                      "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
                  setState(() {
                    widget.values[key] = formatted;
                  });
                  widget.onValueChanged(key, formatted);
                }
              }
            : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: enabled ? Colors.white : const Color(0xFFF8FAFC),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value.isEmpty ? '' : value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              const Icon(Icons.calendar_month_outlined,
                  size: 16, color: Color(0xFF0288D1)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuspectedAccusedBlock extends StatefulWidget {
  final int index;
  final Map<String, dynamic> values;
  final Function(String key, dynamic value) onValueChanged;
  final bool readOnly;

  const _SuspectedAccusedBlock({
    Key? key,
    required this.index,
    required this.values,
    required this.onValueChanged,
    required this.readOnly,
  }) : super(key: key);

  @override
  State<_SuspectedAccusedBlock> createState() => _SuspectedAccusedBlockState();
}

class _SuspectedAccusedBlockState extends State<_SuspectedAccusedBlock> {
  List<Map<String, dynamic>> _suspects = [];

  @override
  void initState() {
    super.initState();
    final existing = widget.values['suspected_accused_list'];
    if (existing is List) {
      _suspects = List<Map<String, dynamic>>.from(
          existing.map((e) => Map<String, dynamic>.from(e as Map)));
    } else {
      _suspects = [];
    }
  }

  void _notifyChange() {
    widget.onValueChanged('suspected_accused_list', _suspects);
  }

  void _addSuspect() {
    if (widget.readOnly) return;
    setState(() {
      _suspects.add({
        'name': '',
        'age': '',
        'gender': 'Male',
        'occupation': '',
        'mobile_number': '',
        'aadhar_number': '',
        'pan_number': '',
        'religion': '',
        'caste': '',
        'address': '',
      });
    });
    _notifyChange();
  }

  void _removeSuspect(int index) {
    if (widget.readOnly) return;
    setState(() {
      _suspects.removeAt(index);
    });
    _notifyChange();
  }

  void _updateSuspectField(int index, String field, String value) {
    if (widget.readOnly) return;
    setState(() {
      _suspects[index][field] = value;
    });
    _notifyChange();
  }

  Widget _buildTextField(int index, String field, String label,
      {bool isFullWidth = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.navyDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: _suspects[index][field]?.toString() ?? '',
          readOnly: widget.readOnly,
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.navyDark),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.lightSubText),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: widget.readOnly ? const Color(0xFFF8FAFC) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppColors.navyMid, width: 1.5),
            ),
          ),
          onChanged: (val) => _updateSuspectField(index, field, val),
        ),
      ],
    );
  }

  Widget _buildGenderToggle(int index) {
    final current = _suspects[index]['gender']?.toString() ?? 'Male';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.navyDark,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: ['Male', 'Female', 'Other'].map((g) {
            final isSelected = current == g;
            return ChoiceChip(
              label: Text(g),
              selected: isSelected,
              onSelected: widget.readOnly
                  ? null
                  : (selected) {
                      if (selected) {
                        _updateSuspectField(index, 'gender', g);
                      }
                    },
              selectedColor: Colors.white,
              backgroundColor: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF0288D1)
                      : AppColors.lightBorder,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              labelStyle: GoogleFonts.poppins(
                fontSize: 12,
                color: isSelected
                    ? const Color(0xFF0288D1)
                    : AppColors.lightSubText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
          // Header Row
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.navyMid.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${widget.index}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyMid,
                  ),
                ),
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
              if (!widget.readOnly)
                ElevatedButton.icon(
                  onPressed: _addSuspect,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text('Add Suspected',
                      style: GoogleFonts.poppins(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE1F5FE),
                    foregroundColor: const Color(0xFF0288D1),
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
          const Divider(height: 24, color: AppColors.lightBorder),

          if (_suspects.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No suspected accused added.',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.lightSubText),
                ),
              ),
            ),

          ..._suspects.asMap().entries.map((e) {
            final idx = e.key;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Suspected #${idx + 1}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navyDark,
                        ),
                      ),
                      if (!widget.readOnly)
                        TextButton.icon(
                          onPressed: () => _removeSuspect(idx),
                          icon: const Icon(Icons.close, size: 14),
                          label: Text('Remove',
                              style: GoogleFonts.poppins(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.dangerRed,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(idx, 'name', 'Name')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(idx, 'age', 'Age')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildGenderToggle(idx),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child:
                              _buildTextField(idx, 'occupation', 'Occupation')),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildTextField(
                              idx, 'mobile_number', 'Mobile Number')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _buildTextField(
                              idx, 'aadhar_number', 'Aadhar Number')),
                      const SizedBox(width: 16),
                      Expanded(
                          child:
                              _buildTextField(idx, 'pan_number', 'PAN Number')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _buildTextField(idx, 'religion', 'Religion')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(idx, 'caste', 'Caste')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(idx, 'address', 'Address', isFullWidth: true),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _UnidentifiedAccusedBlock extends StatefulWidget {
  final int index;
  final Map<String, dynamic> values;
  final Function(String key, dynamic value) onValueChanged;
  final bool readOnly;

  const _UnidentifiedAccusedBlock({
    Key? key,
    required this.index,
    required this.values,
    required this.onValueChanged,
    required this.readOnly,
  }) : super(key: key);

  @override
  State<_UnidentifiedAccusedBlock> createState() =>
      _UnidentifiedAccusedBlockState();
}

class _UnidentifiedAccusedBlockState extends State<_UnidentifiedAccusedBlock> {
  List<Map<String, dynamic>> _unidentified = [];

  @override
  void initState() {
    super.initState();
    final existing = widget.values['unidentified_accused_list'];
    if (existing is List) {
      _unidentified = List<Map<String, dynamic>>.from(
          existing.map((e) => Map<String, dynamic>.from(e as Map)));
    } else {
      _unidentified = [];
    }
  }

  void _notifyChange() {
    widget.onValueChanged('unidentified_accused_list', _unidentified);
  }

  void _addUnidentified() {
    if (widget.readOnly) return;
    setState(() {
      _unidentified.add({
        'ua_age': '',
        'ua_height': '',
        'ua_gender': 'Male',
        'ua_skin': '',
        'ua_occupation': '',
        'ua_mark': '',
        'ua_address': '',
      });
    });
    _notifyChange();
  }

  void _removeUnidentified(int index) {
    if (widget.readOnly) return;
    setState(() {
      _unidentified.removeAt(index);
    });
    _notifyChange();
  }

  void _updateUnidentifiedField(int index, String field, String value) {
    if (widget.readOnly) return;
    setState(() {
      _unidentified[index][field] = value;
    });
    _notifyChange();
  }

  Widget _buildTextField(int index, String field, String label,
      {bool isFullWidth = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.navyDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: _unidentified[index][field]?.toString() ?? '',
          readOnly: widget.readOnly,
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.navyDark),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.lightSubText),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: widget.readOnly ? const Color(0xFFF8FAFC) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppColors.navyMid, width: 1.5),
            ),
          ),
          onChanged: (val) => _updateUnidentifiedField(index, field, val),
        ),
      ],
    );
  }

  Widget _buildGenderToggle(int index) {
    final current = _unidentified[index]['ua_gender']?.toString() ?? 'Male';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.navyDark,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: ['Male', 'Female', 'Other'].map((g) {
            final isSelected = current == g;
            return ChoiceChip(
              label: Text(g),
              selected: isSelected,
              onSelected: widget.readOnly
                  ? null
                  : (selected) {
                      if (selected) {
                        _updateUnidentifiedField(index, 'ua_gender', g);
                      }
                    },
              selectedColor: Colors.white,
              backgroundColor: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF0288D1)
                      : AppColors.lightBorder,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              labelStyle: GoogleFonts.poppins(
                fontSize: 12,
                color: isSelected
                    ? const Color(0xFF0288D1)
                    : AppColors.lightSubText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
          // Header Row
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.navyMid.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${widget.index}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyMid,
                  ),
                ),
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
              if (!widget.readOnly)
                ElevatedButton.icon(
                  onPressed: _addUnidentified,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text('Add Unidentified',
                      style: GoogleFonts.poppins(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE1F5FE),
                    foregroundColor: const Color(0xFF0288D1),
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
          const Divider(height: 24, color: AppColors.lightBorder),

          if (_unidentified.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No unidentified accused added.',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.lightSubText),
                ),
              ),
            ),

          ..._unidentified.asMap().entries.map((e) {
            final idx = e.key;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Unidentified #${idx + 1}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navyDark,
                        ),
                      ),
                      if (!widget.readOnly)
                        TextButton.icon(
                          onPressed: () => _removeUnidentified(idx),
                          icon: const Icon(Icons.close, size: 14),
                          label: Text('Remove',
                              style: GoogleFonts.poppins(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.dangerRed,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _buildTextField(
                              idx, 'ua_age', 'Approximate Age')),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildTextField(idx, 'ua_height', 'Height')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildGenderToggle(idx),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _buildTextField(idx, 'ua_skin', 'Skin Color')),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildTextField(
                              idx, 'ua_occupation', 'Possible Occupation')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(idx, 'ua_mark', 'Identification Mark',
                      isFullWidth: true),
                  const SizedBox(height: 12),
                  _buildTextField(idx, 'ua_address', 'Address',
                      isFullWidth: true),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AccusedBlock extends StatefulWidget {
  final int index;
  final Map<String, dynamic> values;
  final Function(String key, dynamic value) onValueChanged;
  final bool readOnly;

  const _AccusedBlock({
    Key? key,
    required this.index,
    required this.values,
    required this.onValueChanged,
    required this.readOnly,
  }) : super(key: key);

  @override
  State<_AccusedBlock> createState() => _AccusedBlockState();
}

class _AccusedBlockState extends State<_AccusedBlock> {
  List<Map<String, dynamic>> _accusedList = [];

  @override
  void initState() {
    super.initState();
    final existing = widget.values['accused_list'];
    if (existing is List) {
      _accusedList = List<Map<String, dynamic>>.from(
          existing.map((e) => Map<String, dynamic>.from(e as Map)));
    } else {
      _accusedList = [];
    }
  }

  void _notifyChange() {
    widget.onValueChanged('accused_list', _accusedList);
  }

  void _addAccused() {
    if (widget.readOnly) return;
    setState(() {
      _accusedList.add({
        'name': '',
        'age': '',
        'gender': 'Male',
        'occupation': '',
        'mobile_number': '',
        'aadhar_number': '',
        'pan_number': '',
        'religion': '',
        'caste': '',
        'address': '',
      });
    });
    _notifyChange();
  }

  void _removeAccused(int index) {
    if (widget.readOnly) return;
    setState(() {
      _accusedList.removeAt(index);
    });
    _notifyChange();
  }

  void _updateAccusedField(int index, String field, String value) {
    if (widget.readOnly) return;
    setState(() {
      _accusedList[index][field] = value;
    });
    _notifyChange();
  }

  Widget _buildTextField(int index, String field, String label,
      {bool isFullWidth = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.navyDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: _accusedList[index][field]?.toString() ?? '',
          readOnly: widget.readOnly,
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.navyDark),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.lightSubText),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: widget.readOnly ? const Color(0xFFF8FAFC) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.lightBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppColors.navyMid, width: 1.5),
            ),
          ),
          onChanged: (val) => _updateAccusedField(index, field, val),
        ),
      ],
    );
  }

  Widget _buildGenderToggle(int index) {
    final current = _accusedList[index]['gender']?.toString() ?? 'Male';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.navyDark,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: ['Male', 'Female', 'Other'].map((g) {
            final isSelected = current == g;
            return ChoiceChip(
              label: Text(g),
              selected: isSelected,
              onSelected: widget.readOnly
                  ? null
                  : (selected) {
                      if (selected) {
                        _updateAccusedField(index, 'gender', g);
                      }
                    },
              selectedColor: Colors.white,
              backgroundColor: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF0288D1)
                      : AppColors.lightBorder,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              labelStyle: GoogleFonts.poppins(
                fontSize: 12,
                color: isSelected
                    ? const Color(0xFF0288D1)
                    : AppColors.lightSubText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
          // Header Row
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.navyMid.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${widget.index}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyMid,
                  ),
                ),
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
              if (!widget.readOnly)
                ElevatedButton.icon(
                  onPressed: _addAccused,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text('Add Accused',
                      style: GoogleFonts.poppins(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE1F5FE),
                    foregroundColor: const Color(0xFF0288D1),
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
          const Divider(height: 24, color: AppColors.lightBorder),

          if (_accusedList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No accused added.',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.lightSubText),
                ),
              ),
            ),

          ..._accusedList.asMap().entries.map((e) {
            final idx = e.key;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Accused #${idx + 1}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navyDark,
                        ),
                      ),
                      if (!widget.readOnly)
                        TextButton.icon(
                          onPressed: () => _removeAccused(idx),
                          icon: const Icon(Icons.close, size: 14),
                          label: Text('Remove',
                              style: GoogleFonts.poppins(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.dangerRed,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(idx, 'name', 'Name')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(idx, 'age', 'Age')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildGenderToggle(idx),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child:
                              _buildTextField(idx, 'occupation', 'Occupation')),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildTextField(
                              idx, 'mobile_number', 'Mobile Number')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _buildTextField(
                              idx, 'aadhar_number', 'Aadhar Number')),
                      const SizedBox(width: 16),
                      Expanded(
                          child:
                              _buildTextField(idx, 'pan_number', 'PAN Number')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _buildTextField(idx, 'religion', 'Religion')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(idx, 'caste', 'Caste')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(idx, 'address', 'Address', isFullWidth: true),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
