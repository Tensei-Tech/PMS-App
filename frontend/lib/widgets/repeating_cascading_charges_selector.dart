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

    _notifyParent();
  }

  @override
  void didUpdateWidget(covariant RepeatingCascadingChargesSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCharges != oldWidget.initialCharges &&
        widget.initialCharges != null &&
        widget.initialCharges!.isNotEmpty &&
        _charges.isEmpty) {
      _initData();
    }
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

    final subList =
        await _caseService.fetchActSubsections(sectionId: sectionId);
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
    });
    _notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingActs) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
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
      );
    }

    if (_charges.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.navyMid.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.gavel_rounded,
                size: 28,
                color: AppColors.navyMid,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'No acts or sections filed yet.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
            if (!widget.readOnly) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _addCharge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyMid,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Add Act & Section',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._charges.asMap().entries.map((entry) {
          final idx = entry.key;
          final charge = entry.value;
          return _buildSingleChargeCard(idx, charge);
        }),
        const SizedBox(height: 10),
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
    final availableSections = actIdKey != null
        ? (_sectionsCache[actIdKey] ?? [])
        : <Map<String, dynamic>>[];

    final sectionIdKey = charge.sectionId?.toString();
    final availableSubsections = sectionIdKey != null
        ? (_subsectionsCache[sectionIdKey] ?? [])
        : <Map<String, dynamic>>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.navyMid,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Charge #${index + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              if (!widget.readOnly)
                Tooltip(
                  message: 'Remove Charge',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _removeCharge(index),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.dangerRed,
                            size: 18,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Remove',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.dangerRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 650;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _buildActDropdown(charge),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: _buildSectionDropdown(charge, availableSections),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: _buildSubsectionDropdown(
                          charge, availableSubsections),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActDropdown(charge),
                  const SizedBox(height: 12),
                  _buildSectionDropdown(charge, availableSections),
                  const SizedBox(height: 12),
                  _buildSubsectionDropdown(charge, availableSubsections),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActDropdown(ChargeItemData charge) {
    return _buildSearchableDropdown(
      key: ValueKey('act_${charge.actId}'),
      label: 'Act / Law *',
      hint: 'Search Act (e.g. BNS, IPC)...',
      initialSelection: _actsList.any((a) => a['id'] == charge.actId)
          ? charge.actId
          : null,
      isEnabled: !widget.readOnly,
      filterCallback: (entries, filter) {
        final query = filter.trim().toLowerCase();
        if (query.isEmpty) return entries;
        return entries
            .where((e) => e.label.toLowerCase().contains(query))
            .toList();
      },
      entries: _actsList.map((a) {
        return DropdownMenuEntry<dynamic>(
          value: a['id'],
          label: a['act_name']?.toString() ?? '',
        );
      }).toList(),
      onSelected: (val) {
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
    );
  }

  Widget _buildSectionDropdown(
      ChargeItemData charge, List<Map<String, dynamic>> availableSections) {
    final bool isEnabled =
        !widget.readOnly && charge.actId != null && availableSections.isNotEmpty;

    return _buildSearchableDropdown(
      key: ValueKey('sec_${charge.actId}_${charge.sectionId}'),
      label: 'Section *',
      hint: charge.actId == null
          ? 'Select Act first'
          : (availableSections.isEmpty
              ? 'Loading sections...'
              : 'Search Section (e.g. 101, murder)...'),
      initialSelection: availableSections.any((s) => s['id'] == charge.sectionId)
          ? charge.sectionId
          : null,
      isEnabled: isEnabled,
      filterCallback: (entries, filter) {
        final query = filter.trim().toLowerCase();
        if (query.isEmpty) return entries;
        return entries
            .where((e) => e.label.toLowerCase().contains(query))
            .toList();
      },
      entries: availableSections.map((s) {
        final sNum = s['section_number']?.toString() ?? '';
        final sTitle = s['section_title']?.toString() ?? '';
        final label = sTitle.isNotEmpty ? 'Sec $sNum - $sTitle' : 'Sec $sNum';
        return DropdownMenuEntry<dynamic>(
          value: s['id'],
          label: label,
        );
      }).toList(),
      onSelected: (val) {
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
    );
  }

  Widget _buildSearchableDropdown({
    required Key key,
    required String label,
    required String hint,
    required dynamic initialSelection,
    required bool isEnabled,
    required List<DropdownMenuEntry<dynamic>> entries,
    required ValueChanged<dynamic> onSelected,
    List<DropdownMenuEntry<dynamic>> Function(List<DropdownMenuEntry<dynamic>> entries, String filter)? filterCallback,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        DropdownMenu<dynamic>(
          key: key,
          expandedInsets: EdgeInsets.zero,
          enabled: isEnabled,
          initialSelection: initialSelection,
          enableFilter: true,
          requestFocusOnTap: true,
          menuHeight: 320,
          leadingIcon: const Icon(
            Icons.search_rounded,
            size: 19,
            color: AppColors.navyMid,
          ),
          hintText: hint,
          textStyle: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.navyDark,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: isEnabled ? Colors.white : const Color(0xFFF1F5F9),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            hintStyle: GoogleFonts.poppins(
              fontSize: 12.5,
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
              borderSide:
                  const BorderSide(color: AppColors.navyMid, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          filterCallback: filterCallback,
          dropdownMenuEntries: entries,
          onSelected: onSelected,
        ),
      ],
    );
  }
  Widget _buildSubsectionDropdown(
      ChargeItemData charge, List<Map<String, dynamic>> availableSubsections) {
    return _buildDropdownField<dynamic>(
      label: 'Subsection (Optional)',
      hint: charge.sectionId == null
          ? 'Select Section first'
          : (availableSubsections.isEmpty
              ? 'None available'
              : 'Select Subsection'),
      value: availableSubsections
              .any((sub) => sub['id'] == charge.subsectionId)
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
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            fillColor: Colors.white,
            filled: true,
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
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
              borderSide:
                  const BorderSide(color: AppColors.navyMid, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
