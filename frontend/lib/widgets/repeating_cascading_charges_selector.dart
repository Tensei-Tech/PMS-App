// lib/widgets/repeating_cascading_charges_selector.dart
// Repeating & Cascading Dropdowns for Charges (Act -> Section -> Subsection)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/case_service.dart';
import '../theme/app_theme.dart';

class ChargeItemData {
  dynamic actId;
  String? actName;
  dynamic sectionId;
  String? sectionNumber;
  String? sectionTitle;
  dynamic subsectionId;
  String? subsectionCode;

  ChargeItemData({
    this.actId,
    this.actName,
    this.sectionId,
    this.sectionNumber,
    this.sectionTitle,
    this.subsectionId,
    this.subsectionCode,
  });

  Map<String, dynamic> toJson() => {
        'act_id': actId,
        'act': actId,
        'act_name': actName,
        'section_id': sectionId,
        'section': sectionId,
        'section_number': sectionNumber,
        'section_title': sectionTitle,
        'subsection_id': subsectionId,
        'subsection': subsectionId,
        'subsection_code': subsectionCode,
      };

  factory ChargeItemData.fromMap(Map<String, dynamic> map) {
    return ChargeItemData(
      actId: map['act_id'] ?? map['act'],
      actName: map['act_name']?.toString(),
      sectionId: map['section_id'] ?? map['section'],
      sectionNumber: map['section_number']?.toString(),
      sectionTitle: map['section_title']?.toString(),
      subsectionId: map['subsection_id'] ?? map['subsection'],
      subsectionCode: map['subsection_code']?.toString(),
    );
  }
}

class RepeatingCascadingChargesSelector extends StatefulWidget {
  final List<dynamic>? initialCharges;
  final ValueChanged<List<Map<String, dynamic>>>? onChargesChanged;
  final ValueChanged<List<dynamic>>? onSectionIdsChanged;
  final bool readOnly;

  const RepeatingCascadingChargesSelector({
    super.key,
    this.initialCharges,
    this.onChargesChanged,
    this.onSectionIdsChanged,
    this.readOnly = false,
  });

  @override
  State<RepeatingCascadingChargesSelector> createState() =>
      _RepeatingCascadingChargesSelectorState();
}

