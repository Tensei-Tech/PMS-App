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

  bool get isEmpty =>
      (actId == null || actId.toString().trim().isEmpty) &&
      (actName == null || actName!.trim().isEmpty) &&
      (sectionId == null || sectionId.toString().trim().isEmpty) &&
      (sectionNumber == null || sectionNumber!.trim().isEmpty);

  bool get isNotEmpty => !isEmpty;
}

class RepeatingCascadingChargesSelector extends StatefulWidget {
  final List<dynamic>? initialCharges;
  final ValueChanged<List<Map<String, dynamic>>>? onChargesChanged;
  final ValueChanged<List<dynamic>>? onSectionIdsChanged;
  final bool readOnly;

  /// Optional limit on the number of charges (e.g. 1 for one charge per row of
  /// a repeating group). Null keeps the unlimited "Add Another Charge" button.
  final int? maxCharges;

  const RepeatingCascadingChargesSelector({
    super.key,
    this.initialCharges,
    this.onChargesChanged,
    this.onSectionIdsChanged,
    this.readOnly = false,
    this.maxCharges,
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

  // The charge open for editing. Other charges that have an Act and Section
  // collapse to a one-line summary; tapping one opens it here.
  ChargeItemData? _editing;

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

    _charges.clear();
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
    // Editable forms open with one blank charge so Act / Section /
    // Subsection show straight away, without an "Add" step.
    if (_charges.isEmpty && !widget.readOnly) {
      _charges.add(ChargeItemData());
    }
    if (mounted) setState(() {});

    _notifyParent();
  }

  @override
  void didUpdateWidget(covariant RepeatingCascadingChargesSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCharges != oldWidget.initialCharges &&
        widget.initialCharges != null &&
        widget.initialCharges!.isNotEmpty &&
        _charges.every((c) => c.isEmpty)) {
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
    final validCharges = _charges.where((c) => c.isNotEmpty).toList();
    final resultList = validCharges.map((c) => c.toJson()).toList();
    widget.onChargesChanged?.call(resultList);

    final sectionIds =
        validCharges.map((c) => c.sectionId).where((id) => id != null).toList();
    widget.onSectionIdsChanged?.call(sectionIds);
  }

  void _addCharge() {
    if (widget.readOnly) return;
    setState(() {
      final fresh = ChargeItemData();
      _charges.add(fresh);
      _editing = fresh;
    });
    _notifyParent();
  }

  void _removeCharge(int index) {
    if (widget.readOnly) return;
    setState(() {
      _charges.removeAt(index);
      // Keep one row on screen: removing the last charge just clears it.
      if (_charges.isEmpty) _charges.add(ChargeItemData());
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

    // Only read-only views can have no charges (editable ones start with a
    // blank row).
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
          ],
        ),
      );
    }

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
        if (!widget.readOnly &&
            (widget.maxCharges == null || _charges.length < widget.maxCharges!))
          TextButton.icon(
            onPressed: _addCharge,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.navyMid,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
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

    final complete = charge.actId != null && charge.sectionId != null;
    if (complete && (widget.readOnly || !identical(charge, _editing))) {
      return _buildChargeSummary(index, charge);
    }

    // Header: "CHARGE 1" on the left, Remove on the right. Remove is hidden
    // while there is a single blank row, since there is nothing to remove.
    final canRemove =
        !widget.readOnly && (_charges.length > 1 || charge.isNotEmpty);
    final header = Row(
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
        Text(
          'CHARGE ${index + 1}',
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.navyMid,
          ),
        ),
        const Spacer(),
        if (complete && !widget.readOnly)
          TextButton.icon(
            onPressed: () => setState(() => _editing = null),
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
        if (canRemove)
          TextButton.icon(
            onPressed: () => _removeCharge(index),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.dangerRed,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 17),
            label: Text(
              'Remove',
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );

    final act = _labelled('Act / Law', true, _buildActDropdown(charge));
    final section = _labelled(
        'Section', true, _buildSectionDropdown(charge, availableSections));
    final subsection = _labelled('Subsection', false,
        _buildSubsectionDropdown(charge, availableSubsections));

    // The header only appears when it says something: several charges to
    // tell apart, or a filled charge that can be removed.
    final showHeader = _charges.length > 1 || canRemove;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.fromLTRB(12, showHeader ? 6 : 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            SizedBox(height: 28, child: header),
            const SizedBox(height: 4),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              // Wide: Act | Section | Subsection on one line
              if (constraints.maxWidth >= 640) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: act),
                    const SizedBox(width: 12),
                    Expanded(flex: 3, child: section),
                    const SizedBox(width: 12),
                    Expanded(flex: 3, child: subsection),
                  ],
                );
              }
              // Medium: Act on top, Section + Subsection side by side
              if (constraints.maxWidth >= 340) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    act,
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: section),
                        const SizedBox(width: 10),
                        Expanded(child: subsection),
                      ],
                    ),
                  ],
                );
              }
              // Very narrow: one field per line
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  act,
                  const SizedBox(height: 10),
                  section,
                  const SizedBox(height: 10),
                  subsection,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// One-line view of a filled charge: "1  BNS 2023 · Sec 100 - Culpable
  /// homicide · Sub (1)", with edit and remove. Tap to edit.
  Widget _buildChargeSummary(int index, ChargeItemData charge) {
    final sec = [
      'Sec ${charge.sectionNumber ?? ''}'.trim(),
      if ((charge.sectionTitle ?? '').trim().isNotEmpty)
        charge.sectionTitle!.trim(),
    ].join(' - ');
    final sub = (charge.subsectionCode ?? '').trim();
    final detail = sub.isEmpty ? sec : '$sec  ·  Sub ($sub)';

    final row = Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.navyMid,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${index + 1}',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                charge.actName ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyDark,
                ),
              ),
            ],
          ),
        ),
        if (!widget.readOnly) ...[
          IconButton(
            tooltip: 'Edit',
            onPressed: () => setState(() => _editing = charge),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.edit_outlined,
                size: 18, color: AppColors.navyMid),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: () => _removeCharge(index),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: AppColors.dangerRed),
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap:
              widget.readOnly ? null : () => setState(() => _editing = charge),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
            child: row,
          ),
        ),
      ),
    );
  }

  /// Field with its label above it ("Act / Law *", "Subsection (optional)").
  Widget _labelled(String label, bool required, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            children: [
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.dangerRed),
                )
            ],
          ),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 4),
        field,
      ],
    );
  }

  static const _fieldTextSize = 12.5;
  static const _fieldPadding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 10);

  InputBorder _border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );

  Widget _buildActDropdown(ChargeItemData charge) {
    return _buildSearchableDropdown(
      key: ValueKey('act_${charge.actId}'),
      label: 'Act / Law *',
      hint: 'Search act (e.g. BNS, IPC)',
      initialSelection:
          _actsList.any((a) => a['id'] == charge.actId) ? charge.actId : null,
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
          _editing = charge;
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
    final bool isEnabled = !widget.readOnly &&
        charge.actId != null &&
        availableSections.isNotEmpty;

    return _buildSearchableDropdown(
      key: ValueKey('sec_${charge.actId}_${charge.sectionId}'),
      label: 'Section *',
      hint: charge.actId == null
          ? 'Select act first'
          : (availableSections.isEmpty ? 'Loading...' : 'Search (e.g. 103)'),
      initialSelection:
          availableSections.any((s) => s['id'] == charge.sectionId)
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
          _editing = charge;
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
    List<DropdownMenuEntry<dynamic>> Function(
            List<DropdownMenuEntry<dynamic>> entries, String filter)?
        filterCallback,
  }) {
    return DropdownMenu<dynamic>(
      key: key,
      expandedInsets: EdgeInsets.zero,
      enabled: isEnabled,
      initialSelection: initialSelection,
      enableFilter: true,
      requestFocusOnTap: true,
      menuHeight: 320,
      hintText: hint,
      textStyle: GoogleFonts.poppins(
        fontSize: _fieldTextSize,
        fontWeight: FontWeight.w500,
        color: AppColors.navyDark,
      ),
      trailingIcon: const Icon(Icons.arrow_drop_down_rounded, size: 20),
      selectedTrailingIcon: const Icon(Icons.arrow_drop_up_rounded, size: 20),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: isEnabled ? Colors.white : const Color(0xFFF8FAFC),
        contentPadding: _fieldPadding,
        hintStyle: GoogleFonts.poppins(
          fontSize: 12,
          color: const Color(0xFF94A3B8),
        ),
        border: _border(AppColors.lightBorder),
        enabledBorder: _border(AppColors.lightBorder),
        focusedBorder: _border(AppColors.navyMid, 1.5),
        disabledBorder: _border(const Color(0xFFE2E8F0)),
      ),
      filterCallback: filterCallback,
      dropdownMenuEntries: entries,
      onSelected: onSelected,
    );
  }

  Widget _buildSubsectionDropdown(
      ChargeItemData charge, List<Map<String, dynamic>> availableSubsections) {
    // Same DropdownMenu as Act and Section, so all fields match in size.
    return _buildSearchableDropdown(
      key: ValueKey('sub_${charge.sectionId}_${charge.subsectionId}'),
      label: 'Subsection',
      hint: charge.sectionId == null
          ? 'Optional'
          : (availableSubsections.isEmpty ? 'None' : 'Optional'),
      initialSelection:
          availableSubsections.any((sub) => sub['id'] == charge.subsectionId)
              ? charge.subsectionId
              : null,
      isEnabled: !widget.readOnly && availableSubsections.isNotEmpty,
      filterCallback: (entries, filter) {
        final query = filter.trim().toLowerCase();
        if (query.isEmpty) return entries;
        return entries
            .where((e) => e.label.toLowerCase().contains(query))
            .toList();
      },
      entries: availableSubsections.map((sub) {
        return DropdownMenuEntry<dynamic>(
          value: sub['id'],
          label: sub['display_name']?.toString() ??
              'Sub. ${sub['subsection_code']}',
        );
      }).toList(),
      onSelected: (val) {
        setState(() {
          _editing = charge;
          charge.subsectionId = val;
          final match = availableSubsections.firstWhere(
            (sub) => sub['id'] == val,
            orElse: () => {},
          );
          charge.subsectionCode = match['subsection_code']?.toString();
        });
        _notifyParent();
      },
    );
  }
}