class _RepeatingCascadingChargesSelectorState
    extends State<RepeatingCascadingChargesSelector> {
  final CaseService _caseService = CaseService();

  List<Map<String, dynamic>> _actsList = [];
  bool _loadingActs = true;

  final List<ChargeItemData> _charges = [];

  // Cache sections by actId and subsections by sectionId
  final Map<String, List<Map<String, dynamic>>> _sectionsCache = {};
  final Map<String, List<Map<String, dynamic>>> _subsectionsCache = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final fetchedActs = await _caseService.fetchActs();
    if (!mounted) return;

    setState(() {
      _actsList = fetchedActs;
      _loadingActs = false;
    });

    if (widget.initialCharges != null && widget.initialCharges!.isNotEmpty) {
      for (final raw in widget.initialCharges!) {
        if (raw is Map) {
          final itemMap = Map<String, dynamic>.from(raw);
          final item = ChargeItemData.fromMap(itemMap);
          _charges.add(item);
          if (item.actId != null) {
            _fetchSectionsForAct(item.actId);
          }
          if (item.sectionId != null) {
            _fetchSubsectionsForSection(item.sectionId);
          }
        }
      }
    }

    if (_charges.isEmpty) {
      _charges.add(ChargeItemData());
    }

    _notifyParent();
  }

  Future<void> _fetchSectionsForAct(dynamic actId) async {
    final key = actId.toString();
    if (_sectionsCache.containsKey(key)) return;

    final secList = await _caseService.fetchActSections(actId: actId);
    if (!mounted) return;
    setState(() {
      _sectionsCache[key] = secList;
    });
  }

  Future<void> _fetchSubsectionsForSection(dynamic sectionId) async {
    final key = sectionId.toString();
    if (_subsectionsCache.containsKey(key)) return;

    final subList = await _caseService.fetchActSubsections(sectionId: sectionId);
    if (!mounted) return;
    setState(() {
      _subsectionsCache[key] = subList;
    });
  }

  void _notifyParent() {
    final resultList = _charges.map((c) => c.toJson()).toList();
    widget.onChargesChanged?.call(resultList);

    final sectionIds =
        _charges.map((c) => c.sectionId).where((id) => id != null).toList();
    widget.onSectionIdsChanged?.call(sectionIds);
  }

  void _addCharge() {
    if (widget.readOnly) return;
    setState(() {
      _charges.add(ChargeItemData());
    });
    _notifyParent();
  }

  void _removeCharge(int index) {
    if (widget.readOnly) return;
    setState(() {
      _charges.removeAt(index);
      if (_charges.isEmpty) {
        _charges.add(ChargeItemData());
      }
    });
    _notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_loadingActs)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text(
                  'Loading Acts reference data...',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          )
        else
          ..._charges.asMap().entries.map((entry) {
            final idx = entry.key;
            final charge = entry.value;
            return _buildSingleChargeCard(idx, charge);
          }),
        const SizedBox(height: 8),
        if (!widget.readOnly)
          OutlinedButton.icon(
            onPressed: _addCharge,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navyMid,
              side: const BorderSide(color: AppColors.navyMid),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: Text(
              'Add Another Charge',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSingleChargeCard(int index, ChargeItemData charge) {
    final actIdKey = charge.actId?.toString();
    final availableSections = actIdKey != null ? (_sectionsCache[actIdKey] ?? []) : <Map<String, dynamic>>[];

    final sectionIdKey = charge.sectionId?.toString();
    final availableSubsections = sectionIdKey != null ? (_subsectionsCache[sectionIdKey] ?? []) : <Map<String, dynamic>>[];

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.navyMid,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Charge #${index + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              if (!widget.readOnly && _charges.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.dangerRed, size: 20),
                  onPressed: () => _removeCharge(index),
                  tooltip: 'Remove Charge',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 10),

          // 1. Act Dropdown
          _buildDropdownField<dynamic>(
            label: 'Act / Law',
            hint: 'Select Act (e.g. BNS 2023, IPC)',
            value: charge.actId,
            items: _actsList.map((a) {
              return DropdownMenuItem<dynamic>(
                value: a['id'],
                child: Text(
                  a['act_name']?.toString() ?? '',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: widget.readOnly
                ? null
                : (val) {
                    setState(() {
                      charge.actId = val;
                      final match = _actsList.firstWhere(
                        (a) => a['id'] == val,
                        orElse: () => {},
                      );
                      charge.actName = match['act_name']?.toString();
                      charge.sectionId = null;
                      charge.sectionNumber = null;
                      charge.sectionTitle = null;
                      charge.subsectionId = null;
                      charge.subsectionCode = null;
                    });
                    if (val != null) {
                      _fetchSectionsForAct(val);
                    }
                    _notifyParent();
                  },
          ),
          const SizedBox(height: 10),

          // 2. Section Dropdown
          _buildDropdownField<dynamic>(
            label: 'Section',
            hint: charge.actId == null
                ? 'Select Act first to load sections'
                : (availableSections.isEmpty
                    ? 'Loading sections...'
                    : 'Select Section (e.g. 103 Murder, 115 Hurt)'),
            value: availableSections.any((s) => s['id'] == charge.sectionId)
                ? charge.sectionId
                : null,
            items: availableSections.map((s) {
              return DropdownMenuItem<dynamic>(
                value: s['id'],
                child: Text(
                  s['display_name']?.toString() ??
                      'Sec ${s['section_number']}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (widget.readOnly || charge.actId == null)
                ? null
                : (val) {
                    setState(() {
                      charge.sectionId = val;
                      final match = availableSections.firstWhere(
                        (s) => s['id'] == val,
                        orElse: () => {},
                      );
                      charge.sectionNumber = match['section_number']?.toString();
                      charge.sectionTitle = match['section_title']?.toString();
                      charge.subsectionId = null;
                      charge.subsectionCode = null;
                    });
                    if (val != null) {
                      _fetchSubsectionsForSection(val);
                    }
                    _notifyParent();
                  },
          ),
          const SizedBox(height: 10),

          // 3. Subsection Dropdown
          _buildDropdownField<dynamic>(
            label: 'Subsection (Optional)',
            hint: charge.sectionId == null
                ? 'Select Section first'
                : (availableSubsections.isEmpty
                    ? 'No Subsections for this section'
                    : 'Select Subsection'),
            value: availableSubsections.any((sub) => sub['id'] == charge.subsectionId)
                ? charge.subsectionId
                : null,
            items: availableSubsections.map((sub) {
              return DropdownMenuItem<dynamic>(
                value: sub['id'],
                child: Text(
                  sub['display_name']?.toString() ??
                      'Sub. ${sub['subsection_code']}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (widget.readOnly || availableSubsections.isEmpty)
                ? null
                : (val) {
                    setState(() {
                      charge.subsectionId = val;
                      final match = availableSubsections.firstWhere(
                        (sub) => sub['id'] == val,
                        orElse: () => {},
                      );
                      charge.subsectionCode =
                          match['subsection_code']?.toString();
                    });
                    _notifyParent();
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,

          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            fillColor: Colors.white,
            filled: true,
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
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
              borderSide: const BorderSide(color: AppColors.navyMid),
            ),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
